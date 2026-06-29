#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.00"

public Plugin myinfo = 
{
	name = "Name of plugin here!", 
	author = "Your name here!", 
	description = "Brief description of plugin functionality here!", 
	version = PLUGIN_VERSION, 
	url = "Your website URL/AlliedModders profile URL"
};

public void OnPluginStart()
{
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
}
public void OnMapStart()
{
	AddFileToDownloadsTable("sound/message.mp3");
	PrecacheSound("sound/message.mp3", true);
}

public Action Command_Say(int client, const char[] command, int args)
{
	char szName[32];
	char symbol[5];
	bool started = false;
	char buffer[128];
	char szText[128];
	GetCmdArgString(buffer, sizeof(buffer));
	GetCmdArgString(szText, sizeof(szText));
	StripQuotes(szText);
	int itemp;
	Format(szText, sizeof(szText), "%s .", szText);
	for (int i = sizeof(szText) - 1; i >= 0; i--)
	{
		itemp = sizeof(szText) - i - 1;
		Format(symbol, sizeof(symbol), "%c", szText[itemp]);
		if (StrEqual(symbol, "&"))
		{
			started = true;
			continue;
		}
		if (started)
		{
			if (!StrEqual(symbol, " "))
			{
				Format(szName, sizeof(szName), "%s%s", szName, symbol);
			} else {
				break;
			}
		}
	}
	
	if (szName[0])
	{
		
		int target = target = FindTarget(client, szName, false, false);
		if (target != -1)
		{
			PrintToChat(client, " \x04Označil jsi \x0B%N", target);
			PrintToChat(target, " \x04Označil tě \x0B%N", client);
			ClientCommand(target, "play message.mp3");
		}
	}
} 