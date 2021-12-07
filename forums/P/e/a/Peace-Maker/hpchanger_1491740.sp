#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "HP Changer",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Admins can set the health of all players via menu",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_hpchanger_version", PLUGIN_VERSION, "HP Changer version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	RegAdminCmd("sm_changehp", Cmd_ChangeHP, ADMFLAG_SLAY, "Opens a menu with different options to set all players health to.");
}

public Action:Cmd_ChangeHP(client, args)
{
	new Handle:hMenu = CreateMenu(Menu_SelectHP);
	SetMenuTitle(hMenu, "Set all alive player's HP to...");
	SetMenuExitButton(hMenu, true);
	
	AddMenuItem(hMenu, "100", "100 HP");
	AddMenuItem(hMenu, "75", "75 HP");
	AddMenuItem(hMenu, "50", "50 HP");
	AddMenuItem(hMenu, "25", "25 HP");
	AddMenuItem(hMenu, "1", "1 HP");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Menu_SelectHP(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new iHP = StringToInt(info);
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) >= 2)
				SetEntityHealth(i, iHP);
		}
		
		PrintToChatAll("HP Changer: %N set all players to %d HP.", param1, iHP);
		LogAction(param1, -1, "Admin set all players to %d HP.", iHP);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}