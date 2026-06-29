#include <regex>
#include <sdktools>
#include <files>
#include <keyvalues>
#include <nextmap>

ArrayList g_currentMaps; // store and refresh mapgroup map list every map change and match end
StringMap g_excludedMaps; // store previous maps at end of match

int g_maxExcludedTimes = 0;
int g_mode = 1;
char g_fileName[PLATFORM_MAX_PATH] = "endmatchvote.txt";
char g_lastMap[PLATFORM_MAX_PATH] ;
char g_currentMap[PLATFORM_MAX_PATH] ;
int isFirstMap = 0;

public PrintToConsoleAndServer(int client, char[] text, any...)
{
    char buffer[512];
    VFormat(buffer, sizeof(buffer), text, 3);
    PrintToConsole(client, buffer);
    PrintToServer(buffer);
}

public void OnPluginStart()
{
    g_excludedMaps = new StringMap();      
    HookEventEx("cs_win_panel_match", cs_win_panel_match);
    PrintToServer("[EndMatchMapGroupVote] LoadPersistantExcludedMaps");
    RegAdminCmd("sm_endmatchvote_max", Cmd_ExcludedMatches, ADMFLAG_CONFIG, "Configure the number of matches an already played map must be excluded. 0 for infinite.");
    RegAdminCmd("sm_endmatchvote_mode", Cmd_SetMode, ADMFLAG_CONFIG, "Configure the persistant (1) or temporary (2) memory of the already played maps");
    RegAdminCmd("sm_endmatchvote_reset", Cmd_Reset, ADMFLAG_CONFIG, "Reset the excluded maps");
    RegAdminCmd("sm_endmatchvote_list", Cmd_List, ADMFLAG_CONFIG, "List the excluded maps");
    LoadPersistantExcludedMaps();
}
 
public OnMapStart()
{
    PrintToServer("[EndMatchMapGroupVote] Map start detected");
    if(isFirstMap == 1) // Ignore very first map load at isFirstMap == 0
    {
        PrintToServer("[EndMatchMapGroupVote] It's first map start sequence, force last played map.");
        ForceChangeLevel(g_lastMap, "[EndMatchMapGroupVote] Restart at last played map");
    } else {
        GetCurrentMap(g_currentMap, sizeof(g_currentMap));
        PrintToServer("[EndMatchMapGroupVote] Current map : %s", g_currentMap);
        SavePersistantExcludedMaps();
    }
    isFirstMap++;
}

public Action Cmd_ExcludedMatches(int client, int args)
{
    if (args < 1)
    {
        PrintToConsole(client, "Usage: sm_endmatchvote_max <nb_of_matchs>");
        return Plugin_Handled;
    }
    
    char number_s[32];
    int number;
    GetCmdArg(1, number_s, sizeof(number_s));
    StringToIntEx(number_s, number);
    g_maxExcludedTimes = number
    PrintToConsoleAndServer(client, "[EndMatchMapGroupVote] sm_endmatchvote_max set to %d", number);
    return Plugin_Handled;
}

public Action Cmd_SetMode(int client, int args)
{
    if (args < 1)
    {
        PrintToConsole(client, "Usage: sm_endmatchvote_mode <1|2>");
        return Plugin_Handled;
    }
    
    char mode_s[32];
    int mode;
    GetCmdArg(1, mode_s, sizeof(mode_s));
    StringToIntEx(mode_s, mode);
    switch(mode) {
        case 1:
        {
            PrintToConsoleAndServer(client, "[EndMatchMapGroupVote] Plugin enable in persistent mode.");
            g_mode = 1;
            return Plugin_Handled;
        }
        case 2:
        {
            PrintToConsoleAndServer(client, "[EndMatchMapGroupVote] Plugin enable in temp mode.");
            g_mode = 2;
            return Plugin_Handled;
        }
        default:
        {
            PrintToConsole(client, "Usage: sm_endmatchvote_mode <1|2>");
            return Plugin_Handled;
        }
    }
}

public Action Cmd_Reset(int client, int args)
{   
    g_excludedMaps.Clear();
    if (FileExists(g_fileName)) DeleteFile(g_fileName);
    PrintToConsoleAndServer(client, "[EndMatchMapGroupVote] Excluded Maps have been reset.");
    return Plugin_Handled;
}

public PrintExcludedMaps()
{
    int nbTimesExcluded;
    char currentExcludedMapName[PLATFORM_MAX_PATH];
    StringMapSnapshot snapshot = g_excludedMaps.Snapshot();
    for(int x = 0; x < snapshot.Length; x++)
    {
        snapshot.GetKey(x, currentExcludedMapName, sizeof(currentExcludedMapName));
        g_excludedMaps.GetValue(currentExcludedMapName, nbTimesExcluded);
        PrintToServer("[EndMatchMapGroupVote] %d - %s (excluded for %d matches)", (x+1), currentExcludedMapName, nbTimesExcluded);
    }
}

