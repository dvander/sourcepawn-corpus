/*
-----------------------------------------------------------------------------
-File:

adminsvspubs.sp

-----------------------------------------------------------------------------
-License:

AdminsVsPubs - CS:S/TF2(OB) SourceMod Plugin: a game mode inspired by
www.themadclan.com (The MAD Community)

Copyright (C) 2010 - 2012 B.D.A.K. Koch

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 3.0, as published by the
Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

As a special exception, AlliedModders LLC gives you permission to link the
code of this program (as well as its derivative works) to "Half-Life 2," the
"Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
by the Valve Corporation.  You must obey the GNU General Public License in
all respects for all other code used.  Additionally, AlliedModders LLC grants
this exception to all derivative works.  AlliedModders LLC defines further
exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
or <http://www.sourcemod.net/license.php>.

-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new	Handle:g_hCvAdminTeam = INVALID_HANDLE, g_CvAdminTeam,
	Handle:g_hCvAdminFlags = INVALID_HANDLE, Handle:g_CvAdminFlags = INVALID_HANDLE,
	Handle:g_hCvConfigStart = INVALID_HANDLE,
	Handle:g_hCvConfigEnd = INVALID_HANDLE,
	Handle:g_hCvEnabled = INVALID_HANDLE, g_CvEnabled,
	Handle:g_hCvPubTeam = INVALID_HANDLE, g_CvPubTeam;

#define PLUGIN_NAME "Admins VS Pubs"
#define PLUGIN_AUTHOR "1Swat2KillThemAll"
#define PLUGIN_DESCRIPTION "Pit the admins against the public players!"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "http://www.themadclan.com"
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	InitVersionCvar("avsp", PLUGIN_NAME, PLUGIN_VERSION);

	g_CvEnabled = InitCvar(g_hCvEnabled, OnConVarChanged, "sm_avsp_enabled", "1", "Sets whether Admins Vs Pubs mode should be enabled", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	if (!InitCvar(g_hCvAdminFlags, OnConVarChanged, "sm_avsp_adminflags", "c", "Determines which sets of adminflags (seperated by '|') an admin needs.", FCVAR_DONTRECORD, _, _, _, _, 3)) {
		g_CvAdminFlags = CreateArray();
		PushArrayCell(g_CvAdminFlags, ADMFLAG_BAN);
		PushArrayCell(g_CvAdminFlags, ADMFLAG_ROOT);
	}
	if (!InitCvar(g_hCvAdminTeam, OnConVarChanged, "sm_avsp_adminteam", "Red", "Sets which team should be used for admins.", FCVAR_DONTRECORD, _, _, _, _, 3)) {
		g_CvAdminTeam = FindTeamByName("Red");
		g_CvAdminTeam = g_CvAdminTeam >= 0 ? g_CvAdminTeam : 2;
	}
	if (!InitCvar(g_hCvPubTeam, OnConVarChanged, "sm_avsp_pubteam", "Blu", "Sets which team should be used for public players.", FCVAR_DONTRECORD, _, _, _, _, 3)) {
		g_CvPubTeam = FindTeamByName("Blu");
		g_CvPubTeam = g_CvPubTeam >= 0 ? g_CvPubTeam : 3;
	}

	// Caching cvar values for something that's prolly used once a match is overkill :)
	g_hCvConfigStart = CreateConVar("sm_avsp_config_start", "sourcemod/adminsvspubs/activated.cfg", "Sets which configuration file should be run when the mod's activated.", FCVAR_DONTRECORD);
	if (g_hCvConfigStart == INVALID_HANDLE) {
		LogMessage("Couldn't create console variable \"sm_avsp_config_start\", using default value \"sourcemod/adminsvspubs/activated.cfg\".");
	}

	g_hCvConfigEnd = CreateConVar("sm_avsp_config_end", "sourcemod/adminsvspubs/deactivated.cfg", "Sets which configuration file should be run when the mod's deactivated.", FCVAR_DONTRECORD);
	if (g_hCvConfigEnd == INVALID_HANDLE) {
		LogMessage("Couldn't create console variable \"sm_avsp_config_end\", using default value \"sourcemod/adminsvspubs/deactivated.cfg\".");
	}

	LoadTranslations("adminsvspubs.phrases.txt");

	AddCommandListener(CListener_JoinTeam, "jointeam");
}

public Action:CListener_JoinTeam(client, const String:command[], argc) {
	if (IsFakeClient(client)) {
		return Plugin_Continue;
	}

	decl String:buff[8];

	GetCmdArg(1, buff, sizeof(buff));
	StripQuotes(buff);
	TrimString(buff);

	if (!strlen(buff)) {
		return Plugin_Handled;
	}

	new team = StringToInt(buff),
		wrong_team = IsClientAdmin(client) ? g_CvPubTeam : g_CvAdminTeam;

	if (team == wrong_team || team == 0) {
		new desired_team = wrong_team == g_CvAdminTeam ? g_CvPubTeam : g_CvAdminTeam;
		if (GetClientTeam(client) != desired_team) {
			ChangeClientTeam(client, desired_team);
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_CvEnabled) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (!IsFakeClient(client)) {
			MoveToCorrectTeam(client);
		}
	}
}

MoveToCorrectTeam(client) {
	if (!IsClientValid(client)) {
		return;
	}

	new	team = GetClientTeam(client),
		IsAdmin = IsClientAdmin(client);

	if ((IsAdmin && team == g_CvAdminTeam) || (!IsAdmin && team == g_CvPubTeam)) {
		return;
	}

	team = (IsAdmin ? g_CvAdminTeam : g_CvPubTeam);

	ChangeClientTeam(client, team);

	decl String:team_name[64];
	GetTeamName(team, team_name, sizeof(team_name));

	PrintToChat(client, "%t", "Moved", team_name);
}

HookEvents() {
	HookEvent("player_death", Event_PlayerDeath);
}

UnhookEvents() {
	UnhookEvent("player_death", Event_PlayerDeath);	
}

bool:IsClientAdmin(client) {
	if (g_CvAdminFlags == INVALID_HANDLE) {
		return true;
	}

	new client_flags = GetUserFlagBits(client);

	for (new i = 0; i < GetArraySize(g_CvAdminFlags); i++) {
		new flags = GetArrayCell(g_CvAdminFlags, i);
		if ((client_flags & flags) == flags) {
			return true;
		}
	}

	return false;
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (cvar == g_hCvEnabled) {
		decl String:file_name[256];

		g_CvEnabled = StringToInt(newVal);
		if (g_CvEnabled) {
			HookEvents();

			for (new i = 1; i <= MaxClients; i++) {
				if (IsClientValid(i)) {
					PrintToChat(i, "%t", "Activated");
				}
			}

			if (g_hCvConfigStart != INVALID_HANDLE) {
				GetConVarString(g_hCvConfigStart, file_name, sizeof(file_name));
			}
			else {
				strcopy(file_name, sizeof(file_name), "sourcemod/adminsvspubs/activated.cfg");
			}
		}
		else {
			UnhookEvents();

			for (new i = 1; i <= MaxClients; i++) {
				if (IsClientValid(i)) {
					PrintToChat(i, "%t", "Deactivated");
				}
			}

			if (g_hCvConfigStart != INVALID_HANDLE) {
				GetConVarString(g_hCvConfigEnd, file_name, sizeof(file_name));
			}
			else {
				strcopy(file_name, sizeof(file_name), "sourcemod/adminsvspubs/activated.cfg");
			}
		}

		if (!StrEqual(file_name, "")) {
			ServerCommand("exec %s", file_name);
		}
	}
	else if (cvar == g_hCvAdminFlags) {
		if (g_CvAdminFlags != INVALID_HANDLE) {
			CloseHandle(g_CvAdminFlags);
			g_CvAdminFlags = INVALID_HANDLE;
		}

		if (!StrEqual(newVal, "")) {
			new maxStrings = 1, maxStringLength = 0;
			for (new i = 0, size = strlen(newVal), msl = 0; i < size; i++) {
				if (newVal[i] == '|') {
					maxStrings++;
					msl = 0;
				}
				else {
					msl++;
					if (msl > maxStringLength) {
						maxStringLength = msl;
					}
				}
			}
			maxStringLength++;

			if (maxStringLength > 1) {
				decl String:buffer[maxStrings][maxStringLength];
				ExplodeString(newVal, "|", buffer, maxStrings, maxStringLength);

				g_CvAdminFlags = CreateArray();
				for (new i = 0; i < maxStrings; i++) {
					new bitstring = ReadFlagString(buffer[i]);
					if (bitstring) {
						PushArrayCell(g_CvAdminFlags, bitstring);
					}
				}

				if (!GetArraySize(g_CvAdminFlags)) {
					CloseHandle(g_CvAdminFlags);
				}
			}
		}
	}
	else if (cvar == g_hCvAdminTeam) {
		g_CvAdminTeam = FindTeamByName(newVal);
		g_CvAdminTeam = g_CvAdminTeam >= 0 ? g_CvAdminTeam : 2;
	}
	else if (cvar == g_hCvPubTeam) {
		g_CvPubTeam = FindTeamByName(newVal);
		g_CvPubTeam = g_CvPubTeam >= 0 ? g_CvPubTeam : 3;
	}
}

stock IsClientValid(client) {
	if (client <= 0 || client > MaxClients) {
		client = GetClientFromSerial(client);
	}

	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}

stock InitVersionCvar(const String:cvar_name[], const String:plugin_name[], const String:plugin_version[], additional_flags = 0) {
	new cvar_name_len = strlen(cvar_name) + 12,
		descr_len = strlen(cvar_name) + 20;
	decl String:name[cvar_name_len],
		String:descr[descr_len];

	Format(name, cvar_name_len, "sm_%s_version", cvar_name);
	Format(descr, descr_len, "\"%s\" - version number", descr);
	new Handle:cvar = CreateConVar(name, plugin_version, descr, FCVAR_NOTIFY | FCVAR_DONTRECORD | additional_flags);
	if (cvar != INVALID_HANDLE) {
		SetConVarString(cvar, plugin_version);
	}
	else {
		LogError("Couldn't create version console variable \"%s\".", name);
	}
}

stock any:InitCvar(&Handle:cvar, ConVarChanged:callback, const String:name[], const String:defaultValue[], const String:description[] = "", flags = 0, bool:hasMin = false, Float:min = 0.0, bool:hasMax = false, Float:max = 0.0, type = -1) {
	cvar = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	if (cvar != INVALID_HANDLE) {
		HookConVarChange(cvar, callback);
	}
	else {
		LogMessage("Couldn't create console variable \"%s\", using default value \"%s\".", name, defaultValue);
	}

	if (type < 0 || type > 3) {
		type = 1;
		new len = strlen(defaultValue);
		for (new i = 0; i < len; i++) {
			if (defaultValue[i] == '.') {
				type = 2;
			}
			else if (IsCharNumeric(defaultValue[i])) {
				continue;
			}
			else {
				type = 0;
				break;
			}
		}
	}

	if (type == 1) {
		return cvar != INVALID_HANDLE ? GetConVarInt(cvar) : StringToInt(defaultValue);
	}
	else if (type == 2) {
		return cvar != INVALID_HANDLE ? GetConVarFloat(cvar) : StringToFloat(defaultValue);
	}
	else if (cvar != INVALID_HANDLE && type == 3) {
		Call_StartFunction(INVALID_HANDLE, callback);
		Call_PushCell(cvar);
		Call_PushString("");
		Call_PushString(defaultValue);
		Call_Finish();

		return true;
	}

	return 0;
}
