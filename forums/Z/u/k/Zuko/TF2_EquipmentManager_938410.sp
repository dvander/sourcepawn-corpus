// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1                  // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <colors>
#include <tf2>
#include <tf2_stocks>
//#include <tf2_ext>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
// ---- Plugin-related constants ---------------------------------------------------
#define PLUGIN_NAME              "[TF2] Equipment Manager"
#define PLUGIN_AUTHOR            "Damizean"
#define PLUGIN_VERSION           "1.1.5"
#define PLUGIN_CONTACT           "elgigantedeyeso@gmail.com"
#define CVAR_FLAGS               FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

//#define DEBUG

// ---- Items management -----------------------------------------------------------
#define MAX_ITEMS                256
#define MAX_SLOTS                3
#define MAX_LENGTH               256

// ---- Wearables flags ------------------------------------------------------------
#define PLAYER_ADMIN             (1 << 0)        // Player is admin.
#define PLAYER_OVERRIDE          (1 << 1)        // Player is overriding the restrictions of the items.
#define PLAYER_LOCK              (1 << 2)        // Player has it's equipment locked

#define FLAG_ADMIN_ONLY          (1 << 0)        // Only admins can use this item.
#define FLAG_USER_DEFAULT        (1 << 1)        // This is the forced default for users.
#define FLAG_ADMIN_DEFAULT       (1 << 2)        // This is the forced default for admins.
#define FLAG_HIDDEN              (1 << 3)        // Hidden from list
#define FLAG_INVISIBLE             (1 << 4)        // Invisible! INVISIBLE!
#define FLAG_HIDE_SCOUT_HAT          (1 << 5)
#define FLAG_HIDE_SCOUT_HEADPHONES   (1 << 6)
#define FLAG_HIDE_HEAVY_HANDS        (1 << 7)
#define FLAG_HIDE_ENGINEER_HELMET    (1 << 8)
#define FLAG_HIDE_SNIPER_QUIVER      (1 << 9)
#define FLAG_HIDE_SNIPER_HAT         (1 << 10)
#define FLAG_HIDE_SOLDIER_ROCKET     (1 << 11)
#define FLAG_HIDE_SOLDIER_HELMET     (1 << 12)
#define FLAG_SHOW_SOLDIER_MEDAL      (1 << 13)

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

// ---- Player tracking ------------------------------------------------------------
new PlayerItem[MAXPLAYERS+1][MAX_SLOTS];
new PlayerItemEntity[MAXPLAYERS+1][MAX_SLOTS];
new PlayerFlags[MAXPLAYERS+1];
new PlayerBodyGroups[MAXPLAYERS+1];

// ---- Object pool variables ------------------------------------------------------
new ItemCount = 0;
new String:ItemName[MAX_ITEMS][MAX_LENGTH];
new String:ItemModel[MAX_ITEMS][MAX_LENGTH];
new ItemFlags[MAX_ITEMS];
new ItemClasses[MAX_ITEMS];
new ItemSlot[MAX_ITEMS];
new ItemTeams[MAX_ITEMS];
new ItemIndex[MAX_ITEMS];
new bool:g_bSdkStarted = false;
new Handle:g_hSdkEquipWearable;
new Handle:g_hSdkRemoveWearable;

// ---- Cvars ----------------------------------------------------------------------
new Handle:CvarVersion              = INVALID_HANDLE;
new Handle:CvarAdminOnly            = INVALID_HANDLE;
new Handle:CvarAdminFlags           = INVALID_HANDLE;
new Handle:CvarAdminOverride        = INVALID_HANDLE;
new Handle:CvarAnnounce             = INVALID_HANDLE;
new Handle:CvarAnnouncePlugin       = INVALID_HANDLE;
new Handle:CvarForceDefaultOnUsers  = INVALID_HANDLE;
new Handle:CvarForceDefaultOnAdmins = INVALID_HANDLE;
new Handle:CvarDelayOnSpawn         = INVALID_HANDLE;
new Handle:CvarLoadItemsLogging     = INVALID_HANDLE;

new bool:CfgAdminOnly      = false;
new bool:CfgAdminOverride  = false;
new bool:CfgAnnounce       = false;
new bool:CfgAnnouncePlugin = false;
new bool:CfgForceOnUsers   = false;
new bool:CfgForceOnAdmins  = false;
new Float:CfgDelayOnSpawn  = 0.0;
new String:CfgAdminFlags[32];

