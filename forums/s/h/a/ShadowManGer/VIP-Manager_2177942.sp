#include <sourcemod>

#define Version "2.2.1"

typedef VIPSelectedCallback = function void(int caller, const char[] name, const char[] steamId, int duration, any additionalData);
typedef VIPCheckedCallback = function void(int vipClient, bool expired);

Database connection;
ConVar authTypeConVar;
AuthIdType authType = AuthId_Engine;

Handle onAddVIPForward;
Handle onRemoveVIPForward;
Handle onDurationChangedForward;

public Plugin myinfo = {
	name = "VIP-Manager",
	author = "Shadow_Man",
	description = "Manage VIPs on your server",
	version = Version,
	url = "http://cf-server.pfweb.eu"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max)
{
	RegPluginLibrary("VIP-Manager");

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_vipm_version", Version, "Version of VIP-Manager", FCVAR_PLUGIN | FCVAR_SPONLY);
	authTypeConVar = CreateConVar("sm_vipm_authid_format", "engine", "Sets which SteamId format should be used.\nEngine (default) | Steam2 | Steam3 | Steam64", FCVAR_PLUGIN);

	RegAdminCmd("sm_vipm", Cmd_PrintHelp, ADMFLAG_ROOT, "Lists all commands.");
	RegAdminCmd("sm_vipm_add", Cmd_AddVIP, ADMFLAG_ROOT, "Add a VIP.");
	RegAdminCmd("sm_vipm_rm", Cmd_RemoveVIP, ADMFLAG_ROOT, "Remove a VIP.");
	RegAdminCmd("sm_vipm_time", Cmd_ChangeVIPDuration, ADMFLAG_ROOT, "Change the duration for a VIP.");
	RegAdminCmd("sm_vipm_check", Cmd_CheckForExpiredVIPs, ADMFLAG_ROOT, "Check for expired VIPs.");

	onAddVIPForward = CreateGlobalForward("OnVIPAdded", ET_Ignore, Param_Cell, Param_String, Param_String, Param_Cell);
	onRemoveVIPForward = CreateGlobalForward("OnVIPRemoved", ET_Ignore, Param_Cell, Param_String, Param_String, Param_String);
	onDurationChangedForward = CreateGlobalForward("OnVIPDurationChanged", ET_Ignore, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell);

	ConnectToDatabase();
}

public void OnConfigsExecuted()
{
	ParseAuthIdFormat();
}

void ParseAuthIdFormat()
{
	char type[16];
	authTypeConVar.GetString(type, sizeof(type));

	if(StrEqual(type, "steam2", false))
		authType = AuthId_Steam2;
	else if(StrEqual(type, "steam3", false))
		authType = AuthId_Steam3;
	else if(StrEqual(type, "steam64", false))
		authType = AuthId_SteamID64;
	else
		authType = AuthId_Engine;
}

public Action Cmd_PrintHelp(int client, int args)
{
	ReplyToCommand(client, "sm_vipm | Lists all commands.");
	ReplyToCommand(client, "sm_vipm_add <\"name\"> <minutes> [\"SteamId\"] | Add a VIP. If SteamID is give, it will be used.");
	ReplyToCommand(client, "sm_vipm_rm <\"name\"> | Remove a VIP");
	ReplyToCommand(client, "sm_vipm_time <set|add|sub> <\"name\"> <minutes> | Change the duration for a VIP.");
	ReplyToCommand(client, "sm_vipm_check | Checks for expired VIPs.");

	return Plugin_Handled;
}

