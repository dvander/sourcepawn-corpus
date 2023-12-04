#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

enum struct Player
{
	int iKDRatio;
	int iClient;
}

public Plugin myinfo =
{
	name		= "auto-team-balance",
	author		= "Keldra",
	description = "",
	version		= "1.0.0",
	url			= "https://github.com/ddorab/auto-team-balance"
};

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
}

void Event_RoundEnd(Event e, const char[] name, bool dB)
{
	ArrayList players[2];
	players[0] = new ArrayList(sizeof(Player));
	players[1] = new ArrayList(sizeof(Player));

	for (int i = 1; i <= MaxClients; i++)
	{
		int team;
		if (!IsClientInGame(i) || (team = GetClientTeam(i)) < 2) continue;

		Player player;
		int	   deaths = GetClientDeaths(i);
		if (deaths <= 0) deaths = 1;
		player.iKDRatio = GetClientFrags(i) / deaths;
		player.iClient	= i;
		players[team - 2].PushArray(player);
	}

	int diff	= players[0].Length - players[1].Length;
	int diffAbs = diff > 0 ? diff : -diff;
	if (diffAbs > 1)
	{
		int index = diff > 1 ? 0 : 1;
		for (int i = 0; i < diffAbs / 2; ++i)
		{
			int	   random = GetRandomInt(0, players[index].Length - 1);
			Player player;

			players[index].GetArray(random, player);
			players[index % 2 == 0 ? 1 : 0].PushArray(player);
			players[index].Erase(random);
		}
	}

	int sum1 = GetSum(players[0]);
	int sum2 = GetSum(players[1]);

	players[0].Sort(Sort_Descending, Sort_Integer);
	players[1].Sort(Sort_Descending, Sort_Integer);

	if (players[0].Length == 0 || players[1].Length == 0) return;

	int	 targetDiff = RoundToFloor((float(sum1) / players[0].Length - float(sum2) / players[1].Length) / (1.0 / players[0].Length + 1.0 / players[1].Length));

	bool bFound		= targetDiff == 0;
	int	 result[2];
	int	 pair[2];
	int	 temp[2] = { -1, ... };
	bool bCheck;
	while (!bFound)
	{
		if (targetDiff > 0) bFound = FindPair(players[0], players[1], targetDiff, result, pair);
		else bFound = FindPair(players[1], players[0], targetDiff, result, pair);

		if (!bFound)
		{
			Player p1;
			Player p2;
			players[0].GetArray(0, p1);
			players[1].GetArray(players[1].Length - 1, p2);

			targetDiff += targetDiff > p1.iKDRatio - p2.iKDRatio ? -1 : 1;
		}
		else
		{
			if ((temp[0] == pair[1] && temp[1] == pair[0]) || (temp[0] == pair[0] && temp[1] == pair[1]) || (bCheck && (temp[0] == pair[0] || temp[1] == pair[1]))) break;

			int	   index = targetDiff > 0 ? 0 : 1;
			Player p1;
			Player p2;
			players[index].GetArray(result[0], p1);
			players[index % 2 == 0 ? 1 : 0].GetArray(result[1], p2);

			players[index].Erase(result[0]);
			players[index % 2 == 0 ? 1 : 0].Erase(result[1]);

			players[index].PushArray(p2);
			players[index % 2 == 0 ? 1 : 0].PushArray(p1);

			players[0].Sort(Sort_Descending, Sort_Integer);
			players[1].Sort(Sort_Descending, Sort_Integer);

			sum1	   = GetSum(players[0]);
			sum2	   = GetSum(players[1]);

			targetDiff = RoundToFloor((float(sum1) / players[0].Length - float(sum2) / players[1].Length) / (1.0 / players[0].Length + 1.0 / players[1].Length));

			bCheck	   = temp[0] == pair[0] || temp[1] == pair[1];
			temp	   = pair;
			bFound	   = targetDiff == 0;
		}
	}

	for (int i = 0; i < players[0].Length; ++i)
	{
		Player player;
		players[0].GetArray(i, player);

		if (GetClientTeam(player.iClient) != 2)
		{
			PrintToChat(player.iClient, "[SM]Takım eşitlemesi için \x09T \x01takımına atıldın.");
		}

		CS_SwitchTeam(player.iClient, 2);
	}

	for (int i = 0; i < players[1].Length; ++i)
	{
		Player player;
		players[1].GetArray(i, player);

		if (GetClientTeam(player.iClient) != 3)
		{
			PrintToChat(player.iClient, "[SM]Takım eşitlemesi için \x0BCT \x01takımına atıldın.");
		}
		CS_SwitchTeam(player.iClient, 3);
	}

	delete players[0];
	delete players[1];
}

int GetSum(ArrayList arr)
{
	int sum;
	for (int i = 0; i < arr.Length; ++i)
	{
		Player player;
		arr.GetArray(i, player);
		sum += player.iKDRatio;
	}

	return sum;
}

bool FindPair(ArrayList arr1, ArrayList arr2, int targetDiff, int result[2], int pair[2])
{
	targetDiff = targetDiff > 0 ? targetDiff : -targetDiff;

	for (int i = 0; i < arr1.Length; ++i)
	{
		Player player;
		arr1.GetArray(i, player);

		int n	  = player.iKDRatio;
		int v1	  = n + targetDiff;
		int v2	  = n - targetDiff;
		result[0] = i;
		pair[0]	  = n;

		for (int j = 0; j < arr2.Length; ++j)
		{
			arr2.GetArray(j, player);

			if (player.iKDRatio == v1)
			{
				result[1] = j;
				pair[1]	  = v1;
				return true;
			}
			if (player.iKDRatio == v2)
			{
				result[1] = j;
				pair[1]	  = v2;
				return true;
			}
		}
	}

	return false;
}