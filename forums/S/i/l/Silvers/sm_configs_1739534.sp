#define PLUGIN_VERSION		"1.5"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] Cvar Configs Updater
*	Author	:	SilverShot
*	Descrp	:	Back up, delete and update cvar configs, retaining your previous configs values.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=188756
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

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

#define CVAR_FLAGS			FCVAR_NOTIFY
#define MAX_CVAR_LENGTH		512


ArrayList g_hArrayCvarList, g_hArrayCvarValues;
ConVar g_hCvarComment, g_hCvarIgnore;



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
	g_hCvarComment = CreateConVar(	"sm_configs_comment",	"0",			"Comment out cvars whos values are default.", CVAR_FLAGS);
	g_hCvarIgnore = CreateConVar(	"sm_configs_ignore",	"",				"Do not move these .cfg files. List their names separated by the | vertical bar, and without the .cfg extension.", CVAR_FLAGS);
	CreateConVar(					"sm_configs_version",	PLUGIN_VERSION,	"Cvar Configs Updater plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"sm_configs");

	RegAdminCmd("sm_configs_backup",	CmdConfigsBackup,	ADMFLAG_ROOT,	"Saves your current .cfg files to a backup folder named \"backup_20240726\" with todays date. Changes map to the current one so plugin cvar configs are created.");
	RegAdminCmd("sm_configs_compare",	CmdConfigsCompare,	ADMFLAG_ROOT,	"Compares files from todays backup with the current ones in your cfgs/sourcemod folder, and lists the values which have changed.");
	RegAdminCmd("sm_configs_update",	CmdConfigsUpdate,	ADMFLAG_ROOT,	"Sets cvar configs values in your cfgs/sourcemod folder to those from todays backup folder. Changes map to the current one so the cvars in-game are correct.");
}

public Action CmdConfigsBackup(int client, int args)
{
	char sDir[PLATFORM_MAX_PATH];
	sDir = "cfg/sourcemod/";

	DirectoryListing hDir = OpenDirectory(sDir);
	if( hDir == null )
	{
		ReplyToCommand(client, "[Configs] Could not open the directory \"cfg/sourcemod\".");
		return Plugin_Handled;
	}

	char sBackup[PLATFORM_MAX_PATH];
	FormatTime(sBackup, sizeof(sBackup), "cfg/sourcemod/backup_%Y%m%d");

	if( DirExists(sBackup) )
	{
		ReplyToCommand(client, "[Configs] You already backed up today! Check: \"%s\"", sBackup);
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

	ReplyToCommand(client, "[Configs] Cvar configs backed up to \"%s\"", sBackup);
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
		ReplyToCommand(client, "[Configs] You have not backed up \"cfg/sourcemod\" today, you must first use the command sm_configs_backup");
		return false;
	}

	char sDir[PLATFORM_MAX_PATH];
	sDir = "cfg/sourcemod/";

	DirectoryListing hDir = OpenDirectory(sDir);
	if( hDir == null )
	{
		ReplyToCommand(client, "[Configs] Could not open the directory \"cfg/sourcemod\".");
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
		ReplyToCommand(client, "[Configs] Cvar configs updated with your values, restarting map to reload values.");

	return true;
}

void ProcessConfigA(int client, const char sBackup[PLATFORM_MAX_PATH], const char sFile[PLATFORM_MAX_PATH])
{
	static char sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "%s/%s", sBackup, sFile);
	File hFile = OpenFile(sPath, "r");
	if( hFile == null )
	{
		ReplyToCommand(client, "[Configs] Failed to open \"%s\".", sPath);
		return;
	}

	static char sLine[1024];
	static char sValue[1024];
	int pos, pos2;

	while( !hFile.EndOfFile() && hFile.ReadLine(sLine, sizeof(sLine)) )
	{
		if( sLine[0] != '\x0' && sLine[0] != '/' && sLine[1] != '/' )
		{
			if( strlen(sLine) > 5 )
			{
				pos = FindCharInString(sLine, ' ');
				if( pos != -1 )
				{
					strcopy(sValue, sizeof(sValue), sLine[pos + 2]);
					pos2 = strlen(sValue) -2;
					if( pos2 < 0 ) pos2 = 0;
					sValue[pos2] = '\x0';
					sLine[pos] = '\x0';
					g_hArrayCvarList.PushString(sLine);
					g_hArrayCvarValues.PushString(sValue);
				}
			}
		}
	}

	delete hFile;
}

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
			ReplyToCommand(client, "[Configs] Failed to create temporary file \"%s\".", sTemp);
			return;
		}
	}

	char sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "cfg/sourcemod/%s", sConfig);
	File hFile = OpenFile(sPath, "r");
	if( hFile == null )
	{
		ReplyToCommand(client, "[Configs] Failed to open the cvar config \"%s\".", sPath);
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
		written = 0;

		if( sLine[0] != '\x0' && sLine[0] != '/' && sLine[1] != '/' )
		{
			if( strlen(sLine) > 5 )
			{
				pos = FindCharInString(sLine, ' ');
				if( pos != -1 )
				{
					strcopy(sValue, sizeof(sValue), sLine[pos + 2]);
					sValue[strlen(sValue)-2] = '\x0';

					strcopy(sCvar, sizeof(sCvar), sLine);
					sCvar[pos] = '\x0';

					if( (entry = g_hArrayCvarList.FindString(sCvar)) != -1 )
					{
						g_hArrayCvarValues.GetString(entry, sValue2, sizeof(sValue2));
						if( strcmp(sValue, sValue2) != 0 )
						{
							if( write )
							{
								sLine[pos+2] = '\x0';
								StrCat(sLine, sizeof(sLine), sValue2);
								StrCat(sLine, sizeof(sLine), "\""); // "
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
				sLine[strlen(sLine)-1] = '\x0';
				if( iCvarComment )
				{
					Format(sValue, sizeof(sValue), "//%s", sLine);
					hTemp.WriteLine(sValue);
				}
				else
				{
					hTemp.WriteLine(sLine);
				}
			}
		}
		else if( write && written == 0 )
		{
			sLine[strlen(sLine)-1] = '\x0';
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