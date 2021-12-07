public Plugin:myinfo =
{
	name = "Fix Zmarket",
	author = "EmojiQ",
	description = "Start Zmarket when round_start",
	version = "1.0",
	url = "http://even4frags.ru/"
};

public OnPluginStart()
{
	HookEvent("round_start", round_start, EventHookMode_PostNoCopy);
}

public round_start(Handle:event, const String:name[], bool:silent)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			FakeClientCommand(i, "zmarket");
	}
}
