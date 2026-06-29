#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SNIPER007"
#define PLUGIN_VERSION "2.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <myjailshop>
#include <clientprefs>
#include <colors>

int Choose[MAXPLAYERS + 1];
bool g_bUsed[MAXPLAYERS + 1];
char g_szPremiumKnife[MAXPLAYERS + 1];
char sza_wpn_list_class[][] =  { "weapon_fists", "weapon_spanner", "weapon_hammer", "weapon_axe" };
char sza_wpn_list_names[][] =  { "Fists", "Spanner (+ DMG)", "Hammer (++ DMG)", "[VIP] Axe (+++ DMG)" };

//HANDLE
Handle g_hTypeKnife;

//SETTINGS
ConVar g_cFists;
ConVar g_cSpanner;
ConVar g_cHammer;
ConVar g_cAxe;
ConVar g_cTimeget;
ConVar g_cFistsdamage;
ConVar g_cSpannerdamage;
ConVar g_cHammerdamage;
ConVar g_cAxedamage;
ConVar g_cMoneytype;
ConVar g_cChooselimit;
ConVar g_cMenuopen;

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Knife Premium [Full Version]",
	author = PLUGIN_AUTHOR,
	description = "Knife Premium from Sniper007",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/Sniper-oo7/"
};

public void OnPluginStart()
{	
	LoadTranslations("Knife-Premium");
	
	RegConsoleCmd("sm_premiumknife", CMD_PremiumKnife);
	RegConsoleCmd("sm_knifepremium", CMD_PremiumKnife);
	RegConsoleCmd("sm_pk", CMD_PremiumKnife);
	RegConsoleCmd("sm_kp", CMD_PremiumKnife);
	
	HookEvent("round_start", Event_RoundStart);
    //HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
   	
   	//FOR PERNAMENT CHOOSE
   	g_hTypeKnife = RegClientCookie("type_knife", "", CookieAccess_Private);
   	
   	//PRICE
   	g_cFists = CreateConVar("sm_fists_price", "100", "Price of Spanner, 0 = free");
   	g_cSpanner = CreateConVar("sm_spanner_price", "500", "Price of Spanner, 0 = free");
	g_cHammer = CreateConVar("sm_hammer_price", "2000", "Price of Hammer, 0 = free");
	g_cAxe = CreateConVar("sm_axe_price", "3500", "Price of Axe, 0 = free");
	//HOW LONG YOU WILL HAVE KNIFE
	g_cTimeget = CreateConVar("sm_time_get", "1", "2 = pernament, 1 = On whole map, 0 = on one round");
	//DAMAGE
	g_cFistsdamage = CreateConVar("sm_fists_damage", "10", "Damage for fists");
	g_cSpannerdamage = CreateConVar("sm_spanner_damage", "30", "Damage for Spanner");
	g_cHammerdamage = CreateConVar("sm_hammer_damage", "50", "Damage for Hammer");
	g_cAxedamage = CreateConVar("sm_axe_damage", "60", "Damage for Axe");
	//TYPE OF MONEY
	g_cMoneytype = CreateConVar("sm_money_type", "0", "0 = game cash, 1 = myjailshop");
	//LIMIT OF CHOOSE
	g_cChooselimit = CreateConVar("sm_choose_limit", "0", "0 = disabled, 1 = player can only choose once for round");
	g_cMenuopen = CreateConVar("sm_menu_open", "0", "Menu only for VIP, 0 = everyone");
	
	AutoExecConfig(true, "Knife-Premium");
}

public void OnMapStart()
{	
	AddFileToDownloadsTable("sound/music/PremiumKnife/fists.mp3");
	AddFileToDownloadsTable("sound/music/PremiumKnife/spanner.mp3");
	AddFileToDownloadsTable("sound/music/PremiumKnife/hammer.mp3");
	AddFileToDownloadsTable("sound/music/PremiumKnife/axe.mp3");
	
	PrecacheSound("music/PremiumKnife/fists.mp3");
	PrecacheSound("music/PremiumKnife/spanner.mp3");
	PrecacheSound("music/PremiumKnife/hammer.mp3");
	PrecacheSound("music/PremiumKnife/axe.mp3");
}

