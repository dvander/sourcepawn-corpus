// Based on the code of the plugin "SM Skinchooser HL2DM" v2.3 by Andi67
#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>
#include <sdktools_stringtables>

#define MAX_MODELS 24

#if SOURCEMOD_V_MINOR > 10
	#define PL_NAME	"[NMRiH] Skins"
	#define PL_VER	"1.0.1"
#endif

static const char
#if SOURCEMOD_V_MINOR < 11
	PL_NAME[]	= "[NMRiH] Skins",
	PL_VER[]	= "1.0.1",
#endif
// Paths to configuration files
	CFG_SKINS[]	= "data/nmrih_skins_playermodels.ini",
	CFG_DL[]	= "configs/nmrih_skins/downloads_list.ini",
	CFG_FORCE[]	= "configs/nmrih_skins/forced_skins.ini",
	CFG_MENU[]	= "configs/nmrih_skins/skins_menu.ini";

enum
{
	CV_Enable,
	CV_Group,
	CV_Admin,
	CV_Timer,
	CV_Force,

	CV_Total
};

KeyValues
	kvList,
	kvPref;
bool
	bLate,
	bDLType,
	bCVar[CV_Total],
	bTPView[MAXPLAYERS+1],
	bRandom[MAXPLAYERS+1];
int
	iForcedSkins,
	iTotalSkins;
char
	sSID[MAXPLAYERS+1][35],
	sForced[MAX_MODELS][PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Skins menu with 3rd person view for NMRiH",
	author		= "Grey83",
	url			= "https://forums.alliedmods.net/showthread.php?t=301319"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
}

public void OnPluginStart()
{
	CreateConVar("nmrih_skins_version", PL_VER, PL_NAME, FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);

	ConVar cvar;
	AddBoolCVar(cvar, "sm_skins_enable",	true,	"Enable/Disable plugin", FCVAR_NOTIFY, CVarChange_Enable, CV_Enable);
	AddBoolCVar(cvar, "sm_skins_admingroup",true,	"Enable/Disable the possebility to use the Groupsystem", _, CVarChange_AdminGroup, CV_Group);
	AddBoolCVar(cvar, "sm_skins_adminonly",	false,	"Enable/Disable deny of access to the menu except for admins", _, CVarChange_AdminOnly, CV_Admin);
	AddBoolCVar(cvar, "sm_skins_spawntimer",true,	"Enable/Disable a timer that changes the model a second after the event 'player_spawn'", _, CVarChange_SpawnTimer, CV_Timer);
	AddBoolCVar(cvar, "sm_skins_forceskin",	true,	"Players get a model regardless of whether they chose the model or not", _, CVarChange_ForceSkin, CV_Force);

	AutoExecConfig(true, "nmrih_skins");

	RegConsoleCmd("sm_model", Cmd_Model);
	RegConsoleCmd("sm_models", Cmd_Model);
	RegConsoleCmd("sm_skin", Cmd_Model);
	RegConsoleCmd("sm_skins", Cmd_Model);

	HookEvent("player_spawn", Event_PlayerSpawn);

	// Load the player's model settings
	char file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), CFG_SKINS);
	kvPref = CreateKeyValues("Models");
	FileToKeyValues(kvPref, file);

	if(bLate)
	{
		for(int i = 1; i <= MaxClients; i++) if(IsClientAuthorized(i)) OnClientPostAdminCheck(i);
		bLate = false;
	}
}

stock void AddBoolCVar(ConVar &cvar, const char[] name, const bool defVal, const char[] descr="", int flags=0, ConVarChanged callback, int type)
{
	cvar = CreateConVar(name, defVal ? "1" : "0", descr, _, true, _, true, 1.0);
	cvar.AddChangeHook(callback);
	bCVar[type] = cvar.BoolValue;
}

public void OnPluginEnd()
{
	// Write the the player's model settings
	char file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), CFG_SKINS);
	KeyValuesToFile(kvPref, file);
	CloseHandle(kvPref);
}

public void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bCVar[CV_Enable] = cvar.BoolValue;
}

public void CVarChange_AdminGroup(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bCVar[CV_Group] = cvar.BoolValue;
}

public void CVarChange_AdminOnly(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bCVar[CV_Admin] = cvar.BoolValue;
}

public void CVarChange_SpawnTimer(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bCVar[CV_Timer] = cvar.BoolValue;
}

public void CVarChange_ForceSkin(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bCVar[CV_Force] = cvar.BoolValue;
}

