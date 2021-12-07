#pragma semicolon 1 // Force all lines to require a semi-colon to signify the end of the line
//#pragma dynamic 65536 // allows the use of more memory

#define REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN

//#define DEBUG 1

#define PLUGIN_VERSION "1.1"
#define PLUGIN_MSG_PREFIX "[oc_harvest_clock] "

#define MAX_PRINTTOPLAYER_MSG_LEN 254
#define MAX_WEAPONNAME_LENGTH 65
#define MAX_MAPNAME_LENGTH 65

new Handle:g_hDefaultClockState = INVALID_HANDLE;
new bool:g_playerClockShow[MAXPLAYERS+1];
new Float:g_fseconds_dayLength;

public Plugin:myinfo = 
{
    name = "oc_harvest clock",
    author = "Reef",
    description = "Shows the time on the oc_harvest",
    version = PLUGIN_VERSION,
    url = "http://reef.pl/oc_harvest_clock/"
};

public OnPluginStart()
{
    CreateConVar("oc_harvest_clock_ver", PLUGIN_VERSION, "oc_harvest clock version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); // TODO: register
    g_hDefaultClockState = CreateConVar("oc_harvest_clock_default_state", "1", "1 = on, 0 = Off", FCVAR_PLUGIN);
    RegConsoleCmd("sm_clock", cmd_toggleTime);
}

public OnMapStart() {
    decl String:mapname_current[MAX_MAPNAME_LENGTH];
    GetCurrentMap(mapname_current, MAX_MAPNAME_LENGTH);
    if (strcmp(mapname_current, "oc_harvest", false) == 0)
    {
        g_fseconds_dayLength = 153.0;
        CreateTimer(1.0, render_clock, _,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

public OnClientPutInServer(client) {
    // NOTE: client finished loading stuff and is now IN GAME
    if (IsFakeClient(client) || (client == 0)) // bots, the server
    {
        return; // forget it
    }
    g_playerClockShow[client] = GetConVarInt(g_hDefaultClockState)==1;
    PrintToPlayer(client, "Type \"!clock\" to turn clock ON/OFF");
}

public OnClientDisconnect(client) {
    if (IsFakeClient(client) || (client == 0)) // bots, the server
    {
        return; // forget it
    }
    g_playerClockShow[client] = false;
}

public Action:cmd_toggleTime(const client, const args)
{
    g_playerClockShow[client] = !g_playerClockShow[client];
    PrintToPlayer(client, "Type \"!clock\" to turn clock ON/OFF");
    return Plugin_Handled;
}

public Action:render_clock(const Handle:timer)
{
    decl Float:fts_current;
    fts_current = GetGameTime();
    
    decl Float:day_number;
    day_number = fts_current/g_fseconds_dayLength;
    decl Float:fseconds_leftUntilMidnight;
    fseconds_leftUntilMidnight = g_fseconds_dayLength - (fts_current - (RoundToFloor(day_number)*g_fseconds_dayLength));
    decl String:str_currentTime[6];
    FormatTime(str_currentTime, sizeof(str_currentTime), "%M:%S", RoundFloat(fseconds_leftUntilMidnight));
    for (new i = 1; i <= MaxClients; i++)
    {
        if (g_playerClockShow[i] && isClientReal(i))
        {
            PrintHintText(i, "Day %i, time: %s", RoundToFloor(day_number), str_currentTime);
        }
    }
#if defined DEBUG
    PrintToServer("Day %f, time: %s (%f)", day_number, str_currentTime, fseconds_leftUntilMidnight); // DEBUG
#endif
    return Plugin_Continue;
}

stock bool:isClientReal(const client, bool:ignoreNotIngameness=false) {
    if (client == 0) {
        return false; // the server, called "WORLD" 
    } else if (!IsClientConnected(client)) {
        return false; // Client is not connected yet or he disconnected already
    } else if (IsFakeClient(client)) {
        return false; // bots
    } else if (ignoreNotIngameness==false && !IsClientInGame(client)) { 
        return false; // Client is connected, but we think he is still loading his map or something
    }
    return true;
}

stock PrintToPlayer(const client, const String:input[])
{
    PrintToPlayerEx(client, "%s", input);
}

stock PrintToPlayerEx(const client, const String:format[], any:...)
{
    decl String:output[MAX_PRINTTOPLAYER_MSG_LEN+1];
    decl String:input[MAX_PRINTTOPLAYER_MSG_LEN+1];
    output = PLUGIN_MSG_PREFIX;
    VFormat(input, MAX_PRINTTOPLAYER_MSG_LEN, format, 3);
    StrCat(output, MAX_PRINTTOPLAYER_MSG_LEN, input);
    PrintToConsole(client, output);
    PrintToChat(client, output);
}
