#include <sourcemod>
#include <sdktools>
#include <cstrike>


public Plugin:myinfo =
{
    name = "Balise",
    author = "Btx",
    description = "Balise for Zombiemod server",
    version = "1.0",
    url = "<- URL ->"
}

public OnPluginStart()
{
	AddCommandListener(Event_SayCallback, "say");
	AddCommandListener(Event_SayCallback, "say_team");
}

 
 public Action:Event_SayCallback(client, const String:command[], argc)
{
	if (client == 0 || !IsClientInGame(client) || IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	decl String:message[32];
	GetCmdArgString(message, sizeof(message));
	StripQuotes(message);
	
	if(StrEqual(message, "!balise"))
{
	client = GetClientUserId(client);
	ServerCommand("sm_beacon #%d", client);
	return Plugin_Handled;
}
return Plugin_Continue;
}
