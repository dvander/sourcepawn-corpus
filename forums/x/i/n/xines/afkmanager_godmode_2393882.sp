#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

// global variables
new Float:g_Position[MAXPLAYERS+1][3];
new g_TimeAFK[MAXPLAYERS+1];
new g_isplaying[MAXPLAYERS+1];

// cvars
new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_TimeToMove = INVALID_HANDLE;

#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "AFK Manager Godmode",
	author = "Liam / Xines",
	description = "Handles AFK Players",
	version = VERSION,
	url = ""
};

public OnPluginStart( )
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	CreateConVar("sm_afk_god_version", VERSION, "Current version of the AFK Godmode Manager", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_Enabled = CreateConVar("sm_afkgodenable", "1", "Is the AFK Godmode manager enabled or disabled? [0 = FALSE, 1 = TRUE]");
	g_Cvar_TimeToMove = CreateConVar("sm_afkgodtime", "200.0", "Time before godmode.");
}

public OnMapStart( )
{
	for(new i = 1; i <= MaxClients; i++)
	{
		g_TimeAFK[i] = 0;
		g_isplaying[i] = 1;
	}
	CreateTimer(8.0, Timer_StartTimers, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_StartTimers(Handle:Timer)
{
	CreateTimer(1.5, Timer_UpdateView, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_CheckPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_TimeAFK[client] = 0;
}

public Action:Timer_UpdateView(Handle:Timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsRealPlayer(i) == false || IsPlayerAlive(i) == false)
		{
			continue;
		}
		GetPlayerEye(i, g_Position[i]);
	}
}

public Action:Timer_CheckPlayers(Handle:Timer)
{
	if(GetConVarInt(g_Cvar_Enabled) == 0)
		return Plugin_Stop;

	for(new i = 1; i < MaxClients; i++)
	{
		if(IsRealPlayer(i) == false)
		{
			continue;
		}
		CheckAFK(i);
		HandleAFK(i);
	}
	return Plugin_Continue;
}

CheckAFK(client)
{
	new Float:f_Loc[3];
	new f_Team = GetClientTeam(client);
	new bool:f_SamePlace[3];
	
	if(f_Team > 1)
	{
		GetPlayerEye(client, f_Loc);
		for(new i = 0; i < 3; i++)
		{
			if(g_Position[client][i] == f_Loc[i])
			{
				f_SamePlace[i] = true;
			}
			else
			{
				f_SamePlace[i] = false;
			}
		}
	}
	if((f_SamePlace[0] == true && f_SamePlace[1] == true && f_SamePlace[2] == true) || (f_Team < 2))
	{
		g_TimeAFK[client]++;
	}
	else
	{
		g_TimeAFK[client] = 0;
		if(1 >= g_isplaying[client])
		{
			PrintToChat(client, "\x04[Godmode] \x03Disappeared");
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1); // god off
			g_isplaying[client]++;
		}
	}
}

HandleAFK(client)
{
	new f_GodTime = RoundToZero(GetConVarFloat(g_Cvar_TimeToMove)) / 10;
	new f_Team = GetClientTeam(client);
	if (g_TimeAFK[client] >= f_GodTime)
	{
		if(f_Team == 2 || f_Team == 3)
		{
			PrintToChat(client, "\x04[Godmode] \x03Activated");
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); // god on
			g_isplaying[client] = 1;
		}
		return;
	}
}

bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];
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

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients( );
}

bool:IsRealPlayer(client)
{
	if(!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client))
	{
		return false;
	}
	return true;
}