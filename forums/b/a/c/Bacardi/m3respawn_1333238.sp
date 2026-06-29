#pragma semicolon 1
#include <sourcemod>
#include <cstrike>

public Plugin:myinfo = {
	name = "M3Respawn - Respawn a dead player",
	author = "M3Studios, Inc.",
	description = "Let's admins respawn any dead player.",
	version = "0.1.1",
	url = "http://forums.alliedmods.net/showpost.php?p=1333238&postcount=26"
}

public OnPluginStart() {
	LoadTranslations("common.phrases"); // Fix [SM] Native "ReplyToCommand" reported: Language phrase "No matching client" not found
	RegAdminCmd("sm_respawn", CmdRespawn, ADMFLAG_KICK, "sm_respawn <#userid|name>");
}

public Action:CmdRespawn(client, args) {
/*	if (args != 1) {
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
*/

	// I take this whole code snip from SM funcommands plugin
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <#userid|name>");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_DEAD,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		doRespawn(client, target_list[i]);
	}

	//return Plugin_Continue;
	return Plugin_Handled; //Fix not show "Unknown command: sm_respawn" on console after respawn dead player
}

public doRespawn(client, target) {
	// Fix not respawn spectators, only players in team CT and T
	if(GetClientTeam(target) >= 2) {

		if(client != target) {
			new String:adminName[MAX_NAME_LENGTH];
			GetClientName(client, adminName, sizeof(adminName));
		
			PrintCenterText(target, "%s has given you another chance", adminName);
		}

		CS_RespawnPlayer(target);
	}
}