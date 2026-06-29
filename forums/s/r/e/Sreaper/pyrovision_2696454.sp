#pragma semicolon 1

#define PLUGIN_AUTHOR "Sreaper"
#define PLUGIN_VERSION "1.00"
#define PYROVISION_ATTRIBUTE "vision opt in flags"

#include <tf2> 
#include <tf2attributes>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Pyrovision", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_pv", Command_PV, ADMFLAG_GENERIC, "Add pyro vision to the target(s), Usage: sm_pv \"target\" \"condition number\" \"duration\"");
}

public Action Command_PV(int client, int args) {
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_pv <target> <enable(0/1)>)");
		return Plugin_Handled;
	}

	
	
	char arg1[65], arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int ienable = StringToInt(arg2);
	
	if (!StrEqual(arg2, "0") && !StrEqual(arg2, "1"))
	{
		ReplyToCommand(client, "[SM] Usage: sm_pv <target> <enable(0/1)>");
		return Plugin_Handled;
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
				arg1, 
				client, 
				target_list, 
				MAXPLAYERS, 
				COMMAND_FILTER_ALIVE, 
				target_name, 
				sizeof(target_name), 
				tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if (view_as<bool>(ienable))
			TF2Attrib_SetByName(target_list[i], PYROVISION_ATTRIBUTE, 1.0);
		else
			TF2Attrib_SetByName(target_list[i], PYROVISION_ATTRIBUTE, 0.0);
		LogAction(client, target_list[i], "\"%L\" %s Pyro Vision on \"%L\".", client, (ienable ? "Enabled" : "Disabled"), target_list[i]);
	}
	
	ShowActivity2(client, "[SM] ", "%s Pyro Vision on %s", (ienable ? "Enabled" : "Disabled"), target_name);
	return Plugin_Handled;
}