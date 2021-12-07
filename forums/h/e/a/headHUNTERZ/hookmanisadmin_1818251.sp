#include <sourcemod>

public Plugin:myinfo = 
{
		name = "Hook Mani's admin",
		author = "headHUNTERZ",
		description = "Lets you use the admin command for SourceMod. Usefull if you switch from Mani to SourceMod.",
		version = "1.0",
		url = "http://www.sourcemod.com/" 
}

public OnPluginStart()
{
        RegConsoleCmd("admin", Command_Admin);
}

public Action:Command_Admin(client, args)
{
        FakeClientCommand(client, "sm_admin");
        return Plugin_Handled;
}
