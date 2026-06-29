new connected[MAXPLAYERS];

public OnPluginStart()
{
	RegAdminCmd("sm_connections", cmd_connections, ADMFLAG_GENERIC, "Print in chat players connections lenght");

	HookEvent("player_disconnect", Event_player_disconnect);
}

public Event_player_disconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	connected[client] = 0;
}

public OnClientConnected(client)
{
	if(connected[client] <= 0)
	{
		connected[client] = GetTime();
	}
}

public Action:cmd_connections(client, arg)
{
	decl String:Name[MAX_NAME_LENGTH], connectiontime, mins, secs;

	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			GetClientName(i, Name, sizeof(Name));
			connectiontime = GetTime() - connected[i];
			mins = (connectiontime/60)%60;
			secs = connectiontime%60;
			if(client == 0)
			{
				PrintToConsole(client, "[SM] %s has been connected for %i:%i!", Name, mins, secs);
			}
			else
			{
				PrintToChat(client, "\x01[SM] \x03%s \x01has been connected for \x03%i\x01:\x03%i\x01!", Name, mins, secs);
			}
		}
	}
}