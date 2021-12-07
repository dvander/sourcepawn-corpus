public Plugin:myinfo = 
{
	name = "Banned by ip, log steamid",
	author = "Bacardi",
	description = "Log player steamid when banned by IP",
	version = "0.1",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("server_addban", ServerAddban, EventHookMode_Post);
}

public ServerAddban(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:ip[16];
	ip[0] = '\0';
	GetEventString(event, "ip", ip, sizeof(ip));

	if(ip[0] != '\0')	// Was IP ban by server ?
	{
		new userid = GetEventInt(event, "userid");
	
		if(userid)	// Client still server ?
		{
			userid = GetClientOfUserId(userid);
			LogToFile("logs/banidlogsteamid.log", "%L %s", userid, ip);
		}
	}
}