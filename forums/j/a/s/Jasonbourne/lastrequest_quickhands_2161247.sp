#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <hosties>
#include <lastrequest>

#define PLUGIN_VERSION "1.0.1"

new g_LREntryNum;
new LR_Player_Prisoner = -1;
new LR_Player_Guard = -1;
new String:g_sLR_Name[64];
new Handle:g_hVersion = INVALID_HANDLE;
new LastWeaponHolder = -1;
new Handle: SpriteTimer = INVALID_HANDLE;
new Handle: LoserSpriteTimer = INVALID_HANDLE;
new Handle: DistanceTimer = INVALID_HANDLE;
new Float:BeamCenter[3];
new Float:RingCenter[3];
new Float:start_radius = 220.1;
new Float:end_radius = 220.0;
new Float:life = 0.1;
new Float:width = 5.0;
new spriteCounter;
new g_Sprite;
new offseta = 0;
new SafeZone = 130;
new Float:PlayerLocation[3];
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


public Plugin:myinfo =
{
    name = "Last Request: Quick Hands",
    author = "Jason Bourne & Kolapsicle",
    description = "Pass off the AK before it explodes",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=243340"
};


public OnPluginStart()
{
    LoadTranslations("quickhands.phrases");

    Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "LR Name", LANG_SERVER);

    g_hVersion = CreateConVar("sm_quickhands_version", PLUGIN_VERSION, "Current Quick Hands version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    SetConVarString(g_hVersion, PLUGIN_VERSION);
}


public OnMapStart()
{
    g_Sprite = PrecacheModel("materials/sprites/laser.vmt");
}


public OnConfigsExecuted()
{
    static bool:bAddedCustomLR = false;
    if ( ! bAddedCustomLR)
    {
        g_LREntryNum = AddLastRequestToList(QuickHands_Start, QuickHands_Stop, g_sLR_Name);
        bAddedCustomLR = true;
    }
}


public OnPluginEnd()
{
    RemoveLastRequestFromList(QuickHands_Start, QuickHands_Stop, g_sLR_Name);
}


public QuickHands_Start(Handle:LR_Array, iIndexInArray)
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

        LastWeaponHolder = -1;
        SDKHook(LR_Player_Prisoner, SDKHook_WeaponEquip, OnWeaponEquip);
        SDKHook(LR_Player_Guard, SDKHook_WeaponEquip, OnWeaponEquip);

        new ak = GivePlayerItem(LR_Player_Prisoner, "weapon_ak47");
        new m_iPrimaryAmmoType        = GetEntProp(ak, Prop_Send, "m_iPrimaryAmmoType");
        SetEntProp(LR_Player_Prisoner, Prop_Send, "m_iAmmo", 0, _, m_iPrimaryAmmoType);
        SetEntProp(ak, Prop_Send, "m_iClip1", 0);
        SetEntityMoveType(LR_Player_Prisoner, MOVETYPE_NONE);
        SetEntityMoveType(LR_Player_Guard, MOVETYPE_NONE);
        CreateTimer(1.0, Unfreeze, LR_Player_Prisoner);
        CreateTimer(1.0, Unfreeze, LR_Player_Guard);
        GetClientAbsOrigin(LR_Player_Prisoner, BeamCenter);
        TeleportEntity(LR_Player_Guard, BeamCenter, NULL_VECTOR, NULL_VECTOR);

        SpriteTimer = CreateTimer(0.1, Timer_DrawSprite, _, TIMER_REPEAT);
        DistanceTimer = CreateTimer(0.1, Timer_CheckDistance, _, TIMER_REPEAT);

        CreateTimer(GetURandomFloat() * 60.0, End_LR);

        PrintToChatAll(CHAT_BANNER, "LR Start", LR_Player_Prisoner, LR_Player_Guard);
        PrintToChatAll(CHAT_BANNER, "LR Explain");
    }
}

 
public Action:Unfreeze(Handle:timer, any:client)
{
    SetEntityMoveType(client, MOVETYPE_WALK);
}


