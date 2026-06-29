#include <sourcemod>

new Handle:Msg_Enable = INVALID_HANDLE;
new Handle:AMsg_Enable = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Simple Connect Announce",
	author = "Marcus",
	description = "Replaces the default connect and disconnect messages with new ones.",
	version = "1.0.0",
	url = "http://snbx.info"
}
public OnPluginStart()
{
	Msg_Enable = CreateConVar("sm_show_connect", "1", "This enables or disables custom connection messages for players.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	AMsg_Enable = CreateConVar("sm_show_a_connect", "1", "This enables or disables custom connection messages for admins.", FCVAR_PLUGIN|FCVAR_NOTIFY);

	HookEvent("player_connect", Event_Connect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_Disconnect, EventHookMode_Pre);
	HookEvent("player_team", Event_Team, EventHookMode_Pre);
}
public OnClientPostAdminCheck(client) 
{
	new AdminId:id = GetUserAdmin(client);
	if (id != INVALID_ADMIN_ID)
	{
		if (GetConVarInt(AMsg_Enable))
		{
			decl String:authid[32];
			GetClientAuthString(client, authid, 32);
			PrintToChatAll("\x07DC6900[Admin]\x01 \x07B2DFEE%N\x01 has joined the server: \x070069DC[%s]\x01", client, authid);
		}
	} else
	{
		if (GetConVarInt(Msg_Enable))
		{
			decl String:authid[32];
			GetClientAuthString(client, authid, 32); 
			PrintToChatAll("\x07B2DFEE%N\x01 has joined the server: \x070069DC[%s]\x01", client, authid);
		}
	}
	return true;
}
public Action:Event_Connect(Handle:event, const String:name[], bool:bDontBroadcast)
{
	SetEventBroadcast(event, true);
	return Plugin_Handled;
}
public Action:Event_Disconnect(Handle:event, const String:name[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:szAuthId[32];
	GetClientAuthString(client, szAuthId, 32);
	PrintToChatAll("\x07B2DFEE%N\x01 has left the server: \x070069DC[%s]\x01", client, szAuthId);
	SetEventBroadcast(event, true);
	return Plugin_Handled;
}
public Action:Event_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetEventBroadcast(event, true);
	return Plugin_Handled;
}