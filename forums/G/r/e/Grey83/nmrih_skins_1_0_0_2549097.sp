// Based on the code of the plugin "SM Skinchooser HL2DM" v2.3 by Andi67
#pragma semicolon 1
#pragma newdecls required

#include <sdktools>

static const char	PLUGIN_NAME[]		= "[NMRiH] Skins",
					PLUGIN_VERSION[]	= "1.0.0",
					PLUGIN_AUTOR[]		= "Grey83",
// Paths to configuration files
					PLAYERS_SKINS[]		= "data/nmrih_skins_playermodels.ini",
					SKINS_DOWNLOADS[]	= "configs/nmrih_skins/downloads_list.ini",
					FORCED_SKINS[]		= "configs/nmrih_skins/forced_skins.ini",
					SKINS_MENU[]		= "configs/nmrih_skins/skins_menu.ini";

#define MAX_MODELS 24

bool bEnable,
	bAdminGroup,
	bAdminOnly,
	bSpawnTimer,
	bForceSkin;

Menu mainmenu;
Handle kv,
	playermodelskv;
bool bLate,
	downloadtype,
	bTPView[MAXPLAYERS+1],
	bRandomSkin[MAXPLAYERS+1];
int iForcedSkins,
	iTotalSkins;
char authid[MAXPLAYERS+1][35],
	sForcedSkins[MAX_MODELS][PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTOR,
	description	= "Skins menu with 3rd person view for NMRiH",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=301319"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("nmrih_skins_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);

	ConVar CVar;
	(CVar = CreateConVar("sm_skins_enable",		"1", "Enable/Disable plugin", FCVAR_NOTIFY, true, _, true, 1.0)).AddChangeHook(CVarChanged_Enable);
	bEnable = CVar.BoolValue;

	(CVar = CreateConVar("sm_skins_admingroup",	"1", "Enable/Disable the possebility to use the Groupsystem", _, true, _, true, 1.0)).AddChangeHook(CVarChanged_AdminGroup);
	bAdminGroup = CVar.BoolValue;

	(CVar = CreateConVar("sm_skins_adminonly",	"0", "Enable/Disable deny of access to the menu except for admins", _, true, _, true, 1.0)).AddChangeHook(CVarChanged_AdminOnly);
	bAdminOnly = CVar.BoolValue;

	(CVar = CreateConVar("sm_skins_spawntimer",	"1", "Enable/Disable a timer that changes the model a second after the event 'player_spawn'", _, true, _, true, 1.0)).AddChangeHook(CVarChanged_SpawnTimer);
	bSpawnTimer = CVar.BoolValue;

	(CVar = CreateConVar("sm_skins_forceskin",	"1", "Players get a model regardless of whether they chose the model or not", _, true, _, true, 1.0)).AddChangeHook(CVarChanged_ForceSkin);
	bForceSkin = CVar.BoolValue;

	AutoExecConfig(true, "nmrih_skins");

	RegConsoleCmd("sm_model", Cmd_Model);
	RegConsoleCmd("sm_models", Cmd_Model);
	RegConsoleCmd("sm_skin", Cmd_Model);
	RegConsoleCmd("sm_skins", Cmd_Model);

	HookEvent("player_spawn", Event_PlayerSpawn);

	// Load the player's model settings
	char file[256];
	BuildPath(Path_SM, file, 255, PLAYERS_SKINS);
	playermodelskv = CreateKeyValues("Models");
	FileToKeyValues(playermodelskv, file);

	if(bLate)
	{
		for(int i = 1; i <= MaxClients; i++) if(IsClientAuthorized(i)) OnClientPostAdminCheck(i);
		bLate = false;
	}
}

public void OnPluginEnd()
{
	// Write the the player's model settings
	char file[256];
	BuildPath(Path_SM, file, 255, PLAYERS_SKINS);
	KeyValuesToFile(playermodelskv, file);
	CloseHandle(playermodelskv);
}

