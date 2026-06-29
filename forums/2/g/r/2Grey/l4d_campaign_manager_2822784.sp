/**
 * [L4D/2] Campaign Manager
 * Created by Bigbuck
 */

/**
 * Thanks to DieTeetasse for German translation
 */

/**
	v1.0.0
	- Initial Release

	v1.0.1
	- Added German translations thanks to DieTeetasse
	- Updated translations to include missing strings
	- Added L4D2 teamversus, realism, and teamscavenge gamemodes
	- Gamemode is now changed based on what category you selected the map from

	v1.0.2
	- Removed sm_ from version cvar to conform with guidelines

	v1.0.3
	- Updated to support L4D2 DLC "The Passing"

	v1.0.4
	- Updated to support L4D2 DLC "The Sacrafice" and "No Mercy"
	- Added support for "Mutation" game mode
 */

// Force strict semicolon mode
#pragma semicolon 1
#pragma newdecls required

/**
 * Includes
 */
#include <sourcemod>
#include <sdktools>
// Make the admin menu plugin optional
#undef REQUIRE_PLUGIN
#include <adminmenu>

enum GameplayMode {
	GameplayMode_Coop			= 1,
	GameplayMode_Versus			= 2,
	GameplayMode_Survival		= 3,
	GameplayMode_Realism		= 4,
	GameplayMode_Scavenge		= 5,	
	GameplayMode_Mutation		= 6
}

/**
 * Handles
 */
// Admin menu handles
Handle Admin_Menu				= INVALID_HANDLE;

TopMenuObject Coop 				= INVALID_TOPMENUOBJECT;
TopMenuObject Versus 			= INVALID_TOPMENUOBJECT;
TopMenuObject Survival 			= INVALID_TOPMENUOBJECT;
TopMenuObject Realism 			= INVALID_TOPMENUOBJECT;
TopMenuObject Scavenge 			= INVALID_TOPMENUOBJECT;
TopMenuObject Mutation			= INVALID_TOPMENUOBJECT;

// Array handles
Handle	Array_Coop			= INVALID_HANDLE;
Handle	Array_Versus		= INVALID_HANDLE;
Handle	Array_Survival		= INVALID_HANDLE;
Handle	Array_Scavenge		= INVALID_HANDLE;
Handle	Array_Mutation		= INVALID_HANDLE;

/**
 * Global variables
 */
// Detects L4D2
bool game_l4d2 = false;

/**
 * Defines
 */
#define PLUGIN_VERSION	"1.1.0"
#define MISSION_PATH	"missions"

/**
 * Global variables
 *
 */
char gamemode[64];

/**
 * Plugin information
 *
 */
public Plugin myinfo =
{
	name = "[L4D/2] Campaign Manager",
	author = "Bigbuck",
	description = "Dynamically creates an admin menu for all campaigns installed on a server.",
	version = PLUGIN_VERSION,
	url = "http://bigbuck-sm.assembla.com/spaces/dashboard/index/bigbuck-sm"
};

/**
 * Setup plugins first run
 */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Require Left 4 Dead
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2) {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

	game_l4d2 = (engine == Engine_Left4Dead2);

	return APLRes_Success;
}

public void OnPluginStart()
{
	// Make sure the missions directory exists
	if (!DirExists(MISSION_PATH))
	{
		SetFailState("Missions directory does not exist on this server.  Campaign Manager cannot continue operation");
	}

	// Load translation file
	LoadTranslations("l4d_campaign_manager");

	// Load the admin menu
	Handle topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

/**
 * Called before a library is removed
 *
 * @string: name - The name of the library
 */
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu")) {
		Admin_Menu = INVALID_HANDLE;
	}
}

/**
 * Called when the admin menu is ready
 *
 * @handle: topmenu - The admin menu handle
 */
