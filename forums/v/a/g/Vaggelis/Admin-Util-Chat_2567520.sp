/* Admin Util - Chat
 *
 * Copyright (C) 2017 Oscar Wos // git.discordlogs.com | theoscar@protonmail.com
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#define PLUGIN_PREFIX "\x01[\x06A. Util.\x01]"
#define PLUGIN_VERSION "1.14"

#include <sourcemod>

ConVar g_cvDeadTalk;

public Plugin myinfo = {
	name = "Admin Util - (Chat)",
	author = "Oscar Wos (OSWO)",
	description = "Admin Util",
	version = PLUGIN_VERSION,
	url = "https://git.discordlogs.com / https://steamcommunity.com/id/OSWO",
}

public void OnPluginStart() {
	AddCommandListener(lSay, "say");
	AddCommandListener(lSayTeam, "say_team");

	g_cvDeadTalk = FindConVar("sv_deadtalk");

	LoadTranslations("admin-util-chat.phrases");
}

Action lSay(int iClient, const char[] cCommand, int iArgc) {
	if (!IsValidClient(iClient)) return;

	ArrayList aAdmins = new ArrayList();
	FindSuitableAdmins(aAdmins, ADMFLAG_GENERIC);

	char cMessage[512];
	int iClientAlive = IsPlayerAlive(iClient);

	GetCmdArgString(cMessage, sizeof(cMessage));
	if (strlen(cMessage) <= 2) return;

	cMessage[strlen(cMessage) - 1] = '\0';

	if (g_cvDeadTalk.BoolValue) return;

	for (int i = 0; i < aAdmins.Length; i++) {
		bool bCheckAlive = !iClientAlive && IsPlayerAlive(aAdmins.Get(i));

		if (bCheckAlive) SendCustomMessage(aAdmins.Get(i), iClient, bCheckAlive, false, cMessage[1]);
	}

	delete aAdmins;
}

Action lSayTeam(int iClient, const char[] cCommand, int iArgc) {
	if (!IsValidClient(iClient)) return;

	ArrayList aAdmins = new ArrayList();
	FindSuitableAdmins(aAdmins, ADMFLAG_GENERIC);

	char cMessage[512];
	int iClientAlive = IsPlayerAlive(iClient);
	int iClientTeam = GetClientTeam(iClient);

	GetCmdArgString(cMessage, sizeof(cMessage));
	if (strlen(cMessage) <= 2) return;

	cMessage[strlen(cMessage) - 1] = '\0';

	for (int i = 0; i < aAdmins.Length; i++) {
		bool bCheckAlive = !iClientAlive && IsPlayerAlive(aAdmins.Get(i));
		bool bCheckTeam = iClientTeam != GetClientTeam(aAdmins.Get(i));

		if (bCheckAlive || bCheckTeam) SendCustomMessage(aAdmins.Get(i), iClient, bCheckAlive, bCheckTeam, cMessage[1]);
	}

	delete aAdmins;
}

void FindSuitableAdmins(ArrayList aAdmins, int iFlag) {
	for (int i = 0; i <= MaxClients; i++) {
		if (IsValidClient(i)) {
			if (CheckCommandAccess(i, "", iFlag, true)) {
				aAdmins.Push(i);
			}
		}
	}
}

void SendCustomMessage(int iClient, int iTarget, bool bDeadChat, bool bDiffChat, char[] cMessage) {
	char cBuffer[512];
	char cTargetName[64];

	GetClientName(iTarget, cTargetName, sizeof(cTargetName));
	Format(cBuffer, sizeof(cBuffer), "%s", PLUGIN_PREFIX);

	if (bDeadChat) { Format(cBuffer, sizeof(cBuffer), "%s (\x0F%T\x01)", cBuffer, "Dead", iClient); }

	if (bDiffChat) {
		switch (GetClientTeam(iTarget)) {
			case 1: {
				Format(cBuffer, sizeof(cBuffer), "%s (\x10%T \x0DS.\x01)", cBuffer, "Team", iClient);
			}
			case 2: {
				Format(cBuffer, sizeof(cBuffer), "%s (\x10%T \x07T\x01)", cBuffer, "Team", iClient);
			}
			case 3: {
				Format(cBuffer, sizeof(cBuffer), "%s (\x10%T \x0BCT\x01)", cBuffer, "Team", iClient);
			}
		}
	}

	Format(cBuffer, sizeof(cBuffer), "%s \x09%s\x01: %s", cBuffer, cTargetName, cMessage);
	PrintToChat(iClient, cBuffer);
}

bool IsValidClient(int iClient) {
	if (iClient > 0 && iClient <= MaxClients && IsValidEntity(iClient) && IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient)) {
		return true;
	}

	return false;
}
