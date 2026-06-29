/*
Swear/Caps Filter/Replacement
Hell Phoenix & Calystos
http://www.charliemaurice.com/plugins

This plugin is based on kaboomkazoom's amxx swear replacement plugin. It allows you to do 3 different replacement
modes. It also sends a warning to the user that foul language is not allowed. It also checks a players name to 
make sure that it doesnt have any bad words in it.

Mode 1 replaces what the user said with a random phrase.
Mode 2 shows just **** (or whatever you set the cvar to) instead of the word (filters it)
Mode 3 doesnt display the users chat at all


Versions:
	1.0
		* First Public Release!
	1.1
		* Added Insurgency Mod Support!
		* Added Cvar to turn off name checking
		* Added custom word replacement (use mode 2)
		* Changed Maxplayers from a define to GetMaxClients();
		* Log now only logs the original message
		* Team say now stays in the team chat instead of getting moved to global chat
	1.2
		* Fixed some errors from the console/log
	1.3
		* Fixed crashing
	1.4
		* Fixed a major loop that caused crashes sometimes (thanks Bailopan)
	1.5
		* Fixed ReplaceString empty string error
		* Added option to ignore team chat filtering
		* Added option to filter ALL CAPS chat
		* Using colors.inc to display team based colored chat
		* Added SPEC/DEAD output to say chat to make it look legit
	1.5.2
		* Added autoconfig system.
		* Added non-swear ALL CAPS chat filter

Todo:

Notes:
	The client name doesnt appear in the team color for any mod other than Insurgency. Not sure this will ever be possible 
	to fix.	The only thing you can do if you dont want the persons name to show up all white is to use mode 3 and not 
	allow it to show at all.

	Make sure that badwords.txt and replacements.txt are in your sourcemod/configs/ directory!

Cvarlist (default value):
	sm_swear_replace_mode 1 <1|2|3> are valid options
	sm_swear_name_check 1 <0|1> are valid options
	sm_swear_replace **** <change this to whatever string you want to replace the word if you dont want stars (for mode 2)>

Admin Commands:
	None
*/

#include <sourcemod>
#include <colors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.5.2"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Swear/Caps Filter/Replacement",
	author = "Hell Phoenix (Modded by Calystos)",
	description = "Swear Replacement",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
};

#define MAX_WORDS	200
#define MAX_REPLACE	50
#define MAX_LINE_LENGTH	192 // maximum length of a single line of text

new Handle:cvarswearmode;
new Handle:cvarswearname;
new Handle:cvarswearreplace;
new Handle:cvarfilterteam;
new Handle:cvarfiltercaps;
new Handle:g_minAlphaCount = INVALID_HANDLE; // minimum amount of alphanumeric characters
new Handle:g_maxPercent = INVALID_HANDLE; // Maximum percent of characters thay may be uppercase

new String:badwordfile[PLATFORM_MAX_PATH];
new String:replacefile[PLATFORM_MAX_PATH];
new String:g_swearwords[MAX_WORDS][32];
new String:g_replaceLines[MAX_REPLACE][191];
new MAX_PLAYERS;
new g_swearNum;
new g_replaceNum;
new capsfound;

public OnPluginStart()
{
	CreateConVar("sm_swearreplace_version", PLUGIN_VERSION, "Swear Replace Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarswearmode = CreateConVar("sm_swear_replace_mode", "2", "Options are 1 (replace), 2 (stars), or 3 (eat the text).", FCVAR_PLUGIN);
	cvarswearname = CreateConVar("sm_swear_name_check", "0", "1 is on, 0 is off.", FCVAR_PLUGIN);
	cvarswearreplace = CreateConVar("sm_swear_replace", "*BEEP*", "You can use any word here...this is what replaces the swear word in mode 2", FCVAR_PLUGIN);
	cvarfilterteam = CreateConVar("sm_swear_filterteam", "1", "Shall we filter team chat as well, or just public chat?", FCVAR_PLUGIN);
	cvarfiltercaps = CreateConVar("sm_swear_filtercaps", "1", "Shall we filter ALL CAPS in chat?", FCVAR_PLUGIN);
	g_maxPercent = CreateConVar("sm_shout_percent", "0.7", "Percent of alphanumeric characters that need to be uppercase before the plugin will kick in.", 0, true, 0.01, true, 1.0);
	g_minAlphaCount = CreateConVar("sm_shout_mincharcount", "5", "Minimum amount of alphanumeric characters before the sentence will be altered.");

	AutoExecConfig(true, "swear_replacement");

	// FakeClientCommand(client, "say trollolollolol");
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_InsurgencySay);
	RegConsoleCmd("say_team", Command_TeamSay);
}