public Action Cmd_List(int client, int args)
{   
    PrintExcludedMaps()
    return Plugin_Handled;
}

public OnConfigsExecuted()
{
    RequestFrame(frame);
}

public void frame(any data)
{
    CreateMapList();
}

public void cs_win_panel_match(Event event, const char[] name, bool dontBroadcast)
{
    CreateMapList();    
    char currentMapName[PLATFORM_MAX_PATH];
    char currentMapName2[PLATFORM_MAX_PATH];
    char currentExcludedMapName[PLATFORM_MAX_PATH];
    
    StringMapSnapshot snapshot = g_excludedMaps.Snapshot();

    int nbTimesExcluded;
    for(int x = 0; x < snapshot.Length; x++)
    {
        snapshot.GetKey(x, currentExcludedMapName, sizeof(currentExcludedMapName));
        g_excludedMaps.GetValue(currentExcludedMapName, nbTimesExcluded);
        g_excludedMaps.SetValue(currentExcludedMapName, nbTimesExcluded+1, true);
        PrintToServer("[EndMatchMapGroupVote] Map %i - %s excluded %i times", x, currentExcludedMapName, nbTimesExcluded);

        if((g_maxExcludedTimes > 0) && (nbTimesExcluded >= g_maxExcludedTimes))
        {
            PrintToServer("[EndMatchMapGroupVote] Remove %i - %s from excluded maps (after %i times)", x, currentExcludedMapName, nbTimesExcluded);
            g_excludedMaps.Remove(currentExcludedMapName);
        }
    }

    delete snapshot;

    // Exclude current map from vote
    GetCurrentMap(currentMapName, sizeof(currentMapName));
    g_excludedMaps.SetValue(currentMapName, 1, true);
    PrintToServer("[EndMatchMapGroupVote] Exclude last played map : %s", currentMapName);

    int ent = FindEntityByClassname(-1, "cs_gamerules");
    
    if(ent != -1)
    {
        int voteOptionsMaps_s = GetEntPropArraySize(ent, Prop_Send, "m_nEndMatchMapGroupVoteOptions");
        int[] voteOptionsMaps = new int[voteOptionsMaps_s];

        // save given map indexs
        for(int vo_idx = 0; vo_idx < voteOptionsMaps_s; vo_idx++)
        {
            voteOptionsMaps[vo_idx] = GameRules_GetProp("m_nEndMatchMapGroupVoteOptions", _, vo_idx);
        }

        bool VoteOptionAlready;

        for(int vo_idx = 0; vo_idx < voteOptionsMaps_s; vo_idx++)
        {

            if(voteOptionsMaps[vo_idx] == -1 || voteOptionsMaps[vo_idx] >= g_currentMaps.Length) return;

            g_currentMaps.GetString(voteOptionsMaps[vo_idx], currentMapName, sizeof(currentMapName));
            PrintToServer("[EndMatchMapGroupVote] Map %s is candidate at position %i ... ", currentMapName, vo_idx);

            // map have played newly
            if(g_excludedMaps.GetValue(currentMapName, nbTimesExcluded))
            {
                PrintToServer("[EndMatchMapGroupVote] ... but %s in an excluded map (#%i). We need to find a replacement map ...", currentMapName, voteOptionsMaps[vo_idx]);
                GameRules_SetProp("m_nEndMatchMapGroupVoteOptions", -1, _, vo_idx, true);
                
                for(int m_idx = 0; m_idx < g_currentMaps.Length; m_idx++)
                {
                    g_currentMaps.GetString(m_idx, currentMapName2, sizeof(currentMapName2));
                    if(!g_excludedMaps.GetValue(currentMapName2, nbTimesExcluded))
                    {
                        PrintToServer("[EndMatchMapGroupVote] ... %s is a replacement candidate ...", currentMapName2);
                        for(int vo_idx2 = 0; vo_idx2 < voteOptionsMaps_s; vo_idx2++)
                        {
                            if(voteOptionsMaps[vo_idx2] == m_idx)
                            {
                                PrintToServer("[EndMatchMapGroupVote] ... but it's already in vote options !");
                                VoteOptionAlready = true;
                                break;
                            }
                        }

                        if(VoteOptionAlready)
                        {
                            VoteOptionAlready = false;
                            m_idx++;
                            continue;
                        }

                        PrintToServer("[EndMatchMapGroupVote] ... put %i - %s in option %i", m_idx, currentMapName2, vo_idx)
                        voteOptionsMaps[vo_idx] = m_idx;
                        GameRules_SetProp("m_nEndMatchMapGroupVoteOptions", m_idx, _, vo_idx, true);
                        break;
                    }                    
                }
            }
        }

    }
}