public void OnMapStart()
{
	iTotalSkins = 0;

	char buffer[PLATFORM_MAX_PATH];
	int models_count, len;

	BuildPath(Path_SM, buffer, sizeof(buffer), CFG_FORCE);

	//open precache file and add everything to download table
	Handle file = OpenFile(buffer, "r");
	while(ReadFileLine(file, buffer, PLATFORM_MAX_PATH) && models_count < MAX_MODELS)
	{
		// Strip leading and trailing whitespace
		TrimString(buffer);
		len = strlen(buffer);

		// Skip comments
		if(len > 1 && buffer[0] == '/' && buffer[1] == '/')
			continue;

		len -= 4;
		// Skip files with wrong types
		if(strcmp(buffer[len], ".mdl", false))
		{
			LogError("File '%s' has the wrong type: '%s'.", buffer, buffer[len]);
			continue;
		}
/*
		// Skip non existing files
		if(!FileExists(buffer))
		{
			LogError("Model '%s' doesn't exists.", buffer);
			continue;
		}
*/
		// Tell Clients to cache model
		if(PrecacheModel(buffer, true))
		{
			// Tell Clients to download files
			AddFileToDownloadsTable(buffer);
			strcopy(sForced[models_count++], strlen(buffer)+1, buffer);
		}
		else LogError("Can't precache model '%s'.", buffer);
	}
	if(file) CloseHandle(file);
	iForcedSkins = models_count;

	BuildPath(Path_SM, buffer, sizeof(buffer), CFG_MENU);
	kvList = CreateKeyValues("Commands");
	FileToKeyValues(kvList, buffer);
	if(!KvGotoFirstSubKey(kvList)) return;

	do
	{
		KvJumpToKey(kvList, "List");
		KvGotoFirstSubKey(kvList);
		do
		{
			KvGetString(kvList, "path", buffer, sizeof(buffer));
			if(PrecacheModel(buffer, true)) iTotalSkins++;
		}
		while(KvGotoNextKey(kvList));
		KvGoBack(kvList);
		KvGoBack(kvList);
	}
	while(KvGotoNextKey(kvList));
	KvRewind(kvList);

	if(bCVar[CV_Enable])
	{
		char path[PLATFORM_MAX_PATH], tmp_path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, buffer, sizeof(buffer), CFG_DL);
		file = OpenFile(buffer, "r");
		if(!file) return;

		bDLType = true;
		Handle dirh;
		FileType type;
		while(ReadFileLine(file, path, sizeof(path)))
		{
			len = strlen(path);
			if(path[len-1] == '\n') path[--len] = 0;
			TrimString(path);
			if(IsEndOfFile(file)) break;

			if(!path[0]) continue;

			if(DirExists(path))
			{
				dirh = OpenDirectory(path);
				while(ReadDirEntry(dirh, buffer, sizeof(buffer), type))
				{
					len = strlen(buffer);
					if(buffer[len-1] == '\n') buffer[--len] = 0;

					TrimString(buffer);

					if(!StrEqual(buffer, "", false) && !StrEqual(buffer, ".", false) && !StrEqual(buffer, "..", false))
					{
						strcopy(tmp_path, 255, path);
						StrCat(tmp_path, 255, "/");
						StrCat(tmp_path, 255, buffer);
						if(type == FileType_File && bDLType) ReadItem(tmp_path);
					}
				}
			}
			else if(bDLType) ReadItem(path);
			if(dirh) CloseHandle(dirh);
		}
		if(file) CloseHandle(file);
	}

	PrintToServer("%s:\n	Total: %i\n	Forced: %i", PL_NAME, iTotalSkins, iForcedSkins);
}

public void OnMapEnd()
{
	CloseHandle(kvList);
}

public void OnClientPostAdminCheck(int client)
{
	// Save the client auth string(steam)
	GetClientAuthId(client, AuthId_Steam2, sSID[client], sizeof(sSID[]));
	bRandom[client] = true;
	bTPView[client] = false;
}

public Action Cmd_Model(int client, int args)
{
	if(bCVar[CV_Enable] && IsValidClient(client) && (!bCVar[CV_Admin] || GetUserAdmin(client) != INVALID_ADMIN_ID)) SendMainMenu(client);

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
	if(buffer[len-1] == '\n') buffer[--len] = 0;

	TrimString(buffer);

	if(len > 1 && buffer[0] == '/' && buffer[1] == '/')
	{
		if(StrContains(buffer, "//") > -1) ReplaceString(buffer, 255, "//", "");
	}
	else if(buffer[0]/* && FileExists(buffer)*/) AddFileToDownloadsTable(buffer);
}

