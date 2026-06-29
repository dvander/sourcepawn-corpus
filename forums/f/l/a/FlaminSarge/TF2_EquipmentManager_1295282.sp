// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1                  // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>
#include <colors>
#include <attachables>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
// ---- Plugin-related constants ---------------------------------------------------
#define PLUGIN_NAME              "[TF2] Equipment Manager"
#define PLUGIN_AUTHOR            "Damizean"
#define PLUGIN_VERSION           "1.1.8.2"
#define PLUGIN_CONTACT           "elgigantedeyeso@gmail.com"
#define CVAR_FLAGS               FCVAR_PLUGIN|FCVAR_NOTIFY

#define DEBUG                    // Uncomment this for debug.information

// ---- Items management -----------------------------------------------------------
#define MAX_ITEMS                256
#define MAX_SLOTS                2
#define MAX_LENGTH               256

// ---- Wearables flags ------------------------------------------------------------
#define PLAYER_ADMIN             (1 << 0)        // Player is admin.
#define PLAYER_OVERRIDE          (1 << 1)        // Player is overriding the restrictions of the items.
#define PLAYER_LOCK              (1 << 2)        // Player has it's equipment locked

#define FLAG_ADMIN_ONLY          (1 << 0)        // Only admins can use this item.
#define FLAG_USER_DEFAULT        (1 << 1)        // This is the forced default for users.
#define FLAG_ADMIN_DEFAULT       (1 << 2)        // This is the forced default for admins.
#define FLAG_HIDDEN              (1 << 3)        // Hidden from list
#define FLAG_INVISIBLE             (1 << 4)      // Invisible! INVISIBLE!
#define FLAG_HIDE_SCOUT_HAT        (1 << 5)
#define FLAG_HIDE_SCOUT_HEADPHONES (1 << 6)
#define FLAG_HIDE_HEAVY_HANDS      (1 << 7)
#define FLAG_HIDE_ENGINEER_HELMET  (1 << 8)
#define FLAG_SHOW_SNIPER_QUIVER    (1 << 9)
#define FLAG_HIDE_SNIPER_HAT       (1 << 10)
#define FLAG_HIDE_SOLDIER_ROCKET   (1 << 11)
#define FLAG_HIDE_SOLDIER_HELMET   (1 << 12)
#define FLAG_REQUIRES_STEAMID      (1 << 13)

#define CLASS_SCOUT              (1 << 0)
#define CLASS_SNIPER             (1 << 1)
#define CLASS_SOLDIER            (1 << 2)
#define CLASS_DEMOMAN            (1 << 3)
#define CLASS_MEDIC              (1 << 4)
#define CLASS_HEAVY              (1 << 5)
#define CLASS_PYRO               (1 << 6)
#define CLASS_SPY                (1 << 7)
#define CLASS_ENGINEER           (1 << 8)
#define CLASS_ALL                0b111111111

#define TEAM_RED                 (1 << 0)
#define TEAM_BLU                 (1 << 1)

// ---- Engine flags ---------------------------------------------------------------
#define EF_BONEMERGE            (1 << 0)
#define EF_BRIGHTLIGHT          (1 << 1)
#define EF_DIMLIGHT             (1 << 2)
#define EF_NOINTERP             (1 << 3)
#define EF_NOSHADOW             (1 << 4)
#define EF_NODRAW               (1 << 5)
#define EF_NORECEIVESHADOW      (1 << 6)
#define EF_BONEMERGE_FASTCULL   (1 << 7)
#define EF_ITEM_BLINK           (1 << 8)
#define EF_PARENT_ANIMATES      (1 << 9)

// ---- Game bodygroups ------------------------------------------------------------
#define BODYGROUP_SCOUT_HAT        (1 << 0)
#define BODYGROUP_SCOUT_HEADPHONES (1 << 1)
#define BODYGROUP_HEAVY_HANDS      (1 << 0)
#define BODYGROUP_ENGINEER_HELMET  (1 << 0)
#define BODYGROUP_SNIPER_QUIVER    (1 << 0)
#define BODYGROUP_SNIPER_HAT       (1 << 1)
#define BODYGROUP_SOLDIER_ROCKET   (1 << 0)
#define BODYGROUP_SOLDIER_HELMET   (1 << 1)
#define BODYGROUP_SOLDIER_MEDAL    (1 << 2)

// *********************************************************************************
// VARIABLES
// *********************************************************************************

// ---- Player variables -----------------------------------------------------------
new g_iPlayerItem[MAXPLAYERS+1][MAX_SLOTS];
new g_iPlayerOwnEntity[MAXPLAYERS+1][MAX_SLOTS];
new g_iPlayerOthersEntity[MAXPLAYERS+1][MAX_SLOTS];
new g_iPlayerFlags[MAXPLAYERS+1];
new g_iPlayerBGroups[MAXPLAYERS+1];

// ---- Item variables -------------------------------------------------------------
//new g_iSlotsCount;
//new String:g_strSlots[MAX_SLOTS][MAX_LENGTH];            // In a future, perhaps?

new g_iItemCount;
new String:g_strItemName[MAX_ITEMS][MAX_LENGTH];
new String:g_strItemModel[MAX_ITEMS][MAX_LENGTH];
new g_iItemFlags[MAX_ITEMS];
new g_iItemClasses[MAX_ITEMS];
new g_iItemSlot[MAX_ITEMS];
new g_iItemTeams[MAX_ITEMS];
new g_iItemIndex[MAX_ITEMS];
new String:g_strItemSteamID[MAX_ITEMS][2048];

// --- SDK variables ---------------------------------------------------------------
new bool:g_bSdkStarted = false;
new Handle:g_hSdkEquipWearable;
new Handle:g_hSdkRemoveWearable;

// ---- Cvars ----------------------------------------------------------------------
new Handle:g_hCvarVersion              = INVALID_HANDLE;
new Handle:g_hCvarAdminOnly            = INVALID_HANDLE;
new Handle:g_hCvarAdminFlags           = INVALID_HANDLE;
new Handle:g_hCvarAdminOverride        = INVALID_HANDLE;
new Handle:g_hCvarAnnounce             = INVALID_HANDLE;
new Handle:g_hCvarAnnouncePlugin       = INVALID_HANDLE;
new Handle:g_hCvarForceDefaultOnUsers  = INVALID_HANDLE;
new Handle:g_hCvarForceDefaultOnAdmins = INVALID_HANDLE;
new Handle:g_hCvarDelayOnSpawn         = INVALID_HANDLE;
new Handle:g_hCvarBlockTriggers        = INVALID_HANDLE;

// ---- Others ---------------------------------------------------------------------
new Handle:g_hCookies[10][MAX_SLOTS];

new bool:g_bAdminOnly      = false;
new bool:g_bAdminOverride  = false;
new bool:g_bAnnounce       = false;
new bool:g_bAnnouncePlugin = false;
new bool:g_bForceUsers     = false;
new bool:g_bForceAdmins    = false;
new bool:g_bBlockTriggers  = false;
new Float:g_fSpawnDelay    = 0.0;
new String:g_strAdminFlags[32];

new Handle:g_hMenuMain   = INVALID_HANDLE;
new Handle:g_hMenuEquip  = INVALID_HANDLE;
new Handle:g_hMenuRemove = INVALID_HANDLE;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_NAME,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

// *********************************************************************************
// METHODS
// *********************************************************************************

// =====[ BASIC PLUGIN MANAGEMENT ]========================================

// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
// At plugin start, create and hook all the proper events to manage the
// wearable items.
// ------------------------------------------------------------------------
public OnPluginStart()
{    
    // Plugin is TF2 only, so make sure it's ran on TF
    decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
    if (!StrEqual(strModName, "tf")) SetFailState("This plugin is TF2 only.");
    
    // Create plugin cvars
    g_hCvarVersion              = CreateConVar("tf_equipment_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY);
    g_hCvarAdminFlags           = CreateConVar("tf_equipment_admin_flags",     "b",   "Only users with one of these flags are considered administrators.", CVAR_FLAGS);
    g_hCvarAdminOnly            = CreateConVar("tf_equipment_admin",           "0",   "Only administrators can use the equipment.",                        CVAR_FLAGS);
    g_hCvarAdminOverride        = CreateConVar("tf_equipment_admin_override",  "0",   "Administrators can override the equipment restrictions.",           CVAR_FLAGS);
    g_hCvarAnnounce             = CreateConVar("tf_equipment_announce",        "1",   "Announces usage and tips about equipable items.",                   CVAR_FLAGS);
    g_hCvarAnnouncePlugin       = CreateConVar("tf_equipment_announce_plugin", "1",   "Announces information of the plugin when joining.",                 CVAR_FLAGS);
    g_hCvarForceDefaultOnUsers  = CreateConVar("tf_equipment_force_users",     "0",   "Forces the default equipment for common users.",                    CVAR_FLAGS);
    g_hCvarForceDefaultOnAdmins = CreateConVar("tf_equipment_force_admins",    "0",   "Forces the default equipment for admin users.",                     CVAR_FLAGS);
    g_hCvarDelayOnSpawn         = CreateConVar("tf_equipment_delayonspawn",    "0.1", "Amount of time to wait to re-equip items after spawn.",             CVAR_FLAGS);
    g_hCvarBlockTriggers        = CreateConVar("tf_equipment_blocktriggers",   "1",   "Blocks the triggers so they won't spam on the chat.",               CVAR_FLAGS);
    
    // Create cookies
    g_hCookies[_:TFClass_DemoMan][0]  = RegClientCookie("tf_equipment_demoman_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_DemoMan][1]  = RegClientCookie("tf_equipment_demoman_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Engineer][0] = RegClientCookie("tf_equipment_engineer_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Engineer][1] = RegClientCookie("tf_equipment_engineer_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Heavy][0]    = RegClientCookie("tf_equipment_heavy_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Heavy][1]    = RegClientCookie("tf_equipment_heavy_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Medic][0]    = RegClientCookie("tf_equipment_medic_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Medic][1]    = RegClientCookie("tf_equipment_medic_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Pyro][0]     = RegClientCookie("tf_equipment_pyro_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Pyro][1]     = RegClientCookie("tf_equipment_pyro_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Scout][0]    = RegClientCookie("tf_equipment_scout_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Scout][1]    = RegClientCookie("tf_equipment_scout_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Sniper][0]   = RegClientCookie("tf_equipment_sniper_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Sniper][1]   = RegClientCookie("tf_equipment_sniper_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Soldier][0]  = RegClientCookie("tf_equipment_soldier_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Soldier][1]  = RegClientCookie("tf_equipment_soldier_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Spy][0]      = RegClientCookie("tf_equipment_spy_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Spy][1]      = RegClientCookie("tf_equipment_spy_1", "", CookieAccess_Public);
    
    // Startup extended stocks
    TF2_SdkStartup();
    
    // Register console commands
    RegConsoleCmd("tf_equipment",        Cmd_Menu, "Shows the equipment manager menu");
    RegConsoleCmd("equipment",           Cmd_Menu, "Shows the equipment manager menu");
    RegConsoleCmd("equip",               Cmd_Menu, "Shows the equipment manager menu");
    RegConsoleCmd("em",                  Cmd_Menu, "Shows the equipment manager menu");
    RegConsoleCmd("hats",                Cmd_Menu, "Shows the equipment manager menu");
    RegAdminCmd("tf_equipment_equip",    Cmd_EquipItem,         ADMFLAG_CHEATS, "Forces to equip an item onto a client.");
    RegAdminCmd("tf_equipment_remove",   Cmd_RemoveItem,        ADMFLAG_CHEATS, "Forces to remove an item on the client.");
    RegAdminCmd("tf_equipment_lock",     Cmd_LockEquipment,     ADMFLAG_CHEATS, "Locks/unlocks the client's equipment so it can't be changed.");
    RegAdminCmd("tf_equipment_override", Cmd_OverrideEquipment, ADMFLAG_CHEATS, "Enables restriction overriding for the client.");
    RegAdminCmd("tf_equipment_reload",   Cmd_Reload,            ADMFLAG_CHEATS, "Reparses the items file and rebuilds the equipment list.");
    RegConsoleCmd("say", Cmd_BlockTriggers);
    RegConsoleCmd("say_team", Cmd_BlockTriggers);
    
    // Hook the proper events and cvars
    HookEvent("post_inventory_application", Event_EquipItem,  EventHookMode_Post);
    HookEvent("player_death", Event_RemoveItem,  EventHookMode_Post);
    HookEvent("player_changeclass", Event_RemoveItem,  EventHookMode_Pre);
    HookConVarChange(g_hCvarAdminFlags,           Cvar_UpdateCfg);
    HookConVarChange(g_hCvarAdminOnly,            Cvar_UpdateCfg);
    HookConVarChange(g_hCvarAdminOverride,        Cvar_UpdateCfg);
    HookConVarChange(g_hCvarAnnounce,             Cvar_UpdateCfg);
    HookConVarChange(g_hCvarAnnouncePlugin,       Cvar_UpdateCfg);
    HookConVarChange(g_hCvarForceDefaultOnUsers,  Cvar_UpdateCfg);
    HookConVarChange(g_hCvarForceDefaultOnAdmins, Cvar_UpdateCfg);
    HookConVarChange(g_hCvarDelayOnSpawn,         Cvar_UpdateCfg);
    
    // Load translations for this plugin
    LoadTranslations("common.phrases");
    LoadTranslations("TF2_EquipmentManager");
    
    // Execute configs.
    AutoExecConfig(true, "TF2_EquipmentManager");
    
    // Create announcement timer.
    CreateTimer(900.0, Timer_Announce, _, TIMER_REPEAT);
}

// ------------------------------------------------------------------------
// OnPluginEnd()
// ------------------------------------------------------------------------
public OnPluginEnd()
{
    // Destroy all entities for everyone, if possible.
    for (new iClient=1; iClient<=MaxClients; iClient++)
    {
        for (new iSlot=0; iSlot<MAX_SLOTS; iSlot++)
            Item_Remove(iClient, iSlot, false);
    }
}

// ------------------------------------------------------------------------
// OnConfigsExecuted()
// ------------------------------------------------------------------------
public OnConfigsExecuted()
{
    // Determine if the version of the cfg is the correct one
    new String:strVersion[16]; GetConVarString(g_hCvarVersion, strVersion, sizeof(strVersion));
    if (StrEqual(strVersion, PLUGIN_VERSION) == false)
    {
        LogMessage("WARNING: Your config file for \"%s\" seems to be out-dated! This may lead to conflicts with \
        the plugin and non-working configs. Fix this by deleting your current config and restart your \
        server. It'll generate a new config with the default Cfg.", PLUGIN_NAME);
    }
    
    // Force Cfg update
    Cvar_UpdateCfg(INVALID_HANDLE, "", "");
}

// ------------------------------------------------------------------------
// UpdateCfg()
// ------------------------------------------------------------------------
public Cvar_UpdateCfg(Handle:hHandle, String:strOldVal[], String:strNewVal[])
{
    g_bAdminOnly      = GetConVarBool(g_hCvarAdminOnly);
    g_bAdminOverride  = GetConVarBool(g_hCvarAdminOverride);
    g_bAnnounce       = GetConVarBool(g_hCvarAnnounce);
    g_bAnnouncePlugin = GetConVarBool(g_hCvarAnnouncePlugin);
    g_bForceUsers     = GetConVarBool(g_hCvarForceDefaultOnUsers);
    g_bForceAdmins    = GetConVarBool(g_hCvarForceDefaultOnAdmins);
    g_fSpawnDelay     = GetConVarFloat(g_hCvarDelayOnSpawn);
    g_bBlockTriggers  = GetConVarBool(g_hCvarBlockTriggers);
    GetConVarString(g_hCvarAdminFlags, g_strAdminFlags, sizeof(g_strAdminFlags));
}

// ------------------------------------------------------------------------
// OnMapStart()
// ------------------------------------------------------------------------
// At map start, make sure to reset all the values for all the clients
// to the default. Also, reparse the items list and rebuild the
// basic menus.
// ------------------------------------------------------------------------
public OnMapStart()
{
    // Reset player's slots
    for (new iClient=1; iClient<=MaxClients; iClient++)
    {
        g_iPlayerFlags[iClient] = 0;
        
        for (new iSlot=0; iSlot<MAX_SLOTS; iSlot++)
        {
            g_iPlayerItem[iClient][iSlot] = -1;
            g_iPlayerOwnEntity[iClient][iSlot] = -1;
            g_iPlayerOthersEntity[iClient][iSlot] = -1;
        }
    }
    
    // Reparse and re-build the menus
    Item_ParseList();
    g_hMenuMain   = Menu_BuildMain();
    g_hMenuEquip  = Menu_BuildSlots("EquipItem");
    g_hMenuRemove = Menu_BuildSlots("RemoveSlot");
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
// At map end, destroy all the built menus.
// ------------------------------------------------------------------------
public OnMapEnd()
{
    // Destroy menus
    if (g_hMenuMain   != INVALID_HANDLE) { CloseHandle(g_hMenuMain);   g_hMenuMain   = INVALID_HANDLE; }
    if (g_hMenuEquip  != INVALID_HANDLE) { CloseHandle(g_hMenuEquip);  g_hMenuEquip  = INVALID_HANDLE; }
    if (g_hMenuRemove != INVALID_HANDLE) { CloseHandle(g_hMenuRemove); g_hMenuRemove = INVALID_HANDLE; }
}

// ------------------------------------------------------------------------
// OnClientPutInServer()
// ------------------------------------------------------------------------
// When a client is put in server, greet the player and show off information
// about the plugin.
// ------------------------------------------------------------------------
public OnClientPutInServer(iClient)
{
    if (g_bAnnouncePlugin)
    {
        CreateTimer(30.0, Timer_Welcome, iClient, TIMER_FLAG_NO_MAPCHANGE);
    }
}

// ------------------------------------------------------------------------
// OnClientPostAdminCheck()
// ------------------------------------------------------------------------
// Identify the client that just connected, checking if at least one of the
// flags listed in the cvar.
// ------------------------------------------------------------------------
public OnClientPostAdminCheck(iClient)
{
    // Retrieve needed flags and determine if the player is an admin.
    new ibFlags = ReadFlagString(g_strAdminFlags);
    
    // Test and setup flag if so.
    if (GetUserFlagBits(iClient) & ibFlags)      g_iPlayerFlags[iClient] |= PLAYER_ADMIN;
    if (GetUserFlagBits(iClient) & ADMFLAG_ROOT) g_iPlayerFlags[iClient] |= PLAYER_ADMIN;
}

// ------------------------------------------------------------------------
// Event_EquipItem()
// ------------------------------------------------------------------------
// On the player spawn (or any other event that requires re-equipment) we
// requip the items the player had selected. If none are found, we also check
// if we should force one upon the player.
// ------------------------------------------------------------------------
public Event_EquipItem(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    CreateTimer(g_fSpawnDelay, Timer_EquipItem, GetClientOfUserId(GetEventInt(hEvent, "userid")), TIMER_FLAG_NO_MAPCHANGE);
}
public Action:Timer_EquipItem(Handle:hTimer, any:iClient)
{
    if (!IsValidClient(iClient)) return Plugin_Handled;
    if (!IsPlayerAlive(iClient)) return Plugin_Handled;
    
    // Retrieve current player bodygroups status.
    g_iPlayerBGroups[iClient] = GetEntProp(iClient, Prop_Send, "m_nBody");
    
    // Iterate through each slot
    for (new iSlot=0; iSlot<MAX_SLOTS; iSlot++)
    {
        // Retrieve the proper cookie value
        g_iPlayerItem[iClient][iSlot] = Item_RetrieveSlotCookie(iClient, iSlot);
        
        // Determine if the hats are still valid for the
        // client.
        if (!Item_IsWearable(iClient, g_iPlayerItem[iClient][iSlot]))
        {
            Item_Remove(iClient, iSlot);
            g_iPlayerItem[iClient][iSlot] = Item_FindDefaultItem(iClient, iSlot);
        }
        
        // Equip the player with the selected item.
        Item_Equip(iClient, g_iPlayerItem[iClient][iSlot]);
    }    
    
    return Plugin_Handled;
}


// ------------------------------------------------------------------------
// Event_RemoveItem()
// ------------------------------------------------------------------------
// On player's death destroy the entity that's meant to be visible for the
// other players.
// ------------------------------------------------------------------------
public Event_RemoveItem(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    for (new iSlot=0; iSlot<MAX_SLOTS; iSlot++) Item_Remove(iClient, iSlot, false, true);
}

// ------------------------------------------------------------------------
// OnClientDisconnect()
// ------------------------------------------------------------------------
// When the client disconnects, remove it's equipped items and reset all
// the flags.
// ------------------------------------------------------------------------
public OnClientDisconnect(iClient)
{
    for (new i=0; i<MAX_SLOTS; i++) Item_Remove(iClient, i, false);
    g_iPlayerFlags[iClient] = 0;
}

// ------------------------------------------------------------------------
// Item_Equip
// ------------------------------------------------------------------------
// Equip the desired item onto a client.
// ------------------------------------------------------------------------
Item_Equip(iClient, iItem)
{
    // Assert if the player is alive.
    if (!IsValidClient(iClient)) return;
    if (!Item_IsWearable(iClient, iItem)) return;
    
    // Retrieve the information of the item and the current item
    new iSlot                  = g_iItemSlot[iItem];
    new iCurrentItem           = g_iPlayerItem[iClient][iSlot];
    new iCurrentEntity         = g_iPlayerOwnEntity[iClient][iSlot];
    new iCurrentOtherEntity    = g_iPlayerOthersEntity[iClient][iSlot];
    new bool:bFullRegeneration = !(TF2_IsEntityWearable(iCurrentEntity) && TF2_IsEntityWearable(iCurrentOtherEntity));
    
    // Depending on if the entities are valid, generate new entities
    // or just change the current model.
    if (bFullRegeneration == true)
    {           
        // If the player's alive...
        if (IsPlayerAlive(iClient)) 
        {
            new iEntity = -1;
            new iEntityOthers = -1;
            
            // Remove the previous entities if it's possible.
            Item_Remove(iClient, iSlot, false);
            
            // If we're about to equip an invisible item, there's no need
            // to generate entities.
            if (!(g_iItemFlags[g_iItemCount] & FLAG_INVISIBLE))
            {
                // Create owner entity.
                iEntity = TF2_SpawnWearable(iClient, g_iItemIndex[iItem]);
                if (iEntity != -1)
                {
                    TF2_EquipWearable(iClient, iEntity);
                    SetEntityModel(iEntity, g_strItemModel[iItem]);
                }
                else
                {
                    LogError("Error while creating owner entity (Client: %N / Hat Id: %i).", iClient, iItem);
                }
                
                // Create the entity for other players to see.
                iEntityOthers = Attachable_CreateAttachable(iClient);
                if (iEntityOthers != -1)
                {
                    SetEntityModel(iEntityOthers, g_strItemModel[iItem]);
                }
                else
                {
                    LogError("Error while creating external entity (Client: %N / Hat Id: %i).", iClient, iItem);
                }
            }
            
            // Change player's item index
            g_iPlayerItem[iClient][iSlot] = iItem;
            
            // Change the visible body parts.
            //SetEntProp(iClient, Prop_Send, "m_nBody", g_iPlayerBGroups[iClient] | Item_DetermineBodyGroups(iClient));
            SetEntProp(iClient, Prop_Send, "m_nBody", CalculateBodyGroups(iClient));
            
            // Done. Assign the proper entities.
            iCurrentEntity = g_iPlayerOwnEntity[iClient][iSlot] = iEntity;
            iCurrentOtherEntity = g_iPlayerOthersEntity[iClient][iSlot] = iEntityOthers;
        }
    }
    else if (iItem != iCurrentItem)
    {
        // If the new item is going to be invisible, remove the currently
        // equipped entities.
        if (g_iItemFlags[g_iItemCount] & FLAG_INVISIBLE)
        {
            Item_Remove(iClient, iSlot, false);
            g_iPlayerItem[iClient][iSlot] = iItem;
        }
        else
        {
            SetEntProp(iCurrentEntity, Prop_Send, "m_iItemDefinitionIndex", g_iItemIndex[iItem]);
            SetEntityModel(iCurrentEntity, g_strItemModel[iItem]);
            SetEntityModel(iCurrentOtherEntity, g_strItemModel[iItem]);
        }
            
        // Change player's item index
        g_iPlayerItem[iClient][iSlot] = iItem;
        
        // Change the visible body parts.
        //SetEntProp(iClient, Prop_Send, "m_nBody", g_iPlayerBGroups[iClient] | Item_DetermineBodyGroups(iClient));
        SetEntProp(iClient, Prop_Send, "m_nBody", CalculateBodyGroups(iClient));
    }
}

// ------------------------------------------------------------------------
// Item_Remove
// ------------------------------------------------------------------------
// Remove the item equipped at the selected slot.
// ------------------------------------------------------------------------
Item_Remove(iClient, iSlot, bool:bCheck = true, bool:bDestroyOthersEntity = false)
{
    // Assert if the player is alive.
    if (bCheck == true && !IsValidClient(iClient)) return;
    if (g_iPlayerItem[iClient][iSlot] == -1) return;
    
    // Destroy the owner entity.
    if (bDestroyOthersEntity == false)
    {
        if (TF2_IsEntityWearable(g_iPlayerOwnEntity[iClient][iSlot]))
        {
            TF2_RemoveWearable(iClient, g_iPlayerOwnEntity[iClient][iSlot]);
            //SetEntProp(iClient, Prop_Send, "m_nBody", g_iPlayerBGroups[iClient] | Item_DetermineBodyGroups(iClient));
        }
        
        g_iPlayerItem[iClient][iSlot] = -1;
        g_iPlayerOwnEntity[iClient][iSlot] = -1;
    }
    
    // Destroy the others entity.
    if (TF2_IsEntityWearable(g_iPlayerOthersEntity[iClient][iSlot]))
    {
        Attachable_UnhookEntity(g_iPlayerOthersEntity[iClient][iSlot]);
        RemoveEdict(g_iPlayerOthersEntity[iClient][iSlot]);
    }
    g_iPlayerOthersEntity[iClient][iSlot] = -1;
    
    // Recalculate body groups
    SetEntProp(iClient, Prop_Send, "m_nBody", CalculateBodyGroups(iClient));
}

// ------------------------------------------------------------------------
// Item_ParseList()
// ------------------------------------------------------------------------
// Parse the items list and precache all the needed models through the
// dependencies file.
// ------------------------------------------------------------------------
Item_ParseList()
{
    // Parse the objects list key values text to acquire all the possible
    // wearable items.
    new Handle:kvItemList = CreateKeyValues("TF2_EquipmentManager");
    new Handle:hStream = INVALID_HANDLE;
    new String:strLocation[256];
    new String:strDependencies[256];
    new String:strLine[256];
    
    // Load the key files.
    BuildPath(Path_SM, strLocation, 256, "configs/TF2_ItemList.cfg");
    FileToKeyValues(kvItemList, strLocation);
    
    // Check if the parsed values are correct
    if (!KvGotoFirstSubKey(kvItemList)) { SetFailState("Error, can't read file containing the item list : %s", strLocation); return; }
    g_iItemCount = 0;
    
    #if defined DEBUG
    LogMessage("Parsing item list {");
    #endif
    
    // Iterate through all keys.
    do
    {
        // Retrieve section name, wich is pretty much the name of the wearable. Also, parse the model.
        KvGetSectionName(kvItemList,       g_strItemName[g_iItemCount],  MAX_LENGTH);
        KvGetString(kvItemList, "model",   g_strItemModel[g_iItemCount], MAX_LENGTH);
        KvGetString(kvItemList, "index",   strLine, sizeof(strLine)); g_iItemIndex[g_iItemCount]   = StringToInt(strLine);
        KvGetString(kvItemList, "flags",   strLine, sizeof(strLine)); g_iItemFlags[g_iItemCount]   = Item_ParseFlags(strLine);
        KvGetString(kvItemList, "classes", strLine, sizeof(strLine)); g_iItemClasses[g_iItemCount] = Item_ParseClasses(strLine);
        KvGetString(kvItemList, "teams",   strLine, sizeof(strLine)); g_iItemTeams[g_iItemCount]   = Item_ParseTeams(strLine);
        KvGetString(kvItemList, "slot",    strLine, sizeof(strLine)); g_iItemSlot[g_iItemCount]    = StringToInt(strLine)-1;
        KvGetString(kvItemList, "steamid", g_strItemSteamID[g_iItemCount], 2048);
        if (strlen(g_strItemSteamID[g_iItemCount]) != 0)
            g_iItemFlags[g_iItemCount] |= FLAG_REQUIRES_STEAMID;
        
        #if defined DEBUG
        LogMessage("    Found item -> %s", g_strItemName[g_iItemCount]);
        LogMessage("        - Model : \"%s\"", g_strItemModel[g_iItemCount]);
        LogMessage("        - Index : %i", g_iItemIndex[g_iItemCount]);
        LogMessage("        - Flags : %b", g_iItemFlags[g_iItemCount]);
        LogMessage("        - Class : %08b", g_iItemClasses[g_iItemCount]);
        LogMessage("        - Teams : %02b", g_iItemTeams[g_iItemCount]);
        LogMessage("        - Slot  : %i", g_iItemSlot[g_iItemCount]+1);
        #endif
        
        // Assert the different parameters passed
        if (g_iItemIndex[g_iItemCount] == 0)
        {
            LogMessage("        @ERROR : Item index should be set to one of the hat index values. Please refer to the config file table.");
            continue;
        }
        if (g_iItemSlot[g_iItemCount] < 0 || g_iItemSlot[g_iItemCount] >= MAX_SLOTS)
        {
            LogMessage("        @ERROR : Item slot should be within valid ranges (1 to %i). Please change it to a correct slot.", MAX_SLOTS);
            continue;
        }
        
        // If it's invisible, skip
        if (!(g_iItemFlags[g_iItemCount] & FLAG_INVISIBLE))
        {
            // Check if model exists, so we can prevent crashes.
            if (!FileExists(g_strItemModel[g_iItemCount], true))
            {
                LogMessage("        @ERROR : File \"%s\" not found. Excluding from list.", g_strItemModel[g_iItemCount]);
                continue;
            }
            
            // Check if the admin wants to use a Valve model.
            if (StrContains(g_strItemModel[g_iItemCount], "models/player/items", true) != -1)
            {
                LogMessage("        @ERROR : Trying to access an official Valve model file (\"%s\").", g_strItemModel[g_iItemCount]);
                LogMessage("                 Valve strictly disapproves the use of the official hats, so we do not support them. Excluding from list.");
                continue;
            }
            
            // Retrieve dependencies file and open if possible.
            Format(strDependencies, sizeof(strDependencies), "%s.dep", g_strItemModel[g_iItemCount]);
            if (FileExists(strDependencies))
            {
                #if defined DEBUG
                LogMessage("        - Found dependencies file. Trying to read.");
                #endif
                
                // Open stream, if possible
                hStream = OpenFile(strDependencies, "r");
                if (hStream == INVALID_HANDLE) { LogMessage("Error, can't read file containing model dependencies."); return; }
                
                while(!IsEndOfFile(hStream))
                {
                    // Try to read line. If EOF has been hit, exit.
                    ReadFileLine(hStream, strLine, sizeof(strLine));
                    
                    // Cleanup line
                    CleanString(strLine);
                    
                    #if defined DEBUG
                    LogMessage("            + File: \"%s\"", strLine);
                    #endif
                    // If file exists...
                    if (!FileExists(strLine, true))
                    {
                        continue;
                    }
                    
                    // Precache depending on type, and add to download table
                    if (StrContains(strLine, ".vmt", false) != -1)      PrecacheDecal(strLine, true);
                    else if (StrContains(strLine, ".mdl", false) != -1) PrecacheModel(strLine, true);
                    else if (StrContains(strLine, ".pcf", false) != -1) PrecacheGeneric(strLine, true);
                    AddFileToDownloadsTable(strLine);
                }
                
                // Close file
                CloseHandle(hStream);
            }
            PrecacheModel(g_strItemModel[g_iItemCount], true);
        }
        
        // Go to next.
        g_iItemCount++;
    }
    while (KvGotoNextKey(kvItemList));
        
    CloseHandle(kvItemList);    
    #if defined DEBUG
    LogMessage("}");
    #endif
}

// ------------------------------------------------------------------------
// Item_ParseFlags()
// ------------------------------------------------------------------------
// Parses the items flags, duh.
// ------------------------------------------------------------------------
Item_ParseFlags(String:strFlags[])
{
    new Flags;
    if (StrContains(strFlags, "USER_DEFAULT", false)  != -1) Flags |= FLAG_USER_DEFAULT;
    if (StrContains(strFlags, "ADMIN_DEFAULT", false) != -1) Flags |= FLAG_ADMIN_DEFAULT;
    if (StrContains(strFlags, "ADMIN_ONLY", false)    != -1) Flags |= FLAG_ADMIN_ONLY;
    if (StrContains(strFlags, "HIDDEN", false)        != -1) Flags |= FLAG_HIDDEN;
    if (StrContains(strFlags, "INVISIBLE", false)     != -1) Flags |= FLAG_INVISIBLE;
    if (StrContains(strFlags, "HIDE_SCOUT_HAT", false)         != -1) Flags |= FLAG_HIDE_SCOUT_HAT;
    if (StrContains(strFlags, "HIDE_SCOUT_HEADPHONES", false)  != -1) Flags |= FLAG_HIDE_SCOUT_HEADPHONES;
    if (StrContains(strFlags, "HIDE_HEAVY_HANDS", false)       != -1) Flags |= FLAG_HIDE_HEAVY_HANDS;    
    if (StrContains(strFlags, "HIDE_ENGINEER_HELMET", false)   != -1) Flags |= FLAG_HIDE_ENGINEER_HELMET;
    //if (StrContains(strFlags, "HIDE_SNIPER_QUIVER", false)     != -1) Flags |= FLAG_HIDE_SNIPER_QUIVER;
    if (StrContains(strFlags, "HIDE_SNIPER_HAT", false)        != -1) Flags |= FLAG_HIDE_SNIPER_HAT;     
    //if (StrContains(strFlags, "HIDE_SOLDIER_ROCKET", false)    != -1) Flags |= FLAG_HIDE_SOLDIER_ROCKET;
    if (StrContains(strFlags, "HIDE_SOLDIER_HELMET", false)    != -1) Flags |= FLAG_HIDE_SOLDIER_HELMET;
    
    return Flags;
}

// ------------------------------------------------------------------------
// Item_ParseClasses()
// ------------------------------------------------------------------------
// Parses the wearable classes, duh.
// ------------------------------------------------------------------------
Item_ParseClasses(String:strClasses[])
{
    new iFlags;
    if (StrContains(strClasses, "SCOUT", false)    != -1) iFlags |= CLASS_SCOUT;
    if (StrContains(strClasses, "SNIPER", false)   != -1) iFlags |= CLASS_SNIPER;
    if (StrContains(strClasses, "SOLDIER", false)  != -1) iFlags |= CLASS_SOLDIER;
    if (StrContains(strClasses, "DEMOMAN", false)  != -1) iFlags |= CLASS_DEMOMAN;
    if (StrContains(strClasses, "MEDIC", false)    != -1) iFlags |= CLASS_MEDIC;
    if (StrContains(strClasses, "HEAVY", false)    != -1) iFlags |= CLASS_HEAVY;
    if (StrContains(strClasses, "PYRO", false)     != -1) iFlags |= CLASS_PYRO;
    if (StrContains(strClasses, "SPY", false)      != -1) iFlags |= CLASS_SPY;
    if (StrContains(strClasses, "ENGINEER", false) != -1) iFlags |= CLASS_ENGINEER;
    if (StrContains(strClasses, "ALL", false)      != -1) iFlags |= CLASS_ALL;
    
    return iFlags;
}
// ------------------------------------------------------------------------
// Item_ParseTeams()
// ------------------------------------------------------------------------
// Parses the wearable teams, duh.
// ------------------------------------------------------------------------
Item_ParseTeams(String:strTeams[])
{
    new iFlags;
    if (StrContains(strTeams, "RED", false) != -1 ) iFlags |= TEAM_RED;
    if (StrContains(strTeams, "BLUE", false) != -1) iFlags |= TEAM_BLU;
    if (StrContains(strTeams, "ALL", false) != -1)  iFlags |= TEAM_RED|TEAM_BLU;
    
    return iFlags;
}

// ------------------------------------------------------------------------
// Item_IsWearable()
// ------------------------------------------------------------------------
// Determines if the selected item is wearable by a player (that means, 
// the player has the enough admin level, is the correct class, etc. These
// Cfg can be overriden if the player has the override flag, though.
// ------------------------------------------------------------------------
Item_IsWearable(iClient, Item)
{
    // If the selected item is not valid, it can't be wearable! Rargh!
    if (Item < 0 || Item >= g_iItemCount) return 0;
    
    // Determine if the client has the override flag.
    if (g_iPlayerFlags[iClient] & PLAYER_OVERRIDE) return 1;
    
    if (g_iPlayerFlags[iClient] & PLAYER_ADMIN)
    {
        if (g_bAdminOverride) return 1;
    } else {
        if (g_iItemFlags[Item] & FLAG_ADMIN_ONLY) return 0;
    }
    
    if (!(Client_ClassFlags(iClient) & g_iItemClasses[Item])) return 0;
    if (!(Client_TeamFlags(iClient) & g_iItemTeams[Item]))    return 0;
    
    decl String:strSteamID[20]; GetClientAuthString(iClient, strSteamID, sizeof(strSteamID));
    if ((g_iItemFlags[Item] & FLAG_REQUIRES_STEAMID) && (StrContains(g_strItemSteamID[Item], strSteamID, false) == -1)) return 0;
    
    // Success!
    return 1;
}

// ------------------------------------------------------------------------
// Item_FindDefaultItem()
// ------------------------------------------------------------------------
Item_FindDefaultItem(iClient, iSlot)
{
    new iFlagsFilter;
    if (g_bForceAdmins && (g_iPlayerFlags[iClient] & PLAYER_ADMIN)) iFlagsFilter = FLAG_ADMIN_DEFAULT;
    else if (g_bForceUsers)                                         iFlagsFilter = FLAG_USER_DEFAULT;
    
    if (iFlagsFilter)
        for (new j=0; j<g_iItemCount; j++)
    {
        if (g_iItemSlot[j] != iSlot)           continue;
        if (!(g_iItemFlags[j] & iFlagsFilter)) continue;
        if (!Item_IsWearable(iClient, j))      continue;
        
        return j;
    }
    
    return -1;
}

// ------------------------------------------------------------------------
// Item_DetermineBodyGroups()
// ------------------------------------------------------------------------
/*Item_DetermineBodyGroups(iClient)
{
    // Determine bodygroups across all the equiped items
    new BodyGroups = 0;
    for (new Slot=0; Slot<MAX_SLOTS; Slot++)
    {
        new Item = g_iPlayerItem[iClient][Slot];
        if (Item == -1) continue;
        
        new Flags = g_iItemFlags[Item];
        
        switch(TF2_GetPlayerClass(iClient))
        {
            case TFClass_Engineer:
            {
                if (Flags & FLAG_HIDE_ENGINEER_HELMET) BodyGroups |= BODYGROUP_ENGINEER_HELMET;
            }
            case TFClass_Scout:
            {
                if (Flags & FLAG_HIDE_SCOUT_HAT) BodyGroups |= BODYGROUP_SCOUT_HAT;
                if (Flags & FLAG_HIDE_SCOUT_HEADPHONES) BodyGroups |= BODYGROUP_SCOUT_HEADPHONES;
            }
            case TFClass_Sniper:
            {
                if (Flags & FLAG_HIDE_SNIPER_HAT) BodyGroups |= BODYGROUP_SNIPER_HAT;
            }
            case TFClass_Soldier:
            {
                if (Flags & FLAG_HIDE_SOLDIER_HELMET) BodyGroups |= BODYGROUP_SOLDIER_HELMET;    
                if (Flags & FLAG_SHOW_SOLDIER_MEDAL) BodyGroups |= BODYGROUP_SOLDIER_MEDAL;
            }
        }
    }
    
    return BodyGroups;
}
*/

// ------------------------------------------------------------------------
// Item_RetrieveSlotCookie()
// ------------------------------------------------------------------------
Item_RetrieveSlotCookie(iClient, Slot)
{
    // If the cookies aren't cached, return.
    if (!AreClientCookiesCached(iClient)) return -1;
    
    // Retrieve current class
    new TFClassType:Class = TF2_GetPlayerClass(iClient);
    if (Class == TFClass_Unknown) return -1;
    
    // Retrieve the class cookie
    decl String:strCookie[64];
    GetClientCookie(iClient, g_hCookies[Class][Slot], strCookie, sizeof(strCookie));
    
    // If it's void, return -1
    if (StrEqual(strCookie, "")) return -1;
    
    // Otherwise, return the cookie value
    return StringToInt(strCookie);    
}

// ------------------------------------------------------------------------
// Item_SetSlotCookie()
// ------------------------------------------------------------------------
Item_SetSlotCookie(iClient, Slot)
{
    // If the cookies aren't cached, return.
    if (!AreClientCookiesCached(iClient)) return;
    
    // Retrieve current class
    new TFClassType:Class = TF2_GetPlayerClass(iClient);
    if (Class == TFClass_Unknown) return;
    
    // Set the class cookie
    decl String:strCookie[64];
    Format(strCookie, sizeof(strCookie), "%i", g_iPlayerItem[iClient][Slot]);
    SetClientCookie(iClient, g_hCookies[_:Class][Slot], strCookie);
}


// ------------------------------------------------------------------------
// Client_ClassFlags()
// ------------------------------------------------------------------------
// Calculates the current class flags and returns them
// ------------------------------------------------------------------------
Client_ClassFlags(iClient)
{
    switch(TF2_GetPlayerClass(iClient))
    {
        case TFClass_DemoMan:  return CLASS_DEMOMAN;
        case TFClass_Engineer: return CLASS_ENGINEER;
        case TFClass_Heavy:    return CLASS_HEAVY;
        case TFClass_Medic:    return CLASS_MEDIC;
        case TFClass_Pyro:     return CLASS_PYRO;
        case TFClass_Scout:    return CLASS_SCOUT;
        case TFClass_Sniper:   return CLASS_SNIPER;
        case TFClass_Soldier:  return CLASS_SOLDIER;
        case TFClass_Spy:      return CLASS_SPY;
    }
    
    return 0;
}

// ------------------------------------------------------------------------
// Client_TeamFlags()
// ------------------------------------------------------------------------
// Calculates the current team flags and returns them
// ------------------------------------------------------------------------
Client_TeamFlags(iClient)
{
    switch(GetClientTeam(iClient))
    {
        case TFTeam_Blue: return TEAM_BLU;
        case TFTeam_Red:  return TEAM_RED;
    }
    
    return 0;
}

// ------------------------------------------------------------------------
// Menu_BuildMain()
// ------------------------------------------------------------------------
// Builds the main menu, displaying the options for the wearable
// items.
// ------------------------------------------------------------------------
Handle:Menu_BuildMain()
{
    // Create menu handle
    new Handle:hMenu = CreateMenu(Menu_Manager, MenuAction_DisplayItem|MenuAction_Display);
    
    // Add the different options
    AddMenuItem(hMenu, "", "Menu_Equip");
    AddMenuItem(hMenu, "", "Menu_Remove");
    AddMenuItem(hMenu, "", "Menu_RemoveAll");
    
    // Setup title
    SetMenuTitle(hMenu, "Menu_Main");
    return hMenu;
}

// ------------------------------------------------------------------------
// Menu_BuildSlots()
// ------------------------------------------------------------------------
// Builds the select slots menu. Nothing fancy, just the slots.
// ------------------------------------------------------------------------
Handle:Menu_BuildSlots(String:StrTitle[])
{
    // Create menu handle
    new Handle:hMenu = CreateMenu(Menu_Manager, MenuAction_Display);
    
    // Add the different options
    for (new i=0; i<MAX_SLOTS; i++)
    {
        new String:StrBuffer[32]; Format(StrBuffer, sizeof(StrBuffer), "Slot %i", i+1);
        AddMenuItem(hMenu, "", StrBuffer);
    }
    
    // Setup title
    SetMenuTitle(hMenu, StrTitle);
    return hMenu;
}

// ------------------------------------------------------------------------
// Menu_BuildItemList(iClient, Slot)
// ------------------------------------------------------------------------
// This method builds and specific menu for the client, based on it's
// current state, class and flags.
// ------------------------------------------------------------------------
Handle:Menu_BuildItemList(iClient, Slot)
{
    // Create the menu Handle
    new Handle:Menu = CreateMenu(Menu_Manager);
    new String:strBuffer[64]; 
    
    // Add all objects
    for (new i=0; i<g_iItemCount; i++) 
    {
        // Skip if not a correct item
        if (g_iItemSlot[i] != Slot)         continue;
        if (!Item_IsWearable(iClient, i)) continue;
        if (g_iItemFlags[i] & FLAG_HIDDEN)  continue;
        
        Format(strBuffer, sizeof(strBuffer), "%i", i);
        AddMenuItem(Menu, strBuffer, g_strItemName[i]);
    }
    
    // Set the menu title
    SetMenuTitle(Menu, "%T", "Menu_SelectItem", iClient, Slot+1);
    
    return Menu;
}

// ------------------------------------------------------------------------
// Menu_Manager()
// ------------------------------------------------------------------------
// The master menu manager. Manages the different menu usages and 
// makes sure to translate the options when necessary.
// ------------------------------------------------------------------------
public Menu_Manager(Handle:hMenu, MenuAction:maState, iParam1, iParam2)
{
    new String:strBuffer[64];
    
    switch(maState)
    {
        case MenuAction_Select:
        {
            // First, check if the player is alive and ingame. If not, do nothing.
            if (!IsValidClient(iParam1)) return 0;
            
            if (hMenu == g_hMenuMain)
            {
                if (iParam2 == 0) DisplayMenu(g_hMenuEquip,  iParam1, MENU_TIME_FOREVER);
                else if (iParam2 == 1) DisplayMenu(g_hMenuRemove, iParam1, MENU_TIME_FOREVER);
                else {
                    for (new i=0; i<MAX_SLOTS; i++)
                    {
                        Item_Remove(iParam1, i);
                        Item_SetSlotCookie(iParam1, i);
                    }
                    CPrintToChat(iParam1, "%t", "Message_RemovedAllItems");
                }
            }
            else if (hMenu == g_hMenuEquip)
            {
                new Handle:hListMenu = Menu_BuildItemList(iParam1, iParam2);
                DisplayMenu(hListMenu,  iParam1, MENU_TIME_FOREVER);
            }
            else if (hMenu == g_hMenuRemove)
            {
                Item_Remove(iParam1, iParam2);
                Item_SetSlotCookie(iParam1, iParam2);
                CPrintToChat(iParam1, "%t", "Message_RemovedItem", iParam2+1);
            }
            else
            {
                GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));
                new Item = StringToInt(strBuffer);
                Item_Equip(iParam1, Item);
                Item_SetSlotCookie(iParam1, g_iItemSlot[Item]);
                CPrintToChat(iParam1, "%t", "Message_EquippedItem", g_strItemName[Item], g_iItemSlot[Item]+1);  
            }
        }
        
        case MenuAction_DisplayItem:
        {
            // Get the display string, we'll use it as a translation phrase
            decl String:strDisplay[64]; GetMenuItem(hMenu, iParam2, "", 0, _, strDisplay, sizeof(strDisplay));
            decl String:strTranslation[255]; Format(strTranslation, sizeof(strTranslation), "%T", strDisplay, iParam1);
            return RedrawMenuItem(strTranslation);
        }
        
        case MenuAction_Display:
        {
            // Retrieve panel
            new Handle:Panel = Handle:iParam2;
            
            // Translate title
            decl String:strTranslation[255];
            if (hMenu == g_hMenuMain)        { Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Main",   iParam1); }
            else if (hMenu == g_hMenuEquip)  { Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Equip",  iParam1); }
            else if (hMenu == g_hMenuRemove) { Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Remove", iParam1); }
            
            // Set title.
            SetPanelTitle(Panel, strTranslation);
        }
        
        case MenuAction_End:
        {
            if (hMenu != g_hMenuMain && hMenu != g_hMenuEquip && hMenu != g_hMenuRemove)
                CloseHandle(hMenu);
        }
    }
    
    return 1;
}

// ------------------------------------------------------------------------
// Cmd_BlockTriggers()
// ------------------------------------------------------------------------
public Action:Cmd_BlockTriggers(iClient, iArgs)
{
    if (!g_bBlockTriggers) return Plugin_Continue;
    if (iClient < 1 || iClient > MaxClients) return Plugin_Continue;
    if (iArgs < 1) return Plugin_Continue;
    
    // Retrieve the first argument and check it's a valid trigger
    decl String:strArgument[64]; GetCmdArg(1, strArgument, sizeof(strArgument));
    if (StrEqual(strArgument, "!tf_equipment", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!equip", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!em", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!hats", true)) return Plugin_Handled;
    
    // If no valid argument found, pass
    return Plugin_Continue;
}

// ------------------------------------------------------------------------
// Cmd_Menu()
// ------------------------------------------------------------------------
// Shows menu to clients, if the client is able to: The plugin isn't set
// to admin only or his equipment is locked.
// ------------------------------------------------------------------------
public Action:Cmd_Menu(iClient, iArgs)
{
    // Not allowed if not ingame.
    if (iClient == 0) { ReplyToCommand(iClient, "[TF2] Command is in-game only."); return Plugin_Handled; }
    
    // Check if the user doesn't have permission. If not, ignore command.
    if (!(g_iPlayerFlags[iClient] & PLAYER_ADMIN))
    {
        if (g_bAdminOnly)
        {
            CPrintToChat(iClient, "%t", "Error_AccessLevel");
            return Plugin_Handled;
        }
        if (g_iPlayerFlags[iClient] & PLAYER_LOCK)
        {
            CPrintToChat(iClient, "%t", "Error_EquipmentLocked");
            return Plugin_Handled;
        }
    }
    
    // Display menu.
    DisplayMenu(g_hMenuMain, iClient, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_EquipItem()
// ------------------------------------------------------------------------
// Force a client to equip an specific items.
// ------------------------------------------------------------------------
public Action:Cmd_EquipItem(iClient, iArgs)
{
    if (iArgs < 2) { ReplyToCommand(iClient, "[TF2] Usage: tf_equipment_equip <#id|name> <item name>."); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strItem[128];  GetCmdArg(2, strItem,   sizeof(strItem));
    new iItem = -1;
    
    // Check if item exists and if so, grab index
    for (new i=0; i<g_iItemCount; i++)
        if (StrEqual(g_strItemName[i], strItem, false))
    {
        iItem = i;
        break;
    }
    if (iItem == -1) { ReplyToCommand(iClient, "[TF2] Unknown item : \"%s\"", strItem); return Plugin_Handled; }
    
    // Process the targets 
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl iTargetList[MAXPLAYERS], iTargetCount;
    decl bool:bTargetTranslate;
    
    if ((iTargetCount = ProcessTargetString(strTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
    strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
    {
        ReplyToTargetError(iClient, iTargetCount);
        return Plugin_Handled;
    }
    
    // Apply to all targets
    for (new i = 0; i < iTargetCount; i++)
    {
        if (!IsValidClient(iTargetList[i])) continue;
        
        // If item isn't wearable, for the client.
        if (!Item_IsWearable(iTargetList[i], iItem)) {
            decl String:strName[64]; GetClientName(iTargetList[i], strName, sizeof(strName));
            CPrintToChat(iClient, "%t", "Error_CantWear", strName);  
            continue;
        }
        
        // Equip item and tell to client.
        Item_Equip(iTargetList[i], iItem);
        Item_SetSlotCookie(iTargetList[i], g_iItemSlot[iItem]);
        CPrintToChat(iTargetList[i], "%t", "Message_ForcedEquip", g_strItemName[iItem], g_iItemSlot[iItem]+1);  
    }
    
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_RemoveItem()
// ------------------------------------------------------------------------
public Action:Cmd_RemoveItem(iClient, iArgs)
{
    // Determine if the number of arguments is valid
    if (iArgs < 2) { ReplyToCommand(iClient, "[TF2] Usage: tf_equipment_remove <#id|name> <slot>."); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strSlot[8];    GetCmdArg(2, strSlot,   sizeof(strSlot));
    new iSlot = StringToInt(strSlot)-1;
    
    // Check if it's a valid slot.
    if (iSlot < 0 || iSlot >= MAX_SLOTS) { ReplyToCommand(iClient, "[TF2] Slot out of range : %i", iSlot+1); return Plugin_Handled; }
    
    // Process the targets
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl iTargetList[MAXPLAYERS], iTargetCount;
    decl bool:bTargetTranslate;
    
    if ((iTargetCount = ProcessTargetString(strTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
    strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
    {
        ReplyToTargetError(iClient, iTargetCount);
        return Plugin_Handled;
    }
    
    // Apply to all targets
    for (new i = 0; i < iTargetCount; i++)
    {
        if (!IsValidClient(iTargetList[i])) continue;
        
        Item_Remove(iTargetList[i], iSlot);
        Item_SetSlotCookie(iTargetList[i], iSlot);
        CPrintToChat(iTargetList[i], "%t", "Message_ForcedRemove", iSlot+1);  
    }
    
    // Done
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_LockEquipment()
// ------------------------------------------------------------------------
public Action:Cmd_LockEquipment(iClient, iArgs)
{
    // Determine if the number of arguments is valid
    if (iArgs < 2) { ReplyToCommand(iClient, "[TF2] Usage: tf_equipment_lock <#id|name> <state>"); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strState[8];   GetCmdArg(2, strState,  sizeof(strState));
    
    // Process the targets
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl iTargetList[MAXPLAYERS], iTargetCount;
    decl bool:bTargetTranslate;
    
    if ((iTargetCount = ProcessTargetString(strTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
    strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
    {
        ReplyToTargetError(iClient, iTargetCount);
        return Plugin_Handled;
    }
    
    // Apply to all targets
    new State = StringToInt(strState);
    if (State == 1) 
        for (new i = 0; i < iTargetCount; i++)
    {
        if (!IsValidClient(iTargetList[i])) continue;
        if (g_iPlayerFlags[iTargetList[i]] & PLAYER_ADMIN) continue;
        
        g_iPlayerFlags[iTargetList[i]] |= PLAYER_LOCK;
        CPrintToChat(iTargetList[i], "%t", "Message_Locked");  
    }
    else
    for (new i = 0; i < iTargetCount; i++)
    {
        if (!IsValidClient(iTargetList[i])) continue;
        if (g_iPlayerFlags[iTargetList[i]] & PLAYER_ADMIN) continue;
        
        g_iPlayerFlags[iTargetList[i]] &= ~PLAYER_LOCK;
        CPrintToChat(iTargetList[i], "%t", "Message_Unlocked");  
    }
    
    // Done
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_OverrideEquipment()
// ------------------------------------------------------------------------
public Action:Cmd_OverrideEquipment(iClient, iArgs)
{
    // Determine if the number of arguments is valid
    if (iArgs < 2) { ReplyToCommand(iClient, "[TF2] Usage: tf_equipment_override <#id|name> <state>"); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strState[8];   GetCmdArg(2, strState,  sizeof(strState));
    
    // Process the targets
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl iTargetList[MAXPLAYERS], iTargetCount;
    decl bool:bTargetTranslate;
    
    if ((iTargetCount = ProcessTargetString(strTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
    strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
    {        
        ReplyToTargetError(iClient, iTargetCount);
        return Plugin_Handled;
    }
    
    // Apply to all targets
    new iState = StringToInt(strState);
    
    if (iState == 1) 
        for (new i = 0; i < iTargetCount; i++)
    {
        if (!IsValidClient(iTargetList[i])) continue;
        
        g_iPlayerFlags[iTargetList[i]] |= PLAYER_OVERRIDE;
        CPrintToChat(iTargetList[i], "%t", "Message_Override_On");  
    }
    else
    for (new i = 0; i < iTargetCount; i++)
    {
        if (!IsValidClient(iTargetList[i])) continue;
        
        g_iPlayerFlags[iTargetList[i]] &= ~PLAYER_OVERRIDE;
        CPrintToChat(iTargetList[i], "%t", "Message_Override_Off");  
    }
    
    // Done
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_Reload()
// ------------------------------------------------------------------------
public Action:Cmd_Reload(iClient, iArgs)
{
    // Reparse item list
    Item_ParseList();
    
    // Re-read admins flags
    new ibFlags = ReadFlagString(g_strAdminFlags);
    for (iClient=1; iClient<=MaxClients; iClient++)
    {    
        if (!IsValidClient(iClient)) continue;
        
        g_iPlayerFlags[iClient] &= ~PLAYER_ADMIN;
        if (GetUserFlagBits(iClient) & ibFlags)      g_iPlayerFlags[iClient] |= PLAYER_ADMIN;
        if (GetUserFlagBits(iClient) & ADMFLAG_ROOT) g_iPlayerFlags[iClient] |= PLAYER_ADMIN;
    }
    
    // Done
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Timer_Welcome
// ------------------------------------------------------------------------
public Action:Timer_Welcome(Handle:hTimer, any:iClient)
{
    if (iClient < 1 || iClient > MaxClients) return Plugin_Stop;
    if (!IsValidClient(iClient)) return Plugin_Stop;
    
    CPrintToChat(iClient, "%t", "Announce_Plugin", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    return Plugin_Stop;
}

// ------------------------------------------------------------------------
// Timer_Announce
// ------------------------------------------------------------------------
public Action:Timer_Announce(Handle:hTimer)
{
    if (!g_bAnnounce) return Plugin_Continue;
    
    if (g_bAdminOnly)
    {
        for (new iClient=1; iClient<=MaxClients; iClient++)
        {
            if (!IsValidClient(iClient)) continue;
            
            if (!(g_iPlayerFlags[iClient] & PLAYER_ADMIN)) continue;
            CPrintToChat(iClient, "%t", "Announce_Command");
        }
    } else {
        CPrintToChatAll("%t", "Announce_Command");
    }
    
    return Plugin_Continue;
}

// ------------------------------------------------------------------------
// CleanString
// ------------------------------------------------------------------------
stock CleanString(String:strBuffer[])
{
    // Cleanup any illegal characters
    new Length = strlen(strBuffer);
    for (new iPos=0; iPos<Length; iPos++)
    {
        switch(strBuffer[iPos])
        {
            case '\r': strBuffer[iPos] = ' ';
            case '\n': strBuffer[iPos] = ' ';
            case '\t': strBuffer[iPos] = ' ';
        }
    }
    
    // Trim string
    TrimString(strBuffer);
}

// ------------------------------------------------------------------------
// TF2_SdkStartup
// ------------------------------------------------------------------------
stock TF2_SdkStartup()
{
    
    new Handle:hGameConf = LoadGameConfigFile("TF2_EquipmentManager");
    if (hGameConf != INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"EquipWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkEquipWearable = EndPrepSDKCall();
        
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"RemoveWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkRemoveWearable = EndPrepSDKCall();
        
        CloseHandle(hGameConf);
        g_bSdkStarted = true;
    } else {
        SetFailState("Couldn't load SDK functions (TF2_EquipmentManager).");
    }
}

// ------------------------------------------------------------------------
// TF2_SpawnWearable
// ------------------------------------------------------------------------
stock TF2_SpawnWearable(iOwner, iDef=52, iLevel=100, iQuality=0)
{
    new iTeam = GetClientTeam(iOwner);
    new iItem = CreateEntityByName("tf_wearable_item");
    
    if (IsValidEdict(iItem))
    {
        //SetEntProp(iItem, Prop_Send, "m_bInitialized", 1);    // Disabling this avoids the crashes related to spies
        // disguising as someone with hat in Windows.
        
        // Using reference data from Batter's Helmet. Thanks to MrSaturn.
        SetEntProp(iItem, Prop_Send, "m_fEffects",             EF_BONEMERGE|EF_BONEMERGE_FASTCULL|EF_NOSHADOW|EF_PARENT_ANIMATES);
        SetEntProp(iItem, Prop_Send, "m_iTeamNum",             iTeam);
        SetEntProp(iItem, Prop_Send, "m_nSkin",                (iTeam-2));
        SetEntProp(iItem, Prop_Send, "m_CollisionGroup",       11);
        SetEntProp(iItem, Prop_Send, "m_iItemDefinitionIndex", iDef);
        SetEntProp(iItem, Prop_Send, "m_iEntityLevel",         iLevel);
        SetEntProp(iItem, Prop_Send, "m_iEntityQuality",       iQuality);
        
        // Spawn.
        DispatchSpawn(iItem);
    }
    
    return iItem;
}

// ------------------------------------------------------------------------
// TF2_EquipWearable
// ------------------------------------------------------------------------
stock TF2_EquipWearable(iOwner, iItem)
{
    if (g_bSdkStarted == false) TF2_SdkStartup();
    
    if (TF2_IsEntityWearable(iItem)) SDKCall(g_hSdkEquipWearable, iOwner, iItem);
    else                             LogMessage("Error: Item %i isn't a valid wearable.", iItem);
}

// ------------------------------------------------------------------------
// TF2_RemoveWearable
// ------------------------------------------------------------------------
stock TF2_RemoveWearable(iOwner, iItem)
{
    if (g_bSdkStarted == false) TF2_SdkStartup();
    
    if (TF2_IsEntityWearable(iItem))
    {
        if (GetEntPropEnt(iItem, Prop_Send, "m_hOwnerEntity") == iOwner) SDKCall(g_hSdkRemoveWearable, iOwner, iItem);
        RemoveEdict(iItem);
    }
}

// ------------------------------------------------------------------------
// TF2_IsEntityWearable
// ------------------------------------------------------------------------
stock bool:TF2_IsEntityWearable(iEntity)
{
    if ((iEntity > 0) && IsValidEdict(iEntity))
    {
        new String:strClassname[32]; GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
        return StrEqual(strClassname, "tf_wearable_item", false);
    }
    
    return false;
}

// ------------------------------------------------------------------------
// IsValidClient
// ------------------------------------------------------------------------
stock bool:IsValidClient(iClient)
{
    if (iClient < 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}
// ------------------------------------------------------------------------
// FindEntityByClassnameSafe
// ------------------------------------------------------------------------
// By Exvel
// ------------------------------------------------------------------------
stock FindEntityByClassnameSafe(iStart, const String:strClassname[])
{
    while (iStart > -1 && !IsValidEntity(iStart)) iStart--;
        return FindEntityByClassname(iStart, strClassname);
}

// ------------------------------------------------------------------------
// CalculateBodyGroups
// ------------------------------------------------------------------------
CalculateBodyGroups(iClient)
{
    new iBodyGroups = g_iPlayerBGroups[iClient];
    new iItemGroups = 0;
    
    for (new iSlot = 0; iSlot < MAX_SLOTS; iSlot++)
    {
        if (g_iPlayerItem[iClient][iSlot] == -1) continue;
        iItemGroups |= g_iItemFlags[g_iPlayerItem[iClient][iSlot]];
    }
    
    switch(TF2_GetPlayerClass(iClient))
    {
        case TFClass_Heavy:
        {
            if (iItemGroups & FLAG_HIDE_HEAVY_HANDS) iBodyGroups = BODYGROUP_HEAVY_HANDS;
        }
        case TFClass_Engineer:
        {
            if (iItemGroups & FLAG_HIDE_ENGINEER_HELMET) iBodyGroups |= BODYGROUP_ENGINEER_HELMET;
        }
        case TFClass_Scout:
        {
            if (iItemGroups & FLAG_HIDE_SCOUT_HAT) iBodyGroups |= BODYGROUP_SCOUT_HAT;
            if (iItemGroups & FLAG_HIDE_SCOUT_HEADPHONES) iBodyGroups |= BODYGROUP_SCOUT_HEADPHONES;
        }
        case TFClass_Sniper:
        {
            if (iItemGroups & FLAG_SHOW_SNIPER_QUIVER) iBodyGroups |= BODYGROUP_SNIPER_QUIVER;
            if (iItemGroups & FLAG_HIDE_SNIPER_HAT) iBodyGroups |= BODYGROUP_SNIPER_HAT;
        }
        case TFClass_Soldier:
        {
            if (iItemGroups & FLAG_HIDE_SOLDIER_ROCKET) iBodyGroups |= BODYGROUP_SOLDIER_ROCKET;   
            if (iItemGroups & FLAG_HIDE_SOLDIER_HELMET) iBodyGroups |= BODYGROUP_SOLDIER_HELMET;   
        }
    }
    
    return iBodyGroups;
}

