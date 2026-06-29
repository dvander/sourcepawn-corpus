#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "MEP"
#define PLUGIN_VERSION "1.2.0"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=341241"

#define ZC_SMOKER       1
#define ZC_BOOMER       2
#define ZC_HUNTER       3
#define ZC_SPITTER      4
#define ZC_JOCKEY       5
#define ZC_CHARGER      6
#define ZC_TANK         8

#define TEAM_SPECTATOR          1
#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

#define HS_COMP_OWN_KILLS       1
#define HS_COMP_TEAM_KILLS      1

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_VALID_HUMAN(%1)		(IS_VALID_CLIENT(%1) && IsClientConnected(%1) && !IsFakeClient(%1))
#define IS_SURVIVOR(%1)         (IS_VALID_CLIENT(%1) && IsClientInGame(%1) && GetClientTeam(%1) == TEAM_SURVIVOR)
#define IS_HUMAN_SURVIVOR(%1)   (IS_VALID_HUMAN(%1) && IS_SURVIVOR(%1))

ConVar g_cvarHsAccCompare;
ConVar g_cvarIgnoreBotsKills;
ConVar g_cvarOnlyHumanPlayer;
ConVar g_cvarPrintMode;
ConVar g_cvarStatsOnFailed;
ConVar g_cvarResetStats;

int g_iHsCompare;
bool g_bIgnoreBotsKills;
bool g_bOnlyHumanPlayer;
bool g_bPrintMode;
bool g_bStatsOnFailed;
bool g_bResetStatsMode;

int g_iChapterCIKills[MAXPLAYERS + 1] = { 0, ... };
int g_iChapterSIKills[MAXPLAYERS + 1] = { 0, ... };
int g_iChapterHSKills[MAXPLAYERS + 1] = { 0, ... };

public Plugin myinfo = {
	name = "[L4D/L4D2] Chapter Statistical Report",
	author = PLUGIN_AUTHOR,
	description = "Report Chapter Statistic such as CI and SI kills, Headshot kills, and Headshot Accuracy",
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
    CreateConVar("csr_version", PLUGIN_VERSION, "Chapter Statistical Report Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
    g_cvarHsAccCompare = CreateConVar("csr_headshot_accuracy_compare", "1", "1=Compare headshot to player's own kills, 2=Compare headshots to all players total kills", FCVAR_NOTIFY, true, 1.0, true, 2.0);
    g_cvarIgnoreBotsKills = CreateConVar("csr_ignore_bots_kills", "0", "0=Add bots total kills for headshot accuracy compare, 1=Do not add bots total kills\nNote:\n- You need to change 'csr_headshot_accuracy_compare' to 2 for this to work.\n- This will affect 'csr_headshot_accuracy_compare' total kills (Excluding bots' kills)\n", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvarOnlyHumanPlayer = CreateConVar("csr_only_human_player", "0", "0=Print all players stats (Including bots), 1=Print only player stats", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvarPrintMode = CreateConVar("csr_print_mode", "0", "0=Print to Chat, 1=Print to Console", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvarStatsOnFailed = CreateConVar("csr_stats_on_failed", "0", "0=Do not print stats when mission failed / lost, 1=Print stats when mission failed / lost", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvarResetStats = CreateConVar("csr_reset_stats", "0","0=Reset stats on round/chapter start, 1=Reset stats on map end", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    AutoExecConfig(true, "l4d2_chapter_statistical_report");

    g_cvarHsAccCompare.AddChangeHook(Action_ConVarChanged);
    g_cvarIgnoreBotsKills.AddChangeHook(Action_ConVarChanged);
    g_cvarOnlyHumanPlayer.AddChangeHook(Action_ConVarChanged);
    g_cvarPrintMode.AddChangeHook(Action_ConVarChanged);
    g_cvarStatsOnFailed.AddChangeHook(Action_ConVarChanged);
    g_cvarResetStats.AddChangeHook(Action_ConVarChanged);

    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);

    HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);
    HookEvent("finale_win", Event_FinaleWin, EventHookMode_Pre);
    HookEvent("mission_lost", Event_MissionLost, EventHookMode_Pre);
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

    RegConsoleCmd("sm_stats", Command_Statistics, "Display the current stats to client's chat.");
    RegConsoleCmd("sm_teamstats", Command_TeamStatistics, "Display the current team stats to client's chat.");
    RegAdminCmd("sm_resetstats", Command_ResetStatistics, ADMFLAG_GENERIC, "Let admin reset all survivors stats.");
}

public void Action_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    g_iHsCompare = g_cvarHsAccCompare.IntValue;
    g_bIgnoreBotsKills = g_cvarIgnoreBotsKills.BoolValue;
    g_bOnlyHumanPlayer = g_cvarOnlyHumanPlayer.BoolValue;
    g_bPrintMode = g_cvarPrintMode.BoolValue;
    g_bStatsOnFailed = g_cvarStatsOnFailed.BoolValue;
    g_bResetStatsMode = g_cvarResetStats.BoolValue;
}

public Action Command_Statistics(int client, int args) {
    PrintClientStats(client);

    return Plugin_Handled;
}

public Action Command_TeamStatistics(int client, int args) {
    PrintTeamStats(client);

    return Plugin_Handled;
}

public Action Command_ResetStatistics(int client, int args) {
    ResetCampaignStats();
    PrintToChat(client, "\x04[CSR] \x01Statistics have sucessfully \x03reset\x01.");

    return Plugin_Handled;
}

public Action Event_PlayerDeath(Event event, char[] name, bool bDontBroadcast) {
    int victim = event.GetInt("entityid");
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    bool isHeadshot = event.GetBool("headshot");
    
    char infectedName[32];
    char clsName[32];

    event.GetString("victimname", infectedName, sizeof(infectedName));
    GetEntityClassname(victim, clsName, sizeof(clsName));

    if (IS_SURVIVOR(attacker) && isHeadshot) g_iChapterHSKills[attacker]++;

    if (StrEqual(infectedName, "infected") || StrEqual(clsName, "infected")) {
        if (IS_SURVIVOR(attacker)) g_iChapterCIKills[attacker]++;
    } else {
        victim = event.GetInt("userid");
        if (victim == 0) return Plugin_Handled;
        int zClass = GetEntProp(GetClientOfUserId(victim), Prop_Send, "m_zombieClass");

        if (zClass >= ZC_SMOKER && zClass <= ZC_TANK) {
            if (IS_SURVIVOR(attacker)) g_iChapterSIKills[attacker]++;
        }
    }
    
    return Plugin_Continue;
}

public Action Event_WitchKilled(Event event, char[] name, bool bDontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IS_SURVIVOR(client)) g_iChapterSIKills[client]++;

    return Plugin_Continue;
}

public Action Event_MapTransition(Event event, char[] name, bool bDontBroadcast) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IS_HUMAN_SURVIVOR(i)) PrintTeamStats(i);
    }

    return Plugin_Continue;
}

