/**
// ====================================================================================================
Change Log:

1.0.0 (25-Jan-2024)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[ND] Beam Resource Points"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Creates a beam distinguishing captured resource points by color"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=345617"

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
#define CONFIG_FILENAME               "nd_resource_point_beam"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_CONSORTIUM               2
#define TEAM_EMPIRE                   3

#define ENTITY_WORLDSPAWN             0

#define ENV_BEAM_SPAWNFLAG_START_ON   1

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar nd_resource_point_beam_version;
    ConVar nd_resource_point_beam_enable;
    ConVar nd_resource_point_beam_alpha;
    ConVar nd_resource_point_beam_model;
    ConVar nd_resource_point_beam_width_start;
    ConVar nd_resource_point_beam_width_end;
    ConVar nd_resource_point_beam_height;
    ConVar nd_resource_point_beam_color_consortium;
    ConVar nd_resource_point_beam_color_empire;
    ConVar nd_resource_point_beam_color_none;
    ConVar nd_resource_point_beam_timer_toogle;

    void Init()
    {
        this.nd_resource_point_beam_version          = CreateConVar("nd_resource_point_beam_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.nd_resource_point_beam_enable           = CreateConVar("nd_resource_point_beam_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.nd_resource_point_beam_alpha            = CreateConVar("nd_resource_point_beam_alpha", "255", "Beam alpha.\n0 = Disable.", CVAR_FLAGS, true, 0.0, true, 255.0);
        this.nd_resource_point_beam_model            = CreateConVar("nd_resource_point_beam_model", "sprites/widestripe.vmt", "Beam model.");
        this.nd_resource_point_beam_width_start      = CreateConVar("nd_resource_point_beam_width_start", "50.0", "Beam start width.", CVAR_FLAGS, true, 0.0);
        this.nd_resource_point_beam_width_end        = CreateConVar("nd_resource_point_beam_width_end", "0.0", "Beam end width.", CVAR_FLAGS, true, 0.0);
        this.nd_resource_point_beam_height           = CreateConVar("nd_resource_point_beam_height", "0.0", "Beam height.\n0 = World Max.", CVAR_FLAGS, true, 0.0);
        this.nd_resource_point_beam_color_consortium = CreateConVar("nd_resource_point_beam_color_consortium", "0 0 255", "Beam color for consortium faction.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
        this.nd_resource_point_beam_color_empire     = CreateConVar("nd_resource_point_beam_color_empire", "255 0 0", "Beam color for consortium faction.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
        this.nd_resource_point_beam_color_none       = CreateConVar("nd_resource_point_beam_color_none", "255 255 255", "Beam color for uncaptured resources.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
        this.nd_resource_point_beam_timer_toogle     = CreateConVar("nd_resource_point_beam_timer_toogle", "0.5", "How often should check for capturing resources to toogle the color.\n0 = OFF.", CVAR_FLAGS, true, 0.0);

        this.nd_resource_point_beam_enable.AddChangeHook(Event_ConVarChanged);
        this.nd_resource_point_beam_alpha.AddChangeHook(Event_ConVarChanged);
        this.nd_resource_point_beam_model.AddChangeHook(Event_ConVarChanged);
        this.nd_resource_point_beam_width_start.AddChangeHook(Event_ConVarChanged);
        this.nd_resource_point_beam_width_end.AddChangeHook(Event_ConVarChanged);
        this.nd_resource_point_beam_height.AddChangeHook(Event_ConVarChanged);
        this.nd_resource_point_beam_color_consortium.AddChangeHook(Event_ConVarChanged);
        this.nd_resource_point_beam_color_empire.AddChangeHook(Event_ConVarChanged);
        this.nd_resource_point_beam_color_none.AddChangeHook(Event_ConVarChanged);
        this.nd_resource_point_beam_timer_toogle.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    ArrayList alEntityData;
    Handle tCaptureCheck;

    bool mapStarted;
    bool eventsHooked;
    bool enable;
    int alpha;
    char model[PLATFORM_MAX_PATH];
    float widthStart;
    float widthEnd;
    float height;
    char colorConsortium[12];
    int iColorConsortium;
    char colorEmpire[12];
    int iColorEmpire;
    char colorNone[12];
    int iColorNone;
    float timerToogle;

    void Init()
    {
        this.alEntityData = new ArrayList(sizeof(EntityData));
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.nd_resource_point_beam_enable.BoolValue;
        this.alpha = this.cvars.nd_resource_point_beam_alpha.IntValue;
        this.cvars.nd_resource_point_beam_model.GetString(this.model, sizeof(this.model));
        TrimString(this.model);
        if (this.enable && this.model[0] != 0)
            PrecacheModel(plugin.model, true);
        this.widthStart = this.cvars.nd_resource_point_beam_width_start.FloatValue;
        this.widthEnd = this.cvars.nd_resource_point_beam_width_end.FloatValue;
        this.height = this.cvars.nd_resource_point_beam_height.FloatValue;
        this.cvars.nd_resource_point_beam_color_consortium.GetString(this.colorConsortium, sizeof(this.colorConsortium));
        TrimString(this.colorConsortium);
        this.iColorConsortium = ConvertRGBToInt(this.colorConsortium);
        this.cvars.nd_resource_point_beam_color_empire.GetString(this.colorEmpire, sizeof(this.colorEmpire));
        TrimString(this.colorEmpire);
        this.iColorEmpire = ConvertRGBToInt(this.colorEmpire);
        this.cvars.nd_resource_point_beam_color_none.GetString(this.colorNone, sizeof(this.colorNone));
        TrimString(this.colorNone);
        this.iColorNone = ConvertRGBToInt(this.colorNone);
        this.timerToogle = this.cvars.nd_resource_point_beam_timer_toogle.FloatValue;

        delete this.tCaptureCheck;
        if (this.enable && this.timerToogle > 0.0)
            this.tCaptureCheck = CreateTimer(this.timerToogle, Timer_CaptureCheck, _, TIMER_REPEAT);
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_nd_resource_point_beam", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }

    void HookEvents()
    {
        if (this.enable && !this.eventsHooked)
        {
            this.eventsHooked = true;

            HookEvent("resource_captured", Event_ResourceCaptured);
            HookEvent("resource_start_capture", Event_ResourceStartCapture);
            HookEvent("resource_end_capture", Event_ResourceEndCapture);

            return;
        }

        if (!this.enable && this.eventsHooked)
        {
            this.eventsHooked = false;

            UnhookEvent("resource_captured", Event_ResourceCaptured);
            UnhookEvent("resource_start_capture", Event_ResourceStartCapture);
            UnhookEvent("resource_end_capture", Event_ResourceEndCapture);

            return;
        }
    }

    void LateLoad()
    {
        this.RemoveAll();
        this.LateLoadAll();
    }

    void RemoveAll()
    {
        for (int i = 0; i < this.alEntityData.Length; i++)
        {
            EntityData entityData;
            this.alEntityData.GetArray(i, entityData, sizeof(entityData));

            int beam = EntRefToEntIndex(entityData.beamRef);

            if (beam == INVALID_ENT_REFERENCE)
                continue;

            RemoveEntity(beam);
        }

        delete this.alEntityData;
        this.alEntityData = new ArrayList(sizeof(EntityData));
    }

    void LateLoadAll()
    {
        if (!this.enable)
            return;

        int entity;

        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "nd_info_primary_resource_point")) != INVALID_ENT_REFERENCE)
        {
            OnSpawnPost(entity);
        }

        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "nd_info_secondary_resource_point")) != INVALID_ENT_REFERENCE)
        {
            OnSpawnPost(entity);
        }

        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "nd_info_tertiary_resource_point")) != INVALID_ENT_REFERENCE)
        {
            OnSpawnPost(entity);
        }
    }

    void CreateBeam(int entity)
    {
        int find = plugin.alEntityData.FindValue(EntIndexToEntRef(entity), EntityData::entRef);

        // If not found, add entity entry to array
        if (find == -1)
        {
            EntityData entityData;
            entityData.Init();
            entityData.entRef = EntIndexToEntRef(entity);
            find = plugin.alEntityData.PushArray(entityData, sizeof(entityData));
        }

        EntityData entityData;
        plugin.alEntityData.GetArray(find, entityData, sizeof(entityData));

        if (EntRefToEntIndex(entityData.beamRef) != INVALID_ENT_REFERENCE)
            return;

        float vPos[3];
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);

        float vEndPos[3];
        vEndPos[0] = vPos[0];
        vEndPos[1] = vPos[1];

        if (plugin.height == 0.0)
        {
            float vWorldMaxs[3];
            GetEntPropVector(ENTITY_WORLDSPAWN, Prop_Data, "m_WorldMaxs", vWorldMaxs);
            vEndPos[2] = vWorldMaxs[2];
        }
        else
        {
            vEndPos[2] = (vPos[2] + plugin.height);
        }

        int beam = CreateEntityByName("env_beam");

        entityData.beamRef = EntIndexToEntRef(beam);
        entityData.beamPos = vPos;
        plugin.alEntityData.SetArray(find, entityData, sizeof(entityData));

        SetEntityModel(beam, plugin.model); // Otherwise must set "model" and "modelindex" to work
        DispatchKeyValueInt(beam, "spawnflags", ENV_BEAM_SPAWNFLAG_START_ON);
        DispatchKeyValueInt(beam, "renderamt", plugin.alpha);
        DispatchKeyValueVector(beam, "origin", vPos);
        SetEntPropVector(beam, Prop_Data, "m_vecEndPos", vEndPos);
        SetEntPropFloat(beam, Prop_Data, "m_fWidth", plugin.widthStart);
        SetEntPropFloat(beam, Prop_Data, "m_fEndWidth", plugin.widthEnd);

        plugin.SetResourcePointBeamColor(entity);

        DispatchSpawn(beam);
    }

    /****************************************************************************************************/

    void SetResourcePointBeamColor(int entity)
    {
        int find = plugin.alEntityData.FindValue(EntIndexToEntRef(entity), EntityData::entRef);

        if (find == -1)
            return;

        EntityData entityData;
        plugin.alEntityData.GetArray(find, entityData, sizeof(entityData));

        int beam = EntRefToEntIndex(entityData.beamRef);

        if (beam == INVALID_ENT_REFERENCE)
            return;

        bool capturing = (GetEntProp(entity, Prop_Send, "m_bCapturing") == 1);

        int iColor;
        if (capturing && entityData.beamToogle)
        {
            int capturingTeam = GetEntProp(entity, Prop_Send, "m_iCapturingTeam");
            switch (capturingTeam)
            {
                case TEAM_CONSORTIUM: iColor = plugin.iColorConsortium;
                case TEAM_EMPIRE: iColor = plugin.iColorEmpire;
                default: iColor = plugin.iColorNone;
            }
        }
        else
        {
            int team = GetEntProp(entity, Prop_Send, "m_iOwnerTeam");
            switch (team)
            {
                case TEAM_CONSORTIUM: iColor = plugin.iColorConsortium;
                case TEAM_EMPIRE: iColor = plugin.iColorEmpire;
                default: iColor = plugin.iColorNone;
            }
        }

        if (entityData.lastBeamColor != iColor)
        {
            SetEntProp(beam, Prop_Send, "m_clrRender", iColor);
            entityData.lastBeamColor = iColor;
            plugin.alEntityData.SetArray(find, entityData, sizeof(entityData));
        }
    }
}

