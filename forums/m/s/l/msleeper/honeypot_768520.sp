/*
-----------------------------------------------------------------------------
TF2 ACHIEVEMENT FARMER HONEYPOT - SOURCEMOD PLUGIN
-----------------------------------------------------------------------------
Code Written By msleeper (c) 2009
Visit http://www.msleeper.com/ for more info!
-----------------------------------------------------------------------------
This plugin will, after a short delay, automatically ban non-Reserved flag
players if they earn an achievement. This plugin is designed to be used with
an achievement box map to attract and autoban achievement farmers. The bans
are compatible with SourceBans.

Why?
Achievement farming ruins the integrity, the purpose, of achievements. The
word achievement doesn't mean "dick around in a map for 45 minutes and earn
unlockables", and since Valve has yet to take a step towards stopping those
who belittle the work and dedication of others, I have.

This Is Unfair / Stupid
Only if you are a farmer. This plugin should only affect those who try to
ruin the game. Normal, responsible players should be unaffected.

A warning to server admins!
This will cost you friends and possibly community members. So far it has
cost me 1 already. But I do not think that people should stand by idly
while others devalue the purpose of achievements and unlockables.

Thank you and enjoy!
- msleeper
-----------------------------------------------------------------------------
Version History

-- 2.0 (2/25/09)
 . Initial release!

-- 2.1 (2/25/09)
 . Made the number of achievements required before ban queuing a cvar.
-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "2.1"

// Log var and ban queue array
new String:Logfile[256];
new BanQueue[MAXPLAYERS + 1];
new AchievementCount[MAXPLAYERS + 1];

// Cvar handles
new Handle:cvar_Achievements = INVALID_HANDLE;
new Handle:cvar_WaitTime = INVALID_HANDLE;
new Handle:cvar_BanTime = INVALID_HANDLE;
new Handle:cvar_BanReason = INVALID_HANDLE;
new Handle:cvar_LogActions = INVALID_HANDLE;

// Plugin info
public Plugin:myinfo = 
{
	name = "TF2 Achievment Farmer Honeypot",
	author = "msleeper",
	description = "Autobans players who gain achievements",
	version = PLUGIN_VERSION,
	url = "http://www.msleeper.com/"
};

// Here we go!
public OnPluginStart()
{
    // Plugin version public Cvar
    CreateConVar("sm_honeypot_version", PLUGIN_VERSION, "TF2 Achievement Farmer Honeypot plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    // Hook the achievement event
    HookEvent("achievement_earned", event_Achievement);

    // Debug command to see who is going to get kicked
    RegConsoleCmd("sm_honeypot_debug", cmd_Debug);

    // Config Cvars
    cvar_Achievements = CreateConVar("sm_honeypot_achievements", "1.0", "Number of achievements required before adding to ban queue", FCVAR_PLUGIN, true, 1.0);
    cvar_WaitTime = CreateConVar("sm_honeypot_waittime", "10.0", "Delay after someone has earned an achievement before banning", FCVAR_PLUGIN, true, 1.0);
    cvar_BanTime = CreateConVar("sm_honeypot_bantime", "0", "Duration of autoban, 0 = permenent", FCVAR_PLUGIN);
    cvar_BanReason = CreateConVar("sm_honeypot_banreason", "Achievement Farming", "Ban reason", FCVAR_PLUGIN);
    cvar_LogActions = CreateConVar("sm_honeypot_logactions", "1.0", "Log banning, 0 = Off, 1 = On", FCVAR_PLUGIN, true, 0.0, true, 1.0);

    // Make that config!
    AutoExecConfig(true, "honeypot");

    // Enable logging
    BuildPath(Path_SM, Logfile, sizeof(Logfile), "logs/honeypot.log");
}

// Reset all players Ban queue when a map changes.

public OnMapStart()
{
    new maxplayers = GetMaxClients();
    for (new i = 1; i <= maxplayers; i++)
    {
        BanQueue[i] = 0;
        AchievementCount[i] = 0;
    }
}

// Print debug information.

public Action:cmd_Debug(client, args)
{
    PrintToConsole(client, "[SM] Honeypot Debug");

    new String:Name[64];

    new maxplayers = GetMaxClients();
    for (new i = 1; i <= maxplayers; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i))
        {
            GetClientName(i, Name, sizeof(Name));

            if ((GetUserFlagBits(i) & ADMFLAG_RESERVATION) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
                PrintToConsole(client, " . %s is *Immune*", Name);
            else if (BanQueue[i] == 0)
                PrintToConsole(client, " . %s has %i/%i warnings", Name, AchievementCount[i], GetConVarInt(cvar_Achievements));
            else if (BanQueue[i] == 1)
                PrintToConsole(client, " . %s is in queue to be Banned", Name);
        }
    }
    
    return Plugin_Handled;
}

// Initialize client's ban status to 0 when they connect.

public OnClientPostAdminCheck(client)
{
    BanQueue[client] = 0;
    AchievementCount[client] = 0;
}

// Ban the player after the wait duration.

public Action:timer_BanPlayer(Handle:timer, any:value)
{
    new String:BanReason[255];
    new UserID = value;

    if (!IsClientConnected(UserID) || !IsClientInGame(UserID))
        return;

    GetConVarString(cvar_BanReason, BanReason, sizeof(BanReason));
    ServerCommand("sm_ban #%i %i \"%s\"", GetClientUserId(UserID), GetConVarInt(cvar_BanTime), BanReason);

    if (GetConVarBool(cvar_LogActions))
    {
        new String:Name[64];
        new String:SteamID[64];

        GetClientName(UserID, Name, sizeof(Name));
        GetClientAuthString(UserID, SteamID, sizeof(SteamID));

        LogToFile(Logfile, "%s (%s) has been banned!", Name, SteamID);
    }
}

public Action:event_Achievement(Handle:event, const String:name[], bool:dontBroadcast)
{
    new Player = GetEventInt(event, "player");
    new String:Name[64];
    GetClientName(Player, Name, sizeof(Name));

    if ((GetUserFlagBits(Player) & ADMFLAG_RESERVATION) || (GetUserFlagBits(Player) & ADMFLAG_ROOT))
    {
        if (GetConVarBool(cvar_LogActions))
            LogToFile(Logfile, "Ban of %s ignored, Reserved Flag met", Name);
    }
    else
    {
        AchievementCount[Player] = AchievementCount[Player] + 1;

        if (GetConVarBool(cvar_LogActions))
            LogToFile(Logfile, "%s has been given %i warning", Name, AchievementCount[Player]);

        if (AchievementCount[Player] >= GetConVarInt(cvar_Achievements))
        {
            BanQueue[Player] = 1;
            CreateTimer(GetConVarFloat(cvar_WaitTime), timer_BanPlayer, Player);

            if (GetConVarBool(cvar_LogActions))
                LogToFile(Logfile, "Adding %s to ban queue", Name);
        }
    }
}