public OnMapStart()
{
	CreateTimer(0.1, Read_Files);
	MAX_PLAYERS = GetMaxClients();
}

public OnMapEnd()
{
	g_swearNum = 0;
	g_replaceNum = 0;
}

public Action:Read_Files(Handle:timer)
{
	BuildPath(Path_SM, badwordfile, sizeof(badwordfile), "configs/badwords.txt");
	BuildPath(Path_SM, replacefile, sizeof(replacefile), "configs/replacements.txt");
	if (!FileExists(badwordfile))
	{
		LogMessage("badwords.txt not parsed...file doesnt exist!");
	}
	else
	{
		new Handle:badwordshandle = OpenFile(badwordfile, "r");
		new i = 0;
		while ( i < MAX_WORDS && !IsEndOfFile(badwordshandle))
		{
			ReadFileLine(badwordshandle, g_swearwords[i], sizeof(g_swearwords[]));
			TrimString(g_swearwords[i]);
			i++;
			g_swearNum++;
		}
		CloseHandle(badwordshandle);
	}
	
	if (!FileExists(replacefile))
	{
		LogMessage("replacements.txt not parsed...file doesnt exist!");
	}
	else
	{
		new Handle:replacehandle = OpenFile(replacefile, "r");
		new i = 0;
		while ( i < MAX_WORDS && !IsEndOfFile(replacehandle))
		{
			ReadFileLine(replacehandle, g_replaceLines[i], sizeof(g_replaceLines[]));
			TrimString(g_replaceLines[i]);
			i++;
			g_replaceNum++;
		}	
		CloseHandle(replacehandle);	
	}
}

public OnClientPutInServer(client)
{
	if (GetConVarInt(cvarswearname) == 1)
	{
		if (client != 0)
		{
			decl String:clientName[64];
			GetClientName(client, clientName, 64);
			string_cleaner(clientName, sizeof(clientName));
			
			new i = 0;
			while (i < g_swearNum)
			{
				if (!StrEqual(g_swearwords[i], "") && StrContains(clientName, g_swearwords[i], false) != -1 )
				{
					LogMessage("[Swear Replacement] Named changed from %s", clientName);
					ClientCommand(client, "name %s", "IhadaBadName");
				}
				i++;
			}	
		}
	}
}

public OnClientSettingsChanged(client)
{
	if (GetConVarInt(cvarswearname) == 1)
	{
		if (client != 0)
		{
			decl String:clientName[64];
			GetClientName(client, clientName, 64);
			string_cleaner(clientName, sizeof(clientName));
			
			new i = 0;
			while (i < g_swearNum)
			{
				if (!StrEqual(g_swearwords[i], "") && StrContains(clientName, g_swearwords[i], false) != -1 )
				{
					LogMessage("[Swear Replacement] Named changed from %s", clientName);
					ClientCommand(client, "name %s", "IhadaBadName");
				}
				i++;
			}	
		}
	}
}

