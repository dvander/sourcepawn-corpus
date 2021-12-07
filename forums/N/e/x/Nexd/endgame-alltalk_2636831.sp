#include <sourcemod>

Handle gh_AllTalk = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "endgame-alltalk",
	author = "Nexd",
	description = "https://forums.alliedmods.net/showthread.php?t=313852",
	version = ""
};

public void OnPluginStart()
{
	HookEvent("cs_win_panel_match", Event_EndMatch);
	HookEvent("start_halftime", Event_HalfTime);
	HookEvent("round_start", Event_RoundStart);

	gh_AllTalk = FindConVar("sv_full_alltalk");
	SetConVarBool(gh_AllTalk, false);
}

public Action Event_HalfTime(Event event, const char[] name, bool dontBroadcast)
{
	SetConVarBool(gh_AllTalk, true);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	SetConVarBool(gh_AllTalk, false);
}

public Action Event_EndMatch(Event event, const char[] name, bool dontBroadcast)
{
	SetConVarBool(gh_AllTalk, true);
}