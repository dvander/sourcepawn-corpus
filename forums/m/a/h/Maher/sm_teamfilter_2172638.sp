#define VERSION "1.0"

#pragma semicolon 1
#pragma tabsize 0
#include <sourcemod>

new bool:g_Enabled = false;
new Handle:g_hDB = INVALID_HANDLE;
new Handle:g_Teams = INVALID_HANDLE;
new String:g_TeamsList[71];

public Plugin:myinfo = 
{
	name = "SM Team Filter",
	author = "Maher Fallouh",
	description = "Allowing specified teams to join the game while preventing others!",
	version = VERSION,
	url = "maher.fallouh@gmail.com"
};

public OnPluginStart()
{
	g_Teams = CreateArray(11);
	CreateConVar("sm_teamfilter_version", VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_teamfilter", Command_TeamFilter, ADMFLAG_ROOT);
	RegConsoleCmd("sm_myteam", Command_MyTeam);
	InitDB();
}

// Here we are creating SQL DB
public InitDB()
{
	new String:sqlError[255];
	
	g_hDB = SQL_Connect("default", true, sqlError, sizeof(sqlError));
	
	if (g_hDB == INVALID_HANDLE)
	{
		LogError("[TeamFilter] Couldn't connect to the Database! Error: %s", sqlError);
	}
	else 
	{
		SQL_LockDatabase(g_hDB);
		SQL_FastQuery(g_hDB, "VACUUM");
		SQL_FastQuery(g_hDB, "CREATE TABLE IF NOT EXISTS player_team (SteamID CHAR(32), Name TEXT NOT NULL, Team CHAR(10), primary key (SteamID, Team));");
		SQL_UnlockDatabase(g_hDB);
	}
}



public Action:Command_TeamFilter(admin, args)
{
	if (args < 1)
	{
		ReplyToCommand(admin, "Usage: !teamfilter <on|off|add|delete|status|members|reset> <team1, team2, ...>");
	}
	else
	{
		new String:arg1[11];
		GetCmdArg(1, arg1, sizeof(arg1));
		if (!strcmp(arg1, "off"))
		{
			if(g_Enabled)
			{
				g_Enabled = false;
				ClearArray(g_Teams);
				PrintToChatAll("\x04[Team Filter]\x01 \x04%N\x01 removed current filter!", admin);
			}
			else
			{
				ReplyToCommand(admin, "\x04[Team Filter]\x01 There is no filter at the moment!");
			}
		}
		else if(!strcmp(arg1, "on"))
		{
			if(args < 2)
			{
				ReplyToCommand(admin, "\x04[Team Filter]\x01 Please specify one team at least!");
			}
			else
			{
				ClearArray(g_Teams);
				new String:team[11];
				for (new i = 2; i <= 7; i++)
				{
					GetCmdArg(i, team, sizeof(team));
					for (new t = 0; t < strlen(team); ++t) 
					{
						if (IsCharLower(team[t])) team[t] = CharToUpper(team[t]);
					}
					if (FindStringInArray(g_Teams, team) == -1 && strlen(team) > 0) 
					{
						PushArrayString(g_Teams, team);
					}
				}
				if (GetArraySize(g_Teams) == 0) 
				{
					ReplyToCommand(admin, "\x04[Team Filter]\x01 Please specify one team at least!");
					return Plugin_Handled;
				}
				g_TeamsList[0] = 0;
				GetArrayString(g_Teams, 0, team, sizeof(team));
				StrCat(g_TeamsList, 71, team);
				for (new i = 1; i < GetArraySize(g_Teams); i++)
				{
					GetArrayString(g_Teams, i, team, sizeof(team));
					StrCat(g_TeamsList, 71, ", ");
					StrCat(g_TeamsList, 71, team);
				}
				PushArrayString(g_Teams, "*");
				PrintToChatAll("\x04[Team Filter]\x01 \x04%N\x01 created a filter \x04[%s]", admin, g_TeamsList);
				g_Enabled = true;
				CheckPlayers();
			}
		}
		else if(!strcmp(arg1, "add"))
		{
			if(args < 2)
			{
				ReplyToCommand(admin, "\x04[Team Filter]\x01 Please specify a team!");
			}
			else if (admin == 0)
			{
				ReplyToCommand(admin, "\x04[Team Filter]\x01 Only ingame command!");
			}
			else
			{
				new String:team[11];
				GetCmdArg(2, team, sizeof(team));
				if (strlen(team) == 0)
				{
					ReplyToCommand(admin, "\x04[Team Filter]\x01 Please specify a team!");
				}
				else
				{
					for (new i = 0; i < strlen(team); ++i) 
					{
						if (IsCharLower(team[i])) team[i] = CharToUpper(team[i]);
					}
					new Handle:menu = CreateMenu(MenuHandler_Add);
					SetMenuTitle(menu, team);
					decl String:SteamID[32];
					decl String:Name[65];
					for (new i = 1; i<= MaxClients; ++i)
					{
						if(IsClientAuthorized(i))
						{
							GetClientAuthString(i, SteamID, sizeof(SteamID));
							GetClientName(i, Name, sizeof(Name));
							AddMenuItem(menu, SteamID, Name);
						}
					}
					SetMenuExitButton(menu, true);
					DisplayMenu(menu, admin, 20);
				}
			}
		}
		else if(!strcmp(arg1, "delete"))
		{
			if(args < 2)
			{
				ReplyToCommand(admin, "\x04[Team Filter]\x01 Please specify a team!");
			}
			else if (admin == 0)
			{
				ReplyToCommand(admin, "\x04[Team Filter]\x01 Only ingame command!");
			}
			else
			{
				new String:team[11];
				GetCmdArg(2, team, sizeof(team));
				if (strlen(team) == 0)
				{
					ReplyToCommand(admin, "\x04[Team Filter]\x01 Please specify a team!");
				}
				else
				{
					for (new i = 0; i < strlen(team); ++i) 
					{
						if (IsCharLower(team[i])) team[i] = CharToUpper(team[i]);
					}
					decl String:query[255];
					new Handle:data = INVALID_HANDLE;
					data = CreateArray(11);
					PushArrayString(data, team);
					PushArrayCell(data, GetClientUserId(admin));
					Format(query, sizeof(query), "SELECT SteamID, Name FROM player_team WHERE Team = '%s'", team);
					SQL_TQuery(g_hDB, DeleteCallback, query, data);
				}
			}
		}
		else if(!strcmp(arg1, "status"))
		{
			if(g_Enabled)
			{
				PrintToChatAll("\x04[Team Filter]\x01 Current active filter is \x04[%s]", g_TeamsList);
			}
			else
			{
				PrintToChatAll("\x04[Team Filter]\x01 There is no filter at the moment!");
			}
		}
		else if(!strcmp(arg1, "members"))
		{
			if(args < 2)
			{
				ReplyToCommand(admin, "\x04[Team Filter]\x01 Please specify a team!");
			}
			else if (admin == 0)
			{
				ReplyToCommand(admin, "\x04[Team Filter]\x01 Only ingame command!");
			}
			else
			{
				new String:team[11];
				GetCmdArg(2, team, sizeof(team));
				if (strlen(team) == 0)
				{
					ReplyToCommand(admin, "\x04[Team Filter]\x01 Please specify a team!");
				}
				else
				{
					for (new i = 0; i < strlen(team); ++i) 
					{
						if (IsCharLower(team[i])) team[i] = CharToUpper(team[i]);
					}
					decl String:query[255];
					Format(query, sizeof(query), "SELECT Name FROM player_team WHERE Team = '%s'", team);
					SQL_TQuery(g_hDB, MembersCallback, query, GetClientUserId(admin));
				}
			}
		}
		else if(!strcmp(arg1, "reset"))
		{
			if(args < 2)
			{
				ReplyToCommand(admin, "\x04[Team Filter]\x01 Please specify a team!");
			}
			else
			{
				new String:team[11];
				GetCmdArg(2, team, sizeof(team));
				if (strlen(team) == 0)
				{
					ReplyToCommand(admin, "\x04[Team Filter]\x01 Please specify a team!");
				}
				else
				{
					for (new i = 0; i < strlen(team); ++i) 
					{
						if (IsCharLower(team[i])) team[i] = CharToUpper(team[i]);
					}
					new String:query[256];
					Format(query, sizeof(query), "DELETE FROM player_team WHERE Team = '%s'", team);
					if (!SQL_FastQuery(g_hDB, query))
					{
						new String:error[255];
						SQL_GetError(g_hDB, error, sizeof(error));
						ReplyToCommand(admin, "\x04[Team Filter]\x01 Quesy failed. error : %s!", error);
					}
					else
					{
						PrintToChatAll("\x04[Team Filter]\x01 All members of\x04 %s\x01 team has been removed!", team);
						PrintToServer("[Team Filter] %s team has been reset by %N", team, admin);
					}
				}
			}
		}
	}
	return Plugin_Handled;
}


public CheckPlayers()
{
	//SQL_LockDatabase(g_hDB);
	for (new i = 1; i <= MaxClients; ++i)
	{
		if(IsClientAuthorized(i))
		{
			decl String:query[255];
			decl String:SteamID[32];
			GetClientAuthString(i, SteamID, sizeof(SteamID));
			
			Format(query, sizeof(query), "SELECT Team FROM player_team WHERE SteamID = '%s'", SteamID);
			SQL_TQuery(g_hDB, T_CheckSteamID, query, GetClientUserId(i));
		}
	}
	//SQL_UnlockDatabase(g_hDB);
}

public T_CheckSteamID(Handle:owner, Handle:query, const String:error[], any:data)
{
	new client;
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (query == INVALID_HANDLE)
	{
		LogError("[TeamFilter] Query failed! %s", error);
		KickClient(client, "Opps :( Authentication failed");
	} 
	else if (!SQL_GetRowCount(query)) 
	{
		KickClient(client, "Opps :( Only members of [%s] can join at the moment! please try again later", g_TeamsList);
	}
	else
	{
		new String:team[11];
		while (SQL_FetchRow(query))
		{
			SQL_FetchString(query, 0, team, sizeof(team));
			if(FindStringInArray(g_Teams, team) != -1) return;
		}
		KickClient(client, "Opps :( Only members of [%s] can join at the moment! please try again later", g_TeamsList);
	}
}

public MembersCallback(Handle:owner, Handle:query, const String:error[], any:data)
{
	new client = GetClientOfUserId(data);
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}
 
	if (query == INVALID_HANDLE)
	{
		LogError("[TeamFilter] Query failed! %s", error);
		if(IsClientInGame(client))
			PrintToChat(client, "\x04[Team Filter]\x01 Failed to fetch members list!");
	} 
	else if (!SQL_GetRowCount(query)) 
	{
		if(IsClientInGame(client))
			PrintToChat(client, "\x04[Team Filter]\x01 Specified team has no members!");
	}
	else
	{
		new String:name[128];
		new Handle:menu = CreateMenu(MenuHandler_List);
		
		while (SQL_FetchRow(query))
		{
			SQL_FetchString(query, 0, name, sizeof(name));
			AddMenuItem(menu, "", name);
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
}

public MenuHandler_List(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if (g_Enabled)
	{
		decl String:query[255];	
		Format(query, sizeof(query), "SELECT Team FROM player_team WHERE SteamID = '%s'", auth);
		SQL_TQuery(g_hDB, T_CheckSteamID, query, GetClientUserId(client));
	}
}

public MenuHandler_Add(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:query[256];
		decl String:SteamID[32];
		decl String:Name[128], String:escapeName[128];
		decl String:Team[11];
		new style;
		GetMenuTitle(menu, Team, sizeof(Team));
		new bool:found = GetMenuItem(menu, param2, SteamID, sizeof(SteamID), style, Name, sizeof(Name));
		if (!found) 
		{
			if(IsClientInGame(param1))
				PrintToChat(param1, "\x04[Team Filter]\x01 Selected member not found!");
			return;
		}
		SQL_EscapeString(g_hDB, Name, escapeName, sizeof(escapeName));
		Format(query, sizeof(query), "REPLACE INTO player_team VALUES ('%s', '%s', '%s')", SteamID, escapeName, Team);
		if (!SQL_FastQuery(g_hDB, query))
		{
			new String:error[255];
			SQL_GetError(g_hDB, error, sizeof(error));
			if(IsClientInGame(param1))
				PrintToChat(param1, "\x04[Team Filter]\x01 Quesy failed. error : %s!", error);
			return;
		}
		PrintToChatAll("\x04[Team Filter]\x01 Player \x04%s\x01 added to \x04%s\x01 team", Name, Team);
		PrintToServer("[Team Filter] Player %s added to %s team by %N", Name, Team, param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Delete(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:query[256];
		decl String:SteamID[32];
		decl String:Name[128];
		decl String:Team[11];
		new style;
		GetMenuTitle(menu, Team, sizeof(Team));
		new bool:found = GetMenuItem(menu, param2, SteamID, sizeof(SteamID), style, Name, sizeof(Name));
		if (!found) 
		{
			if(IsClientInGame(param1))
				PrintToChat(param1, "\x04[Team Filter]\x01 Selected member not found!");
			return;
		}
		Format(query, sizeof(query), "DELETE FROM player_team WHERE SteamID = '%s' and Team = '%s'", SteamID, Team);
		if (!SQL_FastQuery(g_hDB, query))
		{
			new String:error[255];
			SQL_GetError(g_hDB, error, sizeof(error));
			if(IsClientInGame(param1))
				PrintToChat(param1, "\x04[Team Filter]\x01 Quesy failed. error : %s!", error);
			return;
		}
		if (g_Enabled)
		{
			Format(query, sizeof(query), "SELECT Team FROM player_team WHERE SteamID = '%s'", SteamID);
			new String:currentSteamID[32];
			new client = 0;
			for(new i = 1; i <= MaxClients; ++i)
			{
				if(IsClientAuthorized(i))
				{
					GetClientAuthString(i, currentSteamID, sizeof(currentSteamID));
					if (!strcmp(currentSteamID, SteamID))
					{
						client = i;
						break;
					}
				}
			}
			SQL_TQuery(g_hDB, T_CheckSteamID, query, GetClientUserId(client));
		}
		PrintToChatAll("\x04[Team Filter]\x01 Player \x04%s\x01 has been deleted from \x04%s\x01 team", Name, Team);
		PrintToServer("[Team Filter] Player %s has been deleted from %s team by %N", Name, Team, param1);
	}

	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


public Action:Command_MyTeam(client, args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "\x04[Team Filter]\x01 Only ingame command!");
	}
	else
	{
		if(IsClientInGame(client))
		{
			decl String:query[255];
			decl String:SteamID[32];
			GetClientAuthString(client, SteamID, sizeof(SteamID));
			Format(query, sizeof(query), "SELECT Team, Name FROM player_team WHERE SteamID = '%s'", SteamID);
			SQL_TQuery(g_hDB, MyTeamCallback, query, GetClientUserId(client));
		}
	}
}

public MyTeamCallback(Handle:owner, Handle:query, const String:error[], any:data)
{
	new client = GetClientOfUserId(data);
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}
 
	if (query == INVALID_HANDLE)
	{
		LogError("[TeamFilter] Query failed! %s", error);
		PrintToChat(client, "\x04[Team Filter]\x01 Failed to fetch MyTeam list!");
	} 
	else if (!SQL_GetRowCount(query)) 
	{
		PrintToChat(client, "\x04[Team Filter]\x01 You are not registered in any team!");
	}
	else
	{
		new String:team[11];
		new String:name[128];
		decl String:entry[256];
		new Handle:menu = CreateMenu(MenuHandler_List);
		SetMenuTitle(menu, "You are a member of");
		while (SQL_FetchRow(query))
		{
			SQL_FetchString(query, 0, team, sizeof(team));
			SQL_FetchString(query, 1, name, sizeof(name));
			
			Format(entry, sizeof(entry), "[%s] %s", team, name);
			AddMenuItem(menu, "", entry);
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
}

public DeleteCallback(Handle:owner, Handle:query, const String:error[], any:data)
{
	new client = GetClientOfUserId(GetArrayCell(data, 1));
	new String:team[11];
	GetArrayString(data, 0, team, sizeof(team));
	ClearArray(data);
	CloseHandle(data);
	
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}
 
	if (query == INVALID_HANDLE)
	{
		LogError("[TeamFilter] Query failed! %s", error);
		PrintToChat(client, "\x04[Team Filter]\x01 Failed to fetch %s members list!", team);
	} 
	else if (!SQL_GetRowCount(query)) 
	{
		PrintToChat(client, "\x04[Team Filter]\x01 Specified team has no members!");
	}
	else
	{
		new String:name[128];
		new String:steamid[32];
		new Handle:menu = CreateMenu(MenuHandler_Delete);
		SetMenuTitle(menu, team);
		while (SQL_FetchRow(query))
		{
			SQL_FetchString(query, 0, steamid, sizeof(steamid));
			SQL_FetchString(query, 1, name, sizeof(name));
			
			AddMenuItem(menu, steamid, name);
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
}