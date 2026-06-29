#include <sourcemod> 
#include <superheromod>

#define PLUGIN_AUTHOR "Methan (moilc)"
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "mSpawn",
	author = PLUGIN_AUTHOR,
	description = "I'm trying some... things.. u know?",
	version = PLUGIN_VERSION
};

public void OnClientPutInServer(client){
	new String:name[32], String:auth[32];
	new AuthIdType:authType;
	
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, authType, auth, sizeof(auth));
	
	PrintToChatAll("\x04%s\x01 (\x05%s\x01) joins the game..", name, auth);
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn){
	ClientCommand(client, "sm_heromenu");
}