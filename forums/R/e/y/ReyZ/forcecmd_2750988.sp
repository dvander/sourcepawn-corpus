#include <sourcemod>
#define permission ADMFLAG_ROOT // What group can use sm_forcecmd command? (Default: root)

public Plugin myinfo = 
{
	name = "Forces Player to Use Command", 
	author = "ReyZ", 
	description = "Forces player to use a command", 
	version = "1.1", 
	url = "https://github.com/ReyZ19", 
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_forcecmd", forcecmd, permission);
}

public Action forcecmd(int client, int args)
{
	if (args <= 1)
	{
		ReplyToCommand(client, "\x04[Sourcemod] \x01Usage: \x05sm_forcecmd <name> <command>");
		return Plugin_Handled;
	}
	char arg1[32]; GetCmdArg(1, arg1, sizeof(arg1));
	char arg2[2048]; GetCmdArgString(arg2, sizeof(arg2));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(
				arg1, 
				client, 
				target_list, 
				MAXPLAYERS, 
				COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_IMMUNITY, 
				target_name, 
				sizeof(target_name), 
				tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	ReplaceStringEx(arg2, sizeof(arg2), arg1, ""); ReplaceStringEx(arg2, sizeof(arg2), " ", "");
	for (int i = 0; i < target_count; i++) {
		FakeClientCommand(target_list[i], "%s", arg2);
	}
	return Plugin_Handled;
} 