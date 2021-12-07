/**
 * =============================================================================
 * L4D Health Glow (C)2011 Buster "Mr. Zero" Nielsen
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License, version 3.0, as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2,"
 * the "Source Engine," the "SourcePawn JIT," and any Game MODs that run on
 * software by the Valve Corporation.  You must obey the GNU General Public
 * License in all respects for all other code used.  Additionally,
 * AlliedModders LLC grants this exception to all derivative works.
 * AlliedModders LLC defines further exceptions, found in LICENSE.txt
 * (as of this writing, version JULY-31-2007), or
 * <http://www.sourcemod.net/license.php>.
 */

/*
 * ==================================================
 *                    Preprocessor
 * ==================================================
 */

/* Parser settings */
#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 4

/* Plugin information */
#define PLUGIN_FULLNAME                 "L4D2 Health Glows"                  // Used when printing the plugin name anywhere
#define PLUGIN_SHORTNAME                "l4d2healthglows"                    // Shorter version of the full name, used in file paths, and other things
#define PLUGIN_AUTHOR                   "Buster \"Mr. Zero\" Nielsen"       // Author of the plugin
#define PLUGIN_DESCRIPTION              "Gives the Survivors a health glow around them." // Description of the plugin
#define PLUGIN_VERSION                  "1.0.3.1"                             // Version of the plugin
#define PLUGIN_URL                      "mrzerodk@gmail.com"                // URL associated with the project
#define PLUGIN_CVAR_PREFIX              "l4d2_healthglows"                   // Prefix for plugin cvars
#define PLUGIN_CMD_PREFIX               "l4d2_healthglows"                   // Prefix for plugin commands
#define PLUGIN_TAG                      "HealthGlow"                        // Plugin tag for chat prints
#define PLUGIN_CMD_GROUP                PLUGIN_SHORTNAME                    // Command group for plugin commands

/* Precompile plugin settings */
#define CREATE_TRACKING_CVAR            // Whether plugin will create a tracking cvar containing the version number of the plugin

#define GLOW_HEALTH_HIGH 100 // Not used but just for completeness sake
#define GLOW_HEALTH_MED 39
#define GLOW_HEALTH_LOW 24

/*
 * L4D2_IsSurvivorGlowDisabled is used to "detect" whether realism mode is active.
 * As in no survivor glows in realism, means "less health glows" by this plugin.
 *
 * Minimum range ensures that glows are not shown when survivors are inside each other.
 * Also hides the players own glow from themself when in third person shoulder mode.
 */

#define GLOW_HEALTH_HIGH_TYPE L4D2_IsSurvivorGlowDisabled() ? L4D2Glow_None : L4D2Glow_Constant
#define GLOW_HEALTH_HIGH_RANGE 0
#define GLOW_HEALTH_HIGH_MINRANGE 0
#define GLOW_HEALTH_HIGH_COLOR_R 0
#define GLOW_HEALTH_HIGH_COLOR_G 64
#define GLOW_HEALTH_HIGH_COLOR_B 0
#define GLOW_HEALTH_HIGH_FLASHING false

#define GLOW_HEALTH_MED_TYPE L4D2_IsSurvivorGlowDisabled() ? L4D2Glow_None : L4D2Glow_Constant
#define GLOW_HEALTH_MED_RANGE 0
#define GLOW_HEALTH_MED_MINRANGE 0
#define GLOW_HEALTH_MED_COLOR_R 72
#define GLOW_HEALTH_MED_COLOR_G 72
#define GLOW_HEALTH_MED_COLOR_B 0
#define GLOW_HEALTH_MED_FLASHING false

#define GLOW_HEALTH_LOW_TYPE L4D2_IsSurvivorGlowDisabled() ? L4D2Glow_None : L4D2Glow_Constant
#define GLOW_HEALTH_LOW_RANGE 0
#define GLOW_HEALTH_LOW_MINRANGE 0
#define GLOW_HEALTH_LOW_COLOR_R 80
#define GLOW_HEALTH_LOW_COLOR_G 0
#define GLOW_HEALTH_LOW_COLOR_B 0
#define GLOW_HEALTH_LOW_FLASHING false

#define GLOW_HEALTH_THIRDSTRIKE_TYPE L4D2_IsSurvivorGlowDisabled() ? L4D2Glow_None : L4D2Glow_Constant
#define GLOW_HEALTH_THIRDSTRIKE_RANGE 0
#define GLOW_HEALTH_THIRDSTRIKE_MINRANGE 0
#define GLOW_HEALTH_THIRDSTRIKE_COLOR_R 64
#define GLOW_HEALTH_THIRDSTRIKE_COLOR_G 64
#define GLOW_HEALTH_THIRDSTRIKE_COLOR_B 64
#define GLOW_HEALTH_THIRDSTRIKE_FLASHING true

