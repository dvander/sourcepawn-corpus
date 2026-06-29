#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

Handle g_timer = INVALID_HANDLE;

int g_entDynamicBlock1 = INVALID_ENT_REFERENCE;
int g_entCraneFrame    = INVALID_ENT_REFERENCE;
int g_entCrane         = INVALID_ENT_REFERENCE;
int g_entCraneWindow   = INVALID_ENT_REFERENCE;

int g_entCable1  = INVALID_ENT_REFERENCE;
int g_entCable2  = INVALID_ENT_REFERENCE;
int g_entCable3  = INVALID_ENT_REFERENCE;
int g_entCable4  = INVALID_ENT_REFERENCE;
int g_entCable5  = INVALID_ENT_REFERENCE;
int g_entCable6  = INVALID_ENT_REFERENCE;
int g_entCable7  = INVALID_ENT_REFERENCE;
int g_entCable8  = INVALID_ENT_REFERENCE;
int g_entCable9  = INVALID_ENT_REFERENCE;
int g_entCable10 = INVALID_ENT_REFERENCE;
int g_entCable11 = INVALID_ENT_REFERENCE;
int g_entCable12 = INVALID_ENT_REFERENCE;
int g_entCable13 = INVALID_ENT_REFERENCE;
int g_entCable14 = INVALID_ENT_REFERENCE;
int g_entCable15 = INVALID_ENT_REFERENCE;
int g_entCable16 = INVALID_ENT_REFERENCE;

int g_entGlowModel      = INVALID_ENT_REFERENCE; // dynamic_prop
int g_entButton         = INVALID_ENT_REFERENCE; // dynamic_prop_button

#define SOUND "ambient/machines/wall_move4.wav"

public void OnPluginStart()
{
    PrecacheModel("models/props_lab/freightelevatorbutton.mdl");
    PrecacheModel("models/props_equipment/cargo_container01.mdl");
    PrecacheModel("models/cranes/crane_frame.mdl");
    PrecacheModel("models/props_industrial/construction_crane.mdl");
    PrecacheModel("models/props_exteriors/lighthouserailing_03_break04.mdl");
    PrecacheModel("models/props_industrial/construction_crane_windows.mdl");

    PrecacheSound(SOUND);

    HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
    HookEvent("round_end",        event_round_end,       EventHookMode_PostNoCopy);
}

void KillEntRef(int &ref)
{
    int ent = EntRefToEntIndex(ref);
    if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
    {
        AcceptEntityInput(ent, "Kill");
    }
    ref = INVALID_ENT_REFERENCE;
}

void CleanupEntities()
{
    KillEntRef(g_entDynamicBlock1);
    KillEntRef(g_entCraneFrame);
    KillEntRef(g_entCrane);
    KillEntRef(g_entCraneWindow);

    KillEntRef(g_entCable1);
    KillEntRef(g_entCable2);
    KillEntRef(g_entCable3);
    KillEntRef(g_entCable4);
    KillEntRef(g_entCable5);
    KillEntRef(g_entCable6);
    KillEntRef(g_entCable7);
    KillEntRef(g_entCable8);
    KillEntRef(g_entCable9);
    KillEntRef(g_entCable10);
    KillEntRef(g_entCable11);
    KillEntRef(g_entCable12);
    KillEntRef(g_entCable13);
    KillEntRef(g_entCable14);
    KillEntRef(g_entCable15);
    KillEntRef(g_entCable16);

    KillEntRef(g_entGlowModel);
    KillEntRef(g_entButton);
}

public void OnMapEnd()
{
    if (g_timer != INVALID_HANDLE)
    {
        CloseHandle(g_timer);
        g_timer = INVALID_HANDLE;
    }
    CleanupEntities();
}

public void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
    if (g_timer != INVALID_HANDLE)
    {
        CloseHandle(g_timer);
        g_timer = INVALID_HANDLE;
    }
    CleanupEntities();
}

