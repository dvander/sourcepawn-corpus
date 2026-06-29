#pragma semicolon 1
#pragma newdecls required

Handle g_hHudSync;

public Plugin myinfo =
{
	name = "HUD Leaderboard",
	author = "Yaser2007",
	description = "Displays Top3 players in bottom of the screen.",
	version = "1.3",
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=Yaser2007&description=&search=1"
};

public void OnPluginStart()
{
	g_hHudSync = CreateHudSynchronizer();

	CreateTimer(1.0, DisplayTopPlayers, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
	if(g_hHudSync != null)
	{
		delete g_hHudSync;
	}
}

public void DisplayTopPlayers(Handle timer)
{
	int num;
	int clients[MAXPLAYERS+1];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || GetPlayerCount() < 3 || GetClientFrags(i) < 1 || GetClientTeam(i) < 2)
		{
			continue;
		}

		clients[num++] = i;
	}

	if(num > 0)
	{
		SortCustom1D(clients, num, SortScores);

		char buffer[256];
		FormatEx(buffer, sizeof(buffer), "#1 %N - %d frags\n", clients[0], GetClientFrags(clients[0]));

		if(num > 1)
		{
			FormatEx(buffer, sizeof(buffer), "%s#2 %N - %d frags\n", buffer, clients[1], GetClientFrags(clients[1]));
		}

		if(num > 2)
		{
			FormatEx(buffer, sizeof(buffer), "%s#3 %N - %d frags", buffer, clients[2], GetClientFrags(clients[2]));
		}

		SetHudTextParams(0.14, 0.0, 1.0, 255, 255, 0, 255);

		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || IsFakeClient(i))
			{
				continue;
			}

			ShowSyncHudText(i, g_hHudSync, buffer);
		}
	}
}

public int SortScores(int client1, int client2, const int[] array, Handle hndl)
{
	int frag1 = GetClientFrags(client1);
	int frag2 = GetClientFrags(client2);

	if(frag1 > frag2)
	{
		return -1;
	}
	else if(frag1 < frag2)
	{
		return 1;
	}

	return 0;
}

stock int GetPlayerCount()
{
	int players;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) < 2)
		{
			continue;
		}

		players++;
	}

	return players;
}

stock int Math_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();
	if(random == 0)
	{
		random++;
	}

	return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}