#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
	name = "Hide radar the dead player",
	author = "Drumanid",
	version = "1.0.1",
	url = "Discord: Drumanid#9108"
};

ConVar g_hCvar;

public void OnPluginStart()
{
	if(!(g_hCvar = FindConVar("sv_disable_radar")))
		SetFailState("No found cvar: sv_disable_radar");

	#define HOOKEVENT(%0,%1) HookEvent(%0, view_as<EventHook>(%1));
	HOOKEVENT("player_spawn", Event_PlayerSpawn)
	HOOKEVENT("player_death", Event_PlayerDeath)
	HOOKEVENT("player_team", Event_PlayerTeam)
}

#define ON "0"
#define OFF "1"

#define RADAR(%0) \
{ int iClient = GetClientOfUserId(hEvent.GetInt("userid")); \
if(!IsFakeClient(iClient)) g_hCvar.ReplicateToClient(iClient, %0); }

void Event_PlayerSpawn(Event hEvent)
	RADAR(ON)

void Event_PlayerDeath(Event hEvent)
	RADAR(OFF)

void Event_PlayerTeam(Event hEvent)
{
	if(hEvent.GetInt("team") < 2)
		RADAR(OFF)
}