public void CVarChanged_Enable(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bEnable = CVar.BoolValue;
}

public void CVarChanged_AdminGroup(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bAdminGroup = CVar.BoolValue;
}

public void CVarChanged_AdminOnly(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bAdminOnly = CVar.BoolValue;
}

public void CVarChanged_SpawnTimer(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bSpawnTimer = CVar.BoolValue;
}

public void CVarChanged_ForceSkin(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bForceSkin = CVar.BoolValue;
}

public void OnMapStart()
{
	iTotalSkins = 0;
	LoadModels();

	char file[256];
	static char path[100];

	kv = CreateKeyValues("Commands");

	BuildPath(Path_SM, file, 255, SKINS_MENU);
	FileToKeyValues(kv, file);
	if(!KvGotoFirstSubKey(kv)) return;

	do
	{
		KvJumpToKey(kv, "List");
		KvGotoFirstSubKey(kv);
		do
		{
			KvGetString(kv, "path", path, sizeof(path),"");
			if(FileExists(path) && PrecacheModel(path, true)) iTotalSkins++;
		}
		while(KvGotoNextKey(kv));
		KvGoBack(kv);
		KvGoBack(kv);
	}
	while(KvGotoNextKey(kv));
	KvRewind(kv);

	if(bEnable) ReadDownloads();

	PrintToServer("%s:\n	Total: %i\n	Forced: %i", PLUGIN_NAME, iTotalSkins, iForcedSkins);
}

public void OnMapEnd()
{
	CloseHandle(kv);
}

stock void LoadModels()
{
	static char buffer[PLATFORM_MAX_PATH], file[PLATFORM_MAX_PATH];
	int models_count;

	BuildPath(Path_SM, file, PLATFORM_MAX_PATH, FORCED_SKINS);

	//open precache file and add everything to download table
	Handle fileh = OpenFile(file, "r");
	while(ReadFileLine(fileh, buffer, PLATFORM_MAX_PATH))
	{
		// Strip leading and trailing whitespace
		TrimString(buffer);

		// Skip non existing files(and Comments)
		if(FileExists(buffer))
		{
			// Tell Clients to download files
			AddFileToDownloadsTable(buffer);
			// Tell Clients to cache model
			if(StrEqual(buffer[strlen(buffer)-4], ".mdl", false) && models_count < MAX_MODELS)
			{
				strcopy(sForcedSkins[models_count++], strlen(buffer)+1, buffer);
				PrecacheModel(buffer, true);
			}
		}
	}
	if(fileh != null) CloseHandle(fileh);
	iForcedSkins = models_count;
}

stock void ReadDownloads()
{
	char file[256];
	BuildPath(Path_SM, file, 255, SKINS_DOWNLOADS);
	Handle fileh = OpenFile(file, "r");
	if(fileh == null) return;

	char buffer[256];
	downloadtype = true;
	int len;
	while(ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if(buffer[len-1] == '\n') buffer[--len] = '\0';

		TrimString(buffer);

		if(buffer[0]) ReadFileFolder(buffer);

		if(IsEndOfFile(fileh)) break;
	}
	if(fileh != null) CloseHandle(fileh);
}

stock void ReadFileFolder(char[] path)
{
	static Handle dirh;
	static char buffer[256], tmp_path[256];
	static FileType type = FileType_Unknown;
	static int len;

	len = strlen(path);
	if(path[len-1] == '\n') path[--len] = '\0';

	TrimString(path);

	if(DirExists(path))
	{
		dirh = OpenDirectory(path);
		while(ReadDirEntry(dirh, buffer, sizeof(buffer), type))
		{
			len = strlen(buffer);
			if(buffer[len-1] == '\n') buffer[--len] = '\0';

			TrimString(buffer);

			if(!StrEqual(buffer, "", false) && !StrEqual(buffer, ".", false) && !StrEqual(buffer, "..", false))
			{
				strcopy(tmp_path, 255, path);
				StrCat(tmp_path, 255, "/");
				StrCat(tmp_path, 255, buffer);
				if(type == FileType_File && downloadtype) ReadItem(tmp_path);
			}
		}
	}
	else if(downloadtype) ReadItem(path);
	if(dirh != null) CloseHandle(dirh);
}

