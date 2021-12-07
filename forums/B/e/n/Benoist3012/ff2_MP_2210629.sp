#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define FF2 "freak_fortress_2"
new Handle:FF2Enabled;
new Handle:FF2MP_MinCharge = INVALID_HANDLE;
new bool:RoundStart;

#define PLUGIN_VERSION "0.0.1"

public Plugin:myinfo=
{
	name="Freak Fortress 2: Luigi's Mansion Ghost Abilittypack",
	author="Benoist3012",
	description="FF2: Luigi's Mansion Ghost",
	version=PLUGIN_VERSION
};
public OnMapStart()
{
	//RoundCounter = 0;
}
public OnPluginStart()
{
	LogMessage("===Freak Fortress 2 More Possibility -v%s===\n*\n*\n*             Created by Benoist3012             \n*\n*\n*=====================================================", PLUGIN_VERSION);
	AddCommandListener( Command_Taunt, "taunt");
	AddCommandListener( Command_Taunt, "+taunt");
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("teamplay_round_win", event_round_end);
	FF2MP_MinCharge = CreateConVar("ff2_required_charge", "0.5", "Change the min percent of uber required for spawn a Heavy", FCVAR_NOTIFY, true, 0.5, true, 1.0);
}
public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(FF2Enabled))
	{
		RoundStart = true;
	}
}
public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(FF2Enabled))
	{
		RoundStart = false;
	}
}
public Action:Command_Taunt(iClient, const String:strCommand[], nArgs)
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if(TF2_GetPlayerClass(iClient) == TFClass_Medic && GetConVarBool(FF2Enabled))
	{
		if(strncmp(mapname, "vsh_", 4, false) == 0 || (strncmp(mapname, "arena_", 6, false) == 0) || (strncmp(mapname, "koth_", 5, false) == 0))
		{
			new medigun=GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
			decl String:mediclassname[64];
			if(IsValidEdict(medigun) && GetEdictClassname(medigun, mediclassname, sizeof(mediclassname)) && !strcmp(mediclassname, "tf_weapon_medigun", false))
			{
				new Charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
				new ReqCharge=RoundToFloor(GetConVarFloat(FF2MP_MinCharge)*100);
				if(Charge>=ReqCharge && !TF2_IsPlayerInCondition(iClient, TFCond_Ubercharged))
				{
					new dead = GetRandomDeadPlayer();
					if(dead != -1)
					{
						decl Float:position[3];
						GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", position);
						SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 0.0);
						TF2_RespawnPlayer(dead);
						if (TF2_GetPlayerClass(dead) != TFClass_Heavy) TF2_SetPlayerClass(dead, TFClass_Heavy);
						TF2_RegeneratePlayer(dead);
						TeleportEntity(dead, position, NULL_VECTOR, NULL_VECTOR);
						AttachParticle(dead, "merasmus_spawn");
						CreateTimer(0.5, Timer_BleedDead, dead, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action:Timer_BleedDead(Handle:hTimer, any:iClient)
{
	if(!RoundStart)
		return Plugin_Stop;
	if(!IsClientInGame(iClient))
		return Plugin_Stop;
	if(!IsPlayerAlive(iClient))
		return Plugin_Stop;
	TF2_MakeBleed(iClient, iClient, 0.3);
	return Plugin_Continue;
}
public OnAllPluginsLoaded()
{
	FF2Enabled = FindConVar("ff2_enabled");
}
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, FF2))
	{
		FF2Enabled = FindConVar("ff2_enabled");
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, FF2))
	{
		FF2Enabled = INVALID_HANDLE;
	}
}
public TF2_OnConditionAdded(client, TFCond:condition)
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if(GetConVarBool(FF2Enabled) && condition==TFCond_Buffed)
	{
		if(strncmp(mapname, "vsh_", 4, false) == 0 || (strncmp(mapname, "arena_", 6, false) == 0) || (strncmp(mapname, "koth_", 5, false) == 0))
		{
			TF2_AddCondition(client, TFCond:TFCond_CritCanteen, -1.0);
		}
	}
}
public TF2_OnConditionRemoved(client, TFCond:condition)
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if(GetConVarBool(FF2Enabled) && condition==TFCond_Buffed)
	{
		if(strncmp(mapname, "vsh_", 4, false) == 0 || (strncmp(mapname, "arena_", 6, false) == 0) || (strncmp(mapname, "koth_", 5, false) == 0))
		{
			TF2_RemoveCondition(client, TFCond:TFCond_CritCanteen);
		}
	}
}
stock GetRandomDeadPlayer()
{
	new clients[MaxClients+1], clientCount;
	for(new i=1;i<=MaxClients;i++)
	{
		if (IsValidEdict(i) && IsClientConnected(i) && IsClientInGame(i) && !IsPlayerAlive(i) && (GetClientTeam(i) > 1))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}
stock AttachParticle(entity, String:particleType[], Float:offset[]={0.0,0.0,0.0}, bool:attach=true)
{
	new particle=CreateEntityByName("info_particle_system");

	decl String:targetName[128];
	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[0]+=offset[0];
	position[1]+=offset[1];
	position[2]+=offset[2];
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(10.0, DeleteParticle, particle);
	return particle;
}
public Action:DeleteParticle(Handle:timer, any:Ent)
{
	if (!IsValidEntity(Ent)) return;
	new String:cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "info_particle_system", false)) AcceptEntityInput(Ent, "Kill");
	return;
}