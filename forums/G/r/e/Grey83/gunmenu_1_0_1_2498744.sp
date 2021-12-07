#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sdkhooks>
#include <sdktools>

bool GiveAWPCT = true,
	GiveAWPT = true;
int PrimaryChoice[MAXPLAYERS+1],
	SecondaryChoice[MAXPLAYERS+1];
Menu g_PrimaryMenu,
	g_SecondaryMenu;

public Plugin myinfo =
{
	name		= "Gun Menu",
	author		= "Potatoz (rewritten by Grey83)",
	description	= "Gun Menu for gamemodes such as Retake, Deathmatch etc.",
	version		= "1.0.1",
	url			= "https://forums.alliedmods.net/showthread.php?t=294225"
};

public void OnPluginStart()
{
	g_PrimaryMenu	= BuildPrimaryMenu();
	g_SecondaryMenu	= BuildSecondaryMenu();

	RegConsoleCmd("sm_guns", Menu_PrimaryWeapon);

	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn",SpawnEvent);
}

Menu BuildPrimaryMenu()
{
	Menu menu = new Menu(MenuHandler1);

	menu.SetTitle("Choose Primary Weapon:");
	menu.AddItem("1", "AK-47 / M4A4");
	menu.AddItem("2", "AK-47 / M4A1-S");
	menu.AddItem("3", "Galil AR / Famas");
	menu.AddItem("4", "SSG-08");
	menu.AddItem("5", "AWP");
	menu.AddItem("6", "P90");
	menu.AddItem("7", "MAC-10 / MP9");

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
	menu.AddItem("1", "Glock/P2000");
	menu.AddItem("2", "Glock/USP-S");
	menu.AddItem("3", "Dual Berettas");
	menu.AddItem("4", "P250");
	menu.AddItem("5", "Tec-9 / Five-SeveN");
	menu.AddItem("6", "Desert Eagle");

	return menu;
}

public Action Menu_SecondaryWeapon(int client, int args)
{
	g_SecondaryMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuHandler2(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select) SecondaryChoice[param1] = param2;
}

public void OnClientPutInServer(int client)
{
	PrimaryChoice[client] = SecondaryChoice[client] = 0;
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
			case 3:	GivePlayerItem(client, "weapon_ssg08");
			case 4:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:
					{
						if(GiveAWPT)
						{
							GiveAWPT = false;
							GivePlayerItem(client, "weapon_awp");
						}
						else
						{
							GivePlayerItem(client, "weapon_ak47");
							PrintToChat(client, " \x07* AWP is limited to 1 player in each team per round.");
						}
					}
					case CS_TEAM_CT:
					{
						if(GiveAWPCT)
						{
							GiveAWPCT = false;
							GivePlayerItem(client, "weapon_awp");
						}
						else
						{
							GivePlayerItem(client, "weapon_m4a1");
							PrintToChat(client, " \x07* AWP is limited to 1 player in each team per round.");
						}
					}
				}
			}
			case 5:	GivePlayerItem(client, "weapon_p90");
			case 6:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_mac10");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_mp9");
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

		switch(GetRandomInt(0, 20))
		{
			case 1:		GivePlayerItem(client, "weapon_flashbang");
			case 2:		GivePlayerItem(client, "weapon_hegrenade");
			case 18:	GivePlayerItem(client, "weapon_smokegrenade");
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