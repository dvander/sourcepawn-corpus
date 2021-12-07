#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "SM WeaponGiver",
	author = "LightningZLaser",
	description = "Admin menu which gives players weapons and items",
	version = "1.0",
	url = "www.FireWaLLCS.net/forums"
}

public OnPluginStart()
{
    RegAdminCmd("wg", ConsoleCmd, ADMFLAG_CUSTOM1); //For admins to be able to use the wg command, they must have the "o" flag in their flags
	RegAdminCmd("say !wg", ConsoleCmd, ADMFLAG_CUSTOM1); //If you know how to and want to change the flag alphabet, replace ADM_CUSTOM1 with something else (ADM_GENERIC means all sourcemod admins will have the access, and ADM_CUSTOM2 is the "p" flag)
	RegAdminCmd("say_team !wg", ConsoleCmd, ADMFLAG_CUSTOM1);
}

new MessagesEnabled = 1; //CHANGE THIS TO 0 TO DISABLE PLUGIN MESSAGES

public Action:ConsoleCmd(client, args)
{
	
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu, "[SM] 武器单 (作者:闪电雷射)");
	AddMenuItem(menu, "手枪", "手枪");
	AddMenuItem(menu, "猎枪", "猎枪");
	AddMenuItem(menu, "冲锋枪", "冲锋枪");
	AddMenuItem(menu, "步枪", "步枪");
	AddMenuItem(menu, "机枪", "机枪");
	AddMenuItem(menu, "其他东西", "其他东西");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}

