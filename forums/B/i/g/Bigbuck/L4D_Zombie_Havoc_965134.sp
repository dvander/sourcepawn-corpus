/* ========================================================
 * L4D Zombie Havoc
 * Based upon L4D SuperVersus by DDR Khat
 * ========================================================
 * Created by Bigbuck
 * Thanks to Mad_Dugan for finale code
 * L4D SuperVersus tweaked and cleaned by Damizean
 * Thanks to AtomicStryker for the tank spawn code
 * Extra medkits code based off of YourEnemyPL's, Damizean's, and Paegus's work
 * Don't spawn bots is based off of Left8Dead
 * ========================================================
*/

/*
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
*/

// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
/* Force strict semicolon mode */
#pragma semicolon 1

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
/* Make the admin menu optional */
#undef REQUIRE_PLUGIN
#include <adminmenu>

// *********************************************************************************
// OPTIONALS - If these exist, we use them. If not, we do nothing.
// *********************************************************************************
native L4D_LobbyUnreserve();
native L4D_LobbyIsReserved();

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define PLUGIN_VERSION	  	"1.2.0"
#define CVAR_FLAGS		  	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define MEDKIT					"models/w_models/weapons/w_eq_Medkit.mdl"

// *********************************************************************************
// VARIABLES
// *********************************************************************************
/* ConVar Handles */
new Handle: SpawnTimer				= INVALID_HANDLE;
new Handle: SurvivorLimit			= INVALID_HANDLE;
new Handle: L4D_SurvivorLimit		= INVALID_HANDLE;
new Handle: SuperTank					= INVALID_HANDLE;
new Handle: SuperTankMultiplier	= INVALID_HANDLE;
new Handle: ExtraAidKits				= INVALID_HANDLE;
new Handle: ExtraAidKitsCount		= INVALID_HANDLE;
new Handle: Unreserve					= INVALID_HANDLE;
new Handle: AutoHavoc					= INVALID_HANDLE;
new Handle: AutoHavocCount			= INVALID_HANDLE;
new Handle: DontSpawnBots			= INVALID_HANDLE;

/* Admin Menu Handles */
new Handle: AdminMenu 				= INVALID_HANDLE;
new TopMenuObject: ChangeMap 			= INVALID_TOPMENUOBJECT;
new TopMenuObject: SetAutoHavoc 		= INVALID_TOPMENUOBJECT;

/* Variables to keep track of the survivors status */
new bool: ClientUnableToEscape[MAXPLAYERS + 1];

/* Variables to keep track of amount of wins and losses */
new SurvivorWins = 0;
new SurvivorLosses = 0;
// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin: myinfo =
{
	name			= "L4D Zombie Havoc",
	author	  		= "Bigbuck",
	description	= "Allows an 8 player Coop campaign.",
	version	 	= PLUGIN_VERSION,
	url		 	= "http://bigbuck.team-havoc.com/pages/zombie_havoc.html"
};

