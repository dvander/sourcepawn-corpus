#pragma semicolon 1

#include <sourcemod>
#include <geoip>
#undef REQUIRE_EXTENSIONS
//#include <geoipcity>
#include <SteamWorks>

#define PLUGIN_VERSION		"1.5.3"

enum OS {
	OS_Unknown = -1,
	OS_Windows = 0,
	OS_Mac = 1,
	OS_Linux = 2,
	OS_Total = 3
};

public Plugin myinfo = {
	name		= "Player Analytics",
	author		= "Dr. McKay / Bara / sneaK / llamasking",
	description	= "Logs analytical data about connecting players",
	version		= PLUGIN_VERSION,
	url			= "http://www.doctormckay.com"
};

//#define DEBUG

Handle g_DB;
char g_IP[64];
char g_GameFolder[64];
Handle g_OSGamedata;
char g_OSConVar[OS_Total][64];

int g_ConnectTime[MAXPLAYERS + 1];
int g_NumPlayers[MAXPLAYERS + 1];
int g_RowID[MAXPLAYERS + 1] = {-1, ...};
char g_ConnectMethod[MAXPLAYERS + 1][64];
int g_MOTDDisabled[MAXPLAYERS + 1] = {-1, ...};
Handle g_MOTDTimer[MAXPLAYERS + 1];
new OS:g_OS[MAXPLAYERS + 1];
Handle g_OSTimer[MAXPLAYERS + 1];
int g_OSQueries[MAXPLAYERS + 1];

#define STEAMWORKS_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "SteamWorks_IsLoaded") == FeatureStatus_Available)

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	if(SQL_CheckConfig("player_analytics")) {
		g_DB = SQL_Connect("player_analytics", true, error, err_max);
	} else {
		g_DB = SQL_Connect("default", true, error, err_max);
	}

	if(g_DB == INVALID_HANDLE) {
		return APLRes_Failure;
	}

	SQL_TQuery(g_DB, OnTableCreated, "CREATE TABLE IF NOT EXISTS `player_analytics` (id int(11) NOT NULL AUTO_INCREMENT, server_ip varchar(32) NOT NULL, name varchar(64), auth varchar(32), connect_time int(11) NOT NULL, connect_date date NOT NULL, connect_method varchar(64) DEFAULT NULL, numplayers tinyint(4) NOT NULL, map varchar(64) NOT NULL, duration int(11) DEFAULT NULL, flags varchar(32) NOT NULL, ip varchar(32) NOT NULL, city varchar(45), region varchar(45), country varchar(45), country_code varchar(2), country_code3 varchar(3), premium tinyint(1), html_motd_disabled tinyint(1), os varchar(32), PRIMARY KEY (id))");

	RegPluginLibrary("player_analytics");
	CreateNative("PA_GetConnectionID", Native_GetConnectionID);

	return APLRes_Success;
}

public OnTableCreated(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if(hndl == INVALID_HANDLE) {
		SetFailState("Unable to create table. %s", error);
	}
}

