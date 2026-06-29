/**
 * Dual Primaries (L4D2 version)
 * Fixed to properly save weapon states including ammo and attachments
 * The code was attempting to access the m_iAmmo array with invalid indices (negative or >= 32)
 * The m_iAmmo property has exactly 32 elements (indices 0-31) 
 * So any index outside this range causes an exception
 * Dunno why i decided to fix this as i usual a different one that works better.
 */

#include <sourcemod>
#include <sdktools>
#include <keyvalues>
#include <sdkhooks>

#define MAX_PLAYERS 33
#define CONFIG_PATH "addons/sourcemod/data/dualprimaries_weapons.cfg"

public Plugin myinfo = 
{
    name = "Dual Primaries",
    author = "DrStr4Nge147 - Fixed By Dominatez",
    description = "Allows players to carry two primary weapons in L4D2 with persistence across maps",
    version = "1.5.8"
};

// Weapon state structure
enum struct WeaponState
{
    char classname[64];
    int clip;
    int ammo;
    int upgrades;
    bool hasLaser;
    bool hasIncendiary;
    bool hasExplosive;
    bool isValid;
}

WeaponState g_PrimarySlot1[MAX_PLAYERS];
WeaponState g_PrimarySlot2[MAX_PLAYERS];

// Global variables for tracking
char g_LastWeapon[MAX_PLAYERS][64];
int g_LastAmmo[MAX_PLAYERS];
bool g_IsWeaponSwitching[MAX_PLAYERS];
float g_LastSwitchTime[MAX_PLAYERS];
bool g_HadUpgradeAmmo[MAX_PLAYERS]; // Track if weapon had upgrade ammo in the previous check

// ConVars for toggles
ConVar g_cvDebugMode;
ConVar g_cvChatHints;
ConVar g_cvAutoSwitch;
ConVar g_cvAutoSwitchSpecial;
ConVar g_cvAllowDuplicates;
ConVar g_cvSwitchCooldown;
ConVar g_cvShowWelcome;
ConVar g_cvShowHUD; // New ConVar for HUD toggle

// Campaign and round tracking
bool g_IsCampaignRestart = false;
int g_RoundRestartCount = 0;
int g_LastRoundRestartTime = 0;

// Plugin version for tracking reloads
#define PLUGIN_VERSION "1.5.7"
char g_LastPluginVersion[32];

void DisplayWelcomeMessage()
{
    char duplicateStatus[64];
    if (g_cvAllowDuplicates.BoolValue)
        duplicateStatus = "\x04ENABLED\x01 - You can carry duplicate weapons";
    else
        duplicateStatus = "\x02DISABLED\x01 - No duplicate weapons allowed";
        
    char chatHintsStatus[64];
    if (g_cvChatHints.BoolValue)
        chatHintsStatus = "\x04ENABLED\x01 - You will see chat notifications";
    else
        chatHintsStatus = "\x02DISABLED\x01 - No chat notifications";
    
    char hudStatus[64];
    if (g_cvShowHUD.BoolValue)
        hudStatus = "\x04ENABLED\x01 - HUD indicator is on";
    else
        hudStatus = "\x02DISABLED\x01 - HUD indicator is off";
    
    PrintToChatAll("\x04[DUAL PRIMARIES] \x01v%s | Duplicates: %s | Hints: %s | HUD: %s", 
        PLUGIN_VERSION,
        duplicateStatus,
        chatHintsStatus,
        hudStatus);
}

void UpdateHUD(int client)
{
    if (!g_cvShowHUD.BoolValue || !IsClientInGame(client) || IsFakeClient(client))
        return;
        
    char hudText[256];
    char weaponName1[64] = "None";
    char weaponName2[64] = "None";
    
    // Get weapon names
    if (g_PrimarySlot1[client].isValid)
    {
        GetWeaponDisplayName(g_PrimarySlot1[client].classname, weaponName1, sizeof(weaponName1));
        if (g_PrimarySlot1[client].clip > 0)
            Format(weaponName1, sizeof(weaponName1), "%s (%d)", weaponName1, g_PrimarySlot1[client].clip);
    }
    
    if (g_PrimarySlot2[client].isValid)
    {
        GetWeaponDisplayName(g_PrimarySlot2[client].classname, weaponName2, sizeof(weaponName2));
        if (g_PrimarySlot2[client].clip > 0)
            Format(weaponName2, sizeof(weaponName2), "%s (%d)", weaponName2, g_PrimarySlot2[client].clip);
    }
    
    // Format HUD text - Show only stored weapons
    Format(hudText, sizeof(hudText), "Stored Weapons:\n1. %s\n2. %s", 
        weaponName1, 
        weaponName2);
    
    // Display HUD
    PrintHintText(client, hudText);
}

void GetWeaponDisplayName(const char[] classname, char[] displayName, int maxlen)
{
    if (StrEqual(classname, "weapon_rifle")) strcopy(displayName, maxlen, "M16");
    else if (StrEqual(classname, "weapon_rifle_ak47")) strcopy(displayName, maxlen, "AK-47");
    else if (StrEqual(classname, "weapon_rifle_desert")) strcopy(displayName, maxlen, "Desert Rifle");
    else if (StrEqual(classname, "weapon_rifle_sg552")) strcopy(displayName, maxlen, "SG552");
    else if (StrEqual(classname, "weapon_smg")) strcopy(displayName, maxlen, "SMG");
    else if (StrEqual(classname, "weapon_smg_silenced")) strcopy(displayName, maxlen, "Silenced SMG");
    else if (StrEqual(classname, "weapon_smg_mp5")) strcopy(displayName, maxlen, "MP5");
    else if (StrEqual(classname, "weapon_pumpshotgun")) strcopy(displayName, maxlen, "Pump Shotgun");
    else if (StrEqual(classname, "weapon_shotgun_chrome")) strcopy(displayName, maxlen, "Chrome Shotgun");
    else if (StrEqual(classname, "weapon_autoshotgun")) strcopy(displayName, maxlen, "Auto Shotgun");
    else if (StrEqual(classname, "weapon_shotgun_spas")) strcopy(displayName, maxlen, "SPAS-12");
    else if (StrEqual(classname, "weapon_hunting_rifle")) strcopy(displayName, maxlen, "Hunting Rifle");
    else if (StrEqual(classname, "weapon_sniper_military")) strcopy(displayName, maxlen, "Military Sniper");
    else if (StrEqual(classname, "weapon_sniper_scout")) strcopy(displayName, maxlen, "Scout");
    else if (StrEqual(classname, "weapon_sniper_awp")) strcopy(displayName, maxlen, "AWP");
    else if (StrEqual(classname, "weapon_rifle_m60")) strcopy(displayName, maxlen, "M60");
    else if (StrEqual(classname, "weapon_grenade_launcher")) strcopy(displayName, maxlen, "Grenade Launcher");
    else 
    {
        // Default: remove 'weapon_' prefix and format nicely
        strcopy(displayName, maxlen, classname);
        ReplaceString(displayName, maxlen, "weapon_", "", false);
        ReplaceString(displayName, maxlen, "_", " ", false);
        
        // Capitalize first letter of each word
        bool capitalize = true;
        for (int i = 0; i < strlen(displayName); i++)
        {
            if (capitalize)
            {
                displayName[i] = CharToUpper(displayName[i]);
                capitalize = false;
            }
            else if (displayName[i] == ' ')
            {
                capitalize = true;
            }
        }
    }
}

public Action Cmd_DualHelp(int client, int args)
{
    if (client == 0)
    {
        PrintToServer("Dual Primaries Commands:");
        PrintToServer("!storeprimary - Store your current primary weapon");
        PrintToServer("!switchprimary - Switch between stored weapons");
        PrintToServer("bind <key> \"sm_switchprimary\" - Bind a key to switch weapons");
        return Plugin_Handled;
    }
    
    PrintToChat(client, "\x04[DUAL PRIMARIES] \x01Commands:");
    PrintToChat(client, "\x04!storeprimary \x01- Store current primary");
    PrintToChat(client, "\x04!switchprimary \x01- Switch between weapons");
    PrintToChat(client, "\x04bind <key> \"sm_switchprimary\" \x01- Bind a key to switch");
    
    return Plugin_Handled;
}

public Action Cmd_DualInfo(int client, int args)
{
    if (client == 0) // Command was executed from server console
    {
        // Display message to all players
        CreateTimer(0.1, Timer_DisplayWelcomeMessage, _, TIMER_FLAG_NO_MAPCHANGE);
        PrintToServer("Dual Primaries info has been displayed to all players.");
    }
    else // Command was executed by a player
    {
        DisplayWelcomeMessage();
    }
    return Plugin_Handled;
}

