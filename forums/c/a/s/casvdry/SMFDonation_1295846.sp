#pragma semicolon 1
#include <sourcemod>

new Handle:db = INVALID_HANDLE;

public OnPluginStart() {
	decl String:error[256];
	if(SQL_CheckConfig("reg")) {
		db = SQL_Connect("reg", true, error, sizeof(error));
	} else {
		SetFailState("Didn't find database.");
	}
	if(db == INVALID_HANDLE) {
		SetFailState("Could not connect to database: %s", error);
	}
}

public OnClientPostAdminCheck(client) {
	decl String:query[256], String:steamid[32];
	
	GetClientAuthString(client, steamid, sizeof(steamid));
	
	Format(query, sizeof(query), "SELECT id_member FROM smf_themes WHERE variable = 'cust_steami' AND value = '%s'", steamid);
	SQL_TQuery(db, SQLQueryID, query, GetClientUserId(client));
}

public SQLQueryID(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if(!StrEqual("", error)) {
		LogError("Query failed: %s", error);
	}
	
	new client = GetClientOfUserId(data);
	if(client == 0) {
		return;
	}

	if(SQL_FetchRow(hndl)) {
		decl String:query[256];
		Format(query, sizeof(query), "SELECT end_time FROM smf_log_subscribed WHERE id_member = %i AND status = 1", SQL_FetchInt(hndl, 0));
		SQL_TQuery(db, SQLQuerySubscription, query, GetClientUserId(client));
	}
}

public SQLQuerySubscription(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if(!StrEqual("", error)) {
		LogError("Query failed: %s", error);
	}
	
	new client = GetClientOfUserId(data);
	if(client == 0) {
		return;
	}
	
	if(SQL_FetchRow(hndl)) {
		new remain = SQL_FetchInt(hndl, 0) - GetTime();
		if(remain < 0) {
			return;
		}
	
		SetUserFlagBits(client, GetUserFlagBits(client) | ADMFLAG_RESERVATION);
	}
}