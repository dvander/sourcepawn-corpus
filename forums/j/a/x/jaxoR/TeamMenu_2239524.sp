#include <sourcemod>
#include <sdktools>

new select_team;

public Plugin:myinfo =
{
	name = "TeamMenu",
	author = "jaxoR",
	description = "Easy plugin for change client teams.",
	version = "1.1",
	url = "http://www.amxmodx-es.com"
};

public OnPluginStart()
{
	RegAdminCmd("sm_teammenu", Command_Team, ADMFLAG_SLAY);
	RegAdminCmd("sm_teammenu_all", Command_Team_All, ADMFLAG_SLAY);
}

public Action:Command_Team_All(client, args)
{
	new String:arg1[32];
	new select;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (args >= 1)
	{
		select = StringToInt(arg1);
	}
	
	if((select == 1) || (select == 2) || (select == 3))
	{
		for(new i=1; i <= MaxClients; i++) 
		{
			if(IsClientInGame(i) && IsClientConnected(i) && (GetClientTeam(i) != select)) 
			{
				ChangeClientTeam(i, select);
				
			}
		}
		
		return Plugin_Handled;
	}
	else
	{
		PrintToConsole(client, "[TeamMenu] Team Erroneo");
		return Plugin_Handled;
	}
}

public Action:Command_Team(client, args)
{
	new String:arg1[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (args >= 1)
	{
		select_team = StringToInt(arg1);
	}
	
	if((select_team == 1) || (select_team == 2) || (select_team == 3))
	{
	
		Menu menu = new Menu(MenuTeam);
		menu.SetTitle("[TeamMenu] Players");
	
		new String:player[32];
		for(new i=1; i <= MaxClients; i++) 
		{
			if(IsClientInGame(i) && IsClientConnected(i) && (GetClientTeam(i) != select_team)) 
			{
				GetClientName(i, player, sizeof(player));
				menu.AddItem(player, player);	
			}
		}
	
		menu.ExitButton = true;
		menu.Display(client, 20);
	
		return Plugin_Handled;
	}
	else
	{
		PrintToConsole(client, "[TeamMenu] Team Erroneo");
		return Plugin_Handled;
	}
}

public int MenuTeam(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];

		menu.GetItem(param2, info, sizeof(info));
		
		new user = FindTarget(0, info);
		ChangeClientTeam(user, select_team);
		Command_Team(param1, select_team);
	}
	else if (action == MenuAction_Cancel)
	{

	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}