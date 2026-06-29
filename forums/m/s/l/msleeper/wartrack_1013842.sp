/*
-----------------------------------------------------------------------------
WAR TRACKER + CLASS ENFORCER - SOURCEMOD PLUGIN
-----------------------------------------------------------------------------
Code Written By msleeper (c) 2009
Visit http://www.msleeper.com/ for more info!
-----------------------------------------------------------------------------
This plugin tracks Soldier vs. Demoman deaths for the War. This information
is tracked very basically into the "default" MySQL database. Whenever a
Soldier kills a Demoman or vice versa, it adds 1 to the death count.

The plugin also is capable of enforcing player classes. Classes can be
enforced to Soldier and Demo mixed, or Red Demo/Blu Soldier only. Note: I
highly recommend non-team switching maps if you use the latter, since people
will complain GREATLY when they are forced to swap teams to the class they
dislike/do not support!

I am not providing any web interface at this time for the stats, though I
may in the future. You can check your War Stats in real-time by typing:

 !warstats in chat
 /warstats in chat
 sm_warstats in console

Anyone who wants to develop this further, please do. It should be very easy
to get the kill stats using a PHP script for your website!

Thank you and enjoy!
- msleeper
-----------------------------------------------------------------------------
Version History

-- 1.0 (12/11/09)
 . Initial release!

-- 1.1 (12/11/09)
 . Added sm_warstats command to show a chat trigger with death stats.
 . Fixed a few very minor bugs/typos.
 . Added release notes (what you're reading!) and other comments.

-- 1.2 (12/12/09)
 . Added Round_Start global war stats announcement, controlled by new cvar:
   sm_wartrack_roundannounce. Default is On.
 . Fixed minor bug with chat announcement output.
 . Cleaned up code/added more detailed comments.
-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2"

// Cvar handles
new Handle:cvar_TrackDeaths = INVALID_HANDLE;
new Handle:cvar_EnforceMode = INVALID_HANDLE;
new Handle:cvar_RoundAnnounce = INVALID_HANDLE;

// Database handle
new Handle:db = INVALID_HANDLE;

// Plugin info
public Plugin:myinfo = 
{
	name = "War Tracker + Class Enforcer",
	author = "msleeper",
	description = "Tracks Soldier/Demo deaths for the War, and enforces classes",
	version = PLUGIN_VERSION,
	url = "http://www.msleeper.com/"
};

// Here we go!
public OnPluginStart()
{
    // Plugin version public Cvar
    CreateConVar("sm_wartrack_version", PLUGIN_VERSION, "War Tracker + Class Enforcer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    // Config Cvars
    cvar_TrackDeaths = CreateConVar("sm_wartrack_trackdeaths", "1", "Enable/disable Death tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_EnforceMode = CreateConVar("sm_wartrack_enforcemode", "0", "Class enforcement mode, 0 = Off, 1 = Soldier and Demo only, 2 = Red is Demos and Blue is Soldiers", FCVAR_PLUGIN, true, 0.0, true, 2.0);
    cvar_RoundAnnounce = CreateConVar("sm_wartrack_roundannounce", "1", "Announce War stats on each Round start. 0 is Off, 1 is On", FCVAR_PLUGIN, true, 0.0, true, 1.0);

    // Hook the events
    HookEvent("player_spawn", event_EnforceClass);
    HookEvent("player_changeclass", event_EnforceClass);
    HookEvent("player_death", event_PlayerDeath);
    HookEvent("teamplay_round_start", event_RoundStart);
    
    // Register console commands for war stats
    RegConsoleCmd("sm_warstats", cmd_WarStats);

    // Make that config!
    AutoExecConfig(true, "wartrack");
}

// Enforce classes on player respawn/class change

public Action:event_EnforceClass(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new TFClassType:class = TF2_GetPlayerClass(client);
    new team = GetClientTeam(client);

    if (GetConVarInt(cvar_EnforceMode) == 0 || team < 2)
		return;

    if (GetConVarInt(cvar_EnforceMode) == 1)
    {
        if (class == TFClass_Soldier || class == TFClass_DemoMan)
            return;

        new rand = GetRandomInt(0, 1);
        if (rand)
            SetPlayerClass(client, TFClass_Soldier);
        else
            SetPlayerClass(client, TFClass_DemoMan);

        return;
    }

    if (GetConVarInt(cvar_EnforceMode) == 2)
    {
        if (team == 2 && class != TFClass_DemoMan)
            SetPlayerClass(client, TFClass_DemoMan);

        if (team == 3 && class != TFClass_Soldier)
            SetPlayerClass(client, TFClass_Soldier);
    }
}

// Add stats to the war tracker

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!GetConVarBool(cvar_TrackDeaths))
		return;

    new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    new TFClassType:VictimClass = TF2_GetPlayerClass(Victim);
    new TFClassType:AttackerClass = TF2_GetPlayerClass(Attacker);

    new String:ClassString[16];

    if (VictimClass == TFClass_Soldier && AttackerClass == TFClass_DemoMan)
        ClassString = "soldier";

    if (VictimClass == TFClass_DemoMan && AttackerClass == TFClass_Soldier)
        ClassString = "demoman";
    
    new String:query[512];
    Format(query, sizeof(query), "UPDATE sm_wartrack SET value = value + 1 where name='%s_deaths'", ClassString);
    SendSQLUpdate(query);
}

public SendSQLUpdate(String:query[])
{
    new String:Error[512];
    db = SQL_Connect("default", true, Error, sizeof(Error));

    if (db == INVALID_HANDLE)
        return;

    SQL_TQuery(db, SQL_ErrorCallback, query);

    CloseHandle(db);
}

public SQL_ErrorCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	return;
}

// Set's a client's class and forces them to respawn

public SetPlayerClass(client, TFClassType:class)
{
    if (!IsClientConnected(client) && !IsClientInGame(client) && IsFakeClient(client))
        return;

    TF2_SetPlayerClass(client, class, false, true);
    TF2_RespawnPlayer(client);
}

// Show the war stats

public Action:cmd_WarStats(client, args)
{
    if (!client)
        return Plugin_Handled;

    if (!IsClientConnected(client) && !IsClientInGame(client) && IsFakeClient(client))
        return Plugin_Handled;

    new String:Error[512];
    db = SQL_Connect("default", true, Error, sizeof(Error));

    if (db == INVALID_HANDLE)
        return Plugin_Handled;

    decl String:query[256];
    query = "SELECT * FROM sm_wartrack";
    SQL_TQuery(db, DisplayStats, query, client);

    CloseHandle(db);
    return Plugin_Handled;
}

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!GetConVarBool(cvar_RoundAnnounce))
		return Plugin_Handled;

    if (GetClientCount() < 1)
        return Plugin_Handled;

    new String:Error[512];
    db = SQL_Connect("default", true, Error, sizeof(Error));

    if (db == INVALID_HANDLE)
        return Plugin_Handled;

    decl String:query[256];
    query = "SELECT * FROM sm_wartrack";

    new maxplayers = GetMaxClients();
    
    for (new i = 1; i <= maxplayers; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
            SQL_TQuery(db, DisplayStats, query, i);
    }

    CloseHandle(db);
    return Plugin_Handled;
}

// Send the war stats to the client's display

public DisplayStats(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client = data;

    if (!client || hndl == INVALID_HANDLE)
        return;

    new String:Class[32];
    new Deaths = 0;

    PrintToChat(client, "\x04This Server's WAR Contributions!");

    while (SQL_FetchRow(hndl))
    {
        SQL_FetchString(hndl, 0, Class, sizeof(Class));
        Deaths = SQL_FetchInt(hndl, 1);

        if (strcmp("soldier_deaths", Class, false) == 0)
            PrintToChat(client, "\x05 -- Soldier Deaths: %i", Deaths);

        if (strcmp("demoman_deaths", Class, false) == 0)
            PrintToChat(client, "\x05 -- Demoman Deaths: %i", Deaths);
    }
}
