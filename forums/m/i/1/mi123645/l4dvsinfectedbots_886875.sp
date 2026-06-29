/********************************************************************************************
* Plugin	: L4dVsInfectedBots with Coop/Survival playable SI spawns
* Version	: 1.7.3
* Game		: Left 4 Dead 
* Author	: djromero (SkyDavid, David) and MI 5
* Testers	: Myself, MI 5
* Website	: www.sky.zebgames.com
* 
* Purpose	: This plugins spawns infected bots to fill up infected's team on vs mode when
* 			  there isn't enough real players. Also allows playable special infected on coop/survival modes.
* 
* WARNING	: Please use sourcemod's latest 1.2 branch snapshot. This plugin was tested with
* 			  build 2541 and 2562. Earlier versions are not supported.
* 
* Note from MI 5: I have detailed all of the modified code with my name on it, so that one can quickly see what was modified.
* 
* Version 1.0
* 		- Initial release.
* Version 1.1
* 		- Implemented "give health" command to fix infected's hud & pounce (hunter) when spawns
* Version 1.1.1
* 		- Fixed survivor's quick HUD refresh when spawning infected bots
* Version 1.1.2
* 		- Fixed crash when counting 
* Version 1.2
* 		- Fixed several bugs while counting players.
* 		- Added chat message to inform infected players (only) that a new bot has been spawned
* Version 1.3
* 		- No infected bots are spawned if at least one player is in ghost mode. If a bot is 
* 		  scheduled to spawn but a player is in ghost mode, the bot will spawn no more than
* 		  5 seconds after the player leaves ghost mode (spawns).
* 		- Infected bots won't stay AFK if they spawn far away. They will always search for
* 		  survivors even if they're far from them.
* 		- Allows survivor's team to be all bots, since we can have all bots on infected's team.
* Version 1.4
* 		- Infected bots can spawn when a real player is dead or in ghost mode without forcing
* 		  them (real players) to spawn.
* 		- Since real players won't be forced to spawn, they won't spawn outside the map or
* 		  in places they can't get out (where only bots can get out).
* Version 1.5
* 		- Added HUD panel for infected bots. Original idea from: Durzel's Infected HUD plugin.
* 		- Added validations so that boomers and smokers do not spawn too often. A boomer can
* 		  only spawn (as a bot) after XX seconds have elapsed since the last one died.
* 		- Added/fixed some routines/validations to prevent memory leaks.
* Version 1.5.1
* 		- Major bug fixes that caused server to hang (infite loops and threading problems).
* Version 1.5.2
* 		- Normalized spawn times for human zombies (min = max).
* 		- Fixed spawn of extra bot when someone dead becomes a tank. If player was alive, his
* 		  bot will still remain if he gets a tank.
* 		- Added 2 new cvars to disallow boomer and/or smoker bots:
* 			l4d_infectedbots_allow_boomer = 1 (allow, default) / 0 (disallow)
* 			l4d_infectedbots_allow_smoker = 1 (allow, default) / 0 (disallow)
* Version 1.5.3
* 		- Fixed issue when boomer/smoker bots would spawn just after human boomer/smoker was
* 		  killed. (I had to hook the player_death event as pre, instead of post to be able to
* 		  check for some info).
* 		- Added new cvar to control the way you want infected spawn times handled:
* 			l4d_infectedbots_normalize_spawntime:
* 				0 (default): Human zombies will use default spawn times (min time if less 
* 							 than 3 players in team) (min default is 20)
* 				1		   : Bots and human zombies will have the same spawn time.
* 							 (max default is 30).
* 		- Fixed issue when all players leave and server would keep playing with only
* 	 	  survivor/infected bots.
* Version 1.5.4
* 		- Fixed (now) issue when all players leave and server would keep playing with only
* 		  survivor/infected bots.
* Version 1.5.5
* 		- Fixed some issues with infected boomer bots spawning just after human boomer is killed.
* 		- Changed method of detecting VS maps to allow non-vs maps to use this plugin.
* Version 1.5.6
* 		- Rollback on method for detecting if map is VS
* Version 1.5.7
* 		- Rewrited the logic on map change and round end.
* 		- Removed multiple timers on "kickallbots" routine.
* 		- Added checks to "IsClientInKickQueue" before kicking bots.
* Version 1.5.8
* 		- Removed the "kickallbots" routine. Used a different method.
* Version 1.6
* 		- Finally fixed issue of server hanging on mapchange or when last player leaves.
* 		  Thx to AcidTester for his help testing this.
* 		- Added cvar to disable infected bots HUD
* Version 1.6
* 		- Fixed issue of HUD's timer not beign killed after each round.
* Version 1.6.1
* 		- Changed some routines to prevent crash on round end.
* Version 1.7.0
*      - Fixed sb_all_bot_team 1 is now set at all times until there are no players in the server.
*      - Survival/Coop now have playable Special Infected spawns.
*      - l4d_infectedbots_enabled_on_coop cvar created for those who want control over the plugin during coop/survival maps.
*      - Able to spectate AI Special Infected in Coop/Survival.
*      - Better AI (Smoker and Boomer don't sit there for a second and then attack a survivor when its within range).
*      - Set the number of VS team changes to 99 if its survival or coop, 2 for versus
*      - Safe Room timer added to coop/survival
*      - l4d_versus_hunter_limit added to control the amount of hunters in versus
*      - l4d_infectedbots_max_player_zombies added to increase the max special infected on the map (Bots and players)
*      - Autoexec created for this plugin
* Version 1.7.1
*      - Fixed Hunter AI where the hunter would run away and around in circles after getting hit
*      - Fixed Hunter Spawning where the hunter would spawn normally for 5 minutes into the map and then suddenly won't respawn at all
*      - An all Survivor Bot team can now pass the areas where they got stuck in (they can move throughout the map on their own now)     
*      - Changed l4d_versus_hunter_limit to l4d_infectedbots_versus_hunter_limit with a new default of 4
*      - It is now possible to change l4d_infectedbots_versus_hunter_limit and l4d_infectedbots_max_player_zombies in-game, just be sure to restart the map after change
*      - Overhauled the plugin, removed coop/survival infected spawn code, code clean up
*
* Version 1.7.2
*      - Removed autoconfig for plugin (delete your autoconfig for this plugin if you have one)
*      - Reintroduced coop/survival playable spawns
*      - spawns at conistent intervals of 20 seconds
*      - Overhauled coop special infected cvar dectection, use z_versus_boomer_limit, z_versus_smoker_limit, and l4d_infectedbots_versus_hunter_limit to alter amount of SI in coop (DO NOT USE THESE CVARS IF THE DIRECTOR IS SPAWNING THE BOTS! USE THE STANDARD COOP CVARS)
*      - Timers implemented for preventing the SI from spawning right at the start
*      - Fixed bug in 1.7.1 where the improved SI AI would reset to old after a map change
* 	   - Added a check on game start to prevent survivor bots from leaving the safe room too early when a player connects
* 	   - Added cvar to control the spawn time of the infected bots (can change at anytime and will take effect at the moment of change)
* 	   - Added cvar to have the director control the spawns (much better coop experience when max zombie players is set above 4), this however removes the option to play as those spawned infected
*	   - Removed l4d_infectedbots_coop_enabled cvar, l4d_infectedbots_director_spawn now replaces it. You can still use l4d_infectedbots_max_players_zombies
* 	   - New kicking mechanism added, there shouldn't be a problem with bots going over the limit
* 	   - Easier to join infected in coop/survival with the sm command "!ji"
* 	   - Introduced a new kicking mechanism, there shouldn't be more than the max infected unless there is a tank
*
* Version 1.7.2a
* 	   - Fixed bots not spawning after a checkpoint
* 	   - Fixed handle error
*
* Version 1.7.3
* 	   - Removed timers altogether and implemented the "old" system
* 	   - Fixed server hibernation problem
* 	   - Fixed error messages saying "Could not use ent_fire without cheats"
* 	   - Fixed Ghost spawning infront of survivors
* 	   - Set the spawn time to 25 seconds as default
* 	   - Fixed Checking bot mechanism
*        
* Thx to all who helped me test this plugin, specially:
* 	- AcidTester
* 	- Dark-Reaper 
*	- Mienaikage
* 	- Number Six
*   - Spector
*   - DarkDemon8
*   - |-|420|KiTtEh|-|
*   - DemonKyuubi
*   - Fubar
*   - Nia
*   - Shiranui
* 	- AtomicStryker
*   - mukla67
*   - lexantis
* 
**********************************************************************************************/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.7.3"
#define DEBUGMODE 0
#define HUD_FREQ 5


