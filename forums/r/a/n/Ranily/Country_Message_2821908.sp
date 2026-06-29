#include <sourcemod>
#include <geoip>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "Country Join Message",
	author = "Ranily",
	description = "Get Players location",
	version = "1.0.0",
	url = "https://github.com/Ranily57/Coutry_Join_Message"
};

public void OnClientPutInServer(int client)
{
	char ipAddress[32];
	GetClientIP(client, ipAddress, sizeof(ipAddress));

	char country[64];
	GeoipCountry(ipAddress, country, sizeof(country));

	char playerName[32];
	GetClientName(client, playerName, sizeof(playerName));

	char message[128];
	Format(message, sizeof(message), "%s has joined the game from %s", playerName, country);

	PrintToChat(client, message);
}