#define PLUGIN_VERSION		"1.5"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] Cvar Configs Updater
*	Author	:	SilverShot
*	Descrp	:	Back up, delete and update cvar configs, retaining your previous configs values.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=188756
*	Plugins	:	http://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.5 (24-May-2018) by Dragokas
	- Added "sm_configs_anomaly_show" command to compare values in cfg files (including 'server.cfg') with actual in-game Cvar to find anomalies/unused cvars.
	- Added "sm_configs_anomaly_fix" to attempt to fix Cvar anomalies (Change "g_bCvarFixOnMapStart" const to apply fix on each map load).
	- Fixes issue with cfg file parser when non-quoted value is trimmed.
	- Fixed issue with displaying cvar value in console if it consist of '%' character or escape '\'.
	- All messages are duplicated to server rcon console, because client's console spam with a garbage sometimes.
	- Made "sm_configs_comment" ConVar = 1 by default, because it can be unaccessible due to ConVar read bug.
	- Added list of Cvar name excludes from fix.
	- Added check for exceeding in cfg file the max/min allowed/defined value.

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
#define MAX_CVAR_LENGTH		128

ArrayList g_hArrayCvarList, g_hArrayCvarValues, g_hArrayCfg, g_hCvarExclude;
ConVar g_hCvarComment, g_hCvarIgnore;

// "fix Cvar anomaly at each map load?"
#define FIX_CVAR_ON_MAP_START 0

public Plugin myinfo =
{
	name = "[ANY] Cvar Configs Updater",
	author = "SilverShot",
	description = "Back up, delete and update cvar configs, retaining your previous configs values; check for Cvar anomaly presence and automatically fix that by request.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=188756"
}

