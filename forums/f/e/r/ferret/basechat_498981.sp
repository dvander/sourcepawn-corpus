/**
 * basechat.sp
 * Implements basic chat commands
 *
 * Changelog:
 *
 * Version 1.5
 * - sm_tsay has a color parameter now.
 * - sm_psay now prefixed in green, and with Private:
 * - SendDialogToAll() fixed
 * - Abandoned Hungarian notation
 * - RCON should now be able to use commands.
 * - New say trigger: @@<player> <message> does sm_psay
 * - New say trigger: @@@<message> does sm_csay 
 * - New cvar: sm_chat_mode - Controls whether players can use say_team @<message>. Default on. They still cannot read it though.
 * - New cvar: sm_psay_mode - Allows players to use the psay alias "@@<player> <message>". Default is off.
 * - New command: sm_msay
 *
 * Version 1.4.3 (July 4th)
 * - Final tsay fix 
 * - Final GetUserAdmin fix. 
 *
 * Version 1.4.2 (July 3rd)
 * - Lol. Now using GetUserAdmin... 
 *
 * Version 1.4.1 (July 2nd)
 * - Forgot to change one function to use NAME/IP authmethod stock. 
 *
 * Version 1.4 (July 2nd)
 * - Add sm_tsay 
 * - sm_say and sm_chat now prefixed in green. 
 * - NAME and IP authmethods should now work with chat triggers. 
 *
 * Version 1.3 (June 29th)
 * - Minor changes to conform to plugin submission rules 
 * - Added sm_basevotes_version Cvar 
 *
 */

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.5"

