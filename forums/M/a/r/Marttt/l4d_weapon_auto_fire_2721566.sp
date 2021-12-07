/**
// ====================================================================================================
Change Log:

1.0.9 (07-March-2021)
    - Fixed minigun not firing. (thanks "Mi.Cura" for reporting)

1.0.8 (08-January-2021)
    - Added config for dual pistols. (thanks "SDArt" dor requesting)

1.0.7 (30-November-2020)
    - Fixed a bug preventing the shotgun to auto reload after releasing a minigun/50 cal.

1.0.6 (15-November-2020)
    - Added missing activeWeapon checks to prevent errors. (thanks "Tonblader" for reporting)

1.0.5 (03-November-2020)
    - Fixed auto fire after releasing a minigun/50 cal. (thanks "ur5efj" for reporting)

1.0.4 (27-October-2020)
    - Added auto reload config for shotgun to full clip. (thanks "KRUTIK" for requesting)
    - Added config to force pistol sound on second shot onwards for the shooter. (thanks "MasterMe" for requesting)

1.0.3 (27-October-2020)
    - Added auto reload config for shotgun to single bullets. (thanks "KRUTIK" for requesting)

1.0.2 (26-October-2020)
    - Fixed auto fire not working on weapon switch.

1.0.1 (19-October-2020)
    - Added new cvars to control frame delays of each weapon.
    - Nerfed the pistol shooting speed.

1.0.0 (16-October-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Weapon Auto Fire"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Allows weapons to auto fire by just holding the attack button (M1)"
#define PLUGIN_VERSION                "1.0.9"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=327919"

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
#define CONFIG_FILENAME               "l4d_weapon_auto_fire"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_WEAPON_PUMPSHOTGUN        "weapon_pumpshotgun"
#define CLASSNAME_WEAPON_SHOTGUN_CHROME     "weapon_shotgun_chrome"
#define CLASSNAME_WEAPON_AUTOSHOTGUN        "weapon_autoshotgun"
#define CLASSNAME_WEAPON_SHOTGUN_SPAS       "weapon_shotgun_spas"

#define L4D2_SOUND_PISTOL_FIRE              ")weapons/pistol/gunfire/pistol_fire.wav"
#define L4D2_SOUND_PISTOL_DUAL_FIRE         ")weapons/pistol/gunfire/pistol_dual_fire.wav"

#define L4D1_SOUND_PISTOL_FIRE              "^weapons/pistol/gunfire/pistol_fire.wav"

#define TEAM_SURVIVOR                 2
#define TEAM_HOLDOUT                  4

#define L4D2_WEPID_PISTOL             1
#define L4D2_WEPID_PUMP_SHOTGUN       3
#define L4D2_WEPID_AUTO_SHOTGUN       4
#define L4D2_WEPID_HUNTING_RIFLE      6
#define L4D2_WEPID_SHOTGUN_CHROME     8
#define L4D2_WEPID_SHOTGUN_SPAS       11
#define L4D2_WEPID_SNIPER_MILITARY    10
#define L4D2_WEPID_GRENADE_LAUNCHER   21
#define L4D2_WEPID_PISTOL_MAGNUM      32
#define L4D2_WEPID_SNIPER_AWP         35
#define L4D2_WEPID_SNIPER_SCOUT       36

#define L4D1_WEPID_PISTOL             1
#define L4D1_WEPID_PUMP_SHOTGUN       3
#define L4D1_WEPID_AUTO_SHOTGUN       4
#define L4D1_WEPID_HUNTING_RIFLE      6

#define SHOTGUN_RELOAD_TYPE_NONE      0
#define SHOTGUN_RELOAD_TYPE_SINGLE    1
#define SHOTGUN_RELOAD_TYPE_FULL      2

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_WeaponSwitch;
static ConVar g_hCvar_ShotgunReloadEmpty;
static ConVar g_hCvar_MachineGunRelease;
static ConVar g_hCvar_Pistol;
static ConVar g_hCvar_Pistol_Frame;
static ConVar g_hCvar_Pistol_ForceSound;
static ConVar g_hCvar_DualPistol;
static ConVar g_hCvar_DualPistol_Frame;
static ConVar g_hCvar_DualPistol_ForceSound;
static ConVar g_hCvar_Pistol_Magnum;
static ConVar g_hCvar_Pistol_Magnum_Frame;
static ConVar g_hCvar_PumpShotgun;
static ConVar g_hCvar_PumpShotgun_Frame;
static ConVar g_hCvar_Shotgun_Chrome;
static ConVar g_hCvar_Shotgun_Chrome_Frame;
static ConVar g_hCvar_AutoShotgun;
static ConVar g_hCvar_AutoShotgun_Frame;
static ConVar g_hCvar_Shotgun_Spas;
static ConVar g_hCvar_Shotgun_Spas_Frame;
static ConVar g_hCvar_Hunting_Rifle;
static ConVar g_hCvar_Hunting_Rifle_Frame;
static ConVar g_hCvar_Sniper_Military;
static ConVar g_hCvar_Sniper_Military_Frame;
static ConVar g_hCvar_Sniper_Scout;
static ConVar g_hCvar_Sniper_Scout_Frame;
static ConVar g_hCvar_Sniper_AWP;
static ConVar g_hCvar_Sniper_AWP_Frame;
static ConVar g_hCvar_Grenade_Launcher;
static ConVar g_hCvar_Grenade_Launcher_Frame;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bConfigLoaded;
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_WeaponSwitch;
static bool   g_bCvar_MachineGunRelease;
static bool   g_bCvar_Pistol;
static bool   g_bCvar_Pistol_Frame;
static bool   g_bCvar_Pistol_ForceSound;
static bool   g_bCvar_DualPistol;
static bool   g_bCvar_DualPistol_Frame;
static bool   g_bCvar_DualPistol_ForceSound;
static bool   g_bCvar_Pistol_Magnum;
static bool   g_bCvar_Pistol_Magnum_Frame;
static bool   g_bCvar_PumpShotgun;
static bool   g_bCvar_PumpShotgun_Frame;
static bool   g_bCvar_Shotgun_Chrome;
static bool   g_bCvar_Shotgun_Chrome_Frame;
static bool   g_bCvar_AutoShotgun;
static bool   g_bCvar_AutoShotgun_Frame;
static bool   g_bCvar_Shotgun_Spas;
static bool   g_bCvar_Shotgun_Spas_Frame;
static bool   g_bCvar_Hunting_Rifle;
static bool   g_bCvar_Hunting_Rifle_Frame;
static bool   g_bCvar_Sniper_Military;
static bool   g_bCvar_Sniper_Military_Frame;
static bool   g_bCvar_Sniper_Scout;
static bool   g_bCvar_Sniper_Scout_Frame;
static bool   g_bCvar_Sniper_AWP;
static bool   g_bCvar_Sniper_AWP_Frame;
static bool   g_bCvar_Grenade_Launcher;
static bool   g_bCvar_Grenade_Launcher_Frame;
static bool   g_bForceSound;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_ShotgunReloadEmpty;
static int    g_iCvar_Pistol_Frame;
static int    g_iCvar_DualPistol_Frame;
static int    g_iCvar_Pistol_Magnum_Frame;
static int    g_iCvar_PumpShotgun_Frame;
static int    g_iCvar_Shotgun_Chrome_Frame;
static int    g_iCvar_AutoShotgun_Frame;
static int    g_iCvar_Shotgun_Spas_Frame;
static int    g_iCvar_Hunting_Rifle_Frame;
static int    g_iCvar_Sniper_Military_Frame;
static int    g_iCvar_Sniper_Scout_Frame;
static int    g_iCvar_Sniper_AWP_Frame;
static int    g_iCvar_Grenade_Launcher_Frame;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static int    gc_iWeaponFrame[MAXPLAYERS+1];
static int    gc_iWeaponFrameCount[MAXPLAYERS+1];
static bool   gc_bWeaponSwitched[MAXPLAYERS+1];
static bool   gc_bUsingMachineWeapon[MAXPLAYERS+1];
static bool   gc_bWeaponReloadShotgun[MAXPLAYERS+1];
static bool   gc_bWeaponPistolSound[MAXPLAYERS+1];
static int    gc_iCurrentButton[MAXPLAYERS+1];
static int    gc_iPreviousButton[MAXPLAYERS+1];

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
    CreateConVar("l4d_weapon_auto_fire_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled                    = CreateConVar("l4d_weapon_auto_fire_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_WeaponSwitch               = CreateConVar("l4d_weapon_auto_fire_weapon_switch", "1", "Auto fire on weapon switch.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_MachineGunRelease          = CreateConVar("l4d_weapon_auto_fire_machine_gun_release", "1", "Auto fire on Machine Guns (Minigun/50cal) release.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ShotgunReloadEmpty         = CreateConVar("l4d_weapon_auto_fire_shotgun_reload_empty", "1", "Auto shotgun reload when the ammo clip is empty.\n0 = OFF, 1 = ON, 2 = Enable but forces full reload.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_Pistol                     = CreateConVar("l4d_weapon_auto_fire_pistol", "1", "Auto fire for Pistol.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Pistol_Frame               = CreateConVar("l4d_weapon_auto_fire_pistol_frame", "3", "How many frames must wait to enable auto fire for Pistol.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);
    g_hCvar_Pistol_ForceSound          = CreateConVar("l4d_weapon_auto_fire_pistol_force_sound", "1", "Force pistol fire sound to the shooter while on auto-fire.\nOther clients aren't affected. The first shot is ignored.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_DualPistol                 = CreateConVar("l4d_weapon_auto_fire_dual_pistol", "1", "Auto fire for Dual Pistol.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_DualPistol_Frame           = CreateConVar("l4d_weapon_auto_fire_dual_pistol_frame", "3", "How many frames must wait to enable auto fire for Dual Pistol.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);
    g_hCvar_DualPistol_ForceSound      = CreateConVar("l4d_weapon_auto_fire_dual_pistol_force_sound", "1", "Force dual pistol fire sound to the shooter while on auto-fire.\nOther clients aren't affected. The first shot is ignored.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_PumpShotgun                = CreateConVar("l4d_weapon_auto_fire_pump_shotgun", "1", "Auto fire for Pump Shotgun.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_PumpShotgun_Frame          = CreateConVar("l4d_weapon_auto_fire_pump_shotgun_frame", "0", "How many frames must wait to enable auto fire for Pump Shotgun.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);
    g_hCvar_AutoShotgun                = CreateConVar("l4d_weapon_auto_fire_auto_shotgun", "1", "Auto fire for Auto Shotgun.\nAlready has auto fire on vanilla.\nEnabling makes it fire faster.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_AutoShotgun_Frame          = CreateConVar("l4d_weapon_auto_fire_auto_shotgun_frame", "0", "How many frames must wait to enable auto fire for Auto Shotgun.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);
    g_hCvar_Hunting_Rifle              = CreateConVar("l4d_weapon_auto_fire_hunting_rifle", "1", "Auto fire for Hunting Rifle.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Hunting_Rifle_Frame        = CreateConVar("l4d_weapon_auto_fire_hunting_rifle_frame", "0", "How many frames must wait to enable auto fire for Hunting Rifle.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);

    if (g_bL4D2)
    {
        g_hCvar_Pistol_Magnum          = CreateConVar("l4d_weapon_auto_fire_pistol_magnum", "1", "Auto fire for Pistol Magnum.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Pistol_Magnum_Frame    = CreateConVar("l4d_weapon_auto_fire_pistol_magnum_frame", "0", "How many frames must wait to enable auto fire for Pistol Magnum.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);
        g_hCvar_Shotgun_Chrome         = CreateConVar("l4d_weapon_auto_fire_shotgun_chrome", "1", "Auto fire for Chrome Shotgun.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Shotgun_Chrome_Frame   = CreateConVar("l4d_weapon_auto_fire_shotgun_chrome_frame", "0", "How many frames must wait to enable auto fire for Chrome Shotgun.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);
        g_hCvar_Shotgun_Spas           = CreateConVar("l4d_weapon_auto_fire_shotgun_spas", "1", "Auto fire for Spas Shotgun.\nL4D2 only.\nAlready has auto fire on vanilla.\nEnabling makes it fire faster.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Shotgun_Spas_Frame     = CreateConVar("l4d_weapon_auto_fire_shotgun_spas_frame", "0", "How many frames must wait to enable auto fire for Spas Shotgun.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);
        g_hCvar_Sniper_Military        = CreateConVar("l4d_weapon_auto_fire_sniper_military", "1", "Auto fire for Military Sniper.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Sniper_Military_Frame  = CreateConVar("l4d_weapon_auto_fire_sniper_military_frame", "0", "How many frames must wait to enable auto fire for Military Sniper.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);
        g_hCvar_Sniper_Scout           = CreateConVar("l4d_weapon_auto_fire_sniper_scout", "1", "Auto fire for Scout Sniper.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Sniper_Scout_Frame     = CreateConVar("l4d_weapon_auto_fire_sniper_scout_frame", "0", "How many frames must wait to enable auto fire for Scout Sniper.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);
        g_hCvar_Sniper_AWP             = CreateConVar("l4d_weapon_auto_fire_sniper_awp", "1", "Auto fire for AWP Sniper.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Sniper_AWP_Frame       = CreateConVar("l4d_weapon_auto_fire_sniper_awp_frame", "0", "How many frames must wait to enable auto fire for AWP Sniper.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);
        g_hCvar_Grenade_Launcher       = CreateConVar("l4d_weapon_auto_fire_grenade_launcher", "1", "Auto fire for Grenade Launcher.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Grenade_Launcher_Frame = CreateConVar("l4d_weapon_auto_fire_grenade_launcher_frame", "0", "How many frames must wait to enable auto fire for Grenade Launcher.\n0 = Instantly on \"weapon_fire\".", CVAR_FLAGS, true, 0.0);
    }

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_WeaponSwitch.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MachineGunRelease.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ShotgunReloadEmpty.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Pistol.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Pistol_Frame.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Pistol_ForceSound.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DualPistol.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DualPistol_Frame.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DualPistol_ForceSound.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PumpShotgun.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PumpShotgun_Frame.AddChangeHook(Event_ConVarChanged);
    g_hCvar_AutoShotgun.AddChangeHook(Event_ConVarChanged);
    g_hCvar_AutoShotgun_Frame.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Hunting_Rifle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Hunting_Rifle_Frame.AddChangeHook(Event_ConVarChanged);

    if (g_bL4D2)
    {
        g_hCvar_Pistol_Magnum.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Pistol_Magnum_Frame.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Shotgun_Chrome.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Shotgun_Chrome_Frame.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Shotgun_Spas.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Shotgun_Spas_Frame.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Sniper_Military.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Sniper_Military_Frame.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Sniper_Scout.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Sniper_Scout_Frame.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Sniper_AWP.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Sniper_AWP_Frame.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Grenade_Launcher.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Grenade_Launcher_Frame.AddChangeHook(Event_ConVarChanged);
    }

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_weapon_auto_fire", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_WeaponSwitch = g_hCvar_WeaponSwitch.BoolValue;
    g_bCvar_MachineGunRelease = g_hCvar_MachineGunRelease.BoolValue;
    g_iCvar_ShotgunReloadEmpty = g_hCvar_ShotgunReloadEmpty.IntValue;

    g_bCvar_Pistol = g_hCvar_Pistol.BoolValue;
    g_iCvar_Pistol_Frame = g_hCvar_Pistol_Frame.IntValue;
    g_bCvar_Pistol_Frame = (g_iCvar_Pistol_Frame > 0);
    g_bCvar_Pistol_ForceSound = (g_hCvar_Pistol_ForceSound.BoolValue);

    g_bCvar_DualPistol = g_hCvar_DualPistol.BoolValue;
    g_iCvar_DualPistol_Frame = g_hCvar_DualPistol_Frame.IntValue;
    g_bCvar_DualPistol_Frame = (g_iCvar_DualPistol_Frame > 0);
    g_bCvar_DualPistol_ForceSound = (g_hCvar_DualPistol_ForceSound.BoolValue);

    g_bForceSound = (g_bCvar_Pistol_ForceSound || g_bCvar_DualPistol_ForceSound);

    g_bCvar_PumpShotgun = g_hCvar_PumpShotgun.BoolValue;
    g_iCvar_PumpShotgun_Frame = g_hCvar_PumpShotgun_Frame.IntValue;
    g_bCvar_PumpShotgun_Frame = (g_iCvar_PumpShotgun_Frame > 0);

    g_bCvar_AutoShotgun = g_hCvar_AutoShotgun.BoolValue;
    g_iCvar_AutoShotgun_Frame = g_hCvar_AutoShotgun_Frame.IntValue;
    g_bCvar_AutoShotgun_Frame = (g_iCvar_AutoShotgun_Frame > 0);

    g_bCvar_Hunting_Rifle = g_hCvar_Hunting_Rifle.BoolValue;
    g_iCvar_Hunting_Rifle_Frame = g_hCvar_Hunting_Rifle_Frame.IntValue;
    g_bCvar_Hunting_Rifle_Frame = (g_iCvar_Hunting_Rifle_Frame > 0);

    if (g_bL4D2)
    {
        g_bCvar_Pistol_Magnum = g_hCvar_Pistol_Magnum.BoolValue;
        g_iCvar_Pistol_Magnum_Frame = g_hCvar_Pistol_Magnum_Frame.IntValue;
        g_bCvar_Pistol_Magnum_Frame = (g_iCvar_Pistol_Magnum_Frame > 0);

        g_bCvar_Shotgun_Chrome = g_hCvar_Shotgun_Chrome.BoolValue;
        g_iCvar_Shotgun_Chrome_Frame = g_hCvar_Shotgun_Chrome_Frame.IntValue;
        g_bCvar_Shotgun_Chrome_Frame = (g_iCvar_Shotgun_Chrome_Frame > 0);

        g_bCvar_Shotgun_Spas = g_hCvar_Shotgun_Spas.BoolValue;
        g_iCvar_Shotgun_Spas_Frame = g_hCvar_Shotgun_Spas_Frame.IntValue;
        g_bCvar_Shotgun_Spas_Frame = (g_iCvar_Shotgun_Spas_Frame > 0);

        g_bCvar_Sniper_Military = g_hCvar_Sniper_Military.BoolValue;
        g_iCvar_Sniper_Military_Frame = g_hCvar_Sniper_Military_Frame.IntValue;
        g_bCvar_Sniper_Military_Frame = (g_iCvar_Sniper_Military_Frame > 0);

        g_bCvar_Sniper_Scout = g_hCvar_Sniper_Scout.BoolValue;
        g_iCvar_Sniper_Scout_Frame = g_hCvar_Sniper_Scout_Frame.IntValue;
        g_bCvar_Sniper_Scout_Frame = (g_iCvar_Sniper_Scout_Frame > 0);

        g_bCvar_Sniper_AWP = g_hCvar_Sniper_AWP.BoolValue;
        g_iCvar_Sniper_AWP_Frame = g_hCvar_Sniper_AWP_Frame.IntValue;
        g_bCvar_Sniper_AWP_Frame = (g_iCvar_Sniper_AWP_Frame > 0);

        g_bCvar_Grenade_Launcher = g_hCvar_Grenade_Launcher.BoolValue;
        g_iCvar_Grenade_Launcher_Frame = g_hCvar_Grenade_Launcher_Frame.IntValue;
        g_bCvar_Grenade_Launcher_Frame = (g_iCvar_Grenade_Launcher_Frame > 0);
    }
}

/****************************************************************************************************/

