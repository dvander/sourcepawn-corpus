#include <sourcemod>

public OnPluginStart()
{
	AddCommandListener(Command_InterceptSuicide, "kill");
	AddCommandListener(Command_InterceptSuicide, "explode");
}

public Action:Command_InterceptSuicide(client, const String:command[], args)
{
	PrintToChatAll("{TEAM}%N {DEFAULT}is no more.", client);
	return Plugin_Continue;
}