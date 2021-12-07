/**
 * basechat.sp
 * Implements basic chat commands
 */

#include <sourcemod>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Basic Chat",
	author = "ferret",
	description = "Basic Chat Commands",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("common.cfg");
	LoadTranslations("plugin.basecommands.cfg");

	RegConsoleCmd("say", Command_SayChat);
	RegConsoleCmd("say_team", Command_SayAdmin);		
	RegAdminCmd("sm_say", Command_SmSay, ADMFLAG_CHAT, "sm_say <message> - sends message to all players");
	RegAdminCmd("sm_chat", Command_SmChat, ADMFLAG_CHAT, "sm_chat <message> - sends message to admins");
	RegAdminCmd("sm_psay", Command_SmPsay, ADMFLAG_CHAT, "sm_psay <name or #userid> <message> - sends private message");
}

public Action:Command_SayChat(client, args)
{
	new String:authid[64];
	GetClientAuthString(client, authid, sizeof(authid));
	new AdminId:aid = FindAdminByIdentity(AUTHMETHOD_STEAM, authid);
	if(aid == INVALID_ADMIN_ID)
	{
		LogMessage("Invalid_admin_id");
		return Plugin_Continue;
	}
	else if (GetAdminFlag(aid, Admin_Chat, Access_Effective))
	{
		LogMessage("no admin_chat flag");
		return Plugin_Continue;	
	}
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	text[strlen(text)-1] = '\0';
	
	if (text[0] != '@')
		return Plugin_Continue;
	
	decl String:message[192];
	strcopy(message, 192, text[2]);
	
	new String:name[64];
	GetClientName(client, name, sizeof(name));
	
	SayToAll(name, message);
	LogMessage("Chat: %L triggered sm_say (text %s)", client, message);
	
	return Plugin_Handled;	
}

public Action:Command_SayAdmin(client, args)
{
	new String:authid[64];
	GetClientAuthString(client, authid, sizeof(authid));
	new AdminId:aid = FindAdminByIdentity(AUTHMETHOD_STEAM, authid);
	if(aid == INVALID_ADMIN_ID)
		return Plugin_Continue;
	else if (GetAdminFlag(aid, Admin_Chat, Access_Effective))
		return Plugin_Continue;	
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	text[strlen(text)-1] = '\0';
	
	if (text[0] != '@')
		return Plugin_Continue;
	
	decl String:message[192];
	strcopy(message, 192, text[2]);

	new String:name[64];
	GetClientName(client, name, sizeof(name));
	
	SayToAdmins(name, message);
	LogMessage("Chat: %L triggered sm_chat (text %s)", client, message);
	
	return Plugin_Handled;	
}

public Action:Command_SmSay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_say <message>");
		return Plugin_Handled;	
	}
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));

	new String:name[64];
	GetClientName(client, name, sizeof(name));
	
	SayToAll(name, text);
	LogMessage("Chat: %L triggered sm_say (text %s)", client, text);
	
	return Plugin_Handled;		
}

public Action:Command_SmChat(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_chat <message>");
		return Plugin_Handled;	
	}	
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));

	new String:name[64];
	GetClientName(client, name, sizeof(name));
	
	SayToAdmins(name, text);
	LogMessage("Chat: %L triggered sm_chat (text %s)", client, text);
	
	return Plugin_Handled;	
}

public Action:Command_SmPsay(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_psay <name or #userid> <message>");
		return Plugin_Handled;	
	}	
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	new String:target[64], String:message[192];

	new len = BreakString(text, target, sizeof(target));
	BreakString(text[len], message, sizeof(message));
	
	new clients[2];
	new numClients = SearchForClients(target, clients, 2);
	
	if (numClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (numClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, clients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	new String:name[64], String:name2[64];
	GetClientName(client, name, sizeof(name));
	GetClientName(clients[0], name2, sizeof(name2));
	
	PrintToChat(client, "(%s) %s: %s", name2, name, message);
	PrintToChat(clients[0], "(%s) %s: %s", name2, name, message);

	LogMessage("Chat: %L triggered sm_psay to %L (text %s)", client, clients[0], message);
	
	return Plugin_Handled;	
}

public SayToAll(String:name[], String:message[])
{
	PrintToChatAll("(ALL) %s: %s", name, message);
}

public SayToAdmins(String:name[], String:message[])
{
	new iMaxClients = GetMaxClients();
	
	for (new i = 1; i <= iMaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			new String:authid[64];
			GetClientAuthString(i, authid, sizeof(authid));
			new AdminId:aid = FindAdminByIdentity(AUTHMETHOD_STEAM, authid);
			if(aid != INVALID_ADMIN_ID && GetAdminFlag(aid, Admin_Chat, Access_Effective))
			{
				PrintToChat(i,"(ADMINS) %s: %s", name, message);
			}
		}	
	}
}