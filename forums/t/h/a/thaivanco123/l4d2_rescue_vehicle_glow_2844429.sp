#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0.3"
#define PLUGIN_NAME    "L4D2 Rescue Vehicle Glow"
#define PLUGIN_AUTHOR  "some guy who got tired of getting lost"
#define PLUGIN_DESC    "makes rescue vehicle glow so you don't wander around like an idiot"

#define CVAR_FLAGS     FCVAR_NOTIFY

// glow types. 0 = off, 3 = that sexy outline you see through walls
#define GLOW_OFF     0
#define GLOW_SEXY    3

// proxy shit for brush entities that refuse to glow on their own
#define MAX_VEHICLES 16
#define PROXY_MODEL  "models/props_junk/wood_crate001a.mdl"

// ------------------------------------------------------------------
// MODEL PATHS — these are basically 100% guaranteed to be the real deal
// if the model path has "helicopter" in it, it's not a random trash can
// ------------------------------------------------------------------
static const char g_sExactModels[][] =
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
    "train_boxcar"
};

// ------------------------------------------------------------------
// TARGETNAMES — if the mapper actually named their shit properly,
// we trust it instantly. no distance check, no questions asked.
// ------------------------------------------------------------------
// REMOVED "pilot" and "heli_pilot" — pilot is the guy inside, not the vehicle itself.
// glowing the pilot just gives you a tiny green outline around a person. useless.
// ADDED "helicopter_brush" for custom maps that use func_brush as rescue platform.
// ADDED boat, river_boat, Balloon, escapevehicle for [AIM] maps.
static const char g_sExactNames[][] =
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
// VAGUE MODELS — these are risky. "boat" could be a random dinghy.
// we ONLY glow these if they ALSO have a rescue targetname AND
// the player is basically standing next to it. paranoid? yes.
// ------------------------------------------------------------------
// REMOVED from this list because they caused chaos:
//   train, vehicle, truck, car, taxi, police
// every damn map has abandoned cars and decorative trains. no thanks.
static const char g_sVagueModels[][] =
{
    "boat",
    "plane",
    "heli"
};

// targetname keywords that prove it's actually rescue-related
static const char g_sRescueNames[][] =
{
    "rescue", "escape", "finale", "getaway",
    "vehicle", "heli", "chopper", "boat", "plane", "train", "c130"
};

// classnames we actually bother scanning. no point checking info_target or whatever
// ADDED func_brush — some custom maps (like yours) use this for helicopter landing pads
// that need collision but aren't prop_dynamic. without this we never find the rescue.
static const char g_sClassnames[][] =
{
    "prop_dynamic",
    "prop_dynamic_override",
    "prop_physics",
    "prop_physics_override",
    "func_tracktrain", //this shit
    "prop_vehicle",
    "prop_vehicle_driveable",
    "func_brush" //this shit
};

ConVar g_hCvarEnable;
ConVar g_hCvarGlowRange;
ConVar g_hCvarGlowColor;
ConVar g_hCvarUpdateRate;
ConVar g_hCvarDebug;
ConVar g_hCvarMaxDistExact;
ConVar g_hCvarMaxDistVague;
ConVar g_hCvarFlashing;

bool g_bCvarEnable;
int g_iCvarGlowRange;
int g_iCvarGlowColor;
bool g_bCvarDebug;
float g_fCvarMaxDistExact;
float g_fCvarMaxDistVague;
bool g_bCvarFlashing;

// proxy tracking so we don't spam entities and crash the server
int g_iVehicleEntRef[MAX_VEHICLES];
int g_iVehicleProxyRef[MAX_VEHICLES];

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESC,
    version     = PLUGIN_VERSION,
    url         = ""
};

