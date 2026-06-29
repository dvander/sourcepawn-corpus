#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION 				"1.0.0.0"

#define C_WHITE						0x01
#define C_TEAM	    					0x03

// ololololololololol parrarrrarallel arrays
new charsThatCouldBeLeet[]			 = { 'l', 'e', 't', 'w' };
new String:charsThatAreLeet[][6]	 = { "1", "3", "7", "\\/\\/" };

public Plugin:myinfo =
{
	name = "1337 Speak",
	author = "Wazz",
	description = "mmmhmmm",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	RegConsoleCmd("say", command_Say);
	RegConsoleCmd("say2", command_Say);
	RegConsoleCmd("say_team", command_Say);
}

public Action:command_Say(Client, args)
{
	if (!Client || IsChatTrigger())
	{
		return Plugin_Continue;
	}
	
	new size = 192;
	new String:text[size];
	GetCmdArgString(text, size);
	
	StripQuotes(text);
	
	if (text[0] == '@')
	{
		return Plugin_Continue;
	}
	
	new String:prefix[16];
	
	new bool:deadChat;
	if (!IsPlayerAlive(Client))
	{
		deadChat = true;
		StrCat(prefix, sizeof(prefix), "*DEAD*");
	}
	
	new String:command[32];
	GetCmdArg(0, command, sizeof(command));

	new bool:teamChat;
	if (!strcmp(command, "say_team"))
	{
		teamChat = true;
		StrCat(prefix, sizeof(prefix), "(TEAM)");
	}
	
	new String:leetText[size];
	LeetSpeakThatShit(text, leetText, size);
	
	if (teamChat)
	{
		new clientTeam = GetClientTeam(Client);
		
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i) && (clientTeam == GetClientTeam(i)))
			{
				if ((deadChat && !IsPlayerAlive(i)) || !deadChat)
				{
					PrintToChatFromSender(i, Client, "%c%s%s%c%N %c:  %s", C_WHITE, prefix, strlen(prefix)>0?" ":"", C_TEAM, Client, C_WHITE, leetText);
				}
			}
		}
	}
	else
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if ((deadChat && !IsPlayerAlive(i)) || !deadChat)
				{
					PrintToChatFromSender(i, Client, "%c%s%s%c%N %c:  %s", C_WHITE, prefix, strlen(prefix)>0?" ":"", C_TEAM, Client, C_WHITE, leetText);
				}
			}
		}
	}

	return Plugin_Handled;
}

LeetSpeakThatShit(const String:msg[], String:dest[], size)
{
	new strIdx;
	new charIdx;
	
	for (new i=0; i<size; i++)
	{
		if ((charIdx = IsLeetChar(msg[i])) > -1)
		{
			strcopy(dest[strIdx], size-strIdx, charsThatAreLeet[charIdx]);
			strIdx += strlen(charsThatAreLeet[charIdx]);
		}
		else
		{
			strcopy(dest[strIdx], size-strIdx, msg[i]);
			strIdx ++;
		}
	}
}

IsLeetChar(char)
{
	for (new i=0; i<sizeof(charsThatCouldBeLeet); i++)
	{
		if (char == charsThatCouldBeLeet[i])
		{
			return i;
		}
	}
	
	return -1;
}

stock PrintToChatFromSender(Client, Sender, const String:raw[], any:...)
{
	new String:msg[192];
	VFormat(msg, sizeof(msg), raw, 4);
	
	new Handle:buffer = StartMessageOne("SayText2", Client);
	if (buffer != INVALID_HANDLE)
	{
		BfWriteByte(buffer, Sender);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, msg);
		EndMessage();
	}
}