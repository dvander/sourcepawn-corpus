#pragma semicolon 1

#include <sourcemod>
#include <regex>

new Handle:ipRegex = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Block ip in chat",
	author = "MegoltElek",
	description = "Block ip in chat",
	version = "1.0",
	url = "https://steamcommunity.com/id/megoltelekhun/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("say", check_ip);
	RegConsoleCmd("say_team", check_ip);
	ipRegex = CompileRegex("\\d+\\D+\\d+\\D+\\d+\\D+\\d+");
}

public Action:check_ip(client, args)
{	
	if (client > 0 && (GetUserFlagBits(client) <= 0)){
		decl String:chat_text[192];
		GetCmdArgString(chat_text, sizeof(chat_text));
		if (MatchRegex(ipRegex, chat_text) > 0) {			
			GetRegexSubString(ipRegex, 0, chat_text, 32);			
			LogAction(client, -1, "IP in chat got blocked!");
			return Plugin_Handled; 
		} 			
	}
	return Plugin_Continue;	
}