#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION 				"1.3.3.7"

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
	"|\\//|",
	"|\\|",
	"0",
	"|*",
	"<|",
	"|2",
	"5",
	"7",
	"|_|",
	"|/",
	"\\/\\/",
	"><",
	"`/",
	"7_"
};

new Handle:g_enabled = INVALID_HANDLE;
new bool:g_enabledh = false;

new Handle:g_leetlevel = INVALID_HANDLE;

new Handle:leetTrie = INVALID_HANDLE;
new bool:EveryOneIsLeet = false;

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
	
	g_leetlevel = CreateConVar("leetspeak_level", "2", "One of this many characters will be turned into 1337speak", FCVAR_PLUGIN);
	
	RegConsoleCmd("say", command_Say);
	RegConsoleCmd("say2", command_Say);
	RegConsoleCmd("say_team", command_Say);
	
	g_enabledh = GetConVarBool(g_enabled);
	HookConVarChange(g_enabled, ConVarChanged);
	
	leetTrie = CreateTrie();
	if(leetTrie == INVALID_HANDLE)
	{
		ThrowError("Could not create the leet Trie! YOU officially FAIL!");
	}
	
	RegAdminCmd("sm_turnleet", Command_LeetPlayer, ADMFLAG_BAN, "sm_turnleet <player1> [player2] ... [playerN] - turn all players leet");
	RegAdminCmd("sm_leetmode", Command_LeetAll, ADMFLAG_BAN, "Turn EVERYONE leet");
}

public OnPluginEnd()
{
	CloseHandle(leetTrie);
}

LeetPlayer(player)
{
	decl String:authid[128];
	GetClientAuthString(player, authid, sizeof(authid));
	
	SetTrieValue(leetTrie, authid, 1337);
}

UnLeetPlayer(player)
{
	decl String:authid[128], leetlevel;
	GetClientAuthString(player, authid, sizeof(authid));
	if(GetTrieValue(leetTrie, authid, leetlevel))
		RemoveFromTrie(leetTrie, authid);
}

bool:IsPlayerLeet(player)
{
	if (!player || !IsClientInGame(player))
		return false;
	decl String:authid[128], leetlevel;
	GetClientAuthString(player, authid, sizeof(authid));
	return GetTrieValue(leetTrie, authid, leetlevel);
}

public Action:Command_LeetPlayer(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_turnleet <player1> [player2] ... [playerN] - turn all players leet");
		return Plugin_Handled;
	}
	
	decl String:player[64];
	
	for(new i = 0; i < args; i++)
	{
		GetCmdArg(i+1, player, sizeof(player));
		new player_id = FindTarget(client, player, true, false);
		
		if(player_id == -1)
			continue;
		
		if (!IsPlayerLeet(player_id))
		{
			LeetPlayer(player_id);
			PrintToChatAll("\x01[SM] \x04%N\x01 is now \x04FREAKIN LEET.", player_id);
		}
		else
		{
			UnLeetPlayer(player_id);
			PrintToChatAll("\x01[SM] \x04%N\x01 is no longer \x04FREAKIN LEET\x01, he blows", player_id);
		}
	}	
	return Plugin_Handled;
}

public Action:Command_LeetAll(client, args)
{
	EveryOneIsLeet = !EveryOneIsLeet;
	
	if (EveryOneIsLeet)
	{
		PrintToChatAll("\x01[SM] \x04Everyone is 1337 now!");
	}
	else
	{
		PrintToChatAll("\x01[SM] \x04Common 1337ness has passed");
	}
	
	return Plugin_Handled;
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
	
	if ((!IsPlayerLeet(Client) && !EveryOneIsLeet))
		return Plugin_Continue;
	
	new size = 192;
	decl String:text[size];
	GetCmdArgString(text, size);
	
	StripQuotes(text);
	
	if (text[0] == '@')
	{
		return Plugin_Continue;
	}
	
	decl String:prefix[16];
	
	new bool:deadChat;
	if (!IsPlayerAlive(Client))
	{
		deadChat = true;
		StrCat(prefix, sizeof(prefix), "*DEAD*");
	}
	
	decl String:command[32];
	GetCmdArg(0, command, sizeof(command));
	
	new bool:teamChat;
	if (!strcmp(command, "say_team"))
	{
		teamChat = true;
		StrCat(prefix, sizeof(prefix), "(TEAM)");
	}
	
	decl String:leetText[size];
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
	
	new skipsetting = GetConVarInt(g_leetlevel)-1;
	new skipped;
	
	for (new i=0; i<size; i++)
	{
		if ((charIdx = IsLeetChar(msg[i])) > -1 && skipped >= skipsetting)
		{
			strcopy(dest[strIdx], size-strIdx, charsThatAreLeet[charIdx]);
			strIdx += strlen(charsThatAreLeet[charIdx]);
			skipped = 0;
		}
		else
		{
			strcopy(dest[strIdx], size-strIdx, msg[i]);
			strIdx ++;
			skipped++;
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