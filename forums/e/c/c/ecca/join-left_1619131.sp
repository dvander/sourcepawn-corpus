#include <sourcemod>

#define PL_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Join - Left Messege",
	author = "EGood",
	description = "",
	version = PL_VERSION,
	url = ""
};

public OnPluginStart() 
{
	CreateConVar("sm_joinleft_enabled", "1", "enable plugin?");
}


public OnClientAuthorized(client, const String:auth[])
{
	PrintToChatAll("\x03Player: \x04%N \x03[\x04%s \x03] Join the game.", client, auth);
	LogError("%N", client)

}
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	PrintToChatAll("\x03Player: \x04%N \x03[\x04%s \x03] Left the game.", client, auth);
	LogError("%N", client)
	}

}