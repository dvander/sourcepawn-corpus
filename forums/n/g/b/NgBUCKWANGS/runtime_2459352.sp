//# vim: set filetype=cpp :

/*
Runtime a SourceMod L4D2 Plugin
Copyright (C) 2016  Victor B. Gonzalez

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the

Free Software Foundation, Inc.
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1.0"

char g_pN[512];
char g_sB[512];
char g_Blame[128];
bool g_RoundInProgress = false;
float g_RoundStartTime;
ArrayList g_TimesTracked;
float g_ClientPos[MAXPLAYERS + 1][3];
Handle g_ScanTimer;
int g_ResetType;  // 0: Round 1: ALL

public Plugin:myinfo= {
	name = "Runtime",
	author = "Victor BUCKWANGS Gonzalez",
	description = "Track L4D2 Map Times",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart() {
	HookEvent("map_transition", RecordRoundHook);
	HookEvent("finale_win", RecordRoundHook);

	HookEvent("round_start", RoundStartHook, EventHookMode_Post);
	HookEvent("round_start_post_nav", RoundStartHook, EventHookMode_Post);
	HookEvent("gameinstructor_draw", RoundStartHook, EventHookMode_Post);
	HookEvent("gameinstructor_nodraw", RoundStartHook, EventHookMode_Post);

	RegConsoleCmd("runtime", GetRound);
	g_TimesTracked = new ArrayList(32);
	RoundStart();
}

public Action GetRound(int client, any args) {
	GetCmdArg(1, g_sB, sizeof(g_sB));

	if (strcmp(g_sB, "*") == 0) {
		DisplayTimes();
	}

	else if (strcmp(g_sB, "blame") == 0) {
		PrintHintTextToAll("Blame: %s", g_Blame);
	}

	else if (strcmp(g_sB, "-rnow") == 0) {
		ResetTrackingVote(client, 0);
	}

	else if (strcmp(g_sB, "-rall") == 0) {
		ResetTrackingVote(client, 1);
	}

	else {
		switch (args) {
			case 1: DisplayTimes(StringToInt(g_sB));
			case 0: DisplayTimes(g_TimesTracked.Length + 1);
		}
	}
}

bool IsClientValid(int client) {
	if (client >= 1 && client <= MaxClients) {
		if (IsClientConnected(client)) {
			 if (IsClientInGame(client)) {
				return true;
			 }
		}
	}

	return false;
}

void CleanUp() {
	g_RoundStartTime = 0.0;
	g_RoundInProgress = false;

	if (g_ScanTimer != null) {
		delete g_ScanTimer;
		g_ScanTimer = null;
	}
}

void RecordRound() {
	if (g_RoundInProgress) {
		float timeTracked = GetTimeLive();
		g_TimesTracked.Push(timeTracked);
		DisplayTimes(-1);
	}

	CleanUp();
}

public RecordRoundHook(Handle event, const char[] name, bool dontBroadcast) {
	RecordRound();
}

void RoundStart() {
	CleanUp();

	if (g_ScanTimer == null) {
		g_ScanTimer = CreateTimer(0.1, ScanTimer, _, TIMER_REPEAT);
	}

	static float reset[3];
	for (int i ; i < sizeof(g_ClientPos) ; i++) {
		g_ClientPos[i] = reset;
	}
}

public RoundStartHook(Handle event, const char[] name, bool dontBroadcast) {
	RoundStart();
}

public Action ScanTimer(Handle timer) {

	float pos1[3];
	float pos2[3];
	g_Blame = "Patience...";

	for (int i = 1; i <= MaxClients; i++) {

		if (!IsClientValid(i)) {
			continue;
		}

		if (GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i)) {

			pos1 = g_ClientPos[i];
			GetClientAbsOrigin(i, pos2);

			if ((pos1[0] + pos1[1] + pos1[2]) == 0.0) {
				g_ClientPos[i] = pos2;
				continue;
			}

			else if (pos1[0] != pos2[0]) {
				if (GetClientButtons(i) != 0) {
					GetClientName(i, g_Blame, sizeof(g_Blame));
					PrintHintTextToAll("Blame: %s", g_Blame);

					g_RoundInProgress = true;
					g_RoundStartTime = GetEngineTime();
					g_ScanTimer = null;
					return Plugin_Stop;
				}
			}
		}
	}
	return Plugin_Continue;
}

float GetTimeLive() {
	if (g_RoundStartTime != 0.0) {
		return GetEngineTime() - g_RoundStartTime;
	}

	return 0.0;
}

void DisplayTimes(int round=0) {
	char t1[32];  // time 1
	char t2[32];  // time 2
	float rTime;  // round time
	float stime;  // summed time

	int rounds = g_TimesTracked.Length;
	bool displayAll = true;
	int j;

	if (round != 0) {
		displayAll = false;

		switch (round > 0) {
			case 1: j = round - 1;
			case 0: j = rounds - round * -1;
		}

		if (j < 0) {
			return;
		}
	}

	for (int i ; i <= rounds ; i++) {
		switch (i < rounds) {
			case 1: rTime = g_TimesTracked.Get(i);
			case 0: rTime = GetTimeLive();
		}

		stime += rTime;
		StandardizeTime(rTime, t1);
		StandardizeTime(stime, t2);

		if (displayAll || i >= j) {
			char form[32] = "\x04%02d: %s / %s";
			PrintToChatAll(form, i + 1, t1, t2);

			if (!displayAll) {
				return;
			}
		}
	}
}

void StandardizeTime(float time, char str[32]) {
	float remainder = time;
	int m = RoundToFloor(FloatDiv(time, 60.0));
	remainder = time - float(m * 60);
	int s = RoundToFloor(remainder);
	remainder = remainder - float(s);
	int d = RoundToFloor(remainder * 100.0);

	char form[32] = "\x04%02d:%02d:%03d";
	Format(str, sizeof(str), form, m, s, d);
}

public int ResetTrackingMenu(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_End) {
		delete menu;
	}

	else if (action == MenuAction_VoteEnd) {
		if (param1 == 0) {  // 0=yes, 1=no
			switch (g_ResetType) {
				case 0: RoundStart();
				case 1: {
					delete g_TimesTracked;
					g_TimesTracked = new ArrayList(32);
					RoundStart();
				}
			}

			g_ResetType = -1;
		}
	}
}

void ResetTrackingVote(int client, int resetType) {
	if (IsVoteInProgress() || !IsClientValid(client)) {
		return;
	}

	GetClientName(client, g_pN, sizeof(g_pN));
	g_ResetType = resetType;

	switch (g_ResetType) {
		case 0: g_sB = "Round";
		case 1: g_sB = "ALL";
		default: return;
	}

	Menu menu = new Menu(ResetTrackingMenu);
	menu.SetTitle("Vote called by %s:\nReset \"%s\" Tracking?", g_pN, g_sB);
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
}
