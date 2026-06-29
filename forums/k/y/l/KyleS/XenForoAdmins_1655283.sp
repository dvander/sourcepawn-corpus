#pragma semicolon 1
#include <dbi>
#include <sourcemod>

enum
{
	eIgnoreOCPACHook = (1<<0),
	eIgnoreORAC = (1<<1),
	eIgnoreFUSCFunc = (1<<2),
}

new Handle:g_hDBIConnection = INVALID_HANDLE;
new Handle:g_hFastLookupTrie = INVALID_HANDLE;

new g_iHookStates;

new GroupId:g_iXFGroupIndex = INVALID_GROUP_ID;
new g_iLastConnection = -1;

new String:g_sFieldName[65];
new Handle:g_hFieldName = INVALID_HANDLE;

public Plugin:myinfo =
{
    name 			=		"XenForo Admins",				/* https://www.youtube.com/watch?v=aAKwsma3QdE&hd=1 */
    author			=		"Kyle Sanderson",
    description		=		"Admin and XenForo integration.",
    version			=		"1.4",
    url					=		"http://SourceMod.net"
};

/* Huge Thanks to
	Jake Bunce		- Who actually knows the Answer to Everything.	http://xenforo.com/community/members/jake-bunce.9/
	Brian 				- Alpha, Beta, Release testing this.						https://plaguefest.com/members/brian.1/
	PlagueFest		- Taking the Step forward to test.						https://plaguefest.com
*/


