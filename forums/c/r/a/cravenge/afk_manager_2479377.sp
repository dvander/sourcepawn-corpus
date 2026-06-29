#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define VERSION "2.8"

float g_Position[MAXPLAYERS+1][3];
int g_TimeAFK[MAXPLAYERS+1];
ConVar g_Cvar_Enabled, g_Cvar_AdminsImmune, g_Cvar_MoveSpec,
	g_Cvar_TimeToMove, g_Cvar_TimeToKick;

public Plugin myinfo =
{
	name = "AFK Manager",
	author = "Liam",
	description = "Provides Managements To AFK Players.",
	version = VERSION,
	url = "http://www.wcugaming.org"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegisterHooks();
	RegisterCvars();
	
	AutoExecConfig(true, "afk_manager");
}

void RegisterCvars()
{
	CreateConVar("afk_manager_version", VERSION, "AFK Manager Version", FCVAR_NOTIFY);
	g_Cvar_Enabled = CreateConVar("afk_manager_enable", "1", "Enable/Disable Plugin");
	g_Cvar_AdminsImmune = CreateConVar("afk_manager_admins", "1", "Enable/Disable Admin Immunity");
	g_Cvar_MoveSpec = CreateConVar("afk_manager_sbk", "1", "Enable/Disable Spec Before Kick");
	g_Cvar_TimeToMove = CreateConVar("afk_manager_move", "60.0", "Time Before Moving AFK Players");
	g_Cvar_TimeToKick = CreateConVar("afk_manager_kick", "300.0", "Time Before Kicking AFK Players");
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			g_TimeAFK[i] = 0;
		}
	}
	
	CreateTimer(60.0, Timer_StartTimers, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_StartTimers(Handle Timer)
{
	CreateTimer(7.0, Timer_UpdateView, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(10.0, Timer_CheckPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

void RegisterHooks()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_team", OnPlayerTeam);
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}
	
	g_TimeAFK[client] = 0;
}

public Action OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}
	
	if (event.GetInt("team") > 1)
	{
		g_TimeAFK[client] = 0;
	}
}

public Action Timer_UpdateView(Handle Timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsFakeClient(i))
		{
			continue;
		}
		
		GetPlayerEye(i, g_Position[i]);
    }
	
	return Plugin_Continue;
}

public Action Timer_CheckPlayers(Handle Timer)
{
	if (!g_Cvar_Enabled.BoolValue)
	{
		return Plugin_Stop;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		
		CheckForAFK(i);
		HandleAFKClient(i);
	}
	
	return Plugin_Continue;
}

void CheckForAFK(int client)
{
	float f_Loc[3];
	bool f_SamePlace[3];
	
	if (GetClientTeam(client) > 1)
	{
		GetPlayerEye(client, f_Loc);
		
		for (int i = 0; i < 3; i++)
		{
			if (g_Position[client][i] == f_Loc[i])
			{
				f_SamePlace[i] = true;
			}
			else
			{
				f_SamePlace[i] = false;
			}
		}
	}
	
	if ((f_SamePlace[0] && f_SamePlace[1] && f_SamePlace[2]) || GetClientTeam(client) < 2)
	{
		g_TimeAFK[client] += 1;
	}
	else
	{
		g_TimeAFK[client] = 0;
	}
}

void HandleAFKClient(int client)
{
	int f_SpecTime = RoundFloat(g_Cvar_TimeToMove.FloatValue) / 10;
	int f_KickTime = RoundFloat(g_Cvar_TimeToKick.FloatValue) / 10;
	
	if (g_Cvar_MoveSpec.BoolValue && g_TimeAFK[client] < f_KickTime && g_TimeAFK[client] >= f_SpecTime)
	{
		if (GetClientTeam(client) < 2)
		{
			return;
		}
		
		Event playerAFK = CreateEvent("player_afk", true);
		playerAFK.SetInt("player", GetClientUserId(client));
		playerAFK.Fire(false);
		
		ChangeClientTeam(client, 1);
		PrintToChatAll("\x03[JBTP]\x01 Moved \x04%N\x01 To \x05Spectators Team\x01!", client);
	}
	
	CheckForAFK(client);
	
	if (g_TimeAFK[client] >= f_KickTime && !IsAdmin(client))
	{
		PrintToChatAll("\x05[-]\x01 Player \x04%N\x01 [AFK]", client);
		KickClient(client, "Kicked Due To Being AFK For Too Long!");
	}
}

bool GetPlayerEye(int client, float pos[3])
{
	float vAngles[3], vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		
		delete trace;
		return true;
	}
	
	delete trace;
	return false;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}

bool IsAdmin(int client)
{
	if (!g_Cvar_AdminsImmune.BoolValue)
	{
		return false;
	}
	
	AdminId admin = GetUserAdmin(client);
	if (admin == INVALID_ADMIN_ID)
	{
		return false;
	}
	
	return true;
}

