// ABOUT THE PLUGIN
/*
plugin details:
- sets a health and speed randomly!
- 3rd plugin i ever made!
---
plugin includes
- sdktools
- sourcemod
- sdktools_functions

---
plugin defines
- witch_spawn
- PLUGIN_VERSION == 1.0

---
contacts
- christiandeacon@aol.com

---
bugs
- none

---
helpers
- {NONE}

---
testers
- NONE

---
author
- gamemann

--- 
plugin version
- 1.0

---
thats all hope you enjoy my plugin!
*/







//includes
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

//defines
#define witch_spawn
#define PLUGIN_VERSION "1.0"


//Handles
new Handle:WitchHealth = INVALID_HANDLE;
new Handle:WitchSpeed = INVALID_HANDLE;
new Handle:WitchHealthTimer = INVALID_HANDLE;
new Handle:WitchSpeedTimer = INVALID_HANDLE;
new Handle:Enabled = INVALID_HANDLE;

//floats
new Float:RandomHealth
new Float:RandomSpeed


/*
version history:

1.0:
- release
*/

public Plugin:myinfo =
{
	name = "l4d2 witch spawned stuff",
	author = "gamemann",
	description = "when a witch is spawned new stuff comes out",
	version = PLUGIN_VERSION,
	url = "sourcemod.net"
};

public OnPluginStart()
{
	//convars
	CreateConVar("sm_plugin_version", PLUGIN_VERSION, "the version of the plugin!", FCVAR_NOTIFY);
	Enabled = CreateConVar("sm_enabled", "1", "if the plugin is enabled or not");
	//Hooking events
	HookEvent("witch_spawn", Event_Witch_Spawn);
	HookEvent("player_spawn", Event_witch_details);
	WitchHealth = FindConVar("z_witch_health");
	WitchSpeed = FindConVar("z_witch_speed");
}

public Event_Witch_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	WitchSpeedTimer = CreateTimer(0.4, WitchSpeedTimerT, TIMER_REPEAT);
	WitchHealthTimer = CreateTimer(0.5, WitchHealthTimerT, TIMER_REPEAT);
}

public Action:WitchSpeedTimerT(Handle:htimer)
{
	static NumPrinted = 0
	if (NumPrinted++ <= 2)
	{
			RandomSpeed = GetRandomInt(1, 500)
			SetConVarInt(WitchSpeed, RandomSpeed)
			NumPrinted = 0
	}
	return Plugin_Continue;
}

public Action:WitchHealthTimerT(Handle:htimer)
{
     static NumPrinted = 0
	if (NumPrinted++ <= 2)
	{
			RandomHealth = GetRandomInt(1, 100000)
			SetConVarInt(WitchHealth, RandomHealth)
			NumPrinted = 0
	}
	return Plugin_Continue;
}

public Event_witch_details(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(Enabled)) {
	PrintToChatAll("this server run randomwitchrun so the health and sppeed is random!");
	}
	return Plugin_Handled;
}
	



	
