/**
// ====================================================================================================
Change Log:

1.0.0 (07-November-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[ASWRD] One Hit Kill"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Kill entities with a single hit"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=340277"

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
#define CONFIG_FILENAME               "aswrd_onehit_kill"

// ====================================================================================================
// Defines
// ====================================================================================================
#define HITGROUP_GEAR                 10
#define HITGROUP_BONE_SHIELD          HITGROUP_GEAR + 1

#define HITBOX_SHIELDBUG_MIDDLE_LEG   1

#define MAXENTITIES                   2048

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bOnTraceAttackHooked[MAXENTITIES+1];

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alOneHitClass;

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
StringMap g_smOneHitClass;

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar aswrd_onehit_kill_version;
    ConVar aswrd_onehit_kill_enable;
    ConVar aswrd_onehit_kill_biomass_any;
    ConVar aswrd_onehit_kill_ignore_shield;
    ConVar aswrd_onehit_kill_door;
    ConVar aswrd_onehit_kill_laserable;

    void Init()
    {
        this.aswrd_onehit_kill_version       = CreateConVar("aswrd_onehit_kill_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.aswrd_onehit_kill_enable        = CreateConVar("aswrd_onehit_kill_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.aswrd_onehit_kill_biomass_any   = CreateConVar("aswrd_onehit_kill_biomass_any", "1", "Enable to hurt Biomass with any weapon.\n0 = 0FF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.aswrd_onehit_kill_ignore_shield = CreateConVar("aswrd_onehit_kill_ignore_shield", "1", "Ignores shield defense from Shield Bug.\n0 = 0FF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.aswrd_onehit_kill_door          = CreateConVar("aswrd_onehit_kill_door", "1", "Smash down doors with a single hit.\n0 = 0FF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.aswrd_onehit_kill_laserable     = CreateConVar("aswrd_onehit_kill_laserable", "1", "Destroys entities that usually break with laser damage, in a single hit.\n0 = 0FF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

        this.aswrd_onehit_kill_enable.AddChangeHook(Event_ConVarChanged);
        this.aswrd_onehit_kill_biomass_any.AddChangeHook(Event_ConVarChanged);
        this.aswrd_onehit_kill_ignore_shield.AddChangeHook(Event_ConVarChanged);
        this.aswrd_onehit_kill_door.AddChangeHook(Event_ConVarChanged);
        this.aswrd_onehit_kill_laserable.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    bool enabled;
    bool biomass_any;
    bool ignore_shield;
    bool door;
    bool laserable;
    bool eventsHooked;

    void Init()
    {
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enabled = this.cvars.aswrd_onehit_kill_enable.BoolValue;
        this.biomass_any = this.cvars.aswrd_onehit_kill_biomass_any.BoolValue;
        this.ignore_shield = this.cvars.aswrd_onehit_kill_ignore_shield.BoolValue;
        this.door = this.cvars.aswrd_onehit_kill_door.BoolValue;
        this.laserable = this.cvars.aswrd_onehit_kill_laserable.BoolValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_aswrd_onehit_kill", Cmd_PrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }
}

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_AlienSwarm)
    {
        strcopy(error, err_max, "This plugin only runs in \"Alien Swarm: Reactive Drop\" game");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    plugin.Init();

    g_alOneHitClass = new ArrayList(ByteCountToCells(36));
    g_smOneHitClass = new StringMap();

    BuildArraylistAndMaps();
}

/****************************************************************************************************/

void BuildArraylistAndMaps()
{
    g_alOneHitClass.Clear();
    g_alOneHitClass.PushString("asw_boomer");
    g_alOneHitClass.PushString("asw_buzzer");
    g_alOneHitClass.PushString("asw_drone");
    g_alOneHitClass.PushString("asw_drone_jumper");
    g_alOneHitClass.PushString("asw_drone_uber");
    g_alOneHitClass.PushString("asw_grub");
    g_alOneHitClass.PushString("asw_harvester");
    g_alOneHitClass.PushString("asw_mortarbug");
    g_alOneHitClass.PushString("asw_parasite");
    g_alOneHitClass.PushString("asw_parasite_defanged");
    g_alOneHitClass.PushString("asw_queen");
    g_alOneHitClass.PushString("asw_ranger");
    g_alOneHitClass.PushString("asw_shaman");
    g_alOneHitClass.PushString("asw_shieldbug");
    g_alOneHitClass.PushString("npc_antlion");
    g_alOneHitClass.PushString("npc_antlion_worker");
    g_alOneHitClass.PushString("npc_antlionguard_cavern");
    g_alOneHitClass.PushString("npc_antlionguard_normal");
    g_alOneHitClass.PushString("npc_fastzombie");
    g_alOneHitClass.PushString("npc_fastzombie_torso");
    g_alOneHitClass.PushString("npc_poisonzombie");
    g_alOneHitClass.PushString("npc_zombie");
    g_alOneHitClass.PushString("npc_zombie_torso");
    //--------------
    g_alOneHitClass.PushString("asw_egg");
    //--------------
    g_alOneHitClass.PushString("asw_alien_goo");
    //--------------
    g_alOneHitClass.PushString("asw_door");
    //--------------
    g_alOneHitClass.PushString("asw_prop_laserable");

    g_smOneHitClass.Clear();
    char classname[64];
    for (int i = 0; i < g_alOneHitClass.Length; i++)
    {
        g_alOneHitClass.GetString(i, classname, sizeof(classname));
        g_smOneHitClass.SetString(classname, "1");
    }
}

/****************************************************************************************************/