public Action Cmd_AddVIP(int client, int args)
{
	if(connection == null) {
		ReplyToCommand(client, "There is currently no connection to the SQL server");
		return Plugin_Handled;
	}

	if(args < 2) {
		ReplyToCommand(client, "Usage: sm_vipm_add <\"name\"> <minutes> [\"SteamId\"]");
		return Plugin_Handled;
	}

	char name[MAX_NAME_LENGTH];
	char steamId[64];

	if(args == 2) {
		char searchName[MAX_NAME_LENGTH];
		GetCmdArg(1, searchName, sizeof(searchName));

		if(!SearchClient(searchName, name, sizeof(name), steamId, sizeof(steamId))) {
			ReplyToCommand(client, "Can't find client '%s'", searchName);
			return Plugin_Handled;
		}
	}
	else {
		GetCmdArg(1, name, sizeof(name));
		GetCmdArg(3, steamId, sizeof(steamId));
	}

	char durationString[16];
	GetCmdArg(2, durationString, sizeof(durationString));

	AddVIP(client, name, steamId, StringToInt(durationString));

	return Plugin_Handled;
}

void AddVIP(int caller, const char[] name, const char[] steamId, int duration)
{
	int len = strlen(name) * 2 + 1;
	char[] escapedName = new char[len];
	connection.Escape(name, escapedName, len);

	len = strlen(steamId) * 2 + 1;
	char[] escapedSteamId = new char[len];
	connection.Escape(steamId, escapedSteamId, len);

	if(duration < -1)
		duration = -1;

	DataPack pack = new DataPack();
	pack.WriteCell(caller);
	pack.WriteString(name);
	pack.WriteString(steamId);
	pack.WriteCell(duration);
	pack.Reset();

	char query[512];
	Format(query, sizeof(query), "INSERT INTO vips (steamId, name, duration) VALUES ('%s', '%s', %i);", escapedSteamId, escapedName, duration);
	connection.Query(AddVIPCallback, query, pack);
}

public void AddVIPCallback(Database db, DBResultSet result, char[] error, any data)
{
	DataPack pack = view_as<DataPack>(data);
	int caller = pack.ReadCell();

	if(result == null) {
		LogError("Error while adding VIP! Error: %s", error);
		ReplyClient(caller, "Can't add VIP! %s", error);

		delete pack;
		return;
	}

	char name[MAX_NAME_LENGTH];
	pack.ReadString(name, sizeof(name));

	char steamId[64];
	pack.ReadString(steamId, sizeof(steamId));

	int duration = pack.ReadCell();

	delete pack;

	int vipClient = FindPlayer(name);
	if(AddVIPToAdminCache(vipClient))
		ReplyClient(caller, "Successfully added '%s' as a VIP for %i minutes!", name, duration);
	else
		ReplyClient(caller, "Added '%s' as a VIP in database, but can't added VIP in admin cache!", name);

	Call_StartForward(onAddVIPForward);
	Call_PushCell(caller);
	Call_PushString(name);
	Call_PushString(steamId);
	Call_PushCell(duration);
	Call_Finish();
}

bool AddVIPToAdminCache(int client)
{
	if(client < 1 || !IsClientConnected(client) || ClientIsAdmin(client)) {
		NotifyPostAdminCheck(client);
		return false;
	}

	char steamId[64];
	GetClientAuthId(client, authType, steamId, sizeof(steamId));

	GroupId group = FindAdmGroup("VIP");
	if(group == INVALID_GROUP_ID) {
		PrintToServer("[VIP-Manager] Couldn't found group 'VIP'! Please create a group called 'VIP'.");

		NotifyPostAdminCheck(client);
		return false;
	}

	AdminId admin = CreateAdmin();
	AdminInheritGroup(admin, group);
	if(!BindAdminIdentity(admin, AUTHMETHOD_STEAM, steamId)) {
		RemoveAdmin(admin);

		NotifyPostAdminCheck(client);
		return false;
	}

	RunAdminCacheChecks(client);
	NotifyPostAdminCheck(client);
	return true;
}

public Action Cmd_RemoveVIP(int client, int args)
{
	if(connection == null) {
		ReplyToCommand(client, "There is currently no connection to the SQL server");
		return Plugin_Handled;
	}

	if(args < 1) {
		ReplyToCommand(client, "Usage: sm_vipm_rm <\"name\">");
		return Plugin_Handled;
	}

	char searchTerm[MAX_NAME_LENGTH];
	GetCmdArg(1, searchTerm, sizeof(searchTerm));

	SearchVIPByName(client, searchTerm, RemoveVIPByCommand);

	return Plugin_Handled;
}

