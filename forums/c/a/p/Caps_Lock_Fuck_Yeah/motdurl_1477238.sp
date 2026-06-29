#pragma semicolon 1
#define PLUGIN_VERSION "1.1"
//Includes:
#include <sourcemod>

public Plugin:myinfo = {
    name = "Open URL MOTD",
    author = "CAPS LOCK FUCK YEAH",
    description = "Goes to a specified URL on the clients MOTD browser",
    version = PLUGIN_VERSION,
    url = "http://achievementwhores.dyndns.org"
};

public OnPluginStart() {
	RegAdminCmd("sm_hiddenurl",Command_url,ADMFLAG_GENERIC,"Goes to a website using the MOTD browser, stealth-style");
	RegAdminCmd("sm_openurl",Command_Vurl,ADMFLAG_GENERIC,"Goes to a website using the MOTD browser");
	LoadTranslations("common.phrases");
}

public Action:Command_url(client, args)
{

	new String:arg1[32], String:arg2[128], argcount;
 
	argcount = GetCmdArgs();
	if(argcount == 0 || argcount == 1){
		ReplyToCommand(client, "Usage: sm_hiddenurl <target> <URL>");
		return Plugin_Handled;
	}
	if(argcount == 2)
	{
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	target_count = ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_NO_BOTS,target_name,sizeof(target_name),tn_is_ml);
 
	if(target_count <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Opened %s on %t", arg2, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Opened %s on %s", arg2, target_name);
	}
 
	for (new i = 0; i < target_count; i++)
	{
			DoUrl(target_list[i], arg2); 
	}
	}
	return Plugin_Handled;
}
public Action:Command_Vurl(client, args)
{

	new String:arg1[32], String:arg2[128], argcount;
 
	argcount = GetCmdArgs();
	if(argcount == 0 || argcount == 1){
		ReplyToCommand(client, "Usage: sm_openurl <target> <URL>");
		return Plugin_Handled;
	}
	if(argcount == 2)
	{
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	target_count = ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_NO_BOTS,target_name,sizeof(target_name),tn_is_ml);
 
	if(target_count <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Opened %s on %t", arg2, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Opened %s on %s", arg2, target_name);
	}
 
	for (new i = 0; i < target_count; i++)
	{
			DoUrlVisible(target_list[i], arg2); 
	}
	}
	return Plugin_Handled;
}

public Action:DoUrl(client, String:url[128])
{
	new Handle:setup = CreateKeyValues("data");
	
	KvSetString(setup, "title", "Musicspam");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", url);
	
	ShowVGUIPanel(client, "info", setup, false);
	CloseHandle(setup);
	return Plugin_Handled;
}
public Action:DoUrlVisible(client, String:url[128])
{
	new Handle:setup = CreateKeyValues("data");
	
	KvSetString(setup, "title", "Musicspam");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", url);
	
	ShowVGUIPanel(client, "info", setup, true);
	CloseHandle(setup);
	return Plugin_Handled;
}