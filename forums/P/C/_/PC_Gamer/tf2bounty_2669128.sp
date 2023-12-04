#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.3"

#define CONTRACT    "vo/pauling/plng_give_bigcontract_allclass_05.mp3"
#define DUEL    "ui/duel_event.wav" 
#define AWARD    "misc/achievement_earned.wav" 
#define REWARD 	"vo/pauling/plng_contract_complete_rareitem_allclass_05.mp3" 

Handle g_Bounty = INVALID_HANDLE;
Handle g_BountyRound = INVALID_HANDLE;
Handle g_BountyStart = INVALID_HANDLE;
Handle g_BountyKills = INVALID_HANDLE;
Handle g_BountyBonus = INVALID_HANDLE;

int ClientBounty[MAXPLAYERS+1];
bool ClientHasBounty[MAXPLAYERS+1] ={false, ...};
int ClientKills[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "TF2 Bounty",
	author = "PC Gamer, using code from Bugs and Dr!fter",
	description = "Place and collect Bounty on TF2 players",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	g_Bounty = CreateConVar("sm_bountyenable", "1", "Disable or enable bounty plugin");
	g_BountyRound = CreateConVar("sm_bounty_round", "250", "Money to add to player bounties if they survive the round");
	g_BountyKills = CreateConVar("sm_bounty_kills", "5", "Kills needed before player has a bounty");
	g_BountyStart = CreateConVar("sm_bounty_start", "500", "Start money of bounty after sm_bounty_kills is reached");
	g_BountyBonus = CreateConVar("sm_bounty_bonus", "50", "Money added to players bounty per kill");
	
	RegAdminCmd("sm_setbounty", SetBounty, ADMFLAG_SLAY, "Set bounty on a player.");
	
	RegConsoleCmd("sm_showbounties", DisplayBountyPanel, "shows current bounties");	
	RegConsoleCmd("sm_showbounty", DisplayBountyPanel, "shows current bounties");
	RegConsoleCmd("sm_bounty", DisplayBountyPanel, "shows current bounties");
	RegConsoleCmd("sm_bounties", DisplayBountyPanel, "shows current bounties");
	
	SetupHooks();
}

public void OnMapStart()
{
	ResetBounties();
	PrecacheSound(CONTRACT);	
	PrecacheSound(DUEL); 
	PrecacheSound(AWARD); 
	PrecacheSound(REWARD);  	
}

public Action EventPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarBool(g_Bounty))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(!IsValidClient(client) || !IsValidClient(attacker))
		{
			return Plugin_Handled;
		}
		
		char AttackerName[100];
		char ClientName[100];
		GetClientName(attacker, AttackerName, sizeof(AttackerName));
		GetClientName(client, ClientName, sizeof(ClientName));
		if(IsValidKill(client, attacker))
		{
			ClientKills[attacker]++;

			//Time to see if the killed client had a bounty

			// He's gotten a kill and already had bounty
			if(ClientHasBounty[attacker])
			{
				ClientBounty[attacker] += GetConVarInt(g_BountyBonus);
			}

			//Has hit bounty kills
			if(ClientKills[attacker] == GetConVarInt(g_BountyKills) && !ClientHasBounty[attacker])
			{
				ClientHasBounty[attacker] = true;
				ClientBounty[attacker] = GetConVarInt(g_BountyStart);
				int amount = GetConVarInt(g_BountyStart);

				EmitSoundToAll(DUEL);
				EmitSoundToAll(CONTRACT);
				SetEntProp(attacker, Prop_Send, "m_bGlowEnabled", 1, 1);	 	
				PrintToChatAll("\x03%N has a Bounty set on them for $%i", attacker, amount);

				for (int i = 1; i <= MaxClients; i++)
				{
					if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
					{
						SetHudTextParams(-1.0, 0.3, 25.0, 255, 255, 255, 255, 0, 25.0, 4.0, 4.0);
						ShowHudText(i, -1, "Bounty!: %N has a Bounty set on them for $%i", attacker, amount);
					}
				}
			}

			if(ClientHasBounty[client])
			{
				PrintToChatAll("\x03%s has taken %s\'s Bounty of $%d", AttackerName, ClientName, ClientBounty[client]);

				for (int i = 1; i <= MaxClients; i++)
				{
					if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
					{
						SetHudTextParams(-1.0, 0.3, 25.0, 255, 255, 255, 255, 0, 25.0, 4.0, 4.0);
						ShowHudText(i, -1, "Bounty!: %s has taken %s\'s Bounty of $%d", AttackerName, ClientName, ClientBounty[client]);
					}
				}

				EmitSoundToAll(AWARD); 
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);	
				//Give attacker the money!
				int attackerMoney = GetCash(attacker);
				attackerMoney += ClientBounty[client];
				//SetEntProp(attacker, Prop_Send, "m_nCurrency", attackerMoney);
				SetCash(attacker, attackerMoney);				
				ClientHasBounty[client] = false;
				ClientBounty[client] = 0;				
				ClientKills[client] = 0;
				CreateTimer(2.0, Command_Getsound);
			}
			ClientKills[client] = 0;
			ClientHasBounty[client] = false;
			ClientBounty[client] = 0;			
		}
	}
	return Plugin_Handled;
}
public void EventRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= 32; i++)
	{
		if(IsClientInGame(i) && ClientHasBounty[i] && IsPlayerAlive(i))
		{
			ClientBounty[i] += GetConVarInt(g_BountyRound);
			PrintToChat(i, "\x03You have an active bounty of $%d", ClientBounty[i]);
			PrintCenterText(i, "You have an active bounty of $%d", ClientBounty[i]);
		}
		if(IsClientInGame(i) && !IsPlayerAlive(i))
		{
			ClientHasBounty[i] = false;
			ClientBounty[i] = 0;
		}
	}
}