new offsetIsGhost;
new offsetIsAlive;

new bool:IsMapVS;

new bool:RoundStarted;
new bool:RoundEnded;
new bool:LeavedSafeRoom;
new MaxInfected;
new SurvivorRealCount;
new SurvivorBotCount;
new InfectedRealCount;
new InfectedBotCount;
new InfectedBotQueue;
new InfectedSpawnTime;
new MaxHunters;
new MaxBoomers;
new MaxSmokers;
new GameMode;
new bool:canSpawnBoomer;
new bool:canSpawnSmoker;
new bool:wait;
new bool:AllBotsTeam;
new Handle:h_AllowBoomerBots;
new Handle:h_AllowSmokerBots;
new Handle:h_AllowHunterBots;
new Handle:h_VersusHunterLimit;
new Handle:h_BotHudEnabled;
new Handle:h_MaxPlayerZombies;
new Handle:h_MaxPlayerZombies2;
new Handle:h_InfectedSpawnTime;
new Handle:h_DirectorSpawn;
new bool:AllowBoomerBots;
new bool:AllowSmokerBots;
new bool:AllowHunterBots;
new bool:BotHudEnabled;
new bool:DirectorSpawn;
new VersusHunterLimit;
new MaxPlayerZombies;

new zombieHP[4];					// Stores special infected max HP

public Plugin:myinfo = 
{
	name = "[L4D] VS Infected Bots",
	author = "djromero (SkyDavid), MI 5",
	description = "Spawns infected bots in versus, allows playable special infected in coop/survival, and changable z_max_player_zombies limit",
	version = PLUGIN_VERSION,
	url = "www.sky.zebgames.com"
}

