#include <sourcemod>

public OnPluginStart()
{
	RegConsoleCmd("say",Command_Say)
}

public Action:Command_Say(client,args)
{
	new AdminFlag:flag
	new AdminId:aid = GetUserAdmin(client)
		
	BitToFlag(ADMFLAG_RCON, flag)

	if (!GetAdminFlag(aid, flag, Access_Effective))
		return Plugin_Handled;

	FakeClientCommand(client,"sm_god #%i 0",GetClientUserId(client))
	
	return Plugin_Handled;
}