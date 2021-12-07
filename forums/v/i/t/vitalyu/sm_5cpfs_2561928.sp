/**
    5CP Fix Suggestions Plugin for Team Fortress 2.
    Copyright (C) 2017  Vasily U.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You can find a full copy of the GNU General Public License
    at <https://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.5"

#define TEAM_NONE 0
#define TEAM_RED 2
#define TEAM_BLU 3

//MAX_FILE_LEN 80 is an arbitrary number, taken from another plugin.
#define MAX_FILE_LEN 80

ConVar g_cvEnabled;
ConVar g_cvShottimer; 
ConVar g_cvTimerMode;
ConVar g_cvStalemateSound;
ConVar g_cvChatTimerInterval;
ConVar g_cvShowTimerBelow;
ConVar g_cvVoiceCountdown;
ConVar g_cvPunishment;
ConVar g_cvPunishmentTimer;
ConVar g_cvDebugSwitchTeams;

bool g_bEnabled;
int g_iShottimer;
int g_iTimerMode;
char g_szStalemateSound[MAX_FILE_LEN];
int g_iChatTimerInterval;
int g_iShowTimerBelow;
int g_iVoiceCountdown;
int g_iPunishment;
int g_iPunishmentTimer;
bool g_bDebugSwitchTeams;

Handle g_hTimer = null;
int g_iTimeLeft;

public Plugin myinfo =
{
    name = "5CP Fix Suggestions",
    author = "Vasily",
    description = "Implements a suggestion for fixing the 5CP gamemode.",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart() {
    CreateConVar("sm_5cpfs_version",
                    PLUGIN_VERSION,
                    "5CP Fix Suggestions Version",
                    FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

    g_cvEnabled = CreateConVar("sm_5cpfs_enabled",
                                    "1",
                                    "Enable or disable plugin. Must be manually disabled for gamemodes other than 5CP.\n0 = Disabled\n1 = Enabled",
                                    FCVAR_DONTRECORD | FCVAR_NOTIFY,
                                    true,
                                    0.0,
                                    true,
                                    1.0);
    g_bEnabled = GetConVarBool(g_cvEnabled);
    HookConVarChange(g_cvEnabled, OnConVarChange);
    
    g_cvShottimer = CreateConVar("sm_5cpfs_shottimer",
                                        "360",
                                        "Time in seconds before control points will be unassigned.\nUse sm_5cpfs_enabled 0 to disable completely.",
                                        FCVAR_NOTIFY,                                               
                                        true, 
                                        1.0, 
                                        false);
    g_iShottimer = GetConVarInt(g_cvShottimer);
    HookConVarChange(g_cvShottimer, OnConVarChange);
    
    g_cvTimerMode = CreateConVar("sm_5cpfs_timer_mode",
                                        "1",
                                        "How to show countdown timer.\n0 = Disabled\n1 = HUD Timer\n2 = Chat Timer",
                                        FCVAR_NOTIFY,                                               
                                        true, 
                                        0.0, 
                                        true,
                                        2.0);
    g_iTimerMode = GetConVarInt(g_cvTimerMode);
    HookConVarChange(g_cvTimerMode, OnConVarChange);
    
    g_cvStalemateSound = CreateConVar("sm_5cpfs_stalemate_sound", 
                                                "vo/announcer_overtime.mp3", 
                                                "Directory location of the sound to play.",
                                                FCVAR_NOTIFY);
    GetConVarString(g_cvStalemateSound, g_szStalemateSound, MAX_FILE_LEN);
    HookConVarChange(g_cvStalemateSound, OnConVarChange);
    
    g_cvChatTimerInterval = CreateConVar("sm_5cpfs_chat_interval",
                                        "10",
                                        "Interval between chat timer notifications.",
                                        FCVAR_NOTIFY,
                                        true,
                                        0.0,
                                        false);
    g_iChatTimerInterval = GetConVarInt(g_cvChatTimerInterval);
    HookConVarChange(g_cvChatTimerInterval, OnConVarChange);
    
    g_cvShowTimerBelow = CreateConVar("sm_5cpfs_show_timer_below",
                                        "30",
                                        "Disables the timer when it is above this amount in seconds.\nSetting it to the same value as the timer or higher than the timer will always show the timer.\n0 = Always hidden.",
                                        FCVAR_NOTIFY,
                                        true,
                                        0.0,
                                        false);
    g_iShowTimerBelow = GetConVarInt(g_cvShowTimerBelow);
    HookConVarChange(g_cvShowTimerBelow, OnConVarChange);
    
    g_cvVoiceCountdown = CreateConVar("sm_5cpfs_countdown_voice",
                                                "5",
                                                "The time at which Announcer voice lines should play.\n>=1 = The voiced countdown will start here.\n0 = Only the stalemate sound will be played.\n-1 = No sounds will be played.",
                                                FCVAR_NOTIFY,
                                                false,
                                                -1.0,
                                                true,
                                                5.0);
    g_iVoiceCountdown = GetConVarInt(g_cvVoiceCountdown);
    HookConVarChange(g_cvVoiceCountdown, OnConVarChange);
    
    g_cvPunishment = CreateConVar("sm_5cpfs_punishment",
                                        "0",
                                        "Punishment upon expiration of the timer.\n1 = The aggressive points (mid and fourth) will be assigned to the defensive team.\n0 = The aggressive points (mid and fourth) will be unassigned.",
                                        FCVAR_NOTIFY,                                               
                                        true, 
                                        0.0, 
                                        true,
                                        1.0);
    g_iPunishment = GetConVarInt(g_cvPunishment);
    HookConVarChange(g_cvPunishment, OnConVarChange);
    
    g_cvPunishmentTimer = CreateConVar("sm_5cpfs_punishment_timer",
                                        "0",
                                        "Only used if sm_5cpfs_punishment is set to 1.\n1 = A new shottimer will be started, if it expires the points will be reassigned.\n0 = A new shottimer will not be started. There will be no shottimer until a team caps a point.",
                                        FCVAR_NOTIFY,                                               
                                        true, 
                                        0.0, 
                                        true,
                                        1.0);
    g_iPunishmentTimer = GetConVarInt(g_cvPunishmentTimer);
    HookConVarChange(g_cvPunishmentTimer, OnConVarChange);
    
    g_cvDebugSwitchTeams = CreateConVar("sm_5cpfs_debug_switch_teams",
                                    "0",
                                    "See README for usage.\n0 = Disabled\n1 = Enabled",
                                    FCVAR_NOTIFY,
                                    true,
                                    0.0,
                                    true,
                                    1.0);
    g_bDebugSwitchTeams = GetConVarBool(g_cvDebugSwitchTeams);
    HookConVarChange(g_cvDebugSwitchTeams, OnConVarChange);

    AutoExecConfig(true, "sm_5cpfs");
}

public void OnMapStart() {
    if (g_bEnabled) {
        HookEvent("teamplay_round_start", OnRoundStart);
        HookEvent("round_start", OnRoundStart);
        HookEvent("round_end", OnRoundEnd);
        HookEvent("teamplay_round_win", OnRoundEnd);

        if (g_iVoiceCountdown >= 0) {
            if (!strcmp(g_szStalemateSound, "", true)) {
                PrecacheSound(g_szStalemateSound, true);
            }
            else {
                g_cvStalemateSound.RestoreDefault();
                GetConVarString(g_cvStalemateSound, g_szStalemateSound, MAX_FILE_LEN);
                PrecacheSound(g_szStalemateSound, true);
            }
            PrecacheSound("vo/compmode/cm_admin_compbegins05.mp3");
            PrecacheSound("vo/compmode/cm_admin_compbegins04.mp3");
            PrecacheSound("vo/compmode/cm_admin_compbegins03.mp3");
            PrecacheSound("vo/compmode/cm_admin_compbegins02.mp3");
            PrecacheSound("vo/compmode/cm_admin_compbegins01.mp3");
        }
    }
}

public void OnMapEnd() {
    DisableCPTimer();
    UnhookEvent("teamplay_round_start", OnRoundStart);
    UnhookEvent("round_start", OnRoundStart);
    UnhookEvent("round_end", OnRoundEnd);
    UnhookEvent("teamplay_round_win", OnRoundEnd);
    UnhookEntityOutput("team_control_point", "OnCapTeam1", CPCapture);
    UnhookEntityOutput("team_control_point", "OnCapTeam2", CPCapture);
}

public void OnRoundStart(Handle hEvent, const char[] szName, bool bDontBroadcast) {
    PrintToChatAll("[5CPFS] Enabled. Timer set at %d seconds", g_iShottimer);
    
    DisableCPTimer();
    HookEntityOutput("team_control_point", "OnCapTeam1", CPCapture);
    HookEntityOutput("team_control_point", "OnCapTeam2", CPCapture);
}

public void OnRoundEnd(Handle hEvent, const char[] szName, bool bDontBroadcast){
    DisableCPTimer();
    UnhookEntityOutput("team_control_point", "OnCapTeam1", CPCapture);
    UnhookEntityOutput("team_control_point", "OnCapTeam2", CPCapture);
}

public void OnConVarChange(Handle hConvar, char[] szOldValue, char[] szNewValue) {
    if (hConvar == g_cvEnabled) {
        g_bEnabled = GetConVarBool(g_cvEnabled);
        if (!g_bEnabled) {
            DisableCPTimer();
            OnMapEnd();
        }
        else {
            OnMapStart();
        }
    }
    else if (hConvar == g_cvShottimer) {
        g_iShottimer = GetConVarInt(g_cvShottimer);
        if (g_hTimer != null && g_iShottimer > 0) {
            g_iTimeLeft = g_iShottimer;
        }
    } 
    else if (hConvar == g_cvChatTimerInterval) {
        g_iChatTimerInterval = GetConVarInt(g_cvChatTimerInterval);
    }
    else if (hConvar == g_cvStalemateSound) {
        if (!strcmp(g_szStalemateSound, "", true)) {
            GetConVarString(g_cvStalemateSound, g_szStalemateSound, MAX_FILE_LEN);
            PrecacheSound(g_szStalemateSound, true);
        }
        else {
            g_cvStalemateSound.RestoreDefault();
        }
    }
    else if (hConvar == g_cvTimerMode) {
        g_iTimerMode = GetConVarInt(g_cvTimerMode);
    }
    else if (hConvar == g_cvShowTimerBelow) {
        g_iShowTimerBelow = GetConVarInt(g_cvShowTimerBelow);
    }
    else if (hConvar == g_cvVoiceCountdown) {
        g_iVoiceCountdown = GetConVarInt(g_cvVoiceCountdown);
    }
    else if (hConvar == g_cvDebugSwitchTeams) {
        g_bDebugSwitchTeams = GetConVarBool(g_cvDebugSwitchTeams);
    }
    else if (hConvar == g_cvPunishment) {
        g_iPunishment = GetConVarInt(g_cvPunishment);
    }
    else if (hConvar == g_cvPunishmentTimer) {
        g_iPunishmentTimer = GetConVarInt(g_cvPunishmentTimer);
    }
}

public Action TickTimer(Handle hTimer, Handle pack) {
    int iCPToDisable = -1;
    int iCappingTeam = -1;

    ResetPack(pack);
    iCPToDisable = ReadPackCell(pack);
    iCappingTeam = ReadPackCell(pack);

    g_iTimeLeft--;
    
    if(g_iTimerMode == 1 && (g_iTimeLeft < g_iShowTimerBelow && g_iShowTimerBelow != 0)) {
        PrintCenterTextAll("Shottimer: %02d:%02d",
                                g_iTimeLeft / 60,
                                g_iTimeLeft % 60);
    }
    if (g_iTimerMode == 2
        && g_iTimeLeft % g_iChatTimerInterval == 0
        && (g_iTimeLeft < g_iShowTimerBelow && g_iShowTimerBelow != 0)) {
        PrintToChatAll("[5CPFS] Shottimer: %02d:%02d",
                            g_iTimeLeft / 60,
                            g_iTimeLeft % 60);
    }
    if (g_iVoiceCountdown > 0 && g_iTimeLeft <= 5) {
        if (g_iVoiceCountdown >= 5 && g_iTimeLeft == 5) {
            EmitSoundToAll("vo/compmode/cm_admin_compbegins05.mp3");
        }
        else if (g_iVoiceCountdown >= 4 && g_iTimeLeft == 4) {
            EmitSoundToAll("vo/compmode/cm_admin_compbegins04.mp3");
        }
        else if (g_iVoiceCountdown >= 3 && g_iTimeLeft == 3) {
            EmitSoundToAll("vo/compmode/cm_admin_compbegins03.mp3");
        }
        else if (g_iVoiceCountdown >= 2 && g_iTimeLeft == 2) {
            EmitSoundToAll("vo/compmode/cm_admin_compbegins02.mp3");
        }
        else if (g_iVoiceCountdown >= 1 && g_iTimeLeft == 1) {
            EmitSoundToAll("vo/compmode/cm_admin_compbegins01.mp3");
        }
    }
    
    if(g_iTimeLeft <= 0) {
        DisableCPTimer();
        DisablePoints(iCPToDisable, iCappingTeam);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

void StartTimer(int iCPToDisable, int iCappingTeam) {
    DisableCPTimer();
    
    DataPack pack;
    
    g_iTimeLeft = g_iShottimer;
    
    g_hTimer = CreateDataTimer(1.0, TickTimer, pack, TIMER_REPEAT);
    pack.WriteCell(iCPToDisable);
    pack.WriteCell(iCappingTeam);
}

void DisableCPTimer() {
    if (g_hTimer != null) {
        KillTimer(g_hTimer);
        g_hTimer = null;
    }
}

public void CPCapture(const char[] szName, int iCaller, int iActivator, float fDelay) {
    int iCappingTeam;

    /*
    For some reason OnCapTeam1 and OnCapTeam2 are switched around.
    Official documentation https://developer.valvesoftware.com/wiki/Team_control_point#Outputs
    last updated 17 March 2017 says this:
    OnCapTeam1
        Sent when RED capture this point.
    OnCapTeam2
        Sent when BLUE capture this point.
    Testing on cp_badlands, cp_gullywash_final, cp_snakewater_final1,
    cp_sunshine, cp_reckoner_rc2, cp_granary_pro_rc8, cp_prolands_b2c, 
    cp_process_final and cp_metalworks leads to the opposite.
    */
    if (strcmp(szName, "OnCapTeam1", true)) {
        if (!g_bDebugSwitchTeams) {
            iCappingTeam = TEAM_BLU;
        }
        else {
            iCappingTeam = TEAM_RED;
        }
    }
    else if (strcmp(szName, "OnCapTeam2", true)) {
        if (!g_bDebugSwitchTeams) {
            iCappingTeam = TEAM_RED;
        }
        else {
            iCappingTeam = TEAM_BLU;
        }
    }
    //1156 is m_iDefaultOwner of the team_control_point entity
    if (GetEntData(iCaller, 1156, 4) != iCappingTeam) {
        StartTimer(iCaller, iCappingTeam);
    }
    else if (g_hTimer != null && GetEntData(iCaller, 1156, 4) == iCappingTeam) {
        /*
        If the defensive team recaptures their 2nd without the timer,
        the point shouldn't be unassigned, but mid should still be unassigned
        because the team holding mid are still aggressors.
        */
        StartTimer(ReturnMidCP(), iCappingTeam);
    }
}

