/**
// ====================================================================================================
Change Log:

1.0.7 (23-02-February-2024)
    - Added better support for Dead Center and Passing finales maps while calling the elevator.
    - Added cvar to set whitelist maps.
    - Fixed an Invalid Handle error (thanks "Krufftys Killers" for reporting)

1.0.6 (21-02-February-2024)
    - Now requires dhooks.
    - Setting the finale flags on "Use" and "ForceFinaleStart" trigger_finale inputs with dhooks.
    - Fixed finale not starting on Crash Course. (thanks "Iizuka07" for reporting)

1.0.5 (06-February-2024)
    - Added cvar to enable the finale by client flag, but still not work on all maps depending on how to trigger to start finale is called. (thanks "Maur0" for requesting)

1.0.4 (05-February-2024)
    - Replaced hard-coded vscript strings calls by left4dhooks NavArea natives. (thanks "Silvers" for providing this feature)
    - Replaced the finale area flag set to only be called while calling the finale instead of setting it to all areas at round start. (thanks "Silvers" for the idea)
    - Fixed plugin constantly blocking SI spawn. (thanks "Asphyxia", "bullet28" and "HarryPotter" for reporting)

1.0.3 (17-March-2022)
    - Fixed plugin not removing invisible walls on Last Stand map. (thanks "VYRNACH_GAMING" for reporting)

1.0.2 (13-March-2022)
    - Fixed plugin not removing invisible walls on Crash Course map. (thanks "VYRNACH_GAMING" for reporting)
    - Fixed blacklist map logic not blocking changes for some events.
    - Added support for the upcoming update that will change the "anv_mapfixes" prefix to "community_update".

1.0.1 (01-July-2021)
    - Now requires left4dhooks.
    - Fixed a bug where SI couldn't spawn before finale starts on vs (2nd team). (thanks "noto3" for reporting)
    - Removed TLS rocks blocking the way on Death Tool finale. (thanks "Maur0" for reporting).
    - Added cvar to only apply on official (not custom) maps. (thanks "SDArt" for requesting)

1.0.0 (28-June-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Unlock Finales"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Allow to start finale events with survivors anywhere"
#define PLUGIN_VERSION                "1.0.7"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=333274"

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
#include <dhooks>
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
#define CONFIG_FILENAME               "l4d2_unlock_finales"

// ====================================================================================================
// Defines
// ====================================================================================================
#define NAV_FINALE                    64

#define MAXENTITIES                   2048

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d2_unlock_finales_version;
    ConVar l4d2_unlock_finales_enable;
    ConVar l4d2_unlock_finales_officialMapsOnly;
    ConVar l4d2_unlock_finales_blacklistMaps;
    ConVar l4d2_unlock_finales_whitelistMaps;
    ConVar l4d2_unlock_finales_flags;

    void Init()
    {
        this.l4d2_unlock_finales_version          = CreateConVar("l4d2_unlock_finales_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d2_unlock_finales_enable           = CreateConVar("l4d2_unlock_finales_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_unlock_finales_officialMapsOnly = CreateConVar("l4d2_unlock_finales_official_maps_only", "0", "Allow the plugin only on official (not custom) maps.\n0 = OFF, 1 = ON.\nNote: Automatically adds official finale maps to the whitelist when ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_unlock_finales_blacklistMaps    = CreateConVar("l4d2_unlock_finales_blacklist_maps", "", "Prevent the plugin running on these maps.\nSeparate by commas (no spaces).\nEmpty = none.\nExample: \"c1m4_atrium,c2m5_concert\", plugin won't run on both maps.", CVAR_FLAGS);
        this.l4d2_unlock_finales_whitelistMaps    = CreateConVar("l4d2_unlock_finales_whitelist_maps", "", "Allow the plugin run on these maps.\nSeparate by commas (no spaces).\nEmpty = none.\nExample: \"c1m4_atrium,c2m5_concert\", plugin will run on both maps.", CVAR_FLAGS);
        this.l4d2_unlock_finales_flags            = CreateConVar("l4d2_unlock_finales_flags", "", "Players with these flags can trigger the finale with players anywhere (doesn't work on all maps).\nEmpty = everyone.\nKnown values at \"\\addons\\sourcemod\\configs\\admin_levels.cfg\".\nExample: \"az\", will enable to players with \"a\" (reservation) or \"z\" (root) flag.", CVAR_FLAGS);

        this.l4d2_unlock_finales_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d2_unlock_finales_officialMapsOnly.AddChangeHook(Event_ConVarChanged);
        this.l4d2_unlock_finales_blacklistMaps.AddChangeHook(Event_ConVarChanged);
        this.l4d2_unlock_finales_whitelistMaps.AddChangeHook(Event_ConVarChanged);
        this.l4d2_unlock_finales_flags.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    ArrayList alNavAreasWithoutFinale;

    Handle hAcceptInput;
    Handle hAcceptInputPost;

    bool useHooked[MAXENTITIES+1];

    int entTerrorPlayerManager;
    bool left4DHooks;
    bool eventsHooked;
    char mapName[64];
    bool isOfficialFinaleMap;
    bool isMapC10M5;
    bool enable;
    bool officialMapOnly;
    char blacklistMaps[512];
    bool isBlacklistMap;
    char whitelistMaps[512];
    bool isWhitelistMap;
    bool isAllowedMap;
    char sFlags[27];
    int flags;

    void Init()
    {
        this.entTerrorPlayerManager = INVALID_ENT_REFERENCE;
        this.alNavAreasWithoutFinale = new ArrayList();
        this.CreateDHooks();
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.l4d2_unlock_finales_enable.BoolValue;
        this.officialMapOnly = this.cvars.l4d2_unlock_finales_officialMapsOnly.BoolValue;
        this.cvars.l4d2_unlock_finales_blacklistMaps.GetString(this.blacklistMaps, sizeof(this.blacklistMaps));
        Format(this.blacklistMaps, sizeof(this.blacklistMaps), ",%s,", this.blacklistMaps);
        ReplaceString(this.blacklistMaps, sizeof(this.blacklistMaps), " ", "");
        ReplaceString(this.blacklistMaps, sizeof(this.blacklistMaps), ",,", "");
        StringToLowerCase(this.blacklistMaps);
        this.isBlacklistMap = (StrContains(this.blacklistMaps, this.mapName, false) != -1);
        this.cvars.l4d2_unlock_finales_whitelistMaps.GetString(this.whitelistMaps, sizeof(this.whitelistMaps));
        Format(this.whitelistMaps, sizeof(this.whitelistMaps), ",%s,", this.whitelistMaps);
        ReplaceString(this.whitelistMaps, sizeof(this.whitelistMaps), " ", "");
        ReplaceString(this.whitelistMaps, sizeof(this.whitelistMaps), ",,", "");
        StringToLowerCase(this.whitelistMaps);
        this.isWhitelistMap = (StrContains(this.whitelistMaps, this.mapName, false) != -1);
        this.isAllowedMap = this.IsAllowedMap();
        this.cvars.l4d2_unlock_finales_flags.GetString(this.sFlags, sizeof(this.sFlags));
        TrimString(this.sFlags);
        this.flags = ReadFlagString(this.sFlags);
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_l4d2_unlock_finales", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }

    void CreateDHooks()
    {
        GameData hGameData = LoadGameConfigFile("sdktools.games/game.left4dead2");
        int offset = hGameData.GetOffset("AcceptInput");
        delete hGameData;

        if (offset == -1)
            SetFailState("Failed to get AcceptInput offset");

        this.hAcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, AcceptInput);
        DHookAddParam(this.hAcceptInput, HookParamType_CharPtr);
        DHookAddParam(this.hAcceptInput, HookParamType_CBaseEntity);
        DHookAddParam(this.hAcceptInput, HookParamType_CBaseEntity);
        DHookAddParam(this.hAcceptInput, HookParamType_Object, 20, DHookPass_ByVal|DHookPass_ODTOR|DHookPass_OCTOR|DHookPass_OASSIGNOP); //varaint_t is a union of 12 (float[3]) plus two int type params 12 + 8 = 20
        DHookAddParam(this.hAcceptInput, HookParamType_Int);

        this.hAcceptInputPost = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, AcceptInputPost);
        DHookAddParam(this.hAcceptInputPost, HookParamType_CharPtr);
        DHookAddParam(this.hAcceptInputPost, HookParamType_CBaseEntity);
        DHookAddParam(this.hAcceptInputPost, HookParamType_CBaseEntity);
        DHookAddParam(this.hAcceptInputPost, HookParamType_Object, 20, DHookPass_ByVal|DHookPass_ODTOR|DHookPass_OCTOR|DHookPass_OASSIGNOP); //varaint_t is a union of 12 (float[3]) plus two int type params 12 + 8 = 20
        DHookAddParam(this.hAcceptInputPost, HookParamType_Int);
    }

    void HookEvents()
    {
        if (this.enable && !this.eventsHooked)
        {
            this.eventsHooked = true;

            HookEvent("player_left_safe_area", Event_PlayerLeftSafeArea);

            HookEntityOutput("trigger_finale", "UseStart", OnUseStart);
            HookEntityOutput("trigger_finale", "FinaleStart", OnFinaleStart);

            return;
        }

        if (!this.enable && this.eventsHooked)
        {
            this.eventsHooked = false;

            UnhookEvent("player_left_safe_area", Event_PlayerLeftSafeArea);

            UnhookEntityOutput("trigger_finale", "UseStart", OnUseStart);
            UnhookEntityOutput("trigger_finale", "FinaleStart", OnFinaleStart);

            return;
        }
    }

    void HookEntity(int entity)
    {
        if (this.useHooked[entity])
            return;

        this.useHooked[entity] = true;
        DHookEntity(this.hAcceptInput, false, entity);
        DHookEntity(this.hAcceptInputPost, true, entity);
    }

    void LateLoad()
    {
        this.LateLoadAll();
    }

    void LateLoadAll()
    {
        if (!this.enable)
            return;

        if (!this.isAllowedMap)
            return;

        if (!HasAnySurvivorLeftSafeArea())
            return;

        plugin.DoMapSpecificConfigs();

        int entity;

        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "trigger_finale")) != INVALID_ENT_REFERENCE)
        {
            this.HookEntity(entity);
        }
    }

    bool IsAllowedMap()
    {
        if (this.isBlacklistMap)
            return false;

        if (this.isWhitelistMap)
            return true;

        if (this.officialMapOnly && !this.isOfficialFinaleMap)
            return false;

        return true;
    }

    void SetAllNavAreasFinale()
    {
        ArrayList areas = new ArrayList();
        L4D_GetAllNavAreas(areas);

        delete plugin.alNavAreasWithoutFinale;
        plugin.alNavAreasWithoutFinale = new ArrayList();

        for (int i = 0; i < areas.Length; i++)
        {
            Address area = areas.Get(i);
            int navSpawnAttributes = L4D_GetNavArea_SpawnAttributes(area);
            if (!(navSpawnAttributes & NAV_FINALE))
            {
                plugin.alNavAreasWithoutFinale.Push(area);
                L4D_SetNavArea_SpawnAttributes(area, navSpawnAttributes|NAV_FINALE);
            }
        }

        delete areas;
    }

    void RestoreNavAreas()
    {
        if (this.alNavAreasWithoutFinale.Length == 0)
            return;

        for (int i = 0; i < this.alNavAreasWithoutFinale.Length; i++)
        {
            Address area = this.alNavAreasWithoutFinale.Get(i);
            int navSpawnAttributes = L4D_GetNavArea_SpawnAttributes(area);
            navSpawnAttributes &= ~NAV_FINALE;
            L4D_SetNavArea_SpawnAttributes(area, navSpawnAttributes);
        }
        delete this.alNavAreasWithoutFinale;
        this.alNavAreasWithoutFinale = new ArrayList();
    }

    void DoMapSpecificConfigs()
    {
        int entity;
        char targetname[64];

        if (StrEqual(plugin.mapName, ",c1m4_atrium,"))
        {
            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "trigger_multiple")) != INVALID_ENT_REFERENCE)
            {
                if (GetEntProp(entity, Prop_Data, "m_iHammerID") == 188774)
                {
                    AcceptEntityInput(entity, "Kill");
                    break;
                }
            }

            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "func_button")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "button_elev_3rdfloor"))
                {
                    AcceptEntityInput(entity, "Unlock");
                    break;
                }
            }

            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "func_door")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "door_elevator_top")) // two doors (left/right)
                    SetEntPropFloat(entity, Prop_Data, "m_flWait", 0.0); // Prevents door closing again after opening it
            }

            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "func_elevator")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "elevator"))
                {
                    SetVariantString("OnReachedBottom door_elevator_top:Open::0:-1");
                    AcceptEntityInput(entity, "AddOutput");
                    break;
                }
            }
        }
        else if (StrEqual(plugin.mapName, ",c2m5_concert,"))
        {
            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "logic_relay")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "stadium_entrance_door_relay"))
                {
                    AcceptEntityInput(entity, "Kill");
                    break;
                }
            }
        }
        else if (StrEqual(plugin.mapName, ",c6m3_port,"))
        {
            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "func_brush")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "elevator_clip_brush"))
                {
                    AcceptEntityInput(entity, "Kill");
                    break;
                }
            }

            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "trigger_push")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "elevator_push"))
                {
                    AcceptEntityInput(entity, "Kill");
                    break;
                }
            }

            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "trigger_multiple")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "generator_elevator_trigger"))
                {
                    AcceptEntityInput(entity, "Kill");
                    break;
                }
            }

            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "func_button")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "generator_elevator_button"))
                {
                    AcceptEntityInput(entity, "Unlock");
                    break;
                }
            }
        }
        else if (StrEqual(plugin.mapName, ",c7m3_port,"))
        {
            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "point_template")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "door_spawner"))
                {
                    AcceptEntityInput(entity, "Kill");
                    break;
                }
            }

            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "func_button_timed")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                //finale_start_button/finale_start_button1/finale_start_button2
                if (StrContains(targetname, "finale_start_button") != -1)
                    AcceptEntityInput(entity, "Unlock");
            }
        }
        else if (StrEqual(plugin.mapName, ",c8m5_rooftop,"))
        {
            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "point_template")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "rooftop_playerclip_template"))
                {
                    AcceptEntityInput(entity, "Kill");
                    break;
                }
            }

            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "func_button")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "radio_button"))
                {
                    AcceptEntityInput(entity, "Unlock");
                    break;
                }
            }
        }
        else if (StrEqual(plugin.mapName, ",c9m2_lots,"))
        {
            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "func_button_timed")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "finaleswitch_initial"))
                {
                    AcceptEntityInput(entity, "Unlock");
                    break;
                }
            }
        }
        else if (StrEqual(plugin.mapName, ",c14m2_lighthouse,"))
        {
            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, "func_brush")) != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

                if (StrEqual(targetname, "lookout_clip"))
                {
                    AcceptEntityInput(entity, "Kill");
                    break;
                }
            }
        }
    }
}

// ====================================================================================================
// left4dhooks - Plugin Dependencies
// ====================================================================================================
#if !defined _l4dh_included
native void L4D_GetAllNavAreas(ArrayList aList);
native int L4D_GetNavArea_SpawnAttributes(Address pTerrorNavArea);
native void L4D_SetNavArea_SpawnAttributes(Address pTerrorNavArea, int flags);
#endif

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    #if !defined _l4dh_included
    MarkNativeAsOptional("L4D_GetAllNavAreas");
    MarkNativeAsOptional("L4D_GetNavArea_SpawnAttributes");
    MarkNativeAsOptional("L4D_SetNavArea_SpawnAttributes");
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
    plugin.left4DHooks = (GetFeatureStatus(FeatureType_Native, "L4D_GetAllNavAreas") == FeatureStatus_Available);
}

/****************************************************************************************************/

