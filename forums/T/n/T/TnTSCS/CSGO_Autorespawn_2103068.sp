#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <colors>

new bool:respawn = false;
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
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
}

public OnMapEnd()
{
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
}

public Action:Command_Respawn(client, args)
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
	if (respawn)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(0.3, RespawnPlayer, GetClientSerial(client));
	}
}

public Event_Round_Freeze_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	respawn = true;
	
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}

	g_hTimer = CreateTimer(30.0, RespawnTime);
	
	CPrintToChatAll("[Server Name] Auto-Respawn: Enabled");
}

public Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (respawn)
	{
		respawn = false;
		
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
	if (respawn)
	{
		new client = GetClientFromSerial(serial);
		
		if (client != 0)
		{
			CS_RespawnPlayer(client);
		}
	}
}

public Action:RespawnTime(Handle:timer)
{
	g_hTimer = INVALID_HANDLE;
	respawn = false;
	CPrintToChatAll("[Server Name] Auto-Respawn: Disabled");
}  