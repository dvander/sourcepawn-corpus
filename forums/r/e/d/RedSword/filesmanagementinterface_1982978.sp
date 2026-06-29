#pragma semicolon 1

#define PLUGIN_VERSION "1.0.2"

#include <sdktools>
#include <filesmanagementinterface>

public Plugin:myinfo =
{
	name = "Files Management Interface",
	author = "RedSword / Bob Le Ponge",
	description = "Allows files-in-folder precache/dl and random file accessor",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//#define DEBUG

#define DEFAULT_SOUNDS				".mp3 .wav"
#define DEFAULT_MODELS				".mdl"
#define DEFAULT_DECALS				".vmt"
#define DEFAULT_GENERICS			".pcf"
#define DEFAULT_DOWNLOADONLY		".phy .vtx .vvd .vtx .vtf"
#define DEFAULT_IGNORE				".ztmp .bz2"

//#define Flags @ function readDir()
#define FLAG_READ_SOUND (1 << 0) //should we consider sounds in the folder ?
#define FLAG_READ_MODEL (1 << 1) //should we consider models in the folder ?
#define FLAG_READ_DECAL (1 << 2) //should we consider decals in the folder ?
#define FLAG_READ_GENERIC (1 << 3) //should we consider generics in the folder ?
#define FLAG_READ_DOWNLOADONLY (1 << 4) //should we consider ignored files in the folder ?
#define FLAG_READ_NODOWNLOAD (1 << 5) //should we consider nodownload files in the folder ?
#define FLAG_READ_RECURSE (1 << 6) //should we read files in folders in folders in folders in folders in folders in folders ?
#define FLAG_READ_NORMAL ( FLAG_READ_SOUND | FLAG_READ_MODEL | FLAG_READ_DECAL | FLAG_READ_GENERIC | FLAG_READ_DOWNLOADONLY | FLAG_READ_NODOWNLOAD | FLAG_READ_RECURSE ) //should we consider nodownload files in the folder ?
#define FLAG_READ_FROM_NATIVE (1 << 7)

//==ConVars values
new String:g_szFile[ 256 ];
new String:g_szSoundExts[ 256 ];
new String:g_szModelExts[ 256 ];
new String:g_szDecalExts[ 256 ];
new String:g_szGenericExts[ 256 ];
new String:g_szDownloadOnlyExts[ 256 ];
new String:g_szNoDownloadExts[ 256 ];
new String:g_szIgnoreExts[ 256 ];

//==Vars
//No iterable tries IS PAINFUL FFFFFFUUUUUUUUUUUUUUUUuu
new Handle:g_hTrieSounds; //key == folder, value = handle to adtArray(fileNames)
new Handle:g_hTrieModels; //key == folder, value = handle to adtArray(fileNames)
new Handle:g_hTrieDecals; //key == folder, value = handle to adtArray(fileNames)
new Handle:g_hTrieGenerics; //key == folder, value = handle to adtArray(fileNames)
new Handle:g_hTrieCustomNoDL; //key == folder, value = handle to adtTrie, which has key == extension and value == handle to adtArray(fileNames)

new Handle:g_hHandlesRef; //hahahahahahhhaahaha

//Mod dependant
new bool:g_bIsNewerMod; //snd_rebuildaudiocache story

//===== Forwards =====

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary( "filesmanagement.core" );
	
	//Randoms
	CreateNative( "FMI_GetRandomSound", Native_GetRandomSound );
	CreateNative( "FMI_GetRandomModel", Native_GetRandomModel );
	CreateNative( "FMI_GetRandomDecal", Native_GetRandomDecal );
	CreateNative( "FMI_GetRandomGeneric", Native_GetRandomGeneric );
	CreateNative( "FMI_GetRandomCustom", Native_GetRandomCustom );
	
	//Precache & DL
	CreateNative( "FMI_PrecacheSoundsFolder", Native_PrecacheSoundsFolder );
	CreateNative( "FMI_PrecacheModelsFolder", Native_PrecacheModelsFolder );
	CreateNative( "FMI_PrecacheDecalsFolder", Native_PrecacheDecalsFolder );
	CreateNative( "FMI_PrecacheGenericsFolder", Native_PrecacheGenericsFolder );
	CreateNative( "FMI_AddToDownloadTableFolder", Native_AddToDownloadTableFolder );
	CreateNative( "FMI_RegisterFolder", Native_RegisterFolder );
	
	return APLRes_Success;
}

