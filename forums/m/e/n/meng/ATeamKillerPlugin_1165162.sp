/* 
	A Team Killer Plugin
		by meng
*/
#include <sourcemod>

new Handle:g_hTKDataTrie;

public OnPluginStart()
{
	g_hTKDataTrie = CreateTrie();
	HookEvent("player_death", EventPlayerDeath);
}

public OnMapStart()
{
	ClearTrie(g_hTKDataTrie);
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	if ((attacker != 0) && (attacker != victim) && (GetClientTeam(attacker) == GetClientTeam(victim)))
	{
		new engineTime = RoundToFloor(GetEngineTime());
		decl String:sSteamID[32], tkData[2];
		GetClientAuthString(attacker, sSteamID, sizeof(sSteamID));
		if (GetTrieArray(g_hTKDataTrie, sSteamID, tkData, 2) && (tkData[1] > engineTime))
		{
			switch (++tkData[0])
			{
				case 5:
				{
					tkData[1] = (engineTime + 600);
					SetTrieArray(g_hTKDataTrie, sSteamID, tkData, 2);
					KickClient(attacker, "Kicked for Team-Killing");
					LogMessage("%N kicked for team-killing", attacker);
				}
				case 10:
				{
					RemoveFromTrie(g_hTKDataTrie, sSteamID);
					BanClient(attacker, 0, BANFLAG_AUTO, "team-killing", "Banned for Team-Killing", "sm_ban", _);
					LogMessage("%N [%s] banned for team-killing", attacker, sSteamID);
				}
				default:
					SetTrieArray(g_hTKDataTrie, sSteamID, tkData, 2);
			}
		}
		else
		{
			tkData[0] = 1;
			tkData[1] = (engineTime + 600);
			SetTrieArray(g_hTKDataTrie, sSteamID, tkData, 2);
		}
	}
}