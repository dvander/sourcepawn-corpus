#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
public Plugin:myinfo = {
	name = "Scream Me",
	author = "The Count",
	description = "Obnoxious.",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

public OnPluginStart(){
	LoadTranslations("common.phrases");
	
	PrecacheSound("vo/spy_sf12_falling01.wav");
	PrecacheSound("vo/spy_sf12_falling02.wav");
	PrecacheSound("vo/scout_sf12_falling01.wav");
	PrecacheSound("vo/scout_sf12_falling02.wav");
	PrecacheSound("vo/scout_sf12_falling03.wav");
	PrecacheSound("vo/soldier_sf12_falling01.wav");
	PrecacheSound("vo/soldier_sf12_falling02.wav");
	PrecacheSound("vo/demoman_sf12_falling01.wav");
	PrecacheSound("vo/heavy_scram2012_falling01.wav");
	PrecacheSound("vo/medic_sf12_falling01.wav");
	PrecacheSound("vo/pyro_paincrticialdeath01.wav");
	PrecacheSound("vo/pyro_paincrticialdeath02.wav");
	PrecacheSound("vo/pyro_paincrticialdeath03.wav");
	PrecacheSound("vo/engineer_paincrticialdeath01.wav");
	PrecacheSound("vo/engineer_paincrticialdeath02.wav");
	PrecacheSound("vo/engineer_paincrticialdeath03.wav");
	PrecacheSound("vo/engineer_paincrticialdeath04.wav");
	PrecacheSound("vo/engineer_paincrticialdeath05.wav");
	PrecacheSound("vo/engineer_paincrticialdeath06.wav");
	PrecacheSound("vo/sniper_paincrticialdeath01.wav");
	PrecacheSound("vo/sniper_paincrticialdeath02.wav");
	PrecacheSound("vo/sniper_paincrticialdeath03.wav");
	PrecacheSound("vo/sniper_paincrticialdeath04.wav");
	
	RegConsoleCmd("sm_screamme", Cmd_ScreamMe, "Scream.");
	RegAdminCmd("sm_scream", Cmd_Scream, ADMFLAG_SLAY, "Scream.");
}

stock FindScream(TFClassType:class, String:path2[], maxlength){
	new String:path[200];
	switch(class){
		case TFClass_Spy:{
			Format(path, sizeof(path), "vo/spy_sf12_falling0%d.wav", GetRandomInt(1,2));
		}
		case TFClass_Scout:{
			Format(path, sizeof(path), "vo/scout_sf12_falling0%d.wav", GetRandomInt(1,3));
		}
		case TFClass_Soldier:{
			Format(path, sizeof(path), "vo/soldier_sf12_falling0%d.wav", GetRandomInt(1,2));
		}
		case TFClass_DemoMan:{
			Format(path, sizeof(path), "vo/demoman_sf12_falling01.wav");
		}
		case TFClass_Heavy:{
			Format(path, sizeof(path), "vo/heavy_scram2012_falling01.wav");
		}
		case TFClass_Medic:{
			Format(path, sizeof(path), "vo/medic_sf12_falling01.wav");
		}
		case TFClass_Pyro:{
			Format(path, sizeof(path), "vo/pyro_paincrticialdeath0%d.wav", GetRandomInt(1,3));
		}
		case TFClass_Engineer:{
			Format(path, sizeof(path), "vo/engineer_paincrticialdeath0%d.wav", GetRandomInt(1,6));
		}
		case TFClass_Sniper:{
			Format(path, sizeof(path), "vo/sniper_paincrticialdeath0%d.wav", GetRandomInt(1,4));
		}
		default:{
			PrintToServer("[SM] This class is unable to scream.");
		}
	}
	strcopy(path2, maxlength, path);
}

public Action:Cmd_Scream(client, args){
	if(args > 1){
		PrintToChat(client, "[SM] Usage: !scream [CLIENT]");
		return Plugin_Handled;
	}
	new targ = -1;
	if(args == 0){
		targ = client;
	}else{
		new String:arg1[MAX_NAME_LENGTH];
		GetCmdArg(1, arg1, sizeof(arg1));
		targ = FindTarget(client, arg1, false, false);
	}
	if(targ == -1){
		return Plugin_Handled;
	}
	if(!IsPlayerAlive(targ)){
		PrintToChat(client, "[SM] Target is not alive.");
		return Plugin_Handled;
	}
	new TFClassType:class = TF2_GetPlayerClass(targ), String:path[200];
	FindScream(class, path, sizeof(path));
	EmitSoundToAll(path, targ, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	PrintToChat(client, "\x01[SM]\x04 Sound played.");
	return Plugin_Handled;
}

public Action:Cmd_ScreamMe(client, args){
	if(!IsPlayerAlive(client)){
		PrintToChat(client, "[SM] Must be alive to use this command.");
		return Plugin_Handled;
	}
	new TFClassType:class = TF2_GetPlayerClass(client), String:path[200];
	FindScream(class, path, sizeof(path));
	EmitSoundToAll(path, client, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	return Plugin_Handled;
}