public OnPluginStart()
{
	CreateConVar("sm_xenforo_admins", "1.3b", "Admin and XenForo integration", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hFieldName = CreateConVar("sm_xenforo_fieldname", "Steam", "XenForo SQL Field Name", FCVAR_PLUGIN|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_PROTECTED|FCVAR_NOT_CONNECTED);
	GetConVarString(g_hFieldName, g_sFieldName, sizeof(g_sFieldName));
	HookConVarChange(g_hFieldName, OnFieldNameChanged);
	
	g_hFastLookupTrie = CreateTrie();
	
	FireUpSQLConnection();
}

public OnMapEnd()
{
	g_iHookStates &= ~eIgnoreOCPACHook;
}

public OnConfigsExecuted()
{
	FireUpSQLConnection();
}

public OnRebuildAdminCache(AdminCachePart:part)
{
	if (g_iHookStates & eIgnoreORAC)
	{
		return;
	}
	
	g_iHookStates &= ~eIgnoreOCPACHook;
	g_iHookStates |= eIgnoreORAC;
	g_iHookStates |= eIgnoreFUSCFunc;
	SQL_TConnect(OnDBIConnectionEstablished, "xenforo");
}

public Action:OnClientPreAdminCheck(client)
{
	return (g_iHookStates & eIgnoreOCPACHook) ? Plugin_Continue : Plugin_Handled;
}

public FireUpSQLConnection()
{
	if ((g_iHookStates & eIgnoreFUSCFunc) || (g_iLastConnection >= (GetTime() - 360)) )
	{
		return;
	}
	
	g_iHookStates &= ~eIgnoreOCPACHook;
	g_iHookStates |= eIgnoreORAC;
	g_iHookStates |= eIgnoreFUSCFunc;
	SQL_TConnect(OnDBIConnectionEstablished, "xenforo");
}

public OnDBIConnectionEstablished(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (g_hDBIConnection != INVALID_HANDLE)
	{
		CloseHandle(g_hDBIConnection);
	}
	
	g_hDBIConnection = hndl;
	
	if (hndl == INVALID_HANDLE || error[0] != '\0')
	{
		LogError("Database Connection: \"%s\".", error);
		LateLoadAdminCall();
		return;
	}
	
	decl String:sQuery[512];
	decl String:sEscapedName[131];
	SQL_EscapeString(hndl, g_sFieldName, sEscapedName, sizeof(sEscapedName));
	
	FormatEx(sQuery, sizeof(sQuery), "\
   SELECT ufv.field_value, u.username, u.user_group_id, u.secondary_group_ids \
   FROM xf_user_field_value AS ufv \
   LEFT JOIN xf_user AS u ON (u.user_id = ufv.user_id) \
   WHERE ufv.field_id = '%s' \
   AND NOT ufv.field_value = '';", sEscapedName);
   
	SQL_TQuery(g_hDBIConnection, ThreadedOnAdminQueryDone,	sQuery);	/* Change 'Steam' to something else if this changes. IPB = rctsteam */
	g_iLastConnection = GetTime();
}

public ThreadedOnAdminQueryDone(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE || error[0] != '\0')
	{
		LogError("Database Query Error: \"%s\".", error);
		LateLoadAdminCall();
		return;
	}
	
	DumpAdminCache(AdminCache_Groups, true); /* All groups (automatically invalidates admins too) */
	
	if (!ReparseTranslations())
	{
		LateLoadAdminCall();
		return; /* Totally will not work. */
	}
	
	decl String:sSteamID[256];
	decl String:sName[256];
	new AdminId:iAdminID;
	new DBResult:iResult;

	while (SQL_FetchRow(hndl))
	{
		sSteamID[0] = '\0';
		
		SQL_FetchString(hndl, 0, sSteamID, sizeof(sSteamID), iResult);		/* SteamID */
		
		if (iResult != DBVal_Data)
		{
			continue; /* Can't do anything really without a SteamID. Something happened with the query. */
		}
		
		TrimString(sSteamID);
		
		iAdminID = FindAdminByIdentity(sSteamID, AUTHMETHOD_STEAM);
		
		if (iAdminID == INVALID_ADMIN_ID)
		{
			sName[0] = '\0';

			SQL_FetchString(hndl, 1, sName, sizeof(sName), iResult);		/* Name */
			if (iResult != DBVal_Data)
			{
				continue; /* Can't do anything really without a Name. Something happened with the query. */
			}
			
			TrimString(sName);
			
			iAdminID = CreateAdmin(sName);
			BindAdminIdentity(iAdminID, AUTHMETHOD_STEAM, sSteamID);
		}
		
		sName[0] = '\0';
		SQL_FetchString(hndl, 2, sName, sizeof(sName), iResult);		/* Primary Group */
		
		if (iResult != DBVal_Data)
		{
			continue; /* Can't do anything really without a Primary Group. */
		}
		
		TrimString(sName);
		
		SQL_FetchString(hndl, 3, sSteamID, sizeof(sSteamID), iResult);		/* Secondary Groups which we explode later */
		if (iResult == DBVal_Data)
		{
			TrimString(sSteamID);
			
			if (sSteamID[0] != '\0')
			{
				if (sName[0] != '\0')
				{
					Format(sName, sizeof(sName), "%s,%s", sName, sSteamID);
				}
				else
				{
					strcopy(sName, sizeof(sName), sSteamID);
				}
			}
		}
		
		if (sName[0] == '\0') /* Nothing is going to be added. Sadly. */
		{
			continue;
		}
		
		TrimString(sName);
		AddAdminToGroups(iAdminID, sName); /* Actually sGroups */
	}
	
	LateLoadAdminCall();
}

public AddAdminToGroups(AdminId:iAdminID, const String:sGroups[])
{
	new iStrSize = (strlen(sGroups) + 1);
	decl String:sConstruction[iStrSize]; /* Who knows what's going to happen. Scary. */
	
	new GroupId:iAdminGroup;
	new iCurPos;
	
	new iChar;
	
	for (new i; i < iStrSize; i++)
	{
		iChar = sGroups[i];
		if (iChar != ',' && iChar != '\0')
		{
			sConstruction[iCurPos] = iChar;
			iCurPos++;
			continue;
		}

		if (iCurPos == 0)
		{
			continue;
		}
		
		sConstruction[iCurPos] = '\0';
		
		TrimString(sConstruction);
		if (GetTrieValue(g_hFastLookupTrie, sConstruction, iAdminGroup))
		{
			AdminInheritGroup(iAdminID, iAdminGroup);
		}

		iCurPos = 0;
	}
}

