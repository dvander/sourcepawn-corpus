#include <sourcemod>
#include <sdktools>

//need a player spawn function to reset models every round
//also need to load and save players current models selection ( t & ct) from kv

//0.2 	- Added model_instantchange cvar (default 1)
//		- Added force models on players


new Handle:mainmenu
new Handle:kv
new Handle:playermodelskv

new maxplayers

new Handle:forcemenu

new String:authid[MAXPLAYERS+1][35]

new selectedplayer[MAXPLAYERS+1]


#define TEAM1 0
#define TEAM2 1


new Handle:cvar_instantchange

#define PLUGIN_VERSION "0.2"

#define ADMIN_FORCELEVEL ADMFLAG_CUSTOM4


public Plugin:myinfo = 
{
	name = "Model Menu",
	author = "pRED*",
	description = "Menu to select player models",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_models",Command_Model)
	RegAdminCmd("sm_forcemodel",Command_ForceModel,ADMIN_FORCELEVEL)
	
	CreateConVar("sm_modelmenu_version", PLUGIN_VERSION, "Model Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	cvar_instantchange = CreateConVar("model_instantchange", "1", "Instant Change to new model? Or wait till next round")
	
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post)
	
	
	new String:file[256]
	BuildPath(Path_SM, file, 255, "data/playermodels.ini")
	playermodelskv = CreateKeyValues("Models")
	FileToKeyValues(playermodelskv, file)
}

public OnPluginEnd()
{
	new String:file[256]
	BuildPath(Path_SM, file, 255, "data/playermodels.ini")
	KeyValuesToFile(playermodelskv, file)
	CloseHandle(playermodelskv)
}

public OnMapStart()
{
	mainmenu = BuildMainMenu()
	forcemenu = BuildForceMenu()
	
	//open precache file and add everything to download table
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/modeldownloads.ini")
	new Handle:fileh = OpenFile(file, "r")
	new String:buffer[256]
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		new len = strlen(buffer)
		if (buffer[len-1] == '\n')
   			buffer[--len] = '\0'
   			
		if (FileExists(buffer))
		{
			AddFileToDownloadsTable(buffer)
		}
		
		if (IsEndOfFile(fileh))
		{
			break
		}
	}
}

public Action:Command_ForceModel(client,args)
{
	maxplayers = GetMaxClients()

	new Handle:menu = CreateMenu(Menu_SelectPlayer)
	
	new String:name[30]
	new String:temp[4]

	for (new i=1; i<=maxplayers; i++)
	{
		if (IsClientInGame(i))
		{
				Format(temp,3,"%i",i)
				GetClientName(i, name, 31);
				AddMenuItem(menu, temp, name)
		}
	}
	
	SetMenuTitle(menu, "Select a Player:")
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
	
	return Plugin_Handled
}

public Menu_SelectPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (forcemenu == INVALID_HANDLE)
		{
			PrintToConsole(param1, "There was an error generating the menu. Check your models.ini file")
			return
		}
		
		new String:info[5]
 
		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info))
		
		if (!found)
			return
			
		selectedplayer[param1] = StringToInt(info)
 
		DisplayMenu(forcemenu, param1, MENU_TIME_FOREVER)
	
	}
	
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

