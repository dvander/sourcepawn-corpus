// Roleplay Classes by Natalya
// This lets server owners set up player classes for a Roleplay Server.
// The classes can also be teamed together like police and city government would be on one team.
// Furthermore, this lets other plugins look at a player's class to determine priveleges.
// This also sets up a basic bank system.
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

// RP Includes
#include <roleplay_classes>
#undef REQUIRE_PLUGIN
#include <roleplay_cars>

new bool:car_menu = false;

#define	RP_CLASS_VERSION	"1.09A GO"
#define	CMD_RESPAWN			"respawn"
#define	WPN_KNFE			"weapon_knife"
#define	MAX_SPAWNS			256
#define	MAX_CELLS			32
#define	GAME_UNKNOWN		0
#define GAME_CSTRIKE		1
#define	GAME_DOD			2

new game = GAME_UNKNOWN;

// Definitions:
#define	MAXDOORS			2048
#define	MAXTEAMS			20
#define	MAXCLASSES			256
#define	CMD_DOORINFO		"info"
#define	CMD_DOOR_OWN		"own"
#define	CMD_DOORTEAM		"team"
#define	CMD_DOORCLSS		"class"
#define	CMD_DOORPLYR		"player"
#define	CMD_DOOR4FIT		"forfeit"
// #define	BEER			"models/props_junk/garbage_glassbottle003a.mdl"

// Variables:
static Locked[MAXDOORS];
static OwnsDoor[MAXPLAYERS+1][MAXDOORS];
static AccessDoor[MAXPLAYERS+1][MAXDOORS];
new String:DoorSteam[MAXDOORS][35];
new String:AccessTeam[MAXTEAMS][MAXDOORS];
new String:AccessClass[MAXCLASSES][MAXDOORS];
new door_group[MAXDOORS];
new group_doors[100][50];
new String:group_name[100][64];
new doorAmount[MAXPLAYERS+1];
new printerAmount[MAXPLAYERS+1];
new save_time = 0;
new printerMoney[2048];

// Misc:
static bool:PrethinkBuffer[33];

// Thanks to GreyScale for this one:
new offsPunchAngle;
new Handle:g_DoorMenu = INVALID_HANDLE;
new Handle:g_DAccPMenu = INVALID_HANDLE;
new Handle:g_PrinterPrice = INVALID_HANDLE;
new Handle:g_SpecialMenu = INVALID_HANDLE;
new Handle:g_Cvar_Enable = INVALID_HANDLE;
new Handle:g_Cvar_ATMUse = INVALID_HANDLE;
new Handle:g_Cvar_Respawn_Time = INVALID_HANDLE;
new Handle:g_Cvar_TeamMode = INVALID_HANDLE;
new Handle:g_Cvar_Database = INVALID_HANDLE;
new Handle:g_Cvar_Debug = INVALID_HANDLE;

new Handle:db_rp = INVALID_HANDLE;
new Handle:g_Door_Price = INVALID_HANDLE;
new Handle:g_Door_Tax = INVALID_HANDLE;
new Handle:g_TeamMenu = INVALID_HANDLE;
new Handle:g_VIPTeamMenu = INVALID_HANDLE;
new Handle:h_warrant_timer = INVALID_HANDLE;
new Handle:g_PayTimer = INVALID_HANDLE;
new Handle:g_Class_Delay = INVALID_HANDLE;
new Handle:g_TimerLength = INVALID_HANDLE;
new Handle:g_DefaultTeam = INVALID_HANDLE;
new Handle:g_DefaultClass = INVALID_HANDLE;
new Handle:h_drunk_a = INVALID_HANDLE;
new Handle:h_drunk_b = INVALID_HANDLE;

new String:authid[MAXPLAYERS+1][35];
new money[MAXPLAYERS+1];
new bank[MAXPLAYERS+1];
new saws[MAXPLAYERS+1];
new printer_owner[2048];
new h_class_changeable[MAXPLAYERS+1];
new Handle:h_refuck_timer = INVALID_HANDLE;
new h_respawnable[MAXPLAYERS+1];
new Handle:g_PrinterMax = INVALID_HANDLE;
new Handle:g_VIPPrinterMax = INVALID_HANDLE;
new Handle:spawnkv;
new Handle:cellkv;
new Handle:doorkv;
new Handle:doormodekv;
new Handle:g_PrinterMoney = INVALID_HANDLE;

// Spawn Mode
new Handle:spawnmodekv;
public bool:InSpawnMode;
new SpawnModeAdmin;
new SMSpawns;
new Float:g_SpawnModeLoc[MAX_SPAWNS][3];
new SelectedSpawn;

// Progress Bar
new g_flProgressBarStartTime;
new g_iProgressBarDuration;

// Thanks to BAILOPAN for this
new Handle:g_useSpawns = INVALID_HANDLE;
public bool:g_useSpawns2 = true;
new g_SpawnQty = 0;
new Float:g_SpawnLoc[MAX_SPAWNS][3];
new g_SpawnTeam[MAX_SPAWNS];
new g_SpawnClass[MAX_SPAWNS];
new class_spawns[MAXCLASSES];
new g_CellQty = 0;
new Float:g_CellLoc[MAX_CELLS][3];

// Player Info Arrays
new player_gender[MAXPLAYERS+1];
new player_cash_or_dd[MAXPLAYERS+1];
new player_salary[MAXPLAYERS+1];
new player_team[MAXPLAYERS+1];
new player_class[MAXPLAYERS+1];
public bool:IsCuffed[MAXPLAYERS+1];
public bool:Warranted[MAXPLAYERS+1];
public bool:AtATM[MAXPLAYERS+1];
public bool:AtGas[MAXPLAYERS+1];
public bool:AtVend[MAXPLAYERS+1];
new Drunk[MAXPLAYERS+1];
new DrunkTime[MAXPLAYERS+1];
new changing_class[MAXPLAYERS+1];
new selected_door[MAXPLAYERS+1];
new just_joined[MAXPLAYERS+1];
new player_respawn_wait[MAXPLAYERS+1];
new targeted_player[MAXPLAYERS+1];
new uncuffing_target[MAXPLAYERS+1];

// Class Info Arrays
new String:team_name[MAXTEAMS+1][35];
new team_vip[MAXTEAMS+1];
new String:class_name[MAXCLASSES+1][35];
new String:class_model_f[MAXCLASSES+1][256];
new String:class_model_m[MAXCLASSES+1][256];
new class_team[MAXCLASSES+1];
new class_teamed[MAXCLASSES+1];
new class_salary[MAXCLASSES+1];
new team_index = 0;
new class_index = 0;
new class_limit[MAXCLASSES+1];
new class_alcohol[MAXCLASSES+1];
new class_assassination[MAXCLASSES+1];
new class_authority[MAXCLASSES+1];
new class_players[MAXCLASSES+1];
new selected_ent[MAXCLASSES+1];

// Player Loading to Database
public bool:InQuery;
public bool:IsDisconnect[33];
public bool:Loaded[33];
public bool:IsPrinter[2048];

public bool:InDoorMode;
new DoorModeAdmin;
new DMDoors;
new DMDoorGroups;
new SelectedDoor;

new players_printers[MAXPLAYERS+1][4];
new started = 0;


// Team Mode stuff...
new team_points[MAXTEAMS+1];
public bool:team_competing[MAXTEAMS+1];
new team_turn_count = 0;
new winning[MAXTEAMS+1];

// Player Name 
/* new String:first_name[MAXPLAYERS+1][35];
new String:last_name[MAXPLAYERS+1][35]; */

public Plugin:myinfo =
{
	name = "CS:GO Roleplay Mod LN Edition",
	author = "Natalya",
	description = "CS:GO RP LN Class Menu",
	version = RP_CLASS_VERSION,
	url = "http://www.lady-natalya.info/"
};


public OnPluginStart()
{
	//Admin Commands:
	RegConsoleCmd("sm_door", DoorMenu, " - Open the door menu.");
	RegConsoleCmd("sm_ent", CommandEnt, "<Name> - Entity Info");
	RegConsoleCmd("sm_attach", CommandParent, "<Name> - Parent an Entity to another Entity");
	RegConsoleCmd("sm_special", Command_Special, " -- Open the Special Menu.");
	RegConsoleCmd("sm_bank", Command_Bank, " -- Bank Menu");
	RegConsoleCmd("sm_banque", Command_Bank, " -- Menu Banque");
	RegConsoleCmd("sm_class", Command_Class, " -- Choose a Class.");
	RegConsoleCmd("sm_classe", Command_Class, " -- Ouvrir le menu Classe.");
	RegConsoleCmd("sm_class_info", Command_Class_Info, " -- Find info about your Class.");
	RegConsoleCmd("sm_debitcard", Command_Debit, " -- Use a Debit Card to give money to a player.");
	RegConsoleCmd("sm_rp_settings", Command_Settings, " -- Change your RP settings.");
	RegConsoleCmd("sm_demote", Command_Demote, " -- Demote a Player.");
	RegConsoleCmd("sm_cuff", Command_cuff, "- Cuffs a player");
	RegConsoleCmd("sm_uncuff", Command_UnCuff, "- Takes handcuffs off of a player");
	RegConsoleCmd("sm_warrant", Command_Warrant, "- Warrants a player for Arrest");
	RegConsoleCmd("sm_rp", Command_RP, "RP Super Menu");
	RegConsoleCmd("sm_givecash", Command_Cash, "-- Give cash to a player.");

	RegAdminCmd("sm_givedoor", CommandGiveDoor, ADMFLAG_CUSTOM3, "<Name> - Gives the door to a player");
	RegAdminCmd("sm_takedoor", CommandTakeDoor, ADMFLAG_CUSTOM3, "<Name> - Takes the door from a player");
	RegAdminCmd("rp_info", CommandInfo, ADMFLAG_CUSTOM3, "Prints Plugin Info to an Admin");
	RegAdminCmd("rp_money", CommandMoney, ADMFLAG_CUSTOM3, "Admin Money Command");
	RegAdminCmd("rp_door_reload", CommandDoorReload, ADMFLAG_CUSTOM3, "Reload Doors");
	RegAdminCmd("rp_door_mode", CommandDoorMode, ADMFLAG_CUSTOM3, "Register Doors");
	RegAdminCmd("rp_player_info", Command_Info, ADMFLAG_CUSTOM3, "Find a player's information.");
	RegAdminCmd("rp_force_save", Command_Save, ADMFLAG_CUSTOM3, "Force DB Save of a Player");
	RegAdminCmd("rp_db_save", Command_DBSave, ADMFLAG_CUSTOM3, "Force Server DB Save");
	RegAdminCmd("rp_spawn_mode", CommandSpawnMode, ADMFLAG_CUSTOM3, "Set up custom spawn points.");
	RegAdminCmd("rp_spawn_reload", CommandSpawnReload, ADMFLAG_CUSTOM3, "Reload custom spawns.");
	
	
	AddCommandListener(Say_Team, "say_team");
	AddCommandListener(Say, "say");

	CreateConVar("rp_version",RP_CLASS_VERSION,"Roleplay Mod Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Class_Delay		= CreateConVar("rp_class_interval", "180.0", "Time in seconds between class switches.", FCVAR_PLUGIN, true, 5.0);
	g_Cvar_Enable		= CreateConVar("rp_classes_enabled", "1", " Enable/Disable Roleplay Classes", FCVAR_PLUGIN);
	g_DefaultClass		= CreateConVar("rp_default_class", "4", "Default class to spawn as. (0 - 255)", FCVAR_PLUGIN);
	g_DefaultTeam		= CreateConVar("rp_default_team", "1", "Default team to spawn on. (0 - 19)", FCVAR_PLUGIN);
	g_Door_Price		= CreateConVar("rp_door_price", "75", "Price to buy a door.", FCVAR_PLUGIN);
	g_Door_Tax			= CreateConVar("rp_door_tax", "50", "Tax on door ownership.", FCVAR_PLUGIN);
	g_PrinterPrice		= CreateConVar("rp_printer_price", "750", "Printers cost this much money.", FCVAR_PLUGIN);
	g_PrinterMax		= CreateConVar("rp_printer_max", "3", "You can have this many printers.", FCVAR_PLUGIN);
	g_VIPPrinterMax		= CreateConVar("rp_vip_printer_max", "4", "VIPs can have this many printers.", FCVAR_PLUGIN);
	g_PrinterMoney		= CreateConVar("rp_printer_money", "150", "Printers give out this much money.", FCVAR_PLUGIN);
	g_TimerLength		= CreateConVar("rp_pay_interval", "300.0", "Time in seconds between pay periods.", FCVAR_PLUGIN, true, 5.0);
	g_useSpawns			= CreateConVar("rp_spawns_enabled", "1", "Use custom spawn locations?", FCVAR_PLUGIN);
	g_Cvar_ATMUse 		= CreateConVar("rp_atm_enabled", "1", "Use map ATMs?  Set to 0 if no ATMs in map.", FCVAR_PLUGIN);
	g_Cvar_Respawn_Time	= CreateConVar("rp_respawn_delay", "20", "Delay before a player can respawn.", FCVAR_PLUGIN);
	g_Cvar_TeamMode 	= CreateConVar("rp_team_mode", "0", "Team Competition?  Use competing key in classes.ini to decide which teams participate.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_Cvar_Database 	= CreateConVar("rp_db_mode", "0", "DB Location 1 = remote or 2 = local -- 0 = failure", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Debug 		= CreateConVar("rp_debug_mode", "0", "Use 1 to turn Debug messages on or 0 to turn them off.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

	decl String:gdir[PLATFORM_MAX_PATH];
	GetGameFolderName(gdir, sizeof(gdir));
	if (StrEqual(gdir,"cstrike",false))		game = GAME_CSTRIKE;	else
	if (StrEqual(gdir,"dod",false))			game = GAME_DOD;		else	game = GAME_UNKNOWN;

	LoadTranslations("plugin.class_menu");
	LoadTranslations("common.phrases");

	HookEntityOutput("trigger_multiple","OnStartTouch",OnStartTouch);
	HookEntityOutput("trigger_multiple","OnEndTouch",OnEndTouch);

	//Server Variable:
	CreateConVar("door_version", "2.0", "Doors Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Class File
	ReadClassFile();
	// Door File
	ReadDoorFile(0);
	// Spawn File
	ReadSpawnFile(0);
	// Cell File
	ReadCellFile();	
	
	offsPunchAngle = FindSendPropInfo("CBasePlayer", "m_vecPunchAngle");	

	new def_class = GetConVarInt(g_DefaultClass);
	new def_team = GetConVarInt(g_DefaultTeam);
	for (new i = 0; i <= class_index; i++)
	{
		class_players[i] = 0;
	}
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			PrintToServer("[DEBUG] %N Retro-Active Loading -- #%i", client, client);
			Loaded[client] = false;
			CreateTimer(1.0, CreateSQLAccount, client);
			PrintToServer("[DEBUG] %N Retro-Active Loaded -- #%i", client, client);
			
			h_class_changeable[client] = 1;
			h_respawnable[client] = 1;
			AtATM[client] = false;
			AtGas[client] = false;
			AtVend[client] = false;
			changing_class[client] = 0;
			just_joined[client] = 1;
			
			player_class[client] = def_class;
			player_team[client] = def_team;
			targeted_player[client] = -1;
			class_players[def_class] += 1;
			
			if (money[client] < 0)
			{
				money[client] = 0;
				new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
				SetEntData(client, MoneyOffset, 0, 4, true);	
			}
			if (bank[client] < 0)
			{
				bank[client] = 0;
			}
	
			if (IsPlayerAlive(client))
			{
				FakeClientCommand(client, "kill");
			}
			h_class_changeable[client] = 1;
			h_respawnable[client] = 1;
			uncuffing_target[client] = -1;
		}
	}
	/*
	PrecacheSound("doors/latchunlocked1.wav", false);
	PrecacheSound("doors/default_locked.wav", false);
	PrecacheSound("buttons/button2.wav", false);
	PrecacheSound("buttons/button3.wav", false);
	PrintToServer("[RP] Class Menu Plugin Load Event Finished");
	*/
	DoorModeAdmin = -1;
	InDoorMode = false;
	
	// Spawn Mode
	SpawnModeAdmin = -1;
	InSpawnMode = false;
	
	// Thanks here go to Bacardi
	new Handle:mp_startmoney = INVALID_HANDLE;
	mp_startmoney = FindConVar("mp_startmoney");

	if(mp_startmoney != INVALID_HANDLE)
	{
		SetConVarBounds(mp_startmoney, ConVarBound_Lower, false);
	}
	team_turn_count = 0;
	ServerCommand("mp_startmoney 0");
	HookConVarChange(g_Cvar_TeamMode, convarchangecallback);

	// Handcuff Breaking Timer
	g_flProgressBarStartTime = FindSendPropOffs("CCSPlayer", "m_flProgressBarStartTime");
	if(g_flProgressBarStartTime == -1)
		SetFailState("Couldnt find the m_flProgressBarStartTime offset!");
	g_iProgressBarDuration = FindSendPropOffs("CCSPlayer", "m_iProgressBarDuration");
	if(g_iProgressBarDuration == -1)
		SetFailState("Couldnt find the m_iProgressBarDuration offset!");
}
public convarchangecallback(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new value = (StringToInt(newValue));
	SetConVarInt(g_Cvar_TeamMode, value, false, true);
	return;
}
public OnAllPluginsLoaded()
{
	car_menu = LibraryExists("car_menu");
}
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "car_menu"))
	{
		car_menu = false;
	}
}
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "car_menu"))
	{
		car_menu = true;
	}
}


// #######
// NATIVES
// #######



public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[],  err_max)
{
	PrintToServer("[RP] Loading Natives");
	CreateNative("IsClientHandcuffed", NativeIsClientHandcuffed);
	CreateNative("GetClientBank", NativeGetClientBank);
	CreateNative("SetClientBank", NativeSetClientBank);
	CreateNative("SetClientMoney", NativeSetClientMoney);
	CreateNative("SetCarOwnership", NativeSetCarOwnership);
	CreateNative("SetLockedState", NativeSetLockedState);
	CreateNative("GetLockedState", NativeGetLockedState);
	CreateNative("GetClientClass", NativeGetClientClass);
	CreateNative("GetClientRPTeam", NativeGetClientRPTeam);
	PrintToServer("[RP] Natives Loaded");
	RegPluginLibrary("class_menu");
	return APLRes_Success;
}
// native functions
public NativeIsClientHandcuffed(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    return IsCuffed[client];
}
public NativeGetClientBank(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return bank[client];
}
public NativeSetClientBank(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new amount = GetNativeCell(2);
	bank[client] = amount;
	return;
}
public NativeSetClientMoney(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new amount = GetNativeCell(2);
	money[client] = amount;
	return;
}
public NativeSetCarOwnership(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new car = GetNativeCell(2);
	new ownership = GetNativeCell(3);
	OwnsDoor[client][car] = ownership;
	return;
}
public NativeSetLockedState(Handle:plugin, numParams)
{
	new entity = GetNativeCell(1);
	new locked = GetNativeCell(2);
	Locked[entity] = locked;
	return;
}
public NativeGetLockedState(Handle:plugin, numParams)
{
	new entity = GetNativeCell(1);
	return Locked[entity];
}
public NativeGetClientClass(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return player_class[client];
}
public NativeGetClientRPTeam(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return player_team[client];
}


// #############
// PLUGIN EVENTS
// #############



