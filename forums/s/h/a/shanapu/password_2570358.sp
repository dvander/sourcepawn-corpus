#include <sourcemod>

public void OnPluginStart()
{
	RegAdminCmd("sm_password", Command_Pass, ADMFLAG_BAN);
	RegAdminCmd("sm_pw", Command_Pass, ADMFLAG_BAN);
	RegAdminCmd("sm_removepw", Command_NoPass, ADMFLAG_BAN);
}

public Action Command_Pass(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_password <password>");

		return Plugin_Handled;
	}

	char sBuffer[32];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));

	ServerCommand("sv_password %s", sBuffer);
	PrintToChatAll("Server has been locked with password.");

	return Plugin_Handled;
}

public Action Command_NoPass(int client, int args)
{
	ServerCommand("sv_password \"\"");
	PrintToChatAll("Server has been unlocked. (no password)");

	return Plugin_Handled;
}

