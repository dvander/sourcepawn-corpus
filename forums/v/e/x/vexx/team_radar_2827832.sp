#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>

#pragma newdecls required

#define CONFIG_FILE "configs/tf2_team_radar.cfg"
#define RADAR_X 0.01 // Default X position of the radar
#define RADAR_Y 0.01 // Default Y position of the radar
#define ELEVATION_THRESHOLD 170.0  // Units to consider a significant elevation difference

// Color definitions
int g_ColorSelf[4] = {255, 255, 0, 255};
int g_ColorTeammateHealthy[4] = {0, 255, 0, 255};
int g_ColorTeammateLow[4] = {255, 0, 0, 255};
int g_ColorPing[4] = {255, 255, 0, 255};

// Color presets
enum struct ColorPreset {
    char name[32];
    int color[4];
}

ColorPreset g_ColorPresets[10] = {
    {"Default", {255, 255, 0, 255}},      // Self (Yellow)
    {"Green", {0, 255, 0, 255}},          // Healthy
    {"Red", {255, 0, 0, 255}},            // Low Health
    {"Blue", {0, 0, 255, 255}},
    {"Yellow", {255, 255, 0, 255}},
    {"Purple", {128, 0, 128, 255}},
    {"Cyan", {0, 255, 255, 255}},
    {"Orange", {255, 165, 0, 255}},
    {"Pink", {255, 192, 203, 255}},
    {"White", {255, 255, 255, 255}}
};


// Elevation icons
char g_ElevationIcons[3][] = {"▽", "●", "△"};  // Below, Same, Above

// Plugin information
public Plugin myinfo = {
    name = "TF2 Team Radar",
    author = "vexx-sm",
    description = "Adds a basic team-only radar to Team Fortress 2.",
    version = "1.5.0",
    url = "https://github.com/vexx-sm/tf2-team-radar"
};

// ConVars
ConVar g_cvUpdateInterval;
ConVar g_cvRadarSize;
ConVar g_cvRadarScale;
ConVar g_cvShowDisguisedSpies;
ConVar g_cvMaxPings;
ConVar g_cvPingDuration;
ConVar g_cvPingCooldown;

// Handles
Handle g_hUpdateTimer;
Handle g_hRadarXCookie;
Handle g_hRadarYCookie;
Handle g_hSelfColorCookie;
Handle g_hHealthyColorCookie;
Handle g_hLowHealthColorCookie;
Handle g_hPingColorCookie;

// Player-specific data
bool g_bRadarEnabled[MAXPLAYERS + 1] = {true, ...};
float g_PingPositions[MAXPLAYERS + 1][32][3];
float g_PingTimes[MAXPLAYERS + 1][32];
float g_LastPingTime[MAXPLAYERS + 1];
float g_fRadarX[MAXPLAYERS + 1] = {RADAR_X, ...};
float g_fRadarY[MAXPLAYERS + 1] = {RADAR_Y, ...};

// Constants
float g_fPositionStep = 0.01; // The amount to move the radar each time
bool g_bConfigLoaded = false;

public void OnPluginStart() {
    LoadConfig();
    
    // Create timer for updating the radar
    g_hUpdateTimer = CreateTimer(g_cvUpdateInterval.FloatValue, Timer_UpdateMiniMap, _, TIMER_REPEAT);
    
    // Register commands
    RegConsoleCmd("sm_radar", Command_RadarMenu, "Open the radar menu");
    RegConsoleCmd("sm_pingradar", Command_Ping, "Ping your current location on the radar");
    RegAdminCmd("sm_reloadradar", Command_ReloadConfig, ADMFLAG_CONFIG, "Reload the Radar config");
    
    // Register client cookies
    g_hRadarXCookie = RegClientCookie("tf2_team_radar_x", "Radar X Position", CookieAccess_Protected);
    g_hRadarYCookie = RegClientCookie("tf2_team_radar_y", "Radar Y Position", CookieAccess_Protected);
    g_hSelfColorCookie = RegClientCookie("tf2_team_radar_self_color", "Radar Self Color", CookieAccess_Protected);
    g_hHealthyColorCookie = RegClientCookie("tf2_team_radar_healthy_color", "Radar Healthy Color", CookieAccess_Protected);
    g_hLowHealthColorCookie = RegClientCookie("tf2_team_radar_low_color", "Radar Low Health Color", CookieAccess_Protected);
    g_hPingColorCookie = RegClientCookie("tf2_team_radar_ping_color", "Radar Ping Color", CookieAccess_Protected);
}

