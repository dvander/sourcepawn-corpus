#pragma semicolon 1

#include <sdktools>

#define PLUGIN_VERSION "1.2"

#define CONTRACT    "vo/pauling/plng_give_bigcontract_allclass_05.mp3"
#define DUEL    "ui/duel_event.wav" 
#define AWARD    "misc/achievement_earned.wav" 
#define REWARD 	"vo/pauling/plng_contract_complete_rareitem_allclass_05.mp3" 

new Handle:g_Bounty = INVALID_HANDLE;
new Handle:g_BountyRound = INVALID_HANDLE;
new Handle:g_BountyStart = INVALID_HANDLE;
new Handle:g_BountyKills = INVALID_HANDLE;
new Handle:g_BountyKill = INVALID_HANDLE;

new ClientBounty[MAXPLAYERS+1];
new bool:ClientHasBounty[MAXPLAYERS+1] ={false, ...};
new ClientKills[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "TF2 Bounty",
	author = "Bugs and Dr!fter, modified by PC Gamer",
	description = "Place and collect Bounty on TF2 players",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	g_Bounty = CreateConVar("sm_bountyenable", "1", "Disable or enable bounty plugin");
	g_BountyRound = CreateConVar("sm_bounty_round", "250", "Money to add to player bounties if they survive the round");
	g_BountyKills = CreateConVar("sm_bounty_kills", "5", "Kills needed before player has a bounty");
	g_BountyStart = CreateConVar("sm_bounty_start", "500", "Start money of bounty after sm_bounty_kills is reached");
	g_BountyKill = CreateConVar("sm_bounty_bonus", "50", "Money added to players bounty per kill");
	
	RegAdminCmd("sm_setbounty", SetBounty, ADMFLAG_SLAY, "Set bounty on a player.");
	
	RegConsoleCmd("sm_showbounties", DisplayBountyPanel, "shows current bounties");	
	RegConsoleCmd("sm_showbounty", DisplayBountyPanel, "shows current bounties");
	RegConsoleCmd("sm_bounty", DisplayBountyPanel, "shows current bounties");
	RegConsoleCmd("sm_bounties", DisplayBountyPanel, "shows current bounties");
	
	SetupHooks();
}

public OnMapStart()
{
	ResetAll();
	PrecacheSound(CONTRACT);	
	PrecacheSound(DUEL); 
	PrecacheSound(AWARD); 
	PrecacheSound(REWARD);  	
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_Bounty))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(!IsValidClient(client) || !IsValidClient(attacker))
		{
			return;
		}
		
		new String:AttackerName[100];
		new String:ClientName[100];
		GetClientName(attacker, AttackerName, sizeof(AttackerName));
		GetClientName(client, ClientName, sizeof(ClientName));
		if(IsValidKill(client, attacker))
		{
			ClientKills[attacker]++;

			//Time to see if the killed client had a bounty

			// He's gotten a kill and already had bounty
			if(ClientHasBounty[attacker])
			{
				ClientBounty[attacker] += GetConVarInt(g_BountyKill);
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

				decl AllPlayers;
				AllPlayers = 32;
				for(new A = 1; A <= AllPlayers; A++)
				{
					if(IsClientConnected(A) && IsClientInGame(A) && !IsFakeClient(A))
					{
						SetHudTextParams(-1.0, 0.3, 25.0, 255, 255, 255, 255, 0, 25.0, 4.0, 4.0);
						ShowHudText(A, -1, "Bounty!: %N has a Bounty set on them for $%i", attacker, amount);
					}
				}
			}

			if(ClientHasBounty[client])
			{
				PrintToChatAll("\x03%s has taken %s\'s Bounty of $%d", AttackerName, ClientName, ClientBounty[client]);

				decl AllPlayers;
				AllPlayers = 32;
				for(new A = 1; A <= AllPlayers; A++)
				{
					if(IsClientConnected(A) && IsClientInGame(A) && !IsFakeClient(A))
					{
						SetHudTextParams(-1.0, 0.3, 25.0, 255, 255, 255, 255, 0, 25.0, 4.0, 4.0);
						ShowHudText(A, -1, "Bounty!: %s has taken %s\'s Bounty of $%d", AttackerName, ClientName, ClientBounty[client]);
					}
				}

				EmitSoundToAll(AWARD); 
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);	
				//Give attacker the money!
				new attackerMoney = GetCash(attacker);
				attackerMoney += ClientBounty[client];
				SetEntProp(attacker, Prop_Send, "m_nCurrency", attackerMoney);
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
}
public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= 32; i++)
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

