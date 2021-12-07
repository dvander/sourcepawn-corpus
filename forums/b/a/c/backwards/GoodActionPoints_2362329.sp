#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>

public Plugin myinfo = 
{
	name = "[CS:GO] Good Action Points.",
	author = "backwards",
	description = "Allows Admins To Reward Clients Points For Good Behaviors.",
	version = "1.0",
	url = "http://steamcommunity.com/id/mypassword"
};

ConVar g_hCvarVersion;

new Handle:g_hDatabase = INVALID_HANDLE;
new bool:SQL_DBLoaded = false;

new TotalRep[MAXPLAYERS+1];
new firstspawn[MAXPLAYERS+1] = {true,...};

public void OnPluginStart()
{
	g_hCvarVersion = CreateConVar("sm_good_actions_version", "1.0", "Good Action Points System", FCVAR_NONE);
	g_hCvarVersion.SetString("1.0");

	SQL_TConnect(SQLCallback_Connect, "Good-Actions-Ranks");
	
	for(new client = 1; client <= MaxClients; client++)
		if(IsClientInGame(client))
			GetPlayerRep(client);
	
	HookEvent("player_spawn", Event_PlayerSpawn);

	RegAdminCmd("sm_repgive", Cmd_RepGive, ADMFLAG_GENERIC, "usage: sm_repgive <player> <points>");
	RegAdminCmd("sm_reptake", Cmd_RepTake, ADMFLAG_GENERIC, "usage: sm_reptake <player> <points>");

	RegConsoleCmd("sm_reprank", Cmd_RepRank, "Shows your current reputation rank.");
	RegConsoleCmd("sm_reptop", Cmd_RepTop, "Shows The Top10 current players based off of reputation rank.");
}

public OnPluginEnd()
{
	for(new client = 1; client <= MaxClients; client++)
		if(IsClientInGame(client))
			OnClientDisconnect(client);
}

public Action:Cmd_RepRank(client, args)
{
	new String:query[256];
	new String:authid[32];
	GetClientAuthString(client, authid, sizeof(authid));
	Format(query, sizeof(query), "SELECT COUNT(*)+1 as rank FROM (SELECT points FROM reputationdata ORDER BY points) AS sc WHERE points > (SELECT points FROM reputationdata WHERE steamid=\"%s\") LIMIT 1;", authid);
	SQL_TQuery(g_hDatabase, SQLCallback_RepRank, query, client);

	return Plugin_Handled;
}

public SQLCallback_RepRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RepSystem] SQLCallback_RepRank failure: %s", error);
		return;
	}

	new rank = 0;
	
	if(SQL_HasResultSet(hndl))
	{
		while(SQL_FetchRow(hndl))
		{
			rank = SQL_FetchInt(hndl, 0);
			PrintToChat(client, "You are Rank %i with %i Reputation!", rank, TotalRep[client]);
		}
	}
}

public Action:Cmd_RepTop(client, args)
{
	new String:query[256];
	new String:authid[32];
	GetClientAuthString(client, authid, sizeof(authid));
	Format(query, sizeof(query), "SELECT * FROM `reputationdata`ORDER BY points DESC LIMIT 10;", authid);
	SQL_TQuery(g_hDatabase, SQLCallback_RepTop, query, client);

	return Plugin_Handled;
}

public SQLCallback_RepTop(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RepSystem] SQLCallback_RepTop failure: %s", error);
		return;
	}
	new Handle:panel = CreatePanel();
	DrawPanelText(panel, "[RepSystem] Top 10 Players by Reputation");

	decl String:steamid[32];
	decl String:name[MAX_NAME_LENGTH];
	new Reputation, index = 0;
	
	if(SQL_HasResultSet(hndl))
	{
		while(SQL_FetchRow(hndl))
		{
			index++;
			SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
			Reputation = SQL_FetchInt(hndl, 1);
			SQL_FetchString(hndl, 2, name, sizeof(name));

			TopRepCallback(client, name, steamid, Reputation, index, panel);
		}
	}
	TopRepCallback(client, "", "", 0, 0, panel);
}

public TopRepCallback(client, const String:name[], const String:steamid[], points, index, Handle:panel)
{
	if(steamid[0] == 0)// last call
	{
		SendPanelToClient(panel, client, TopRepHandler, 10);
		CloseHandle(panel);
	}
	else
	{
		decl String:text[256];
		if(index > 3)
		{
			Format(text, sizeof(text), "%i. %s - %i Rep", index, name, points);
			DrawPanelText(panel, text);
		}
		else
		{
			Format(text, sizeof(text), "%s - %i Rep", name, points);
			DrawPanelItem(panel, text);
		}
	}
}

public TopRepHandler(Handle:menu, MenuAction:action, param1, param2)
{
}


