#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_VERSION "0.3"

public Plugin myinfo =
{
	name = "[L4D2]Witch Adrenaline Boost",
	author = "Backflip9",
	description = "Instakill witch within 10 seconds of using adrenaline",
	version = PLUGIN_VERSION,
	url = "streamercabin.net"
};

static bool hasAdrenaline[MAXPLAYERS+1];
static char prepend[32];
static float cooldown_time;

public void OnPluginStart()
{
  cooldown_time=10.0;
	//CreateConVar("l4d2_witch_adrenaline_boost_version", PLUGIN_VERSION, "[L4D2]Witch_Adrenaline_Boost", FCVAR_DONTRECORD|FCVAR_NOTIFY);
  CreateConVar("l4d_wab_cooldown","10","Amount of time the witch adrenaline boost is active after using adrenaline",FCVAR_NOTIFY,true/*hasmin*/,1.0,true/*hasmax*/,3600.00);
  ConVar cooldown_convar=FindConVar("l4d_wab_cooldown");
  HookConVarChange(cooldown_convar,on_cooldown_change);
	
  for(int i=0;i<MAXPLAYERS+1;i++)
  {
    hasAdrenaline[i]=false;
  }
  #if defined DEBUG
  prepend="[SM_WAB]";
  PrintToServer("%sstarting...",prepend);
  #endif
  HookEvent("adrenaline_used",shoot_adrenaline);
  HookEvent("infected_hurt", hurt_zombie);
}

public void on_cooldown_change(Handle convar,const char[] oldValue,const char[] newValue)
{
  float new_cooldown=StringToFloat(newValue);
  if(new_cooldown>0 && new_cooldown < 3600)
  {
    cooldown_time=new_cooldown;
    PrintToServer("%scooldown_time changed to: %f",prepend,cooldown_time);
  }
  else
  {
    PrintToServer("%sInvalid input <%s> must be a positive integer below 3600: %f\n",prepend,newValue,new_cooldown);
  }
}

public void hurt_zombie(Handle event,const char[] name, bool dontBroadcast)
{
  char nameBuf[32];
  int victim=GetEventInt(event,"entityid");
  if(GetEntityClassname(victim,nameBuf,sizeof(nameBuf)))
  {// is the enemy a witch?
    if(strcmp(nameBuf,"witch")!=0){return;}//not a witch, we don't care what happens
  }
  #if defined DEBUG
  else
  {
    PrintToServer("%sfailed to retrieve class name of infected: %d",prepend,victim);
  }
  #endif
  //get client index
  /*
  int attackerInt=GetEventInt(event,"attacker");
  int attacker_client=GetClientOfUserId(attackerInt);
  */
  int attacker_client=GetClientOfUserId(GetEventInt(event,"attacker"));//client index of the attacker
  if(IsFakeClient(attacker_client)){return;}//bots can't take advantage of this
  #if defined DEBUG
  PrintToServer("%sattacker: %N",prepend,attacker_client);
  if(IsClientInGame(attacker_client) && GetClientName(attacker_client,nameBuf,sizeof(nameBuf)))
  {
    PrintToServer("%sattacker: %s",prepend,nameBuf);
  }
  else
  {
    PrintToServer("%sfailed to retrieve client name of client: %d",prepend,attacker_client);
  }
  #endif
  //is adrenaline active?
  //if(!GetEntProp(attacker_client, Prop_Send, "m_bAdrenalineActive", 1))
  //if(hasAdrenaline[attacker_client])
  if(hasAdrenaline[attacker_client])
  {
    //get weapon type
    if( attacker_client && IsClientInGame(attacker_client) && IsPlayerAlive(attacker_client) && GetClientTeam(attacker_client) == 2 )
    {
      int weapon = GetEntPropEnt(attacker_client, Prop_Send, "m_hActiveWeapon");
      if( weapon > 0 && IsValidEntity(weapon) )
      {
        char weaponName[32];
        if(GetEntityClassname(weapon, weaponName, sizeof(weaponName)))
        {
          //is this a melee weapon?
          if(strcmp(weaponName,"weapon_melee")==0)
          {
            int damageType=GetEventInt(event,"type");
            #if defined DEBUG
            PrintToServer("%sdamageType: %d",prepend,damageType);
            #endif
            float damageVec[3]= {0.0,0.0,0.0};
            float witchPosition[3]={0.0,0.0,0.0};
            SDKHooks_TakeDamage(victim,attacker_client,attacker_client,999999.0,DMG_SLASH,weapon,damageVec,witchPosition);
            hasAdrenaline[attacker_client]=false;
            #if defined DEBUG
            PrintToServer("%sDEACTIVATED BOOST",prepend);
            #endif
          }
        }
        #if defined DEBUG
        else
        {
          PrintToServer("%sfailed to retrieve weapon name of client: %d",prepend,attacker_client);
        }
        #endif
      }
      #if defined DEBUG
      else
      {
        PrintToServer("%sinvalid weapon",prepend);
      }
      #endif
    }
  }
  #if defined DEBUG
  else
  {
    PrintToServer("%sadrenaline is not present",prepend);
  }
  #endif
}

public void shoot_adrenaline(Handle event,const char[] name, bool dontBroadcast)
{
  int aIndex=GetClientOfUserId(GetEventInt(event,"userid"));
  char clientName[32];
  GetClientName(aIndex,clientName,sizeof(clientName));
  PrintToChat(aIndex,"%sYour adrenaline boost has been activated!",prepend);
  PrintToServer("%sadrenaline boost activated for: %s",prepend,clientName);
  hasAdrenaline[aIndex]=true;
  CreateTimer(cooldown_time,disableAdrenalineBoost,GetClientSerial(aIndex));
}

public void OnClientPutInServer(int clientIndex)
{
  hasAdrenaline[clientIndex]=false;
}

public void OnClientDisconnect(int clientIndex)
{
  hasAdrenaline[clientIndex]=false;
}

public Action disableAdrenalineBoost(Handle timer,any serial)
{
  int this_client=GetClientFromSerial(serial);
  char clientName[32];

  if(!IsClientInGame(this_client) || !GetClientName(this_client,clientName,sizeof(this_client)))
  {
    #if defined DEBUG
    PrintToServer("%sfailed to retrieve client name for ID: %d",prepend,this_client);
    #endif
    return Plugin_Stop;
  }
  //the client may have had their adrenaline deactivated already by actually slashing at the witch
  if(hasAdrenaline[this_client])
  {
    hasAdrenaline[this_client]=false;
    PrintToChat(this_client,"%sYour adrenaline boost has been deactivated!",prepend);
  }
  #if defined DEBUG
  PrintToServer("%sadrenaline boost deactivated: %d",prepend,this_client);
  #endif
  if(this_client==0)
  {
    return Plugin_Stop;
  }
  return Plugin_Handled;
}