void LoadConfig() {
    char configPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, configPath, sizeof(configPath), CONFIG_FILE);
    
    if (!FileExists(configPath)) {
        LogMessage("Configuration file %s not found. Creating default configuration.", configPath);
        CreateDefaultConfig(configPath);
    }
    
    KeyValues kv = new KeyValues("TF2TeamRadar");
    if (!kv.ImportFromFile(configPath)) {
        LogError("Error loading configuration file %s", configPath);
        delete kv;
        return;
    }
    
    // Create and set ConVars
    g_cvUpdateInterval = CreateConVar("sm_radar_update_interval", "0.1", "How often the radar updates (in seconds)");
    g_cvRadarSize = CreateConVar("sm_radar_size", "2560.0", "The in-game units the radar covers");
    g_cvRadarScale = CreateConVar("sm_radar_scale", "0.225", "The size of the radar on the screen (0-1)");
    g_cvShowDisguisedSpies = CreateConVar("sm_radar_show_disguised_spies", "1", "Show disguised enemy spies on the radar (0 = No, 1 = Yes)");
    g_cvMaxPings = CreateConVar("sm_radar_max_pings", "5", "Maximum pings to show at a time");
    g_cvPingDuration = CreateConVar("sm_radar_ping_duration", "5.0", "Duration of each ping in seconds");
    g_cvPingCooldown = CreateConVar("sm_radar_ping_cooldown", "3.0", "Cooldown between pings in seconds");
    
    g_cvUpdateInterval.SetFloat(kv.GetFloat("update_interval", 0.1));
    g_cvRadarSize.SetFloat(kv.GetFloat("radar_size", 2560.0));
    g_cvRadarScale.SetFloat(kv.GetFloat("radar_scale", 0.225));
    g_cvShowDisguisedSpies.SetBool(view_as<bool>(kv.GetNum("show_disguised_spies", 1)));
    g_cvMaxPings.SetInt(kv.GetNum("max_pings", 5));
    g_cvPingDuration.SetFloat(kv.GetFloat("ping_duration", 5.0));
    g_cvPingCooldown.SetFloat(kv.GetFloat("ping_cooldown", 3.0));
    
    // Load colors
    char colorBuffer[16];
    kv.GetString("color_self", colorBuffer, sizeof(colorBuffer), "255 255 0 255");
    ParseColor(colorBuffer, g_ColorSelf);
    kv.GetString("color_teammate_healthy", colorBuffer, sizeof(colorBuffer), "0 255 0 255");
    ParseColor(colorBuffer, g_ColorTeammateHealthy);
    kv.GetString("color_teammate_low", colorBuffer, sizeof(colorBuffer), "255 0 0 255");
    ParseColor(colorBuffer, g_ColorTeammateLow);
    kv.GetString("color_ping", colorBuffer, sizeof(colorBuffer), "255 255 0 255");
    ParseColor(colorBuffer, g_ColorPing);
    
    delete kv;
    g_bConfigLoaded = true;
    LogMessage("Radar configuration loaded successfully.");
}

void CreateDefaultConfig(const char[] path) {
    KeyValues kv = new KeyValues("TF2TeamRadar");
    
    kv.SetFloat("update_interval", 0.1);
    kv.SetFloat("radar_size", 2560.0);
    kv.SetFloat("radar_scale", 0.225);
    kv.SetNum("show_disguised_spies", 1);
    kv.SetString("color_self", "255 255 0 255");
    kv.SetString("color_teammate_healthy", "0 255 0 255");
    kv.SetString("color_teammate_low", "255 0 0 255");
    kv.SetString("color_ping", "255 255 0 255");
    kv.SetNum("max_pings", 5);
    kv.SetFloat("ping_duration", 5.0);
    kv.SetFloat("ping_cooldown", 3.0);
    
    if (!kv.ExportToFile(path)) {
        LogError("Failed to create default configuration file at %s", path);
    } else {
        LogMessage("Created default configuration file at %s", path);
    }
    
    delete kv;
}

