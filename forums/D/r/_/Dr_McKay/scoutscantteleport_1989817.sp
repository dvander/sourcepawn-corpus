#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = {
	name		= "[TF2] Scouts Can't Teleport",
	author		= "Dr. McKay",
	description	= "Prevents scouts from taking teleporters",
	version		= "1.0.0",
	url			= "http://www.doctormckay.com"
};

public Action:TF2_OnPlayerTeleport(client, teleporter, &bool:result) {
	if(TF2_GetPlayerClass(client) == TFClass_Scout) {
		result = false;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}