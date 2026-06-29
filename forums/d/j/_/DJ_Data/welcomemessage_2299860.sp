#include sourcemod

stock bool:hasBeenWelcomed[MAXPLAYERS + 1] = false; 

public Plugin:myinfo =
{
	name = "test",
	author = "test",
	description = "test",
	version = "0.01",
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(3.0, Delay, client); 
}

public Action:Delay(Handle:timer, any:client)
{
	if(!hasBeenWelcomed[client] && IsClientInGame(client))
	{
		hasBeenWelcomed[client] = true;
		PrintToChat(client, "\x01*\x04##################\n## Welcome %N ##\nRead our rules and glhf\n##################", client);
	}
}