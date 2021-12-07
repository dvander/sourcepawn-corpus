#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "UNKNOWN",
	author = "AMBI",
	description = "Admin menu which gives players weapons and items",
	version = "",
	url = "www.FireWaLLCS.net/forums"
}

public OnPluginStart()
{
	RegAdminCmd("wg", ConsoleCmd, ADMFLAG_CUSTOM1);            //For admins to be able to use the wg command, they must have the "o" flag in their flags
	RegAdminCmd("say !wg", ConsoleCmd, ADMFLAG_CUSTOM1);       //If you know how to and want to change the flag alphabet, replace ADM_CUSTOM1 with something else (ADM_GENERIC means all sourcemod admins will have the access, and ADM_CUSTOM2 is the "p" flag)
	RegAdminCmd("say_team !wg", ConsoleCmd, ADMFLAG_CUSTOM1);
}

new MessagesEnabled = 1; //CHANGE THIS TO 0 TO DISABLE PLUGIN MESSAGES

public Action:ConsoleCmd(client, args)
{
	
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu, "Weapon Giver by AMBI");
	AddMenuItem(menu, "Pistols", "Pistols");
	AddMenuItem(menu, "Shotguns", "Shotguns");
	AddMenuItem(menu, "Sub-Machineguns", "Sub-Machineguns");
	AddMenuItem(menu, "Rifles", "Rifles");
	AddMenuItem(menu, "Machineguns", "Machineguns");
	AddMenuItem(menu, "Misc Items", "Misc Items");
	AddMenuItem(menu, "Others", "Others");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}