void ParseColor(const char[] colorString, int color[4]) {
    char parts[4][4];
    ExplodeString(colorString, " ", parts, sizeof(parts), sizeof(parts[]));
    
    for (int i = 0; i < 4; i++) {
        color[i] = StringToInt(parts[i]);
    }
}

public void OnPluginEnd() {
    delete g_hUpdateTimer;
}

public void OnClientConnected(int client) {
    g_bRadarEnabled[client] = true;
}

public void OnClientCookiesCached(int client) {
    LoadRadarPosition(client);
    LoadColorPreferences(client);  
}

void LoadColorPreferences(int client) {
    char buffer[32];
    
    GetClientCookie(client, g_hSelfColorCookie, buffer, sizeof(buffer));
    if (buffer[0] != '\0') {
        ParseColorString(buffer, g_ColorSelf);
    }
    
    GetClientCookie(client, g_hHealthyColorCookie, buffer, sizeof(buffer));
    if (buffer[0] != '\0') {
        ParseColorString(buffer, g_ColorTeammateHealthy);
    }
    
    GetClientCookie(client, g_hLowHealthColorCookie, buffer, sizeof(buffer));
    if (buffer[0] != '\0') {
        ParseColorString(buffer, g_ColorTeammateLow);
    }
    
    GetClientCookie(client, g_hPingColorCookie, buffer, sizeof(buffer));
    if (buffer[0] != '\0') {
        ParseColorString(buffer, g_ColorPing);
    }
}

void ParseColorString(const char[] colorStr, int color[4]) {
    char parts[4][8];
    ExplodeString(colorStr, " ", parts, sizeof(parts), sizeof(parts[]));
    
    for (int i = 0; i < 4; i++) {
        color[i] = StringToInt(parts[i]);
    }
}

void LoadRadarPosition(int client) {
    char sValue[16];
    
    GetClientCookie(client, g_hRadarXCookie, sValue, sizeof(sValue));
    if (sValue[0] != '\0')
        g_fRadarX[client] = StringToFloat(sValue);
    else
        g_fRadarX[client] = RADAR_X;
    
    GetClientCookie(client, g_hRadarYCookie, sValue, sizeof(sValue));
    if (sValue[0] != '\0')
        g_fRadarY[client] = StringToFloat(sValue);
    else
        g_fRadarY[client] = RADAR_Y;
}

void SaveRadarPosition(int client) {
    char sValue[16];
    
    FloatToString(g_fRadarX[client], sValue, sizeof(sValue));
    SetClientCookie(client, g_hRadarXCookie, sValue);
    
    FloatToString(g_fRadarY[client], sValue, sizeof(sValue));
    SetClientCookie(client, g_hRadarYCookie, sValue);
}

