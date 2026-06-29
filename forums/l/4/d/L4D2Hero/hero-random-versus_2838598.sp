#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

Handle g_cvMapCount = INVALID_HANDLE;

// Map Arrays
char g_NormalMaps[][] = {
    "c1m1_hotel", "c1m2_streets", "c1m3_mall",
    "c2m1_highway", "c2m2_fairgrounds", "c2m3_coaster",
    "c3m1_plankcountry", "c3m2_swamp", "c3m3_shantytown",
    "c4m1_milltown_a", "c4m2_sugarmill_a", "c4m3_sugarmill_b",
    "c5m1_waterfront", "c5m2_park", "c5m3_cemetery",
    "c6m1_riverbank", "c6m2_bedlam",
    "c7m1_docks", "c7m2_barge",
    "c8m1_apartment", "c8m2_subway", "c8m3_sewers", "c8m4_interior",
    "c9m1_alleys",
    "c10m1_caves", "c10m2_drainage", "c10m3_ranchhouse", "c10m4_mainstreet",
    "c11m1_greenhouse", "c11m2_offices", "c11m3_garage", "c11m4_terminal",
    "c12m1_hilltop", "c12m2_traintunnel", "c12m3_bridge", "c12m4_barn",
    "c13m1_alpinecreek", "c13m2_southpinestream", "c13m3_memorialbridge"
};

char g_FinaleMaps[][] = {
    "c1m4_atrium",
    "c2m5_concert",
    "c3m4_plantation",
    "c4m5_milltown_escape",
    "c5m5_bridge",
    "c6m3_port",
    "c7m3_port",
    "c8m5_rooftop",
    "c9m2_lots",
    "c10m5_houseboat",
    "c11m5_runway",
    "c12m5_cornfield",
    "c13m4_cutthroatcreek"
};

ArrayList g_GameMapList = null;
int g_CurrentMapIndex = 0;
int g_iTotalMaps = 0;
char g_CurrentMapName[64];
bool g_TournamentActive = false;

// Simplified safe room tracking
int g_SafeRoomExits = 0;  // Count how many times survivors have left safe room on this map
bool g_MapCompleted = false;
bool g_WaitingForRoundEnd = false;  // True when both teams have left safe room, waiting for round to end

public Plugin myinfo = {
    name = "L4D2 Tournament System",
    author = "Hero Random Versus",
    description = "Creates a tournament system for L4D2 with map rotation and scoring using safe room detection.",
    version = "1.3",
    url = ""
};

public void OnPluginStart()
{

    // check if tournament is already active and if so, reset

    if (g_TournamentActive)
    {
        PrintToChatAll("\x04[Tournament]\x01 Tournament is already active. Stopping current tournament...");
        Command_StopTournament(0, 0);
    }


    RegConsoleCmd("sm_startrvs", Command_StartTournament, "Starts the tournament with random maps.");
    RegConsoleCmd("sm_stoprvs", Command_StopTournament, "Stops the current tournament.");
    RegConsoleCmd("sm_rvsmaps", Command_Status, "Displays the current tournament status.");
    RegConsoleCmd("sm_rvsreset", Command_ResetMap, "Reset current map progress (admin only).");

    g_cvMapCount = CreateConVar("l4d2_tournament_maps", "4", "Number of regular maps before finale", FCVAR_NOTIFY, true, 1.0, true, 10.0);
    // Hook events
    HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_Post);
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
    
    GetCurrentMap(g_CurrentMapName, sizeof(g_CurrentMapName));
}

