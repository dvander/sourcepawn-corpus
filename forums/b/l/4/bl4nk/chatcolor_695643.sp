#include <sourcemod>

public Plugin:myinfo =
{
  name = "chat color tester",
  author = "bl4nk",
  description = "used to test chat colors",
  version = "1.0.0",
  url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_chatcolor", Command_ChatColor, ADMFLAG_CHEATS, "sm_chatcolor");
}

public Action:Command_ChatColor(client, args)
{
	PrintToChat(client, "\x01This is color: 01");
	PrintToChat(client, "\x02This is color: 02");
	PrintToChat(client, "\x03This is color: 03");
	PrintToChat(client, "\x04This is color: 04");
	PrintToChat(client, "\x05This is color: 05");
	PrintToChat(client, "\x06This is color: 06");

	return Plugin_Handled;
}