public Action Command_RadarMenu(int client, int args) {
    if (client == 0) {
        ReplyToCommand(client, "This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    ShowRadarMenu(client);
    return Plugin_Handled;
}

void ShowRadarMenu(int client) {
    Menu menu = new Menu(RadarMenuHandler);
    menu.SetTitle("Radar Menu");
    menu.AddItem("toggle", g_bRadarEnabled[client] ? "Disable Radar" : "Enable Radar");
    menu.AddItem("position", "Adjust Position");
    menu.AddItem("colors", "Change Colors");
    if (CheckCommandAccess(client, "sm_reloadradar", ADMFLAG_CONFIG)) {
        menu.AddItem("reload", "Reload Configuration");
        char spiesInfo[64];
        FormatEx(spiesInfo, sizeof(spiesInfo), "Show Disguised Spies: %s", g_cvShowDisguisedSpies.BoolValue ? "On" : "Off");
        menu.AddItem("spies", spiesInfo);
    }
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowPositionMenu(int client) {
    Menu menu = new Menu(PositionMenuHandler);
    menu.SetTitle("Adjust Radar Position");
    menu.AddItem("up", "Move Up");
    menu.AddItem("down", "Move Down");
    menu.AddItem("left", "Move Left");
    menu.AddItem("right", "Move Right");
    menu.AddItem("reset", "Reset to Default");
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowColorMenu(int client) {
    Menu menu = new Menu(ColorMenuHandler);
    menu.SetTitle("Radar Color Settings");
    
    menu.AddItem("self", "Self Icon Color");
    menu.AddItem("healthy", "Healthy Teammate Color");
    menu.AddItem("damaged", "Damaged Teammate Color");
    menu.AddItem("ping", "Ping Color");
    menu.AddItem("reset", "Reset All Colors");
    
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int ColorMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            
            if (StrEqual(info, "reset")) {
                ResetAllColors(param1);
                PrintToChat(param1, "Radar colors have been reset.");
                ShowColorMenu(param1);
            } else {
                ShowColorSelectionMenu(param1, info);
            }
        }
        case MenuAction_Cancel: {
            if (param2 == MenuCancel_ExitBack) {
                ShowRadarMenu(param1);
            }
        }
        case MenuAction_End: {
            delete menu;
        }
    }
    return 0;
}

void ShowColorSelectionMenu(int client, const char[] elementType) {
    Menu menu = new Menu(ColorSelectionHandler);
    menu.SetTitle("Select Color");
    
    for (int i = 0; i < sizeof(g_ColorPresets); i++) {
        char indexStr[8];
        IntToString(i, indexStr, sizeof(indexStr));
        menu.AddItem(indexStr, g_ColorPresets[i].name);
    }
    
    menu.ExitBackButton = true;
    PushMenuString(menu, "element", elementType);
    menu.Display(client, MENU_TIME_FOREVER);
}

public int ColorSelectionHandler(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char elementType[32], indexStr[8];
            GetMenuString(menu, "element", elementType, sizeof(elementType));
            menu.GetItem(param2, indexStr, sizeof(indexStr));
            int colorIndex = StringToInt(indexStr);
            
            if (StrEqual(elementType, "self")) {
                if (colorIndex == 0) colorIndex = 0;  // Yellow for Default
                SetClientColorPreference(param1, g_hSelfColorCookie, g_ColorPresets[colorIndex].color);
                g_ColorSelf = g_ColorPresets[colorIndex].color;
            } else if (StrEqual(elementType, "healthy")) {
                if (colorIndex == 0) colorIndex = 1;  // Green for Default
                SetClientColorPreference(param1, g_hHealthyColorCookie, g_ColorPresets[colorIndex].color);
                g_ColorTeammateHealthy = g_ColorPresets[colorIndex].color;
            } else if (StrEqual(elementType, "damaged")) {
                if (colorIndex == 0) colorIndex = 2;  // Red for Default
                SetClientColorPreference(param1, g_hLowHealthColorCookie, g_ColorPresets[colorIndex].color);
                g_ColorTeammateLow = g_ColorPresets[colorIndex].color;
            } else if (StrEqual(elementType, "ping")) {
                if (colorIndex == 0) colorIndex = 0;  // Yellow for Default
                SetClientColorPreference(param1, g_hPingColorCookie, g_ColorPresets[colorIndex].color);
                g_ColorPing = g_ColorPresets[colorIndex].color;
            }
            
            ShowColorSelectionMenu(param1, elementType);
        }
        case MenuAction_Cancel: {
            if (param2 == MenuCancel_ExitBack) {
                ShowColorMenu(param1);
            }
        }
        case MenuAction_End: {
            delete menu;
        }
    }
    return 0;
}

void SetClientColorPreference(int client, Handle cookie, int color[4]) {
    char colorStr[32];
    FormatEx(colorStr, sizeof(colorStr), "%d %d %d %d", color[0], color[1], color[2], color[3]);
    SetClientCookie(client, cookie, colorStr);
}

