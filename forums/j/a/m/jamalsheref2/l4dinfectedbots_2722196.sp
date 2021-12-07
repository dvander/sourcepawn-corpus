/********************************************************************************************
* Plugin	: L4D InfectedBots with Coop/Survival playable SI spawns
* Version	: 1.8.3
* Game		: Left 4 Dead 
* Author	: djromero (SkyDavid, David) and MI 5
* Testers	: Myself, MI 5
* Website	: www.sky.zebgames.com
* 
* Purpose	: This plugins spawns infected bots to fill up infected's team on vs mode when
* 			  there isn't enough real players. Also allows playable special infected on coop/survival modes.
* 
* WARNING	: Please use sourcemod's latest 1.2 branch snapshot. Earlier versions are not supported.
* 
* 
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
* Version 1.7.4
* 	   - Fixed bots spawning too fast
* 	   - Completely fixed Ghost bug (Ghosts will stay ghosts until the play spawns them)
* 	   - New cvar "l4d_infectedbots_tank_playable" that allows tanks to be playable on coop/survival
* Version 1.7.5
* 	   - Added command to join survivors (!js)
* 	   - Removed cvars: l4d_infectedbots_allow_boomer, l4d_infectedbots_allow_smoker and l4d_infectedbots_allow_hunter (redundent with new cvars)
* 	   - Added cvars: l4d_infectedbots_boomer_limit and l4d_infectedbots_smoker_limit
*	   - Added cvar: l4d_infectedbots_infected_team_joinable, cvar that can either allow or disallow players from joining the infected team on coop/survival
* 	   - Cvars renamed:  l4d_infectedbots_max_player_zombies to l4d_infectedbots_max_specials, l4d_infectedbots_tank_playable to l4d_infectedbots_coop_survival_tank_playable
* 	   - Bug fix with l4d_infectedbots_max_specials and l4d_infectedbots_director_spawn not setting correctly when the server first starts up
* 	   - Improved Boomer AI in versus (no longer sits there for a second when he is seen)
* 	   - Autoconfig (was applied in 1.7.4, just wasn't shown in the changelog) Be sure to delete your old one
* 	   - Reduced the chances of the director misplacing a bot
* 	   - If the tank is playable in coop or survival, a player will be picked as the tank, regardless of the player's status
* 	   - Fixed bug where the plugin may return "[L4D] Infected Bots: CreateFakeClient returned 0 -- Infected bot was not spawned"
* 	   - Removed giving health to infected when they spawn, they no longer need this as Valve fixed this bug
* 	   - Tank_killed game event was not firing due to the tank not being spawned by the director, this has been fixed by setting it in the player_death event and checking to see if it was a tank
* 	   - Fixed human infected players causing problems with infected bot spawning
* 	   - Added cvar: l4d_infectedbots_free_spawn which allows the spawning in coop/survival to be like versus (Thanks AtomicStryker for using some of your code from your infected ghost everywhere plugin!)
*	   - If there is only one survivor player in versus, the safe room door will be UTTERLY DESTROYED.    
* 	   - Open slots will be available to tanks by automatically increasing the max infected limit and decreasing when the tanks are killed
*	   - Bots were not spawning during a finale. This bug has been fixed.
* 	   - Fixed Survivor death finale glitch which would cause all player infected to freeze and not spawn
* 	   - Added a HUD that shows stats about Infected Players of when they spawn (from Durzel's Infected HUD plugin)
* 	   - Priority system added to the spawning in coop/survival, no longer does the first infected player always get the first infected bot that spawns
* 	   - Modified Spawn Restrictions
* 	   - Infected bots in versus now spawn as ghosts, and fully spawn two seconds later
* 	   - Removed commands that kicked with ServerCommand, this was causing crashes
* 	   - Added a check in coop/survival to put players on infected when they first join if the survivor team is full
* 	   - Removed cvar: l4d_infectedbots_hunter_limit
* 
* Version 1.7.6
* 	   - Finale Glitch is fixed completely, no longer runs on timers
* 	   - Fixed bug with spawning when Director Spawning is on
* 	   - Added cvar: l4d_infectedbots_stats_board, can turn the stats board on or off after an infected dies
* 	   - Optimizations here and there
* 	   - Added a random system where the tank can go to anyone, rather than to the first person on the infected team
* 	   - Fixed bug where 4 specials would spawn when the tank is playable and on the field
* 	   - Fixed Free spawn bug where laggy players would not be ghosted
* 	   - Errors related to "SetEntData" have been fixed
* 	   - MaxSpecials is no longer linked to Director Spawning
* 
* Version 1.7.7
* 	   - Support for admincheats (Thanks Whosat for this!)
* 	   - Reduced Versus checkpoint door unlocker timer to 10 seconds (no longer shows the message)
* 	   - Redone Versus door buster, now it simply unlocks the door
* 	   - Fixed Director Spawning bug when free spawn is turned on
* 	   - Added spawn timer to Director Spawning mode to prevent one player from taking all the bots
* 	   - Now shows respawn timers for bots in Versus
* 	   - When a player takes over a tank in coop/survival, the SI no longer disappears
* 	   - Redone Tank Lottery (Thanks AtomicStryker!)
* 	   - There is no limit on player tanks now
* 	   - Entity errors should be fixed, valid checks implemented
* 	   - Cvars that were changed by the plugin can now be changed with a server.cfg
*      - Director Spawning now works correctly when the value is changed from being 0 or 1
* 	   - Infected HUD now shows the health of the infected, rather than saying "ALIVE"
* 	   - Fixed Ghost bug on Survival start after a round (Kills all ghosts)
* 	   - Tank Health now shown properly in infected HUD
* 	   - Changed details of the infected HUD when Director Spawning is on
* 	   - Reduced the chances of the stats board appearing
*	
* Version 1.7.8
* 	   - Removed The Dedibots, Director and The Spawner, from spec, the bots still spawn and is still compatible with admincheats (fixes 7/8 human limit reached problem)
* 	   - Changed the format of some of the announcements
* 	   - Reduced size of HUD
* 	   - HUD will NOT show infected players unless there are more than 5 infected players on the team (Versus only)
* 	   - KillInfected function now only applies to survival at round start
* 	   - Fixed Tank turning into hunter problem
* 	   - Fixed Special Smoker bug and other ghost related problems
* 	   - Fixed music glitch where certain pieces of music would keep playing over and over
* 	   - Fixed bug when a SI bot dies in versus with director spawning on, it would keep spawning that bot
* 	   - Fixed 1 health point bug in director spawning mode
* 	   - Fixed Ghost spawning bug in director spawning mode where all ghosts would spawn at once
* 	   - Fixed Coop Tank lottery starting for versus
* 	   - Fixed Client 0 error with the Versus door unlocker
* 	   - Added cvar: l4d_infectedbots_jointeams_announce
* 	   	
* Version 1.7.9
* 	   - Fixed a rare bug where if a map changed and director spawning is on, it would not allow the infected to be playable
* 	   - Removed Sphere bubbles for infected and spectators
* 	   - Modified Spawn restriction system
* 	   - Fixed bug where changing class limits on the spot would not take effect immediately
* 	   - Removed infected bot ghosts in versus, caused too many bugs
* 	   - Director spawn can now be changed in-game without a restart
* 	   - The Gamemode being changed no longer needs a restart
* 	   - Fixed bug where if admincheats is installed and an admin picked to spawn infected did not have root, would not spawn the infected
* 	   - Fixed bug where players could not spawn as ghosts in versus if the gamemode was set in a server.cfg instead of the l4d dedicated server tool (which still has adverse effects, plugin or not)
* 
* Version 1.8.0
* 	   - Fixed bug where the sphere bubbles would come back after the player dies
* 	   - Fixed additional bugs coming from the "mp_gamemode/server.cfg" bug
* 	   - Now checks if the admincheats plugin is installed and adapts
* 	   - Fixed Free spawn bug that prevent players from spawning as ghosts on the third map (or higher) on a campaign
* 	   - Fixed bug with spawn restrictions (was counting dead players as alive)
* 	   - Added ConVarHooks to Infected HUD cvars (will take effect immediately after being changed)
* 	   - Survivor Bots won't move out of the safe room until the player is fully in game
* 	   - Bots will not be shown on the infected HUD when they are not supposed to be (being replaced by a player on director spawn mode, or a tank being kicked for a player tank to take over)
* 
* Version 1.8.1
* 	   - Reverted back to the old kicking system
* 	   - Fixed Tank on fire timer for survival
* 	   - Survivor players can no longer join a full infected team in versus when theres a tank in play
* 	   - When a tank spawns in coop, they are not taken over by a player instantly; instead they are stationary until the tank moves, and then a player takes over (Thanks AtomicStryker!)
* 
* Version 1.8.1 Fix V1
* 	   - Changed safe room detection (fixes Crash Course and custom maps) (Thanks AtomicStryker!)
* 
* Version 1.8.2
* 	   - Added Flashlights to the infected
* 	   - Prevented additional music from playing when spawning as an infected
* 	   - Redid the free spawning system, more robust and effective
* 	   - Fixed bug where human tanks would break z_max_player_zombies (Now prevents players from joining a full infected team in versus when a tank spawns)
* 	   - Redid the VersusDoorUnlocker, now activates without restrictions
* 	   - Fixed bug where tanks would keep spawning over and over
* 	   - Fixed bug where the HUD would display the tank on fire even though it's not
* 	   - Increased default spawn time to 30 seconds
* 
* Version 1.8.3
* 	   - Enhanced Hunter AI (Hunter bots pounce farther, versus only)
* 	   - Model detection methods have been replaced with class detections (Compatible with Character Select Menu)
* 	   - Fixed VersusDoorUnlocker not working on the second round
* 	   - Added cvar l4d_infectedbots_coordination (bots will wait until all other bot spawn timers are 0 and then spawn at once)
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
* 	- persnickety
* 	- Krazien
* 
**********************************************************************************************/

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.8.3"
#define DEBUG 0
#define DEBUGTANK 0
#define DEBUGHUD 0
#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR 		2
#define TEAM_INFECTED 		3
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_TANK	5

// Offsets

new offsetIsGhost; // Offset to see if the player is a ghost or not
new offsetIsAlive; // Offset to see if the player is alive or not
new offsetIsCulling; // Offset to make the player cull (Allows the player to press e and turn into a ghost)
new offsetlifeState; // Offset to prevent the player from spawning when the player is not supposed to
new offsetZombieClass; // Offset to prevent the stats board from showing
new offsetScrimmageType; // Offset to remove sphere bubbles in coop/survival

// Variables

new InfectedRealCount; // Holds the amount of real infected players in versus
new InfectedBotCount; // Holds the amount of infected bots in any gamemode
new InfectedBotQueue; // Holds the amount of bots that are going to spawn
new InfectedSpawnTime; // Holds the spawntime for the infected bots
new GameMode; // Holds the GameMode, 1 for coop, 2 for versus, 3 for survival
new TanksPlaying; // Holds the amount of tanks on the playing field
new BoomerLimit; // Sets the Boomer Limit, related to the boomer limit cvar
new SmokerLimit; // Sets the Smoker Limit, related to the smoker limit cvar
//new HunterLimit; // Sets the Hunter Limit, related to the hunter limit cvar
new TankLimit; // Sets the Tank Limit, related to the tank per spawn cvar
new MaxPlayerZombies; // Holds the amount of the maximum amount of special zombies on the field
new MaxPlayerTank; // Used for setting an additional slot for each tank that spawns
new BotReady; // Used to determine how many bots are ready, used only for the coordination feature

// Booleans

new bool:RoundStarted; // Used to state if the round started or not
new bool:RoundEnded; // States if the round has ended or not
new bool:LeavedSafeRoom; // States if the survivors have left the safe room
new bool:canSpawnBoomer; // States if we can spawn a boomer (releated to spawn restrictions)
new bool:canSpawnSmoker; // States if we can spawn a smoker (releated to spawn restrictions)
new bool:wait; // Used to allow a certain function to work while others wait
new bool:DirectorSpawn; // Can allow either the director to spawn the infected (normal l4d behavior), or allow the plugin to spawn them
new bool:TankPlayer; // Indicates whether the cvar for allowing playable tanks is on or off
new bool:JoinableTeams; // Allows the Infected team to be joinable or not
new bool:FreeSpawn; // Allows ghosts to spawn in coop/survival or not
new bool:SpecialHalt; // Loop Breaker, prevents specials spawning, while Director is spawning, from spawning again
new bool:TankFrustStop; // Prevents the tank frustration event from firing as it counts as a tank spawn
new bool:FinaleStarted; // States whether the finale has started or not
new bool:StatsBoard; // States whether the stats board is shown after a special dies in coop/survival
new bool:WillBeTank[MAXPLAYERS+1]; // States whether that player will be the tank
new bool:TankHalt; // Loop Breaker, prevents player tanks from spawning over and over
new bool:JoinableTeamsAnnounce; // Announces to clients that the infected team is joinable
new bool:TankWasSeen; // Used only in coop, prevents the Sound hook event from triggering over and over again
new bool:PlayerLifeState[MAXPLAYERS+1]; // States whether that player has the lifestate changed from switching the gamemode
new bool:DoNotChangeGameMode; // Tells the plugin not to execute the ConVarHook associated with the GameMode
new bool:FinaleGlitchStopBot; // Tells the plugin not to spawn a bot in Director Spawning mode when a player has the finale glitch
new bool:InitialSpawn; // Related to the coordination feature, tells the plugin to let the infected spawn when the survivors leave the safe room
new bool:Coordination; // Tells the plugin if coordination is on or off


// Handles

new Handle:h_BoomerLimit; // Related to the Boomer limit cvar
new Handle:h_SmokerLimit; // Related to the Smoker limit cvar
//new Handle:h_HunterLimit; // Related to the Hunter limit cvar
new Handle:h_MaxPlayerZombies; // Related to the max specials cvar
new Handle:h_InfectedSpawnTime; // Related to the spawn time cvar
new Handle:h_DirectorSpawn; // yeah you're getting the idea
new Handle:h_TankPlayer; // yup, same thing again
new Handle:h_GameMode; // uh huh
new Handle:h_JoinableTeams; // Can you guess this one?
new Handle:h_TankLimit; // Getting bored?
new Handle:h_FreeSpawn; // We're done now, so be excited
new Handle:h_StatsBoard; // Oops, now we are
new Handle:h_Difficulty; // Ok, maybe not
new Handle:h_JoinableTeamsAnnounce; // ...
new Handle:h_AdminCheatsDetected;
new Handle:h_Coordination;


// Stuff related to Durzel's HUD (Panel was redone)

