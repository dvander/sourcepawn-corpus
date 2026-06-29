#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "SteamID Menu",
	author = "Yaser2007",
	description = "Shows your steamids (2,3,64) in menu.",
	version = "1.0",
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=Yaser2007&description=&search=1"
};

public void OnPluginStart()
{
	RegConsoleCmd("steamid", Cmd_SteamID);
}

public Action Cmd_SteamID(int client, int args)
{
	if(!client)
	{
		return Plugin_Handled;
	}

	char steamid[3][MAX_AUTHID_LENGTH];
	char display[3][MAX_AUTHID_LENGTH];

	char types[3][] =
	{
		"SteamID2",
		"SteamID3",
		"SteamID64"
	};

	AuthIdType authType[3] =
	{
		AuthId_Steam2,
		AuthId_Steam3,
		AuthId_SteamID64
	};

	Menu menu = CreateMenu(Menu_SteamIDs);

	for(int i = 0; i < 3; i++)
	{
		GetClientAuthId(client, authType[i], steamid[i], sizeof(steamid[]), false);
		FormatEx(display[i], sizeof(display[]), "%s: %s", types[i], steamid[i]);
		AddMenuItem(menu, steamid[i], display[i]);
	}

	DisplayMenu(menu, client, 30);

	return Plugin_Handled;
}

public void Menu_SteamIDs(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, item, info, sizeof(info));
			PrintToChat(client, info);
		}
	}
}