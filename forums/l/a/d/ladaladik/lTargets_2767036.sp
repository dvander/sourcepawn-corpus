#include <sourcemod>
#include <sdktools>
#include <discord>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.00"

public Plugin myinfo = 
{
	name = "Targets", 
	author = "LaFF", 
	description = "spy someone plugin", 
	version = PLUGIN_VERSION, 
	url = "LaFF#6135"
};

Database g_Database = null;

bool IsTargeted[MAXPLAYERS + 1] = false;
char szPlayerWebhook[MAXPLAYERS + 1][32];
char szPlayerDesc[MAXPLAYERS + 1][32];

int iKills[MAXPLAYERS + 1];

public void OnPluginStart()
{
	Database.Connect(Connect_Database, "target");
	RegAdminCmd("sm_addtarget", command_add, ADMFLAG_BAN);
	RegAdminCmd("sm_targets", command_targets, ADMFLAG_BAN);
	RegAdminCmd("sm_removetarget", command_remove, ADMFLAG_BAN);
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	HookEvent("player_death", Event_PD);
}
public Action command_targets(int client, int args)
{
	if (IsClientInGame(client))
	{
		g_Database.Query(Db_LoadMenu, "SELECT * FROM `target`", GetClientUserId(client));
	}
}
public void Db_LoadMenu(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || results == null)
	{
		LogError("targets menu returned error: %s", error);
		return;
	}
	int client = GetClientOfUserId(data);
	char szDesc[32];
	char szSteam64[32];
	char szWebhook[32];
	char temp[128];
	Menu menu = new Menu(mMenu);
	int loops;
	menu.SetTitle("ALL TARGETS [CLICK TO REMOVE]");
	while (results.FetchRow())
	{
		results.FetchString(0, szSteam64, sizeof(szSteam64));
		results.FetchString(1, szWebhook, sizeof(szWebhook));
		results.FetchString(2, szDesc, sizeof(szDesc));
		Format(temp, sizeof(temp), "Description \"%s\", steam64 \"%s\", webhook \"%s\"", szDesc, szSteam64, szWebhook);
		menu.AddItem(szSteam64, temp);
		loops++;
	}
	if (loops <= 0)
	{
		menu.AddItem("", "Seems like all your players are angels, you didn't add anyone yet :P", ITEMDRAW_DISABLED);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}
public int mMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char szItem[32];
			menu.GetItem(param2, szItem, sizeof(szItem));
			
			char query[254];
			g_Database.Format(query, sizeof(query), "DELETE FROM `target` WHERE steam64 = '%s'", szItem);
			g_Database.Query(Db_DoQuery, query);
		}
	}
}
public Action Event_PD(Event event, const char[] cmd, bool dbc)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsClientInGame(attacker))
	{
		iKills[attacker]++;
	}
}
public void OnMapEnd()
{
	char sMessage[254];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))continue;
		if (!IsTargeted[i])continue;
		if (iKills[i] > 0)
		{
			Format(sMessage, sizeof(sMessage), "**%N** ||%s|| MAPEND : Has %i kills", i, szPlayerDesc[i], iKills[i]);
			Discord_SendMessage(szPlayerWebhook[i], sMessage);
		}
	}
}

public Action Command_Say(int client, const char[] command, int args)
{
	if (IsClientInGame(client) && IsTargeted[client])
	{
		char text[128];
		char sMessage[254];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		Format(sMessage, sizeof(sMessage), "**%N** ||%s|| **%s** : %s", client, szPlayerDesc[client], command, text);
		Discord_SendMessage(szPlayerWebhook[client], sMessage);
	}
}

public Action command_add(int client, int args)
{
	char cmd[32];
	char webhook[32];
	char desc[32];
	GetCmdArg(1, cmd, sizeof(cmd));
	GetCmdArg(2, webhook, sizeof(webhook));
	GetCmdArg(3, desc, sizeof(desc));
	char query[354];
	PrintToChat(client, "[SM] You've sucesfully targeted player (%s), message will be sent into webhook entry named (%s) description is (%s)", cmd, webhook, desc);
	g_Database.Format(query, sizeof(query), "INSERT INTO `target` (steam64, webhook, descr) VALUES ('%s', '%s', '%s')", cmd, webhook, desc);
	g_Database.Query(Db_DoQuery, query);
}
public Action command_remove(int client, int args)
{
	char cmd[32];
	GetCmdArg(1, cmd, sizeof(cmd));
	char query[254];
	PrintToChat(client, "[SM] You've sucesfully removed (%s) from targets", cmd);
	g_Database.Format(query, sizeof(query), "DELETE FROM `target` WHERE steam64 = '%s'", cmd);
	g_Database.Query(Db_DoQuery, query);
}

public void OnClientPutInServer(int client)
{
	if (client > 0)IsTargeted[client] = false; iKills[client] = 0;
	char steam64[32];
	if (IsClientInGame(client) && GetClientAuthId(client, AuthId_SteamID64, steam64, sizeof(steam64)))
	{
		GetClientAuthId(client, AuthId_SteamID64, steam64, sizeof(steam64));
		char query[254];
		g_Database.Format(query, sizeof(query), "SELECT * FROM `target` WHERE steam64 = '%s'", steam64);
		g_Database.Query(Db_LoadPlayer, query, GetClientUserId(client));
	}
}
public void OnClientDisconnect(int client)
{
	if (IsTargeted[client])
	{
		char sMessage[254];
		Format(sMessage, sizeof(sMessage), "**%N** ||%s|| **ACT** : Disconnected", client, szPlayerDesc[client]);
		Discord_SendMessage(szPlayerWebhook[client], sMessage);
	}
}

public void Db_LoadPlayer(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || results == null)
	{
		LogError("targets returned error: %s", error);
		return;
	}
	int client = GetClientOfUserId(data);
	if (results.FetchRow())
	{
		if (IsClientInGame(client))
		{
			IsTargeted[client] = true;
			results.FetchString(1, szPlayerWebhook[client], sizeof(szPlayerWebhook));
			results.FetchString(2, szPlayerDesc[client], sizeof(szPlayerDesc));
			char sMessage[254];
			Format(sMessage, sizeof(sMessage), "**%N** ||%s|| **ACT** : Connected", client, szPlayerDesc[client]);
			Discord_SendMessage(szPlayerWebhook[client], sMessage);
		}
	} else {
		// hráč neexistuje v db
	}
	
}

public void Connect_Database(Database db, const char[] error, int data)
{
	char query[356];
	if (db == null)
	{
		PrintToServer("[target] invalid database handle");
		return;
	}
	g_Database = db;
	PrintToServer("[target] SUCESFULLY CONNECTED TO DATABASE");
	Format(query, sizeof(query), 
		"CREATE TABLE IF NOT EXISTS `target` (`steam64` VARCHAR(32), `webhook` VARCHAR(32), `descr` VARCHAR(32)) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
		);
	
	g_Database.Query(Db_DoQuery, query);
}


public void Db_DoQuery(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || results == null)
	{
		LogError("[TARGETS DO QUERY] returned error: %s", error);
		return;
	}
}
