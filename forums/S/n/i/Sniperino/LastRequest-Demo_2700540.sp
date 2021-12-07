#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Sniper007"
#define PLUGIN_VERSION "2.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colors>
#include <myjailbreak>
#include <myjbwarden>
#include <myjailshop>
#include <CustomPlayerSkins>

#pragma newdecls required

bool g_bJePP = false;
bool g_bKnife = false;
bool g_bJeT[MAXPLAYERS + 1];
bool g_bJeCT[MAXPLAYERS + 1];
bool g_bStrela[MAXPLAYERS + 1];
bool g_bhaspp[MAXPLAYERS + 1];

int PocetPP;
int g_iLRCountdown;

int KolikDoKonce;

Handle g_hDataS4S;

public Plugin myinfo = 
{
	name = "LastRequest-Premium [DEMO VERSION]", 
	author = PLUGIN_AUTHOR, 
	description = "LastRequest Premium from Sniper007", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/Sniper-oo7/"
};

public void OnPluginStart()
{
	LoadTranslations("LastRequest-Premium");
	
	RegConsoleCmd("sm_pp", CMD_PP);
	RegConsoleCmd("sm_lr", CMD_PP);
	RegConsoleCmd("sm_lastrequest", CMD_PP);
	RegConsoleCmd("sm_posledniprani", CMD_PP);
	
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", OnPlayerDeath);
	
	CreateTimer(1.0, PosledniPrani, _, TIMER_REPEAT);
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/music/LR/lastrequest.mp3");
	PrecacheSound("music/LR/lastrequest.mp3", true);
}

public Action Event_RoundEnd(Event event, const char[] name, bool bDontBroadcast)
{
	g_bJePP = false;
	g_bKnife = false;
	PocetPP = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			g_bJeT[i] = false;
			g_bJeCT[i] = false;
			g_bhaspp[i] = false;
		}
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool bDontBroadcast)
{
	g_iLRCountdown = 30;
	g_bJePP = false;
	g_bKnife = false;
	PocetPP = 0;
}

public void OnClientPutInServer(int client)
{
	if (IsValidClient(client))
	{
		g_bJeT[client] = false;
		g_bJeCT[client] = false;
	}
}

public void OnClientDisconnect(int client)
{
	if (IsValidClient(client))
	{
		g_bJeT[client] = false;
		g_bJeCT[client] = false;
	}
}

