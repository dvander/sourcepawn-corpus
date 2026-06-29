#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo =
{
	name = "[CSGO] Team Details",
	author = "Cruze",
	description = "Shows Team Details in menu",
	version = "1.0",
	url = "http://steamcommunity.com/profiles/76561198132924835"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_teamdetails", Command_TeamDetails, "Command to see Team Details");
	RegConsoleCmd("sm_td", Command_TeamDetails, "Command to see Team Details");
	RegConsoleCmd("sm_teamdetail", Command_TeamDetails, "Command to see Team Details");
}

public Action Command_TeamDetails(int client, int args)
{
	Menu menu = new Menu(Handle_DetailsMenu);
	menu.SetTitle("----------TEAM DETAILS----------");
	menu.AddItem("", "Cash Info");
	menu.AddItem("", "Weapons Info");
	menu.ExitButton = true;
	menu.Display(client, 30);
	return Plugin_Handled;
}   

public int Handle_DetailsMenu(Menu menu, MenuAction action, int client, int selection)   
{
	if(action == MenuAction_Select)
	{
		if(selection == 0)
		{
			CashInfo(client);
		}
		else if(selection == 1)
		{
			WeaponsInfo(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

public int Handle_BackMenu(Menu menu, MenuAction action, int client, int selection)   
{
	if(action == MenuAction_End)
	{
		delete menu;
	}
	else if(action == MenuAction_Cancel)
	{
		if(selection == MenuCancel_ExitBack)
		{
			Command_TeamDetails(client, 0);
		}
	}
}

void CashInfo(int client)
{
	int count = 0;
	char buffer[64];
	Menu menu = new Menu(Handle_BackMenu);
	menu.SetTitle("----------CASH INFO----------");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && i != client)
		{
			bool dead = IsPlayerAlive(i);
			int cash = GetEntProp(i, Prop_Send, "m_iAccount");
			Format(buffer, sizeof(buffer), "%N : %d%s", i, cash, !dead ? " (dead)":"");
			menu.AddItem("", buffer, ITEMDRAW_DISABLED);
			count++;
		}
	}
	if(!count)
	{
		menu.AddItem("", "You don't have any teammates.", ITEMDRAW_DISABLED);
	}
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, 30);
}
void WeaponsInfo(int client)
{
	int count = 0;
	char buffer[64];
	Menu menu = new Menu(Handle_BackMenu);
	menu.SetTitle("----------WEAPONS INFO----------");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && i != client)
		{
			bool dead = IsPlayerAlive(i);
			char PrimaryWep[64] = "none", SecondaryWep[64] = "none";
			if(GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY) && IsValidEntity(GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY)))
			{
				GetEntityClassname(GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY), PrimaryWep, sizeof(PrimaryWep));
			}
			if(GetPlayerWeaponSlot(i, CS_SLOT_SECONDARY) && IsValidEntity(GetPlayerWeaponSlot(i, CS_SLOT_SECONDARY)))
			{
				GetEntityClassname(GetPlayerWeaponSlot(i, CS_SLOT_SECONDARY), SecondaryWep, sizeof(SecondaryWep));
			}
			if(!StrEqual(PrimaryWep, "none", false) && !StrEqual(SecondaryWep, "none", false))
			{
				UppercaseALetterInString(PrimaryWep, 7);
				UppercaseALetterInString(SecondaryWep, 7);
				Format(buffer, sizeof(buffer), "%N : %s - %s", i, PrimaryWep[7], SecondaryWep[7]);
			}
			else if(StrEqual(PrimaryWep, "none", false) && !StrEqual(SecondaryWep, "none", false))
			{
				UppercaseALetterInString(SecondaryWep, 7);
				Format(buffer, sizeof(buffer), "%N : %s - %s", i, PrimaryWep, SecondaryWep[7]);
			}
			else if(!StrEqual(PrimaryWep, "none", false) && StrEqual(SecondaryWep, "none", false))
			{
				UppercaseALetterInString(PrimaryWep, 7);
				Format(buffer, sizeof(buffer), "%N : %s - %s", i, PrimaryWep[7], SecondaryWep);
			}
			else if(StrEqual(PrimaryWep, "none", false) && StrEqual(SecondaryWep, "none", false))
			{
				Format(buffer, sizeof(buffer), "%N : %s - %s%s", i, PrimaryWep, SecondaryWep, !dead ? " (dead)":"");
			}
			menu.AddItem("", buffer, ITEMDRAW_DISABLED);
			count++;
		}
	}
	if(!count)
	{
		menu.AddItem("", "You don't have any teammates.", ITEMDRAW_DISABLED);
	}
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

void UppercaseALetterInString(char[] sWeapon, int num)
{
	if(sWeapon[num] == 'a')
	{
		sWeapon[num] = 'A';
	}
	else if(sWeapon[num] == 'b')
	{
		sWeapon[num] = 'B';
	}
	else if(sWeapon[num] == 'c')
	{
		sWeapon[num] = 'C';
	}
	else if(sWeapon[num] == 'd')
	{
		sWeapon[num] = 'D';
	}
	else if(sWeapon[num] == 'e')
	{
		sWeapon[num] = 'E';
	}
	else if(sWeapon[num] == 'f')
	{
		sWeapon[num] = 'F';
	}
	else if(sWeapon[num] == 'g')
	{
		sWeapon[num] = 'G';
	}
	else if(sWeapon[num] == 'h')
	{
		sWeapon[num] = 'H';
	}
	else if(sWeapon[num] == 'i')
	{
		sWeapon[num] = 'I';
	}
	else if(sWeapon[num] == 'j')
	{
		sWeapon[num] = 'J';
	}
	else if(sWeapon[num] == 'k')
	{
		sWeapon[num] = 'K';
	}
	else if(sWeapon[num] == 'l')
	{
		sWeapon[num] = 'L';
	}
	else if(sWeapon[num] == 'm')
	{
		sWeapon[num] = 'M';
	}
	else if(sWeapon[num] == 'n')
	{
		sWeapon[num] = 'N';
	}
	else if(sWeapon[num] == 'o')
	{
		sWeapon[num] = 'O';
	}
	else if(sWeapon[num] == 'p')
	{
		sWeapon[num] = 'P';
	}
	else if(sWeapon[num] == 'q')
	{
		sWeapon[num] = 'Q';
	}
	else if(sWeapon[num] == 'r')
	{
		sWeapon[num] = 'R';
	}
	else if(sWeapon[num] == 's')
	{
		sWeapon[num] = 'S';
	}
	else if(sWeapon[num] == 't')
	{
		sWeapon[num] = 'T';
	}
	else if(sWeapon[num] == 'u')
	{
		sWeapon[num] = 'U';
	}
	else if(sWeapon[num] == 'v')
	{
		sWeapon[num] = 'V';
	}
	else if(sWeapon[num] == 'w')
	{
		sWeapon[num] = 'W';
	}
	else if(sWeapon[num] == 'x')
	{
		sWeapon[num] = 'X';
	}
	else if(sWeapon[num] == 'y')
	{
		sWeapon[num] = 'Y';
	}
	else if(sWeapon[num] == 'z')
	{
		sWeapon[num] = 'Z';
	}
	strcopy(sWeapon, 64, sWeapon);
}

/*
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon && IsValidEntity(weapon))
	{
		char className[48];
		GetEntityClassname(weapon, className, sizeof(className));
	}
*/