public OnPluginEnd()
{
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{
			GetClientAuthId(client, AuthId_Engine, authid[client], sizeof(authid[]));
			DBSave(client);
			PrintToServer("[RP] Plugin Ending -- updating client in SQL Database.", authid[client]);
			LogMessage("[RP] Plugin Ending -- updating client in SQL Database.", authid[client]);
		}
	}
	
	UnhookEntityOutput("trigger_multiple","OnStartTouch",OnStartTouch);
	UnhookEntityOutput("trigger_multiple","OnEndTouch",OnEndTouch);
}
public OnMapStart()
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		HookEvent("player_spawn", PlayerSpawnEvent);
		HookEvent("player_death", PlayerDeathEvent);
		g_TeamMenu = BuildTeamMenu();
		g_VIPTeamMenu = BuildVIPTeamMenu();
		g_SpecialMenu = BuildSpecialMenu();
		g_DoorMenu = BuildDoorMenu();
		PrintToServer("[RP] Map Start Menu Building completed.");

		// Set up the pay timer thing.
		new Float:interval[1];
		interval[0] = GetConVarFloat(g_TimerLength);
		g_PayTimer = CreateTimer(interval[0], Pay_Time, INVALID_HANDLE, TIMER_REPEAT);	
	}
	PrecacheSound("doors/latchunlocked1.wav", false);
	PrecacheSound("doors/default_locked.wav", false);
	PrecacheSound("buttons/button2.wav", false);
	PrecacheSound("buttons/button3.wav", false);
	ReadDoorFile(0);
	ReadSpawnFile(0);
	ReadCellFile();
	
	// Spawn Mode
	SpawnModeAdmin = -1;
	InSpawnMode = false;

	if (GetConVarInt(g_Cvar_TeamMode))
	{
		PrintToServer("[RP] Team Competition Mode Enabled");
	}
	else
	{
		PrintToServer("[RP] Team Competition Mode Disabled");
	}
	PrintToServer("[RP] Setting Start Money to 0 in 5 seconds...");
	CreateTimer(5.0, FUCKING_STARTMONEY_0);

	// This handles the database mode.
	if (started == 0)
	{
		new db_mode = GetConVarInt(g_Cvar_Database);
		if (db_mode == 0)
		{
			CreateTimer(1.0, FUCKING_DB_MODE_NOT_0);
		}
		else InitializeRPDB();
	}

	if (GetConVarInt(g_Cvar_Debug))
	{
		PrintToServer("[RP Debug] Server Running in Debug Mode");
		PrintToServer("[RP Debug] rp_debug_mode = 1");
		PrintToServer("[RP Debug] Set rp_debug_mode to 0 to disable most debug messages.");
	}


	for (new i_t = 0; i_t <= team_index; i_t++)
	{
		team_points[i_t] = 0;
	}
	new def_class = GetConVarInt(g_DefaultClass);
	new def_team = GetConVarInt(g_DefaultTeam);
	for (new i = 0; i <= class_index; i++)
	{
		class_players[i] = 0;
	}
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{ 	
			player_class[client] = def_class;
			player_team[client] = def_team;
			class_players[def_class] += 1;
			changing_class[client] = 0;
			selected_ent[client] = -1;
			printerAmount[client] = 0;
		}
	}

	PrintToServer("[RP] Class Menu Map Start Event Finished");
}
public Action:FUCKING_DB_MODE_NOT_0(Handle:Timer, any:client)
{
	new db_mode = GetConVarInt(g_Cvar_Database);
	if (db_mode == 0)
	{
		PrintToChatAll("\x03[RP] rp_db_mode is 0 -- set it to 1 or 2");
		CreateTimer(1.0, FUCKING_DB_MODE_NOT_0);
	}
	else InitializeRPDB();
}
public Action:FUCKING_STARTMONEY_0(Handle:Timer, any:client)
{
	ServerCommand("mp_startmoney 0");
	PrintToServer("[RP] mp_startmoney should now be 0");
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new maxclients = GetMaxClients();
	if ((victim != 0) && (attacker != 0) && (victim <= maxclients) && (attacker <= maxclients))
    {
		if (IsClientInGame(victim))
		{
			if (IsClientInGame(attacker))
			{
				if ((GetClientTeam(victim) == 2) && (GetClientTeam(attacker) == 3))
				{
					if ((IsPlayerAlive(victim)) && (attacker == inflictor))
					{
						decl String:WeaponName[30];
						GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));					
						if(StrEqual(WeaponName, "weapon_knife", false))
						{
							if(!Warranted[victim])
							{
								if(IsCuffed[victim])
								{
									IsCuffed[victim] = false;
									UnCuff(victim);					
								}
								else if(!IsCuffed[victim])
								{
									IsCuffed[victim] = true;
									Cuff(victim);								
								}
							}
							if(Warranted[victim])
							{
								new teleport_here = GetRandomInt(0, g_CellQty);
								TeleportEntity(victim, g_CellLoc[teleport_here], NULL_VECTOR, NULL_VECTOR);
								PrintToChat(victim, "\x04Cell = %i  x = %f   y = %f   z = %f", teleport_here, g_CellLoc[teleport_here][0], g_CellLoc[teleport_here][1], g_CellLoc[teleport_here][2]);
						 		new String:Name[64];
								Warranted[victim] = false;
								Cuff(victim);

								GetClientName(victim, Name, sizeof(Name));
								PrintToChatAll("\x03[RP] %T", "Arrested", LANG_SERVER, Name);
							}
							damage = 0.0;
							return Plugin_Changed;
						}
					}
				}
				else if ((GetClientTeam(victim) == 3) && (GetClientTeam(attacker) == 3))
				{
					if (attacker != victim)
					{
							// CT Friendly Fire
							damage = 0.0;
							return Plugin_Changed;
					}
				}
			}
		}
		if (damagetype & DMG_VEHICLE)
		{
			new String:ClassName[30];
			GetEdictClassname(inflictor, ClassName, sizeof(ClassName));
			if (StrEqual("prop_vehicle_driveable", ClassName, false))
			{
				new Driver = GetEntPropEnt(inflictor, Prop_Send, "m_hPlayer");
				if (Driver != -1)
				{
					attacker = Driver;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Changed;
}
public OnPropPhysBreak(const String:output[], caller, activator, Float:delay)
{
	new owner = printer_owner[caller];

	if (owner > 0)
	{
		if (IsClientConnected(owner))
		{
			printerAmount[owner] -= 1;
			for (new index = 0; index < 4; index++)
			{
				if (players_printers[owner][index] == caller)
				{
					players_printers[owner][index] = 0;
					break;
				}
			}
		}
		else printerAmount[owner] = 0;
	}
	else printerAmount[owner] = 0;
	
	if (0 < activator <= MaxClients)
	{
		if (IsPlayerAlive(activator))
		{
			new print_inc = GetConVarInt(g_PrinterMoney);
			new printercash = (printerMoney[caller] * print_inc);
			if (printercash <= 0)
			{
				printercash = 150;
			}
			
			PrintToChat(activator, "\x03[RP] %T", "Money_Printer_Broken", activator, printercash);
			new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			money[activator] = GetEntData(activator, MoneyOffset, 4);
			money[activator] += printercash;
			if (money[activator] > 65535)
			{
				money[activator] = 65535;
			}
			SetEntData(activator, MoneyOffset, money[activator], 4, true);
		}
	}
	printer_owner[caller] = 0;
	IsPrinter[caller] = false;
	printerMoney[caller] = 0;
	return;
}
public OnMapEnd()
{
	team_turn_count = 0;
	for (new i_t = 0; i_t <= team_index; i_t++)
	{
		team_points[i_t] = 0;
	}
	new def_class = GetConVarInt(g_DefaultClass);
	new def_team = GetConVarInt(g_DefaultTeam);
	for (new i = 0; i <= class_index; i++)
	{
		class_players[i] = 0;
	}
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{ 	
			player_class[client] = def_class;
			player_team[client] = def_team;
			class_players[def_class] += 1;
			selected_ent[client] = -1;
		}
	}
	if (g_PayTimer != INVALID_HANDLE)
	{
		CloseHandle(g_PayTimer);
		g_PayTimer = INVALID_HANDLE;
	}
	if (h_warrant_timer != INVALID_HANDLE)
	{
		CloseHandle(h_warrant_timer);
		h_warrant_timer = INVALID_HANDLE;
	}
	if (h_refuck_timer != INVALID_HANDLE)
	{
		CloseHandle(h_refuck_timer);
		h_refuck_timer = INVALID_HANDLE;
	}
	if (g_TeamMenu != INVALID_HANDLE)
	{
		CloseHandle(g_TeamMenu);
		g_TeamMenu = INVALID_HANDLE;
	}
	if (g_VIPTeamMenu != INVALID_HANDLE)
	{
		CloseHandle(g_VIPTeamMenu);
		g_VIPTeamMenu = INVALID_HANDLE;
	}
	if (g_SpecialMenu != INVALID_HANDLE)
	{
		CloseHandle(g_SpecialMenu);
		g_SpecialMenu = INVALID_HANDLE;
	}
	if (g_DoorMenu != INVALID_HANDLE)
	{
		CloseHandle(g_DoorMenu);
		g_DoorMenu = INVALID_HANDLE;
	}
	if (g_DAccPMenu != INVALID_HANDLE)
	{
		CloseHandle(g_DAccPMenu);
		g_DAccPMenu = INVALID_HANDLE;
	}
	if (h_drunk_a != INVALID_HANDLE)
	{
		CloseHandle(h_drunk_a);
		h_drunk_a = INVALID_HANDLE;
	}
	if (h_drunk_b != INVALID_HANDLE)
	{
		CloseHandle(h_drunk_b);
		h_drunk_b = INVALID_HANDLE;
	}
	if (doormodekv != INVALID_HANDLE)
	{
		CloseHandle(doormodekv);
		doormodekv = INVALID_HANDLE;
	}
	UnhookEvent("player_spawn", PlayerSpawnEvent);
	UnhookEvent("player_death", PlayerDeathEvent);
}



// #############
// CLIENT EVENTS
// #############



public bool:OnClientConnect(client, String:Reject[], Len)
{
	PrintToServer("[RP] %N Connected -- #%i", client, client);
	Loaded[client] = false;
	targeted_player[client] = -1;
	doorAmount[client] = 0;
	printerAmount[client] = 0;
	if (GetConVarInt(g_Cvar_Debug))
	{
		PrintToServer("[RP Debug] OnClientConnect completed for %N -- #%i", client, client);
	}
	return true;
}
public OnclientPutInServer(client)
{
	PrintToServer("[RP] %N Put In Server -- #%i", client, client);
	if (GetConVarInt(g_Cvar_Enable))
	{
		//Defaults:
		player_team[client] = -1;
		player_class[client] = -1;				
		AtATM[client] = false;
		AtGas[client] = false;
		AtVend[client] = false;
		selected_door[client] = -1;
		doorAmount[client] = 0;
		printerAmount[client] = 0;
		IsCuffed[client] = false;
		Warranted[client] = false;
		changing_class[client] = 0;
		selected_ent[client] = -1;
		h_class_changeable[client] = 1;
		h_respawnable[client] = 1;
		just_joined[client] = 1;
	}
	if (GetConVarInt(g_Cvar_Debug))
	{
		PrintToServer("[RP Debug] OnclientPutInServer completed for %N -- #%i", client, client);
	}
}
public Action:CreateSQLAccount(Handle:Timer, any:client)
{
	if (GetConVarInt(g_Cvar_Debug))
	{
		PrintToServer("[RP Debug] Attempting CreateSQLAccount for %N -- #%i", client, client);
	}
	if (IsClientInGame(client))
	{
		if (GetConVarInt(g_Cvar_Debug))
		{
			PrintToServer("[RP Debug] CreateSQLAccount: %N is in game.", client, client);
		}
		new String:SteamId[64];
		GetClientAuthId(client, AuthId_Engine, SteamId, 64);
	
		if(StrEqual(SteamId, "") || InQuery)
		{
			CreateTimer(1.0, CreateSQLAccount, client);
		}
		else
		{			
			// InQuery stops it from loading more than one player at a time.
			InQuery = true;
			InitializeClientonDB(client);
		}
	}
}
public OnClientPostAdminCheck(client)
{
	PrintToServer("[RP] %N Post Admin Check -- #%i", client, client);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	new t = GetConVarInt(g_DefaultTeam);
	new c = GetConVarInt(g_DefaultClass);	
	player_team[client] = t;
	player_class[client] = c;
	player_salary[client] = class_salary[c];
	class_players[c] += 1;
	
	h_respawnable[client] = 1;
	h_class_changeable[client] = 1;
	CreateTimer(1.0, Respawn_Time_B, client);
	player_respawn_wait[client] = 10;

	GetClientAuthId(client, AuthId_Engine, authid[client], sizeof(authid[]));
	
	for(new X = 0; X < MAXDOORS; X++)
	{
		//Clear:
		OwnsDoor[client][X] = 0;
		if (IsValidEntity(X))
		{
			new match = (StrContains(DoorSteam[X], authid[client], false));
			if (match > -1)
			{
				OwnsDoor[0][X] = 0;
				OwnsDoor[client][X] = 1;
			}
		}
	}/*
	CreateTimer(1.0, CreateSQLAccount, client);*/
	if (GetConVarInt(g_Cvar_Debug))
	{
		PrintToServer("[RP Debug] OnClientPostAdminCheck completed for %N -- #%i", client, client);
	}
}
public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	ServerCommand("mp_startmoney 0");
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		uncuffing_target[client] = -1;
		if (!Loaded[client])
		{
			if (GetConVarInt(g_Cvar_Debug))
			{
				PrintToServer("[DEBUG] %N Timer 3 ...", client);
			}
			CreateTimer(1.0, CreateSQLAccount, client);
			if (GetConVarInt(g_Cvar_Debug))
			{
				PrintToServer("[DEBUG] %N Timer 3 Created", client);
			}
		}
 		if (IsPlayerAlive(client))
 		{	
			IsCuffed[client] = false;
			Warranted[client] = false;
			AtATM[client] = false;
			AtGas[client] = false;
			AtVend[client] = false;
			Drunk[client] = 0;
			selected_ent[client] = -1;
			selected_door[client] = -1;
			new c = player_class[client];
			new t = player_team[client];
			
			if (c == -1)
			{
				c = GetConVarInt(g_DefaultClass);
				t = GetConVarInt(g_DefaultTeam);
				player_class[client] = c;
				player_team[client] = t;
			}
			else
			{
				new String:gender[16];
				if (player_gender[client] == 0)
				{
					Format(gender, sizeof(gender), "Female");
				}
				if(player_gender[client] == 1)
				{
					Format(gender, sizeof(gender), "Male");
				}
				PrintToChat(client, "\x03[RP] %T", "Your_Class", client, class_name[c]);
				PrintToChat(client, "\x03[RP] %T", "Your_Team", client, team_name[t]);
				if (GetConVarInt(g_Cvar_TeamMode))
				{
					if (team_competing[t])
					{
						PrintToChat(client, "\x03[RP] %T", "Team_Mode_On", client);
					}
				}
				new String:tag_str[32];
				Format(tag_str, sizeof(tag_str), "[%s]", team_name[t]);
				CS_SetClientClanTag(client, tag_str);
			}
			
			
			if((player_team[client] == 0) && (IsPlayerAlive(client)))
			{
				CS_SwitchTeam(client, 3);
			} else CS_SwitchTeam(client, 2);
			SetEntProp(client, Prop_Data, "m_iDeaths", player_team[client]);

			if (money[client] < 0)
			{
				money[client] = 0;
			}
			if (bank[client] < 0)
			{
				bank[client] = 0;
			}
			new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			SetEntData(client, MoneyOffset, money[client], 4, true);

            // Now choose model according to gender.  Assume male if not chosen.
			if (player_gender[client] == 1)
            {
				if (!StrEqual(class_model_m[c],""))
				{
					if (IsModelPrecached(class_model_m[c]))
					{
						SetEntityModel(client, class_model_m[c]);
					}
					else if (!IsModelPrecached(class_model_m[c]))
					{
						PrecacheModel(class_model_m[c]);
						SetEntityModel(client, class_model_m[c]);
					}
				}
				if (StrEqual(class_model_m[c],""))
				{
					PrintToChat(client, "\x03[RP DEBUG] Your player model was not registered at plugin start.");
					LogMessage("[RP Debug] Error in classes.ini for model_m of %s.", class_name[c]);
				}
     		}
			else if (player_gender[client] == 0)
            {
				if (!StrEqual(class_model_f[c],""))
				{
					if (IsModelPrecached(class_model_f[c]))
					{
						SetEntityModel(client, class_model_f[c]);
					}
					else if (!IsModelPrecached(class_model_f[c]))
					{
						PrecacheModel(class_model_f[c]);
						SetEntityModel(client, class_model_f[c]);
					}
				}
				if (StrEqual(class_model_f[c],""))
				{
					PrintToChat(client, "\x03[RP DEBUG] Your player model was not registered at plugin start.");
					LogMessage("[RP Debug] Error in classes.ini for model_f of %s.", class_name[c]);
				}		
     		}

			// If custom spawns are enabled and there is a custom spawn config, teleport them to a spawn for their team.
			if ((GetConVarInt(g_useSpawns)) && (g_useSpawns2 = true))
			{
				new spawn_here = -1;
				if (class_spawns[c] > 0)
				{
					do
					{
						spawn_here = GetRandomInt(0, g_SpawnQty);

					} while (g_SpawnClass[spawn_here] != c);
				}
				else
				{
					do
					{
						spawn_here = GetRandomInt(0, g_SpawnQty);

					} while (g_SpawnTeam[spawn_here] != t);
				}
				TeleportEntity(client, g_SpawnLoc[spawn_here], NULL_VECTOR, NULL_VECTOR);
			}
			
			new plyr_gun1 = GetPlayerWeaponSlot(client, 1);
			new plyr_gun2 = GetPlayerWeaponSlot(client, 2);
			// We now know the player's guns.  Let's figure out if we give a knife to them or not.
			if (IsValidEntity(plyr_gun1))
			{
				RemovePlayerItem(client, plyr_gun1);
				RemoveEdict(plyr_gun1);
			}
			if (!IsValidEntity(plyr_gun2))
			{
				GivePlayerItem(client, WPN_KNFE);
			}
			new String:fuck[64];
			GetClientName(client, fuck, sizeof(fuck));
			
			h_refuck_timer = CreateTimer(0.4, Respawn_Time_Fuck, client);			
		}
		CreateTimer(0.1, HudRolePlay, client);
	}
}
public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (killer > 0)
		{
			if (IsClientInGame(killer))
			{
				if (killer != client)
				{
					if ((GetClientTeam(killer) == 2) && (GetClientTeam(client) == 3))
					{
						money[killer] = GetEntData(killer, MoneyOffset, 4);
						money[killer] -= 300;
						SetEntData(killer, MoneyOffset, money[killer], 4, true);
					}
					else if ((GetClientTeam(killer) == 3) && (GetClientTeam(client) == 2))
					{
						money[killer] = GetEntData(killer, MoneyOffset, 4);
						money[killer] -= 300;
						SetEntData(killer, MoneyOffset, money[killer], 4, true);
					}
					else if ((GetClientTeam(killer) == 2) && (GetClientTeam(client) == 2))
					{
						money[killer] = GetEntData(killer, MoneyOffset, 4);
						money[killer] += 3300;
						SetEntData(killer, MoneyOffset, money[killer], 4, true);
					}
					else if ((GetClientTeam(killer) == 3) && (GetClientTeam(client) == 3))
					{
						money[killer] = GetEntData(killer, MoneyOffset, 4);
						money[killer] += 3300;
						SetEntData(killer, MoneyOffset, money[killer], 4, true);
					}					
				}
			}
		}
		if (IsClientInGame(client))
		{		
			money[client] = GetEntData(client, MoneyOffset, 4);
			if (money[client] < 0)
			{
				money[client] = 0;
			}
			
			AtATM[client] = false;
			AtGas[client] = false;
			AtVend[client] = false;

			if (player_team[client] == 0)
			{
				CS_SwitchTeam(client, 3);
			}	else CS_SwitchTeam(client, 2);
			
			new c = player_class[client];

			if (c > -1)
			{
				if (class_assassination[c] == 1)
				{
					if (class_players[c] > 0)
					{
						class_players[c] -= 1;
					}
					new t_index = GetConVarInt(g_DefaultTeam);
					new c_index = GetConVarInt(g_DefaultClass);	
				
					player_team[client] = t_index;
					player_class[client] = c_index;
					player_salary[client] = class_salary[c_index];
					class_players[c_index] += 1;
				
					PrintToChat(client, "\x03[RP] %T", "ASSASSINATION", client, class_name[c_index]);

					if (h_class_changeable[client] == 1)
					{
						new Float:time[1];
						time[0] = GetConVarFloat(g_Class_Delay);
						h_class_changeable[client] = 0;
						CreateTimer(time[0], Respawn_Time, client);
					}
				}
				CS_SetClientClanTag(client, "[DEAD]");
			}
			new r_time = GetConVarInt(g_Cvar_Respawn_Time);
			if (r_time > 0)
			{
				h_respawnable[client] = 0;
				CreateTimer(1.0, Respawn_Time_B, client);
			
				player_respawn_wait[client] = r_time;
			}
			CancelClientMenu(client, true, INVALID_HANDLE);

			new AdminId:admin = GetUserAdmin(client);
			if (admin != INVALID_ADMIN_ID)
			{
				h_class_changeable[client] = 1;
			}
		}
	}
}
public OnClientDisconnect(client)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		selected_door[client] = -1;

		// Take their doors.
		if (doorAmount[client] > 0)
		{
			//Defaults:
			for(new X = 0; X < MAXDOORS; X++)
			{
				//Clear:
				OwnsDoor[client][X] = 0;
				if (StrEqual(DoorSteam[X], authid[client], false))
				{
					OwnsDoor[0][X] = 1;
				}
			}
		}
		doorAmount[client] = 0;

		if (printerAmount[client] > 0)
		{
			for (new index = 0; index <= 2048; index++)
			{
				if (IsValidEdict(index))
				{
					if (IsValidEntity(index))
					{
						new String:ClassName[64];
						GetEdictClassname(index, ClassName, 255);
						if ((StrEqual(ClassName, "prop_physics")) || (StrEqual(ClassName, "prop_physics_multiplayer")) || (StrEqual(ClassName, "prop_physics_override")))
						{
							if (IsPrinter[index])
							{
								new String:targetname[64];
								GetTargetName(index, targetname, sizeof(targetname));
								if(StrEqual(targetname, authid[client], false))
								{
									IsPrinter[index] = false;
									AcceptEntityInput(index,"Kill");
								}
							}
						}
					}
				}
			}
			players_printers[client][0] = 0;
			players_printers[client][1] = 0;
			players_printers[client][2] = 0;
			players_printers[client][3] = 0;
		}
		printerAmount[client] = 0;
		DBSave(client);
		IsDisconnect[client] = true;
		Loaded[client] = false;
		if (DoorModeAdmin == client)
		{
			InDoorMode = false;
			DoorModeAdmin = -1;
			CloseHandle(doormodekv);
			// May need to reset Door Mode stuff here?
		}
		if (SpawnModeAdmin == client)
		{
			InSpawnMode = false;
			SpawnModeAdmin = -1;
			CloseHandle(spawnmodekv);
			// May need to reset Spawn Mode stuff here?
		}
	}
}



// ##############
// BANK FUNCTIONS
// ##############




public Menu_Bank(Handle:atm, MenuAction:action, param1, param2)
{
	// User has walked up to an ATM
	if (action == MenuAction_Select)
	{
		if(GetConVarInt(g_Cvar_ATMUse))
		{
			if (AtATM[param1] == false)
			{
				PrintToChat(param1, "\x03[RP] %T", "Go_To_ATM", param1);
				return;			
			}
		}
		if(!IsPlayerAlive(param1))
		return;
		if(!IsClientInGame(param1))
		return;
		
		new String:info[32];
		GetMenuItem(atm, param2, info, sizeof(info));

		if (StrEqual(info, "deposit"))
		{
			new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			money[param1] = GetEntData(param1, MoneyOffset, 4);
			if (money[param1] <= 0)
			{
				PrintToChat(param1, "\x03[RP] %T", "No_Money_To_Deposit", param1);
				return;					
			}
			
			new Handle:temp_menu_bank = CreateMenu(Menu_Deposit);
			new String:title_str[64];
			new String:all_cash_str[32];
			Format(title_str, sizeof(title_str), "%T", "Deposit_Amount", param1);
			Format(all_cash_str, sizeof(all_cash_str), "%T", "All_Cash", param1);

			if (money[param1] >= 100)
			{
				AddMenuItem(temp_menu_bank, "100", "$100");
			}
			if (money[param1] >= 200)
			{
				AddMenuItem(temp_menu_bank, "200", "$200");
			}
			if (money[param1] >= 500)
			{
				AddMenuItem(temp_menu_bank, "500", "$500");
			}
			if (money[param1] >= 1000)
			{
				AddMenuItem(temp_menu_bank, "1000", "$1000");
			}
			if (money[param1] >= 2000)
			{
				AddMenuItem(temp_menu_bank, "2000", "$2000");
			}
			if (money[param1] >= 5000)
			{
				AddMenuItem(temp_menu_bank, "5000", "$5000");
			}
			
			AddMenuItem(temp_menu_bank, "all", all_cash_str);
			SetMenuTitle(temp_menu_bank, title_str);
			DisplayMenu(temp_menu_bank, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info, "withdraw"))
		{
			if (bank[param1] <= 0)
			{
				PrintToChat(param1, "\x03[RP] %T", "No_Money_To_Withdraw", param1);
				return;					
			}
			
			new Handle:temp_menu_bank = CreateMenu(Menu_Withdraw);
			new String:title_str[64];
			new String:max_out_str[32];
			Format(title_str, sizeof(title_str), "%T", "Withdraw_Amount", param1);
			Format(max_out_str, sizeof(max_out_str), "%T", "Max_Out", param1);
			
			if (bank[param1] >= 100)
			{
				AddMenuItem(temp_menu_bank, "100", "$100");
			}
			if (bank[param1] >= 200)
			{
				AddMenuItem(temp_menu_bank, "200", "$200");
			}
			if (bank[param1] >= 500)
			{
				AddMenuItem(temp_menu_bank, "500", "$500");
			}
			if (bank[param1] >= 1000)
			{
				AddMenuItem(temp_menu_bank, "1000", "$1000");
			}
			if (bank[param1] >= 2000)
			{
				AddMenuItem(temp_menu_bank, "2000", "$2000");
			}
			if (bank[param1] >= 5000)
			{
				AddMenuItem(temp_menu_bank, "5000", "$5000");
			}
			AddMenuItem(temp_menu_bank, "all", max_out_str);	
			SetMenuTitle(temp_menu_bank, title_str);
			DisplayMenu(temp_menu_bank, param1, MENU_TIME_FOREVER);
		}
	}
	return;
}
public Menu_Deposit(Handle:temp_menu_bank, MenuAction:action, param1, param2)
{
	// User has selected to deposit money
	if (action == MenuAction_Select)
	{
		if(!IsClientInGame(param1))
		return;
		if(!IsPlayerAlive(param1))
		return;
		if(GetConVarInt(g_Cvar_ATMUse))
		{
			if (AtATM[param1] == false)
			{
				PrintToChat(param1, "\x03[RP] %T", "Go_To_ATM", param1);
				return;			
			}
		}
	}
	if (param1 <= 0)
	{
		return;
	}	
	new String:info[32];
	GetMenuItem(temp_menu_bank, param2, info, sizeof(info));
	new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	money[param1] = GetEntData(param1, MoneyOffset, 4);
	
	if(StrEqual(info,"all"))
	{
		bank[param1] += money[param1];
		money[param1] = 0;
		SetEntData(param1, MoneyOffset, 0, 4, true);
		PrintToChat(param1, "\x03[RP] %T", "Bank", param1, bank[param1]);
		return;
	}
	
	new deposit_amt = StringToInt(info, 10);
	// Thanks here go to Cancer for his bug testing efforts.
	if (deposit_amt < 0)
	{
		PrintToChat(param1, "\x03[RP] You can't deposit a negative amount.  Stop trying to cheat.");
		return;
	}
	if (money[param1] >= deposit_amt)
	{
		if (param1 == 0)
		{
			return;
		}
		bank[param1] += deposit_amt;
		PrintToChat(param1, "\x03[RP] %T", "Bank", param1, bank[param1]);

		money[param1] -= deposit_amt;
		SetEntData(param1, MoneyOffset, money[param1], 4, true);
	}
	return;
}
public Menu_Withdraw(Handle:temp_menu_bank, MenuAction:action, param1, param2)
{
	// User has selected to withdraw money
	if (param1 <= 0)
	{
		return;
	}
	if(!IsClientInGame(param1))
	return;
	if(!IsPlayerAlive(param1))
	return;
	if (action == MenuAction_Select)
	{
		if(GetConVarInt(g_Cvar_ATMUse))
		{
			if (AtATM[param1] == false)
			{
				PrintToChat(param1, "\x03[RP] %T", "Go_To_ATM", param1);
				return;			
			}
		}
	}
	if (param1 <= 0)
	{
		return;
	}	

	new String:info[32];
	GetMenuItem(temp_menu_bank, param2, info, sizeof(info));
	new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	money[param1] = GetEntData(param1, MoneyOffset, 4);
	
	new difference = (65535 - money[param1]);
	
	if(StrEqual(info,"all"))
	{
		new wallet = (money[param1] + bank[param1]);
		if (wallet <= 65535)
		{
			money[param1] = wallet;
			SetEntData(param1, MoneyOffset, wallet, 4, true);
			PrintToChat(param1, "\x03[RP] %T", "Withdrew_All", param1);
			bank[param1] = 0;
			return;
		}
		if (wallet > 65535)
		{
			bank[param1] -= difference;
			SetEntData(param1, MoneyOffset, 65535, 4, true);
			PrintToChat(param1, "\x03[RP] %T", "Withdrew", param1, difference);
			return;
		}
		return;
	}
	new withdraw_amt = StringToInt(info, 10);
	if (withdraw_amt > bank[param1])
	{
		PrintToChat(param1, "\x03[RP] Invalid Transaction.");
		return;		
	}
	new final_cash = (withdraw_amt + money[param1]);
	if (final_cash <= 65535)
	{
		bank[param1] -= withdraw_amt;
		money[param1] = final_cash;
		SetEntData(param1, MoneyOffset, final_cash, 4, true);
		PrintToChat(param1, "\x03[RP] %T", "Withdrew", param1, withdraw_amt);
	}
	if (final_cash > 65535)
	{
		bank[param1] -= difference;
		SetEntData(param1, MoneyOffset, 65535, 4, true);	
		PrintToChat(param1, "\x03[RP] %T", "Withdrew", param1, difference);
		return;
	}
	return;
}
public OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	if (activator > 0 && activator <= MaxClients)
	{
		if(caller == -1)
			return;
		if(!IsPlayerAlive(activator))
			return;
		if(!IsClientInGame(activator))
			return;
		if(GetConVarInt(g_Cvar_ATMUse))
		{
			new String:classname[64];
			new String:targetname[64];
		
			GetEdictClassname(caller,classname,sizeof(classname));
			if(StrEqual(classname,"trigger_multiple"))
			{
				GetTargetName(caller,targetname,sizeof(targetname));
				if(StrEqual(targetname,"atm"))
				{
					AtATM[activator] = true;

					new Handle:atm = CreateMenu(Menu_Bank);
					new String:title_str[32], String:deposit_str[32], String:withdraw_str[32];
				
					Format(title_str, sizeof(title_str), "%T", "ATM_Menu", activator);
					Format(deposit_str, sizeof(deposit_str), "%T", "Deposit", activator);
					Format(withdraw_str, sizeof(withdraw_str), "%T", "Withdraw", activator);
				
					AddMenuItem(atm,"deposit", deposit_str);
					AddMenuItem(atm,"withdraw", withdraw_str);
					SetMenuTitle(atm, title_str);

					DisplayMenu(atm, activator, MENU_TIME_FOREVER);							
					PrintToChat(activator, "\x03[RP] %T", "Bank", activator, bank[activator]);
				}
				else if(StrEqual(targetname,"gas"))
				{			
					AtGas[activator] = true;
				}
				else if(StrEqual(targetname,"vend"))
				{			
					AtVend[activator] = true;
				}
			}
		}
	}
	return;
}
public OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	if (0 < activator <= MaxClients)
	{
		if(caller == -1)
			return;
		if(!IsClientInGame(activator))
			return;
		if(!IsPlayerAlive(activator))
			return;

		new String:classname[64];
		new String:targetname[64];
			
		GetEdictClassname(caller,classname,sizeof(classname));
		if(StrEqual(classname,"trigger_multiple"))
		{
			GetTargetName(caller,targetname,sizeof(targetname));
			if(StrEqual(targetname,"atm"))
			{
				if(GetConVarInt(g_Cvar_ATMUse))
				{
					AtATM[activator] = false;
				}
			}
			else if(StrEqual(targetname,"gas"))
			{
				AtGas[activator] = false;
			}
			else if(StrEqual(targetname,"vend"))
			{
				AtVend[activator] = false;
			}
		}
	}
	return;
}
public Action:Command_Debit(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
 		if (!IsPlayerAlive(client))
 		{
			PrintToChat(client, "\x04[RP] %T", "Youre_Dead", client);
			return Plugin_Handled;
		}			
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		if (args <= 0)
		{
			PrintToChat(client, "\x03[RP] Usage: sm_debitcard 'amount'");
			return Plugin_Handled;
		}
 		if (IsPlayerAlive(client))
 		{
			PrintToChat(client, "\x03[RP] %T", "Bank", client, bank[client]);
			new debit_amt = StringToInt(arg1, 10);
			if (debit_amt < 0)
			{
				PrintToChat(client, "\x03[RP] You can't debit someone a negative amount.  Stop trying to cheat.");
				return Plugin_Handled;
			}
			if (debit_amt > bank[client])
			{
				PrintToChat(client, "\x03[RP] You don't have enough money in your bank account for this transaction.");
				return Plugin_Handled;
			}
			//Declare:
			decl Ent;
			decl String:ClassName[255];
			//Initialize:
			Ent = GetClientAimTarget(client, false);

			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "player"))
				{
					bank[Ent] += debit_amt;
					bank[client] -= debit_amt;
					PrintToChat(client, "\x03[RP] %T", "You_Debited", client, debit_amt, bank[client]);
					PrintToChat(client, "\x03[RP] %N %T", "You_Got_Credited", Ent, client, debit_amt, bank[Ent]);
					return Plugin_Handled;
				}
				else PrintToChat(client, "\x03[RP] %T", "Look", client);
			}
			else PrintToChat(client, "\x03[RP] %T", "Look", client);
  		}
  		else PrintToChat(client, "\x04[RP] %T", "Youre_Dead", client);
	}
	else PrintToChat(client, "\x04[RP] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Command_Cash(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
 		if (!IsPlayerAlive(client))
 		{
			PrintToChat(client, "\x04[RP] %T", "Youre_Dead", client);
			return Plugin_Handled;
		}			
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		if (args <= 0)
		{
			PrintToChat(client, "\x03[RP] Usage: sm_givecash 'amount'");
			return Plugin_Handled;
		}
 		if (IsPlayerAlive(client))
 		{
			new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			money[client] = GetEntData(client, MoneyOffset, 4);
			
			new debit_amt = StringToInt(arg1, 10);
			if (debit_amt < 0)
			{
				PrintToChat(client, "\x03[RP] You can't give someone a negative amount.  Stop trying to cheat.");
				return Plugin_Handled;
			}
			if (debit_amt > money[client])
			{
				PrintToChat(client, "\x03[RP] %T.", "Expensive", client);
				return Plugin_Handled;
			}
			
			//Declare:
			decl Ent;
			decl String:ClassName[255];
			//Initialize:
			Ent = GetClientAimTarget(client, false);

			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "player"))
				{
					new total_cash = (money[Ent] + debit_amt);
					if (total_cash > 65535)
					{
						new difference = (total_cash - 65535);
						debit_amt -= difference;
					}
					
					money[Ent] += debit_amt;
					SetEntData(Ent, MoneyOffset, money[Ent], 4, true);
					
					money[client] -= debit_amt;
					SetEntData(client, MoneyOffset, money[client], 4, true);

					new String:receiver[32];
					new String:giver[32];					
					Format(receiver, sizeof(receiver), "%N", Ent);
					Format(giver, sizeof(giver), "%N", client);
					
					PrintToChat(client, "\x03[RP] %T", "Gave", client, debit_amt, receiver);
					PrintToChat(client, "\x03[RP] %T", "Got", Ent, debit_amt, giver);
					return Plugin_Handled;
				}
				else PrintToChat(client, "\x03[RP] %T", "Look", client);
			}
			else PrintToChat(client, "\x03[RP] %T", "Look", client);
  		}
  		else PrintToChat(client, "\x04[RP] %T", "Youre_Dead", client);
	}
	else PrintToChat(client, "\x04[RP] %T", "Disabled", client);
	return Plugin_Handled;
}



// #########
// ARRESTING
// #########



public Action:Command_cuff(client, Args)
{
	// Only Government can use this.
	if (GetClientTeam(client) != 3)
	{
		PrintToChat(client, "\x03[RP] You can't use this command unless you are on the Government team.");
		return Plugin_Handled;
	}
	if (IsPlayerAlive(client))
	{
		//Declare:
		decl Player;
		decl String:ClassName[255];

		//Initialize:
		Player = GetClientAimTarget(client, true);

		//Valid:
		if(Player != -1)
		{
			//Class Name:
			GetEdictClassname(Player, ClassName, 255);

			//Valid:
			if(StrEqual(ClassName, "player"))
			{
				if (GetClientTeam(Player) != 3)
				{
					// Is the cop close enough?
					decl Float:cop_vec[3], Float:plyr_vec[3], Float:dist_vec;

					GetClientAbsOrigin(client, cop_vec);
					GetClientAbsOrigin(Player, plyr_vec);
					dist_vec = GetVectorDistance(cop_vec, plyr_vec, false);

					if (dist_vec < 96)
					{
						decl String:PlayerName[32], String:clientName[32];
						Cuff(Player);

						//HP:
						SetEntityHealth(Player, 100);
						GetClientName(client, clientName, sizeof(clientName));
						GetClientName(Player, PlayerName, sizeof(PlayerName));
						//Print:

						new String:sname[80];
						GetClientName(client, sname, 80);
						LogMessage("%s cuff %s", sname, PlayerName);
						PrintToChat(client, "\x03 [RP] Got him. %s is now cuffed.",PlayerName);
						PrintToChat(Player, "\x03 [RP] You are handcuffed by %s.",clientName);
      				}
					else PrintToChat(client, "\x03 [RP] You are not close enough to cuff this player.");
				}
				else PrintToChat(client, "\x03 [RP] You can't use this command on Government members.");
			}
			else PrintToChat(client, "\x03 [RP] You must look at a player to use this command.");
		}
		else PrintToChat(client, "\x03 [RP] You must look at a player to use this command.");
	}
	return Plugin_Handled;
}
public Action:Command_UnCuff(client, Args)
{
	// Only Government can use this.
	if (GetClientTeam(client) != 3)
	{
		PrintToChat(client, "\x03[RP] You can't use this command unless you are on the Government team.");
		return Plugin_Handled;
	}
	if (IsPlayerAlive(client))
	{
		//Declare:
		decl Player;
		decl String:ClassName[255];

		//Initialize:
		Player = GetClientAimTarget(client, true);

		//Valid:
		if(Player != -1)
		{
			//Class Name:
			GetEdictClassname(Player, ClassName, 255);

			//Valid:
			if(StrEqual(ClassName, "player"))
			{
				if (GetClientTeam(Player) != 3)
				{
					// Is the cop close enough?
					decl Float:cop_vec[3], Float:plyr_vec[3], Float:dist_vec;

					GetClientAbsOrigin(client, cop_vec);
					GetClientAbsOrigin(Player, plyr_vec);
					dist_vec = GetVectorDistance(cop_vec, plyr_vec, false);

					if (dist_vec < 64)
					{
						decl String:PlayerName[32], String:clientName[32];
						UnCuff(Player);

						//HP:
						SetEntityHealth(Player, 100);
						GetClientName(client, clientName, sizeof(clientName));
						GetClientName(Player, PlayerName, sizeof(PlayerName));
						//Print:

						new String:sname[80];
						GetClientName(client, sname, 80);
						LogMessage("%s cuff %s", sname, PlayerName);
						PrintToChat(client, "\x03 [RP] You took the handcuffs off of %s.",PlayerName);
						PrintToChat(Player, "\x03 [RP] You are uncuffed by %s.",clientName);
      				}
					else PrintToChat(client, "\x03 [RP] You are not close enough to uncuff this player.");
				}
				else PrintToChat(client, "\x03 [RP] You can't use this command on Government members.");
			}
			else PrintToChat(client, "\x03 [RP] You must look at a player to use this command.");
		}
		else PrintToChat(client, "\x03 [RP] You must look at a player to use this command.");
	}
	return Plugin_Handled;
}
public Cuff(client)
{
	uncuffing_target[client] = -1;
	decl String:fuck[64];
	GetClientName(client, fuck, sizeof(fuck));

	//Speed:
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.5);

	//Cuff:
	IsCuffed[client] = true;
	selected_ent[client] = -1;

 	if (IsPlayerAlive(client))
 	{
		// Are they carrying?
		new plyr_gun0 = GetPlayerWeaponSlot(client, 0);
		new plyr_gun1 = GetPlayerWeaponSlot(client, 1);
		new plyr_gun2 = GetPlayerWeaponSlot(client, 2);
		new plyr_gun3 = GetPlayerWeaponSlot(client, 3);
		if (IsValidEntity(plyr_gun0))
		{
			RemovePlayerItem(client, plyr_gun0);
			RemoveEdict(plyr_gun0);
		}
		if (IsValidEntity(plyr_gun1))
		{
			RemovePlayerItem(client, plyr_gun1);
			RemoveEdict(plyr_gun1);
		}
		if (IsValidEntity(plyr_gun2))
		{
			RemovePlayerItem(client, plyr_gun2);
			RemoveEdict(plyr_gun2);
		}
		if (IsValidEntity(plyr_gun3))
		{
			RemovePlayerItem(client, plyr_gun3);
			RemoveEdict(plyr_gun3);
		}
		new String:fuck2[32];
		GetClientName(client, fuck2, sizeof(fuck2));
		ServerCommand("sm_hp \"%s\" 100", fuck2);
		SetEntityRenderColor(client, 255, 100, 100, 255);
	}
}
public UnCuff(client)
{
	decl String:fuck[32];
	GetClientName(client, fuck, sizeof(fuck));

	//Speed:
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);

	//Cuff:
	IsCuffed[client] = false;
	selected_ent[client] = -1;

	new plyr_gun2 = GetPlayerWeaponSlot(client, 2);
	if (!IsValidEntity(plyr_gun2))
	{
		GivePlayerItem(client, "weapon_knife", 0);
	}

	SetEntityRenderColor(client, 255, 255, 255, 255);
}
public Action:Command_Warrant(client, Arguments)
{
	// Only Government can use this.
	if (GetClientTeam(client) != 3)
	{
		PrintToChat(client, "\x03[RP] You can't use this command unless you are on the Government team.");
		return Plugin_Handled;
	}

	//Arguments:
	if(Arguments < 1)
	{

		//Print:
		PrintToConsole(client, "[RP] Usage: sm_warrant <Name>");

		//Return:
		return Plugin_Handled;
	}
	//Declare:
	decl MaxPlayers, Player;
	decl String:PlayerName[32];

	//Initialize:
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));

	//Find:
	MaxPlayers = GetMaxClients();
	for(new X = 1; X <= MaxPlayers ; X++)
	{

		//Connected:
		if(!IsClientConnected(X)) continue;

		//Declare:
		decl String:Name[32];

		//Initialize:
		GetClientName(X, Name, sizeof(Name));

		//Save:
		if(StrContains(Name, PlayerName, false) != -1) Player = X;
	}

	//Invalid Name:
	if(Player <= 0)
	{

		//Print:
		PrintToConsole(client, "[RP] Could not find client %s", PlayerName);

		//Return:
		return Plugin_Handled;
	}
	else if(!IsClientInGame(Player))
	{
		PrintToConsole(client, "[RP] Could not find client %s", PlayerName);
		return Plugin_Handled;
	}
	
	//Declare:
	decl String:Name[32];

	//Name:
	GetClientName(Player, Name, 32);


	if (IsPlayerAlive(client))
	{
		new c = player_class[client];
		if (class_authority[c] == 1)
		{
			if (!Warranted[Player])
			{
				Warranted[Player] = true;
				PrintToChat(client, "\x03[RP] You put out a warrant for the arrest of %s.", Name);
				PrintToChat(Player, "\x03[RP] There is a warrant for your arrest.");
				PrintToChatAll("\x03[RP] A warrant for the arrest of %s has been put out.", Name);

				h_warrant_timer = CreateTimer(300.0, Warrant_Time, Player);

				return Plugin_Handled;
			}
			else if (Warranted[Player])
			{
				Warranted[Player] = false;
				PrintToChat(client, "\x03[RP] You lifted the warrant off of %s.", Name);
				PrintToChat(Player, "\x03[RP] There is no longer a warrant for your arrest.");
				PrintToChatAll("\x03[RP] The warrant for the arrest of %s has been cancelled.", Name);
				return Plugin_Handled;
			}
		}
		else PrintToChat(client, "\x03[RP] You can't use this command unless you are the highest ranking player on the %s team.", team_name[0]);
		return Plugin_Handled;
	}
	else PrintToChat(client, "\x04[RP] %T", "Youre_Dead", client);
	return Plugin_Handled;
}
public Action:Warrant_Time(Handle:timer, any:Player)
{
	if (!Warranted[Player])
	{
		return;
	}
	else if (Warranted[Player])
	{
		Warranted[Player] = false;
		if((IsClientConnected(Player)) && (IsClientInGame(Player)))
		{
			PrintToChat(Player, "\x03[RP] There is no longer a warrant for your arrest.");
			return;
		}
	}
}



