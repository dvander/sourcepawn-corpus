#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:g_CVarEnabled;

public Plugin myinfo =
{
	name = "Round Exec by Mado",
	author = "Mado",
	description = "none",
	version = PLUGIN_VERSION,
	url = "http://www.bluegames.ro/forum/"
}

public OnPluginStart()
{
	g_CVarEnabled = CreateConVar("sm_roundexec_enable", "1", "<1/0> Set to 1 to enable plugin.");
    HookEvent("round_start", RoundStart, EventHookMode_Post);
    HookEvent("round_end", RoundEnd, EventHookMode_Post);
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
if (GetConVarInt(g_CVarEnabled)){
	ServerCommand("exec round_start.cfg");
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
if (GetConVarInt(g_CVarEnabled)) {
	ServerCommand("exec round_end.cfg");
}