public OnPluginStart()
{
	// We find some offsets
	offsetIsGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	//offsetIsAlive = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	offsetIsAlive = 2236;
	
	//Add a sourcemod command so players can easily join infected in coop/survival
	RegConsoleCmd("sm_ji", JoinInfected);
	//RegConsoleCmd("sm_sp", JoinSpectator);
	
	// We hook the round_start (and round_end) event on plugin start, since it occurs before map_start
	HookEvent("round_start", RoundStart, EventHookMode_Post);
	HookEvent("round_end", RoundEnd, EventHookMode_Pre);
	
	// We register the version cvar
	CreateConVar("l4d_vsinfectedbots_version", PLUGIN_VERSION, "Version of L4D VS Infected Bots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Reads zombies max HP
	zombieHP[0] = GetConVarInt(FindConVar("z_hunter_health"));
	zombieHP[1] = GetConVarInt(FindConVar("z_gas_health"));
	zombieHP[2] = GetConVarInt(FindConVar("z_exploding_health"));
	zombieHP[3] = RoundToFloor(GetConVarInt(FindConVar("z_tank_health")) * 1.5); // on vs, tank's health is increased
	
	// console variables
	h_AllowBoomerBots = CreateConVar("l4d_infectedbots_allow_boomer", "1", "If 1, it will allow boomer bots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_AllowSmokerBots = CreateConVar("l4d_infectedbots_allow_smoker", "1", "If 1, it will allow smoker bots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_AllowHunterBots = CreateConVar("l4d_infectedbots_allow_hunter", "1", "If 1, it will allow hunter bots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_VersusHunterLimit = CreateConVar("l4d_infectedbots_versus_hunter_limit", "2", "Sets the limit for hunters spawned by the plugin, must either restart the round or change the map if changed in-game", FCVAR_PLUGIN|FCVAR_NOTIFY);
	h_BotHudEnabled = CreateConVar("l4d_infectedbots_showhud", "1", "If infected bots hud will show", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_MaxPlayerZombies = CreateConVar("l4d_infectedbots_max_player_zombies", "4", "Defines how many special infected can be on the map on coop/versus, must either restart the round or change the map if changed in-game", FCVAR_PLUGIN|FCVAR_NOTIFY); 
	h_MaxPlayerZombies2 = FindConVar("z_max_player_zombies");
	h_InfectedSpawnTime = CreateConVar("l4d_infectedbots_spawn_time", "25", "Sets spawn time for special infected spawned by the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	h_DirectorSpawn = CreateConVar("l4d_infectedbots_director_spawn", "0", "If 1, the director will spawn the special infected instead of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	HookConVarChange(h_AllowBoomerBots, ConVarAllowBoomerBots);
	HookConVarChange(h_AllowSmokerBots, ConVarAllowSmokerBots);
	HookConVarChange(h_AllowHunterBots, ConVarAllowHunterBots);
	HookConVarChange(h_VersusHunterLimit, ConVarVersusHunterLimit);
	HookConVarChange(h_BotHudEnabled, ConVarBotHudEnabled);
	HookConVarChange(h_MaxPlayerZombies, ConVarMaxPlayerZombies);
	HookConVarChange(h_InfectedSpawnTime, ConVarInfectedSpawnTime);
	HookConVarChange(h_DirectorSpawn, ConVarDirectorSpawn);
	AllowBoomerBots = GetConVarBool(h_AllowBoomerBots);
	AllowSmokerBots = GetConVarBool(h_AllowSmokerBots);
	AllowHunterBots = GetConVarBool(h_AllowHunterBots);
	VersusHunterLimit = GetConVarInt(h_VersusHunterLimit);
	BotHudEnabled = GetConVarBool(h_BotHudEnabled);
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
	InfectedSpawnTime = GetConVarInt(h_InfectedSpawnTime);
	DirectorSpawn = GetConVarBool(h_DirectorSpawn);
	
	//set some variables
	RoundStarted = false;
	RoundEnded = false;
	
	wait = false;
	
	// We hook some events ...
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", PlayerTeam);
	HookEvent("player_left_start_area", PlayerLeftStart);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("door_open", PlayerLeftCheckPoint);
	HookEvent("create_panic_event", SurvivalStart);
	
}

public ConVarBotHudEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BotHudEnabled = GetConVarBool(h_BotHudEnabled);
}

public ConVarAllowBoomerBots(Handle:convar, const String:oldValue[], const String:newValue[])
{
	AllowBoomerBots = GetConVarBool(h_AllowBoomerBots);
}
public ConVarAllowSmokerBots(Handle:convar, const String:oldValue[], const String:newValue[])
{
	AllowSmokerBots = GetConVarBool(h_AllowSmokerBots);
}

public ConVarAllowHunterBots(Handle:convar, const String:oldValue[], const String:newValue[])
{
	AllowHunterBots = GetConVarBool(h_AllowHunterBots);
}

public ConVarVersusHunterLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	VersusHunterLimit = GetConVarInt(h_VersusHunterLimit);
}

public ConVarMaxPlayerZombies(Handle:convar, const String:oldValue[], const String:newValue[])
{
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
}

public ConVarInfectedSpawnTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	InfectedSpawnTime = GetConVarInt(h_InfectedSpawnTime);
}

public ConVarDirectorSpawn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	DirectorSpawn = GetConVarBool(h_DirectorSpawn);
}

TweakSettings ()
{
	
	// We tweak some settings ...
	
	//We turn off the ability for the director to spawn the bots, and have the plugin do it while allowing the director to spawn tanks and witches, MI 5
	if (GameMode == 1)
	{
		SetConVarInt(FindConVar("z_gas_limit"), 0);
		SetConVarInt(FindConVar("z_exploding_limit"), 0);
		SetConVarInt(FindConVar("z_hunter_limit"), 0);
		ResetConVar(FindConVar("director_no_specials"), true, true);
	}
	
	
	//Better Versus Infected AI, reset if not versus, MI 5
	if (GameMode == 2)
	{
		SetConVarInt(FindConVar("boomer_vomit_delay"), 0);
		SetConVarInt(FindConVar("smoker_tongue_delay"), 0);
		SetConVarInt(FindConVar("hunter_leap_away_give_up_range"), 0);
		ResetConVar(FindConVar("director_no_specials"), true, true);
	}
	
	//z_discard_range was cut out because I wanted to keep the ability for relocating SI in, MI 5
	if (GameMode != 2)
	{
		ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
		ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
		ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
		//SetConVarInt(FindConVar("z_discard_range"), 10000000);
	}
	
	//Turns off the ability for the director to spawn infected bots in survival, interstingly enough it does not affect tank spawns, MI
	if (GameMode == 3)
	{
		SetConVarInt(FindConVar("director_no_specials"), 1);
	}
	
	//Some cvar tweaks
	SetConVarInt(FindConVar("z_attack_flow_range"), 50000);
	SetConVarInt(FindConVar("director_spectate_specials"), 1);
}

public Action:RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	// We determine if map is vs ...
	new String:MapName[80];
	GetCurrentMap(MapName, sizeof(MapName));
	if (StrContains(MapName, "", false) != -1)
		IsMapVS = true;
	else
	IsMapVS = false;
	
	//Linking the handle MaxPlayerZombies2 with the variable MaxPlayerZombies, MI 5
	SetConVarBounds(h_MaxPlayerZombies2, ConVarBound_Upper, false, 14.0);
	SetConVarInt(h_MaxPlayerZombies2, MaxPlayerZombies)
	
	//reset some variables
	InfectedBotQueue = 0;
	
	
	//MI 5, We determine what the gamemode is
	new String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrContains(GameName, "survival", false) != -1)
		GameMode = 3;
	else if (StrContains(GameName, "versus", false) != -1)
		GameMode = 2;
	else if (StrContains(GameName, "coop", false) != -1)
		GameMode = 1;
	
	//Gamemode 3 is survival, 2 versus, and 1 coop
	
	//If its survival
	if (GameMode == 3)
	{
		//Change the max infected to survival values
		// Infected maxs
		MaxInfected = GetConVarInt(FindConVar("holdout_max_specials"));
		MaxBoomers = GetConVarInt(FindConVar("holdout_max_boomers"));
		MaxSmokers = GetConVarInt(FindConVar("holdout_max_smokers"));
		MaxHunters = GetConVarInt(FindConVar("holdout_max_hunters"));
		
	}
	//If its Versus
	if (GameMode == 2)
	{
		//Change the max infected to versus values
		// Infected maxs
		MaxInfected = MaxPlayerZombies
		MaxBoomers = GetConVarInt(FindConVar("z_versus_boomer_limit"));
		MaxSmokers = GetConVarInt(FindConVar("z_versus_smoker_limit"));
		MaxHunters = VersusHunterLimit
	}
	// If its coop
	if (GameMode == 1)
	{
		//Change the max infected to coop values
		// Infected maxs
		MaxInfected = MaxPlayerZombies
		MaxBoomers = GetConVarInt(FindConVar("z_versus_boomer_limit"));
		MaxSmokers = GetConVarInt(FindConVar("z_versus_smoker_limit"));
		MaxHunters = VersusHunterLimit
	}
	
	//MI 5, We determine if Director spawning is on and turn off the spawning on the plugin
	if (DirectorSpawn)
	{
		IsMapVS = false;
	}
	
	if (IsMapVS)
	{
		
		// If round haven't started ...
		if (!RoundStarted)
		{
			
			// and we reset some variables ... And stop the survivor bots from moving at round start, the bot checker will only be in effect for coop/survival, MI 5
			LeavedSafeRoom = false;
			RoundEnded = false;
			RoundStarted = true;

			//Two timers for survival/coop and the timer for bot checkup, MI 5
			
			if (GameMode == 2)
			{
			CreateTimer(120.0, BotEnhancerTimer);
			}
			if (GameMode == 3)
			{
				CreateTimer(30.0, BotEnhancerTimer);
			}
			if (GameMode != 2)
			{
				CreateTimer(65.0, InfectedBotChecker) 
			}
			TweakSettings();
		}
	}
}

