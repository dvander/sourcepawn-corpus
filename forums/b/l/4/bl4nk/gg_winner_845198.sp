#pragma semicolon 1

#include <sourcemod>
#include <gungame>

#define PLUGIN_VERSION "1.0.0"

new String:LastKill[MAXPLAYERS+1][32];

public Plugin:myinfo =
{
	name = "GunGame Winner",
	author = "bl4nk",
	description = "Shows a MOTD window with the winner's information when the game is won",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	decl String:victimName[32];
	GetClientName(victim, victimName, sizeof(victimName));

	LastKill[attacker] = victimName;
}

public GG_OnWinner(client, const String:weapon[])
{
	decl String:name[32], String:url[256];
	GetClientName(client, name, sizeof(name));

	Format(url, sizeof(url), "http://gungame5.com/gg5_win.php?winnerName=%s&loserName=%s&wins=%i&place=%s&totalPlaces=%s", name, LastKill[client], GG_GetClientWins(client), 0, 0);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ShowMOTDPanel(i, "", url, MOTDPANEL_TYPE_URL);
		}
	}
}