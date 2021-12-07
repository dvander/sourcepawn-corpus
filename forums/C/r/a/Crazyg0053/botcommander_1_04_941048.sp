#include <sourcemod>
#include <sdktools_functions>
#include <cstrike>

#pragma semicolon 1
 
#define PLUGIN_VERSION "1.04"
 
public Plugin:myinfo = {
    name = "BotCommander",
    author = "CrazyG0053",
    description = "Maintains Server Bots",
    version = PLUGIN_VERSION,
    url = "http://www.soucemod.net"
};

new botCount =0;
new playerCount =0;

public OnPluginStart(){
	RegAdminCmd("sm_botadd", Command_BotAdd, ADMFLAG_CUSTOM3, "adds a server bot");
	RegAdminCmd("sm_botkick", Command_BotKick, ADMFLAG_CUSTOM3, "removes all server bots");
	HookEvent("round_start", RoundStart);
}

public OnMapStart()
{
	//Resets Variables
	ServerCommand("bot_kick");
	ServerCommand("bot_add");
	ServerCommand("bot_add");
	botCount = 2;
	playerCount = 0;
}
public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Calculates the number of Players currently on T or CT
	playerCount=(GetTeamClientCount(2)+GetTeamClientCount(3)-botCount);

	//Performs Bot Balancing Action Based on playerCount and botCount
	if(botCount==0){
		if(playerCount==0){
			ServerCommand("bot_add");
			ServerCommand("bot_add");
			botCount = 2;
		}
		if(playerCount==1){
			ServerCommand("bot_add");
			botCount = 1;
		}
		//
		//Settings are correct if playerCount >1	
		//
	}
	if(botCount==1){
		if(playerCount==0){
			ServerCommand("bot_add");
			botCount = 2;	
		}
		//
		//Settings are correct if playerCount == 1
		//
		if(playerCount>1){
			ServerCommand("bot_kick");
			botCount = 0;
		}
	}	
	if(botCount==2){
		//
		//Settings are correct if playerCount ==0
		//
		if(playerCount==1){
			ServerCommand("bot_kick");
			ServerCommand("bot_add");
			botCount = 1;
		}
		if(playerCount>1){
			ServerCommand("bot_kick");
			botCount = 0;
		}
	}
	//
	//If botCount > 3 Balancing is disabled due to Bot Play being desired.
	//
}
public Action:Command_BotAdd(client, args){
	ServerCommand("bot_add");
	botCount++;
	return Plugin_Handled;
}
public Action:Command_BotKick(client, args){
	ServerCommand("bot_kick");
	botCount=0;

	if(playerCount==0){
		ServerCommand("bot_add");
		ServerCommand("bot_add");
		botCount = 2;	
	}
	if(playerCount==1){
		ServerCommand("bot_add");
		botCount = 1;	
	}
	//
	//Settings are correct if playerCount >1
	//
	return Plugin_Handled;
}