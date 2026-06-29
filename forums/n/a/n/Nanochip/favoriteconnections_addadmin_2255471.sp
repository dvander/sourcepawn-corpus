#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.3"

//CVAR Handlers
new Handle:hEnable = INVALID_HANDLE;
new Handle:hFlags = INVALID_HANDLE;
new Handle:hImmunity = INVALID_HANDLE;
new Handle:hGroup = INVALID_HANDLE;
new Handle:hChatColors = INVALID_HANDLE;
new Handle:hAdminPlugin = INVALID_HANDLE;

//File Path for Key Values
static String:kvPath[PLATFORM_MAX_PATH];

//SQL Magic
new Handle:hInsertQuery = INVALID_HANDLE;
new Handle:hCheckQuery = INVALID_HANDLE;
new Handle:hSelectAdminID = INVALID_HANDLE;
new Handle:hSelectGroupID = INVALID_HANDLE;
new Handle:hCheckGroup = INVALID_HANDLE;
new Handle:hInsertAdminGroupIDs = INVALID_HANDLE;

new String:InsertQuery[] = "INSERT INTO sm_admins (authtype, identity, flags, immunity, name) VALUES ('steam', ?, ?, ?, ?)";
new String:CheckQuery[] = "SELECT EXISTS (SELECT * FROM sm_admins WHERE identity = ?)";
new String:SelectAdminID[] =	"SELECT id FROM sm_admins WHERE identity = ?";
new String:SelectGroupID[] = "SELECT id FROM sm_groups WHERE name = ?";
new String:CheckGroup[] = "SELECT EXISTS (SELECT * FROM sm_groups WHERE name = ?)";
new String:InsertAdminGroupIDs[] = "INSERT INTO sm_admins_groups (admin_id, group_id, inherit_order) VALUES (?, ?, '0')";

new AdminID;
new GroupID;

//My plugin information
public Plugin:myinfo =
{
	name = "Favorite Connections: Add Admin",
  	author = "Nanochip",
	version = PLUGIN_VERSION,
  	description = "Detect when a player connects to the server via favorites and add them to admins.cfg.",
	url = "http://thecubeserver.org/"
};

