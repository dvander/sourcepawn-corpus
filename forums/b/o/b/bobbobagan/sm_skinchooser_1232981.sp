/*******************************************************************************

SM Skinchooser

Version: 1.8
Author: Andi67




Update to 1.8:
Fixed another Handlebug. 


Update to 1.7: 

Added new Cvar "sm_skinchooser_autodisplay"   


Update to 1.6: 

Supported now all Flags


Update to 1.5:

Fixed native Handle error


Update to 1.4:

Plugin now handles the following Flags:

"" - for Public
"b" - Generic Admins
"g" - Mapchange Admins
"t" - Custom Admins for use Reserved Skins
"z" - Root Admins

Now you only will see Sections/Groups in the Menu you have Access to 

Rearranged skins.ini for better overview

Fixed some Menubugs

Added Gamedata for Hl2mp



Everybody can edit this plugin and copy this plugin.

Thanks to:
Pred,Tigerox,Recon for making Modelmenu

Swat_88 for making sm_downloader and precacher

Paegus,Ghosty for helping me to bring up the Menu on Teamjoin

And special THX to Feuersturm who helped me to fix the Spectatorbug!!!

HAVE FUN!!!

*******************************************************************************/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1


#define SM_SKINCHOOSER_VERSION		"1.8"


new Handle:g_version=INVALID_HANDLE;
new Handle:g_enabled=INVALID_HANDLE;
new Handle:g_normal=INVALID_HANDLE;
new Handle:g_autodisplay=INVALID_HANDLE;
new Handle:mainmenu = INVALID_HANDLE;
new Handle:kv;
new Handle:hGameConf;
new Handle:hSetModel;
new Handle:playermodelskv;
new String:authid[MAXPLAYERS+1][35];
new String:map[256];
new String:mediatype[256];
new downloadtype;

public Plugin:myinfo = 
{
	name = "SM SKINCHOOSER",
	author = "Andi67",
	description = "Skin Menu",
	version = SM_SKINCHOOSER_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	g_version = CreateConVar("sm_skinchooser_version",SM_SKINCHOOSER_VERSION,"SM SKINCHOOSER VERSION",FCVAR_NOTIFY);
	SetConVarString(g_version,SM_SKINCHOOSER_VERSION);
	g_normal = CreateConVar("sm_skinchooser_normal","1");
	g_enabled = CreateConVar("sm_skinchooser_enabled","1");
	g_autodisplay = CreateConVar("sm_skinchooser_autodisplay","1");
	
	// Create the model menu command
	RegConsoleCmd("sm_models", Command_Model);
	
	// Load the game data file
	hGameConf = LoadGameConfigFile("skinchooser.gamedata");
	
	// Hook the spawn event
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	
	// Model changing SDK call
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetModel");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	hSetModel = EndPrepSDKCall();
	
	// Load the player's model settings
	new String:file[256];
	BuildPath(Path_SM, file, 255, "data/skinchooser_playermodels.ini");
	playermodelskv = CreateKeyValues("Models");
	FileToKeyValues(playermodelskv, file);
}

public OnPluginEnd()
{
	CloseHandle(g_version);
	CloseHandle(g_enabled);
	CloseHandle(g_normal);
	
	// Write the the player's model settings
	new String:file[256];
	BuildPath(Path_SM, file, 255, "data/skinchooser_playermodels.ini");
	KeyValuesToFile(playermodelskv, file);
	CloseHandle(playermodelskv);
}

public OnMapStart()
{	
	new String:file[256];
	decl String:path[100];
	
	kv = CreateKeyValues("Commands");
	BuildPath(Path_SM, file, 255, "configs/skins.ini");
	FileToKeyValues(kv, file);
	
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
	do
	{
		KvJumpToKey(kv, "Team1");
		KvGotoFirstSubKey(kv);
		do
		{
			KvGetString(kv, "path", path, sizeof(path),"");
			if (FileExists(path))
				PrecacheModel(path,true);
		} 
		while (KvGotoNextKey(kv));
		
		KvGoBack(kv);
		KvGoBack(kv);
		KvJumpToKey(kv, "Team2");
		KvGotoFirstSubKey(kv);
		do
		{
			KvGetString(kv, "path", path, sizeof(path),"");
			if (FileExists(path))
				PrecacheModel(path,true);
		}
		while (KvGotoNextKey(kv));
			
		KvGoBack(kv);
		KvGoBack(kv);
		
	} 
	while (KvGotoNextKey(kv));	
	
	KvRewind(kv);
	
	if(GetConVarInt(g_enabled) == 1)
	{
		if(GetConVarInt(g_normal) == 1) ReadDownloads();
	}
}