/*
 * ==================================================
 *                     l4d_stocks
 * ==================================================
 */

#define L4DTeam_Survivor      2

#define L4D2Glow_None         0
#define L4D2Glow_OnUse        1
#define L4D2Glow_OnLookAt     2
#define L4D2Glow_Constant     3

/*
 * ==================================================
 *                     Includes
 * ==================================================
 */

/*
 * --------------------
 *       Globals
 * --------------------
 */
#include <sourcemod>
#include <sdktools>

/*
 * --------------------
 *       Modules
 * --------------------
 */

/*
 * ==================================================
 *                     macros.sp
 * ==================================================
 */

#define FOR_EACH_CLIENT_COND(%1,%2)                                            \
    for (int %1 = 1; %1 <= MaxClients; %1++)                                \
        if (%2)

#define FOR_EACH_CLIENT_IN_GAME(%1)                                            \
    FOR_EACH_CLIENT_COND(%1, IsClientInGame(%1))

#define FOR_EACH_CLIENT_CONNECTED(%1)                                        \
    FOR_EACH_CLIENT_COND(%1, IsClientConnected(%1))

#define FOR_EACH_CLIENT_ON_TEAM(%1,%2)                                        \
    FOR_EACH_CLIENT_IN_GAME(%1)                                                \
        if (GetClientTeam(%1) == %2)

#define FOR_EACH_SURVIVOR(%1)                                                \
    FOR_EACH_CLIENT_ON_TEAM(%1, L4DTeam_Survivor)

/*
 * ==================================================
 *                     Variables
 * ==================================================
 */

/*
 * --------------------
 *       Private
 * --------------------
 */

static bool  g_isGlowDisabled;
static bool  g_isPluginEnding;
static int   g_maxIncaps = 2;
static float g_fCvar_pain_pills_decay_rate;

static bool  g_isInGame[MAXPLAYERS + 1];
static bool  g_isIT[MAXPLAYERS + 1];

/*
 * ==================================================
 *                     Forwards
 * ==================================================
 */

public Plugin myinfo =
{
    name           = PLUGIN_FULLNAME,
    author         = PLUGIN_AUTHOR,
    description    = PLUGIN_DESCRIPTION,
    version        = PLUGIN_VERSION,
    url            = PLUGIN_URL
}

/**
 * Called on pre plugin start.
 *
 * @param myself        Handle to the plugin.
 * @param late          Whether or not the plugin was loaded "late" (after map load).
 * @param error         Error message buffer in case load failed.
 * @param err_max       Maximum number of characters for error message buffer.
 * @return              APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Plugin only support Left 4 Dead 2");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/**
 * Called on plugin start.
 *
 * @noreturn
 */
public void OnPluginStart()
{
    /* Plugin start up routine */
    CreateTrackingConVar();

    HookConVarChange(FindConVar("survivor_max_incapacitated_count"), OnIncapMax_ConVarChange);
    HookConVarChange(FindConVar("sv_disable_glow_survivors"), OnGlowDisable_ConVarChange);
    HookConVarChange(FindConVar("pain_pills_decay_rate"), PainPillsDecayRate_ConVarChange);

    /* SI grab events */
    HookEvent("pounce_end", UpdateGlow_Victim_Event);
    HookEvent("tongue_release", UpdateGlow_Victim_Event);
    HookEvent("jockey_ride_end", UpdateGlow_Victim_Event);
    HookEvent("charger_carry_end", UpdateGlow_Victim_Event);
    HookEvent("charger_pummel_end", UpdateGlow_Victim_Event);

    HookEvent("lunge_pounce", UpdateGlow_Victim_Event);
    HookEvent("tongue_grab", UpdateGlow_Victim_Event);
    HookEvent("jockey_ride", UpdateGlow_Victim_Event);
    HookEvent("charger_carry_start", UpdateGlow_Victim_Event);
    HookEvent("charger_pummel_start", UpdateGlow_Victim_Event);

    /* SI Boomer events */
    HookEvent("player_now_it", UpdateGlow_NowIT_Event);
    HookEvent("player_no_longer_it", UpdateGlow_NoLongerIt_Event);

    /* Survivor related events */
    HookEvent("revive_success", UpdateGlow_Subject_Event);
    HookEvent("heal_success", UpdateGlow_Subject_Event);
    HookEvent("player_incapacitated_start", UpdateGlow_UserId_Event);
    HookEvent("player_ledge_grab", UpdateGlow_UserId_Event);
    HookEvent("player_death", UpdateGlow_UserId_Event);
    HookEvent("defibrillator_used", UpdateGlow_Subject_Event);
    HookEvent("player_hurt", UpdateGlow_UserId_Event);

    HookEvent("player_bot_replace", UpdateGlow_Idle_Event);
    HookEvent("bot_player_replace", UpdateGlow_Idle_Event);
}

