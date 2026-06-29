#include <sourcemod>
#include <sdktools>
#include <cstrike>
int PrimaryChoice[MAXPLAYERS + 1];
int SecondaryChoice[MAXPLAYERS + 1];
public Plugin myinfo = 
{
	name = "Gun menu", 
	author = "ExTacY, Fixed by S4muRaY'", 
	description = "", 
	version = "1.0", 
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_guns", Command_Guns);
}
public Action Command_Guns(int client, int args)
{
	BuildPrimaryMenu(client);
}
stock BuildPrimaryMenu(int client)
{
	Menu menu = new Menu(MenuHandler1);
	menu.SetTitle("Choose Primary Weapon:");
	menu.AddItem("1", "M4A4 / AK-47");
	menu.AddItem("2", "M4A1-S / AK-47");
	menu.AddItem("3", "Galil AR / Famas");
	menu.AddItem("4", "UMP-45");
	menu.AddItem("5", "SSG-08");
	menu.AddItem("6", "AWP");
	menu.Display(client, MENU_TIME_FOREVER);
}

stock BuildSecondaryMenu(int client)
{
	Menu menu = new Menu(MenuHandler2);
	menu.SetTitle("Choose Secondary Weapon:");
	menu.AddItem("1", "P2000 / Glock");
	menu.AddItem("2", "USP-S / Glock");
	menu.AddItem("3", "Dual Berettas");
	menu.AddItem("4", "P250");
	menu.AddItem("5", "Tec-9 / Five-SeveN");
	menu.AddItem("6", "Deagle");
	menu.Display(client, MENU_TIME_FOREVER);
}
public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		PrimaryChoice[param1] = param2;
		BuildSecondaryMenu(param1);
	}
}
public int MenuHandler2(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		SecondaryChoice[param1] = param2;
		CreateTimer(0.1, GiveEquipment, param1);
	}
}
public Action GiveEquipment(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		RemoveAllWeapons(client);
		switch (PrimaryChoice[client])
		{
			case 0:
			{
				switch (GetClientTeam(client))
				{
					case CS_TEAM_T:GivePlayerItem(client, "weapon_ak47");
					case CS_TEAM_CT:GivePlayerItem(client, "weapon_m4a1");
				}
			}
			case 1:
			{
				switch (GetClientTeam(client))
				{
					case CS_TEAM_T:GivePlayerItem(client, "weapon_ak47");
					case CS_TEAM_CT:GivePlayerItem(client, "weapon_m4a1_silencer");
				}
			}
			case 2:
			{
				switch (GetClientTeam(client))
				{
					case CS_TEAM_T:GivePlayerItem(client, "weapon_galilar");
					case CS_TEAM_CT:GivePlayerItem(client, "weapon_famas");
				}
			}
			case 3:GivePlayerItem(client, "weapon_ump45");
			case 4:GivePlayerItem(client, "weapon_ssg08");
			case 5:GivePlayerItem(client, "weapon_awp");
		}
	}
	
	switch (SecondaryChoice[client])
	{
		case 0:
		{
			switch (GetClientTeam(client))
			{
				case CS_TEAM_T:GivePlayerItem(client, "weapon_glock");
				case CS_TEAM_CT:GivePlayerItem(client, "weapon_hkp2000");
			}
		}
		case 1:
		{
			switch (GetClientTeam(client))
			{
				case CS_TEAM_T:GivePlayerItem(client, "weapon_glock");
				case CS_TEAM_CT:GivePlayerItem(client, "weapon_usp_silencer");
			}
		}
		case 2:GivePlayerItem(client, "weapon_elite");
		case 3:GivePlayerItem(client, "weapon_p250");
		case 4:
		{
			switch (GetClientTeam(client))
			{
				case CS_TEAM_T:GivePlayerItem(client, "weapon_tec9");
				case CS_TEAM_CT:GivePlayerItem(client, "weapon_fiveseven");
			}
		}
		case 5:GivePlayerItem(client, "weapon_deagle");
	}
}
stock bool IsValidClient(int client)
{
	if (client > MaxClients)
		return false;
	if (client <= 0)
		return false;
	if (!IsClientConnected(client))
		return false;
	return IsClientInGame(client);
}

stock RemoveAllWeapons(int client)
{
	int weaponslot = 0;
	int ent = -1;
	if (weaponslot == 5)
	{
		return Plugin_Handled;
	}
	while ((ent = GetPlayerWeaponSlot(client, weaponslot)) == -1 && weaponslot <= 5)
	{
		weaponslot++;
	}
	while ((ent = GetPlayerWeaponSlot(client, weaponslot)) != -1 && weaponslot <= 5)
	{
		CS_DropWeapon(client, ent, false, false);
		AcceptEntityInput(ent, "Kill");
		weaponslot++;
		ent = -1;
	}
} 