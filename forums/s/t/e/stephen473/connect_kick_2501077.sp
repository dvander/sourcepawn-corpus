#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Connect Kicker",
	author = "Hardy",
	description = "When player connect,he is kicked auto! [NO TESTED!]",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{	
}

public OnClientPutInServer(client)
{
KickClient(client, "This server closed! New IP : X.X.X.X.X.X");
}
