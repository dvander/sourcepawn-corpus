/**
* CS:GO Skins Chooser by Root, updated version by Kuristaja (kuristaja08@luukku.com)
*
* Description:
*   Changes player skin and appropriate arms on the fly without editing any configuration files.
*
* Version 1.2.4
* Changelog & more info at http://goo.gl/4nKhJ
*/

// ====[ INCLUDES ]==========================================================================
#include <sdktools>
#include <cstrike>
#undef REQUIRE_PLUGIN
#tryinclude <updater>

// ====[ CONSTANTS ]=========================================================================
#define PLUGIN_NAME     "CS:GO Skins Chooser"
#define PLUGIN_VERSION  "1.2.4"
#define UPDATE_URL      "https://raw.github.com/zadroot/CSGO_SkinsChooser/master/updater.txt"
#define MAX_SKINS_COUNT 100
#define MAX_SKIN_LENGTH PLATFORM_MAX_PATH + 1
#define RANDOM_SKIN     -1

// ====[ VARIABLES ]=========================================================================
new	Handle:sc_enable     	= INVALID_HANDLE,
	Handle:sc_random     	= INVALID_HANDLE,
	Handle:sc_changetype 	= INVALID_HANDLE,
	Handle:sc_spawnmenu 	= INVALID_HANDLE,
	Handle:sc_admflag    	= INVALID_HANDLE,
	Handle:t_skins_menu  	= INVALID_HANDLE,
	Handle:ct_skins_menu 	= INVALID_HANDLE,
	String:TerrorSkin[MAX_SKINS_COUNT][MAX_SKIN_LENGTH],
	String:TerrorArms[MAX_SKINS_COUNT][MAX_SKIN_LENGTH],
	String:CTerrorSkin[MAX_SKINS_COUNT][MAX_SKIN_LENGTH],
	String:CTerrorArms[MAX_SKINS_COUNT][MAX_SKIN_LENGTH],
	TSkins_Count, CTSkins_Count, Selected[MAXPLAYERS + 1] = {RANDOM_SKIN, ...};

// ====[ PLUGIN ]============================================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "Simply stock skin chooser for CS:GO",
	version     = PLUGIN_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=1889086"
}


/* OnPluginStart()
 *
 * When the plugin starts up.
 * ------------------------------------------------------------------------------------------ */
