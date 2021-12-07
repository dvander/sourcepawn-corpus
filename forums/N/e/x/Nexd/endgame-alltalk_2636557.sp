#include <sourcemod>

Handle gh_AllTalk = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "endgame-alltalk",
	author = "Nexd",
	description = "",
	version = "https://forums.alliedmods.net/showthread.php?t=313852"
};

public void OnPluginStart()
{
	HookEvent("cs_win_panel_match", Event_EndMatch);
	gh_AllTalk = FindConVar("sv_full_alltalk");
	SetConVarBool(gh_AllTalk, false);
}

public Action Event_EndMatch(Event event, const char[] name, bool dontBroadcast)
{
	SetConVarBool(gh_AllTalk, true);
}