#pragma semicolon 1
#include <sourcemod>
#tryinclude <steamtools>

#define PLUGIN_VERSION "1.1"
#define PLUGIN_DESCRIPTION "Redux of Web Shortcuts and Dynamic MOTD Functionality"

public Plugin:myinfo =
{
    name 		=		"Web Shortcuts",				/* https://www.youtube.com/watch?v=h6k5jwllFfA&hd=1 */
    author		=		"Kyle Sanderson, Nicholas Hastings",
    description	=		PLUGIN_DESCRIPTION,
    version		=		PLUGIN_VERSION,
    url			=		"http://SourceMod.net"
};

enum _:States {
	Game_TF2 = (1<<0),
	Game_L4D = (1<<1),
	Big_MOTD = (1<<8)
};

new g_iGameMode;

enum _:FieldCheckFlags
{
	Flag_Steam_ID			=	(1<<0),
	Flag_User_ID			=	(1<<1),
	Flag_Friend_ID			=	(1<<2),
	Flag_Name				=	(1<<3),
	Flag_IP					=	(1<<4),
	Flag_Language			=	(1<<5),
	Flag_Rate				=	(1<<6),
	Flag_Server_IP			=	(1<<7),
	Flag_Server_Port		=	(1<<8),
	Flag_Server_Name		=	(1<<9),
	Flag_Server_Custom		=	(1<<10),
	Flag_L4D_GameMode		=	(1<<11),
	Flag_Current_Map		=	(1<<12),
	Flag_Next_Map			=	(1<<13),
	Flag_GameDir			=	(1<<14),
	Flag_CurPlayers			=	(1<<15),
	#if defined _steamtools_included
	Flag_MaxPlayers			=	(1<<16),
	Flag_VACStatus			=	(1<<17),
	Flag_Server_Pub_IP		=	(1<<18),
	Flag_Steam_ConnStatus	=	(1<<19)
	#else
	Flag_MaxPlayers			=	(1<<16)
	#endif  /* _steamtools_included	 */
}; 

#define IsTeamFortress2() (g_iGameMode & Game_TF2)
#define IsLeftForDead() (g_iGameMode & Game_L4D)
#define GoLargeOrGoHome() (IsTeamFortress2() && (g_iGameMode & Big_MOTD))

/*#include "Duck"*/

new Handle:g_hIndexArray = INVALID_HANDLE;
new Handle:g_hFastLookupTrie = INVALID_HANDLE;

new Handle:g_hCurrentTrie = INVALID_HANDLE;
new String:g_sCurrentSection[128];

