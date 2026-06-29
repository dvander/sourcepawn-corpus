#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <zombiereloaded>

#define PL_VERSION "1.0.0-stable"

new Handle:g_hTime = INVALID_HANDLE;
new g_Time = 15;

new bool:g_RoundEnd = false;

new g_BeamSprite = -1;
new g_HaloSprite = -1;

public Plugin:myinfo =
{
    name        = "Beacon Last Human",
    author      = "alongub",
    description = "Beacons last survivor for X seconds.",
    version     = PL_VERSION,
    url         = "http://steamcommunity.com/id/alon"
};

public OnPluginStart()
{
	g_hTime = CreateConVar("blt_time", "15", "The amount of time in seconds to beacon last survivor.", FCVAR_PLUGIN);
	HookConVarChange(g_hTime, OnTimeCvarChange);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	HookEvent("player_death", Event_PlayerDeath);
	
	AutoExecConfig(true);
}

public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/bomb_planted_ring.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo.vtf");
}

public OnTimeCvarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_Time = GetConVarInt(cvar);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new humans = 0;
	new zombies = 0;
	
	new client = -1;

	for (new i = 1; i < GetMaxClients(); ++i)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
			continue;

		if (ZR_IsClientHuman(i))
		{
			humans++;
			client = i;
		}
		else if (ZR_IsClientZombie(i))
		{
			zombies++;
		}
	}

	if (zombies > 0 && humans == 1 && client != -1)
	{
		CreateTimer(1.0, Timer_Beacon, client, TIMER_REPEAT);
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundEnd = false;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundEnd = true;
}

public Action:Timer_Beacon(Handle:timer, any:client)
{
	static times = 0;
	
	if (g_RoundEnd)
	{
		times = 0;
		return Plugin_Stop;
	}
	
	if (times < g_Time)
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		
		vec[2] += 10;
	
		TE_SetupBeamRingPoint(vec, 10.0, 190.0, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 5.0, 0.0, {0, 0, 255, 255}, 10, 0);
		TE_SendToAll();

		EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN);
		times++;

		PrintCenterTextAll("Last human is under beacon for %d seconds.", (g_Time - times));
	}
	else
	{
		times = 0;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}