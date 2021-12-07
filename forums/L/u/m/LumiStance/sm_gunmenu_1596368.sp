/*
Name: Gun Menu Lite
Author: LumiStance
Date: 2011 - 11/13

Description:
	Provides a menu to choose weapons.  Once choosen the weapons are automatically given at respawn.
	The avaible weapons are configurable (see configuration below).  The menu also provides a choice
	of no gun or random.  Bots are given the same items as players and random guns.

	The plugin can also be configured to give health, armor, helmet, flashbangs, smokegrenade, hegrenade,
	defusekits, and nightvision at spawn.  C4 pickup can be disabled.  A configurable sound is played when
	when a player scores.

	Servers using this mod: http://www.game-monitor.com/search.php?vars=sm_gunmenu_version&num=100

Installation:
	Place compiled plugin (sm_gunmenu.smx) into the plugins folder.
	Place the configuration file (gunmenu.ini) into the config folder.
	Changes to gunmenu.ini are read at map/plugin load time.

Complimentary Plugins:
	Ammo Replenishment Lite: http://forums.alliedmods.net/showthread.php?t=158534
	Deathmatch Lite Respawn: http://forums.alliedmods.net/showthread.php?t=130853

Background:
	This plugin was inspired by these objectives:
		Code 100% SourcePawn - Accessible to more programmers
		No custom gamedata - If SourceMod works, then this plugin works
		Stand alone modules - Only install what you need
	Much gratitude towards Bailopan and crew for creating the original CSS:DM
	plugin before there was SourceMod, and for developing SourceMod and SourcePawn.

Files:
	cstrike/addons/sourcemod/plugins/sm_gunmenu.smx
	cstrike/addons/sourcemod/configs/gunmenu.ini
	cstrike/cfg/server.cfg

Commands:
	sm_guns and sm_gunmenu
		When enabled, presents player with menus to choose primary and secondary weapons

Gun Menu Configuration (Change in gunmenu.ini):
	Configuration is specified as key values in the gunmenu.ini file.
	There are four sections:
		Settings - frag_sound (relative to sound), allow_c4 (yes/no), buy_zones (yes/no)
		SpawnItems - health (0 no change), armor (0 no change), helmet (yes/no),
			flashbangs (yes/no), smokegrenade (yes/no), hegrenade (yes/no),
			defusekits (yes/no), nightvision (yes/no)
		PrimaryMenu - classname and menu text ("weapon_g3sg1" "D3/AU-1")
		SecondaryMenu - classname and menu text ("weapon_fiveseven" "ES Five Seven")

Server Configuration Variables (Change in server.cfg):
	mp_fraglimit - Set this to score need to win map
	mp_ignore_round_win_conditions - Set this to prevent round end

To-Do:
	Knife steal
	Free For All plugin
	Other suggestions?

Changelog:
	1.0 <-> 2011 - 11/13 LumiStance
		Add code to close menu if player spectates
		Add code to prevent spectators from opening menu
		Add code to set bots to random guns
		Consolidate Configuration Sections
		Homogenize Error Messages
		Remove Options Menu stubs
	0.9 <-> 2011 - 10/17 LumiStance
		Add code to strip Nades
		Removed quantity option for Flashbangs
		Cleanup entity removal code
		Modify GivePrimary and GiveSecondary to retrieve weapon index
		Add code to handle late load
	0.8 <-> 2011 - 07/01 LumiStance
		Add code to limit Defuser to CT
		Add code to strip bomb on pickup (configurable)
		Add code to prevent spectators from getting guns
		Add SetFailState for entity member offsets
	0.7 <-> 2011 - 06/28 LumiStance
		Improve client_index validation in Event_HandleSpawn
		Fix IsFakeClient() placement in Event_PlayerDeath
	0.6 <-> 2011 - 06/24 LumiStance
		Add code to remove buy zones
		Add code to give/set Health, Nades, Night Vision, etc.
		Add frag sound
		Add code to nuke menus OnPluginEnd
	0.5 <-> 2011 - 06/23 LumiStance
		Public beta release
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
#define PLUGIN_VERSION "1.0-lm"
#define PLUGIN_ANNOUNCE "\x04[Gun Menu Lite]\x01 v1.0-lm by LumiStance"
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
enum Teams
{
	CS_TEAM_NONE,
	CS_TEAM_SPECTATOR,
	CS_TEAM_T,
	CS_TEAM_CT
};

// Console Variables
new Handle:g_ConVar_Version;
// Configuration
new g_ConfigTimeStamp = -1;
new String:g_szFragSound[PLATFORM_MAX_PATH];
new g_AllowBuyMenu = false;
new g_AllowBomb = false;
new g_SpawnHealth = 0;
new g_SpawnArmor = 0;
new bool:g_SpawnHelmet = false;
new bool:g_SpawnFlash = false;
new bool:g_SpawnSmoke = false;
new bool:g_SpawnHE = false;
new bool:g_SpawnDefuser = false;
new bool:g_SpawnNV = false;
// Weapon Entity Members and Data
new m_iHealth = -1;
new m_ArmorValue = -1;
new m_bHasHelmet = -1;
new m_bHasDefuser = -1;
new m_bHasNightVision = -1;
// Weapon Menu Configuration
#define MAX_WEAPON_COUNT 32
#define RANDOM_WEAPON 0x63
#define SHOW_MENU -1
new g_PrimaryGunCount;
new g_SecondaryGunCount;
new String:g_PrimaryGuns[MAX_WEAPON_COUNT][32];
new String:g_SecondaryGuns[MAX_WEAPON_COUNT][32];
// Menus
new bool:g_MenuOpen[MAXPLAYERS+1] = {false, ...};
new Handle:g_PrimaryMenu = INVALID_HANDLE;
new Handle:g_SecondaryMenu = INVALID_HANDLE;
// Player Settings
new g_PlayerPrimary[MAXPLAYERS+1] = {-1, ...};
new g_PlayerSecondary[MAXPLAYERS+1] = {-1, ...};

public OnPluginStart()
{
	// Version of plugin - Visible to game-monitor.com - Don't store in configuration file
	g_ConVar_Version = CreateConVar("sm_gunmenu_version", PLUGIN_VERSION, "[SM] Gun Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Cache Send Property Offsets
	m_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
	m_ArmorValue = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	m_bHasHelmet = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
	m_bHasDefuser = FindSendPropOffs("CCSPlayer", "m_bHasDefuser");
	m_bHasNightVision = FindSendPropOffs("CCSPlayer", "m_bHasNightVision");
	if (m_iHealth == -1 || m_ArmorValue == -1 || m_bHasHelmet == -1 || m_bHasDefuser == -1 || m_bHasNightVision == -1)
		SetFailState("\nFailed to retrieve entity member offsets");

	// Client Commands
	RegConsoleCmd("sm_guns", Command_GunMenu);
	RegConsoleCmd("sm_gunmenu", Command_GunMenu);

	// Event Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("bomb_pickup", Event_BombPickup);
	HookEvent("player_team", Event_PlayerTeam);
}

public OnPluginEnd()
{
	CancelMenu(g_PrimaryMenu);
	CheckCloseHandle(g_PrimaryMenu);
	CancelMenu(g_SecondaryMenu);
	CheckCloseHandle(g_SecondaryMenu);
}

public OnMapStart()
{
	// Load configuration
	CheckConfig("configs/gunmenu.ini");

	// Remove buy zones from map to disable the buy menu
	if (!g_AllowBuyMenu)
		RemoveBuyZones();

	// Handle late load
	if (GetClientCount(true))
		for (new client_index = 1; client_index <= MaxClients; ++client_index)
			if (IsClientInGame(client_index))
			{
				OnClientPutInServer(client_index);
				if (IsPlayerAlive(client_index))
					CreateTimer(0.1, Event_HandleSpawn, GetClientUserId(client_index));
			}


	// Work around A2S_RULES bug in linux orange box
	SetConVarString(g_ConVar_Version, PLUGIN_VERSION);
}

// Must be manually replayed for late load
public OnClientPutInServer(client_index)
{
	PrintToChat(client_index, PLUGIN_ANNOUNCE);
	g_MenuOpen[client_index]=false;

	// Give bots random guns
	if (IsFakeClient(client_index))
	{
		g_PlayerPrimary[client_index] = RANDOM_WEAPON;
		g_PlayerSecondary[client_index] = RANDOM_WEAPON;
	}
	else
	{
		g_PlayerPrimary[client_index] = SHOW_MENU;
		g_PlayerSecondary[client_index] = SHOW_MENU;
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Event_HandleSpawn, GetEventInt(event, "userid"));
}

// Did a player get a kill?
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_szFragSound[0])
	{
		new victim_index = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker_index = GetClientOfUserId(GetEventInt(event, "attacker"));

		if (0 < attacker_index && attacker_index <= MaxClients && attacker_index != victim_index && !IsFakeClient(attacker_index))
			EmitSoundToClient(attacker_index, g_szFragSound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	}
}

public Action:Event_BombPickup( Handle:event, const String:name[], bool:dontBroadcast )
{
	if (!g_AllowBomb)
		RemoveWeaponBySlot(GetClientOfUserId(GetEventInt(event, "userid")), Slot_C4);
}

// If player spectated close any gun menus
public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_index = GetClientOfUserId(GetEventInt(event, "userid"));

	if (g_MenuOpen[client_index] && (Teams:GetEventInt(event, "team") == CS_TEAM_SPECTATOR))
	{
		CancelClientMenu(client_index);		// Delayed
		g_MenuOpen[client_index] = false;
	}
}

stock CheckConfig(const String:ini_file[])
{
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), ini_file);

	new timestamp = GetFileTime(file, FileTime_LastChange);

	if (timestamp == -1)
		SetFailState("\nCould not stat config file: %s.", file);

	if (timestamp != g_ConfigTimeStamp)
	{
		InitializeMenus();
		if (ParseConfigFile(file))
		{
			FinalizeMenus();

			if (g_szFragSound[0])
				CacheSoundFile(g_szFragSound);

			g_ConfigTimeStamp = timestamp;
		}
	}
}

stock CacheSoundFile(String:sound[])
{
	decl String:buffer[PLATFORM_MAX_PATH];
	PrecacheSound(sound, true);
	Format(buffer, sizeof(buffer), "sound/%s", sound);
	AddFileToDownloadsTable(buffer);
}

stock InitializeMenus()
{
	g_PrimaryGunCount=0;
	CheckCloseHandle(g_PrimaryMenu);
	g_PrimaryMenu = CreateMenu(MenuHandler_ChoosePrimary, MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	SetMenuTitle(g_PrimaryMenu, "Choose a Primary Weapon:");
	AddMenuItem(g_PrimaryMenu, "63", "Random");

	g_SecondaryGunCount=0;
	CheckCloseHandle(g_SecondaryMenu);
	g_SecondaryMenu = CreateMenu(MenuHandler_ChooseSecondary, MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	SetMenuTitle(g_SecondaryMenu, "Choose a Secondary Weapon:");
	AddMenuItem(g_SecondaryMenu, "63", "Random");
}

stock FinalizeMenus()
{
	AddMenuItem(g_PrimaryMenu, "FF", "None");
	AddMenuItem(g_SecondaryMenu, "FF", "None");
}

bool:ParseConfigFile(const String:file[]) {
	// Set Defaults
	g_szFragSound[0] = 0;
	g_AllowBuyMenu = false;
	g_AllowBomb = false;

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
	if (g_configLevel==2)
	{
		if (StrEqual("Settings", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_SettingsKeyValue, Config_EndSection);
		else if (StrEqual("SpawnItems", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_SpawnItemsKeyValue, Config_EndSection);
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
	SetFailState("\nDidn't recognize configuration: Level %i %s=%s", g_configLevel, key, value);
	return SMCParse_Continue;
}

public SMCResult:Config_SettingsKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if (StrEqual("frag_sound", key, false))
		strcopy(g_szFragSound, sizeof(g_szFragSound), value);
	else if (StrEqual("allow_c4", key, false))
		g_AllowBomb = StrEqual("yes", value, false);
	else if (StrEqual("buy_zones", key, false))
		g_AllowBuyMenu = StrEqual("yes", value, false);
	return SMCParse_Continue;
}

public SMCResult:Config_SpawnItemsKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if (StrEqual("health", key, false))
		g_SpawnHealth = StringToInt(value);
	else if (StrEqual("armor", key, false))
		g_SpawnArmor = StringToInt(value);
	else if (StrEqual("helmet", key, false))
		g_SpawnHelmet = StrEqual("yes", value, false);
	else if (StrEqual("flashbangs", key, false))
		g_SpawnFlash = StrEqual("yes", value, false);
	else if (StrEqual("smokegrenade", key, false))
		g_SpawnSmoke = StrEqual("yes", value, false);
	else if (StrEqual("hegrenade", key, false))
		g_SpawnHE = StrEqual("yes", value, false);
	else if (StrEqual("defusekits", key, false))
		g_SpawnDefuser = StrEqual("yes", value, false);
	else if (StrEqual("nightvision", key, false))
		g_SpawnNV = StrEqual("yes", value, false);
	return SMCParse_Continue;
}

public SMCResult:Config_PrimaryKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes) {
	if (g_PrimaryGunCount>=MAX_WEAPON_COUNT)
		SetFailState("\nToo many weapons declared!");

	decl String:weapon_id[4];
	strcopy(g_PrimaryGuns[g_PrimaryGunCount], sizeof(g_PrimaryGuns[]), weapon_class);
	Format(weapon_id, sizeof(weapon_id), "%02.2X", g_PrimaryGunCount++);
	AddMenuItem(g_PrimaryMenu, weapon_id, weapon_name);
	return SMCParse_Continue;
}

public SMCResult:Config_SecondaryKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes)
{
	if (g_SecondaryGunCount>=MAX_WEAPON_COUNT)
		SetFailState("\nToo many weapons declared!");

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
		SetFailState("\nPlugin configuration error");
}

// Set Player's Primary Weapon
public MenuHandler_ChoosePrimary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Display)
		g_MenuOpen[param1] = true;
	else if (action == MenuAction_Select)
	{
		new client_index = param1;
		decl String:weapon_id[4];
		GetMenuItem(menu, param2, weapon_id, sizeof(weapon_id));
		new weapon_index = StringToInt(weapon_id, 16);

		g_PlayerPrimary[client_index] = weapon_index;
		if (Teams:GetClientTeam(client_index) > CS_TEAM_SPECTATOR)
			GivePrimary(client_index);

		DisplayMenu(g_SecondaryMenu, client_index, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		g_MenuOpen[param1] = false;
		if (param2 == MenuCancel_Exit)	// CancelClientMenu sends MenuCancel_Interrupted reason
		{
			if (g_SecondaryMenu != INVALID_HANDLE)
				DisplayMenu(g_SecondaryMenu, param1, MENU_TIME_FOREVER);
		}
	}
}

// Set Player's Secondary Weapon
public MenuHandler_ChooseSecondary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Display)
		g_MenuOpen[param1] = true;
	else if (action == MenuAction_Select)
	{
		new client_index = param1;
		decl String:weapon_id[4];
		GetMenuItem(menu, param2, weapon_id, sizeof(weapon_id));
		new weapon_index = StringToInt(weapon_id, 16);

		g_PlayerSecondary[client_index] = weapon_index;
		if (Teams:GetClientTeam(client_index) > CS_TEAM_SPECTATOR)
			GiveSecondary(client_index);
	}
	else if (action == MenuAction_Cancel)
		g_MenuOpen[param1] = false;
}

// After Delay, Show Menu or Give Weapons
public Action:Event_HandleSpawn(Handle:timer, any:user_index)
{
	// This event implies client is in-game while GetClientOfUserId() checks IsClientConnected()
	new client_index = GetClientOfUserId(user_index);
	if (!client_index)
		return;

	new Teams:client_team = Teams:GetClientTeam(client_index);
	if (client_team > CS_TEAM_SPECTATOR)
	{
		// Health
		if (g_SpawnHealth)
			SetEntData(client_index, m_iHealth, g_SpawnHealth, 1, true);
		// Vest Armor
		if (g_SpawnArmor)
			SetEntData(client_index, m_ArmorValue, g_SpawnArmor, 1, true);
		// Helmet
		SetEntData(client_index, m_bHasHelmet, 1&_:g_SpawnHelmet, 1, true);
		// Remove any nades
		StripNades(client_index);
		// Flash Bangs
		if (g_SpawnFlash)
			GivePlayerItem(client_index, "weapon_flashbang");
		// Smoke Grenade
		if (g_SpawnSmoke)
			GivePlayerItem(client_index, "weapon_smokegrenade");
		// HE Grenade
		if (g_SpawnHE)
			GivePlayerItem(client_index, "weapon_hegrenade");
		// Defuser Kit
		if (client_team == CS_TEAM_CT)
			SetEntData(client_index, m_bHasDefuser, 1&_:g_SpawnDefuser, 1, true);
		// Night Vision
		SetEntData(client_index, m_bHasNightVision, 1&_:g_SpawnNV, 1, true);

		// Show Menu or Give Guns
		if (g_PlayerPrimary[client_index]==SHOW_MENU && g_PlayerSecondary[client_index]==SHOW_MENU)
		{
			if (g_PrimaryMenu != INVALID_HANDLE)
				DisplayMenu(g_PrimaryMenu, client_index, MENU_TIME_FOREVER);
			else if (g_SecondaryMenu != INVALID_HANDLE)
				DisplayMenu(g_SecondaryMenu, client_index, MENU_TIME_FOREVER);
		}
		else
		{
			GivePrimary(client_index);
			GiveSecondary(client_index);
		}
	}
}

stock GivePrimary(client_index)
{
	new weapon_index = g_PlayerPrimary[client_index];
	RemoveWeaponBySlot(client_index, Slot_Primary);
	if (weapon_index == RANDOM_WEAPON)
		weapon_index = GetRandomInt(0, g_PrimaryGunCount-1);
	if (weapon_index >= 0 && weapon_index < g_PrimaryGunCount)
		GivePlayerItem(client_index, g_PrimaryGuns[weapon_index]);
}

stock GiveSecondary(client_index)
{
	new weapon_index = g_PlayerSecondary[client_index];
	RemoveWeaponBySlot(client_index, Slot_Secondary);
	if (weapon_index == RANDOM_WEAPON)
		weapon_index = GetRandomInt(0, g_SecondaryGunCount-1);
	if (weapon_index >= 0 && weapon_index < g_SecondaryGunCount)
		GivePlayerItem(client_index, g_SecondaryGuns[weapon_index]);
}

public Action:Command_GunMenu(client_index, args)
{
	if (IsClientInGame(client_index) && Teams:GetClientTeam(client_index) > CS_TEAM_SPECTATOR)
	{
		if (g_PrimaryMenu != INVALID_HANDLE)
			DisplayMenu(g_PrimaryMenu, client_index, MENU_TIME_FOREVER);
		else if (g_SecondaryMenu != INVALID_HANDLE)
			DisplayMenu(g_SecondaryMenu, client_index, MENU_TIME_FOREVER);
	}
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

stock StripNades(client_index)
{
	while (RemoveWeaponBySlot(client_index, Slot_Grenade)) {}
}

stock bool:RemoveWeaponBySlot(client_index, Slots:slot)
{
	new entity_index = GetPlayerWeaponSlot(client_index, _:slot);
	if (entity_index>0)
	{
		RemovePlayerItem(client_index, entity_index);
		AcceptEntityInput(entity_index, "Kill");
		return true;
	}
	return false;
}

stock RemoveBuyZones()
{
	new MaxEntities = GetMaxEntities();
	decl String:sz_classname[16];

	for (new entity_index = MaxClients+1; entity_index < MaxEntities; ++entity_index)
	{
		if (IsValidEdict(entity_index))
		{
			GetEdictClassname(entity_index, sz_classname, sizeof(sz_classname));
			if (StrEqual(sz_classname, "func_buyzone"))
				AcceptEntityInput(entity_index, "Kill");
		}
	}
}

stock min(a, b) {return (a<b) ? a:b;}
stock max(a, b) {return (a>b) ? a:b;}