public void OnPluginEnd()
{
    g_isPluginEnding = true;

    FOR_EACH_CLIENT_IN_GAME(client)
    {
        L4D2_SetEntityGlow(client, L4D2Glow_None, 1, 0, { 0, 0 , 1 }, false);
        L4D2_RemoveEntityGlow(client);
    }
}

public void OnAllPluginsLoaded()
{
    g_maxIncaps = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
    g_isGlowDisabled = GetConVarBool(FindConVar("sv_disable_glow_survivors"));
    g_fCvar_pain_pills_decay_rate = GetConVarFloat(FindConVar("pain_pills_decay_rate"));

    FOR_EACH_CLIENT_IN_GAME(client)
    {
        g_isInGame[client] = true;
    }

    FOR_EACH_SURVIVOR(client)
    {
        UpdateSurvivorHealthGlow(client);
    }

    /* For people using admin cheats and other stuff that changes survivor health */
    CreateTimer(1.0, UpdateGlows_Timer, _, TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{
    if (client == 0)
    {
        return;
    }

    g_isInGame[client] = true;
}

public void OnClientDisconnect(int client)
{
    if (client == 0)
    {
        return;
    }

    g_isInGame[client] = false;
}

public void OnIncapMax_ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_maxIncaps = GetConVarInt(convar);
}

public void OnGlowDisable_ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_isGlowDisabled = GetConVarBool(convar);
}

public void PainPillsDecayRate_ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_fCvar_pain_pills_decay_rate = GetConVarFloat(convar);
}

public Action UpdateGlows_Timer(Handle timer)
{
    if (g_isPluginEnding)
    {
        return Plugin_Stop;
    }

    FOR_EACH_CLIENT_IN_GAME(client)
    {
        L4D2_SetEntityGlow(client, L4D2Glow_None, 1, 0, { 0, 0 , 1 }, false);
        L4D2_RemoveEntityGlow(client);
    }

    FOR_EACH_SURVIVOR(client)
    {
        UpdateSurvivorHealthGlow(client);
    }

    return Plugin_Continue;
}

public void UpdateGlow_UserId_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client] || GetClientTeam(client) != L4DTeam_Survivor)
    {
        return;
    }

    UpdateSurvivorHealthGlow(client);
}

public void UpdateGlow_Subject_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "subject"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client] || GetClientTeam(client) != L4DTeam_Survivor)
    {
        return;
    }

    UpdateSurvivorHealthGlow(client);
}

public void UpdateGlow_Victim_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "victim"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client] || GetClientTeam(client) != L4DTeam_Survivor)
    {
        return;
    }

    UpdateSurvivorHealthGlow(client);
}

public void UpdateGlow_NowIT_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client] || GetClientTeam(client) != L4DTeam_Survivor)
    {
        return;
    }

    g_isIT[client] = true;
    UpdateSurvivorHealthGlow(client);
}

public void UpdateGlow_NoLongerIt_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client] || GetClientTeam(client) != L4DTeam_Survivor)
    {
        return;
    }

    g_isIT[client] = false;
    UpdateSurvivorHealthGlow(client);
}

public void UpdateGlow_Idle_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "player"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client])
    {
        return;
    }

    int bot = GetClientOfUserId(GetEventInt(event, "bot"));

    UpdateSurvivorHealthGlow(client);
    UpdateSurvivorHealthGlow(bot);
}

/*
 * ==================================================
 *                     Public API
 * ==================================================
 */

void UpdateSurvivorHealthGlow(int client)
{
    if (g_isPluginEnding || !g_isInGame[client])
    {
        return;
    }

    if (GetClientTeam(client) != L4DTeam_Survivor || // If client isn't survivor
        !IsPlayerAlive(client) ||                            // or isn't alive
        L4D_IsPlayerIncapacitated(client) ||                 // or incapacitated
        L4D2_GetInfectedAttacker(client) > 0 ||              // or infected player is pining survivor
        g_isIT[client] ||                                    // or is IT (boomer vomit)
        !L4D2_IsPlayerSurvivorGlowEnable(client))            // or survivor glow is disabled on JUST this player
    {
        L4D2_SetEntityGlow(client, L4D2Glow_None, 1, 0, { 0, 0 , 1 }, false);
        L4D2_RemoveEntityGlow(client);
        return;
    }

    int health = GetClientHealth(client) + RoundToCeil(GetClientTempHealth(client));

    bool lastLife = L4D_GetPlayerReviveCount(client) >= L4D_GetMaxReviveCount();

    int type;
    int color[3];
    int range;
    int minRange;
    bool flashing;
    GetHealthGlowForClient(health, lastLife, type, range, minRange, color, flashing);

    L4D2_SetEntityGlow(client, type, range, minRange, color, flashing);
}

