#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
    name = "EndBlock",
    author = "-SNiGS- Fire",
    description = "Blocks Round-End Exploit",
    version = PLUGIN_VERSION,
    url = "www.snigsclan.com"
};

public OnPluginStart()
{
    CreateConVar("l4d_endblock", PLUGIN_VERSION, "Blocks Round-End Exploit", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    Block();
}

public Action:Block()
{	
    new flags1 = GetCommandFlags("overview_names");
    new flags2 = GetCommandFlags("outtro_stats_done");
    SetCommandFlags("overview_names", flags1|FCVAR_CHEAT);
    SetCommandFlags("outtro_stats_done", flags2|FCVAR_CHEAT);
    
    return Plugin_Handled;
}