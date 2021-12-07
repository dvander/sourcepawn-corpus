/*
enforceteamplay.sp

Description:
	Enforces team play by punishing players who do not stick together

Versions:
	0.8
		* Initial Release

*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "0.8"

#define NORMAL_DELAY 2.5

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Enforce Team Play",
	author = "dalto",
	description = "Enforces team play by punishing players who do not stick together",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Handle:g_hTimerList[MAXPLAYERS + 1];
new Handle:g_hPunishList[MAXPLAYERS + 1];
new g_timerCount[MAXPLAYERS + 1];
new g_caughtCount[MAXPLAYERS + 1];
new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarRadius = INVALID_HANDLE;
new Handle:g_CvarPollCount = INVALID_HANDLE;
new Handle:g_CvarPollsNeeded = INVALID_HANDLE;
new Handle:g_CvarPollTime = INVALID_HANDLE;
new Handle:g_CvarPunishInterval = INVALID_HANDLE;
new Handle:g_CvarDamageAmount = INVALID_HANDLE;
new iHealth;

public OnPluginStart()
{
	CreateConVar("sm_enforce_team_play_version", PLUGIN_VERSION, "Enforce Team Play Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarEnable = CreateConVar("sm_enforce_team_play_enable", "1", "Set to 0 to disable ETP");
	g_CvarRadius = CreateConVar("sm_enforce_team_play_radius", "800", "The radius to check for a player being away from team mates");
	g_CvarPollCount = CreateConVar("sm_enforce_team_play_poll_count", "10", "the amount of times a players position is polled");
	g_CvarPollsNeeded = CreateConVar("sm_enforce_team_play_polls_needed", "5", "The number of times he is found outside of the radius to be punished");
	g_CvarPollTime = CreateConVar("sm_enforce_team_play_poll_time", "0.5", "The polling interval");
	g_CvarPunishInterval = CreateConVar("sm_enforce_team_play_punish_interval", "2.5", "The frequency of the punishment");
	g_CvarDamageAmount = CreateConVar("sm_enforce_team_play_damage_amount", "5", "The amount of damage to do");

	// Execute the config file
	AutoExecConfig(true, "enforceteamplay");
	
	iHealth = FindSendPropOffs("CBasePlayer", "m_iHealth");

	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);
}

public Action:EventRoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsValidHandle(g_hTimerList[i]))
		{
			CloseHandle(g_hTimerList[i]);
		}
		if(IsValidHandle(g_hPunishList[i]))
		{
			CloseHandle(g_hPunishList[i]);
		}
	}
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// check to see if there is an outstanding handle from last round
	if(IsValidHandle(g_hTimerList[client]))
	{
		CloseHandle(g_hTimerList[client]);
	}

	if(IsValidHandle(g_hPunishList[client]))
	{
		CloseHandle(g_hPunishList[client]);
	}

	if(!GetConVarBool(g_CvarEnable))
	{
		return Plugin_Continue;
	}

	// get the players position and start the timing cycle	
	g_hTimerList[client] = CreateTimer(NORMAL_DELAY, CheckSoloTimer, client);
	
	return Plugin_Continue;
}

public Action:CheckSoloTimer(Handle:timer, any:client)
{
	// check to make sure the client is still connected
	if(!IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if(!IsFakeClient(client))
	{
		//PrintToChatAll("CheckSoloTimer");
	}
	if(IsSolo(client))
	{
		// it looks like this person is solo, time to get serious
		g_caughtCount[client] = 0;
		g_timerCount[client] = 1;
		g_hTimerList[client] = CreateTimer(GetConVarFloat(g_CvarPollTime), CaughtSoloTimer, client);
	}
	else {
		g_hTimerList[client] = CreateTimer(NORMAL_DELAY, CheckSoloTimer, client);
	}
	return Plugin_Handled;
}

public bool:IsSolo(client)
{
	new bool:foundTeammate = false;
	new bool:foundPlayer = false;
	new Float:playerPos[3];
	new Float:clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && IsPlayerAlive(i) && i != client)
		{
			foundTeammate = true;
			GetClientAbsOrigin(i, playerPos);
			if(GetVectorDistance(playerPos, clientPos) < GetConVarInt(g_CvarRadius))
			{
				foundPlayer = true;
			}
		}
	}
	if(!foundPlayer && foundTeammate)
	{
		return true;
	}
	return false;
}

public Action:CaughtSoloTimer(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if(!IsFakeClient(client))
	{
		//PrintToChatAll("CaughtSoloTimer");
	}
	new Float:currentPos[3];	
	GetClientAbsOrigin(client, currentPos);
	if(g_timerCount[client] < GetConVarInt(g_CvarPollCount))
	{
		if(IsPlayerAlive(client) && IsSolo(client))
		{
			g_caughtCount[client]++;
		}
		g_timerCount[client]++;
		g_hTimerList[client] = CreateTimer(1.0, CaughtSoloTimer, client);
	} else {
		if(g_caughtCount[client] >= GetConVarInt(g_CvarPollsNeeded) && IsPlayerAlive(client) && IsSolo(client))
		{
			decl String:name[30];
			GetClientName(client, name, sizeof(name));
			for(new i = 1; i <= GetMaxClients(); i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client))
				{
					PrintToChat(i, "%s is being punished for their selfish actions", name);
				}
			}
			PrintCenterText(client, "You are being punished by Enforce Team Play");
			DamagePlayer(client);
			g_hPunishList[client] = CreateTimer(GetConVarFloat(g_CvarPunishInterval), DamageTimer, client);
		} else {
			g_hTimerList[client] = CreateTimer(NORMAL_DELAY, CheckSoloTimer, client);
		}
	}
	
	return Plugin_Handled;
}

public Action:DamageTimer(Handle:timer, any:client)
{
	if(!IsFakeClient(client))
	{
		//PrintToChatAll("DamageTimer");
	}
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(IsSolo(client))
		{
			DamagePlayer(client);
			g_hPunishList[client] = CreateTimer(GetConVarFloat(g_CvarPunishInterval), DamageTimer, client);
		} else {
			g_hTimerList[client] = CreateTimer(NORMAL_DELAY, CheckSoloTimer, client);
		}
	}
}

DamagePlayer(client)
{
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new targetHealth = GetEntData(client, iHealth) - GetConVarInt(g_CvarDamageAmount);
		SetEntData(client, iHealth, targetHealth > 1 ? targetHealth : 1);
	}
}
