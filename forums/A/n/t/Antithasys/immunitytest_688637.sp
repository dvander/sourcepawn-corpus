#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"
#define MAX_STRING_LEN 255

public Plugin:myinfo =
{
	name = "Immunity Test",
	author = "Antithasys",
	description = "Test immunity code",
	version = PLUGIN_VERSION,
	url = "http://www.mytf2.com"
}

public OnPluginStart()
{
	RegConsoleCmd("doihaveimmunity", Command_ImmunityCheck, "Returns if you are immune or not");
}

public Action:Command_ImmunityCheck(client, args)
{
	if (client == 0) {
		ReplyToCommand(client, "Command must be run at the player level");
		return Plugin_Handled;
	}
	decl String:flags[MAX_STRING_LEN];
	flags = "a";
	if (has_flags(client, flags))
		ReplyToCommand(client, "You are immune");
	else
		ReplyToCommand(client, "You are NOT immune");
	return Plugin_Handled;
}

stock has_flags(id, const String:flags[])
{
    new ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(id) & ibFlags) == ibFlags) {
		return true;
	}
	if (GetUserFlagBits(id) & ADMFLAG_ROOT) {
		return true;
	}
	return false;
}