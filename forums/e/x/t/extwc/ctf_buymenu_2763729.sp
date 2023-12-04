#include <sourcemod>
#include <cstrike>
#include <sdktools>

#define HEGRENADE_OFFSET 14
#define FLASHBANG_OFFSET 15
#define SMOKE_OFFSET 16
#define MOLOTOV_OFFSET 17
#define DECOY_OFFSET 18

#define LoopAllPlayers(%1) for(int %1=1;%1<=MaxClients;++%1)\
if(IsClientInGame(%1))

bool b_DisableAutoBuymenu[MAXPLAYERS + 1];
bool b_AutoRebuy[MAXPLAYERS + 1];
bool b_HEAlreadyBought[MAXPLAYERS + 1];
bool b_FBAlreadyBought[MAXPLAYERS + 1];
bool b_DCAlreadyBought[MAXPLAYERS + 1];
bool b_SGAlreadyBought[MAXPLAYERS + 1];
bool b_MLAlreadyBought[MAXPLAYERS + 1];

char g_IsMenuBuyPrim[MAXPLAYERS + 1][64];
char g_IsMenuBuySec[MAXPLAYERS + 1][64];
char g_IsMenuBuyTaser[MAXPLAYERS + 1][64];
char g_IsMenuBuyArmor[MAXPLAYERS + 1][64];
char g_IsMenuBuyItem1[MAXPLAYERS + 1][64];
char g_IsMenuBuyItem2[MAXPLAYERS + 1][64];
char g_IsMenuBuyItem3[MAXPLAYERS + 1][64];
char g_IsMenuBuyItem4[MAXPLAYERS + 1][64];
char g_IsMenuBuyItem5[MAXPLAYERS + 1][64];
char g_IsMenuBuyItem6[MAXPLAYERS + 1][64];

public Plugin myinfo = 
{
	name = "Custom Buy Menu",
	author = "extwc",
	description = "Allows both teams to buy any weapon",
	version = "1.0",
	url = "https://discord.com/invite/yMZC878uSj"
};

public void OnPluginStart()
{
	RegConsoleCmd("buy", 				CMD_buy,		"Buy Cmd");
	AddCommandListener(CMD_BuyMenu, "open_buymenu");
	HookEvent("player_spawn", 	CTF_PlayerSpawn);
}

public void OnClientDisconnect(int client)
{
	Buymenu_ClearAll(client);
}

public void OnClientPutInServer(int client)
{
	Buymenu_ClearAll(client);
}

public Action CTF_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client))
		Buymenu_OnPlayerSpawn(client);
}

public Action:CMD_BuyMenu(client, const String:cmd[], argc)
{
	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
		{
			if(IsPlayerAlive(client))
			{
				ClientCommand(client, "buymenu");
				
				if(b_AutoRebuy[client])
					ShowRebuyMenu(client);
				else
				{
					char Msg[150];
					Format(Msg, sizeof(Msg),"<font size='22' color='#4a75b5'> [Buymenu] Activado. </font>");
					PrintHintText(client, Msg);
					b_DisableAutoBuymenu[client] = false;
					ShowWeaponsMenu(client);
				}
			}
			// Cant be used by dead players
		}
		// Cant be used by spectators
	}
	return Plugin_Handled;
}

public Buymenu_OnPlayerSpawn(client)
{
	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
		{
			if(IsPlayerAlive(client))
			{
				Buymenu_ClearGnd(client);
				
				if(!b_DisableAutoBuymenu[client])
					ShowWeaponsMenu(client);
				else 
				{
					if(b_AutoRebuy[client])
					{
						char Msg[150];
						Format(Msg, sizeof(Msg),"<font size='22' color='#A30000'>[Rebuy] Automatico.</font> Podes desactivarlo con la tecla de Compras.");
						PrintHintText(client, Msg);
						
						CreateTimer(1.0, GiveRebuy, client);
					}
					else
					{
						char Msg[150];
						Format(Msg, sizeof(Msg),"<font size='22' color='#4a75b5'>[Buymenu] Desactivado.</font> Podes activarlo con la tecla de Compras.");
						PrintHintText(client, Msg);
					}
				}
			}
		}
	}
	return;
}