public Action:Cmd_RepGive(client, args)
{
	if(args != 2)
	{
		PrintToChat(client, "usage: sm_repgive <player> <points>");
		return Plugin_Handled;
	}

	new String:arg1[32], String:arg2[32];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new target = FindTarget(client, arg1);
	if (target == -1)
	{
		PrintToChat(client, "[RepSystem]: Target not found!");
		return Plugin_Handled;
	}

	new value = StringToInt(arg2);
	if(value < 1 || value >= 99999999)
	{
		PrintToChat(client, "[RepSystem]: %i is not a valid value!", value);
		return Plugin_Handled;
	}

	TotalRep[target] += value;
	SavePlayerRep(target);

	new String:name[MAX_NAME_LENGTH];

	GetClientName(target, name, sizeof(name));

	PrintToChat(client, "[RepSystem]: You've Given %s %i reputation points!", name, value);
	PrintToChatAll("[RepSystem]: %s has been given %i reputation and now has %i points!", name, value, TotalRep[target]);
	PlaySound("common/bass.wav");

	return Plugin_Handled;
}

public Action:Cmd_RepTake(client, args)
{
	if(args != 2)
	{
		PrintToChat(client, "usage: sm_reptake <player> <points>");
		return Plugin_Handled;
	}

	new String:arg1[32], String:arg2[32];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new target = FindTarget(client, arg1);
	if (target == -1)
	{
		PrintToChat(client, "[RepSystem]: Target not found!");
		return Plugin_Handled;
	}

	new value = StringToInt(arg2);
	if(value < 1 || value >= 99999999)
	{
		PrintToChat(client, "[RepSystem]: %i is not a valid value!", value);
		return Plugin_Handled;
	}

	TotalRep[target] -= value;
	if(TotalRep[target] < 0)
		TotalRep[target] = 0;

	SavePlayerRep(target);

	new String:name[MAX_NAME_LENGTH];

	GetClientName(target, name, sizeof(name));

	PrintToChat(client, "[RepSystem]: You've Taken Away %i reputation points from %s!", value, name);
	PrintToChatAll("[RepSystem]: %s has had %i reputation points taken away and now has %i rep..", name, value, TotalRep[target]);
	PlaySound("common/bass.wav");
	
	return Plugin_Handled;
}

public void DefaultAll()
{
	for(new client = 1; client <= MaxClients; client++)
		if(IsClientInGame(client))
			GetPlayerRep(client);
}

public OnClientDisconnect(client)
{
	SavePlayerRep(client);
	TotalRep[client] = 0;
	firstspawn[client] = true;
}

public OnClientAuthorized(client, const String:auth[])
{
	GetPlayerRep(client);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client))
		return Plugin_Continue;
	
	if(firstspawn[client])
	{
		GetPlayerRep(client);
		firstspawn[client] = false;
	}

	return Plugin_Continue;
}


public SQLCallback_Connect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Error connecting to database. %s", error);
	} else {
		g_hDatabase = hndl;
		decl String:BufferQuery[512];
		Format(BufferQuery, sizeof(BufferQuery), "CREATE TABLE IF NOT EXISTS `reputationdata` (`steamid` varchar(32) NOT NULL, `points` int(11) DEFAULT 0, `name` varchar(32) NOT NULL)");
		SQL_TQuery(g_hDatabase, SQLCallback_Enabled, BufferQuery);
	}
}
public SQLCallback_Enabled(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Error connecting to database. %s", error);
	} else {
		SQL_DBLoaded = true;
		DefaultAll();
	}
}

GetPlayerRep(client)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		if(SQL_DBLoaded)
		{
			new String:authid[32];
			new String:query[256];
			GetClientAuthString(client, authid, sizeof(authid));
			Format(query, sizeof(query), "SELECT * FROM `reputationdata` WHERE steamid=\"%s\"", authid);
			SQL_TQuery(g_hDatabase, SQLCallback_GetPlayer, query, GetClientUserId(client));
		}
	}
}

SavePlayerRep(client)
{
	if(SQL_DBLoaded && TotalRep[client] != 0 && !IsFakeClient(client))
	{
		new String:query[256];
		new String:authid[32];
		new String:name[MAX_NAME_LENGTH];
		GetClientAuthString(client, authid, sizeof(authid));
		GetClientName(client, name, sizeof(name));

		Format(query, sizeof(query), "UPDATE `reputationdata` SET points=%i, name=\"%s\" WHERE steamid=\"%s\"", TotalRep[client], name, authid);
		SQL_TQuery(g_hDatabase, SQLCallback_Void, query);
	}
}

public SQLCallback_GetPlayer(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Error. %s", error);
	} else {
		new client = GetClientOfUserId(userid);
		if(client == 0)
			return;
		
		if(SQL_GetRowCount(hndl)>=1)
		{
			SQL_FetchRow(hndl);
			TotalRep[client] = SQL_FetchInt(hndl, 1);
		}
		else
		{
			new String:query[256];
			new String:authid[32];
			new String:name[MAX_NAME_LENGTH];
			GetClientName(client, name, sizeof(name));
			GetClientAuthString(client, authid, sizeof(authid));
			Format(query, sizeof(query), "INSERT INTO `reputationdata` (steamid, points, name) VALUES(\"%s\", 0, \"%s\")", authid, name);
			SQL_TQuery(g_hDatabase, SQLCallback_Void, query, userid);
		}
	}
}

public SQLCallback_Void(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		LogError("Error. %s", error);
}

public PlaySound(String:soundpath[])
{
	decl String:buffer[150];
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			Format(buffer, sizeof(buffer), "playgamesound %s", soundpath);
			ClientCommand(i, buffer);
		}
	}
}