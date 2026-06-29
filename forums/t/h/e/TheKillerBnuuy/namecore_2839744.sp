#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "NameCore",
	author = "0x5F3759DF",
	description = "Stores names of players who have visited the server, which can be looked up via any AuthIdType.",
	version = "1.0",
	url = "https://steamcommunity.com/id/0x5F3759DF_TF2/"
};


#define SIZEOF_QUERY 1024
#define SIZEOF_NAME 256
#define SIZEOF_AUTHID 48

#define DB_CREATE "CREATE TABLE IF NOT EXISTS NameCoreData(auth_steam64 VARCHAR(%i) PRIMARY KEY, auth_engine VARCHAR(%i) NOT NULL, auth_steam2 VARCHAR(%i) NOT NULL, auth_steam3 VARCHAR(%i) NOT NULL, name VARCHAR(%i) NOT NULL)"
#define DB_CREATE_MYSQL_CAT " ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"
#define DB_INSERT "INSERT INTO NameCoreData (auth_steam64, auth_engine, auth_steam2, auth_steam3, name) VALUES ('%s', '%s', '%s', '%s', '%s') ON DUPLICATE KEY UPDATE name='%s';"
#define DB_INSERT_LITE "INSERT OR REPLACE INTO NameCoreData (auth_steam64, auth_engine, auth_steam2, auth_steam3, name) VALUES ('%s', '%s', '%s', '%s', '%s');"
#define DB_SELECT "SELECT name, auth_engine, auth_steam2, auth_steam3, auth_steam64 FROM NameCoreData WHERE (%s='%s');"


enum CacheType {
	CT_Name,
	CT_Engine,
	CT_Steam2,
	CT_Steam3,
	CT_Steam64,
	CT_Size
}

enum TableKey {
	TK_Engine,
	TK_Steam2,
	TK_Steam3,
	TK_Steam64
}

enum struct LookupJobCallback {
	Handle plugin;
	Function callback;
	any data;
	
	void Set(Handle plugin, Function callback, any data) {
		this.plugin = plugin;
		this.callback = callback;
		this.data = data;
	}
	
	void Execute(const char[] result_name) {
		Call_StartFunction(this.plugin, this.callback);
		Call_PushString(result_name);
		Call_PushCell(strlen(result_name) != 0);
		Call_PushCell(this.data);
		Call_Finish();
	}
}

int __curjobid;
#define NextJobId (__curjobid++)

enum struct LookupJob {
	int jobid;
	char auth[SIZEOF_AUTHID];
	ArrayList callbacks;
	
	int Add(Handle plugin, Function callback, any data) {
		if (!this.callbacks) {
			this.callbacks = new ArrayList(sizeof(LookupJobCallback));
			this.jobid = NextJobId;
		}
		LookupJobCallback job_callback;
		job_callback.Set(plugin, callback, data);
		this.callbacks.PushArray(job_callback);
		return this.jobid;
	}
	
	void Delete() {
		if(this.callbacks) {
			delete this.callbacks;
		}
	}
	
	int Execute(const char[] result_name) {
		int len = this.callbacks.Length;
		LookupJobCallback callback;
		
		for(int i; i < len; i++) {
			this.callbacks.GetArray(i, callback);
			callback.Execute(result_name);
		}
		return len;
	}
}

char gTableKeyStrings[4][] = {
	"auth_engine",
	"auth_steam2",
	"auth_steam3",
	"auth_steam64"
};

ArrayList gLookupJobs;
ArrayList gFetchCache[CT_Size];
ConVar cvCacheSize;
ConVar cvUseNameChanges;
ConVar cvDatabase;
ConVar cvPluginVersion;
Database gDatabase;
bool gIsDBReady;
char gCurDatabaseKey[256];

