/**
// ====================================================================================================
Change Log:

1.0.2 (29-May-2022)
    - Improved performance.
    - Fixed logic running twice on plugin load.
    - Fixed glow color not being applied.

1.0.1 (04-October-2021)
    - Added glow color cvar.

1.0.0 (27-September-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Random Entity Color"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Gives a random color to entities on the map"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=334470"

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
#define CONFIG_FILENAME               "l4d_random_entity_color"
#define DATA_FILENAME                 "l4d_random_entity_color"

// ====================================================================================================
// Defines
// ====================================================================================================
#define MODEL_MELEE_FIREAXE           "models/weapons/melee/w_fireaxe.mdl"
#define MODEL_MELEE_FRYING_PAN        "models/weapons/melee/w_frying_pan.mdl"
#define MODEL_MELEE_MACHETE           "models/weapons/melee/w_machete.mdl"
#define MODEL_MELEE_BASEBALL_BAT      "models/weapons/melee/w_bat.mdl"
#define MODEL_MELEE_CROWBAR           "models/weapons/melee/w_crowbar.mdl"
#define MODEL_MELEE_CRICKET_BAT       "models/weapons/melee/w_cricket_bat.mdl"
#define MODEL_MELEE_TONFA             "models/weapons/melee/w_tonfa.mdl"
#define MODEL_MELEE_KATANA            "models/weapons/melee/w_katana.mdl"
#define MODEL_MELEE_ELECTRIC_GUITAR   "models/weapons/melee/w_electric_guitar.mdl"
#define MODEL_MELEE_KNIFE             "models/w_models/weapons/w_knife_t.mdl"
#define MODEL_MELEE_GOLFCLUB          "models/weapons/melee/w_golfclub.mdl"
#define MODEL_MELEE_PITCHFORK         "models/weapons/melee/w_pitchfork.mdl"
#define MODEL_MELEE_SHOVEL            "models/weapons/melee/w_shovel.mdl"
#define MODEL_MELEE_RIOTSHIELD        "models/weapons/melee/w_riotshield.mdl"

#define MODEL_GNOME                   "models/props_junk/gnome.mdl"
#define MODEL_COLA                    "models/w_models/weapons/w_cola.mdl"

#define MODEL_GASCAN                  "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANECANISTER         "models/props_junk/propanecanister001a.mdl"
#define MODEL_OXYGENTANK              "models/props_equipment/oxygentank01.mdl"
#define MODEL_FIREWORKS_CRATE         "models/props_junk/explosive_box001.mdl"

#define L4D2_WEPID_PISTOL                     "1"
#define L4D2_WEPID_SMG                        "2"
#define L4D2_WEPID_PUMPSHOTGUN                "3"
#define L4D2_WEPID_AUTOSHOTGUN                "4"
#define L4D2_WEPID_RIFLE                      "5"
#define L4D2_WEPID_HUNTING_RIFLE              "6"
#define L4D2_WEPID_SMG_SILENCED               "7"
#define L4D2_WEPID_SHOTGUN_CHROME             "8"
#define L4D2_WEPID_RIFLE_DESERT               "9"
#define L4D2_WEPID_SNIPER_MILITARY            "10"
#define L4D2_WEPID_SHOTGUN_SPAS               "11"
#define L4D2_WEPID_FIRST_AID_KIT              "12"
#define L4D2_WEPID_MOLOTOV                    "13"
#define L4D2_WEPID_PIPE_BOMB                  "14"
#define L4D2_WEPID_PAIN_PILLS                 "15"
#define L4D2_WEPID_GASCAN                     "16"
#define L4D2_WEPID_PROPANETANK                "17"
#define L4D2_WEPID_OXYGENTANK                 "18"
#define L4D2_WEPID_CHAINSAW                   "20"
#define L4D2_WEPID_GRENADE_LAUNCHER           "21"
#define L4D2_WEPID_ADRENALINE                 "23"
#define L4D2_WEPID_DEFIBRILLATOR              "24"
#define L4D2_WEPID_VOMITJAR                   "25"
#define L4D2_WEPID_RIFLE_AK47                 "26"
#define L4D2_WEPID_GNOME                      "27"
#define L4D2_WEPID_COLA_BOTTLES               "28"
#define L4D2_WEPID_FIREWORKCRATE              "29"
#define L4D2_WEPID_UPGRADEPACK_INCENDIARY     "30"
#define L4D2_WEPID_UPGRADEPACK_EXPLOSIVE      "31"
#define L4D2_WEPID_PISTOL_MAGNUM              "32"
#define L4D2_WEPID_SMG_MP5                    "33"
#define L4D2_WEPID_RIFLE_SG552                "34"
#define L4D2_WEPID_SNIPER_AWP                 "35"
#define L4D2_WEPID_SNIPER_SCOUT               "36"
#define L4D2_WEPID_RIFLE_M60                  "37"

#define CONFIG_ENABLE                 0
#define CONFIG_RANDOM                 1
#define CONFIG_R                      2
#define CONFIG_G                      3
#define CONFIG_B                      4
#define CONFIG_ARRAYSIZE              5

#define MAXENTITIES                   2048

#define NOCOLOR                       -2 // -2 cause some entities has m_clrRender = -1

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_UseGlowColor;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bCvar_Enabled;
bool g_bCvar_UseGlowColor;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iDefaultConfig[CONFIG_ARRAYSIZE];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
int ge_iRGBA[MAXENTITIES+1] = { NOCOLOR, ... };

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alPluginEntities;

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
StringMap g_smWeaponIdToClassname;
StringMap g_smMeleeModelToName;
StringMap g_smPropModelToClassname;
StringMap g_smClassnameConfig;
StringMap g_smMeleeConfig;

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

    g_bL4D2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    g_alPluginEntities = new ArrayList();
    g_smWeaponIdToClassname = new StringMap();
    g_smMeleeModelToName = new StringMap();
    g_smPropModelToClassname = new StringMap();
    g_smClassnameConfig = new StringMap();
    g_smMeleeConfig = new StringMap();

    BuildMaps();

    LoadConfigs();

    CreateConVar("l4d_random_entity_color_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled        = CreateConVar("l4d_random_entity_color_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    if (g_bL4D2)
        g_hCvar_UseGlowColor = CreateConVar("l4d_random_entity_color_use_glow_color", "1", "(L4D2 only) Apply the same color from glow.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
        g_hCvar_UseGlowColor.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_colorinfo", CmdInfo, ADMFLAG_ROOT, "Outputs to the chat the color info about the entity at your crosshair.");
    RegAdminCmd("sm_colorreload", CmdReload, ADMFLAG_ROOT, "Reload the color configs.");
    RegAdminCmd("sm_colorremove", CmdRemove, ADMFLAG_ROOT, "Remove plugin color from entity at crosshair.");
    RegAdminCmd("sm_colorremoveall", CmdRemoveAll, ADMFLAG_ROOT, "Remove all colors created by the plugin.");
    RegAdminCmd("sm_coloradd", CmdAdd, ADMFLAG_ROOT, "Add color (with default config) to entity at crosshair.");
    RegAdminCmd("sm_colorall", CmdAll, ADMFLAG_ROOT, "Add color (with default config) to everything possible.");
    RegAdminCmd("sm_print_cvars_l4d_random_entity_color", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void BuildMaps()
{
    if (g_bL4D2)
    {
        g_smWeaponIdToClassname.Clear();
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PISTOL, "weapon_pistol");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SMG, "weapon_smg");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PUMPSHOTGUN, "weapon_pumpshotgun");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_AUTOSHOTGUN, "weapon_autoshotgun");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE, "weapon_rifle");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_HUNTING_RIFLE, "weapon_hunting_rifle");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SMG_SILENCED, "weapon_smg_silenced");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SHOTGUN_CHROME, "weapon_shotgun_chrome");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_DESERT, "weapon_rifle_desert");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SNIPER_MILITARY, "weapon_sniper_military");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SHOTGUN_SPAS, "weapon_shotgun_spas");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_FIRST_AID_KIT, "weapon_first_aid_kit");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_MOLOTOV, "weapon_molotov");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PIPE_BOMB, "weapon_pipe_bomb");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PAIN_PILLS, "weapon_pain_pills");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_GASCAN, "weapon_gascan");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PROPANETANK, "weapon_propanetank");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_OXYGENTANK, "weapon_oxygentank");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_CHAINSAW, "weapon_chainsaw");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_GRENADE_LAUNCHER, "weapon_grenade_launcher");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_ADRENALINE, "weapon_adrenaline");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_DEFIBRILLATOR, "weapon_defibrillator");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_VOMITJAR, "weapon_vomitjar");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_AK47, "weapon_rifle_ak47");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_GNOME, "weapon_gnome");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_COLA_BOTTLES, "weapon_cola_bottles");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_FIREWORKCRATE, "weapon_fireworkcrate");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_UPGRADEPACK_INCENDIARY, "weapon_upgradepack_incendiary");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_UPGRADEPACK_EXPLOSIVE, "weapon_upgradepack_explosive");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PISTOL_MAGNUM, "weapon_pistol_magnum");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SMG_MP5, "weapon_smg_mp5");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_SG552, "weapon_rifle_sg552");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SNIPER_AWP, "weapon_sniper_awp");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SNIPER_SCOUT, "weapon_sniper_scout");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_M60, "weapon_rifle_m60");

        g_smMeleeModelToName.Clear();
        g_smMeleeModelToName.SetString(MODEL_MELEE_FIREAXE, "fireaxe");
        g_smMeleeModelToName.SetString(MODEL_MELEE_FRYING_PAN, "frying_pan");
        g_smMeleeModelToName.SetString(MODEL_MELEE_MACHETE, "machete");
        g_smMeleeModelToName.SetString(MODEL_MELEE_BASEBALL_BAT, "baseball_bat");
        g_smMeleeModelToName.SetString(MODEL_MELEE_CROWBAR, "crowbar");
        g_smMeleeModelToName.SetString(MODEL_MELEE_CRICKET_BAT, "cricket_bat");
        g_smMeleeModelToName.SetString(MODEL_MELEE_TONFA, "tonfa");
        g_smMeleeModelToName.SetString(MODEL_MELEE_KATANA, "katana");
        g_smMeleeModelToName.SetString(MODEL_MELEE_ELECTRIC_GUITAR, "electric_guitar");
        g_smMeleeModelToName.SetString(MODEL_MELEE_KNIFE, "knife");
        g_smMeleeModelToName.SetString(MODEL_MELEE_GOLFCLUB, "golfclub");
        g_smMeleeModelToName.SetString(MODEL_MELEE_PITCHFORK, "pitchfork");
        g_smMeleeModelToName.SetString(MODEL_MELEE_SHOVEL, "shovel");
        g_smMeleeModelToName.SetString(MODEL_MELEE_RIOTSHIELD, "riotshield");

        g_smPropModelToClassname.Clear();
        g_smPropModelToClassname.SetString(MODEL_GNOME, "weapon_gnome");
        g_smPropModelToClassname.SetString(MODEL_COLA, "weapon_cola_bottles");
        g_smPropModelToClassname.SetString(MODEL_GASCAN, "weapon_gascan");
        g_smPropModelToClassname.SetString(MODEL_PROPANECANISTER, "weapon_propanetank");
        g_smPropModelToClassname.SetString(MODEL_OXYGENTANK, "weapon_oxygentank");
        g_smPropModelToClassname.SetString(MODEL_FIREWORKS_CRATE, "weapon_fireworkcrate");
    }
    else
    {
        g_smPropModelToClassname.Clear();
        g_smPropModelToClassname.SetString(MODEL_GASCAN, "weapon_gascan");
        g_smPropModelToClassname.SetString(MODEL_PROPANECANISTER, "weapon_propanetank");
        g_smPropModelToClassname.SetString(MODEL_OXYGENTANK, "weapon_oxygentank");
    }
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    LateLoad();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    if (g_bL4D2)
        g_bCvar_UseGlowColor = g_hCvar_UseGlowColor.BoolValue;
}

/****************************************************************************************************/

