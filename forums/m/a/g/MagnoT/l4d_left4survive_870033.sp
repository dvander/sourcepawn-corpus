/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* Version History
* 0.x	- Base code.
* 1.0	- First release.
* 1.1	- Fixed lag when we have more than 4 special infected in scene
*/

#include <sourcemod>

// define
#define PLUGIN_VERSION "1.1"
#define PLUGIN_NAME "Left4Survive"

// Controls
new bool:g_bLockLimits;
new bool:g_bIsRunning;
new bool:g_bSpawned;
new g_curInfected;
new g_curSurvivors;
new g_tableCoef;

// CVars Handles
new Handle:g_hActivate		=INVALID_HANDLE;
new Handle:g_hMaxinfected	=INVALID_HANDLE;
new Handle:g_hGroupspawn	=INVALID_HANDLE;
new Handle:g_hSpawnInterval	=INVALID_HANDLE;
new Handle:g_hCoef			=INVALID_HANDLE;
new Handle:g_hMethod		=INVALID_HANDLE;
new Handle:g_hShowHint		=INVALID_HANDLE;
new Handle:g_hSpecialLimit	=INVALID_HANDLE;

// Timer handle
new Handle:g_hSpawnTimer	=INVALID_HANDLE;

// Info
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "MagnoT",
	description = "Forces Director to randomly spawn special infected (coop only)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/" //http://driftinc.co.nr
};

// Starting
public OnPluginStart()
{
	g_hActivate 		= CreateConVar("sm_l4s_enable", "1", "[L4S] Turn on/off random spawning of special infected", FCVAR_PLUGIN|FCVAR_NOTIFY);
	// Method 1 is default and has best result
	g_hMethod 			= CreateConVar("sm_l4s_method", "1", "[L4S] Method to use", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
	g_hMaxinfected 		= CreateConVar("sm_l4s_maxinfected", "4", "[L4S] Sets the maximum number of special infected", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hGroupspawn 		= CreateConVar("sm_l4s_spawngroup", "0", "[L4S] Turn on/off group spawn (if 1, group spawn will be enforced)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hSpawnInterval 	= CreateConVar("sm_l4s_spawninterval", "25.0", "[L4S] Sets the random interval", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hCoef 			= CreateConVar("sm_l4s_coefficient", "0", "[L4S] Sets a sum coefficient for the special infected limit", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hShowHint			= CreateConVar("sm_l4s_showhint", "1", "[L4S] Turn on/off death hints", FCVAR_PLUGIN|FCVAR_NOTIFY);	
	
	// Seed for random (not necessary)
	//SetRandomSeed(GetGameTime());
	
	// Init globals
	g_bLockLimits	=false;
	g_bSpawned		=false;
	g_bIsRunning	=false;
	g_curInfected	=0;
	g_tableCoef		=0;
	// To handle LXD servers
	g_curSurvivors	=RoundFloat(GetConVarFloat(FindConVar("survivor_limit"))); //4
	
	// Update 1.1, fix bad behavior for +4 special (hidden game convar)
	g_hSpecialLimit=FindConVar("z_max_player_zombies");
	SetConVarBounds(g_hSpecialLimit, ConVarBound_Upper, true, 16.0);
	SetConVarFloat(g_hSpecialLimit, 16.0, true, false);
	
	// attempt to start plugin
	PreInit();
	
	// convar changes update the plugin state
	HookConVarChange(g_hActivate, OnStateChange);
	HookConVarChange(FindConVar("mp_gamemode"), OnStateChange);
	HookConVarChange(g_hCoef, OnChangeCoef);
	
	// config file
	AutoExecConfig(true, "Left4Survive");
}

// Core
PreInit()
{
	// retrieve gamemode convar (plugin applicable for coop only)
	decl String:sGameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	
	// starting
	if(strcmp(sGameMode, "coop")==0 && GetConVarInt(g_hActivate)==1)
	{
		// timer for the switchbosses limit
		if (GetConVarInt(g_hMethod) == 1)
			g_hSpawnTimer=CreateTimer(GetConVarFloat(g_hSpawnInterval), SwitchBosses_m1, _, TIMER_REPEAT);
		else
		g_hSpawnTimer=CreateTimer(GetConVarFloat(g_hSpawnInterval), SwitchBosses_m2, _, TIMER_REPEAT);
		
		// coefficient
		g_tableCoef = GetConVarInt(g_hCoef);
		SetConVarInt(g_hMaxinfected, ((g_tableCoef+1)*4), true, false);
		
		// Server log
		PrintToServer("[L4S] Interval: %.1f", GetConVarFloat(g_hSpawnInterval));
		PrintToServer("[L4S] Max specials: %d", GetConVarInt(g_hMaxinfected));
		PrintToServer("[L4S] Coefficient: %d", GetConVarInt(g_hCoef));
		
		// Hooks
		HookEvent("round_start", Event_Reset);
		HookEvent("mission_lost", Event_Reset);
		
		if (GetConVarInt(g_hMethod) == 1)
			HookEvent("player_spawn", Event_PlayerSpawn1, EventHookMode_Pre);
		else
		HookEvent("player_spawn", Event_PlayerSpawn2, EventHookMode_Pre);
		
		HookEvent("player_death", Event_PlayerDead);
		
		// We increase the infected count for tank because it's a client too
		HookEvent("tank_spawn", Event_TankSpawn);
		HookEvent("tank_killed", Event_TankKilled);
		
		// plugin is running
		g_bIsRunning=true;
		
		// Log
		//PrintToChatAll("[L4S] Plugin is running...");
	}
	else
	{
		if(g_bIsRunning==true)
		{
			//KillTimer(g_hSpawnTimer,true);
			CloseHandle(g_hSpawnTimer);
			
			// UnHooks
			UnhookEvent("round_start", Event_Reset);
			UnhookEvent("mission_lost", Event_Reset);
			
			if (GetConVarInt(g_hMethod) == 1)
				UnhookEvent("player_spawn", Event_PlayerSpawn1, EventHookMode_Pre);
			else
			UnhookEvent("player_spawn", Event_PlayerSpawn2, EventHookMode_Pre);
			
			UnhookEvent("player_death", Event_PlayerDead);
			UnhookEvent("tank_spawn", Event_TankSpawn);
			UnhookEvent("tank_killed", Event_TankKilled);
			
			// reverting to default limits
			SetConVarInt(FindConVar("z_hunter_limit"), 1, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 1, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 1, true, false);
			SetConVarInt(FindConVar("z_ghost_group_spawn"), 1, true, false);
		}
		
		// plugin is running
		g_bIsRunning=false;
		
		// Log
		//PrintToChatAll("[L4S] Plugin is not running...");
	}
}

// CVars hooks
public OnStateChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(oldVal, newVal)!=0)
	{	
		// Re-check plugin state
		PreInit();
	}
}

public OnChangeCoef(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(oldVal, newVal)!=0)
	{	
		// coefficient
		g_tableCoef = GetConVarInt(g_hCoef);
		SetConVarInt(g_hMaxinfected, ((g_tableCoef+1)*4), true, false);
	}
}