public void OnAdminMenuReady(Handle topmenu)
{
	// Block us from being called twice
	if (topmenu == Admin_Menu) {
		return;
	}

	Admin_Menu = topmenu;

	char cm_title[30];
	Format(cm_title, sizeof(cm_title), "%T", "CM_Title", LANG_SERVER);

	// Add the ZA menu to the SM menu
	AddToTopMenu(Admin_Menu, cm_title, TopMenuObject_Category, MenuHandler_Top, INVALID_TOPMENUOBJECT);
	// Create a menu object for us so we can add items to our menu
	TopMenuObject CM_Menu = FindTopMenuCategory(Admin_Menu, cm_title);
	// Make sure what we just created is not invalid
	if (CM_Menu == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	// Setup correct categories and arrays
	Coop 			= AddToTopMenu(Admin_Menu, "cm_coop",		TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_coop",		ADMFLAG_CHANGEMAP);
	Versus 			= AddToTopMenu(Admin_Menu, "cm_versus",		TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_versus",		ADMFLAG_CHANGEMAP);
	Survival 		= AddToTopMenu(Admin_Menu, "cm_survival",	TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_survival",	ADMFLAG_CHANGEMAP);

	Array_Coop 		= CreateArray(32);
	Array_Versus 	= CreateArray(32);
	Array_Survival	= CreateArray(32);

	if (game_l4d2) {
		Realism 		= AddToTopMenu(Admin_Menu, "cm_realism", 		TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_realism",		ADMFLAG_CHANGEMAP);
		Scavenge		= AddToTopMenu(Admin_Menu, "cm_scavenge", 		TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_scavenge", 		ADMFLAG_CHANGEMAP);
		Mutation		= AddToTopMenu(Admin_Menu, "cm_mutation_10", 	TopMenuObject_Item, MenuHandler_TopItems, CM_Menu, "cm_mutation_10", 	ADMFLAG_CHANGEMAP);

		Array_Scavenge	= CreateArray(32);
		Array_Mutation	= CreateArray(32);
	}

	// Open the missions directory
	DirectoryListing missions_dir = OpenDirectory(MISSION_PATH);
	if (missions_dir == INVALID_HANDLE) {
		SetFailState("Cannot open missions directory");
	}

	// Setup strings
	char buffer[256];
	char full_path[256];
	char campaign_mode[64];

	// Loop through all the files
	while(missions_dir.GetNext(buffer, sizeof(buffer)))
	{
		// Skip folders and credits file
		if (DirExists(buffer) || StrEqual(buffer, "credits.txt", false) || StrEqual(buffer, ".", false) || StrEqual(buffer, "..", false))
		{
			continue;
		}

		// Create the keyvalues
		Format(full_path, sizeof(full_path), "%s/%s", MISSION_PATH, buffer);
		
		KeyValues missions_kv = CreateKeyValues("mission");
		missions_kv.ImportFromFile(full_path);

		// Get to correct position so we can start our loop
		missions_kv.JumpToKey("modes", false);
		missions_kv.GotoFirstSubKey();

		do
		{
			// First get the section name
			missions_kv.GetSectionName(campaign_mode, sizeof(campaign_mode));
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
			else if (StrEqual(campaign_mode, "mutation10", true)) {
				PushArrayString(Array_Mutation, full_path);
			}
		} while (missions_kv.GotoNextKey());
		
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
 */
void MenuHandler_Top(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "%T:", "CM_Title", LANG_SERVER);
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "CM_Title", LANG_SERVER);
	}
}

/**
 * Handles the CM top menu items
 *
 * @handle: topmenu - The top menu handle
 * @topmenuaction: action - The top menu action being performed
 * @topmenuobject: object_id - The top menu object being changes
 * @string: buffer - Buffer for translations
 */
void MenuHandler_TopItems(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == Coop)
		{
			GameplayModeTitle(GameplayMode_Coop, buffer, maxlength);
		}
		else if (object_id == Versus)
		{
			GameplayModeTitle(GameplayMode_Versus, buffer, maxlength);
		}
		else if (object_id == Survival)
		{
			GameplayModeTitle(GameplayMode_Survival, buffer, maxlength);
		}
		else if (object_id == Realism)
		{
			GameplayModeTitle(GameplayMode_Realism, buffer, maxlength);
		}
		else if (object_id == Scavenge)
		{
			GameplayModeTitle(GameplayMode_Scavenge, buffer, maxlength);
		}
		else if (object_id == Mutation)
		{
			GameplayModeTitle(GameplayMode_Mutation, buffer, maxlength);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == Coop)
		{
			GameModeMenu(GameplayMode_Coop, client);
		}
		else if (object_id == Versus)
		{
			GameModeMenu(GameplayMode_Versus, client);
		}
		else if (object_id == Survival)
		{
			GameModeMenu(GameplayMode_Survival, client);
		}
		else if (object_id == Realism)
		{
			GameModeMenu(GameplayMode_Realism, client);
		}
		else if (object_id == Scavenge)
		{
			GameModeMenu(GameplayMode_Scavenge, client);
		}
		else if (object_id == Mutation)
		{
			GameModeMenu(GameplayMode_Mutation, client);
		}
	}
}

// MARK: - Game mode menu

Action GameModeMenu(GameplayMode gameMode, int client)
{
	Menu menu = CreateMenu(GameplayModeMenuHandler(gameMode));

	char title[30];
	GameplayModeTitle(gameMode, title, sizeof(title));
	Format(title, sizeof(title), "%s:", title);
	menu.SetTitle(title);

	BuildMenu(GameplayModeMapArray(gameMode), menu);
	menu.Display(client, 20);

	return Plugin_Handled;
}

// MARK: - Menu Handlers

int MenuHandler_Coop(Menu coopMenu, MenuAction action, int client, int position)
{
	return GameModeHandler("coop", coopMenu, action, client, position);
}

int MenuHandler_Versus(Menu versusMenu, MenuAction action, int client, int position)
{
	return GameModeHandler("versus", versusMenu, action, client, position);
}

int MenuHandler_Survival(Menu survivalMenu, MenuAction action, int client, int position)
{
	return GameModeHandler("survival", survivalMenu, action, client, position);
}

int MenuHandler_Realism(Menu realismMenu, MenuAction action, int client, int position)
{
	return GameModeHandler("realism", realismMenu, action, client, position);
}

int MenuHandler_Scavenge(Menu scavengeMenu, MenuAction action, int client, int position)
{
	return GameModeHandler("scavenge", scavengeMenu, action, client, position);
}

int MenuHandler_Mutation(Menu mutationMenu, MenuAction action, int client, int position)
{
	return GameModeHandler("mutation10", mutationMenu, action, client, position);
}

int GameModeHandler(char gameMode[64], Menu topMenu, MenuAction action, int client, int position)
{
	if (action != MenuAction_Select) return 0;

	Menu menu = CreateMenu(MenuHandler_Map);
	char file[64];
	GetMenuItem(topMenu, position, file, sizeof(file));
	
	gamemode = gameMode;
	BuildMenuHandler(menu, file);
	menu.Display(client, 20);

	return 0;
}

/**
 * CM map menu handler
 *
 * @handle: Menu_Map - The campaign menu handle
 * @menuaction: action - The action the user has taken on the menu
 * @param: Client - The Client using the menu
 * @param: position - The name of the campaign chosen
 */
int MenuHandler_Map(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		// Get the chosen map name
		char map_file[64];
		menu.GetItem(position, map_file, sizeof(map_file));

		// Change the map and gamemode
		ForceChangeLevel(map_file, "[L4D/2] Campaign Manager");
		
		char l4d_gamemode[64];
		GetConVarString(FindConVar("mp_gamemode"), l4d_gamemode, sizeof(l4d_gamemode));

		if (!StrEqual(l4d_gamemode, gamemode, false)) {
			ServerCommand("sm_cvar mp_gamemode %s", gamemode);
		}
	}

	return 0;
}

// MARK: - Build

void BuildMenu(Handle array, Menu menu)
{
	// Setup strings
	char buffer[256];
	char campaign_name[64];

	// Loop through the coop maps
	int arraySize = GetArraySize(array);
	for (int i = 0; i < arraySize; i++)
	{
		// Get the mission file
		GetArrayString(array, i, buffer, sizeof(buffer));

		// Setup the keyvalues
		KeyValues kv = CreateKeyValues("mission");
		kv.ImportFromFile(buffer);

		// Get the name of the campaign and translate it if needed
		kv.GetString("DisplayTitle", campaign_name, sizeof(campaign_name));
		if (StrContains(campaign_name, "#L4D", true) != -1) {
			Format(campaign_name, sizeof(campaign_name), "%T", campaign_name, LANG_SERVER);
		}
		menu.AddItem(buffer, campaign_name);

		// Always close the handle
		CloseHandle(kv);
	}
}

void BuildMenuHandler(Menu menu, const char[] file_name)
{
	// Create keyvalues
	KeyValues mission_file = CreateKeyValues("mission");
	mission_file.ImportFromFile(file_name);

	// Get the name of the campaign and translate it if needed
	char campaign_name[64];
	mission_file.GetString("DisplayTitle", campaign_name, sizeof(campaign_name));

	if (StrContains(campaign_name, "#L4D", true) != -1) {
		SetMenuTitle(menu, "%T:", campaign_name, LANG_SERVER);
	} else {
		SetMenuTitle(menu, "%s:", campaign_name);
	}

	// Get to the correct position
	mission_file.JumpToKey("modes");
	mission_file.JumpToKey(gamemode);

	if (mission_file.GotoFirstSubKey()) {
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
 */
void LoadCampaignValues(KeyValues kv, Menu menu)
{
	// Setup strings
	char map[64];
	char map_name[64];

	do
	{
		// Get the name and map file
		kv.GetString("DisplayName", map_name, sizeof(map_name));
		kv.GetString("Map", map, sizeof(map));
		// If the map is valid continue
		if (!IsMapValid(map)) {
			LogError("Map file, %s, is invalid", map);
			continue;
		}
		// If it needs to be translated, do so
		if (StrContains(map_name, "#L4D", true) != -1) {
			Format(map_name, sizeof(map_name), "%T", map_name, LANG_SERVER);
		}
		menu.AddItem(map, map_name);
	} while (kv.GotoNextKey());
}

// MARK: - Enum helpers

void GameplayModeTitle(GameplayMode mode, char[] result, int maxLen)
{
	switch (mode) {
		case GameplayMode_Coop:		Format(result, maxLen, "%T", "CM_GameMode_Coop", LANG_SERVER);
		case GameplayMode_Versus:	Format(result, maxLen, "%T", "CM_GameMode_Versus", LANG_SERVER);
		case GameplayMode_Survival:	Format(result, maxLen, "%T", "CM_GameMode_Survival", LANG_SERVER);
		case GameplayMode_Realism:	Format(result, maxLen, "%T", "CM_GameMode_Realism", LANG_SERVER);
		case GameplayMode_Scavenge: Format(result, maxLen, "%T", "CM_GameMode_Scavenge", LANG_SERVER);
		case GameplayMode_Mutation: Format(result, maxLen, "%T", "CM_GameMode_Mutation", LANG_SERVER);
		default: Format(result, maxLen, "%s", "Unknown");
	}
}

MenuHandler GameplayModeMenuHandler(GameplayMode mode)
{
	switch (mode) {
		case GameplayMode_Coop:		return MenuHandler_Coop;
		case GameplayMode_Versus:	return MenuHandler_Versus;
		case GameplayMode_Survival:	return MenuHandler_Survival;
		case GameplayMode_Realism:	return MenuHandler_Realism;
		case GameplayMode_Scavenge: return MenuHandler_Scavenge;
		case GameplayMode_Mutation: return MenuHandler_Mutation;
		default: return MenuHandler_Coop;
	}
}

Handle GameplayModeMapArray(GameplayMode mode)
{
	switch (mode) {
		case GameplayMode_Coop:		return Array_Coop;
		case GameplayMode_Versus:	return Array_Versus;
		case GameplayMode_Survival:	return Array_Survival;
		case GameplayMode_Realism:	return Array_Coop;
		case GameplayMode_Scavenge: return Array_Scavenge;
		case GameplayMode_Mutation: return Array_Mutation;
		default: return Array_Coop;
	}
}

void GameplayModeToStr(GameplayMode mode, char[] result, int maxLen)
{
	switch (mode) {
		case GameplayMode_Coop:		Format(result, maxLen, "%s", "coop");
		case GameplayMode_Versus:	Format(result, maxLen, "%s", "versus");
		case GameplayMode_Survival:	Format(result, maxLen, "%s", "survival");
		case GameplayMode_Realism:	Format(result, maxLen, "%s", "realism");
		case GameplayMode_Scavenge: Format(result, maxLen, "%s", "scavenge");
		case GameplayMode_Mutation: Format(result, maxLen, "%s", "mutation10");
		default: Format(result, maxLen, "%s", "coop");
	}

}

