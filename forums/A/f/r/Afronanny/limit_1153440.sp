#include <sourcemod>

new Handle:g_hCvarEnabled;
new Handle:g_hCvarMaxPlayers;

public Plugin:myinfo = 
{
	name = "Player Limit",
	author = "Afronanny",
	description = "Limit the amount of non-reserved-slot players in the server",
	version = "1.0",
	url = "http://lmgtfy.com"
}

public OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("sm_connectionlimit_enabled", "1", "Enable/disable plugin", FCVAR_SPONLY);
	g_hCvarMaxPlayers = CreateConVar("sm_connectionlimit_limitat", "3", "Number of clients to cap at before limit is put into effect", FCVAR_SPONLY);
}

public OnClientPostAdminCheck(client)
{
	if (GetConVarBool(g_hCvarEnabled))
	{
		new flags = GetUserFlagBits(client);
		if (!(flags & ADMFLAG_RESERVATION))
		{
			if (GetClientCount() > GetConVarInt(g_hCvarMaxPlayers))
			{
				KickClient(client, "This slot is reserved");
			}
		}
	}
}
