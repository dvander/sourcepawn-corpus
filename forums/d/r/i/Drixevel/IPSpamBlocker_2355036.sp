#pragma semicolon 1

#include <sourcemod>
#include <Regex>

Handle hRegex;

public Plugin myinfo = 
{
	name = "IP Spam Blocker",
	author = "Keith Warren (Drixevel)",
	description = "Blocks IPs from being spammed everywhere.",
	version = "1.0.0",
	url = "http://www.drixevel.com/"
};

public void OnPluginStart()
{
	HookEvent("player_changename", OnNameChange);
	
	AddCommandListener(Command_SayChat, "say");
	AddCommandListener(Command_SayChat, "say_team");
	
	hRegex = CompileRegex("\\d+\\.\\d+\\.\\d+\\.\\d+(:\\d+)?");
}

public Action Command_SayChat(int client, const char[] command, int argc)
{
	char text[255];
	GetCmdArgString(text, sizeof(text));
	
	if (MatchRegex(hRegex, text) > 0)
	{
		LogAction(client, -1, "IP has been blocked in chat.");
		return Plugin_Handled;				
	}
	
	return Plugin_Continue;
}

public Action OnNameChange(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		char sNewName[MAX_NAME_LENGTH];
		GetEventString(event, "newname", sNewName, sizeof(sNewName));
		
		if (MatchRegex(hRegex, sNewName) > 0)
		{
			LogAction(client, -1, "IP has been blocked in name, user kicked.");
			KickClient(client, "Please don't post an IP in your name.");
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	char sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName));
	
	if (MatchRegex(hRegex, sName) > 0)
	{
		LogAction(client, -1, "IP has been blocked in name, user kicked on connect.");
		KickClient(client, "Remove the IP from your name and reconnect.");
	}
}