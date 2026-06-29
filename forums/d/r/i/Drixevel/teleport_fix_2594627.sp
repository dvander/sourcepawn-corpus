#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Teleport Fix",
	author = "Keith Warren (Shaders Allen)",
	description = "Pushes players up 2 units on teleport.",
	version = "1.0.0",
	url = "https://github.com/ShadersAllen"
};

public void OnPluginStart()
{
	HookEntityOutput("trigger_teleport", "OnEndTouch", OnTeleport);
}

public void OnTeleport(const char[] output, int caller, int activator, float delay)
{
	if (activator > 0 && activator <= MaxClients)
	{
		float vecOrigin[3];
		GetClientAbsOrigin(activator, vecOrigin);

		vecOrigin[2] += 2.0;

		TeleportEntity(activator, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	}
}
