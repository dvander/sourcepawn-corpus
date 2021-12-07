#pragma semicolon 1

#include <sourcemod>

#define PLUG_VER	"1.0.0"

public Plugin myinfo =
{
	name = "Fake Connect/Disconnect Messages",
	author = "aIM",
	description = "Prints fake connection and disconnection messages to chat.",
	version = PLUG_VER,
	url = ""
};

public OnPluginStart()
{
	RegAdminCmd("sm_fakeconnect", Cmd_Connect, ADMFLAG_CHEATS, "Prints a fake connection message.");
	RegAdminCmd("sm_fakedisconnect", Cmd_Disconnect, ADMFLAG_CHEATS, "Prints a fake disconnection message.");
	RegAdminCmd("sm_fakedisconnect2", Cmd_Disconnect2, ADMFLAG_CHEATS, "Prints a fake disconnection message without networking a real client.");
}

public Action Cmd_Connect (client, args)
{
	if (args < 1)
	{
		PrintToChat(client, "[FCDM] Usage: sm_fakeconnect <name>");
		return Plugin_Handled;
	}
	decl String:Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));
	
	decl String:arg[65];
	BreakString(Arguments, arg, sizeof(arg));
	
	PrintToChatAll("%s has joined the game", arg);
	return Plugin_Handled;
}

public Action Cmd_Disconnect (client, args)
{
	if (args < 2)
	{
		PrintToChat(client, "[FCDM] Usage: sm_fakedisconnect <player> <reason>");
		return Plugin_Handled;
	}
	decl len;
	decl String:Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));
	
	decl String:arg[65];
	len = BreakString(Arguments, arg, sizeof(arg));
	new target = FindTarget(client, arg, true, false);
	
	PrintToChatAll("%N left the game (%s)", target, Arguments[len]);
	return Plugin_Handled;
}

public Action Cmd_Disconnect2 (client, args)
{
	if (args < 2)
	{
		PrintToChat(client, "[FCDM] Usage: sm_fakedisconnect2 <name> <reason>");
		return Plugin_Handled;
	}
	decl len;
	decl String:Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));
	
	decl String:arg[65];
	len = BreakString(Arguments, arg, sizeof(arg));
	
	PrintToChatAll("%s left the game (%s)", arg, Arguments[len]);
	return Plugin_Handled;
}