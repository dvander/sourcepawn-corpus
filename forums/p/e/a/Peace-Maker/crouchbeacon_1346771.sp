#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define TEAM_T 2
#define TEAM_CT 3

#define BEACON_RADIUS 375.0

#define PLUGIN_VERSION "1.0"

new g_RedColor[4] = {255, 75, 75, 255};
new g_BlueColor[4] = {75, 75, 255, 255};

new g_BeamSprite = -1;
new g_HaloSprite = -1;

new Handle:g_CVCrouchTime = INVALID_HANDLE;

new Handle:g_TimerCrouching[MAXPLAYERS+2] = {INVALID_HANDLE,...};

public Plugin:myinfo = 
{
	name = "Crouch Beacon",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Add a beacon to crouching players",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	CreateConVar("sm_crouchbeacon_version", PLUGIN_VERSION, "Crouch Beacon version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_CVCrouchTime = CreateConVar("sm_crouchbeacon_time", "5", "Amount of time in seconds a player needs to crouch to get baconized.", FCVAR_PLUGIN, true, 0.0);
}

public OnMapStart()
{
	PrecacheSound("buttons/blip1.wav", true);
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Player is crouching?
	if(buttons & IN_DUCK)
	{
		// Just started to crouch?
		if(g_TimerCrouching[client] == INVALID_HANDLE)
		{
			g_TimerCrouching[client] = CreateTimer(GetConVarFloat(g_CVCrouchTime), Timer_OnShowBeacon, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		// He stopped crouching - Stop beacon
		if(g_TimerCrouching[client] != INVALID_HANDLE)
		{
			CloseHandle(g_TimerCrouching[client]);
			g_TimerCrouching[client] = INVALID_HANDLE;
		}
	}
}

public Action:Timer_OnShowBeacon(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		g_TimerCrouching[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	
	new iTeam = GetClientTeam(client);
	if(iTeam < TEAM_T)
	{
		g_TimerCrouching[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10; // don't display beacon in the floor ;)
	
	// display beacon
	if(iTeam == TEAM_T)
	{
		TE_SetupBeamRingPoint(vec, 10.0, BEACON_RADIUS, g_BeamSprite, g_HaloSprite, 
			0, 10, 1.0, 10.0, 0.0, g_RedColor, 0, 0);
	}
	else if(iTeam == TEAM_CT)
	{
		TE_SetupBeamRingPoint(vec, 10.0, BEACON_RADIUS, g_BeamSprite, g_HaloSprite, 
			0, 10, 1.0, 10.0, 0.0, g_BlueColor, 0, 0);
	}
	TE_SendToAll();
	
	GetClientEyePosition(client, vec);
	EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN);
	
	g_TimerCrouching[client] = CreateTimer(2.0, Timer_OnShowBeacon, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}