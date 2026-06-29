#include <sceneprocessor>
#pragma semicolon 1
#include <sourcemod>


#define WARN_BOOMER "WarnBoomer"
#define WARN_SMOKER "WarnSmoker"
#define WARN_SPITTER "WarnSpitter"
#define WARN_CHARGER "WarnCharger"
#define WARN_TANK "WarnTank"

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8

#define PLUGIN_VERSION "1.6"


public Plugin:myinfo =
{
	name = "[L4D2] Special Infected Warnings Vocalize Fix",
	author = "DeathChaos25",
	description = "Fixes the 'I heard a (Insert Special Infected here)' warning lines not working for some specific Special Infected.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2189049",
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn_Event);
	CreateConVar("l4d2_si_warnings_vocalize_fix_version", PLUGIN_VERSION, "[L4D2] Special Infected Warnings Vocalize Fix", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public PlayerSpawn_Event(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	static iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || GetClientTeam(iClient) != 3)
		return;

	if(!IsFakeClient(iClient) && GetEntProp(iClient, Prop_Send, "m_isGhost", 1))
		return;

	static String:sAnnounceSpecial[PLATFORM_MAX_PATH];//keep string in memory can help at peaktimes

	/* What Special should the survivors warn for having heard? */
	switch(GetEntProp(iClient, Prop_Send, "m_zombieClass"))
	{
		case ZOMBIECLASS_BOOMER:
			sAnnounceSpecial = WARN_BOOMER;
		case ZOMBIECLASS_SMOKER:
			sAnnounceSpecial = WARN_SMOKER;
		case ZOMBIECLASS_CHARGER:
			sAnnounceSpecial = WARN_CHARGER;
		case ZOMBIECLASS_SPITTER:
			sAnnounceSpecial = WARN_SPITTER;
		case ZOMBIECLASS_TANK:
			sAnnounceSpecial = WARN_TANK;
		case ZOMBIECLASS_HUNTER, ZOMBIECLASS_JOCKEY:
			return;
	}

	/* Only one survivor will actually be picked to Vocalize
	*  Once a survivor who meets all of the criteria is found,
	*  he/she will warn and the loop will terminate */

	/* Because we don't want to always pick the first client index
	*  that matches all criteria, we use a percentage chance to
	*  possibly skip over it instead of always choosing the first positive*/
	for(new i = 1; i <= MaxClients; i++)
	{
		static random;
		random = GetRandomInt(1,4);
		if (!IsSurvivor(i) || !IsPlayerAlive(i) || IsActorBusy(i) || random != 1)
			continue;

		PerformSceneEx(i, sAnnounceSpecial, _, 0.0);
		break;
	}
}

static bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}