stock void SendMainMenu(int client)
{
	if(!KvGotoFirstSubKey(kvList)) return;

	static char buffer[30], accessFlag[2];
	int items;
	AdminId admin = GetUserAdmin(client);
	Menu menu = CreateMenu(Menu_Group, MENU_ACTIONS_ALL);
	do
	{
		if(bCVar[CV_Group])
		{	// check if they have access
			static char group[30], temp[2];
			KvGetString(kvList, "Admin", group, sizeof(group));
			static int count;
			count = GetAdminGroupCount(admin);
			for(int i; i < count; i++) if(FindAdmGroup(group) == GetAdminGroup(admin, i, temp, sizeof(temp)))
			{	// Get the model group name and add it to the menu
				KvGetSectionName(kvList, buffer, sizeof(buffer));
				menu.AddItem(buffer, buffer);
				items++;
			}
		}

		KvGetString(kvList, "admin", accessFlag, sizeof(accessFlag));

		if(!accessFlag[0] || CheckFlagAccess(client, accessFlag[0]))
		{
			KvGetSectionName(kvList, buffer, sizeof(buffer));
			menu.AddItem(buffer, buffer);
			items++;
		}
	}
	while(KvGotoNextKey(kvList));
	KvRewind(kvList);

	if(!items)
	{
		CloseHandle(menu);
		PrintToChat(client, "\x01[\x04Skins\x01] \x03No skins available");
		return;
	}

	menu.AddItem("none","None");
	menu.SetTitle("%s (%i categories):\n ", PL_NAME, items);

	menu.Display(client, MENU_TIME_FOREVER);
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
					KvSetString(kvPref, sSID[client], "");
					KvRewind(kvPref);
				}

				bRandom[client] = true;
				ForceSkin(client);

				bTPView[client] = false;
				ToggleView(client);

				// We don't need to go any further, return
				return 0;
			}

			// User selected a group
			// advance kv to this group
			KvJumpToKey(kvList, info);
			if(!GetClientTeam(client)) KvJumpToKey(kvList, "List");	// Show models
			else return 0;										// They must be spectator, return
			// Get the first model
			KvGotoFirstSubKey(kvList);

			// Create the menu
			Menu tempmenu = CreateMenu(Menu_Model, MENU_ACTIONS_ALL);

			// Add the models to the menu
			static int items;
			static char buffer[30], path[PLATFORM_MAX_PATH];
			items = 0;
			do
			{
				// Add the model to the menu
				KvGetSectionName(kvList, buffer, sizeof(buffer));
				KvGetString(kvList, "path", path, sizeof(path));
				tempmenu.AddItem(path, buffer);
				items++;
			}
			while(KvGotoNextKey(kvList));
			// Rewind the KVs
			KvRewind(kvList);
			// Set the menu title to the model group name
			tempmenu.SetTitle("%s\n  %s (%i pcs):\n ", PL_NAME, info, items);
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

			char model[PLATFORM_MAX_PATH];
			if(!menu.GetItem(param, model, sizeof(model))) return;

			ApplyModel(client, model);

			// Save the user's choice so it is automatically applied
			// each time they spawn
			if(!GetClientTeam(client))
			{
				bRandom[client] = false;
				KvSetString(kvPref, sSID[client], model);
				KvRewind(kvPref);
			}

			SendMainMenu(client);
		}
		case MenuAction_Cancel:
		{
			if(param == MenuCancel_ExitBack) SendMainMenu(client);
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
	if(!IsValidClient(client) || !IsPlayerAlive(client)) return;

	if(bTPView[client])
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 70);
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);	// -1
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!bCVar[CV_Enable]) return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	bTPView[client] = false;
	if(!IsValidClient(client)) return;

	if(bCVar[CV_Timer]) CreateTimer(1.0, Timer_Spawn, GetClientUserId(client));
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

	static char model[PLATFORM_MAX_PATH];
	KvGetString(kvPref, sSID[client], model, sizeof(model));
	bRandom[client] = !model[0];
	ApplyModel(client, model);
	KvRewind(kvPref);
}

stock void ForceSkin(const int client)
{
	if(bCVar[CV_Force] && bCVar[CV_Timer] && bRandom[client] && IsPlayerAlive(client))
		ApplyModel(client, sForced[GetRandomInt(0, iForcedSkins - 1)]);
}

stock void ApplyModel(const int client, const char[] model)
{
	if(!model[0] || !IsModelPrecached(model)) return;

	SetEntityModel(client, model);
	SetEntityRenderColor(client);
}

stock bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}