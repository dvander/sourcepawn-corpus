#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "sm_redirect",
	author = "Ratty",
	description = "shows a dialog asking people to connect to other servers",
	version = PLUGIN_VERSION,
	url = "http://nom-nom-nom.us/"
}

public OnPluginStart()
{
	RegAdminCmd( "sm_redirect",    Redirect,      ADMFLAG_CHEATS, "<client> <server>" );
}

public Action:Redirect( client, args )
{

	decl String:Name[MAX_NAME_LENGTH] = "";
	new String:Server[192];

	if (args != 2 )
	{
	ReplyToCommand (client, "Usage: sm_redirect \"<user>\" \"<server ip:port>\"");
	return Plugin_Handled;
	}

	GetCmdArg (1, Name, sizeof (Name));
	GetCmdArg (2, Server, sizeof (Server));
	new iClient = FindTarget(client, Name, true, false);

	if (iClient == -1)
	{ 
		ReplyToCommand (client, "Erf.");
		return Plugin_Handled;
	}

	DisplayAskConnectBox(client, 10.0, Server)
	return Plugin_Handled;

}
