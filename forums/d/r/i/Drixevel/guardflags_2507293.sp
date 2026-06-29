//Pragma
#pragma semicolon 1
#pragma newdecls required

//Sourcemod Includes
#include <sourcemod>
#include <tf2_stocks>

//ConVars
ConVar convar_Status;
ConVar convar_Override;

//Globals
bool betweenrounds;

public Plugin myinfo = 
{
	name = "Guard Flags", 
	author = "Keith Warren (Drixevel)", 
	description = "Blocks you from joining the guards/blue team if you don't have the necessary flags.", 
	version = "1.0.0", 
	url = "http://www.drixevel.com/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	convar_Status = CreateConVar("sm_guardflags_status", "1", "Status of the plugin.\n1 = on, 0 = off", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_Override = CreateConVar("sm_guardflags_override", "guard_override", "Override name to use.", FCVAR_NOTIFY);
	AutoExecConfig();
	
	AddCommandListener(Listener_OnTeamChange, "jointeam");
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("arena_round_start", Event_OnRoundStart);
	HookEvent("teamplay_round_win", Event_OnRoundEnd);
}

public Action Listener_OnTeamChange(int client, const char[] command, int argc)
{
	if (!GetConVarBool(convar_Status))
	{
		return Plugin_Continue;
	}
	
	char sTeam[64];
	GetCmdArg(1, sTeam, sizeof(sTeam));
	
	if (!StrEqual(sTeam, "3") && !StrEqual(sTeam, "blue"))
	{
		return Plugin_Continue;
	}
	
	if (CanJoinGuard(client))
	{
		return Plugin_Continue;
	}
	
	PrintToChat(client, "You are not allowed on the guards team.");
	return Plugin_Stop;
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(convar_Status))
	{
		return;
	}
	
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	
	if (TF2_GetClientTeam(client) == TFTeam_Blue && !CanJoinGuard(client))
	{
		if (betweenrounds)
		{
			TF2_ChangeClientTeam(client, TFTeam_Red);
			TF2_RespawnPlayer(client);
		}
		
		ForcePlayerSuicide(client);
		PrintToChat(client, "You are not allowed on the guards team.");
	}
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(convar_Status))
	{
		return;
	}
	
	betweenrounds = false;
}

public void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(convar_Status))
	{
		return;
	}
	
	betweenrounds = true;
}

bool CanJoinGuard(int client)
{
	char sOverride[MAX_NAME_LENGTH];
	GetConVarString(convar_Override, sOverride, sizeof(sOverride));
	
	return CheckCommandAccess(client, sOverride, ADMFLAG_CUSTOM6);
}