#include <sourcemod>
#include <geoip>
#include <colors>

public Plugin:myinfo = 
{
	name = "[CS:GO] Players Join Message",
	author = "Spy",
	description = "Message in the chat when a player enters your server.",
	version = "1.1",
	url = "https://forums.alliedmods.net"
};


public OnClientPutInServer(client)
{
	decl String:name[128];
	decl String:steamid[128];
	decl String:ip[128];
	decl String:country[128];
	
	GetClientName(client, name, sizeof(name));
	CPrintToChatAll("{darkred}[*] {default}Player: {green}%s", name);

	GetClientAuthString(client, steamid, sizeof(steamid));
	CPrintToChatAll("{darkred}[*] {default}SteamID: {green}%s", steamid);

	GetClientIP(client, ip, sizeof(ip), false);
	CPrintToChatAll("{darkred}[*] {default}IP: {green}%s", ip);

	if(GeoipCountry(ip, country, sizeof(country)))
	{
		CPrintToChatAll("{darkred}[*] {default}Country: {green}%s", country);
	}
	else
	{
		CPrintToChatAll("{darkred}[*] {default}Country: {green}Undefined.");
	}
}

public OnClientDisconnect(client)
{
	decl String:name[128];
	decl String:steamid[128];

	GetClientName(client, name, sizeof(name));
	GetClientAuthString(client, steamid, sizeof(steamid));

	CPrintToChatAll("{darkred}[*] {default}The player {green}%s {darkred}STEAMID: %s{default} desconected.", name, steamid);
}