public MenuHandler1(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		new String:name[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		if(strcmp(info, "手枪") == 0)
		{
			new Handle:menupistol = CreateMenu(MenuHandler1);
			SetMenuTitle(menupistol, "[SM] 武器单- 手枪");
			AddMenuItem(menupistol, "Glock", "Glock");
			AddMenuItem(menupistol, "USP 手枪", "USP 手枪");
			AddMenuItem(menupistol, "沙漠老鹰手枪", "沙漠老鹰手枪");
			AddMenuItem(menupistol, "P228 手枪", "P228 手枪");
			AddMenuItem(menupistol, "五七手枪", "五七手枪");
			AddMenuItem(menupistol, "双拿手枪", "双拿手枪");
			SetMenuExitButton(menupistol, true);
			DisplayMenu(menupistol, client, 0);
		}
		if(strcmp(info, "猎枪") == 0)
        {
			new Handle:menushotgun = CreateMenu(MenuHandler1);
			SetMenuTitle(menushotgun, "[SM] 武器单- 猎枪");
			AddMenuItem(menushotgun, "M3 猎枪", "M3 猎枪");
			AddMenuItem(menushotgun, "XM1014 自动猎枪", "XM1014 自动猎枪");
			SetMenuExitButton(menushotgun, true);
			DisplayMenu(menushotgun, client, 0);
		}
		if(strcmp(info, "冲锋枪") == 0)
		{
			new Handle:menusmg = CreateMenu(MenuHandler1);
			SetMenuTitle(menusmg, "[SM] 武器单- 冲锋枪");
			AddMenuItem(menusmg, "自动手枪", "自动手枪");
			AddMenuItem(menusmg, "MAC-10 冲锋枪", "MAC-10 冲锋枪");
			AddMenuItem(menusmg, "MP5 冲锋枪", "MP5 冲锋枪");
			AddMenuItem(menusmg, "UMP 冲锋枪", "UMP 冲锋枪");
			AddMenuItem(menusmg, "P90 冲锋枪", "P90 冲锋枪");
			SetMenuExitButton(menusmg, true);
			DisplayMenu(menusmg, client, 0);
		}
		if(strcmp(info, "步枪") == 0)
		{
			new Handle:menurifle = CreateMenu(MenuHandler1);
			SetMenuTitle(menurifle, "[SM] 武器单- 步枪");
			AddMenuItem(menurifle, "FAMAS 步枪", "FAMAS 步枪");
			AddMenuItem(menurifle, "防守者步枪", "防守者步枪");
			AddMenuItem(menurifle, "侦察狙击步枪", "侦察狙击步枪");
			AddMenuItem(menurifle, "AK-47 步枪", "AK-47 步枪");
			AddMenuItem(menurifle, "M4A1 步枪", "M4A1 步枪");
			AddMenuItem(menurifle, "AUG 步枪", "AUG 步枪");
			AddMenuItem(menurifle, "Krieg 步枪", "Krieg 步枪");
			AddMenuItem(menurifle, "AWP 狙击步枪", "AWP 狙击步枪");
			AddMenuItem(menurifle, "SG550 (CT 自动狙击步枪)", "SG550 (CT 自动狙击步枪)");
			AddMenuItem(menurifle, "G3SG1 (T 自动狙击步枪)", "G3SG1 (T 自动狙击步枪)");
			SetMenuExitButton(menurifle, true);
			DisplayMenu(menurifle, client, 0);
		}
		if(strcmp(info, "机枪") == 0)
		{
			new Handle:menumg = CreateMenu(MenuHandler1);
			SetMenuTitle(menumg, "[SM] 武器单- 机枪");
			AddMenuItem(menumg, "机枪", "机枪");
			SetMenuExitButton(menumg, true);
			DisplayMenu(menumg, client, 0);
		}
		if(strcmp(info, "其他东西") == 0)
		{
			new Handle:menumisc = CreateMenu(MenuHandler1);
			SetMenuTitle(menumisc, "[SM] 武器单- 其他东西");
			AddMenuItem(menumisc, "刀子", "刀子");
			AddMenuItem(menumisc, "手榴弹", "手榴弹");
			AddMenuItem(menumisc, "闪光弹", "闪光弹");
			AddMenuItem(menumisc, "烟雾弹", "烟雾弹");
			AddMenuItem(menumisc, "安全套装", "安全套装");
			AddMenuItem(menumisc, "安全套装和安全帽", "安全套装和安全帽");
			AddMenuItem(menumisc, "C4 定时炸弹", "C4 定时炸弹");
			AddMenuItem(menumisc, "定时炸弹停止器", "定时炸弹停止器");
			AddMenuItem(menumisc, "夜视镜", "夜视镜");
			AddMenuItem(menumisc, "饼干", "饼干");
			SetMenuExitButton(menumisc, true);
			DisplayMenu(menumisc, client, 0);
		}
		if(strcmp(info, "Glock") == 0)
		{
			new Handle:menuglock = CreateMenu(MenuHandler2);
			
			SetMenuTitle(menuglock, "请选择玩家");
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
		if(strcmp(info, "USP 手枪") == 0)
		{
			new Handle:menuusp = CreateMenu(MenuHandler3);
			
			SetMenuTitle(menuusp, "请选择玩家");
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
		if(strcmp(info, "沙漠老鹰手枪") == 0)
		{
			new Handle:menudeagle = CreateMenu(MenuHandler4);
			
			SetMenuTitle(menudeagle, "请选择玩家");
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
		if(strcmp(info, "P228 手枪") == 0)
		{
			new Handle:menucompact = CreateMenu(MenuHandler5);
			
			SetMenuTitle(menucompact, "请选择玩家");
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
		if(strcmp(info, "五七手枪") == 0)
		{
			new Handle:menu57 = CreateMenu(MenuHandler6);
			
			SetMenuTitle(menu57, "请选择玩家");
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
		if(strcmp(info, "双拿手枪") == 0)
		{
			new Handle:menuelites = CreateMenu(MenuHandler7);
			
			SetMenuTitle(menuelites, "请选择玩家");
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
		if(strcmp(info, "M3 猎枪") == 0)
		{
			new Handle:menum3 = CreateMenu(MenuHandler8);
			
			SetMenuTitle(menum3, "请选择玩家");
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
		if(strcmp(info, "XM1014 自动猎枪") == 0)
		{
			new Handle:menuautoshotty = CreateMenu(MenuHandler9);
			
			SetMenuTitle(menuautoshotty, "请选择玩家");
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
		if(strcmp(info, "自动手枪") == 0)
		{
			new Handle:menumachinepistol = CreateMenu(MenuHandler10);
			
			SetMenuTitle(menumachinepistol, "请选择玩家");
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
		if(strcmp(info, "MAC-10 冲锋枪") == 0)
		{
			new Handle:menumac10 = CreateMenu(MenuHandler11);
			
			SetMenuTitle(menumac10, "请选择玩家");
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
		if(strcmp(info, "MP5 冲锋枪") == 0)
		{
			new Handle:menump5 = CreateMenu(MenuHandler12);
			
			SetMenuTitle(menump5, "请选择玩家");
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
		if(strcmp(info, "UMP 冲锋枪") == 0)
		{
			new Handle:menuump = CreateMenu(MenuHandler13);
			
			SetMenuTitle(menuump, "请选择玩家");
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
		if(strcmp(info, "P90 冲锋枪") == 0)
		{
			new Handle:menup90 = CreateMenu(MenuHandler14);
			
			SetMenuTitle(menup90, "请选择玩家");
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
		if(strcmp(info, "FAMAS 步枪") == 0)
		{
			new Handle:menuclarion = CreateMenu(MenuHandler15);
			
			SetMenuTitle(menuclarion, "请选择玩家");
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
		if(strcmp(info, "防守者步枪") == 0)
		{
			new Handle:menudefender = CreateMenu(MenuHandler16);
			
			SetMenuTitle(menudefender, "请选择玩家");
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
		if(strcmp(info, "侦察狙击步枪") == 0)
		{
			new Handle:menuscout = CreateMenu(MenuHandler17);
			
			SetMenuTitle(menuscout, "请选择玩家");
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
		if(strcmp(info, "AK-47 步枪") == 0)
		{
			new Handle:menuak47 = CreateMenu(MenuHandler18);
			
			SetMenuTitle(menuak47, "请选择玩家");
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
		if(strcmp(info, "M4A1 步枪") == 0)
		{
			new Handle:menum4a1 = CreateMenu(MenuHandler19);
			
			SetMenuTitle(menum4a1, "请选择玩家");
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
		if(strcmp(info, "AUG 步枪") == 0)
		{
			new Handle:menuaug = CreateMenu(MenuHandler20);
			
			SetMenuTitle(menuaug, "请选择玩家");
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
		if(strcmp(info, "Krieg 步枪") == 0)
		{
			new Handle:menukrieg = CreateMenu(MenuHandler21);
			
			SetMenuTitle(menukrieg, "请选择玩家");
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
		if(strcmp(info, "AWP 狙击步枪") == 0)
		{
			new Handle:menuawp = CreateMenu(MenuHandler22);
			
			SetMenuTitle(menuawp, "请选择玩家");
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
		if(strcmp(info, "SG550 (CT 自动狙击步枪)") == 0)
		{
			new Handle:menusg550 = CreateMenu(MenuHandler23);
			
			SetMenuTitle(menusg550, "请选择玩家");
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
		if(strcmp(info, "G3SG1 (T 自动狙击步枪)") == 0)
		{
			new Handle:menug3sg1 = CreateMenu(MenuHandler24);
			
			SetMenuTitle(menug3sg1, "请选择玩家");
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
		if(strcmp(info, "机枪") == 0)
		{
			new Handle:menumachine = CreateMenu(MenuHandler25);
			
			SetMenuTitle(menumachine, "请选择玩家");
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
		if(strcmp(info, "刀子") == 0)
		{
			new Handle:menuknife = CreateMenu(MenuHandler26);
			
			SetMenuTitle(menuknife, "请选择玩家");
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
		if(strcmp(info, "手榴弹") == 0)
		{
			new Handle:menugrenade = CreateMenu(MenuHandler27);
			
			SetMenuTitle(menugrenade, "请选择玩家");
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
		if(strcmp(info, "闪光弹") == 0)
		{
			new Handle:menuflashbang = CreateMenu(MenuHandler28);
			
			SetMenuTitle(menuflashbang, "请选择玩家");
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
		if(strcmp(info, "烟雾弹") == 0)
		{
			new Handle:menusmoke = CreateMenu(MenuHandler29);
			
			SetMenuTitle(menusmoke, "请选择玩家");
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
		if(strcmp(info, "安全套装") == 0)
		{
			new Handle:menukevlar = CreateMenu(MenuHandler30);
			
			SetMenuTitle(menukevlar, "请选择玩家");
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
		if(strcmp(info, "安全套装和安全帽") == 0)
		{
			new Handle:menukevhelm = CreateMenu(MenuHandler31);
			
			SetMenuTitle(menukevhelm, "请选择玩家");
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
		if(strcmp(info, "C4 定时炸弹") == 0)
		{
			new Handle:menuc4 = CreateMenu(MenuHandler32);
			
			SetMenuTitle(menuc4, "请选择玩家");
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
		if(strcmp(info, "定时炸弹停止器") == 0)
		{
			new Handle:menudefuser = CreateMenu(MenuHandler33);
			
			SetMenuTitle(menudefuser, "请选择玩家");
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
		if(strcmp(info, "夜视镜") == 0)
		{
			new Handle:menunight = CreateMenu(MenuHandler34);
			
			SetMenuTitle(menunight, "请选择玩家");
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
		if(strcmp(info, "饼干") == 0)
		{
			new Handle:menucookies = CreateMenu(MenuHandler35);
			
			SetMenuTitle(menucookies, "请选择玩家");
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04Glock", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04USP 手枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04沙漠老鹰手枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04P228 手枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04五七手枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04双拿手枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04M3 猎枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04XM1014 自动猎枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04自动手枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04MAC-10 冲锋枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04MP5 冲锋枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04UMP 冲锋枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04P90 冲锋枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04FAMAS 步枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04防守者步枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04侦察狙击步枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04AK-47 步枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04M4A1 步枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04AUG 步枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04Krieg 步枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04AWP 狙击步枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04SG550 自动狙击步枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04G3SG1 自动狙击步枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04机枪", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04刀子", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04手榴弹", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04闪光弹", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04烟雾弹", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04安全套装", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04安全套装和安全帽", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04C4 定时炸弹", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04定时炸弹停止器", namegiver, namereceiver);
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
					PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04夜视镜", namegiver, namereceiver);
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
				PrintToChatAll("\x01[管理员] \x03%s \x01给了 \x03%s \x04饼干", namegiver, namereceiver);
				DisplayMenu(menucookies, client, 0);
			}
			}
		}
	}
}