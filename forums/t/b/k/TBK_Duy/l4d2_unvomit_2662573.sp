#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY

new Handle:g_hVomit;
ConVar RemoveVomitTime;

public Plugin:myinfo =
{
	name = "[L4D2] Unvomit",
	author = "SilverShot, TBK Duy",
	description = "Removes the vomit effect from a survivor",
	version = "1.1",
	url = "http://forums.alliedmods.net/showthread.php?t=185653"
}

public OnPluginStart()
{
	new Handle:hGameConf = LoadGameConfigFile("l4d2_unvomit");
	if( hGameConf == INVALID_HANDLE )
	{
		SetFailState("Failed to load gamedata: l4d2_unvomit.txt");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTerrorPlayer::OnITExpired") == false )
		SetFailState("Failed to find signature: CTerrorPlayer::OnITExpired");
	g_hVomit = EndPrepSDKCall();
	if( g_hVomit == INVALID_HANDLE )
		SetFailState("Failed to create SDKCall: CTerrorPlayer::OnITExpired");

	HookEvent("player_now_it", Event_GetVomited, EventHookMode_Post);
	
	RemoveVomitTime = CreateConVar("l4d2_removevomittime", "1.0", "Add random number (0 don't work srly)");
	
	AutoExecConfig(true, "l4d2_removevomittime");
}

public void Event_GetVomited(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		CreateTimer(GetConVarFloat(RemoveVomitTime), RemoveVomit, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action RemoveVomit(Handle timer,int client)
{
	Unvomited(client);
}

public Action:Unvomited(int client)
{
	if(client && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		SDKCall(g_hVomit, client);
	}
	return Plugin_Handled;
}

