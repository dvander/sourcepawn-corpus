#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.6"
#define MAX_VEHICLES 16
#define PROXY_MODEL "models/props_junk/wood_crate001a.mdl"


public Plugin myinfo =
{
    name        = "[L4D2] Rescue Vehicle Glow",
    author      = "thaivanco123, made by KL (Support by ChatGPT)",
    description = "Make the rescue vehicle Glow",
    version     = PLUGIN_VERSION,
    url         = "https://forums.alliedmods.net/showthread.php?t=352703"
};

// ------------------------------------------------------------------
// Exact model checks.
// These models are highly reliable rescue vehicle identifiers.
// ------------------------------------------------------------------
char g_sExactModels[][] =
{
    "helicopter",
    "chopper",
    "c130",
    "plane_rescue",
    "boat_rescue",
    "ferry",
    "barge",
    "train_rescue",
    "locomotive",
    "subway",
    "metro",
    "apc",
    "getaway_vehicle",
    "finale_vehicle",
    "rescue_vehicle",
    "escape_boat",
    "escape_plane",
    "rescue_heli",
    "train_enginecar",
    "train_boxcar",
    "racecar"
};

// ------------------------------------------------------------------
// Exact targetname checks.
// ------------------------------------------------------------------
char g_sExactNames[][] =
{
    "rescue_heli",
    "rescue_vehicle",
    "escape_vehicle",
    "finale_vehicle",
    "getaway_car",
    "rescue_boat",
    "rescue_train",
    "rescue_plane",
    "rescue",
    "helicopter_brush",
    "boat",
    "river_boat",
    "Balloon",
    "escapevehicle"
};

// ------------------------------------------------------------------
// Vague model checks.
// ------------------------------------------------------------------
char g_sVagueModels[][] =
{
    "boat",
    "plane",
    "heli",
    "armored",
    "hel"
};

// ------------------------------------------------------------------
// Rescue-related keywords.
// ------------------------------------------------------------------
char g_sRescueNames[][] =
{
    "rescue",
    "escape",
    "finale",
    "getaway",
    "vehicle",
    "heli",
    "chopper",
    "boat",
    "plane",
    "train",
    "c130",
    "helicopter_brush",
    "bus",
    "copt"
};

// ------------------------------------------------------------------
// Supported entity classnames.
// ------------------------------------------------------------------
char g_sClassnames[][] =
{
    "prop_dynamic",
    "prop_dynamic_override",
    "prop_physics",
    "prop_physics_override",
    "func_tracktrain",
    "prop_vehicle",
    "prop_vehicle_driveable",
    "func_brush"
};

ConVar g_hEnable;
ConVar g_hGlowRange;
ConVar g_hGlowColor;
ConVar g_hGlowFlashing;

bool g_bFinaleStarted = false;
bool g_bRescueArrived = false;

int g_iVehicleEntRef[MAX_VEHICLES];
int g_iVehicleProxyRef[MAX_VEHICLES];

