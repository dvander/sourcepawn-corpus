/**
 * L4D Zombie Havoc
 * Based upon L4D SuperVersus by DDR Khat
 *
 * Created by Bigbuck
 * Thanks to Mad_Dugan for finale code
 * L4D SuperVersus tweaked and cleaned by Damizean
 * Thanks to AtomicStryker for the tank spawn code
 * Extra medkits code based off of YourEnemyPL's, Damizean's, and Paegus's work
 */

/**
	v1.0.0
	- Initial Release

	v1.1.0
	- Changed medkit spawning logic to support custom maps
	- Removed change team menu to prevent abusing it to respawn faster
	- Fixed all specials being kicked when a new special spawned
	- Code optimization and cleanup
	- Changed ConVar's from l4d_ to zm_

	v1.2.0
	- Added Auto Havoc: Automatically adjust difficulty based on survivor performance
	- Changed some ConVar's descriptions to be more explanatory
	- Fixed survivor limit not changing correctly
	- Added option to only spawn bots if there are more than four survivors

	v1.3.0
	- Changed ConVar's from zm_ to l4d_zh_
	- Added translation file for easy translations
	- Removed Coop gamemode requirement
	- Fixed broken URL in plugin info
	- Fixed some incorrect map names in Zombie Havoc admin map menu
	- Added automatic spawning of bots for human take over when needed

	v1.3.1b
	- Changed ConVar's from l4d_zh to sm_l4d_zh (Sorry, I was trying to find a standardized way of naming them)
	- Hopefully fixed automatic spawning of bots

	v1.3.2b
	- Changed ConVar's to sm_l4d_zh from sm_l4d (Last time I promise)
	- Fixed client not connected error found in v1.3.1b
	- Updated handling of automatic spawning of bots
	- Updated automatic map changing for 9-29-09 L4D update

	v1.3.3
	- Changed FakeClientCommand to ChangeClientTeam in automatic spawning function
	- Fixed spawning of 8 survivors no mattter what settings
	- Added check to reduce sm_l4d_zh_survivors_min_limit if a human player leaves
	- Added admin command !sm_addbot to add a bot manually instead of using RCON
	- Updated custom map menu to include new Crash Course campaign
	- Fixed spelling mistake in sm_l4d_zh_survivor_min_LIMIT not imit
*/

// Force strict semicolon mode
#pragma semicolon 1

/**
 * Includes
 *
 */
#include <sourcemod>
#include <sdktools>
// Make the admin menu optional
#undef REQUIRE_PLUGIN
#include <adminmenu>

/**
 * Optional Includes
 *
 */
native L4D_LobbyUnreserve();
native L4D_LobbyIsReserved();

/**
 * Constants
 *
 */
#define PLUGIN_VERSION	"1.3.3"
#define CVAR_FLAGS		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define MEDKIT				"models/w_models/weapons/w_eq_Medkit.mdl"

/**
 * Handles
 *
 */
new Handle: Unreserve					= INVALID_HANDLE;
new Handle: L4D_SurvivorLimit		= INVALID_HANDLE;
new Handle: SurvivorMaxLimit		= INVALID_HANDLE;
new Handle: SurvivorMinLimit		= INVALID_HANDLE;
new Handle: AutomaticSpawning		= INVALID_HANDLE;
new Handle: SpawnTimer				= INVALID_HANDLE;
new Handle: SuperTank					= INVALID_HANDLE;
new Handle: SuperTankMultiplier	= INVALID_HANDLE;
new Handle: ExtraAidKits				= INVALID_HANDLE;
new Handle: ExtraAidKitsCount		= INVALID_HANDLE;
new Handle: AutoHavoc					= INVALID_HANDLE;
new Handle: AutoHavocCount			= INVALID_HANDLE;

// Admin Menu Handles
new Handle: AdminMenu 				= INVALID_HANDLE;
new TopMenuObject: ChangeMap 			= INVALID_TOPMENUOBJECT;
new TopMenuObject: SetAutoHavoc 		= INVALID_TOPMENUOBJECT;

// Variables to keep track of the survivors status
new bool: ClientUnableToEscape[MAXPLAYERS + 1];

// Variable to check if the convar is changing, to prevent change loops.
new bool: ConvarChanging = false;

// Variables to keep track of amount of wins and losses
new SurvivorWins 	= 0;
new SurvivorLosses	= 0;

/**
 * Plugin Information
 *
 */
public Plugin: myinfo =
{
	name			= "L4D Zombie Havoc",
	author	  		= "Bigbuck",
	description	= "Allows up to an 8 player Coop campaign.",
	version	 	= PLUGIN_VERSION,
	url		 	= "http://bigbuck.team-havoc.com/index.php?page=projects&project=zombie_havoc"
};

/**
 * Called when the plugin has been loaded
 *
 */
