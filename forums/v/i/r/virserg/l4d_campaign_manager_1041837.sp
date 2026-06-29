/**
 * [L4D/2] Campaign Manager
 * Created by Bigbuck
 *
 */

/**
 * Thanks to DieTeetasse for German translation
 *
 */

/**
	v1.0.0
	- Initial Release

	v1.0.1
	- Added German translations thanks to DieTeetasse
	- Updated translations to include missing strings
	- Added L4D2 teamversus, realism, and teamscavenge gamemodes
	- Gamemode is now changed based on what category you selected the map from
 */

// Force strict semicolon mode
#pragma semicolon 1

/**
 * Includes
 *
 */
#include <sourcemod>
#include <sdktools>
// Make the admin menu plugin optional
#undef REQUIRE_PLUGIN
#include <adminmenu>

/**
 * Handles
 *
 */
// Admin menu handles
new Handle: Admin_Menu			= INVALID_HANDLE;
new TopMenuObject: Coop 			= INVALID_TOPMENUOBJECT;
new TopMenuObject: Versus 			= INVALID_TOPMENUOBJECT;
new TopMenuObject: Team_Versus 	= INVALID_TOPMENUOBJECT;
new TopMenuObject: Survival 		= INVALID_TOPMENUOBJECT;
new TopMenuObject: Realism 		= INVALID_TOPMENUOBJECT;
new TopMenuObject: Scavenge 		= INVALID_TOPMENUOBJECT;
new TopMenuObject: Team_Scavenge	= INVALID_TOPMENUOBJECT;
// Array handles
new Handle:	Array_Coop			= INVALID_HANDLE;
new Handle:	Array_Versus			= INVALID_HANDLE;
new Handle:	Array_Survival		= INVALID_HANDLE;
new Handle:	Array_Scavenge		= INVALID_HANDLE;

/**
 * Global variables
 *
 */
// Detects L4D2
new bool: game_l4d2 = false;

/**
 * Defines
 *
 */
#define PLUGIN_VERSION	"1.0.1"
#define MISSION_PATH		"missions"

/**
 * Global variables
 *
 */
new String: gamemode[64];

/**
 * Plugin information
 *
 */
public Plugin: myinfo =
{
	name = "[L4D/2] Campaign Manager",
	author = "Bigbuck",
	description = "Dynamically creates an admin menu for all campaigns installed on a server.",
	version = PLUGIN_VERSION,
	url = "http://bigbuck-sm.assembla.com/spaces/dashboard/index/bigbuck-sm"
};

/**
 * Setup plugins first run
 *
 */
public OnPluginStart()
{
	// Require Left 4 Dead
	decl String: game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Use this in Left 4 Dead or Left 4 Dead 2 only.");
	}
	// We need to know if L4D2 is running
	if (StrEqual(game_name, "left4dead2", false))
	{
		game_l4d2 = true;
	}

	// Make sure the missions directory exists
	if (!DirExists(MISSION_PATH))
	{
		SetFailState("missions directory does not exist on this server.  Campaign Manager cannot continue operation");
	}

	// Create convars
	CreateConVar("sm_l4d_campaign_manager_version", PLUGIN_VERSION, "[L4D/2] Campaign Manager Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Load translation file
	LoadTranslations("l4d_campaign_manager");

	// Load the admin menu
	new Handle: topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

/**
 * Called before a library is removed
 *
 * @string: name - The name of the library
 *
 */
public OnLibraryRemoved(const String: name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		Admin_Menu = INVALID_HANDLE;
	}
}

/**
 * Called when the admin menu is ready
 *
 * @handle: topmenu - The admin menu handle
 *
 */