// *********************************************************************************
// METHODS
// *********************************************************************************
// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
public OnPluginStart()
{
	/* Require Left 4 Dead */
	decl String: GameName[50];
	GetGameFolderName(GameName, sizeof(GameName));
	if (!StrEqual(GameName, "left4dead", false))
	{
		SetFailState("Use this in Left 4 Dead only.");
	}

	/* Require Coop gamemode */
	decl String: GameMode[32];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	if (!StrEqual(GameMode, "coop", false))
	{
		SetFailState("Use this in a Coop game only.");
	}

	/* Create convars */
	CreateConVar("sm_zombie_havoc_version", PLUGIN_VERSION, "L4D Zombie Havoc version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	L4D_SurvivorLimit  	 	= FindConVar("survivor_limit");
	SurvivorLimit	   		= CreateConVar("zm_survivor_limit", "8", "Maximum amount of survivors", CVAR_FLAGS, true, 1.00, true, 8.00);
	SuperTank		  			= CreateConVar("zm_supertank", "0", "Set tanks HP based on number of survivors", CVAR_FLAGS, true, 0.0, true, 1.0);
	SuperTankMultiplier	= CreateConVar("zm_tank_hpmulti", "0.25", "Tanks HP multiplier (multiplier * (survivors - 4))", CVAR_FLAGS, true, 0.01, true, 1.00);
	ExtraAidKits				= CreateConVar("zm_XtraHP", "1", "Give survivors extra HP packs at each ammo pile outside of the safehouse?", CVAR_FLAGS, true, 0.0, true, 1.0);
	ExtraAidKitsCount		= CreateConVar("zm_XtraHP_count", "4", "If XtraHP is turned on, how many HP packs to give at each ammo pile outside of the safehouse?", CVAR_FLAGS, true, 4.0);
	Unreserve		   			= CreateConVar("zm_killreservation", "0", "Should we clear lobby reservaton? (For use with the Left 4 Downtown extension only)", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoHavoc	  				= CreateConVar("zm_auto_havoc", "1", "Automatically adjust difficulty based on survivor performance?", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoHavocCount  			= CreateConVar("zm_auto_havoc_count", "2", "If Auto Havoc is turned on, how many losses until difficulty is reset?", CVAR_FLAGS, true, 1.0);
	DontSpawnBots			= CreateConVar("zm_dont_spawn_bots", "0", "Only spawn bots if there are more than four survivors?", CVAR_FLAGS, true, 0.0, true, 1.0);

	/* Hook convars */
	SetConVarBounds(L4D_SurvivorLimit,  ConVarBound_Upper, true, 8.0);
	HookConVarChange(L4D_SurvivorLimit,	FSL);
	HookConVarChange(SurvivorLimit,	 	FSL);

	/* Register Commands */
	RegAdminCmd("sm_hardzombies",	HardZombies, ADMFLAG_KICK, "How many zombies you want to add. (In multiples of 30. Recommended: 3 Max: 6)");
	RegConsoleCmd("sm_jointeam", 	JoinSurvivors, "Join the survivor team");

	/* Hook Events */
	HookEvent("tank_spawn",		   		Event_TankSpawn);
	HookEvent("finale_vehicle_leaving",	Event_FinaleVehicleLeaving, EventHookMode_PostNoCopy);
	HookEvent("finale_win", 				Event_FinaleWin, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", 			Event_MissionLost, EventHookMode_PostNoCopy);
	HookEvent("map_transition", 			Event_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("round_freeze_end", 		Event_RoundFreezeEnd, EventHookMode_PostNoCopy);
	HookEvent("revive_success",		 	Event_ReviveSuccess);
	HookEvent("survivor_rescued",	   		Event_SurvivorRescued);
	HookEvent("player_incapacitated",   	Event_PlayerIncapacitated);
	HookEvent("player_death",		   		Event_PlayerDeath);
	HookEvent("player_first_spawn",	 	Event_PlayerFirstSpawn);

	/* If the Admin menu has been loaded start adding stuff to it */
	new Handle: topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	/* Exec Zombie Havoc config */
	AutoExecConfig(true, "l4d_zombie_havoc");
}

// ------------------------------------------------------------------------
// OnAskPluginLoad()
// ------------------------------------------------------------------------
public bool: AskPluginLoad()
{
	/* Uses L4Downtown lobby reservartion if applicable */
	MarkNativeAsOptional("L4D_LobbyUnreserve");
	MarkNativeAsOptional("L4D_LobbyIsReserved");

	return true;
}

// ------------------------------------------------------------------------
// OnLibraryRemoved()
// ------------------------------------------------------------------------
public OnLibraryRemoved(const String: name[])
{
	/* Unreserve lobby if L4Downtown is removed */
	if (StrEqual(name, "Left 4 Downtown Extension"))
	{
		SetConVarInt(Unreserve, 0);
	}

	/* If the admin menu is unloaded, stop trying to use it */
	if (StrEqual(name, "adminmenu")) {
		AdminMenu = INVALID_HANDLE;
	}
}

// ------------------------------------------------------------------------
// L4DDownTown() - Handles the L4Downtown extension
// ------------------------------------------------------------------------
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

// ------------------------------------------------------------------------
// OnConvarChange()
// ------------------------------------------------------------------------
#define FORCE_INT_CHANGE(%1,%2,%3) public %1 (Handle: c, const String: o[], const String: n[]) { SetConVarInt(%2, %3);}
FORCE_INT_CHANGE(FSL, L4D_SurvivorLimit, GetConVarInt(SurvivorLimit))

// ------------------------------------------------------------------------
// OnClientConnect()
// ------------------------------------------------------------------------
public bool: OnClientConnect(Client, String: rejectmsg[], maxlen)
{
	new String: name[100];
	GetClientName(Client, name, 100);

	/* Fix for tank not spawning during finale */
	if (IsFakeClient(Client) && (StrContains(name, "tank", false) != -1))
	{
		TankHasJoined();
	}

	/* Has to return true for Client to connect */
	return true;
}

// ------------------------------------------------------------------------
// OnClientPutInServer() - We have to use this because AIDirector Puts bots in, but doesn't connect them
// ------------------------------------------------------------------------
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
}

// ------------------------------------------------------------------------
// OnClientDisconnect()
// ------------------------------------------------------------------------
public OnClientDisconnect(Client)
{
	if (IsFakeClient(Client))
	{
		return;
	}

	/* Server goes into hibernation with no real players in game */
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
}

// ------------------------------------------------------------------------
// OnMapStart()
// ------------------------------------------------------------------------
public OnMapStart()
{
	/* Give extra medkits if turned on */
	if (GetConVarInt(ExtraAidKits))
	{
		ExtraMedkits();
	}

	/* Control the difficulty if Auto Havoc is on */
	if (GetConVarInt(AutoHavoc))
	{
		AutoHavocControl();
	}
}

// ------------------------------------------------------------------------
// Event_MapTransition()
// ------------------------------------------------------------------------
public Event_MapTransition(Handle: hEvent, const String: strName[], bool: bDontBroadcast)
{
	/* Add one to total SurvivorWins */
	SurvivorWins++;
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
public OnMapEnd()
{
	/* Stop current spawn timer so a new one is created */
	if (SpawnTimer != INVALID_HANDLE)
	{
		KillTimer(SpawnTimer);
		SpawnTimer = INVALID_HANDLE;
	}
}

// ------------------------------------------------------------------------
// Event_RoundFreezeEnd()
// ------------------------------------------------------------------------
public Event_RoundFreezeEnd(Handle: hEvent, const String: strName[], bool: bDontBroadcast)
{
	/* Make sure Auto Havoc is updated */
	if (GetConVarInt(AutoHavoc))
	{
		AutoHavocControl();
	}
}

// ------------------------------------------------------------------------
// TeamPlayers() - Get amount of players on a team
// ------------------------------------------------------------------------
TeamPlayers(any: team)
{
	new int = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		/* Connection check */
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

// ------------------------------------------------------------------------
// RealPlayersInGame() - Determine if there are real players in game
// ------------------------------------------------------------------------
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

// ------------------------------------------------------------------------
// Event_PlayerFirstSpawn()
// ------------------------------------------------------------------------
public Event_PlayerFirstSpawn(Handle: hEvent, const String: strName[], bool: bDontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (Client)
	{
		if (GetClientTeam(Client) == 2)
		{
			/* Give extra aid kits if turned on */
			if (GetConVarInt(ExtraAidKits))
			{
				BypassAndExecuteCommand(Client, "give", "first_aid_kit");
			}

			/* Give every survivor a shotgun to prevent lost weapons */
			BypassAndExecuteCommand(Client, "give", "pumpshotgun");
		}
	}

	/* Startup bot spawn timer */
	if (SpawnTimer != INVALID_HANDLE)
	{
		return;
	}

	SpawnTimer = CreateTimer(1.5, SpawnTick, _, TIMER_REPEAT);
}

// ------------------------------------------------------------------------
// SpawnTick()
// ------------------------------------------------------------------------
public Action: SpawnTick(Handle: hTimer, any: Junk)
{
	/* Determine the number of survivors and fill the empty slots */
	new NumSurvivors = TeamPlayers(2);

	/* It's impossible to have less than 4 survivors. Set the lower
	limit to 4 in order to prevent errors with the respawns */
	if (NumSurvivors < 4)
	{
		return Plugin_Continue;
	}

	/* Get correct number of bots to spawn */
	new MaxSurvivors = 0;
	if (GetConVarInt(DontSpawnBots))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				MaxSurvivors++;
			}
		}
	}
	else
	{
		MaxSurvivors = GetConVarInt(SurvivorLimit);
	}

	/* Spawn the bots */
	for (;NumSurvivors < MaxSurvivors; NumSurvivors++)
	{
		SpawnFakeClient();
	}

	/* Once the missing bots are made, dispose of the timer */
	SpawnTimer = INVALID_HANDLE;

	return Plugin_Stop;
}

// ------------------------------------------------------------------------
// SpawnFakeClient() - Spawns the bots
// ------------------------------------------------------------------------
SpawnFakeClient()
{
	/* Spawn a bot */
	new Bot = CreateFakeClient("SurvivorBot");
	if (Bot == 0)
	{
		return;
	}

	/* Change the bot team to the survivors */
	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	CreateTimer(0.5, KickFakeClient, Bot);
}

// ------------------------------------------------------------------------
// KickFakeClient() - Kicks a bot
// ------------------------------------------------------------------------
public Action: KickFakeClient(Handle: hTimer, any: Client)
{
	/* Connection check */
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

// ------------------------------------------------------------------------
// TankHasJoined() - Fixes tank not spawning in finale, thanks AtomicStryker
// ------------------------------------------------------------------------
public Action: TankHasJoined()
{
	/* Iterate all Clients */
	for (new target = 1; target <= GetMaxClients(); target++)
	{
		if (IsClientInGame(target))
		{
			/* Get the target Client class */
			new String: class[100];
			GetClientModel(target, class, sizeof(class));

			/* Kick all special infected that are not tanks */
			if (GetClientTeam(target) == 3 && IsFakeClient(target) && (StrContains(class, "hulk", false) == -1))
			{
				KickClient(target);
			}
		}
	}

	return Plugin_Continue;
}

// ------------------------------------------------------------------------
// Event_TankSpawn() - For SuperTank
// ------------------------------------------------------------------------
public Event_TankSpawn(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	if (!GetConVarInt(SuperTank))
	{
		return;
	}

	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	CreateTimer(1.0, SetTankHP, Client);
}

// ------------------------------------------------------------------------
// SetTankHP() - Sets tank HP if SuperTank is turned on
// ------------------------------------------------------------------------
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

// ------------------------------------------------------------------------
// HardZombies()
// ------------------------------------------------------------------------
public Action: HardZombies(Client, args)
{
	new String: arg[8];
	GetCmdArg(1, arg, 8);
	new Input = StringToInt(arg[0]);

	if (Input == 1)
	{
		SetConVarInt(FindConVar("z_common_limit"),		  		30); // Default
		SetConVarInt(FindConVar("z_mob_spawn_min_size"),		10); // Default
		SetConVarInt(FindConVar("z_mob_spawn_max_size"),		30); // Default
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"),	20); // Default
		SetConVarInt(FindConVar("z_mega_mob_size"),		 	45); // Default
	}
	else if (Input > 1 && Input < 7)
	{
		SetConVarInt(FindConVar("z_common_limit"),		  		30 * Input);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"),		30 * Input);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"),		30 * Input);
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

// ------------------------------------------------------------------------
// Event_FinaleVehicleLeaving() - Thanks to Mad_Dugan for this
// ------------------------------------------------------------------------
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
		/* Connection + escape check */
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

// ------------------------------------------------------------------------
// Event_MissionLost()
// ------------------------------------------------------------------------
public Event_MissionLost(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	/* Add one to total SurvivorLosses */
	SurvivorLosses++;
}

// ------------------------------------------------------------------------
// Event_FinaleWin()
// ------------------------------------------------------------------------
public Event_FinaleWin(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	/* Setup timer to force campaign change */
	CreateTimer(60.0, FinaleCampaignChange);
}

// ------------------------------------------------------------------------
// FinaleCampaignChange()
// ------------------------------------------------------------------------
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
		ServerCommand("changelevel l4d_hospital01_apartment");
	}
}

// ------------------------------------------------------------------------
// Event_ReviveSuccess() - Thanks to Mad_Dugan for this
// ------------------------------------------------------------------------
public Event_ReviveSuccess(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "subject"));
	ClientUnableToEscape[Client] = false;
}