public OnPluginStart()
{
	// Require Left 4 Dead
	decl String: GameName[50];
	GetGameFolderName(GameName, sizeof(GameName));
	if (!StrEqual(GameName, "left4dead", false))
	{
		SetFailState("Use this in Left 4 Dead only.");
	}

	// Create convars
	CreateConVar("sm_zombie_havoc_version", PLUGIN_VERSION, "L4D Zombie Havoc version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	L4D_SurvivorLimit  		= FindConVar("survivor_limit");
	SurvivorMaxLimit	   	= CreateConVar("sm_l4d_zh_survivor_max_limit", "8", "Maximum amount of survivors allowed (Includes bots)", CVAR_FLAGS, true, 4.0, true, 18.0);
	SurvivorMinLimit		= CreateConVar("sm_l4d_zh_survivor_min_limit", "4", "Starting amount of survivors (Includes bots)", CVAR_FLAGS, true, 4.0, true, 18.0);
	AutomaticSpawning		= CreateConVar("sm_l4d_zh_automatic_spawning", "1", "Enable or disable automatic spawning of bots for human take over", CVAR_FLAGS, true, 0.0, true, 1.0);
	SuperTank		  			= CreateConVar("sm_l4d_zh_supertank", "0", "Set tanks HP based on number of survivors", CVAR_FLAGS, true, 0.0, true, 1.0);
	SuperTankMultiplier	= CreateConVar("sm_l4d_zh_tank_hpmulti", "0.25", "Tanks HP multiplier ((1 + multiplier) * (# of survivors - 4))", CVAR_FLAGS, true, 0.01, true, 1.00);
	ExtraAidKits				= CreateConVar("sm_l4d_zh_extra_aidkits", "1", "Give survivors extra HP packs at each ammo pile outside of the safehouse?", CVAR_FLAGS, true, 0.0, true, 1.0);
	ExtraAidKitsCount		= CreateConVar("sm_l4d_zh_extra_aidkits_count", "4", "If XtraHP is turned on, how many HP packs to give at each ammo pile outside of the safehouse?", CVAR_FLAGS, true, 4.0);
	Unreserve		   			= CreateConVar("sm_l4d_zh_kill_reservation", "0", "Should we clear lobby reservaton? (For use with the Left 4 Downtown extension only)", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoHavoc	  				= CreateConVar("sm_l4d_zh_auto_havoc", "1", "Automatically adjust difficulty based on survivor performance?", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoHavocCount  			= CreateConVar("sm_l4d_zh_auto_havoc_count", "2", "If Auto Havoc is turned on, how many losses until difficulty is reset?", CVAR_FLAGS, true, 1.0);

	// Hook convars
	SetConVarBounds(L4D_SurvivorLimit,  ConVarBound_Upper, true, 18.0);
	HookConVarChange(L4D_SurvivorLimit,	ConVar_Manage);
	HookConVarChange(SurvivorMaxLimit,	ConVar_Manage);

	// Register Commands
	RegAdminCmd("sm_hardzombies",	HardZombies, ADMFLAG_KICK, "How many zombies you want to add. (In multiples of 30. Recommended: 3 Max: 6)");
	RegAdminCmd("sm_addbot",		AddBot, ADMFLAG_KICK, "Add a Survivor bot");
	RegConsoleCmd("sm_jointeam", 	JoinSurvivors, "Join the survivor team");

	// Hook Events
	HookEvent("tank_spawn",		   		Event_TankSpawn);
	HookEvent("finale_vehicle_leaving",	Event_FinaleVehicleLeaving, EventHookMode_PostNoCopy);
	HookEvent("finale_win", 			Event_FinaleWin, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", 			Event_MissionLost, EventHookMode_PostNoCopy);
	HookEvent("map_transition", 		Event_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("round_freeze_end", 		Event_RoundFreezeEnd, EventHookMode_PostNoCopy);
	HookEvent("revive_success",		 	Event_ReviveSuccess);
	HookEvent("survivor_rescued",	   	Event_SurvivorRescued);
	HookEvent("player_incapacitated",   Event_PlayerIncapacitated);
	HookEvent("player_death",		   	Event_PlayerDeath);
	HookEvent("player_first_spawn",	 	Event_PlayerFirstSpawn);

	// If the Admin menu has been loaded start adding stuff to it
	new Handle: topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	// Exec Zombie Havoc config
	AutoExecConfig(true, "l4d_zombie_havoc");
	// Load translations file
	LoadTranslations("plugin.l4d_zombie_havoc");
}

/**
 * Uses L4Downtown if applicable
 *
 */
public bool: AskPluginLoad()
{
	MarkNativeAsOptional("L4D_LobbyUnreserve");
	MarkNativeAsOptional("L4D_LobbyIsReserved");

	return true;
}

/**
 * Called before any optionals are removed
 *
 */
public OnLibraryRemoved(const String: name[])
{
	// Unreserve lobby if L4Downtown is removed
	if (StrEqual(name, "Left 4 Downtown Extension"))
	{
		SetConVarInt(Unreserve, 0);
	}

	// If the admin menu is unloaded, stop trying to use it
	if (StrEqual(name, "adminmenu")) {
		AdminMenu = INVALID_HANDLE;
	}
}

/**
 * Handles the L4Downtown extension
 *
 */
bool: L4DDownTown()
{
	if (GetConVarFloat(FindConVar("left4downtown_version")) > 0.00)
	{
		return true;
	}
	else
	{
		return false;
	}
}

/**
 * Handles ConVar value changing
 *
 */
public ConVar_Manage(Handle: ConVar, const String: Value[], const String: NewValue[])
{
	if (ConvarChanging)
	{
		return;
	}

	ConvarChanging = true;
	SetConVarInt(L4D_SurvivorLimit, GetConVarInt(SurvivorMaxLimit));
	ConvarChanging = false;
}

/**
 * Called when a client tries to connect.
 *
 */
public bool: OnClientConnect(Client, String: rejectmsg[], maxlen)
{
	new String: name[100];
	GetClientName(Client, name, 100);

	// Fix for tank not spawning during finale
	if (IsFakeClient(Client) && (StrContains(name, "tank", false) != -1))
	{
		TankHasJoined();
	}

	// Has to return true for Client to connect
	return true;
}

/**
 * We have to use this because AIDirector Puts bots in, but doesn't connect them
 *
 */
public OnClientPutInServer(Client)
{
	if (!GetConVarInt(Unreserve))
	{
		return;
	}

	if (L4DDownTown() || L4D_LobbyIsReserved())
	{
		L4D_LobbyUnreserve();
	}

	// Automatic spawning if turned on
	if (GetConVarInt(AutomaticSpawning))
	{
		if (!IsFakeClient(Client) && IsClientConnected(Client))
		{
			AutomaticBotSpawning(Client);
		}
	}
}

/**
 * Called when a client disconnects
 *
 */
public OnClientDisconnect(Client)
{
	if (IsFakeClient(Client))
	{
		return;
	}

	// Server goes into hibernation with no real players in game
	if (!RealPlayersInGame())
	{
		new i;
		for (i = 1; i <= GetMaxClients(); i++)
		{
			if (!IsClientConnected(i))
			{
				continue;
			}

			KickFakeClient(INVALID_HANDLE, i);
		}
	}

	// Automatic spawning if turned on
	if (GetConVarInt(AutomaticSpawning))
	{
		new SurvivorsNew = TeamPlayers(2);
		new HumanSurvivorsNew = HumanTeamPlayers(2);

		if (HumanSurvivorsNew < SurvivorsNew)
		{
			if (GetConVarInt(SurvivorMinLimit) > 4)
			{
				new SurvivorsIntNew = GetConVarInt(SurvivorMinLimit) - 1;
				SetConVarInt(SurvivorMinLimit, SurvivorsIntNew);

				// Get a random bot and kick him
				new FakeBot = GetRandomInt(1, GetClientCount());
				while(IsFakeClient(FakeBot))
				{
					// Choose dead bots first
					if (!IsPlayerAlive(FakeBot))
					{
						FakeBot = GetRandomInt(1, GetClientCount());
					}
					else
					{
						FakeBot = GetRandomInt(1, GetClientCount());
					}
				}
				KickFakeClient(INVALID_HANDLE, FakeBot);
			}
		}
	}
}

/**
 * Called when a map starts
 *
 */
public OnMapStart()
{
	// Give extra medkits if turned on
	if (GetConVarInt(ExtraAidKits))
	{
		ExtraMedkits();
	}

	// Control the difficulty if Auto Havoc is on
	if (GetConVarInt(AutoHavoc))
	{
		AutoHavocControl();
	}
}

/**
 * Called when the map is changed
 *
 */
public Event_MapTransition(Handle: hEvent, const String: strName[], bool: bDontBroadcast)
{
	// Add one to SurvivorWins total
	SurvivorWins++;
}

/**
 * Called when a map ends
 *
 */
public OnMapEnd()
{
	// Stop current spawn timer so a new one is created
	if (SpawnTimer != INVALID_HANDLE)
	{
		KillTimer(SpawnTimer);
		SpawnTimer = INVALID_HANDLE;
	}
}

/**
 * Called at the beginning of a new round
 *
 */
public Event_RoundFreezeEnd(Handle: hEvent, const String: strName[], bool: bDontBroadcast)
{
	// Make sure Auto Havoc gets updated
	if (GetConVarInt(AutoHavoc))
	{
		AutoHavocControl();
	}
}

/**
 * Get amount of players on a team, includes bots
 *
 */
TeamPlayers(any: team)
{
	new int = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		// Connection check
		if (!IsClientInGame(i))
		{
			continue;
		}
		if (GetClientTeam(i) != team)
		{
			continue;
		}

		int++;
	}

	return int;
}

/**
 * Get amount of human players on a team
 *
 */
HumanTeamPlayers(any: team)
{
	new int = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		// Connection check
		if (!IsClientConnected(i))
		{
			continue;
		}
		if (!IsFakeClient(i))
		{
			continue;
		}
		if (!IsClientInGame(i))
		{
			continue;
		}
		if (GetClientTeam(i) != team)
		{
			continue;
		}

		int++;
	}

	return int;
}

/**
 * Determine if there are real players in game
 *
 */
bool: RealPlayersInGame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			return true;
		}
	}

	return false;
}