public void OnPluginStart()
{
    // Create ConVars for toggles
    g_cvDebugMode = CreateConVar("sm_dualprimary_debug", "0", "Enable debug output (0=disabled, 1=verbose, 2=debug)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
    g_cvChatHints = CreateConVar("sm_dualprimary_chathints", "0", "Enable chat notifications (0=disabled, 1=enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvAllowDuplicates = CreateConVar("sm_dualprimary_allowduplicates", "0", "Allow carrying duplicate weapons (0=disabled, 1=enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvShowHUD = CreateConVar("sm_dualprimary_showhud", "1", "Show HUD indicator for stored weapons (0=disabled, 1=enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvSwitchCooldown = CreateConVar("sm_dualprimary_cooldown", "1", "Cooldown between weapon switches (in seconds)", FCVAR_NOTIFY, true, 0.1, true, 5.0);
    g_cvShowWelcome = CreateConVar("sm_dualprimary_showwelcome", "1", "Show welcome message on plugin load (0=disabled, 1=enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvAutoSwitch = CreateConVar("sm_dualprimary_autoswitch", "1", "Auto-switch to other primary when ammo is depleted (0=disabled, 1=enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvAutoSwitchSpecial = CreateConVar("sm_dualprimary_autoswitch_special", "1", "Auto-switch special weapons when ammo is depleted and dropped (M60/Grenade Launcher) (0=disabled, 1=enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    // Show welcome message if this is the first load or a reload
    if (!StrEqual(g_LastPluginVersion, PLUGIN_VERSION))
    {
        strcopy(g_LastPluginVersion, sizeof(g_LastPluginVersion), PLUGIN_VERSION);
        if (g_cvShowWelcome.BoolValue)
        {
            CreateTimer(5.0, Timer_DisplayWelcomeMessage, _, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    
    // Register admin commands with proper flags
    RegAdminCmd("sm_switchprimary", Cmd_SwitchPrimary, ADMFLAG_ROOT, "Switch between two primaries");
    RegAdminCmd("sm_storeprimary", Cmd_StorePrimary, ADMFLAG_ROOT, "Manually store current primary weapon");
    RegAdminCmd("sm_primarystatus", Cmd_PrimaryStatus, ADMFLAG_ROOT, "Show stored primary weapons");
    
        // Add client commands
    RegConsoleCmd("sm_dualinfo", Cmd_DualInfo, "Show dual primary weapons information");
    RegConsoleCmd("dualinfo", Cmd_DualInfo, "Show dual primary weapons information (bindable)");
    
    // Add help command
    RegConsoleCmd("sm_dualhelp", Cmd_DualHelp, "Show dual primary weapons help");
    RegConsoleCmd("dualhelp", Cmd_DualHelp, "Show dual primary weapons help (bindable)");
    
    RegAdminCmd("switchprimary", Cmd_SwitchPrimary, ADMFLAG_ROOT, "Switch between two primaries (bindable)");
    RegAdminCmd("storeprimary", Cmd_StorePrimary, ADMFLAG_ROOT, "Manually store current primary weapon (bindable)");
    RegAdminCmd("primarystatus", Cmd_PrimaryStatus, ADMFLAG_ROOT, "Show stored primary weapons (bindable)");
    
    // Add server commands for console use
    RegServerCmd("sm_switchprimary_server", Cmd_SwitchPrimary_Server, "Switch primary weapons from server console");
    RegServerCmd("sm_storeprimary_server", Cmd_StorePrimary_Server, "Store primary weapon from server console");
    RegServerCmd("sm_primarystatus_server", Cmd_PrimaryStatus_Server, "Show primary status from server console");
    
    HookEvent("weapon_drop", Event_WeaponDrop);
    HookEvent("item_pickup", Event_ItemPickup);
    HookEvent("weapon_pickup", Event_WeaponPickup);
    
    // Hook round and campaign events
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("map_transition", Event_MapTransition);
    HookEvent("finale_win", Event_FinaleWin);
    HookEvent("mission_lost", Event_MissionLost);
    
    // Precache sounds
    PrecacheSound("items/itempickup.wav");
    PrecacheSound("buttons/button10.wav");
    HookEvent("player_death", Event_PlayerDeath);
    
    // Create a timer to check for ammo changes since itempickup event doesn't exist in L4D2
    CreateTimer(0.5, Timer_CheckAmmoChanges, _, TIMER_REPEAT);
    
    // Create a timer to periodically check for weapon changes
    CreateTimer(1.0, Timer_CheckWeaponChanges, _, TIMER_REPEAT);
    
    // Auto-generate config file
    AutoExecConfig(true, "dualprimary");
    
    // Create data directory if it doesn't exist
    if (!DirExists("data"))
    {
        CreateDirectory("data", 511);
    }
}

public void OnClientPutInServer(int client)
{
    // Load from config if:
    // 1. Config file exists AND
    // 2. It's not a campaign restart AND
    // 3. We haven't detected multiple rapid restarts recently
    if (FileExists(CONFIG_PATH) && !g_IsCampaignRestart && g_RoundRestartCount < 2)
    {
        // Delay loading slightly to ensure client is fully connected
        DataPack pack = new DataPack();
        pack.WriteCell(GetClientUserId(client));
        CreateTimer(0.5, Timer_LoadWeaponState, pack, TIMER_FLAG_NO_MAPCHANGE);
        
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Will load weapon state from config");
    }
    else
    {
        ClearWeaponState(g_PrimarySlot1[client]);
        ClearWeaponState(g_PrimarySlot2[client]);
        
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Clean slate - no config loading (Campaign restart: %s, Restart count: %d)", 
                g_IsCampaignRestart ? "Yes" : "No", g_RoundRestartCount);
    }
    g_LastAmmo[client] = -1;
    g_IsWeaponSwitching[client] = false;
}

public void OnMapStart()
{
    // Don't immediately reset campaign restart flag - let it persist for a bit
    // Only reset if it's been more than 10 seconds since last round restart
    int currentTime = GetTime();
    if (currentTime - g_LastRoundRestartTime > 10)
    {
        g_IsCampaignRestart = false;
        g_RoundRestartCount = 0;
        if (g_cvDebugMode.BoolValue)
            PrintToServer("[DualPrimaries] Map started - reset campaign restart flags (clean transition)");
    }
    else
    {
        if (g_cvDebugMode.BoolValue)
            PrintToServer("[DualPrimaries] Map started - keeping campaign restart flags (recent restart detected)");
    }
    
    // g_IsMapTransition is no longer used - we rely on config file existence instead
}

public Action Timer_DisplayWelcomeMessage(Handle timer)
{
    DisplayWelcomeMessage();
    return Plugin_Stop;
}

void ClearWeaponState(WeaponState weapon)
{
    weapon.classname[0] = '\0';
    weapon.clip = 0;
    weapon.ammo = 0;
    weapon.upgrades = 0;
    weapon.hasLaser = false;
    weapon.hasIncendiary = false;
    weapon.hasExplosive = false;
    weapon.isValid = false;
}

void CopyWeaponState(WeaponState source, WeaponState dest)
{
    strcopy(dest.classname, sizeof(dest.classname), source.classname);
    dest.clip = source.clip;
    dest.ammo = source.ammo;
    dest.upgrades = source.upgrades;
    dest.hasLaser = source.hasLaser;
    dest.hasIncendiary = source.hasIncendiary;
    dest.hasExplosive = source.hasExplosive;
    dest.isValid = source.isValid;
}

void SaveCurrentWeaponState(int client, WeaponState weapon)
{
    int currentWeapon = GetPlayerWeaponSlot(client, 0);
    if (currentWeapon > 0 && IsValidEntity(currentWeapon))
    {
        SaveWeaponState(currentWeapon, weapon);
        
        // If the weapon has upgrade ammo, make sure to save that too
        int upgradeBitVec = GetEntProp(currentWeapon, Prop_Send, "m_upgradeBitVec");
        if (upgradeBitVec & (1 << 0) || upgradeBitVec & (1 << 1))
        {
            // The weapon has either incendiary or explosive ammo
            weapon.ammo = GetEntProp(currentWeapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
            weapon.hasIncendiary = (upgradeBitVec & (1 << 0)) ? true : false;
            weapon.hasExplosive = (upgradeBitVec & (1 << 1)) ? true : false;
        }
        else
        {
            // No upgrade ammo, clear the flags
            weapon.hasIncendiary = false;
            weapon.hasExplosive = false;
        }
    }
    else
    {
        ClearWeaponState(weapon);
    }
}

void SaveWeaponState(int weaponEntity, WeaponState weapon)
{
    if (weaponEntity <= 0 || !IsValidEntity(weaponEntity))
    {
        ClearWeaponState(weapon);
        return;
    }
    
    int owner = GetEntPropEnt(weaponEntity, Prop_Send, "m_hOwnerEntity");
    if (owner <= 0 || owner > MaxClients)
    {
        ClearWeaponState(weapon);
        return;
    }
    
    GetEntityClassname(weaponEntity, weapon.classname, sizeof(weapon.classname));
    weapon.clip = GetEntProp(weaponEntity, Prop_Send, "m_iClip1");
    
    // Get reserve ammo from the player, not the weapon
    int ammoType = GetEntProp(weaponEntity, Prop_Send, "m_iPrimaryAmmoType");
    if (ammoType >= 0)
    {
        weapon.ammo = GetEntProp(owner, Prop_Send, "m_iAmmo", _, ammoType);
        
        // Save upgrade ammo count if applicable
        int upgradeBitVec = GetEntProp(weaponEntity, Prop_Send, "m_upgradeBitVec");
        if (upgradeBitVec & (1 << 0)) // Incendiary ammo
        {
            weapon.hasIncendiary = true;
            weapon.hasExplosive = false;
            weapon.ammo = GetEntProp(weaponEntity, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
        }
        else if (upgradeBitVec & (1 << 1)) // Explosive ammo
        {
            weapon.hasExplosive = true;
            weapon.hasIncendiary = false;
            weapon.ammo = GetEntProp(weaponEntity, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
        }
        else
        {
            weapon.hasIncendiary = false;
            weapon.hasExplosive = false;
        }
    }
    else
    {
        weapon.ammo = 0;
        weapon.hasIncendiary = false;
        weapon.hasExplosive = false;
    }
    
    weapon.upgrades = GetEntProp(weaponEntity, Prop_Send, "m_upgradeBitVec");
    weapon.hasLaser = (weapon.upgrades & (1 << 2)) ? true : false;
    weapon.isValid = true;
}

int RestoreWeaponState(int client, WeaponState weapon)
{
    if (!weapon.isValid || weapon.classname[0] == '\0')
        return -1;
    
    int newWeapon = GivePlayerItem(client, weapon.classname);
    if (newWeapon > 0 && IsValidEntity(newWeapon))
    {
        SetEntProp(newWeapon, Prop_Send, "m_iClip1", weapon.clip);
        
        // Get the ammo type for this weapon
        int ammoType = GetEntProp(newWeapon, Prop_Send, "m_iPrimaryAmmoType");
        
        // Apply upgrade ammo if needed
        if (weapon.hasIncendiary || weapon.hasExplosive)
        {
            int newUpgradeBitVec = GetEntProp(newWeapon, Prop_Send, "m_upgradeBitVec");
            
            if (weapon.hasIncendiary)
            {
                newUpgradeBitVec |= (1 << 0);  // Set incendiary bit
                newUpgradeBitVec &= ~(1 << 1); // Clear explosive bit
            }
            else if (weapon.hasExplosive)
            {
                newUpgradeBitVec |= (1 << 1);  // Set explosive bit
                newUpgradeBitVec &= ~(1 << 0); // Clear incendiary bit
            }
            
            // Apply the upgrade bit vector and ammo count
            SetEntProp(newWeapon, Prop_Send, "m_upgradeBitVec", newUpgradeBitVec);
            
            // Only set the upgraded ammo if we have some left
            if (weapon.ammo > 0)
            {
                // First, clear any existing upgrade ammo to prevent stacking
                newUpgradeBitVec = GetEntProp(newWeapon, Prop_Send, "m_upgradeBitVec");
                newUpgradeBitVec &= ~(1 << 0); // Clear incendiary bit
                newUpgradeBitVec &= ~(1 << 1); // Clear explosive bit
                
                // Set the appropriate upgrade bit
                if (weapon.hasIncendiary)
                    newUpgradeBitVec |= (1 << 0);
                else if (weapon.hasExplosive)
                    newUpgradeBitVec |= (1 << 1);
                    
                SetEntProp(newWeapon, Prop_Send, "m_upgradeBitVec", newUpgradeBitVec);
                SetEntProp(newWeapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", weapon.ammo);
                
                // Make sure we have ammo in reserve for the upgrade type
                if (ammoType >= 0)
                {
                    // Only give ammo if we're actually low
                    int currentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
                    if (currentAmmo <= 0)
                    {
                        // Give a small amount of ammo to prevent infinite ammo exploit
                        SetEntProp(client, Prop_Send, "m_iAmmo", GetMaxAmmoForWeapon(weapon.classname) / 4, _, ammoType);
                    }
                }
            }
            else
            {
                // No more upgrade ammo, revert to regular ammo
                newUpgradeBitVec &= ~(1 << 0); // Clear incendiary bit
                newUpgradeBitVec &= ~(1 << 1); // Clear explosive bit
                SetEntProp(newWeapon, Prop_Send, "m_upgradeBitVec", newUpgradeBitVec);
                
                // Restore the clip to the last known value
                SetEntProp(newWeapon, Prop_Send, "m_iClip1", weapon.clip);
                
                // Make sure we have some regular ammo in reserve
                if (ammoType >= 0)
                {
                    int currentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
                    if (currentAmmo <= 0)
                    {
                        SetEntProp(client, Prop_Send, "m_iAmmo", GetMaxAmmoForWeapon(weapon.classname) / 2, _, ammoType);
                    }
                }
                
                // We're done here, return the weapon
                return newWeapon;
            }
        }
        else
        {
            // No upgrade ammo, just set the normal upgrades (like laser sight)
            SetEntProp(newWeapon, Prop_Send, "m_upgradeBitVec", weapon.upgrades & ~(1 << 0) & ~(1 << 1));
        }
        
        // Set ammo in reserve if we're not using upgrade ammo
        if (ammoType >= 0 && !weapon.hasIncendiary && !weapon.hasExplosive)
        {
            SetEntProp(client, Prop_Send, "m_iAmmo", weapon.ammo, _, ammoType);
        }
    }
    
    return newWeapon;
}

// ----------------------
// ITEM PICKUP
// ----------------------
public void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;

    char item[64];
    event.GetString("item", item, sizeof(item));
    
    if (g_cvDebugMode.BoolValue)
        PrintToChat(client, "[DEBUG] Item pickup detected: %s", item);

    if (IsPrimaryWeapon(item))
    {
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Primary weapon pickup detected: %s", item);
        
        // Use a timer to handle weapon storage after pickup is complete
        DataPack pack = new DataPack();
        pack.WriteCell(GetClientUserId(client));
        pack.WriteString(item);
        CreateTimer(0.1, Timer_HandleWeaponPickup, pack, TIMER_FLAG_NO_MAPCHANGE);
    }
}

// ----------------------
// WEAPON PICKUP
// ----------------------
public void Event_WeaponPickup(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;

    char weapon[64];
    event.GetString("weapon", weapon, sizeof(weapon));
    
    if (g_cvDebugMode.BoolValue)
        PrintToChat(client, "[DEBUG] Weapon pickup detected: %s", weapon);

    if (IsPrimaryWeapon(weapon))
    {
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Primary weapon pickup detected: %s", weapon);
        
        // Use a timer to handle weapon storage after pickup is complete
        DataPack pack = new DataPack();
        pack.WriteCell(GetClientUserId(client));
        pack.WriteString(weapon);
        CreateTimer(0.1, Timer_HandleWeaponPickup, pack, TIMER_FLAG_NO_MAPCHANGE);
    }
}

// ----------------------
// PERIODIC WEAPON CHECK
// ----------------------

public Action Timer_CheckWeaponChanges(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || !IsPlayerAlive(client))
            continue;
            
        int weapon = GetPlayerWeaponSlot(client, 0);
        if (weapon <= 0 || !IsValidEntity(weapon))
            continue;
            
        char currentWeapon[64];
        GetEntityClassname(weapon, currentWeapon, sizeof(currentWeapon));
        
        if (!IsPrimaryWeapon(currentWeapon))
            continue;
            
        // Check if weapon changed
        if (!StrEqual(g_LastWeapon[client], currentWeapon, false))
        {
            if (g_LastWeapon[client][0] != '\0') // Had a previous weapon
            {
                if (g_cvDebugMode.BoolValue)
                    PrintToChat(client, "[DEBUG] Weapon change detected: %s -> %s", g_LastWeapon[client], currentWeapon);
                
                // Only handle weapon change if auto-switch is enabled or we're not currently switching weapons
                if (g_cvAutoSwitch.BoolValue || !g_IsWeaponSwitching[client]) {
                    if (g_cvDebugMode.BoolValue) {
                        PrintToChat(client, "[DEBUG] Processing weapon change: %s -> %s (Auto-switch: %s)", 
                            g_LastWeapon[client], currentWeapon, 
                            g_cvAutoSwitch.BoolValue ? "enabled" : "disabled");
                    }
                    
                    DataPack pack = new DataPack();
                    pack.WriteCell(GetClientUserId(client));
                    pack.WriteString(currentWeapon);
                    CreateTimer(0.1, Timer_HandleWeaponPickup, pack, TIMER_FLAG_NO_MAPCHANGE);
                } else if (g_cvDebugMode.BoolValue) {
                    PrintToChat(client, "[DEBUG] Skipping weapon change - auto-switch is disabled");
                }
            }
            
            strcopy(g_LastWeapon[client], sizeof(g_LastWeapon[]), currentWeapon);
        }
    }
    
    return Plugin_Continue;
}

public Action Timer_CheckAmmoChanges(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || !IsPlayerAlive(client))
            continue;
            
        int weapon = GetPlayerWeaponSlot(client, 0);
        if (weapon <= 0 || !IsValidEntity(weapon))
            continue;
            
        char currentWeapon[64];
        GetEntityClassname(weapon, currentWeapon, sizeof(currentWeapon));
        
        if (!IsPrimaryWeapon(currentWeapon))
            continue;
            
        // Get current ammo
        int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
        // FIXED: Validate ammo type is within bounds (0-31 for 32 element array)
        if (ammoType < 0 || ammoType >= 32) 
        {
            if (g_cvDebugMode.BoolValue)
                PrintToChat(client, "[DEBUG] Invalid ammo type: %d (out of bounds 0-31)", ammoType);
            continue;
        }
        
        int currentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
        
        // Check for upgrade ammo
        int upgradeBitVec = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
        bool hasUpgradeAmmo = (upgradeBitVec & (1 << 0)) || (upgradeBitVec & (1 << 1));
        
        // Get current clip ammo and check if weapon is being reloaded
        int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
        bool isReloading = view_as<bool>(GetEntProp(weapon, Prop_Send, "m_bInReload"));
        
        if (g_cvDebugMode.BoolValue && clip <= 0 && currentAmmo <= 0) {
            PrintToChat(client, "[DEBUG] Weapon empty - Clip: %d, Reserve: %d, Reloading: %s, Switching: %s, LastAmmo: %d", 
                clip, currentAmmo, isReloading ? "yes" : "no", 
                g_IsWeaponSwitching[client] ? "yes" : "no", g_LastAmmo[client]);
        }
        
        // Check if current weapon is completely out of ammo (both clip and reserve)
        // and should auto-switch
        if (clip <= 0 && currentAmmo <= 0 && !isReloading && !g_IsWeaponSwitching[client]) {
            // Only auto-switch if we have another primary weapon available and it has ammo
            if (g_PrimarySlot1[client].isValid && g_PrimarySlot2[client].isValid) {
                // Check if the other weapon has any ammo
                bool otherWeaponHasAmmo = false;
                
                // Determine which slot we're currently using and check the other one
                bool usingSlot1 = StrEqual(currentWeapon, g_PrimarySlot1[client].classname, false);
                
                if (usingSlot1) {
                    // Check if slot 2 has ammo
                    otherWeaponHasAmmo = (g_PrimarySlot2[client].ammo > 0 || g_PrimarySlot2[client].clip > 0);
                } else {
                    // Check if slot 1 has ammo
                    otherWeaponHasAmmo = (g_PrimarySlot1[client].ammo > 0 || g_PrimarySlot1[client].clip > 0);
                }
                
                if (!otherWeaponHasAmmo) {
                    if (g_cvDebugMode.BoolValue) {
                        PrintToChat(client, "[DEBUG] Both primary weapons are empty - not switching");
                    }
                    continue;
                }
                
                // Only auto-switch if enabled in settings
                if (g_cvAutoSwitch.BoolValue) {
                    // Switch to the other primary weapon
                    if (usingSlot1) {
                        if (g_cvDebugMode.BoolValue) {
                            PrintToChat(client, "[DEBUG] Auto-switching to secondary primary (completely out of ammo)");
                        }
                        FakeClientCommand(client, "sm_switchprimary");
                    } else if (!usingSlot1) {
                        if (g_cvDebugMode.BoolValue) {
                            PrintToChat(client, "[DEBUG] Auto-switching to primary weapon (completely out of ammo)");
                        }
                        FakeClientCommand(client, "sm_switchprimary");
                    }
                } else if (g_cvDebugMode.BoolValue) {
                    PrintToChat(client, "[DEBUG] Would auto-switch but auto-switch is disabled");
                }
                
                // Update last ammo and skip the rest of the ammo check to prevent multiple switches
                g_LastAmmo[client] = currentAmmo;
                g_IsWeaponSwitching[client] = true;
                CreateTimer(0.1, Timer_ResetWeaponSwitch, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                continue;
            }
        }
        
        // STRICT AMMO REPLENISHMENT RULES:
        // 1. Only trigger on actual ammo pickups (ammo increase without weapon change)
        // 2. Never trigger during weapon switches
        // 3. Never trigger when picking up new weapons
        
        // Debug info
        if (g_cvDebugMode.BoolValue && (g_LastAmmo[client] != currentAmmo || !StrEqual(g_LastWeapon[client], currentWeapon, false)))
        {
            bool isNewWeaponPickup = (g_LastAmmo[client] == -1 || currentAmmo > g_LastAmmo[client] + 20);
            
            PrintToChat(client, "[DEBUG] Ammo: %d -> %d | Weapon: %s | Last: %s | Switch: %s | Upgrade: %s | NewPickup: %s",
                g_LastAmmo[client], currentAmmo, currentWeapon, g_LastWeapon[client],
                g_IsWeaponSwitching[client] ? "yes" : "no",
                hasUpgradeAmmo ? "yes" : "no",
                isNewWeaponPickup ? "yes" : "no");
        }
        
        // Check for valid ammo pickup
        bool isSameWeapon = StrEqual(g_LastWeapon[client], currentWeapon, false);
        bool isAmmoIncrease = (g_LastAmmo[client] != -1 && currentAmmo > g_LastAmmo[client]);
        
        // Check if we just picked up a new weapon of the same type
        bool isNewWeaponPickup = (g_LastAmmo[client] == -1 || currentAmmo > g_LastAmmo[client] + 20);
        
        // Only trigger replenish if:
        // 1. We're not switching weapons
        // 2. We're still holding the same weapon
        // 3. Ammo actually increased slightly (not a full reload from weapon pickup)
        // 4. Not using upgraded ammo
        // 5. Not picking up a new weapon (even if same type)
        if (!g_IsWeaponSwitching[client] && 
            isSameWeapon && 
            isAmmoIncrease && 
            !hasUpgradeAmmo &&
            !isNewWeaponPickup)
        {
            if (g_cvDebugMode.BoolValue)
                PrintToChat(client, "[DEBUG] Strict ammo pickup detected: %d -> %d", 
                    g_LastAmmo[client], currentAmmo);
            
            ReplenishBothPrimaryWeapons(client);
        }
        else if (g_IsWeaponSwitching[client] && g_cvDebugMode.BoolValue)
        {
            PrintToChat(client, "[DEBUG] Ammo change ignored during weapon switching");
        }
        
        // Update tracking variables
        g_LastAmmo[client] = currentAmmo;
        g_HadUpgradeAmmo[client] = hasUpgradeAmmo;
    }
    
    return Plugin_Continue;
}

public Action Timer_HandleWeaponPickup(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    char newWeaponName[64];
    pack.ReadString(newWeaponName, sizeof(newWeaponName));
    delete pack;
    
    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;
    
    int currentWeapon = GetPlayerWeaponSlot(client, 0);
    if (currentWeapon <= 0 || !IsValidEntity(currentWeapon))
        return Plugin_Stop;
    
    char currentClassname[64];
    GetEntityClassname(currentWeapon, currentClassname, sizeof(currentClassname));
    
    // Check for duplicate weapon if restriction is enabled
    if (!g_cvAllowDuplicates.BoolValue && IsDuplicateWeapon(client, currentClassname))
    {
        // Only show duplicate message if not switching weapons
        if (g_cvChatHints.BoolValue && !g_IsWeaponSwitching[client])
            PrintToChat(client, "[DualPrimaries] Cannot store duplicate weapon");
        return Plugin_Stop;
    }
    
    // If we had a previous weapon stored in slot 1 and it's different from the new weapon
    if (g_PrimarySlot1[client].isValid && 
        !StrEqual(g_PrimarySlot1[client].classname, currentClassname, false))
    {
        // Only store the old weapon in slot 2 if slot 2 is empty
        if (!g_PrimarySlot2[client].isValid)
        {
            // Copy the old weapon from slot 1 to slot 2
            CopyWeaponState(g_PrimarySlot1[client], g_PrimarySlot2[client]);
            // Don't show stored message during weapon switching
            if (g_cvChatHints.BoolValue && !g_IsWeaponSwitching[client])
                PrintToChat(client, "[DualPrimaries] Stored %s", g_PrimarySlot2[client].classname);
        }
    }
    
    // Save the new weapon in slot 1
    SaveWeaponState(currentWeapon, g_PrimarySlot1[client]);
    
    // Only show equipped message if not switching weapons
    if (g_cvChatHints.BoolValue && !g_IsWeaponSwitching[client])
        PrintToChat(client, "[DualPrimaries] Equipped %s", currentClassname);
    
    // Save to config file in real-time
    SavePlayerWeaponStateToConfig(client);
    
    // Auto-switch to the new weapon if enabled and not already switching
    if (g_cvAutoSwitch.BoolValue && !g_IsWeaponSwitching[client]) {
        if (g_cvDebugMode.BoolValue) {
            PrintToChat(client, "[DEBUG] Auto-switching to newly equipped weapon (enabled: %s)", 
                g_cvAutoSwitch.BoolValue ? "yes" : "no");
        }
        CreateTimer(0.1, Timer_SwitchToOtherPrimary, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // Update HUD after storing
    if (g_cvShowHUD.BoolValue)
    {
        UpdateHUD(client);
    }
    
    return Plugin_Stop;
}

// Handle legacy ConVar changes
public void OnLegacyConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    char name[64];
    convar.GetName(name, sizeof(name));
    
    if (StrEqual(name, "sm_dualprimary_allow_duplicates"))
    {
        g_cvAllowDuplicates.BoolValue = convar.BoolValue;
    }
    else if (StrEqual(name, "sm_dualprimary_hints"))
    {
        g_cvChatHints.BoolValue = convar.BoolValue;
    }
}

// ----------------------
// DROP EVENT
// ----------------------
public void Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;

    int weapon = event.GetInt("propid");
    if (weapon <= 0) return;

    char classname[64];
    GetEntityClassname(weapon, classname, sizeof(classname));
    
    if (g_cvDebugMode.BoolValue) {
        PrintToChat(client, "[DEBUG] Weapon dropped: %s (IsPrimary: %s, IsSpecial: %s)", 
            classname, 
            IsPrimaryWeapon(classname) ? "yes" : "no",
            IsSpecialWeapon(classname) ? "yes" : "no");
            
        // Debug slot states
        PrintToChat(client, "[DEBUG] Slot1: %s (valid: %s)", 
            g_PrimarySlot1[client].isValid ? g_PrimarySlot1[client].classname : "none", 
            g_PrimarySlot1[client].isValid ? "yes" : "no");
        PrintToChat(client, "[DEBUG] Slot2: %s (valid: %s)", 
            g_PrimarySlot2[client].isValid ? g_PrimarySlot2[client].classname : "none", 
            g_PrimarySlot2[client].isValid ? "yes" : "no");
    }

    if (IsPrimaryWeapon(classname))
    {
        bool isSpecialWeapon = IsSpecialWeapon(classname);
        
        // For special weapons (M60/Grenade Launcher) that are auto-dropped when empty
        if (isSpecialWeapon) {
            // Clear the weapon state for the dropped special weapon
            bool wasInSlot1 = (g_PrimarySlot1[client].isValid && StrEqual(g_PrimarySlot1[client].classname, classname, false));
            bool wasInSlot2 = (g_PrimarySlot2[client].isValid && StrEqual(g_PrimarySlot2[client].classname, classname, false));
            
            if (wasInSlot1) {
                ClearWeaponState(g_PrimarySlot1[client]);
                if (g_cvDebugMode.BoolValue) {
                    PrintToChat(client, "[DEBUG] Cleared special weapon from slot 1");
                }
            } else if (wasInSlot2) {
                ClearWeaponState(g_PrimarySlot2[client]);
                if (g_cvDebugMode.BoolValue) {
                    PrintToChat(client, "[DEBUG] Cleared special weapon from slot 2");
                }
            }
            
            // For special weapons, force switch to the other primary weapon
            if (g_cvAutoSwitchSpecial.BoolValue && (g_PrimarySlot1[client].isValid || g_PrimarySlot2[client].isValid)) {
                if (g_cvDebugMode.BoolValue) {
                    PrintToChat(client, "[DEBUG] Special weapon dropped, forcing switch to other primary");
                }
                
                // Create a timer to handle the switch after a short delay
                // This ensures the weapon drop is fully processed first
                DataPack pack = new DataPack();
                pack.WriteCell(GetClientUserId(client));
                pack.WriteCell(true);  // Force switch for special weapons
                CreateTimer(0.2, Timer_ForceSwitchWeapon, pack, TIMER_FLAG_NO_MAPCHANGE);
            }
            
            // Save the updated state
            SavePlayerWeaponStateToConfig(client);
            return;
        }
        
        // Original behavior for regular primary weapons
        if (!g_PrimarySlot2[client].isValid && 
            g_PrimarySlot1[client].isValid && 
            !StrEqual(classname, g_PrimarySlot1[client].classname, false))
        {
            // Check for duplicate weapon if restriction is enabled
            if (!g_cvAllowDuplicates.BoolValue && IsDuplicateWeapon(client, classname))
            {
                if (g_cvChatHints.BoolValue)
                    PrintToChat(client, "[DualPrimaries] Cannot store duplicate weapon: %s (duplicate weapons disabled)", classname);
                return;
            }
            
            SaveWeaponState(weapon, g_PrimarySlot2[client]);
            if (g_cvChatHints.BoolValue)
                PrintToChat(client, "[DualPrimaries] Stored %s", classname);
            
            // Save to config file in real-time
            SavePlayerWeaponStateToConfig(client);
            
            // Auto-switch to the new weapon if enabled
            if (g_cvAutoSwitch.BoolValue) {
                if (g_cvDebugMode.BoolValue) {
                    PrintToChat(client, "[DEBUG] Auto-switching to newly stored weapon (enabled: %s)", 
                        g_cvAutoSwitch.BoolValue ? "yes" : "no");
                }
                CreateTimer(0.1, Timer_SwitchToOtherPrimary, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

// ----------------------
// TIMER: Force switch weapon (used for special weapons)
// ----------------------
public Action Timer_ForceSwitchWeapon(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());
    bool forceSwitch = view_as<bool>(pack.ReadCell());
    delete pack;
    
    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) {
        return Plugin_Stop;
    }
    
    // For special weapons, we want to switch to the other primary regardless of current weapon
    if (forceSwitch) {
        if (g_PrimarySlot1[client].isValid || g_PrimarySlot2[client].isValid) {
            if (g_cvDebugMode.BoolValue) {
                PrintToChat(client, "[DEBUG] Force switching to other primary weapon");
            }
            FakeClientCommand(client, "sm_switchprimary");
        }
        return Plugin_Stop;
    }
    
    return Plugin_Stop;
}

// ----------------------
// TIMER: Switch to other primary weapon (for regular weapons)
// ----------------------
public Action Timer_SwitchToOtherPrimary(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) {
        return Plugin_Stop;
    }
    
    // Don't switch if we're already holding a primary weapon
    int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (activeWeapon > 0) {
        char classname[64];
        GetEntityClassname(activeWeapon, classname, sizeof(classname));
        if (IsPrimaryWeapon(classname)) {
            if (g_cvDebugMode.BoolValue) {
                PrintToChat(client, "[DEBUG] Already holding a primary weapon, skipping auto-switch");
            }
            return Plugin_Stop;
        }
    }
    
    // Only switch if we have a valid weapon in slot 1
    if (g_PrimarySlot1[client].isValid) {
        if (g_cvDebugMode.BoolValue) {
            PrintToChat(client, "[DEBUG] Auto-switching to primary weapon from slot 1");
        }
        FakeClientCommand(client, "sm_switchprimary");
    }
    
    return Plugin_Stop;
}

// ----------------------
// TIMER: Reset Weapon Switch Flag
// ----------------------
public Action Timer_ResetWeaponSwitch(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && client <= MaxClients) {
        g_IsWeaponSwitching[client] = false;
        if (g_cvDebugMode.BoolValue) {
            PrintToChat(client, "[DEBUG] Weapon switch cooldown reset");
        }
    }
    return Plugin_Stop;
}

// ----------------------
// COOLDOWN MANAGEMENT
// ----------------------
void ResetCooldown(int client = 0)
{
    if (client > 0 && client <= MaxClients)
    {
        g_LastSwitchTime[client] = 0.0;
        if (g_cvDebugMode.BoolValue)
            PrintToServer("[DualPrimaries] Reset cooldown for client %N", client);
    }
    else
    {
        // Reset for all clients
        for (int i = 1; i <= MaxClients; i++)
        {
            g_LastSwitchTime[i] = 0.0;
        }
        if (g_cvDebugMode.BoolValue)
            PrintToServer("[DualPrimaries] Reset cooldowns for all clients");
    }
}

// ----------------------
// CAMPAIGN/ROUND EVENTS
// ----------------------
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // Reset cooldowns for all players at the start of a new round
    ResetCooldown();
    
    int currentTime = GetTime();
    
    // Check if this is a quick restart (within 8 seconds of last restart for more reliability)
    if (currentTime - g_LastRoundRestartTime < 8)
    {
        g_RoundRestartCount++;
        if (g_cvDebugMode.BoolValue)
            PrintToServer("[DualPrimaries] Quick round restart detected (count: %d, time diff: %d sec)", 
                g_RoundRestartCount, currentTime - g_LastRoundRestartTime);
    }
    else
    {
        // Reset count if it's been a while
        g_RoundRestartCount = 1;
        if (g_cvDebugMode.BoolValue)
            PrintToServer("[DualPrimaries] New round started (time diff: %d sec)", 
                currentTime - g_LastRoundRestartTime);
    }
    
    g_LastRoundRestartTime = currentTime;
    
    // If multiple quick restarts OR if there's no config file and this is a restart, it's likely a campaign restart
    if (g_RoundRestartCount >= 2 || (!FileExists(CONFIG_PATH) && g_RoundRestartCount > 1))
    {
        g_IsCampaignRestart = true;
        if (g_cvDebugMode.BoolValue)
            PrintToServer("[DualPrimaries] Campaign restart detected - clearing weapon states (restarts: %d, config exists: %s)", 
                g_RoundRestartCount, FileExists(CONFIG_PATH) ? "Yes" : "No");
        
        // Clear all weapon states for campaign restart
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                ClearWeaponState(g_PrimarySlot1[i]);
                ClearWeaponState(g_PrimarySlot2[i]);
            }
        }
        
        // Delete the config file on campaign restart
        DeleteConfigFile();
    }
    else if (g_cvDebugMode.BoolValue)
    {
        PrintToServer("[DualPrimaries] Normal round start - not a campaign restart");
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    // No longer saving at round end - now done in real-time
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
    // Reset cooldowns for all players during map transition
    ResetCooldown();
    
    // We no longer need to set g_IsMapTransition since we use file existence instead
    g_IsCampaignRestart = false; // Reset campaign restart flag for map transitions
    if (g_cvDebugMode.BoolValue)
        PrintToServer("[DualPrimaries] Map transition detected - reset cooldowns");
}

public void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
    // Clear weapon states and config file when campaign is completed
    DeleteConfigFile();
    if (g_cvDebugMode.BoolValue)
        PrintToServer("[DualPrimaries] Campaign completed - cleared weapon states");
}

public void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
    // This is typically a wipe/restart scenario
    g_IsCampaignRestart = true;
    
    // Clear weapon states for all players when mission is lost
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            ClearWeaponState(g_PrimarySlot1[client]);
            ClearWeaponState(g_PrimarySlot2[client]);
            SavePlayerWeaponStateToConfig(client);
        }
    }
    
    if (g_cvDebugMode.BoolValue)
        PrintToServer("[DualPrimaries] Mission lost - cleared all player weapon states and marked as campaign restart");
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client)) return;
    
    // Player death clears their weapon states (as intended - working correctly)
    ClearWeaponState(g_PrimarySlot1[client]);
    ClearWeaponState(g_PrimarySlot2[client]);
    
    // Save cleared state to config file in real-time
    SavePlayerWeaponStateToConfig(client);
    
    if (g_cvDebugMode.BoolValue)
        PrintToChat(client, "[DEBUG] Weapon states cleared due to death");
}

// ----------------------
// SWITCH COMMAND
// ----------------------
public Action Cmd_SwitchPrimary(int client, int args)
{
    // If command is used from server console, try to get target
    if (client == 0)
    {
        if (args < 1)
        {
            PrintToServer("[DualPrimaries] Usage: sm_switchprimary <#userid|name> (from server console) or !switchprimary (in-game)");
            return Plugin_Handled;
        }
        
        char targetName[MAX_TARGET_LENGTH];
        char target_name[MAX_TARGET_LENGTH];
        int target_list[MAXPLAYERS];
        int target_count;
        bool tn_is_ml;
        
        GetCmdArg(1, targetName, sizeof(targetName));
        
        if ((target_count = ProcessTargetString(
            targetName,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_ALIVE, // Only allow alive players
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
        {
            ReplyToTargetError(client, target_count);
            return Plugin_Handled;
        }
        
        // Use the first target
        client = target_list[0];
    }
    
    // Check if client is valid and in-game
    if (!IsClientInGame(client))
    {
        ReplyToCommand(client, "[DualPrimaries] You must be in-game to use this command.");
        return Plugin_Handled;
    }
    
    // Check if player is alive
    if (!IsPlayerAlive(client))
    {
        ReplyToCommand(client, "[DualPrimaries] You must be alive to switch weapons.");
        return Plugin_Handled;
    }

    // Debug output
    if (g_cvDebugMode.BoolValue)
    {
        PrintToChat(client, "[DEBUG] Slot2 Valid: %s, Classname: '%s'", 
            g_PrimarySlot2[client].isValid ? "Yes" : "No", 
            g_PrimarySlot2[client].classname);
        
        // Show cooldown info in debug mode
        float cooldown = g_cvSwitchCooldown.FloatValue;
        float currentTime = GetGameTime();
        float timeSinceLastSwitch = currentTime - g_LastSwitchTime[client];
        PrintToChat(client, "[DEBUG] Cooldown: %.1f/%.1f", timeSinceLastSwitch, cooldown);
    }

    if (!g_PrimarySlot2[client].isValid || g_PrimarySlot2[client].classname[0] == '\0')
    {
        if (g_cvChatHints.BoolValue)
        {
            PrintToChat(client, "[DualPrimaries] No other weapon stored to switch to.");
        }
        return Plugin_Handled;
    }

    // Check cooldown
    float cooldown = g_cvSwitchCooldown.FloatValue;
    float currentTime = GetGameTime();
    float timeSinceLastSwitch = currentTime - g_LastSwitchTime[client];
    
    if (cooldown > 0.0 && timeSinceLastSwitch < cooldown)
    {
        if (g_cvChatHints.BoolValue)
        {
            float remaining = cooldown - timeSinceLastSwitch;
            // Visual feedback
            PrintToChat(client, " \x01[\x04DualPrimaries\x01] \x03Please wait \x04%.1f \x03seconds before switching weapons again.", remaining);
            // Play error sound
            EmitSoundToClient(client, "buttons/button10.wav");
            
            // Visual cooldown bar in chat
            int progressBars = 10;
            int filledBars = RoundToFloor((timeSinceLastSwitch / cooldown) * progressBars);
            char progressBar[32];
            Format(progressBar, sizeof(progressBar), "\x03[\x04");
            
            for (int i = 0; i < progressBars; i++)
            {
                if (i < filledBars)
                    StrCat(progressBar, sizeof(progressBar), "|");
                else
                    StrCat(progressBar, sizeof(progressBar), " ");
            }
            
            StrCat(progressBar, sizeof(progressBar), "\x03]");
            PrintToChat(client, "%s \x03Cooldown: \x04%.1f/%.1f", progressBar, timeSinceLastSwitch, cooldown);
        }
        
        // Block the command completely during cooldown
        return Plugin_Stop;
    }
    
    // Update last switch time
    g_LastSwitchTime[client] = currentTime;
    
    // Play switch sound
    EmitSoundToClient(client, "items/itempickup.wav");
    
    // Mark that we're switching weapons to prevent ammo replenishment
    g_IsWeaponSwitching[client] = true;
    
    // Save current weapon state
    int currentWeapon = GetPlayerWeaponSlot(client, 0);
    WeaponState tempState;
    if (currentWeapon > 0)
    {
        SaveWeaponState(currentWeapon, tempState);
        RemovePlayerItem(client, currentWeapon);
        AcceptEntityInput(currentWeapon, "Kill"); // Properly remove the weapon entity
    }
    else
    {
        ClearWeaponState(tempState);
    }

    // Restore the stored weapon with its state
    int restoredWeapon = RestoreWeaponState(client, g_PrimarySlot2[client]);
    if (restoredWeapon > 0)
    {
        // Store the weapon that was in slot 2 (now equipped) into slot 1
        // First save the current weapon's state
        SaveCurrentWeaponState(client, g_PrimarySlot2[client]);
        
        // Then copy the state to slot 1
        WeaponState slot2Backup;
        CopyWeaponState(g_PrimarySlot2[client], slot2Backup);
        CopyWeaponState(slot2Backup, g_PrimarySlot1[client]);
        
        // Check for duplicate before storing current weapon in slot 2 if restriction is enabled
        if (!g_cvAllowDuplicates.BoolValue && tempState.isValid && 
            StrEqual(tempState.classname, g_PrimarySlot1[client].classname, false))
        {
            // Don't store the current weapon in slot 2 if it would create a duplicate
            // Just clear slot 2 instead
            ClearWeaponState(g_PrimarySlot2[client]);
            
            if (g_cvChatHints.BoolValue)
            {
                PrintToChat(client, "[DualPrimaries] Switched to %s", g_PrimarySlot1[client].classname);
            }
            
            if (g_cvDebugMode.BoolValue)
                PrintToChat(client, "[DEBUG] Weapon switch completed, previous weapon cleared to avoid duplicate");
        }
        else
        {
            // Normal operation - store the previous weapon in slot 2
            CopyWeaponState(tempState, g_PrimarySlot2[client]);

            if (g_cvChatHints.BoolValue)
            {
                PrintToChat(client, "[DualPrimaries] Switched to %s", g_PrimarySlot1[client].classname);
            }
            
            // Save to config file in real-time
            SavePlayerWeaponStateToConfig(client);
        }
    }
    else
    {
        if (g_cvChatHints.BoolValue)
            PrintToChat(client, "[DualPrimaries] Failed to restore weapon state.");
    }

    // Clear the switching flag after a short delay to allow weapon switch to complete
    CreateTimer(1.0, Timer_ClearSwitchingFlag, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    // Update HUD after switching
    if (g_cvShowHUD.BoolValue)
    {
        CreateTimer(0.1, Timer_UpdateHUD, GetClientUserId(client));
    }
    
    return Plugin_Handled;
}

// Timer to update HUD after a short delay
public Action Timer_UpdateHUD(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
    {
        UpdateHUD(client);
    }
    return Plugin_Stop;
}

// ----------------------
// STORE COMMAND
// ----------------------
public Action Cmd_StorePrimary(int client, int args)
{
    // If command is used from server console, try to get target
    if (client == 0)
    {
        if (args < 1)
        {
            PrintToServer("[DualPrimaries] Usage: sm_storeprimary <#userid|name> (from server console) or !storeprimary (in-game)");
            return Plugin_Handled;
        }
        
        char targetName[MAX_TARGET_LENGTH];
        char target_name[MAX_TARGET_LENGTH];
        int target_list[MAXPLAYERS];
        int target_count;
        bool tn_is_ml;
        
        GetCmdArg(1, targetName, sizeof(targetName));
        
        if ((target_count = ProcessTargetString(
            targetName,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_ALIVE, // Only allow alive players
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
        {
            ReplyToTargetError(client, target_count);
            return Plugin_Handled;
        }
        
        // Use the first target
        client = target_list[0];
    }
    
    // Check if client is valid and in-game
    if (!IsClientInGame(client))
    {
        ReplyToCommand(client, "[DualPrimaries] You must be in-game to use this command.");
        return Plugin_Handled;
    }
    
    // Check if player is alive
    if (!IsPlayerAlive(client))
    {
        ReplyToCommand(client, "[DualPrimaries] You must be alive to store weapons.");
        return Plugin_Handled;
    }

    int weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon <= 0 || !IsValidEntity(weapon))
    {
        if (g_cvChatHints.BoolValue)
            PrintToChat(client, "[DualPrimaries] No primary weapon to store.");
        return Plugin_Handled;
    }

    char classname[64];
    GetEntityClassname(weapon, classname, sizeof(classname));
    
    if (!IsPrimaryWeapon(classname))
    {
        if (g_cvChatHints.BoolValue)
            PrintToChat(client, "[DualPrimaries] Current weapon is not a primary weapon.");
        return Plugin_Handled;
    }

    // Check for duplicate weapon if restriction is enabled
    if (!g_cvAllowDuplicates.BoolValue && IsDuplicateWeapon(client, classname))
    {
        if (g_cvChatHints.BoolValue)
            PrintToChat(client, "[DualPrimaries] Cannot store duplicate weapon: %s (duplicate weapons disabled)", classname);
        
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Duplicate weapon store blocked: %s", classname);
        return Plugin_Handled;
    }

    SaveWeaponState(weapon, g_PrimarySlot2[client]);
    if (g_cvChatHints.BoolValue)
        PrintToChat(client, "[DualPrimaries] Manually stored %s in slot 2.", classname);
    
    // Save to config file in real-time
    SavePlayerWeaponStateToConfig(client);
    
    return Plugin_Handled;
}

// ----------------------
// STATUS COMMAND
// ----------------------
public Action Cmd_PrimaryStatus(int client, int args)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client)) return Plugin_Handled;

    PrintToChat(client, "[DualPrimaries] === Weapon Status ===");
    
    if (g_PrimarySlot1[client].isValid)
    {
        PrintToChat(client, "[DualPrimaries] Slot 1: %s (Clip: %d, Ammo: %d, Upgrades: %s%s%s)", 
            g_PrimarySlot1[client].classname,
            g_PrimarySlot1[client].clip,
            g_PrimarySlot1[client].ammo,
            g_PrimarySlot1[client].hasLaser ? "L" : "",
            g_PrimarySlot1[client].hasIncendiary ? "I" : "",
            g_PrimarySlot1[client].hasExplosive ? "E" : "");
    }
    else
    {
        PrintToChat(client, "[DualPrimaries] Slot 1: Empty");
    }
    
    if (g_PrimarySlot2[client].isValid)
    {
        PrintToChat(client, "[DualPrimaries] Slot 2: %s (Clip: %d, Ammo: %d, Upgrades: %s%s%s)", 
            g_PrimarySlot2[client].classname,
            g_PrimarySlot2[client].clip,
            g_PrimarySlot2[client].ammo,
            g_PrimarySlot2[client].hasLaser ? "L" : "",
            g_PrimarySlot2[client].hasIncendiary ? "I" : "",
            g_PrimarySlot2[client].hasExplosive ? "E" : "");
    }
    else
    {
        PrintToChat(client, "[DualPrimaries] Slot 2: Empty");
    }
    
    return Plugin_Handled;
}

// ----------------------
// SERVER COMMANDS
// ----------------------
public Action Cmd_SwitchPrimary_Server(int args)
{
    if (args < 1)
    {
        PrintToServer("[DualPrimaries] Usage: sm_switchprimary_server <client_id>");
        return Plugin_Handled;
    }
    
    char arg[32];
    GetCmdArg(1, arg, sizeof(arg));
    int client = StringToInt(arg);
    
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
    {
        PrintToServer("[DualPrimaries] Invalid client ID: %d", client);
        return Plugin_Handled;
    }
    
    return Cmd_SwitchPrimary(client, 0);
}

public Action Cmd_StorePrimary_Server(int args)
{
    if (args < 1)
    {
        PrintToServer("[DualPrimaries] Usage: sm_storeprimary_server <client_id>");
        return Plugin_Handled;
    }
    
    char arg[32];
    GetCmdArg(1, arg, sizeof(arg));
    int client = StringToInt(arg);
    
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
    {
        PrintToServer("[DualPrimaries] Invalid client ID: %d", client);
        return Plugin_Handled;
    }
    
    return Cmd_StorePrimary(client, 0);
}

public Action Cmd_PrimaryStatus_Server(int args)
{
    if (args < 1)
    {
        PrintToServer("[DualPrimaries] Usage: sm_primarystatus_server <client_id>");
        return Plugin_Handled;
    }
    
    char arg[32];
    GetCmdArg(1, arg, sizeof(arg));
    int client = StringToInt(arg);
    
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
    {
        PrintToServer("[DualPrimaries] Invalid client ID: %d", client);
        return Plugin_Handled;
    }
    
    return Cmd_PrimaryStatus(client, 0);
}

// ----------------------
// AMMO REPLENISHMENT
// ----------------------

void ReplenishBothPrimaryWeapons(int client)
{
    int currentWeapon = GetPlayerWeaponSlot(client, 0);
    if (currentWeapon <= 0 || !IsValidEntity(currentWeapon)) 
    {
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] No valid current weapon");
        return;
    }
    
    char currentClassname[64];
    GetEntityClassname(currentWeapon, currentClassname, sizeof(currentClassname));
    
    if (!IsPrimaryWeapon(currentClassname)) 
    {
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Current weapon %s is not primary", currentClassname);
        return;
    }
    
    // Get the current weapon's ammo type and current ammo amount
    int currentAmmoType = GetEntProp(currentWeapon, Prop_Send, "m_iPrimaryAmmoType");
    // FIXED: Validate ammo type is within bounds (0-31 for 32 element array)
    if (currentAmmoType < 0 || currentAmmoType >= 32) 
    {
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Invalid ammo type: %d (out of bounds 0-31)", currentAmmoType);
        return;
    }
    
    int currentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, currentAmmoType);
    
    if (g_cvDebugMode.BoolValue)
        PrintToChat(client, "[DEBUG] Current weapon: %s, AmmoType: %d, Ammo: %d", currentClassname, currentAmmoType, currentAmmo);
    
    bool slot1Updated = false, slot2Updated = false;
    
    // Update stored weapon states with the new ammo amount
    if (g_PrimarySlot1[client].isValid)
    {
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Slot1: %s, replenishing ammo", g_PrimarySlot1[client].classname);
        
        // Get the appropriate ammo amount for slot 1 weapon's ammo type
        int slot1AmmoType = GetWeaponAmmoType(g_PrimarySlot1[client].classname);
        // FIXED: Validate slot1AmmoType before accessing array
        int slot1Ammo = 0;
        if (slot1AmmoType >= 0 && slot1AmmoType < 32)
        {
            slot1Ammo = (slot1AmmoType == currentAmmoType) ? currentAmmo : GetEntProp(client, Prop_Send, "m_iAmmo", _, slot1AmmoType);
        }
        
        // If slot1 uses different ammo type, set it to max ammo for that type
        if (slot1AmmoType != currentAmmoType && (slot1AmmoType < 0 || slot1AmmoType >= 32))
        {
            slot1Ammo = GetMaxAmmoForWeapon(g_PrimarySlot1[client].classname);
        }
        else if (slot1AmmoType == currentAmmoType)
        {
            slot1Ammo = currentAmmo;
        }
        
        g_PrimarySlot1[client].ammo = slot1Ammo;
        slot1Updated = true;
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Updated slot 1 (%s) ammo to %d", g_PrimarySlot1[client].classname, slot1Ammo);
    }
    else if (g_cvDebugMode.BoolValue)
    {
        PrintToChat(client, "[DEBUG] Slot1 is empty");
    }
    
    if (g_PrimarySlot2[client].isValid)
    {
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Slot2: %s, replenishing ammo", g_PrimarySlot2[client].classname);
        
        // Get the appropriate ammo amount for slot 2 weapon's ammo type
        int slot2AmmoType = GetWeaponAmmoType(g_PrimarySlot2[client].classname);
        // FIXED: Validate slot2AmmoType before accessing array
        int slot2Ammo = 0;
        if (slot2AmmoType >= 0 && slot2AmmoType < 32)
        {
            slot2Ammo = (slot2AmmoType == currentAmmoType) ? currentAmmo : GetEntProp(client, Prop_Send, "m_iAmmo", _, slot2AmmoType);
        }
        
        // If slot2 uses different ammo type, set it to max ammo for that type
        if (slot2AmmoType != currentAmmoType && (slot2AmmoType < 0 || slot2AmmoType >= 32))
        {
            slot2Ammo = GetMaxAmmoForWeapon(g_PrimarySlot2[client].classname);
        }
        else if (slot2AmmoType == currentAmmoType)
        {
            slot2Ammo = currentAmmo;
        }
        
        g_PrimarySlot2[client].ammo = slot2Ammo;
        slot2Updated = true;
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Updated slot 2 (%s) ammo to %d", g_PrimarySlot2[client].classname, slot2Ammo);
    }
    else if (g_cvDebugMode.BoolValue)
    {
        PrintToChat(client, "[DEBUG] Slot2 is empty");
    }
    
    if (g_cvChatHints.BoolValue && (slot1Updated || slot2Updated))
        PrintToChat(client, "[DualPrimaries] Ammo replenished for %s%s%s.", 
            slot1Updated ? "slot 1" : "",
            (slot1Updated && slot2Updated) ? " and " : "",
            slot2Updated ? "slot 2" : "");
    
    // Save to config file in real-time if any ammo was updated
    if (slot1Updated || slot2Updated)
    {
        SavePlayerWeaponStateToConfig(client);
    }
}
int GetWeaponAmmoType(const char[] weaponClassname)
{
    // Return the ammo type for a given weapon
    if (StrContains(weaponClassname, "rifle", false) != -1 ||
        StrEqual(weaponClassname, "weapon_rifle", false) ||
        StrEqual(weaponClassname, "weapon_rifle_ak47", false) ||
        StrEqual(weaponClassname, "weapon_rifle_desert", false) ||
        StrEqual(weaponClassname, "weapon_rifle_sg552", false) ||
        StrEqual(weaponClassname, "weapon_m60", false))
    {
        return 3; // Rifle ammo
    }
    else if (StrContains(weaponClassname, "smg", false) != -1 ||
             StrEqual(weaponClassname, "weapon_smg", false) ||
             StrEqual(weaponClassname, "weapon_smg_silenced", false) ||
             StrEqual(weaponClassname, "weapon_smg_mp5", false))
    {
        return 5; // SMG ammo
    }
    else if (StrContains(weaponClassname, "shotgun", false) != -1 ||
             StrEqual(weaponClassname, "weapon_shotgun_chrome", false) ||
             StrEqual(weaponClassname, "weapon_shotgun_spas", false) ||
             StrEqual(weaponClassname, "weapon_autoshotgun", false) ||
             StrEqual(weaponClassname, "weapon_pumpshotgun", false))
    {
        return 7; // Shotgun ammo
    }
    else if (StrContains(weaponClassname, "sniper", false) != -1 ||
             StrEqual(weaponClassname, "weapon_sniper_military", false) ||
             StrEqual(weaponClassname, "weapon_hunting_rifle", false))
    {
        return 9; // Sniper ammo
    }
    
    return -1; // Unknown weapon
}

int GetMaxAmmoForWeapon(const char[] weaponClassname)
{
    // Return max ammo for different weapon types
    if (StrContains(weaponClassname, "rifle", false) != -1 ||
        StrEqual(weaponClassname, "weapon_rifle", false) ||
        StrEqual(weaponClassname, "weapon_rifle_ak47", false) ||
        StrEqual(weaponClassname, "weapon_rifle_desert", false) ||
        StrEqual(weaponClassname, "weapon_rifle_sg552", false))
    {
        return 360; // Rifle max ammo
    }
    else if (StrEqual(weaponClassname, "weapon_m60", false))
    {
        return 150; // M60 max ammo
    }
    else if (StrContains(weaponClassname, "smg", false) != -1 ||
             StrEqual(weaponClassname, "weapon_smg", false) ||
             StrEqual(weaponClassname, "weapon_smg_silenced", false) ||
             StrEqual(weaponClassname, "weapon_smg_mp5", false))
    {
        return 650; // SMG max ammo
    }
    else if (StrContains(weaponClassname, "shotgun", false) != -1 ||
             StrEqual(weaponClassname, "weapon_shotgun_chrome", false) ||
             StrEqual(weaponClassname, "weapon_shotgun_spas", false) ||
             StrEqual(weaponClassname, "weapon_autoshotgun", false) ||
             StrEqual(weaponClassname, "weapon_pumpshotgun", false))
    {
        return 72; // Shotgun max ammo
    }
    else if (StrContains(weaponClassname, "sniper", false) != -1 ||
             StrEqual(weaponClassname, "weapon_sniper_military", false) ||
             StrEqual(weaponClassname, "weapon_hunting_rifle", false))
    {
        return 180; // Sniper max ammo
    }
    
    return 100; // Default fallback
}

public Action Timer_ClearSwitchingFlag(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && client <= MaxClients && IsClientInGame(client))
    {
        g_IsWeaponSwitching[client] = false;
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Weapon switching flag cleared");
    }
    return Plugin_Stop;
}

public Action Timer_LoadWeaponState(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    delete pack;
    
    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client))
        return Plugin_Stop;
    
    LoadWeaponStateFromConfig(client);
    
    if (g_cvDebugMode.BoolValue)
        PrintToChat(client, "[DEBUG] Delayed weapon state load completed");
    
    return Plugin_Stop;
}