public Action:EventInv(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && ClientHasBounty[client] && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1, 1);
		PrintToChat(client, "\x03You have an active bounty of $%d", ClientBounty[client]);
		PrintCenterText(client, "You have an active bounty of $%d", ClientBounty[client]);
	}
}

public OnClientDisconnect(client)
{
	ClientBounty[client] = 0;
	ClientHasBounty[client] = false;
}
//Private Functions
ResetAll()
{
	for(new i = 1; i <= 32; i++)
	{
		ClientBounty[i] = 0;
		ClientHasBounty[i] = false;
	}
}
SetupHooks()
{
	//Hook events!
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd);
	HookEvent("post_inventory_application", EventInv, EventHookMode_Post);	
}

public Action:DisplayBountyPanel(client, any)
{
	new bool:bounty;
	new Handle:BountyPanel = CreatePanel();
	SetPanelTitle(BountyPanel, "Current Bounties");
	for(new i = 1; i <= 32; i++)
	{
		if(ClientHasBounty[i])
		{
			bounty = true;
			new String:name[100];
			new String:text[120];
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
}
//Menu panel for the panel Thanks to ^Bugs^ for the MenuHandle bit
public MenuHandle(Handle:menu, MenuAction:action, parm1, parm2)
{
	if (action == MenuAction_End)
	{
		//	Nothing... just an empty function.
	}	
}
//Stocks
stock bool:IsValidKill(client, attacker)
{
	if(client != 0 && attacker != 0 && client != attacker && client <= 32 && attacker <= 32 && GetClientTeam(client) != GetClientTeam(attacker))
	return true;
	//anything else is false
	return false;
}
public Action:SetBounty(client, args)
{
	decl String:targetName[128];
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] sm_setbounty <target> <amount>");
		return Plugin_Handled;
	}
	GetCmdArg(1, targetName, sizeof(targetName));
	new targetClient = FindTarget(client, targetName, false, true);
	if(targetClient == -1) 
	{
		PrintToChat(client, "\x04Unknown Target");
		return Plugin_Handled;
	}
	GetClientName(targetClient, targetName, sizeof(targetName));
	decl String:stringint[10];
	GetCmdArg(2, stringint, sizeof(stringint));
	new amount = StringToInt(stringint);
	ClientBounty[targetClient] = amount;
	ClientHasBounty[targetClient] = true;
	EmitSoundToAll(DUEL);
	EmitSoundToAll(CONTRACT);
	SetEntProp(targetClient, Prop_Send, "m_bGlowEnabled", 1, 1);	 	
	PrintToChatAll("\x03%s has a Bounty set on them for $%i", targetName, amount);

	decl AllPlayers;
	AllPlayers = 32;
	for(new A = 1; A <= AllPlayers; A++)
	{
		if(IsClientConnected(A) && IsClientInGame(A) && !IsFakeClient(A))
		{
			SetHudTextParams(-1.0, 0.3, 25.0, 255, 255, 255, 255, 0, 25.0, 4.0, 4.0);
			ShowHudText(A, -1, "Bounty!: %s has a Bounty set on them for $%i", targetName, amount);
		}
	}

	return Plugin_Handled;
}

stock SetCash(client, iAmount)
{
	if(iAmount < 0) iAmount = 0;
	SetEntProp(client, Prop_Send, "m_nCurrency", iAmount);
}

stock GetCash(client)
{
	return GetEntProp(client, Prop_Send, "m_nCurrency");
}

public Action:Command_Getsound(Handle timer) 
{
	EmitSoundToAll(REWARD);
	return Plugin_Handled;	
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > 32) return false;
	return IsClientInGame(client);
}