void LoadPersistantExcludedMaps()
{   
    PrintToServer("[EndMatchMapGroupVote] LoadPersistantExcludedMaps");
    if (!FileExists(g_fileName)) return;
    
    KeyValues kv = new KeyValues(g_fileName);
    
    if(kv.ImportFromFile(g_fileName))
    {
        if(kv.JumpToKey("excludedmaps"))
        {
            if(kv.GotoFirstSubKey())
            {
                do
                {
                    char mapName[PLATFORM_MAX_PATH];
                    int nbExcludedTimes;
                    char nbExcludedTimes_s[PLATFORM_MAX_PATH];
                    kv.GetString("mapname", mapName, sizeof(mapName));
                    kv.GetString("nbExcludedTimes", nbExcludedTimes_s, sizeof(nbExcludedTimes_s));
                    StringToIntEx(nbExcludedTimes_s, nbExcludedTimes);
                    PrintToServer("[EndMatchMapGroupVote] mapName: %s, nbExcludedTimes %d",mapName, nbExcludedTimes);
                    g_excludedMaps.SetValue(mapName, nbExcludedTimes, true);
                    
                } while(kv.GotoNextKey())
            }
        }
        kv.Rewind();
        if(kv.JumpToKey("currentMap"))
        {
            kv.GetString("mapname", g_lastMap, sizeof(g_lastMap));
        }
    }
    delete kv;
    PrintExcludedMaps();
}

void SavePersistantExcludedMaps()
{   
    PrintToServer("[EndMatchMapGroupVote] SavePersistantExcludedMaps");
    KeyValues kv = new KeyValues(g_fileName);
    StringMapSnapshot snapshot = g_excludedMaps.Snapshot();

    if (FileExists(g_fileName)) DeleteFile(g_fileName);
    
    if(g_mode == 1)
    {
        for (int i = 0; i < snapshot.Length; i++)
        {
            kv.JumpToKey("excludedmaps", true);
            char idx[3];
            IntToString(i,idx,sizeof(idx));
            kv.JumpToKey(idx, true);
            char key[PLATFORM_MAX_PATH];
            int value;
            snapshot.GetKey(i, key, sizeof(key));
            g_excludedMaps.GetValue(key, value);
            kv.SetString("mapName", key);
            kv.SetNum("nbExcludedTimes", value);
            kv.Rewind();
        }
        kv.JumpToKey("currentMap", true);
        kv.SetString("mapName", g_currentMap);
        kv.Rewind();
        kv.ExportToFile(g_fileName);
    }
    
    delete kv;
}

void CreateMapList() {
    CreateMapListFromGameModesServer();
    if(g_currentMaps.Length == 0) {
        CreateMapListFromPrintMapGroupSv();
    }
}

void CreateMapListFromGameModesServer()
{
    if(g_currentMaps != null) delete g_currentMaps;
    g_currentMaps = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    
    KeyValues kv = new KeyValues("GameModes_Server.txt");

    if(kv.ImportFromFile("gamemodes_server.txt"))
    {    
        if(kv.JumpToKey("mapgroups"))
        {
            if(kv.GotoFirstSubKey(false))
            {
                if(kv.JumpToKey("maps"))
                {
                    if(kv.GotoFirstSubKey(false))
                    {
                        do 
                        {
                            char mapName[PLATFORM_MAX_PATH];
                            kv.GetSectionName(mapName, sizeof(mapName));
                            g_currentMaps.PushString(mapName);
                        } while (kv.GotoNextKey(false));
                    }
                }
            }
        }
    }
    
    delete kv;
}  

void CreateMapListFromPrintMapGroupSv()
{
    if(g_currentMaps != null) delete g_currentMaps;
    g_currentMaps = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));

    // I really hate to do this way, grab map list:(
    char consoleoutput[5000];
    ServerCommandEx(consoleoutput, sizeof(consoleoutput), "print_mapgroup_sv");

    int skip;
    int sub;

    char buffer[PLATFORM_MAX_PATH];
    Regex regex = new Regex("^[[:blank:]]+(\\w.*)$", PCRE_MULTILINE);
    
    while( (sub = regex.Match(consoleoutput[skip])) > 0 )
    {
        if(!regex.GetSubString(0, buffer, sizeof(buffer)))
        {
            break;
        }

        skip += StrContains(consoleoutput[skip], buffer);
        skip += strlen(buffer);

        for(int x = 1; x < sub; x++)
        {
            if(!regex.GetSubString(x, buffer, sizeof(buffer)))
            {
                break;
            }
            g_currentMaps.PushString(buffer); // Add also false maps to match vote indexs
        }
    }
    delete regex;
    
}  