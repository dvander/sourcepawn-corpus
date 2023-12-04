#pragma semicolon 1
#define DEBUG
#define PLUGIN_AUTHOR "pr0mers"
#define PLUGIN_VERSION "1.00"
#include <sourcemod>
#include <sdktools>
#include <cstrike>
int list[MAXPLAYERS + 1];
public OnPluginStart()
{
	RegAdminCmd("sm_disguiseme",hideme,ADMFLAG_GENERIC);
	RegAdminCmd("sm_disguisedebug",hidemedebug,ADMFLAG_ROOT);
	HookEvent("player_disconnect", cikti,EventHookMode_PostNoCopy);
	AddCommandListener(msj, "say");
	AddCommandListener(tkmmsj, "say_team");
}
public Action hideme(int client,int args){
	if(args != 1){
		ReplyToCommand(client,"Usage: sm_disguiseme <1|0> 1 = on , 0 = off");
		return ;
	}
	char text[128];
	GetCmdArg(1, text, sizeof(text));
	//PrintToChatAll("%s", text);
	if(StrEqual(text,"0") == false && StrEqual(text,"1") == false){
		ReplyToCommand(client,"Usage: sm_disguiseme <1|0> 1 = on , 0 = off");
		return ;
	}
	list[client] = StringToInt(text);
}
public Action hidemedebug(int client,int args){
	for(int i = 1; i <= GetMaxClients(); i++){
		PrintToConsole(client,"Player: %N isdiguisted: %d",i,list[i]);
	}
}
public Action msj(client, const String:command[], args)
{
	if(list[client]==1){
		char text[4096];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		if(StrEqual(text,"")){
		   return Plugin_Continue;
		}
		if(IsPlayerAlive(client)==true){
			
		  	int takm = GetClientTeam(client);
		  	if(takm == CS_TEAM_CT){
		  		PrintToChatAll(" \x0A%N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}
		  	else if(takm == CS_TEAM_T){
		  		PrintToChatAll(" \x09%N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}
		  	else if(takm == CS_TEAM_SPECTATOR){
		  		PrintToChatAll(" \x01*SPEC* \x03%N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}	
	  	}
	  	else{
	  		int takm = GetClientTeam(client);
		  	if(takm == CS_TEAM_CT){
		  		PrintToChatAll(" \x0A*DEAD* %N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}
		  	else if(takm == CS_TEAM_T){
		  		PrintToChatAll(" \x09*DEAD* %N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}
		  	else if(takm == CS_TEAM_SPECTATOR){
		  		PrintToChatAll(" \x01*SPEC* \x03%N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}
	  	}
	}
}
public Action tkmmsj(client, const String:command[], args)
{
	if(list[client]==1){
		char text[4096];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		if(StrEqual(text,"")){
		   return Plugin_Continue;
		}
		if(IsPlayerAlive(client)==true){
			
		  	int takm = GetClientTeam(client);
		  	if(takm == CS_TEAM_CT){
		  		PrintToChatAll(" \x0A(Counter-Terrorist) %N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}
		  	else if(takm == CS_TEAM_T){
		  		PrintToChatAll(" \x09(Terrorist) %N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}
		  	else if(takm == CS_TEAM_SPECTATOR){
		  		PrintToChatAll(" \x01(Spectator) \x03%N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}	
	  	}
	  	else{
	  		int takm = GetClientTeam(client);
		  	if(takm == CS_TEAM_CT){
		  		PrintToChatAll(" \x0A*DEAD*(Terrorist) %N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}
		  	else if(takm == CS_TEAM_T){
		  		PrintToChatAll(" \x09*DEAD*(Counter-Terrorist) %N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}
		  	else if(takm == CS_TEAM_SPECTATOR){
		  		PrintToChatAll(" \x01(Spectator) \x03%N : \x01%s", client, text);
		  		return Plugin_Handled;
		  	}	
	  	}
	}
}
public Action cikti(Handle:event, const String:name[], bool:dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	list[client] = 0;
}