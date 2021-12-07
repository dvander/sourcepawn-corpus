/*  [CS:GO] Mute on Votes
 *
 *  Copyright (C) 2018 Daniel Sartor // kniv.com.br // plock@kniv.com.br
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

#include <sourcemod>
#include <sdktools>
#include <basecomm>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#tryinclude <warden>

#pragma newdecls required

#define PLUGIN_AUTHOR "ReFlexPoison, Plock"
#define PLUGIN_VERSION "1.4"

bool g_bVoteInProgress = false;
bool g_bVoteGagged[MAXPLAYERS + 1];
bool g_bMuted[MAXPLAYERS + 1];
bool g_bGagged[MAXPLAYERS + 1];

bool g_bWarden = false;

Handle MuteTimer = null;

ConVar g_ConVar_Enabled;
ConVar g_ConVar_Immunity;
ConVar g_ConVar_Method;
ConVar g_ConVar_WardenImmunity;

public Plugin myinfo = {
    name = "Mute on Votes",
    author = PLUGIN_AUTHOR,
    version = PLUGIN_VERSION,
    url = "www.kniv.com.br"
};

public void OnPluginStart() {
	
	AutoExecConfig_SetFile("muteonvotes");
	AutoExecConfig_SetCreateFile(true);
	
	g_ConVar_Enabled = AutoExecConfig_CreateConVar("mov_enabled", "1", "Enable/Disable plugin", FCVAR_NONE);
	g_ConVar_Immunity = AutoExecConfig_CreateConVar("mov_immunity", "1", "Admins with B flag will be immune.", FCVAR_NONE);
	g_ConVar_Method = AutoExecConfig_CreateConVar("mov_method", "0", "0 = Mute. 1 = Gag. 2 = Both", FCVAR_NONE);
	g_ConVar_WardenImmunity = AutoExecConfig_CreateConVar("mov_wardenimmunity", "0", "Warden immune to mute/gags. Used on Jailbreak servers.", FCVAR_NONE);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	LoadTranslations("muteonvotes.phrases");
}

public void OnAllPluginsLoaded()
{
	if(LibraryExists("warden")) {
		g_bWarden = true;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("warden_exist");
	MarkNativeAsOptional("warden_iswarden");
	MarkNativeAsOptional("warden_set");
	MarkNativeAsOptional("warden_remove");
	return APLRes_Success;
}

public void OnMapStart()
{
	if (MuteTimer == null) {
		MuteTimer = CreateTimer(0.1, Timer_CheckVote, _, TIMER_REPEAT);
	} else {
		ClearTimer(MuteTimer);
		MuteTimer = CreateTimer(0.1, Timer_CheckVote, _, TIMER_REPEAT);
	}
}

public void OnClientPostAdminCheck(int client) {
	g_bVoteGagged[client] = false;
	g_bMuted[client] = false;
	g_bGagged[client] = false;
	if (IsValidClient(client)) {
		if (g_ConVar_Enabled.IntValue == 1) {
			if (g_bVoteInProgress) {
				if (g_ConVar_Method.IntValue == 0) {
					MutePlayer(client);
				} else if (g_ConVar_Method.IntValue == 1) {
					GagPlayer(client);
				} else if (g_ConVar_Method.IntValue == 2) {
					MutePlayer(client);
					GagPlayer(client);
				}
			}
		}
	}
}

public Action Timer_CheckVote(Handle timer, int client) {
	if (g_ConVar_Enabled.IntValue != 1) {
		return Plugin_Continue;
	}
	
	if(IsVoteInProgress() && !g_bVoteInProgress) {
		g_bVoteInProgress = true;
		if (g_ConVar_Method.IntValue == 0) {
			PrintToChatAll("%t", "Mute All");
			MuteAllPlayers();
		} else if (g_ConVar_Method.IntValue == 1) {
			PrintToChatAll("%t", "Gag All");
			GagAllPlayers();
		} else if (g_ConVar_Method.IntValue == 2) {
			PrintToChatAll("%t", "Silence All");
			SilenceAllPlayers();
		}
	} else if (!IsVoteInProgress() && g_bVoteInProgress) {
		g_bVoteInProgress = false;
		PrintToChatAll("%t", "UnSilence All");
		UnSilenceAll();
	}
	
	return Plugin_Continue;
}

public void MuteAllPlayers() {
	for (int i = 1;i<=MaxClients;i++) {
		if (IsValidClient(i)) {
			if (g_ConVar_Immunity.IntValue == 1 && (GetUserFlagBits(i) & ADMFLAG_GENERIC)) {
				PrintToChat(i, "%t", "Immune Mute");
				continue;
			}
			if (g_bWarden && g_ConVar_WardenImmunity.IntValue == 1 && warden_iswarden(i)) {
				PrintToChat(i, "%t", "Immune Mute Warden");
				continue;
			}
			MutePlayer(i);
		}
	}
}

public void GagAllPlayers() {
	for (int i = 1;i<=MaxClients;i++) {
		if (IsValidClient(i)) {
			if (g_ConVar_Immunity.IntValue == 1 && (GetUserFlagBits(i) & ADMFLAG_GENERIC)) {
				PrintToChat(i, "%t", "Immune Gag");
				continue;
			}
			if (g_bWarden && g_ConVar_WardenImmunity.IntValue == 1 && warden_iswarden(i)) {
				PrintToChat(i, "%t", "Immune Gag Warden");
				continue;
			}
			GagPlayer(i);
		}
	}
}

public void SilenceAllPlayers() {
	for (int i = 1;i<=MaxClients;i++) {
		if (IsValidClient(i)) {
			if (g_ConVar_Immunity.IntValue == 1 && (GetUserFlagBits(i) & ADMFLAG_GENERIC)) {
				PrintToChat(i, "%t", "Immune Silence");
				continue;
			}
			if (g_bWarden && g_ConVar_WardenImmunity.IntValue == 1 && warden_iswarden(i)) {
				PrintToChat(i, "%t", "Immune Silence Warden");
				continue;
			}
			MutePlayer(i);
			GagPlayer(i);
		}
	}
}

public void UnSilenceAll() {
	for (int i = 1;i<=MaxClients;i++) {
		if (IsValidClient(i)) {
			UnmutePlayer(i);
			UngagPlayer(i);
		}
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (StrEqual(command, "say") || StrEqual(command, "say_team")) {
	    if (g_bVoteGagged[client]) {
	    	return Plugin_Handled;
	    }
	}
	return Plugin_Continue;
}

public void warden_OnWardenCreated (int client) {
	if (IsValidClient(client)) {
		if (g_bWarden && g_ConVar_Enabled.IntValue == 1 && g_ConVar_WardenImmunity.IntValue == 1) {
			if (g_bVoteInProgress) {
				UnmutePlayer(client);
				UngagPlayer(client);
			}
		}
	}
}

stock bool IsValidClient(int client) {
	if (!( 1 <= client <= MaxClients ) || !IsClientInGame(client))
		return false; 
	if (IsFakeClient(client))
		return false;
	return true; 
}

stock void ClearTimer(Handle &timer) {
    if (timer != null) {
        KillTimer(timer);
        timer = null;
    }
}

stock void MutePlayer(int client)
{
	g_bMuted[client] = BaseComm_IsClientMuted(client);
	if(!g_bMuted[client]) {
		SetClientListeningFlags(client, VOICE_MUTED);
	}
}

stock void UnmutePlayer(int client)
{
	if(!g_bMuted[client]) {
		SetClientListeningFlags(client, VOICE_NORMAL);
	}
}

stock void GagPlayer(int client)
{
	g_bGagged[client] = BaseComm_IsClientGagged(client);
	if(!g_bGagged[client]) {
		g_bVoteGagged[client] = true;
	}
}

stock void UngagPlayer(int client)
{
	if(!g_bGagged[client]) {
		g_bVoteGagged[client] = false;
	}
}