// Limit tables, Method 1 - Director spawn using the limits
public Action:SwitchBosses_m1(Handle:hTimer)
{
	//PrintToChatAll("[L4S] Method 1 set...");
	
	if (!g_bLockLimits)
		switch(GetRandomInt(0,9))
	{
		// Common random tables: using regular limit for infected = 3
		case 0:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		0+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		1+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	2+g_tableCoef, true, false);
		}
		case 1:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		0+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		2+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	1+g_tableCoef, true, false);
		}
		case 2:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		2+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		1+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	0+g_tableCoef, true, false);
		}
		case 3:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		2+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		0+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	1+g_tableCoef, true, false);
		}
		case 4:
		{
			SetConVarInt(FindConVar("z_hunter_limit"),		1+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		0+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	2+g_tableCoef, true, false);
		}
		case 5:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		1+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		2+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	0+g_tableCoef, true, false);
		}
		
		// Regular limits +1 hunter (just for fun)
		case 6:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		2+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		1+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	1+g_tableCoef, true, false);
		}
		
		// Storm round with a single type
		case 7:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		3, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		1+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	0, true, false);
		}
		case 8:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		1+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		3, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	0, true, false);
		}
		case 9:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		1+g_tableCoef, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		0, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	3, true, false);
		}
	}
	
	// Group spawn changes too
	// When '0' Director uses time interval to spawn infected
	// so it can storm the round with infected
	// '1' cooldown the round
	if(GetConVarInt(g_hGroupspawn)!=1)
		SetConVarInt(FindConVar("z_ghost_group_spawn"), GetRandomInt(0,1), true, false);
	
}

// Limit tables, Method 2 - Plugin manually spawn
public Action:SwitchBosses_m2(Handle:hTimer)
{
	//PrintToChatAll("[L4S] Method 2 set...");
	switch(GetRandomInt(0,3))
	{
		// Common random tables: for method 2, we simply clear one type
		case 0:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		0, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		1, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	1, true, false);
		}
		case 1:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		1, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		1, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	0, true, false);
		}
		case 2:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		1, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		0, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	1, true, false);
		}
		case 3:
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 		1, true, false);
			SetConVarInt(FindConVar("z_gas_limit"), 		1, true, false);
			SetConVarInt(FindConVar("z_exploding_limit"), 	1, true, false);
		}
	}
	
	// Group spawn changes too
	// When '0' Director uses time interval to spawn infected
	// so it can storm the round with infected
	// '1' cooldown the round
	if(GetConVarInt(g_hGroupspawn)!=1)
		SetConVarInt(FindConVar("z_ghost_group_spawn"), GetRandomInt(0,1), true, false);
	
}