void SearchVIPByName(int caller, const char[] searchTerm, VIPSelectedCallback callback, any additionalData = 0)
{
	char query[128];
	Format(query, sizeof(query), "SELECT * FROM vips WHERE name LIKE '%%%s%%';", searchTerm);

	DataPack pack = new DataPack();
	pack.WriteCell(caller);
	pack.WriteString(searchTerm);
	pack.WriteFunction(callback);
	pack.WriteCell(additionalData);
	pack.Reset();

	connection.Query(VIPSearchingResult, query, pack);
}

public void VIPSearchingResult(Database db, DBResultSet result, char[] error, any data)
{
	DataPack pack = view_as<DataPack>(data);
	int caller = pack.ReadCell();

	if(result == null) {
		LogError("Error while selecting VIP! Error: %s", error);
		ReplyClient(caller, "Can't select VIP! %s", error);

		delete pack;
		return;
	}

	char searchTerm[MAX_NAME_LENGTH];
	pack.ReadString(searchTerm, sizeof(searchTerm));

	if(result.RowCount == 0) {
		ReplyClient(caller, "Can't find a VIP with the name '%s'!", searchTerm);

		delete pack;
		return;
	}
	else if(result.RowCount > 1) {
		ReplyClient(caller, "Found more than one VIP with the name '%s'! Please specify the name more accurately!", searchTerm);

		delete pack;
		return;
	}

	result.FetchRow();

	char name[MAX_NAME_LENGTH];
	result.FetchString(1, name, sizeof(name));

	char steamId[64];
	result.FetchString(0, steamId, sizeof(steamId));

	int duration = result.FetchInt(3);

	Call_StartFunction(null, pack.ReadFunction());
	Call_PushCell(caller);
	Call_PushString(name);
	Call_PushString(steamId);
	Call_PushCell(duration);
	Call_PushCell(pack.ReadCell());
	Call_Finish();

	delete pack;
}

public void RemoveVIPByCommand(int caller, const char[] name, const char[] steamId, int duration, any nothing)
{
	char adminName[MAX_NAME_LENGTH];
	GetClientName(caller, adminName, sizeof(adminName));

	char reason[256];
	Format(reason, sizeof(reason), "Removed by admin '%s'", adminName);

	RemoveVIP(caller, name, steamId, reason);
}

void RemoveVIP(int caller, const char[] name, const char[] steamId, const char[] reason)
{
	int len = strlen(steamId) * 2 + 1;
	char[] escapedSteamId = new char[len];
	connection.Escape(steamId, escapedSteamId, len);

	char query[128];
	Format(query, sizeof(query), "DELETE FROM vips WHERE steamId = '%s';", escapedSteamId);

	DataPack pack = new DataPack();
	pack.WriteCell(caller);
	pack.WriteString(name);
	pack.WriteString(steamId);
	pack.WriteString(reason);
	pack.Reset();

	connection.Query(CallbackRemoveVIP, query, pack);
}

public void CallbackRemoveVIP(Database db, DBResultSet result, char[] error, any data)
{
	DataPack pack = view_as<DataPack>(data);
	int caller = pack.ReadCell();

	if(result == null) {
		LogError("Error while removing VIP! Error: %s", error);
		ReplyClient(caller, "Can't remove VIP! %s", error);

		delete pack;
		return;
	}

	char name[MAX_NAME_LENGTH];
	pack.ReadString(name, sizeof(name));

	char steamId[64];
	pack.ReadString(steamId, sizeof(steamId));

	char reason[256];
	pack.ReadString(reason, sizeof(reason));

	delete pack;

	RemoveVIPFromAdminCache(steamId);

	Call_StartForward(onRemoveVIPForward);
	Call_PushCell(caller);
	Call_PushString(name);
	Call_PushString(steamId);
	Call_PushString(reason);
	Call_Finish();

	ReplyClient(caller, "Removed VIP %s(%s)! Reason: %s", name, steamId, reason);
}

