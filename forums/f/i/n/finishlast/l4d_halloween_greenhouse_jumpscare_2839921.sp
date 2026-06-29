// ====================================================================================================
// Plugin Info
// ====================================================================================================
#define PLUGIN_NAME        "[L4D1/2] Halloween Greenhouse Jumpscare"
#define PLUGIN_AUTHOR      "Finishlast"
#define PLUGIN_DESCRIPTION "Little jumpscare for Dead Air Greenhouse map"
#define PLUGIN_VERSION     "1.0.0"
#define PLUGIN_URL         "https://forums.alliedmods.net/showthread.php?t=2839921"

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes & Pragmas
// ====================================================================================================
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_sound>

// ====================================================================================================
// Defines
// ====================================================================================================
#define PARTICLE_FIRE "fire_large_01"
#define BLOCK_MODEL "models/props_furniture/picture_frame4.mdl"
#define PLATE_MODEL "models/props_street/traffic_plate_01.mdl"
#define NUM_BLOCKS 30
#define MAX_PLAYERS 65

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int ent_plate_trigger;
int ent_dynamic_blocks[NUM_BLOCKS];

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public void OnPluginStart()
{
    HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
}

// ====================================================================================================
// event_round_freeze_end
// ====================================================================================================
public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
    char sMap[64];
    GetCurrentMap(sMap, sizeof(sMap));
    if (!StrEqual(sMap, "l4d_airport01_greenhouse", false) && !StrEqual(sMap, "l4d_vs_airport01_greenhouse", false) && !StrEqual(sMap, "c11m1_greenhouse", false))
        return;

    PrecacheSound("animation/van_inside_hit_wall.wav");
    PrecacheSound("ambient/creatures/town_scared_sob2.wav");
    PrecacheSound("ambient/levels/caves/dist_growl1.wav");
    PrecacheSound("ambient/creatures/town_scared_sob1.wav");

    PrecacheModel(PLATE_MODEL);
    PrecacheModel(BLOCK_MODEL);

    float pos[3];
    float ang[3];

    pos[0] = 4105.0;
    pos[1] = 693.0;
    pos[2] = 529.0;

    ang[0] = 0.0;
    ang[1] = 90.0;
    ang[2] = 0.0;

    ent_plate_trigger = CreateEntityByName("prop_dynamic");
    DispatchKeyValue(ent_plate_trigger, "model", PLATE_MODEL);
    DispatchKeyValue(ent_plate_trigger, "solid", "6");
    DispatchKeyValue(ent_plate_trigger, "disableshadows", "1");
    DispatchKeyValue(ent_plate_trigger, "disablereceiveshadows", "1");
    DispatchKeyValue(ent_plate_trigger, "rendermode", "10"); //
    DispatchKeyValue(ent_plate_trigger, "renderamt", "0");    
    DispatchSpawn(ent_plate_trigger);
    TeleportEntity(ent_plate_trigger, pos, ang, NULL_VECTOR);
    SDKHook(ent_plate_trigger, SDKHook_Touch, OnTouch);
}

// ====================================================================================================
// OnTouch
// ====================================================================================================
public void OnTouch(int client, int other)
{
    if (other <= 0 || other > MaxClients || !IsClientInGame(other) || IsFakeClient(other) || GetClientTeam(other) != 2)
        return;

    CreateTimer(1.0, scare);
    CreateTimer(3.0, scare2);
    CreateTimer(5.0, scare3);
    SDKUnhook(ent_plate_trigger, SDKHook_Touch, OnTouch);
}

// ====================================================================================================
// The scare parts
// ====================================================================================================
public Action scare(Handle timer)
{
    for (int i = 0; i < 6; i++)
    {
        Command_Play("ambient/levels/caves/dist_growl1.wav");
    }
    for (int i = 0; i < 4; i++)
    {
        Command_Play("ambient/creatures/town_scared_sob1.wav");
    }

    float ang[3];
    ang[0] = 0.0;
    ang[1] = 0.0;
    ang[2] = 0.0;

    float baseX = 3889.0;
    float baseY = 651.0;
    float baseZ = 541.0;

    for (int i = 0; i < NUM_BLOCKS; i++)
    {
        int row = i / 6;
        int col = i % 6;

        float pos[3];
        pos[0] = baseX;
        pos[1] = baseY + float(col) * 18.0;
        pos[2] = baseZ + float(row) * 26.0;

        ent_dynamic_blocks[i] = CreateEntityByName("prop_dynamic_override");
        DispatchKeyValue(ent_dynamic_blocks[i], "model", BLOCK_MODEL);
        DispatchKeyValue(ent_dynamic_blocks[i], "disableshadows", "1");
        DispatchKeyValue(ent_dynamic_blocks[i], "solid", "6");
        DispatchSpawn(ent_dynamic_blocks[i]);
        TeleportEntity(ent_dynamic_blocks[i], pos, ang, NULL_VECTOR);
    }

    return Plugin_Continue;
}

public Action scare2(Handle timer)
{
    for (int i = 0; i < 4; i++)
    {
        Command_Play("ambient/creatures/town_scared_sob2.wav");
    }

    float ang[3];
    ang[0] = 0.0;
    ang[1] = 0.0;
    ang[2] = 0.0;

    for (int i = 0; i < 4; i++)
    {
        float pos[3];
        pos[0] = 3900.0 + float(i) * 100.0;
        pos[1] = 690.0;
        pos[2] = 550.0;

        int entity = CreateEntityByName("info_particle_system");
        if (entity != -1)
        {
            DispatchKeyValue(entity, "effect_name", PARTICLE_FIRE);
            DispatchSpawn(entity);
            ActivateEntity(entity);
            AcceptEntityInput(entity, "start");
            TeleportEntity(entity, pos, ang, NULL_VECTOR);
            SetVariantString("OnUser1 !self:Kill::2:-1");
            AcceptEntityInput(entity, "AddOutput");
            AcceptEntityInput(entity, "FireUser1");
        }
    }

    return Plugin_Continue;
}

public Action scare3(Handle timer)
{
    Command_Play("animation/van_inside_hit_wall.wav");

    for (int i = 0; i < 4; i++)
    {
          Command_Play("ambient/creatures/town_scared_sob1.wav");
    }

    float ang[3];
    ang[0] = 0.0;
    ang[1] = 0.0;
    ang[2] = 0.0;

    for (int i = 0; i < 4; i++)
    {
        float pos[3];
        pos[0] = 3900.0 + float(i) * 100.0;
        pos[1] = 690.0;
        pos[2] = 642.0;

        int entity = CreateEntityByName("info_particle_system");
        if (entity != -1)
        {
            DispatchKeyValue(entity, "effect_name", PARTICLE_FIRE);
            DispatchSpawn(entity);
            ActivateEntity(entity);
            AcceptEntityInput(entity, "start");
            TeleportEntity(entity, pos, ang, NULL_VECTOR);
            SetVariantString("OnUser1 !self:Kill::2:-1");
            AcceptEntityInput(entity, "AddOutput");
            AcceptEntityInput(entity, "FireUser1");
        }
    }

    for (int i = 0; i < NUM_BLOCKS; i++)
    {
        if (ent_dynamic_blocks[i] != -1)
        {
            AcceptEntityInput(ent_dynamic_blocks[i], "Kill");
        }
    }

    return Plugin_Continue;
}

// ====================================================================================================
// Play sounds
// ====================================================================================================
public Action Command_Play(const char[] sound)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            ClientCommand(i, "playgamesound %s", sound);
        }
    }
    return Plugin_Handled;
}
