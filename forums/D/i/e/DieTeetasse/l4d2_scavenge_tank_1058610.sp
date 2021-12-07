#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

#define MAX_GASCANS 16
#define MAX_SURVIVORS 8
#define MAX_WITCHES 16

#define PLUGIN_NAME			"Scavenge Tank"
#define PLUGIN_AUTHOR		"Mrs. Campanula, Die Teetasse"
#define PLUGIN_DESC			"Allow to spawn tank in scavenge mode"
#define PLUGIN_VERSION		"1.0.11"
#define PLUGIN_URL			"http://forums.alliedmods.net/showthread.php?p=1058610"
#define PLUGIN_TAG			"[ScavTank]"

#define SOUND_TANK 			"./music/tank/tank.wav"

/*
To Do:
- changing wandering witch spawning
- changing witch spawn logic -> Trace
- spawn arrays cvar = "1, 5, 16" and "0:20, 1:20"

Changelog:
v1.0.11:
- rewrote tank logic
- little revision

v1.0.10:
- fixed bug that prevents the lottery from working

v1.0.9:
- added witch spawning (command, cvar, logic)
	if there are standing gascans without survivors and witches => spawn sitting witch
	else spawn a wandering witch at a autospawn position
- added notfication cvar
- fixed multiple count of one gas can

v1.0.8:
- fixed bugging can count on new map

v1.0.7:
- fixed possible error log for unhooking events if the gamemode changed
- (maybe) fixed tank sound

v1.0.6:
- fixed bug, where infected switched class on tank spawn without a reason

v1.0.5:
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

new Handle:hNotification;

new Handle:hHordeAfterScoreTied;
new Handle:hHordeAfterOvertime;
new Handle:hHordeAfterCanCount;

new Handle:hTankAfterScoreTied;
new Handle:hTankAfterOvertime;
new Handle:hTankAfterCanCount;

new Handle:hWitchAfterScoreTied;
new Handle:hWitchAfterOvertime;
new Handle:hWitchAfterCanCount;

new bool:bUnhook = false;
new bool:bOvertime;
new bool:bFirstTeam;
new bool:bPooredIn = false;
new nGasCount;

public OnPluginStart()
{
	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("Scavenge Tank will only work with Left 4 Dead 2!");

	RegServerCmd("l4d2_scavengetank_force_tank_spawn", Server_ForceTankSpawn, "Force tank spawn");
	RegServerCmd("l4d2_scavengetank_force_horde_spawn", Server_ForceTankSpawn, "Force horde spawn");
	RegServerCmd("l4d2_scavengetank_force_witch_spawn", Server_ForceWitchSpawn, "Force witch spawn");
	
	CreateConVar("l4d2_scavengetank_version", PLUGIN_VERSION, "Scavenge tank version", CVAR_FLAGS|FCVAR_DONTRECORD);

	hNotification = CreateConVar("l4d2_scavengetank_notifications", "1", "Notify the players when something is spawned", CVAR_FLAGS);

	hHordeAfterOvertime = CreateConVar("l4d2_scavengetank_spawn_horde_after_overtime", "1", "Spawn horde after first overtime", CVAR_FLAGS);
	hHordeAfterScoreTied = CreateConVar("l4d2_scavengetank_spawn_horde_after_score_tied", "1", "Spawn horde after score tied (only for second team)", CVAR_FLAGS);
	hHordeAfterCanCount = CreateConVar("l4d2_scavengetank_spawn_horde_after_cans_count", "0", "Spawn horde after specified count of poured cans ( 0 to disable )", CVAR_FLAGS);

	hTankAfterOvertime = CreateConVar("l4d2_scavengetank_spawn_tank_after_overtime", "0", "Spawn tank after first overtime", CVAR_FLAGS);
	hTankAfterScoreTied = CreateConVar("l4d2_scavengetank_spawn_tank_after_score_tied", "0", "Spawn tank after score tied (only for second team)", CVAR_FLAGS);
	hTankAfterCanCount = CreateConVar("l4d2_scavengetank_spawn_tank_after_cans_count", "5", "Spawn tank after specified count of poured cans ( 0 to disable )", CVAR_FLAGS);

	hWitchAfterOvertime = CreateConVar("l4d2_scavengetank_spawn_witch_after_overtime", "0", "Spawn witch after first overtime", CVAR_FLAGS);
	hWitchAfterScoreTied = CreateConVar("l4d2_scavengetank_spawn_witch_after_score_tied", "0", "Spawn witch after score tied (only for second team)", CVAR_FLAGS);
	hWitchAfterCanCount = CreateConVar("l4d2_scavengetank_spawn_witch_after_cans_count", "5", "Spawn witch after specified count of poured cans ( 0 to disable )", CVAR_FLAGS);

	SetRandomSeed(GetTime());
}

public OnMapStart()
{
	if(CheckGameMode())
	{
		HookEvent("scavenge_round_start", Event_RoundStart, EventHookMode_Pre);
		HookEvent("scavenge_round_halftime", Event_Halftime, EventHookMode_Pre);
		HookEvent("scavenge_score_tied", Event_ScoreTied, EventHookMode_Pre);
		HookEvent("begin_scavenge_overtime", Event_Overtime, EventHookMode_Pre);
		HookEvent("gascan_pour_completed", Event_GasCanPourCompleted, EventHookMode_Pre);

		PrefetchSound(SOUND_TANK);
		PrecacheSound(SOUND_TANK);
		
		bUnhook = true;
		
		//fix for roundstart be triggered befor mapstart
		bOvertime = false;
		nGasCount = 0;
		bFirstTeam = true;
	}
	
	bUnhook = false;
}

public OnMapEnd()
{
	if(bUnhook)
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
	new String:gameMode[20];
	GetConVarString(FindConVar("mp_gamemode"), gameMode, sizeof(gameMode));
	return (StrContains("scavenge", gameMode) > -1);
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
			
		if(GetConVarBool(hWitchAfterOvertime))
			SpawnWitch();	
			
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
		
	if(GetConVarBool(hWitchAfterScoreTied))
		SpawnWitch();
				
	return Plugin_Continue;
}

public Action:Event_GasCanPourCompleted(Handle:event, String:name[], bool:nobroadcast)
{
	if (bPooredIn == true) return Plugin_Continue;

	nGasCount++;
	
	if(nGasCount == 15 && !bFirstTeam)
	{
		if (GetConVarBool(hHordeAfterScoreTied))
			SpawnHorde();
	
		if (GetConVarBool(hTankAfterScoreTied))
			SpawnTank();
			
		if (GetConVarBool(hWitchAfterScoreTied))
			SpawnWitch();
	}

	new hordecount = GetConVarInt(hHordeAfterCanCount);	
	new tankcount = GetConVarInt(hTankAfterCanCount);
	new witchcount = GetConVarInt(hWitchAfterCanCount);

	if(hordecount > 0 && (nGasCount % hordecount == 0))
		SpawnHorde();
	
	if(tankcount > 0 && (nGasCount % tankcount == 0))
		SpawnTank();
		
	if(witchcount > 0 && (nGasCount % witchcount == 0))
		SpawnWitch();
	
	bPooredIn = true;
	CreateTimer(0.5, PouredInDelay);
	
	return Plugin_Continue;
}

public Action:PouredInDelay(Handle:timer, any:data)
{
	bPooredIn = false;
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

public Action:Server_ForceWitchSpawn(args)
{
	SpawnWitch();
	return Plugin_Continue;
}

public SpawnHorde()
{
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
	
	if (GetConVarInt(hNotification) == 1) PrintToChatAll("%s A horde spawned! Pay attention!", PLUGIN_TAG);
} 

public SpawnTank()
{
	new infectedAlive[MaxClients];
	new infectedAliveCount = 0;
	new infectedDead[MaxClients];
	new infectedDeadCount = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{	
		if(!IsClientConnected(i)) continue;
		if(!IsClientInGame(i)) continue;
		
		// infected?
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
			if (!IsPlayerAlive(i) || GetEntProp(i, Prop_Send, "m_isGhost") == 1)
			{
				// Dead / Waiting / Ghost
				infectedDead[infectedDeadCount] = i;
				infectedDeadCount++;
			}
			else {
				// Alive
				infectedAlive[infectedAliveCount] = i;
				infectedAliveCount++;
			}
		}
	}

	new chosenTank = -1;
	
	// Tank bot fix (if everyone is alive)
	if (infectedDeadCount < 1)
	{	
		// choose tank
		new choice = GetRandomInt(0, infectedAliveCount-1);
		chosenTank = infectedAlive[choice];
		
		// move to spec and back
		ChangeClientTeam(chosenTank, 1);
		ChangeClientTeam(chosenTank, 3);
	}
	else 
	{	
		// somebody random spawns the tank
		new choice = GetRandomInt(0, infectedDeadCount-1);
		chosenTank = infectedDead[choice];
	}
	
	// spawn tank
	new flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	FakeClientCommand(chosenTank, "z_spawn tank auto");
	SetCommandFlags("z_spawn", flags);
	
	if (GetConVarInt(hNotification) == 1) PrintToChatAll("%s A tank spawned! Be ready!", PLUGIN_TAG);
	EmitSoundToAll(SOUND_TANK);
}  

public SpawnWitch()
{
	new entitycount = GetEntityCount();
	new gascans = 0, i, j, possiblegascans = 0, survivors = 0, witches = 0;
	new bool:tempcan;
	new Float:cans[MAX_GASCANS][3], Float:entpos[MAX_GASCANS][3], Float:survivorpos[MAX_SURVIVORS][3], Float:witchespos[MAX_WITCHES][3];
	new Float:z_entpos[MAX_GASCANS], Float:z_survivorpos[MAX_SURVIVORS], Float:z_witchespos[MAX_WITCHES];
	new String:entname[50];

	// find gascans and witches
	for (i = 1; i < entitycount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, entname, sizeof(entname));

			/*
				m_iState:
					0 = standing
					2 = in survivor hands
			*/
			if (StrContains(entname, "weapon_gascan") > -1)
			{
				if (GetEntProp(i, Prop_Send, "m_iState") == 0)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos[gascans]);
				
					// save the z-coordinate (height) special
					z_entpos[gascans] = entpos[gascans][2];
					entpos[gascans][2] = 0.0;
					gascans++;
				}
			}
			
			if (StrContains(entname, "witch") > -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", witchespos[witches]);
				z_witchespos[witches] = witchespos[witches][2];
				witchespos[witches][2] = 0.0;
				witches++;
			}
		}
	}

	//PrintToChatAll("Found %d gascans and %d witches!", gascans, witches);
	
	// find survivors
	for(i = 1; i <= MaxClients; i++)
	{	
		if(!IsClientConnected(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(GetClientTeam(i) != 2) continue;
		
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", survivorpos[survivors]);
		z_survivorpos[survivors] = survivorpos[survivors][2];
		survivorpos[survivors][2] = 0.0;
		survivors++;
	}	
	
	//PrintToChatAll("Found %d survivors!", survivors);
	
	// find a gascan without survivors and witches nearby
	for (i = 0; i < gascans; i++)
	{
		tempcan = true;
	
		// survivors
		for (j = 0; j < survivors; j++)
		{
			// gascan survivor distance < 450.0 and gascan survivor height < 75.0
			if (FloatCompare(GetVectorDistance(entpos[i], survivorpos[j]), 450.0) == -1 && FloatCompare(FloatAbs(z_entpos[i] - z_survivorpos[j]), 75.0) == -1)
			{
				tempcan = false;
				break;
			}
		}

		// witches
		for (j = 0; j < witches; j++)
		{
			// gascan witch distance < 250.0 and gascan witch height < 75.0
			if (FloatCompare(GetVectorDistance(entpos[i], witchespos[j]), 250.0) == -1 && FloatCompare(FloatAbs(z_entpos[i] - z_witchespos[j]), 75.0) == -1)
			{
				tempcan = false;
				break;
			}
		}
		
		// if possible save pos
		if (tempcan == true)
		{
			cans[possiblegascans] = entpos[i];
			cans[possiblegascans][2] = z_entpos[i];
			possiblegascans++;
		}
	}
	
	//PrintToChatAll("Found %d possible gascans!", possiblegascans);
	
	new choice;
	// no possible cans?
	if (possiblegascans == 0)
	{
		// spawn wandering witch
		SpawnWitchAtPos(false);
		 
		if (GetConVarInt(hNotification) == 1) PrintToChatAll("%s A witch spawned! She is wandering around!", PLUGIN_TAG);
	}
	// spawn to gascan randomly
	else
	{
		choice = GetRandomInt(0, possiblegascans-1);
		SpawnWitchAtPos(true, cans[choice]);	
		
		if (GetConVarInt(hNotification) == 1) PrintToChatAll("%s A witch spawned! Flashlights out!", PLUGIN_TAG);
	}
	
	
}

SpawnWitchAtPos(bool:ispos, Float:pos[3] = {0.0, 0.0, 0.0})
{
	new commander = -1;
	new flags_pos, flags_spawn;

	for(new i = 1; i <= MaxClients; i++)
	{	
		if(!IsClientConnected(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(GetClientTeam(i) != 2) continue;
		
		commander = i;
		break;
	}	
	
	// no commander => no suvivors => leave
	if (commander == -1) return;

	if (ispos == true)
	{
		// change the spawn (x, y) a little bit so the witch will not spawn on top of a gas can
		pos[0] += 25.0;
		pos[1] += 25.0;
		
		// enable pos
		flags_pos = GetCommandFlags("z_spawn_const_pos");
		SetCommandFlags("z_spawn_const_pos", flags_pos & ~FCVAR_CHEAT);
		FakeClientCommand(commander, "z_spawn_const_pos %f %f %f", pos[0], pos[1], pos[2]);		
		
		// spawn
		flags_spawn = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", flags_spawn & ~FCVAR_CHEAT);
		FakeClientCommand(commander, "z_spawn witch");
		SetCommandFlags("z_spawn", flags_spawn);	
	
		// disable
		FakeClientCommand(commander, "z_spawn_const_pos");
		SetCommandFlags("z_spawn_const_pos", flags_pos);	
	}
	else
	{
		// enable wandering
		flags_pos = GetCommandFlags("witch_force_wander");
		SetCommandFlags("witch_force_wander", flags_pos & ~FCVAR_CHEAT);
		SetConVarInt(FindConVar("witch_force_wander"), 1);

		// spawn random
		flags_spawn = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", flags_spawn & ~FCVAR_CHEAT);
		FakeClientCommand(commander, "z_spawn witch auto");
		SetCommandFlags("z_spawn", flags_spawn);
		
		CreateTimer(1.0, WitchWanderingDelay);
	}
}

public Action:WitchWanderingDelay(Handle:timer)
{
		// disable wandering
		SetConVarInt(FindConVar("witch_force_wander"), 0);
		new flags_pos = GetCommandFlags("witch_force_wander");
		SetCommandFlags("witch_force_wander", flags_pos & FCVAR_CHEAT);
}