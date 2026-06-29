/**
* DoD:S GunMenu by Root
*
* Description:
*   Provides a menu to choose weapons which are automatically given at respawn, automatically gives ammo, grenades etc...
*
* Version 2.0
* Changelog & more info at http://goo.gl/4nKhJ
*/

#include <sdktools>

// ====[ CONSTANTS ]=====================================================
#define PLUGIN_NAME          "DoD:S GunMenu"
#define PLUGIN_VERSION       "2.1"

#define DOD_MAXPLAYERS       33
#define MAX_WEAPON_LENGTH    24
#define RANDOM_WEAPON        13 // just in case...
#define PRIMARY_WEAPON_COUNT 12
#define DEFAULT_WEAPON_COUNT 4
#define TEAM_SPECTATOR       1
#define SHOW_MENU            -1

enum Slots
{
	Slot_Primary,
	Slot_Secondary,
	Slot_Melee,
	Slot_Grenade
};

// ====[ VARIABLES ]=====================================================
new	Handle:WeaponsTrie      = INVALID_HANDLE,
	Handle:guns_enablemenu  = INVALID_HANDLE,
	Handle:guns_usetriggers = INVALID_HANDLE,
	Handle:guns_saveweapons = INVALID_HANDLE,
	Handle:PrimaryMenu      = INVALID_HANDLE,
	Handle:SecondaryMenu    = INVALID_HANDLE,
	Handle:MeleeMenu        = INVALID_HANDLE,
	Handle:GrenadesMenu     = INVALID_HANDLE;

new	m_iAmmo,
	ParserLevel,
	PrimaryGuns_Count,
	SecondaryGuns_Count,
	MeleeWeapons_Count,
	Grenades_Count;

new	String:PrimaryGuns  [PRIMARY_WEAPON_COUNT][MAX_WEAPON_LENGTH],
	String:SecondaryGuns[DEFAULT_WEAPON_COUNT][MAX_WEAPON_LENGTH],
	String:MeleeWeapons [DEFAULT_WEAPON_COUNT][MAX_WEAPON_LENGTH],
	String:Grenades     [DEFAULT_WEAPON_COUNT][MAX_WEAPON_LENGTH];

new	PrimaryIndex  [DOD_MAXPLAYERS + 1],
	SecondaryIndex[DOD_MAXPLAYERS + 1],
	MeleeIndex    [DOD_MAXPLAYERS + 1],
	GrenadeIndex  [DOD_MAXPLAYERS + 1];

// ====[ PLUGIN ]========================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root, update Micmacx",
	description = "Provides a menu to choose allowed weapons which are automatically given at respawn",
	version     = PLUGIN_VERSION,
	url         = "http://dodsplugins.com/"
}


/**
 * ----------------------------------------------------------------------
 *     ____           ______                  __  _
 *    / __ \____     / ____/__  ______  _____/ /_(_)____  ____  _____
 *   / / / / __ \   / /_   / / / / __ \/ ___/ __/ // __ \/ __ \/ ___/
 *  / /_/ / / / /  / __/  / /_/ / / / / /__/ /_/ // /_/ / / / (__  )
 *  \____/_/ /_/  /_/     \__,_/_/ /_/\___/\__/_/ \____/_/ /_/____/
 *
 * ----------------------------------------------------------------------
*/

/* OnPluginStart()
 *
 * When the plugin starts up.
 * ---------------------------------------------------------------------- */
