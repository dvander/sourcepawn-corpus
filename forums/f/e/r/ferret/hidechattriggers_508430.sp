/**
 * hidechattriggers.sp
 * Lets you specify a list of chat messages to not display
 * This file is part of SourceMod, Copyright (C) 2004-2007 AlliedModders LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * Version: $Id$
 */

#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Hide Chat Triggers",
	author = "AlliedModders LLC",
	description = "Block chat commands from displaying",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
};

/* Handles to convars used by plugin */
new Handle:g_TriggerList = INVALID_HANDLE;
new bool:g_INS = false;

public OnPluginStart()
{
	g_TriggerList = CreateArray(64);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
		
	decl String:modname[64];
	GetGameFolderName(modname, sizeof(modname));
	
	if (strcmp(modname, "ins") == 0)
	{
		g_INS = true;
		RegConsoleCmd("say2", Command_Say);
	}	
	
}

stock bool:IsValidCvarChar(c)
{
	return (c == '_' || IsCharAlpha(c) || IsCharNumeric(c));
}

public OnConfigsExecuted()
{
	decl String:path[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, path, sizeof(path), "configs/chattriggers.txt");
	
	new Handle:file = OpenFile(path, "rt");
	
	if (file == INVALID_HANDLE)
	{
		LogError("[SM] Could not open file: %s", path);
		return;
	}
	
	decl String:buffer[255];
	while (!IsEndOfFile(file) && ReadFileLine(file, buffer, sizeof(buffer)))
	{
		TrimString(buffer);
		if (buffer[0] == '\0' || !IsValidCvarChar(buffer[0]))
		{
			continue;
		}

		PushArrayString(g_TriggerList, buffer);
	}
	
	CloseHandle(file);
}

public Action:Command_Say(client, args)
{	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	new startidx;
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if (g_INS)
	{
		startidx += 4;
	}
	
	decl String:trigger[192];
	BreakString(text[startidx], trigger, sizeof(trigger));
	
	decl String:hidden[64];
	new count = GetArraySize(g_TriggerList);
	for (new i = 0; i < count; i++)
	{
		GetArrayString(g_TriggerList, i, hidden, sizeof(hidden));
		if (strcmp(trigger, hidden, false) == 0)
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;	
}