/**
 * cvarhider.sp
 * Lets you hide cvars through addons/sourcemod/configs/hiddencvars.txt
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
	name = "Cvar Hider",
	author = "AlliedModders LLC",
	description = "Hides public CVARs",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
};

/* Handles to convars used by plugin */
new Handle:g_CvarList = INVALID_HANDLE;

public OnPluginStart()
{
	g_CvarList = CreateArray();
}

stock bool:IsValidCvarChar(c)
{
	return (c == '_' || IsCharAlpha(c) || IsCharNumeric(c));
}

public OnConfigsExecuted()
{
	decl String:path[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, path, sizeof(path), "configs/hiddencvars.txt");
	
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
		new Handle:hndl = FindConVar(buffer);
		if (hndl == INVALID_HANDLE)
		{
			continue;
		}
		PushArrayCell(g_CvarList, hndl);
	}
	CloseHandle(file);
	
	HideConVars();
}

public OnPluginEnd()
{
	ShowConVars();
}

HideConVars()
{
	new count = GetArraySize(g_CvarList);
	for (new i=0; i<count; i++)
	{
		new Handle:hndl = GetArrayCell(g_CvarList, i);
		/* In case the cvar was unloaded by Metamod! */
		if (!IsValidHandle(hndl))
		{
			continue;
		}
		new flags = GetConVarFlags(hndl);
		flags &= ~FCVAR_NOTIFY;
		SetConVarFlags(hndl, flags);
	}
}

ShowConVars()
{
	new count = GetArraySize(g_CvarList);
	for (new i=0; i<count; i++)
	{
		new Handle:hndl = GetArrayCell(g_CvarList, i);
		/* In case the cvar was unloaded by Metamod! */
		if (!IsValidHandle(hndl))
		{
			continue;
		}
		new flags = GetConVarFlags(hndl);
		flags |= FCVAR_NOTIFY;
		SetConVarFlags(hndl, flags);
	}
}