public OnAdminMenuReady(Handle: topmenu)
{
	// Block us from being called twice
	if (topmenu == Admin_Menu)
	{
		return;
	}
	Admin_Menu = topmenu;

	// Add the ZA menu to the SM menu
	AddToTopMenu(Admin_Menu, "Campaign Manager", TopMenuObject_Category, MenuHandler_Top, INVALID_TOPMENUOBJECT);
	// Create a menu object for us so we can add items to our menu
	new TopMenuObject: CM_Menu = FindTopMenuCategory(Admin_Menu, "Campaign Manager");
	// Make sure what we just created is not invalid
	if (CM_Menu == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	// Setup correct categories and arrays
	if (game_l4d2)
	{
		Coop 				= AddToTopMenu(Admin_Menu, "cm_coop", TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_coop", ADMFLAG_CHANGEMAP);
		Versus 			= AddToTopMenu(Admin_Menu, "cm_versus", TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_versus", ADMFLAG_CHANGEMAP);
		Team_Versus 		= AddToTopMenu(Admin_Menu, "cm_team_versus", TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_team_versus", ADMFLAG_CHANGEMAP);
		Survival 			= AddToTopMenu(Admin_Menu, "cm_survival", TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_survival", ADMFLAG_CHANGEMAP);
		Realism 			= AddToTopMenu(Admin_Menu, "cm_realism", TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_realism", ADMFLAG_CHANGEMAP);
		Scavenge			= AddToTopMenu(Admin_Menu, "cm_scavenge", TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_scavenge", ADMFLAG_CHANGEMAP);
		Team_Scavenge	= AddToTopMenu(Admin_Menu, "cm_team_scavenge", TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_team_scavenge", ADMFLAG_CHANGEMAP);

		Array_Coop 		= CreateArray(32);
		Array_Versus 	= CreateArray(32);
		Array_Survival 	= CreateArray(32);
		Array_Scavenge	= CreateArray(32);
	}
	else
	{
		Coop 		= AddToTopMenu(Admin_Menu, "cm_coop", TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_coop", ADMFLAG_CHANGEMAP);
		Versus 	= AddToTopMenu(Admin_Menu, "cm_versus", TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_versus", ADMFLAG_CHANGEMAP);
		Survival 	= AddToTopMenu(Admin_Menu, "cm_survival", TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_survival", ADMFLAG_CHANGEMAP);

		Array_Coop 		= CreateArray(32);
		Array_Versus 	= CreateArray(32);
		Array_Survival 	= CreateArray(32);
	}

	// Open the missions directory
	new Handle: missions_dir = INVALID_HANDLE;
	missions_dir = OpenDirectory(MISSION_PATH);
	if (missions_dir == INVALID_HANDLE)
	{
		SetFailState("Cannot open missions directory");
	}

	// Setup strings
	decl String: buffer[256];
	decl String: full_path[256];
	decl String: campaign_mode[64];

	// Loop through all the files
	while (ReadDirEntry(missions_dir, buffer, sizeof(buffer)))
	{
		// Skip folders and credits file
		if (DirExists(buffer) || StrEqual(buffer, "credits.txt", false))
		{
			continue;
		}

		// Create the keyvalues
		Format(full_path, sizeof(full_path), "%s/%s", MISSION_PATH, buffer);
		new Handle: missions_kv = CreateKeyValues("mission");
		FileToKeyValues(missions_kv, full_path);

		// Get to correct position so we can start our loop
		KvJumpToKey(missions_kv, "modes", false);
		KvGotoFirstSubKey(missions_kv);

		do
		{
			// First get the section name
			KvGetSectionName(missions_kv, campaign_mode, sizeof(campaign_mode));
			// Put it in the correct array
			if (StrEqual(campaign_mode, "coop", true))
			{
				PushArrayString(Array_Coop, full_path);
			}
			else if (StrEqual(campaign_mode, "versus", true))
			{
				PushArrayString(Array_Versus, full_path);
			}
			else if (StrEqual(campaign_mode, "survival", true))
			{
				PushArrayString(Array_Survival, full_path);
			}
			else if (StrEqual(campaign_mode, "scavenge", true))
			{
				PushArrayString(Array_Scavenge, full_path);
			}
		} while (KvGotoNextKey(missions_kv));

		// Close the KV handle for the next loop
		CloseHandle(missions_kv);
	}

	// Close the directory handle
	CloseHandle(missions_dir);
}

/**
 * Handles the CM top menu
 *
 * @handle: topmenu - The top menu handle
 * @topmenuaction: action - The top menu action being performed
 * @topmenuobject: object_id - The top menu object being changes
 * @string: buffer - Buffer for translations
 *
 */
public MenuHandler_Top(Handle: topmenu, TopMenuAction: action, TopMenuObject: object_id, Client, String: buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "Campaign Manager:");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Campaign Manager");
	}
}

/**
 * Handles the CM top menu items
 *
 * @handle: topmenu - The top menu handle
 * @topmenuaction: action - The top menu action being performed
 * @topmenuobject: object_id - The top menu object being changes
 * @string: buffer - Buffer for translations
 *
 */
public MenuHandler_TopItems(Handle: topmenu, TopMenuAction: action, TopMenuObject: object_id, Client, String: buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == Coop)
		{
			Format(buffer, maxlength, "Coop");
		}
		else if (object_id == Versus)
		{
			Format(buffer, maxlength, "Versus");
		}
		else if (object_id == Team_Versus)
		{
			Format(buffer, maxlength, "Team Versus");
		}
		else if (object_id == Survival)
		{
			Format(buffer, maxlength, "Survival");
		}
		else if (object_id == Realism)
		{
			Format(buffer, maxlength, "Realism");
		}
		else if (object_id == Scavenge)
		{
			Format(buffer, maxlength, "Scavenge");
		}
		else if (object_id == Team_Scavenge)
		{
			Format(buffer, maxlength, "Team Scavenge");
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == Coop)
		{
			CoopMenu(Client, false);
		}
		else if (object_id == Versus)
		{
			VersusMenu(Client, false);
		}
		else if (object_id == Team_Versus)
		{
			TeamVersusMenu(Client, false);
		}
		else if (object_id == Survival)
		{
			SurvivalMenu(Client, false);
		}
		else if (object_id == Realism)
		{
			RealismMenu(Client, false);
		}
		else if (object_id == Scavenge)
		{
			ScavengeMenu(Client, false);
		}
		else if (object_id == Team_Scavenge)
		{
			TeamScavengeMenu(Client, false);
		}
	}
}

/**
 * Creates the CM coop menu
 *
 * @param: Client - The Client that is using the menu
 * @param: args - The clients choice
 *
 */
public Action: CoopMenu(Client, args)
{
	// Create menu handle
	new Handle: Menu_Coop = CreateMenu(MenuHandler_Coop);
	// Set menu title
	SetMenuTitle(Menu_Coop, "Coop:");

	// Build and display menu
	BuildMenu(Array_Coop, Menu_Coop);
	DisplayMenu(Menu_Coop, Client, 20);

	return Plugin_Handled;
}

/**
 * CM coop menu handler
 *
 * @handle: CoopMenu - The coop menu handle
 * @menuaction: action - The action the user has taken on the menu
 * @param: Client - The Client using the menu
 * @param: position - The name of the map chosen
 *
 */
public MenuHandler_Coop(Handle: CoopMenu, MenuAction: action, Client, position)
{
	if (action == MenuAction_Select)
	{
		// Create handle for map menu
		new Handle: Menu_Map = CreateMenu(MenuHandler_Map);

		// Get the chosen file name
		decl String: file[64];
		GetMenuItem(CoopMenu, position, file, sizeof(file));

		// Build and display menu
		gamemode = "coop";
		BuildMenuHandler(Menu_Map, file);
		DisplayMenu(Menu_Map, Client, 20);
	}
}

/**
 * Creates the CM versus menu
 *
 * @param: Client - The Client that is using the menu
 * @param: args - The clients choice
 *
 */
public Action: VersusMenu(Client, args)
{
	// Create menu handle
	new Handle: Menu_Versus = CreateMenu(MenuHandler_Versus);
	// Set menu title
	SetMenuTitle(Menu_Versus, "Versus:");

	// Build and display menu
	BuildMenu(Array_Versus, Menu_Versus);
	DisplayMenu(Menu_Versus, Client, 20);

	return Plugin_Handled;
}

/**
 * CM versus menu handler
 *
 * @handle: VersusMenu - The versus menu handle
 * @menuaction: action - The action the user has taken on the menu
 * @param: Client - The Client using the menu
 * @param: position - The name of the map chosen
 *
 */
public MenuHandler_Versus(Handle: VersusMenu, MenuAction: action, Client, position)
{
	if (action == MenuAction_Select)
	{
		// Create handle for map menu
		new Handle: Menu_Map = CreateMenu(MenuHandler_Map);

		// Get the chosen file name
		decl String: file[64];
		GetMenuItem(VersusMenu, position, file, sizeof(file));

		// Build and display menu
		gamemode = "versus";
		BuildMenuHandler(Menu_Map, file);
		DisplayMenu(Menu_Map, Client, 20);
	}
}

/**
 * Creates the CM team versus menu
 *
 * @param: Client - The Client that is using the menu
 * @param: args - The clients choice
 *
 */
public Action: TeamVersusMenu(Client, args)
{
	// Create menu handle
	new Handle: Menu_TeamVersus = CreateMenu(MenuHandler_TeamVersus);
	// Set menu title
	SetMenuTitle(Menu_TeamVersus, "Team Versus:");

	// Build and display menu
	BuildMenu(Array_Versus, Menu_TeamVersus);
	DisplayMenu(Menu_TeamVersus, Client, 20);

	return Plugin_Handled;
}

/**
 * CM team versus menu handler
 *
 * @handle: TeamVersusMenu - The versus menu handle
 * @menuaction: action - The action the user has taken on the menu
 * @param: Client - The Client using the menu
 * @param: position - The name of the map chosen
 *
 */
public MenuHandler_TeamVersus(Handle: TeamVersusMenu, MenuAction: action, Client, position)
{
	if (action == MenuAction_Select)
	{
		// Create handle for map menu
		new Handle: Menu_Map = CreateMenu(MenuHandler_Map);

		// Get the chosen file name
		decl String: file[64];
		GetMenuItem(TeamVersusMenu, position, file, sizeof(file));

		// Build and display menu
		gamemode = "versus";
		BuildMenuHandler(Menu_Map, file);
		gamemode = "teamversus";
		DisplayMenu(Menu_Map, Client, 20);
	}
}

/**
 * Creates the CM survival menu
 *
 * @param: Client - The Client that is using the menu
 * @param: args - The clients choice
 *
 */
public Action: SurvivalMenu(Client, args)
{
	// Create menu handle
	new Handle: Menu_Survival = CreateMenu(MenuHandler_Survival);
	// Set menu title
	SetMenuTitle(Menu_Survival, "Survival:");

	// Build and display menu
	BuildMenu(Array_Survival, Menu_Survival);
	DisplayMenu(Menu_Survival, Client, 20);

	return Plugin_Handled;
}

/**
 * CM survival menu handler
 *
 * @handle: SurvivalMenu - The survival menu handle
 * @menuaction: action - The action the user has taken on the menu
 * @param: Client - The Client using the menu
 * @param: position - The name of the map chosen
 *
 */
public MenuHandler_Survival(Handle: SurvivalMenu, MenuAction: action, Client, position)
{
	if (action == MenuAction_Select)
	{
		// Create handle for map menu
		new Handle: Menu_Map = CreateMenu(MenuHandler_Map);

		// Get the chosen file name
		decl String: file[64];
		GetMenuItem(SurvivalMenu, position, file, sizeof(file));

		// Build and display menu
		gamemode = "survival";
		BuildMenuHandler(Menu_Map, file);
		DisplayMenu(Menu_Map, Client, 20);
	}
}

/**
 * Creates the CM realism menu
 *
 * @param: Client - The Client that is using the menu
 * @param: args - The clients choice
 *
 */
public Action: RealismMenu(Client, args)
{
	// Create menu handle
	new Handle: Menu_Realism = CreateMenu(MenuHandler_Realism);
	// Set menu title
	SetMenuTitle(Menu_Realism, "Realism:");

	// Build and display menu
	BuildMenu(Array_Coop, Menu_Realism);
	DisplayMenu(Menu_Realism, Client, 20);

	return Plugin_Handled;
}

/**
 * CM versus menu handler
 *
 * @handle: RealismMenu - The versus menu handle
 * @menuaction: action - The action the user has taken on the menu
 * @param: Client - The Client using the menu
 * @param: position - The name of the map chosen
 *
 */
public MenuHandler_Realism(Handle: RealismMenu, MenuAction: action, Client, position)
{
	if (action == MenuAction_Select)
	{
		// Create handle for map menu
		new Handle: Menu_Map = CreateMenu(MenuHandler_Map);

		// Get the chosen file name
		decl String: file[64];
		GetMenuItem(RealismMenu, position, file, sizeof(file));

		// Build and display menu
		gamemode = "coop";
		BuildMenuHandler(Menu_Map, file);
		gamemode = "realism";
		DisplayMenu(Menu_Map, Client, 20);
	}
}

/**
 * Creates the CM scavenge menu
 *
 * @param: Client - The Client that is using the menu
 * @param: args - The clients choice
 *
 */
public Action: ScavengeMenu(Client, args)
{
	// Create menu handle
	new Handle: Menu_Scavenge = CreateMenu(MenuHandler_Scavenge);
	// Set menu title
	SetMenuTitle(Menu_Scavenge, "Scavenge:");

	// Build and display menu
	BuildMenu(Array_Scavenge, Menu_Scavenge);
	DisplayMenu(Menu_Scavenge, Client, 20);

	return Plugin_Handled;
}

/**
 * CM scavenge menu handler
 *
 * @handle: ScavengeMenu - The scavenge menu handle
 * @menuaction: action - The action the user has taken on the menu
 * @param: Client - The Client using the menu
 * @param: position - The name of the map chosen
 *
 */
public MenuHandler_Scavenge(Handle: ScavengeMenu, MenuAction: action, Client, position)
{
	if (action == MenuAction_Select)
	{
		// Create handle for map menu
		new Handle: Menu_Map = CreateMenu(MenuHandler_Map);

		// Get the chosen file name
		decl String: file[64];
		GetMenuItem(ScavengeMenu, position, file, sizeof(file));

		// Build and display menu
		gamemode = "scavenge";
		BuildMenuHandler(Menu_Map, file);
		DisplayMenu(Menu_Map, Client, 20);
	}
}

/**
 * Creates the CM team scavenge menu
 *
 * @param: Client - The Client that is using the menu
 * @param: args - The clients choice
 *
 */
public Action: TeamScavengeMenu(Client, args)
{
	// Create menu handle
	new Handle: Menu_TeamScavenge = CreateMenu(MenuHandler_TeamScavenge);
	// Set menu title
	SetMenuTitle(Menu_TeamScavenge, "Team Scavenge:");

	// Build and display menu
	BuildMenu(Array_Scavenge, Menu_TeamScavenge);
	DisplayMenu(Menu_TeamScavenge, Client, 20);

	return Plugin_Handled;
}

/**
 * CM scavenge menu handler
 *
 * @handle: ScavengeMenu - The scavenge menu handle
 * @menuaction: action - The action the user has taken on the menu
 * @param: Client - The Client using the menu
 * @param: position - The name of the map chosen
 *
 */
public MenuHandler_TeamScavenge(Handle: TeamScavengeMenu, MenuAction: action, Client, position)
{
	if (action == MenuAction_Select)
	{
		// Create handle for map menu
		new Handle: Menu_Map = CreateMenu(MenuHandler_Map);

		// Get the chosen file name
		decl String: file[64];
		GetMenuItem(TeamScavengeMenu, position, file, sizeof(file));

		// Build and display menu
		gamemode = "scavenge";
		BuildMenuHandler(Menu_Map, file);
		gamemode = "teamscavenge";
		DisplayMenu(Menu_Map, Client, 20);
	}
}

/**
 * CM map menu handler
 *
 * @handle: Menu_Map - The campaign menu handle
 * @menuaction: action - The action the user has taken on the menu
 * @param: Client - The Client using the menu
 * @param: position - The name of the campaign chosen
 *
 */
public MenuHandler_Map(Handle: Menu_Map, MenuAction: action, Client, position)
{
	if (action == MenuAction_Select)
	{
		// Get the chosen map name
		decl String: map_file[64];
		GetMenuItem(Menu_Map, position, map_file, sizeof(map_file));

		// Change the map and gamemode
		ForceChangeLevel(map_file, "[L4D/2] Campaign Manager");
		decl String: l4d_gamemode[64];
		GetConVarString(FindConVar("mp_gamemode"), l4d_gamemode, sizeof(l4d_gamemode));
		if (!StrEqual(l4d_gamemode, gamemode, false))
		{
			ServerCommand("sm_cvar mp_gamemode %s", gamemode);
		}
	}
}

/**
 * Builds the campaign menu
 *
 * @handle: array - The gamemode array handle
 * @handle: menu - The menu handle
 *
 */
BuildMenu(Handle: array, Handle: menu)
{
	// Setup strings
	decl String: buffer[256];
	decl String: campaign_name[64];

	// Loop through the coop maps
	new array_size = GetArraySize(array);
	for (new i = 0; i < array_size; i++)
	{
		// Get the mission file
		GetArrayString(array, i, buffer, sizeof(buffer));

		// Setup the keyvalues
		new Handle: kv = CreateKeyValues("mission");
		FileToKeyValues(kv, buffer);

		// Get the name of the campaign and translate it if needed
		KvGetString(kv, "DisplayTitle", campaign_name, sizeof(campaign_name));
		if (StrContains(campaign_name, "#L4D", true) != -1)
		{
			Format(campaign_name, sizeof(campaign_name), "%T", campaign_name, LANG_SERVER);
			AddMenuItem(menu, buffer, campaign_name);
		}
		else
		{
			AddMenuItem(menu, buffer, campaign_name);
		}

		// Always close the handle
		CloseHandle(kv);
	}
}

/**
 * Builds the map menu
 *
 * @handle: menu - The handle to the menu
 * @param: file_name - The file name we need to open
 *
 */
BuildMenuHandler(Handle: menu, String: file_name[])
{
	// Create keyvalues
	new Handle: mission_file = CreateKeyValues("mission");
	FileToKeyValues(mission_file, file_name);

	// Get the name of the campaign and translate it if needed
	decl String: campaign_name[64];
	KvGetString(mission_file, "DisplayTitle", campaign_name, sizeof(campaign_name));
	if (StrContains(campaign_name, "#L4D", true) != -1)
	{
		SetMenuTitle(menu, "%T:", campaign_name, LANG_SERVER);
	}
	else
	{
		SetMenuTitle(menu, "%s:", campaign_name);
	}

	// Get to the correct position
	KvJumpToKey(mission_file, "modes");
	KvJumpToKey(mission_file, gamemode);

	if (KvGotoFirstSubKey(mission_file))
	{
		LoadCampaignValues(mission_file, menu);
	}

	// Close the handle and display menu
	CloseHandle(mission_file);
}

/**
 * Loads the campaign names from the keyvalues
 *
 * @handle: kv - The keyvalue file handle
 * @handle: menu - Secondary handle needed to add menu items
 *
 */
LoadCampaignValues(Handle: kv, Handle: menu)
{
	// Setup strings
	decl String: map[64];
	decl String: map_name[64];

	do
	{
		// Get the name and map file
		KvGetString(kv, "DisplayName", map_name, sizeof(map_name));
		KvGetString(kv, "Map", map, sizeof(map));
		// If the map is valid continue
		if (!IsMapValid(map))
		{
			LogError("Map file, %s, is invalid", map);
			continue;
		}
		// If it needs to be translated, do so
		if (StrContains(map_name, "#L4D", true) != -1)
		{
			Format(map_name, sizeof(map_name), "%T", map_name, LANG_SERVER);
			AddMenuItem(menu, map, map_name);
		}
		else
		{
			AddMenuItem(menu, map, map_name);
		}
	} while (KvGotoNextKey(kv));
}