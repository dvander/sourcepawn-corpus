// Comment out to not require semicolons at the end of each line of code.
#pragma semicolon 1

#include <sourcemod>
#include <colors>
#include <multicolors>


#include "thc_rpg/project.inc"
#include "thc_rpg/base/wrappers.inc"

// Project Base includes
#include "thc_rpg/base/versioninfo.inc"
#include "thc_rpg/base/accessmanager.inc"
#include "thc_rpg/base/logmanager.inc"
#include "thc_rpg/base/translationsmanager.inc"
#include "thc_rpg/base/configmanager.inc"
#include "thc_rpg/base/eventmanager.inc"
#include "thc_rpg/base/modulemanager.inc"

// Libraries includes
#include "thc_rpg/libraries/authlib"
#include "thc_rpg/libraries/damagelib"
#include "thc_rpg/libraries/offsetlib"
#include "thc_rpg/libraries/utilities"
#include "thc_rpg/libraries/weaponlib"

// Core includes
#include "thc_rpg/helpers.inc"
#include "thc_rpg/admincmds.inc"
#include "thc_rpg/rpgmenu.inc"
#include "thc_rpg/upgradesystem.inc"
#include "thc_rpg/sql.inc"
#include "thc_rpg/vectors.inc"
#include "thc_rpg/xpsystem.inc"
#include "thc_rpg/effects.inc"
#include "thc_rpg/hooks.inc"

// Module includes
#include "thc_rpg/core.inc"

// health upgrades
#include "thc_rpg/upgrades/health.inc"
#include "thc_rpg/upgrades/medic.inc"
#include "thc_rpg/upgrades/regen_hp.inc"
#include "thc_rpg/upgrades/vampire.inc"

// others
#include "thc_rpg/upgrades/bouncybullets.inc"
#include "thc_rpg/upgrades/damage.inc"
#include "thc_rpg/upgrades/firenade.inc"
#include "thc_rpg/upgrades/frostnade.inc"
#include "thc_rpg/upgrades/firepistol.inc"
#include "thc_rpg/upgrades/frostpistol.inc"
#include "thc_rpg/upgrades/gravity.inc"
#include "thc_rpg/upgrades/icestab.inc"
#include "thc_rpg/upgrades/longjump.inc"
#include "thc_rpg/upgrades/mirrordamage.inc"
#include "thc_rpg/upgrades/poisonsmoke.inc"
#include "thc_rpg/upgrades/positionswap.inc"
#include "thc_rpg/upgrades/regen_ammo.inc"
#include "thc_rpg/upgrades/regen_armor.inc"
#include "thc_rpg/upgrades/regen_grenades.inc"
#include "thc_rpg/upgrades/stealth.inc"

// speed upgrades
#include "thc_rpg/upgrades/speed.inc"
#include "thc_rpg/upgrades/adrenaline.inc"
#include "thc_rpg/upgrades/impulse.inc"
/**
 * Record plugin info.
 */
public Plugin:myinfo =
{
    name = PROJECT_FULLNAME,
    author = PROJECT_AUTHOR,
    description = PROJECT_DESCRIPTION,
    version = PROJECT_VERSION,
    url = PROJECT_URL
};

/**
 * Called before plugin is loaded.
 * 
 * @param myself	Handle to the plugin.
 * @param late		Whether or not the plugin was loaded "late" (after map load).
 * @param error		Error message buffer in case load failed.
 * @param err_max	Maximum number of characters for error message buffer.
 * @return			APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Let plugin load successfully.
    return APLRes_Success;
}

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
    // Forward event to other project base components.
    
    ModuleMgr_OnPluginStart();
    
    #if defined EVENT_MANAGER
        EventMgr_OnPluginStart();
    #endif
    
    #if defined CONFIG_MANAGER
        ConfigMgr_OnPluginStart();
    #endif
    
    #if defined TRANSLATIONS_MANAGER
        TransMgr_OnPluginStart();
    #else
        Project_LoadExtraTranslations(); // Call this to load translations if the translations manager isn't included.
    #endif
    
    #if defined LOG_MANAGER
        LogMgr_OnPluginStart();
    #endif
    
    #if defined ACCESS_MANAGER
        AccessMgr_OnPluginStart();
    #endif
    
    #if defined VERSION_INFO
        VersionInfo_OnPluginStart();
    #endif
    
    // Forward the OnPluginStart event to all modules.
    ForwardOnPluginStart();
    
    // All modules should be registered by this point!
    
    #if defined EVENT_MANAGER
        // Forward the OnEventsRegister to all modules.
        EventMgr_Forward(g_EvOnEventsRegister, g_CommonEventData1, 0, 0, g_CommonDataType1);

        // Forward the OnEventsReady to all modules.
        EventMgr_Forward(g_EvOnEventsReady, g_CommonEventData1, 0, 0, g_CommonDataType1);

        // Forward the OnAllModulesLoaded to all modules.
        EventMgr_Forward(g_EvOnAllModulesLoaded, g_CommonEventData1, 0, 0, g_CommonDataType1);
    #endif	
}

/**
 * Plugin is ending.
 */
public OnPluginEnd()
{
    // Unload in reverse order of loading.
    
    #if defined EVENT_MANAGER
        // Forward event to all modules.
        EventMgr_Forward(g_EvOnPluginEnd, g_CommonEventData1, 0, 0, g_CommonDataType1);
    #endif
    
    // Forward event to other project base components.
    
    #if defined VERSION_INFO
        VersionInfo_OnPluginEnd();
    #endif
    
    #if defined ACCESS_MANAGER
        AccessMgr_OnPluginEnd();
    #endif
    
    #if defined LOG_MANAGER
        LogMgr_OnPluginEnd();
    #endif
    
    #if defined TRANSLATIONS_MANAGER
        TransMgr_OnPluginEnd();
    #endif
    
    #if defined CONFIG_MANAGER
        ConfigMgr_OnPluginEnd();
    #endif
    
    #if defined EVENT_MANAGER
        EventMgr_OnPluginEnd();
    #endif
    
    ModuleMgr_OnPluginEnd();
}