void ResetAllColors(int client) {
    // Self = Yellow (Default)
    SetClientColorPreference(client, g_hSelfColorCookie, g_ColorPresets[0].color);
    g_ColorSelf = g_ColorPresets[0].color;
    
    // Healthy = Green
    SetClientColorPreference(client, g_hHealthyColorCookie, g_ColorPresets[1].color);
    g_ColorTeammateHealthy = g_ColorPresets[1].color;
    
    // Damaged = Red
    SetClientColorPreference(client, g_hLowHealthColorCookie, g_ColorPresets[2].color);
    g_ColorTeammateLow = g_ColorPresets[2].color;
    
    // Pings = Yellow (Default)
    SetClientColorPreference(client, g_hPingColorCookie, g_ColorPresets[0].color);
    g_ColorPing = g_ColorPresets[0].color;
}



public int RadarMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            
            if (StrEqual(info, "toggle")) {
                g_bRadarEnabled[param1] = !g_bRadarEnabled[param1];
                PrintToChat(param1, "Radar has been %s.", g_bRadarEnabled[param1] ? "enabled" : "disabled");
            }
            else if (StrEqual(info, "position")) {
                ShowPositionMenu(param1);
                return 0;
            }
			else if (StrEqual(info, "colors")) {
                ShowColorMenu(param1);
                return 0;
            }
			else if (StrEqual(info, "reload")) {
                FakeClientCommand(param1, "sm_reloadradar");
            }
			else if (StrEqual(info, "spies")) {
                g_cvShowDisguisedSpies.SetBool(!g_cvShowDisguisedSpies.BoolValue);
                PrintToChat(param1, "Show Disguised Spies: %s", g_cvShowDisguisedSpies.BoolValue ? "On" : "Off");
            }
            ShowRadarMenu(param1); // Show the menu again after any action
        }
        case MenuAction_End: {
            delete menu;
        }
    }
    return 0;
}

public int PositionMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            
            if (StrEqual(info, "up")) {
                g_fRadarY[param1] = max(0.0, g_fRadarY[param1] - g_fPositionStep);
            }
            else if (StrEqual(info, "down")) {
                g_fRadarY[param1] = min(1.0 - g_cvRadarScale.FloatValue, g_fRadarY[param1] + g_fPositionStep);
            }
            else if (StrEqual(info, "left")) {
                g_fRadarX[param1] = max(0.0, g_fRadarX[param1] - g_fPositionStep);
            }
            else if (StrEqual(info, "right")) {
                g_fRadarX[param1] = min(1.0 - g_cvRadarScale.FloatValue, g_fRadarX[param1] + g_fPositionStep);
            }
            else if (StrEqual(info, "reset")) {
                g_fRadarX[param1] = RADAR_X;
                g_fRadarY[param1] = RADAR_Y;
            }
            
            SaveRadarPosition(param1);
            ShowPositionMenu(param1);
        }
        case MenuAction_Cancel: {
            if (param2 == MenuCancel_ExitBack || param2 == MenuCancel_Exit) {
                PrintToChat(param1, "Radar position updated and saved.");
                if (param2 == MenuCancel_ExitBack) {
                    ShowRadarMenu(param1);
                }
            }
        }
        case MenuAction_End: {
            delete menu;
        }
    }
    return 0;
}

public Action Command_ReloadConfig(int client, int args) {
    LogMessage("Reloading radar configuration...");
    LoadConfig();
    if (g_bConfigLoaded) {
        ReplyToCommand(client, "[Radar] Configuration reloaded successfully.");
        
        // Recreate the timer with the new update interval
        delete g_hUpdateTimer;
        g_hUpdateTimer = CreateTimer(g_cvUpdateInterval.FloatValue, Timer_UpdateMiniMap, _, TIMER_REPEAT);
    }
    else {
        ReplyToCommand(client, "[Radar] Failed to reload configuration. Check server logs for details.");
    }
    
    return Plugin_Handled;
}