public MenuHandler1(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[1024];
		new String:name[1024];
		GetMenuItem(menu, param2, info, sizeof(info));
		if(strcmp(info, "Pistols") == 0)
		{
			new Handle:menupistol = CreateMenu(MenuHandler1);
			SetMenuTitle(menupistol, "WeaponGiver - Pistols");
			AddMenuItem(menupistol, "Glock", "Glock");
			AddMenuItem(menupistol, "USP", "USP");
			AddMenuItem(menupistol, "Deagle", "Deagle");
			AddMenuItem(menupistol, "P228", "P228");
			AddMenuItem(menupistol, "Five-Seven", "Five-Seven");
			AddMenuItem(menupistol, "Dual Elites", "Dual Elites");
			SetMenuExitButton(menupistol, true);
			DisplayMenu(menupistol, client, 0);
		}
		if(strcmp(info, "Shotguns") == 0)
        {
			new Handle:menushotgun = CreateMenu(MenuHandler1);
			SetMenuTitle(menushotgun, "WeaponGiver - Shotguns");
			AddMenuItem(menushotgun, "Shotgun M3", "Shotgun M3");
			AddMenuItem(menushotgun, "Auto Shotgun", "Auto Shotgun");
			SetMenuExitButton(menushotgun, true);
			DisplayMenu(menushotgun, client, 0);
		}
		if(strcmp(info, "Sub-Machineguns") == 0)
		{
			new Handle:menusmg = CreateMenu(MenuHandler1);
			SetMenuTitle(menusmg, "WeaponGiver - SMGs");
			AddMenuItem(menusmg, "Machine Pistol", "Machine Pistol");
			AddMenuItem(menusmg, "Ingram MAC-10", "Ingram MAC-10");
			AddMenuItem(menusmg, "MP5", "MP5");
			AddMenuItem(menusmg, "UMP", "UMP");
			AddMenuItem(menusmg, "P90", "P90");
			SetMenuExitButton(menusmg, true);
			DisplayMenu(menusmg, client, 0);
		}
		if(strcmp(info, "Rifles") == 0)
		{
			new Handle:menurifle = CreateMenu(MenuHandler1);
			SetMenuTitle(menurifle, "WeaponGiver - Rifles");
			AddMenuItem(menurifle, "Clarion", "Clarion");
			AddMenuItem(menurifle, "Defender", "Defender");
			AddMenuItem(menurifle, "Scout", "Scout");
			AddMenuItem(menurifle, "AK-47", "AK-47");
			AddMenuItem(menurifle, "M4A1", "M4A1");
			AddMenuItem(menurifle, "AUG", "AUG");
			AddMenuItem(menurifle, "Krieg", "Krieg");
			AddMenuItem(menurifle, "AWP", "AWP");
			AddMenuItem(menurifle, "SG550)", "SG550");
			AddMenuItem(menurifle, "G3SG1)", "G3SG1");
			SetMenuExitButton(menurifle, true);
			DisplayMenu(menurifle, client, 0);
		}
		if(strcmp(info, "Machineguns") == 0)
		{
			new Handle:menumg = CreateMenu(MenuHandler1);
			SetMenuTitle(menumg, "WeaponGiver - Machineguns");
			AddMenuItem(menumg, "Machinegun", "Machinegun");
			SetMenuExitButton(menumg, true);
			DisplayMenu(menumg, client, 0);
		}
		if(strcmp(info, "Misc Items") == 0)
		{
			new Handle:menumisc = CreateMenu(MenuHandler1);
			SetMenuTitle(menumisc, "WeaponGiver - Misc Items");
			AddMenuItem(menumisc, "Knife", "Knife");
			AddMenuItem(menumisc, "Grenade", "Grenade");
			AddMenuItem(menumisc, "Flashbang", "Flashbang");
			AddMenuItem(menumisc, "Smoke Grenade", "Smoke Grenade");
			AddMenuItem(menumisc, "Kevlar", "Kevlar");
			AddMenuItem(menumisc, "Kevlar + Helmet", "Kevlar + Helmet");
			AddMenuItem(menumisc, "C4 Bomb", "C4 Bomb");
			AddMenuItem(menumisc, "Defuser", "Defuser");
			AddMenuItem(menumisc, "Nightvision", "Nightvision");
			AddMenuItem(menumisc, "Cookies", "Cookies");
			SetMenuExitButton(menumisc, true);
			DisplayMenu(menumisc, client, 0);
		}
		if(strcmp(info, "Others") == 0)
		{
			new Handle:menuothers = CreateMenu(MenuHandler1);
			SetMenuTitle(menuothers, "WeaponGiver - Others");
			AddMenuItem(menuothers, "Дать пинка ;)", "Дать пинка ;)");
			AddMenuItem(menuothers, "Дать пивка x]", "Дать пивка x]");
			AddMenuItem(menuothers, "Предложить колы ;P", "Предложить колы ;P");
			AddMenuItem(menuothers, "Повысить умения ;D", "Повысить умения ;D");
			AddMenuItem(menuothers, "Насрать за шиворот ;O", "Насрать за шиворот ;O");
			AddMenuItem(menuothers, "Подогнать сухариков ;]", "Подогнать сухариков ;]");
			SetMenuExitButton(menuothers, true);
			DisplayMenu(menuothers, client, 0);
		}
		if(strcmp(info, "Glock") == 0)
		{
			new Handle:menuglock = CreateMenu(MenuHandler2);
			
			SetMenuTitle(menuglock, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuglock, name, name);
				}
			}
			SetMenuExitButton(menuglock, true);
			DisplayMenu(menuglock, client, 0);
		}
		if(strcmp(info, "USP") == 0)
		{
			new Handle:menuusp = CreateMenu(MenuHandler3);
			
			SetMenuTitle(menuusp, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuusp, name, name);
				}
			}
			SetMenuExitButton(menuusp, true);
			DisplayMenu(menuusp, client, 0);
		}
		if(strcmp(info, "Deagle") == 0)
		{
			new Handle:menudeagle = CreateMenu(MenuHandler4);
			
			SetMenuTitle(menudeagle, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menudeagle, name, name);
				}
			}
			SetMenuExitButton(menudeagle, true);
			DisplayMenu(menudeagle, client, 0);
		}
		if(strcmp(info, "P228") == 0)
		{
			new Handle:menucompact = CreateMenu(MenuHandler5);
			
			SetMenuTitle(menucompact, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menucompact, name, name);
				}
			}
			SetMenuExitButton(menucompact, true);
			DisplayMenu(menucompact, client, 0);
		}
		if(strcmp(info, "Five-Seven") == 0)
		{
			new Handle:menu57 = CreateMenu(MenuHandler6);
			
			SetMenuTitle(menu57, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menu57, name, name);
				}
			}
			SetMenuExitButton(menu57, true);
			DisplayMenu(menu57, client, 0);
		}
		if(strcmp(info, "Dual Elites") == 0)
		{
			new Handle:menuelites = CreateMenu(MenuHandler7);
			
			SetMenuTitle(menuelites, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuelites, name, name);
				}
			}
			SetMenuExitButton(menuelites, true);
			DisplayMenu(menuelites, client, 0);
		}
		if(strcmp(info, "Shotgun M3") == 0)
		{
			new Handle:menum3 = CreateMenu(MenuHandler8);
			
			SetMenuTitle(menum3, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menum3, name, name);
				}
			}
			SetMenuExitButton(menum3, true);
			DisplayMenu(menum3, client, 0);
		}
		if(strcmp(info, "Auto Shotgun") == 0)
		{
			new Handle:menuautoshotty = CreateMenu(MenuHandler9);
			
			SetMenuTitle(menuautoshotty, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuautoshotty, name, name);
				}
			}
			SetMenuExitButton(menuautoshotty, true);
			DisplayMenu(menuautoshotty, client, 0);
		}
		if(strcmp(info, "Machine Pistol") == 0)
		{
			new Handle:menumachinepistol = CreateMenu(MenuHandler10);
			
			SetMenuTitle(menumachinepistol, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menumachinepistol, name, name);
				}
			}
			SetMenuExitButton(menumachinepistol, true);
			DisplayMenu(menumachinepistol, client, 0);
		}
		if(strcmp(info, "Ingram MAC-10") == 0)
		{
			new Handle:menumac10 = CreateMenu(MenuHandler11);
			
			SetMenuTitle(menumac10, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menumac10, name, name);
				}
			}
			SetMenuExitButton(menumac10, true);
			DisplayMenu(menumac10, client, 0);
		}
		if(strcmp(info, "MP5") == 0)
		{
			new Handle:menump5 = CreateMenu(MenuHandler12);
			
			SetMenuTitle(menump5, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menump5, name, name);
				}
			}
			SetMenuExitButton(menump5, true);
			DisplayMenu(menump5, client, 0);
		}
		if(strcmp(info, "UMP") == 0)
		{
			new Handle:menuump = CreateMenu(MenuHandler13);
			
			SetMenuTitle(menuump, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuump, name, name);
				}
			}
			SetMenuExitButton(menuump, true);
			DisplayMenu(menuump, client, 0);
		}
		if(strcmp(info, "P90") == 0)
		{
			new Handle:menup90 = CreateMenu(MenuHandler14);
			
			SetMenuTitle(menup90, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menup90, name, name);
				}
			}
			SetMenuExitButton(menup90, true);
			DisplayMenu(menup90, client, 0);
		}
		if(strcmp(info, "Clarion") == 0)
		{
			new Handle:menuclarion = CreateMenu(MenuHandler15);
			
			SetMenuTitle(menuclarion, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuclarion, name, name);
				}
			}
			SetMenuExitButton(menuclarion, true);
			DisplayMenu(menuclarion, client, 0);
		}
		if(strcmp(info, "Defender") == 0)
		{
			new Handle:menudefender = CreateMenu(MenuHandler16);
			
			SetMenuTitle(menudefender, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menudefender, name, name);
				}
			}
			SetMenuExitButton(menudefender, true);
			DisplayMenu(menudefender, client, 0);
		}
		if(strcmp(info, "Scout") == 0)
		{
			new Handle:menuscout = CreateMenu(MenuHandler17);
			
			SetMenuTitle(menuscout, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuscout, name, name);
				}
			}
			SetMenuExitButton(menuscout, true);
			DisplayMenu(menuscout, client, 0);
		}
		if(strcmp(info, "AK-47") == 0)
		{
			new Handle:menuak47 = CreateMenu(MenuHandler18);
			
			SetMenuTitle(menuak47, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuak47, name, name);
				}
			}
			SetMenuExitButton(menuak47, true);
			DisplayMenu(menuak47, client, 0);
		}
		if(strcmp(info, "M4A1") == 0)
		{
			new Handle:menum4a1 = CreateMenu(MenuHandler19);
			
			SetMenuTitle(menum4a1, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menum4a1, name, name);
				}
			}
			SetMenuExitButton(menum4a1, true);
			DisplayMenu(menum4a1, client, 0);
		}
		if(strcmp(info, "AUG") == 0)
		{
			new Handle:menuaug = CreateMenu(MenuHandler20);
			
			SetMenuTitle(menuaug, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuaug, name, name);
				}
			}
			SetMenuExitButton(menuaug, true);
			DisplayMenu(menuaug, client, 0);
		}
		if(strcmp(info, "Krieg") == 0)
		{
			new Handle:menukrieg = CreateMenu(MenuHandler21);
			
			SetMenuTitle(menukrieg, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menukrieg, name, name);
				}
			}
			SetMenuExitButton(menukrieg, true);
			DisplayMenu(menukrieg, client, 0);
		}
		if(strcmp(info, "AWP") == 0)
		{
			new Handle:menuawp = CreateMenu(MenuHandler22);
			
			SetMenuTitle(menuawp, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuawp, name, name);
				}
			}
			SetMenuExitButton(menuawp, true);
			DisplayMenu(menuawp, client, 0);
		}
		if(strcmp(info, "SG550 (CT Autosniper)") == 0)
		{
			new Handle:menusg550 = CreateMenu(MenuHandler23);
			
			SetMenuTitle(menusg550, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menusg550, name, name);
				}
			}
			SetMenuExitButton(menusg550, true);
			DisplayMenu(menusg550, client, 0);
		}
		if(strcmp(info, "G3SG1 (T Autosniper)") == 0)
		{
			new Handle:menug3sg1 = CreateMenu(MenuHandler24);
			
			SetMenuTitle(menug3sg1, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menug3sg1, name, name);
				}
			}
			SetMenuExitButton(menug3sg1, true);
			DisplayMenu(menug3sg1, client, 0);
		}
		if(strcmp(info, "Machinegun") == 0)
		{
			new Handle:menumachine = CreateMenu(MenuHandler25);
			
			SetMenuTitle(menumachine, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menumachine, name, name);
				}
			}
			SetMenuExitButton(menumachine, true);
			DisplayMenu(menumachine, client, 0);
		}
		if(strcmp(info, "Knife") == 0)
		{
			new Handle:menuknife = CreateMenu(MenuHandler26);
			
			SetMenuTitle(menuknife, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuknife, name, name);
				}
			}
			SetMenuExitButton(menuknife, true);
			DisplayMenu(menuknife, client, 0);
		}
		if(strcmp(info, "Grenade") == 0)
		{
			new Handle:menugrenade = CreateMenu(MenuHandler27);
			
			SetMenuTitle(menugrenade, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menugrenade, name, name);
				}
			}
			SetMenuExitButton(menugrenade, true);
			DisplayMenu(menugrenade, client, 0);
		}
		if(strcmp(info, "Flashbang") == 0)
		{
			new Handle:menuflashbang = CreateMenu(MenuHandler28);
			
			SetMenuTitle(menuflashbang, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuflashbang, name, name);
				}
			}
			SetMenuExitButton(menuflashbang, true);
			DisplayMenu(menuflashbang, client, 0);
		}
		if(strcmp(info, "Smoke Grenade") == 0)
		{
			new Handle:menusmoke = CreateMenu(MenuHandler29);
			
			SetMenuTitle(menusmoke, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menusmoke, name, name);
				}
			}
			SetMenuExitButton(menusmoke, true);
			DisplayMenu(menusmoke, client, 0);
		}
		if(strcmp(info, "Kevlar") == 0)
		{
			new Handle:menukevlar = CreateMenu(MenuHandler30);
			
			SetMenuTitle(menukevlar, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menukevlar, name, name);
				}
			}
			SetMenuExitButton(menukevlar, true);
			DisplayMenu(menukevlar, client, 0);
		}
		if(strcmp(info, "Kevlar + Helmet") == 0)
		{
			new Handle:menukevhelm = CreateMenu(MenuHandler31);
			
			SetMenuTitle(menukevhelm, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menukevhelm, name, name);
				}
			}
			SetMenuExitButton(menukevhelm, true);
			DisplayMenu(menukevhelm, client, 0);
		}
		if(strcmp(info, "C4 Bomb") == 0)
		{
			new Handle:menuc4 = CreateMenu(MenuHandler32);
			
			SetMenuTitle(menuc4, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuc4, name, name);
				}
			}
			SetMenuExitButton(menuc4, true);
			DisplayMenu(menuc4, client, 0);
		}
		if(strcmp(info, "Defuser") == 0)
		{
			new Handle:menudefuser = CreateMenu(MenuHandler33);
			
			SetMenuTitle(menudefuser, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menudefuser, name, name);
				}
			}
			SetMenuExitButton(menudefuser, true);
			DisplayMenu(menudefuser, client, 0);
		}
		if(strcmp(info, "Nightvision") == 0)
		{
			new Handle:menunight = CreateMenu(MenuHandler34);
			
			SetMenuTitle(menunight, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menunight, name, name);
				}
			}
			SetMenuExitButton(menunight, true);
			DisplayMenu(menunight, client, 0);
		}
		if(strcmp(info, "Cookies") == 0)
		{
			new Handle:menucookies = CreateMenu(MenuHandler35);
			
			SetMenuTitle(menucookies, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menucookies, name, name);
				}
			}
			SetMenuExitButton(menucookies, true);
			DisplayMenu(menucookies, client, 0);
		}
		if(strcmp(info, "Дать пинка ;)") == 0)
		{
			new Handle:menuw1 = CreateMenu(MenuHandler36);
			
			SetMenuTitle(menuw1, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuw1, name, name);
				}
			}
			SetMenuExitButton(menuw1, true);
			DisplayMenu(menuw1, client, 0);
		}
		if(strcmp(info, "Подогнать сухариков ;]") == 0)
		{
			new Handle:menuw2 = CreateMenu(MenuHandler37);
			
			SetMenuTitle(menuw2, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuw2, name, name);
				}
			}
			SetMenuExitButton(menuw2, true);
			DisplayMenu(menuw2, client, 0);
		}
		if(strcmp(info, "Дать пивка x]") == 0)
		{
			new Handle:menuw3 = CreateMenu(MenuHandler38);
			
			SetMenuTitle(menuw3, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuw3, name, name);
				}
			}
			SetMenuExitButton(menuw3, true);
			DisplayMenu(menuw3, client, 0);
		}
		if(strcmp(info, "Повысить умения ;D") == 0)
		{
			new Handle:menuw4 = CreateMenu(MenuHandler39);
			
			SetMenuTitle(menuw4, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuw4, name, name);
				}
			}
			SetMenuExitButton(menuw4, true);
			DisplayMenu(menuw4, client, 0);
		}
		if(strcmp(info, "Предложить колы ;P") == 0)
		{
			new Handle:menuw5 = CreateMenu(MenuHandler40);
			
			SetMenuTitle(menuw5, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuw5, name, name);
				}
			}
			SetMenuExitButton(menuw5, true);
			DisplayMenu(menuw5, client, 0);
		}
		if(strcmp(info, "Насрать за шиворот ;O") == 0)
		{
			new Handle:menuw6 = CreateMenu(MenuHandler41);
			
			SetMenuTitle(menuw6, "Select Player");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(menuw6, name, name);
				}
			}
			SetMenuExitButton(menuw6, true);
			DisplayMenu(menuw6, client, 0);
		}
        }
}

