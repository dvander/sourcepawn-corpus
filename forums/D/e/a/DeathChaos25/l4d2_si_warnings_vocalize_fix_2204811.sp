/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* [L4D2] Special Infected Warnings Vocalize Fix
* 
* About : This plugin aims to be a simple fix for some
*  		  special infected warnings never being called upon.
* 
* =============================
* ===      Change Log       ===
* =============================
* 
* Version 1.0    2014-08-24
* - Initial Release
* 
* =============================
* 
* Version 1.1    2014-08-25
* - Added a cvar that allows to change
*   the chance of a vocalization warning.
* 
* =============================
* 
* Version 1.2	 2014-08-25
* - Added HeardBoomer, HeardSmoker and HeardTank 
*   support for L4D1 Survivors.
* 
* =============================
* 
* Version 1.3	 2014-08-26 (50+ views)
* - Added new CVARs to control the delays for how much a survivor must wait
*   being able to vocalize for hearing the same special again, and another for
*   how much a survivor should wait between different specials
* 
* =============================
* 
* Version 1.4    2014-09-11
* - Added a check to see if a survivor isn't already vocalizing before
*   attempting to warn for an infected, as nt doing so would cause the
*   vocalization to fail but still run the timer to delay for the next
*   infected warning.
* 
* =============================
* 
* Version 1.5    2014-09-28 (Original Concept by id, I optimized and cleaned it up :p)
* - Semi major code re-write, plugin now requires Modified Talker to work.
* 
* - Removed all Timers/conditions and exchanged vcd reference for a talker concept.
*   Using context in talkerfiles to apply timers and conditions to the world.
* 
* - Also removed all CVARs and thus, no cfg file is needed anymore.
* 
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


#include <sourcemod>
#include <sceneprocessor> 

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

#define PLUGIN_VERSION "1.5"

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
	HookEvent("player_spawn", PlayerSpawn_Event) 
	CreateConVar("l4d2_si_warnings_vocalize_fix_version", PLUGIN_VERSION, "[L4D2] Special Infected Warnings Vocalize Fix", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD) 
	
}

public PlayerSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")) 
	
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3) {
		return
	}
	new class = GetEntProp(client, Prop_Send, "m_zombieClass") 
	decl String:announce_special[PLATFORM_MAX_PATH] 
	
	/* What Special should the survivors warn for having heard? */
	if (class == ZOMBIECLASS_BOOMER)  announce_special = WARN_BOOMER 
	else if (class == ZOMBIECLASS_SMOKER) announce_special = WARN_SMOKER 
	else if (class == ZOMBIECLASS_CHARGER) announce_special = WARN_CHARGER 
	else if (class == ZOMBIECLASS_SPITTER) announce_special = WARN_SPITTER 
	else if (class == ZOMBIECLASS_TANK) announce_special = WARN_TANK
	
	/* Only one survivor will actually be picked to Vocalize
	*  Once a survivor who meets all of the criteria is found,
	*  he/she will warn and the loop will terminate */
	
	/* Because we don't want to always pick the first client index
	*  that matches all criteria, we use a percentage chance to
	*  possibly skip over it instead of always choosing the first positive*/
	for (new i = 1; i <= MaxClients; i++) {
		new random = GetRandomInt(1,4)
		if (IsSurvivor(i) && IsPlayerAlive(i) && !IsActorBusy(i) && random == 1) {				
			PerformSceneEx(i, announce_special, _, 2.0)
			i=MaxClients
			break 
		}
	}	
}	

stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true 
	}
	return false 
}
