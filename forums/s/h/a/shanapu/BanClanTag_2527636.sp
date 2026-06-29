#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

ConVar gc_bPlugin;

Handle g_aBadTags;

public Plugin myinfo =
{
	name = "Ban Clan Tags",
	description = "Auto Ban a player with bad tag",
	author = "shanapu",
	version = "1.0.0",
	url = "https://github.com/shanapu/"
}

public void OnPluginStart()
{
	AutoExecConfig(true,"banclantags");
	gc_bPlugin = CreateConVar("sm_badtag_enable", "1", "0 - disabled, 1 - enable", _, true, 0.0, true, 1.0);

	HookEvent("player_spawn", Event_Spawn);
}

public void Event_Spawn(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	CreateTimer(0.1, Timer_DelayCheck, client);
}

public void OnClientPutInServer(int client)
{
	CreateTimer(5.0, Timer_DelayCheck, client);
}

public void OnClientSettingsChanged(int client)
{
	CreateTimer(0.1, Timer_DelayCheck, client);
}

public void OnConfigsExecuted()
{
	GetBadTags();
}

public Action Timer_DelayCheck(Handle timer, int client)
{
	if (IsClientInGame(client))
	{
		CheckClanTag(client);
	}
}

void GetBadTags()
{
	char g_filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, g_filename, sizeof(g_filename), "configs/banclantags.ini");

	Handle file = OpenFile(g_filename, "rt");

	if (file == INVALID_HANDLE)
	{
		LogMessage("Could not open file!");
		return;
	}

	g_aBadTags = CreateArray(255);

	while (!IsEndOfFile(file))
	{
		char line[255];

		if(!ReadFileLine(file, line, sizeof(line)))
		{
			break;
		}

		TrimString(line);

		if (!line[0])
			continue;

		PushArrayString(g_aBadTags, line);
	}

	CloseHandle(file);
}

void CheckClanTag(int client)
{
	if (gc_bPlugin.BoolValue)
	{
		char sClanTag[255];
		CS_GetClientClanTag(client, sClanTag, sizeof(sClanTag));

		if (!sClanTag[0])
			return;

		for (int i = 0; i < GetArraySize(g_aBadTags); i++)
		{
			char sBadTag[255];
			GetArrayString(g_aBadTags, i, sBadTag, sizeof(sBadTag));

			if (!StrContains(sClanTag, sBadTag, false))
			{
				BanClient(client, 0, BANFLAG_AUTO, "Bad Clan Tag");
				LogMessage("The ClanTag of %N was %s - player was banned", client, sClanTag);

				break;
			}
		}
	}
}