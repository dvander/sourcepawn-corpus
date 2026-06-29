
#include <regex>
Regex regex



public Plugin myinfo = 
{
	name = "[Synergy] banid reformat",
	author = "Bacardi",
	description = "Replace STEAM2 format to STEAM3 on banid command",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};


enum {
	regex_steam2 = 0,	// whole STEAM2 ID
	regex_steam_prefix,	// STEAM_
	regex_steam_id,		// 0 or 1
	regex_steam_number	// steam number
}


public void OnPluginStart()
{
	AddCommandListener(banid, "banid");
	AddCommandListener(banid, "kickid");

	//regex       \b(STEAM_)\d:([0-1]):(\d{1,10})\b
	char error[255];
	RegexError errcode;
	regex = new Regex("\\b(STEAM_)\\d:([0-1]):(\\d{1,10})\\b", _, error, sizeof(error), errcode);

	if(errcode != REGEX_ERROR_NONE)
		SetFailState("Fail %s , code: %i", error, errcode);
}

public Action banid(int client, const char[] command, int argc)
{
	if(argc < 1) // character colon (:) is splitting command argument in multiple pieces
		return Plugin_Continue;

	char arg[255];
	GetCmdArgString(arg, sizeof(arg));
	//PrintToServer("arg %s", arg);

	char buffer[255];
	strcopy(buffer, sizeof(buffer), arg);

	RegexError errcode;

	int captures = regex.Match(buffer, errcode);

	if(captures < 1)
	{
		if(captures == -1)
		{
			LogError("regex.Match failed -1: %s , errcode: %i", buffer, errcode);
		}

		return Plugin_Continue;
	}

	char steam2[25];

	// get Steam2 for search string
	if(!regex.GetSubString(regex_steam2, steam2, sizeof(steam2)))
		return Plugin_Continue;

	//PrintToServer("regex_steam2 %s, %i", steam2, captures);


	if(!regex.GetSubString(regex_steam_id, buffer, sizeof(buffer)))
		return Plugin_Continue;

	//PrintToServer("regex_steam_id %s, %i", buffer, captures);
	int y = StringToInt(buffer);


	if(!regex.GetSubString(regex_steam_number, buffer, sizeof(buffer)))
		return Plugin_Continue;

	//PrintToServer("regex_steam_number %s, %i", buffer, captures);
	int z = StringToInt(buffer);


	z = z * 2 + y; // convert Steam2 to Steam3, STEAM_X:y:z -> [U:1:z]

	Format(buffer, sizeof(buffer), "[U:1:%d]", z);

	// Match and replace one steam2 only, from command banid argument
	if(ReplaceString(arg, sizeof(arg), steam2, buffer, true) != 1)
		return Plugin_Continue;


	LogMessage("  %s STEAMID type converted: (%s -> %s)", command, steam2, buffer);

	ServerCommand("%s %s", command, arg);

	return Plugin_Handled;
}
