#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart()
{
	RegConsoleCmd("sm_teams", Command_TeamsPanel, "Show Team Panel");
	RegConsoleCmd("sm_team", Command_TeamsPanel, "Show Team Panel");
}

Action Command_TeamsPanel(int client, int args)
{
	Create_ShowTeamsPanel(client);
	return Plugin_Handled;
}

void Create_ShowTeamsPanel(int client)
{
	Panel panel = new Panel();
	
	static char sID [12];
	static char sName [MAX_NAME_LENGTH];
	
	panel.DrawItem("Spectator Team");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		else if (GetClientTeam(i) == 1)
		{
			GetClientName(i, sName, sizeof(sName));
			Format(sID, sizeof(sID), "%s", GetClientUserId(i));
			panel.DrawItem(sName, ITEMDRAW_RAWLINE);
		}
	}
	
	panel.DrawItem("Survivors Team");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		else if (GetClientTeam(i) == 2)
		{
			GetClientName(i, sName, sizeof(sName));
			Format(sID, sizeof(sID), "%s", GetClientUserId(i));
			panel.DrawItem(sName, ITEMDRAW_RAWLINE);
		}
	}
	
	panel.DrawItem("Infected Team");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		else if (GetClientTeam(i) == 3)
		{
			GetClientName(i, sName, sizeof(sName));
			Format(sID, sizeof(sID), "%s", GetClientUserId(i));
			panel.DrawItem(sName, ITEMDRAW_RAWLINE);
		}
	}
	panel.Send(client, HandleShowTeamsPanel, MENU_TIME_FOREVER);
	delete panel;
}

int HandleShowTeamsPanel(Menu menu, MenuAction action, int client, int selectedIndex)
{
	switch(action) 
	{
		case MenuAction_End: 
		{
			delete menu;
		}
	}
	return 0;
}