/*
 * ==================================================
 *                    Private API
 * ==================================================
 */

void GetHealthGlowForClient(int health, bool lastLife, int &type, int &range, int &minRange, int color[3], bool &flashing)
{
    if (lastLife)
    {
        type = GLOW_HEALTH_THIRDSTRIKE_TYPE;
        range = GLOW_HEALTH_THIRDSTRIKE_RANGE;
        minRange = GLOW_HEALTH_THIRDSTRIKE_MINRANGE;
        color = {GLOW_HEALTH_THIRDSTRIKE_COLOR_R, GLOW_HEALTH_THIRDSTRIKE_COLOR_G, GLOW_HEALTH_THIRDSTRIKE_COLOR_B};
        flashing = GLOW_HEALTH_THIRDSTRIKE_FLASHING;
        return;
    }

    if (health <= GLOW_HEALTH_LOW)
    {
        type = GLOW_HEALTH_LOW_TYPE;
        range = GLOW_HEALTH_LOW_RANGE;
        minRange = GLOW_HEALTH_LOW_MINRANGE;
        color = {GLOW_HEALTH_LOW_COLOR_R, GLOW_HEALTH_LOW_COLOR_G, GLOW_HEALTH_LOW_COLOR_B};
        flashing = GLOW_HEALTH_MED_FLASHING;
    }
    else if (health <= GLOW_HEALTH_MED)
    {
        type = GLOW_HEALTH_MED_TYPE;
        range = GLOW_HEALTH_MED_RANGE;
        minRange = GLOW_HEALTH_MED_MINRANGE;
        color = {GLOW_HEALTH_MED_COLOR_R, GLOW_HEALTH_MED_COLOR_G, GLOW_HEALTH_MED_COLOR_B};
        flashing = GLOW_HEALTH_MED_FLASHING;
    }
    else
    {
        type = GLOW_HEALTH_HIGH_TYPE;
        range = GLOW_HEALTH_HIGH_RANGE;
        minRange = GLOW_HEALTH_HIGH_MINRANGE;
        color = {GLOW_HEALTH_HIGH_COLOR_R, GLOW_HEALTH_HIGH_COLOR_G, GLOW_HEALTH_HIGH_COLOR_B};
        flashing = GLOW_HEALTH_HIGH_FLASHING;
    }
}

int L4D_GetMaxReviveCount()
{
    return g_maxIncaps;
}

bool L4D2_IsSurvivorGlowDisabled()
{
    return g_isGlowDisabled;
}

/**
 * Creates plugin tracking convar.
 *
 * @noreturn
 */
void CreateTrackingConVar()
{
#if defined CREATE_TRACKING_CVAR
    char cvarName[128];
    Format(cvarName, sizeof(cvarName), "%s_%s", PLUGIN_CVAR_PREFIX, "version");

    char desc[128];
    Format(desc, sizeof(desc), "%s SourceMod Plugin Version", PLUGIN_FULLNAME);

    ConVar cvar = CreateConVar(cvarName, PLUGIN_VERSION, desc, FCVAR_NOTIFY|FCVAR_DONTRECORD);
    SetConVarString(cvar, PLUGIN_VERSION);
#endif
}

/*
 * ==================================================
 *                     l4d_stocks
 * ==================================================
 */

/**
 * Set entity glow. This is consider safer and more robust over setting each glow
 * property on their own because glow offset will be check first.
 *
 * @param entity        Entity index.
 * @parma type          Glow type.
 * @param range         Glow max range, 0 for unlimited.
 * @param minRange      Glow min range.
 * @param colorOverride Glow color, RGB.
 * @param flashing      Whether the glow will be flashing.
 * @return              True if glow was set, false if entity does not support
 *                      glow.
 */
