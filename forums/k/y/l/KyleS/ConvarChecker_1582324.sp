#pragma semicolon 1
#include <sourcemod>

#define MAXCVARVALUELENGTH 12
#define MAXCVARLENGTH 256
#define FILECOUNT 2

#define PLUGIN_VERSION "1.1b"
#define PLUGIN_DESCRIPTION "Attempts to detect Cheating."

enum ComparisonType
{
	iCompStrEqual = 0,
	iCompGreater,
	iCompLess,
	iCompBound,
	iCompFloatEqual,
	iCompNonExist,
};

enum DealWithAction
{
	iDWAKickClient = 0,
	iDWABanClient,
};

enum FileNames
{
	iSlowAdditions = 0,
	iSlowRemovals,
};

public Plugin:myinfo =
{
    name 		=		"FAC - Convar Checker",			// https://www.youtube.com/watch?v=Rw7aMVvPDmc&hd=1
    author		=		"Kyle Sanderson",
    description	=		PLUGIN_DESCRIPTION,
    version		=		PLUGIN_VERSION,
    url			=		"http://SourceMod.net"
};

new bool:g_bClientCheckedIn[MAXPLAYERS+1] = {true, ...};
new String:g_sCurrentConVar[MAXCVARLENGTH];
new g_iClientDetected[MAXPLAYERS+1];

new Handle:g_hCVarHandleTrie;
new Handle:g_hIterationCvarNameArray;
new Handle:g_hStorageArray;

new Handle:g_hTimerHandle = INVALID_HANDLE;

new g_iFileTime[FILECOUNT];

/* ConVars */
new Float:g_fTimerTime;
new g_iCvarCheckCount;
new g_iKickRatioLimit;
new g_iAction;
new g_iBanTime;

public OnPluginStart()
{
	g_hIterationCvarNameArray = CreateArray(MAXCVARLENGTH);
	g_hStorageArray = CreateArray(MAXCVARVALUELENGTH);
	g_hCVarHandleTrie = CreateTrie();
	
	decl String:sConVarName[MAXCVARLENGTH], bool:bIsCommand, iFlags;
	
	new Handle:hSearchHandle = FindFirstConCommand(sConVarName, sizeof(sConVarName), bIsCommand, iFlags);
	new Handle:hToCVar = INVALID_HANDLE;
	if (!bIsCommand && ((iFlags & FCVAR_REPLICATED) || (iFlags & FCVAR_CHEAT)) && !(iFlags & FCVAR_PROTECTED) && !(iFlags & FCVAR_PLUGIN) && !(iFlags & FCVAR_DONTRECORD) && (StrContains(sConVarName, "_version") == -1))
	{
		hToCVar = FindConVar(sConVarName);
		SetTrieValue(g_hCVarHandleTrie, sConVarName, hToCVar);
		PushArrayString(g_hIterationCvarNameArray, sConVarName);
	}
	
	while (FindNextConCommand(hSearchHandle, sConVarName, sizeof(sConVarName), bool:bIsCommand, iFlags))
	{
		if (bIsCommand || ((iFlags & FCVAR_PROTECTED) || (iFlags & FCVAR_DONTRECORD) || (iFlags & FCVAR_PLUGIN)) || !(iFlags & FCVAR_REPLICATED) && !(iFlags & FCVAR_CHEAT) || (StrContains(sConVarName, "_version", false) != -1)) // sourcemod_version is not tagged with FCVAR_PLUGIN because it no longer exists in the SDK. For shame Valve.
		{
			continue;
		}
		
		hToCVar = FindConVar(sConVarName);
		
		SetTrieValue(g_hCVarHandleTrie, sConVarName, hToCVar);
		PushArrayString(g_hIterationCvarNameArray, sConVarName);
	}
	
	RandomizeConVars();
	//RegConsoleCmd("sm_dump_convars", OnDumpConvars);
	
	CreateConVar("sm_fac_convarcheck_verison", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	new Handle:hRandom;
	HookConVarChange((hRandom = CreateConVar("fac_convarcheck_timertime",	"5.0",	"How often should I be querying for values? (0 to disable)", _, true, 0.0)),	OnQueryTimeChange);
	g_fTimerTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("fac_convarcheck_checkcount",	"5",	"How many checks should I do before moving on?", _, true, 0.0)),	OnCheckCountChange);
	g_iCvarCheckCount = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("fac_convarcheck_ratiocheck",	"75",	"If the ratio is higher then this, something has gone terribly wrong.", _, true, 0.0)),	OnKickRatioChange);
	g_iKickRatioLimit = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("fac_convarcheck_detectionaction",	"1",	"0 = Kick, 1 = Ban", _, true, 0.0, true, 1.0)),	OnActionChange);
	g_iAction = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("fac_convarcheck_banduration",	"0",	"Ban Length. 0 = Permanent. Onwards = Minutes.", _, true, 0.0, true, 1.0)),	OnBanTimeChange);
	g_iBanTime = GetConVarInt(hRandom);
}
/*
public Action:OnDumpConvars(client, argc)
{
	new iArraySize = GetArraySize(g_hIterationCvarNameArray);
	new Handle:hFile = OpenFile("dump.txt", "w+");
	decl String:sString[256];
	for (new i; i < iArraySize; i++)
	{
		GetArrayString(g_hIterationCvarNameArray, i, sString, sizeof(sString));
		WriteFileLine(hFile, sString);
	}
	
	CloseHandle(hFile);
	return Plugin_Handled;
}
*/
public OnConfigsExecuted()
{
	ResetTempData();
	ParseFiles();
	GetNewConVar();
	RestartCheckTimer();
}