new respawnDelay[MAXPLAYERS+1]; 			// Used to store individual player respawn delays after death
new hudDisabled[MAXPLAYERS+1];				// Stores the client preference for whether HUD is shown
new clientGreeted[MAXPLAYERS+1]; 			// Stores whether or not client has been shown the mod commands/announce
new zombieHP[4];					// Stores special infected max HP
new Handle:cvarZombieHP[4];				// Array of handles to the 4 cvars we have to hook to monitor HP changes
new bool:isTankOnFire		= false; 		// Used to store whether tank is on fire
new burningTankTimeLeft		= 0; 			// Stores number of seconds Tank has left before he dies
new bool:roundInProgress 		= false;		// Flag that marks whether or not a round is currently in progress
new Handle:infHUDTimer 		= INVALID_HANDLE;	// The main HUD refresh timer
new Handle:respawnTimer 	= INVALID_HANDLE;	// Respawn countdown timer
new Handle:doomedTankTimer 	= INVALID_HANDLE;	// "Tank on Fire" countdown timer
new Handle:delayedDmgTimer 	= INVALID_HANDLE;	// Delayed damage update timer
new Handle:pInfHUD 		= INVALID_HANDLE;	// The panel shown to all infected users
new Handle:usrHUDPref 		= INVALID_HANDLE;	// Stores the client HUD preferences persistently

// Console commands
new Handle:h_InfHUD		= INVALID_HANDLE;
new Handle:h_Announce 	= INVALID_HANDLE;
new bool:InfHUD;
new bool:Announce;

public Plugin:myinfo = 
{
	name = "[L4D] Infected Bots",
	author = "djromero (SkyDavid), MI 5",
	description = "Spawns infected bots in versus, allows playable special infected in coop/survival, and changable z_max_player_zombies limit",
	version = PLUGIN_VERSION,
	url = "www.sky.zebgames.com"
}