public Action:RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	// If map is vs ... 
	if (IsMapVS)
	{
		// If round has not been reported as ended ..
		if (!RoundEnded)
		{
			// we mark the round as ended
			RoundEnded = true;
			RoundStarted = false;
			LeavedSafeRoom = false;
		}
	}
}

public OnMapEnd()
{
	// If map is vs ... 
	if (IsMapVS)
	{
		RoundStarted = false;
		RoundEnded = true;
		LeavedSafeRoom = false;
		
		// We kill the hud timer
		//KillHudTimer();
	}
}

public Action:PlayerLeftStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	if ((GameMode == 2) || (GameMode == 1))
	{  
		// We check is map is VS ....
		if (IsMapVS)
		{
			// We don't care who left, just that at least one did
			if (!LeavedSafeRoom)
			{
				
				
				LeavedSafeRoom = true;
				
				// We reset some settings
				canSpawnBoomer = true;
				canSpawnSmoker = true;
				
				// We start the hud timer
				//KillHudTimer();
				CreateTimer(float(HUD_FREQ), ShowHudThread, _, TIMER_REPEAT);
				
				// We check if we need to spawn bots
				CheckIfBotsNeeded(true);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:PlayerLeftCheckPoint(Handle:event, const String:name[], bool:checkpoint)
{
	
	if (GameMode == 1)
	{  
		// We check is map is VS ....
		if (IsMapVS)
		{
			// We don't care who left, just that at least one did
			if (!LeavedSafeRoom)
			{
				
				
				LeavedSafeRoom = true;
				
				// We reset some settings
				canSpawnBoomer = true;
				canSpawnSmoker = true;
				
				// We start the hud timer
				//KillHudTimer();
				CreateTimer(float(HUD_FREQ), ShowHudThread, _, TIMER_REPEAT);
				
				// We check if we need to spawn bots
				CheckIfBotsNeeded(true);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:SurvivalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	if (GameMode == 3)
	{  
		// We check is map is VS ....
		if (IsMapVS)
		{
			// We don't care who left, just that at least one did
			if (!LeavedSafeRoom)
			{
				
				
				LeavedSafeRoom = true;
				
				// We reset some settings
				canSpawnBoomer = true;
				canSpawnSmoker = true;
				
				// We start the hud timer
				//KillHudTimer();
				CreateTimer(float(HUD_FREQ), ShowHudThread, _, TIMER_REPEAT);
				
				// We check if we need to spawn bots
				CheckIfBotsNeeded(true);
			}
		}
	}
	
	return Plugin_Continue;
}

//Check the amount of survivor bots and activate the entities if the team is filled with bots, we create a timer that fires an entity to get around the stuck bot problem, MI 5

public Action:BotEnhancerTimer(Handle:Timer)
{
	if ((LeavedSafeRoom) || (GameMode == 3))
	{
		// reset counters
		SurvivorBotCount = 0;
		SurvivorRealCount = 0;
		
		// First we count the ammount of survivor real players and bots
		new i;
		for (i=1;i<=GetMaxClients();i++)
		{
			// If player is not connected ...
			if (!IsClientConnected(i)) continue;
			
			// We check if player is in game
			if (!IsClientInGame(i)) continue;
			
			// Check if client is survivor ...
			if (GetClientTeam(i)==2)
			{
				// If player is a bot ... Added a check to allow players to be counted as bots in coop/survival, MI 5
				if (IsFakeClient(i))
					SurvivorBotCount++;
				else 				
				SurvivorRealCount++;
			}
		}
		// is survivors's team all bots ??? 
		if (SurvivorRealCount == 0)
		{
			new flags2 = GetCommandFlags("ent_fire");
			SetCommandFlags("ent_fire", flags2 & ~FCVAR_CHEAT);
			//Ents to be executed so that the survivor bots can move on
			
			ServerCommand("ent_fire elevator_button");
			ServerCommand("ent_fire barricade_gas_can ignite");
			ServerCommand("ent_fire radio_button");
			ServerCommand("ent_fire radio");
			ServerCommand("ent_fire emergency_door open");
			ServerCommand("ent_fire train_engine_button");
			ServerCommand("ent_fire button_safedoor_panic");
			ServerCommand("ent_fire radio forcefinalestart");
			
			CreateTimer(5.0, BotEnhancerTimer);
			CreateTimer(6.0, CheatReseter);
			
			
		}
		else
		{
			CreateTimer(10.0, BotEnhancerTimer)
		}
	}
}

public Action:InfectedBotChecker(Handle:Timer)
{
	//This is to constantly check for bots that have gone missing for any apparent reason, like the game not finding spawns for them or a bot being booted, for coop/survival only
	if (LeavedSafeRoom)
	{
		// current count ...
		new total = 0
		new String:class[150];
		new i;
		for (i=1;i<=GetMaxClients();i++)
		{
			// if player is connected and ingame ...
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				// if player is on infected's team
				if (GetClientTeam(i) == 3)
				{
					total++;
					
					// We determine his class
					GetClientModel(i, class, sizeof(class));
						
					
					//If player is a tank
					if (StrContains(class, "hulk", true) == -1)
					{
						total--;
					}
				}
			}
		}
		if (total + InfectedBotQueue < MaxInfected)
		{
			CheckIfBotsNeeded(false);
		}
		
	}
	CreateTimer(float(InfectedSpawnTime), InfectedBotChecker);
}

public Action:InfectedBotBooterVersus(Handle:Timer)
{
	//This is to check if there are any extra bots and boot them if necessary, excluding tanks, versus only
	if (GameMode == 2)
	{
		// 1 = Hunter, 2 = Smoker, 3 = Boomer
		
		// current count ...
		new boomers=0;
		new smokers=0;
		new hunters=0;
		new total = 0
		new String:class[150];
		new i;
		for (i=1;i<=GetMaxClients();i++)
		{
			// if player is connected and ingame ...
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				// if player is on infected's team
				if (GetClientTeam(i) == 3)
				{
					// We determine his class
					GetClientModel(i, class, sizeof(class));
					
					// We count depending on class ...
					if (StrContains(class, "boomer", false) != -1)
					{
						boomers++;
						total++;
					}
					else if (StrContains(class, "smoker", false) != -1)
					{
						smokers++;
						total++;
					}
					else if (StrContains(class, "hunter", false) != -1)
					{
						hunters++;	
						total++;
					}
				}
			}
		}
		if (total + InfectedBotQueue > MaxInfected)
		{
			new kick = total + InfectedBotQueue - MaxInfected; 
			new kicked = 0;
			
			// We kick any extra bots ....
			for (i=1;(i<=GetMaxClients())&&(kicked < kick);i++)
			{
				// If player is infected and is a bot ...
				if (IsClientConnected(i) && IsFakeClient(i) && IsClientInGame(i))
				{
					//  If bot is on infected ...
					if (GetClientTeam(i) == 3)
					{
						// Get player model
						GetClientModel(i, class, sizeof(class));
						
						// If player is not a tank
						if (StrContains(class, "hulk", false) == -1)
						{
							// timer to kick bot
							CreateTimer(0.1,kickbot,i);
							
							// increment kicked count ..
							kicked++;
						}
					}
				}
			}
		}
	}
}


//Allows players to easily join infected in coop/survival, MI 5

public OnClientPutInServer(client)
{
	if ((client) && (GameMode != 2) && (!DirectorSpawn))
	{
		CreateTimer(30.0, AnnounceJoinInfected, client);
	}
}

public Action:JoinInfected(client, args)
{
	if ((client) && (GameMode != 2) && (!DirectorSpawn))
	{
		ChangeClientTeam(client, 3);
	}
}

//public Action:JoinSpectator(client, args)
//{
	//if ((client) && (GameMode != 2) && (!DirectorSpawn))
	//{
		//ChangeClientTeam(client, 1);
	//}
//}

public Action:AnnounceJoinInfected(Handle:timer, any:client)
{
	if (IsClientInGame(client) && (GameMode != 2) && (!DirectorSpawn))
	{
		PrintToChat(client, "[SM] Type !ji to join the infected team");
	}
}

public Action:CheatReseter(Handle:Timer)
{
	
	new flags3 = GetCommandFlags("ent_fire");
	SetCommandFlags("ent_fire", flags3|FCVAR_CHEAT);
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Ignore this entire section if it's not versus, MI 5
	
	if (GameMode == 2)
	{
		// If round has ended .. we ignore this
		if (RoundEnded)
			return Plugin_Continue;
		
		// We only listen to this if they leaved the safe room
		if (!LeavedSafeRoom)
			return Plugin_Continue;
		
		// We get the client id and time
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		// If client is valid
		if (client == 0) return Plugin_Continue;
		if (!IsClientConnected(client)) return Plugin_Continue;
		if (!IsClientInGame(client)) return Plugin_Continue;
		
		// If player spawned on infected's team ...
		if (GetClientTeam(client)==3)
		{
			// If player is human...
			if (!IsFakeClient(client))
			{
				// we get the classtype ...
				new String:class[100];
				GetClientModel(client, class, sizeof(class));
				
				// and prevents boots from spawning on the same class ...
				if (StrContains(class, "boomer", false) != -1)
				{
					canSpawnBoomer = false;
					CreateTimer(float(InfectedSpawnTime * 1), ResetSpawnRestriction, 3);
				}
				else if (StrContains(class, "smoker", false) != -1)
				{
					canSpawnSmoker = false;
					CreateTimer(float(InfectedSpawnTime * 1), ResetSpawnRestriction, 2);
				}
			}
			
			
			// We give him health
			GiveHealth(client);
		}
	}
	return Plugin_Continue;
}

//Modified InfectedSpawnTime here for coop/survival, MI 5

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If round has ended .. we ignore this
	if (RoundEnded)
		return Plugin_Continue;
	
	// We only listen to this if they leaved the safe room
	if (!LeavedSafeRoom)
		return Plugin_Continue;
	
	// We get the client id and time
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// If client is valid
	if (client == 0) return Plugin_Continue;
	if (!IsClientConnected(client)) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	
	// If player wasn't on infected team, we ignore this ...
	if (GetClientTeam(client)!=3)
		return Plugin_Continue;
	
	// Depending on victim classtype ...
	new String:class[100];
	GetClientModel(client, class, sizeof(class));
	
	// We count depending on class ...
	if (GameMode == 2)
	{
		if (StrContains(class, "boomer", false) != -1)
		{
			canSpawnBoomer = false;
			CreateTimer(float(InfectedSpawnTime * 1), ResetSpawnRestriction, 3);
		}
		else if (StrContains(class, "smoker", false) != -1)
		{
			canSpawnSmoker = false;
			CreateTimer(float(InfectedSpawnTime * 1), ResetSpawnRestriction, 2);
		}
	}
	if (GameMode != 2)
	{	
		if (StrContains(class, "boomer", false) != -1)
		{
			canSpawnBoomer = false;
			CreateTimer(float(InfectedSpawnTime * 1), ResetSpawnRestriction, 3);
		}
		else if (StrContains(class, "smoker", false) != -1)
		{
			canSpawnSmoker = false;
			CreateTimer(float(InfectedSpawnTime * 1), ResetSpawnRestriction, 2);
		}
	}
	// determines if victim was a bot ...
	new bool:victimisbot = GetEventBool(event, "victimisbot");
	
	// if victim was a bot, we setup a timer to spawn a new bot ...
	if ((victimisbot) && (GameMode == 2))
	{
		// first we refresh the hud
		ShowHud();
		
		CreateTimer(float(InfectedSpawnTime), Spawn_InfectedBot, _, 0);
		InfectedBotQueue++;
		
		#if DEBUGMODE
		PrintToChatAll("An infected bot has been added to the spawn queue...");
		#endif
	}
	if (GameMode != 2)
	{
		// first we refresh the hud
		ShowHud();
		
		CreateTimer(float(InfectedSpawnTime), Spawn_InfectedBot, _, 0);
		InfectedBotQueue++;
		
		#if DEBUGMODE
		PrintToChatAll("An infected bot has been added to the spawn queue...");
		#endif
	}
	return Plugin_Continue;
}



public Action:ResetSpawnRestriction (Handle:timer, any:bottype)
{
	
	switch (bottype)
	{
		case 2: // smoker
		canSpawnSmoker = true;
		case 3: // boomer
		canSpawnBoomer = true;
	}
}

public Action:PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Ignore this entire section if it's not versus, MI 5
	if (GameMode == 2)
	{
		// If round has ended .. we ignore this
		if (RoundEnded)
			return Plugin_Continue;
		
		// We only listen to this if they leaved the safe room
		if (!LeavedSafeRoom)
			return Plugin_Continue;
		
		// If player is a bot, we ignore this ...
		new bool:isbot = GetEventBool(event, "isbot");
		if (isbot) return Plugin_Continue;
		
		// We get some data needed ...
		new newteam = GetEventInt(event, "team");
		new oldteam = GetEventInt(event, "oldteam");
		
		// If player's new/old team is infected, we recount the infected and add bots if needed ...
		if ((oldteam == 3)||(newteam == 3))
		{
			CheckIfBotsNeeded(false);
		}
	}
	return Plugin_Continue;
}

public OnClientConnected(client)
{
	// If is a real player
	if (!IsFakeClient(client))
	SetConVarInt(FindConVar("sb_all_bot_team"), 1);
}

public OnClientDisconnect(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	// If no real players are left in game ... and we restore sb_all_bot_team, MI 5
	if (!RealPlayersInGame(client))
	{	
		
		SetConVarInt(FindConVar("sb_all_bot_team"), 0);
		GameEnded();
	}
}

GameEnded()
{
	LeavedSafeRoom = false;
	RoundEnded = true;
	RoundStarted = false;
	wait = false;
}

public Action:CheckIfBotsNeededLater (Handle:timer, any:spawn_immediately)
{
	CheckIfBotsNeeded(spawn_immediately);
}


CheckIfBotsNeeded(bool:spawn_immediately)
{
	
	// If round has ended .. we ignore this
	if (RoundEnded) return;
	
	// We only listen to this if they leaved the safe room
	if (!LeavedSafeRoom) return;
	
	// If we must wait ...
	if (wait)
	{
		CreateTimer(1.0, CheckIfBotsNeededLater, spawn_immediately, 0);
		return;
	}
	
	// we tell other functions to wait ...
	wait = true;
	
	
	// First, we count the infected
	if (GameMode == 2)
	{
		CountInfected();
	}
	if (GameMode != 2)
	{
		CountInfected_NoTank();
	}
	
	new diff = MaxInfected - (InfectedBotCount + InfectedRealCount + InfectedBotQueue);
	new i;
	
	// If we need more infected bots
	if (diff > 0)
	{
		
		
		for (i=0;i<diff;i++)
		{
			// If we need them right away ...
			if (spawn_immediately)
			{
				// We just use 2 seconds ...
				CreateTimer(2.0, Spawn_InfectedBot, _, 0);
				InfectedBotQueue++;
			}
			else // We use the normal time ..
			{
				CreateTimer(float(InfectedSpawnTime), Spawn_InfectedBot, _, 0);
				InfectedBotQueue++;
			}
		}
	}
	
	if (GameMode == 2)
	{
		CountInfected_NoTank();
	}
	
	//Kick Timer
	CreateTimer(1.0, InfectedBotBooterVersus)
	
	// we let other functions work in peace ...
	wait = false;
}

CountInfected()
{
	
	// reset counters
	InfectedBotCount = 0;
	InfectedRealCount = 0;
	
	// First we count the ammount of infected real players and bots
	new i;
	for (i=1;i<=GetMaxClients();i++)
	{
		// If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if ((GetClientTeam(i)==3) && (GameMode == 2))
		{
			// If player is a bot ...
			if (IsFakeClient(i))
				InfectedBotCount++;
			else
				InfectedRealCount++;
		}
	}
	
	// is infected's team all bots ???
	if (InfectedRealCount == 0)	
		AllBotsTeam = true;
	else
	AllBotsTeam = false;
}

CountInfected_NoTank()
{
	
	// player class
	new String:class[100];
	
	// reset counters
	InfectedBotCount = 0;
	InfectedRealCount = 0;
	
	// First we count the ammount of infected real players and bots
	new i;
	for (i=1;i<=GetMaxClients();i++)
	{
		// If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if ((GetClientTeam(i)==3) && (GameMode == 2))
		{
			// Get player model
			GetClientModel(i, class, sizeof(class));
			
			// If player is not a tank
			if (StrContains(class, "hulk", false) == -1)
			{
				// If player is a bot ...
				if (IsFakeClient(i))
					InfectedBotCount++;
				else
				InfectedRealCount++;
			}
		}
	}
	
	// is infected's team all bots ???
	if (InfectedRealCount == 0)	AllBotsTeam = true;
}

BotTypeNeeded()
{
	
	// 1 = Hunter, 2 = Smoker, 3 = Boomer
	
	// current count ...
	new boomers=0;
	new smokers=0;
	new hunters=0;
	new String:class[150];
	new i;
	for (i=1;i<=GetMaxClients();i++)
	{
		// if player is connected and ingame ...
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			// if player is on infected's team
			if (GetClientTeam(i) == 3)
			{
				// We determine his class
				GetClientModel(i, class, sizeof(class));
				
				// We count depending on class ...
				if (StrContains(class, "boomer", false) != -1)
					boomers++;
				else if (StrContains(class, "smoker", false) != -1)
					smokers++;
				else if (StrContains(class, "hunter", false) != -1)
					hunters++;	
			}
		}
	}
	
	// buffer the variables ...
	new bool:tmpAllowBoomerBots = AllowBoomerBots;
	new bool:tmpAllowSmokerBots = AllowSmokerBots;
	new bool:tmpAllowHunterBots = AllowHunterBots;
	
	// If team is made up of bots only ... we need all of them ...
	if (AllBotsTeam)
	{
		tmpAllowBoomerBots = true;
		tmpAllowSmokerBots = true;
		tmpAllowHunterBots = true;
	}
	
	// We need a boomer??? can we spawn a boomer??? is boomer bot allowed??
	if ((boomers < MaxBoomers) && (canSpawnBoomer) && (tmpAllowBoomerBots))
		return 3;
	else if ((smokers < MaxSmokers) && (canSpawnSmoker) && (tmpAllowSmokerBots)) // we need a smoker ???? can we spawn a smoker ??? is smoker bot allowed ??
		return 2;
	else if ((hunters < MaxHunters) && (tmpAllowHunterBots)) // we need a hunter ???? can we spawn a hunter ??? is hunter bot allowed ??
		return 1;
	
	return 0;
}

public Action:Spawn_InfectedBot(Handle:timer)
{
	
	// We decrement the infected queue
	InfectedBotQueue--;
	
	// If round has ended, we ignore this request ...
	if (RoundEnded) return;
	
	// If round has not started
	if (!RoundStarted) return;
	
	// If survivors haven't leaved safe room ... we ignore this request (must be from previous round)
	if (!LeavedSafeRoom) return;
	
	// If busy, we setup a new timer in 1 sec...
	if (wait)
	{
		CreateTimer(1.0, Spawn_InfectedBot, _, 0);
		return;
	}
	
	
	
	// Now we tell other functions to wait
	wait = true;
	
	// First we get the infected count
	CountInfected();
	
	// If infected's team is already full ... we ignore this request (a real player connected after timer started ) ..
	if ((InfectedRealCount + InfectedBotCount) >= MaxInfected) 	
	{
		wait = false;
		return;
	}
	
	// Before spawning the bot, we determine if an real infected player is dead, since the new infected bot will be controlled by this player
	new i;
	new bool:resetGhost[MAXPLAYERS];
	new bool:resetDead[MAXPLAYERS];
	new bool:resetTeam[MAXPLAYERS];
	
	
	// This code allows infected players to not take over infected bots for versus, but sightly modified to have it take over infected bots for coop/survival,  MI 5
	for (i=1;i<=GetMaxClients();i++)
	{
		if (IsClientConnected(i) && (!IsFakeClient(i)) && IsClientInGame(i)) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if (GetClientTeam(i)==3)
			{
				// If player is a ghost ....
				if ((IsPlayerGhost(i)) && (GameMode == 2))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
					resetDead[i] = true;
					SetAliveStatus(i, true);
				}
				else if ((!IsPlayerAlive(i)) && (GameMode == 2)) // if player is just dead ...
				{
					resetTeam[i] = true;
					ChangeClientTeam(i, 1);
				}
			}
		}
	}
	
	// We get any client ....
	new anyclient = GetAnyClient();
	new bool:temp = false;
	if (anyclient == 0)
	{
		
		// we create a fake client
		anyclient = CreateFakeClient("Bot");
		if (anyclient == 0)
		{
			LogError("[L4D] Infected Bots: CreateFakeClient returned 0 -- Infected bot was not spawned");
			wait = false;
			return;
		}
		temp = true;
	}
	
	// enable the z_spawn command without sv_cheats
	new String:command[] = "z_spawn";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	
	// Determine the bot class needed ...
	new bot_type = BotTypeNeeded();
	
	// We spawn the bot ...
	switch (bot_type)
	{
		case 1: // Hunter
		{
			FakeClientCommand(anyclient, "z_spawn hunter auto");
		}
		case 2: // Smoker
		{
			FakeClientCommand(anyclient, "z_spawn smoker auto");
		}
		case 3: // Boomber
		{
			FakeClientCommand(anyclient, "z_spawn boomer auto");
		}
	}
	
	
	// restore z_spawn
	SetCommandFlags(command, flags);
	
	// We restore the player's status, modified only for versus, MI 5
	if (GameMode == 2)
	{
		for (i=1;i<=GetMaxClients();i++)
		{
			if (resetGhost[i] == true)
				SetGhostStatus(i, true);
			if (resetDead[i] == true)
				SetAliveStatus(i, false);
			if (resetTeam[i] == true)
				ChangeClientTeam(i, 3);
		}
	}
	// If client was temp, we setup a timer to kick the fake player
	if (temp) CreateTimer(0.1,kickbot,anyclient);
	
	// We refresh the HUD
	ShowHud();
	
	// Debug print
	#if DEBUGMODE
	PrintToChatAll("Spawning an infected bot. Type = %i ", bot_type);
	#endif
	
	// we let other functions perform ...
	wait = false;
	
	return;
}

