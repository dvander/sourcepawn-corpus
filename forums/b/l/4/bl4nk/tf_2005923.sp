#undef REQUIRE_EXTENSIONS
#undef AUTOLOAD_EXTENSIONS
#include <tf2_stocks>
#include <sdkhooks>

#define SCOREMOD_NOACTION 0
#define SCORE_NOACTION -1
#define SCORE_REAL -2
#define SCORE_THISROUND -3

// CVars' handles
new Handle:cvar_bonusroundtime = INVALID_HANDLE;

// CVars' variables
new Float:g_fBonusRoundTime = 15.0;

// Score management
new TFScore[MAXPLAYERS+1] = {SCORE_NOACTION, ...};
new TFScoreMod[MAXPLAYERS+1] = {SCOREMOD_NOACTION, ...};

// Loading TF stuff on plugin start
public TF_Stuff()
{
    //Cheking for extensions
    CheckTFExtensions();
    
    // Finding CVars for stats fix
    cvar_bonusroundtime = FindConVar("mp_bonusroundtime");
    
    // Hooking them
    HookConVarChange(cvar_bonusroundtime, OnCVarChange);
    //HookConVarChange(cvar_chattime, OnCVarChange);
    
    // Hooking events for detecting of new game start
    HookEvent("teamplay_round_start", Event_NewGameStart, EventHookMode_Pre);
    HookEvent("teamplay_restart_round", Event_TFRoundRestartCommand);
    
    // Events that req for correct game stats working:
    
    // Game Panel event
    HookEvent("teamplay_broadcast_audio", Event_TFScoresPanel_Start, EventHookMode_Pre);
    HookEvent("teamplay_round_win", Event_TFScoresPanel_End, EventHookMode_PostNoCopy);
    // High Score event for detecting of new round
    HookEvent("teamplay_round_win", Event_TFHighScoreRound_Start, EventHookMode_Pre);
    HookEvent("teamplay_round_start", Event_TFHighScoreRound_End, EventHookMode_PostNoCopy);
    // High Score event after death
    HookEvent("player_death", Event_TFHighScoreDeath_Start, EventHookMode_Pre);
    // Stats upload at map end
    HookEvent("teamplay_game_over", Event_TFGameOver_End, EventHookMode_PostNoCopy);
}

// This TF function calls everytime when player's score is modified and we can change score to what ever we want.
/*public OnCalcPlayerScore(client, score)
{
    if (TFScore[client] > SCORE_NOACTION)
    {
        TFScoreMod[client] = TFScore[client] - score;
        TFScore[client] = SCORE_NOACTION;
    }
    else if (TFScore[client] == SCORE_NOACTION)
    {
        return (score + TFScoreMod[client]);
    }
    else if (TFScore[client] == SCORE_REAL)
    {
        return score;
    }
    
    return (score + TFScoreMod[client]);
}*/

public Hook_OnThinkPost(iEnt) {
    static iTotalScoreOffset = -1;
    if (iTotalScoreOffset == -1) {
        iTotalScoreOffset = FindSendPropInfo("CTFPlayerResource", "m_iTotalScore");
    }
    
    new iTotalScore[MAXPLAYERS+1];
    GetEntDataArray(iEnt, iTotalScoreOffset, iTotalScore, MaxClients+1);
    
    for (new i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && IsClientInGame(i)) {
            /*if (g_iSetScore[i] > -1) {
                iTotalScore[i] = g_iSetScore[i];
            } else if (g_iScoreMod[i] != 0) {
                iTotalScore[i] += g_iScoreMod[i];
            }*/
            if (TFScore[i] > SCORE_NOACTION) {
                TFScoreMod[i] = TFScore[i] - iTotalScore[i];
                TFScore[i] = SCORE_NOACTION;
            } else if (TFScore[i] == SCORE_NOACTION) {
                iTotalScore[i] += TFScoreMod[i];
            } else if (TFScore[i] == SCORE_REAL) {
                continue;
            }

            iTotalScore[i] += TFScoreMod[i];
        }
    }
    
    SetEntDataArray(iEnt, iTotalScoreOffset, iTotalScore, MaxClients+1);
}