public OnMapEnd()
{
	g_hTimerHandle = INVALID_HANDLE;
}

static stock ParseFiles()
{
	new bool:bChanged;
	decl String:sPathToSM[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPathToSM, sizeof(sPathToSM), "");
	
	decl String:sBuffer[PLATFORM_MAX_PATH];
	FormatEx(sBuffer, sizeof(sBuffer), "%sconfigs/FAC/AdditionsSlowThread.cfg", sPathToSM);
	
	new iTime;
	new Handle:hFile;
	new Handle:hToConVar;
	if (FileExists(sBuffer))
	{
		iTime = GetFileTime(sBuffer, FileTime_LastChange);
		if (iTime != g_iFileTime[iSlowAdditions])
		{
			hFile = OpenFile(sBuffer, "r");
			while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
			{
				TrimString(sBuffer);
				
				if ((sBuffer[0] == '/' && sBuffer[1] == '/') || sBuffer[0] == '#' || sBuffer[0] == '\n' || sBuffer[0] == '\0' || sBuffer[0] == '\r')
				{
					continue;
				}
				
				hToConVar = FindConVar(sBuffer);
				
				if (hToConVar != INVALID_HANDLE)
				{
					PushArrayString(g_hIterationCvarNameArray, sBuffer);
					SetTrieValue(g_hCVarHandleTrie, sBuffer, hToConVar);
				}
				else
				{
					LogError("Unable to Find: \"%s\".", sBuffer);
				}
			}
			
			CloseHandle(hFile);
			g_iFileTime[iSlowAdditions] = iTime;
			bChanged = true;
		}
	}
	
	FormatEx(sBuffer, sizeof(sBuffer), "%sconfigs/FAC/RemovalsSlowThread.cfg", sPathToSM);
	if (FileExists(sBuffer))
	{
		iTime = GetFileTime(sBuffer, FileTime_LastChange);
		if (iTime != g_iFileTime[iSlowRemovals])
		{
			new iArrayPos;
			hFile = OpenFile(sBuffer, "r");
			while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
			{
				TrimString(sBuffer);
				
				if ((sBuffer[0] == '/' && sBuffer[1] == '/') || sBuffer[0] == '#' || sBuffer[0] == '\n' || sBuffer[0] == '\0' || sBuffer[0] == '\r')
				{
					continue;
				}
				
				if (GetTrieValue(g_hCVarHandleTrie, sBuffer, hToConVar))
				{
					iArrayPos = FindStringInArray(g_hIterationCvarNameArray, sBuffer);
					if (iArrayPos != -1) // If it doesn't exist, or we already removed it. Why the hell would we error/print? That's such a KAC thing to do.
					{
						RemoveFromArray(g_hIterationCvarNameArray, iArrayPos);
					}
				}
				else
				{
					LogError("Unable to Find: \"%s\".\nThis plugin was probably never calling it, or there was an engine change.", sBuffer);
				}
			}
			
			CloseHandle(hFile);
			g_iFileTime[iSlowRemovals] = iTime;
			bChanged = true;
		}
	}
	
	if (bChanged)
	{
		RandomizeConVars();
	}
}