// ---- Others ---------------------------------------------------------------------
new Handle:hMenuMain   = INVALID_HANDLE;
new Handle:hMenuEquip  = INVALID_HANDLE;
new Handle:hMenuRemove = INVALID_HANDLE;

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
    CvarVersion              = CreateConVar("tf_equipment_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    CvarAdminFlags           = CreateConVar("tf_equipment_admin_flags",     "b",   "Only users with one of these flags are considered administrators.", CVAR_FLAGS);
    CvarAdminOnly            = CreateConVar("tf_equipment_admin",           "0",   "Only administrators can use the equipment.",                        CVAR_FLAGS);
    CvarAdminOverride        = CreateConVar("tf_equipment_admin_override",  "0",   "Administrators can override the equipment restrictions.",           CVAR_FLAGS);
    CvarAnnounce             = CreateConVar("tf_equipment_announce",        "1",   "Announces usage and tips about equipable items.",                   CVAR_FLAGS);
    CvarAnnouncePlugin       = CreateConVar("tf_equipment_announce_plugin", "1",   "Announces information of the plugin when joining.",                 CVAR_FLAGS);
    CvarForceDefaultOnUsers  = CreateConVar("tf_equipment_force_users",     "0",   "Forces the default equipment for common users.",                    CVAR_FLAGS);
    CvarForceDefaultOnAdmins = CreateConVar("tf_equipment_force_admins",    "0",   "Forces the default equipment for admin users.",                     CVAR_FLAGS);
    CvarDelayOnSpawn         = CreateConVar("tf_equipment_delayonspawn",    "0.3", "Amount of time to wait to re-equip items after spawn.",             CVAR_FLAGS);
	CvarLoadItemsLogging         = CreateConVar("tf_equipment_loaditemsloging",    "1", "Display loading items log.",                                   CVAR_FLAGS);
    
    // Startup extended stocks
    TF2_SdkStartup();
    
    // Register console commands
    RegConsoleCmd("tf_equipment",        Cmd_Menu, "Shows the equipment manager menu");
    RegConsoleCmd("equipment",           Cmd_Menu, "Shows the equipment manager menu");
    RegConsoleCmd("equip",               Cmd_Menu, "Shows the equipment manager menu");
    RegConsoleCmd("em",                  Cmd_Menu, "Shows the equipment manager menu");
    RegAdminCmd("tf_equipment_equip",    Cmd_EquipItem,         ADMFLAG_GENERIC, "Forces to equip an item onto a client.");
    RegAdminCmd("tf_equipment_remove",   Cmd_RemoveItem,        ADMFLAG_GENERIC, "Forces to remove an item on the client.");
    RegAdminCmd("tf_equipment_lock",     Cmd_LockEquipment,     ADMFLAG_GENERIC, "Locks/unlocks the client's equipment so it can't be changed.");
    RegAdminCmd("tf_equipment_override", Cmd_OverrideEquipment, ADMFLAG_GENERIC, "Enables restriction overriding for the client.");
    RegAdminCmd("tf_equipment_reload",   Cmd_Reload,            ADMFLAG_GENERIC, "Reparses the items file and rebuilds the equipment list.");
    
    // Hook the proper events and cvars
    HookEvent("player_spawn",             Event_EquipItem,  EventHookMode_Post);
    HookEvent("player_changeclass",       Event_RemoveItem, EventHookMode_Pre);
    HookEvent("teamplay_round_stalemate", Event_RemoveItem, EventHookMode_Pre);
    AddNormalSoundHook(NormalSHook:Hook_Sound); 
    HookConVarChange(CvarAdminFlags,           Cvar_UpdateCfg);
    HookConVarChange(CvarAdminOnly,            Cvar_UpdateCfg);
    HookConVarChange(CvarAdminOverride,        Cvar_UpdateCfg);
    HookConVarChange(CvarAnnounce,             Cvar_UpdateCfg);
    HookConVarChange(CvarAnnouncePlugin,       Cvar_UpdateCfg);
    HookConVarChange(CvarForceDefaultOnUsers,  Cvar_UpdateCfg);
    HookConVarChange(CvarForceDefaultOnAdmins, Cvar_UpdateCfg);
    HookConVarChange(CvarDelayOnSpawn,         Cvar_UpdateCfg);
    
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
    for (new i=1; i<=MaxClients; i++)
    {
        for (new j=0; j<MAX_SLOTS; j++)
            Item_Remove(i, j, 1, 0);
    }
}

