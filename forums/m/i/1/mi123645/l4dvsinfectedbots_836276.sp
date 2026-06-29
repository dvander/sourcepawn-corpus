/********************************************************************************************
* Plugin	: L4dVsInfectedBots (with Coop/Survival Playble SI spawns)
* Version	: 1.7.0
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
* 
* Thx to all who helped me test this plugin, specially:
* 	- AcidTester
* 	- Dark-Reaper 
*	- Mienaikage
* 	- Number Six
* 
**********************************************************************************************/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.7.0"
#define DEBUGMODE 0
#define HUD_FREQ 5


new offsetIsGhost;
new offsetIsAlive;

new bool:IsMapVS;

new bool:RoundStarted;
new bool:RoundEnded;
new bool:LeavedSafeRoom;
new GameMode;
new MaxInfected;
new InfectedRealCount;
new InfectedBotCount;
new InfectedBotQueue;
new InfectedSpawnTime;
new MaxHunters;
new MaxBoomers;
new MaxSmokers;
new bool:canSpawnBoomer;
new bool:canSpawnSmoker;
new bool:canSpawnHunter;
new bool:wait;
new bool:AllBotsTeam;
new Handle:h_AllowBoomerBots;
new Handle:h_AllowSmokerBots;
new Handle:h_AllowHunterBots;
new Handle:h_VersusHunterLimit;
new Handle:h_NormalizeSpawnTime;
new Handle:h_BotHudEnabled;
new Handle:h_CoopEnabled;
new Handle:h_MaxPlayerZombies;
new Handle:h_MaxPlayerZombies2;
new bool:AllowBoomerBots;
new bool:AllowSmokerBots;
new bool:AllowHunterBots;
new bool:NormalizeSpawnTime;
new bool:BotHudEnabled;
new bool:CoopEnabled;
new VersusHunterLimit;
new MaxPlayerZombies;

new zombieHP[4];					// Stores special infected max HP

public Plugin:myinfo = 
{
	name = "[L4D] VS Infected Bots",
	author = "djromero (SkyDavid) and MI 5",
	description = "Spawns infected bots for versus and playable infected bots for coop/survival",
	version = PLUGIN_VERSION,
	url = "www.sky.zebgames.com"
}