public Action PosledniPrani(Handle timer)
{
	GetMapTimeLeft(KolikDoKonce);
	
	if (GameRules_GetProp("m_bWarmupPeriod") != 1)
	{
		if (MyJailbreak_IsEventDayRunning())
		{
			char EventDay[64];
			MyJailbreak_GetEventDayName(EventDay);
			
			if (StrEqual(EventDay, "freeday", false))
			{
				if (GetTeamAliveCount(2) == 1 && GetTeamAliveCount(3) >= 1)
				{
					if (g_bJePP == false)
					{
						g_bJePP = true;
						ServerCommand("mp_solid_teammates 0");
					}
					
					if (g_bJePP == true)
					{
						if (g_iLRCountdown > 0)
						{
							g_iLRCountdown--;
						}
					}
					
					if (g_iLRCountdown == 0)
					{
						g_iLRCountdown = -1;
						for (int i = 1; i <= MaxClients; i++)
						{
							if (IsValidClient(i))
							{
								if (IsPlayerAlive(i))
								{
									if (GetClientTeam(i) == CS_TEAM_T)
									{
										ForcePlayerSuicide(i);
										CPrintToChatAll(" \x04[LR]\x01 %t", "lr_timeout", i);
									}
								}
							}
						}
					}
					
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i))
						{
							if (g_bJePP == true)
							{
								if (g_iLRCountdown > 0)
								{
									SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
									PrintCenterText(i, "\n[<font color='#00FF00'>LR</font>] Time to choose last request: <font color='#FF0000'>%i</font>", g_iLRCountdown);
									if (GetClientTeam(i) == CS_TEAM_T)
									{
										if (IsPlayerAlive(i))
										{
											if (g_bhaspp[i] == false)
											{
												g_bhaspp[i] = true;
												FakeClientCommand(i, "sm_lr");
											}
										}
									}
								}
							}
							
							if (GetClientTeam(i) == CS_TEAM_T)
							{
								if (IsPlayerAlive(i))
								{
									if (g_bJeT[i] == false)
									{
										g_bJeT[i] = true;
										SetClientListeningFlags(i, VOICE_NORMAL);
									}
								}
							}
						}
					}
				}
			}
		}
		else
		{
			if (GetTeamAliveCount(2) == 1 && GetTeamAliveCount(3) >= 1)
			{
				if (g_bJePP == false)
				{
					g_bJePP = true;
					ServerCommand("mp_solid_teammates 0");
				}
				
				if (g_bJePP == true)
				{
					if (g_iLRCountdown > 0)
					{
						g_iLRCountdown--;
					}
				}
				
				if (g_iLRCountdown == 0)
				{
					g_iLRCountdown = -1;
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i))
						{
							if (IsPlayerAlive(i))
							{
								if (GetClientTeam(i) == CS_TEAM_T)
								{
									ForcePlayerSuicide(i);
									CPrintToChatAll(" \x04[LR]\x01 %t", "lr_timeout", i);
								}
							}
						}
					}
				}
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						if (g_bJePP == true)
						{
							if (g_iLRCountdown > 0)
							{
								SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
								PrintCenterText(i, "\n[<font color='#00FF00'>LR</font>] Time to choose last request: <font color='#FF0000'>%i</font>", g_iLRCountdown);
								if (GetClientTeam(i) == CS_TEAM_T)
								{
									if (IsPlayerAlive(i))
									{
										if (g_bhaspp[i] == false)
										{
											g_bhaspp[i] = true;
											FakeClientCommand(i, "sm_pp");
										}
									}
								}
							}
						}
						
						if (GetClientTeam(i) == CS_TEAM_T)
						{
							if (IsPlayerAlive(i))
							{
								if (g_bJeT[i] == false)
								{
									g_bJeT[i] = true;
								}
								
								if (!(KolikDoKonce > 0))
								{
									if (g_bJeT[i] == true)
									{
										FakeClientCommand(i, "sm_pp");
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action CMD_PP(int client, int args)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (GetClientTeam(client) == CS_TEAM_T)
		{
			if (MyJailbreak_IsEventDayRunning())
			{
				char EventDay[64];
				MyJailbreak_GetEventDayName(EventDay);
				
				if (StrEqual(EventDay, "freeday", false))
				{
					if (g_bKnife == false)
					{
						if (GetTeamAliveCount(2) == 1 && GetTeamAliveCount(3) >= 1)
						{
							openPP(client);
						}
						else
						{
							CReplyToCommand(client, " \x04[LR]\x01 %t", "lr_none");
						}
					}
					else
					{
						CReplyToCommand(client, " \x04[LR]\x01 %t", "lr_active");
					}
				}
				else
				{
					CReplyToCommand(client, " \x04[LR]\x01 %t", "lr_dayactive");
				}
			}
			else
			{
				if (g_bKnife == false)
				{
					if (GetTeamAliveCount(2) == 1 && GetTeamAliveCount(3) >= 1)
					{
						openPP(client);
					}
					else
					{
						CReplyToCommand(client, " \x04[LR]\x01 %t", "lr_none");
					}
				}
				else
				{
					CReplyToCommand(client, " \x04[LR]\x01 %t", "lr_active");
				}
			}
		}
	}
}

//MENU

void openPP(int client)
{
	Menu menu = new Menu(mPPHandler);
	
	menu.SetTitle("Choose last request:");
	
	char EventDay[64];
	MyJailbreak_GetEventDayName(EventDay);
	if (g_bKnife == false)
	{
		menu.AddItem("pp3", "Knife Fight");
	}
	else
	{
		menu.AddItem("pp3", "Knife Fight", ITEMDRAW_DISABLED);
	}
	
	menu.ExitBackButton = true;
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int mPPHandler(Menu menu, MenuAction action, int client, int index)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (IsValidClient(client))
			{
				if (GetTeamAliveCount(2) == 1 && GetTeamAliveCount(3) >= 1)
				{
					char szItem[32];
					menu.GetItem(index, szItem, sizeof(szItem));
					
					if (StrEqual(szItem, "pp3"))
					{
						CMD_KNIFE(client);
					}
				}
				else
				{
					CReplyToCommand(client, " \x04[LR]\x01 %t", "lr_noplayers");
				}
			}
		}
		case MenuAction_Cancel:
		{
			if (index == MenuCancel_ExitBack)
			{
				if (IsValidClient(client))
				{
					openPP(client);
				}
			}
		}
	}
}

