#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
    name = "[ANY] Redirector",
    author = "Dr. McKay",
    description = "Redirects players using a command",
    version = PLUGIN_VERSION,
    url = "http://www.doctormckay.com"
}

new Handle:messageTimeCvar = INVALID_HANDLE;

public OnPluginStart() {
	RegAdminCmd("sm_redirect_show", Command_Redirect, ADMFLAG_BAN);
	messageTimeCvar = CreateConVar("sm_redirect_time", "30.0", "The time in seconds to show the redirect dialog for");
	LoadTranslations("common.phrases");
}

public Action:Command_Redirect(client, args) {
	if(args != 2) {
		ReplyToCommand(client, "[SM] Usage: sm_redirect_show <target> <IP>");
		return Plugin_Handled;
	}
	decl String:arg1[MAX_NAME_LENGTH], String:arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new Float:time = GetConVarFloat(messageTimeCvar);
	
	decl String:target_name[MAX_NAME_LENGTH];
	new target_list[MAXPLAYERS];
	new target_count;
	new bool:tn_is_ml;
	
	if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for(new i = 0; i < target_count; i++) {
		DisplayAskConnectBox(target_list[i], time, arg2);
	}
	ShowActivity2(client, "[SM] ", "Redirected '%s' to '%s'", target_name, arg2);
	return Plugin_Handled;
}