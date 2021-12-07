#pragma semicolon 1
#define PLUGIN_VERSION		"1.1"
static g_iClients[MAXPLAYERS+1], g_iTimeMap[MAXPLAYERS+1], g_iTimeTotal[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[ANY] Playtime",
	author = "SilverShot",
	description = "Display how long you have been connected and how long you have been in the current map.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.com/plugins.php?cat=0&mod=6&title=&author=Silvers&description=&search=1"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_timemap", CmdTimeMap);
	RegConsoleCmd("sm_timetotal", CmdTimeTotal);
	RegConsoleCmd("sm_playtime", CmdTimeTotal);

	// Plugin reload, init arrays.
	for( new i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			g_iClients[i] = GetClientUserId(i);
			g_iTimeMap[i] = RoundToZero(GetClientTime(i));
		}
}

public OnClientPutInServer(client)
{
	if( g_iClients[client] != GetClientUserId(client) )
	{
		g_iClients[client] = GetClientUserId(client);
		if( !IsFakeClient(client) )
			g_iTimeTotal[client] = RoundToZero(GetClientTime(client));
	}
}

public OnMapStart()
{
	for( new i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && !IsFakeClient(i) )
			g_iTimeMap[i] = RoundToZero(GetClientTime(i));
}

public Action:CmdTimeMap(client, args)
{
	if( client && g_iClients[client] == GetClientUserId(client) )
	{
		new String:buffer[70], seconds = RoundToZero(GetClientTime(client)) - g_iTimeMap[client];
		SecondsToTime(seconds, buffer);
		PrintToChat(client, "[Playtime] \x04You have played this map for %s", buffer);
	}
	return Plugin_Handled;
}

public Action:CmdTimeTotal(client, args)
{
	if( client && g_iClients[client] == GetClientUserId(client) )
	{
		new String:buffer[70], seconds = RoundToZero(GetClientTime(client));
		SecondsToTime(seconds, buffer);
		PrintToChat(client, "[Playtime] \x04You have been connected for %s", buffer);
	}
	return Plugin_Handled;
}

SecondsToTime(seconds, String:buffer[70])
{
	new days, hour, mins, secs;
	if( seconds >= 86400 )
	{
		days = RoundToFloor(float(seconds / 86400));
		seconds = seconds % 86400;
    }
	if( seconds >= 3600)
	{
		hour = RoundToFloor(float(seconds / 3600));
		seconds = seconds % 3600;
    }
	if( seconds >= 60)
	{
		mins = RoundToFloor(float(seconds / 60));
		seconds = seconds % 60;
    }
	secs = RoundToFloor(float(seconds));

	if( days )
		Format(buffer, 70, "%s\x01%d\x04 days, ", buffer, days);
	if( hour )
		Format(buffer, 70, "%s\x01%d\x04 hours, ", buffer, hour);
	Format(buffer, 70, "%s\x01%d\x04 mins, ", buffer, mins);
	Format(buffer, 70, "%s\x01%d\x04 secs", buffer, secs);
}