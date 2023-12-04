#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>
#include <sdktools_gamerules>

#define PL_NAME			"[INS] End of outpost"
#define PL_VERSION		"1.1.0 (rewritten by Grey83)"
#define PL_DESCRIPTION	"Get rid of the infinity in gamemode outpost"
#define PL_AUTHOR		"Polaris (FoNg)"
#define PL_URL			"https://github.com/lamya3"

enum
{
	T_SEC = 2,
	T_INS
};

int
	iEnd;
bool
	bEndflag,
	bScoreChanged,
	bOutpost;

public Plugin myinfo =
{
	name		= PL_NAME,
	author		= PL_AUTHOR,//thanks bob(https://steamcommunity.com/id/TE4R/), he provided some solutions to technical problems.
	description	= PL_DESCRIPTION,
	version		= PL_VERSION,
	url			= PL_URL
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Insurgency)
		return APLRes_Success;

	FormatEx(error, err_max, "Plugin only for Insurgency (2014)");
	return APLRes_Failure;
}

public void OnPluginStart()
{
	CreateConVar("sm_endlevel_version", PL_VERSION, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar = FindConVar("mp_gamemode");
	if(cvar)
	{
		cvar.AddChangeHook(CVarChange_Mode);
		CVarChange_Mode(cvar, NULL_STRING, NULL_STRING);
	}

	cvar = CreateConVar("sm_outpost_endlevel", "25", "Which level we can tirgger round win?? (You can't lower than level3.)", FCVAR_NOTIFY, true, 3.0, true, 2147483647.0);
	cvar.AddChangeHook(CVarChange_End);
	iEnd = cvar.IntValue;

	HookEvent("round_level_advanced", Event_RoundLevelAdvanced, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEndCall, EventHookMode_Pre);
	HookEvent("player_stats_updated", Event_PostMsgChange, EventHookMode_PostNoCopy);
	HookEvent("game_start", Event_NewRounds, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_NewRounds, EventHookMode_PostNoCopy);
}

public void CVarChange_Mode(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	char buffer[32];
	cvar.GetString(buffer, sizeof(buffer));
	bOutpost = StrContains(buffer, "outpost", false) != -1;
}

public void CVarChange_End(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iEnd = cvar.IntValue - 1;
}

public void OnMapStart()
{
	bEndflag = bScoreChanged = false;
}

public void Event_NewRounds(Event event, const char[] name, bool dontBroadcast)
{
	bEndflag = bScoreChanged = false;
}

public void Event_RoundLevelAdvanced(Event event, const char[] name, bool dontBroadcast)
{
	if(bOutpost) CreateTimer(3.0, LevelReachCall, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action LevelReachCall(Handle timer)
{
	if(GameRules_GetProp("m_iLevel") > iEnd)
	{
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == T_SEC)
			SetEntProp(i, Prop_Send, "m_lifeState", 2);
		RequestFrame(SetSecuityWinScore);
	}

	return Plugin_Stop;
}

public void SetSecuityWinScore(any data)
{
	int iTeam, iTeamNum, val, iEntoffs, i_RoundsWon;
	while((iTeam = FindEntityByClassname(iTeam, "play_team_manager")) != -1)
	{
		if((val = (iTeamNum = GetEntProp(iTeam, Prop_Send, "m_iTeamNum")) == T_SEC ? 1 : iTeamNum == T_INS ? -1 : 0))
		{
			if((iEntoffs = FindSendPropInfo("CPlayTeam", "m_iRoundsWon")) == -1)
				LogError("RoundsWon invalid (%d)", i_RoundsWon);
			else if((i_RoundsWon = GetEntData(iTeam, iEntoffs)) == -1)
				LogError("Entoffs error (%d)", iEntoffs);
			else SetEntData(iTeam, iEntoffs, i_RoundsWon + val, 4, true);
		}
		else LogError("Team index invalid (%d)", iTeamNum);
	}
	bScoreChanged = true;
}

public void Event_RoundEndCall(Event event, const char[] name, bool dontBroadcast)
{
	if(bOutpost) bEndflag = true;
}

public void Event_PostMsgChange(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEndflag || !bScoreChanged || !bOutpost)
		return;

	Event win = CreateEvent("round_end", true);
	if(win)
	{
		win.SetInt("winner", T_SEC);
		win.SetInt("reason", 0);
		win.SetString("message", "#game_team_winner_elimination_coop");
		win.Fire();
	}

	bEndflag = bScoreChanged = false;
}