public void OnMapStart()
{
    char newMapName[64];
    GetCurrentMap(newMapName, sizeof(newMapName));
    
    // Reset tracking for new map
    g_SafeRoomExits = 0;
    g_MapCompleted = false;
    g_WaitingForRoundEnd = false;
    
    if (g_TournamentActive && !StrEqual(g_CurrentMapName, newMapName))
    {
        PrintToChatAll("\x04[Tournament]\x01 Map loaded: %s", newMapName);
        
        if (IsMapInTournament(newMapName))
        {
            strcopy(g_CurrentMapName, sizeof(g_CurrentMapName), newMapName);
            UpdateCurrentMapIndex(newMapName);
            
            PrintToChatAll("\x04[Tournament]\x01 Tournament map active: %s (%d/%d)", 
                          newMapName, g_CurrentMapIndex + 1, g_iTotalMaps);
            PrintToChatAll("\x04[Tournament]\x01 Both teams need to play as survivors (leave safe room twice).");
        }
        else
        {
            strcopy(g_CurrentMapName, sizeof(g_CurrentMapName), newMapName);
        }
    }
    else
    {
        strcopy(g_CurrentMapName, sizeof(g_CurrentMapName), newMapName);
    }
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{


    if (!g_TournamentActive || !IsMapInTournament(g_CurrentMapName))
        return;
    
    // Don't reset if we're in the middle of a map completion
    if (g_MapCompleted)
        return;
        
    PrintToChatAll("\x04[Tournament]\x01 Round started on %s (Safe room exits: %d/2)", g_CurrentMapName, g_SafeRoomExits);
    
    if (g_SafeRoomExits == 0)
        PrintToChatAll("\x04[Tournament]\x01 Waiting for first team to play as survivors...");
    else if (g_SafeRoomExits == 1)
        PrintToChatAll("\x04[Tournament]\x01 Waiting for second team to play as survivors...");
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_TournamentActive || !IsMapInTournament(g_CurrentMapName))
        return;
    
    // If we're waiting for the round to end after both teams played, mark as completed
    if (g_WaitingForRoundEnd && g_SafeRoomExits >= 2)
    {
        g_MapCompleted = true;
        g_WaitingForRoundEnd = false;
        
        // Update our map index for tracking
        if (g_CurrentMapIndex >= g_GameMapList.Length - 1)
        {
        //    PrintToChatAll("\x04[Tournament]\x01 🏆 TOURNAMENT COMPLETED! 🏆");
       //     PrintToChatAll("\x04[Tournament]\x01 Second team completed their round on %s!", g_CurrentMapName);
        //    PrintToChatAll("\x04[Tournament]\x01 All maps have been played by both teams!");
        //    PrintToChatAll("\x04[Tournament]\x01 Tournament will restart from the beginning...");
            g_CurrentMapIndex = 0; // Reset for next tournament
        }
        else
        {
        //    PrintToChatAll("\x04[Tournament]\x01 🎉 Second team completed their round on %s!", g_CurrentMapName);
        //    PrintToChatAll("\x04[Tournament]\x01 Both teams have fully played this map!");
            g_CurrentMapIndex++; // Move to next map
        }
        
        PrintToChatAll("\x04[Tournament]\x01 Map will change automatically when round transitions...");
    }
    else
    {
        // Normal round end, just show progress
        if (g_SafeRoomExits == 1)
            PrintToChatAll("\x04[Tournament]\x01 First team completed their round. Waiting for second team...");
    }
}

public void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_TournamentActive || !IsMapInTournament(g_CurrentMapName) || g_MapCompleted)
        return;
    
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsValidClient(client))
        return;
    
    int team = GetClientTeam(client);
    
    // Debug: Show team info
  //  PrintToChatAll("\x04[Tournament]\x01 DEBUG: Player %N (Team %d) left start area", client, team);
    
    // In L4D2, survivors are team 2
    if (team == 2)
    {
        g_SafeRoomExits++;
        
        PrintToChatAll("\x04[Tournament]\x01 Survivors left safe room! (Exit #%d/2)", g_SafeRoomExits);
        
        if (g_SafeRoomExits >= 2)
        {
            // Both teams have left safe room - set next map now and wait for round to end
            g_WaitingForRoundEnd = true;
           // PrintToChatAll("\x04[Tournament]\x01 Both teams have started playing %s as survivors!", g_CurrentMapName);
           // PrintToChatAll("\x04[Tournament]\x01 Waiting for second team to complete their round...");
            
            // Determine and set the next map now
            int nextMapIndex = g_CurrentMapIndex;
            
            // Check if this was the last map
            if (g_CurrentMapIndex >= g_GameMapList.Length - 1)
            {
                PrintToChatAll("\x04[Tournament]\x01 This is the final map of the tournament!");
                nextMapIndex = 0; // Reset to start for next tournament
            }
            else
            {
                nextMapIndex++;
            }
            
            // Set the next map
            char nextMap[64];
            g_GameMapList.GetString(nextMapIndex, nextMap, sizeof(nextMap));
            
            if (IsMapValid(nextMap))
            {
                SetNextMap(nextMap);
                if (g_CurrentMapIndex >= g_GameMapList.Length - 1)
                {
                   // PrintToChatAll("\x04[Tournament]\x01 Next map set to: %s (Tournament restart)", nextMap);
                }
                else
                {
                  //  PrintToChatAll("\x04[Tournament]\x01 Next map set to: %s (%d/%d)", nextMap, nextMapIndex + 1, g_GameMapList.Length);
                }
            }
            else
            {
                PrintToChatAll("\x04[Tournament]\x01 Error: Invalid next map: %s", nextMap);
            }
        }
        else
        {
            //PrintToChatAll("\x04[Tournament]\x01 First team completed! Waiting for second team to play as survivors...");
        }
    }
    else
    {
        // Not a survivor, ignore
       // PrintToChatAll("\x04[Tournament]\x01 DEBUG: Non-survivor left start area, ignoring.");
    }
}

