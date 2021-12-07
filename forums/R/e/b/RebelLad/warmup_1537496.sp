#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Tf2 Warm Up Round",
	author = "RebelLad",
	description = "Creates a warm up round at the start of each map",
	version = PLUGIN_VERSION,
	url = "http://"
};
new Handle:g_warmuptime;

public OnPluginStart() {
g_warmuptime = CreateConVar("warmuproundtime", "15", "Time (in minutes) the warm up round lasts")

}

public OnMapStart() {
new g_roundtime = GetConVarInt(g_warmuptime);
new Float:roundtimer = Float:g_roundtime * 60; 
PrintToChatAll("Warm up round starting, ending in %d minutes", g_roundtime);
ServerCommand("mp_restartround %d", roundtimer);

}
