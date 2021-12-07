#include <sdktools>

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post)
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Music(client)
	PrintToChat(client, "[SM] Don't be a dumbass. Earn strange levels by yourself. Nobody likes cheaters :)")
	
	SetEntityHealth(client, 1000000)
	
	new userid = GetClientUserId(client);
	CreateTimer(30.0, SlayClient, userid)
}

public Action:SlayClient(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(client);
	ForcePlayerSuicide(client)
	PrintToChat(client, "[SM] Australian Justice Served!")
}

stock Music(client)
{
	if ( !IsClientInGame( client ) )
		return;
	
	new Handle:kv = CreateKeyValues( "data" );
	
	KvSetString( kv, "title", "Epic Sax Guy" );
	KvSetNum( kv, "type", MOTDPANEL_TYPE_URL );
	KvSetString( kv, "msg", "www.youtube.com/watch?v=kxopViU98Xo");
	
	ShowVGUIPanel( client, "info", kv, false );
	
	CloseHandle( kv );
}