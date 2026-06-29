#include <sourcemod>

bool bChatDisabled;

public Plugin myinfo =
{
	name = "toggle chat",
	author = "91346706501435897134",
	description = "allows admins to disable/enable the chat",
	version = "1.2",
}

public void OnPluginStart()
{
	RegAdminCmd("sm_togglechat", Command_ToggleChat, ADMFLAG_CHAT, "disable/enable the chat");
}

public Action Command_ToggleChat(int client, int args)
{
	if (bChatDisabled)
	{
		bChatDisabled = false;

		ReplyToCommand(client, ">> Chat is now enabled.");
		PrintToChatAll(">> %N enabled the chat!", client);
	}
	else
	{
		bChatDisabled = true;

		ReplyToCommand(client, ">> Chat is now disabled.");
		PrintToChatAll(">> %N disabled the chat!", client);
	}

	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	if (client != 0 && (StrEqual(command, "say") || StrEqual(command, "say_team")) && bChatDisabled)
	{
		PrintToChat(client, ">> Chat is currently disabled!");

		return Plugin_Handled;
	}

	return Plugin_Continue;
}