public void OnPluginStart()
{
	g_hCvarComment = CreateConVar(	"sm_configs_comment",	"1",			"Comment out cvars whos values are default.", CVAR_FLAGS);
	g_hCvarIgnore = CreateConVar(	"sm_configs_ignore",	"",				"Do not move these .cfg files. List their names separated by the | vertical bar, and without the .cfg extension.", CVAR_FLAGS);
	CreateConVar(					"sm_configs_version",	PLUGIN_VERSION,	"Cvar Configs Updater plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"sm_configs");

	RegAdminCmd("sm_configs_backup",		CmdConfigsBackup,	ADMFLAG_ROOT,	"Saves your current .cfg files to a backup folder named \"backup_20240726\" with todays date. Changes map to the current one so plugin cvar configs are created.");
	RegAdminCmd("sm_configs_compare",		CmdConfigsCompare,	ADMFLAG_ROOT,	"Compares files from todays backup with the current ones in your cfgs/sourcemod folder, and lists the values which have changed.");
	RegAdminCmd("sm_configs_anomaly_show",	CmdConfigsCompare2,	ADMFLAG_ROOT,	"Compares cfg files values with actual Cvar values to find anomalies and print difference/missing Cvars to server and client console.");
	RegAdminCmd("sm_configs_anomaly_fix",	CmdConfigsFix,		ADMFLAG_ROOT,	"Attempting to overwrite anomalous ConVars by cfg files values.");
	RegAdminCmd("sm_configs_update",		CmdConfigsUpdate,	ADMFLAG_ROOT,	"Sets cvar configs values in your cfgs/sourcemod folder to those from todays backup folder. Changes map to the current one so the cvars in-game are correct.");

	g_hArrayCfg = new ArrayList(PLATFORM_MAX_PATH);
	g_hCvarExclude = new ArrayList(MAX_CVAR_LENGTH);
	
	// List of additional cfgs to parse (use with "sm_configs_anomaly" command)
	g_hArrayCfg.PushString("cfg/server.cfg");
	g_hArrayCfg.PushString("cfg/autoexec.cfg");
	
	// List of Cvar excludes from hanling by fix
	g_hCvarExclude.PushString("sv_tags");
}

public void OnMapStart()
{
	#if (FIX_CVAR_ON_MAP_START)
		CompareConfigs2(0, true);
	#endif
}

public Action CmdConfigsBackup(int client, int args)
{
	char sDir[PLATFORM_MAX_PATH];
	strcopy(sDir, sizeof(sDir), "cfg/sourcemod/");

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
	int exploded = ExplodeString(sIgnore, "|", sIgnoreBuffer, 32, 64);

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

public Action CmdConfigsCompare2(int client, int args)
{
	CompareConfigs2(client, false);
	return Plugin_Handled;
}

public Action CmdConfigsFix(int client, int args)
{
	CompareConfigs2(client, true);
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
	strcopy(sDir, sizeof(sDir), "cfg/sourcemod/");

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

bool CompareConfigs2(int client, bool doFix)
{
	char sDir[PLATFORM_MAX_PATH];
	strcopy(sDir, sizeof(sDir), "cfg/sourcemod/");

	DirectoryListing hDir = OpenDirectory(sDir);
	if( hDir == null )
	{
		PrintConsoles(client, "Could not open the directory \"cfg/sourcemod\".");
		return false;
	}
	
	g_hArrayCvarList = new ArrayList(MAX_CVAR_LENGTH);
	g_hArrayCvarValues = new ArrayList(MAX_CVAR_LENGTH);

	char sFile[PLATFORM_MAX_PATH];
	FileType filetype;
	int pos, iFiles;
	
	while( hDir.GetNext(sFile, sizeof(sFile), filetype) )
	{
		if( filetype == FileType_File )
		{
			pos = FindCharInString(sFile, '.', true);
			if( pos != -1 && strcmp(sFile[pos], ".cfg", false) == 0 )
			{
				iFiles++;
				Format(sFile, sizeof(sFile), "cfg/sourcemod/%s", sFile);
				CheckCfgAnomaly(client, sFile, doFix);
			}
		}
	}

	// process additional cfgs
	for (int i = 0; i < g_hArrayCfg.Length; i++) {
		iFiles++;
		g_hArrayCfg.GetString(i, sFile, sizeof(sFile));
		CheckCfgAnomaly(client, sFile, doFix);
	}

	PrintConsoles(client, "Total Files: %i", iFiles);

	delete g_hArrayCvarList;
	delete g_hArrayCvarValues;
	delete hDir;

	return true;
}

void CheckCfgAnomaly(int client, const char sFile[PLATFORM_MAX_PATH], bool doFix)
{
	int iCount, iTotal;
	char sCvarName[MAX_CVAR_LENGTH];
	char sCfgValue[MAX_CVAR_LENGTH];
	char sCvarValueCur[MAX_CVAR_LENGTH];
	char sCvarValueDef[MAX_CVAR_LENGTH];
	ConVar hCvar;
	float min, max, fCfgValue;
	bool hasMin, hasMax;

	g_hArrayCvarList.Clear();
	g_hArrayCvarValues.Clear();

	// parse cfg
	ProcessConfigA(client, ".", sFile);

	// compare to actual
	for (int i = 0; i < g_hArrayCvarList.Length; i++) {
		iTotal++;
		g_hArrayCvarList.GetString(i, sCvarName, sizeof(sCvarName));

		if (g_hCvarExclude.FindString(sCvarName) != -1)
			continue;

		if ((hCvar = FindConVar(sCvarName)) != null) {
			iCount++;
			g_hArrayCvarValues.GetString(i, sCfgValue, sizeof(sCfgValue));
			hCvar.GetString(sCvarValueCur, sizeof(sCvarValueCur));
			hCvar.GetDefault(sCvarValueDef, sizeof(sCvarValueDef));
			
			if (!doFix) {
				// check for min/max value excess
				hasMin = hCvar.GetBounds(ConVarBound_Lower, min);
				hasMax = hCvar.GetBounds(ConVarBound_Upper, max);
			
				if (hasMin || hasMax) {
					if (!IsNumeric(sCfgValue)) {
						PrintConsoles(client, "Cfg value should be numeric. Cfg: %s, Cvar: %s, CfgValue: %s", sFile, sCvarName, sCfgValue);
					} else {
						fCfgValue = StringToFloat(sCfgValue);
						if (hasMin && fCfgValue < min)
							PrintConsoles(client, "Cfg value is too small. Cfg: %s, Cvar: %s, CfgValue: %s (min: %f)", sFile, sCvarName, sCfgValue, min);
						if (hasMax && fCfgValue > max)
							PrintConsoles(client, "Cfg value is too big. Cfg: %s, Cvar: %s, CfgValue: %s (max: %f)", sFile, sCvarName, sCfgValue, max);
					}
				}
				if (StrEqual(sCfgValue, "-2147483648")) {
					PrintConsoles(client, "Cfg value is too big. Cfg: %s, Cvar: %s, Value: %s, CfgValue: %s (max: 2147483647)", sFile, sCvarName, sCvarValueCur, sCfgValue);
				}
			}
			
			if (!IsCvarValuesEqual(sCvarValueCur, sCfgValue)) {

				if (!doFix)
					PrintConsoles(client, "ConVar value is different. Cfg: %s, Cvar: %s, Value: %s (default: %s), should be: %s", 
						sFile, sCvarName, EscapeString(sCvarValueCur), EscapeString(sCvarValueDef), EscapeString(sCfgValue));

				if (doFix) {
					hCvar.SetString(sCfgValue, true, false);

					// check result again
					hCvar.GetString(sCvarValueCur, sizeof(sCvarValueCur));
					if (!StrEqual(sCvarValueCur, sCfgValue)) {
						PrintConsoles(client, "FAILURE. Unable to fix value of convar: %s", sCvarName);
					} else {
						PrintConsoles(client, "Successfully changed convar: %s", sCvarName);
					}
				}
			}
		} else {
			if (!doFix)
				PrintConsoles(client, "ConVar is not used: %s, cfg: %s", sCvarName, sFile);
		}
	}
}

bool IsCvarValuesEqual(char[] sValue1, char[] sValue2)
{
	bool err1, err2;
	float fValue1, fValue2;
	fValue1 = ParseFloat(sValue1, err1);
	fValue2 = ParseFloat(sValue2, err2);
	
	if (!err1 && !err2)
		if (AreFloatAlmostEqual(fValue1, fValue2))
			return (true);
	
	if (err1 ^ err2)
		return (false);

	return (StrEqual(sValue1, sValue2, false));
}

bool AreFloatAlmostEqual(float a, float b, float precision = 0.001)
{
    return FloatAbs( a - b ) <= precision;
}

float ParseFloat(char[] Str, bool &err)
{
	if (IsNumeric(Str)) {
		err = false;
		return (StringToFloat(Str));
	} else {
		err = true;
	}
	return 0.0;
}

void ProcessConfigA(int client, const char sBackup[PLATFORM_MAX_PATH], const char sFile[PLATFORM_MAX_PATH])
{
	char sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "%s/%s", sBackup, sFile);
	File hFile = OpenFile(sPath, "r");
	if( hFile == null )
	{
		PrintConsoles(client, "Failed to open \"%s\".", sPath);
		return;
	}

	char sValue[256];
	char sLine[256];
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
					sLine[pos] = '\x0';

					if (StrEqual(sLine, "sm_cvar")) {
						strcopy(sLine, sizeof(sLine), sValue); // value => initial line
						pos = FindCharInString(sLine, ' ');    // repeat same parsing
						if( pos == -1 ) {
							continue;
						} else {
							strcopy(sValue, sizeof(sValue), sLine[pos + 1]);
							sLine[pos] = '\x0';
						}
					}
					if (!StrEqual(sLine, "sm") && !StrEqual(sLine, "exec") && !StrEqual(sLine, "setmaster")) {
						sValue = UnQuote(sValue);
						g_hArrayCvarList.PushString(sLine);
						g_hArrayCvarValues.PushString(sValue);
					}
				}
			}
		}
	}
	delete hFile;
}

