/**
// ====================================================================================================
Change Log:

1.0.7 (01-May-2021)
    - Added cvar to enable chase on every valid survivor instead only the shooter. (thanks "MasterMind420" for the idea)
    - Added some checks to prevent zombies chasing players in death, team change or disconnect events.

1.0.6 (08-March-2021)
    - Added cvars to disable the chase while pipe bomb, vomit or another external chase are active. (thanks "MasterMind420" for helping me)

1.0.5 (13-February-2021)
    - Fixed a wrong spawn position to warn common zombies. (thanks "Beatles" and "Maur0" for reporting)

1.0.4 (26-January-2021)
    - Added multiple cvars to configure which weapons should warn common zombies. (thanks "Sony Arizona" for requesting)
    - Added L4D1 support for silencer upgrade.

1.0.3 (09-January-2021)
    - Added cvar to control if common zombies should be warned while a tank is alive. (thanks "Mi.Cura" for requesting)
    - Added cvar to control if common zombies should be warned while in starting safe area.

1.0.2 (04-January-2021)
    - Added cvar to control the chance for the silenced smg weapon. L4D2 only. (thanks "MedicDTI " for requesting)

1.0.1 (03-January-2021)
    - Fixed invalid entity error on FindEntityByClassname. (thanks "Krufftys Killers" for reporting)
    - Added sm_forcechase admin command.

1.0.0 (31-December-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Shot Warns Common"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Warns common zombies when shooting"
#define PLUGIN_VERSION                "1.0.7"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=329613"

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
#define CONFIG_FILENAME               "l4d_shot_warns_common"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_INFO_GOAL_INFECTED_CHASE     "info_goal_infected_chase"

#define CLASSNAME_PROP_MINIGUN        "prop_minigun"
#define CLASSNAME_PROP_MINIGUN_L4D1   "prop_minigun_l4d1"

#define SOUND_HEGRENADE_BEEP          "weapons/hegrenade/beep.wav"

#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define L4D1_ZOMBIECLASS_TANK         5
#define L4D2_ZOMBIECLASS_TANK         8

#define L4D1_UPGRADE_SILENCER         (1 << 18) // 262144

#define L4D2_WEPID_PISTOL                   1
#define L4D2_WEPID_SMG_UZI                  2
#define L4D2_WEPID_PUMP_SHOTGUN             3
#define L4D2_WEPID_AUTO_SHOTGUN             4
#define L4D2_WEPID_RIFLE_M16                5
#define L4D2_WEPID_HUNTING_RIFLE            6
#define L4D2_WEPID_SMG_SILENCED             7
#define L4D2_WEPID_SHOTGUN_CHROME           8
#define L4D2_WEPID_RIFLE_DESERT             9
#define L4D2_WEPID_SNIPER_MILITARY          10
#define L4D2_WEPID_SHOTGUN_SPAS             11
#define L4D2_WEPID_MOLOTOV                  13
#define L4D2_WEPID_PIPE_BOMB                14
#define L4D2_WEPID_PAIN_PILLS               15
#define L4D2_WEPID_GASCAN                   16
#define L4D2_WEPID_PROPANE_TANK             17
#define L4D2_WEPID_OXYGEN_TANK              18
#define L4D2_WEPID_MELEE                    19
#define L4D2_WEPID_CHAINSAW                 20
#define L4D2_WEPID_GRENADE_LAUNCHER         21
#define L4D2_WEPID_ADRENALINE               23
#define L4D2_WEPID_VOMIT_JAR                25
#define L4D2_WEPID_RIFLE_AK47               26
#define L4D2_WEPID_GNOME                    27
#define L4D2_WEPID_COLA_BOTTLES             28
#define L4D2_WEPID_FIREWORKS_CRATE          29
#define L4D2_WEPID_PISTOL_MAGNUM            32
#define L4D2_WEPID_SMG_MP5                  33
#define L4D2_WEPID_RIFLE_SG552              34
#define L4D2_WEPID_SNIPER_AWP               35
#define L4D2_WEPID_SNIPER_SCOUT             36
#define L4D2_WEPID_RIFLE_M60                37
#define L4D2_WEPID_MACHINE_GUN              54

#define L4D2_WEPID_MELEE_FIREAXE            0
#define L4D2_WEPID_MELEE_FRYING_PAN         1
#define L4D2_WEPID_MELEE_MACHETE            2
#define L4D2_WEPID_MELEE_BASEBALL_BAT       3
#define L4D2_WEPID_MELEE_CROWBAR            4
#define L4D2_WEPID_MELEE_CRICKET_BAT        5
#define L4D2_WEPID_MELEE_TONFA              6
#define L4D2_WEPID_MELEE_KATANA             7
#define L4D2_WEPID_MELEE_ELECTRIC_GUITAR    8
#define L4D2_WEPID_MELEE_KNIFE              9
#define L4D2_WEPID_MELEE_GOLFCLUB           10
#define L4D2_WEPID_MELEE_PITCHFORK          11
#define L4D2_WEPID_MELEE_SHOVEL             12
#define L4D2_WEPID_MELEE_RIOTSHIELD         13
#define L4D2_WEPID_MELEE_CUSTOM             -1

#define L4D1_WEPID_PISTOL                   1
#define L4D1_WEPID_SMG_UZI                  2
#define L4D1_WEPID_PUMP_SHOTGUN             3
#define L4D1_WEPID_AUTO_SHOTGUN             4
#define L4D1_WEPID_RIFLE_M16                5
#define L4D1_WEPID_HUNTING_RIFLE            6
#define L4D1_WEPID_MOLOTOV                  9
#define L4D1_WEPID_PIPE_BOMB               10
#define L4D1_WEPID_PAIN_PILLS              12
#define L4D1_WEPID_MACHINE_GUN             29

// ====================================================================================================
// Native Cvars
// ====================================================================================================
static ConVar g_hCvar_pipe_bomb_initial_beep_interval;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Bots;
static ConVar g_hCvar_SafeArea;
static ConVar g_hCvar_Everyone;
static ConVar g_hCvar_PipeBombBeep;
static ConVar g_hCvar_ExternalChase;
static ConVar g_hCvar_TankAlive;
static ConVar g_hCvar_Duration;
static ConVar g_hCvar_Chance;
static ConVar g_hCvar_Pistol;
static ConVar g_hCvar_Pistol_Magnum;
static ConVar g_hCvar_PumpShotgun;
static ConVar g_hCvar_Shotgun_Chrome;
static ConVar g_hCvar_AutoShotgun;
static ConVar g_hCvar_Shotgun_Spas;
static ConVar g_hCvar_SMG_Uzi;
static ConVar g_hCvar_SMG_Silenced;
static ConVar g_hCvar_SMG_MP5;
static ConVar g_hCvar_Rifle_M16;
static ConVar g_hCvar_Rifle_Desert;
static ConVar g_hCvar_Rifle_AK47;
static ConVar g_hCvar_Rifle_SG552;
static ConVar g_hCvar_Rifle_M60;
static ConVar g_hCvar_Hunting_Rifle;
static ConVar g_hCvar_Sniper_Military;
static ConVar g_hCvar_Sniper_Scout;
static ConVar g_hCvar_Sniper_AWP;
static ConVar g_hCvar_Grenade_Launcher;
static ConVar g_hCvar_Chainsaw;
static ConVar g_hCvar_Minigun;
static ConVar g_hCvar_50Cal;
static ConVar g_hCvar_Melee_Baseball_Bat;
static ConVar g_hCvar_Melee_Cricket_Bat;
static ConVar g_hCvar_Melee_Crowbar;
static ConVar g_hCvar_Melee_Electric_Guitar;
static ConVar g_hCvar_Melee_Fireaxe;
static ConVar g_hCvar_Melee_Frying_Pan;
static ConVar g_hCvar_Melee_Golfclub;
static ConVar g_hCvar_Melee_Katana;
static ConVar g_hCvar_Melee_Knife;
static ConVar g_hCvar_Melee_Machete;
static ConVar g_hCvar_Melee_Tonfa;
static ConVar g_hCvar_Melee_Pitchfork;
static ConVar g_hCvar_Melee_Shovel;
static ConVar g_hCvar_Melee_RiotShield;
static ConVar g_hCvar_Melee_Custom;
static ConVar g_hCvar_Molotov;
static ConVar g_hCvar_PipeBomb;
static ConVar g_hCvar_VomitJar;
static ConVar g_hCvar_PainPills;
static ConVar g_hCvar_Adrenaline;
static ConVar g_hCvar_Gascan;
static ConVar g_hCvar_PropaneTank;
static ConVar g_hCvar_OxygenTank;
static ConVar g_hCvar_FireworksCrate;
static ConVar g_hCvar_Gnome;
static ConVar g_hCvar_ColaBottles;
static ConVar g_hCvar_UpgradeSilencer;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bConfigLoaded;
static bool   g_bEventsHooked;
static bool   g_bAliveTank;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Bots;
static bool   g_bCvar_SafeArea;
static bool   g_bCvar_Everyone;
static bool   g_bCvar_PipeBombBeep;
static bool   g_bCvar_ExternalChase;
static bool   g_bCvar_TankAlive;
static bool   g_bCvar_Chance;
static bool   g_bCvar_Pistol;
static bool   g_bCvar_Pistol_Magnum;
static bool   g_bCvar_PumpShotgun;
static bool   g_bCvar_Shotgun_Chrome;
static bool   g_bCvar_AutoShotgun;
static bool   g_bCvar_Shotgun_Spas;
static bool   g_bCvar_SMG_Uzi;
static bool   g_bCvar_SMG_Silenced;
static bool   g_bCvar_SMG_MP5;
static bool   g_bCvar_Rifle_M16;
static bool   g_bCvar_Rifle_Desert;
static bool   g_bCvar_Rifle_AK47;
static bool   g_bCvar_Rifle_SG552;
static bool   g_bCvar_Rifle_M60;
static bool   g_bCvar_Hunting_Rifle;
static bool   g_bCvar_Sniper_Military;
static bool   g_bCvar_Sniper_Scout;
static bool   g_bCvar_Sniper_AWP;
static bool   g_bCvar_Grenade_Launcher;
static bool   g_bCvar_Chainsaw;
static bool   g_bCvar_Minigun;
static bool   g_bCvar_50Cal;
static bool   g_bCvar_Melee_Baseball_Bat;
static bool   g_bCvar_Melee_Cricket_Bat;
static bool   g_bCvar_Melee_Crowbar;
static bool   g_bCvar_Melee_Electric_Guitar;
static bool   g_bCvar_Melee_Fireaxe;
static bool   g_bCvar_Melee_Frying_Pan;
static bool   g_bCvar_Melee_Golfclub;
static bool   g_bCvar_Melee_Katana;
static bool   g_bCvar_Melee_Knife;
static bool   g_bCvar_Melee_Machete;
static bool   g_bCvar_Melee_Tonfa;
static bool   g_bCvar_Melee_Pitchfork;
static bool   g_bCvar_Melee_Shovel;
static bool   g_bCvar_Melee_RiotShield;
static bool   g_bCvar_Melee_Custom;
static bool   g_bCvar_Molotov;
static bool   g_bCvar_PipeBomb;
static bool   g_bCvar_VomitJar;
static bool   g_bCvar_PainPills;
static bool   g_bCvar_Adrenaline;
static bool   g_bCvar_Gascan;
static bool   g_bCvar_PropaneTank;
static bool   g_bCvar_OxygenTank;
static bool   g_bCvar_FireworksCrate;
static bool   g_bCvar_Gnome;
static bool   g_bCvar_ColaBottles;
static bool   g_bCvar_UpgradeSilencer;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iTankClass;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_pipe_bomb_initial_beep_interval;
static float  g_fLastPipeBombBeep;
static float  g_fCvar_Duration;
static float  g_fCvar_Chance;

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
static StringMap g_smMeleeIDs;

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
static ArrayList g_alChaseEntities;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static bool   gc_bGoalEnable[MAXPLAYERS+1];
static int    gc_iGoalEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE , ... };
static float  gc_fGoalLastShot[MAXPLAYERS+1];

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
    g_iTankClass = (g_bL4D2 ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK);

    g_smMeleeIDs = new StringMap();
    g_alChaseEntities = new ArrayList();

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    BuildMaps();

    g_hCvar_pipe_bomb_initial_beep_interval = FindConVar("pipe_bomb_initial_beep_interval");

    CreateConVar("l4d_shot_warns_common_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled                   = CreateConVar("l4d_shot_warns_common_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Bots                      = CreateConVar("l4d_shot_warns_common_bots", "1", "Allow plugin behaviour on survivor bots.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_SafeArea                  = CreateConVar("l4d_shot_warns_common_safe_area", "1", "Allow trigger common zombies while survivors are in the starting safe area.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Everyone                  = CreateConVar("l4d_shot_warns_common_everyone", "0", "Should the zombies attack all valid survivors.\n0 = Only the shooter, 1 = Every valid survivor.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_PipeBombBeep              = CreateConVar("l4d_shot_warns_common_pipe_bomb_beep", "0", "Trigger common zombies while Pipe Bomb is beeping.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ExternalChase             = CreateConVar("l4d_shot_warns_common_external_chase", "0", "Allow trigger common zombies while external chase entities are activated.\nExamples: intro/ending cutscenes, covered by vomit or [L4D2 only] vomit jar cloud.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_TankAlive                 = CreateConVar("l4d_shot_warns_common_tank_alive", "1", "Allow trigger common zombies while a tank is alive.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Duration                  = CreateConVar("l4d_shot_warns_common_duration", "1.0", "Duration (seconds) that common zombies can be warned after shooting.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Chance                    = CreateConVar("l4d_shot_warns_common_chance", "100.0", "Chance to trigger common zombies while firing.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Pistol                    = CreateConVar("l4d_shot_warns_common_pistol", "1", "Trigger common zombies while firing with a Pistol.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_PumpShotgun               = CreateConVar("l4d_shot_warns_common_pump_shotgun", "1", "Trigger common zombies while firing with a Pump Shotgun.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_AutoShotgun               = CreateConVar("l4d_shot_warns_common_auto_shotgun", "1", "Trigger common zombies while firing with a Auto Shotgun.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_SMG_Uzi                   = CreateConVar("l4d_shot_warns_common_smg_uzi", "1", "Trigger common zombies while firing with a SMG Uzi.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Rifle_M16                 = CreateConVar("l4d_shot_warns_common_rifle_m16", "1", "Trigger common zombies while firing with a M16 Rifle.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Hunting_Rifle             = CreateConVar("l4d_shot_warns_common_hunting_rifle", "1", "Trigger common zombies while firing with a Hunting Rifle.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Minigun                   = CreateConVar("l4d_shot_warns_common_machine_gun_minigun", "1", "Trigger common zombies while firing with a Minigun.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Molotov                   = CreateConVar("l4d_shot_warns_common_molotov", "0", "Trigger common zombies while throwing a Molotov.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_PipeBomb                  = CreateConVar("l4d_shot_warns_common_pipe_bomb", "0", "Trigger common zombies while throwing a Pipe Bomb.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_PainPills                 = CreateConVar("l4d_shot_warns_common_pain_pills", "0", "Trigger common zombies while using a Pain Pills.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    if (g_bL4D2)
    {
        g_hCvar_Pistol_Magnum         = CreateConVar("l4d_shot_warns_common_pistol_magnum", "1", "Trigger common zombies while firing with a Pistol Magnum.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Shotgun_Chrome        = CreateConVar("l4d_shot_warns_common_shotgun_chrome", "1", "Trigger common zombies while firing with a Chrome Shotgun.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Shotgun_Spas          = CreateConVar("l4d_shot_warns_common_shotgun_spas", "1", "Trigger common zombies while firing with a Spas Shotgun.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_SMG_Silenced          = CreateConVar("l4d_shot_warns_common_smg_silenced", "0", "Trigger common zombies while firing with a Silenced SMG weapon.\nL4D2 only.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_SMG_MP5               = CreateConVar("l4d_shot_warns_common_smg_mp5", "1", "Trigger common zombies while firing with a SMG MP5.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Rifle_Desert          = CreateConVar("l4d_shot_warns_common_rifle_desert", "1", "Trigger common zombies while firing with a Desert Rifle.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Rifle_AK47            = CreateConVar("l4d_shot_warns_common_rifle_ak47", "1", "Trigger common zombies while firing with a AK47 Rifle.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Rifle_SG552           = CreateConVar("l4d_shot_warns_common_rifle_sg552", "1", "Trigger common zombies while firing with a SG552 Rifle.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Rifle_M60             = CreateConVar("l4d_shot_warns_common_rifle_m60", "1", "Trigger common zombies while firing with a M60 Rifle.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Sniper_Military       = CreateConVar("l4d_shot_warns_common_sniper_military", "1", "Trigger common zombies while firing with a Military Sniper.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Sniper_Scout          = CreateConVar("l4d_shot_warns_common_sniper_scout", "1", "Trigger common zombies while firing with a Scout Sniper.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Sniper_AWP            = CreateConVar("l4d_shot_warns_common_sniper_awp", "1", "Trigger common zombies while firing with a AWP Sniper.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Grenade_Launcher      = CreateConVar("l4d_shot_warns_common_grenade_launcher", "1", "Trigger common zombies while firing with a Grenade Launcher.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Chainsaw              = CreateConVar("l4d_shot_warns_common_chainsaw", "1", "Trigger common zombies while firing with a Chainsaw.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_50Cal                 = CreateConVar("l4d_shot_warns_common_machine_gun_50cal", "1", "Trigger common zombies while firing with a 50cal.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Baseball_Bat    = CreateConVar("l4d_shot_warns_common_melee_baseball_bat", "0", "Trigger common zombies while attacking with a Baseball Bat.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Cricket_Bat     = CreateConVar("l4d_shot_warns_common_melee_cricket_bat", "0", "Trigger common zombies while attacking with a Cricket Bat.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Crowbar         = CreateConVar("l4d_shot_warns_common_melee_crowbar", "0", "Trigger common zombies while attacking with a Crowbar.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Electric_Guitar = CreateConVar("l4d_shot_warns_common_melee_electric_guitar", "0", "Trigger common zombies while attacking with an Electric Guitar.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Fireaxe         = CreateConVar("l4d_shot_warns_common_melee_fireaxe", "0", "Trigger common zombies while attacking with a Fire Axe.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Frying_Pan      = CreateConVar("l4d_shot_warns_common_melee_frying_pan", "0", "Trigger common zombies while attacking with a Frying Pan.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Golfclub        = CreateConVar("l4d_shot_warns_common_melee_golfclub", "0", "Trigger common zombies while attacking with a Golf Club.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Katana          = CreateConVar("l4d_shot_warns_common_melee_katana", "0", "Trigger common zombies while attacking with a Katana.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Knife           = CreateConVar("l4d_shot_warns_common_melee_knife", "0", "Trigger common zombies while attacking with a Knife.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Machete         = CreateConVar("l4d_shot_warns_common_melee_machete", "0", "Trigger common zombies while attacking with a Machete.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Tonfa           = CreateConVar("l4d_shot_warns_common_melee_tonfa", "0", "Trigger common zombies while attacking with a Tonfa.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Pitchfork       = CreateConVar("l4d_shot_warns_common_melee_pitchfork", "0", "Trigger common zombies while attacking with a Pitchfork.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Shovel          = CreateConVar("l4d_shot_warns_common_melee_shovel", "0", "Trigger common zombies while attacking with a Shovel.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_RiotShield      = CreateConVar("l4d_shot_warns_common_melee_riotshield", "0", "Trigger common zombies while attacking with a Riot Shield.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Melee_Custom          = CreateConVar("l4d_shot_warns_common_melee_custom", "0", "Trigger common zombies while attacking with Custom Melees.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_VomitJar              = CreateConVar("l4d_shot_warns_common_vomit_jar", "0", "Trigger common zombies while throwing a Vomit Jar.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Adrenaline            = CreateConVar("l4d_shot_warns_common_adrenaline", "0", "Trigger common zombies while an Adrenaline.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Gascan                = CreateConVar("l4d_shot_warns_common_gascan", "0", "Trigger common zombies while throwing or pouring a Gascan.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_PropaneTank           = CreateConVar("l4d_shot_warns_common_propane_tank", "0", "Trigger common zombies while throwing a Propane Tank.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_OxygenTank            = CreateConVar("l4d_shot_warns_common_oxygen_tank", "0", "Trigger common zombies while throwing an Oxygen Tank.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_FireworksCrate        = CreateConVar("l4d_shot_warns_common_fireworks_crate", "0", "Trigger common zombies while throwing a Fireworks Crate.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_Gnome                 = CreateConVar("l4d_shot_warns_common_gnome", "0", "Trigger common zombies while throwing a Gnome.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_ColaBottles           = CreateConVar("l4d_shot_warns_common_cola_bottles", "0", "Trigger common zombies throwing or delivering a Cola Bottles.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    }

    g_hCvar_UpgradeSilencer           = CreateConVar("l4d_shot_warns_common_upgrade_silencer", "1", "Don't trigger common zombies while silencer upgrade is active.\nL4D1 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_pipe_bomb_initial_beep_interval.AddChangeHook(Event_ConVarChanged);

    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Bots.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SafeArea.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Everyone.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PipeBombBeep.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ExternalChase.AddChangeHook(Event_ConVarChanged);
    g_hCvar_TankAlive.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Duration.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Chance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Pistol.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PumpShotgun.AddChangeHook(Event_ConVarChanged);
    g_hCvar_AutoShotgun.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SMG_Uzi.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Rifle_M16.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Hunting_Rifle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Minigun.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Molotov.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PipeBomb.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PainPills.AddChangeHook(Event_ConVarChanged);

    if (g_bL4D2)
    {
        g_hCvar_Pistol_Magnum.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Shotgun_Chrome.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Shotgun_Spas.AddChangeHook(Event_ConVarChanged);
        g_hCvar_SMG_Silenced.AddChangeHook(Event_ConVarChanged);
        g_hCvar_SMG_MP5.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Rifle_Desert.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Rifle_AK47.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Rifle_SG552.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Rifle_M60.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Sniper_Military.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Sniper_Scout.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Sniper_AWP.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Grenade_Launcher.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Chainsaw.AddChangeHook(Event_ConVarChanged);
        g_hCvar_50Cal.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Baseball_Bat.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Cricket_Bat.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Crowbar.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Electric_Guitar.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Fireaxe.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Frying_Pan.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Golfclub.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Katana.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Knife.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Machete.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Tonfa.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Pitchfork.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Shovel.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_RiotShield.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Melee_Custom.AddChangeHook(Event_ConVarChanged);
        g_hCvar_VomitJar.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Adrenaline.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Gascan.AddChangeHook(Event_ConVarChanged);
        g_hCvar_PropaneTank.AddChangeHook(Event_ConVarChanged);
        g_hCvar_OxygenTank.AddChangeHook(Event_ConVarChanged);
        g_hCvar_FireworksCrate.AddChangeHook(Event_ConVarChanged);
        g_hCvar_Gnome.AddChangeHook(Event_ConVarChanged);
        g_hCvar_ColaBottles.AddChangeHook(Event_ConVarChanged);
    }
    else
    {
        g_hCvar_UpgradeSilencer.AddChangeHook(Event_ConVarChanged);
    }

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_forcechase", CmdForceChase, ADMFLAG_ROOT, "Force common zombies chase on self (no args) or specified targets. Example: self -> sm_forcechase / target -> sm_forcechase @bots");
    RegAdminCmd("sm_print_cvars_l4d_shot_warns_common", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");

    CreateTimer(1.0, TimerAliveTankCheck, _, TIMER_REPEAT);
    CreateTimer(1.0, TimerDisable, _, TIMER_REPEAT);
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    int entity;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (gc_iGoalEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iGoalEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
                AcceptEntityInput(entity, "Kill");

            gc_iGoalEntRef[client] = INVALID_ENT_REFERENCE;
        }
    }
}

/****************************************************************************************************/

