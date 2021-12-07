#include <sourcemod>

public OnPluginStart()
{
	RegAdminCmd("sm_steam", command_printGroup, ADMFLAG_GENERIC, "Print what you set");
}

public Action:command_printGroup(client, args)
{
	PrintToChatAll("group");
	return Plugin_Handled;
}
