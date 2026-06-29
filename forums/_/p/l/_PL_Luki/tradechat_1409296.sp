#include <sourcemod>
#include <clientprefs>
#include <colors>

#define PLUGIN_VERSION "1.3 - not tested"

public Plugin:myinfo = 
{
	name = "Trade Chat",
	author = "Luki",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://luki.net.pl"
};

new Handle:hCookie = INVALID_HANDLE;
new Handle:hAdTimerInterval = INVALID_HANDLE;
new Handle:hAntiSpamDelay = INVALID_HANDLE;
new Handle:hAntiSpamMaxCount = INVALID_HANDLE;
new Handle:hChatCheck = INVALID_HANDLE;
new Handle:hChatTrigger1 = INVALID_HANDLE;
new Handle:hChatTrigger2 = INVALID_HANDLE;
new Handle:hChatTrigger3 = INVALID_HANDLE;

new HideTradeChat[MAXPLAYERS + 1];
new TradeChatGag[MAXPLAYERS + 1];
new LastMessageTime[MAXPLAYERS + 1];
new SpamCount[MAXPLAYERS + 1];
new String:logfile[255];
new iAntiSpamDelay = 0;
new iAntiSpamMaxCount = 0;
new String:sChatTrigger1[32] = "trade";
new String:sChatTrigger2[32] = "sell";
new String:sChatTrigger3[32] = "buy";

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("tradechat.phrases");

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("sm_t", Command_TradeChat);
	RegConsoleCmd("sm_trade", Command_TradeChat);
	RegConsoleCmd("sm_hidechat", Command_HideChat);
	
	RegAdminCmd("sm_trade_gag", Command_TradeGag, ADMFLAG_CHAT);
	RegAdminCmd("sm_trade_ungag", Command_TradeUnGag, ADMFLAG_CHAT);
	
	CreateConVar("sm_trade_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hAdTimerInterval = CreateConVar("sm_trade_adinterval" , "180", "Interval between displaying the advert (0 = disable)", FCVAR_PLUGIN|FCVAR_REPLICATED, true, 0.0);
	hAntiSpamDelay = CreateConVar("sm_trade_antispam_delay", "5", "Minimum delay between messages from one client (0 = disable)", FCVAR_PLUGIN|FCVAR_REPLICATED, true, 0.0, true, 60.0);
	hAntiSpamMaxCount = CreateConVar("sm_trade_antispam_max", "5", "Maximum number of messages, that player can send during block time before autogag (0 = disable)", FCVAR_PLUGIN|FCVAR_REPLICATED, true, 0.0, true, 15.0);
	hChatCheck = CreateConVar("sm_trade_chatcheck", "0", "", FCVAR_PLUGIN|FCVAR_REPLICATED, true, 0.0, true, 3.0);
	
	hChatTrigger1 = CreateConVar("sm_trade_chattrigger1", "trade", "", FCVAR_PLUGIN|FCVAR_REPLICATED);
	hChatTrigger2 = CreateConVar("sm_trade_chattrigger2", "sell", "", FCVAR_PLUGIN|FCVAR_REPLICATED);
	hChatTrigger3 = CreateConVar("sm_trade_chattrigger3", "buy", "", FCVAR_PLUGIN|FCVAR_REPLICATED);
	
	if (hAntiSpamDelay != INVALID_HANDLE)
		HookConVarChange(hAntiSpamDelay, OnAntiSpamDelayChange);
		
	if (hAntiSpamMaxCount != INVALID_HANDLE)
		HookConVarChange(hAntiSpamMaxCount, OnAntiSpamMaxCountChange);
	
	if (hChatTrigger1 != INVALID_HANDLE)
		HookConVarChange(hChatTrigger1, OnChatTriggersChange);
	if (hChatTrigger2 != INVALID_HANDLE)
		HookConVarChange(hChatTrigger2, OnChatTriggersChange);
	if (hChatTrigger3 != INVALID_HANDLE)
		HookConVarChange(hChatTrigger3, OnChatTriggersChange);
	
	BuildPath(Path_SM, logfile, sizeof(logfile), "logs/tradechat.log");
	
	AutoExecConfig(true);
}

