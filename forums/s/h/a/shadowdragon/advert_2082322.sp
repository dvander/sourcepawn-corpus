#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <morecolors>

new Handle:h_spawn_Text = INVALID_HANDLE;

#define PLUGIN_VERSION "1";

public Plugin:myinfo =
{
	name = "Adverts",
	author = "ShadowDragon",
};

public OnPluginStart()
{
	h_spawn_Text = CreateConVar("sm_spawn_message", "", "Spawn message(Colors: {red} {blue} {green} {pink} {gold} {white} {black} etc");
	HookEvent("player_spawn",SpawnEvent);
	AutoExecConfig(true, "kaos-advert");
}

public OnClientPutInServer(client)
{
	decl String:name_[64]
	GetClientName(client, name_, sizeof(name_))
	CPrintToChat(client, "{red}Player {white}%s {red}has joined", name_)
}

public Action:SpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);
	new String:buffer[900];
	GetConVarString(h_spawn_Text, buffer, sizeof(buffer));
	CPrintToChat(client, "%s", buffer)
}
	
	