public void OnMapStart()
{
    GetCurrentMap(plugin.mapName, sizeof(plugin.mapName));
    StringToLowerCase(plugin.mapName);
    Format(plugin.mapName, sizeof(plugin.mapName), ",%s,", plugin.mapName);

    plugin.isOfficialFinaleMap = IsOfficialFinale();
    plugin.isMapC10M5 = (StrEqual(plugin.mapName, ",c10m5_houseboat,"));
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
    if (!plugin.enable)
        return;

    if (!plugin.isAllowedMap)
        return;

    if (entity < 0)
        return;

    if (StrEqual(classname, "trigger_finale"))
        plugin.HookEntity(entity);

    if (plugin.isMapC10M5)
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    plugin.useHooked[entity] = false;
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    char targetname[64];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (targetname[0] == 0)
        return;

    if (StrContains(targetname, "anv_mapfixes_rockslide") != -1 || StrContains(targetname, "community_update_rockslide") != -1)
        AcceptEntityInput(entity, "Kill");
}

/****************************************************************************************************/

void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
    if (!plugin.isAllowedMap)
        return;

    plugin.DoMapSpecificConfigs();
}

/****************************************************************************************************/

void OnUseStart(const char[] output, int caller, int activator, float delay)
{
    if (!plugin.isAllowedMap)
        return;

    int entity;
    char targetname[64];

    if (StrEqual(plugin.mapName, ",c3m4_plantation,"))
    {
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "env_physics_blocker")) != INVALID_ENT_REFERENCE)
        {
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

            if (StrEqual(targetname, "anv_mapfixes_point_of_no_return") || StrEqual(targetname, "community_update_point_of_no_return"))
                AcceptEntityInput(entity, "Kill");
        }
    }
    else if (StrEqual(plugin.mapName, ",c4m5_milltown_escape,"))
    {
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "env_physics_blocker")) != INVALID_ENT_REFERENCE)
        {
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

            if (StrEqual(targetname, "anv_mapfixes_point_of_no_return") || StrEqual(targetname, "community_update_point_of_no_return"))
                AcceptEntityInput(entity, "Kill");
        }
    }
    else if (StrEqual(plugin.mapName, ",c9m2_lots,"))
    {
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "env_physics_blocker")) != INVALID_ENT_REFERENCE)
        {
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

            if (StrEqual(targetname, "anv_mapfixes_point_of_no_return") || StrEqual(targetname, "community_update_point_of_no_return"))
                AcceptEntityInput(entity, "Kill");
        }
    }
    else if (StrEqual(plugin.mapName, ",c12m5_cornfield,"))
    {
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "env_physics_blocker")) != INVALID_ENT_REFERENCE)
        {
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

            if (StrEqual(targetname, "anv_mapfixes_point_of_no_return") || StrEqual(targetname, "community_update_point_of_no_return"))
                AcceptEntityInput(entity, "Kill");
        }
    }
}