public OnPluginStart()
{
	// Cache send property offset (for ammo setup)
	if ((m_iAmmo = FindSendPropInfo("CDODPlayer", "m_iAmmo")) == -1)
		SetFailState("Fatal Error: Unable to find prop offset \"CDODPlayer::m_iAmmo\"!");

	// Create plugin ConVars
	CreateConVar("dod_gunmenu_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	guns_enablemenu  = CreateConVar("dod_guns_enablemenu",  "1", "Whether or not show gun menu at every respawn",                                  _, true, 0.0, true, 1.0);
	guns_usetriggers = CreateConVar("dod_guns_usetriggers", "1", "Whether or not allow players to say \"weapon\" and get its weapon by classname", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	guns_saveweapons = CreateConVar("dod_guns_saveweapons", "1", "Whether or not save preferenced weapons and automatically give them on respawn", _, true, 0.0, true, 1.0);

	// Create/register gunmenu commands
	RegConsoleCmd("sm_guns",    Command_GunMenu);
	RegConsoleCmd("sm_weapons", Command_GunMenu);
	RegConsoleCmd("sm_gunmenu", Command_GunMenu);

	// Hook event after player spawns
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	// Create trie with weapon names
	WeaponsTrie = CreateTrie();
	AutoExecConfig(true, "dod_gunmenu");
}

/* OnMapStart()
 *
 * When the map starts.
 * ---------------------------------------------------------------------- */
public OnMapStart()
{
	// Loads weapons config from configs directory
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/weapons.ini");

	// Create menus and parse a config then
	InitializeMenus();
	ClearTrie(WeaponsTrie);
	ParseConfigFile(file);
}

/* OnClientPutInServer()
 *
 * Called when a client is entering the game.
 * ---------------------------------------------------------------------- */
public OnClientPutInServer(client)
{
	// Show gun menu to normal players
	PrimaryIndex[client]   =
	SecondaryIndex[client] =
	MeleeIndex[client]     =
	GrenadeIndex[client]   =
	(IsFakeClient(client)) ? RANDOM_WEAPON : SHOW_MENU;
}

/* OnClientSayCommand()
 *
 * When a client says something.
 * ---------------------------------------------------------------------- */
public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	// Check whether or not allow player to get weapons by names
	if (GetConVarBool(guns_usetriggers))
	{
		if (IsValidClient(client))
		{
			decl String:text[MAX_WEAPON_LENGTH], String:prefix[] = "weapon_", index;

			// Copy original message
			strcopy(text, sizeof(text), sArgs);

			// Remove quotes from destination string, otherwise indexes will never be detected
			StripQuotes(text);

			// Now get rid of capital chars
			for (index = 0; index < strlen(text); index++)
			{
				// CharToLower is already checks for IsCharUpper
				text[index] = CharToLower(text[index]);
			}

			// Add 'weapon_' prefix to given text
			StrCat(prefix, MAX_WEAPON_LENGTH, text);

			// Because 'bar' is called as 'weapon_bar' in trie
			if (GetTrieValue(WeaponsTrie, prefix, index))
			{
				// Does prefix is equal to primary gun by its index?
				if (StrEqual(PrimaryGuns[index], prefix))
				{
					PrimaryIndex[client] = index;
					GivePrimary(client);
				}
				else if (StrEqual(SecondaryGuns[index], prefix))
				{
					// Nope, that was secondary weapon
					SecondaryIndex[client] = index;
					GiveSecondary(client);
				}
				else if (StrEqual(MeleeWeapons[index], prefix))
				{
					// Set appropriate weapon index and give weapon
					MeleeIndex[client] = index;
					GiveMelee(client);
				}
				else if (StrEqual(Grenades[index], prefix))
				{
					GrenadeIndex[client] = index;
					GiveGrenades(client);
				}

				// Dont show message
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}


/**
 * ----------------------------------------------------------------------
 *      ______                  __
 *     / ____/_   _____  ____  / /______
 *    / __/  | | / / _ \/ __ \/ __/ ___/
 *   / /___  | |/ /  __/ / / / /_(__  )
 *  /_____/  |___/\___/_/ /_/\__/____/
 *
 * ----------------------------------------------------------------------
*/

/* Event_player_spawn()
 *
 * Called when a player spawns.
 * ---------------------------------------------------------------------- */
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Plugin should work only with valid clients
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		// Show menu if client not choose weapons yet
		if (PrimaryIndex[client]   == SHOW_MENU
		&&  SecondaryIndex[client] == SHOW_MENU
		&&  MeleeIndex[client]     == SHOW_MENU
		&&  GrenadeIndex[client]   == SHOW_MENU)
		{
			if (GetConVarBool(guns_enablemenu))
			{
				// Check if menu is valid (i.e have any weapon(s) in a config)
				if (PrimaryMenu != INVALID_HANDLE)
					DisplayMenu(PrimaryMenu, client, MENU_TIME_FOREVER);
				else if (SecondaryMenu != INVALID_HANDLE)
					DisplayMenu(SecondaryMenu, client, MENU_TIME_FOREVER);
				else if (MeleeMenu != INVALID_HANDLE)
					DisplayMenu(MeleeMenu, client, MENU_TIME_FOREVER);
				else if (GrenadesMenu != INVALID_HANDLE)
					DisplayMenu(GrenadesMenu, client, MENU_TIME_FOREVER);
			}
		}

		// If plugin is enabled at least by menu or triggers, check whether or not automatically give weapons on respawn
		else if ((GetConVarBool(guns_enablemenu) || GetConVarBool(guns_usetriggers)) && GetConVarBool(guns_saveweapons))
		{
			// Success, give all weapons then
			GivePrimary(client);
			GiveSecondary(client);
			GiveMelee(client);
			GiveGrenades(client);
		}
	}
}

/**
 * ----------------------------------------------------------------------
 *      __  ___
 *     /  |/  /___  ___  __  ________
 *    / /|_/ / _ \/ __ \/ / / // ___/
 *   / /  / /  __/ / / / /_/ /(__  )
 *  /_/  /_/\___/_/ /_/\__,_/_____/
 *
 * ----------------------------------------------------------------------
*/

/* Command_GunMenu()
 *
 * Show gun menu to a player.
 * ---------------------------------------------------------------------- */
public Action:Command_GunMenu(client, args)
{
	// Plugin disabled - GunMenu disabled
	if (GetConVarBool(guns_enablemenu))
	{
		// Allow only valid players to use gun menu command
		if (IsValidClient(client))
		{
			/* Menu with primary guns */
			if (PrimaryMenu != INVALID_HANDLE)
				DisplayMenu(PrimaryMenu, client, MENU_TIME_FOREVER);
			/* with secondary */
			else if (SecondaryMenu != INVALID_HANDLE)
				DisplayMenu(SecondaryMenu, client, MENU_TIME_FOREVER);
			/* with melee */
			else if (MeleeMenu != INVALID_HANDLE)
				DisplayMenu(MeleeMenu, client, MENU_TIME_FOREVER);
			/* and grenades */
			else if (GrenadesMenu != INVALID_HANDLE)
				DisplayMenu(GrenadesMenu, client, MENU_TIME_FOREVER);
		}
	}

	// Prevents showing 'Unknown command' in client console
	return Plugin_Handled;
}

/* InitializeMenus()
 *
 * Create menus if config is valid.
 * ---------------------------------------------------------------------- */
InitializeMenus()
{
	// Reset amount of all available weapons at every map start
	PrimaryGuns_Count = SecondaryGuns_Count = MeleeWeapons_Count = Grenades_Count = 0;

	CheckCloseHandle(PrimaryMenu);
	CheckCloseHandle(SecondaryMenu); // Close all menu handlers
	CheckCloseHandle(MeleeMenu);
	CheckCloseHandle(GrenadesMenu);

	// Re-create menus for every weapon sections
	PrimaryMenu   = CreateMenu(MenuHandler_ChoosePrimary,   MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	SecondaryMenu = CreateMenu(MenuHandler_ChooseSecondary, MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	MeleeMenu     = CreateMenu(MenuHandler_ChooseMelee,     MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	GrenadesMenu  = CreateMenu(MenuHandler_ChooseGrenades,  MenuAction_Display|MenuAction_Select|MenuAction_Cancel);

	// Set titles of all menus
	SetMenuTitle(PrimaryMenu,   "Choose a Primary Weapon:");
	SetMenuTitle(SecondaryMenu, "Choose a Secondary Weapon:");
	SetMenuTitle(MeleeMenu,     "Choose a Melee Weapon:");
	SetMenuTitle(GrenadesMenu,  "Choose a Grenades:");

	// Add 'random' selec option to primary and secondary weapon sections
	AddMenuItem(PrimaryMenu,   "13", "Random");
	AddMenuItem(SecondaryMenu, "13", "Random");
}

/* MenuHandler_ChoosePrimary()
 *
 * Menu to set player's primary weapon.
 * ---------------------------------------------------------------------- */
public MenuHandler_ChoosePrimary(Handle:menu, MenuAction:action, client, param)
{
	// Retrieve menu action
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:weapon_id[4];
			GetMenuItem(menu, param, weapon_id, sizeof(weapon_id));

			PrimaryIndex[client] = StringToInt(weapon_id);

			// Give correct weapon to a player
			GivePrimary(client);

			// If client pressed something, call menu with secondary weapons immediate
			DisplayMenu(SecondaryMenu, client, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			if (param == MenuCancel_Exit) // CancelClientMenu sends MenuCancel_Interrupted reason
			{
				if (SecondaryMenu != INVALID_HANDLE)
				{
					DisplayMenu(SecondaryMenu, client, MENU_TIME_FOREVER);
				}
			}
		}
	}
}

/* MenuHandler_ChooseSecondary()
 *
 * Menu to set player's secondary weapon.
 * ---------------------------------------------------------------------- */
public MenuHandler_ChooseSecondary(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select: /* Called when player pressed something in a menu */
		{
			// Getting weapon name from config file
			decl String:weapon_id[4];
			GetMenuItem(menu, param, weapon_id, sizeof(weapon_id));

			SecondaryIndex[client] = StringToInt(weapon_id);
			GiveSecondary(client);

			DisplayMenu(MeleeMenu, client, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel: /* When client pressed 0 */
		{
			// Close a menu with secondary weapons
			if (param == MenuCancel_Exit)
			{
				if (MeleeMenu != INVALID_HANDLE)
				{
					DisplayMenu(MeleeMenu, client, MENU_TIME_FOREVER);
				}
			}
		}
	}
}

/* MenuHandler_ChooseMelee()
 *
 * Menu to set player's melee weapon.
 * ---------------------------------------------------------------------- */
public MenuHandler_ChooseMelee(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:weapon_id[4];

			// Give weapon which is covered under this title
			GetMenuItem(menu, param, weapon_id, sizeof(weapon_id));

			MeleeIndex[client] = StringToInt(weapon_id);
			GiveMelee(client);

			DisplayMenu(GrenadesMenu, client, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			// Client pressed exit on a melee weapon menu, call last grenade menu
			if (param == MenuCancel_Exit)
			{
				// Call only if menu is valid (i.e config have Grenades section)
				if (GrenadesMenu != INVALID_HANDLE)
				{
					// Show latest menu with grenades
					DisplayMenu(GrenadesMenu, client, MENU_TIME_FOREVER);
				}
			}
		}
	}
}

/* MenuHandler_ChooseGrenades()
 *
 * Menu to set grenades.
 * ---------------------------------------------------------------------- */
public MenuHandler_ChooseGrenades(Handle:menu, MenuAction:action, client, param)
{
	// Thee are only one action for grenades, and that's selection
	if (action == MenuAction_Select)
	{
		decl String:weapon_id[4];
		GetMenuItem(menu, param, weapon_id, sizeof(weapon_id));

		GrenadeIndex[client] = StringToInt(weapon_id);
		GiveGrenades(client);
	}
}


/**
 * ----------------------------------------------------------------------
 *    _    __    __
 *   | |  /  |  / /___  ____ _____  ____  ____  _____
 *   | | / / | / // _ \/ __ `/ __ \/ __ \/ __ \/ ___/
 *   | |/ /| |/ //  __/ /_/ / /_/ / /_/ / / / (__  )
 *   |___/ |___/ \___/\__,_/ .___/\____/_/ /_/____/
 *                        /_/
 * ----------------------------------------------------------------------
*/

/* GiveWeapon()
 *
 * Removing old weapon and replaces to a new one.
 * ---------------------------------------------------------------------- */
GivePrimary(client)
{
	// Get primary weapon index
	new weapon = PrimaryIndex[client];

	// Check if player has chosen random weapon
	if (weapon == RANDOM_WEAPON) weapon = GetRandomInt(0, PrimaryGuns_Count - 1);
	if (0 <= weapon < PrimaryGuns_Count)
	{
		RemoveWeaponBySlot(client, Slot_Primary);
		GivePlayerItem(client, PrimaryGuns[weapon]);
		SetAmmo(client, Slot_Primary);
	}
}

GiveSecondary(client)
{
	new weapon = SecondaryIndex[client];
	if (weapon == RANDOM_WEAPON) weapon = GetRandomInt(0, SecondaryGuns_Count - 1);

	// Include zero index, because if client choose a random weapon, he may not take it
	if (0 <= weapon < SecondaryGuns_Count)
	{
		// Remove old secondary weapon
		RemoveWeaponBySlot(client, Slot_Secondary);
		GivePlayerItem(client, SecondaryGuns[weapon]);
		SetAmmo(client, Slot_Secondary);
	}
}

GiveMelee(client)
{
	new weapon = MeleeIndex[client];
	if (0 <= weapon < MeleeWeapons_Count)
	{
		RemoveWeaponBySlot(client, Slot_Melee);

		// Then give exact item
		GivePlayerItem(client, MeleeWeapons[weapon]);
	}
}

GiveGrenades(client)
{
	new weapon = GrenadeIndex[client];

	// No random here - no check
	if (0 <= weapon < Grenades_Count)
	{
		RemoveWeaponBySlot(client, Slot_Grenade);
		GivePlayerItem(client, Grenades[weapon]);

		// And add ammo for it
		SetAmmo(client, Slot_Grenade);
	}
}

/* SetAmmo()
 *
 * Adds magazines to a specified weapons.
 * ---------------------------------------------------------------------- */
SetAmmo(client, Slots:slot)
{
	// Returns the weapon in a player's slot
	new weapon = GetPlayerWeaponSlot(client, _:slot);

	// Checking if weapon is valid
	if (IsValidEdict(weapon))
	{
		// I dont know how its working, but its working very well!
		switch (GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"))
		{
			case 1:  SetEntData(client, m_iAmmo + 4,   14); /* Colt */
			case 2:  SetEntData(client, m_iAmmo + 8,   16); /* P38 */
			case 3:  SetEntData(client, m_iAmmo + 12,  40); /* C96 */
			case 4:  SetEntData(client, m_iAmmo + 16,  80); /* Garand */
			case 5:  SetEntData(client, m_iAmmo + 20,  60); /* K98+scoped */
			case 6:  SetEntData(client, m_iAmmo + 24,  30); /* M1 Carbine */
			case 7:  SetEntData(client, m_iAmmo + 28,  50); /* Spring */
			case 8:  SetEntData(client, m_iAmmo + 32, 180); /* Thompson, MP40 and STG44 */
			case 9:  SetEntData(client, m_iAmmo + 36, 240); /* BAR */
			case 10: SetEntData(client, m_iAmmo + 40, 300); /* 30cal */
			case 11: SetEntData(client, m_iAmmo + 44, 250); /* MG42 */
			case 12: SetEntData(client, m_iAmmo + 48,   4); /* Bazooka, Panzerschreck */
			case 13: SetEntData(client, m_iAmmo + 52,   2); /* US frag gren */
			case 14: SetEntData(client, m_iAmmo + 56,   2); /* Stick gren */
			case 15: SetEntData(client, m_iAmmo + 68,   1); /* US Smoke */
			case 16: SetEntData(client, m_iAmmo + 72,   1); /* Stick smoke */
			case 17: SetEntData(client, m_iAmmo + 84,   2); /* Riflegren US */
			case 18: SetEntData(client, m_iAmmo + 88,   2); /* Riflegren GER */
		}
	}
}

/* RemoveWeaponBySlot()
 *
 * Remove's player weapon by slot.
 * ---------------------------------------------------------------------- */
RemoveWeaponBySlot(client, Slots:slot)
{
	// Get slot which should be removed
	new weapon = GetPlayerWeaponSlot(client, _:slot);

	// Checking if weapon is valid
	if (IsValidEdict(weapon))
	{
		// Proper weapon removing
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
}


/**
 * ----------------------------------------------------------------------
 *     ______            _____
 *    / ____/___  ____  / __(_)___ _
 *   / /   / __ \/ __ \/ /_/ / __ `/
 *  / /___/ /_/ / / / / __/ / /_/ /
 *  \____/\____/_/ /_/_/ /_/\__, /
 *                         /____/
 * ----------------------------------------------------------------------
*/

/* ParseConfigFile()
 *
 * Parses a config file.
 * ---------------------------------------------------------------------- */
ParseConfigFile(const String:file[])
{
	// Create parser with all sections (start & end)
	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders (parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	// Checking for error
	new String:error[128], line, col, SMCError:result = SMC_ParseFile(parser, file, line, col);

	// Close handle
	CloseHandle(parser);

	// Log an error
	if (result != SMCError_Okay)
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s at line %d, col %d of %s", error, line, col, file);
	}
}

/* Config_NewSection()
 *
 * Called when the parser is entering a new section or sub-section.
 * ---------------------------------------------------------------------- */
public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes)
{
	// Ignore first config level (GunMenu Weapons)
	ParserLevel++;

	if (ParserLevel == 2)
	{
		// Checking if menu names is correct
		if (StrEqual("Primary Guns", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_PrimaryKeyValue, Config_EndSection);

		/* If correct - sets the three main reader functions */
		else if (StrEqual("Secondary Guns", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_SecondaryKeyValue, Config_EndSection);

		/* for specified menu */
		else if (StrEqual("Melee Weapons", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_MeleeKeyValue, Config_EndSection);
		else if (StrEqual("Grenades", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_GrenadeKeyValue, Config_EndSection);
	}
	// Anyway create pointers
	else SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	return SMCParse_Continue;
}

/* Config_UnknownKeyValue()
 *
 * Called when the parser finds a new key/value pair.
 * ---------------------------------------------------------------------- */
public SMCResult:Config_UnknownKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	// Log an error if unknown key value found in a config file
	SetFailState("Didn't recognize configuration: %s = %s", key, value);
	return SMCParse_Continue;
}

/* Config_PrimaryKeyValue()
 *
 * Called when the parser finds a primary key/value pair.
 * ---------------------------------------------------------------------- */
public SMCResult:Config_PrimaryKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes)
{
	// Weapons should not exceed real value
	if (PrimaryGuns_Count > PRIMARY_WEAPON_COUNT)
		SetFailState("Too many weapons declared!");

	decl String:weapon_id[4];

	// Copies one string to another string
	strcopy(PrimaryGuns[PrimaryGuns_Count], sizeof(PrimaryGuns[]), weapon_class);
	FormatEx(weapon_id, sizeof(weapon_id), "%i", PrimaryGuns_Count++);
	AddMenuItem(PrimaryMenu, weapon_id, weapon_name);
	SetTrieValue(WeaponsTrie, weapon_class, StringToInt(weapon_id));
	return SMCParse_Continue;
}

/* Config_SecondaryKeyValue()
 *
 * Called when the parser finds a secondary key/value pair.
 * ---------------------------------------------------------------------- */
public SMCResult:Config_SecondaryKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes)
{
	if (SecondaryGuns_Count > DEFAULT_WEAPON_COUNT)
		SetFailState("Too many weapons declared!");

	decl String:weapon_id[4];
	strcopy(SecondaryGuns[SecondaryGuns_Count], sizeof(SecondaryGuns[]), weapon_class);

	// Calculate number of avaliable secondary weapons
	FormatEx(weapon_id, sizeof(weapon_id), "%i", SecondaryGuns_Count++);
	AddMenuItem(SecondaryMenu, weapon_id, weapon_name);
	SetTrieValue(WeaponsTrie, weapon_class, StringToInt(weapon_id));
	return SMCParse_Continue;
}

/* Config_MeleeKeyValue()
 *
 * Called when the parser finds a melee key/value pair.
 * ---------------------------------------------------------------------- */
public SMCResult:Config_MeleeKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes)
{
	if (MeleeWeapons_Count > DEFAULT_WEAPON_COUNT)
		SetFailState("Too many weapons declared!");

	decl String:weapon_id[4];
	strcopy(MeleeWeapons[MeleeWeapons_Count], sizeof(MeleeWeapons[]), weapon_class);
	FormatEx(weapon_id, sizeof(weapon_id), "%i", MeleeWeapons_Count++);

	// Add every weapon as menu item
	AddMenuItem(MeleeMenu, weapon_id, weapon_name);
	SetTrieValue(WeaponsTrie, weapon_class, StringToInt(weapon_id));
	return SMCParse_Continue;
}

/* Config_GrenadeKeyValue()
 *
 * Called when the parser finds a grenade's key/value pair.
 * ---------------------------------------------------------------------- */
public SMCResult:Config_GrenadeKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes)
{
	if (Grenades_Count > DEFAULT_WEAPON_COUNT)
		SetFailState("Too many weapons declared!");

	// If grenades aren't avaliable at all, dont add greandes in a menu
	decl String:weapon_id[4];
	strcopy(Grenades[Grenades_Count], sizeof(Grenades[]), weapon_class);
	FormatEx(weapon_id, sizeof(weapon_id), "%i", Grenades_Count++);
	AddMenuItem(GrenadesMenu, weapon_id, weapon_name);

	// Add weapon_classname string into trie and add weapon id there as a key
	SetTrieValue(WeaponsTrie, weapon_class, StringToInt(weapon_id));

	return SMCParse_Continue;
}

/* Config_EndSection()
 *
 * Called when the parser finds the end of the current section.
 * ---------------------------------------------------------------------- */
public SMCResult:Config_EndSection(Handle:parser)
{
	// Config is ready - return to original level
	ParserLevel--;

	// I prefer textparse, because there is possible to easy add/remove weapons/sections with no issues
	SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	return SMCParse_Continue;
}

/* Config_End()
 *
 * Called when the config is ready.
 * ---------------------------------------------------------------------- */
public Config_End(Handle:parser, bool:halted, bool:failed)
{
	// Failed to load config. Maybe we missed a braket or something?
	if (failed)
	{
		SetFailState("Plugin configuration error!");
	}
}


/**
 * ----------------------------------------------------------------------
 *      __  ____
 *     /  |/  (_)__________
 *    / /|_/ / // ___/ ___/
 *   / /  / / /(__  ) /__
 *  /_/  /_/_//____/\___/
 *
 * ----------------------------------------------------------------------
*/

/* CheckCloseHandle()
 *
 * Checks if handle is closed or not and close handle.
 * ---------------------------------------------------------------------- */
CheckCloseHandle(&Handle:handle)
{
	// Check and close handle if not closed yet
	if (handle != INVALID_HANDLE)
	{
		CloseHandle(handle);
		handle = INVALID_HANDLE;
	}
}

/* IsValidClient()
 *
 * Checks if a client is valid.
 * ---------------------------------------------------------------------- */
bool:IsValidClient(client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > TEAM_SPECTATOR) ? true : false;
}