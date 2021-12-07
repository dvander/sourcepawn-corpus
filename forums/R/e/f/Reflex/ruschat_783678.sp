/*
	Written by Reflex (rereflex@gmail.com)
	Thanks to AngelX
*/

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo =
{
	name		= "Russian Chat",
	author		= "Reflex",
	description	= "Adds Cyrillics support in game chat",
	version		= PLUGIN_VERSION,
	url			= "http://www.sourcemod.net/showthread.php?t=87942"
};

public OnPluginStart()
{
	RegConsoleCmd("say",      Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public Action:Command_Say(client, args)
{
	decl String:text[256];
	if (GetCmdArgString(text, sizeof(text)) < 1) return Plugin_Continue;
	if (CyrrilycReplase(text))
	{
	    decl String:command[32];
	    GetCmdArg(0, command, sizeof(command));
	    FakeClientCommandEx(client, "%s %s", command, text);  
	    return Plugin_Stop;
	}
	return Plugin_Continue;
}

bool:CyrrilycReplase(String:text[])
{
	new bool:IsRussian = false;
	new textlen = strlen(text) - 1;
	for (new i = 0; i <= textlen; i++)
	{
		if (GetCharBytes(text[i]) == 2)
		{
			if ((text[i] == 0xc3) && (text[i+1] > 0x7f) && (text[i+1] < 0xc0))
			{
				if (text[i+1] > 0xaf)
				{
					text[i]   += 0xe;
					text[i+1] -= 0x30;			
				} else {
					text[i]   += 0xd;
					text[i+1] += 0x10;
				}
				IsRussian = true;
			}	// fix some kb layouts
			else if ((text[i] == 0xc2)
				&& (text[i+1] == 0xbf))
			{
				text[i]   = 0xd1;
				text[i+1] = 0x8a;
				IsRussian = true;
			}
			else if ((text[i] == 0xc2)
				&& (text[i+1] == 0xaf))
			{
				text[i]   = 0xd0;
				text[i+1] = 0xaa;
				IsRussian = true;
			}
			else if ((text[i] == 0xc2)
				&& (text[i+1] == 0xba))
			{
				text[i]   = 0xd1;
				text[i+1] = 0x8d;
				IsRussian = true;
			}
			else if ((text[i] == 0xc2)
				&& (text[i+1] == 0xaa))
			{
				text[i]   = 0xd0;
				text[i+1] = 0xad;
				IsRussian = true;
			}
			else if ((text[i] == 0xc2)
				&& (text[i+1] == 0xb3))
			{
				text[i]   = 0xd1;
				text[i+1] = 0x8b;
				IsRussian = true;
			}
			else if ((text[i] == 0xc2)
				&& (text[i+1] == 0xb2))
			{
				text[i]   = 0xd0;
				text[i+1] = 0xab;
				IsRussian = true;
			}
			else if ((text[i] == 0xc2)
				&& (text[i+1] == 0xb8))
			{
				text[i]   = 0xd1;
				text[i+1] = 0x91;
				IsRussian = true;
			}
			else if ((text[i] == 0xc2)
				&& (text[i+1] == 0xa8))
			{
				text[i]   = 0xd0;
				text[i+1] = 0x81;
				IsRussian = true;
			}
			i++;	// because GetCharBytes() return 2
		}
	}
	return IsRussian;
}