// ################
// REGULAR COMMANDS
// ################



public Action:CommandEnt(client, Arguments)
{
	decl Ent;
	//Ent:
	Ent = GetClientAimTarget(client, false);
	if (Ent == -1)
	{
		decl Float:_origin[3], Float:_angles[3];
		GetClientEyePosition( client, _origin );
		GetClientEyeAngles( client, _angles );

		new Handle:trace = TR_TraceRayFilterEx( _origin, _angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers );
		if( !TR_DidHit( trace ) )
		{
			PrintToChat(client, "\x03[RP]Unable to pick the current location.");
			return Plugin_Handled;
    	}
		decl Float:position[3];
		TR_GetEndPosition(position, trace);

		PrintToChat(client, "\x03[RP] Location: %f, %f, %f.", position[0], position[1], position[2]);
		return Plugin_Handled;
	}
	else
	{
		new String:targetname[64], String:ClassName[64];
		GetTargetName(Ent,targetname,sizeof(targetname));
		GetEdictClassname(Ent, ClassName, 255);
		PrintToChat(client, "\x04[Info] Entity #: %i Name: %s Type: %s", Ent, targetname, ClassName);
		if (StrEqual(ClassName, "prop_vehicle_driveable", false))
		{
			new Driver = GetEntPropEnt(Ent, Prop_Send, "m_hPlayer");
			if (Driver != -1)
			{
				new String:name[32];
				GetClientName(Driver, name, sizeof(name));
				PrintToChat(client, "\x03[RP] %T", "Driver", client, name);
			}
			else PrintToChat(client, "\x03[RP] %T", "No_Driver", client);
		}
		if ((StrEqual(ClassName, "prop_door_rotating", false)) || (StrEqual(ClassName, "func_door_rotating", false)))
		{
			PrintToChat(client, "\x03[RP] Door Steam: %s Group: %i   %i %i", DoorSteam[Ent], door_group[Ent], OwnsDoor[client][Ent], OwnsDoor[0][Ent]);
			decl String:hammerStr[32];
			new hammerInt = (GetEntProp(Ent, Prop_Data, "m_iHammerID", 32));
			IntToString(hammerInt, hammerStr, 32);
			PrintToChat(client, "\x03[RP] Hammer Id is %s.", hammerStr);
		}
	}
	return Plugin_Handled;
}
public Action:CommandInfo(client, Arguments)
{
	if (client != 0)
	{
		PrintToConsole(client, "[RP] Plugin Status Info");
		PrintToConsole(client, "[RP] Version: %s", RP_CLASS_VERSION);
		PrintToConsole(client, "[RP] Spawn Quantity: %i", g_SpawnQty);
		PrintToConsole(client, "[RP] Prison Cell Quantity: %i", g_CellQty);
		PrintToConsole(client, "[RP] Teams: %i", team_index);
		PrintToConsole(client, "[RP] You own %i doors.", doorAmount[client]);
		return Plugin_Handled;
	}
	if (client == 0)
	{
		PrintToServer("[RP] Plugin Status Info");
		PrintToServer("[RP] Version: %s", RP_CLASS_VERSION);
		PrintToServer("[RP] Spawn Quantity: %i", g_SpawnQty);
		PrintToServer("[RP] Prison Cell Quantity: %i", g_CellQty);
		PrintToServer("[RP] Teams: %i", team_index);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action:CommandParent(client, Arguments)
{
	if (IsClientInGame(client)) 
	{
		if (IsCuffed[client])
		{
			PrintToChat(client, "\x04[RP] %T", "Handcuffed", client);
			return Plugin_Handled;
		}
		if (!IsPlayerAlive(client))
		{
			PrintToChat(client, "\x04[RP] %T", "Youre_Dead", client);
			return Plugin_Handled;
		}

		decl Ent;
		//Ent:
		Ent = GetClientAimTarget(client, false);
		if (IsValidEntity(Ent))
		{
			new AdminId:admin = GetUserAdmin(client);
			if (admin == INVALID_ADMIN_ID)
			{
				new String:classname[32];
				GetEdictClassname(Ent, classname, 32);
				if (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_physics_multiplayer"))
				{
					new Handle:parentmenu = CreateMenu(Menu_Parent);
				
					new String:title_str[32];
					Format(title_str, sizeof(title_str), "Parent Entity #%i", Ent);
				
					AddMenuItem(parentmenu, "parent", "Attach to Aim Target");
					AddMenuItem(parentmenu, "detach", "Detach From Parent");
					SetMenuTitle(parentmenu, title_str);
				
					DisplayMenu(parentmenu, client, 20);
					selected_ent[client] = Ent;
					return Plugin_Handled;
				}
			}
			else
			{
				new String:classname[32];
				GetEdictClassname(Ent, classname, 32);
				if (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_physics_multiplayer"))
				{
					new Handle:parentmenu = CreateMenu(Menu_Parent);
				
					new String:title_str[32];
					Format(title_str, sizeof(title_str), "Parent Entity #%i", Ent);
				
					AddMenuItem(parentmenu, "parent", "Attach to Aim Target");
					AddMenuItem(parentmenu, "detach", "Detach From Parent");
					SetMenuTitle(parentmenu, title_str);
				
					DisplayMenu(parentmenu, client, 20);
					selected_ent[client] = Ent;
					return Plugin_Handled;
				}
				else if (StrEqual(classname, "prop_vehicle_driveable"))
				{
					new String:model[256];
					GetEntPropString(Ent, Prop_Data, "m_ModelName", model, sizeof(model));
					if (StrEqual(model, "models/natalya/vehicles/chair_s197_right.mdl", false))
					{				
						new Handle:parentmenu = CreateMenu(Menu_Parent);
				
						new String:title_str[32];
						Format(title_str, sizeof(title_str), "Attach Chair to Car");
				
						AddMenuItem(parentmenu, "parent", "Attach to Aim Target");
						AddMenuItem(parentmenu, "detach", "Detach From Car");
						SetMenuTitle(parentmenu, title_str);
				
						DisplayMenu(parentmenu, client, 20);
						selected_ent[client] = Ent;
						return Plugin_Handled;
					}
				}
			}
		}
		else PrintToChat(client, "\x03[RP] You must look at a prop to use this command.");
	}
	return Plugin_Handled;
}
public Menu_Parent(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (IsCuffed[param1])
		{
			PrintToChat(param1, "\x04[RP] %T", "Handcuffed", param1);
			return;
		}
		if (!IsPlayerAlive(param1))
		{
			PrintToChat(param1, "\x03[RP] You must be alive to use this command.");
			return;
		}
		new ent1 = selected_ent[param1];
		if (ent1 == -1)
		{
			if (!IsValidEntity(ent1))
			{
				return;
			}
			return;
		}
		
		// We have checked for all problems.  Let's do it!!
		
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"parent"))
		{
			decl ent2;
			ent2 = GetClientAimTarget(param1, false);
			if (IsValidEntity(ent2))
			{
				new String:classname[32];
				GetEdictClassname(ent2, classname, 32);
				new String:classname_e[32];
				GetEdictClassname(ent1, classname_e, 32);
				if (StrEqual(classname_e, "prop_vehicle_driveable"))
				{
					if (StrEqual(classname, "prop_vehicle_driveable"))
					{
						new String:targetname[64];
						GetTargetName(ent2,targetname,sizeof(targetname));
	
						SetVariantString(targetname);
						AcceptEntityInput(ent1, "SetParent", ent1, ent1, 0);
						SetVariantString("vehicle_feet_passenger1");					
						AcceptEntityInput(ent1, "SetParentAttachment", ent1, ent1, 0);
						return;
					}
					return;
				}
				else if (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_vehicle_driveable") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_physics_multiplayer"))
				{
					decl Float:PosVec1[3], Float:PosVec2[3];
					new Float:distance;
					
					GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", PosVec1);
					GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", PosVec2);

					distance = GetVectorDistance(PosVec1, PosVec2);
					if (distance > 256.0)
					{
						PrintToChat(param1, "\x04[RP] Sorry, the entities you selected are too far apart.");
						return;					
					}
					
					new String:targetname[64];
					GetTargetName(ent2,targetname,sizeof(targetname));
	
					SetVariantString(targetname);
					AcceptEntityInput(ent1, "SetParent", ent1, ent1, 0);

					PrintToChat(param1, "\x04[Info] Entity #%i was parented to %s.", ent1, targetname);
					return;
				}
				else if ((ent2 > 0) && (IsPlayerAlive(ent2)))
				{
					new AdminId:admin = GetUserAdmin(param1);
					if (admin == INVALID_ADMIN_ID)
					{
						new String:ent2_name[16];
						Format(ent2_name, sizeof(ent2_name), "%i", ent2);
						DispatchKeyValue(ent2, "targetname", ent2_name);
						DispatchSpawn(ent2);
						PrintToChat(param1, "\x04[Info] %s", ent2_name);
						
						new String:targetname[64];
						GetTargetName(ent2,targetname,sizeof(targetname)); 
	
						SetVariantString(ent2_name);
						AcceptEntityInput(ent1, "SetParent", ent2, ent1, 0);
						SetVariantString("forward");
						AcceptEntityInput(ent1, "SetParentAttachment", ent1, ent1, 0);

						PrintToChat(param1, "\x04[Info] Entity #%i was parented to %N.", ent1, ent2);
						return;					
					}
				}
				else PrintToChat(param1, "\x04[RP] Sorry, you can't attach anything to this object. (#%i)", ent2);
				return;
			}
		}
		if (StrEqual(info,"detach"))
		{
			new String:targetname[64];
			GetTargetName(ent1,targetname,sizeof(targetname));			

			SetVariantString(targetname);
			AcceptEntityInput(ent1, "SetParent", ent1, ent1, 0);

			PrintToChat(param1, "\x04[Info] Entity #%i was detached.", ent1);
			return;
		}
	}
	return;
}
public Action:Command_Info(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		// Make sure they are doing it right before we waste CPU on them.
		if (args < 1)
		{
			PrintToChat(client, "\x03[RP Error] Usage: rp_player_info <#userid|name>");
			return Plugin_Handled;
		}

		// We know the access level of the command user.  Let's find out about the target now.
		decl String:arg[65];
		GetCmdArg(1, arg, sizeof(arg));

		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		new targeted;
		for (new ib = 0; ib < target_count; ib++)
		{
			// Someone was matched by the command argument.
			if (IsClientInGame(target_list[ib]))
			{
				targeted = target_list[ib];
				new t = player_team[targeted];
				new c = player_class[targeted];
				if (client == 0)
				{
					PrintToServer("[RP Client Info] Player %N (%i)", targeted, targeted);
					PrintToServer("Money: %i", money[targeted]);
					PrintToServer("Bank: %i", bank[targeted]);
					PrintToServer("Saws: %i", saws[targeted]);
					PrintToServer("Sex: %i", player_gender[targeted]);
					PrintToServer("Direct Deposit: %i", player_cash_or_dd[targeted]);
					PrintToServer("Team: %s", team_name[t]);
					PrintToServer("Class: %s", class_name[c]);
				}
				else
				{
					PrintToChat(client, "[RP Client Info] Player %N (%i)", targeted, targeted);
					PrintToChat(client, "Money: %i", money[targeted]);
					PrintToChat(client, "Bank: %i", bank[targeted]);
					PrintToChat(client, "Saws: %i", saws[targeted]);
					PrintToChat(client, "Sex: %i", player_gender[targeted]);
					PrintToChat(client, "Direct Deposit: %i", player_cash_or_dd[targeted]);
					PrintToChat(client, "Team: %s", team_name[t]);
					PrintToChat(client, "Class: %s", class_name[c]);
				}
			}
		}
	}
	return Plugin_Handled;
}
public Action:Command_Save(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		// Make sure they are doing it right before we waste CPU on them.
		if (args < 1)
		{
			PrintToChat(client, "\x03[RP Error] Usage: rp_force_save <#userid|name>");
			return Plugin_Handled;
		}

		// We know the access level of the command user.  Let's find out about the target now.
		decl String:arg[65];
		GetCmdArg(1, arg, sizeof(arg));

		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		new targeted;
		for (new ib = 0; ib < target_count; ib++)
		{
			// Someone was matched by the command argument.  Let's find out who.
			if (IsClientInGame(target_list[ib]))
			{
				targeted = target_list[ib];
				if (Loaded[targeted])
				{
					PrintToServer("[RP] FS: %N (%i) Is Loaded", targeted, targeted);
				}
				Loaded[targeted] = false;
				CreateTimer(1.0, CreateSQLAccount, targeted);
				if (client == 0)
				{
					PrintToServer("[RP] Forced Save: %N (%i)", targeted, targeted);
				}
				else
				{
					PrintToChat(client, "[RP] Forced Save: %N (%i)", targeted, targeted);
				}
			}
		}
	}
	return Plugin_Handled;
}
public Action:Command_DBSave(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		for (new player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				DBSave(player);
			}
		}
	}
	if (client == 0)
	{
		PrintToServer("[RP] Server Forced DB Save");
	}
	else
	{
		PrintToChat(client, "[RP] %N Forced DB Save", client);
	}
	return Plugin_Handled;
}
public Action:Command_Demote(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		// Make sure they are doing it right before we waste CPU on them.
		if (args < 2)
		{
			PrintToChat(client, "\x03[RP Error] Usage: sm_demote <#userid|name> <reason>");
			return Plugin_Handled;
		}

		// We know the access level of the command user.  Let's find out about the target now.
		decl String:arg[65];
		GetCmdArg(1, arg, sizeof(arg));

		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for (new ib = 0; ib < target_count; ib++)
		{
			// Someone was matched by the command argument.  Let's find out who and if they can be demoted.
			if (IsClientInGame(target_list[ib]))
			{
				new i = target_list[ib];
				if (player_team[client] == player_team[i])
				{
					// They are on the same team.  Find out what their class is.
					// If they're the same class they can't demote eachother so let's end it here.  If different, continue.
					if (player_class[client] != player_class[i])
					{
						new c_c = player_class[client];
						new c_i = player_class[i];
						
						// We finally have all the info for the second player.  Let's finish this.
						
						if (class_authority[c_c] < class_authority[c_i])
						{
							// Looks like they were able to demote.
							new String:clientName[32];
							GetClientName(client, clientName, 32);
							
							new t = player_team[client];
							new c = player_class[client];

							decl String:arg2[65];
							GetCmdArg(2, arg2, sizeof(arg2));
		
							PrintToChatAll("\x03[RP] Player %N was demoted from %s by %s %s.", i, team_name[t], class_name[c], clientName);
							if (!StrEqual(arg2, "", false))
							{
								PrintToChatAll("\x03[RP] Reason: %s", arg2);
							}

							// Make them a Citizen.
							new t_index = GetConVarInt(g_DefaultTeam);
							new c_index = GetConVarInt(g_DefaultClass);	
							player_team[i] = t_index;
							player_class[i] = c_index;
							player_salary[i] = class_salary[c_index];

							// Respawn them if not already dead.
							if (IsPlayerAlive(i))
							{
								FakeClientCommandEx(i, "kill");
							}
							// Finally done holy fuck!!
							return Plugin_Handled;
						}
						else
						{
							PrintToChat(client, "\x03[RP Error] You can't demote someone who has equal or higher rank than you.");
							return Plugin_Handled;
						}
					}
					else
					{
						PrintToChat(client, "\x03[RP Error] You can't demote someone who is the same class as you.");
						return Plugin_Handled;
					}
				}
				else
				{
					PrintToChat(client, "\x03[RP Error] This player is not on your team.");
					return Plugin_Handled;
				}
			}
			else
			{
				PrintToChat(client, "\x03[RP Error] This player is not in game.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}
public Action:CommandMoney(client, Arguments)
{
	//Arguments:
	if(Arguments < 2)
	{
		//Print:
		PrintToConsole(client, "[ITEM] Usage: rp_money <Name> <Amount>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl MaxPlayers, Player;
	decl String:PlayerName[32];

	//Initialize:
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));

	//Find:
	MaxPlayers = GetMaxClients();
	for(new X = 1; X <= MaxPlayers ; X++)
	{
		//Connected:
		if(!IsClientConnected(X)) continue;

		//Declare:
		decl String:Name[32];

		//Initialize:
		GetClientName(X, Name, sizeof(Name));

		//Save:
		if(StrContains(Name, PlayerName, false) != -1) Player = X;
	}

	//Invalid Name:
	if(Player == -1)
	{
		//Print:
		PrintToConsole(client, "[RP DEBUG] Could not find client %s", PlayerName);

		//Return:
		return Plugin_Handled;
	}

	decl String:arg2[8];
	GetCmdArg(2, arg2, sizeof(arg2));
	new money_amt = StringToInt(arg2, 10);
	
	// Ok let's give them a ton of money.
	bank[Player] += money_amt;

	new String:clientName[32];
	GetClientName(Player, clientName, 32);
	
	if (client != 0)
	{
		GetClientAuthId(client, AuthId_Engine, authid[client], sizeof(authid[]));
		PrintToChat(client, "\x03[RP] You gave player %s (%s) $%i.", clientName, authid[Player], money_amt);
		LogMessage("[RP] Player %s (%s) was given $%i by admin %s.", clientName, authid[Player], money_amt, authid[client]);
	}
	if (client == 0)
	{
		PrintToServer("[RP] Player %s was given $%i by the server.", authid[Player], money_amt);
		LogMessage("[RP] Player %s was given $%i by the server.", authid[Player], money_amt);
	}
	return Plugin_Handled;
}
public Action:Command_Class_Info(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new t = player_team[client];
		new c = player_class[client];
		
		PrintToChat(client, "\x03[RP] As a %s, your salary is %i.  You are on the %s team.", class_name[c], class_salary[c], team_name[t]);
	}
	return Plugin_Handled;
}
public Action:Say_Team(client, const String:command[], args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			if (IsCuffed[client])
			{
				PrintToChat(client, "\x04[RP] %T", "Handcuffed", client);
				return Plugin_Handled;
			}
			if(client == 0) return Plugin_Handled;
			
			decl String:Arg[255];
			GetCmdArgString(Arg, sizeof(Arg));
			StripQuotes(Arg);
			TrimString(Arg);
			
			// If it's admin chat stop it here.
			if(Arg[0] == '@') return Plugin_Handled;
			
			new String:clientName[32];
			GetClientName(client, clientName, 32);
			new c = player_class[client];
			if (class_teamed[c] == 1)
			{
				for (new i = 1; i <= MaxClients; i += 1)
				{
					if (IsClientInGame(i))
					{
						if (player_team[client] == player_team[i])
						{
							PrintToChat(i, "\x04(Radio) %s: %s", clientName, Arg);
						}
					}
				}
			} else PrintToChat(client, "\x03[RP] %T", "No_Radio", client);
			return Plugin_Handled;
		}
		else return Plugin_Continue;
	}
	else return Plugin_Continue;
}
public Action:Say(client, const String:command[], args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if(client == 0) return Plugin_Handled;
		if (IsPlayerAlive(client))
		{		
			decl String:Arg[255];
			GetCmdArgString(Arg, sizeof(Arg));
			new String:clientName[32];
			GetClientName(client, clientName, 32);			

			if (!strncmp(Arg,"/me ",4,false))
			{
				if (GetConVarInt(g_Cvar_Debug))
				{
					PrintToChat(client, "\x01[DEBUG] /me was called.");
				}
				decl String:mesg[512];
				if (StrEqual(command,"say")) Format(mesg,sizeof(mesg),"\x04*** \x03%s\x04 %s",clientName,Arg[4]);
				if (StrEqual(command,"say_team")) Format(mesg,sizeof(mesg),"\x01*** \x03%s\x04 %s",clientName,Arg[4]);
				for (new i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && (!IsPlayerAlive(i) || IsPlayerAlive(client)))
				{
					if (StrEqual(command,"say_team") && (GetClientTeam(client) != GetClientTeam(i))) continue;
					PrintToChatEx(client,i,mesg);
				}
				return Plugin_Handled;		
			}
	

			StripQuotes(Arg);
			TrimString(Arg);
			
			// If it's admin chat stop it here.
			if(Arg[0] == '@') return Plugin_Handled;
			if(Arg[0] == '!') return Plugin_Continue;
			if(Arg[0] == '/') return Plugin_Continue;
			
			decl Float:PosVec[3], Float:PosVec2[3];
			GetClientEyePosition(client, PosVec);
			

			new Float:distance;

			
			for (new i = 1; i <= MaxClients; i += 1)
            {
				if (IsClientInGame(i))
				{
					GetClientEyePosition(i, PosVec2);
					distance = GetVectorDistance(PosVec, PosVec2);

					if (512.0 >= distance)
					{
						PrintToChat(i, "%s: %s", clientName, Arg);
					}
				}
			}
			return Plugin_Handled;
		}
		else return Plugin_Continue;
	}
	else return Plugin_Continue;
}
public PrintToChatEx(from,to,const String:format[],any:...)
{
	decl String:message[512];
	VFormat(message,sizeof(message),format,4);
	
	if ((game == GAME_DOD) || !to)
	{
		PrintToChat(to,message);
		return;
	}

	new Handle:hBf = StartMessageOne("SayText2",to);
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, from);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, message);
	
		EndMessage();
	}
}
public Action:CommandDoorReload(client, Arguments)
{
	ReadDoorFile(client);
	return Plugin_Handled;
}
stock CreateDoorModeMenu(Handle:door_mode_menu, String:title_str[])
{
	SetMenuTitle(door_mode_menu, title_str);
		
	AddMenuItem(door_mode_menu, "1", "Select Door");
	AddMenuItem(door_mode_menu, "2", "Display Door Info");
	AddMenuItem(door_mode_menu, "3", "Delete Door Info");
	AddMenuItem(door_mode_menu, "4", "Save");
	AddMenuItem(door_mode_menu, "5", "List Doors");
	AddMenuItem(door_mode_menu, "6", "Reset Door Mode");
	AddMenuItem(door_mode_menu, "7", "Exit Door Mode");
}
public Action:CommandDoorMode(client, Arguments)
{
	if (client < 1)
	{
		PrintToChat(client, "\x03[RP ADMIN] You must be in-game to use this command.");
		return Plugin_Handled;
	}
	if (DoorModeAdmin == -1)
	{
		DoorModeAdmin = client;
		InDoorMode = true;
		new case_thingy = -1;
		
		
		// First we check to see if we can load an existing door list.
		new String:sPath[PLATFORM_MAX_PATH];
		new String:mapname[64];
		new String:path_str[96];
	
		GetCurrentMap(mapname, sizeof(mapname));
		new pos = FindCharInString(mapname, '/', true);
		if(pos == -1)
		{
			pos = 0;
		}
		else
		{
			pos += 1;
		}
		Format(path_str, sizeof(path_str), "configs/rp_map_configs/%s_doors.txt", mapname[pos]);
	
		BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
		doormodekv = CreateKeyValues("Doors");

		if (doormodekv == INVALID_HANDLE)
		{
			CreateTimer(0.1, DoorMode_Restart, client);
		}		
		
		if (!FileToKeyValues(doormodekv, sPath))
		{
			PrintToChat(client, "\x04[RP DEBUG] Doors from file %s could not be loaded, or there is an error with the file, or the file does not exist.", path_str);
			PrintToChat(client, "\x04[RP DEBUG] A new file will be created.");
			case_thingy = 0;
		}
		else
		{
			PrintToChat(client, "\x04[RP DEBUG] Attempting to load doors from file: %s", path_str);
			case_thingy = 1;
		}
		
		DMDoors = 0;
		DMDoorGroups = 0;
		new group_buffer = 0;
		KvRewind(doormodekv);
		
		if (case_thingy == 1)
		{
			// This is where we load the existing door file.
			if (!KvGotoFirstSubKey(doormodekv))
			{
				if (client == 0)
				{
					PrintToServer("[RP DEBUG] There are no doors listed in %s, or there is an error with the file.", path_str);
				}
				else PrintToChat(client, "\x04[RP DEBUG] There are no doors listed in %s, or there is an error with the file.", path_str);
				case_thingy = 0;
			}
			else
			{
				new door_index;
				do
				{
					door_index = KvGetNum(doormodekv, "index", -1);
					group_buffer = KvGetNum(doormodekv, "group", -1);
					if (IsValidEntity(door_index))
					{
						DMDoors += 1;
					}
					if (group_buffer > DMDoorGroups)
					{
						DMDoorGroups = group_buffer;
					}
				} while (KvGotoNextKey(doormodekv));
				PrintToChat(client, "\x04[RP] %i owned doors were detected.", DMDoors);
			}
		}		
		// Make door menu, do stuff, etc...
		
		new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);		
		new String:title_str[32];
		Format(title_str, sizeof(title_str), "Door Mode");
		CreateDoorModeMenu(door_mode_menu, title_str);		
		DisplayMenu(door_mode_menu, client, MENU_TIME_FOREVER);
	}
	else if (DoorModeAdmin == client)
	{
		// Same shit, different day.  Make door menu, etc...
		
		InDoorMode = true;
		new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);		
		new String:title_str[32];
		Format(title_str, sizeof(title_str), "Door Mode");
		CreateDoorModeMenu(door_mode_menu, title_str);		
		DisplayMenu(door_mode_menu, client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintToChat(client, "\x03[RP ADMIN] Admin %N is currently using Door Mode.", DoorModeAdmin);
	}
	return Plugin_Handled;
}
public Action:DoorMode_Restart(Handle:Timer, any:client)
{
	doormodekv = CreateKeyValues("Doors");
	DMDoors = 0;
	DMDoorGroups = 0;
	KvRewind(doormodekv);
	if (doormodekv == INVALID_HANDLE)
	{
		CreateTimer(0.1, DoorMode_Restart, client);
	}
}
public Menu_DoorMode(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"1"))
		{
			// Adds a new door.
			//Declare:
			decl Ent;
			decl String:ClassName[255];
			//Initialize:
			Ent = GetClientAimTarget(param1, false);

			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
				{
					KvRewind(doormodekv);
					
					// Door Selected.  Now we see if it already has some information, and if it doesn't we simply create it.
					KvRewind(doormodekv);
					if (!KvGotoFirstSubKey(doormodekv, true))
					{
						PrintToChat(param1, "\x03[RP ADMIN] No Doors were added yet.");
					}
					new door_buffer = -1;
					new matched = 0;
					do
					{
						door_buffer = KvGetNum(doormodekv, "index", -1);
						if (door_buffer == Ent)
						{
							// This door is old.  Lets display a menu with the door's info and the ability to edit it.
							matched = 1;
							new String:steam_str[32];
							new group = KvGetNum(doormodekv, "group", -1);
							new mode = KvGetNum(doormodekv, "mode", 0);
							new team = KvGetNum(doormodekv, "team", -1);
							new class = KvGetNum(doormodekv, "class", -1);
							KvGetString(doormodekv, "steamid", steam_str, sizeof(steam_str), "-1");
							
							new String:group_str[16], String:mode_str[16], String:team_str[32], String:class_str[32], String:steamid_str[16];
							Format(group_str, sizeof(group_str), "Group: %i", group);
							Format(mode_str, sizeof(mode_str), "Mode: %i", mode);
							if (team == -1)
							{
								Format(team_str, sizeof(team_str), "Team: Unselected");
							}
							else Format(team_str, sizeof(team_str), "Team: %s", team_name[team]);
							if (class == -1)
							{
								Format(class_str, sizeof(class_str), "Class: Unselected");
							}							
							else Format(class_str, sizeof(class_str), "Class: %s", class_name[class]);
							if (StrEqual(steam_str, "-1", false))
							{
								Format(steamid_str, sizeof(steamid_str), "Steam ID: Unselected");
							}
							else Format(steamid_str, sizeof(steamid_str), "Steam ID: %s", steam_str);
					
							new Handle:door_add_menu = CreateMenu(Menu_DoorModeAdd);
							SetMenuTitle(door_add_menu, "Door %i", Ent);							
							AddMenuItem(door_add_menu, "1", group_str);
							AddMenuItem(door_add_menu, "2", mode_str);
							AddMenuItem(door_add_menu, "3", team_str);
							AddMenuItem(door_add_menu, "4", class_str);
							AddMenuItem(door_add_menu, "5", steamid_str);
							
							DisplayMenu(door_add_menu, param1, MENU_TIME_FOREVER);
							SelectedDoor = Ent;
							return;
						}
					} while (KvGotoNextKey(doormodekv));
					if (matched == 0)
					{
						// This door is new.  Lets add it then prompt the admin for more input.
						KvRewind(doormodekv);
						
						new String:index_str[8];
						Format(index_str, sizeof(index_str), "%i", Ent);
						KvJumpToKey(doormodekv, index_str, true);
						KvSetNum(doormodekv, "index", Ent);
						new group = -1;
						KvSetNum(doormodekv, "group", -1);
						new mode = 0;
						KvSetNum(doormodekv, "mode", 0);

						new String:group_str[16], String:mode_str[16];
						Format(group_str, sizeof(group_str), "Group: %i", group);
						Format(mode_str, sizeof(mode_str), "Mode: %i", mode);
						
						new Handle:door_add_menu = CreateMenu(Menu_DoorModeAdd);
						SetMenuTitle(door_add_menu, "Door %i", Ent);							
						AddMenuItem(door_add_menu, "1", group_str);
						AddMenuItem(door_add_menu, "2", mode_str);
						AddMenuItem(door_add_menu, "3", "Team: Unselected");
						AddMenuItem(door_add_menu, "4", "Class: Unselected");
						AddMenuItem(door_add_menu, "5", "Steam ID: Unselected");
						
						DisplayMenu(door_add_menu, param1, MENU_TIME_FOREVER);
						SelectedDoor = Ent;
						DMDoors += 1;
						return;
					}
					KvRewind(doormodekv);
				}
				else PrintToChat(param1, "\x03[RP ADMIN] Entity %i is not a valid door.", Ent);
			}
			else PrintToChat(param1, "\x03[RP ADMIN] You must look at a door.");
			
			new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);		
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "Door Mode");
			CreateDoorModeMenu(door_mode_menu, title_str);		
			DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info,"2"))
		{
			// Displays info for the door that player is looking at.
			//Declare:
			decl Ent;
			decl String:ClassName[255];
			//Initialize:
			Ent = GetClientAimTarget(param1, false);

			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
				{
					KvRewind(doormodekv);
					if (!KvGotoFirstSubKey(doormodekv, true))
					{
						PrintToChat(param1, "\x03[RP ADMIN] No Doors were added yet.");
					}
					new door_buffer = -1;
					new matched = 0;
					do
					{
						door_buffer = KvGetNum(doormodekv, "index", -1);
						if (door_buffer == Ent)
						{
							matched = 1;
							new String:steam_str[32];
							KvGetString(doormodekv, "steamid", steam_str, sizeof(steam_str));
							PrintToChat(param1, "\x03[RP] Door: %i  Group: %i  Mode: %i  Team: %i  Class: %i  Steam: %s", KvGetNum(doormodekv, "index", -1), KvGetNum(doormodekv, "group", -1), KvGetNum(doormodekv, "mode", 0), KvGetNum(doormodekv, "team", 0), KvGetNum(doormodekv, "class", 0), steam_str);									
							KvRewind(doormodekv);
							break;
						}
					} while (KvGotoNextKey(doormodekv));
					if (matched == 0)
					{
						PrintToChat(param1, "\x03[RP ADMIN] Door %i was not edited yet.", Ent);
					}
				}
				else PrintToChat(param1, "\x03[RP ADMIN] Entity %i is not a valid door.", Ent);
			}
			else PrintToChat(param1, "\x03[RP ADMIN] You must look at a door.");
			
			new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "Door Mode");
			CreateDoorModeMenu(door_mode_menu, title_str);
			DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info,"3"))
		{
			// Deletes info for the door that player is looking at.
			//Declare:
			decl Ent;
			decl String:ClassName[255];
			//Initialize:
			Ent = GetClientAimTarget(param1, false);

			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
				{
					KvRewind(doormodekv);
					if (!KvGotoFirstSubKey(doormodekv, true))
					{
						PrintToChat(param1, "\x03[RP ADMIN] No Doors were added yet.");
					}
					new door_buffer = -1;
					new matched = 0;
					do
					{
						door_buffer = KvGetNum(doormodekv, "index", -1);
						if (door_buffer == Ent)
						{
							matched = 1;
							KvDeleteThis(doormodekv);
							PrintToChat(param1, "\x03[RP ADMIN] Information for Door %i Deleted", Ent);
							KvRewind(doormodekv);
							break;
						}
					} while (KvGotoNextKey(doormodekv));
					if (matched == 0)
					{
						PrintToChat(param1, "\x03[RP ADMIN] Door %i was not edited yet.", Ent);
					}
				}
				else PrintToChat(param1, "\x03[RP ADMIN] Entity %i is not a valid door.", Ent);
			}
			else PrintToChat(param1, "\x03[RP ADMIN] You must look at a door.");
			
			new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "Door Mode");
			CreateDoorModeMenu(door_mode_menu, title_str);
			DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info,"4"))
		{
			new String:sPath[PLATFORM_MAX_PATH];
			new String:mapname[64];
			new String:path_str[96];
	
			GetCurrentMap(mapname, sizeof(mapname));
			new pos = FindCharInString(mapname, '/', true);
			if(pos == -1)
			{
				pos = 0;
			}
			else
			{
				pos += 1;
			}
			Format(path_str, sizeof(path_str), "configs/rp_map_configs/%s_doors.txt", mapname[pos]);
			
			BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
			KvRewind(doormodekv);
			KeyValuesToFile(doormodekv, sPath);			
			
			new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "All Doors Saved");
			CreateDoorModeMenu(door_mode_menu, title_str);
			DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
			
			PrintToChat(param1, "\x03[RP ADMIN] Doors Saved -- Use rp_door_reload to load changes.");
		}
		if (StrEqual(info,"5"))
		{	
			new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "Door Mode");
			CreateDoorModeMenu(door_mode_menu, title_str);
			DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
			
			if (DMDoors <= 0)
			{
				PrintToChat(param1, "\x03[RP ADMIN] No Doors Yet.");
			}
			else
			{
				KvRewind(doormodekv);
				
				PrintToChat(param1, "\x03[RP ADMIN] See Console for Output.");
				PrintToConsole(param1, "[RP] Door Mode Doors");
				PrintToConsole(param1, "Total Doors:  %i", DMDoors);
				new String:max_str[8];
				new String:steam_str[32];
				Format(max_str, sizeof(max_str), "%i", DMDoors);
				
				KvGotoFirstSubKey(doormodekv, true);
				
				for (new i = 0; i <= DMDoors; i++)
				{
					if (KvGotoNextKey(doormodekv))
					{
						KvGetString(doormodekv, "steamid", steam_str, sizeof(steam_str));					
						PrintToConsole(param1, "Door: %i  Group: %i  Mode: %i  Team: %i  Class: %i  Steam: %i", KvGetNum(doormodekv, "index", -1), KvGetNum(doormodekv, "group", -1), KvGetNum(doormodekv, "mode", 0), KvGetNum(doormodekv, "team", 0), KvGetNum(doormodekv, "class", 0), steam_str);
					} else break;
				}
			}
		}
		if (StrEqual(info,"6"))
		{
			new Handle:door_mode_reset_menu = CreateMenu(Menu_DoorModeReset);
			SetMenuTitle(door_mode_reset_menu, "Delete All Changes?");
		
			AddMenuItem(door_mode_reset_menu, "1", "Yes");
			AddMenuItem(door_mode_reset_menu, "2", "No");
		
			DisplayMenu(door_mode_reset_menu, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info,"7"))
		{
			new Handle:door_mode_exit_menu = CreateMenu(Menu_DoorModeExit);
			SetMenuTitle(door_mode_exit_menu, "Save Changes Before Exit?");
		
			AddMenuItem(door_mode_exit_menu, "1", "Yes");
			AddMenuItem(door_mode_exit_menu, "2", "No");
		
			DisplayMenu(door_mode_exit_menu, param1, MENU_TIME_FOREVER);
		}
	}
}
public Menu_DoorModeAdd(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"1"))
		{
			// This mode selects a group.
			if ((SelectedDoor < 1) || (!IsValidEdict(SelectedDoor)))
			{
				return;
			}
			new Handle:door_mode_group_select = CreateMenu(Menu_DoorGroupSelect);
			SetMenuTitle(door_mode_group_select, "Select Group for Door %i", SelectedDoor);
		
			new String:i_str[4];
			for (new i = 0; i < DMDoorGroups; i++)
			{
				Format(i_str, sizeof(i_str), "%i", i);
				AddMenuItem(door_mode_group_select, i_str, i_str);
			}
			AddMenuItem(door_mode_group_select, "-1", "Add to New Group");
			DisplayMenu(door_mode_group_select, param1, MENU_TIME_FOREVER);
			return;
		}
		if (StrEqual(info,"2"))
		{
			// This mode selects an ownership mode.
			if ((SelectedDoor < 1) || (!IsValidEdict(SelectedDoor)))
			{
				return;
			}
			new Handle:door_mode_mode_select = CreateMenu(Menu_DoorModeModeSelect);
			SetMenuTitle(door_mode_mode_select, "Select Ownership Mode for Door %i", SelectedDoor);
		
			AddMenuItem(door_mode_mode_select, "0", "Team Ownership");
			AddMenuItem(door_mode_mode_select, "1", "Class Ownership");
			AddMenuItem(door_mode_mode_select, "3", "Steam ID Ownership");
			DisplayMenu(door_mode_mode_select, param1, MENU_TIME_FOREVER);
			return;
		}
		if (StrEqual(info,"3"))
		{
			// This mode selects a team.
			if ((SelectedDoor < 1) || (!IsValidEdict(SelectedDoor)))
			{
				return;
			}
			new Handle:door_mode_team_select = CreateMenu(Menu_DoorTeamSelect);
			SetMenuTitle(door_mode_team_select, "Select Team for Door %i", SelectedDoor);
		
			new String:i_str[4];
			AddMenuItem(door_mode_team_select, "-2", "Deselect Team");
			for (new i = 0; i < team_index; i++)
			{
				Format(i_str, sizeof(i_str), "%i", i);
				AddMenuItem(door_mode_team_select, i_str, team_name[i]);
			}
			AddMenuItem(door_mode_team_select, "-1", "Make Un-Buyable");
			DisplayMenu(door_mode_team_select, param1, MENU_TIME_FOREVER);
			return;
		}
		if (StrEqual(info,"4"))
		{
			// This mode selects a class.
			if ((SelectedDoor < 1) || (!IsValidEdict(SelectedDoor)))
			{
				return;
			}
			new Handle:door_mode_class_select = CreateMenu(Menu_DoorClassSelect);
			SetMenuTitle(door_mode_class_select, "Select Class for Door %i", SelectedDoor);
		
			new String:i_str[4];
			for (new i = 0; i < class_index; i++)
			{
				Format(i_str, sizeof(i_str), "%i", i);
				AddMenuItem(door_mode_class_select, i_str, class_name[i]);
			}
			DisplayMenu(door_mode_class_select, param1, MENU_TIME_FOREVER);
			return;
		}
		if (StrEqual(info,"5"))
		{
			// This mode is by the Steam ID of a player in game.
			if ((SelectedDoor < 1) || (!IsValidEdict(SelectedDoor)))
			{
				return;
			}
			new Handle:door_mode_steam_select = CreateMenu(Menu_DoorSteamSelect);
			SetMenuTitle(door_mode_steam_select, "Select who to give Door %i to...", SelectedDoor);

			decl String:identifier[32];
			decl String:name[32];
			for (new i = 1; i < GetMaxClients(); i++)
			{
				if (IsClientInGame(i))
				{
					GetClientName(i, name, sizeof(name));
					Format(identifier, sizeof(identifier), "%i", i);
					AddMenuItem(door_mode_steam_select, identifier, name);
				}
			}
			DisplayMenu(door_mode_steam_select, param1, MENU_TIME_FOREVER);
			return;
		}
	}
	KvRewind(doormodekv);
	return;
}
public Menu_DoorGroupSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		KvRewind(doormodekv);
		new String:info[32];
		new String:door_temp[8];
		new String:title_str[32];
		Format(door_temp, sizeof(door_temp), "%i", SelectedDoor);
		GetMenuItem(menu, param2, info, sizeof(info));
		new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);
		KvJumpToKey(doormodekv, door_temp, false);
		if (StrEqual(info,"-1"))
		{
			KvSetNum(doormodekv, "group", DMDoorGroups);
			Format(title_str, sizeof(title_str), "Door %s set to Group %i", door_temp, DMDoorGroups);
			DMDoorGroups += 1;		
		}
		else
		{
			KvSetString(doormodekv, "group", info);
			Format(title_str, sizeof(title_str), "Door %s set to Group %s", door_temp, info);
		}
		SelectedDoor = -1;
		KvRewind(doormodekv);
		

		CreateDoorModeMenu(door_mode_menu, title_str);
		
		DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
	}
	KvRewind(doormodekv);
	SelectedDoor = -1;
	return;
}
public Menu_DoorModeModeSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		KvRewind(doormodekv);
		new String:info[32];
		new String:door_temp[8];
		Format(door_temp, sizeof(door_temp), "%i", SelectedDoor);
		GetMenuItem(menu, param2, info, sizeof(info));
		
		KvJumpToKey(doormodekv, door_temp, false);
		KvSetString(doormodekv, "mode", info);
		
		SelectedDoor = -1;
		KvRewind(doormodekv);
		
		new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);
		SetMenuTitle(door_mode_menu, "All Doors Reset");
		
		AddMenuItem(door_mode_menu, "1", "Select Door");
		AddMenuItem(door_mode_menu, "2", "Display Door Info");
		AddMenuItem(door_mode_menu, "3", "Delete Door Info");
		AddMenuItem(door_mode_menu, "4", "Save");
		AddMenuItem(door_mode_menu, "5", "List Doors");
		AddMenuItem(door_mode_menu, "6", "Reset Door Mode");
		AddMenuItem(door_mode_menu, "7", "Exit Door Mode");
		
		DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
	}
	KvRewind(doormodekv);
	SelectedDoor = -1;
	return;
}
public Menu_DoorTeamSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		KvRewind(doormodekv);
		new String:info[32];
		new String:door_temp[8];
		Format(door_temp, sizeof(door_temp), "%i", SelectedDoor);
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);
		
		KvJumpToKey(doormodekv, door_temp, false);
		if (StrEqual(info,"-2"))
		{
			KvSetNum(doormodekv, "team", -1);
			KvSetNum(doormodekv, "mode", 0);
			SetMenuTitle(door_mode_menu, "Door %s is now Buyable", door_temp);
			
		}
		if (StrEqual(info,"-1"))
		{
			KvSetNum(doormodekv, "team", team_index + 1);
			KvSetNum(doormodekv, "mode", 0);
			SetMenuTitle(door_mode_menu, "Door %s is now Unbuyable", door_temp);
			
		}
		else 
		{
			KvSetString(doormodekv, "team", info);
			KvSetNum(doormodekv, "mode", 0);
			new t = StringToInt(info);
			SetMenuTitle(door_mode_menu, "Door %s Set to %s", door_temp, team_name[t]);
		}
		SelectedDoor = -1;
		KvRewind(doormodekv);
		
		
		AddMenuItem(door_mode_menu, "1", "Select Door");
		AddMenuItem(door_mode_menu, "2", "Display Door Info");
		AddMenuItem(door_mode_menu, "3", "Delete Door Info");
		AddMenuItem(door_mode_menu, "4", "Save");
		AddMenuItem(door_mode_menu, "5", "List Doors");
		AddMenuItem(door_mode_menu, "6", "Reset Door Mode");
		AddMenuItem(door_mode_menu, "7", "Exit Door Mode");
		
		DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
	}
	KvRewind(doormodekv);
	SelectedDoor = -1;
	return;
}
public Menu_DoorClassSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		KvRewind(doormodekv);
		new String:info[32];
		new String:door_temp[8];
		Format(door_temp, sizeof(door_temp), "%i", SelectedDoor);
		GetMenuItem(menu, param2, info, sizeof(info));
		
		KvJumpToKey(doormodekv, door_temp, false);
		
		KvSetString(doormodekv, "class", info);
		KvSetNum(doormodekv, "mode", 1);
		
		SelectedDoor = -1;
		KvRewind(doormodekv);
		
		new c = StringToInt(info);
		
		new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);
		SetMenuTitle(door_mode_menu, "Door %s Set to %s, mode set to Class", door_temp, class_name[c]);
		
		AddMenuItem(door_mode_menu, "1", "Select Door");
		AddMenuItem(door_mode_menu, "2", "Display Door Info");
		AddMenuItem(door_mode_menu, "3", "Delete Door Info");
		AddMenuItem(door_mode_menu, "4", "Save");
		AddMenuItem(door_mode_menu, "5", "List Doors");
		AddMenuItem(door_mode_menu, "6", "Reset Door Mode");
		AddMenuItem(door_mode_menu, "7", "Exit Door Mode");
		
		DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
	}
	KvRewind(doormodekv);
	SelectedDoor = -1;
	return;
}
public Menu_DoorSteamSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		KvRewind(doormodekv);
		new String:info[32];
		new String:door_temp[8];
		Format(door_temp, sizeof(door_temp), "%i", SelectedDoor);
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new c = StringToInt(info, 10);
		new String:steamid[32];
		GetClientAuthId(c, AuthId_Engine, steamid, sizeof(steamid));
		
		KvJumpToKey(doormodekv, door_temp, false);
		
		KvSetString(doormodekv, "steamid", steamid);
		KvSetNum(doormodekv, "mode", 3);
		
		SelectedDoor = -1;
		KvRewind(doormodekv);
		
		new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);
		SetMenuTitle(door_mode_menu, "Door %s Set to %N %s, mode set to SteamID", door_temp, c, steamid);
		
		AddMenuItem(door_mode_menu, "1", "Select Door");
		AddMenuItem(door_mode_menu, "2", "Display Door Info");
		AddMenuItem(door_mode_menu, "3", "Delete Door Info");
		AddMenuItem(door_mode_menu, "4", "Save");
		AddMenuItem(door_mode_menu, "5", "List Doors");
		AddMenuItem(door_mode_menu, "6", "Reset Door Mode");
		AddMenuItem(door_mode_menu, "7", "Exit Door Mode");
		
		DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
	}
	KvRewind(doormodekv);
	SelectedDoor = -1;
	return;
}
public Menu_DoorModeReset(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"1"))
		{
			// Reset Doors
			if (doormodekv != INVALID_HANDLE)
			{
				CloseHandle(doormodekv);
				doormodekv = INVALID_HANDLE;
			}
			doormodekv = CreateKeyValues("Doors");
			DMDoors = 0;
			KvRewind(doormodekv);
			
			new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);
			SetMenuTitle(door_mode_menu, "All Doors Reset");
		
			AddMenuItem(door_mode_menu, "1", "Select Door");
			AddMenuItem(door_mode_menu, "2", "Display Door Info");
			AddMenuItem(door_mode_menu, "3", "Delete Door Info");
			AddMenuItem(door_mode_menu, "4", "Save");
			AddMenuItem(door_mode_menu, "5", "List Doors");
			AddMenuItem(door_mode_menu, "6", "Reset Door Mode");
			AddMenuItem(door_mode_menu, "7", "Exit Door Mode");
		
			DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
		}
		else
		{
			new Handle:door_mode_menu = CreateMenu(Menu_DoorMode);
			SetMenuTitle(door_mode_menu, "Door Mode");
		
			AddMenuItem(door_mode_menu, "1", "Select Door");
			AddMenuItem(door_mode_menu, "2", "Display Door Info");
			AddMenuItem(door_mode_menu, "3", "Delete Door Info");
			AddMenuItem(door_mode_menu, "4", "Save");
			AddMenuItem(door_mode_menu, "5", "List Doors");
			AddMenuItem(door_mode_menu, "6", "Reset Door Mode");
			AddMenuItem(door_mode_menu, "7", "Exit Door Mode");
		
			DisplayMenu(door_mode_menu, param1, MENU_TIME_FOREVER);
		}
	}
	return;
}
public Menu_DoorModeExit(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"1"))
		{
			// Save and exit
			new String:sPath[PLATFORM_MAX_PATH];
			new String:mapname[64];
			new String:path_str[96];
	
			GetCurrentMap(mapname, sizeof(mapname));
			new pos = FindCharInString(mapname, '/', true);
			if(pos == -1)
			{
				pos = 0;
			}
			else
			{
				pos += 1;
			}
			Format(path_str, sizeof(path_str), "configs/rp_map_configs/%s_doors.txt", mapname[pos]);
			
			BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
			KvRewind(doormodekv);
			KeyValuesToFile(doormodekv, sPath);
			if (doormodekv != INVALID_HANDLE)
			{
				KvRewind(doormodekv);
				CloseHandle(doormodekv);
				doormodekv = INVALID_HANDLE;
			}
			
			ReadDoorFile(param1);
		}
		else
		{
			// Just exit
			InDoorMode = false;
			DoorModeAdmin = -1;
			if (doormodekv != INVALID_HANDLE)
			{
				KvRewind(doormodekv);
				CloseHandle(doormodekv);
				doormodekv = INVALID_HANDLE;
			}
			
			ReadDoorFile(param1);
		}
	}
	return;
}


