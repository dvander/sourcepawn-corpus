#include <sourcemod>
#include <sdktools>
#include <tf2>

#define PLUGIN_VERSION "1.0"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Tf2 Warm Up Round",
	author = "RebelLad",
	description = "Creates a warm up round at the start of each map",
	version = PLUGIN_VERSION,
	url = "http://"
};
new Handle:g_warmuptime;
new g_roundtime; 

public OnPluginStart() {
//mp_restartgame 1
g_warmuptime = CreateConVar("warmuproundtime", "15", "Time (in minutes) the warm up round lasts")

}

public OnMapStart() {
ServerCommand("hale_enabled 0");
g_roundtime = GetConVarInt(g_warmuptime);
new Float:roundtimer = Float:g_roundtime; 
PrintToChatAll("Warm up round starting, ending in %d minutes", g_roundtime);
CreateTimer(roundtimer, End_warmup);
}
public Action:End_warmup(Handle:timer){
ServerCommand("hale_enabled 1");
PrintToChatAll("Warm up round over, restarting");
ServerCommand("mp_restartround 3");
}







