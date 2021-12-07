#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "PlayerJoin",
	author = "WinCher",
	description = "Player Join Message On Your Server",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnClientAuthorized(client)
{
	if(!(client>0 && client<=MaxClients))
		return;

	new String:sAuthString[32];
	GetClientName(client, sAuthString, sizeof(sAuthString));

	if(!IsFakeClient(client) && StrEqual(sAuthString, "", false))
		return;

	if(!IsFakeClient(client))
	{
		if(client==0)
			return;

		decl String:join[PLATFORM_MAX_PATH], String:playername[128];
		GetClientName(client, playername, sizeof(playername));
		PrintHintTextToAll("Player %s Connected to server", playername);
	}
	return;
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
		if(client==0)
			return;

		decl String:join[PLATFORM_MAX_PATH], String:playername[128];
		GetClientName(client, playername, sizeof(playername));
		PrintHintTextToAll("Player %s Disconnected the server", playername);
	}
}