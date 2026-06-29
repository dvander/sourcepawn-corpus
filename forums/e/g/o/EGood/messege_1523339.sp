#include <sourcemod>

#define PLUGIN_VERSION "1.1"
#define ST_FLAG FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD

public Plugin:myinfo = 
{
	name = "Connect & Disconnect Messege",
	author = "EGood",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart() {
	CreateConVar( "sm_messege_version", PLUGIN_VERSION, "Connect Messege Version", ST_FLAG );
	
}


public OnClientAuthorized(client, const String:auth[])
{
	PrintToChatAll("\x03Player: \x04%N \x03SteamID: \x04%s \x03Join the game.", client, auth);
	LogError("%N", client)

}
public OnClientDisconnect(client)
{
if(IsClientInGame(client))
{
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	PrintToChatAll("\x03Player: \x04%N \x03SteamID: \x04%s \x03Left the game.", client, auth);
	LogError("%N", client)
}

}