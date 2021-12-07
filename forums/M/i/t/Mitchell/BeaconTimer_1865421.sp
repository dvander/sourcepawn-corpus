//Beacon Timer!
//Made by Pigophone
//Version 1.4

#include <sdktools>


#define TEAM_T 2
#define TEAM_CT 3
// Sounds
#define SOUND_BLIP		"buttons/blip1.wav"
#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE

// Following are model indexes for temp entities
new g_BeamSprite		= -1;
new g_HaloSprite		= -1;

// Basic color arrays for temp entities
new redColor[4]		= {255, 75, 75, 255};
new greenColor[4]	= {75, 255, 75, 255};
new blueColor[4]	= {75, 75, 255, 255};
new greyColor[4]	= {128, 128, 128, 255};

new Handle:BeaconTimer;
new Handle:cvarPluginEnable = INVALID_HANDLE;
new Handle:cvarTime = INVALID_HANDLE;
new Handle:cvarPlayersToActivate = INVALID_HANDLE;
new Handle:g_Cvar_BeaconRadius = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Pigophones Beacon Timer",
	author = "Pigophone, Edited By Mitch.",
	description = "Pigophones Beacon Timer",
	version = "1.4",
	url = ""
};

public OnPluginStart()
{
	HookEvent("round_start", SetTimerFunc);
	HookEvent("round_end", KillTimerFunc);
	cvarPluginEnable = CreateConVar("sm_beacontimer_enabled", "1", "Enables and Disables The Timer", _, true, 0.0, true, 1.0);
	cvarTime = CreateConVar("sm_beacontimer_time", "60.0", "Wait time for the Timer", _, true, 5.0, true, 600.0);
	cvarPlayersToActivate = CreateConVar("sm_beacontimer_playerstoactivate", "0", "How many players are needed for the Timer to be activated", _, true, 0.0, true, 1.0);
	g_Cvar_BeaconRadius = CreateConVar("sm_beacontimer_radius", "375", "Sets the radius for beacon's light rings.", 0, true, 50.0, true, 1500.0);
}
 
public SetTimerFunc(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarPluginEnable))
	{	
		if(GetPlayerCount() >= GetConVarInt(cvarPlayersToActivate))
		{
			if(BeaconTimer != INVALID_HANDLE)
			{
				KillTimer(BeaconTimer);
				BeaconTimer = INVALID_HANDLE;
			}
			BeaconTimer = CreateTimer(GetConVarFloat(cvarTime), BeaconAll);
		}
	}
}


public KillTimerFunc(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(BeaconTimer != INVALID_HANDLE)
	{
		KillTimer(BeaconTimer);
		BeaconTimer = INVALID_HANDLE;
	}
}


public Action:BeaconAll(Handle:timer)
{
	//ServerCommand("sm_beacon @alive");
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i))
			CreateTimer(1.0, Timer_Beacon, GetClientUserId(i), DEFAULT_TIMER_FLAGS);	
	
	BeaconTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

GetPlayerCount()
{
    new players;
    for (new i = 1; i <= MaxClients; i++)
    {
		if (IsClientInGame(i))
		    players++;
    }
    return players;
}  


public OnMapStart()
{
	PrecacheSound(SOUND_BLIP, true);

	if (GuessSDKVersion() == SOURCE_SDK_LEFT4DEAD2)
	{
		g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	}
	else
	{
		g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	}
	
}

public Action:Timer_Beacon(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	new team = GetClientTeam(client);

	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
	TE_SendToAll();
	
	if (team == 2)
	{
		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	}
	else if (team == 3)
	{
		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
	}
	else
	{
		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 10, 0);
	}
	
	TE_SendToAll();
		
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	
		
	return Plugin_Continue;
}