public Action:GiveRebuy(Handle tmr, client)
{
	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
		{
			if(IsPlayerAlive(client))
			{
				Buymenu_Give(client, g_IsMenuBuyPrim[client], false);
				Buymenu_Give(client, g_IsMenuBuySec[client], false);
				Buymenu_Give(client, g_IsMenuBuyArmor[client], false);
				Buymenu_Give(client, g_IsMenuBuyItem1[client], false);
				Buymenu_Give(client, g_IsMenuBuyItem2[client], false);
				Buymenu_Give(client, g_IsMenuBuyItem3[client], false);
				Buymenu_Give(client, g_IsMenuBuyItem4[client], false);
				Buymenu_Give(client, g_IsMenuBuyItem5[client], false);
				Buymenu_Give(client, g_IsMenuBuyItem6[client], false);
				Buymenu_Give(client, g_IsMenuBuyTaser[client], false);
			}
		}
	}
}

void ShowRebuyMenu(int client)
{
	Menu menu = new Menu(Buymenu_HandleOptions);
	SetMenuTitle(menu, "¿Abrir menu de compra?\nSi tenias rebuy activado.\nEste se desactivara.");
	
	menu.AddItem("buy_enable", 			"Si");
	menu.AddItem("exit", 				"No");
	SetMenuExitButton(menu, false);
	menu.Display(client, 0);
}

void ShowWeaponsMenu(int client)
{
	Menu menu = new Menu(Buymenu_HandleOptions);
	SetMenuTitle(menu, "Menu de compra:");
	
	menu.AddItem("weapons_1", 				"Arma primaria");
	menu.AddItem("weapons_2", 				"Arma secundaria\n");
	menu.AddItem("items", 					"Utilidades\n");
	if(StrEqual(g_IsMenuBuyPrim[client], "") && StrEqual(g_IsMenuBuySec[client], "") && StrEqual(g_IsMenuBuyTaser[client], "") && StrEqual(g_IsMenuBuyArmor[client], "") && StrEqual(g_IsMenuBuyItem1[client], "") && StrEqual(g_IsMenuBuyItem2[client], "") && StrEqual(g_IsMenuBuyItem3[client], "") && StrEqual(g_IsMenuBuyItem4[client], "") && StrEqual(g_IsMenuBuyItem5[client], "") && StrEqual(g_IsMenuBuyItem6[client], ""))
	menu.AddItem("exit", 					"No comprar esta vez.");
	else
	menu.AddItem("exit", 					"Finalizar compra.");
	if(StrEqual(g_IsMenuBuyPrim[client], "") && StrEqual(g_IsMenuBuySec[client], "") && StrEqual(g_IsMenuBuyTaser[client], "") && StrEqual(g_IsMenuBuyArmor[client], "") && StrEqual(g_IsMenuBuyItem1[client], "") && StrEqual(g_IsMenuBuyItem2[client], "") && StrEqual(g_IsMenuBuyItem3[client], "") && StrEqual(g_IsMenuBuyItem4[client], "") && StrEqual(g_IsMenuBuyItem5[client], "") && StrEqual(g_IsMenuBuyItem6[client], ""))
	menu.AddItem("exit_and_disable", 		"No comprar. (No mostrar de nuevo)");
	else
	menu.AddItem("rebuy_and_disable", 		"Rebuy, (No mostrar de nuevo)");
	SetMenuExitButton(menu, false);
	menu.Display(client, 0);
}

