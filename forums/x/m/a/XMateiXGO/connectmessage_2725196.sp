#include <sourcemod>
#include <colors>
#include <geoip>
#pragma tabsize 0

public Plugin:myinfo = 
{
name = "Connect/Disconnect Message",
author = "X Matei X",
description = "A simple connect/disconnect message for players.",
version = "1.0",
url = "forums.alliedmods.net",
};


public OnClientPutInServer(client)
{
	new String:name[99], String:IP[99], String:Country[99];

	GetClientName(client, name, sizeof(name));
	GetClientIP(client, IP, sizeof(IP), true);
    if(!GeoipCountry(IP, Country, sizeof Country))
    {
		Country = "Unknown Country";
    }  
	CPrintToChatAll("★ {green}CSGO {default}➜ {purple}%s {default}connected from {green}(%s).", name, Country);

}

public OnClientDisconnect(client)
{
	new String:name[99], String:IP[99], String:Country[99];

	GetClientName(client, name, sizeof(name));
	GetClientIP(client, IP, sizeof(IP), true);
    if(!GeoipCountry(IP, Country, sizeof Country))
    {
        Country = "Unknown Country";
    } 
	CPrintToChatAll("★ {green}CSGO {default}➜ {purple}%s {default}disconnected from {green}(%s).", name, Country);
}