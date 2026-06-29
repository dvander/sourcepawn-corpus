#include <sourcemod>

public Plugin:myinfo =
{
	name = "Block Spectator Chat",
	author = "Sidezz",
	description = "Disabled spectator text chat",
	version = "1.0",
	url = "coldcommunity.com"
}

public OnPluginStart()
{
	AddCommandListener(blockSpectatorChat, "say");
	AddCommandListener(blockSpectatorChat, "say_team");
}

public Action:blockSpectatorChat(client, const String:command[], argc)
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		if(!CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
		{
			if(GetClientTeam(client) <= 1)
			{
				//Block Text:
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
} 