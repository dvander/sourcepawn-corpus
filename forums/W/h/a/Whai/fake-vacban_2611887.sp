#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.00"

public Plugin myinfo =
{
	name = "Fake Vac Ban",
	author = "Whai",
	description = "Kick Someone with the VAC ban reason.",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	RegAdminCmd("sm_fakevac", Cmd_fakevac, ADMFLAG_KICK, "Kick a player with vac ban reason.");
	RegAdminCmd("sm_fakevac2", Cmd_fakevac2, ADMFLAG_CHAT, "Prints a fake vac ban message with custom player name.");
	LoadTranslations("common.phrases");
}

public Action Cmd_fakevac (client, args)
{
	if (args < 1)
	{
		new String:name[32];
		GetClientName(client, name, sizeof(name));
	
		KickClient(client, "%s", "VAC banned from secure server", name);
		return Plugin_Handled;
	
	}
	if (args == 1)
	{
		new String:arg1[64];
		GetCmdArg(1, arg1, sizeof(arg1));
		new target = FindTarget(client, arg1, true, false);
		if (target == -1)
		{
			return Plugin_Handled;
		}
 
		KickClient(target, "%s", "VAC banned from secure server", target);
		return Plugin_Handled;
	}
	if (args > 1)
	{
		ReplyToCommand(client, "[Fake-VacBan] Usage: sm_fakevac <player>");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action Cmd_fakevac2 (client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[Fake-VacBan] Usage: sm_fakevac2 <name>");
		return Plugin_Handled;
	}
	if (args == 1)
	{
		decl String:Arguments[256];
		GetCmdArgString(Arguments, sizeof(Arguments));
	
	
		PrintToChatAll("%s left the game (VAC banned from secure server)", Arguments);
	}
	return Plugin_Handled;
}