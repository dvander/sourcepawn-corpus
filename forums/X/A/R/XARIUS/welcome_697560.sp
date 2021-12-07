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
  CreateTimer(1.0, PrintWelcome, client, TIMER_REPEAT);
}

public Action:PrintWelcome(Handle:timer, any:client)
{
  new String:clientname[MAX_NAME_LENGTH];
  static TimesRepeated = 0;
  if (TimesRepeated <=5)
  {
    GetClientName(client, clientname, sizeof(clientname));
    PrintHintText(client, "Welcome to our server, %s.  Please enjoy your stay!", clientname);
    TimesRepeated++;
    return Plugin_Continue;
  }
  else
  {
    TimesRepeated = 0;
    return Plugin_Stop;
  }
}