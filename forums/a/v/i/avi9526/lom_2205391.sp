//──────────────────────────────────────────────────────────────────────────────
/*
	Copyright 2006-2014 AlliedModders LLC
	Copyright 2013-2014 avi9526 <dromaretsky@gmail.com>
	Copyright 2013-2014 FlaminSarge http://forums.alliedmods.net/member.php?u=84304
	Copyright 2013-2014 Doctor Mc kay http://www.doctormckay.com
*/
//──────────────────────────────────────────────────────────────────────────────
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
//──────────────────────────────────────────────────────────────────────────────
#pragma semicolon	1
//──────────────────────────────────────────────────────────────────────────────
// vim: set ts=4 :
//──────────────────────────────────────────────────────────────────────────────
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items_giveweapon>
//──────────────────────────────────────────────────────────────────────────────
#define PLUGIN_VERSION "0.75"
//──────────────────────────────────────────────────────────────────────────────
// Amount of used configs
#define CFG_COUNT	2
// Max used strings length
#define STR_LEN		128
// Admin flag
#define ADMFLAG_NONE	0
// Load-Out Manager activation condition
#define COND_NEVER	-1	// never
#define COND_VALVE	0	// only when Valve's item server off-line
#define COND_ALWAYS	1	// always
// Sub-menu max level
#define MAX_MENU_LEVEL	32
// Amount of weapon in load-out
#define MAX_WEAP	5
// Amount of classes in TF2
#define MAX_CLASS	9
// Max amount of load-outs that player can have per every class
#define MAX_LOADOUT	14
// Error codes
#define ERR_NONE			0	// unknown
#define ERR_OK				1	// no error - success
#define ERR_WEAP_NOT_FOUND	2	// no weapon founded by identifier
#define ERR_WRONG_CLASS		4	// player has class which is not allowed by weapon class mask
#define ERR_WRONG_SLOT		8	// requested weapon in wrong slot
#define ERR_ACCESS			16	// access to requested weapon is restricted
#define ERR_OP				32	// access to over-powered weapon allowed only when apocalypse mode activated
#define ERR_GAMEMODE		64	// weapon is restricted by game mode
// Game modes
#define GAME_MODE_ANY		1
#define GAME_MODE_MVM		2
//──────────────────────────────────────────────────────────────────────────────
#define LOG_PREFIX		"[LOM]"
#define CHAT_PREFIX		"\x01[\x0763B5EALOM\x01]"
//──────────────────────────────────────────────────────────────────────────────
// Command's and console variables and config files
#define CVAR_VERSION	"sm_lom_version"
#define CVAR_APOCALIPSE	"sm_lom_apocalypse"
#define CVAR_INSTANT	"sm_lom_instant"
#define CVAR_GIVECUSTOM	"sm_lom_givecustom"
#define CVAR_WEAPONS	"sm_lom_weapons"
#define CMD_ACCESS		"sm_lom_access"
#define CMD_MENU		"sm_lom"
#define CMD_RELOAD		"sm_lom_reload"
#define CMD_LONAME		"sm_loname"
#define CFG_WEAPONS_FILENAME		"configs/weapons.cfg"
#define CFG_WEAPONS_NAME			"LOM-Weapon-Config"
#define CFG_WEAPONS_SECTION_LIST	"lom_weapon_list"
// Config of GiveWeapon mod
#define CFG_GIVECUSTOM_FILENAME		"configs/tf2items.givecustom.txt"
#define CFG_GIVECUSTOM_SECTION_LIST	"custom_give_weapons_vlolz"
// Menu
#define MENU_MAIN		"main"
#define MENU_SLOT		"slot"
#define MENU_CLASS		"class"
#define MENU_WEAP		"weapon"
#define MENU_HELP		"help"
#define MENU_SAVE		"save"
#define MENU_LOAD		"load"
#define MENU_REM		"remove"
#define MENU_INFO		"info"
// Menu items
// Basic
#define ITEM_BASIC_BACK		"back"
#define ITEM_BASIC_EXIT		"exit"
// Slot
#define ITEM_SLOT_PRIMARY	"Primary"
#define ITEM_SLOT_SECOND	"Secondary"
#define ITEM_SLOT_MELEE		"Melee"
#define ITEM_SLOT_PDA1		"PDA 1"
#define ITEM_SLOT_PDA2		"PDA 2"
// Class
#define ITEM_CLASS_UNKNOWN	"Unknown"
#define ITEM_CLASS_SCOUT	"Scout"
#define ITEM_CLASS_SOLDIER	"Soldier"
#define ITEM_CLASS_PYRO		"Pyroman"
#define ITEM_CLASS_DEMO		"Demoman"
#define ITEM_CLASS_HEAVY	"Heavy"
#define ITEM_CLASS_ENGI		"Engineer"
#define ITEM_CLASS_MEDIC	"Medic"
#define ITEM_CLASS_SNIPER	"Sniper"
#define ITEM_CLASS_SPY		"Spy"
// Main menu items
#define ITEM_MAIN_GIVE		"main_give"
#define ITEM_MAIN_LOAD		"main_load"
#define ITEM_MAIN_SAVE		"main_save"
#define ITEM_MAIN_REM		"main_rem"
#define ITEM_MAIN_HELP		"main_help"
#define ITEM_MAIN_ENABLE	"main_enable"
#define ITEM_MAIN_DISABLE	"main_disable"
#define ITEM_MAIN_INFO		"main_info"
// Save loadout menu items
#define ITEM_SAVE_NEW		"save_new"
//──────────────────────────────────────────────────────────────────────────────
public Plugin:myinfo = 
{
	name = "[TF2] Load-Out Manager",
	author = "avi9526. See source code for more details",
	description = "Menu based GUI wrap for GiveWeapon plug-in",
	version = PLUGIN_VERSION,
	url = "/dev/null"
}
//──────────────────────────────────────────────────────────────────────────────
// Global variables
//──────────────────────────────────────────────────────────────────────────────
new Handle:	hVersion;

// Special mode when over-powered weapon allowed for anyone, which make possible to beat MvM wave 666 with 1..2 players
// Over-powered weapon itself does not present in this plug-in or game - create GiveWeapon config file to make such weapon first
new Handle:	hApocalypse;
new Apocalypse;

// Store code for game mode. MvM only supported for now
// Introduced to deal with Deflector - minigun that is available only on MvM maps
new GameModeFlag;

// Give weapon to player instantly or wait until he touch locker
new Handle:	hInstant;
new Instant;

enum WeaponInfo
{
	// Identifier (see https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes)
	ID,
	// Custom weapon in tf2items.givecustom.txt config is given by own ID but it is fake,
	// thats just weapon with custom attributes and etc, which is based on some parent weapon, here we store parent weapon ID
	ParentID,
	// Class restrictions binary mask (Scout = 2, Sniper = 4, Soldier = 8, DemoMan = 16, Medic = 32, Heavy = 64, Pyro = 128, Spy = 256, Engineer = 512, All = = 1023)
	Class,
	// Slot index (Primary = 0, Secondary = 1, Melee = 2, PDA1 = 3, PDA2 = 4)
	// Used to group weapon in menu
	Slot,
	// Game mode restrictions binary mask (MvM = 1)
	// Was used to deal with "Deflector" - minigun which only available in MvM game mode
	GameMode,
	// Name
	String:	Name[STR_LEN],
	// Access command
	// Real or non-existent command with some admin overrides to control access to this weapon
	String:	Access[STR_LEN],
	// WeaponInfo used only when admin allow it
	// Use for over-powered weapon
	Apocalyptic,
	// This variable stores weapon index in weapon's array
	// not supposed to match, used to speed-up weapon look-up in array if possible
	ArrayIndex
};

// Info about config file
enum Config
{
	// Path to config (with base in sourcemod folder)
	String:	Path[STR_LEN],
	// Name of the section with weapons list
	String:	WeapSecName[STR_LEN],
	// Name of CVar to set enable state for config
	String:	sEnabled[STR_LEN],
	// CVar handle to control config enable state
	Handle: hEnabled,
	// Is config allowed to be parsed
	Enabled
};

// Info about menu
enum Menu
{
	// Identifier of menu (see MENU_* constants above)
	String:	ID[STR_LEN],
	// Selected by player menu item
	String:	Return[STR_LEN],
	// Player class for the moment when he select item
			MenuPlrClass
};

enum LoadoutInfo
{
	// Loadout identifier
	LoID,
	// Name for loadout
	String: LoName[STR_LEN],
	// Array which store list of weapon in load-out
	Handle: LoWeap
};

enum ClassInfo
{
	// Current weapon for class
	Handle: CurWeap,
	// Array which store list of player's load-outs
	Handle: LoadOuts
};

enum PlayerData
{
	// Player ID
			PlrID,
	// Sequence of menu calls with returned values
	Handle: MenuSeq,
	// Class specific data
	Handle: Classes,
	// String buffer used to give name to loadouts
	String: StrBufLOName,
	// Is LOM enabled for player
			PlrEnabled
};

// Array
new Players[MAXPLAYERS+1][PlayerData];

new	Configs[CFG_COUNT][Config];

