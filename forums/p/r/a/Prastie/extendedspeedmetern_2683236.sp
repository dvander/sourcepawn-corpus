/*****************************************************************


C O M P I L E   O P T I O N S


*****************************************************************/

// enforce semicolons after each code statement
#pragma semicolon 1

/*****************************************************************


P L U G I N   I N C L U D E S


*****************************************************************/

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smlib/pluginmanager>
#include <colors>

// Optional admin menu implementation
#undef REQUIRE_PLUGIN
#include <adminmenu>

/*****************************************************************


P L U G I N   I N F O


*****************************************************************/

#define PLUGIN_NAME				"Extended Speed meter"
#define PLUGIN_TAG				"sm"
#define PLUGIN_AUTHOR			"kiljon (based on Chanz's work)"
#define PLUGIN_DESCRIPTION		"Shows current player speed in HUD, saves it and manages the highest."
#define PLUGIN_VERSION 			"1.4"
#define PLUGIN_URL				"https://forums.alliedmods.net/showthread.php?p=2336846"

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

/*****************************************************************


P L U G I N   D E F I N E S


*****************************************************************/

#define MAX_UNIT_TYPES 4
#define MAX_UNITMESS_LENGTH 5

#define STEAMAUTH_LENGTH 32
#define MAX_MAPNAME_LENGTH	32

#define ADMINMENU_TOPSPEEDCOMMANDS		"TopspeedCommands"

/*****************************************************************


G L O B A L   V A R S


*****************************************************************/

// ConVar Handles
new Handle:g_cvarUnit = INVALID_HANDLE;
new Handle:g_cvarFloodTime = INVALID_HANDLE;
new Handle:g_cvarDisplayTick = INVALID_HANDLE;
new Handle:g_cvarShowHUD = INVALID_HANDLE;
new Handle:g_cvarShowSpeedToSpecs = INVALID_HANDLE;
new Handle:g_cvarShowRoundTopspeeds = INVALID_HANDLE;
new Handle:g_cvarShowGameTopspeeds = INVALID_HANDLE;
new Handle:g_cvarShowTopspeedMapMenu = INVALID_HANDLE;
new Handle:g_cvarShowTopspeedTopMenu = INVALID_HANDLE;
new Handle:g_cvarShowNewTopspeedMapMessage = INVALID_HANDLE;
new Handle:g_cvarShowZeroTopspeeds = INVALID_HANDLE;
new Handle:g_cvarCheckSoundPrecache = INVALID_HANDLE;
new Handle:g_cvarAmountOfTopspeedMap = INVALID_HANDLE;
new Handle:g_cvarAmountOfTopspeedTop = INVALID_HANDLE;
new Handle:g_cvarAmountOfPrintedRecords = INVALID_HANDLE;
new Handle:g_cvarAmountOfSecondsInfoHelpPrintInterval = INVALID_HANDLE;
new Handle:g_cvarDatabaseConfigName = INVALID_HANDLE;
new Handle:g_cvarExtendedSpeedMeterVersion = INVALID_HANDLE;

// ConVars runtime saver
new g_iPlugin_Unit = 0;
new Float:g_fPlugin_FloodTime = 0.0;
new Float:g_fPlugin_DisplayTick = 0.0;
new bool:g_bPlugin_ShowHUD = false;
new bool:g_bPlugin_ShowSpeedToSpecs = false;
new bool:g_bPlugin_ShowRoundTopspeeds = false;
new bool:g_bPlugin_ShowGameTopspeeds = false;
new bool:g_bPlugin_ShowTopspeedMapMenu = false;
new bool:g_bPlugin_ShowTopspeedTopMenu = false;
new bool:g_bPlugin_ShowNewTopspeedMapMessage = false;
new bool:g_bPlugin_ShowZeroTopspeeds = false;
new bool:g_bPlugin_CheckSoundPrecache = false;
new g_iPlugin_AmountOfTopspeedMap = 0;
new g_iPlugin_AmountOfTopspeedTop = 0;
new g_iPlugin_AmountOfPrintedRecords = 0;
new g_iPlugin_AmountOfSecondsInfoHelpPrintInterval = 0;
new String:g_sPlugin_DatabaseConfigName[255];
new String:g_sPlugin_ExtendedSpeedMeterVersion[4];

// Game
new g_bIsHL2DM = false;

// Timer
new Handle:g_hTimer_Think = INVALID_HANDLE;

// Dynamic Arrays
new Handle:g_hSessionSteamId = INVALID_HANDLE;
new Handle:g_hSessionName = INVALID_HANDLE;
new Handle:g_hSessionMaxSpeedRound = INVALID_HANDLE;
new Handle:g_hSessionMaxSpeedGame = INVALID_HANDLE;
new Handle:g_hSessionMaxSpeedGameTimeStamp = INVALID_HANDLE;
new Handle:g_hSessionHigherRecord = INVALID_HANDLE;
new Handle:g_hSessionNewRecord = INVALID_HANDLE;

new Handle:g_hRecordSteamId = INVALID_HANDLE;
new Handle:g_hRecordName = INVALID_HANDLE;
new Handle:g_hRecordMaxSpeed = INVALID_HANDLE;
new Handle:g_hRecordMaxSpeedTimeStamp = INVALID_HANDLE;

new Handle:g_hAllSteamId = INVALID_HANDLE;
new Handle:g_hAllName = INVALID_HANDLE;
new Handle:g_hAllMaxSpeed = INVALID_HANDLE;
new Handle:g_hAllMaxSpeedTimeStamp = INVALID_HANDLE;

new Handle:g_hHighestOverallSteamId = INVALID_HANDLE;
new Handle:g_hHighestOverallName = INVALID_HANDLE;
new Handle:g_hHighestOverallMapName = INVALID_HANDLE;
new Handle:g_hHighestOverallMaxSpeed = INVALID_HANDLE;
new Handle:g_hHighestOverallMaxSpeedTimeStamp = INVALID_HANDLE;

new Handle:g_hDifferentMapList = INVALID_HANDLE;
new Handle:g_hDifferentMapRecordSteamId = INVALID_HANDLE;
new Handle:g_hDifferentMapRecordName = INVALID_HANDLE;
new Handle:g_hDifferentMapRecordMaxSpeed = INVALID_HANDLE;
new Handle:g_hDifferentMapRecordMaxSpeedTimeStamp = INVALID_HANDLE;
new Handle:g_hDifferentMapRecordMapName = INVALID_HANDLE;

// Game Management
new bool:g_bRoundEnded = false;
new bool:g_bGameEnded = false;

// Connection to database
new Handle:g_hSQL;
new g_iReconnectCounter = 0;

// TopMenu (admin menu)
new Handle:g_hTopMenu = INVALID_HANDLE;

// Misc
new bool:g_bClientSetZero[MAXPLAYERS + 1];
new Float:g_fLastCommand = 0.0;
new Float:g_fHighestSpeedrecord = 0.0;
new String:g_sCurrentMap[MAX_MAPNAME_LENGTH];
new bool:g_bHelpJustPrinted = false;
new bool:g_bFirstMapLoad = true;

new String:g_szUnitMess_Name[MAX_UNIT_TYPES][MAX_UNITMESS_LENGTH] = {
	
	"km/h",
	"mph",
	"u/s",
	"m/s"
};

new Float:g_fUnitMess_Calc[MAX_UNIT_TYPES] = {
	
	0.04263157894736842105263157894737,
	0.05681807590283512505382617918945,
	1.0,
	0.254
};

/*****************************************************************


F O R W A R D   P U B L I C S


*****************************************************************/

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	
	MarkNativeAsOptional("IsVoteInProgress");
	return APLRes_Success;
}

