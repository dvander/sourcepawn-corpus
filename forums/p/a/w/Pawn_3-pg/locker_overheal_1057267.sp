#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Locker Overheal",
	author = "Pawn",
	description = "Overheals players when they touch a resupply locker in spawn",
	version = PLUGIN_VERSION,
	url = "http://www.3-pg.com/"
}

new Float:PlayersInRange[MAXPLAYERS+1]
new m_Offsetm_iHealth
new m_Offsetm_iMaxHealth
new Handle:cvar_tf_boost_drain_time
new Handle:cvar_tf_max_health_boost
new Handle:cvar_locker_overheal_enabled
new bool:bPluginEnabled


public OnPluginStart()
{
  m_Offsetm_iHealth = FindSendPropOffs("CTFPlayer", "m_iHealth")
  m_Offsetm_iMaxHealth = FindSendPropOffs("CBaseObject", "m_iMaxHealth")
  HookEntityOutput("prop_dynamic", "OnAnimationBegun", EntityOutput_OnAnimationBegun)

  cvar_locker_overheal_enabled = CreateConVar("sm_locker_overheal_enabled", "1", "Locker Overheal enabled. 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0)
  HookConVarChange(cvar_locker_overheal_enabled, CVAR_Changed)
  bPluginEnabled = GetConVarBool(cvar_locker_overheal_enabled)

  cvar_tf_max_health_boost = FindConVar("tf_max_health_boost")
  cvar_tf_boost_drain_time = FindConVar("tf_boost_drain_time")
  
  CreateConVar("sm_locker_overheal_version", PLUGIN_VERSION, "Locker Overheal Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
}


public EntityOutput_OnAnimationBegun(const String:output[], caller, activator, Float:delay)
{
  if (bPluginEnabled)
  {
    if (IsValidEntity(caller))
    {
      decl String:modelname[128]
      GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128)
      if (StrEqual(modelname, "models/props_gameplay/resupply_locker.mdl"))
      {
        decl Float:pos[3]
        GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos)
        FindPlayersInRange(pos, 128.0, 0, caller, false, caller)
        new j
        new PlayerHealth, PlayerMaxHealth
        for (j=1; j<=MaxClients; j++)
        {
          if(PlayersInRange[j]>0.0)
          {
            PlayerHealth = GetClientHealth(j)
            PlayerMaxHealth = GetEntData(j, m_Offsetm_iMaxHealth, 4)
            PlayerHealth = RoundToZero(PlayerMaxHealth * GetConVarFloat(cvar_tf_max_health_boost))
            SetEntData(j, m_Offsetm_iHealth, PlayerHealth, 4, true)
            
            new Handle:pack
            new Float:interval = ((GetConVarFloat(cvar_tf_boost_drain_time)) / (PlayerHealth - PlayerMaxHealth))
            CreateDataTimer(interval, Timer_OverHealDecay, pack)
            WritePackCell(pack, GetClientUserId(j))
            WritePackCell(pack, PlayerHealth)
            WritePackFloat(pack, interval)
            WritePackCell(pack,PlayerMaxHealth)
          }
        }
      }
    }
  }
}


// players in range setup  (self = 0 if doesn't affect self)
FindPlayersInRange(Float:location[3], Float:radius, team, self, bool:trace, donthit)
{
  new Float:rsquare = radius*radius
  decl Float:orig[3]
  new Float:distance
  new Handle:tr
  new j
  for (j=1; j<=MaxClients; j++)
  {
    PlayersInRange[j] = 0.0
    if (IsClientInGame(j) && IsPlayerAlive(j))
    {
      if ( (team>1 && GetClientTeam(j)==team) || team==0 || j==self)
      {
        GetClientAbsOrigin(j, orig)
        orig[0]-=location[0]
        orig[1]-=location[1]
        orig[2]-=location[2]
        orig[0]*=orig[0]
        orig[1]*=orig[1]
        orig[2]*=orig[2]
        distance = orig[0]+orig[1]+orig[2]
        if (distance < rsquare)
        {
          if (trace)
          {
            GetClientEyePosition(j, orig)
            tr = TR_TraceRayFilterEx(location, orig, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfOrPlayers, donthit)
            if (tr!=INVALID_HANDLE)
            {
              if (TR_GetFraction(tr)>0.98)
              {
                  PlayersInRange[j] = SquareRoot(distance)/radius
              }
              CloseHandle(tr)
            }
          }
          else
          {
              PlayersInRange[j] = SquareRoot(distance)/radius
          }
        }
      }
    }
  }
}


public bool:TraceRayDontHitSelfOrPlayers(entity, mask, any:startent)
{
  if(entity == startent)
  {
    return false
  }
  
  if (entity <= GetMaxClients())
  {
    return false
  }
  
  return true
}


public CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
  bPluginEnabled = GetConVarBool(cvar_locker_overheal_enabled)
}


public Action:Timer_OverHealDecay(Handle:Timer, Handle:pack)
{
  ResetPack(pack)
  new userid = ReadPackCell(pack)
  new LastPlayerHealth = ReadPackCell(pack)
  new Float:interval = ReadPackFloat(pack)
  new PlayerMaxHealth = ReadPackCell(pack)
  
  new client = GetClientOfUserId(userid)
  if (IsClientInGame(client) && IsPlayerAlive(client))
  {
    new PlayerHealth = GetClientHealth(client)

    if(PlayerHealth > PlayerMaxHealth)
    {
      //if (Health hasn't changed since last time checked) OR (health has changed, but by more than the regular decay amount)
      if ((LastPlayerHealth == PlayerHealth) || (LastPlayerHealth - PlayerHealth > 1))
      {
        PlayerHealth--
        SetEntData(client, m_Offsetm_iHealth, PlayerHealth, 4, true)
        new Handle:pack2
        CreateDataTimer(interval, Timer_OverHealDecay, pack2)
        WritePackCell(pack2, userid)
        WritePackCell(pack2, PlayerHealth)
        WritePackFloat(pack2, interval)
        WritePackCell(pack2, PlayerMaxHealth)
      }
    }
  }
}