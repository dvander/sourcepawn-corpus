#pragma semicolon 1
//#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_NAME        "Simple vip expires"
#define PLUGIN_AUTHOR      "lingzhidiyu"
#define PLUGIN_DESCRIPTION "description"
#define PLUGIN_VERSION     "1.0"
#define PLUGIN_URL         "url"

public Plugin myinfo = {
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version     = PLUGIN_VERSION,
	url         = PLUGIN_URL
}

public void OnPluginStart() {
	RegConsoleCmd("sm_vipduration", Command);
}

public Action Command(client, args) {
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, 32, true);

	bool bFound = false;
	File f = OpenFile("addons/sourcemod/configs/admins_simple.ini", "a+");
	char szBuffer[256];
	char szExplode[2][256];
	while (!f.EndOfFile()) {
		if (f.ReadLine(szBuffer, 256)) {
			if (StrContains(szBuffer, "//", true) == 0) {
				continue;
			}

			Trim(szBuffer);

			char steamID[32];
			GetStringByQuota(0, szBuffer, steamID);

			ExplodeString(szBuffer, ";", szExplode, 2, 256, false);

			if (StrEqual(steamID, SteamID, true)) {
				bFound = true;

				PrintToChat(client, " \x04Your vip expires \x02%s", szExplode[1]);
				break;
			}
		}
	}

	if (!bFound) {
		PrintToChat(client, " \x04You don't have vip");
	}

	delete f;
}

GetStringByQuota(int num, char[] str, char[] newStr) {
	int start = -1;
	int end = -1;
	int count = -1;

	int len = strlen(str);
	for (int x = 0; x < len; x++) {
		if (str[x] == '\"') {
			for (int j = x + 1; j < len; j++) {
				if (str[j] == '\"') {
					count++;
					if (count == num) {
						start = x + 1;
						end = j - 1;
					}
				}
			}
		}
	}

	int newLen;
	for (int x = start; x <= end; x++) {
		newStr[newLen++] = str[x];
	}
}

Trim(char[] str) {
	int len = strlen(str);

	if (str[len-1] == '\n') {
		str[--len] = '\0';
	}

	TrimString(str);
}