// ------------------------------------------------------------------------
// Event_SurvivorRescued() - Thanks to Mad_Dugan for this
// ------------------------------------------------------------------------
public Event_SurvivorRescued(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	ClientUnableToEscape[Client] = false;
}

// ------------------------------------------------------------------------
// Event_PlayerIncapacitated() - Thanks to Mad_Dugan for this
// ------------------------------------------------------------------------
public Event_PlayerIncapacitated(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	ClientUnableToEscape[Client] = true;
}

// ------------------------------------------------------------------------
// Event_PlayerDeath() - Thanks to Mad_Dugan for this
// ------------------------------------------------------------------------
public Event_PlayerDeath(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	ClientUnableToEscape[Client] = true;
}

// ------------------------------------------------------------------------
// BypassAndExecuteCommand()
// ------------------------------------------------------------------------
BypassAndExecuteCommand(Client, String: strCommand[], String: strParam1[])
{
	new Flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, Flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, Flags);
}

// ------------------------------------------------------------------------
// AutoHavocControl() - Controls the difficulty
// ------------------------------------------------------------------------
AutoHavocControl()
{
	/* Make sure Auto Havoc is on */
	if (GetConVarInt(AutoHavoc))
	{
		if (SurvivorWins >= 4 && SurvivorWins < 7)
		{
			ServerCommand("sm_hardzombies 1");
			PrintHintTextToAll("Auto Havoc Level 1 activated.  Good luck!");
		}
		else if (SurvivorWins >= 7 && SurvivorWins <= 9)
		{
			ServerCommand("sm_hardzombies 2");
			PrintHintTextToAll("Auto Havoc Level 2 activated.  This should be fun!");
		}
		else if (SurvivorWins >= 10)
		{
			ServerCommand("sm_hardzombies 3");
			PrintHintTextToAll("Auto Havoc Level 3 activated. Time to die!");
		}

		/* Reset difficulty if things get too hot */
		if (SurvivorLosses >= GetConVarInt(AutoHavocCount))
		{
			AutoHavocReset();
		}
	}
}