/****************************************************************************************************/

enum struct EntityData
{
    int entRef;
    int beamRef;
    bool capturing;
    bool beamToogle;
    float beamPos[3];
    int lastBeamColor;

    void Init()
    {
        this.entRef = INVALID_ENT_REFERENCE;
        this.beamRef = INVALID_ENT_REFERENCE;
        this.capturing = false;
        this.beamToogle = false;
        this.beamPos = {0.0, 0.0, 0.0};
        this.lastBeamColor = -1;
    }
}

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_NuclearDawn)
    {
        strcopy(error, err_max, "This plugin only runs in \"Nuclear Dawn\" game");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    plugin.Init();
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    plugin.RemoveAll();
}

/****************************************************************************************************/

public void OnMapStart()
{
    plugin.mapStarted = true;

    if (plugin.enable && plugin.model[0] != 0)
        PrecacheModel(plugin.model, true);
}

/****************************************************************************************************/

public void OnMapEnd()
{
    plugin.mapStarted = false;
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    plugin.GetCvarValues();
    plugin.HookEvents();
    plugin.LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!plugin.mapStarted)
        return;

    if (!plugin.enable)
        return;

    if (entity < 0)
        return;

    if (StrEqual(classname, "nd_info_primary_resource_point"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
        return;
    }

    if (StrEqual(classname, "nd_info_secondary_resource_point"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
        return;
    }

    if (StrEqual(classname, "nd_info_tertiary_resource_point"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
        return;
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!plugin.enable)
        return;

    if (entity < 0)
        return;

    int find;

    find = -1;
    while ((find = plugin.alEntityData.FindValue(EntIndexToEntRef(entity), EntityData::entRef)) != -1)
    {
        plugin.alEntityData.Erase(find);
    }

    find = -1;
    while ((find = plugin.alEntityData.FindValue(EntIndexToEntRef(entity), EntityData::beamRef)) != -1)
    {
        EntityData entityData;
        plugin.alEntityData.GetArray(find, entityData, sizeof(entityData));
        entityData.beamRef = INVALID_ENT_REFERENCE;
        plugin.alEntityData.SetArray(find, entityData, sizeof(entityData));
    }
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    RequestFrame(Frame_SpawnPost, EntIndexToEntRef(entity)); // some plugins teleport after spawning so the position is only updated in the next frame
}

/****************************************************************************************************/

void Frame_SpawnPost(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    plugin.CreateBeam(entity);
}

/****************************************************************************************************/

void Event_ResourceCaptured(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("entindex");
    RequestFrame(Frame_Capture, EntIndexToEntRef(entity)); // capturing props are only updated in the next frame
}

/****************************************************************************************************/

void Event_ResourceStartCapture(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("entindex");

    int find = plugin.alEntityData.FindValue(EntIndexToEntRef(entity), EntityData::entRef);

    if (find == -1)
        return;

    EntityData entityData;
    plugin.alEntityData.GetArray(find, entityData, sizeof(entityData));
    entityData.capturing = true;
    plugin.alEntityData.SetArray(find, entityData, sizeof(entityData));

    RequestFrame(Frame_Capture, EntIndexToEntRef(entity)); // capturing props are only updated in the next frame
}

/****************************************************************************************************/

void Event_ResourceEndCapture(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("entindex");
    RequestFrame(Frame_Capture, EntIndexToEntRef(entity)); // capturing props are only updated in the next frame
}

/****************************************************************************************************/

void Frame_Capture(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    plugin.SetResourcePointBeamColor(entity);
}

/****************************************************************************************************/

Action Timer_CaptureCheck(Handle timer)
{
    for (int i = 0; i < plugin.alEntityData.Length; i++)
    {
        EntityData entityData;
        plugin.alEntityData.GetArray(i, entityData, sizeof(entityData));

        if (EntRefToEntIndex(entityData.beamRef) == INVALID_ENT_REFERENCE)
            continue;

        int entity = EntRefToEntIndex(entityData.entRef);

        bool capturing = (GetEntProp(entity, Prop_Send, "m_bCapturing") == 1);

        if (capturing)
        {
            entityData.beamToogle = !entityData.beamToogle;
            plugin.alEntityData.SetArray(i, entityData, sizeof(entityData));
        }
        else
        {
            if (entityData.capturing)
            {
                entityData.capturing = false;
                plugin.alEntityData.SetArray(i, entityData, sizeof(entityData));
            }
        }

        plugin.SetResourcePointBeamColor(entity);
    }

    return Plugin_Continue;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (nd_resource_point_beam) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "nd_resource_point_beam_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "nd_resource_point_beam_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "nd_resource_point_beam_alpha : %i", plugin.alpha);
    PrintToConsole(client, "nd_resource_point_beam_model : \"%s\"", plugin.model);
    PrintToConsole(client, "nd_resource_point_beam_width_start : %.1f", plugin.widthStart);
    PrintToConsole(client, "nd_resource_point_beam_width_end : %.1f", plugin.widthEnd);
    PrintToConsole(client, "nd_resource_point_beam_height : %.1f", plugin.height);
    PrintToConsole(client, "nd_resource_point_beam_color_consortium : \"%s\" (%i)", plugin.colorConsortium, plugin.iColorConsortium);
    PrintToConsole(client, "nd_resource_point_beam_color_empire : \"%s\" (%i)", plugin.colorEmpire, plugin.iColorEmpire);
    PrintToConsole(client, "nd_resource_point_beam_color_none : \"%s\" (%i)", plugin.colorNone, plugin.iColorNone);
    PrintToConsole(client, "nd_resource_point_beam_timer_toogle : %.1f", plugin.timerToogle);
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Returns the integer value of a RGB string.
 * Format: Three values between 0-255 separated by spaces. "<0-255> <0-255> <0-255>"
 * Example: "255 255 255"
 *
 * @param sColor        RGB color string.
 * @return              Integer value of the RGB string or 0 if not in specified format.
 */
int ConvertRGBToInt(char[] sColor)
{
    int color;

    if (sColor[0] == 0)
        return color;

    char sColors[3][4];
    int count = ExplodeString(sColor, " ", sColors, sizeof(sColors), sizeof(sColors[]));

    switch (count)
    {
        case 1:
        {
            color = StringToInt(sColors[0]);
        }
        case 2:
        {
            color = StringToInt(sColors[0]);
            color += 256 * StringToInt(sColors[1]);
        }
        case 3:
        {
            color = StringToInt(sColors[0]);
            color += 256 * StringToInt(sColors[1]);
            color += 65536 * StringToInt(sColors[2]);
        }
    }

    return color;
}