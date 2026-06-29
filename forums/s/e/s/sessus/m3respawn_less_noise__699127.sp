#pragma semicolon 1
#include <sourcemod>
#include <cstrike>

public Plugin:myinfo = {
	name = "M3Respawn - Respawn a dead player",
	author = "M3Studios, Inc.",
	description = "Let's admins respawn any dead player.",
	version = "0.1.0",
	url = "http://www.m3studiosinc.com/"
}

public OnPluginStart() {
	RegAdminCmd("sm_respawn", CmdRespawn, ADMFLAG_KICK, "sm_respawn <#userid|name>");
}

public Action:CmdRespawn(client, args) {
	if (args != 1) {
		return Plugin_Handled;	
	}
	
	new String:Target[64];
	GetCmdArg(1, Target, sizeof(Target));
	
	new String:targetName[MAX_TARGET_LENGTH];
	new targetList[MAXPLAYERS], targetCount;
	new bool:tnIsMl;
	
	targetCount = ProcessTargetString(Target, client, targetList, sizeof(targetList), COMMAND_FILTER_DEAD, targetName, sizeof(targetName), tnIsMl);

	if(targetCount == 0) {
		ReplyToTargetError(client, COMMAND_TARGET_NONE);
	} else {
		for (new i=0; i<targetCount; i++) {
			doRespawn(client, targetList[i]);
		}
	}
	
	return Plugin_Continue;
}

public doRespawn(client, target) {
		
	CS_RespawnPlayer(target);
}