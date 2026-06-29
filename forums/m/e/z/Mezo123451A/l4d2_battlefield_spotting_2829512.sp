#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.4"
#define SPOT_DURATION 10.0
#define SPOT_COOLDOWN 10.0
#define MAX_SPOT_DISTANCE 2000.0

enum struct SpottedEntity {
    int entityRef;
    int type;
    float spotTime;
    bool isSpotted;
    int spottedBy;
}

ArrayList g_SpottedEntities;
bool g_PlayerSpotCooldown[MAXPLAYERS + 1];
Handle g_hSpotCooldownTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
Handle g_hHudSync = INVALID_HANDLE;
Handle g_hTipsTimer = INVALID_HANDLE;
Handle g_hGlowCheckTimer = INVALID_HANDLE;

// ConVars
ConVar g_hVersion;
ConVar g_hSpotDuration;
ConVar g_hSpotCooldown;
ConVar g_hSpotDistance;
ConVar g_hSpotEnabled;
ConVar g_hSpotGlow;
ConVar g_hChatTips;
ConVar g_hMinChatInterval;
ConVar g_hMaxChatInterval;
ConVar g_hSpotItems;
ConVar g_hShowSpotParticle;
ConVar g_hShowSpotMessages;
ConVar g_hShowCooldownMessage;
ConVar g_hSpotSoundEnabled;

