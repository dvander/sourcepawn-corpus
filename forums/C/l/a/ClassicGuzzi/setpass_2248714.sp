#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new String:LastPass[32];
new Handle:g_pass;

public Plugin:myinfo =
{
	name = "Set Password!",
	author = "Classic",
	description = "Lets any admin to set its own password.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_pass", Command_Pass, ADMFLAG_PASSWORD,"Sets server password");
	RegAdminCmd("sm_nopass", Command_NoPass, ADMFLAG_PASSWORD,"Sets server password as none");
	g_pass = FindConVar("sv_password");
	GetConVarString(g_pass,LastPass,sizeof(LastPass));

}


public Action:Command_Pass(client, args)
{	
	new String:Pass[32];
	
	if(args == 0)
	{
		ReplyToCommand(client,"The current password is \"%s\".",LastPass);
		return Plugin_Handled;
	}
	
	if (args > 0)
	{
		GetCmdArg(1, Pass, sizeof(Pass));
		SetConVarString(g_pass,Pass,false,true);
		strcopy(LastPass,sizeof(LastPass),Pass);
		ReplyToCommand(client,"The new password is \"%s\".",Pass);
	}
	return Plugin_Handled;	
}

public Action:Command_NoPass(client, args)
{	
	SetConVarString(g_pass,"",false,true);
	strcopy(LastPass,sizeof(LastPass),"");
	ReplyToCommand(client,"The new password is \"\".");
	return Plugin_Handled;	
}	