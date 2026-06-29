/**
// ====================================================================================================
Change Log:

1.1.1 (05-February-2024)
    - Fixed a bug where the skin would reset while interacting with other items. (thanks "HarryPotter" for reporting)
    - Fixed a bug not updating the viewmodel skin while using the give command.
    - Now the plugin doesn't set skins for player weapons equipped during the map chapter transition.

1.1.0 (17-September-2022)
    - Added cvar to ignore weapons that already have a skin different than default. (thanks "HarryPotter" for requesting)

1.0.9 (14-March-2022)
    - Added safe check while getting the entity skin to prevent errors. (thanks "HarryPotter" for reporting)

1.0.8 (12-March-2022)
    - Fixed gascans not applying skin on pickup. (thanks to "Toranks" for reporting and "ryzewash" for the code snippet to fix it)

1.0.7 (17-October-2021)
    - Fixed prop_physics gascans not changing their skin when enable. (thanks to "ryzewash" for reporting)

1.0.6 (04-June-2021)
    - Added gascan option. (thanks to "TrevorSoldier" for requesting)

1.0.5 (10-November-2020)
    - Fixed logic to apply RNG skin only after the config is loaded.
    - Fixed error when the StringMaps weren't initialized yet. (thanks to "Krufftys Killers" for reporting)

1.0.4 (10-November-2020)
    - Added cvar to select which weapons should have RNG skin. (thanks to "larrybrains" for requesting)

1.0.3 (03-November-2020)
    - Fixed spawner entities' skin logic.
    - Removed RNG logic from owned weapons.
    - Added admin command to scramble weapon skins in real-time.
    - Fixed compatibility with the skin menu plugin.

1.0.2 (30-September-2020)
    - Fixed a bug where sometimes it didn't apply the correct skin when picking up an item from a spawner with count = 1. (thanks "Tonblader" for reporting)

1.0.1 (30-September-2020)
    - Removed EventHookMode_PostNoCopy from hook events. (thanks "AK978" for reporting)

1.0.0 (29-September-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Weapons Skins RNG"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Applies random skins to spawned weapons"
#define PLUGIN_VERSION                "1.1.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=327609"

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
#define CONFIG_FILENAME               "l4d2_wskin_rng"

// ====================================================================================================
// Defines
// ====================================================================================================
#define L4D2_WEPID_PISTOL_MAGNUM      "32"
#define L4D2_WEPID_SMG_UZI            "2"
#define L4D2_WEPID_SMG_SILENCED       "7"
#define L4D2_WEPID_PUMP_SHOTGUN       "3"
#define L4D2_WEPID_SHOTGUN_CHROME     "8"
#define L4D2_WEPID_AUTO_SHOTGUN       "4"
#define L4D2_WEPID_RIFLE_M16          "5"
#define L4D2_WEPID_RIFLE_AK47         "26"
#define L4D2_WEPID_HUNTING_RIFLE      "6"

#define MODEL_W_CROWBAR               "models/weapons/melee/w_crowbar.mdl"
#define MODEL_W_CRICKET_BAT           "models/weapons/melee/w_cricket_bat.mdl"

#define MODEL_GASCAN                  "models/props_junk/gascan001a.mdl"

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
    ConVar l4d2_wskin_rng_version;
    ConVar l4d2_wskin_rng_enable;
    ConVar l4d2_wskin_rng_ignore_skin;
    ConVar l4d2_wskin_rng_pistol_magnum;
    ConVar l4d2_wskin_rng_pump_shotgun;
    ConVar l4d2_wskin_rng_shotgun_chrome;
    ConVar l4d2_wskin_rng_auto_shotgun;
    ConVar l4d2_wskin_rng_smg_uzi;
    ConVar l4d2_wskin_rng_smg_silenced;
    ConVar l4d2_wskin_rng_rifle_m16;
    ConVar l4d2_wskin_rng_rifle_ak47;
    ConVar l4d2_wskin_rng_hunting_rifle;
    ConVar l4d2_wskin_rng_cricket_bat;
    ConVar l4d2_wskin_rng_crowbar;
    ConVar l4d2_wskin_rng_gascan;

    void Init()
    {
        this.l4d2_wskin_rng_version        = CreateConVar("l4d2_wskin_rng_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d2_wskin_rng_enable         = CreateConVar("l4d2_wskin_rng_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_ignore_skin    = CreateConVar("l4d2_wskin_rng_ignore_skin", "1", "Ignore weapons that already have a skin different than default.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_pistol_magnum  = CreateConVar("l4d2_wskin_rng_pistol_magnum", "1", "Weapon skin RNG for Pistol Magnum.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_pump_shotgun   = CreateConVar("l4d2_wskin_rng_pump_shotgun", "1", "Weapon skin RNG for Pump Shotgun.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_shotgun_chrome = CreateConVar("l4d2_wskin_rng_shotgun_chrome", "1", "Weapon skin RNG for Chrome Shotgun.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_auto_shotgun   = CreateConVar("l4d2_wskin_rng_auto_shotgun", "1", "Weapon skin RNG for Auto Shotgun.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_smg_uzi        = CreateConVar("l4d2_wskin_rng_smg_uzi", "1", "Weapon skin RNG for SMG Uzi.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_smg_silenced   = CreateConVar("l4d2_wskin_rng_smg_silenced", "1", "Weapon skin RNG for Silenced SMG.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_rifle_m16      = CreateConVar("l4d2_wskin_rng_rifle_m16", "1", "Weapon skin RNG for M16 Rifle.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_rifle_ak47     = CreateConVar("l4d2_wskin_rng_rifle_ak47", "1", "Weapon skin RNG for AK47 Rifle.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_hunting_rifle  = CreateConVar("l4d2_wskin_rng_hunting_rifle", "1", "Weapon skin RNG for Hunting Rifle.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_cricket_bat    = CreateConVar("l4d2_wskin_rng_cricket_bat", "1", "Weapon skin RNG for Cricket Bat melee.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_crowbar        = CreateConVar("l4d2_wskin_rng_crowbar", "1", "Weapon skin RNG for Crowbar melee.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_wskin_rng_gascan         = CreateConVar("l4d2_wskin_rng_gascan", "1", "Weapon skin RNG for Gascan.\nNote: Enabling this may glitch some plugins that check the gascan skin to detect if is a scavenge one.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

        this.l4d2_wskin_rng_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_ignore_skin.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_pistol_magnum.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_pump_shotgun.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_shotgun_chrome.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_auto_shotgun.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_smg_uzi.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_smg_silenced.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_rifle_m16.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_rifle_ak47.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_hunting_rifle.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_cricket_bat.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_crowbar.AddChangeHook(Event_ConVarChanged);
        this.l4d2_wskin_rng_gascan.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    StringMap smWeaponIdToClassname;
    StringMap smWeaponCount;
    StringMap smMeleeModelCount;
    ArrayList alClassname;

    bool isGascan[MAXENTITIES+1];

    int gascanModelIndex;
    bool enable;
    bool ignoreSkin;
    bool pistolMagnum;
    bool pumpShotgun;
    bool shotgunChrome;
    bool autoShotgun;
    bool smgUzi;
    bool smgSilenced;
    bool rifleM16;
    bool rifleAK47;
    bool huntingRifle;
    bool cricketBat;
    bool crowbar;
    bool melee;
    bool gascan;

    void Init()
    {
        this.gascanModelIndex = -1;

        this.BuildClassnameArrayList();
        this.BuildWeaponStringMap();
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.l4d2_wskin_rng_enable.BoolValue;
        this.ignoreSkin = this.cvars.l4d2_wskin_rng_ignore_skin.BoolValue;
        this.pistolMagnum = this.cvars.l4d2_wskin_rng_pistol_magnum.BoolValue;
        this.pumpShotgun = this.cvars.l4d2_wskin_rng_pump_shotgun.BoolValue;
        this.shotgunChrome = this.cvars.l4d2_wskin_rng_shotgun_chrome.BoolValue;
        this.autoShotgun = this.cvars.l4d2_wskin_rng_auto_shotgun.BoolValue;
        this.smgUzi = this.cvars.l4d2_wskin_rng_smg_uzi.BoolValue;
        this.smgSilenced = this.cvars.l4d2_wskin_rng_smg_silenced.BoolValue;
        this.rifleM16 = this.cvars.l4d2_wskin_rng_rifle_m16.BoolValue;
        this.rifleAK47 = this.cvars.l4d2_wskin_rng_rifle_ak47.BoolValue;
        this.huntingRifle = this.cvars.l4d2_wskin_rng_hunting_rifle.BoolValue;
        this.cricketBat = this.cvars.l4d2_wskin_rng_cricket_bat.BoolValue;
        this.crowbar = this.cvars.l4d2_wskin_rng_crowbar.BoolValue;
        this.melee = (this.cricketBat || this.crowbar);
        this.gascan = this.cvars.l4d2_wskin_rng_gascan.BoolValue;

        if (this.enable)
            this.gascanModelIndex = PrecacheModel(MODEL_GASCAN, true);

        this.BuildWeaponCountMap();
        this.BuildMeleeModelCountMap();
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_wskin_rng", CmdWSkinRng, ADMFLAG_ROOT, "Scramble the weapon skins randomly in real time.");
        RegAdminCmd("sm_print_cvars_l4d2_wskin_rng", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }

    void LateLoad()
    {
        this.LateLoadAll();
    }

    void LateLoadAll()
    {
        if (!this.enable)
            return;

        int entity;
        int count;
        char classname[36];

        for (int i = 0; i < plugin.alClassname.Length; i++)
        {
            plugin.alClassname.GetString(i, classname, sizeof(classname));

            if (!plugin.smWeaponCount.GetValue(classname, count))
                continue;

            entity = INVALID_ENT_REFERENCE;
            while ((entity = FindEntityByClassname(entity, classname)) != INVALID_ENT_REFERENCE)
            {
                OnSpawnPost(entity);
            }
        }

        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "prop_physics*")) != INVALID_ENT_REFERENCE)
        {
            if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
                OnSpawnPostPhysicsProp(entity);
        }

        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "physics_prop")) != INVALID_ENT_REFERENCE)
        {
            OnSpawnPostPhysicsProp(entity);
        }
    }

    void UpdateWeaponSkin(int entity)
    {
        if (!plugin.enable)
            return;

        if (plugin.ignoreSkin && GetEntProp(entity, Prop_Send, "m_nSkin") > 0)
            return;

        if (HasEntProp(entity, Prop_Send, "m_bPickedUpOnTransition") && GetEntProp(entity, Prop_Send, "m_bPickedUpOnTransition") == 1) // Ignore player weapons received during map chapter transition
            return;

        char classname[36];
        if (plugin.isGascan[entity])
            classname = "weapon_gascan";
        else
            GetEntityClassname(entity, classname, sizeof(classname));

        int count;

        if (StrEqual(classname, "weapon_melee"))
        {
            char sMeleeName[16];
            GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", sMeleeName, sizeof(sMeleeName));

            if (!plugin.smWeaponCount.GetValue(sMeleeName, count))
                return;
        }
        else if (StrEqual(classname, "weapon_melee_spawn"))
        {
            char modelname[PLATFORM_MAX_PATH];
            GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
            StringToLowerCase(modelname);

            if (!plugin.smMeleeModelCount.GetValue(modelname, count))
                return;
        }
        else if (StrEqual(classname, "weapon_spawn"))
        {
            int weaponId = GetEntProp(entity, Prop_Data, "m_weaponID");
            char sWeaponId[3];
            IntToString(weaponId, sWeaponId, sizeof(sWeaponId));

            char weaponClassname[36];
            if (!plugin.smWeaponIdToClassname.GetString(sWeaponId, weaponClassname, sizeof(weaponClassname)))
                return;

            if (!plugin.smWeaponCount.GetValue(weaponClassname, count))
                return;
        }
        else
        {
            if (!plugin.smWeaponCount.GetValue(classname, count))
                return;
        }

        if (count == 0)
            return;

        int skin = GetRandomInt(0, count);

        SetEntProp(entity, Prop_Send, "m_nSkin", skin);

        if (HasEntProp(entity, Prop_Data, "m_nWeaponSkin"))
            SetEntProp(entity, Prop_Data, "m_nWeaponSkin", skin);

        int viewModel = FindEntityViewModel(entity);
        if (viewModel != -1)
            SetEntProp(viewModel, Prop_Send, "m_nSkin", skin);
    }

    void BuildClassnameArrayList()
    {
        delete this.alClassname;
        this.alClassname = new ArrayList(ByteCountToCells(36));
        this.alClassname.PushString("weapon_melee");
        this.alClassname.PushString("weapon_melee_spawn");
        this.alClassname.PushString("weapon_spawn");
        this.alClassname.PushString("weapon_pistol_magnum");
        this.alClassname.PushString("weapon_pistol_magnum_spawn");
        this.alClassname.PushString("weapon_smg");
        this.alClassname.PushString("weapon_smg_spawn");
        this.alClassname.PushString("weapon_smg_silenced");
        this.alClassname.PushString("weapon_smg_silenced_spawn");
        this.alClassname.PushString("weapon_pumpshotgun");
        this.alClassname.PushString("weapon_pumpshotgun_spawn");
        this.alClassname.PushString("weapon_shotgun_chrome");
        this.alClassname.PushString("weapon_shotgun_chrome_spawn");
        this.alClassname.PushString("weapon_autoshotgun");
        this.alClassname.PushString("weapon_autoshotgun_spawn");
        this.alClassname.PushString("weapon_rifle");
        this.alClassname.PushString("weapon_rifle_spawn");
        this.alClassname.PushString("weapon_rifle_ak47");
        this.alClassname.PushString("weapon_rifle_ak47_spawn");
        this.alClassname.PushString("weapon_hunting_rifle");
        this.alClassname.PushString("weapon_hunting_rifle_spawn");
        this.alClassname.PushString("weapon_gascan");
    }

    void BuildWeaponStringMap()
    {
        delete this.smWeaponIdToClassname;
        this.smWeaponIdToClassname = new StringMap();
        this.smWeaponIdToClassname.SetString(L4D2_WEPID_PISTOL_MAGNUM, "weapon_pistol_magnum");
        this.smWeaponIdToClassname.SetString(L4D2_WEPID_SMG_UZI, "weapon_smg");
        this.smWeaponIdToClassname.SetString(L4D2_WEPID_SMG_SILENCED, "weapon_smg_silenced");
        this.smWeaponIdToClassname.SetString(L4D2_WEPID_PUMP_SHOTGUN, "weapon_pumpshotgun");
        this.smWeaponIdToClassname.SetString(L4D2_WEPID_SHOTGUN_CHROME, "weapon_shotgun_chrome");
        this.smWeaponIdToClassname.SetString(L4D2_WEPID_AUTO_SHOTGUN, "weapon_autoshotgun");
        this.smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_M16, "weapon_rifle");
        this.smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_AK47, "weapon_rifle_ak47");
        this.smWeaponIdToClassname.SetString(L4D2_WEPID_HUNTING_RIFLE, "weapon_hunting_rifle");
    }

    void BuildWeaponCountMap()
    {
        delete this.smWeaponCount;
        this.smWeaponCount = new StringMap();

        this.smWeaponCount.SetValue("weapon_spawn", 0);

        if (this.melee)
        {
            this.smWeaponCount.SetValue("weapon_melee", 0);
            this.smWeaponCount.SetValue("weapon_melee_spawn", 0);
        }
        if (this.pistolMagnum)
        {
            this.smWeaponCount.SetValue("weapon_pistol_magnum", 2);
            this.smWeaponCount.SetValue("weapon_pistol_magnum_spawn", 2);
        }
        if (this.smgUzi)
        {
            this.smWeaponCount.SetValue("weapon_smg", 1);
            this.smWeaponCount.SetValue("weapon_smg_spawn", 1);
        }
        if (this.smgSilenced)
        {
            this.smWeaponCount.SetValue("weapon_smg_silenced", 1);
            this.smWeaponCount.SetValue("weapon_smg_silenced_spawn", 1);
        }
        if (this.pumpShotgun)
        {
            this.smWeaponCount.SetValue("weapon_pumpshotgun", 1);
            this.smWeaponCount.SetValue("weapon_pumpshotgun_spawn", 1);
        }
        if (this.shotgunChrome)
        {
            this.smWeaponCount.SetValue("weapon_shotgun_chrome", 1);
            this.smWeaponCount.SetValue("weapon_shotgun_chrome_spawn", 1);
        }
        if (this.autoShotgun)
        {
            this.smWeaponCount.SetValue("weapon_autoshotgun", 1);
            this.smWeaponCount.SetValue("weapon_autoshotgun_spawn", 1);
        }
        if (this.rifleM16)
        {
            this.smWeaponCount.SetValue("weapon_rifle", 2);
            this.smWeaponCount.SetValue("weapon_rifle_spawn", 2);
        }
        if (this.rifleAK47)
        {
            this.smWeaponCount.SetValue("weapon_rifle_ak47", 2);
            this.smWeaponCount.SetValue("weapon_rifle_ak47_spawn", 2);
        }
        if (this.huntingRifle)
        {
            this.smWeaponCount.SetValue("weapon_hunting_rifle", 1);
            this.smWeaponCount.SetValue("weapon_hunting_rifle_spawn", 1);
        }
        if (this.cricketBat)
        {
            this.smWeaponCount.SetValue("cricket_bat", 1);
        }
        if (this.crowbar)
        {
            this.smWeaponCount.SetValue("crowbar", 1);
        }
        if (this.gascan)
        {
            this.smWeaponCount.SetValue("weapon_gascan", 3);
        }
    }

    void BuildMeleeModelCountMap()
    {
        delete this.smMeleeModelCount;
        this.smMeleeModelCount = new StringMap();

        if (!this.melee)
            return;

        if (this.cricketBat)
            this.smMeleeModelCount.SetValue(MODEL_W_CRICKET_BAT, 1);

        if (this.crowbar)
            this.smMeleeModelCount.SetValue(MODEL_W_CROWBAR, 1);
    }
}

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

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    plugin.Init();
}

/****************************************************************************************************/