public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
    // Safety: clean up any leftovers before spawning new ones
    if (g_timer != INVALID_HANDLE)
    {
        CloseHandle(g_timer);
        g_timer = INVALID_HANDLE;
    }
    CleanupEntities();

    char sMap[64];
    GetCurrentMap(sMap, sizeof(sMap));
    if (!StrEqual(sMap, "l4d_river01_docks", false) && !StrEqual(sMap, "c7m1_docks", false))
    {
        return;
    }

    float pos[3], ang[3], fwd[3];

    pos[0] = 12184.0;
    pos[1] = 37.0;
    pos[2] = 1.0;

    ang[0] = 0.0;
    ang[1] = 0.0;
    ang[2] = 0.0;

    GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(fwd, 100.0);
    AddVectors(fwd, pos, fwd);

    char origin[100];
    Format(origin, sizeof(origin), "%0.1f %0.1f %0.1f", fwd[0], fwd[1], fwd[2]);

    float output[3];
    MakeVectorFromPoints(fwd, pos, output);
    GetVectorAngles(output, ang);
    ang[0] = 0.0;

    char targetname[100];
    int tick = GetGameTickCount();
    Format(targetname, sizeof(targetname), "@glow_%i", tick);

    CreateModel(fwd, ang, origin, targetname);
    CreateButton(fwd, ang, origin, targetname);

    // create doors and box
    pos[0] = 12170.0;
    pos[1] = -80.0;
    pos[2] = -62.0;
    ang[0] = 0.0;
    ang[1] = 90.0;
    ang[2] = 0.0;

    int ent = CreateEntityByName("prop_dynamic");
    if (ent != -1)
    {
        DispatchKeyValue(ent, "model", "models/props_equipment/cargo_container01.mdl");
        DispatchKeyValue(ent, "disableshadows", "1");
        DispatchKeyValue(ent, "solid", "6");
        DispatchSpawn(ent);
        TeleportEntity(ent, pos, ang, NULL_VECTOR);
        SDKHook(ent, SDKHook_Touch, OnTouch);
        g_entDynamicBlock1 = EntIndexToEntRef(ent);
    }

    // cables
    pos[2] = 95.0;
    ang[0] = 90.0;

    int cableEnt;

    cableEnt = CreateCable(pos, ang);
    g_entCable1 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable2 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable3 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable4 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable5 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable6 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable7 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable8 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable9 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable10 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable11 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable12 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable13 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable14 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable15 = EntIndexToEntRef(cableEnt);

    pos[2] += 64.0;
    cableEnt = CreateCable(pos, ang);
    g_entCable16 = EntIndexToEntRef(cableEnt);

    // crane frame
    pos[0] = 12610.0;
    pos[1] = -140.0;
    pos[2] = -362.0;
    ang[0] = 0.0;
    ang[1] = 0.0;
    ang[2] = 0.0;

    ent = CreateEntityByName("prop_dynamic");
    if (ent != -1)
    {
        DispatchKeyValue(ent, "model", "models/cranes/crane_frame.mdl");
        DispatchKeyValue(ent, "disableshadows", "1");
        DispatchKeyValue(ent, "solid", "6");
        DispatchSpawn(ent);
        TeleportEntity(ent, pos, ang, NULL_VECTOR);
        g_entCraneFrame = EntIndexToEntRef(ent);
    }

    pos[2] = 445.0;
    ang[1] = 172.0;
    ent = CreateEntityByName("prop_dynamic");
    if (ent != -1)
    {
        DispatchKeyValue(ent, "model", "models/props_industrial/construction_crane.mdl");
        DispatchKeyValue(ent, "disableshadows", "1");
        DispatchKeyValue(ent, "solid", "6");
        DispatchSpawn(ent);
        TeleportEntity(ent, pos, ang, NULL_VECTOR);
        g_entCrane = EntIndexToEntRef(ent);
    }

    pos[2] = 436.0;
    ang[1] = 172.0;
    ent = CreateEntityByName("prop_dynamic");
    if (ent != -1)
    {
        DispatchKeyValue(ent, "model", "models/props_industrial/construction_crane_windows.mdl");
        DispatchKeyValue(ent, "spawnflags", "264");
        DispatchKeyValue(ent, "disableshadows", "1");
        DispatchKeyValue(ent, "solid", "6");
        DispatchSpawn(ent);
        TeleportEntity(ent, pos, ang, NULL_VECTOR);
        g_entCraneWindow = EntIndexToEntRef(ent);
    }

    int btn = EntRefToEntIndex(g_entButton);
    if (btn != INVALID_ENT_REFERENCE && IsValidEntity(btn))
    {
        HookSingleEntityOutput(btn, "OnPressed", OnPressed);
    }
}