public OnMapEnd()
{
	CloseHandle(kv);
}

Handle:BuildMainMenu(client)
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Group);
	
	if (!KvGotoFirstSubKey(kv))
	{
		return INVALID_HANDLE;
	}
	
	decl String:buffer[30];
	decl String:accessFlag[5];
	new AdminId:admin = GetUserAdmin(client);
	
	{
		do
		{
			//Get accesFlag and see if the Admin is in it
			KvGetString(kv, "admin", accessFlag, sizeof(accessFlag));
			
			if(StrEqual(accessFlag,""))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"a") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Reservation, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}			
			
			if(StrEqual(accessFlag,"b") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Generic, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"c") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Kick, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"d") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Ban, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"e") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Unban, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"f") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Slay, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}			
			
			if(StrEqual(accessFlag,"g") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Changemap, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"h") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Convars, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"i") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Config, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"j") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Chat, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"k") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Vote, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"l") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Password, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"m") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_RCON, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"n") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Cheats, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"o") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom1, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"p") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom2, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"q") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom3, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"r") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom4, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"s") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom5, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}			
			
			if(StrEqual(accessFlag,"t") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom6, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"z") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Root, Access_Effective))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				AddMenuItem(menu,buffer,buffer);
			}
			
		} while (KvGotoNextKey(kv));	
	}
	KvRewind(kv);
	
	AddMenuItem(menu,"none","None");
	SetMenuTitle(menu, "Skins");
	
	return menu;
}

public ReadFileFolder(String:path[])
{
	new Handle:dirh = INVALID_HANDLE;
	new String:buffer[256];
	new String:tmp_path[256];
	new FileType:type = FileType_Unknown;
	new len;
	
	len = strlen(path);
	if (path[len-1] == '\n')
		path[--len] = '\0';
	
	TrimString(path);
	
	if(DirExists(path))
	{
		dirh = OpenDirectory(path);
		while(ReadDirEntry(dirh,buffer,sizeof(buffer),type))
		{
			len = strlen(buffer);
			if (buffer[len-1] == '\n')
				buffer[--len] = '\0';
			
			TrimString(buffer);
			
			if (!StrEqual(buffer,"",false) && !StrEqual(buffer,".",false) && !StrEqual(buffer,"..",false))
			{
				strcopy(tmp_path,255,path);
				StrCat(tmp_path,255,"/");
				StrCat(tmp_path,255,buffer);
				if(type == FileType_File)
				{
					if(downloadtype == 1)
					{
						ReadItem(tmp_path);
					}
					
					
				}
			}
		}
	}
	else{
		if(downloadtype == 1)
		{
			ReadItem(path);
		}
		
	}
	if(dirh != INVALID_HANDLE)
	{
		CloseHandle(dirh);
	}
}

public ReadDownloads()
{
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/skinchooserdownloads.ini");
	new Handle:fileh = OpenFile(file, "r");
	new String:buffer[256];
	downloadtype = 1;
	new len;
	
	GetCurrentMap(map,255);
	
	if(fileh == INVALID_HANDLE) return;
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{	
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';
		
		TrimString(buffer);
		
		if(!StrEqual(buffer,"",false))
		{
			ReadFileFolder(buffer);
		}
		
		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE)
	{
		CloseHandle(fileh);
	}
}