// Handling round start, mission fail, etc
public OnMapStart()
{
	Reset();
}

public Action:Event_Reset(Handle:event, const String:name[], bool:dontBroadcast)
{
	Reset();
	return Plugin_Continue;
}

// We reset everything including some cvars
public Reset()
{
	g_curInfected=0;
	g_bLockLimits=false;
	SetConVarInt(FindConVar("z_ghost_group_spawn"), GetConVarInt(g_hGroupspawn), true, false);
	// might help
	SetConVarInt(FindConVar("survivor_allow_crawling"), 1, true, false);
}

// =====================================================================================================
// Player handling functions
// Player Spawn: It doesn't prevent a client from spawning so we have to kick the clients
// we don't want to spawn
public Action:Event_PlayerSpawn1(Handle:event, const String:name[], bool:dontBroadcast)
{
	// get client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0) return Plugin_Continue; // won't happen!
	
	// log
	decl String:cl_name[64];
	GetClientName(client, cl_name, sizeof(cl_name));
	
	// Log
	//PrintToChatAll("[L4S] Spawning %s", cl_name);
	
	// Ignore Tank and Survivor spawn, we skip the code
	if (strcmp(cl_name, "Tank")==0 || GetClientTeam(client)==2)
		return Plugin_Continue;
	
	// Prevents app strange behavior when we have more than 4 infected on coop maps
	// If we reach 4 infected count limit, we kick next spawned bots
	// Support for regular coop: 4 survivors
	if (GetClientCount() > (g_curSurvivors+GetConVarInt(g_hMaxinfected)) && GetClientTeam(client)==3)
	{
		KickClientEx(client, "");
		//PrintToChatAll("\x05[\x01Excesso!");
		return Plugin_Handled;
	}
	
	// Count every special infected spawn so we can prevent more than the limit spawning
	if (GetClientTeam(client)==3 && strcmp(cl_name, "Tank")!=0)
	{
		// if we have more than 4 infected, kick it immediatly
		// we also lock the limits change because Director will ignore the previous
		// set limits and will keep spawning bots
		if (g_curInfected==GetConVarInt(g_hMaxinfected))
		{
			KickClientEx(client, "");
			g_bLockLimits=true;
			//PrintToChatAll("\x05[\x01Cancel spawn!");
			return Plugin_Handled;
		}
		
		// otherwise increase count
		g_curInfected++;
		g_bLockLimits=false;
		//PrintToChatAll("\x05[\x01A client attempted to spawn, %s / Clients: %d", cl_name, GetClientCount(true));
		//PrintToChatAll("\x05[\x01Currently, we have %d infected", g_curInfected);
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn2(Handle:event, const String:name[], bool:dontBroadcast)
{
	// get client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0) return Plugin_Continue; // won't happen!
	
	// log
	decl String:cl_name[64];
	GetClientName(client, cl_name, sizeof(cl_name));
	
	// Ignore Tank and Survivor spawn, we skip the code
	if (strcmp(cl_name, "Tank")==0 || GetClientTeam(client)==2)
		return Plugin_Continue;
	
	// Count every special infected spawn so we can prevent more than the limit spawning
	if (GetClientTeam(client)==3 && strcmp(cl_name, "Tank")!=0)
	{
		// if we have more than 4 infected, kick it immediatly
		// we also lock the limits change because Director will ignore the previous
		// set limits and will keep spawning bots
		if (g_curInfected==GetConVarInt(g_hMaxinfected))
		{
			KickClientEx(client, "");
			//PrintToChatAll("\x05[\x01Cancel spawn!");
			return Plugin_Handled;
		}
		
		// otherwise increase count
		g_curInfected++;
	}
	
	if (GetClientTeam(client)==3 && GetConVarInt(g_hMaxinfected)>g_curInfected &&
	strcmp(cl_name, "Tank")!=0 && g_bSpawned==false)
	{
		// add 1 or 2 more infected of the same type
		for (new i=0; i<GetRandomInt(1,2);++i)
		{
			if (StrContains(cl_name, "Hunter", true)!=-1)
				StripAndExecuteClientCommand("z_spawn", "hunter", "auto");  
			else if (StrContains(cl_name, "Boomer", true)!=-1)
				StripAndExecuteClientCommand("z_spawn", "boomer", "auto");  
			else if (StrContains(cl_name, "Smoker", true)!=-1)
				StripAndExecuteClientCommand("z_spawn", "smoker", "auto");
			
			//g_curInfected++;
		}
		
		// Sleep 2.5 for g_bSpawned return to false again
		CreateTimer(5.0, UnlockSpawn);
		g_bSpawned=true;
	}
	
	//PrintToChatAll("\x05[\x01A client attempted to spawn, %s / Clients: %d", cl_name, GetClientCount(true));
	//PrintToChatAll("\x05[\x01Currently, we have %d infected", g_curInfected);
	
	return Plugin_Continue;
}

public Action:UnlockSpawn(Handle:hTimer)
{
	g_bSpawned=false;
}

/* http://www.sourcemod.net/ */
StripAndExecuteClientCommand(const String:command[], String:param[], String:param1[]) {
	
	// Removes sv_cheat flag from command
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	
	//ClientCommand(client, "%s %s", command, param)
	//FakeClientCommand(client, "%s %s", command, param);
	ServerCommand("%s %s %s", command, param, param1)
	
	
	// Restore sv_cheat flag on command
	SetCommandFlags(command, flags);
}

// Handles the kill message and the infected counter
public Action:Event_PlayerDead(Handle:event, const String:name[], bool:dontBroadcast)
{
	// get the dead client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Handled;
	
	// log
	decl String:cl_name[64];
	GetClientName(client, cl_name, 64);
	//PrintToChatAll("\x05[\x01%s is dead", cl_name);
	
	// Kill hints
	if(GetConVarInt(g_hShowHint)!=0)
	{
		// attacker
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		decl String:aName[64];
		GetClientName(attacker, aName, sizeof(aName));
		
		// Type (victim), better than get (n)Infected >> Infected type name
		decl String:vName[64];
		GetEventString(event, "victimname", vName, sizeof(vName));
		
		// Weapon
		decl String:weapon[64];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		// death hints
		if (GetClientTeam(client)==2)
			// Survivor death
		PrintCenterTextAll("%s is dead!", cl_name);
		else if (strcmp(aName, vName)==0 || StrContains(aName, vName)!=-1)
			// Infected death with no cause
		PrintCenterTextAll("%s is dead!", vName);
		else if (strcmp(GetWeapon(weapon), "melee")==0)
			// Infected death caused by claw, melee
		PrintCenterTextAll("%s killed %s", aName, vName);
		else
		// Infected death cause by a weapon
		PrintCenterTextAll("%s killed %s with %s", aName, vName, GetWeapon(weapon));
		
	}
	// continue...
	
	// Ignore for Tank and Survivor death
	if (strcmp(cl_name, "Tank")==0 || GetClientTeam(client)==2)
		return Plugin_Continue;
	
	// Prevents app strange behavior when we have more than 4 infected on coop maps
	// decrease the infected limit counter
	if (g_curInfected > 0 || g_curInfected <= GetConVarInt(g_hMaxinfected))
	{
		if (GetClientTeam(client)==3)
		{
			g_curInfected=g_curInfected - 1 ;
			//PrintToChatAll("\x05[\x01Currently, we have %d infected", g_curInfected);
		}
	}
	return Plugin_Continue;
}

String:GetWeapon(const String:weapon[])
{
	// pistol
	// dual_pistols
	// smg
	// rifle
	// pumpshotgun
	// autoshotgun
	// hunting_rifle
	// "" = melee
	
	decl String:out[32];
	
	if (strcmp(weapon, "pistol")==0)
	{
		out = "Pistol";
		return out;
	} else if (strcmp(weapon, "dual_pistols")==0)
	{
		out = "Pistols";
		return out;
	} else if (strcmp(weapon, "smg")==0)
	{
		out = "Sub Machinegun";
		return out;
	} else if (strcmp(weapon, "rifle")==0)
	{
		out = "Colt Rifle";
		return out;
	} else if (strcmp(weapon, "pumpshotgun")==0)
	{
		out = "Pump Shotgun";
		return out;
	} else if (strcmp(weapon, "autoshotgun")==0)
	{
		out = "Automatic Shotgun";
		return out;
	} else if (strcmp(weapon, "hunting_rifle")==0)
	{
		out = "Sniper Rifle";
		return out;
	} 
	
	out = "melee"; // na porrada
	return out;
}

// =====================================================================================================
// Tank handling functions
// Info: we count Tank spawn as well
public Action:Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// get the tank client
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//if (client == 0) return Plugin_Continue;
	g_curInfected++;
}

public Action:Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	// get the tank client
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//if (client == 0) return Plugin_Continue;
	g_curInfected=g_curInfected - 1 ;
}