public Action Command_Ping(int client, int args) {
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return Plugin_Handled;
    
    float currentTime = GetGameTime();
    if (currentTime - g_LastPingTime[client] < g_cvPingCooldown.FloatValue) {
        PrintToChat(client, "You must wait before pinging again.");
        return Plugin_Handled;
    }
    
    float eyePos[3], eyeAng[3], endPos[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, eyeAng);
    
    TR_TraceRayFilter(eyePos, eyeAng, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
    
    if (TR_DidHit()) {
        TR_GetEndPosition(endPos);
        
        // Find the oldest ping slot and replace it
        int oldestIndex = 0;
        float oldestTime = g_PingTimes[client][0];
        for (int i = 1; i < g_cvMaxPings.IntValue; i++) {
            if (g_PingTimes[client][i] < oldestTime) {
                oldestIndex = i;
                oldestTime = g_PingTimes[client][i];
            }
        }
        g_PingPositions[client][oldestIndex] = endPos;
        g_PingTimes[client][oldestIndex] = currentTime;
        g_LastPingTime[client] = currentTime;
        PrintToTeam(client, "Teammate has pinged a location!");
    }
    else {
        PrintToChat(client, "Couldn't find a valid position to ping.");
    }
    return Plugin_Handled;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask, any data) {
    return entity != data;
}

public Action Timer_UpdateMiniMap(Handle timer) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && IsClientInGame(i) && g_bRadarEnabled[i]) {
            UpdateMiniMap(i);
        }
    }
    return Plugin_Continue;
}

void DrawElevationIcon(int client, float x, float y, int color[4], const char[] icon) {
    Handle hud = CreateHudSynchronizer();
    SetHudTextParams(x, y, g_cvUpdateInterval.FloatValue + 0.1, color[0], color[1], color[2], color[3]);
    ShowSyncHudText(client, hud, icon);
    delete hud;
}

void UpdateMiniMap(int client) {
    if (!IsPlayerAlive(client)) return;
    
    float playerPos[3], playerAng[3];
    GetClientAbsOrigin(client, playerPos);
    GetClientAbsAngles(client, playerAng);
    
    float x = g_fRadarX[client];
    float y = g_fRadarY[client];
    float w = g_cvRadarScale.FloatValue;
    float h = g_cvRadarScale.FloatValue;
    float centerX = x + (w / 2);
    float centerY = y + (h / 2);
    
    DrawPanel(client, x, y);
    DrawArrow(client, centerX, centerY, g_ColorSelf);
    
    float currentTime = GetGameTime();
    for (int i = 1; i <= MaxClients; i++) {
        if (i != client && IsValidClient(i) && IsClientInGame(i) && IsPlayerAlive(i)) {
            int clientTeam = GetClientTeam(client);
            int targetTeam = GetClientTeam(i);
            bool shouldShow = false;
            
            // Check if the player is a teammate
            if (targetTeam == clientTeam) {
                shouldShow = true;
            }
            // Check if the player is an enemy Spy disguised as a teammate
            else if (g_cvShowDisguisedSpies.BoolValue && TF2_GetPlayerClass(i) == TFClass_Spy && TF2_IsPlayerInCondition(i, TFCond_Disguised)) {
                int disguiseTeam = GetEntProp(i, Prop_Send, "m_nDisguiseTeam");
                if (disguiseTeam == clientTeam) {
                    shouldShow = true;
                }
            }
            
            if (shouldShow) {
                float targetPos[3], relativePos[3];
                GetClientAbsOrigin(i, targetPos);
                SubtractVectors(targetPos, playerPos, relativePos);
                
                float angle = ThisDegToRad(-playerAng[1] - 270);
                float rotatedX = relativePos[0] * Cosine(angle) - relativePos[1] * Sine(angle);
                float rotatedY = relativePos[0] * Sine(angle) + relativePos[1] * Cosine(angle);
                
                float dotX = centerX + (rotatedX / g_cvRadarSize.FloatValue) * w;
                float dotY = centerY - (rotatedY / g_cvRadarSize.FloatValue) * h;
                
                if (dotX >= x && dotX <= x + w && dotY >= y && dotY <= y + h) {
                    int health = GetClientHealth(i);
                    int maxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");
                    float healthPercentage = float(health) / float(maxHealth);
                    
                    int color[4];
                    if (healthPercentage <= 0.5) {
                        color = g_ColorTeammateLow;
                    } else {
                        color = g_ColorTeammateHealthy;
                    }
                    
                    // Calculate elevation difference
                    float elevationDiff = targetPos[2] - playerPos[2];
                    int elevationIndex = 1;  // Default to same level
                    if (elevationDiff > ELEVATION_THRESHOLD) {
                        elevationIndex = 2;  // Above
                    } else if (elevationDiff < -ELEVATION_THRESHOLD) {
                        elevationIndex = 0;  // Below
                    }
                    
                    DrawElevationIcon(client, dotX, dotY, color, g_ElevationIcons[elevationIndex]);
                }
            }
        }
    }
    
    // Draw pings
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client)) {
            for (int j = 0; j < g_cvMaxPings.IntValue; j++) {
                if (currentTime - g_PingTimes[i][j] < g_cvPingDuration.FloatValue) {
                    float pingPos[3], relativePos[3];
                    pingPos = g_PingPositions[i][j];
                    SubtractVectors(pingPos, playerPos, relativePos);
                    
                    float angle = ThisDegToRad(-playerAng[1] - 270);
                    float rotatedX = relativePos[0] * Cosine(angle) - relativePos[1] * Sine(angle);
                    float rotatedY = relativePos[0] * Sine(angle) + relativePos[1] * Cosine(angle);
                    
                    float pingX = centerX + (rotatedX / g_cvRadarSize.FloatValue) * w;
                    float pingY = centerY - (rotatedY / g_cvRadarSize.FloatValue) * h;
                    
                    if (pingX >= x && pingX <= x + w && pingY >= y && pingY <= y + h) {
                        DrawPing(client, pingX, pingY, g_ColorPing);
                    }
                }
            }
        }
    }
}