public void BuildMaps()
{
    // Melees
    g_smMeleeIDs.Clear();
    g_smMeleeIDs.SetValue("fireaxe",         L4D2_WEPID_MELEE_FIREAXE);
    g_smMeleeIDs.SetValue("frying_pan",      L4D2_WEPID_MELEE_FRYING_PAN);
    g_smMeleeIDs.SetValue("machete",         L4D2_WEPID_MELEE_MACHETE);
    g_smMeleeIDs.SetValue("baseball_bat",    L4D2_WEPID_MELEE_BASEBALL_BAT);
    g_smMeleeIDs.SetValue("crowbar",         L4D2_WEPID_MELEE_CROWBAR);
    g_smMeleeIDs.SetValue("cricket_bat",     L4D2_WEPID_MELEE_CRICKET_BAT);
    g_smMeleeIDs.SetValue("tonfa",           L4D2_WEPID_MELEE_TONFA);
    g_smMeleeIDs.SetValue("katana",          L4D2_WEPID_MELEE_KATANA);
    g_smMeleeIDs.SetValue("electric_guitar", L4D2_WEPID_MELEE_ELECTRIC_GUITAR);
    g_smMeleeIDs.SetValue("knife",           L4D2_WEPID_MELEE_KNIFE);
    g_smMeleeIDs.SetValue("golfclub",        L4D2_WEPID_MELEE_GOLFCLUB);
    g_smMeleeIDs.SetValue("pitchfork",       L4D2_WEPID_MELEE_PITCHFORK);
    g_smMeleeIDs.SetValue("shovel",          L4D2_WEPID_MELEE_SHOVEL);
    g_smMeleeIDs.SetValue("riotshield",      L4D2_WEPID_MELEE_RIOTSHIELD);
    g_smMeleeIDs.SetValue("custom",          L4D2_WEPID_MELEE_CUSTOM);
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
    g_fCvar_pipe_bomb_initial_beep_interval = g_hCvar_pipe_bomb_initial_beep_interval.FloatValue;
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_Bots = g_hCvar_Bots.BoolValue;
    g_fCvar_Duration = g_hCvar_Duration.FloatValue;
    g_bCvar_SafeArea = g_hCvar_SafeArea.BoolValue;
    g_bCvar_Everyone = g_hCvar_Everyone.BoolValue;
    g_bCvar_PipeBombBeep = g_hCvar_PipeBombBeep.BoolValue;
    g_bCvar_ExternalChase = g_hCvar_ExternalChase.BoolValue;
    g_bCvar_TankAlive = g_hCvar_TankAlive.BoolValue;
    g_fCvar_Chance = g_hCvar_Chance.FloatValue;
    g_bCvar_Chance = (g_fCvar_Chance > 0.0);
    g_bCvar_Pistol = g_hCvar_Pistol.BoolValue;
    g_bCvar_PumpShotgun = g_hCvar_PumpShotgun.BoolValue;
    g_bCvar_AutoShotgun = g_hCvar_AutoShotgun.BoolValue;
    g_bCvar_SMG_Uzi = g_hCvar_SMG_Uzi.BoolValue;
    g_bCvar_Rifle_M16 = g_hCvar_Rifle_M16.BoolValue;
    g_bCvar_Hunting_Rifle = g_hCvar_Hunting_Rifle.BoolValue;
    g_bCvar_Minigun = g_hCvar_Minigun.BoolValue;
    g_bCvar_Molotov = g_hCvar_Molotov.BoolValue;
    g_bCvar_PipeBomb = g_hCvar_PipeBomb.BoolValue;
    g_bCvar_PipeBombBeep = g_hCvar_PipeBomb.BoolValue;
    g_bCvar_PainPills = g_hCvar_PainPills.BoolValue;

    if (g_bL4D2)
    {
        g_bCvar_Pistol_Magnum = g_hCvar_Pistol_Magnum.BoolValue;
        g_bCvar_Shotgun_Chrome = g_hCvar_Shotgun_Chrome.BoolValue;
        g_bCvar_Shotgun_Spas = g_hCvar_Shotgun_Spas.BoolValue;
        g_bCvar_SMG_Silenced = g_hCvar_SMG_Silenced.BoolValue;
        g_bCvar_SMG_MP5 = g_hCvar_SMG_MP5.BoolValue;
        g_bCvar_Rifle_Desert = g_hCvar_Rifle_Desert.BoolValue;
        g_bCvar_Rifle_AK47 = g_hCvar_Rifle_AK47.BoolValue;
        g_bCvar_Rifle_SG552 = g_hCvar_Rifle_SG552.BoolValue;
        g_bCvar_Rifle_M60 = g_hCvar_Rifle_M60.BoolValue;
        g_bCvar_Sniper_Military = g_hCvar_Sniper_Military.BoolValue;
        g_bCvar_Sniper_Scout = g_hCvar_Sniper_Scout.BoolValue;
        g_bCvar_Sniper_AWP = g_hCvar_Sniper_AWP.BoolValue;
        g_bCvar_Grenade_Launcher = g_hCvar_Grenade_Launcher.BoolValue;
        g_bCvar_Chainsaw = g_hCvar_Chainsaw.BoolValue;
        g_bCvar_50Cal = g_hCvar_50Cal.BoolValue;
        g_bCvar_Melee_Baseball_Bat = g_hCvar_Melee_Baseball_Bat.BoolValue;
        g_bCvar_Melee_Cricket_Bat = g_hCvar_Melee_Cricket_Bat.BoolValue;
        g_bCvar_Melee_Crowbar = g_hCvar_Melee_Crowbar.BoolValue;
        g_bCvar_Melee_Electric_Guitar = g_hCvar_Melee_Electric_Guitar.BoolValue;
        g_bCvar_Melee_Fireaxe = g_hCvar_Melee_Fireaxe.BoolValue;
        g_bCvar_Melee_Frying_Pan = g_hCvar_Melee_Frying_Pan.BoolValue;
        g_bCvar_Melee_Golfclub = g_hCvar_Melee_Golfclub.BoolValue;
        g_bCvar_Melee_Katana = g_hCvar_Melee_Katana.BoolValue;
        g_bCvar_Melee_Knife = g_hCvar_Melee_Knife.BoolValue;
        g_bCvar_Melee_Machete = g_hCvar_Melee_Machete.BoolValue;
        g_bCvar_Melee_Tonfa = g_hCvar_Melee_Tonfa.BoolValue;
        g_bCvar_Melee_Pitchfork = g_hCvar_Melee_Pitchfork.BoolValue;
        g_bCvar_Melee_Shovel = g_hCvar_Melee_Shovel.BoolValue;
        g_bCvar_Melee_RiotShield = g_hCvar_Melee_RiotShield.BoolValue;
        g_bCvar_Melee_Custom = g_hCvar_Melee_Custom.BoolValue;
        g_bCvar_VomitJar = g_hCvar_VomitJar.BoolValue;
        g_bCvar_Adrenaline = g_hCvar_Adrenaline.BoolValue;
        g_bCvar_Gascan = g_hCvar_Gascan.BoolValue;
        g_bCvar_PropaneTank = g_hCvar_PropaneTank.BoolValue;
        g_bCvar_OxygenTank = g_hCvar_OxygenTank.BoolValue;
        g_bCvar_FireworksCrate = g_hCvar_FireworksCrate.BoolValue;
        g_bCvar_Gnome = g_hCvar_Gnome.BoolValue;
        g_bCvar_ColaBottles = g_hCvar_ColaBottles.BoolValue;
    }
    else
    {
        g_bCvar_UpgradeSilencer = g_hCvar_UpgradeSilencer.BoolValue;
    }
}