//KNIFE
//SHOT4SHOT
void CMD_KNIFE(int client)
{
	char info1[255];
	Menu menu = CreateMenu(Handler_KNIFEMenus);
	
	Format(info1, sizeof(info1), "Choose player:", client);
	menu.SetTitle(info1);
	
	int iValidCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			if (GetClientTeam(i) == CS_TEAM_CT)
			{
				char userid[11];
				char username[MAX_NAME_LENGTH];
				IntToString(GetClientUserId(i), userid, sizeof(userid));
				Format(username, sizeof(username), "%N", i);
				menu.AddItem(userid, username);
				iValidCount++;
			}
		}
	}
	
	if (iValidCount == 0)
	{
		Format(info1, sizeof(info1), "NO PRISON GUARDS", client);
		menu.AddItem("", info1, ITEMDRAW_DISABLED);
	}
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_KNIFEMenus(Menu menu5, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		char name[32];
		menu5.GetItem(Position, name, sizeof(name));
		int user = GetClientOfUserId(StringToInt(name));
		
		if (IsValidClient(user))
		{
			g_hDataS4S = CreateDataPack();
			WritePackCell(g_hDataS4S, user);
			
			char info[255];
			Menu menu6 = CreateMenu(Handler_KNIFE);
			
			Format(info, sizeof(info), "Choose Knife Duel:", client);
			menu6.SetTitle(info);
			Format(info, sizeof(info), "Turn on Duel", client);
			menu6.AddItem("1", info);
			menu6.ExitBackButton = true;
			menu6.ExitButton = true;
			menu6.Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (Position == MenuCancel_ExitBack)
		{
			FakeClientCommand(client, "sm_pp");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu5;
	}
}

public int Handler_KNIFE(Menu menu6, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		
		ResetPack(g_hDataS4S);
		int user = ReadPackCell(g_hDataS4S);
		
		menu6.GetItem(Position, info, sizeof(info));
		
		if (strcmp(info, "1") == 0) // next round
		{
			if (IsValidClient(user))
			{
				if (IsPlayerAlive(user))
				{
					if (g_bJeCT[user] == false)
					{
						if (GetClientTeam(user) == CS_TEAM_CT)
						{
							g_bJeCT[user] = true;
							CPrintToChatAll(" \x04[LR]\x01 %t", "lr_choosen", user);
							CPrintToChat(user, " \x04[LR]\x01 %t", "lr_playerchosen");
							PocetPP++;
						}
					}
					
					g_bKnife = true;
					g_iLRCountdown = -1;
					EmitSoundToAll("music/LR/lastrequest.mp3", client, SNDCHAN_STREAM);
					CPrintToChatAll(" \x04[LR]\x01 %t", "lr_knife", client);
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i) && IsPlayerAlive(i))
						{
							PrintCenterText(i, "\n[<font color='#00FF00'>LR</font>] <font color='#0000FF'>%N</font> VS. <font color='#FF0000'>%N</font>", user, client);
							if (g_bJeCT[i] == true || g_bJeT[i] == true)
							{
								SetEntProp(i, Prop_Data, "m_iMaxHealth", 100);
								SetEntProp(i, Prop_Send, "m_iHealth", 100);
								SetEntProp(i, Prop_Data, "m_iMaxHealth", 1);
							}
						}
					}
				}
				else
				{
					CPrintToChatAll(" \x04[LR]\x01 %t", "lr_noalivect", client);
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (Position == MenuCancel_ExitBack)
		{
			FakeClientCommand(client, "sm_pp");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu6;
	}
}

public Action OpenPP(Handle timer, int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		openPP(client);
	}
}

//SMRT

public void OnPlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client))
	{
		if (g_bJeCT[client] == true)
		{
			CreateTimer(0.1, Konec);
			g_bJeCT[client] = false;
		}
		
		if (g_bJeT[client] == true)
		{
			CreateTimer(0.1, Konec);
			g_bJeT[client] = false;
		}
	}
}

public Action Konec(Handle timer)
{
	g_bKnife = false;
	PocetPP = 0;
	g_iLRCountdown = 30;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (IsPlayerAlive(i))
			{
				g_bStrela[i] = false;
				if (GetClientTeam(i) == CS_TEAM_T)
				{
					FakeClientCommand(i, "sm_pp");
				}
			}
		}
	}
}

/*
public Action Konec2(Handle timer)
{
	g_bShot4Shot = false;
	g_bNoScope = false;
	g_bKnife = false;
	g_bJePP = false;
	PocetPP = 0;
}
*/

stock int GetTeamAliveCount(int iTeamNum)
{
	int iCount;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	if (IsClientInGame(iClient) && GetClientTeam(iClient) == iTeamNum && IsPlayerAlive(iClient))
		iCount++;
	return iCount;
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
	return CheckCommandAccess(client, "", ADMFLAG_CUSTOM4);
}