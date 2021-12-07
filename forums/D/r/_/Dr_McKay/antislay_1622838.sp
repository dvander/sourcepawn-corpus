#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new bool:antiSlay[MAXPLAYERS + 1] = false;

public Plugin:myinfo = {
	name        = "[Any] Anti-Slay",
	author      = "Dr. McKay",
	description = "Gives particular players immunity to admin slay",
	version     = "1.0.0",
	url         = "http://www.doctormckay.com"
};

public OnPluginStart() {
	RegAdminCmd("sm_adminslay", Command_Slay, ADMFLAG_SLAY, "Slays a player");
	RegAdminCmd("sm_antislay", Command_AntiSlay, ADMFLAG_ROOT, "Prevents an admin from slaying a player");
}

public OnClientConnected(client) {
	antiSlay[client] = false;
}

public OnClientDisconnect(client) {
	antiSlay[client] = false;
}

public Action:Command_Slay(client, args) {
	if(args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_adminslay [target]");
		return Plugin_Handled;
	}
	new String:arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	decl target_count;
	
	target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml);
	
	if(target_count <= 0) {
		ReplyToCommand(client, "[SM] No matching client was found.");
		return Plugin_Handled;
	}
	
	ShowActivity2(client, "[SM] ", "Slayed %s", target_name);
	LogAction(client, -1, "%L slayed %s", client, target_name);
	
	for(new i = 0; i < target_count; i++) {
		if(!antiSlay[target_list[i]]) {
			if(IsPlayerAlive(i)) ForcePlayerSuicide(i);
		}
		else if(target_count == 1) ReplyToCommand(client, "[SM] That target has slay immunity.");
	}
	
	return Plugin_Handled;
}

public Action:Command_AntiSlay(client, args) {
	if(args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_antislay [target]");
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	decl target_count;
	
	target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml);
	
	if(target_count <= 0) {
		ReplyToCommand(client, "[SM] No matching client was found.");
		return Plugin_Handled;
	}
	
	ShowActivity2(client, "[SM] ", "Toggled slay immunity on %s", target_name);
	LogAction(client, -1, "%L toggled slay immunity on %s", client, target_name);
	
	for(new i = 0; i < target_count; i++) {
		if(IsClientInGame(i)) antiSlay[target_list[i]] = !antiSlay[target_list[i]];
	}
	
	return Plugin_Handled;
}