void LoadConfigs()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/%s.cfg", DATA_FILENAME);

    if (!FileExists(path))
    {
        SetFailState("Missing required data file on \"data/%s.cfg\", please re-download.", DATA_FILENAME);
        return;
    }

    KeyValues kv = new KeyValues(DATA_FILENAME);
    kv.ImportFromFile(path);

    g_smClassnameConfig.Clear();
    g_smMeleeConfig.Clear();

    int default_enable;
    int default_random;
    char default_color[12];

    int iColor[3];

    if (kv.JumpToKey("default"))
    {
        default_enable = kv.GetNum("enable", 0);
        default_random = kv.GetNum("random", 0);
        kv.GetString("color", default_color, sizeof(default_color), "255 255 255");

        iColor = ConvertRGBToIntArray(default_color);

        g_iDefaultConfig[CONFIG_ENABLE] = default_enable;
        g_iDefaultConfig[CONFIG_RANDOM] = default_random;
        g_iDefaultConfig[CONFIG_R] = iColor[0];
        g_iDefaultConfig[CONFIG_G] = iColor[1];
        g_iDefaultConfig[CONFIG_B] = iColor[2];
    }

    kv.Rewind();

    char section[64];
    int enable;
    int random;
    char color[12];

    int config[CONFIG_ARRAYSIZE];

    if (kv.JumpToKey("classnames"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                enable = kv.GetNum("enable", default_enable);
                if (enable == 0)
                    continue;

                random = kv.GetNum("random", default_random);
                kv.GetString("color", color, sizeof(color), default_color);

                iColor = ConvertRGBToIntArray(color);

                config[CONFIG_ENABLE] = enable;
                config[CONFIG_RANDOM] = random;
                config[CONFIG_R] = iColor[0];
                config[CONFIG_G] = iColor[1];
                config[CONFIG_B] = iColor[2];

                kv.GetSectionName(section, sizeof(section));
                TrimString(section);
                StringToLowerCase(section);

                g_smClassnameConfig.SetArray(section, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    if (kv.JumpToKey("melees"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                enable = kv.GetNum("enable", default_enable);
                if (enable == 0)
                    continue;

                random = kv.GetNum("random", default_random);
                kv.GetString("color", color, sizeof(color), default_color);

                iColor = ConvertRGBToIntArray(color);

                config[CONFIG_ENABLE] = enable;
                config[CONFIG_RANDOM] = random;
                config[CONFIG_R] = iColor[0];
                config[CONFIG_G] = iColor[1];
                config[CONFIG_B] = iColor[2];

                kv.GetSectionName(section, sizeof(section));
                TrimString(section);
                StringToLowerCase(section);

                g_smMeleeConfig.SetArray(section, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    delete kv;
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;
    char classname[36];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
    {
        if (entity < 0)
            continue;

        GetEntityClassname(entity, classname, sizeof(classname));
        OnEntityCreated(entity, classname);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bCvar_Enabled)
        return;

    if (entity < 0)
        return;

    if (!HasEntProp(entity, Prop_Send, "m_clrRender"))
        return;

    if (g_bCvar_UseGlowColor && HasEntProp(entity, Prop_Send, "m_glowColorOverride"))
        RequestFrame(OnNextFrameGlow, EntIndexToEntRef(entity));
    else
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_iRGBA[entity] = NOCOLOR;

    int find = g_alPluginEntities.FindValue(EntIndexToEntRef(entity));
    if (find != -1)
        g_alPluginEntities.Erase(find);
}

/****************************************************************************************************/

void OnNextFrameGlow(int entityRef)
{
    RequestFrame(OnNextFrame, entityRef);
}

/****************************************************************************************************/

void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    int find = g_alPluginEntities.FindValue(EntIndexToEntRef(entity));
    if (find != -1)
        return;

    char targetname[22];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
    if (StrEqual(targetname, "l4d_random_beam_item")) // l4d_random_beam_item plugin compatibility
        return;

    char modelname[PLATFORM_MAX_PATH];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
    StringToLowerCase(modelname);

    char classname[36];
    GetEntityClassname(entity, classname, sizeof(classname));

    if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
        g_smPropModelToClassname.GetString(modelname, classname, sizeof(classname));

    bool isMelee;
    char melee[16];

    if (StrContains(classname, "weapon_melee") == 0)
    {
        isMelee = true;

        if (StrEqual(classname, "weapon_melee"))
            GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", melee, sizeof(melee));
        else //weapon_melee_spawn
            g_smMeleeModelToName.GetString(modelname, melee, sizeof(melee));
    }

    if (StrEqual(classname, "weapon_spawn"))
    {
        int weaponId = GetEntProp(entity, Prop_Data, "m_weaponID");
        char sWeaponId[3];
        IntToString(weaponId, sWeaponId, sizeof(sWeaponId));

        if (!g_smWeaponIdToClassname.GetString(sWeaponId, classname, sizeof(classname)))
            return;
    }

    if (classname[0] == 'w')
        ReplaceString(classname, sizeof(classname), "_spawn", "");

    int config[CONFIG_ARRAYSIZE];

    if (isMelee && config[CONFIG_ENABLE] == 0)
        g_smMeleeConfig.GetArray(melee, config, sizeof(config));

    if (config[CONFIG_ENABLE] == 0)
        g_smClassnameConfig.GetArray(classname, config, sizeof(config));

    if (config[CONFIG_ENABLE] == 0)
        return;

    if (ge_iRGBA[entity] == NOCOLOR)
        ge_iRGBA[entity] = GetEntProp(entity, Prop_Send, "m_clrRender");

    int renderColor[4];
    GetEntityRenderColor(entity, renderColor[0], renderColor[1], renderColor[2], renderColor[3]);

    if (g_bCvar_UseGlowColor && HasEntProp(entity, Prop_Send, "m_glowColorOverride") && GetEntProp(entity, Prop_Send, "m_glowColorOverride") != 0)
    {
        int glowColor = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
        renderColor[0] = ((glowColor >> 00) & 0xFF);
        renderColor[1] = ((glowColor >> 08) & 0xFF);
        renderColor[2] = ((glowColor >> 16) & 0xFF);
    }
    else if (config[CONFIG_RANDOM] == 1)
    {
        renderColor[0] = GetRandomInt(0, 255);
        renderColor[1] = GetRandomInt(0, 255);
        renderColor[2] = GetRandomInt(0, 255);
    }
    else
    {
        renderColor[0] = config[CONFIG_R];
        renderColor[1] = config[CONFIG_G];
        renderColor[2] = config[CONFIG_B];
    }

    SetEntityRenderColor(entity, renderColor[0], renderColor[1], renderColor[2], renderColor[3]);

    g_alPluginEntities.Push(EntIndexToEntRef(entity));
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    RemoveAll();
}

/****************************************************************************************************/

void RemoveAll()
{
    if (g_alPluginEntities.Length > 0)
    {
        int entity;

        ArrayList g_alPluginEntitiesClone = g_alPluginEntities.Clone();

        for (int i = 0; i < g_alPluginEntitiesClone.Length; i++)
        {
            entity = EntRefToEntIndex(g_alPluginEntitiesClone.Get(i));

            if (entity == INVALID_ENT_REFERENCE)
                continue;

            SetEntProp(entity, Prop_Send, "m_clrRender", ge_iRGBA[entity]);
            ge_iRGBA[entity] = NOCOLOR;
        }

        delete g_alPluginEntitiesClone;

        g_alPluginEntities.Clear();
    }
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdInfo(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (!IsValidEntity(entity))
    {
        PrintToChat(client, "\x04Invalid target.");
        return Plugin_Handled;
    }

    if (!HasEntProp(entity, Prop_Send, "m_clrRender"))
    {
        PrintToChat(client, "\x04Target entity has no color property.");
        return Plugin_Handled;
    }

    int color = GetEntProp(entity, Prop_Send, "m_clrRender");
    int rgba[4];
    rgba[0] = ((color >> 00) & 0xFF);
    rgba[1] = ((color >> 08) & 0xFF);
    rgba[2] = ((color >> 16) & 0xFF);
    rgba[3] = ((color >> 24) & 0xFF);

    char classname[36];
    GetEntityClassname(entity, classname, sizeof(classname));

    char modelname[PLATFORM_MAX_PATH];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));

    PrintToChat(client, "\x05Index: \x03%i \x05Classname: \x03%s \x05Model: \x03%s \x05Color (RGBA|Integer): \x03%i %i %i %i|%i", entity, classname, modelname, rgba[0], rgba[1], rgba[2], rgba[3], color);

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdReload(int client, int args)
{
    LoadConfigs();

    RemoveAll();

    LateLoad();

    if (IsValidClient(client))
        PrintToChat(client, "\x04Color configs reloaded.");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdRemove(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (!IsValidEntity(entity))
    {
        PrintToChat(client, "\x04Invalid target.");
        return Plugin_Handled;
    }

    if (!HasEntProp(entity, Prop_Send, "m_clrRender"))
    {
        PrintToChat(client, "\x04Target entity has no color property.");
        return Plugin_Handled;
    }

    if (ge_iRGBA[entity] == NOCOLOR)
    {
        PrintToChat(client, "\x04Target entity color hasn't been overrided.");
        return Plugin_Handled;
    }

    SetEntProp(entity, Prop_Send, "m_clrRender", ge_iRGBA[entity]);
    ge_iRGBA[entity] = NOCOLOR;

    int find = g_alPluginEntities.FindValue(EntIndexToEntRef(entity));
    if (find != -1)
        g_alPluginEntities.Push(EntIndexToEntRef(entity));

    PrintToChat(client, "\x04Removed target entity plugin color.");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdRemoveAll(int client, int args)
{
    RemoveAll();

    if (IsValidClient(client))
        PrintToChat(client, "\x04Removed all colors override made by the plugin.");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdAdd(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (entity == -1)
    {
        PrintToChat(client, "\x04Invalid target.");
        return Plugin_Handled;
    }

    if (!HasEntProp(entity, Prop_Send, "m_clrRender"))
    {
        PrintToChat(client, "\x04Target entity has no color property.");
        return Plugin_Handled;
    }

    if (ge_iRGBA[entity] == NOCOLOR)
        ge_iRGBA[entity] = GetEntProp(entity, Prop_Send, "m_clrRender");

    int renderColor[4];
    GetEntityRenderColor(entity, renderColor[0], renderColor[1], renderColor[2], renderColor[3]);

    if (g_bCvar_UseGlowColor && HasEntProp(entity, Prop_Send, "m_glowColorOverride") && GetEntProp(entity, Prop_Send, "m_glowColorOverride") != 0)
    {
        int glowColor = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
        renderColor[0] = ((glowColor >> 00) & 0xFF);
        renderColor[1] = ((glowColor >> 08) & 0xFF);
        renderColor[2] = ((glowColor >> 16) & 0xFF);
    }
    else if (g_iDefaultConfig[CONFIG_RANDOM] == 1)
    {
        renderColor[0] = GetRandomInt(0, 255);
        renderColor[1] = GetRandomInt(0, 255);
        renderColor[2] = GetRandomInt(0, 255);
    }
    else
    {
        renderColor[0] = g_iDefaultConfig[CONFIG_R];
        renderColor[1] = g_iDefaultConfig[CONFIG_G];
        renderColor[2] = g_iDefaultConfig[CONFIG_B];
    }

    SetEntityRenderColor(entity, renderColor[0], renderColor[1], renderColor[2], renderColor[3]);

    int find = g_alPluginEntities.FindValue(EntIndexToEntRef(entity));
    if (find != -1)
        g_alPluginEntities.Push(EntIndexToEntRef(entity));

    PrintToChat(client, "\x04Color added to target entity.");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdAll(int client, int args)
{
    RemoveAll();

    int entity;
    int glowColor;
    int renderColor[4];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
    {
        if (entity < 0)
            continue;

        if (!HasEntProp(entity, Prop_Send, "m_clrRender"))
            continue;

        if (ge_iRGBA[entity] == NOCOLOR)
            ge_iRGBA[entity] = GetEntProp(entity, Prop_Send, "m_clrRender");

        GetEntityRenderColor(entity, renderColor[0], renderColor[1], renderColor[2], renderColor[3]);

        if (g_bCvar_UseGlowColor && HasEntProp(entity, Prop_Send, "m_glowColorOverride") && GetEntProp(entity, Prop_Send, "m_glowColorOverride") != 0)
        {
            glowColor = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
            renderColor[0] = ((glowColor >> 00) & 0xFF);
            renderColor[1] = ((glowColor >> 08) & 0xFF);
            renderColor[2] = ((glowColor >> 16) & 0xFF);
        }
        else if (g_iDefaultConfig[CONFIG_RANDOM] == 1)
        {
            renderColor[0] = GetRandomInt(0, 255);
            renderColor[1] = GetRandomInt(0, 255);
            renderColor[2] = GetRandomInt(0, 255);
        }
        else
        {
            renderColor[0] = g_iDefaultConfig[CONFIG_R];
            renderColor[1] = g_iDefaultConfig[CONFIG_G];
            renderColor[2] = g_iDefaultConfig[CONFIG_B];
        }

        SetEntityRenderColor(entity, renderColor[0], renderColor[1], renderColor[2], renderColor[3]);

        g_alPluginEntities.Push(EntIndexToEntRef(entity));
    }

    if (IsValidClient(client))
        PrintToChat(client, "\x04Color added to all valid entities.");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (l4d_random_entity_color) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_random_entity_color_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_random_entity_color_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_random_entity_color_use_glow_color : %b (%s)", g_bCvar_UseGlowColor, g_bCvar_UseGlowColor ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------------------- Array List -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "g_alPluginEntities count : %i", g_alPluginEntities.Length);
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
 * @param client          Client index.
 * @return                True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client          Client index.
 * @return                True if client index is valid and client is in game, false otherwise.
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
 * Returns the integer array value of a RGB string.
 * Format: Three values between 0-255 separated by spaces. "<0-255> <0-255> <0-255>"
 * Example: "255 255 255"
 *
 * @param sColor        RGB color string.
 * @return              Integer array (int[3]) value of the RGB string or {0,0,0} if not in specified format.
 */
int[] ConvertRGBToIntArray(char[] sColor)
{
    int color[3];

    if (sColor[0] == 0)
        return color;

    char sColors[3][4];
    int count = ExplodeString(sColor, " ", sColors, sizeof(sColors), sizeof(sColors[]));

    switch (count)
    {
        case 1:
        {
            color[0] = StringToInt(sColors[0]);
        }
        case 2:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
        }
        case 3:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
            color[2] = StringToInt(sColors[2]);
        }
    }

    return color;
}