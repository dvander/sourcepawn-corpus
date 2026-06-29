#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Hostname Map Display",
	author = "Xatt1c",
	description = "Displays the current map in the hostname.",
	version = "1.1.0",
	url = ""
}

public OnMapStart()
{
	CreateTimer(0.2, HostnameTimer);
}

public OnMapEnd()
{
	ServerCommand("exec server.cfg");
}

public Action:HostnameTimer(Handle:timer)
{
	decl String:sname[256], String:map[256], String:servername[256];
	GetClientName(0, sname, sizeof(sname));
	GetCurrentMap(map, sizeof(map));
	Format(servername, sizeof(servername), "%s Map: %s", sname, map);
	ServerCommand("hostname %s", servername);
}