public void OnPluginStart() {
	cvCacheSize = CreateConVar("namecore_cache_size", "50", "Size of namecore cache. For best results, make this number greater than your player slot count.", FCVAR_PROTECTED, true, 0.0);
	cvUseNameChanges = CreateConVar("namecore_use_name_changes", "0", "If set to 1, namecore will update when a client's name gets changed mid-game.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvDatabase = CreateConVar("namecore_database", "default", "What database namecore will use, check addons/sourcemod/configs/databases.cfg for available values. (Warning: Cancels all callbacks and clears cache on change!)", FCVAR_PROTECTED);
	cvPluginVersion = CreateConVar("namecore_version", "1.0", "Version of namecore");
	AutoExecConfig(true, "namecore");
	for(CacheType index; index < CT_Size; index++) gFetchCache[index] = new ArrayList(index == CT_Name ? SIZEOF_NAME : SIZEOF_AUTHID);
	gLookupJobs = new ArrayList(sizeof(LookupJob));
	HookEvent("player_changename", Event_OnNameChanged);
	if(!TryCreateDBConnection()) {
		char databasekey[256];
		cvDatabase.GetString(databasekey, sizeof(databasekey));
		LogError("[NameCore] Database '%s' was not found in databases.cfg! Try changing the namecore_database cvar!", databasekey);
	}
	HookConVarChange(cvDatabase, OnDatabaseCvarChanged);
}

public void OnDatabaseCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(StrEqual(oldValue, newValue)) {
		return;
	}
	if(!TryCreateDBConnection(newValue)) {
		LogError("[NameCore] Database '%s' was not found in databases.cfg! Database '%s' will continue to be used.", newValue, gCurDatabaseKey);
	}
}

bool TryCreateDBConnection(const char[] force_value = "") {
	char databasekey[256];
	if (strlen(force_value)) {
		strcopy(databasekey, sizeof(databasekey), force_value);
	} else {
		cvDatabase.GetString(databasekey, sizeof(databasekey));
	}
	if(!SQL_CheckConfig(databasekey)) {
		return false;
	}
	strcopy(gCurDatabaseKey, sizeof(gCurDatabaseKey), databasekey);
	Database.Connect(OnDatabaseLoaded, databasekey);
	return true;
}

void OnDatabaseLoaded(Database db, const char[] error, any data) {
	if(gDatabase) {
		delete gDatabase;
	}
	gDatabase = db;
	if(!db) {
		SetFailState("[NameCore] failed to connect: %s", error);
	}
	PrintToServer("[NameCore] connection successful!");
	gDatabase.SetCharset("utf8");
	
	char query[SIZEOF_QUERY];
	BuildQuery_Create(query, SIZEOF_QUERY);
	SQL_TQuery(gDatabase, DBPostTableCreate, query);
}

void DBPostTableCreate(Handle owner, Handle hndl, const char[] error, int junk){
	gIsDBReady = true;
	
	for(CacheType cache_type; cache_type < CT_Size; cache_type++) {
		gFetchCache[cache_type].Clear();
	}
	
	LookupJob job;
	int job_index = gLookupJobs.Length;
	while(job_index--) {
		gLookupJobs.GetArray(job_index, job);
		job.Delete();
	}
	gLookupJobs.Clear();
	
	for(int i = 1; i <= MaxClients; i++) {
		if (!IsClientConnected(i) || !IsClientAuthorized(i))continue;
		OnClientAuthorized(i, "Hello, I see you reading my code :)");
	}
}

void DBDoNothing(Handle owner, Handle hndl, const char[] error, int junk){
	
}

//I am unsure if GetClientName works inside the name change event, so im doing a RequestFrame just in case.
public void Event_OnNameChanged(Event event, const char[] name, bool dontBroadcast) {
	if (!cvUseNameChanges.BoolValue)return;
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (!client)return;
 	RequestFrame(Frame_NameChanged, userid);
}

void Frame_NameChanged(int userid) {
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientAuthorized(client))return;
	OnClientAuthorized(client, "DummyString");
}

//the provided auth can be either steam2 or engine, so it's not useful
public void OnClientAuthorized(int client, const char[] provided_auth) {
	if(!IsAuthIDValid(provided_auth) || !gIsDBReady)return;
	
	char name[SIZEOF_NAME];
	char auth_engine[SIZEOF_AUTHID];
	char auth_steam2[SIZEOF_AUTHID];
	char auth_steam3[SIZEOF_AUTHID];
	char auth_steam64[SIZEOF_AUTHID];
	
	if(!(
		GetClientAuthId(client, AuthId_Engine, auth_engine, SIZEOF_AUTHID) &&
		GetClientAuthId(client, AuthId_Steam2, auth_steam2, SIZEOF_AUTHID) &&
		GetClientAuthId(client, AuthId_Steam3, auth_steam3, SIZEOF_AUTHID) &&
		GetClientAuthId(client, AuthId_SteamID64, auth_steam64, SIZEOF_AUTHID) &&
		IsAuthIDValid(auth_engine) &&
		IsAuthIDValid(auth_steam2) &&
		IsAuthIDValid(auth_steam3) &&
		IsAuthIDValid(auth_steam64)
	))return;
	
	GetClientName(client, name, sizeof(name));
	AddToCache(name, auth_engine, auth_steam2, auth_steam3, auth_steam64);
	
	char query[SIZEOF_QUERY];
	BuildQuery_Insert(query, SIZEOF_QUERY, auth_engine, auth_steam2, auth_steam3, auth_steam64, name);
	SQL_TQuery(gDatabase, DBDoNothing, query);
}