public OnPluginStart()
{
	//CVARs
	CreateConVar("filesmanagementinterfaceversion", PLUGIN_VERSION, "Files Management Interface version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT);
	
	new Handle:randomHandle; //KyleS hates handles, remember that everyone !
	
	randomHandle = CreateConVar("fmi_file", "filesmanagementinterface.ini", "File to read that will contain the folder paths which will have their files precached & downloaded. Can be a filepath.", FCVAR_PLUGIN);
	HookConVarChange( randomHandle, OnFileChange );
	GetConVarString( randomHandle, g_szFile, sizeof(g_szFile) );
	
	randomHandle = CreateConVar("fmi_fileext_sound", DEFAULT_SOUNDS, "File extensions to precache and consider sounds when using the interface (.inc)", FCVAR_PLUGIN);
	HookConVarChange( randomHandle, OnFileExtSoundChange );
	GetConVarString( randomHandle, g_szSoundExts, sizeof(g_szSoundExts) );
	
	randomHandle = CreateConVar("fmi_fileext_model", DEFAULT_MODELS, "File extensions to precache and consider models when using the interface (.inc)", FCVAR_PLUGIN);
	HookConVarChange( randomHandle, OnFileExtModelChange );
	GetConVarString( randomHandle, g_szModelExts, sizeof(g_szModelExts) );
	
	randomHandle = CreateConVar("fmi_fileext_decal", DEFAULT_DECALS, "File extensions to precache and consider decals when using the interface (.inc)", FCVAR_PLUGIN);
	HookConVarChange( randomHandle, OnFileExtDecalChange );
	GetConVarString( randomHandle, g_szDecalExts, sizeof(g_szDecalExts) );
	
	randomHandle = CreateConVar("fmi_fileext_generic", DEFAULT_GENERICS, "File extensions to precache and consider generics when using the interface (.inc)", FCVAR_PLUGIN);
	HookConVarChange( randomHandle, OnFileExtGenericChange );
	GetConVarString( randomHandle, g_szGenericExts, sizeof(g_szGenericExts) );
	
	randomHandle = CreateConVar("fmi_fileext_downloadonly", DEFAULT_DOWNLOADONLY, "File extensions that will be downloaded, but not accessible via the interface (.inc)", FCVAR_PLUGIN);
	HookConVarChange( randomHandle, OnFileExtDownloadOnlyChange );
	GetConVarString( randomHandle, g_szDownloadOnlyExts, sizeof(g_szDownloadOnlyExts) );
	
	randomHandle = CreateConVar("fmi_fileext_nodownload", ".txt .ini .cfg", "File extensions that won't be downloaded but will be accessible via the interface (.inc)", FCVAR_PLUGIN);
	HookConVarChange( randomHandle, OnFileExtNoDownloadChange );
	GetConVarString( randomHandle, g_szNoDownloadExts, sizeof(g_szNoDownloadExts) );
	
	randomHandle = CreateConVar("fmi_fileext_ignore", DEFAULT_IGNORE, "File extensions that won't be downloaded/precached (directly) nor accessible via the interface (.inc), when using fmi_file", FCVAR_PLUGIN);
	HookConVarChange( randomHandle, OnFileExtIgnoreChange );
	GetConVarString( randomHandle, g_szIgnoreExts, sizeof(g_szIgnoreExts) );
	
	RegAdminCmd("sm_fmi_reloadfiles", 
		Command_ReloadFiles, 
		ADMFLAG_RCON, 
		"sm_fmi_reloadfiles or !fmi_reloadfiles ; reload files/folders in the file 'fmi_file'");
	
	g_hTrieSounds = CreateTrie();
	g_hTrieModels = CreateTrie();
	g_hTrieDecals = CreateTrie();
	g_hTrieGenerics = CreateTrie();
	g_hTrieCustomNoDL = CreateTrie();
	g_hHandlesRef = CreateArray();
	
	//Mod dependant
	decl String:szBuffer[ 32 ];
	GetGameFolderName( szBuffer, sizeof(szBuffer) );
	
	g_bIsNewerMod = //thanks to a certain duck
		StrEqual( szBuffer, "csgo", false ) ||
		StrEqual( szBuffer, "left4dead", false ) ||
		StrEqual( szBuffer, "left4dead2", false ) ||
		StrEqual( szBuffer, "swarm", false ) ||
		StrEqual( szBuffer, "nucleardawn", false ) ||
		StrEqual( szBuffer, "dinodday", false );

}

public OnConfigsExecuted()
{
	//Called on plugin load/reload
	parseFileWithFolderNamesAndPrecacheAndDownload();
}

//===== Callback cmd =====

public Action:Command_ReloadFiles(iClient, args)
{
	parseFileWithFolderNamesAndPrecacheAndDownload();
}

//===== Privates ; big ones =====

parseFileWithFolderNamesAndPrecacheAndDownload()
{
	reloadTries();
	
	if ( !FileExists( g_szFile ) )
	{
		//LogError("parseFileWithFolderNamesAndPrecacheAndDownload::Couldn't find file '%s'", g_szFile);
		LogMessage("Didn't find file '%s' to parse; it may be wanted", g_szFile);
		return;
	}
	
	new Handle:file = OpenFile( g_szFile, "r" );
	
	if ( file == INVALID_HANDLE )
	{
		LogError("parseFileWithFolderNamesAndPrecacheAndDownload::Couldn't open file '%s' for reading", g_szFile);
		return;
	}
	
	
	readFMIFile( file );
	
	
	CloseHandle( file );
}

readFMIFile( Handle:file )
{
	decl String:szLine[ 256 ];
	
	new Handle:dir;
	
	while ( !IsEndOfFile( file ) && ReadFileLine( file, szLine, sizeof(szLine) ) )
	{
		checkForComments( szLine );
		
		TrimString( szLine );
		
		if ( szLine[ 0 ] == '\0' )
			continue;
		
#if defined DEBUG
		PrintToServer("reading line '%s'", szLine);
#endif
		
		if ( !DirExists( szLine ) )
		{
			LogError("readFMIFile::Couldn't find directory '%s'", szLine);
			continue;
		}
		
		dir = OpenDirectory( szLine );
		if ( dir == INVALID_HANDLE )
		{
			LogError("readFMIFile::Couldn't open directory '%s' for reading", szLine);
			continue;
		}
		
		
		
		readDir( dir, szLine, FLAG_READ_NORMAL );
		
		
		
		CloseHandle( dir );
	}
	
}
//return the number of files which had an action done (either precached, downloaded and/or registered)
readDir( Handle:dir, const String:path[], flags, const String:readFileExts[]="" )
{
	static String:szBuffer[ 256 ];
	static String:szTmpPath[ 256 ];
	static String:szExt[ 16 ];
	new FileType:fileType = FileType_Unknown;
	new Handle:tmpHandle;
	
	new Handle:subDir;
	
	new nbActions;
	
	//Mod dependant
	new stringprecacheSoundTable;
	if ( g_bIsNewerMod )
	{
		stringprecacheSoundTable = FindStringTable( "soundprecache" );
	}
	
	while ( ReadDirEntry( dir, szBuffer, sizeof(szBuffer), fileType ) )
	{
		if ( ( szBuffer[ 0 ] == '.' ) && ( szBuffer[ 1 ] == '\0' || ( szBuffer[ 1 ] == '.' && szBuffer[ 2 ] == '\0' ) ) ) //why the fuck do we read "." and ".." ?? gg M$
			continue;
		
		new tmpLen = strcopy( szTmpPath, sizeof(szTmpPath), path );
		if ( szTmpPath[ tmpLen - 1 ] != '/' ) //allows both putting '/' or not
		{
			StrCat( szTmpPath, sizeof(szTmpPath), "/" );
		}
		StrCat( szTmpPath, sizeof(szTmpPath), szBuffer );
		
		if ( FileType:fileType == FileType_File )
		{
			if ( !FileExists( szTmpPath ) )
			{
				LogError("readDir::Couldn't find file '%s'", szTmpPath);
				continue;
			}
			
			
			
			//Find extension
			if ( !getFilenameExtension( szBuffer, szExt, sizeof(szExt) ) )
				continue;
			
#if defined DEBUG
		PrintToServer("found file '%s' had extension '%s' under dir %s ; flags = %d; searched exts = '%s'", szBuffer, szExt, path, flags, readFileExts);
#endif
			//==Deal with extension
			//I strongly believe extensions are case unsensitive
			//I thought about putting everything in a trie, but what if a file needs to be checked CaSe UnSENsiTIvE ?
			if ( ( flags & FLAG_READ_SOUND ) && (
				( !( flags & FLAG_READ_FROM_NATIVE ) && StrContains( g_szSoundExts, szExt, false ) != -1 ) ||
				( ( flags & FLAG_READ_FROM_NATIVE ) && StrContains( readFileExts, szExt, false ) != -1 )
				) )
			{
#if defined DEBUG
		PrintToServer("found file '%s' was a sound; under key = %s", szBuffer, path);
#endif
				
				//2 Add to dl table
				AddFileToDownloadsTable( szTmpPath );
				
				
				//Mod dependant : 2- Format str to precache
				new len = strlen( szTmpPath );
				
				if ( !g_bIsNewerMod )
				{
					new i; //remove "sound/"
					for ( ; i + 6 < len; ++i )
					{
						szTmpPath[ i ] = szTmpPath[ i + 6 ];
					}
					szTmpPath[ i ] = '\0';
					len -= 6;
					PrecacheSound( szTmpPath, true );//Arghhh; stoopid thing needs no sound/
				}
				else //csgo & friends
				{
					szTmpPath[ 0 ] = '*';
					new i = 1; //replace "sound/" by "*"
					for ( ; i + 5 < len; ++i )
					{
						szTmpPath[ i ] = szTmpPath[ i + 5 ];
					}
					szTmpPath[ i ] = '\0';
					len -= 5;
					AddToStringTable( stringprecacheSoundTable, szTmpPath );
				}
				
				
				//1.5 remove the sound file name as it is always there; by formating szTmpPath
				szTmpPath[ len - strlen( szBuffer ) - 1 ] = '\0'; //-1 because of another '/'
				
				//1- Add to trie
				if ( !GetTrieValue( g_hTrieSounds, szTmpPath, tmpHandle ) )
				{
					tmpHandle = CreateArray(64);
					PushArrayCell( g_hHandlesRef, tmpHandle );
					
					SetTrieValue( g_hTrieSounds, szTmpPath, tmpHandle );
				}
				
#if defined DEBUG
		PrintToServer("sound : PushArrayString ('%d', '%s') in the TrieKey = %s", tmpHandle, szBuffer, szTmpPath);
#endif
				PushArrayString( tmpHandle, szBuffer );
				
#if defined DEBUG
				//DELETE BELOW
				decl String:szEstiBuffer[ 256 ];
				
				GetArrayString( tmpHandle, GetArraySize( tmpHandle ) - 1, szEstiBuffer, sizeof(szEstiBuffer) );
				
				PrintToServer("ESTIBUFFER = %s", szEstiBuffer);
				
				//DELETE ABOVE
#endif
				nbActions++;
			}
			else if ( ( flags & FLAG_READ_MODEL ) && (
				( !( flags & FLAG_READ_FROM_NATIVE ) && StrContains( g_szModelExts, szExt, false ) != -1 ) ||
				( ( flags & FLAG_READ_FROM_NATIVE ) && StrContains( readFileExts, szExt, false ) != -1 )
				) )
			{
#if defined DEBUG
		PrintToServer("found file '%s' was a model", szBuffer);
#endif
				//1- Add to trie
				if ( !GetTrieValue( g_hTrieModels, path, tmpHandle ) )
				{
					tmpHandle = CreateArray(64);
					PushArrayCell( g_hHandlesRef, tmpHandle );
					
					SetTrieValue( g_hTrieModels, path, tmpHandle );
				}
				
				PushArrayString( tmpHandle, szBuffer );
				
				//2- Precache & dl
				AddFileToDownloadsTable( szTmpPath );
				PrecacheModel( szTmpPath, true );
				
				nbActions++;
			}
			else if ( ( flags & FLAG_READ_DECAL ) && (
				( !( flags & FLAG_READ_FROM_NATIVE ) && StrContains( g_szDecalExts, szExt, false ) != -1 )  ||
				( ( flags & FLAG_READ_FROM_NATIVE ) && StrContains( readFileExts, szExt, false ) != -1 )
				) )
			{
#if defined DEBUG
		PrintToServer("found file '%s' was a decal", szBuffer);
#endif
				//1- Add to trie
				if ( !GetTrieValue( g_hTrieDecals, path, tmpHandle ) )
				{
					tmpHandle = CreateArray(64);
					PushArrayCell( g_hHandlesRef, tmpHandle );
					
					SetTrieValue( g_hTrieDecals, path, tmpHandle );
				}
				
				PushArrayString( tmpHandle, szBuffer );
				
				//2- Precache & dl
				AddFileToDownloadsTable( szTmpPath );
				PrecacheDecal( szTmpPath, true );
				
				nbActions++;
			}
			else if ( ( flags & FLAG_READ_GENERIC ) && (
				( !( flags & FLAG_READ_FROM_NATIVE ) && StrContains( g_szGenericExts, szExt, false ) != -1 ) ||
				( ( flags & FLAG_READ_FROM_NATIVE ) && StrContains( readFileExts, szExt, false ) != -1 )
				) )
			{
#if defined DEBUG
		PrintToServer("found file '%s' was a generic", szBuffer);
#endif
				//1- Add to trie
				if ( !GetTrieValue( g_hTrieGenerics, path, tmpHandle ) )
				{
					tmpHandle = CreateArray(64);
					PushArrayCell( g_hHandlesRef, tmpHandle );
					
					SetTrieValue( g_hTrieGenerics, path, tmpHandle );
				}
				
				PushArrayString( tmpHandle, szBuffer );
				
				//2- Precache & dl
				AddFileToDownloadsTable( szTmpPath );
				PrecacheGeneric( szTmpPath, true );
				
				nbActions++;
			}
			else if ( ( flags & FLAG_READ_DOWNLOADONLY ) && (
				( !( flags & FLAG_READ_FROM_NATIVE ) && StrContains( g_szDownloadOnlyExts, szExt, false ) != -1 ) ||
				( ( flags & FLAG_READ_FROM_NATIVE ) && StrContains( readFileExts, szExt, false ) != -1 )
				) )
			{
#if defined DEBUG
		PrintToServer("found file '%s' was an ignoreButDL", szBuffer);
#endif
				//DL then gtfo
				AddFileToDownloadsTable( szTmpPath );
				
				nbActions++;
			}
			else if ( ( flags & FLAG_READ_NODOWNLOAD ) && (
				( !( flags & FLAG_READ_FROM_NATIVE ) && StrContains( g_szNoDownloadExts, szExt, false ) != -1 ) ||
				( ( flags & FLAG_READ_FROM_NATIVE ) && StrContains( readFileExts, szExt, false ) != -1 )
				) )
			{
#if defined DEBUG
		PrintToServer("found file '%s' was an custom", szBuffer);
#endif
				//Don't forget g_hHandlesRef ^2
				//Add to trie
				new Handle:tmpTrieHandle;
				
				if ( !GetTrieValue( g_hTrieCustomNoDL, path, tmpTrieHandle ) )
				{
					tmpTrieHandle = CreateTrie();
					PushArrayCell( g_hHandlesRef, tmpTrieHandle );
					
					SetTrieValue( g_hTrieCustomNoDL, path, tmpTrieHandle );
				}
				
				
				//GetTrie again; with ext
				if ( !GetTrieValue( tmpTrieHandle, szExt, tmpHandle ) )
				{
					tmpHandle = CreateArray(64);
					PushArrayCell( g_hHandlesRef, tmpHandle );
					
					SetTrieValue( tmpTrieHandle, szExt, tmpHandle );
				}
				
				PushArrayString( tmpHandle, szBuffer );
				
#if defined DEBUG
		PrintToServer("PushArrayString( %d, %s ) under handles Trie=%d in the first trieKey = %s and 2nd triKey = %s", tmpHandle, szBuffer, tmpTrieHandle, path, szExt);
#endif
				
				nbActions++;
			}
			else if ( flags == FLAG_READ_NORMAL && StrContains( g_szIgnoreExts, szExt, false ) != -1 )
			{
#if defined DEBUG
		PrintToServer("found file '%s' was nothing =(", szBuffer);
#endif
				LogMessage("(OK) Did nothing with file '%s'; it is unknown what to do with this extension", szTmpPath);
			}
			
		}
		else if ( FileType:fileType == FileType_Directory )
		{
			if ( flags & FLAG_READ_RECURSE )
			{
				if ( !DirExists( szTmpPath ) )
				{
					LogError("readDir::Couldn't find directory '%s'", szTmpPath);
					continue;
				}
				
				subDir = OpenDirectory( szTmpPath );
				if ( subDir == INVALID_HANDLE )
				{
					LogError("readDir::Couldn't open directory '%s' for reading its files", szTmpPath);
					continue;
				}
				
				nbActions += readDir( subDir, szTmpPath, flags );
				
				CloseHandle( subDir );
			}
		}
		else //== FileType_Unknown
		{
			LogError("readDir::Couldn't determine type of file/dir/wtf '%s'", szBuffer);
			//continue;
		}
	}
	
	return nbActions;
}

reloadTries()
{
	for ( new i = GetArraySize( g_hHandlesRef ) - 1; i >= 0; --i )
	{
		if ( GetArrayCell( g_hHandlesRef, i ) != INVALID_HANDLE )
		{
			CloseHandle( GetArrayCell( g_hHandlesRef, i ) );
			SetArrayCell( g_hHandlesRef, i, INVALID_HANDLE );
		}
	}
	
	ClearTrie( g_hTrieSounds );
	ClearTrie( g_hTrieModels );
	ClearTrie( g_hTrieDecals );
	ClearTrie( g_hTrieGenerics );
	ClearTrie( g_hTrieCustomNoDL );
	ClearArray( g_hHandlesRef );
}

//=== privates (smaller ones)

checkForComments( String:str[] ) //kinda-trimEnd
{
	new len = strlen( str );
	for ( new i; i < len; ++i )
	{
		if ( str[ i ] == ';' || ( str[ i ] == '/' && i + 1 < len && str[ i + 1 ] == '/' ) )
		{
			str[ i ] = '\0';
			return;
		}
	}
}
bool:getFilenameExtension( const String:str[], String:ext[], sizeExt )
{
	new len = strlen( str );
	
	//1- get index of '.'
	new i = len - 2;
	for ( ; i > 0; --i ) //don't check 0
	{
		if ( str[ i ] == '.' )
			break;
	}
	
	new j;
	for ( ; j < sizeExt && i + j < len; ++j )
	{
		ext[ j ] = str[ i + j ];
	}
	
	if ( j < sizeExt )
		ext[ j ] = '\0';
	else
		ext[ sizeExt - 1 ] = 0;
	
	return i != 0;
}

//===== ConVarChange =====

bool:newValueHasDefaultOnes(const String:newValue[], const String:defValue[], Handle:cvar)
{
	decl String:szBuffer[ 64 ][ 16 ];
	for ( new i; i < sizeof(szBuffer); ++i )
	{
		szBuffer[ i ][ 0 ] = '\0';
	}
	
	new nbDefStrings = ExplodeString( defValue, " ", szBuffer, sizeof(szBuffer), sizeof(szBuffer[]) );
	
	while ( nbDefStrings > 0 )
	{
		--nbDefStrings;
		
		if ( StrContains( newValue, szBuffer[ nbDefStrings ], false ) == -1 )
		{
			decl String:szCVarName[ 64 ];
			GetConVarName( cvar, szCVarName, sizeof(szCVarName) );
			
			LogError( "Extensions in ConVar '%s' must ensure they have the default extensions. Default : '%s', new (failed) value : '%s'.", 
				szCVarName,
				defValue,
				newValue );
			return false;
		}
	}
	
	return true;
}

public OnFileChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(g_szFile, sizeof(g_szFile), newVal);
	
	parseFileWithFolderNamesAndPrecacheAndDownload();
}
public OnFileExtSoundChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if ( newValueHasDefaultOnes( newVal, DEFAULT_SOUNDS, cvar ) )
	{
		strcopy(g_szSoundExts, sizeof(g_szSoundExts), newVal);
		
		parseFileWithFolderNamesAndPrecacheAndDownload();
	}
	else
	{
		SetConVarString( cvar, oldVal );
	}
}
public OnFileExtModelChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if ( newValueHasDefaultOnes( newVal, DEFAULT_MODELS, cvar ) )
	{
		strcopy(g_szModelExts, sizeof(g_szModelExts), newVal);
		
		parseFileWithFolderNamesAndPrecacheAndDownload();
	}
	else
	{
		SetConVarString( cvar, oldVal );
	}
}
public OnFileExtDecalChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if ( newValueHasDefaultOnes( newVal, DEFAULT_DECALS, cvar ) )
	{
		strcopy(g_szDecalExts, sizeof(g_szDecalExts), newVal);
		
		parseFileWithFolderNamesAndPrecacheAndDownload();
	}
	else
	{
		SetConVarString( cvar, oldVal );
	}
}
public OnFileExtGenericChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if ( newValueHasDefaultOnes( newVal, DEFAULT_GENERICS, cvar ) )
	{
		strcopy(g_szGenericExts, sizeof(g_szGenericExts), newVal);
		
		parseFileWithFolderNamesAndPrecacheAndDownload();
	}
	else
	{
		SetConVarString( cvar, oldVal );
	}
}
public OnFileExtDownloadOnlyChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if ( newValueHasDefaultOnes( newVal, DEFAULT_DOWNLOADONLY, cvar ) )
	{
		strcopy(g_szDownloadOnlyExts, sizeof(g_szDownloadOnlyExts), newVal);
		
		parseFileWithFolderNamesAndPrecacheAndDownload();
	}
	else
	{
		SetConVarString( cvar, oldVal );
	}
}
public OnFileExtNoDownloadChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(g_szNoDownloadExts, sizeof(g_szNoDownloadExts), newVal);
	
	parseFileWithFolderNamesAndPrecacheAndDownload();
}
public OnFileExtIgnoreChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(g_szIgnoreExts, sizeof(g_szIgnoreExts), newVal);
	
	parseFileWithFolderNamesAndPrecacheAndDownload();
}










