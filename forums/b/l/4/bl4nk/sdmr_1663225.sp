#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2.0a"

new g_iRandomClass;
new g_iRandomClassSpecific[MAXPLAYERS+1];

new bool:g_bIsActive;
new bool:g_bMaxClass;
new bool:g_bClassRestrictions;

new Handle:g_hCvarClass;
new Handle:g_hCvarEnable;
new Handle:g_hCvarRandom;
new Handle:g_hCvarDisable;

new Handle:g_hGameConf;
new Handle:g_hForceStalemate;

public Plugin:myinfo = {
    name = "Sudden Death Melee Redux",
    author = "bl4nk",
    description = "Melee only mode during sudden death",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
};

public OnPluginStart() {
    CreateConVar("sm_sdmr_version", PLUGIN_VERSION, "Sudden Death Melee Redux Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_hCvarClass = CreateConVar("sm_suddendeathmelee_class", "scout", "Class for people to spawn as", FCVAR_PLUGIN);
    g_hCvarEnable = CreateConVar("sm_suddendeathmelee_enable", "1", "Enable/Disable the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarRandom = CreateConVar("sm_suddendeathmelee_random", "1", "Which random mode to choose a class for someone to spawn as (1 = Everyone has a random class, 2 = Everyone has the same random class)", FCVAR_PLUGIN, true, 1.0, true, 2.0);
    g_hCvarDisable = CreateConVar("sm_suddendeathmelee_disableplugins", "1", "Disable known plugins that can cause issues", FCVAR_PLUGIN, true, 0.0, true, 1.0);

    AutoExecConfig(true, "plugin.suddendeathmelee");

    //RegAdminCmd("sm_forcestalemate", Command_ForceStalemate, ADMFLAG_CHEATS, "sm_forcestalemate");

    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
    HookEvent("teamplay_round_start", Event_SuddenDeathEnd);
    HookEvent("teamplay_round_win", Event_SuddenDeathEnd);

    g_hGameConf = LoadGameConfigFile("sdmr.games");

    StartPrepSDKCall(SDKCall_GameRules);
    PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Virtual, "ForceStalemate");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
    g_hForceStalemate = EndPrepSDKCall();
}

public Event_PlayerSpawn(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast) {
    if (GetConVarBool(g_hCvarEnable) && g_bIsActive) {
        new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

        decl String:szClassString[32];
        GetConVarString(g_hCvarClass, szClassString, sizeof(szClassString));

        new TFClassType:iClass = TF2_GetClass(szClassString);
        if (iClass == TFClass_Unknown) {
            if (strcmp(szClassString, "random") == 0) {
                switch(GetConVarInt(g_hCvarRandom)) {
                    case 1: {
                        iClass = TFClassType:g_iRandomClassSpecific[iClient];
                    }
                    case 2: {
                        iClass = TFClassType:g_iRandomClass;
                    }
                }
            } else {
                iClass = TF2_GetPlayerClass(iClient);
            }
        }


        if (TF2_GetPlayerClass(iClient) != iClass) {
            TF2_SetPlayerClass(iClient, iClass);
        }
		
		CreateTimer(0.1, Timer_MeleeStrip, GetEventInt(hEvent, "userid"));
    }
}

public Action:Timer_MeleeStrip(Handle:timer, any:userid) {
    new iClient = GetClientOfUserId(userid);
    if (iClient && IsPlayerAlive(iClient)) {
        for (new i = 0; i <= 5; i++) {
            if (i == 2) {
                continue;
            }

            TF2_RemoveWeaponSlot(iClient, i);
        }

        new weapon = GetPlayerWeaponSlot(iClient, 2);
        SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", weapon);
    }
}

public Event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_bIsActive = true;

    if (GetConVarBool(g_hCvarEnable) && GetConVarBool(g_hCvarDisable)) {
        new Handle:hMaxClass = FindConVar("sm_maxclass_allow");
        if (hMaxClass != INVALID_HANDLE) {
            g_bMaxClass = GetConVarBool(hMaxClass);
            SetConVarBool(hMaxClass, false);
        }

        new Handle:hClassRestrictions = FindConVar("sm_classrestrict_enabled");
        if (hClassRestrictions != INVALID_HANDLE) {
            g_bClassRestrictions = GetConVarBool(hClassRestrictions);
            SetConVarBool(hClassRestrictions, false);
        }
    }

    g_iRandomClass = GetRandomInt(1, 9);

    for (new i = 1; i <= MAXPLAYERS; i ++) {
        g_iRandomClassSpecific[i] = GetRandomInt(1, 9);
    }
}

public Event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (g_bIsActive && GetConVarBool(g_hCvarDisable)) {
        new Handle:hMaxClass = FindConVar("sm_maxclass_allow");
        if (hMaxClass != INVALID_HANDLE) {
            SetConVarBool(hMaxClass, g_bMaxClass);
        }

        new Handle:hClassRestrictions = FindConVar("sm_classrestrict_enabled");
        if (hClassRestrictions != INVALID_HANDLE) {
            SetConVarBool(hClassRestrictions, g_bClassRestrictions);
        }
    }

    g_bIsActive = false;
}

public Action:Command_ForceStalemate(client, args) {
    SDKCall(g_hForceStalemate, 1, false, false);

    return Plugin_Handled;
}