public void OnPluginStart()
{
    g_hCvarEnable      = CreateConVar("sm_rescue_glow_enable", "1", "0 = plugin sleeps, 1 = plugin works", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvarGlowRange   = CreateConVar("sm_rescue_glow_range", "0", "how far the glow renders visually (0 = forever)", CVAR_FLAGS, true, 0.0);
    g_hCvarGlowColor   = CreateConVar("sm_rescue_glow_color", "0 255 0", "R G B. default is hacker green.", CVAR_FLAGS);
    g_hCvarUpdateRate  = CreateConVar("sm_rescue_glow_rate", "3.0", "seconds between scans. don't spam the server.", CVAR_FLAGS, true, 1.0);
    g_hCvarDebug       = CreateConVar("sm_rescue_glow_debug", "0", "1 = dumps every glowing entity to console. noisy but useful.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvarMaxDistExact = CreateConVar("sm_rescue_glow_maxdist_exact", "8000", "exact models can glow from this far (0 = no limit)", CVAR_FLAGS, true, 0.0);
    g_hCvarMaxDistVague = CreateConVar("sm_rescue_glow_maxdist_vague", "2000", "vague models need to be THIS close or we ignore them", CVAR_FLAGS, true, 0.0);
    g_hCvarFlashing    = CreateConVar("sm_rescue_glow_flashing", "0", "1 = flashing glow, 0 = steady glow", CVAR_FLAGS, true, 0.0, true, 1.0);

    // uncomment if you want an auto-generated cfg file. i personally don't care.
    // AutoExecConfig(true, "l4d2_rescue_vehicle_glow");

    g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarGlowRange.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarGlowColor.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarUpdateRate.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarDebug.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarMaxDistExact.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarMaxDistVague.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarFlashing.AddChangeHook(ConVarChanged_Cvars);

    // hook events
    HookEvent("round_start", Event_RoundStart);
    HookEvent("mission_lost", Event_RoundEnd);
    HookEvent("map_transition", Event_RoundEnd);

    // periodic scan timer. like a heartbeat but for rescue vehicles
    CreateTimer(g_hCvarUpdateRate.FloatValue, Timer_UpdateGlow, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapStart()
{
    // precache the proxy model so it doesn't show ERROR
    PrecacheModel(PROXY_MODEL, true);
    
    static const char sChunkModels[][] = {
        "models/props_junk/wood_crate001a_chunk01.mdl",
        "models/props_junk/wood_crate001a_chunk02.mdl",
        "models/props_junk/wood_crate001a_chunk03.mdl",
        "models/props_junk/wood_crate001a_chunk04.mdl",
        "models/props_junk/wood_crate001a_chunk05.mdl",
        "models/props_junk/wood_crate001a_chunk07.mdl",
        "models/props_junk/wood_crate001a_chunk09.mdl"
    };
    
    for (int i = 0; i < sizeof(sChunkModels); i++)
        PrecacheModel(sChunkModels[i], true);
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

void GetCvars()
{
    g_bCvarEnable       = g_hCvarEnable.BoolValue;
    g_iCvarGlowRange    = g_hCvarGlowRange.IntValue;
    g_iCvarGlowColor    = ParseGlowColor();
    g_bCvarDebug        = g_hCvarDebug.BoolValue;
    g_fCvarMaxDistExact = g_hCvarMaxDistExact.FloatValue;
    g_fCvarMaxDistVague = g_hCvarMaxDistVague.FloatValue;
    g_bCvarFlashing     = g_hCvarFlashing.BoolValue;
}

public void OnConfigsExecuted()
{
    GetCvars();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    ClearAllProxies();
    // give entities a few seconds to spawn before we start scanning blindly
    CreateTimer(3.0, Timer_UpdateGlow, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    ClearAllProxies();
}

Action Timer_UpdateGlow(Handle timer)
{
    if (!g_bCvarEnable)
        return Plugin_Continue;

    // if this map is a finale map.
    // no more guessing based on events that might not fire on custom maps.
    if (!L4D_IsMissionFinalMap())
    {
        ClearAllProxies();
        return Plugin_Continue;
    }

    ApplyRescueGlow();
    return Plugin_Continue;
}

// ------------------------------------------------------------------
// finds closest living survivor to a point. returns distance.
// used to make sure we don't glow some random prop on the other side
// of the map because it happens to have "train" in its model path.
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
// PROXY MANAGEMENT — 1 proxy per vehicle, no duplicates, no leaks
// brush entities like func_tracktrain can't glow on their own so we
// parent a prop_dynamic_override to them and glow that instead.
// ------------------------------------------------------------------
void ClearAllProxies()
{
    for (int i = 0; i < MAX_VEHICLES; i++)
    {
        if (g_iVehicleProxyRef[i] != 0)
        {
            int proxy = EntRefToEntIndex(g_iVehicleProxyRef[i]);
            if (proxy != INVALID_ENT_REFERENCE && proxy > MaxClients && IsValidEntity(proxy))
                RemoveEntity(proxy);
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
            if (proxy != INVALID_ENT_REFERENCE && proxy > MaxClients && IsValidEntity(proxy))
                return proxy;
            // proxy died somehow, clear the slot
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

    // TeleportEntity BEFORE DispatchSpawn. doing it the other way round can crash the server.
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
// THE MEAT. scans all entities by classname, reads their model path
// and targetname, decides if it's rescue-worthy, then slaps glow on it.
// for brush entities we use a proxy because they can't glow themselves.
// ------------------------------------------------------------------
void ApplyRescueGlow()
{
    char modelPath[PLATFORM_MAX_PATH];
    char targetName[128];
    char sClass[64];
    float entityPos[3];
    int glowColor = g_iCvarGlowColor;
    bool bDebug = g_bCvarDebug;
    float maxExact = g_fCvarMaxDistExact;
    float maxVague = g_fCvarMaxDistVague;

    // iterate through our classname whitelist
    for (int c = 0; c < sizeof(g_sClassnames); c++)
    {
        int entity = -1;
        while ((entity = FindEntityByClassname(entity, g_sClassnames[c])) != INVALID_ENT_REFERENCE)
        {
            if (!IsValidEntity(entity) || entity <= MaxClients)
                continue;

            // Read the damn model path.
            GetEntPropString(entity, Prop_Data, "m_ModelName", modelPath, sizeof(modelPath));
            GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));

            int matchType = IsRescueVehicle(modelPath, targetName);
            if (matchType == 0)
                continue; // not our guy

            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
            float dist = GetClosestSurvivorDistance(entityPos);

            // matchType 1 = exact model. respect maxExact distance.
            if (matchType == 1)
            {
                if (maxExact > 0.0 && dist > maxExact)
                    continue;
            }
            // matchType 2 = vague model + rescue name. MUST be close. very close.
            else if (matchType == 2)
            {
                if (maxVague > 0.0 && dist > maxVague)
                    continue;
            }
            // matchType 3 = exact targetname. mapper knew what they were doing. glow no matter what.
            else if (matchType == 3)
            {
                // distance? we don't know her.
            }

            // check if this entity already has a proxy. if yes, skip.
            int vehicleRef = EntIndexToEntRef(entity);
            int existing = FindExistingVehicleProxy(vehicleRef);
            if (existing != -1)
            {
                if (bDebug)
                    PrintToServer("[RescueGlow] vehicle %d already has proxy %d, skipping", entity, existing);
                continue;
            }

            // figure out if this entity needs a proxy or can glow directly
            GetEntityClassname(entity, sClass, sizeof(sClass));
            bool bNeedsProxy = (sClass[0] == 'f' && sClass[4] == '_');

            if (!bNeedsProxy)
            {
                // prop_dynamic / prop_physics can glow directly. no proxy needed.
                SetEntProp(entity, Prop_Send, "m_iGlowType", GLOW_OFF);
                SetEntProp(entity, Prop_Send, "m_iGlowType", GLOW_SEXY);
                SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlowRange);
                SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 0);
                SetEntProp(entity, Prop_Send, "m_glowColorOverride", glowColor);
                SetEntProp(entity, Prop_Send, "m_bFlashing", g_bCvarFlashing);

                if (bDebug)
                {
                    PrintToServer("[RescueGlow] direct glow ent %d | tier:%d | dist:%.0f | class:%s | model:%s | name:%s",
                        entity, matchType, dist, g_sClassnames[c], modelPath, targetName);
                }
                continue;
            }

            // brush entity. create a proxy and glow that instead.
            int proxy = CreateGlowProxy(entity);
            if (proxy == -1)
                continue; // failed to create proxy, skip this one

            RegisterVehicleProxy(vehicleRef, EntIndexToEntRef(proxy));

            // slap the glow on the proxy
            SetEntProp(proxy, Prop_Send, "m_iGlowType", GLOW_OFF);
            SetEntProp(proxy, Prop_Send, "m_iGlowType", GLOW_SEXY);
            SetEntProp(proxy, Prop_Send, "m_nGlowRange", g_iCvarGlowRange);
            SetEntProp(proxy, Prop_Send, "m_nGlowRangeMin", 180);
            SetEntProp(proxy, Prop_Send, "m_glowColorOverride", glowColor);
            SetEntProp(proxy, Prop_Send, "m_bFlashing", g_bCvarFlashing);

            if (bDebug)
            {
                PrintToServer("[RescueGlow] proxy glow ent %d (proxy:%d) | tier:%d | dist:%.0f | class:%s | model:%s | name:%s",
                    entity, proxy, matchType, dist, g_sClassnames[c], modelPath, targetName);
            }
        }
    }
}

// ------------------------------------------------------------------
// decides if an entity deserves to glow. returns:
//   0 = nah
//   1 = exact model match (respects maxExact distance)
//   2 = vague model + rescue targetname (respects maxVague distance, very strict)
//   3 = exact targetname (glow immediately, ignore distance, mapper knows best)
// ------------------------------------------------------------------
int IsRescueVehicle(const char[] modelPath, const char[] targetName)
{
    // tier 3: exact targetname. if the mapper named it "rescue_heli" we don't ask questions.
    // "helicopter_brush" catches func_brush entities used as rescue platforms in custom maps.
    // "boat", "river_boat", "Balloon", "escapevehicle" for [AIM] maps.
    for (int i = 0; i < sizeof(g_sExactNames); i++)
    {
        if (StrContains(targetName, g_sExactNames[i], false) != -1)
            return 3;
    }

    // tier 1: exact model path. "helicopter" in the model name? probably legit.
    for (int i = 0; i < sizeof(g_sExactModels); i++)
    {
        if (StrContains(modelPath, g_sExactModels[i], false) != -1)
            return 1;
    }

    // tier 2: vague model. "boat" could be anything. need rescue targetname AND proximity.
    for (int i = 0; i < sizeof(g_sVagueModels); i++)
    {
        if (StrContains(modelPath, g_sVagueModels[i], false) != -1)
        {
            for (int j = 0; j < sizeof(g_sRescueNames); j++)
            {
                if (StrContains(targetName, g_sRescueNames[j], false) != -1)
                    return 2;
            }
            break; // vague model but no rescue name = not our problem
        }
    }

    return 0; // get outta here
}

// ------------------------------------------------------------------
// parses "R G B" convar into the packed integer the game wants.
// if you mess up the format you get green. deal with it.
// ------------------------------------------------------------------
int ParseGlowColor()
{
    char colorStr[16];
    g_hCvarGlowColor.GetString(colorStr, sizeof(colorStr));
    int r = 0, g = 255, b = 0;

    if (colorStr[0])
    {
        char parts[3][4];
        int num = ExplodeString(colorStr, " ", parts, 3, 4);
        if (num >= 1) r = StringToInt(parts[0]);
        if (num >= 2) g = StringToInt(parts[1]);
        if (num >= 3) b = StringToInt(parts[2]);
    }
    return (r << 16) | (g << 8) | b;
}

public void OnPluginEnd()
{
    ClearAllProxies(); // clean up after ourselves. mom raised a gentleman.
}