void DisablePoints(int iCPToDisable, int iCappingTeam) {
    int iRewardTeam = -1;
    
    DisableCPTimer();
    
    if (g_iPunishment == 1) {
        if (iCappingTeam == TEAM_BLU) {
            iRewardTeam = TEAM_RED;
        }
        else if (iCappingTeam == TEAM_RED) {
            iRewardTeam = TEAM_BLU;
        }
    }
    else {
        iRewardTeam = TEAM_NONE;
    }
    
    if (g_iVoiceCountdown > 0) {
        EmitSoundToAll(g_szStalemateSound);
    }
    //1156 is m_iDefaultOwner of the team_control_point entity
    if (GetEntData(iCPToDisable, 1156, 4) != TEAM_NONE) {
        SetVariantInt(iRewardTeam);
        AcceptEntityInput(iCPToDisable, "SetOwner", 0, 0);
    }
    SetVariantInt(iRewardTeam);
    AcceptEntityInput(ReturnMidCP(), "SetOwner", 0, 0);
    
    if (g_iPunishmentTimer == 0) {
        DisableCPTimer();
    }
    PrintToChatAll("[5CPFS] Shottimer reached 0. Points reassigned.");
}

int ReturnMidCP() {
    int iLookUpIndex = -1;
    int iMidCP;

    for (int n = 0; n <= 5; n++) {
        iMidCP = FindEntityByClassname(iLookUpIndex, "team_control_point");
        iLookUpIndex = iMidCP;
        if (IsValidEntity(iMidCP)) {
            //1156 is m_iDefaultOwner of the team_control_point entity
            if (GetEntData(iMidCP, 1156, 4) == TEAM_NONE) {
                return iMidCP;
            }
        }
    }
    
    return -1;
}
