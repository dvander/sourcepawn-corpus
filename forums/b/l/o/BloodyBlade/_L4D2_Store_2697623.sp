#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "Shop", 
	author = "Перевод L4D2noob.ru, Автор - Explait", 
	description = "Shop", 
	version = "1.3", 
	url = "https://l4d2noob.ru/"
}

int g_iCredits[MAXPLAYERS + 1];
int cooldownTimes[MAXPLAYERS + 1] = {-1, ...};

int ZombieKilled = 1;
int InfectedKilled = 2;
int WitchKilled = 3;
int TankKilled = 4;

public void OnPluginStart()
{
	RegConsoleCmd("sm_shop", HinT);
	RegConsoleCmd("sm_pay", Pay);
	HookEvent("witch_killed", witch_killed);
	HookEvent("infected_death", infected_death);
	HookEvent("player_death", player_death);
	RegAdminCmd("sm_givemoney", GiveMoney, ADMFLAG_SLAY);
	HookEvent("tank_killed", tank_killed);
}

public void OnClientPutInServer(int client)
{
    cooldownTimes[client] = -1;
}

public Action HinT(int client, int args) // создаем функцию для комманды)
{
        // Timer
    int currentTime = GetTime();
    if (cooldownTimes[client] != -1 && cooldownTimes[client] > currentTime)
    {
        ReplyToCommand(client, "Эй, ты слишком часто используешь магазин, подожди ка!");
        return Plugin_Handled;
    }
    
    cooldownTimes[client] = currentTime + 90;
    //End Timer

    Menu menu = CreateMenu(MeleeMenuHandler);
    SetMenuTitle(menu, "Твои деньги %d", g_iCredits[client]);

    AddMenuItem(menu, "option1", "Оружие");
    AddMenuItem(menu, "option2", "Рукопашное");
    AddMenuItem(menu, "option3", "Остальное");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
    SetMenuExitButton(menu, true);

    return Plugin_Handled;
}

public Action GiveMoney(int client, int args)
{
	char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int target = FindTarget(client, arg1);
	int money = 0;
	money = StringToInt(arg2);

	if (args != 2)
	{
		PrintToChat(client, "[L4D2Noob.RU] Используй: !givemoney <player> <money>");
	}

	g_iCredits[target] += money;
	char name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	PrintToChat(client, "[L4D2Noob.RU] Ты передал %i %s", money, name);
}

public void witch_killed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char sname[32];
	GetClientName(client, sname, 32);
	g_iCredits[client] += WitchKilled;
}

public void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	g_iCredits[attacker] += InfectedKilled;
}

public void infected_death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	g_iCredits[attacker] += ZombieKilled;
}

public void tank_killed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char nname[32];
	GetClientName(client, nname, 32);
	g_iCredits[client] = TankKilled;
}

