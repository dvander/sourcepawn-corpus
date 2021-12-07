#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <lang>
#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#include <dhooks>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1

#define VERSION "0.13.4"

#define UPDATE_URL "http://sourcemodplugin.h3bus.fr/deathmatch/updatefile.txt"

#define DMG_HEADSHOT (1 << 30)

new Float:g_vOffWorldPosition[3] = {-9999.9, -9999.9, -9999.9};

enum weapons_Types {
    weapons_type_Primary,
    weapons_type_Secondary,
    weapons_type_Equipement,
    weapons_type_None
};
////
#include "deathmatch/utils.sp"
#include "deathmatch/fifo.sp"
#include "deathmatch/kvtree.sp"
#include "deathmatch/smc_reader.sp"
#include "deathmatch/cvar_stack.sp"
#include "deathmatch/cvars.sp"
#include "deathmatch/config.sp"
#include "deathmatch/dhook.sp"
#include "deathmatch/sounds.sp"
#include "deathmatch/warmup.sp"
#include "deathmatch/weapons.sp"
#include "deathmatch/weapons_tracker.sp"
#include "deathmatch/players.sp"
#include "deathmatch/user_messages.sp"
#include "deathmatch/config_messages.sp"
#include "deathmatch/menus_fifo.sp"
#include "deathmatch/menus.sp"
#include "deathmatch/rank_display.sp"
#include "deathmatch/spawns.sp"
#include "deathmatch/admin_cmd.sp"
#include "deathmatch/admin_menu_tree.sp"
#include "deathmatch/admin_menu.sp"

public Plugin:myinfo =
{
    name = "Deathmatch",
    author = "H3bus",
    description = "Deathmatch/Warmups/Per map configuration.",
    version = VERSION,
    url = "http://www.sourcemod.net/"
};

new bool:g_bLateLoaded = false;
new bool:g_bDelayExecNotRun = true;
new bool:g_bMapStarted = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    decl String:gamedir[PLATFORM_MAX_PATH];
    GetGameFolderName(gamedir, sizeof(gamedir));
    if( strcmp(gamedir, "csgo") != 0)
    {
        strcopy(error, err_max, "This plugin is only supported on CSGO");
        return APLRes_Failure;
    }
    
    g_bLateLoaded = late;
    
    return APLRes_Success;
}