public MenuHandler2(Handle:menuglock, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuglock, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_glock");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuglock, client, 0);
			}
			}
		}
	}
}
public MenuHandler3(Handle:menuusp, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuusp, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_usp");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuusp, client, 0);
			}
			}
		}
	}
}
public MenuHandler4(Handle:menudeagle, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menudeagle, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_deagle");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menudeagle, client, 0);
			}
			}
		}
	}
}
public MenuHandler5(Handle:menucompact, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menucompact, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_p228");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menucompact, client, 0);
			}
			}
		}
	}
}
public MenuHandler6(Handle:menu57, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menu57, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_fiveseven");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menu57, client, 0);
			}
			}
		}
	}
}
public MenuHandler7(Handle:menuelites, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuelites, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_elite");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuelites, client, 0);
			}
			}
		}
	}
}

public MenuHandler8(Handle:menum3, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menum3, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_m3");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menum3, client, 0);
			}
			}
		}
	}
}

public MenuHandler9(Handle:menuautoshotty, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuautoshotty, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_xm1014");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuautoshotty, client, 0);
			}
			}
		}
	}
}

public MenuHandler10(Handle:menumachinepistol, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menumachinepistol, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_tmp");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menumachinepistol, client, 0);
			}
			}
		}
	}
}

public MenuHandler11(Handle:menumac10, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menumac10, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_mac10");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menumac10, client, 0);
			}
			}
		}
	}
}