public OnPluginStart()
{
	g_hIndexArray = CreateArray(); /* We'll only use this for cleanup to prevent handle leaks and what not.
									  Our friend below doesn't have iteration, so we have to do this... */
	g_hFastLookupTrie = CreateTrie();
	
	AddCommandListener(Client_Say, "say");
	AddCommandListener(Client_Say, "say_team");
	
	/* From Psychonic */
	Duck_OnPluginStart();
	
	new Handle:cvarVersion = CreateConVar("webshortcutsredux_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	/* On a reload, this will be set to the old version. Let's update it. */
	SetConVarString(cvarVersion, PLUGIN_VERSION);
}

public Action:Client_Say(iClient, const String:sCommand[], argc)
{
	if (argc < 1 || !IsValidClient(iClient))
	{
		return Plugin_Continue; /* Well. While we can probably have blank hooks, I doubt anyone wants this. Lets not waste cycles. Let the game deal with this. */
	}
	
	decl String:sFirstArg[64]; /* If this is too small, let someone know. */
	GetCmdArg(1, sFirstArg, sizeof(sFirstArg));
	TrimString(sFirstArg);
	
	new Handle:hStoredTrie = INVALID_HANDLE;
	if (!GetTrieValue(g_hFastLookupTrie, sFirstArg, hStoredTrie) || hStoredTrie == INVALID_HANDLE) /* L -> R. Strings are R -> L, but that can change. */
	{
		return Plugin_Continue; /* Didn't find anything. Bug out! */
	}
	
	if (DealWithOurTrie(iClient, sFirstArg, hStoredTrie))
	{
		return Plugin_Handled; /* We want other hooks to be called, I guess. We just don't want it to go to the game. */
	}
	
	return Plugin_Continue; /* Well this is embarasing. We didn't actually hook this. Or atleast didn't intend to. */
}

public bool:DealWithOurTrie(iClient, const String:sHookedString[], Handle:hStoredTrie)
{
	decl String:sUrl[256];
	if (!GetTrieString(hStoredTrie, "Url", sUrl, sizeof(sUrl)))
	{
		LogError("Unable to find a Url for: \"%s\".", sHookedString);
		return false;
	}
	
	new iUrlBits;
	
	if (!GetTrieValue(hStoredTrie, "UrlBits", iUrlBits))
	{
		iUrlBits = 0; /* That's fine, there are no replacements! Less work for us. */
	}
	
	decl String:sTitle[256];
	new iTitleBits;
	if (!GetTrieString(hStoredTrie, "Title", sTitle, sizeof(sTitle)))
	{
		sTitle[0] = '\0'; /* We don't really need a title. Don't worry, it's cool. */
		iTitleBits = 0;
	}
	else
	{
		if (!GetTrieValue(hStoredTrie, "TitleBits", iTitleBits))
		{
			iTitleBits = 0; /* That's fine, there are no replacements! Less work for us. */
		}
	}
	
	Duck_DoReplacements(iClient, sUrl, iUrlBits, sTitle, iTitleBits); /* Arrays are passed by reference. Variables are copied. */
	
	new bool:bBig;
	new bool:bNotSilent = true;
	
	GetTrieValue(hStoredTrie, "Silent", bNotSilent);
	if (GoLargeOrGoHome())
	{
		GetTrieValue(hStoredTrie, "Big", bBig);
	}

	decl String:sMessage[256];
	if (GetTrieString(hStoredTrie, "Msg", sMessage, sizeof(sMessage)))
	{
		new iMsgBits;
		GetTrieValue(hStoredTrie, "MsgBits", iMsgBits);
		
		if (iMsgBits != 0)
		{
			Duck_DoReplacements(iClient, sMessage, iMsgBits, sMessage, 0); /* Lame Hack for now */
		}
		
		PrintToChatAll("%s", sMessage);
	}
	
	DisplayMOTDWithOptions(iClient, sTitle, sUrl, bBig, bNotSilent, MOTDPANEL_TYPE_URL);
	return true;
}

public ClearExistingData()
{
	new Handle:hHandle = INVALID_HANDLE;
	for (new i = (GetArraySize(g_hIndexArray) - 1); i >= 0; i--)
	{
		hHandle = GetArrayCell(g_hIndexArray, i);
		
		if (hHandle == INVALID_HANDLE)
		{
			continue;
		}
		
		CloseHandle(hHandle);
	}
	
	ClearArray(g_hIndexArray);
	ClearTrie(g_hFastLookupTrie);
}

public OnConfigsExecuted()
{
	ClearExistingData();
	
	decl String:sPath[256];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/Webshortcuts.txt");
	if (!FileExists(sPath))
	{
		return;
	}
	
	ProcessFile(sPath);
}

public ProcessFile(const String:sPathToFile[])
{
	new Handle:hSMC = SMC_CreateParser();
	SMC_SetReaders(hSMC, SMCNewSection, SMCReadKeyValues, SMCEndSection);
	
	new iLine;
	new SMCError:ReturnedError = SMC_ParseFile(hSMC, sPathToFile, iLine); /* Calls the below functions, then execution continues. */
	
	if (ReturnedError != SMCError_Okay)
	{
		decl String:sError[256];
		SMC_GetErrorString(ReturnedError, sError, sizeof(sError));
		if (iLine > 0)
		{
			LogError("Could not parse file (Line: %d, File \"%s\"): %s.", iLine, sPathToFile, sError);
			CloseHandle(hSMC); /* Sneaky Handles. */
			return;
		}
		
		LogError("Parser encountered error (File: \"%s\"): %s.", sPathToFile, sError);
	}

	CloseHandle(hSMC);
}

public SMCResult:SMCNewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	if (!opt_quotes)
	{
		LogError("Invalid Quoting used with Section: %s.", name);
	}
	
	strcopy(g_sCurrentSection, sizeof(g_sCurrentSection), name);
	
	if (GetTrieValue(g_hFastLookupTrie, name, g_hCurrentTrie))
	{
		return SMCParse_Continue;
	}
	else /* That's cool. Sounds like an initial insertion. Just wanted to make sure! */
	{
		g_hCurrentTrie = CreateTrie();
		PushArrayCell(g_hIndexArray, g_hCurrentTrie); /* Don't be leakin */
		SetTrieValue(g_hFastLookupTrie, name, g_hCurrentTrie);
		SetTrieString(g_hCurrentTrie, "Name", name);
	}
	
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
	else if (g_hCurrentTrie == INVALID_HANDLE)
	{
		return SMCParse_Continue;
	}
	
	switch (key[0])
	{
		case 'p','P':
		{
			if (!StrEqual(key, "Pointer", false))
			{
				return SMCParse_Continue;
			}
			
			new iFindValue;
			iFindValue = FindValueInArray(g_hIndexArray, g_hCurrentTrie);
			
			if (iFindValue > -1)
			{
				RemoveFromArray(g_hIndexArray, iFindValue);
			}
			
			if (g_sCurrentSection[0] != '\0')
			{
				RemoveFromTrie(g_hFastLookupTrie, g_sCurrentSection);
			}
			
			CloseHandle(g_hCurrentTrie); /* We're about to invalidate below */

			if (GetTrieValue(g_hFastLookupTrie, value, g_hCurrentTrie))
			{
				SetTrieValue(g_hFastLookupTrie, g_sCurrentSection, g_hCurrentTrie, true);
				return SMCParse_Continue;
			}

			g_hCurrentTrie = CreateTrie(); /* Ruhro, the thing this points to doesn't actually exist. Should we error or what? Nah, lets try and recover. */
			PushArrayCell(g_hIndexArray, g_hCurrentTrie); /* Don't be losin handles */
			SetTrieValue(g_hFastLookupTrie, g_sCurrentSection, g_hCurrentTrie, true);
			SetTrieString(g_hCurrentTrie, "Name", g_sCurrentSection, true);
		}
		
		case 'u','U':
		{
			if (!StrEqual(key, "Url", false))
			{
				return SMCParse_Continue;
			}
			
			SetTrieString(g_hCurrentTrie, "Url", value, true);
			
			new iBits;
			Duck_CalcBits(value, iBits); /* Passed by Ref */
			SetTrieValue(g_hCurrentTrie, "UrlBits", iBits, true);
		}
		
		case 'T','t':
		{
			if (!StrEqual(key, "Title", false))
			{
				return SMCParse_Continue;
			}
			
			SetTrieString(g_hCurrentTrie, "Title", value, true);
			
			new iBits;
			Duck_CalcBits(value, iBits); /* Passed by Ref */
			SetTrieValue(g_hCurrentTrie, "TitleBits", iBits, true);
		}
		
		case 'b','B':
		{
			if (!GoLargeOrGoHome() || !StrEqual(key, "Big", false)) /* Maybe they don't know they can't use it? Oh well. Protect the silly. */
			{
				return SMCParse_Continue;
			}
			
			SetTrieValue(g_hCurrentTrie, "Big", TranslateToBool(value), true);
		}
	
		case 'h','H':
		{
			if (!StrEqual(key, "Hook", false))
			{
				return SMCParse_Continue;
			}
			
			SetTrieValue(g_hFastLookupTrie, value, g_hCurrentTrie, true);
		}
		
		case 's', 'S':
		{
			if (!StrEqual(key, "Silent", false))
			{
				return SMCParse_Continue;
			}
			
			SetTrieValue(g_hCurrentTrie, "Silent", !TranslateToBool(value), true);
		}
		
		case 'M', 'm':
		{
			if (!StrEqual(key, "Msg", false))
			{
				return SMCParse_Continue;
			}
			
			SetTrieString(g_hCurrentTrie, "Msg", value, true);
			
			new iBits;
			Duck_CalcBits(value, iBits); /* Passed by Ref */
			
			SetTrieValue(g_hCurrentTrie, "MsgBits", iBits, true);
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult:SMCEndSection(Handle:smc)
{
	g_hCurrentTrie = INVALID_HANDLE;
	g_sCurrentSection[0] = '\0';
}

public bool:TranslateToBool(const String:sSource[])
{
	switch(sSource[0])
	{
		case '0', 'n', 'N', 'f', 'F':
		{
			return false;
		}
		
		case '1', 'y', 'Y', 't', 'T', 's', 'S':
		{
			return true;
		}
	}
	
	return false; /* Assume False */
}

public DisplayMOTDWithOptions(iClient, const String:sTitle[], const String:sUrl[], bool:bBig, bool:bNotSilent, iType)
{
	new Handle:hKv = CreateKeyValues("motd");

	if (bBig)
	{
		KvSetNum(hKv, "customsvr", 1);
	}
	
	KvSetNum(hKv, "type", iType);
	
	if (sTitle[0] != '\0')
	{
		KvSetString(hKv, "title", sTitle);
	}
		
	if (sUrl[0] != '\0')
	{
		KvSetString(hKv, "msg", sUrl);
	}
	
	ShowVGUIPanel(iClient, "info", hKv, bNotSilent);
	CloseHandle(hKv);
}

static stock bool:IsValidClient(iClient)
{
	return (0 < iClient <= MaxClients && IsClientInGame(iClient));
}

/* Psychonics Realm */

#define FIELD_CHECK(%1,%2);\
if (StrContains(source, %1) != -1) { field |= %2; }

#define TOKEN_STEAM_ID         "{STEAM_ID}"
#define TOKEN_USER_ID          "{USER_ID}"
#define TOKEN_FRIEND_ID        "{FRIEND_ID}"
#define TOKEN_NAME             "{NAME}"
#define TOKEN_IP               "{IP}"
#define TOKEN_LANGUAGE         "{LANGUAGE}"
#define TOKEN_RATE             "{RATE}"
#define TOKEN_SERVER_IP        "{SERVER_IP}"
#define TOKEN_SERVER_PORT      "{SERVER_PORT}"
#define TOKEN_SERVER_NAME      "{SERVER_NAME}"
#define TOKEN_SERVER_CUSTOM    "{SERVER_CUSTOM}"
#define TOKEN_L4D_GAMEMODE     "{L4D_GAMEMODE}"
#define TOKEN_CURRENT_MAP      "{CURRENT_MAP}"
#define TOKEN_NEXT_MAP         "{NEXT_MAP}"
#define TOKEN_GAMEDIR          "{GAMEDIR}"
#define TOKEN_CURPLAYERS       "{CURPLAYERS}"
#define TOKEN_MAXPLAYERS       "{MAXPLAYERS}"

#if defined _steamtools_included
#define TOKEN_VACSTATUS		   "{VAC_STATUS}"
#define TOKEN_SERVER_PUB_IP    "{SERVER_PUB_IP}"
#define TOKEN_STEAM_CONNSTATUS "{STEAM_CONNSTATUS}"	
new g_bSteamTools;
#endif  /* _steamtools_included */

/* Cached values */
new String:g_szServerIp[16];
new String:g_szServerPort[6];
/* These can all be larger but whole buffer holds < 128 */
new String:g_szServerName[128];
new String:g_szServerCustom[128];
new String:g_szL4DGameMode[128];
new String:g_szCurrentMap[128];
new String:g_szGameDir[64];



/*new Handle:g_hCmdQueue[MAXPLAYERS+1];*/

#if defined _steamtools_included
public Steam_FullyLoaded()
{
	g_bSteamTools = true;
}

public OnLibraryRemoved(const String:sLibrary[])
{
	if (!StrEqual(sLibrary, "SteamTools", false))
	{
		return;
	}
	
	g_bSteamTools = false;
}

#endif

public Duck_OnPluginStart()
{
	decl String:sGameDir[64];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if (!strncmp(sGameDir, "tf", 2, false) || !strncmp(sGameDir, "tf_beta", 7, false))
	{
		g_iGameMode |= Game_TF2;
		g_iGameMode |= Big_MOTD;
	}
	
	/* On a reload, these will already be registered and could be set to non-default */
	
	if (IsTeamFortress2())
	{
		/* AddCommandListener(Duck_TF2OnClose, "closed_htmlpage"); */
	}	
	
	LongIPToString(GetConVarInt(FindConVar("hostip")), g_szServerIp);	
	GetConVarString(FindConVar("hostport"), g_szServerPort, sizeof(g_szServerPort));
	
	new Handle:hostname = FindConVar("hostname");
	decl String:szHostname[256];
	GetConVarString(hostname, szHostname, sizeof(szHostname));
	Duck_UrlEncodeString(g_szServerName, sizeof(g_szServerName), szHostname);
	HookConVarChange(hostname, OnCvarHostnameChange);
	
	decl String:szCustom[256];
	new Handle:hCVARCustom = CreateConVar("WebShortcuts_Custom", "", "Custom String for this server.");
	GetConVarString(hCVARCustom, szCustom, sizeof(szCustom));
	Duck_UrlEncodeString(g_szServerCustom, sizeof(g_szServerCustom), szCustom);
	HookConVarChange(hCVARCustom, OnCvarCustomChange);
	
	new iSDKVersion = GuessSDKVersion();
	if (iSDKVersion == SOURCE_SDK_LEFT4DEAD || iSDKVersion == SOURCE_SDK_LEFT4DEAD2)
	{
		g_iGameMode |= Game_L4D;
		new Handle:hGameMode = FindConVar("mp_gamemode");
		decl String:szGamemode[256];
		GetConVarString(hGameMode, szGamemode, sizeof(szGamemode));
		Duck_UrlEncodeString(g_szL4DGameMode, sizeof(g_szL4DGameMode), szGamemode);
		HookConVarChange(hGameMode, OnCvarGamemodeChange);
	}
	
	Duck_UrlEncodeString(g_szGameDir, sizeof(g_szGameDir), sGameDir);
}

public OnMapStart()
{
	decl String:sTempMap[sizeof(g_szCurrentMap)];
	GetCurrentMap(sTempMap, sizeof(sTempMap));
	
	Duck_UrlEncodeString(g_szCurrentMap, sizeof(g_szCurrentMap), sTempMap);
}

stock Duck_DoReplacements(iClient, String:sUrl[256], iUrlBits, String:sTitle[256], iTitleBits) /* Huge thanks to Psychonic */
{
	if (iUrlBits & Flag_Steam_ID || iTitleBits & Flag_Steam_ID)
	{
		decl String:sSteamId[64];
		if (GetClientAuthString(iClient, sSteamId, sizeof(sSteamId)))
		{
			ReplaceString(sSteamId, sizeof(sSteamId), ":", "%3a");
			if (iTitleBits & Flag_Steam_ID)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_STEAM_ID, sSteamId);
			if (iUrlBits & Flag_Steam_ID)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_STEAM_ID, sSteamId);
		}
		else
		{
			if (iTitleBits & Flag_Steam_ID)
				ReplaceString(sTitle,   sizeof(sTitle),   TOKEN_STEAM_ID, "");
			if (iUrlBits & Flag_Steam_ID)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_STEAM_ID, "");
		}
	}
	
	if (iUrlBits & Flag_User_ID || iTitleBits & Flag_User_ID)
	{
		decl String:sUserId[16];
		IntToString(GetClientUserId(iClient), sUserId, sizeof(sUserId));
		if (iTitleBits & Flag_User_ID)
			ReplaceString(sTitle, sizeof(sTitle), TOKEN_USER_ID, sUserId);
		if (iUrlBits & Flag_User_ID)
			ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_USER_ID, sUserId);
	}
	
	if (iUrlBits & Flag_Friend_ID || iTitleBits & Flag_Friend_ID)
	{
		decl String:sFriendId[64];
		if (GetClientFriendID(iClient, sFriendId, sizeof(sFriendId)))
		{
			if (iTitleBits & Flag_Friend_ID)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_FRIEND_ID, sFriendId);
			if (iUrlBits & Flag_Friend_ID)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_FRIEND_ID, sFriendId);
		}
		else
		{
			if (iTitleBits & Flag_Friend_ID)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_FRIEND_ID, "");
			if (iUrlBits & Flag_Friend_ID)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_FRIEND_ID, "");
		}
	}
	
	if (iUrlBits & Flag_Name || iTitleBits & Flag_Name)
	{
		decl String:sName[MAX_NAME_LENGTH];
		if (GetClientName(iClient, sName, sizeof(sName)))
		{
			decl String:sEncName[sizeof(sName)*3];
			Duck_UrlEncodeString(sEncName, sizeof(sEncName), sName);
			if (iTitleBits & Flag_Name)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_NAME, sEncName);
			if (iUrlBits & Flag_Name)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_NAME, sEncName);
		}
		else
		{
			if (iTitleBits & Flag_Name)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_NAME, "");
			if (iUrlBits & Flag_Name)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_NAME, "");
		}
	}
	
	if (iUrlBits & Flag_IP || iTitleBits & Flag_IP)
	{
		decl String:sClientIp[32];
		if (GetClientIP(iClient, sClientIp, sizeof(sClientIp)))
		{
			if (iTitleBits & Flag_IP)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_IP, sClientIp);
			if (iUrlBits & Flag_IP)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_IP, sClientIp);
		}
		else
		{
			if (iTitleBits & Flag_IP)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_IP, "");
			if (iUrlBits & Flag_IP)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_IP, "");
		}
	}
	
	if (iUrlBits & Flag_Language || iTitleBits & Flag_Language)
	{
		decl String:sLanguage[32];
		if (GetClientInfo(iClient, "cl_language", sLanguage, sizeof(sLanguage)))
		{
			decl String:sEncLanguage[sizeof(sLanguage)*3];
			Duck_UrlEncodeString(sEncLanguage, sizeof(sEncLanguage), sLanguage);
			if (iTitleBits & Flag_Language)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_LANGUAGE, sEncLanguage);
			if (iUrlBits & Flag_Language)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_LANGUAGE, sEncLanguage);
		}
		else
		{
			if (iTitleBits & Flag_Language)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_LANGUAGE, "");
			if (iUrlBits & Flag_Language)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_LANGUAGE, "");
		}
	}
	
	if (iUrlBits & Flag_Rate || iTitleBits & Flag_Rate)
	{
		decl String:sRate[16];
		if (GetClientInfo(iClient, "rate", sRate, sizeof(sRate)))
		{
			/* due to iClient's rate being silly, this won't necessarily be all digits */
			decl String:sEncRate[sizeof(sRate)*3];
			Duck_UrlEncodeString(sEncRate, sizeof(sEncRate), sRate);
			if (iTitleBits & Flag_Rate)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_RATE, sEncRate);
			if (iUrlBits & Flag_Rate)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_RATE, sEncRate);
		}
		else
		{
			if (iTitleBits & Flag_Rate)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_RATE, "");
			if (iUrlBits & Flag_Rate)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_RATE, "");
		}
	}
	
	if (iTitleBits & Flag_Server_IP)
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_IP, g_szServerIp);
	if (iUrlBits & Flag_Server_IP)
		ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_SERVER_IP, g_szServerIp);
	
	if (iTitleBits & Flag_Server_Port)
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_PORT, g_szServerPort);
	if (iUrlBits & Flag_Server_Port)
		ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_SERVER_PORT, g_szServerPort);
	
	if (iTitleBits & Flag_Server_Name)
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_NAME, g_szServerName);
	if (iUrlBits & Flag_Server_Name)
		ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_SERVER_NAME, g_szServerName);	
	
	if (iTitleBits & Flag_Server_Custom)
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_CUSTOM, g_szServerCustom);
	if (iUrlBits & Flag_Server_Custom)
		ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_SERVER_CUSTOM, g_szServerCustom);
	
	if (IsLeftForDead() && ((iUrlBits & Flag_L4D_GameMode) || (iTitleBits & Flag_L4D_GameMode)))
	{
		if (iTitleBits & Flag_L4D_GameMode)
			ReplaceString(sTitle, sizeof(sTitle), TOKEN_L4D_GAMEMODE, g_szL4DGameMode);
		if (iUrlBits & Flag_L4D_GameMode)
			ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_L4D_GAMEMODE, g_szL4DGameMode);
	}
	
	if (iTitleBits & Flag_Current_Map)
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_CURRENT_MAP, g_szCurrentMap);
	if (iUrlBits & Flag_Current_Map)
		ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_CURRENT_MAP, g_szCurrentMap);
	
	if (iUrlBits & Flag_Next_Map || iTitleBits & Flag_Next_Map)
	{
		decl String:szNextMap[PLATFORM_MAX_PATH];
		if (GetNextMap(szNextMap, sizeof(szNextMap)))
		{
			if (iTitleBits & Flag_Next_Map)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_NEXT_MAP, szNextMap);
			if (iUrlBits & Flag_Next_Map)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_NEXT_MAP, szNextMap);
		}
		else
		{
			if (iTitleBits & Flag_Next_Map)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_NEXT_MAP, "");
			if (iUrlBits & Flag_Next_Map)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_NEXT_MAP, "");
		}
	}
	
	if (iTitleBits & Flag_GameDir)
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_GAMEDIR, g_szGameDir);
	if (iUrlBits & Flag_GameDir)
		ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_GAMEDIR, g_szGameDir);
	
	if (iUrlBits & Flag_CurPlayers || iTitleBits & Flag_CurPlayers)
	{
		decl String:sCurPlayers[10];
		IntToString(GetClientCount(false), sCurPlayers, sizeof(sCurPlayers));
		if (iTitleBits & Flag_CurPlayers)
			ReplaceString(sTitle, sizeof(sTitle), TOKEN_CURPLAYERS, sCurPlayers);
		if (iUrlBits & Flag_CurPlayers)
			ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_CURPLAYERS, sCurPlayers);
	}
	
	if (iUrlBits & Flag_MaxPlayers || iTitleBits & Flag_MaxPlayers)
	{
		decl String:maxplayers[10];
		IntToString(MaxClients, maxplayers, sizeof(maxplayers));
		if (iTitleBits & Flag_MaxPlayers)
			ReplaceString(sTitle, sizeof(sTitle), TOKEN_MAXPLAYERS, maxplayers);
		if (iUrlBits & Flag_MaxPlayers)
			ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_MAXPLAYERS, maxplayers);
	}
	
