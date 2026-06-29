/**
// ====================================================================================================
Change Log:

1.0.9 (27-05-22)
	- Change description and funcionality of l4d2_nerf_damage_common_wound_dead. Now can prevents only leg-related wounds for no more flying commons and supports all commons and uncommons.

1.0.8 (03-March-2021)
    - Fixed incompatibility with the [L4D & L4D2] Dissolve Infected plugin. (thanks "jeremyvillanueva" for reporting, and "Silvers" for the code to fix)

1.0.7 (02-February-2021)
    - Fixed wrong damage from machine guns. (thanks Maur0 for reporting)
    - Fixed insta-kill cvar. (thanks Maur0 for reporting)

1.0.6 (01-February-2021)
    - Code changes to be able to compile directly from SM forum.
    - Fixed damage dropoff calculation, same as sv_damage 2. (precise distance calculation between attacker and victim)

1.0.5 (27-January-2021)
    - Fixed incendiary/explosive ammo logic.
    - Fixed melee protection check by entity.
    - Added cvar to nerf common damage to themselves. (when brawling or in vomit)

1.0.4 (26-January-2021)
    - Fixed wounds logic on melee hits. (thanks Maur0 for reporting)

1.0.3 (26-January-2021)
    - Fixed wrong damage flag with chainsaw. (thanks Maur0 for reporting)
    - Added damage dropoff logic and cvar. (decreases damage based on distance)
    - Added RangeModifier cvars for machine guns.
    - Added stumble effect cvar for non-melees.
    - Added stumble effect cvar for explosive ammo.
    - Added cvar to remove automatic stumble from shotguns.
    - Added cvar to ignore headshot.

1.0.2 (21-January-2021)
    - Added cvar allowing to stumble zombies on melee attack. (thanks Maur0 for requesting)
    - Fixed melee damage. (thanks Maur0 for reporting)
    - Fixed melee hit counting multiple times while using some custom damage flags.
    - Fixed headshot and insta-kill chance checks.
    - Added weapons damage on the print cvar command.
    - Ignoring 0 damage.

1.0.1 (20-January-2021)
    - Fixed some weapons burning commons. (thanks Maur0 for reporting)

1.0.0 (19-January-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Nerf Damage To Commons"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Nerfs some insta-kill damages dealt to commons"
#define PLUGIN_VERSION                "1.0.9"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=330085"

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
#define CONFIG_FILENAME               "l4d2_nerf_damage_common"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_INFECTED            "infected"

#define CLASSNAME_PROP_MINIGUN        "prop_minigun"
#define CLASSNAME_PROP_MINIGUN_L4D1   "prop_minigun_l4d1"

#define TEAM_SURVIVOR                 2
#define TEAM_HOLDOUT                  4

#define MAXENTITIES                   2048

#define HITGROUP_HEAD                 1

#define NO_WOUND                     -1

#define Z_DIFFICULTY_EASY             1
#define Z_DIFFICULTY_NORMAL           2
#define Z_DIFFICULTY_HARD             3
#define Z_DIFFICULTY_EXPERT           4

#define L4D2_WEPID_NONE                     0
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
#define L4D2_WEPID_MELEE                    19
#define L4D2_WEPID_CHAINSAW                 20
#define L4D2_WEPID_GRENADE_LAUNCHER         21
#define L4D2_WEPID_RIFLE_AK47               26
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

#define GENDER_FEMALE_L4D1            22
#define GENDER_FEMALE_L4D2            2
#define GENDER_MALE                   1
#define GENDER_MALE2                  21
#define GENDER_MALE3                  20
#define GENDER_MALE4                  0
#define GENDER_MALE5                  12
#define GENDER_MALE6                  13
#define GENDER_MALE7                  14
#define GENDER_MALE8                  16
#define GENDER_CEDA                   11
#define GENDER_RIOT                   15
#define PART_A                        3
#define PART_B                        4
#define PART_C                        5
#define PART_E                        8
#define PART_F                        9
#define PART_G                        13
#define PART_H                        14
#define PART_I                        15
#define PART_J                        16
#define PART_K                        17
#define PART_L                        19
#define PART_M                        20
#define PART_N                        21
#define PART_O                        22
#define PART_P                        23
#define PART_Q                        24
#define PART_R                        25

// ====================================================================================================
// Native Cvars
// ====================================================================================================
static ConVar g_hCvar_chainsaw_damage;
static ConVar g_hCvar_z_non_head_damage_factor_easy;
static ConVar g_hCvar_z_non_head_damage_factor_normal;
static ConVar g_hCvar_z_non_head_damage_factor_hard;
static ConVar g_hCvar_z_non_head_damage_factor_expert;
static ConVar g_hCvar_z_non_head_damage_factor_multiplier;
static ConVar g_hCvar_z_difficulty;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_IgnoreHeadshot;
static ConVar g_hCvar_InstaKillChance;
static ConVar g_hCvar_WoundDead;
static ConVar g_hCvar_DamageFactor;
static ConVar g_hCvar_DamageDropoff;
static ConVar g_hCvar_Common;
static ConVar g_hCvar_CommonDamage;
static ConVar g_hCvar_ShotgunStumble;
static ConVar g_hCvar_Pistol_Magnum;
static ConVar g_hCvar_Hunting_Rifle;
static ConVar g_hCvar_Sniper_Military;
static ConVar g_hCvar_Sniper_Scout;
static ConVar g_hCvar_Sniper_AWP;
static ConVar g_hCvar_Rifle_M60;
static ConVar g_hCvar_Chainsaw;
static ConVar g_hCvar_Minigun;
static ConVar g_hCvar_MinigunDamage;
static ConVar g_hCvar_MinigunRangeModifier;
static ConVar g_hCvar_50Cal;
static ConVar g_hCvar_50CalDamage;
static ConVar g_hCvar_50CalRangeModifier;
static ConVar g_hCvar_ExplosiveAmmo;
static ConVar g_hCvar_ExplosiveAmmoFactor;
static ConVar g_hCvar_ExplosiveAmmoStumble;
static ConVar g_hCvar_IncendiaryAmmo;
static ConVar g_hCvar_IncendiaryAmmoFactor;
static ConVar g_hCvar_NonMeleeStumbleChance;
static ConVar g_hCvar_MeleeStumbleChance;
static ConVar g_hCvar_MeleeDamage;
static ConVar g_hCvar_MeleeSpamProtection;
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

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bLeft4DHooks;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_IgnoreHeadshot;
static bool   g_bCvar_InstaKillChance;
static bool   g_bCvar_WoundDead;
static bool   g_bCvar_DamageFactor;
static bool   g_bCvar_DamageDropoff;
static bool   g_bCvar_Common;
static bool   g_bCvar_ShotgunStumble;
static bool   g_bCvar_Pistol_Magnum;
static bool   g_bCvar_Hunting_Rifle;
static bool   g_bCvar_Sniper_Military;
static bool   g_bCvar_Sniper_Scout;
static bool   g_bCvar_Sniper_AWP;
static bool   g_bCvar_Rifle_M60;
static bool   g_bCvar_Chainsaw;
static bool   g_bCvar_50Cal;
static bool   g_bCvar_Minigun;
static bool   g_bCvar_ExplosiveAmmo;
static bool   g_bCvar_ExplosiveAmmoFactor;
static bool   g_bCvar_ExplosiveAmmoStumble;
static bool   g_bCvar_IncendiaryAmmo;
static bool   g_bCvar_IncendiaryAmmoFactor;
static bool   g_bCvar_NonMeleeStumbleChance;
static bool   g_bCvar_MeleeStumbleChance;
static bool   g_bCvar_MeleeSpamProtection;
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

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_chainsaw_damage;
static int    g_iCvar_z_difficulty;
static int    g_iCvar_CommonDamage;
static int    g_iCvar_50CalDamage;
static int    g_iCvar_MinigunDamage;
static int    g_iCvar_MeleeDamage;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_z_non_head_damage_factor_easy;
static float  g_fCvar_z_non_head_damage_factor_normal;
static float  g_fCvar_z_non_head_damage_factor_hard;
static float  g_fCvar_z_non_head_damage_factor_expert;
static float  g_fCvar_z_non_head_damage_factor_multiplier;
static float  g_fDifficultyFactor;
static float  g_fDamageFactor;
static float  g_fCvar_MinigunRangeModifier;
static float  g_fCvar_50CalRangeModifier;
static float  g_fCvar_ExplosiveAmmoFactor;
static float  g_fCvar_IncendiaryAmmoFactor;
static float  g_fCvar_NonMeleeStumbleChance;
static float  g_fCvar_MeleeStumbleChance;
static float  g_fCvar_MeleeSpamProtection;
static float  g_fCvar_InstaKillChance;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
static char   g_sCvar_z_difficulty[11];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static bool   ge_bIsCommon[MAXENTITIES+1];
static float  ge_fLastMeleeAttack[MAXENTITIES+1][MAXPLAYERS+1];

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
static StringMap g_smWeaponIDs;
static StringMap g_smMeleeIDs;

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
static ArrayList g_alWeaponInfo;

// ====================================================================================================
// left4dhooks - Plugin Dependencies
// ====================================================================================================
#if !defined _l4dh_included
enum L4D2IntWeaponAttributes
{
    L4D2IWA_Damage = 0
};

enum L4D2FloatWeaponAttributes
{
    L4D2FWA_RangeModifier = 13
};

native int L4D2_GetIntWeaponAttribute(const char[] weaponName, L4D2IntWeaponAttributes attr);
native float L4D2_GetFloatWeaponAttribute(const char[] weaponName, L4D2FloatWeaponAttributes attr);
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
    MarkNativeAsOptional("L4D2_GetIntWeaponAttribute");
    MarkNativeAsOptional("L4D2_GetFloatWeaponAttribute");
    #endif

    g_alWeaponInfo = new ArrayList(ByteCountToCells(24));
    g_smWeaponIDs = new StringMap();
    g_smMeleeIDs = new StringMap();

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnAllPluginsLoaded()
{
    g_bLeft4DHooks = (GetFeatureStatus(FeatureType_Native, "L4D2_GetIntWeaponAttribute") == FeatureStatus_Available);
}

/****************************************************************************************************/