// value for cvar can be quoted (CvarName "value") or not quoted (CvarName Value).
char[] UnQuote(char[] Str)
{
	int pos;
	char EndChar;
	char buf[MAX_CVAR_LENGTH];
	strcopy(buf, sizeof(buf), Str);
	TrimString(buf);
	if (buf[0] == '\"') {
		EndChar = '\"';
		strcopy(buf, sizeof(buf), buf[1]);
	} else {
		EndChar = ' ';
	}
	pos = FindCharInString(buf, EndChar);
	if( pos != -1 ) {
		buf[pos] = '\x0';
	}
	return buf;
}

// fix issue with trying to display in colsole cvar value with % specifier, or escape character
char[] EscapeString(char[] Str)
{
	char buf[MAX_CVAR_LENGTH];
	strcopy(buf, sizeof(buf), Str);
	ReplaceString(buf, sizeof(buf), "%", "%%");
	ReplaceString(buf, sizeof(buf), "\\", "\\\\");
	return buf;
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

	char sCvar[MAX_CVAR_LENGTH];
	char sLine[256];
	char sValue[256];
	char sValue2[256];
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

bool IsNumeric(char[] Str)
{
	static Regex regex;
	if (regex == null)
		regex = new Regex("^(((\\+|-)?\\d+(\\.\\d+)?)|((\\+|-)?\\.\\d+))(e(\\+|-)\\d+)?$", PCRE_CASELESS);
	return (regex.Match(Str) > 0);
}

void PrintConsoles(int client, const char[] format, any ...)
{
	char buffer[400], buf2[450];
	VFormat(buffer, sizeof(buffer), format, 3);
	Format(buf2, sizeof(buf2), "[SM_CONFIGS]: %s", buffer);
	PrintToServer(buf2);
	if (client != 0 && IsClientInGame(client))
		PrintToConsole(client, buf2);
}