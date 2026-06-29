#include <sourcemod>
 
public OnClientConnected(client)
{
        if(!IsFakeClient(client))
	{
	       new String:name[64]
	       GetClientName(client, name, sizeof(name))
	       PrintToChatAll("%s has joined the game", name)
        }
}