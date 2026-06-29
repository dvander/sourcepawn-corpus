#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

#define PLUGIN_NAME			"Scavenge Tank"
#define PLUGIN_AUTHOR		"Mrs. Campanula, Die Teetasse"
#define PLUGIN_DESC			"Allow to spawn tank in scavenge mode"
#define PLUGIN_VERSION		"1.0.4"
#define PLUGIN_URL			"http://forums.alliedmods.net/showthread.php?p=1009547"
#define PLUGIN_TAG			"[ScavTank]"

#define SOUND_TANK 			"./music/tank/tank.wav"

/*
Changelog:
v1.0.4:
- fixed tank spawn
- added tank music on spawn
- added chat notification on spawn
- changed convar descriptions
- changed convar flags
- added gamecheck
- added version cvar

Known bugs:
- if all infected are alive a bot tank will spawn
*/

public Plugin:myinfo = 
{
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESC,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL
}

new Handle:hTankAfterScoreTied;
new Handle:hTankAfterOvertime;
new Handle:hTankAfterCanCount;

new bool:bOvertime;
new bool:bFirstTeam;
new nGasCount;

public OnPluginStart()
{
	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("L4D1 Versus will only work with Left 4 Dead 2!");

	RegServerCmd("l4d2_scavengetank_force_spawn", Server_ForceTankSpawn, "Force tank spawn");
	
	CreateConVar("l4d2_scavengetank_version", PLUGIN_VERSION, "Scavenge tank version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hTankAfterOvertime = CreateConVar("l4d2_scavengetank_spawn_tank_after_overtime", "0", "Spawn tank after first overtime", CVAR_FLAGS);
	hTankAfterScoreTied = CreateConVar("l4d2_scavengetank_spawn_tank_after_score_tied", "0", "Spawn tank after score tied (only for second team)", CVAR_FLAGS);
	hTankAfterCanCount = CreateConVar("l4d2_scavengetank_spawn_tank_after_cans_count", "5", "Spawn tank after specified count of poured cans ( 0 to disable )", CVAR_FLAGS);
}

public OnMapStart()
{
	if( CheckGameMode() )
	{
		HookEvent("scavenge_round_start", Event_RoundStart, EventHookMode_Pre);
		HookEvent("scavenge_round_halftime", Event_Halftime, EventHookMode_Pre);
		HookEvent("scavenge_score_tied", Event_ScoreTied, EventHookMode_Pre);
		HookEvent("begin_scavenge_overtime", Event_Overtime, EventHookMode_Pre);
		HookEvent("gascan_pour_completed", Event_GasCanPourCompleted, EventHookMode_Pre);

		PrefetchSound(SOUND_TANK);
	}
	
	
}

public OnMapEnd()
{
	if( CheckGameMode() )
	{
		UnhookEvent("scavenge_round_start", Event_RoundStart, EventHookMode_Pre);
		UnhookEvent("scavenge_round_halftime", Event_Halftime, EventHookMode_Pre);
		UnhookEvent("scavenge_score_tied", Event_ScoreTied, EventHookMode_Pre);
		UnhookEvent("begin_scavenge_overtime", Event_Overtime, EventHookMode_Pre);
		UnhookEvent("gascan_pour_completed", Event_GasCanPourCompleted, EventHookMode_Pre);
	}
}

public bool:CheckGameMode()
{
	new String:gameMode[15];
	GetConVarString(FindConVar("mp_gamemode"), gameMode, sizeof(gameMode));
	return ( StrContains("scavenge", gameMode) > -1 );
}

public Action:Event_RoundStart(Handle:event, String:name[], bool:nobroadcast)
{
	bOvertime = false;
	nGasCount = 0;
	bFirstTeam = true;
	return Plugin_Continue;
}

public Action:Event_Overtime(Handle:event, String:name[], bool:nobroadcast)
{
	if( !bOvertime )
	{
		if( GetConVarBool(hTankAfterOvertime) )
			SpawnTank();
		bOvertime = true;
	}
	return Plugin_Continue;
}

public Action:Event_Halftime(Handle:event, String:name[], bool:nobroadcast)
{
	bOvertime = false;
	nGasCount = 0;
	bFirstTeam = false;
	return Plugin_Continue;
}

public Action:Event_ScoreTied(Handle:event, String:name[], bool:nobroadcast)
{
	if( GetConVarBool(hTankAfterScoreTied) )
		SpawnTank();
	return Plugin_Continue;
}

public Action:Event_GasCanPourCompleted(Handle:event, String:name[], bool:nobroadcast)
{
	nGasCount++;
	
	if( nGasCount == 15 && GetConVarBool(hTankAfterScoreTied) && bFirstTeam )
	{
		SpawnTank();
	}
	
	new i = GetConVarInt(hTankAfterCanCount);
	if( i > 0 && (nGasCount % i == 0) )
		SpawnTank();
	
	return Plugin_Continue;
}

public Action:Server_ForceTankSpawn(args)
{
	SpawnTank();
	return Plugin_Continue;
}

public SpawnTank()
{
	PrintToChatAll("%s A tank spawned! Be ready!", PLUGIN_TAG);
	
	new flags = GetCommandFlags("z_spawn");
	
	for(new i = 1; i <= MaxClients; i++)
	{	
		if(!IsClientConnected(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(GetClientTeam(i) != 2) continue;
		
		SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
		FakeClientCommand(i, "z_spawn tank auto");
		SetCommandFlags("z_spawn", flags);
		break;
	}
	
	EmitSoundToAll(SOUND_TANK);
}  