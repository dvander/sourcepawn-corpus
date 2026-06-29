/**
 * A plugin to fix handling of strings beginning with a quotation mark (") but not ending with one
 * by the say and say_team commands. For example: say "test would originally produce tes as the chat message.
 * If the string was only two characters long, such as in the case of say "t the server would crash.
 *
 * This plugin is meant to avoid this by producing a user message containing the entire string.
 * So say "test would simply produce "test as the chat message.
 * The default behavior is still followed if the string begins and ends with quotes, 
 * or if it does not begin with a quote.
 */
 
 /**
 * SayText format for Dystopia:
 * byte containing clientid of sender
 * string containing message
 * byte value treated as bool to determine if colors should be applied to text
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

/* TODO: Are these message lengths right? */
#define CHAT_MESSAGE_STRL 		192 /* Maximum length of body of chat message. */
#define FULL_CHAT_MESSAGE_STRL	256 /* Maximum length of entire chat message. */
#define STEAM_AUTH_STRL 		34  /* Maximum length of Steam ID. */

/* TODO: Why does the compiler throw an error when trying to make these a consts? */
/**
 * Lookup tables to map team IDs to team names. Unassigned is unlikely to actually be used, and seeing it should be a
 * bit of a surprise. We make separate ones for logging AND chat because SOMEBODY was not sure if the spectator team
 * name should have been Spectator or Spectators.
 */
char g_TeamNamesLogging[][] = {"Unassigned", "Spectator", "Punks", "Corps"};
char g_TeamNamesChat[][] = {"Unassigned", "Spectators", "Punks", "Corps"};

/* Array to contain all teamids. */
int g_TeamID[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Say Command Fix",
	author = "emjay",
	description = "Fixes an issue with parsing a string beginning with a quote by say and say_team.",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2472497"
};

public void OnPluginStart()
{
	/* Hook the say and say_team commands. */
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_SayTeam, "say_team");
	
	/* Hook the player_team event. */
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
}

/* Update array of team IDs when a player changes their team. */
public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int EventClient = GetClientOfUserId( event.GetInt("userid") );
	g_TeamID[EventClient] = event.GetInt("team");
}

public Action Command_Say(int client, const char[] command, int argc)
{
	char SayParam[CHAT_MESSAGE_STRL];
	int SayParamLength = GetCmdArgString( SayParam, sizeof(SayParam) );
	
	if(SayParamLength < 1 || SayParam[SayParamLength - 1] == '"' || SayParam[0] != '"')
	{
		return Plugin_Continue;
	}
	
	char SenderName[MAX_NAME_LENGTH];
	GetClientName( client, SenderName, sizeof(SenderName) );
	
	char SenderSteamID[STEAM_AUTH_STRL];
	GetClientAuthId( client, AuthId_Steam2, SenderSteamID, sizeof(SenderSteamID) );
	
	char ChatMessageString[FULL_CHAT_MESSAGE_STRL];
	Format(ChatMessageString, sizeof(ChatMessageString), "%s: %s\n", SenderName, SayParam);
	
	Handle ChatMessage = StartMessageAll("SayText");
	BfWriteByte(ChatMessage, client);
	BfWriteString(ChatMessage, ChatMessageString);
	BfWriteByte(ChatMessage, 0x01);
	EndMessage();
	
	/* All chat messages should be printed to the server console as well. */
	PrintToServer(ChatMessageString);
	
	/**
	 * Overriding the original command will prevent the log entry from being automatically created, 
	 * so we need to do that.
	 */
	LogToGame("\"%s<%d><%s><%s>\" say \"%s\"",
			  SenderName, 
			  GetClientUserId(client), 
			  SenderSteamID, 
			  g_TeamNamesLogging[ g_TeamID[client] ],
			  SayParam);
	
	return Plugin_Handled;
}

public Action Command_SayTeam(int client, const char[] command, int argc)
{
	char SayParam[CHAT_MESSAGE_STRL];
	int SayParamLength = GetCmdArgString( SayParam, sizeof(SayParam) );
	
	if(SayParamLength < 1 || SayParam[SayParamLength - 1] == '"' || SayParam[0] != '"')
	{
		return Plugin_Continue;
	}
	
	char SenderName[MAX_NAME_LENGTH];
	GetClientName( client, SenderName, sizeof(SenderName) );
	
	char SenderSteamID[STEAM_AUTH_STRL];
	GetClientAuthId( client, AuthId_Steam2, SenderSteamID, sizeof(SenderSteamID) );
	
	char ChatMessageString[FULL_CHAT_MESSAGE_STRL];
	Format(ChatMessageString, 
		   sizeof(ChatMessageString), 
		   "(%s) %s: %s\n",
		   g_TeamNamesChat[ g_TeamID[client] ],
		   SenderName, 
		   SayParam);
	
	for(int RecipientIndex = 1; RecipientIndex <= MaxClients; ++RecipientIndex)
	{
		if( g_TeamID[RecipientIndex] == g_TeamID[client] && IsClientInGame(RecipientIndex) )
		{
			Handle ChatMessage = StartMessageOne("SayText", RecipientIndex);
			BfWriteByte(ChatMessage, client);
			BfWriteString(ChatMessage, ChatMessageString);
			BfWriteByte(ChatMessage, 0x01);
			EndMessage();
		}
	}
	
	/* All chat messages should be printed to the server console as well. */
	PrintToServer(ChatMessageString);
	
	/**
	 * Overriding the original command will prevent the log entry from being automatically created, 
	 * so we need to do that.
	 */
	LogToGame("\"%s<%d><%s><%s>\" say_team \"%s\"",
			  SenderName, 
			  GetClientUserId(client), 
			  SenderSteamID, 
			  g_TeamNamesLogging[ g_TeamID[client] ],
			  SayParam);
	
	return Plugin_Handled;
}