public OnPluginStart()
{
	// We find some offsets
	offsetIsGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	//offsetIsAlive = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	offsetIsAlive = 2236;
	
	// Infected maxs, MI 5 change
	MaxInfected = MaxPlayerZombies
	MaxBoomers = GetConVarInt(FindConVar("z_versus_boomer_limit"));
	MaxSmokers = GetConVarInt(FindConVar("z_versus_smoker_limit"));
	MaxHunters = VersusHunterLimit
	
	// We read the spawn time for infected ...
	InfectedSpawnTime = GetConVarInt(FindConVar("z_ghost_delay_max"));
	
	// We reset some variables
	InfectedBotQueue = 0;
	
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
	
	// console variables to disable boomer and smoker bots
	h_AllowBoomerBots = CreateConVar("l4d_infectedbots_allow_boomer", "1", "If 1, it will allow boomer bots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_AllowSmokerBots = CreateConVar("l4d_infectedbots_allow_smoker", "1", "If 1, it will allow smoker bots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_AllowHunterBots = CreateConVar("l4d_infectedbots_allow_hunter", "1", "If 1, it will allow hunter bots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_VersusHunterLimit = CreateConVar("l4d_versus_hunter_limit", "2", "Sets the limit for hunters spawned in versus by the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_NormalizeSpawnTime = CreateConVar("l4d_infectedbots_normalize_spawntime", "0", "If 1, all infected will spawn at maximum time", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_BotHudEnabled = CreateConVar("l4d_infectedbots_showhud", "1", "If infected bots hud will show", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_CoopEnabled = CreateConVar("l4d_infectedbots_enabled_on_coop", "1", "If 1, the plugin will be activated on coop/survival maps", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_MaxPlayerZombies = CreateConVar("l4d_infectedbots_max_player_zombies", "4", "Defines how many special infected can be on the map on coop/versus", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY); 
	h_MaxPlayerZombies2 = FindConVar("z_max_player_zombies");
	HookConVarChange(h_AllowBoomerBots, ConVarAllowBoomerBots);
	HookConVarChange(h_AllowSmokerBots, ConVarAllowSmokerBots);
	HookConVarChange(h_AllowHunterBots, ConVarAllowHunterBots);
  	HookConVarChange(h_VersusHunterLimit, ConVarVersusHunterLimit);
	HookConVarChange(h_NormalizeSpawnTime, ConVarNormalizeSpawnTime);
	HookConVarChange(h_BotHudEnabled, ConVarBotHudEnabled);
	HookConVarChange(h_CoopEnabled, ConVarCoopEnabled);
	HookConVarChange(h_MaxPlayerZombies, ConVarMaxPlayerZombies);
	AllowBoomerBots = GetConVarBool(h_AllowBoomerBots);
	AllowSmokerBots = GetConVarBool(h_AllowSmokerBots);
	AllowHunterBots = GetConVarBool(h_AllowHunterBots);
	VersusHunterLimit = GetConVarInt(h_VersusHunterLimit);
	NormalizeSpawnTime = GetConVarBool(h_NormalizeSpawnTime);
	BotHudEnabled = GetConVarBool(h_BotHudEnabled);
	CoopEnabled = GetConVarBool(h_CoopEnabled);
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
	
	
	//Create an auto config
	AutoExecConfig(true, "l4dvsinfectedbots");
	
	// We hook some events ...
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", PlayerTeam);
	HookEvent("player_left_start_area", PlayerLeftStart);
	HookEvent("player_spawn", PlayerSpawn);
	
	// We set some variables
	RoundStarted = false;
	RoundEnded = false;
	
	wait = false;
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

public ConVarCoopEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CoopEnabled = GetConVarBool(h_CoopEnabled);
}

public ConVarMaxPlayerZombies(Handle:convar, const String:oldValue[], const String:newValue[])
{
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
}

public ConVarNormalizeSpawnTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	NormalizeSpawnTime = GetConVarBool(h_NormalizeSpawnTime);
	
	if (NormalizeSpawnTime)
		SetConVarInt(FindConVar("z_ghost_delay_min"), InfectedSpawnTime);
	else
	ResetConVar(FindConVar("z_ghost_delay_min"));
}

TweakSettings ()
{
	
	
	//Faster attacking AI, MI 5 Code
	if (GameMode == 2)
   {
    SetConVarFloat(FindConVar("boomer_vomit_delay"), 0.1);
    SetConVarFloat(FindConVar("smoker_tongue_delay"), 0.1);
    ResetConVar(FindConVar("vs_max_team_switches"), true, true);
	 }
	
	if (GameMode != 2)
	{
    ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
    ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
    SetConVarInt(FindConVar("vs_max_team_switches"), 99);
	}
	
	// We tweak some settings ... with an additional vs team switch, MI 5 change
	SetConVarInt(FindConVar("z_attack_flow_range"), 50000);
	SetConVarInt(FindConVar("sb_all_bot_team"), 1);
	
	
	//MI 5 Code, Check to see if the plugin is enabled for coop/survival, so that the survivors can't spectate SI
	if (CoopEnabled)
	SetConVarInt(FindConVar("director_spectate_specials"), 1);
	else
  ResetConVar(FindConVar("director_spectate_specials"), true, true);
	
	if (NormalizeSpawnTime)
		SetConVarInt(FindConVar("z_ghost_delay_min"), InfectedSpawnTime);
	else
	ResetConVar(FindConVar("z_ghost_delay_min"), true, true);
}


public Action:UnTweakSettingsLater (Handle:timer)
{
	UnTweakSettings();
}

UnTweakSettings ()
{

	
	// We restore some settings
	ResetConVar(FindConVar("z_attack_flow_range"), true, true);
	ResetConVar(FindConVar("z_ghost_delay_min"), true, true);
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
	
	//Linking the handle MaxPlayerZombies2 with the variable MaxPlayerZombies, MI 5 Code
	SetConVarBounds(h_MaxPlayerZombies2, ConVarBound_Upper, false, 14.0);
	SetConVarInt(h_MaxPlayerZombies2, MaxPlayerZombies)
	
	//MI 5 Code, We determine what the gamemode is
	new string:GameName[16];
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
	MaxBoomers = GetConVarInt(FindConVar("z_exploding_limit"));
	MaxSmokers = GetConVarInt(FindConVar("z_gas_limit"));
	MaxHunters = GetConVarInt(FindConVar("z_hunter_limit"));
	}
	
	//MI 5 Code, We determine if the ConVar CoopEnabled is off and make sure that the gamemode is not versus
	if ((!CoopEnabled) && (GameMode !=2))
	{
	IsMapVS = false;
	}

	if (IsMapVS)
	{
		
		// If round haven't started ...
		if (!RoundStarted)
		{
		
			
			// and we reset some variables ...
			LeavedSafeRoom = false;
			RoundEnded = false;
			RoundStarted = true;
			//Start the Safe Room Timer for Coop/Survival, MI 5 Code, two timers for the two modes
			if (GameMode == 1)
			{
			CreateTimer(30.0, SafeTimer)
			}
			if (GameMode == 3)
			{
			CreateTimer(120.0, SafeTimer)
			}
			TweakSettings();
		}
	}
}

public Action:SafeTimer(Handle:timer)
{
// The safe room timer is in place when the round starts for coop/survival
		
	if (IsMapVS)
	{	
		if (!LeavedSafeRoom)
		{
			
			
			LeavedSafeRoom = true;
			
			// We reset some settings
			canSpawnBoomer = true;
			canSpawnSmoker = true;
			canSpawnHunter = true;
			
			// We start the hud timer
			//KillHudTimer();
			CreateTimer(float(HUD_FREQ), ShowHudThread, _, TIMER_REPEAT);
			
			// We check if we need to spawn bots
			CheckIfBotsNeeded(true);
		}
  }
 	return Plugin_Continue;
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
  //MI 5 Code, Initiate new timer when survivors leave the safe room, which may be canceled out by the safe timer
	if (GameMode == 3)
  {
  
  CreateTimer(45.0, SafeTimer)
  }
  
  	if (GameMode == 2)
  
  {  
	// We check is map is VS ....
    if (IsMapVS)
    {
      // We don't care who left, just that at least one did
      if (!LeavedSafeRoom)
      {
        
			
        LeavedSafeRoom = true;
			
        // We reset some settings, Added Hunter, MI 5
        canSpawnBoomer = true;
        canSpawnSmoker = true;
        canSpawnHunter = true;
        
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

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	//Added Hunter check, MI 5
	
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
			
			// and prevents boots from spawning on the same class ... Reduced time to spawn as they were spawning too long, MI 5
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
      			else if (StrContains(class, "hunter", false) != -1)
			{
				canSpawnHunter = false;
				CreateTimer(float(InfectedSpawnTime * 1), ResetSpawnRestriction, 1);
			}
		}
		
		
		// We give him health
		GiveHealth(client);
	}
	
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
  // Added Hunter check, MI 5
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
	
	// We count depending on class ... Reduced time to spawn as they were spawning too long, MI 5
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
	else if (StrContains(class, "hunter", false) != -1)
	{
		canSpawnHunter = false;
		CreateTimer(float(InfectedSpawnTime * 1), ResetSpawnRestriction, 1);
	}
	
	// determines if victim was a bot ...
	new bool:victimisbot = GetEventBool(event, "victimisbot");
	
	// if victim was a bot, we setup a timer to spawn a new bot ...
	if (victimisbot)
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
	
	// Added Hunter, MI 5
	switch (bottype)
	{
		case 1: // hunter
		canSpawnHunter = true;
		case 2: // smoker
		canSpawnSmoker = true;
		case 3: // boomer
		canSpawnBoomer = true;
	}
}

public Action:PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
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
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	// If is a real player
	if (IsFakeClient(client))
		return;
	
	// If no real players are left in game ... Reset for sb_all_bot_team 1 here as it was not working at GameEnded, MI 5
	if (!RealPlayersInGame(client))
	{	
		ResetConVar(FindConVar("sb_all_bot_team"), true, true);
		
		GameEnded();
	}
}

GameEnded()
{
	
	
	LeavedSafeRoom = false;
	RoundEnded = true;
	RoundStarted = false;
	wait = false;
	
	CreateTimer(2.0, UnTweakSettingsLater);  
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
	CountInfected();
	
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
	
	
	
	CountInfected_NoTank();
	
	// If we need to kick some bots ....
	if (diff < 0)
	{
		new kick = diff * -1;
		new String:class[100];
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
		if (GetClientTeam(i)==3)
		{
			// If player is a bot ... Added a check to allow players to be counted as bots in coop/survival, MI 5
			if (IsFakeClient(i))
				InfectedBotCount++;
			else if (GameMode == 2)				
				InfectedRealCount++;
		}
	}
	// is infected's team all bots ??? 
	if (InfectedRealCount == 0)
	{
	
	AllBotsTeam = true;
	}
	else
	{
	AllBotsTeam = false;
  }
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
		//if (GetClientTeam(i)==3)
		{
			// Get player model
			GetClientModel(i, class, sizeof(class));
			
			// If player is not a tank
			if (StrContains(class, "hulk", false) == -1)
			{
				// If player is a bot ... Added a check to allow players to be counted as bots in coop/survival, MI 5
				if (IsFakeClient(i))
					InfectedBotCount++;
				else if (GameMode == 2)        	
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
	
	// current count ... Added Hunter, MI 5
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
				
				// We count depending on class ... Added Hunter, MI 5
				if (StrContains(class, "boomer", false) != -1)
					boomers++;
				else if (StrContains(class, "smoker", false) != -1)
					smokers++;
				else if (StrContains(class, "hunter", false) != -1)
					hunters++;	
			}
		}
	}
	
	// buffer the variables ... Added Hunter, MI 5
	new bool:tmpAllowBoomerBots = AllowBoomerBots;
	new bool:tmpAllowSmokerBots = AllowSmokerBots;
	new bool:tmpAllowHunterBots = AllowHunterBots;
	
	// If team is made up of bots only ... we need all of them ... Added Hunter, MI 5
	if (AllBotsTeam)
	{
		tmpAllowBoomerBots = true;
		tmpAllowSmokerBots = true;
		tmpAllowHunterBots = true;
	}
	
	// We need a boomer??? can we spawn a boomer??? is boomer bot allowed?? MI 5 Code, adding the hunter limit
	if ((boomers < MaxBoomers) && (canSpawnBoomer) && (tmpAllowBoomerBots))
		return 3;
	else if ((smokers < MaxSmokers) && (canSpawnSmoker) && (tmpAllowSmokerBots)) // we need a smoker ???? can we spawn a smoker ??? is smoker bot allowed ??
		return 2;
	else if ((hunters < MaxHunters) && (canSpawnHunter) && (tmpAllowHunterBots)) // we need a hunter ???? can we spawn a hunter ??? is hunter bot allowed ??
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

  // Implemented a versus check to allow a coop/survival player SI to take control of an infected bot, MI 5
	
	if (GameMode == 2)
{   
     for (i=1;i<=GetMaxClients();i++)
    {
      if (IsClientConnected(i) && (!IsFakeClient(i)) && IsClientInGame(i)) // player is connected and is not fake and it's in game ...
      {
        // If player is on infected's team and is dead ..
        if (GetClientTeam(i)==3)
        {
          // If player is a ghost ....
          if (IsPlayerGhost(i))
          {
            resetGhost[i] = true;
            SetGhostStatus(i, false);
            resetDead[i] = true;
            SetAliveStatus(i, true);
          }
          else if (!IsPlayerAlive(i)) // if player is just dead ...
          {
            resetTeam[i] = true;
            ChangeClientTeam(i, 1);
          }
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
	
	
	// We spawn the bot ... Added Hunter, MI 5
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
	// Added versus check for reset flags for dead SI players, MI 5
	if (GameMode == 2)
	{
    // We restore the player's status
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
	
	// Now we show the hud to all real infected players
	
	for (i = 1; i <= GetMaxClients(); i++) 
	{
		// If player is connected, ingame and is not a bot ...
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i)) 
		{
			// if player is on infected's team ...
			if (GetClientTeam(i) == 3)
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

////////////////////////////////////////