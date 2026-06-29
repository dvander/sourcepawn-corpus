#include <sourcemod>
#include <tf2attributes>

#pragma newdecls		required
#pragma semicolon		1

EngineVersion EV;

bool TracersEnabled[MAXPLAYERS+1]=false;

public Plugin myinfo={
	name="[TF2] Toggle Tracers",
	author="91346706501435897134",
	description="Enables/Disables tracers.",
	version="1.1",
	url="http://steamcommunity.com/profiles/76561198356491749"
}

void CheckEngineVersion(){
	EV=GetEngineVersion();
	if(EV!=Engine_TF2){SetFailState("[TRACER_ROUNDS] : This plugin is for TF2 only.");}
}

public void OnPluginStart(){
	CheckEngineVersion();
	RegAdminCmd("sm_toggletracers",cmd_toggletracers,ADMFLAG_ROOT,"Toggles tracers");
}

bool ValidClient(int client){
	if(!client||!IsPlayerAlive(client)||!GetClientTeam(client)||IsClientSourceTV(client)||IsFakeClient(client)){return false;}
	else{return true;}
}

void ToggleTracerRounds(int client){
	if(!TracersEnabled[client]){
		TracersEnabled[client]=true;
		TF2Attrib_SetByName(client,"sniper fires tracer",1.0);
		ReplyToCommand(client,">> Tracers enabled.\n>> Please change class for changes to take effect.");
	}
	else{
		TracersEnabled[client]=false;
		TF2Attrib_RemoveByName(client,"sniper fires tracer");
		ReplyToCommand(client,">> Tracers disabled.\n>> Please change class for changes to take effect.");
	}
}

public Action cmd_toggletracers(int client, int args){
	if(ValidClient(client)){ToggleTracerRounds(client);}
	else{ReplyToCommand(client,">> You are not eligible to use this command.");}
	return Plugin_Handled;
}