/**
* Plugin started! Initialize everything!
*/
public OnPluginStart()
{
	
	//Translations
	LoadTranslations("plugin.extendedspeedmeter.phrases");
	
	//Init for smlib
	SMLib_OnPluginStart(PLUGIN_NAME, PLUGIN_TAG, PLUGIN_VERSION, PLUGIN_AUTHOR, PLUGIN_DESCRIPTION, PLUGIN_URL);
	
	// Check the current game by checking the folder
	new String:gamedir[PLATFORM_MAX_PATH];
	GetGameFolderName(gamedir, sizeof(gamedir));
	
	// Get all ConVars
	g_cvarUnit = CreateConVarEx("unit", "0", "Unit of measurement of speed (0=kilometers per hour, 1=miles per hour, 2=units per second, 3=meters per second)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_cvarDisplayTick = CreateConVarEx("tick", "0.2", "This sets how often the display is redrawn (this is the display tick rate).", FCVAR_NOTIFY);
	g_cvarShowHUD = CreateConVarEx("showhud", "1", "Display the speedmeter HUD?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarShowSpeedToSpecs = CreateConVarEx("showtospecs", "1", "Should spectators be able to see the speed of the one they are spectating?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarShowRoundTopspeeds = CreateConVarEx("showroundtopspeeds", "1", "Display the highest topspeeds of the current round at the end of the round?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarShowGameTopspeeds = CreateConVarEx("showgametopspeeds", "1", "Display the highest topspeeds of the current game at the end of the game?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarShowTopspeedMapMenu = CreateConVarEx("showtopspeedmapmenu", "1", "Display a menu to view all the highest topspeeds of the current map?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarShowTopspeedTopMenu = CreateConVarEx("showtopspeedtopmenu", "1", "Display a menu to view all the highest topspeeds across all maps?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarShowNewTopspeedMapMessage = CreateConVarEx("shownewtopspeedmapmessage", "1", "Display a message when the highest topspeed of the current map is beaten? (automatically disabled for new clients for spam reasons with new maps)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarShowZeroTopspeeds = CreateConVarEx("showzerotopspeeds", "0", "Display topspeeds with the value 0?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarAmountOfTopspeedMap = CreateConVarEx("amountofrecordsintopspeedmap", "0", "This sets how many records should be shown in the topspeedmap menu (0: unlimited)", FCVAR_NOTIFY);
	g_cvarAmountOfTopspeedTop = CreateConVarEx("amountofrecordsintopspeedtop", "10", "This sets how many records should be shown in the topspeedtop menu", FCVAR_NOTIFY);
	g_cvarAmountOfPrintedRecords = CreateConVarEx("amountofprintedrecords", "3", "This sets how many records should be printed in chat", FCVAR_NOTIFY);
	g_cvarAmountOfSecondsInfoHelpPrintInterval = CreateConVarEx("amountofsecondsinfohelpprintinterval", "240", "This sets per how many seconds an info message for help should be printed in chat (0: disabled)", FCVAR_NOTIFY);
	g_cvarDatabaseConfigName = CreateConVarEx("databaseconfigname", "default", "This sets which database config should be used to store the topspeed table in (check addons/sourcemod/configs/databases.cfg)", FCVAR_NOTIFY);
	g_cvarExtendedSpeedMeterVersion = CreateConVarEx("version", PLUGIN_VERSION, "This sets sets the current version of the extended speed meter", FCVAR_NOTIFY);
	
	// Team Fortress 2 and Counter Strike Source cache the game sound so the cvar of soundchecking should be set to 1
	new String:checkPrecache[1];
	checkPrecache = "0";
	if (StrEqual(gamedir, "cstrike", false) || StrEqual(gamedir, "tf", false))
	{
		checkPrecache = "1";
	}
	g_cvarCheckSoundPrecache = CreateConVarEx("checksoundprecache", checkPrecache, "Check if the hint sound is precached? (enabling this will make this plugin try to stop the UI/hint.wav, a spamming sound that notifies a player that a hint is displayed) This plugin will enable this automatically for TF2 and CSS. If the game doesn't support this, it will give the 'SV_StartSound: UI/hint.wav not precached (0)' error and then you set this cvar to 0. If the game does support it, it might still give issues, try sv_hudhint_sound 0 to stop the hint sounds or a similar console command.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//g_cvar_FloodTime will be found in OnConfigsExecuted!
	
	// ConVar Runtime optimizer
	g_iPlugin_Unit = GetConVarInt(g_cvarUnit);
	g_fPlugin_DisplayTick = GetConVarFloat(g_cvarDisplayTick);
	g_bPlugin_ShowHUD = bool:GetConVarInt(g_cvarShowHUD);
	g_bPlugin_ShowSpeedToSpecs = bool:GetConVarInt(g_cvarShowSpeedToSpecs);
	g_bPlugin_ShowRoundTopspeeds = bool:GetConVarInt(g_cvarShowRoundTopspeeds);
	g_bPlugin_ShowGameTopspeeds = bool:GetConVarInt(g_cvarShowGameTopspeeds);
	g_bPlugin_ShowTopspeedMapMenu = bool:GetConVarInt(g_cvarShowTopspeedMapMenu);
	g_bPlugin_ShowTopspeedTopMenu = bool:GetConVarInt(g_cvarShowTopspeedTopMenu);
	g_bPlugin_ShowNewTopspeedMapMessage = bool:GetConVarInt(g_cvarShowNewTopspeedMapMessage);
	g_bPlugin_ShowZeroTopspeeds = bool:GetConVarInt(g_cvarShowZeroTopspeeds);
	g_bPlugin_CheckSoundPrecache = bool:GetConVarInt(g_cvarCheckSoundPrecache);
	g_iPlugin_AmountOfTopspeedMap = GetConVarInt(g_cvarAmountOfTopspeedMap);
	g_iPlugin_AmountOfTopspeedTop = GetConVarInt(g_cvarAmountOfTopspeedTop);
	g_iPlugin_AmountOfPrintedRecords = GetConVarInt(g_cvarAmountOfPrintedRecords);
	g_iPlugin_AmountOfSecondsInfoHelpPrintInterval = GetConVarInt(g_cvarAmountOfSecondsInfoHelpPrintInterval);
	GetConVarString(g_cvarDatabaseConfigName, g_sPlugin_DatabaseConfigName, sizeof(g_sPlugin_DatabaseConfigName));
	GetConVarString(g_cvarExtendedSpeedMeterVersion, g_sPlugin_ExtendedSpeedMeterVersion, sizeof(g_sPlugin_ExtendedSpeedMeterVersion));
	//g_cvar_FloodTime is set in OnConfigsExecuted!
	
	// Find out if the game is HL2 deathmatch because that needs a different kind of text display
	if (StrEqual(gamedir, "hl2mp", false))
	{
		g_bIsHL2DM = true;
	}
	else
	{
		g_bIsHL2DM = false;
	}
	
	// Create the dynamic arrays
	g_hSessionSteamId = CreateArray(MAX_STEAMAUTH_LENGTH);
	g_hSessionName = CreateArray(MAX_NAME_LENGTH);
	g_hSessionMaxSpeedRound = CreateArray(4);
	g_hSessionMaxSpeedGame = CreateArray(4);
	g_hSessionMaxSpeedGameTimeStamp = CreateArray(20);
	g_hSessionHigherRecord = CreateArray(5);
	g_hSessionNewRecord = CreateArray(5);
	
	g_hRecordSteamId = CreateArray(MAX_STEAMAUTH_LENGTH);
	g_hRecordName = CreateArray(MAX_NAME_LENGTH);
	g_hRecordMaxSpeed = CreateArray(4);
	g_hRecordMaxSpeedTimeStamp = CreateArray(20);
	
	g_hAllSteamId = CreateArray(MAX_STEAMAUTH_LENGTH);
	g_hAllName = CreateArray(MAX_NAME_LENGTH);
	g_hAllMaxSpeed = CreateArray(4);
	g_hAllMaxSpeedTimeStamp = CreateArray(20);
	
	g_hHighestOverallSteamId = CreateArray(MAX_STEAMAUTH_LENGTH);
	g_hHighestOverallName = CreateArray(MAX_NAME_LENGTH);
	g_hHighestOverallMapName = CreateArray(MAX_MAPNAME_LENGTH);
	g_hHighestOverallMaxSpeed = CreateArray(4);
	g_hHighestOverallMaxSpeedTimeStamp = CreateArray(20);
	
	g_hDifferentMapList = CreateArray(MAX_MAPNAME_LENGTH);
	
	g_hDifferentMapRecordSteamId = CreateArray(MAX_STEAMAUTH_LENGTH);
	g_hDifferentMapRecordName = CreateArray(MAX_NAME_LENGTH);
	g_hDifferentMapRecordMaxSpeed = CreateArray(4);
	g_hDifferentMapRecordMaxSpeedTimeStamp = CreateArray(20);
	g_hDifferentMapRecordMapName = CreateArray(MAX_MAPNAME_LENGTH);
	
	// Hook the ConVars
	HookConVarChange(g_cvarUnit, ConVarTopspeed_Change);
	HookConVarChange(g_cvarDisplayTick, ConVarTopspeed_Change);
	HookConVarChange(g_cvarShowHUD, ConVarTopspeed_Change);
	HookConVarChange(g_cvarShowSpeedToSpecs, ConVarTopspeed_Change);
	HookConVarChange(g_cvarShowRoundTopspeeds, ConVarTopspeed_Change);
	HookConVarChange(g_cvarShowGameTopspeeds, ConVarTopspeed_Change);
	HookConVarChange(g_cvarShowTopspeedMapMenu, ConVarTopspeed_Change);
	HookConVarChange(g_cvarShowTopspeedTopMenu, ConVarTopspeed_Change);
	HookConVarChange(g_cvarShowNewTopspeedMapMessage, ConVarTopspeed_Change);
	HookConVarChange(g_cvarShowZeroTopspeeds, ConVarTopspeed_Change);
	HookConVarChange(g_cvarCheckSoundPrecache, ConVarTopspeed_Change);
	HookConVarChange(g_cvarAmountOfTopspeedMap, ConVarTopspeed_Change);
	HookConVarChange(g_cvarAmountOfTopspeedTop, ConVarTopspeed_Change);
	HookConVarChange(g_cvarAmountOfPrintedRecords, ConVarTopspeed_Change);
	HookConVarChange(g_cvarAmountOfSecondsInfoHelpPrintInterval, ConVarTopspeed_Change);
	HookConVarChange(g_cvarDatabaseConfigName, ConVarTopspeed_Change);
	//g_cvar_FloodTime is hooked in OnConfigsExecuted!
	//g_cvarExtendedSpeedMeterVersion does not need a hook
	
	// Hook events
	HookEventEx("round_start", OnRoundStart);
	HookEventEx("round_end", OnRoundEnd);
	HookEvent("player_changename", Event_PlayerNameChange);
	
	// Console Commands
	RegConsoleCmd("topspeed", Command_TopSpeedCurrent, "Shows the current fastest players on the map");
	RegConsoleCmd("topspeeds", Command_TopSpeedCurrent, "Shows the current fastest players on the map");
	RegConsoleCmd("topspeedmap", Command_TopSpeedAllTime, "Shows the all time fastest players on the map");
	RegConsoleCmd("topspeedtop", Command_TopSpeedTop, "Shows the fastest players ever");
	RegConsoleCmd("topspeedpr", Command_TopSpeedPersonal, "Shows the records of the current player");
	RegConsoleCmd("topspeedhelp", Command_TopSpeedHelp, "Shows help for the topspeed plugin");
	
	// Admin commands
	RegAdminCmd("sm_listtopspeed", Command_ListTopSpeed, ADMFLAG_ROOT, "Dumps all current topspeed players information in the console");
	RegAdminCmd("sm_topspeedadmin", Command_TopspeedAdmin, ADMFLAG_BAN, "Manage all topspeeds & topspeed records");
	
	RegAdminCmd("sm_topspeedreset", Command_TopspeedReset, ADMFLAG_BAN, "sm_topspeedreset");
	RegAdminCmd("sm_topspeedresetall", Command_TopspeedResetAll, ADMFLAG_BAN, "sm_topspeedresetall");
	RegAdminCmd("sm_topspeeddelete", Command_TopspeedDelete, ADMFLAG_BAN, "sm_topspeeddelete");
	RegAdminCmd("sm_topspeeddeleteall", Command_TopspeedDeleteAll, ADMFLAG_BAN, "sm_topspeeddeleteall");
	RegAdminCmd("sm_topspeeddeletedifferent", Command_TopspeedDeleteDifferent, ADMFLAG_BAN, "sm_topspeeddeletedifferent");
	RegAdminCmd("sm_topspeeddeletedifferentall", Command_TopspeedDeleteDifferentAll, ADMFLAG_BAN, "sm_topspeeddeletedifferentall");
	
	// Check admin menu
	new Handle:_hTemp = INVALID_HANDLE;
	if(LibraryExists("adminmenu") && ((_hTemp = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(_hTemp);
	
	// Auto Config (you should always use it)
	// Always with "plugin." prefix and the short name
	decl String:configName[MAX_PLUGIN_SHORTNAME_LENGTH + 8];
	Format(configName, sizeof(configName), "plugin.%s", g_sPlugin_Short_Name);
	AutoExecConfig(true, configName);
	
	// Connect to SQL and create a table for this plugin if it has not been created yet
	ConnectSQL();
}

/**
* All configs are executed, actually start the timer for the plugin.
*/
public OnConfigsExecuted()
{
	
	// Verify that the timer for the plugin is invalid
	if (g_hTimer_Think == INVALID_HANDLE)
	{
		// Start timer for the plugin
		g_hTimer_Think = CreateTimer(g_fPlugin_DisplayTick, Timer_Think, INVALID_HANDLE, TIMER_REPEAT);
	}
	
	// Find the flood time ConVar and hook a change event
	g_cvarFloodTime = FindConVar("sm_flood_time");
	g_fPlugin_FloodTime = GetConVarFloat(g_cvarFloodTime);
	HookConVarChange(g_cvarFloodTime, ConVarChange_FloodTime);
	
	//Late load init.
	ClientAll_Initialize();
}

/**
* A map started, reset all data and fetch the records from the database.
*/
public OnMapStart()
{
	
	/* original fix
	// hax against valvefail (thx psychonic for fix)
	if (GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE)
	{
		SetConVarString(g_cvarVersion, PLUGIN_VERSION);
	}*/
	
	// new fix
	// hax against valvefail (thx psychonic for fix)
	if (GetEngineVersion() == Engine_DODS || GetEngineVersion() == Engine_HL2DM || GetEngineVersion() == Engine_TF2)
	{
		SetConVarString(g_cvarVersion, PLUGIN_VERSION);
	}
	
	// Set the last command time against flooding
	g_fLastCommand = GetGameTime();
	
	// Clear all dynamic arrays that store data for the map
	ClearArray(g_hSessionSteamId);
	ClearArray(g_hSessionName);
	ClearArray(g_hSessionMaxSpeedRound);
	ClearArray(g_hSessionMaxSpeedGame);
	ClearArray(g_hSessionMaxSpeedGameTimeStamp);
	ClearArray(g_hSessionHigherRecord);
	ClearArray(g_hSessionNewRecord);
	
	ClearArray(g_hRecordSteamId);
	ClearArray(g_hRecordName);
	ClearArray(g_hRecordMaxSpeed);
	ClearArray(g_hRecordMaxSpeedTimeStamp);
	
	ClearArray(g_hAllSteamId);
	ClearArray(g_hAllName);
	ClearArray(g_hAllMaxSpeed);
	ClearArray(g_hAllMaxSpeedTimeStamp);
	
	ClearArray(g_hHighestOverallSteamId);
	ClearArray(g_hHighestOverallName);
	ClearArray(g_hHighestOverallMapName);
	ClearArray(g_hHighestOverallMaxSpeed);
	ClearArray(g_hHighestOverallMaxSpeedTimeStamp);
	
	ClearArray(g_hDifferentMapList);
	ClearArray(g_hDifferentMapRecordSteamId);
	ClearArray(g_hDifferentMapRecordName);
	ClearArray(g_hDifferentMapRecordMaxSpeed);
	ClearArray(g_hDifferentMapRecordMaxSpeedTimeStamp);
	ClearArray(g_hDifferentMapRecordMapName);
	
	// Loop all clients
	for (new client=1; client<=MaxClients; client++)
	{
		
		// Verify that the client is in game and authorized
		if (!IsClientInGame(client) || !IsClientAuthorized(client))
		{
			continue;
		}
		
		// Add the client to the arrays
		InsertNewPlayer(client);
	}
	
	// Remember that the game and round are starting
	g_bGameEnded = false;
	g_bRoundEnded = false;
	
	// Get the current map name
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
	String_ToLower(g_sCurrentMap, g_sCurrentMap, sizeof(g_sCurrentMap));
	
	// Get the speed records of the current map (if it's the first map it'll be loaded by the connect SQL function)
	if (!g_bFirstMapLoad)
	{
		GetMapRecords(g_sCurrentMap);
	}
	else
	{
		g_bFirstMapLoad = false;
	}
}

/**
* A map ended, save the records to the database.
*/
public OnMapEnd()
{
	
	// Save the possible new records
	SaveMapRecords();
}

/**
* An user connected, initialize its client.
*/
public OnClientConnected(client)
{
	
	Client_Initialize(client);
}

/**
* An admin connected, initialize its client.
*/
public OnClientPostAdminCheck(client)
{
	
	Client_Initialize(client);
}

/*****************************************************************


C A L L B A C K   F U N C T I O N S


*****************************************************************/

/**
* ConVar following changes. (StrToInt gives 0 with an error, StrToFloat gives 0.0 with an error)
*/
public ConVarTopspeed_Change(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == g_cvarUnit)
	{
		// Get the new value
		g_iPlugin_Unit = StringToInt(newVal);
	}
	else if (cvar == g_cvarDisplayTick)
	{
		// Get the new value
		g_fPlugin_DisplayTick = StringToFloat(newVal);
		
		// Make sure the new value is valid
		if (g_fPlugin_DisplayTick > 0.0)
		{
			// Check if the timer is currently active
			if (g_hTimer_Think != INVALID_HANDLE)
			{
				// Stop the timer if it was active
				KillTimer(g_hTimer_Think);
				g_hTimer_Think = INVALID_HANDLE;
			}
			
			// Create a new timer with the given tick
			g_hTimer_Think = CreateTimer(g_fPlugin_DisplayTick, Timer_Think, INVALID_HANDLE, TIMER_REPEAT);
		}
	}
	else if (cvar == g_cvarShowHUD)
	{
		// Get the new value
		g_bPlugin_ShowHUD = bool:StringToInt(newVal);
	}
	else if (cvar == g_cvarShowSpeedToSpecs)
	{
		// Get the new value
		g_bPlugin_ShowSpeedToSpecs = bool:StringToInt(newVal);
	}
	else if (cvar == g_cvarShowRoundTopspeeds)
	{
		// Get the new value
		g_bPlugin_ShowRoundTopspeeds = bool:StringToInt(newVal);
	}
	else if (cvar == g_cvarShowGameTopspeeds)
	{
		// Get the new value
		g_bPlugin_ShowGameTopspeeds = bool:StringToInt(newVal);
	}
	else if (cvar == g_cvarShowTopspeedMapMenu)
	{
		// Get the new value
		g_bPlugin_ShowTopspeedMapMenu = bool:StringToInt(newVal);
	}
	else if (cvar == g_cvarShowTopspeedTopMenu)
	{
		// Get the new value
		g_bPlugin_ShowTopspeedTopMenu = bool:StringToInt(newVal);
	}
	else if (cvar == g_cvarShowNewTopspeedMapMessage)
	{
		// Get the new value
		g_bPlugin_ShowNewTopspeedMapMessage = bool:StringToInt(newVal);
	}
	else if (cvar == g_cvarShowZeroTopspeeds)
	{
		// Get the new value
		g_bPlugin_ShowZeroTopspeeds = bool:StringToInt(newVal);
	}
	else if (cvar == g_cvarCheckSoundPrecache)
	{
		// Get the new value
		g_bPlugin_CheckSoundPrecache = bool:StringToInt(newVal);
	}
	else if (cvar == g_cvarAmountOfTopspeedMap)
	{
		// Get the new value
		g_iPlugin_AmountOfTopspeedMap = StringToInt(newVal);
	}
	else if (cvar == g_cvarAmountOfTopspeedTop)
	{
		// Get the new value
		g_iPlugin_AmountOfTopspeedTop = StringToInt(newVal);
	}
	else if (cvar == g_cvarAmountOfPrintedRecords)
	{
		// Get the new value
		g_iPlugin_AmountOfPrintedRecords = StringToInt(newVal);
	}
	else if (cvar == g_cvarAmountOfSecondsInfoHelpPrintInterval)
	{
		// Get the new value
		g_iPlugin_AmountOfSecondsInfoHelpPrintInterval = StringToInt(newVal);
	}
	else if (cvar == g_cvarDatabaseConfigName)
	{
		// Check that the value is not the same
		if (StrEqual(g_sPlugin_DatabaseConfigName, newVal, true))
		{
			// Get the new value
			strcopy(g_sPlugin_DatabaseConfigName, sizeof(g_sPlugin_DatabaseConfigName), newVal);
			
			// Reconnect to the database
			ConnectSQL();
			
			// Temporary declaration
			decl String:steamId[MAX_STEAMAUTH_LENGTH];
			
			// Get the map records again
			ClearArray(g_hRecordSteamId);
			ClearArray(g_hRecordName);
			ClearArray(g_hRecordMaxSpeed);
			ClearArray(g_hRecordMaxSpeedTimeStamp);
			GetMapRecords(g_sCurrentMap);
			
			// Check all clients their status
			new size = GetArraySize(g_hSessionName);
			decl Float:gamespeed;
			
			for (new i=0; i<size; i++)
			{
				
				// Get all the client details
				GetArrayString(g_hSessionSteamId, i, steamId, sizeof(steamId));
				gamespeed = GetArrayCell(g_hSessionMaxSpeedGame, i);
				
				// Check if the client has a record in the new database
				new recordInNewDatabaseId = FindStringInArray(g_hRecordSteamId, steamId);
				if (recordInNewDatabaseId != -1)
				{
					// The client has a record, remember it and check if the current one is higher
					SetArrayCell(g_hSessionNewRecord, i, false);
					if (gamespeed > GetArrayCell(g_hRecordMaxSpeed, recordInNewDatabaseId))
					{
						SetArrayCell(g_hSessionHigherRecord, i, true);
					}
					else
					{
						SetArrayCell(g_hSessionHigherRecord, i, false);
					}
				}
				else
				{
					// The client does not have a record, remember it
					SetArrayCell(g_hSessionNewRecord, i, true);
				}
			}
		}
	}
}

/**
* ConVar following changes of the flood time.
*/
public ConVarChange_FloodTime(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	
	// Get the new value
	g_fPlugin_FloodTime = StringToFloat(newVal);
}

/**
* Command to list all current session/game speedrecords.
*/
public Action:Command_TopSpeedCurrent(client, args)
{
	
	// Do the command after flood verification
	if (VerifyNoSpam(client))
	{
		ShowBestCurrentSession();
	}
	
	return Plugin_Handled;
}

/**
* Command to list all time world speedrecords.
*/
public Action:Command_TopSpeedAllTime(client, args)
{
	
	// Do the command after flood verification
	if (VerifyNoSpam(client))
	{
		ShowBestAllTime(client);
	}
	
	return Plugin_Handled;
}

/**
* Command to list the highest speedrecords ever.
*/
public Action:Command_TopSpeedTop(client, args)
{
	
	// Do the command after flood verification
	if (VerifyNoSpam(client))
	{
		ShowHighestOverall(client);
	}
	
	return Plugin_Handled;
}

/**
* Command to list the speedrecords of the current player.
*/
public Action:Command_TopSpeedPersonal(client, args)
{
	
	// Do the command after flood verification
	if (VerifyNoSpam(client))
	{
		ShowPersonal(client);
	}
	
	return Plugin_Handled;
}

/**
* Command to show help about the topspeed commands.
*/
public Action:Command_TopSpeedHelp(client, args)
{
	
	// Do the command after flood verification
	if (VerifyNoSpam(client))
	{
		ShowHelp(client);
	}
	
	return Plugin_Handled;
}

/**
* Prevent spam by keeping track of the last time a topspeed command was executed.
*/
stock VerifyNoSpam(clientCurrent)
{
	// Make sure the command isn't spammed by checking last command time
	if (g_fLastCommand > GetGameTime())
	{
		// Print a warning to the client
		PrintToChat(clientCurrent, "[SM] %t!", "You are flooding the server, try again later");
		
		return false;
	}
	
	// Check if sm_flood_time was set and set the last command time (in the future) to prevent flood
	if (g_cvarFloodTime != INVALID_HANDLE)
	{
		// The value was set, add that to the current game time
		g_fLastCommand = GetGameTime() + g_fPlugin_FloodTime;
	}
	else
	{
		// The value was set, add a default 0.75
		g_fLastCommand = GetGameTime() + 0.75;
	}
	
	return true;
}

/**
* Admin command to list all current session/game speedrecords.
*/
public Action:Command_ListTopSpeed(client, args)
{
	
	// Notify the client that the output is in the console
	CPrintToChat(client, "{red}[%t] {green}%t", "Speed meter", "Check console for all current speedrecords");
	
	// Get the current amount of records and print it
	new size = GetArraySize(g_hSessionSteamId);
	PrintToConsole(client, "%t: %d", "Amount of records", size);
	
	// Verify the array integrity and submit a log error if it's not stable
	if ((size != GetArraySize(g_hSessionName)) || (size != GetArraySize(g_hSessionMaxSpeedRound)) || (size != GetArraySize(g_hSessionMaxSpeedGame)))
	{
		LogError("%s: ERROR: array size is different from other arrays. Report to %s on %s", PLUGIN_NAME, PLUGIN_AUTHOR, PLUGIN_URL);
		return Plugin_Handled;
	}
	
	PrintToConsole(client, "%t:", "Listing speedrecords");
	
	// Temporary declarations
	decl String:steamid[MAX_STEAMAUTH_LENGTH];
	decl String:name[MAX_NAME_LENGTH];
	decl String:gamespeedTimeStamp[20];
	decl Float:gamespeed;
	decl Float:roundspeed;
	
	// Loop over all records
	for (new i=0; i<size; i++)
	{
		
		// Get all the values
		GetArrayString(g_hSessionSteamId, i, steamid, sizeof(steamid));
		GetArrayString(g_hSessionName, i, name, sizeof(name));
		GetArrayString(g_hSessionMaxSpeedGameTimeStamp, i, gamespeedTimeStamp, sizeof(gamespeedTimeStamp));
		gamespeed = GetArrayCell(g_hSessionMaxSpeedGame, i);
		roundspeed = GetArrayCell(g_hSessionMaxSpeedRound, i);
		
		// Print the values in console
		PrintToConsole(client, "%t: %.64s; %t: %.32s; %t: %.4f; %t: %.4f; %t %t: %.20s", "Player", name, "SteamID", steamid, "Game Speed", gamespeed, "Round Speed", roundspeed, "Game Speed", "Timestamp", gamespeedTimeStamp);
	}
	
	return Plugin_Handled;
}

/**
* Admin command to manage all current and past speedrecords.
*/
public Action:Command_TopspeedAdmin(client, args)
{
	
	// Show the topspeed admin menu
	ShowTopspeedAdmin(client);
	
	return Plugin_Handled;
}

/**
* A new round started, notice it and reset the round speeds.
*/
public OnRoundStart(Handle:event, const String:name[], bool:broadcast)
{
	
	// Remember that the round and the game/session started
	g_bRoundEnded = false;
	g_bGameEnded = false;
	
	// Reset the round speeds
	ResetRoundSpeeds();
}

/**
* The round ended, notice it for possibly displaying the records of the round or game/session.
*/
public OnRoundEnd(Handle:event, const String:name[], bool:broadcast)
{
	
	// Remember that the round ended
	g_bRoundEnded = true;
	
	// Get the timeleft
	new timeleft = 0;
	GetMapTimeLeft(timeleft);
	
	// Check if the game/session is over
	if (timeleft <= 0)
	{
		// Game ended
		// Remember that the game ended
		g_bGameEnded = true;
		
		// Possibly print highest records of current game/session
		if (g_bPlugin_ShowRoundTopspeeds)
		{
			ShowBestCurrentSession();
		}
	}
	else
	{
		// Possibly print highest records of current round
		if (g_bPlugin_ShowGameTopspeeds)
		{
			ShowBestRound();
		}
	}
}

/**
* Function to execute once the given interval has elapsed.
*/
public Action:Timer_Think(Handle:timer)
{
	
	// If the plugin is disabled then don't do anything
	if (g_iPlugin_Enable != 1)
	{
		return Plugin_Handled;
	}
	
	// If the round ended or the game ended then don't do anything
	if (g_bRoundEnded || g_bGameEnded)
	{
		return Plugin_Handled;
	}
	
	// If a vote is in progress then remember it, it may not show the speedmeter
	new bool:voteInProgress = false;
	if (IsVoteInProgress())
	{
		voteInProgress = true;
	}
	
	// Loop all clients and show the speed meter
	for (new client=1; client<=MaxClients; client++)
	{
		
		// Show the speed meter for the client
		ShowSpeedMeter(client, voteInProgress);
	}
	
	// Print the info text every given seconds (RoundToFloor is probably the fastest way for float to int) if wanted
	if (g_iPlugin_AmountOfSecondsInfoHelpPrintInterval > 0)
	{
		if (RoundToFloor(GetGameTime()) % g_iPlugin_AmountOfSecondsInfoHelpPrintInterval == 0)
		{
			// Check that it has not just been printed
			if (!g_bHelpJustPrinted)
			{
				g_bHelpJustPrinted = true;
				CPrintToChatAll("[SM] %t", "For more info about Speed meter, type !topspeedhelp in chat");
			}
		}
		else
		{
			// Reset
			g_bHelpJustPrinted = false;
		}
	}
	
	// Nothing more to do, plugin is handled
	return Plugin_Handled;
}

/**
* A player changed his name, update his name in the dynamic array.
*/
public Event_PlayerNameChange(Handle:event, const String:name[], bool:broadcast)
{
	
	// Temporary declarations
	decl client;
	decl String:oldName[MAX_NAME_LENGTH];
	decl String:newName[MAX_NAME_LENGTH];
	
	// Get the current client
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!Client_IsValid(client) || !IsClientInGame(client))
	{
		// Client is not valid or not in game, discard the name change
		return;
	}
	
	// Catch the new and old names
	GetEventString(event, "newname", newName, sizeof(newName));
	GetEventString(event, "oldname", oldName, sizeof(oldName));
	
	// Verify that they are not identical
	if (!StrEqual(oldName, newName, true))
	{
		// Find the steam id of the client
		decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
		GetClientAuthId(client, AuthId_Steam2, clientSteamId, sizeof(clientSteamId));
		
		// Find the client index inside the dynamic arrays
		new id = FindStringInArray(g_hSessionSteamId, clientSteamId);
		
		if (id != -1)
		{
			// Update the name id the client is found
			SetArrayString(g_hSessionName, id, newName);
		}
	}
}

/**
* Check for removed libraries.
*/
public OnLibraryRemoved(const String:name[])
{
	
	// Check if the adminmenu was removed, if so delete it
	if (StrEqual(name, "adminmenu"))
	{
		g_hTopMenu = INVALID_HANDLE;
	}
}
 
/**
* The admin menu is ready, add the plugin admin menu to it.
*/
public OnAdminMenuReady(Handle:aTopMenu)
{
	
	// Prevent double execution
	if (aTopMenu == g_hTopMenu)
	{
		return;
	}
	else
	{
		// Catch the menu
		g_hTopMenu = aTopMenu;
	}
	
	// Add a speed meter category and verify it
	new TopMenuObject:topspeed_commands = AddToTopMenu(g_hTopMenu, "exspeedmetercomm_cmds", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT);
	if(topspeed_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	// Add all commands to the admin menu (in the topspeed category)
	AddToTopMenu(g_hTopMenu, "sm_topspeedreset", TopMenuObject_Item, AdminMenu_ResetCurrent, topspeed_commands, "sm_topspeedreset", ADMFLAG_BAN);
	AddToTopMenu(g_hTopMenu, "sm_topspeedresetall", TopMenuObject_Item, AdminMenu_ResetAllCurrent, topspeed_commands, "sm_topspeedresetall", ADMFLAG_BAN);
	AddToTopMenu(g_hTopMenu, "sm_topspeeddelete", TopMenuObject_Item, AdminMenu_DeleteRecord, topspeed_commands, "sm_topspeeddelete", ADMFLAG_BAN);
	AddToTopMenu(g_hTopMenu, "sm_topspeeddeleteall", TopMenuObject_Item, AdminMenu_DeleteAllRecords, topspeed_commands, "sm_topspeeddeleteall", ADMFLAG_BAN);
	AddToTopMenu(g_hTopMenu, "sm_topspeeddeletedifferent", TopMenuObject_Item, AdminMenu_DeleteDifferentRecord, topspeed_commands, "sm_topspeeddeletedifferent", ADMFLAG_BAN);
	AddToTopMenu(g_hTopMenu, "sm_topspeeddeletedifferentall", TopMenuObject_Item, AdminMenu_DeleteAllDifferentRecords, topspeed_commands, "sm_topspeeddeletedifferentall", ADMFLAG_BAN);
}

/**
* Create a category handler for the created category which responds for the adminmenu plugin.
*/
public CategoryHandler(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "Speed meter Commands", param1);
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "%T:", "Speed meter Commands", param1);
	}
}

/*****************************************************************


P L U G I N   F U N C T I O N S


*****************************************************************/

/**
* Show the speed meter to the client.
*/
stock ShowSpeedMeter(player, bool:voteInProgress)
{
	
	// Verifiy client
	if (!Client_IsValid(player) || !IsClientInGame(player) || IsFakeClient(player))
	{
		return;
	}
	
	// Initialize client of which the speed is shown
	new client = -1;
	// Check if the client is spectating
	new Obs_Mode:observMode = Client_GetObserverMode(player);
	
	// Check the state of the current client
	if (g_bPlugin_ShowSpeedToSpecs && IsClientObserver(player) && (observMode == OBS_MODE_CHASE || observMode == OBS_MODE_IN_EYE))
	{
		// Client is spectating and the speed of the spectated client should be shown
		client = Client_GetObserverTarget(player);
		Client_PrintDebug(player, "#1 you are dead/spectator and specing: %N", client);
	}
	else if (IsPlayerAlive(player))
	{
		// Client is alive, not spectating
		client = player;
		Client_PrintDebug(player, "#2 you are alive");
	}
	else if (IsClientObserver(player))
	{
		// Client is spectating and the speed should not be seen
		Client_PrintDebug(player, "#3 you are dead/spectator and specing nobody or the setting of spectator viewing is off");
		return;
	}
	else
	{
		// Something went wrong, client is not alive and not spectating
		Client_PrintDebug(player, "#4 you are not spec and not alive?");
		return;
	}
	
	// Validate the client of which the speed should be shown
	if (!Client_IsValid(client))
	{
		Client_PrintDebug(player, "#4 your target %N isn't valid", client);
		return;
	}
	if (!IsClientInGame(client))
	{
		Client_PrintDebug(player, "#5 your target %N isn't in game", client);
		return;
	}
	if (!IsPlayerAlive(client))
	{
		Client_PrintDebug(player, "#6 your target %N isn't alive", client);
		return;
	}
	if (!IsClientAuthorized(client))
	{
		Client_PrintDebug(player, "#7 your target %N isn't authed", client);
		return;
	}
	
	// Get the current velocity of the client that is displayed
	new Float:clientVel[3];
	Entity_GetAbsVelocity(client, clientVel);
	
	// Get the fall speed of the velocity (for verification purposes)
	new Float:fallSpeed = clientVel[2];
	
	// Reset the fall speed and calculate the vector and therefore the current speed
	clientVel[2] = 0.0;
	new Float:speed = GetVectorLength(clientVel);
	
	// Get the client his steam id
	new String:clientSteamId[STEAMAUTH_LENGTH];
	GetClientAuthId(client, AuthId_Steam2, clientSteamId, sizeof(clientSteamId));
	
	// Find the client in the dynamic topspeed array
	new clientIndex = FindStringInArray(g_hSessionSteamId, clientSteamId);
	
	// Verify that the client is found in the dynamic array
	if (clientIndex == -1)
	{
		// Client is not found, insert the player as a new client
		LogError("The steam id of the client is not found in the dynamic array g_hSessionSteamId");
		clientIndex = InsertNewPlayer(client);
	}
	
	// If the topspeed is faster then his fastest of the round then update the topspeed
	if (GetArrayCell(g_hSessionMaxSpeedRound, clientIndex) < speed)
	{
		SetArrayCell(g_hSessionMaxSpeedRound, clientIndex, speed);
	}
	
	// If the topspeed is faster then his fastest of the game/session then update the topspeed
	if (GetArrayCell(g_hSessionMaxSpeedGame, clientIndex) < speed)
	{
		// Set array cell value at the end for easier topspeedmap verification purposes
		
		// Save the timestamp as well
		new String:timestamp[20];
		FormatTime(timestamp, sizeof(timestamp), "%Y/%m/%d %H:%M:%S", GetTime());
		SetArrayString(g_hSessionMaxSpeedGameTimeStamp, clientIndex, timestamp);
		
		// Check if the client has a previous record
		if (!GetArrayCell(g_hSessionNewRecord, clientIndex))
		{
			// The client has a previous record, check if it's a new speedrecord
			
			// Find the current record
			new recordIndex = FindStringInArray(g_hRecordSteamId, clientSteamId);
			if (recordIndex == -1)
			{
				// Something went wrong, define the client as a new client
				SetArrayCell(g_hSessionNewRecord, clientIndex, true);
			}
			else
			{
				// Check if the current highest speedrecord is faster then the previous
				if (GetArrayCell(g_hRecordMaxSpeed, recordIndex) < speed)
				{
					// New record! Mark that the client has a higher record
					SetArrayCell(g_hSessionHigherRecord, clientIndex, true);
					
					// Possibly display a message of a highest speedrecord
					if (g_bPlugin_ShowNewTopspeedMapMessage)
					{
						// Check if the client went faster then all speedrecords
						
						// Get the highest speedrecord and compare it (and check them rounded to the unit to prevent duplicate messages)
						if ((g_fHighestSpeedrecord * g_fUnitMess_Calc[g_iPlugin_Unit]) < (speed * g_fUnitMess_Calc[g_iPlugin_Unit]))
						{
							// New fastest world record! fetch the name and print it
							new String:clientName[MAX_NAME_LENGTH];
							GetArrayString(g_hSessionName, clientIndex, clientName, sizeof(clientName));
							CPrintToChatAll("{red}[%t] {green}%t! {red}%.1f %s {green}%s", "Speed meter", "New fastest speedrecord", (Float:speed * g_fUnitMess_Calc[g_iPlugin_Unit]), g_szUnitMess_Name[g_iPlugin_Unit], clientName);
							
							// Save the record
							g_fHighestSpeedrecord = speed;
						}
					}
				}
			}
		}
		else
		{
			// Clients that connect for the first time to the map will not get a shout out since it's spam when the map is loaded for the first time
		}
		
		// Set the new value
		SetArrayCell(g_hSessionMaxSpeedGame, clientIndex, speed);
	}
	
	// Make sure not to display the speedmeter when a vote is in progress or when it is set not to show
	if (!voteInProgress && g_bPlugin_ShowHUD)
	{
		// Display the current speed, first check for compatibility
		if (!g_bIsHL2DM)
		{
			// Not HL2MP
			// If the speed is 0 then check if the player is standing still
			if ((speed == 0.0) && (fallSpeed == 0.0))
			{
				// Check if the player is standing still
				if (!g_bClientSetZero[player])
				{
					// Player just stopped moving, display 0.0 as current speed once
					//PrintHintText(player, "%t\n%.1f %s", "Current speed", 0.0, g_szUnitMess_Name[g_iPlugin_Unit]);
					SetHudTextParams(-1.0, 0.70, g_fPlugin_DisplayTick, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(player, -1, "SPEED:");
					SetHudTextParams(-1.0, 0.70, g_fPlugin_DisplayTick, 0, 0, 255, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(player, -1, "\n%.1f", 0.0);
					
					// Stop the hint sound if wanted
					if (g_bPlugin_CheckSoundPrecache)
					{
						// Check if the hint sound is catched that attaches to this hint text
						if (IsSoundPrecached("UI/hint.wav"))
						{
							// The hint sound is attached, stop the sound to prevent this spam sound
							StopSound(player, SNDCHAN_STATIC, "UI/hint.wav");
						}
					}
					
					// Remember that the speed is set to 0.0 for this player, so next time it won't keep on displaying 0.0 speed
					g_bClientSetZero[player] = true;
				}
				return;
			}
			// Remember that this player is moving
			g_bClientSetZero[player] = false;
			
			// Display the speed
			//PrintHintText(player, "%t\n%.1f %s", "Current speed", speed * g_fUnitMess_Calc[g_iPlugin_Unit], g_szUnitMess_Name[g_iPlugin_Unit]);
			SetHudTextParams(-1.0, 0.70, 0.3, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(player, -1, "SPEED:");
			SetHudTextParams(-1.0, 0.70, g_fPlugin_DisplayTick, 0, 0, 255, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(player, -1, "\n%.1f", speed * g_fUnitMess_Calc[g_iPlugin_Unit]);
			
			// Stop the hint sound if wanted
			if (g_bPlugin_CheckSoundPrecache)
			{
				// Check if the hint sound is catched that attaches to this hint text
				if (IsSoundPrecached("UI/hint.wav"))
				{
					// The hint sound is attached, stop the sound to prevent this spam sound
					StopSound(player, SNDCHAN_STATIC, "UI/hint.wav");
				}
			}
		}
		else
		{
			// HL2MP, Display the speed
			SetHudTextParams(0.01, 1.0, g_fPlugin_DisplayTick, 255, 255, 255, 255, 0, 6.0, 0.01, 0.01);
			ShowHudText(player, -1, "%t %.1f %s", "Current speed", speed * g_fUnitMess_Calc[g_iPlugin_Unit], g_szUnitMess_Name[g_iPlugin_Unit]);
		}
	}
}

/**
* Display the admin panel to manage speedrecords.
*/
stock ShowTopspeedAdmin(client)
{
	
	// Temporary declarations
	decl String:menuItem[255];
	
	// Create a menu for the admin to control which records to administrate
	new Handle:menuHandle = CreateMenu(TopspeedAdminMenuCallBack);
	SetMenuTitle(menuHandle, " - %t - \n", "Speed meter Commands");
	
	// Add the options for the admin
	Format(menuItem, sizeof(menuItem), "%t", "Reset a current speedrecord");
	AddMenuItem(menuHandle, "ResetCurrent", menuItem);
	Format(menuItem, sizeof(menuItem), "%t", "Reset all current speedrecords");
	AddMenuItem(menuHandle, "ResetAll", menuItem);
	Format(menuItem, sizeof(menuItem), "%t", "Delete a saved speedrecord on the current map");
	AddMenuItem(menuHandle, "DeleteRecord", menuItem);
	Format(menuItem, sizeof(menuItem), "%t", "Delete all saved speedrecords on the current map");
	AddMenuItem(menuHandle, "DeleteAll", menuItem);
	Format(menuItem, sizeof(menuItem), "%t", "Delete a saved speedrecord on a different map");
	AddMenuItem(menuHandle, "DeleteDifferent", menuItem);
	Format(menuItem, sizeof(menuItem), "%t", "Delete all saved speedrecords on a different map");
	AddMenuItem(menuHandle, "DeleteDifferentAll", menuItem);
	
	// Display the created menu
	DisplayMenu(menuHandle, client, MENU_TIME_FOREVER);
}

/**
* Display the speedrecords of the current round.
*/
stock ShowBestRound()
{
	
	// Sort all records according to their best topspeed in the current round
	SortBestRound();
	
	// Get the amount of records
	new size = GetArraySize(g_hSessionName);
	
	// Temporary declarations
	decl String:clientName[MAX_NAME_LENGTH];
	decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
	decl Float:topspeed;
	decl String:currentClientSteamId[MAX_STEAMAUTH_LENGTH];
	
	// Print the main line in all chat, other lines are in client chat to be able to make them red
	CPrintToChatAll("{red}[%t] {green}%t:", "Speed meter", "Current speedrecords on this round");
	
	// Loop over all records
	for (new i=0; i<size; i++)
	{
		
		// Catch all data of that record
		GetArrayString(g_hSessionName, i, clientName, sizeof(clientName));
		GetArrayString(g_hSessionSteamId, i, clientSteamId, sizeof(clientSteamId));
		topspeed = Float:GetArrayCell(g_hSessionMaxSpeedRound, i) * g_fUnitMess_Calc[g_iPlugin_Unit];
		
		// Only show zero values if it is set to do so
		if (topspeed > 0 || g_bPlugin_ShowZeroTopspeeds)
		{
			// Loop over all clients to print the speedrecord in their chat
			for (new client=1; client<=MaxClients; client++)
			{
				
				// Verifiy that the client is in game
				if (IsClientInGame(client))
				{
					// Get the current client steam id that is being looped
					GetClientAuthId(client, AuthId_Steam2, currentClientSteamId, sizeof(currentClientSteamId));
					
					// If the steam id of the speedrecord is the same as the current looped steam id, then print the record in red
					if (StrEqual(clientSteamId, currentClientSteamId, false))
					{
						// Print the record of the client in the chat
						CPrintToChat(client, "{green}%d{red}. %s ({green}%.1f %s{red})", i + 1, clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
					}
					else if (i < g_iPlugin_AmountOfPrintedRecords)
					{
						// Print the speedrecords in green in the chat for other clients
						CPrintToChat(client, "{green}%d{red}. {green}%s (%.1f %s)", i + 1, clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
					}
				}
			}
		}
	}
}

/**
* Display the speedrecords of the current game/session.
*/
stock ShowBestCurrentSession()
{
	
	// Sort all records according to their best speedrecord in the current game/session
	SortBestGame();
	
	// Get the amount of records
	new size = GetArraySize(g_hSessionName);
	
	// Temporary declarations
	decl String:clientName[MAX_NAME_LENGTH];
	decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
	decl Float:topspeed;
	decl String:currentClientSteamId[MAX_STEAMAUTH_LENGTH];
	
	// Print the main line in all chat, other lines are in client chat to be able to make them red
	CPrintToChatAll("{red}[%t] {green}%t:", "Speed meter", "Current speedrecords on this map");
	
	// Loop over all records
	for (new i=0; i<size; i++)
	{
		
		// Catch all data of that record
		GetArrayString(g_hSessionName, i, clientName, sizeof(clientName));
		GetArrayString(g_hSessionSteamId, i, clientSteamId, sizeof(clientSteamId));
		topspeed = Float:GetArrayCell(g_hSessionMaxSpeedGame, i) * g_fUnitMess_Calc[g_iPlugin_Unit];
		
		// Only show zero values if it is set to do so
		if (topspeed > 0 || g_bPlugin_ShowZeroTopspeeds)
		{
			// Loop over all clients to print the speedrecord in their chat
			for (new client=1; client<=MaxClients; client++)
			{
				
				// Verifiy that the client is in game
				if (IsClientInGame(client))
				{
					// Get the current client steam id that is being looped
					GetClientAuthId(client, AuthId_Steam2, currentClientSteamId, sizeof(currentClientSteamId));
					
					// If the steam id of the speedrecord is the same as the current looped steam id, then print the record in red
					if (StrEqual(clientSteamId, currentClientSteamId, false))
					{
						// Print the record of the client in the chat
						CPrintToChat(client, "{green}%d{red}. %s ({green}%.1f %s{red})", i + 1, clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
					}
					else if (i < g_iPlugin_AmountOfPrintedRecords)
					{
						// Print the speedrecords in green in the chat for other clients
						CPrintToChat(client, "{green}%d{red}. {green}%s (%.1f %s)", i + 1, clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
					}
				}
			}
		}
	}
}

/**
* Display the speedrecords of all time on this map, and show a menu to the current client to browse through all records.
*/
stock ShowBestAllTime(clientCurrent, bool:printInChat = true)
{
	
	// Combine and sort all speedrecords ever according to their highest speedrecord on this map
	CombineAllMapRecords();
	SortAllMapRecords();
	
	// Get the amount of records
	new size = GetArraySize(g_hAllName);
	
	// Temporary declarations
	decl String:recordString[50];
	decl String:clientName[MAX_NAME_LENGTH];
	decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
	decl Float:topspeed;
	decl String:currentClientSteamId[MAX_STEAMAUTH_LENGTH];
	
	// Create the menu in which all records are visible if wanted, menu handle has to be created though
	new Handle:menuHandle = CreateMenu(TopspeedMapMenuCallBack);
	if (g_bPlugin_ShowTopspeedMapMenu)
	{
		SetMenuTitle(menuHandle, " - %t - \n", "Highest speedrecords on this map (colorless)");
	}
	
	// Print the main line in all chat, other lines are in client chat to be able to make them red
	if (printInChat)
	{
		CPrintToChatAll("{red}[%t] {green}%t:", "Speed meter", "Highest speedrecords on this map");
	}
	
	// Loop over all records
	for (new i=0; i<size; i++)
	{
		
		// Catch all data of that record
		GetArrayString(g_hAllName, i, clientName, sizeof(clientName));
		GetArrayString(g_hAllSteamId, i, clientSteamId, sizeof(clientSteamId));
		topspeed = Float:GetArrayCell(g_hAllMaxSpeed, i) * g_fUnitMess_Calc[g_iPlugin_Unit];
		
		// Only show zero values if it is set to do so
		if (topspeed > 0 || g_bPlugin_ShowZeroTopspeeds)
		{
			// Add the speedrecord to the menu if wanted
			if (g_bPlugin_ShowTopspeedMapMenu)
			{
				// Only show to the given limit
				if (i < g_iPlugin_AmountOfTopspeedMap || g_iPlugin_AmountOfTopspeedMap <= 0)
				{
					Format(recordString, 50, "%s (%.1f %s)", clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
					AddMenuItem(menuHandle, clientSteamId, recordString);
				}
			}
			
			// Loop over all clients to print the speedrecord in their chat
			if (printInChat)
			{
				for (new client=1; client<=MaxClients; client++)
				{
					
					// Verifiy that the client is in game
					if (IsClientInGame(client))
					{
						// Get the current client steam id that is being looped
						GetClientAuthId(client, AuthId_Steam2, currentClientSteamId, sizeof(currentClientSteamId));
						
						// If the steam id of the speedrecord is the same as the current looped steam id, then print the record in red
						if (StrEqual(clientSteamId, currentClientSteamId, false))
						{
							// Print the record of the client in the chat
							CPrintToChat(client, "{green}%d{red}. %s ({green}%.1f %s{red})", i + 1, clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
						}
						else if (i < g_iPlugin_AmountOfPrintedRecords)
						{
							// Print the speedrecords in green in the chat for other clients
							CPrintToChat(client, "{green}%d{red}. {green}%s (%.1f %s)", i + 1, clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
						}
					}
				}
			}
		}
	}
	
	// Display the menu to the client if wanted
	if (g_bPlugin_ShowTopspeedMapMenu)
	{
		DisplayMenu(menuHandle, clientCurrent, MENU_TIME_FOREVER);
	}
}

/**
* Display the highest speedrecords ever, and show a menu to the current client to browse through all records.
*/
stock ShowHighestOverall(clientCurrent, bool:printInChat = true)
{
	
	// Get the highest overall speedrecords (database function)
	GetHighestOverallTopspeedRecords(clientCurrent, printInChat);
}

/**
* Display the highest speedrecords ever, and show a menu to the current client to browse through all records.
*/
stock ShowHighestOverallMain(clientCurrent, bool:printInChat = true)
{
	
	// Temporary declarations
	decl String:recordString[50];
	decl String:clientName[MAX_NAME_LENGTH];
	decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
	decl Float:topspeed;
	decl String:currentClientSteamId[MAX_STEAMAUTH_LENGTH];
	
	// Display the records
	
	// They are already combined and sorted
	
	// Get the amount of records (filter out the extra records)
	new size = GetArraySize(g_hHighestOverallName);
	if (size > g_iPlugin_AmountOfTopspeedTop)
	{
		size = g_iPlugin_AmountOfTopspeedTop;
	}
	
	// Create the menu in which all records are visible if wanted, menu handle has to be created though
	new Handle:menuHandle = CreateMenu(TopspeedTopMenuCallBack);
	if (g_bPlugin_ShowTopspeedTopMenu)
	{
		SetMenuTitle(menuHandle, " - %t - \n", "Highest speedrecords on all maps (colorless)");
	}
	
	// Print the main line in all chat, other lines are in client chat to be able to make them red
	if (printInChat)
	{
		CPrintToChatAll("{red}[%t] {green}%t:", "Speed meter", "Highest speedrecords on all maps");
	}
	
	// Loop over all records
	for (new i=0; i<size; i++)
	{
		
		// Catch all data of that record
		GetArrayString(g_hHighestOverallName, i, clientName, sizeof(clientName));
		GetArrayString(g_hHighestOverallSteamId, i, clientSteamId, sizeof(clientSteamId));
		topspeed = Float:GetArrayCell(g_hHighestOverallMaxSpeed, i) * g_fUnitMess_Calc[g_iPlugin_Unit];
		
		// Only show zero values if it is set to do so
		if (topspeed > 0 || g_bPlugin_ShowZeroTopspeeds)
		{
			// Add the speedrecord to the menu if wanted
			if (g_bPlugin_ShowTopspeedMapMenu)
			{
				// Only show to the given limit
				if (i < g_iPlugin_AmountOfTopspeedTop || g_iPlugin_AmountOfTopspeedTop <= 0)
				{
					Format(recordString, 50, "%s (%.1f %s)", clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
					AddMenuItem(menuHandle, clientSteamId, recordString); // The value will not be used since a record is unique by steam id and map name
				}
			}
			
			// Loop over all clients to print the speedrecords in their chat
			if (printInChat)
			{
				for (new client=1; client<=MaxClients; client++)
				{
					
					// Verifiy that the client is in game
					if (IsClientInGame(client))
					{
						// Get the current client steam id that is being looped
						GetClientAuthId(client, AuthId_Steam2, currentClientSteamId, sizeof(currentClientSteamId));
						
						// If the steam id of the speedrecord is the same as the current looped steam id, then print the record in red
						if (StrEqual(clientSteamId, currentClientSteamId, false))
						{
							// Print the record of the client in the chat
							CPrintToChat(client, "{green}%d{red}. %s ({green}%.1f %s{red})", i + 1, clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
						}
						else if (i < g_iPlugin_AmountOfPrintedRecords)
						{
							// Print the speedrecords in green in the chat for other clients
							CPrintToChat(client, "{green}%d{red}. {green}%s (%.1f %s)", i + 1, clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
						}
					}
				}
			}
		}
	}
	
	// Set the paging and display the menu to the client if wanted
	if (g_bPlugin_ShowTopspeedTopMenu)
	{
		SetMenuPagination(menuHandle, 5);
		DisplayMenu(menuHandle, clientCurrent, MENU_TIME_FOREVER);
	}
}

/**
* Show a menu to the current client to browse through all his personal records.
*/
stock ShowPersonal(clientCurrent)
{
	
	// First get the different map list
	
	// Temporary declaration
	decl String:sQuery[448];
	
	// Create the SQL get query to retreive all maps
	FormatEx(sQuery, sizeof(sQuery), "SELECT DISTINCT map FROM topspeed WHERE map != '%s' ORDER BY map", g_sCurrentMap);
	
	// Activate the query
	SQL_TQuery(g_hSQL, ShowPersonalDifferentMapListCallback, sQuery, clientCurrent);
}

/**
* Callback function for the personal records map list.
*/
public ShowPersonalDifferentMapListCallback(Handle:owner, Handle:hQueryDifferentMapList, const String:sError[], any:clientCurrent)
{
	if (hQueryDifferentMapList == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: SQL error on getting personal records maplist: %s", PLUGIN_NAME, sError);
		return;
	}
	else
	{
		// Temporary declarations
		decl String:mapName[MAX_MAPNAME_LENGTH];
		decl String:sQuery[448];
		decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
		
		// Reset the maplist
		ClearArray(g_hDifferentMapList);
		
		// Get the records if there are any
		if (SQL_GetRowCount(hQueryDifferentMapList) > 0)
		{
			// Fetch Data per Row
			while (SQL_FetchRow(hQueryDifferentMapList))
			{
				// Fetch the values
				SQL_FetchString(hQueryDifferentMapList, 0, mapName, sizeof(mapName));
				
				// Save it locally
				PushArrayString(g_hDifferentMapList, mapName);
			}
		}
		
		// Get the client his steamid
		GetClientAuthId(clientCurrent, AuthId_Steam2, clientSteamId, sizeof(clientSteamId));
		
		// Create the SQL get query to retreive all records of the player without the current map
		FormatEx(sQuery, sizeof(sQuery), "SELECT DISTINCT a.map, (SELECT COUNT(b.speed) FROM topspeed AS b WHERE b.map = a.map AND b.speed >= personal.speed) AS rank, COUNT(a.speed) AS total, personal.speed FROM topspeed AS a JOIN topspeed AS personal ON a.map = personal.map WHERE a.map != '%s' AND personal.auth = '%s' GROUP BY a.map ORDER BY a.map;", g_sCurrentMap, clientSteamId);
		
		// Activate the query
		SQL_TQuery(g_hSQL, ShowPersonalMainCallback, sQuery, clientCurrent);
	}
}

/**
* Callback function for the personal map records.
*/
public ShowPersonalMainCallback(Handle:owner, Handle:hQuery, const String:sError[], any:clientCurrent)
{
	if (hQuery == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: SQL error on getting personal records: %s", PLUGIN_NAME, sError);
		return;
	}
	else
	{
		// Temporary declarations
		decl String:recordString[50];
		decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
		decl String:currentMapRecordSteamId[MAX_STEAMAUTH_LENGTH];
		decl String:mapName[MAX_MAPNAME_LENGTH];
		decl Float:topspeed;
		decl Float:currentMapTopspeed;
		new rank = 0;
		new totalAmount = 0;
		new currentMapRank = -1;
		new currentMapTotalAmount = 0;
		new currentMapAmountZero = 0;
		new mapIndex = -1;
		
		// Create and display a loading menu
		new Handle:menuHandle = CreateMenu(TopspeedPersonalMenuCallBack);
		SetMenuTitle(menuHandle, " - %t - \n", "Personal speedrecords");
		
		// Get the client his steamid
		GetClientAuthId(clientCurrent, AuthId_Steam2, clientSteamId, sizeof(clientSteamId));
		
		// Add the rank of the current map
		
		// Combine and sort all speedrecords ever according to their best speedrecord on this map
		CombineAllMapRecords();
		SortAllMapRecords();
		
		// Get the amount of records
		currentMapTotalAmount = GetArraySize(g_hAllName);
		
		// Loop partially over all records of the current map
		for (new i=0; i<currentMapTotalAmount; i++)
		{
			
			// Get the topspeed
			topspeed = Float:GetArrayCell(g_hAllMaxSpeed, i);
			
			// Only show zero values if it is set to do so
			if (topspeed > 0 || g_bPlugin_ShowZeroTopspeeds)
			{
				// Get the current record its steam id
				GetArrayString(g_hAllSteamId, i, currentMapRecordSteamId, sizeof(currentMapRecordSteamId));
				
				// Check if the steam id is the same
				if (StrEqual(clientSteamId, currentMapRecordSteamId, false))
				{
					// The same steam id, this is the client its record, save the rank
					currentMapRank = i + 1;
					break;
				}
			}
			else
			{
				currentMapAmountZero++;
			}
		}
		
		// Loop over all records of the current map to find zero values
		if (!g_bPlugin_ShowZeroTopspeeds)
		{
			for (new i=0; i<currentMapTotalAmount; i++)
			{
				
				// Get the topspeed
				topspeed = Float:GetArrayCell(g_hAllMaxSpeed, i);
				
				// Only show zero values if it is set to do so
				if (topspeed <= 0)
				{
					// One more zero
					currentMapAmountZero++;
				}
			}
		}
		
		// Verify a record was found
		if (currentMapRank > - 1)
		{
			// Get the current topspeed
			currentMapTopspeed = Float:GetArrayCell(g_hAllMaxSpeed, currentMapRank - 1);
			
			// Add the rank to the menu
			Format(recordString, 50, "%s: #%d/%d (%.1f %s)", g_sCurrentMap, currentMapRank, currentMapTotalAmount - currentMapAmountZero, currentMapTopspeed * g_fUnitMess_Calc[g_iPlugin_Unit], g_szUnitMess_Name[g_iPlugin_Unit]);
			AddMenuItem(menuHandle, g_sCurrentMap, recordString);
		}
		else
		{
			// Add an empty rank to the menu
			Format(recordString, 50, "%s: %t", g_sCurrentMap, "No speedrecord found");
			AddMenuItem(menuHandle, g_sCurrentMap, recordString);
		}
		
		// Get a list of all different maps
		new Handle:mapsWithoutRecord = g_hDifferentMapList;
		
		// Get the records if there are any
		if (SQL_GetRowCount(hQuery) > 0)
		{
			// Fetch Data per Row
			while (SQL_FetchRow(hQuery))
			{
				// Fetch the values
				SQL_FetchString(hQuery, 0, mapName, sizeof(mapName));
				rank = SQL_FetchInt(hQuery, 1);
				totalAmount = SQL_FetchInt(hQuery, 2);
				topspeed = Float:SQL_FetchFloat(hQuery, 3);
				
				// Add the rank straight to the menu
				Format(recordString, 50, "%s: #%d/%d (%.1f %s)", mapName, rank, totalAmount, topspeed * g_fUnitMess_Calc[g_iPlugin_Unit], g_szUnitMess_Name[g_iPlugin_Unit]);
				AddMenuItem(menuHandle, mapName, recordString);
				
				// Delete the map from the maps without a record
				mapIndex = FindStringInArray(mapsWithoutRecord, mapName);
				RemoveFromArray(mapsWithoutRecord, mapIndex);
			}
		}
		
		// Add all remaining maps without a record
		
		// Get the amount
		new mapsWithoutRecordSize = GetArraySize(mapsWithoutRecord);
		
		// Loop over all the maps without a record
		// Loop all current records
		for (new i=0; i<mapsWithoutRecordSize; i++)
		{
			
			// Get the map
			GetArrayString(mapsWithoutRecord, i, mapName, sizeof(mapName));
			
			// Add the map to the menu
			Format(recordString, 50, "%s: %t", mapName, "No speedrecord found");
			AddMenuItem(menuHandle, mapName, recordString);
		}
		
		// Display the menu to the client
		DisplayMenu(menuHandle, clientCurrent, MENU_TIME_FOREVER);
	}
}

/**
* Combine all current records with previous records of the map to get all records ever.
*/
stock CombineAllMapRecords()
{
	
	// Empty current list
	ClearArray(g_hAllSteamId);
	ClearArray(g_hAllName);
	ClearArray(g_hAllMaxSpeed);
	ClearArray(g_hAllMaxSpeedTimeStamp);
	
	// Get the amounts of current records and previous records
	new sessionSize = GetArraySize(g_hSessionName);
	new recordSize = GetArraySize(g_hRecordName);
	
	// Temporary declarations
	decl String:clientName[MAX_NAME_LENGTH];
	decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
	decl String:clientSpeedTimeStamp[20];
	decl Float:clientSpeed;
	new Handle:g_hHigherRecord = CreateArray(MAX_STEAMAUTH_LENGTH);
	
	// Loop all current records
	for (new i=0; i<sessionSize; i++)
	{
		
		// Check the record status of the current client
		if (GetArrayCell(g_hSessionNewRecord, i) || GetArrayCell(g_hSessionHigherRecord, i))
		{
			// New record or higher record, add it
			// Catch all data of that record
			GetArrayString(g_hSessionName, i, clientName, sizeof(clientName));
			GetArrayString(g_hSessionSteamId, i, clientSteamId, sizeof(clientSteamId));
			GetArrayString(g_hSessionMaxSpeedGameTimeStamp, i, clientSpeedTimeStamp, sizeof(clientSpeedTimeStamp));
			clientSpeed = Float:GetArrayCell(g_hSessionMaxSpeedGame, i);
			
			// Add the record to the collection of all records
			PushArrayString(g_hAllSteamId, clientSteamId);
			PushArrayString(g_hAllName, clientName);
			PushArrayString(g_hAllMaxSpeedTimeStamp, clientSpeedTimeStamp);
			PushArrayCell(g_hAllMaxSpeed, clientSpeed);
			
			// Remember if it's higher, so it isn't added
			if (GetArrayCell(g_hSessionHigherRecord, i))
			{
				// Add it to the temporary array
				PushArrayString(g_hHigherRecord, clientSteamId);
			}
		}
		else
		{
			// Client already had a higher record
		}
	}
	
	// Loop over all previous records, all records that were lower are already removed from the record array
	for (new i=0; i<recordSize; i++)
	{
		
		// Catch all data of that record
		GetArrayString(g_hRecordName, i, clientName, sizeof(clientName));
		GetArrayString(g_hRecordSteamId, i, clientSteamId, sizeof(clientSteamId));
		GetArrayString(g_hRecordMaxSpeedTimeStamp, i, clientSpeedTimeStamp, sizeof(clientSpeedTimeStamp));
		clientSpeed = Float:GetArrayCell(g_hRecordMaxSpeed, i);
		
		// Check if the given client currently has a higher record
		new clientHasHigherRecord = FindStringInArray(g_hHigherRecord, clientSteamId);
		if (clientHasHigherRecord == -1)
		{
			// The client is not found among the clients that have higher records
			
			// Add the record to the collection of all records
			PushArrayString(g_hAllSteamId, clientSteamId);
			PushArrayString(g_hAllName, clientName);
			PushArrayString(g_hAllMaxSpeedTimeStamp, clientSpeedTimeStamp);
			PushArrayCell(g_hAllMaxSpeed, clientSpeed);
		}
	}
}

/**
* Sort all speedrecords of the current round.
*/
stock SortBestRound()
{
	
	// Get the amount of current records
	new size = GetArraySize(g_hSessionName);
	
	// Loop over all records
	new i, j;
	for (i=0; i<size; i++) {
		// Now loop over all other records and compare them to the current record
		for (j=i; j<size; j++) {
			// Compare both records
			if (GetArrayCell(g_hSessionMaxSpeedRound, i) < GetArrayCell(g_hSessionMaxSpeedRound, j))
			{
				// The record is higher, swap the place (swap all dynamic arrays)
				SwapArrayItems(g_hSessionSteamId, i, j);
				SwapArrayItems(g_hSessionName, i, j);
				SwapArrayItems(g_hSessionMaxSpeedRound, i, j);
				SwapArrayItems(g_hSessionMaxSpeedGame, i, j);
				SwapArrayItems(g_hSessionMaxSpeedGameTimeStamp, i, j);
				
				SwapArrayItems(g_hSessionHigherRecord, i, j);
				SwapArrayItems(g_hSessionNewRecord, i, j);
			} 
		} 
	}
}

/**
* Sort all speedrecords of the current game/session.
*/
stock SortBestGame()
{
	
	// Get the amount of current records
	new size = GetArraySize(g_hSessionName);
	
	// Loop over all records
	new i, j;
	for (i=0; i<size; i++) {
		// Now loop over all other records and compare them to the current record
		for (j=i; j<size; j++) {
			// Compare both records
			if (GetArrayCell(g_hSessionMaxSpeedGame, i) < GetArrayCell(g_hSessionMaxSpeedGame, j))
			{
				// The record is higher, swap the place (swap all dynamic arrays)
				SwapArrayItems(g_hSessionSteamId, i, j);
				SwapArrayItems(g_hSessionName, i, j);
				SwapArrayItems(g_hSessionMaxSpeedRound, i, j);
				SwapArrayItems(g_hSessionMaxSpeedGame, i, j);
				SwapArrayItems(g_hSessionMaxSpeedGameTimeStamp, i, j);
				
				SwapArrayItems(g_hSessionHigherRecord, i, j);
				SwapArrayItems(g_hSessionNewRecord, i, j);
			} 
		} 
	}
}

/**
* Sort all speedrecords of the current map.
*/
stock SortAllMapRecords()
{
	
	// Get the amount of all records
	new size = GetArraySize(g_hAllName);
	
	// Loop over all records
	new i, j;
	for (i=0; i<size; i++) {
		// Now loop over all other records and compare them to the current record
		for (j=i; j<size; j++) {
			// Compare both records
			if (GetArrayCell(g_hAllMaxSpeed, i) < GetArrayCell(g_hAllMaxSpeed, j))
			{
				// The record is higher, swap the place (swap the dynamic arrays of all records)
				SwapArrayItems(g_hAllSteamId, i, j);
				SwapArrayItems(g_hAllName, i, j);
				SwapArrayItems(g_hAllMaxSpeedTimeStamp, i, j);
				SwapArrayItems(g_hAllMaxSpeed, i, j);
			} 
		} 
	}
}

/**
* Sort the best ever speedrecords.
*/
stock SortHighestOverallRecords()
{
	
	// Get the amount of all records
	new size = GetArraySize(g_hHighestOverallName);
	
	// Loop over all records
	new i, j;
	for (i=0; i<size; i++) {
		// Now loop over all other records and compare them to the current record
		for (j=i; j<size; j++) {
			// Compare both records
			if (GetArrayCell(g_hHighestOverallMaxSpeed, i) < GetArrayCell(g_hHighestOverallMaxSpeed, j))
			{
				// The record is higher, swap the place (swap the dynamic arrays of all records)
				SwapArrayItems(g_hHighestOverallSteamId, i, j);
				SwapArrayItems(g_hHighestOverallName, i, j);
				SwapArrayItems(g_hHighestOverallMaxSpeedTimeStamp, i, j);
				SwapArrayItems(g_hHighestOverallMaxSpeed, i, j);
				SwapArrayItems(g_hHighestOverallMapName, i, j);
			}
		}
	}
}

/**
* Display help in a menu to the current client to view the commands of the plugin and get information about them.
*/
stock ShowHelp(clientCurrent)
{
	
	// Temporary variable
	decl String:menuItem[255];
	
	// Create the menu
	new Handle:menuHandle = CreateMenu(TopspeedHelpMenuCallBack);
	SetMenuTitle(menuHandle, " - %t - \n", "Speed meter help");
	
	// Add the help items
	Format(menuItem, sizeof(menuItem), "!topspeed - %t", "View all speedrecords of the current players on the current map");
	AddMenuItem(menuHandle, "topspeed", menuItem);
	Format(menuItem, sizeof(menuItem), "!topspeedmap - %t", "View the highest speedrecords of all players on the current map");
	AddMenuItem(menuHandle, "topspeedmap", menuItem);
	Format(menuItem, sizeof(menuItem), "!topspeedtop - %t", "View the highest speedrecords of all players on all maps");
	AddMenuItem(menuHandle, "topspeedtop", menuItem);
	Format(menuItem, sizeof(menuItem), "!topspeedpr - %t", "View your highest speedrecords and rankings on all maps");
	AddMenuItem(menuHandle, "topspeedpr", menuItem);
	
	// Display the menu
	DisplayMenu(menuHandle, clientCurrent, MENU_TIME_FOREVER);
}

/**
* Reset all topspeeds for the round.
*/
stock ResetRoundSpeeds()
{
	
	// Loop over all clients of this game/session
	new size = GetArraySize(g_hSessionMaxSpeedRound);
	for (new i=0; i<size; i++)
	{
		
		// Reset the values to 0.0 for the next round
		SetArrayCell(g_hSessionMaxSpeedRound, i, 0.0);
	}
}

/**
* Function to intialize all legit clients in the begin.
*/
ClientAll_Initialize()
{
	
	// Loop over all clients and itialize legit ones
	for (new client=1; client<=MaxClients; client++)
	{
		
		// Don't initialize unauthorized, sourcetv clients, replay clients and not in game clients
		if (!IsClientInGame(client) || !IsClientAuthorized(client) || IsClientSourceTV(client) || IsClientReplay(client))
		{
			continue;
		}
		
		Client_Initialize(client);
	}
}

/**
* Function to intialize all data for a new client.
*/
Client_Initialize(client)
{
	
	// Initialize Variables
	g_bClientSetZero[client] = false;
	
	// Functions
	InsertNewPlayer(client);
}

/**
* New player insertion, add the player to the dynamic arrays.
*/
stock InsertNewPlayer(client)
{
	
	// Temporary declarations
	new String:clientSteamId[MAX_STEAMAUTH_LENGTH];
	GetClientAuthId(client, AuthId_Steam2, clientSteamId, sizeof(clientSteamId));
	new String:clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	
	// Make sure the client has a valid steam id
	if (clientSteamId[0] && !StrEqual(clientSteamId, "BOT"))
	{
		// Check if the client already exists
		new id = FindStringInArray(g_hSessionSteamId, clientSteamId);
		if (id == -1)
		{
			// New client, add the steam id, name to the dynamic arrays and initialise the speeds
			PushArrayString(g_hSessionSteamId, clientSteamId);
			PushArrayString(g_hSessionName, clientName);
			PushArrayCell(g_hSessionMaxSpeedRound, 0.0);
			PushArrayCell(g_hSessionMaxSpeedGame, 0.0);
			PushArrayCell(g_hSessionHigherRecord, false);
			
			// Save the timestamp as well
			new String:timestamp[20];
			FormatTime(timestamp, sizeof(timestamp), "%Y/%m/%d %H:%M:%S", GetTime());
			PushArrayString(g_hSessionMaxSpeedGameTimeStamp, timestamp);
			
			// Check if the steam id is stored in the database
			new recordId = FindStringInArray(g_hRecordSteamId, clientSteamId);
			
			if (recordId == -1)
			{
				// New steam id!
				PushArrayCell(g_hSessionNewRecord, true);
				
				// Easy debug
				// PrintToServer("############# NEW STEAM ID CONNECTED #############");
			}
			else
			{
				// Steam id was found in the database
				PushArrayCell(g_hSessionNewRecord, false);
				
				// Easy debug
				// PrintToServer("############# STEAM ID IS FOUND IN THE DATABASE RECORDS #############");
			}
		}
		else
		{
			// Client already existed, update the name
			// Easy debug
			// PrintToServer("############# CLIENT ALREADY EXISTED %s #############", clientName);
			SetArrayString(g_hSessionName, id, clientName);
		}
		
		// Make sure the client is now in the dynamix arrays
		id = FindStringInArray(g_hSessionSteamId, clientSteamId);
		
		if (id == -1)
		{
			// Still haven't found the id in the dynamic arrays
			LogError("%s: Still can't find the steam id in the g_hSessionSteamId dynamic array.", PLUGIN_NAME);
		}
		
		return id;
	}
	else
	{
		// Easy debug
		// PrintToServer("############# NOT A VALID PLAYER %s #############", clientName);
		return -1;
	}
}

/*****************************************************************


M E N U   C A L L B A C K   F U N C T I O N S


*****************************************************************/

/**
* Callback function for the topspeedmap menu, this reacts to what the client does inside the menu.
*/
public TopspeedMapMenuCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, the steam id of a player that did a record
		decl String:choice[MAX_STEAMAUTH_LENGTH];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Find the chosen record
		new recordIndex = FindStringInArray(g_hAllSteamId, choice);
		if (recordIndex == -1)
		{
			// Something went wrong, close the menu
			CloseHandle(menuhandle);
		}
		else
		{
			// Temporary declarations
			decl String:clientName[MAX_NAME_LENGTH];
			decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
			decl String:topspeedTimeStamp[20];
			decl Float:topspeed;
			decl String:menuItem[255];
			
			// Get all data of that record
			GetArrayString(g_hAllName, recordIndex, clientName, sizeof(clientName));
			GetArrayString(g_hAllSteamId, recordIndex, clientSteamId, sizeof(clientSteamId));
			GetArrayString(g_hAllMaxSpeedTimeStamp, recordIndex, topspeedTimeStamp, sizeof(topspeedTimeStamp));
			topspeed = Float:GetArrayCell(g_hAllMaxSpeed, recordIndex);
			
			// Create the submenu in which all details of the record are visible (\n is for an enter)
			new Handle:menuHandle = CreateMenu(TopspeedMapSubMenuCallBack);
			SetMenuTitle(menuHandle, " - %t - \n%t: %s\n%t: %s\n%t: %.1f %s\n%t: %s\n", "Speedrecord", "Map", g_sCurrentMap, "Player", clientName, "Speed", topspeed * g_fUnitMess_Calc[g_iPlugin_Unit], g_szUnitMess_Name[g_iPlugin_Unit], "Timestamp", topspeedTimeStamp);
			
			// Add the back button
			Format(menuItem, sizeof(menuItem), "%t", "Back");
			AddMenuItem(menuHandle, "Back", menuItem);
			
			// Display the menu
			DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedmap submenu, only back and exit buttons are present in the submenu.
*/
public TopspeedMapSubMenuCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Back
		ShowBestAllTime(Client, false);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedtop menu, this reacts to what the client does inside the menu.
*/
public TopspeedTopMenuCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Select action found, the client clicked on a topspeedmap record
		// Temporary declarations
		decl String:clientName[MAX_NAME_LENGTH];
		decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
		decl String:topspeedTimeStamp[20];
		decl Float:topspeed;
		decl String:mapName[MAX_MAPNAME_LENGTH];
		decl String:menuItem[255];
		
		// Get all data of that record
		GetArrayString(g_hHighestOverallName, Position, clientName, sizeof(clientName));
		GetArrayString(g_hHighestOverallSteamId, Position, clientSteamId, sizeof(clientSteamId));
		GetArrayString(g_hHighestOverallMaxSpeedTimeStamp, Position, topspeedTimeStamp, sizeof(topspeedTimeStamp));
		GetArrayString(g_hHighestOverallMapName, Position, mapName, sizeof(mapName));
		topspeed = Float:GetArrayCell(g_hHighestOverallMaxSpeed, Position);
		
		// Create the submenu in which all details of the record are visible (\n is for an enter)
		new Handle:menuHandle = CreateMenu(TopspeedTopSubMenuCallBack);
		SetMenuTitle(menuHandle, " - %t - \n%t: %s\n%t: %s\n%t: %.1f %s\n%t: %s\n", "Speedrecord", "Map", mapName, "Player", clientName, "Speed", topspeed * g_fUnitMess_Calc[g_iPlugin_Unit], g_szUnitMess_Name[g_iPlugin_Unit], "Timestamp", topspeedTimeStamp);
		
		// Add the back button
		Format(menuItem, sizeof(menuItem), "%t", "Back");
		AddMenuItem(menuHandle, "Back", menuItem);
		
		// Display the menu
		DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedtop submenu, only back and exit buttons are present in the submenu.
*/
public TopspeedTopSubMenuCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Back
		ShowHighestOverall(Client, false);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedtop menu, this reacts to what the client does inside the menu.
*/
public TopspeedPersonalMenuCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, the map of a rank
		decl String:choice[MAX_MAPNAME_LENGTH];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Check if it is the current map
		if (StrEqual(choice, g_sCurrentMap))
		{
			// Create the menu
			new Handle:menuHandle = CreateMenu(TopspeedPersonalSubMenuCallBack);
			SetMenuTitle(menuHandle, " - %t - \n%t %s\n", "Personal speedrecords", "All speedrecords of", choice);
			
			// Temporary declarations
			decl String:clientName[MAX_NAME_LENGTH];
			decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
			decl Float:topspeed;
			decl String:recordString[50];
			new size = 0;
			
			// It's the current map, get all records and sort them
			CombineAllMapRecords();
			SortAllMapRecords();
			
			// Get the amount of records
			size = GetArraySize(g_hAllName);
			
			// Loop over all records
			for (new i=0; i<size; i++)
			{
				
				// Catch all data of that record
				GetArrayString(g_hAllName, i, clientName, sizeof(clientName));
				GetArrayString(g_hAllSteamId, i, clientSteamId, sizeof(clientSteamId));
				topspeed = Float:GetArrayCell(g_hAllMaxSpeed, i) * g_fUnitMess_Calc[g_iPlugin_Unit];
				
				// Don't add zero speeds if wanted
				if (topspeed > 0 || g_bPlugin_ShowZeroTopspeeds)
				{
					// Add the record to the menu
					Format(recordString, 50, "%s (%.1f %s)", clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
					AddMenuItem(menuHandle, choice, recordString);
				}
			}
			
			// Display the created menu
			SetMenuExitBackButton(menuHandle, true);
			DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
		}
		else
		{
			// Get the records of that different map
			
			// Temporary declaration
			decl String:sQuery[448];
			
			// Create the SQL get query to retreive all records from the map
			FormatEx(sQuery, sizeof(sQuery), "SELECT auth, name, speed, timestamp, map FROM topspeed WHERE map = '%s' ORDER BY speed DESC", choice);
			
			// Activate the query
			SQL_TQuery(g_hSQL, TopspeedPersonalDifferentMapMenuCallBack, sQuery, Client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the map records loading for topspeed personal.
*/
public TopspeedPersonalDifferentMapMenuCallBack(Handle:owner, Handle:hQuery, const String:sError[], any:Client)
{
	
	if (hQuery == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: SQL error on getting map records for topspeed personal: %s", PLUGIN_NAME, sError);
		return;
	}
	else
	{
		// Temporary declarations
		decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
		decl String:clientName[MAX_NAME_LENGTH];
		decl String:topspeedTimeStamp[20];
		decl String:map[MAX_MAPNAME_LENGTH];
		decl Float:topspeed;
		decl String:recordString[50];
		new size = 0;
		
		// Reset the dynamic arrays
		ClearArray(g_hDifferentMapRecordSteamId);
		ClearArray(g_hDifferentMapRecordName);
		ClearArray(g_hDifferentMapRecordMaxSpeed);
		ClearArray(g_hDifferentMapRecordMaxSpeedTimeStamp);
		ClearArray(g_hDifferentMapRecordMapName);
		
		// Get the records if there are any
		if (SQL_GetRowCount(hQuery) > 0)
		{
			// Fetch Data per Row
			while (SQL_FetchRow(hQuery))
			{
				// Fetch the values
				SQL_FetchString(hQuery, 0, clientSteamId, sizeof(clientSteamId));
				SQL_FetchString(hQuery, 1, clientName, sizeof(clientName));
				topspeed = Float:SQL_FetchFloat(hQuery, 2);
				SQL_FetchString(hQuery, 3, topspeedTimeStamp, sizeof(topspeedTimeStamp));
				SQL_FetchString(hQuery, 4, map, sizeof(map));
				
				// Easy debug
				// PrintToServer("############# GET RECORD #############");
				// PrintToServer("%s %s %f %s %s", clientSteamId, clientName, topspeed, topspeedTimeStamp, map);
				// PrintToServer("############# ---------- #############");
				
				// Save it locally
				if (StrEqual(map, g_sCurrentMap, false))
				{
					PushArrayString(g_hRecordSteamId, clientSteamId);
					PushArrayString(g_hRecordName, clientName);
					PushArrayCell(g_hRecordMaxSpeed, topspeed);
					PushArrayString(g_hRecordMaxSpeedTimeStamp, topspeedTimeStamp);
					
					// Save the current highest speedrecord
					if (topspeed > g_fHighestSpeedrecord)
					{
						g_fHighestSpeedrecord = topspeed;
					}
				}
				else
				{
					PushArrayString(g_hDifferentMapRecordSteamId, clientSteamId);
					PushArrayString(g_hDifferentMapRecordName, clientName);
					PushArrayCell(g_hDifferentMapRecordMaxSpeed, topspeed);
					PushArrayString(g_hDifferentMapRecordMaxSpeedTimeStamp, topspeedTimeStamp);
					PushArrayString(g_hDifferentMapRecordMapName, map);
				}
			}
			
			// Create the menu
			new Handle:menuHandle = CreateMenu(TopspeedPersonalSubMenuCallBack);
			SetMenuTitle(menuHandle, " - %t - \n%t %s\n", "Personal speedrecords", "All speedrecords of", map);
			
			// Get the amount of records
			size = GetArraySize(g_hDifferentMapRecordName);
			
			// Loop over all records
			for (new i=0; i<size; i++)
			{
				
				// Catch all data of that record
				GetArrayString(g_hDifferentMapRecordName, i, clientName, sizeof(clientName));
				GetArrayString(g_hDifferentMapRecordSteamId, i, clientSteamId, sizeof(clientSteamId));
				topspeed = Float:GetArrayCell(g_hDifferentMapRecordMaxSpeed, i) * g_fUnitMess_Calc[g_iPlugin_Unit];
				GetArrayString(g_hDifferentMapRecordMapName, i, map, sizeof(map));
				
				// Don't add zero speeds if wanted
				if (topspeed > 0 || g_bPlugin_ShowZeroTopspeeds)
				{
					// Add the record to the menu
					Format(recordString, 50, "%s (%.1f %s)", clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
					AddMenuItem(menuHandle, map, recordString);
				}
			}
			
			// Display the created menu
			SetMenuExitBackButton(menuHandle, true);
			DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
		}
	}
}

/**
* Callback function for the topspeedpr submenu, this reacts to what the client does inside the menu.
*/
public TopspeedPersonalSubMenuCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Select action found, the client clicked on a speedrecord
		// Get the map
		decl String:choice[MAX_MAPNAME_LENGTH];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Temporary declarations
		decl String:clientName[MAX_NAME_LENGTH];
		decl String:topspeedTimeStamp[20];
		decl Float:topspeed;
		decl String:menuItem[255];
		
		// Get all data of that record, depending on the map
		if (StrEqual(choice, g_sCurrentMap))
		{
			GetArrayString(g_hAllName, Position, clientName, sizeof(clientName));
			GetArrayString(g_hAllMaxSpeedTimeStamp, Position, topspeedTimeStamp, sizeof(topspeedTimeStamp));
			topspeed = Float:GetArrayCell(g_hAllMaxSpeed, Position);
		}
		else
		{
			GetArrayString(g_hDifferentMapRecordName, Position, clientName, sizeof(clientName));
			GetArrayString(g_hDifferentMapRecordMaxSpeedTimeStamp, Position, topspeedTimeStamp, sizeof(topspeedTimeStamp));
			topspeed = Float:GetArrayCell(g_hDifferentMapRecordMaxSpeed, Position);
		}
		
		// Create the submenu in which all details of the record are visible (\n is for an enter)
		new Handle:menuHandle = CreateMenu(TopspeedPersonalSubSubMenuCallBack);
		SetMenuTitle(menuHandle, " - %t - \n%t: %s\n%t: %s\n%t: %.1f %s\n%t: %s\n", "Speedrecord", "Map", choice, "Player", clientName, "Speed", topspeed * g_fUnitMess_Calc[g_iPlugin_Unit], g_szUnitMess_Name[g_iPlugin_Unit], "Timestamp", topspeedTimeStamp);
		
		// Add the back button
		Format(menuItem, sizeof(menuItem), "%t", "Back");
		AddMenuItem(menuHandle, choice, menuItem);
		
		// Display the menu
		DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		if (Position == MenuCancel_ExitBack)
		{
			// Back
			ShowPersonal(Client);
			return;
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedpr subsubmenu, only back and exit buttons are present in the subsubmenu.
*/
public TopspeedPersonalSubSubMenuCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Back
		ShowPersonal(Client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedadmin menu, this reacts to what the client does inside the menu.
*/
public TopspeedAdminMenuCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, the action the admin wants to do
		decl String:choice[50];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Select action found, the client clicked on an option
		if (StrEqual(choice, "ResetCurrent"))
		{
			// Option: Reset a current speedrecord
			ResetCurrent(Client);
		}
		else if (StrEqual(choice, "ResetAll"))
		{
			// Option: Reset all current speedrecords
			ResetAllCurrent(Client);
		}
		else if (StrEqual(choice, "DeleteRecord"))
		{
			// Option: Delete a speedrecord on the current map
			DeleteRecord(Client);
		}
		else if (StrEqual(choice, "DeleteAll"))
		{
			// Option: Delete all speedrecords on the current map
			DeleteAllRecords(Client);
		}
		else if (StrEqual(choice, "DeleteDifferent"))
		{
			// Option: Delete a speedrecord on a different map
			DeleteDifferentRecord(Client);
		}
		else if (StrEqual(choice, "DeleteDifferentAll"))
		{
			// Option: Delete all speedrecords on a different map
			DeleteAllDifferentRecord(Client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedadmin "Reset a current speedrecord" submenu.
*/
public TopspeedAdminMenuResetCurrentCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, the steam id of the player
		decl String:choice[MAX_STEAMAUTH_LENGTH];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Find the chosen record
		new recordIndex = FindStringInArray(g_hSessionSteamId, choice);
		if (recordIndex == -1)
		{
			// Something went wrong, close the menu
			CloseHandle(menuhandle);
		}
		else
		{
			// Reset the roundspeed and gamespeed
			SetArrayCell(g_hSessionMaxSpeedRound, recordIndex, 0.0);
			SetArrayCell(g_hSessionMaxSpeedGame, recordIndex, 0.0);
			
			// Reset that the client possibly achieved a higher topspeed
			SetArrayCell(g_hSessionHigherRecord, recordIndex, false);
			
			// Action done, return to main topspeed admin menu
			ShowTopspeedAdmin(Client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (Position == MenuCancel_ExitBack)
		{
			// Back
			ShowTopspeedAdmin(Client);
			return;
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedadmin "Reset all current speedrecords" submenu.
*/
public TopspeedAdminMenuResetCurrentAllCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, yes/no if they should be reset
		decl String:choice[20];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Check if it is confirmed
		if (StrEqual(choice, "yes"))
		{
			// Action confirmed
			
			// Get the amount of records
			new size = GetArraySize(g_hSessionName);
			
			// Loop over all records
			for (new i=0; i<size; i++)
			{
				
				// Reset the roundspeed and gamespeed
				SetArrayCell(g_hSessionMaxSpeedRound, i, 0.0);
				SetArrayCell(g_hSessionMaxSpeedGame, i, 0.0);
				
				// Reset that the client possibly achieved a higher topspeed
				SetArrayCell(g_hSessionHigherRecord, i, false);
			}
			
			// Action done, return to main topspeed admin menu
			ShowTopspeedAdmin(Client);
		}
		else
		{
			// Action rejected, return to main topspeed admin menu
			ShowTopspeedAdmin(Client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedadmin "Delete a saved speedrecord on the current map" submenu.
*/
public TopspeedAdminMenuDeleteRecordCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, the steam id of a player
		decl String:choice[MAX_STEAMAUTH_LENGTH];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Find the chosen record
		new recordIndex = FindStringInArray(g_hRecordSteamId, choice);
		if (recordIndex == -1)
		{
			// Something went wrong, close the menu
			CloseHandle(menuhandle);
		}
		else
		{
			// Temporary declarations
			decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
			decl String:topspeedTimeStamp[20];
			
			// Get all data of that record
			GetArrayString(g_hRecordSteamId, recordIndex, clientSteamId, sizeof(clientSteamId));
			GetArrayString(g_hRecordMaxSpeedTimeStamp, recordIndex, topspeedTimeStamp, sizeof(topspeedTimeStamp));
			
			// Make sure the player is reset in terms of its status
			new sessionIndex = FindStringInArray(g_hRecordSteamId, clientSteamId);
			
			// Check if the player is/was in game/session
			if (sessionIndex > -1)
			{
				// Reset that the client possibly achieved a higher topspeed
				SetArrayCell(g_hSessionHigherRecord, sessionIndex, false);
				
				// Set that the client its record is new
				SetArrayCell(g_hSessionNewRecord, sessionIndex, true);
			}
			
			// Delete the record in the database
			DeleteMapRecord(clientSteamId, topspeedTimeStamp);
			
			// Delete the record from the dynamic arrays
			RemoveFromArray(g_hRecordSteamId, recordIndex);
			RemoveFromArray(g_hRecordName, recordIndex);
			RemoveFromArray(g_hRecordMaxSpeed, recordIndex);
			RemoveFromArray(g_hRecordMaxSpeedTimeStamp, recordIndex);
			
			// Action done, return to main topspeed admin menu
			ShowTopspeedAdmin(Client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (Position == MenuCancel_ExitBack)
		{
			// Back
			ShowTopspeedAdmin(Client);
			return;
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedadmin "Delete all saved speedrecords on the current map" submenu.
*/
public TopspeedAdminMenuDeleteRecordAllCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, yes/no if they should be deleted
		decl String:choice[20];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Check if it is confirmed
		if (StrEqual(choice, "yes"))
		{
			// Action confirmed
			
			// First reset all clients in game
			
			// Get the amount of records
			new size = GetArraySize(g_hSessionName);
			
			// Loop over all records
			for (new i=0; i<size; i++)
			{
				
				// Reset that the client possibly achieved a higher topspeed
				SetArrayCell(g_hSessionHigherRecord, i, false);
				
				// Set that the client its record is new
				SetArrayCell(g_hSessionNewRecord, i, true);
			}
			
			// Then delete all records in the database
			DeleteMapRecords(g_sCurrentMap);
			
			// Remove all records from the dynamic array
			ClearArray(g_hRecordSteamId);
			ClearArray(g_hRecordName);
			ClearArray(g_hRecordMaxSpeed);
			ClearArray(g_hRecordMaxSpeedTimeStamp);
			
			// Action done, return to main topspeed admin menu
			ShowTopspeedAdmin(Client);
		}
		else
		{
			// Action rejected, return to main topspeed admin menu
			ShowTopspeedAdmin(Client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedadmin "Delete a saved speedrecord on a different map" submenu.
*/
public TopspeedAdminMenuDeleteRecordDifferentMapCallBack(Handle:menuhandle, MenuAction:action, clientCurrent, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, the different map
		new String:choice[MAX_MAPNAME_LENGTH];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Get the records of that different map
		
		// Temporary declaration
		decl String:sQuery[448];
		
		// Create the SQL get query to retreive all records from the map
		FormatEx(sQuery, sizeof(sQuery), "SELECT auth, name, speed, timestamp, map FROM topspeed WHERE map = '%s' ORDER BY speed DESC", choice);
		
		// Activate the query
		SQL_TQuery(g_hSQL, TopspeedAdminMenuDeleteRecordDifferentMapListingCallBack, sQuery, clientCurrent);
	}
	else if (action == MenuAction_Cancel)
	{
		if (Position == MenuCancel_ExitBack)
		{
			// Back
			ShowTopspeedAdmin(clientCurrent);
			return;
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the map records loading for topspeed delete menu.
*/
public TopspeedAdminMenuDeleteRecordDifferentMapListingCallBack(Handle:menuhandle, Handle:hQuery, const String:sError[], any:Client)
{
	
	if (hQuery == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: SQL error on getting map records for topspeed personal: %s", PLUGIN_NAME, sError);
		return;
	}
	else
	{
		// Temporary declarations
		decl String:recordString[50];
		decl String:clientName[MAX_NAME_LENGTH];
		decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
		decl Float:topspeed;
		decl String:topspeedTimeStamp[20];
		decl String:map[MAX_MAPNAME_LENGTH];
		
		// Reset the dynamic arrays
		ClearArray(g_hDifferentMapRecordSteamId);
		ClearArray(g_hDifferentMapRecordName);
		ClearArray(g_hDifferentMapRecordMaxSpeed);
		ClearArray(g_hDifferentMapRecordMaxSpeedTimeStamp);
		ClearArray(g_hDifferentMapRecordMapName);
		
		// Get the records if there are any
		if (SQL_GetRowCount(hQuery) > 0)
		{
			// Fetch Data per Row
			while (SQL_FetchRow(hQuery))
			{
				// Fetch the values
				SQL_FetchString(hQuery, 0, clientSteamId, sizeof(clientSteamId));
				SQL_FetchString(hQuery, 1, clientName, sizeof(clientName));
				topspeed = Float:SQL_FetchFloat(hQuery, 2);
				SQL_FetchString(hQuery, 3, topspeedTimeStamp, sizeof(topspeedTimeStamp));
				SQL_FetchString(hQuery, 4, map, sizeof(map));
				
				// Easy debug
				// PrintToServer("############# GET RECORD #############");
				// PrintToServer("%s %s %f %s %s", clientSteamId, clientName, topspeed, topspeedTimeStamp, map);
				// PrintToServer("############# ---------- #############");
				
				// Save it locally
				if (StrEqual(map, g_sCurrentMap, false))
				{
					PushArrayString(g_hRecordSteamId, clientSteamId);
					PushArrayString(g_hRecordName, clientName);
					PushArrayCell(g_hRecordMaxSpeed, topspeed);
					PushArrayString(g_hRecordMaxSpeedTimeStamp, topspeedTimeStamp);
					
					// Save the current highest speedrecord
					if (topspeed > g_fHighestSpeedrecord)
					{
						g_fHighestSpeedrecord = topspeed;
					}
				}
				else
				{
					PushArrayString(g_hDifferentMapRecordSteamId, clientSteamId);
					PushArrayString(g_hDifferentMapRecordName, clientName);
					PushArrayCell(g_hDifferentMapRecordMaxSpeed, topspeed);
					PushArrayString(g_hDifferentMapRecordMaxSpeedTimeStamp, topspeedTimeStamp);
					PushArrayString(g_hDifferentMapRecordMapName, map);
				}
			}
			
			// Get the amount of records
			new size = GetArraySize(g_hDifferentMapRecordMaxSpeed);
			
			// Create the menu
			new Handle:menuHandle = CreateMenu(TopspeedAdminMenuDeleteRecordDifferentMapRecordSelectedCallBack);
			SetMenuTitle(menuHandle, " - %t - \n%t\n%t %s\n", "Speed meter Commands", "Delete a saved speedrecord on a different map", "All speedrecords of", map);
			
			// Loop over all records
			for (new i=0; i<size; i++)
			{
				
				// Catch all data of that record
				GetArrayString(g_hDifferentMapRecordName, i, clientName, sizeof(clientName));
				GetArrayString(g_hDifferentMapRecordSteamId, i, clientSteamId, sizeof(clientSteamId));
				topspeed = Float:GetArrayCell(g_hDifferentMapRecordMaxSpeed, i) * g_fUnitMess_Calc[g_iPlugin_Unit];
				
				// Add the record to the menu
				Format(recordString, 50, "%s (%.1f %s)", clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
				AddMenuItem(menuHandle, clientSteamId, recordString);
			}
			
			// Display the created menu
			SetMenuExitBackButton(menuHandle, true);
			DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
		}
	}
}

/**
* Callback function for the topspeedadmin "Delete a saved speedrecord on a different map" submenu after selecting a record to delete.
*/
public TopspeedAdminMenuDeleteRecordDifferentMapRecordSelectedCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, the steam id of the player
		decl String:choice[MAX_STEAMAUTH_LENGTH];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Find the chosen record
		new recordIndex = FindStringInArray(g_hDifferentMapRecordSteamId, choice);
		if (recordIndex == -1)
		{
			// Something went wrong, close the menu
			CloseHandle(menuhandle);
		}
		else
		{
			// Temporary declarations
			decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
			decl String:topspeedTimeStamp[20];
			
			// Get all data of that record
			GetArrayString(g_hDifferentMapRecordSteamId, recordIndex, clientSteamId, sizeof(clientSteamId));
			GetArrayString(g_hDifferentMapRecordMaxSpeedTimeStamp, recordIndex, topspeedTimeStamp, sizeof(topspeedTimeStamp));
			
			// Delete the record in the database
			DeleteMapRecord(clientSteamId, topspeedTimeStamp);
			
			// Delete the record from the dynamic arrays
			RemoveFromArray(g_hDifferentMapRecordSteamId, recordIndex);
			RemoveFromArray(g_hDifferentMapRecordName, recordIndex);
			RemoveFromArray(g_hDifferentMapRecordMaxSpeed, recordIndex);
			RemoveFromArray(g_hDifferentMapRecordMaxSpeedTimeStamp, recordIndex);
			RemoveFromArray(g_hDifferentMapRecordMapName, recordIndex);
			
			// Action done, return to main topspeed admin menu
			ShowTopspeedAdmin(Client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (Position == MenuCancel_ExitBack)
		{
			// Back
			DeleteDifferentRecord(Client);
			return;
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedadmin "Delete all saved speedrecords on a different map" submenu.
*/
public TopspeedAdminMenuDeleteRecordDifferentMapAllCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, the different map
		new String:choice[MAX_MAPNAME_LENGTH];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Temporary declaration
		decl String:menuItem[255];
	
		// Confirm this dangerous choice
		new Handle:menuHandle = CreateMenu(TopspeedAdminMenuDeleteRecordDifferentMapAllSelectedCallBack);
		SetMenuTitle(menuHandle, " - %t - \n%t %s\n\n%t?\n", "Speed meter Commands", "Delete all saved speedrecords on", choice, "Are you sure");
	
		// Options
		Format(menuItem, sizeof(menuItem), "%t", "Yes");
		AddMenuItem(menuHandle, choice, menuItem);
		Format(menuItem, sizeof(menuItem), "%t", "No");
		AddMenuItem(menuHandle, "no", menuItem);
		
		// Display the created menu
		DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		if (Position == MenuCancel_ExitBack)
		{
			// Back
			ShowTopspeedAdmin(Client);
			return;
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedadmin "Delete all saved speedrecords on a different map" submenu after verifying to delete all records of a map.
*/
public TopspeedAdminMenuDeleteRecordDifferentMapAllSelectedCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, no if cancelled, the mapname if confirmed
		decl String:choice[20];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Check if it is confirmed
		if (!StrEqual(choice, "no"))
		{
			// Action confirmed
			
			// Delete all records in the database
			DeleteMapRecords(choice);
			
			// Action done, return to main topspeed admin menu
			ShowTopspeedAdmin(Client);
		}
		else
		{
			// Action rejected, return to main topspeed admin menu
			ShowTopspeedAdmin(Client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/**
* Callback function for the topspeedhelp menu.
*/
public TopspeedHelpMenuCallBack(Handle:menuhandle, MenuAction:action, Client, Position)
{
	
	if (action == MenuAction_Select)
	{
		// Get the chosen item, the command that the player wants info about
		decl String:choice[50];
		GetMenuItem(menuhandle, Position, choice, sizeof(choice));
		
		// Player selected an item, let the player say the command
		if (StrEqual(choice, "topspeed"))
		{
			ShowBestCurrentSession();
		}
		else if (StrEqual(choice, "topspeedmap"))
		{
			ShowBestAllTime(Client);
		}
		else if (StrEqual(choice, "topspeedtop"))
		{
			ShowHighestOverall(Client);
		}
		else if (StrEqual(choice, "topspeedpr"))
		{
			ShowPersonal(Client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}

/*****************************************************************


A D M I N   F U N C T I O N S


*****************************************************************/

/**
* Command for "Reset a current speedrecord".
*/
public Action:Command_TopspeedReset(client, args)
{
	
	ResetCurrent(client);

	return Plugin_Handled;
}

/**
* Admin menu handler for "Reset a current speedrecord".
*/
public AdminMenu_ResetCurrent(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Reset a current speedrecord", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		ResetCurrent(param);
	}
}

/**
* Reset a current topspeed.
*/
stock ResetCurrent(Client)
{
	
	// Sort all records according to their best topspeed in the current game/session
	SortBestGame();
	
	// Get the amount of records
	new size = GetArraySize(g_hSessionName);
	
	// Temporary declarations
	decl String:clientName[MAX_NAME_LENGTH];
	decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
	decl Float:topspeed;
	decl String:recordString[50];
	
	// Create the menu
	new Handle:menuHandle = CreateMenu(TopspeedAdminMenuResetCurrentCallBack);
	SetMenuTitle(menuHandle, " - %t - \n%t\n", "Speed meter Commands", "Reset a current speedrecord");
	
	// Loop over all records
	for (new i=0; i<size; i++)
	{
				
		// Catch all data of that record
		GetArrayString(g_hSessionName, i, clientName, sizeof(clientName));
		GetArrayString(g_hSessionSteamId, i, clientSteamId, sizeof(clientSteamId));
		topspeed = Float:GetArrayCell(g_hSessionMaxSpeedGame, i) * g_fUnitMess_Calc[g_iPlugin_Unit];
		
		// Only show zero values if it is set to do so
		if (topspeed > 0 || g_bPlugin_ShowZeroTopspeeds)
		{
			// Add the record to the menu
			Format(recordString, 50, "%s (%.1f %s)", clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
			AddMenuItem(menuHandle, clientSteamId, recordString);
		}
	}
	
	// Display the created menu
	SetMenuExitBackButton(menuHandle, true);
	DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
}

/**
* Command for "Reset all current speedrecords".
*/
public Action:Command_TopspeedResetAll(client, args)
{
	
	ResetAllCurrent(client);

	return Plugin_Handled;
}

/**
* Admin menu handler for "Reset all current speedrecords".
*/
public AdminMenu_ResetAllCurrent(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Reset all current speedrecords", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		ResetAllCurrent(param);
	}
}

/**
* Reset all current topspeeds.
*/
stock ResetAllCurrent(Client)
{
	
	// Temporary declaration
	decl String:menuItem[255];
	
	// Confirm this dangerous choice
	new Handle:menuHandle = CreateMenu(TopspeedAdminMenuResetCurrentAllCallBack);
	SetMenuTitle(menuHandle, " - %t - \n%t\n\n%t?\n", "Speed meter Commands", "Reset all current speedrecords", "Are you sure");
	
	// Options
	Format(menuItem, sizeof(menuItem), "%t", "Yes");
	AddMenuItem(menuHandle, "yes", menuItem);
	Format(menuItem, sizeof(menuItem), "%t", "No");
	AddMenuItem(menuHandle, "no", menuItem);
	
	// Display the created menu
	DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
}

/**
* Command for "Delete a saved speedrecord on the current map".
*/
public Action:Command_TopspeedDelete(client, args)
{
	
	DeleteRecord(client);

	return Plugin_Handled;
}

/**
* Admin menu handler for "Delete a saved speedrecord on the current map".
*/
public AdminMenu_DeleteRecord(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Delete a saved speedrecord on the current map", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DeleteRecord(param);
	}
}

/**
* Delete a previous speedrecord on this map.
*/
stock DeleteRecord(Client)
{
	
	// All previously saved records are already sorted on import
	
	// Get the amount of records
	new size = GetArraySize(g_hRecordName);
	
	// Temporary declarations
	decl String:recordString[50];
	decl String:clientName[MAX_NAME_LENGTH];
	decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
	decl Float:topspeed;
	
	// Create the menu
	new Handle:menuHandle = CreateMenu(TopspeedAdminMenuDeleteRecordCallBack);
	SetMenuTitle(menuHandle, " - %t - \n%t\n", "Speed meter Commands", "Delete a saved speedrecord on the current map");
	
	// Loop over all records
	for (new i=0; i<size; i++)
	{
		
		// Catch all data of that record
		GetArrayString(g_hRecordName, i, clientName, sizeof(clientName));
		GetArrayString(g_hRecordSteamId, i, clientSteamId, sizeof(clientSteamId));
		topspeed = Float:GetArrayCell(g_hRecordMaxSpeed, i) * g_fUnitMess_Calc[g_iPlugin_Unit];
		
		// Add the speedrecord to the menu
		Format(recordString, 50, "%s (%.1f %s)", clientName, topspeed, g_szUnitMess_Name[g_iPlugin_Unit]);
		AddMenuItem(menuHandle, clientSteamId, recordString);
	}
	
	// Display the created menu
	SetMenuExitBackButton(menuHandle, true);
	DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
}

/**
* Command for "Delete all saved speedrecords on the current map".
*/
public Action:Command_TopspeedDeleteAll(client, args)
{
	
	DeleteAllRecords(client);

	return Plugin_Handled;
}

/**
* Admin menu handler for "Delete all saved speedrecords on the current map".
*/
public AdminMenu_DeleteAllRecords(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Delete all saved speedrecords on the current map", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DeleteAllRecords(param);
	}
}

/**
* Delete all previous speedrecords on this map.
*/
stock DeleteAllRecords(Client)
{	
	
	// Temporary declaration
	decl String:menuItem[255];
	
	// Confirm this dangerous choice
	new Handle:menuHandle = CreateMenu(TopspeedAdminMenuDeleteRecordAllCallBack);
	SetMenuTitle(menuHandle, " - %t - \n%t\n\n%t?\n", "Speed meter Commands", "Delete all saved speedrecords on the current map", "Are you sure");
	
	// Options
	Format(menuItem, sizeof(menuItem), "%t", "Yes");
	AddMenuItem(menuHandle, "yes", menuItem);
	Format(menuItem, sizeof(menuItem), "%t", "No");
	AddMenuItem(menuHandle, "no", menuItem);
	
	// Display the created menu
	DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
}

/**
* Command for "Delete a saved speedrecord on a different map".
*/
public Action:Command_TopspeedDeleteDifferent(client, args)
{
	
	DeleteDifferentRecord(client);

	return Plugin_Handled;
}

/**
* Admin menu handler for "Delete a saved speedrecord on a different map".
*/
public AdminMenu_DeleteDifferentRecord(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Delete a saved speedrecord on a different map", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DeleteDifferentRecord(param);
	}
}

/**
* Delete a previous speedrecord on a different map.
*/
stock DeleteDifferentRecord(Client)
{
	
	// First get the different map list
	
	// Temporary declaration
	decl String:sQuery[448];
	
	// Create the SQL get query to retreive all maps
	FormatEx(sQuery, sizeof(sQuery), "SELECT DISTINCT map FROM topspeed WHERE map != '%s' ORDER BY map", g_sCurrentMap);
	
	// Activate the query
	SQL_TQuery(g_hSQL, DeleteDifferentRecordDifferentMapListCallback, sQuery, Client);
}

/**
* Callback function for retreiving map list for the delete different record.
*/
public DeleteDifferentRecordDifferentMapListCallback(Handle:owner, Handle:hQueryDifferentMapList, const String:sError[], any:Client)
{
	if (hQueryDifferentMapList == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: SQL error on getting personal records maplist: %s", PLUGIN_NAME, sError);
		return;
	}
	else
	{
		// Temporary declarations
		decl String:mapName[MAX_MAPNAME_LENGTH];
		decl String:map[MAX_MAPNAME_LENGTH];
		
		// Reset the maplist
		ClearArray(g_hDifferentMapList);
		
		// Get the records if there are any
		if (SQL_GetRowCount(hQueryDifferentMapList) > 0)
		{
			// Fetch Data per Row
			while (SQL_FetchRow(hQueryDifferentMapList))
			{
				// Fetch the values
				SQL_FetchString(hQueryDifferentMapList, 0, mapName, sizeof(mapName));
				
				// Save it locally
				PushArrayString(g_hDifferentMapList, mapName);
			}
		}
		
		// Create the menu
		new Handle:menuHandle = CreateMenu(TopspeedAdminMenuDeleteRecordDifferentMapCallBack);
		SetMenuTitle(menuHandle, " - %t - \n%t\n", "Speed meter Commands", "Delete a saved speedrecord on a different map");
		
		// Get the amount of maps and loop over them
		new mapListSize = GetArraySize(g_hDifferentMapList);
		
		for (new i=0; i<mapListSize; i++)
		{
			
			// Add the map to the options
			GetArrayString(g_hDifferentMapList, i, map, sizeof(map));
			AddMenuItem(menuHandle, map, map);
		}
		
		// Display the created menu
		SetMenuExitBackButton(menuHandle, true);
		DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
	}
}

/**
* Command for "Delete all saved speedrecords on a different map".
*/
public Action:Command_TopspeedDeleteDifferentAll(client, args)
{
	
	DeleteAllDifferentRecord(client);

	return Plugin_Handled;
}

/**
* Admin menu handler for "Delete all saved speedrecords on a different map".
*/
public AdminMenu_DeleteAllDifferentRecords(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Delete all saved speedrecords on a different map", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DeleteAllDifferentRecord(param);
	}
}

/**
* Delete a previous speedrecords on a different map.
*/
stock DeleteAllDifferentRecord(Client)
{
	
	// First get the different map list
	
	// Temporary declaration
	decl String:sQuery[448];
	
	// Create the SQL get query to retreive all maps
	FormatEx(sQuery, sizeof(sQuery), "SELECT DISTINCT map FROM topspeed WHERE map != '%s' ORDER BY map", g_sCurrentMap);
	
	// Activate the query
	SQL_TQuery(g_hSQL, DeleteAllDifferentRecordDifferentMapListCallback, sQuery, Client);
}

/**
* Callback function for retreiving maplist for the delete all different records of a map.
*/
public DeleteAllDifferentRecordDifferentMapListCallback(Handle:owner, Handle:hQueryDifferentMapList, const String:sError[], any:Client)
{
	if (hQueryDifferentMapList == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: SQL error on getting personal records maplist: %s", PLUGIN_NAME, sError);
		return;
	}
	else
	{
		// Temporary declarations
		decl String:mapName[MAX_MAPNAME_LENGTH];
		decl String:map[MAX_MAPNAME_LENGTH];
		
		// Reset the maplist
		ClearArray(g_hDifferentMapList);
		
		// Get the records if there are any
		if (SQL_GetRowCount(hQueryDifferentMapList) > 0)
		{
			// Fetch Data per Row
			while (SQL_FetchRow(hQueryDifferentMapList))
			{
				// Fetch the values
				SQL_FetchString(hQueryDifferentMapList, 0, mapName, sizeof(mapName));
				
				// Save it locally
				PushArrayString(g_hDifferentMapList, mapName);
			}
		}
		
		// Create the menu
		new Handle:menuHandle = CreateMenu(TopspeedAdminMenuDeleteRecordDifferentMapAllCallBack);
		SetMenuTitle(menuHandle, " - %t - \n%t\n", "Speed meter Commands", "Delete all saved speedrecords on a different map");
		
		// Get the amount of maps and loop over them
		new mapListSize = GetArraySize(g_hDifferentMapList);
		
		for (new i=0; i<mapListSize; i++)
		{
			
			// Add the map to the options
			GetArrayString(g_hDifferentMapList, i, map, sizeof(map));
			AddMenuItem(menuHandle, map, map);
		}
		
		// Display the created menu
		SetMenuExitBackButton(menuHandle, true);
		DisplayMenu(menuHandle, Client, MENU_TIME_FOREVER);
	}
}

/*****************************************************************


D A T A B A S E   F U N C T I O N S


*****************************************************************/

/**
* Try connecting to the database.
*/
stock ConnectSQL()
{
	
	if (g_hSQL != INVALID_HANDLE)
	{
		// Close the handle first if it was already open
		CloseHandle(g_hSQL);
	}
	
	g_hSQL = INVALID_HANDLE;

	SQL_TConnect(ConnectSQLCallback, "speedmeter");
}

/**
* Callback function for connecting to the database, this is useful for possible errors on connects to the database and it initializes the table for this plugin.
*/
public ConnectSQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	
	if (g_iReconnectCounter >= 15)
	{
		// Too many reconnects
		LogError("%s: Plugin stopped, reconnect counter reached max", PLUGIN_NAME);
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: Connection to SQL database has failed: %s", PLUGIN_NAME, error);
		
		// Try to reconnect
		g_iReconnectCounter++;
		ConnectSQL();
		
		return;
	}

	// Connected! Find out which database is connected for the correct table creation
	decl String:sDriver[16];
	SQL_GetDriverIdent(owner, sDriver, sizeof(sDriver));

	g_hSQL = CloneHandle(hndl);		
	
	if (StrEqual(sDriver, "mysql", false))
	{
		// For MySQL the database should do the set names query before all other queries
		SQL_TQuery(g_hSQL, SetNamesCallback, "SET NAMES  'utf8'", _, DBPrio_High);
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `topspeed` (`id` int(11) NOT NULL AUTO_INCREMENT, `map` varchar(32) NOT NULL, `auth` varchar(32) NOT NULL, `speed` float NOT NULL, `name` varchar(64) NOT NULL, `timestamp` varchar(20) NOT NULL, PRIMARY KEY (`id`));");
	}
	else if (StrEqual(sDriver, "sqlite", false))
	{
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `topspeed` (`id` INTEGER PRIMARY KEY, `map` varchar(32) NOT NULL, `auth` varchar(32) NOT NULL, `speed` float NOT NULL, `name` varchar(64) NOT NULL, `timestamp` varchar(20) NOT NULL);");
	}
	else
	{
		// Try MySQL as default
		SQL_TQuery(g_hSQL, SetNamesCallback, "SET NAMES  'utf8'", _, DBPrio_High);
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `topspeed` (`id` int(11) NOT NULL AUTO_INCREMENT, `map` varchar(32) NOT NULL, `auth` varchar(32) NOT NULL, `speed` float NOT NULL, `name` varchar(64) NOT NULL, `timestamp` varchar(20) NOT NULL, PRIMARY KEY (`id`));");
	}
	
	// Reset the counter
	g_iReconnectCounter = 1;
	
	// Get the current map records now SQL is connected, only do it on the intial connect with SQL
	ClearArray(g_hRecordSteamId);
	ClearArray(g_hRecordName);
	ClearArray(g_hRecordMaxSpeed);
	ClearArray(g_hRecordMaxSpeedTimeStamp);
	GetMapRecords(g_sCurrentMap);
}

/**
* Callback function for the set names query, this is only useful for possible errors.
*/
public SetNamesCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	
	if (hndl == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: SQL error on setting names: %s", PLUGIN_NAME, error);
		return;
	}
}

/**
* Callback function for the create table query, this is useful for possible errors and possible database reconnects.
*/
public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	
	if (owner == INVALID_HANDLE)
	{
		// Connecting to the database failed, log the error
		LogError("%s: SQL error on connecting to the database: %s", PLUGIN_NAME, error);
		
		// Try to reconnect
		g_iReconnectCounter++;
		ConnectSQL();

		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: SQL error on creating the table: %s", PLUGIN_NAME, error);
		return;
	}
}

/**
* Load all records of the map from the database.
*/
stock GetMapRecords(String:map[])
{
	
	// Temporary declarations
	decl String:sQuery[448], String:sError[255];
	
	// Create the SQL get query to retreive all records from the map
	FormatEx(sQuery, sizeof(sQuery), "SELECT auth, name, speed, timestamp FROM topspeed WHERE map = '%s' ORDER BY speed DESC", map);
	
	// Lock the database for usage and create a handle to activate the query
	SQL_LockDatabase(g_hSQL);
	new Handle:hQuery = SQL_Query(g_hSQL, sQuery);
	
	if (hQuery == INVALID_HANDLE)
	{
		// Something went wrong, log the error and unlock the database
		SQL_GetError(g_hSQL, sError, sizeof(sError));
		LogError("%s: SQL error on getting map records: %s", PLUGIN_NAME, sError);
		SQL_UnlockDatabase(g_hSQL);
		return;
	}
	
	bool bInitHighestSpeedrecord = false;
	
	// Get the records if there are any
	if (SQL_GetRowCount(hQuery) > 0)
	{
		// Temporary declarations
		decl String:clientName[MAX_NAME_LENGTH];
		decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
		decl String:topspeedTimeStamp[20];
		decl Float:topspeed;
		
		// Fetch Data per Row
		while (SQL_FetchRow(hQuery))
		{
			// Fetch the values
			SQL_FetchString(hQuery, 0, clientSteamId, sizeof(clientSteamId));
			SQL_FetchString(hQuery, 1, clientName, sizeof(clientName));
			topspeed = Float:SQL_FetchFloat(hQuery, 2);
			SQL_FetchString(hQuery, 3, topspeedTimeStamp, sizeof(topspeedTimeStamp));
			
			// Easy debug
			// PrintToServer("############# GET RECORD #############");
			// PrintToServer("%s %s %f %s %s", clientSteamId, clientName, topspeed, topspeedTimeStamp, map);
			// PrintToServer("############# ---------- #############");
			
			// Save it locally
			if (StrEqual(map, g_sCurrentMap, false))
			{
				PushArrayString(g_hRecordSteamId, clientSteamId);
				PushArrayString(g_hRecordName, clientName);
				PushArrayCell(g_hRecordMaxSpeed, topspeed);
				PushArrayString(g_hRecordMaxSpeedTimeStamp, topspeedTimeStamp);
				
				if (!bInitHighestSpeedrecord)
				{
					g_fHighestSpeedrecord = topspeed;
					bInitHighestSpeedrecord = true;
				}
				
				// Save the current highest speedrecord
				if (topspeed > g_fHighestSpeedrecord)
				{
					g_fHighestSpeedrecord = topspeed;
				}
			}
			else
			{
				PushArrayString(g_hDifferentMapRecordSteamId, clientSteamId);
				PushArrayString(g_hDifferentMapRecordName, clientName);
				PushArrayCell(g_hDifferentMapRecordMaxSpeed, topspeed);
				PushArrayString(g_hDifferentMapRecordMaxSpeedTimeStamp, topspeedTimeStamp);
				PushArrayString(g_hDifferentMapRecordMapName, map);
			}
		}
	}
	
	// Unlock the database for usage and close the handle
	SQL_UnlockDatabase(g_hSQL); 
	CloseHandle(hQuery);
}

/**
* Get the highest overall speedrecords in the database.
*/
stock GetHighestOverallTopspeedRecords(clientCurrent, bool:printInChat)
{
	
	// If it should not be printed then it was already retrieved
	if (!printInChat)
	{
		ShowHighestOverallMain(clientCurrent, false);
	}
	else
	{
		// Temporary declaration
		decl String:sQuery[448];
		
		// Create the SQL get query to retreive all highest speedrecords without the current map, oldest records get a higher priority with equal speeds
		FormatEx(sQuery, sizeof(sQuery), "SELECT auth, name, speed, timestamp, map FROM topspeed WHERE map != '%s' ORDER BY speed DESC, timestamp ASC LIMIT %d", g_sCurrentMap, g_iPlugin_AmountOfTopspeedTop);
		
		// Activate the query
		SQL_TQuery(g_hSQL, GetHighestOverallTopspeedRecordsMainCallback, sQuery, clientCurrent);
	}
}

/**
* Callback function for the overall highest speeds records.
*/
public GetHighestOverallTopspeedRecordsMainCallback(Handle:owner, Handle:hQuery, const String:sError[], any:clientCurrent)
{
	if (hQuery == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: SQL error on getting the highest speedrecords: %s", PLUGIN_NAME, sError);
		return;
	}
	else
	{
		// Temporary declarations
		decl String:clientName[MAX_NAME_LENGTH];
		decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
		decl String:topspeedTimeStamp[20];
		decl String:mapName[MAX_MAPNAME_LENGTH];
		decl Float:topspeed;
			
		// Empty the arrays to keep all records in
		ClearArray(g_hHighestOverallSteamId);
		ClearArray(g_hHighestOverallName);
		ClearArray(g_hHighestOverallMapName);
		ClearArray(g_hHighestOverallMaxSpeed);
		ClearArray(g_hHighestOverallMaxSpeedTimeStamp);
		
		// Get the records if there are any
		if (SQL_GetRowCount(hQuery) > 0)
		{
			// Fetch Data per Row
			while (SQL_FetchRow(hQuery))
			{
				// Fetch the values
				SQL_FetchString(hQuery, 0, clientSteamId, sizeof(clientSteamId));
				SQL_FetchString(hQuery, 1, clientName, sizeof(clientName));
				topspeed = (Float:SQL_FetchFloat(hQuery, 2) * g_fUnitMess_Calc[g_iPlugin_Unit]);
				SQL_FetchString(hQuery, 3, topspeedTimeStamp, sizeof(topspeedTimeStamp));
				SQL_FetchString(hQuery, 4, mapName, sizeof(mapName));
				
				// Only show zero values if it is set to do so
				if (topspeed > 0 || g_bPlugin_ShowZeroTopspeeds)
				{
					// Save it locally
					PushArrayString(g_hHighestOverallSteamId, clientSteamId);
					PushArrayString(g_hHighestOverallName, clientName);
					PushArrayCell(g_hHighestOverallMaxSpeed, Float:SQL_FetchFloat(hQuery, 2));
					PushArrayString(g_hHighestOverallMaxSpeedTimeStamp, topspeedTimeStamp);
					PushArrayString(g_hHighestOverallMapName, mapName);
				}
			}
		}
		
		// Now add all speedrecords of the current map
		
		// Combine and sort all records of the current map
		CombineAllMapRecords();
		SortAllMapRecords();
		
		// Find the amount of records that are higher then the lowest in the best ever
		new amountOfHigherRecordsInCurrentMap = 0;
		
		// Verify that there are previous records found
		if (GetArraySize(g_hHighestOverallMaxSpeed) > 0)
		{
			while (GetArrayCell(g_hAllMaxSpeed, amountOfHigherRecordsInCurrentMap) > GetArrayCell(g_hHighestOverallMaxSpeed, GetArraySize(g_hHighestOverallMaxSpeed) - 1))
			{
				amountOfHigherRecordsInCurrentMap++;
				
				// Make sure not to go over the current amount of topspeeds and break if so
				if (amountOfHigherRecordsInCurrentMap >= GetArraySize(g_hAllMaxSpeed))
				{
					break;
				}
			}
		}
		else
		{
			// No records found in the database yet
			amountOfHigherRecordsInCurrentMap = GetArraySize(g_hAllMaxSpeed);
		}
			
		// Make sure to fully populate the amount if needed
		new actualAmountOfMapRecordsToAdd = 0;
		new minimumAmountOfMapRecordsToAdd = g_iPlugin_AmountOfTopspeedTop - GetArraySize(g_hHighestOverallMaxSpeed);
		if (amountOfHigherRecordsInCurrentMap < minimumAmountOfMapRecordsToAdd)
		{
			// Make sure it is fully populated, but don't add more then possible
			if (GetArraySize(g_hAllMaxSpeed) < minimumAmountOfMapRecordsToAdd)
			{
				actualAmountOfMapRecordsToAdd = GetArraySize(g_hAllMaxSpeed);
			}
			else
			{
				actualAmountOfMapRecordsToAdd = minimumAmountOfMapRecordsToAdd;
			}
		}
		else
		{
			actualAmountOfMapRecordsToAdd = amountOfHigherRecordsInCurrentMap;
		}
		
		// Add the amount of records of the current map to add
		for (new i=0; i<actualAmountOfMapRecordsToAdd; i++)
		{
			
			// Get the topspeed data
			GetArrayString(g_hAllName, i, clientName, sizeof(clientName));
			GetArrayString(g_hAllSteamId, i, clientSteamId, sizeof(clientSteamId));
			GetArrayString(g_hAllMaxSpeedTimeStamp, i, topspeedTimeStamp, sizeof(topspeedTimeStamp));
			topspeed = Float:GetArrayCell(g_hAllMaxSpeed, i);
			
			// Add it to the dynamic arrays
			PushArrayString(g_hHighestOverallSteamId, clientSteamId);
			PushArrayString(g_hHighestOverallName, clientName);
			PushArrayCell(g_hHighestOverallMaxSpeed, topspeed);
			PushArrayString(g_hHighestOverallMaxSpeedTimeStamp, topspeedTimeStamp);
			PushArrayString(g_hHighestOverallMapName, g_sCurrentMap);
		}
		
		// Sort the dynamic arrays
		SortHighestOverallRecords();
		
		// Now show the records
		ShowHighestOverallMain(clientCurrent, true);
	}
}

/**
* Save all the new and updated records to the database.
*/
stock SaveMapRecords()
{
	
	// Temporary declarations
	decl String:clientSteamId[MAX_STEAMAUTH_LENGTH];
	decl String:clientName[MAX_NAME_LENGTH];
	decl String:topspeedTimeStamp[20];
	decl Float:topspeed;
	decl String:sQuery[256], String:sError[255];
	
	// Get the amount of current game/session records for the loop
	new sessionSize = GetArraySize(g_hSessionName);
	
	// Loop across all game/session records
	for (new i=0; i<sessionSize; i++)
	{
	
		// Check if the record is new or better then previous by checking the booleans
		if (GetArrayCell(g_hSessionNewRecord, i) || GetArrayCell(g_hSessionHigherRecord, i))
		{
			// Get the current client steam id and name and make the name safe for database use
			GetArrayString(g_hSessionName, i, clientName, sizeof(clientName));
			GetArrayString(g_hSessionSteamId, i, clientSteamId, sizeof(clientSteamId));
			ReplaceString(clientName, sizeof(clientName), "'", "", false);
			
			// Get the speedrecord and its timestamp
			topspeed = Float:GetArrayCell(g_hSessionMaxSpeedGame, i);
			GetArrayString(g_hSessionMaxSpeedGameTimeStamp, i, topspeedTimeStamp, sizeof(topspeedTimeStamp));
			
			// Distinguish a new record from an updated record
			if (GetArrayCell(g_hSessionNewRecord, i))
			{
				// New record, verify that the client authentication is not empty and the speed is higher then 0
				if (clientSteamId[0] && topspeed > 0)
				{
					// Create the SQL insert query
					FormatEx(sQuery, sizeof(sQuery), "INSERT INTO topspeed (map, auth, name, speed, timestamp) VALUES ('%s', '%s', '%s', %f, '%s');", g_sCurrentMap, clientSteamId, clientName, topspeed, topspeedTimeStamp);
					
					// Lock the database for usage and create a handle to activate the query
					SQL_LockDatabase(g_hSQL);
					new Handle:hQuery = SQL_Query(g_hSQL, sQuery);
					
					// Easy debug
					// PrintToServer("############# INSERT RECORD #############");
					// PrintToServer("%s %s %f %s", clientSteamId, clientName, topspeed, topspeedTimeStamp);
					// PrintToServer("############# ------------- #############");
					
					if (hQuery == INVALID_HANDLE)
					{
						// Something went wrong, log the error and unlock the database
						SQL_GetError(g_hSQL, sError, sizeof(sError));
						LogError("%s: SQL error on insert: %s", PLUGIN_NAME, sError);
						SQL_UnlockDatabase(g_hSQL);
						return;
					}
					
					// Unlock the database for usage and close the handle
					SQL_UnlockDatabase(g_hSQL); 
					CloseHandle(hQuery);
				}
			}
			else if (GetArrayCell(g_hSessionHigherRecord, i))
			{
				// Higher record, update the topspeed and current name, create the SQL update query
				FormatEx(sQuery, sizeof(sQuery), "UPDATE topspeed SET name = '%s', speed = %f, timestamp = '%s' WHERE map = '%s' AND auth = '%s';", clientName, topspeed, topspeedTimeStamp, g_sCurrentMap, clientSteamId);
				
				// Lock the database for usage and create a handle to activate the query
				SQL_LockDatabase(g_hSQL);
				new Handle:hQuery = SQL_Query(g_hSQL, sQuery);
				
				// Easy debug
				// PrintToServer("############# UPDATE RECORD #############");
				// PrintToServer("%s %s %f %s", clientSteamId, clientName, topspeed, topspeedTimeStamp);
				// PrintToServer("############# ------------- #############");
				
				if (hQuery == INVALID_HANDLE)
				{
					// Something went wrong, log the error and unlock the database
					SQL_GetError(g_hSQL, sError, sizeof(sError));
					LogError("%s: SQL error on update: %s", PLUGIN_NAME, sError);
					SQL_UnlockDatabase(g_hSQL);
					return;
				}
				
				// Unlock the database for usage and close the handle
				SQL_UnlockDatabase(g_hSQL); 
				CloseHandle(hQuery);
			}
		}
		else
		{
			// Client already had a higher record
		}
	}
}

/**
* Delete a given speedrecord in the database, a steam id can only have records based on timestamps, it's the most accurate way besides deleting on IDs.
*/
stock DeleteMapRecord(String:clientSteamId[], String:topspeedTimeStamp[])
{
	
	// Temporary declaration
	decl String:sQuery[448];
	
	// Easy debug
	// PrintToServer("############# DELETE RECORD #############");
	// PrintToServer("%s %s", clientSteamId, topspeedTimeStamp);
	// PrintToServer("############# ------------- #############");
	
	// Create the SQL delete query
	FormatEx(sQuery, sizeof(sQuery), "DELETE FROM topspeed WHERE auth = '%s'AND timestamp = '%s'", clientSteamId, topspeedTimeStamp);
	
	// Activate the query
	SQL_TQuery(g_hSQL, DeleteMapRecordCallback, sQuery, _);
}

/**
* Callback function for deleting a record.
*/
public DeleteMapRecordCallback(Handle:owner, Handle:hQuery, const String:sError[], any:clientCurrent)
{
	if (hQuery == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: SQL error on deleting a speedrecord: %s", PLUGIN_NAME, sError);
		return;
	}
}

/**
* Delete all speedrecords of a given map in the database.
*/
stock DeleteMapRecords(String:map[])
{
	
	// Temporary declaration
	decl String:sQuery[448];
	
	// Easy debug
	// PrintToServer("############# DELETE RECORDS #############");
	// PrintToServer("all map records %s", map);
	// PrintToServer("############# -------------- #############");
	
	// Create the SQL insert query
	FormatEx(sQuery, sizeof(sQuery), "DELETE FROM topspeed WHERE map = '%s'", map);
	
	// Activate the query
	SQL_TQuery(g_hSQL, DeleteMapRecordsCallback, sQuery, _);
}

/**
* Callback function for deleting all records.
*/
public DeleteMapRecordsCallback(Handle:owner, Handle:hQuery, const String:sError[], any:clientCurrent)
{
	if (hQuery == INVALID_HANDLE)
	{
		// Something went wrong, log the error
		LogError("%s: SQL error on deleting speedrecords: %s", PLUGIN_NAME, sError);
		return;
	}
}