public void OnMapStart()
{
    if (plugin.enable)
        plugin.gascanModelIndex = PrecacheModel(MODEL_GASCAN, true);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    plugin.GetCvarValues();
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

    if (entity < 0)
        return;

    switch (classname[0])
    {
        case 'w':
        {
            if (classname[1] != 'e') // weapon_*
                return;

            int count;
            if (!plugin.smWeaponCount.GetValue(classname, count))
                return;

            SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
        }
        case 'p':
        {
            if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
                SDKHook(entity, SDKHook_SpawnPost, OnSpawnPostPhysicsProp);
        }
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    plugin.isGascan[entity] = false;
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    RequestFrame(Frame_SpawnPost, EntIndexToEntRef(entity)); // 1 frame later required to get skin (m_nSkin) updated
}

/****************************************************************************************************/

void OnSpawnPostPhysicsProp(int entity)
{
    if (!plugin.gascan)
        return;

    if (GetEntProp(entity, Prop_Send, "m_nModelIndex") != plugin.gascanModelIndex)
        return;

    plugin.isGascan[entity] = true;
    RequestFrame(Frame_SpawnPost, EntIndexToEntRef(entity)); // 1 frame later required to get skin (m_nSkin) updated
}

/****************************************************************************************************/

void Frame_SpawnPost(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    plugin.UpdateWeaponSkin(entity);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdWSkinRng(int client, int args)
{
    plugin.LateLoad();

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------------- Plugin Cvars (l4d2_wskin_rng) --------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_wskin_rng_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_wskin_rng_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_ignore_skin : %b (%s)", plugin.ignoreSkin, plugin.ignoreSkin ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_pistol_magnum : %b (%s)", plugin.pistolMagnum, plugin.pistolMagnum ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_pump_shotgun : %b (%s)", plugin.pumpShotgun, plugin.pumpShotgun ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_shotgun_chrome : %b (%s)", plugin.shotgunChrome, plugin.shotgunChrome ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_auto_shotgun : %b (%s)", plugin.autoShotgun, plugin.autoShotgun ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_smg_uzi : %b (%s)", plugin.smgUzi, plugin.smgUzi ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_smg_silenced : %b (%s)", plugin.smgSilenced, plugin.smgSilenced ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_rifle_m16 : %b (%s)", plugin.rifleM16, plugin.rifleM16 ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_rifle_ak47 : %b (%s)", plugin.rifleAK47, plugin.rifleAK47 ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_hunting_rifle : %b (%s)", plugin.huntingRifle, plugin.huntingRifle ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_cricket_bat : %b (%s)", plugin.cricketBat, plugin.cricketBat ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_crowbar : %b (%s)", plugin.crowbar, plugin.crowbar ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_gascan : %b (%s)", plugin.gascan, plugin.gascan ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
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
 * Find the related entity view model.
 *
 * @param entity        Entity index.
 */
int FindEntityViewModel(int entity)
{
    int viewModel = -1;
    while ((viewModel = FindEntityByClassname(viewModel, "predicted_viewmodel")) != -1)
    {
        if (GetEntPropEnt(viewModel, Prop_Send, "m_hWeapon") == entity)
            return viewModel;
    }
    return -1;
}