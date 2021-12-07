#include <sourcemod>
#include <cstrike>

StringMap g_hHashMap;

public void OnPluginStart()
{
	HookEvent("player_connect_full", Event_PlayerConnectFull);
}

public void OnMapStart()
{
	BrowseKeyValues();
}

public void Event_PlayerConnectFull(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientInGame(client))
	{
		char steamid[21];
		int team;
		if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)) && g_hHashMap.GetValue(steamid, team))
		{
			CS_SwitchTeam(client, team);
		}
	}
}

void BrowseKeyValues()
{
	delete g_hHashMap;

	KeyValues kv = new KeyValues("SteamIDs for Teams");
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "configs/steamidteams.cfg");
	if (!FileExists(config))
	{
		kv.JumpToKey("STEAM_0:0:00000000", true);
		kv.SetString("team", "ct");
		kv.Rewind();
		kv.JumpToKey("STEAM_0:0:11111111", true);
		kv.SetString("team", "t");
		kv.Rewind();
		kv.ExportToFile(config);
		LogMessage("Generated the config file %s!", config);
	}

	if (!kv.ImportFromFile(config) || !kv.GotoFirstSubKey())
	{
		delete kv;
		SetFailState("Failure parsing the config file %s!", config);
	}

	g_hHashMap = new StringMap();
	char steamid[21], team[11];
	do {
		kv.GetSectionName(steamid, sizeof(steamid));
		kv.GetString("team", team, sizeof(team));
		g_hHashMap.SetValue(steamid, StrEqual(team, "t", false) ? CS_TEAM_T : CS_TEAM_CT);
		LogMessage("Set team for SteamID: '%s' to '%s'!", steamid, team);
	} while kv.GotoNextKey();
	delete kv;
}
