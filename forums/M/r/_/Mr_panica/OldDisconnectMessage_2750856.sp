public void OnPluginStart()
{
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	char reason[64];
	
	GetEventString(event, "reason", reason, sizeof(reason));
	PrintToChatAll("%N left the game (%s)", client, reason);
	SetEventBroadcast(event, true);

	return Plugin_Continue;
}