int CreateCable(const float pos[3], const float ang[3])
{
    int ent = CreateEntityByName("prop_dynamic");
    if (ent == -1)
        return -1;

    DispatchKeyValue(ent, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
    DispatchKeyValue(ent, "spawnflags", "264");
    DispatchKeyValue(ent, "disableshadows", "1");
    DispatchSpawn(ent);
    TeleportEntity(ent, pos, ang, NULL_VECTOR);
    return ent;
}

// Create dynamic model (glow)
void CreateModel(const float fwd[3], const float ang[3], const char[] origin, const char[] targetname)
{
    int ent = CreateEntityByName("prop_dynamic");
    if (ent == -1)
        return;

    DispatchKeyValue(ent, "origin", origin);
    DispatchKeyValue(ent, "targetname", targetname);
    DispatchKeyValue(ent, "model", "models/props_lab/freightelevatorbutton.mdl");
    DispatchKeyValue(ent, "spawnflags", "0");
    DispatchSpawn(ent);
    TeleportEntity(ent, fwd, ang, NULL_VECTOR);

    g_entGlowModel = EntIndexToEntRef(ent);
}

void CreateButton(const float fwd[3], const float ang[3], const char[] origin, const char[] targetname)
{
    int ent = CreateEntityByName("func_button");
    if (ent == -1)
        return;

    DispatchKeyValue(ent, "origin", origin);
    DispatchKeyValue(ent, "glow", targetname);
    DispatchKeyValue(ent, "wait", "-1");
    DispatchKeyValue(ent, "spawnflags", "1025");

    DispatchSpawn(ent);
    ActivateEntity(ent);

    TeleportEntity(ent, fwd, ang, NULL_VECTOR);
    SetEntityModel(ent, "models/props_lab/freightelevatorbutton.mdl");

    float vMins[3] = { -30.0, -30.0, 0.0 }, vMaxs[3] = { 30.0, 30.0, 200.0 };
    SetEntPropVector(ent, Prop_Send, "m_vecMins", vMins);
    SetEntPropVector(ent, Prop_Send, "m_vecMaxs", vMaxs);

    int enteffects = GetEntProp(ent, Prop_Send, "m_fEffects");
    enteffects |= 32;
    SetEntProp(ent, Prop_Send, "m_fEffects", enteffects);

    g_entButton = EntIndexToEntRef(ent);
}

public void OnPressed(const char[] output, int caller, int activator, float delay)
{
    int btn = EntRefToEntIndex(g_entButton);
    if (btn != INVALID_ENT_REFERENCE && IsValidEntity(btn))
    {
        AcceptEntityInput(btn, "Kill"); // prevent double-trigger
        g_entButton = INVALID_ENT_REFERENCE;
    }

    int block = EntRefToEntIndex(g_entDynamicBlock1);
    if (block != INVALID_ENT_REFERENCE && IsValidEntity(block))
    {
        EmitSoundToAll(SOUND, block);
    }

    char command[] = "director_force_panic_event";
    int flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(activator, command);
    SetCommandFlags(command, flags);

    int glow = EntRefToEntIndex(g_entGlowModel);
    if (glow != INVALID_ENT_REFERENCE && IsValidEntity(glow))
    {
        // Remove glow entity from func_button
        SetEntProp(btn, Prop_Send, "m_glowEntity", -1);
    }

    if (g_timer != INVALID_HANDLE)
    {
        CloseHandle(g_timer);
        g_timer = INVALID_HANDLE;
    }
    g_timer = CreateTimer(0.1, gate, _, TIMER_REPEAT);
}

public Action gate(Handle timer)
{
    static int numlift = 0;
    static int numsound = 0;

    int block = EntRefToEntIndex(g_entDynamicBlock1);
    if (block == INVALID_ENT_REFERENCE || !IsValidEntity(block))
    {
        numlift = 0;
        numsound = 0;
        g_timer = INVALID_HANDLE;
        return Plugin_Stop;
    }

    float pos[3], ang[3], dir[3];
    GetEntPropVector(block, Prop_Data, "m_vecAbsOrigin", pos);
    GetEntPropVector(block, Prop_Send, "m_angRotation", ang);
    pos[2] += 0.3;
    dir[0] = dir[1] = dir[2] = 0.0;

    if (numlift >= 340)
    {
        numlift = 0;
        SetConVarInt(FindConVar("sb_unstick"), 1);
        g_timer = INVALID_HANDLE;
        return Plugin_Stop;
    }

    TeleportEntity(block, pos, ang, dir);

    numlift++;
    numsound++;

    if (numsound == 23)
    {
        EmitSoundToAll(SOUND, block);
        numsound = 0;
    }
    return Plugin_Continue;
}

public void OnTouch(int entity, int other)
{
    if (other > 0 && other <= MaxClients)
    {
        if (IsClientInGame(other) && IsFakeClient(other) && GetClientTeam(other) == 2)
        {
            SetConVarInt(FindConVar("sb_unstick"), 0);
            int block = EntRefToEntIndex(g_entDynamicBlock1);
            if (block != INVALID_ENT_REFERENCE && IsValidEntity(block))
            {
                SDKUnhook(block, SDKHook_Touch, OnTouch);
            }
        }
    }
}
