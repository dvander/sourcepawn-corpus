#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <colors>

new bool:g_bRespawn = false;
new Handle:g_hTimer = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("player_death",  Event_Player_Death);
	HookEvent("round_freeze_end", Event_Round_Freeze_End);
	HookEvent("round_end", Event_Round_End);
	
	RegConsoleCmd("sm_respawn", Command_Respawn);
	RegConsoleCmd("sm_rs", Command_Respawn);
}

public OnMapStart()
{
	// Let's reset the respawn timer and bool allowing respawns until a round starts.
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	
	g_bRespawn = false;
}

public OnMapEnd()
{
	OnMapStart();
}

public Action:Command_Respawn(client, args) // Allow players to type !respawn or !rs anytime to respawn themselves, added by request
{
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	CS_RespawnPlayer(client);
	
	return Plugin_Handled;
}

public Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bRespawn) // If respawn timer has not expired, respawn player
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(0.3, RespawnPlayer, GetClientSerial(client)); // Wait 0.3 seconds before respawning, just because
	}
}

public Event_Round_Freeze_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRespawn = true; // set this to true once the round starts
	
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}

	g_hTimer = CreateTimer(30.0, RespawnTime); // Create 30 second timer after freeze time has expired
	
	CPrintToChatAll("[Server Name] Auto-Respawn: Enabled");
}

public Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bRespawn) // Round ended before respawn timer finished, let's clean that up for next round
	{
		g_bRespawn = false;
		
		if (g_hTimer != INVALID_HANDLE)
		{
			KillTimer(g_hTimer);
			g_hTimer = INVALID_HANDLE;
		}
		
		CPrintToChatAll("[Server Name] Round Ended - Auto-Respawn: Disabled");
	}
}

public Action:RespawnPlayer(Handle:timer, any:serial)
{
	if (g_bRespawn) // If still allowed to respawn, let's respawn the player, if the client's serial is still valid
	{
		new client = GetClientFromSerial(serial);
		
		if (client != 0)
		{
			CS_RespawnPlayer(client);
		}
	}
	
	return Plugin_Handled;
}

public Action:RespawnTime(Handle:timer) // Respawn timer has ended, let's clean up and notify players.
{
	g_hTimer = INVALID_HANDLE;
	g_bRespawn = false;
	CPrintToChatAll("[Server Name] Auto-Respawn: Disabled");
	
	return Plugin_Handled;
}  