public void OnClientCookiesCached(int client)
{
	char buffer[12];
	
	GetClientCookie(client, g_hTypeKnife, buffer, sizeof(buffer));
	if (StrEqual(buffer, ""))
	{
		SetClientCookie(client, g_hTypeKnife, "0");
	}
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
    {
    	Choose[client] = 0;
    }
	
	SDKHook(client, SDKHook_OnTakeDamage, TakeDamageHook);
}

public void OnClientDisconnect(int client)
{
	Choose[client] = 0;
}

public Action CMD_PremiumKnife(int client, int args)
{
	if (IsValidClient(client))
	{
		if (IsPlayerAlive(client))
		{
			if(g_cMenuopen.IntValue == 0)
			{
				openPremiumKnife(client);
			}
			else
			{
				if(IsClientVIP(client))
				{
					openPremiumKnife(client);
				}
				else
				{
					CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "no_buy_vip");
				}
			}
		}
		else
		{
			CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "player_alive");
		}
	}
	
	return Plugin_Handled;
}


public void Event_RoundStart(Event event, const char[] name, bool bDontBroadcast)
{   
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			g_bUsed[i] = false;
		}
	}
	
	if(g_cTimeget.IntValue == 1 || g_cTimeget.IntValue == 2)
	{
    	CreateTimer(1.5, PremiumKnife);
    }
}

public Action PremiumKnife(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(g_cTimeget.IntValue == 2)
			{
				char typeofknife[12];
				GetClientCookie(i, g_hTypeKnife, typeofknife, sizeof(typeofknife));
				Choose[i] = StringToInt(typeofknife);
			}
			
			if(Choose[i] == 1)
			{
				RemoveKnife(i);
				int iItem = GivePlayerItem(i, "weapon_fists");
				EquipPlayerWeapon(i, iItem);
			}
			else if(Choose[i] == 2)
			{
				RemoveKnife(i);
				int iItem = GivePlayerItem(i, "weapon_spanner");
				EquipPlayerWeapon(i, iItem);
			}
			else if(Choose[i] == 3)
			{
				RemoveKnife(i);
				int iItem = GivePlayerItem(i, "weapon_hammer");
				EquipPlayerWeapon(i, iItem);
			}
			else if(Choose[i] == 4)
			{
				RemoveKnife(i);
				int iItem = GivePlayerItem(i, "weapon_axe");
				EquipPlayerWeapon(i, iItem);
			}
		}
    }
}