void RemoveVIPFromAdminCache(char[] steamId)
{
	AdminId admin = FindAdminByIdentity(AUTHMETHOD_STEAM, steamId);
	if(AdminInheritFromGroupVIP(admin))
		RemoveAdmin(admin);
}

bool AdminInheritFromGroupVIP(AdminId admin)
{
	if(admin == INVALID_ADMIN_ID)
		return false;

	int groupCount = GetAdminGroupCount(admin);
	for(int groupNumber = 0; groupNumber < groupCount; groupNumber++) {
		char groupName[8];
		GetAdminGroup(admin, groupNumber, groupName, sizeof(groupName));

		if(StrEqual(groupName, "VIP", false))
			return true;
	}

	return false;
}

public Action Cmd_ChangeVIPDuration(int client, int args)
{
	if(args != 3) {
		ReplyToCommand(client, "Usage: sm_vipm_time <set|add|sub> <\"name\"> <minutes>");
		return Plugin_Handled;
	}

	char searchTerm[MAX_NAME_LENGTH];
	GetCmdArg(2, searchTerm, sizeof(searchTerm));

	char minutesString[8];
	GetCmdArg(3, minutesString, sizeof(minutesString));

	int minutes = StringToInt(minutesString);
	if(minutes < 0)
		minutes *= -1;

	char mode[8];
	GetCmdArg(1, mode, sizeof(mode));

	if(StrEqual(mode, "set", false))
		SearchVIPByName(client, searchTerm, SetVIPDuration, minutes);
	else if(StrEqual(mode, "add", false))
		SearchVIPByName(client, searchTerm, AddVIPDuration, minutes);
	else if(StrEqual(mode, "sub", false))
		SearchVIPByName(client, searchTerm, SubVIPDuration, minutes);
	else
		ReplyToCommand(client, "Unknown mode '%s'! Please use 'set', 'add' or 'sub'.", mode);

	return Plugin_Handled;
}

public void SetVIPDuration(int caller, const char[] name, const char[] steamId, int duration, any newDuration)
{
	ChangeVIPDuration(caller, name, steamId, "set", duration, newDuration);
}

public void AddVIPDuration(int caller, const char[] name, const char[] steamId, int duration, any durationToAdd)
{
	int newDuration = duration + durationToAdd;
	ChangeVIPDuration(caller, name, steamId, "add", duration, newDuration);
}

public void SubVIPDuration(int caller, const char[] name, const char[] steamId, int duration, any durationToSub)
{
	int newDuration = duration - durationToSub;
	ChangeVIPDuration(caller, name, steamId, "sub", duration, newDuration);
}

void ChangeVIPDuration(int caller, const char[] name, const char[] steamId, const char[] mode, int oldDuration, int newDuration)
{
	char query[128];
	Format(query, sizeof(query), "UPDATE vips SET duration = %i WHERE steamId = '%s'", newDuration, steamId);

	DataPack pack = new DataPack();
	pack.WriteCell(caller);
	pack.WriteString(name);
	pack.WriteString(steamId);
	pack.WriteString(mode);
	pack.WriteCell(oldDuration);
	pack.WriteCell(newDuration);
	pack.Reset();

	connection.Query(CallbackChangeTime, query, pack);
}

public void CallbackChangeTime(Database db, DBResultSet result, char[] error, any data)
{
	DataPack pack = view_as<DataPack>(data);
	int caller = pack.ReadCell();

	if(result == null) {
		LogError("Error while manipulate VIP time! Error: %s", error);
		ReplyClient(caller, "Can't change time for VIP! %s", error);

		delete pack;
		return;
	}

	char name[MAX_NAME_LENGTH];
	pack.ReadString(name, sizeof(name));

	char steamId[64];
	pack.ReadString(steamId, sizeof(steamId));

	char mode[8];
	pack.ReadString(mode, sizeof(mode));

	int oldDuration = pack.ReadCell();
	int newDuration = pack.ReadCell();

	delete pack;

	Call_StartForward(onDurationChangedForward);
	Call_PushCell(caller);
	Call_PushString(name);
	Call_PushString(steamId);
	Call_PushString(mode);
	Call_PushCell(oldDuration);
	Call_PushCell(newDuration);
	Call_Finish();

	ReplyClient(caller, "Changed time for VIP '%s' from %i to %i minutes!", name, oldDuration, newDuration);
}