public ReadItem(String:buffer[])
{
	new len = strlen(buffer);
	if (buffer[len-1] == '\n')
		buffer[--len] = '\0';
	
	TrimString(buffer);
	
	if(len >= 2 && buffer[0] == '/' && buffer[1] == '/')
	{
		if(StrContains(buffer,"//") >= 0)
		{
			ReplaceString(buffer,255,"//","");
		}
	}
	else if (!StrEqual(buffer,"",false) && FileExists(buffer))
	{
		if(StrContains(mediatype,"Model",true) >= 0)
		{
			PrecacheModel(buffer,true);
		}
		AddFileToDownloadsTable(buffer);
	}
}

public Menu_Group(Handle:menu, MenuAction:action, param1, param2)
{
	// User has selected a model group
	if (action == MenuAction_Select)
	{
		new String:info[30];
		
		// Get the group they selected
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		
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
			if (GetClientTeam(param1) == 2)
			{
				KvSetString(playermodelskv, "Team1", "");
				KvSetString(playermodelskv, "Team1Group", "");
			}
			else if (GetClientTeam(param1) == 3)
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
		KvJumpToKey(kv, info);
		
		
		// Check users team		
		if (GetClientTeam(param1) == 2)
		{
			// Show team 1 models
			KvJumpToKey(kv, "Team1");
		}
		else if (GetClientTeam(param1) == 3)
		{
			// Show team 2 models
			KvJumpToKey(kv, "Team2");
		}
		else
		
		// They must be spectator, return
		return;
		
		
		// Get the first model		
		KvGotoFirstSubKey(kv);
		
		// Create the menu
		new Handle:tempmenu = CreateMenu(Menu_Model);
		
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
		
		
		// Set the menu title to the model group name
		SetMenuTitle(tempmenu, info);
		
		// Rewind the KVs
		KvRewind(kv);
		
		// Display the menu
		DisplayMenu(tempmenu, param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
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
		
		
		if (!found)
			return;
		
		// Set the user's model
		if (!StrEqual(info,"") && IsModelPrecached(info) && IsClientConnected(param1))
		{
			// Set the model
			LogMessage("Setting Model for client %i: %s",param1,info);
			SDKCall(hSetModel, param1, info);
		}
		
		// Get the player's steam
		KvJumpToKey(playermodelskv,authid[param1], true);		
		
		// Save the user's choice so it is automatically applied
		// each time they spawn
		if (GetClientTeam(param1) == 2)
		{
			KvSetString(playermodelskv, "Team1", info);
			KvSetString(playermodelskv, "Team1Group", group);
		}
		else if (GetClientTeam(param1) == 3)
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

public OnClientPostAdminCheck(client)
{
	// Save the client auth string (steam)
	GetClientAuthString(client, authid[client], sizeof(authid[]));
}

public Action:Command_Model(client,args)
{
	//Create the main menu
	mainmenu = BuildMainMenu(client);
	
	// Do we have a valid model menu
	if (mainmenu == INVALID_HANDLE)
	{ 
		// We don't, send an error message and return
		PrintToConsole(client, "There was an error generating the menu. Check your skins_css.ini file.");
		return Plugin_Handled;
	}
	
	// We have a valid menu, display it and return
	DisplayMenu(mainmenu, client, MENU_TIME_FOREVER);	
	return Plugin_Handled;
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_autodisplay))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetEventInt(event, "team");
		
		if((team == 2 || team == 3) && IsClientInGame(client))
		
		{
			Command_Model(client, 0);
		}
		return;
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Get the userid and client
	new clientId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientId);
	
	// Get the user's authid
	KvJumpToKey(playermodelskv,authid[client],true);
	
	new String:model[256];
	
	// Get the user's model pref
	if (GetClientTeam(client) == 2)
	{
		KvGetString(playermodelskv, "Team1", model, sizeof(model), "");
	}
	else if (GetClientTeam(client) == 3)
	{
		KvGetString(playermodelskv, "Team2", model, sizeof(model), "");
	}		
	
	// Make sure that they have a valid model pref
	if (!StrEqual(model,"", false) && IsModelPrecached(model))
	{
		// Set the model
		SDKCall(hSetModel, client, model);
	}
	if (!StrEqual(model,"") && IsModelPrecached(model))
	{
		SetEntityModel(client, model);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	// Rewind the KVs
	KvRewind(playermodelskv);
}