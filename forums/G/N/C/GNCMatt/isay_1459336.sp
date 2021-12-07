#pragma semicolon 1
#include <sourcemod>
#include <tf2_hud>

#define PLUGIN_VERSION  "0.0.1"


public Plugin:myinfo = 
{
	name = "TF2 Hud Say",
	author = "[GNC] Matt",
	description = "Prints a message in a special TF2 HUD area.",
	version = PLUGIN_VERSION,
	url = "http://www.mattsfiles.com"
}

public OnPluginStart()
{
	RegAdminCmd("sm_isay", cmdISay, ADMFLAG_CHAT, "Usage: sm_isay <message> - Prints a message in a special TF2 HUD.");
}


public Action:cmdISay(client, args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_isay <message>");
		return Plugin_Handled;
	}
	else
	{
		new String:arg[256]; GetCmdArgString(arg, sizeof(arg));
		
		PrintToHudAll(arg);
	}
	
	return Plugin_Handled;
}