/****************************************************************************************************/

public void LateLoad()
{
    if (g_bCvar_TankAlive)
        g_bAliveTank = HasAnyTankAlive();

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_INFO_GOAL_INFECTED_CHASE)) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    if (gc_bGoalEnable[client])
        DisableChase(client, true);
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("tank_spawn", Event_TankSpawn);
        HookEvent("player_death", Event_PlayerDeath);
        HookEvent("player_team", Event_PlayerTeam);
        HookEvent("weapon_fire", Event_WeaponFire);
        AddNormalSoundHook(SoundHook);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("tank_spawn", Event_TankSpawn);
        UnhookEvent("player_death", Event_PlayerDeath);
        UnhookEvent("player_team", Event_PlayerTeam);
        UnhookEvent("weapon_fire", Event_WeaponFire);
        RemoveNormalSoundHook(SoundHook);

        return;
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    int find = g_alChaseEntities.FindValue(entity);
    if (find != -1)
        g_alChaseEntities.Erase(find);
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 'i')
       return;

    if (StrEqual(classname, CLASSNAME_INFO_GOAL_INFECTED_CHASE))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnSpawnPost(int entity)
{
    if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1) // Ignore entities with hammerid -1
        return;

    if (g_alChaseEntities.FindValue(entity) == -1)
        g_alChaseEntities.Push(entity);

    for (int client = 1; client <= MaxClients; client++)
    {
        if (gc_bGoalEnable[client])
            DisableChase(client, true);
    }
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    OnSpawnPost(entity);
}

