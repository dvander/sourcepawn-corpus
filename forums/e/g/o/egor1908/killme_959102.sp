/* Plugin Template generated by Pawn Studio */

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Kill me",
	author = "Egor",
	description = "Kills a player when he types !kill",
	version = "0.1",
	url = "http://forums.alliedmods.net/showthread.php?t=105997"
}

public OnPluginStart()
{
		RegConsoleCmd("sm_kill", killme);
}

public Action:killme(client, args)
{
		decl String:clientName[64];
		GetClientName(client, clientName, sizeof(clientName));

		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				ClientCommand(i, "kill");
			}
		}
}


public IsValidClient (client)  //Client validation here, i dunno what for but i add it anyway :P
{
    if (client == 0)
        return false;
    
    if (!IsClientConnected(client))
        return false;
    
    if (IsFakeClient(client))
        return false;
    
    if (!IsClientInGame(client))
        return false;	
		
    return true;
}
