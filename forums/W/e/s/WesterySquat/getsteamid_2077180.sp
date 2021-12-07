#include <sourcemod>
#include <morecolors>

new String:sAuth[20]; /* création variable pour prendre le steam id */

public Plugin:myinfo = 
{
	name = "GetSteamID",
	author = "Westery",
	description = "Simple plugin for get steam ID",
	version = "0.2",
	url = "http://forum.supreme-elite.fr"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_mysteam", Command_mysteam); /* création de la commande pour récuperer mons team id */
	RegConsoleCmd("sm_steamid", Command_steamid); /* création de la commande pour récuperer mons team id */
}

public Action:Command_mysteam(client, args) /* commande pour le steam id */
{
	if (GetClientAuthString(client, sAuth, sizeof(sAuth)))
	{
		CPrintToChat(client, "{white}Hi {fullred}%N{white}, your steam id is : {fullred}%s{white}.", client, sAuth);
		return Plugin_Handled;
	}
}

public Action:Command_steamid(client, args) /* commande pour le steam id */
{
	if (GetClientAuthString(client, sAuth, sizeof(sAuth)))
	{
		CPrintToChat(client, "{white}Hi {fullred}%N{white}, your steam id is : {fullred}%s{white}.", client, sAuth);
		return Plugin_Handled;
	}
}