// ------------------------------------------------------------------------
// AutoHavocControl() - Reset changed CVAR's to default
// ------------------------------------------------------------------------
AutoHavocReset()
{
	/* Reset the survivor performance count */
	SurvivorWins = 0;
	SurvivorLosses = 0;
}

// ------------------------------------------------------------------------
// ExtraMedkits()
// ------------------------------------------------------------------------
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

		/* Cycle through all medkits */
		new eMedkit = -1;
		while ((eMedkit = FindEntityByClassname(eMedkit, "weapon_first_aid_kit_spawn")) != -1)
		{
			decl Float: vMedkitPos[3];
			GetEntPropVector(eMedkit, Prop_Send, "m_vecOrigin", vMedkitPos);

			/* Found a medkit within range, we're done here */
			if (GetVectorDistance(vMedkitPos, vAmmoPos) <= 500)
			{
				return;
			}
		}

		/* If no medkits in range */
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

// ------------------------------------------------------------------------
// JoinSurvivors() - Switch Client to survivors
// ------------------------------------------------------------------------
public Action: JoinSurvivors(Client, args)
{
	FakeClientCommand(Client, "jointeam 2");

	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// OnAdminMenuReady() - Load Zombie Havoc custom menu
// ------------------------------------------------------------------------
public OnAdminMenuReady(Handle: TopMenu) {
	/* Block us from being called twice */
	if (TopMenu == AdminMenu)
	{
		return;
	}

	AdminMenu = TopMenu;

	/* Add a category to the SourceMod menu */
	AddToTopMenu(AdminMenu, "Zombie Havoc", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT);
	/* Get a handle for the catagory we just added so we can add items to it */
	new TopMenuObject: ZombieHavoc = FindTopMenuCategory(AdminMenu, "Zombie Havoc");

	/* Don't attempt to add items to the catagory if for some reason the catagory doesn't exist */
	if (ZombieHavoc == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	/* The order that items are added to menus has no relation to the order that they appear. Items are sorted alphabetically automatically
	Assign the menus to global values so we can easily check what a menu is when it is chosen */
	ChangeMap = AddToTopMenu(AdminMenu, "zm_changemap", TopMenuObject_Item, Menu_TopItemHandler, ZombieHavoc, "zm_changemap", ADMFLAG_CHEATS);
	SetAutoHavoc = AddToTopMenu(AdminMenu, "zm_auto_havoc", TopMenuObject_Item, Menu_TopItemHandler, ZombieHavoc, "zm_auto_havoc", ADMFLAG_CHEATS);
}

// ------------------------------------------------------------------------
// CategoryHandler() - Controls Zombie Havoc custom menu
// ------------------------------------------------------------------------
public CategoryHandler(Handle: topmenu, TopMenuAction: action, TopMenuObject: object_id, Client, String: buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "Zombie Havoc:");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Zombie Havoc");
	}
}