public void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);

        int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        OnWeaponSwitchPost(client, weapon);
    }

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop_m*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_heat")) // CPropMinigun / CPropMachineGun
            SDKHook(entity, SDKHook_UsePost, OnUsePost);
    }
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (!g_bConfigLoaded)
        return;

    if (IsFakeClient(client))
        return;

    SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_iWeaponFrame[client] = 0;
    gc_iWeaponFrameCount[client] = 0;
    gc_bWeaponSwitched[client] = false;
    gc_bUsingMachineWeapon[client] = false;
    gc_bWeaponReloadShotgun[client] = false;
    gc_bWeaponPistolSound[client] = false;
    gc_iPreviousButton[client] = 0;
    gc_iCurrentButton[client] = 0;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 'p')
       return;

    if (HasEntProp(entity, Prop_Send, "m_heat")) // CPropMinigun / CPropMachineGun
        SDKHook(entity, SDKHook_UsePost, OnUsePost);
}

/****************************************************************************************************/

public void OnUsePost(int entity, int activator, int caller, UseType type, float value)
{
    if (!g_bCvar_Enabled)
        return;

    if (!g_bCvar_MachineGunRelease)
        return;

    int client = GetEntPropEnt(entity, Prop_Send, "m_owner");

    if (!IsValidClient(client))
        return;

    gc_bUsingMachineWeapon[client] = true;
}

