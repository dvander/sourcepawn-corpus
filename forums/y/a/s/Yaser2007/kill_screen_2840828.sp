#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Kill Screen",
	author = "Yaser2007",
	version = "1.1",
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=Yaser2007&description=&search=1"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(attacker < 1 || attacker > MaxClients || attacker == victim || !IsClientInGame(attacker))
	{
		return Plugin_Continue;
	}

	FadeScreen(attacker, 100, 100, (0x0001|0x0010), {0, 0, 255, 75});

	return Plugin_Continue;
}

stock void FadeScreen(int client, int duration, int holdtime, int flags, int color[4])
{
	Handle message = StartMessageOne("Fade", client, 1);

	if(GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
	}

	EndMessage();
}