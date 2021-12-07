#include <sourcemod>

Handle gh_ForceEnd = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Force-cvar",
	author = "Nexd",
	description = "https://forums.alliedmods.net/showthread.php?t=313935",
	version = ""
};

public void OnPluginStart()
{
	HookEvent("cs_win_panel_match", Event_EndMatch);

	gh_ForceEnd = FindConVar("mp_match_end_changelevel");
	SetConVarBool(gh_ForceEnd, true);
}

public Action Event_EndMatch(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(gh_ForceEnd) == false) {
		SetConVarBool(gh_ForceEnd, true);
	}
}