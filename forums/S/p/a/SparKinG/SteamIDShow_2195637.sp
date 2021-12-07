#include <sourcemod>
#include <morecolors>

new String:sAuth[20]; 

public Plugin:myinfo = 
{
	name = "SteamIDShow",
	author = "SparKinG",
	description = "Show's your SteamID",
	version = "1.0",
}

public OnPluginStart()
{
	RegConsoleCmd("sm_steamid", Command_steamid);
}

public Action:Command_steamid(client, args)
{
	if (GetClientAuthString(client, sAuth, sizeof(sAuth)))
	{
		CPrintToChat(client, "{deepskyblue}Hi {fullblue}%N{deepskyblue}, your SteamID is: {fullblue}%s{deepskyblue}!", client, sAuth);
		return Plugin_Handled;
	}
}