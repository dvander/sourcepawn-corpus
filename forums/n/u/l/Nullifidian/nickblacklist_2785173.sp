#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

bool	g_bLateLoad,
		ga_bRenamed[MAXPLAYERS + 1] = {false, ...};

char	g_sLogFilePath[PLATFORM_MAX_PATH],
		ga_sBlackList[][] = {
		"keydrop",
		"csgorun",
		"TradeSkinsFast",
		"Farmskins",
		"csgocases",
		"Chefcases",
		"hellcase",
		"csgoempire",
		"Key-Drop",
		"g4skins",
		"banditcamp",
		"TF2EASY",
		"TRADEIT",
		"Society.gg",
		"CASEDROP",
		"csgolive",
		"BUYSKINS",
		"gmod-best",
		"tasty-drop",
		"CSidling",
		"PTRunners",
		"gocase",
		"CSGOFAST",
		".com"
};

public Plugin myinfo = {
	name		= "nickblacklist",
	author		= "Nullifidian",
	description	= "Removes blacklisted words from player's nick & logs it",
	version		= "1.4",
	url			= ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() {
	HookEvent("player_changename", Event_ChangeName, EventHookMode_Pre);

	char sBuffer[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE, sBuffer, sizeof(sBuffer));
	ReplaceString(sBuffer, sizeof(sBuffer), ".smx", ".log", false);
	BuildPath(Path_SM, g_sLogFilePath, sizeof(g_sLogFilePath), "logs/%s", sBuffer);

	if (g_bLateLoad) {
		char sName[32];
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i)) {
				continue;
			}
			if (GetClientName(i, sName, sizeof(sName))) {
				FindAndRemove(i, sName);
			}
		}
	}
}

public void OnClientPutInServer(int client) {
	if (!IsFakeClient(client)) {
		ga_bRenamed[client] = false;
		char sName[32];
		if (GetClientName(client, sName, sizeof(sName))) {
			FindAndRemove(client, sName);
		}
	}
}

public Action Event_ChangeName(Event event, char[] name, bool dontBroadcast) {
	int	client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsClientInGame(client) || IsFakeClient(client)) {
		return Plugin_Continue;
	}

	if (ga_bRenamed[client]) {
		dontBroadcast = true;
		ga_bRenamed[client] = false;
		return Plugin_Continue;
	}

	char sNew[32];
	event.GetString("newname", sNew, sizeof(sNew));

	if (FindAndRemove(client, sNew)) {
		//event.SetString("newname", sNew);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool FindAndRemove(int client, char sName[32]) {
	bool bRemoved = false;
	char sNewName[32];

	sNewName = sName;
	
	for (int i=0; i<sizeof(ga_sBlackList); i++) {
		if (ReplaceString(sNewName, sizeof(sNewName), ga_sBlackList[i], "", false)) {
			bRemoved = true;
		}
	}

	if (bRemoved) {
		char sBuffer[32];
		TrimString(sNewName);

		if (strlen(sNewName) < 1) {
			FormatEx(sNewName, sizeof(sNewName), "Player #%d", client);
		}

		ga_bRenamed[client] = true;
		SetClientName(client, sNewName);

		GetClientAuthId(client, AuthId_Steam2, sBuffer, sizeof(sBuffer));
		LogToFile(g_sLogFilePath, "changed [%s] %s's nick to %s", sBuffer, sName, sNewName);

		return true;
	}
	return false;
}