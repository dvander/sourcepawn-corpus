#include <sourcemod>

public Plugin myinfo =
{
	name = "[L4D & L4D2] Survivor Limit - Convar Upper Bounds",
	author = "SilverShot",
	description = "Sets survivor_limit cvar upper bounds.",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=320875"
}

public void OnPluginStart()
{
	// From: https://forums.alliedmods.net/showthread.php?t=109413
	SetConVarBounds(FindConVar("survivor_limit"), ConVarBound_Upper, false);
}