// ###########
// BUILD MENUS
// ###########



Handle:BuildTeamMenu()
{
	if (team_index == 0)
	{
		PrintToServer("[RP] Error: BuildTeamMenu (00) -- Unable to build team menu.  No teams indexed.");
		LogMessage("[RP] Error: BuildTeamMenu (00) -- Unable to build team menu.  No teams indexed.");
		return INVALID_HANDLE;
	}
	if (class_index == 0)
	{
		PrintToServer("[RP] Error: BuildTeamMenu (01) -- Unable to build team menu.  No classes indexed.");
		LogMessage("[RP] Error: BuildTeamMenu (01) -- Unable to build team menu.  No classes indexed.");
		return INVALID_HANDLE;
	}
	
	PrintToServer("[RP] BuildTeamMenu passed preliminary checks.");
	
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Team);
	
	new i = 0;
	new String:team_str[4];
	new limit = team_index - 1;
	do
	{
		if (team_vip[i] == 0)
		{
			Format(team_str, sizeof(team_str), "%i", i);
			AddMenuItem(menu,team_str,team_name[i]);
		}
		i += 1;

	} while (i <= limit);
	
	SetMenuTitle(menu, "Choose a Team");
	PrintToServer("[RP] BuildTeamMenu completed successfully.");
	return menu;
}
Handle:BuildVIPTeamMenu()
{
	if (team_index == 0)
	{
		PrintToServer("[RP] Error: BuildVIPTeamMenu (00) -- Unable to build team menu.  No teams indexed.");
		LogMessage("[RP] Error: BuildVIPTeamMenu (00) -- Unable to build team menu.  No teams indexed.");
		return INVALID_HANDLE;
	}
	if (class_index == 0)
	{
		PrintToServer("[RP] Error: BuildVIPTeamMenu (01) -- Unable to build team menu.  No classes indexed.");
		LogMessage("[RP] Error: BuildVIPTeamMenu (01) -- Unable to build team menu.  No classes indexed.");
		return INVALID_HANDLE;
	}
	
	PrintToServer("[RP] BuildVIPTeamMenu passed preliminary checks.");
	
	/* Create the menu Handle */
	new Handle:vipmenu = CreateMenu(Menu_Team);
	
	new i = 0;
	new String:team_str[4];
	new limit = team_index - 1;
	do
	{
		Format(team_str, sizeof(team_str), "%i", i);
		AddMenuItem(vipmenu,team_str,team_name[i]);
		i += 1;

	} while (i <= limit);
	
	SetMenuTitle(vipmenu, "Choose a Team");
	PrintToServer("[RP] BuildVIPTeamMenu completed successfully.");
	return vipmenu;
}
Handle:BuildSpecialMenu()
{
	new Handle:special = CreateMenu(Menu_Special);
	AddMenuItem(special, "A", "Buy a Money printer");
	AddMenuItem(special, "B", "Buy a Handcuff Saw $100");
	AddMenuItem(special, "C", "Use a Handcuff Saw");
//	new String:beer_str[24];
//	new price = GetConVarInt(g_Beer_Price);
//	Format(beer_str, sizeof(beer_str), "Buy a Beer $%i", price);
//	AddMenuItem(special, "E", beer_str);
	AddMenuItem(special, "D", "Info");
	SetMenuTitle(special, "RP Special Item Menu");
	PrintToServer("[RP] BuildSpecialMenu completed successfully.");
	return special;
}



// ##############
// MENU FUNCTIONS
// ##############



public Menu_Special(Handle:special, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(special, param2, info, sizeof(info));
		if (StrEqual(info,"A"))
		{
			if (!IsPlayerAlive(param1))
			{
				PrintToChat(param1, "\x04[RP] %T", "Youre_Dead", param1);
				return;
			}
			new max_printers = 0;
			new AdminId:admin = GetUserAdmin(param1);
			if (admin != INVALID_ADMIN_ID)
			{
				max_printers = GetConVarInt(g_VIPPrinterMax);
			}
			else max_printers = GetConVarInt(g_PrinterMax);
			if (printerAmount[param1] < max_printers)
			{
				if (player_team[param1] == 0)
				{
					PrintToChat(param1, "\x03[RP] You can't own contraband while working for the Government.");
					return;
				}
				new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
				money[param1] = GetEntData(param1, MoneyOffset, 4);
				new printer_price = GetConVarInt(g_PrinterPrice);
				if (money[param1] >= printer_price)
				{
					decl Float:_origin[3], Float:_angles[3];
					GetClientEyePosition( param1, _origin );
					GetClientEyeAngles( param1, _angles );

					new Handle:trace = TR_TraceRayFilterEx( _origin, _angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers );
					if( !TR_DidHit( trace ) )
		    		{
						PrintToChat(param1, "\x03[NsPM]Unable to pick the current location.");
						return;
    				}
					else
					{
						decl Float:VecAngles[3], Float:position[3], VecOrigin[3], Float:VecDirection[3];
						TR_GetEndPosition(position, trace);

						// Now spawn the model and drop it!!
						new prop = CreateEntityByName("prop_physics_override");

						if (!IsModelPrecached("models/natalya/props/consolebox01_expl.mdl"))
						{
							PrecacheModel("models/natalya/props/consolebox01_expl.mdl");
						}

						DispatchKeyValue(prop, "skin", "0");
						SetEntityModel(prop, "models/natalya/props/consolebox01_expl.mdl");
						DispatchKeyValueFloat (prop, "MaxPitch", 360.00);
						DispatchKeyValueFloat (prop, "MinPitch", -360.00);
						DispatchKeyValueFloat (prop, "MaxYaw", 90.00);
						DispatchSpawn(prop);
						
						GetClientAuthId(param1, AuthId_Engine, authid[param1], sizeof(authid[]));
						
						GetClientEyeAngles(param1, VecAngles);
						GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
						VecOrigin[0] += VecDirection[0] * 32;
						VecOrigin[1] += VecDirection[1] * 32;
						VecOrigin[2] += VecDirection[2] * 1;
						VecAngles[0] = 0.0;
						VecAngles[1] += 180.0;
						VecAngles[2] = 0.0;
						DispatchKeyValueVector(prop, "Angles", VecAngles);
						DispatchKeyValue(prop, "health", "10");
						DispatchKeyValue(prop, "ExplodeRadius", "16");
						DispatchKeyValue(prop, "ExplodeDamage", "10");
						DispatchKeyValue(prop, "Damagetype", "1");
						DispatchKeyValue(prop, "PerformanceMode", "0");
						DispatchKeyValue(prop, "targetname", authid[param1]);
						DispatchSpawn(prop);
						TeleportEntity(prop, position, NULL_VECTOR, NULL_VECTOR);
						PrintToServer("[RP] Money Printer spawned at %f, %f, %f.", position[0], position[1], position[2]);
						PrintToChat(param1, "\x03[RP] %T", "Money_Printer_Spawned", param1);
						
						printer_owner[prop] = param1;
						IsPrinter[prop] = true;
						printerMoney[prop] = 0;

						money[param1] -= printer_price;
						SetEntData(param1, MoneyOffset, money[param1], 4, true);
						new temp_amt = printerAmount[param1];
						players_printers[param1][temp_amt] = prop;
						printerAmount[param1] += 1;
						
						HookSingleEntityOutput(prop, "OnBreak", EntityOutput:OnPropPhysBreak);
						return;
					}
				}
				else PrintToChat(param1, "\x03[RP] %T", "Expensive", param1);
				return;
			}
			else PrintToChat(param1, "\x03[RP] You already have the maximum amount of Money Printers. (%i)", max_printers);
			return;
		}
		if (StrEqual(info,"B"))
		{
			new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			money[param1] = GetEntData(param1, MoneyOffset, 4);

			if (money[param1] > 99)
			{
				money[param1] -= 100;
				SetEntData(param1, MoneyOffset, money[param1], 4, true);
				saws[param1] += 1;

				PrintToChat(param1, "\x03[RP] You bought a Handcuff Saw.");
				return;
			}
			else PrintToChat(param1, "\x03[RP] %T", "Expensive", param1);
			return;
		}
		if (StrEqual(info,"C"))
		{
			//Declare:
			decl Ent;
			decl String:ClassName[255];
			//Initialize:
			Ent = GetClientAimTarget(param1, false);

			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "player"))
				{
					if (IsCuffed[Ent])
					{
						if (saws[param1] > 0)
						{
							UnCuff(Ent);
							saws[param1] -= 1;
							return;
						}
						else PrintToChat(param1, "\x03[RP] You have 0 Handcuff Saws.  Buy some more!!");
						return;
					}
					else PrintToChat(param1, "\x03[RP] This player is not Handcuffed.");
					return;
				}
				else PrintToChat(param1, "\x03[RP] %T", "Look", param1);
				return;
			}
			else PrintToChat(param1, "\x03[RP] %T", "Look", param1);
			return;
		}
		if (StrEqual(info,"D"))
		{
			if (saws[param1] == 1)
			{
				PrintToChat(param1, "\x03[RP] You have 1 Handcuff Saw.");
			}
			else PrintToChat(param1, "\x03[RP] You have %i Handcuff Saws.", saws[param1]);
			if (printerAmount[param1] == 1)
			{
				PrintToChat(param1, "\x03[RP] You have 1 Money Printer.");
				return;
			}
			else PrintToChat(param1, "\x03[RP] You have %i Money Printers.", printerAmount[param1]);
		}
