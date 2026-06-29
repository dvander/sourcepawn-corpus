#include <sourcemod>

public Plugin myinfo = {
	name = "Fexec",
	author = "Sadpeak",
	description = "executes a command on behalf of another player",
	version = "1.2",
	url = "http://steamcommunity.com/id/sadpeak"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases"); 
	RegAdminCmd("sm_fexec", fake_exec, ADMFLAG_ROOT, "executes a command on behalf of another player");
	RegAdminCmd("sm_exec", exec, ADMFLAG_ROOT, "executes a command on behalf of another player");
}
 
public Action fake_exec(int client, int args) {
	char arg[256];
	char name[65];
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
 	GetCmdArg(1, name, sizeof(name));
	GetCmdArg(2, arg, sizeof(arg));
	
	if ((target_count = ProcessTargetString(
			name,
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (int i = 0; i < target_count; i++) {
			FakeClientCommandEx(target_list[i], arg);
	}
	}

	return Plugin_Handled;
}

public Action exec(int client, int args) {
	char arg[256];
	char name[65];
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
 	GetCmdArg(1, name, sizeof(name));
	GetCmdArg(2, arg, sizeof(arg));
	
	if ((target_count = ProcessTargetString(
			name,
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (int i = 0; i < target_count; i++) {
			ClientCommand(target_list[i], arg);
	}
	}

	return Plugin_Handled;
}