public OnPluginStart()
{
	// Notes on the offsets: altough m_isGhost is used to check or set a player's ghost status, for some weird reason this disallowed the player from spawning.
	// So I found and used m_isCulling to allow the player to press use and spawn as a ghost (which in this case, I forced the client to press use)
	
	// m_lifeState is an alternative to the "switching to spectator and back" method when a bot spawns. This was used to prevent players from taking over those bots, but
	// this provided weird movements when a player was spectating on the infected team.
	
	// ZombieClass is a cool one. It changes the class of the zombie to whatever (common infected, smoker, hunter, etc.). In the case of this plugin, it is used to prevent
	// the stats board from coming up. By setting the class of the player to a common infected upon death, the stat board no longer pops up.
	
	// ScrimmageType is interesting as it was used in the beta. The scrimmage code was abanonded and replaced with versus, but some of it is still left over in the final.
	// In the previous versions of this plugin (or not using this plugin at all), you might have seen giant bubbles or spheres around the map. Those are scrimmage spawn
	// spheres that were used to prevent infected from spawning within there. It was bothering me, and a whole lot of people who saw them. Thanks to AtomicStryker who
	// URGED me to remove the spheres, I began looking for a solution. He told me to use various source handles like m_scrimmageType and others. I experimented with it,
	// and found out that it removed the spheres, and implemented it into the plugin. The spheres are no longer shown, and they were useless anyway as infected still spawn 
	// within it.
	
	// We find some offsets
	offsetIsGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	offsetIsAlive = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	offsetIsCulling = FindSendPropInfo("CTerrorPlayer", "m_isCulling");
	offsetlifeState = FindSendPropInfo("CTerrorPlayer", "m_lifeState");
	offsetZombieClass = FindSendPropInfo("CTerrorPlayer", "m_zombieClass");
	offsetScrimmageType = FindSendPropInfo("CTerrorPlayer", "m_scrimmageType");
	
	
	// Removes the boundaries for z_max_player_zombies
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false, 14.0);
	
	// Notes on the sourcemod commands:
	// JoinSpectator is actually a developer command I used to see if the bots spawn correctly with and without a player. It was incredibly useful for this purpose, but it
	// will not be in the final versions.
	
	// Add a sourcemod command so players can easily join infected in coop/survival
	RegConsoleCmd("sm_ji", JoinInfected);
	RegConsoleCmd("sm_js", JoinSurvivors);
	//RegConsoleCmd("sm_sp", JoinSpectator);
	
	// We hook the round_start (and round_end) event on plugin start, since it occurs before map_start
	HookEvent("round_start", evtRoundStart, EventHookMode_Post);
	HookEvent("round_end", evtRoundEnd, EventHookMode_Pre);
	
	// We register the version cvar
	CreateConVar("l4d_infectedbots_version", PLUGIN_VERSION, "Version of L4D Infected Bots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	
	// console variables
	h_BoomerLimit = CreateConVar("l4d_infectedbots_boomer_limit", "1", "Sets the limit for boomers spawned by the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	h_SmokerLimit = CreateConVar("l4d_infectedbots_smoker_limit", "1", "Sets the limit for smokers spawned by the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	//h_HunterLimit = CreateConVar("l4d_infectedbots_hunter_limit", "2", "Sets the limit for hunters spawned by the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	h_TankLimit = CreateConVar("l4d_infectedbots_tanks_per_spawn", "1", "Number of tanks when a tank spawns, includes the original tank", FCVAR_PLUGIN|FCVAR_NOTIFY);
	h_MaxPlayerZombies = CreateConVar("l4d_infectedbots_max_specials", "4", "Defines how many special infected can be on the map on all gamemodes", FCVAR_PLUGIN|FCVAR_NOTIFY); 
	h_InfectedSpawnTime = CreateConVar("l4d_infectedbots_spawn_time", "30", "Sets spawn time for special infected spawned by the plugin in seconds", FCVAR_PLUGIN|FCVAR_NOTIFY);
	h_DirectorSpawn = CreateConVar("l4d_infectedbots_director_spawn", "0", "If 1, the plugin will use the director's timing of the spawns", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_TankPlayer = CreateConVar("l4d_infectedbots_coop_survival_tank_playable", "0", "If 1, tank will be playable in coop/survival, only one player can take control of a tank at a time", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_JoinableTeams = CreateConVar("l4d_infectedbots_infected_team_joinable", "1", "If 1, players can join the infected team in coop/survival", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_FreeSpawn = CreateConVar("l4d_infectedbots_free_spawn", "0", "If 1, infected players in coop/survival will spawn as ghosts, does not allow ghost spawning at finale on versus", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_GameMode = FindConVar("mp_gamemode");
	h_Difficulty = FindConVar("z_difficulty");
	h_StatsBoard = CreateConVar("l4d_infectedbots_stats_board", "1", "If 1, the stats board will show up after an infected player dies", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_JoinableTeamsAnnounce = CreateConVar("l4d_infectedbots_jointeams_announce", "1", "If 1, clients will be announced to about joining the infected team", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_Coordination = CreateConVar("l4d_infectedbots_coordination", "0", "If 1, bots will only spawn when all other bot timers are at zero", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(h_BoomerLimit, ConVarBoomerLimit);
	HookConVarChange(h_SmokerLimit, ConVarSmokerLimit);
	//HookConVarChange(h_HunterLimit, ConVarHunterLimit);
	HookConVarChange(h_MaxPlayerZombies, ConVarMaxPlayerZombies);
	HookConVarChange(h_InfectedSpawnTime, ConVarInfectedSpawnTime);
	HookConVarChange(h_DirectorSpawn, ConVarDirectorSpawn);
	HookConVarChange(h_TankPlayer, ConVarTankPlayer);
	HookConVarChange(h_JoinableTeams, ConVarJoinableTeams);
	HookConVarChange(h_TankLimit, ConVarTankLimit);
	HookConVarChange(h_FreeSpawn, ConVarFreeSpawn);
	HookConVarChange(h_GameMode, ConVarGameMode);
	HookConVarChange(h_StatsBoard, ConVarStatsBoard);
	HookConVarChange(h_Difficulty, ConVarDifficulty);
	HookConVarChange(h_JoinableTeamsAnnounce, ConVarJoinableTeamsAnnounce);
	HookConVarChange(h_Coordination, ConVarCoordination);
	BoomerLimit = GetConVarInt(h_BoomerLimit);
	SmokerLimit = GetConVarInt(h_SmokerLimit);
	//HunterLimit = GetConVarInt(h_HunterLimit);
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
	InfectedSpawnTime = GetConVarInt(h_InfectedSpawnTime);
	DirectorSpawn = GetConVarBool(h_DirectorSpawn);
	TankPlayer = GetConVarBool(h_TankPlayer);
	JoinableTeams = GetConVarBool(h_JoinableTeams);
	TankLimit = GetConVarInt(h_TankLimit);
	FreeSpawn = GetConVarBool(h_FreeSpawn);
	StatsBoard = GetConVarBool(h_StatsBoard);
	JoinableTeamsAnnounce = GetConVarBool(h_JoinableTeamsAnnounce);
	Coordination = GetConVarBool(h_Coordination);
	
	// Some of these events are being used multiple times. Although I copied Durzel's code, I felt this would make it more organized as there is a ton of code in events 
	// Such as PlayerDeath, PlayerSpawn and others.
	
	// We hook some events ...
	HookEvent("player_death", evtPlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", evtPlayerTeam);
	HookEvent("player_spawn", evtPlayerSpawn);
	HookEvent("create_panic_event", evtSurvivalStart);
	HookEvent("tank_frustrated", evtTankFrustrated);
	HookEvent("finale_start", evtFinaleStart);
	HookEvent("mission_lost", evtMissionLost);
	HookEvent("player_hurt", evtInfectedHurt);
	HookEvent("player_death", evtInfectedDeath);
	HookEvent("player_spawn", evtInfectedSpawn);
	HookEvent("player_hurt", evtInfectedHurt);
	HookEvent("player_team", evtTeamSwitch);
	HookEvent("player_death", evtInfectedWaitSpawn);
	HookEvent("ghost_spawn_time", evtInfectedWaitSpawn);
	
	// Hook a sound
	AddNormalSoundHook(NormalSHook:HookSound_Callback);
	//AddNormalSoundHook(NormalSHook:HookSound_Callback2);
	
	// We set some variables
	RoundStarted = false;
	RoundEnded = false;
	
	wait = false;
	
	//Autoconfig for plugin
	AutoExecConfig(true, "l4dinfectedbots");
	
	// Hook "say" so clients can toggle HUD on/off for themselves
	RegConsoleCmd("sm_infhud", Command_Say);
	
	// ----- Plugin cvars ------------------------
	h_InfHUD = CreateConVar("l4d_infectedbots_infhud_enable", "1", "Toggle whether L4D Infected HUD plugin is active or not.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_Announce = CreateConVar("l4d_infectedbots_infhud_announce", "1", "Toggle whether L4D Infected HUD plugin announces itself to clients.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(h_InfHUD, ConVarInfHUD);
	HookConVarChange(h_Announce, ConVarAnnounce);
	InfHUD = GetConVarBool(h_InfHUD);
	Announce = GetConVarBool(h_Announce);
	
	//----- Zombie HP hooks ---------------------	
	//We store the special infected max HP values in an array and then hook the cvars used to modify them
	//just in case another plugin (or an admin) decides to modify them.  Whilst unlikely if we don't do
	//this then the HP percentages on the HUD will end up screwy, and since it's a one-time initialisation
	//when the plugin loads there's a trivial overhead.
	cvarZombieHP[0] = FindConVar("z_hunter_health");
	cvarZombieHP[1] = FindConVar("z_gas_health");
	cvarZombieHP[2] = FindConVar("z_exploding_health");
	cvarZombieHP[3] = FindConVar("z_tank_health");
	
	zombieHP[0] = 250;	// Hunter default HP
	if (cvarZombieHP[0] != INVALID_HANDLE) {
		zombieHP[0] = GetConVarInt(cvarZombieHP[0]); 
		HookConVarChange(cvarZombieHP[0], cvarZombieHPChanged);
	}
	zombieHP[1] = 250;	// Smoker default HP
	if (cvarZombieHP[1] != INVALID_HANDLE) {
		zombieHP[1] = GetConVarInt(cvarZombieHP[1]); 
		HookConVarChange(cvarZombieHP[1], cvarZombieHPChanged);
	}
	zombieHP[2] = 50;	// Boomer default HP
	if (cvarZombieHP[2] != INVALID_HANDLE) {
		zombieHP[2] = GetConVarInt(cvarZombieHP[2]);
		HookConVarChange(cvarZombieHP[2], cvarZombieHPChanged);
	}
	decl String:difficulty[100];
	
	GetConVarString(FindConVar("z_difficulty"), difficulty, sizeof(difficulty));
	GameModeCheck();
	
	// This is the code that detects the tank's health. I had to do a GameMode check on plugin start, because the tank health on VS was not detecting correctly as the 
	// difficulty was still normal.
	
	if (GameMode == 2)
	{
		zombieHP[3] = 4000;	// Tank default HP
		if (cvarZombieHP[3] != INVALID_HANDLE) {
			zombieHP[3] = RoundToFloor(GetConVarInt(cvarZombieHP[3]) * 1.5);	// Tank health is multiplied by 1.5x in VS	
			HookConVarChange(cvarZombieHP[3], cvarZombieHPChanged);
		}
	}
	else if ((GameMode != 2) && (StrContains(difficulty, "Easy", false) != -1))  
	{
		zombieHP[3] = 4000;	// Tank default HP
		if (cvarZombieHP[3] != INVALID_HANDLE) {
			zombieHP[3] = RoundToFloor(GetConVarInt(cvarZombieHP[3]) * 0.75);
			HookConVarChange(cvarZombieHP[3], cvarZombieHPChanged);
		}
	}
	else if ((GameMode != 2) && (StrContains(difficulty, "Normal", false) != -1))
	{
		zombieHP[3] = 4000;	// Tank default HP
		if (cvarZombieHP[3] != INVALID_HANDLE) {
			zombieHP[3] = GetConVarInt(cvarZombieHP[3]);
			HookConVarChange(cvarZombieHP[3], cvarZombieHPChanged);
		}
	}
	else if ((GameMode != 2) && (StrContains(difficulty, "Hard", false) != -1) || (StrContains(difficulty, "Impossible", false) != -1))
	{
		zombieHP[3] = 4000;	// Tank default HP
		if (cvarZombieHP[3] != INVALID_HANDLE) {
			zombieHP[3] = RoundToFloor(GetConVarInt(cvarZombieHP[3]) * 2.0);
			HookConVarChange(cvarZombieHP[3], cvarZombieHPChanged);
		}
	}
	
	// Create persistent storage for client HUD preferences 
	usrHUDPref = CreateTrie();
	
}

public ConVarBoomerLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BoomerLimit = GetConVarInt(h_BoomerLimit);
	SetConVarInt(FindConVar("z_versus_boomer_limit"), BoomerLimit);
}
public ConVarSmokerLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SmokerLimit = GetConVarInt(h_SmokerLimit);
	SetConVarInt(FindConVar("z_versus_smoker_limit"), SmokerLimit);
}

//public ConVarHunterLimit(Handle:convar, const String:oldValue[], const String:newValue[])
//{
//HunterLimit = GetConVarInt(h_HunterLimit);
//}

public ConVarMaxPlayerZombies(Handle:convar, const String:oldValue[], const String:newValue[])
{
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
	CreateTimer(0.1, MaxSpecialsSet);
}

public ConVarInfectedSpawnTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	InfectedSpawnTime = GetConVarInt(h_InfectedSpawnTime);
}

public ConVarDirectorSpawn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	DirectorSpawn = GetConVarBool(h_DirectorSpawn);
	if (!DirectorSpawn)
	{
		TweakSettings();
		CheckIfBotsNeeded(true);
	}
	else
	{
		DirectorStuff();
	}
}

public ConVarTankPlayer(Handle:convar, const String:oldValue[], const String:newValue[])
{
	TankPlayer = GetConVarBool(h_TankPlayer);
}

public ConVarJoinableTeams(Handle:convar, const String:oldValue[], const String:newValue[])
{
	JoinableTeams = GetConVarBool(h_JoinableTeams);
}

public ConVarTankLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	TankLimit = GetConVarInt(h_TankLimit);
}

public ConVarFreeSpawn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FreeSpawn = GetConVarBool(h_FreeSpawn);
}

public ConVarGameMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// If the plugin is changing the gamemode manually, don't execute this convar hook
	
	if (DoNotChangeGameMode)
		return;
	
	GameModeCheck();
	if (!DirectorSpawn)
	{
		TweakSettings();
	}
	else
	{
		DirectorStuff();
	}
	if (infHUDTimer == INVALID_HANDLE) {
		infHUDTimer = CreateTimer(5.0, showInfHUD, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	if (GameMode == 2)
	{
		zombieHP[3] = 4000;	// Tank default HP
		if (cvarZombieHP[3] != INVALID_HANDLE) {
			zombieHP[3] = RoundToFloor(GetConVarInt(cvarZombieHP[3]) * 1.5);	// Tank health is multiplied by 1.5x in VS	
			HookConVarChange(cvarZombieHP[3], cvarZombieHPChanged);
		}
	}
}

public ConVarDifficulty(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl String:difficulty[100];
	
	GetConVarString(FindConVar("z_difficulty"), difficulty, sizeof(difficulty));
	
	if (GameMode == 2)
	{
		zombieHP[3] = 4000;	// Tank default HP
		if (cvarZombieHP[3] != INVALID_HANDLE) {
			zombieHP[3] = RoundToFloor(GetConVarInt(cvarZombieHP[3]) * 1.5);	// Tank health is multiplied by 1.5x in VS	
			HookConVarChange(cvarZombieHP[3], cvarZombieHPChanged);
		}
	}
	else if ((GameMode != 2) && (StrContains(difficulty, "Easy", false) != -1))  
	{
		zombieHP[3] = 4000;	// Tank default HP
		if (cvarZombieHP[3] != INVALID_HANDLE) {
			zombieHP[3] = RoundToFloor(GetConVarInt(cvarZombieHP[3]) * 0.75);
			HookConVarChange(cvarZombieHP[3], cvarZombieHPChanged);
		}
	}
	else if ((GameMode != 2) && (StrContains(difficulty, "Normal", false) != -1))
	{
		zombieHP[3] = 4000;	// Tank default HP
		if (cvarZombieHP[3] != INVALID_HANDLE) {
			zombieHP[3] = GetConVarInt(cvarZombieHP[3]);
			HookConVarChange(cvarZombieHP[3], cvarZombieHPChanged);
		}
	}
	else if ((GameMode != 2) && (StrContains(difficulty, "Hard", false) != -1) || (StrContains(difficulty, "Impossible", false) != -1))
	{
		zombieHP[3] = 4000;	// Tank default HP
		if (cvarZombieHP[3] != INVALID_HANDLE) {
			zombieHP[3] = RoundToFloor(GetConVarInt(cvarZombieHP[3]) * 2.0);
			HookConVarChange(cvarZombieHP[3], cvarZombieHPChanged);
		}
	}
}

public ConVarStatsBoard(Handle:convar, const String:oldValue[], const String:newValue[])
{
	StatsBoard = GetConVarBool(h_StatsBoard);
}

public ConVarJoinableTeamsAnnounce(Handle:convar, const String:oldValue[], const String:newValue[])
{
	JoinableTeamsAnnounce = GetConVarBool(h_JoinableTeamsAnnounce);
}

public ConVarInfHUD(Handle:convar, const String:oldValue[], const String:newValue[])
{
	InfHUD = GetConVarBool(h_InfHUD);
}

public ConVarAnnounce(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Announce = GetConVarBool(h_Announce);
}

public ConVarCoordination(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Coordination = GetConVarBool(h_Coordination);
}

TweakSettings()
{
	// We tweak some settings ...
	
	// Some interesting things about this. There was a bug I discovered that in versions 1.7.8 and below, infected players would not spawn as ghosts in VERSUS. This was
	// due to the fact that the coop class limits were not being reset (I didn't think they were linked at all, but I should have known better). This bug has been fixed
	// with the coop class limits being reset on every gamemode except coop of course.
	
	if (!DirectorSpawn)
	{
		switch (GameMode)
		{
			case 1: // Coop, We turn off the ability for the director to spawn the bots, and have the plugin do it while allowing the director to spawn tanks and witches, 
			// MI 5
			{
				ResetConVar(FindConVar("director_no_specials"), true, true);
				ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
				ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
				ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
				ResetConVar(FindConVar("boomer_exposed_time_tolerance"), true, true);
				ResetConVar(FindConVar("holdout_max_smokers"), true, true);
				ResetConVar(FindConVar("holdout_max_boomers"), true, true);
				ResetConVar(FindConVar("holdout_max_hunters"), true, true);
				ResetConVar(FindConVar("holdout_max_specials"), true, true);
				ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
				ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
				ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
				ResetConVar(FindConVar("z_hunter_lunge_stagger_time"), true, true);
				SetConVarInt(FindConVar("z_gas_limit"), 0);
				SetConVarInt(FindConVar("z_exploding_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
				SetConVarInt(FindConVar("vs_max_team_switches"), 9999);
			}
			case 2: // Versus, Better Versus Infected AI, reset if not versus, MI 5
			{
				SetConVarInt(FindConVar("z_gas_limit"), 999);
				SetConVarInt(FindConVar("z_exploding_limit"), 999);
				SetConVarInt(FindConVar("z_hunter_limit"), 999);
				ResetConVar(FindConVar("holdout_max_smokers"), true, true);
				ResetConVar(FindConVar("holdout_max_boomers"), true, true);
				ResetConVar(FindConVar("holdout_max_hunters"), true, true);
				ResetConVar(FindConVar("holdout_max_specials"), true, true);
				ResetConVar(FindConVar("director_no_specials"), true, true);
				ResetConVar(FindConVar("vs_max_team_switches"), true, true);
				SetConVarFloat(FindConVar("smoker_tongue_delay"), 0.0);
				SetConVarFloat(FindConVar("boomer_vomit_delay"), 0.0);
				SetConVarFloat(FindConVar("boomer_exposed_time_tolerance"), 0.0);
				SetConVarInt(FindConVar("hunter_leap_away_give_up_range"), 0);
				SetConVarInt(FindConVar("z_hunter_lunge_distance"), 5000);
				SetConVarInt(FindConVar("hunter_pounce_ready_range"), 1500);
				SetConVarFloat(FindConVar("hunter_pounce_loft_rate"), 0.055);
				SetConVarFloat(FindConVar("z_hunter_lunge_stagger_time"), 0.0);
			}
			case 3: // Survival, Turns off the ability for the director to spawn infected bots in survival, MI 5
			{
				ResetConVar(FindConVar("z_gas_limit"), true, true);
				ResetConVar(FindConVar("z_exploding_limit"), true, true);
				ResetConVar(FindConVar("z_hunter_limit"), true, true);
				ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
				ResetConVar(FindConVar("director_no_specials"), true, true);
				ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
				ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
				ResetConVar(FindConVar("boomer_exposed_time_tolerance"), true, true);
				ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
				ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
				ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
				ResetConVar(FindConVar("z_hunter_lunge_stagger_time"), true, true);
				SetConVarInt(FindConVar("holdout_max_smokers"), 0);
				SetConVarInt(FindConVar("holdout_max_boomers"), 0);
				SetConVarInt(FindConVar("holdout_max_hunters"), 0);
				SetConVarInt(FindConVar("holdout_max_specials"), MaxPlayerZombies);
				SetConVarInt(FindConVar("vs_max_team_switches"), 9999);
			}
		}
		
		//Some cvar tweaks
		SetConVarInt(FindConVar("z_attack_flow_range"), 50000);
		SetConVarInt(FindConVar("director_spectate_specials"), 1);
		SetConVarInt(FindConVar("z_spawn_safety_range"), 0);
		SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000);
		SetConVarInt(FindConVar("z_versus_boomer_limit"), BoomerLimit);
		SetConVarInt(FindConVar("z_versus_smoker_limit"), SmokerLimit);
		
		#if DEBUG
		LogMessage("Tweaking Settings");
		#endif
	}
}

public Action:evtRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	//Check the GameMode
	GameModeCheck();
	
	if (GameMode != 0)
	{
		// Added a delay to setting MaxSpecials so that it would set correctly when the server first starts up
		CreateTimer(0.4, MaxSpecialsSet);
		
		//reset some variables
		InfectedBotQueue = 0;
		TanksPlaying = 0;
		BotReady = 0;
		TankFrustStop = false;
		FinaleStarted = false;
		SpecialHalt = false;
		TankWasSeen = false;
		DoNotChangeGameMode = false;
		InitialSpawn = false;
		
		// Find out if AdminCheats is installed
		
		h_AdminCheatsDetected = FindConVar("sm_admin_cheats_version");
		
		// execute the director spawning settings, won't go through if director spawning is off
		
		// If round haven't started ...
		if (!RoundStarted)
		{
			// Kill all infected ghosts if the game mode is survival
			if (GameMode == 3)
			{
				KillInfected();
			}
			// Zero all respawn times ready for the next round and any other arrays
			for (new i = 1; i <= MaxClients; i++) {
				respawnDelay[i] = 0;
				PlayerLifeState[i] = false;
				
			}
			// Show the HUD to the connected clients.
			roundInProgress = true;
			infHUDTimer = CreateTimer(5.0, showInfHUD, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			// and we reset some variables ...
			LeavedSafeRoom = false;
			RoundEnded = false;
			RoundStarted = true;
			// Start up TweakSettings or Director Stuff
			if (!DirectorSpawn)
				TweakSettings();
			else
			DirectorStuff();
			
			if (GameMode != 3)
			{
				CreateTimer(1.0, PlayerLeftStart);
			}
			if (GameMode == 2)
			{
				CreateTimer(10.0, VersusDoorUnlocker);
			}
		}
	}
}

GameModeCheck()
{
	#if DEBUG
	LogMessage("Checking Gamemode");
	#endif
	//MI 5, We determine what the gamemode is
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false))
		GameMode = 1;
	else 
	{
		GameMode = 0;
		CreateTimer(30.0, IncorrectGameMode);
	}
}

KillInfected()
{
	for (new i=1; i<=MaxClients; i++)
	{
		// If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i)==TEAM_INFECTED)
		{
			if (!IsFakeClient(i) && IsPlayerGhost(i))
			{
				ForcePlayerSuicide(i);
			}
		}
	}
}

public Action:MaxSpecialsSet(Handle:Timer)
{
	SetConVarInt(FindConVar("z_max_player_zombies"), MaxPlayerZombies);
	#if DEBUG
	LogMessage("Max Player Zombies Set");
	#endif
}

public Action:IncorrectGameMode(Handle:Timer)
{
	// Show this to everyone when the gamemode has been set incorrectly
	PrintToChatAll("\x04[SM] \x03INFECTED BOTS: \x03mp_gamemode \x04has been set \x03INCORRECTLY! PLUGIN WILL NOT START!");
}

DirectorStuff()
{	
	
	SpecialHalt = false;
	SetConVarInt(FindConVar("z_spawn_safety_range"), 0);
	SetConVarInt(FindConVar("director_spectate_specials"), 1);
	if (GameMode != 2)
	{
		SetConVarInt(FindConVar("vs_max_team_switches"), 9999);
		ResetConVar(FindConVar("z_hunter_limit"), true, true);
		ResetConVar(FindConVar("z_exploding_limit"), true, true);
		ResetConVar(FindConVar("z_gas_limit"), true, true);
		ResetConVar(FindConVar("holdout_max_smokers"), true, true);
		ResetConVar(FindConVar("holdout_max_boomers"), true, true);
		ResetConVar(FindConVar("holdout_max_hunters"), true, true);
		ResetConVar(FindConVar("holdout_max_specials"), true, true);
	}
	else if (GameMode == 2)
	{
		ResetConVar(FindConVar("vs_max_team_switches"), true, true);
	}
	
	#if DEBUG
	LogMessage("Director Stuff has been executed");
	#endif
	
}

public Action:evtRoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	
	// If round has not been reported as ended ..
	if (!RoundEnded)
	{
		
		// we mark the round as ended
		RoundEnded = true;
		RoundStarted = false;
		LeavedSafeRoom = false;
		roundInProgress = false;
		isTankOnFire = false;
		
		// This I set in because the panel was never originally designed for multiple gamemodes.
		
		CreateTimer(5.0, HUDReset);
		
		#if DEBUG
		LogMessage("Round Ended");
		#endif
	}
	
}

public OnMapEnd()
{
	#if DEBUG
	LogMessage("Map has ended");
	#endif
	
	RoundStarted = false;
	RoundEnded = true;
	LeavedSafeRoom = false;
	roundInProgress = false;
	
}

public Action:PlayerLeftStart(Handle:Timer)
{
	if (LeftStartArea())
	{
		// We don't care who left, just that at least one did
		if (!LeavedSafeRoom)
		{
			LeavedSafeRoom = true;
			
			// We reset some settings
			canSpawnBoomer = true;
			canSpawnSmoker = true;
			InitialSpawn = true;
			
			// We check if we need to spawn bots
			CheckIfBotsNeeded(true);
			#if DEBUG
			LogMessage("Checking to see if we need bots");
			#endif
			CreateTimer(3.0, InitialSpawnReset);
		}
	}
	else
	{
		CreateTimer(1.0, PlayerLeftStart);
	}
	
	return Plugin_Continue;
}



// This is hooked to the panic event, but only starts if its survival. This is what starts up the bots in survival.

public Action:evtSurvivalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	if (GameMode == 3)
	{  
		
		// We don't care who left, just that at least one did
		if (!LeavedSafeRoom)
		{
			
			LeavedSafeRoom = true;
			
			// We reset some settings
			canSpawnBoomer = true;
			canSpawnSmoker = true;
			InitialSpawn = true;
			
			// We check if we need to spawn bots
			CheckIfBotsNeeded(true);
			#if DEBUG
			LogMessage("Checking to see if we need bots");
			#endif
			CreateTimer(3.0, InitialSpawnReset);
		}
		
	}
	
	return Plugin_Continue;
}

public Action:InitialSpawnReset(Handle:Timer)
{
	InitialSpawn = false;
}

public Action:BotReadyReset(Handle:Timer)
{
	BotReady = 0;
}

//Checks the amount of survivor bots and activate the entities if the team is filled with bots. We create a timer that fires an entity to get around the stuck bot problem
// MI 5
// This function has been removed and a plugin by AtomicStryker now does this.



// The Versus Door Unlocker function unlocks the door when the round starts if there is only one survivor player.

public Action:VersusDoorUnlocker(Handle:Timer)
{
	if (!LeavedSafeRoom)
	{
		new bot = CreateFakeClient("tempbot");
		if (bot != 0)
		{
			ChangeClientTeam(bot,TEAM_INFECTED);
			CreateTimer(0.1,kickbot,bot);
		}
		else
		{
			LogError("Temperory Infected Bot was not spawned for the Versus Door Unlocker!");
		}
		CreateTimer(10.0, VersusDoorUnlocker);
	}
}

public Action:InfectedPlayerJoiner(Handle:Timer, any:client)
{
	// This code puts players on the infected after the survivor team has been filled.
	
	// set variables
	new SurvivorRealCount;
	new SurvivorLimit = GetConVarInt(FindConVar("survivor_limit"));
	
	// reset counters
	SurvivorRealCount = 0;
	
	// First we count the ammount of survivor real players
	
	for (new i=1; i<=MaxClients; i++)
	{
		// If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is survivor ...
		if (GetClientTeam(i)==TEAM_SURVIVOR)
		{
			// If player is a real player ... 
			if (!IsFakeClient(i))
			{
				SurvivorRealCount++;
				#if DEBUG
				LogMessage("Found a survivor player");
				#endif
			}
		}
	}
	// If the survivor team is full
	if (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR && !IsFakeClient(client) && SurvivorRealCount == SurvivorLimit)
	{
		ChangeClientTeam(client, TEAM_INFECTED);
		PrintHintText(client, "INFECTED BOTS PLUGIN: Placing you on the Infected team due to survivor team being full");
	}
	else if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == TEAM_SPECTATOR && SurvivorRealCount < SurvivorLimit)
	{
		FakeClientCommand(client, "jointeam 2");
		PrintHintText(client, "INFECTED BOTS PLUGIN: Placing you on the Survivor team");
	}
}

public Action:InfectedBotBooterVersus(Handle:Timer)
{
	//This is to check if there are any extra bots and boot them if necessary, excluding tanks, versus only
	if (GameMode == 2)
	{
		// 1 = Hunter, 2 = Smoker, 3 = Boomer
		
		// current count ...
		new total = 0;
		
		for (new i=1; i<=MaxClients; i++)
		{
			// if player is connected and ingame ...
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				// if player is on infected's team
				if (GetClientTeam(i) == TEAM_INFECTED)
				{
					
					// We count depending on class ...
					if (!IsPlayerTank(i) || (IsPlayerTank(i) && GetClientHealth(i) <= 1))
					{
						total++;
					}
					
				}
			}
		}
		if (total + InfectedBotQueue > MaxPlayerZombies)
		{
			new kick = total + InfectedBotQueue - MaxPlayerZombies; 
			new kicked = 0;
			
			// We kick any extra bots ....
			for (new i=1;(i<=MaxClients)&&(kicked < kick);i++)
			{
				// If player is infected and is a bot ...
				if (IsClientConnected(i) && IsFakeClient(i) && IsClientInGame(i))
				{
					//  If bot is on infected ...
					if (GetClientTeam(i) == TEAM_INFECTED)
					{
						
						// If player is not a tank
						if (!IsPlayerTank(i) || (IsPlayerTank(i) && GetClientHealth(i) <= 1))
						{
							// timer to kick bot
							CreateTimer(0.1,kickbot,i);
							
							// increment kicked count ..
							kicked++;
							#if DEBUG
							LogMessage("Kicked a Bot");
							#endif
						}
					}
				}
			}
		}
	}
}

