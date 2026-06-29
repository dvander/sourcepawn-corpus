#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hosties>
#include <lastrequest>

#define PLUGIN_VERSION "1.0.3"
#define SERVER 0
#define PRISONER 0
#define GUARD 1

new g_LREntryNum;
new Handle:LR_Information = INVALID_HANDLE;
new IndexInArray;
new String:g_sLR_Name[64];
new Handle:g_hLRTime = INVALID_HANDLE;
new Handle:g_hVersion = INVALID_HANDLE;
new bool:LR_Status = false;
new g_iHealth;
new dmg[2];
new g_Sprite;
new colours[7][4] =
{
    {255, 0, 0, 255},
    {255, 127, 0, 255},
    {255, 255, 0, 255},
    {0, 255, 0, 255},
    {0, 0, 255, 255},
    {75, 0, 130, 255},
    {143, 0, 255, 255}
};
new Handle:SpriteTimer;
new Float:BeamCenter[3];

public Plugin:myinfo =
{
    name = "Last Request: Max Damage",
    author = "Jason Bourne & Kolapsicle",
    description = "Deal the maximum amount of damage to yourself within the time limit to win this LR.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2159214"
};

public OnPluginStart()
{
    LoadTranslations("maxdmg.phrases");

    Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "LR Name", LANG_SERVER);

    HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Pre);

    g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");

    if (g_iHealth == -1)
    {
        SetFailState("Error - Unable to get offset for CSSPlayer::m_iHealth");
    }

    LR_Information = CreateArray(10);

    g_hLRTime = CreateConVar("sm_maxdmg_lrtime", "30.0", "How long (in seconds) should this LR last for?", _, true, 10.0, true, 60.0);
    AutoExecConfig(true, "LR_maxdamage", "sourcemod");

    /** Version cvar **/
    g_hVersion = CreateConVar("sm_maxdmg_version", PLUGIN_VERSION, "Current Max Damage version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    SetConVarString(g_hVersion, PLUGIN_VERSION);
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

public OnMapStart()
{
    g_Sprite = PrecacheModel("materials/sprites/laser.vmt");
}

public LR_Start(Handle:LR_Array, iIndexInArray)
{
    LR_Status = true;
    // keep a local copy of LR array
    LR_Information = LR_Array;
    IndexInArray = iIndexInArray;

    new This_LR_Type = GetArrayCell(LR_Information, IndexInArray, _:Block_LRType);
    if (This_LR_Type == g_LREntryNum)
    {
        new LR_Player_Prisoner = GetArrayCell(LR_Information, IndexInArray, _:Block_Prisoner);
        new LR_Player_Guard = GetArrayCell(LR_Information, IndexInArray, _:Block_Guard);

        // check datapack value
        new LR_Pack_Value = GetArrayCell(LR_Information, IndexInArray, _:Block_Global1);
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

        dmg[PRISONER] = 0;
        dmg[GUARD] = 0;

        CreateTimer(GetConVarFloat(g_hLRTime), Timer_LR);

        PrintToChatAll(CHAT_BANNER, "LR Start", LR_Player_Prisoner, LR_Player_Guard);
        PrintToChatAll(CHAT_BANNER, "LR Explain", GetConVarFloat(g_hLRTime));
    }
}

public Action:Timer_LR(Handle:timer)
{
    new This_LR_Type = GetArrayCell(LR_Information, IndexInArray, _:Block_LRType);
    if (This_LR_Type == g_LREntryNum)
    {
        new LR_Player_Prisoner = GetArrayCell(LR_Information, IndexInArray, _:Block_Prisoner);
        new LR_Player_Guard = GetArrayCell(LR_Information, IndexInArray, _:Block_Guard);
        new loser, winner;

        if (dmg[PRISONER] == dmg[GUARD])
        {
            SetEntityHealth(LR_Player_Prisoner, 100);
            SetEntityHealth(LR_Player_Guard, 100);

            GivePlayerItem(LR_Player_Prisoner, "weapon_knife");
            GivePlayerItem(LR_Player_Guard, "weapon_knife");

            PrintToChatAll(CHAT_BANNER, "LR No Winner", dmg[GUARD]);
            ServerCommand("sm_cancellr");
        } else
        {
            if (dmg[PRISONER] > dmg[GUARD])
            {
                winner = LR_Player_Prisoner;
                loser = LR_Player_Guard;
            } else if(dmg[GUARD] > dmg[PRISONER])
            {
                winner = LR_Player_Guard;
                loser = LR_Player_Prisoner;
            }

            GetClientAbsOrigin(winner, BeamCenter);
            SetEntityHealth(winner, 100);
            GivePlayerItem(winner, "weapon_knife");

            SetEntityMoveType(loser, MOVETYPE_NONE);
            StripAllWeapons(loser);
            TeleportEntity(loser, BeamCenter, NULL_VECTOR, NULL_VECTOR);
            SetEntityHealth(loser, 1);

            CreateTimer(0.1, Timer_CreateSprite);
            SpriteTimer = CreateTimer(3.0, Timer_CreateSprite, _, TIMER_REPEAT);

            PrintToChatAll(CHAT_BANNER, "LR Winner", winner);
        }
    }
    return Plugin_Continue;
}

public Action:Timer_CreateSprite(Handle:timer)
{
    new Float:height = BeamCenter[2];

    for (new i = 0; i < 7; i++)
    {
        BeamCenter[2] += 10;
        TE_SetupBeamRingPoint(BeamCenter, 100.1, 100.0, g_Sprite, 0, 0, 25, 3.0, 7.0, 0.0, colours[i], 1, 0);
        TE_SendToAll();
    }

    BeamCenter[2] = height;
}

public LR_Stop(This_LR_Type, Player_Prisoner, Player_Guard)
{
    LR_Status = false;
    
    if (This_LR_Type == g_LREntryNum)
    {
        if (SpriteTimer != INVALID_HANDLE)
        {
            KillTimer(SpriteTimer);
            SpriteTimer = INVALID_HANDLE;
        }

        LR_Information = INVALID_HANDLE;
    }
}

public Action:EventPlayerHurt(Handle:event, const String:name[],bool:dontBroadcast)
{
    if (LR_Status)
    {
        new This_LR_Type = GetArrayCell(LR_Information, IndexInArray, _:Block_LRType);
        if (This_LR_Type == g_LREntryNum)
        {
            new LR_Player_Prisoner = GetArrayCell(LR_Information, IndexInArray, _:Block_Prisoner);
            new LR_Player_Guard = GetArrayCell(LR_Information, IndexInArray, _:Block_Guard);
            new victim = GetClientOfUserId(GetEventInt(event, "userid"));
            new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
            new dhealth = GetEventInt(event, "dmg_health");

            if (IsClientInLastRequest(victim))
            {
                decl String:wname[64];
                GetEventString(event, "weapon", wname, sizeof(wname));

                if (victim == attacker || attacker == SERVER)
                {
                    if (victim == LR_Player_Guard)
                    {
                        dmg[GUARD] += dhealth;
                    } else if (victim == LR_Player_Prisoner)
                    {
                        dmg[PRISONER] += dhealth;
                    }
                }
                if (GetEntityMoveType(victim) != MOVETYPE_NONE)
                {
                    SetEntData(victim, g_iHealth, 100, 4, true);
                }
            }
        }
    }
    
    return Plugin_Continue;
}