// ----------------------
// CONFIG FILE FUNCTIONS
// ----------------------

void SavePlayerWeaponStateToConfig(int client)
{
    // Don't save weapon states for bots
    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
        return;
        
    char steamId[64];
    if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
        return;
    
    KeyValues kv = new KeyValues("DualPrimariesConfig");
    
    // Load existing config if it exists
    if (FileExists(CONFIG_PATH))
    {
        kv.ImportFromFile(CONFIG_PATH);
    }
    
    // Navigate to or create the player's section
    kv.JumpToKey(steamId, true);
    
    // Clear existing data for this player
    kv.DeleteKey("Slot1");
    kv.DeleteKey("Slot2");
    
    // Save slot 1 if valid
    if (g_PrimarySlot1[client].isValid)
    {
        kv.JumpToKey("Slot1", true);
        kv.SetString("classname", g_PrimarySlot1[client].classname);
        kv.SetNum("clip", g_PrimarySlot1[client].clip);
        kv.SetNum("ammo", g_PrimarySlot1[client].ammo);
        kv.SetNum("upgrades", g_PrimarySlot1[client].upgrades);
        kv.SetNum("hasLaser", g_PrimarySlot1[client].hasLaser ? 1 : 0);
        kv.SetNum("hasIncendiary", g_PrimarySlot1[client].hasIncendiary ? 1 : 0);
        kv.SetNum("hasExplosive", g_PrimarySlot1[client].hasExplosive ? 1 : 0);
        kv.GoBack();
        
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Saved slot 1 to config: %s", g_PrimarySlot1[client].classname);
    }
    
    // Save slot 2 if valid
    if (g_PrimarySlot2[client].isValid)
    {
        kv.JumpToKey("Slot2", true);
        kv.SetString("classname", g_PrimarySlot2[client].classname);
        kv.SetNum("clip", g_PrimarySlot2[client].clip);
        kv.SetNum("ammo", g_PrimarySlot2[client].ammo);
        kv.SetNum("upgrades", g_PrimarySlot2[client].upgrades);
        kv.SetNum("hasLaser", g_PrimarySlot2[client].hasLaser ? 1 : 0);
        kv.SetNum("hasIncendiary", g_PrimarySlot2[client].hasIncendiary ? 1 : 0);
        kv.SetNum("hasExplosive", g_PrimarySlot2[client].hasExplosive ? 1 : 0);
        kv.GoBack();
        
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Saved slot 2 to config: %s", g_PrimarySlot2[client].classname);
    }
    
    // If both slots are empty, remove the player's section entirely
    if (!g_PrimarySlot1[client].isValid && !g_PrimarySlot2[client].isValid)
    {
        kv.GoBack(); // Go back to root
        kv.DeleteKey(steamId);
        if (g_cvDebugMode.BoolValue)
            PrintToChat(client, "[DEBUG] Removed empty weapon state from config");
    }
    
    kv.Rewind();
    kv.ExportToFile(CONFIG_PATH);
    delete kv;
}


