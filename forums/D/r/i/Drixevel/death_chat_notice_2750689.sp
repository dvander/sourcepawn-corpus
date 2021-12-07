#include <sourcemod>

public void OnPluginStart()
{
	LoadTranslations("death_chat_notice.phrases");

	HookEvent("player_death", Event_PlayerDeath);
}

public void Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iVictim != 0 && GetClientTeam(iVictim) == 2)
	{
		PrintToChatAll("%t", "player died", iVictim);
	}
}