/**
 * Called when a player first spawns
 *
 */
public Event_PlayerFirstSpawn(Handle: hEvent, const String: strName[], bool: bDontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (Client)
	{
		if (GetClientTeam(Client) == 2)
		{
			// Give extra aid kits if turned on
			if (GetConVarInt(ExtraAidKits))
			{
				BypassAndExecuteCommand(Client, "give", "first_aid_kit");
			}

			// Give every survivor a shotgun to prevent lost weapons
			BypassAndExecuteCommand(Client, "give", "pumpshotgun");
		}
	}

	// Startup bot spawn timer
	if (SpawnTimer != INVALID_HANDLE)
	{
		return;
	}

	SpawnTimer = CreateTimer(1.5, SpawnTick, _, TIMER_REPEAT);
}

/**
 * Controls automatic spawning of Survivor Bots for human takeover
 *
 */
AutomaticBotSpawning(Client)
{
	// Make sure this is turned on first
	if (!GetConVarInt(AutomaticSpawning))
	{
		return;
	}

	// Setup buffer string for translations
	decl String: buffer[128];

	new Survivors = TeamPlayers(2);
	new HumanSurvivors = HumanTeamPlayers(2);

	// If team is full of humans tell client so
	if (HumanSurvivors == GetConVarInt(SurvivorMaxLimit))
	{
		Format(buffer, sizeof(buffer), "%T", "L_SURVIVOR_TEAM_FULL", LANG_SERVER);
		PrintToChat(Client, buffer);

		return;
	}

	// If min survivor limit is all humans and max survivor limit hasn't been reached yet
	if (HumanSurvivors == GetConVarInt(SurvivorMinLimit) && Survivors != GetConVarInt(SurvivorMaxLimit))
	{
		// Add one to survivor limit and spawn bot
		new SurvivorInt = GetConVarInt(SurvivorMinLimit) + 1;
		SetConVarInt(SurvivorMinLimit, SurvivorInt);
		SpawnFakeClient();

		// Let the new client know a bot is spawning for him and what to do
		Format(buffer, sizeof(buffer), "%T", "L_BOT_SPAWNED", LANG_SERVER);
		PrintToChat(Client, buffer);
	}
	// If survivor team is full but contains bots, change the human players team and let him know
	else if (Survivors == GetConVarInt(SurvivorMaxLimit))
	{
		ChangeClientTeam(Client, 2);
		Format(buffer, sizeof(buffer), "%T", "L_AUTO_CONNECT", LANG_SERVER);
		PrintToChat(Client, buffer);
	}
}

