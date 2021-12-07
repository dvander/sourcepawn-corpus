#include <sourcemod>
#include <sdktools>
#include <colors>
#include <menus>

#define L4D_TEAM_SPECTATOR 1
#define L4D_TEAM_INFECTED 3
#define L4D_TEAM_SURVIVOR 2
#define L4D_MAXPLAYERS 14
#define DEBUG 0

new bool:TeamSuccess = false;

public Plugin:myinfo =
{
	name = "idle",
	author = "gamemann",
	description = "you can type !idle into the chatbox and you become idle",
	version = "1.0",
	url = "sourcemod.net",
};

public OnPluginStart()
{
	//events
	HookEvent("round_start", RoundStart);

	//convars
	CreateConVar("sm_plugin_version", "1.0", "plugins version", 	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	//events

	//commands
	RegConsoleCmd("sm_idle", CmdIdle);
	RegConsoleCmd("sm_infected", CmdInfectedTeam);
	RegConsoleCmd("sm_survivor", CmdSurvivorTeam);
	RegConsoleCmd("sm_joingame", CmdJoinGame);
	RegConsoleCmd("sm_idledetails", CmdDetails);
	RegConsoleCmd("sm_teamsmenu", CmdMenu);
}

public Action:CmdJoinGame(client, args)
{
	LogAction(0, -1, "DEBUG:addplayer");
	if(IsClientInGame(client))
	{
		TeamSuccess = true;
		FakeClientCommand(client, "jointeam 2");
		ChangeClientTeam(client, L4D_TEAM_SURVIVOR);
		PrintToChat(client, "you have joined the game which is survivors");
	}
	if(TeamSuccess == false)
	{
		PrintToChat(client, "joined team: unsuccessful");
	}
	return Plugin_Handled;
}

public Action:CmdSurvivorTeam(client, args)
{
	LogAction(0, -1, "DEBUG:addplayer");
	if(IsClientInGame(client))
	{ 
		TeamSuccess = true;
		ChangeClientTeam(client, L4D_TEAM_SURVIVOR);
		FakeClientCommand(client, "jointeam 2");
		PrintToChat(client, "you have joined the survivor team");
	}
	if(TeamSuccess == false)
	{
		PrintToChat(client, "joined team: unsuccessful");
	}
	return Plugin_Handled;
}

public Action:CmdInfectedTeam(client, args)
{
	LogAction(0, -1, "DEBUG:addplayer");
	if(IsClientInGame(client))
	{
		TeamSuccess = true;
		ChangeClientTeam(client, L4D_TEAM_INFECTED);
		FakeClientCommand(client, "jointeam 3");
		PrintToChat(client, "you have joined the infected team");
	}
	if(TeamSuccess == false)
	{
		PrintToChat(client, "joined team: unsuccessful");
	}
	return Plugin_Handled;
}

public Action:CmdIdle(client, args)
{
	TeamSuccess = true;
	ChangeClientTeam(client, L4D_TEAM_SPECTATOR);
	FakeClientCommand(client, "jointeam 1");
	CPrintToChatAll("{green}you have joined the specator day");
	if(TeamSuccess == false)
	{
		PrintToChat(client, "joined team: unsuccessful");
	}
	return Plugin_Handled;
}


//now for the teaming part now!!! It is cool

public OnClientPutInServer(client)
{
	new Handle:menu = CreateMenu(L4d2TeamsMenu);
	SetMenuTitle(menu, "l4d2 teams menu!!");
	AddMenuItem(menu, "option0", "survivor");
	AddMenuItem(menu, "option1", "infected");
	AddMenuItem(menu, "option3", "spectator");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	//RETURN PLUGIN_HANDLE;
}

public L4d2TeamsMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("jointeam");
	SetCommandFlags("jointeam", flags & ~FCVAR_CHEAT);
	if(action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: //survivor team
			{
				LogAction(0, -1, "DEBUG:addplayer");
				if(IsClientInGame(client))
				{
					TeamSuccess = true;
					ChangeClientTeam(client, L4D_TEAM_SURVIVOR);
					FakeClientCommand(client, "jointeam 2");
					PrintToChat(client, "you have joined the infected team");
				}
				if(TeamSuccess == false)
				{
					PrintToChat(client, "joined team: unsuccessful");
				}
			
			}
			case 1: //infected team
			{
				LogAction(0, -1, "DEBUG:addplayer");
				if(IsClientInGame(client))
				{
					TeamSuccess = true;
					ChangeClientTeam(client, L4D_TEAM_INFECTED);
					FakeClientCommand(client, "jointeam 1");
					PrintToChat(client, "you have joined the infected team");
				}
				if(TeamSuccess == false)
				{
					PrintToChat(client, "joined team: unsuccessful");
				}
			}
			case 2: //spectator team
			{
				TeamSuccess = true;
				ChangeClientTeam(client, L4D_TEAM_SPECTATOR);
				FakeClientCommand(client, "jointeam 3");
				CPrintToChatAll("{green}you have joined the specator day");
				if(TeamSuccess == false)
				{
					PrintToChat(client, "joined team: unsuccessful");
				}
			}
		}
	}
}