/****************************************************************************************************/

public void OnWeaponSwitchPost(int client, int weapon)
{
    if (!gc_bUsingMachineWeapon[client])
    {
        gc_bWeaponSwitched[client] = false;
        gc_bWeaponReloadShotgun[client] = false;
    }

    if (!g_bCvar_Enabled)
        return;

    if (!IsValidEntity(weapon))
        return;

    if (!g_bCvar_WeaponSwitch)
        return;

    if (!(GetClientButtons(client) & IN_ATTACK))
        return;

    int team = GetClientTeam(client);

    if (team != TEAM_SURVIVOR && team != TEAM_HOLDOUT)
        return;

    gc_bWeaponSwitched[client] = true;

    if (g_iCvar_ShotgunReloadEmpty == SHOTGUN_RELOAD_TYPE_NONE)
        return;

    int ammo = GetEntProp(weapon, Prop_Send, "m_iClip1", 1);

    if (ammo != 0)
        return;

    char classnameWeapon[22];
    GetEntityClassname(weapon, classnameWeapon, sizeof(classnameWeapon));

    if (StrEqual(classnameWeapon, CLASSNAME_WEAPON_PUMPSHOTGUN))
    {
        gc_bWeaponReloadShotgun[client] = true;
        return;
    }

    if (StrEqual(classnameWeapon, CLASSNAME_WEAPON_AUTOSHOTGUN))
    {
        gc_bWeaponReloadShotgun[client] = true;
        return;
    }

    if (!g_bL4D2)
        return;

    if (StrEqual(classnameWeapon, CLASSNAME_WEAPON_SHOTGUN_CHROME))
    {
        gc_bWeaponReloadShotgun[client] = true;
        return;
    }

    if (StrEqual(classnameWeapon, CLASSNAME_WEAPON_SHOTGUN_SPAS))
    {
        gc_bWeaponReloadShotgun[client] = true;
        return;
    }
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("weapon_fire", g_bL4D2 ? Event_WeaponFire_L4D2 : Event_WeaponFire_L4D1);
        AddNormalSoundHook(SoundHook);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("weapon_fire", g_bL4D2 ? Event_WeaponFire_L4D2 : Event_WeaponFire_L4D1);
        RemoveNormalSoundHook(SoundHook);

        return;
    }
}

