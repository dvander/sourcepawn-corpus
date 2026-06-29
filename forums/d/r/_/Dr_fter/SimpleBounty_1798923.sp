#include <sourcemod>

#define PLUGIN_VERSION "1.2.2"

new Handle:g_Bounty = INVALID_HANDLE;
new Handle:g_BountyStart = INVALID_HANDLE;
new Handle:g_BountyKills = INVALID_HANDLE;
new Handle:g_BountyHeadshot = INVALID_HANDLE;
new Handle:g_BountyKill = INVALID_HANDLE;
new Handle:g_BountyRound = INVALID_HANDLE;
new Handle:g_BountyDisplay = INVALID_HANDLE;
new Handle:g_version = INVALID_HANDLE;
new Handle:g_BountyBomb = INVALID_HANDLE;
new Handle:g_BountyHostie = INVALID_HANDLE;

new ClientKills[MAXPLAYERS+1];
new ClientBounty[MAXPLAYERS+1];
new bool:ClientHasBounty[MAXPLAYERS+1] ={false, ...};

new g_MoneyOffset;

public Plugin:myinfo = 
{
	name = "Bounty",
	author = "Dr!fter",
	description = "Bounty",
	version = PLUGIN_VERSION,
	url = "www.Spawnpoint.com"
}
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	new String:modname[50];
	GetGameFolderName(modname, sizeof(modname));
	if(!StrEqual(modname,"cstrike",false) && !StrEqual(modname, "csgo", false))
		SetFailState("Game is not counter strike source!");
	
	g_version = CreateConVar("sm_simple_bounty_version", PLUGIN_VERSION, "Bounty Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Bounty = CreateConVar("sm_bounty", "1", "Disable or enable bounty plugin");
	g_BountyKills = CreateConVar("sm_bounty_kills", "5", "Kills needed before player has a bounty");
	g_BountyStart = CreateConVar("sm_bounty_start", "1000", "Start money of bounty after sm_bounty_kills is reached");
	g_BountyHeadshot = CreateConVar("sm_bounty_headshot", "125", "Headshot bonus how much more they get if the kill was a headshot.");
	g_BountyKill = CreateConVar("sm_bounty_bonus", "250", "Money added to players bounty per kill");
	g_BountyRound = CreateConVar("sm_bounty_round", "250", "Money to add to player bounties if they survive the round");
	g_BountyHostie = CreateConVar("sm_bounty_hostie", "100", "How much bounty should go up per hostie resuced");
	g_BountyBomb = CreateConVar("sm_bounty_bomb", "250", "How much bounty goes up to player that planted bomb if bomb explodes");
	g_BountyDisplay = CreateConVar("sm_bounty_display", "1", "1 = Print To chat 2 = print to center 0 = disable messages");
	
	RegAdminCmd("sm_setbounty", SetBounty, ADMFLAG_CONVARS, "Set bounty on a player.");
	
	AutoExecConfig(true, "plugins.bounty")
	
	RegConsoleCmd("say", CheckText);
	RegConsoleCmd("say_team", CheckText);
	
	g_MoneyOffset = FindSendPropOffs("CCSPlayer","m_iAccount");
	if(g_MoneyOffset == -1)
	{
		SetFailState("Can not find m_iAccount.");
	}
	
	SetupHooks();
}
public OnConfigsExecuted()
{
	SetConVarString(g_version, PLUGIN_VERSION, true, false);
}
public OnMapStart()
{
	ResetAll();
}
public Action:EventHostage(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0 && IsClientInGame(client)&& ClientHasBounty[client] && IsPlayerAlive(client))
		ClientBounty[client] += GetConVarInt(g_BountyHostie);
	
	if(ClientBounty[client] > 16000)
		ClientBounty[client] = 16000;
}
public Action:EventBomb(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0 && IsClientInGame(client) && ClientHasBounty[client] && IsPlayerAlive(client))
		ClientBounty[client] += GetConVarInt(g_BountyBomb);
	
	if(ClientBounty[client] > 16000)
		ClientBounty[client] = 16000;
}
public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_Bounty))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new bool:Headshot = GetEventBool(event, "headshot");
		new String:AttackerName[100];
		new String:ClientName[100];
		GetClientName(attacker, AttackerName, sizeof(AttackerName));
		GetClientName(client, ClientName, sizeof(ClientName));
		if(IsValidKill(client, attacker))
		{
			ClientKills[attacker]++;
			
			// He's gotten a kill and already had bounty
			if(ClientHasBounty[attacker] && ClientBounty[attacker] <= 16000)
				ClientBounty[attacker] += GetConVarInt(g_BountyKill);
			
			//His kill was also headshot give him bonus
			if(ClientHasBounty[attacker] && Headshot && ClientBounty[attacker] <= 16000)
				ClientBounty[attacker] += GetConVarInt(g_BountyHeadshot);
			
			//if greater set it to 16000
			if(ClientBounty[attacker] > 16000)
				ClientBounty[attacker] = 16000;
			
			//Has hit bounty kills
			if(ClientKills[attacker] == GetConVarInt(g_BountyKills))
			{
				ClientHasBounty[attacker] = true;
				ClientBounty[attacker] = GetConVarInt(g_BountyStart);
				
				if(GetConVarInt(g_BountyDisplay) == 1)
					PrintToChatAll("\x03%s has a bounty", AttackerName);
				else if(GetConVarInt(g_BountyDisplay) == 2)
					PrintCenterTextAll("%s has a bounty", AttackerName);
			}
			
			//Time to see if the killed client had a bounty
			if(ClientHasBounty[client])
			{
				if(GetConVarInt(g_BountyDisplay) == 1)
					PrintToChatAll("\x03%s has taken %s\'s bounty of $%d", AttackerName, ClientName, ClientBounty[client]);
				else if(GetConVarInt(g_BountyDisplay) == 2)
					PrintCenterTextAll("%s has taken %s\'s bounty of $%d", AttackerName, ClientName, ClientBounty[client]);
				
				//Give attacker the money!
				new attackerMoney = GetEntData(attacker, g_MoneyOffset);
				attackerMoney += ClientBounty[client];
				
				if(attackerMoney >= 16000)
					SetEntData(attacker, g_MoneyOffset, 16000);
				else
					SetEntData(attacker, g_MoneyOffset, attackerMoney);
			}
		}
		ClientKills[client] = 0;
		ClientHasBounty[client] = false;
		ClientBounty[client] = 0;
	}
}
public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && ClientHasBounty[i] && IsPlayerAlive(i))
		{
			ClientBounty[i] += GetConVarInt(g_BountyRound)
			if(GetConVarInt(g_BountyDisplay) == 1)
				PrintToChat(i, "\x03You have an active bounty of $%d", ClientBounty[i]);
			else if(GetConVarInt(g_BountyDisplay) == 2)
				PrintCenterText(i, "You have an active bounty of $%d", ClientBounty[i]);
		}
		if(IsClientInGame(i) && !IsPlayerAlive(i))
		{
			ClientKills[i] = 0;
			ClientHasBounty[i] = false;
			ClientBounty[i] = 0;
		}
	}
}
public Action:CheckText(client, args)
{
	decl String:text[192];
	new startidx = 0;
	if(GetCmdArgString(text, sizeof(text)) < 1)// if its more than 1 its more than just bounty so return continue
	{
		return Plugin_Continue;
	}
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	if(strcmp(text[startidx], "bounty", false) == 0)
	{
		DisplayBountyPanel(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public OnClientDisconnect(client)
{
	ClientKills[client] = 0;
	ClientBounty[client] = 0;
	ClientHasBounty[client] = false;
}
//Private Functions
ResetAll()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		ClientKills[i] = 0;
		ClientBounty[i] = 0;
		ClientHasBounty[i] = false;
	}
}
SetupHooks()
{
	//Hook events!
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd);
	HookEvent("hostage_rescued", EventHostage);
	HookEvent("bomb_exploded", EventBomb);
}
DisplayBountyPanel(client)
{
	new bool:bounty;
	new Handle:BountyPanel = CreatePanel();
	SetPanelTitle(BountyPanel, "Current Bounties");
	for(new i = 1; i <= MaxClients; i++)
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
		SendPanelToClient(BountyPanel, client, MenuHandle, 10)
	}
	else
		PrintToChat(client, "\x04No one has a bounty");
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
	if(client != 0 && attacker != 0 && client != attacker && client <= MaxClients && attacker <= MaxClients && GetClientTeam(client) != GetClientTeam(attacker))
		return true;
	//anything else is false
	return false
}
public Action:SetBounty(client, args)
{
	decl String:targetName[128];
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] sm_setbounty <target> <ammount>");
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
	new ammount = StringToInt(stringint);
	if(ammount > 16000)
		ammount = 16000;
	ClientBounty[targetClient] = ammount;
	ClientHasBounty[targetClient] = true;
	if(GetConVarInt(g_BountyDisplay) == 1)
		PrintToChatAll("\x03%s had a bounty set on them for $%i", targetName, ammount);
	else if(GetConVarInt(g_BountyDisplay) == 2)
		PrintCenterTextAll("%s had a bounty set on them for $%i", targetName, ammount);
	return Plugin_Handled;
}