/**
 * Spawn correct number of starting bots
 *
 */
public Action: SpawnTick(Handle: hTimer, any: Junk)
{
	// Determine the number of survivors and fill the empty slots
	new NumSurvivors = TeamPlayers(2);

	// It's impossible to have less than 4 survivors. Set the lower
	// limit to 4 in order to prevent errors with the respawns
	if (NumSurvivors < 4)
	{
		return Plugin_Continue;
	}

	// Spawn the starting # of bots
	new StartingSurvivors = GetConVarInt(SurvivorMinLimit);
	for (;NumSurvivors < StartingSurvivors; NumSurvivors++)
	{
		SpawnFakeClient();
	}

	// Once the missing bots are made, dispose of the timer
	SpawnTimer = INVALID_HANDLE;

	return Plugin_Stop;
}

/**
 * Spawns a Survivor Bot
 *
 */
SpawnFakeClient()
{
	// Spawn a bot
	new Bot = CreateFakeClient("SurvivorBot");
	if (!Bot)
	{
		return;
	}

	// Change the bots team to the survivors
	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	CreateTimer(0.5, KickFakeClient, Bot);
}

/**
 * Kicks a Survivor Bot
 *
 */
public Action: KickFakeClient(Handle: hTimer, any: Client)
{
	// Connection check
	if (!IsClientInGame(Client) || !IsFakeClient(Client))
	{
		return Plugin_Stop;
	}

	if (GetClientTeam(Client) == 2)
	{
		KickClient(Client, "Killing bot - Freeing slot.");
	}

	return Plugin_Stop;
}

/**
 * Fixes tank not spawning in finale
 * Thanks to AtomicStryker
 *
 */
public Action: TankHasJoined()
{
	// Iterate all Clients
	for (new target = 1; target <= GetMaxClients(); target++)
	{
		if (IsClientInGame(target))
		{
			// Get the target Client model
			new String: class[100];
			GetClientModel(target, class, sizeof(class));

			// Kick all special infected that are not tanks
			if (GetClientTeam(target) == 3 && IsFakeClient(target) && (StrContains(class, "hulk", false) == -1))
			{
				KickClient(target);
			}
		}
	}

	return Plugin_Continue;
}

/**
 * Determines if a tank should be a Super Tank
 *
 */
public Event_TankSpawn(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	if (!GetConVarInt(SuperTank))
	{
		return;
	}

	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	CreateTimer(1.0, SetTankHP, Client);
}

/**
 * Controls the Super Tank
 *
 */
public Action: SetTankHP(Handle: Timer, any: Client)
{
	if (!GetConVarInt(SuperTank))
	{
		return Plugin_Stop;
	}

	new Float: ExtraSurvivors = (float(TeamPlayers(2)) - 4.0);
	if (RoundFloat(ExtraSurvivors) < 0)
	{
		return Plugin_Stop;
	}

	new TankHP = RoundFloat((GetEntProp(Client, Prop_Send, "m_iHealth") * (1.0 + (GetConVarFloat(SuperTankMultiplier) * ExtraSurvivors))));
	if (TankHP > 65535)
	{
		TankHP = 65535;
	}

	SetEntProp(Client, Prop_Send, "m_iHealth", TankHP);
	SetEntProp(Client, Prop_Send, "m_iMaxHealth", TankHP);

	return Plugin_Stop;
}

/**
 * Controls sm_hardzombies admin command
 *
 */
public Action: HardZombies(Client, args)
{
	new String: arg[8];
	GetCmdArg(1, arg, 8);
	new Input = StringToInt(arg[0]);

	if (Input == 1)
	{
		// Default Values
		SetConVarInt(FindConVar("z_common_limit"),		  	30);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"),	10);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"),	30);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"),	20);
		SetConVarInt(FindConVar("z_mega_mob_size"),		 	45);
	}
	else if (Input > 1 && Input < 7)
	{
		SetConVarInt(FindConVar("z_common_limit"),		  	30 * Input);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"),	30 * Input);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"),	30 * Input);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"),	30 * Input);
		SetConVarInt(FindConVar("z_mega_mob_size"),		 	30 * Input);
	}
	else
	{
		ReplyToCommand(Client, "\x01[SM] Usage: How many zombies you want to add. (In multiples of 30. Recommended: 3 Max: 6)");
		ReplyToCommand(Client, "\x01		  : Anything above 3 may cause moments of lag, 1 resets the defaults");
	}

	return Plugin_Handled;
}