public MenuHandler12(Handle:menump5, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menump5, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_mp5navy");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menump5, client, 0);
			}
			}
		}
	}
}

public MenuHandler13(Handle:menuump, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuump, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_ump45");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuump, client, 0);
			}
			}
		}
	}
}

public MenuHandler14(Handle:menup90, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menup90, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_p90");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menup90, client, 0);
			}
			}
		}
	}
}

public MenuHandler15(Handle:menuclarion, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuclarion, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_famas");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuclarion, client, 0);
			}
			}
		}
	}
}

public MenuHandler16(Handle:menudefender, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menudefender, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_galil");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menudefender, client, 0);
			}
			}
		}
	}
}

public MenuHandler17(Handle:menuscout, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuscout, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_scout");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuscout, client, 0);
			}
			}
		}
	}
}

public MenuHandler18(Handle:menuak47, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuak47, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_ak47");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuak47, client, 0);
			}
			}
		}
	}
}

public MenuHandler19(Handle:menum4a1, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menum4a1, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_m4a1");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menum4a1, client, 0);
			}
			}
		}
	}
}

public MenuHandler20(Handle:menuaug, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuaug, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_aug");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuaug, client, 0);
			}
			}
		}
	}
}

public MenuHandler21(Handle:menukrieg, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menukrieg, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_sg552");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menukrieg, client, 0);
			}
			}
		}
	}
}

