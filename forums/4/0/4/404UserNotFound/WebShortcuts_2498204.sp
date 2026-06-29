#pragma semicolon 1
#include <sourcemod>
#tryinclude <steamtools>
#pragma newdecls required

#define PLUGIN_VERSION "1.2newsyntax"
#define PLUGIN_DESCRIPTION "Redux of Web Shortcuts and Dynamic MOTD Functionality"

public Plugin myinfo =
{
    name 		=		"Web Shortcuts",				/* https://www.youtube.com/watch?v=h6k5jwllFfA&hd=1 */
    author		=		"Kyle Sanderson, Nicholas Hastings, 404 (abrandnewday)",
    description	=		PLUGIN_DESCRIPTION,
    version		=		PLUGIN_VERSION,
    url			=		"http://SourceMod.net"
};

EngineVersion g_hEngineVersion;
bool g_bBigMOTDCompatible = false;
//int g_iGameMode;

#define FLAG_STEAM_ID					(1<<0)
#define FLAG_STEAM_ID3					(1<<1)
#define FLAG_USER_ID					(1<<2)
#define FLAG_FRIEND_ID					(1<<3)
#define FLAG_NAME						(1<<4)
#define FLAG_PLAYER_IP					(1<<5)
#define FLAG_PLAYER_LANGUAGE			(1<<6)
#define FLAG_PLAYER_RATE				(1<<7)
#define FLAG_SERVER_IP					(1<<8)
#define FLAG_SERVER_PORT				(1<<9)
#define FLAG_SERVER_NAME				(1<<10)
#define FLAG_SERVER_CUSTOM				(1<<11)
#define FLAG_ENGINE_L4D					(1<<12)
#define FLAG_CURRENT_MAP				(1<<13)
#define FLAG_NEXT_MAP					(1<<14)
#define FLAG_GAME_DIR					(1<<15)
#define FLAG_CURRENT_PLAYERS			(1<<16)
#if defined _steamtools_included
#define FLAG_MAXPLAYERS					(1<<17)
#define FLAG_VAC_STATUS					(1<<18)
#define FLAG_SERVER_PUBLIC_IP			(1<<19)
#define FLAG_STEAM_CONNECTION_STATUS	(1<<20)
#else
#define FLAG_MAXPLAYERS					(1<<17)
#endif  /* _steamtools_included	 */

/*#include "Duck"*/

ArrayList g_hIndexArray = null;
StringMap g_hFastLookupTrie = null;
StringMap g_hCurrentTrie = null;
char g_sCurrentSection[128];

ConVar g_cvUnloadMOTDOnDismissal;
ConVar g_cvVersion;

