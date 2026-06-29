#include <sourcemod>

public Plugin myinfo =
{
	name = "Chat Wheel Blocker",
	author = "MINFAS, Sples1",
	description = "Block things from chatwheel menu introduced in broken fang operation",
	version = "1.1",
	url = "http://steamcommunity.com/id/minfasdj"
};

public void OnPluginStart()
{
	HookUserMessage(GetUserMessageId("RadioText"), BlockRadio, true);

	AddCommandListener(Command_Ping, "chatwheel_ping");
	AddCommandListener(Command_Ping, "player_ping"); //thanks Sples1
}

public Action Command_Ping(int client, const char[] command, int args)
{
	return Plugin_Handled;
}

public Action BlockRadio(UserMsg msg_id, Protobuf bf, const int[] players, int playersNum, bool reliable, bool init)
{
	char buffer[64];
	PbReadString(bf, "params", buffer, sizeof(buffer), 0);

	if (StrContains(buffer, "#Chatwheel_"))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}