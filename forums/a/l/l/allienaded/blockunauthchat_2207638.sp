#include <sourcemod>

public Plugin:myinfo =
{
	name = "Block Unauthenticated Chat",
	author = "GoD-Tony",
	description = "Blocks chat messages from unauthenticated users.",
	version = "1.0"
};

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	if (client && !IsClientAuthorized(client))
		return Plugin_Stop;

	return Plugin_Continue;
}