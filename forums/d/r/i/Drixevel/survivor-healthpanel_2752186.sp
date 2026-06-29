/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[L4D/L4D2] Survivor Health Panel"
#define PLUGIN_DESCRIPTION "Adds a command to show the survivors health through a panel."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>

/*****************************/
//ConVars

ConVar convar_Status;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	convar_Status = CreateConVar("sm_healthpanel_status", "1", "Should the plugin be enabled or disabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_healthpanel", Command_HealthPanel, "Displays the survivors health panel.");
}

public Action Command_HealthPanel(int client, int args)
{
	if (!convar_Status.BoolValue)
		return Plugin_Handled;
		
	if (client == 0)
		return Plugin_Handled;
	
	OpenHealthPanel(client);
	return Plugin_Handled;
}

void OpenHealthPanel(int client)
{
	Panel panel = new Panel();
	panel.SetTitle("Current health for Survivors:");
	
	char sDisplay[256]; char sSurvivor[32];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		
		GetPlayerSurvivorName(i, sSurvivor, sizeof(sSurvivor));
		
		if (IsPlayerAlive(i))
			FormatEx(sDisplay, sizeof(sDisplay), "(%s) %N (%i Health)", sSurvivor, i, GetClientHealth(i));
		else
			FormatEx(sDisplay, sizeof(sDisplay), "(%s) %N (Dead)", sSurvivor, i);
		
		panel.DrawText(sDisplay);
	}
	
	panel.DrawItem("Exit");
	
	panel.Send(client, PanelHandler_Void, MENU_TIME_FOREVER);
	delete panel;
}

public int PanelHandler_Void(Menu menu, MenuAction action, int param1, int param2)
{
	//Do Nothing Here.
}

void GetPlayerSurvivorName(int client, char[] buffer, int size)
{
	int survivor = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		switch (survivor)
		{
			case 0: strcopy(buffer, size, "Nick");
			case 1: strcopy(buffer, size, "Rochelle");
			case 2: strcopy(buffer, size, "Coach");
			case 3: strcopy(buffer, size, "Ellis");
			case 4: strcopy(buffer, size, "Bill");
			case 5: strcopy(buffer, size, "Zoey");
			case 6: strcopy(buffer, size, "Francis");
			case 7: strcopy(buffer, size, "Louis");
		}
	}
	else
	{
		switch (survivor)
		{
			case 0: strcopy(buffer, size, "Bill");
			case 1: strcopy(buffer, size, "Zoey");
			case 2: strcopy(buffer, size, "Francis");
			case 3: strcopy(buffer, size, "Louis");
		}
	}
}