#include <sourcemod>
 
public Plugin:myinfo =
{
	name = "Server Commander",
	author = "Unrealomega",
	description = "Allows an admin to execute server-side commands from client-side.",
	version = "1.0",
	url = "http://gangstagang.com"
};
 
public OnPluginStart()
{
	RegAdminCmd("sm_server", Command_Server, ADMFLAG_RCON);
}

public Action:Command_Server(client, args)
{
	decl String:Command[512];
	
	GetCmdArg(1, Command, sizeof(Command));
	if (args == 0){
		PrintToConsole(client, "sm_server [Command]");
		return Plugin_Handled;
	}
	else {
		ServerCommand(Command);
		return Plugin_Handled;
	}
}