/** ** ** ** ** ** ** ** ** ** ** ** ** 
* * * * * * * ENTER NATIVES * * * * * *
** ** ** ** ** ** ** ** ** ** ** ** **/

//== GetRandom

public Native_GetRandomSound(Handle:hPlugin, iNumParams)
{
	decl String:folder[ 256 ];
	GetNativeString( 1, folder, sizeof(folder) );
	
	if ( g_bIsNewerMod && folder[ 0 ] != '*' )
	{
		Format( folder, sizeof(folder), "*%s", folder );
	}
	
	decl Handle:adtArrayHandle;
	
	if ( !GetTrieValue( g_hTrieSounds, folder, adtArrayHandle ) )
		return false;
	
	new arraySize = GetArraySize( adtArrayHandle );
	
	if ( arraySize == 0 )
		return false;
	
	decl String:toPutInOutBuffer[ 256 ];
	
	GetArrayString( adtArrayHandle, GetRandomInt( 0, arraySize - 1 ), toPutInOutBuffer, GetNativeCell(3) );
	
	Format( toPutInOutBuffer, GetNativeCell(3), "%s/%s", folder, toPutInOutBuffer );
	
	SetNativeString( 2, toPutInOutBuffer, GetNativeCell(3) );
	
	return true;
}
public Native_GetRandomModel(Handle:hPlugin, iNumParams)
{
	decl String:folder[ 256 ];
	GetNativeString( 1, folder, sizeof(folder) );
	
	decl Handle:adtArrayHandle;
	
	if ( !GetTrieValue( g_hTrieModels, folder, adtArrayHandle ) )
		return false;
	
	new arraySize = GetArraySize( adtArrayHandle );
	
	if ( arraySize == 0 )
		return false;
	
	decl String:toPutInOutBuffer[ 256 ];
	
	GetArrayString( adtArrayHandle, GetRandomInt( 0, arraySize - 1 ), toPutInOutBuffer, GetNativeCell(3) );
	
	Format( toPutInOutBuffer, GetNativeCell(3), "%s/%s", folder, toPutInOutBuffer );
	
	SetNativeString( 2, toPutInOutBuffer, GetNativeCell(3) );
	
	return true;
}
public Native_GetRandomDecal(Handle:hPlugin, iNumParams)
{
	decl String:folder[ 256 ];
	GetNativeString( 1, folder, sizeof(folder) );
	
	decl Handle:adtArrayHandle;
	
	if ( !GetTrieValue( g_hTrieDecals, folder, adtArrayHandle ) )
		return false;
	
	new arraySize = GetArraySize( adtArrayHandle );
	
	if ( arraySize == 0 )
		return false;
	
	decl String:toPutInOutBuffer[ 256 ];
	
	GetArrayString( adtArrayHandle, GetRandomInt( 0, arraySize - 1 ), toPutInOutBuffer, GetNativeCell(3) );
	
	Format( toPutInOutBuffer, GetNativeCell(3), "%s/%s", folder, toPutInOutBuffer );
	
	SetNativeString( 2, toPutInOutBuffer, GetNativeCell(3) );
	
	return true;
}
public Native_GetRandomGeneric(Handle:hPlugin, iNumParams)
{
	decl String:folder[ 256 ];
	GetNativeString( 1, folder, sizeof(folder) );
	
	decl Handle:adtArrayHandle;
	
	if ( !GetTrieValue( g_hTrieGenerics, folder, adtArrayHandle ) )
		return false;
	
	new arraySize = GetArraySize( adtArrayHandle );
	
	if ( arraySize == 0 )
		return false;
	
	decl String:toPutInOutBuffer[ 256 ];
	
	GetArrayString( adtArrayHandle, GetRandomInt( 0, arraySize - 1 ), toPutInOutBuffer, GetNativeCell(3) );
	
	Format( toPutInOutBuffer, GetNativeCell(3), "%s/%s", folder, toPutInOutBuffer );
	
	SetNativeString( 2, toPutInOutBuffer, GetNativeCell(3) );
	
	return true;
}
public Native_GetRandomCustom(Handle:hPlugin, iNumParams)
{
	decl String:folder[ 256 ];
	GetNativeString( 1, folder, sizeof(folder) );
	
	decl Handle:adt2ndTrieHandle;
	
#if defined DEBUG
		PrintToChatAll("About to try to get %s", folder);
#endif
	
	if ( !GetTrieValue( g_hTrieCustomNoDL, folder, adt2ndTrieHandle ) )
		return false;
	
	decl String:fileExt[ 16 ];
	GetNativeString( 2, fileExt, sizeof(fileExt) );
	
	decl Handle:adtArrayHandle;
	
#if defined DEBUG
		PrintToChatAll("About to try to get %s in handle %d", fileExt, adt2ndTrieHandle);
#endif
	
	if ( !GetTrieValue( adt2ndTrieHandle, fileExt, adtArrayHandle ) )
		return false;
	
	new arraySize = GetArraySize( adtArrayHandle );
		
#if defined DEBUG
		PrintToChatAll("Size = %d", arraySize);
#endif
	
	if ( arraySize == 0 )
		return false;
	
	decl String:toPutInOutBuffer[ 256 ];
	
	GetArrayString( adtArrayHandle, GetRandomInt( 0, arraySize - 1 ), toPutInOutBuffer, GetNativeCell(4) );
	
	Format( toPutInOutBuffer, GetNativeCell(4), "%s/%s", folder, toPutInOutBuffer );
	
	SetNativeString( 3, toPutInOutBuffer, GetNativeCell(4) );
	
	return true;
}