void DrawPanel(int client, float x, float y) {
    Handle hud = CreateHudSynchronizer();
    SetHudTextParams(x, y, g_cvUpdateInterval.FloatValue + 0.1, 255, 255, 255, 0);
    ShowSyncHudText(client, hud, "");
    delete hud;
    
    int clients[1];
    clients[0] = client;
    
    Handle message = StartMessageEx(GetUserMessageId("VGUIMenu"), clients, 1);
    BfWriteString(message, "radar_background");
    BfWriteByte(message, true);
    BfWriteByte(message, 0);
    EndMessage();
}

void DrawArrow(int client, float x, float y, int color[4]) {
    Handle hud = CreateHudSynchronizer();
    SetHudTextParams(x, y, g_cvUpdateInterval.FloatValue + 0.1, color[0], color[1], color[2], color[3]);
    ShowSyncHudText(client, hud, "⮝");
    delete hud;
}

void DrawPing(int client, float x, float y, int color[4]) {
    Handle hud = CreateHudSynchronizer();
    SetHudTextParams(x, y, g_cvUpdateInterval.FloatValue + 0.1, color[0], color[1], color[2], color[3]);
    ShowSyncHudText(client, hud, "!");
    delete hud;
}

void PrintToTeam(int client, const char[] message) {
    int team = GetClientTeam(client);
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && IsClientInGame(i) && GetClientTeam(i) == team) {
            PrintToChat(i, message);
        }
    }
}

void PushMenuString(Menu menu, const char[] unused, const char[] value) {
    char buffer[256];
    menu.GetTitle(buffer, sizeof(buffer));
    Format(buffer, sizeof(buffer), "%s|%s", buffer, value);
    menu.SetTitle(buffer);
}

void GetMenuString(Menu menu, const char[] unused, char[] buffer, int maxlength) {
    char title[256];
    menu.GetTitle(title, sizeof(title));
    
    int splitIndex = StrContains(title, "|");
    if (splitIndex != -1) {
        strcopy(buffer, maxlength, title[splitIndex + 1]);
    }
}

bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientConnected(client));
}

float ThisDegToRad(float degrees) {
    return degrees * 0.017453293;
}


// Helper functions for min and max
float max(float a, float b) {
    return (a > b) ? a : b;
}

float min(float a, float b) {
    return (a < b) ? a : b;
}