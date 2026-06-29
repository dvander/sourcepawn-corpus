#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "2.0"

new Handle:multi = INVALID_HANDLE;
new multiplier = 2;
new bool:survival = false;
new bool:isHookedEvent = false;
new bool:isHookedCvar = false;
new bool:isHookedSpawn = false;
new survivors = -1;
new zlives = 0;

/* ChangeLog
2.00	Zombie Lives set on Player Spawn rather than PlayerCount on RoundEnd. (for better accuracy)
*/

public Plugin:myinfo = {
	name = "Zombo Lives Multiplier",
	author = "Will2Tango",
	description = "Changes mp_zombomaxlives based on a multiplier",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_zombolives_version", PLUGIN_VERSION, "Zombo Lives Multiplier Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	multi = CreateConVar("sm_zombolives_multi", "2", "Multiplier for Zombie Lives. (default = 2)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(multi,GetMultiplier);
}

public GetMultiplier(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	if (strcmp(oldValue, newValue) != 0)
	{
		//multiplier = GetConVarInt(multi);
		multiplier = StringToInt(newValue);
		if (multiplier == 2 && isHookedEvent)
		{
			UnhookEvent("game_round_restart", NewRound, EventHookMode_PostNoCopy); isHookedEvent = false;
			ServerCommand("mp_zombomaxlives -1");
		}
		else if (multiplier != 2 && !isHookedEvent)
		{
			HookEvent("game_round_restart", NewRound, EventHookMode_PostNoCopy); isHookedEvent = true;
		}
	}
}

public OnConfigsExecuted()
{
	new String:mapName[32];
	GetCurrentMap(mapName, sizeof(mapName));
	if (StrContains(mapName, "zps_", false) != -1) {survival = true;} else	{survival = false;}
	if (survival)
	{
		if (!isHookedEvent) {HookEvent("game_round_restart", NewRound, EventHookMode_PostNoCopy); isHookedEvent = true;}
		if (!isHookedCvar) {HookConVarChange(multi,GetMultiplier); isHookedCvar = true;}
	}
	else
	{
		if (isHookedEvent)
		{
			UnhookEvent("game_round_restart", NewRound, EventHookMode_PostNoCopy); isHookedEvent = false;
			ServerCommand("mp_zombomaxlives -1");
		}
		if (isHookedCvar) {UnhookConVarChange(multi,GetMultiplier); isHookedCvar = false;}
	}
}

public NewRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (multiplier != 2 && survival)
	{
		survivors = -1;
		if (!isHookedSpawn) {HookEvent("player_spawn", Event_PlayerSpawn); isHookedSpawn = true;}
	}
	else
	{
		if (isHookedSpawn) {UnhookEvent("player_spawn", Event_PlayerSpawn); isHookedSpawn = false;}
	}
}

public Action:Event_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	if (team == 2)
	{
		survivors++;
		zlives = survivors * multiplier;
		if (zlives > 1) {ServerCommand("mp_zombomaxlives %i", zlives);} else {ServerCommand("mp_zombomaxlives -1");}
	}
	else if (team == 3)
	{
		if (isHookedSpawn) {UnhookEvent("player_spawn", Event_PlayerSpawn); isHookedSpawn = false;}
	}
}

public OnPluginEnd()
{
	ServerCommand("mp_zombomaxlives -1");
}