public Action Cmd_CheckForExpiredVIPs(int client, int args)
{
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.Reset();

	char query[128];
	if(DriverIsSQLite())
		Format(query, sizeof(query), "SELECT * FROM vips WHERE (strftime('%%s', joindate, duration || ' minutes') - strftime('%%s', 'now')) < 0 AND duration >= 0;");
	else
		Format(query, sizeof(query), "SELECT * FROM vips WHERE TIMEDIFF(DATE_ADD(joindate, INTERVAL duration MINUTE), NOW()) < 0 AND duration >= 0;");

	connection.Query(CallbackCheckForExpiredVIPs, query, pack);
	return Plugin_Handled;
}

public void CallbackCheckForExpiredVIPs(Database db, DBResultSet result, char[] error, any data)
{
	DataPack pack = view_as<DataPack>(data);
	int caller = pack.ReadCell();

	delete pack;

	if(result == null) {
		LogError("Error while checking VIPs! Error: %s", error);
		ReplyClient(caller, "Can't check VIPs! %s", error);
		return;
	}

	if(result.RowCount <= 0) {
		ReplyClient(caller, "No VIP is expired.");
		return;
	}

	while(result.FetchRow()) {
		char name[MAX_NAME_LENGTH];
		result.FetchString(1, name, sizeof(name));

		char steamId[64];
		result.FetchString(0, steamId, sizeof(steamId));

		RemoveVIP(caller, name, steamId, "Time expired!");
	}

	ReplyClient(caller, "Removed all expired VIPs!");
}

void ConnectToDatabase()
{
	if(SQL_CheckConfig("vip-manager"))
		Database.Connect(CallbackConnect, "vip-manager");
	else
		Database.Connect(CallbackConnect, "default");
}

public void CallbackConnect(Database db, char[] error, any data)
{
	if(db == null)
		LogError("Can't connect to server. Error: %s", error);

	connection = db;
	CreateTableIfNotExists();
}

void CreateTableIfNotExists()
{
	connection.Query(CallbackCreateTable, "CREATE TABLE IF NOT EXISTS vips (steamId VARCHAR(64) PRIMARY KEY, name VARCHAR(64) NOT NULL, joindate TIMESTAMP DEFAULT CURRENT_TIMESTAMP, duration INT(11) NOT NULL);");
}

public void CallbackCreateTable(Database db, DBResultSet result, char[] error, any data)
{
	if(result == null)
		LogError("Error while creating table! Error: %s", error);
}

public Action OnClientPreAdminCheck(int client)
{
	if(connection == null)
		return Plugin_Continue;

	CheckVIP(client, VIPCheckedSuccessfully);
	return Plugin_Handled;
}

void CheckVIP(int vipClient, VIPCheckedCallback callback)
{
	if(vipClient < 1 || !IsClientConnected(vipClient))
		return;

	char steamId[64];
	GetClientAuthId(vipClient, authType, steamId, sizeof(steamId));

	int len = strlen(steamId) * 2 + 1;
	char[] escapedSteamId = new char[len];
	connection.Escape(steamId, escapedSteamId, len);

	char query[196];
	if(DriverIsSQLite())
		Format(query, sizeof(query), "SELECT (strftime('%%s', joindate, duration || ' minutes') - strftime('%%s', 'now')) < 0 AS expired FROM vips WHERE steamId = '%s' AND duration >= 0;", escapedSteamId);
	else
		Format(query, sizeof(query), "SELECT TIMEDIFF(DATE_ADD(joindate, INTERVAL duration MINUTE), NOW()) < 0 AS expired FROM vips WHERE steamId = '%s' AND duration >= 0;", escapedSteamId);

	DataPack pack = new DataPack();
	pack.WriteCell(vipClient);
	pack.WriteFunction(callback);
	pack.Reset();

	connection.Query(CallbackCheckVIP, query, pack, DBPrio_High);
}