bool IsAuthIDValid(const char[] authid) {
	return !(
		StrEqual(authid, "STEAM_ID_PENDING") ||
		StrEqual(authid, "STEAM_ID_LAN") ||
		StrEqual(authid, "BOT")
	);
}

CacheType AuthTypeToCacheType(AuthIdType auth) {
	switch (auth) {
		case AuthId_Engine:    return CT_Engine;
		case AuthId_Steam2:    return CT_Steam2;
		case AuthId_Steam3:    return CT_Steam3;
		case AuthId_SteamID64: return CT_Steam64;
	}
	ThrowError("[NameCore] Invalid Auth type!");
	return CT_Engine;
}

TableKey AuthTypeToTableKey(AuthIdType auth) {
	switch (auth) {
		case AuthId_Engine:    return TK_Engine;
		case AuthId_Steam2:    return TK_Steam2;
		case AuthId_Steam3:    return TK_Steam3;
		case AuthId_SteamID64: return TK_Steam64;
	}
	ThrowError("[NameCore] Invalid Auth type!");
	return TK_Engine;
}

ArrayList AuthToArray(AuthIdType auth) {
	return gFetchCache[AuthTypeToCacheType(auth)];
}

void EnforceCacheSize() {
	int max_size = cvCacheSize.IntValue;
	while (gFetchCache[CT_Name].Length > max_size) {
		for(CacheType index; index < CT_Size; index++) gFetchCache[index].Erase(0);
	}
}

void AddToCache(const char[] name, const char[] id_engine, const char[] id_steam2, const char[] id_steam3, const char[] id_steam64) {
	int index = gFetchCache[CT_Engine].FindString(id_engine);
	if (index == -1) {
		gFetchCache[CT_Name].PushString(name);
		gFetchCache[CT_Engine].PushString(id_engine);
		gFetchCache[CT_Steam2].PushString(id_steam2);
		gFetchCache[CT_Steam3].PushString(id_steam3);
		gFetchCache[CT_Steam64].PushString(id_steam64);
		EnforceCacheSize();
	} else {
		gFetchCache[CT_Name].SetString(index, name);
	}
}

int GetCacheIndex(AuthIdType auth_type, const char[] auth) {
	return AuthToArray(auth_type).FindString(auth);
}

bool FindLookupJobByAuth(const char[] auth, LookupJob result) {
	LookupJob search;
	int index = gLookupJobs.Length;
	while(index--) {
		gLookupJobs.GetArray(index, search);
		if (!StrEqual(auth, search.auth))continue;
		gLookupJobs.GetArray(index, result);
		return true;
	}
	return false;
}

bool FindLookupJobByJobId(int jobid, LookupJob result) {
	LookupJob search;
	int index = gLookupJobs.Length;
	while(index--) {
		gLookupJobs.GetArray(index, search);
		if (search.jobid != jobid)continue;
		gLookupJobs.GetArray(index, result);
		return true;
	}
	return false;
}

void EraseJobByJobId(int jobid) {
	LookupJob search;
	int index = gLookupJobs.Length;
	while(index--) {
		gLookupJobs.GetArray(index, search);
		if (search.jobid != jobid)continue;
		gLookupJobs.Erase(index);
		search.Delete();
		return;
	}
}

bool AddLookupJob(const char[] auth, Handle plugin, Function callback, any data, int &jobid) {
	LookupJob job;
	if(FindLookupJobByAuth(auth, job)) {
		jobid = job.Add(plugin, callback, data);
		return false;
	}
	strcopy(job.auth, SIZEOF_AUTHID, auth);
	jobid = job.Add(plugin, callback, data);
	gLookupJobs.PushArray(job);
	return true;
}

void MakeStringSqlSafe(char[] str, int len) {
	char newbuffer[SIZEOF_QUERY];
	gDatabase.Escape(str, newbuffer, SIZEOF_QUERY);
	strcopy(str, len, newbuffer);
}

bool IsMySQL() {
	DBDriver driver = gDatabase.Driver;
	char driverName[32];
	driver.GetIdentifier(driverName, sizeof(driverName));
	return StrEqual(driverName, "mysql");
}

