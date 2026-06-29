//Tank Notification for L4D/L4d2
//Prints a message when a tank spawns, music is unreliable.
//2022-2-6 Weld Inclusion

#include <sourcemod>
#include <sdktools>
#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "Tank Notification",
	author = "Weld Inclusion",
	description = "Prints a server chat message when a tank spawns.",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2770712"
}

public void OnPluginStart ()
{
   HookEvent("tank_spawn", TankNotify, EventHookMode_PostNoCopy);
}

public void TankNotify(Event event, const char[] name, bool dontBroadcast)
{
   PrintToChatAll("Tank!");
}