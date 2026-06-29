#pragma semicolon 1

public Plugin myinfo =
{
	name = "Chatwheel Blocker",
	author = "Sples1",
	description = "Block Chatwheel features",
	version = "1.2"
};

public void OnPluginStart()
{
	AddCommandListener(Command_Block, "chatwheel_ping");
	AddCommandListener(Command_Block, "player_ping");
	AddCommandListener(Command_Block, "playerradio");
	AddCommandListener(Command_Block, "playerchatwheel");
}

public Action Command_Block(int client, const char[] command, int args)
{
	return Plugin_Handled;
}