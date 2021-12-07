#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SNIPER007"
#define PLUGIN_VERSION "2.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>

bool g_bBody[MAXPLAYERS + 1] = false;

Handle gh_AutoBhop = INVALID_HANDLE;

//GUNMENU
char sza_wpn_list_class[][] =  { "weapon_ak47", "weapon_m4a1", "weapon_m4a1_silencer", "weapon_awp", "weapon_nova" };
char sza_wpn_list_names[][] =  { "AK47 + DEAGLE", "M4A4 + DEAGLE", "M4A1-S + DEAGLE", "AWP + DEAGLE", "NOVA + DEAGLE" };

int WhatGun[MAXPLAYERS];

char g_szSelectedWeapon[MAXPLAYERS + 1];

bool Useda[MAXPLAYERS] = false;

int timeout;
int advert;

//SETTINGS
ConVar g_cVIPhealthbonus;
ConVar g_cVIPhealthspawn;
ConVar g_cVIPhit;
ConVar g_cVIPkill;
ConVar g_cVIPspeed;
ConVar g_cVIPgravity;
ConVar g_cVIPguntimer;
ConVar g_cVIPadverts;
ConVar g_cVIPbhop;
ConVar g_cVIPextramoney;

int round;
bool g_bGunActivated = false;

#pragma newdecls required

public Plugin myinfo = 
{
	name = "VIP Premium", 
	author = PLUGIN_AUTHOR, 
	description = "VIP Premium from Sniper007", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/Sniper-oo7/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_gun", CMD_Gunmenus);
	RegConsoleCmd("sm_gunmenu", CMD_Gunmenus);
	RegConsoleCmd("sm_guns", CMD_Gunmenus);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", OnPlayerDeath);
	
	//CHANGE IT
	g_cVIPhealthbonus = CreateConVar("sm_vip_health_bonus", "5", "Bonus for kill HP");
	g_cVIPhealthspawn = CreateConVar("sm_vip_health_spawn", "10", "On round start VIP HP");
	g_cVIPhit = CreateConVar("sm_vip_money_hit", "50", "Bonus money for VIP for hit player");
	g_cVIPkill = CreateConVar("sm_vip_kill_money", "300", "Money for VIP for killing players");
	g_cVIPspeed = CreateConVar("sm_vip_speed", "1.2", "Speed for vip, 0 = disabled");
	g_cVIPgravity = CreateConVar("sm_vip_gravity", "0.7", "Gravity for vip, 0 = disabled");
	g_cVIPguntimer = CreateConVar("sm_vip_gun_timer", "20", "How long gun menu will work from round start, 0 = disabled");
	g_cVIPadverts = CreateConVar("sm_vip_adverts", "120", "Every X sec will write message in chat, 0 = disabled");
	g_cVIPbhop = CreateConVar("sm_vip_bhop", "1", "Bhop for VIP 1 = enable, 0 = disabled");
	g_cVIPextramoney = CreateConVar("sm_vip_extra_money", "100", "How much money will VIP get on every round start, 0 = disabled");
	
	gh_AutoBhop = FindConVar("sv_autobunnyhopping");
	SetConVarBool(gh_AutoBhop, false);
	
	AutoExecConfig(true, "VIP-Premium");
	
	CreateTimer(1.0, VIPtag, _, TIMER_REPEAT);
	
	advert = g_cVIPadverts.IntValue;
}

public void OnClientPutInServer(int client)
{
	if (IsValidClient(client))
	{
		CreateTimer(1.0, JoinVIP, client);
		Useda[client] = false;
		WhatGun[client] = 0;
	}
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action JoinVIP(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		if (IsClientVIP(client))
		{
			if (g_cVIPbhop.IntValue == 1)
			{
				SendConVarValue(client, gh_AutoBhop, "1");
			}
			PrintToChatAll(" \x01[\x04*\x01] Player \x04[VIP] \x10%N \x01has join to the server!", client);
		}
	}
}

public void OnClientDisconnect(int client)
{
	Useda[client] = false;
	WhatGun[client] = 0;
	if (IsValidClient(client))
	{
		if (IsClientVIP(client))
		{
			PrintToChatAll(" \x01[\x04*\x01] Player \x04[VIP] \x10%N \x01has disconnect from the server!", client);
		}
	}
}

public Action CMD_Gunmenus(int client, int args)
{
	if (IsValidClient(client))
	{
		if (IsPlayerAlive(client))
		{
			openGuny(client);
		}
		else
		{
			PrintToChat(client, " \x04[VIP]\x01 You have to live"); //You can edit text in quotation marks "TEXT" [WARNING: THIS MARKING COLOR -> \x04 \x01 .. <- (https://ctrlv.cz/shots/2015/03/08/Mlwd.png)]
		}
	}
	
	return Plugin_Handled;
}