/**
 * Manually spawns a Survivor Bot
 *
 */
public Action: AddBot(Client, args)
{
	new SurvivorLimit = GetConVarInt(SurvivorMinLimit) + 1;
	SetConVarInt(SurvivorMinLimit, SurvivorLimit);
	ServerCommand("sb_add");

	return Plugin_Handled;
}

/**
 * Controls Finale vehicle
 * Thanks to Mad_Dugan
 *
 */
public Event_FinaleVehicleLeaving(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new eSurvivor = FindEntityByClassname(-1, "info_survivor_position");
	if (eSurvivor == -1)
	{
		return;
	}

	new Float: Pos[3];
	GetEntPropVector(eSurvivor, Prop_Send, "m_vecOrigin", Pos);
	for (new i = 1; i <= MaxClients; i++)
	{
		// Connection + escape check
		if (!IsClientInGame(i))
		{
			continue;
		}
		if (GetClientTeam(i) != 2)
		{
			continue;
		}
		if (ClientUnableToEscape[i] != false)
		{
			continue;
		}

		TeleportEntity(i, Pos, NULL_VECTOR, NULL_VECTOR);
	}
}

/**
 * Controls mission lost
 *
 */
public Event_MissionLost(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	// Add one to SurvivorLosses total
	SurvivorLosses++;
}

/**
 * Controls finale win
 *
 */
public Event_FinaleWin(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	// Setup timer for campaign change
	CreateTimer(60.0, FinaleCampaignChange);
}

/**
 * Controls automatic campaign change
 *
 */
public Action: FinaleCampaignChange(Handle: Timer)
{
	decl String: CurrentMap[128];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));

	if ((StrContains(CurrentMap, "hospital05_rooftop", false)) >= 0)
	{
		ServerCommand("changelevel l4d_deathaboard01_prison");
	}
	else if ((StrContains(CurrentMap, "deathaboard05_light", false)) >= 0)
	{
		ServerCommand("changelevel l4d_smalltown01_caves");
	}
	else if ((StrContains(CurrentMap, "smalltown05_houseboat", false)) >= 0)
	{
		ServerCommand("changelevel l4d_nt01_mansion_b1");
	}
	else if ((StrContains(CurrentMap, "nt05_wake_b1", false)) >= 0)
	{
		ServerCommand("changelevel l4d_airport01_greenhouse");
	}
	else if ((StrContains(CurrentMap, "airport05_runway", false)) >= 0)
	{
		ServerCommand("changelevel l4d_farm01_hilltop");
	}
	else if ((StrContains(CurrentMap, "farm05_cornfield", false)) >= 0)
	{
		ServerCommand("changelevel l4d_garage01_alleys");
	}
	else if ((StrContains(CurrentMap, "garage02_lots", false)) >= 0)
	{
		ServerCommand("changelevel l4d_hospital01_apartment");
	}
}

/**
 * Controls Survivor revice success
 * Thanks to Mad_Dugan
 *
 */
public Event_ReviveSuccess(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "subject"));
	ClientUnableToEscape[Client] = false;
}

/**
 * Controls Survivor rescued
 * Thanks to Mad_Dugan
 *
 */
public Event_SurvivorRescued(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	ClientUnableToEscape[Client] = false;
}

/**
 * Controls player incapacitated
 * Thanks to Mad_Dugan
 *
 */
public Event_PlayerIncapacitated(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	ClientUnableToEscape[Client] = true;
}

/**
 * Controls player death
 * Thanks to Mad_Dugan
 *
 */
public Event_PlayerDeath(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	ClientUnableToEscape[Client] = true;
}

/**
 * Bypasses the sv_cheats to use command
 * Thanks to Damizean
 *
 */
BypassAndExecuteCommand(Client, String: strCommand[], String: strParam1[])
{
	new Flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, Flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, Flags);
}

/**
 * Automatically controls zombie difficulty
 *
 */
AutoHavocControl()
{
	// Setup buffer string for translations
	decl String: buffer[128];

	// Make sure Auto Havoc is on
	if (GetConVarInt(AutoHavoc))
	{
		if (SurvivorWins >= 4 && SurvivorWins < 7)
		{
			ServerCommand("sm_hardzombies 1");
			Format(buffer, sizeof(buffer), "%T", "L_AUTO_HAVOC_1", LANG_SERVER);
			PrintHintTextToAll(buffer);
		}
		else if (SurvivorWins >= 7 && SurvivorWins <= 9)
		{
			ServerCommand("sm_hardzombies 2");
			Format(buffer, sizeof(buffer), "%T", "L_AUTO_HAVOC_2", LANG_SERVER);
			PrintHintTextToAll(buffer);
		}
		else if (SurvivorWins >= 10)
		{
			ServerCommand("sm_hardzombies 3");
			Format(buffer, sizeof(buffer), "%T", "L_AUTO_HAVOC_3", LANG_SERVER);
			PrintHintTextToAll(buffer);
		}

		// Reset difficulty if things get too hot
		if (SurvivorLosses >= GetConVarInt(AutoHavocCount))
		{
			AutoHavocReset();
		}
	}
}

/**
 * Resets survivor performance count
 *
 */