#if defined _steamtools_included	
	if (iUrlBits & Flag_VACStatus || iTitleBits & Flag_VACStatus)
	{
		if (g_bSteamTools && Steam_IsVACEnabled())
		{
			if (iTitleBits & Flag_VACStatus)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_VACSTATUS, "1");
			if (iUrlBits & Flag_VACStatus)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_VACSTATUS, "1");
		}
		else
		{
			if (iTitleBits & Flag_VACStatus)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_VACSTATUS, "0");
			if (iUrlBits & Flag_VACStatus)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_VACSTATUS, "0");
		}
	}
	
	if (iUrlBits & Flag_Server_Pub_IP || iTitleBits & Flag_Server_Pub_IP)
	{
		if (g_bSteamTools)
		{
			decl ip[4];
			decl String:sIPString[16];
			Steam_GetPublicIP(ip);
			FormatEx(sIPString, sizeof(sIPString), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
			
			if (iTitleBits & Flag_Server_Pub_IP)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_PUB_IP, sIPString);
			if (iUrlBits & Flag_Server_Pub_IP)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_SERVER_PUB_IP, sIPString);
		}
		else
		{
			if (iTitleBits & Flag_Server_Pub_IP)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_PUB_IP, "");
			if (iUrlBits & Flag_Server_Pub_IP)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_SERVER_PUB_IP, "");
		}
	}
	
	if (iUrlBits & Flag_Steam_ConnStatus || iTitleBits & Flag_Steam_ConnStatus)
	{
		if (g_bSteamTools && Steam_IsConnected())
		{
			if (iTitleBits & Flag_Steam_ConnStatus)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_STEAM_CONNSTATUS, "1");
			if (iUrlBits & Flag_Steam_ConnStatus)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_STEAM_CONNSTATUS, "1");
		}
		else
		{
			if (iTitleBits & Flag_Steam_ConnStatus)
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_STEAM_CONNSTATUS, "0");
			if (iUrlBits & Flag_Steam_ConnStatus)
				ReplaceString(sUrl,   sizeof(sUrl),   TOKEN_STEAM_CONNSTATUS, "0");
		}
	}
