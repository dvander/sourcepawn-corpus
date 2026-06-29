#include <sourcemod>

new Handle:hEnable;
new Handle:hUpTime_Min, Handle:hUpTime_Max;
new Handle:hMaxPlayers;
new Handle:hWarn_ShowChat;
new bool:InRestartCountdown;
new iIdleTime;

public const Plugin:myinfo = {
	name = "Server UpTime Restarter",
	author = "CoolJosh3k",
	description = "Restarts a server after a specified uptime. Respects player counts.",
	version = "1.0.0",
	url = "https://www.TF2TightRope.com/",
}

public OnPluginStart()
{
	AutoExecConfig();
	hEnable = CreateConVar("SUR_Enable", "1", "Use this if you wish to stop plugin functions temporarily.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hUpTime_Min = CreateConVar("SUR_UpTime_Min", "86400", "Minimum time in seconds before restart attempt. Default is 1 day.", FCVAR_NONE, true, 60.0);
	hUpTime_Max = CreateConVar("SUR_UpTime_Min_Max", "259200", "Maximum time in seconds before server restart is forced, regardless of player count. Default is 3 days.", FCVAR_NONE, true, 60.0);
	hMaxPlayers = CreateConVar("SUR_MaxPlayers", "4", "Atleast this many players will cause the restart to be delayed. Spectators are not counted.", FCVAR_NONE, true, 1.0);
	hWarn_ShowChat = CreateConVar("SUR_Warn_ShowChat", "1", "Display restart warning message as a chat message.", FCVAR_NONE, true, 0.0, true, 1.0);
	CreateTimer(1.0, CheckTime, _, TIMER_REPEAT);
}

stock bool:IsValidPlayer(client)
{
	if ((client < 1) || (client > MaxClients))
	{
		return false;
	}
	if (IsClientInGame(client))
	{
		if (IsFakeClient(client))
		{
			return false;
		}
		if (IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
		if (GetClientTeam(client) < 2)	//No team or spectator
		{
			return false;
		}
	}
	else	//Client is not in the game
	{
		return false;
	}
	return true;
}

public Action:CheckTime(Handle:timer)
{
	if (GetConVarBool(hEnable) == false)
	{
		return;
	}
	if (InRestartCountdown)	//We are already going to be restarting, but we are busy still letting players know before we actually do.
	{
		return;
	}
	if (GetEngineTime() >= GetConVarInt(hUpTime_Max))	//It has been far too long. A server restart must happen.
	{
		BeginServerRestart();
		return;
	}
	if (GetEngineTime() >= GetConVarInt(hUpTime_Min))
	{
		if (GetGameTime() < 60.0)	//Give time for server to fill. It only just started a new map and might have had enough players.
		{
			iIdleTime++;	//GameTime will not start incrementing without at least 1 player, so we must account for that scenario.
			if (iIdleTime < 60)	//We have been not been idle for long enough. Someone might be coming.
			{
				return;
			}
		}
		else
		{
			iIdleTime = 0;
		}
		new TotalActivePlayers;
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsValidPlayer(client))
			{
				TotalActivePlayers++;
			}
		}
		if (TotalActivePlayers >= GetConVarInt(hMaxPlayers))
		{
			return;
		}
		else
		{
			BeginServerRestart();
			return;
		}
	}
	return;
}

public OnMapEnd()
{
	if (GetConVarBool(hEnable) == false)
	{
		return;
	}
	if (InRestartCountdown)
	{
		LogMessage("Server restart using \"Server UpTime Restarter\" on map end...");
		ServerCommand("_restart");
	}
}

//=================================//
//- Chain of timers for countdown -//


public BeginServerRestart()
{
	InRestartCountdown = true;
	if (GetConVarBool(hWarn_ShowChat))
	{
		PrintToChatAll("\x03SUR: \x04Server will perform scheduled restart in 60 seconds.");
	}
	CreateTimer(30.0, ServerRestartThirty);
}

public Action:ServerRestartThirty(Handle:timer)
{
	if (GetConVarBool(hEnable))
	{
		if (GetConVarBool(hWarn_ShowChat))
		{
			PrintToChatAll("\x03SUR: \x04Server will perform scheduled restart in 30 seconds.");
		}
		CreateTimer(20.0, ServerRestartTen);
	}
	else
	{
		InRestartCountdown = false;
	}
}

public Action:ServerRestartTen(Handle:timer)
{
	if (GetConVarBool(hEnable))
	{
		if (GetConVarBool(hWarn_ShowChat))
		{
			PrintToChatAll("\x03SUR: \x04Server will perform scheduled restart in TEN seconds.");
		}
		CreateTimer(5.0, ServerRestartFive);
	}
	else
	{
		InRestartCountdown = false;
	}
}

public Action:ServerRestartFive(Handle:timer)
{
	if (GetConVarBool(hEnable))
	{
		if (GetConVarBool(hWarn_ShowChat))
		{
			PrintToChatAll("\x03SUR: \x04Server will perform scheduled restart in FIVE seconds!");
		}
		CreateTimer(4.0, ServerRestartOne);
	}
	else
	{
		InRestartCountdown = false;
	}
}

public Action:ServerRestartOne(Handle:timer)
{
	if (GetConVarBool(hEnable))
	{
		if (GetConVarBool(hWarn_ShowChat))
		{
			PrintToChatAll("\x03SUR: \x04Server will now restart!");
		}
		CreateTimer(1.0, ServerRestartZero);
	}
	else
	{
		InRestartCountdown = false;
	}
}

public Action:ServerRestartZero(Handle:timer)
{
	if (GetConVarBool(hEnable))
	{
		LogMessage("Server restart using \"Server UpTime Restarter\"...");
		ServerCommand("_restart");
	}
	else
	{
		InRestartCountdown = false;
	}
}




