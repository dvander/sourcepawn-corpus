#include <sourcemod>

#pragma semicolon 1

new Handle:sm_adminreloader_roundsetting = INVALID_HANDLE;
new roundCount = 1;

public Plugin:myinfo =
{
	name = "Admin reloader",
	author = "dataviruset",
	description = "Reloads admins every x round",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
	sm_adminreloader_roundsetting = CreateConVar("sm_adminreloader_roundsetting", "4", "The admins will be reloaded every (this cvar value) rounds: x - number of rounds");
}

public OnMapStart()
{
	roundCount = 1;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundCount++;

	if (roundCount >= GetConVarInt(sm_adminreloader_roundsetting))
	{
		ServerCommand("sm_reloadadmins");
		roundCount = 1;
	}
}