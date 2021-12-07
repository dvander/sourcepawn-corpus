//Includes
#include <sourcemod>
#include <multicolors>
 
//Definitions 
#define PLUGIN_VERSION 	"1.0"
 
public Plugin:myinfo =
{
	name = "Coinflip",
	author = "KennY",
	description = "Makes a coinflip 50/50",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/kennysweden/"
}

public OnPluginStart()
{
    RegConsoleCmd("sm_coinflip", OnFlip, "Flip the coin");
	LoadTranslations("Coinflip.phrases")
}

public Action:OnFlip(int client, int args)
{
  	switch(GetRandomInt(1, 2)) 
    { 
        case 1: 
        { 
            CPrintToChatAll("%t %t", "MSG_PREFIX", "Terrorist"); 
        } 
        case 2: 
        { 
            CPrintToChatAll("%t %t", "MSG_PREFIX", "Counter Terrorist");
        } 
    } 		
	return Plugin_Handled;
}