public Action Command_ResetMap(int client, int args)
{
    if (!IsClientInGame(client) || !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
    {
        PrintToChat(client, "\x04[Tournament]\x01 Admin access required.");
        return Plugin_Handled;
    }
    
    g_SafeRoomExits = 0;
    g_MapCompleted = false;
    g_WaitingForRoundEnd = false;
    
    PrintToChatAll("\x04[Tournament]\x01 Map progress reset by admin. Both teams need to play again.");
    return Plugin_Handled;
}

public Action Command_Status(int client, int args)
{
    if (!g_TournamentActive || g_GameMapList == null || g_GameMapList.Length == 0)
    {
        PrintToChat(client, "\x04[Tournament]\x01 No tournament is currently active.");
        return Plugin_Handled;
    }

    g_iTotalMaps = g_GameMapList.Length;
    
    PrintToChat(client, "\x04[Tournament]\x01 Tournament Status:");
    PrintToChat(client, "\x04[Tournament]\x01 Current map: %s (%d/%d)", g_CurrentMapName, g_CurrentMapIndex + 1, g_iTotalMaps);
  //  PrintToChat(client, "\x04[Tournament]\x01 Safe room exits: %d/2", g_SafeRoomExits);
  //  PrintToChat(client, "\x04[Tournament]\x01 Waiting for round end: %s", g_WaitingForRoundEnd ? "Yes" : "No");
    PrintToChat(client, "\x04[Tournament]\x01 Map completed: %s", g_MapCompleted ? "Yes" : "No");
    
    // Show map list
    PrintToChatAll("\x04[Tournament]\x01 Tournament map list:");
    for (int i = 0; i < g_iTotalMaps; i++)
    {
        char map[64];
        g_GameMapList.GetString(i, map, sizeof(map));
        char status[32] = "";
        
        if (i < g_CurrentMapIndex)
            strcopy(status, sizeof(status), " ✅ Completed");
        else if (i == g_CurrentMapIndex)
        {
            if (g_MapCompleted)
                strcopy(status, sizeof(status), " ⏳ Advancing...");
            else if (g_WaitingForRoundEnd)
                strcopy(status, sizeof(status), " ⏱️ Waiting for round end");
            else if (g_SafeRoomExits == 0)
                strcopy(status, sizeof(status), " 🔄 Waiting for Team 1");
            else if (g_SafeRoomExits == 1)
                strcopy(status, sizeof(status), " 🔄 Waiting for Team 2");
            else
                strcopy(status, sizeof(status), " 🎉 Both teams played");
        }
        else
            strcopy(status, sizeof(status), " ⏸️ Pending");
            
        PrintToChatAll("\x04[Tournament]\x01 %d. %s%s%s", i + 1, map, 
                       (i == g_iTotalMaps - 1) ? " (FINALE)" : "", status);
    }
    
    return Plugin_Handled;
}   

public Action Command_StartTournament(int client, int args)
{
    if (!IsClientInGame(client))
    {
        PrintToChat(client, "\x04[Tournament]\x01 You must be in-game to start a tournament.");
        return Plugin_Handled;
    }

    // check if tournament is already active force reset 
    if (g_TournamentActive)
    {
        PrintToChatAll("\x04[Tournament]\x01 Tournament is already active. Stopping current tournament...");
        Command_StopTournament(client, args);
    }

    if (g_GameMapList == null)
    {
        g_GameMapList = new ArrayList(64);
    }
    else
    {
        g_GameMapList.Clear();
    }

    // Initialize the tournament system
    g_CurrentMapIndex = 0;
    g_TournamentActive = true;
    g_SafeRoomExits = 0;
    g_MapCompleted = false;
    g_WaitingForRoundEnd = false;


    GenerateMapList();
    
    GetCurrentMap(g_CurrentMapName, sizeof(g_CurrentMapName));
    
    PrintToChatAll("\x04[Tournament]\x01 Tournament started with %d maps.", g_GameMapList.Length);
    PrintToChatAll("\x04[Tournament]\x01 Each map requires both teams to play as survivors (leave safe room).");
    
    CreateTimer(2.0, Timer_LoadFirstMap);
    
    return Plugin_Handled;
}

public Action Timer_LoadFirstMap(Handle timer)
{
    if (g_GameMapList == null || g_GameMapList.Length == 0)
    {
        PrintToChatAll("\x04[Tournament]\x01 No maps available for the tournament.");
        return Plugin_Handled;
    }

    g_CurrentMapIndex = 0;
    g_SafeRoomExits = 0;
    g_MapCompleted = false;
    g_WaitingForRoundEnd = false;
    
    char firstMap[64];
    g_GameMapList.GetString(g_CurrentMapIndex, firstMap, sizeof(firstMap));
    
    if (StrEqual(g_CurrentMapName, firstMap))
    {
        PrintToChatAll("\x04[Tournament]\x01 Already on first tournament map: %s", firstMap);
        PrintToChatAll("\x04[Tournament]\x01 Tournament begins now! Waiting for first team to leave safe room...");
    }
    else
    {
        PrintToChatAll("\x04[Tournament]\x01 Loading first tournament map: %s", firstMap);
        
        if (!IsMapValid(firstMap))
        {
            PrintToChatAll("\x04[Tournament]\x01 Invalid map: %s", firstMap);
            return Plugin_Handled;
        }

        // we need to force the first map change 
        ForceChangeLevel(firstMap, "Loading first tournament map...");
    }
    
    return Plugin_Handled;
}

public Action Command_StopTournament(int client, int args)
{
    if (!IsClientInGame(client))
    {
        PrintToChat(client, "\x04[Tournament]\x01 You must be in-game to stop a tournament.");
        return Plugin_Handled;
    }

    g_TournamentActive = false;
    g_SafeRoomExits = 0;
    g_MapCompleted = false;
    g_WaitingForRoundEnd = false;
    g_CurrentMapIndex = 0;

    if (g_GameMapList != null)
    {
        delete g_GameMapList;
        g_GameMapList = null;
    }
    
    PrintToChatAll("\x04[Tournament]\x01 Tournament stopped.");
    
    return Plugin_Handled;
}

// ================================
// Helper Functions
// ================================
bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

bool IsMapInTournament(const char[] mapName)
{
    if (g_GameMapList == null)
        return false;
        
    for (int i = 0; i < g_GameMapList.Length; i++)
    {
        char tournamentMap[64];
        g_GameMapList.GetString(i, tournamentMap, sizeof(tournamentMap));
        if (StrEqual(mapName, tournamentMap))
            return true;
    }
    return false;
}

void UpdateCurrentMapIndex(const char[] mapName)
{
    if (g_GameMapList == null)
        return;
        
    for (int i = 0; i < g_GameMapList.Length; i++)
    {
        char tournamentMap[64];
        g_GameMapList.GetString(i, tournamentMap, sizeof(tournamentMap));
        if (StrEqual(mapName, tournamentMap))
        {
            g_CurrentMapIndex = i;
            return;
        }
    }
}

void GenerateMapList()
{
    int mapCount = GetConVarInt(g_cvMapCount);
    
    ArrayList tempList = new ArrayList(64);
    for (int i = 0; i < sizeof(g_NormalMaps); i++)
    {
        tempList.PushString(g_NormalMaps[i]);
    }
    
    for (int i = 0; i < mapCount && tempList.Length > 0; i++)
    {
        int index = GetRandomInt(0, tempList.Length - 1);
        char map[64];
        tempList.GetString(index, map, sizeof(map));
        g_GameMapList.PushString(map);
        tempList.Erase(index);
    }
    
    delete tempList;
    
    int finaleIndex = GetRandomInt(0, sizeof(g_FinaleMaps) - 1);
    g_GameMapList.PushString(g_FinaleMaps[finaleIndex]);
    
    g_iTotalMaps = g_GameMapList.Length;
    
    PrintToChatAll("\x04[Tournament]\x01 Map list generated:");
    for (int i = 0; i < g_iTotalMaps; i++)
    {
        char map[64];
        g_GameMapList.GetString(i, map, sizeof(map));
        PrintToChatAll("\x04[Tournament]\x01 %d. %s%s", i + 1, map, 
                       (i == g_iTotalMaps - 1) ? " (FINALE)" : "");
    }
}