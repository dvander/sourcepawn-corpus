#include <sourcemod>
#include <sdktools>
#include <colors>

#pragma semicolon 1

#define SOUND_LEVELUP "ui/item_acquired.wav"

#define PLUGIN_VERSION "1.0"

new Handle:hDatabase = INVALID_HANDLE;
new Handle:Rankings = INVALID_HANDLE;
new Handle:MinKills = INVALID_HANDLE;
new Handle:MaxKills = INVALID_HANDLE;
new Handle:levelHUD[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:hudLevel;
new Handle:hudTitle;
new Handle:hudEXP;
new String:game[32];

public Plugin:myinfo = {
	name = "[ANY] HLXCE Cosmetic Leveling Mod",
	author = "senseless",
	description = "Importing HLXCE stats in-game",
	version = PLUGIN_VERSION,
	url = "http://www.xjz.me"
}

public OnPluginStart() {
	Rankings = CreateArray(128);  
	MinKills = CreateArray(128);  
	MaxKills = CreateArray(128);  

	GetGameFolderName(game, sizeof(game));
	if((StrEqual(game, "tf"))) {
		TF2DataImport();
	} else {
		SetFailState("This plugin is not for %s", game);
	}

	hudTitle = CreateHudSynchronizer();
	hudLevel = CreateHudSynchronizer();
	hudEXP = CreateHudSynchronizer();
	StartSQL();
}

StartSQL() {
	SQL_TConnect(GotDatabase);
}
 
public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if (hndl == INVALID_HANDLE) {
		LogError("[LMod] Database Connection Error: %s", error);
	} else {
		hDatabase = hndl;
	}
}

public OnClientPostAdminCheck(client) {
	if(IsFakeClient(client)) {
		return;
	}
	
	CreateTimer(2.0, DrawHud, client);
}

public OnClientDisconnect(client)
{
	CloseHandle(Handle:levelHUD[client]);
}

public Action:DrawHud(Handle:timer, any:client) {
	if (!client) {
		return;
	}
	if(IsFakeClient(client)) {
		return;
	}
	
	decl String:steam_id[32];
	decl String:query[255];
	
	GetClientAuthString(client, steam_id, sizeof(steam_id));
	ReplaceString(steam_id, strlen(steam_id), "STEAM_0:", "");
	Format(query, sizeof(query), "select count(*) FROM hlstats_PlayerUniqueIds, hlstats_Events_Frags WHERE (hlstats_PlayerUniqueIds.playerId = hlstats_Events_Frags.killerId) AND hlstats_PlayerUniqueIds.game='%s' AND hlstats_PlayerUniqueIds.uniqueId='%s'", game, steam_id);
	SQL_TQuery(hDatabase, T_RankUpd, query, GetClientUserId(client));
	CreateTimer(2.0, DrawHud, client);
}

public T_RankUpd(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	decl TotalKills;
	decl NextLevel;
	decl T_MinKills;
	decl T_MaxKills;
	decl UserRank;
	decl MaxLevel;
	decl String:steam_id[32];
	decl String:TextRank[32];
	decl String:temp[32];
	
	if ((client = GetClientOfUserId(data)) == 0) {
		return;
	}

	GetClientAuthString(client, steam_id, sizeof(steam_id));
 
	if (hndl == INVALID_HANDLE) {
		LogError("[LMod] Query failed! %s", error);
	}

	if(SQL_FetchRow(hndl)) {
		TotalKills = SQL_FetchInt(hndl,0);
		new i = 0;
		while (i < GetArraySize(MinKills)) {
			GetArrayString(MinKills, i, temp, sizeof(temp));
			T_MinKills = StringToInt(temp);
			GetArrayString(MaxKills, i, temp, sizeof(temp));
			T_MaxKills = StringToInt(temp);
			if (TotalKills >= T_MinKills) {
				if (TotalKills <= T_MaxKills) {
					NextLevel = T_MaxKills;
					UserRank = i+1;
					GetArrayString(Rankings, i, TextRank, sizeof(TextRank));
				}
			} 
			MaxLevel = i+1;
			i++;
		}
	}
	SetHudTextParams(0.04, 0.01, 2.2, 100, 200, 255, 150, 0);
	ShowSyncHudText(client, hudTitle, "Title: %s", TextRank);
	SetHudTextParams(0.04, 0.04, 2.2, 255, 200, 100, 150, 0);
	ShowSyncHudText(client, hudLevel, "Level: %d/%d", UserRank, MaxLevel);
	SetHudTextParams(0.04, 0.07, 2.2, 255, 200, 100, 150, 0);	
	ShowSyncHudText(client, hudEXP, "EXP: %d/%d", TotalKills, NextLevel);
}

bool:TF2DataImport() {
	decl String:query[255];
	decl String:error[255];

	new Handle:db = SQL_Connect("default", true, error, sizeof(error));
	if (db == INVALID_HANDLE) {
		LogError("[LMod] Could Not Connect to Database, error: %s", error);
		return false;
	}

	Format(query,sizeof(query), "SELECT rankName, minKills, maxKills FROM hlstats_Ranks WHERE game='tf' ORDER BY minKills ASC");
	new Handle:data = SQL_Query(db, query);
	if(!data) {
		SQL_GetError(db, error, sizeof(error));
		LogError("[LMod] DB Error:%s", error);
	} else {
		new i = 0;
		decl String:temp[128];
		while (SQL_FetchRow(data)) {
			SQL_FetchString(data, 0, temp, sizeof(temp));
			PushArrayString(Rankings, temp);
			SQL_FetchString(data, 1, temp, sizeof(temp));
			PushArrayString(MinKills, temp);
			SQL_FetchString(data, 2, temp, sizeof(temp));
			PushArrayString(MaxKills, temp);
			i++;
		}
	}
	CloseHandle(db);
	return true;
}





