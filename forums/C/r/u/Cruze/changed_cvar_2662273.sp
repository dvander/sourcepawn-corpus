#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
	name		= "Changed cvar value",
	author	  	= "Cruze",
	description = "idk",
	version	 	= "1.0",
	url		 	= "http://steamcommunity.com/profiles/76561198132924835"
};

public void OnMapStart() 
{
	SetConVarInt(FindConVar("mp_damage_headshot_only"), 1);
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
		return;
	SendConVarValue(client, FindConVar("mp_damage_headshot_only"), "0");
}