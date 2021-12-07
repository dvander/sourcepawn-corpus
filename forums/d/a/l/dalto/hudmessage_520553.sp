/*
hudmessage.sp

Description:
	Allows an admin to send hud messages to players
	
Credits:
	Thanks to everyone in the scripting forum.  You guys have been super supportive of all my questions.

Versions:
	1.0
		* Initial Release
		
*/


#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "HUD Message",
	author = "AMP",
	description = "Allows an admin to send hud messages to players",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

// Global Variables
new Handle:g_CvarEnable = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_hud_message_version", PLUGIN_VERSION, "HUD Message Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarEnable = CreateConVar("sm_hud_message_enable", "1", "Enables the plugin");
}

// Once the configs have executed we register the admin commands if appropriate
public OnConfigsExecuted()
{
	if(GetConVarBool(g_CvarEnable))
	{
		RegAdminCmd("sm_phsay", CommandPHSay, ADMFLAG_CHAT);
		RegAdminCmd("sm_hudmessage", CommandHudMessage, ADMFLAG_CHAT);
	}
}

// Adapted from basechat
public Action:CommandPHSay(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_phsay <name or #userid> <message>");
		return Plugin_Handled;	
	}	
	
	// get the arguments and split them out, into arg and message
	decl String:text[192], String:arg[64], String:message[192];
	GetCmdArgString(text, sizeof(text));
	new len = BreakString(text, arg, sizeof(arg));
	BreakString(text[len], message, sizeof(message));
	
	// try to find a player to target
	new target = FindTarget(client, arg, true, false);
	if(target == -1)
	{
		ReplyToCommand(client, "sm_phsay didn't find anyone to send a message to");
		return Plugin_Handled;	
	}

	// send the message
	PrintHintText(target, message);

	return Plugin_Handled;	
}

public Action:CommandHudMessage(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hudmessage <steamid> <message>");
		return Plugin_Handled;	
	}	
	
	// parse the command string and populate targetId and message
	decl String:text[192], String:targetId[64], String:message[192];
	GetCmdArgString(text, sizeof(text));
	new len = BreakString(text, targetId, sizeof(targetId));
	BreakString(text[len], message, sizeof(message));
	
	// try to find a matching steamId
	decl String:steamId[30];
	new target = 0;
	for(new i = 1; i < GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientAuthString(i, steamId, sizeof(steamId));
			if(strcmp(steamId, targetId) == 0)
			{
				target = i;
				break;
			}
		}
	}
	
	// check to see if we found one
	if(!target)
	{
		ReplyToCommand(client, "sm_hudmessage couldn't find that steamid");
		return Plugin_Handled;	
	}
	
	// send the message
	PrintHintText(target, message);
	
	return Plugin_Handled;	
}