static stock RestartCheckTimer()
{
	if (g_hTimerHandle != INVALID_HANDLE)
	{
		CloseHandle(g_hTimerHandle);
	}
	
	if (g_fTimerTime == 0.0)
	{
		g_hTimerHandle = INVALID_HANDLE;
	}
	else
	{
		g_hTimerHandle = CreateTimer(g_fTimerTime, ConvarChecking, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

public Action:ConvarChecking(Handle:Timer)
{
	static iQueryCount;
	if (iQueryCount == g_iCvarCheckCount)
	{
		KickOutstandingClients();
		ResetTempData();
		GetNewConVar();
		iQueryCount = 0;
	}
	else
	{
		decl String:sCurrentConVar[sizeof(g_sCurrentConVar)];
		strcopy(sCurrentConVar, sizeof(sCurrentConVar), g_sCurrentConVar);
		
		decl String:sCurrentConVarValue[MAXCVARLENGTH];
		new Handle:hConVar;
		
		GetTrieValue(g_hCVarHandleTrie, sCurrentConVar, hConVar);
		
		GetConVarString(hConVar, sCurrentConVarValue, sizeof(sCurrentConVarValue));
		new iArrayPos = GetArraySize(g_hStorageArray);
		
		PushArrayString(g_hStorageArray, sCurrentConVarValue);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (g_bClientCheckedIn[i])
			{
				continue;
			}
			
			QueryClientConVar(i, sCurrentConVar, OnQueryFinished, iArrayPos);
		}
		
		iQueryCount++;
	}
}

static stock KickOutstandingClients()
{
	new iBadPlayerRatio = GetBadPlayerRatio();
	if (iBadPlayerRatio == 0)
	{
		return;
	}
	
	if (iBadPlayerRatio >= g_iKickRatioLimit)
	{
		LogError("WARNING: I was about to do something nasty to %i percent of the server because they all failed the check for %s.\nI highly suggest blacklisting this convar.", iBadPlayerRatio, g_sCurrentConVar);
		return;
	}
	
	decl String:sMessage[256];
	decl String:sTemp[128];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (g_iClientDetected[i])
		{
			switch (g_iAction)
			{
				case iDWAKickClient:
				{
					KickClient(i, "Comparison fail for %s.", g_sCurrentConVar);
				}
				
				case iDWABanClient:
				{
					InsertServerCommand("sm_ban #%i %i \"FAC: Convar Violation (%s).\"", GetClientUserId(i), g_iBanTime, g_sCurrentConVar);
					KickClient(i, "Comparison fail for %s.", g_sCurrentConVar);
				}
			}
		}
		else if (!g_bClientCheckedIn[i])
		{
			FormatEx(sMessage, sizeof(sMessage), "%N Info:( ", i);
			
			if (GetClientAuthString(i, sTemp, sizeof(sTemp)))
			{
				Format(sMessage, sizeof(sMessage), "%sAuth: \"%s\" | ", sMessage, sTemp);	
			}
			
			if (GetClientIP(i, sTemp, sizeof(sTemp)))
			{
				Format(sMessage, sizeof(sMessage), "%sIP Address: \"%s\"", sMessage, sTemp);
			}
			
			Format(sMessage, sizeof(sMessage), "%s ) Failed to respond intime for ConVar: %s", sMessage, g_sCurrentConVar);
			LogMessage("%s", sMessage);
			KickClient(i, "Failed to respond to a Query in time.");
		}
	}
}

static stock RandomizeConVars()
{
	new iArraySize = (GetArraySize(g_hIterationCvarNameArray)-1);
	new iXRandSize = (iArraySize * GetRandomInt(0,3));
	new iRand;
	new iRand2;
	SortADTArray(g_hIterationCvarNameArray, Sort_Random, Sort_String);
	for (new i; i < iXRandSize; i++)
	{
		iRand = GetURandomInt()+GetRandomInt(0, iArraySize);
		iRand2 = GetRandomInt(0, iArraySize);
		iRand = iRand-GetURandomInt();
		iRand = GetRandomInt(0, iArraySize);
		SwapArrayItems(g_hIterationCvarNameArray, iRand, iRand2); // Good luck Figuring this out >:o
	}
}

static stock GetNewConVar()
{
	static iCurrentArrayIndex;
	new iArraySize = (GetArraySize(g_hIterationCvarNameArray) - 1); // -1 because GetArraySize counts index 0 as 1, which is proper.
	new Handle:hToCvar;
	
	if (g_sCurrentConVar[0] != '\0')
	{
		GetTrieValue(g_hCVarHandleTrie, g_sCurrentConVar, hToCvar);
		UnhookConVarChange(hToCvar, OnTempHookChange);
	}
	
	if (iCurrentArrayIndex >= iArraySize)
	{
		RandomizeConVars();
		iCurrentArrayIndex = 0;
	}
	else
	{
		SwapArrayItems(g_hIterationCvarNameArray, iCurrentArrayIndex, GetRandomInt(0, iArraySize)); // Since the loop can take a _very_ long to recurse, this stops cheating.
		iCurrentArrayIndex++;
	}
	
	GetArrayString(g_hIterationCvarNameArray, iCurrentArrayIndex, g_sCurrentConVar, sizeof(g_sCurrentConVar));
	GetTrieValue(g_hCVarHandleTrie, g_sCurrentConVar, hToCvar);
	HookConVarChange(hToCvar, OnTempHookChange);
}

static stock ResetTempData()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			g_bClientCheckedIn[i] = false;
		}
		else if (!g_bClientCheckedIn[i])
		{
			g_bClientCheckedIn[i] = true;
		}
	}
	
	ClearArray(g_hStorageArray);
}

