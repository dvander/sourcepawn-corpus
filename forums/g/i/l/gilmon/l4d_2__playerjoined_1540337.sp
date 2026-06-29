#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[L4D2]Player Join",
	author = "gilmon",
	description = "Show who joined the server",
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

		decl String:file[PLATFORM_MAX_PATH], String:playername[128];
		BuildPath(Path_SM, file, sizeof(file), "logs/joinedplayer.log");

		GetClientName(client, playername, sizeof(playername));
		LogToFileEx(file, "Player %s Connected to server", playername);
		PrintToChatAll("\x03%s\x01 \x04is join the game\x01", playername);
	}
	return;
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
		if(client==0)
			return;

		decl String:file[PLATFORM_MAX_PATH], String:playername[128];
		BuildPath(Path_SM, file, sizeof(file), "logs/exitedplayer.log");

		GetClientName(client, playername, sizeof(playername));
		LogToFileEx(file, "Player %s Disconnected the server", playername);
		PrintToChatAll("\x04Player\x01 \x03%s\x01 \x04 is leave the game\x01", playername);
	}
}