public Plugin myinfo = {
    name = "L4D2 Battlefield Spotting",
    author = "Mezo123451A",
    description = "Adds Battlefield-style spotting mechanics using 'E' key",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart() {
    // Create ConVars
    g_hVersion = CreateConVar("l4d2_spot_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
    g_hSpotDuration = CreateConVar("l4d2_spot_duration", "10.0", "Duration of spot marker in seconds", FCVAR_NOTIFY, true, 1.0, true, 120.0);
    g_hSpotCooldown = CreateConVar("l4d2_spot_cooldown", "10.0", "Cooldown between spots in seconds", FCVAR_NOTIFY, true, 0.0, true, 120.0);
    g_hSpotDistance = CreateConVar("l4d2_spot_distance", "2000.0", "Maximum spotting distance", FCVAR_NOTIFY, true, 100.0, true, 5000.0);
    g_hSpotEnabled = CreateConVar("l4d2_spot_enabled", "1", "Enable/disable spotting system", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hSpotGlow = CreateConVar("l4d2_spot_glow", "1", "Enable/disable glow effect on spotted enemies", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hChatTips = CreateConVar("l4d2_spot_chat_tips", "1", "Enable/disable chat tips about how to use the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hMinChatInterval = CreateConVar("l4d2_spot_min_chat_interval", "90.0", "Minimum interval between chat tips in seconds", FCVAR_NOTIFY, true, 90.0, true, 180.0);
    g_hMaxChatInterval = CreateConVar("l4d2_spot_max_chat_interval", "180.0", "Maximum interval between chat tips in seconds", FCVAR_NOTIFY, true, 90.0, true, 180.0);
    g_hSpotItems = CreateConVar("l4d2_spot_items", "1", "Enable/disable spotting of items and weapons", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hShowSpotParticle = CreateConVar("l4d2_spot_show_particle", "0", "Show the light particle under spotted entities", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hShowSpotMessages = CreateConVar("l4d2_spot_show_messages", "1", "Show spotted announcement messages in chat", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hShowCooldownMessage = CreateConVar("l4d2_spot_show_cooldown_msg", "1", "Show cooldown message when spotting is on cooldown", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hSpotSoundEnabled = CreateConVar("l4d2_spot_sound_enabled", "1", "Enable/disable spot confirmation sound", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    // Set version ConVar
    g_hVersion.SetString(PLUGIN_VERSION);

    // Initialize arrays and handlers
    g_SpottedEntities = new ArrayList(sizeof(SpottedEntity));
    g_hHudSync = CreateHudSynchronizer();
    
    // Hook events
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    
    // Create config file
    AutoExecConfig(true, "l4d2_battlefield_spotting");
    
    // Create timer for cleanup
    CreateTimer(0.1, Timer_UpdateSpots, _, TIMER_REPEAT);
    
    // Make the timer run at the fastest possible rate
    g_hGlowCheckTimer = CreateTimer(0.001, Timer_CheckSurvivorGlow, _, TIMER_REPEAT);

    // Start tips timer
    StartTipsTimer();

    // Precache sound
    PrecacheSound("buttons/blip1.wav");
}

void StartTipsTimer() {
    // Kill existing timer if any
    if (g_hTipsTimer != INVALID_HANDLE) {
        KillTimer(g_hTipsTimer);
        g_hTipsTimer = INVALID_HANDLE;
    }
    
    // Get interval values from ConVars
    float minInterval = g_hMinChatInterval.FloatValue;
    float maxInterval = g_hMaxChatInterval.FloatValue;
    float interval = GetRandomFloat(minInterval, maxInterval);
    
    // Create new timer with random interval
    g_hTipsTimer = CreateTimer(interval, Timer_ShowTip, _, TIMER_REPEAT);
}

public Action Timer_ShowTip(Handle timer) {
    if (g_hChatTips.BoolValue) {
        PrintToChatAll("\x04Spotting\x01: Press \x05 E \x01 key while looking at \x03Special Infected\x01, \x04Tanks\x01, or \x04Witches\x01 to spot them for your team!");
        
        // Get new random interval for next message
        float minInterval = g_hMinChatInterval.FloatValue;
        float maxInterval = g_hMaxChatInterval.FloatValue;
        float interval = GetRandomFloat(minInterval, maxInterval);
        
        // Create new timer with new interval
        g_hTipsTimer = CreateTimer(interval, Timer_ShowTip, _, TIMER_REPEAT);
        
        // Kill current timer
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public void OnPluginEnd() {
    // Clean up any remaining spotted entities
    for (int i = 0; i < g_SpottedEntities.Length; i++) {
        SpottedEntity spotted;
        g_SpottedEntities.GetArray(i, spotted);
        int entity = EntRefToEntIndex(spotted.entityRef);
        if (IsValidEntity(entity)) {
            SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
        }
    }
    
    delete g_SpottedEntities;
    
    if (g_hTipsTimer != INVALID_HANDLE) {
        KillTimer(g_hTipsTimer);
        g_hTipsTimer = INVALID_HANDLE;
    }
    
    if (g_hGlowCheckTimer != INVALID_HANDLE) {
        KillTimer(g_hGlowCheckTimer);
        g_hGlowCheckTimer = INVALID_HANDLE;
    }
    
    // Remove glow from all survivors
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) == 2) {
            SetEntProp(i, Prop_Send, "m_iGlowType", 0);
            SetEntProp(i, Prop_Send, "m_glowColorOverride", 0);
        }
    }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
    if (buttons & IN_USE) {
        PerformSpot(client);
    }
    return Plugin_Continue;
}

Action PerformSpot(int client) {
    if (!IsValidClient(client) || !g_hSpotEnabled.BoolValue)
        return Plugin_Continue;

    if (g_PlayerSpotCooldown[client] && g_hSpotCooldown.FloatValue > 0.0) {
        if (g_hShowCooldownMessage.BoolValue) {
            PrintHintText(client, "Spotting is on cooldown. Please wait.");
        }
        return Plugin_Continue;
    }
    
    if (AttemptSpot(client)) {
        g_PlayerSpotCooldown[client] = true;
        g_hSpotCooldownTimer[client] = CreateTimer(g_hSpotCooldown.FloatValue, Timer_SpotCooldown, client);
    }
    
    return Plugin_Continue;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    // Debug print
    PrintToServer("[Debug] Event_PlayerDeath - victim: %d", client);
    
    // Remove glow from infected only
    if (IsValidClient(client)) {
        // Immediately remove glow effect
        if (IsValidEntity(client)) {
            SetEntProp(client, Prop_Send, "m_iGlowType", 0);
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
        }
        if (GetClientTeam(client) == 3) {
            RemoveSpottedEntity(client);
        }
    }
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    g_SpottedEntities.Clear();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    g_SpottedEntities.Clear();
}

bool AttemptSpot(int client) {
    // Don't allow spotting if the client is a survivor and attacking
    if (IsValidClient(client) && GetClientTeam(client) == 2 && (GetClientButtons(client) & IN_ATTACK)) {
        return false;
    }

    float eyePos[3], eyeAng[3], endPos[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, eyeAng);
    
    TR_TraceRayFilter(eyePos, eyeAng, MASK_SOLID, RayType_Infinite, TraceFilter_SpotTarget, client);
    
    if (TR_DidHit()) {
        TR_GetEndPosition(endPos);
        int target = TR_GetEntityIndex();
        float distance = GetVectorDistance(eyePos, endPos);
        
        // Additional safety check - never spot survivors
        if (IsValidClient(target) && GetClientTeam(target) == 2) {
            return false;
        }
        
        // Print for debugging
        PrintToServer("Spotted entity: %d at distance: %f", target, distance);
        
        if (distance <= g_hSpotDistance.FloatValue) {
            if (IsValidInfected(target) || IsWitch(target)) {
                SpotTarget(client, target, distance);
                return true;
            }
            else if (g_hSpotItems.BoolValue && IsSpottableItem(target)) {
                PrintToServer("Attempting to spot item");
                SpotItem(client, target, distance);
                return true;
            }
        }
    }
    
    return false;
}

void SpotTarget(int client, int target, float distance) {
    // Never allow spotting of survivors - early exit
    if (IsValidClient(target) && GetClientTeam(target) == 2) {
        return;
    }

    // Additional safety check before adding new spotted entity
    if (!IsValidInfected(target) && !IsWitch(target)) {
        return;
    }

    // Check if target is already spotted and update timer if so
    bool alreadySpotted = false;
    for (int i = 0; i < g_SpottedEntities.Length; i++) {
        SpottedEntity spotted;
        g_SpottedEntities.GetArray(i, spotted);
        if (EntRefToEntIndex(spotted.entityRef) == target) {
            spotted.spotTime = GetGameTime(); // Reset the timer
            g_SpottedEntities.SetArray(i, spotted);
            alreadySpotted = true;
            break;
        }
    }

    if (!alreadySpotted) {
        SpottedEntity spotted;
        spotted.entityRef = EntIndexToEntRef(target);
        spotted.type = IsWitch(target) ? 9 : L4D2_GetPlayerZombieClass(target);
        spotted.spotTime = GetGameTime();
        spotted.isSpotted = true;
        spotted.spottedBy = client;
        
        g_SpottedEntities.PushArray(spotted);
        
        // Only apply glow if target is infected or witch
        if (g_hSpotGlow.BoolValue) {
            if (IsValidInfected(target) || IsWitch(target)) {
                SetEntProp(target, Prop_Send, "m_iGlowType", 3);
                // Use hardcoded colors based on type
                switch (spotted.type) {
                    case 1: SetEntProp(target, Prop_Send, "m_glowColorOverride", 0xFF0000);  // Smoker - Red
                    case 2: SetEntProp(target, Prop_Send, "m_glowColorOverride", 0x00FF00);  // Boomer - Green
                    case 3: SetEntProp(target, Prop_Send, "m_glowColorOverride", 0x0000FF);  // Hunter - Blue
                    case 4: SetEntProp(target, Prop_Send, "m_glowColorOverride", 0xFFFF00);  // Spitter - Yellow
                    case 5: SetEntProp(target, Prop_Send, "m_glowColorOverride", 0xFF00FF);  // Jockey - Purple
                    case 6: SetEntProp(target, Prop_Send, "m_glowColorOverride", 0x00FFFF);  // Charger - Cyan
                    case 8: SetEntProp(target, Prop_Send, "m_glowColorOverride", 0xFF8000);  // Tank - Orange
                    case 9: SetEntProp(target, Prop_Send, "m_glowColorOverride", 0xFFFFFF);  // Witch - White
                    default: SetEntProp(target, Prop_Send, "m_glowColorOverride", 0xFFFFFF); // Default - White
                }
            }
        }
        
        DisplaySpotInfo(client, distance, spotted.type);

        if (g_hShowSpotParticle.BoolValue) {
            float targetPos[3];
            GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
            DisplaySpotIcon(client, targetPos);
        }

        if (g_hShowSpotMessages.BoolValue) {
            char spotter_name[MAX_NAME_LENGTH];
            GetClientName(client, spotter_name, sizeof(spotter_name));
            char target_name[32];
            strcopy(target_name, sizeof(target_name), GetInfectedName(spotted.type));
            PrintToChatAll("\x01[\x04Spotting\x01] \x03%s\x01 spotted a \x05%s\x01!", spotter_name, target_name);
        }

        if (g_hSpotSoundEnabled.BoolValue) {
            EmitSoundToClient(client, "buttons/blip1.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
        }
    }
}

bool IsValidInfected(int client) {
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (GetClientTeam(client) != 3) return false;  // Make sure it's only infected team
    if (!IsPlayerAlive(client)) return false;
    
    // Additional safety check - never consider survivors as valid infected
    if (GetClientTeam(client) == 2) return false;
    
    return true;
}

void RemoveSpottedEntity(int entity) {
    // Debug print
    PrintToServer("[Debug] RemoveSpottedEntity called for entity: %d", entity);
    
    // Immediately remove glow from survivors if they somehow got it
    if (IsValidClient(entity) && GetClientTeam(entity) == 2) {
        SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
        SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0);
        PrintToServer("[Debug] Removed glow from survivor: %d", entity);
        return;
    }
    
    // Process spotted entities
    for (int i = g_SpottedEntities.Length - 1; i >= 0; i--) {
        SpottedEntity spotted;
        g_SpottedEntities.GetArray(i, spotted);
        
        int spottedEntity = EntRefToEntIndex(spotted.entityRef);
        
        if (spottedEntity == entity || !IsValidEntity(spottedEntity)) {
            // Remove glow effect
            if (IsValidEntity(spottedEntity)) {
                SetEntProp(spottedEntity, Prop_Send, "m_iGlowType", 0);
                SetEntProp(spottedEntity, Prop_Send, "m_glowColorOverride", 0);
            }
            g_SpottedEntities.Erase(i);
        }
    }
}

public Action Timer_UpdateSpots(Handle timer) {
    if (!g_hSpotEnabled.BoolValue)
        return Plugin_Continue;

    float currentTime = GetGameTime();
    float spotDuration = g_hSpotDuration.FloatValue;
    
    for (int i = g_SpottedEntities.Length - 1; i >= 0; i--) {
        SpottedEntity spotted;
        g_SpottedEntities.GetArray(i, spotted);
        
        int entity = EntRefToEntIndex(spotted.entityRef);
        
        // Additional safety check for survivors
        if (IsValidClient(entity) && GetClientTeam(entity) == 2) {
            g_SpottedEntities.Erase(i);
            continue;
        }
        
        // Check if entity is valid and if time has expired
        if (!IsValidEntity(entity) || (currentTime - spotted.spotTime >= spotDuration)) {
            if (IsValidEntity(entity)) {
                SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
                SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0);
            }
            g_SpottedEntities.Erase(i);
            continue;
        }
        
        // Only show particle if enabled and entity is valid
        if (g_hShowSpotParticle.BoolValue && IsValidEntity(entity)) {
            float targetPos[3];
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetPos);
            DisplaySpotIcon(spotted.spottedBy, targetPos);
        }
    }
    
    return Plugin_Continue;
}

void DisplaySpotInfo(int client, float distance, int type) {
    SetHudTextParams(-1.0, 0.4, g_hSpotDuration.FloatValue, 255, 255, 0, 255);
    ShowSyncHudText(client, g_hHudSync, "Spotted %s (%.0f units)", GetInfectedName(type), distance);
}

void DisplaySpotIcon(int client, float targetPos[3]) {
    // Only display if particle is enabled
    if (g_hShowSpotParticle.BoolValue) {
        TE_SetupGlowSprite(targetPos, GetSpotIconModel(), 0.1, 0.5, 255);
        TE_SendToClient(client);
    }
}

int GetSpotIconModel() {
    return PrecacheModel("sprites/glow.vmt");
}

char[] GetInfectedName(int type) {
    char name[32];
    switch (type) {
        case 1: name = "Smoker";
        case 2: name = "Boomer";
        case 3: name = "Hunter";
        case 4: name = "Spitter";
        case 5: name = "Jockey";
        case 6: name = "Charger";
        case 8: name = "Tank";
        case 9: name = "Witch";
        default: name = "Special Infected";
    }
    return name;
}

bool TraceFilter_SpotTarget(int entity, int contentsMask, any client) {
    if (entity == client) return false;
    
    // Never allow spotting survivors
    if (IsValidClient(entity) && GetClientTeam(entity) == 2) return false;
    
    // Only allow spotting of infected players
    if (entity > 0 && entity <= MaxClients) {
        return IsValidInfected(entity);
    }
    
    // Allow spotting witches and items
    if (IsWitch(entity)) return true;
    if (g_hSpotItems.BoolValue && IsSpottableItem(entity)) return true;
    
    return false;
}

Action Timer_SpotCooldown(Handle timer, any client) {
    g_PlayerSpotCooldown[client] = false;
    g_hSpotCooldownTimer[client] = INVALID_HANDLE;
    return Plugin_Stop;
}

bool IsWitch(int entity) {
    if (entity <= 0 || entity > 2048) return false;
    char classname[6];
    GetEntityClassname(entity, classname, sizeof(classname));
    return strcmp(classname, "witch", false) == 0;
}

bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool IsSpottableItem(int entity) {
    if (entity <= 0) return false;
    
    char classname[64];
    if (!IsValidEntity(entity)) return false;
    GetEntityClassname(entity, classname, sizeof(classname));
    
    // Print for debugging
    PrintToServer("Attempting to spot item: %s", classname);
    
    return (StrContains(classname, "weapon_", false) == 0) ||
           (StrContains(classname, "upgrade_", false) == 0) ||
           (strcmp(classname, "weapon_pain_pills", false) == 0) ||
           (strcmp(classname, "weapon_first_aid_kit", false) == 0) ||
           (strcmp(classname, "weapon_defibrillator", false) == 0) ||
           (strcmp(classname, "weapon_pipe_bomb", false) == 0) ||
           (strcmp(classname, "weapon_molotov", false) == 0) ||
           (strcmp(classname, "weapon_vomitjar", false) == 0);
}

void SpotItem(int client, int target, float distance) {
    char itemName[64];
    GetEntityClassname(target, itemName, sizeof(itemName));
    
    // Special handling for weapon_spawn entities
    if (StrEqual(itemName, "weapon_spawn")) {
        char weaponName[64];
        GetEntPropString(target, Prop_Data, "m_ModelName", weaponName, sizeof(weaponName));
        
        // Convert model name to weapon name
        if (StrContains(weaponName, "sniper_awp", false) != -1) itemName = "AWP";
        else if (StrContains(weaponName, "sniper_scout", false) != -1) itemName = "Scout";
        else if (StrContains(weaponName, "rifle_sg552", false) != -1) itemName = "SG552";
        else if (StrContains(weaponName, "smg_mp5", false) != -1) itemName = "MP5";
        else if (StrContains(weaponName, "rifle", false) != -1) itemName = "M16 Rifle";
        else itemName = "Weapon";  // Default fallback
    }
    // Special handling for melee weapon spawns
    else if (StrEqual(itemName, "weapon_melee_spawn")) {
        char meleeModelName[64];
        GetEntPropString(target, Prop_Data, "m_ModelName", meleeModelName, sizeof(meleeModelName));
        
        // Debug print
        PrintToServer("DEBUG - Melee model name: %s", meleeModelName);
        
        // Convert model name to melee weapon name (updated checks)
        if (StrContains(meleeModelName, "bat", false) != -1) itemName = "Baseball Bat";
        else if (StrContains(meleeModelName, "cricket", false) != -1) itemName = "Cricket Bat";
        else if (StrContains(meleeModelName, "crowbar", false) != -1) itemName = "Crowbar";
        else if (StrContains(meleeModelName, "guitar", false) != -1) itemName = "Electric Guitar";
        else if (StrContains(meleeModelName, "axe", false) != -1) itemName = "Fire Axe";
        else if (StrContains(meleeModelName, "pan", false) != -1) itemName = "Frying Pan";
        else if (StrContains(meleeModelName, "golf", false) != -1) itemName = "Golf Club";
        else if (StrContains(meleeModelName, "katana", false) != -1) itemName = "Katana";
        else if (StrContains(meleeModelName, "machete", false) != -1) itemName = "Machete";
        else if (StrContains(meleeModelName, "tonfa", false) != -1) itemName = "Nightstick";
        else if (StrContains(meleeModelName, "pitchfork", false) != -1) itemName = "Pitchfork";
        else if (StrContains(meleeModelName, "shovel", false) != -1) itemName = "Shovel";
        else if (StrContains(meleeModelName, "knife", false) != -1) itemName = "Knife";
        else {
            // Debug print for unhandled melee weapons
            PrintToServer("DEBUG - Unhandled melee weapon model: %s", meleeModelName);
            itemName = "Melee Weapon";
        }
    }
    else if (StrContains(itemName, "weapon_") != -1) {
        // Regular weapon handling (existing code)
        ReplaceString(itemName, sizeof(itemName), "weapon_", "");
        ReplaceString(itemName, sizeof(itemName), "_spawn", "");
        
        if (StrEqual(itemName, "smg")) itemName = "SMG";
        else if (StrEqual(itemName, "smg_mp5")) itemName = "MP5";
        else if (StrEqual(itemName, "smg_silenced")) itemName = "Silenced SMG";
        else if (StrEqual(itemName, "pumpshotgun")) itemName = "Pump Shotgun";
        else if (StrEqual(itemName, "shotgun_chrome")) itemName = "Chrome Shotgun";
        else if (StrEqual(itemName, "autoshotgun")) itemName = "Auto Shotgun";
        else if (StrEqual(itemName, "shotgun_spas")) itemName = "SPAS Shotgun";
        else if (StrEqual(itemName, "rifle")) itemName = "M16 Rifle";
        else if (StrEqual(itemName, "rifle_desert")) itemName = "Desert Rifle";
        else if (StrEqual(itemName, "rifle_ak47")) itemName = "AK-47";
        else if (StrEqual(itemName, "rifle_sg552")) itemName = "SG552";
        else if (StrEqual(itemName, "hunting_rifle")) itemName = "Hunting Rifle";
        else if (StrEqual(itemName, "sniper_military")) itemName = "Military Sniper";
        else if (StrEqual(itemName, "sniper_awp")) itemName = "AWP";
        else if (StrEqual(itemName, "sniper_scout")) itemName = "Scout";
        else if (StrEqual(itemName, "rifle_m60")) itemName = "M60";
        else if (StrEqual(itemName, "grenade_launcher")) itemName = "Grenade Launcher";
        else if (StrEqual(itemName, "pistol")) itemName = "Pistol";
        else if (StrEqual(itemName, "pistol_magnum")) itemName = "Magnum";
        else if (StrEqual(itemName, "chainsaw")) itemName = "Chainsaw";
        // Items and throwables
        else if (StrEqual(itemName, "pain_pills")) itemName = "Pain Pills";
        else if (StrEqual(itemName, "first_aid_kit")) itemName = "First Aid Kit";
        else if (StrEqual(itemName, "defibrillator")) itemName = "Defibrillator";
        else if (StrEqual(itemName, "pipe_bomb")) itemName = "Pipe Bomb";
        else if (StrEqual(itemName, "molotov")) itemName = "Molotov";
        else if (StrEqual(itemName, "vomitjar")) itemName = "Vomit Jar";
        else if (StrEqual(itemName, "upgradepack_incendiary")) itemName = "Incendiary Ammo";
        else if (StrEqual(itemName, "upgradepack_explosive")) itemName = "Explosive Ammo";
        else if (StrEqual(itemName, "adrenaline")) itemName = "Adrenaline";
        else if (StrEqual(itemName, "melee")) itemName = "Melee Weapon";
    }
    
    bool alreadySpotted = false;
    for (int i = 0; i < g_SpottedEntities.Length; i++) {
        SpottedEntity spotted;
        g_SpottedEntities.GetArray(i, spotted);
        if (EntRefToEntIndex(spotted.entityRef) == target) {
            spotted.spotTime = GetGameTime();
            g_SpottedEntities.SetArray(i, spotted);
            alreadySpotted = true;
            break;
        }
    }

    if (!alreadySpotted) {
        SpottedEntity spotted;
        spotted.entityRef = EntIndexToEntRef(target);
        spotted.type = 0;
        spotted.spotTime = GetGameTime();
        spotted.isSpotted = true;
        spotted.spottedBy = client;
        
        g_SpottedEntities.PushArray(spotted);
        
        if (g_hSpotGlow.BoolValue) {
            SetEntProp(target, Prop_Send, "m_iGlowType", 3);
            // White color for all items
            SetEntProp(target, Prop_Send, "m_glowColorOverride", 0xFFFFFF);
        }
        
        // Handle special cases
        if (StrEqual(itemName, "cola_bottles")) itemName = "Cola Bottles";
        else if (StrEqual(itemName, "gnome")) itemName = "Gnome";
        
        SetHudTextParams(-1.0, 0.4, g_hSpotDuration.FloatValue, 255, 255, 0, 255);
        ShowSyncHudText(client, g_hHudSync, "Spotted %s (%.0f units)", itemName, distance);

        if (g_hShowSpotParticle.BoolValue) {
            float targetPos[3];
            GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
            DisplaySpotIcon(client, targetPos);
        }

        if (g_hShowSpotMessages.BoolValue) {
            char spotter_name[MAX_NAME_LENGTH];
            GetClientName(client, spotter_name, sizeof(spotter_name));
            PrintToChatAll("\x01[\x04Spotting\x01] \x03%s\x01 spotted a \x05%s\x01!", spotter_name, itemName);
        }

        if (g_hSpotSoundEnabled.BoolValue) {
            EmitSoundToClient(client, "buttons/blip1.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
        }
    }
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    
    // If a survivor somehow got glow, remove it immediately
    if (IsValidClient(victim) && GetClientTeam(victim) == 2) {
        SetEntProp(victim, Prop_Send, "m_iGlowType", 0);
        SetEntProp(victim, Prop_Send, "m_glowColorOverride", 0);
    }
}

public Action Timer_CheckSurvivorGlow(Handle timer) {
    // Loop through all clients
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) == 2) {  // If it's a survivor
            // Force glow to be off at all times for survivors
            SetEntProp(i, Prop_Send, "m_iGlowType", 0);
            SetEntProp(i, Prop_Send, "m_glowColorOverride", 0);
        }
    }
    return Plugin_Continue;
}