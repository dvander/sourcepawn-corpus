
#include <sourcemod>

public Plugin:myinfo = 
{
	name = "[TF2]Popfiles",
	author = "Bitl",
	description = "Loads popfiles easier on the server",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_popfile", Command_Popfile, ADMFLAG_RCON);
}

public Action:Command_Popfile(client, args)
{
	if (args == 0)
	{
		PrintToChat(client, "sm_popfile [Popfile name] or !popfile [Popfile name]");
	}
	else if (args == 1)
	{
		new String:arg[256];
		GetCmdArgString(arg, sizeof(arg));
		ServerCommand("tf_mvm_popfile %s", arg);
	}
}