// This code, combined with Durzel's code, announce certain messages to clients when they first enter the server

public OnClientPutInServer(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	// Durzel's code
	
	decl String:clientSteamID[32];
	new foundKey, doHideHUD;
	
	GetClientAuthString(client, clientSteamID, 32);
	
	// Try and find their HUD visibility preference
	foundKey = GetTrieValue(Handle:usrHUDPref, clientSteamID, doHideHUD);
	if (foundKey) {
		if (doHideHUD) {
			// This user chose not to view the HUD at some point in the game
			hudDisabled[client] = 1;
		}
	}
	// End Durzel's code
	
	if ((client) && (GameMode != 2) && (JoinableTeams))
	{
		CreateTimer(30.0, AnnounceJoinInfected, client);
		CreateTimer(15.0, InfectedPlayerJoiner, client);
	}
	
	// This sets sb_all_bot_team to 1 when a player comes into the server, this allows the server to hibernate
	
	SetConVarInt(FindConVar("sb_all_bot_team"), 1);
	
	#if DEBUG
	LogMessage("OnClientPutInServer has started");
	#endif
}

public Action:JoinInfected(client, args)
{
	if ((client) && (GameMode != 2) && (JoinableTeams) && (GameMode != 0))
	{
		ChangeClientTeam(client, TEAM_INFECTED);
	}
}

public Action:JoinSurvivors(client, args)
{
	if ((client) && (GameMode != 2) && (GameMode != 0))
	{
		FakeClientCommand(client, "jointeam 2");
	}
}

// Joining spectators is for developers only, commented in the final

public Action:JoinSpectator(client, args)
{
	if ((client) && (JoinableTeams))
	{
		ChangeClientTeam(client, TEAM_SPECTATOR);
	}
}

public Action:AnnounceJoinInfected(Handle:timer, any:client)
{
	if ((JoinableTeamsAnnounce) && (JoinableTeams) && (GameMode != 2) && (GameMode != 0) && (IsClientConnected(client)) && (IsClientInGame(client) && (!IsFakeClient(client))))
	{
		PrintHintText(client, "Infected Bots Plugin: Type !ji in chat to join the infected team or type !js to join the survivors!");
	}
}

public Action:evtPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
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
	if (GetClientTeam(client)==TEAM_INFECTED)
	{
		
		// Change the Gamemode to versus so that players can spawn as bots if free spawning is on
		
		if (DirectorSpawn && GameMode != 2)
		{
			
			if ((FreeSpawn && PlayerReady()) || (!FreeSpawn && FinaleGlitchStopBot))
			{
				ToVersus();
			}
			
			
			if (IsPlayerSmoker(client))
			{
				if (IsFakeClient(client))
				{
					if (!SpecialHalt)
					{
						CreateTimer(0.1, kickbot, client);
						
						#if DEBUG
						LogMessage("Smoker kicked");
						#endif
						
						new BotNeeded = 1;
						if (!FinaleGlitchStopBot)
						{
							CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
						}
						
						#if DEBUG
						LogMessage("Spawned Smoker");
						#endif
					}
				}
			}
			else if (IsPlayerBoomer(client))
			{
				if (IsFakeClient(client))
				{
					if (!SpecialHalt)
					{
						CreateTimer(0.1, kickbot, client);
						
						#if DEBUG
						LogMessage("Boomer kicked");
						#endif
						
						new BotNeeded = 2;
						if (!FinaleGlitchStopBot)
						{
							CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
						}
						
						#if DEBUG
						LogMessage("Spawned Booomer");
						#endif
					}
				}
			}
			else if (IsPlayerHunter(client))
			{
				if (IsFakeClient(client))
				{
					if (!SpecialHalt)
					{
						CreateTimer(0.1, kickbot, client);
						
						#if DEBUG
						LogMessage("Hunter Kicked");
						#endif
						
						new BotNeeded = 3;
						if (!FinaleGlitchStopBot)
						{
							CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
						}
						
						#if DEBUG
						LogMessage("Hunter Spawned");
						#endif
					}
				}
			}
		}
		
		if (IsPlayerTank(client))
		{
			if (LeavedSafeRoom)
			{
				#if DEBUG
				LogMessage("Tank Event Triggered");
				#endif
				if (!TankFrustStop)
				{
					TanksPlaying = 0;
					MaxPlayerTank = 0;
					for (new i=1;i<=MaxClients;i++)
					{
						// If player is not connected ...
						if (!IsClientConnected(i)) continue;
						
						// We check if player is in game
						if (!IsClientInGame(i)) continue;
						
						// Check if client is infected ...
						if (GetClientTeam(i)==TEAM_INFECTED)
						{
							
							// If player is a tank
							if (IsPlayerTank(i) && GetClientHealth(i) > 1)
							{
								TanksPlaying++;
								MaxPlayerTank++;
							}
						}
					}
					
					MaxPlayerTank = MaxPlayerTank + MaxPlayerZombies;
					SetConVarInt(FindConVar("z_max_player_zombies"), MaxPlayerTank);
					#if DEBUG
					LogMessage("Incremented Max Zombies from Tank Spawn EVENT");
					#endif
					
					if (GameMode != 1)
					{
						CreateTimer(0.5, TankSpawner, client);
					}
				}
			}
		}
		
		// This fixes the music glitch thats been bothering me and many players for a long time. The music keeps playing over and over when it shouldn't. Doesn't execute
		// on versus.
		if (GameMode != 2 && !IsFakeClient(client))
		{
			ClientCommand(client, "music_dynamic_stop_playing Event.MissionStart_BaseLoop_Hospital");
			ClientCommand(client, "music_dynamic_stop_playing Event.MissionStart_BaseLoop_Airport");
			ClientCommand(client, "music_dynamic_stop_playing Event.MissionStart_BaseLoop_Farm");
			ClientCommand(client, "music_dynamic_stop_playing Event.MissionStart_BaseLoop_Small_Town");
			ClientCommand(client, "music_dynamic_stop_playing Event.MissionStart_BaseLoop_Garage");
			ClientCommand(client, "music_dynamic_stop_playing Event.CheckPointBaseLoop_Hospital");
			ClientCommand(client, "music_dynamic_stop_playing Event.CheckPointBaseLoop_Airport");
			ClientCommand(client, "music_dynamic_stop_playing Event.CheckPointBaseLoop_Small_Town");
			ClientCommand(client, "music_dynamic_stop_playing Event.CheckPointBaseLoop_Farm");
			ClientCommand(client, "music_dynamic_stop_playing Event.CheckPointBaseLoop_Garage");
			ClientCommand(client, "music_dynamic_stop_playing Event.Zombat");
			ClientCommand(client, "music_dynamic_stop_playing Event.Zombat_A2");
			ClientCommand(client, "music_dynamic_stop_playing Event.Zombat_A3");
			ClientCommand(client, "music_dynamic_stop_playing Event.Tank");
			ClientCommand(client, "music_dynamic_stop_playing Event.TankMidpoint");
			ClientCommand(client, "music_dynamic_stop_playing Event.TankBrothers");
			ClientCommand(client, "music_dynamic_stop_playing Event.WitchAttack");
			ClientCommand(client, "music_dynamic_stop_playing Event.WitchBurning");
			ClientCommand(client, "music_dynamic_stop_playing Event.WitchRage");
			ClientCommand(client, "music_dynamic_stop_playing Event.HunterPounce");
			ClientCommand(client, "music_dynamic_stop_playing Event.SmokerChoke");
			ClientCommand(client, "music_dynamic_stop_playing Event.SmokerDrag");
			ClientCommand(client, "music_dynamic_stop_playing Event.VomitInTheFace");
			ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangTwoHands");
			ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangOneHand");
			ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFingers");
			ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangAboutToFall");
			ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFalling");
			ClientCommand(client, "music_dynamic_stop_playing Event.Down");
			ClientCommand(client, "music_dynamic_stop_playing Event.BleedingOut");
			ClientCommand(client, "music_dynamic_stop_playing Event.Down");
		}
		
	}
	
	return Plugin_Continue;
}

public Action:evtPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
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
	if (GetClientTeam(client)!=TEAM_INFECTED)
		return Plugin_Continue;
	
	// We count depending on class ...
	
	// This code had me bewildered for days. This code restricts spawns on certain classes, to prevent for example, a boomer spawning three seconds after a boomer spawned.
	// So I took the Infected spawn time, and added one second to it, making that player into a hunter to allow other players to take the class.
	// Below that, is the tank slot code. Or part of it. It detects if an AI or player tank died, and deducts it from the field respectively. Also tells the plugin that a
	// spot is available for another player to take the tank.
	
	// The code below that is part of the Director spawning code. It tells the plugin whether an infected has died and it deducts. The tank code is also used there as 
	// well (redundent?).
	
	if (!DirectorSpawn)
	{
		if (IsPlayerBoomer(client))
		{
			canSpawnBoomer = false;
			CreateTimer(float(InfectedSpawnTime + 1), ResetSpawnRestriction, 3);
			#if DEBUG
			LogMessage("Boomer died, setting spawn restrictions");
			#endif
		}
		else if (IsPlayerSmoker(client))
		{
			canSpawnSmoker = false;
			CreateTimer(float(InfectedSpawnTime + 1), ResetSpawnRestriction, 2);
		}
	}
	
	if (IsPlayerTank(client))
	{
		TankWasSeen = false;
	}
	
	// determines if victim was a bot ...
	new bool:victimisbot = GetEventBool(event, "victimisbot");
	
	// if victim was a bot, we setup a timer to spawn a new bot ...
	if ((victimisbot) && (GameMode == 2) && (!DirectorSpawn))
	{
		CreateTimer(float(InfectedSpawnTime), Spawn_InfectedBot, _, 0);
		InfectedBotQueue++;
		
		#if DEBUG
		PrintToChatAll("An infected bot has been added to the spawn queue...");
		#endif
	}
	// This spawns a bot in coop/survival regardless if the special that died was controlled by a player, MI 5
	if ((GameMode != 2) && (!DirectorSpawn))
	{
		
		CreateTimer(float(InfectedSpawnTime), Spawn_InfectedBot, _, 0);
		InfectedBotQueue++;
		
		#if DEBUG
		PrintToChatAll("An infected bot has been added to the spawn queue...");
		#endif
	}
	
	//This will prevent the stats board from coming up if the cvar was set to 1
	if (!IsFakeClient(client) && !StatsBoard && GameMode != 2)
	{
		CreateTimer(1.0, ZombieClassTimer, client);
	}
	
	// Removes Sphere bubbles in the map when a player dies and tell the plugin they no logner have their flashlight
	
	if (GameMode != 2)
	{
		CreateTimer(0.1, ScrimmageTimer, client);
	}
	
	
	return Plugin_Continue;
}