// Cheking for TF extensions. This code will run several times so I put it into separate function.
public CheckTFExtensions()
{
    if (GetExtensionFileStatus("game.tf2.ext") != 1)
    {
        LogAction(-1, -1, "TF2 Tools extension is not running");
        SetFailState("TF2 Tools extension is not running");
    }
    /*else if (GetExtensionFileStatus("calcplayerscore.ext") != 1)
    {
        LogAction(-1, -1, "CalcPlayerScore extension is not running");
        SetFailState("CalcPlayerScore extension is not running");
    }*/

    new iIndex = FindEntityByClassname(MaxClients+1, "tf_player_manager");
    if (iIndex == -1) {
        SetFailState("Unable to find tf_player_manager entity");
    }
    
    SDKHook(iIndex, SDKHook_ThinkPost, Hook_OnThinkPost);
}

// Plugin has a conflict with scoremod.smx so we must unload it
public UnloadScoreMod()
{
    if (Game == GAME_TF && FindPluginByFile("scoremod.smx") != INVALID_HANDLE)
    {
        ServerCommand("sm plugins unload scoremod");
    }
}

// TF round restart command event
public Action:Event_TFRoundRestartCommand(Handle:event, const String:name[], bool:dontBroadcast)
{   
    if (!save_scores)
    {
        return Plugin_Continue;
    }
    
    // Mark next round as a new game
    g_NextRoundNewGame = true;
    
    return Plugin_Continue;
}


// -------------------- Functions and events that fix stats working in TF --------------------

// Set client score to not modified value
public TFStatsFix_ClientNonModScore(client)
{
    TFScore[client] = SCORE_REAL;
}

// Return client score to modified value
public TFStatsFix_ClientModScore(client)
{
    TFScore[client] = SCORE_NOACTION;
}

// Set all clients' scores to not modified value
public TFStatsFix_NonModScores()
{
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client) && TFScoreMod[client] != SCOREMOD_NOACTION)
        {
            TFStatsFix_ClientNonModScore(client);
        }
    }
}

// Set all clients' scores to modified value
public TFStatsFix_ModScores()
{
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client) && TFScore[client] == SCORE_REAL)
        {
            TFStatsFix_ClientModScore(client);
        }
    }
}

// --- Situation #1 ---

// Before Scores Panel start show set not modified score
public Action:Event_TFScoresPanel_Start(Handle:event, const String:name[], bool:dontBroadcast)
{   
    if (!save_scores)
    {
        return Plugin_Continue;
    }
    
    decl String:sound[64];
    GetEventString(event, "sound", sound, sizeof(sound))
    
    if (StrEqual(sound, "Game.Stalemate") || StrEqual(sound, "Game.YourTeamWon"))
    {
        TFStatsFix_NonModScores();
    }
    
    return Plugin_Continue;
}

// After Scores Panel showed return modified score
public Action:Event_TFScoresPanel_End(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!save_scores)
    {
        return Plugin_Continue;
    }
    
    TFStatsFix_ModScores(); 
    return Plugin_Continue;
}

// --- Situation #2 ---

// Client's high score table started show  - set not mod score
public Action:Event_TFHighScoreDeath_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!save_scores)
    {
        return Plugin_Continue;
    }
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (TFScore[client] == SCORE_REAL)
    {
        TFStatsFix_ClientNonModScore(client);
        CreateTimer(0.01, Action_TFHighScoreDeath_End, client);
    }
    
    return Plugin_Continue;
}

// Client's high score table ended show - set modified score
public Action:Action_TFHighScoreDeath_End(Handle:timer, any:client)
{
    if (TFScore[client] == SCORE_REAL)
    {
        TFStatsFix_ClientModScore(client);
    }
}

// --- Situation #3 ---

public Action:Event_TFHighScoreRound_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!save_scores)
    {
        return Plugin_Continue;
    }
    
    CreateTimer(g_fBonusRoundTime - 0.1, Action_TFHighScoreRound_Start);    
    return Plugin_Continue;
}

public Action:Action_TFHighScoreRound_Start(Handle:timer, any:client)
{
    TFStatsFix_NonModScores();
}

public Action:Event_TFHighScoreRound_End(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!save_scores)
    {
        return Plugin_Continue;
    }
    
    TFStatsFix_ModScores(); 
    return Plugin_Continue;
}

// --- Situation #4 ---

public Action:Event_TFGameOver_End(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!save_scores)
    {
        return Plugin_Continue;
    }
    
    TFStatsFix_ModScores(); 
    return Plugin_Continue;
}