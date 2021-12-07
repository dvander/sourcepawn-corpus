public void OnPluginStart()
{
	RegConsoleCmd("sm_1v1", Command_1v1, "- Start a 1v1 config");
	RegConsoleCmd("sm_5v5", Command_5v5, "- Start a 5v5 config");
}

public Action:Command_1v1(client, args)
{
	ServerCommand("exec 1v1.cfg");
	return Plugin_Handled;
}

public Action:Command_5v5(client, args)
{
	ServerCommand("exec 5v5.cfg");
	return Plugin_Handled;
}

public Plugin myinfo = 
{
	name = "Load Config",
	author = "Sidezz",
	description = "Stuff for people",
	version = SOURCEMOD_VERSION,
	url = ""
};