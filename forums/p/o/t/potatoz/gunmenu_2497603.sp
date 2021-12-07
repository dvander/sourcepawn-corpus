/*                                                        
 * 		    Copyright (C) 2018 Adam "Potatoz" Ericsson
 * 
 * 	This program is free software: you can redistribute it and/or modify it
 * 	under the terms of the GNU General Public License as published by the Free
 * 	Software Foundation, either version 3 of the License, or (at your option) 
 * 	any later version.
 *
 * 	This program is distributed in the hope that it will be useful, but WITHOUT 
 * 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * 	FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * 	See http://www.gnu.org/licenses/. for more information
 */

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

bool GiveAWPCT = true,
	GiveAWPT = true;
int PrimaryChoice[MAXPLAYERS+1],
	SecondaryChoice[MAXPLAYERS+1],
	AwpChoice[MAXPLAYERS+1];
Menu g_PrimaryMenu,
	g_SecondaryMenu,
	g_AwpMenu;

public Plugin myinfo =
{
	name = "Gun Menu",
	author = "Potatoz",
	description = "Gun Menu for gamemodes such as Retake, Deathmatch etc.",
	version = "1.1",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	g_PrimaryMenu = BuildPrimaryMenu();
	g_SecondaryMenu = BuildSecondaryMenu();
	g_AwpMenu = BuildAwpMenu();

	RegConsoleCmd("sm_guns", Menu_PrimaryWeapon);
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy); 
	HookEvent("player_spawn",SpawnEvent);
} 

Menu BuildPrimaryMenu()
{
	Menu menu = new Menu(MenuHandler1);

	menu.SetTitle("Choose Primary Weapon:");
	menu.AddItem("1", "M4A4 / AK-47");
	menu.AddItem("2", "M4A1-S / AK-47");
	menu.AddItem("3", "Galil AR / Famas");
	menu.AddItem("4", "UMP-45");
	menu.AddItem("5", "SSG-08");

	return menu;
}

public Action Menu_PrimaryWeapon(int client, int args)
{
	g_PrimaryMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		PrimaryChoice[param1] = param2;
		g_SecondaryMenu.Display(param1, MENU_TIME_FOREVER);
	}
}

Menu BuildSecondaryMenu()
{
	Menu menu = new Menu(MenuHandler2);

	menu.SetTitle("Choose Secondary Weapon:");
	menu.AddItem("1", "P2000 / Glock");
	menu.AddItem("2", "USP-S / Glock");
	menu.AddItem("3", "Dual Berettas");
	menu.AddItem("4", "P250");
	menu.AddItem("5", "Tec-9 / Five-SeveN");
	menu.AddItem("6", "Deagle");

	return menu;
}

public Action Menu_SecondaryWeapon(int client, int args)
{
	g_SecondaryMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuHandler2(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		SecondaryChoice[param1] = param2;
		g_AwpMenu.Display(param1, MENU_TIME_FOREVER);
	}
}

Menu BuildAwpMenu()
{
	Menu menu = new Menu(MenuHandler3);

	menu.SetTitle("Allow yourself to recieve AWP?");
	menu.AddItem("1", "Yes");
	menu.AddItem("2", "No");

	return menu;
}

public Action Menu_AwpChoice(int client, int args)
{
	g_AwpMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuHandler3(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
		AwpChoice[param1] = param2;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
}

public void Hook_PostThinkPost(int entity)
{
	SetEntProp(entity, Prop_Send, "m_bInBuyZone", 0);
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	GiveAWPCT = GiveAWPT = true;
}

public void SpawnEvent(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, GiveEquipment, GetClientOfUserId(event.GetInt("userid")), TIMER_FLAG_NO_MAPCHANGE);
}

public Action GiveEquipment(Handle timer, any client)
{
	if(IsValidClient(client))
	{
		RemoveAllWeapons(client);
		switch(PrimaryChoice[client])
		{
			case 0:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_ak47");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_m4a1");
				}
			}
			case 1:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_ak47");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_m4a1_silencer");
				}
			}
			case 2:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_galilar");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_famas");
				}
			}
			case 3:	GivePlayerItem(client, "weapon_ump45");
			case 4:	GivePlayerItem(client, "weapon_ssg08");
		}
		
		switch(AwpChoice[client])
		{
			case 0:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:
					{
						if(GiveAWPT)
						{
							GiveAWPT = false;
							RemoveAllWeapons(client);
							GivePlayerItem(client, "weapon_awp");
						}
						else
						{
							PrintToChat(client, " \x07* AWP is limited to 1 player in each team per round.");
							PrintToChat(client, " \x07* You have been given your default loadout.");
						}
					}
					case CS_TEAM_CT:
					{
						if(GiveAWPCT)
						{
							GiveAWPCT = false;
							RemoveAllWeapons(client);
							GivePlayerItem(client, "weapon_awp");
						}
						else
						{
							PrintToChat(client, " \x07* AWP is limited to 1 player in each team per round.");
							PrintToChat(client, " \x07* You have been given your default loadout.");
						}
					}
				}
			}
		}

		switch(SecondaryChoice[client])
		{
			case 0:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_glock");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_hkp2000");
				}
			}
			case 1:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_glock");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_usp_silencer");
				}
			}
			case 2:	GivePlayerItem(client, "weapon_elite");
			case 3:	GivePlayerItem(client, "weapon_p250");
			case 4:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_tec9");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_fiveseven");
				}
			}
			case 5:	GivePlayerItem(client, "weapon_deagle");
		}

		switch(GetRandomInt(0, 10))
		{
			case 2:	GivePlayerItem(client, "weapon_hegrenade");
			case 9:	GivePlayerItem(client, "weapon_smokegrenade");
		}
		
		switch(GetRandomInt(0, 1))
		{
			case 1:	GivePlayerItem(client, "weapon_flashbang");
		}

		GivePlayerItem(client, "weapon_knife");
		GivePlayerItem(client, "item_assaultsuit");
	}
}

void RemoveAllWeapons(int client)
{
	if(IsValidClient(client))
	{
		int ent;
		for(int i; i < 4; i++)
		{
			if((ent = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, ent);
				RemoveEdict(ent);
			}
		}
	}
}

bool IsValidClient(int client)
{
	return (0 < client <= MaxClients && IsClientInGame(client));
}