
#pragma semicolon 1

#include <sourcemod>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

public Plugin:myinfo = 
{
	name = "[TF2]F4P Reserved Slots",
	author = "ssinga",
	description = "kick free players if server is full",
	version = SOURCEMOD_VERSION,
	url = "http://web.ssinga.jp/"
};

public OnPluginStart(){
	LoadTranslations("anti-f2p.phrases");
}

public OnClientPutInServer(){
	if(GetClientCount(false) >= GetMaxClients()){
		SelectKickClient();
	}
}

SelectKickClient()
{
	for(new client = 1; client < MAXPLAYERS+1;client++){
		if( IsClientInGame( client ) && IsClientAuthorized(client) &&  !IsFakeClient( client )){
			if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459)){
				KickClient(client, "%t","text");
				return;
			}
		}
	}
}