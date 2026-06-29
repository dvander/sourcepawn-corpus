#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Float:g_uLoc[3];

public Plugin:myinfo =
{
	name = "Simple Teleport",
	author = "Taco",
	description = "Teleports a user to a saved location.",
	version = "1.1",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_saveloc", Save_Loc, ADMFLAG_KICK, "saves location");
	RegAdminCmd("sm_tele", Teleport_User, ADMFLAG_KICK, "sm_tele <#userid|name>");
}

public Action:Save_Loc(client, args)
{
	GetClientAbsOrigin(client, g_uLoc);
	return Plugin_Handled;
}

public Action:Teleport_User(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_tele <#userid|name>");
		return Plugin_Handled;
	}

	decl String:Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));

	decl String:arg[65];
	new len = BreakString(Arguments, arg, sizeof(arg));

	new target = FindTarget(client, arg);
	if (target == -1)
	{
		return Plugin_Handled;
	}

	GetClientName(target, arg, sizeof(arg));

	if (len == -1)
	{
		/* Safely null terminate */
		len = 0;
		Arguments[0] = '\0';
	}

	ShowActivity(client, "teleported %s", arg);

	TeleportEntity(target, g_uLoc, NULL_VECTOR, NULL_VECTOR);

	return Plugin_Handled;
}
