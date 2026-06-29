#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR "MEP"
#define PLUGIN_VERSION "1.0.1"
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

ConVar cvar_csr_hs_comp;
ConVar cvar_csr_ignore_bots_kills;
ConVar cvar_csr_only_human_player;

bool g_bCSRIgnoreBotsKills;
bool g_bCSROnlyHumanPlayer;

int g_iCSRHsComp;
int g_iChapterCIKills[MAXPLAYERS + 1] = { 0, ... };
int g_iChapterSIKills[MAXPLAYERS + 1] = { 0, ... };
int g_iChapterHSKills[MAXPLAYERS + 1] = { 0, ... };

public Plugin myinfo = {
	name = "[L4D2] Chapter Statistical Report",
	author = PLUGIN_AUTHOR,
	description = "Report Chapter Statistic such as CI and SI kills, Headshot kills, and Headshot Accuracy",
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
    CreateConVar("csr_version", PLUGIN_VERSION, "Chapter Statistical Report Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
    cvar_csr_hs_comp = CreateConVar("csr_headshot_accuracy_compare", "1", "1=Compare headshot to player's own kills, 2=Compare headshots to total kills", FCVAR_NOTIFY, true, 1.0, true, 2.0);
    cvar_csr_ignore_bots_kills = CreateConVar("csr_ignore_bots_kills", "0", "0=Calculate bots stats, 1=Do not calculate bots stats\nNote:\n- You need to change 'cvar_csr_hs_comp' to 2 for this to work.\n- This will affect 'cvar_csr_hs_comp' total kills (Excluding bots' kills)\n", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvar_csr_only_human_player = CreateConVar("csr_only_human_player", "0", "0=Print all players stats (Including bots), 1=Print only player stats", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    AutoExecConfig(true, "l4d2_chapter_statistical_report");
    
    cvar_csr_hs_comp.AddChangeHook(Action_ConVarChanged);
    cvar_csr_ignore_bots_kills.AddChangeHook(Action_ConVarChanged);
    cvar_csr_only_human_player.AddChangeHook(Action_ConVarChanged);
    
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);
    
    HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);
    HookEvent("finale_win", Event_FinaleWin, EventHookMode_Pre);
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    
    RegConsoleCmd("sm_stats", Command_Statistic, "Display the current stats to client's chat. Stats will reset every chapter finished or chapter failed");
    RegConsoleCmd("sm_teamstats", Command_TeamStatistic, "Display the current team stats to client's chat. Stats will reset every chapter finished or chapter failed");
}

public void Action_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    g_iCSRHsComp = cvar_csr_hs_comp.IntValue;
    g_bCSRIgnoreBotsKills = cvar_csr_ignore_bots_kills.BoolValue;
    g_bCSROnlyHumanPlayer = cvar_csr_only_human_player.BoolValue;
}

public Action Command_Statistic(int client, int args) {
    PrintClientStats(client);

    return Plugin_Continue;
}

public Action Command_TeamStatistic(int client, int args) {
    PrintTeamStats(client);

    return Plugin_Continue;
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

public Action Event_RoundStart(Event event, char[] name, bool bDontBroadcast) {
    ResetCampaignStats();

    return Plugin_Continue;
}

public int GetTotalKills() {
    int kills = 0;

    for (int i = 1; i <= MaxClients; i++) {
        if (g_bCSRIgnoreBotsKills) {
            if (IS_HUMAN_SURVIVOR(i)) kills += (g_iChapterCIKills[i] + g_iChapterSIKills[i]);
        } else {
            if (IS_SURVIVOR(i)) kills += (g_iChapterCIKills[i] + g_iChapterSIKills[i]);
        }
    }

    return kills;
}

public void PrintClientStats(int client) {
    PrintToChat(client, "\x04[STATS] \x03Chapter Statistical Report");

    if (IS_SURVIVOR(client)) {
        char clientName[64];
        GetClientName(client, clientName, sizeof(clientName));
        
        int killCount  = 0;
        
        if (g_iCSRHsComp == 1) {
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
        
        PrintToChat(client, "\x04[!] \x03%s \x01- \x04CI \x01(\x05%d\x01) \x01- \x04SI \x01(\x05%d\x01) \x01- \x04HS \x01(\x05%d\x01) \x01- \x04HS Acc. \x01(\x05%i%%\x01)", clientName, g_iChapterCIKills[client], g_iChapterSIKills[client], g_iChapterHSKills[client], roundedHSPct);
    }
}

public void PrintTeamStats(int client) {
    PrintToChat(client, "\x04[STATS] \x03Chapter Statistical Report");

    for (int i = 1; i <= MaxClients; i++) {
        if (g_bCSROnlyHumanPlayer) {
            if (IS_HUMAN_SURVIVOR(i)) {
                char clientName[64];
                GetClientName(i, clientName, sizeof(clientName));

                int killCount  = 0;

                if (g_iCSRHsComp == 1) {
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
                
                PrintToChat(client, "\x04[!] \x03%s \x01- \x04CI \x01(\x05%d\x01) \x01- \x04SI \x01(\x05%d\x01) \x01- \x04HS \x01(\x05%d\x01) \x01- \x04HS Acc. \x01(\x05%i%%\x01)", clientName, g_iChapterCIKills[i], g_iChapterSIKills[i], g_iChapterHSKills[i], roundedHSPct);
            }
        } else {
            if (IS_SURVIVOR(i)) {
                char clientName[64];
                GetClientName(i, clientName, sizeof(clientName));

                int killCount  = 0;

                if (g_iCSRHsComp == 1) {
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
                
                PrintToChat(client, "\x04[!] \x03%s \x01- \x04CI \x01(\x05%d\x01) \x01- \x04SI \x01(\x05%d\x01) \x01- \x04HS \x01(\x05%d\x01) \x01- \x04HS Acc. \x01(\x05%i%%\x01)", clientName, g_iChapterCIKills[i], g_iChapterSIKills[i], g_iChapterHSKills[i], roundedHSPct);
            }
        }
    }
}

public void ResetCampaignStats() {
    for (int i = 1; i <= MaxClients; i++) {
        g_iChapterCIKills[i] = 0;
        g_iChapterSIKills[i] = 0;
        g_iChapterHSKills[i] = 0;
    }
}