public GetAnyClient ()
{
	
	new i;
	for (i=1;i<=GetMaxClients();i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i)))
		{
			return i;
		}
	}
	return 0;
}

public Action:kickbot(Handle:timer, any:value)
{
	
	KickThis(value);
}

KickThis (client)
{
	
	if (IsClientConnected(client) && (!IsClientInKickQueue(client)))
	{
		KickClient(client,"Kick");
	}
}



bool:IsPlayerGhost (client)
{
	new isghost;
	isghost = GetEntData(client, offsetIsGhost, 1);
	
	if (isghost == 1)
		return true;
	else
	return false;
}

SetAliveStatus (client, bool:alive)
{
	if (alive)
		SetEntData(client, offsetIsAlive, 1, 1, true);
	else
	SetEntData(client, offsetIsAlive, 0, 1, false);
}

SetGhostStatus (client, bool:ghost)
{
	if (ghost)
		SetEntData(client, offsetIsGhost, 1, 1, true);
	else
	SetEntData(client, offsetIsGhost, 0, 1, false);
}

GiveHealth (client)
{
	
	// enable the give command without sv_cheats
	new String:command[] = "give";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	
	// fakes give health command
	FakeClientCommand(client, "give health");
	
	// restore give 
	SetCommandFlags(command, flags);
}