AutoHavocReset()
{
	SurvivorWins = 0;
	SurvivorLosses = 0;
}

/**
 * Controls spawning of extra medkits
 *
 */
ExtraMedkits()
{
	if (!IsModelPrecached(MEDKIT))
	{
		PrecacheModel(MEDKIT);
	}

	new eAmmoPile = -1;
	while ((eAmmoPile = FindEntityByClassname(eAmmoPile, "weapon_ammo_spawn")) != -1)
	{
		new Float: vAmmoPos[3];
		GetEntPropVector(eAmmoPile, Prop_Send, "m_vecOrigin", vAmmoPos);

		// Cycle through all medkits
		new eMedkit = -1;
		while ((eMedkit = FindEntityByClassname(eMedkit, "weapon_first_aid_kit_spawn")) != -1)
		{
			decl Float: vMedkitPos[3];
			GetEntPropVector(eMedkit, Prop_Send, "m_vecOrigin", vMedkitPos);

			// Found a medkit within range, we're done here
			if (GetVectorDistance(vMedkitPos, vAmmoPos) <= 500)
			{
				return;
			}
		}

		// If no medkits in range
		for (new HP = 0; HP < GetConVarInt(ExtraAidKitsCount); HP++)
		{
			new index = CreateEntityByName("weapon_first_aid_kit");
			if (index)
			{
				SetEntityModel(index, MEDKIT);
				DispatchSpawn(index);

				TeleportEntity(index, vAmmoPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}

	return;
}

/**
 * Switchs a client to the Survivor team
 *
 */
public Action: JoinSurvivors(Client, args)
{
	FakeClientCommand(Client, "jointeam 2");

	return Plugin_Handled;
}

/**
 * Loads Zombie Havoc adminmenu into SM admin menu
 *
 */
public OnAdminMenuReady(Handle: TopMenu) {
	// Block us from being called twice
	if (TopMenu == AdminMenu)
	{
		return;
	}

	AdminMenu = TopMenu;

	// Add a category to the SourceMod menu
	AddToTopMenu(AdminMenu, "Zombie Havoc", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT);
	// Get a handle for the catagory we just added so we can add items to it
	new TopMenuObject: ZombieHavoc = FindTopMenuCategory(AdminMenu, "Zombie Havoc");

	// Don't attempt to add items to the catagory if for some reason the catagory doesn't exist
	if (ZombieHavoc == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	// The order that items are added to menus has no relation to the order that they appear. Items are sorted alphabetically automatically
	// Assign the menus to global values so we can easily check what a menu is when it is chosen
	ChangeMap = AddToTopMenu(AdminMenu, "zh_changemap", TopMenuObject_Item, Menu_TopItemHandler, ZombieHavoc, "zh_changemap", ADMFLAG_CHEATS);
	SetAutoHavoc = AddToTopMenu(AdminMenu, "zh_auto_havoc", TopMenuObject_Item, Menu_TopItemHandler, ZombieHavoc, "zh_auto_havoc", ADMFLAG_CHEATS);
}

/**
 * Creates first category of Zombie Havoc admin menu
 *
 */
public CategoryHandler(Handle: topmenu, TopMenuAction: action, TopMenuObject: object_id, Client, String: buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "%T:", "L_ZOMBIE_HAVOC_COL", Client);
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "L_ZOMBIE_HAVOC", Client);
	}
}

/**
 * Controls first category of Zombie Havoc admin menu
 *
 */
public Menu_TopItemHandler(Handle: topmenu, TopMenuAction: action, TopMenuObject: object_id, Client, String: buffer[], maxlength)
{
	// When an item is displayed to a player tell the menu to format the item
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == ChangeMap)
		{
			Format(buffer, maxlength, "%T", "L_CHANGE_MAP", Client);
		}
		if (object_id == SetAutoHavoc)
		{
			Format(buffer, maxlength, "%T", "L_AUTO_HAVOC", Client);
		}
	}
	// When an item is selected do the following
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == ChangeMap)
		{
			Menu_ChangeMap(Client, false);
		}
		if (object_id == SetAutoHavoc)
		{
			Menu_SetAutoHavoc(Client, false);
		}
	}
}

/**
 * Creates Zombie Havoc change map menu
 *
 */
public Action: Menu_ChangeMap(Client, args)
{
	// Setup buffer string for translations
	decl String: buffer[128];

	new Handle: ChangeMapMenu = CreateMenu(MenuHandler_ChangeMap);
	Format(buffer, sizeof(buffer), "%T", "L_CHOOSE_CAMPAIGN", Client);
	SetMenuTitle(ChangeMapMenu, buffer);

	Format(buffer, sizeof(buffer), "%T", "L_NO_MERCY", Client);
	AddMenuItem(ChangeMapMenu, "NoMercy", buffer);

	Format(buffer, sizeof(buffer), "%T", "L_DEATH_TOLL", Client);
	AddMenuItem(ChangeMapMenu, "DeathToll", buffer);

	Format(buffer, sizeof(buffer), "%T", "L_DEAD_AIR", Client);
	AddMenuItem(ChangeMapMenu, "DeadAir", buffer);

	Format(buffer, sizeof(buffer), "%T", "L_BLOOD_HARVEST", Client);
	AddMenuItem(ChangeMapMenu, "BloodHarvest", buffer);

	Format(buffer, sizeof(buffer), "%T", "L_CRASH_COURSE", Client);
	AddMenuItem(ChangeMapMenu, "CrashCourse", buffer);

	DisplayMenu(ChangeMapMenu, Client, 20);

	return Plugin_Handled;
}