public int MeleeMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));

			if (StrEqual(item, "option1"))
			{
				Menu wmenu = CreateMenu(Weapon_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
				SetMenuTitle(wmenu, "Оружие (Твои деньги: %i)", g_iCredits[param1]);

				AddMenuItem(wmenu, "option1", "Магнум - 150");
				AddMenuItem(wmenu, "option2", "Автоматический дробовик - 400");
				AddMenuItem(wmenu, "option3", "Снайперская винтовка - 400");
				AddMenuItem(wmenu, "option4", "Военный дробовик SPAS - 400");
				AddMenuItem(wmenu, "option5", "Дробовик - $ 300");
				AddMenuItem(wmenu, "option6", "Хромированный дробовик - 260");
				AddMenuItem(wmenu, "option7", "Пистолет-пулемёт UZI - 250");
				AddMenuItem(wmenu, "option8", "MAC-10 с глушителем - 260");
				AddMenuItem(wmenu, "option9", "AK-47 - $ 500");
				AddMenuItem(wmenu, "option10", "M16 - $ 510");
				AddMenuItem(wmenu, "option11", "M60 - $ 1000");
				AddMenuItem(wmenu, "option12", "Охотничья винтовка - 300");
				AddMenuItem(wmenu, "option13", "FN SCAR-L - 300");
				AddMenuItem(wmenu, "option14", "Гранатомёт - 500");
				SetMenuExitButton(wmenu, true);

				DisplayMenu(wmenu, param1, MENU_TIME_FOREVER);
			}
			if (StrEqual(item, "option2"))
			{
			    Menu mmenu = CreateMenu(Melee_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			    SetMenuTitle(mmenu, "Рукопашное (Твои деньги: %i)", g_iCredits[param1]);
			    AddMenuItem(mmenu, "option1", "Бензопила - 300");
			    AddMenuItem(mmenu, "option2", "Катана - 300");
			    AddMenuItem(mmenu, "option3", "Мачете - 300");
			    AddMenuItem(mmenu, "option4", "Полицейская дубинка - 300");
			    AddMenuItem(mmenu, "option5", "Гитара - 300");
			    SetMenuExitButton(mmenu, true);

			    DisplayMenu(mmenu, param1, MENU_TIME_FOREVER);
			}
			if (StrEqual(item, "option3"))
			{
				Menu omenu = CreateMenu(Other_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
				SetMenuTitle(omenu, "Остальное (Твои деньги: %i)", g_iCredits[param1]);
				AddMenuItem(omenu, "option1", "Аптечка - 100");
				AddMenuItem(omenu, "option2", "Адреналин - 60");
				AddMenuItem(omenu, "option3", "Таблетки - 50");
				AddMenuItem(omenu, "option4", "Патроны - 200");
				AddMenuItem(omenu, "option5", "Бомба - 90");
				AddMenuItem(omenu, "option6", "Молотов - 110");
				AddMenuItem(omenu, "option7", "Блевотина - 120");
				SetMenuExitButton(omenu, true);

				DisplayMenu(omenu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

public Action Pay(int client, int args)
{
	char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int paymoney = 0;
	paymoney = StringToInt(arg2);
	int target = FindTarget(client, arg1);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	if (args != 2)
	{
		ReplyToCommand(client, "[L4D2Noob.RU] используй: !pay <name> <money>");
	}
	g_iCredits[target] += paymoney;
	g_iCredits[client] -= paymoney;
	PrintToChat(target, "[L4D2Noob.RU] %s передал тебе %i", client, paymoney);
	PrintToChat(client, "[L4D2Noob.RU] Спасибо за платеж!: %i", paymoney);
	return Plugin_Handled;
}

/*public int Weapon_Menu_Handler(Menu weaponmenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[64];
			GetMenuItem(weaponmenu, param2, item, sizeof(item))

			if (StrEqual(item, "Оружие"))
			{
				Menu menu = CreateMenu(Weapon_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
				SetMenuTitle(menu, "Оружие");

				AddMenuItem(menu, "option1", "Магнум - 150");
				AddMenuItem(menu, "option2", "Автоматический дробовик - 400");
				AddMenuItem(menu, "option3", "Снайперская винтовка - 400");
				AddMenuItem(menu, "option4", "Военный дробовик SPAS - 400");
				AddMenuItem(menu, "option5", "Дробовик - $ 300");
				AddMenuItem(menu, "option6", "Хромированный дробовик - 260");
				AddMenuItem(menu, "option7", "Пистолет-пулемёт UZI - 250");
				AddMenuItem(menu, "option8", "MAC-10 с глушителем - 260");
				AddMenuItem(menu, "option9", "AK-47 - 500");
				AddMenuItem(menu, "option10", "M16 - 510");
				AddMenuItem(menu, "option11", "M60 - 1000");
				AddMenuItem(menu, "option12", "Охотничья винтовка - 300");
				AddMenuItem(menu, "option13", "FN SCAR-L - 300");
				AddMenuItem(menu, "option14", "Гранатомёт - 500");
				SetMenuExitButton(menu, true);

				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

public int Other_Menu_Handler(Menu othermenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[64];
			GetMenuItem(othermenu, param2, item, sizeof(item))

			if (StrEqual(item, "Остальное"))
			{
				Menu menu = CreateMenu(Other_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
				SetMenuTitle(menu, "Остальное");
				AddMenuItem(menu, "option1", "Аптечка - 100");
				AddMenuItem(menu, "option2", "Адреналин - 60");
				AddMenuItem(menu, "option3", "Таблетки - 50");
				AddMenuItem(menu, "option4", "Патроны - 200");
				AddMenuItem(menu, "option5", "Бомба - 90");
				AddMenuItem(menu, "option6", "Молотов - 110");
				AddMenuItem(menu, "option7", "Блевотина - 120");
				SetMenuExitButton(menu, true);
				
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

public int Melee_Menu_Handler(Menu meleemenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[64];
			GetMenuItem(meleemenu, param2, item, sizeof(item))
			
			if (StrEqual(item, "Рукопашное"))
			{
			    Menu menu = CreateMenu(Melee_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
				SetMenuTitle(menu, "Melee");
			    AddMenuItem(menu, "option1", "Бензопила - 300");
			    AddMenuItem(menu, "option2", "Катана - 300");
			    AddMenuItem(menu, "option3", "Мачете - 300");
			    AddMenuItem(menu, "option4", "Полицейская дубинка - 300");
			    AddMenuItem(menu, "option5", "Гитара - 300");
				SetMenuExitButton(menu, true);

				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}
*/

public int Weapon_Menu_Handle(Menu wmenu, MenuAction action, int client, int Position)
{
	int flagszspawn = GetCommandFlags("give");
	SetCommandFlags("give", flagszspawn & ~FCVAR_CHEAT);
	char Item[32];
	wmenu.GetItem(Position, Item, sizeof(Item));
	wmenu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	if (action == MenuAction_Select)
	{
		if (StrEqual(Item, "option1"))
		{
			if (g_iCredits[client] >= 150)
			{
				FakeClientCommand(client, "give pistol_magnum");
				g_iCredits[client] -= 150;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 150", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option2"))
		{
			if (g_iCredits[client] >= 400)
			{
				FakeClientCommand(client, "give autoshotgun");
				g_iCredits[client] -= 400;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 400", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option3"))
		{
			if (g_iCredits[client] >= 400)
			{
				FakeClientCommand(client, "give sniper_military");
				g_iCredits[client] -= 400;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 400", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option4"))
		{
			if (g_iCredits[client] >= 400)
			{
				FakeClientCommand(client, "give shotgun_spas");
				g_iCredits[client] -= 400;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 400", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option5"))
		{
			if (g_iCredits[client] >= 300)
			{
				FakeClientCommand(client, "give pumpshotgun");
				g_iCredits[client] -= 300;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 300", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option6"))
		{
			if (g_iCredits[client] >= 260)
			{
				FakeClientCommand(client, "give shotgun_chrome");
				g_iCredits[client] -= 260;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 260", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option7"))
		{
			if (g_iCredits[client] >= 250)
			{
				FakeClientCommand(client, "give smg");
				g_iCredits[client] -= 250;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 250", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option8"))
		{
			if (g_iCredits[client] >= 260)
			{
				FakeClientCommand(client, "give smg_silenced");
				g_iCredits[client] -= 260;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 260", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option9"))
		{
			if (g_iCredits[client] >= 500)
			{
				FakeClientCommand(client, "give rifle_ak47");
				g_iCredits[client] -= 500;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 500", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option10"))
		{
			if (g_iCredits[client] >= 510)
			{
				FakeClientCommand(client, "give rifle");
				g_iCredits[client] -= 510;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 510", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option11"))
		{
			if (g_iCredits[client] >= 1000)
			{
				FakeClientCommand(client, "give rifle_m60");
				g_iCredits[client] -= 1000;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 1000", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option12"))
		{
			if (g_iCredits[client] >= 300)
			{
				FakeClientCommand(client, "give hunting_rifle");
				g_iCredits[client] -= 300;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 300", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option13"))
		{
			if (g_iCredits[client] >= 300)
			{
				FakeClientCommand(client, "give rifle_desert");
				g_iCredits[client] -= 300;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 300", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option14"))
		{
			if (g_iCredits[client] >= 500)
			{
				FakeClientCommand(client, "give weapon_grenade_launcher");
				g_iCredits[client] -= 500;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 500", g_iCredits[client]);
			}
		}
	}
	SetCommandFlags("give", flagszspawn | FCVAR_CHEAT);
}

public int Melee_Menu_Handle(Menu mmenu, MenuAction action, int client, int Position)
{
	int flagszspawn = GetCommandFlags("give");
	SetCommandFlags("give", flagszspawn & ~FCVAR_CHEAT);
	char Item[32];
	mmenu.GetItem(Position, Item, sizeof(Item));
	mmenu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	if (action == MenuAction_Select)
	{
		if (StrEqual(Item, "option1"))
		{
			if (g_iCredits[client] >= 300)
			{
				FakeClientCommand(client, "give chainsaw");
				g_iCredits[client] -= 300;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 300", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option2"))
		{
			if (g_iCredits[client] >= 300)
			{
				FakeClientCommand(client, "give katana");
				g_iCredits[client] -= 300;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 300", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option3"))
		{
			if (g_iCredits[client] >= 300)
			{
				FakeClientCommand(client, "give machete");
				g_iCredits[client] -= 300;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 300", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option4"))
		{
			if (g_iCredits[client] >= 300)
			{
				FakeClientCommand(client, "give tonfa");
				g_iCredits[client] -= 300;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 300", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option5"))
		{
			if (g_iCredits[client] >= 300)
			{
				FakeClientCommand(client, "give electric_guitar");
				g_iCredits[client] -= 300;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 300", g_iCredits[client]);
			}
		}
	}
	SetCommandFlags("give", flagszspawn | FCVAR_CHEAT);
}

public int Other_Menu_Handle(Menu omenu, MenuAction action, int client, int Position)
{
	int flagszspawn = GetCommandFlags("give");
	SetCommandFlags("give", flagszspawn & ~FCVAR_CHEAT);
	char Item[32];
	omenu.GetItem(Position, Item, sizeof(Item));
	omenu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	if (action == MenuAction_Select)
	{
		if (StrEqual(Item, "option1"))
		{
			if (g_iCredits[client] >= 100)
			{
				FakeClientCommand(client, "give first_aid_kit");
				g_iCredits[client] -= 100;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 100", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option2"))
		{
			if (g_iCredits[client] >= 60)
			{
				FakeClientCommand(client, "give adrenaline");
				g_iCredits[client] -= 60;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 60", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option3"))
		{
			if (g_iCredits[client] >= 50)
			{
				FakeClientCommand(client, "give pain_pills");
				g_iCredits[client] -= 50;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 50", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option4"))
		{
			if (g_iCredits[client] >= 200)
			{
				FakeClientCommand(client, "give ammo");
				g_iCredits[client] -= 200;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 200", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option5"))
		{
			if (g_iCredits[client] >= 90)
			{
				FakeClientCommand(client, "give pipe_bomb");
				g_iCredits[client] -= 90;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 90", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option6"))
		{
			if (g_iCredits[client] >= 110)
			{
				FakeClientCommand(client, "give molotov");
				g_iCredits[client] -= 110;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 110", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option7"))
		{
			if (g_iCredits[client] >= 120)
			{
				FakeClientCommand(client, "give vomitjar");
				g_iCredits[client] -= 120;
			}
			else
			{
				PrintToChat(client, "[L4D2Noob.RU] Твои деньги: %i (Тебе не хватает денег! Надо 120", g_iCredits[client]);
			}
		}
	}
	SetCommandFlags("give", flagszspawn | FCVAR_CHEAT);
}