/****************************************************************************************************/

public void Event_WeaponFire_L4D2(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client))
        return;

    if (IsFakeClient(client))
        return;

    gc_iWeaponFrame[client] = 0;
    gc_iWeaponFrameCount[client] = 0;
    gc_bWeaponPistolSound[client] = false;

    int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

    if (!IsValidEntity(activeWeapon))
        return;

    switch (event.GetInt("weaponid"))
    {
        case L4D2_WEPID_PISTOL:
        {
            int m_isDualWielding = GetEntProp(activeWeapon, Prop_Send, "m_isDualWielding"); // Dual Pistol

            if (m_isDualWielding == 1)
            {
                if (!g_bCvar_DualPistol)
                    return;

                gc_bWeaponPistolSound[client] = g_bCvar_DualPistol_ForceSound;

                if (g_bCvar_DualPistol_Frame)
                    gc_iWeaponFrame[client] = g_iCvar_DualPistol_Frame;
            }
            else // Pistol
            {
                if (!g_bCvar_Pistol)
                    return;

                gc_bWeaponPistolSound[client] = g_bCvar_Pistol_ForceSound;

                if (g_bCvar_Pistol_Frame)
                    gc_iWeaponFrame[client] = g_iCvar_Pistol_Frame;
            }
        }
        case L4D2_WEPID_PISTOL_MAGNUM:
        {
            if (!g_bCvar_Pistol_Magnum)
                return;

            if (g_bCvar_Pistol_Magnum_Frame)
                gc_iWeaponFrame[client] = g_iCvar_Pistol_Magnum_Frame;
        }
        case L4D2_WEPID_PUMP_SHOTGUN:
        {
            if (!g_bCvar_PumpShotgun)
                return;

            if (g_bCvar_PumpShotgun_Frame)
                gc_iWeaponFrame[client] = g_iCvar_PumpShotgun_Frame;

            if (g_iCvar_ShotgunReloadEmpty != SHOTGUN_RELOAD_TYPE_NONE)
            {
                int ammo = GetEntProp(activeWeapon, Prop_Send, "m_iClip1", 1);

                if (ammo == 1)
                    gc_bWeaponReloadShotgun[client] = true;
            }
        }
        case L4D2_WEPID_SHOTGUN_CHROME:
        {
            if (!g_bCvar_Shotgun_Chrome)
                return;

            if (g_bCvar_Shotgun_Chrome_Frame)
                gc_iWeaponFrame[client] = g_iCvar_Shotgun_Chrome_Frame;

            if (g_iCvar_ShotgunReloadEmpty != SHOTGUN_RELOAD_TYPE_NONE)
            {
                int ammo = GetEntProp(activeWeapon, Prop_Send, "m_iClip1", 1);

                if (ammo == 1)
                    gc_bWeaponReloadShotgun[client] = true;
            }
        }
        case L4D2_WEPID_AUTO_SHOTGUN:
        {
            if (!g_bCvar_AutoShotgun)
                return;

            if (g_bCvar_AutoShotgun_Frame)
                gc_iWeaponFrame[client] = g_iCvar_AutoShotgun_Frame;

            if (g_iCvar_ShotgunReloadEmpty != SHOTGUN_RELOAD_TYPE_NONE)
            {
                int ammo = GetEntProp(activeWeapon, Prop_Send, "m_iClip1", 1);

                if (ammo == 1)
                    gc_bWeaponReloadShotgun[client] = true;
            }
        }
        case L4D2_WEPID_SHOTGUN_SPAS:
        {
            if (!g_bCvar_Shotgun_Spas)
                return;

            if (g_bCvar_Shotgun_Spas_Frame)
                gc_iWeaponFrame[client] = g_iCvar_Shotgun_Spas_Frame;

            if (g_iCvar_ShotgunReloadEmpty != SHOTGUN_RELOAD_TYPE_NONE)
            {
                int ammo = GetEntProp(activeWeapon, Prop_Send, "m_iClip1", 1);

                if (ammo == 1)
                    gc_bWeaponReloadShotgun[client] = true;
            }
        }
        case L4D2_WEPID_HUNTING_RIFLE:
        {
            if (!g_bCvar_Hunting_Rifle)
                return;

            if (g_bCvar_Hunting_Rifle_Frame)
                gc_iWeaponFrame[client] = g_iCvar_Hunting_Rifle_Frame;
        }
        case L4D2_WEPID_SNIPER_MILITARY:
        {
            if (!g_bCvar_Sniper_Military)
                return;

            if (g_bCvar_Sniper_Military_Frame)
                gc_iWeaponFrame[client] = g_iCvar_Sniper_Military_Frame;
        }
        case L4D2_WEPID_SNIPER_SCOUT:
        {
            if (!g_bCvar_Sniper_Scout)
                return;

            if (g_bCvar_Sniper_Scout_Frame)
                gc_iWeaponFrame[client] = g_iCvar_Sniper_Scout_Frame;
        }
        case L4D2_WEPID_SNIPER_AWP:
        {
            if (!g_bCvar_Sniper_AWP)
                return;

            if (g_bCvar_Sniper_AWP_Frame)
                gc_iWeaponFrame[client] = g_iCvar_Sniper_AWP_Frame;
        }
        case L4D2_WEPID_GRENADE_LAUNCHER:
        {
            if (!g_bCvar_Grenade_Launcher)
                return;

            if (g_bCvar_Grenade_Launcher_Frame)
                gc_iWeaponFrame[client] = g_iCvar_Grenade_Launcher_Frame;
        }
        default:
        {
            return;
        }
    }

    if (gc_iWeaponFrame[client] != 0) // Continues the logic on OnPlayerRunCmd
        return;

    SetEntProp(activeWeapon, Prop_Send, "m_isHoldingFireButton", 0);
}