/*		if (StrEqual(info,"E"))
		{
			if (!IsPlayerAlive(param1))
			{
				PrintToChat(param1, "\x04[RP] %T", "Youre_Dead", param1);
				return;
			}	
			new c = player_class[param1];
			if (class_alcohol[c] != 1)
			{
				PrintToChat(param1, "\x03[RP] Your class (%s) can't buy alcohol.", class_name[c]);
				return;
			}
			new price = GetConVarInt(g_Beer_Price);
			new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			money[param1] = GetEntData(param1, MoneyOffset, 4);

			if (money[param1] < price)
			{
				PrintToChat(param1, "\x03[RP] You can't afford this.  It costs $%i.", price);
				return;
			}

			// They're alive, their class can buy alcohol, and they have $5.  Let's spawn them a drink.  :)			
			new Float:EyeAng[3];
			GetClientEyeAngles(param1, EyeAng);
			new Float:ForwardVec[3];
			GetAngleVectors(EyeAng, ForwardVec, NULL_VECTOR, NULL_VECTOR);			
			ScaleVector(ForwardVec, 32.0);
			ForwardVec[2] = 0.0;
			new Float:EyePos[3];
			GetClientEyePosition(param1, EyePos);
			new Float:AbsAngle[3];
			GetclientAbsAngles(param1, AbsAngle);

			new Float:SpawnAngles[3];
			SpawnAngles[1] = EyeAng[1];
			new Float:SpawnOrigin[3];
			AddVectors(EyePos, ForwardVec, SpawnOrigin);

			new beer = CreateEntityByName("prop_physics_override");
			if(IsValidEntity(beer))
			{
				TeleportEntity(beer, SpawnOrigin, SpawnAngles, NULL_VECTOR);				
				DispatchKeyValue(beer, "model", BEER);
				DispatchKeyValue(beer, "PerformanceMode", "0");
				DispatchKeyValue(beer, "StartDisabled", "false");
				DispatchKeyValue(beer, "Solid", "6");
				SetEntProp(beer, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(beer, Prop_Data, "m_usSolidFlags", 16);
				SetEntProp(beer, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValueFloat (beer, "MaxPitch", 360.00);
				DispatchKeyValueFloat (beer, "MinPitch", -360.00);
				DispatchKeyValueFloat (beer, "MaxYaw", 90.00);		
				ActivateEntity(beer);
				DispatchSpawn(beer);
				AcceptEntityInput(beer, "Enable");
				AcceptEntityInput(beer, "TurnOn");
				Beer[beer] = 1;
				PrintToChat(param1, "\x03[RP] You bought a beer.");
				money[param1] -= price;
				SetEntData(param1, MoneyOffset, money[param1], 4, true);	
			}
		} */
	}
	return;
}
public Menu_Settings(Handle:settings, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(settings, param2, info, sizeof(info));
		if (StrEqual(info,"FEMALE"))
		{
			player_gender[param1] = 0;
			PrintToChat(param1, "\x03[RP] The next time you spawn you will be Female.");
		}
		if (StrEqual(info,"MALE"))
		{
			player_gender[param1] = 1;
			PrintToChat(param1, "\x03[RP] The next time you spawn you will be Male.");
		}
		if (StrEqual(info,"CASH"))
		{
			player_cash_or_dd[param1] = 0;
			PrintToChat(param1, "\x03[RP] From now on you will be paid in Cash.");
		}
		if (StrEqual(info,"DD"))
		{
			player_cash_or_dd[param1] = 1;
			PrintToChat(param1, "\x03[RP] From now on you will be paid by Direct Deposit to your Bank account.");
		}
	}
	return;
}
public Menu_Team(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		return;
	}
	if (action == MenuAction_Select)
	{
		// They chose a team.  We should kill them, set their team, and set class to -1 temporarily.
		// Then give them a menu with all the classes for their team, so they can choose.	

		player_class[param1] = -1;		
		player_team[param1] = param2;


		if (IsPlayerAlive(param1))
		{
			FakeClientCommand(param1, "kill");
		}

		
		new Handle:tempmenu = CreateMenu(Menu_Class);
		
		decl String:buffer[4];
		decl String:item_name[32];	
		new total = 0;
		new tc = 0;
		for (new c = 0; c < class_index; c++)
		{
			if (class_team[c] == param2)
			{
				class_players[c] = 0;
				new MaxPlayers = GetMaxClients();
				for (new tempplayer = 1; tempplayer < MaxPlayers; tempplayer++)
				{
					if (IsClientConnected(tempplayer))
					{
						if (IsClientInGame(tempplayer))
						{
							tc = player_class[tempplayer];
							if (tc != -1)
							{
								class_players[tc] += 1;
							}
						}
					}
				}
				if (class_players[c] < class_limit[c])
				{
					Format(buffer, sizeof(buffer), "%i", c);
					Format(item_name, sizeof(item_name), "%s (%i)", class_name[c], class_players[c]);
					AddMenuItem(tempmenu, buffer, item_name);
					total += 1;
				}
				else if (class_players[c] >= class_limit[c])
				{
					Format(buffer, sizeof(buffer), "%i", c);
					Format(item_name, sizeof(item_name), "%s (%i)", class_name[c], class_players[c]);
					AddMenuItem(tempmenu, buffer, item_name, ITEMDRAW_DISABLED);
					total += 1;
				}				
			}
		}
		if (total == 0)
		{
			AddMenuItem(tempmenu, "NOTHING", "Error: No Classes Detected", ITEMDRAW_DISABLED);
		}
		SetMenuTitle(tempmenu, team_name[param2]);
		DisplayMenu(tempmenu, param1, MENU_TIME_FOREVER);
		changing_class[param1] = 1;
	}
	return;
}
public Menu_Class(Handle:tempmenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		return;
	}
	if (action == MenuAction_Select)
	{
		// Player was given the class menu and chose a class.
		// Respawn them, add to class_players, and set them as their class.
		
		new String:info[32];
		GetMenuItem(tempmenu, param2, info, sizeof(info));
		new index = StringToInt(info);
	
		player_class[param1] = index;
			
		new Float:time[1];
		time[0] = GetConVarFloat(g_Class_Delay);
		h_class_changeable[param1] = 0;
		new AdminId:admin = GetUserAdmin(param1);
		if (admin != INVALID_ADMIN_ID)
		{
			h_class_changeable[param1] = 1;
		}
		else CreateTimer(time[0], Respawn_Time, param1);
		
		changing_class[param1] = 0;
		CS_RespawnPlayer(param1);		
	}
	return;
}



// #############
// MENU COMMANDS
// #############


