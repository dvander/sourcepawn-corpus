#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ANY] Admin and Player Command Test",
	author = "Psyk0tik (Crasher_3637) and Tobi2104",
	description = "Test commands",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=308932"
};

public void OnPluginStart()
{
	// Admin command
	// void RegAdminCmd(const char[] cmd, ConCmd callback, int adminflags, const char[] description, const char[] group, int flags)
	RegAdminCmd("sm_admintest", cmdAdminTest, ADMFLAG_GENERIC, "Test admin command.");

	// Player command
	// void RegConsoleCmd(const char[] cmd, ConCmd callback, const char[] description, int flags)
	RegConsoleCmd("sm_cmdtest", cmdPlayerTest, "Test player command.");
}

public Action cmdAdminTest(int client, int args)
{
	// Check if admin is a valid in-game client.
	if (!IsClientInGame(client) || client == 0)
	{
		ReplyToCommand(client, "[SM] You must be in-game to use this command.");
		return Plugin_Handled;
	}
	PrintToChat(client, "[SM] Admin test command works.");
	return Plugin_Handled;
}

public Action cmdPlayerTest(int client, int args)
{
	// Check if player is a valid in-game client.
	if (!IsClientInGame(client) || client == 0)
	{
		ReplyToCommand(client, "[SM] You must be in-game to use this command.");
		return Plugin_Handled;
	}
	PrintToChat(client, "[SM] Player test command works.");
	return Plugin_Handled;
}