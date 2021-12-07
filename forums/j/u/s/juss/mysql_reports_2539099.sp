#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

public Plugin myinfo =
{
	name = "SQL report Manager",
	author = "juss",
	description = "Manages SQL reports",
	version = "1.0",
	url = "https://rullers.ru"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_report", Players_Menu);
}

Database Connect()
{
	char error[255];
	Database db;

	if (SQL_CheckConfig("reports"))
	{
		db = SQL_Connect("reports", true, error, sizeof(error));
	} else {
		db = SQL_Connect("default", true, error, sizeof(error));
	}

	if (db == null)
	{
		LogError("Could not connect to database: %s", error);
	}

	return db;
}

public int ReasonMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		char info[32];
		bool found = menu.GetItem(param2, info, sizeof(info));
		PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int PlayersMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		char info[32];
		char display[32];
		bool found = menu.GetItem(param2, info, sizeof(info), param2, display, sizeof(display));

		char query[256];
		Database db = Connect();

		char userid[32];
		GetClientAuthId(param1, AuthId_Steam2, userid, sizeof(userid));

		DBResultSet rs;
		Format(query, sizeof(query), "SELECT id FROM sm_report WHERE reporter = '%s' AND reported = '%s'", userid, info);
		if ((rs = SQL_Query(db, query)) == null)
		{
			PrintToChat(param1, "\x02 \x02 [Server] query failed");
		}

		if (rs.RowCount > 0)
		{
			PrintToChat(param1, "\x02 \x07 [Server] Report on player %s has been send already!", display);
			delete rs;
			delete db;
			return Plugin_Handled;
		}
		delete rs;


		if (strcmp(info, userid, true) == 0)
		{
			PrintToChat(param1, "\x02 \x07 [Server] Looks like you are trying to report yourself =)");
			return Plugin_Handled;
		}

		Format(query, sizeof(query), "INSERT INTO sm_report (reported,reporter) VALUES ('%s','%s')", info, userid);

		if (!SQL_FastQuery(db, query))
		{
			PrintToChat(param1, "\x02 \x02 [Server] Report insertion query failed");
		} else {
			PrintToChat(param1, "\x02 \x04 [Server] Report on Player %s has been send", display);
		}
		delete db;

		/*PrintToChat(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);*/
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action Players_Menu(int client, int args)
{
	Menu menu = new Menu(PlayersMenuHandler);
	menu.SetTitle("Report Player");

	int mc = GetMaxClients();

	char cName[255];
	char steamid[255];

	for(int i = 1; i <= mc; i++)
	{
		/*if(IsClientInGame(i) && (CanUserTarget(client, i)))*/
		if(IsClientInGame(i))
		{
			GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));
			GetClientName(i, cName, sizeof(cName));
			menu.AddItem(steamid, cName);
		}
	}

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, 20);

	return Plugin_Handled;
}


public Action Menu_Reasons(int client, int args)
{
	Menu menu = new Menu(ReasonMenuHandler);
	menu.SetTitle("Select reason %s", args);
	menu.AddItem("wallhack", "Wallhack");
	menu.AddItem("aim", "Aim");
	menu.AddItem("speedhack", "Speedhack");
	menu.AddItem("cheating", "Cheating");
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, 20);

	return Plugin_Handled;
}