public Action:Spawn_InfectedBot_Director(Handle:timer, any:BotNeeded)
{
	// Don't go into this function if free spawning is on and a player is ready to spawn
	
	if (FreeSpawn && PlayerReady())
	{
		return;
	}
	
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetDead[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && (!IsFakeClient(i)) && IsClientInGame(i)) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				// If player is a ghost ....
				if (IsPlayerGhost(i))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
					resetDead[i] = true;
					SetAliveStatus(i, true);
				}
				else if (!IsPlayerAlive(i) && respawnDelay[i] > 0 && GameMode != 2)
				{
					resetLife[i] = true;
					SetLifeState(i, false);
					#if DEBUG
					LogMessage("Detected a dead player with a respawn timer, setting restrictions to prevent player from taking a bot");
					#endif
				}
			}
		}
	}
	// This code here kicks the infected bot that the director spawns, and is replaced by one spawned by the plugin. This allows that infected bot to be playable.
	
	new anyclient = GetAnyClient();
	new bool:temp = false;
	if (anyclient == 0)
	{
		#if DEBUG
		LogMessage("[Infected bots] Creating temp client to fake command");
		#endif
		
		// we create a fake client
		anyclient = CreateFakeClient("Bot");
		if (anyclient == 0)
		{
			LogError("[L4D] Infected Bots: CreateFakeClient returned 0 -- Infected bot was not spawned");
			wait = false;
		}
		temp = true;
	}
	
	// Add Root Admin flag
	new admindata = GetUserFlagBits(anyclient);
	if (h_AdminCheatsDetected != INVALID_HANDLE)
	{
		SetUserFlagBits(anyclient, ADMFLAG_ROOT);
	}
	
	// enable the z_spawn command without sv_cheats
	new String:command[] = "z_spawn";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	
	new CurrentGameMode = GameMode;
	
	if (GameMode != 2 && !FreeSpawn)
	{
		// This is to tell the plugin not to execute the gamemode ConVarHook
		DoNotChangeGameMode = true;
		
		// Set the Gamemode to versus so that the spawned infected will spawn with a flashlight
		SetConVarString(FindConVar("mp_gamemode"), "versus");
	}
	
	SpecialHalt = true;
	
	switch (BotNeeded)
	{
		case 1: // Smoker
		FakeClientCommand(anyclient, "z_spawn smoker auto", command);
		case 2: // Boomer
		FakeClientCommand(anyclient, "z_spawn boomer auto", command);
		case 3: // Hunter
		FakeClientCommand(anyclient, "z_spawn hunter auto", command);
	}
	
	SpecialHalt = false;
	
	if (!FreeSpawn)
	{
		// Restore the Gamemode
		if (CurrentGameMode == 1)
		{
			SetConVarString(FindConVar("mp_gamemode"), "coop");
			DoNotChangeGameMode = false;
		}
		else if (CurrentGameMode == 3)
		{
			SetConVarString(FindConVar("mp_gamemode"), "survival");
			DoNotChangeGameMode = false;
		}
	}
	
	// restore z_spawn and user flags
	
	if (h_AdminCheatsDetected != INVALID_HANDLE)
	{
		SetUserFlagBits(anyclient, admindata);
	}
	SetCommandFlags(command, flags);
	
	// We restore the player's status
	for (new i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i] == true)
			SetGhostStatus(i, true);
		if (resetDead[i] == true)
			SetAliveStatus(i, false);
		if (resetLife[i] == true)
			SetLifeState(i, true);
	}
	// If client was temp, we setup a timer to kick the fake player
	if (temp) CreateTimer(0.1,kickbot,anyclient);
}

public Action:CullingTimer(Handle:timer, any:client)
{
	if (client != 0)
	{
		if (!IsPlayerGhost(client))
		{
			SetCullingStatus(client, true);
			CreateTimer(0.1, CullingTimer, client);
		}
	}
}


public Action:ZombieClassTimer(Handle:timer, any:client)
{
	if (client != 0)
	{
		SetZombieClass(client, false);
	}
}

public Action:RestoreFreeSpawn(Handle:timer)
{
	FreeSpawn = false;
}

public Action:ResetSpawnRestriction (Handle:timer, any:bottype)
{
	#if DEBUG
	LogMessage("Resetting spawn restrictions for either Smoker or Boomer");
	#endif
	switch (bottype)
	{
		case 2: // smoker
		canSpawnSmoker = true;
		case 3: // boomer
		canSpawnBoomer = true;
	}
	
}

public Action:evtPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	// If player is a bot, we ignore this ...
	new bool:isbot = GetEventBool(event, "isbot");
	if (isbot) return Plugin_Continue;
	
	// We get some data needed ...
	new newteam = GetEventInt(event, "team");
	new oldteam = GetEventInt(event, "oldteam");
	
	// We get the client id and time
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// If player's new/old team is infected, we recount the infected and add bots if needed ...
	if (!RoundEnded && LeavedSafeRoom && (oldteam == 3||newteam == 3) && GameMode == 2)
	{
		CheckIfBotsNeeded(false);
	}
	if (!RoundEnded && LeavedSafeRoom && newteam == 3 && GameMode == 2)
	{
		//Kick Timer
		CreateTimer(1.0, InfectedBotBooterVersus);
		#if DEBUG
		LogMessage("A player switched to infected, attempting to boot a bot");
		#endif
	}
	else if ((newteam == 3 || newteam == 1) && GameMode != 2)
	{
		// Removes Sphere bubbles in the map when a player joins the infected team, or spectator team
		
		CreateTimer(0.1, ScrimmageTimer, client);
	}
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	// When a client disconnects we need to restore their HUD preferences to default for when 
	// a new client joins and fill the space.
	hudDisabled[client] = 0;
	clientGreeted[client] = 0;
	
	// Reset all other arrays
	respawnDelay[client] = 0;
	WillBeTank[client] = false;
	PlayerLifeState[client] = false;
	
	
	// If no real players are left in game ... and we restore sb_all_bot_team, MI 5
	if (!RealPlayersInGame(client))
	{	
		SetConVarInt(FindConVar("sb_all_bot_team"), 0);
		GameEnded();
	}
}

GameEnded()
{
	#if DEBUG
	LogMessage("Game ended");
	#endif
	LeavedSafeRoom = false;
	RoundEnded = true;
	RoundStarted = false;
	wait = false;
	roundInProgress = false;
	FinaleGlitchStopBot = false;
	isTankOnFire = false;
	
	// Zero all respawn times ready for the next round
	for (new i = 1; i <= MaxClients; i++) {
		respawnDelay[i] = 0;
	}
	
	// This I set in because the panel was never originally designed for multiple gamemodes.
	
	CreateTimer(5.0, HUDReset);
	
}

public Action:ScrimmageTimer (Handle:timer, any:client)
{
	if (client != 0)
	{
		SetScrimmageType(client, false);
	}
}

public Action:CheckIfBotsNeededLater (Handle:timer, any:spawn_immediately)
{
	CheckIfBotsNeeded(spawn_immediately);
}


CheckIfBotsNeeded(bool:spawn_immediately)
{
	if (!DirectorSpawn)
	{
		#if DEBUG
		LogMessage("Checking bots");
		#endif
		// If round has ended .. we ignore this
		if (RoundEnded) return;
		
		// We only listen to this if they leaved the safe room
		if (!LeavedSafeRoom) return;
		
		// If we must wait ...
		if (wait)
		{
			CreateTimer(2.0, CheckIfBotsNeededLater, spawn_immediately, 0);
			#if DEBUG
			LogMessage("Waiting at CheckIfBotsNeeded");
			#endif
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
			CountInfected_NoTank_Coop();
		}
		
		new diff = MaxPlayerZombies - (InfectedBotCount + InfectedRealCount + InfectedBotQueue);
		
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
					InfectedBotQueue++;
					CreateTimer(0.5, Spawn_InfectedBot, _, 0);
					#if DEBUG
					LogMessage("Setting up the bot now");
					#endif
				}
				else // We use the normal time ..
				{
					InfectedBotQueue++;
					CreateTimer(float(InfectedSpawnTime), Spawn_InfectedBot, _, 0);
				}
			}
		}
		
		
		if (GameMode == 2)
		{
			CountInfected_NoTank();
		}
		
		
		// we let other functions work in peace ...
		wait = false;
	}
}

CountInfected()
{
	// reset counters
	InfectedBotCount = 0;
	InfectedRealCount = 0;
	
	// First we count the ammount of infected real players and bots
	
	for (new i=1;i<=MaxClients;i++)
	{
		// If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i)==TEAM_INFECTED)
		{
			// If player is a bot ...
			if (IsFakeClient(i))
				InfectedBotCount++;
			else
			InfectedRealCount++;
		}
	}
	
}

CountInfected_NoTank()
{
	// reset counters
	InfectedBotCount = 0;
	InfectedRealCount = 0;
	
	// First we count the ammount of infected real players and bots
	
	for (new i=1;i<=MaxClients;i++)
	{
		// If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i)==TEAM_INFECTED)
		{
			
			// If player is not a tank
			if (!IsPlayerTank(i) || (IsPlayerTank(i) && GetClientHealth(i) <= 1))
			{
				// If player is a bot ...
				if (IsFakeClient(i))
					InfectedBotCount++;
				else
				InfectedRealCount++;
			}
		}
	}
	
}

// Note: This function is also used for survival.

CountInfected_NoTank_Coop()
{
	#if DEBUG
	LogMessage("Counting Bots for Coop");
	#endif
	
	// reset counters
	InfectedBotCount = 0;
	InfectedRealCount = 0;
	
	// First we count the ammount of infected real players and bots
	
	for (new i=1;i<=MaxClients;i++)
	{
		// If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i)==TEAM_INFECTED)
		{
			
			// If someone is a tank and the tank is playable...count him in play
			if ((IsPlayerTank(i) && GetClientHealth(i) > 1) && TankPlayer)
			{
				InfectedRealCount++;
			}
			
			// If player is not a tank
			if (!IsPlayerTank(i) || IsPlayerTank(i) && GetClientHealth(i) <= 1)
			{
				// If player is a bot ...
				if (IsFakeClient(i))
				{
					InfectedBotCount++;
					#if DEBUG
					LogMessage("Found a bot");
					#endif
				}
				else if (!IsFakeClient(i) && IsPlayerAlive(i) || !IsFakeClient(i) && IsPlayerGhost(i) && !FreeSpawn)
				{
					InfectedRealCount++;
					#if DEBUG
					LogMessage("Found a player");
					#endif
				}
				else if (!IsFakeClient(i) && FreeSpawn)
				{
					InfectedRealCount++;
					#if DEBUG
					LogMessage("Found a player");
					#endif
				}
			}
		}
	}
}

public Action:TankFrustratedTimer(Handle:timer)
{
	TankFrustStop = false;
}

public Action:TankHaltTimer(Handle:timer)
{
	TankHalt = false;
}

// This code here is to prevent a loop when the tank gets frustrated. Apparently the game counts a tank being frustrated as a spawned tank, and triggers the tank spawn
// event. Hmm...That may be why the rescue vehicle sometimes arrives earlier than expected...I was pondering one of Left 4 Dead's bugs.

public Action:evtTankFrustrated(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	TankFrustStop = true;
	#if DEBUG
	LogMessage("Tank is frustrated!");
	#endif
	CreateTimer(2.0, TankFrustratedTimer);
}

// This starts a timer that starts up the TankSpawner function. This is to make sure that every tank gets spawned correctly. It also increases the max player zombies cvar
// by one.


// The main Tank code, it allows a player to take over the tank when if allowed, and adds additional tanks if the tanks per spawn cvar was set.