public void OnPluginStart()
{
    g_hEnable       = CreateConVar("sm_rescue_glow_enable", "1", "Enable or disable the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hGlowColor    = CreateConVar("sm_rescue_glow_color", "0 255 0", "Glow color in RGB format", FCVAR_NOTIFY);
    g_hGlowRange    = CreateConVar("sm_rescue_glow_range", "0", "Glow render distance (0 = unlimited)", FCVAR_NOTIFY, true, 0.0);
    g_hGlowFlashing = CreateConVar("sm_rescue_glow_flashing", "1", "Enable flashing glow effect", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    HookEvent("round_start", Event_RoundStart);

    // Finale has started
    HookEvent("finale_escape_start", Event_FinaleStart);

    // Rescue vehicle has arrived and is waiting
    HookEvent("finale_vehicle_ready", Event_RescueArrived);

    HookEvent("finale_vehicle_leaving", Event_FinaleEnd);
    HookEvent("finale_win", Event_FinaleEnd);

    HookEvent("mission_lost", Event_Reset);
    HookEvent("map_transition", Event_Reset);

    AutoExecConfig(true, "l4d2_rescue_vehicle_glow");

    CreateTimer(3.0, Timer_UpdateGlow, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapStart()
{
    PrecacheModel(PROXY_MODEL, true);

    g_bFinaleStarted = false;
    g_bRescueArrived = false;

    // Give entities time to fully spawn.
    CreateTimer(5.0, Timer_DelayedScan);
}

public void Event_RoundStart(Event e, const char[] n, bool d)
{
    g_bFinaleStarted = false;
    g_bRescueArrived = false;

    // Some finale entities spawn slightly later.
    CreateTimer(3.0, Timer_DelayedScan);
}

// ------------------------------------------------------------------
// Finale activated.
// DO NOT glow yet.
// ------------------------------------------------------------------
public void Event_FinaleStart(Event e, const char[] n, bool d)
{
    g_bFinaleStarted = true;
    g_bRescueArrived = false;
}

void ClearAllProxies()
{
    for (int i = 0; i < MAX_VEHICLES; i++)
    {
        if (g_iVehicleProxyRef[i] != 0)
        {
            int proxy = EntRefToEntIndex(g_iVehicleProxyRef[i]);

            if (proxy != INVALID_ENT_REFERENCE
            && proxy > MaxClients
            && IsValidEntity(proxy))
            {
                RemoveEntity(proxy);
            }
        }

        g_iVehicleEntRef[i] = 0;
        g_iVehicleProxyRef[i] = 0;
    }
}

int FindExistingVehicleProxy(int vehicleRef)
{
    for (int i = 0; i < MAX_VEHICLES; i++)
    {
        if (g_iVehicleEntRef[i] == vehicleRef)
        {
            int proxy = EntRefToEntIndex(g_iVehicleProxyRef[i]);

            if (proxy != INVALID_ENT_REFERENCE
            && proxy > MaxClients
            && IsValidEntity(proxy))
            {
                return proxy;
            }

            g_iVehicleEntRef[i] = 0;
            g_iVehicleProxyRef[i] = 0;

            return -1;
        }
    }

    return -1;
}

void RegisterVehicleProxy(int vehicleRef, int proxyRef)
{
    for (int i = 0; i < MAX_VEHICLES; i++)
    {
        if (g_iVehicleEntRef[i] == 0)
        {
            g_iVehicleEntRef[i] = vehicleRef;
            g_iVehicleProxyRef[i] = proxyRef;
            return;
        }
    }
}

int CreateGlowProxy(int parentEntity)
{
    if (!IsValidEntity(parentEntity) || parentEntity <= MaxClients)
        return -1;

    int proxy = CreateEntityByName("prop_dynamic_override");

    if (proxy == -1 || proxy <= MaxClients)
        return -1;

    float vPos[3], vAng[3];

    GetEntPropVector(parentEntity, Prop_Send, "m_vecOrigin", vPos);
    GetEntPropVector(parentEntity, Prop_Send, "m_angRotation", vAng);

    TeleportEntity(proxy, vPos, vAng, NULL_VECTOR);

    DispatchKeyValue(proxy, "targetname", "rescueglow_proxy");
    DispatchKeyValue(proxy, "spawnflags", "0");
    DispatchKeyValue(proxy, "solid", "0");
    DispatchKeyValue(proxy, "disableshadows", "1");
    DispatchKeyValue(proxy, "disablereceiveshadows", "1");
    DispatchKeyValue(proxy, "model", PROXY_MODEL);
    DispatchKeyValue(proxy, "DefaultAnim", "idle");

    if (!DispatchSpawn(proxy))
    {
        if (proxy > MaxClients && IsValidEntity(proxy))
            RemoveEntity(proxy);

        return -1;
    }

    SetVariantEntity(parentEntity);

    if (!AcceptEntityInput(proxy, "SetParent"))
    {
        if (proxy > MaxClients && IsValidEntity(proxy))
            RemoveEntity(proxy);

        return -1;
    }

    SetEntityRenderMode(proxy, RENDER_NONE);

    return proxy;
}

// ------------------------------------------------------------------
// Rescue vehicle has arrived.
// NOW enable glow.
// ------------------------------------------------------------------
public void Event_RescueArrived(Event e, const char[] n, bool d)
{
    g_bRescueArrived = true;

    ApplyRescueGlow();

    PrintToChatAll(
        "\x04[Rescue]\x01 The rescue vehicle has arrived. Follow the glowing area to escape!"
    );
}

public void Event_FinaleEnd(Event e, const char[] n, bool d)
{
    g_bFinaleStarted = false;
    g_bRescueArrived = false;

    RemoveAllGlows();
}

public void Event_Reset(Event e, const char[] n, bool d)
{
    g_bFinaleStarted = false;
    g_bRescueArrived = false;

    RemoveAllGlows();
}

public Action Timer_DelayedScan(Handle timer)
{
    if (!g_hEnable.BoolValue)
        return Plugin_Stop;

    // Only glow after rescue vehicle arrived.
    if (!g_bRescueArrived)
        return Plugin_Stop;

    ApplyRescueGlow();

    return Plugin_Stop;
}

public Action Timer_UpdateGlow(Handle timer)
{
    if (!g_hEnable.BoolValue)
        return Plugin_Continue;

    // Glow ONLY when rescue vehicle is ready.
    if (!g_bFinaleStarted || !g_bRescueArrived)
        return Plugin_Continue;

    ApplyRescueGlow();

    return Plugin_Continue;
}

// ------------------------------------------------------------------
// Finds the closest living survivor distance.
// ------------------------------------------------------------------
float GetClosestSurvivorDistance(const float pos[3])
{
    float minDist = 10000000.0;
    float survivorPos[3];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
            continue;

        GetClientAbsOrigin(i, survivorPos);

        float dist = GetVectorDistance(pos, survivorPos);

        if (dist < minDist)
            minDist = dist;
    }

    return minDist;
}

// ------------------------------------------------------------------
// Main rescue glow logic.
// ------------------------------------------------------------------
void ApplyRescueGlow()
{
    char modelPath[PLATFORM_MAX_PATH];
    char targetName[128];
    float entityPos[3];

    int glowColor = ParseGlowColor();

    float maxExact = 100000.0;
    float maxVague = 20000.0;

    for (int c = 0; c < sizeof(g_sClassnames); c++)
    {
        int entity = -1;

        while ((entity = FindEntityByClassname(entity, g_sClassnames[c])) != INVALID_ENT_REFERENCE)
        {
            if (!IsValidEntity(entity) || entity <= MaxClients)
                continue;

            GetEntPropString(entity, Prop_Data, "m_ModelName", modelPath, sizeof(modelPath));
            GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));

            int matchType = IsRescueVehicle(modelPath, targetName);

            if (matchType == 0)
                continue;

            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);

            float dist = GetClosestSurvivorDistance(entityPos);

            if (matchType == 1)
            {
                if (maxExact > 0.0 && dist > maxExact)
                    continue;
            }
            else if (matchType == 2)
            {
                if (maxVague > 0.0 && dist > maxVague)
                    continue;
            }
            else if (matchType == 3)
            {
                // distance?
            }

            // Reset old glow state first.
            SetEntProp(entity, Prop_Send, "m_iGlowType", 0);

// ------------------------------------------------------------------
// func_tracktrain / func_brush require a glow proxy.
// ------------------------------------------------------------------
char sClass[64];

GetEntityClassname(entity, sClass, sizeof(sClass));

bool bNeedsProxy = (sClass[0] == 'f' && sClass[4] == '_');

if (!bNeedsProxy)
{
    SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
    SetEntProp(entity, Prop_Send, "m_iGlowType", 3);

    SetEntProp(entity, Prop_Send, "m_nGlowRange", g_hGlowRange.IntValue);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 0);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", glowColor);
    SetEntProp(entity, Prop_Send, "m_bFlashing", g_hGlowFlashing.IntValue);

    continue;
}

int vehicleRef = EntIndexToEntRef(entity);

int proxy = FindExistingVehicleProxy(vehicleRef);

if (proxy == -1)
{
    proxy = CreateGlowProxy(entity);

    if (proxy == -1)
        continue;

    RegisterVehicleProxy(
        vehicleRef,
        EntIndexToEntRef(proxy)
    );
}

SetEntProp(proxy, Prop_Send, "m_iGlowType", 0);
SetEntProp(proxy, Prop_Send, "m_iGlowType", 3);

SetEntProp(proxy, Prop_Send, "m_nGlowRange", g_hGlowRange.IntValue);
SetEntProp(proxy, Prop_Send, "m_nGlowRangeMin", 180);
SetEntProp(proxy, Prop_Send, "m_glowColorOverride", glowColor);
SetEntProp(proxy, Prop_Send, "m_bFlashing", g_hGlowFlashing.IntValue);
        }
    }
}