public Action Event_FinaleWin(Event event, char[] name, bool bDontBroadcast) {    
    for (int i = 1; i <= MaxClients; i++) {
        if (IS_HUMAN_SURVIVOR(i)) PrintTeamStats(i);
    }

    return Plugin_Continue;
}

public Action Event_MissionLost(Event event, char[] name, bool bDontBroadcast) {
    if (g_bStatsOnFailed) {
        for (int i = 1; i <= MaxClients; i++) {
            if (IS_HUMAN_SURVIVOR(i)) PrintTeamStats(i);
        }
    }

    return Plugin_Continue;
}

public Action Event_RoundStart(Event event, char[] name, bool bDontBroadcast) {
    if (!g_bResetStatsMode) {
        ResetCampaignStats();
    } else {
        if (L4D_IsFirstMapInScenario()) {
            ResetCampaignStats();
        }
    }

    
    return Plugin_Continue;
}

public int GetTotalKills() {
    int kills = 0;

    for (int i = 1; i <= MaxClients; i++) {
        if (g_bIgnoreBotsKills) {
            if (IS_HUMAN_SURVIVOR(i)) kills += (g_iChapterCIKills[i] + g_iChapterSIKills[i]);
        } else {
            if (IS_SURVIVOR(i)) kills += (g_iChapterCIKills[i] + g_iChapterSIKills[i]);
        }
    }

    return kills;
}

public void PrintClientStats(int client) {
    if (g_bPrintMode) {
        PrintToChat(client, "\x04[STATS] \x01Your statistics printed on the \x03Console\x01.");
        PrintToConsole(client, "\x04[STATS] \x03Chapter Statistical Report");
    } else {
        PrintToChat(client, "\x04[STATS] \x03Chapter Statistical Report");
    }
    
    if (IS_SURVIVOR(client)) {
        char clientName[64];
        GetClientName(client, clientName, sizeof(clientName));
        
        int killCount  = 0;

        if (g_iHsCompare == 1) {
            killCount = g_iChapterCIKills[client] + g_iChapterSIKills[client];
        } else {
            killCount = GetTotalKills();
        }

        float hsPercentage = 0.0;
        int roundedHSPct = 0;

        if (g_iChapterHSKills[client] > 0) {
            hsPercentage = (float(g_iChapterHSKills[client]) / float(killCount)) * 100;
            roundedHSPct = RoundFloat(hsPercentage);
        }

        if (g_bPrintMode) {
            PrintToConsole(client, "\x04[!] \x03%s \x01- \x04CI \x01(\x05%d\x01) \x01- \x04SI \x01(\x05%d\x01) \x01- \x04HS \x01(\x05%d\x01) \x01- \x04HS Acc. \x01(\x05%i%%\x01)", clientName, g_iChapterCIKills[client], g_iChapterSIKills[client], g_iChapterHSKills[client], roundedHSPct);
        } else {
            PrintToChat(client, "\x04[!] \x03%s \x01- \x04CI \x01(\x05%d\x01) \x01- \x04SI \x01(\x05%d\x01) \x01- \x04HS \x01(\x05%d\x01) \x01- \x04HS Acc. \x01(\x05%i%%\x01)", clientName, g_iChapterCIKills[client], g_iChapterSIKills[client], g_iChapterHSKills[client], roundedHSPct);
        }
    }
}

