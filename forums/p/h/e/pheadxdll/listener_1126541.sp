#include <sourcemod>

public OnPluginStart()
{
	AddCommandListener(Listener_AdminOnly, "build");
}

public Action:Listener_AdminOnly(client, const String:command[], argc)
{	
	if(client && argc && !(GetUserFlagBits(client) & ADMFLAG_CUSTOM1))
	{
		new String:strCommand[5];
		GetCmdArg(1, strCommand, sizeof(strCommand));
		
		if(StringToInt(strCommand) == 3)
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
