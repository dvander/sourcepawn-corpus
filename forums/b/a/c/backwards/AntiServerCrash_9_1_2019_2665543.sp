#include <sourcemod>

public Plugin myinfo =
{
	name = "Anti Server Crash 9/1/2019",
	author = "backwards",
	description = "Prevents New Server Crash Exploit.",
	version = SOURCEMOD_VERSION,
	url = "http://www.steamcommunity.com/id/mypassword"
};

public OnAllPluginsLoaded()
{
	AddCommandListener(Listen);
}

public Action:Listen(client, const String:command[], argc)
{
	if(StrEqual(command, "survival_equip"))
	{
		if(IsValidClient(client))
			if(!IsClientInKickQueue(client))
				KickClient(client, "Server Crash Exploit Attempt");
			
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool IsValidClient(int client)
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
        return false;
 
    return true;
}