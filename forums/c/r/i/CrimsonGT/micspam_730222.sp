/** 
* vim: set filetype=c :
*
* =============================================================================
* Anti-Micspam
*
* Copyright 2008 Ryan Mannion. All Rights Reserved.
* =============================================================================
* 
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define CVAR_VERSION	    0
#define CVAR_THRESHOLD	    1
#define CVAR_IMMUNITY	    2
#define CVAR_PUNISHMENT	    3
#define CVAR_KICKMSG	    4
#define CVAR_MUTEMSG	    5
#define CVAR_BANMSG	    6
#define CVAR_BANTIME	    7
#define CVAR_NUM_CVARS	    8

#define MICSPAM_VERSION	    "0.3"

public Plugin:myinfo = {
	name = "Anti-Micspam",
	author = "Ryan \"FLOOR_MASTER\" Mannion",
	description = "Automatically mute or punish players who engage in HLSS/HLDJ spamming",
	version = MICSPAM_VERSION,
	url = "http://www.2fort2furious.com"
};

new g_times[65];
new Handle:g_cvars[CVAR_NUM_CVARS];

public OnPluginStart() {
	
	g_cvars[CVAR_VERSION] = CreateConVar(
	"sm_micspam_version",
	MICSPAM_VERSION,
	"Anti-Micspam Version",
	FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cvars[CVAR_THRESHOLD] = CreateConVar(
	"sm_micspam_threshold",
	"3",
	"Time, in seconds, a player can transmit prerecorded audio before being muted",
	FCVAR_PLUGIN);
	
	g_cvars[CVAR_IMMUNITY] = CreateConVar(
	"sm_micspam_immunity",
	"0",
	"Players with an immunity level greater than this value will be immune to the effects of this plugin",
	FCVAR_PLUGIN);
	
	g_cvars[CVAR_PUNISHMENT] = CreateConVar(
	"sm_micspam_punishment",
	"0",
	"0 = mute player, 1 = kick player, 2 = ban player",
	FCVAR_PLUGIN);
	
	g_cvars[CVAR_KICKMSG] = CreateConVar(
	"sm_micspam_kickmsg",
	"You were kicked due to excessive micspam",
	"Kick message to display to a player who was kicked for micspam",
	FCVAR_PLUGIN);
	
	g_cvars[CVAR_MUTEMSG] = CreateConVar(
	"sm_micspam_mutemsg",
	"You were muted due to excessive micspam",
	"Message to display to a player who was muted for micspam",
	FCVAR_PLUGIN);
	
	g_cvars[CVAR_BANMSG] = CreateConVar(
	"sm_micspam_banmsg",
	"You were banned due to excessive micspam",
	"Message to display to a player who was banned for micspam",
	FCVAR_PLUGIN);
	
	g_cvars[CVAR_BANTIME] = CreateConVar(
	"sm_micspam_bantime",
	"5",
	"Duration of ban, in minutes (0 = permanent)",
	FCVAR_PLUGIN,
	true, 0.0);
	
	CreateTimer(1.0, Timer_CheckAudio, _, TIMER_REPEAT);
}

public Action:Timer_CheckAudio(Handle:timer, any:data) {
	new max_clients = GetMaxClients();
	
	for (new client = 1; client <= max_clients; client++) {
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			QueryClientConVar(client, "voice_inputfromfile", CB_CheckAudio);
		}
	}
}

public CB_CheckAudio(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[]) {
	if (result == ConVarQuery_Okay && StringToInt(cvarValue) == 1) {
		if (GetTime() - g_times[client] > GetConVarInt(g_cvars[CVAR_THRESHOLD])) {

			if(IsClientConnected(client))
			{
				new AdminId:admin = GetUserAdmin(client);

				if (admin != INVALID_ADMIN_ID && GetAdminImmunityLevel(admin) > GetConVarInt(g_cvars[CVAR_IMMUNITY])) {
					return;
				}
			}

			decl String:message[256];
			switch (GetConVarInt(g_cvars[CVAR_PUNISHMENT])) {
				case 0: {
					if (GetClientListeningFlags(client) != VOICE_MUTED) {
						GetConVarString(g_cvars[CVAR_MUTEMSG], message, sizeof(message));
						LogAction(client, -1, "%L triggered anti-micspam protection, muting", client);
						PrintToChat(client, "%c%s", 4, message);
						SetClientListeningFlags(client, VOICE_MUTED);
					}
				}
				case 1: {
					GetConVarString(g_cvars[CVAR_KICKMSG], message, sizeof(message));
					LogAction(client, -1, "%L triggered anti-micspam protection, kicking", client);
					KickClient(client, message);
				}
				case 2: {
					GetConVarString(g_cvars[CVAR_BANMSG], message, sizeof(message));
					LogAction(client, -1, "%L triggered anti-micspam protection, banning", client);
					BanClient(client, GetConVarInt(g_cvars[CVAR_BANTIME]), BANFLAG_AUTHID, message, message, "micspam");
				}
			}
		}
	}
	else {
		g_times[client] = GetTime();
	}
}

