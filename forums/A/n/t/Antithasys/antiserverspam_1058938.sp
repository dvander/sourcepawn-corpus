#define REPLACEMENT_MSG "I love your server!  I will bring all my friends here!"

#define PLUGIN_VERSION "1.0.0"

#define CHAT_SYMBOL 	'@'
#define CHAR_PERCENT 	"%"
#define CHAR_NULL 		"\0"

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Anti Server Spam",
	author = "Antithasys",
	description = "Replaces server ip spam with message",
	version = PLUGIN_VERSION,
	url = "http://www.simple-plugins.com"
}

public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
}

/**
Commands
*/
public Action:Command_Say(client, args)
{
	
	/**
	Make sure its not the server or a chat trigger
	*/
	if (client == 0 || IsChatTrigger())
	{
		return Plugin_Continue;
	}
	
	/**
	Get the message
	*/
	decl	String:sMessage[128];
	GetCmdArgString(sMessage, sizeof(sMessage));
	
	/**
	Process the message
	*/
	return ProcessMessage(client, false, sMessage, sizeof(sMessage));
}

public Action:Command_SayTeam(client, args)
{
	
	/**
	Make sure we are enabled.
	*/
	if (client == 0 || IsChatTrigger())
	{
		return Plugin_Continue;
	}
	
	/**
	Get the message
	*/
	decl	String:sMessage[128];
	GetCmdArgString(sMessage, sizeof(sMessage));
	
	/**
	Process the message
	*/
	return ProcessMessage(client, true, sMessage, sizeof(sMessage));
}

stock Action:ProcessMessage(client, bool:teamchat, String:message[], maxlength)
{

	new String:sOriginalMessage[128];
	
	/**
	The client is, so get the chat message and strip it down.
	*/
	StripQuotes(message);
	TrimString(message);
		
	/**
	Because we are dealing with a chat message, lets take out all the %'s
	*/
	ReplaceString(message, maxlength, CHAR_PERCENT, CHAR_NULL);
	strcopy(sOriginalMessage, sizeof(sOriginalMessage), message);
		
	/**
	Make sure it's not blank
	*/
	if (IsStringBlank(message))
	{
		return Plugin_Stop;
	}
		
	/**
	Bug out if they are using the admin chat symbol (admin chat).
	*/
	if (message[0] == CHAT_SYMBOL)
	{
		return Plugin_Continue;
	}

	/**
	Make sure they said an ip address word
	*/
	else if (!SaidIPAddress(message, maxlength))
	{
		return Plugin_Continue;
	}
		
	/**
	Format the message.
	*/
	decl String:sChatMsg[384];
	FormatMessage(client, GetClientTeam(client), IsPlayerAlive(client), teamchat, message, sChatMsg, sizeof(sChatMsg));
		
	/**
	Send the message.
	*/
	new iCurrentTeam = GetClientTeam(client);
	if (teamchat)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == iCurrentTeam)
			{
				SayText2One(i, client, sChatMsg);
			}
		}
	}
	else
	{
		SayText2All(client, sChatMsg);
	}
	
	/**
	We are done, bug out, and stop the original chat message.
	*/
	return Plugin_Stop;
}

stock FormatMessage(client, team, bool:alive, bool:teamchat, const String:message[], String:chatmsg[], maxlength)
{
	decl	String:sDead[10],
				String:sTeam[15],
				String:sClientName[64];
	
	GetClientName(client, sClientName, sizeof(sClientName));
	
	if (teamchat)
	{
		if (team != 0)
		{
			Format(sTeam, sizeof(sTeam), "(TEAM) ");
		}
		else
		{
			Format(sTeam, sizeof(sTeam), "(Spectator) ");
		}
	}
	else
	{
		if (team != 0)
		{
			Format(sTeam, sizeof(sTeam), "");
		}
		else
		{
			Format(sTeam, sizeof(sTeam), "*SPEC* ");
		}
	}
	
	if (team != 0)
	{
		if (alive)
		{
			Format(sDead, sizeof(sDead), "");
		}
		else
		{
			Format(sDead, sizeof(sDead), "*DEAD* ");
		}
	}
	else
	{
		Format(sDead, sizeof(sDead), "");
	}
	
	Format(chatmsg, maxlength, "\x01%s%s\x03%s \x01:  %s", sDead, sTeam, sClientName, message);
}

stock bool:SaidIPAddress(String:message[], maxlength)
{
	new bool:bBad;
	new String:sWords[64][128];
	ExplodeString(message, " ", sWords, sizeof(sWords), sizeof(sWords[]));
	for (new i = 0; i < sizeof(sWords); i++)
	{
		TrimString(sWords[i]);
		if (IsStringBlank(sWords[i]))
		{
			continue;
		}
		if (LooksLikeIpAddress(sWords[i]))
		{
			bBad = true;
			break;
		}
	}
	if (bBad)
	{
		Format(message, maxlength, REPLACEMENT_MSG);
	}
	return bBad;
}

stock bool:IsStringBlank(const String:input[])
{
	new len = strlen(input);
	for (new i=0; i<len; i++)
	{
		if (!IsCharSpace(input[i]))
		{
			return false;
		}
	}
	return true;
}

stock bool:LooksLikeIpAddress(const String:input[])
{
	new iDotIndexes[3];
	iDotIndexes[0] = StrContains(input, ".");
	if (iDotIndexes[0] != -1)
	{
		iDotIndexes[1] = StrContains(input[iDotIndexes[0] + 1], ".");
		if (iDotIndexes[1] != -1)
		{
			iDotIndexes[1] = iDotIndexes[0] + iDotIndexes[1] + 1;
			iDotIndexes[2] = StrContains(input[iDotIndexes[1] + 1], ".");
			if (iDotIndexes[2] != -1)
			{
				iDotIndexes[2] = iDotIndexes[1] + iDotIndexes[2] + 1;
				if (IsCharNumeric(input[iDotIndexes[0] + 1]) && IsCharNumeric(input[iDotIndexes[0] - 1])
					&& (IsCharNumeric(input[iDotIndexes[1] + 1]) && IsCharNumeric(input[iDotIndexes[1] - 1]))
					&& (IsCharNumeric(input[iDotIndexes[2] + 1]) && IsCharNumeric(input[iDotIndexes[2] - 1])))
				{
					
					/**
					So it has 3 periods and each char on either side of the period is a number
					Looks like an IP Address to me!
					*/
					return true;
				}
			}
		}
	}
	return false;
}

stock SayText2One(client, author, const String:message[]) 
{ 
	new Handle:buffer = StartMessageOne("SayText2", client); 
	if (buffer != INVALID_HANDLE) 
	{ 
		BfWriteByte(buffer, author); 
		BfWriteByte(buffer, true); 
		BfWriteString(buffer, message); 
		EndMessage(); 
	} 
}

stock SayText2All(client, const String:message[])
{
	new Handle:buffer = StartMessageAll("SayText2");
	if (buffer != INVALID_HANDLE)
	{
		BfWriteByte(buffer, client);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage();
	}
}  