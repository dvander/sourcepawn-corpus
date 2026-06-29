#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

// --- VARIABLES ---
ConVar g_cvStoryMode;
Handle g_hWarningTimer = null;

// --- SDK CALL HANDLES ---
static Handle hDirectorChangeLevel;
static Handle hDirectorClearTeamScores;
static Address TheDirector = Address_Null;

public Plugin myinfo =
{
    name = "L4D2 Story Switch (English - 5 Min Warning)",
    author = "Gemini AI & Lux",
    description = "Story Mode Switcher with English Notifications & 5m Warnings",
    version = "3.6",
    url = ""
};

public void OnPluginStart()
{
    g_cvStoryMode = CreateConVar("l4d_story_mode_active", "0", "0: Off, 1: L4D1, 2: L4D2", FCVAR_NOTIFY);

    RegAdminCmd("sm_l4d1_story_start", Command_StartL4D1, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_l4d2_story_start", Command_StartL4D2, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_l4d1_story_stop", Command_StopStory, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_l4d2_story_stop", Command_StopStory, ADMFLAG_CHANGEMAP);
    
    HookEvent("finale_win", Event_FinaleWin);

    // Load Gamedata
    Handle hGamedata = LoadGameConfigFile("l4d2_changelevel"); 
    if(hGamedata == null) SetFailState("ERROR: Missing 'gamedata/l4d2_changelevel.txt'");
    
    StartPrepSDKCall(SDKCall_Raw);
    if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CDirector::OnChangeChapterVote"))
        SetFailState("Error: Signature 'OnChangeChapterVote' invalid.");
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    hDirectorChangeLevel = EndPrepSDKCall();
    
    TheDirector = GameConfGetAddress(hGamedata, "CDirector");
    
    StartPrepSDKCall(SDKCall_Raw);
    if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CDirector::ClearTeamScores"))
        SetFailState("Error: Signature 'ClearTeamScores' invalid.");
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
    hDirectorClearTeamScores = EndPrepSDKCall();
    
    delete hGamedata;
}

public void OnConfigsExecuted()
{
    if (g_cvStoryMode.IntValue != 0)
    {
        ServerCommand("sv_lan 0");
        ServerCommand("sv_allow_lobby_connect_only 0");
        ServerCommand("heartbeat");
        //ServerCommand("sm_cvar mp_gamemode coop"); 
    }
}

// --- WARNING SYSTEM (ADJUSTED TIMING) ---

public void OnMapStart()
{
    if (g_hWarningTimer != null) { KillTimer(g_hWarningTimer); g_hWarningTimer = null; }

    if (g_cvStoryMode.IntValue != 0)
    {
        char currentMap[64];
        GetCurrentMap(currentMap, sizeof(currentMap));

        // Check conditions
        if (StrContains(currentMap, "c11", false) != -1 || StrContains(currentMap, "c12", false) != -1)
        {
            // THAY ĐỔI Ở ĐÂY:
            // Tạo Timer lần đầu tiên sau 60 giây (1 phút) để đảm bảo người chơi nhìn thấy
            CreateTimer(60.0, Timer_FirstWarning, _, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action Timer_FirstWarning(Handle timer)
{
    // Gọi hàm cảnh báo lần 1
    Timer_CheckAndWarn(null);
    
    // Sau đó thiết lập timer lặp lại mỗi 300 giây (5 phút)
    if (g_hWarningTimer == null)
    {
        g_hWarningTimer = CreateTimer(300.0, Timer_CheckAndWarn, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
    return Plugin_Stop;
}

public void OnMapEnd()
{
    if (g_hWarningTimer != null) { KillTimer(g_hWarningTimer); g_hWarningTimer = null; }
}

public Action Timer_CheckAndWarn(Handle timer)
{
    if (g_cvStoryMode.IntValue == 0) return Plugin_Stop;

    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));

    // 1. DAM IT WARNING
    if (StrContains(currentMap, "c11", false) != -1)
    {
        PrintToChatAll("\x04[Story Mode] \x01WARNING: The next campaign is \x03Dam It\x01.");
        PrintToChatAll("\x01Required Addon (Download both parts or you might crash):");
        PrintToChatAll("\x05https://steamcommunity.com/sharedfiles/filedetails/?id=3185415283");
    }
    
    // 2. REDEMPTION 2 WARNING
    else if (StrContains(currentMap, "c12", false) != -1)
    {
        PrintToChatAll("\x04[Story Mode] \x01WARNING: The next campaign is \x03Redemption II\x01.");
        PrintToChatAll("\x01Required Addon (Download now to avoid being kicked):");
        PrintToChatAll("\x05https://steamcommunity.com/sharedfiles/filedetails/?id=2258821434");
    }

    return Plugin_Continue;
}

// --- CHANGELEVEL LOGIC ---

void L4D2_NativeChangeLevel(const char[] sMapName, bool bShouldResetScores=true)
{
    PrintToChatAll("\x04[Story Mode]\x01 Switching map to: \x03%s", sMapName);
    if(bShouldResetScores) SDKCall(hDirectorClearTeamScores, TheDirector, 1);
    SDKCall(hDirectorChangeLevel, TheDirector, sMapName);
}

// --- COMMANDS ---

public Action Command_StartL4D1(int client, int args)
{
    g_cvStoryMode.SetInt(1);
    PrintToChatAll("\x04[Story Mode]\x01 Starting \x03Left 4 Dead 1 Storyline\x01.");
    PrintToChatAll("\x04[Story Mode]\x01 First Chapter: \x05No Mercy\x01.");
    DataPack pack = new DataPack(); pack.WriteString("c8m1_apartment");
    CreateTimer(3.0, Timer_ExecChangeLevel, pack);
    return Plugin_Handled;
}

public Action Command_StartL4D2(int client, int args)
{
    g_cvStoryMode.SetInt(2);
    PrintToChatAll("\x04[Story Mode]\x01 Starting \x03Left 4 Dead 2 Storyline\x01.");
    PrintToChatAll("\x04[Story Mode]\x01 First Chapter: \x05Dead Center\x01.");
    DataPack pack = new DataPack(); pack.WriteString("c1m1_hotel");
    CreateTimer(3.0, Timer_ExecChangeLevel, pack);
    return Plugin_Handled;
}

public Action Command_StopStory(int client, int args)
{
    g_cvStoryMode.SetInt(0);
    PrintToChatAll("\x04[Story Mode]\x01 Story Mode has been \x03STOPPED\x01.");
    if (g_hWarningTimer != null) { KillTimer(g_hWarningTimer); g_hWarningTimer = null; }
    return Plugin_Handled;
}

// --- EVENTS ---

public Action Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
    int mode = g_cvStoryMode.IntValue;
    if (mode == 0) return Plugin_Continue;

    char currentMap[64]; GetCurrentMap(currentMap, sizeof(currentMap));
    char nextMap[64]; bool bFound = false;

    if (mode == 1) bFound = GetNextL4D1Map(currentMap, nextMap, sizeof(nextMap));
    else if (mode == 2) bFound = GetNextL4D2Map(currentMap, nextMap, sizeof(nextMap));

    if (bFound)
    {
        PrintToChatAll("\x04[Story Mode]\x01 Campaign Finished! Moving to the next chapter in 15 seconds...");
        DataPack pack = new DataPack(); pack.WriteString(nextMap);
        CreateTimer(15.0, Timer_ExecChangeLevel, pack);
    }
    else
    {
        PrintToChatAll("\x04[Story Mode]\x01 Congratulations! You have completed the entire Story.");
        g_cvStoryMode.SetInt(0);
    }
    return Plugin_Continue;
}

public Action Timer_ExecChangeLevel(Handle timer, DataPack pack)
{
    char mapName[64]; pack.Reset(); pack.ReadString(mapName, sizeof(mapName)); delete pack;
    L4D2_NativeChangeLevel(mapName, true);
    return Plugin_Stop;
}

// --- MAP LIST ---

bool GetNextL4D1Map(const char[] currentMap, char[] nextMap, int maxlen)
{
    if (StrEqual(currentMap, "c8m5_rooftop")) { strcopy(nextMap, maxlen, "c9m1_alleys"); return true; }
    if (StrEqual(currentMap, "c9m2_lots")) { strcopy(nextMap, maxlen, "c10m1_caves"); return true; }
    if (StrEqual(currentMap, "c10m5_houseboat")) { strcopy(nextMap, maxlen, "c11m1_greenhouse"); return true; }
    if (StrEqual(currentMap, "c11m5_runway")) { strcopy(nextMap, maxlen, "c14m1_orchard"); return true; } 
    if (StrEqual(currentMap, "c14m3_dam")) { strcopy(nextMap, maxlen, "c12m1_hilltop"); return true; }
    if (StrEqual(currentMap, "c12m5_cornfield")) { strcopy(nextMap, maxlen, "redemptionii-deadstop"); return true; } 
    if (StrEqual(currentMap, "roundhouse")) { strcopy(nextMap, maxlen, "c7m1_docks"); return true; }
    return false;
}

bool GetNextL4D2Map(const char[] currentMap, char[] nextMap, int maxlen)
{
    if (StrEqual(currentMap, "c1m4_atrium")) { strcopy(nextMap, maxlen, "c6m1_riverbank"); return true; }
    if (StrEqual(currentMap, "c6m3_port")) { strcopy(nextMap, maxlen, "c2m1_highway"); return true; }
    if (StrEqual(currentMap, "c2m5_concert")) { strcopy(nextMap, maxlen, "c3m1_plankcountry"); return true; }
    if (StrEqual(currentMap, "c3m4_plantation")) { strcopy(nextMap, maxlen, "c4m1_milltown_a"); return true; }
    if (StrEqual(currentMap, "c4m5_milltown_escape")) { strcopy(nextMap, maxlen, "c5m1_waterfront"); return true; }
    return false;
}