// ------------------------------------------------------------------------
// OnConfigsExecuted()
// ------------------------------------------------------------------------
public OnConfigsExecuted()
{
    // Determine if the version of the cfg is the correct one
    new String:strVersion[16]; GetConVarString(CvarVersion, strVersion, sizeof(strVersion));
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
    CfgAdminOnly      = GetConVarBool(CvarAdminOnly);
    CfgAdminOverride  = GetConVarBool(CvarAdminOverride);
    CfgAnnounce       = GetConVarBool(CvarAnnounce);
    CfgAnnouncePlugin = GetConVarBool(CvarAnnouncePlugin);
    CfgForceOnUsers   = GetConVarBool(CvarForceDefaultOnUsers);
    CfgForceOnAdmins  = GetConVarBool(CvarForceDefaultOnAdmins);
    CfgDelayOnSpawn   = GetConVarFloat(CvarDelayOnSpawn);
    GetConVarString(CvarAdminFlags, CfgAdminFlags, sizeof(CfgAdminFlags));
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
    for (new i=1; i<=MaxClients; i++)
    {
        PlayerFlags[i] = 0;
        
        for (new j=0; j<MAX_SLOTS; j++)
        {
            PlayerItem[i][j] = -1;
            PlayerItemEntity[i][j] = -1;
        }
    }
    
    // Reparse and re-build the menus
    Item_ParseList();
    hMenuMain   = Menu_BuildMain();
    hMenuEquip  = Menu_BuildSlots("EquipItem");
    hMenuRemove = Menu_BuildSlots("RemoveSlot");
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
// At map end, destroy all the built menus.
// ------------------------------------------------------------------------
public OnMapEnd()
{
    // Destroy menus
    if (hMenuMain   != INVALID_HANDLE) { CloseHandle(hMenuMain);   hMenuMain   = INVALID_HANDLE; }
    if (hMenuEquip  != INVALID_HANDLE) { CloseHandle(hMenuEquip);  hMenuEquip  = INVALID_HANDLE; }
    if (hMenuRemove != INVALID_HANDLE) { CloseHandle(hMenuRemove); hMenuRemove = INVALID_HANDLE; }
}

// ------------------------------------------------------------------------
// OnClientPutInServer()
// ------------------------------------------------------------------------
// When a client is put in server, greet the player and show off information
// about the plugin.
// ------------------------------------------------------------------------
public OnClientPutInServer(Client)
{
    if (CfgAnnouncePlugin)
    {
        CreateTimer(30.0, Timer_Welcome, Client, TIMER_FLAG_NO_MAPCHANGE);
    }
}

// ------------------------------------------------------------------------
// OnClientPostAdminCheck()
// ------------------------------------------------------------------------
// Identify the client that just connected, checking if at least one of the
// flags listed in the cvar.
// ------------------------------------------------------------------------
public OnClientPostAdminCheck(Client)
{
    // Retrieve needed flags and determine if the player is an admin.
    new ibFlags = ReadFlagString(CfgAdminFlags);

    // Test and setup flag if so.
    if (GetUserFlagBits(Client) & ibFlags)      PlayerFlags[Client] |= PLAYER_ADMIN;
    if (GetUserFlagBits(Client) & ADMFLAG_ROOT) PlayerFlags[Client] |= PLAYER_ADMIN;
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
    CreateTimer(CfgDelayOnSpawn, Timer_EquipItem, GetClientOfUserId(GetEventInt(hEvent, "userid")), TIMER_FLAG_NO_MAPCHANGE);
}
public Action:Timer_EquipItem(Handle:hTimer, any:Client)
{
    if (Client == 0)                return Plugin_Handled;
    if (!IsClientConnected(Client)) return Plugin_Handled;
    if (!IsClientInGame(Client))    return Plugin_Handled;
    if (!IsPlayerAlive(Client))     return Plugin_Handled;
    
    // Retrieve current player bodygroups status.
    PlayerBodyGroups[Client] = GetEntProp(Client, Prop_Send, "m_nBody");
    
    // Determine if the hats are still valid for the
    // client.
    for (new i=0; i<MAX_SLOTS; i++)
    {
        if (!Item_IsWearable(Client, PlayerItem[Client][i]))
        {
            // Remove the item that's not possible to wear
            Item_Remove(Client, i, 1);
            
            // Determine new wearable item
            PlayerItem[Client][i] = Item_FindDefaultItem(Client, i);
        }
        
        // Equip the player with the selected item.
        Item_Equip(Client, PlayerItem[Client][i]);
    }    
    
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Event_RemoveItem()
// ------------------------------------------------------------------------
// On player's death or change class, we need to remove the item equipped,
// otherwise there would appear some errors where the items would take over  
// weapons slots.
// ------------------------------------------------------------------------
public Event_RemoveItem(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    for (new i=0; i<MAX_SLOTS; i++) Item_Remove(Client, i, 0);
}

// ------------------------------------------------------------------------
// Hook_Sound()
// ------------------------------------------------------------------------
// When using a resupply, the game automatically removes all the items
// and re-equps them to the player. However, it will also remove the items
// equipped, so we need to re-equip them. We detect the resupply through the
// specific sound it plays when used.
// ------------------------------------------------------------------------
public Action:Hook_Sound(Clients[64], &NumClients, String:StrSample[PLATFORM_MAX_PATH], &Entity)
{
    if (!StrEqual(StrSample, "items/regenerate.wav", true)) return Plugin_Continue;
    for (new i=0; i<MAX_SLOTS; i++)
    {    
        // Retrieve new bodygroups
        PlayerBodyGroups[Entity] = GetEntProp(Entity, Prop_Send, "m_nBody");
    
        // Re-equip everything.
        if (Item_IsValidWearable(PlayerItemEntity[Entity][i])) RemoveEdict(PlayerItemEntity[Entity][i]);
        Item_Equip(Entity, PlayerItem[Entity][i]); 
    }
    return Plugin_Continue;
}  

// ------------------------------------------------------------------------
// OnClientDisconnect()
// ------------------------------------------------------------------------
// When the client disconnects, remove it's equipped items and reset all
// the flags.
// ------------------------------------------------------------------------
public OnClientDisconnect(Client)
{
    for (new i=0; i<MAX_SLOTS; i++) Item_Remove(Client, i, 1, 0);
    PlayerFlags[Client] = 0;
}

// ------------------------------------------------------------------------
// Item_Equip
// ------------------------------------------------------------------------
// Equip the desired item onto a client.
// ------------------------------------------------------------------------
Item_Equip(Client, Item)
{
    // Assert if the player is alive.
    if (Client == 0) return;
    if (!IsClientConnected(Client)) return;
    if (!IsClientInGame(Client))    return;
    
    // If nothing to attach, do nothing.
    if (Item == -1) return;
    
    // Retrieve the information of the item and the current item
    new Slot          = ItemSlot[Item];
    new CurrentItem   = PlayerItem[Client][Slot];
    new CurrentEntity = PlayerItemEntity[Client][Slot];
    
    // Change the item index now
    PlayerItem[Client][Slot] = Item;
     
    // Determine if the current entity is valid. If not, create a new
    // entity to use as hat. If it was valid, just change the model.
    if (!TF2_IsEntityWearable(CurrentEntity))
    {   
        // Of course, only create the entity 
        if (IsPlayerAlive(Client)) 
        {
            new Entity = TF2_SpawnWearable(Client, ItemIndex[Item]);
            TF2_EquipWearable(Client, Entity);
            
            if (ItemFlags[ItemCount] & FLAG_INVISIBLE)
            {
                SetEntityRenderMode(Entity, RENDER_NONE);
            }
            else
            {
                SetEntityModel(Entity, ItemModel[Item]);
            }
            SetEntProp(Client, Prop_Send, "m_nBody", PlayerBodyGroups[Client] | Item_DetermineBodyGroups(Client));
            
            PlayerItemEntity[Client][Slot] = Entity;
        }
    }
    else if (Item != CurrentItem)
    {
        SetEntProp(CurrentEntity, Prop_Send, "m_iItemDefinitionIndex", ItemIndex[Item]);
        if (ItemFlags[ItemCount] & FLAG_INVISIBLE)
        {
            SetEntityRenderMode(CurrentEntity, RENDER_NONE);
        }
        else
        {
            SetEntityRenderMode(CurrentEntity, RENDER_NORMAL);
            SetEntityModel(CurrentEntity, ItemModel[Item]);
        }
        SetEntProp(Client, Prop_Send, "m_nBody", PlayerBodyGroups[Client] | Item_DetermineBodyGroups(Client));
    }
}

// ------------------------------------------------------------------------
// Item_IsCTFWearable
// ------------------------------------------------------------------------
// Checks if the item is a valid tf_wearable_item
// ------------------------------------------------------------------------
bool:Item_IsValidWearable(Entity)
{
    if (!IsValidEntity(Entity)) return false;
    decl String:strClassName[64]; GetEdictClassname(Entity, strClassName, sizeof(strClassName));
    return StrEqual("tf_wearable_item", strClassName);
}

// ------------------------------------------------------------------------
// Item_Remove
// ------------------------------------------------------------------------
// Remove the item equipped at the selected slot.
// ------------------------------------------------------------------------
Item_Remove(Client, Slot, Reset, Check=1)
{
    // Assert if the player is alive.
    if (Check)
    {
        if (Client == 0) return;
        if (!IsClientConnected(Client)) return;
        if (!IsClientInGame(Client))    return;
    }
    
    // Assert if there was an item to begin with.
    if (PlayerItem[Client][Slot] == -1) return;

    // Reset item index
    if (Reset) PlayerItem[Client][Slot] = -1;
    
    // Destroy the item entity
    if (TF2_IsEntityWearable(PlayerItemEntity[Client][Slot]))
    {
        TF2_RemoveWearable(Client, PlayerItemEntity[Client][Slot]);
        SetEntProp(Client, Prop_Send, "m_nBody", PlayerBodyGroups[Client] | Item_DetermineBodyGroups(Client));
    }
    PlayerItemEntity[Client][Slot] = -1;
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
    ItemCount = 0;
	
	if (GetConVarInt(CvarLoadItemsLogging))
	{
		LogMessage("### PARSING ITEM LIST ###");
	}
    
    // Iterate through all keys.
    do
    {
        // Retrieve section name, wich is pretty much the name of the wearable. Also, parse the model.
        KvGetSectionName(kvItemList,       ItemName[ItemCount],  MAX_LENGTH);
        KvGetString(kvItemList, "model",   ItemModel[ItemCount], MAX_LENGTH);
        KvGetString(kvItemList, "index",   strLine, sizeof(strLine)); ItemIndex[ItemCount]   = StringToInt(strLine);
        KvGetString(kvItemList, "flags",   strLine, sizeof(strLine)); ItemFlags[ItemCount]   = Item_ParseFlags(strLine);
        KvGetString(kvItemList, "classes", strLine, sizeof(strLine)); ItemClasses[ItemCount] = Item_ParseClasses(strLine);
        KvGetString(kvItemList, "teams",   strLine, sizeof(strLine)); ItemTeams[ItemCount]   = Item_ParseTeams(strLine);
        KvGetString(kvItemList, "slot",    strLine, sizeof(strLine)); ItemSlot[ItemCount]    = StringToInt(strLine)-1;
        
		if (GetConVarInt(CvarLoadItemsLogging))
		{
			LogMessage("Found item -> %s", ItemName[ItemCount]);
		}
        #if defined DEBUG
            LogMessage("    - Model : \"%s\"", ItemModel[ItemCount]);
            LogMessage("    - Index : %i", ItemIndex[ItemCount]);
            LogMessage("    - Flags : %b", ItemFlags[ItemCount]);
            LogMessage("    - Class : %08b", ItemClasses[ItemCount]);
            LogMessage("    - Teams : %02b", ItemTeams[ItemCount]);
            LogMessage("    - Slot  : %i", ItemSlot[ItemCount]+1);
        #endif
        
        // If it's invisible, skip
        if (!(ItemFlags[ItemCount] & FLAG_INVISIBLE))
        {
            // Check if model exists, so we can prevent crashes.
            if (!FileExists(ItemModel[ItemCount], true))
            {
                LogMessage("    @ERROR : File \"%s\" not found. Excluding from list.", ItemModel[ItemCount]);
                continue;
            }
            
            // Retrieve dependencies file and open if possible.
            Format(strDependencies, sizeof(strDependencies), "%s.dep", ItemModel[ItemCount]);
            if (FileExists(strDependencies))
            {
                #if defined DEBUG
                    LogMessage("    - Found dependencies file. Trying to read.");
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
                        LogMessage("        + File: \"%s\"", strLine);
                    #endif
                    // If file exists...
                    if (!FileExists(strLine, true))
                    {
                        continue;
                    }
                    
                    // Precache depending on type, and add to download table
                    if (StrContains(strLine, ".vmt", false) != -1)      PrecacheDecal(strLine, true);
                    else if (StrContains(strLine, ".vtf", false) != -1) PrecacheDecal(strLine, true);
                    else if (StrContains(strLine, ".mdl", false) != -1) PrecacheModel(strLine, true);
                    AddFileToDownloadsTable(strLine);
                }
                
                // Close file
                CloseHandle(hStream);
                
                // Precache model, anyway
                PrecacheModel(ItemModel[ItemCount], true);
            } else {
                PrecacheModel(ItemModel[ItemCount], true);
            }
        }
        
        // Go to next.
        ItemCount++;
    }
    while (KvGotoNextKey(kvItemList));
    
    CloseHandle(kvItemList);   
	if (GetConVarInt(CvarLoadItemsLogging))
	{	
		LogMessage("### FINISHED PARSING ###");
	}
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
    //if (StrContains(strFlags, "HIDE_HEAVY_HANDS", false)       != -1) Flags |= FLAG_HIDE_HEAVY_HANDS;    
    if (StrContains(strFlags, "HIDE_ENGINEER_HELMET", false)   != -1) Flags |= FLAG_HIDE_ENGINEER_HELMET;
    //if (StrContains(strFlags, "HIDE_SNIPER_QUIVER", false)     != -1) Flags |= FLAG_HIDE_SNIPER_QUIVER;
    if (StrContains(strFlags, "HIDE_SNIPER_HAT", false)        != -1) Flags |= FLAG_HIDE_SNIPER_HAT;     
    //if (StrContains(strFlags, "HIDE_SOLDIER_ROCKET", false)    != -1) Flags |= FLAG_HIDE_SOLDIER_ROCKET;
    if (StrContains(strFlags, "HIDE_SOLDIER_HELMET", false)    != -1) Flags |= FLAG_HIDE_SOLDIER_HELMET;
    if (StrContains(strFlags, "SHOW_SOLDIER_MEDAL", false)     != -1) Flags |= FLAG_SHOW_SOLDIER_MEDAL;

    return Flags;
}

// ------------------------------------------------------------------------
// Item_ParseClasses()
// ------------------------------------------------------------------------
// Parses the wearable classes, duh.
// ------------------------------------------------------------------------
Item_ParseClasses(String:strClasses[])
{
    new Flags;
    if (StrContains(strClasses, "SCOUT", false)    != -1) Flags |= CLASS_SCOUT;
    if (StrContains(strClasses, "SNIPER", false)   != -1) Flags |= CLASS_SNIPER;
    if (StrContains(strClasses, "SOLDIER", false)  != -1) Flags |= CLASS_SOLDIER;
    if (StrContains(strClasses, "DEMOMAN", false)  != -1) Flags |= CLASS_DEMOMAN;
    if (StrContains(strClasses, "MEDIC", false)    != -1) Flags |= CLASS_MEDIC;
    if (StrContains(strClasses, "HEAVY", false)    != -1) Flags |= CLASS_HEAVY;
    if (StrContains(strClasses, "PYRO", false)     != -1) Flags |= CLASS_PYRO;
    if (StrContains(strClasses, "SPY", false)      != -1) Flags |= CLASS_SPY;
    if (StrContains(strClasses, "ENGINEER", false) != -1) Flags |= CLASS_ENGINEER;
    if (StrContains(strClasses, "ALL", false)      != -1) Flags |= CLASS_ALL;
    
    return Flags;
}
// ------------------------------------------------------------------------
// Item_ParseTeams()
// ------------------------------------------------------------------------
// Parses the wearable teams, duh.
// ------------------------------------------------------------------------
Item_ParseTeams(String:strTeams[])
{
    new Flags;
    if (StrContains(strTeams, "RED", false) != -1 ) Flags |= TEAM_RED;
    if (StrContains(strTeams, "BLUE", false) != -1) Flags |= TEAM_BLU;
    if (StrContains(strTeams, "ALL", false) != -1)  Flags |= TEAM_RED|TEAM_BLU;
    
    return Flags;
}

// ------------------------------------------------------------------------
// Item_IsWearable()
// ------------------------------------------------------------------------
// Determines if the selected item is wearable by a player (that means, 
// the player has the enough admin level, is the correct class, etc. These
// Cfg can be overriden if the player has the override flag, though.
// ------------------------------------------------------------------------
Item_IsWearable(Client, Item)
{
    // If the selected item is not valid, it can't be wearable! Rargh!
    if (Item == -1) return 0;
    
    // Determine if the client has the override flag.
    if (PlayerFlags[Client] & PLAYER_OVERRIDE) return 1;
    
    if (PlayerFlags[Client] & PLAYER_ADMIN)
    {
        if (CfgAdminOverride) return 1;
    } else {
        if (ItemFlags[Item] & FLAG_ADMIN_ONLY) return 0;
    }
    
    if (!(Client_ClassFlags(Client) & ItemClasses[Item])) return 0;
    if (!(Client_TeamFlags(Client) & ItemTeams[Item]))    return 0;
    
    // Success!
    return 1;
}

// ------------------------------------------------------------------------
// Item_FindDefaultItem()
// ------------------------------------------------------------------------
Item_FindDefaultItem(Client, Slot)
{
    new FlagsFilter;
    if (CfgForceOnAdmins && (PlayerFlags[Client] & PLAYER_ADMIN)) FlagsFilter = FLAG_ADMIN_DEFAULT;
    else if (CfgForceOnUsers)                                     FlagsFilter = FLAG_USER_DEFAULT;
            
    if (FlagsFilter)
        for (new j=0; j<ItemCount; j++)
        {
            if (ItemSlot[j] != Slot)           continue;
            if (!(ItemFlags[j] & FlagsFilter)) continue;
            if (!Item_IsWearable(Client, j))   continue;
                    
            return j;
        }
    
    return -1;
}

// ------------------------------------------------------------------------
// Item_DetermineBodyGroups()
// ------------------------------------------------------------------------
Item_DetermineBodyGroups(Client)
{
    // Determine bodygroups across all the equiped items
    new BodyGroups = 0;
    for (new Slot=0; Slot<MAX_SLOTS; Slot++)
    {
        new Item = PlayerItem[Client][Slot];
        if (Item == -1) continue;
        
        new Flags = ItemFlags[Item];
        
        switch(TF2_GetPlayerClass(Client))
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

// ------------------------------------------------------------------------
// Client_ClassFlags()
// ------------------------------------------------------------------------
// Calculates the current class flags and returns them
// ------------------------------------------------------------------------
Client_ClassFlags(Client)
{
    switch(TF2_GetPlayerClass(Client))
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
Client_TeamFlags(Client)
{
    switch(GetClientTeam(Client))
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
    new Handle:Menu = CreateMenu(Menu_Manager, MenuAction_DisplayItem|MenuAction_Display);

    // Add the different options
    AddMenuItem(Menu, "", "Menu_Equip");
    AddMenuItem(Menu, "", "Menu_Remove");
    AddMenuItem(Menu, "", "Menu_RemoveAll");
    
    // Setup title
    SetMenuTitle(Menu, "Menu_Main");
    return Menu;
}

// ------------------------------------------------------------------------
// Menu_BuildSlots()
// ------------------------------------------------------------------------
// Builds the select slots menu. Nothing fancy, just the slots.
// ------------------------------------------------------------------------
Handle:Menu_BuildSlots(String:StrTitle[])
{
    // Create menu handle
    new Handle:Menu = CreateMenu(Menu_Manager, MenuAction_Display);

    // Add the different options
    for (new i=0; i<MAX_SLOTS; i++)
    {
        new String:StrBuffer[32]; Format(StrBuffer, sizeof(StrBuffer), "Slot %i", i+1);
        AddMenuItem(Menu, "", StrBuffer);
    }
    
    // Setup title
    SetMenuTitle(Menu, StrTitle);
    return Menu;
}

// ------------------------------------------------------------------------
// Menu_BuildItemList(Client, Slot)
// ------------------------------------------------------------------------
// This method builds and specific menu for the client, based on it's
// current state, class and flags.
// ------------------------------------------------------------------------
Handle:Menu_BuildItemList(Client, Slot)
{
    // Create the menu Handle
    new Handle:Menu = CreateMenu(Menu_Manager);
    new String:strBuffer[64]; 
    
    // Add all objects
    for (new i=0; i<ItemCount; i++) 
    {
        // Skip if not a correct item
        if (ItemSlot[i] != Slot)         continue;
        if (!Item_IsWearable(Client, i)) continue;
        if (ItemFlags[i] & FLAG_HIDDEN)  continue;
        
        Format(strBuffer, sizeof(strBuffer), "%i", i);
        AddMenuItem(Menu, strBuffer, ItemName[i]);
    }

    // Set the menu title
    SetMenuTitle(Menu, "%T", "Menu_SelectItem", Client, Slot+1);

    return Menu;
}

// ------------------------------------------------------------------------
// Menu_Manager()
// ------------------------------------------------------------------------
// The master menu manager. Manages the different menu usages and 
// makes sure to translate the options when necessary.
// ------------------------------------------------------------------------
public Menu_Manager(Handle:hMenu, MenuAction:State, Param1, Param2)
{
    new String:strBuffer[64];
    
    switch(State)
    {
        case MenuAction_Select:
        {
            // First, check if the player is alive and ingame. If not, do nothing.
            if (!IsClientConnected(Param1)) return 0;
            if (!IsClientInGame(Param1))    return 0;
            
            if (hMenu == hMenuMain)
                {
                    if (Param2 == 0) DisplayMenu(hMenuEquip,  Param1, MENU_TIME_FOREVER);
                    else if (Param2 == 1) DisplayMenu(hMenuRemove, Param1, MENU_TIME_FOREVER);
                    else {
                        for (new i=0; i<MAX_SLOTS; i++) Item_Remove(Param1, i, 1);
                        CPrintToChat(Param1, "%t", "Message_RemovedAllItems");
                    }
                }
            else if (hMenu == hMenuEquip)
                {
                    new Handle:hListMenu = Menu_BuildItemList(Param1, Param2);
                    DisplayMenu(hListMenu,  Param1, MENU_TIME_FOREVER);
                }
            else if (hMenu == hMenuRemove)
                {
                    Item_Remove(Param1, Param2, 1);
                    CPrintToChat(Param1, "%t", "Message_RemovedItem", Param2+1);
                }
            else
                {
                    GetMenuItem(hMenu, Param2, strBuffer, sizeof(strBuffer));
                    new Item = StringToInt(strBuffer);
                    Item_Equip(Param1, Item);
                    CPrintToChat(Param1, "%t", "Message_EquippedItem", ItemName[Item], ItemSlot[Item]+1);  
                }
        }
        
        case MenuAction_DisplayItem:
        {
            // Get the display string, we'll use it as a translation phrase
            decl String:strDisplay[64]; GetMenuItem(hMenu, Param2, "", 0, _, strDisplay, sizeof(strDisplay));
            decl String:strTranslation[255]; Format(strTranslation, sizeof(strTranslation), "%T", strDisplay, Param1);
            return RedrawMenuItem(strTranslation);
        }
        
        case MenuAction_Display:
        {
            // Retrieve panel
            new Handle:Panel = Handle:Param2;
             
            // Translate title
            decl String:strTranslation[255];
            if (hMenu == hMenuMain)        { Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Main",   Param1); }
            else if (hMenu == hMenuEquip)  { Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Equip",  Param1); }
            else if (hMenu == hMenuRemove) { Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Remove", Param1); }
     
            // Set title.
            SetPanelTitle(Panel, strTranslation);
        }
        
        case MenuAction_End:
        {
            if (hMenu != hMenuMain && hMenu != hMenuEquip && hMenu != hMenuRemove)
                CloseHandle(hMenu);
        }
    }
    
    return 1;
}

// ------------------------------------------------------------------------
// Cmd_Menu()
// ------------------------------------------------------------------------
// Shows menu to clients, if the client is able to: The plugin isn't set
// to admin only or his equipment is locked.
// ------------------------------------------------------------------------
public Action:Cmd_Menu(Client, Args)
{
    // Not allowed if not ingame.
    if (Client == 0) { ReplyToCommand(Client, "[TF2] Command is in-game only."); return Plugin_Handled; }
    
    // Check if the user doesn't have permission. If not, ignore command.
    if (!(PlayerFlags[Client] & PLAYER_ADMIN))
    {
        if (CfgAdminOnly)
        {
            CPrintToChat(Client, "%t", "Error_AccessLevel");
            return Plugin_Handled;
        }
        if (PlayerFlags[Client] & PLAYER_LOCK)
        {
            CPrintToChat(Client, "%t", "Error_EquipmentLocked");
            return Plugin_Handled;
        }
    }
    
    // Display menu.
    DisplayMenu(hMenuMain, Client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_EquipItem()
// ------------------------------------------------------------------------
// Force a client to equip an specific items.
// ------------------------------------------------------------------------
public Action:Cmd_EquipItem(Client, Args)
{
    if (Args < 2) { ReplyToCommand(Client, "[TF2] Usage: tf_equipment_equip <#id|name> <item name>."); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strItem[128];  GetCmdArg(2, strItem,   sizeof(strItem));
    new Item = -1;
    
    // Check if item exists and if so, grab index
    for (new i=0; i<ItemCount; i++)
        if (StrEqual(ItemName[i], strItem, false))
        {
            Item = i;
            break;
        }
    if (Item == -1) { ReplyToCommand(Client, "[TF2] Unknown item : \"%s\"", strItem); return Plugin_Handled; }
    
    // Process the targets 
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl TargetList[MAXPLAYERS], TargetCount;
    decl bool:TargetTranslate;
    
    if ((TargetCount = ProcessTargetString(strTarget, Client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
                                           strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
    {
        ReplyToTargetError(Client, TargetCount);
        return Plugin_Handled;
    }

    // Apply to all targets
    for (new i = 0; i < TargetCount; i++)
    {
        if (!IsClientConnected(TargetList[i])) continue;
        if (!IsClientInGame(TargetList[i]))    continue;
        
        // If item isn't wearable, for the client.
        if (!Item_IsWearable(TargetList[i], Item)) {
            decl String:strName[64]; GetClientName(TargetList[i], strName, sizeof(strName));
            CPrintToChat(Client, "%t", "Error_CantWear", strName);  
            continue;
        }
        
        // Equip item and tell to client.
        Item_Equip(TargetList[i], Item);
        CPrintToChat(TargetList[i], "%t", "Message_ForcedEquip", ItemName[Item], ItemSlot[Item]+1);  
    }
    
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_RemoveItem()
// ------------------------------------------------------------------------
public Action:Cmd_RemoveItem(Client, Args)
{
    // Determine if the number of arguments is valid
    if (Args < 2) { ReplyToCommand(Client, "[TF2] Usage: tf_equipment_remove <#id|name> <slot>."); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strSlot[8];    GetCmdArg(2, strSlot,   sizeof(strSlot));
    new Slot = StringToInt(strSlot)-1;
    
    // Check if it's a valid slot.
    if (Slot < 0 || Slot >= MAX_SLOTS) { ReplyToCommand(Client, "[TF2] Slot out of range : %i", Slot+1); return Plugin_Handled; }
    
    // Process the targets
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl TargetList[MAXPLAYERS], TargetCount;
    decl bool:TargetTranslate;
 
    if ((TargetCount = ProcessTargetString(strTarget, Client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
                                           strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
    {
        ReplyToTargetError(Client, TargetCount);
        return Plugin_Handled;
    }

    // Apply to all targets
    for (new i = 0; i < TargetCount; i++)
    {
        if (!IsClientConnected(TargetList[i])) continue;
        if (!IsClientInGame(TargetList[i]))    continue;
        
        Item_Remove(TargetList[i], Slot, 1);
        CPrintToChat(TargetList[i], "%t", "Message_ForcedRemove", Slot+1);  
    }
    
    // Done
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_LockEquipment()
// ------------------------------------------------------------------------
public Action:Cmd_LockEquipment(Client, Args)
{
    // Determine if the number of arguments is valid
    if (Args < 2) { ReplyToCommand(Client, "[TF2] Usage: tf_equipment_lock <#id|name> <state>"); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strState[8];   GetCmdArg(2, strState,  sizeof(strState));
    
    // Process the targets
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl TargetList[MAXPLAYERS], TargetCount;
    decl bool:TargetTranslate;
 
    if ((TargetCount = ProcessTargetString(strTarget, Client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
                                           strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
    {
        ReplyToTargetError(Client, TargetCount);
        return Plugin_Handled;
    }

    // Apply to all targets
    new State = StringToInt(strState);
    if (State == 1) 
        for (new i = 0; i < TargetCount; i++)
        {
            if (!IsClientConnected(TargetList[i])) continue;
            if (!IsClientInGame(TargetList[i]))    continue;
            if (PlayerFlags[TargetList[i]] & PLAYER_ADMIN) continue;
            
            PlayerFlags[TargetList[i]] |= PLAYER_LOCK;
            CPrintToChat(TargetList[i], "%t", "Message_Locked");  
        }
    else
        for (new i = 0; i < TargetCount; i++)
        {
            if (!IsClientConnected(TargetList[i])) continue;
            if (!IsClientInGame(TargetList[i]))    continue;
            if (PlayerFlags[TargetList[i]] & PLAYER_ADMIN) continue;
            
            PlayerFlags[TargetList[i]] &= ~PLAYER_LOCK;
            CPrintToChat(TargetList[i], "%t", "Message_Unlocked");  
        }
        
    // Done
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_OverrideEquipment()
// ------------------------------------------------------------------------
public Action:Cmd_OverrideEquipment(Client, Args)
{
    // Determine if the number of arguments is valid
    if (Args < 2) { ReplyToCommand(Client, "[TF2] Usage: tf_equipment_override <#id|name> <state>"); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strState[8];   GetCmdArg(2, strState,  sizeof(strState));
    
    // Process the targets
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl TargetList[MAXPLAYERS], TargetCount;
    decl bool:TargetTranslate;
 
    if ((TargetCount = ProcessTargetString(strTarget, Client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
                                           strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
    {        
        ReplyToTargetError(Client, TargetCount);
        return Plugin_Handled;
    }

    // Apply to all targets
    new State = StringToInt(strState);
    
    if (State == 1) 
        for (new i = 0; i < TargetCount; i++)
        {
            if (!IsClientConnected(TargetList[i])) continue;
            if (!IsClientInGame(TargetList[i]))    continue;
        
            PlayerFlags[TargetList[i]] |= PLAYER_OVERRIDE;
            CPrintToChat(TargetList[i], "%t", "Message_Override_On");  
        }
    else
        for (new i = 0; i < TargetCount; i++)
        {
            if (!IsClientConnected(TargetList[i])) continue;
            if (!IsClientInGame(TargetList[i]))    continue;
            
            PlayerFlags[TargetList[i]] &= ~PLAYER_OVERRIDE;
            CPrintToChat(TargetList[i], "%t", "Message_Override_Off");  
        }
    
    // Done
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_Reload()
// ------------------------------------------------------------------------
public Action:Cmd_Reload(Client, Args)
{
    // Reparse item list
    Item_ParseList();
    
    // Re-read admins flags
    new ibFlags = ReadFlagString(CfgAdminFlags);
    for (new i=1; i<=MaxClients; i++)
    {    
        if (!IsClientConnected(i)) continue;
        if (!IsClientInGame(i))    continue;
    
        PlayerFlags[Client] &= ~PLAYER_ADMIN;
        if (GetUserFlagBits(i) & ibFlags)      PlayerFlags[i] |= PLAYER_ADMIN;
        if (GetUserFlagBits(i) & ADMFLAG_ROOT) PlayerFlags[i] |= PLAYER_ADMIN;
    }

    // Done
    return Plugin_Handled;
}



// ------------------------------------------------------------------------
// Timer_Welcome
// ------------------------------------------------------------------------
public Action:Timer_Welcome(Handle:hTimer, any:Client)
{
	if (IsClientConnected(Client) && IsClientInGame(Client))
	{
		CPrintToChat(Client, "%t", "Announce_Plugin", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	}
    return Plugin_Stop;
}

// ------------------------------------------------------------------------
// Timer_Announce
// ------------------------------------------------------------------------
public Action:Timer_Announce(Handle:hTimer)
{
    if (!CfgAnnounce) return Plugin_Continue;

    if (CfgAdminOnly)
    {
        for (new i=1; i<=MaxClients; i++)
        {
            if (!IsClientConnected(i)) continue;
            if (!IsClientInGame(i))    continue;
    
            if (!(PlayerFlags[i] & PLAYER_ADMIN)) continue;
            CPrintToChat(i, "%t", "Announce_Command");
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
    for (new i=0; i<Length; i++)
    {
        switch(strBuffer[i])
        {
            case '\r': strBuffer[i] = ' ';
            case '\n': strBuffer[i] = ' ';
            case '\t': strBuffer[i] = ' ';
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
// TF2_SdkStartup
// ------------------------------------------------------------------------
stock TF2_SpawnWearable(iOwner, iDef=52, iLevel=99, iQuality=3)
{
    new iTeam = GetClientTeam(iOwner);
    new iItem = CreateEntityByName("tf_wearable_item");
    
    if (IsValidEdict(iItem))
    {
        SetEntProp(iItem, Prop_Send, "m_bInitialized", 1);

        // Using reference data from Batter's Helmet. Thanks to MrSaturn.
        SetEntProp(iItem, Prop_Send, "m_fEffects",             EF_BONEMERGE|EF_BONEMERGE_FASTCULL|EF_NOSHADOW);
        SetEntProp(iItem, Prop_Send, "m_iTeamNum",             iTeam);
        SetEntProp(iItem, Prop_Send, "m_nSkin",                (iTeam-2));
        SetEntProp(iItem, Prop_Send, "m_CollisionGroup",       11);
        SetEntProp(iItem, Prop_Send, "m_iItemDefinitionIndex", iDef);
        SetEntProp(iItem, Prop_Send, "m_iEntityLevel",         iLevel);
        SetEntProp(iItem, Prop_Send, "m_iEntityQuality",       iQuality);
        
        // Spawn and change model
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
    
    if (TF2_IsEntityWearable(iItem))
    {
        SDKCall(g_hSdkEquipWearable, iOwner, iItem);
    }
    else
    {
        LogMessage("Error: Item %i isn't a valid wearable.", iItem);
    }
}

// ------------------------------------------------------------------------
// TF2_RemoveWearable
// ------------------------------------------------------------------------
stock TF2_RemoveWearable(iOwner, iItem)
{
    if (g_bSdkStarted == false) TF2_SdkStartup();
    
    if (TF2_IsEntityWearable(iItem))
    {
        if (GetEntPropEnt(iItem, Prop_Send, "m_hOwnerEntity") == iOwner)
        {
            SDKCall(g_hSdkRemoveWearable, iOwner, iItem);
        }
		RemoveEdict(iItem);
    }
}

// ------------------------------------------------------------------------
// TF2_IsEntityWearable
// ------------------------------------------------------------------------
stock bool:TF2_IsEntityWearable(iEntity)
{
    if (iEntity > 0)
    {
        if (IsValidEdict(iEntity))
        {
            new String:strClassname[32];
            GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
            
            return StrEqual(strClassname, "tf_wearable_item", false);
        }
    }
    
    return false;
}