/****************************************************************************************************/

void OnFinaleStart(const char[] output, int caller, int activator, float delay)
{
    if (!plugin.isAllowedMap)
        return;

    int entity;
    char targetname[64];

    if (StrEqual(plugin.mapName, ",c9m2_lots,"))
    {
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "env_physics_blocker")) != INVALID_ENT_REFERENCE)
        {
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

            if (StrEqual(targetname, "anv_mapfixes_point_of_no_return") || StrEqual(targetname, "community_update_point_of_no_return"))
                AcceptEntityInput(entity, "Kill");
        }
    }
}

/****************************************************************************************************/

MRESReturn AcceptInput(int pThis, Handle hReturn, Handle hParams)
{
    if (!plugin.enable)
        return MRES_Ignored;

    if (!plugin.isAllowedMap)
        return MRES_Ignored;

    char inputName[17];
    DHookGetParamString(hParams, 1, inputName, sizeof(inputName));

    if (StrEqual(inputName, "Use") || StrEqual(inputName, "ForceFinaleStart"))
    {
        int activator = -1;
        if (!DHookIsNullParam(hParams, 2))
            activator = DHookGetParam(hParams, 2);

        if (IsValidClient(activator))
        {
            if (plugin.flags != 0 && !(GetUserFlagBits(activator) & plugin.flags))
                return MRES_Ignored;
        }

        plugin.SetAllNavAreasFinale();
        RequestFrame(Frame_RestoreNavAreas); // Just for safety in case another plugin blocks the input
    }

    return MRES_Ignored;
}