public Menu_Force(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[256]
 
		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info))
		
		if (!found)
			return
			
		new player = selectedplayer[param1]
			
		new team = GetClientTeam(player)
		
		if (!IsModelPrecached(info))
		{
			PrecacheModel(info);	
		}
				
		// set users model
		//insert magic here.
		if (!StrEqual(info,""))
		{
			if (IsModelPrecached(info) && IsClientConnected(player) && GetConVarBool(cvar_instantchange))
			{
				LogMessage("Setting Model for client %i: %s",player,info)
				SetEntityModel(param1, info)
			}
			
			KvJumpToKey(playermodelskv,authid[player],true)
			
			
			if (team == 2)
			{
				KvSetString(playermodelskv, "Team1", info)
				KvSetString(playermodelskv, "Team1Group", "")
				KvSetNum(playermodelskv, "Team1F", 1)
			}
			else if (team == 3)
			{
				KvSetString(playermodelskv, "Team2", info)
				KvSetString(playermodelskv, "Team2Group", "")
				KvSetNum(playermodelskv, "Team2F", 1)
			}
			
			KvRewind(kv)
		}
		else
		{
			KvJumpToKey(playermodelskv,authid[player],true)
			
			
			if (team == 2)
			{
				KvSetString(playermodelskv, "Team1", "")
				KvSetString(playermodelskv, "Team1Group", "")
				KvSetNum(playermodelskv, "Team1F", 0)
			}
			else if (team == 3)
			{
				KvSetString(playermodelskv, "Team2", "")
				KvSetString(playermodelskv, "Team2Group", "")
				KvSetNum(playermodelskv, "Team2F", 0)
			}
			
			KvRewind(kv)
		}
			
	}
}

Handle:BuildMainMenu()
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Group)
	
	kv = CreateKeyValues("Commands")
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/models.ini")
	FileToKeyValues(kv, file)
	
	if (!KvGotoFirstSubKey(kv))
	{
		return INVALID_HANDLE
	}
	
	decl String:buffer[30]
	
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer))
		
		AddMenuItem(menu,buffer,buffer)
		
	} while (KvGotoNextKey(kv))
	
	KvRewind(kv)
	
	SetMenuTitle(menu, "Choose a Model")
 
	return menu
}

public OnMapEnd()
{
	CloseHandle(kv)
	CloseHandle(mainmenu)
}

public OnClientPutInServer(client)
{
	GetClientAuthString(client, authid[client], sizeof(authid[]))
}

public Action:Command_Model(client,args)
{
	if (mainmenu == INVALID_HANDLE)
	{
		PrintToConsole(client, "There was an error generating the menu. Check your models.ini file")
		return Plugin_Handled
	}
 
	DisplayMenu(mainmenu, client, MENU_TIME_FOREVER)
	
	return Plugin_Handled
}

public Menu_Group(Handle:menu, MenuAction:action, param1, param2)
{
	// user has selected a model group

	if (action == MenuAction_Select)
	{
		new String:info[30]

		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info))
		
		if (!found)
			return
			
		// user selected a group
		// advance kv to this group
		KvJumpToKey(kv, info)
		
		// check if they have access
		new String:group[30]
		new String:temp[2]
		KvGetString(kv,"Admin",group,sizeof(group))
		new AdminId:AdmId = GetUserAdmin(param1)
		new count = GetAdminGroupCount(AdmId)
		new bool:access = false
		for (new i =0; i<count; i++) 
		{
			if (FindAdmGroup(group) == GetAdminGroup(AdmId, i, temp, sizeof(temp)))
			{
				access = true
			}
		}
		
		if (StrEqual(group,""))
			access = true
		
		if (!access)
		{
			PrintToChat(param1,"Sorry, You do not have access to this command")
			KvRewind(kv)
			return
		}
		// check users team
		
		if (GetClientTeam(param1) == 2)
		{
			KvJumpToKey(kv, "Team1")	
		}
		else if (GetClientTeam(param1) == 3)
		{
			KvJumpToKey(kv, "Team2")	
		}
		else
		{
			KvRewind(kv)
			return
		}
			
		
		// build menu
		// name - path
		KvGotoFirstSubKey(kv)
		
		new Handle:tempmenu = CreateMenu(Menu_Model)

		decl String:buffer[30]
		decl String:path[256]
		do
		{
			KvGetSectionName(kv, buffer, sizeof(buffer))
			
			KvGetString(kv, "path", path, sizeof(path),"")
			
			AddMenuItem(tempmenu,path,buffer)
	
		} while (KvGotoNextKey(kv))
			
		SetMenuTitle(tempmenu, group)
		
		KvRewind(kv)
		
		DisplayMenu(tempmenu, param1, MENU_TIME_FOREVER)
	}
}

