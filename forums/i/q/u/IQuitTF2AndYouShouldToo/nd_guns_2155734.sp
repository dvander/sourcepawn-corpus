#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[ND] Guns Menu",
	author = "abrandnewday",
	description = "Allows clients to get guns!",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	RegConsoleCmd("sm_guns", WeaponMenu);
	RegConsoleCmd("guns", WeaponMenu);

	CreateConVar("nd_guns_version", PLUGIN_VERSION, "ND Gun Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:WeaponMenu(client,args)
{
	Weapons(client);
	
	return Plugin_Handled;
}

public Action:Weapons(client)
{
	new Handle:menu = CreateMenu(WeaponMenuHandler);
	SetMenuTitle(menu, "Guns Menu");
	AddMenuItem(menu, "option1", "Ammo Pack");
	AddMenuItem(menu, "option2", "Arm Blade");
	AddMenuItem(menu, "option3", "Arm Knifes");
	AddMenuItem(menu, "option4", "Avenger");
	AddMenuItem(menu, "option5", "Avenger Launcher");
	AddMenuItem(menu, "option6", "Bag 90");
	AddMenuItem(menu, "option7", "Chaingun");
	AddMenuItem(menu, "option8", "Chaingun Tier 2");
	AddMenuItem(menu, "option9", "Daisy Cutter");
	AddMenuItem(menu, "option10", "EMP Grenade");
	AddMenuItem(menu, "option11", "Energy Arm Blade");
	AddMenuItem(menu, "option12", "Energy Arm Knives");
	AddMenuItem(menu, "option13", "F2000");
	AddMenuItem(menu, "option14", "F2000 Launcher");
	AddMenuItem(menu, "option15", "F2000 Silenced");
	AddMenuItem(menu, "option16", "Frag Grenade");
	AddMenuItem(menu, "option17", "Grenade Launcher");
	AddMenuItem(menu, "option18", "Hypospray");
	AddMenuItem(menu, "option19", "M95");
	AddMenuItem(menu, "option20", "M95 Tier 2");
	AddMenuItem(menu, "option21", "Medpack");
	AddMenuItem(menu, "option22", "Mine");
	AddMenuItem(menu, "option23", "ML17 Grenade");
	AddMenuItem(menu, "option24", "MP7");
	AddMenuItem(menu, "option25", "MP500");
	AddMenuItem(menu, "option26", "NX300");
	AddMenuItem(menu, "option27", "P12 Grenade");
	AddMenuItem(menu, "option28", "P900");
	AddMenuItem(menu, "option29", "Paladin");
	AddMenuItem(menu, "option30", "Paladin Semi-Auto");
	AddMenuItem(menu, "option31", "PP22");
	AddMenuItem(menu, "option32", "PSG");
	AddMenuItem(menu, "option33", "PSG Semi Auto");
	AddMenuItem(menu, "option34", "Radar Kit");
	AddMenuItem(menu, "option35", "Remote Grenade");
	AddMenuItem(menu, "option36", "Repair Tool");
	AddMenuItem(menu, "option37", "Shotgun");
	AddMenuItem(menu, "option38", "Shotgun Silver Nova");
	AddMenuItem(menu, "option39", "Shotgun Tier 2");
	AddMenuItem(menu, "option40", "SP5");
	AddMenuItem(menu, "option41", "SP5 Fire Sword");
	AddMenuItem(menu, "option42", "SVR Grenade");
	AddMenuItem(menu, "option43", "U23 Grenade");
	AddMenuItem(menu, "option44", "X01");
	AddMenuItem(menu, "option45", "X01 Tier 2");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);

	return Plugin_Handled;
}

public WeaponMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	SetConVarBool(FindConVar("sv_cheats"), true, false);

	if (action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: FakeClientCommand(client, "give weapon_ammopack");
			case 1: FakeClientCommand(client, "give weapon_armblade");
			case 2: FakeClientCommand(client, "give weapon_armknives");
			case 3: FakeClientCommand(client, "give weapon_avenger");
			case 4: FakeClientCommand(client, "give weapon_avenger_launcher");
			case 5: FakeClientCommand(client, "give weapon_bag90");
			case 6: FakeClientCommand(client, "give weapon_chaingun");
			case 7: FakeClientCommand(client, "give weapon_chaingun_tier2");
			case 8: FakeClientCommand(client, "give weapon_daisycutter");
			case 9: FakeClientCommand(client, "give weapon_emp_grenade");
			case 10: FakeClientCommand(client, "give weapon_energy_armblade");
			case 11: FakeClientCommand(client, "give weapon_energy_armknives");
			case 12: FakeClientCommand(client, "give weapon_f2000");
			case 13: FakeClientCommand(client, "give weapon_f2000_launcher");
			case 14: FakeClientCommand(client, "give weapon_f2000_silenced");
			case 15: FakeClientCommand(client, "give weapon_frag_grenade");
			case 16: FakeClientCommand(client, "give weapon_grenade_launcher");
			case 17: FakeClientCommand(client, "give weapon_hypospray");
			case 18: FakeClientCommand(client, "give weapon_m95");
			case 19: FakeClientCommand(client, "give weapon_m95_tier2");
			case 20:FakeClientCommand(client, "give weapon_medpack");
			case 21: FakeClientCommand(client, "give weapon_mine");
			case 22: FakeClientCommand(client, "give weapon_ml17_grenade");
			case 23: FakeClientCommand(client, "give weapon_mp7");
			case 24: FakeClientCommand(client, "give weapon_mp500");
			case 25: FakeClientCommand(client, "give weapon_nx300");
			case 26: FakeClientCommand(client, "give weapon_p12_grenade");
			case 27: FakeClientCommand(client, "give weapon_p900");
			case 28: FakeClientCommand(client, "give weapon_paladin");
			case 29: FakeClientCommand(client, "give weapon_paladin_semi_auto");
			case 30: FakeClientCommand(client, "give weapon_pp22");
			case 31: FakeClientCommand(client, "give weapon_psg");
			case 32: FakeClientCommand(client, "give weapon_psg_semi_auto");
			case 33: FakeClientCommand(client, "give weapon_radarkit");
			case 34: FakeClientCommand(client, "give weapon_remote_grenade");
			case 35: FakeClientCommand(client, "give weapon_repair_tool");
			case 36: FakeClientCommand(client, "give weapon_shotgun");
			case 37: FakeClientCommand(client, "give weapon_shotgun_silvernova");
			case 38: FakeClientCommand(client, "give weapon_shotgun_tier2");
			case 39: FakeClientCommand(client, "give weapon_sp5");
			case 40: FakeClientCommand(client, "give weapon_sp5_firesword");
			case 41: FakeClientCommand(client, "give weapon_svr_grenade");
			case 42: FakeClientCommand(client, "give weapon_u23_grenade");
			case 43: FakeClientCommand(client, "give weapon_x01");
			case 44: FakeClientCommand(client, "give weapon_x01_tier2");
		}
	}
	SetConVarBool(FindConVar("sv_cheats"), false, false);
}
