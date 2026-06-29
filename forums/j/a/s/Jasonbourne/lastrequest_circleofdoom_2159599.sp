#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <hosties>
#include <lastrequest>
#include <cstrike>
#include <smlib>

#define COD_VERSION "1.0.2"
#define PREPARE_TIME 3.0

new g_LREntryNum;
new LR_Player_Prisoner = -1;
new LR_Player_Guard = -1;
new String:g_sLR_Name[64];
new Handle:g_hVersion = INVALID_HANDLE;
new Handle: SpriteTimer = INVALID_HANDLE;
new Handle: DistanceTimer = INVALID_HANDLE;
new Float:BeamCenter[3];
new Float:RingCenter[3];
new Float:start_radius = 220.1;
new Float:end_radius = 220.0;
new Float:g_fLife = 0.1;
new Float:g_fWidth = 5.0;
new spriteCounter;
new g_Sprite;
new offseta = 0;
new SafeZone = 130;
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
    name = "Last Request: Circle of Doom",
    author = "Jason Bourne & Kolapsicle",
    description = "Circle of Doom Custom LR for SM Hosties Mod",
    version = COD_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=243126"
};


public OnPluginStart()
{
    LoadTranslations("circleofdoom.phrases");

    Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "LR Name", LANG_SERVER);

    g_hVersion = CreateConVar("sm_circleofdoom_version", COD_VERSION, "Current Circle of Doom version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    SetConVarString(g_hVersion, COD_VERSION);
}


public OnMapStart()
{
	if(GetEngineVersion() == Engine_CSS)
	{
		g_Sprite = PrecacheModel("materials/sprites/laser.vmt");
	}
	else if(GetEngineVersion() == Engine_CSGO)
	{
		g_Sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	}
}


public OnConfigsExecuted()
{
    static bool:bAddedCustomLR = false;
    if ( ! bAddedCustomLR)
    {
        g_LREntryNum = AddLastRequestToList(CircleOfDoom_Start, CircleOfDoom_Stop, g_sLR_Name);
        bAddedCustomLR = true;
    }
}


public OnPluginEnd()
{
    RemoveLastRequestFromList(CircleOfDoom_Start, CircleOfDoom_Stop, g_sLR_Name);
}


public CircleOfDoom_Start(Handle:LR_Array, iIndexInArray)
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

        SDKHook(LR_Player_Prisoner, SDKHook_OnTakeDamage, OnTakeDamage);
        SDKHook(LR_Player_Guard, SDKHook_OnTakeDamage, OnTakeDamage);

        SetEntityMoveType(LR_Player_Prisoner, MOVETYPE_NONE);
        SetEntityMoveType(LR_Player_Guard, MOVETYPE_NONE);

        GivePlayerItem(LR_Player_Prisoner, "weapon_knife", CS_SLOT_KNIFE);
        GivePlayerItem(LR_Player_Guard, "weapon_knife", CS_SLOT_KNIFE);

        GetClientAbsOrigin(LR_Player_Prisoner, BeamCenter);
        TeleportEntity(LR_Player_Guard, BeamCenter, NULL_VECTOR, NULL_VECTOR);

        SpriteTimer = CreateTimer(0.1, Timer_DrawSprite, _, TIMER_REPEAT);
        DistanceTimer = CreateTimer(0.1, Timer_CheckDistance, _, TIMER_REPEAT);
        CreateTimer(PREPARE_TIME, Timer_Unfreeze);

        PrintToChatAll(CHAT_BANNER, "LR Freeze");
        PrintToChatAll(CHAT_BANNER, "LR Start", LR_Player_Prisoner, LR_Player_Guard);
        PrintToChatAll(CHAT_BANNER, "LR Explain");
    }
}


public Action:Timer_Unfreeze(Handle:timer)
{
	SetEntityMoveType(LR_Player_Prisoner, MOVETYPE_WALK);
	SetEntityMoveType(LR_Player_Guard, MOVETYPE_WALK);
	PrintToChatAll(CHAT_BANNER, "LR Go");
	return Plugin_Stop;
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
            PrintToChatAll(CHAT_BANNER, "LR Winner", LR_Player_Prisoner);
            ForcePlayerSuicide(LR_Player_Guard);
        }
        else
        {
            GetClientAbsOrigin(LR_Player_Prisoner, prisonerLocation);
            distance = SquareRoot(Pow((prisonerLocation[0] - BeamCenter[0]), 2.0) + Pow((prisonerLocation[1] - BeamCenter[1]), 2.0));
            if (distance > SafeZone)
            {
                PrintToChatAll(CHAT_BANNER, "LR Winner", LR_Player_Guard);
                ForcePlayerSuicide(LR_Player_Prisoner);
            }
        }
    }

    return Plugin_Continue;
}

public Action:Timer_DrawSprite(Handle:timer)
{
    spriteCounter++;

    for (new i = 0; i < 7; i++)
    {
        BeamCenter[2] += 10;
        if (i == 0)
        {
            TE_SetupBeamRingPoint(BeamCenter, start_radius, end_radius, g_Sprite, 0, 0, 25, g_fLife, g_fWidth, 0.0, colours[0], 1, 0);
            TE_SendToAll();
        }
        TE_SetupBeamRingPoint(BeamCenter, start_radius + 70, end_radius + 70, g_Sprite, 0, 0, 25, g_fLife, g_fWidth, 0.0, colours[0], 1, 0);
        TE_SendToAll();
    }

    BeamCenter[2] -= 70;

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

        TE_SetupBeamPoints(a, b, g_Sprite, 0, 0, 25, g_fLife,
                    g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
        TE_SendToAll();
        TE_SetupBeamPoints(c, b, g_Sprite, 0, 0, 25, g_fLife,
                    g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
        TE_SendToAll();
        TE_SetupBeamPoints(a, c, g_Sprite, 0, 0, 25, g_fLife,
                    g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
        TE_SendToAll();
        TE_SetupBeamPoints(d, e, g_Sprite, 0, 0, 25, g_fLife,
                    g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
        TE_SendToAll();
        TE_SetupBeamPoints(d, f, g_Sprite, 0, 0, 25, g_fLife,
                    g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
        TE_SendToAll();
        TE_SetupBeamPoints(e, f, g_Sprite, 0, 0, 25, g_fLife,
                    g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
        TE_SendToAll();
    }
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
    if (attacker == LR_Player_Guard || attacker == LR_Player_Prisoner)
    {
        SlapPlayer(victim, 0, true);
    }
    return Plugin_Handled;
}

public CircleOfDoom_Stop(This_LR_Type, Player_Prisoner, Player_Guard)
{
    if (This_LR_Type == g_LREntryNum)
    {
        SDKUnhook(Player_Prisoner, SDKHook_OnTakeDamage, OnTakeDamage);
        SDKUnhook(Player_Guard, SDKHook_OnTakeDamage, OnTakeDamage);

        if (SpriteTimer != INVALID_HANDLE)
        {
            KillTimer(SpriteTimer);
            SpriteTimer = INVALID_HANDLE;
        }

        if (DistanceTimer != INVALID_HANDLE)
        {
            KillTimer(DistanceTimer);
            DistanceTimer = INVALID_HANDLE;
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