public void Event_RoundStart(Event event, const char[] name, bool bDontBroadcast)
{
	if (GameRules_GetProp("m_bWarmupPeriod") != 1)
	{
		timeout = g_cVIPguntimer.IntValue;
		round++;
		if (round == 4)
		{
			g_bGunActivated = true;
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (IsClientVIP(i))
			{
				if (IsPlayerAlive(i))
				{
					if (g_cVIPextramoney.IntValue > 0)
					{
						int penizes = GetEntProp(i, Prop_Send, "m_iAccount");
						SetEntProp(i, Prop_Send, "m_iAccount", penizes + g_cVIPextramoney.IntValue);
						PrintToChat(i, " \x04[VIP]\x01 You got %i bonus money", g_cVIPextramoney.IntValue);
					}
					
					//SPEED & GRAVITY
					if (g_cVIPspeed.FloatValue > 0)
					{
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", g_cVIPspeed.FloatValue);
					}
					
					if (g_cVIPgravity.FloatValue > 0)
					{
						SetEntityGravity(i, g_cVIPgravity.FloatValue);
					}
					
					//GUNS
					
					if(round >= 4)
					{
						WhatGunGive(i);
					}
					Useda[i] = false;
					
					GivePlayerItem(i, "weapon_hegrenade");
					GivePlayerItem(i, "weapon_deagle");
					
					SetEntityHealth(i, g_cVIPhealthspawn.IntValue);
					Func_SetPlayerArmor(i);
				}
			}
		}
	}
}

