#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <profiler>

#define PLUGIN_VERSION "1.0"
#define DEBUG 1
#define CVAR_FLAGS FCVAR_NOTIFY

/*
	Dedicated to the one Russian well-known and most popular game provider with the most bugged FTP in the world, which they unable to fix for more than 5 years.
*/

public Plugin myinfo = {
	name = "[ANY] FTP Ghosts Remover",
	author = "Dragokas",
	description = "Enumerates and removes ghost files on FTP which preventing upload from normal functioning",
	version = PLUGIN_VERSION,
	url = "http://github.com/dragokas"
};

ConVar g_hCvarPath;
ArrayList g_Found, g_Exclude;
char g_sRoot[PLATFORM_MAX_PATH], g_sFileExclusion[PLATFORM_MAX_PATH], g_sPathSeparator[4];
int g_iLenRoot;

public void OnPluginStart()
{
	CreateConVar( "sm_ftp_ghost_version", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS | FCVAR_DONTRECORD );
	
	g_hCvarPath = CreateConVar( 	"sm_ftp_ghost_path", 	"../", 		"Path for scanning. Default: all game folder. You can limit it by defining e.g. as 'addons/sourcemod/'", CVAR_FLAGS );
	
	AutoExecConfig(true, "sm_ftp_ghost");
	
	RegAdminCmd("sm_ghost_list", 	CmdList, 	ADMFLAG_ROOT, "Lists ghost files to be deleted");
	RegAdminCmd("sm_ghost_exclude", CmdExclude, ADMFLAG_ROOT, "<path> Exclude this file from the delete operation");
	RegAdminCmd("sm_ghost_delete", 	CmdDelete, 	ADMFLAG_ROOT, "Delete all ghost files");
	
	g_Found = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	g_Exclude = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	
	BuildPath(Path_SM, g_sFileExclusion, sizeof(g_sFileExclusion), "data/ftp_ghost_exclusion.txt");
	
	BuildPath(Path_SM, g_sRoot, sizeof(g_sRoot), "plugins/");
	g_iLenRoot = strlen(g_sRoot);
	strcopy(g_sPathSeparator, sizeof(g_sPathSeparator), g_sRoot[g_iLenRoot-1]);
	
	GetCvars();
	
	g_hCvarPath.AddChangeHook(OnConVarChanged);
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_hCvarPath.GetString(g_sRoot, sizeof(g_sRoot));
}

public Action CmdList(int client, int argc)
{
	if( argc == 0 )
	{
		ReplyToCommand(client, "Selected folder: %s", g_sRoot);
		PrepareScan(client, g_sRoot);
	}
	else {
		char root[PLATFORM_MAX_PATH];
		GetCmdArg(1, root, sizeof(root));
		ReplyToCommand(client, "Selected folder: %s", root);
		PrepareScan(client, root);
	}
	return Plugin_Handled;
}

void PrepareScan(int client, char[] dirname)
{
	#if DEBUG
	Handle hProf = CreateProfiler();
	StartProfiling(hProf);
	#endif
	
	g_Found.Clear();
	UpdateExclusions();
	ScanFolder(client, dirname);
	ReplyToCommand(client, "Total files found: %i", g_Found.Length);
	
	#if DEBUG
	StopProfiling(hProf);
	ReplyToCommand(client, "time = %.2f", GetProfilerTime(hProf));
	#endif
}

public Action CmdExclude(int client, int argc)
{
	char sFile[PLATFORM_MAX_PATH];
	
	if( argc == 0 )
	{	
		ReplyToCommand(client, "Using: sm_ghost_exclude \"path\"");
	}
	else {
		GetCmdArg(1, sFile, sizeof(sFile));
		File hFile = OpenFile(g_sFileExclusion, "a+");
		if( hFile )
		{
			hFile.WriteLine(sFile);
			hFile.Close();
		}
		ReplyToCommand(client, "Added to exclusions: %s", sFile);
	}
	return Plugin_Handled;
}

public Action CmdDelete(int client, int argc)
{
	if( argc == 0 )
	{
		PrepareDelete(client, g_sRoot);
	}
	else {
		char root[PLATFORM_MAX_PATH];
		GetCmdArg(1, root, sizeof(root));
		PrepareDelete(client, root);
	}
	return Plugin_Handled;
}

void PrepareDelete(int client, char[] dirname)
{
	char sFile[PLATFORM_MAX_PATH];
	bool result;
	
	PrepareScan(client, dirname);
	
	if( g_Found.Length == 0 )
	{
		ReplyToCommand(client, "No files found.");
	}
	else {
		for( int i = 0; i < g_Found.Length; i++ )
		{
			g_Found.GetString(i, sFile, sizeof(sFile));
			result = DeleteFile(sFile);
			ReplyToCommand(client, "[%s] Delete: %s", result ? "OK" : "FAIL", sFile);
		}
		ReplyToCommand(client, "Total processed files: %i", g_Found.Length);
	}
}

void ScanFolder(int client, char[] dirname)
{
	char 			sFile[PLATFORM_MAX_PATH];
	FileType 		fileType;
	
	DirectoryListing dir = OpenDirectory(dirname);
	if( dir == null )
		return;
	
	while( dir.GetNext(sFile, sizeof(sFile), fileType) )
	{
		switch( fileType )
		{
			case FileType_File:
			{
				if( sFile[0] == '.' || sFile[strlen(sFile) - 1] == '.' )
				{
					Format(sFile, sizeof(sFile), "%s%s", dirname, sFile);
					
					if( g_Exclude.FindString(sFile) == -1 )
					{
						ReplyToCommand(client, "Found: %s", sFile);
						g_Found.PushString(sFile);
					}
				}
			}
			case FileType_Directory:
			{
				if( strcmp(sFile, ".") != 0 && strcmp(sFile, "..") != 0 )
				{
					Format(sFile, sizeof(sFile), "%s%s%s", dirname, sFile, g_sPathSeparator);
					ScanFolder(client, sFile);
				}
			}
		}
	}
	delete dir;
}

void UpdateExclusions()
{
	char sFile[PLATFORM_MAX_PATH];
	g_Exclude.Clear();
	File hFile = OpenFile(g_sFileExclusion, "r");
	if( hFile )
	{
		while( !hFile.EndOfFile() )
		{
			hFile.ReadLine(sFile, sizeof(sFile));
			TrimString(sFile);
			g_Exclude.PushString(sFile);
		}
		hFile.Close();
	}
}