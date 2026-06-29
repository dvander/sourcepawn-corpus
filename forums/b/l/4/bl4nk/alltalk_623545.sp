#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new Handle:AllTalk = INVALID_HANDLE;

// Functions
public Plugin:myinfo =
{
	name = "Round-End Alltalk",
	author = "bl4nk",
	description = "Enables alltalk at round end",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	HookEvent("teamplay_round_start", event_RoundEnd);
	HookEvent("teamplay_round_win", event_RoundEnd);
	HookEvent("teamplay_round_stalemate", event_RoundEnd);
	HookEvent("teamplay_round_active", event_RoundStart);

	AllTalk = FindConVar("sv_alltalk");
	if (AllTalk == INVALID_HANDLE)
		SetFailState("Unable to find convar: sv_alltalk");
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarBool(AllTalk, true);
}

public event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarBool(AllTalk, false);
}