void LoadWeaponStateFromConfig(int client)
{
    // Don't load weapon states for bots
    if (!FileExists(CONFIG_PATH) || IsFakeClient(client))
        return;
        
    char steamId[64];
    if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
        return;
        
    KeyValues kv = new KeyValues("DualPrimariesConfig");
    if (!kv.ImportFromFile(CONFIG_PATH))
    {
        delete kv;
        return;
    }
    
    if (!kv.JumpToKey(steamId))
    {
        delete kv;
        return;
    }
    
    // Load slot 1
    if (kv.JumpToKey("Slot1"))
    {
        char classname[64];
        kv.GetString("classname", classname, sizeof(classname));
        
        if (strlen(classname) > 0)
        {
            strcopy(g_PrimarySlot1[client].classname, sizeof(g_PrimarySlot1[].classname), classname);
            g_PrimarySlot1[client].clip = kv.GetNum("clip");
            g_PrimarySlot1[client].ammo = kv.GetNum("ammo");
            g_PrimarySlot1[client].upgrades = kv.GetNum("upgrades");
            g_PrimarySlot1[client].hasLaser = kv.GetNum("hasLaser") ? true : false;
            g_PrimarySlot1[client].hasIncendiary = kv.GetNum("hasIncendiary") ? true : false;
            g_PrimarySlot1[client].hasExplosive = kv.GetNum("hasExplosive") ? true : false;
            g_PrimarySlot1[client].isValid = true;
            
            if (g_cvDebugMode.BoolValue)
                PrintToChat(client, "[DEBUG] Loaded slot 1: %s", classname);
        }
        kv.GoBack();
    }
    
    // Load slot 2
    if (kv.JumpToKey("Slot2"))
    {
        char classname[64];
        kv.GetString("classname", classname, sizeof(classname));
        
        if (strlen(classname) > 0)
        {
            strcopy(g_PrimarySlot2[client].classname, sizeof(g_PrimarySlot2[].classname), classname);
            g_PrimarySlot2[client].clip = kv.GetNum("clip");
            g_PrimarySlot2[client].ammo = kv.GetNum("ammo");
            g_PrimarySlot2[client].upgrades = kv.GetNum("upgrades");
            g_PrimarySlot2[client].hasLaser = kv.GetNum("hasLaser") ? true : false;
            g_PrimarySlot2[client].hasIncendiary = kv.GetNum("hasIncendiary") ? true : false;
            g_PrimarySlot2[client].hasExplosive = kv.GetNum("hasExplosive") ? true : false;
            g_PrimarySlot2[client].isValid = true;
            
            if (g_cvDebugMode.BoolValue)
                PrintToChat(client, "[DEBUG] Loaded slot 2: %s", classname);
        }
        kv.GoBack();
    }
    
    delete kv;
}