//GUN-MENU
void openPremiumKnife(int client)
{
	Menu menu = new Menu(mPKHandler);
	
	menu.SetTitle("Choose Knife:");
	
	for (int wep; wep < sizeof(sza_wpn_list_class); wep++)
	{
		menu.AddItem(sza_wpn_list_class[wep], sza_wpn_list_names[wep]);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int mPKHandler(Menu menu, MenuAction action, int client, int index)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (IsValidClient(client))
			{
				if (IsPlayerAlive(client))
				{
					if (g_bUsed[client] == false)
					{
						if(g_cMoneytype.IntValue == 0)
						{
							char szItem[32];
							menu.GetItem(index, szItem, sizeof(szItem));
							Format(g_szPremiumKnife[client], sizeof(g_szPremiumKnife), "%s", szItem);
							if(StrEqual(g_szPremiumKnife[client], "weapon_fists"))
							{	
								if(g_cFists.IntValue == 0)
								{
									RemoveKnife(client);
									int iItem = GivePlayerItem(client, "weapon_fists");
									EquipPlayerWeapon(client, iItem);
									Choose[client] = 1;
									if(g_cChooselimit.IntValue == 1)
									{
										g_bUsed[client] = true;
									}
									
									if(g_cTimeget.IntValue == 2)
									{
										SetClientCookie(client, g_hTypeKnife, "1");
									}
								}
								else
								{
									int money = GetEntProp(client, Prop_Send, "m_iAccount");
									if(money >= g_cFists.IntValue)
									{
										RemoveKnife(client);
										int iItem = GivePlayerItem(client, "weapon_fists");
										EquipPlayerWeapon(client, iItem);
										Choose[client] = 1;
										if(g_cChooselimit.IntValue == 1)
										{
											g_bUsed[client] = true;
										}
										
										if(g_cTimeget.IntValue == 2)
										{
											SetClientCookie(client, g_hTypeKnife, "1");
										}
										
										SetEntProp(client, Prop_Send, "m_iAccount", money - g_cFists.IntValue);
									}
									else
									{
										CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "no_money_fists", g_cFists.IntValue);
										openPremiumKnife(client);
									}
								}
							}
							else if(StrEqual(g_szPremiumKnife[client], "weapon_spanner"))
							{							
								if(g_cSpanner.IntValue == 0)
								{
									RemoveKnife(client);
									int iItem = GivePlayerItem(client, "weapon_spanner");
									EquipPlayerWeapon(client, iItem);
									Choose[client] = 2;
									if(g_cChooselimit.IntValue == 1)
									{
										g_bUsed[client] = true;
									}
									
									if(g_cTimeget.IntValue == 2)
									{
										SetClientCookie(client, g_hTypeKnife, "2");
									}
								}
								else
								{
									int money = GetEntProp(client, Prop_Send, "m_iAccount");
									if(money >= g_cSpanner.IntValue)
									{
										RemoveKnife(client);
										int iItem = GivePlayerItem(client, "weapon_spanner");
										EquipPlayerWeapon(client, iItem);
										Choose[client] = 2;
										if(g_cChooselimit.IntValue == 1)
										{
											g_bUsed[client] = true;
										}
										
										if(g_cTimeget.IntValue == 2)
										{
											SetClientCookie(client, g_hTypeKnife, "2");
										}
										
										SetEntProp(client, Prop_Send, "m_iAccount", money - g_cSpanner.IntValue);
									}
									else
									{
										CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "no_money_spanner", g_cSpanner.IntValue);
										openPremiumKnife(client);
									}
								}
							}
							else if(StrEqual(g_szPremiumKnife[client], "weapon_hammer"))
							{	
								if(g_cHammer.IntValue == 0)
								{
									RemoveKnife(client);
									int iItem = GivePlayerItem(client, "weapon_hammer");
									EquipPlayerWeapon(client, iItem);
									Choose[client] = 3;
									if(g_cChooselimit.IntValue == 1)
									{
										g_bUsed[client] = true;
									}
									
									if(g_cTimeget.IntValue == 2)
									{
										SetClientCookie(client, g_hTypeKnife, "3");
									}
								}
								else
								{	
									int money = GetEntProp(client, Prop_Send, "m_iAccount");
									if(money >= g_cHammer.IntValue)
									{							
										RemoveKnife(client);
										int iItem = GivePlayerItem(client, "weapon_hammer");
										EquipPlayerWeapon(client, iItem);
										Choose[client] = 3;
										if(g_cChooselimit.IntValue == 1)
										{
											g_bUsed[client] = true;
										}
										
										if(g_cTimeget.IntValue == 2)
										{
											SetClientCookie(client, g_hTypeKnife, "3");
										}
										
										SetEntProp(client, Prop_Send, "m_iAccount", money - g_cHammer.IntValue);
									}
									else
									{
										CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "no_money_hammer", g_cHammer.IntValue);
										openPremiumKnife(client);
									}
								}
							}
							else if(StrEqual(g_szPremiumKnife[client], "weapon_axe"))
							{							
								if(IsClientVIP(client))
								{
									if(g_cAxe.IntValue == 0)
									{
										RemoveKnife(client);
										int iItem = GivePlayerItem(client, "weapon_axe");
										EquipPlayerWeapon(client, iItem);
										Choose[client] = 4;
										if(g_cChooselimit.IntValue == 1)
										{
											g_bUsed[client] = true;
										}
										
										if(g_cTimeget.IntValue == 2)
										{
											SetClientCookie(client, g_hTypeKnife, "4");
										}
									}
									else
									{
										int money = GetEntProp(client, Prop_Send, "m_iAccount");
										if(money >= g_cAxe.IntValue)
										{
											RemoveKnife(client);
											int iItem = GivePlayerItem(client, "weapon_axe");
											EquipPlayerWeapon(client, iItem);
											Choose[client] = 4;
											if(g_cChooselimit.IntValue == 1)
											{
												g_bUsed[client] = true;
											}
											
											if(g_cTimeget.IntValue == 2)
											{
												SetClientCookie(client, g_hTypeKnife, "4");
											}
											
											SetEntProp(client, Prop_Send, "m_iAccount", money - g_cAxe.IntValue);
										}
										else
										{
											CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "no_money_axe", g_cAxe.IntValue);
											openPremiumKnife(client);
										}
									}
								}
								else
								{
									PrintToChat(client, " \x04[Knife-Premium]\x01 You have to buy \x04VIP\x01!");
									openPremiumKnife(client);
								}
							}
						}
						else if(g_cMoneytype.IntValue == 1)
						{
							char szItem[32];
							menu.GetItem(index, szItem, sizeof(szItem));
							Format(g_szPremiumKnife[client], sizeof(g_szPremiumKnife), "%s", szItem);
							if(StrEqual(g_szPremiumKnife[client], "weapon_fists"))
							{	
								if(g_cFists.IntValue == 0)
								{
									RemoveKnife(client);
									int iItem = GivePlayerItem(client, "weapon_fists");
									EquipPlayerWeapon(client, iItem);
									Choose[client] = 1;
									if(g_cChooselimit.IntValue == 1)
									{
										g_bUsed[client] = true;
									}
									
									if(g_cTimeget.IntValue == 2)
									{
										SetClientCookie(client, g_hTypeKnife, "1");
									}
								}
								else
								{
									int money = MyJailShop_GetCredits(client);
									if(money >= g_cFists.IntValue)
									{
										RemoveKnife(client);
										int iItem = GivePlayerItem(client, "weapon_fists");
										EquipPlayerWeapon(client, iItem);
										Choose[client] = 1;
										if(g_cChooselimit.IntValue == 1)
										{
											g_bUsed[client] = true;
										}
										
										if(g_cTimeget.IntValue == 2)
										{
											SetClientCookie(client, g_hTypeKnife, "1");
										}
										
										MyJailShop_SetCredits(client, MyJailShop_GetCredits(client) - g_cFists.IntValue);
									}
									else
									{
										CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "no_money_fists", g_cFists.IntValue);
										openPremiumKnife(client);
									}
								}
							}
							else if(StrEqual(g_szPremiumKnife[client], "weapon_spanner"))
							{							
								if(g_cSpanner.IntValue == 0)
								{
									RemoveKnife(client);
									int iItem = GivePlayerItem(client, "weapon_spanner");
									EquipPlayerWeapon(client, iItem);
									Choose[client] = 2;
									if(g_cChooselimit.IntValue == 1)
									{
										g_bUsed[client] = true;
									}
									
									if(g_cTimeget.IntValue == 2)
									{
										SetClientCookie(client, g_hTypeKnife, "2");
									}
								}
								else
								{
									int money = MyJailShop_GetCredits(client);
									if(money >= g_cSpanner.IntValue)
									{
										RemoveKnife(client);
										int iItem = GivePlayerItem(client, "weapon_spanner");
										EquipPlayerWeapon(client, iItem);
										Choose[client] = 2;
										if(g_cChooselimit.IntValue == 1)
										{
											g_bUsed[client] = true;
										}
										
										if(g_cTimeget.IntValue == 2)
										{
											SetClientCookie(client, g_hTypeKnife, "2");
										}
										
										MyJailShop_SetCredits(client, MyJailShop_GetCredits(client) - g_cSpanner.IntValue);
									}
									else
									{
										CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "no_money_spanner", g_cSpanner.IntValue);
										openPremiumKnife(client);
									}
								}
							}
							else if(StrEqual(g_szPremiumKnife[client], "weapon_hammer"))
							{	
								if(g_cHammer.IntValue == 0)
								{
									RemoveKnife(client);
									int iItem = GivePlayerItem(client, "weapon_hammer");
									EquipPlayerWeapon(client, iItem);
									Choose[client] = 3;
									if(g_cChooselimit.IntValue == 1)
									{
										g_bUsed[client] = true;
									}
									
									if(g_cTimeget.IntValue == 2)
									{
										SetClientCookie(client, g_hTypeKnife, "3");
									}
								}
								else
								{	
									int money = MyJailShop_GetCredits(client);
									if(money >= g_cHammer.IntValue)
									{							
										RemoveKnife(client);
										int iItem = GivePlayerItem(client, "weapon_hammer");
										EquipPlayerWeapon(client, iItem);
										Choose[client] = 3;
										if(g_cChooselimit.IntValue == 1)
										{
											g_bUsed[client] = true;
										}
										
										if(g_cTimeget.IntValue == 2)
										{
											SetClientCookie(client, g_hTypeKnife, "3");
										}
										
										MyJailShop_SetCredits(client, MyJailShop_GetCredits(client) - g_cHammer.IntValue);
									}
									else
									{
										CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "no_money_hammer", g_cHammer.IntValue);
										openPremiumKnife(client);
									}
								}
							}
							else if(StrEqual(g_szPremiumKnife[client], "weapon_axe"))
							{							
								if(IsClientVIP(client))
								{
									if(g_cAxe.IntValue == 0)
									{
										RemoveKnife(client);
										int iItem = GivePlayerItem(client, "weapon_axe");
										EquipPlayerWeapon(client, iItem);
										Choose[client] = 4;
										if(g_cChooselimit.IntValue == 1)
										{
											g_bUsed[client] = true;
										}
										
										if(g_cTimeget.IntValue == 2)
										{
											SetClientCookie(client, g_hTypeKnife, "4");
										}
									}
									else
									{
										int money = MyJailShop_GetCredits(client);
										if(money >= g_cAxe.IntValue)
										{
											RemoveKnife(client);
											int iItem = GivePlayerItem(client, "weapon_axe");
											EquipPlayerWeapon(client, iItem);
											Choose[client] = 4;
											if(g_cChooselimit.IntValue == 1)
											{
												g_bUsed[client] = true;
											}
											
											if(g_cTimeget.IntValue == 2)
											{
												SetClientCookie(client, g_hTypeKnife, "4");
											}
											
											MyJailShop_SetCredits(client, MyJailShop_GetCredits(client) - g_cAxe.IntValue);
										}
										else
										{
											CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "no_money_axe", g_cAxe.IntValue);
											openPremiumKnife(client);
										}
									}
								}
								else
								{
									CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "no_buy_vip");
									openPremiumKnife(client);
								}
							}
						}
					}
					else
					{
						CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "wait_next_round");
					}
				}
				else
				{
					CPrintToChat(client, " \x04[Knife-Premium]\x01 %t", "player_alive");
				}
			}
		}
		case MenuAction_End:
	    {
	    	delete menu;
	    }
	}
}