public Action:Command_RP(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new String:title_str[32], String:class_str[32], String:door_str[32], String:item_str[32], String:prop_str[32], String:car_str[32], String:special_str[32], String:settings_str[32];
		Format(title_str, sizeof(title_str), "%T", "RP_Menu", client);
		Format(class_str, sizeof(class_str), "%T", "Class_Menu", client);
		Format(door_str, sizeof(door_str), "%T", "Door_Menu", client);
		Format(item_str, sizeof(item_str), "%T", "Item_Menu", client);
		Format(prop_str, sizeof(prop_str), "%T", "Prop_Menu", client);
		Format(car_str, sizeof(car_str), "%T", "Car_Menu", client);
		Format(special_str, sizeof(special_str), "%T", "Special_Menu", client);
		Format(settings_str, sizeof(settings_str), "%T", "RP_Settings", client);

		new Handle:rp_menu = CreateMenu(Menu_RP);
		AddMenuItem(rp_menu, "0", class_str);
		AddMenuItem(rp_menu, "1", door_str);
		AddMenuItem(rp_menu, "2", item_str);
		AddMenuItem(rp_menu, "3", prop_str);
		AddMenuItem(rp_menu, "4", car_str);
		AddMenuItem(rp_menu, "5", special_str);
		AddMenuItem(rp_menu, "6", settings_str);
		SetMenuTitle(rp_menu, title_str);
		DisplayMenu(rp_menu, client, 0);
	}
	return Plugin_Handled;
}
public Menu_RP(Handle:rp_menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(rp_menu, param2, info, sizeof(info));
		
		new i = StringToInt(info);
		if (i == 0)
		{
			FakeClientCommandEx(param1, "sm_class");
		}
		if (i == 1)
		{
			FakeClientCommandEx(param1, "sm_door");
		}
		if (i == 2)
		{
			FakeClientCommandEx(param1, "sm_item");
		}
		if (i == 3)
		{
			FakeClientCommandEx(param1, "sm_propmenu");
		}
		if (i == 4)
		{
			FakeClientCommandEx(param1, "sm_car_menu");
		}
		if (i == 5)
		{
			FakeClientCommandEx(param1, "sm_special");
		}
		if (i == 6)
		{
			FakeClientCommandEx(param1, "sm_rp_settings");
		}
	}
	return;
}
public Action:Command_Class(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (g_TeamMenu == INVALID_HANDLE)
		{
			PrintToServer("There was an error generating the menu. Check your classes.ini file");
			return Plugin_Handled;
		}
		if (!IsPlayerAlive(client))
		{
			if (h_respawnable[client] == 1)
			{
				CS_RespawnPlayer(client);
				PrintToChat(client, "\x03[RP] %T", "Respawned", client);
				return Plugin_Handled;
			}
			else if (h_respawnable[client] == 0)
			{
				new AdminId:admin = GetUserAdmin(client);
				if (admin == INVALID_ADMIN_ID)
				{
					new r_time = GetConVarInt(g_Cvar_Respawn_Time);
					PrintToChat(client, "\x03[RP] %T", "Respawn_Time", client, r_time);
					return Plugin_Handled;
				}
				if (admin != INVALID_ADMIN_ID)
				{			
					DisplayMenu(g_VIPTeamMenu, client, MENU_TIME_FOREVER);
				}
				return Plugin_Handled;
			}
		}
		if (just_joined[client] == 1)
		{
			new AdminId:admin = GetUserAdmin(client);
			if (admin == INVALID_ADMIN_ID)
			{
				DisplayMenu(g_TeamMenu, client, MENU_TIME_FOREVER);
			}
			if (admin != INVALID_ADMIN_ID)
			{			
				DisplayMenu(g_VIPTeamMenu, client, MENU_TIME_FOREVER);
			}
			return Plugin_Handled;
		}
		if (h_class_changeable[client] == 1)
		{
			if (IsCuffed[client])
			{
				PrintToChat(client, "\x04[RP] %T", "Handcuffed", client);
				return Plugin_Handled;
			}
			new AdminId:admin = GetUserAdmin(client);
			if (admin == INVALID_ADMIN_ID)
			{
				DisplayMenu(g_TeamMenu, client, MENU_TIME_FOREVER);
			}
			if (admin != INVALID_ADMIN_ID)
			{			
				DisplayMenu(g_VIPTeamMenu, client, MENU_TIME_FOREVER);
			}
			return Plugin_Handled;
		}
		if (h_class_changeable[client] == 0)
		{
			if (IsPlayerAlive(client))
			{
				PrintToChat(client, "\x03[RP] %T", "Class_Wait", client);
				return Plugin_Handled;
			}
		}
	}
	else PrintToChat(client, "\x04[RP] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Command_Bank(client, args)
{
	if(GetConVarInt(g_Cvar_ATMUse))
	{
		if (AtATM[client] == false)
		{
			PrintToChat(client, "\x03[RP] %T", "Go_To_ATM", client);
			return Plugin_Handled;			
		}
		else
		{
			new Handle:atm = CreateMenu(Menu_Bank);
			new String:title_str[32], String:deposit_str[32], String:withdraw_str[32];
			
			Format(title_str, sizeof(title_str), "%T", "ATM_Menu", client);
			Format(deposit_str, sizeof(deposit_str), "%T", "Deposit", client);
			Format(withdraw_str, sizeof(withdraw_str), "%T", "Withdraw", client);
			
			AddMenuItem(atm,"deposit", deposit_str);
			AddMenuItem(atm,"withdraw", withdraw_str);
			SetMenuTitle(atm, title_str);

			DisplayMenu(atm, client, MENU_TIME_FOREVER);
			PrintToChat(client, "\x03[RP] %T", "Bank", client, bank[client]);		
		}
	}
	else
	{
		new Handle:atm = CreateMenu(Menu_Bank);
		new String:title_str[32], String:deposit_str[32], String:withdraw_str[32];
			
		Format(title_str, sizeof(title_str), "%T", "Bank_Menu", client);
		Format(deposit_str, sizeof(deposit_str), "%T", "Deposit", client);
		Format(withdraw_str, sizeof(withdraw_str), "%T", "Withdraw", client);
			
		AddMenuItem(atm,"deposit", deposit_str);
		AddMenuItem(atm,"withdraw", withdraw_str);
		SetMenuTitle(atm, title_str);

		DisplayMenu(atm, client, MENU_TIME_FOREVER);
			
		DisplayMenu(atm, client, MENU_TIME_FOREVER);
		PrintToChat(client, "\x03[RP] %T", "Bank", client, bank[client]);
	}
	return Plugin_Handled;
}
public Action:Command_Settings(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new Handle:settings = CreateMenu(Menu_Settings);
		new String:title_str[32];
		new String:gender_str[32];
		new String:switch_str[32];
		
		Format(title_str, sizeof(title_str), "%T", "Settings_Menu", client);
		SetMenuTitle(settings, title_str);

		if (player_gender[client] == 0)
		{
			Format(gender_str, sizeof(gender_str), "%T", "Youre_Female", client);
			Format(switch_str, sizeof(switch_str), "%T", "Be_Male", client);
			
			AddMenuItem(settings, "FEMALE", gender_str, ITEMDRAW_DISABLED);
			AddMenuItem(settings, "MALE", switch_str);
		}
		else if (player_gender[client] == 1)
		{
			Format(gender_str, sizeof(gender_str), "%T", "Youre_Male", client);
			Format(switch_str, sizeof(switch_str), "%T", "Be_Female", client);
			
			AddMenuItem(settings, "FEMALE", switch_str);
			AddMenuItem(settings, "MALE", gender_str, ITEMDRAW_DISABLED);
		}
		else
		{
			player_gender[client] = 1;
			AddMenuItem(settings, "NULL", "There was a problem with your gender selection.", ITEMDRAW_DISABLED);
			AddMenuItem(settings, "NULL", "You were switched to Male.", ITEMDRAW_DISABLED);			
		}
		
		// player_cash_or_dd -- 0 = Cash 1 = DD
		if (player_cash_or_dd[client] == 0)
		{
			AddMenuItem(settings, "CASH", "Get Paid in Cash (SELECTED)", ITEMDRAW_DISABLED);
			AddMenuItem(settings, "DD", "Get Paid by Direct Deposit");			
		}
		else if (player_cash_or_dd[client] == 1)
		{
			AddMenuItem(settings, "CASH", "Get Paid in Cash");
			AddMenuItem(settings, "DD", "Get Paid by Direct Deposit (SELECTED)", ITEMDRAW_DISABLED);			
		}
		else
		{
			player_cash_or_dd[client] = 0;
			AddMenuItem(settings, "NULL", "There was a problem with your pay selection.", ITEMDRAW_DISABLED);
			AddMenuItem(settings, "NULL", "You were switched to get paid in Cash.", ITEMDRAW_DISABLED);	
		}
		DisplayMenu(settings, client, MENU_TIME_FOREVER);
	}
	else PrintToChat(client, "\x04[RP] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Command_Special(client, args)
{
	if (IsPlayerAlive(client))
	{
		if (GetConVarInt(g_Cvar_Enable))
		{
			if (IsCuffed[client])
			{
				PrintToChat(client, "\x04[RP] %T", "Handcuffed", client);
				return Plugin_Handled;
			}
			if (g_SpecialMenu == INVALID_HANDLE)
			{
				PrintToConsole(client, "[RP DEBUG] There was an error generating the Special menu.");
				PrintToServer("[RP DEBUG] There was an error generating the Special menu.");
			}
			else DisplayMenu(g_SpecialMenu, client, MENU_TIME_FOREVER);
		}
		else PrintToChat(client, "\x04[RP] %T", "Disabled", client);
	}
	else PrintToChat(client, "\x04[RP] %T", "Youre_Dead", client);
	return Plugin_Handled;
}



// ######
// TIMERS
// ######



public Action:Pay_Time(Handle:timer)
{
	new String:ClassName[64];
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && (GetClientTeam(client) > 1))
		{
			new c = player_class[client];
			if (c > MAXCLASSES)
			{
				c = GetConVarInt(g_DefaultClass);
			}
			else if (c < 0)
			{
				c = GetConVarInt(g_DefaultClass);
			}
			new tax = 0;
			if (doorAmount[client] > 0)
			{
				new tax_inc = GetConVarInt(g_Door_Tax);
				tax = (tax_inc *= doorAmount[client]);
			}

			// Ok we know how much to give them, let's do it!!
			// We will do Direct Deposit first...  Any errors will be done by cash.
			if (player_cash_or_dd[client] == 1)
			{
				new wallet = bank[client];
				wallet += class_salary[c];
				wallet -= tax;
				
				if (wallet < 0)
				{
					bank[client] = 0;
					PrintToChat(client, "\x03[RP] %T", "Paid_By_DD", client, class_salary[c]);
					PrintToChat(client, "\x03[RP] %T", "Paid_For_Doors", client, tax);
					PrintToChat(client, "\x03[RP] Because you can no longer afford your doors you have lost ownership of them.");
					
					//Defaults:
					for(new X = 1; X < MAXDOORS; X++)
					{
						if (IsValidEdict(X))
						{
							GetEdictClassname(X, ClassName, 255);
							if (!StrEqual(ClassName, "prop_vehicle_driveable", false))
							{
								//Clear:
								OwnsDoor[client][X] = 0;
							}
						}
					}
					doorAmount[client] = 0;
				}
				else if (wallet >= 0)
				{
					bank[client] += class_salary[c];
					bank[client] -= tax;

					PrintToChat(client, "\x03[RP] %T", "Paid_By_DD", client, class_salary[c]);
					if (tax > 0)
					{
						PrintToChat(client, "\x03[RP] %T", "Paid_For_Doors", client, tax);
					}
				}
				PrintToChat(client, "\x03[RP] %T", "Bank", client, bank[client]);
			}
			else
			{
				player_cash_or_dd[client] = 0;
				new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
				money[client] = GetEntData(client, MoneyOffset, 4);
			
				new wallet = money[client];
				wallet += class_salary[c];
				wallet -= tax;

				if (wallet < 0)
				{
					money[client] = 0;
					SetEntData(client, MoneyOffset, 0, 4, true);

					PrintToChat(client, "\x03[RP] %T", "Paid_In_Cash", client, class_salary[c]);
					PrintToChat(client, "\x03[RP] %T", "Paid_For_Doors", client, tax);
					PrintToChat(client, "\x03[RP] Because you can no longer afford your doors you have lost ownership of them.");
				
					//Defaults:
					for(new X = 1; X < MAXDOORS; X++)
					{
						if (IsValidEdict(X))
						{
							GetEdictClassname(X, ClassName, 255);
							if (!StrEqual(ClassName, "prop_vehicle_driveable", false))
							{
								//Clear:
								OwnsDoor[client][X] = 0;
							}
						}
					}
					doorAmount[client] = 0;
				}
				else if ((wallet >= 0) && (wallet <= 65535))
				{
					money[client] = wallet;
					SetEntData(client, MoneyOffset, wallet, 4, true);

					PrintToChat(client, "\x03[RP] %T", "Paid_In_Cash", client, class_salary[c]);
					if (tax > 0)
					{
						PrintToChat(client, "\x03[RP] %T", "Paid_For_Doors", client, tax);
					}
				}
				else if (wallet > 65535)
				{
					money[client] = 65535;
					SetEntData(client, MoneyOffset, 65535, 4, true);
					if(GetConVarInt(g_Cvar_ATMUse))
					{
						PrintToChat(client, "\x03[RP] You can only carry $65535.");
						PrintToChat(client, "\x03[RP] Use an ATM to put some money into your bank account, or use !rp_settings to switch to Direct Deposit.");
					}
					else
					{
						PrintToChat(client, "\x03[RP] You can only carry $65535.");
						PrintToChat(client, "\x03[RP] Use !bank to put some money into your bank account, or use !rp_settings to switch to Direct Deposit.");
					}
				}
			}
			new t = player_team[client];
			if ((GetConVarInt(g_Cvar_TeamMode)) && (team_competing[t]))
			{
				team_points[t] += class_salary[c];
				team_points[t] -= tax;
				if (team_points[t] <= 0)
				{
					team_points[t] = 0;
				}
			}
 		}
	}
	// At this point we tell all the printers to generate money.
	for (new printer = 1; printer <= 2048; printer++)
	{
		if (IsValidEdict(printer))
		{
			if (IsValidEntity(printer))
			{
				if (IsPrinter[printer])
				{
					//Class Name:
					GetEdictClassname(printer, ClassName, 255);
		
					if ((StrEqual(ClassName, "prop_physics")) || (StrEqual(ClassName, "prop_physics_multiplayer")) || (StrEqual(ClassName, "prop_physics_override")))
					{
						printerMoney[printer] += 1;
						if (printerMoney[printer]  >= 5)
						{
							printerMoney[printer] = 4;
						}
					}
					else
					{
						IsPrinter[printer] = false;
						printerMoney[printer] = 0;
					}
				}
			}
		}
	}
	if (GetConVarInt(g_Cvar_TeamMode))
	{
		// Team competition mode is on.  Count pays until the 6th pay (30 minutes) then compare scores and award bonuses.
		if (team_turn_count < 5)
		{
			team_turn_count += 1;
		}
		else
		{
			team_turn_count = 0;
			new winner_buffer = 0;
			new winners = 1;
			new buffer_2 = 0;
			for (new i_t = 0; i_t <= team_index; i_t++)
			{
				if ((team_points[winner_buffer] < team_points[i_t]) && (winner_buffer != i_t))
				{
					winner_buffer = i_t;
					winners = 1;					
					for (buffer_2 = 0; buffer_2 <= team_index; buffer_2++)
					{
						winning[buffer_2] = 0;
					}
					winning[i_t] = 1;
				}
				else if (team_points[winner_buffer] == team_points[i_t])
				{
					winner_buffer = i_t;
					winners += 1;
					winning[i_t] = 1;
				}
			}

			// Okay we found the winners, now distribute $$.
			new qty_of_players = 0;
			new earnings = 0;
			if (winners == 1)
			{
				new lol = winner_buffer;
				// Count players on winning team...
				for (new pp = 1; pp <= MaxClients; pp++)
				{
					if ((IsClientInGame(pp)) && (player_team[pp] == lol))
					{
						qty_of_players += 1;
					}
				}
				if (qty_of_players > 0)
				{
					earnings = ((team_points[lol] / qty_of_players) / 2);
					for (new pp = 1; pp <= MaxClients; pp++)
					{
						if ((IsClientInGame(pp)) && (player_team[pp] == lol))
						{
							bank[pp] += earnings;
							PrintToChat(pp, "\x03[RP] You got $%i as a bonus because your team (%s) made the most money this round.", earnings, player_team[pp]);
						}
					}
				}				
			}
			else if (winners > 1)
			{
				// First add all money...
				new lmao = 0;
				new loller = 0;
				for (lmao = 0; lmao <= team_index; lmao++)
				{
					if (winning[lmao] == 1)
					{
						loller += team_points[lmao];
					}
				}
				// loller is the total score of the winning teams.
				// Now we count the number of winning players.
				new temp = 0;
				for (new pp = 1; pp <= MaxClients; pp++)
				{
					if (IsClientInGame(pp))
					{
						temp = player_team[pp];
						if (winning[temp] == 1)
						{
							qty_of_players += 1;
						}
					}
				}
				if ((qty_of_players > 0) && (loller > 0))
				{
					earnings = ((loller / qty_of_players) / 2);
					for (new pp = 1; pp <= MaxClients; pp++)
					{
						if (IsClientInGame(pp))
						{
							temp = player_team[pp];
							if (winning[temp] == 1)
							{
								bank[pp] += earnings;
								PrintToChat(pp, "\x03[RP] You got $%i as a bonus because your team (%s) tied for making the most money this round.", earnings, team_name[temp]);
							}
						}	
					}
				}
			}
			for (new i_t = 0; i_t <= team_index; i_t++)
			{
				team_points[i_t] = 0;
				winning[i_t] = 0;
			}
			PrintToChatAll("\x04[RP] 30 Minutes passed.  Team scores reset.");
		}
	}
	// Okay now that everyone got paid let's save the DB because if the server crashed, it wouldn't remember anything.
	if (save_time == 2)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{	
				GetClientAuthId(client, AuthId_Engine, authid[client], sizeof(authid[]));
				PrintToServer("[RP] Auto Save -- updating client %N (%s) in SQL Database. B: %i  M: %i", client, authid[client], bank[client], money[client]);
				LogMessage("[RP] Auto Save -- updating client %N (%s) in SQL Database. B: %i  M: %i", client, authid[client], bank[client], money[client]);
				DBSave(client);
			}
		}
		save_time = 0;
	}
	else if (save_time == 1)
	{
		save_time = 2;
	}
	else if (save_time == 0)
	{
		save_time = 1;
	}
}
public Action:Respawn_Time(Handle:timer, any:param1)
{
	h_class_changeable[param1] = 1;
}
public Action:Respawn_Time_B(Handle:timer, any:param1)
{
	if (IsClientInGame(param1))
	{
		if (!IsPlayerAlive(param1))
		{
			if (player_respawn_wait[param1] > 1)
			{
				player_respawn_wait[param1] -= 1;
				CreateTimer(1.0, Respawn_Time_B, param1);
			}
			else
			{	
				player_respawn_wait[param1] = 0;
				h_respawnable[param1] = 1;
		
				new Handle:respawn_temp_menu = CreateMenu(Respawn_Menu);
				AddMenuItem(respawn_temp_menu, "g_InfoMenu", "Press 1 to Respawn");
				SetMenuTitle(respawn_temp_menu, "");
				DisplayMenu(respawn_temp_menu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}
public Respawn_Menu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (IsClientInGame(param1))
		{
			if (!IsPlayerAlive(param1))
			{
				CS_RespawnPlayer(param1);
			}
		}
	}
	return;
}
public Action:Respawn_Time_Fuck(Handle:timer, any:client)
{
    if (IsClientInGame(client))
    {
		if (IsPlayerAlive(client))
		{
			new plyr_gun1 = GetPlayerWeaponSlot(client, 1);
			new plyr_gun2 = GetPlayerWeaponSlot(client, 2);
			// We now know the player's guns.  Let's figure out if we give a knife to them or not.
			if (IsValidEntity(plyr_gun1))
			{
				RemovePlayerItem(client, plyr_gun1);
				RemoveEdict(plyr_gun1);
			}
			if (!IsValidEntity(plyr_gun2))
			{
				GivePlayerItem(client, WPN_KNFE);
			}
		}
	}
}



// #############
// DOOR COMMANDS
// #############



//Give Door:
public Action:CommandGiveDoor(client, Arguments)
{

	//Arguments:
	if(Arguments < 1)
	{

		//Print:
		PrintToConsole(client, "[RP] Usage: rp_givedoor <Name>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl MaxPlayers, Player;
	decl String:PlayerName[32];

	//Initialize:
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));

	//Find:
	MaxPlayers = GetMaxClients();
	for(new X = 1; X <= MaxPlayers ; X++)
	{

		//Connected:
		if(!IsClientConnected(X)) continue;

		//Declare:
		decl String:Name[32];

		//Initialize:
		GetClientName(X, Name, sizeof(Name));

		//Save:
		if(StrContains(Name, PlayerName, false) != -1) Player = X;
	}

	//Invalid Name:
	if(Player == -1)
	{

		//Print:
		PrintToConsole(client, "[RP] Could not find client %s", PlayerName);

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl Ent;
	decl String:Name[32], String:ClassName[255];

	//Name:
	GetClientName(Player, Name, 32);

	//Ent:
	Ent = GetClientAimTarget(client, false);

	//Error:
	if(Ent <= 1)
	{

		//Print:
		PrintToConsole(client, "[RP] Invalid Door.");

		//Return:
		return Plugin_Handled;
	}

	//Classname:
	GetEdictClassname(Ent, ClassName, 255);

	//Error:
	if(!(StrEqual(ClassName, "func_door") || StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating") || StrEqual(ClassName, "prop_vehicle_driveable")))
	{

		//Print:
		PrintToConsole(client, "[RP] Invalid Door.");

		//Return:
		return Plugin_Handled;
	}

	//Has Door Already:
	if(OwnsDoor[Player][Ent] == 1)
	{

		//Print:
		PrintToConsole(client, "[RP] Player already owns that door");

		//Return:
		return Plugin_Handled;
	}

	//Save:
	OwnsDoor[Player][Ent] = 1;
	doorAmount[Player] += 1;

	//Print:
	PrintToConsole(client, "[RP] %s has been given ownership of door #%d.", Name, Ent);
	PrintToChat(Player, "\x03[RP] You have been given ownership of door #%d.", Ent);

	//Return:
	return Plugin_Handled;
}

//Take Door:
public Action:CommandTakeDoor(client, Arguments)
{

	//Arguments:
	if(Arguments < 1)
	{

		//Print:
		PrintToConsole(client, "[RP] Usage: rp_takedoor <Name>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl MaxPlayers, Player;
	decl String:PlayerName[32];

	//Initialize:
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));

	//Find:
	MaxPlayers = GetMaxClients();
	for(new X = 1; X <= MaxPlayers ; X++)
	{

		//Connected:
		if(!IsClientConnected(X)) continue;

		//Declare:
		decl String:Name[32];

		//Initialize:
		GetClientName(X, Name, sizeof(Name));

		//Save:
		if(StrContains(Name, PlayerName, false) != -1) Player = X;
	}

	//Invalid Name:
	if(Player == -1)
	{

		//Print:
		PrintToConsole(client, "[RP] Could not find client %s", PlayerName);

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl Ent;
	decl String:Name[32], String:ClassName[255];

	//Name:
	GetClientName(Player, Name, 32);

	//Ent:
	Ent = GetClientAimTarget(client, false);

	//Error:
	if(Ent <= 1)
	{

		//Print:
		PrintToConsole(client, "[RP] Invalid Door.");

		//Return:
		return Plugin_Handled;
	}

	//Classname:
	GetEdictClassname(Ent, ClassName, 255);

	//Error:
	if(!(StrEqual(ClassName, "func_door") || StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating") || StrEqual(ClassName, "prop_vehicle_driveable")))
	{

		//Print:
		PrintToConsole(client, "[RP] Invalid Door.");

		//Return:
		return Plugin_Handled;
	}

	//Not Owner:
	if(OwnsDoor[Player][Ent] != 1)
	{

		//Print:
		PrintToConsole(client, "[RP] Player does not own that door");

		//Return:
		return Plugin_Handled;
	}

	//Save:
	OwnsDoor[Player][Ent] = 0;
	doorAmount[Player] -= 1;
	AcceptEntityInput(Ent, "Unlock", client);

	for (new i = 1; i <= MaxClients; i += 1)
	{
		if(AccessDoor[i][Ent] != 1)
		{
			continue;
		}
		else if(AccessDoor[i][Ent] == 1)
		{
			AccessDoor[i][Ent] = 0;
		}
	}
	//Update:
	PrintToConsole(client, "[RP] %s has lost ownership of door #%d.", Name, Ent);
	PrintToChat(Player, "[RP] You have lost ownership of door #%d.", Ent);



	//Return:
	return Plugin_Handled;
}



// ##############
// DOOR FUNCTIONS
// ##############



//Prethink:
public OnGameFrame()
{

	//Declare:
	decl MaxPlayers;

	//Initialize:
	MaxPlayers = GetMaxClients();

	//Loop:
	for(new client = 1; client <= MaxPlayers; client++)
	{

		//Connected:
		if(IsClientConnected(client) && IsClientInGame(client))
		{

			//Alive:
			if(IsPlayerAlive(client))
			{
				//Shift:
				if(GetClientButtons(client) & IN_SPEED)
				{
					//Overflow:
					if(!PrethinkBuffer[client])
					{

						//Action:
						CommandSpeed(client);

						//UnHook:
						PrethinkBuffer[client] = true;
					}
				}
				//Weapon 2:
				else if(GetClientButtons(client) & IN_ATTACK2)
				{
					//Overflow:
					if(!PrethinkBuffer[client])
					{
						//Action:
						CommandAttack2(client);

						//UnHook:
						PrethinkBuffer[client] = true;
					}
				}
				else if(GetClientButtons(client) & IN_USE)
				{
					if(!PrethinkBuffer[client])
					{
						//Action:
						CommandUse(client);

						//UnHook:
						PrethinkBuffer[client] = true;
					}
				}
				//Nothing:
				else
				{

					//Hook:
					PrethinkBuffer[client] = false;
				}
			}
		}
	}
}
public Action:A_Time(Handle:timer, any:client)
{
	if(DrunkTime[client] > 0)
	{
        if (IsClientInGame(client))
		{		
			new Float:vecPunch[3];
			vecPunch[0] = GetRandomFloat(-50.0, 50.0);
			vecPunch[1] = GetRandomFloat(-50.0, 50.0);
			vecPunch[2] = GetRandomFloat(-50.0, 50.0);
        
			if (offsPunchAngle != -1)
			{
				SetEntDataVector(client, offsPunchAngle, vecPunch);
			}

			DrunkTime[client] -= 1;
			SetEntityRenderColor(client, 255, 255, 100, 255);
			h_drunk_b = CreateTimer(0.50, B_Time, client);				
		}	
	}
	else if(DrunkTime[client] <= 0)
	{
		DrunkTime[client] = 0;
		Drunk[client] = 0;
		SetEntityRenderColor(client, 255, 255, 255, 255);

		new String:clientName[32];
		GetClientName(client, clientName, 32);

		new Float:distance;
		decl Float:PosVec[3], Float:PosVec2[3];							
		GetClientEyePosition(client, PosVec);		
		
		for (new i = 1; i <= MaxClients; i += 1)
		{
			if (IsClientInGame(i))
			{
				GetClientEyePosition(i, PosVec2);
				distance = GetVectorDistance(PosVec, PosVec2);
				if (512.0 >= distance)
				{
					PrintToChat(i, "*** %s is sobering up ***", clientName);
				}
			}
		}		
	}
}
public Action:B_Time(Handle:timer, any:client)
{
	if(DrunkTime[client] > 0)
	{
        if (IsClientInGame(client))
		{
			
			new Float:vecPunch[3];
			vecPunch[0] = GetRandomFloat(-50.0, 50.0);
			vecPunch[1] = GetRandomFloat(-50.0, 50.0);
			vecPunch[2] = GetRandomFloat(-50.0, 50.0);
        
			if (offsPunchAngle != -1)
			{
				SetEntDataVector(client, offsPunchAngle, vecPunch);
			}

			DrunkTime[client] -= 1;
			SetEntityRenderColor(client, 255, 255, 100, 255);
			h_drunk_a = CreateTimer(0.50, A_Time, client);				
		}	
	}
	else if(DrunkTime[client] <= 0)
	{
		DrunkTime[client] = 0;
		Drunk[client] = 0;
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		new String:clientName[32];
		GetClientName(client, clientName, 32);

		new Float:distance;
		decl Float:PosVec[3], Float:PosVec2[3];							
		GetClientEyePosition(client, PosVec);		
		
		for (new i = 1; i <= MaxClients; i += 1)
		{
			if (IsClientInGame(i))
			{
				GetClientEyePosition(i, PosVec2);
				distance = GetVectorDistance(PosVec, PosVec2);
				if (512.0 >= distance)
				{
					PrintToChat(i, "*** %s is sobering up ***", clientName);
				}
			}
		}	
	}
}


//Shift Key:
public Action:CommandSpeed(client)
{

	//Declare:
	decl String:ClassName[255];
	//Initialize:
	new Ent = GetClientAimTarget(client, false);
	new t = player_team[client];
	new c = player_class[client];

	//Valid:
	if ((Ent >= 1) && (IsValidEntity(Ent)))
	{
		//Class Name:
		GetEdictClassname(Ent, ClassName, 255);
		if (AccessTeam[t][Ent] == 1)
     	{
			//Valid:
			if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating") || StrEqual(ClassName, "prop_vehicle_driveable"))
			{
				//Lock:
				if(Locked[Ent] != 1)
				{

					//Lock:
					Locked[Ent] = 1;

					//Print:
					PrintToChat(client, "\x03[RP] %T", "You_Locked_Door", client);

					//Lock:
					AcceptEntityInput(Ent, "Lock", client);
					EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
				}

				//Unlock:
				else if(Locked[Ent] == 1)
				{

					//Unlock:
					Locked[Ent] = 0;

					//Print:
					PrintToChat(client, "\x03[RP] %T", "You_Unlocked_Door", client);

					//Unlock:
					AcceptEntityInput(Ent, "Unlock", client);
					EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
				}
			}
     	}
		else if (AccessClass[c][Ent] == 1)
     	{
			//Valid:
			if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating") || StrEqual(ClassName, "prop_vehicle_driveable"))
			{
				//Lock:
				if(Locked[Ent] != 1)
				{

					//Lock:
					Locked[Ent] = 1;

					//Print:
					PrintToChat(client, "\x03[RP] %T", "You_Locked_Door", client);

					//Lock:
					AcceptEntityInput(Ent, "Lock", client);
					EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
				}

				//Unlock:
				else if(Locked[Ent] == 1)
				{

					//Unlock:
					Locked[Ent] = 0;

					//Print:
					PrintToChat(client, "\x03[RP] %T", "You_Unlocked_Door", client);

					//Unlock:
					AcceptEntityInput(Ent, "Unlock", client);
					EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
				}
			}
     	}
		//Ownership:
		else if(OwnsDoor[client][Ent] == 1)
		{
			//Valid:
			if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating") || StrEqual(ClassName, "prop_vehicle_driveable"))
			{
				//Lock:
				if(Locked[Ent] != 1)
				{

					//Lock:
					Locked[Ent] = 1;

					//Print:
					PrintToChat(client, "\x03[RP] %T", "You_Locked_Door", client);

					//Lock:
					AcceptEntityInput(Ent, "Lock", client);
					EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
				}

				//Unlock:
				else if(Locked[Ent] == 1)
				{

					//Unlock:
					Locked[Ent] = 0;

					//Print:
					PrintToChat(client, "\x03[RP] %T", "You_Unlocked_Door", client);

					//Unlock:
					AcceptEntityInput(Ent, "Unlock", client);
					EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
				}
			}
		}
		else if(AccessDoor[client][Ent] == 1)
		{
			//Valid:
			if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating") || StrEqual(ClassName, "prop_vehicle_driveable"))
			{
				//Lock:
				if(Locked[Ent] != 1)
				{

					//Lock:
					Locked[Ent] = 1;

					//Print:
					PrintToChat(client, "\x03[RP] %T", "You_Locked_Door", client);

					//Lock:
					AcceptEntityInput(Ent, "Lock", client);
					EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
				}

				//Unlock:
				else if(Locked[Ent] == 1)
				{

					//Unlock:
					Locked[Ent] = 0;

					//Print:
					PrintToChat(client, "\x03[RP] %T", "You_Unlocked_Door", client);

					//Unlock:
					AcceptEntityInput(Ent, "Unlock", client);
					EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
				}
			}
		}
	}
}

//Attack 2:
public Action:CommandAttack2(client)
{

	//Declare:
	decl Ent;
	decl String:ClassName[255];
	//Initialize:
	Ent = GetClientAimTarget(client, false);

	//Valid:
	if(Ent != -1)
	{
		//Class Name:
		GetEdictClassname(Ent, ClassName, 255);

		//Valid:
		if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
		{
			new String:targetname[64];
			GetTargetName(Ent,targetname,sizeof(targetname));
			//Ownership:
			if(OwnsDoor[client][Ent] == 1)
			{
				if(Locked[Ent] != 1)
				{
					PrintToChat(client, "\x03[RP] You own this door (%s) and it is \x04UNLOCKED\x03. (#%i)", targetname, Ent);
				}
				if(Locked[Ent] == 1)
				{
					PrintToChat(client, "\x03[RP] You own this door (%s) and it is \x04LOCKED\x03. (#%i)", targetname, Ent);
				}
			}
			else if(OwnsDoor[client][Ent] == 0)
			{
				if(AccessDoor[client][Ent] == 1)
				{
					if(Locked[Ent] != 1)
					{
						PrintToChat(client, "\x03[RP] You have access to this door (%s) and it is \x04UNLOCKED\x03. (#%i)", targetname, Ent);
					}
					if(Locked[Ent] == 1)
					{
						PrintToChat(client, "\x03[RP] You have access to this door (%s) and it is \x04LOCKED\x03. (#%i)", targetname, Ent);
					}
				}
				else if(AccessDoor[client][Ent] == 0)
				{
					new t = player_team[client];
					if (AccessTeam[t][Ent] == 1)
     				{
						if(Locked[Ent] != 1)
						{
							PrintToChat(client, "\x03[RP] Your team (%s) has access to this door (%s) and it is \x04UNLOCKED\x03. (#%i)", team_name[t], targetname, Ent);
						}
						if(Locked[Ent] == 1)
						{
							PrintToChat(client, "\x03[RP] Your team (%s) has access to this door (%s) and it is \x04LOCKED\x03. (#%i)", team_name[t], targetname, Ent);
						}
					}
					else if (AccessTeam[t][Ent] != 1)
					{
						new c = player_class[client];
						if (AccessClass[c][Ent] == 1)
						{
							if(Locked[Ent] != 1)
							{
								PrintToChat(client, "\x03[RP] Your class (%s) has access to this door (%s) and it is \x04UNLOCKED\x03. (#%i)", class_name[c], targetname, Ent);
							}
							if(Locked[Ent] == 1)
							{
								PrintToChat(client, "\x03[RP] Your class (%s) has access to this door (%s) and it is \x04LOCKED\x03. (#%i)", class_name[c], targetname, Ent);
							}							
						}
						else
						{
							if(Locked[Ent] != 1)
							{
								PrintToChat(client, "\x03[RP] You don't have access to this door but it is \x04UNLOCKED\x03. (#%i)", Ent);
							}
							if(Locked[Ent] == 1)
							{
								PrintToChat(client, "\x03[RP] You don't have access to this door and it is \x04LOCKED\x03. (#%i)", Ent);
							}
						}
					}
				}
			}
		}
		else if (StrEqual(ClassName, "prop_vehicle_driveable") && car_menu)
		{
			new String:targetname[64];
			GetTargetName(Ent,targetname,sizeof(targetname));
			PrintToChat(client, "\x04[Info] Entity #: %i Name: %s", Ent, targetname);
			
			new owner = GetCarOwner(Ent);
			
			PrintToChat(client, "\x04[Info] Car's Owner:  %N", owner);
			
			new Driver = GetEntPropEnt(Ent, Prop_Send, "m_hPlayer");
			if (Driver != -1)
			{
				new String:name[32];
				GetClientName(Driver, name, sizeof(name));
				if(Locked[Ent] != 1)
				{
					PrintToChat(client, "\x03[RP] This car is being driven by %s and it is \x04UNLOCKED\x03.", name);
				}
				if(Locked[Ent] == 1)
				{
					PrintToChat(client, "\x03[RP] This car is being driven by %s and it is \x04LOCKED\x03.", name);
				}
				if(player_team[client] == 0)
				{
					new speed = GetEntProp(Ent, Prop_Data, "m_nSpeed");
					PrintHintText(client, "Vehicle Speed: %i", speed);
				}
			}
			if (Driver == -1)
			{
				if(Locked[Ent] != 1)	
				{	
					PrintToChat(client, "\x03[RP] This car has no driver but it is \x04UNLOCKED\x03.");
				}
				if(Locked[Ent] == 1)	
				{	
					PrintToChat(client, "\x03[RP] This car has no driver and it is \x04LOCKED\x03.");
				}
			}
		}
		else if (StrEqual(ClassName, "player"))
		{	
			new String:title_str[32], String:cash_str[32], String:warrant_str[32], String:unwarrant_str[32], String:debit_str[32], String:cuff_str[32], String:demote_str[32];
			Format(title_str, sizeof(title_str), "Player: %N", Ent);
			Format(cash_str, sizeof(cash_str), "%T", "Give_Cash", client);
			Format(debit_str, sizeof(debit_str), "%T", "Use_Card", client);
			Format(demote_str, sizeof(demote_str), "%T", "Demote", client);
			Format(warrant_str, sizeof(warrant_str), "%T", "Warrant", client);
			Format(unwarrant_str, sizeof(unwarrant_str), "%T", "Unwarrant", client);
			Format(cuff_str, sizeof(cuff_str), "%T", "Break_Cuffs", client);
			
			new Handle:player_menu = CreateMenu(Menu_Player);

			SetMenuTitle(player_menu, title_str);
			
			new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			money[client] = GetEntData(client, MoneyOffset, 4);
			if (money[client] > 0)
			{
				AddMenuItem(player_menu, "1", cash_str);
			}
			else AddMenuItem(player_menu, "1", cash_str, ITEMDRAW_DISABLED);
			
			if (bank[client] > 0)
			{
				AddMenuItem(player_menu, "2", debit_str);
			}
			else AddMenuItem(player_menu, "2", debit_str, ITEMDRAW_DISABLED);
			
			new c = player_class[client];
			
			if ((GetClientTeam(client) == 3) && (class_authority[c] == 1))
			{
				if(!Warranted[Ent])
				{
					AddMenuItem(player_menu, "4", warrant_str);
				}
				else
				{
					AddMenuItem(player_menu, "4", unwarrant_str);
				}
			}
			else
			{
				if(!Warranted[Ent])
				{
					AddMenuItem(player_menu, "4", warrant_str, ITEMDRAW_DISABLED);
				}
				else
				{
					AddMenuItem(player_menu, "4", unwarrant_str, ITEMDRAW_DISABLED);
				}
			}
			
			new team = GetClientTeam(client);
			if ((team == 2) && (IsCuffed[client] == false))
			{
				if (IsCuffed[Ent] == true)
				{
					AddMenuItem(player_menu, "5", cuff_str);
				}
				else AddMenuItem(player_menu, "5", cuff_str, ITEMDRAW_DISABLED);
			}
			
			if (player_team[client] == player_team[Ent])
			{
				if (player_class[client] != player_class[Ent])
				{
					new c_c = player_class[client];
					new c_Ent = player_class[Ent];
						
					// We finally have all the info for the second player.  Let's finish this.
						
					if (class_authority[c_c] < class_authority[c_Ent])
					{
						AddMenuItem(player_menu, "3", demote_str);
					}
					else AddMenuItem(player_menu, "3", demote_str, ITEMDRAW_DISABLED);
				}
				else AddMenuItem(player_menu, "3", demote_str, ITEMDRAW_DISABLED);
			}
			else AddMenuItem(player_menu, "3", demote_str, ITEMDRAW_DISABLED);
			targeted_player[client] = Ent;
			
			DisplayMenu(player_menu, client, MENU_TIME_FOREVER);
			return;			
		}
		else if ((StrEqual(ClassName, "prop_physics")) || (StrEqual(ClassName, "prop_physics_multiplayer")) || (StrEqual(ClassName, "prop_physics_override")))
		{
			if (IsPrinter[Ent])
			{
				new print_inc = GetConVarInt(g_PrinterMoney);
				new printercash = (printerMoney[Ent] * print_inc);
				if (printercash < 0)
				{
					printercash = 0;
				}				
				PrintHintText(client, "%T", "Money_Printer_Hint", client, printercash);
			}
		}
	}
}
//USE:
public Action:CommandUse(client)
{
	//Declare:
	decl Ent;
	decl String:ClassName[255];
	//Initialize:
	Ent = GetClientAimTarget(client, false);

	//Valid:
	if(Ent != -1)
	{
		//Class Name:
		GetEdictClassname(Ent, ClassName, 255);
		
		if ((StrEqual(ClassName, "prop_physics")) || (StrEqual(ClassName, "prop_physics_multiplayer")) || (StrEqual(ClassName, "prop_physics_override")))
		{
			if (IsPrinter[Ent])
			{
				new Float:origin[3];
				new Float:item_origin[3];
				new Float:distance;

				GetClientAbsOrigin(client, origin);	
				GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", item_origin);
				distance = GetVectorDistance(origin, item_origin, false);

				if ((printerMoney[Ent] > 0) && (distance < 80.00))
				{
					new print_inc = GetConVarInt(g_PrinterMoney);
					new printercash = (printerMoney[Ent] * print_inc);
					
					PrintToChat(client, "\x03[RP] %T", "Money_Printer_Gives", client, printercash);
					EmitSoundToAll("buttons/button3.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);

					new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
					money[client] = GetEntData(client, MoneyOffset, 4);
					money[client] += printercash;
					
					new t = player_team[client];
					if ((GetConVarInt(g_Cvar_TeamMode)) && (team_competing[t]))
					{
						team_points[t] += printercash;
					}
					
					if (money[client] > 65535)
					{
						money[client] = 65535;
					}
					SetEntData(client, MoneyOffset, money[client], 4, true);
					printerMoney[Ent] = 0;
				}
				else if ((printerMoney[Ent] <= 0) && (distance < 80.00))
				{
					PrintToChat(client, "\x03[RP] %T", "Money_Printer_Empty", client);
					EmitSoundToAll("buttons/button2.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
				}
			}
		}
	}
}
public Menu_Player(Handle:player_menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(player_menu, param2, info, sizeof(info));
		if (targeted_player[param1] <= 0)
		{
			return;
		}
		if (!IsClientInGame(targeted_player[param1]))
		{
			return;
		}
		if (StrEqual(info,"1"))
		{
			// They chose to give cash.  Let's make them a menu to make it easy.
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "Give cash to %N?", targeted_player[param1]);
			
			new Handle:givecash_menu = CreateMenu(Menu_GiveCash);
			if (money[param1] >= 5)
			{
				AddMenuItem(givecash_menu, "5", "$5");
			}
			if (money[param1] >= 50)
			{
				AddMenuItem(givecash_menu, "50", "$50");
			}			
			if (money[param1] >= 100)
			{
				AddMenuItem(givecash_menu, "100", "$100");
			}
			if (money[param1] >= 200)
			{
				AddMenuItem(givecash_menu, "200", "$200");
			}
			if (money[param1] >= 500)
			{
				AddMenuItem(givecash_menu, "500", "$500");
			}
			if (money[param1] >= 1000)
			{
				AddMenuItem(givecash_menu, "1000", "$1000");
			}
			if (money[param1] >= 5000)
			{
				AddMenuItem(givecash_menu, "5000", "$5000");
			}		
			AddMenuItem(givecash_menu, "all", "All Cash");			
			
			SetMenuTitle(givecash_menu, title_str);
			DisplayMenu(givecash_menu, param1, MENU_TIME_FOREVER);
			return;
		}
		else if (StrEqual(info,"2"))
		{
			// They chose to use their debit card.  Let's make them a menu to make it easy.
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "Transfer money to %N?", targeted_player[param1]);
			
			new Handle:givedebit_menu = CreateMenu(Menu_GiveDebit);
			if (bank[param1] >= 5)
			{
				AddMenuItem(givedebit_menu, "5", "$5");
			}
			if (bank[param1] >= 50)
			{
				AddMenuItem(givedebit_menu, "50", "$50");
			}			
			if (bank[param1] >= 100)
			{
				AddMenuItem(givedebit_menu, "100", "$100");
			}
			if (bank[param1] >= 200)
			{
				AddMenuItem(givedebit_menu, "200", "$200");
			}
			if (bank[param1] >= 500)
			{
				AddMenuItem(givedebit_menu, "500", "$500");
			}
			if (bank[param1] >= 1000)
			{
				AddMenuItem(givedebit_menu, "1000", "$1000");
			}
			if (bank[param1] >= 5000)
			{
				AddMenuItem(givedebit_menu, "5000", "$5000");
			}
			if (bank[param1] >= 10000)
			{
				AddMenuItem(givedebit_menu, "10000", "$10000");
			}
			if (bank[param1] >= 50000)
			{
				AddMenuItem(givedebit_menu, "50000", "$50000");
			}
			if (bank[param1] >= 100000)
			{
				AddMenuItem(givedebit_menu, "100000", "$100000");
			}			
			
			SetMenuTitle(givedebit_menu, title_str);
			DisplayMenu(givedebit_menu, param1, MENU_TIME_FOREVER);
			return;
		}
		else if (StrEqual(info,"3"))
		{
			new target = targeted_player[param1];
			if (!IsClientInGame(target))
			{
				return;
			}
			targeted_player[param1] = -1;
			
			// Looks like they were able to demote.
							
			new t = player_team[param1];
			new c = player_class[param1];

			decl String:arg2[65];
			GetCmdArg(2, arg2, sizeof(arg2));
		
			PrintToChatAll("\x03[RP] Player %N was demoted from %s by %s %N.", target, team_name[t], class_name[c], param1);

			// Make them a Citizen.
			new t_index = GetConVarInt(g_DefaultTeam);
			new c_index = GetConVarInt(g_DefaultClass);	
			player_team[target] = t_index;
			player_class[target] = c_index;
			player_salary[target] = class_salary[c_index];

			// Respawn them if not already dead.
			if (IsPlayerAlive(target))
			{
				FakeClientCommandEx(target, "kill");
			}
			return;
		}
		else if (StrEqual(info,"4"))
		{
			new target = targeted_player[param1];
			if ((!IsClientInGame(target)) || (!IsClientInGame(param1)) || (!IsPlayerAlive(target)) || (!IsPlayerAlive(param1))) 
			{
				return;
			}
			targeted_player[param1] = -1;
			
			// They are the mayor or whoever, and they can issue a warrant.
			
			if (!Warranted[target])
			{
				Warranted[target] = true;
				PrintToChat(param1, "\x03[RP] You put out a warrant for the arrest of %N.", target);
				PrintToChat(target, "\x03[RP] There is a warrant for your arrest.");
				PrintToChatAll("\x03[RP] A warrant for the arrest of %N has been put out.", target);

				h_warrant_timer = CreateTimer(300.0, Warrant_Time, target);

				return;
			}
			else if (Warranted[target])
			{
				Warranted[target] = false;
				PrintToChat(param1, "\x03[RP] You lifted the warrant off of %N.", target);
				PrintToChat(target, "\x03[RP] There is no longer a warrant for your arrest.");
				PrintToChatAll("\x03[RP] The warrant for the arrest of %N has been cancelled.", target);
				return;
			}
		}
		else if (StrEqual(info,"5"))
		{
			new target = targeted_player[param1];
			if ((!IsClientInGame(target)) || (!IsClientInGame(param1)) || (!IsPlayerAlive(target)) || (!IsPlayerAlive(param1)) || (IsCuffed[param1] == true)) 
			{
				return;
			}
			targeted_player[param1] = -1;
			
			// They can uncuff the player, if the player is cuffed.
			
			if (IsCuffed[target])
			{
				new Float:origin[3];
				new Float:target_origin[3];
				new Float:distance;

				GetClientAbsOrigin(param1, origin);	
				GetClientAbsOrigin(target, target_origin);
				distance = GetVectorDistance(origin, target_origin, false);
				if (distance <= 80.00)
				{								
					new Float:dur_float = 6.0;
					uncuffing_target[param1] = target;
					// Show Progress Bar
					SetEntDataFloat(param1, g_flProgressBarStartTime, GetGameTime(), true);
					SetEntData(param1, g_iProgressBarDuration, dur_float, 4, true);
					SetEntPropFloat(param1, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
					SetEntProp(param1, Prop_Send, "m_iProgressBarDuration", dur_float);								
					CreateTimer(dur_float, Uncuff_Time, param1);
					Blops_ShowBarTime(param1, 6);
					
					PrintToChat(param1, "\x03[RP] Uncuffing...  Stay near %N.", target);
					PrintToChat(target, "\x03[RP] %N is uncuffing you.  Hold still.", param1);
				}
			}
		}
		return;
	}
	return;
}
public Action:Uncuff_Time(Handle:Timer, any:client)
{
	new target = uncuffing_target[client];
	uncuffing_target[client] = -1;
	
	if ((target == -1) || (!IsClientInGame(target)) || (!IsPlayerAlive(target)) || (!IsClientHandcuffed(target)) || (!IsClientInGame(client)) || (!IsPlayerAlive(client)) || (IsClientHandcuffed(client)))
	{
		PrintToChat(client, "\x 03[RP] Uncuffing Failed");
		return;
	}
	
	if ((IsClientInGame(target)) && (IsPlayerAlive(target)) && (IsClientHandcuffed(target)))
	{
		new Float:origin[3];
		new Float:target_origin[3];
		new Float:distance;

		GetClientAbsOrigin(client, origin);	
		GetClientAbsOrigin(target, target_origin);
		distance = GetVectorDistance(origin, target_origin, false);
		
		if (distance <= 80.0)
		{
			UnCuff(target);		
			EmitSoundToAll("doors/latchunlocked1.wav", target, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
			
			PrintToChat(client, "\x03[RP] You uncuffed %N.", target);
			PrintToChat(target, "\x03[RP] You were uncuffed by %N.", client);			
			return;
		}
		else PrintToChat(client, "\x03[RP] You moved away from %N...  Uncuffing Failed.", target);
	}
	else return;
}
public Menu_GiveCash(Handle:givecash_menu, MenuAction:action, param1, param2)
{
	// User has selected to give cash to someone
	if (param1 <= 0)
	{
		return;
	}
	if (!IsClientInGame(param1))
	{
		return;
	}
	new target = targeted_player[param1];
	if (!IsClientInGame(target))
	{
		return;
	}
	targeted_player[param1] = -1;
	if (action == MenuAction_Select)
	{	
		if(!IsClientInGame(target))
		return;
		if(!IsPlayerAlive(target))
		return;
		if(!IsClientInGame(param1))
		return;
		if(!IsPlayerAlive(param1))
		return;

		if (param1 <= 0)
		{
			return;
		}
		if (target <= 0)
		{
			return;
		}		
		new String:info[32];
		GetMenuItem(givecash_menu, param2, info, sizeof(info));
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		money[param1] = GetEntData(param1, MoneyOffset, 4);
		money[target] = GetEntData(target, MoneyOffset, 4);
		
		new givecash_amt = StringToInt(info, 10);	
		if (givecash_amt > money[param1])
		{
			PrintToChat(param1, "\x03[RP] Stop trying to cheat.");
			return;
		}
		if (money[param1] <= 0)
		{
			PrintToChat(param1, "\x03[RP] Stop trying to cheat.");
			return;
		}
		
		new difference = (65535 - money[target]);
	
		if(StrEqual(info,"all"))
		{
			new wallet = (money[param1] + money[target]);
			if (wallet <= 65535)
			{
				money[target] = wallet;
				new t = player_team[param1];
				new t2 = player_team[target];
				if ((GetConVarInt(g_Cvar_TeamMode)) && (team_competing[t]))
				{
					team_points[t] -= money[param1];
					team_points[t2] += money[param1];
				}
				SetEntData(target, MoneyOffset, wallet, 4, true);
				money[param1] = 0;
				SetEntData(param1, MoneyOffset, 0, 4, true);				
	
				PrintToChat(param1, "\x03[RP] You gave all your cash to %N.", target);
				PrintToChat(target, "\x03[RP] %N gave you all of their cash.", param1);
				return;
			}
			if (wallet > 65535)
			{
				money[param1] -= difference;
				new t = player_team[param1];
				new t2 = player_team[target];
				if ((GetConVarInt(g_Cvar_TeamMode)) && (team_competing[t]))
				{
					team_points[t] -= difference;
					team_points[t2] += difference;
				}
				SetEntData(param1, MoneyOffset, money[param1], 4, true);
				money[target] = 65535;
				SetEntData(target, MoneyOffset, 65535, 4, true);
				PrintToChat(param1, "\x03[RP] You gave $%i to %N.", difference, target);
				PrintToChat(target, "\x03[RP] %N gave you $%i.", param1, difference);
				return;
			}
			return;
		}
		else if (money[param1] >= givecash_amt)
		{
			new wallet = (givecash_amt + money[target]);
			
			if (wallet <= 65535)
			{
				new t = player_team[param1];
				new t2 = player_team[target];
				if ((GetConVarInt(g_Cvar_TeamMode)) && (team_competing[t]))
				{
					team_points[t] -= givecash_amt;
					team_points[t2] += givecash_amt;
					if (team_points[t] <= 0)
					{
						team_points[t] = 0;
					}
				}
				money[param1] -= givecash_amt;
				SetEntData(param1, MoneyOffset, money[param1], 4, true);
				money[target] = wallet;
				SetEntData(target, MoneyOffset, money[target], 4, true);
				PrintToChat(param1, "\x03[RP] You $%i in cash to %N.", givecash_amt, target);
				PrintToChat(target, "\x03[RP] %N gave you $%i in cash.", param1, givecash_amt);
				return;
			}
			if (wallet > 65535)
			{
				new t = player_team[param1];
				new t2 = player_team[target];
				if ((GetConVarInt(g_Cvar_TeamMode)) && (team_competing[t]))
				{
					team_points[t] -= difference;
					team_points[t2] += difference;
					if (team_points[t] <= 0)
					{
						team_points[t] = 0;
					}
				}
				money[param1] -= difference;
				SetEntData(param1, MoneyOffset, money[param1], 4, true);
				money[target] = 65535;
				SetEntData(target, MoneyOffset, 65535, 4, true);
				PrintToChat(param1, "\x03[RP] You gave $%i to %N.", difference, target);
				PrintToChat(target, "\x03[RP] %N gave you $%i.", param1, difference);
				return;
			}
			return;
		}
	}
	return;
}
public Menu_GiveDebit(Handle:givedebit_menu, MenuAction:action, param1, param2)
{
	// User has selected to give debit card money to someone
	if (param1 <= 0)
	{
		return;
	}
	if (!IsClientInGame(param1))
	{
		return;
	}
	new target = targeted_player[param1];
	if (!IsClientInGame(target))
	{
		return;
	}
	targeted_player[param1] = -1;
	if (action == MenuAction_Select)
	{	
		if(!IsClientInGame(target))
		return;
		if(!IsPlayerAlive(target))
		return;
		if(!IsClientInGame(param1))
		return;
		if(!IsPlayerAlive(param1))
		return;

		if (param1 <= 0)
		{
			return;
		}
		if (target <= 0)
		{
			return;
		}		
		new String:info[32];
		GetMenuItem(givedebit_menu, param2, info, sizeof(info));
		
		new givedebit_amt = StringToInt(info, 10);	
		if (givedebit_amt > bank[param1])
		{
			PrintToChat(param1, "\x03[RP] Stop trying to cheat.");
			return;
		}
		else if (bank[param1] <= 0)
		{
			PrintToChat(param1, "\x03[RP] Stop trying to cheat.");
			return;
		}	
		else if (bank[param1] >= givedebit_amt)
		{
			new wallet = (givedebit_amt + bank[target]);
			
			new t = player_team[param1];
			new t2 = player_team[target];
			if ((GetConVarInt(g_Cvar_TeamMode)) && (team_competing[t]))
			{
				team_points[t] -= givedebit_amt;
				team_points[t2] += givedebit_amt;
				if (team_points[t] <= 0)
				{
					team_points[t] = 0;
				}
			}			
			
			bank[param1] -= givedebit_amt;
			bank[target] = wallet;
			PrintToChat(param1, "\x03[RP] You debited $%i to %N from your bank account.", givedebit_amt, target);
			PrintToChat(target, "\x03[RP] %N debited $%i to your bank account.", param1, givedebit_amt);
			return;
		}
	}
	return;
}

// #########
// DOOR MENU
// #########



Handle:BuildDoorMenu()
{
	new price = GetConVarInt(g_Door_Price);
	new String:door_buy_str[32];
	Format(door_buy_str, sizeof(door_buy_str), "Buy a door ($%i)", price);

	new Handle:doors = CreateMenu(Menu_Doors);
	AddMenuItem(doors, CMD_DOORINFO, "Get Door Information");
	AddMenuItem(doors, CMD_DOOR_OWN, door_buy_str);
	AddMenuItem(doors, CMD_DOORTEAM, "Give door access to a team");
	AddMenuItem(doors, CMD_DOORCLSS, "Give door access to a class");
	AddMenuItem(doors, CMD_DOORPLYR, "Give door access to a player");
	AddMenuItem(doors, CMD_DOOR4FIT, "Forfeit this door");
	SetMenuTitle(doors, "RP Door Menu");
	PrintToServer("[RP] BuildDoorMenu completed successfully.");
	return doors;
}
public Menu_AccessTeam(Handle:tempmenu2, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(tempmenu2);
	}
	else if (action == MenuAction_Select)
	{
		decl Ent;
		//Initialize:
		Ent = GetClientAimTarget(param1, false);
		
		//Valid:
		if(Ent == -1)
		{
			PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
			return;
		}
		new String:targetname[64];
		GetTargetName(Ent,targetname,sizeof(targetname));
		
		if(OwnsDoor[param1][Ent] == 0)
		{
			PrintToChat(param1, "\x03[RP] You can't give teams access to a door that you don't own. (%s)", targetname);
			return;
		}
		
		if (AccessTeam[param2][Ent] != 1)
		{
			AccessTeam[param2][Ent] = 1;
			PrintToChat(param1, "\x03[RP] You gave access for door (%s) to the %s team.", targetname, team_name[param2]);
		}
		else if (AccessTeam[param2][Ent] == 1)
		{
			AccessTeam[param2][Ent] = 0;
			PrintToChat(param1, "\x03[RP] You took access for door (%s) away from the %s team.", targetname, team_name[param2]);
		}
	}
	return;
}
public Menu_AccessClass(Handle:tempmenu4, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(tempmenu4);
	}
	else if (action == MenuAction_Select)
	{
		decl Ent;
		//Initialize:
		Ent = GetClientAimTarget(param1, false);
		
		//Valid:
		if(Ent == -1)
		{
			PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
			return;
		}
		new String:targetname[64];
		GetTargetName(Ent,targetname,sizeof(targetname));
		
		if(OwnsDoor[param1][Ent] == 0)
		{
			PrintToChat(param1, "\x03[RP] You can't give classes access to a door that you don't own. (%s)", targetname);
			return;
		}
		
		if (AccessClass[param2][Ent] != 1)
		{
			AccessClass[param2][Ent] = 1;
			PrintToChat(param1, "\x03[RP] You gave access for door (%s) to the %s class.", targetname, class_name[param2]);
		}
		else if (AccessClass[param2][Ent] == 1)
		{
			AccessClass[param2][Ent] = 0;
			PrintToChat(param1, "\x03[RP] You took access for door (%s) away from the %s class.", targetname, class_name[param2]);
		}
	}
	return;
}
public Menu_AccessGive(Handle:tempmenu3, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(tempmenu3);
	}
	else if (action == MenuAction_Select)
	{
		new Ent = selected_door[param1];	
		if(Ent != -1)
		{
			new String:info[32];
				
			GetMenuItem(tempmenu3, param2, info, sizeof(info));
			StripQuotes(info);
			TrimString(info);

			new lol = StringToInt(info, 10);

			new String:targetname[64];
			GetTargetName(Ent,targetname,sizeof(targetname));
		
		
			if(AccessDoor[lol][Ent] != 1)
			{
				AccessDoor[lol][Ent] = 1;
				PrintToChat(param1, "\x03[RP] You gave access for door (%s) to %N.", targetname, lol);
			}
			else if(AccessDoor[lol][Ent] == 1)
			{
				AccessDoor[lol][Ent] = 0;
				PrintToChat(param1, "\x03[RP] You took access for door (%s) away from %N.", targetname, lol);
			}
		}
	}
	selected_door[param1] = -1;
}
public Menu_Doors(Handle:doors, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		//Declare:
		decl Ent;
		decl String:ClassName[255];
		//Initialize:
		Ent = GetClientAimTarget(param1, false);
		new String:info[32];

		GetMenuItem(doors, param2, info, sizeof(info));
		if (StrEqual(info,CMD_DOORINFO))
		{
			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating") || StrEqual(ClassName, "prop_vehicle_driveable"))
				{
					new String:targetname[64];
					GetTargetName(Ent,targetname,sizeof(targetname));
					new owned = 0;
					for (new i = 0; i <= MaxClients; i += 1)
					{
						if(OwnsDoor[i][Ent] != 1)
						{
							continue;
						}
						else if(OwnsDoor[i][Ent] == 1)
						{
							owned = 1;
						}
  					}
					if (owned == 0)
					{
						 PrintToChat(param1, "\x03[RP] This door (%s) is not yet owned.", targetname);
					}
					else if (owned == 1)
					{
						if(Locked[Ent] != 1)
						{
							PrintToChat(param1, "\x03[RP] This door (%s) is owned and \x04UNLOCKED\x03.", targetname);
						}
						else if (Locked[Ent] == 1)
						{
							PrintToChat(param1, "\x03[RP] This door (%s) is owned and \x04LOCKED\x03.", targetname);
						}
					}

    			}
				else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
			}
			else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
		}
		if (StrEqual(info,CMD_DOOR_OWN))
		{
			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
				{
					new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
					money[param1] = GetEntData(param1, MoneyOffset, 4);
					new price = GetConVarInt(g_Door_Price);
					if ((money[param1] >= price) || (bank[param1] >= price))
					{
						new String:targetname[64];
						GetTargetName(Ent,targetname,sizeof(targetname));
						new owned = 0;
						for (new i = 0; i <= MaxClients; i += 1)
						{
							if(OwnsDoor[i][Ent] != 1)
							{
								continue;
							}
							else if(OwnsDoor[i][Ent] == 1)
							{
								owned = 1;
							}
	  					}
						if (owned == 0)
						{
							OwnsDoor[param1][Ent] = 1;
							if ((money[param1] >= price))
							{
								money[param1] -= price;
							} else bank[param1] -=price;
							SetEntData(param1, MoneyOffset, money[param1], 4, true);
							new group = door_group[Ent];
							if ((group > -1) && (group < 100))
							{
								new door;
								for (new bb = 0; bb < 50; bb += 1)
								{
									if (group_doors[group][bb] < 1)
									{
										break;
									}
									else
									{
										door = group_doors[group][bb];
										OwnsDoor[param1][door] = 1;
										doorAmount[param1] += 1;
									}
								}								
								if (StrEqual(group_name[group], "UNKNOWN", false))
								{
									PrintToChat(param1, "\x03[RP] You bought this door (%s) for $%i.", targetname, price);
								}
								else
								{
									PrintToChat(param1, "\x03[RP] You bought %s for $%i.", group_name[group], price);
								}
							}
							else
							{
								doorAmount[param1] += 1;
								PrintToChat(param1, "\x03[RP] You bought this door (%s) for $%i.", targetname, price);
							}
						}
						else if (owned == 1)
						{
							PrintToChat(param1, "\x03[RP] This door (%s) is already owned.", targetname);
						}
 					}
 					else if (money[param1] < price)
 					{
 						PrintToChat(param1, "\x03[RP] You can't afford this.  It costs $%i to buy a door.", price);
 					}
    			}
				else if (StrEqual(ClassName, "prop_vehicle_driveable"))
 				{
					new String:targetname[64];
					GetTargetName(Ent,targetname,sizeof(targetname));
					GetClientAuthId(param1, AuthId_Engine, authid[param1], sizeof(authid[]));

					if ((StrContains(targetname, authid[param1], false)) != -1)
					{
						new owned = 0;
						for (new i = 0; i <= MaxClients; i += 1)
						{
							if(OwnsDoor[i][Ent] != 1)
							{
								continue;
							}
							else if(OwnsDoor[i][Ent] == 1)
							{
								owned = 1;
							}
	  					}
						if (owned == 0)
						{
							OwnsDoor[param1][Ent] = 1;
							PrintToChat(param1, "\x03[RP] You now have keys for this car. (%s)", targetname);
						}
						else if (owned == 1)
						{
							PrintToChat(param1, "\x03[RP] You already have keys for this car.", targetname);
						}
					}
					else PrintToChat(param1, "\x03[RP] You can't take someone else's car.");
    			}
				else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
			}
			else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
		}
		if (StrEqual(info,CMD_DOORTEAM))
		{
			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating") || StrEqual(ClassName, "prop_vehicle_driveable"))
				{
					new String:targetname[64];
					GetTargetName(Ent,targetname,sizeof(targetname));
					if(OwnsDoor[param1][Ent] == 1)
					{
						if (team_index == 0)
						{
							PrintToServer("[RP] Error: CMD_DOORTEAM (00) -- Unable to build team access menu.  No teams indexed.");
							LogMessage("[RP] Error: CMD_DOORTEAM (00) -- Unable to build team access menu.  No teams indexed.");
							return;
						}
						if (class_index == 0)
						{
							PrintToServer("[RP] Error: CMD_DOORTEAM (01) -- Unable to build team access menu.  No classes indexed.");
							LogMessage("[RP] Error: CMD_DOORTEAM (01) -- Unable to build team access menu.  No classes indexed.");
							return;
						}
						new Handle:tempmenu2 = CreateMenu(Menu_AccessTeam);

						new i = 0;
						new String:team_str[4];
						new limit = team_index - 1;
						do
						{
							Format(team_str, sizeof(team_str), "%i", i);
							AddMenuItem(tempmenu2,team_str,team_name[i]);
							i += 1;

						} while (i <= limit);
	
						SetMenuTitle(tempmenu2, "Toggle Door Access for Team:");
						DisplayMenu(tempmenu2, param1, MENU_TIME_FOREVER);
						return;
					}
					else if(OwnsDoor[param1][Ent] == 0)
					{
						PrintToChat(param1, "\x03[RP] You can't give players access to a door that you don't own. (%s)", targetname);
					}
    			}
				else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
			}
			else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
		}
		if (StrEqual(info,CMD_DOORCLSS))
		{
			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating") || StrEqual(ClassName, "prop_vehicle_driveable"))
				{
					new String:targetname[64];
					GetTargetName(Ent,targetname,sizeof(targetname));
					if(OwnsDoor[param1][Ent] == 1)
					{
						if (team_index == 0)
						{
							PrintToServer("[RP] Error: CMD_DOORCLSS (00) -- Unable to build class access menu.  No teams indexed.");
							LogMessage("[RP] Error: CMD_DOORCLSS (00) -- Unable to build class access menu.  No teams indexed.");
							return;
						}
						if (class_index == 0)
						{
							PrintToServer("[RP] Error: CMD_DOORCLSS (01) -- Unable to build class access menu.  No classes indexed.");
							LogMessage("[RP] Error: CMD_DOORCLSS (01) -- Unable to build class access menu.  No classes indexed.");
							return;
						}
						new Handle:tempmenu4 = CreateMenu(Menu_AccessClass);

						new i = 0;
						new String:class_str[4];
						new limit = class_index - 1;
						do
						{
							Format(class_str, sizeof(class_str), "%i", i);
							AddMenuItem(tempmenu4,class_str,class_name[i]);
							i += 1;

						} while (i <= limit);
	
						SetMenuTitle(tempmenu4, "Toggle Door Access for Class:");
						DisplayMenu(tempmenu4, param1, MENU_TIME_FOREVER);
						return;
					}
					else if(OwnsDoor[param1][Ent] == 0)
					{
						PrintToChat(param1, "\x03[RP] You can't give classes access to a door that you don't own. (%s)", targetname);
					}
    			}
				else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
			}
			else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
		}
		if (StrEqual(info,CMD_DOORPLYR))
		{
			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating") || StrEqual(ClassName, "prop_vehicle_driveable"))
				{
					new String:targetname[64];
					GetTargetName(Ent,targetname,sizeof(targetname));
					if(OwnsDoor[param1][Ent] == 1)
					{
						decl String:name[32];
						decl String:identifier[32];
						new Handle:tempmenu3 = CreateMenu(Menu_AccessGive);
						for (new i = 1; i < GetMaxClients(); i++)
						{
							if (IsClientInGame(i))
							{
								GetClientName(i, name, sizeof(name));
								Format(identifier, sizeof(identifier), "%i", i);
								AddMenuItem(tempmenu3, identifier, name);
							}
						}
						
						selected_door[param1] = Ent;

						SetMenuTitle(tempmenu3, "Toggle Door Access for Player:");
						DisplayMenu(tempmenu3, param1, MENU_TIME_FOREVER);
					}
					else if(OwnsDoor[param1][Ent] == 0)
					{
						PrintToChat(param1, "\x03[RP] You can't give players access to a door that you don't own. (%s)", targetname);
					}
    			}
				else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
			}
			else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
		}
		if (StrEqual(info,CMD_DOOR4FIT))
		{
			//Valid:
			if(Ent != -1)
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
				{
					new String:targetname[64];
					GetTargetName(Ent,targetname,sizeof(targetname));
					if(OwnsDoor[param1][Ent] == 1)
					{
						OwnsDoor[param1][Ent] = 0;
						new group = door_group[Ent];
						if (group != -1)
						{
							new door;
							for (new b2 = 0; b2 < 50; b2++)
							{
								if (group_doors[group][b2] < 1)
								{
									break;
								}
								else
								{
									door = group_doors[group][b2];
									OwnsDoor[param1][door] = 0;
									AcceptEntityInput(door, "Unlock", param1);
									doorAmount[param1] -= 1;
									for (new i = 1; i <= MaxClients; i += 1)
									{
										if(AccessDoor[i][door] != 1)
										{
											continue;
										}
										else if(AccessDoor[i][door] == 1)
										{
											AccessDoor[i][door] = 0;
										}
									}
								}
							}							
							if (StrEqual(group_name[group], "UNKNOWN", false))
							{
								PrintToChat(param1, "\x03[RP] You no longer own this door. (%s)", targetname);
							}
							else
							{
								PrintToChat(param1, "\x03[RP] You no longer own this. (%s)", group_name[group]);
							}
						}
						else
						{
							PrintToChat(param1, "\x03[RP] You no longer own this door. (%s)", targetname);
						}							

						AcceptEntityInput(Ent, "Unlock", param1);
						doorAmount[param1] -= 1;
						for (new i = 1; i <= MaxClients; i += 1)
						{
							if(AccessDoor[i][Ent] != 1)
							{
								continue;
							}
							else if(AccessDoor[i][Ent] == 1)
							{
								AccessDoor[i][Ent] = 0;
							}
						}
					}
					else if(OwnsDoor[param1][Ent] == 0)
					{
						PrintToChat(param1, "\x03[RP] You can't give up a door that you don't own. (%s)", targetname);
					}
    			}
				else if(StrEqual(ClassName, "prop_vehicle_driveable"))
				{
					new String:targetname[64];
					GetTargetName(Ent,targetname,sizeof(targetname));
					if(OwnsDoor[param1][Ent] == 1)
					{
						OwnsDoor[param1][Ent] = 0;
						AcceptEntityInput(Ent, "Unlock", param1);
						PrintToChat(param1, "\x03[RP] You no longer have the keys to this car. (%s)", targetname);
						for (new i = 1; i <= MaxClients; i += 1)
						{
							if(AccessDoor[i][Ent] != 1)
							{
								continue;
							}
							else if(AccessDoor[i][Ent] == 1)
							{
								AccessDoor[i][Ent] = 0;
							}
						}
					}
					else if(OwnsDoor[param1][Ent] == 0)
					{
						PrintToChat(param1, "\x03[RP] You didn't have the keys to this car. (%s)", targetname);
					}
    			}
				else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
			}
			else PrintToChat(param1, "\x03[RP] You must look at a door to use this command.");
		}
	}
}
// Door Menu
public Action:DoorMenu(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsCuffed[client])
		{
			PrintToChat(client, "\x04[RP] %T", "Handcuffed", client);
			return Plugin_Handled;
		}
		if (g_DoorMenu == INVALID_HANDLE)
		{
			PrintToConsole(client, "There was an error generating the menu.");
		}
		else DisplayMenu(g_DoorMenu, client, MENU_TIME_FOREVER);
	}
	else PrintToChat(client, "\x04[RP] %T", "Disabled", client);
	return Plugin_Handled;
}



