#include <cstrike>

public void OnPluginStart()
{
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_PostNoCopy);
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	static int num[2], i , team;
	for(i = 1, num[0] = num[1] = 0; i <= MaxClients; i++)
		if(IsClientInGame(i)&& !IsFakeClient(i) && (team = GetClientTeam(i)) > 1 && IsPlayerAlive(i))
		{
			num[team - 2]++;
			if(num[0] && num[1]) return;
		}

	CS_TerminateRound(0.1, num[0] ? CSRoundEnd_TerroristWin : CSRoundEnd_CTWin, true);
}