void ShowWeapons1Menu(int client)
{
	Menu menu = new Menu(Buymenu_HandleOptions);
	SetMenuTitle(menu, "Menu de compra:");
	
	menu.AddItem("buy", 					"Volver");
	menu.AddItem("weapon_galilar", 			"Galil - $2000");
	menu.AddItem("weapon_famas", 			"Famas - $2250");
	menu.AddItem("weapon_ak47", 			"AK-47 - $2500");
	menu.AddItem("weapon_m4a1", 			"M4A1 - $2900");
	menu.AddItem("weapon_aug", 				"AUG - $3500");
	menu.AddItem("weapon_sg556", 			"SG556 - $3500");
	menu.AddItem("weapon_m4a1_silencer", 	"M4A1-S - $3100");
	menu.AddItem("weapon_ssg08", 			"Scout - $3800");
	menu.AddItem("weapon_awp", 				"AWP - $8000");
	menu.AddItem("weapon_g3sg1", 			"G3SG1 - $6000");
	menu.AddItem("weapon_scar20", 			"SCAR20 - $6000");
	menu.AddItem("weapon_negev", 			"NEGEV");
	menu.AddItem("weapon_mp7", 				"MP7 - $1250");
	menu.AddItem("weapon_mac10", 			"MAC10 - $1400");
	menu.AddItem("weapon_mp5sd",			"MP5: Silencer - $1500");
	menu.AddItem("weapon_ump45", 			"UMP-45 - $1700");
	menu.AddItem("weapon_p90", 				"P90 - $2350");
	menu.AddItem("weapon_mp9", 				"MP9 - $1250");
	menu.AddItem("weapon_bizon", 			"Bizon - $2500");
	menu.AddItem("weapon_nova", 			"Nova - $1700");
	menu.AddItem("weapon_xm1014", 			"XM1014 - $3000");
	menu.AddItem("weapon_mag7",				"MAG7 - $3000");
	menu.AddItem("weapon_m249", 			"M249 - $3000");
	SetMenuExitButton(menu, false);
	menu.Display(client, 0);
}

void ShowWeapons2Menu(int client)
{
	Menu menu = new Menu(Buymenu_HandleOptions);
	SetMenuTitle(menu, "Menu de compra:");
	
	menu.AddItem("buy", 				"Volver");
	menu.AddItem("weapon_glock", 		"Glock - $400");
	menu.AddItem("weapon_hkp2000", 		"USP - $500");
	menu.AddItem("weapon_p250", 		"P250 - $600");
	menu.AddItem("weapon_deagle", 		"Deagle - $650");
	menu.AddItem("weapon_fiveseven",	"Fiveseven - $750");
	menu.AddItem("weapon_elite", 		"Dual burretas - $750");
	menu.AddItem("weapon_revolver", 	"Revolver - $800");
	menu.AddItem("weapon_tec9", 		"TEC-9 - $1000");
	menu.AddItem("weapon_cz75a",		"cz75a - $1200");
	menu.AddItem("weapon_usp_silencer",	"USP: Silencer - $500");
	SetMenuExitButton(menu, false);
	menu.Display(client, 0);
}

void ShowItemsMenu(int client)
{
	Menu menu = new Menu(Buymenu_HandleOptions);
	SetMenuTitle(menu, "Menu de compra:");
	
	menu.AddItem("buy", 						"Volver");
	menu.AddItem("item_vesthelm",				"Chaleco y casco - $1000");
	menu.AddItem("item_kevlar",					"Chaleco solo - $650");
	
	if(!b_HEAlreadyBought[client])
		menu.AddItem("weapon_hegrenade",			"HE Grenade - $300");
	else
		menu.AddItem("weapon_hegrenade",			"HE disponible en el proximo respawn.");
	if(!b_FBAlreadyBought[client])
		menu.AddItem("weapon_flashbang",			"Flashbang - $200");
	else
		menu.AddItem("weapon_flashbang",			"FB disponible en el proximo respawn.");
	if(!b_DCAlreadyBought[client])
		menu.AddItem("weapon_decoy",				"Decoy - $50");
	else
		menu.AddItem("weapon_decoy",				"Decoy disponible en el proximo respawn.");
	if(!b_SGAlreadyBought[client])
		menu.AddItem("weapon_smokegrenade",		"Smoke - $100");
	else
		menu.AddItem("weapon_smokegrenade",		"SG disponible en el proximo respawn.");
	if(!b_MLAlreadyBought[client])
		menu.AddItem("weapon_molotov",			"Molotov - $400");
	else
		menu.AddItem("weapon_molotov",			"Molo disponible en el proximo respawn.");
	
	menu.AddItem("weapon_taser",				"Taser - $200");
	
	SetMenuExitButton(menu, false);
	menu.Display(client, 0);
}