public void PrintTeamStats(int client) {
    if (g_bPrintMode) {
        PrintToChat(client, "\x04[STATS] \x01Team statistics printed on the \x03Console\x01.");
        PrintToConsole(client, "\x04[STATS] \x03Chapter Statistical Report");
    } else {
        PrintToChat(client, "\x04[STATS] \x03Chapter Statistical Report");
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (g_bOnlyHumanPlayer) {
            if (IS_HUMAN_SURVIVOR(i)) {
                char clientName[64];
                GetClientName(i, clientName, sizeof(clientName));

                int killCount  = 0;

                if (g_iHsCompare == 1) {
                    killCount = g_iChapterCIKills[client] + g_iChapterSIKills[client];
                } else {
                    killCount = GetTotalKills();
                }

                float hsPercentage = 0.0;
                int roundedHSPct = 0;

                if (g_iChapterHSKills[i] > 0) {
                    hsPercentage = (float(g_iChapterHSKills[i]) / float(killCount)) * 100;
                    roundedHSPct = RoundFloat(hsPercentage);
                }
                
                if (g_bPrintMode) {
                    PrintToConsole(client, "\x04[!] \x03%s \x01- \x04CI \x01(\x05%d\x01) \x01- \x04SI \x01(\x05%d\x01) \x01- \x04HS \x01(\x05%d\x01) \x01- \x04HS Acc. \x01(\x05%i%%\x01)", clientName, g_iChapterCIKills[i], g_iChapterSIKills[i], g_iChapterHSKills[i], roundedHSPct);
                } else {
                    PrintToChat(client, "\x04[!] \x03%s \x01- \x04CI \x01(\x05%d\x01) \x01- \x04SI \x01(\x05%d\x01) \x01- \x04HS \x01(\x05%d\x01) \x01- \x04HS Acc. \x01(\x05%i%%\x01)", clientName, g_iChapterCIKills[i], g_iChapterSIKills[i], g_iChapterHSKills[i], roundedHSPct);
                }
            }
        } else {
            if (IS_SURVIVOR(i)) {
                char clientName[64];
                GetClientName(i, clientName, sizeof(clientName));

                int killCount  = 0;

                if (g_iHsCompare == 1) {
                    killCount = g_iChapterCIKills[client] + g_iChapterSIKills[client];
                } else {
                    killCount = GetTotalKills();
                }

                float hsPercentage = 0.0;
                int roundedHSPct = 0;

                if (g_iChapterHSKills[i] > 0) {
                    hsPercentage = (float(g_iChapterHSKills[i]) / float(killCount)) * 100;
                    roundedHSPct = RoundFloat(hsPercentage);
                }
                
                if (g_bPrintMode) {
                    PrintToConsole(client, "\x04[!] \x03%s \x01- \x04CI \x01(\x05%d\x01) \x01- \x04SI \x01(\x05%d\x01) \x01- \x04HS \x01(\x05%d\x01) \x01- \x04HS Acc. \x01(\x05%i%%\x01)", clientName, g_iChapterCIKills[i], g_iChapterSIKills[i], g_iChapterHSKills[i], roundedHSPct);
                } else {
                    PrintToChat(client, "\x04[!] \x03%s \x01- \x04CI \x01(\x05%d\x01) \x01- \x04SI \x01(\x05%d\x01) \x01- \x04HS \x01(\x05%d\x01) \x01- \x04HS Acc. \x01(\x05%i%%\x01)", clientName, g_iChapterCIKills[i], g_iChapterSIKills[i], g_iChapterHSKills[i], roundedHSPct);
                }
            }
        }
    }
}

public void ResetCampaignStats() {
    for (int i = 1; i <= MaxClients; i++) {
        if (IS_VALID_CLIENT(i)) {
            g_iChapterCIKills[i] = 0;
            g_iChapterSIKills[i] = 0;
            g_iChapterHSKills[i] = 0;
        }
    }
}