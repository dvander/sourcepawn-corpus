#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

#define PLUGIN_NAME			"Scavenge Tank"
#define PLUGIN_AUTHOR		"Mrs. Campanula, Die Teetasse"
#define PLUGIN_DESC			"Allow to spawn tank in scavenge mode"
#define PLUGIN_VERSION		"1.0.5"
#define PLUGIN_URL			"http://forums.alliedmods.net/showthread.php?p=1009547"
#define PLUGIN_TAG			"[ScavTank]"

#define SOUND_TANK 			"./music/tank/tank.wav"

/*
Changelog:
v1.0.5;
- changed logic
	if score tied tank is enabled a tank will spawn for the second team at 15 gas cans poured in
- changed name of tank spawn command
- added horde cvars, commands etc pp
- fixed bot tank

v1.0.4:
- fixed tank spawn
- added tank music on spawn
- added chat notification on spawn
- changed convar descriptions
- changed convar flags
- added gamecheck
- added version cvar

*/

public Plugin:myinfo = 
{
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESC,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL
}

new Handle:hHordeAfterScoreTied;
new Handle:hHordeAfterOvertime;
new Handle:hHordeAfterCanCount;
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

	RegServerCmd("l4d2_scavengetank_force_tank_spawn", Server_ForceTankSpawn, "Force tank spawn");
	RegServerCmd("l4d2_scavengetank_force_horde_spawn", Server_ForceTankSpawn, "Force horde spawn");
	
	CreateConVar("l4d2_scavengetank_version", PLUGIN_VERSION, "Scavenge tank version", CVAR_FLAGS|FCVAR_DONTRECORD);

	hHordeAfterOvertime = CreateConVar("l4d2_scavengetank_spawn_horde_after_overtime", "1", "Spawn horde after first overtime", CVAR_FLAGS);
	hHordeAfterScoreTied = CreateConVar("l4d2_scavengetank_spawn_horde_after_score_tied", "1", "Spawn horde after score tied (only for second team)", CVAR_FLAGS);
	hHordeAfterCanCount = CreateConVar("l4d2_scavengetank_spawn_horde_after_cans_count", "0", "Spawn horde after specified count of poured cans ( 0 to disable )", CVAR_FLAGS);
	hTankAfterOvertime = CreateConVar("l4d2_scavengetank_spawn_tank_after_overtime", "0", "Spawn tank after first overtime", CVAR_FLAGS);
	hTankAfterScoreTied = CreateConVar("l4d2_scavengetank_spawn_tank_after_score_tied", "0", "Spawn tank after score tied (only for second team)", CVAR_FLAGS);
	hTankAfterCanCount = CreateConVar("l4d2_scavengetank_spawn_tank_after_cans_count", "5", "Spawn tank after specified count of poured cans ( 0 to disable )", CVAR_FLAGS);
	
	SetRandomSeed(GetTime());
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
		if(GetConVarBool(hHordeAfterOvertime))
			SpawnHorde();
			
		if(GetConVarBool(hTankAfterOvertime))
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
	if(GetConVarBool(hHordeAfterScoreTied))
		SpawnHorde();
		
	if(GetConVarBool(hTankAfterScoreTied))
		SpawnTank();
		
	return Plugin_Continue;
}

public Action:Event_GasCanPourCompleted(Handle:event, String:name[], bool:nobroadcast)
{
	nGasCount++;
	
	if(nGasCount == 15 && !bFirstTeam)
	{
		if (GetConVarBool(hHordeAfterScoreTied))
			SpawnHorde();
	
		if (GetConVarBool(hTankAfterScoreTied))
			SpawnTank();
	}

	new hordecount = GetConVarInt(hHordeAfterCanCount);	
	new tankcount = GetConVarInt(hTankAfterCanCount);

	if(hordecount > 0 && (nGasCount % hordecount == 0))
		SpawnHorde();
	
	if(tankcount > 0 && (nGasCount % tankcount == 0))
		SpawnTank();
	
	return Plugin_Continue;
}

public Action:Server_ForceHordeSpawn(args)
{
	SpawnHorde();
	return Plugin_Continue;
}

public Action:Server_ForceTankSpawn(args)
{
	SpawnTank();
	return Plugin_Continue;
}

public SpawnHorde()
{
	PrintToChatAll("%s A horde spawned! Pay attention!", PLUGIN_TAG);
	
	new flags = GetCommandFlags("z_spawn");
	
	for(new i = 1; i <= MaxClients; i++)
	{	
		if(!IsClientConnected(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(GetClientTeam(i) != 2) continue;
		
		SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
		FakeClientCommand(i, "z_spawn mob auto");
		SetCommandFlags("z_spawn", flags);
		break;
	}
} 

public SpawnTank()
{
	PrintToChatAll("%s A tank spawned! Be ready!", PLUGIN_TAG);
	
	new newtank;
	new newtanks[MaxClients];
	new tankcounter = 0;
	new bool:all_inf_alive = true;
	
	for(new i = 1; i <= MaxClients; i++)
	{	
		if(!IsClientConnected(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		
		//if infected save id for kill to take over tank bot
		if(GetClientTeam(i) == 3)
		{
			/*
			Dead:
				Alive: 0
				Ghost: 0
				LifeState: 1

			Waiting:
				Alive: 0
				Ghost: 0
				LifeState: 2
				
			Spawning:
				Alive: 1
				Ghost: 1
				LifeState: 0
				
			Alive:
				Alive: 1
				Ghost: 0
				LifeState: 0
			*/
			if (!IsPlayerAlive(i) || GetEntProp(i, Prop_Send, "m_isGhost") == 1) all_inf_alive = false;
			else 
			{
				newtanks[tankcounter] = i;
				tankcounter++;
			}
		}
	}

	//Tank bot fix
	if (all_inf_alive && tankcounter > 0)
	{	
		//choose tank
		new choice = GetRandomInt(0, tankcounter-1);
		newtank = newtanks[choice];
		PrintToChatAll("Choice: %d", choice);
		
		//move to spec and back
		ChangeClientTeam(newtank, 1);
		ChangeClientTeam(newtank, 3);
	}
		
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