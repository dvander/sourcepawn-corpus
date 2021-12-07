#pragma semicolon 1
#include <sourcemod>
#tryinclude <classbackend>

/* Defines */
#define PLUGIN_DESCRIPTION	"Provides a backend for player class plugins."
#define PLUGIN_VERSION		"1.0"

/* Natives */
#if defined _cb_included
#else								// Oh Web Compiler. How you hate us so.
native bool:CB_IsFullOfData();
native CB_GetTrieIndex(const String:sName[]);
native Handle:CB_GetSpecificTrie(iIndex);
native Handle:CB_GetMasterArray();
native Handle:CB_GetMasterTrie();
#endif

/* Forwards */
new Handle:g_hForwardOnTrieClear = INVALID_HANDLE;
new Handle:g_hForwardOnTrieLoad = INVALID_HANDLE;

/* My Info */
public Plugin:myinfo = 
{
	name		=	"Class Backend",
	author		=	"Kyle Sanderson",
	description	=	PLUGIN_DESCRIPTION,		// http://www.youtube.com/watch?v=4-04x2ddZLQ
	version		=	PLUGIN_VERSION,
	url			=	"http://www.SourceMod.net"
};

/* Globals */
new bool:g_bIsFullOfData = false;

new Handle:g_hTrie;
new Handle:g_hArray;
new Handle:g_hCurrentTrie;

new String:g_sBuildPath[PLATFORM_MAX_PATH];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("CB_GetMasterArray", Native_GetMasterArrayHandle);
	CreateNative("CB_GetMasterTrie", Native_GetMasterTrieHandle);
	CreateNative("CB_IsFullOfData", Native_IsFullOfData);
	CreateNative("CB_GetSpecificTrie", Native_GetSpecificTrieHandle);
	CreateNative("CB_GetTrieIndex", Native_GetTrieIndex);
	
	g_hForwardOnTrieClear = CreateGlobalForward("CB_OnDataCleared", ET_Ignore);
	g_hForwardOnTrieLoad = CreateGlobalForward("CB_OnDataCached", ET_Ignore);
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_classbackend_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hTrie = CreateTrie();
	g_hArray = CreateArray();
	BuildPath(Path_SM, g_sBuildPath, sizeof(g_sBuildPath), "configs/ClassManager");
}

public OnConfigsExecuted()
{
	ClearExistingData();
	GetNewClassData();
}

public ClearExistingData()
{
	if (!g_bIsFullOfData)
	{
		return;
	}
	
	new Handle:hStoredHandle;
	
	for (new i = GetArraySize(g_hArray); i >= 0; i--)
	{
		hStoredHandle = GetArrayCell(g_hArray, i);
		if (hStoredHandle == INVALID_HANDLE) // Yeah yeah yeah... I know this is a silly trap
		{
			continue;
		}
		
		CloseHandle(hStoredHandle);
	}
	
	ClearArray(g_hArray);
	ClearTrie(g_hTrie);
	
	Call_StartForward(g_hForwardOnTrieClear);
	Call_Finish();
	
	g_bIsFullOfData = false;
}

public GetNewClassData() /* Elements taken from Berni/Graczu's MapConfigs plugin(s) */
{
	decl String:sPath[PLATFORM_MAX_PATH], String:sMap[PLATFORM_MAX_PATH], String:sFormatted[PLATFORM_MAX_PATH];

	FormatEx(sFormatted, sizeof(sFormatted), "%s/ALoad", g_sBuildPath);
	
	new Handle:hDir = OpenDirectory(sFormatted);
	
	if (hDir == INVALID_HANDLE)
	{
		ThrowError("Unable to open the directory: %s.", sFormatted);
	}
	
	new FileType:ReturnedFileType;	
	
	while (ReadDirEntry(hDir, sPath, sizeof(sPath), ReturnedFileType))
	{
		if ((sPath[0] == '.' && sPath[1] == '\0') || (sPath[1] == '.' && sPath[2] == '\0') || (ReturnedFileType != FileType_File))
		{
			continue;
		}

		Format(sPath, sizeof(sPath), "%s/%s", sFormatted, sPath);
		ProcessClassFile(sPath);
	}
	
	CloseHandle(hDir); // Thought you could sneak away eh? >:o
	
	hDir = OpenDirectory(g_sBuildPath);
	
	if (hDir == INVALID_HANDLE)
	{
		ThrowError("Unable to open the directory: %s.", g_sBuildPath);
	}

	if (!GetCurrentMap(sMap, sizeof(sMap)))
	{
		ThrowError("Unable to get the current map. I was probably called too early. Dropping out.");
	}
	
	while (ReadDirEntry(hDir, sPath, sizeof(sPath), ReturnedFileType))
	{
		if ((sPath[0] == '.' && sPath[1] == '\0') || (sPath[1] == '.' && sPath[2] == '\0') || (ReturnedFileType != FileType_File))
		{
			continue;
		}
		
		strcopy(sFormatted, sizeof(sFormatted), sPath);
		
		for (new i = strlen(sFormatted); i > 0; i--) // Stripping the file extension for the map check, if any.
		{
			if (sFormatted[i] != '.')
			{
				continue;
			}
			
			sFormatted[i] = '\0';
			break;
		}
		
		if ((StrContains(sMap, sFormatted, false) > -1) && (strncmp(sFormatted, sMap, strlen(sFormatted), false) == 0))
		{
			Format(sPath, sizeof(sPath), "%s/%s", g_sBuildPath, sPath);
			ProcessClassFile(sPath);
		}
	}

	Call_StartForward(g_hForwardOnTrieLoad);
	Call_Finish();
	
	CloseHandle(hDir); // Thought I'd forget about you eh? >:o
	
	if (GetArraySize(g_hArray))
	{
		g_bIsFullOfData = true;
	}
}
	
