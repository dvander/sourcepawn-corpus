#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.1"
#define ST_FLAG FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD

public Plugin:myinfo = 
{
	name = "Connect & Disconnect Messege",
	author = "EGood & DJ.TechnoWolf",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart() {
	CreateConVar( "sm_messege_version", PLUGIN_VERSION, "Connect Messege Version", ST_FLAG );
	
}


public OnClientAuthorized(client, const String:auth[])
{
	CPrintToChatAll("{green}Player: {lightgreen}%N {green}SteamID: {lightgreen}%s {green}Join the game.", client, auth);
	LogError("%N", client)

}
public OnClientDisconnect(client)
{
if(IsClientInGame(client))
{
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	CPrintToChatAll("{green}Player: {lightgreen}%N {green}SteamID: {lightgreen}%s {green}Left the game.", client, auth);
	LogError("%N", client)
}

}