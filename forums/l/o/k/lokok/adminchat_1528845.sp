/**
 * =============================================================================
 * Admin Chat Communication Plugin
 * Implements chat communication among admins.
 * You can chat with admins using a special character like '@<message>' when broadcasting a message.
 * This plugin offers the same possibility '$<message>' but only the admins will be able to see it.
 * You need colors.inc in scripting/include to compile it. You can get it here
 * http://forums.alliedmods.net/showthread.php?t=96831
 * =============================================================================
 */

#pragma semicolon 1

#include <sourcemod>
#include <colors>
#define PLUGIN_VERSION "1"

public Plugin:myinfo = 
{
	name = "Admin Chat",
	author = "Am2feel",
	description = "Communication among Admins by Chat",
	version = PLUGIN_VERSION,
	url = "http://cs.apeople.org/"
};

#define CHAT_SYMBOL '$'
#define CHAT_SYMBOL2 ';'
#define FCVAR_DONTRECORD        (1<<17)    /**< Don't record these command in demo files. */
new bool:g_DoColor = true;
new Handle:g_Cvar_AdminChatmode = INVALID_HANDLE;
new Handle:g_Cvar_AdminChatColorized = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("say", Command_SayChat);
	CreateConVar("sm_adminchat_version", PLUGIN_VERSION, "Adminchat Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_AdminChatmode = CreateConVar("sm_adminchat_mode", "1", "Allows players to send messages to admin chat by chat ($, ;).", 0, true, 0.0, true, 1.0);
	g_Cvar_AdminChatColorized = CreateConVar("sm_adminchat_colorized", "1", "Enable new Colorized Admin Chat (default) or keep it classical.", 0, true, 0.0, true, 1.0);
	AutoExecConfig(true, "adminchat");
	//g_Cvar_Chatmode = FindConVar("sm_chat_mode");	
	decl String:modname[64];
	GetGameFolderName(modname, sizeof(modname));

	if (strcmp(modname, "hl2mp") == 0)
	{
		g_DoColor = false;
	}

}

public Action:Command_SayChat(client, args)
{	
	decl String:text[192];
	if (IsChatTrigger() || GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	new startidx;
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if ((text[startidx] != CHAT_SYMBOL) && (text[startidx] != CHAT_SYMBOL2))
		return Plugin_Continue;
	else if ((text[startidx] == CHAT_SYMBOL) || (text[startidx] == CHAT_SYMBOL2))
	{
		decl String:message[192];
		strcopy(message, 192, text[startidx+1]);
		decl String:name[64];
		GetClientName(client, name, sizeof(name));
		if (!CheckCommandAccess(client, "sm_chat", ADMFLAG_CHAT) && GetConVarBool(g_Cvar_AdminChatmode))
		{
			g_DoColor = true;
			SendChatToAdmins(client, message);
			g_DoColor = false;
			LogAction(client, -1, "%L triggered sm_chat (chat version) - client triggered (text %s)", client, message);			
		}
		else if (CheckCommandAccess(client, "sm_chat", ADMFLAG_CHAT)) // sm_chat alias
		{
			SendChatToAdmins(client, message);
			LogAction(client, -1, "%L triggered sm_chat (chat version) (text %s)", client, message);
		}
	}
	else
		return Plugin_Continue;
	return Plugin_Handled;	
}

public Action:Command_SayAdmin(client, args)
{
	if (!CheckCommandAccess(client, "sm_chat", ADMFLAG_CHAT) && !GetConVarBool(g_Cvar_AdminChatmode))
	{
		return Plugin_Continue;	
	}
	
	decl String:text[192];
	if (IsChatTrigger() || GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	new startidx;
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if ((text[startidx] != CHAT_SYMBOL) && (text[startidx] != CHAT_SYMBOL2))
		return Plugin_Continue;
	
	decl String:message[192];
	strcopy(message, 192, text[startidx+1]);

	SendChatToAdmins(client, message);
	LogAction(client, -1, "%L triggered sm_chat (text %s)", client, message);
	
	return Plugin_Handled;	
}

SendChatToAdmins(from, String:message[])
{
	new fromAdmin = CheckCommandAccess(from, "sm_chat", ADMFLAG_CHAT);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (from == i || CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT)))
		{
			if (GetConVarBool(g_Cvar_AdminChatColorized))
			{
				CPrintToChatEx(i, from, "{green}(%sADMINS) %N: {teamcolor}%s{default}", fromAdmin ? "" : "TO ", from, message);
				// possible color values are: {default} or {green} or {olive} or [({lightgreen} or {red} or {blue}) XOR {teamcolor}]
			}
			else if (g_DoColor) 
			{
				PrintToChat(i, "\x04(%sADMINS) %N: \x01%s", fromAdmin ? "" : "TO ", from, message);
			}
			else
			{
				PrintToChat(i, "(%sADMINS) %N: %s", fromAdmin ? "" : "TO ", from, message);
			}
		}	
	}
}