//TRAILY + BUNNYHOP
public Action OnPlayerRunCmd(int client, int & buttons, int & impulse, float vel[3], float angles[3], int & weapon, int & subtype, int & cmdnum, int & tickcount, int & seed, int mouse[2])
{
	if (IsClientVIP(client))
	{
		if (IsPlayerAlive(client))
		{	
			if (g_cVIPbhop.IntValue == 1)
			{
				if (buttons & IN_JUMP)
				{
					if (!(GetEntityFlags(client) & FL_ONGROUND))
					{
						if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
						{
							if (GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
							{
								buttons &= ~IN_JUMP;
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public void OnPlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	int Zivoty = GetClientHealth(attacker) + g_cVIPhealthbonus.IntValue;
	
	if (GameRules_GetProp("m_bWarmupPeriod") != 1)
	{
		if (IsValidClient(attacker))
		{
			if (IsPlayerAlive(attacker))
			{
				if (!IsFakeClient(attacker))
				{
					if (IsClientVIP(attacker))
					{
						//BONUS HP
						SetEntityHealth(attacker, Zivoty);
						//MONEY FOR KILL
						int penizes = GetEntProp(attacker, Prop_Send, "m_iAccount");
						SetEntProp(attacker, Prop_Send, "m_iAccount", penizes + g_cVIPkill.IntValue);
					}
				}
			}
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	//BONUS MONEY FOR HIT (STEAM GROUP)
	if (GameRules_GetProp("m_bWarmupPeriod") != 1)
	{
		if (IsValidClient(attacker))
		{
			if (GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT || GetClientTeam(attacker) == CS_TEAM_CT && GetClientTeam(victim) == CS_TEAM_T)
			{
				if (IsClientVIP(attacker))
				{
					if (g_bBody[attacker] == false)
					{
						if (!IsFakeClient(attacker))
						{
							int ucet = GetEntProp(attacker, Prop_Send, "m_iAccount");
							SetEntProp(attacker, Prop_Send, "m_iAccount", ucet + g_cVIPhit.IntValue);
							PrintToChat(attacker, " \x04[VIP] \x01You got \x0450 $ \x01money for hurt player"); //You can edit text in quotation marks "TEXT" [WARNING: THIS IS MARKING COLOR -> \x04 \x01 .. <- (https://ctrlv.cz/shots/2015/03/08/Mlwd.png)]
							g_bBody[attacker] = true;
							CreateTimer(15.0, Body, attacker);
						}
					}
				}
			}
		}
	}
}

public Action Body(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		if (IsPlayerAlive(client))
		{
			g_bBody[client] = false;
		}
	}
}

//GUN MENU
void openGuny(int client)
{
	Menu menu = new Menu(mAutHandler);
	
	menu.SetTitle("Choose Gun:");
	
	for (int wep; wep < sizeof(sza_wpn_list_class); wep++)
	{
		menu.AddItem(sza_wpn_list_class[wep], sza_wpn_list_names[wep]);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int mAutHandler(Menu menu, MenuAction action, int client, int index)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (g_bGunActivated == true)
			{
				if (timeout >= 1)
				{
					if (Useda[client] == false)
					{
						if (IsValidClient(client))
						{
							if (IsPlayerAlive(client))
							{
								char szItem[32];
								menu.GetItem(index, szItem, sizeof(szItem));
								Format(g_szSelectedWeapon[client], sizeof(g_szSelectedWeapon), "%s", szItem);
								RemovePrimaryWeapons(client);
								RemoveSecondaryWeapons(client);
								if(StrEqual(g_szSelectedWeapon[client], "weapon_ak47"))
								{
									WhatGun[client] = 1;
								}
								else if(StrEqual(g_szSelectedWeapon[client], "weapon_m4a1"))
								{
									WhatGun[client] = 2;
								}
								else if(StrEqual(g_szSelectedWeapon[client], "weapon_m4a1_silencer"))
								{
									WhatGun[client] = 3;
								}
								else if(StrEqual(g_szSelectedWeapon[client], "weapon_awp"))
								{
									WhatGun[client] = 4;
								}
								else if(StrEqual(g_szSelectedWeapon[client], "weapon_nova"))
								{
									WhatGun[client] = 5;
								}
								GivePlayerItem(client, g_szSelectedWeapon[client]);
								Useda[client] = true;
							}
							else
							{
								PrintToChat(client, " \x04[VIP]\x01 You have to live!");
							}
						}
					}
					else
					{
						PrintToChat(client, " \x04[VIP]\x01 You already chosen gun!");
					}
				}
				else
				{
					PrintToChat(client, " \x04[VIP]\x01 Time for choosing gun is gone!");
				}
			}
			else
			{
				PrintToChat(client, " \x04[VIP]\x01 You have to wait for third round!");
			}
		}
		case MenuAction_End:
	    {
	    	delete menu;
	    }
	}
}


void RemovePrimaryWeapons(int client)
{
	if (IsValidClient(client))
	{
		int iWepIndex = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		
		if (iWepIndex != -1)
		{
			RemovePlayerItem(client, iWepIndex);
			AcceptEntityInput(iWepIndex, "Kill");
		}
	}
}

void RemoveSecondaryWeapons(int client)
{
	if (IsValidClient(client))
	{
		int iWepIndex = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		
		if (iWepIndex != -1)
		{
			RemovePlayerItem(client, iWepIndex);
			AcceptEntityInput(iWepIndex, "Kill");
		}
	}
}

public Action VIPtag(Handle timer)
{
	if (g_cVIPguntimer.IntValue >= 1)
	{
		if (timeout >= 1)
		{
			timeout--;
		}
	}
	
	if (g_cVIPadverts.IntValue >= 1)
	{
		if (advert >= 1)
		{
			advert--;
		}
		else if (advert == 0)
		{
			advert = g_cVIPadverts.IntValue;
			PrintToChatAll(" \x04[VIP]\x01 Buy VIP and get very cool benefits ! Write in chat \x04/vip");
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (IsClientVIP(i))
			{
				CS_SetClientClanTag(i, "[VIP]");
			}
		}
	}
}

stock bool IsValidClient(int client, bool alive = false)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}

stock bool IsClientVIP(int client)
{
	return CheckCommandAccess(client, "", ADMFLAG_RESERVATION);
}

stock void Func_SetPlayerArmor(int client, int health = 100, int type = 1)
{
	if (IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", health, type);
	}
} 

stock void WhatGunGive(int client)
{
	if(WhatGun[client] == 1)
	{
		RemovePrimaryWeapons(client);
		RemoveSecondaryWeapons(client);
		GivePlayerItem(client, "weapon_ak47");
	}
	else if(WhatGun[client] == 2)
	{
		RemovePrimaryWeapons(client);
		RemoveSecondaryWeapons(client);
		GivePlayerItem(client, "weapon_m4a1");
	}
	else if(WhatGun[client] == 3)
	{
		RemovePrimaryWeapons(client);
		RemoveSecondaryWeapons(client);
		GivePlayerItem(client, "weapon_m4a1_silencer");
	}
	else if(WhatGun[client] == 4)
	{
		RemovePrimaryWeapons(client);
		RemoveSecondaryWeapons(client);
		GivePlayerItem(client, "weapon_awp");
	}
	else if(WhatGun[client] == 5)
	{
		RemovePrimaryWeapons(client);
		RemoveSecondaryWeapons(client);
		GivePlayerItem(client, "weapon_nova");
	}
}