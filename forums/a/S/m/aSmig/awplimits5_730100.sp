#include <sourcemod>
#include <sdktools>
#include <events>
#pragma semicolon 1

#define TEAM_T 2
#define TEAM_CT 3

new Handle:g_Cvar_MinClients = INVALID_HANDLE;
new Handle:g_Cvar_MinTeamSize = INVALID_HANDLE;
new Handle:g_Cvar_MinAWPs = INVALID_HANDLE;
new Handle:g_Cvar_MaxAWPs = INVALID_HANDLE;
new bool:g_IsLowerLimit = false;
new bool:g_hasmani = false;
new bool:g_haslrestrict = false;

public Plugin:myinfo = {
    name = "AWP After ClientCount/TeamClientCount Limit",
    author = "Shango+Sven",
    description = "This is a Plugin designed to restrict the AWP based on number of players in Game both per team and cumulative",
    version = "1.0.2.0",
    url = "http://www.stompfest.com/"
}

public OnPluginStart() {
    new Handle:hnMani = INVALID_HANDLE;
    if ((hnMani = FindConVar("mani_admin_plugin_version")) != INVALID_HANDLE) {
	CloseHandle(hnMani);
	g_hasmani = true;
    }

    if (FindPluginByFile("restrict.smx") != INVALID_HANDLE) {
	g_haslrestrict = true;
    }

    g_Cvar_MinClients = CreateConVar("sm_awplimit_minclients", "10", "Min players required to unrestrict the AWP.");
    g_Cvar_MinTeamSize = CreateConVar("sm_awplimit_minteamsize", "5", "Min players per team required to unrestrict the AWP.");
    g_Cvar_MinAWPs = CreateConVar("sm_awplimit_minawps", "0", "Number of AWPs allowed per team before threshold is reached.");
    g_Cvar_MaxAWPs = CreateConVar("sm_awplimit_maxawps", "1", "Number of AWPs allowed per team after threshold is reached.");

    if (!HookEvent("player_team", Event_LimitAWPCheck, EventHookMode_PostNoCopy)) {
	SetFailState("Could not hook the player_team event.");
    }
    if (!HookEvent("round_start", Event_LimitAWPCheck, EventHookMode_PostNoCopy)) {
	SetFailState("Could not hook the round_start event.");
    }
}

public OnClientDisconnect_Post(client) {
    LimitAWPCheck();
}

public Action:Event_LimitAWPCheck(Handle:event, const String:name[], bool:dontBroadcast) {
    LimitAWPCheck();
}

LimitAWPCheck() {
    if (
	(
	    (GetConVarInt(g_Cvar_MinClients) > 0) &&
	    ((GetTeamClientCount(TEAM_T) + GetTeamClientCount(TEAM_CT)) < GetConVarInt(g_Cvar_MinClients))
	) || (
	    (GetConVarInt(g_Cvar_MinTeamSize) > 0) && (
		(GetTeamClientCount(TEAM_T) < GetConVarInt(g_Cvar_MinTeamSize)) ||
		(GetTeamClientCount(TEAM_CT) < GetConVarInt(g_Cvar_MinTeamSize))
	    )
	)
    ) {
	LimitAWPLower();
    } else {
	LimitAWPUpper();
    }
}

LimitAWPLower() {
    if (!g_IsLowerLimit) {
	g_IsLowerLimit = true;
	
	if(g_hasmani) {
	    ServerCommand("ma_restrict awp %i", GetConVarInt(g_Cvar_MinAWPs));
	} else {
	    if (g_haslrestrict) ServerCommand("sm_restrict awp %i", GetConVarInt(g_Cvar_MinAWPs));
	}
    }
}

LimitAWPUpper() {
    if (g_IsLowerLimit) {
	g_IsLowerLimit = false;
	
	if(g_hasmani) {
	    ServerCommand("ma_restrict awp %i", GetConVarInt(g_Cvar_MaxAWPs));
	} else {
	    if (g_haslrestrict) ServerCommand("sm_restrict awp %i", GetConVarInt(g_Cvar_MaxAWPs));
	}
    }
}
