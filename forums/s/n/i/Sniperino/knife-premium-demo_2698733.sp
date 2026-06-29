#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SNIPER007"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

int Choose[MAXPLAYERS + 1];
bool g_bUsed[MAXPLAYERS + 1];
char g_szPremiumKnife[MAXPLAYERS + 1];
char sza_wpn_list_class[][] =  { "weapon_fists", "weapon_spanner", "weapon_hammer", "weapon_axe" };
char sza_wpn_list_names[][] =  { "Fists", "Spanner", "Hammer", "[VIP] Axe" };

ConVar g_cChooselimit;

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Knife Premium [Demo Version]",
	author = PLUGIN_AUTHOR,
	description = "Knife Premium from Sniper007",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/Sniper-oo7/"
};

public void OnPluginStart()
{	
	RegConsoleCmd("sm_premiumknife", CMD_PremiumKnife);
	RegConsoleCmd("sm_knifepremium", CMD_PremiumKnife);
	RegConsoleCmd("sm_pk", CMD_PremiumKnife);
	RegConsoleCmd("sm_kp", CMD_PremiumKnife);
	
	HookEvent("round_start", Event_RoundStart);

	g_cChooselimit = CreateConVar("sm_choose_limit", "0", "0 = disabled, 1 = player can only choose once for round");
	
	AutoExecConfig(true, "Knife-Premium");
}

public void OnMapStart()
{	
}

public void OnClientPutInServer(int client)
{
	if(IsPravyClient(client))
    {
    	g_szPremiumKnife[client] = -1;
    }
}

public void OnClientDisconnect(int client)
{
	g_szPremiumKnife[client] = -1;
}

public Action CMD_PremiumKnife(int client, int args)
{
	if (IsPravyClient(client))
	{
		if (IsPlayerAlive(client))
		{
			openPremiumKnife(client);
		}
		else
		{
			PrintToChat(client, " \x04[Premium-Knife]\x01 You have to live"); //You can edit text in quotation marks "TEXT" [WARNING: THIS MARKING COLOR -> \x04 \x01 .. <- (https://ctrlv.cz/shots/2015/03/08/Mlwd.png)]
		}
	}
	
	return Plugin_Handled;
}


public void Event_RoundStart(Event event, const char[] name, bool bDontBroadcast)
{   
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsPravyClient(i))
		{
			g_bUsed[i] = false;
		}
	}
	
    CreateTimer(1.5, PremiumKnife);
}

public Action PremiumKnife(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsPravyClient(i))
		{	
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
			if (IsPravyClient(client))
			{
				if (IsPlayerAlive(client))
				{
					if (g_bUsed[client] == false)
					{
						char szItem[32];
						menu.GetItem(index, szItem, sizeof(szItem));
						Format(g_szPremiumKnife[client], sizeof(g_szPremiumKnife), "%s", szItem);
						if(StrEqual(g_szPremiumKnife[client], "weapon_fists"))
						{	
							RemoveKnife(client);
							int iItem = GivePlayerItem(client, "weapon_fists");
							EquipPlayerWeapon(client, iItem);
							Choose[client] = 1;
							if(g_cChooselimit.IntValue == 1)
							{
								g_bUsed[client] = true;
							}
						}
						else if(StrEqual(g_szPremiumKnife[client], "weapon_spanner"))
						{							
							RemoveKnife(client);
							int iItem = GivePlayerItem(client, "weapon_spanner");
							EquipPlayerWeapon(client, iItem);
							Choose[client] = 2;
							if(g_cChooselimit.IntValue == 1)
							{
								g_bUsed[client] = true;
							}
						}
						else if(StrEqual(g_szPremiumKnife[client], "weapon_hammer"))
						{	
							RemoveKnife(client);
							int iItem = GivePlayerItem(client, "weapon_hammer");
							EquipPlayerWeapon(client, iItem);
							Choose[client] = 3;
							if(g_cChooselimit.IntValue == 1)
							{
								g_bUsed[client] = true;
							}
						}
						else if(StrEqual(g_szPremiumKnife[client], "weapon_axe"))
						{							
							if(IsClientVIP(client))
							{
								RemoveKnife(client);
								int iItem = GivePlayerItem(client, "weapon_axe");
								EquipPlayerWeapon(client, iItem);
								Choose[client] = 4;
								if(g_cChooselimit.IntValue == 1)
								{
									g_bUsed[client] = true;
								}
							}
							else
							{
								PrintToChat(client, " \x04[Premium-Knife]\x01 You have to buy \x04VIP\x01!");
								openPremiumKnife(client);
							}
						}
					}
					else
					{
						PrintToChat(client, " \x04[Premium-Knife]\x01 You have already chosen knife, you have to wait to next round!");
					}
				}
				else
				{
					PrintToChat(client, " \x04[Premium-Knife]\x01 You have to live!");
				}
			}
		}
	}
}

stock bool IsPravyClient(int client, bool alive = false)
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
	if(IsPravyClient(client))
	{
		int iWepIndex = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		
		if(iWepIndex != -1)
		{
			RemovePlayerItem(client, iWepIndex);
			AcceptEntityInput(iWepIndex, "Kill");
		}
	}
}