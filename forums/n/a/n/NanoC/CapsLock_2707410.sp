#pragma semicolon 1

#include <sourcemod>
#include <chat-processor>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION		"1.1.1"

public Plugin myinfo = 
{
	name		= "[ANY] Anti Caps Lock",
	author		= "Dr. McKay, Nano",
	description	= "Forces text to lowercase when too many caps are used",
	version		= PLUGIN_VERSION,
	url			= ""
};

ConVar g_cvarPctRequired;
ConVar g_cvarMinLength;
ConVar g_cvarUsingSymbols;

public void OnPluginStart() 
{
	g_cvarPctRequired = CreateConVar("anti_caps_lock_percent", "0.1", "Force all letters to lowercase when this percent of letters is uppercase", _, true, 0.0, true, 1.0);
	g_cvarMinLength = CreateConVar("anti_caps_lock_min_length", "2", "Only force letters to lowercase when a message has at least this many letters", _, true, 0.0);
	g_cvarUsingSymbols = CreateConVar("anti_caps_lock_using_symbols", "1", "Force all letters to lowercase ONLY if they have ! or / at the beginning (for sourcemod cmds) | 1 enabled - 0 disabled");
}

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool & processcolors, bool & removecolors)
{
	int letters, uppercase, length = strlen(message);
	for(int i = 0; i < length; i++) 
	{
		if(g_cvarUsingSymbols.IntValue == 1)
		{
			if(message[0] == '!' || message[1] == '!')
			{
				if(message[i] >= 'A' && message[i] <= 'Z') 
				{
					uppercase++;
					letters++;
				}
				else if(message[i] >= 'a' && message[i] <= 'z') 
				{
					letters++;
				}
			}
		}
		else if(g_cvarUsingSymbols.IntValue == 0)
		{
			if(message[i] >= 'A' && message[i] <= 'Z') 
			{
				uppercase++;
				letters++;
			}
			else if(message[i] >= 'a' && message[i] <= 'z') 
			{
				letters++;
			}
		}
	}

	if(letters >= GetConVarInt(g_cvarMinLength) && float(uppercase) / float(letters) >= GetConVarFloat(g_cvarPctRequired)) 
	{
		for(int i = 0; i < length; i++) 
		{
			if(message[i] >= 'A' && message[i] <= 'Z') 
			{
				message[i] = CharToLower(message[i]);
			}
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}