public ProcessClassFile(const String:sPath[]) /* Thanks to Psychonic for getting me going on SMC, and Dynamic Menu for being so clear. */
{
	new Handle:hSMC = SMC_CreateParser();
	SMC_SetReaders(hSMC, SMCNewSection, SMCReadKeyValues, SMCEndSection);

	PrintToServer("Loading: %s", sPath);
	
	new iLine;
	new SMCError:ReturnedError = SMC_ParseFile(hSMC, sPath, iLine); // Calls the below functions, then execution continues.
	
	if (ReturnedError != SMCError_Okay)
	{
		decl String:sError[256];
		SMC_GetErrorString(ReturnedError, sError, sizeof(sError));
		if (iLine > 0)
		{
			LogError("Could not parse file (Line: %d, File \"%s\"): %s.", iLine, sPath, sError);
			CloseHandle(hSMC); // Sneaky Handles.
			return;
		}
		
		LogError("Parser encountered error (File: \"%s\"): %s.", sPath, sError);
	}

	CloseHandle(hSMC);
}

public SMCResult:SMCNewSection(Handle:smc, const String:name[], bool:opt_quotes)
{	
	if ((!GetTrieValue(g_hTrie, name, g_hCurrentTrie)) || (g_hCurrentTrie == INVALID_HANDLE))
	{
		g_hCurrentTrie = CreateTrie();
	}
	
	SetTrieValue(g_hTrie, name, g_hCurrentTrie);
	PushArrayCell(g_hArray, g_hCurrentTrie);
}

public SMCResult:SMCReadKeyValues(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if (!key_quotes)
	{
		LogError("Invalid Quoting used with Key: %s", key);
	}
	
	else if (!value_quotes)
	{
		LogError("Invalid Quoting used with Key: \"%s\" Value: \"%s\"", key);
	}
	
	SetTrieString(g_hCurrentTrie, key, value, true);
}

public SMCResult:SMCEndSection(Handle:smc)
{
	g_hCurrentTrie = INVALID_HANDLE;
}

public Native_GetTrieIndex(Handle:hPlugin, numParams)
{
	new iVariable;
	GetNativeStringLength(1, iVariable);
	iVariable++;
	
	decl String:sString[iVariable];
	GetNativeString(1, sString, iVariable);
	
	iVariable = -1;
	GetTrieValue(g_hTrie, sString, iVariable);
	
	return iVariable;
}

public Native_GetMasterArrayHandle(Handle:hPlugin, numParams)
{
	return _:CloneHandle(g_hArray, hPlugin);
}

public Native_GetMasterTrieHandle(Handle:hPlugin, numParams)
{
	return _:CloneHandle(g_hTrie, hPlugin);
}

public Native_GetSpecificTrieHandle(Handle:hPlugin, numParams)
{
	new iValue = GetNativeCell(1);
	new iArraySize = GetArraySize(g_hArray);
	
	if (iValue > iArraySize || iValue < 0)
	{
		ThrowNativeError(SP_ERROR_ARRAY_BOUNDS, "Invalid Array Size. Asked: (%i) Max: (%i)", iValue, iArraySize);
	}
	
	new Handle:hReturn = GetArrayCell(g_hArray, iValue);
	
	if (hReturn == INVALID_HANDLE)
	{
		return _:INVALID_HANDLE;
	}
	
	return _:CloneHandle(hReturn, hPlugin);
}

public Native_IsFullOfData(Handle:hPlugin, numParams)
{
	return _:g_bIsFullOfData;
}