public void OnPluginStart() {
	int ip = GetConVarInt(FindConVar("hostip"));
	Format(g_IP, sizeof(g_IP), "%d.%d.%d.%d:%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF, GetConVarInt(FindConVar("hostport")));

	GetGameFolderName(g_GameFolder, sizeof(g_GameFolder));
	g_OSGamedata = LoadGameConfigFile("detect_os.games");
	if(g_OSGamedata == INVALID_HANDLE) {
		LogError("Failed to load gamedata file detect_os.games.txt: client operating system data will be unavailable.");
	} else {
		GameConfGetKeyValue(g_OSGamedata, "Convar_Windows", g_OSConVar[OS_Windows], sizeof(g_OSConVar[]));
		GameConfGetKeyValue(g_OSGamedata, "Convar_Mac", g_OSConVar[OS_Mac], sizeof(g_OSConVar[]));
		GameConfGetKeyValue(g_OSGamedata, "Convar_Linux", g_OSConVar[OS_Linux], sizeof(g_OSConVar[]));
	}
}

public void OnAllPluginsLoaded() {
	if (!STEAMWORKS_AVAILABLE())
	{
		LogMessage("SteamWorks extension not found, prime status logging will be unavailable");
	}
}

public void OnClientConnected(int client) {
	if(IsFakeClient(client)) {
		return;
	}

	g_MOTDDisabled[client] = -1;
	g_ConnectTime[client] = GetTime();
	g_NumPlayers[client] = GetRealClientCount();
	g_RowID[client] = -1;
	g_OS[client] = OS_Unknown;

	char buffer[30];
	if(GetClientInfo(client, "cl_connectmethod", buffer, sizeof(buffer))) {
		SQL_EscapeString(g_DB, buffer, g_ConnectMethod[client], sizeof(g_ConnectMethod[]));
		Format(g_ConnectMethod[client], sizeof(g_ConnectMethod[]), "'%s'", g_ConnectMethod[client]);
	} else {
		strcopy(g_ConnectMethod[client], sizeof(g_ConnectMethod[]), "NULL");
	}
}

public void OnClientPutInServer(int client) {
	if(IsFakeClient(client)) {
		return;
	}

	QueryClientConVar(client, "cl_disablehtmlmotd", OnMOTDQueried);
	g_MOTDTimer[client] = CreateTimer(30.0, Timer_MOTDTimeout, GetClientUserId(client));

	for(int i = 0; i < _:OS_Total; i++) {
		QueryClientConVar(client, g_OSConVar[i], OnOSQueried);
	}
	g_OSTimer[client] = CreateTimer(30.0, Timer_OSTimeout, GetClientUserId(client));
}

public void OnMOTDQueried(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue) {
	if(g_MOTDTimer[client] == INVALID_HANDLE) {
		return; // Timed out
	}

	if(result == ConVarQuery_Okay) {
		g_MOTDDisabled[client] = (bool:StringToInt(cvarValue)) ? 1 : 0;
	} else {
		g_MOTDDisabled[client] = -1;
	}

	CloseHandle(g_MOTDTimer[client]);
	g_MOTDTimer[client] = INVALID_HANDLE;
}

public Action Timer_MOTDTimeout(Handle timer, any userid) {
	int client = GetClientOfUserId(userid);
	if(client == 0) {
		return;
	}

	g_MOTDDisabled[client] = -1;
	g_MOTDTimer[client] = INVALID_HANDLE;
}

public void OnOSQueried(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue) {
	if(g_OSTimer[client] == INVALID_HANDLE) {
		return; // Timed out
	}

	if(result == ConVarQuery_NotFound) {
		g_OSQueries[client]++;
		if(g_OSQueries[client] >= _:OS_Total) {
			CloseHandle(g_OSTimer[client]);
			g_OSTimer[client] = INVALID_HANDLE;
		}
		return;
	} else {
		for(int i = 0; i < _:OS_Total; i++) {
			if(StrEqual(cvarName, g_OSConVar[i])) {
				g_OS[client] = OS:i;
				break;
			}
		}

		CloseHandle(g_OSTimer[client]);
		g_OSTimer[client] = INVALID_HANDLE;
	}
}

public Action Timer_OSTimeout(Handle timer, any userid) {
	int client = GetClientOfUserId(userid);
	if(client == 0) {
		return;
	}

	g_OSTimer[client] = INVALID_HANDLE;
}

public void OnClientPostAdminCheck(int client) {
	if(IsFakeClient(client)) {
		return;
	}

	CreateTimer(1.0, Timer_HandleConnect, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_HandleConnect(Handle timer, int client) {
	if(client == 0) {
		return Plugin_Stop;
	}

	if(g_MOTDTimer[client] != INVALID_HANDLE || g_OSTimer[client] != INVALID_HANDLE || g_ConnectTime[client] == 0) {
		return Plugin_Continue;
	}

	char date[64];
	char map[64];
	new AdminFlag:flags[32];
	char flagstring[64];
	char ip[64];
	char city[45];
	char region[45];
	char country_name[45];
	char country_code[3];
	char country_code3[4];

	char buffers[10][256];
	FormatTime(date, sizeof(date), "%Y-%m-%d");
	GetCurrentMap(map, sizeof(map));
	GetClientName(client, buffers[0], sizeof(buffers[]));
	GetClientAuthId(client, AuthId_Steam2, buffers[1], sizeof(buffers[]));
	int num = FlagBitsToArray(GetUserFlagBits(client), flags, sizeof(flags));
	for(int i = 0; i < num; i++) {
		int flagchar;
		FindFlagChar(flags[i], flagchar);
		flagstring[i] = flagchar;
	}
	flagstring[num] = '\0';
	GetClientIP(client, ip, sizeof(ip));

	GeoipCode2(ip, country_code);
	GeoipCode3(ip, country_code3);
	GeoipCountry(ip, country_name, sizeof(country_name));

	if(GetFeatureStatus(FeatureType_Native, "GeoipCity") == FeatureStatus_Available)
	{
		GeoipRegion(ip, region, sizeof(region));
		GeoipCity(ip, city, sizeof(city));
	}

	strcopy(buffers[2], sizeof(buffers[]), city);
	strcopy(buffers[3], sizeof(buffers[]), region);
	strcopy(buffers[4], sizeof(buffers[]), country_name);
	strcopy(buffers[5], sizeof(buffers[]), country_code);
	strcopy(buffers[6], sizeof(buffers[]), country_code3);

	if(STEAMWORKS_AVAILABLE() && SteamWorks_IsLoaded()) {
		int premium_appid;
		if (StrEqual(g_GameFolder, "csgo"))
			premium_appid = 624820;
		else if (StrEqual(g_GameFolder, "tf"))
			premium_appid = 459;
		else
			premium_appid = 1; // Nobody has this.

		if(k_EUserHasLicenseResultDoesNotHaveLicense == SteamWorks_HasLicenseForApp(client, premium_appid)) {
			strcopy(buffers[7], sizeof(buffers[]), "0");
		} else {
			strcopy(buffers[7], sizeof(buffers[]), "1");
		}
	}

	if(g_MOTDDisabled[client] != -1) {
		IntToString(g_MOTDDisabled[client], buffers[8], sizeof(buffers[]));
	}

	if(g_OS[client] == OS_Windows) {
		strcopy(buffers[9], sizeof(buffers[]), "Windows");
	} else if(g_OS[client] == OS_Mac) {
		strcopy(buffers[9], sizeof(buffers[]), "MacOS");
	} else if(g_OS[client] == OS_Linux) {
		strcopy(buffers[9], sizeof(buffers[]), "Linux");
	}

	// This replaces empty cells (such as location if it doesn't resolve) with 'NULL'.
	// Then, before sending the query to the SQL server, it replaces that with a true null instead of a string.
	// This prevents errors such as "Data too long for column 'country_code' at row 1."

	char escapedBuffers[10][513];
	for(int i = 0; i < sizeof(buffers); i++) {
		if(strlen(buffers[i]) == 0) {
			strcopy(escapedBuffers[i], sizeof(escapedBuffers[]), "NULL");
		} else {
			SQL_EscapeString(g_DB, buffers[i], escapedBuffers[i], sizeof(escapedBuffers[]));
		}
	}

	char query[512];
	Format(query, sizeof(query), "INSERT INTO `player_analytics` SET server_ip = '%s', name =\"%s\", auth = '%s', connect_time = %d, connect_date = '%s', connect_method = %s, numplayers = %d, map = '%s', flags = '%s', ip = '%s', city = '%s', region = '%s', country = '%s', country_code = '%s', country_code3 = '%s', premium = %s, html_motd_disabled = %s, os = '%s'",
		g_IP, escapedBuffers[0], escapedBuffers[1], g_ConnectTime[client], date, g_ConnectMethod[client], g_NumPlayers[client], map, flagstring, ip, escapedBuffers[2], escapedBuffers[3], escapedBuffers[4], escapedBuffers[5], escapedBuffers[6], escapedBuffers[7], escapedBuffers[8], escapedBuffers[9]);

	ReplaceString(query, sizeof(query), "'NULL'", "NULL", true);

#if !defined DEBUG
	SQL_TQuery(g_DB, OnRowInserted, query, GetClientUserId(client));
#else
	PrintToServer("%s", query);
#endif
	return Plugin_Stop;
}

GetRealClientCount() {
	int total = 0;
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) && !IsFakeClient(i)) {
			total++;
		}
	}
	return total; // Note that this value will include the client who's connecting. If you want to get the number of players in-game when they actually initiated their connection, decrement this by one.
}

