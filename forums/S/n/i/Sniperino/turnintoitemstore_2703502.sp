#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Sniper007"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <store>
#include <colors>

#pragma newdecls required

int i_suit[MAXPLAYERS + 1];
int i_suitusage[MAXPLAYERS + 1];
int i_Cooldown[MAXPLAYERS + 1];
int i_typeofsuit[MAXPLAYERS + 1];

bool g_bSuit[MAXPLAYERS + 1] = false;
bool g_bSuitOn[MAXPLAYERS + 1] = false;

ConVar g_cSUITeffect;
ConVar g_cSUITusage;
ConVar g_cSUITsound;
ConVar g_cSUITvip;
ConVar g_cSUITradio;
ConVar g_cSUITcouch;
ConVar g_cSUITbarstool;
ConVar g_cSUITwagon;
ConVar g_cSUITbed;
ConVar g_cSUITmetalcrate;
ConVar g_cSUITbookcase;
ConVar g_cSUITmailbox;
ConVar g_cSUIThsmap;

public Plugin myinfo = 
{
	name = "Turn into items CS:GO", 
	author = PLUGIN_AUTHOR, 
	description = "Menu that allow you to turn into item", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/Sniper-oo7/"
};

public void OnPluginStart()
{
	LoadTranslations("TurnIntoItemStore");
	
	RegConsoleCmd("sm_suit", CMD_Suit);
	
	HookEvent("round_start", Event_RoundStart);
	
	//SUIT PRICES
	g_cSUITradio = CreateConVar("sm_suit_radio", "500", "How much credits for radio suit");
	g_cSUITcouch = CreateConVar("sm_suit_couch", "600", "How much credits for couch suit");
	g_cSUITbarstool = CreateConVar("sm_suit_barstool", "700", "How much credits for barstool suit");
	g_cSUITwagon = CreateConVar("sm_suit_wagon", "900", "How much credits for wagon suit");
	g_cSUITbed = CreateConVar("sm_suit_bed", "600", "How much credits for bed suit");
	g_cSUITmetalcrate = CreateConVar("sm_suit_metalcrate", "600", "How much credits for metalcrate suit");
	g_cSUITbookcase = CreateConVar("sm_suit_bookcase", "700", "How much credits for bookcase suit");
	g_cSUITmailbox = CreateConVar("sm_suit_mailbox", "500", "How much credits for mailbox suit");
	//OTHERS
	g_cSUITeffect = CreateConVar("sm_suit_effect", "15", "Suit effect in sec, 0 = suit move system");
	g_cSUITusage = CreateConVar("sm_suit_usage", "4", "How many times can player use suit");
	g_cSUITsound = CreateConVar("sm_suit_sound_effect", "1", "Sound effect suit");
	g_cSUIThsmap = CreateConVar("sm_suit_hs_map_team", "1", "HideASeek map support teams, 0 = everyone can use menu");
	g_cSUITvip = CreateConVar("sm_suit_vip_suit", "1", "Reserved suits for VIP, 0 = disabled");
	
	AutoExecConfig(true, "TurnIntoItem");
	
	CreateTimer(1.0, TimerSuit, _, TIMER_REPEAT);
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/music/suit/suit_up.mp3");
	PrecacheSound("music/suit/suit_up.mp3");
	
	PrecacheModel("models/props/cs_militia/couch.mdl");
	PrecacheModel("models/props/cs_italy/radio_wooden.mdl");
	PrecacheModel("models/props/de_dust/wagon.mdl");
	PrecacheModel("models/props/cs_militia/barstool01.mdl");
	PrecacheModel("models/props/de_inferno/bed.mdl");
	PrecacheModel("models/props/de_dust/dust_metal_crate.mdl");
	PrecacheModel("models/props/cs_havana/bookcase_large.mdl");
	PrecacheModel("models/props/cs_militia/mailbox01.mdl");
	
	int i = -1;
	while ((i = FindEntityByClassname(i, "env_cascade_light")) != -1)
	{
		AcceptEntityInput(i, "Kill");
	}
}

