#include <sourcemod>
#include <cstrike>
#include <sdktools>

public Plugin:myinfo =
{
	name = "[Scoreboard] Tags-Fix",
	description = "Scoreboard tags-fix",
	author = ".P4NDAzz",
	version = "0.2",
	url = "http://steamcommunity.com/id/PhilipTheBoss321"
};

Handle WelcomeTimers[MAXPLAYERS+1];
 
public void OnClientPutInServer(int client)
{
	WelcomeTimers[client] = CreateTimer(0.1, WelcomePlayers, TIMER_REPEAT, client);
}
 
public Action WelcomePlayers(Handle timer, any client)
{
    if (CheckCommandAccess(client, "founder", ADMFLAG_ROOT))
    {
        CS_SetClientClanTag(client, "[Owner]");
    }
    else if (CheckCommandAccess(client, "headadmin", ADMFLAG_CHEATS))
	{
		CS_SetClientClanTag(client, "[Head-Admin]");
	}
	else if (CheckCommandAccess(client, "admin", ADMFLAG_GENERIC))
	{
		CS_SetClientClanTag(client, "[Admin]");
	}
	else if (CheckCommandAccess(client, "vip", ADMFLAG_CUSTOM1))
	{
		CS_SetClientClanTag(client, "[VIP]");
	}
}