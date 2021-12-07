/** 
 * vim: set filetype=c :
 *
 * =============================================================================
 * Anti-Micspam
 *
 * Copyright 2008 Ryan Mannion. All Rights Reserved.
 * Copyright 2009-2010 Bor3d Gaming. All Rights Reserved.
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
#define CVAR_BANMSG	    	6
#define CVAR_BANTIME	    7
#define CVAR_SBINT	    	8
#define CVAR_NUM_CVARS	    9

#define MICSPAMBG_VERSION	    "0.5"

public Plugin:myinfo = {
    name = "Anti-Micspam",
    author = "FLOOR_MASTER and Bor3dGaming.com",
    description = "Automatically mute or punish players who engage in HLSS/HLDJ spamming with SourceBans integration",
    version = MICSPAMBG_VERSION,
    url = "http://www.bor3dgaming.com"
};

new g_times[65];
new Handle:g_cvars[CVAR_NUM_CVARS];
new Handle:BanClientSB = INVALID_HANDLE;

public OnPluginStart() {

    g_cvars[CVAR_VERSION] = CreateConVar(
	"sm_micspambg_version", MICSPAMBG_VERSION, "Anti-Micspam Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvars[CVAR_THRESHOLD] = CreateConVar("sm_micspam_threshold", "3", "How long (in seconds) should I allow transmitting pre-recorded audio before punishment?", FCVAR_PLUGIN);

    g_cvars[CVAR_IMMUNITY] = CreateConVar("sm_micspam_immunity", "0", "What is the minimum immunity level to bypass being punished for micspamming?", FCVAR_PLUGIN);

    g_cvars[CVAR_PUNISHMENT] = CreateConVar("sm_micspam_punishment", "0", "What should I do with micspammers? (0 = Mute, 1 = Kick, 2 = Ban)", FCVAR_PLUGIN);

    g_cvars[CVAR_KICKMSG] = CreateConVar("sm_micspam_kickmsg", "You were kicked due to excessive micspam.", "Kick message to display to a player who was kicked for micspam.", FCVAR_PLUGIN);

    g_cvars[CVAR_MUTEMSG] = CreateConVar("sm_micspam_mutemsg", "was muted due to excessive micspam.", "Message to display to the server when a player is muted for micspam.", FCVAR_PLUGIN);

    g_cvars[CVAR_BANMSG] = CreateConVar("sm_micspam_banmsg", "Excessive Micspam Violation", "Reason displayed when a player is banned for micspam.", FCVAR_PLUGIN);

    g_cvars[CVAR_BANTIME] = CreateConVar("sm_micspam_bantime", "5", "How long should a player be banned for mic spam? (0 = Permanent Ban)", FCVAR_PLUGIN, true, 0.0);
	
    g_cvars[CVAR_SBINT] = CreateConVar("sm_sourceban_integration", "0", "Do you want to use SourceBan integration for banning process? (1 = Yes, 0 = No)", FCVAR_PLUGIN);

    CreateTimer(1.0, Timer_CheckAudio, _, TIMER_REPEAT);

    AutoExecConfig(true, "sm_micspambg");
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
	    new AdminId:admin = GetUserAdmin(client);
	    if (admin != INVALID_ADMIN_ID && GetAdminImmunityLevel(admin) > GetConVarInt(g_cvars[CVAR_IMMUNITY])) {
		return;
	    }

	    decl String:message[256];
	    switch (GetConVarInt(g_cvars[CVAR_PUNISHMENT])) {
		case 0: {
		    if (GetClientListeningFlags(client) != VOICE_MUTED) {
			GetConVarString(g_cvars[CVAR_MUTEMSG], message, sizeof(message));
			LogAction(client, -1, "%L triggered anti-micspam protection, muting", client);
			PrintToChatAll("\x03[Anti-Micspam] %N %s", client, message);
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
		    if (GetConVarInt(g_cvars[CVAR_SBINT]) == 1) {
			BanClientSB = FindConVar("sb_version");
			if ( BanClientSB != INVALID_HANDLE ) {
			ServerCommand("sm_ban #%d %d \"%s\"", GetClientUserId(client), GetConVarInt(g_cvars[CVAR_BANTIME]), message);	
			CloseHandle(BanClientSB);
			return;
			}
			}
			else {
			BanClient(client, GetConVarInt(g_cvars[CVAR_BANTIME]), BANFLAG_AUTHID, message, message, "micspam");
			}
		}
	    }
	}
    }
    else {
	g_times[client] = GetTime();
    }
}