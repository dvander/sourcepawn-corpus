#include sdktools
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "[TF2] Smarter Doors",
	author = "DarthNinja",
	description = "Opens all doors at the end of the round.",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

new bool:g_bIsRoundActive = true;

public OnPluginStart()
{
	CreateConVar("sm_smarterdoors_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
	
	HookEvent("teamplay_round_win", RoundEnded);
	HookEvent("teamplay_round_stalemate", RoundEnded);
	HookEvent("teamplay_round_active", RoundStarted);
	HookEvent("arena_round_start", RoundStarted);
}

public OnMapStart()
{
	HookEntityOutput("func_door", "OnClose", DoorClosing);
}

public DoorClosing(const String:output[], caller, activator, Float:delay)
{
	if (!g_bIsRoundActive)
		AcceptEntityInput(caller, "Open");
}

public Action:RoundEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsRoundActive = false;

	new iDoor = -1;
	while ((iDoor = FindEntityByClassname(iDoor, "func_door")) != -1)
	{
		AcceptEntityInput(iDoor, "Open");
	}
} 

public Action:RoundStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_bIsRoundActive = true;
} 