public void OnPluginStart()
{
    BuildStringMaps();

    g_hCvar_chainsaw_damage = FindConVar("chainsaw_damage");
    g_hCvar_z_non_head_damage_factor_easy = FindConVar("z_non_head_damage_factor_easy");
    g_hCvar_z_non_head_damage_factor_normal = FindConVar("z_non_head_damage_factor_normal");
    g_hCvar_z_non_head_damage_factor_hard = FindConVar("z_non_head_damage_factor_hard");
    g_hCvar_z_non_head_damage_factor_expert = FindConVar("z_non_head_damage_factor_expert");
    g_hCvar_z_non_head_damage_factor_multiplier = FindConVar("z_non_head_damage_factor_multiplier");
    g_hCvar_z_difficulty = FindConVar("z_difficulty");

    CreateConVar("l4d2_nerf_damage_common_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled               = CreateConVar("l4d2_nerf_damage_common_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_IgnoreHeadshot        = CreateConVar("l4d2_nerf_damage_common_ignore_headshot", "1", "Ignore headshot damage\nNote: By default, a common zombie instantly dies on a headshot.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_InstaKillChance       = CreateConVar("l4d2_nerf_damage_common_insta_kill_chance", "5.0", "Chance to insta-kill (any weapon).\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_WoundDead             = CreateConVar("l4d2_nerf_damage_common_wound_dead", "1", "Prevent leg-related wounds when the common is still alive.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_DamageFactor          = CreateConVar("l4d2_nerf_damage_common_damage_factor", "1", "Apply difficulty and damage multiplier on non-headshot hits.\nFormula: damage * z_non_head_damage_factor_<difficulty> * z_non_head_damage_factor_multiplier.\nCheck \"z_non_head_damage_factor_*\" cvars for more info.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_DamageDropoff         = CreateConVar("l4d2_nerf_damage_common_damage_dropoff", "1", "Apply damage dropoff.\nDecreases damage based on distance if RangeModifier < 1.0.\nFormula: Damage * (RangeModifier ^ (Distance/500))\nSource: https://counterstrike.fandom.com/wiki/Damage_dropoff.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Common                = CreateConVar("l4d2_nerf_damage_common_common", "1", "Nerf damage incoming from other common infecteds.\nUsually happens when they are brawling or in vomit.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_CommonDamage          = CreateConVar("l4d2_nerf_damage_common_common_damage", "1", "Damage received from other common infecteds (doesn't scale with damage factor).\nGame default: 4 (brawling) / 10 (vomit).", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ShotgunStumble        = CreateConVar("l4d2_nerf_damage_common_shotgun_stumble", "0", "Stumble effect from shotgun hits.\n0 = OFF (uses l4d2_nerf_damage_common_non_melee_stumble_chance cvar), 1 = ON (default game behaviour).", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Pistol_Magnum         = CreateConVar("l4d2_nerf_damage_common_pistol_magnum", "1", "Nerf damage for Pistol Magnum.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Hunting_Rifle         = CreateConVar("l4d2_nerf_damage_common_hunting_rifle", "1", "Nerf damage for Hunting Rifle.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Sniper_Military       = CreateConVar("l4d2_nerf_damage_common_sniper_military", "1", "Nerf damage for Military Sniper.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Sniper_Scout          = CreateConVar("l4d2_nerf_damage_common_sniper_scout", "1", "Nerf damage for Scout Sniper.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Sniper_AWP            = CreateConVar("l4d2_nerf_damage_common_sniper_awp", "1", "Nerf damage for AWP Sniper.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Rifle_M60             = CreateConVar("l4d2_nerf_damage_common_rifle_m60", "1", "Nerf damage for Rifle M60.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Chainsaw              = CreateConVar("l4d2_nerf_damage_common_chainsaw", "1", "Nerf damage for Chainsaw.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Minigun               = CreateConVar("l4d2_nerf_damage_common_minigun", "1", "Nerf damage for Minigun.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_MinigunDamage         = CreateConVar("l4d2_nerf_damage_common_minigun_damage", "32", "Minigun damage on common infecteds.\nGame default: 50.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0);
    g_hCvar_MinigunRangeModifier  = CreateConVar("l4d2_nerf_damage_common_minigun_rangemodifier", "0.97", "Minigun range modifier on common infecteds.\nGame default: 1.0.\n1.0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_50Cal                 = CreateConVar("l4d2_nerf_damage_common_50cal", "1", "Nerf damage for 50cal.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_50CalDamage           = CreateConVar("l4d2_nerf_damage_common_50cal_damage", "50", "50cal damage on common infecteds.\nGame default: 50.", CVAR_FLAGS, true, 0.0);
    g_hCvar_50CalRangeModifier    = CreateConVar("l4d2_nerf_damage_common_50cal_rangemodifier", "0.97", "50cal range modifier on common infecteds.\nGame default: 1.0.\n1.0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_ExplosiveAmmo         = CreateConVar("l4d2_nerf_damage_common_explosive_ammo", "1", "Nerf damage for Explosive Ammo.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0);
    g_hCvar_ExplosiveAmmoFactor   = CreateConVar("l4d2_nerf_damage_common_explosive_ammo_factor", "2.0", "Multiplier for explosive ammo/melee flag.\n1.0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_ExplosiveAmmoStumble  = CreateConVar("l4d2_nerf_damage_common_explosive_ammo_stumble", "1", "Add the stumble effect to common infecteds when hit by an explosive ammo.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0);
    g_hCvar_IncendiaryAmmo        = CreateConVar("l4d2_nerf_damage_common_incendiary_ammo", "1", "Nerf damage for Incendiary Ammo.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0);
    g_hCvar_IncendiaryAmmoFactor  = CreateConVar("l4d2_nerf_damage_common_incendiary_ammo_factor", "1.5", "Multiplier for incendiary ammo/melee flag.\n1.0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_NonMeleeStumbleChance = CreateConVar("l4d2_nerf_damage_common_non_melee_stumble_chance", "5.0", "Chance to stumble common infecteds during a non-melee attack.\nDoesn't affect Shotguns.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_MeleeStumbleChance    = CreateConVar("l4d2_nerf_damage_common_melee_stumble_chance", "15.0", "Chance to stumble common infecteds during a melee attack.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_MeleeDamage           = CreateConVar("l4d2_nerf_damage_common_melee_damage", "250", "Melee damage on common infecteds.\nGame default: 50.", CVAR_FLAGS, true, 0.0);
    g_hCvar_MeleeSpamProtection   = CreateConVar("l4d2_nerf_damage_common_melee_spam_protection", "0.1", "Safe interval in seconds between melee attacks per client.\nUseful for melees that has DMG_BURN flag, otherwise the attack is registered multiple times by the game.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Melee_Baseball_Bat    = CreateConVar("l4d2_nerf_damage_common_melee_baseball_bat", "1", "Nerf damage for Baseball Bat.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Cricket_Bat     = CreateConVar("l4d2_nerf_damage_common_melee_cricket_bat", "1", "Nerf damage for Cricket Bat.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Crowbar         = CreateConVar("l4d2_nerf_damage_common_melee_crowbar", "1", "Nerf damage for Crowbar.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Electric_Guitar = CreateConVar("l4d2_nerf_damage_common_melee_electric_guitar", "1", "Nerf damage for Electric Guitar.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Fireaxe         = CreateConVar("l4d2_nerf_damage_common_melee_fireaxe", "1", "Nerf damage for Fire Axe.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Frying_Pan      = CreateConVar("l4d2_nerf_damage_common_melee_frying_pan", "1", "Nerf damage for Frying Pan.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Golfclub        = CreateConVar("l4d2_nerf_damage_common_melee_golfclub", "1", "Nerf damage for Golf Club.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Katana          = CreateConVar("l4d2_nerf_damage_common_melee_katana", "1", "Nerf damage for Katana.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Knife           = CreateConVar("l4d2_nerf_damage_common_melee_knife", "1", "Nerf damage for Knife.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Machete         = CreateConVar("l4d2_nerf_damage_common_melee_machete", "1", "Nerf damage for Machete.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Tonfa           = CreateConVar("l4d2_nerf_damage_common_melee_tonfa", "1", "Nerf damage for Tonfa.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Pitchfork       = CreateConVar("l4d2_nerf_damage_common_melee_pitchfork", "1", "Nerf damage for Pitchfork.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Shovel          = CreateConVar("l4d2_nerf_damage_common_melee_shovel", "1", "Nerf damage for Shovel.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_RiotShield      = CreateConVar("l4d2_nerf_damage_common_melee_riotshield", "1", "Nerf damage for Riot Shield.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Melee_Custom          = CreateConVar("l4d2_nerf_damage_common_melee_custom", "1", "Nerf damage for Custom Melees.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_chainsaw_damage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_z_non_head_damage_factor_easy.AddChangeHook(Event_ConVarChanged);
    g_hCvar_z_non_head_damage_factor_normal.AddChangeHook(Event_ConVarChanged);
    g_hCvar_z_non_head_damage_factor_hard.AddChangeHook(Event_ConVarChanged);
    g_hCvar_z_non_head_damage_factor_expert.AddChangeHook(Event_ConVarChanged);
    g_hCvar_z_non_head_damage_factor_multiplier.AddChangeHook(Event_ConVarChanged);
    g_hCvar_z_difficulty.AddChangeHook(Event_ConVarChanged);

    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_IgnoreHeadshot.AddChangeHook(Event_ConVarChanged);
    g_hCvar_InstaKillChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_WoundDead.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DamageFactor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DamageDropoff.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Common.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CommonDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ShotgunStumble.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Pistol_Magnum.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Hunting_Rifle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Sniper_Military.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Sniper_Scout.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Sniper_AWP.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Rifle_M60.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Chainsaw.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Minigun.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinigunDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinigunRangeModifier.AddChangeHook(Event_ConVarChanged);
    g_hCvar_50Cal.AddChangeHook(Event_ConVarChanged);
    g_hCvar_50CalDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_50CalRangeModifier.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ExplosiveAmmo.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ExplosiveAmmoFactor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ExplosiveAmmoStumble.AddChangeHook(Event_ConVarChanged);
    g_hCvar_IncendiaryAmmo.AddChangeHook(Event_ConVarChanged);
    g_hCvar_IncendiaryAmmoFactor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_NonMeleeStumbleChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MeleeStumbleChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MeleeDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MeleeSpamProtection.AddChangeHook(Event_ConVarChanged);
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

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_nerf_damage_common", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void BuildStringMaps()
{
    // Weapons Info
    g_alWeaponInfo.Clear();
    g_alWeaponInfo.PushString("weapon_pistol");
    g_alWeaponInfo.PushString("weapon_smg");
    g_alWeaponInfo.PushString("weapon_pumpshotgun");
    g_alWeaponInfo.PushString("weapon_autoshotgun");
    g_alWeaponInfo.PushString("weapon_rifle");
    g_alWeaponInfo.PushString("weapon_hunting_rifle");
    g_alWeaponInfo.PushString("weapon_smg_silenced");
    g_alWeaponInfo.PushString("weapon_shotgun_chrome");
    g_alWeaponInfo.PushString("weapon_rifle_desert");
    g_alWeaponInfo.PushString("weapon_sniper_military");
    g_alWeaponInfo.PushString("weapon_shotgun_spas");
    g_alWeaponInfo.PushString("weapon_grenade_launcher");
    g_alWeaponInfo.PushString("weapon_rifle_ak47");
    g_alWeaponInfo.PushString("weapon_pistol_magnum");
    g_alWeaponInfo.PushString("weapon_smg_mp5");
    g_alWeaponInfo.PushString("weapon_rifle_sg552");
    g_alWeaponInfo.PushString("weapon_sniper_awp");
    g_alWeaponInfo.PushString("weapon_sniper_scout");
    g_alWeaponInfo.PushString("weapon_rifle_m60");

    // Weapons
    g_smWeaponIDs.Clear();
    g_smWeaponIDs.SetValue("weapon_pistol",            L4D2_WEPID_PISTOL);
    g_smWeaponIDs.SetValue("weapon_smg",               L4D2_WEPID_SMG_UZI);
    g_smWeaponIDs.SetValue("weapon_pumpshotgun",       L4D2_WEPID_PUMP_SHOTGUN);
    g_smWeaponIDs.SetValue("weapon_autoshotgun",       L4D2_WEPID_AUTO_SHOTGUN);
    g_smWeaponIDs.SetValue("weapon_rifle",             L4D2_WEPID_RIFLE_M16);
    g_smWeaponIDs.SetValue("weapon_hunting_rifle",     L4D2_WEPID_HUNTING_RIFLE);
    g_smWeaponIDs.SetValue("weapon_smg_silenced",      L4D2_WEPID_SMG_SILENCED);
    g_smWeaponIDs.SetValue("weapon_shotgun_chrome",    L4D2_WEPID_SHOTGUN_CHROME);
    g_smWeaponIDs.SetValue("weapon_rifle_desert",      L4D2_WEPID_RIFLE_DESERT);
    g_smWeaponIDs.SetValue("weapon_sniper_military",   L4D2_WEPID_SNIPER_MILITARY);
    g_smWeaponIDs.SetValue("weapon_shotgun_spas",      L4D2_WEPID_SHOTGUN_SPAS);
    g_smWeaponIDs.SetValue("weapon_melee",             L4D2_WEPID_MELEE);
    g_smWeaponIDs.SetValue("weapon_chainsaw",          L4D2_WEPID_CHAINSAW);
    g_smWeaponIDs.SetValue("weapon_grenade_launcher",  L4D2_WEPID_GRENADE_LAUNCHER);
    g_smWeaponIDs.SetValue("weapon_rifle_ak47",        L4D2_WEPID_RIFLE_AK47);
    g_smWeaponIDs.SetValue("weapon_pistol_magnum",     L4D2_WEPID_PISTOL_MAGNUM);
    g_smWeaponIDs.SetValue("weapon_smg_mp5",           L4D2_WEPID_SMG_MP5);
    g_smWeaponIDs.SetValue("weapon_rifle_sg552",       L4D2_WEPID_RIFLE_SG552);
    g_smWeaponIDs.SetValue("weapon_sniper_awp",        L4D2_WEPID_SNIPER_AWP);
    g_smWeaponIDs.SetValue("weapon_sniper_scout",      L4D2_WEPID_SNIPER_SCOUT);
    g_smWeaponIDs.SetValue("weapon_rifle_m60",         L4D2_WEPID_RIFLE_M60);
    g_smWeaponIDs.SetValue("prop_minigun",             L4D2_WEPID_MACHINE_GUN);
    g_smWeaponIDs.SetValue("prop_minigun_l4d1",        L4D2_WEPID_MACHINE_GUN);

    // Melees
    g_smMeleeIDs.Clear();
    g_smMeleeIDs.SetValue("fireaxe",                   L4D2_WEPID_MELEE_FIREAXE);
    g_smMeleeIDs.SetValue("frying_pan",                L4D2_WEPID_MELEE_FRYING_PAN);
    g_smMeleeIDs.SetValue("machete",                   L4D2_WEPID_MELEE_MACHETE);
    g_smMeleeIDs.SetValue("baseball_bat",              L4D2_WEPID_MELEE_BASEBALL_BAT);
    g_smMeleeIDs.SetValue("crowbar",                   L4D2_WEPID_MELEE_CROWBAR);
    g_smMeleeIDs.SetValue("cricket_bat",               L4D2_WEPID_MELEE_CRICKET_BAT);
    g_smMeleeIDs.SetValue("tonfa",                     L4D2_WEPID_MELEE_TONFA);
    g_smMeleeIDs.SetValue("katana",                    L4D2_WEPID_MELEE_KATANA);
    g_smMeleeIDs.SetValue("electric_guitar",           L4D2_WEPID_MELEE_ELECTRIC_GUITAR);
    g_smMeleeIDs.SetValue("knife",                     L4D2_WEPID_MELEE_KNIFE);
    g_smMeleeIDs.SetValue("golfclub",                  L4D2_WEPID_MELEE_GOLFCLUB);
    g_smMeleeIDs.SetValue("pitchfork",                 L4D2_WEPID_MELEE_PITCHFORK);
    g_smMeleeIDs.SetValue("shovel",                    L4D2_WEPID_MELEE_SHOVEL);
    g_smMeleeIDs.SetValue("riotshield",                L4D2_WEPID_MELEE_RIOTSHIELD);
    g_smMeleeIDs.SetValue("custom",                    L4D2_WEPID_MELEE_CUSTOM);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

/****************************************************************************************************/

public void GetCvars()
{
    g_iCvar_chainsaw_damage = g_hCvar_chainsaw_damage.IntValue;
    g_fCvar_z_non_head_damage_factor_easy = g_hCvar_z_non_head_damage_factor_easy.FloatValue;
    g_fCvar_z_non_head_damage_factor_normal = g_hCvar_z_non_head_damage_factor_normal.FloatValue;
    g_fCvar_z_non_head_damage_factor_hard = g_hCvar_z_non_head_damage_factor_hard.FloatValue;
    g_fCvar_z_non_head_damage_factor_expert = g_hCvar_z_non_head_damage_factor_expert.FloatValue;
    g_fCvar_z_non_head_damage_factor_multiplier = g_hCvar_z_non_head_damage_factor_multiplier.FloatValue;

    g_hCvar_z_difficulty.GetString(g_sCvar_z_difficulty, sizeof(g_sCvar_z_difficulty));
    StringToLowerCase(g_sCvar_z_difficulty);

    if (StrEqual(g_sCvar_z_difficulty, "easy"))
        g_iCvar_z_difficulty = Z_DIFFICULTY_EASY;
    else if (StrEqual(g_sCvar_z_difficulty, "normal"))
        g_iCvar_z_difficulty = Z_DIFFICULTY_NORMAL;
    else if (StrEqual(g_sCvar_z_difficulty, "hard"))
        g_iCvar_z_difficulty = Z_DIFFICULTY_HARD;
    else if (StrEqual(g_sCvar_z_difficulty, "impossible"))
        g_iCvar_z_difficulty = Z_DIFFICULTY_EXPERT;
    else
        g_iCvar_z_difficulty = Z_DIFFICULTY_NORMAL;

    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_IgnoreHeadshot = g_hCvar_IgnoreHeadshot.BoolValue;
    g_fCvar_InstaKillChance = g_hCvar_InstaKillChance.FloatValue;
    g_bCvar_InstaKillChance = (g_fCvar_InstaKillChance > 0.0);
    g_bCvar_WoundDead = g_hCvar_WoundDead.BoolValue;
    g_bCvar_DamageFactor = g_hCvar_DamageFactor.BoolValue;
    g_bCvar_DamageDropoff = g_hCvar_DamageDropoff.BoolValue;
    g_bCvar_Common = g_hCvar_Common.BoolValue;
    g_iCvar_CommonDamage = g_hCvar_CommonDamage.IntValue;
    g_bCvar_ShotgunStumble = g_hCvar_ShotgunStumble.BoolValue;
    g_bCvar_Pistol_Magnum = g_hCvar_Pistol_Magnum.BoolValue;
    g_bCvar_Rifle_M60 = g_hCvar_Rifle_M60.BoolValue;
    g_bCvar_Hunting_Rifle = g_hCvar_Hunting_Rifle.BoolValue;
    g_bCvar_Sniper_Military = g_hCvar_Sniper_Military.BoolValue;
    g_bCvar_Sniper_Scout = g_hCvar_Sniper_Scout.BoolValue;
    g_bCvar_Sniper_AWP = g_hCvar_Sniper_AWP.BoolValue;
    g_bCvar_Chainsaw = g_hCvar_Chainsaw.BoolValue;
    g_bCvar_Minigun = g_hCvar_Minigun.BoolValue;
    g_iCvar_MinigunDamage = g_hCvar_MinigunDamage.IntValue;
    g_fCvar_MinigunRangeModifier = g_hCvar_MinigunRangeModifier.FloatValue;
    g_bCvar_50Cal = g_hCvar_50Cal.BoolValue;
    g_iCvar_50CalDamage = g_hCvar_50CalDamage.IntValue;
    g_fCvar_50CalRangeModifier = g_hCvar_50CalRangeModifier.FloatValue;
    g_bCvar_ExplosiveAmmo = g_hCvar_ExplosiveAmmo.BoolValue;
    g_fCvar_ExplosiveAmmoFactor = g_hCvar_ExplosiveAmmoFactor.FloatValue;
    g_bCvar_ExplosiveAmmoFactor = (g_fCvar_ExplosiveAmmoFactor > 1.0);
    g_bCvar_ExplosiveAmmoStumble = g_hCvar_ExplosiveAmmoStumble.BoolValue;
    g_bCvar_IncendiaryAmmo = g_hCvar_IncendiaryAmmo.BoolValue;
    g_fCvar_IncendiaryAmmoFactor = g_hCvar_IncendiaryAmmoFactor.FloatValue;
    g_bCvar_IncendiaryAmmoFactor = (g_fCvar_IncendiaryAmmoFactor > 1.0);
    g_fCvar_NonMeleeStumbleChance = g_hCvar_NonMeleeStumbleChance.FloatValue;
    g_bCvar_NonMeleeStumbleChance = (g_fCvar_NonMeleeStumbleChance > 0.0);
    g_fCvar_MeleeStumbleChance = g_hCvar_MeleeStumbleChance.FloatValue;
    g_bCvar_MeleeStumbleChance = (g_fCvar_MeleeStumbleChance > 0.0);
    g_iCvar_MeleeDamage = g_hCvar_MeleeDamage.IntValue;
    g_fCvar_MeleeSpamProtection = g_hCvar_MeleeSpamProtection.FloatValue;
    g_bCvar_MeleeSpamProtection = (g_fCvar_MeleeSpamProtection > 0.0);
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

    if (g_bCvar_DamageFactor)
    {
        switch (g_iCvar_z_difficulty)
        {
            case Z_DIFFICULTY_EASY:   g_fDifficultyFactor = g_fCvar_z_non_head_damage_factor_easy;
            case Z_DIFFICULTY_NORMAL: g_fDifficultyFactor = g_fCvar_z_non_head_damage_factor_normal;
            case Z_DIFFICULTY_HARD:   g_fDifficultyFactor = g_fCvar_z_non_head_damage_factor_hard;
            case Z_DIFFICULTY_EXPERT: g_fDifficultyFactor = g_fCvar_z_non_head_damage_factor_expert;
        }

        g_fDamageFactor = g_fDifficultyFactor * g_fCvar_z_non_head_damage_factor_multiplier;
    }
    else
    {
        g_fDamageFactor = 1.0;
    }
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_INFECTED)) != INVALID_ENT_REFERENCE)
    {
        ge_bIsCommon[entity] = true;
        SDKHook(entity, SDKHook_TraceAttack, OnTraceAttack);
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    for (int entity = MaxClients+1; entity <= GetMaxEntities(); entity++)
    {
        ge_fLastMeleeAttack[entity][client] = 0.0;
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!IsValidEntityIndex(entity))
        return;

    ge_bIsCommon[entity] = false;

    for (int client = 1; client <= MaxClients; client++)
    {
        ge_fLastMeleeAttack[entity][client] = 0.0;
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 'i')
       return;

    if (StrEqual(classname, CLASSNAME_INFECTED))
    {
        ge_bIsCommon[entity] = true;
        SDKHook(entity, SDKHook_TraceAttack, OnTraceAttack);
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

/****************************************************************************************************/

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if (!g_bLeft4DHooks)
        return Plugin_Continue;

    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    // Block dissolver damage to common, otherwise server will crash. (Code fix by "Silvers" on "Dissolve Infected" plugin)
    if (damage == 10000.0 && damagetype == 5982249)
    {
        damage = 0.0;
        return Plugin_Continue;
    }

    if (hitgroup == HITGROUP_HEAD)
    {
        if (g_bCvar_IgnoreHeadshot)
            SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);

        return Plugin_Continue;
    }

    bool damagetype_changed;

    if (damage == 0.0)
    {
        damagetype_changed = true;
        damagetype = DMG_GENERIC;
    }

    if (g_bCvar_IncendiaryAmmo && (damagetype & DMG_BURN))
    {
        damagetype_changed = true;
        damagetype &= ~DMG_BURN;
        damagetype |= DMG_REMOVENORAGDOLL; // Add a fake damage type to retrieve that was DMG_BURN on OnTakeDamage
    }

    return damagetype_changed ? Plugin_Changed : Plugin_Continue;
}

/****************************************************************************************************/

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    // Block dissolver damage to common, otherwise server will crash. (Code fix by "Silvers" on "Dissolve Infected" plugin)
    if (damage == 10000.0 && damagetype == 5982249)
    {
        damage = 0.0;
        return Plugin_Stop;
    }

    if (!g_bLeft4DHooks)
        return Plugin_Continue;

    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (g_bCvar_Common && IsValidEntityIndex(attacker) && ge_bIsCommon[attacker])
    {
        damage = float(g_iCvar_CommonDamage);
        return Plugin_Changed;
    }

    bool damagetype_changed;

    if (!g_bCvar_ShotgunStumble && damagetype & DMG_BUCKSHOT)
    {
        damagetype_changed = true;
        damagetype &= ~DMG_BUCKSHOT;
    }

    if (g_bCvar_ExplosiveAmmo && g_bCvar_ExplosiveAmmoStumble && (damagetype & DMG_BLAST))
    {
        damagetype_changed = true;
        damagetype |= DMG_BUCKSHOT; // Stumble common infecteds
    }

    if (g_bCvar_IncendiaryAmmo && (damagetype & DMG_REMOVENORAGDOLL))
    {
        damagetype_changed = true;
        damagetype &= ~DMG_REMOVENORAGDOLL;
        damagetype |= DMG_BURN;
    }

    if (damage == 0.0)
        return damagetype_changed ? Plugin_Changed : Plugin_Continue;

    float health = float(GetEntProp(victim, Prop_Data, "m_iHealth"));

    if (g_bCvar_InstaKillChance && g_fCvar_InstaKillChance >= GetRandomFloat(0.0, 100.0))
    {
        damage = health;
        return Plugin_Changed;
    }

    if (!IsValidClient(attacker))
        return Plugin_Continue;

    int team = GetClientTeam(attacker);

    if (team != TEAM_SURVIVOR && team != TEAM_HOLDOUT)
        return Plugin_Continue;

    int weaponEntity = (IsValidEntity(weapon) ? weapon : inflictor);

    if (!IsValidEntity(weaponEntity))
        return Plugin_Continue;

    char weaponName[24];
    GetEntityClassname(weaponEntity, weaponName, sizeof(weaponName));

    bool isMelee = HasEntProp(weaponEntity, Prop_Send, "m_bInMeleeSwing"); // CTerrorMeleeWeapon
    bool isMachineGun = HasEntProp(weaponEntity, Prop_Send, "m_heat"); // CPropMinigun / CPropMountedGun
    bool isExplosive = (g_bCvar_ExplosiveAmmo && (damagetype & DMG_BLAST));
    bool isIncendiary = (g_bCvar_IncendiaryAmmo && (damagetype & DMG_BURN));
    bool isStumble;

    int weaponid;
    int meleeid;

    if (isMelee)
    {
        weaponid = L4D2_WEPID_MELEE;

        if (g_bCvar_MeleeStumbleChance && g_fCvar_MeleeStumbleChance >= GetRandomFloat(0.0, 100.0))
        {
            isStumble = true;
            damagetype |= DMG_BUCKSHOT; // Stumble common infecteds
        }

        char meleeName[16];
        GetEntPropString(weaponEntity, Prop_Data, "m_strMapSetScriptName", meleeName, sizeof(meleeName));

        if (!g_smMeleeIDs.GetValue(meleeName, meleeid))
            g_smMeleeIDs.GetValue("custom", meleeid);
    }
    else
    {
        if (isMachineGun)
            weaponid = L4D2_WEPID_MACHINE_GUN;
        else
            g_smWeaponIDs.GetValue(weaponName, weaponid);

        if (g_bCvar_NonMeleeStumbleChance && g_fCvar_NonMeleeStumbleChance >= GetRandomFloat(0.0, 100.0))
        {
            isStumble = true;
            damagetype |= DMG_BUCKSHOT; // Stumble common infecteds
        }
    }

    if (weaponid == L4D2_WEPID_NONE)
        return Plugin_Continue;

    int weaponDamage;
    float weaponRangeModifier;

    switch (weaponid)
    {
        case L4D2_WEPID_CHAINSAW:
        {
            if (!g_bCvar_Chainsaw)
                return Plugin_Continue;

            weaponDamage = g_iCvar_chainsaw_damage;
            weaponRangeModifier = 1.0;
        }
        case L4D2_WEPID_MACHINE_GUN:
        {
            if (StrEqual(weaponName, CLASSNAME_PROP_MINIGUN))
            {
                if (!g_bCvar_50Cal)
                    return Plugin_Continue;

                weaponDamage = g_iCvar_50CalDamage;
                weaponRangeModifier = g_fCvar_50CalRangeModifier;
            }
            else if (StrEqual(weaponName, CLASSNAME_PROP_MINIGUN_L4D1))
            {
                if (!g_bCvar_Minigun)
                    return Plugin_Continue;

                weaponDamage = g_iCvar_MinigunDamage;
                weaponRangeModifier = g_fCvar_MinigunRangeModifier;
            }
        }
        case L4D2_WEPID_PISTOL_MAGNUM:
        {
            if (!g_bCvar_Pistol_Magnum)
                return Plugin_Continue;

            weaponDamage = L4D2_GetIntWeaponAttribute(weaponName, L4D2IWA_Damage);
            weaponRangeModifier = L4D2_GetFloatWeaponAttribute(weaponName, L4D2FWA_RangeModifier);
        }
        case L4D2_WEPID_RIFLE_M60:
        {
            if (!g_bCvar_Rifle_M60)
                return Plugin_Continue;

            weaponDamage = L4D2_GetIntWeaponAttribute(weaponName, L4D2IWA_Damage);
            weaponRangeModifier = L4D2_GetFloatWeaponAttribute(weaponName, L4D2FWA_RangeModifier);
        }
        case L4D2_WEPID_HUNTING_RIFLE:
        {
            if (!g_bCvar_Hunting_Rifle)
                return Plugin_Continue;

            weaponDamage = L4D2_GetIntWeaponAttribute(weaponName, L4D2IWA_Damage);
            weaponRangeModifier = L4D2_GetFloatWeaponAttribute(weaponName, L4D2FWA_RangeModifier);
        }
        case L4D2_WEPID_SNIPER_AWP:
        {
            if (!g_bCvar_Sniper_AWP)
                return Plugin_Continue;

            weaponDamage = L4D2_GetIntWeaponAttribute(weaponName, L4D2IWA_Damage);
            weaponRangeModifier = L4D2_GetFloatWeaponAttribute(weaponName, L4D2FWA_RangeModifier);
        }
        case L4D2_WEPID_SNIPER_MILITARY:
        {
            if (!g_bCvar_Sniper_Military)
                return Plugin_Continue;

            weaponDamage = L4D2_GetIntWeaponAttribute(weaponName, L4D2IWA_Damage);
            weaponRangeModifier = L4D2_GetFloatWeaponAttribute(weaponName, L4D2FWA_RangeModifier);
        }
        case L4D2_WEPID_SNIPER_SCOUT:
        {
            if (!g_bCvar_Sniper_Scout)
                return Plugin_Continue;

            weaponDamage = L4D2_GetIntWeaponAttribute(weaponName, L4D2IWA_Damage);
            weaponRangeModifier = L4D2_GetFloatWeaponAttribute(weaponName, L4D2FWA_RangeModifier);
        }
        case L4D2_WEPID_MELEE:
        {
            switch (meleeid)
            {
                case L4D2_WEPID_MELEE_FIREAXE:
                {
                    if (!g_bCvar_Melee_Fireaxe)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_FRYING_PAN:
                {
                    if (!g_bCvar_Melee_Frying_Pan)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_MACHETE:
                {
                    if (!g_bCvar_Melee_Machete)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_BASEBALL_BAT:
                {
                    if (!g_bCvar_Melee_Baseball_Bat)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_CROWBAR:
                {
                    if (!g_bCvar_Melee_Crowbar)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_CRICKET_BAT:
                {
                    if (!g_bCvar_Melee_Cricket_Bat)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_TONFA:
                {
                    if (!g_bCvar_Melee_Tonfa)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_KATANA:
                {
                    if (!g_bCvar_Melee_Katana)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_ELECTRIC_GUITAR:
                {
                    if (!g_bCvar_Melee_Electric_Guitar)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_KNIFE:
                {
                    if (!g_bCvar_Melee_Knife)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_GOLFCLUB:
                {
                    if (!g_bCvar_Melee_Golfclub)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_PITCHFORK:
                {
                    if (!g_bCvar_Melee_Pitchfork)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_SHOVEL:
                {
                    if (!g_bCvar_Melee_Shovel)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_RIOTSHIELD:
                {
                    if (!g_bCvar_Melee_RiotShield)
                        return Plugin_Continue;
                }
                case L4D2_WEPID_MELEE_CUSTOM:
                {
                    if (!g_bCvar_Melee_Custom)
                        return Plugin_Continue;
                }
            }

            if (g_bCvar_MeleeSpamProtection && (GetGameTime() - ge_fLastMeleeAttack[victim][attacker] < g_fCvar_MeleeSpamProtection))
                weaponDamage = 0;
            else
                weaponDamage = g_iCvar_MeleeDamage;

            ge_fLastMeleeAttack[victim][attacker] = GetGameTime();

            weaponRangeModifier = 1.0;
        }
        default:
        {
            if (!isExplosive && !isIncendiary && !isStumble)
                return Plugin_Continue;

            weaponDamage = L4D2_GetIntWeaponAttribute(weaponName, L4D2IWA_Damage);
            weaponRangeModifier = L4D2_GetFloatWeaponAttribute(weaponName, L4D2FWA_RangeModifier);
        }
    }

    bool damageDropoff = (weaponRangeModifier != 1.0);

    if (g_bCvar_DamageDropoff && damageDropoff)
    {
        float vPosAttacker[3];
        GetClientEyePosition(attacker, vPosAttacker);

        float distance = GetVectorDistance(vPosAttacker, damagePosition);

        float weaponDamageDropoff = (weaponDamage * (Pow(weaponRangeModifier, (distance / 500))));
        damage = weaponDamageDropoff;
    }
    else
    {
        damage = float(weaponDamage);
    }

    if (g_bCvar_DamageFactor)
        damage *= g_fDamageFactor;

    if (isExplosive && g_bCvar_ExplosiveAmmoFactor)
        damage *= g_fCvar_ExplosiveAmmoFactor;

    if (isIncendiary && g_bCvar_IncendiaryAmmoFactor)
        damage *= g_fCvar_IncendiaryAmmoFactor;

    if (damage < health)
    {
        if (isExplosive)
            damagetype &= ~DMG_BLAST;

        if (isIncendiary)
            damagetype &= ~DMG_BURN;

        if (g_bCvar_WoundDead)
        {
            int wound1 = GetEntProp(victim, Prop_Send, "m_iRequestedWound1");
            int wound2 = GetEntProp(victim, Prop_Send, "m_iRequestedWound2");
            int gender = GetEntProp(victim, Prop_Send, "m_Gender");
            if (gender == GENDER_MALE || gender == GENDER_MALE2 || gender == GENDER_MALE3 || gender == GENDER_MALE4 || gender == GENDER_MALE5 || gender == GENDER_MALE6 || gender == GENDER_MALE7 || gender == GENDER_MALE8)
			{
				if (wound1 == PART_H || wound1 == PART_I || wound1 == PART_J || wound1 == PART_K || wound1 == PART_M || wound1 == PART_N || wound1 == PART_O || wound1 == PART_P || wound1 == PART_Q || wound1 == PART_R)
        	    {
        	        SetEntProp(victim, Prop_Send, "m_iRequestedWound1", NO_WOUND);
        	    }
				if (wound2 == PART_H || wound2 == PART_I || wound2 == PART_J || wound2 == PART_K || wound2 == PART_M || wound2 == PART_N || wound2 == PART_O || wound2 == PART_P || wound2 == PART_Q || wound2 == PART_R)
				{
	        	    SetEntProp(victim, Prop_Send, "m_iRequestedWound2", NO_WOUND);
        	    }
			}
            else if (gender == GENDER_FEMALE_L4D1 || gender == GENDER_FEMALE_L4D2)
			{
				if (wound1 == PART_G || wound1 == PART_H || wound1 == PART_I || wound1 == PART_J || wound1 == PART_L || wound1 == PART_M || wound1 == PART_N || wound1 == PART_O || wound1 == PART_P || wound1 == PART_Q)
            	{
        	        SetEntProp(victim, Prop_Send, "m_iRequestedWound1", NO_WOUND);
        	    }
				if (wound2 == PART_G || wound2 == PART_H || wound2 == PART_I || wound2 == PART_J || wound2 == PART_L || wound2 == PART_M || wound2 == PART_N || wound2 == PART_O || wound2 == PART_P || wound2 == PART_Q)
				{
        	        SetEntProp(victim, Prop_Send, "m_iRequestedWound2", NO_WOUND);
        	    }
			}
			else if (gender == GENDER_RIOT)
			{
				if (wound1 == PART_A || wound1 == PART_B || wound1 == PART_C)
				{
	        	    SetEntProp(victim, Prop_Send, "m_iRequestedWound1", NO_WOUND);
        	    }
				if (wound2 == PART_A || wound2 == PART_B || wound2 == PART_C)
				{
	        	    SetEntProp(victim, Prop_Send, "m_iRequestedWound2", NO_WOUND);
        	    }
	        }
			else if (gender == GENDER_CEDA)
			{
				if (wound1 == PART_E || wound1 == PART_B || wound1 == PART_C || wound1 == PART_F)
            	{
        	        SetEntProp(victim, Prop_Send, "m_iRequestedWound1", NO_WOUND);
        	    }
				if (wound2 == PART_E || wound2 == PART_B || wound2 == PART_C || wound2 == PART_F)
				{
	        	    SetEntProp(victim, Prop_Send, "m_iRequestedWound2", NO_WOUND);
        	    }
	        }				
        }
    }

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
    PrintToConsole(client, "--------------- Plugin Cvars (l4d2_nerf_damage_common) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_nerf_damage_common_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_nerf_damage_common_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_ignore_headshot : %b (%s)", g_bCvar_IgnoreHeadshot, g_bCvar_IgnoreHeadshot ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_insta_kill_chance : %.1f%% (%s)", g_fCvar_InstaKillChance, g_bCvar_InstaKillChance ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_wound_dead : %b (%s)", g_bCvar_WoundDead, g_bCvar_WoundDead ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_damage_factor : %b (%s)", g_bCvar_DamageFactor, g_bCvar_DamageFactor ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_damage_dropoff : %b (%s)", g_bCvar_DamageDropoff, g_bCvar_DamageDropoff ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_common : %b (%s)", g_bCvar_Common, g_bCvar_Common ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_common_damage : %i", g_iCvar_CommonDamage);
    PrintToConsole(client, "l4d2_nerf_damage_common_shotgun_stumble : %b (%s)", g_bCvar_ShotgunStumble, g_bCvar_ShotgunStumble ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_pistol_magnum : %b (%s)", g_bCvar_Pistol_Magnum, g_bCvar_Pistol_Magnum ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_hunting_rifle : %b (%s)", g_bCvar_Hunting_Rifle, g_bCvar_Hunting_Rifle ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_sniper_military : %b (%s)", g_bCvar_Sniper_Military, g_bCvar_Sniper_Military ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_sniper_scout : %b (%s)", g_bCvar_Sniper_Scout, g_bCvar_Sniper_Scout ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_sniper_awp : %b (%s)", g_bCvar_Sniper_AWP, g_bCvar_Sniper_AWP ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_rifle_m60 : %b (%s)", g_bCvar_Rifle_M60, g_bCvar_Rifle_M60 ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_chainsaw : %b (%s)", g_bCvar_Chainsaw, g_bCvar_Chainsaw ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_minigun : %b (%s)", g_bCvar_Minigun, g_bCvar_Minigun ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_minigun_damage : %i", g_iCvar_MinigunDamage);
    PrintToConsole(client, "l4d2_nerf_damage_common_minigun_rangemodifier : %.2f", g_fCvar_MinigunRangeModifier);
    PrintToConsole(client, "l4d2_nerf_damage_common_50cal : %b (%s)", g_bCvar_50Cal, g_bCvar_50Cal ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_50cal_damage : %i", g_iCvar_50CalDamage);
    PrintToConsole(client, "l4d2_nerf_damage_common_50cal_rangemodifier : %.2f", g_fCvar_50CalRangeModifier);
    PrintToConsole(client, "l4d2_nerf_damage_common_explosive_ammo : %b (%s)", g_bCvar_ExplosiveAmmo, g_bCvar_ExplosiveAmmo ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_explosive_ammo_factor : %.2f (%s)", g_fCvar_ExplosiveAmmoFactor, g_bCvar_ExplosiveAmmoFactor ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_explosive_ammo_stumble : %b (%s)", g_bCvar_ExplosiveAmmoStumble, g_bCvar_ExplosiveAmmoStumble ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_incendiary_ammo : %b (%s)", g_bCvar_IncendiaryAmmo, g_bCvar_IncendiaryAmmo ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_incendiary_ammo_factor : %.2f (%s)", g_fCvar_IncendiaryAmmoFactor, g_bCvar_IncendiaryAmmoFactor ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_non_melee_stumble_chance : %.1f%% (%s)", g_fCvar_NonMeleeStumbleChance, g_bCvar_NonMeleeStumbleChance ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_stumble_chance : %.1f%% (%s)", g_fCvar_MeleeStumbleChance, g_bCvar_MeleeStumbleChance ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_damage : %i", g_iCvar_MeleeDamage);
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_spam_protection : %.2f (%s)", g_fCvar_MeleeSpamProtection, g_bCvar_MeleeSpamProtection ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_baseball_bat : %b (%s)", g_bCvar_Melee_Baseball_Bat, g_bCvar_Melee_Baseball_Bat ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_cricket_bat : %b (%s)", g_bCvar_Melee_Cricket_Bat, g_bCvar_Melee_Cricket_Bat ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_crowbar : %b (%s)", g_bCvar_Melee_Crowbar, g_bCvar_Melee_Crowbar ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_electric_guitar : %b (%s)", g_bCvar_Melee_Electric_Guitar, g_bCvar_Melee_Electric_Guitar ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_fireaxe : %b (%s)", g_bCvar_Melee_Fireaxe, g_bCvar_Melee_Fireaxe ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_frying_pan : %b (%s)", g_bCvar_Melee_Frying_Pan, g_bCvar_Melee_Frying_Pan ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_golfclub : %b (%s)", g_bCvar_Melee_Golfclub, g_bCvar_Melee_Golfclub ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_katana : %b (%s)", g_bCvar_Melee_Katana, g_bCvar_Melee_Katana ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_knife : %b (%s)", g_bCvar_Melee_Knife, g_bCvar_Melee_Knife ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_machete : %b (%s)", g_bCvar_Melee_Machete, g_bCvar_Melee_Machete ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_tonfa : %b (%s)", g_bCvar_Melee_Tonfa, g_bCvar_Melee_Tonfa ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_pitchfork : %b (%s)", g_bCvar_Melee_Pitchfork, g_bCvar_Melee_Pitchfork ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_shovel : %b (%s)", g_bCvar_Melee_Shovel, g_bCvar_Melee_Shovel ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_riotshield : %b (%s)", g_bCvar_Melee_RiotShield, g_bCvar_Melee_RiotShield ? "true" : "false");
    PrintToConsole(client, "l4d2_nerf_damage_common_melee_custom : %b (%s)", g_bCvar_Melee_Custom, g_bCvar_Melee_Custom ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "z_health : %i", FindConVar("z_health").IntValue);
    PrintToConsole(client, "chainsaw_damage : %i", g_iCvar_chainsaw_damage);
    PrintToConsole(client, "z_non_head_damage_factor_easy : %.2f", g_fCvar_z_non_head_damage_factor_easy);
    PrintToConsole(client, "z_non_head_damage_factor_normal : %.2f", g_fCvar_z_non_head_damage_factor_normal);
    PrintToConsole(client, "z_non_head_damage_factor_hard : %.2f", g_fCvar_z_non_head_damage_factor_hard);
    PrintToConsole(client, "z_non_head_damage_factor_expert : %.2f", g_fCvar_z_non_head_damage_factor_expert);
    PrintToConsole(client, "z_non_head_damage_factor_multiplier : %.2f", g_fCvar_z_non_head_damage_factor_multiplier);
    PrintToConsole(client, "z_difficulty : \"%s\" %s", g_sCvar_z_difficulty, g_iCvar_z_difficulty == Z_DIFFICULTY_EXPERT ? "(expert)" : "");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------------------------------------------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "left4dhooks : %s", g_bLeft4DHooks ? "true" : "false");
    PrintToConsole(client, "Current Damage Factor : %.2f => (Difficulty: %.2f * Multiplier: %.2f)", g_fDamageFactor, g_fDifficultyFactor, g_fCvar_z_non_head_damage_factor_multiplier);
    PrintToConsole(client, "");
    CreateTimer(0.1, TimerPrintCvars, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action TimerPrintCvars(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (!IsValidClient(client))
        return Plugin_Handled;

    PrintToConsole(client, "------------------ Weapons Damage and RangeModifier ------------------");
    PrintToConsole(client, "");
    if (g_bLeft4DHooks)
    {
        char weaponName[24];
        int weaponDamage;
        float weaponRangeModifier;
        for (int i = 0; i < g_alWeaponInfo.Length; i++)
        {
            g_alWeaponInfo.GetString(i, weaponName, sizeof(weaponName));
            weaponDamage = L4D2_GetIntWeaponAttribute(weaponName, L4D2IWA_Damage);
            weaponRangeModifier = L4D2_GetFloatWeaponAttribute(weaponName, L4D2FWA_RangeModifier);
            PrintToConsole(client, "%s : Damage = %i, RangeModifier = %.2f", weaponName, weaponDamage, weaponRangeModifier);
        }
    }
    PrintToConsole(client, "%s : Damage = %i (game cvar), RangeModifier = %.2f", "weapon_chainsaw", g_iCvar_chainsaw_damage, 1.00);
    PrintToConsole(client, "%s : Damage = %i (plugin cvar), RangeModifier = %.2f", "weapon_melee", g_iCvar_MeleeDamage, 1.00);
    PrintToConsole(client, "%s : Damage = %i (plugin cvar), RangeModifier (plugin cvar) = %.2f", "minigun", g_iCvar_MinigunDamage, g_fCvar_MinigunRangeModifier);
    PrintToConsole(client, "%s : Damage = %i (plugin cvar), RangeModifier (plugin cvar) = %.2f", "50cal", g_iCvar_50CalDamage, g_fCvar_50CalRangeModifier);
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