public void OnClientPostAdminCheck(int client)
{
	// Save the client auth string(steam)
//	GetClientAuthString(client, authid[client], sizeof(authid[]));
	GetClientAuthId(client, AuthId_Steam2, authid[client], sizeof(authid[]));
	bRandomSkin[client] = true;
	bTPView[client] = false;
}

public Action Cmd_Model(int client, int args)
{
	if(bEnable && IsValidClient(client) && (mainmenu = BuildMainMenu(client)) == null
	&& (bAdminOnly && GetUserAdmin(client) != INVALID_ADMIN_ID) || !bAdminOnly)
			mainmenu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

stock bool CheckFlagAccess(int client, int access_flag)
{
	static AdminId id;
	if((id = GetUserAdmin(client)) == INVALID_ADMIN_ID) return false;

	static AdminFlag flag;
	return FindFlagByChar(access_flag, flag) && GetAdminFlag(id, flag, Access_Effective);
}

stock void ReadItem(char[] buffer)
{
	int len = strlen(buffer);
	if(buffer[len-1] == '\n') buffer[--len] = '\0';

	TrimString(buffer);

	if(len >= 2 && buffer[0] == '/' && buffer[1] == '/')
	{
		if(StrContains(buffer, "//") > -1) ReplaceString(buffer, 255, "//", "");
	}
	else if(buffer[0] && FileExists(buffer)) AddFileToDownloadsTable(buffer);
}

stock Menu BuildMainMenu(int client)
{
	if(!KvGotoFirstSubKey(kv)) return null;

	Menu menu = CreateMenu(Menu_Group, MENU_ACTIONS_ALL);

	static int items;
	items = 0;
	static char buffer[30], accessFlag[2];
	AdminId admin = GetUserAdmin(client);
	do
	{
		if(bAdminGroup)
		{
			// check if they have access
			static char group[30], temp[2];
			KvGetString(kv, "Admin", group, sizeof(group));
			static int count;
			count = GetAdminGroupCount(admin);
			for(int i; i < count; i++)
			{
				if(FindAdmGroup(group) == GetAdminGroup(admin, i, temp, sizeof(temp)))
				{
					// Get the model group name and add it to the menu
					KvGetSectionName(kv, buffer, sizeof(buffer));
					menu.AddItem(buffer, buffer);
					items++;
				}
			}
		}

		KvGetString(kv, "admin", accessFlag, sizeof(accessFlag));

		if(!accessFlag[0] || CheckFlagAccess(client, accessFlag[0]))
		{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			menu.AddItem(buffer, buffer);
			items++;
		}
	}
	while(KvGotoNextKey(kv));
	KvRewind(kv);

	menu.AddItem("none","None");
	menu.SetTitle("%s (%i categories):\n ", PLUGIN_NAME, items);

	return menu;
}

public int Menu_Group(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			bTPView[client] = true;
			ToggleView(client);
		}
		// User has selected a model group
		case MenuAction_Select:
		{
			if(!IsValidClient(client)) return 0;

			char info[30];
			if(!menu.GetItem(param, info, sizeof(info))) return 0;

			//tigeox
			// Check to see if the user has decided they don't want a model
			//(e.g. go to a stock model)
			if(StrEqual(info,"none"))
			{
				// Clear their saved model so that the next time
				// they spawn, they are able to use a stock model
				if(!GetClientTeam(client))
				{
					KvSetString(playermodelskv, authid[client], "");
					KvRewind(playermodelskv);
				}

				bRandomSkin[client] = true;
				ForceSkin(client);

				bTPView[client] = false;
				ToggleView(client);

				// We don't need to go any further, return
				return 0;
			}

			// User selected a group
			// advance kv to this group
			KvJumpToKey(kv, info);
			if(!GetClientTeam(client)) KvJumpToKey(kv, "List");	// Show models
			else return 0;										// They must be spectator, return
			// Get the first model
			KvGotoFirstSubKey(kv);

			// Create the menu
			Menu tempmenu = CreateMenu(Menu_Model, MENU_ACTIONS_ALL);

			// Add the models to the menu
			static int items;
			static char buffer[30], path[256];
			items = 0;
			do
			{
				// Add the model to the menu
				KvGetSectionName(kv, buffer, sizeof(buffer));
				KvGetString(kv, "path", path, sizeof(path),"");
				tempmenu.AddItem(path, buffer);
				items++;
			}
			while(KvGotoNextKey(kv));
			// Rewind the KVs
			KvRewind(kv);
			// Set the menu title to the model group name
			tempmenu.SetTitle("%s\n  %s (%i pcs):\n ", PLUGIN_NAME, info, items);
			tempmenu.ExitBackButton = true;
			tempmenu.ExitButton = false;
			tempmenu.Display(client, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			bTPView[client] = false;
			ToggleView(client);
		}
		case MenuAction_End: CloseHandle(menu);
	}
	return 0;
}

