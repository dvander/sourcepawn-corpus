#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION 				"1.0.0.0"

#define C_WHITE						0x01
#define C_TEAM	    					0x03

// ololololololololol parrarrrarallel arrays
new charsThatCouldBeLeet[52] = {
	'a',
	'b',
	'c',
	'd',
	'e',
	'f',
	'g',
	'h',
	'i',
	'j',
	'k',
	'l',
	'm',
	'n',
	'o',
	'p',
	'q',
	'r',
	's',
	't',
	'u',
	'v',
	'w',
	'x',
	'y',
	'z',
	'A',
	'B',
	'C',
	'D',
	'E',
	'F',
	'G',
	'H',
	'I',
	'J',
	'K',
	'L',
	'M',
	'N',
	'O',
	'P',
	'Q',
	'R',
	'S',
	'T',
	'U',
	'V',
	'W',
	'X',
	'Y',
	'Z'
};
new String:charsThatAreLeet[26][6] = {
	"4",
	"|3",
	"<",
	"|)",
	"3",
	"]=",
	"6",
	"|-|",
	"1",
	"_|",
	"|<",
	"|_",
	"/\\/\\",
	"|\\|",
	"0",
	"|*",
	"<|",
	"|2",
	"5",
	"7",
	"|_|",
	"\\/",
	"\\/\\/",
	"><",
	"`/",
	"7_"
};

new Handle:g_enabled = INVALID_HANDLE;
new bool:g_enabledh = false;

public Plugin:myinfo =
{
	name = "1337 Speak",
	author = "Wazz|MatthiasVance|Dragonshadow|psychonic",
	description = "Everyone can be 1337 now.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("leetspeak_version", PLUGIN_VERSION, "Everybody can be 1337 now.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_enabled = CreateConVar("leetspeak_enable", "1", "Enable/Disable 1337speak", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	RegConsoleCmd("say", command_Say);
	RegConsoleCmd("say2", command_Say);
	RegConsoleCmd("say_team", command_Say);
	
	g_enabledh = GetConVarBool(g_enabled);
	HookConVarChange(g_enabled, ConVarChanged);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_enabledh = GetConVarBool(g_enabled);
}
public Action:command_Say(Client, args)
{
	if(!g_enabledh)
	{
		return Plugin_Continue;
	}
	
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
			if(IsCharUpper(char))
			{
				return (i-26);
			}
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