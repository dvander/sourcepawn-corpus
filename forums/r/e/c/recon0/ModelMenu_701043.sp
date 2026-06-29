#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

//#define DEBUG

// Holds the main menu
new Handle:mainmenu;
new Handle:kv;
new Handle:playermodelskv;

// Holds the auth ids
new String:authid[MAXPLAYERS + 1][35];

// Holds access flags between menus
new String:accessFlags[MAXPLAYERS + 1][5];

new Handle:hGameConf;
new Handle:hSetModel;

// Admin flag letters array
// Credit: From the SourceBans plugin
new AdminFlag:g_FlagLetters[26];

#define PLUGIN_VERSION "1.2.7"


public Plugin:myinfo = 
{
	name = "Model Menu",
	author = "pRED*, Recon, tigerox",
	description = "Menu to select player models",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	// Create the model menu command
	RegConsoleCmd("sm_models",Command_Model);
	
	// Create the vresion cvar
	CreateConVar("sm_modelmenu_version", PLUGIN_VERSION, "ModelMenu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Load the game data file
	hGameConf = LoadGameConfigFile("modelmenu.gamedata");
	
	// Hook the spawn event
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	// Model changing SDK call
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetModel");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	hSetModel = EndPrepSDKCall();
	
	// Load the player's model settings
	new String:file[256];
	BuildPath(Path_SM, file, 255, "data/playermodels.ini");
	playermodelskv = CreateKeyValues("Models");
	FileToKeyValues(playermodelskv, file);
	
	// Create the flag letters array
	// Credit: From the SourceBans plugin
	g_FlagLetters['a'-'a'] = Admin_Reservation;
	g_FlagLetters['b'-'a'] = Admin_Generic;
	g_FlagLetters['c'-'a'] = Admin_Kick;
	g_FlagLetters['d'-'a'] = Admin_Ban;
	g_FlagLetters['e'-'a'] = Admin_Unban;
	g_FlagLetters['f'-'a'] = Admin_Slay;
	g_FlagLetters['g'-'a'] = Admin_Changemap;
	g_FlagLetters['h'-'a'] = Admin_Convars;
	g_FlagLetters['i'-'a'] = Admin_Config;
	g_FlagLetters['j'-'a'] = Admin_Chat;
	g_FlagLetters['k'-'a'] = Admin_Vote;
	g_FlagLetters['l'-'a'] = Admin_Password;
	g_FlagLetters['m'-'a'] = Admin_RCON;
	g_FlagLetters['n'-'a'] = Admin_Cheats;
	g_FlagLetters['o'-'a'] = Admin_Custom1;
	g_FlagLetters['p'-'a'] = Admin_Custom2;
	g_FlagLetters['q'-'a'] = Admin_Custom3;
	g_FlagLetters['r'-'a'] = Admin_Custom4;
	g_FlagLetters['s'-'a'] = Admin_Custom5;
	g_FlagLetters['t'-'a'] = Admin_Custom6;
	g_FlagLetters['z'-'a'] = Admin_Root;
}

public OnPluginEnd()
{
	// Write the the player's model settings
	new String:file[256];
	BuildPath(Path_SM, file, 255, "data/playermodels.ini");
	KeyValuesToFile(playermodelskv, file);
	CloseHandle(playermodelskv);
}

public OnMapStart()
{
	// Create the main menu
	mainmenu = BuildMainMenu();
	
	//open precache file and add everything to download table
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/modeldownloads.ini");
	new Handle:fileh = OpenFile(file, "r");
	new String:buffer[256];
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		new len = strlen(buffer);
		if (buffer[len-1] == '\n')
   			buffer[--len] = '\0';
   			
		if (FileExists(buffer))
		{
			#if defined DEBUG
				LogMessage("Adding file \"%s\" to the download table.", buffer);
			#endif
			
			AddFileToDownloadsTable(buffer);
		}
		
		if (IsEndOfFile(fileh))
			break;
	}
}

Handle:BuildMainMenu()
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Group);
	
	// Load the list of models
	kv = CreateKeyValues("Commands");
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/models.ini");
	FileToKeyValues(kv, file);
	
	// Make sure there is at least one model group
	if (!KvGotoFirstSubKey(kv))
	{
		return INVALID_HANDLE;
	}
	
	// Load the model groups
	decl String:buffer[30];	
	do
	{
		// Get the model group name and add it to the menu
		KvGetSectionName(kv, buffer, sizeof(buffer));		
		AddMenuItem(menu,buffer,buffer);
		
		// Load the models for each team
		LoadModels("Team1");
		LoadModels("Team2");
	} 
	while (KvGotoNextKey(kv));
	
	// Rewind the KVs
	KvRewind(kv);
	
	// tigerox
	// Add the no model option
	AddMenuItem(menu,"none","None");
	
	// Se the menu title
	SetMenuTitle(menu, "Choose a Model");
	 
	// Return the menu
	return menu;
}

