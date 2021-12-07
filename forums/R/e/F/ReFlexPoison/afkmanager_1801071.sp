#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"

#define TAG "\x04[AFK Manager]\x01"

new Handle:cvarAFKEnabled;
new Handle:cvarAFKTime;
new Handle:cvarAFKLogs;
new Handle:Version;

new Float:p_Position[MAXPLAYERS+1][3];
new p_AFKTime[MAXPLAYERS+1];
new bool:p_AFKWarned[MAXPLAYERS+1] = { false, ... };

new Handle:h_TimerAFKView;
new Handle:h_TimerAFKCheck;

public Plugin:myinfo =
{
	name = "AFK Manager",
	author = "ReFlexPoison",
	description = "Manage afk players with custom configurations.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net",
}

public OnPluginStart()
{
	Version = CreateConVar("sm_afkmanager_version", PLUGIN_VERSION, "Deathrun Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD);
	
	cvarAFKEnabled = CreateConVar("sm_afkmanager_enabled", "1", "Enable AFK manager.\n0 = Disabled\n1 = Slay\n2 = Kick", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvarAFKTime = CreateConVar("sm_afkmanager_time", "90.0", "Time in seconds before handling an AFK player.", FCVAR_PLUGIN, true, 30.0);
	cvarAFKLogs = CreateConVar("sm_afkmanager_logs", "1", "Enable logs of AFK handles.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookEvent("player_spawn", OnPlayerSpawn);
	
	AutoExecConfig(true, "plugin.afkmanager");
}

public OnConfigsExecuted()
{
	SetConVarString(Version, PLUGIN_VERSION);
	h_TimerAFKView = CreateTimer(7.0, Timer_UpdateView, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	h_TimerAFKCheck = CreateTimer(2.0, Timer_CheckPlayers, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	ClearTimer(h_TimerAFKView);
	ClearTimer(h_TimerAFKCheck);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	p_AFKWarned[client] = false;
}

public Action:Timer_CheckPlayers(Handle:Timer)
{
	if(!GetConVarBool(cvarAFKEnabled))
	{
		return Plugin_Continue;
	}
	for(new i = 1; i < MaxClients; i++)
	{
		if(!IsValidClient(i) || IsFakeClient(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		CheckForAFK(i);
		HandleAFKClient(i);
	}
	return Plugin_Continue;
}

public Action:Timer_UpdateView(Handle:Timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || IsFakeClient(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		GetPlayerEye(i, p_Position[i]);
	}
}

stock IsValidClient(client, bool:replaycheck = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}
	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}

stock ClearTimer(&Handle:timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

stock HandleAFKClient(client)
{
	CheckForAFK(client);
	if(p_AFKTime[client] >= RoundToZero(GetConVarFloat(cvarAFKTime) - 15) && !p_AFKWarned[client])
	{
		if(GetConVarInt(cvarAFKEnabled) == 2)
		{
			PrintToChat(client, "%s You are about to be kicked for inactivity!", TAG);
		}
		else if(GetConVarInt(cvarAFKEnabled) == 1)
		{
			PrintToChat(client, "%s You are about to be slayed for inactivity!", TAG);
		}
		p_AFKWarned[client] = true;
	}
	if(p_AFKTime[client] >= RoundToZero(GetConVarFloat(cvarAFKTime)))
	{
		p_AFKTime[client] = 0;
		if(GetConVarInt(cvarAFKEnabled) == 2)
		{
			PrintToChat(client, "%s You were kicked for inactivity!", TAG);
			KickClient(client, "[AFK Manager] You were kicked for being afk too long", TAG);
			if(GetConVarBool(cvarAFKLogs))
			{
				LogMessage("%N was kicked for inactivity.", client);
			}
		}
		if(GetConVarInt(cvarAFKEnabled) == 1)
		{
			PrintToChat(client, "%s You were slayed for inactivity!", TAG);
			ForcePlayerSuicide(client);
			if(GetConVarBool(cvarAFKLogs))
			{
				LogMessage("%N was slayed for inactivity.", client);
			}
		}
	}
}

stock GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3];
	new Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

stock CheckForAFK(client)
{
	new Float:f_Loc[3];
	new bool:f_SamePlace[3];
	GetPlayerEye(client, f_Loc);
	for(new i = 0; i < 3; i++)
	{
		if(p_Position[client][i] == f_Loc[i])
		{
			f_SamePlace[i] = true;
		}
		else
		{
			f_SamePlace[i] = false;
		}
	}
	if((f_SamePlace[0] && f_SamePlace[1] && f_SamePlace[2]))
	{
		p_AFKTime[client]++;
	}
	else
	{
		p_AFKTime[client] = 0;
		p_AFKWarned[client] = false;
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients();
}