public OnConfigsExecuted()
{
	if (GetConVarFloat(hAdTimerInterval) != 0.0)
		CreateTimer(GetConVarFloat(hAdTimerInterval), AdTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	iAntiSpamDelay = GetConVarInt(hAntiSpamDelay);
	iAntiSpamMaxCount = GetConVarInt(hAntiSpamMaxCount);
}

public OnAllPluginsLoaded()
{
	new Handle:Plugin_ClientPrefs = FindPluginByFile("clientprefs.smx");
	new PluginStatus:Plugin_ClientPrefs_Status = GetPluginStatus(Plugin_ClientPrefs);
	if ((Plugin_ClientPrefs == INVALID_HANDLE) || (Plugin_ClientPrefs_Status != Plugin_Running))
		LogError("This plugin require clientprefs plugin to allow users to disable trade chat.");
	else
		hCookie = RegClientCookie("tradechat", "Hide trade chat", CookieAccess_Protected);
}

public OnClientPostAdminCheck(client)
{
	TradeChatGag[client] = 0;
	LastMessageTime[client] = 0;
	SpamCount[client] = 0;
	if (hCookie != INVALID_HANDLE)
	{
		new String:cookie[4];
		if (AreClientCookiesCached(client))
		{
			GetClientCookie(client, hCookie, cookie, sizeof(cookie));
			if (StrEqual(cookie, "on"))
			{
				HideTradeChat[client] = 1;
				return;
			}
			if (StrEqual(cookie, "off"))
			{
				HideTradeChat[client] = 0;
				return;
			}
		}
		SetClientCookie(client, hCookie, "off");
		HideTradeChat[client] = 0;
	}
	else
	{
		HideTradeChat[client] = 0;
	}
}

public Action:Command_Say(client, args)
{
	new checkTriggers = GetConVarInt(hChatCheck);
	if (checkTriggers < 1)
		return Plugin_Continue;
	
	new String:text[512];
	GetCmdArgString(text, sizeof(text));
	
	if ((strcmp(text, sChatTrigger1, false) == 0) ||
		((checkTriggers >= 2) && (strcmp(text, sChatTrigger2, false) == 0)) || 
		((checkTriggers >= 3) && (strcmp(text, sChatTrigger3, false) == 0)))
	{
		DoTradeChat(client, text);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:Command_TradeChat(client, args)
{
	new String:text[512];
	GetCmdArgString(text, sizeof(text));
	
	DoTradeChat(client, text);
	
	return Plugin_Handled;
}

public DoTradeChat(client, String:msg[])
{
	TrimString(msg);
	if (strlen(msg) == 0)
		return;
	
	if (HideTradeChat[client])
	{
		CPrintToChat(client, "%t", "TradeDisabledForYou");
		return;
	}
	
	if (TradeChatGag[client])
	{
		CPrintToChat(client, "%t", "TradeBanned");
		return;
	}
	
	new String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	if (((GetTime() - LastMessageTime[client]) <= iAntiSpamDelay) && (iAntiSpamDelay != 0))
	{
		SpamCount[client]++;
		if ((SpamCount[client] > iAntiSpamMaxCount) && (iAntiSpamMaxCount != 0))
		{
			TradeChatGag[client] = 1;
			LogToFile(logfile, "%L was automatically banned from trade chat", client);
			CPrintToChatAll("%t", "AntiSpamAutoGag", name);
			return;
		}
		LastMessageTime[client] = GetTime();
		LogToFile(logfile, "%L was blocked from sending offer", client);
		CPrintToChat(client, "%t", "AntiSpamBlocked");
		return;
	}
	
	SpamCount[client] = 0;
	LastMessageTime[client] = GetTime();
	
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			if (!HideTradeChat[i])
				CPrintToChat(i, "{green}[Trade Chat] {lightgreen}%s: {default}%s", name, msg);
	
	LogToFile(logfile, "%L say \"%s\"", client, msg);
}

public Action:Command_TradeGag(client, args)
{
	new String:sTarget[MAX_NAME_LENGTH];

	if (!GetCmdArg(1, sTarget, sizeof(sTarget)))
	{
		ReplyToCommand(client, "%t", "TradeGagUsage");
		return Plugin_Handled;
	}
	
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml, String:target_name[MAX_TARGET_LENGTH];
	
	if ((target_count = ProcessTargetString(
			sTarget,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		new String:name[MAX_NAME_LENGTH], String:clientSID[32], String:targetSID[32];
		GetClientName(target_list[i], sTarget, sizeof(sTarget));
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, clientSID, sizeof(clientSID));
		GetClientAuthString(target_list[i], targetSID, sizeof(targetSID));
		TradeChatGag[target_list[i]] = 1;

		CPrintToChatAll("%t", "TradeBan", name, sTarget);
		LogToFile(logfile, "%L has disabled trade chat for %L", client, target_list[i]);
	}
	
	return Plugin_Handled;
}

public Action:Command_TradeUnGag(client, args)
{
	new String:sTarget[MAX_NAME_LENGTH];

	if (!GetCmdArg(1, sTarget, sizeof(sTarget)))
	{
		ReplyToCommand(client, "%t", "TradeGagUsage");
		return Plugin_Handled;
	}
	
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml, String:target_name[MAX_TARGET_LENGTH];
	
	if ((target_count = ProcessTargetString(
			sTarget,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED || COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		new String:name[MAX_NAME_LENGTH], String:clientSID[32], String:targetSID[32];
		GetClientName(target_list[i], sTarget, sizeof(sTarget));
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, clientSID, sizeof(clientSID));
		GetClientAuthString(target_list[i], targetSID, sizeof(targetSID));
		TradeChatGag[target_list[i]] = 0;
		LastMessageTime[target_list[i]] = 0;
		SpamCount[target_list[i]] = 0;

		CPrintToChatAll("%t", "TradeUnBan", name, sTarget);
		LogToFile(logfile, "%L has enabled trade chat for %L", client, target_list[i]);
	}
	
	return Plugin_Handled;
}

public Action:Command_HideChat(client, args)
{
	if (hCookie != INVALID_HANDLE)
	{
		new String:name[MAX_NAME_LENGTH], String:steamID[32];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, steamID, sizeof(steamID));
		if (!HideTradeChat[client])
		{
			SetClientCookie(client, hCookie, "on");
			HideTradeChat[client] = 1;
			CPrintToChat(client, "%t", "HideChatOn");
			LogToFile(logfile, "%L has disabled trade chat.", client);
		}
		else
		{
			SetClientCookie(client, hCookie, "off");
			HideTradeChat[client] = 0;
			CPrintToChat(client, "%t", "HideChatOff");
			LogToFile(logfile, "%L has enabled trade chat.", client);
		}
	}
	
	return Plugin_Handled;
}

public Action:AdTimer(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			if (!HideTradeChat[i])
			{
				CPrintToChat(i, "%t", "Advert1");
				CPrintToChat(i, "%t", "Advert2");
			}
	}
	return Plugin_Continue;
}

public OnAntiSpamDelayChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	iAntiSpamDelay = StringToInt(newVal);
}

public OnAntiSpamMaxCountChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	iAntiSpamMaxCount = StringToInt(newVal);
}

public OnChatTriggersChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(hChatTrigger1, sChatTrigger1, sizeof(sChatTrigger1));
	GetConVarString(hChatTrigger2, sChatTrigger2, sizeof(sChatTrigger2));
	GetConVarString(hChatTrigger3, sChatTrigger3, sizeof(sChatTrigger3));
}