public int Buymenu_HandleOptions(Menu menu, MenuAction action, int client, int item) 
{
	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
		{
			if (IsPlayerAlive(client))
			{
				switch(action)
				{
					case MenuAction_Select:
					{
						char info[32];
						GetMenuItem(menu, item, info, sizeof(info));
						
						if(StrEqual(info, "exit"))
						{
							return;
						}
						else if(StrEqual(info, "exit_and_disable"))
						{
							b_DisableAutoBuymenu[client] = true;
							char Msg[150];
							Format(Msg, sizeof(Msg),"<font size='22' color='#4a75b5'>[Buymenu] Desactivado.</font> Podes activarlo con la tecla de Compras.");
							PrintHintText(client, Msg);
							return;
						}
						else if(StrEqual(info, "rebuy_and_disable"))
						{
							b_DisableAutoBuymenu[client] = true;
							b_AutoRebuy[client] = true;
							char Msg[150];
							Format(Msg, sizeof(Msg),"<font size='22' color='#A30000'>[Rebuy] Automatico.</font> Podes desactivarlo con la tecla de Compras.");
							PrintHintText(client, Msg);
							return;
						}
						else if(StrEqual(info, "buy_enable"))
						{
							PrintHintText(client, "<font size='22' color='#4a75b5'>[Buymenu] Activado.</font> <font size='22' color='#A30000'>[Rebuy] Desactivado.</font>\n(Se vacio el historial de compra)");
							Buymenu_ClearAll(client);
							ShowWeaponsMenu(client);
						}
						else if(StrEqual(info, "buy"))
							ShowWeaponsMenu(client);
						else if(StrEqual(info, "weapons_1"))
							ShowWeapons1Menu(client);
						else if(StrEqual(info, "weapons_2"))
							ShowWeapons2Menu(client);
						else if(StrEqual(info, "items"))
							ShowItemsMenu(client);
						else
						{
							Buymenu_Give(client, info, true);
						}
					}
				}
			}
			// Cant be used by dead players
		}
		// Cant be used by spectators
	}
	return;
}

