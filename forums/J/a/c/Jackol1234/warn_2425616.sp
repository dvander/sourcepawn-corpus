#include <sourcemod>
#include <colors>

#pragma semicolon 1

#define PLUGIN_VERSION "0.3"

public Plugin myinfo =
{
	name = "SM Warnings",
	author = "DeweY",
	version = PLUGIN_VERSION,
	description = "Allows admins to give clients warnings.",
	url = "https://forums.alliedmods.net/member.php?u=259936"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_warn", Command_Warn, ADMFLAG_GENERIC, "Use to give clients a warning.");
}

public Action Command_Warn(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_warn <name|#userid> <warning message>");
		return;
	}

	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1);
	if (target == -1)
	{
		return;
	}

	char buffer[100];
	char reason[128];
	if (args >= 2)
	{
		GetCmdArg(2, reason, 128);
		for (int i = 3; i <= args; i++)
		{
			GetCmdArg(i, buffer, 100);
			Format(reason, 128, "%s %s", reason, buffer);
		}
	}

	CPrintToChat(target, "{darkred}You have been warned for:{default} %s", reason);

	for (int i = 1; i < MaxClients; i++)
	{
		if (GetAdminFlag(GetUserAdmin(i), Admin_Generic))
		{
			CPrintToChat(i, "{darkblue}%N warned %N for:{default} %s", client, target, reason);
		}
	}
}

/*------Change Log-------
* 0.1 - Initial release.
* 0.2 - Added prefix to warning and announcment to other admins.
* 0.3 - Added color into the plugin.
* 0.3 - Fixed index's and PrintToChat -> CPrintToChat.
*/