#endif  /* _steamtools_included */
}

stock bool:GetClientFriendID(client, String:sFriendID[], size) 
{
#if defined _steamtools_included
	Steam_GetCSteamIDForClient(client, sFriendID, size);
#else
	decl String:sSteamID[64];
	if (!GetClientAuthString(client, sSteamID, sizeof(sSteamID)))
	{
		sFriendID[0] = '\0'; /* Sanitize incase the return isn't checked. */
		return false;
	}
	
	TrimString(sSteamID); /* Just incase... */
	
	if (StrEqual(sSteamID, "STEAM_ID_LAN", false))
	{
		sFriendID[0] = '\0';
		return false;
	}
	
	decl String:toks[3][16];
	ExplodeString(sSteamID, ":", toks, sizeof(toks), sizeof(toks[]));
	
	new iServer = StringToInt(toks[1]);
	new iAuthID = StringToInt(toks[2]);
	new iFriendID = (iAuthID*2) + 60265728 + iServer;
	
	if (iFriendID >= 100000000)
	{
		decl String:temp[12], String:carry[12];
		FormatEx(temp, sizeof(temp), "%d", iFriendID);
		FormatEx(carry, 2, "%s", temp);
		new icarry = StringToInt(carry[0]);
		new upper = 765611979 + icarry;
		
		FormatEx(temp, sizeof(temp), "%d", iFriendID);
		FormatEx(sFriendID, size, "%d%s", upper, temp[1]);
	}
	else
	{
		Format(sFriendID, size, "765611979%d", iFriendID);
	}
	#endif
	return true;
}

