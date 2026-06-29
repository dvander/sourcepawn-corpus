#pragma semicolon 1
#include <sourcemod>
#define VERSION "0.1"

public Plugin:myinfo =
{
	name = "Welcome Message",
	author = "XARiUS",
	description = "Simple welcome message announcer.",
	version = "0.1",
	url = "http://www.the-otc.com/"
};

public OnPluginStart()
{
  CreateConVar("sm_welcome_version", VERSION, "Simple welcome message announcer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnClientPostAdminCheck(client)
{
  new String:clientname[MAX_NAME_LENGTH];
  GetClientName(client, clientname, sizeof(clientname));
  PrintToChatAll("[SM] Welcome to our server, %s.  Please enjoy your stay!", clientname);
}