public int Menu_Model(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			bTPView[client] = true;
			ToggleView(client);
		}
		// User choose a model
		case MenuAction_Select:
		{
			if(!IsValidClient(client)) return;

			char model[256];
			if(!menu.GetItem(param, model, sizeof(model))) return;

			ApplyModel(client, model);

			// Save the user's choice so it is automatically applied
			// each time they spawn
			if(!GetClientTeam(client))
			{
				bRandomSkin[client] = false;
				KvSetString(playermodelskv, authid[client], model);
				KvRewind(playermodelskv);
			}

			(mainmenu = BuildMainMenu(client)).Display(client, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			if(param == MenuCancel_ExitBack) (mainmenu = BuildMainMenu(client)).Display(client, MENU_TIME_FOREVER);
			else
			{
				bTPView[client] = false;
				ToggleView(client);
			}
		}
		// If they picked exit, close the menu handle
		case MenuAction_End: CloseHandle(menu);
	}
}

stock void ToggleView(int client)
{
	if(IsValidClient(client))
	{
		if(bTPView[client])
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
			SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
			SetEntProp(client, Prop_Send, "m_iFOV", 70);
		}
		else
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
			SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
			SetEntProp(client, Prop_Send, "m_iFOV", 90);
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnable) return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	bTPView[client] = false;
	if(!IsValidClient(client)) return;

	if(bSpawnTimer) CreateTimer(1.0, Timer_Spawn, GetClientUserId(client));
	else ApplyModelFromCfg(client);
	ForceSkin(client);
}

public Action Timer_Spawn(Handle timer, any userid)
{
	ApplyModelFromCfg(GetClientOfUserId(userid));
}

stock void ApplyModelFromCfg(int client)
{
	if(!IsValidClient(client) || GetClientTeam(client)) return;

	static char model[256];
	KvGetString(playermodelskv, authid[client], model, sizeof(model), "");
	bRandomSkin[client] = !model[0];
	ApplyModel(client, model);
	KvRewind(playermodelskv);
}

stock void ForceSkin(const int client)
{
	if(!bForceSkin || !bSpawnTimer || !bRandomSkin[client] || GetClientTeam(client)) return;

	ApplyModel(client, sForcedSkins[GetRandomInt(0, iForcedSkins - 1)]);
}

stock void ApplyModel(const int client, const char[] model)
{
	if(!model[0] || !IsModelPrecached(model)) return;

	SetEntityModel(client, model);
	SetEntityRenderColor(client);
}

stock bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}