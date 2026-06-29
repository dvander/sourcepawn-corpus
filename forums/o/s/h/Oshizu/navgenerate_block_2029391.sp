public Plugin:myinfo = 
{
	name = "[ANY] Block Generating Navigation Files",
	author = "Oshizu / Sena™ ¦",
	description = "Disables nav_generate commands so server can't generate navigation files",
	version = "1.0",
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	RegServerCmd("nav_generate", NAVGEN)
	RegConsoleCmd("nav_generate", NAVGEN2)
}

public Action:NAVGEN(args)
{
	return Plugin_Handled;
}

public Action:NAVGEN2(client, args)
{
	return Plugin_Handled;
}