/****************************************************************************************************/

public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    if (g_bCvar_PipeBombBeep)
        return Plugin_Continue;

    if (!IsValidEntityIndex(entity))
        return Plugin_Continue;

    if (sample[0] != 'w')
        return Plugin_Continue;

    if (!HasEntProp(entity, Prop_Send, "m_bIsLive")) // *_projectile
        return Plugin_Continue;

    if (!StrEqual(sample, SOUND_HEGRENADE_BEEP))
        return Plugin_Continue;

    g_fLastPipeBombBeep = GetGameTime();

    for (int client = 1; client <= MaxClients; client++)
    {
        if (gc_bGoalEnable[client])
            DisableChase(client, true);
    }

    return Plugin_Continue;
}

/****************************************************************************************************/

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bCvar_TankAlive)
        g_bAliveTank = true;
}

/****************************************************************************************************/

public Action TimerAliveTankCheck(Handle timer)
{
    if (g_bAliveTank)
        g_bAliveTank = HasAnyTankAlive();

    return Plugin_Continue;
}

/****************************************************************************************************/

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client))
        return;

    if (gc_bGoalEnable[client])
        DisableChase(client, true);
}

/****************************************************************************************************/

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client))
        return;

    if (gc_bGoalEnable[client])
        DisableChase(client, true);
}