/**
 * Controls Zombie Havoc change map menu
 *
 */
public MenuHandler_ChangeMap(Handle: ChangeMapMenu, MenuAction: action, Client, CampaignName)
{
	// Setup buffer string for translations
	decl String: buffer[128];

	if (action == MenuAction_Select)
	{
		switch (CampaignName)
		{
			case 0:
			{
				new Handle: NoMercyMenu = CreateMenu(NoMercyMenuHandler);
				Format(buffer, sizeof(buffer), "%T", "L_NO_MERCY_MAPS", Client);
				SetMenuTitle(NoMercyMenu, buffer);

				Format(buffer, sizeof(buffer), "%T", "L_NO_MERCY_APARTMENTS", Client);
				AddMenuItem(NoMercyMenu, "NM_Apartment", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_NO_MERCY_SUBWAY", Client);
				AddMenuItem(NoMercyMenu, "NM_Subway", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_NO_MERCY_SEWERS", Client);
				AddMenuItem(NoMercyMenu, "NM_Sewers", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_NO_MERCY_HOSPITAL", Client);
				AddMenuItem(NoMercyMenu, "NM_Hospital", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_NO_MERCY_ROOFTOP_FINALE", Client);
				AddMenuItem(NoMercyMenu, "NM_RooftopFinale", buffer);

				DisplayMenu(NoMercyMenu, Client, 20);
			}
			case 1:
			{
				new Handle: DeathTollMenu = CreateMenu(DeathTollMenuHandler);
				Format(buffer, sizeof(buffer), "%T", "L_DEATH_TOLL_MAPS", Client);
				SetMenuTitle(DeathTollMenu, buffer);

				Format(buffer, sizeof(buffer), "%T", "L_DEATH_TOLL_TURNPIKE", Client);
				AddMenuItem(DeathTollMenu, "DT_Turnpike", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_DEATH_TOLL_DRAINS", Client);
				AddMenuItem(DeathTollMenu, "DT_Drains", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_DEATH_TOLL_CHURCH", Client);
				AddMenuItem(DeathTollMenu, "DT_Church", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_DEATH_TOLL_TOWN", Client);
				AddMenuItem(DeathTollMenu, "DT_Town", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_DEATH_TOLL_BOATHOUSE_FINALE", Client);
				AddMenuItem(DeathTollMenu, "DT_BoathouseFinale", buffer);

				DisplayMenu(DeathTollMenu, Client, 20);
			}
			case 2:
			{
				new Handle: DeadAirMenu = CreateMenu(DeadAirMenuHandler);
				Format(buffer, sizeof(buffer), "%T", "L_DEAD_AIR_MAPS", Client);
				SetMenuTitle(DeadAirMenu, buffer);

				Format(buffer, sizeof(buffer), "%T", "L_DEAD_AIR_GREENHOUSE", Client);
				AddMenuItem(DeadAirMenu, "DA_Greenhouse", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_DEAD_AIR_CRANE", Client);
				AddMenuItem(DeadAirMenu, "DA_CRANE", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_DEAD_AIR_CONSTRUCTION_SITE", Client);
				AddMenuItem(DeadAirMenu, "DA_ContructionSite", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_DEAD_AIR_TERMINAL", Client);
				AddMenuItem(DeadAirMenu, "DA_Terminal", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_DEAD_AIR_RUNWAY_FINALE", Client);
				AddMenuItem(DeadAirMenu, "DA_RunwayFinale", buffer);

				DisplayMenu(DeadAirMenu, Client, 20);
			}
			case 3:
			{
				new Handle: BloodHarvestMenu = CreateMenu(BloodHarvestMenuHandler);
				Format(buffer, sizeof(buffer), "%T", "L_BLOOD_HARVEST_MAPS", Client);
				SetMenuTitle(BloodHarvestMenu, buffer);

				Format(buffer, sizeof(buffer), "%T", "L_BLOOD_HARVEST_WOODS", Client);
				AddMenuItem(BloodHarvestMenu, "BH_Woods", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_BLOOD_HARVEST_TUNNEL", Client);
				AddMenuItem(BloodHarvestMenu, "BH_Tunnel", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_BLOOD_HARVEST_BRIDGE", Client);
				AddMenuItem(BloodHarvestMenu, "BH_Bridge", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_BLOOD_HARVEST_TRAIN_STATION", Client);
				AddMenuItem(BloodHarvestMenu, "BH_TraiNStation", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_BLOOD_HARVEST_FARMHOUSE_FINALE", Client);
				AddMenuItem(BloodHarvestMenu, "BH_FarmhouseFinale", buffer);

				DisplayMenu(BloodHarvestMenu, Client, 20);
			}
			case 4:
			{
				new Handle: CrashCourseMenu = CreateMenu(CrashCourseMenuHandler);
				Format(buffer, sizeof(buffer), "%T", "L_CRASH_COURSE_MAPS", Client);
				SetMenuTitle(CrashCourseMenu, buffer);

				Format(buffer, sizeof(buffer), "%T", "L_CRASH_COURSE_ALLEYS", Client);
				AddMenuItem(CrashCourseMenu, "CC_Alleys", buffer);

				Format(buffer, sizeof(buffer), "%T", "L_CRASH_COURSE_TRUCK_DEPOT", Client);
				AddMenuItem(CrashCourseMenu, "CC_TruckDepot", buffer);

				DisplayMenu(CrashCourseMenu, Client, 20);
			}
		}
	}
}

/**
 * Controls No Mercy map menu
 *
 */
public NoMercyMenuHandler(Handle: NoMercyMenu, MenuAction: action, Client, MapName)
{
	if (action == MenuAction_Select)
	{
		switch (MapName)
		{
			case 0:
			{
				ServerCommand("changelevel l4d_hospital01_apartment");
			}
			case 1:
			{
				ServerCommand("changelevel l4d_hospital02_subway");
			}
			case 2:
			{
				ServerCommand("changelevel l4d_hospital03_sewers");
			}
			case 3:
			{
				ServerCommand("changelevel l4d_hospital04_interior");
			}
			case 4:
			{
				ServerCommand("changelevel l4d_hospital05_rooftop");
			}
		}
	}
}

/**
 * Controls Death Toll map menu
 *
 */
public DeathTollMenuHandler(Handle: DeathTollMenu, MenuAction: action, Client, MapName)
{
	if (action == MenuAction_Select)
	{
		switch (MapName)
		{
			case 0:
			{
				ServerCommand("changelevel l4d_smalltown01_caves");
			}
			case 1:
			{
				ServerCommand("changelevel l4d_smalltown02_drainage");
			}
			case 2:
			{
				ServerCommand("changelevel l4d_smalltown03_ranchhouse");
			}
			case 3:
			{
				ServerCommand("changelevel l4d_smalltown04_mainstreet");
			}
			case 4:
			{
				ServerCommand("changelevel l4d_smalltown05_houseboat");
			}
		}
	}
}

/**
 * Controls Dead Air map menu
 *
 */
public DeadAirMenuHandler(Handle: DeadAirMenu, MenuAction: action, Client, MapName)
{
	if (action == MenuAction_Select)
	{
		switch (MapName)
		{
			case 0:
			{
				ServerCommand("changelevel l4d_airport01_greenhouse");
			}
			case 1:
			{
				ServerCommand("changelevel l4d_airport02_offices");
			}
			case 2:
			{
				ServerCommand("changelevel l4d_airport03_garage");
			}
			case 3:
			{
				ServerCommand("changelevel l4d_airport04_terminal");
			}
			case 4:
			{
				ServerCommand("changelevel l4d_airport05_runway");
			}
		}
	}
}

/**
 * Controls Blood Harvest map menu
 *
 */
public BloodHarvestMenuHandler(Handle: BloodHarvestMenu, MenuAction: action, Client, MapName)
{
	if (action == MenuAction_Select)
	{
		switch (MapName)
		{
			case 0:
			{
				ServerCommand("changelevel l4d_farm01_hilltop");
			}
			case 1:
			{
				ServerCommand("changelevel l4d_farm02_traintunnel");
			}
			case 2:
			{
				ServerCommand("changelevel l4d_farm03_bridge");
			}
			case 3:
			{
				ServerCommand("changelevel l4d_farm04_barn");
			}
			case 4:
			{
				ServerCommand("changelevel l4d_farm05_cornfield");
			}
		}
	}
}

/**
 * Controls Crash Course map menu
 *
 */
public CrashCourseMenuHandler(Handle: CrashCourseMenu, MenuAction: action, Client, MapName)
{
	if (action == MenuAction_Select)
	{
		switch (MapName)
		{
			case 0:
			{
				ServerCommand("changelevel l4d_garage01_alleys");
			}
			case 1:
			{
				ServerCommand("changelevel l4d_garage02_lots");
			}
		}
	}
}

/**
 * Creates Auto Havoc menu
 *
 */
public Action: Menu_SetAutoHavoc(Client, args)
{
	// Setup buffer string for translations
	decl String: buffer[128];

	new Handle: SetAutoHavocMenu = CreateMenu(MenuHandler_SetAutoHavocMenu);
	Format(buffer, sizeof(buffer), "%T", "L_AUTO_HAVOC_TOGGLE", Client);
	SetMenuTitle(SetAutoHavocMenu, buffer);

	if (GetConVarInt(AutoHavoc))
	{
		Format(buffer, sizeof(buffer), "%T", "L_AUTO_HAVOC_OFF", Client);
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "L_AUTO_HAVOC_ON", Client);
	}
	AddMenuItem(SetAutoHavocMenu, "AutoHavoc", buffer);

	DisplayMenu(SetAutoHavocMenu, Client, 20);

	return Plugin_Handled;
}

/**
 * Controls Auto Havoc menu
 *
 */
public MenuHandler_SetAutoHavocMenu(Handle: SetAutoHavocMenu, MenuAction: action, Client, AutoHavocVar)
{
	if (action == MenuAction_Select)
	{
		switch (AutoHavocVar)
		{
			case 0:
			{
				SetAutoHavocInt(0, 0);
			}
		}
	}
}

/**
 * Controls Auto Havoc menu choice
 *
 */
public Action: SetAutoHavocInt(Client, args)
{
	// Setup buffer string for translations
	decl String: buffer[128];

	if (GetConVarInt(AutoHavoc))
	{
		SetConVarInt(AutoHavoc, 0);
		Format(buffer, sizeof(buffer), "%T", "L_AUTO_HAVOC_DISABLED", Client);
		PrintToChatAll(buffer);
	}
	else
	{
		SetConVarInt(AutoHavoc, 1);
		Format(buffer, sizeof(buffer), "%T", "L_AUTO_HAVOC_ENABLED", Client);
		PrintToChatAll(buffer);
	}
}