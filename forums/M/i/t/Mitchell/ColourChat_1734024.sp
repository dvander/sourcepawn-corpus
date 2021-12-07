#include <regex>
#include <scp>
new const String:PLUGIN_VERSION[10] = "1.0.0";
new Handle:hRegex;
public Plugin:myinfo =
{
	name = "[Any] Arbitrary Chat Colours",
	author = "DarthNinja",
	description = "Colours!  Everywhere!",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("chatcolours_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY);
}
//Using Simple Chat Processor
public Action:OnChatMessage(&client, Handle:recipients, String:name[], String:message[])
{
	if (!CheckCommandAccess(client, "chat_colour_override", 0, true))
		return Plugin_Continue;	//No access, so leaf it alone
		
	decl String:matchedTag[64];
	decl String:Copy[64];
	hRegex = CompileRegex("(#[A-Fa-f0-9]{6})");
	while (MatchRegex(hRegex, message) > 0)
	{
		GetRegexSubString(hRegex, 0, matchedTag, sizeof(matchedTag));
		new location = StrContains(message, matchedTag);
		if (location == -1)
			break; // Something bad happened, run away!

		strcopy(Copy, sizeof(Copy), matchedTag);
		ReplaceStringEx(Copy, sizeof(Copy), "#", "\x07");
		ReplaceStringEx(message, MAXLENGTH_MESSAGE, matchedTag, Copy);
	}
	//CloseHandle(hRegex);
	return Plugin_Changed;
}