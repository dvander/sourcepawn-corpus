#include <sourcemod>

public Plugin:myinfo =
{
    name = "Dumbass zapper", 
    author = "Kigen", 
    description = "The dumbasses stop here!", 
    version = "1.0", 
    url = "http://www.codingdirect.com/"
};

public OnPluginStart()
{
	CreateConVar("dumbasszapper_version", "1.0", "Dumbass Zapper version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnClientAuthorized(client, const String:auth[])
{
	CreateTimer(0.1, ZapDumbass, client);
}

public Action:ZapDumbass(Handle:timer, any:client)
{
	BanClient(client, 0, BANFLAG_AUTO, "Dumbass", "You've been banned for being a dumbass");
	return Plugin_Stop;
}