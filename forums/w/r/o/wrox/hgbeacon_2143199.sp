#pragma semicolon 1
#include <sdktools>

#define SOUND_BLIP		"buttons/blip1.wav"

new g_BeamSprite		= -1;
new g_HaloSprite		= -1;

new bool:g_RoundEnd = false;
new bool:g_BeaconOn = false;

new redColor[4]		= {255, 75, 75, 255};

new Handle:BeaconTimer;
new Handle:cvarPluginEnable = INVALID_HANDLE;
new Handle:cvarTime = INVALID_HANDLE;
new Handle:g_Cvar_BeaconRadius = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "HG Beacon",
	author = "Johnny",
	description = "Beacons remaining players when appropriate",
	version = "1.01"
};

public OnPluginStart()
{
	HookEvent("round_start", EventRoundStart);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd);
	cvarPluginEnable = CreateConVar("sm_beacontimer_enabled", "1", "Enables and Disables The Timer", _, true, 0.0, true, 1.0);
	cvarTime = CreateConVar("sm_beacontimer_time", "1.0", "Wait time for the Timer", _, true, 5.0, true, 600.0);
	g_Cvar_BeaconRadius = CreateConVar("sm_beacontimer_radius", "375", "Sets the radius for beacon's light rings.", 0, true, 50.0, true, 1500.0);
	
	CreateTimer(1.0, TimeChecker, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimeChecker(Handle:timer)
{
	if(GetPlayerCount() < 3 && GetPlayerCount() > 1)
	{
		if (!g_BeaconOn)
		{
			BeaconTimer = CreateTimer(GetConVarFloat(cvarTime), BeaconAll);
		}
	}
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundEnd = false;
	g_BeaconOn = false;
}
 
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarPluginEnable))
	{
		if(GetPlayerCount() <= 1)
		{
			if(BeaconTimer != INVALID_HANDLE)
			{
				KillTimer(BeaconTimer);
				BeaconTimer = INVALID_HANDLE;
			}
		}
		
		if(GetPlayerCount() < 3 && GetPlayerCount() > 1)
		{
			if (!g_BeaconOn)
			{
				BeaconTimer = CreateTimer(GetConVarFloat(cvarTime), BeaconAll);
			}
		}
	}
}


public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundEnd = true;
	g_BeaconOn = false;
	
	if(BeaconTimer != INVALID_HANDLE)
	{
		KillTimer(BeaconTimer);
		BeaconTimer = INVALID_HANDLE;
	}
}

public Action:BeaconAll(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) >= 2)
		{
			CreateTimer(1.0, Timer_Beacon, GetClientUserId(i), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			g_BeaconOn = true;
		}
	}
	BeaconTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public OnMapStart()
{
	PrecacheSound(SOUND_BLIP, true);
	g_BeamSprite = PrecacheModel("materials/sprites/bomb_planted_ring.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo.vtf");
}

public OnMapEnd()
{
	g_RoundEnd = true;
	g_BeaconOn = false;
	
	if(BeaconTimer != INVALID_HANDLE)
	{
		KillTimer(BeaconTimer);
		BeaconTimer = INVALID_HANDLE;
	}
}

public Action:Timer_Beacon(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (g_RoundEnd)
	{
		return Plugin_Stop;
	}
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && 0 < client <= MaxClients)
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;
		
		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
		
		TE_SendToAll();
		
		GetClientEyePosition(client, vec);
		EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);
	}
	return Plugin_Continue;
}

stock GetPlayerCount()
{
	new players;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) >= 2)
		{
			players++;
		}
	}
	return players;
}