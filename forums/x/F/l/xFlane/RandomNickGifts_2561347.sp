#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "xFlane"
#define PLUGIN_VERSION "1.00"

#define NICKNAME_PART "alliedmodders"

#define PREFIX "[SM]"

#include <sourcemod>
#include <sdktools>

#define CHANCE_TO_RECEIVE_MONEY 33
#define CHANCE_TO_WEAPON CHANCE_TO_RECEIVE_MONEY + 33
#define CHANCE_TO_KEVLAR CHANCE_TO_WEAPON + 33


int moneyGifts[] = 
{
	500,
	1500,
	2500,
	3500,
	4500,
	6500,
	7500,
	8500
};

char itemGifts[][] = 
{
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_awp",
	"weapon_deagle"
};

#pragma newdecls required

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "[SM] Nickname random gifts.",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/xflane/"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	HookEvent("player_spawn", Event_Spawn);
}

public Action Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	char clientName[32];
	GetClientName(client, clientName, 32);
	
	if(StrContains(clientName, NICKNAME_PART) > -1)
	{
		int num = GetRandomInt(0, 100);
		if(num <= CHANCE_TO_RECEIVE_MONEY)
		{
			int money = moneyGifts[GetRandomInt(0, sizeof(moneyGifts) - 1)];
			PrintToChat(client, "%s You have received \x04%i$\x01, because you have \x04%s\x01 in your name", PREFIX, money, NICKNAME_PART);
			money += GetEntProp(client, Prop_Send, "m_iAccount");
			SetEntProp(client, Prop_Send, "m_iAccount", money > 16000 ? 16000 : money);
		}
		else if(num <= CHANCE_TO_WEAPON)
		{
			char weapon[32];
			strcopy(weapon, 32, itemGifts[GetRandomInt(0, sizeof(itemGifts) - 1)]);
			GivePlayerItem(client, weapon);
			ReplaceString(weapon, 32, "weapon_", "");
			PrintToChat(client, "%s You have received \x04%s\x01, because you have \x04%s\x01 in your name.", PREFIX, weapon, NICKNAME_PART);
		}
		else if(num <= CHANCE_TO_KEVLAR)
		{
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
			PrintToChat(client, "%s You have received \x04kevlar\x01, because you have \x04%s\x01 in your name.", PREFIX, NICKNAME_PART);
		}
	
	}
}
