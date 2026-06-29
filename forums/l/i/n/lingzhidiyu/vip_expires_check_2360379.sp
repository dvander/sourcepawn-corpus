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
	char ClientSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, ClientSteamID, 32, true);
	RemoveSteam_(ClientSteamID, 32);

	bool bFound = false;
	File f = OpenFile("addons/sourcemod/configs/admins_simple.ini", "a+");
	char szBuffer[256];
	char szExplode[2][256];
	while (!f.EndOfFile()) {
		if (f.ReadLine(szBuffer, 256)) {
			if (StrContains(szBuffer, "//", true) == 0 || szBuffer[0] == '\n') {
				continue;
			}

			Trim(szBuffer);

			char FileSteamID[32];
			GetStringByQuota(0, szBuffer, FileSteamID);
			RemoveSteam_(FileSteamID, 32);

			if (StrEqual(FileSteamID, ClientSteamID, true)) {
				bFound = true;

				ExplodeString(szBuffer, ";", szExplode, 2, 256, false);

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

int RemoveSteam_(char[] SteamID, int size) {
	char newSteamID[32];

	int count;
	int len = strlen(SteamID);
	for (int x = 10; x < len; x++) {
		newSteamID[count++] = SteamID[x];
	}

	strcopy(SteamID, size, newSteamID);
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

					x = j;
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