#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <cstrike>
#include <hosties>
#include <lastrequest>

#define BS_VERSION "1.0.3"
#define COLLISION_NOBLOCK 2
#define COLLISION_BLOCK 5

new g_LREntryNum;
new LR_Player_Prisoner = -1;
new LR_Player_Guard = -1;
new String:g_sLR_Name[64];
new Handle:g_hVersion = INVALID_HANDLE;

new Handle:g_hNoBlock;
new IsNoBlockEnabled;
new g_offsCollisionGroup;
new g_iHealth;

public Plugin:myinfo =
{
    name = "Last Request: Backstabs",
    author = "Jason Bourne & Kolapsicle",
    description = "Win the LR by backstabbing your opponent.",
    version = BS_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=243262"
};


public OnPluginStart()
{
    LoadTranslations("backstabs.phrases");

    Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "LR Name", LANG_SERVER);

    HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Pre);

    g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");

    if (g_iHealth == -1)
    {
        SetFailState("Error - Unable to get offset for CSSPlayer::m_iHealth");
    }

    g_hVersion = CreateConVar("sm_backstabs_version", BS_VERSION, "Current Backstabs version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    SetConVarString(g_hVersion, BS_VERSION);

    g_hNoBlock = FindConVar("sm_hosties_noblock_enable");

    IsNoBlockEnabled = GetConVarInt(g_hNoBlock);
    if (IsNoBlockEnabled == 0)
    {
         g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
    }
}


public OnConfigsExecuted()
{
    static bool:bAddedCustomLR = false;
    if ( ! bAddedCustomLR)
    {
        g_LREntryNum = AddLastRequestToList(LR_Start, LR_Stop, g_sLR_Name);
        bAddedCustomLR = true;
    }
}


public OnPluginEnd()
{
    RemoveLastRequestFromList(LR_Start, LR_Stop, g_sLR_Name);
}


public LR_Start(Handle:LR_Array, iIndexInArray)
{
    new This_LR_Type = GetArrayCell(LR_Array, iIndexInArray, _:Block_LRType);
    if (This_LR_Type == g_LREntryNum)
    {
        LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
        LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard);

        // check datapack value
        new LR_Pack_Value = GetArrayCell(LR_Array, iIndexInArray, _:Block_Global1);
        switch (LR_Pack_Value)
        {
            case -1:
            {
                PrintToServer("no info included");
            }
        }

        SetEntityHealth(LR_Player_Prisoner, 100);
        SetEntityHealth(LR_Player_Guard, 100);

        StripAllWeapons(LR_Player_Prisoner);
        StripAllWeapons(LR_Player_Guard);

        GivePlayerItem(LR_Player_Guard, "weapon_knife", CS_SLOT_KNIFE);
        GivePlayerItem(LR_Player_Prisoner, "weapon_knife", CS_SLOT_KNIFE);

        if (IsNoBlockEnabled == 0)
        {
            SetEntData(LR_Player_Prisoner, g_offsCollisionGroup, COLLISION_NOBLOCK, 4, true);
            SetEntData(LR_Player_Guard, g_offsCollisionGroup, COLLISION_NOBLOCK, 4, true);
        }

        PrintToChatAll(CHAT_BANNER, "LR Start", LR_Player_Prisoner, LR_Player_Guard);
        PrintToChatAll(CHAT_BANNER, "LR Explain");
    }
}


public LR_Stop(This_LR_Type, Player_Prisoner, Player_Guard)
{
    if (This_LR_Type == g_LREntryNum && LR_Player_Prisoner != -1)
    {
        if (IsClientInGame(LR_Player_Prisoner))
        {
            if (IsNoBlockEnabled == 0)
            {
                SetEntData(LR_Player_Prisoner, g_offsCollisionGroup, COLLISION_BLOCK, 4, true);
            }
            if (IsPlayerAlive(LR_Player_Prisoner))
            {
                SetEntityHealth(LR_Player_Prisoner, 100);
                PrintToChatAll(CHAT_BANNER, "LR Winner BS", LR_Player_Prisoner);
            }
        }

        if (IsClientInGame(LR_Player_Guard))
        {
            if (IsNoBlockEnabled == 0)
            {
                SetEntData(LR_Player_Guard, g_offsCollisionGroup, COLLISION_BLOCK, 4, true);
            }
            if (IsPlayerAlive(LR_Player_Guard))
            {
                SetEntityHealth(LR_Player_Guard, 100);
                PrintToChatAll(CHAT_BANNER, "LR Winner BS", LR_Player_Guard);
            }
        }

        LR_Player_Prisoner = -1;
        LR_Player_Guard = -1;
    }
}


public Action:EventPlayerHurt(Handle:event, const String:name[],bool:dontBroadcast)
{
    if (LR_Player_Prisoner != -1)
    {
        new victim = GetClientOfUserId(GetEventInt(event, "userid"));
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        new health = GetEventInt(event, "health");
        new dhealth = GetEventInt(event, "dmg_health");
        decl String:wname[64];
        GetEventString(event, "weapon", wname, sizeof(wname));

        if(IsClientInGame(victim) && IsClientInGame(attacker))
        {
            if(IsClientInLastRequest(victim))
            {
                if((!StrEqual(wname, "knife", false)) || (attacker != LR_Player_Prisoner && attacker != LR_Player_Guard) || (dhealth < 100))
                {
                    SetEntityHealth(victim, 100);
                }
            }
            else if(!IsClientInLastRequest(victim) && IsClientInLastRequest(attacker))
            {
                SetEntData(victim, g_iHealth, health + dhealth, 4, true);
            }
        }
    }

    return Plugin_Continue;
}