// ##########
// LOAD FILES
// ##########



public ReadClassFile()
{
	new Handle:classmenukv;
	classmenukv = CreateKeyValues("Commands");
	new String:file2[256];
	BuildPath(Path_SM, file2, 255, "configs/classes.ini");
	FileToKeyValues(classmenukv, file2);
	
	KvRewind(classmenukv);
	if (!KvGotoFirstSubKey(classmenukv))
	{
		PrintToServer("[RP DEBUG] There are no teams listed in classes.ini, or there is an error with the file.");
		return;
	}
		
	// Index the teams first.
	new vip_team_count = 0;
	new competition_buffer = 0;
	do
	{
		KvGetSectionName(classmenukv, team_name[team_index], 35);
		
		team_vip[team_index] = KvGetNum(classmenukv, "VIP", 0);
		if (team_vip[team_index] == 1)
		{
			vip_team_count += 1;
		}
		competition_buffer = KvGetNum(classmenukv, "competing", 0);
		if (competition_buffer == 1)
		{
			team_competing[team_index] = true;
		}
		else
		{
			team_competing[team_index] = false;
		}
		PrintToServer("[RP] Team %i: %s  VIP? %i  Competing? %i", team_index, team_name[team_index], team_vip[team_index], competition_buffer);
		team_index += 1;

	} while (KvGotoNextKey(classmenukv));
	KvRewind(classmenukv);
	
	// Now let's index all of the classes.
	new lol = 0;
	do
	{
		KvJumpToKey(classmenukv, team_name[lol]);
		KvGotoFirstSubKey(classmenukv);
		do
		{
			KvGetSectionName(classmenukv, class_name[class_index], 35);
			class_salary[class_index] = KvGetNum(classmenukv, "Salary", 0);
			class_limit[class_index] = KvGetNum(classmenukv, "slots", 0);
			class_team[class_index] = lol;
			class_assassination[class_index] = KvGetNum(classmenukv, "assassination", 0);
			class_authority[class_index] = KvGetNum(classmenukv, "authority", 0);
			KvGetString(classmenukv, "model_f", class_model_f[class_index], 255, "player/ct_sas.mdl");
			KvGetString(classmenukv, "model_m", class_model_m[class_index], 255, "player/ct_sas.mdl");
			class_alcohol[class_index] = KvGetNum(classmenukv, "alcohol", 0);
			class_teamed[class_index] = KvGetNum(classmenukv, "team", 0);
			if (class_teamed[class_index] > 1)
			{
				class_teamed[class_index] = 1;
			}
			class_index += 1;

		} while ((KvGotoNextKey(classmenukv)) && (class_index <= MAXCLASSES));
		lol += 1;
		KvRewind(classmenukv);
		
	} while ((lol <= team_index) && (lol <= MAXTEAMS));

	KvRewind(classmenukv);	
	
	PrintToServer("[RP] Classes Loaded");
	PrintToServer("[RP] %i teams were detected. [Max 20]", team_index);
	if (vip_team_count == 0)
	{
		PrintToServer("[RP] None were VIP teams.");
	}
	if (vip_team_count == 1)
	{
		PrintToServer("[RP] 1 VIP team was detected.");
	}
	if (vip_team_count > 1)
	{
		PrintToServer("[RP] %i VIP teams were detected.", vip_team_count);
	}
	PrintToServer("[RP] %i classes were detected. [Max 256]", class_index - team_index);
	KvRewind(classmenukv);
	CloseHandle(classmenukv);
}
public ReadDoorFile(client)
{
	new String:sPath[PLATFORM_MAX_PATH];
	new String:mapname[64];
	new String:path_str[96];

	GetCurrentMap(mapname, sizeof(mapname));
	new pos = FindCharInString(mapname, '/', true);
	if(pos == -1)
	{
		pos = 0;
	}
	else
	{
		pos += 1;
	}
	Format(path_str, sizeof(path_str), "configs/rp_map_configs/%s_doors.txt", mapname[pos]);
	
	BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
	doorkv = CreateKeyValues("Doors");
	if (!FileToKeyValues(doorkv, sPath))
	{
		if (client == 0)
		{
			PrintToServer("[RP DEBUG] There are no doors listed in %s, or there is an error with the file.", path_str);
		}
		else PrintToChat(client, "\x04[RP DEBUG] There are no doors listed in %s, or there is an error with the file.", path_str);
		return;
	}
	new OwnedDoors = 0;

	KvRewind(doorkv);

	if (!KvGotoFirstSubKey(doorkv))
	{
		if (client == 0)
		{
			PrintToServer("[RP DEBUG] There are no doors listed in %s, or there is an error with the file.", path_str);
		}
		else PrintToChat(client, "\x04[RP DEBUG] There are no doors listed in %s, or there is an error with the file.", path_str);
		return;
	}
	new team_buffer;
	new door_index;
	new class_buffer;
	new mode_buffer;
	new String:steam_buffer[35];
	new group;
	for (new lol = 0; lol < 100; lol++)
	{
		Format(group_name[lol], sizeof(group_name[]), "UNKNOWN");
	}
	do
	{
		group = -1;
		door_index = KvGetNum(doorkv, "index", -1);
		if (IsValidEntity(door_index))
		{
			group = KvGetNum(doorkv, "group", -1);
			if ((group > -1) && (group < 100))
			{
				if (StrEqual(group_name[group], "UNKNOWN", false))
				{
					KvGetString(doorkv, "group_name", group_name[group], 255, "UNKNOWN");				
				}
				door_group[door_index] = group;
				for (new b2 = 0; b2 < 50; b2++)
				{
					if (group_doors[group][b2] < 1)
					{
						group_doors[group][b2] = door_index;
						break;
					}
				}
			}
			else door_group[door_index] = -1;
			mode_buffer = KvGetNum(doorkv, "mode", 0);
			if (mode_buffer == 0)
			{
				team_buffer = KvGetNum(doorkv, "team", -1);
				if (team_buffer > -1)
				{
					AccessTeam[team_buffer][door_index] = 1;
					OwnsDoor[0][door_index] = 1;
				}
			}
			else if (mode_buffer == 1)
			{
				class_buffer = KvGetNum(doorkv, "class", 0);
				AccessClass[class_buffer][door_index] = 1;
				OwnsDoor[0][door_index] = 1;
			}
			else if (mode_buffer == 2)
			{
				class_buffer = KvGetNum(doorkv, "class", 0);
				AccessClass[class_buffer][door_index] = 1;
				team_buffer = KvGetNum(doorkv, "team", 0);
				AccessTeam[team_buffer][door_index] = 1;
				OwnsDoor[0][door_index] = 1;
			}
			else if (mode_buffer == 3)
			{
				KvGetString(doorkv, "steamid", steam_buffer, sizeof(steam_buffer));
				Format(DoorSteam[door_index], sizeof(DoorSteam[]), "%s", steam_buffer);
				OwnsDoor[0][door_index] = 1;
			}
			OwnedDoors += 1;
		}

	} while (KvGotoNextKey(doorkv));
	if (client == 0)
	{
		PrintToServer("[RP] Doors Loaded");
		PrintToServer("[RP] %i owned doors were detected.", OwnedDoors);
	}
	else
	{
		PrintToChat(client, "\x04[RP] Doors Loaded");
		PrintToChat(client, "\x04[RP] %i owned doors were detected.", OwnedDoors);
	}
}



// ######
// SPAWNS
// ######



