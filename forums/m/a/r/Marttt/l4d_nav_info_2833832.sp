/**
// ====================================================================================================
Change Log:

1.0.1 (12-February-2025)
    - Added beam life cvar.

1.0.0 (11-February-2025)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Nav Info"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Output some nav area information to the chat/console"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=350354"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#tryinclude <left4dhooks> // Download here: https://forums.alliedmods.net/showthread.php?t=321696

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_nav_info"

// ====================================================================================================
// Defines
// ====================================================================================================
#define ENTITY_WORLDSPAWN             0

#define MODEL_SPRITE                  "sprites/laserbeam.vmt"

// ====================================================================================================
// left4dhooks - Plugin Dependencies
// ====================================================================================================
#if !defined _l4dh_included
native Address L4D_GetNavAreaByID(int id);
native void L4D_GetNavAreaCenter(Address area, float vecPos[3]);
native int L4D_GetNavAreaID(Address area);
native void L4D_GetNavAreaPos(Address area, float vecPos[3]);
native void L4D_GetNavAreaSize(Address area, float vecSize[3]);
native int L4D_GetNavArea_AttributeFlags(Address pTerrorNavArea);
native int L4D_GetNavArea_SpawnAttributes(Address pTerrorNavArea);
native any L4D_GetNearestNavArea(const float vecPos[3], float maxDist = 300.0, bool anyZ = false, bool checkLOS = false, bool checkGround = false, int teamID = 2);

enum
{
    NAV_BASE_CROUCH = 1,
    NAV_BASE_JUMP = 2,
    NAV_BASE_PRECISE = 4,
    NAV_BASE_NO_JUMP = 8,
    NAV_BASE_STOP = 16,
    NAV_BASE_RUN = 32,
    NAV_BASE_WALK = 64,
    NAV_BASE_AVOID = 128,
    NAV_BASE_TRANSIENT = 256,
    NAV_BASE_DONT_HIDE = 512,
    NAV_BASE_STAND = 1024,
    NAV_BASE_NO_HOSTAGES = 2048,
    NAV_BASE_STAIRS = 4096,
    NAV_BASE_NO_MERGE = 8192,
    NAV_BASE_OBSTACLE_TOP = 16384,
    NAV_BASE_CLIFF = 32768,
    NAV_BASE_TANK_ONLY = 65536,
    NAV_BASE_MOB_ONLY = 131072,
    NAV_BASE_PLAYERCLIP = 262144,
    NAV_BASE_BREAKABLEWALL = 524288,
    NAV_BASE_FLOW_BLOCKED = 134217728,
    NAV_BASE_OUTSIDE_WORLD = 268435456,
    NAV_BASE_MOSTLY_FLAT = 536870912,
    NAV_BASE_HAS_ELEVATOR = 1073741824,
    NAV_BASE_NAV_BLOCKER = -2147483648
};

enum
{
    NAV_SPAWN_EMPTY = 2,
    NAV_SPAWN_STOP_SCAN = 4,
    NAV_SPAWN_BATTLESTATION = 32,
    NAV_SPAWN_FINALE = 64,
    NAV_SPAWN_PLAYER_START = 128,
    NAV_SPAWN_BATTLEFIELD = 256,
    NAV_SPAWN_IGNORE_VISIBILITY = 512,
    NAV_SPAWN_NOT_CLEARABLE = 1024,
    NAV_SPAWN_CHECKPOINT = 2048,
    NAV_SPAWN_OBSCURED = 4096,
    NAV_SPAWN_NO_MOBS = 8192,
    NAV_SPAWN_THREAT = 16384,
    NAV_SPAWN_RESCUE_VEHICLE = 32768,
    NAV_SPAWN_RESCUE_CLOSET = 65536,
    NAV_SPAWN_ESCAPE_ROUTE = 131072,
    NAV_SPAWN_DESTROYED_DOOR = 262144,
    NAV_SPAWN_NOTHREAT = 524288,
    NAV_SPAWN_LYINGDOWN = 1048576,
    NAV_SPAWN_COMPASS_NORTH = 16777216,
    NAV_SPAWN_COMPASS_NORTHEAST = 33554432,
    NAV_SPAWN_COMPASS_EAST = 67108864,
    NAV_SPAWN_COMPASS_EASTSOUTH = 134217728,
    NAV_SPAWN_COMPASS_SOUTH = 268435456,
    NAV_SPAWN_COMPASS_SOUTHWEST = 536870912,
    NAV_SPAWN_COMPASS_WEST = 1073741824,
    NAV_SPAWN_COMPASS_WESTNORTH = -2147483648
};
#endif

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d_nav_info_version;
    ConVar l4d_nav_info_enable;
    ConVar l4d_nav_info_max_dist;
    ConVar l4d_nav_info_beam_model;
    ConVar l4d_nav_info_beam_life;

    void Init()
    {
        this.l4d_nav_info_version    = CreateConVar("l4d_nav_info_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d_nav_info_enable     = CreateConVar("l4d_nav_info_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_nav_info_max_dist   = CreateConVar("l4d_nav_info_max_dist", "100.0", "Max distance to look for a nearby nav area.", CVAR_FLAGS, true, 0.0);
        this.l4d_nav_info_beam_model = CreateConVar("l4d_nav_info_beam_model", "sprites/laserbeam.vmt", "Beam model.");
        this.l4d_nav_info_beam_life  = CreateConVar("l4d_nav_info_beam_life", "10.0", "Beam life duration.", CVAR_FLAGS, true, 0.0);

        this.l4d_nav_info_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d_nav_info_max_dist.AddChangeHook(Event_ConVarChanged);
        this.l4d_nav_info_beam_model.AddChangeHook(Event_ConVarChanged);
        this.l4d_nav_info_beam_life.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    bool left4DHooks;
    bool enable;
    float maxDist;
    char beamModel[PLATFORM_MAX_PATH];
    int beamModelIndex;
    float beamLife;

    void Init()
    {
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.l4d_nav_info_enable.BoolValue;
        this.maxDist = this.cvars.l4d_nav_info_max_dist.FloatValue;
        this.cvars.l4d_nav_info_beam_model.GetString(this.beamModel, sizeof(this.beamModel));
        TrimString(this.beamModel);
        if (this.beamModel[0] != 0)
            plugin.beamModelIndex = PrecacheModel(plugin.beamModel, true);
        this.beamLife = this.cvars.l4d_nav_info_beam_life.FloatValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_navinfo", Cmd_NavInfo, ADMFLAG_ROOT, "Displays information about the nav area which your crosshair is over or by specifying a nav area id.");
        RegAdminCmd("sm_print_cvars_l4d_nav_info", Cmd_PrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }

    void SetupBeamPoints(int client, float start[3], float end[3], int color[4], float width)
    {
        float beamStart[3];
        beamStart = start;
        beamStart[2] += width;

        float beamEnd[3];
        beamEnd = end;
        beamEnd[2] += width;

        TE_SetupBeamPoints(beamStart, beamEnd, plugin.beamModelIndex, 0, 0, 0, plugin.beamLife, width, width, 0, 0.0, color, 0);
        TE_SendToClient(client);
    }
}

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    #if !defined _l4dh_included
    MarkNativeAsOptional("L4D_GetNavAreaByID");
    MarkNativeAsOptional("L4D_GetNavAreaCenter");
    MarkNativeAsOptional("L4D_GetNavAreaID");
    MarkNativeAsOptional("L4D_GetNavAreaPos");
    MarkNativeAsOptional("L4D_GetNavAreaSize");
    MarkNativeAsOptional("L4D_GetNavArea_AttributeFlags");
    MarkNativeAsOptional("L4D_GetNavArea_SpawnAttributes");
    MarkNativeAsOptional("L4D_GetNearestNavArea");
    #endif

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    plugin.Init();
}

/****************************************************************************************************/