void L4D2_SetEntityGlow(int entity, int type, int range, int minRange, int colorOverride[3], bool flashing)
{
    if (!IsValidEntity(entity))
    {
        return;
    }

    char netclass[128];
    GetEntityNetClass(entity, netclass, 128);

    int offset = FindSendPropInfo(netclass, "m_iGlowType");

    if (offset < 1)
    {
        return;
    }

    L4D2_SetEntityGlow_Type(entity, type);
    L4D2_SetEntityGlow_Range(entity, range);
    L4D2_SetEntityGlow_MinRange(entity, minRange);
    L4D2_SetEntityGlow_Color(entity, colorOverride);
    L4D2_SetEntityGlow_Flashing(entity, flashing);
}

/**
 * Returns whether player is incapacitated.
 *
 * Note: A tank player will return true when in dying animation.
 *
 * @param client        Player index.
 * @return              True if incapacitated, false otherwise.
 * @error               Invalid client index.
 */
bool L4D_IsPlayerIncapacitated(int client)
{
    return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0;
}

/**
 * Set entity glow type.
 *
 * @param entity        Entity index.
 * @parma type          Glow type.
 * @noreturn
 * @error               Invalid entity index or entity does not support glow.
 */
void L4D2_SetEntityGlow_Type(int entity, int type)
{
    SetEntProp(entity, Prop_Send, "m_iGlowType", type);
}

/**
 * Set entity glow range.
 *
 * @param entity        Entity index.
 * @parma range         Glow range.
 * @noreturn
 * @error               Invalid entity index or entity does not support glow.
 */
void L4D2_SetEntityGlow_Range(int entity, int range)
{
    SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
}

/**
 * Set entity glow min range.
 *
 * @param entity        Entity index.
 * @parma minRange      Glow min range.
 * @noreturn
 * @error               Invalid entity index or entity does not support glow.
 */
void L4D2_SetEntityGlow_MinRange(int entity, int minRange)
{
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", minRange);
}

/**
 * Set entity glow color.
 *
 * @param entity        Entity index.
 * @parma colorOverride Glow color, RGB.
 * @noreturn
 * @error               Invalid entity index or entity does not support glow.
 */
void L4D2_SetEntityGlow_Color(int entity, int colorOverride[3])
{
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", colorOverride[0] + (colorOverride[1] * 256) + (colorOverride[2] * 65536));
}

/**
 * Set entity glow flashing state.
 *
 * @param entity        Entity index.
 * @parma flashing      Whether glow will be flashing.
 * @noreturn
 * @error               Invalid entity index or entity does not support glow.
 */
void L4D2_SetEntityGlow_Flashing(int entity, bool flashing)
{
    SetEntProp(entity, Prop_Send, "m_bFlashing", flashing);
}

/**
 * Removes entity glow.
 *
 * @param entity        Entity index.
 * @return              True if glow was removed, false if entity does not
 *                      support glow.
 */
void L4D2_RemoveEntityGlow(int entity)
{
    L4D2_SetEntityGlow(entity, L4D2Glow_None, 0, 0, { 0, 0, 0 }, false);
}

/**
 * Whether survivor glow for player is enabled.
 *
 * @param client        Client index.
 * @return              True if survivor glow is enabled, false otherwise.
 * @error               Invalid client index.
 */
bool L4D2_IsPlayerSurvivorGlowEnable(int client)
{
    return GetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled") > 0;
}

/**
 * Return player current revive count.
 *
 * @param client        Client index.
 * @return              Survivor's current revive count.
 * @error               Invalid client index.
 */
int L4D_GetPlayerReviveCount(int client)
{
    return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

/**
 * Returns infected attacker of survivor victim.
 *
 * Note: Infected attacker means the infected player that is currently
 * pinning down the survivor. Such as hunter, smoker, charger and jockey.
 *
 * @param client        Survivor client index.
 * @return              Infected attacker index, -1 if not found.
 * @error               Invalid client index.
 */
int L4D2_GetInfectedAttacker(int client)
{
    int attacker;

    /* Charger */
    attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
    if (attacker > 0)
    {
        return attacker;
    }

    attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
    if (attacker > 0)
    {
        return attacker;
    }

    /* Hunter */
    attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
    if (attacker > 0)
    {
        return attacker;
    }

    /* Smoker */
    attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
    if (attacker > 0)
    {
        return attacker;
    }

    /* Jockey */
    attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
    if (attacker > 0)
    {
        return attacker;
    }

    return -1;
}

/****************************************************************************************************/

// ====================================================================================================
// Thanks to Silvers
// ====================================================================================================
/**
 * Returns the client temporary health.
 *
 * @param client        Client index.
 * @return              Client temporary health.
 */
float GetClientTempHealth(int client)
{
    float health = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    health -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fCvar_pain_pills_decay_rate;
    return health < 0.0 ? 0.0 : health;
}