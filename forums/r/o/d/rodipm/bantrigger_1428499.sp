#include <sourcemod>
#include <cstrike>
#include <sdktools>

public Plugin:myinfo =
{
	name = "BanTrigger",
	author = "RpM",
	description = "Bane Um Player Atirando Nele",
	version = "1.0",
	url = "www.LiquidBR.com"
};

new bool:bantriggeron = false;
new adm;
new String:tname[70];
new attacker;
new target;

public OnPluginStart()
{
	RegAdminCmd("bantrigger", bantrigger, ADMFLAG_BAN, "Ativa A Arma Para Dar O Ban");
	HookEvent("weapon_fire", weapon_fire);
}

public Action:bantrigger(client, args)
{
	if(bantriggeron == false)
	{
		adm = GetClientOfUserId(GetClientUserId(client));
		bantriggeron = true;
		PrintHintText(client, "BanTrigger Ativado");
	}
	else if(bantriggeron == true)
	{
		bantriggeron = false;
		PrintHintText(client, "BanTrigger Desativado");
	}
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if(action == MenuAction_End) {
		CloseHandle(menu);
	} else if(action == MenuAction_Select) {
		new String:menu_item_title[50];
		GetMenuItem(menu, param2, menu_item_title, sizeof(menu_item_title));
		if(StrEqual(menu_item_title, "0")) {
			BanClient(target, 0, BANFLAG_AUTHID, "BanTrigger: Permanente", "Banido Pelo BanTrigger");
			bantriggeron = false;
			PrintHintText(adm, "BanTrigger Desativado");
			
		} else if(StrEqual(menu_item_title, "30")) {
			BanClient(target, 30, BANFLAG_AUTHID, "BanTrigger: 30 minutos", "Banido Pelo BanTrigger");
			bantriggeron = false;
			PrintHintText(adm, "BanTrigger Desativado");
			
		} else if(StrEqual(menu_item_title, "60")) {
			BanClient(target, 60, BANFLAG_AUTHID, "BanTrigger: 1 hora", "Banido Pelo BanTrigger");
			bantriggeron = false;
			PrintHintText(adm, "BanTrigger Desativado");
			
		} else if(StrEqual(menu_item_title, "1440")) {
			BanClient(target, 1440, BANFLAG_AUTHID, "BanTrigger: 1 dia", "Banido Pelo BanTrigger");
			bantriggeron = false;
			PrintHintText(adm, "BanTrigger Desativado");
			
		} else if(StrEqual(menu_item_title, "10080")) {
			BanClient(target, 10080, BANFLAG_AUTHID, "BanTrigger: 1 semana", "Banido Pelo BanTrigger");
			bantriggeron = false;
			PrintHintText(adm, "BanTrigger Desativado");
		}
	}
}

public Action:weapon_fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bantriggeron == true)
	{
		attacker = GetClientOfUserId(GetEventInt(event, "userid"));
		if(attacker == adm)
		{
			target = GetClientAimTarget(attacker, true);
			GetClientName(target, tname, sizeof(tname));
			
			new Handle:menu = CreateMenu(MenuHandler);
			SetMenuTitle(menu, "Ban: %s", tname);
			AddMenuItem(menu, "0", "Permanente");
			AddMenuItem(menu, "30", "30 Minutos");
			AddMenuItem(menu, "60", "1 Hora");
			AddMenuItem(menu, "1440", "1 Dia");
			AddMenuItem(menu, "10080", "1 Semana");
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, attacker, 20);

		}	
	}
}