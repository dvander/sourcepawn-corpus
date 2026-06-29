
/*
	(CS:GO) In game respawn system, server bot_add_t, bot_add_ct commands start executed by player jointeam command! Bug
*/
public Plugin myinfo =
{
	name = "[CS:GO] bug fix - bot add jointeam",
	author = "Bacardi",
	description = "Stop server adding extra bots!",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=312256"
};

public void OnPluginStart()
{
	AddCommandListener(CommandListener, "bot_add_ct");
	AddCommandListener(CommandListener, "bot_add_t");
	AddCommandListener(CommandListener, "jointeam");
}

public Action CommandListener(int client, const char[] command, int argc)
{
	// CS:GO bug - in fast respawn system, player jointeam command will execute server commands bot_add_ct, bot_add_t
	static int jointeam_timestamp;

	// Collect all client commands in this code block
	if(0 < client <= MaxClients)
	{
		if(!StrEqual(command, "jointeam", false)) return Plugin_Continue;

		jointeam_timestamp = GetGameTickCount() + 1;

		return Plugin_Continue;
	}

	if(argc <= 0 && jointeam_timestamp == GetGameTickCount())
	{
		// block extra server commands bot_add_ct and bot_add_t
		return Plugin_Handled;
	}

	return Plugin_Continue;
}