// ------------------------------------------------------------------
// Rescue vehicle detection logic.
// ------------------------------------------------------------------
int IsRescueVehicle(const char[] modelPath, const char[] targetName)
{
    // Exact targetname match
    for (int i = 0; i < sizeof(g_sExactNames); i++)
    {
        if (StrContains(targetName, g_sExactNames[i], false) != -1)
            return 3;
    }

    // Exact model match
    for (int i = 0; i < sizeof(g_sExactModels); i++)
    {
        if (StrContains(modelPath, g_sExactModels[i], false) != -1)
            return 1;
    }

    // Vague model + rescue keyword
    for (int i = 0; i < sizeof(g_sVagueModels); i++)
    {
        if (StrContains(modelPath, g_sVagueModels[i], false) != -1)
        {
            for (int j = 0; j < sizeof(g_sRescueNames); j++)
            {
                if (StrContains(targetName, g_sRescueNames[j], false) != -1)
                    return 2;
            }

            break;
        }
    }

    return 0;
}

// ------------------------------------------------------------------
// Parses RGB glow color.
// ------------------------------------------------------------------
int ParseGlowColor()
{
    char colorStr[16];

    g_hGlowColor.GetString(colorStr, sizeof(colorStr));

    int r = 0;
    int g = 255;
    int b = 0;

    if (strlen(colorStr) > 0)
    {
        char parts[3][4];

        int num = ExplodeString(colorStr, " ", parts, 3, 4);

        if (num >= 1)
            r = StringToInt(parts[0]);

        if (num >= 2)
            g = StringToInt(parts[1]);

        if (num >= 3)
            b = StringToInt(parts[2]);
    }

    return r + (g << 8) + (b << 16);
}

// ------------------------------------------------------------------
// Removes all active glow effects.
// ------------------------------------------------------------------
void RemoveAllGlows()
{
    for (int c = 0; c < sizeof(g_sClassnames); c++)
    {
        int entity = -1;

        while ((entity = FindEntityByClassname(entity, g_sClassnames[c])) != INVALID_ENT_REFERENCE)
        {
            if (IsValidEntity(entity) && entity > MaxClients)
            {
                SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
                SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0);
            }
        }
    }

    ClearAllProxies();
}