public void OnAllPluginsLoaded()
{
    plugin.left4DHooks = (GetFeatureStatus(FeatureType_Native, "L4D_GetNavAreaID") == FeatureStatus_Available);
}

/****************************************************************************************************/

public void OnMapStart()
{
    if (plugin.enable && plugin.beamModel[0] != 0)
        plugin.beamModelIndex = PrecacheModel(plugin.beamModel, true);
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    plugin.GetCvarValues();
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action Cmd_PrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------------- Plugin Cvars (l4d_nav_info) --------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_nav_info_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_nav_info_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "l4d_nav_info_max_dist : %.1f", plugin.maxDist);
    PrintToConsole(client, "l4d_nav_info_beam_model : \"%s\"", plugin.beamModel);
    PrintToConsole(client, "l4d_nav_info_beam_life : %.1f", plugin.beamLife);
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "left4dhooks : %s", plugin.left4DHooks ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action Cmd_NavInfo(int client, int args)
{
    if (!plugin.enable)
        return Plugin_Handled;

    if (!IsValidClient(client))
    {
        PrintToChat(client, "Invalid client (%i)", client);
        return Plugin_Handled;
    }

    Address navArea;
    int navAreaId;
    float vTracePos[3];

    if (args > 0)
    {
        char sArg[11];
        GetCmdArg(1, sArg, sizeof(sArg));

        navAreaId = StringToInt(sArg);
        if (navAreaId == 0)
        {
            PrintToChat(client, "Invalid nav area id parameter (\"%s\", expected an int value)", sArg);
            return Plugin_Handled;
        }

        navArea = L4D_GetNavAreaByID(navAreaId);
        if (!navArea)
        {
            PrintToChat(client, "Nav area id \"%i\" not found", navAreaId);
            return Plugin_Handled;
        }
    }

    if (!navArea)
    {
        float vPos[3];
        GetClientEyePosition(client, vPos);

        float vAng[3];
        GetClientEyeAngles(client, vAng);

        Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_ALL, RayType_Infinite, TraceFilterWorld);
        if (TR_DidHit(trace))
        {
            TR_GetEndPosition(vTracePos, trace);
            delete trace;

            PrintToChat(client, "Searching for nearby (%.1f range) nav area at: %.1f %.1f %.1f", plugin.maxDist, vTracePos[0], vTracePos[1], vTracePos[2]);

            navArea = L4D_GetNearestNavArea(vTracePos, plugin.maxDist);
            if (!navArea)
            {
                PrintToChat(client, "Nav area not found at %.1f %.1f %.1f", vTracePos[0], vTracePos[1], vTracePos[2]);
                return Plugin_Handled;
            }
        }
        else
        {
            delete trace;

            PrintToChat(client, "Trace hit nothing");
            return Plugin_Handled;
        }
    }

    PrintToChat(client, "Nav area address found: %i", navArea);

    if (navAreaId == 0)
        navAreaId = L4D_GetNavAreaID(navArea);
    PrintToChat(client, "Nav area id: %i", navAreaId);

    float vOrigin[3];
    L4D_GetNavAreaPos(navArea, vOrigin);
    PrintToChat(client, "Nav area origin: %.1f %.1f %.1f", vOrigin[0], vOrigin[1], vOrigin[2]);

    float vCenter[3];
    L4D_GetNavAreaCenter(navArea, vCenter);
    PrintToChat(client, "Nav area center: %.1f %.1f %.1f", vCenter[0], vCenter[1], vCenter[2]);

    float vSize[3];
    L4D_GetNavAreaSize(navArea, vSize);
    PrintToChat(client, "Nav area size: %.1f %.1f %.1f", vSize[0], vSize[1], vSize[2]);

    // Names retrieved from https://developer.valvesoftware.com/wiki/List_of_L4D_Series_Nav_Mesh_Attributes
    int navAttributeFlags = L4D_GetNavArea_AttributeFlags(navArea);
    PrintToChat(client, "Nav area base attributes: %i", navAttributeFlags);

    if (navAttributeFlags > 0)
    {
        if (navAttributeFlags & NAV_BASE_CROUCH) PrintToChat(client, "- CROUCH (%i)", NAV_BASE_CROUCH);
        if (navAttributeFlags & NAV_BASE_JUMP) PrintToChat(client, "- JUMP (%i)", NAV_BASE_JUMP);
        if (navAttributeFlags & NAV_BASE_PRECISE) PrintToChat(client, "- PRECISE (%i)", NAV_BASE_PRECISE);
        if (navAttributeFlags & NAV_BASE_NO_JUMP) PrintToChat(client, "- NO_JUMP (%i)", NAV_BASE_NO_JUMP);
        if (navAttributeFlags & NAV_BASE_STOP) PrintToChat(client, "- STOP (%i)", NAV_BASE_STOP);
        if (navAttributeFlags & NAV_BASE_RUN) PrintToChat(client, "- RUN (%i)", NAV_BASE_RUN);
        if (navAttributeFlags & NAV_BASE_WALK) PrintToChat(client, "- WALK (%i)", NAV_BASE_WALK);
        if (navAttributeFlags & NAV_BASE_AVOID) PrintToChat(client, "- AVOID (%i)", NAV_BASE_AVOID);
        if (navAttributeFlags & NAV_BASE_TRANSIENT) PrintToChat(client, "- TRANSIENT (%i)", NAV_BASE_TRANSIENT);
        if (navAttributeFlags & NAV_BASE_DONT_HIDE) PrintToChat(client, "- DONT_HIDE (%i)", NAV_BASE_DONT_HIDE);
        if (navAttributeFlags & NAV_BASE_STAND) PrintToChat(client, "- STAND (%i)", NAV_BASE_STAND);
        if (navAttributeFlags & NAV_BASE_NO_HOSTAGES) PrintToChat(client, "- NO_HOSTAGES (%i)", NAV_BASE_NO_HOSTAGES);
        if (navAttributeFlags & NAV_BASE_STAIRS) PrintToChat(client, "- STAIRS (%i)", NAV_BASE_STAIRS);
        if (navAttributeFlags & NAV_BASE_NO_MERGE) PrintToChat(client, "- NO_MERGE (%i)", NAV_BASE_NO_MERGE);
        if (navAttributeFlags & NAV_BASE_OBSTACLE_TOP) PrintToChat(client, "- OBSTACLE_TOP (%i)", NAV_BASE_OBSTACLE_TOP);
        if (navAttributeFlags & NAV_BASE_CLIFF) PrintToChat(client, "- CLIFF (%i)", NAV_BASE_CLIFF);
        if (navAttributeFlags & NAV_BASE_TANK_ONLY) PrintToChat(client, "- TANK_ONLY (%i)", NAV_BASE_TANK_ONLY);
        if (navAttributeFlags & NAV_BASE_MOB_ONLY) PrintToChat(client, "- MOB_ONLY (%i)", NAV_BASE_MOB_ONLY);
        if (navAttributeFlags & NAV_BASE_PLAYERCLIP) PrintToChat(client, "- PLAYERCLIP (%i)", NAV_BASE_PLAYERCLIP);
        if (navAttributeFlags & NAV_BASE_BREAKABLEWALL) PrintToChat(client, "- BREAKABLEWALL (%i)", NAV_BASE_BREAKABLEWALL);
        if (navAttributeFlags & NAV_BASE_FLOW_BLOCKED) PrintToChat(client, "- NAV_MESH_FLOW_BLOCKED (%i)", NAV_BASE_FLOW_BLOCKED);
        if (navAttributeFlags & NAV_BASE_OUTSIDE_WORLD) PrintToChat(client, "- NAV_MESH_OUTSIDE_WORLD (%i)", NAV_BASE_OUTSIDE_WORLD);
        if (navAttributeFlags & NAV_BASE_MOSTLY_FLAT) PrintToChat(client, "- NAV_MESH_MOSTLY_FLAT (%i)", NAV_BASE_MOSTLY_FLAT);
        if (navAttributeFlags & NAV_BASE_HAS_ELEVATOR) PrintToChat(client, "- NAV_MESH_HAS_ELEVATOR (%i)", NAV_BASE_HAS_ELEVATOR);
        if (navAttributeFlags & NAV_BASE_NAV_BLOCKER) PrintToChat(client, "- NAV_MESH_NAV_BLOCKER (%i)", NAV_BASE_NAV_BLOCKER);
    }

    int navSpawnAttributes = L4D_GetNavArea_SpawnAttributes(navArea);
    PrintToChat(client, "Nav area spawn attributes: %i", navSpawnAttributes);

    if (navSpawnAttributes > 0)
    {
        if (navSpawnAttributes & NAV_SPAWN_EMPTY) PrintToChat(client, "- EMPTY (%i)", NAV_SPAWN_EMPTY);
        if (navSpawnAttributes & NAV_SPAWN_STOP_SCAN) PrintToChat(client, "- STOP_SCAN (%i)", NAV_SPAWN_STOP_SCAN);
        if (navSpawnAttributes & NAV_SPAWN_BATTLESTATION) PrintToChat(client, "- BATTLESTATION (%i)", NAV_SPAWN_BATTLESTATION);
        if (navSpawnAttributes & NAV_SPAWN_FINALE) PrintToChat(client, "- FINALE (%i)", NAV_SPAWN_FINALE);
        if (navSpawnAttributes & NAV_SPAWN_PLAYER_START) PrintToChat(client, "- PLAYER_START (%i)", NAV_SPAWN_PLAYER_START);
        if (navSpawnAttributes & NAV_SPAWN_BATTLEFIELD) PrintToChat(client, "- BATTLEFIELD (%i)", NAV_SPAWN_BATTLEFIELD);
        if (navSpawnAttributes & NAV_SPAWN_IGNORE_VISIBILITY) PrintToChat(client, "- IGNORE_VISIBILITY (%i)", NAV_SPAWN_IGNORE_VISIBILITY);
        if (navSpawnAttributes & NAV_SPAWN_NOT_CLEARABLE) PrintToChat(client, "- NOT_CLEARABLE (%i)", NAV_SPAWN_NOT_CLEARABLE);
        if (navSpawnAttributes & NAV_SPAWN_CHECKPOINT) PrintToChat(client, "- CHECKPOINT (%i)", NAV_SPAWN_CHECKPOINT);
        if (navSpawnAttributes & NAV_SPAWN_OBSCURED) PrintToChat(client, "- OBSCURED (%i)", NAV_SPAWN_OBSCURED);
        if (navSpawnAttributes & NAV_SPAWN_NO_MOBS) PrintToChat(client, "- NO_MOBS (%i)", NAV_SPAWN_NO_MOBS);
        if (navSpawnAttributes & NAV_SPAWN_THREAT) PrintToChat(client, "- THREAT (%i)", NAV_SPAWN_THREAT);
        if (navSpawnAttributes & NAV_SPAWN_RESCUE_VEHICLE) PrintToChat(client, "- RESCUE_VEHICLE (%i)", NAV_SPAWN_RESCUE_VEHICLE);
        if (navSpawnAttributes & NAV_SPAWN_RESCUE_CLOSET) PrintToChat(client, "- RESCUE_CLOSET (%i)", NAV_SPAWN_RESCUE_CLOSET);
        if (navSpawnAttributes & NAV_SPAWN_ESCAPE_ROUTE) PrintToChat(client, "- ESCAPE_ROUTE (%i)", NAV_SPAWN_ESCAPE_ROUTE);
        if (navSpawnAttributes & NAV_SPAWN_DESTROYED_DOOR) PrintToChat(client, "- DESTROYED_DOOR (%i)", NAV_SPAWN_DESTROYED_DOOR); // DOOR
        if (navSpawnAttributes & NAV_SPAWN_NOTHREAT) PrintToChat(client, "- NOTHREAT (%i)", NAV_SPAWN_NOTHREAT);
        if (navSpawnAttributes & NAV_SPAWN_LYINGDOWN) PrintToChat(client, "- LYINGDOWN (%i)", NAV_SPAWN_LYINGDOWN);
        if (navSpawnAttributes & NAV_SPAWN_COMPASS_NORTH) PrintToChat(client, "- COMPASS_NORTH (%i)", NAV_SPAWN_COMPASS_NORTH);
        if (navSpawnAttributes & NAV_SPAWN_COMPASS_NORTHEAST) PrintToChat(client, "- COMPASS_NORTHEAST (%i)", NAV_SPAWN_COMPASS_NORTHEAST);
        if (navSpawnAttributes & NAV_SPAWN_COMPASS_EAST) PrintToChat(client, "- COMPASS_EAST (%i)", NAV_SPAWN_COMPASS_EAST);
        if (navSpawnAttributes & NAV_SPAWN_COMPASS_EASTSOUTH) PrintToChat(client, "- COMPASS_EASTSOUTH (%i)", NAV_SPAWN_COMPASS_EASTSOUTH);
        if (navSpawnAttributes & NAV_SPAWN_COMPASS_SOUTH) PrintToChat(client, "- COMPASS_SOUTH (%i)", NAV_SPAWN_COMPASS_SOUTH);
        if (navSpawnAttributes & NAV_SPAWN_COMPASS_SOUTHWEST) PrintToChat(client, "- COMPASS_SOUTHWEST (%i)", NAV_SPAWN_COMPASS_SOUTHWEST);
        if (navSpawnAttributes & NAV_SPAWN_COMPASS_WEST) PrintToChat(client, "- COMPASS_WEST (%i)", NAV_SPAWN_COMPASS_WEST);
        if (navSpawnAttributes & NAV_SPAWN_COMPASS_WESTNORTH) PrintToChat(client, "- COMPASS_WESTNORTH (%i)", NAV_SPAWN_COMPASS_WESTNORTH);
    }

    float vLaserStart[3];
    float vLaserEnd[3];

    // Trace - START
    if (args == 0)
    {
        vLaserStart = vTracePos;
        vLaserEnd = vLaserStart;
        vLaserEnd[2] += 70.0;
        plugin.SetupBeamPoints(client, vLaserStart, vLaserEnd, {255, 255, 255, 255}, 0.5);
    }
    // Trace - END

    // Laser center - START
    vLaserStart = vCenter;
    vLaserEnd = vLaserStart;
    vLaserEnd[2] += 70.0;
    plugin.SetupBeamPoints(client, vLaserStart, vLaserEnd, {255, 0, 0, 255}, 0.5);
    // Laser center - END

    // Laser origin - START
    vLaserStart = vOrigin;
    vLaserEnd = vLaserStart;
    vLaserEnd[2] += 70.0;
    plugin.SetupBeamPoints(client, vLaserStart, vLaserEnd, {0, 0, 255, 255}, 0.5);
    // Laser origin - END

    // Laser area - START
    vLaserEnd = vLaserStart;
    vLaserEnd[0] += vSize[0];
    plugin.SetupBeamPoints(client, vLaserStart, vLaserEnd, {0, 255, 0, 255}, 0.5);

    vLaserStart = vLaserEnd;
    vLaserEnd = vLaserStart;
    vLaserEnd[2] += 70.0;
    plugin.SetupBeamPoints(client, vLaserStart, vLaserEnd, {0, 255, 0, 255}, 0.5);
    vLaserEnd = vLaserStart;
    vLaserEnd[1] += vSize[1];
    plugin.SetupBeamPoints(client, vLaserStart, vLaserEnd, {0, 255, 0, 255}, 0.5);

    vLaserStart = vLaserEnd;
    vLaserEnd = vLaserStart;
    vLaserEnd[2] += 70.0;
    plugin.SetupBeamPoints(client, vLaserStart, vLaserEnd, {0, 255, 0, 255}, 0.5);
    vLaserEnd = vLaserStart;
    vLaserEnd[0] -= vSize[0];
    plugin.SetupBeamPoints(client, vLaserStart, vLaserEnd, {0, 255, 0, 255}, 0.5);

    vLaserStart = vLaserEnd;
    vLaserEnd = vLaserStart;
    vLaserEnd[2] += 70.0;
    plugin.SetupBeamPoints(client, vLaserStart, vLaserEnd, {0, 255, 0, 255}, 0.5);
    vLaserEnd = vLaserStart;
    vLaserEnd[1] -= vSize[1];
    plugin.SetupBeamPoints(client, vLaserStart, vLaserEnd, {0, 255, 0, 255}, 0.5);
    // Laser area - END

    return Plugin_Handled;
}

/****************************************************************************************************/

public bool TraceFilterWorld(int entity, int contentsMask)
{
    return (entity == ENTITY_WORLDSPAWN);
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if is a valid client index.
 *
 * @param client        Client index.
 * @return              True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client        Client index.
 * @return              True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}