public Action:CMD_buy(int client, int args) 
{
	if(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
	{
		if(IsPlayerAlive(client))
		{
			char info[32];
			GetCmdArg(args, info, sizeof(info));
			
			char weapon[32];
			if(StrEqual(info, "kevlar") || StrEqual(info, "vesthelm"))
			{
				Format(weapon, sizeof(weapon), "item_%s", info);
			}
			else
				Format(weapon, sizeof(weapon), "weapon_%s", info);
	
			if(StrEqual(weapon, "weapon_29"))
				Format(weapon, sizeof(weapon), "weapon_hegrenade");
				
			if(StrEqual(weapon, "weapon_28"))
				Format(weapon, sizeof(weapon), "weapon_flashbang");
				
			if(StrEqual(weapon, "weapon_27"))
				Format(weapon, sizeof(weapon), "weapon_decoy");

			Buymenu_Give(client, weapon, false);
		}
	}
	return Plugin_Handled;
}

public Action:Buymenu_Give(int client, char[] weapon, bool isMenu)
{
	new i_clientmoney = GetMoney(client);
	new w_cost = 0;
	new w_primary = 0;
	new w_secondary = 0;
	new w_taser = 0;
	new w_item = 0;

	int slot1 = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	int slot2 = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	
	if(StrEqual(weapon, "weapon_galilar") || StrEqual(weapon, "weapon_galil"))
	{
		w_primary = 1;
		w_cost = 2000;
	}
	else if(StrEqual(weapon, "weapon_famas"))
	{
		w_primary = 1;
		w_cost = 2250;
	}
	else if(StrEqual(weapon, "weapon_ak47"))
	{
		w_primary = 1;
		w_cost = 2500;
	}
	else if(StrEqual(weapon, "weapon_m4a1"))
	{
		w_primary = 1;
		w_cost = 2900;
	}
	else if(StrEqual(weapon, "weapon_aug"))
	{
		w_primary = 1;
		w_cost = 3500;
	}
	else if(StrEqual(weapon, "weapon_sg556"))
	{
		w_primary = 1;
		w_cost = 3500;
	}
	else if(StrEqual(weapon, "weapon_m4a1_silencer"))
	{
		w_primary = 1;
		w_cost = 3100;
	}
	else if(StrEqual(weapon, "weapon_ssg08"))
	{
		w_primary = 1;
		w_cost = 3800;
	}
	else if(StrEqual(weapon, "weapon_awp"))
	{
		w_primary = 1;
		w_cost = 8000;
	}
	else if(StrEqual(weapon, "weapon_g3sg1"))
	{
		w_primary = 1;
		w_cost = 6000;
	}
	else if(StrEqual(weapon, "weapon_scar20"))
	{
		w_primary = 1;
		w_cost = 6000;
	}
	else if(StrEqual(weapon, "weapon_negev"))
	{
		w_primary = 1;
		w_cost = 4000;
	}
	else if(StrEqual(weapon, "weapon_mp7"))
	{
		w_primary = 1;
		w_cost = 1250;
	}
	else if(StrEqual(weapon, "weapon_mac10"))
	{
		w_primary = 1;
		w_cost = 1400;
	}
	else if(StrEqual(weapon, "weapon_mp5sd"))
	{
		w_primary = 1;
		w_cost = 1500;
	}
	else if(StrEqual(weapon, "weapon_ump45"))
	{
		w_primary = 1;
		w_cost = 1700;
	}
	else if(StrEqual(weapon, "weapon_p90"))
	{
		w_primary = 1;
		w_cost = 2350;
	}
	else if(StrEqual(weapon, "weapon_mp9"))
	{
		w_primary = 1;
		w_cost = 1250;
	}
	else if(StrEqual(weapon, "weapon_bizon"))
	{
		w_primary = 1;
		w_cost = 2500;
	}
	else if(StrEqual(weapon, "weapon_nova"))
	{
		w_primary = 1;
		w_cost = 1700;
	}
	else if(StrEqual(weapon, "weapon_xm1014"))
	{
		w_primary = 1;
		w_cost = 3000;
	}
	else if(StrEqual(weapon, "weapon_mag7"))
	{
		w_primary = 1;
		w_cost = 3000;
	}
	else if(StrEqual(weapon, "weapon_m249"))
	{
		w_primary = 1;
		w_cost = 3000;
	}
	else if(StrEqual(weapon, "weapon_glock"))
	{
		w_secondary = 1;
		w_cost = 400;
	}
	else if(StrEqual(weapon, "weapon_hkp2000"))
	{
		w_secondary = 1;
		w_cost = 500;
	}
	else if(StrEqual(weapon, "weapon_p250"))
	{
		w_secondary = 1;
		w_cost = 600;
	}
	else if(StrEqual(weapon, "weapon_deagle"))
	{
		w_secondary = 1;
		w_cost = 650;
	}
	else if(StrEqual(weapon, "weapon_fiveseven"))
	{
		w_secondary = 1;
		w_cost = 750;
	}
	else if(StrEqual(weapon, "weapon_elite"))
	{
		w_secondary = 1;
		w_cost = 750;
	}
	else if(StrEqual(weapon, "weapon_revolver"))
	{
		w_secondary = 1;
		w_cost = 800;
	}
	else if(StrEqual(weapon, "weapon_tec9"))
	{
		w_secondary = 1;
		w_cost = 1000;
	}
	else if(StrEqual(weapon, "weapon_cz75a"))
	{
		w_secondary = 1;
		w_cost = 1200;
	}
	else if(StrEqual(weapon, "weapon_usp_silencer"))
	{
		w_secondary = 1;
		w_cost = 500;
	}
	else if(StrEqual(weapon, "weapon_taser"))
	{
		w_taser = 1;
		w_cost = 200;
	}
	
	if(w_primary == 1 || w_secondary == 1 || w_taser == 1)
	{
		if(!ClientHasWeapon(client, weapon))
		{
			if(i_clientmoney >= w_cost)
			{
				if(w_primary)
				{
					if(slot1 > 0) 
					{
						CS_DropWeapon(client, slot1, false, false);
					}
				}
				
				if(w_secondary)
				{
					if(slot2 > 0)
					{
						CS_DropWeapon(client, slot2, false, false);
					}
				}
					
				SetMoney(client, i_clientmoney - w_cost);
				GivePlayerItem(client, weapon);
				
				if(isMenu)
				{
					if(w_primary)
					Format(g_IsMenuBuyPrim[client], sizeof(g_IsMenuBuyPrim[]), "%s", weapon);
				
					if(w_secondary)
					Format(g_IsMenuBuySec[client], sizeof(g_IsMenuBuySec[]), "%s", weapon);
					
					if(w_taser)
					Format(g_IsMenuBuyTaser[client], sizeof(g_IsMenuBuyTaser[]), "%s", weapon);
					
					ShowWeaponsMenu(client);
				}
			}
			else
			{
				PrintCenterText(client, "#Cstrike_TitlesTXT_Not_Enough_Money");
				if(w_primary && isMenu)
				ShowWeapons1Menu(client);
				
				if(w_secondary && isMenu)
				ShowWeapons2Menu(client);
			}
		}
		else
		{
			PrintCenterText(client, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
			
			if(w_primary && isMenu)
			ShowWeapons1Menu(client);
				
			if(w_secondary && isMenu)
			ShowWeapons2Menu(client);
		}
	}
		
	if(StrEqual(weapon, "item_vesthelm"))
	{
		w_item = 2;
		w_cost = 1000;
	}
	else if(StrEqual(weapon, "item_kevlar"))
	{
		w_item = 1;
		w_cost = 650;
	}
	else if(StrEqual(weapon, "weapon_hegrenade"))
	{
		w_item = 1;
		w_cost = 300;
	}
	else if(StrEqual(weapon, "weapon_flashbang"))
	{
		w_item = 1;
		w_cost = 200;
	}
	else if(StrEqual(weapon, "weapon_decoy"))
	{
		w_item = 1;
		w_cost = 50;
	}
	else if(StrEqual(weapon, "weapon_smokegrenade"))
	{
		w_item = 1;
		w_cost = 100;
	}
	else if(StrEqual(weapon, "weapon_molotov"))
	{
		w_item = 1;
		w_cost = 400;
	}
	
	if(w_item == 1 || w_item == 2)
	{
		if(StrEqual(weapon, "item_vesthelm") || StrEqual(weapon, "item_kevlar"))
		{
			if(GetClientArmor(client) < 100)
			{
				if(w_item == 1)
				{
					if(i_clientmoney >= w_cost)
					{
						SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
						SetMoney(client, i_clientmoney - w_cost);
						if(isMenu)
						{
							Format(g_IsMenuBuyArmor[client], sizeof(g_IsMenuBuyArmor[]), "%s", weapon);
							ShowWeaponsMenu(client);
						}
					}
					else
					{
						PrintCenterText(client, "#Cstrike_TitlesTXT_Not_Enough_Money");
						if(isMenu)
							ShowItemsMenu(client);
					}
				}
				if(w_item == 2)
				{
					if(!GetEntProp(client, Prop_Send, "m_bHasHelmet"))
					{	
						if(i_clientmoney >= w_cost)
						{
							SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
							SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
							SetMoney(client, i_clientmoney - w_cost);
							if(isMenu)
							{
								Format(g_IsMenuBuyArmor[client], sizeof(g_IsMenuBuyArmor[]), "%s", weapon);
								ShowWeaponsMenu(client);
							}
						}
						else
						{
							PrintCenterText(client, "#Cstrike_TitlesTXT_Not_Enough_Money");
							if(isMenu)
								ShowItemsMenu(client);
						}
					} 
					else 
					{
						if(i_clientmoney >= 650)
						{
							SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
							SetMoney(client, i_clientmoney - 650);
							PrintHintText(client, "#Cstrike_TitlesTXT_Already_Have_Helmet_Bought_Kevlar");
							if(isMenu)
							{
								Format(g_IsMenuBuyArmor[client], sizeof(g_IsMenuBuyArmor[]), "%s", weapon);
								ShowWeaponsMenu(client);
							}
						}
						else
						{
							PrintCenterText(client, "#Cstrike_TitlesTXT_Not_Enough_Money");
							if(isMenu)
								ShowItemsMenu(client);
						}
					}
				}
			} 
			else if(GetClientArmor(client) == 100)
			{
				if(w_item == 1)
				{
					PrintHintText(client, "#Cstrike_TitlesTXT_Already_Have_Kevlar");
					if(isMenu)
						ShowItemsMenu(client);
				}
				
				if(w_item == 2)
				{	
					if(!GetEntProp(client, Prop_Send, "m_bHasHelmet"))
					{
						if(i_clientmoney >= 350)
						{
							SetMoney(client, i_clientmoney - 350);
							SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
							PrintHintText(client, "#Cstrike_TitlesTXT_Already_Have_Kevlar_Bought_Helmet");
							if(isMenu)
							{
								Format(g_IsMenuBuyArmor[client], sizeof(g_IsMenuBuyArmor[]), "%s", weapon);
								ShowWeaponsMenu(client);
							}
						}
						else
						{
							PrintCenterText(client, "#Cstrike_TitlesTXT_Not_Enough_Money");
							if(isMenu)
								ShowItemsMenu(client);
						}
					} 
					else 
					{
						PrintHintText(client, "#Cstrike_TitlesTXT_Already_Have_Kevlar_Helmet");
						if(isMenu)
							ShowItemsMenu(client);
					}
				}
			}
		}
		else if(StrEqual(weapon, "weapon_hegrenade"))
		{
			if(b_HEAlreadyBought[client] == true)
			{
				PrintCenterText(client, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				if(isMenu)
					ShowItemsMenu(client);
			}
			else if(GetClientHEStock(client) == 0)
			{
				if(i_clientmoney >= w_cost)
				{
					SetMoney(client, i_clientmoney - w_cost);
					GivePlayerItem(client, weapon);
					b_HEAlreadyBought[client] = true;
					
					if(isMenu)
					{
						Format(g_IsMenuBuyItem1[client], sizeof(g_IsMenuBuyItem1[]), "%s", weapon);
						ShowWeaponsMenu(client);
					}
				}
				else
				{
					PrintCenterText(client, "#Cstrike_TitlesTXT_Not_Enough_Money");
					if(isMenu)
						ShowItemsMenu(client);
				}
			}
			else
			{
				PrintCenterText(client, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				if(isMenu)
					ShowItemsMenu(client);
			}
		}
		else if(StrEqual(weapon, "weapon_flashbang"))
		{
			if(b_FBAlreadyBought[client] == true)
			{
				PrintCenterText(client, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				if(isMenu)
					ShowItemsMenu(client);
			}
			else if(GetClientFBStock(client) == 0)
			{
				if(i_clientmoney >= w_cost)
				{
					SetMoney(client, i_clientmoney - w_cost);
					GivePlayerItem(client, weapon);
					b_FBAlreadyBought[client] = true;
					
					if(isMenu)
					{
						Format(g_IsMenuBuyItem2[client], sizeof(g_IsMenuBuyItem2[]), "%s", weapon);
						ShowWeaponsMenu(client);
					}
				}
				else
				{
					PrintCenterText(client, "#Cstrike_TitlesTXT_Not_Enough_Money");
					if(isMenu)
						ShowItemsMenu(client);
				}
			}
			else
			{
				PrintCenterText(client, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				if(isMenu)
					ShowItemsMenu(client);
			}
		}
		else if(StrEqual(weapon, "weapon_decoy"))
		{
			if(b_DCAlreadyBought[client] == true)
			{
				PrintCenterText(client, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				if(isMenu)
					ShowItemsMenu(client);
			}
			else if(GetClientDCStock(client) == 0)
			{
				if(i_clientmoney >= w_cost)
				{
					SetMoney(client, i_clientmoney - w_cost);
					GivePlayerItem(client, weapon);
					b_DCAlreadyBought[client] = true;
					
					if(isMenu)
					{
						Format(g_IsMenuBuyItem3[client], sizeof(g_IsMenuBuyItem3[]), "%s", weapon);
						ShowWeaponsMenu(client);
					}
				}
				else
				{
					PrintCenterText(client, "#Cstrike_TitlesTXT_Not_Enough_Money");
					if(isMenu)
						ShowItemsMenu(client);
				}
			}
			else
			{
				PrintCenterText(client, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				if(isMenu)
					ShowItemsMenu(client);
			}
		}
		else if(StrEqual(weapon, "weapon_smokegrenade"))
		{
			if(b_SGAlreadyBought[client] == true)
			{
				PrintCenterText(client, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				if(isMenu)
					ShowItemsMenu(client);
			}
			else if(GetClientSGStock(client) == 0)
			{
				if(i_clientmoney >= w_cost)
				{
					SetMoney(client, i_clientmoney - w_cost);
					GivePlayerItem(client, weapon);
					b_DCAlreadyBought[client] = true;
					
					if(isMenu)
					{
						Format(g_IsMenuBuyItem4[client], sizeof(g_IsMenuBuyItem4[]), "%s", weapon);
						ShowWeaponsMenu(client);
					}
				}
				else
				{
					PrintCenterText(client, "#Cstrike_TitlesTXT_Not_Enough_Money");
					if(isMenu)
						ShowItemsMenu(client);
				}
			}
			else
			{
				PrintCenterText(client, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				if(isMenu)
					ShowItemsMenu(client);
			}
		}
		else if(StrEqual(weapon, "weapon_molotov"))
		{
			if(b_MLAlreadyBought[client] == true)
			{
				PrintCenterText(client, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				if(isMenu)
					ShowItemsMenu(client);
			}
			else if(GetClientMLStock(client) == 0)
			{
				if(i_clientmoney >= w_cost)
				{
					SetMoney(client, i_clientmoney - w_cost);
					GivePlayerItem(client, weapon);
					b_DCAlreadyBought[client] = true;
					
					if(isMenu)
					{
						Format(g_IsMenuBuyItem5[client], sizeof(g_IsMenuBuyItem5[]), "%s", weapon);
						ShowWeaponsMenu(client);
					}
				}
				else
				{
					PrintCenterText(client, "#Cstrike_TitlesTXT_Not_Enough_Money");
					if(isMenu)
						ShowItemsMenu(client);
				}
			}
			else
			{
				PrintCenterText(client, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				if(isMenu)
					ShowItemsMenu(client);
			}
		}
	}
	
	return Plugin_Handled;
}

void Buymenu_ClearAll(int client)
{
	Format(g_IsMenuBuyPrim[client], sizeof(g_IsMenuBuyPrim[]), "");
	Format(g_IsMenuBuySec[client], sizeof(g_IsMenuBuySec[]), "");
	Format(g_IsMenuBuyTaser[client], sizeof(g_IsMenuBuyTaser[]), "");
	Format(g_IsMenuBuyArmor[client], sizeof(g_IsMenuBuyArmor[]), "");
	Format(g_IsMenuBuyItem1[client], sizeof(g_IsMenuBuyItem1[]), "");
	Format(g_IsMenuBuyItem2[client], sizeof(g_IsMenuBuyItem2[]), "");
	Format(g_IsMenuBuyItem3[client], sizeof(g_IsMenuBuyItem3[]), "");
	Format(g_IsMenuBuyItem4[client], sizeof(g_IsMenuBuyItem4[]), "");
	Format(g_IsMenuBuyItem5[client], sizeof(g_IsMenuBuyItem5[]), "");
	Format(g_IsMenuBuyItem6[client], sizeof(g_IsMenuBuyItem6[]), "");
	b_DisableAutoBuymenu[client] = false;
	b_AutoRebuy[client] = false;
}

void Buymenu_ClearGnd(int client)
{
	b_HEAlreadyBought[client] = false;
	b_FBAlreadyBought[client] = false;
	b_DCAlreadyBought[client] = false;
	b_SGAlreadyBought[client] = false;
	b_MLAlreadyBought[client] = false;
}

stock bool ClientHasWeapon(int client, const char[] weapon)
{
    int length = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons"); 
     
    for (int i= 0; i < length; i++)  
    {  
        int item = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);  

        if (item != -1)  
        {  
            char classname[64]; 
            
            if (GetEntityClassname(item, classname, sizeof(classname)))
            {
				int weaponindex = GetEntProp(item, Prop_Send, "m_iItemDefinitionIndex");
				switch (weaponindex)
				{
					case 23: strcopy(classname, 64, "weapon_mp5sd");
					case 60: strcopy(classname, 64, "weapon_m4a1_silencer");
					case 61: strcopy(classname, 64, "weapon_usp_silencer");
					case 63: strcopy(classname, 64, "weapon_cz75a");
					case 64: strcopy(classname, 64, "weapon_revolver");
				}
			
				if (StrEqual(weapon, classname, false))
				{
					return true;
				}
            }
        }  
    } 

    return false;
}

GetClientHEStock(client)
{
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, HEGRENADE_OFFSET);
}

GetClientFBStock(client)
{
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, FLASHBANG_OFFSET);
}

GetClientDCStock(client)
{
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, DECOY_OFFSET);
}
GetClientMLStock(client)
{
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, MOLOTOV_OFFSET);
} 

GetClientSGStock(client)
{
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, SMOKE_OFFSET);
}

stock SetMoney(int client, int money)
{
	SetEntProp(client, Prop_Send, "m_iAccount", money);
}

stock GetMoney(client)
{
	return GetEntProp(client, Prop_Send, "m_iAccount");
}

bool IsClientValid(int client)
{
	if(client < 1 || client > MaxClients + 1)
		return false;
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return false;
	
	return true;
}