/****************************************************************************************************/

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_SafeArea && !HasAnySurvivorLeftSafeArea())
        return;

    if (!g_bCvar_PipeBombBeep && GetGameTime() - g_fLastPipeBombBeep < g_fCvar_pipe_bomb_initial_beep_interval)
        return;

    if (!g_bCvar_ExternalChase && g_alChaseEntities.Length > 0)
        return;

    if (!g_bCvar_TankAlive && g_bAliveTank)
        return;

    if (g_bCvar_Chance && g_fCvar_Chance < GetRandomFloat(0.0, 100.0))
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    int weaponid = event.GetInt("weaponid");

    if (!g_bL4D2)
    {
        if (g_bCvar_UpgradeSilencer && (GetEntProp(client, Prop_Send, "m_upgradeBitVec") & L4D1_UPGRADE_SILENCER))
            return;
    }

    if (!IsValidWeapon(client, weaponid))
        return;

    if (!IsValidClient(client))
        return;

    int team = GetClientTeam(client);

    if (team != TEAM_SURVIVOR && team != TEAM_HOLDOUT)
        return;

    if (!g_bCvar_Bots && IsFakeClient(client))
        return;

    if (g_bCvar_Everyone)
    {
        for (int target = 1; target <= MaxClients; target++)
        {
            if (client == target)
            {
                PerformChase(target);
            }
            else
            {
                if (!IsClientInGame(target))
                    continue;

                if (!IsPlayerAlive(target))
                    continue;

                team = GetClientTeam(target);

                if (team != TEAM_SURVIVOR && team != TEAM_HOLDOUT)
                    continue;

                if (!g_bCvar_Bots && IsFakeClient(target))
                    continue;

                PerformChase(target);
            }
        }
    }
    else
    {
        PerformChase(client);
    }
}