public OnPluginStart()
{
  	//Creating CVARS
	CreateConVar("favoriteconnections_addadmin_version", PLUGIN_VERSION, "Favorite Connections: Add Admins Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hEnable = CreateConVar("favoriteconnections_addadmin_enable", "1", "Enable the plugin? 1 = Enable, 0 = Disable", FCVAR_NOTIFY);
	hFlags = CreateConVar("favoriteconnections_addadmin_flags", "", "Set the flags of the user who joined via favorites (leave it blank to omit)", FCVAR_NOTIFY);
	hImmunity = CreateConVar("favoriteconnections_addadmin_immunity", "", "Set the immunity level of the user who joined via favorites (leave it blank to omit)", FCVAR_NOTIFY);
	hGroup = CreateConVar("favoriteconnections_addadmin_group", "", "Set the group of the user who joined via favorites (leave it blank to omit)", FCVAR_NOTIFY);
	hChatColors = CreateConVar("favoriteconnections_addadmin_customchatcolors", "0", "Do you have the custom-chatcolors plugin? Yes = 1 No = 0", FCVAR_NOTIFY);
	hAdminPlugin = CreateConVar("favoriteconnections_addadmin_adminplugin", "0", "Which Admin Plugin is running? 0 = Flatfile, 1 = SQL Admin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
  
  	//Auto execute and create the config for CVARS
	AutoExecConfig(true, "FavoriteConnections_AddAdmin");
	
  	//Building the file path for KV
	BuildPath(Path_SM, kvPath, sizeof(kvPath), "configs/admins.cfg");
	if(GetConVarBool(hAdminPlugin)) {
		if(!PrepareQuery()) {
			PrintToServer("[Favorite Connections: Add Admin] Error while connecting to database and preparing statement");
		}
	}
}

public Action:ClientConnectedViaFavorites(client)
{
  	//Should the plugin be enabled?
	if (!GetConVarBool(hEnable)) {
		return Plugin_Continue;
	}
	
	//Declaring variables
	new String:name[256], String:authid[128], String:flags[32], String:immunity[10], String:group[256];
	
	//Assigning variables
	GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
	GetClientName(client, name, sizeof(name));
	GetConVarString(hFlags, flags, sizeof(flags));
	GetConVarString(hImmunity, immunity, sizeof(immunity));
	GetConVarString(hGroup, group, sizeof(group));
	
	if(GetConVarBool(hAdminPlugin)) {
		SQL_BindParamString(hCheckQuery, 0, authid, true);
		if(!SQL_Execute(hCheckQuery)) {
			decl String:Error[1024];
			SQL_GetError(hCheckQuery, Error, sizeof(Error));
			PrintToServer("[Favorite Connections: Add Admin] An error has occured while querying the Database: %s", Error);
			return Plugin_Continue;
		}
		
		if(SQL_FetchRow(hCheckQuery)) {
			if(SQL_FetchInt(hCheckQuery, 0) == 1) {
				return Plugin_Continue;
			}
		} else {
			PrintToServer("[Favorite Connections: Add Admin] An error has occured while fetching the Query Result");
			return Plugin_Continue;
		}
		
		new immune = StringToInt(immunity);
		SQL_BindParamString(hInsertQuery, 0, authid, true);
		SQL_BindParamString(hInsertQuery, 1, flags, true);
		SQL_BindParamInt(hInsertQuery, 2, immune, true);
		SQL_BindParamString(hInsertQuery, 3, name, true);
		if(!SQL_Execute(hInsertQuery)) {
			decl String:Error[1024];
			SQL_GetError(hInsertQuery, Error, sizeof(Error));
			PrintToServer("[Favorite Connections: Add Admin] An error has occured while writing to the Database: %s", Error);
		}
		if (!StrEqual(group, ""))
		{
			//If the group doesn't exist then return
			if (!IsValidGroup(group))
			{
				PrintToServer("[Favorite Connections: Add Admin] %s doesn't exist in the Database! Fix the cvar!", group);
				return Plugin_Continue;
			}
			
			//Get the admin ID
			SQL_BindParamString(hSelectAdminID, 0, authid, true);
			if(!SQL_Execute(hSelectAdminID))
			{
				decl String:Error[1024];
				SQL_GetError(hSelectAdminID, Error, sizeof(Error));
				PrintToServer("[Favorite Connections: Add Admin] An error has occurred while fetching admin ID from the Database: %s", Error);
				return Plugin_Continue;
			}
			if (SQL_FetchRow(hSelectAdminID))
			{
				AdminID = SQL_FetchInt(hSelectAdminID, 0);
			}
			
			//Get the group ID
			SQL_BindParamString(hSelectGroupID, 0, group, true);
			if(!SQL_Execute(hSelectGroupID))
			{
				decl String:Error[1024];
				SQL_GetError(hSelectGroupID, Error, sizeof(Error));
				PrintToServer("[Favorite Connections: Add Admin] An error has occurred while fetching group ID from the Database: %s", Error);
				return Plugin_Continue;
			}
			if (SQL_FetchRow(hSelectGroupID))
			{
				GroupID = SQL_FetchInt(hSelectGroupID, 0);
			}
			
			//Insert the admin and group IDs into the database
			SQL_BindParamInt(hInsertAdminGroupIDs, 0, AdminID, true);
			SQL_BindParamInt(hInsertAdminGroupIDs, 1, GroupID, true);
			if(!SQL_Execute(hInsertAdminGroupIDs))
			{
				decl String:Error[1024];
				SQL_GetError(hInsertAdminGroupIDs, Error, sizeof(Error));
				PrintToServer("[Favorite Connections: Add Admin] An error has occurred while inserting admin and group IDs to the Database: %s", Error);
				return Plugin_Continue;
			}
		}
		PrintToServer("[Favorite Connections: Add Admin] %s(%s) joined the server via favorites - added to Admin SQL Database", name, authid);
		
		//Reload admins.cfg cache
		ServerCommand("sm_reloadadmins");
		
		//If custom-chatcolors is present, reload the cache.
		if (GetConVarBool(hChatColors)) {
			ServerCommand("sm_reloadccc");
		}
	} else {
		//Create File Handler for Key Values in admins.cfg
		new Handle:hFileHandler = CreateKeyValues("Admins");
		FileToKeyValues(hFileHandler, kvPath);
	  
		//Check if the user already exists in the admins.cfg
		if (KvJumpToKey(hFileHandler, authid, false))
		{
			return Plugin_Continue;
		}
		KvRewind(hFileHandler);
		
		//Add the user to admins.cfg
		if (KvJumpToKey(hFileHandler, authid, true))
		{
			KvSetString(hFileHandler, "name", name);
			KvSetString(hFileHandler, "auth", "steam");
			KvSetString(hFileHandler, "identity", authid);
			if (!StrEqual(flags, ""))
				KvSetString(hFileHandler, "flags", flags);
			if (!StrEqual(immunity, ""))
				KvSetString(hFileHandler, "immunity", immunity);
			if (!StrEqual(group, ""))
				KvSetString(hFileHandler, "group", group);
		}
		KvRewind(hFileHandler);
		KeyValuesToFile(hFileHandler, kvPath);
		CloseHandle(hFileHandler);
		
		//Log that the user was added to admins.cfg
		PrintToServer("[Favorite Connections: Add Admin] %s(%s) joined the server via favorites - added to admins.cfg", name, authid);
		
		//Reload admins.cfg cache
		ServerCommand("sm_reloadadmins");
		
		//If custom-chatcolors is present, reload the cache.
		if (GetConVarBool(hChatColors)) {
			ServerCommand("sm_reloadccc");
		}
	}
	return Plugin_Continue;
}

bool:IsValidGroup(String:group[])
{
	SQL_BindParamString(hCheckGroup, 0, group, true);
	if(!SQL_Execute(hCheckGroup))
	{
		decl String:Error[1024];
		SQL_GetError(hCheckGroup, Error, sizeof(Error));
		PrintToServer("An error has occured while querying the Database: %s", Error);
		return false;
	}
	if(SQL_FetchRow(hCheckGroup)) 
	{
		if(SQL_FetchInt(hCheckGroup, 0) == 1) 
		{
			return true;
		}
	}
	return false;
}

bool:PrepareQuery() {
	decl String:error[255];
	new Handle:db = INVALID_HANDLE;

	if (SQL_CheckConfig("admins")) {
		db = SQL_Connect("admins", true, error, sizeof(error));
	} else {
		db = SQL_Connect("default", true, error, sizeof(error));
	}

	if (db == INVALID_HANDLE) {
		PrintToServer("Could not connect to database \"default\": %s", error);
		return false;
	}
	if (hInsertQuery == INVALID_HANDLE) {
		hInsertQuery = SQL_PrepareQuery(db, InsertQuery, error, sizeof(error));
		if (hInsertQuery == INVALID_HANDLE) {
			PrintToServer("Could not prepare InsertQuery statement: %s", error);
			return false;
		}
	}
	if (hCheckQuery == INVALID_HANDLE) {
		hCheckQuery = SQL_PrepareQuery(db, CheckQuery, error, sizeof(error));
		if (hCheckQuery == INVALID_HANDLE) {
			PrintToServer("Could not prepare CheckQuery statement: %s", error);
			return false;
		}
	}
	if (hSelectAdminID == INVALID_HANDLE) {
		hSelectAdminID = SQL_PrepareQuery(db, SelectAdminID, error, sizeof(error));
		if (hSelectAdminID == INVALID_HANDLE) {
			PrintToServer("Could not prepare SelectAdminID statement: %s", error);
			return false;
		}
	}
	if (hSelectGroupID == INVALID_HANDLE) {
		hSelectGroupID = SQL_PrepareQuery(db, SelectGroupID, error, sizeof(error));
		if (hSelectGroupID == INVALID_HANDLE) {
			PrintToServer("Could not prepare SelectGroupID statement: %s", error);
			return false;
		}
	}
	if (hCheckGroup == INVALID_HANDLE) {
		hCheckGroup = SQL_PrepareQuery(db, CheckGroup, error, sizeof(error));
		if (hCheckGroup == INVALID_HANDLE) {
			PrintToServer("Could not prepare CheckGroup statement: %s", error);
			return false;
		}
	}
	if (hInsertAdminGroupIDs == INVALID_HANDLE) {
		hInsertAdminGroupIDs = SQL_PrepareQuery(db, InsertAdminGroupIDs, error, sizeof(error));
		if (hInsertAdminGroupIDs == INVALID_HANDLE) {
			PrintToServer("Could not prepare InsertAdminGroupIDs statement: %s", error);
			return false;
		}
	}
	return true;
}
