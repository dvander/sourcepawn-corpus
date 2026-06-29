#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Money Plugins",
	author = "Born To Kiil [Vision 3]",
	description = "Money plugins",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("bomb_planted", EventBombPlanted);
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new lMoney = GetEntProp(client, Prop_Send, "m_iAccount");
	new looserandommoney = GetRandomInt(1000, 5000);
	
	SetEntProp(client, Prop_Send, "m_iAccount", lMoney -looserandommoney);  
	
	PrintToChat(client, "[SM] You lose %d money for dying!", looserandommoney);
}

public Action:EventBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new rMoney = GetEntProp(client, Prop_Send, "m_iAccount");
	new moneyreward = GetRandomInt(1000, 5000);
	
	SetEntProp(client, Prop_Send, "m_iAccount", rMoney +moneyreward);
	
	PrintToChat(client, "[SM] You got %d money for planting the bomb!", moneyreward);
}