/****************************************************************************************************/

MRESReturn AcceptInputPost(int pThis, Handle hReturn, Handle hParams)
{
    if (!plugin.enable)
        return MRES_Ignored;

    if (!plugin.isAllowedMap)
        return MRES_Ignored;

    char inputName[17];
    DHookGetParamString(hParams, 1, inputName, sizeof(inputName));

    if (StrEqual(inputName, "Use") || StrEqual(inputName, "ForceFinaleStart"))
        plugin.RestoreNavAreas();

    return MRES_Ignored;
}

/****************************************************************************************************/

void Frame_RestoreNavAreas()
{
    plugin.RestoreNavAreas();
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d2_unlock_finales) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_unlock_finales_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_unlock_finales_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "l4d2_unlock_finales_official_maps_only : %b (%s)", plugin.officialMapOnly, plugin.officialMapOnly ? "true" : "false");
    PrintToConsole(client, "l4d2_unlock_finales_blacklist_maps : \"%s\"", plugin.blacklistMaps);
    PrintToConsole(client, "l4d2_unlock_finales_whitelist_maps : \"%s\"", plugin.whitelistMaps);
    PrintToConsole(client, "l4d2_unlock_finales_flags : %i (\"%s\")", plugin.flags, plugin.sFlags);
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "left4dhooks : %s", plugin.left4DHooks ? "true" : "false");
    PrintToConsole(client, "Map : \"%s\"", plugin.mapName);
    PrintToConsole(client, "Official Finale Map? : %b (%s)", plugin.isOfficialFinaleMap, plugin.isOfficialFinaleMap ? "true" : "false");
    PrintToConsole(client, "Blacklist Map? : %b (%s)", plugin.isBlacklistMap, plugin.isBlacklistMap ? "true" : "false");
    PrintToConsole(client, "Whitelist Map? : %b (%s)", plugin.isWhitelistMap, plugin.isWhitelistMap ? "true" : "false");
    PrintToConsole(client, "Allowed Map? : %b (%s)", plugin.isAllowedMap, plugin.isAllowedMap ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
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

/****************************************************************************************************/

/**
 * Converts the string to lower case.
 *
 * @param input         Input string.
 */
void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}