public Action:TankSpawner(Handle:timer, any:client)
{
	#if DEBUGTANK
	LogMessage("Tank Spawner Triggred");
	#endif
	new Index[8];
	new IndexCount = 0;
	decl Float:position[3];
	
	if (client != 0 && IsClientInGame(client))
	{
		GetClientAbsOrigin(client, position);
	}
	
	if (TankPlayer && GameMode != 2)
	{
		for (new t=1;t<=MaxClients;t++)
		{
			// If player is not connected ...
			if (!IsClientConnected(t)) continue;
			
			// We check if player is in game
			if (!IsClientInGame(t)) continue;
			
			// Check if client is infected ...
			if (GetClientTeam(t)!=TEAM_INFECTED) continue;
			
			if (!IsFakeClient(t))
			{
				
				// If player is not a tank
				
				if (!IsPlayerTank(t) || (IsPlayerTank(t) && GetClientHealth(t) <= 1))
				{
					IndexCount++; // increase count of valid targets
					Index[IndexCount] = t; //save target to index
					#if DEBUGTANK
					PrintToChatAll("Client %i found to be valid Tank Choice", Index[IndexCount]);
					#endif
				}
			}	
		}
	}
	
	if (TankPlayer)
	{
		#if DEBUGTANK
		PrintToChatAll("Valid Tank Candidates found: %i", IndexCount);
		#endif
	}
	
	if (GameMode != 2 && TankPlayer && IndexCount != 0 )
	{
		TankKicker();
		#if DEBUGTANK
		PrintToChatAll("TankKicker was run.");
		#endif
	}
	
	if (TankPlayer && IndexCount != 0 && GameMode != 2)
	{
		new tank = GetRandomInt(1, IndexCount);  // pick someone from the valid targets
		WillBeTank[Index[tank]] = true;
		
		#if DEBUGTANK
		PrintToChatAll("Random Number pulled: %i, from %i", tank, IndexCount);
		PrintToChatAll("Client chosen to be Tank: %i", Index[tank]);
		#endif
		
		ChangeClientTeam(Index[tank], TEAM_SPECTATOR);
		ChangeClientTeam(Index[tank], TEAM_INFECTED);
	}
	
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetDead[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	if (TanksPlaying < TankLimit || TankPlayer && IndexCount != 0  && !TankHalt)
	{
		for (new i=1;i<=MaxClients;i++)
		{
			if (IsClientConnected(i) && (!IsFakeClient(i)) && IsClientInGame(i)) // player is connected and is not fake and it's in game ...
			{
				// If player is on infected's team and is dead ..
				if ((GetClientTeam(i)==TEAM_INFECTED) && WillBeTank[i] == false)
				{
					// If player is a ghost ....
					if (IsPlayerGhost(i))
					{
						resetGhost[i] = true;
						SetGhostStatus(i, false);
						resetDead[i] = true;
						SetAliveStatus(i, true);
						#if DEBUG
						LogMessage("Player is a ghost, taking preventive measures to prevent the player from taking over the tank");
						#endif
					}
					else if (!IsPlayerAlive(i))
					{
						resetLife[i] = true;
						SetLifeState(i, false);
						#if DEBUG
						LogMessage("Dead player found, setting restrictions to prevent the player from taking over the tank");
						#endif
					}
				}
			}
		}
		
		// Find any human client and give client admin rights
		new anyclient = GetAnyClient();
		new bool:temp = false;
		if (anyclient == 0)
		{
			#if DEBUG
			LogMessage("[Infected bots] Creating temp client to fake command");
			#endif
			// we create a fake client
			anyclient = CreateFakeClient("Bot");
			if (anyclient == 0)
			{
				LogError("[L4D] Infected Bots: CreateFakeClient returned 0 -- Infected Tank was not spawned");
				wait = false;
			}
			temp = true;
		}
		
		// Check to see if they have the root admin flag, give it to them if they don't have it
		
		new admindata = GetUserFlagBits(anyclient);
		
		if (h_AdminCheatsDetected != INVALID_HANDLE)
		{
			SetUserFlagBits(anyclient, ADMFLAG_ROOT);
		}
		
		
		// enable the z_spawn command without sv_cheats
		new String:command[] = "z_spawn";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		
		new CurrentGameMode = GameMode;
		decl String:difficulty[100];
		
		GetConVarString(FindConVar("z_difficulty"), difficulty, sizeof(difficulty));
		
		if (GameMode != 2)
		{
			// This is to tell the plugin not to execute the gamemode ConVarHook
			DoNotChangeGameMode = true;
			
			// Check the difficulty mode and adjust the tank health from there
			
			if (StrEqual(difficulty, "Easy", false))
			{
				SetConVarFloat(FindConVar("versus_tank_bonus_health"), 0.75);
			}
			else if (StrEqual(difficulty, "Normal", false))
			{
				SetConVarFloat(FindConVar("versus_tank_bonus_health"), 1.0);
			}
			else if (StrEqual(difficulty, "Hard", false))
			{
				SetConVarFloat(FindConVar("versus_tank_bonus_health"), 2.0);
			}
			else if (StrEqual(difficulty, "Impossible", false))
			{
				SetConVarFloat(FindConVar("versus_tank_bonus_health"), 2.0);
			}
			
			// Set the Gamemode to versus so that the spawned tank will spawn with a flashlight
			SetConVarString(FindConVar("mp_gamemode"), "versus");
		}
		
		FakeClientCommand(anyclient, "z_spawn tank auto", command);
		
		// Restore the Gamemode
		if (CurrentGameMode == 1)
		{
			SetConVarString(FindConVar("mp_gamemode"), "coop");
			ResetConVar(FindConVar("versus_tank_bonus_health"), true, true);
			DoNotChangeGameMode = false;
		}
		else if (CurrentGameMode == 3)
		{
			SetConVarString(FindConVar("mp_gamemode"), "survival");
			ResetConVar(FindConVar("versus_tank_bonus_health"), true, true);
			DoNotChangeGameMode = false;
		}
		
		
		
		// restore z_spawn and user flags
		SetCommandFlags(command, flags);
		if (h_AdminCheatsDetected != INVALID_HANDLE)
		{
			SetUserFlagBits(anyclient, admindata);
		}
		
		
		if (TankPlayer && GameMode != 2)
		{
			TankHalt = true;
		}
		
		// Start the Tank Halt Timer
		CreateTimer(2.0, TankHaltTimer);
		
		
		// We restore the player's status
		for (new i=1;i<=MaxClients;i++)
		{
			if (resetGhost[i] == true)
				SetGhostStatus(i, true);
			if (resetDead[i] == true)
				SetAliveStatus(i, false);
			if (resetLife[i] == true)
				SetLifeState(i, true);
			if (WillBeTank[i] == true)
			{
				if (client != 0)
				{
					TeleportEntity(i, position, NULL_VECTOR, NULL_VECTOR);
				}
				WillBeTank[i] = false;
			}
		}
		
		// If client was temp, we setup a timer to kick the fake player
		if (temp) CreateTimer(0.1,kickbot,anyclient);
		
		#if DEBUGTANK
		if (IsPlayerTank(i) && IsFakeClient(client))
		{
			PrintToChatAll("Bot Tank Spawn Event Triggered");
		}
		if (IsPlayerTank(i) && !IsFakeClient(client))
		{
			PrintToChatAll("Human Tank Spawn Event Triggered");
		}
		#endif
	}
	if (TanksPlaying < TankLimit)
	{
		CreateTimer(0.5, TankSpawner);
	}
	else if (TanksPlaying == TankLimit)
	{
		MaxPlayerTank = MaxPlayerZombies;
		SetConVarInt(FindConVar("z_max_player_zombies"), MaxPlayerZombies);
	}
}

public Action:HookSound_Callback(Clients[64], &NumClients, String:StrSample[PLATFORM_MAX_PATH], &Entity)
{
	if (TankWasSeen)
		return Plugin_Continue;
	
	if (!LeavedSafeRoom)
		return Plugin_Continue;
	
	//to work only on tank steps, its Tank_walk
	if (StrContains(StrSample, "Tank_walk", false) == -1) return Plugin_Continue;
	
	if (GameMode != 1)
		return Plugin_Continue;
	
	
	for (new i=1;i<=MaxClients;i++)
	{
		// If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i)==TEAM_INFECTED)
		{
			
			// If player is a tank
			if (IsPlayerTank(i) && GetClientHealth(i) > 1)
			{
				CreateTimer(0.1, TankSpawner, i);
			}
		}
	}
	TankWasSeen = true;
	return Plugin_Continue;
}

// This event serves to make sure the bots spawn at the start of the finale event. The director disallows spawning until the survivors have started the event, so this was
// definitely needed.

public Action:evtFinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	FinaleStarted = true;
	CheckIfBotsNeeded(true);
}

// This code was to fix an unintentional bug in Left 4 Dead. If it is coop, and the finale started with the survivors lost, the screen will stay stuck looking at the 
// finale and would not move at all. The only way to fix this is to either change the map, or spawn the infected as ghosts...which I have done here. However, if free 
// spawning is off, it will make the infected spawn normal again after the first spawn.

public Action:evtMissionLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && (!IsFakeClient(i)) && IsClientInGame(i)) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				if (FinaleStarted)
				{
					PrintToChat(i, "\x04[SM] \x03 Infected Bots: \x04Please wait, you will spawn as a \x03ghost \x04shortly to get by the finale glitch");
					FinaleGlitchStopBot = true;
					#if DEBUG
					LogMessage("Mission lost on the finale");
					#endif
				}
				respawnDelay[i] = 0;
			}
		}
	}
}


BotTypeNeeded()
{
	#if DEBUG
	LogMessage("Determining Bot type now");
	#endif
	
	// 1 = Hunter, 2 = Smoker, 3 = Boomer
	
	// current count ...
	new boomers=0;
	new smokers=0;
	
	for (new i=1;i<=MaxClients;i++)
	{
		// if player is connected and ingame ...
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			// if player is on infected's team
			if (GetClientTeam(i) == TEAM_INFECTED)
			{
				
				// We count depending on class ...
				if (IsPlayerSmoker(i) && GetClientHealth(i) > 1)
					smokers++;
				else if (IsPlayerBoomer(i) && GetClientHealth(i) > 1)
					boomers++;	
			}
		}
	}
	
	// We need a boomer??? can we spawn a boomer??? is boomer bot allowed??
	
	if ((smokers < SmokerLimit) && (canSpawnSmoker)) // we need a smoker ???? can we spawn a smoker ??? is smoker bot allowed ??
	{
		#if DEBUG
		LogMessage("Returning Smoker");
		#endif
		return 2;
	}
	if ((boomers < BoomerLimit) && (canSpawnBoomer))
	{
		#if DEBUG
		LogMessage("Returning Boomer");
		#endif
		return 3;
	}
	
	return 1;
}

ToVersus()
{
	new CurrentGameMode = GameMode;
	new OldHunterLimit = GetConVarInt(FindConVar("z_hunter_limit"));
	new OldSmokerLimit = GetConVarInt(FindConVar("z_gas_limit"));
	new OldBoomerLimit = GetConVarInt(FindConVar("z_exploding_limit"));
	new Handle:datapack = CreateDataPack();
	
	WritePackCell(datapack, CurrentGameMode);
	WritePackCell(datapack, OldHunterLimit);
	WritePackCell(datapack, OldSmokerLimit);
	WritePackCell(datapack, OldBoomerLimit);
	
	SetConVarInt(FindConVar("director_no_bosses"), 1);
	SetConVarFloat(FindConVar("versus_tank_chance"), 0.0);
	SetConVarFloat(FindConVar("versus_tank_chance_intro"), 0.0);
	SetConVarFloat(FindConVar("versus_tank_chance_finale"), 0.0);
	SetConVarFloat(FindConVar("versus_witch_chance"), 0.0);
	SetConVarFloat(FindConVar("versus_witch_chance_intro"), 0.0);
	SetConVarFloat(FindConVar("versus_witch_chance_finale"), 0.0);
	SetConVarInt(FindConVar("z_ghost_delay_max"), 0);
	SetConVarInt(FindConVar("z_ghost_delay_min"), 0);
	SetConVarInt(FindConVar("z_ghost_delay_minspawn"), 0);
	SetConVarInt(FindConVar("z_hunter_limit"), 999);
	SetConVarInt(FindConVar("z_gas_limit"), 999);
	SetConVarInt(FindConVar("z_exploding_limit"), 999);
	
	
	
	
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientConnected(i) && (!IsFakeClient(i)) && IsClientInGame(i)) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				if (!IsPlayerAlive(i) && respawnDelay[i] > 0)
				{
					SetLifeState(i, false);
					PlayerLifeState[i] = true;
				}
			}
		}
	}
	
	if (GameMode != 2)
	{
		// This is to tell the plugin not to execute the gamemode ConVarHook
		DoNotChangeGameMode = true;
		
		// Set the Gamemode to versus so that the spawned infected will spawn with a flashlight
		SetConVarString(FindConVar("mp_gamemode"), "versus");
	}
	
	CreateTimer(0.1, FromVersus, datapack);
	
}

public Action:FromVersus(Handle:timer, any:datapack)
{
	// Reset the data pack
	ResetPack(datapack);
	
	// Set the variables and retrieve the values from the datapack
	new CurrentGameMode = ReadPackCell(datapack);
	new OldHunterLimit = ReadPackCell(datapack);
	new OldSmokerLimit = ReadPackCell(datapack);
	new OldBoomerLimit = ReadPackCell(datapack);
	
	
	// Restore the Gamemode
	if (CurrentGameMode == 1)
	{
		SetConVarString(FindConVar("mp_gamemode"), "coop");
	}
	else if (CurrentGameMode == 3)
	{
		SetConVarString(FindConVar("mp_gamemode"), "survival");
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (PlayerLifeState[i] == true)
		{
			SetLifeState(i, true);
			PlayerLifeState[i] = false;
		}
		
		
	}
	
	ResetConVar(FindConVar("z_ghost_delay_max"), true, true);
	ResetConVar(FindConVar("z_ghost_delay_min"), true, true);
	ResetConVar(FindConVar("z_ghost_delay_minspawn"), true, true);
	ResetConVar(FindConVar("versus_tank_chance"), true, true);
	ResetConVar(FindConVar("versus_tank_chance_intro"), true, true);
	ResetConVar(FindConVar("versus_tank_chance_finale"), true, true);
	ResetConVar(FindConVar("versus_witch_chance"), true, true);
	ResetConVar(FindConVar("versus_witch_chance_intro"), true, true);
	ResetConVar(FindConVar("versus_witch_chance_finale"), true, true);
	ResetConVar(FindConVar("director_no_bosses"), true, true);
	
	if (!DirectorSpawn)
	{
		SetConVarInt(FindConVar("z_hunter_limit"), 0);
		SetConVarInt(FindConVar("z_gas_limit"), 0);
		SetConVarInt(FindConVar("z_exploding_limit"), 0);
	}
	else
	{
		SetConVarInt(FindConVar("z_hunter_limit"), OldHunterLimit);
		SetConVarInt(FindConVar("z_gas_limit"), OldSmokerLimit);
		SetConVarInt(FindConVar("z_exploding_limit"), OldBoomerLimit);
	}
	FinaleGlitchStopBot = false;
}