public void OnPluginStart()
{
	g_hIndexArray = new ArrayList();
	/* ^- We'll only use this for cleanup to prevent handle leaks and what not.
	Our friend below doesn't have iteration, so we have to do this... */
	g_hFastLookupTrie = new StringMap();
	
	g_hEngineVersion = GetEngineVersion();
	
	AddCommandListener(Client_Say, "say");
	AddCommandListener(Client_Say, "say_team");
	
	/* From Psychonic */
	Duck_OnPluginStart();
	
	g_cvVersion = CreateConVar("webshortcutsredux_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY);
	
	g_cvUnloadMOTDOnDismissal = FindConVar("sv_motd_unload_on_dismissal");
	
	/* On a reload, this will be set to the old version. Let's update it. */
	g_cvVersion.SetString(PLUGIN_VERSION);
}

public Action Client_Say(int iClient, const char[] sCommand, int argc)
{
	if (argc < 1 || !IsValidClient(iClient))
	{
		return Plugin_Continue; /* Well. While we can probably have blank hooks, I doubt anyone wants this. Lets not waste cycles. Let the game deal with this. */
	}
	
	char sFirstArg[64]; /* If this is too small, let someone know. */
	GetCmdArg(1, sFirstArg, sizeof(sFirstArg));
	TrimString(sFirstArg);
	
	StringMap hStoredTrie = null;
	if (!g_hFastLookupTrie.GetValue(sFirstArg, hStoredTrie) || hStoredTrie == null) /* L -> R. Strings are R -> L, but that can change. */
	{
		return Plugin_Continue; /* Didn't find anything. Bug out! */
	}
	
	if (DealWithOurTrie(iClient, sFirstArg, hStoredTrie))
	{
		return Plugin_Handled; /* We want other hooks to be called, I guess. We just don't want it to go to the game. */
	}
	
	return Plugin_Continue; /* Well this is embarasing. We didn't actually hook this. Or atleast didn't intend to. */
}

public bool DealWithOurTrie(int iClient, const char[] sHookedString, StringMap hStoredTrie)
{
	char sUrl[256];
	if (!hStoredTrie.GetString("Url", sUrl, sizeof(sUrl)))
	{
		LogError("Unable to find a Url for: \"%s\".", sHookedString);
		return false;
	}
	
	int iUrlBits;
	if (!hStoredTrie.GetValue("UrlBits", iUrlBits))
	{
		iUrlBits = 0; /* That's fine, there are no replacements! Less work for us. */
	}
	
	char sTitle[256];
	int iTitleBits;
	if (!hStoredTrie.GetString("Title", sTitle, sizeof(sTitle)))
	{
		sTitle[0] = '\0'; /* We don't really need a title. Don't worry, it's cool. */
		iTitleBits = 0;
	}
	else
	{
		if (!hStoredTrie.GetValue("TitleBits", iTitleBits))
		{
			iTitleBits = 0; /* That's fine, there are no replacements! Less work for us. */
		}
	}
	
	Duck_DoReplacements(iClient, sUrl, iUrlBits, sTitle, iTitleBits); /* Arrays are passed by reference. Variables are copied. */
	
	bool bBig;
	bool bNotSilent = true;
	hStoredTrie.GetValue("Silent", bNotSilent);
//	if (GoLargeOrGoHome())
	if(g_hEngineVersion == Engine_TF2 && g_bBigMOTDCompatible == true)
	{
		hStoredTrie.GetValue("Big", bBig);
	}

	char sMessage[256];
	if (hStoredTrie.GetString("Msg", sMessage, sizeof(sMessage)))
	{
		int iMsgBits;
		hStoredTrie.GetValue("MsgBits", iMsgBits);
		
		if (iMsgBits != 0)
		{
			Duck_DoReplacements(iClient, sMessage, iMsgBits, sMessage, 0); /* Lame Hack for now */
		}
		
		PrintToChatAll("%s", sMessage);
	}
	
	DisplayMOTDWithOptions(iClient, sTitle, sUrl, bBig, bNotSilent, MOTDPANEL_TYPE_URL);
	return true;
}

public void ClearExistingData()
{
	Handle hHandle = null;
	for (int i = (g_hIndexArray.Length - 1); i >= 0; i--)
	{
		hHandle = g_hIndexArray.Get(i);
		
		if (hHandle == null)
		{
			continue;
		}
		
		delete hHandle;
	}
	
	g_hIndexArray.Clear();
	g_hFastLookupTrie.Clear();
}

public void OnConfigsExecuted()
{
	ClearExistingData();
	
	char sPath[256];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/Webshortcuts.txt");
	if (!FileExists(sPath))
	{
		return;
	}
	
	ProcessFile(sPath);
}

public void ProcessFile(const char[] sPathToFile)
{
	Handle hSMC = SMC_CreateParser();
	SMC_SetReaders(hSMC, SMCNewSection, SMCReadKeyValues, SMCEndSection);
	
	int iLine;
	SMCError ReturnedError = SMC_ParseFile(hSMC, sPathToFile, iLine); /* Calls the below functions, then execution continues. */
	
	if (ReturnedError != SMCError_Okay)
	{
		char sError[256];
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

public SMCResult SMCNewSection(Handle smc, const char[] name, bool opt_quotes)
{
	if (!opt_quotes)
	{
		LogError("Invalid Quoting used with Section: %s.", name);
	}
	
	strcopy(g_sCurrentSection, sizeof(g_sCurrentSection), name);
	
	if (g_hFastLookupTrie.GetValue(name, g_hCurrentTrie))
	{
		return SMCParse_Continue;
	}
	else /* That's cool. Sounds like an initial insertion. Just wanted to make sure! */
	{
		g_hCurrentTrie = new StringMap();
		g_hIndexArray.Push(g_hCurrentTrie); /* Don't be leakin */
		g_hFastLookupTrie.SetValue(name, g_hCurrentTrie);
		g_hCurrentTrie.SetString("Name", name);
	}
	
	return SMCParse_Continue;
}

public SMCResult SMCReadKeyValues(Handle smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
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
			
			int iFindValue = g_hIndexArray.FindValue(g_hCurrentTrie);
			
			if (iFindValue > -1)
			{
				g_hIndexArray.Erase(iFindValue);
			}
			
			if (g_sCurrentSection[0] != '\0')
			{
				g_hFastLookupTrie.Remove(g_sCurrentSection);
			}
			
			delete g_hCurrentTrie; /* We're about to invalidate below */

			if (g_hFastLookupTrie.GetValue(value, g_hCurrentTrie))
			{
				g_hFastLookupTrie.SetValue(g_sCurrentSection, g_hCurrentTrie, true);
				return SMCParse_Continue;
			}

			g_hCurrentTrie = new StringMap(); /* Ruhro, the thing this points to doesn't actually exist. Should we error or what? Nah, lets try and recover. */
			g_hIndexArray.Push(g_hCurrentTrie); /* Don't be losin handles */
			g_hFastLookupTrie.SetValue(g_sCurrentSection, g_hCurrentTrie, true);
			g_hCurrentTrie.SetString("Name", g_sCurrentSection, true);
		}
		
		case 'u','U':
		{
			if (!StrEqual(key, "Url", false))
			{
				return SMCParse_Continue;
			}
			
			g_hCurrentTrie.SetString("Url", value, true);
			
			int iBits;
			Duck_CalcBits(value, iBits); /* Passed by Ref */
			g_hCurrentTrie.SetValue("UrlBits", iBits, true);
		}
		
		case 'T','t':
		{
			if (!StrEqual(key, "Title", false))
			{
				return SMCParse_Continue;
			}
			
			g_hCurrentTrie.SetString("Title", value, true);
			
			int iBits;
			Duck_CalcBits(value, iBits); /* Passed by Ref */
			g_hCurrentTrie.SetValue("TitleBits", iBits, true);
		}
		
		case 'b','B':
		{
			if (g_hEngineVersion == Engine_TF2 && g_bBigMOTDCompatible == true && !StrEqual(key, "Big", false)) /* Maybe they don't know they can't use it? Oh well. Protect the silly. */
			{
				return SMCParse_Continue;
			}
			
			g_hCurrentTrie.SetValue("Big", TranslateToBool(value), true);
		}
	
		case 'h','H':
		{
			if (!StrEqual(key, "Hook", false))
			{
				return SMCParse_Continue;
			}
			
			g_hFastLookupTrie.SetValue(value, g_hCurrentTrie, true);
		}
		
		case 's', 'S':
		{
			if (!StrEqual(key, "Silent", false))
			{
				return SMCParse_Continue;
			}
			
			g_hCurrentTrie.SetValue("Silent", !TranslateToBool(value), true);
		}
		
		case 'M', 'm':
		{
			if (!StrEqual(key, "Msg", false))
			{
				return SMCParse_Continue;
			}
			
			g_hCurrentTrie.SetString("Msg", value, true);
			
			int iBits;
			Duck_CalcBits(value, iBits); /* Passed by Ref */
			
			g_hCurrentTrie.SetValue("MsgBits", iBits, true);
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult SMCEndSection(Handle smc)
{
	g_hCurrentTrie = null;
	g_sCurrentSection[0] = '\0';
}

public bool TranslateToBool(const char[] sSource)
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

public void DisplayMOTDWithOptions(int iClient, const char[] sTitle, const char[] sUrl, bool bBig, bool bNotSilent, int iType)
{
	KeyValues hKv = new KeyValues("motd");

	if (bBig)
	{
		hKv.SetNum("customsvr", 1);
	}
	
	KvSetNum(hKv, "type", iType);
	
	if (sTitle[0] != '\0')
	{
		hKv.SetString("title", sTitle);
	}
		
	if (sUrl[0] != '\0')
	{
		hKv.SetString("msg", sUrl);
	}
	
	if (g_cvUnloadMOTDOnDismissal)
	{
		hKv.SetNum("unload", g_cvUnloadMOTDOnDismissal.BoolValue ? 1 : 0);
	}
	
	ShowVGUIPanel(iClient, "info", hKv, bNotSilent);
	delete hKv;
}

static stock bool IsValidClient(int iClient)
{
	return (0 < iClient <= MaxClients && IsClientInGame(iClient));
}

/* Psychonics Realm */

#define FIELD_CHECK(%1,%2);\
if (StrContains(source, %1) != -1) { field |= %2; }

#define TOKEN_STEAM_ID         "{STEAM_ID}"
#define TOKEN_STEAM_ID3        "{STEAM_ID3}"
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
int g_bSteamTools;
#endif  /* _steamtools_included */

/* Cached values */
char g_szServerIp[16];
char g_szServerPort[6];
/* These can all be larger but whole buffer holds < 128 */
char g_szServerName[128];
char g_szServerCustom[128];
char g_szL4DGameMode[128];
char g_szCurrentMap[128];
char g_szGameDir[64];



/*new Handle:g_hCmdQueue[MAXPLAYERS+1];*/

#if defined _steamtools_included
public int Steam_FullyLoaded()
{
	g_bSteamTools = true;
}

public void OnLibraryRemoved(const char[] sLibrary)
{
	if (!StrEqual(sLibrary, "SteamTools", false))
	{
		return;
	}
	
	g_bSteamTools = false;
}

#endif

public void Duck_OnPluginStart()
{
	if(g_hEngineVersion == Engine_TF2)
	{
		g_bBigMOTDCompatible = true;
	}
	
	/* On a reload, these will already be registered and could be set to non-default */
	
	// Not sure why this if statement wasn't commented out completely if it's empty...
//	if (IsTeamFortress2())
//	{
		/* AddCommandListener(Duck_TF2OnClose, "closed_htmlpage"); */
//	}	
	
	ConVar cvHostIp = FindConVar("hostip");
	LongIPToString(cvHostIp.IntValue, g_szServerIp);
	
	ConVar cvHostPort = FindConVar("hostport");
	cvHostPort.GetString(g_szServerPort, sizeof(g_szServerPort));
	
	ConVar cvHostName = FindConVar("hostname");
	char szHostname[256];
	cvHostName.GetString(szHostname, sizeof(szHostname));
	Duck_UrlEncodeString(g_szServerName, sizeof(g_szServerName), szHostname);
	cvHostName.AddChangeHook(OnCvarHostnameChange);
	
	char szCustom[256];
	ConVar cvCustom = CreateConVar("WebShortcuts_Custom", "", "Custom String for this server.");
	cvCustom.GetString(szCustom, sizeof(szCustom));
	Duck_UrlEncodeString(g_szServerCustom, sizeof(g_szServerCustom), szCustom);
	cvCustom.AddChangeHook(OnCvarCustomChange);
	
	if(g_hEngineVersion == Engine_Left4Dead || g_hEngineVersion == Engine_Left4Dead2)
	{
		g_bBigMOTDCompatible = false;
		ConVar cvGameMode = FindConVar("mp_gamemode");
		char szGamemode[256];
		cvGameMode.GetString(szGamemode, sizeof(szGamemode));
		Duck_UrlEncodeString(g_szL4DGameMode, sizeof(g_szL4DGameMode), szGamemode);
		cvGameMode.AddChangeHook(OnCvarGamemodeChange);
	}
	
	char sGameDir[64];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	Duck_UrlEncodeString(g_szGameDir, sizeof(g_szGameDir), sGameDir);
}

public void OnMapStart()
{
	char sTempMap[sizeof(g_szCurrentMap)];
	GetCurrentMap(sTempMap, sizeof(sTempMap));
	
	Duck_UrlEncodeString(g_szCurrentMap, sizeof(g_szCurrentMap), sTempMap);
}

stock void Duck_DoReplacements(int iClient, char sUrl[256], int iUrlBits, char sTitle[256], int iTitleBits) /* Huge thanks to Psychonic */
{
	if (iUrlBits & FLAG_STEAM_ID || iTitleBits & FLAG_STEAM_ID)
	{
		char sSteamId[64];
		if (GetClientAuthId(iClient, AuthId_Steam2, sSteamId, sizeof(sSteamId)))
		{
			ReplaceString(sSteamId, sizeof(sSteamId), ":", "%3a");
			if (iTitleBits & FLAG_STEAM_ID)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_STEAM_ID, sSteamId);
			}
			if (iUrlBits & FLAG_STEAM_ID)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_STEAM_ID, sSteamId);
			}
		}
		else
		{
			if (iTitleBits & FLAG_STEAM_ID)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_STEAM_ID, "");
			}
			if (iUrlBits & FLAG_STEAM_ID)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_STEAM_ID, "");
			}
		}
	}
	
	if (iUrlBits & FLAG_STEAM_ID3 || iTitleBits & FLAG_STEAM_ID3)
	{
		char sSteamId3[64];
		if (GetClientAuthId(iClient, AuthId_Steam3, sSteamId3, sizeof(sSteamId3)))
		{
			ReplaceString(sSteamId3, sizeof(sSteamId3), "[", "%5b");
			ReplaceString(sSteamId3, sizeof(sSteamId3), ":", "%3a");
			ReplaceString(sSteamId3, sizeof(sSteamId3), "]", "%5D");
			if (iTitleBits & FLAG_STEAM_ID3)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_STEAM_ID3, sSteamId3);
			}
			if (iUrlBits & FLAG_STEAM_ID3)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_STEAM_ID3, sSteamId3);
			}
		}
		else
		{
			if (iTitleBits & FLAG_STEAM_ID3)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_STEAM_ID3, "");
			}
			if (iUrlBits & FLAG_STEAM_ID3)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_STEAM_ID3, "");
			}
		}
	}
	
	if (iUrlBits & FLAG_USER_ID || iTitleBits & FLAG_USER_ID)
	{
		char sUserId[16];
		IntToString(GetClientUserId(iClient), sUserId, sizeof(sUserId));
		if (iTitleBits & FLAG_USER_ID)
		{
			ReplaceString(sTitle, sizeof(sTitle), TOKEN_USER_ID, sUserId);
		}
		if (iUrlBits & FLAG_USER_ID)
		{
			ReplaceString(sUrl, sizeof(sUrl), TOKEN_USER_ID, sUserId);
		}
	}
	
	if (iUrlBits & FLAG_FRIEND_ID || iTitleBits & FLAG_FRIEND_ID)
	{
		char sFriendId[64];
		if (GetClientFriendID(iClient, sFriendId, sizeof(sFriendId)))
		{
			if (iTitleBits & FLAG_FRIEND_ID)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_FRIEND_ID, sFriendId);
			}
			if (iUrlBits & FLAG_FRIEND_ID)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_FRIEND_ID, sFriendId);
			}
		}
		else
		{
			if (iTitleBits & FLAG_FRIEND_ID)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_FRIEND_ID, "");
			}
			if (iUrlBits & FLAG_FRIEND_ID)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_FRIEND_ID, "");
			}
		}
	}
	
	if (iUrlBits & FLAG_NAME || iTitleBits & FLAG_NAME)
	{
		char sName[MAX_NAME_LENGTH];
		if (GetClientName(iClient, sName, sizeof(sName)))
		{
			char sEncName[sizeof(sName)*3];
			Duck_UrlEncodeString(sEncName, sizeof(sEncName), sName);
			if (iTitleBits & FLAG_NAME)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_NAME, sEncName);
			}
			if (iUrlBits & FLAG_NAME)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_NAME, sEncName);
			}
		}
		else
		{
			if (iTitleBits & FLAG_NAME)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_NAME, "");
			}
			if (iUrlBits & FLAG_NAME)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_NAME, "");
			}
		}
	}
	
	if (iUrlBits & FLAG_PLAYER_IP || iTitleBits & FLAG_PLAYER_IP)
	{
		char sClientIp[32];
		if (GetClientIP(iClient, sClientIp, sizeof(sClientIp)))
		{
			if (iTitleBits & FLAG_PLAYER_IP)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_IP, sClientIp);
			}
			if (iUrlBits & FLAG_PLAYER_IP)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_IP, sClientIp);
			}
		}
		else
		{
			if (iTitleBits & FLAG_PLAYER_IP)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_IP, "");
			}
			if (iUrlBits & FLAG_PLAYER_IP)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_IP, "");
			}
		}
	}
	
	if (iUrlBits & FLAG_PLAYER_LANGUAGE || iTitleBits & FLAG_PLAYER_LANGUAGE)
	{
		char sLanguage[32];
		if (GetClientInfo(iClient, "cl_language", sLanguage, sizeof(sLanguage)))
		{
			char sEncLanguage[sizeof(sLanguage)*3];
			Duck_UrlEncodeString(sEncLanguage, sizeof(sEncLanguage), sLanguage);
			if (iTitleBits & FLAG_PLAYER_LANGUAGE)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_LANGUAGE, sEncLanguage);
			}
			if (iUrlBits & FLAG_PLAYER_LANGUAGE)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_LANGUAGE, sEncLanguage);
			}
		}
		else
		{
			if (iTitleBits & FLAG_PLAYER_LANGUAGE)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_LANGUAGE, "");
			}
			if (iUrlBits & FLAG_PLAYER_LANGUAGE)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_LANGUAGE, "");
			}
		}
	}
	
	if (iUrlBits & FLAG_PLAYER_RATE || iTitleBits & FLAG_PLAYER_RATE)
	{
		char sRate[16];
		if (GetClientInfo(iClient, "rate", sRate, sizeof(sRate)))
		{
			/* due to iClient's rate being silly, this won't necessarily be all digits */
			char sEncRate[sizeof(sRate)*3];
			Duck_UrlEncodeString(sEncRate, sizeof(sEncRate), sRate);
			if (iTitleBits & FLAG_PLAYER_RATE)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_RATE, sEncRate);
			}
			if (iUrlBits & FLAG_PLAYER_RATE)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_RATE, sEncRate);
			}
		}
		else
		{
			if (iTitleBits & FLAG_PLAYER_RATE)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_RATE, "");
			}
			if (iUrlBits & FLAG_PLAYER_RATE)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_RATE, "");
			}
		}
	}
	
	if (iTitleBits & FLAG_SERVER_IP)
	{
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_IP, g_szServerIp);
	}
	if (iUrlBits & FLAG_SERVER_IP)
	{
		ReplaceString(sUrl, sizeof(sUrl), TOKEN_SERVER_IP, g_szServerIp);
	}
	
	if (iTitleBits & FLAG_SERVER_PORT)
	{
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_PORT, g_szServerPort);
	}
	if (iUrlBits & FLAG_SERVER_PORT)
	{
		ReplaceString(sUrl, sizeof(sUrl), TOKEN_SERVER_PORT, g_szServerPort);
	}
	
	if (iTitleBits & FLAG_SERVER_NAME)
	{
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_NAME, g_szServerName);
	}
	if (iUrlBits & FLAG_SERVER_NAME)
	{
		ReplaceString(sUrl, sizeof(sUrl), TOKEN_SERVER_NAME, g_szServerName);
	}
	
	if (iTitleBits & FLAG_SERVER_CUSTOM)
	{
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_CUSTOM, g_szServerCustom);
	}
	if (iUrlBits & FLAG_SERVER_CUSTOM)
	{
		ReplaceString(sUrl, sizeof(sUrl), TOKEN_SERVER_CUSTOM, g_szServerCustom);
	}
	
	if ((g_hEngineVersion == Engine_Left4Dead || g_hEngineVersion == Engine_Left4Dead2) && ((iUrlBits & FLAG_ENGINE_L4D) || (iTitleBits & FLAG_ENGINE_L4D)))
	{
		if (iTitleBits & FLAG_ENGINE_L4D)
		{
			ReplaceString(sTitle, sizeof(sTitle), TOKEN_L4D_GAMEMODE, g_szL4DGameMode);
		}
		if (iUrlBits & FLAG_ENGINE_L4D)
		{
			ReplaceString(sUrl, sizeof(sUrl), TOKEN_L4D_GAMEMODE, g_szL4DGameMode);
		}
	}
	
	if (iTitleBits & FLAG_CURRENT_MAP)
	{
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_CURRENT_MAP, g_szCurrentMap);
	}
	if (iUrlBits & FLAG_CURRENT_MAP)
	{
		ReplaceString(sUrl, sizeof(sUrl), TOKEN_CURRENT_MAP, g_szCurrentMap);
	}
	
	if (iUrlBits & FLAG_NEXT_MAP || iTitleBits & FLAG_NEXT_MAP)
	{
		char szNextMap[PLATFORM_MAX_PATH];
		if (GetNextMap(szNextMap, sizeof(szNextMap)))
		{
			if (iTitleBits & FLAG_NEXT_MAP)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_NEXT_MAP, szNextMap);
			}
			if (iUrlBits & FLAG_NEXT_MAP)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_NEXT_MAP, szNextMap);
			}
		}
		else
		{
			if (iTitleBits & FLAG_NEXT_MAP)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_NEXT_MAP, "");
			}
			if (iUrlBits & FLAG_NEXT_MAP)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_NEXT_MAP, "");
			}
		}
	}
	
	if (iTitleBits & FLAG_GAME_DIR)
	{
		ReplaceString(sTitle, sizeof(sTitle), TOKEN_GAMEDIR, g_szGameDir);
	}
	if (iUrlBits & FLAG_GAME_DIR)
	{
		ReplaceString(sUrl, sizeof(sUrl), TOKEN_GAMEDIR, g_szGameDir);
	}
	
	if (iUrlBits & FLAG_CURRENT_PLAYERS || iTitleBits & FLAG_CURRENT_PLAYERS)
	{
		char sCurPlayers[10];
		IntToString(GetClientCount(false), sCurPlayers, sizeof(sCurPlayers));
		if (iTitleBits & FLAG_CURRENT_PLAYERS)
		{
			ReplaceString(sTitle, sizeof(sTitle), TOKEN_CURPLAYERS, sCurPlayers);
		}
		if (iUrlBits & FLAG_CURRENT_PLAYERS)
		{
			ReplaceString(sUrl, sizeof(sUrl), TOKEN_CURPLAYERS, sCurPlayers);
		}
	}
	
	if (iUrlBits & FLAG_MAXPLAYERS || iTitleBits & FLAG_MAXPLAYERS)
	{
		char maxplayers[10];
		IntToString(MaxClients, maxplayers, sizeof(maxplayers));
		if (iTitleBits & FLAG_MAXPLAYERS)
		{
			ReplaceString(sTitle, sizeof(sTitle), TOKEN_MAXPLAYERS, maxplayers);
		}
		if (iUrlBits & FLAG_MAXPLAYERS)
		{
			ReplaceString(sUrl, sizeof(sUrl), TOKEN_MAXPLAYERS, maxplayers);
		}
	}
	
