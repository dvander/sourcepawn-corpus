#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.1"

new Handle:hTimer = INVALID_HANDLE;
new Handle:hSurvivorLimit = INVALID_HANDLE;
new Handle:hInfectedLimit = INVALID_HANDLE;
new Handle:hL4DPlayersKick = INVALID_HANDLE;
new Handle:hL4DPlayersDelay = INVALID_HANDLE;
new Handle:hL4DPlayersTimer = INVALID_HANDLE;
new Handle:hL4DSurvivorLimit = INVALID_HANDLE;
new Handle:hL4DInfectedLimit = INVALID_HANDLE;

new prevTime = 0;
new spawnCount = 0;
new bool:startInit = false;
new bool:flagSpawn = false;
new Float:fSpawnOrigin[3];


public Plugin:myinfo = {
	name = "L4D Players",
	author = "NiCo-op",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://nico-op.forjp.net/"
};

public OnPluginStart()
{
	CreateConVar("l4d_players_version",
		PLUGIN_VERSION,
		"L4D Players",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD
	);

	hL4DSurvivorLimit = CreateConVar(
		"l4d_survivor_limit",
		"10",
		" none ",
		FCVAR_NOTIFY,
		true,
		0.0,
		true,
		32.0
	);

	hL4DInfectedLimit = CreateConVar(
		"l4d_infected_limit",
		"20",
		" none ",
		FCVAR_NOTIFY,
		true,
		0.0,
		true,
		32.0
	);

	hL4DPlayersKick = CreateConVar(
		"l4d_players_kick",
		"0.1",
		" none ",
		FCVAR_NOTIFY,
		true,
		0.0,
		true,
		1.0
	);

	hL4DPlayersTimer = CreateConVar(
		"l4d_players_timer",
		"0.75",
		" none ",
		FCVAR_NOTIFY,
		true,
		0.0,
		true,
		1.0
	);

	hL4DPlayersDelay = CreateConVar(
		"l4d_players_delay",
		"13",
		" none ",
		FCVAR_NOTIFY,
		true,
		0.0,
		true,
		60.0
	);

	hSurvivorLimit = FindConVar("survivor_limit");
	SetConVarBounds(hSurvivorLimit, ConVarBound_Upper, true, 32.0);
	hInfectedLimit = FindConVar("z_max_player_zombies");
	SetConVarBounds(hInfectedLimit, ConVarBound_Upper, true, 32.0);

	HookConVarChange(hL4DSurvivorLimit, L4DSurvivorLimit);
	HookConVarChange(hL4DInfectedLimit, L4DInfectedLimit);
	HookConVarChange(hSurvivorLimit, L4DSurvivorLimit);
	HookConVarChange(hInfectedLimit, L4DInfectedLimit);

	HookEvent("round_start_post_nav", OnRoundStartPostNav);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("finale_vehicle_leaving", OnFinaleVehicleLeaving);
	HookEvent("round_end", OnRoundEnd);
}

public L4DSurvivorLimit(Handle:convar, const String:oldValue[], const String:newValue[]){
	SetConVarInt(hSurvivorLimit, GetConVarInt(hL4DSurvivorLimit), true, false);
}
public L4DInfectedLimit(Handle:convar, const String:oldValue[], const String:newValue[]){
	SetConVarInt(hInfectedLimit, GetConVarInt(hL4DInfectedLimit), true, false);
}

public OnMapEnd()
{
	startInit = false;
	flagSpawn = false;
}

public Action:OnRoundStartPostNav(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!startInit){
		startInit = true;
		spawnCount = 0;
		prevTime = GetTime();
		hTimer = CreateTimer(GetConVarFloat(hL4DPlayersTimer),
			TimerAddSurvivor, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	startInit = false;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(spawnCount < 4){
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client && IsValidEntity(client) && GetClientTeam(client) == 2){
			flagSpawn = true;
			GetClientAbsOrigin(client, fSpawnOrigin);
		}
	}
	return Plugin_Continue;
}

public Action:OnFinaleVehicleLeaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	new index = FindEntityByClassname(-1, "info_survivor_position");
	if(index != -1){
		decl Float:fOrigin[3];
		GetEntPropVector(index, Prop_Send, "m_vecOrigin", fOrigin);
		new max = GetMaxClients();
		for(new i=1; i<=max; i++){
			if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2){
				TeleportEntity(i, fOrigin, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}

	return Plugin_Continue;
}

public Action:TimerKickFakeClient(Handle:timer, any:client)
{
	if(client && IsClientConnected(client) && IsFakeClient(client)){
		KickClient(client, "AddSurvivor");
	}
	return Plugin_Stop;
}

public AddSurvivor(){
	new bot = CreateFakeClient("Not in Ghost.");
	if(bot){
		ChangeClientTeam(bot, 2);
		DispatchKeyValue(bot, "classname", "SurvivorBot");
		DispatchSpawn(bot);
		if(IsValidEntity(bot)){
			if(flagSpawn){
				TeleportEntity(bot, fSpawnOrigin, NULL_VECTOR, NULL_VECTOR);
			}
			else{
				new max = GetMaxClients();
				for(new i=1; i <= max; i++){
					if(IsClientConnected(i)
					  && IsClientInGame(i)
					  && IsPlayerAlive(i)
					  && GetClientTeam(i) == 2){
						flagSpawn = true;
						GetClientAbsOrigin(i, fSpawnOrigin);
						TeleportEntity(bot, fSpawnOrigin, NULL_VECTOR, NULL_VECTOR);
						break;
					}
				}
			}
		}
		new Float:delay = GetConVarFloat(hL4DPlayersKick);
		if(delay <= 0.0){
			KickClient(bot, "AddSurvivor");
		}
		else{
			CreateTimer(delay, TimerKickFakeClient, bot);
		}
	}
}

public Action:TimerAddSurvivor(Handle:timer, any:client)
{
	if(hTimer != timer){
		PrintToServer("INFO:L4D Players is called");
		return Plugin_Stop;
	}

	new delay = GetConVarInt(hL4DPlayersDelay);
	new time = GetTime() - prevTime;
	if(time < 0 || !prevTime){
		prevTime = GetTime();
		return Plugin_Continue;
	}

	if(time < delay){
		PrintToServer("WAIT:L4D Players:(delay:%d/%d)", time, delay);
		return Plugin_Continue;
	}

	new count = GetTeamClientCount(2);
	if(count < 4){
		PrintToServer("WAIT:L4D Players:(spawn:%d/4)", count);
		return Plugin_Continue;
	}

	if(spawnCount < 4 && count >= 4){
		spawnCount = 4;
	}

	new limit = GetConVarInt(hL4DSurvivorLimit);
	while(count < limit && spawnCount < limit){
		count++;
		spawnCount++;
		AddSurvivor();
		PrintToServer("INFO:L4D Players:(spawn:%d:%d/%d)", count, spawnCount, limit);
		return Plugin_Continue;
	}
	PrintToServer("END:L4D Players:(spawn:%d:%d/%d)", count, spawnCount, limit);
	return Plugin_Stop;
}