/****************************************************************************************************/

/**
 * Returns whether any survivor have left the safe area.
 *
 * @return              True if any survivor have left safe area, false otherwise.
 */
bool HasAnySurvivorLeftSafeArea()
{
    int entity = EntRefToEntIndex(plugin.entTerrorPlayerManager);

    if (entity == INVALID_ENT_REFERENCE)
        entity = FindEntityByClassname(-1, "terror_player_manager");

    if (entity == INVALID_ENT_REFERENCE)
    {
        plugin.entTerrorPlayerManager = INVALID_ENT_REFERENCE;
        return false;
    }

    plugin.entTerrorPlayerManager = EntIndexToEntRef(entity);

    return (GetEntProp(entity, Prop_Send, "m_hasAnySurvivorLeftSafeArea") == 1);
}

/****************************************************************************************************/

/**
 * Returns if the current map is a official finale campaign
 *
 * @return              True if the current map is a official finale campaign, false otherwise.
 */
bool IsOfficialFinale()
{
    if (StrEqual(plugin.mapName, ",c1m4_atrium,"))
        return true;
    if (StrEqual(plugin.mapName, ",c2m5_concert,"))
        return true;
    if (StrEqual(plugin.mapName, ",c3m4_plantation,"))
        return true;
    if (StrEqual(plugin.mapName, ",c4m5_milltown_escape,"))
        return true;
    if (StrEqual(plugin.mapName, ",c6m3_port,"))
        return true;
    if (StrEqual(plugin.mapName, ",c7m3_port,"))
        return true;
    if (StrEqual(plugin.mapName, ",c8m5_rooftop,"))
        return true;
    if (StrEqual(plugin.mapName, ",c9m2_lots,"))
        return true;
    if (StrEqual(plugin.mapName, ",c10m5_houseboat,"))
        return true;
    if (StrEqual(plugin.mapName, ",c11m5_runway,"))
        return true;
    if (StrEqual(plugin.mapName, ",c12m5_cornfield,"))
        return true;
    if (StrEqual(plugin.mapName, ",c13m4_cutthroatcreek,"))
        return true;
    if (StrEqual(plugin.mapName, ",c14m2_lighthouse,"))
        return true;

    return false;
}