public Action:Spawn_InfectedBot(Handle:timer)
{
	
	
	// If round has ended, we ignore this request ...
	if (RoundEnded) return;
	
	// If round has not started
	if (!RoundStarted) return;
	
	// If survivors haven't leaved safe room ... we ignore this request (must be from previous round)
	if (!LeavedSafeRoom) return;
	
	new Infected = MaxPlayerZombies;
	
	if (Coordination && !DirectorSpawn && !InitialSpawn && !PlayerReady())
	{
		BotReady++;
		
		for (new i=1;i<=MaxClients;i++)
		{
			// If player is not connected ...
			if (!IsClientConnected(i)) continue;
			
			// We check if player is in game
			if (!IsClientInGame(i)) continue;
			
			// Check if client is infected ...
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				// If player is a real player 
				if (!IsFakeClient(i))
					Infected--;
			}
		}
	
		if (BotReady >= Infected)
		{
			CreateTimer(3.0, BotReadyReset);
		}
		else if (BotReady < Infected)
		{
			InfectedBotQueue--;
			return;
		}
		
	}
	
	
	// If busy, we setup a new timer in 1 sec...
	if (wait)
	{
		CreateTimer(1.0, Spawn_InfectedBot, _, 0);
		#if DEBUG
		LogMessage("Waiting at Spawn_InfectedBot");
		#endif
		return;
	}
	
	
	// Now we tell other functions to wait
	wait = true;
	
	// First we get the infected count
	if (GameMode == 2)
	{
		CountInfected();
	}
	if (GameMode != 2)
	{
		CountInfected_NoTank_Coop();
	}
	// If infected's team is already full ... we ignore this request (a real player connected after timer started ) ..
	if ((InfectedRealCount + InfectedBotCount) >= MaxPlayerZombies) 	
	{
		wait = false;
		#if DEBUG
		LogMessage("We found a player, don't spawn a bot");
		#endif
		return;
	}
	
	// Before spawning the bot, we determine if an real infected player is dead, since the new infected bot will be controlled by this player
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetDead[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && (!IsFakeClient(i)) && IsClientInGame(i)) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				// If player is a ghost ....
				if (IsPlayerGhost(i))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
					resetDead[i] = true;
					SetAliveStatus(i, true);
					#if DEBUG
					LogMessage("Player is a ghost, taking preventive measures for spawning an infected bot");
					#endif
				}
				else if (!IsPlayerAlive(i) && GameMode == 2) // if player is just dead and free spawning is on...
				{
					resetLife[i] = true;
					SetLifeState(i, false);
				}
				else if (!IsPlayerAlive(i) && respawnDelay[i] > 0)
				{
					resetLife[i] = true;
					SetLifeState(i, false);
					#if DEBUG
					LogMessage("Found a dead player, spawn time has not reached zero, delaying player to Spawn an infected bot");
					#endif
				}
			}
		}
	}
	
	// We get any client ....
	new anyclient = GetAnyClient();
	new bool:temp = false;
	if (anyclient == 0)
	{
		#if DEBUG
		LogMessage("[Infected bots] Creating temp client to fake command");
		#endif
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
	
	new admindata = GetUserFlagBits(anyclient);
	
	if (h_AdminCheatsDetected != INVALID_HANDLE)
	{
		SetUserFlagBits(anyclient, ADMFLAG_ROOT);
	}
	
	new String:command[] = "z_spawn";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	
	
	new CurrentGameMode = GameMode;
	
	if (GameMode != 2 && !FreeSpawn)
	{
		// This is to tell the plugin not to execute the gamemode ConVarHook
		DoNotChangeGameMode = true;
		
		// Set the Gamemode to versus so that the spawned infected will spawn with a flashlight
		SetConVarString(FindConVar("mp_gamemode"), "versus");
	}
	
	// Determine the bot class needed ...
	new bot_type = BotTypeNeeded();
	
	// We spawn the bot ...
	switch (bot_type)
	{
		case 0: // Nothing
		{
			FakeClientCommand(anyclient, "z_spawn hunter auto", command);
			#if DEBUG
			LogMessage("Bot_type returned NOTHING!");
			#endif
		}
		case 1: // Hunter
		{
			#if DEBUG
			LogMessage("Spawning Hunter");
			#endif
			FakeClientCommand(anyclient, "z_spawn hunter auto", command);
		}
		case 2: // Smoker
		{	
			#if DEBUG
			LogMessage("Spawning Smoker");
			#endif
			FakeClientCommand(anyclient, "z_spawn smoker auto", command);
		}
		case 3: // Boomer
		{
			#if DEBUG
			LogMessage("Spawning Boomer");
			#endif
			FakeClientCommand(anyclient, "z_spawn boomer auto", command);
		}
	}
	
	if (!FreeSpawn)
	{
		// Restore the Gamemode
		if (CurrentGameMode == 1)
		{
			SetConVarString(FindConVar("mp_gamemode"), "coop");
			DoNotChangeGameMode = false;
		}
		else if (CurrentGameMode == 3)
		{
			SetConVarString(FindConVar("mp_gamemode"), "survival");
			DoNotChangeGameMode = false;
		}
	}
	
	// restore z_spawn and user flags
	
	if (h_AdminCheatsDetected != INVALID_HANDLE)
	{
		SetUserFlagBits(anyclient, admindata);
	}
	SetCommandFlags(command, flags);
	
	// We restore the player's status
	for (new i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i] == true)
			SetGhostStatus(i, true);
		if (resetDead[i] == true)
			SetAliveStatus(i, false);
		if (resetLife[i] == true)
			SetLifeState(i, true);
		//ChangeClientTeam(i, 3)
	}
	
	// If client was temp, we setup a timer to kick the fake player
	if (temp) CreateTimer(0.1,kickbot,anyclient);
	
	// Debug print
	#if DEBUG
	PrintToChatAll("Spawning an infected bot. Type = %i ", bot_type);
	#endif
	
	// We decrement the infected queue
	InfectedBotQueue--;
	
	// we let other functions perform ...
	wait = false;
	
	CheckIfBotsNeeded(true);
	
	return;
}

public TankKicker ()
{
	
	for (new t=1;t<=MaxClients;t++)
	{
		// If player is not connected ...
		if (!IsClientConnected(t)) continue;
		
		// We check if player is in game
		if (!IsClientInGame(t)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(t)==TEAM_INFECTED)
		{
			
			if (IsFakeClient(t))
			{
				// If player is a tank
				if (IsPlayerTank(t) && GetClientHealth(t) > 1)
				{
					TanksPlaying--;
					MaxPlayerTank--;
					CreateTimer(0.1, kickbot, t);
					#if DEBUGTANK
					LogMessage("Tank Kicked");
					#endif
					break;
				}
			}
		}
		
	}
}


public GetAnyClient ()
{
	#if DEBUG
	LogMessage("[Infected bots] Looking for any real client to fake command");
	#endif
	for (new i=1;i<=MaxClients;i++)
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
		if (IsFakeClient(client)) KickClient(client,"Kick");
	}
}

bool:IsPlayerGhost (client)
{
	if (GetEntData(client, offsetIsGhost, 1))
		return true;
	else
	return false;
}

bool:IsPlayerSmoker (client)
{
	new class = GetEntProp(client,Prop_Send,"m_zombieClass");
	
	if(class == ZOMBIECLASS_SMOKER)
		return true;
	else
	return false;
}

bool:IsPlayerBoomer (client)
{
	new class = GetEntProp(client,Prop_Send,"m_zombieClass");
	
	if(class == ZOMBIECLASS_BOOMER)
		return true;
	else
	return false;
}

bool:IsPlayerHunter (client)
{
	new class = GetEntProp(client,Prop_Send,"m_zombieClass");
	
	if(class == ZOMBIECLASS_HUNTER)
		return true;
	else
	return false;
}

bool:IsPlayerTank (client)
{
	new class = GetEntProp(client,Prop_Send,"m_zombieClass");
	
	if(class == ZOMBIECLASS_TANK)
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
	{	
		SetEntData(client, offsetIsGhost, 1, 1, true);
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
	}
	else
	{
		SetEntData(client, offsetIsGhost, 0, 1, false);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

SetCullingStatus (client, bool:spawn)
{
	if (spawn)
		SetEntData(client, offsetIsCulling, 1, 1, true);
	else
	SetEntData(client, offsetIsCulling, 0, 1, false);
}

SetLifeState (client, bool:ready)
{
	if (ready)
		SetEntData(client,offsetlifeState, 1, 1, true);
	else
	SetEntData(client, offsetlifeState, 0, 1, false);
}

SetZombieClass (client, bool:stats)
{
	if (stats)
		SetEntData(client,offsetZombieClass, 1, 1, true);
	else
	SetEntData(client, offsetZombieClass, 0, 1, false);
}

SetScrimmageType (client, bool:scrim)
{
	if (scrim)
		SetEntData(client,offsetScrimmageType, 1, 1, true);
	else
	SetEntData(client, offsetScrimmageType, 0, 1, false);
}

bool:RealPlayersInGame (client)
{
	
	for (new i=1;i<=MaxClients;i++)
	{
		if (i != client)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
				return true;
		}
	}
	
	return false;
}

bool:BotsAlive ()
{
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i))
			if (GetClientTeam(i) == TEAM_INFECTED)
				return true;
		}
	
	return false;
}

MoreThanFivePlayers()
{
	
	new InfectedReal;
	
	// reset counters
	InfectedReal = 0;
	
	// First we count the ammount of infected real players and bots
	
	for (new i=1;i<=MaxClients;i++)
	{
		// If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i)==TEAM_INFECTED)
		{
			// If player is a real player ...
			if (!IsFakeClient(i))
				InfectedReal++;
		}
	}
	if (InfectedReal > 5)
	{
		return true;
	}
	else
	{
		return false;
	}
}

PlayerReady()
{
	// This function checks to see if a player has a respawn time and may prevent a bot from spawning in director spawning mode if theres a player ready to spawn 
	//with free spawning mode on 
	
	// First we count the ammount of infected real players
	
	for (new i=1;i<=MaxClients;i++)
	{
		// If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i)==TEAM_INFECTED)
		{
			// If player is a real player and is dead...
			if (!IsFakeClient(i) && GetClientHealth(i) <= 1)
			{
				if (respawnDelay[i] == 0)
				{
					return true;
				}
			}
		}
	}
	return false;
}

bool:LeftStartArea()
{
	new ent = -1, maxents = GetMaxEntities();
	for (new i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		new offset = FindSendPropInfo("CTerrorPlayerResource", "m_hasAnySurvivorLeftSafeArea");
		if (offset > 0)
		{
			if (GetEntData(ent, offset))
			{
				if (GetEntData(ent, offset) == 1) return true;
			}
		}
	}
	return false;
}

//---------------------------------------------Durzel's HUD------------------------------------------

public OnPluginEnd()
{
	// Destroy the persistent storage for client HUD preferences
	if (usrHUDPref != INVALID_HANDLE) {
		CloseHandle(usrHUDPref);
	}
	
	#if DEBUGHUD
	PrintToChatAll("\x01\x04[infhud]\x01 [%f] \x03Infected HUD\x01 stopped.", GetGameTime());
	#endif
}

public Menu_InfHUDPanel(Handle:menu, MenuAction:action, param1, param2) { return; }

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (IsClientInGame(client)) {
		if (GetClientTeam(client) == TEAM_INFECTED) {
			// Show welcoming instruction message to client
			PrintHintText(client, "This server runs \x03Infected Bots v%s\x01 - say !infhud to toggle HUD on/off", PLUGIN_VERSION);
			
			// This client now knows about the mod, don't tell them again for the rest of the game.
			clientGreeted[client] = 1;
		}
	}
}

public cvarZombieHPChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Handle a sysadmin modifying the special infected max HP cvars
	decl String:cvarStr[255];
	GetConVarName(convar, cvarStr, sizeof(cvarStr));
	decl String:difficulty[100];
	
	GetConVarString(FindConVar("z_difficulty"), difficulty, sizeof(difficulty));
	
	#if DEBUGHUD
	PrintToChatAll("\x01\x04[infhud]\x01 [%f] cvarZombieHPChanged(): Infected HP cvar '%s' changed from '%s' to '%s'", GetGameTime(), cvarStr, oldValue, newValue);
	#endif
	
	if (StrEqual(cvarStr, "z_hunter_health", false)) {
		zombieHP[0] = StringToInt(newValue);
	} else if (StrEqual(cvarStr, "z_gas_health", false)) {
		zombieHP[1] = StringToInt(newValue);
	} else if (StrEqual(cvarStr, "z_exploding_health", false)) {
		zombieHP[2] = StringToInt(newValue);
	} else if (StrEqual(cvarStr, "z_tank_health", false) && GameMode == 2) {
		zombieHP[3] = RoundToFloor(StringToInt(newValue) * 1.5);	// Tank health is multiplied by 1.5x in VS
	} else if (StrEqual(cvarStr, "z_tank_health", false) && GameMode != 2 && StrContains(difficulty, "Easy", false) != -1)  {
		zombieHP[3] = RoundToFloor(StringToInt(newValue) * 0.75);
	} else if (StrEqual(cvarStr, "z_tank_health", false) && GameMode != 2 && StrContains(difficulty, "Normal", false) != -1)  {
		zombieHP[3] = RoundToFloor(StringToInt(newValue) * 1.0);
	} else if (StrEqual(cvarStr, "z_tank_health", false) && GameMode != 2 && StrContains(difficulty, "Hard", false) != -1)  {
		zombieHP[3] = RoundToFloor(StringToInt(newValue) * 2.0);
	} else if (StrEqual(cvarStr, "z_tank_health", false) && GameMode != 2 && StrContains(difficulty, "Impossible", false) != -1)  {
		zombieHP[3] = RoundToFloor(StringToInt(newValue) * 2.0);
	}
}

