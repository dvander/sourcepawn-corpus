#pragma newdecls required
#pragma semicolon 1
#pragma tabsize 0
#include <tf2>

public Plugin myinfo = {
	name = "TF2 All Crit",
	author = "blendmaster345",
	description = "Make every hit a crit",
	version = "1.0.2",
	url = "http://sourcemod.net/"
}

ConVar IsAllCritOn;

public void OnPluginStart() {
	IsAllCritOn = CreateConVar("tf_allcrits", "1", "Enable/Disable All Crits");
	AutoExecConfig(true, "tf_allcrits");
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result) {
	result = IsAllCritOn.BoolValue;
	return Plugin_Handled;  //Stop TF2 from doing anything about it
}