/*

			Sunglasses SourceMOD Plugin
			(c) 2008 SAMURAI
			
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Sun Glasses",
	author = "SAMURAI",
	description = "Buy sunglasses and you won't be flashed",
	version = "0.1",
	url = "www.cs-utilz.net"
}

#define ALPHA_SET 0.5
#define NULL_CHAR 0
#define QUOTE_CHAR 34

// offsets
new g_iMoney = -1;
new g_iFlashAlpha = -1;
new g_inBuyzone = -1;

new bool:had_sunglasses[MAXPLAYERS + 1] = false;
new g_used_count[MAXPLAYERS + 1] = 0;

// messages
stock const String:PLAYER_BE_ALIVE[] = "You must be alive to buy sunglasses";
stock const String:NOT_ENOUGH_MONEY[] = "You don't have enough money to buy sunglasses";
stock const String:AD_MESSAGE[] = "Type 'sunglasses' in chat to buy sunglasses";
stock const String:SUCC_MSG[] = "You got sunglasses. Now you won't be flashed";
stock const String:NO_MORE_ACTIVE[] = "Sunglasses aren't active anymore";
stock const String:ONLY_BUYZONE[] = "You must be in the buyzone for buying sunglasses";

// cvars
new Handle:cvar_price = INVALID_HANDLE;
new Handle:cvar_message = INVALID_HANDLE;
new Handle:cvar_mode = INVALID_HANDLE;
new Handle:cvar_max = INVALID_HANDLE;


public OnPluginStart()
{
	RegConsoleCmd("say",CMD_BUY_SUNGLASSES,"buy sunshit");
	RegConsoleCmd("say_team",CMD_BUY_SUNGLASSES,"buy sunshit");
	
	// find offsets
	g_iMoney = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_iFlashAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	g_inBuyzone = FindSendPropOffs("CCSPlayer","m_bInBuyZone");
	
	// register cvars
	cvar_price = CreateConVar("sunglasses_price","1100","Set Sunglasses price");
	cvar_message = CreateConVar("sunglasses_msg_mode","1","Set message mode display");
	cvar_mode = CreateConVar("sunglasses_mode","1","Set sunglasses mode");
	cvar_max = CreateConVar("sunglasses_max","4","Set how many times player won't be flashed in a round");
	
	// hook events
	HookEvent("player_blind",Event_Flashed);
	HookEvent("player_spawn",Event_spawn);
}


public Action:CMD_BUY_SUNGLASSES(id,args)
{
	decl String:SayText[191];
	GetCmdArgString(SayText, sizeof(SayText));
	
	remove_quotes(SayText);
	
	if(StrEqual(SayText,"sunglasses",false))
	{
		if(!IsPlayerAlive(id) )
		{
			PrintToChat(id,PLAYER_BE_ALIVE);
			return Plugin_Handled;
		}
		
		if(g_inBuyzone != 1)
		{
			if(GetEntData(id,g_inBuyzone) != 1)
			{
				PrintToChat(id,ONLY_BUYZONE);
				return Plugin_Handled;
			}
		}
	

		if(get_user_money(id) < GetConVarInt(cvar_price))
		{
			PrintToChat(id,NOT_ENOUGH_MONEY);
			return Plugin_Handled;
		}
	
		new sPrice = GetConVarInt(cvar_price);
		set_user_money(id,get_user_money(id) - sPrice);
		PrintToChat(id,SUCC_MSG);
	
		had_sunglasses[id] = true;
		g_used_count[id]++;
	}
	
	return Plugin_Continue;
		
}


public Action:Event_Flashed(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
    if (g_iFlashAlpha != -1)
    {
		if(had_sunglasses[client])
		{
			if(GetConVarInt(cvar_mode) == 2 && g_used_count[client] >= GetConVarInt(cvar_max) )
			{
				PrintToChat(client,NO_MORE_ACTIVE);
				return;
				
			}
			
			SetEntDataFloat(client,g_iFlashAlpha,ALPHA_SET);
			
			g_used_count[client]++;
		}
    }
}


public Action:Event_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(GetConVarInt(cvar_message) == 2)
		PrintToChatAll(AD_MESSAGE);
	
	had_sunglasses[client] = false;
	g_used_count[client] = 0;
}


public OnClientPutInServer()
{
	if(GetConVarInt(cvar_message) > 0)
		CreateTimer(15.0,DISPLAY_MSG);
}

public Action:DISPLAY_MSG(Handle:timer)
{
	PrintToChatAll(AD_MESSAGE);
}

	
public bool:OnClientConnect(client)
{
	had_sunglasses[client] = false;
	g_used_count[client] = 0;
}

public OnClientDisconnect(client)
{
	had_sunglasses[client] = false;
	g_used_count[client] = 0;
}



/**   Support functions 		**/
stock set_user_money(client, amount)
{
	if(g_iMoney != -1)
		SetEntData(client, g_iMoney, amount);
}

stock get_user_money(client)
{
	if(g_iMoney != -1)
		return GetEntData(client, g_iMoney);

	return 0;
}


stock remove_quotes(String:str[]) 
{
	new maxlen = strlen(str);
	new i;
	
	if(maxlen == 0)
		return;
		
	if(str[maxlen - 1] == QUOTE_CHAR) 
		str[--maxlen] = NULL_CHAR;
		
	if(str[0] == QUOTE_CHAR) 
	{
		for(i=0; i<=maxlen; i++)
			str[i] = str[i+1];
		
		str[i-2] = NULL_CHAR;
	}
}