public OnPluginStart()
{
	// Create console variables
	CreateConVar("sm_csgo_skins_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	sc_enable     = CreateConVar("sm_csgo_skins_enable",  "1", "Whether or not enable CS:GO Skins Chooser plugin",                                   FCVAR_PLUGIN, true, 0.0, true, 1.0);
	sc_random     = CreateConVar("sm_csgo_skins_random",  "1", "Whether or not randomly change models for all players on every respawn\n2 = Once",   FCVAR_PLUGIN, true, 0.0, true, 2.0);
	sc_changetype = CreateConVar("sm_csgo_skins_change",  "0", "Determines when change selected player skin:\n0 = On next respawn\n1 = Immediately", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	sc_spawnmenu  = CreateConVar("sm_csgo_skins_spawnmenu",  "0", "Whether or not show the skins menu on player spawn", 							 FCVAR_PLUGIN, true, 0.0, true, 1.0);
	sc_admflag    = CreateConVar("sm_csgo_skins_admflag", "",  "If flag is specified (a-z), only admins with that flag will able to use skins menu", FCVAR_PLUGIN);

	// Create/register client commands to setup player skins
	RegConsoleCmd("sm_skin",  Command_SkinsMenu);
	RegConsoleCmd("sm_skins", Command_SkinsMenu);
	RegConsoleCmd("sm_model", Command_SkinsMenu);
	
	// Hook skins-related player events
	HookEvent("player_spawn",      OnPlayerEvents, EventHookMode_Post);
	HookEvent("player_disconnect", OnPlayerEvents, EventHookMode_Post);

	// Create and exec plugin's configuration file
	AutoExecConfig(true, "csgo_skins");

#if defined _updater_included
	if (LibraryExists("updater"))
	{
		// Adds plugin to the updater
		Updater_AddPlugin(UPDATE_URL);
	}
#endif
}

/* OnMapStart()
 *
 * When the map starts.
 * ------------------------------------------------------------------------------------------ */
public OnMapStart()
{
	// Declare string to load skin's config from sourcemod/configs folder
	decl String:file[PLATFORM_MAX_PATH], String:curmap[PLATFORM_MAX_PATH];
	GetCurrentMap(curmap, sizeof(curmap));

	// Does current map string contains a "workshop" prefix at a start?
	if (strncmp(curmap, "workshop", 8) == 0)
	{
		// If yes - skip the first 19 characters to avoid comparing the "workshop/12345678" prefix
		BuildPath(Path_SM, file, sizeof(file), "configs/skins/%s.cfg", curmap[19]);
	}
	else /* That's not a workshop map */
	{
		// Let's check that custom skin configuration file is exists for current map
		BuildPath(Path_SM, file, sizeof(file), "configs/skins/%s.cfg", curmap);
	}

	// Unfortunately config for current map is not exists
	if (!FileExists(file))
	{
		// Then use default one
		BuildPath(Path_SM, file, sizeof(file), "configs/skins/any.cfg");

		// Disable plugin if no generic config is avaliable
		if (!FileExists(file))
		{
			SetFailState("Fatal error: Unable to open generic configuration file \"%s\"!", file);
		}
	}

	// Refresh menus, config and downloads
	InitDownloadsList();
	PrepareMenus();
	PrepareConfig(file);
}

#if defined _updater_included
/* OnLibraryAdded()
 *
 * Called after a library is added that the current plugin references.
 * ------------------------------------------------------------------------------------------ */
public OnLibraryAdded(const String:name[])
{
	// Updater
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
#endif

/* OnPlayerEvents()
 *
 * Called when player spawns or disconnects from a server.
 * ------------------------------------------------------------------------------------------ */
public OnPlayerEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Does plugin is enabled?
	if (GetConVarBool(sc_enable))
	{
		// Get real player index from event key
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new random = GetConVarInt(sc_random);

		// player_spawn event was fired
		if (name[7] == 's')
		{
			// Make sure player is valid and not controlling a bot
			if (IsValidClient(client) && (random || !GetEntProp(client, Prop_Send, "m_bIsControllingBot")))
			{
				new team  = GetClientTeam(client);
				new model = Selected[client];
				
				if (GetConVarBool(sc_spawnmenu))
				{
					if (IsClientInGame(client) && ! IsFakeClient(client))
					{
						Command_SkinsMenu(client, -1);
					}
				}
				
				// Get same random number for using same arms and skin
				new trandom  = GetRandomInt(0, TSkins_Count  - 1);
				new ctrandom = GetRandomInt(0, CTSkins_Count - 1);

				// Change player skin to random only once
				if (random == 2 && model == RANDOM_SKIN)
				{
					// And assign random model
					Selected[client] = (team == CS_TEAM_T ? trandom : ctrandom);
				}

				// Set skin depends on client's team
				switch (team)
				{
					case CS_TEAM_T: // Terrorists
					{
						// If random model should be accepted, get random skin of all avalible skins
						if (random == 1 && model == RANDOM_SKIN)
						{
							SetEntityModel(client, TerrorSkin[trandom]);

							// Same random int
							SetEntPropString(client, Prop_Send, "m_szArmsModel", TerrorArms[trandom]);
							
							// Change arms only for real clients, not bots
							if (IsClientInGame(client) && ! IsFakeClient(client))
							{
								CreateTimer(0.15, RemoveItemTimer, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						else if (RANDOM_SKIN < model < TSkins_Count)
						{
							SetEntityModel(client, TerrorSkin[model]);
							SetEntPropString(client, Prop_Send, "m_szArmsModel", TerrorArms[model]);
							
							if (IsClientInGame(client) && ! IsFakeClient(client))
							{
								CreateTimer(0.15, RemoveItemTimer, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
					case CS_TEAM_CT: // Counter-Terrorists
					{
						// Also make sure that player havent chosen any skin yet
						if (random == 1 && model == RANDOM_SKIN)
						{
							SetEntityModel(client, CTerrorSkin[ctrandom]);
							SetEntPropString(client, Prop_Send, "m_szArmsModel", CTerrorArms[ctrandom]);
							
							if (IsClientInGame(client) && ! IsFakeClient(client))
							{
								CreateTimer(0.15, RemoveItemTimer, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
							}
						}

						// Model index must be valid (more than map default and less than max)
						else if (RANDOM_SKIN < model < CTSkins_Count)
						{
							// And set the model
							SetEntityModel(client, CTerrorSkin[model]);
							SetEntPropString(client, Prop_Send, "m_szArmsModel", CTerrorArms[model]);
							
							if (IsClientInGame(client) && ! IsFakeClient(client))
							{
								CreateTimer(0.15, RemoveItemTimer, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
				}
			}
		}
		else Selected[client] = RANDOM_SKIN; // Reset skin on player_disconnect
	}
}

// Timers for updating the viewmodel arms
public Action:RemoveItemTimer(Handle:timer, any:ref)
{
	new client = EntRefToEntIndex(ref);
	
	if (client != INVALID_ENT_REFERENCE)
	{
		new item = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (item > 0)
		{
			RemovePlayerItem(client, item);
			
			new Handle:ph=CreateDataPack();
			WritePackCell(ph, EntIndexToEntRef(client));
			WritePackCell(ph, EntIndexToEntRef(item));
			CreateTimer(0.15 , AddItemTimer, ph, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:AddItemTimer(Handle:timer, any:ph)
{  
	new client, item;
	
	ResetPack(ph);
	
	client = EntRefToEntIndex(ReadPackCell(ph));
	item = EntRefToEntIndex(ReadPackCell(ph));
	
	if (client != INVALID_ENT_REFERENCE && item != INVALID_ENT_REFERENCE)
	{
		EquipPlayerWeapon(client, item);
	}
}

/* Command_SkinsMenu()
 *
 * Shows skin's menu to a player.
 * ------------------------------------------------------------------------------------------ */
public Action:Command_SkinsMenu(client, args)
{
	if (GetConVarBool(sc_enable))
	{
		// Once again make sure that client is valid
		if (IsValidClient(client) && (IsPlayerAlive(client) || !GetConVarBool(sc_changetype)))
		{
			// Get flag name from convar string and get client's access
			decl String:admflag[AdminFlags_TOTAL], AdmFlag;
			GetConVarString(sc_admflag, admflag, sizeof(admflag));

			// Converts a string of flag characters to a bit string
			AdmFlag = ReadFlagString(admflag);

			// Check if player is having any access (including skins overrides)
			if (AdmFlag == 0
			||  AdmFlag != 0 && CheckCommandAccess(client, "csgo_skins_override", AdmFlag, true))
			{
				// Show individual skin menu depends on client's team
				switch (GetClientTeam(client))
				{
					case CS_TEAM_T:  if (t_skins_menu  != INVALID_HANDLE) DisplayMenu(t_skins_menu,  client, 20);
					case CS_TEAM_CT: if (ct_skins_menu != INVALID_HANDLE) DisplayMenu(ct_skins_menu, client, 20);
				}
			}
			else if (! args)
			{
				PrintToChat(client, "You have no access to the skins menu!");
			}
		}
	}

	// That thing fixing 'unknown command' in client console on command call
	return Plugin_Handled;
}

/* MenuHandler_ChooseSkin()
 *
 * Menu to set player's skin.
 * ------------------------------------------------------------------------------------------ */
public MenuHandler_ChooseSkin(Handle:menu, MenuAction:action, client, param)
{
	// Called when player pressed something in a menu
	if (action == MenuAction_Select)
	{
		// Don't use any other value than 10, otherwise you may crash clients and a server
		decl String:skin_id[10];
		GetMenuItem(menu, param, skin_id, sizeof(skin_id));

		// Make sure we havent selected random skin
		if (!StrEqual(skin_id, "Random"))
		{
			// Get skin number
			new skin = StringToInt(skin_id, sizeof(skin_id));

			// Correct. So lets save the selected skin
			Selected[client] = skin;

			// Set player model and arms immediately
			if (GetConVarBool(sc_changetype))
			{
				// Depends on client team obviously
				switch (GetClientTeam(client))
				{
					case CS_TEAM_T:
					{
						SetEntityModel(client, TerrorSkin[skin]);
						SetEntPropString(client, Prop_Send, "m_szArmsModel", TerrorArms[skin]);
						
						if (IsClientInGame(client) && ! IsFakeClient(client))
						{
							CreateTimer(0.15, RemoveItemTimer, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
						}
					}
					case CS_TEAM_CT:
					{
						SetEntityModel(client, CTerrorSkin[skin]);
						SetEntPropString(client, Prop_Send, "m_szArmsModel", CTerrorArms[skin]);
						
						if (IsClientInGame(client) && ! IsFakeClient(client))
						{
							CreateTimer(0.15, RemoveItemTimer, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
		else Selected[client] = RANDOM_SKIN;
	}
}

/* PrepareConfig()
 *
 * Adds skins to a menu, makes limits for allowed skins
 * ------------------------------------------------------------------------------------------ */
PrepareConfig(const String:file[])
{
	// Creates a new KeyValues structure to setup player skins
	new Handle:kv = CreateKeyValues("Skins");

	// Convert given file to a KeyValues tree
	FileToKeyValues(kv, file);

	// Get 'Terrorists' section
	if (KvJumpToKey(kv, "Terrorists"))
	{
		decl String:section[MAX_SKINS_COUNT], String:skin[MAX_SKINS_COUNT], String:arms[MAX_SKINS_COUNT], String:skin_id[3];

		// Sets the current position in the KeyValues tree to the first sub key
		KvGotoFirstSubKey(kv);

		do
		{
			// Get current section name
			KvGetSectionName(kv, section, sizeof(section));

			// Also make sure we've got 'skin' and 'arms' sections
			if (KvGetString(kv, "skin", skin, sizeof(skin)))
			{
				KvGetString(kv, "arms", arms, sizeof(arms));				
				if (StrEqual(arms, "")) arms = "models/weapons/t_arms_leet.mdl";

				// Copy the full path of skin from config and save it
				strcopy(TerrorSkin[TSkins_Count], sizeof(TerrorSkin[]), skin);
				strcopy(TerrorArms[TSkins_Count], sizeof(TerrorArms[]), arms);

				Format(skin_id, sizeof(skin_id), "%d", TSkins_Count++);

				AddMenuItem(t_skins_menu, skin_id, section);

				// Precache every model (before mapchange) to prevent client crashes
				if (! IsModelPrecached(skin)) PrecacheModel(skin, true);
				
				// Precache arms too. Those will not crash client, but arms will not be shown at all
				if (! IsModelPrecached(arms)) PrecacheModel(arms, true);
			}
			else LogError("Player model for \"%s\" is incorrect!", section);
		}

		// Because we need to process all keys
		while (KvGotoNextKey(kv));
	}
	else SetFailState("Fatal error: Missing \"Terrorists\" section!");

	// Get back to the top
	KvRewind(kv);

	// Check CT config right now
	if (KvJumpToKey(kv, "Counter-Terrorists"))
	{
		decl String:section[MAX_SKINS_COUNT], String:skin[MAX_SKINS_COUNT], String:arms[MAX_SKINS_COUNT], String:skin_id[3];

		KvGotoFirstSubKey(kv);

		// Lets begin
		do
		{
			KvGetSectionName(kv, section, sizeof(section));

			if (KvGetString(kv, "skin", skin, sizeof(skin)))
			{
				KvGetString(kv, "arms", arms, sizeof(arms));				
				if (StrEqual(arms, "")) arms = "models/weapons/ct_arms_st6.mdl";
				
				strcopy(CTerrorSkin[CTSkins_Count], sizeof(CTerrorSkin[]), skin);
				strcopy(CTerrorArms[CTSkins_Count], sizeof(CTerrorArms[]), arms);

				// Calculate number of avalible CT skins
				Format(skin_id, sizeof(skin_id), "%d", CTSkins_Count++);

				// Add every section as a menu item
				AddMenuItem(ct_skins_menu, skin_id, section);

				// Precache every model (before mapchange) to prevent client crashes
				if (! IsModelPrecached(skin)) PrecacheModel(skin, true);
				
				// Precache arms too. Those will not crash client, but arms will not be shown at all
				if (! IsModelPrecached(arms)) PrecacheModel(arms, true);
			}

			// Something is wrong
			else LogError("Player model for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(kv));
	}
	else SetFailState("Fatal error: Missing \"Counter-Terrorists\" section!");

	KvRewind(kv);

	// Local handles must be freed
	CloseHandle(kv);
}

// Prepare downloads
public InitDownloadsList()
{
 	if (FileExists("addons/sourcemod/configs/skins/downloads.ini"))
	{
		new String:line[MAX_SKIN_LENGTH];
		new Handle:fileHandle=OpenFile("addons/sourcemod/configs/skins/downloads.ini","r");

		new entries = -1;

		while(! IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, line, sizeof(line)))
		{
			// Remove whitespaces and empty lines
			TrimString(line);
			ReplaceString(line, sizeof(line), " ", "", false);
		
			// Skip comments
			if (line[0] != '/')
			{
				if (FileExists(line, true))
				{
					AddFileToDownloadsTable(line);
					entries++;
				}
			}
		}
		CloseHandle(fileHandle);
	}
}

/* PrepareMenus()
 *
 * Create menus if config is valid.
 * ------------------------------------------------------------------------------------------ */
PrepareMenus()
{
	// Firstly zero out amount of avalible skins
	TSkins_Count = CTSkins_Count = 0;

	// Then safely close menu handles
	if (t_skins_menu != INVALID_HANDLE)
	{
		CloseHandle(t_skins_menu);
		t_skins_menu = INVALID_HANDLE;
	}
	if (ct_skins_menu != INVALID_HANDLE)
	{
		CloseHandle(ct_skins_menu);
		ct_skins_menu = INVALID_HANDLE;
	}

	// Create specified menus depends on client teams
	t_skins_menu  = CreateMenu(MenuHandler_ChooseSkin, MenuAction_Select);
	ct_skins_menu = CreateMenu(MenuHandler_ChooseSkin, MenuAction_Select);

	// And dont forget to set the menu's titles
	SetMenuTitle(t_skins_menu,  "Choose your Terrorist skin:");
	SetMenuTitle(ct_skins_menu, "Choose your Counter-Terrorist skin:");

	if (GetConVarBool(sc_random))
	{
		AddMenuItem(t_skins_menu,  "Random", "Random");
		AddMenuItem(ct_skins_menu, "Random", "Random");
	}
}

/* IsValidClient()
 *
 * Checks if a client is valid.
 * ------------------------------------------------------------------------------------------ */
bool:IsValidClient(client) return (1 <= client <= MaxClients && IsClientInGame(client)) ? true : false;