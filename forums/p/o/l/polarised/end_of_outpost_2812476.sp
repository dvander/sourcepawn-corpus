#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_DESCRIPTION	"Get rid of the infinity in gamemode outpost"
#define PLUGIN_NAME 		"End of outpost"
#define PLUGIN_VERSION		"1.0.9"
#define PLUGIN_AUTHOR		"Polaris (FoNg)"
#define PLUGIN_URL			"https://github.com/lamya3"

#define TEAMLIST_CLASS      "play_team_manager"
#define TEAM_SEC            2
#define TEAM_INS            3

Handle  cvar_Gamemode        = null;
Handle  cvar_Levelset        = null;
char    Gamemode[32];
bool    Endflag              = false;
bool    ScoreChanged         = false;

public Plugin myinfo =
{
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,//thanks bob(https://steamcommunity.com/id/TE4R/), he provided some solutions to technical problems.
	description 	= PLUGIN_DESCRIPTION,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Insurgency) return APLRes_Success;

	FormatEx(error, err_max, "Plugin only for Insurgency (2014)");
	return APLRes_Failure;
}

public void OnPluginStart() 
{
    CreateConVar("sm_endlevel_version", PLUGIN_VERSION, "Level chooser plugin version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    cvar_Levelset = CreateConVar("sm_outpost_endlevel", "25", "Which level we can tirgger round win?? (You can't lower than level3.)", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 3.0, true, 2147483647.0);
    HookEvent("round_level_advanced",Event_RoundLevelAdvanced);
    HookEvent("round_end", Event_RoundEndCall, EventHookMode_Pre);
    HookEvent("player_stats_updated",PostMsgChange,EventHookMode_Post);
    HookEvent("game_start", Event_NewRounds);
    HookEvent("round_start", Event_NewRounds);
}

public void OnMapStart()
{
    cvar_Gamemode = FindConVar("mp_gamemode");
    GetConVarString(cvar_Gamemode, Gamemode ,sizeof(Gamemode));
    Endflag = false;ScoreChanged = false;
}

public void Event_NewRounds(Event event, const char[] name, bool dontBroadcast)
{
    Endflag = false; ScoreChanged = false;
}

public Action Event_RoundLevelAdvanced(Event event, const char[] name, bool dontBroadcast)
{
    if(IsGamemodeOk())
    {
        EndCallDelay();
    }
    return Plugin_Continue;
}

public Action LevelReachCall(Handle timer)
{
    if(GameRules_GetProp("m_iLevel", 4) >= GetConVarInt(cvar_Levelset))
    {
        KillPlayersEnd();
        RequestFrame(SetSecuityWinScore);
        return Plugin_Continue;
    }
    else return Plugin_Continue;
}

public Action Event_RoundEndCall (Event event, const char[] name, bool dontBroadcast)
{
    if(IsGamemodeOk())
    {
        Endflag = true;
    }
    return Plugin_Continue;
}

public Action PostMsgChange (Event event, const char[] name, bool dontBroadcast)
{
    if(Endflag && ScoreChanged && IsGamemodeOk())
    {
        SetSecuityWinEvent(TEAM_SEC);
        Endflag = false;ScoreChanged = false;
    }
    return Plugin_Continue;
}

public void EndCallDelay()
{
    CreateTimer(3.0, LevelReachCall, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void KillPlayersEnd()
{
    for (int i = 1; i <= MaxClients; i++) 
    {
		if (IsPlayTeam(i, TEAM_SEC)) 
        {
            SetEntProp(i, Prop_Send, "m_lifeState", 2);
        }
	}
}

public void SetSecuityWinScore()
{
    int iTeam = 0;
    while ((iTeam = FindEntityByClassname(iTeam, TEAMLIST_CLASS)) != -1)
    {
        int iTeamNum = GetEntProp(iTeam, Prop_Send, "m_iTeamNum");
        if(iTeamNum == TEAM_SEC)
        {
            ScoreCalc(iTeam, 1);
        }
        else if(iTeamNum == TEAM_INS)
        {
            ScoreCalc(iTeam, -1);
        }
        else
        {
            LogError("Team index invalid(%d)",iTeamNum);
        }
    }
    ScoreChanged = true;
}

public void SetSecuityWinEvent(int WinTeam)
{
    Event e_secwin = CreateEvent("round_end", true);
    if(e_secwin == null) return;
    e_secwin.SetInt("winner", WinTeam);
    e_secwin.SetInt("reason", 0); 
    e_secwin.SetString("message", "#game_team_winner_elimination_coop"); 
    e_secwin.Fire();
}

void ScoreCalc(int iTeam,int ScoreNum)
{
    int i_RoundsWon = -1; int iEntoffs = 948; int iTotalscoreTeam = -1;
    iEntoffs = FindSendPropInfo("CPlayTeam", "m_iRoundsWon");
    i_RoundsWon = GetEntData(iTeam, iEntoffs, 4);
    if(iEntoffs != -1 && i_RoundsWon != -1)
    {
        iTotalscoreTeam = i_RoundsWon + ScoreNum;
        SetEntData(iTeam, iEntoffs, iTotalscoreTeam, 4, true);
    }
    else
    {
        LogError("Entoffs error(%d) or RoundsWon invalid(%d)",iEntoffs,i_RoundsWon);
    }
}

bool IsPlayTeam(int client,int PlayTeamIndex)
{
    if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == PlayTeamIndex)
    { 				
		return true;
    }
    else return false;
}

bool IsGamemodeOk()
{
    if(StrContains(Gamemode, "outpost", false) != -1)
    {
        return true;
    }
    else return false;
}

