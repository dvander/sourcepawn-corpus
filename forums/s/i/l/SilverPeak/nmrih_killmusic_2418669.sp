#include <sourcemod>

#define PLUGIN_VERSION "1"

public Plugin:myinfo =
{
    name = "nmrih_killmusic",
    author = "SilverPeak",
    description = "this plugin mutes the nmrih ambiance music on all connected clients",
    version = PLUGIN_VERSION,
    url = "wasted24.com"
};

 
public void OnPluginStart()
{
        CreateTimer(15.0, killmusic, _, TIMER_REPEAT);
}

public Action killmusic(Handle timer)
{
static iClient = -1, iMaxClients = 0;
iMaxClients = GetMaxClients ();
for (iClient = 1; iClient <= iMaxClients; iClient++){
if (IsClientConnected (iClient) && IsClientInGame (iClient)){
ClientCommand(iClient, "snd_musicvolume 0.000000");
}}
return Plugin_Continue;
}