public Plugin:myinfo =
{
	name = "Anti Client Crash Fix For Legacy CSGO",
	author = "backwards",
	description = "...",
	version = "1.0",
	url = "http://www.steamcommunity.com/id/mypassword"
}

public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("SendPlayerItemFound"), Hook_ItemFound, true);
}

public Action Hook_ItemFound(UserMsg msg_id, any msg, const int[] players, int playersNum, bool reliable, bool init)
{
	return Plugin_Handled;
}