public void EventInv(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && ClientHasBounty[client] && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1, 1);
		PrintToChat(client, "\x03You have an active bounty of $%d", ClientBounty[client]);
		PrintCenterText(client, "You have an active bounty of $%d", ClientBounty[client]);
	}
}

public void OnClientDisconnect(int client)
{
	ClientBounty[client] = 0;
	ClientHasBounty[client] = false;
}

//Private Functions
Action ResetBounties()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		ClientBounty[i] = 0;
		ClientHasBounty[i] = false;
	}
	return Plugin_Handled;
}
Action SetupHooks()
{
	//Hook events!
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd);
	HookEvent("post_inventory_application", EventInv, EventHookMode_Post);
	
	return Plugin_Handled;
}

public Action DisplayBountyPanel(int client, any any)
{
	bool bounty;
	Handle BountyPanel = CreatePanel();
	SetPanelTitle(BountyPanel, "Current Bounties");
	for (int i = 1; i <= MaxClients; i++)
	{
		if(ClientHasBounty[i])
		{
			bounty = true;
			char name[100];
			char text[120];
			GetClientName(i, name, sizeof(name));
			Format(text, sizeof(text), "%s  |  $%d", name, ClientBounty[i]);
			DrawPanelText(BountyPanel, text);
		}
	}
	if(bounty)
	{
		DrawPanelText(BountyPanel, "Press 0 to exit");
		SendPanelToClient(BountyPanel, client, MenuHandle, 10);
	}
	else
	PrintToChat(client, "\x04No one has a Bounty");

	return Plugin_Handled;
}
//Menu panel for the panel Thanks to ^Bugs^ for the MenuHandle bit
public int MenuHandle(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End)
	{
		//	Nothing... just an empty function.
		CloseHandle(menu);
	}

	return 1;
}
//Stocks
stock bool IsValidKill(int client, int attacker)
{
	if(client != 0 && attacker != 0 && client != attacker && client <= 32 && attacker <= 32 && GetClientTeam(client) != GetClientTeam(attacker))
	return true;
	//anything else is false
	return false;
}
public Action SetBounty(int client, int args)
{
	char targetName[128];
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] sm_setbounty <target> <amount>");
		return Plugin_Handled;
	}
	GetCmdArg(1, targetName, sizeof(targetName));
	int targetClient = FindTarget(client, targetName, false, true);
	if(targetClient == -1) 
	{
		PrintToChat(client, "\x04Unknown Target");
		return Plugin_Handled;
	}
	GetClientName(targetClient, targetName, sizeof(targetName));
	char stringint[10];
	GetCmdArg(2, stringint, sizeof(stringint));
	int amount = StringToInt(stringint);
	ClientBounty[targetClient] = amount;
	ClientHasBounty[targetClient] = true;
	EmitSoundToAll(DUEL);
	EmitSoundToAll(CONTRACT);
	SetEntProp(targetClient, Prop_Send, "m_bGlowEnabled", 1, 1);	 	
	PrintToChatAll("\x03%s has a Bounty set on them for $%i", targetName, amount);

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			SetHudTextParams(-1.0, 0.3, 25.0, 255, 255, 255, 255, 0, 25.0, 4.0, 4.0);
			ShowHudText(i, -1, "Bounty!: %s has a Bounty set on them for $%i", targetName, amount);
		}
	}

	return Plugin_Handled;
}

stock Action SetCash(int client, int iAmount)
{
	if(iAmount < 0) iAmount = 0;
	SetEntProp(client, Prop_Send, "m_nCurrency", iAmount);
	
	return Plugin_Handled;
}

stock int GetCash(int client)
{
	return GetEntProp(client, Prop_Send, "m_nCurrency");
}

public Action Command_Getsound(Handle timer) 
{
	EmitSoundToAll(REWARD);
	return Plugin_Handled;	
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > 32) return false;
	return IsClientInGame(client);
}