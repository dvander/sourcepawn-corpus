#pragma semicolon 1
#include <sdktools>
#define PLUGIN_NAME "Chicken Eater"
#define PLUGIN_VERSION "1.0.0"
public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = "Mitchell",
	description = "Eat chickens to gain HP",
	version = PLUGIN_VERSION,
	url = "mtch.tech"
}

ConVar cEnabled;
ConVar cHP;
ConVar cMaxHP;

public OnPluginStart() {
	CreateConVar("sm_chickeneater_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	cEnabled = CreateConVar("sm_chickeneater_enable", "1");
	cHP = CreateConVar("sm_chickeneater_enable", "15", "How much HP the player recieves after eating a chicken");
	cMaxHP = CreateConVar("sm_chickeneater_maxhp", "100", "Cap HP");
	AutoExecConfig();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float ang[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
	static int oldButtons[MAXPLAYERS+1];
	if(!cEnabled.BoolValue || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	if(buttons - oldButtons[client] > 0 && buttons & IN_USE) {
		int target = GetClientAimTarget(client, false);
		if(target > MaxClients && IsValidEntity(target)) {
			char className[32];
			GetEntityClassname(target, className, sizeof(className));
			if(StrEqual(className, "chicken")) {
				AcceptEntityInput(target, "Break");
				if(GetUserFlagBits(client) & ADMFLAG_CUSTOM2) //Check Vip Flag
					SetEntityHealth(client, clampInt(GetClientHealth(client) + cHP.IntValue, 0, cMaxHP.IntValue));
			}
		}
	}
	oldButtons[client] = buttons;
	return Plugin_Continue;
}

public int clampInt(int value, int min, int max) {
	return (value > max) ? max : (value < min) ? min : value;
}