#if defined _steamtools_included	
	if (iUrlBits & FLAG_VAC_STATUS || iTitleBits & FLAG_VAC_STATUS)
	{
		if (g_bSteamTools && Steam_IsVACEnabled())
		{
			if (iTitleBits & FLAG_VAC_STATUS)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_VACSTATUS, "1");
			}
			if (iUrlBits & FLAG_VAC_STATUS)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_VACSTATUS, "1");
			}
		}
		else
		{
			if (iTitleBits & FLAG_VAC_STATUS)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_VACSTATUS, "0");
			}
			if (iUrlBits & FLAG_VAC_STATUS)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_VACSTATUS, "0");
			}
		}
	}
	
	if (iUrlBits & FLAG_SERVER_PUBLIC_IP || iTitleBits & FLAG_SERVER_PUBLIC_IP)
	{
		if (g_bSteamTools)
		{
			int ip[4];
			char sIPString[16];
			Steam_GetPublicIP(ip);
			FormatEx(sIPString, sizeof(sIPString), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
			
			if (iTitleBits & FLAG_SERVER_PUBLIC_IP)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_PUB_IP, sIPString);
			}
			if (iUrlBits & FLAG_SERVER_PUBLIC_IP)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_SERVER_PUB_IP, sIPString);
			}
		}
		else
		{
			if (iTitleBits & FLAG_SERVER_PUBLIC_IP)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_SERVER_PUB_IP, "");
			}
			if (iUrlBits & FLAG_SERVER_PUBLIC_IP)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_SERVER_PUB_IP, "");
			}
		}
	}
	
	if (iUrlBits & FLAG_STEAM_CONNECTION_STATUS || iTitleBits & FLAG_STEAM_CONNECTION_STATUS)
	{
		if (g_bSteamTools && Steam_IsConnected())
		{
			if (iTitleBits & FLAG_STEAM_CONNECTION_STATUS)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_STEAM_CONNSTATUS, "1");
			}
			if (iUrlBits & FLAG_STEAM_CONNECTION_STATUS)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_STEAM_CONNSTATUS, "1");
			}
		}
		else
		{
			if (iTitleBits & FLAG_STEAM_CONNECTION_STATUS)
			{
				ReplaceString(sTitle, sizeof(sTitle), TOKEN_STEAM_CONNSTATUS, "0");
			}
			if (iUrlBits & FLAG_STEAM_CONNECTION_STATUS)
			{
				ReplaceString(sUrl, sizeof(sUrl), TOKEN_STEAM_CONNSTATUS, "0");
			}
		}
	}
