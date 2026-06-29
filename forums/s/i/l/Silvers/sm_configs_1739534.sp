/*
*	Cvar Configs Updater
*	Copyright (C) 2022 Silvers
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



#define PLUGIN_VERSION		"1.7"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] Cvar Configs Updater
*	Author	:	SilverShot
*	Descrp	:	Back up, delete and update cvar configs, retaining your previous configs values.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=188756
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.7 (15-Jan-2022)
	- Fixed sometimes adding an extra quote to lines. Thanks to "Hawkins" for reporting.
	- Fixed deleting the last character if there were no more new lines.

	- Merged some changes from the (24-May-2018) update by Dragokas:
		- Fixes issue with cfg file parser when non-quoted value is trimmed.
		- Fixed issue with displaying cvar value in console if it consist of '%' character or escape '\'.
		- All messages are duplicated to server rcon console, because client's console spam with a garbage sometimes.
		- Made "sm_configs_comment" ConVar = 1 by default, because it can be inaccessible due to ConVar read bug.
		- Added list of Cvar name excludes from fix.

1.6 (01-Sep-2021)
	- Fixed errors when commenting out lines that have escape characters. Thanks to "KoMiKoZa" for reporting.

1.5 (10-May-2020)
	- Increased maximum cvar length to allow for larger values.
	- Various changes to tidy up code.

1.4 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Fixed not detecting if backups were already created due to an extra slash at end of directory path.

1.3 (13-Oct-2012)
	- Fixed array index error when lines are empty. Thanks to "disawar1" for reporting.

1.2 (10-Jul-2012)
	- Fixed array index error when reading long lines. Thanks to "Patcher" for reporting.

1.1 (30-Jun-2012)
	- Fixed a small error.

1.0 (30-Jun-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <regex>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define MAX_CVAR_LENGTH		512


ArrayList g_hArrayCvarList, g_hArrayCvarValues;
ConVar g_hCvarComment, g_hCvarIgnore;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[ANY] Cvar Configs Updater",
	author = "SilverShot",
	description = "Back up, delete and update cvar configs, retaining your previous configs values.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=188756"
}

public void OnPluginStart()
{
	g_hCvarComment = CreateConVar(	"sm_configs_comment",	"1",			"Comment out cvars when their value matches the default.", CVAR_FLAGS);
	g_hCvarIgnore = CreateConVar(	"sm_configs_ignore",	"",				"Do not move these .cfg files. List their names separated by the | vertical bar, and without the .cfg extension.", CVAR_FLAGS);
	CreateConVar(					"sm_configs_version",	PLUGIN_VERSION,	"Cvar Configs Updater plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"sm_configs");

	RegAdminCmd("sm_configs_backup",		CmdConfigsBackup,	ADMFLAG_ROOT,	"Saves your current .cfg files to a backup folder named \"backup_20240726\" with todays date. Changes map to the current one so plugin cvar configs are created.");
	RegAdminCmd("sm_configs_compare",		CmdConfigsCompare,	ADMFLAG_ROOT,	"Compares files from todays backup with the current ones in your cfgs/sourcemod folder, and lists the values which have changed.");
	RegAdminCmd("sm_configs_update",		CmdConfigsUpdate,	ADMFLAG_ROOT,	"Sets cvar configs values in your cfgs/sourcemod folder to those from todays backup folder. Changes map to the current one so the cvars in-game are correct.");
}

public Action CmdConfigsBackup(int client, int args)
{
	char sDir[PLATFORM_MAX_PATH];
	sDir = "cfg/sourcemod/";

	DirectoryListing hDir = OpenDirectory(sDir);
	if( hDir == null )
	{
		PrintConsoles(client, "Could not open the directory \"cfg/sourcemod\".");
		return Plugin_Handled;
	}

	char sBackup[PLATFORM_MAX_PATH];
	FormatTime(sBackup, sizeof(sBackup), "cfg/sourcemod/backup_%Y%m%d");

	if( DirExists(sBackup) )
	{
		PrintConsoles(client, "You already backed up today! Check: \"%s\"", sBackup);
		return Plugin_Handled;
	}

	CreateDirectory(sBackup, 511);

	char sIgnore[1024];
	char sIgnoreBuffer[32][64];
	char sFile[PLATFORM_MAX_PATH];
	char sPath[PLATFORM_MAX_PATH];
	char sNew[PLATFORM_MAX_PATH];
	FileType filetype;
	int pos;

	g_hCvarIgnore.GetString(sIgnore, sizeof(sIgnore));
	int exploded = ExplodeString(sIgnore, "|", sIgnoreBuffer, sizeof(sIgnoreBuffer), sizeof(sIgnoreBuffer[]));

	while( hDir.GetNext(sFile, sizeof(sFile), filetype) )
	{
		if( filetype == FileType_File )
		{
			pos = FindCharInString(sFile, '.', true);
			if( pos != -1 &&
				strcmp(sFile[pos], ".cfg", false) == 0 &&
				strcmp(sFile, "sourcemod.cfg") &&
				strcmp(sFile, "sm_warmode_off.cfg") &&
				strcmp(sFile, "sm_warmode_on.cfg")
			)
			{
				pos = 0;
				if( exploded )
				{
					for( int i = 0; i < exploded; i++ )
					{
						Format(sPath, sizeof(sPath), "%s.cfg", sIgnoreBuffer[i]);
						if( strcmp(sFile, sPath) == 0 )
						{
							pos = 1;
							break;
						}
					}
				}

				if( pos == 0 )
				{
					Format(sPath, sizeof(sPath), "%s%s", sDir, sFile);
					Format(sNew, sizeof(sNew), "%s/%s", sBackup, sFile);
					RenameFile(sNew, sPath);
				}
			}
		}
	}

	PrintConsoles(client, "Cvar configs backed up to \"%s\"", sBackup);
	delete hDir;

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	ForceChangeLevel(sMap, "Cvar Configs Reloading Map");

	return Plugin_Handled;
}

public Action CmdConfigsCompare(int client, int args)
{
	CompareConfigs(client, false);
	return Plugin_Handled;
}

public Action CmdConfigsUpdate(int client, int args)
{
	if( CompareConfigs(client, true) )
	{
		char sMap[64];
		GetCurrentMap(sMap, sizeof(sMap));
		ForceChangeLevel(sMap, "Cvar Configs Reloading Map");
	}

	return Plugin_Handled;
}

bool CompareConfigs(int client, bool write)
{
	char sBackup[PLATFORM_MAX_PATH];
	FormatTime(sBackup, sizeof(sBackup), "cfg/sourcemod/backup_%Y%m%d");
	if( DirExists(sBackup) == false )
	{
		PrintConsoles(client, "You have not backed up \"cfg/sourcemod\" today, you must first use the command sm_configs_backup");
		return false;
	}

	char sDir[PLATFORM_MAX_PATH];
	sDir = "cfg/sourcemod/";

	DirectoryListing hDir = OpenDirectory(sDir);
	if( hDir == null )
	{
		PrintConsoles(client, "Could not open the directory \"cfg/sourcemod\".");
		return false;
	}

	g_hArrayCvarList = new ArrayList(MAX_CVAR_LENGTH);
	g_hArrayCvarValues = new ArrayList(MAX_CVAR_LENGTH);

	char sFile[PLATFORM_MAX_PATH];
	char sPath[PLATFORM_MAX_PATH];
	FileType filetype;
	int pos, iCount, iTotal;

	while( hDir.GetNext(sFile, sizeof(sFile), filetype) )
	{
		if( filetype == FileType_File )
		{
			pos = FindCharInString(sFile, '.', true);
			if( pos != -1 && strcmp(sFile[pos], ".cfg", false) == 0 )
			{
				Format(sPath, sizeof(sPath), "%s/%s", sBackup, sFile);
				if( FileExists(sPath) )
				{
					ProcessConfigA(client, sBackup, sFile);
					ProcessConfigB(client, sFile, write);
					g_hArrayCvarList.Clear();
					g_hArrayCvarValues.Clear();
					iCount++;
				}
				iTotal++;
			}
		}
	}

	delete g_hArrayCvarList;
	delete g_hArrayCvarValues;
	delete hDir;

	if( write )
		PrintConsoles(client, "Cvar configs updated with your values, restarting map to reload values.");

	return true;
}

// Get cvar values from backup folder and store for comparing or updating
void ProcessConfigA(int client, const char sBackup[PLATFORM_MAX_PATH], const char sFile[PLATFORM_MAX_PATH])
{
	static char sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "%s/%s", sBackup, sFile);
	File hFile = OpenFile(sPath, "r");
	if( hFile == null )
	{
		PrintConsoles(client, "Failed to open \"%s\".", sPath);
		return;
	}

	static char sLine[1024];
	static char sValue[1024];
	int pos;

	while( !hFile.EndOfFile() && hFile.ReadLine(sLine, sizeof(sLine)) )
	{
		TrimString(sLine);

		if( sLine[0] != '\x0' && sLine[0] != '/' && sLine[1] != '/' )
		{
			if( strlen(sLine) > 5 )
			{
				pos = FindCharInString(sLine, ' ');
				if( pos != -1 )
				{
					strcopy(sValue, sizeof(sValue), sLine[pos + 1]);
					ReplaceString(sValue, sizeof(sValue), "\n", "");
					ReplaceString(sValue, sizeof(sValue), "\r", "");
					sValue = UnQuote(sValue);
					sLine[pos] = '\x0';

					if( strcmp(sLine, "sm_cvar") == 0 )
					{
						strcopy(sLine, sizeof(sLine), sValue); // value => initial line
						pos = FindCharInString(sLine, ' '); // repeat same parsing
						if( pos == -1 )
						{
							continue;
						} else {
							strcopy(sValue, sizeof(sValue), sLine[pos + 1]);
							sLine[pos] = '\x0';
						}
					}

					if( strcmp(sLine, "sm") && strcmp(sLine, "exec") && strcmp(sLine, "setmaster") )
					{
						g_hArrayCvarList.PushString(sLine);
						g_hArrayCvarValues.PushString(sValue);
					}
				}
			}
		}
	}

	delete hFile;
}

// Compare changes or write previous values
void ProcessConfigB(int client, const char sConfig[PLATFORM_MAX_PATH], bool write = false)
{
	char sTemp[PLATFORM_MAX_PATH];
	File hTemp;
	if( write )
	{
		Format(sTemp, sizeof(sTemp), "cfg/sourcemod/%s.temp", sConfig);
		hTemp = OpenFile(sTemp, "w");
		if( hTemp == null )
		{
			PrintConsoles(client, "Failed to create temporary file \"%s\".", sTemp);
			return;
		}
	}

	char sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "cfg/sourcemod/%s", sConfig);
	File hFile = OpenFile(sPath, "r");
	if( hFile == null )
	{
		PrintConsoles(client, "Failed to open the cvar config \"%s\".", sPath);
		return;
	}

	static char sCvar[MAX_CVAR_LENGTH];
	static char sLine[1024];
	static char sValue[1024];
	static char sValue2[1024];
	int pos, entry, iCount, written;
	int iCvarComment = g_hCvarComment.IntValue;

	while( !hFile.EndOfFile() && hFile.ReadLine(sLine, sizeof(sLine)) )
	{
		TrimString(sLine);

		written = 0;

		if( sLine[0] != '\x0' && sLine[0] != '/' && sLine[1] != '/' )
		{
			if( strlen(sLine) > 5 )
			{
				pos = FindCharInString(sLine, ' ');
				if( pos != -1 )
				{
					strcopy(sValue, sizeof(sValue), sLine[pos + 1]);
					ReplaceString(sValue, sizeof(sValue), "\n", "");
					ReplaceString(sValue, sizeof(sValue), "\r", "");
					sValue = UnQuote(sValue);

					strcopy(sCvar, sizeof(sCvar), sLine);
					sCvar[pos] = '\x0';

					if( (entry = g_hArrayCvarList.FindString(sCvar)) != -1 )
					{
						g_hArrayCvarValues.GetString(entry, sValue2, sizeof(sValue2));
						if( strcmp(sValue, sValue2) != 0 )
						{
							if( write )
							{
								sLine[pos] = '\x0';
								StrCat(sLine, sizeof(sLine), " \""); // "
								StrCat(sLine, sizeof(sLine), sValue2);
								StrCat(sLine, sizeof(sLine), "\""); // "
								ReplaceString(sLine, sizeof(sLine), "%", "%%");
								hTemp.WriteLine(sLine);
								written = 1;
							}
							else
							{
								ReplyToCommand(client, "%s : %s \"%s\" set \"%s\"", sConfig, sCvar, sValue, sValue2);
							}
						}
						iCount++;
					}
				}
			}

			if( write && written == 0 )
			{
				if( iCvarComment )
				{
					sValue2 = "//";
					StrCat(sValue2, sizeof(sValue2), sLine);
					ReplaceString(sValue2, sizeof(sValue2), "%", "%%");
					hTemp.WriteLine(sValue2);
				}
				else
				{
					ReplaceString(sLine, sizeof(sLine), "%", "%%");
					hTemp.WriteLine(sLine);
				}
			}
		}
		else if( write && written == 0 )
		{
			ReplaceString(sLine, sizeof(sLine), "%", "%%");
			hTemp.WriteLine(sLine);
		}
	}

	delete hFile;

	if( write )
	{
		FlushFile(hTemp);
		delete hTemp;
		DeleteFile(sPath);
		RenameFile(sPath, sTemp);
	}
}

// value for cvar can be quoted (CvarName "value") or not quoted (CvarName Value).
char[] UnQuote(char[] Str)
{
	int pos;
	char EndChar;
	char buf[MAX_CVAR_LENGTH];
	strcopy(buf, sizeof(buf), Str);
	TrimString(buf);
	if( buf[0] == '\"' )
	{
		EndChar = '\"';
		strcopy(buf, sizeof(buf), buf[1]);
	} else {
		EndChar = ' ';
	}
	pos = FindCharInString(buf, EndChar);
	if( pos != -1 )
	{
		buf[pos] = '\x0';
	}
	return buf;
}

void PrintConsoles(int client, const char[] format, any ...)
{
	char buffer[400], buf2[450];
	VFormat(buffer, sizeof(buffer), format, 3);
	Format(buf2, sizeof(buf2), "[SM_CONFIGS]: %s", buffer);
	PrintToServer(buf2);
	if( client != 0 && IsClientInGame(client) )
		PrintToConsole(client, buf2);
}