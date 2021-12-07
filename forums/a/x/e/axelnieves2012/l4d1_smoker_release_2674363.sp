#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

#define INCAP_GRAB		1
#define INCAP_POUNCE	2

#define TEAM_SURVIVOR	2

int g_Attacker[MAXPLAYERS+1];
int g_IncapType[MAXPLAYERS+1];
Handle l4d1_smoker_release_enabled;

public Plugin myinfo = 
{
	name = "Smoker Release",
	author = "Axel Juan Nieves",
	description = "Smokers will release their victim on incapacitating them",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	
	CreateConVar("l4d1_smoker_release_ver", PLUGIN_VERSION, "Version of the infected release plugin.", FCVAR_DONTRECORD);
	l4d1_smoker_release_enabled = CreateConVar("l4d1_smoker_release_enabled", PLUGIN_VERSION, "Enable/Disable this plugin", 0);

	AutoExecConfig(true, "l4d1_smoker_release");
	
	HookEvent("tongue_grab", event_tongue_grab);
	HookEvent("tongue_release", event_tongue_release);
	HookEvent("lunge_pounce", event_lunge_pounce);
	HookEvent("pounce_stopped", event_pounce_stopped);
	HookEvent("player_incapacitated", event_player_incapacitated, EventHookMode_Pre);
	HookEvent("player_death", reset_stats, EventHookMode_Post);
	HookEvent("round_start", reset_stats, EventHookMode_Post);
	HookEvent("round_end", reset_stats, EventHookMode_Post);
	
}

public void reset_stats(Handle event, const char[] name, bool dontBroadcast)
{
	if ( StrEqual(name, "round_start") || StrEqual(name, "round_end") )
	{
		for (int i=1; i<=MAXPLAYERS; i++)
		{
			g_Attacker[i] = 0;
			g_IncapType[i] = 0;
		}
		return;
	}
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_Attacker[client] = 0;
	g_IncapType[client] = 0;
}

//hunter's pounce start...
public void event_lunge_pounce(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	
	g_Attacker[victim] = attacker;
	g_IncapType[victim] = INCAP_POUNCE;
}

public void event_pounce_stopped(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim")); //survivor player
	if (!victim) return;
	g_Attacker[victim] = 0;
	g_IncapType[victim] = 0;
}

//smoker grabbed someone...
public void event_tongue_grab(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	
	g_Attacker[victim] = attacker;
	g_IncapType[victim]=INCAP_GRAB;
}

//smoker released someone...
public void event_tongue_release(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int smoker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!smoker) return;
	
	//we need to check this because hunters can steal victims to smokers...
	if (g_Attacker[victim] == smoker)
	{
		g_Attacker[victim] = 0;
		g_IncapType[victim] = 0;
	}
}

public void event_player_incapacitated(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !GetConVarBool(l4d1_smoker_release_enabled) ) return;
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !IsValidClientInGame(victim) ) return;
	if ( GetClientTeam(victim)!=TEAM_SURVIVOR ) return;
	
	//check if incapped by smoker tongue...
	if ( g_IncapType[victim]&INCAP_GRAB == 0 ) 
		return;
	
	//Release victim...
	SetEntityMoveType(g_Attacker[victim], MOVETYPE_NOCLIP);
	CreateTimer(0.1, SetMovetype, g_Attacker[victim]);
}

public Action SetMovetype(Handle timer, int client)
{
	if ( !IsValidClientInGame(client) )
		return Plugin_Stop;
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	return Plugin_Stop;
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}