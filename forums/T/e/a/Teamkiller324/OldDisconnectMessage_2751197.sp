public	Plugin	myinfo	=	{
	name		=	"[TF2] Old Disconnect Message",
	author		=	"Mr_panica",
	description	=	"Returns the reason player left the server in the old way",
	version		=	"1.01",
	url			=	"https://forums.alliedmods.net/showthread.php?t=333176"
}

public void OnPluginStart()	{
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)	{
	event.BroadcastDisabled = true;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client))	{
		char reason[256];
		event.GetString("reason", reason, sizeof(reason));
		PrintToChatAll("%N left the game (%s)", client, reason);
	}
	return Plugin_Continue;
}

/**
 *	Makes sure the client is valid so it doesn't spit out errors at times
 */
bool IsValidClient(int client)	{
	if(client == 0)
		return	false;
	if(client == -1)
		return	false;
	if(client < 1 || client > MaxClients)
		return	false;
	if(!IsClientConnected(client))
		return	false;
	if(IsClientReplay(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	return	true;
}