/****************************************************************************************************/

public void Event_WeaponFire_L4D1(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client))
        return;

    if (IsFakeClient(client))
        return;

    gc_iWeaponFrame[client] = 0;
    gc_iWeaponFrameCount[client] = 0;
    gc_bWeaponPistolSound[client] = false;

    int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

    if (!IsValidEntity(activeWeapon))
        return;

    switch (event.GetInt("weaponid"))
    {
        case L4D1_WEPID_PISTOL:
        {
            int m_isDualWielding = GetEntProp(activeWeapon, Prop_Send, "m_isDualWielding"); // Dual Pistol

            if (m_isDualWielding == 1)
            {
                if (!g_bCvar_DualPistol)
                    return;

                gc_bWeaponPistolSound[client] = g_bCvar_DualPistol_ForceSound;

                if (g_bCvar_DualPistol_Frame)
                    gc_iWeaponFrame[client] = g_iCvar_DualPistol_Frame;
            }
            else // Pistol
            {
                if (!g_bCvar_Pistol)
                    return;

                gc_bWeaponPistolSound[client] = g_bCvar_Pistol_ForceSound;

                if (g_bCvar_Pistol_Frame)
                    gc_iWeaponFrame[client] = g_iCvar_Pistol_Frame;
            }
        }
        case L4D1_WEPID_PUMP_SHOTGUN:
        {
            if (!g_bCvar_PumpShotgun)
                return;

            if (g_bCvar_PumpShotgun_Frame)
                gc_iWeaponFrame[client] = g_iCvar_PumpShotgun_Frame;

            if (g_iCvar_ShotgunReloadEmpty != SHOTGUN_RELOAD_TYPE_NONE)
            {
                int ammo = GetEntProp(activeWeapon, Prop_Send, "m_iClip1", 1);

                if (ammo == 1)
                    gc_bWeaponReloadShotgun[client] = true;
            }
        }
        case L4D1_WEPID_AUTO_SHOTGUN:
        {
            if (!g_bCvar_AutoShotgun)
                return;

            if (g_bCvar_AutoShotgun_Frame)
                gc_iWeaponFrame[client] = g_iCvar_AutoShotgun_Frame;

            if (g_iCvar_ShotgunReloadEmpty != SHOTGUN_RELOAD_TYPE_NONE)
            {
                int ammo = GetEntProp(activeWeapon, Prop_Send, "m_iClip1", 1);

                if (ammo == 1)
                    gc_bWeaponReloadShotgun[client] = true;
            }
        }
        case L4D1_WEPID_HUNTING_RIFLE:
        {
            if (!g_bCvar_Hunting_Rifle)
                return;

            if (g_bCvar_Hunting_Rifle_Frame)
                gc_iWeaponFrame[client] = g_iCvar_Hunting_Rifle_Frame;
        }
        default:
        {
            return;
        }
    }

    if (gc_iWeaponFrame[client] != 0) // Continues the logic on OnPlayerRunCmd
        return;

    SetEntProp(activeWeapon, Prop_Send, "m_isHoldingFireButton", 0);
}

