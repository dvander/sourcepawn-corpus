#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2_direct>

#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))
#define PLUGIN_VERSION "1.1" 
new Handle:SkillTimer[MAXPLAYERS+1] 	= {	INVALID_HANDLE, ...};
new Handle:ShakeTimer[MAXPLAYERS+1] 	= {	INVALID_HANDLE, ...};
new bool:g_kick[MAXPLAYERS+1];
new bool:g_shake[MAXPLAYERS+1];

public Plugin:myinfo =
{
    name = "Fighting",
    author = "Chi_Nai",
    description = "Kick Zombie and Wrestling Tips",
    version = PLUGIN_VERSION,
    url = "N/A"
}
public OnPluginStart()
{
	HookEvent("player_spawn", Player_Spawn)
}
public OnClientConnected(client)
{
	if(!IsFakeClient(client))
	{
                g_kick[client] = true;
                g_shake[client] = true;
        	if(SkillTimer[client] != INVALID_HANDLE)
        	{
	        	KillTimer(SkillTimer[client]);
	         	SkillTimer[client] = INVALID_HANDLE;
           	}
           	if(ShakeTimer[client] != INVALID_HANDLE)
          	{
	         	KillTimer(ShakeTimer[client]);
	          	ShakeTimer[client] = INVALID_HANDLE;
        	}
	}
}
public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
        	if(SkillTimer[client] != INVALID_HANDLE)
        	{
	        	KillTimer(SkillTimer[client]);
	         	SkillTimer[client] = INVALID_HANDLE;
           	}
           	if(ShakeTimer[client] != INVALID_HANDLE)
          	{
	         	KillTimer(ShakeTimer[client]);
	          	ShakeTimer[client] = INVALID_HANDLE;
        	}
	}
}
public Action:Player_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))

	if (client > 0 && client <= GetMaxClients())
	{
		if (IsValidEntity(client) && IsClientInGame(client))
		{
			if (GetClientTeam(client) == 2)
			{
                               	if(SkillTimer[client] != INVALID_HANDLE)
                           	{
	                           	KillTimer(SkillTimer[client]);
	                         	SkillTimer[client] = INVALID_HANDLE;
                             	}
                            	SkillTimer[client] = CreateTimer(1.0, ukick, client, TIMER_REPEAT);
			}
		}
	}
        return;
}
public Action:OnPlayerRunCmd(client, &buttons, &impuls, Float:vel[3], Float:angles[3])
{
	if(GetClientTeam(client) == 2)
	{
                if (g_shake[client])
                {
                       if (buttons & IN_DUCK)
                       {
	                       if(!(GetEntityFlags(client) & FL_ONGROUND))
	                       {
                                       L4D2Direct_DoAnimationEvent(client, 96);
                                       g_shake[client] = false;
                                       ShakeTimer[client] = CreateTimer(0.5, Shocktimer, client);
                                       return;
	                       }
	                }
             	}
    	}
}
public Action:Shocktimer(Handle:timer, any:client)
{
        g_shake[client] = true;
        Shock(client);
	if(ShakeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(ShakeTimer[client]);
		ShakeTimer[client] = INVALID_HANDLE;
	}
}
public Action:Shock(client)
{
	if(!IsPlayerAlive(client))
	{
		return;
	}
	new Float:pos[3];
	new Float:_pos[3];
	GetClientAbsOrigin(client, _pos);
	pos[0] = _pos[0];
	pos[1] = _pos[1];
	pos[2] = _pos[2]+30.0;

	new Float:NowLocation[3];
	GetClientAbsOrigin(client, NowLocation);
	new Float:entpos[3];
	new iMaxEntities = GetMaxEntities();
	new Float:distance[3];

        ShowParticle(NowLocation, "charger_wall_impact", 0.5);
        EmitSoundToAll("animation/bombing_run_01.wav", client);

	for(new x=1; x<=MaxClients; x++)
	{
		if (IsValidClient(x))
		{
			GetEntPropVector(x, Prop_Send, "m_vecOrigin", entpos);
			if(GetVectorDistance(entpos, NowLocation) <= 200.0) Shake_Screen(x, 5.0, 1.0, 1.0);
		}
	}
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
        {
                if (IsCommonInfected(iEntity) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
                {
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
			SubtractVectors(entpos, NowLocation, distance);
			if(GetVectorLength(distance) <= 200.0)
			{
				DealDamage(client, iEntity, 100);
			}
		}
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3 && IsPlayerAlive(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, pos, distance);
				if(GetVectorLength(distance) <= 200.0)
				{
                                	if(GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
					{
				 	        DealDamage(client, i, 100, 16777280)
			         	}
                                        else
					{
				 	        DealDamage(client, i, 100)
			         	}
				}
			}
		}
	}
	return;
}
public Action:ukick(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{
                new buttons;
                buttons = GetClientButtons(client);
                if (buttons & IN_USE)
                {
                        L4D2Direct_DoAnimationEvent(client, 37);
                        g_kick[client] = true;
                        SDKUnhook(client, SDKHook_Touch, Kick_Touch);
                        SDKHook(client, SDKHook_Touch, Kick_Touch);
                }
        }
}
public Action:Kick_Touch(entity, client)
{
        if (client > GetMaxClients())
        {
	        decl String:classname[128];
	        GetEdictClassname(client, classname, 128);
	        if (StrEqual(classname, "infected", true))
	        {
                         if (g_kick[entity])
                         {
                                  DealDamage(entity, client,50, 16777280);
                                  SDKUnhook(entity, SDKHook_Touch, Kick_Touch);
                                  g_kick[entity] = false;
	                 }
                }
        }
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
                if (g_kick[entity])
                {
                        DealDamage(entity, client,50, 16777280);
                        SDKUnhook(entity, SDKHook_Touch, Kick_Touch);
                        g_kick[entity] = false;
	        }
        }
}
DealDamage(attacker=0,victim,damage,dmg_type=0)
{
	if(IsValidEdict(victim) && damage>0)
	{
		new String:victimid[64];
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new PointHurt = CreateEntityByName("point_hurt");
		if(PointHurt)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim,"targetname",victimid);
			DispatchKeyValue(PointHurt,"DamageTarget",victimid);
			DispatchKeyValueFloat(PointHurt,"Damage",float(damage));
			DispatchKeyValue(PointHurt,"DamageType",dmg_type_str);

			DispatchSpawn(PointHurt);

			AcceptEntityInput(PointHurt, "Hurt", attacker);
                        AcceptEntityInput(PointHurt, "Hurt", -1);
			RemoveEdict(PointHurt);
		}
	}
}
stock bool:IsCommonInfected(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "infected");
	}
	return false;
}
public Shake_Screen(client, Float:Amplitude, Float:Duration, Float:Frequency)
{
	new Handle:Bfw;

	Bfw = StartMessageOne("Shake", client, 1);
	BfWriteByte(Bfw, 0);
	BfWriteFloat(Bfw, Amplitude);
	BfWriteFloat(Bfw, Duration);
	BfWriteFloat(Bfw, Frequency);

	EndMessage();
}
public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
}
public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle) || IsValidEdict(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
}
