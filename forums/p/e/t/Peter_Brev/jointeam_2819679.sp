/******************************
INCLUDE ALL THE NECESSARY FILES
******************************/

#include <sourcemod>
#include <sdktools>

/******************************
COMPILE OPTIONS
******************************/

#pragma semicolon 1

/******************************
PLUGIN DEFINES
******************************/

/*Plugin Info*/
#define PLUGIN_NAME		   "HL2MP - Jointeam"
#define PLUGIN_AUTHOR	   "Peter Brev"
#define PLUGIN_VERSION	   "1.0"
#define PLUGIN_DESCRIPTION "Allows players to join a new team"
#define PLUGIN_URL		   ""

/******************************
PLUGIN INFO BASED ON PREVIOUS DEFINES
******************************/
public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url			= PLUGIN_URL,
};

ConVar g_cTeamplay;

/******************************
INITIATE THE PLUGIN
******************************/
public void OnPluginStart()
{
	g_cTeamplay = FindConVar("mp_teamplay");

	/***REGISTER COMMANDS***/

	RegConsoleCmd("sm_spectate", Command_Spectate, "Sends player to spectate");
	RegConsoleCmd("sm_spec", Command_Spectate, "Sends player to spectate");
	RegConsoleCmd("sm_rebels", Command_Rebels, "Sends player to Rebels");
	RegConsoleCmd("sm_combine", Command_Combine, "Sends player to Combine");
	RegConsoleCmd("sm_teams", Command_Jointeam, "Jointeam Menu");
	RegConsoleCmd("sm_switch", Command_Jointeam, "Jointeam Menu");
}

public Action Command_Spectate(int client, int args)
{
	int teams;
	teams = GetClientTeam(client);
	if (teams != 1)
	{
		ClientCommand(client, "jointeam 1");
		return Plugin_Handled;
	}

	PrintToChat(client, "[SM] You are already a spectator.");
	return Plugin_Handled;
}

public Action Command_Rebels(int client, int args)
{
	int teams;
	teams = GetClientTeam(client);
	if (GetConVarInt(g_cTeamplay) == 1)
	{
		if (teams != 3)
		{
			ClientCommand(client, "jointeam 3");
			return Plugin_Handled;
		}

		else
		{
			PrintToChat(client, "[SM] You are already on team Rebels.");
			return Plugin_Handled;
		}
	}

	else
	{
		if (teams != 0)
		{
			ClientCommand(client, "jointeam 3");
			return Plugin_Handled;
		}

		else
		{
			PrintToChat(client, "[SM] You are already on team Players.");
			return Plugin_Handled;
		}
	}
}

public Action Command_Combine(int client, int args)
{
	int teams;
	teams = GetClientTeam(client);
	if (GetConVarInt(g_cTeamplay) == 1)
	{
		if (teams != 2)
		{
			ClientCommand(client, "jointeam 2");
			return Plugin_Handled;
		}

		else
		{
			PrintToChat(client, "[SM] You are already on team Combine.");
			return Plugin_Handled;
		}
	}

	else
	{
		if (teams != 0)
		{
			ClientCommand(client, "jointeam 2");
			return Plugin_Handled;
		}

		else
		{
			PrintToChat(client, "[SM] You are already on team Players.");
			return Plugin_Handled;
		}
	}
}

public Action Command_Jointeam(int client, int args)
{
	PrintToChat(client, "[SM] Press your escape key to choose a team from the menu.");
	new Handle: menuhandle = CreateMenu(MenuCallBack);
	SetMenuTitle(menuhandle, "Choose Team");
	AddMenuItem(menuhandle, "spectate", "Spectate");
	AddMenuItem(menuhandle, "jointeam2", "Combine");
	AddMenuItem(menuhandle, "jointeam3", "Rebels");
	SetMenuPagination(menuhandle, MENU_NO_PAGINATION);
	SetMenuExitButton(menuhandle, true);
	DisplayMenu(menuhandle, client, 20);
	return Plugin_Handled;
}

public MenuCallBack(Handle: menuhandle, MenuAction: action, Client, Position)
{
	if (action == MenuAction_Select)
	{
		char Item[20];
		GetMenuItem(menuhandle, Position, Item, sizeof(Item));

		if (StrEqual(Item, "spectate"))
		{
			int teams;
			teams = GetClientTeam(Client);
			if (teams != 1)
			{
				ClientCommand(Client, "jointeam 1");
			}

			PrintToChat(Client, "[SM] You are already a spectator.");
		}
		else if (StrEqual(Item, "jointeam2"))
		{
			int teams;
			teams = GetClientTeam(Client);
			if (GetConVarInt(g_cTeamplay) == 1)
			{
				if (teams != 2)
				{
					ClientCommand(Client, "jointeam 2");
				}

				else
				{
					PrintToChat(Client, "[SM] You are already on team Combine.");
				}
			}

			else
			{
				if (teams != 0)
				{
					ClientCommand(Client, "jointeam 2");
				}

				else
				{
					PrintToChat(Client, "[SM] You are already on team Players.");
				}
			}
		}
		else if (StrEqual(Item, "jointeam3"))
		{
			int teams;
			teams = GetClientTeam(Client);
			if (GetConVarInt(g_cTeamplay) == 1)
			{
				if (teams != 3)
				{
					ClientCommand(Client, "jointeam 3");
				}

				else
				{
					PrintToChat(Client, "[SM] You are already on team Rebels.");
				}
			}

			else
			{
				if (teams != 0)
				{
					ClientCommand(Client, "jointeam 3");
				}

				else
				{
					PrintToChat(Client, "[SM] You are already on team Players.");
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuhandle);
	}
}