#pragma semicolon 1
#include <sourcemod>
#include <voiceware>
 
#define LANGUAGE "en" // language voice used

public Plugin myinfo =
{
	name = "SM Chat text to voice",
	description = "Text to voice",
	author = "Franc1sco franug",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	RegConsoleCmd("say", Say);
}
 
public Action Say(int client, int args)
{
	if (client!=0)
	{
		char buffer[255];
		GetCmdArgString(buffer,sizeof(buffer));
		StripQuotes(buffer);
		VoiceWareToAll(LANGUAGE, buffer);
	}  
	return Plugin_Continue;
}