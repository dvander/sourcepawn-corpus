//Simple Booter

#include <sourcemod>
#include <sdkhooks>

#define VERSION "1.0.0b"

public Plugin:myinfo =
{
    name = "Simple Booter", 
    author = "JZServices", 
    description = "Source Bugfix", 
    version = VERSION, 
    url = "http://www.notdcommunity.com"
};

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		new bool:matched=false;
		decl String:clientsteamid[64];
		GetClientAuthString(client,clientsteamid,sizeof(clientsteamid));
		for (new x=1;x<MaxClients;x++)
		{
			if (client==x){continue;}
			if (IsClientConnected(x))
			{
				decl String:playersteamid[64];
				GetClientAuthString(x,playersteamid,sizeof(playersteamid));
				if (StrEqual(clientsteamid,playersteamid,false))
				{
					PrintToServer("Matched player %N - %s and %N - %s",client,clientsteamid,x,playersteamid);
					ServerCommand("kickid %d", GetClientUserId(client));
					matched=true;
				}
			}
		}
		if (!matched){PrintToServer("Player %N - %s validated",client,clientsteamid);}
	}
}