public OnQueryFinished(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:iValue)
{
	if (g_bClientCheckedIn[client])
	{
		return; // This client has already been checked / is invalid.
	}
	
	if (strncmp(g_sCurrentConVar, cvarName, strlen(g_sCurrentConVar), false) != 0)
	{
		return; // The client replied late... Really late. We don't want to invalidate them though as a cheat could be trying to fool us.
	}
	
	g_bClientCheckedIn[client] = true; // This invalidates the client.
	
	if (result != ConVarQuery_Okay)
	{
		g_iClientDetected[client] = true;
		return;
	}
	
	decl String:sStoredValue[MAXCVARVALUELENGTH];
	GetArrayString(g_hStorageArray, iValue, sStoredValue, sizeof(sStoredValue));
	
	if ((strncmp(cvarValue, sStoredValue, strlen(sStoredValue), false) == 0) || (FindStringInArray(g_hStorageArray, cvarValue) != -1))
	{
		return; // If this doesn't pass we have a potential issue. However, we want to be damn sure it isn't a bug.
	}
	
	new Handle:hConVar = INVALID_HANDLE; // Since we're only using this for storage, it's a single cell and doesn't have to be closed as it's pointing to an existing handle.
	GetTrieValue(g_hCVarHandleTrie, cvarName, hConVar);
	
	if (hConVar == INVALID_HANDLE) // This is a very lame trap that should never happen.
	{
		if ((hConVar = FindConVar(cvarName)) == INVALID_HANDLE)
		{
			return; // We'll let the client off the hook as we couldn't get a handle...
		}
		else
		{
			SetTrieValue(g_hCVarHandleTrie, cvarName, hConVar);
		}
	}
	
	decl String:sCurrConVarValue[MAXCVARVALUELENGTH];
	GetConVarString(hConVar, sCurrConVarValue, sizeof(sCurrConVarValue));
	
	if (strncmp(cvarValue, sCurrConVarValue, strlen(sCurrConVarValue), false) == 0)
	{
		return; // If this doesn't pass... Ban and ask questions later.
	}
	
	g_iClientDetected[client] = true; // We can store their failure if we want. But at the moment? Lets not bother.
}

public OnQueryTimeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fTimerTime = GetConVarFloat(convar);
	RestartCheckTimer();
}

public OnCheckCountChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iCvarCheckCount = GetConVarInt(convar);
}

public OnKickRatioChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iKickRatioLimit = GetConVarInt(convar);
}

public OnTempHookChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	PushArrayString(g_hStorageArray, newValue);
}

public OnBanTimeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iBanTime = GetConVarInt(convar);
}

public OnActionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iAction = GetConVarInt(convar);
}

public OnClientDisconnect_Post(client)
{
	g_bClientCheckedIn[client] = true;
	g_iClientDetected[client] = false;
}

static stock GetPlayerRealCount()
{
	new iCount;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			iCount++;
		}
	}
	
	return iCount;
}

static stock GetBadPlayerRatio()
{
	new iCount;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_iClientDetected[i])
		{
			iCount++;
		}
	}
	
	if (iCount == 0)
	{
		return 0;
	}
	
	return RoundToCeil(float(iCount / GetPlayerRealCount()) * 100);
}