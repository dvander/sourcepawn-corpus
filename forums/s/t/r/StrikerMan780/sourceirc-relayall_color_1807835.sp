/*
This file is part of SourceIRC.

SourceIRC is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

SourceIRC is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with SourceIRC.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <sdktools>
#include <regex>
#undef REQUIRE_PLUGIN
#include <sourceirc>

new game;
#define UNKNOWN 0
#define CSTRIKE 1
#define DODS	2
#define HL2DM	3
#define TF2		4
#define AG2		5

stock GetGame()
{
	new String:gamestr[64];
	GetGameFolderName(gamestr, sizeof(gamestr));
	
	if (!strcmp(gamestr, "cstrike"))
	{
		game = CSTRIKE;
	}
	else if (!strcmp(gamestr, "dod"))
	{
		game = DODS;
	}
	else if (!strcmp(gamestr, "hl2mp"))
	{
		game = HL2DM;
	}
	else if (!strcmp(gamestr, "tf"))
	{
		game = TF2;
	}
	else if (!strcmp(gamestr, "ag2"))
	{
		game = AG2;
	}
	else
	{
		game = UNKNOWN;
	}
}

new g_userid = 0;

new bool:g_isteam = false;

public Plugin:myinfo = {
	name = "SourceIRC -> Relay All (With IRC Colors -> AG2/TF2 Colors)",
	author = "Azelphur",
	description = "Relays various game events",
	version = IRC_VERSION,
	url = "http://azelphur.com/"
};

public OnPluginStart()
{	
	RegConsoleCmd("me", Command_Me);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	HookEvent("player_changename", Event_PlayerChangeName, EventHookMode_Post);
	HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
	HookEvent("player_chat", Event_PlayerSay, EventHookMode_Post);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
	
	LoadTranslations("sourceirc.phrases");
	
	GetGame();
}

public OnAllPluginsLoaded() 
{
	if (LibraryExists("sourceirc"))
	{
		IRC_Loaded();
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "sourceirc"))
	{
		IRC_Loaded();
	}
}

IRC_Loaded()
{
	IRC_CleanUp(); // Call IRC_CleanUp as this function can be called more than once.
	IRC_HookEvent("PRIVMSG", Event_PRIVMSG);
}

public Action:Command_Say(client, args)
{
	g_isteam = false; // Ugly hack to get around player_chat event not working.
}

public Action:Command_SayTeam(client, args)
{
	g_isteam = true; // Ugly hack to get around player_chat event not working.
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	decl String:result[IRC_MAXLEN], String:message[256];
	result[0] = '\0';
	GetEventString(event, "text", message, sizeof(message));
	
	if (!IsPlayerAlive(client))
	{
		StrCat(result, sizeof(result), "*DEAD* ");
	}
	
	if (g_isteam)
	{
		StrCat(result, sizeof(result), "(TEAM) ");
	}
	
	new team
	if (client != 0)
	{
		team = IRC_GetTeamColor(GetClientTeam(client));
	}
	else
	{
		team = 0;
	}
	
	if (team == -1)
	{
		Format(result, sizeof(result), "%s%N: %s", result, client, message);
	}
	else
	{
		Format(result, sizeof(result), "%s\x03%02d%N\x03: %s", result, team, client, message);
	}
	
	IRC_MsgFlaggedChannels("relay", result);
}


public OnClientAuthorized(client, const String:auth[]) // We are hooking this instead of the player_connect event as we want the steamid
{
	new userid = GetClientUserId(client);
	if (userid <= g_userid) // Ugly hack to get around mass connects on map change
	{
		return true;
	}
	
	g_userid = userid;
	decl String:playername[MAX_NAME_LENGTH], String:result[IRC_MAXLEN];
	GetClientName(client, playername, sizeof(playername));
	Format(result, sizeof(result), "%t", "Player Connected", playername, auth, userid);
	
	if (!StrEqual(result, ""))
	{
		IRC_MsgFlaggedChannels("relay", result);
	}
	
	return true;
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (client != 0)
	{
		decl String:reason[128], String:playername[MAX_NAME_LENGTH], String:auth[64], String:result[IRC_MAXLEN];
		GetEventString(event, "reason", reason, sizeof(reason));
		GetClientName(client, playername, sizeof(playername));
		GetClientAuthString(client, auth, sizeof(auth));
		
		for (new i = 0; i <= strlen(reason); i++)
		{ // For some reason, certain disconnect reasons have \n in them, so i'm stripping them. Silly valve.
			if (reason[i] == '\n')
			{
				RemoveChar(reason, sizeof(reason), i);
			}
		}
		
		Format(result, sizeof(result), "%t", "Player Disconnected", playername, auth, userid, reason);
		
		if (!StrEqual(result, ""))
		{
			IRC_MsgFlaggedChannels("relay", result);
		}
	}
}

public Action:Event_PlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if (client != 0)
	{
		decl String:oldname[128], String:newname[MAX_NAME_LENGTH], String:auth[64], String:result[IRC_MAXLEN];
		GetEventString(event, "oldname", oldname, sizeof(oldname));
		GetEventString(event, "newname", newname, sizeof(newname));
		GetClientAuthString(client, auth, sizeof(auth));
		Format(result, sizeof(result), "%t", "Changed Name", oldname, auth, userid, newname);
		
		if (!StrEqual(result, ""))
		{
			IRC_MsgFlaggedChannels("relay", result);
		}
	}
}

public OnMapEnd()
{
	IRC_MsgFlaggedChannels("relay", "%t", "Map Changing");
}

public OnMapStart()
{
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));
	IRC_MsgFlaggedChannels("relay", "%t", "Map Changed", map);
}

public Action:Command_Me(client, args)
{
	decl String:Args[256], String:name[64], String:auth[64], String:text[512];
	GetCmdArgString(Args, sizeof(Args));
	GetClientName(client, name, sizeof(name));
	GetClientAuthString(client, auth, sizeof(auth));
	
	new team = IRC_GetTeamColor(GetClientTeam(client));
	if (team == -1)
	{
		IRC_MsgFlaggedChannels("relay", "* %s %s", name, Args);
	}
	else
	{
		IRC_MsgFlaggedChannels("relay", "* \x03%02d%s\x03 %s", team, name, Args);
	}
	
	Format(text, sizeof(text), "\x01* \x03%s\x01 %s", name, Args);
	SayText2All(client, text);
	return Plugin_Handled;
}

public Action:Event_PRIVMSG(const String:hostmask[], args)
{
	decl String:channel[64];
	IRC_GetEventArg(1, channel, sizeof(channel));
	
	if (IRC_ChannelHasFlag(channel, "relay"))
	{
		decl String:nick[IRC_NICK_MAXLEN], String:text[IRC_MAXLEN];
		IRC_GetNickFromHostMask(hostmask, nick, sizeof(nick));
		IRC_GetEventArg(2, text, sizeof(text));
		if (!strncmp(text, "\x01ACTION ", 8) && text[strlen(text)-1] == '\x01')
		{
			text[strlen(text)-1] = '\x00';
			IRC_Strip2(text, sizeof(text)); // Strip IRC Color Codes
			IRC_StripGame(text, sizeof(text)); // Strip Game color codes
			
			if(game == AG2)
			{
				PrintToChatAll("^0[^2IRC^0] * %s %s", nick, text[7])
			}
			else
			{
				PrintToChatAll("\x01[\x04IRC\x01] * %s %s", nick, text[7]);
			}
		}
		else 
		{
			IRC_Strip2(text, sizeof(text)); // Strip IRC Color Codes	
			IRC_StripGame(text, sizeof(text)); // Strip Game color codes
			
			if(game == AG2)
			{
				PrintToChatAll("^0[^2IRC^0] %s : %s", nick, text);
			}
			else
			{
				PrintToChatAll("\x01[\x04IRC\x01] %s : %s", nick, text);
			}
		}
	}
}

stock SayText2All(clientid4team, const String:message[])
{
	new Handle:hBf;
	hBf = StartMessageAll("SayText2");
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, clientid4team); 
		BfWriteByte(hBf, 0); 
		BfWriteString(hBf, message);
		EndMessage();
	}
}

public OnPluginEnd() {
	IRC_CleanUp();
}

// http://bit.ly/defcon
stock IRC_Strip2(String:str[], maxlength)
{
	static Handle:hRegex = INVALID_HANDLE;
	hRegex = CompileRegex("\x16|\x0f|\x1F|\x02|\x03(\\d{1,2}(,\\d{1,2})?)?");
	
	decl String:matchedTag[64];
	decl String:matchedTag2[64];
	
	decl String:Copy[64];
	decl Number;
	decl bool:foundmatch;
	
	while (MatchRegex(hRegex, str) > 0)
	{
		GetRegexSubString(hRegex, 0, matchedTag, sizeof(matchedTag));
		foundmatch = GetRegexSubString(hRegex, 1, matchedTag2, sizeof(matchedTag2));
		
		new location = StrContains(str, matchedTag);
		if (location == -1)
		{
			break; // Something bad happened, run away!
		}
		
		Number = StringToInt(matchedTag2);
		strcopy(Copy, sizeof(Copy), matchedTag);
		
		if(!foundmatch)
		{
			if(game == AG2)
			{
				ReplaceStringEx(Copy, sizeof(Copy), "\x03", "^0");
			}
			else if(game == TF2 || game == CSTRIKE || game == HL2DM)
			{
				ReplaceStringEx(Copy, sizeof(Copy), "\x03", "\x01");
			}
			else
			{
				ReplaceStringEx(Copy, sizeof(Copy), "\x03", "");
			}
		}
		else if(Number < 16)
		{
			if(game == AG2)
			{
				ReplaceStringEx(Copy, sizeof(Copy), "\x03", "$");
			}
			else if(game == TF2 || game == CSTRIKE || game == HL2DM)
			{
				ReplaceStringEx(Copy, sizeof(Copy), "\x03", "\x07");
			}
			else
			{
				ReplaceStringEx(Copy, sizeof(Copy), "\x03", "");
			}
		}
		else
		{
			if(game == AG2)
			{
				ReplaceStringEx(Copy, sizeof(Copy), "\x03", "^0");
			}
			else if(game == TF2 || game == CSTRIKE || game == HL2DM)
			{
				ReplaceStringEx(Copy, sizeof(Copy), "\x03", "\x01");
			}
			else
			{
				ReplaceStringEx(Copy, sizeof(Copy), "\x03", "");
			}
		}
		
		ReplaceStringEx(Copy, sizeof(Copy), "\x16", "");
		ReplaceStringEx(Copy, sizeof(Copy), "\x0f", "");
		ReplaceStringEx(Copy, sizeof(Copy), "\x1F", "");
		ReplaceStringEx(Copy, sizeof(Copy), "\x02", "");
		
		if(game == AG2)
		{
			if(Number == 0)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "FFF");
			}
			else if(Number == 1)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "111");
			}
			else if(Number == 2)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "00C");
			}
			else if(Number == 3)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "0B0");
			}
			else if(Number == 4)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "F00");
			}
			else if(Number == 5)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "C33");
			}
			else if(Number == 6)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "80F");
			}
			else if(Number == 7)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "F40");
			}
			else if(Number == 8)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "FF0");
			}
			else if(Number == 9)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "0F0");
			}
			else if(Number == 10)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "0A8");
			}
			else if(Number == 11)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "0FF");
			}
			else if(Number == 12)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "00F");
			}
			else if(Number == 13)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "F0F");
			}
			else if(Number == 14)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "555");
			}
			else if(Number == 15)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "AAA");
			}
			else if(Number > 15)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "");
			}
		}
		else if(game == TF2 || game == CSTRIKE || game == HL2DM)
		{
			if(Number == 0)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "FFFFFF");
			}
			else if(Number == 1)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "111111");
			}
			else if(Number == 2)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "0000CC");
			}
			else if(Number == 3)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "00BB00");
			}
			else if(Number == 4)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "FF0000");
			}
			else if(Number == 5)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "CC3333");
			}
			else if(Number == 6)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "8800FF");
			}
			else if(Number == 7)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "FF4400");
			}
			else if(Number == 8)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "FFFF00");
			}
			else if(Number == 9)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "00FF00");
			}
			else if(Number == 10)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "00AA88");
			}
			else if(Number == 11)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "00FFFF");
			}
			else if(Number == 12)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "0000FF");
			}
			else if(Number == 13)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "FF00FF");
			}
			else if(Number == 14)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "555555");
			}
			else if(Number == 15)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "AAAAAA");
			}
			else if(Number > 15)
			{
				ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "");
			}
		}
		else
		{
			ReplaceStringEx(Copy, sizeof(Copy), matchedTag2, "");
		}
		
		ReplaceStringEx(str, maxlength, matchedTag, Copy);
	}
}