bool:BotsAlive ()
{
	
	new i;
	for (i=1;i<=GetMaxClients();i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i))
			if (IsPlayerAlive(i) && (GetClientTeam(i) == 3))
				return true;
		}
	
	return false;
}

bool:RealPlayersInGame (client)
{
	
	new i;
	for (i=1;i<=GetMaxClients();i++)
	{
		if (i != client)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
				return true;
		}
	}
	
	return false;
}

public Action:ShowHudThread (Handle:timer)
{
	
	// If round ended
	if (RoundEnded)
		return Plugin_Stop;
	
	ShowHud();
	
	return Plugin_Continue;
}

ShowHud ()
{
	// If HUD is disabled, we don't show it
	if (!BotHudEnabled) return;
	
	// If no bots are alive, no point in showing the HUD
	if (!BotsAlive()) return;
	
	
	
	// We create the panel and set its title
	new Handle:hud;
	hud = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	SetPanelTitle(hud, "INFECTED BOTS:");
	
	// Loop through infected bots and show their status
	new i;
	new String:iClass [150];
	new String:linebuf[150];
	new iHP;
	for (i = 1; i <= GetMaxClients(); i++) 
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i)) 
		{
			if ((GetClientTeam(i) == 3)&& IsPlayerAlive(i))
			{
				// Work out what they're playing as
				GetClientModel(i, iClass, sizeof(iClass));
				if (StrContains(iClass, "hunter", false) != -1) 
				{
					strcopy(iClass, sizeof(iClass), "Hunter");
					iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[0]) * 100);
				} else if (StrContains(iClass, "smoker", false) != -1) 
				{
					strcopy(iClass, sizeof(iClass), "Smoker");
					iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[1]) * 100);
				} else if (StrContains(iClass, "boomer", false) != -1) 
				{
					strcopy(iClass, sizeof(iClass), "Boomer");
					iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[2]) * 100);
				} else if (StrContains(iClass, "hulk", false) != -1) 
				{
					strcopy(iClass, sizeof(iClass), "Tank");
					iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[3]) * 100);	
				}
				
				// We format the final line and print it ..
				Format(linebuf, sizeof(linebuf), "%s (%i%%)", iClass, iHP);
				DrawPanelItem(hud, linebuf);
			} // player is infected and alive ...
		} // player is connected, in-game and is a bot ...
	} 
	
	// Now we show the hud to all real infected players and spectators
	
	for (i = 1; i <= GetMaxClients(); i++) 
	{
		// If player is connected, ingame and is not a bot ...
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i)) 
		{
			// if player is on infected's team ... or spectators
			if ((GetClientTeam(i) == 3) || (GetClientTeam(i) == 1))
			{
				// checks player's menu ...
				if ((GetClientMenu(i) == MenuSource_RawPanel) || (GetClientMenu(i) == MenuSource_None))
				{	
					SendPanelToClient(hud, i, Menu_Hud, HUD_FREQ);
				}
			}	
		}
	}
	
	CloseHandle(hud);
}


public Menu_Hud(Handle:menu, MenuAction:action, param1, param2) { return; }

///////////////////
