/*******************************************************************************

  SM Skinchooser
  
  v2.3r5 (unofficial) to fix some log errors and menu handles.

  Version: 2.3
  Author: Andi67

  Added new Cvar "sm_skinchooser_forceplayerskin" , only works if "sm_skinchooser_playerspawntimer" is set to "1" !!!
  This is used to force players become a customskin on Spawn.
  Added autocreating configfile on first start.
  
 
  Update to 2.2
  Added Cvar for displaying Menu only for Admins
  Added Cvar for Mods like Resistance and Liberation where player_spawn is fired a little bit later so we add an one second timer
  to make sure Model is set on spawn.
  
  
  Update to 2.1:
  Added new Cvar sm_skinchooser_admingroup , brings back the old GroupSystem.
  Bahhhh amazing now you can use Flags and multiple Groups!!!
  
   
  Update to 2.0: 
  New cvar sm_skinchooser_SkinBots , forces Bots to have a skin.
  New cvar sm_skinchooser_displaytimer , makes it possible to display the menu a little bit
  later not directly by choosing a team.
  New cvar sm_skinchooser_menustarttime , here you can modify the time when Menu should be displayed by joining the team
  related to sm_skinchooser_displaytimer.
  
  
  Update to 1.9:
  Removed needing of Gamedata.txt , so from now Gamedata.txt is no more needed!!!  
   
   
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

#define MAX_FILE_LEN 256
#define MODELS_PER_TEAM 24

#define SM_SKINCHOOSER_VERSION	"2.3r5"

new Handle:g_version=INVALID_HANDLE;
new Handle:g_enabled=INVALID_HANDLE;
new Handle:g_autodisplay=INVALID_HANDLE;
new Handle:g_displaytimer=INVALID_HANDLE;
new Handle:mainmenu = INVALID_HANDLE;
new Handle:g_AdminGroup = INVALID_HANDLE;
new Handle:g_AdminOnly = INVALID_HANDLE;
new Handle:g_PlayerSpawnTimer = INVALID_HANDLE;
new Handle:g_ForcePlayerSkin = INVALID_HANDLE;
new Handle:kv;
new Handle:g_menustarttime;
new Handle:playermodelskv;

new String:authid[MAXPLAYERS+1][35];
new String:map[256];
new String:mediatype[256];
new downloadtype;

new String:g_ModelsPlayerTeam2[MODELS_PER_TEAM][MAX_FILE_LEN];
new String:g_ModelsPlayerTeam3[MODELS_PER_TEAM][MAX_FILE_LEN];
new String:g_ModelsPlayer_Count_Team2;
new String:g_ModelsPlayer_Count_Team3;
new String:g_ModelsBotsTeam2[MODELS_PER_TEAM][MAX_FILE_LEN];
new String:g_ModelsBotsTeam3[MODELS_PER_TEAM][MAX_FILE_LEN];
new String:g_ModelsBots_Count_Team2;
new String:g_ModelsBots_Count_Team3;
new Handle:g_SkinBots=INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "SM SKINCHOOSER",
	author = "Andi67",
	description = "Skin Menu",
	version = SM_SKINCHOOSER_VERSION,
	url = "http://www.andi67-blog.de.vu"
};

public OnPluginStart()
{
	g_version = CreateConVar("sm_skinchooser_version",SM_SKINCHOOSER_VERSION,"SM SKINCHOOSER VERSION",FCVAR_NOTIFY);
	SetConVarString(g_version,SM_SKINCHOOSER_VERSION);
	g_enabled = CreateConVar("sm_skinchooser_enabled","1");
	g_autodisplay = CreateConVar("sm_skinchooser_autodisplay","1");
	g_displaytimer = CreateConVar("sm_skinchooser_displaytimer","0");
	g_menustarttime = CreateConVar("sm_skinchooser_menustarttime" , "5.0");
	g_SkinBots = CreateConVar("sm_skinchooser_skinbots","1");
	g_AdminGroup = CreateConVar("sm_skinchooser_admingroup","1");
	g_AdminOnly = CreateConVar("sm_skinchooser_adminonly","0");
	g_PlayerSpawnTimer = CreateConVar("sm_skinchooser_playerspawntimer","1");
	g_ForcePlayerSkin = CreateConVar("sm_skinchooser_forceplayerskin" , "1");
	
	
	AutoExecConfig(true, "sm_skinchooser");
	
	// Create the model menu command
	RegConsoleCmd("sm_models", Command_Model);
	

	
	// Hook the spawn event
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	
	
	// Load the player's model settings
	new String:file[256];
	BuildPath(Path_SM, file, 255, "data/skinchooser_playermodels.ini");
	playermodelskv = CreateKeyValues("Models");
	FileToKeyValues(playermodelskv, file);
}

public OnMapStart()
{	
	g_ModelsPlayer_Count_Team2 = 0;
	g_ModelsPlayer_Count_Team3 = 0;
	g_ModelsPlayer_Count_Team2 = LoadModels(g_ModelsPlayerTeam2, "configs/sm_skinchooser/forceskinsplayer_team2.ini");
	g_ModelsPlayer_Count_Team3  = LoadModels(g_ModelsPlayerTeam3,  "configs/sm_skinchooser/forceskinsplayer_team3.ini");	
	
	g_ModelsBots_Count_Team2 = 0;
	g_ModelsBots_Count_Team3 = 0;
	g_ModelsBots_Count_Team2 = LoadModels(g_ModelsBotsTeam2, "configs/sm_skinchooser/forceskinsbots_team2.ini");
	g_ModelsBots_Count_Team3  = LoadModels(g_ModelsBotsTeam3,  "configs/sm_skinchooser/forceskinsbots_team3.ini");
	
	new String:file[256];
	decl String:path[100];

	kv = CreateKeyValues("Commands");
	BuildPath(Path_SM, file, 255, "configs/sm_skinchooser/skins.ini");
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
	
	ReadDownloads();
	
	//if(GetConVarInt(g_enabled) == 1) 
	//{
	//	ReadDownloads();
	//}
}

public OnMapEnd()
{
	// Write the the player's model settings
	new String:file[256];
	BuildPath(Path_SM, file, 255, "data/skinchooser_playermodels.ini");
	KeyValuesToFile(playermodelskv, file);
	CloseHandle(kv);
}

public OnPluginEnd()
{
	CloseHandle(playermodelskv);
	CloseHandle(g_version);
	CloseHandle(g_enabled);
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
			if(GetConVarInt(g_AdminGroup) == 1)
			{
				// check if they have access
				new String:group[30];
				new String:temp[2];
				KvGetString(kv,"Admin",group,sizeof(group));
				new AdminId:AdmId = GetUserAdmin(client);
				new count = GetAdminGroupCount(AdmId);
				for (new i =0; i<count; i++) 
				{
					if (FindAdmGroup(group) == GetAdminGroup(AdmId, i, temp, sizeof(temp)))
					{
						// Get the model group name and add it to the menu
						KvGetSectionName(kv, buffer, sizeof(buffer));		
						AddMenuItem(menu,buffer,buffer);
					}
				}
			}

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
	BuildPath(Path_SM, file, 255, "configs/sm_skinchooser/skinchooserdownloads.ini");
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
		// (e.g. go to a stock model)%%
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
			
			if(GetConVarInt(g_ForcePlayerSkin) == 1)
			{
				if (!IsFakeClient(param1))
				{
					skin_players(param1);
				}
			}
			
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
		if (!StrEqual(info,"") && IsModelPrecached(info) && IsClientConnected(param1)&& !IsFakeClient(param1)&& IsValidEntity(param1))
		{
			// Set the model
			LogMessage("Setting Model for client %i: %s",param1,info);
			SetEntityModel(param1, info);
			SetEntityRenderColor(param1, 255, 255, 255, 255);
		}
		
		// Get the player's steam
		KvJumpToKey(playermodelskv,authid[param1], true);		
		
		// Save the user's choice so it is automatically applied
		// each time they spawn
		if (GetClientTeam(param1) == 2 && !IsFakeClient(param1))
		{
			KvSetString(playermodelskv, "Team1", info);
			KvSetString(playermodelskv, "Team1Group", group);
		}
		else if (GetClientTeam(param1) == 3 && !IsFakeClient(param1))
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

public Action:Timer_Menu(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(GetClientTeam(client) == 2 || GetClientTeam(client) == 3 )
		{
			Command_Model(client, 0);

			mainmenu = BuildMainMenu(client);
			
			if (mainmenu == INVALID_HANDLE)
			{ 
				// We don't, send an error message and return
				PrintToConsole(client, "There was an error generating the menu. Check your skins.ini file.");
				return Plugin_Handled;
			}
			
			new AdminId:admin = GetUserAdmin(client);
			
			if (GetConVarInt(g_AdminOnly) == 1 && admin != INVALID_ADMIN_ID)
			{
				// We have a valid menu, display it and return
				DisplayMenu(mainmenu, client, MENU_TIME_FOREVER);
				PrintToChat(client, "Skinmenu is open , choose your Model!!!");
			}
			else if(GetConVarInt(g_AdminOnly) == 0)
			{
				DisplayMenu(mainmenu, client, MENU_TIME_FOREVER);
				PrintToChat(client, "Skinmenu is open , choose your Model!!!");
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_Model(client,args)
{
	if(GetConVarInt(g_enabled) == 1)	
	{
		if (IsValidClient(client) && IsClientInGame(client) && GetClientTeam(client) > 1 && !IsFakeClient(client))
		{
			//Create the main menu
			mainmenu = BuildMainMenu(client);
		
			// Do we have a valid model menu
			if (mainmenu == INVALID_HANDLE)
			{ 
				// We don't, send an error message and return
				PrintToConsole(client, "There was an error generating the menu. Check your skins.ini file.");
				return Plugin_Handled;
			}
		
			new AdminId:admin = GetUserAdmin(client);
		
			if (GetConVarInt(g_AdminOnly) == 1 && admin != INVALID_ADMIN_ID)
			{
				// We have a valid menu, display it and return
				DisplayMenu(mainmenu, client, MENU_TIME_FOREVER);
			}
			else if(GetConVarInt(g_AdminOnly) == 0)
			{
				DisplayMenu(mainmenu, client, MENU_TIME_FOREVER);
			}
		}
	}
	
	return Plugin_Handled;
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_enabled) == 1)	
	{	
		if( GetConVarBool(g_autodisplay) )
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new team = GetEventInt(event, "team");
			if( GetConVarBool(g_displaytimer))
			{
				if(IsValidClient(client) && IsClientInGame(client) && (team == 2 || team == 3) && !IsFakeClient(client))
				{
					CreateTimer(GetConVarFloat(g_menustarttime), Timer_Menu, client);
				}
			}
		
			else if(IsValidClient(client) && IsClientInGame(client) && (team == 2 || team == 3) && !IsFakeClient(client))
			{
				Command_Model(client, 0);
			}
			return;
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_enabled) == 1)	
	{	
		// Get the userid and client
		new clientId = GetEventInt(event, "userid");
		new client = GetClientOfUserId(clientId);	
	
	
		if( GetConVarInt(g_PlayerSpawnTimer) == 1)
		{
			if(IsValidClient(client) && IsClientInGame(client) && GetClientTeam(client) > 1)
			{
				CreateTimer(1.0, Timer_Spawn, GetClientUserId(client));
			}
		}
	
		else if( GetConVarInt(g_PlayerSpawnTimer) == 0)
		{
			// Get the user's authid
			KvJumpToKey(playermodelskv,authid[client],true);
	
			new String:model[256];
			new String:group[30];	
	
			// Get the user's model pref
			if (IsValidClient(client) && GetClientTeam(client) == 2 && IsClientInGame(client))
			{
				KvGetString(playermodelskv, "Team1", model, sizeof(model), "");
				KvGetString(playermodelskv, "Team1Group", group, sizeof(group), "");
			}
			else if (IsValidClient(client) && GetClientTeam(client) == 3 && IsClientInGame(client))
			{
				KvGetString(playermodelskv, "Team2", model, sizeof(model), "");
				KvGetString(playermodelskv, "Team2Group", group, sizeof(group), "");
			}		
	
			// Make sure that they have a valid model pref
			if (!StrEqual(model,"", false) && IsModelPrecached(model) && IsValidClient(client) && IsClientInGame(client))
			{
				// Set the model
				SetEntityModel(client, model);
				SetEntityRenderColor(client, 255, 255, 255, 255);
			}
			if (!StrEqual(model,"") && IsModelPrecached(model) && IsValidClient(client) && IsClientInGame(client))
			{
				SetEntityModel(client, model);
				SetEntityRenderColor(client, 255, 255, 255, 255);
			}
	
			// Rewind the KVs
			KvRewind(playermodelskv);
		}
	
		if(IsValidClient(client) && IsFakeClient(client) && GetConVarInt(g_SkinBots) == 1 && IsClientInGame(client))
		{
			skin_bots(client);
		}
		if(IsValidClient(client) && !IsFakeClient(client) && GetConVarInt(g_ForcePlayerSkin) == 1 && GetConVarInt(g_PlayerSpawnTimer) == 1 && IsClientInGame(client))
		{
			skin_players(client);
		}
	}
}

public Action:Timer_Spawn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);	
	// Get the user's authid
	KvJumpToKey(playermodelskv,authid[client],true);
	
	new String:model[256];
	new String:group[30];	
	
	// Get the user's model pref
	if (IsValidClient(client) && IsClientInGame(client))
	{
		if (GetClientTeam(client) == 2)
		{
			KvGetString(playermodelskv, "Team1", model, sizeof(model), "");
			KvGetString(playermodelskv, "Team1Group", group, sizeof(group), "");
		}
		if (GetClientTeam(client) == 3)
		{
			KvGetString(playermodelskv, "Team2", model, sizeof(model), "");
			KvGetString(playermodelskv, "Team2Group", group, sizeof(group), "");
		}		
	}	
	// Make sure that they have a valid model pref
	if (!StrEqual(model,"", false) && IsModelPrecached(model) && IsValidClient(client) && IsClientInGame(client))
	{
		// Set the model
		SetEntityModel(client, model);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	if (!StrEqual(model,"") && IsModelPrecached(model) && IsValidClient(client) && IsClientInGame(client))
	{
		SetEntityModel(client, model);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	
	// Rewind the KVs
	KvRewind(playermodelskv);
}	

stock LoadModels(String:models[][], String:ini_file[])
{
	decl String:buffer[MAX_FILE_LEN];
	decl String:file[MAX_FILE_LEN];
	new models_count;

	BuildPath(Path_SM, file, MAX_FILE_LEN, ini_file);

	//open precache file and add everything to download table
	new Handle:fileh = OpenFile(file, "r");
	while (ReadFileLine(fileh, buffer, MAX_FILE_LEN))
	{
		// Strip leading and trailing whitespace
		TrimString(buffer);

		// Skip non existing files (and Comments)
		if (FileExists(buffer))
		{
			// Tell Clients to download files
			AddFileToDownloadsTable(buffer);
			// Tell Clients to cache model
			if (StrEqual(buffer[strlen(buffer)-4], ".mdl", false) && (models_count<MODELS_PER_TEAM))
			{
				strcopy(models[models_count++], strlen(buffer)+1, buffer);
				PrecacheModel(buffer, true);
			}
		}
	}
	return models_count;
}

stock skin_bots(client)
{
	new team = GetClientTeam(client);
	if (IsValidClient(client) && IsClientInGame(client))
	{
		if (team==2)
		{
			SetEntityModel(client,g_ModelsBotsTeam2[GetRandomInt(0, g_ModelsBots_Count_Team2-1)]);
		}
		else if (team==3)
		{
			SetEntityModel(client,g_ModelsBotsTeam3[GetRandomInt(0, g_ModelsBots_Count_Team3-1)]);
		}
	}
}

stock skin_players(client)
{
	new team = GetClientTeam(client);
	if (IsValidClient(client) && IsClientInGame(client))
	{
		if (team==2)
		{
			SetEntityModel(client,g_ModelsPlayerTeam2[GetRandomInt(0, g_ModelsPlayer_Count_Team2-1)]);
		}
		else if (team==3)
		{
			SetEntityModel(client,g_ModelsPlayerTeam3[GetRandomInt(0, g_ModelsPlayer_Count_Team3-1)]);
		}
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return true;
}
