#pragma semicolon 1

#include <sourcemod>
#include <colors>

new Handle:sm_Join_Message = INVALID_HANDLE;
new String:Message[128];
public Plugin:myinfo =
{
	name = "Welcome Plugin CSGO",
	author = "fat0nix",
	description = "This is my first plugin and it shows message if an player joins your server",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=187975"
};

public OnPluginStart()
{
	sm_Join_Message = CreateConVar("sm_join_message", "Welcome {name}[{steamid}][{ip}], to ", "Join Message", FCVAR_NOTIFY);
	AutoExecConfig(true, "onJoin");
	HookEvent("player_activate", Player_Activated, EventHookMode_Post);
}

public Action:Player_Activated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(4.0, Timer_Welcome, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Welcome(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		GetConVarString(sm_Join_Message, Message, sizeof(Message));
		new String:Name[128];
		new String:SteamID[128];
		new String:IP[128];
		new String:Count[128];
		GetClientName(client, Name, sizeof(Name));
		GetClientAuthString(client, SteamID, sizeof(SteamID));
		GetClientIP(client, IP, sizeof(IP));
		ReplaceString(Message, sizeof(Message), "{name}", Name, false);
		ReplaceString(Message, sizeof(Message), "{steamid}", SteamID, false);
		ReplaceString(Message, sizeof(Message), "{ip}", IP, false);
		CPrintToChat(client, Message, client);
	}
}