/****************************************************************************************************/

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (!IsValidClientIndex(client))
        return Plugin_Continue;

    if (IsFakeClient(client))
        return Plugin_Continue;

    if (!(buttons & IN_ATTACK))
    {
        gc_iWeaponFrame[client] = 0;
        gc_iWeaponFrameCount[client] = 0;
        gc_bWeaponSwitched[client] = false;
        gc_bUsingMachineWeapon[client] = false;
        // Don't reset gc_bWeaponReloadShotgun[client] otherwise it can bug with double M1 click when ammo is 0
        gc_bWeaponPistolSound[client] = false;
        gc_iCurrentButton[client] = 0;
        gc_iPreviousButton[client] = 0;
        return Plugin_Continue;
    }

    if (gc_bUsingMachineWeapon[client])
    {
        int usingMachineWeapon = GetEntProp(client, Prop_Send, "m_usingMountedWeapon"); // Note: m_usingMountedGun does not work for L4D1 minigun

        if (usingMachineWeapon == 1)
            return Plugin_Continue;

        gc_bUsingMachineWeapon[client] = false;
        buttons &= ~IN_ATTACK;
        return Plugin_Changed;
    }

    if (gc_bWeaponSwitched[client])
    {
        gc_bWeaponSwitched[client] = false;
        buttons &= ~IN_ATTACK;
        return Plugin_Changed;
    }

    if (gc_bWeaponPistolSound[client])
    {
        gc_iPreviousButton[client] = gc_iCurrentButton[client];
        gc_iCurrentButton[client] = buttons;
    }

    if (gc_bWeaponReloadShotgun[client])
    {
        int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

        if (IsValidEntity(activeWeapon))
        {
            int ammo = GetEntProp(activeWeapon, Prop_Send, "m_iClip1", 1);

            switch (g_iCvar_ShotgunReloadEmpty)
            {
                case SHOTGUN_RELOAD_TYPE_SINGLE:
                {
                    if (ammo == 0)
                    {
                        buttons &= ~IN_ATTACK;
                        buttons |= IN_RELOAD;
                        return Plugin_Changed;
                    }
                }

                case SHOTGUN_RELOAD_TYPE_FULL:
                {
                    int m_bInReload = GetEntProp(activeWeapon, Prop_Send, "m_bInReload");

                    if (ammo == 0 || m_bInReload == 1)
                    {
                        buttons &= ~IN_ATTACK;
                        buttons |= IN_RELOAD;
                        return Plugin_Changed;
                    }
                }
            }
        }

        gc_bWeaponReloadShotgun[client] = false;
    }

    if (gc_iWeaponFrame[client] == 0)
        return Plugin_Continue;

    if (gc_iWeaponFrame[client] != gc_iWeaponFrameCount[client])
    {
        gc_iWeaponFrameCount[client]++;
        return Plugin_Continue;
    }

    gc_iWeaponFrame[client] = 0;
    gc_iWeaponFrameCount[client] = 0;

    buttons &= ~IN_ATTACK;

    return Plugin_Changed;
}