Duck_CalcBits(const String:source[], &field)
{
	field = 0;
	
	FIELD_CHECK(TOKEN_STEAM_ID,    Flag_Steam_ID);
	FIELD_CHECK(TOKEN_USER_ID,     Flag_User_ID);
	FIELD_CHECK(TOKEN_FRIEND_ID,   Flag_Friend_ID);
	FIELD_CHECK(TOKEN_NAME,        Flag_Name);
	FIELD_CHECK(TOKEN_IP,          Flag_IP);
	FIELD_CHECK(TOKEN_LANGUAGE,    Flag_Language);
	FIELD_CHECK(TOKEN_RATE,        Flag_Rate);
	FIELD_CHECK(TOKEN_SERVER_IP,   Flag_Server_IP);
	FIELD_CHECK(TOKEN_SERVER_PORT, Flag_Server_Port);
	FIELD_CHECK(TOKEN_SERVER_NAME, Flag_Server_Name);
	FIELD_CHECK(TOKEN_SERVER_CUSTOM, Flag_Server_Custom);
	
	if (IsLeftForDead())
	{
		FIELD_CHECK(TOKEN_L4D_GAMEMODE, Flag_L4D_GameMode);
	}
	
	FIELD_CHECK(TOKEN_CURRENT_MAP, Flag_Current_Map);
	FIELD_CHECK(TOKEN_NEXT_MAP,    Flag_Next_Map);
	FIELD_CHECK(TOKEN_GAMEDIR,     Flag_GameDir);
	FIELD_CHECK(TOKEN_CURPLAYERS,  Flag_CurPlayers);
	FIELD_CHECK(TOKEN_MAXPLAYERS,  Flag_MaxPlayers);

#if defined _steamtools_included
	FIELD_CHECK(TOKEN_VACSTATUS,        Flag_VACStatus);
	FIELD_CHECK(TOKEN_SERVER_PUB_IP,    Flag_Server_Pub_IP);
	FIELD_CHECK(TOKEN_STEAM_CONNSTATUS, Flag_Steam_ConnStatus);
#endif
}

