#include <sourcemod>

#pragma newdecls required

public Plugin myinfo =  
{
	name = "[CS:GO] Dead Overlay", 
	author = "Kento from Akami Studio", 
	description = "Display overlay when player dead.", 
	version = "1.0", 
	url = "http://steamcommunity.com/id/kentomatoryoshika/"
};

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnPlayerDeath);
	
	CreateConVar("sm_dead_overlay", "", "Overlay to display.");
	CreateConVar("sm_dead_overlay_time", "5.0", "How long should overlay display?");
}

public void OnMapStart()
{
	char overlay_path[PLATFORM_MAX_PATH];
	GetConVarString(FindConVar("sm_dead_overlay"), overlay_path, sizeof(overlay_path));
	PrecacheDecal(overlay_path, true);
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	char overlay_path[PLATFORM_MAX_PATH];
	GetConVarString(FindConVar("sm_dead_overlay"), overlay_path, sizeof(overlay_path));
	SetClientOverlay(client, overlay_path);
	
	CreateTimer(GetConVarFloat(FindConVar("sm_dead_overlay_time")), DeleteOverlay, client);
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

// Code taken from csgoware 
// https://forums.alliedmods.net/showthread.php?p=2500764
bool SetClientOverlay(int client, char[] strOverlay)
{
	if (IsValidClient(client))
	{
		int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
		SetCommandFlags("r_screenoverlay", iFlags);	
		ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay);
		return true;
	}
	return false;
}

public Action DeleteOverlay(Handle tmr, any client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		SetClientOverlay(client, "");
	}
	return Plugin_Handled;
}