public Action:End_LR(Handle:timer)
{
    if (LR_Player_Prisoner != -1)
    {
        new winner, loser;
        if (LastWeaponHolder == LR_Player_Prisoner)
        {
            winner = LR_Player_Guard;
        }
        else if (LastWeaponHolder == LR_Player_Guard)
        {
            winner = LR_Player_Prisoner;
        }

        loser = LastWeaponHolder;

        GetClientAbsOrigin(winner, PlayerLocation);
        SetEntityHealth(winner, 100);
        GivePlayerItem(winner, "weapon_knife");
        LoserSpriteTimer = CreateTimer(0.1, Timer_DrawLoserSprite, _, TIMER_REPEAT);


        SetEntityMoveType(loser, MOVETYPE_NONE);
        StripAllWeapons(loser);
        TeleportEntity(loser, BeamCenter, NULL_VECTOR, NULL_VECTOR);
        SetEntityHealth(loser, 1);

        PrintToChatAll(CHAT_BANNER, "LR Winner", winner);

        LR_Player_Prisoner = -1;
        LR_Player_Guard = -1;
    }
}


public Action:Timer_DrawLoserSprite(Handle:timer)
{
    for (new i = 0; i < 7; i++)
    {
        BeamCenter[2] += 10;
        TE_SetupBeamRingPoint(BeamCenter, 100.0, 100.1, g_Sprite, 0, 0, 25, life, width, 0.0, colours[0], 1, 0);
        TE_SendToAll();
    }

    BeamCenter[2] -= 70;
}


public Action:OnWeaponEquip(client, weapon)
{
   LastWeaponHolder = client;
}


public Action:Timer_CheckDistance(Handle:timer)
{
    if (LR_Player_Prisoner != -1)
    {
        new Float:distance;
        new Float:guardLocation[3];
        new Float:prisonerLocation[3];

        GetClientAbsOrigin(LR_Player_Guard, guardLocation);
        distance = SquareRoot(Pow((guardLocation[0] - BeamCenter[0]), 2.0) + Pow((guardLocation[1] - BeamCenter[1]), 2.0));
        if (distance > SafeZone)
        {
            PrintToChatAll(CHAT_BANNER, "LR Boundary", LR_Player_Guard);
            ForcePlayerSuicide(LR_Player_Guard);
        }
        else
        {
            GetClientAbsOrigin(LR_Player_Prisoner, prisonerLocation);
            distance = SquareRoot(Pow((prisonerLocation[0] - BeamCenter[0]), 2.0) + Pow((prisonerLocation[1] - BeamCenter[1]), 2.0));
            if (distance > SafeZone)
            {
                PrintToChatAll(CHAT_BANNER, "LR Boundary", LR_Player_Prisoner);
                ForcePlayerSuicide(LR_Player_Prisoner);
            }
        }
    }

    return Plugin_Continue;
}


