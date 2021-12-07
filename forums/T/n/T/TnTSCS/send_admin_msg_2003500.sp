/*
* Taken from basechat.sp and modified slightly to allow say chat with chat symbol from non-admins to send msg to admins.
* 
*/

#pragma semicolon 1

#include <sourcemod>

#define CHAT_SYMBOL '@'

new Handle:g_Cvar_Chatmode = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	g_Cvar_Chatmode = FindConVar("sm_chat_mode");
	AddCommandListener(Command_SayChat, "say");
}

public Action:Command_SayChat(client, const String:command[], argc)
{
	if (IsChatTrigger() || CheckCommandAccess(client, "sm_chat", ADMFLAG_CHAT) || 
		client < 1 || client > MaxClients || !GetConVarBool(g_Cvar_Chatmode))
	{
		return Plugin_Continue;
	}
	
	new String:text[192];
	
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	new startidx;
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if (text[startidx] != CHAT_SYMBOL)
	{
		return Plugin_Continue;
	}
	
	new String:message[192];
	strcopy(message, 192, text[startidx+1]);
	
	SendChatToAdmins(client, message);
	LogAction(client, -1, "\"%L\" triggered sm_chat (text %s)", client, message);
	
	return Plugin_Handled;
}

SendChatToAdmins(from, String:message[])
{
	new fromAdmin = CheckCommandAccess(from, "sm_chat", ADMFLAG_CHAT);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (from == i || CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT)))
		{
			PrintToChat(i, "\x04(%sADMINS) %N: \x01%s", fromAdmin ? "" : "TO ", from, message);
		}	
	}
}