/****************************************************************************************************/

public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    if (!g_bForceSound)
        return Plugin_Continue;

    if (!IsValidClientIndex(entity))
        return Plugin_Continue;

    if (!gc_bWeaponPistolSound[entity])
        return Plugin_Continue;

    if (!(gc_iPreviousButton[entity] & IN_ATTACK))
        return Plugin_Continue;

    if (g_bL4D2)
    {
        if (sample[0] != ')')
            return Plugin_Continue;

        if (!(StrEqual(sample, L4D2_SOUND_PISTOL_FIRE) || StrEqual(sample, L4D2_SOUND_PISTOL_DUAL_FIRE)))
            return Plugin_Continue;
    }
    else
    {
        if (sample[0] != '^')
            return Plugin_Continue;

        if (!StrEqual(sample, L4D1_SOUND_PISTOL_FIRE))
            return Plugin_Continue;
    }

    gc_bWeaponPistolSound[entity] = false;

    for (int i = 0; i < numClients; i++)
    {
        if (clients[i] == entity)
            return Plugin_Continue;
    }

    clients[numClients++] = entity;

    return Plugin_Changed;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_weapon_auto_fire) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_weapon_auto_fire_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_weapon_auto_fire_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_weapon_switch : %b (%s)", g_bCvar_WeaponSwitch, g_bCvar_WeaponSwitch ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_machine_gun_release : %b (%s)", g_bCvar_MachineGunRelease, g_bCvar_MachineGunRelease ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_shotgun_reload_empty : %i (%s)", g_iCvar_ShotgunReloadEmpty, g_iCvar_ShotgunReloadEmpty > 0 ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_pistol : %b (%s)", g_bCvar_Pistol, g_bCvar_Pistol ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_pistol_frame : %i (%s)", g_iCvar_Pistol_Frame, g_bCvar_Pistol_Frame ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_pistol_force_sound : %b (%s)", g_bCvar_Pistol_ForceSound, g_bCvar_Pistol_ForceSound ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_dual_pistol : %b (%s)", g_bCvar_DualPistol, g_bCvar_DualPistol ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_dual_pistol_frame : %i (%s)", g_iCvar_DualPistol_Frame, g_bCvar_DualPistol_Frame ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_dual_pistol_force_sound : %b (%s)", g_bCvar_DualPistol_ForceSound, g_bCvar_DualPistol_ForceSound ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_pistol_magnum : %b (%s)", g_bCvar_Pistol_Magnum, g_bCvar_Pistol_Magnum ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_pistol_magnum_frame : %i (%s)", g_iCvar_Pistol_Magnum_Frame, g_bCvar_Pistol_Magnum_Frame ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_pump_shotgun : %b (%s)", g_bCvar_PumpShotgun, g_bCvar_PumpShotgun ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_pump_shotgun_frame : %i (%s)", g_iCvar_PumpShotgun_Frame, g_bCvar_PumpShotgun_Frame ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_shotgun_chrome : %b (%s)", g_bCvar_Shotgun_Chrome, g_bCvar_Shotgun_Chrome ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_shotgun_chrome_frame : %i (%s)", g_iCvar_Shotgun_Chrome_Frame, g_bCvar_Shotgun_Chrome_Frame ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_auto_shotgun : %b (%s)", g_bCvar_AutoShotgun, g_bCvar_AutoShotgun ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_auto_shotgun_frame : %i (%s)", g_iCvar_AutoShotgun_Frame, g_bCvar_AutoShotgun_Frame ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_shotgun_spas : %b (%s)", g_bCvar_Shotgun_Spas, g_bCvar_Shotgun_Spas ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_shotgun_spas_frame : %i (%s)", g_iCvar_Shotgun_Spas_Frame, g_bCvar_Shotgun_Spas_Frame ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_hunting_rifle : %b (%s)", g_bCvar_Hunting_Rifle, g_bCvar_Hunting_Rifle ? "true" : "false");
    PrintToConsole(client, "l4d_weapon_auto_fire_hunting_rifle_frame : %b (%s)", g_iCvar_Hunting_Rifle_Frame, g_bCvar_Hunting_Rifle_Frame ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_sniper_military : %b (%s)", g_bCvar_Sniper_Military, g_bCvar_Sniper_Military ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_sniper_military_frame : %i (%s)", g_iCvar_Sniper_Military_Frame, g_bCvar_Sniper_Military_Frame ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_sniper_scout : %b (%s)", g_bCvar_Sniper_Scout, g_bCvar_Sniper_Scout ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_sniper_scout_frame : %i (%s)", g_iCvar_Sniper_Scout_Frame, g_bCvar_Sniper_Scout_Frame ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_sniper_awp : %b (%s)", g_bCvar_Sniper_AWP, g_bCvar_Sniper_AWP ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_sniper_awp_frame : %i (%s)", g_iCvar_Sniper_AWP_Frame, g_bCvar_Sniper_AWP_Frame ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_grenade_launcher : %b (%s)", g_bCvar_Grenade_Launcher, g_bCvar_Grenade_Launcher ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_weapon_auto_fire_grenade_launcher_frame : %i (%s)", g_iCvar_Grenade_Launcher_Frame, g_bCvar_Grenade_Launcher_Frame ? "true" : "false");
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
 * Validates if is a valid entity index (between MaxClients+1 and 2048).
 *
 * @param entity        Entity index.
 * @return              True if entity index is valid, false otherwise.
 */
bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}