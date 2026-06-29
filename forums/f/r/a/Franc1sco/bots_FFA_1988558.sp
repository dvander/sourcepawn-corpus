#pragma semicolon 1
#include <sourcemod>
#include <botattackcontrol>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Bots for FFA",
	author = "Franc1sco steam: franug",
	description = ".",
	version = PLUGIN_VERSION,
	url = "http://www.clanuea.com/"
};


public Action:OnShouldBotAttackPlayer(bot, player, &bool:result)
{
	if(result) return Plugin_Continue; // he will attack now
	
	result = true;
	return Plugin_Changed; // attack to everyone
}