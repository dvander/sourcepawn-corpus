

#include <mapchooser>

public void OnPluginStart()
{
	HookEventEx("round_announce_match_point", round_announce_match_point);
}

public void round_announce_match_point(Event event, const char[] name, bool dontBroadcast)
{
	//mp_match_end_restart 0
	//mp_match_end_changelevel 1

	CreateTimer(2.0, delay, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action delay(Handle timer)
{
	ConVar mp_match_end_restart = FindConVar("mp_match_end_restart");
	ConVar mp_match_end_changelevel = FindConVar("mp_match_end_changelevel");

	if(mp_match_end_restart.BoolValue || !mp_match_end_changelevel.BoolValue)
	{
		if(mp_match_end_restart.BoolValue)
		{
			PrintToChatAll(" \x01\x04[SM]\x01 Map vote will not start when mp_match_end_restart 1");
			LogAction(-1, -1, "[SM] Map vote will not start when mp_match_end_restart 1");
		}
		if(!mp_match_end_changelevel.BoolValue)
		{
			PrintToChatAll(" \x01\x04[SM]\x01 Map vote will not start when mp_match_end_changelevel 0");
			LogAction(-1, -1, "[SM] Map vote will not start when mp_match_end_changelevel 0");
		}

		return;
	}

	if(!CanMapChooserStartVote() || !EndOfMapVoteEnabled() || HasEndOfMapVoteFinished())
		return;

	InitiateMapChooserVote(MapChange_MapEnd);
}
