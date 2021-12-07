#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Interesting"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>


public Plugin myinfo = 
{
	name = "UserID",
	author = PLUGIN_AUTHOR,
	description = "Sets player's clan tag as their userID'",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/AAAAAAGGHHH/"
};

public void OnClientPostAdminCheck(int client)
{
	int ID = GetClientUserId(client);
	char userID[6];
	
	for(int i = 0; ID > 0; i++)
	{
		userID[i] = ID % 10;
		ID = ID / 10;
	}
	
	CS_SetClientClanTag(client, userID);
}