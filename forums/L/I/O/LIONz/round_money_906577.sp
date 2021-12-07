#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.0.1"

new Handle:g_Cvar_RoundMoney = INVALID_HANDLE;
new Handle:g_Cvar_RoundMoneyEnabled = INVALID_HANDLE;
new Handle:g_Cvar_RoundMoneyReserved = INVALID_HANDLE;
new Handle:g_Cvar_RoundMoneyRoot = INVALID_HANDLE;
new Handle:g_Cvar_RoundMoneyNotify = INVALID_HANDLE;
new Handle:g_Cvar_RoundMoneyAdvert = INVALID_HANDLE;
new g_iAccount = -1;
new g_iMoney = 0;

public Plugin:myinfo =
{
	name = "Round Money",
	author = "LIONz",
	description = "Give Extra Money At Round End",
	version = "PLUGIN_VERSION",
	url = "http://gamerx.lv/"
};

public OnPluginStart()
{
	LoadTranslations("roundmoney.phrases");

	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	if (g_iAccount == -1)
	{
		PrintToServer("[SM] Unable to start round money, cannot find necessary send prop offsets.");
		return;
	}
	
	CreateConVar("sm_round_money_version", PLUGIN_VERSION, "Round Money Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_RoundMoneyEnabled = CreateConVar("sm_round_money_enabled", "1", "Enables and Disables plugin", _, true, 0.0, true, 1.0);
	g_Cvar_RoundMoneyReserved = CreateConVar("sm_round_money_reserved", "1", "Enables and Disables plugin for admin flag RESERVATION", _, true, 0.0, true, 1.0);
	g_Cvar_RoundMoneyRoot = CreateConVar("sm_round_money_root", "1", "Enables and Disables plugin for admin flag ROOT", _, true, 0.0, true, 1.0);
	g_Cvar_RoundMoneyNotify = CreateConVar("sm_round_money_notify", "1", "Enables and Disables plugin notices in chat", _, true, 0.0, true, 1.0);
	g_Cvar_RoundMoneyAdvert = CreateConVar("sm_round_money_advert", "1", "Enables and Disables plugin advertisment for non registered players in chat", _, true, 0.0, true, 1.0);
	g_Cvar_RoundMoney = CreateConVar("sm_round_money", "3000", "Amount of money to give should be a number between 0 and 16000", _, true, 0.0, true, 16000.0);
	
	HookEvent("round_end", Event_RoundEnd);
	
	AutoExecConfig(true, "roundmoney");
}

public GiveMoney(client)
{
	g_iMoney = GetEntData(client, g_iAccount);
	SetEntData(client, g_iAccount, g_iMoney + GetConVarInt(g_Cvar_RoundMoney));
	
	if(GetUserFlagBits(client) & (ADMFLAG_RESERVATION) && GetConVarBool(g_Cvar_RoundMoneyNotify))
	{
		PrintToChat(client,"\x01[\x04SM\x01] \x03%t", "TRANSLATION_NOTICE", GetConVarInt(g_Cvar_RoundMoney));
	}
	else if(GetUserFlagBits(client) & (ADMFLAG_ROOT) && GetConVarBool(g_Cvar_RoundMoneyNotify))
	{
		PrintToChat(client,"\x01[\x04SM\x01] \x03%t", "TRANSLATION_NOTICE", GetConVarInt(g_Cvar_RoundMoney));
	}
	else if(GetConVarBool(g_Cvar_RoundMoneyAdvert))
	{
		PrintToChat(client,"\x01[\x04SM\x01] \x03%t", "TRANSLATION_ADVERT", GetConVarInt(g_Cvar_RoundMoney));
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iMaxClients = GetMaxClients();
		
	for (new i = 1; i <= iMaxClients; i++)
	{	
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if(GetUserFlagBits(i) & (ADMFLAG_RESERVATION) && GetConVarBool(g_Cvar_RoundMoneyEnabled) && GetConVarBool(g_Cvar_RoundMoneyReserved))
		{
			if (IsClientInGame(i))
			GiveMoney(i);
		}
		else if(GetUserFlagBits(i) & (ADMFLAG_ROOT) && GetConVarBool(g_Cvar_RoundMoneyEnabled) && GetConVarBool(g_Cvar_RoundMoneyRoot))
		{
			if (IsClientInGame(i))
			GiveMoney(i);
		}
	}
}