public void OnMapStart()
{
    // Fix for when OnConfigsExecuted is not executed by SM in some games
    RequestFrame(OnConfigsExecuted);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    plugin.GetCvarValues();

    HookEvents();

    LateLoad();
}


/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

void HookEvents()
{
    if (plugin.enabled && !plugin.eventsHooked)
    {
        plugin.eventsHooked = true;

        HookEvent("difficulty_changed", Event_DifficultyChanged);
        HookEvent("alien_spawn", Event_Spawn);
        HookEvent("buzzer_spawn", Event_Spawn);
        return;
    }

    if (!plugin.enabled && plugin.eventsHooked)
    {
        plugin.eventsHooked = false;

        UnhookEvent("difficulty_changed", Event_DifficultyChanged);
        UnhookEvent("alien_spawn", Event_Spawn);
        UnhookEvent("buzzer_spawn", Event_Spawn);

        return;
    }
}

/****************************************************************************************************/

// Difficulty changes modifies health of all live aliens
void Event_DifficultyChanged(Event event, const char[] name, bool dontBroadcast)
{
    LateLoad();
}

/****************************************************************************************************/

void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("entindex");

    RequestFrame(Frame_Spawn, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;
    char classname[64];

    for (int i = 0; i < g_alOneHitClass.Length; i++)
    {
        g_alOneHitClass.GetString(i, classname, sizeof(classname));

        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, classname)) != INVALID_ENT_REFERENCE)
        {
            if (StrEqual(classname, "asw_door"))
            {
                if (plugin.door)
                    RequestFrame(Frame_Spawn, EntIndexToEntRef(entity));

                continue;
            }

            if (StrEqual(classname, "asw_prop_laserable"))
            {
                if (plugin.laserable)
                    RequestFrame(Frame_Spawn, EntIndexToEntRef(entity));

                continue;
            }

            RequestFrame(Frame_Spawn, EntIndexToEntRef(entity));
        }
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    if (StrEqual(classname, "asw_egg"))
    {
        RequestFrame(Frame_Spawn, EntIndexToEntRef(entity));
        return;
    }

    if (StrEqual(classname, "asw_alien_goo"))
    {
        RequestFrame(Frame_Spawn, EntIndexToEntRef(entity));
        return;
    }

    if (StrEqual(classname, "asw_door"))
    {
        if (plugin.door)
            RequestFrame(Frame_Spawn, EntIndexToEntRef(entity));

        return;
    }

    if (StrEqual(classname, "asw_prop_laserable"))
    {
        if (plugin.laserable)
            RequestFrame(Frame_Spawn, EntIndexToEntRef(entity));

        return;
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bOnTraceAttackHooked[entity] = false;
}

/****************************************************************************************************/

void Frame_Spawn(int entityRef)
{
    if (!plugin.enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    SetEntProp(entity, Prop_Data, "m_iHealth", 1);

    HookEntity(entity);
}

/****************************************************************************************************/

void HookEntity(int entity)
{
    if (ge_bOnTraceAttackHooked[entity])
        return;

    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));

    if (StrEqual(classname, "asw_shieldbug"))
    {
        ge_bOnTraceAttackHooked[entity] = true;
        SDKHook(entity, SDKHook_TraceAttack, TraceAttackShieldBug);
        return;
    }

    if (StrEqual(classname, "asw_alien_goo"))
    {
        ge_bOnTraceAttackHooked[entity] = true;
        SDKHook(entity, SDKHook_TraceAttack, TraceAttackBiomass);
        return;
    }
}

/****************************************************************************************************/

Action TraceAttackShieldBug(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if (!plugin.enabled)
        return Plugin_Continue;

    if (!plugin.ignore_shield)
        return Plugin_Continue;

    bool shieldBugBlockedDamage;

    // Shield bug ignores damage based on the hitgroup/hitbox. (SOURCE: asw_shieldbug_shared.cpp>CASW_Shieldbug::BlockedDamage)
    if (hitgroup == HITGROUP_BONE_SHIELD)
        shieldBugBlockedDamage = true;

    if (hitbox == HITBOX_SHIELDBUG_MIDDLE_LEG)
        shieldBugBlockedDamage = true;

    if (shieldBugBlockedDamage)
        SDKHooks_TakeDamage(victim, attacker, inflictor, damage, damagetype, .bypassHooks = false);

    return Plugin_Continue;
}

/****************************************************************************************************/

Action TraceAttackBiomass(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if (!plugin.enabled)
        return Plugin_Continue;

    if (!plugin.biomass_any)
        return Plugin_Continue;

    if (damagetype & DMG_BURN)
        return Plugin_Continue;

    damagetype |= DMG_BURN; // goo is only damaged by fire (SOURCE: asw_alien_goo_shared.cpp>CASW_Alien_Goo::OnTakeDamage)
    return Plugin_Changed;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action Cmd_PrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (aswrd_onehit_kill) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "aswrd_onehit_kill_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "aswrd_onehit_kill_enable : %b (%s)", plugin.enabled, plugin.enabled ? "true" : "false");
    PrintToConsole(client, "aswrd_onehit_kill_biomass_any : %b (%s)", plugin.biomass_any, plugin.biomass_any ? "true" : "false");
    PrintToConsole(client, "aswrd_onehit_kill_ignore_shield : %b (%s)", plugin.ignore_shield, plugin.ignore_shield ? "true" : "false");
    PrintToConsole(client, "aswrd_onehit_kill_door : %b (%s)", plugin.door, plugin.door ? "true" : "false");
    PrintToConsole(client, "aswrd_onehit_kill_laserable : %b (%s)", plugin.laserable, plugin.laserable ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}