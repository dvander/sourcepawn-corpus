#include <sourcemod>

#pragma semicolon 1

public Plugin myinfo = {
	name        = "Block words",
	author      = "TheUnderTaker",
	description = "Block words",
	version     = "1.0",
	url         = "http://steamcommunity.com/id/theundertaker007/"
};

public void OnPluginStart()
{
	AddCommandListener(OnSay, "say");
	AddCommandListener(OnSay, "say_team");
}

public Action:OnSay(client, const String:command[], args)
{
	new String:text[4096];
	GetCmdArgString(text, 4096);
	StripQuotes(text);
	if (StrEqual(text, "#spec_help_text #spec_duck"))
	{
		decl String:Buffer[100];
		Format(Buffer, sizeof(Buffer),  "");
		GotOpposedString("#spec_help_text #spec_duck", Buffer, sizeof(Buffer));
	}
}

stock void GotOpposedString(const char[] original, char[] opposite, int maxlength)
{
 if (strlen(original)+1 > maxlength)
  LogError("So small buffer for opposite string. Original string length %d. Buffer length %d. String will cut off.", strlen(original)+1, maxlength);
 int nullpos = (strlen(original)+1 > maxlength) ? maxlength-1 : strlen(original);
 opposite[nullpos] = '\0';
 for (int i = 0; i != nullpos; i++)
  opposite[i] = original[nullpos-1-i];
}