// ------------------------------------------------------------------------
// Menu_TopItemHandler() - Controls Zombie Havoc custom menu
// ------------------------------------------------------------------------
public Menu_TopItemHandler(Handle: topmenu, TopMenuAction: action, TopMenuObject: object_id, Client, String: buffer[], maxlength)
{
	/* When an item is displayed to a player tell the menu to format the item */
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == ChangeMap)
		{
			Format(buffer, maxlength, "Change Map");
		}
		if (object_id == SetAutoHavoc)
		{
			Format(buffer, maxlength, "Auto Havoc");
		}
	}
	/* When an item is selected do the following */
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

// ------------------------------------------------------------------------
// Menu_ChangeMap() - Creates Zombie Havoc change map menu
// ------------------------------------------------------------------------
public Action: Menu_ChangeMap(Client, args)
{
	new Handle: ChangeMapMenu = CreateMenu(MenuHandler_ChangeMap);
	SetMenuTitle(ChangeMapMenu, "Pick a Campaign:");

	AddMenuItem(ChangeMapMenu, "NoMercy", "No Mercy");
	AddMenuItem(ChangeMapMenu, "DeathToll", "Death Toll");
	AddMenuItem(ChangeMapMenu, "DeadAir", "Dead Air");
	AddMenuItem(ChangeMapMenu, "BloodHarvest", "Blood Harvest");

	DisplayMenu(ChangeMapMenu, Client, 20);

	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// MenuHandler_ChangeMap() - Handles Zombie Havoc custom campaign menu
// ------------------------------------------------------------------------
public MenuHandler_ChangeMap(Handle: ChangeMapMenu, MenuAction: action, Client, CampaignName)
{
	if (action == MenuAction_Select)
	{
		switch (CampaignName)
		{
			case 0:
			{
				new Handle: NoMercyMenu = CreateMenu(NoMercyMenuHandler);
				SetMenuTitle(NoMercyMenu, "No Mercy Maps:");

				AddMenuItem(NoMercyMenu, "NM_Apartment", "Apartment");
				AddMenuItem(NoMercyMenu, "NM_Subway", "Subway");
				AddMenuItem(NoMercyMenu, "NM_Sewers", "Sewers");
				AddMenuItem(NoMercyMenu, "NM_Interior", "Interior");
				AddMenuItem(NoMercyMenu, "NM_Rooftop", "Rooftop Finale");

				DisplayMenu(NoMercyMenu, Client, 20);
			}
			case 1:
			{
				new Handle: DeathTollMenu = CreateMenu(DeathTollMenuHandler);
				SetMenuTitle(DeathTollMenu, "Death Toll Maps:");

				AddMenuItem(DeathTollMenu, "DT_Caves", "Caves");
				AddMenuItem(DeathTollMenu, "DT_Drainage", "Drainage");
				AddMenuItem(DeathTollMenu, "DT_RanchHouse", "Ranch House");
				AddMenuItem(DeathTollMenu, "DT_MainStreet", "Main Street");
				AddMenuItem(DeathTollMenu, "DT_Houseboat", "Houseboat Finale");

				DisplayMenu(DeathTollMenu, Client, 20);
			}
			case 2:
			{
				new Handle: DeadAirMenu = CreateMenu(DeadAirMenuHandler);
				SetMenuTitle(DeadAirMenu, "Dead Air Maps:");

				AddMenuItem(DeadAirMenu, "DA_Greenhouse", "Greenhouse");
				AddMenuItem(DeadAirMenu, "DA_Officies", "Offices");
				AddMenuItem(DeadAirMenu, "DA_Garage", "Garage");
				AddMenuItem(DeadAirMenu, "DA_Terminal", "Terminal");
				AddMenuItem(DeadAirMenu, "DA_Runway", "Runway Finale");

				DisplayMenu(DeadAirMenu, Client, 20);
			}
			case 3:
			{
				new Handle: BloodHarvestMenu = CreateMenu(BloodHarvestMenuHandler);
				SetMenuTitle(BloodHarvestMenu, "Blood Harvest Maps:");

				AddMenuItem(BloodHarvestMenu, "BH_Hilltop", "Hilltop");
				AddMenuItem(BloodHarvestMenu, "BH_TrainTunnel", "Train Tunnel");
				AddMenuItem(BloodHarvestMenu, "BH_Bridge", "Bridge");
				AddMenuItem(BloodHarvestMenu, "BH_Barn", "Barn");
				AddMenuItem(BloodHarvestMenu, "BH_Cornfield", "Cornfield Finale");

				DisplayMenu(BloodHarvestMenu, Client, 20);
			}
		}
	}
}

// ------------------------------------------------------------------------
// NoMercyMenuHandler - Handles Zombie Havoc custom map menu
// ------------------------------------------------------------------------
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

// ------------------------------------------------------------------------
// DeathTollMenuHandler - Handles Zombie Havoc custom map menu
// ------------------------------------------------------------------------
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

// ------------------------------------------------------------------------
// DeadAirMenuHandler - Handles Zombie Havoc custom map menu
// ------------------------------------------------------------------------
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

// ------------------------------------------------------------------------
// BloodHarvestMenuHandler - Handles Zombie Havoc custom map menu
// ------------------------------------------------------------------------
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

// ------------------------------------------------------------------------
// Menu_SetAutoHavoc() - Creates Zombie Havoc auto havoc set
// ------------------------------------------------------------------------
public Action: Menu_SetAutoHavoc(Client, args)
{
	new Handle: SetAutoHavocMenu = CreateMenu(MenuHandler_SetAutoHavocMenu);
	SetMenuTitle(SetAutoHavocMenu, "Toggle Auto Havoc:");

	AddMenuItem(SetAutoHavocMenu, "AutoHavocOn", "On");
	AddMenuItem(SetAutoHavocMenu, "AutoHavocOff", "Off");

	DisplayMenu(SetAutoHavocMenu, Client, 20);

	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// MenuHandler_SetAutoHavoc - Handles Zombie Havoc auto havoc
// ------------------------------------------------------------------------
public MenuHandler_SetAutoHavocMenu(Handle: SetAutoHavocMenu, MenuAction: action, Client, AutoHavocVar)
{
	if (action == MenuAction_Select)
	{
		switch (AutoHavocVar)
		{
			case 0:
			{
				SetConVarInt(AutoHavoc, 1);
			}
			case 1:
			{
				SetConVarInt(AutoHavoc, 0);
			}
		}
	}
}