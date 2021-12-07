#include <sourcemod>

#pragma semicolon 1

new Handle:BuyFragEnabled;
new Handle:FragLimit;
new Handle:FragCost;

new MoneyOff;


new FragCount[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Buy a Frag",
	author = "Fredd",
	description = "Lets clients buy frags",
	version = "1.0",
	url = "www.sourcemod.net"
}
public OnPluginStart()
{
	CreateConVar("buyfrag_version", "1.0", "Buy Frag Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	BuyFragEnabled 	= CreateConVar("buyfrag_enabled", "1", "Enables/Disables client to buy frags");
	FragLimit		= CreateConVar("buyfrag_limit", "3", "How many times are client allowed to buy frags");
	FragCost		= CreateConVar("buyfrag_cost", "3000", "Sets the cost of a frag");
	
	MoneyOff 		= FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	HookEvent("player_spawn", PlayerSpawn);
	RegConsoleCmd("say", SayHook);
	RegConsoleCmd("say_team", SayHook);
	
	CreateTimer(60.0, PrintNotice, _, TIMER_REPEAT);
}public Action:SayHook(client, args)
{
	if(GetConVarInt(BuyFragEnabled) == 1)
	{
		new String:text[192];
		GetCmdArgString(text, sizeof(text));
			
		new startidx = 0;
		if (text[0] == '"')
		{
			startidx = 1;
			
			new len = strlen(text);
			if (text[len-1] == '"')
			{
				text[len-1] = '\0';
			}
		}
			
		if(StrEqual(text[startidx], "/buyfrag") || StrEqual(text[startidx], "buyfrag"))
		{
			if(FragCount[client] == GetConVarInt(FragLimit))
			{
				PrintToChat(client,"\x04[BuyFrag] \x01You have exceeded the buy frag limit per round");
				
				return Plugin_Continue;
			}
			else if(GetEntData(client, MoneyOff) < GetConVarInt(FragCost))
			{
				PrintToChat(client, "\x04[BuyFrag] \x01Not enough money, you need $%i", GetConVarInt(FragCost));	
				
				return Plugin_Continue;
			} else
			{
				new Score = GetClientFrags(client)+1;
				
				SetEntProp(client, Prop_Data, "m_iFrags", Score);
				SetEntData(client, MoneyOff, (GetEntData(client, MoneyOff)-(GetConVarInt(FragCost))));
				
				FragCount[client]++;
				
				return Plugin_Continue;
			}	
		}
	}
	return Plugin_Continue;
}
public Action:PrintNotice(Handle:timer) 
{ 
	if(GetConVarInt(BuyFragEnabled) == 1) 
		PrintToChatAll("\x04[BuyFrag] \x01Buying Frags is enabled type \x04/buyfrag \x01or \x04buyfrag \x01 to buy a frag"); 
	return Plugin_Continue;
}
public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) { new client = GetClientOfUserId(GetEventInt(event, "userid")); FragCount[client] = 0; }
public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {FragCount[client] = 0; return true;}
public OnClientDisconnect(client) FragCount[client] = 0;