new Handle:	Weapons;
//──────────────────────────────────────────────────────────────────────────────
// Hook functions
//──────────────────────────────────────────────────────────────────────────────
public OnPluginStart()
{
	hVersion = CreateConVar("sm_lom_version", PLUGIN_VERSION, "Load-Out Manager Version", FCVAR_PLUGIN);
	if (hVersion != INVALID_HANDLE)
	{
		SetConVarString(hVersion, PLUGIN_VERSION);
	}
	
	GameModeFlag = 0;
	
	new Temp[WeaponInfo];

	Weapons = CreateArray(sizeof(Temp));
	
	hApocalypse = CreateConVar(CVAR_APOCALIPSE, "0", "Allow over-powered weapon to everyone", _, true, 0.0, true, 1.0);
	Apocalypse = GetConVarInt(hApocalypse);
	HookConVarChange(hApocalypse, OnConVarChanged);
	
	hInstant = CreateConVar(CVAR_INSTANT, "1", "Give weapon to player instantly or wait until him to touch locker", _, true, 0.0, true, 1.0);
	Instant = GetConVarInt(hInstant);
	HookConVarChange(hInstant, OnConVarChanged);
	
	// Init list of used config files
	InitConfigList();
	// Init data for all players
	InitPlayersData();
	
	for (new i = 0; i < CFG_COUNT; i ++)
	{
		Configs[i][hEnabled] = CreateConVar(Configs[i][sEnabled], "1", "Is allowed to read appropriate config file", _, true, 0.0, true, 1.0);
		Configs[i][Enabled] = GetConVarInt(Configs[i][hEnabled]);
		HookConVarChange(Configs[i][hEnabled], OnConVarChanged);
	}
	
	for (new i = 0; i < MAXPLAYERS+1; i ++)
	{
		Players[i][PlrID] = i;
	}
	
	// Hook to event when player gets items
	HookEvent("post_inventory_application", OnInventoryApplication);
	
	RegConsoleCmd(CMD_MENU, Command_MainMenu, "Load-Out Manager");
	RegConsoleCmd(CMD_LONAME, Command_LoadoutName, "Load-Out Manager - give name to loadout before save");
	RegAdminCmd(CMD_RELOAD, Command_Reload, ADMFLAG_RCON, "Load-Out Manager - Reload config files");
}
//──────────────────────────────────────────────────────────────────────────────
// If console variable changed - need change corresponding internal variables
public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new NewIntVal = -1;
	new OldIntVal = -1;
	new Client = -1;
	if(convar == hApocalypse)
	{
		NewIntVal = StringToInt(newValue);
		OldIntVal = StringToInt(oldValue);
		if (NewIntVal != OldIntVal)
		{
			Apocalypse = NewIntVal;
			LogAction(-1, -1, "%s '%s' now is %d", LOG_PREFIX, CVAR_APOCALIPSE, Apocalypse);
			if (Apocalypse)
			{
				PrintToChatAll("%s Admin has started apocalypse mode - go get Over-Powered [OP] weapon in \"!lom\" menu", CHAT_PREFIX);
			}
			else
			{
				PrintToChatAll("%s Admin has disabled apocalypse mode", CHAT_PREFIX);
			}
			for (Client = 0; Client < MAXPLAYERS+1; Client ++)
			{
				ResetPlayerWeapon(Players[Client]);
			}
		}
	}
	else if(convar == hInstant)
	{
		NewIntVal = StringToInt(newValue);
		OldIntVal = StringToInt(oldValue);
		if (NewIntVal != OldIntVal)
		{
			Instant = NewIntVal;
			LogAction(-1, -1, "%s '%s' now is %d", LOG_PREFIX, CVAR_INSTANT, Instant);
		}
	}
	else
	{
		for (new i = 0; i < CFG_COUNT; i ++)
		{
			if (convar == Configs[i][hEnabled])
			{
				Configs[i][Enabled] = StringToInt(newValue);
				LogAction(-1, -1, "%s %s now is %d", LOG_PREFIX, Configs[i][sEnabled], Configs[i][Enabled]);
			}
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
public OnClientConnected(Client)
{
	ClearPlayerData(Players[Client]);
	Players[Client][PlrID] = Client;
	LogAction(-1, -1, "%s client connected %L", LOG_PREFIX, Players[Client][PlrID]);
}
//──────────────────────────────────────────────────────────────────────────────
public OnClientDisconnect(Client)
{
	ClearPlayerData(Players[Client]);
}
//──────────────────────────────────────────────────────────────────────────────
public OnPluginEnd()
{
	FreePlayersData();
}
//──────────────────────────────────────────────────────────────────────────────
public OnMapStart()
{
	if (IsMvM())
	{
		GameModeFlag = GAME_MODE_MVM;
		LogAction(-1, -1, "%s Game mode is MvM", LOG_PREFIX);
	}
	else
	{
		GameModeFlag = GAME_MODE_ANY;
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Hook callback
// any time player touch locker or respawn or etc - he gets weapon from item server (if available)
// so we need to re-give him weapon every time - not very good solution, but no other way at this moment
public OnInventoryApplication(Handle: event, const String: name[], bool: dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	// Give player current weapon and report about errors
	GivePlayerCurWeapon(Players[Client]);
}
//──────────────────────────────────────────────────────────────────────────────
// Console commands
//──────────────────────────────────────────────────────────────────────────────
// Console command to reload config files
public Action:Command_Reload(Client, Args)
{
	ReloadWeaponList();
	return Plugin_Handled;
}
//──────────────────────────────────────────────────────────────────────────────
// Console command to call main menu
public Action:Command_MainMenu(Client, Args)
{
	if (!IsValidClient(Client))
	{
		LogAction(-1, -1, "%s Wrong client '%L' triggered this function", LOG_PREFIX, Client);
		return Plugin_Handled;
	}
	
	if (!CheckCommandAccess(Client, CMD_ACCESS, ADMFLAG_NONE, true))
	{
		ReplyToCommand(Client, "%s You don't have access to this command. Check access to '%s' command", CHAT_PREFIX, CMD_ACCESS);
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(Client))
	{
		PrintToChat(Client, "%s You must be alive", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	if (Args == 0)
	{
		ShowMainMenu(Client);
	}
	else
	{
		// Command called with argument
		
		new String: StrBuf[STR_LEN];
		GetCmdArg(1, StrBuf, STR_LEN);
		TryGivePlayerLoadout(Players[Client],	// player info record
							 _: TF2_GetPlayerClass(Client),	// player class
							 StringToInt(StrBuf));	// loadout index
	}
	
	return Plugin_Handled;
}
//──────────────────────────────────────────────────────────────────────────────
// Console command to reload config files
public Action:Command_LoadoutName(Client, Args)
{
	if (!IsValidClient(Client))
	{
		LogAction(-1, -1, "%s Wrong client '%L' triggered this function", LOG_PREFIX, Client);
		return Plugin_Handled;
	}
	
	if (!CheckCommandAccess(Client, CMD_ACCESS, ADMFLAG_NONE, true))
	{
		ReplyToCommand(Client, "%s You don't have access to this command. Check access to '%s' command", CHAT_PREFIX, CMD_ACCESS);
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(Client))
	{
		PrintToChat(Client, "%s You must be alive", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	if (Args == 0)
	{
		ReplyToCommand(Client, "%s Provide name for loadout", CHAT_PREFIX);
	}
	else
	{
		// Command called with argument
		
		new String: StrBuf[STR_LEN];
		GetCmdArg(1, StrBuf, STR_LEN);
		Format(Players[Client][StrBufLOName], STR_LEN, "%s", StrBuf);
	}
	
	return Plugin_Handled;
}
//──────────────────────────────────────────────────────────────────────────────










//──────────────────────────────────────────────────────────────────────────────
// API
//──────────────────────────────────────────────────────────────────────────────
/**
 * Check if client is player (bot or human) that already in game
 *
 * @param Client		Player unique identifier
 * @return				Boolean
 * @error				No
 */
stock IsValidClient(Client)
{
	if ((Client <= 0) || (Client > MaxClients) || (!IsClientInGame(Client)))
	{
		return false;
	}
	
	if (IsClientSourceTV(Client) || IsClientReplay(Client))
	{
		return false;
	}
	
	return true;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Check if client is bot player that already in game
 *
 * @param Client		Player unique identifier
 * @return				Boolean
 * @error				No
 */
stock IsValidBot(Client)
{
	if (!IsValidClient(Client))
	{
		return false;
	}
	
	if (GetClientTeam(Client) <= 1)	// unassigned or spectators
	{
		return false;
	}
	
	return IsFakeClient(Client);
}
//──────────────────────────────────────────────────────────────────────────────
// Processing weapon info record
//──────────────────────────────────────────────────────────────────────────────
/**
 * Create weapon info record. Dummy function for further development
 *
 * @param Weap			WeaponInfo info record to be initialized
 * @noreturn
 * @error				No
 */
CreateWeapon(Weap[WeaponInfo])
{
	ClearWeapon(Weap);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Destroy weapon info record. Dummy function for further development
 *
 * @param Weap			WeaponInfo info record to be destroyed
 * @noreturn
 * @error				No
 */
DestroyWeapon(Weap[WeaponInfo])
{
	ClearWeapon(Weap);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Clear weapon info record
 *
 * @param Weap			WeaponInfo info record to be cleared
 * @noreturn
 * @error				No
 */
ClearWeapon(Weap[WeaponInfo])
{
	Weap[ID]			= -1;
	Weap[ParentID]		= -1;
	Weap[Class]			= -1;
	Weap[Slot]			= -1;
	Weap[GameMode]		= 0;
	Weap[Apocalyptic]	= 0;
	Weap[ArrayIndex]	= -1;
	Format(Weap[Name], STR_LEN, "");
	Format(Weap[Access], STR_LEN, "");
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Give weapon to client now
 *
 * @param Weap			WeaponInfo info record to given to player
 * @param Client		Player unique identifier
 * @return				0 on error, 1 on success
 * @error				No
 */
GiveWeapon(Weap[WeaponInfo], Client)
{
	new Result = 0;
	new Cls = 0;
	new Err = ERR_NONE;
	if (Weap[ID] >= 0)
	{
		Cls = _: TF2_GetPlayerClass(Client);
		Err = CheckWeapon(Weap, Client, Cls);
		if (Err == ERR_NONE)
		{
			if (TF2Items_CheckWeapon(Weap[ID]))
			{
				TF2Items_GiveWeapon(Client, Weap[ID]);
				LogAction(-1, -1, "%s Player '%L' gets weapon '%s' (%d)", LOG_PREFIX, Client, Weap[Name], Weap[ID]);
				Result = 1;
			}
		}
		else
		{
			ReportWeapError(Client, Err, Weap, Client, Cls);
		}
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Make a copy of weapon info record
 *
 * @param Src			WeaponInfo info record to be copied
 * @param Dest			Destenation for copy
 * @noreturn
 * @error				No
 */
CopyWeapon(Src[WeaponInfo], Dest[WeaponInfo])
{
	Dest[ID]			= Src[ID];
	Dest[ParentID]		= Src[ParentID];
	Dest[Class]			= Src[Class];
	Dest[Slot]			= Src[Slot];
	Dest[GameMode]		= Src[GameMode];
	Dest[Apocalyptic]	= Src[Apocalyptic];
	Dest[ArrayIndex]	= Src[ArrayIndex];

	Format(Dest[Name], sizeof(Dest[Name]), "%s", Src[Name]);
	Format(Dest[Access], sizeof(Dest[Access]), "%s", Src[Access]);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Check weapon
 *
 * @param Weap			WeaponInfo to be checked
 * @param Client		Player unique identifier
 * @param ClassIndex	Class to check, use -1 to skip
 * @param SlotIndex		Slot to check, use -1 to skip
 * @return				Error code
 * @error				No
 */
CheckWeapon(Weap[WeaponInfo], Client, ClassIndex = -1, SlotIndex = -1)
{
	new Result = ERR_NONE;
	if ((ClassIndex >= 0) && (!CheckWeapClass(Weap, ClassIndex)))
	{
		Result = Result | ERR_WRONG_CLASS;
	}
	if ((SlotIndex >= 0) && (!CheckWeapSlot(Weap, SlotIndex)))
	{
		Result = Result | ERR_WRONG_SLOT;
	}
	if (!CheckWeapAccess(Weap, Client))
	{
		Result = Result | ERR_ACCESS;
	}
	if (!CheckWeapApocMode(Weap, Apocalypse))
	{
		Result = Result | ERR_OP;
	}
	if (!CheckWeapGameMode(Weap, GameModeFlag))
	{
		Result = Result | ERR_GAMEMODE;
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Check if weapon can be used with some class
 *
 * @param Weap			WeaponInfo to be checked
 * @param ClassIndex	Class index to check weapon
 * @return				0 if weapon not allowed for this class, 1 if allowed
 * @error				No
 */
CheckWeapClass(Weap[WeaponInfo], ClassIndex)
{
	new Result = 0;
	new ClassMask = 1 << (_: ClassIndex);
	if (Weap[Class] & ClassMask > 0)
	{
		Result = 1;
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Check if weapon can be used with some slot
 *
 * @param Weap			WeaponInfo to be checked
 * @param SlotIndex		Slot index to check weapon
 * @return				0 if weapon not allowed for this slot, 1 if allowed
 * @error				No
 */
CheckWeapSlot(Weap[WeaponInfo], SlotIndex)
{
	new Result = 0;
	if (Weap[Slot] == _:SlotIndex)
	{
		Result = 1;
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Check if weapon can be used in some gamemode
 *
 * @param Weap			WeaponInfo to be checked
 * @param GameModeFlag	Gamemode binary flag to check weapon
 * @return				0 if weapon not allowed in this gamemode, 1 if allowed
 * @error				No
 */
CheckWeapGameMode(Weap[WeaponInfo], GameModeFl)
{
	new Result = 0;
	if (GameModeFl & Weap[GameMode] > 0)
	{
		Result = 1;
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Check if client has access to some weapon
 *
 * @param Weap			WeaponInfo to be checked
 * @param Client		Player unique identifier
 * @return				0 if client has no access to this weapon, 1 if access granted
 * @error				No
 */
CheckWeapAccess(Weap[WeaponInfo], Client)
{
	new Result = 0;
	if (strlen(Weap[Access]) > 0)
	{
		if (CheckCommandAccess(Client, Weap[Access], ADMFLAG_NONE, true))
		{
			Result = 1;
		}
	}
	else
	{
		Result = 1;
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Check if weapon allowed with current Apocalypse mode state
 *
 * @param Weap			WeaponInfo to be checked
 * @param Apoc			Apocalypse mode state
 * @return				0 if weapon not allowed to use, 1 if allowed
 * @error				No
 */
CheckWeapApocMode(Weap[WeaponInfo], Apoc)
{
	new Result = 0;
	if (! Weap[Apocalyptic] || Apoc)
	{
		Result = 1;
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Report error about receiving weapon to client
 *
 * @param Client		Player unique identifier
 * @param ErrCode		Error code to be reported
 * @param Weap			Weapon info
 * @param ClassIndex	Class, use -1 to skip
 * @param SlotIndex		Slot, use -1 to skip
 * @noreturn
 * @error				No
 */
ReportWeapError(Client, ErrCode, Weap[WeaponInfo], ClassIndex = -1, SlotIndex = -1)
{
	new String: StrBuf[STR_LEN];
	new String: StrBuf2[STR_LEN];
	if (IsValidClient(Client))
	{
		if (ErrCode & ERR_ACCESS != ERR_NONE)
		{
			PrintToChat(Client, "%s You do not have access to weapon \"%s\" (%d)", CHAT_PREFIX, Weap[Name], Weap[ID]);
		}
		if (ErrCode & ERR_GAMEMODE != ERR_NONE)
		{
			PrintToChat(Client, "%s WeaponInfo \"%s\" (%d) is not available in current game mode", CHAT_PREFIX, Weap[Name], Weap[ID]);
		}
		if (ErrCode & ERR_OP != ERR_NONE)
		{
			PrintToChat(Client, "%s WeaponInfo \"%s\" (%d) is over-powered - usage allowed only during apocalypse", CHAT_PREFIX, Weap[Name], Weap[ID]);
		}
		if ((ClassIndex >= 0) && (ErrCode & ERR_WRONG_CLASS != ERR_NONE))
		{
			Int2Class(ClassIndex, StrBuf, sizeof(StrBuf));
			PrintToChat(Client, "%s WeaponInfo \"%s\" (%d) is not allowed for \"%s\" class", CHAT_PREFIX, Weap[Name], Weap[ID], StrBuf);
		}
		if ((SlotIndex >= 0) && (ErrCode & ERR_WRONG_SLOT != ERR_NONE))
		{
			Int2Slot(SlotIndex, StrBuf, sizeof(StrBuf));
			Int2Slot(Weap[Slot], StrBuf2, sizeof(StrBuf2));
			PrintToChat(Client, "%s Can't equip weapon \"%s\" (%d) in slot \"%s\", this weapon is for slot \"%s\"", CHAT_PREFIX, Weap[Name], Weap[ID], StrBuf, StrBuf2);
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Processing weapon array
//──────────────────────────────────────────────────────────────────────────────
/**
 * Create array of weapons
 *
 * @param WeapArray		Weapon array to be initialized
 * @noreturn
 * @error				No
 */
CreateWeapArray(&Handle: WeapArray)
{
	new Temp[WeaponInfo];
	if (WeapArray != INVALID_HANDLE)
	{
		LogError("%s [%s] Weapon array seems not clear, reinitializing - possible memory leak", LOG_PREFIX, "CreateWeapArray");
	}
	CreateWeapon(Temp);
	WeapArray = CreateArray(sizeof(Temp));
	DestroyWeapon(Temp);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Destroy weapon array
 *
 * @param WeapArray		Weapon array to be destroyed
 * @noreturn
 * @error				No
 */
DestroyWeapArray(&Handle: WeapArray)
{
	ClearWeapArray(WeapArray);
	WeapArray = INVALID_HANDLE;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Clear weapon array
 *
 * @param WeapArray		Weapon array to be cleared
 * @noreturn
 * @error				No
 */
ClearWeapArray(&Handle: WeapArray)
{
	new i = 0;
	new Temp[WeaponInfo];
	new Size = GetArraySize(WeapArray);
	while (i < Size)
	{
		GetWeapFromArray(WeapArray, i, Temp);
		DestroyWeapon(Temp);
		i ++;
	}
	ClearArray(WeapArray);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Get weapon from weapon array
 *
 * @param Src			Load-out array
 * @param Dest			Destenation weapon info record
 * @return				0 on error, 1 on success
 * @error				WeaponInfo index out of loadout bounds. Loadout length missmatch predefined by MAX_WEAP value
 */
GetWeapFromArray(Handle: Src, Index, Dest[WeaponInfo])
{
	new Result = 0;
	new Size = GetArraySize(Src);
	if ((Index >= 0) && (Index < Size))
	{
		GetArrayArray(Src, Index, Dest[0]);
		Result = 1;
	}
	else
	{
		LogError("%s [%s] Requested weapon index '%d' is out of array bounds '%d..%d'", LOG_PREFIX, "GetWeapFromArray", Index, 0, Size);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Set weapon to weapon array
 *
 * @param Src			WeaponInfo info record to be put in loadout
 * @param Dest			Destenation array
 * @return				0 on error, 1 on success
 * @error				WeaponInfo index out of array bounds
 */
SetWeapToArray(Src[WeaponInfo], &Handle: Dest, Index)
{
	new Result = 0;
	new Size = GetArraySize(Dest);
	if ((Index >= 0) && (Index < Size))
	{
		SetArrayArray(Dest, Index, Src[0]);
		Result = 1;
	}
	else
	{
		LogError("%s [%s] Requested weapon index '%d' is out of array bounds '%d..%d'", LOG_PREFIX, "SetWeapToArray", Index, 0, Size);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Append weapon to weapon array
 *
 * @param Src			WeaponInfo info record to be put in loadout
 * @param Dest			Destenation array
 * @return				0 on error, 1 on success
 * @error				No
 */
AddWeapToArray(Src[WeaponInfo], &Handle: Dest)
{
	new Result = 0;
	PushArrayArray(Dest, Src[0]);
	Result = 1;
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Copy weapon array
 *
 * @param Src			Source array
 * @param Dest			Destenation array
 * @return				0 on error, 1 on success
 * @error				No
 */
CopyWeapArray(Handle: Src, &Handle: Dest)
{
	new Result = 0;
	new Size = 0;
	new i = 0;
	new WeapSrc[WeaponInfo];
	new WeapDest[WeaponInfo];
	ClearWeapArray(Dest);
	Size = GetArraySize(Src);
	ResizeArray(Dest, Size);
	while (i < Size)
	{
		GetWeapFromArray(Src, i, WeapSrc);
		CopyWeapon(WeapSrc, WeapDest);
		SetWeapToArray(WeapDest, Dest, i);
		i ++;
	}
	Result = 1;
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Processing loadout info record
//──────────────────────────────────────────────────────────────────────────────
/**
 * Create loadout info record
 *
 * @param Lo			Loadout info record to be initialized
 * @noreturn
 * @error				No
 */
CreateLoadOut(Lo[LoadoutInfo])
{
	CreateWeapArray(Lo[LoWeap]);
	ClearWeapArray(Lo[LoWeap]);
	new Temp[WeaponInfo];
	// Fill array with blank weapon info records
	CreateWeapon(Temp);
	new i;
	for (i = 0; i < MAX_WEAP; i ++)
	{
		AddWeapToArray(Temp, Lo[LoWeap]);
	}
	Lo[LoID] = 0;
	Format(Lo[LoName], STR_LEN, "");
	DestroyWeapon(Temp);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Destroy loadout info record. Dummy function for further development
 *
 * @param Lo			Loadout info record to be destroyed
 * @noreturn
 * @error				No
 */
DestroyLoadOut(Lo[LoadoutInfo])
{
	DestroyWeapArray(Lo[LoWeap]);
	Format(Lo[LoName], STR_LEN, "");
	Lo[LoID] = 0;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Clear loadout info record
 *
 * @param Lo			Loadout info record to be cleared
 * @noreturn
 * @error				No
 */
ClearLoadOut(Lo[LoadoutInfo])
{
	new i = 0;
	new Weap[WeaponInfo];
	new Size = GetArraySize(Lo[LoWeap]);
	for (i = 0; i < Size; i ++)
	{
		GetWeapFromLoadOut(Lo, i, Weap);
		ClearWeapon(Weap);
		SetWeapToLoadOut(Weap, Lo, i);
	}
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Get weapon from loadout
 *
 * @param Src			Load-out record
 * @param Dest			Destenation weapon record
 * @return				0 on error, 1 on success
 * @error				WeaponInfo index out of loadout bounds
 */
GetWeapFromLoadOut(Src[LoadoutInfo], Index, Dest[WeaponInfo])
{
	new Result = 0;
	Result = GetWeapFromArray(Src[LoWeap], Index, Dest);
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Set weapon to loadout
 *
 * @param Src			WeaponInfo info record to be put in loadout
 * @param Dest			Destenation loadout record
 * @return				0 on error, 1 on success
 * @error				WeaponInfo index out of loadout bounds
 */
SetWeapToLoadOut(Src[WeaponInfo], Dest[LoadoutInfo], Index)
{
	new Result = 0;
	Result = SetWeapToArray(Src, Dest[LoWeap], Index);
	Result = 1;
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Copy/duplicate loadout
 *
 * @param Src			Source loadout
 * @param Dest			Destenation loadout
 * @return				0 on error, 1 on success
 * @error				No
 */
CopyLoadout(Src[LoadoutInfo], Dest[LoadoutInfo])
{
	new Result = 0;
	Dest[LoID] = Src[LoID];
	Format(Dest[LoName], STR_LEN, "%s", Src[LoName]);
	Result = CopyWeapArray(Src[LoWeap], Dest[LoWeap]);
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Give loadout to client now
 *
 * @param Lo			Loadout info record to be given to the player
 * @param Client		Player unique identifier
 * @return				0 on error, 1 on success
 * @error				No
 */
GiveLoadout(Lo[LoadoutInfo], Client)
{
	new Result = 0;
	new i = 0;
	new Weap[WeaponInfo];
	new Size = GetArraySize(Lo[LoWeap]);
	if (Size == MAX_WEAP)
	{
		// Given weapon become active - give primary weapon last
		for (i = Size - 1; i >= 0 ; i --)
		{
			GetWeapFromLoadOut(Lo, i, Weap);
			GiveWeapon(Weap, Client);
		}
	}
	else
	{
		LogError("%s [%s]  Number of weapons in loadout is '%d', but must be '%d'", LOG_PREFIX, "GiveLoadout", Size, MAX_WEAP);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Processing loadouts array
//──────────────────────────────────────────────────────────────────────────────
/**
 * Create loadouts array
 *
 * @param LoArray		Loadouts array to be initialized
 * @noreturn
 * @error				No
 */
CreateLoadOutArray(&Handle: LoArray)
{
	new Temp[LoadoutInfo];
	if (LoArray != INVALID_HANDLE)
	{
		LogError("%s [%s] Loadouts array seems not clear, reinitializing - possible memory leak", LOG_PREFIX, "CreateLoadOutArray");
	}
	LoArray = CreateArray(sizeof(Temp));
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Destroy loadouts array
 *
 * @param LoArray		Loadouts array to be destroyed
 * @noreturn
 * @error				No
 */
DestroyLoadOutArray(&Handle: LoArray)
{
	ClearLoadOutArray(LoArray);
	LoArray = INVALID_HANDLE;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Clear loadout array
 *
 * @param LoArray		Loadouts array to be cleared
 * @noreturn
 * @error				No
 */
ClearLoadOutArray(&Handle: LoArray)
{
	new i = 0;
	new Temp[LoadoutInfo];
	new Size = GetArraySize(LoArray);
	while (i < Size)
	{
		GetLoadOutFromArray(LoArray, i, Temp);
		DestroyLoadOut(Temp);
		i ++;
	}	
	ClearArray(LoArray);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Get loadout from loadouts list
 *
 * @param Src			Dynamic array with requested loadout record
 * @param Index			Index of requsted loadout record in dynamic array
 * @param Dest			Destenation loadout record to save data
 * @return				0 on error, 1 on success
 * @error				Loadout index out of array bounds
 */
GetLoadOutFromArray(Handle: Src, Index, Dest[LoadoutInfo])
{
	new Result = 0;
	new Size = GetArraySize(Src);
	if ((Index >= 0) && (Index < Size))
	{
		GetArrayArray(Src, Index, Dest[0]);
		Result = 1;
	}
	else
	{
		LogError("%s [%s] Requested load-out index '%d' is out of array bounds '%d..%d'", LOG_PREFIX, "GetLoadOutFromArray", Index, 0, Size);
	}
	return Result;	
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Set loadout to loadouts list
 *
 * @param Src			Loadout info record that must be put in array
 * @param Dest			Destenation dynamic array to store loadout
 * @param Index			Index in dynamic array to place loadout info record
 * @return				0 on error, 1 on success
 * @error				Loadout index out of array bounds
 */
SetLoadOutToArray(Src[LoadoutInfo], &Handle: Dest, Index)
{
	new Result = 0;
	new Size = GetArraySize(Dest);
	if ((Index >= 0) && (Index < Size))
	{
		SetArrayArray(Dest, Index, Src[0]);
		Result = 1;
	}
	else
	{
		LogError("%s [%s] Requested load-out index '%d' is out of array bounds '%d..%d'", LOG_PREFIX, "SetLoadOutToArray", Index, 0, Size);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Append loadout to loadouts list
 *
 * @param Src			Loadout info record that must be put in array
 * @param Dest			Destenation dynamic array to store loadout
 * @return				1 on success, 0 if max loadout array length MAX_LOADOUT reached
 * @error				No
 */
AddLoadOutToArray(Src[LoadoutInfo], &Handle: Dest)
{
	new Result = 0;
	new Size = GetArraySize(Dest);
	if (Size < MAX_LOADOUT)
	{
		PushArrayArray(Dest, Src[0]);
		Result = 1;
	}
	else
	{
		LogError("%s [%s] Max loadouts array length '%d' reached", LOG_PREFIX, "AddLoadOutToArray", MAX_LOADOUT);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Remove loadout from loadouts list
 *
 * @param Src			Loadout info record
 * @param Index			Index in dynamic array to remove loadout info record
 * @return				1 on success, 0 if max loadout array length MAX_LOADOUT reached
 * @error				No
 */
RemLoadOutFromArray(&Handle: Src, Index)
{
	new Result = 0;
	new Size = GetArraySize(Src);
	new Lo[LoadoutInfo];
	if ((Index >= 0) && (Index < Size))
	{
		GetLoadOutFromArray(Src, Index, Lo);
		DestroyLoadOut(Lo);
		RemoveFromArray(Src, Index);
		Result = 1;
	}
	else
	{
		LogError("%s [%s] Requested load-out index '%d' is out of array bounds '%d..%d'", LOG_PREFIX, "RemLoadOutFromArray", Index, 0, Size);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Processing class info record
//──────────────────────────────────────────────────────────────────────────────
/**
 * Create class info record
 *
 * @param Cls			Class info record to be initialized
 * @noreturn
 * @error				No
 */
CreateClass(Cls[ClassInfo])
{
	InitCurWeap(Cls);
	CreateLoadOutArray(Cls[LoadOuts]);
	ClearLoadOutArray(Cls[LoadOuts]);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Create current weapon for class info record
 *
 * @param Cls			Class info record
 * @noreturn
 * @error				No
 */
InitCurWeap(Cls[ClassInfo])
{
	CreateLoadOutArray(Cls[CurWeap]);
	ClearLoadOutArray(Cls[CurWeap]);
	new Lo[LoadoutInfo];
	CreateLoadOut(Lo);
	AddLoadOutToArray(Lo, Cls[CurWeap]);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Destroy class info record
 *
 * @param Cls			Class info record to be destroyed
 * @noreturn
 * @error				No
 */
DestroyClass(Cls[ClassInfo])
{
	DestroyLoadOutArray(Cls[CurWeap]);
	DestroyLoadOutArray(Cls[LoadOuts]);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Clear current weapon for class
 *
 * @param Cls			Class info record
 * @noreturn
 * @error				No
 */
ClearCurWeap(Cls[ClassInfo])
{
	new Lo[LoadoutInfo];
	GetLoadOutFromArray(Cls[CurWeap], 0, Lo);
	ClearLoadOut(Lo);
	SetLoadOutToArray(Lo, Cls[CurWeap], 0);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Clear class info record
 *
 * @param Cls			Class info record to be cleared
 * @noreturn
 * @error				No
 */
ClearClass(Cls[ClassInfo])
{
	ClearCurWeap(Cls);
	ClearLoadOutArray(Cls[LoadOuts]);
}
//──────────────────────────────────────────────────────────────────────────────
// Processing classes array
//──────────────────────────────────────────────────────────────────────────────
/**
 * Create classes array
 *
 * @param ClsArray		Classes array to be initialized
 * @noreturn
 * @error				No
 */
CreateClassArray(&Handle: ClsArray)
{
	new Temp[ClassInfo];
	if (ClsArray != INVALID_HANDLE)
	{
		LogError("%s [%s] Classes array seems not clear, reinitializing - possible memory leak", LOG_PREFIX, "CreateClassArray");
	}
	ClsArray = CreateArray(sizeof(Temp));
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Destroy classes array
 *
 * @param ClsArray		Classes array to be destroyed
 * @noreturn
 * @error				No
 */
DestroyClassArray(&Handle: ClsArray)
{
	ClearClassArray(ClsArray);
	ClsArray = INVALID_HANDLE;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Clear classes array
 *
 * @param ClsArray		Classes array to be cleared
 * @noreturn
 * @error				No
 */
ClearClassArray(&Handle: ClsArray)
{
	new i = 0;
	new Temp[ClassInfo];
	new Size = GetArraySize(ClsArray);
	while (i < Size)
	{
		GetClassFromArray(ClsArray, i, Temp);
		DestroyClass(Temp);
		i ++;
	}	
	ClearArray(ClsArray);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Get class from classes list
 *
 * @param Src			Dynamic array with requested class record
 * @param Index			Index of requsted class record in dynamic array
 * @param Dest			Destenation class record to save data
 * @return				0 on error, 1 on success
 * @error				Class index out of array bounds
 */
GetClassFromArray(Handle: Src, Index, Dest[ClassInfo])
{
	new Result = 0;
	new Size = GetArraySize(Src);
	if ((Index >= 0) && (Index < Size))
	{
		GetArrayArray(Src, Index, Dest[0]);
		Result = 1;
	}
	else
	{
		LogError("%s [%s] Requested load-out index '%d' is out of array bounds '%d..%d'", LOG_PREFIX, "GetClassFromArray", Index, 0, Size);
	}
	return Result;	
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Set class to classes list
 *
 * @param Src			Class info record that must be put in array
 * @param Dest			Destenation dynamic array to store class
 * @param Index			Index in dynamic array to place class info record
 * @return				0 on error, 1 on success
 * @error				Class index out of array bounds
 */
SetClassToArray(Src[ClassInfo], &Handle: Dest, Index)
{
	new Result = 0;
	new Size = GetArraySize(Dest);
	if ((Index >= 0) && (Index < Size))
	{
		SetArrayArray(Dest, Index, Src[0]);
		Result = 1;
	}
	else
	{
		LogError("%s [%s] Requested load-out index '%d' is out of array bounds '%d..%d'", LOG_PREFIX, "SetClassToArray", Index, 0, Size);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Append class to classes list
 *
 * @param Src			Class info record that must be put in array
 * @param Dest			Destenation dynamic array to store class
 * @return				1 on success, 0 if max classes array length MAX_CLASS reached
 * @error				No
 */
AddClassToArray(Src[ClassInfo], &Handle: Dest)
{
	new Result = 0;
	new Size = GetArraySize(Dest);
	if (Size < MAX_CLASS)
	{
		PushArrayArray(Dest, Src[0]);
		Result = 1;
	}
	else
	{
		LogError("%s [%s] Max classes array length '%d' reached", LOG_PREFIX, "AddClassToArray", MAX_CLASS);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Processing player info record
//──────────────────────────────────────────────────────────────────────────────
/**
 * Create player info record
 *
 * @param Plr			Player info record to be initialized
 * @noreturn
 * @error				No
 */
CreatePlayerData(Plr[PlayerData])
{
	// Init menu sequence array
	new VarMenu[Menu];
	Plr[MenuSeq] = CreateArray(sizeof(VarMenu));	
	// Init classes array with MAX_CLASS classes
	InitClasses(Plr);
	// Init string buffer
	Format(Plr[StrBufLOName], STR_LEN, "");
	Plr[PlrEnabled] = 0;
	//Plr[PlrID] = -1;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Create classes array for player info record
 *
 * @param Plr			Player info record
 * @noreturn
 * @error				No
 */
InitClasses(Plr[PlayerData])
{
	CreateClassArray(Plr[Classes]);
	
	new VarClass[ClassInfo];
	new i = 0;
	
	for (i = 0; i < MAX_CLASS; i ++)
	{
		CreateClass(VarClass);
		AddClassToArray(VarClass, Plr[Classes]);
	}
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Destroy player info record
 *
 * @param Plr			Player info record to be destroyed
 * @noreturn
 * @error				No
 */
DestroyPlayerData(Plr[PlayerData])
{
	ClearMenuSeq(Plr);
	DestroyClassArray(Plr[Classes]);
	Format(Plr[StrBufLOName], STR_LEN, "");
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Clear menu sequence for player
 *
 * @param Plr			Player info record
 * @noreturn
 * @error				No
 */
ClearMenuSeq(Plr[PlayerData])
{
	ClearArray(Plr[MenuSeq]);
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Clear classes for player
 *
 * @param Plr			Player info record
 * @noreturn
 * @error				No
 */
ClearClasses(Plr[PlayerData])
{
	new VarClass[ClassInfo];
	new i = 0;
	
	for (i = 0; i < MAX_CLASS; i ++)
	{
		GetClassFromArray(Plr[Classes], i, VarClass);
		ClearClass(VarClass);
		SetClassToArray(VarClass, Plr[Classes], i);
	}
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Clear player info record
 *
 * @param Plr			Player info record to be cleared
 * @noreturn
 * @error				No
 */
ClearPlayerData(Plr[PlayerData])
{
	ClearMenuSeq(Plr);
	ClearClasses(Plr);
	Plr[PlrEnabled] = 0;
	// Plr[PlrID] = -1;
	Format(Plr[StrBufLOName], STR_LEN, "");
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Give player current weapon
 *
 * @param Plr			Player info record
 * @return				0 on error, 1 on success
 * @error				No
 */
GivePlayerCurWeapon(Plr[PlayerData])
{
	new Result = 0;
	new Cls[ClassInfo];
	new Lo[LoadoutInfo];
	if (Plr[PlrEnabled] && IsValidClient(Plr[PlrID]) && IsPlayerAlive(Plr[PlrID]))
	{
		if (GetClassFromArray(Plr[Classes], _: TF2_GetPlayerClass(Plr[PlrID]) - 1, Cls))
		{
			if (GetLoadOutFromArray(Cls[CurWeap], 0, Lo))
			{
				Result = GiveLoadout(Lo, Plr[PlrID]);
			}
		}
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Give player weapon by its ID
 *
 * @param Plr			Player info record
 * @param WeapIndex		Requested weapon ID
 * @param ClassIndex	Class to check, use -1 to skip
 * @param SlotIndex		Slot to check, use -1 to skip
 * @return				0 on error, 1 on success
 * @error				No
 */
TryGivePlayerWeaponID(Plr[PlayerData], WeapIndex, ClassIndex, SlotIndex)
{
	new Result = 0;
	new ErrCode = ERR_NONE;
	new Cls[ClassInfo];
	new Lo[LoadoutInfo];
	new Weap[WeaponInfo];
	//PrintToChat(Plr[PlrID], "%s Trying to give weapon %d, player class is %d", CHAT_PREFIX, WeapIndex, ClassIndex);
	if (WeapIndex >= 0)
	{
		if (FindWeapon(WeapIndex, Weap, ClassIndex) >= 0)
		{
			ErrCode = CheckWeapon(Weap, Plr[PlrID], ClassIndex, SlotIndex);
			if (ErrCode == ERR_NONE)
			{
				GetClassFromArray(Plr[Classes], ClassIndex - 1, Cls);
				GetLoadOutFromArray(Cls[CurWeap], 0, Lo);
				SetWeapToLoadOut(Weap, Lo, SlotIndex);
				SetLoadOutToArray(Lo, Cls[CurWeap], 0);
				SetClassToArray(Cls, Plr[Classes], ClassIndex - 1);
				if (Instant)
				{
					Result = GivePlayerCurWeapon(Plr);
				}
				else
				{
					PrintCenterText(Plr[PlrID], "Touch locker to apply changes");
					Result = 1;
				}
			}
			else
			{
				ReportWeapError(Plr[PlrID], ErrCode, Weap, ClassIndex, SlotIndex);
			}
		}
		else
		{
			PrintToChat(Plr[PlrID], "%s WeaponInfo (%d) seems to be not available on this server or it's for another class", CHAT_PREFIX, WeapIndex);
			LogAction(-1, -1, "%s Player '%L' request weapon '%d' which seem to be not present in config file", LOG_PREFIX, Plr[PlrID], WeapIndex);
		}
	}
	else
	{
		GetClassFromArray(Plr[Classes], ClassIndex - 1, Cls);
		GetLoadOutFromArray(Cls[CurWeap], 0, Lo);
		CreateWeapon(Weap);
		SetWeapToLoadOut(Weap, Lo, SlotIndex);
		SetLoadOutToArray(Lo, Cls[CurWeap], 0);
		SetClassToArray(Cls, Plr[Classes], ClassIndex - 1);
		if (Instant)
		{
			ResetPlayerWeapon(Plr);
		}
		else
		{
			PrintCenterText(Plr[PlrID], "Touch locker to apply changes");
		}
		Result = 1;
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Give player loadout for current class
 *
 * @param Plr			Player info record
 * @param ClassIndex	Class index to check if player requested loadout for his current class
 * @param LoIndex		Loadout index in array stored in class info record
 * @return				0 on error, 1 on success
 * @error				No
 */
TryGivePlayerLoadout(Plr[PlayerData], ClassIndex, LoIndex)
{
	new Result = 0;
	new Lo[LoadoutInfo];
	new Lo2[LoadoutInfo];
	new Cls[ClassInfo];
	new CurClassIndex = 0;
	new String: StrBuf[STR_LEN];
	new String: StrBuf2[STR_LEN];
	if (IsPlayerAlive(Plr[PlrID]))
	{
		if (Plr[PlrEnabled])
		{
			CurClassIndex = _: TF2_GetPlayerClass(Plr[PlrID]);
			// Check if current player class is same as one from which player requested loadout
			if (CurClassIndex == ClassIndex)
			{
				// Loading class to temporary variable
				// ClassIndex is in range 1..9, but array index is in range 0..8, so -1
				GetClassFromArray(Plr[Classes], ClassIndex - 1, Cls);
				// Get loadout index in array
				// Check array size
				if (LoIndex >= 0 && LoIndex < GetArraySize(Cls[LoadOuts]))
				{
					GetLoadOutFromArray(Cls[LoadOuts], LoIndex, Lo);
					GetLoadOutFromArray(Cls[CurWeap], 0, Lo2);
					CopyLoadout(Lo, Lo2);	// avoid problems - use special function to duplicate loadout
					SetLoadOutToArray(Lo2, Cls[CurWeap], 0);
					SetClassToArray(Cls, Plr[Classes], ClassIndex - 1);
					if (Instant)
					{
						ResetPlayerWeapon(Plr);
					}
					else
					{
						PrintCenterText(Plr[PlrID], "Touch locker to apply changes");
					}
					Result = 1;
				}
				else
				{
					PrintToChat(Plr[PlrID], "%s Wrong loadout index", CHAT_PREFIX);
				}
			}
			else
			{
				Int2Class(ClassIndex, StrBuf, STR_LEN);
				Int2Class(CurClassIndex, StrBuf2, STR_LEN);
				PrintToChat(Plr[PlrID], "%s You requested loadout %d from class %s, but your current class is %s - can't do that", CHAT_PREFIX, LoIndex, StrBuf, StrBuf2);
			}
		}
		else
		{
			PrintToChat(Plr[PlrID], "%s Load-Out Manager disabled for You", CHAT_PREFIX);
		}
	}
	else
	{
		PrintToChat(Plr[PlrID], "%s You must be alive", CHAT_PREFIX);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Save player loadout for current class
 *
 * @param Plr			Player info record
 * @param ClassIndex	Class index to check if player requested loadout for his current class
 * @param LoIndex		Loadout index in array stored in class info record, use -1 to append as new
 * @return				0 on error, 1 on success
 * @error				No
 */
TrySavePlayerLoadout(Plr[PlayerData], ClassIndex, LoIndex = -1)
{
	new Result = 0;
	new Lo[LoadoutInfo];
	new Lo2[LoadoutInfo];
	new Cls[ClassInfo];
	new CurClassIndex = 0;
	new String: StrBuf[STR_LEN];
	new String: StrBuf2[STR_LEN];
	if (IsPlayerAlive(Plr[PlrID]))
	{
		if (Plr[PlrEnabled])
		{
			CurClassIndex = _: TF2_GetPlayerClass(Plr[PlrID]);
			// Check if current player class is same as one from which player requested loadout
			if (CurClassIndex == ClassIndex)
			{
				// Loading class to temporary variable
				// ClassIndex is in range 1..9, but array index is in range 0..8, so -1
				GetClassFromArray(Plr[Classes], ClassIndex - 1, Cls);
				// Get loadout index in array
				// Check array size
				if (LoIndex >= 0 && LoIndex < GetArraySize(Cls[LoadOuts]))	// replace some loadout
				{
					GetLoadOutFromArray(Cls[CurWeap], 0, Lo);
					GetLoadOutFromArray(Cls[LoadOuts], LoIndex, Lo2);
					CopyLoadout(Lo, Lo2);	// avoid problems - use special function to duplicate loadout
					// Check if player want name loadout - use that name and then clear it
					if (strlen(Plr[StrBufLOName]) > 0)
					{
						Format(Lo2[LoName], STR_LEN, "%s", Plr[StrBufLOName]);
						Format(Plr[StrBufLOName], STR_LEN, "");
					}
					SetLoadOutToArray(Lo2, Cls[LoadOuts], LoIndex);
					SetClassToArray(Cls, Plr[Classes], ClassIndex - 1);
				}
				else if (LoIndex == -1)	// add as new at the end
				{
					GetLoadOutFromArray(Cls[CurWeap], 0, Lo);
					CreateLoadOut(Lo2);
					CopyLoadout(Lo, Lo2);	// avoid problems - use special function to duplicate loadout
					// Check if player want name loadout - use that name and then clear it
					if (strlen(Plr[StrBufLOName]) > 0)
					{
						Format(Lo2[LoName], STR_LEN, "%s", Plr[StrBufLOName]);
						Format(Plr[StrBufLOName], STR_LEN, "");
					}
					AddLoadOutToArray(Lo2, Cls[LoadOuts]);
					SetClassToArray(Cls, Plr[Classes], ClassIndex - 1);
				}
				else
				{
					PrintToChat(Plr[PlrID], "%s Wrong loadout index", CHAT_PREFIX);
				}
			}
			else
			{
				Int2Class(ClassIndex, StrBuf, STR_LEN);
				Int2Class(CurClassIndex, StrBuf2, STR_LEN);
				PrintToChat(Plr[PlrID], "%s You requested to save current loadout from class %s, but your current class is %s - can't do that", CHAT_PREFIX, StrBuf, StrBuf2);
			}
		}
		else
		{
			PrintToChat(Plr[PlrID], "%s Load-Out Manager disabled for You", CHAT_PREFIX);
		}
	}
	else
	{
		PrintToChat(Plr[PlrID], "%s You must be alive", CHAT_PREFIX);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Remove player loadout for current class
 *
 * @param Plr			Player info record
 * @param ClassIndex	Class index to check if player requested loadout for his current class
 * @param LoIndex		Loadout index in array stored in class info record
 * @return				0 on error, 1 on success
 * @error				No
 */
TryRemovePlayerLoadout(Plr[PlayerData], ClassIndex, LoIndex)
{
	new Result = 0;
	new Cls[ClassInfo];
	new CurClassIndex = 0;
	new String: StrBuf[STR_LEN];
	new String: StrBuf2[STR_LEN];
	if (IsPlayerAlive(Plr[PlrID]))
	{
		if (Plr[PlrEnabled])
		{
			CurClassIndex = _: TF2_GetPlayerClass(Plr[PlrID]);
			// Check if current player class is same as one from which player requested loadout
			if (CurClassIndex == ClassIndex)
			{
				// Loading class to temporary variable
				// ClassIndex is in range 1..9, but array index is in range 0..8, so -1
				GetClassFromArray(Plr[Classes], ClassIndex - 1, Cls);
				// Get loadout index in array
				// Check array size
				if (LoIndex >= 0 && LoIndex < GetArraySize(Cls[LoadOuts]))	// replace some loadout
				{
					RemLoadOutFromArray(Cls[LoadOuts], LoIndex);
					SetClassToArray(Cls, Plr[Classes], ClassIndex - 1);
				}
				else
				{
					PrintToChat(Plr[PlrID], "%s Wrong loadout index", CHAT_PREFIX);
				}
			}
			else
			{
				Int2Class(ClassIndex, StrBuf, STR_LEN);
				Int2Class(CurClassIndex, StrBuf2, STR_LEN);
				PrintToChat(Plr[PlrID], "%s You requested to remove loadout %d from class %s, but your current class is %s - can't do that", CHAT_PREFIX, LoIndex, StrBuf, StrBuf2);
			}
		}
		else
		{
			PrintToChat(Plr[PlrID], "%s Load-Out Manager disabled for You", CHAT_PREFIX);
		}
	}
	else
	{
		PrintToChat(Plr[PlrID], "%s You must be alive", CHAT_PREFIX);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Reset player weapon
 * Set PlrEnabled to 0 before call this routine, because player will get weapon again
 *
 * @param Plr			Player info record
 * @return				0 on error, 1 on success
 * @error				No
 */
ResetPlayerWeapon(Plr[PlayerData])
{
	new Result = 0;
	if (IsValidClient(Plr[PlrID]))
	{
		if (IsPlayerAlive(Plr[PlrID]))
		{
			// TODO: Restore player health after this call
			TF2_RegeneratePlayer(Plr[PlrID]);
			Result = 1;
		}
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Processing static PlayerData array
//──────────────────────────────────────────────────────────────────────────────
/**
 * Initialize data for all players
 * Call it once per plug-in working time
 *
 * @noreturn
 * @error				No
 */
InitPlayersData()
{
	for (new Client = 0; Client < MAXPLAYERS+1; Client ++)
	{
		CreatePlayerData(Players[Client]);
	}
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Free data for all players
 * Call it once per plug-in working time
 *
 * @noreturn
 * @error				No
 */
FreePlayersData()
{
	for (new Client = 0; Client < MAXPLAYERS+1; Client ++)
	{
		DestroyPlayerData(Players[Client]);
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Other
//──────────────────────────────────────────────────────────────────────────────
/**
 * Get weapon index in weapon list by it's identifier and save to WeapData variable
 *
 * @param WeapID		Unique weapon identifier
 * @param Weap			WeaponInfo info record to store founded weapon
 * @param ClassIndex	Player class. Required because of BASE Jumper weapon, which is for different classes and slots
 * @return				-1 if not found, >= 0 - index of founded weapon in list
 * @error				No
 */
FindWeapon(WeapID, Weap[WeaponInfo], ClassIndex)
{
	new Result = -1;
	new Size = GetArraySize(Weapons);
	new WeapData[WeaponInfo];
	new Index = -1;
	new bool: Finded = false;
	new ClassMask = 1 << (_: ClassIndex);	
	Index = 0;
	Finded = false;
	while ((! Finded) && (Index < Size))
	{
		GetArrayArray(Weapons, Index, WeapData[0]);
		if ((WeapData[Class] & ClassMask > 0) && (WeapData[ID] == WeapID))
		{
			Finded = true;
			Result = Index;
			Weap = WeapData;
		}
		Index ++;
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
/**
 * Read config files to Weapons list
 *
 * @noreturn
 * @error				No
 */
ReloadWeaponList()
{
	new Handle: KeyValues = INVALID_HANDLE;
	
	new String: ConfigFile[STR_LEN];
	new String: Section[STR_LEN];	// Section name
	new String: SubSection[STR_LEN];	// Sub-section name
	new Data[WeaponInfo];
	new Index;
	
	// Clear all data from weapons list array in memory
	ClearArray(Weapons);
	
	Index = 0;
	// We have few config files to read
	for (new i = 0; i < CFG_COUNT; i ++)
	{
		if (Configs[i][Enabled])
		{
			// Get config file full path
			BuildPath(Path_SM, ConfigFile, sizeof(ConfigFile), Configs[i][Path]);
			// Checking for file to exist appears to be useless since FileToKeyValues also do it
			if (FileExists(ConfigFile))
			{
				// Read config file to memory to parse it
				KeyValues = CreateKeyValues(CFG_WEAPONS_NAME);
				LogAction(-1, -1, "%s Begin reading config file '%s'", LOG_PREFIX, ConfigFile);
				if (FileToKeyValues(KeyValues, ConfigFile) == true)
				{
					// Check section name
					KvGetSectionName(KeyValues, Section, sizeof(Section));
					if (StrEqual(Configs[i][WeapSecName], Section) == true)
					{
						// Go to first sub-key
						if (KvGotoFirstSubKey(KeyValues))
						{
							LogAction(-1, -1, "%s Reading weapon list", LOG_PREFIX);
							// Go trough all next sub-keys
							do
							{
								KvGetSectionName(KeyValues, SubSection, sizeof(SubSection));
								if (SubSection[0] != '*')
								{
									// Get individual weapon settings
									Data[ID] = StringToInt(SubSection);
									if (Data[ID] > 0)
									{
										Data[ParentID] = KvGetNum(KeyValues, "Index", -1);	// get parent weapon ID - only for custom weapons
										Data[Class] = KvGetNum(KeyValues, "Class", 1023);
										Data[Slot] = KvGetNum(KeyValues, "Slot", 0);
										Data[GameMode] = KvGetNum(KeyValues, "GameMode", 1023);
										Data[Apocalyptic] = KvGetNum(KeyValues, "Apocalyptic", 0);
										Data[ArrayIndex] = Index;	// save current array index
										KvGetString(KeyValues, "Name", Data[Name], STR_LEN);
										KvGetString(KeyValues, "Access", Data[Access], STR_LEN);
										
										LogAction(-1, -1, "%s WeaponInfo '%s' (%d) added", LOG_PREFIX, Data[Name], Data[ID]);
										
										// Push retrieved data to weapons array in memory
										// https://forums.alliedmods.net/showpost.php?p=1063696&postcount=3
										PushArrayArray(Weapons, Data[0]);
										
										Index ++;
									}
								}
							}
							while (KvGotoNextKey(KeyValues));
							KvGoBack(KeyValues);
						}
					}
				}
				else
				{
					LogAction(-1, -1, "%s Failed to read existing config file '%s'", LOG_PREFIX, ConfigFile);
				}
				CloseHandle(KeyValues);
				LogAction(-1, -1, "%s Done reading config file '%s'", LOG_PREFIX, ConfigFile);
			}
			else
			{
				LogAction(-1, -1, "%s Config file '%s' does not exist", LOG_PREFIX, ConfigFile);
			}
		}
		else
		{
			LogAction(-1, -1, "%s Config file '%s' is disabled by console variable '%s'", LOG_PREFIX, Configs[i][Path], Configs[i][sEnabled]);
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────







//──────────────────────────────────────────────────────────────────────────────
// Stocks
//──────────────────────────────────────────────────────────────────────────────
// Init list of config files used
InitConfigList()
{
	new i = 0;
	
	Format(Configs[i][Path], STR_LEN, "%s", CFG_WEAPONS_FILENAME);
	Format(Configs[i][WeapSecName], STR_LEN, "%s", CFG_WEAPONS_SECTION_LIST);
	Format(Configs[i][sEnabled], STR_LEN, "%s", CVAR_WEAPONS);
	Configs[i][Enabled] = 1;
	Configs[i][hEnabled] = INVALID_HANDLE;
	i ++;
	
	Format(Configs[i][Path], STR_LEN, "%s", CFG_GIVECUSTOM_FILENAME);
	Format(Configs[i][WeapSecName], STR_LEN, "%s", CFG_GIVECUSTOM_SECTION_LIST);
	Format(Configs[i][sEnabled], STR_LEN, "%s", CVAR_GIVECUSTOM);
	Configs[i][Enabled] = 1;
	Configs[i][hEnabled] = INVALID_HANDLE;
	i ++;
}
//──────────────────────────────────────────────────────────────────────────────
stock bool:IsMvM()
{
	new bool:ismvm = bool:GameRules_GetProp("m_bPlayingMannVsMachine");
	return ismvm;
}
//──────────────────────────────────────────────────────────────────────────────
// Convert slot name to slot index
Slot2Int(String: StrName[])
{
	new Result = -1;
	if (StrEqual(StrName, ITEM_SLOT_PRIMARY))
	{
		Result = 0;
	}
	else if (StrEqual(StrName, ITEM_SLOT_SECOND))
	{
		Result = 1;
	}
	else if (StrEqual(StrName, ITEM_SLOT_MELEE))
	{
		Result = 2;
	}
	else if (StrEqual(StrName, ITEM_SLOT_PDA1))
	{
		Result = 3;
	}
	else if (StrEqual(StrName, ITEM_SLOT_PDA2))
	{
		Result = 4;
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Convert slot index to slot name
Int2Slot(SlotIndex, String: StrName[], MaxLength)
{
	new Result = -1;
	if (SlotIndex == 0)
	{
		Format(StrName, MaxLength, "%s", ITEM_SLOT_PRIMARY);
	}
	else if (SlotIndex == 1)
	{
		Format(StrName, MaxLength, "%s", ITEM_SLOT_SECOND);
	}
	else if (SlotIndex == 2)
	{
		Format(StrName, MaxLength, "%s", ITEM_SLOT_MELEE);
	}
	else if (SlotIndex == 3)
	{
		Format(StrName, MaxLength, "%s", ITEM_SLOT_PDA1);
	}
	else if (SlotIndex == 4)
	{
		Format(StrName, MaxLength, "%s", ITEM_SLOT_PDA2);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Convert class name to class index
Class2Int(String: StrName[])
{
	new Result = -1;
	if (StrEqual(StrName, ITEM_CLASS_UNKNOWN))
	{
		Result = _: TFClass_Unknown;
	}
	else if (StrEqual(StrName, ITEM_CLASS_SCOUT))
	{
		Result = _: TFClass_Scout;
	}
	else if (StrEqual(StrName, ITEM_CLASS_SOLDIER))
	{
		Result = _: TFClass_Soldier;
	}
	else if (StrEqual(StrName, ITEM_CLASS_PYRO))
	{
		Result = _: TFClass_Pyro;
	}
	else if (StrEqual(StrName, ITEM_CLASS_DEMO))
	{
		Result = _: TFClass_DemoMan;
	}
	else if (StrEqual(StrName, ITEM_CLASS_HEAVY))
	{
		Result = _: TFClass_Heavy;
	}
	else if (StrEqual(StrName, ITEM_CLASS_ENGI))
	{
		Result = _: TFClass_Engineer;
	}
	else if (StrEqual(StrName, ITEM_CLASS_MEDIC))
	{
		Result = _: TFClass_Medic;
	}
	else if (StrEqual(StrName, ITEM_CLASS_SNIPER))
	{
		Result = _: TFClass_Sniper;
	}
	else if (StrEqual(StrName, ITEM_CLASS_SPY))
	{
		Result = _: TFClass_Spy;
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Convert class index to class name
Int2Class(ClassIndex, String: StrName[], MaxLength)
{
	new Result = -1;
	if (ClassIndex == _: TFClass_Unknown)
	{
		Format(StrName, MaxLength, "%s", ITEM_CLASS_UNKNOWN);
	}
	else if (ClassIndex == _: TFClass_Scout)
	{
		Format(StrName, MaxLength, "%s", ITEM_CLASS_SCOUT);
	}
	else if (ClassIndex == _: TFClass_Soldier)
	{
		Format(StrName, MaxLength, "%s", ITEM_CLASS_SOLDIER);
	}
	else if (ClassIndex == _: TFClass_Pyro)
	{
		Format(StrName, MaxLength, "%s", ITEM_CLASS_PYRO);
	}
	else if (ClassIndex == _: TFClass_DemoMan)
	{
		Format(StrName, MaxLength, "%s", ITEM_CLASS_DEMO);
	}
	else if (ClassIndex == _: TFClass_Heavy)
	{
		Format(StrName, MaxLength, "%s", ITEM_CLASS_HEAVY);
	}
	else if (ClassIndex == _: TFClass_Engineer)
	{
		Format(StrName, MaxLength, "%s", ITEM_CLASS_ENGI);
	}
	else if (ClassIndex == _: TFClass_Medic)
	{
		Format(StrName, MaxLength, "%s", ITEM_CLASS_MEDIC);
	}
	else if (ClassIndex == _: TFClass_Sniper)
	{
		Format(StrName, MaxLength, "%s", ITEM_CLASS_SNIPER);
	}
	else if (ClassIndex == _: TFClass_Spy)
	{
		Format(StrName, MaxLength, "%s", ITEM_CLASS_SPY);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Menu
//──────────────────────────────────────────────────────────────────────────────
// Menu sequence analyzer
MenuLogic(Client)
{
	new MenuData[Menu];
	new Size = GetArraySize(Players[Client][MenuSeq]);
	new Level = 0;
	new SlotIndex = -1;
	new WeapIndex = -1;
	new LoIndex = -1;
	
	if (Size < MAX_MENU_LEVEL)
	{
		LogAction(-1, -1, "%s Player '%L' sub-menu level is %d", LOG_PREFIX, Client, Size);
	}
	else
	{
		LogAction(-1, -1, "%s Player '%L' sub-menu max level reached %d - ignore further operations", LOG_PREFIX, Client, Size);
		return;
	}
	
	if (Level < Size)
	{
		GetArrayArray(Players[Client][MenuSeq], Level, MenuData[0]);
		Level ++;
		if (StrEqual(MenuData[ID], MENU_MAIN))
		{
			if (Level < Size)
			{
				GetArrayArray(Players[Client][MenuSeq], Level, MenuData[0]);
				Level ++;
				if (StrEqual(MenuData[ID], MENU_SLOT))
				{
					if (Level < Size)
					{
						GetArrayArray(Players[Client][MenuSeq], Level, MenuData[0]);
						Level ++;
						if (StrEqual(MenuData[ID], MENU_WEAP))
						{
							if (Level < Size)
							{
					
							}
							else
							{
								if (StrEqual(MenuData[Return], ITEM_BASIC_BACK))
								{
									RemoveFromArray(Players[Client][MenuSeq], Level - 1);
									RemoveFromArray(Players[Client][MenuSeq], Level - 2);
									ShowSlotMenu(Client);
								}
								else	// Player selected weapon he want to get right now - save it as current and give it to him
								{
									WeapIndex = StringToInt(MenuData[Return]);	// get weapon index as integer from string
									GetArrayArray(Players[Client][MenuSeq], Level - 2, MenuData[0]);	// get slot number from top menu level
									SlotIndex = Slot2Int(MenuData[Return]);	// get slot number
									TryGivePlayerWeaponID(Players[Client], WeapIndex, _: TF2_GetPlayerClass(Client), SlotIndex);
									// Come back to slot menu
									RemoveFromArray(Players[Client][MenuSeq], Level - 1);
									RemoveFromArray(Players[Client][MenuSeq], Level - 2);
									ShowSlotMenu(Client);
								}
							}
						}
					}
					else
					{
						if (StrEqual(MenuData[Return], ITEM_BASIC_BACK))
						{
							RemoveFromArray(Players[Client][MenuSeq], Level - 1);
							RemoveFromArray(Players[Client][MenuSeq], Level - 2);
							ShowMainMenu(Client);
						}
						else
						{
							SlotIndex = Slot2Int(MenuData[Return]);
							if (SlotIndex >= 0)
							{
								ShowWeapMenu(Client, _: TF2_GetPlayerClass(Client), SlotIndex);
							}
						}
					}
				}
				else if (StrEqual(MenuData[ID], MENU_LOAD) || StrEqual(MenuData[ID], MENU_INFO))
				{
					if (Level < Size)
					{
						
					}
					else
					{
						if (StrEqual(MenuData[Return], ITEM_BASIC_BACK))
						{
							RemoveFromArray(Players[Client][MenuSeq], Level - 1);
							RemoveFromArray(Players[Client][MenuSeq], Level - 2);
							ShowMainMenu(Client);
						}
						else
						{
							LoIndex = StringToInt(MenuData[Return]);	// get loadout index to replace it
							GetArrayArray(Players[Client][MenuSeq], Level - 2, MenuData[0]);	// get player class
								//	when he opened this menu and compare with his current class
								//	to prevent problems when player open menu for one class and then changed it before load loadout
							TryGivePlayerLoadout(Players[Client], MenuData[MenuPlrClass], LoIndex);
							RemoveFromArray(Players[Client][MenuSeq], Level - 1);
							RemoveFromArray(Players[Client][MenuSeq], Level - 2);
							ShowMainMenu(Client);
						}
					}
				}
				else if (StrEqual(MenuData[ID], MENU_SAVE))
				{
					if (Level < Size)
					{
						
					}
					else
					{
						if (StrEqual(MenuData[Return], ITEM_BASIC_BACK))
						{
							RemoveFromArray(Players[Client][MenuSeq], Level - 1);
							RemoveFromArray(Players[Client][MenuSeq], Level - 2);
							ShowMainMenu(Client);
						}
						else
						{
							if (StrEqual(MenuData[Return], ITEM_SAVE_NEW))
							{
								LoIndex = -1;	// it's mean - save as new
							}
							else
							{
								LoIndex = StringToInt(MenuData[Return]);	// get loadout index to replace it
							}
							GetArrayArray(Players[Client][MenuSeq], Level - 2, MenuData[0]);	// get player class
							//	when he opened this menu and compare with his current class
							//	to prevent problems when player open menu for one class and then changed it before load loadout
							TrySavePlayerLoadout(Players[Client], MenuData[MenuPlrClass], LoIndex);
							RemoveFromArray(Players[Client][MenuSeq], Level - 1);
							RemoveFromArray(Players[Client][MenuSeq], Level - 2);
							ShowMainMenu(Client);
						}
					}
				}
				else if (StrEqual(MenuData[ID], MENU_REM))
				{
					if (Level < Size)
					{
						
					}
					else
					{
						if (StrEqual(MenuData[Return], ITEM_BASIC_BACK))
						{
							RemoveFromArray(Players[Client][MenuSeq], Level - 1);
							RemoveFromArray(Players[Client][MenuSeq], Level - 2);
							ShowMainMenu(Client);
						}
						else
						{
							LoIndex = StringToInt(MenuData[Return]);	// get loadout index to replace it
							GetArrayArray(Players[Client][MenuSeq], Level - 2, MenuData[0]);	// get player class
							//	when he opened this menu and compare with his current class
							//	to prevent problems when player open menu for one class and then changed it before load loadout
							TryRemovePlayerLoadout(Players[Client], MenuData[MenuPlrClass], LoIndex);
							RemoveFromArray(Players[Client][MenuSeq], Level - 1);
							RemoveFromArray(Players[Client][MenuSeq], Level - 2);
							ShowMainMenu(Client);
						}
					}
				}
				else if (StrEqual(MenuData[ID], MENU_HELP))
				{
					if (Level < Size)
					{

					}
					else
					{
						if (StrEqual(MenuData[Return], ITEM_BASIC_BACK))
						{
							RemoveFromArray(Players[Client][MenuSeq], Level - 1);
							RemoveFromArray(Players[Client][MenuSeq], Level - 2);
							ShowMainMenu(Client);
						}
					}
				}
			}
			else	// Main menu level
			{
				// Player want weapon now - show slot selection first
				if (StrEqual(MenuData[Return], ITEM_MAIN_GIVE))
				{
					ShowSlotMenu(Client);
				}
				// Player want to load some loadout
				else if (StrEqual(MenuData[Return], ITEM_MAIN_LOAD))
				{
					ShowLoadoutLoadMenu(Client);
				}
				// Player want to browse some loadout
				else if (StrEqual(MenuData[Return], ITEM_MAIN_INFO))
				{
					ShowLoadoutInfoMenu(Client);
				}
				// Player want to save current loadout
				else if (StrEqual(MenuData[Return], ITEM_MAIN_SAVE))
				{
					ShowLoadoutSaveMenu(Client);
				}
				// Player want to remove some loadout
				else if (StrEqual(MenuData[Return], ITEM_MAIN_REM))
				{
					ShowLoadoutRemoveMenu(Client);
				}
				// Player want see help
				else if (StrEqual(MenuData[Return], ITEM_MAIN_HELP))
				{
					ShowHelpMenu(Client);
				}
				// Player want enable mod for himself
				else if (StrEqual(MenuData[Return], ITEM_MAIN_ENABLE))
				{
					Players[Client][PlrEnabled] = 1;
					if (Instant)
					{
						GivePlayerCurWeapon(Players[Client]);
					}
					else
					{
						PrintCenterText(Client, "Touch locker to apply changes");
					}
					ShowMainMenu(Client);
				}
				// Player want disable mod for himself
				else if (StrEqual(MenuData[Return], ITEM_MAIN_DISABLE))
				{
					Players[Client][PlrEnabled] = 0;
					if (Instant)
					{
						ResetPlayerWeapon(Players[Client]);
					}
					else
					{
						PrintCenterText(Client, "Touch locker to apply changes");
					}
				}
			}
		}
	}
	// Example:
	//GetArrayArray(Players[Client][MenuSeq], Level, MenuData);
	//Level ++;
	//if (StrEqual(MenuData[ID], MENU_MAIN))
	//{
		//if (Level < Size)
		//{

		//}
		//else
		//{

		//}
	//}
}
//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public BasicMenuHandler(Handle:hMenu, MenuAction:action, param1, param2, String: MenuID[])
{
	new String: Info[STR_LEN];
	new MenuData[Menu];
	new Client = 0;
	new Cls = -1;
	new bool: Result = false;
	
	if (action == MenuAction_Select)
	{
		GetMenuItem(hMenu, param2, Info, sizeof(Info));
		Result = true;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			Format(Info, sizeof(Info), "%s", ITEM_BASIC_BACK);
			Result = true;
		}
		else
		{
			Format(Info, sizeof(Info), "%s", ITEM_BASIC_EXIT);
		}
	}

	if (action == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	
	if (Result)
	{
		Client = param1;
		Format(MenuData[ID], STR_LEN, "%s", MenuID);
		Format(MenuData[Return], STR_LEN, "%s", Info);
		if (IsPlayerAlive(Client))
		{
			Cls = _: TF2_GetPlayerClass(Client);
		}
		MenuData[MenuPlrClass] = Cls;
		PushArrayArray(Players[Client][MenuSeq], MenuData[0]);
		LogAction(-1, -1, "%s Player '%L' select item '%s' in '%s' menu", LOG_PREFIX, Client, MenuData[Return], MenuData[ID]);
		MenuLogic(Client);
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show main menu
ShowMainMenu(Client)
{
	ClearMenuSeq(Players[Client]);	// main menu clear all menu sequence
	
	new Handle:MainMenu = CreateMenu(MainMenuHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	
	SetMenuTitle(MainMenu, "Load-Out Manager");
	
	if (Players[Client][PlrEnabled])
	{
		AddMenuItem(MainMenu, ITEM_MAIN_GIVE, "Give weapon");
		AddMenuItem(MainMenu, ITEM_MAIN_LOAD, "Load loadout");
		AddMenuItem(MainMenu, ITEM_MAIN_SAVE, "Save loadout");
		AddMenuItem(MainMenu, ITEM_MAIN_INFO, "View loadout");
		AddMenuItem(MainMenu, ITEM_MAIN_REM, "Remove loadout");
		AddMenuItem(MainMenu, ITEM_MAIN_DISABLE, "Disable");
	}
	else
	{
		AddMenuItem(MainMenu, ITEM_MAIN_ENABLE, "Enable");
	}
	AddMenuItem(MainMenu, ITEM_MAIN_HELP, "Help/FAQ");
	
	SetMenuExitButton(MainMenu, true);
	DisplayMenu(MainMenu, Client, MENU_TIME_FOREVER);

	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public MainMenuHandler(Handle: hMenu, MenuAction: action, param1, param2)
{
	BasicMenuHandler(hMenu, action, param1, param2, MENU_MAIN);
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show menu
ShowSlotMenu(Client)
{
	new Handle: hMenu = CreateMenu(SlotMenuHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);

	SetMenuTitle(hMenu, "Select weapon slot");
	
	AddMenuItem(hMenu, ITEM_SLOT_PRIMARY, "Primary");
	AddMenuItem(hMenu, ITEM_SLOT_SECOND, "Secondary");
	AddMenuItem(hMenu, ITEM_SLOT_MELEE, "Melee");
	AddMenuItem(hMenu, ITEM_SLOT_PDA1, "PDA 1");
	AddMenuItem(hMenu, ITEM_SLOT_PDA2, "PDA 2");
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, Client, MENU_TIME_FOREVER);

	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public SlotMenuHandler(Handle:hMenu, MenuAction:action, param1, param2)
{
	BasicMenuHandler(hMenu, action, param1, param2, MENU_SLOT);
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show menu
ShowClassMenu(Client)
{
	new Handle: hMenu = CreateMenu(ClassMenuHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);

	SetMenuTitle(hMenu, "Select class");
	
	AddMenuItem(hMenu, ITEM_CLASS_CURRENT, "Current");
	AddMenuItem(hMenu, ITEM_CLASS_SCOUT, "Scout");
	AddMenuItem(hMenu, ITEM_CLASS_SOLDIER, "Soldier");
	AddMenuItem(hMenu, ITEM_CLASS_PYRO, "Pyroman");
	AddMenuItem(hMenu, ITEM_CLASS_DEMO, "Demoman");
	AddMenuItem(hMenu, ITEM_CLASS_HEAVY, "Heavy");
	AddMenuItem(hMenu, ITEM_CLASS_ENGI, "Engineer");
	AddMenuItem(hMenu, ITEM_CLASS_MEDIC, "Medic");
	AddMenuItem(hMenu, ITEM_CLASS_SNIPER, "Sniper");
	AddMenuItem(hMenu, ITEM_CLASS_SPY, "Spy");
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, Client, MENU_TIME_FOREVER);

	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public ClassMenuHandler(Handle:hMenu, MenuAction:action, param1, param2)
{
	BasicMenuHandler(hMenu, action, param1, param2, MENU_CLASS);
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show menu
ShowHelpMenu(Client)
{
	new Handle: hMenu = CreateMenu(HelpMenuHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);

	SetMenuTitle(hMenu, "Help/FAQ");
	
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "Q: What is this?", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "A: This is menu where You able to get weapon", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "", ITEMDRAW_SPACER);
	
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "Q: Can I get hat with that mod?", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "A: No, weapons only", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "", ITEMDRAW_SPACER);
	
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "Q: How do I save loadout with name?", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "A: Before save loadout write in chat !loname <NAME>", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "", ITEMDRAW_SPACER);
	
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "Q: Can I get strange weapon with this mod?", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "A: Basically yes, but it will crash your game client, so it was disabled", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "", ITEMDRAW_SPACER);
	
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "Q: Why weapon given with this mod is not visible to others?", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "A: Valve want money for job they did", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "", ITEMDRAW_SPACER);
	
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "Q: What is OP or apocalyptic weapon?", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "A: Modified by admins weapon which is very Over-Powered (OP)", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, ITEM_BASIC_BACK, "", ITEMDRAW_SPACER);
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, Client, MENU_TIME_FOREVER);

	return;
}//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public HelpMenuHandler(Handle:hMenu, MenuAction:action, param1, param2)
{
	BasicMenuHandler(hMenu, action, param1, param2, MENU_HELP);
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show menu
// Enable all - force all weapon, except access restricted ones, to be enabled
ShowWeapMenu(Client, ClassIndex, SlotIndex, EnableAll = false)
{
	new Handle: hMenu = CreateMenu(WeapMenuHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	new bool: HaveAccess = false;
	new bool: WeapEnabled = false;
	new Index = 0;
	new ClassMask = 1 << (_: ClassIndex);
	new String: StrBuf[STR_LEN];
	new String: StrBuf2[STR_LEN];

	SetMenuTitle(hMenu, "Weapon select");
	
	AddMenuItem(hMenu, "-1", "< Reset >");
	
	new Size = GetArraySize(Weapons);
	new WeapData[WeaponInfo];
	for (Index = 0; Index < Size; Index ++)
	{
		GetArrayArray(Weapons, Index, WeapData[0]);
		if ((ClassIndex <= 0) || (WeapData[Class] & ClassMask != 0))
		{
			if (WeapData[Slot] == _:SlotIndex)
			{
				HaveAccess = false;
				if (strlen(WeapData[Access]) > 0)
				{
					HaveAccess = CheckCommandAccess(Client, WeapData[Access], ADMFLAG_NONE, true);
				}
				else
				{
					HaveAccess = true;
				}
				
				if (HaveAccess)
				{
					WeapEnabled = EnableAll || ((GameModeFlag & WeapData[GameMode] != 0) && (! WeapData[Apocalyptic] || Apocalypse));
					Format(StrBuf, sizeof(StrBuf), "%d", WeapData[ID]);
					Format
					(
						StrBuf2, sizeof(StrBuf2),
						"%s%s%s (%d)",
						(WeapData[GameMode] == GAME_MODE_MVM) ? "[MvM] " : "",
						(WeapData[Apocalyptic] > 0) ? "[OP] " : "",
						WeapData[Name],
						WeapData[ID]
					);
					AddMenuItem(hMenu, StrBuf, StrBuf2, WeapEnabled ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
				}
			}
		}
	}
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, Client, MENU_TIME_FOREVER);

	return;
}//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public WeapMenuHandler(Handle:hMenu, MenuAction:action, param1, param2)
{
	BasicMenuHandler(hMenu, action, param1, param2, MENU_WEAP);
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show menu
ShowLoadoutSaveMenu(Client)
{
	new Handle: hMenu = CreateMenu(LoadoutSaveHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	
	SetMenuTitle(hMenu, "Save current loadout");
	
	new Size = 0;
	new Cls[ClassInfo];
	new Lo[LoadoutInfo];
	new ClassIndex = 0;
	new i = 0;
	new String: StrBuf[STR_LEN];
	new String: StrBuf2[STR_LEN];
	
	if (IsPlayerAlive(Client))
	{
		ClassIndex = _: TF2_GetPlayerClass(Client);
		if (ClassIndex > 0 && ClassIndex <= MAX_CLASS)
		{
			GetClassFromArray(Players[Client][Classes], ClassIndex - 1, Cls);
			Size = GetArraySize(Cls[LoadOuts]);
			if (Size < MAX_LOADOUT)
			{
				AddMenuItem(hMenu, ITEM_SAVE_NEW, "< New >");
			}
			else
			{
				AddMenuItem(hMenu, ITEM_SAVE_NEW, "< Limit reached >", ITEMDRAW_DISABLED);
			}
			while (i < Size)
			{
				GetLoadOutFromArray(Cls[LoadOuts], i, Lo);
				Format(StrBuf, STR_LEN, "%d", i);
				if (strlen(Lo[LoName]) > 0)
				{
					Format(StrBuf2, STR_LEN, "Loadout %s - %s", StrBuf, Lo[LoName]);
				}
				else
				{
					Format(StrBuf2, STR_LEN, "Loadout %s", StrBuf);
				}
				AddMenuItem(hMenu, StrBuf, StrBuf2);
				i ++;
			}
		}
		else
		{
			AddMenuItem(hMenu, "-", "Can't determine your current class", ITEMDRAW_DISABLED);
		}
	}
	else
	{
		AddMenuItem(hMenu, "-", "You must be alive", ITEMDRAW_DISABLED);
	}
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, Client, MENU_TIME_FOREVER);
	
	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public LoadoutSaveHandler(Handle:hMenu, MenuAction:action, param1, param2)
{
	BasicMenuHandler(hMenu, action, param1, param2, MENU_SAVE);
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show menu
ShowLoadoutInfoMenu(Client)
{
	new Handle: hMenu = CreateMenu(LoadoutInfoHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	
	SetMenuTitle(hMenu, "View and load loadout");
	
	new Size = 0;
	new Cls[ClassInfo];
	new Lo[LoadoutInfo];
	new Weap[WeaponInfo];
	new ClassIndex = 0;
	new i = 0;
	new j = 0;
	new String: StrBuf[STR_LEN];
	new String: StrBuf2[STR_LEN];
	
	if (IsPlayerAlive(Client))
	{
		ClassIndex = _: TF2_GetPlayerClass(Client);
		if (ClassIndex > 0 && ClassIndex <= MAX_CLASS)
		{
			GetClassFromArray(Players[Client][Classes], ClassIndex - 1, Cls);
			Size = GetArraySize(Cls[LoadOuts]);
			if (Size > 0)
			{
				while (i < Size)
				{
					GetLoadOutFromArray(Cls[LoadOuts], i, Lo);
					Format(StrBuf, STR_LEN, "%d", i);
					Format(StrBuf2, STR_LEN, "Loadout index: %s", StrBuf);
					AddMenuItem(hMenu, StrBuf, StrBuf2);
					Format(StrBuf, STR_LEN, "Name: %s", Lo[LoName]);
					AddMenuItem(hMenu, "-", StrBuf, ITEMDRAW_DISABLED);
					for (j = 0; j < MAX_WEAP; j ++)
					{
						GetWeapFromLoadOut(Lo, j, Weap);
						if (Weap[ID] >= 0)
						{
							Int2Slot(j, StrBuf, STR_LEN);
							Format(StrBuf2, STR_LEN, "%s: %s", StrBuf, Weap[Name]);
							AddMenuItem(hMenu, "-", StrBuf2, ITEMDRAW_DISABLED);
						}
						else
						{
							Int2Slot(j, StrBuf, STR_LEN);
							Format(StrBuf2, STR_LEN, "%s: < None >", StrBuf);
							AddMenuItem(hMenu, "-", StrBuf2, ITEMDRAW_DISABLED);
						}
					}
					i ++;
				}
			}
			else
			{
				AddMenuItem(hMenu, "-", "< No loadouts >", ITEMDRAW_DISABLED);
			}
		}
		else
		{
			AddMenuItem(hMenu, "-", "Can't determine your current class", ITEMDRAW_DISABLED);
		}
	}
	else
	{
		AddMenuItem(hMenu, "-", "You must be alive", ITEMDRAW_DISABLED);
	}
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, Client, MENU_TIME_FOREVER);
	
	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public LoadoutInfoHandler(Handle:hMenu, MenuAction:action, param1, param2)
{
	BasicMenuHandler(hMenu, action, param1, param2, MENU_INFO);
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show menu
ShowLoadoutLoadMenu(Client)
{
	new Handle: hMenu = CreateMenu(LoadoutLoadHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	
	SetMenuTitle(hMenu, "Load loadout");
	
	new Size = 0;
	new Cls[ClassInfo];
	new Lo[LoadoutInfo];
	new Weap[WeaponInfo];
	new ClassIndex = 0;
	new i = 0;
	new String: StrBuf[STR_LEN];
	new String: StrBuf2[STR_LEN];
	
	if (IsPlayerAlive(Client))
	{
		ClassIndex = _: TF2_GetPlayerClass(Client);
		if (ClassIndex > 0 && ClassIndex <= MAX_CLASS)
		{
			GetClassFromArray(Players[Client][Classes], ClassIndex - 1, Cls);
			Size = GetArraySize(Cls[LoadOuts]);
			if (Size > 0)
			{
				while (i < Size)
				{
					GetLoadOutFromArray(Cls[LoadOuts], i, Lo);
					Format(StrBuf, STR_LEN, "%d", i);
					if (strlen(Lo[LoName]) > 0)
					{
						Format(StrBuf2, STR_LEN, "Loadout %s - %s", StrBuf, Lo[LoName]);
					}
					else
					{
						Format(StrBuf2, STR_LEN, "Loadout %s", StrBuf);
					}
					AddMenuItem(hMenu, StrBuf, StrBuf2);
					i ++;
				}
			}
			else
			{
				AddMenuItem(hMenu, "-", "< No loadouts >", ITEMDRAW_DISABLED);
			}
		}
		else
		{
			AddMenuItem(hMenu, "-", "Can't determine your current class", ITEMDRAW_DISABLED);
		}
	}
	else
	{
		AddMenuItem(hMenu, "-", "You must be alive", ITEMDRAW_DISABLED);
	}
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, Client, MENU_TIME_FOREVER);
	
	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public LoadoutLoadHandler(Handle:hMenu, MenuAction:action, param1, param2)
{
	BasicMenuHandler(hMenu, action, param1, param2, MENU_LOAD);
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show menu
ShowLoadoutRemoveMenu(Client)
{
	new Handle: hMenu = CreateMenu(LoadoutRemoveHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	
	SetMenuTitle(hMenu, "Remove loadout");
	
	new Size = 0;
	new Cls[ClassInfo];
	new Lo[LoadoutInfo];
	new ClassIndex = 0;
	new i = 0;
	new String: StrBuf[STR_LEN];
	new String: StrBuf2[STR_LEN];
	
	if (IsPlayerAlive(Client))
	{
		ClassIndex = _: TF2_GetPlayerClass(Client);
		if (ClassIndex > 0 && ClassIndex <= MAX_CLASS)
		{
			GetClassFromArray(Players[Client][Classes], ClassIndex - 1, Cls);
			Size = GetArraySize(Cls[LoadOuts]);
			if (Size > 0)
			{
				while (i < Size)
				{
					GetLoadOutFromArray(Cls[LoadOuts], i, Lo);
					Format(StrBuf, STR_LEN, "%d", i);
					if (strlen(Lo[LoName]) > 0)
					{
						Format(StrBuf2, STR_LEN, "Loadout %s - %s", StrBuf, Lo[LoName]);
					}
					else
					{
						Format(StrBuf2, STR_LEN, "Loadout %s", StrBuf);
					}
					AddMenuItem(hMenu, StrBuf, StrBuf2);
					i ++;
				}
			}
			else
			{
				AddMenuItem(hMenu, "-", "< No loadouts >", ITEMDRAW_DISABLED);
			}
		}
		else
		{
			AddMenuItem(hMenu, "-", "Can't determine your current class", ITEMDRAW_DISABLED);
		}
	}
	else
	{
		AddMenuItem(hMenu, "-", "You must be alive", ITEMDRAW_DISABLED);
	}
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, Client, MENU_TIME_FOREVER);
	
	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public LoadoutRemoveHandler(Handle:hMenu, MenuAction:action, param1, param2)
{
	BasicMenuHandler(hMenu, action, param1, param2, MENU_REM);
}
//──────────────────────────────────────────────────────────────────────────────