public Action:monitorRespawn(Handle:timer)
{
	// Counts down any active respawn timers
	new i, foundActiveRTmr = false;
	
	// If round has ended then end timer gracefully
	if (!roundInProgress) {
		respawnTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	for (i = 1; i <= MaxClients; i++) {
		if (respawnDelay[i] > 0) {
			respawnDelay[i]--;
			foundActiveRTmr = true;
		}
	}
	
	if (!foundActiveRTmr && (respawnTimer != INVALID_HANDLE)) {
		// Being a ghost doesn't trigger an event which we can hook (player_spawn fires when player actually spawns),
		// so as a nasty kludge after the respawn timer expires for at least one player we set a timer for 1 second 
		// to update the HUD so it says "SPAWNING"
		if (delayedDmgTimer == INVALID_HANDLE) {
			delayedDmgTimer = CreateTimer(1.0, delayedDmgUpdate, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		// We didn't decrement any of the player respawn times, therefore we don't 
		// need to run this timer anymore.
		respawnTimer = INVALID_HANDLE;
		return Plugin_Stop;
	} else {
		if (doomedTankTimer == INVALID_HANDLE) ShowInfectedHUD(2);
	}
	return Plugin_Continue;
}

public Action:doomedTankCountdown(Handle:timer)
{
	// If round has ended then end timer gracefully
	if (!roundInProgress) {
		doomedTankTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	// Counts down the number of seconds before the Tank will die automatically
	// from fire damage (if not before from gun damage)
	if (isTankOnFire) {
		if (--burningTankTimeLeft <= 0) {
			// Tank is dead :(
			#if DEBUGHUD
			PrintToChatAll("\x01\x04[infhud]\x01 [%f] Tank died automatically from fire timer expiry.", GetGameTime());
			#endif
			isTankOnFire = false;
			doomedTankTimer = INVALID_HANDLE;
			return Plugin_Stop;
		} else {
			// This is almost the same as the respawnTimer code (which only updates the HUD in one of the two 1-second update
			// timer functions, however there may well be an instance in the game where both the Tank is on fire, and people are
			// respawning - therefore we need to make sure *at least one* of the 1-second timers updates the HUD, so we choose this
			// one (as it's rarer in game and therefore more optimal to do two extra code checks to achieve the same result).
			if (respawnTimer == INVALID_HANDLE || (doomedTankTimer != INVALID_HANDLE && respawnTimer != INVALID_HANDLE)) {
				ShowInfectedHUD(4);
			}
		}			
	} else {
		// If tank isn't on fire we shouldn't be running this function at all.
		doomedTankTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:delayedDmgUpdate(Handle:timer) 
{
	delayedDmgTimer = INVALID_HANDLE;
	ShowInfectedHUD(3);
	return Plugin_Handled;
}

public queueHUDUpdate(src)
{
	// queueHUDUpdate basically ensures that we're not constantly refreshing the HUD when there are one or more
	// timers active.  For example, if we have a respawn countdown timer (which is likely at any given time) then
	// there is no need to refresh 
	
	// Don't bother with infected HUD updates if the round has ended.
	if (!roundInProgress) return;
	
	if (respawnTimer == INVALID_HANDLE && doomedTankTimer == INVALID_HANDLE) {
		ShowInfectedHUD(src);
		#if DEBUGHUD
	} else {
		PrintToChatAll("\x01\x04[infhud]\x01 [%f] queueHUDUpdate(): Instant HUD update ignored, 1-sec timer active.", GetGameTime());
		#endif
	}	
}

public Action:showInfHUD(Handle:timer) 
{
	if (roundInProgress) {
		ShowInfectedHUD(1);
		return Plugin_Continue;
	} else {
		infHUDTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}		
}

public Action:Command_Say(client, args)
{
	decl String:clientSteamID[32];
	
	GetClientAuthString(client, clientSteamID, 32);
	
	
	
	if (InfHUD) {
		if (hudDisabled[client] == 0) {
			PrintToChat(client, "\x01\x04[infhud]\x01 Infected HUD DISABLED - say !infhud to re-enable.");
			SetTrieValue(usrHUDPref, clientSteamID, 1);
			hudDisabled[client] = 1;
		} else {
			PrintToChat(client, "\x01\x04[infhud]\x01 Infected HUD ENABLED - say !infhud to disable.");
			RemoveFromTrie(usrHUDPref, clientSteamID);
			hudDisabled[client] = 0;
		}
	} else {
		// Server admin has disabled Infected HUD server-wide
		PrintToChat(client, "\x01\x04[infhud]\x01 Infected HUD is currently DISABLED on this server for all players.");
	}	
	return Plugin_Handled;
	
	
}


public ShowInfectedHUD(src)
{
	if ((!InfHUD) || IsVoteInProgress()) {
		return;
	}
	
	// If no bots are alive, and if there is 5 or less players, no point in showing the HUD
	if (GameMode == 2 && !BotsAlive() && !MoreThanFivePlayers())
	{
		return;
	}
	
	
	#if DEBUGHUD
	decl String:calledFunc[255];
	switch (src) {
		case 1: strcopy(calledFunc, sizeof(calledFunc), "showInfHUD");
		case 2: strcopy(calledFunc, sizeof(calledFunc), "monitorRespawn");
		case 3: strcopy(calledFunc, sizeof(calledFunc), "delayedDmgUpdate");
		case 4: strcopy(calledFunc, sizeof(calledFunc), "doomedTankCountdown");
		case 10: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - client join");
		case 11: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - team switch");
		case 12: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - spawn");
		case 13: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - death");
		case 14: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - menu closed");
		case 15: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - player kicked");
		case 16: strcopy(calledFunc, sizeof(calledFunc), "evtRoundEnd");
		default: strcopy(calledFunc, sizeof(calledFunc), "UNKNOWN");
	}
	
	PrintToChatAll("\x01\x04[infhud]\x01 [%f] ShowInfectedHUD() called by [\x04%i\x01] '\x03%s\x01'", GetGameTime(), src, calledFunc);
	#endif 
	
	new i, team, ghostOffset;
	new playerIsAlive, playerIsGhost;
	decl String:iName[MAX_NAME_LENGTH];
	decl String:iClass[100];
	new iHP;
	
	decl String:lineBuf[100];
	decl String:iStatus[15];
	
	// Display information panel to infected clients
	pInfHUD = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	SetPanelTitle(pInfHUD, "INFECTED TEAM:");
	DrawPanelItem(pInfHUD, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	if (roundInProgress) {
		// Offset to detect whether player is a ghost or not
		ghostOffset = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
		
		// Loop through infected players and show their status
		for (i = 1; i <= MaxClients; i++) {
			if ((IsClientConnected(i) && IsClientInGame(i) && MoreThanFivePlayers() && !IsFakeClient(i)) || (IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i)) || (IsClientConnected(i) && IsClientInGame(i) && GameMode != 2 && !IsFakeClient(i))) {
				if (GetClientMenu(i) == MenuSource_RawPanel || GetClientMenu(i) == MenuSource_None) {
					team = GetClientTeam(i);
					if (team == TEAM_INFECTED) {
						GetClientName(i, iName, sizeof(iName));
						
						// Work out what they're playing as
						
						if (IsPlayerHunter(i)) {
							strcopy(iClass, sizeof(iClass), "Hunter");
							iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[0]) * 100);
						} else if (IsPlayerSmoker(i)) {
							strcopy(iClass, sizeof(iClass), "Smoker");
							iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[1]) * 100);
						} else if (IsPlayerBoomer(i)) {
							strcopy(iClass, sizeof(iClass), "Boomer");
							iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[2]) * 100);
						} else if (IsPlayerTank(i)) {
							strcopy(iClass, sizeof(iClass), "Tank");
							iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[3]) * 100);	
						}
						
						// Work out what the client is currently doing
						playerIsAlive = IsPlayerAlive(i);
						playerIsGhost = GetEntData(i,ghostOffset,1);
						if (playerIsAlive) {
							// Check to see if they are a ghost or not
							if (playerIsGhost == 1) {
								strcopy(iStatus, sizeof(iStatus), "GHOST");
							} else {
								Format(iStatus, sizeof(iStatus), "%i%%", iHP);
							}
						} else {
							if (respawnDelay[i] > 0 && !DirectorSpawn) {
								Format(iStatus, sizeof(iStatus), "DEAD (%i)", respawnDelay[i]);
								strcopy(iClass, sizeof(iClass), "");
								// As a failsafe if they're dead/waiting set HP to 0
								iHP = 0;
							} 
							else if (respawnDelay[i] >= 0 && DirectorSpawn && GameMode != 2) {
								Format(iStatus, sizeof(iStatus), "WAIT (%i)", respawnDelay[i]);
								strcopy(iClass, sizeof(iClass), "");
								// As a failsafe if they're dead/waiting set HP to 0
								iHP = 0;
							} 
							else if (respawnDelay[i] == 0 && GameMode != 2 && !DirectorSpawn) {
								Format(iStatus, sizeof(iStatus), "READY");
								strcopy(iClass, sizeof(iClass), "");
								// As a failsafe if they're dead/waiting set HP to 0
								iHP = 0;
								if (FreeSpawn || FinaleGlitchStopBot)
								{
									ToVersus();
								}
							} 
							else {
								Format(iStatus, sizeof(iStatus), "DEAD");
								strcopy(iClass, sizeof(iClass), "");
								// As a failsafe if they're dead/waiting set HP to 0
								iHP = 0;
							}
						}
						
						// Special case - if player is Tank and on fire, show the countdown
						if (StrContains(iClass, "Tank", false) != -1 && isTankOnFire && playerIsAlive) {
							Format(iStatus, sizeof(iStatus), "ON FIRE (%i)", burningTankTimeLeft);
						}
						
						if (IsFakeClient(i))
						{
							Format(lineBuf, sizeof(lineBuf), "%s-%s", iName, iStatus);
							
							DrawPanelItem(pInfHUD, lineBuf);
						}
						else if (!IsFakeClient(i))
						{
							Format(lineBuf, sizeof(lineBuf), "%s-%s-%s", iName, iClass, iStatus);
							
							DrawPanelItem(pInfHUD, lineBuf);
						}
					}
					#if DEBUGHUD
				} else {
					PrintToChat(i, "x01\x04[infhud]\x01 [%f] Not showing infected HUD as vote/menu (%i) is active", GetClientMenu(i), GetGameTime());
					#endif
				}
			}
		}
	}
	
	// Output the current team status to all infected clients
	// Technically the below is a bit of a kludge but we can't be 100% sure that a client status doesn't change
	// between building the panel and displaying it.
	for (i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
			team = GetClientTeam(i);
			if ((team == TEAM_INFECTED || GetClientTeam(i) == TEAM_SPECTATOR) && (hudDisabled[i] == 0) && (GetClientMenu(i) == MenuSource_RawPanel || GetClientMenu(i) == MenuSource_None)) {	
				SendPanelToClient(pInfHUD, i, Menu_InfHUDPanel, 5);
			}
		}
	}
	
	CloseHandle(pInfHUD);
}

public Action:evtTeamSwitch(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check to see if player joined infected team and if so refresh the HUD
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client) {
		if (GetClientTeam(client) == TEAM_INFECTED) {
			queueHUDUpdate(11);
		} else {
			// If player teamswitched to survivor, remove the HUD from their screen
			// immediately to stop them getting an advantage
			if (GetClientMenu(client) == MenuSource_RawPanel) {
				CancelClientMenu(client);
			}
		} 
	}
}

public Action:evtInfectedSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Infected player spawned, so refresh the HUD
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client) {
		if (GetClientTeam(client) == TEAM_INFECTED) {
			queueHUDUpdate(12); 
			
			// If player joins server and doesn't have to wait to spawn they might not see the announce
			// until they next die (and have to wait).  As a fallback we check when they spawn if they've 
			// already seen it or not.
			if (clientGreeted[client] == 0 && (Announce)) {		
				CreateTimer(3.0, TimerAnnounce, client);	
			}
		}
	}
}

public Action:evtInfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Infected player died, so refresh the HUD
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client) {
		if (GetClientTeam(client) == TEAM_INFECTED) {
			// If player is tank and dies before the fire would've killed them, kill the fire timer
			if (IsPlayerTank(client) && isTankOnFire && (doomedTankTimer != INVALID_HANDLE)) {
				#if DEBUGHUD
				PrintToChatAll("\x01\x04[infhud]\x01 [%f] Tank died naturally before fire timer expired.", GetGameTime());
				#endif
				isTankOnFire = false;
				KillTimer(doomedTankTimer);
				doomedTankTimer = INVALID_HANDLE;  
			}
			
			queueHUDUpdate(13);
		}
	}
}

public Action:evtInfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	// The life of a regular special infected is pretty transient, they won't take many shots before they 
	// are dead (unlike the survivors) so we can afford to refresh the HUD reasonably quickly when they take damage.
	// The exception to this is the Tank - with 5000 health the survivors could be shooting constantly at it 
	// resulting in constant HUD refreshes which is not efficient.  So, we check to see if the entity being 
	// shot is a Tank or not and adjust the non-repeating timer accordingly.
	
	// Don't bother with infected HUD update if the round has ended
	if (!roundInProgress) return;
	
	new mFlagsOffset;
	
	decl Handle:fireTankExpiry;
	decl String:difficulty[100];
	
	GetConVarString(FindConVar("z_difficulty"), difficulty, sizeof(difficulty));
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client) {
		if (GetClientTeam(client) == TEAM_INFECTED) {
			if (IsPlayerTank(client)) {
				
				// If player is a tank and is on fire, we start the 
				// 30-second guaranteed death timer and let his fellow Infected guys know.
				
				mFlagsOffset = FindSendPropOffs("CTerrorPlayer", "m_fFlags");
				if ((GetEntData(client, mFlagsOffset) & FL_ONFIRE) && (doomedTankTimer == INVALID_HANDLE) && IsPlayerAlive(client)) {
					isTankOnFire = true;
					if ((StrContains(difficulty, "Easy", false) != -1) && (GameMode == 1))
					{
						fireTankExpiry = FindConVar("tank_burn_duration_normal");
					}
					else if ((StrContains(difficulty, "Normal", false) != -1) && (GameMode == 1))
					{
						fireTankExpiry = FindConVar("tank_burn_duration_normal");
					}
					else if ((StrContains(difficulty, "Hard", false) != -1) && (GameMode == 1))
					{
						fireTankExpiry = FindConVar("tank_burn_duration_hard");
					}
					else if ((StrContains(difficulty, "Impossible", false) != -1) && (GameMode == 1))
					{
						fireTankExpiry = FindConVar("tank_burn_duration_expert");
					}
					else if (GameMode == 2 || GameMode == 3)
					{
						fireTankExpiry = FindConVar("z_tank_burning_lifetime");
					}
					burningTankTimeLeft = (fireTankExpiry != INVALID_HANDLE) ? GetConVarInt(fireTankExpiry) : 30;
					doomedTankTimer = CreateTimer(1.0, doomedTankCountdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);										
				}		
			}
			
			// If we only have the 5 second timer running then we do a delayed damage update
			// (in reality with 4 players playing it's unlikely all of them will be alive at the same time
			// so we will probably have at least one faster timer running)
			if (delayedDmgTimer == INVALID_HANDLE && respawnTimer == INVALID_HANDLE && doomedTankTimer == INVALID_HANDLE) {
				delayedDmgTimer = CreateTimer(2.0, delayedDmgUpdate, _, TIMER_FLAG_NO_MAPCHANGE);
			} 
			
		}
	}
}

public Action:evtInfectedWaitSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	
	// Don't bother with infected HUD update if the round has ended
	if (!roundInProgress) return;
	
	// Store this players respawn time in an array so we can present it to other clients
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new timetowait;
	
	if (client != 0)
	{
		if (GameMode == 2 && !IsFakeClient(client))
		{	
			timetowait = GetEventInt(event, "spawntime");
		}
		else if (GameMode != 2 && !IsFakeClient(client))
		{	
			timetowait = InfectedSpawnTime;
		}
		else if (IsFakeClient(client))
		{	
			timetowait = InfectedSpawnTime;
		}
	}
	if (client) {
		respawnDelay[client] = timetowait;
		// Only start timer if we don't have one already going.
		if (respawnTimer == INVALID_HANDLE) {
			// Note: If we have to start a new timer then there will be a 1 second delay before it starts, so 
			// subtract 1 from the pending spawn time
			respawnDelay[client] = (timetowait-1);
			respawnTimer = CreateTimer(1.0, monitorRespawn, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		
		// Send mod details/commands to the client, unless they have seen the announce already.
		// Note: We can't do this in OnClientPutInGame because the client may not be on the infected team
		// when they connect, and we can't put it in evtTeamSwitch because it won't register if the client
		// joins the server already on the Infected team.
		if (clientGreeted[client] == 0 && (Announce)) {
			CreateTimer(8.0, TimerAnnounce, client);	
		}
	}
}

public Action:HUDReset(Handle:timer)
{
	infHUDTimer 		= INVALID_HANDLE;	// The main HUD refresh timer
	respawnTimer 	= INVALID_HANDLE;	// Respawn countdown timer
	doomedTankTimer 	= INVALID_HANDLE;	// "Tank on Fire" countdown timer
	delayedDmgTimer 	= INVALID_HANDLE;	// Delayed damage update timer
	pInfHUD 		= INVALID_HANDLE;	// The panel shown to all infected users
}
