#pragma semicolon 1
#include <sourcemod>
#include <colors>

#define CHAT_SYMBOL '#'
#define MP 34
#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Trade Chat",
	author = "Kemsan",
	description = "Trade Chat, spam.. the end!",
	version = PLUGIN_VERSION,
	url = "http://www.schoolskill.com.pl/"
};


new bool:UseTrade[MP]=false;
new bool:DontAsk[MP]=false;

new Handle:cvarAnnounceTime = INVALID_HANDLE;


public OnPluginStart()
{
	LoadTranslations("Trade");
	RegConsoleCmd("say", Command_SayChat);
	RegConsoleCmd("trade",  CallPanel, "Open on/off trade panel");

	cvarAnnounceTime = CreateConVar("trade_announce_time", "180", "Info about trade chat will show every X seconds", FCVAR_PLUGIN);

	
}

public OnClientAuthorized(client, const String:auth[])
{
	UseTrade[client]=true;
}

public OnMapStart()
{

		new Float:time = GetConVarFloat(cvarAnnounceTime);
		if (time > 0.0)
			CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Announce(Handle:hTimer)
{
		CPrintToChatAll("%t", "TradeAd1");
		CPrintToChatAll("%t", "TradeAd2");
		CPrintToChatAll("%t", "TradeAd3");
		CPrintToChatAll("%t", "TradeAd4");
		return Plugin_Continue;
}

public Action:Command_SayChat(client, args)
{	
	
	decl String:text[192];
	if (IsChatTrigger() || GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	new startidx;
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if (text[startidx] != '#')
		return Plugin_Continue;
	
	decl String:message[192];
	strcopy(message, 192, text[startidx+1]);

	SendChatTrade(client, message);
	LogAction(client, -1, "%L triggered trade chat (text # %s)", client, message);
	
	return Plugin_Handled;	
}


public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
		new client=GetClientOfUserId(GetEventInt(event, "userid"));
		if (!DontAsk[client])
			TradePanel(client);		
	return Plugin_Continue;
}

public Action:CallPanel(client, Args)
{

	TradePanel(client);

	return Plugin_Continue;
}

//Panel's procedure
public TradePanel(client)
{		
	new Handle:panel = CreatePanel();
	new String:str[256];
	Format(str,256,"%t","Trade1");
	//str="Choose whether you want to see trade chat";
	SetPanelTitle(panel, str);
	
	Format(str,256,"%t","Trade2");
	//str="Show trade chat";
	DrawPanelItem(panel, str);
	
	Format(str,256,"%t","Trade3");
	//str="Hide trade chat";
	DrawPanelItem(panel, str); 
	
	Format(str,256,"%t","Trade4");
	//str="Show, don't ask me again";
	DrawPanelItem(panel, str); 
	
	Format(str,256,"%t","Trade5");
	//str="Hide, don't ask me again";
	DrawPanelItem(panel, str); 
	
	SendPanelToClient(panel, client, TradePanelH, 20);
	CloseHandle(panel); 
	//return Plugin_Continue;	
}

//Panel's Handle Procedure
public TradePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				UseTrade[param1]=false;
				DontAsk[param1]=false;
			}
			case 2:
			{
				UseTrade[param1]=true;
				DontAsk[param1]=false;
			}
			case 3:
			{
				UseTrade[param1]=false;
				DontAsk[param1]=true;
			}
			case 4:
			{
				UseTrade[param1]=true;
				DontAsk[param1]=true;
			}
		}
	}
}


SendChatTrade(client, String:message[])
{
	new String:nameBuf[MAX_NAME_LENGTH];
	new String:color[30];
	GetClientName(client, nameBuf, sizeof(nameBuf));

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) && UseTrade[i] == false)
		{
			continue;
		}
		
		CPrintToChat(i, "{green}(TRADE) {olive}%s: {default}%s", nameBuf, message);
		
	}
}