public void CallbackCheckVIP(Database db, DBResultSet result, char[] error, any data)
{
	if(result == null) {
		LogError("Error while checking VIP! Error: %s", error);
		return;
	}
	else if(result.RowCount <= 0)
		return;

	DataPack pack = view_as<DataPack>(data);
	int vipClient = pack.ReadCell();

	result.FetchRow();
	bool expired = view_as<bool>(result.FetchInt(0));

	Call_StartFunction(null, pack.ReadFunction());
	Call_PushCell(vipClient);
	Call_PushCell(expired);
	Call_Finish();

	delete pack;
}

public void VIPCheckedSuccessfully(int vipClient, bool expired)
{
	if(expired)
		RemoveVIPByExpiration(vipClient);
	else
		FetchVIP(vipClient);
}

void FetchVIP(int vipClient)
{
	if(vipClient < 1 || !IsClientConnected(vipClient) || ClientIsAdmin(vipClient))
		return;

	char steamId[64];
	GetClientAuthId(vipClient, authType, steamId, sizeof(steamId));

	int len = strlen(steamId) * 2 + 1;
	char[] escapedSteamId = new char[len];
	connection.Escape(steamId, escapedSteamId, len);

	char query[128];
	Format(query, sizeof(query), "SELECT duration FROM vips WHERE steamId = '%s';", escapedSteamId);
	connection.Query(CallbackFetchVIP, query, vipClient, DBPrio_High);
}

public void CallbackFetchVIP(Database db, DBResultSet result, char[] error, any data)
{
	int vipClient = data;

	if(result == null) {
		LogError("Error while fetching VIP! Error: %s", error);
		return;
	}

	if(result.RowCount != 1)
		return;

	AddVIPToAdminCache(vipClient);
}

void RemoveVIPByExpiration(int vipClient)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(vipClient, name, sizeof(name));

	char steamId[64];
	GetClientAuthId(vipClient, authType, steamId, sizeof(steamId));

	RemoveVIP(0, name, steamId, "Time expired");
}

public int OnRebuildAdminCache(AdminCachePart part)
{
	if(part == AdminCache_Admins)
		CheckAvailableVIPs();
}

void CheckAvailableVIPs()
{
	for(int i = 1; i < MaxClients; i++)
		CheckVIP(i, VIPCheckedSuccessfully);
}

void ReplyClient(int client, const char[] format, any ...)
{
	int len = strlen(format) + 256;
	char[] message = new char[len];
	VFormat(message, len, format, 3);

	if(client == 0)
		PrintToServer(message);
	else
		PrintToChat(client, message);
}

bool DriverIsSQLite()
{
	DBDriver driver = connection.Driver;
	char identifier[64];
	driver.GetIdentifier(identifier, sizeof(identifier));

	return StrEqual(identifier, "sqlite");
}

bool SearchClient(const char[] search, char[] name, nameLength, char[] steamId, steamIdLength)
{
	int client = FindPlayer(search);
	if(client == -1)
		return false;

	GetClientName(client, name, nameLength);
	GetClientAuthId(client, authType, steamId, steamIdLength);
	return true;
}

int FindPlayer(const char[] searchTerm)
{
	for(int client = 1; client < MaxClients; client++) {
		if(ClientNameContainsString(client, searchTerm))
			return client;
	}

	return -1;
}

bool ClientNameContainsString(int client, const char[] str)
{
	if(client < 1 || !IsClientConnected(client))
		return false;

	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName));

	return StrContains(playerName, str, false) > -1;
}

bool ClientIsAdmin(int client)
{
	return GetUserAdmin(client) != INVALID_ADMIN_ID;
}