/****************************************************************************************************/

public void PerformChase(int client)
{
    int entity = EntRefToEntIndex(gc_iGoalEntRef[client]);

    if (entity == INVALID_ENT_REFERENCE)
    {
        float vPos[3];
        GetClientEyePosition(client, vPos);

        entity = CreateEntityByName(CLASSNAME_INFO_GOAL_INFECTED_CHASE);
        gc_iGoalEntRef[client] = EntIndexToEntRef(entity);
        DispatchKeyValue(entity, "targetname", "l4d_shot_warns_common");
        SetEntProp(entity, Prop_Data, "m_iHammerID", -1);

        TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(entity);
        ActivateEntity(entity);

        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", client);
    }

    gc_fGoalLastShot[client] = GetGameTime();

    if (!gc_bGoalEnable[client])
    {
        AcceptEntityInput(entity, "Enable");
        gc_bGoalEnable[client] = true;
    }
}

/****************************************************************************************************/

public bool IsValidWeapon(int client, int weaponid)
{
    if (g_bL4D2)
    {
        switch (weaponid)
        {
            case L4D2_WEPID_PISTOL:
            {
                if (!g_bCvar_Pistol)
                    return false;
            }
            case L4D2_WEPID_SMG_UZI:
            {
                if (!g_bCvar_SMG_Uzi)
                    return false;
            }
            case L4D2_WEPID_PUMP_SHOTGUN:
            {
                if (!g_bCvar_PumpShotgun)
                    return false;
            }
            case L4D2_WEPID_AUTO_SHOTGUN:
            {
                if (!g_bCvar_AutoShotgun)
                    return false;
            }
            case L4D2_WEPID_RIFLE_M16:
            {
                if (!g_bCvar_Rifle_M16)
                    return false;
            }
            case L4D2_WEPID_HUNTING_RIFLE:
            {
                if (!g_bCvar_Hunting_Rifle)
                    return false;
            }
            case L4D2_WEPID_SMG_SILENCED:
            {
                if (!g_bCvar_SMG_Silenced)
                    return false;
            }
            case L4D2_WEPID_SHOTGUN_CHROME:
            {
                if (!g_bCvar_Shotgun_Chrome)
                    return false;
            }
            case L4D2_WEPID_RIFLE_DESERT:
            {
                if (!g_bCvar_Rifle_Desert)
                    return false;
            }
            case L4D2_WEPID_SNIPER_MILITARY:
            {
                if (!g_bCvar_Sniper_Military)
                    return false;
            }
            case L4D2_WEPID_SHOTGUN_SPAS:
            {
                if (!g_bCvar_Shotgun_Spas)
                    return false;
            }
            case L4D2_WEPID_MOLOTOV:
            {
                if (!g_bCvar_Molotov)
                    return false;
            }
            case L4D2_WEPID_PIPE_BOMB:
            {
                if (!g_bCvar_PipeBomb)
                    return false;
            }
            case L4D2_WEPID_PAIN_PILLS:
            {
                if (!g_bCvar_PainPills)
                    return false;
            }
            case L4D2_WEPID_GASCAN:
            {
                if (!g_bCvar_Gascan)
                    return false;
            }
            case L4D2_WEPID_PROPANE_TANK:
            {
                if (!g_bCvar_PropaneTank)
                    return false;
            }
            case L4D2_WEPID_OXYGEN_TANK:
            {
                if (!g_bCvar_OxygenTank)
                    return false;
            }
            case L4D2_WEPID_MELEE:
            {
                int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

                if (!IsValidEntity(activeWeapon))
                    return false;

                if (!HasEntProp(activeWeapon, Prop_Data, "m_strMapSetScriptName")) // CTerrorMeleeWeapon
                    return false;

                int meleeid;
                char meleeName[16];
                GetEntPropString(activeWeapon, Prop_Data, "m_strMapSetScriptName", meleeName, sizeof(meleeName));

                if (!g_smMeleeIDs.GetValue(meleeName, meleeid))
                    g_smMeleeIDs.GetValue("custom", meleeid);

                switch (meleeid)
                {
                    case L4D2_WEPID_MELEE_FIREAXE:
                    {
                        if (!g_bCvar_Melee_Fireaxe)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_FRYING_PAN:
                    {
                        if (!g_bCvar_Melee_Frying_Pan)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_MACHETE:
                    {
                        if (!g_bCvar_Melee_Machete)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_BASEBALL_BAT:
                    {
                        if (!g_bCvar_Melee_Baseball_Bat)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_CROWBAR:
                    {
                        if (!g_bCvar_Melee_Crowbar)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_CRICKET_BAT:
                    {
                        if (!g_bCvar_Melee_Cricket_Bat)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_TONFA:
                    {
                        if (!g_bCvar_Melee_Tonfa)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_KATANA:
                    {
                        if (!g_bCvar_Melee_Katana)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_ELECTRIC_GUITAR:
                    {
                        if (!g_bCvar_Melee_Electric_Guitar)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_KNIFE:
                    {
                        if (!g_bCvar_Melee_Knife)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_GOLFCLUB:
                    {
                        if (!g_bCvar_Melee_Golfclub)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_PITCHFORK:
                    {
                        if (!g_bCvar_Melee_Pitchfork)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_SHOVEL:
                    {
                        if (!g_bCvar_Melee_Shovel)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_RIOTSHIELD:
                    {
                        if (!g_bCvar_Melee_RiotShield)
                            return false;
                    }
                    case L4D2_WEPID_MELEE_CUSTOM:
                    {
                        if (!g_bCvar_Melee_Custom)
                            return false;
                    }
                }
            }
            case L4D2_WEPID_CHAINSAW:
            {
                if (!g_bCvar_Chainsaw)
                    return false;
            }
            case L4D2_WEPID_GRENADE_LAUNCHER:
            {
                if (!g_bCvar_Grenade_Launcher)
                    return false;
            }
            case L4D2_WEPID_ADRENALINE:
            {
                if (!g_bCvar_Adrenaline)
                    return false;
            }
            case L4D2_WEPID_VOMIT_JAR:
            {
                if (!g_bCvar_VomitJar)
                    return false;
            }
            case L4D2_WEPID_RIFLE_AK47:
            {
                if (!g_bCvar_Rifle_AK47)
                    return false;
            }
            case L4D2_WEPID_GNOME:
            {
                if (!g_bCvar_Gnome)
                    return false;
            }
            case L4D2_WEPID_COLA_BOTTLES:
            {
                if (!g_bCvar_ColaBottles)
                    return false;
            }
            case L4D2_WEPID_FIREWORKS_CRATE:
            {
                if (!g_bCvar_FireworksCrate)
                    return false;
            }
            case L4D2_WEPID_PISTOL_MAGNUM:
            {
                if (!g_bCvar_Pistol_Magnum)
                    return false;
            }
            case L4D2_WEPID_SMG_MP5:
            {
                if (!g_bCvar_SMG_MP5)
                    return false;
            }
            case L4D2_WEPID_RIFLE_SG552:
            {
                if (!g_bCvar_Rifle_SG552)
                    return false;
            }
            case L4D2_WEPID_SNIPER_AWP:
            {
                if (!g_bCvar_Sniper_AWP)
                    return false;
            }
            case L4D2_WEPID_SNIPER_SCOUT:
            {
                if (!g_bCvar_Sniper_Scout)
                    return false;
            }
            case L4D2_WEPID_RIFLE_M60:
            {
                if (!g_bCvar_Rifle_M60)
                    return false;
            }
            case L4D2_WEPID_MACHINE_GUN:
            {
                if (g_bCvar_Minigun && g_bCvar_50Cal)
                    return true;

                if (!g_bCvar_Minigun && !g_bCvar_50Cal)
                    return false;

                int machineGun = GetEntPropEnt(client, Prop_Data, "m_hUseEntity");

                if (!IsValidEntity(machineGun))
                    return false;

                if (!HasEntProp(machineGun, Prop_Send, "m_heat")) // CPropMinigun / CPropMountedGun
                    return false;

                char classname[18];
                GetEntityClassname(machineGun, classname, sizeof(classname));

                if (StrEqual(classname, CLASSNAME_PROP_MINIGUN))
                {
                    if (!g_bCvar_50Cal)
                        return false;
                }
                else if (StrEqual(classname, CLASSNAME_PROP_MINIGUN_L4D1))
                {
                    if (!g_bCvar_Minigun)
                        return false;
                }
            }
            default:
            {
                return false;
            }
        }
    }
    else
    {
        switch (weaponid)
        {
            case L4D1_WEPID_PISTOL:
            {
                if (!g_bCvar_Pistol)
                    return false;
            }
            case L4D1_WEPID_SMG_UZI:
            {
                if (!g_bCvar_SMG_Uzi)
                    return false;
            }
            case L4D1_WEPID_PUMP_SHOTGUN:
            {
                if (!g_bCvar_PumpShotgun)
                    return false;
            }
            case L4D1_WEPID_AUTO_SHOTGUN:
            {
                if (!g_bCvar_AutoShotgun)
                    return false;
            }
            case L4D1_WEPID_RIFLE_M16:
            {
                if (!g_bCvar_Rifle_M16)
                    return false;
            }
            case L4D1_WEPID_HUNTING_RIFLE:
            {
                if (!g_bCvar_Hunting_Rifle)
                    return false;
            }
            case L4D1_WEPID_MOLOTOV:
            {
                if (!g_bCvar_Molotov)
                    return false;
            }
            case L4D1_WEPID_PIPE_BOMB:
            {
                if (!g_bCvar_PipeBomb)
                    return false;
            }
            case L4D1_WEPID_PAIN_PILLS:
            {
                if (!g_bCvar_PainPills)
                    return false;
            }
            case L4D1_WEPID_MACHINE_GUN:
            {
                if (!g_bCvar_Minigun)
                    return false;
            }
            default:
            {
                return false;
            }
        }
    }

    return true;
}

/****************************************************************************************************/

public Action TimerDisable(Handle timer)
{
    if (!g_bConfigLoaded)
        return Plugin_Continue;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!gc_bGoalEnable[client])
            continue;

        if (GetGameTime() - gc_fGoalLastShot[client] < g_fCvar_Duration)
            continue;

        DisableChase(client, false);
    }

    return Plugin_Continue;
}

/****************************************************************************************************/

void DisableChase(int client, bool kill)
{
    gc_bGoalEnable[client] = false;

    if (gc_iGoalEntRef[client] == INVALID_ENT_REFERENCE)
        return;

    int entity = EntRefToEntIndex(gc_iGoalEntRef[client]);

    if (entity == INVALID_ENT_REFERENCE)
    {
        gc_iGoalEntRef[client] = INVALID_ENT_REFERENCE;
        return;
    }

    AcceptEntityInput(entity, "Disable");

    if (kill)
    {
        gc_iGoalEntRef[client] = INVALID_ENT_REFERENCE;
        gc_fGoalLastShot[client] = 0.0;
        AcceptEntityInput(entity, "Kill");
    }
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdForceChase(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (args == 0) // self
    {
        PerformChase(client);
        return Plugin_Handled;
    }
    else // specified target
    {
        char sArg[64];
        GetCmdArg(1, sArg, sizeof(sArg));

        char target_name[MAX_TARGET_LENGTH];
        int target_list[MAXPLAYERS];
        int target_count;
        bool tn_is_ml;

        if ((target_count = ProcessTargetString(
            sArg,
            client,
            target_list,
            sizeof(target_list),
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
        {
            return Plugin_Handled;
        }

        for (int i = 0; i < target_count; i++)
        {
            PerformChase(target_list[i]);
        }
    }

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_shot_warns_common) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_shot_warns_common_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_shot_warns_common_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_bots : %b (%s)", g_bCvar_Bots, g_bCvar_Bots ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_safe_area : %b (%s)", g_bCvar_SafeArea, g_bCvar_SafeArea ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_everyone : %b (%s)", g_bCvar_Everyone, g_bCvar_Everyone ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_pipe_bomb_beep : %b (%s)", g_bCvar_PipeBombBeep, g_bCvar_PipeBombBeep ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_external_chase : %b (%s)", g_bCvar_ExternalChase, g_bCvar_ExternalChase ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_tank_alive : %b (%s)", g_bCvar_TankAlive, g_bCvar_TankAlive ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_duration : %.2f", g_fCvar_Duration);
    PrintToConsole(client, "l4d_shot_warns_common_chance : %.2f%% (%s)", g_fCvar_Chance, g_bCvar_Chance ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_pistol : %b (%s)", g_bCvar_Pistol, g_bCvar_Pistol ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_pistol_magnum : %b (%s)", g_bCvar_Pistol_Magnum, g_bCvar_Pistol_Magnum ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_pump_shotgun : %b (%s)", g_bCvar_PumpShotgun, g_bCvar_PumpShotgun ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_shotgun_chrome : %b (%s)", g_bCvar_Shotgun_Chrome, g_bCvar_Shotgun_Chrome ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_auto_shotgun : %b (%s)", g_bCvar_AutoShotgun, g_bCvar_AutoShotgun ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_shotgun_spas : %b (%s)", g_bCvar_Shotgun_Spas, g_bCvar_Shotgun_Spas ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_smg_uzi : %b (%s)", g_bCvar_SMG_Uzi, g_bCvar_SMG_Uzi ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_smg_silenced : %b (%s)", g_bCvar_SMG_Silenced, g_bCvar_SMG_Silenced ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_smg_mp5 : %b (%s)", g_bCvar_SMG_MP5, g_bCvar_SMG_MP5 ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_rifle_m16 : %b (%s)", g_bCvar_Rifle_M16, g_bCvar_Rifle_M16 ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_rifle_desert : %b (%s)", g_bCvar_Rifle_Desert, g_bCvar_Rifle_Desert ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_rifle_ak47 : %b (%s)", g_bCvar_Rifle_AK47, g_bCvar_Rifle_AK47 ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_rifle_sg552 : %b (%s)", g_bCvar_Rifle_SG552, g_bCvar_Rifle_SG552 ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_rifle_m60 : %b (%s)", g_bCvar_Rifle_M60, g_bCvar_Rifle_M60 ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_hunting_rifle : %b (%s)", g_bCvar_Hunting_Rifle, g_bCvar_Hunting_Rifle ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_sniper_military : %b (%s)", g_bCvar_Sniper_Military, g_bCvar_Sniper_Military ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_sniper_scout : %b (%s)", g_bCvar_Sniper_Scout, g_bCvar_Sniper_Scout ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_sniper_awp : %b (%s)", g_bCvar_Sniper_AWP, g_bCvar_Sniper_AWP ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_grenade_launcher : %b (%s)", g_bCvar_Grenade_Launcher, g_bCvar_Grenade_Launcher ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_chainsaw : %b (%s)", g_bCvar_Chainsaw, g_bCvar_Chainsaw ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_machine_gun_minigun : %b (%s)", g_bCvar_Minigun, g_bCvar_Minigun ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_machine_gun_50cal : %b (%s)", g_bCvar_50Cal, g_bCvar_50Cal ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_baseball_bat : %b (%s)", g_bCvar_Melee_Baseball_Bat, g_bCvar_Melee_Baseball_Bat ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_cricket_bat : %b (%s)", g_bCvar_Melee_Cricket_Bat, g_bCvar_Melee_Cricket_Bat ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_crowbar : %b (%s)", g_bCvar_Melee_Crowbar, g_bCvar_Melee_Crowbar ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_electric_guitar : %b (%s)", g_bCvar_Melee_Electric_Guitar, g_bCvar_Melee_Electric_Guitar ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_fireaxe : %b (%s)", g_bCvar_Melee_Fireaxe, g_bCvar_Melee_Fireaxe ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_frying_pan : %b (%s)", g_bCvar_Melee_Frying_Pan, g_bCvar_Melee_Frying_Pan ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_golfclub : %b (%s)", g_bCvar_Melee_Golfclub, g_bCvar_Melee_Golfclub ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_katana : %b (%s)", g_bCvar_Melee_Katana, g_bCvar_Melee_Katana ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_knife : %b (%s)", g_bCvar_Melee_Knife, g_bCvar_Melee_Knife ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_machete : %b (%s)", g_bCvar_Melee_Machete, g_bCvar_Melee_Machete ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_tonfa : %b (%s)", g_bCvar_Melee_Tonfa, g_bCvar_Melee_Tonfa ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_pitchfork : %b (%s)", g_bCvar_Melee_Pitchfork, g_bCvar_Melee_Pitchfork ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_shovel : %b (%s)", g_bCvar_Melee_Shovel, g_bCvar_Melee_Shovel ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_riotshield : %b (%s)", g_bCvar_Melee_RiotShield, g_bCvar_Melee_RiotShield ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_melee_custom : %b (%s)", g_bCvar_Melee_Custom, g_bCvar_Melee_Custom ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_molotov : %b (%s)", g_bCvar_Molotov, g_bCvar_Molotov ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_pipe_bomb : %b (%s)", g_bCvar_PipeBomb, g_bCvar_PipeBomb ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_vomit_jar : %b (%s)", g_bCvar_VomitJar, g_bCvar_VomitJar ? "true" : "false");
    PrintToConsole(client, "l4d_shot_warns_common_pain_pills : %b (%s)", g_bCvar_PainPills, g_bCvar_PainPills ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_adrenaline : %b (%s)", g_bCvar_Adrenaline, g_bCvar_Adrenaline ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_gascan : %b (%s)", g_bCvar_Gascan, g_bCvar_Gascan ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_propane_tank : %b (%s)", g_bCvar_PropaneTank, g_bCvar_PropaneTank ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_oxygen_tank : %b (%s)", g_bCvar_OxygenTank, g_bCvar_OxygenTank ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_fireworks_crate : %b (%s)", g_bCvar_FireworksCrate, g_bCvar_FireworksCrate ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_gnome : %b (%s)", g_bCvar_Gnome, g_bCvar_Gnome ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_cola_bottles : %b (%s)", g_bCvar_ColaBottles, g_bCvar_ColaBottles ? "true" : "false");
    if (!g_bL4D2) PrintToConsole(client, "l4d_shot_warns_common_upgrade_silencer : %b (%s)", g_bCvar_UpgradeSilencer, g_bCvar_UpgradeSilencer ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "pipe_bomb_initial_beep_interval : %.2f", g_fCvar_pipe_bomb_initial_beep_interval);
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

/****************************************************************************************************/

/**
 * Gets the client L4D1/L4D2 zombie class id.
 *
 * @param client        Client index.
 * @return L4D1         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED
 */
int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}

/****************************************************************************************************/

/**
 * Returns if the client is in ghost state.
 *
 * @param client        Client index.
 * @return              True if client is in ghost state, false otherwise.
 */
bool IsPlayerGhost(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}

/****************************************************************************************************/

/**
 * Validates if the client is incapacitated.
 *
 * @param client        Client index.
 * @return              True if the client is incapacitated, false otherwise.
 */
bool IsPlayerIncapacitated(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1);
}

/****************************************************************************************************/

/**
 * Returns if the client is a valid tank.
 *
 * @param client        Client index.
 * @return              True if client is a tank, false otherwise.
 */
bool IsPlayerTank(int client)
{
    if (GetClientTeam(client) != TEAM_INFECTED)
        return false;

    if (!IsPlayerAlive(client))
        return false;

    if (IsPlayerGhost(client))
        return false;

    if (GetZombieClass(client) != g_iTankClass)
        return false;

    return true;
}

/****************************************************************************************************/

/**
 * Returns if any tank is alive.
 *
 * @return              True if any tank is alive, false otherwise.
 */
bool HasAnyTankAlive()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (!IsPlayerTank(client))
            continue;

        if (IsPlayerIncapacitated(client))
            continue;

        return true;
    }

    return false;
}

/****************************************************************************************************/

/**
 * Returns whether any survivor have left the safe area.
 *
 * @return              True if any survivor have left safe area, false otherwise.
 */
static int g_iEntTerrorPlayerManager = INVALID_ENT_REFERENCE;
bool HasAnySurvivorLeftSafeArea()
{
    int entity = EntRefToEntIndex(g_iEntTerrorPlayerManager);

    if (entity == INVALID_ENT_REFERENCE)
        entity = FindEntityByClassname(-1, "terror_player_manager");

    if (entity == INVALID_ENT_REFERENCE)
    {
        g_iEntTerrorPlayerManager = INVALID_ENT_REFERENCE;
        return false;
    }

    g_iEntTerrorPlayerManager = EntIndexToEntRef(entity);

    return (GetEntProp(entity, Prop_Send, "m_hasAnySurvivorLeftSafeArea") == 1);
}