public Action CMD_Suit(int client, int args)
{
	if (IsValidClient(client))
	{
		if (IsPlayerAlive(client))
		{
			if(g_cSUIThsmap.IntValue > 0)
			{
				char MapName[128];
				GetCurrentMap(MapName, sizeof(MapName));
				
				if (strncmp(MapName, "seek_house", 8) == 0)
				{
					if (GetClientTeam(client) == CS_TEAM_CT)
					{
						openSuit(client);
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nohider");
					}
				}
				else if (strncmp(MapName, "hs_mirage", 8) == 0)
				{
					if (GetClientTeam(client) == CS_TEAM_T)
					{
						openSuit(client);
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nohider");
					}
				}
				else if (strncmp(MapName, "qwertyu", 8) == 0)
				{
					if (GetClientTeam(client) == CS_TEAM_T)
					{
						openSuit(client);
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nohider");
					}
				}
				else if (strncmp(MapName, "seek_haus_night", 8) == 0)
				{
					if (GetClientTeam(client) == CS_TEAM_CT)
					{
						openSuit(client);
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nohider");
					}
				}
				else if (strncmp(MapName, "hs_italy", 8) == 0)
				{
					if (GetClientTeam(client) == CS_TEAM_T)
					{
						openSuit(client);
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nohider");
					}
				}
				else if (strncmp(MapName, "hs_office", 8) == 0)
				{
					if (GetClientTeam(client) == CS_TEAM_T)
					{
						openSuit(client);
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nohider");
					}
				}
				else
				{
					CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nomap");
				}
			}
			else
			{
				openSuit(client);
			}
		}
	}
	return Plugin_Handled;
}

public void Event_RoundStart(Event event, const char[] name, bool bDontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			i_suitusage[i] = 0;
			i_suit[i] = 0;
			i_typeofsuit[i] = 0;
			i_Cooldown[i] = 0;
			g_bSuit[i] = false;
			g_bSuitOn[i] = false;
		}
	}
}

