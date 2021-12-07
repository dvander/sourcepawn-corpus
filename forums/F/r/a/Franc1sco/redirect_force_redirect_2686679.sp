#include <sourcemod>
#include <redirect>
#include <redirect_core>

public Plugin:myinfo =
{
    name = "Server Redirect: Force Redirect on CS:GO",
    author = "Franc1sco Franug",
    description = "Server redirection: Force Redirect on CS:GO",
    version = "1.0",
    url = "http://steamcommunity.com/id/franug"
};


public OnAskClientConnect(client, String:ip[], String:password[])
{
	char ips[2][64];
	ExplodeString(ip, ":", ips, sizeof(ips), sizeof(ips[]));
	
	char sIPv4[4][4];
	ExplodeString(ips[0], ".", sIPv4, sizeof(sIPv4), sizeof(sIPv4[]));
	int iIP = GetIP32FromIPv4(sIPv4);
	
	RedirectClientOnServer(client,iIP, StringToInt(ips[1]));
}