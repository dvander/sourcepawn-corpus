#include <sourcemod>
#include <sdktools>

//need a player spawn function to reset models every round
//also need to load and save players current models selection ( t & ct) from kv


new Handle:mainmenu = INVALID_HANDLE
new Handle:kv = INVALID_HANDLE
new Handle:playermodelskv = INVALID_HANDLE

new String:authid[MAXPLAYERS+1][35]


#define TEAM2 1
#define TEAM1 0

new Handle:hGameConf
new Handle:hSetModel

#define PLUGIN_VERSION "0.13ox"


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
	
	CreateConVar("sm_modelmenu_version", PLUGIN_VERSION, "Super Commands Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	hGameConf = LoadGameConfigFile("modelmenu.gamedata")
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post)
	
	StartPrepSDKCall(SDKCall_Player)
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetModel")
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer)
	hSetModel = EndPrepSDKCall()
	
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
	new String:file[256]
	decl String:path[100]

	//tigerox
	//read in models.ini and precache
	kv = CreateKeyValues("Commands")
	BuildPath(Path_SM, file, 255, "configs/models.ini")
	FileToKeyValues(kv, file)
	
	if (!KvGotoFirstSubKey(kv))
	{
		return 
	}
	do
	{
		KvJumpToKey(kv, "Team1")
		KvGotoFirstSubKey(kv)
		do
		{
			KvGetString(kv, "path", path, sizeof(path),"")
			if (FileExists(path))
				PrecacheModel(path,true)
		} while (KvGotoNextKey(kv))
		
		KvGoBack(kv)
		KvGoBack(kv)
		KvJumpToKey(kv, "Team2")
		KvGotoFirstSubKey(kv)
		do
		{
			KvGetString(kv, "path", path, sizeof(path),"")
			if (FileExists(path))
				PrecacheModel(path,true)
		} while (KvGotoNextKey(kv))
			
		KvGoBack(kv)
		KvGoBack(kv)
			
	} while (KvGotoNextKey(kv))	
		
	KvRewind(kv)
	
	//open precache file and add everything to download table
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
			break
	}
}
//tigerox
//pass in the client that you want to build this menu for
//The player will only see groups they are in
Handle:BuildMainMenu(client)
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Group)
	
	if (!KvGotoFirstSubKey(kv))
	{
		return INVALID_HANDLE
	}
	
	//tigerox
	//build only groups the client is in
	decl String:buffer[30]
	decl String:group[30]
	new String:temp[2]
	new AdminId:AdmId = GetUserAdmin(client)
	new count = GetAdminGroupCount(AdmId)

	for (new i =0; i<count; i++) 
	{
		//check all the groups and see if this admin is in it.
		do
		{
			//Get group name of group to check
			KvGetString(kv, "Admin", group, sizeof(group))
			
			if (FindAdmGroup(group) == GetAdminGroup(AdmId, i, temp, sizeof(temp)))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer))
		
				AddMenuItem(menu,buffer,buffer)
			}
		} while (KvGotoNextKey(kv))	
	}
	KvRewind(kv)

	//tigerox
	//add option to select no model
	AddMenuItem(menu,"none","None");
	SetMenuTitle(menu, "Choose a Model")
 
	return menu
}

public OnMapEnd()
{
	CloseHandle(kv)
}

public OnClientPutInServer(client)
{
	GetClientAuthString(client, authid[client], sizeof(authid[]))
}
	

public Action:Command_Model(client,args)
{
	//tigerox
	//create the menu
	if(GetClientTeam(client) > 1)
	{
		mainmenu = BuildMainMenu(client)
	
		//check if the menu could be created
		if(mainmenu == INVALID_HANDLE)
		{
			PrintToConsole(client, "There was an error generating the menu. Check your models.ini file")
			return Plugin_Handled
		}

		DisplayMenu(mainmenu, client, MENU_TIME_FOREVER)
	}
	else
		PrintToChat(client, "[Model Menu] Join a team before selecting a model!")
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
		
		//tigeox
		//check for no model selection
		if(StrEqual(info,"none"))
		{
			KvJumpToKey(playermodelskv,authid[param1],true)
		
				
			if (GetClientTeam(param1) == 2)
			{
				KvSetString(playermodelskv, "Team1", "")
				KvSetString(playermodelskv, "Team1Group", "")
			}
			else if (GetClientTeam(param1) == 3)
			{
				KvSetString(playermodelskv, "Team2", "")
				KvSetString(playermodelskv, "Team2Group", "")
			}
		
			KvRewind(playermodelskv)
			
			return
		}
		
		// user selected a group
		// advance kv to this group
		KvJumpToKey(kv, info)
		
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
			
		SetMenuTitle(tempmenu, info)
		
		KvRewind(kv)
		
		DisplayMenu(tempmenu, param1, MENU_TIME_FOREVER)
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
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
		
		//tigerox
		//set the correct admin group
		KvJumpToKey(kv, group)		
		KvGetString(kv, "Admin", group, sizeof(group))
		KvRewind(kv)
			
		//TigerOx
		//log model change
		if (!StrEqual(info,"") && IsModelPrecached(info) && IsClientConnected(param1))
		{
			LogMessage("Setting Model for client %i: %s",param1,info)
		}
	
		
		KvJumpToKey(playermodelskv,authid[param1],true)
		
				
		if (GetClientTeam(param1) == 2)
		{
			KvSetString(playermodelskv, "Team1", info)
			KvSetString(playermodelskv, "Team1Group", group)
		}
		else if (GetClientTeam(param1) == 3)
		{
			KvSetString(playermodelskv, "Team2", info)
			KvSetString(playermodelskv, "Team2Group", group)
		}
		
		KvRewind(playermodelskv)
	}
	else if (action == MenuAction_End)
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
		
	if (GetClientTeam(client) == 2)
	{
		KvGetString(playermodelskv, "Team1", model, sizeof(model))
		KvGetString(playermodelskv, "Team1Group", group, sizeof(group))
	}
	else if (GetClientTeam(client) == 3)
	{
		KvGetString(playermodelskv, "Team2", model, sizeof(model))
		KvGetString(playermodelskv, "Team2Group", group, sizeof(group))
	}
	
		
	new String:temp[2]
	new AdminId:AdmId = GetUserAdmin(client)
	new count = GetAdminGroupCount(AdmId)
	new bool:access = false
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
	
	//tigerox
	//just fix access no need to bother the user
	if (!access)
	{
		if (GetClientTeam(client) == 2)
		{
			KvSetString(playermodelskv, "Team1", "")
			KvSetString(playermodelskv, "Team1Group", "")
			
		}
		else if (GetClientTeam(client) == 3)
		{
			KvSetString(playermodelskv, "Team2", "")
			KvSetString(playermodelskv, "Team2Group", "")
		}
		model = ""
	}
		
	if (!StrEqual(model,"") && IsModelPrecached(model))
	{
		SDKCall(hSetModel, client, model)
	}
			
	KvRewind(playermodelskv)
}