public Menu_Model(Handle:menu, MenuAction:action, param1, param2)
{
	//user choose a model
	
	if (action == MenuAction_Select)
	{
		new String:info[256]
		new String:group[30]

		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info))
		GetMenuTitle(menu, group, sizeof(group))	
		
		if (!found)
			return	
			
		new team = GetClientTeam(param1)
		
		KvJumpToKey(playermodelskv,authid[param1],true)
		
		
		if ((team == 2 && KvGetNum(playermodelskv,"Team1F")) || (team == 3 && KvGetNum(playermodelskv,"Team2F")))
		{
			PrintToChat(param1,"Sorry, You cannot change your model at the moment")
			return
		}
	
		// set users model
		//insert magic here.
		if (!StrEqual(info,"") && IsModelPrecached(info) && IsClientConnected(param1) && GetConVarBool(cvar_instantchange))
		{
			LogMessage("Setting Model for client %i: %s",param1,info)
			SetEntityModel(param1, info)
		}
		
		if (team == 2)
		{
			KvSetString(playermodelskv, "Team1", info)
			KvSetString(playermodelskv, "Team1Group", group)
			

		}
		else if (team == 3)
		{
			KvSetString(playermodelskv, "Team2", info)
			KvSetString(playermodelskv, "Team2Group", group)
		}
		
		KvRewind(playermodelskv)
	}
	
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	
	KvJumpToKey(playermodelskv,authid[client],true)
	

	
	new String:model[256]
	new String:group[30]
	
	new team = GetClientTeam(client)
	
	new bool:access = false
		
	if (team == 2)
	{
		KvGetString(playermodelskv, "Team1", model, sizeof(model))
		KvGetString(playermodelskv, "Team1Group", group, sizeof(group))
		
		if (KvGetNum(playermodelskv,"Team1F"))
			access = true
	}
	else if (team == 3)
	{
		KvGetString(playermodelskv, "Team2", model, sizeof(model))
		KvGetString(playermodelskv, "Team2Group", group, sizeof(group))
		
		if (KvGetNum(playermodelskv,"Team2F"))
			access = true
	}
		
	new String:temp[2]
	new AdminId:AdmId = GetUserAdmin(client)
	new count = GetAdminGroupCount(AdmId)
	
	for (new i =0; i<count; i++) 
	{
		if (FindAdmGroup(group) == GetAdminGroup(AdmId, i, temp, sizeof(temp)))
		{
			access = true
			break
		}
	}
	
	if (StrEqual(group,""))
		access = true
		
	if (!access)
	{
		PrintToChat(client,"Sorry, You no longer have access to this model. Please select another using sm_models")
		return
	}
	
	if (!IsModelPrecached(model))
	{
		PrecacheModel(model);	
	}
		
	if (!StrEqual(model,"") && IsModelPrecached(model))
	{
		SetEntityModel(client, model);
	}
			
	KvRewind(playermodelskv)
}

Handle:BuildForceMenu()
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Force)
	
	AddMenuItem(menu, "", "None")
	
	new Handle:tempkv = CreateKeyValues("Commands")
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/forcemodels.ini")
	FileToKeyValues(tempkv, file)
	
	if (!KvGotoFirstSubKey(tempkv))
	{
		return INVALID_HANDLE
	}
	
	decl String:buffer[30]
	decl String:path[100]

	do
	{
		KvGetSectionName(tempkv, buffer, sizeof(buffer))
		KvGetString(tempkv, "path", path, sizeof(path),"")
		
		if (FileExists(path))
		{
			PrecacheModel(path,true)
			AddFileToDownloadsTable(path)
			
			AddMenuItem(menu,path,buffer)
		}
		
	} while (KvGotoNextKey(tempkv))
	
	KvRewind(tempkv)
	CloseHandle(tempkv)
	
	SetMenuTitle(menu, "Choose a Model")
 
	return menu
}