/* Courtesy of Mr. Asher Baker */
stock LongIPToString(ip, String:szBuffer[16])
{
	FormatEx(szBuffer, sizeof(szBuffer), "%i.%i.%i.%i", (((ip & 0xFF000000) >> 24) & 0xFF), (((ip & 0x00FF0000) >> 16) & 0xFF), (((ip & 0x0000FF00) >>  8) & 0xFF), (((ip & 0x000000FF) >>  0) & 0xFF));
}

/* loosely based off of PHP's urlencode */
stock Duck_UrlEncodeString(String:output[], size, const String:input[])
{
	new icnt = 0;
	new ocnt = 0;
	
	for(;;)
	{
		if (ocnt == size)
		{
			output[ocnt-1] = '\0';
			return;
		}
		
		new c = input[icnt];
		if (c == '\0')
		{
			output[ocnt] = '\0';
			return;
		}
		
		// Use '+' instead of '%20'.
		// Still follows spec and takes up less of our limited buffer.
		if (c == ' ')
		{
			output[ocnt++] = '+';
		}
		else if ((c < '0' && c != '-' && c != '.') ||
			(c < 'A' && c > '9') ||
			(c > 'Z' && c < 'a' && c != '_') ||
			(c > 'z' && c != '~')) 
		{
			output[ocnt++] = '%';
			Format(output[ocnt], size-strlen(output[ocnt]), "%x", c);
			ocnt += 2;
		}
		else
		{
			output[ocnt++] = c;
		}
		
		icnt++;
	}
}

public OnCvarHostnameChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Duck_UrlEncodeString(g_szServerName, sizeof(g_szServerName), newValue);
}

public OnCvarGamemodeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Duck_UrlEncodeString(g_szL4DGameMode, sizeof(g_szL4DGameMode), newValue);
}

public OnCvarCustomChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Duck_UrlEncodeString(g_szServerCustom, sizeof(g_szServerCustom), newValue);
}