//== GetFolders

public Native_PrecacheSoundsFolder(Handle:hPlugin, iNumParams)
{
	decl String:szFolder[ 256 ];
	decl String:szExt[ 256 ];
	
	GetNativeString( 1, szFolder, sizeof(szFolder) );
	GetNativeString( 2, szExt, sizeof(szExt) );
	new recurse = GetNativeCell( 3 ) != 0 ? FLAG_READ_RECURSE : 0;
	
	if ( StrEqual( szExt, "" ) )
	{
		strcopy( szExt, sizeof(szExt), g_szSoundExts );
	}
	
	
	new retval;
	
	new Handle:dir = openDirFromNative( szFolder, 1 );
	
	if ( dir != INVALID_HANDLE )
	{
		retval = readDir( dir, szFolder, FLAG_READ_FROM_NATIVE | FLAG_READ_SOUND | recurse, szExt );
		
		CloseHandle( dir );
	}
	else
	{
		retval = -1;
	}
	
	return retval;
}
public Native_PrecacheModelsFolder(Handle:hPlugin, iNumParams)
{
	decl String:szFolder[ 256 ];
	decl String:szExt[ 256 ];
	
	GetNativeString( 1, szFolder, sizeof(szFolder) );
	GetNativeString( 2, szExt, sizeof(szExt) );
	new recurse = GetNativeCell( 3 ) != 0 ? FLAG_READ_RECURSE : 0;
	
	if ( StrEqual( szExt, "" ) )
	{
		strcopy( szExt, sizeof(szExt), g_szModelExts );
	}
	
	
	new retval;
	
	new Handle:dir = openDirFromNative( szFolder, 2 );
	
	if ( dir != INVALID_HANDLE )
	{
		retval = readDir( dir, szFolder, FLAG_READ_FROM_NATIVE | FLAG_READ_MODEL | recurse, szExt );
		
		CloseHandle( dir );
	}
	else
	{
		retval = -1;
	}
	
	return retval;
}
public Native_PrecacheDecalsFolder(Handle:hPlugin, iNumParams)
{
	decl String:szFolder[ 256 ];
	decl String:szExt[ 256 ];
	
	GetNativeString( 1, szFolder, sizeof(szFolder) );
	GetNativeString( 2, szExt, sizeof(szExt) );
	new recurse = GetNativeCell( 3 ) != 0 ? FLAG_READ_RECURSE : 0;
	
	if ( StrEqual( szExt, "" ) )
	{
		strcopy( szExt, sizeof(szExt), g_szDecalExts );
	}
	
	
	new retval;
	
	new Handle:dir = openDirFromNative( szFolder, 3 );
	
	if ( dir != INVALID_HANDLE )
	{
		retval = readDir( dir, szFolder, FLAG_READ_FROM_NATIVE | FLAG_READ_DECAL | recurse, szExt );
		
		CloseHandle( dir );
	}
	else
	{
		retval = -1;
	}
	
	return retval;
}
public Native_PrecacheGenericsFolder(Handle:hPlugin, iNumParams)
{
	decl String:szFolder[ 256 ];
	decl String:szExt[ 256 ];
	
	GetNativeString( 1, szFolder, sizeof(szFolder) );
	GetNativeString( 2, szExt, sizeof(szExt) );
	new recurse = GetNativeCell( 3 ) != 0 ? FLAG_READ_RECURSE : 0;
	
	if ( StrEqual( szExt, "" ) )
	{
		strcopy( szExt, sizeof(szExt), g_szGenericExts );
	}
	
	
	new retval;
	
	new Handle:dir = openDirFromNative( szFolder, 4 );
	
	if ( dir != INVALID_HANDLE )
	{
		retval = readDir( dir, szFolder, FLAG_READ_FROM_NATIVE | FLAG_READ_GENERIC | recurse, szExt );
		
		CloseHandle( dir );
	}
	else
	{
		retval = -1;
	}
	
	return retval;
}
public Native_AddToDownloadTableFolder(Handle:hPlugin, iNumParams)
{
	decl String:szFolder[ 256 ];
	decl String:szExt[ 256 ];
	
	GetNativeString( 1, szFolder, sizeof(szFolder) );
	GetNativeString( 2, szExt, sizeof(szExt) );
	new recurse = GetNativeCell( 3 ) != 0 ? FLAG_READ_RECURSE : 0;
	
	if ( StrEqual( szExt, "" ) )
	{
		strcopy( szExt, sizeof(szExt), g_szDownloadOnlyExts );
	}
	
	
	new retval;
	
	new Handle:dir = openDirFromNative( szFolder, 5 );
	
	if ( dir != INVALID_HANDLE )
	{
		retval = readDir( dir, szFolder, FLAG_READ_FROM_NATIVE | FLAG_READ_DOWNLOADONLY | recurse, szExt );
		
		CloseHandle( dir );
	}
	else
	{
		retval = -1;
	}
	
	return retval;
}
public Native_RegisterFolder(Handle:hPlugin, iNumParams)
{
	decl String:szFolder[ 256 ];
	decl String:szExt[ 256 ];
	
	GetNativeString( 1, szFolder, sizeof(szFolder) );
	GetNativeString( 2, szExt, sizeof(szExt) );
	new recurse = GetNativeCell( 3 ) != 0 ? FLAG_READ_RECURSE : 0;
	
	if ( StrEqual( szExt, "" ) )
	{
		strcopy( szExt, sizeof(szExt), g_szNoDownloadExts );
	}
	
	
	new retval;
	
	new Handle:dir = openDirFromNative( szFolder, 6 );
	
	if ( dir != INVALID_HANDLE )
	{
		retval = readDir( dir, szFolder, FLAG_READ_FROM_NATIVE | FLAG_READ_NODOWNLOAD | recurse, szExt );
		
		CloseHandle( dir );
	}
	else
	{
		retval = -1;
	}
	
	return retval;
}

//== privates @ natives

Handle:openDirFromNative(const String:dirPath[], source) //source = easier to find source if bug just from log
{
	if ( !DirExists( dirPath ) )
	{
		LogError("openDirFromNative::Couldn't find directory '%s'", dirPath);
		return INVALID_HANDLE;
	}
	
	new Handle:dir = OpenDirectory( dirPath );
	if ( dir == INVALID_HANDLE )
	{
		LogError("openDirFromNative::Couldn't open directory '%s' for reading; source = %d", dirPath, source);
	}
	
	return dir;
}