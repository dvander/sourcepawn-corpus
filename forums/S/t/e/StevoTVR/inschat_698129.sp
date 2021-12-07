#pragma semicolon 1
#include <sourcemod>
 
public Plugin:myinfo =
{
	name = "Insurgency Chat",
	author = "Stevo.TVR",
	description = "Enables logging of Insurgency chat messages and converts it to regular chat that plugins recognize",
	version = "1.3",
	url = "http://www.theville.org/"
};

#define CHAT_SYMBOL '@'

new Handle:g_logEnable;
 
public OnPluginStart()
{
	g_logEnable = CreateConVar("inschat_logging", "1", "Enable logging of chat", _, true, 0.0, true, 1.0);
	RegConsoleCmd("say2", Command_Say);
	RegServerCmd("say", Server_Say);
}

public Action:Command_Say(client, args)
{
	new String:text[192], String:cmd[16], String:name[MAX_NAME_LENGTH], String:steamid[64], String:team[32];
	new startidx = 4;
	
	if (GetCmdArgString(text, sizeof(text)) < 1 || client == 0)
	{
		return Plugin_Continue;
	}
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx += 1;
	}
	
	if (text[0] == '1')
	{
		cmd = "say";
	}
	else
	{
		cmd = "say_team";
	}
	
	GetClientName(client, name, sizeof(name));
	GetClientAuthString(client, steamid, sizeof(steamid));
	switch (GetClientTeam(client))
	{
		case 1:
		{
			team = "U.S. Marines";
		}
		case 2:
		{
			team = "Iraqi Insurgents";
		}
		default:
		{
			team = "Unassigned";
		}
	}
	
	if (GetConVarBool(g_logEnable))
	{
		LogToGame("\"%s<%i><%s><%s>\" %s \"%s\"", name, GetClientUserId(client), steamid, team, cmd, text[startidx]);
	}
	FakeClientCommandEx(client, "%s %s", cmd, text[startidx]);
	
	if (text[startidx] == CHAT_SYMBOL || IsChatTrigger())
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:Server_Say(args)
{
	new String:text[192];
	new startidx = 0;
	
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx += 1;
	}
		
	PrintToChatAll("Console: %s", text[startidx]);
		
	return Plugin_Handled;
}