public MenuHandler22(Handle:menuawp, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuawp, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_awp");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuawp, client, 0);
			}
			}
		}
	}
}

public MenuHandler23(Handle:menusg550, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menusg550, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_sg550");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menusg550, client, 0);
			}
			}
		}
	}
}

public MenuHandler24(Handle:menug3sg1, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menug3sg1, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_g3sg1");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menug3sg1, client, 0);
			}
			}
		}
	}
}

public MenuHandler25(Handle:menumachine, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menumachine, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_m249");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menumachine, client, 0);
			}
			}
		}
	}
}

public MenuHandler26(Handle:menuknife, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuknife, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_knife");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuknife, client, 0);
			}
			}
		}
	}
}

public MenuHandler27(Handle:menugrenade, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menugrenade, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_hegrenade");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menugrenade, client, 0);
			}
			}
		}
	}
}

public MenuHandler28(Handle:menuflashbang, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuflashbang, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_flashbang");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuflashbang, client, 0);
			}
			}
		}
	}
}

public MenuHandler29(Handle:menusmoke, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menusmoke, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_smokegrenade");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menusmoke, client, 0);
			}
			}
		}
	}
}

public MenuHandler30(Handle:menukevlar, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menukevlar, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "item_kevlar");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menukevlar, client, 0);
			}
			}
		}
	}
}

