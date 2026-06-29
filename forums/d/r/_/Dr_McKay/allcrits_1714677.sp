#pragma semicolon 1

#include <sourcemod>
#include <tf2>

public Plugin:myinfo = {
	name        = "[TF2] All Crits",
	author      = "Dr. McKay",
	description = "Every shot is a crit",
	version     = "1.0.0",
	url         = "http://www.doctormckay.com"
};

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) {
    result = true;
	return Plugin_Handled;
}