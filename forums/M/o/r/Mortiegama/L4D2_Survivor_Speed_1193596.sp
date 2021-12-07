#include <sourcemod>
#pragma semicolon 1

#define L4D2 Survivor Speed
#define PLUGIN_VERSION "1.0"

new Handle:cvarSurvivorSpeed;
static laggedMovementOffset = 0;

public Plugin:myinfo = 
{
    name = "[L4D2] Survivor Speed",
    author = "Mortiegama",
    description = "Allows custom set Survivor Speed.",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_survivorspeed_version", PLUGIN_VERSION, "Survivor Speed Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarSurvivorSpeed = CreateConVar("sm_ss_survivorspeed", "1.25", "Enables the Bonus Healing plugin (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");

	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("player_first_spawn", event_PlayerFirstSpawn);
}

public event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
		CreateTimer(0.5, Event_SurvivorSpeed, client);
	}
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
		CreateTimer(0.5, Event_SurvivorSpeed, client);
	}
}

public Action:Event_SurvivorSpeed(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
		PrintHintText(client, "Your speed has been increased!");
		SetEntDataFloat(client, laggedMovementOffset, 1.0*GetConVarFloat(cvarSurvivorSpeed), true);
	}
}

public IsValidClient(client)
{
	if (client == 0)
		return false;

	if (!IsClientConnected(client))
		return false;
	
	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;

	if (!IsValidEntity(client))
		return false;

	return true;
}


