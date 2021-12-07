#include <sourcemod>
 
public Plugin:myinfo =
{
	name = "Terrorist Infect",
	author = "enviolinador",
	description = "Infects terrorists (via ZombieReloaded) on round start.",
	version = "0.0.1",
	url = "http://www.google.com/"
};
 
public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}
 
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Infect Ts
	ServerCommand("zr_infect @t");
}