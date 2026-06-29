#include <sourcemod>

public Plugin:myinfo =
{
	name = "VIP Connect",
	author = "Sreaper",
	description = "Displays VIP when a VIP client connects",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnClientPutInServer(client)
{
	CreateTimer(20.0, PrintSuperVIPStuff, GetClientUserId(client));
}

public Action:PrintSuperVIPStuff(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0)
{
PrintToChatAll("VIP %N connected", client);
}
}