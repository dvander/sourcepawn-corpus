#include <sourcemod>
#include <tf2_stocks>

bool g_bWaitingForPlayers = false;

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public void TF2_OnWaitingForPlayersStart()
{
	g_bWaitingForPlayers = true;
}

public void TF2_OnWaitingForPlayersEnd()
{
	g_bWaitingForPlayers = false;
}

public void Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (GameRules_GetRoundState() == RoundState_RoundRunning && !g_bWaitingForPlayers && !(hEvent.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)) // Make sure death event was not triggered by dead ringer
	{
		int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
		if (iVictim == GetClientOfUserId(hEvent.GetInt("attacker")) && iVictim != 0 && TF2_GetClientTeam(iVictim) == TFTeam_Red)
		{
			TF2_ChangeClientTeam(iVictim, TFTeam_Blue);
		}
	}
}