public MenuHandler31(Handle:menukevhelm, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menukevhelm, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "item_assaultsuit");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menukevhelm, client, 0);
			}
			}
		}
	}
}

public MenuHandler32(Handle:menuc4, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuc4, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "weapon_c4");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menuc4, client, 0);
			}
			}
		}
	}
}

public MenuHandler33(Handle:menudefuser, MenuAction:action, client, param2)

{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menudefuser, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "item_defuser");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menudefuser, client, 0);
			}
			}
		}
	}
}

public MenuHandler34(Handle:menunight, MenuAction:action, client, param2)

{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menunight, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				GivePlayerItem(i, "item_nvgs");
				if (MessagesEnabled == 1)
				{
					
				}
				DisplayMenu(menunight, client, 0);
			}
			}
		}
	}
}

public MenuHandler35(Handle:menucookies, MenuAction:action, client, param2)

{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menucookies, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				PrintToChatAll("\x01(ADMIN) \x03%s \x01gave \x03%s \x01some \x04Cookies", namegiver, namereceiver);
				DisplayMenu(menucookies, client, 0);
			}
			}
		}
	}
}

public MenuHandler36(Handle:menuw1, MenuAction:action, client, param2)

{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuw1, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				PrintToChatAll("\x01\x03%s \x01дал пинка \x03%s \x01;;)", namegiver, namereceiver);
				DisplayMenu(menuw1, client, 0);
			}
			}
		}
	}
}

