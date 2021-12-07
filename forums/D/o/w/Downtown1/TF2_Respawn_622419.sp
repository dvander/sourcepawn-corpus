#include <sourcemod>
#include <tf2>
#include <sdktools>

new Handle:RespawnTimeBlue = INVALID_HANDLE
new Handle:RespawnTimeRed = INVALID_HANDLE
new Handle:RespawnTimeEnabled = INVALID_HANDLE
new SuddenDeathMode //Are we in SuddenDeathMode boolean?
new TF2GameRulesEntity //The entity that controls spawn wave times

//TF2 Teams
const TeamBlu = 3
const TeamRed = 2

#define PLUGIN_VERSION "1.0.5"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "TF2 Fast Respawns",
	author = "WoZeR",
	description = "Fast Respawn for TF2!",
	version = PLUGIN_VERSION,
	url = "http://www.3-pg.com"
}

public OnPluginStart()
{
	RespawnTimeEnabled = CreateConVar("sm_respawn_time_enabled", "1", "Enable or disable the plugin 1=On, 0=Off", FCVAR_PLUGIN|FCVAR_NOTIFY)
	RespawnTimeBlue = CreateConVar("sm_respawn_time_blue", "10.0", "Respawn time for Blue team", FCVAR_PLUGIN|FCVAR_NOTIFY)
	RespawnTimeRed = CreateConVar("sm_respawn_time_red", "10.0", "Respawn time for Red team", FCVAR_PLUGIN|FCVAR_NOTIFY)
	
	CreateConVar("sm_respawn_time_version", PLUGIN_VERSION, "TF2 Fast Respawns Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	//Force a high respawnwavetime, doesn't work with certain maps. Left here for anyone interested.
	//SetConVarInt(FindConVar("mp_respawnwavetime"), 999) //Default 10

	//Hook the ConVar for changes
	HookConVarChange(RespawnTimeBlue, RespawnConVarChanged)
	HookConVarChange(RespawnTimeRed, RespawnConVarChanged)
	HookConVarChange(RespawnTimeEnabled, RespawnConVarChanged)
	
	HookEvent("player_death", EventPlayerDeath)
	HookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy) //Disable spawning during suddendeath. Could be fun if enabled with melee only.
	HookEvent("teamplay_round_win", EventSuddenDeath, EventHookMode_PostNoCopy) //Disable spawning during beat the crap out of the losing team mode. Fun if on :)
	HookEvent("teamplay_game_over", EventSuddenDeath, EventHookMode_PostNoCopy) //Disable spawning
	HookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy) //Enable fast spawning
}

public OnMapStart()
{
	//Find the TF_GameRules Entity
	TF2GameRulesEntity = FindEntityByClassname(-1, "tf_gamerules");
	
	if (TF2GameRulesEntity == -1)
	{
		LogToGame("Could not find TF_GameRules to set respawn wave time")
	}
}

//Player died, create a timer based on the player's team to respawn the player
public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new Float:RespawnTime = 0.0
	
	if (GetConVarBool(RespawnTimeEnabled) && SuddenDeathMode == 0) //If we are enabled and SuddenDeathMode is not running then spawn players
	{
		new PlayerTeam = GetClientTeam(client)
		if (PlayerTeam == TeamBlu)
		{
			SetRespawnTime() //Have to do this since valve likes to reset the TF_GameRules during rounds and map changes
			RespawnTime = GetConVarFloat(RespawnTimeBlue)
			PrintHintText(client, "Respawning in %.1f seconds", RespawnTime) //inform the player time to wait for respond
			CreateTimer(RespawnTime, SpawnPlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE) //Respawn the player at the specified time
		}
		else if (PlayerTeam == TeamRed)
		{
			SetRespawnTime() //Have to do this since valve likes to reset the TF_GameRules during rounds and map changes
			RespawnTime = GetConVarFloat(RespawnTimeRed)
			PrintHintText(client, "Respawning in %.1f seconds", RespawnTime) //inform the player time to wait for respond
			CreateTimer(RespawnTime, SpawnPlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE) //Respawn the player at the specified time
		}
	}
	return Plugin_Continue
}

public Action:SpawnPlayerTimer(Handle:timer, any:client)
{
	//Respawn the player if he is in game and is dead, and its not sudden death
	if(!SuddenDeathMode && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client))
	{
		TF2_RespawnPlayer(client)
	}
	return Plugin_Continue
}

//One of the Respawn ConVar's changed so update the respawn wave time
public RespawnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetRespawnTime()
}

public SetRespawnTime()
{
	if (TF2GameRulesEntity != -1)
	{
		new Float:RespawnTimeRedValue = GetConVarFloat(RespawnTimeRed)
		if (RespawnTimeRedValue >= 6.0) //Added this check for servers setting spawn time to 6 seconds. The -6.0 below would cause instant spawn.
		{
			SetVariantFloat(RespawnTimeRedValue - 6.0) //I subtract 6 to help with getting an exact spawn time since valve adds on time to the spawn wave
		}
		else
		{
			SetVariantFloat(RespawnTimeRedValue)
		}
		AcceptEntityInput(TF2GameRulesEntity, "SetRedTeamRespawnWaveTime", -1, -1, 0)
		
		new Float:RespawnTimeBlueValue = GetConVarFloat(RespawnTimeBlue)
		if (RespawnTimeBlueValue >= 6.0)
		{
			SetVariantFloat(RespawnTimeBlueValue - 6.0) //I subtract 6 to help with getting an exact spawn time since valve adds on time to the spawn wave
		}
		else
		{
			SetVariantFloat(RespawnTimeBlueValue)
		}
		AcceptEntityInput(TF2GameRulesEntity, "SetBlueTeamRespawnWaveTime", -1, -1, 0)
	}
}

public Action:EventSuddenDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Don't respawn players during sudden death mode
	SuddenDeathMode = 1
	return Plugin_Continue
}

public Action:EventRoundReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Time to respawn players again, wahoo!
	SuddenDeathMode = 0
	return Plugin_Continue
}