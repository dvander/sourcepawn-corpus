/**********************************************
* File Name: C_AWPBlocker.sp
-----------------------------------------------
* Author: Cooty - David Kutnar
* Update: 13.01.2013
* Game: Counter-Strike : Source
* Plugin Version: 1.3.0.0
* Addon: SourceMod v1.4.2.0
-----------------------------------------------
* Copyright Cooty © 2013
**********************************************/

// Include headers:
#include <sourcemod>

// Plugin information:
public Plugin:myinfo = 
{
	name = "AWP Blocker",
	author = "Cooty",
	description = "AWP per Team Blocker.",
	version = "1.3.0.0",
	url = "",
};

// Handles:
new Handle:g_CvarOne = INVALID_HANDLE;
new Handle:g_CvarTwo = INVALID_HANDLE;
new Handle:g_CvarThree = INVALID_HANDLE;

// Plugin initialization.
public OnPluginStart()
{
	// Hook  start of the round:
	HookEvent("round_start", Event_RoundStart);
	
	// Initialize cvars form cfg file:
	g_CvarOne = CreateConVar("c_awpblocker_one", "10", "One AWP per team from players count?");
	g_CvarTwo = CreateConVar("c_awpblocker_two", "20", "Two AWP's per team from players count?");
	g_CvarThree = CreateConVar("c_awpblocker_three", "28", "Three AWP's per team from players count?");
	
	// Execute the config file:
	AutoExecConfig(true, "C_AWPBlocker");
}

// Round start event.
public Action:Event_RoundStart(Handle:event, const String:name[], bool:broadcast) 
{
	// Get active players on server:
	new pl_count = GetPlayersCount();

	// Check if players count is bigger than zero:
	if (pl_count > 0)
	{
		if (pl_count >= GetConVarInt(g_CvarOne) && pl_count < GetConVarInt(g_CvarTwo) && pl_count < GetConVarInt(g_CvarThree))
		{ 
			ServerCommand("sm_restrict awp 1"); 
			PrintToChatAll("\x01[\x04SM\x01]\x05 AWP per team: 1");
		}
		else if (pl_count >= GetConVarInt(g_CvarTwo) && pl_count < GetConVarInt(g_CvarThree))
		{ 
			ServerCommand("sm_restrict awp 2"); 
			PrintToChatAll("\x01[\x04SM\x01]\x05 AWP per team: 2");
		}
		else if (pl_count >= GetConVarInt(g_CvarThree))
		{ 
			ServerCommand("sm_restrict awp 3"); 
			PrintToChatAll("\x01[\x04SM\x01]\x05 AWP per team: 3");
		}
	}

	// Stop plugin activity:
	return Plugin_Stop;
} 

// Getting number of connected players:
GetPlayersCount()
{
	new players;
	
	// For all players on the server:
	for (new i = 1; i <= MaxClients; i++)
	{
		// Check if player is not spectator, is in game & isnot a bot:
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
		{ players++; }
	}
	
	// Return final value:
	return players;
}