#endif  /* _steamtools_included */
}

stock bool GetClientFriendID(int client, char[] sFriendID, int size) 
{
#if defined _steamtools_included
	Steam_GetCSteamIDForClient(client, sFriendID, size);
#else
	char sSteamID[64];
	if (!GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID)))
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
	
	char toks[3][16];
	ExplodeString(sSteamID, ":", toks, sizeof(toks), sizeof(toks[]));
	
	int iServer = StringToInt(toks[1]);
	int iAuthID = StringToInt(toks[2]);
	int iFriendID = (iAuthID*2) + 60265728 + iServer;
	
	if (iFriendID >= 100000000)
	{
		char temp[12], String:carry[12];
		FormatEx(temp, sizeof(temp), "%d", iFriendID);
		FormatEx(carry, 2, "%s", temp);
		int icarry = StringToInt(carry[0]);
		int upper = 765611979 + icarry;
		
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

void Duck_CalcBits(const char[] source, int& field)
{
	field = 0;
	
	FIELD_CHECK(TOKEN_STEAM_ID,    FLAG_STEAM_ID);
	FIELD_CHECK(TOKEN_STEAM_ID3,   FLAG_STEAM_ID3);
	FIELD_CHECK(TOKEN_USER_ID,     FLAG_USER_ID);
	FIELD_CHECK(TOKEN_FRIEND_ID,   FLAG_FRIEND_ID);
	FIELD_CHECK(TOKEN_NAME,        FLAG_NAME);
	FIELD_CHECK(TOKEN_IP,          FLAG_PLAYER_IP);
	FIELD_CHECK(TOKEN_LANGUAGE,    FLAG_PLAYER_LANGUAGE);
	FIELD_CHECK(TOKEN_RATE,        FLAG_PLAYER_RATE);
	FIELD_CHECK(TOKEN_SERVER_IP,   FLAG_SERVER_IP);
	FIELD_CHECK(TOKEN_SERVER_PORT, FLAG_SERVER_PORT);
	FIELD_CHECK(TOKEN_SERVER_NAME, FLAG_SERVER_NAME);
	FIELD_CHECK(TOKEN_SERVER_CUSTOM, FLAG_SERVER_CUSTOM);
	
	if(g_hEngineVersion == Engine_Left4Dead || g_hEngineVersion == Engine_Left4Dead2)
	{
		FIELD_CHECK(TOKEN_L4D_GAMEMODE, FLAG_ENGINE_L4D);
	}
	
	FIELD_CHECK(TOKEN_CURRENT_MAP, FLAG_CURRENT_MAP);
	FIELD_CHECK(TOKEN_NEXT_MAP,    FLAG_NEXT_MAP);
	FIELD_CHECK(TOKEN_GAMEDIR,     FLAG_GAME_DIR);
	FIELD_CHECK(TOKEN_CURPLAYERS,  FLAG_CURRENT_PLAYERS);
	FIELD_CHECK(TOKEN_MAXPLAYERS,  FLAG_MAXPLAYERS);

#if defined _steamtools_included
	FIELD_CHECK(TOKEN_VACSTATUS,        FLAG_VAC_STATUS);
	FIELD_CHECK(TOKEN_SERVER_PUB_IP,    FLAG_SERVER_PUBLIC_IP);
	FIELD_CHECK(TOKEN_STEAM_CONNSTATUS, FLAG_STEAM_CONNECTION_STATUS);
#endif
}

/* Courtesy of Mr. Asher Baker */
stock void LongIPToString(int ip, char szBuffer[16])
{
	FormatEx(szBuffer, sizeof(szBuffer), "%i.%i.%i.%i", (((ip & 0xFF000000) >> 24) & 0xFF), (((ip & 0x00FF0000) >> 16) & 0xFF), (((ip & 0x0000FF00) >>  8) & 0xFF), (((ip & 0x000000FF) >>  0) & 0xFF));
}

/* loosely based off of PHP's urlencode */
stock void Duck_UrlEncodeString(char[] output, int size, const char[] input)
{
	int icnt = 0;
	int ocnt = 0;
	
	for(;;)
	{
		if (ocnt == size)
		{
			output[ocnt-1] = '\0';
			return;
		}
		
		int c = input[icnt];
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

public void OnCvarHostnameChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Duck_UrlEncodeString(g_szServerName, sizeof(g_szServerName), newValue);
}

public void OnCvarGamemodeChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Duck_UrlEncodeString(g_szL4DGameMode, sizeof(g_szL4DGameMode), newValue);
}

public void OnCvarCustomChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Duck_UrlEncodeString(g_szServerCustom, sizeof(g_szServerCustom), newValue);
}