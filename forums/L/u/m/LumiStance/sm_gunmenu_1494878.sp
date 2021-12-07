/*
Name: Gun Menu Lite
Author: LumiStance
Date: 2011 - 03/25

Description:

Background:
	This plugin was inspired by these objectives:
		Code 100% SourceMod - Accessible to more programmers
		No custom gamedata - If SourceMod works, then this plugin works
		Modular - Instead of having a monolithic plugin that does everything
	Thanks Bailopan for creating the original CSS:DM plugin before there was SourceMod,
	and for developing SourceMod and SourcePawn.

	Reload Implementation
		Hooks from CSS:DM basics by Bailopan
		m_iAmmo http://forums.alliedmods.net/showthread.php?t=81546

Files:
	cstrike/addons/sourcemod/plugins/sm_gunmenu.smx
	cstrike/addons/sourcemod/configs/gunmenu.ini

Changelog:
	0.5 <-> 2011 - 06/04 LumiStance
		Develop Ammo Clip Refill on Kill
		Move Refill and Restock into stand alone plugin
	0.4 <-> 2011 - 03/25 LumiStance
		Add code to only load config file and rebuild menus if timestamp changed
		Moved 'None' weapon choice to end of menu
		Add Reserve Ammo Replenishment and configuration
		Made Configuration Section Titles case insensitive
	0.3 <-> 2011 - 02/09 LumiStance
		Fix range checking
	0.2 <-> 2011 - 01/04 LumiStance
		Remember Selection
		Separate primary and secondary arrays
		Implement Random and None Weapons
		Range checking on selections, Announce
	0.1 <-> 2011 - 01/03 LumiStance
		Initial Menu
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// Plugin definitions
#define PLUGIN_VERSION "0.5-lm"
#define PLUGIN_ANNOUNCE "\x04[Gun Menu Lite]\x01 v0.5-lm by LumiStance"
public Plugin:myinfo =
{
	name = "Gun Menu Lite",
	author = "LumiStance",
	version = PLUGIN_VERSION,
	description = "Lets players select from a menu of allowed weapons.",
	url = "http://srcds.LumiStance.com/"
};

// Constants
enum Slots
{
	Slot_Primary,
	Slot_Secondary,
	Slot_Knife,
	Slot_Grenade,
	Slot_C4,
	Slot_None
};

// Console Variables
new Handle:g_ConVar_Version;
// Configuration
new g_ConfigTimeStamp = -1;
// Weapon Menu Configuration
#define MAX_WEAPON_COUNT 32
new g_PrimaryGunCount;
new g_SecondaryGunCount;
new String:g_PrimaryGuns[MAX_WEAPON_COUNT][32];
new String:g_SecondaryGuns[MAX_WEAPON_COUNT][32];
// Menus
new Handle:g_PrimaryMenu = INVALID_HANDLE;
new Handle:g_SecondaryMenu = INVALID_HANDLE;
new Handle:g_OptionsMenu = INVALID_HANDLE;
// Player Settings
new g_PlayerPrimary[MAXPLAYERS+1] = {-1, ...};
new g_PlayerSecondary[MAXPLAYERS+1] = {-1, ...};

public OnPluginStart()
{
	// Version of plugin - Visible to game-monitor.com - Don't store in configuration file
	g_ConVar_Version = CreateConVar("sm_gunmenu_version", PLUGIN_VERSION, "[SM] Gun Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Client Commands
	RegConsoleCmd("sm_guns", Command_GunMenu);
	RegConsoleCmd("sm_gunmenu", Command_GunMenu);

	// Event Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnMapStart()
{
	// Load configuration
	CheckConfig("configs/gunmenu.ini");

	// Work around A2S_RULES bug in linux orange box
	SetConVarString(g_ConVar_Version, PLUGIN_VERSION);
}

public OnClientPutInServer(client_index)
{
	PrintToChat(client_index, PLUGIN_ANNOUNCE);
	g_PlayerPrimary[client_index]=-1;
	g_PlayerSecondary[client_index]=-1;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Event_HandleSpawn, GetEventInt(event, "userid"));
}

stock CheckConfig(const String:ini_file[])
{
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, PLATFORM_MAX_PATH, ini_file);

	new timestamp = GetFileTime(file, FileTime_LastChange);

	if (timestamp == -1)
		SetFailState("[SM] FragWinner: Could not stat config file:\n    %s.", file);

	if (timestamp != g_ConfigTimeStamp)
	{
		InitializeMenus();
		if (ParseConfigFile(file))
		{
			FinalizeMenus();
			g_ConfigTimeStamp = timestamp;
		}
	}
}

stock InitializeMenus()
{
	g_PrimaryGunCount=0;
	CheckCloseHandle(g_PrimaryMenu);
	g_PrimaryMenu = CreateMenu(MenuHandler_ChoosePrimary);
	SetMenuTitle(g_PrimaryMenu, "Choose a Primary Weapon:");
	AddMenuItem(g_PrimaryMenu, "63", "Random");

	g_SecondaryGunCount=0;
	CheckCloseHandle(g_SecondaryMenu);
	g_SecondaryMenu = CreateMenu(MenuHandler_ChooseSecondary);
	SetMenuTitle(g_SecondaryMenu, "Choose a Secondary Weapon:");
	AddMenuItem(g_SecondaryMenu, "63", "Random");

	CheckCloseHandle(g_OptionsMenu);
}

stock FinalizeMenus()
{
	AddMenuItem(g_PrimaryMenu, "FF", "None");
	AddMenuItem(g_SecondaryMenu, "FF", "None");
}

bool:ParseConfigFile(const String:file[]) {
	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	new line = 0;
	new col = 0;
	new String:error[128];
	new SMCError:result = SMC_ParseFile(parser, file, line, col);
	CloseHandle(parser);

	if (result != SMCError_Okay) {
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}

	return (result == SMCError_Okay);
}

new g_configLevel;
public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes)
{
	g_configLevel++;
//	PrintToServer("Level %i %s", g_configLevel, section);
	if (g_configLevel==2)
	{
		if (StrEqual("Settings", section, false))
		{
			SMC_SetReaders(parser, Config_NewSection, Config_SettingsKeyValue, Config_EndSection);
			// Set Defaults
		}
		else if (StrEqual("AutoItems", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_AutoItemsKeyValue, Config_EndSection);
		else if (StrEqual("BotItems", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_BotItemsKeyValue, Config_EndSection);
		else if (StrEqual("PrimaryMenu", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_PrimaryKeyValue, Config_EndSection);
		else if (StrEqual("SecondaryMenu", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_SecondaryKeyValue, Config_EndSection);
	}
	else
		SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	return SMCParse_Continue;
}

public SMCResult:Config_UnknownKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	PrintToServer("Level %i %s=%s", g_configLevel, key, value);
	return SMCParse_Continue;
}

public SMCResult:Config_SettingsKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	return SMCParse_Continue;
}

public SMCResult:Config_AutoItemsKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
//	PrintToServer("Level %i %s=%s", g_configLevel, key, value);
	return SMCParse_Continue;
}

public SMCResult:Config_BotItemsKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
//	PrintToServer("Level %i %s=%s", g_configLevel, key, value);
	return SMCParse_Continue;
}

public SMCResult:Config_PrimaryKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes) {
	if (g_PrimaryGunCount>=MAX_WEAPON_COUNT)
		SetFailState("[SM] DM Gun Menu: Too many weapons declared!");

	decl String:weapon_id[4];
	strcopy(g_PrimaryGuns[g_PrimaryGunCount], sizeof(g_PrimaryGuns[]), weapon_class);
	Format(weapon_id, sizeof(weapon_id), "%02.2X", g_PrimaryGunCount++);
	AddMenuItem(g_PrimaryMenu, weapon_id, weapon_name);
	return SMCParse_Continue;
}

public SMCResult:Config_SecondaryKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes)
{
	if (g_SecondaryGunCount>=MAX_WEAPON_COUNT)
		SetFailState("[SM] DM Gun Menu: Too many weapons declared!");

	decl String:weapon_id[4];
	strcopy(g_SecondaryGuns[g_SecondaryGunCount], sizeof(g_SecondaryGuns[]), weapon_class);
	Format(weapon_id, sizeof(weapon_id), "%02.2X", g_SecondaryGunCount++);
	AddMenuItem(g_SecondaryMenu, weapon_id, weapon_name);
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser)
{
	g_configLevel--;
	SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed)
{
	if (failed)
		SetFailState("Plugin configuration error");
}

// Set Player's Primary Weapon
public MenuHandler_ChoosePrimary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new client_index = param1;
		decl String:weapon_id[4];
		GetMenuItem(menu, param2, weapon_id, sizeof(weapon_id));
		new weapon_index = StringToInt(weapon_id, 16);

		g_PlayerPrimary[client_index] = weapon_index;
		GivePrimary(client_index, weapon_index);

		DisplayMenu(g_SecondaryMenu, client_index, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
		DisplayMenu(g_SecondaryMenu, param1, MENU_TIME_FOREVER);
}

// Set Player's Secondary Weapon
public MenuHandler_ChooseSecondary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new client_index = param1;
		decl String:weapon_id[4];
		GetMenuItem(menu, param2, weapon_id, sizeof(weapon_id));
		new weapon_index = StringToInt(weapon_id, 16);

		g_PlayerSecondary[client_index] = weapon_index;
		GiveSecondary(client_index, weapon_index);

//		DisplayMenu(g_OoptionsMenu, client_index, MENU_TIME_FOREVER);
	}
//	else if (action == MenuAction_Cancel)
//	DisplayMenu(g_OoptionsMenu, client_index, 10);
}

// After Delay, Show Menu or Give Weapons
public Action:Event_HandleSpawn(Handle:timer, any:user_index)
{
	new client_index = GetClientOfUserId(user_index);

	// Make sure the client is on a team and didn't disconnect during delay
	if (IsClientInGame(client_index) && GetClientTeam(client_index) >= 2)
	{
		if (g_PlayerPrimary[client_index]<0 && g_PlayerSecondary[client_index]<0)
			DisplayMenu(g_PrimaryMenu, client_index, MENU_TIME_FOREVER);
		else
		{
			GivePrimary(client_index, g_PlayerPrimary[client_index]);
			GiveSecondary(client_index, g_PlayerSecondary[client_index]);
		}
	}
}

stock GivePrimary(client_index, weapon_index)
{
	RemoveWeaponBySlot(client_index, Slot_Primary);
	if (weapon_index == 0x63)
		weapon_index = GetRandomInt(0, g_PrimaryGunCount-1);
	if (weapon_index >= 0 && weapon_index < g_PrimaryGunCount)
		GivePlayerItem(client_index, g_PrimaryGuns[weapon_index]);
}

stock GiveSecondary(client_index, weapon_index)
{
	RemoveWeaponBySlot(client_index, Slot_Secondary);
	if (weapon_index == 0x63)
		weapon_index = GetRandomInt(0, g_SecondaryGunCount-1);
	if (weapon_index >= 0 && weapon_index < g_SecondaryGunCount)
		GivePlayerItem(client_index, g_SecondaryGuns[weapon_index]);
}

public Action:Command_GunMenu(client_index, args)
{
	if (IsClientInGame(client_index) && GetClientTeam(client_index) >= 2)
		DisplayMenu(g_PrimaryMenu, client_index, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

stock CheckCloseHandle(&Handle:handle)
{
	if (handle != INVALID_HANDLE)
	{
		CloseHandle(handle);
		handle = INVALID_HANDLE;
	}
}

// May not work for grenades and C4 - See GunGame UTIL_ForceDropWeaponBySlot
stock RemoveWeaponBySlot(client_index, Slots:slot)
{
	new entity_index = GetPlayerWeaponSlot(client_index, _:slot);
	if (entity_index>0)
	{
		RemovePlayerItem(client_index, entity_index);
		AcceptEntityInput(entity_index, "kill");
//		RemoveEdict(entity_index);
	}
}