public Action:Timer_DrawSprite(Handle:timer)
{
    spriteCounter++;
    BeamCenter[2] += 10;

    TE_SetupBeamRingPoint(BeamCenter, start_radius, end_radius, g_Sprite, 0, 0, 25, life, width, 0.0, colours[0], 1, 0);
    TE_SendToAll();

    TE_SetupBeamRingPoint(BeamCenter, start_radius + 70, end_radius + 70, g_Sprite, 0, 0, 25, life, width, 0.0, colours[0], 1, 0);
    TE_SendToAll();

    BeamCenter[2] -= 10;

    new Float:a[3];
    new Float:b[3];
    new Float:c[3];
    new Float:d[3];
    new Float:e[3];
    new Float:f[3];
    offseta += 10;
    new radius = 18;
    new Float:ring_radius = 127.5;
    for (new i = 0; i < 8; i++)
    {
        RingCenter[0] = BeamCenter[0] + ring_radius * Cosine(DegToRad(offseta + i * 45.0));
        RingCenter[1] = BeamCenter[1] + ring_radius * Sine(DegToRad(offseta + i * 45.0));
        RingCenter[2] = BeamCenter[2];

        a[2] = RingCenter[2] + 10;
        b[2] = RingCenter[2] + 10;
        c[2] = RingCenter[2] + 10;
        d[2] = RingCenter[2] + 10;
        e[2] = RingCenter[2] + 10;
        f[2] = RingCenter[2] + 10;

        a[0] = RingCenter[0] + radius * Cosine(DegToRad(90.0));
        a[1] = RingCenter[1] + radius * Sine(DegToRad(90.0));

        b[0] = RingCenter[0] + radius * Cosine(DegToRad(210.0));
        b[1] = RingCenter[1] + radius * Sine(DegToRad(210.0));

        c[0] = RingCenter[0] + radius * Cosine(DegToRad(330.0));
        c[1] = RingCenter[1] + radius * Sine(DegToRad(330.0));

        d[0] = RingCenter[0] + radius * Cosine(DegToRad(270.0));
        d[1] = RingCenter[1] + radius * Sine(DegToRad(270.0));

        e[0] = RingCenter[0] + radius * Cosine(DegToRad(30.0));
        e[1] = RingCenter[1] + radius * Sine(DegToRad(30.0));

        f[0] = RingCenter[0] + radius * Cosine(DegToRad(150.0));
        f[1] = RingCenter[1] + radius * Sine(DegToRad(150.0));

        TE_SetupBeamPoints(a, b, g_Sprite, 0, 0, 25, life,
                    width, width, 0, 0.0, colours[4], 0);
        TE_SendToAll();
        TE_SetupBeamPoints(c, b, g_Sprite, 0, 0, 25, life,
                    width, width, 0, 0.0, colours[4], 0);
        TE_SendToAll();
        TE_SetupBeamPoints(a, c, g_Sprite, 0, 0, 25, life,
                    width, width, 0, 0.0, colours[4], 0);
        TE_SendToAll();
        TE_SetupBeamPoints(d, e, g_Sprite, 0, 0, 25, life,
                    width, width, 0, 0.0, colours[4], 0);
        TE_SendToAll();
        TE_SetupBeamPoints(d, f, g_Sprite, 0, 0, 25, life,
                    width, width, 0, 0.0, colours[4], 0);
        TE_SendToAll();
        TE_SetupBeamPoints(e, f, g_Sprite, 0, 0, 25, life,
                    width, width, 0, 0.0, colours[4], 0);
        TE_SendToAll();
    }
}


public QuickHands_Stop(This_LR_Type, Player_Prisoner, Player_Guard)
{
    if (This_LR_Type == g_LREntryNum)
    {
        SDKUnhook(Player_Prisoner, SDKHook_WeaponEquip, OnWeaponEquip);
        SDKUnhook(Player_Guard, SDKHook_WeaponEquip, OnWeaponEquip);

        if (SpriteTimer != INVALID_HANDLE)
        {
            KillTimer(SpriteTimer);
            SpriteTimer = INVALID_HANDLE;
        }
        if (LoserSpriteTimer != INVALID_HANDLE)
        {
            KillTimer(LoserSpriteTimer);
            LoserSpriteTimer = INVALID_HANDLE;
        }
        if (DistanceTimer != INVALID_HANDLE)
        {
            KillTimer(DistanceTimer);
            DistanceTimer = INVALID_HANDLE;
        }

        if (IsClientInGame(Player_Guard))
        {
            if (IsPlayerAlive(Player_Guard))
            {
                GivePlayerItem(Player_Guard, "weapon_knife");
            }
        }

        if (IsClientInGame(Player_Prisoner))
        {
            if (IsPlayerAlive(Player_Prisoner))
            {
                GivePlayerItem(Player_Prisoner, "weapon_knife");
            }
        }

        if (IsClientInGame(Player_Prisoner) && IsClientInGame(Player_Guard))
        {
            if (IsPlayerAlive(Player_Prisoner) && IsPlayerAlive(Player_Guard))
            {
                PrintToChatAll(CHAT_BANNER, "LR Abort");
            }
        }

        LR_Player_Prisoner = -1;
        LR_Player_Guard = -1;
    }
}
