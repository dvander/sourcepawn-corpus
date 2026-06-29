public Plugin:myinfo =
{
	name = "No Bots",
	author = "Neuro Toxin",
	description = "Stops those pesky rouge bots",
	version = "1.0",
	url = "",
}

new Handle:cvar_bot_quota = INVALID_HANDLE;

public OnPluginStart()
{
	cvar_bot_quota = FindConVar("bot_quota");

	if (cvar_bot_quota == INVALID_HANDLE)
		LogError("Unable to find convar: cvar_bot_quota");
}

public OnClientConnected(client)
{
	if (cvar_bot_quota != INVALID_HANDLE)
	{
		new bot_quota = GetConVarInt(cvar_bot_quota);
		
		if (bot_quota > 0)
		{
			LogError("Bot quota detected: bot_quota %d", bot_quota);
			SetConVarInt(cvar_bot_quota, 0);		
		}
	}
	
	if (!IsFakeClient(client))
		return;

	new String:name[48]
	if(!GetClientName(client, name, sizeof(name)))
		return;
	
	LogError("Kicking bot %s", name);
	ServerCommand("bot_kick %s", name);
}