public OnRowInserted(Handle:owner, Handle:hndl, const String:error[], any:userid) {
	int client = GetClientOfUserId(userid);
	if(client == 0) {
		return;
	}

	if(hndl == INVALID_HANDLE) {
		LogError("Unable to insert row for client %L. %s", client, error);
		return;
	}

	g_RowID[client] = SQL_GetInsertId(hndl);

	Handle fwd = CreateGlobalForward("PA_OnConnectionLogged", ET_Ignore, Param_Cell, Param_Cell);
	Call_StartForward(fwd);
	Call_PushCell(client);
	Call_PushCell(g_RowID[client]);
	Call_Finish();
	CloseHandle(fwd);
}

public void OnClientDisconnect(int client) {
	if(g_RowID[client] == -1 || g_ConnectTime[client] == 0) {
		g_ConnectTime[client] = 0;
		return;
	}

	char query[256];
	Format(query, sizeof(query), "UPDATE `player_analytics` SET duration = %d WHERE id = %d", GetTime() - g_ConnectTime[client], g_RowID[client]);
#if !defined DEBUG
	SQL_TQuery(g_DB, OnRowUpdated, query, g_RowID[client]);
#else
	PrintToServer("%s", query);
#endif

	g_ConnectTime[client] = 0;
}

public OnRowUpdated(Handle:owner, Handle:hndl, const String:error[], any:id) {
	if(hndl == INVALID_HANDLE) {
		LogError("Unable to update row %d. %s", id, error);
	}
}

public Native_GetConnectionID(Handle:plugin, numParams) {
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client)) {
		ThrowNativeError(SP_ERROR_PARAM, "Client index %d is invalid, not connected, or fake", client);
		return -1;
	}

	return g_RowID[client];
}