public Action:Command_Say(client, args)
{
	if (client != 0)
	{
		decl String:speech[191];
		decl String:clientname[64];
		GetClientName(client, clientname, 64);
		GetCmdArgString(speech, sizeof(speech));

		new startidx = 0;
		if (speech[0] == '"')
		{
			startidx = 1;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"')
			{
				speech[len-1] = '\0';
			}
		}

		decl String:originalstring[191];
		strcopy(originalstring, sizeof(speech), speech[startidx]);
		string_cleaner(speech[startidx], sizeof(speech) - startidx);

		new i = 0;
		new found;
		while (i < g_swearNum)
		{
			if (!StrEqual(g_swearwords[i], "") && StrContains(speech[startidx], g_swearwords[i], false) != -1 )
			{
				new String:replacement[32];
				GetConVarString(cvarswearreplace, replacement, 32);
				ReplaceString(speech, strlen(speech), g_swearwords[i], replacement, false);
				found = true;
			}
			i++;
		}

		decl String:prestr[10];
		prestr[0] = '\0';
		if (found)
		{
 			if (GetClientTeam(client) == 1) Format(prestr, sizeof(prestr), "*SPEC* ");
			else if (!IsPlayerAlive(client)) Format(prestr, sizeof(prestr), "*DEAD* ");

			LogMessage("[Swear Replacement] %s : %s", clientname, originalstring);
			if (GetConVarInt(cvarswearmode) == 1)
			{
				new random_replace = GetRandomInt(0, g_replaceNum);
				strcopy(speech[startidx], sizeof(g_replaceLines[]), g_replaceLines[random_replace]);
				CPrintToChatAllEx(client, "%s{teamcolor}%s{default} :  %s", prestr, clientname, speech[startidx]);
				CPrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
			else if (GetConVarInt(cvarswearmode) == 2)
			{
				CPrintToChatAllEx(client, "%s{teamcolor}%s{default} :  %s", prestr, clientname, speech[startidx]);
				CPrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
			else if (GetConVarInt(cvarswearmode) == 3)
			{
				CPrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
		}
		if (capsfound)
		{
			CPrintToChatAllEx(client, "%s{teamcolor}%s{default} :  %s", prestr, clientname, speech[startidx]);
			return Plugin_Handled;
		}
		
	}
	return Plugin_Continue;
}

public Action:Command_TeamSay(client, args)
{
	if (client != 0)
	{
		decl String:speech[191];
		decl String:clientname[64];
		GetClientName(client, clientname, 64);
		GetCmdArgString(speech, sizeof(speech));
		
		new startidx = 0;
		if (speech[0] == '"')
		{
			startidx = 1;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"')
			{
					speech[len-1] = '\0';
			}
		}
		decl String:originalstring[191];
		strcopy(originalstring, sizeof(speech), speech[startidx]);

		string_cleaner(speech[startidx], sizeof(speech) - startidx);

		// Do we want to filter private/team chat?
		if (GetConVarInt(cvarfilterteam) == 0) return Plugin_Continue;

		new i = 0;
		new found;
		while (i < g_swearNum)
		{
			if (!StrEqual(g_swearwords[i], "") && StrContains(speech[startidx], g_swearwords[i], false) != -1 )
			{
				new String:replacement[32];
				GetConVarString(cvarswearreplace, replacement, 32);
				ReplaceString(speech, strlen(speech), g_swearwords[i], replacement, false);
				found = true;
			}
			i++;
		}

		decl String:prestr[10];
		prestr[0] = '\0';
		if (found)
		{
 			if (GetClientTeam(client) == 1) Format(prestr, sizeof(prestr), "(Spectator) {teamcolor}");
			else if (!IsPlayerAlive(client)) Format(prestr, sizeof(prestr), "{teamcolor}*DEAD* ");
			else Format(prestr, sizeof(prestr), "{teamcolor}");

			LogMessage("[Swear Replacement] %s : %s", clientname, originalstring);
			if (GetConVarInt(cvarswearmode) == 1)
			{
				new random_replace = GetRandomInt(0, g_replaceNum);
				strcopy(speech[startidx], sizeof(g_replaceLines[]), g_replaceLines[random_replace]);
				for (new j = 1; j < MAX_PLAYERS; j++)
				{
					if (IsClientConnected(j))
					{
						if (GetClientTeam(j) == GetClientTeam(client))
						{
							CPrintToChat(j, "%s%s :  %s", prestr, clientname, speech[startidx]);
						}
					}
				}
				CPrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
			else if (GetConVarInt(cvarswearmode) == 2)
			{
				for (new j = 1; j < MAX_PLAYERS; j++)
				{
					if (IsClientConnected(j))
					{
						if (GetClientTeam(j) == GetClientTeam(client))
						{
							CPrintToChat(j, "%s%s :  %s", prestr, clientname, speech[startidx]);
						}
					}
				}
				CPrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
			else if (GetConVarInt(cvarswearmode) == 3)
			{
				CPrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
		}
		if (capsfound)
		{
			for (new j = 1; j < MAX_PLAYERS; j++)
			{
				if (IsClientConnected(j))
				{
					if (GetClientTeam(j) == GetClientTeam(client))
					{
						CPrintToChat(j, "%s%s :  %s", prestr, clientname, speech[startidx]);
					}
				}
			}
			return Plugin_Handled;
		}
		
	}
	return Plugin_Continue;
}

public Action:Command_InsurgencySay(client, args)
{
	if (client != 0)
	{
		decl String:speech[191];
		decl String:clientname[64];
		GetClientName(client, clientname, 64);
		GetCmdArgString(speech, sizeof(speech));
		
		new startidx = 0;
		if (speech[0] == '"')
		{
			startidx = 1;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"')
			{
					speech[len-1] = '\0';
			}
		}
		
		decl String:originalstring[191];
		strcopy(originalstring, sizeof(speech), speech[startidx]);
		string_cleaner(speech[startidx], sizeof(speech) - startidx);
		
		new i = 0;
		new found;
		while (i < g_swearNum)
		{
			if (!StrEqual(g_swearwords[i], "") && StrContains(speech[startidx], g_swearwords[i], false) != -1 )
			{
				new String:replacement[32];
				GetConVarString(cvarswearreplace, replacement, 32);
				ReplaceString(speech, strlen(speech), g_swearwords[i], replacement, false);
				found = true;
			}
			i++;
		}
		if (found)
		{
			LogMessage("[Swear Replacement] %s : %s", clientname, originalstring);
			if (GetConVarInt(cvarswearmode) == 1)
			{
				new random_replace = GetRandomInt(0, g_replaceNum);
				strcopy(speech[startidx], sizeof(g_replaceLines[]), g_replaceLines[random_replace]);
				ClientCommand(client, "say2 %s", speech[startidx]);
				CPrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
			else if (GetConVarInt(cvarswearmode) == 2)
			{
				ClientCommand(client, "say2 %s", speech[startidx]);
				CPrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
			else if (GetConVarInt(cvarswearmode) == 3)
			{
				CPrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
		}
		if (capsfound)
		{
			ClientCommand(client, "say2 %s", speech[startidx]);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public string_cleaner(String:str[], maxlength)
{
	if (GetConVarInt(cvarfiltercaps) == 1)
	{
		CheckStringForCaps(str);
	}
		
	new i, len = strlen(str);
	if (GetConVarInt(cvarswearmode) != 2)
	{
		ReplaceString ( str, maxlength, " ", "", false );
	}

	ReplaceString(str, maxlength, "|<", "k", false);
	ReplaceString(str, maxlength, "|>", "p", false);
	ReplaceString(str, maxlength, "()", "o", false);
	ReplaceString(str, maxlength, "[]", "o", false);
	ReplaceString(str, maxlength, "{}", "o", false);

	for (i = 0; i < len; i++)
	{
		if (str[i] == '@')
			str[i] = 'a';

		if (str[i] == '$')
			str[i] = 's';

		if (str[i] == '0')
			str[i] = 'o';

		if (str[i] == '7')
			str[i] = 't';

		if (str[i] == '3')
			str[i] = 'e';

		if (str[i] == '5')
			str[i] = 's';

		if (str[i] == '<')
			str[i] = 'c';

		if (GetConVarInt(cvarswearmode) != 2)
		{
			if (str[i] == '3')
				str[i] = 'e';
		}
		
	}
}

/*
 * Converts a string entirely to lowercase characters
 * @param arg		Text to convert to lowercase
 */
public StrToLower(String:arg[])
{
	for (new i = 0; i < strlen(arg); i++)
	{
		arg[i] = CharToLower(arg[i]);
	}
}

/*
 * Calls the GetClientName() function, but replaces the name of client 0 (the console)
 * with a small piece of text, instead of the entire server name.
 */
public ClientName(client, String:name[MAX_NAME_LENGTH])
{
	if (client == 0)
	{
		name = "[console]";
	}
	else
	{
		GetClientName(client, name, sizeof(name));
	}
}

/*
 * Copies a part of a string to a new string.
 * @param text			Source text from which the characters are copies
 * @param result		Destionation string
 * @param startIndex	Position in the source string at which copying will start. Zero based.
 * @param endIndex		Position in the source string at which copying will end. This means the character specified by the end
 index is NOT copied.
 */
public SubString(const String:text[], String:result[], startIndex, endIndex)
{
	// check input
	new length = endIndex - startIndex;
	if (length <= 0 || startIndex >= strlen(text))
	{
		return;
	}
	
	// perform char-by-char copy
	for (new index = 0; index < length; index++)
	{
		result[index] = text[index + startIndex];
	}

	// add termination character	
	result[length] = '\0';
}

public CheckStringForCaps(String:argString[])
{
	new upperCount = 0;			// total amount of upper text chars
	new totalCount = 0;			// total amount of text chars (no numeric or other chars)
	for (new i = 0; i < strlen(argString); i++)
	{
		if (IsCharAlpha(argString[i]))
		{
			totalCount++;
			if (IsCharUpper(argString[i]))
			{
				upperCount++;
			}
		}
	}
	
	// calculate percentage of characters that is uppercase & get convar values
	new Float:percentageUpper = float(upperCount) / float(totalCount);
	new Float:maxPercent = GetConVarFloat(g_maxPercent);
	new minCharCount = GetConVarInt(g_minAlphaCount);
	capsfound = false;
	
	if (totalCount >= minCharCount && percentageUpper >= maxPercent)
	{
		capsfound = true;
		// remove the surrounding quotes, if they are present
		if (argString[0] == '"' && argString[strlen(argString) - 1] == '"')
		{
			// bit of an ugly call to substring, but it'll always work here.
			SubString(argString, argString, 1, strlen(argString) - 1);
		}
		
		// replace all alphanumeric chars, except the first char
		for (new i = 1; i < strlen(argString); i++)
		{
			if (IsCharAlpha(argString[i]))
			{
				argString[i] = CharToLower(argString[i]);
			}
		}
	}
}
