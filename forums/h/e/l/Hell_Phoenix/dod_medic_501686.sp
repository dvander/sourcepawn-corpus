/*
DoD Medic
Hell Phoenix
http://www.charliemaurice.com/plugins

This plugin is a basic medic plugin.  If someone is below the set health, they can type in !medic and receive some life back.


Versions:
	1.0
		* First Public Release!
 
Cvarlist (default value):
	dod_medic_health_maximum 30 <Maximum Health left to be able to use !medic>
	dod_medic_health_give 40 <Amount of health to give when !medic is used>

Admin Commands:
	None
	

*/


#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new Handle:cvarhealthmaximum;
new Handle:cvarhealthtogive;


public Plugin:myinfo = 
{
	name = "DoD Medic",
	author = "Hell Phoenix",
	description = "DoD Medic",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
};

public OnPluginStart(){
	CreateConVar("dod_medic_version", PLUGIN_VERSION, "DoD Medic Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarhealthmaximum = CreateConVar("dod_medic_health_maximum","30","Maximum Health left to be able to use !medic",FCVAR_PLUGIN);
	cvarhealthtogive = CreateConVar("dod_medic_health_give","40","Amount of health to give when !medic is used",FCVAR_PLUGIN);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

}

public Action:Command_Say(client,args){
	if(client != 0){
			
		decl String:speech[64];
		decl String:clientName[64];
		GetClientName(client,clientName,64);
		GetCmdArgString(speech,sizeof(speech));
		
		new startidx = 0;
		if (speech[0] == '"'){
			startidx = 1;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"'){
					speech[len-1] = '\0';
			}
		}
		
		if(strcmp(speech[startidx],"!medic",false) == 0){
			CreateTimer(0.1, Medic, client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:Medic(Handle:timer, any:client){
	new dead = GetPlayerState(client);
	new health = GetPlayerHealth(client);
	LogMessage("%s", health);
	if (dead != 512){
		PrintToChat(client, "[DoD Medic] Medics cant raise the dead you know!");
		return Plugin_Continue;
	}
	if (health <= GetConVarInt(cvarhealthmaximum)){
		ClientCommand(client, "voice_medic");
		new nhealth = (GetConVarInt(cvarhealthtogive) + health);
		SetEntProp(client, Prop_Send, "m_iHealth", nhealth, 1);
	}else{
		PrintToChat(client, "[DoD Medic] Thats merely a flesh wound!");
	}
			
	return Plugin_Handled;
}


public GetPlayerHealth(playerindex){
 return GetEntData(playerindex,GetHealthOffset(playerindex));
}
public GetHealthOffset(playerindex){
 return FindDataMapOffs(playerindex,"m_iHealth");
}

public GetPlayerState(playerindex){
 return GetEntData(playerindex,GetStateOffset(playerindex));
}
public GetStateOffset(playerindex){
 return FindDataMapOffs(playerindex,"m_lifeState");
}

