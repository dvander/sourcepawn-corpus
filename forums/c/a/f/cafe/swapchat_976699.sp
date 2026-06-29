/*
* [L4D] Chat Swapper (c) 2009 Jonah Hirsch
* 
* 
* Swaps specified player's team chat sending/receiving
* 
*  
* Changelog								
* ------------		
* 1.0									
*  - Initial Release			
* 
* 		
*/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0"

new flagged_users[MAXPLAYERS]

public Plugin:myinfo = 
{
	name = "Chat Swapper",
	author = "Crazydog",
	description = "Swaps chat sending/receiving of specified players",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}

public OnPluginStart(){
	RegConsoleCmd("say_team", Command_SayTeam);
}

public OnClientAuthorized(client, const String:auth[]){
	new String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, MAX_NAME_LENGTH);
	if(StrEqual(name, "TESTTEST")){
		flagged_users[client] = 1;
	}
}

public Action:Command_SayTeam(client, args){
	new String:text[192], String:name[MAX_NAME_LENGTH], team;
	GetClientName(client, name, MAX_NAME_LENGTH);
	team = GetClientTeam(client);
	GetCmdArgString(text, sizeof(text));
	
	new startidx = 0;
	if(text[0] == '"'){
		startidx = 1;
		new len = strlen(text);
		if(text[len-1] == '"'){
			text[len-1] = '\0';
		}
		
	}
		
	if(flagged_users[client] == 1){
		for (new i=1;i<=GetMaxClients();i++){
			if ((IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i)) && GetClientTeam(i) != team) && flagged_users[client] == 0 || i == client){
				if(team == 2){
					PrintToChat(i, "\x01(Survivor) \x08%s\x01 :  %s", name, text[startidx]);
				}
				if(team == 3){
					PrintToChat(i, "\x01(Infected) \x08%s\x01 :  %s", name, text[startidx]);
				}
			}
		}
	}else if(flagged_users[client] == 0){
		for (new i=1;i<=GetMaxClients();i++){
			if ((IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i)) && GetClientTeam(i) == team) && flagged_users[client] == 0 || i == client){
				if(team == 2){
					PrintToChat(i, "\x01(Survivor) \x08%s\x01 :  %s", name, text[startidx]);
				}
				if(team == 3){
					PrintToChat(i, "\x01(Infected) \x08%s\x01 :  %s", name, text[startidx]);
				}
			}
		}		
	}
	return Plugin_Handled
}
		
		