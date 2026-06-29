/**
 *
 * Port of the VScript mod "Survivor Fainting" to SourceMod.
 * Spawns a prop_ragdoll at the survivor's position and translates
 * WASD/Jump inputs into physics impulses on the ragdoll.
 *
 * Commands:
 *   sm_faint            - Toggle faint ragdoll on yourself
 *   sm_faintplayer      - (Admin) Toggle faint on another player/bot
 *
 * CVars:
 *   l4d2_faint_impulse_interval  - Min interval between movement impulses (default: 0.06s)
 *   l4d2_faint_admins_only       - Restrict sm_faint to admins (0/1)
 *   l4d2_faint_require_grounded  - Require player to be on ground to faint (0/1)
 *   l4d2_faint_fall_damage       - Remove faint when ragdoll falls far enough to cause damage (0/1)
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

Handle g_hApplyAbsVelocityImpulse = null;

#define PLUGIN_VERSION  "1.3.0"

// Input flags (L4D2)
#define IN_ATTACK       (1 << 0)
#define IN_JUMP         (1 << 1)
#define IN_FORWARD      (1 << 3)
#define IN_BACK         (1 << 4)
#define IN_MOVELEFT     (1 << 9)
#define IN_MOVERIGHT    (1 << 10)
#define IN_USE          (1 << 5)
#define IN_RELOAD       (1 << 13)

// Collision groups
#define COLLISION_GROUP_DEBRIS          1
#define COLLISION_GROUP_DEBRIS_TRIGGER  2
#define COLLISION_GROUP_PLAYER          5

#define MOVE_FORCE 16.0
#define JUMP_FORCE 325.0

// Trace content masks for clip brushes
#define CONTENTS_PLAYERCLIP  0x10000
#define CONTENTS_MONSTERCLIP 0x20000

// Glow types (L4D2)
enum L4D2GlowType
{
    L4D2Glow_None       = 0,
    L4D2Glow_Constant   = 1,
    L4D2Glow_Occluded   = 2,
    L4D2Glow_Unoccluded = 3,
}

bool g_bIntroActive; // true while campaign intro cinematic is playing

// -----------------------------------------------------------------------
// Per-client globals
// -----------------------------------------------------------------------
int     g_iRagdoll[MAXPLAYERS+1]     = { INVALID_ENT_REFERENCE, ... };
float   g_fCmdDelay[MAXPLAYERS+1];
float   g_fTimeCannotGetUp[MAXPLAYERS+1];
float   g_fJumpCooldown[MAXPLAYERS+1];
float   g_fThinkCooldown[MAXPLAYERS+1];
float   g_fMoveCooldown[MAXPLAYERS+1];
int     g_iWallBounceCount[MAXPLAYERS+1];     // number of wall impulses in current window
float   g_fWallBounceWindowStart[MAXPLAYERS+1]; // when the current bounce window started
float   g_fWallBounceCooldown[MAXPLAYERS+1];  // lockout time after too many bounces
float   g_fThinkRate[MAXPLAYERS+1];   // throttle: think runs at ~30fps
float   g_fLastRagPos[MAXPLAYERS+1][3]; // previous ragdoll position for wall-crossing rollback
bool    g_bRagInAir[MAXPLAYERS+1];        // ragdoll is airborne (set on jump, cleared on landing)
float   g_fRagGroundZ[MAXPLAYERS+1];      // highest Z the ragdoll was on the ground; used for fall height calc
int     g_iWeaponHandEnt[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... }; // active weapon ref saved when faint starts, restored on exit

// -----------------------------------------------------------------------
// CVars
// -----------------------------------------------------------------------
ConVar  g_cvImpulseInterval;
ConVar  g_cvAdminsOnly;
ConVar  g_cvRequireGrounded;
ConVar  g_cvFallDamage;
ConVar  g_cvGravity;

float g_fImpulseInterval;
bool  g_bAdminsOnly;
bool  g_bRequireGrounded;
bool  g_bFallDamage;

// -----------------------------------------------------------------------
// Catches ragdoll destruction by the engine fader — ends faint cleanly
public void OnEntityDestroyed(int entity)
{
    if (entity <= 0) return;

    int ref = EntIndexToEntRef(entity);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_iRagdoll[i] == ref)
        {
            RemoveFaintRagdoll(i);
            return;
        }
    }
}

public Plugin myinfo =
{
    name        = "L4D2 Faint",
    author      = "Ferks-FK, Shadowysn (Workshop MOD)",
    description = "Survivors faint ragdoll.",
    version     = PLUGIN_VERSION,
    url         = "https://forums.alliedmods.net/showthread.php?t=352746"
};

// -----------------------------------------------------------------------
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse,
    float vel[3], float angles[3], int &weapon, int &subtype,
    int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if (g_iRagdoll[client] == INVALID_ENT_REFERENCE) return Plugin_Continue;

    // Block interactions during faint; IN_ATTACK is intentionally kept to allow exiting
    buttons &= ~IN_USE;
    buttons &= ~IN_RELOAD;

    return Plugin_Changed;
}

public void OnPluginStart()
{
    CreateConVar("l4d2_faint_version", PLUGIN_VERSION, "Plugin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvImpulseInterval = CreateConVar("l4d2_faint_impulse_interval", "0.06", "Minimum interval between movement impulses (s). Higher = slower.", FCVAR_NOTIFY, true, 0.01);
    g_cvAdminsOnly      = CreateConVar("l4d2_faint_admins_only",      "0",    "Restrict sm_faint to admins (0/1)",                                 FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvRequireGrounded = CreateConVar("l4d2_faint_require_grounded", "1",    "Require players to be on the ground to faint (0/1).",                FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvFallDamage      = CreateConVar("l4d2_faint_fall_damage",      "1",    "Remove faint when ragdoll falls far enough to cause damage (0/1).", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    AutoExecConfig(true, "l4d2_survivor_faint");

    g_cvImpulseInterval.AddChangeHook(OnCvarChanged);
    g_cvAdminsOnly.AddChangeHook(OnCvarChanged);
    g_cvRequireGrounded.AddChangeHook(OnCvarChanged);
    g_cvFallDamage.AddChangeHook(OnCvarChanged);

    g_cvGravity = FindConVar("sv_gravity");

    RegConsoleCmd("sm_faint",       Cmd_Faint,       "Toggle ragdoll on your own survivor");
    RegAdminCmd  ("sm_faintplayer", Cmd_FaintPlayer, ADMFLAG_GENERIC, "Toggle faint on another player: sm_faintplayer <#userid|name>");

    HookEvent("player_hurt",            Event_PlayerHurt);
    HookEvent("player_death",           Event_PlayerDeath);
    HookEvent("player_disconnect",      Event_PlayerDisconnect);
    HookEvent("player_incapacitated",   Event_PlayerIncap);
    HookEvent("charger_carry_start",    Event_ChargerCarryStart);
    HookEvent("map_transition",         Event_MapTransition);
    HookEvent("gameinstructor_nodraw",  Event_IntroCutsceneBegin, EventHookMode_PostNoCopy);
    HookEvent("gameinstructor_draw",    Event_IntroCutsceneEnd,   EventHookMode_PostNoCopy);

    // ApplyAbsVelocityImpulse — used to push the ragdoll physics object
    GameData hGameData = new GameData("l4d2_survivor_faint");
    if (hGameData != null)
    {
        StartPrepSDKCall(SDKCall_Entity);
        PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ApplyAbsVelocityImpulse");
        PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
        g_hApplyAbsVelocityImpulse = EndPrepSDKCall();
        delete hGameData;
    }
    if (g_hApplyAbsVelocityImpulse == null)
        LogMessage("[Faint] SDKCall not available - movement via SetAbsVelocity");

    GetCvars();
}

void OnCvarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

void GetCvars()
{
    g_fImpulseInterval = g_cvImpulseInterval.FloatValue;
    g_bAdminsOnly      = g_cvAdminsOnly.BoolValue;
    g_bRequireGrounded = g_cvRequireGrounded.BoolValue;
    g_bFallDamage      = g_cvFallDamage.BoolValue;
}

public void OnConfigsExecuted()
{
    GetCvars();
}

public void OnClientDisconnect(int client)
{
    RemoveFaintRagdoll(client);
    // g_iRagdoll is already cleared by RemoveFaintRagdoll
    g_fCmdDelay[client]        = 0.0;
    g_fTimeCannotGetUp[client] = 0.0;
    g_fJumpCooldown[client]    = 0.0;
    g_fThinkCooldown[client]   = 0.0;
    g_fMoveCooldown[client]    = 0.0;
    g_iWallBounceCount[client]      = 0;
    g_fWallBounceWindowStart[client] = 0.0;
    g_fWallBounceCooldown[client]   = 0.0;
    g_fThinkRate[client]            = 0.0;
    g_fLastRagPos[client][0]   = 0.0;
    g_fLastRagPos[client][1]   = 0.0;
    g_fLastRagPos[client][2]   = 0.0;
    g_bRagInAir[client]        = false;
    g_fRagGroundZ[client]      = 0.0;
    g_iWeaponHandEnt[client]   = INVALID_ENT_REFERENCE;
}

public void OnMapStart()
{
    g_bIntroActive = false;

    for (int i = 1; i <= MaxClients; i++)
    {
        g_iRagdoll[i]            = INVALID_ENT_REFERENCE;
        g_fCmdDelay[i]           = 0.0;
        g_fTimeCannotGetUp[i]    = 0.0;
        g_fJumpCooldown[i]       = 0.0;
        g_fThinkCooldown[i]      = 0.0;
        g_fMoveCooldown[i]       = 0.0;
        g_iWallBounceCount[i]       = 0;
        g_fWallBounceWindowStart[i] = 0.0;
        g_fWallBounceCooldown[i]    = 0.0;
        g_fThinkRate[i]             = 0.0;
        g_fLastRagPos[i][0]      = 0.0;
        g_fLastRagPos[i][1]      = 0.0;
        g_fLastRagPos[i][2]      = 0.0;
        g_bRagInAir[i]           = false;
        g_fRagGroundZ[i]         = 0.0;
        g_iWeaponHandEnt[i]      = INVALID_ENT_REFERENCE;
    }
}

// -----------------------------------------------------------------------
// Commands
// -----------------------------------------------------------------------
Action Cmd_Faint(int client, int args)
{
    if (client == 0) { ReplyToCommand(client, "[Faint] In-game only."); return Plugin_Handled; }
    if (g_bAdminsOnly && !CheckCommandAccess(client, "sm_faint_admin", ADMFLAG_GENERIC))
    {
        ReplyToCommand(client, "[Faint] Only admins can use this command.");
        return Plugin_Handled;
    }
    MainRagdollFunc(client);
    return Plugin_Handled;
}

Action Cmd_FaintPlayer(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[Faint] Usage: sm_faintplayer <#userid|name>");
        return Plugin_Handled;
    }

    char arg[64];
    GetCmdArg(1, arg, sizeof(arg));

    char target_name[MAX_TARGET_LENGTH];
    int  target_list[MAXPLAYERS];
    int  target_count;
    bool tn_is_ml;

    target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS,
                                       COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml);

    if (target_count <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    for (int i = 0; i < target_count; i++)
    {
        int target = target_list[i];
        if (!IsSurvivor(target)) continue;
        MainRagdollFunc(target);
    }

    if (target_count == 1)
        ReplyToCommand(client, "[Faint] Faint applied to %s.", target_name);
    else
        ReplyToCommand(client, "[Faint] Faint applied to %d players.", target_count);

    return Plugin_Handled;
}

// -----------------------------------------------------------------------
// Events
// -----------------------------------------------------------------------
void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (!victim || !IsClientInGame(victim) || !IsSurvivor(victim)) return;

    if (GetRagdoll(victim) != INVALID_ENT_REFERENCE)
        RemoveFaintRagdoll(victim);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client))
        RemoveFaintRagdoll(client);
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client))
        RemoveFaintRagdoll(client);
}

void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!client || !IsClientInGame(client)) return;
    RemoveFaintRagdoll(client);
}

void Event_ChargerCarryStart(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("victim"));
    if (victim > 0 && IsClientInGame(victim) && GetRagdoll(victim) != INVALID_ENT_REFERENCE)
        RemoveFaintRagdoll(victim);
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
        RemoveFaintRagdoll(i);
}

void Event_IntroCutsceneBegin(Event event, const char[] name, bool dontBroadcast)
{
    g_bIntroActive = true;
}

void Event_IntroCutsceneEnd(Event event, const char[] name, bool dontBroadcast)
{
    g_bIntroActive = false;
}

// -----------------------------------------------------------------------
// Timers
// -----------------------------------------------------------------------
Action Timer_KillRagdoll(Handle timer, any ragRef)
{
    int rag = EntRefToEntIndex(ragRef);
    if (rag != INVALID_ENT_REFERENCE && IsValidEntity(rag))
        AcceptEntityInput(rag, "Kill");
    return Plugin_Stop;
}

Action Timer_RestoreMoveType(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
    {
        SetEntProp(client, Prop_Data, "m_MoveType", MOVETYPE_WALK);
        SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
    }
    return Plugin_Stop;
}

// -----------------------------------------------------------------------
// Core
// -----------------------------------------------------------------------

bool IsOnMovingPlatform(int client)
{
    // Check ground entity before faint is active
    int groundEnt = GetEntPropEnt(client, Prop_Data, "m_hGroundEntity");
    if (groundEnt > 0 && IsValidEntity(groundEnt))
    {
        char groundClass[64];
        GetEntityClassname(groundEnt, groundClass, sizeof(groundClass));
        if (IsMovingPlatformClass(groundClass)) return true;
    }

    // During faint: trace downward from ragdoll to detect moving ground
    int rag = GetRagdoll(client);
    if (rag == INVALID_ENT_REFERENCE || !IsValidEntity(rag)) return false;

    float ragPos[3];
    GetEntPropVector(rag, Prop_Send, "m_vecOrigin", ragPos);

    float trStart[3], trEnd[3];
    trStart    = ragPos;
    trStart[2] += 5.0;
    trEnd      = ragPos;
    trEnd[2]  -= 40.0;

    Handle tr = TR_TraceRayFilterEx(trStart, trEnd, MASK_PLAYERSOLID,
                                    RayType_EndPoint, Filter_IgnoreRagdollAndPlayer,
                                    view_as<any>(rag | (client << 16)));
    bool hit = TR_DidHit(tr);
    int hitEnt = hit ? TR_GetEntityIndex(tr) : -1;
    delete tr;

    if (!hit || hitEnt <= 0 || !IsValidEntity(hitEnt)) return false;

    char hitClass[64];
    GetEntityClassname(hitEnt, hitClass, sizeof(hitClass));
    return IsMovingPlatformClass(hitClass);
}

bool IsMovingPlatformClass(const char[] cls)
{
    return (StrContains(cls, "func_elevator") != -1 ||
            StrContains(cls, "func_move")     != -1 ||
            StrContains(cls, "func_track")    != -1 ||
            StrContains(cls, "func_door")     != -1 ||
            StrContains(cls, "func_plat")     != -1);
}

void MainRagdollFunc(int client)
{
    if (!client || !IsClientInGame(client)) return;
    if (!IsPlayerAlive(client)) return;
    if (!IsSurvivor(client)) return;
    if (IsPinned(client)) return;
    if (IsGhost(client)) return;
    if (IsIncapacitated(client)) return;

    if (IsOnMovingPlatform(client))
    {
        ReplyToCommand(client, "[Faint] Cant faint while on a moving platform.");
        return;
    }

    float now = GetGameTime();
    if (g_fCmdDelay[client] > now) return;
    g_fCmdDelay[client] = now + 0.5;

    if (GetRagdoll(client) != INVALID_ENT_REFERENCE)
        RemoveFaintRagdoll(client);
    else
    {
        if (g_bRequireGrounded && !(GetEntityFlags(client) & FL_ONGROUND))
        {
            ReplyToCommand(client, "[Faint] You must be on the ground to faint.");
            return;
        }
        CreateFaintRagdoll(client);
    }
}

int CreateFaintRagdoll(int client)
{
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        return INVALID_ENT_REFERENCE;
    if (GetRagdoll(client) != INVALID_ENT_REFERENCE)
        return INVALID_ENT_REFERENCE;

    char model[PLATFORM_MAX_PATH];
    GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));

    float origin[3], angles[3];
    GetClientAbsOrigin(client, origin);
    GetClientEyeAngles(client, angles);

    // Trace downward to find exact floor position — avoids clipping on slopes.
    // Only when grounded; if airborne, use current position as-is to avoid
    // snapping the ragdoll to a floor that may be far below or clipping into a ceiling.
    bool isOnGround = (GetEntityFlags(client) & FL_ONGROUND) != 0;
    if (isOnGround)
    {
        float trStart[3], trEnd[3];
        trStart = origin;
        trStart[2] += 10.0;
        trEnd    = origin;
        trEnd[2] -= 50.0;

        Handle tr = TR_TraceRayFilterEx(trStart, trEnd, MASK_PLAYERSOLID_BRUSHONLY,
                                        RayType_EndPoint, Filter_IgnoreClient,
                                        view_as<any>(client));
        if (TR_DidHit(tr))
        {
            float hitPos[3];
            TR_GetEndPosition(hitPos, tr);
            origin[2] = hitPos[2] + 48.0; // +48: aligns ragdoll root bone above floor
        }
        else
        {
            origin[2] += 48.0;
        }
        delete tr;
    }

    angles[0] = 0.0;
    angles[2] = 0.0;

    int rag = CreateEntityByName("prop_ragdoll");
    if (!IsValidEntity(rag)) return INVALID_ENT_REFERENCE;

    DispatchKeyValue(rag, "model", model);
    DispatchKeyValue(rag, "solid", "0");
    DispatchKeyValue(rag, "spawnflags", "32772");

    char entName[64];
    FormatEx(entName, sizeof(entName), "faint_ragdoll_%d", client);
    DispatchKeyValue(rag, "targetname", entName);

    DispatchSpawn(rag);
    TeleportEntity(rag, origin, angles, NULL_VECTOR);

    SetEntProp(rag, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
    SetEntProp(rag, Prop_Send, "m_fEffects", (1 << 17));
    SetEntProp(rag, Prop_Send, "m_nForceBone", GetEntProp(client, Prop_Send, "m_nForceBone"));

    // Glow on the ragdoll — color reflects current survivor health
    int glowColor[3];
    GetSurvivorGlowColor(client, glowColor);
    L4D2_SetEntityGlow(rag, L4D2Glow_Unoccluded, 0, 0, glowColor, false);

    float vel[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
    SetEntPropFloat(client, Prop_Send, "m_flFallVelocity", 0.0);

    SetEntProp(client, Prop_Data, "m_MoveType", MOVETYPE_NONE);
    SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
    SetEntProp(client, Prop_Send, "m_fEffects", 0);

    SetEntityRenderMode(client, RENDER_TRANSALPHA);
    SetEntityRenderColor(client, 255, 255, 255, 0);

    // Suppress glow on the invisible player entity
    L4D2_RemoveEntityGlow(client);

    // Force third-person camera for survivors
    if (IsSurvivor(client))
    {
        SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", GetGameTime() + 999999.0);
    }
    else
    {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
        SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
        SetEntPropEnt(client, Prop_Send, "m_hViewEntity", rag);
    }

    g_iRagdoll[client] = EntIndexToEntRef(rag);

    g_fTimeCannotGetUp[client] = GetGameTime() + 0.5;
    g_fJumpCooldown[client]    = GetGameTime() + 1.0;
    g_fThinkCooldown[client]   = GetGameTime() + 0.25;
    g_fMoveCooldown[client]    = 0.0;
    g_iWallBounceCount[client]      = 0;
    g_fWallBounceWindowStart[client] = 0.0;
    g_fWallBounceCooldown[client]   = 0.0;
    g_fThinkRate[client]            = 0.0;
    g_fLastRagPos[client][0]   = 0.0;
    g_fLastRagPos[client][1]   = 0.0;
    g_fLastRagPos[client][2]   = 0.0;
    g_bRagInAir[client]        = false;
    g_fRagGroundZ[client]      = origin[2]; // initial ground Z at faint creation
    g_iWeaponHandEnt[client]   = INVALID_ENT_REFERENCE;

    // Transfer player velocity to ragdoll at spawn
    float ragPos[3], ragAng[3];
    GetEntPropVector(rag, Prop_Send, "m_vecOrigin", ragPos);
    GetEntPropVector(rag, Prop_Send, "m_angRotation", ragAng);
    TeleportEntity(rag, ragPos, ragAng, vel);

    SDKHook(client, SDKHook_PostThink,     Hook_ClientThink);
    SDKHook(client, SDKHook_WeaponCanUse,  WeaponCanUseSwitch);
    SDKHook(client, SDKHook_WeaponSwitch,  WeaponCanUseSwitch);
    SDKHook(client, SDKHook_PostThinkPost, Hook_HideAddons);

    return rag;
}

void RemoveFaintRagdoll(int client)
{
    if (client <= 0) return;

    int ragRef = g_iRagdoll[client];
    if (ragRef == INVALID_ENT_REFERENCE) return;

    float savedGroundZ = g_bFallDamage ? g_fRagGroundZ[client] : 0.0;

    g_iRagdoll[client] = INVALID_ENT_REFERENCE;
    g_fLastRagPos[client][0] = 0.0;
    g_fLastRagPos[client][1] = 0.0;
    g_fLastRagPos[client][2] = 0.0;
    g_fRagGroundZ[client]    = 0.0;

    int rag = EntRefToEntIndex(ragRef);

    if (rag == INVALID_ENT_REFERENCE || !IsValidEntity(rag))
    {
        if (IsClientInGame(client))
            RestoreClient(client, INVALID_ENT_REFERENCE, savedGroundZ);
        return;
    }

    SDKUnhook(client, SDKHook_PostThink,     Hook_ClientThink);
    SDKUnhook(client, SDKHook_WeaponCanUse,  WeaponCanUseSwitch);
    SDKUnhook(client, SDKHook_WeaponSwitch,  WeaponCanUseSwitch);
    SDKUnhook(client, SDKHook_PostThinkPost, Hook_HideAddons);
    RestoreClient(client, rag, savedGroundZ);

    CreateTimer(0.05, Timer_KillRagdoll, ragRef);
}

void RestoreClient(int client, int rag, float savedGroundZ = 0.0)
{
    if (!IsClientInGame(client)) return;

    SetEntityRenderMode(client, RENDER_NORMAL);
    SetEntityRenderColor(client, 255, 255, 255, 255);
    SetEntProp(client, Prop_Send, "m_fEffects", 0);
    L4D2_RemoveEntityGlow(client);
    SetEntPropFloat(client, Prop_Send, "m_flFallVelocity", 0.0);

    if (IsSurvivor(client))
    {
        SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", GetGameTime());
    }
    else
    {
        SetEntProp(client, Prop_Send, "m_hObserverTarget", -1);
        int viewEnt = GetEntPropEnt(client, Prop_Send, "m_hViewEntity");
        if (viewEnt > 0 && IsValidEntity(viewEnt))
            SetEntProp(client, Prop_Send, "m_hViewEntity", -1);
        SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
    }

    if (!IsPlayerAlive(client) || GetClientHealth(client) <= 0) return;

    if (rag != INVALID_ENT_REFERENCE && IsValidEntity(rag))
    {
        float ragOrigin[3];
        GetEntPropVector(rag, Prop_Send, "m_vecOrigin", ragOrigin);

        // Don't teleport to ragdoll during intro — engine controls player position
        if (!g_bIntroActive)
        {
            float ragVel[3];
            GetEntPropVector(rag, Prop_Data, "m_vecAbsVelocity", ragVel);
            float clientAng[3];
            GetClientEyeAngles(client, clientAng);

            // Pass downward velocity to player so the game applies correct fall damage.
            // Uses physics formula: v = sqrt(2 * gravity * height), respects sv_gravity.
            if (savedGroundZ != 0.0)
            {
                float fallHeight = savedGroundZ - ragOrigin[2];
                if (fallHeight > 0.0)
                {
                    float gravity   = g_cvGravity.FloatValue;
                    float impactVel = SquareRoot(2.0 * gravity * fallHeight);
                    ragVel[2]       = -impactVel;
                }
            }

            TeleportEntity(client, ragOrigin, clientAng, ragVel);

            // m_flFallVelocity must match the downward speed for the game to apply damage
            if (ragVel[2] < 0.0)
                SetEntPropFloat(client, Prop_Send, "m_flFallVelocity", FloatAbs(ragVel[2]));
        }
    }

    SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);

    CreateTimer(0.02, Timer_RestoreMoveType, GetClientUserId(client));
}

// -----------------------------------------------------------------------
// Per-frame think while in faint
// -----------------------------------------------------------------------
Action Hook_ClientThink(int client)
{
    int rag = GetRagdoll(client);
    if (rag == INVALID_ENT_REFERENCE)
    {
        RemoveFaintRagdoll(client);
        SDKUnhook(client, SDKHook_PostThink,    Hook_ClientThink);
        SDKUnhook(client, SDKHook_PostThinkPost, Hook_HideAddons);
        return Plugin_Continue;
    }

    if (!IsClientInGame(client))
    {
        RemoveFaintRagdoll(client);
        return Plugin_Continue;
    }

    int buttons = GetClientButtons(client);

    if (buttons & IN_ATTACK)
    {
        RemoveFaintRagdoll(client);
        return Plugin_Continue;
    }

    float now = GetGameTime();
    if (g_fThinkRate[client] > now) return Plugin_Continue;
    g_fThinkRate[client] = now + 0.033;

    // Every 0.25s: re-apply MOVETYPE_NONE and collision group (engine may reset them)
    if (g_fThinkCooldown[client] < now)
    {
        g_fThinkCooldown[client] = now + 0.25;
        DoAttachments(client);

        // Cancel faint if survivor gets grabbed by a special infected (fallback)
        if (IsPinned(client))
        {
            RemoveFaintRagdoll(client);
            return Plugin_Continue;
        }

        if (IsOnMovingPlatform(client))
        {
            RemoveFaintRagdoll(client);
            return Plugin_Continue;
        }

        if (g_bRagInAir[client])
        {
            float ragPos[3];
            GetEntPropVector(rag, Prop_Send, "m_vecOrigin", ragPos);
            float trS[3], trE[3];
            trS    = ragPos;
            trS[2] += 5.0;
            trE    = ragPos;
            trE[2] -= 20.0;
            Handle landTr = TR_TraceRayFilterEx(trS, trE, MASK_PLAYERSOLID_BRUSHONLY,
                                                RayType_EndPoint, Filter_IgnoreRagdoll,
                                                view_as<any>(rag));
            bool onGround = TR_DidHit(landTr);
            delete landTr;

            if (onGround)
                g_bRagInAir[client] = false;
        }
    }

    // Rollback: if ragdoll crossed a wall since last tick, revert its position
    float curRagPos[3];
    GetEntPropVector(rag, Prop_Send, "m_vecOrigin", curRagPos);
    {
        if (g_fLastRagPos[client][0] != 0.0 || g_fLastRagPos[client][1] != 0.0)
        {
            float checkStart[3], checkEnd[3];
            checkStart    = g_fLastRagPos[client];
            checkStart[2] += 20.0;
            checkEnd      = curRagPos;
            checkEnd[2]   += 20.0;

            Handle wallTr = TR_TraceRayFilterEx(checkStart, checkEnd, CONTENTS_PLAYERCLIP|CONTENTS_MONSTERCLIP,
                                                RayType_EndPoint, Filter_IgnoreRagdollAndPlayer,
                                                view_as<any>(rag | (client << 16)));
            bool crossed = TR_DidHit(wallTr);
            delete wallTr;

            if (crossed)
            {
                // Limit impulses to 3 per 2s window to prevent ping-pong between parallel walls
                if (g_fWallBounceCooldown[client] > now)
                {
                    // In lockout — teleport back to last safe position and zero velocity
                    float ragAng[3];
                    GetEntPropVector(rag, Prop_Send, "m_angRotation", ragAng);
                    TeleportEntity(rag, g_fLastRagPos[client], ragAng, NULL_VECTOR);
                    float zeroVel[3];
                    SetEntPropVector(rag, Prop_Data, "m_vecAbsVelocity", zeroVel);
                }
                else
                {
                    // Reset window if older than 2s
                    if (now - g_fWallBounceWindowStart[client] > 2.0)
                    {
                        g_iWallBounceCount[client]       = 0;
                        g_fWallBounceWindowStart[client] = now;
                    }

                    g_iWallBounceCount[client]++;

                    if (g_iWallBounceCount[client] > 3)
                    {
                        // Too many bounces — lockout for 1s and reset counter
                        g_fWallBounceCooldown[client]    = now + 1.0;
                        g_iWallBounceCount[client]       = 0;
                        g_fWallBounceWindowStart[client] = 0.0;
                    }
                    else
                    {
                // Apply impulse away from wall, scaled by movement delta.
                // Clamped to a maximum to prevent excessive force when stuck.
                float delta[3];
                delta[0] = curRagPos[0] - g_fLastRagPos[client][0];
                delta[1] = curRagPos[1] - g_fLastRagPos[client][1];
                delta[2] = 0.0;

                float ragAng[3];
                GetEntPropVector(rag, Prop_Send, "m_angRotation", ragAng);
                TeleportEntity(rag, g_fLastRagPos[client], ragAng, NULL_VECTOR);

                float pushVec[3];
                pushVec[0] = -delta[0] * 100.0;
                pushVec[1] = -delta[1] * 100.0;
                pushVec[2] = 0.0;

                // Cap maximum force to avoid ragdoll flying too far
                float maxForce = 400.0;
                float pushLen = SquareRoot(pushVec[0] * pushVec[0] + pushVec[1] * pushVec[1]);
                if (pushLen > maxForce)
                {
                    pushVec[0] = (pushVec[0] / pushLen) * maxForce;
                    pushVec[1] = (pushVec[1] / pushLen) * maxForce;
                }
                pushVec[2] = 150.0; // upward pop to help escape ledges and protrusions

                if (g_hApplyAbsVelocityImpulse != null)
                {
                    AcceptEntityInput(rag, "Wake");
                    SDKCall(g_hApplyAbsVelocityImpulse, rag, pushVec);
                }
                else
                {
                    SetEntPropVector(rag, Prop_Data, "m_vecAbsVelocity", pushVec);
                    AcceptEntityInput(rag, "Wake");
                }
                    } // end bounce count check
                } // end lockout check
                return Plugin_Continue;
            }
        }

        g_fLastRagPos[client] = curRagPos;
    }

    // Fall damage: check every tick whether ragdoll has fallen far enough to cause damage.
    // If so, remove the faint — the game handles fall damage naturally when the player lands.
    if (g_bFallDamage)
    {
        float trS[3], trE[3];
        trS    = curRagPos;
        trS[2] += 5.0;
        trE    = curRagPos;
        trE[2] -= 20.0;
        Handle groundTr = TR_TraceRayFilterEx(trS, trE, MASK_PLAYERSOLID_BRUSHONLY,
                                              RayType_EndPoint, Filter_IgnoreRagdoll,
                                              view_as<any>(rag));
        bool onGround = TR_DidHit(groundTr);
        delete groundTr;

        if (onGround)
        {
            // Always keep ground reference current — player may have walked downhill
            g_fRagGroundZ[client] = curRagPos[2];
        }
        else if (g_fRagGroundZ[client] != 0.0)
        {
            // Ragdoll is airborne — check if fall height exceeds damage threshold.
            float gravity     = g_cvGravity.FloatValue;
            float minVel      = 501.0;
            float minHeight   = (minVel * minVel) / (2.0 * gravity);
            float fallHeight  = g_fRagGroundZ[client] - curRagPos[2];
            if (fallHeight >= minHeight)
            {
                // Remove faint so the game applies fall damage naturally on landing
                RemoveFaintRagdoll(client);
                return Plugin_Continue;
            }
        }
    }

    // Sync invisible player position to ragdoll each tick (keeps hitbox aligned).
    // During intro cinematic the engine force-moves players — skip teleport to avoid desync.
    if (!g_bIntroActive)
        TeleportEntity(client, curRagPos, NULL_VECTOR, NULL_VECTOR);

    if (buttons == 0) return Plugin_Continue;

    bool inFwd   = !!(buttons & IN_FORWARD);
    bool inBwd   = !!(buttons & IN_BACK);
    bool inLft   = !!(buttons & IN_MOVELEFT);
    bool inRgt   = !!(buttons & IN_MOVERIGHT);
    bool jumping = !!(buttons & IN_JUMP);

    if ((inFwd || inBwd || inLft || inRgt) && MOVE_FORCE > 0.0)
    {
        float eyeAng[3];
        GetClientEyeAngles(client, eyeAng);
        eyeAng[0] = 0.0;
        eyeAng[2] = 0.0;

        float fwdVec[3], lftVec[3];
        GetAngleVectors(eyeAng, fwdVec, lftVec, NULL_VECTOR);

        float moveVec[3];
        moveVec[0] = 0.0; moveVec[1] = 0.0; moveVec[2] = 0.0;

        if (inFwd) { moveVec[0] += fwdVec[0]; moveVec[1] += fwdVec[1]; }
        if (inBwd) { moveVec[0] -= fwdVec[0]; moveVec[1] -= fwdVec[1]; }
        if (inLft) { moveVec[0] -= lftVec[0]; moveVec[1] -= lftVec[1]; }
        if (inRgt) { moveVec[0] += lftVec[0]; moveVec[1] += lftVec[1]; }

        if ((inFwd || inBwd) && (inLft || inRgt))
        {
            moveVec[0] *= 0.5;
            moveVec[1] *= 0.5;
        }

        moveVec[0] *= MOVE_FORCE;
        moveVec[1] *= MOVE_FORCE;

        if (g_fMoveCooldown[client] > now)
            return Plugin_Continue;
        g_fMoveCooldown[client] = now + g_fImpulseInterval;

        if (g_hApplyAbsVelocityImpulse != null)
        {
            AcceptEntityInput(rag, "Wake");
            SDKCall(g_hApplyAbsVelocityImpulse, rag, moveVec);
        }
        else
        {
            float curVel[3];
            GetEntPropVector(rag, Prop_Data, "m_vecAbsVelocity", curVel);
            curVel[0] += moveVec[0];
            curVel[1] += moveVec[1];
            SetEntPropVector(rag, Prop_Data, "m_vecAbsVelocity", curVel);
            AcceptEntityInput(rag, "Wake");
        }
    }

    if (jumping && JUMP_FORCE > 0.0 && g_fJumpCooldown[client] < now)
    {
        float ragOrigin[3];
        GetEntPropVector(rag, Prop_Send, "m_vecOrigin", ragOrigin);

        float trStart2[3], trEnd2[3];
        trStart2    = ragOrigin;
        trStart2[2] += 5.0;
        trEnd2      = ragOrigin;
        trEnd2[2]  -= 20.0;

        Handle trace = TR_TraceRayFilterEx(trStart2, trEnd2, MASK_PLAYERSOLID_BRUSHONLY,
                                           RayType_EndPoint, Filter_IgnoreRagdoll,
                                           view_as<any>(rag));
        bool hitGround = TR_DidHit(trace);
        delete trace;

        if (hitGround)
        {
            g_fJumpCooldown[client] = now + 0.75;
            g_bRagInAir[client] = true;

            float jumpVec[3];
            jumpVec[0] = 0.0; jumpVec[1] = 0.0; jumpVec[2] = JUMP_FORCE;
            if (g_hApplyAbsVelocityImpulse != null)
            {
                AcceptEntityInput(rag, "Wake");
                SDKCall(g_hApplyAbsVelocityImpulse, rag, jumpVec);
            }
            else
            {
                float curVel[3];
                GetEntPropVector(rag, Prop_Data, "m_vecAbsVelocity", curVel);
                curVel[2] += jumpVec[2];
                SetEntPropVector(rag, Prop_Data, "m_vecAbsVelocity", curVel);
                AcceptEntityInput(rag, "Wake");
            }
        }
        else
        {
            g_fJumpCooldown[client] = now + 0.75;
        }
    }

    return Plugin_Continue;
}

Action WeaponCanUseSwitch(int client, int weapon)
{
    return Plugin_Stop;
}

// Hide all weapon addons and the active weapon model every frame
void Hook_HideAddons(int client)
{
    SetEntProp(client, Prop_Send, "m_iAddonBits", 0);

    int iEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (iEnt != -1)
    {
        if (g_iWeaponHandEnt[client] == INVALID_ENT_REFERENCE)
            g_iWeaponHandEnt[client] = EntIndexToEntRef(iEnt);
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
    }
}

bool Filter_IgnoreClient(int entity, int contentsMask, any data)
{
    return entity != data;
}

bool Filter_IgnoreRagdoll(int entity, int contentsMask, any data)
{
    return entity != data;
}

bool Filter_IgnoreRagdollAndPlayer(int entity, int contentsMask, any data)
{
    int rag    = data & 0xFFFF;
    int player = (data >> 16) & 0xFFFF;
    return entity != rag && entity != player;
}

// -----------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------

void DoAttachments(int client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;
    SetEntProp(client, Prop_Data, "m_MoveType", MOVETYPE_NONE);
    SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
}

int GetRagdoll(int client)
{
    int ref = g_iRagdoll[client];
    if (ref == INVALID_ENT_REFERENCE) return INVALID_ENT_REFERENCE;
    int idx = EntRefToEntIndex(ref);
    if (idx == INVALID_ENT_REFERENCE)
    {
        g_iRagdoll[client] = INVALID_ENT_REFERENCE;
        return INVALID_ENT_REFERENCE;
    }
    return idx;
}

// -----------------------------------------------------------------------
// Glow stocks (L4D2)
// -----------------------------------------------------------------------

stock bool L4D2_SetEntityGlow(int entity, L4D2GlowType type, int range, int minRange, int colorOverride[3], bool flashing)
{
    char netclass[128];
    GetEntityNetClass(entity, netclass, sizeof(netclass));
    if (FindSendPropInfo(netclass, "m_iGlowType") < 1)
        return false;

    SetEntProp(entity, Prop_Send, "m_iGlowType",        type);
    SetEntProp(entity, Prop_Send, "m_nGlowRange",        range);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin",     minRange);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride",
        colorOverride[0] + (colorOverride[1] * 256) + (colorOverride[2] * 65536));
    SetEntProp(entity, Prop_Send, "m_bFlashing",         flashing);
    return true;
}

stock bool L4D2_RemoveEntityGlow(int entity)
{
    int empty[3];
    return L4D2_SetEntityGlow(entity, L4D2Glow_None, 0, 0, empty, false);
}

// Returns the default game glow color based on survivor health.
// Values match L4D2 default cl_glow_survivor_health_* cvars (float 0-1 -> int 0-255).
void GetSurvivorGlowColor(int client, int color[3])
{
    float hp = GetClientHealth(client) + GetTempHealth(client);

    if (hp >= 40)
    {
        // cl_glow_survivor_health_high: 0.035, 0.686, 0.192
        color[0] = 9;   color[1] = 175; color[2] = 49;
    }
    else if (hp >= 25)
    {
        // cl_glow_survivor_health_med: 0.588, 0.478, 0.031
        color[0] = 150; color[1] = 122; color[2] = 8;
    }
    else if (hp > 1)
    {
        // cl_glow_survivor_health_low: 0.698, 0.247, 0.0
        color[0] = 178; color[1] = 63;  color[2] = 0;
    }
    else
    {
        // cl_glow_survivor_health_crit: 0.627, 0.094, 0.094
        color[0] = 160; color[1] = 24;  color[2] = 24;
    }
}

stock float GetTempHealth(int client)
{
    static ConVar painPillsDecayCvar;
    if (painPillsDecayCvar == null)
    {
        painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
        if (painPillsDecayCvar == null)
            return 0.0;
    }

    float fGameTime   = GetGameTime();
    float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
    float fHealth     = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");

    fHealth -= (fGameTime - fHealthTime) * painPillsDecayCvar.FloatValue;
    return fHealth < 0.0 ? 0.0 : fHealth;
}

// -----------------------------------------------------------------------
// State checks
// -----------------------------------------------------------------------
bool IsSurvivor(int client)
{
    return GetClientTeam(client) == 2;
}

bool IsIncapacitated(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

bool IsGhost(int client)
{
    if (GetClientTeam(client) != 3) return false;
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

bool IsPinned(int client)
{
    static const char pinProps[][] = {
        "m_pummelAttacker", "m_pummelVictim",
        "m_carryAttacker",  "m_carryVictim",
        "m_pounceAttacker", "m_pounceVictim",
        "m_jockeyAttacker", "m_jockeyVictim",
        "m_tongueOwner",    "m_tongueVictim"
    };
    for (int i = 0; i < sizeof(pinProps); i++)
    {
        if (!HasEntProp(client, Prop_Send, pinProps[i])) continue;
        int pinner = GetEntPropEnt(client, Prop_Send, pinProps[i]);
        if (pinner > 0 && IsValidEntity(pinner)) return true;
    }
    return false;
}
