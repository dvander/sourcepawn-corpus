#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[FoF] Guns Menu",
	author = "abrandnewday",
	description = "Allows clients to get guns!",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	RegConsoleCmd("sm_guns", WeaponMenu);
	RegConsoleCmd("guns", WeaponMenu);

	CreateConVar("fof_guns_version", PLUGIN_VERSION, "FoF Gun Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:WeaponMenu(client, args)
{
	Weapons(client);
	
	return Plugin_Handled;
}

public Action:Weapons(client)
{
	if(IsValidClient(client))
	{
		new Handle:menu = CreateMenu(WeaponMenuHandler);
		SetMenuTitle(menu, "Gun Menu");
		AddMenuItem(menu, "0", "Hatchet");
		AddMenuItem(menu, "1", "Bow");
		AddMenuItem(menu, "2", "Smith Carbine");
		AddMenuItem(menu, "3", "Coach Shotgun");
		AddMenuItem(menu, "4", "Colt Navy 1851");
		AddMenuItem(menu, "5", "Deringer");
		AddMenuItem(menu, "6", "Dynamite");
		AddMenuItem(menu, "7", "Black Dynamite");
		AddMenuItem(menu, "8", "Henry Rifle");
		AddMenuItem(menu, "9", "Knife");
		AddMenuItem(menu, "10", "Mare's Leg");
		AddMenuItem(menu, "11", "Peacemaker");
		AddMenuItem(menu, "12", "Sawed-Off Shotgun");
		AddMenuItem(menu, "13", "SW Schofield");
		AddMenuItem(menu, "14", "Sharps Rifle");
		AddMenuItem(menu, "15", "Pump Shotgun W1893");
		AddMenuItem(menu, "16", "Volcanic Pistol");
		AddMenuItem(menu, "17", "Colt Walker");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 15);
	}
	return Plugin_Handled;
}

public WeaponMenuHandler(Handle:menu, MenuAction:action, client, item)
{
	SetConVarBool(FindConVar("sv_cheats"), true, false);

	if(action == MenuAction_Select)
	{
		switch(item)
		{
			case 0: FakeClientCommand(client, "give weapon_axe");
			case 1: FakeClientCommand(client, "give weapon_bow");
			case 2: FakeClientCommand(client, "give weapon_carbine");
			case 3: FakeClientCommand(client, "give weapon_coachgun");
			case 4: FakeClientCommand(client, "give weapon_coltnavy");
			case 5: FakeClientCommand(client, "give weapon_deringer");
			case 6: FakeClientCommand(client, "give weapon_dynamite");
			case 7: FakeClientCommand(client, "give weapon_dynamite_black");
			case 8: FakeClientCommand(client, "give weapon_henryrifle");
			case 9: FakeClientCommand(client, "give weapon_knife");
			case 10: FakeClientCommand(client, "give weapon_maresleg");
			case 11: FakeClientCommand(client, "give weapon_peacemaker");
			case 12: FakeClientCommand(client, "give weapon_sawedoff_shotgun");
			case 13: FakeClientCommand(client, "give weapon_schofield");
			case 14: FakeClientCommand(client, "give weapon_sharps");
			case 15: FakeClientCommand(client, "give weapon_shotgun");
			case 16: FakeClientCommand(client, "give weapon_volcanic");
			case 17: FakeClientCommand(client, "give weapon_walker");
		}
	}
	SetConVarBool(FindConVar("sv_cheats"), false, false);
}

stock bool:IsValidClient(client, bool:replay = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client)) return false;
	if(replay && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
	return true;
}

