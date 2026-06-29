#include <sourcemod>

public Plugin myinfo =
{
	name = "Bot kicker",
	author = "Ole",
	description = "dynamically kick and add bots as players join",
	version = "1.0",
	url = "https://steamcommunity.com/profiles/76561197998774290"
};
int realplayers;
int maxBots;
int defBotQuota;

public void OnConfigsExecuted(){
	ConVar botsConvar = FindConVar("bot_quota");
	defBotQuota = botsConvar.IntValue;
}


public void OnClientConnected(int client){
    if(IsFakeClient(client)){
       
        return;
    }
    ConVar botsConvar = FindConVar("bot_quota");
    realplayers++;
    maxBots = botsConvar.IntValue;
    if(realplayers <= defBotQuota){
   		botsConvar.IntValue = maxBots - 1;
   		PrintToChatAll("[SM] Kicking a bot to make place for a human...");
   	}
    
    
    
    
    
}

public void OnClientDisconnect(int client){
    if(IsFakeClient(client)){
        return;
    }
    realplayers--;
    if(realplayers < defBotQuota){
		ConVar botsConvar = FindConVar("bot_quota");
   		maxBots = botsConvar.IntValue;
   		botsConvar.IntValue = maxBots + 1;
   		PrintToChatAll("[SM] Replacing leaving player with a bot...")
}
    

    
    
    

}