public ReadSpawnFile(client)
{
	new String:sPath[PLATFORM_MAX_PATH];
	new String:mapname[64];
	new String:path_str[96];
	
	GetCurrentMap(mapname, sizeof(mapname));
	new pos = FindCharInString(mapname, '/', true);
	if(pos == -1)
	{
		pos = 0;
	}
	else
	{
		pos += 1;
	}
	Format(path_str, sizeof(path_str), "configs/rp_map_configs/%s_spawns.txt", mapname[pos]);
	
	BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
	spawnkv = CreateKeyValues("Spawns");
	FileToKeyValues(spawnkv, sPath);

	KvRewind(spawnkv);

	if (!KvGotoFirstSubKey(spawnkv))
	{
		if (client == 0)
		{
			PrintToServer("[RP DEBUG] There are no spawns listed in %s, or there is an error with the file.", path_str);
		}
		else PrintToChat(client, "\x04[RP DEBUG] There are no spawns listed in %s, or there is an error with the file.", path_str);
		g_useSpawns2 = false;
		return;
	}
	
	for (new i = 0; i < 256; i++)
	{
		class_spawns[i] = 0;
	}

	new team_buffer = 0;
	new class_buffer = 0;
	new Float:spawn[3];
	g_SpawnQty = -1;

	do
	{
		team_buffer = KvGetNum(spawnkv, "team", 21);
		class_buffer = KvGetNum(spawnkv, "class", 256);
		spawn[0] = KvGetFloat(spawnkv, "x", 0.0);
		spawn[1] = KvGetFloat(spawnkv, "y", 0.0);
		spawn[2] = KvGetFloat(spawnkv, "z", 0.0);
		g_SpawnQty += 1;

		g_SpawnLoc[g_SpawnQty][0] = spawn[0];
		g_SpawnLoc[g_SpawnQty][1] = spawn[1];
		g_SpawnLoc[g_SpawnQty][2] = spawn[2];
		g_SpawnTeam[g_SpawnQty] = team_buffer;
		g_SpawnClass[g_SpawnQty] = class_buffer;
		if (class_buffer < 256)
		{
			class_spawns[class_buffer] += 1;
		}
		
	} while (KvGotoNextKey(spawnkv));
	if (client == 0)
	{
		PrintToServer("[RP] Spawns Loaded");
		PrintToServer("[RP] %i spawns were detected.", g_SpawnQty+1);
	}
	else
	{
		PrintToChat(client, "\x04[RP] Spawns Loaded");
		PrintToChat(client, "\x04[RP] %i spawns were detected.", g_SpawnQty+1);
	}

}
public Action:CommandSpawnMode(client, Arguments)
{
	if (client < 1)
	{
		PrintToServer("[RP] You must be in-game to use this command.");
		return Plugin_Handled;
	}
	if (SpawnModeAdmin == -1)
	{
		SpawnModeAdmin = client;
		InSpawnMode = true;
		new case_thingy = -1;
		
		
		// First we check to see if we can load an existing spawn list.
		new String:sPath[PLATFORM_MAX_PATH];
		new String:mapname[64];
		new String:path_str[96];
	
		GetCurrentMap(mapname, sizeof(mapname));
		Format(path_str, sizeof(path_str), "configs/rp_map_configs/%s_spawns.txt", mapname);
	
		BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
		spawnmodekv = CreateKeyValues("Spawns");

		if (spawnmodekv == INVALID_HANDLE)
		{
			CreateTimer(0.1, SpawnMode_Restart, client);
		}		
		
		if (!FileToKeyValues(spawnmodekv, sPath))
		{
			PrintToChat(client, "\x04[RP DEBUG] Spawns from file %s could not be loaded, or there is an error with the file, or the file does not exist.", path_str);
			PrintToChat(client, "\x04[RP DEBUG] A new file will be created.");
			case_thingy = 0;
		}
		else
		{
			PrintToChat(client, "\x04[RP DEBUG] Attempting to load spawns from file: %s", path_str);
			case_thingy = 1;
		}
		
		SMSpawns = 0;
		KvRewind(spawnmodekv);
		
		if (case_thingy == 1)
		{
			if (!KvGotoFirstSubKey(spawnmodekv))
			{
				if (client == 0)
				{
					PrintToServer("[RP DEBUG] There are no spawns listed in %s, or there is an error with the file.", path_str);
				}
				else PrintToChat(client, "\x04[RP DEBUG] There are no spawns listed in %s, or there is an error with the file.", path_str);
				case_thingy = 0;
			}
			else
			{
				g_SpawnQty = -1;
				for (new i = 0; i < 256; i++)
				{
					class_spawns[i] = 0;
				}
				new String:spawn_templol2[8];
				new Float:spawn_lol[3];
				new team_buffer = 0;
				new class_buffer = 0;

				for (new i = 0; i < MAX_SPAWNS; i++)
				{
					KvRewind(spawnmodekv);
					
					Format(spawn_templol2, sizeof(spawn_templol2), "%i", i);
					if (KvJumpToKey(spawnmodekv, spawn_templol2, false))
					{
						team_buffer = KvGetNum(spawnkv, "team", 21);
						class_buffer = KvGetNum(spawnkv, "class", 256);
						spawn_lol[0] = KvGetFloat(spawnmodekv, "x", 0.0);
						spawn_lol[1] = KvGetFloat(spawnmodekv, "y", 0.0);
						spawn_lol[2] = KvGetFloat(spawnmodekv, "z", 0.0);
						g_SpawnQty += 1;
				
						g_SpawnLoc[g_SpawnQty][0] = spawn_lol[0];
						g_SpawnLoc[g_SpawnQty][1] = spawn_lol[1];
						g_SpawnLoc[g_SpawnQty][2] = spawn_lol[2];
						g_SpawnTeam[g_SpawnQty] = team_buffer;
						g_SpawnClass[g_SpawnQty] = class_buffer;
						
						if (class_buffer < 256)
						{
							class_spawns[class_buffer] += 1;
						}
						KvRewind(spawnmodekv);
					}
				}
				PrintToChat(client, "\x04[RP] %i custom spawns were detected.", g_SpawnQty+1);
			}
		}		
		// Make spawn menu, do stuff, etc...
		
		new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
		new String:title_str[32];
		Format(title_str, sizeof(title_str), "Spawn Mode");
		CreateSpawnModeMenu(spawn_mode_menu, title_str);		
		DisplayMenu(spawn_mode_menu, client, MENU_TIME_FOREVER);
	}
	else if (SpawnModeAdmin == client)
	{
		// Same shit, different day.  Make spawn menu, etc...
		
		InSpawnMode = true;
		new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
		new String:title_str[32];
		Format(title_str, sizeof(title_str), "Spawn Mode");
		CreateSpawnModeMenu(spawn_mode_menu, title_str);		
		DisplayMenu(spawn_mode_menu, client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintToChat(client, "\x03[RP ADMIN] Admin %N is currently using Spawn Mode.", SpawnModeAdmin);
	}
	return Plugin_Handled;
}
public Action:SpawnMode_Restart(Handle:Timer, any:client)
{
	spawnmodekv = CreateKeyValues("Spawns");
	SMSpawns = 0;
	KvRewind(spawnmodekv);
	if (spawnmodekv == INVALID_HANDLE)
	{
		CreateTimer(0.1, SpawnMode_Restart, client);
	}
}
public Menu_SpawnMode(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"1"))
		{
			decl Ent;
			//Ent:
			Ent = GetClientAimTarget(param1, false);
			if (Ent == -1)
			{
				decl Float:_origin[3], Float:_angles[3];
				GetClientEyePosition( param1, _origin );
				GetClientEyeAngles( param1, _angles );

				new Handle:trace = TR_TraceRayFilterEx( _origin, _angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers );
				if( !TR_DidHit( trace ) )
				{
					PrintToChat(param1, "\x03[RR]Unable to pick the current location.");
					return;
				}
				decl Float:position[3];
				TR_GetEndPosition(position, trace);

				PrintToChat(param1, "\x03[RR] New Spawn #%i -- Location: %f, %f, %f.", SMSpawns, position[0], position[1], position[2]);

				g_SpawnModeLoc[SMSpawns][0] = position[0];
				g_SpawnModeLoc[SMSpawns][1] = position[1];
				g_SpawnModeLoc[SMSpawns][2] = position[2];
				
				
				new String:spawn_temp[8];
				Format(spawn_temp, sizeof(spawn_temp), "%i", SMSpawns);
				
				KvRewind(spawnmodekv);
				if (KvJumpToKey(spawnmodekv, spawn_temp, true))
				{
					SelectedSpawn = SMSpawns;
					KvSetFloat(spawnmodekv, "x", position[0]);
					KvSetFloat(spawnmodekv, "y", position[1]);
					KvSetFloat(spawnmodekv, "z", position[2]+4);
					SMSpawns += 1;
					
					// We have the location for the spawn, but now we need to choose a team or class.
					new Handle:spawn_add_menu = CreateMenu(Menu_SpawnModeAdd);
					SetMenuTitle(spawn_add_menu, "Spawn %s", spawn_temp);							
					AddMenuItem(spawn_add_menu, "1", "Team: Unselected");
					AddMenuItem(spawn_add_menu, "2", "Class: Unselected");
					DisplayMenu(spawn_add_menu, param1, MENU_TIME_FOREVER);
					return;
				} else PrintToChat(param1, "\x03[RP ERROR] Spawn %i could not be created.  :(", SMSpawns);
				KvRewind(spawnmodekv);
				
			}
			else PrintToChat(param1, "\x03[RP ADMIN] You must look at the ground.");
			
			InSpawnMode = true;
			new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "Spawn Mode");
			CreateSpawnModeMenu(spawn_mode_menu, title_str);		
			DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info,"2"))
		{
			// Save Spawns
			new String:sPath[PLATFORM_MAX_PATH];
			new String:mapname[64];
			new String:path_str[96];
	
			GetCurrentMap(mapname, sizeof(mapname));
			Format(path_str, sizeof(path_str), "configs/rp_map_configs/%s_spawns.txt", mapname);
			
			BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
			KvRewind(spawnmodekv);
			KeyValuesToFile(spawnmodekv, sPath);			
			
			new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "All Spawns Saved");
			CreateSpawnModeMenu(spawn_mode_menu, title_str);		
			DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
			
			PrintToChat(param1, "\x03[RP ADMIN] Spawns Saved, changes not loaded yet.");
		}
		if (StrEqual(info,"3"))
		{
			// List Spawns
			new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "See Console for Output.");
			CreateSpawnModeMenu(spawn_mode_menu, title_str);		
			DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
			
			if (SMSpawns <= 0)
			{
				PrintToChat(param1, "\x03[RP ADMIN] No Spawns Yet.");
			}
			else
			{
				KvRewind(spawnmodekv);
				
				PrintToChat(param1, "\x03[RP ADMIN] See Console for Output.");
				PrintToConsole(param1, "[RP] Spawn Mode Spawns");
				PrintToConsole(param1, "[RP] Total Spawns:  %i", SMSpawns);
				
				new Float:temp_x;
				new Float:temp_y;
				new Float:temp_z;
				
				new String:spawn_temp2[4];
								
				for (new i = 0; i <= SMSpawns; i++)
				{
					Format(spawn_temp2, sizeof(spawn_temp2), "%i", i);
					if (KvJumpToKey(spawnmodekv, spawn_temp2, false))
					{
						temp_x = KvGetFloat(spawnmodekv, "x", -6.6);
						temp_y = KvGetFloat(spawnmodekv, "y", -6.6);
						temp_z = KvGetFloat(spawnmodekv, "z", -6.6);
						
						PrintToConsole(param1, "[RP] Spawn #%i:  x = %f  y = %f  z = %f", i, temp_x, temp_y, temp_z);
						KvRewind(spawnmodekv);
					}
					else
					{
						KvRewind(spawnmodekv);
						break;
					}
				}
			}
		}
		if (StrEqual(info,"4"))
		{
			// Reset all changes.
			new Handle:spawn_mode_reset_menu = CreateMenu(Menu_SpawnModeReset);
			SetMenuTitle(spawn_mode_reset_menu, "Delete All Changes?");
		
			AddMenuItem(spawn_mode_reset_menu, "1", "Yes");
			AddMenuItem(spawn_mode_reset_menu, "2", "No");
		
			DisplayMenu(spawn_mode_reset_menu, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info,"5"))
		{
			new Handle:spawn_mode_exit_menu = CreateMenu(Menu_SpawnModeExit);
			SetMenuTitle(spawn_mode_exit_menu, "Save Changes Before Exit?");
		
			AddMenuItem(spawn_mode_exit_menu, "1", "Yes");
			AddMenuItem(spawn_mode_exit_menu, "2", "No");
		
			DisplayMenu(spawn_mode_exit_menu, param1, MENU_TIME_FOREVER);
		}
	}
	return;
}
public Menu_SpawnModeAdd(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"1"))
		{
			// This mode selects a team.
			if (SelectedSpawn < 0)
			{
				return;
			}
			new Handle:spawn_mode_team_select = CreateMenu(Menu_SpawnTeamSelect);
			SetMenuTitle(spawn_mode_team_select, "Select Team for Spawn %i", SelectedSpawn);
		
			new String:i_str[4];
			for (new i = 0; i < team_index; i++)
			{
				Format(i_str, sizeof(i_str), "%i", i);
				AddMenuItem(spawn_mode_team_select, i_str, team_name[i]);
			}
			DisplayMenu(spawn_mode_team_select, param1, MENU_TIME_FOREVER);
			return;
		}
		if (StrEqual(info,"2"))
		{
			// This mode selects a class.
			if (SelectedSpawn < 0)
			{
				return;
			}
			new Handle:spawn_mode_class_select = CreateMenu(Menu_SpawnClassSelect);
			SetMenuTitle(spawn_mode_class_select, "Select Class for Spawn %i", SelectedSpawn);
		
			new String:i_str[4];
			for (new i = 0; i < class_index; i++)
			{
				Format(i_str, sizeof(i_str), "%i", i);
				AddMenuItem(spawn_mode_class_select, i_str, class_name[i]);
			}
			DisplayMenu(spawn_mode_class_select, param1, MENU_TIME_FOREVER);
			return;
		}
	}
	KvRewind(spawnmodekv);
	return;
}
public Menu_SpawnTeamSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		KvRewind(spawnmodekv);
		new String:info[32];
		new String:spawn_temp[8];
		Format(spawn_temp, sizeof(spawn_temp), "%i", SelectedSpawn);
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);
		
		KvJumpToKey(spawnmodekv, spawn_temp, false);

		KvSetString(spawnmodekv, "team", info);
		new t = StringToInt(info);
		SetMenuTitle(spawn_mode_menu, "Spawn %s Set to %s", spawn_temp, team_name[t]);

		SelectedSpawn = -1;
		KvRewind(spawnmodekv);

		AddMenuItem(spawn_mode_menu, "1", "Set Location as a Spawn");
		AddMenuItem(spawn_mode_menu, "2", "Save");
		AddMenuItem(spawn_mode_menu, "3", "List Spawns");
		AddMenuItem(spawn_mode_menu, "4", "Reset Spawn Mode");
		AddMenuItem(spawn_mode_menu, "5", "Exit Spawn Mode");

		DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
	}
	KvRewind(spawnmodekv);
	SelectedSpawn = -1;
	return;
}
public Menu_SpawnClassSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		KvRewind(spawnmodekv);
		new String:info[32];
		new String:spawn_temp[8];
		Format(spawn_temp, sizeof(spawn_temp), "%i", SelectedSpawn);
		GetMenuItem(menu, param2, info, sizeof(info));
		
		KvJumpToKey(spawnmodekv, spawn_temp, false);
		
		KvSetString(spawnmodekv, "class", info);

		SelectedSpawn = -1;
		KvRewind(spawnmodekv);

		new c = StringToInt(info);

		new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);
		SetMenuTitle(spawn_mode_menu, "Spawn %s Set to %s, mode set to Class", spawn_temp, class_name[c]);

		AddMenuItem(spawn_mode_menu, "1", "Set Location as a Spawn");
		AddMenuItem(spawn_mode_menu, "2", "Save");
		AddMenuItem(spawn_mode_menu, "3", "List Spawns");
		AddMenuItem(spawn_mode_menu, "4", "Reset Spawn Mode");
		AddMenuItem(spawn_mode_menu, "5", "Exit Spawn Mode");

		DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
	}
	KvRewind(spawnmodekv);
	SelectedSpawn = -1;
	return;
}
public Menu_SpawnModeReset(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"1"))
		{
			// Reset Spawns
			if (spawnmodekv != INVALID_HANDLE)
			{
				CloseHandle(spawnmodekv);
				spawnmodekv = INVALID_HANDLE;
			}
			spawnmodekv = CreateKeyValues("Spawns");
			SMSpawns = 0;
			KvRewind(spawnmodekv);
			
			new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "All Changes Reset");
			CreateSpawnModeMenu(spawn_mode_menu, title_str);		
			DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
		}
		else
		{
			new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "Spawn Mode");
			CreateSpawnModeMenu(spawn_mode_menu, title_str);		
			DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
		}
	}
	return;
}
public Menu_SpawnModeExit(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"1"))
		{
			// Save and exit
			new String:sPath[PLATFORM_MAX_PATH];
			new String:mapname[64];
			new String:path_str[96];
	
			GetCurrentMap(mapname, sizeof(mapname));
			Format(path_str, sizeof(path_str), "configs/rp_map_configs/%s_spawns.txt", mapname);
			
			BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
			KvRewind(spawnmodekv);
			KeyValuesToFile(spawnmodekv, sPath);
			if (spawnmodekv != INVALID_HANDLE)
			{
				KvRewind(spawnmodekv);
				CloseHandle(spawnmodekv);
				spawnmodekv = INVALID_HANDLE;
			}
			InSpawnMode = false;
			SpawnModeAdmin = -1;
			ReadSpawnFile(param1);
		}
		else
		{
			// Just exit
			InSpawnMode = false;
			SpawnModeAdmin = -1;
			if (spawnmodekv != INVALID_HANDLE)
			{
				KvRewind(spawnmodekv);
				CloseHandle(spawnmodekv);
				spawnmodekv = INVALID_HANDLE;
			}
			
			ReadSpawnFile(param1);
		}
	}
	return;
}
public Action:CommandSpawnReload(client, Arguments)
{
	ReadSpawnFile(client);
	return Plugin_Handled;
}
stock CreateSpawnModeMenu(Handle:spawn_mode_menu, String:title_str[])
{
	SetMenuTitle(spawn_mode_menu, title_str);
		
	AddMenuItem(spawn_mode_menu, "1", "Set Location as a Spawn");
	AddMenuItem(spawn_mode_menu, "2", "Save");
	AddMenuItem(spawn_mode_menu, "3", "List Spawns");
	AddMenuItem(spawn_mode_menu, "4", "Reset Spawn Mode");
	AddMenuItem(spawn_mode_menu, "5", "Exit Spawn Mode");
}



// ##########
// JAIL CELLS
// ##########


public ReadCellFile()
{
	new String:sPath[PLATFORM_MAX_PATH];
	new String:mapname[64];
	new String:path_str[96];
	
	GetCurrentMap(mapname, sizeof(mapname));
	new pos = FindCharInString(mapname, '/', true);
	if(pos == -1)
	{
		pos = 0;
	}
	else
	{
		pos += 1;
	}
	Format(path_str, sizeof(path_str), "configs/rp_map_configs/%s_cells.txt", mapname[pos]);	
	
	BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
	cellkv = CreateKeyValues("Cells");
	FileToKeyValues(cellkv, sPath);

	KvRewind(cellkv);

	if (!KvGotoFirstSubKey(cellkv))
	{
		PrintToServer("[RP DEBUG] There are no cells listed in %s, or there is an error with the file.", path_str);
		return;
	}

	new Float:cell[3];
	g_CellQty = -1;

	do
	{
		cell[0] = KvGetFloat(cellkv, "x", 0.0);
		cell[1] = KvGetFloat(cellkv, "y", 0.0);
		cell[2] = KvGetFloat(cellkv, "z", 0.0);
		g_CellQty += 1;

		g_CellLoc[g_CellQty][0] = cell[0];
		g_CellLoc[g_CellQty][1] = cell[1];
		g_CellLoc[g_CellQty][2] = cell[2];
		PrintToServer("[RP] Cell %i: x=%f y=%f z=%f", g_CellQty, g_CellLoc[g_CellQty][0], g_CellLoc[g_CellQty][1], g_CellLoc[g_CellQty][2]);
		
	} while (KvGotoNextKey(cellkv));
	PrintToServer("[RP] Jail Cells Loaded");
	PrintToServer("[RP] %i cells were detected.", g_CellQty+1);

}



// #####
// RP DB
// #####




public InitializeRPDB()
{
	// Same as createdbcars
	new String:error[255];
	new db_mode = GetConVarInt(g_Cvar_Database);
	
	if (db_mode == 1)
	{
		// MySQL
		
		db_rp = SQL_Connect("ln-roleplay", true, error, sizeof(error));
		if(db_rp == INVALID_HANDLE)
		{
			SetFailState("[class_menu.smx] %s", error);
		}
		
		// Stuff
		new len = 0;
		decl String:query[20000];
		
		// Format the DB RP Table
		len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Roleplay`");
		len += Format(query[len], sizeof(query)-len, " (`STEAMID` varchar(25) NOT NULL, `LASTONTIME` int(25) NOT NULL DEFAULT 0, ");
		len += Format(query[len], sizeof(query)-len, "`SEX` int(25) NOT NULL DEFAULT 0, `CASH` int(25) NOT NULL DEFAULT 0, `BANK` int(25) NOT NULL DEFAULT 0, `SAWS` int(25) NOT NULL DEFAULT 0, `DEPOSIT` int(25) NOT NULL DEFAULT 0, ");
		len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`STEAMID`));");
		
		
		// Lock and Load!!
		SQL_LockDatabase(db_rp);
		SQL_FastQuery(db_rp, query);
		SQL_UnlockDatabase(db_rp);
		started = 1;
		
		PrintToServer("[RP] RP Data Base Created//Loaded!! (Mode 1)");
	}
	else if (db_mode == 2) //sqlite
	{
		db_rp = SQLite_UseDatabase("rp_data", error, sizeof(error));
		if(db_rp == INVALID_HANDLE)
		{
			SetFailState("[class_menu.smx] %s", error);
		}
		
		// Stuff
		new len = 0;
		decl String:query[20000];
		
		// Format the DB RP Table
		len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Roleplay`");
		len += Format(query[len], sizeof(query)-len, " (`STEAMID` varchar(25) NOT NULL, `LASTONTIME` int(25) NOT NULL DEFAULT 0, ");
		len += Format(query[len], sizeof(query)-len, "`SEX` int(25) NOT NULL DEFAULT 0, `CASH` int(25) NOT NULL DEFAULT 0, `BANK` int(25) NOT NULL DEFAULT 0, `SAWS` int(25) NOT NULL DEFAULT 0, `DEPOSIT` int(25) NOT NULL DEFAULT 0, ");
		len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`STEAMID`));");
		
		
		// Lock and Load!!
		SQL_LockDatabase(db_rp);
		SQL_FastQuery(db_rp, query);
		SQL_UnlockDatabase(db_rp);
		started = 1;
		
		PrintToServer("[RP] RP Data Base Created//Loaded!! (Mode 2)");
	}
	else
	{
		Format(error, sizeof(error), "[RP] rp_db_mode is %i when it needs to be 1 or 2.", db_mode);
		SetFailState("[class_menu.smx] %s", error);
	}
}

public InitializeClientonDB(client)
{
	if(IsFakeClient(client)) return true;
	
	new String:SteamId[255];
	new String:query[255];
	
	new conuserid;
	conuserid = GetClientUserId(client);
	
	GetClientAuthId(client, AuthId_Engine, SteamId, sizeof(SteamId));
	Format(query, sizeof(query), "SELECT LASTONTIME FROM Roleplay WHERE STEAMID = '%s';", SteamId);
	SQL_TQuery(db_rp, T_CheckConnectingRP, query, conuserid);
	return true;
}
public T_CheckConnectingRP(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	
	/* Make sure the client didn't disconnect while the thread was running */
	
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return true;
	}
	
	new String:SteamId[255];
	GetClientAuthId(client, AuthId_Engine, SteamId, sizeof(SteamId));
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		PrintToServer("[RP] %N's Query failed! %s", client, error);
	}
	else 
	{
		new String:buffer[512];
		if (!SQL_GetRowCount(hndl))
		{
			// insert user
			GetClientAuthId(client, AuthId_Engine, SteamId, sizeof(SteamId));
			Format(buffer, sizeof(buffer), "INSERT INTO Roleplay (`STEAMID`,`LASTONTIME`, `SEX`, `CASH`, `BANK`, `SAWS`, `DEPOSIT`) VALUES ('%s',%i, 1, 500, 500, 0, 0);", SteamId, GetTime());
			SQL_FastQuery(db_rp, buffer);

			player_gender[client] = 1;
			money[client] = 500;
			bank[client] = 500;
			saws[client] = 0;
			player_cash_or_dd[client] = 0;
			
			PrintToChatAll("\x04[RP] Registered New Player: %N", client);
			PrintToServer("[RP] Registered New Player: %N", client);
	
			new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			SetEntData(client, MoneyOffset, money[client], 4, true);
		}
		else
		{
			Format(buffer, sizeof(buffer), "SELECT * FROM `Roleplay` WHERE STEAMID = '%s';", SteamId);
			SQL_TQuery(db_rp, DBRPLoad_Callback, buffer, data);
		}
		FinallyLoaded(client);
	}
	return true;
}
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogMessage("SQL Error: %s", error);
	}
}
public FinallyLoaded(client)
{
	if (client <= 0)return true;
	if(!IsClientConnected(client))return true;
	if(IsFakeClient(client)) return true;
	InQuery = false;		
	Loaded[client] = true;
	IsDisconnect[client] = false;
	PrintToServer("[RP Debug] %N was loaded.", client);
	return true;
}

// New Client Loading Done.  Now for Client Data Updating

public Action:DBSave_Restart(Handle:Timer, any:client){
	DBSave(client);
	return Plugin_Handled;
}
public DBSave(client)
{
	if(!IsClientConnected(client))return true;
	if(InQuery)
	{
		CreateTimer(1.0, DBSave_Restart, client);
		return true;
	}
	
	
	if(Loaded[client]){
		InQuery = true;
		new userid = GetClientUserId(client);
				
		//Declare:
		new String:SteamId[32], String:query[512];
		new UnixTime = GetTime();
		
		//Initialize:
		GetClientAuthId(client, AuthId_Engine, SteamId, sizeof(SteamId));
		
		Format(query, sizeof(query), "UPDATE Roleplay SET LASTONTIME = %d WHERE STEAMID = '%s';",UnixTime, SteamId);
		SQL_TQuery(db_rp, T_SaveCallback, query, userid);		

		Format(query, sizeof(query), "UPDATE Roleplay SET `SEX` = %i, `CASH` = %i, `BANK` = %i, `SAWS` = %i, `DEPOSIT` = %i WHERE STEAMID = '%s';", player_gender[client], money[client], bank[client], saws[client], player_cash_or_dd[client], SteamId);				
		SQL_TQuery(db_rp, T_SaveCallback, query, userid);

		if (GetConVarInt(g_Cvar_Debug))
		{
			PrintToChatAll("\x04[DEBUG] Updated Player %N %s", client, SteamId);
		}
		PrintToServer("[DEBUG] Updated Player %N %s", client, SteamId);
			
		if(IsDisconnect[client])
		{
			Loaded[client] = false;
			IsDisconnect[client] = false;
		}
		InQuery = false;
	}
	return true;
}
public T_SaveCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	/* Make sure the client didn't disconnect while the thread was running */
	if (GetClientOfUserId(data) == 0)
	{
		return;
	}
	return;
}
// Now we go to loading existing clients.

public DBRPLoad_Callback(Handle:owner, Handle:hndl, const String:error[], any:data)
{  
	new client = GetClientOfUserId(data);
	
	//Make sure the client didn't disconnect while the thread was running
	
	if(client == 0)
	{
		return true;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		PrintToServer("[RP ERROR] DBRPLoad_Callback A %N's Query failed! %s", client, error);
		PrintToChatAll("\x04[RP ERROR] DBRPLoad_Callback A %N's Query failed! %s", client, error);
	}
	else
	{
		new String:SteamId[32];
		new String:Found_Steam[32];
		GetClientAuthId(client, AuthId_Engine, SteamId, 32);
		
		if(!SQL_GetRowCount(hndl))
		{	
			PrintToChatAll("\x04[RP ERROR] Client (%i) %s was not found in the DB.", client, SteamId);
			PrintToServer("[RP ERROR] Client (%i) %s was not found in the DB.", client, SteamId);			
			LogError("Database error! SteamID not found!");
		}
		else
		{
			while (SQL_FetchRow(hndl))
			{
				SQL_FetchString(hndl, (0), Found_Steam, sizeof(Found_Steam));
				player_gender[client] = SQL_FetchInt(hndl,(2));
				money[client] = SQL_FetchInt(hndl,(3));
				bank[client] = SQL_FetchInt(hndl,(4));
				saws[client] = SQL_FetchInt(hndl,(5));
				player_cash_or_dd[client] = SQL_FetchInt(hndl,(6));
			}
		} 
	}
	return true;
}



// ######
// STOCKS
// ######



public bool:TraceEntityFilterPlayers( entity, contentsMask, any:data )
{
    return entity > MaxClients && entity != data;
}
stock GetTargetName(entity, String:buf[], len)
{
	// Thanks to Joe Maley for this.
	GetEntPropString(entity, Prop_Data, "m_iName", buf, len);
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

public Action:HudRolePlay(Handle:Timer, any:client)
{
	if(IsClientInGame(client))
	{
		new c = player_class[client];
		new t = player_team[client];
		new String:class[128];
		new String:team[128];
		new String:lieu[128];
		if (c < 0)
		{
			class = "Class Unselected";
			player_salary[client] = 0;
		}
		else
		{
			class = class_name[c];
			player_salary[client] = class_salary[c];
		}
		if (t == -1)
		{
			team = "Team Unselected";
		}
		else
		{
			team = team_name[t];
		}
		if (AtGas[client])
		{
			lieu = "Gas Station";
		}
		else if (AtATM[client])
		{
			lieu = "ATM";
		}
		else if (AtVend[client])
		{
			lieu = "Vending Machine";
		}
		else
		{
			lieu = "";
		}

		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		money[client] = GetEntData(client, MoneyOffset, 4);
		
		if (money[client] < 0)
		{
			money[client] = 0;
		}
		if (bank[client] < 0)
		{
			bank[client] = 0;
		}
		new String:tmptext[1024];
		if (!IsPlayerAlive(client))
		{
			// Player is dead.  Show respawn countdown.
			if (player_respawn_wait[client] > 9)
			{
				Format(tmptext, sizeof(tmptext), "Cash: $%i  Bank: $%i\nTeam: %s  Class: %s\nSalary: $%i  You are dead.  Respawn in: %i", money[client], bank[client], team, class, player_salary[client], player_respawn_wait[client]);
			}
			else if (player_respawn_wait[client] > 0)
			{
				Format(tmptext, sizeof(tmptext), "Cash: $%i  Bank: $%i\nTeam: %s  Class: %s\nSalary: $%i  You are dead.  Respawn in:  %i", money[client], bank[client], team, class, player_salary[client], player_respawn_wait[client]);
			}
			else
			{
				Format(tmptext, sizeof(tmptext), "Cash: $%i  Bank: $%i\nTeam: %s  Class: %s\nSalary: $%i  You can respawn now.", money[client], bank[client], team, class, player_salary[client]);
			}
			PrintHintText(client, tmptext);
			CreateTimer(0.2, HudRolePlay, client);
		}
		else
		{
			if ((AtGas[client]) || (AtVend[client]))
			{
				Format(tmptext, sizeof(tmptext), "Cash: $%i  Bank: $%i\nTeam: %s  Class: %s\nSalary: $%i  You are at a %s.", money[client], bank[client], team, class, player_salary[client], lieu);
			}
			else if (AtATM[client])
			{
				if ((team_competing[t] == true) && (GetConVarInt(g_Cvar_TeamMode)))
				{
					Format(tmptext, sizeof(tmptext), "%T", "HUD_ATM_T", client, money[client], bank[client], team, class, player_salary[client], team, team_points[t]);
				}
				else
				{
					Format(tmptext, sizeof(tmptext), "%T", "HUD_ATM", client, money[client], bank[client], team, class, player_salary[client]);
				}
			}
			else
			{
				if ((team_competing[t] == true) && (GetConVarInt(g_Cvar_TeamMode)))
				{
					Format(tmptext, sizeof(tmptext), "%T", "HUD_T", client, money[client], bank[client], team, class, player_salary[client], team, team_points[t]);
				}
				else
				{
					Format(tmptext, sizeof(tmptext), "%T", "HUD", client, money[client], bank[client], team, class, player_salary[client]);
				}
			}
			PrintHintText(client, tmptext);
			CreateTimer(0.2, HudRolePlay, client);
		}
	}
}

stock Blops_ShowBarTime(client, dur)
{
	if (!IsValidEntity(client) || !IsClientInGame(client)) return;
	Blops_RemoveBarTime(INVALID_HANDLE, client);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", dur);
	CreateTimer(float(dur), Blops_RemoveBarTime, client);
}

public Action:Blops_RemoveBarTime(Handle: timer, any:client)
{
	if (!IsValidEntity(client) || !IsClientInGame(client)) return;
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
}