public Plugin:myinfo = 
{
	name = "Basic Chat",
	author = "ferret",
	description = "Basic Chat Commands",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new String:g_ColorNames[13][32] = {"White", "Red", "Green", "Blue", "Yellow", "Purple", "Cyan", "Orange", "Pink", "Olive", "Lime", "Violet", "Lightblue"};
new g_Colors[13][3] = {{255,255,255},{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255},{0,255,255},{255,128,0},{255,0,128},{128,255,0},{0,255,128},{128,0,255},{0,128,255}};

new Handle:g_Cvar_Chatmode = INVALID_HANDLE;
new Handle:g_Cvar_Psaymode = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.basecommands");

	CreateConVar("sm_basechat_version", PLUGIN_VERSION, "BaseChat Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Cvar_Chatmode = CreateConVar("sm_chat_mode", "1", "Allows player's to send messages to admin chat.", 0, true, 0.0, true, 1.0);
	g_Cvar_Psaymode = CreateConVar("sm_psay_mode", "0", "Allows player's to use psay 'say @@' alias.", 0, true, 0.0, true, 1.0);

	RegConsoleCmd("say", Command_SayChat);
	RegConsoleCmd("say_team", Command_SayAdmin);		
	RegAdminCmd("sm_say", Command_SmSay, ADMFLAG_CHAT, "sm_say <message> - sends message to all players");
	RegAdminCmd("sm_csay", Command_SmCsay, ADMFLAG_CHAT, "sm_csay <message> - sends centered message to all players");
	RegAdminCmd("sm_hsay", Command_SmHsay, ADMFLAG_CHAT, "sm_hsay <message> - sends hint message to all players");
	RegAdminCmd("sm_tsay", Command_SmTsay, ADMFLAG_CHAT, "sm_tsay [color] <message> - sends top-left message to all players");
	RegAdminCmd("sm_chat", Command_SmChat, ADMFLAG_CHAT, "sm_chat <message> - sends message to admins");
	RegAdminCmd("sm_psay", Command_SmPsay, ADMFLAG_CHAT, "sm_psay <name or #userid> <message> - sends private message");
	RegAdminCmd("sm_msay", Command_SmMsay, ADMFLAG_CHAT, "sm_msay <message> - sends message as a menu panel");
}

public Action:Command_SayChat(client, args)
{
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	text[strlen(text)-1] = '\0';
	
	if (text[1] != '@')
		return Plugin_Continue;
	
	new msgStart = 2;
	
	if (text[2] == '@')
	{
		msgStart = 3;
		
		if (text[3] == '@')
			msgStart = 4;
	}
	
	decl String:message[192];
	strcopy(message, 192, text[msgStart]);
	
	new String:name[64];
	GetClientName(client, name, sizeof(name));
	
	if (msgStart == 2 && CheckAdminForChat(client)) // sm_say alias
	{
		SendChatToAll(name, message);
		LogMessage("Chat: %L triggered sm_say (text %s)", client, message);
	}
	else if (msgStart == 4 && CheckAdminForChat(client)) // sm_csay alias
	{
		PrintCenterTextAll("%s: %s", name, text);
		LogMessage("Chat: %L triggered sm_csay (text %s)", client, text);		
	}	
	else if (msgStart == 3 && (CheckAdminForChat(client) || GetConVarBool(g_Cvar_Psaymode))) // sm_psay alias
	{
		new String:target[64];
	
		new len = BreakString(message, target, sizeof(target));
		
		new clients[2];
		new numClients = SearchForClients(target, clients, 2);
		
		if (numClients == 0)
		{
			PrintToChat(client, "[SM] %t", "No matching client");
			return Plugin_Handled;
		}
		else if (numClients > 1)
		{
			PrintToChat(client, "[SM] %t", "More than one client matches", target);
			return Plugin_Handled;
		}
		else if (!CanUserTarget(client, clients[0]))
		{
			PrintToChat(client, "[SM] %t", "Unable to target");
			return Plugin_Handled;
		}		
		
		new String:name2[64];
		GetClientName(clients[0], name2, sizeof(name2));
	
		PrintToChat(client, "\x04(Private to %s) %s: \x01%s", name2, name, message[len]);
		PrintToChat(clients[0], "\x04(Private to %s) %s: \x01%s", name2, name, message[len]);

		LogMessage("Chat: %L triggered sm_psay to %L (text %s)", client, clients[0], message);		
	}
	else
		return Plugin_Continue;
	
	return Plugin_Handled;	
}

public Action:Command_SayAdmin(client, args)
{
	if (!CheckAdminForChat(client) && !GetConVarBool(g_Cvar_Chatmode))
		return Plugin_Continue;	
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	text[strlen(text)-1] = '\0';
	
	if (text[1] != '@')
		return Plugin_Continue;
	
	decl String:message[192];
	strcopy(message, 192, text[2]);

	new String:name[64];
	GetClientName(client, name, sizeof(name));
	
	SendChatToAdmins(name, message);
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
	if(client == 0)
		strcopy(name, sizeof(name), "RCON"); 
	else
		GetClientName(client, name, sizeof(name));
			
	SendChatToAll(name, text);
	LogMessage("Chat: %L triggered sm_say (text %s)", client, text);
	
	return Plugin_Handled;		
}

public Action:Command_SmCsay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_csay <message>");
		return Plugin_Handled;	
	}
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));

	new String:name[64];
	if(client == 0)
		strcopy(name, sizeof(name), "RCON"); 
	else
		GetClientName(client, name, sizeof(name));
	
	PrintCenterTextAll("%s: %s", name, text);
	LogMessage("Chat: %L triggered sm_csay (text %s)", client, text);
	
	return Plugin_Handled;		
}

public Action:Command_SmHsay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hsay <message>");
		return Plugin_Handled;  
	}
    
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
 
	new String:name[64];
	if(client == 0)
		strcopy(name, sizeof(name), "RCON"); 
	else
		GetClientName(client, name, sizeof(name));
    
	SendHintToAll("%s: %s", name, text);
	LogMessage("Chat: %L triggered sm_hsay (text %s)", client, text);
    
	return Plugin_Handled;    
}

public Action:Command_SmTsay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_tsay <message>");
		return Plugin_Handled;  
	}
    
	decl String:text[192], String:colorStr[16];
	GetCmdArgString(text, sizeof(text));
	
	new len = BreakString(text, colorStr, 16);
 
	new String:name[64];
	if(client == 0)
		strcopy(name, sizeof(name), "RCON"); 
	else
		GetClientName(client, name, sizeof(name));
		
	new color = FindColor(colorStr);

	if(color == -1)    
	    SendDialogToAll(_, "%s: %s", name, text);
	else
		SendDialogToAll(color, "%s: %s", name, text[len]);

	LogMessage("Chat: %L triggered sm_tsay (text %s)", client, text);
    
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
	if(client == 0)
		strcopy(name, sizeof(name), "RCON"); 
	else
		GetClientName(client, name, sizeof(name));
	
	SendChatToAdmins(name, text);
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
	if(client == 0)
		strcopy(name, sizeof(name), "RCON"); 
	else
		GetClientName(client, name, sizeof(name));

	GetClientName(clients[0], name2, sizeof(name2));
	
	PrintToChat(client, "\x04(Private: %s) %s: \x01%s", name2, name, message);
	PrintToChat(clients[0], "\x04(Private: %s) %s: \x01%s", name2, name, message);

	LogMessage("Chat: %L triggered sm_psay to %L (text %s)", client, clients[0], message);
	
	return Plugin_Handled;	
}