public MenuHandler37(Handle:menuw2, MenuAction:action, client, param2)

{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuw2, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				PrintToChatAll("\x01\x03%s \x01подогнал для \x03%s \x01немного сухариков ;)", namegiver, namereceiver);
				DisplayMenu(menuw2, client, 0);
			}
			}
		}
	}
}

public MenuHandler38(Handle:menuw3, MenuAction:action, client, param2)

{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuw3, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				PrintToChatAll("\x01\x03%s \x01дал \x03%s \x01\x01холодненького пивка ;)", namegiver, namereceiver);
				DisplayMenu(menuw3, client, 0);
			}
			}
		}
	}
}

public MenuHandler39(Handle:menuw4, MenuAction:action, client, param2)

{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuw4, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				PrintToChatAll("\x01\x03%s \x01повысил умения \x03%s \x01до 27 уровня! ;)", namegiver, namereceiver);
				DisplayMenu(menuw4, client, 0);
			}
			}
		}
	}
}

public MenuHandler40(Handle:menuw5, MenuAction:action, client, param2)

{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuw5, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				PrintToChatAll("\x01\x03%s \x01предложил \x03%s \x01выпить холодненькой колы ;)", namegiver, namereceiver);
				DisplayMenu(menuw5, client, 0);
			}
			}
		}
	}
}

public MenuHandler41(Handle:menuw6, MenuAction:action, client, param2)

{
	if (action == MenuAction_Select) 
	{
		new String:namereceiver[32];
		new String:namegiver[32];
		new String:loopname[32];
		GetClientName(client, namegiver, sizeof(namegiver));
		GetMenuItem(menuw6, param2, namereceiver, sizeof(namereceiver));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
			GetClientName(i, loopname, sizeof(loopname));
			if ((StrEqual(loopname, namereceiver, true)) && (IsClientInGame(i)))
			{
				PrintToChatAll("\x01\x03%s \x01с удовольствием бы насрал \x03%s \x01за шиворот ;)", namegiver, namereceiver);
				DisplayMenu(menuw6, client, 0);
			}
			}
		}
	}
}

