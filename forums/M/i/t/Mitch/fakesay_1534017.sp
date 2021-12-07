#include <sourcemod>
#include <admin>
#include <colors>

#define VERSION "1.0.0.0"

public Plugin:myinfo =
{
	name = "[Any] Fakesay",
	author = "Mitch",
	description = "Safe version of sm_fakesay from funcommandsx",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1534017"
};

public OnPluginStart()
{
	CreateConVar("sm_fakesay_version", VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_fakesay", Command_Fakesay, ADMFLAG_BAN, "Makes a client say text.");
	LoadTranslations("common.phrases");
}

public Action:Command_Fakesay(client, args)
{
	if(args  != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakesay <#userid|name> <text>");
		return Plugin_Handled;
	}

	decl String:Target[64];
	decl String:text[128];

	GetCmdArg(1, Target, sizeof(Target));
	GetCmdArg(2, text, sizeof(text));

	new itarget = FindTarget(client, Target);
	if(itarget == -1)
	{
		ReplyToCommand(client, "Unable to find target");
		return Plugin_Handled;
	}
	CPrintToChatAllEx(itarget, "{teamcolor}%N{default} :  %s", itarget, text);
	LogAction(client, itarget, "%L made %L say %s ", client, itarget, text);
	return Plugin_Handled;
}			