public Action:Command_SmMsay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_msay <message>");
		return Plugin_Handled;	
	}
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));

	new String:name[64];
	if(client == 0)
		strcopy(name, sizeof(name), "RCON"); 
	else
		GetClientName(client, name, sizeof(name));
		
	SendPanelToAll(name, text);

	LogMessage("Chat: %L triggered sm_msay (text %s)", client, text);
	
	return Plugin_Handled;		
}

bool:CheckAdminForChat(client)
{
	new AdminId:aid = GetUserAdmin(client);
	
	if(aid == INVALID_ADMIN_ID)
	{
		return false;			
	}
	
	return GetAdminFlag(aid, Admin_Chat, Access_Effective);
}

FindColor(String:color[])
{
	for (new i = 0; i < 13; i++)
	{
		if(strcmp(color, g_ColorNames[i], false) == 0)
			return i;
	}
	
	return -1;
}

stock SendChatToAll(String:name[], String:message[])
{
	PrintToChatAll("\x04(ALL) %s: \x01%s", name, message);
}

stock SendChatToAdmins(String:name[], String:message[])
{
	new iMaxClients = GetMaxClients();
	
	for (new i = 1; i <= iMaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (CheckAdminForChat(i))
			{
				PrintToChat(i, "\x04(ADMINS) %s: \x01%s", name, message);
			}
		}	
	}
}

stock SendHintToAll(String:text[], any:...)
{
	new String:message[192];
	VFormat(message, 191, text, 2);
 
	new iLen = strlen(message);
    
	if (iLen > 30)
	{
		new iLastAdded = 0;
 
		for (new i = 0; i < iLen; i++)
		{
			if((message[i] == ' ' && iLastAdded > 30 && (iLen - i) > 10) || ((GetNextSpaceCount(text, i + 1) + iLastAdded)  > 34))
			{
				message[i] = '\n';
				iLastAdded = 0;
			}
			else
				iLastAdded++;
		}
	}
 
	new Handle:hHintMessage = StartMessageAll("HintText");
	BfWriteByte(hHintMessage, -1);
	BfWriteString(hHintMessage, message);
	EndMessage();
}
 
stock GetNextSpaceCount(String:text[], iCurIndex)
{
	new iCount = 0;
	new iLen = strlen(text);
	
	for (new i = iCurIndex; i < iLen; i++)
	{
		if (text[i] == ' ')
			return iCount;
		else
			iCount++;
	}
 
	return iCount;
} 

stock SendDialogToAll(color = 0, String:text[], any:...)
{
	new String:message[100];
	VFormat(message, sizeof(message), text, 3);	
	
	new MaxClients = GetMaxClients();
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			new Handle:kv = CreateKeyValues("Stuff", "title", message);
			KvSetColor(kv, "color", g_Colors[color][0], g_Colors[color][1], g_Colors[color][2], 255);
			KvSetNum(kv, "level", 1);
			KvSetNum(kv, "time", 10);
			
			CreateDialog(i, kv, DialogType_Msg);
			
			CloseHandle(kv);
		}
	}	
}

stock SendPanelToAll(String:name[], String:message[])
{
	decl String:title[100];
	Format(title, 64, "(Admin) %s:", name);
	
	new Handle:mSayPanel = CreatePanel();
	SetPanelTitle(mSayPanel, title);
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);
	DrawPanelText(mSayPanel, message);
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);

	SetPanelCurrentKey(mSayPanel, 10);
	DrawPanelItem(mSayPanel, "Exit", ITEMDRAW_CONTROL);

	new MaxClients = GetMaxClients();
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SendPanelToClient(mSayPanel, i, Handler_DoNothing, 10);
		}
	}

	CloseHandle(mSayPanel);
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	/* Do nothing */
}