public LateLoadAdminCall()
{
	g_iHookStates |= eIgnoreOCPACHook;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		RunAdminCacheChecks(i);
		NotifyPostAdminCheck(i);
	}
	
	g_iHookStates &= ~eIgnoreFUSCFunc;
	g_iHookStates &= ~eIgnoreORAC;
}

public bool:ReparseTranslations()
{
	decl String:sPath[256];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/XenForoAdminTranslations.cfg");
	
	if (!FileExists(sPath))
	{
		return false;
	}

	ClearTrie(g_hFastLookupTrie);

	new Handle:hSMC = SMC_CreateParser();
	SMC_SetReaders(hSMC, SMCNewSection, SMCReadKeyValues, SMCEndSection);
	
	new iLine;
	new SMCError:ReturnedError = SMC_ParseFile(hSMC, sPath, iLine); /* Calls the below functions, then execution continues. */
	
	if (ReturnedError != SMCError_Okay)
	{
		decl String:sError[256];
		SMC_GetErrorString(ReturnedError, sError, sizeof(sError));
		if (iLine > 0)
		{
			LogError("Could not parse file (Line: %d, File \"%s\"): %s.", iLine, sPath, sError);
			CloseHandle(hSMC); /* Sneaky Handles. */
			return true; /* Run with what we have. */
		}
		
		LogError("Parser encountered error (File: \"%s\"): %s.", sPath, sError);
	}

	CloseHandle(hSMC);
	return true;
}

public OnFieldNameChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_sFieldName, sizeof(g_sFieldName), newValue);
}

public SMCResult:SMCNewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	if (!opt_quotes)
	{
		LogError("Invalid Quoting used with Section: \"%s\".", name);
	}
	
	if (GetTrieValue(g_hFastLookupTrie, name, g_iXFGroupIndex))
	{
		return SMCParse_Continue; /* Cool! Saves the below */
	}
	/* That's cool. Sounds like an initial insertion. Just wanted to make sure! */
	
	g_iXFGroupIndex = CreateAdmGroup(name);
		
	if (g_iXFGroupIndex == INVALID_GROUP_ID)
	{
		g_iXFGroupIndex = FindAdmGroup(name);
	
		if (g_iXFGroupIndex ==  INVALID_GROUP_ID)
		{
			return SMCParse_Continue; /* No idea wtf is going on now. */
		}
	}
	
	SetTrieValue(g_hFastLookupTrie, name, g_iXFGroupIndex, true);
	return SMCParse_Continue;
}

public SMCResult:SMCReadKeyValues(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if (!key_quotes)
	{
		LogError("Invalid Quoting used with Key: \"%s\".", key);
	}
	else if (!value_quotes)
	{
		LogError("Invalid Quoting used with Key: \"%s\" Value: \"%s\".", key, value);
	}
	
	if (g_iXFGroupIndex == INVALID_GROUP_ID) /* Garbage in here. We can log an error if the user wishes to. Should Never Hapen though. */
	{
		return SMCParse_Continue;
	}
	
	switch (key[0])
	{

		case 'F','f':
		{
			if (!StrEqual("Flags", key, false))
			{
				return SMCParse_Continue;
			}
			
			new AdminFlag:iFoundFlag;
			for (new i = strlen(value); i >= 0; i--)
			{
				if (!FindFlagByChar(value[i], iFoundFlag))
				{
					continue;
				}
				
				SetAdmGroupAddFlag(g_iXFGroupIndex, iFoundFlag, true);
			}
		}

		case 'I','i':
		{
			if (!StrEqual("Immunity", key, false))
			{
				return SMCParse_Continue;
			}
			
			SetAdmGroupImmunityLevel(g_iXFGroupIndex, StringToInt(value));
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult:SMCEndSection(Handle:smc)
{
	g_iXFGroupIndex = INVALID_GROUP_ID;
}