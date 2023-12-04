#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "",
	author = "",
	description = "",
	version = "",
	url = ""
};


public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	
	int messageLength = strlen(sArgs);
	
	for (int i = 0; i <= messageLength;i++) 
		{
            if (StrEqual(sArgs[i], "?"))
            {
            	PrintToChat(client, "bread.");
				break;
			}
		}
}