LoadModels(const String:team[])
{	
	// Get the team 1 models		
	if (KvJumpToKey(kv, team))
	{
		// Are there any models?
		if (KvGotoFirstSubKey(kv))
		{	
			// Holds the model path
			decl String:path[100];
			
			do
			{				
				// Get the path
				KvGetString(kv, "path", path, sizeof(path),"");
				
				// Make sure the model exists
				if (FileExists(path))
				{
					PrecacheModel(path, true);				
					AddFileToDownloadsTable(path);
				}
			} 
			while (KvGotoNextKey(kv));
			
			// Go back to the model group
			KvGoBack(kv);
			KvGoBack(kv);
		}
		else
		{
			// No, return to the model group
			KvGoBack(kv);
		}
	}	
}

public OnMapEnd()
{
	// Close the KV and main menu handles
	CloseHandle(kv);
	CloseHandle(mainmenu);
}

public OnClientPostAdminCheck(client)
{
	// Save the client auth string (steam)
	GetClientAuthString(client, authid[client], sizeof(authid[]));
}

public Action:Command_Model(client,args)
{
	// Do we have a valid model menu
	if (mainmenu == INVALID_HANDLE)
	{
		// We don't, send an error message and return
		PrintToConsole(client, "There was an error generating the menu. Check your models.ini file.");
		return Plugin_Handled;
	}
 
	// We have a valid menu, display it and return
	DisplayMenu(mainmenu, client, MENU_TIME_FOREVER);	
	return Plugin_Handled;
}

public Menu_Group(Handle:menu, MenuAction:action, param1, param2)
{
	// User has selected a model group
	if (action == MenuAction_Select)
	{
		new String:info[30];
		
		// Get the group they selected
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));		
			
		// Get the user's team
		new team = GetClientTeam(param1);
		
		if (!found)
			return;
				
		//tigeox
		// Check to see if the user has decided they don't want a model
		// (e.g. go to a stock model)
		if(StrEqual(info,"none"))
		{
			// Get the player's authid
			KvJumpToKey(playermodelskv,authid[param1],true);
		
			// Clear their saved model so that the next time
			// they spawn, they are able to use a stock model
			if (team == 2)
			{
				KvSetString(playermodelskv, "Team1", "");
				KvSetString(playermodelskv, "Team1Group", "");
			}
			else if (team == 3)
			{
				KvSetString(playermodelskv, "Team2", "");
				KvSetString(playermodelskv, "Team2Group", "");
			}
			
			// Rewind the KVs
			KvRewind(playermodelskv);
			
			// We don't need to go any further, return
			return;
		}			
		
		// User selected a group
		// advance kv to this group
		#if defined DEBUG
			LogMessage("User \"%L\" selected group \"%s\". Jumped? %i.", param1, info, KvJumpToKey(kv, info));
		#else
			KvJumpToKey(kv, info);
		#endif
		
		// Check if they have access 
		// to the selected model group
		new String:accessFlag[5];		
		KvGetString(kv,"Admin", accessFlag, sizeof(accessFlag));
		new bool:access = GetUserModelAccess(param1, accessFlag);
		new bool:validTeam = true;
		
		// If they have no access, show an error and return
		if (!access)
		{
			PrintToChat(param1,"Sorry, you do not have access to this model group.");
			return;
		}	
		
		// Check users team		
		if (team == 2)
		{
			// Show team 1 models
			KvJumpToKey(kv, "Team1");
		}
		else if (team == 3)
		{
			// Show team 2 models
			KvJumpToKey(kv, "Team2");
		}
		else
		{
			// Invalid team
			validTeam = false;
		}
			
		// Holds the menu
		new Handle:tempmenu = INVALID_HANDLE;
		
		// Get the first model		
		if (validTeam && KvGotoFirstSubKey(kv))
		{
			// Create the menu of models
			tempmenu = CreateMenu(Menu_Model);		

			// Add the models to the menu
			decl String:buffer[30];
			decl String:path[256];
			do
			{
				// Add the model to the menu
				KvGetSectionName(kv, buffer, sizeof(buffer));			
				KvGetString(kv, "path", path, sizeof(path),"");			
				AddMenuItem(tempmenu,path,buffer);
		
			} 
			while (KvGotoNextKey(kv));
			
			// Save the access flag
			accessFlags[param1] = accessFlag;
			
			// Set the menu title to the model group name
			SetMenuTitle(tempmenu, info);		
		}
		else
		{
			// No models in this group
			tempmenu = CreateMenu(Menu_DoNothing);
			AddMenuItem(tempmenu, "nomodel", "The selected group doesn't contain any models for your team.");
			SetMenuTitle(tempmenu, "No Models Available");			
		}
		
		// Rewind the KVs
		KvRewind(kv);
		
		// Display the menu
		DisplayMenu(tempmenu, param1, MENU_TIME_FOREVER);
	}
}