void openSuit(int client)
{
	char text[64];
	
	Menu menu = new Menu(mSuitHandler);
	
	menu.SetTitle("Choose the suit:");
	
	Format(text, sizeof(text), "Radio [%i credits]", g_cSUITradio.IntValue);
	menu.AddItem("suit1", text);
	Format(text, sizeof(text), "Couch [%i credits]", g_cSUITcouch.IntValue);
	menu.AddItem("suit2", text);
	Format(text, sizeof(text), "Bar-Stool [%i credits]", g_cSUITbarstool.IntValue);
	menu.AddItem("suit3", text);
	Format(text, sizeof(text), "Wagon [%i credits]", g_cSUITwagon.IntValue);
	menu.AddItem("suit4", text);
	if(g_cSUITvip.IntValue > 0)
	{
		if(IsClientVIP(client))
		{
			Format(text, sizeof(text), "Bed [%i credits]", g_cSUITbed.IntValue);
			menu.AddItem("suit5", text);
			Format(text, sizeof(text), "Metal Crate [%i credits]", g_cSUITmetalcrate.IntValue);
			menu.AddItem("suit6", text);
			Format(text, sizeof(text), "BookCase [%i credits]", g_cSUITbookcase.IntValue);
			menu.AddItem("suit7", text);
			Format(text, sizeof(text), "MailBox [%i credits]", g_cSUITmailbox.IntValue);
			menu.AddItem("suit8", text);
		}
		else
		{
			Format(text, sizeof(text), "Bed [%i credits]", g_cSUITbed.IntValue);
			menu.AddItem("suit5", text, ITEMDRAW_DISABLED);
			Format(text, sizeof(text), "Metal Crate [%i credits]", g_cSUITmetalcrate.IntValue);
			menu.AddItem("suit6", text, ITEMDRAW_DISABLED);
			Format(text, sizeof(text), "BookCase [%i credits]", g_cSUITbookcase.IntValue);
			menu.AddItem("suit7", text, ITEMDRAW_DISABLED);
			Format(text, sizeof(text), "MailBox [%i credits]", g_cSUITmailbox.IntValue);
			menu.AddItem("suit8", text, ITEMDRAW_DISABLED);
		}
	}
	else
	{
		Format(text, sizeof(text), "Bed [%i credits]", g_cSUITbed.IntValue);
		menu.AddItem("suit5", text);
		Format(text, sizeof(text), "Metal Crate [%i credits]", g_cSUITmetalcrate.IntValue);
		menu.AddItem("suit6", text);
		Format(text, sizeof(text), "BookCase [%i credits]", g_cSUITbookcase.IntValue);
		menu.AddItem("suit7", text);
		Format(text, sizeof(text), "MailBox [%i credits]", g_cSUITmailbox.IntValue);
		menu.AddItem("suit8", text);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int mSuitHandler(Menu menu, MenuAction action, int client, int index)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				char szItem[32];
				menu.GetItem(index, szItem, sizeof(szItem));
				
				if (StrEqual(szItem, "suit1"))
				{
					if (i_suitusage[client] < g_cSUITusage.IntValue)
					{
						if (Store_GetClientCredits(client) >= g_cSUITbed.IntValue)
						{
							if (i_suit[client] == 0)
							{
								Store_SetClientCredits(client, Store_GetClientCredits(client) - g_cSUITbed.IntValue);
								CPrintToChat(client, " \x04[HNS] \x01%t", "hns_radio", Store_GetClientCredits(client));
								i_suitusage[client]++;
								i_typeofsuit[client] = 1;
								if (g_cSUITeffect.IntValue > 0)
								{
									i_suit[client] = g_cSUITeffect.IntValue;
									CreateTimer(g_cSUITeffect.FloatValue, EndEffect, client);
									RemoveKnife(client);
									SetEntityModel(client, "models/props/cs_italy/radio_wooden.mdl");
									if(g_cSUITsound.IntValue > 0)
									{
										EmitSoundToClient(client, "music/suit/suit_up.mp3");
									}
								}
							}
							else
							{
								CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_inuse", i_suit[client]);
							}
						}
						else
						{
							CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nocredits");
						}
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nousage");
					}
				}
				else if (StrEqual(szItem, "suit2"))
				{
					if (i_suitusage[client] < g_cSUITusage.IntValue)
					{
						if (Store_GetClientCredits(client) >= g_cSUITcouch.IntValue)
						{
							if (i_suit[client] == 0)
							{
								Store_SetClientCredits(client, Store_GetClientCredits(client) - g_cSUITcouch.IntValue);
								CPrintToChat(client, " \x04[HNS] \x01%t", "hns_couch", Store_GetClientCredits(client));
								i_suitusage[client]++;
								i_typeofsuit[client] = 2;
								if (g_cSUITeffect.IntValue > 0)
								{
									i_suit[client] = g_cSUITeffect.IntValue;
									SetEntityModel(client, "models/props/cs_militia/couch.mdl");
									CreateTimer(g_cSUITeffect.FloatValue, EndEffect, client);
									RemoveKnife(client);
									if(g_cSUITsound.IntValue > 0)
									{
										EmitSoundToClient(client, "music/suit/suit_up.mp3");
									}
								}
							}
							else
							{
								CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_inuse", i_suit[client]);
							}
						}
						else
						{
							CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nocredits");
						}
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nousage");
					}
				}
				else if (StrEqual(szItem, "suit3"))
				{
					if (i_suitusage[client] < g_cSUITusage.IntValue)
					{
						if (Store_GetClientCredits(client) >= g_cSUITbarstool.IntValue)
						{
							if (i_suit[client] == 0)
							{
								Store_SetClientCredits(client, Store_GetClientCredits(client) - g_cSUITbarstool.IntValue);
								CPrintToChat(client, " \x04[HNS] \x01%t", "hns_barstool", Store_GetClientCredits(client));
								i_suitusage[client]++;
								i_typeofsuit[client] = 3;
								if (g_cSUITeffect.IntValue > 0)
								{
									i_suit[client] = g_cSUITeffect.IntValue;
									RemoveKnife(client);
									CreateTimer(g_cSUITeffect.FloatValue, EndEffect, client);
									SetEntityModel(client, "models/props/cs_militia/barstool01.mdl");
									if(g_cSUITsound.IntValue > 0)
									{
										EmitSoundToClient(client, "music/suit/suit_up.mp3");
									}
								}
							}
							else
							{
								CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_inuse", i_suit[client]);
							}
						}
						else
						{
							CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nocredits");
						}
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nousage");
					}
				}
				else if (StrEqual(szItem, "suit4"))
				{
					if (i_suitusage[client] < g_cSUITusage.IntValue)
					{
						if (Store_GetClientCredits(client) >= g_cSUITwagon.IntValue)
						{
							if (i_suit[client] == 0)
							{
								Store_SetClientCredits(client, Store_GetClientCredits(client) - g_cSUITwagon.IntValue);
								CPrintToChat(client, " \x04[HNS] \x01%t", "hns_wagon", Store_GetClientCredits(client));
								i_suitusage[client]++;
								i_typeofsuit[client] = 4;
								if (g_cSUITeffect.IntValue > 0)
								{
									i_suit[client] = g_cSUITeffect.IntValue;
									CreateTimer(g_cSUITeffect.FloatValue, EndEffect, client);
									SetEntityModel(client, "models/props/de_dust/wagon.mdl");
									RemoveKnife(client);
									if(g_cSUITsound.IntValue > 0)
									{
										EmitSoundToClient(client, "music/suit/suit_up.mp3");
									}
								}
							}
							else
							{
								CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_inuse", i_suit[client]);
							}
						}
						else
						{
							CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nocredits");
						}
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nousage");
					}
				}
				else if (StrEqual(szItem, "suit5"))
				{
					if (i_suitusage[client] < g_cSUITusage.IntValue)
					{
						if (Store_GetClientCredits(client) >= g_cSUITbed.IntValue)
						{
							if (i_suit[client] == 0)
							{
								Store_SetClientCredits(client, Store_GetClientCredits(client) - g_cSUITbed.IntValue);
								CPrintToChat(client, " \x04[HNS] \x01%t", "hns_bed", Store_GetClientCredits(client));
								i_suitusage[client]++;
								i_typeofsuit[client] = 5;
								if (g_cSUITeffect.IntValue > 0)
								{
									i_suit[client] = g_cSUITeffect.IntValue;
									RemoveKnife(client);
									SetEntityModel(client, "models/props/de_inferno/bed.mdl");
									CreateTimer(g_cSUITeffect.FloatValue, EndEffect, client);
									if(g_cSUITsound.IntValue > 0)
									{
										EmitSoundToClient(client, "music/suit/suit_up.mp3");
									}
								}
							}
							else
							{
								CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_inuse", i_suit[client]);
							}
						}
						else
						{
							CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nocredits");
						}
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nousage");
					}
				}
				else if (StrEqual(szItem, "suit6"))
				{
					if (i_suitusage[client] < g_cSUITusage.IntValue)
					{
						if (Store_GetClientCredits(client) >= g_cSUITmetalcrate.IntValue)
						{
							if (i_suit[client] == 0)
							{
								Store_SetClientCredits(client, Store_GetClientCredits(client) - g_cSUITmetalcrate.IntValue);
								CPrintToChat(client, " \x04[HNS] \x01%t", "hns_metalcrate", Store_GetClientCredits(client));
								i_suitusage[client]++;
								i_typeofsuit[client] = 6;
								if (g_cSUITeffect.IntValue > 0)
								{
									i_suit[client] = g_cSUITeffect.IntValue;
									RemoveKnife(client);
									SetEntityModel(client, "models/props/de_dust/dust_metal_crate.mdl");
									CreateTimer(g_cSUITeffect.FloatValue, EndEffect, client);
									if(g_cSUITsound.IntValue > 0)
									{
										EmitSoundToClient(client, "music/suit/suit_up.mp3");
									}
								}
							}
							else
							{
								CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_inuse", i_suit[client]);
							}
						}
						else
						{
							CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nocredits");
						}
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nousage");
					}
				}
				else if (StrEqual(szItem, "suit7"))
				{
					if (i_suitusage[client] < g_cSUITusage.IntValue)
					{
						if (Store_GetClientCredits(client) >= g_cSUITbookcase.IntValue)
						{
							if (i_suit[client] == 0)
							{
								Store_SetClientCredits(client, Store_GetClientCredits(client) - g_cSUITbookcase.IntValue);
								CPrintToChat(client, " \x04[HNS] \x01%t", "hns_bookcase", Store_GetClientCredits(client));
								i_suitusage[client]++;
								i_typeofsuit[client] = 7;
								if (g_cSUITeffect.IntValue > 0)
								{
									i_suit[client] = g_cSUITeffect.IntValue;
									RemoveKnife(client);
									SetEntityModel(client, "models/props/cs_havana/bookcase_large.mdl");
									CreateTimer(g_cSUITeffect.FloatValue, EndEffect, client);
									if(g_cSUITsound.IntValue > 0)
									{
										EmitSoundToClient(client, "music/suit/suit_up.mp3");
									}
								}
							}
							else
							{
								CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_inuse", i_suit[client]);
							}
						}
						else
						{
							CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nocredits");
						}
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nousage");
					}
				}
				else if (StrEqual(szItem, "suit8"))
				{
					if (i_suitusage[client] < g_cSUITusage.IntValue)
					{
						if (Store_GetClientCredits(client) >= g_cSUITmailbox.IntValue)
						{
							if (i_suit[client] == 0)
							{
								Store_SetClientCredits(client, Store_GetClientCredits(client) - g_cSUITmailbox.IntValue);
								CPrintToChat(client, " \x04[HNS] \x01%t", "hns_mailbox", Store_GetClientCredits(client));
								i_suitusage[client]++;
								i_typeofsuit[client] = 8;
								if (g_cSUITeffect.IntValue > 0)
								{
									i_suit[client] = g_cSUITeffect.IntValue;
									RemoveKnife(client);
									SetEntityModel(client, "models/props/cs_militia/mailbox01.mdl");
									CreateTimer(g_cSUITeffect.FloatValue, EndEffect, client);
									if(g_cSUITsound.IntValue > 0)
									{
										EmitSoundToClient(client, "music/suit/suit_up.mp3");
									}
								}
							}
							else
							{
								CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_inuse", i_suit[client]);
							}
						}
						else
						{
							CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nocredits");
						}
					}
					else
					{
						CReplyToCommand(client, " \x04[HNS] \x01%t", "hns_nousage");
					}
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsValidClient(client))
	{
		if (IsPlayerAlive(client))
		{
			if (g_cSUITeffect.IntValue == 0)
			{
				if (i_typeofsuit[client] > 0)
				{
					float buffer[3];
					GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", buffer);
					float bufferlength = GetVectorLength(buffer);
					if (bufferlength > 0.0)
					{
						if (g_bSuit[client] == true)
						{
							g_bSuit[client] = false;
							i_Cooldown[client] = 0;
							if (g_bSuitOn[client] == true)
							{
								PrintToChat(client, " \x04[HNS]\x01 You moved, you are now looking like a human!");
								if(GetClientTeam(client) == CS_TEAM_CT)
								{
									SetEntityModel(client, "models/player/custom_player/legacy/ctm_st6_varianti.mdl");
								}
								else
								{
									SetEntityModel(client, "models/player/custom_player/legacy/tm_leet_variantf.mdl");
								}
								int iItem = GivePlayerItem(client, "weapon_knife");
								EquipPlayerWeapon(client, iItem);
							}
							g_bSuitOn[client] = false;
						}
					}
					else
					{
						if (g_bSuit[client] == false)
						{
							i_Cooldown[client] = 3;
							g_bSuit[client] = true;
						}
						
						if (i_Cooldown[client] == 0)
						{
							if (g_bSuitOn[client] == false)
							{
								TypeOfSuitSet(client);
								g_bSuitOn[client] = true;
								RemoveKnife(client);
								PrintToChat(client, " \x04[HNS]\x01 You have now active suit!");
								if(g_cSUITsound.IntValue > 0)
								{
									EmitSoundToClient(client, "music/suit/suit_up.mp3");
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action EndEffect(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		if (IsPlayerAlive(client))
		{
			if(GetClientTeam(client) == CS_TEAM_CT)
			{
				SetEntityModel(client, "models/player/custom_player/legacy/ctm_st6_varianti.mdl");
			}
			else
			{
				SetEntityModel(client, "models/player/custom_player/legacy/tm_leet_variantf.mdl");
			}
			CPrintToChat(client, " \x04[HNS] \x01%t", "hns_human");
			int iItem = GivePlayerItem(client, "weapon_knife");
			EquipPlayerWeapon(client, iItem);
		}
	}
}

public Action TimerSuit(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (IsPlayerAlive(i))
			{
				if (i_Cooldown[i] >= 1)
				{
					i_Cooldown[i]--;
					SetHudTextParams(-1.0, 0.4, 1.02, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(i, -1, "Don't move during: %i sec", i_Cooldown[i]);
				}
				
				if (i_suit[i] >= 1)
				{
					i_suit[i]--;
					SetHudTextParams(-1.0, 0.4, 1.02, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(i, -1, "Suit Effect will expire in: %i sec", i_suit[i]);
				}
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool alive = false)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}

void RemoveKnife(int client)
{
	if (IsValidClient(client))
	{
		int iWepIndex = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		
		if (iWepIndex != -1)
		{
			RemovePlayerItem(client, iWepIndex);
			AcceptEntityInput(iWepIndex, "Kill");
		}
	}
}

stock void TypeOfSuitSet(int client)
{
	if (i_typeofsuit[client] == 1)
	{
		SetEntityModel(client, "models/props/cs_italy/radio_wooden.mdl");
	}
	else if (i_typeofsuit[client] == 2)
	{
		SetEntityModel(client, "models/props/cs_militia/couch.mdl");
	}
	else if (i_typeofsuit[client] == 3)
	{
		SetEntityModel(client, "models/props/cs_militia/barstool01.mdl");
	}
	else if (i_typeofsuit[client] == 4)
	{
		SetEntityModel(client, "models/props/de_dust/wagon.mdl");
	}
	else if (i_typeofsuit[client] == 5)
	{
		SetEntityModel(client, "models/props/de_inferno/bed.mdl");
	}
	else if (i_typeofsuit[client] == 6)
	{
		SetEntityModel(client, "models/props/de_dust/dust_metal_crate.mdl");
	}
	else if (i_typeofsuit[client] == 7)
	{
		SetEntityModel(client, "models/props/cs_havana/bookcase_large.mdl");
	}
	else if (i_typeofsuit[client] == 8)
	{
		SetEntityModel(client, "models/props/cs_militia/mailbox01.mdl");
	}
} 

stock bool IsClientVIP(int client)
{
    return CheckCommandAccess(client, "", ADMFLAG_RESERVATION);
}