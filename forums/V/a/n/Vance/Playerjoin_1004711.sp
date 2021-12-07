//#pragma semicolon 1

#include <sourcemod>
#include <topmenus>
#include <menus>
#include <timers>
 
public Plugin:myinfo =
{
	name = "Player Joined Notifier",
	author = "{[FIIK]}Vance",
	description = "Tells players when a new player has joined.",
	version = "1.0.0.0",
	url = "N/A"
};

public OnClientConnected(client)
{
	new String:name[64]
	GetClientName(client, name, sizeof(name))
	PrintToChatAll("%s has joined the game.", name)
}