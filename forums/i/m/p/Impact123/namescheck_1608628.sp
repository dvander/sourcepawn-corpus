#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

// Define your unwated names here
new String:g_PermittedNames[][] = {"unnamed", "unconnected", "", "hitler", "asshole", "motherfucker", "bitch"};

// Define the name it should change to here
new String:g_ChangedName[] = "Change your Name";

public Plugin:myinfo = 
{
	name = "New Plugin",
	author = "Unknown",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}



public OnClientSettingsChanged(client)
{
	// CreateTimer(3.0, CheckNameTimer, client);
	CheckName(client);
}



public OnClientPostAdminCheck(client)
{
	// CreateTimer(3.0, CheckNameTimer, client);
	CheckName(client); 
}


/* Used for timer
public Action:CheckNameTimer(Handle:timer, any:client)
{
	CheckName(client);
}
*/



CheckName(client)
{
	if(client >0 && IsClientConnected(client) && IsClientInGame(client))
	{
		decl String:ClientName[MAX_NAME_LENGTH];
		GetClientName(client, ClientName, sizeof(ClientName));
		new len = sizeof(g_PermittedNames);
		for(new i; i< len;i++)
		{
			if(StrContains(ClientName, g_PermittedNames[i], false) != -1)
			{
				SetClientInfo(client, "name", g_ChangedName);
				SetEntPropString(client, Prop_Data, "m_szNetname", g_ChangedName);
				break;
			}
		}
	}
}
