#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Grunt Kicker",
	author = "anacron",
	description = "Kick player named Grunt",
	version = "1.0.8",
	url = "http://inFamous-Clan.eu"
}
public OnPluginStart()
{
	HookEvent("player_changename",Event_player_changename);
}
public OnClientPostAdminCheck(client)
{
	decl String:name[128];
	GetClientName(client, name, 256);
	if (StrContains(name,"Grunt",false) > -1)
	{
		KickClient(client,"Set Your name correctly.");
		PrintToChatAll("Player %s was kicked for unapproved nickname", name);
	}
}
public Event_player_changename(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:newname[128];
	GetEventString(event,"newname",newname,256);
	if (StrContains(newname,"Grunt",false) > -1)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		KickClient(client,"Set Your name correctly.");
		PrintToChatAll("Player %s was kicked for unapproved nickname", newname);
	}
}
