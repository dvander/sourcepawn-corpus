//Includes
#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <warden>
 
//Definitions 
#define PLUGIN_VERSION 	"1.0"

new bool:CanUseCommand = true;
 
public Plugin:myinfo =
{
	name = "Warden Coinflip",
	author = "KennY",
	description = "Makes a coinflip 50/50",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/kennysweden/"
}

public OnPluginStart()
{
    RegConsoleCmd("sm_coinflip", OnFlip, "Flip the coin");
	LoadTranslations("warden-coinflip.phrases")
}

public Action:OnFlip(client, args)
{
    if (warden_iswarden(client) == CanUseCommand)
	
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
    else  
    {
        CPrintToChat(client, "%t %t", "MSG_PREFIX", "Only Warden");  
    }	
	return Plugin_Handled;
}

