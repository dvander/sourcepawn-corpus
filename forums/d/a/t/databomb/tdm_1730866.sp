#include <sourcemod>
#include <sdktools>

#define PLGN_VRSN "1.0.0"

public Plugin:myinfo =
{
	name = "ND Team Deathmatch", 
	author = "databomb", 
	description = "Provides a one-life variant for Team Deathmatch on Nuclear Dawn servers", 
	version = PLGN_VRSN, 
	url = "http://vintagejailbreak.org"
};

#define TEAM_EMPIRE		3
#define TEAM_CONSORT	2
#define TEAM_SPEC		1

new g_WinsEmpire = 0;
new g_WinsConsort = 0;

new Handle:gH_Cvar_MinTime = INVALID_HANDLE;
new Handle:gH_Cvar_WaveInterval = INVALID_HANDLE;
new bool:g_bDeathThisRound = false;

public OnPluginStart()
{
	HookEvent("round_end", RoundEnd);
	HookEvent("player_death", PlayerDeath);
	HookEvent("round_win", CheckWins);
	HookEvent("round_start", RoundEnd);
	
	gH_Cvar_MinTime = FindConVar("nd_spawn_min_time");
	
	SetConVarBounds(gH_Cvar_MinTime, ConVarBound_Upper, true, 500.0);
	SetConVarBounds(gH_Cvar_MinTime, ConVarBound_Lower, true, 1.0);
	
	new flags = GetConVarFlags(gH_Cvar_MinTime);
	flags &= (~FCVAR_NOTIFY);
	SetConVarFlags(gH_Cvar_MinTime, flags);
	
	gH_Cvar_WaveInterval = FindConVar("nd_spawn_wave_interval");
	
	flags = GetConVarFlags(gH_Cvar_WaveInterval);
	flags &= (~FCVAR_NOTIFY);
	SetConVarFlags(gH_Cvar_WaveInterval, flags);
	
	SetConVarBounds(gH_Cvar_WaveInterval, ConVarBound_Upper, true, 500.0);
	SetConVarBounds(gH_Cvar_WaveInterval, ConVarBound_Lower, true, 1.0);
}

public OnConfigsExecuted()
{
	SetConVarFloat(gH_Cvar_MinTime, 2.0);
	SetConVarFloat(gH_Cvar_WaveInterval, 3.0);
}

// For the first round
public OnMapStart()
{
	g_WinsConsort = 0;
	g_WinsEmpire = 0;
	
	g_bDeathThisRound = false;
	SetConVarFloat(gH_Cvar_MinTime, 2.0);
	SetConVarFloat(gH_Cvar_WaveInterval, 3.0);
}

public CheckWins(Handle:event, const String:name[], bool:dontBroadcast)
{
	new winner = GetEventInt(event, "team");
	if (winner == TEAM_CONSORT)
	{
		g_WinsConsort++;
	}
	else if (winner == TEAM_EMPIRE)
	{
		g_WinsEmpire++;
	}
}

public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bDeathThisRound = false;
	SetConVarFloat(gH_Cvar_MinTime, 2.0);
	SetConVarFloat(gH_Cvar_WaveInterval, 3.0);
	
	PrintToChatAll("Wins | Empire: %d | Consortium %d", g_WinsEmpire, g_WinsConsort);
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bDeathThisRound)
	{
		g_bDeathThisRound = true;
		SetConVarFloat(gH_Cvar_MinTime, 299.0);
		SetConVarFloat(gH_Cvar_WaveInterval, 300.0);
	}
	
	// check if the kill was to someone on the other team
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// check if anyone else is alive
	new ConsortAlive, EmpireAlive;
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		if (IsClientInGame(idx) && IsPlayerAlive(idx) && idx != victim)
		{
			new team = GetClientTeam(idx);
			if (team == TEAM_CONSORT)
			{
				ConsortAlive++;
			}
			else if (team == TEAM_EMPIRE)
			{
				EmpireAlive++;
			}
		}
	}
	
	PrintToChatAll("Left Alive | Consortium %d | Empire %d", ConsortAlive, EmpireAlive);
	
	if (!ConsortAlive || !EmpireAlive)
	{
		new team = GetClientTeam(victim);
		new iEntity = -1;
		while ((iEntity = FindEntityByClassname(iEntity, "struct_transport_gate")) != -1)
		{
			if (IsValidEntity(iEntity))
			{
				if (team == GetEntProp(iEntity, Prop_Send, "m_iTeamNum"))
				{
					AcceptEntityInput(iEntity, "Kill");
				}
			}
		}
	}
}

public OnClientConnected(client)
{
	new TotalPeople = 0;
	for (new index = 1; index <= MaxClients; index++)
	{
		if (IsClientInGame(index))
		{
			TotalPeople++;
		}
	}
	
	if (TotalPeople <= 1)
	{
		SetConVarFloat(gH_Cvar_MinTime, 2.0);
		SetConVarFloat(gH_Cvar_WaveInterval, 3.0);
	}
}