//messaging part like PrintToChat
/* print to chat all == create
print to chat == create
print to all == false
print hint text == create
print to chat text == false&true
*/

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= GetMaxClients(); i++)
		if (IsClientInGame(i))
	{
		PrintHintText(i, "type in the chat !idledetails to find out about teams");
	}
}

public Action:CmdDetails(client, args)
{
	for (new i = 1; i <= GetMaxClients(); i++)
		if (IsClientInGame(i))
	{
		PrintToChat(client, "if you type in the chatbox !idle and !infected !survivor and !teamsmenu for more things!!! to pick which side you want to play on");
		PrintHintText(i, "check your chatbox for the details!!!");
	}
}

public Action:CmdMenu(client, args)
{
	new Handle:menu = CreateMenu(L4d2TeamsMenuMenu);
	SetMenuTitle(menu, "l4d2 teams menu!!");
	AddMenuItem(menu, "option0", "survivor");
	AddMenuItem(menu, "option1", "infected");
	AddMenuItem(menu, "option3", "spectator");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	//RETURN PLUGIN_HANDLE;
}

public L4d2TeamsMenuMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("jointeam");
	SetCommandFlags("jointeam", flags & ~FCVAR_CHEAT);
	if(action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: //survivor team
			{
				LogAction(0, -1, "DEBUG:addplayer");
				if(IsClientInGame(client))
				{ 
					TeamSuccess = true;
					ChangeClientTeam(client, L4D_TEAM_SURVIVOR);
					FakeClientCommand(client, "jointeam 2");
					PrintToChat(client, "you have joined the survivor team");
				}
				if(TeamSuccess == false)
				{
					PrintToChat(client, "joined team: unsuccessful");
				}
			}
			case 1: //infected team
			{
				LogAction(0, -1, "DEBUG:addplayer");
				if(IsClientInGame(client))
				{
					TeamSuccess = true;
					ChangeClientTeam(client, L4D_TEAM_INFECTED);
					FakeClientCommand(client, "jointeam 1");
					PrintToChat(client, "you have joined the infected team");
				}
				if(TeamSuccess == false)
				{
					PrintToChat(client, "joined team: unsuccessful");
				}
			}
			case 2: //spectator team
			{
				TeamSuccess = true;
				ChangeClientTeam(client, L4D_TEAM_SPECTATOR);
				FakeClientCommand(client, "jointeam 3");
				CPrintToChatAll("{green}you have joined the specator day");
				if(TeamSuccess == false)
				{
					PrintToChat(client, "joined team: unsuccessful");
				}
			}
		}
	}
}







			
			

				