void DeleteConfigFile()
{
    if (FileExists(CONFIG_PATH))
    {
        DeleteFile(CONFIG_PATH);
        if (g_cvDebugMode.BoolValue)
            PrintToServer("[DualPrimaries] Deleted config file");
    }
}

bool IsSpecialWeapon(const char[] classname)
{
    return (StrEqual(classname, "weapon_m60", false) ||
            StrEqual(classname, "weapon_rifle_m60", false) ||
            StrEqual(classname, "weapon_grenade_launcher", false) ||
            StrEqual(classname, "m60", false) ||
            StrEqual(classname, "rifle_m60", false) ||
            StrEqual(classname, "grenade_launcher", false));
}

bool IsPrimaryWeapon(const char[] classname)
{
    return (StrContains(classname, "weapon_rifle", false) != -1
         || StrContains(classname, "weapon_smg", false) != -1
         || StrContains(classname, "weapon_shotgun", false) != -1
         || StrContains(classname, "weapon_sniper", false) != -1
         || StrEqual(classname, "weapon_m60", false)
         || StrEqual(classname, "weapon_rifle_m60", false)
         || StrEqual(classname, "weapon_grenade_launcher", false)
         // Also check for item pickup names (without weapon_ prefix)
         || StrContains(classname, "rifle", false) != -1
         || StrContains(classname, "smg", false) != -1
         || StrContains(classname, "shotgun", false) != -1
         || StrContains(classname, "sniper", false) != -1
         || StrEqual(classname, "pumpshotgun", false)
         || StrEqual(classname, "autoshotgun", false)
         || StrEqual(classname, "hunting_rifle", false)
         || StrEqual(classname, "sniper_military", false)
         || StrEqual(classname, "smg_silenced", false)
         || StrEqual(classname, "smg_mp5", false)
         || StrEqual(classname, "m60", false)
         || StrEqual(classname, "rifle_m60", false)
         || StrEqual(classname, "grenade_launcher", false));
}

bool IsDuplicateWeapon(int client, const char[] weaponClassname)
{
    // Don't check for duplicates if we're in the middle of switching weapons
    if (g_IsWeaponSwitching[client])
        return false;
        
    // Check if this weapon already exists in either slot
    if (g_PrimarySlot1[client].isValid && StrEqual(g_PrimarySlot1[client].classname, weaponClassname, false))
        return true;
        
    if (g_PrimarySlot2[client].isValid && StrEqual(g_PrimarySlot2[client].classname, weaponClassname, false))
        return true;
        
    return false;
}