public Action TakeDamageHook(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if ( (client>=1) && (client<=MaxClients) && (attacker>=1) && (attacker<=MaxClients) && (attacker==inflictor) )
    {
    	char WeaponName[64];
        GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));
        if (StrContains(WeaponName, "fists", false) != -1)
        {
            damage = g_cFistsdamage.FloatValue;
            EmitSoundToAll("music/PremiumKnife/fists.mp3", attacker);
            return Plugin_Changed;
        }
        
        char WeaponSpanner[64];
        GetClientWeapon(attacker, WeaponSpanner, sizeof(WeaponSpanner));
        if (StrContains(WeaponSpanner, "spanner", false) != -1)
        {
            damage = g_cSpannerdamage.FloatValue;
            EmitSoundToAll("music/PremiumKnife/spanner.mp3", attacker);
            return Plugin_Changed;
        }
        
        char WeaponHammer[64];
        GetClientWeapon(attacker, WeaponHammer, sizeof(WeaponHammer));
        if (StrContains(WeaponHammer, "hammer", false) != -1)
        {
            damage = g_cHammerdamage.FloatValue;
            EmitSoundToAll("music/PremiumKnife/hammer.mp3", attacker);
            return Plugin_Changed;
        }
        
        char WeaponAxe[64];
        GetClientWeapon(attacker, WeaponAxe, sizeof(WeaponAxe));
        if (StrContains(WeaponAxe, "axe", false) != -1)
        {
            damage = g_cAxedamage.FloatValue;
            EmitSoundToAll("music/PremiumKnife/axe.mp3", attacker);
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

stock bool IsValidClient(int client, bool alive = false)
{
    if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && (alive == false || IsPlayerAlive(client)))
    {
        return true;
    }
   
    return false;
}

stock bool IsClientVIP(int client)
{
    return CheckCommandAccess(client, "", ADMFLAG_RESERVATION);
}

void RemoveKnife(int client)
{
	if(IsValidClient(client))
	{
		int iWepIndex = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		
		if(iWepIndex != -1)
		{
			RemovePlayerItem(client, iWepIndex);
			AcceptEntityInput(iWepIndex, "Kill");
		}
	}
}