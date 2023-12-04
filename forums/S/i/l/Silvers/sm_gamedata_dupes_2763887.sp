/*
*	GameData Dupe Keys Tester
*	Copyright (C) 2021 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"1.0"

/*======================================================================================
	Plugin Info:

*	Name	:	[ANY] GameData Dupe Keys Tester
*	Author	:	SilverShot
*	Descrp	:	Checks for duplicate keys within a GameData file.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=335270
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (20-Nov-2021)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define MAX_LEN_STRING 128 // Maximum length of section names

ArrayList g_alMemPatches;
ArrayList g_alFunctions;
ArrayList g_alAddresses;
ArrayList g_alOffsets;
ArrayList g_alSignatures;
ArrayList g_alKeys;

char g_sCurrentSection[MAX_LEN_STRING];
int g_iSectionIndex;
int g_iSectionLevel;
int g_iClientPrint;
int g_iDuplicates;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[ANY] GameData Dupe Keys Tester",
	author = "SilverShot",
	description = "Checks for duplicate keys within a GameData file.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=335270"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_gamedata_dupe", CmdDupe, ADMFLAG_ROOT, "[filename] (without the .txt extension). Check for duplicated entries. No args = check all .txt GameData files.");

	CreateConVar("sm_gamedata_dupe_version", PLUGIN_VERSION, "GameData Dupe Keys Tester plugin version.");
}

public Action CmdDupe(int client, int args)
{
	if( args == 1 )
	{
		char sPath[PLATFORM_MAX_PATH];
		GetCmdArg(1, sPath, sizeof(sPath));
		BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", sPath);

		if( FileExists(sPath) == false )
		{
			ReplyToCommand(client, "[SM] Missing file \"%s\"", sPath);
			return Plugin_Handled;
		}

		g_iSectionIndex = 0;
		g_iSectionLevel = 0;
		g_iDuplicates = 0;
		g_iClientPrint = client;

		ParseConfigFile(sPath);

		ReplyToCommand(client, "Duplicates found: %d.",  g_iDuplicates);
	} else {
		g_iClientPrint = client;

		char sFile[PLATFORM_MAX_PATH];
		char sPath[PLATFORM_MAX_PATH];
		char sTest[PLATFORM_MAX_PATH];
		GetCmdArg(1, sPath, sizeof(sPath));
		BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata");

		FileType type;
		DirectoryListing hDir = OpenDirectory(sPath, false, NULL_STRING);
		if( hDir == null )
		{
			ReplyToCommand(client, "Failed to open GameData folder.");
			return Plugin_Handled;
		}

		while( hDir.GetNext(sFile, sizeof(sFile), type) )
		{
			// Ignore "." and ".." and match ".txt" extension
			if( strcmp(sFile, ".") && strcmp(sFile, "..") && strcmp(sFile[strlen(sFile) - 4], ".txt") == 0 )
			{
				g_iSectionIndex = 0;
				g_iSectionLevel = 0;
				g_iDuplicates = 0;

				BuildPath(Path_SM, sTest, sizeof(sTest), "gamedata/%s", sFile);
				ParseConfigFile(sTest);

				if( g_iDuplicates )
				{
					ReplyToCommand(client, "GameData dupes: %d \"%s\"", g_iDuplicates, sFile);
					ReplyToCommand(client, "");
				}
			}
		}

		delete hDir;
	}

	return Plugin_Handled;
}

bool ParseConfigFile(const char[] file)
{
	SMCParser parser = new SMCParser();
	SMC_SetReaders(parser, GameData_NewSection, GameData_KeyValue, GameData_EndSection);
	parser.OnEnd = GameData_End;

	char error[128];
	int line = 0, col = 0;
	SMCError result = parser.ParseFile(file, line, col);

	if( result != SMCError_Okay )
	{
		parser.GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s [%d]", error, line, col, file, result);
	}

	delete parser;
	return (result == SMCError_Okay);
}

public SMCResult GameData_NewSection(Handle parser, const char[] section, bool quotes)
{
	g_iSectionLevel++;

	switch( g_iSectionLevel )
	{
		case 2:
		{
			strcopy(g_sCurrentSection, sizeof(g_sCurrentSection), section);
		}
		case 3:
		{
			g_iSectionIndex = 0;
			if( strcmp(section, "MemPatches", false) == 0 )		g_iSectionIndex = 1;
			if( strcmp(section, "Functions", false) == 0 )		g_iSectionIndex = 2;
			if( strcmp(section, "Addresses", false) == 0 )		g_iSectionIndex = 3;
			if( strcmp(section, "Offsets", false) == 0 )		g_iSectionIndex = 4;
			if( strcmp(section, "Signatures", false) == 0 )		g_iSectionIndex = 5;
			if( strcmp(section, "Keys", false) == 0 )			g_iSectionIndex = 6;

			switch( g_iSectionIndex )
			{
				case 1:		g_alMemPatches = new ArrayList(ByteCountToCells(MAX_LEN_STRING));
				case 2:		g_alFunctions = new ArrayList(ByteCountToCells(MAX_LEN_STRING));
				case 3:		g_alAddresses = new ArrayList(ByteCountToCells(MAX_LEN_STRING));
				case 4:		g_alOffsets = new ArrayList(ByteCountToCells(MAX_LEN_STRING));
				case 5:		g_alSignatures = new ArrayList(ByteCountToCells(MAX_LEN_STRING));
				case 6:		g_alKeys = new ArrayList(ByteCountToCells(MAX_LEN_STRING));
			}
		}
		case 4:
		{
			switch( g_iSectionIndex )
			{
				case 1:		if( g_alMemPatches.FindString(section) != -1 )		{ ReplyToCommand(g_iClientPrint, "Duplicate \"MemPatches\" in \"%s\": \"%s\"", g_sCurrentSection, section); g_iDuplicates++; }	else	g_alMemPatches.PushString(section);
				case 2:		if( g_alFunctions.FindString(section) != -1 )		{ ReplyToCommand(g_iClientPrint, "Duplicate \"Functions\"  in \"%s\": \"%s\"", g_sCurrentSection, section); g_iDuplicates++; }	else	g_alFunctions.PushString(section);
				case 3:		if( g_alAddresses.FindString(section) != -1 )		{ ReplyToCommand(g_iClientPrint, "Duplicate \"Addresses\"  in \"%s\": \"%s\"", g_sCurrentSection, section); g_iDuplicates++; }	else	g_alAddresses.PushString(section);
				case 4:		if( g_alOffsets.FindString(section) != -1 )			{ ReplyToCommand(g_iClientPrint, "Duplicate \"Offsets\"    in \"%s\": \"%s\"", g_sCurrentSection, section); g_iDuplicates++; }	else	g_alOffsets.PushString(section);
				case 5:		if( g_alSignatures.FindString(section) != -1 )		{ ReplyToCommand(g_iClientPrint, "Duplicate \"Signatures\" in \"%s\": \"%s\"", g_sCurrentSection, section); g_iDuplicates++; }	else	g_alSignatures.PushString(section);
				case 6:		if( g_alKeys.FindString(section) != -1 )			{ ReplyToCommand(g_iClientPrint, "Duplicate \"Keys\"       in \"%s\": \"%s\"", g_sCurrentSection, section); g_iDuplicates++; }	else	g_alKeys.PushString(section);
			}
		}
	}

	return SMCParse_Continue;
}

public SMCResult GameData_KeyValue(Handle parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	return SMCParse_Continue;
}

public SMCResult GameData_EndSection(Handle parser)
{
	if( g_iSectionLevel == 3 )
	{
		delete g_alMemPatches;
		delete g_alFunctions;
		delete g_alAddresses;
		delete g_alOffsets;
		delete g_alSignatures;
		delete g_alKeys;
	}

	g_iSectionLevel--;
	return SMCParse_Continue;
}

public void GameData_End(Handle parser, bool halted, bool failed)
{
	if( failed )
		LogError("Error: Cannot config.");
}