public OnPluginStart()
{
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
    
    LoadTranslations("deathmatch.phrases");
    
    config_Init();
    userMessage_Init();
    configMessages_Init();
    dhook_Init();
    weapons_Init();
    cvars_Init();
    players_Init();
    menusFifo_Init();
    menus_Init();
    adminMenu_init();
    adminCmd_Init();
    config_Init();
    spawns_Init();
    sounds_Init();
     
    // Client Commands
    RegConsoleCmd("sm_guns", Command_Guns, "Opens the !guns menu");
    
    AddCommandListener(Event_Say, "say");
    AddCommandListener(Event_Say, "say_team");
    AddCommandListener(Event_Drop, "drop");
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("gg_killed_enemy", Event_GGKilledEnemy, EventHookMode_Pre);
    HookEvent("hegrenade_detonate", Event_HegrenadeDetonate, EventHookMode_Post);
    HookEvent("player_given_c4", Event_BombPickup, EventHookMode_Post);
    HookEvent("bomb_pickup", Event_BombPickup, EventHookMode_Post);
    HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
    HookUserMessage(GetUserMessageId("TextMsg"), Event_TextMsg, true);
    HookUserMessage(GetUserMessageId("HintText"), Event_HintText, true);
    AddNormalSoundHook(Event_Sound);
    AddAmbientSoundHook(Event_AmbiantSound);
    AddTempEntHook("EffectDispatch", TE_OnEffectDispatch);
    AddTempEntHook("World Decal", TE_OnDecal);
    AddTempEntHook("Entity Decal", TE_OnDecal);
    
    for(new clientIndex = 1; clientIndex <= MaxClients; clientIndex++)
    {
        if(players_IsClientValid(clientIndex) && IsClientInGame(clientIndex))
            SDKHook(clientIndex, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public OnPluginEnd()
{
    SetBuyZones("Enable");
    SetObjectives("Enable");

    config_Close();
    menus_Close();
    menusFifo_Close();
    cvars_Close();
    weapons_Close();
    configMessages_Close();
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
    
    rankdisplay_OnLibraryAdded(name);
    dhook_OnLibraryAdded(name);
}

public OnLibraryRemoved(const String:name[])
{    
    rankdisplay_OnLibraryRemoved(name);
    dhook_OnLibraryRemoved(name);
}

UpdateState()
{
    if(!g_bMapStarted)
        return;
        
    new old_enabled = g_bConfig_Enabled;
    new old_gunMenuMode = g_iConfig_GunMenuMode;
    decl String:default_primary_ent[WEAPON_ENTITIES_NAME_SIZE];
    decl String:default_secondary_ent[WEAPON_ENTITIES_NAME_SIZE];
    decl String:gunMenuTriggers[CONFIG_GUN_TRIGGER_MAX_COUNT*(CONFIG_GUN_TRIGGER_MAX_SIZE)];
    decl String:entityRemoval[CONFIG_ENTITY_REMOVAL_MAX_COUNT*(CONFIG_ENTITY_REMOVAL_MAX_SIZE)];
    decl String:equimpentReward[200];
    decl String:customSpawnSounds[SOUNDS_SPAWN_MAX_POOL_COUNT*SOUNDS_SPAWN_MAX_PATH_SIZE];
    decl bool:customSpawnSoundsEnabled;
    decl customSpawnSoundsLevel;
    decl String:strColor[200];
    decl String:strColor_Deserialized[4][5];
    decl String:textFilters[CONFIG_FILTERS_MAX_COUNT*(CONFIG_FILTERS_MAX_SIZE)];
    
    new Handle:CvarHandle;
    
    if((CvarHandle = FindConVar("mp_randomspawn")) != INVALID_HANDLE)
        g_bConfig_mp_randomspawn           = GetConVarBool(CvarHandle);
    if((CvarHandle = FindConVar("mp_randomspawn_los")) != INVALID_HANDLE)
        g_bConfig_mp_randomspawn_los           = GetConVarBool(CvarHandle);
    if((CvarHandle = FindConVar("mp_teammates_are_enemies")) != INVALID_HANDLE)
        g_bConfig_mp_teammates_are_enemies  = GetConVarBool(CvarHandle);
    if((CvarHandle = FindConVar("mp_death_drop_gun")) != INVALID_HANDLE)
        g_iConfig_mp_death_drop_gun  = GetConVarInt(CvarHandle);
    if((CvarHandle = FindConVar("mp_death_drop_grenade")) != INVALID_HANDLE)
        g_iConfig_mp_death_drop_grenade  = GetConVarInt(CvarHandle);
    
    g_bConfig_Enabled                   = cvars_GetPluginConvarBool(eCvars_dm_enabled);
    g_bConfig_RemoveObjectives          = cvars_GetPluginConvarBool(eCvars_dm_remove_objectives);
    g_bConfig_RemoveChickens            = cvars_GetPluginConvarBool(eCvars_dm_remove_chickens);
    g_bConfig_HideRadar                 = cvars_GetPluginConvarBool(eCvars_dm_hide_radar);
    
    g_bConfig_WeaponsAllowThirdParty    = cvars_GetPluginConvarBool(eCvars_dm_weapons_allow_3rd_party);
    g_bConfig_WeaponsAllowUncarried     = cvars_GetPluginConvarBool(eCvars_dm_weapons_allow_not_carried);
    g_bConfig_WeaponsAllowDrop          = cvars_GetPluginConvarBool(eCvars_dm_weapons_allow_drop);
    g_bConfig_WeaponsAllowNadeDrop      = cvars_GetPluginConvarBool(eCvars_dm_weapons_allow_drop_nade);
    g_bConfig_WeaponsAllowKnifeDrop     = cvars_GetPluginConvarBool(eCvars_dm_weapons_allow_drop_knife);
    g_bConfig_WeaponsAllowTazerDrop     = cvars_GetPluginConvarBool(eCvars_dm_weapons_allow_drop_zeus);
    g_bConfig_WeaponsAllowC4Drop        = cvars_GetPluginConvarBool(eCvars_dm_weapons_allow_drop_c4);
    g_iConfig_WeaponsMaxUncarried       = cvars_GetPluginConvarInt(eCvars_dm_weapons_max_not_carried);
    g_iConfig_WeaponsMaxUncarriedSameType               = cvars_GetPluginConvarInt(eCvars_dm_weapons_max_same_not_carried);
    g_bConfig_WeaponsUncarriedEnforce_FurthestToPlayers = cvars_GetPluginConvarBool(eCvars_dm_weapons_remove_furthest);
    g_bConfig_WeaponsUncarriedEnforce_NotInPlayerLOS            = cvars_GetPluginConvarBool(eCvars_dm_weapons_remove_not_in_los);
    g_bConfig_WeaponsUncarriedEnforce_MostWeaponSameTypeFirst   = cvars_GetPluginConvarBool(eCvars_dm_weapons_remove_sametype_first);
    
    g_bConfig_RandomSpam_Internal       = cvars_GetPluginConvarBool(eCvars_dm_randomspawn_internal);
    g_bConfig_NormalSpam_Internal       = cvars_GetPluginConvarBool(eCvars_dm_normalspawn_internal);
    g_bConfig_NormalSpam_LOS            = cvars_GetPluginConvarBool(eCvars_dm_normalspawn_los);
    g_fConfig_MedianSpawnDistance_ratio = cvars_GetPluginConvarFloat(eCvars_dm_spawn_median_distance_ratio);
    g_fConfig_MedianSpawnDistance_ratio *= g_fConfig_MedianSpawnDistance_ratio;
    g_fConfig_MinTeamSpawnDistance_ratio = cvars_GetPluginConvarFloat(eCvars_dm_spawn_min_team_distance_ratio);
    g_fConfig_MinTeamSpawnDistance_ratio *= g_fConfig_MinTeamSpawnDistance_ratio;
    spawns_ApplyMedianRatio(g_fConfig_MedianSpawnDistance_ratio, g_fConfig_MinTeamSpawnDistance_ratio);
    
    g_bConfig_SpawnFade_Enable          = cvars_GetPluginConvarBool(eCvars_dm_spawn_fade_enable);
    g_iConfig_SpawnFade_HoldDuration    = RoundFloat(cvars_GetPluginConvarFloat(eCvars_dm_spawn_fade_hold_duration) * 1000.0);
    g_iConfig_SpawnFade_Duration        = RoundFloat(cvars_GetPluginConvarFloat(eCvars_dm_spawn_fade_duration) * 1000.0);
    
    cvars_GetPluginConvarString(eCvars_dm_spawn_fade_color, strColor, sizeof(strColor));
    RemoveChar(strColor, ' ');
    new colorCount = deserializeStrings(strColor, strColor_Deserialized, sizeof(strColor_Deserialized), sizeof(strColor_Deserialized[]), ',');
    if(colorCount > sizeof(g_iConfig_SpawnFade_Color)) colorCount = sizeof(g_iConfig_SpawnFade_Color);
    for(new i = 0; i < colorCount; i++)
        g_iConfig_SpawnFade_Color[i]  = StringToInt(strColor_Deserialized[i]);
    
    g_bConfig_SpawnProtection_Enable    = cvars_GetPluginConvarBool(eCvars_dm_spawn_protection_enable);
    g_fConfig_SpawnProtection_Duration  = cvars_GetPluginConvarFloat(eCvars_dm_spawn_protection_duration);
    g_bConfig_SpawnProtection_ClearOnShoot = cvars_GetPluginConvarBool(eCvars_dm_spawn_protection_clearonshoot);
    
    
    cvars_GetPluginConvarString(eCvars_dm_spawn_protection_color_ct, strColor, sizeof(strColor));
    RemoveChar(strColor, ' ');
    colorCount = deserializeStrings(strColor, strColor_Deserialized, sizeof(strColor_Deserialized), sizeof(strColor_Deserialized[]), ',');
    if(colorCount > sizeof(g_iConfig_SpawnProtection_ColorCT)) colorCount = sizeof(g_iConfig_SpawnProtection_ColorCT);
    for(new i = 0; i < colorCount; i++)
        g_iConfig_SpawnProtection_ColorCT[i]  = StringToInt(strColor_Deserialized[i]);
    
    cvars_GetPluginConvarString(eCvars_dm_spawn_protection_color_t, strColor, sizeof(strColor));
    RemoveChar(strColor, ' ');
    colorCount = deserializeStrings(strColor, strColor_Deserialized, sizeof(strColor_Deserialized), sizeof(strColor_Deserialized[]), ',');
    if(colorCount > sizeof(g_iConfig_SpawnProtection_ColorT)) colorCount = sizeof(g_iConfig_SpawnProtection_ColorT);
    for(new i = 0; i < colorCount; i++)
        g_iConfig_SpawnProtection_ColorT[i]  = StringToInt(strColor_Deserialized[i]);
    
    cvars_GetPluginConvarString(eCvars_dm_spawn_protection_hudfadecolor_ct, strColor, sizeof(strColor));
    RemoveChar(strColor, ' ');
    colorCount = deserializeStrings(strColor, strColor_Deserialized, sizeof(strColor_Deserialized), sizeof(strColor_Deserialized[]), ',');
    if(colorCount > sizeof(g_iConfig_SpawnProtection_HUDColorCT)) colorCount = sizeof(g_iConfig_SpawnProtection_ColorT);
    for(new i = 0; i < colorCount; i++)
        g_iConfig_SpawnProtection_HUDColorCT[i]  = StringToInt(strColor_Deserialized[i]);
    
    cvars_GetPluginConvarString(eCvars_dm_spawn_protection_hudfadecolor_t, strColor, sizeof(strColor));
    RemoveChar(strColor, ' ');
    colorCount = deserializeStrings(strColor, strColor_Deserialized, sizeof(strColor_Deserialized), sizeof(strColor_Deserialized[]), ',');
    if(colorCount > sizeof(g_iConfig_SpawnProtection_HUDColorT)) colorCount = sizeof(g_iConfig_SpawnProtection_ColorT);
    for(new i = 0; i < colorCount; i++)
        g_iConfig_SpawnProtection_HUDColorT[i]  = StringToInt(strColor_Deserialized[i]);
    
    g_iConfig_GunMenuMode               = cvars_GetPluginConvarInt (eCvars_dm_gun_menu_mode);
    g_bConfig_LimitedWeaponsRotation    = cvars_GetPluginConvarBool(eCvars_dm_limited_weapons_rotation);
    g_fConfig_LimitedWeaponsRotationTime    = cvars_GetPluginConvarFloat(eCvars_dm_limited_weapons_rotation_time);
    g_fConfig_LimitedWeaponsRotationMinTime = cvars_GetPluginConvarFloat(eCvars_dm_limited_weapons_rotation_min_time);
    g_bConfig_ReplenishAmmo             = cvars_GetPluginConvarBool(eCvars_dm_replenish_ammo);
    g_bConfig_ReplenishClip             = cvars_GetPluginConvarBool(eCvars_dm_replenish_clip);
    g_bConfig_ReplenishClipHS           = cvars_GetPluginConvarBool(eCvars_dm_replenish_clip_headshot);
    g_bConfig_ReplenishClipKnife        = cvars_GetPluginConvarBool(eCvars_dm_replenish_clip_knife);
    g_bConfig_ReplenishClipNade         = cvars_GetPluginConvarBool(eCvars_dm_replenish_clip_nade);
    g_bConfig_FastEquip                 = cvars_GetPluginConvarBool(eCvars_dm_fast_equip);
    g_bConfig_NoDamage_Knife            = cvars_GetPluginConvarBool(eCvars_dm_no_damage_knife);
    g_bConfig_NoDamage_Taser            = cvars_GetPluginConvarBool(eCvars_dm_no_damage_taser);
    g_bConfig_NoDamage_Nade             = cvars_GetPluginConvarBool(eCvars_dm_no_damage_nade);
    g_bConfig_NoDamage_World            = cvars_GetPluginConvarBool(eCvars_dm_no_damage_world);
    g_bConfig_OnlyHS                    = cvars_GetPluginConvarBool(eCvars_dm_onlyhs);
    g_bConfig_NoDamage_TriggerHurt      = cvars_GetPluginConvarBool(eCvars_dm_no_damage_trigger_hurt);
    g_bConfig_OnlyHS_OneShot            = cvars_GetPluginConvarBool(eCvars_dm_onlyhs_oneshot);
    g_bConfig_OnlyHS_AllowKnife         = cvars_GetPluginConvarBool(eCvars_dm_onlyhs_allowknife);
    g_bConfig_OnlyHS_AllowTaser         = cvars_GetPluginConvarBool(eCvars_dm_onlyhs_allowtaser);
    g_bConfig_OnlyHS_AllowNade          = cvars_GetPluginConvarBool(eCvars_dm_onlyhs_allownade);
    g_bConfig_OnlyHS_AllowWorld         = cvars_GetPluginConvarBool(eCvars_dm_onlyhs_allowworld);
    g_bConfig_OnlyHS_AllowTriggerHurt   = cvars_GetPluginConvarBool(eCvars_dm_onlyhs_allowtriggerhurt);
    g_iConfig_StartHP                   = cvars_GetPluginConvarInt (eCvars_dm_hp_start);
    g_iConfig_MaxHP                     = cvars_GetPluginConvarInt (eCvars_dm_hp_max);
    g_iConfig_StartKevlar               = cvars_GetPluginConvarInt (eCvars_dm_kevlar_start);
    g_iConfig_MaxKevlar                 = cvars_GetPluginConvarInt (eCvars_dm_kevlar_max);
    g_iConfig_HPPerKill                 = cvars_GetPluginConvarInt (eCvars_dm_hp_kill);
    g_iConfig_HPPerHeadshotKill         = cvars_GetPluginConvarInt (eCvars_dm_hp_hs);
    g_iConfig_HPPerKnifeKill            = cvars_GetPluginConvarInt (eCvars_dm_hp_knife);
    g_iConfig_HPPerNadeKill             = cvars_GetPluginConvarInt (eCvars_dm_hp_nade);
    g_iConfig_HPToKevlarRatio           = RoundFloat(cvars_GetPluginConvarFloat(eCvars_dm_hp_to_kevlar_ratio) * 100.0);
    g_iConfig_HPToKevlarMode            = cvars_GetPluginConvarInt (eCvars_dm_hp_to_kevlar_mode);
    g_iConfig_HPToHelmet                = cvars_GetPluginConvarInt (eCvars_dm_hp_to_helmet);
    g_bConfig_DisplayHPMessages         = cvars_GetPluginConvarBool(eCvars_dm_hp_messages);
    g_bConfig_Helmet                    = cvars_GetPluginConvarBool(eCvars_dm_helmet);
    g_iConfig_Zeus                      = cvars_GetPluginConvarInt(eCvars_dm_zeus);
    g_bConfig_Knife                     = cvars_GetPluginConvarBool(eCvars_dm_knife);
    g_bConfig_Defuser                   = cvars_GetPluginConvarBool(eCvars_dm_defuser);
    
    g_iConfig_Incendiary                = cvars_GetPluginConvarInt (eCvars_dm_nades_incendiary);
    g_iConfig_Decoy                     = cvars_GetPluginConvarInt (eCvars_dm_nades_decoy);
    g_iConfig_flashbang                 = cvars_GetPluginConvarInt (eCvars_dm_nades_flashbang);
    g_iConfig_He                        = cvars_GetPluginConvarInt (eCvars_dm_nades_he);
    g_iConfig_Smoke                     = cvars_GetPluginConvarInt (eCvars_dm_nades_smoke);
    
    g_iConfig_ZeusMax                   = cvars_GetPluginConvarInt(eCvars_dm_zeus_max);
    g_iConfig_IncendiaryMax             = cvars_GetPluginConvarInt (eCvars_dm_nades_incendiary_max);
    g_iConfig_DecoyMax                  = cvars_GetPluginConvarInt (eCvars_dm_nades_decoy_max);
    g_iConfig_flashbangMax              = cvars_GetPluginConvarInt (eCvars_dm_nades_flashbang_max);
    g_iConfig_HeMax                     = cvars_GetPluginConvarInt (eCvars_dm_nades_he_max);
    g_iConfig_SmokeMax                  = cvars_GetPluginConvarInt (eCvars_dm_nades_smoke_max);
    
    g_bConfig_ConnectHideMenu           = cvars_GetPluginConvarBool(eCvars_dm_connect_hide_menu);
    g_bConfig_RandomMenuEnabled         = cvars_GetPluginConvarBool(eCvars_dm_enable_random_menu);
    
    g_fConfig_SpawnEditorSpeed_ratio    = cvars_GetPluginConvarFloat(eCvars_dm_spawns_editor_speed_ratio);
    g_fConfig_SpawnEditorGravity_ratio  = cvars_GetPluginConvarFloat(eCvars_dm_spawns_editor_gravity_ratio);
    
    g_bConfig_Filter_KillEvents         = cvars_GetPluginConvarBool(eCvars_dm_filter_kill_log);
    g_bConfig_Filter_KillBeep           = cvars_GetPluginConvarBool(eCvars_dm_filter_kill_beep);
    
    g_bConfigs_FilterBloodDecals        = cvars_GetPluginConvarBool(eCvars_dm_filter_blood_decals);
    g_bConfigs_FilterBloodSplatter      = cvars_GetPluginConvarBool(eCvars_dm_filter_blood_splatter);
    
    cvars_GetPluginConvarString(eCvars_dm_default_primary, default_primary_ent, sizeof(default_primary_ent));
    cvars_GetPluginConvarString(eCvars_dm_default_secondary, default_secondary_ent, sizeof(default_secondary_ent));
    
    weapons_FindId(default_primary_ent, g_iConfig_DefaultPrimary);
    if(g_iConfig_DefaultPrimary > NO_WEAPON_SELECTED)
        weapons_SetLimit(g_iConfig_DefaultPrimary, -1);
    weapons_FindId(default_secondary_ent, g_iConfig_DefaultSecondary);
    if(g_iConfig_DefaultSecondary > NO_WEAPON_SELECTED)
        weapons_SetLimit(g_iConfig_DefaultSecondary, -1);
    
    cvars_GetPluginConvarString(eCvars_dm_gun_menu_triggers, gunMenuTriggers, sizeof(gunMenuTriggers));
    g_iGunMenuTriggersCount = deserializeStrings(gunMenuTriggers, g_sGunMenuTriggers, CONFIG_GUN_TRIGGER_MAX_COUNT, CONFIG_GUN_TRIGGER_MAX_SIZE);
    
    cvars_GetPluginConvarString(eCvars_dm_entity_remove_plugin, entityRemoval, sizeof(entityRemoval));
    g_iSystemEntityRemovalCount = deserializeStrings(entityRemoval, g_sSystemEntityRemoval, CONFIG_ENTITY_REMOVAL_MAX_COUNT, CONFIG_ENTITY_REMOVAL_MAX_SIZE);
    
    cvars_GetPluginConvarString(eCvars_dm_entity_remove_user, entityRemoval, sizeof(entityRemoval));
    g_iUserEntityRemovalCount = deserializeStrings(entityRemoval, g_sUserEntityRemoval, CONFIG_ENTITY_REMOVAL_MAX_COUNT, CONFIG_ENTITY_REMOVAL_MAX_SIZE);
    
    cvars_GetPluginConvarString(eCvars_dm_equip_kill, equimpentReward, sizeof(equimpentReward));
    players_LoadEquimpentReward(equimpentReward, players_EquipmentReward_Kill);
    
    cvars_GetPluginConvarString(eCvars_dm_equip_headshot, equimpentReward, sizeof(equimpentReward));
    players_LoadEquimpentReward(equimpentReward, players_EquipmentReward_HS);
    
    cvars_GetPluginConvarString(eCvars_dm_equip_knife, equimpentReward, sizeof(equimpentReward));
    players_LoadEquimpentReward(equimpentReward, players_EquipmentReward_Knife);
    
    cvars_GetPluginConvarString(eCvars_dm_equip_nade, equimpentReward, sizeof(equimpentReward));
    players_LoadEquimpentReward(equimpentReward, players_EquipmentReward_Nade);
    
    customSpawnSoundsEnabled    = cvars_GetPluginConvarBool(eCvars_dm_spawn_custom_sounds_enable);
    customSpawnSoundsLevel      = cvars_GetPluginConvarInt(eCvars_dm_spawn_custom_sounds_level);
    cvars_GetPluginConvarString(eCvars_dm_spawn_custom_sounds, customSpawnSounds, sizeof(customSpawnSounds));
    sounds_LoadSpawnSounds_ToOthers(customSpawnSoundsEnabled, customSpawnSoundsLevel, customSpawnSounds);
    
    customSpawnSoundsEnabled    = cvars_GetPluginConvarBool(eCvars_dm_spawn_custom_sounds_to_self_enable);
    customSpawnSoundsLevel      = cvars_GetPluginConvarInt(eCvars_dm_spawn_custom_sounds_to_self_level);
    cvars_GetPluginConvarString(eCvars_dm_spawn_custom_sounds_to_self, customSpawnSounds, sizeof(customSpawnSounds));
    sounds_LoadSpawnSounds_ToPlayer(customSpawnSoundsEnabled, customSpawnSoundsLevel, customSpawnSounds);
    
    customSpawnSoundsEnabled    = cvars_GetPluginConvarBool(eCvars_dm_spawn_custom_sounds_to_team_enable);
    customSpawnSoundsLevel      = cvars_GetPluginConvarInt(eCvars_dm_spawn_custom_sounds_to_team_level);
    cvars_GetPluginConvarString(eCvars_dm_spawn_custom_sounds_to_team, customSpawnSounds, sizeof(customSpawnSounds));
    sounds_LoadSpawnSounds_ToTeam(customSpawnSoundsEnabled, customSpawnSoundsLevel, customSpawnSounds);
    
    g_bConfig_Filter_Texts = cvars_GetPluginConvarBool(eCvars_dm_filter_texts_enabled);
    g_bConfig_Log_Texts = cvars_GetPluginConvarBool(eCvars_dm_log_texts_enabled);
    cvars_GetPluginConvarString(eCvars_dm_filter_texts, textFilters, sizeof(textFilters));
    RemoveChar(textFilters, ' ');
    g_iConfig_Filter_Texts_Count = deserializeStrings(textFilters, g_sConfig_Filter_Texts, CONFIG_FILTERS_MAX_COUNT, CONFIG_FILTERS_MAX_SIZE, .separator=',');
    
    g_bConfig_Filter_Hints = cvars_GetPluginConvarBool(eCvars_dm_filter_hints_enabled);
    g_bConfig_Log_Hints = cvars_GetPluginConvarBool(eCvars_dm_log_hints_enabled);
    cvars_GetPluginConvarString(eCvars_dm_filter_hints, textFilters, sizeof(textFilters));
    RemoveChar(textFilters, ' ');
    g_iConfig_Filter_Hints_Count = deserializeStrings(textFilters, g_sConfig_Filter_Hints, CONFIG_FILTERS_MAX_COUNT, CONFIG_FILTERS_MAX_SIZE, .separator=',');
    
    g_bConfig_Filter_Sounds = cvars_GetPluginConvarBool(eCvars_dm_filter_sounds_enabled);
    g_bConfig_Log_Sounds = cvars_GetPluginConvarBool(eCvars_dm_log_sounds_enabled);
    cvars_GetPluginConvarString(eCvars_dm_filter_sounds, textFilters, sizeof(textFilters));
    RemoveChar(textFilters, ' ');
    g_iConfig_Filter_Sounds_Count = deserializeStrings(textFilters, g_sConfig_Filter_Sounds, CONFIG_FILTERS_MAX_COUNT, CONFIG_FILTERS_MAX_SIZE, .separator=',');
    
    
    rankdisplay_CvarUpdate();
    
    if(g_iConfig_Zeus < 0)
    {
        g_iConfig_Zeus = 1;
        g_bConfig_ZeusRefill = true;
    }
    else
        g_bConfig_ZeusRefill = false;
    
    if (g_iConfig_He < 0)
    {
        g_iConfig_He = 1;
        g_bConfig_HeRefill = true;
    }
    else
        g_bConfig_HeRefill = false;
    
    if(g_bConfig_Knife)
    {
        weapons_SetLimit(g_iWeapons_WeaponIndex_Knife, -1);
    }
    else
    {
        weapons_SetLimit(g_iWeapons_WeaponIndex_Knife, 0);
        
    }
    
    players_UpdateSpawnEquipment();
    players_UpdateMaxEquipment();
    
    if (g_bConfig_Enabled && !old_enabled)
    {
        players_ResetAllClientsSettings();
        players_RespawnAll();
        SetBuyZones("Disable");
        decl String:status[10];
        status = (g_bConfig_RemoveObjectives) ? "Disable" : "Enable";
        SetObjectives(status);
    }
    else if (!g_bConfig_Enabled && old_enabled)
    {
        menus_Close();
        SetBuyZones("Enable");
        SetObjectives("Enable");
        cvars_RestoreCvars(.keepedAlso = true, .clearLocked = true);
    }
    
    if (g_bConfig_Enabled)
    {
        SetGrenadeState();
        SetZeusState();
        
        if (g_iConfig_GunMenuMode != old_gunMenuMode && g_iConfig_GunMenuMode != 1)
        {
            menus_Close();
        }
        
    }
}

public Action:Timer_DelayExec(Handle:timer)
{
    // Hotfix or Delayed exec is run twice at server start. Don't know why
    if (g_bDelayExecNotRun)
    {
        if (!g_bLateLoaded)
        {
            warmup_Start();
        }
        else
        {
            config_Load(false);
            weapons_ResetUsers();
            menus_Close();
            players_ResetAllClientsSettings();
            players_RespawnAll();
        }
        
        g_bLateLoaded = false;
        g_bDelayExecNotRun = false;
    }
}

public OnMapStart()
{
    new Float:OffWorldOffset[3] = {-100.0, -100.0, -100.0};

    utils_OnMapStart();
    config_OnMapStart();
    menus_OnMapStart();
    rankDisplay_OnMapStart();
    spawns_OnMapStart();
    sounds_OnMapStart();
    weapons_OnMapStart();

    GetEntPropVector(0, Prop_Data, "m_WorldMins", g_vOffWorldPosition);
    AddVectors(g_vOffWorldPosition, OffWorldOffset, g_vOffWorldPosition);
    
    g_bDelayExecNotRun = true;
    CreateTimer(0.1, Timer_DelayExec, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
        
    if (g_bConfig_Enabled)
    {
        SetBuyZones("Disable");
        if (g_bConfig_RemoveObjectives)
        {
            SetObjectives("Disable");
            RemoveHostages();
        }
        SetGrenadeState();
        SetZeusState();
    }
    
    g_bMapStarted = true;
}

public OnMapEnd()
{
    userMessage_OnMapEnd();
    spawns_OnMapEnd();
    
    g_bMapStarted = false;
}

public Action:Event_TextMsg(UserMsg:msg_id, Handle:pb, const players[], playersNum, bool:reliable, bool:init)
{
    if(g_bConfig_Enabled && g_bConfig_Filter_Texts)
    {
        decl String:text[CONFIG_FILTERS_MAX_SIZE];
        
        PbReadString(pb, "params", text, sizeof(text), 0);
    
        if(g_bConfig_Log_Texts)
            LogMessage("LOG Text: \"%s\"", text);
        
        if(IsStringInList(text, g_sConfig_Filter_Texts, g_iConfig_Filter_Texts_Count))
            return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action:Event_HintText(UserMsg:msg_id, Handle:pb, const players[], playersNum, bool:reliable, bool:init)
{
    if(g_bConfig_Enabled && g_bConfig_Filter_Hints)
    {
        decl String:text[CONFIG_FILTERS_MAX_SIZE];
        
        PbReadString(pb, "text", text, sizeof(text));
        
        if(g_bConfig_Log_Hints)
            LogMessage("LOG Hint: \"%s\"", text);
        
        if(IsStringInList(text, g_sConfig_Filter_Hints, g_iConfig_Filter_Hints_Count))
            return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action:Event_Sound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
    if(g_bConfig_Enabled && g_bConfig_Filter_Sounds)
    {
        if(g_bConfig_Log_Sounds)
            LogMessage("LOG Sound: \"%s\"", sample);
        
        if(IsStringInList(sample, g_sConfig_Filter_Sounds, g_iConfig_Filter_Sounds_Count))
            return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action:Event_AmbiantSound(String:sample[PLATFORM_MAX_PATH], &entity, &Float:volume, &level, &pitch, Float:pos[3], &flags, &Float:delay)
{
    if(g_bConfig_Enabled && g_bConfig_Filter_Sounds)
    {
        if(g_bConfig_Log_Sounds)
            LogMessage("LOG Sound: \"%s\"", sample);
        
        if(IsStringInList(sample, g_sConfig_Filter_Sounds, g_iConfig_Filter_Sounds_Count))
            return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action:Event_Say(clientIndex, const String:command[], arg)
{
    if (g_bConfig_Enabled && players_IsClientValid(clientIndex) && IsClientInGame(clientIndex) && (Teams:GetClientTeam(clientIndex) > TeamSpectator))
    {
        decl String:text[11];
        GetCmdArgString(text, sizeof(text));
        StripQuotes(text);
        TrimChatTriggers(text);
    
        for(new i = 0; i < g_iGunMenuTriggersCount; i++)
        {
            if (StrEqual(text, g_sGunMenuTriggers[i], false))
            {
                menus_OnClientRequestGuns(clientIndex);
                return Plugin_Handled;
            }
        }
    }
    return Plugin_Continue;
}

public Action:Event_Drop(clientIndex, const String:command[], arg)
{
    if (g_bConfig_Enabled)
    {
        players_OnDropCommand(clientIndex);
        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new newTeam = GetEventInt(event, "team");
    new oldTeam = GetEventInt(event, "oldteam");
    new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
    
    players_OnClientSwitchTeam(clientIndex, oldTeam, newTeam);
    
    return Plugin_Continue;
}

public Action:Timer_AfterRoundStart(Handle:timer)
{
    weapons_EnforceLimits();
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (g_bConfig_Enabled)
    {
        if (g_bConfig_RemoveObjectives)
            RemoveHostages();
            
        RemoveWeaponGeneratorEntities();
        CreateTimer(0.1, Timer_AfterRoundStart, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
    }
    return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (g_bConfig_Enabled)
    {
        new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
        
        players_OnClientSpawn(clientIndex);
        userMessage_OnClientSpawn(clientIndex);
    }
    return Plugin_Continue;
}

public Action:Event_HegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!g_bConfig_Enabled || !g_bConfig_HeRefill)
        return Plugin_Continue;
    
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    
    if(players_IsClientValid(client) && IsPlayerAlive(client))
    {
        weapons_GivePlayerItem(client,"weapon_hegrenade", g_iWeapons_WeaponIndex_HE);
        
        if(g_bConfig_FastEquip)
            players_FastSwitch(client, NO_WEAPON_SELECTED);
    }
    
    return Plugin_Continue;
}

public Action:Event_BombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!g_bConfig_Enabled || !g_bConfig_RemoveObjectives)
        return Plugin_Continue;
    
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    
    if(players_IsClientValid(client) && IsPlayerAlive(client))
        players_RemoveC4(client);
    
    return Plugin_Handled;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (g_bConfig_Enabled && GetEventInt(event, "health") <= 0)
    {
        new deadIndex = GetClientOfUserId(GetEventInt(event, "userid"));
        
        players_OnDeathEvent(deadIndex);
    }
    return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (g_bConfig_Enabled)
    {
        new deadIndex = GetClientOfUserId(GetEventInt(event, "userid"));
        new attackerIndex = GetClientOfUserId(GetEventInt(event, "attacker"));
        
        userMessage_OnClientDeath(deadIndex);
        
        if(deadIndex != attackerIndex)
            players_OnkillEvent(attackerIndex, event);
        
        if(g_bConfig_Filter_KillEvents)
            return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:Event_GGKilledEnemy(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(g_bConfig_Enabled && g_bConfig_Filter_KillBeep)
        return Plugin_Handled;
    else
        return Plugin_Continue;
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (g_bConfig_Enabled)
    {
        new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
        
        if(players_IsClientValid(clientIndex))
            players_OnWeaponFire(clientIndex);
    }
    return Plugin_Continue;
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
    if(!g_bConfig_Enabled || !players_IsClientValid(victim))
        return Plugin_Continue;
    
    if(g_bConfig_OnlyHS)
    {
        new bool:filterDamage = true;
        
        if(!players_IsClientValid(attacker))
            filterDamage = !g_bConfig_OnlyHS_AllowWorld;
        
        else
        {
            new weapon = players_GetActiveWeapon(attacker);
            new weaponId = -1;

            if(IsValidEdict(weapon))
                weapons_IsEntityTagged(weapon, weaponId);
            
            if(hitgroup == 1)
            {
                filterDamage = false;
            }
            else if(g_bConfig_OnlyHS_AllowKnife && weaponId == g_iWeapons_WeaponIndex_Knife)
            {
                filterDamage = false;
            }
            else if(g_bConfig_OnlyHS_AllowTaser && weaponId == g_iWeapons_WeaponIndex_Tazer)
            {
                filterDamage = false;
            }
            else if(g_bConfig_OnlyHS_AllowNade || g_bConfig_OnlyHS_AllowTriggerHurt)
            {
                decl String:inflictorName[WEAPON_ENTITIES_NAME_SIZE];
                GetEdictClassname(inflictor, inflictorName, sizeof(inflictorName));
                
                if(g_bConfig_OnlyHS_AllowNade && StrEqual(inflictorName, "hegrenade_projectile"))
                    filterDamage = false;
                
                if(g_bConfig_OnlyHS_AllowTriggerHurt && StrEqual(inflictorName, "trigger_hurt"))
                    filterDamage = false;
            }
        }
        
        if(filterDamage)
            return Plugin_Handled;
        else
            return Plugin_Continue;
    }
    else
    {
        new bool:filterDamage = false;
        
        if(!players_IsClientValid(attacker))
            filterDamage = g_bConfig_NoDamage_World;
        
        else
        {
            new weapon = players_GetActiveWeapon(attacker);
            new weaponId = -1;

            if(IsValidEdict(weapon))
                weapons_IsEntityTagged(weapon, weaponId);
            
            if(g_bConfig_NoDamage_Knife && weaponId == g_iWeapons_WeaponIndex_Knife)
            {
                filterDamage = true;
            }
            else if(g_bConfig_NoDamage_Taser && weaponId == g_iWeapons_WeaponIndex_Tazer)
            {
                filterDamage = true;
            }
            else if(g_bConfig_NoDamage_Nade || g_bConfig_NoDamage_TriggerHurt)
            {
                decl String:inflictorName[WEAPON_ENTITIES_NAME_SIZE];
                GetEdictClassname(inflictor, inflictorName, sizeof(inflictorName));
                
                if(g_bConfig_NoDamage_Nade && StrEqual(inflictorName, "hegrenade_projectile"))
                    filterDamage = true;
                    
                if(g_bConfig_NoDamage_TriggerHurt && StrEqual(inflictorName, "trigger_hurt"))
                    filterDamage = false;
            } 
        }
        
        if(filterDamage)
            return Plugin_Handled;
        else
            return Plugin_Continue;
    }
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
    if(!g_bConfig_Enabled || !players_IsClientValid(victim))
        return Plugin_Continue;
    
    if(g_bConfig_OnlyHS_OneShot && (damagetype & DMG_HEADSHOT != 0))
    {
        damage = float(GetClientHealth(victim) * 4);
        return Plugin_Changed;
    }
    else
        return Plugin_Continue;
}

public Action:Command_Guns(clientIndex, args)
{
    if (g_bConfig_Enabled && players_IsClientValid(clientIndex) && IsClientInGame(clientIndex))
        menus_OnClientRequestGuns(clientIndex);

    return Plugin_Handled;
}

public Action:TE_OnEffectDispatch(const String:te_name[], const Players[], numClients, Float:delay)
{
    if(!g_bConfigs_FilterBloodSplatter)
       return Plugin_Continue;
       
    new iEffectIndex = TE_ReadNum("m_iEffectName");
    decl String:sEffectName[64];

    Utils_GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));
    
    if(StrEqual(sEffectName, "csblood"))
        return Plugin_Handled;

    return Plugin_Continue;
}

public Action:TE_OnDecal(const String:te_name[], const Players[], numClients, Float:delay)
{
    if(!g_bConfigs_FilterBloodDecals)
       return Plugin_Continue;
       
    new nIndex = TE_ReadNum("m_nIndex");
    decl String:sDecalName[64];

    Utils_GetDecalName(nIndex, sDecalName, sizeof(sDecalName));
        
    if(StrStartWith(sDecalName, "decals/blood"))
        return Plugin_Handled;
    
    return Plugin_Continue;
}

SetBuyZones(const String:status[])
{
    new maxEntities = GetMaxEntities();
    decl String:class[24];
    
    for (new i = MaxClients + 1; i < maxEntities; i++)
    {
        if (IsValidEdict(i))
        {
            GetEdictClassname(i, class, sizeof(class));
            if (StrEqual(class, "func_buyzone"))
                AcceptEntityInput(i, status);
        }
    }
}

SetObjectives(const String:status[])
{
    new maxEntities = GetMaxEntities();
    decl String:class[24];
    
    for (new i = MaxClients + 1; i < maxEntities; i++)
    {
        if (IsValidEdict(i))
        {
            GetEdictClassname(i, class, sizeof(class));
            if (StrEqual(class, "func_bomb_target") || StrEqual(class, "func_hostage_rescue"))
                AcceptEntityInput(i, status);
        }
    }
}

RemoveWeaponGeneratorEntities()
{
    for (new i = 0; i < g_iSystemEntityRemovalCount; i++)
    {
        new entity = -1;
        while ((entity = FindEntityByClassname2(entity, g_sSystemEntityRemoval[i])) != -1)
        {
            AcceptEntityInput(entity, "Kill");
        }
    }
    
    for (new i = 0; i < g_iUserEntityRemovalCount; i++)
    {
        new entity = -1;
        while ((entity = FindEntityByClassname2(entity, g_sUserEntityRemoval[i])) != -1)
        {
            AcceptEntityInput(entity, "Kill");
        }
    }
}

RemoveHostages()
{
    new maxEntities = GetMaxEntities();
    decl String:class[24];
    
    for (new i = MaxClients + 1; i < maxEntities; i++)
    {
        if (IsValidEdict(i))
        {
            GetEdictClassname(i, class, sizeof(class));
            if (StrEqual(class, "hostage_entity"))
                AcceptEntityInput(i, "Kill");
        }
    }
}

SetGrenadeState()
{
    new maxGrenadesSameType = 0;
    if (g_iPlayers_MaxEquipment[players_MyWeapon_Incendiary] > maxGrenadesSameType) maxGrenadesSameType = g_iPlayers_MaxEquipment[players_MyWeapon_Incendiary];
    if (g_iPlayers_MaxEquipment[players_MyWeapon_Decoy] > maxGrenadesSameType) maxGrenadesSameType = g_iPlayers_MaxEquipment[players_MyWeapon_Decoy];
    if (g_iPlayers_MaxEquipment[players_MyWeapon_Flash] > maxGrenadesSameType) maxGrenadesSameType = g_iPlayers_MaxEquipment[players_MyWeapon_Flash];
    if (g_iPlayers_MaxEquipment[players_MyWeapon_He] > maxGrenadesSameType) maxGrenadesSameType = g_iPlayers_MaxEquipment[players_MyWeapon_He];
    if (g_iPlayers_MaxEquipment[players_MyWeapon_Smoke] > maxGrenadesSameType) maxGrenadesSameType = g_iPlayers_MaxEquipment[players_MyWeapon_Smoke];
    cvars_SetExternalCvarInt("ammo_grenade_limit_default", maxGrenadesSameType, .backup = true, .keeped = false, .locked = false);
    cvars_SetExternalCvarInt("ammo_grenade_limit_flashbang", g_iPlayers_MaxEquipment[players_MyWeapon_Flash], .backup = true, .keeped = false, .locked = false);
    cvars_SetExternalCvarInt("ammo_grenade_limit_total", g_iPlayers_MaxEquipment[players_MyWeapon_Incendiary] + 
                                                         g_iPlayers_MaxEquipment[players_MyWeapon_Decoy] + 
                                                         g_iPlayers_MaxEquipment[players_MyWeapon_Flash] + 
                                                         g_iPlayers_MaxEquipment[players_MyWeapon_He] +
                                                         g_iPlayers_MaxEquipment[players_MyWeapon_Smoke],
                                                         .backup = true, .keeped = false, .locked = false);
}

SetZeusState()
{
    if (g_iPlayers_MaxEquipment[players_MyWeapon_Tazer] > 0)
        cvars_SetExternalCvarInt("mp_weapons_allow_zeus", 1, .backup = true, .keeped = false, .locked = false);
}

public OnClientConnected(clientIndex)
{
    players_OnClientConnected(clientIndex);
    userMessage_OnClientConnected(clientIndex);
}

public OnClientPutInServer(clientIndex)
{
    SDKHook(clientIndex, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(clientIndex, SDKHook_TraceAttack, OnTraceAttack);
    dhook_OnClientPutInServer(clientIndex);
    players_OnClientPutInServer(clientIndex);
}

public OnClientDisconnect(clientIndex)
{
    menus_OnClientDisconnect(clientIndex);
    players_RemoveClientRagdoll(clientIndex);
    players_OnClientDisconnect(clientIndex);
    userMessage_OnClientDisconnect(clientIndex);
    rankDisplay_OnClientDisconnect(clientIndex);
}

public Hook_OnChickenSpawned(entity)
{
    TeleportEntity(entity, g_vOffWorldPosition, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(entity, "TurnOff");
}

public OnEntityCreated(entity, const String:classname[])
{
    if (g_bConfig_Enabled && (entity > MaxClients) && IsValidEdict(entity))
    {
        if(g_bConfig_RemoveChickens && StrEqual(classname, "chicken"))
            SDKHook(entity, SDKHook_Spawn, Hook_OnChickenSpawned);
        
        else if( StrStartWith(classname, "weapon_") )
        {
            weapons_DeTagEntity(entity);
           
            SDKHook(entity, SDKHook_Spawn, Hook_OnWeaponSpawned);
        }
    }
}

public OnEntityDestroyed(entity)
{
    if (g_bConfig_Enabled && (entity > MaxClients) && IsValidEdict(entity))
    {
        decl String:EntityName[WEAPON_ENTITIES_NAME_SIZE];
        decl weaponId;
        decl client;
        decl team;
        
        GetEdictClassname(entity, EntityName, sizeof(EntityName));
        
        if( StrStartWith(EntityName, "weapon_") && weapons_IsEntityTagged(entity, weaponId, client, _, team) )
        {
            weapons_RemoveUncarried(entity, weaponId);
            weapons_RemoveUser(weaponId, client, team == CS_TEAM_CT);
            weapons_DeTagEntity(entity);
        }
    }
}