public Menu_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		// Close the menu handle
		CloseHandle(menu);	
	}
}

public Menu_Model(Handle:menu, MenuAction:action, param1, param2)
{
	// User choose a model	
	if (action == MenuAction_Select)
	{
		new String:info[256];
		new String:group[30];

		// Get the model's menu item
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		new team = GetClientTeam(param1);
		group = accessFlags[param1];
		
		if (!found)
			return;
			
		// Set the user's model
		#if defined DEBUG			
			LogMessage("Menu_Model | Model precached? %i | Client connected? %i | info is: %s |info equal to \"\"? %i.",
					   IsModelPrecached(info), IsClientConnected(param1), info, StrEqual(info,"", false));
		#endif
		if (!StrEqual(info,"", false) && IsModelPrecached(info) && IsClientConnected(param1))
		{
			// Set the model
			LogMessage("Setting Model for player \"%L\" to \"%s\".",param1,info);
			SDKCall(hSetModel, param1, info);
		}
		
		// Get the player's steam
		KvJumpToKey(playermodelskv,authid[param1], true);		
		
		// Save the user's choice so it is automatically applied
		// each time they spawn
		if (team == 2)
		{
			KvSetString(playermodelskv, "Team1", info);
			KvSetString(playermodelskv, "Team1Group", group);			
		}
		else if (team == 3)
		{
			KvSetString(playermodelskv, "Team2", info);
			KvSetString(playermodelskv, "Team2Group", group);
		}
		
		// Rewind the KVs
		KvRewind(playermodelskv);
	}
	
	// If they picked exit, close the menu handle
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Get the userid and client
	new clientId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientId);
	new clientTeam = GetClientTeam(client);
	
	#if defined DEBUG	
		LogMessage("Player \"%L\" spawned.", client);	
	#endif
	
	// Get the user's authid
	KvJumpToKey(playermodelskv,authid[client],true);
	
	new String:model[256];
	new String:group[30];
	
	// Get the user's model pref
	if (clientTeam == 2)
	{
		KvGetString(playermodelskv, "Team1", model, sizeof(model), "");
		KvGetString(playermodelskv, "Team1Group", group, sizeof(group), "");
	}
	else if (clientTeam == 3)
	{
		KvGetString(playermodelskv, "Team2", model, sizeof(model), "");
		KvGetString(playermodelskv, "Team2Group", group, sizeof(group), "");
	}
	
	// Find out if they still have access
	new bool:access = GetUserModelAccess(client, group);
	
	#if defined DEBUG	
		LogMessage("PlayerSpawn | Found model \"%s\", access %s for player \"%L\". Has access? %i.",
				   model, group, client, access);	
	#endif		
	
	// If they don't have access, show an error and return
	if (!access)
	{
		// Let the user know they no longer have access
		PrintToChat(client, "Sorry. You no longer have access to this model. Please select another using sm_models.");
		
		if (clientTeam == 2)
		{
			// Clear the player's model
			KvSetString(playermodelskv, "Team1", "");
			KvSetString(playermodelskv, "Team1Group", "");		
		}
		else if (clientTeam == 3)
		{
			// Clear the player's model
			KvSetString(playermodelskv, "Team2", "");
			KvSetString(playermodelskv, "Team2Group", "");		
		}
		
		return;
	}
	
	// Make sure that they have a valid model pref
	#if defined DEBUG
		LogMessage("PlayerSpawn | Model precached? %i | model is: %s | model equal to \"\"? %i.",
				   IsModelPrecached(model), model, StrEqual(model,"", false));
	#endif
	if (!StrEqual(model,"", false) && IsModelPrecached(model))
	{
		#if defined DEBUG	
			LogMessage("PlayerSpawn | Setting model \"%s\" for player \"%L\".", model, client);	
		#endif
		
		// Set the model
		SDKCall(hSetModel, client, model);
	}
	
	// Rewind the KVs
	KvRewind(playermodelskv);
}

bool:GetUserModelAccess(client, String:accessFlag[])
{
	// If no flag is required, return true
	if (StrEqual(accessFlag,""))
	{
		return true;
	}
	
	// Get the user's admin ID
	new AdminId:admin = GetUserAdmin(client);
	
	// Check admin flags
	if (admin != INVALID_ADMIN_ID)	
	{		
		// Is there a valid flag?
		if (accessFlag[0] >= 'a' && accessFlag[0] <= 'z')
		{			
			// Does the admin have the flag needed for this model?
			if (GetAdminFlag(admin, g_FlagLetters[accessFlag[0] - 'a'], Access_Effective))
				return true;
			else
				return false;			
		}
		else
		{
			LogError("Invalid flag in configs/models.ini.");
			return false;
		}
	}		
	else
	{
		// No admin ID, return false
		return false;
	}
}