void BuildQuery_Create(char[] result, int len) {
	FormatEx(result, len, DB_CREATE, SIZEOF_AUTHID, SIZEOF_AUTHID, SIZEOF_AUTHID, SIZEOF_AUTHID, SIZEOF_NAME);
	if(IsMySQL()) {
		StrCat(result, len, DB_CREATE_MYSQL_CAT);
	}
}

void BuildQuery_Insert(char[] result, int len, const char[] auth_engine, const char[] auth_steam2, const char[] auth_steam3, const char[] auth_steam64, const char[] name) {
	char safename[SIZEOF_NAME * 2 + 1];
	strcopy(safename, SIZEOF_NAME * 2 + 1, name);
	MakeStringSqlSafe(safename, SIZEOF_NAME * 2 + 1);
	if(IsMySQL()) {
		FormatEx(result, len, DB_INSERT, auth_steam64, auth_engine, auth_steam2, auth_steam3, safename, safename);
	} else {
		FormatEx(result, len, DB_INSERT_LITE, auth_steam64, auth_engine, auth_steam2, auth_steam3, safename);
	}
	
}


void BuildQuery_Select(AuthIdType auth_type, const char[] auth_id, char[] result, int len) {
	FormatEx(result, len, DB_SELECT, gTableKeyStrings[AuthTypeToTableKey(auth_type)], auth_id);
}

void NameLookupPost(Handle owner, Handle hndl, const char[] error, int jobid) {
	char name[SIZEOF_NAME];
	char auth_engine[SIZEOF_AUTHID];
	char auth_steam2[SIZEOF_AUTHID];
	char auth_steam3[SIZEOF_AUTHID];
	char auth_steam64[SIZEOF_AUTHID];
	
	LookupJob job;
	if(!FindLookupJobByJobId(jobid, job)) {
		LogError("NameLookup job id: %i was not found!", jobid);
		return;
	}
	
	while (SQL_FetchRow(hndl)) {
		SQL_FetchString(hndl, 0, name, SIZEOF_NAME);
		SQL_FetchString(hndl, 1, auth_engine, SIZEOF_AUTHID);
		SQL_FetchString(hndl, 2, auth_steam2, SIZEOF_AUTHID);
		SQL_FetchString(hndl, 3, auth_steam3, SIZEOF_AUTHID);
		SQL_FetchString(hndl, 4, auth_steam64, SIZEOF_AUTHID);
		AddToCache(name, auth_engine, auth_steam2, auth_steam3, auth_steam64);
		break;
	}
	job.Execute(name);
	EraseJobByJobId(jobid);
	if (!gLookupJobs.Length) {
		__curjobid = 0;
	}
}

int Native_GetNameByAuth(Handle plugin, int args) {
	char auth[SIZEOF_AUTHID];
	AuthIdType auth_type = GetNativeCell(1);
	GetNativeString(2, auth, SIZEOF_AUTHID);
	Function callback = GetNativeFunction(3);
	any data = GetNativeCell(4);
	
	if(StrContains(auth, "'") || StrContains(auth, "\\")) {
		char stinky_plugin_who_is_gross_and_bad[PLATFORM_MAX_PATH];
		GetPluginFilename(plugin, stinky_plugin_who_is_gross_and_bad, sizeof(stinky_plugin_who_is_gross_and_bad));
		PrintToServer("[NameCore] Just a heads up, one of your plugins (%s) just tried to do an SQL-Injection attack. You're welcome :)", stinky_plugin_who_is_gross_and_bad);
		return -1;
	}
	
	if(!gIsDBReady) {
		return 0;
	}
	
	int cache_index = GetCacheIndex(auth_type, auth);
	
	if (cache_index != -1) {
		char name[SIZEOF_NAME];
		gFetchCache[CT_Name].GetString(cache_index, name, SIZEOF_NAME);
		
		Call_StartFunction(plugin, callback);
		Call_PushString(name);
		Call_PushCell(true);
		Call_PushCell(data);
		Call_Finish();
		return 1;
	}
	
	int jobid;
	if(AddLookupJob(auth, plugin, callback, data, jobid)) {
		char query[SIZEOF_QUERY];
		BuildQuery_Select(auth_type, auth, query, SIZEOF_QUERY);
		SQL_TQuery(gDatabase, NameLookupPost, "", jobid);
	}
	
	return 1;
}

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int errlen) {
	CreateNative("NameCore_GetName", Native_GetNameByAuth);
	RegPluginLibrary("NameCore");
	return APLRes_Success;
}