#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colorvariables>
#include <cstrike>
#include <warningshot>

#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.1"

ConVar cvDamage;
ConVar cvColored;
ConVar cvVersion;
ConVar cvRed;
ConVar cvGreen;
ConVar cvBlue;

char prefix[] = "[{blue}WarningShot{default}]";

Handle gF_OnWarningShotGiven = null;

public Plugin myinfo = {
	name = "Warning Shots",
	author = "Hypr",
	description = "Gives CT ability to give warning shots to T.",
	version = VERSION,
	url = "http://trinityplay.net"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("GiveClientWarningShot", Native_GiveClientWarningShot);
}

public void OnPluginStart() {
	
	SetGlobalTransTarget(LANG_SERVER);
	LoadTranslations("warningshot.phrases.txt");
	
	AutoExecConfig(true, "warningshot");
	cvColored = CreateConVar("sm_warning_colored", "4", "How long should the victim of the warning shot be colored red?\nSet to 0 to disable entirerly!", FCVAR_NOTIFY);
	cvDamage = CreateConVar("sm_warning_damage", "15", "How much damage is a warning shot supposed to give?", FCVAR_NOTIFY, true, 1.0, true, 30.0);
	cvVersion = CreateConVar("sm_warning_version", VERSION, "The plugin version.\nNot to be fiddled with..", FCVAR_DONTRECORD);
	
	cvRed = CreateConVar("sm_warning_color_R", "255", "The RED value of the color the warned T should get.", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	cvGreen = CreateConVar("sm_warning_color_G", "114", "The GREEN value of the color the warned T should get.", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	cvBlue = CreateConVar("sm_warning_color_B", "0", "The BLUE value of the color the warned T should get.", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i))
			continue;
		SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
	
	gF_OnWarningShotGiven = CreateGlobalForward("OnWarningShotGiven", ET_Ignore, Param_Cell, Param_Cell);
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	// Victim = The damaged entity
	// Inflictor = The attacking entity
	
	if(IsClientInGame(inflictor) && GetClientTeam(inflictor) == CS_TEAM_CT && GetClientTeam(victim) == CS_TEAM_T && IsPlayerAlive(victim) && IsPlayerAlive(inflictor)) {
		if(GetClientButtons(inflictor) & IN_USE) {
			if(GetClientHealth(victim) <= GetConVarInt(cvDamage)) {
				CPrintToChatAll("%s {red}The targeted player's hp is less than the warning's damage.", prefix);
				return Plugin_Handled;
			}
			GiveClientWarningShot(victim, inflictor);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action ColorTimer(Handle timer, int client) {
	SetEntityRenderColor(client);
	return Plugin_Stop;
}

/*
* Natives
*/
public int Native_GiveClientWarningShot(Handle plugin, int numParams) {
	int victim = GetNativeCell(1);
	int inflictor = GetNativeCell(2);
	int damage = (GetClientHealth(victim) - cvDamage.IntValue);
	if(IsPlayerAlive(victim)) {
		if(cvColored.IntValue > 0) {
			SetEntityRenderColor(victim, cvRed.IntValue, cvGreen.IntValue, cvBlue.IntValue);
			CreateTimer(cvColored.FloatValue, ColorTimer, victim);
		}
		SetEntityHealth(victim, damage);
		CPrintToChatAll("%s {red}%t", prefix, "Warning Shot", inflictor, victim);
		PrintHintText(victim, "<font color='#d2e845'>%t</font>", "Warning Shot Hint", inflictor);
		
		Call_StartForward(gF_OnWarningShotGiven);
		Call_PushCell(victim);
		Call_PushCell(inflictor);
		Call_Finish();
		
		return true;
	}
	
	return false; 
}
