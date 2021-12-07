#include <sourcemod>
#define permission ADMFLAG_ROOT // What group can use sm_forcecmd command? (Default: root)

public Plugin myinfo = 
{
	name = "Forces Player to Use Command",
	author = "ReyZ",
	description = "Forces player to use a command",
	version = "1",
	url = "https://www.sourcemod.net",
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
	
	char arg1[32];GetCmdArg(1, arg1, sizeof(arg1));
	char arg2[MAX_NAME_LENGTH];GetCmdArgString(arg2, sizeof(arg2));
	
	ReplaceStringEx(arg2, sizeof(arg2), arg1, "");ReplaceStringEx(arg2, sizeof(arg2), " ", "");
	
	int target = FindTarget(client, arg1);
	
	if (target == -1)
	{
		PrintToChat(client, "\x04[Sourcemod] \x01Player not found.");
		return Plugin_Handled;
	}
	
	FakeClientCommand(target, "%s", arg2);
	return Plugin_Handled;
}