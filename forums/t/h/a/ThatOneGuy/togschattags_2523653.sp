//2.1 - added spam blocker
//2.2 - Converted team names to read team name...was using CSS ones before.

#pragma semicolon 1
#define PLUGIN_VERSION "2.2"

#include <sourcemod>
#include <autoexecconfig>
#include <sdktools>
#include <regex>
#include <morecolors>
#include <adminmenu>
#include <clientprefs>
#include <basecomm>

new	Handle:g_hEnabled = INVALID_HANDLE;
new g_iEnabled;
new	Handle:g_hAdminSeeAll = INVALID_HANDLE;
new g_iAdminSeeAll;
new Handle:g_hAdminSeeAllFlag = INVALID_HANDLE;
new String:g_sAdminSeeAllFlag[30];
new	Handle:g_hConvertTriggerCases = INVALID_HANDLE;
new g_iConvertTriggerCases;
new Handle:g_hAccessFlag = INVALID_HANDLE;
new String:g_sAccessFlag[30];
new Handle:g_hAdminFlag = INVALID_HANDLE;
new String:g_sAdminFlag[30];
new Handle:g_hAdminUnloadFlag = INVALID_HANDLE;
new String:g_sAdminUnloadFlag[30];
new	Handle:g_hLog = INVALID_HANDLE;
new g_iLog;
new	Handle:g_hSpamDuration = INVALID_HANDLE;
new Float:g_fSpamDuration;

new Handle:hTopMenu = INVALID_HANDLE;
new Handle:g_hRegexHex;
new bool:g_bLateLoad;

//cookies
new Handle:g_hCookieTagHidden = INVALID_HANDLE;
new Handle:g_hCookieIsRestricted = INVALID_HANDLE;
new Handle:g_hCookieTag = INVALID_HANDLE;
new Handle:g_hCookieTagColor = INVALID_HANDLE;
new Handle:g_hCookieNameColor = INVALID_HANDLE;
new Handle:g_hCookieChatColor = INVALID_HANDLE;

//player cookie settings
new g_iTagSetting[MAXPLAYERS + 1] = {0, ...};	
new g_iTagHidden[MAXPLAYERS + 1] = {1, ...};			
new g_iIsRestricted[MAXPLAYERS + 1] = {0, ...};	
new g_iIsLoaded[MAXPLAYERS + 1] = {0, ...};
new String:g_sSteamID[MAXPLAYERS + 1][32];
new String:g_sName[MAXPLAYERS + 1][MAX_NAME_LENGTH];
new String:g_sTagColor[MAXPLAYERS + 1][7];	//default for each color is white, if the player has access and tag is unhidden
new String:g_sNameColor[MAXPLAYERS + 1][7];		
new String:g_sChatColor[MAXPLAYERS + 1][7];		
new String:g_sTag[MAXPLAYERS + 1][22];

//client data indexes for g_iTagSetting
#define INDEX_NONE 0
#define INDEX_CHAT 1
#define INDEX_NAME 2
#define INDEX_NAMECHAT 3
#define INDEX_TEXT 4
#define INDEX_TEXTCHAT 5
#define INDEX_TEXTNAME 6
#define INDEX_TEXTNAMECHAT 7
#define INDEX_TEXTTAG 8
#define INDEX_TEXTTAGCHAT 9
#define INDEX_TEXTTAGNAME 10
#define INDEX_TEXTTAGNAMECHAT 11

//cfg file data
new String:g_sPath[PLATFORM_MAX_PATH];
new String:g_sColorName[255][255];
new String:g_sColorHex[255][255];
new g_iColorCount;
new Handle:g_hBlockedTags = INVALID_HANDLE;
new Handle:g_hIgnoredText_Equal = INVALID_HANDLE;
new Handle:g_hIgnoredText_Contains = INVALID_HANDLE;

//chat logger
new String:g_sChatLogPath[PLATFORM_MAX_PATH];

//chat spam blocker
new g_iChatTime1[MAXPLAYERS + 1] = {-1,...};
new g_iChatTime2[MAXPLAYERS + 1] = {-1,...};
new g_iSpamCoolDown[MAXPLAYERS + 1] = {-1,...};

new String:sTeamTwoName[MAX_NAME_LENGTH];
new String:sTeamThreeName[MAX_NAME_LENGTH];

public Plugin:myinfo =
{
	name = "TOGs Chat Tags",
	author = "That One Guy",
	description = "Gives players with designated flag the ability to set their own custom tags",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("togschattags");
	AutoExecConfig_CreateConVar("tct_version", PLUGIN_VERSION, "TOGs Chat Tags: Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	
	g_hEnabled = AutoExecConfig_CreateConVar("tct_enable", "1", "Enable plugin (0 = Disabled, 1 = Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnCVarChange);
	g_iEnabled = GetConVarInt(g_hEnabled);
	
	g_hAdminSeeAll = AutoExecConfig_CreateConVar("tct_seeall", "1", "Enable admin see-all (admins with set flag see even hidden chat).", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hAdminSeeAll, OnCVarChange);
	g_iAdminSeeAll = GetConVarInt(g_hAdminSeeAll);
	
	g_hAdminSeeAllFlag = CreateConVar("tct_seeallflag", "z", "Flag required for admin see-all (if enabled).", FCVAR_NONE);
	HookConVarChange(g_hAdminSeeAllFlag, OnCVarChange);
	GetConVarString(g_hAdminSeeAllFlag, g_sAdminSeeAllFlag, sizeof(g_sAdminSeeAllFlag));
	
	g_hConvertTriggerCases = AutoExecConfig_CreateConVar("tct_triggercase", "1", "Convert chat triggers to lowercase if theyre uppercase.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConvertTriggerCases, OnCVarChange);
	g_iConvertTriggerCases = GetConVarInt(g_hConvertTriggerCases);
	
	g_hAccessFlag = CreateConVar("tct_accessflag", "a", "If \"\", everyone can change their tags, otherwise, only players with this flag can access plugin features.", FCVAR_NONE);
	HookConVarChange(g_hAccessFlag, OnCVarChange);
	GetConVarString(g_hAccessFlag, g_sAccessFlag, sizeof(g_sAccessFlag));
	
	g_hAdminFlag = CreateConVar("tct_adminflag", "g", "Only players with this flag can restrict/remove tags of players.", FCVAR_NONE);
	HookConVarChange(g_hAdminFlag, OnCVarChange);
	GetConVarString(g_hAdminFlag, g_sAdminFlag, sizeof(g_sAdminFlag));
	
	g_hAdminUnloadFlag = CreateConVar("tct_unloadflag", "h", "Only players with this flag can unload the entire plugin until map change.", FCVAR_NONE);
	HookConVarChange(g_hAdminUnloadFlag, OnCVarChange);
	GetConVarString(g_hAdminUnloadFlag, g_sAdminUnloadFlag, sizeof(g_sAdminUnloadFlag));
	
	g_hLog = AutoExecConfig_CreateConVar("tct_log", "1", "Enable chat logger.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hLog, OnCVarChange);
	g_iLog = GetConVarInt(g_hLog);
	
	g_hSpamDuration = AutoExecConfig_CreateConVar("tct_spamduration", "5", "Number of seconds used for the spam protection (0 = disabled). If messages sent exceeds tct_spamcount within this time frame, it blocks them.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSpamDuration, OnCVarChange);
	g_fSpamDuration = GetConVarFloat(g_hSpamDuration);
	
	//player commands
	RegConsoleCmd("sm_tags", Command_Tag, "Opens TOGs Chat Tags Menu.");
	RegConsoleCmd("sm_tagcolor", Command_TagColor, "Change tag color to a specified hexadecimal value.");
	RegConsoleCmd("sm_settag", Command_SetText, "Change tag text.");
	RegConsoleCmd("sm_namecolor", Command_NameColor, "Change name color to a specified hexadecimal value.");
	RegConsoleCmd("sm_chatcolor", Command_ChatColor, "Change chat color to a specified hexadecimal value.");
	RegConsoleCmd("sm_checktag", Command_CheckTag, "Check tag settings of another player.");
	
	//admin commands - RegConsoleCmd used to allow setting access via cvar "tct_adminflag"
	RegConsoleCmd("sm_reloadtagcolors", Cmd_Reload, "Reloads color cfg file for tags.");
	RegConsoleCmd("sm_unrestricttag", Cmd_Unrestrict, "Unrestrict player from setting their chat tags.");
	RegConsoleCmd("sm_restricttag", Cmd_Restrict, "Restrict player from setting their chat tags.");
	RegConsoleCmd("sm_removetag", Cmd_RemoveTag, "Removes a players tag setup.");
	RegConsoleCmd("sm_unloadtags", Cmd_Unload, "Unloads the entire plugin for the current map.");
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_SayTeam, "say_team");
	//hook admin chat chat commands for chat logging if they use console
	AddCommandListener(Command_AdminChat, "sm_say");
	AddCommandListener(Command_AdminOnlyChat, "sm_chat");
	AddCommandListener(Command_CSay, "sm_csay");
	AddCommandListener(Command_TSay, "sm_tsay");
	AddCommandListener(Command_MSay, "sm_msay");
	AddCommandListener(Command_HSay, "sm_hsay");
	AddCommandListener(Command_PSay, "sm_psay");

	HookEvent("player_changename", Event_NameChange);
	
	//client prefs and cookies	
	SetCookieMenuItem(Menu_ClientPrefs, 0, "TOGs Chat Tags");
	g_hCookieTagHidden = RegClientCookie("HideTag", "Hide chat tag", CookieAccess_Protected);
	g_hCookieIsRestricted = RegClientCookie("TagRestricted", "Is player restricted from changing chat tags", CookieAccess_Private);
	g_hCookieTag = RegClientCookie("TagText", "ChatTagText", CookieAccess_Protected);
	g_hCookieTagColor = RegClientCookie("TagColor", "Chat Tag Color", CookieAccess_Protected);
	g_hCookieNameColor = RegClientCookie("NameColor", "Name Color", CookieAccess_Protected);
	g_hCookieChatColor = RegClientCookie("ChatColor", "Chat Color", CookieAccess_Protected);
	
	//hex checker
	g_hRegexHex = CompileRegex("([A-Fa-f0-9]{6})");
	
	//admin menu - Account for late loading
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	//color file
	BuildPath(Path_SM, g_sPath, sizeof(g_sPath), "configs/togschattags_colors.cfg");
	
	//overwrite cookies if they are cached
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && AreClientCookiesCached(i))
		{
			LoadClientData(i);
		}
	}
	
	//chat logger
	decl String:sBuffer[PLATFORM_MAX_PATH];
	FormatTime(sBuffer, sizeof(sBuffer), "%m%d%y");
	Format(sBuffer, sizeof(sBuffer), "logs/chatlogger/chatlogs_%s.log", sBuffer);
	BuildPath(Path_SM, g_sChatLogPath, sizeof(g_sChatLogPath), sBuffer);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public OnMapStart()
{
	if(g_iEnabled)
	{
		LoadColorCfg();
		LoadCustomConfigs();
	}
	if(g_iLog)
	{
		CreateTimer(30.0, Timer_UpdatePath, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	GetTeamName(2, sTeamTwoName, sizeof(sTeamTwoName));
	GetTeamName(3, sTeamThreeName, sizeof(sTeamThreeName));
}

public Action:Timer_UpdatePath(Handle:Timer, any:Client)
{
	decl String:sBuffer[256];
	FormatTime(sBuffer, sizeof(sBuffer), "%m%d%y");
	Format(sBuffer, sizeof(sBuffer), "logs/chatlogger/chatlogs_%s.log", sBuffer);
	BuildPath(Path_SM, g_sChatLogPath, sizeof(g_sChatLogPath), sBuffer);
}

public OnConfigsExecuted()
{
	if(g_iEnabled)
	{
		LoadColorCfg();
		LoadCustomConfigs();
		
		if(g_bLateLoad)
		{
			Reload();
			if(g_iLog)
			{
				CreateTimer(30.0, Timer_UpdatePath, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public LoadColorCfg()
{
	if(!FileExists(g_sPath))
	{
		SetFailState("Configuration file %s not found!", g_sPath);
		return;
	}

	new Handle:hKeyValues = CreateKeyValues("TOGs Chat Tags");
	if(!FileToKeyValues(hKeyValues, g_sPath))
	{
		SetFailState("Improper structure for configuration file %s!", g_sPath);
		return;
	}

	if(!KvGotoFirstSubKey(hKeyValues))
	{
		SetFailState("Can't find configuration file %s!", g_sPath);
		return;
	}

	for(new i = 0; i < 255; i++)
	{
		strcopy(g_sColorName[i], sizeof(g_sColorName[]), "");
		strcopy(g_sColorHex[i], sizeof(g_sColorHex[]), "");
	}

	g_iColorCount = 0;
	do
	{
		KvGetString(hKeyValues, "name", g_sColorName[g_iColorCount], sizeof(g_sColorName[]));
		KvGetString(hKeyValues, "hex",	g_sColorHex[g_iColorCount], sizeof(g_sColorHex[]));
		ReplaceString(g_sColorHex[g_iColorCount], sizeof(g_sColorHex[]), "#", "", false);

		if(!IsValidHex(g_sColorHex[g_iColorCount]))
		{
			LogError("Invalid hexadecimal value for color %s.", g_sColorName[g_iColorCount]);
			strcopy(g_sColorName[g_iColorCount], sizeof(g_sColorName[]), "");
			strcopy(g_sColorHex[g_iColorCount], sizeof(g_sColorHex[]), "");
		}

		g_iColorCount++;
	}
	while(KvGotoNextKey(hKeyValues));
	CloseHandle(hKeyValues);
}

public LoadCustomConfigs()
{
	g_hBlockedTags = CreateArray(64);
	decl String:sBuffer[256];
	
	decl String:sFile[256];
	BuildPath(Path_SM, sFile, 255, "configs/togschattags_blocked.cfg");
	new Handle:hFile = OpenFile(sFile, "r");
	if (hFile != INVALID_HANDLE)
	{
		new i = 0;		//indexing the array
		while(ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
		{
			TrimString(sBuffer);		//remove spaces and tabs at both ends of string
			if((StrContains(sBuffer, "//") == -1) && (!StrEqual(sBuffer, "")))		//filter out comments and blank lines
			{
				ResizeArray(g_hBlockedTags, i+1);
				SetArrayString(g_hBlockedTags, i, sBuffer);
				i++;	//only increments if a valid string is found
			}
		}
	}
	else
	{
		LogError("File does not exist: \"%s\"", sFile);
	}
	
	CloseHandle(hFile);
	
	g_hIgnoredText_Equal = CreateArray(64);
	
	BuildPath(Path_SM, sFile, 255, "configs/togschattags_ignore_equal.cfg");
	new Handle:hFile2 = OpenFile(sFile, "r");
	if (hFile2 != INVALID_HANDLE)
	{
		new j = 0;		//indexing the array
		while(ReadFileLine(hFile2, sBuffer, sizeof(sBuffer)))
		{
			TrimString(sBuffer);		//remove spaces and tabs at both ends of string
			if((StrContains(sBuffer, "//") == -1) && (!StrEqual(sBuffer, "")))		//filter out comments and blank lines
			{
				ResizeArray(g_hIgnoredText_Equal, j+1);
				SetArrayString(g_hIgnoredText_Equal, j, sBuffer);
				j++;	//only increments if a valid string is found
			}
		}
	}
	else
	{
		LogError("File does not exist: \"%s\"", sFile);
	}
	
	CloseHandle(hFile2);
	
	g_hIgnoredText_Contains = CreateArray(64);
	
	BuildPath(Path_SM, sFile, 255, "configs/togschattags_ignore_contains.cfg");
	new Handle:hFile3 = OpenFile(sFile, "r");
	if (hFile3 != INVALID_HANDLE)
	{
		new k = 0;		//indexing the array
		while(ReadFileLine(hFile3, sBuffer, sizeof(sBuffer)))
		{
			TrimString(sBuffer);		//remove spaces and tabs at both ends of string
			if((StrContains(sBuffer, "//") == -1) && (!StrEqual(sBuffer, "")))		//filter out comments and blank lines
			{
				ResizeArray(g_hIgnoredText_Contains, k+1);
				SetArrayString(g_hIgnoredText_Contains, k, sBuffer);
				k++;	//only increments if a valid string is found
			}
		}
	}
	else
	{
		LogError("File does not exist: \"%s\"", sFile);
	}
	
	CloseHandle(hFile3);
}

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// Client Connections /////////////////////////////
//////////////////////////////////////////////////////////////////////////////

public OnClientConnected(client)	//get names as soon as they connect
{
	GetClientName(client, g_sName[client], sizeof(g_sName[]));
	g_iTagSetting[client] = 0;	
	g_iTagHidden[client] = 1;			
	g_iIsRestricted[client] = 0;	
	g_iIsLoaded[client] = 0;
	g_iChatTime1[client] = 0;
	g_iChatTime2[client] = 0;
	g_iSpamCoolDown[client] = 0;
	g_sTagColor[client] = "";
	g_sNameColor[client] = "";	
	g_sChatColor[client] = "";
	g_sTag[client] = "";
}

public OnClientAuthorized(client, const String:strAuth[])		//get Steam ID as soon as it is available
{
	GetClientAuthString(client, g_sSteamID[client], sizeof(g_sSteamID[]));
}

public OnClientPostAdminCheck(client)
{
	if(g_iEnabled && IsValidClient(client))
	{
		if(!g_iIsLoaded[client] && AreClientCookiesCached(client))	//if client cookies are aready cached, then load setup (else it will be loaded in OnClientCookiesCached())
		{
			LoadClientData(client);
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_iEnabled)
	{
		g_iTagSetting[client] = 0;
		g_sSteamID[client] = "";
		g_sName[client] = "";
		g_iTagHidden[client] = 1;			
		g_iIsRestricted[client] = 0;	
		g_iIsLoaded[client] = 0;
		g_iChatTime1[client] = 0;
		g_iChatTime2[client] = 0;
		g_iSpamCoolDown[client] = 0;
		g_sTagColor[client] = "";
		g_sNameColor[client] = "";	
		g_sChatColor[client] = "";		
		g_sTag[client] = "";
	}
}

bool:HasFlags(String:sFlags[], client)
{
	if(StrEqual(sFlags, "public", false) || StrEqual(sFlags, "", false))
	{
		return true;
	}
	if(StrEqual(sFlags, "none", false))
	{
		return false;
	}
	
	new AdminId:id = GetUserAdmin(client);
	if(id == INVALID_ADMIN_ID)
	{
		return false;
	}
	if(CheckCommandAccess(client, "sm_not_a_command", ADMFLAG_ROOT, true))
	{
		return true;
	}
	
	new iCount, iFound, flags;
	if(StrContains(sFlags, ";", false) != -1) //check if multiple strings
	{
		new c = 0, iStrCount = 0;
		while(sFlags[c] != '\0')
		{
			if(sFlags[c++] == ';')
			{
				iStrCount++;
			}
		}
		iStrCount++; //add one more for IP after last comma
		decl String:sTempArray[iStrCount][30];
		ExplodeString(sFlags, ";", sTempArray, iStrCount, 30);
		
		for(new i = 0; i < iStrCount; i++)
		{
			flags = ReadFlagString(sTempArray[i]);
			iCount = 0;
			iFound = 0;
			for(new j = 0; j <= 20; j++)
			{
				if(flags & (1<<j))
				{
					iCount++;

					if(GetAdminFlag(id, AdminFlag:j))
					{
						iFound++;
					}
				}
			}
			
			if(iCount == iFound)
			{
				return true;
			}
		}
	}
	else
	{
		flags = ReadFlagString(sFlags);
		iCount = 0;
		iFound = 0;
		for(new i = 0; i <= 20; i++)
		{
			if(flags & (1<<i))
			{
				iCount++;

				if(GetAdminFlag(id, AdminFlag:i))
				{
					iFound++;
				}
			}
		}

		if(iCount == iFound)
		{
			return true;
		}
	}
	return false;
}

//////////////////////////////////////////////////////////////////
///////////////////////////// Events /////////////////////////////
//////////////////////////////////////////////////////////////////

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_iEnabled)
	{
		decl String:sText[300];
		GetCmdArgString(sText, sizeof(sText));
		StripQuotes(sText);
		
		if(g_iConvertTriggerCases)
		{
			if((sText[0] == '!') || (sText[0] == '/'))
			{
				if(IsCharUpper(sText[1]))
				{
					for(new i = 0; i <= strlen(sText); ++i)
					{
						sText[i] = CharToLower(sText[i]);
					}

					FakeClientCommand(client, "say %s", sText);
					return Plugin_Handled;
				}
			}
		}
		
		if(g_iLog)
		{
			//this also logs admin/player commands entered via chat. Need to log admin chat through console separately
			decl String:sName[MAX_NAME_LENGTH];
			if(IsValidClient(client))
			{
				GetClientName(client, sName, sizeof(sName));
			}
			else
			{
				Format(sName, sizeof(sName), "CONSOLE");
			}
			LogToFileEx(g_sChatLogPath, "%s (say): %s", sName, sText);
		}
		
		//if invalid, continue with regular say function
		if(!IsValidClient(client))
		{
			return Plugin_Continue;
		}

		//check for hiding invisible chat triggers and admin chat
		if((IsChatTrigger() && (sText[0] == '/')) || ((sText[0] == '@') && HasFlags("j", client)))
		{
			return Plugin_Continue;
		}

		new iIgnoredText = 0;
	
		for(new j = 0; j < GetArraySize(g_hIgnoredText_Equal); j++)
		{
			decl String:sBuffer[128];
			GetArrayString(g_hIgnoredText_Equal, j, sBuffer, sizeof(sBuffer));
			if(StrEqual(sText, sBuffer, false))
			{
				iIgnoredText = 1;
			}
		}
		
		for(new k = 0; k < GetArraySize(g_hIgnoredText_Contains); k++)
		{
			decl String:sBuffer2[128];
			GetArrayString(g_hIgnoredText_Contains, k, sBuffer2, sizeof(sBuffer2));
			if(StrContains(sText, sBuffer2, false) != -1)
			{
				iIgnoredText = 1;
			}
		}
		
		if(iIgnoredText)
		{
			return Plugin_Continue;
		}
		
		if (BaseComm_IsClientGagged(client))
		{
			PrintToChat(client, "=================================");
			PrintToChat(client, " ƪ(ツ)ノ                           Nice Try!                 ( ͡° ͜ʖ ͡°)");
			PrintToChat(client, "--------- You're gagged and cannot speak. --------");
			PrintToChat(client, "(ノಠ益ಠ)ノ彡┻━┻       YOU MAD?       ლ(ಠ益ಠლ)");
			PrintToChat(client, "=================================");
			return Plugin_Continue;	
		}
		
		if(g_iSpamCoolDown[client])
		{
			PrintToChat(client, "\x03You are sending messages too fast!");
			return Plugin_Handled;
		}
		else if(g_iChatTime2[client])
		{
			g_iSpamCoolDown[client] = 1;
			CreateTimer(g_fSpamDuration, TimerCallback_Spam3, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(g_iChatTime1[client])
		{
			g_iChatTime2[client] = 1;
			CreateTimer(g_fSpamDuration, TimerCallback_Spam2, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			g_iChatTime1[client] = 1;
			CreateTimer(g_fSpamDuration, TimerCallback_Spam1, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		SendMessage(client, sText);
		
	}
	else
	{
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

public Action:Command_SayTeam(client, const String:command[], argc)
{
	if(g_iEnabled)
	{
		decl String:sText[300];
		GetCmdArgString(sText, sizeof(sText));
		StripQuotes(sText);
		
		if(g_iConvertTriggerCases)
		{
			if((sText[0] == '!') || (sText[0] == '/'))
			{
				if(IsCharUpper(sText[1]))
				{
					for(new i = 0; i <= strlen(sText); ++i)
					{
						sText[i] = CharToLower(sText[i]);
					}

					FakeClientCommand(client, "say %s", sText);
					return Plugin_Handled;
				}
			}
		}
		
		if(g_iLog)
		{
			//this also logs admin/player commands entered via chat. Need to log admin chat through console separately
			decl String:sName[MAX_NAME_LENGTH];
			if(IsValidClient(client))
			{
				GetClientName(client, sName, sizeof(sName));
			}
			else
			{
				Format(sName, sizeof(sName), "CONSOLE");
			}
			LogToFileEx(g_sChatLogPath, "%s (say_team): %s", sName, sText);
		}

		//if invalid, not currently having access, or has no setup saved, continue with regular say function
		if(!IsValidClient(client))
		{
			return Plugin_Continue;
		}
		
		//check for hiding invisible chat triggers and admin chat
		if((IsChatTrigger() && (sText[0] == '/')) || (sText[0] == '@'))
		{
			return Plugin_Continue;
		}
		
		new iIgnoredText = 0;
	
		for(new j = 0; j < GetArraySize(g_hIgnoredText_Equal); j++)
		{
			decl String:sBuffer[128];
			GetArrayString(g_hIgnoredText_Equal, j, sBuffer, sizeof(sBuffer));
			if(StrEqual(sText, sBuffer, false))
			{
				iIgnoredText = 1;
			}
		}
		
		for(new k = 0; k < GetArraySize(g_hIgnoredText_Contains); k++)
		{
			decl String:sBuffer2[128];
			GetArrayString(g_hIgnoredText_Contains, k, sBuffer2, sizeof(sBuffer2));
			if(StrContains(sText, sBuffer2, false) != -1)
			{
				iIgnoredText = 1;
			}
		}
		
		if(iIgnoredText)
		{
			return Plugin_Continue;
		}

		if (BaseComm_IsClientGagged(client))
		{
			PrintToChat(client, "=================================");
			PrintToChat(client, " ƪ(ツ)ノ                           Nice Try!                 ( ͡° ͜ʖ ͡°)");
			PrintToChat(client, "--------- You're gagged and cannot speak. --------");
			PrintToChat(client, "(ノಠ益ಠ)ノ彡┻━┻       YOU MAD?       ლ(ಠ益ಠლ)");
			PrintToChat(client, "=================================");
			return Plugin_Continue;	
		}
		
		if(g_iSpamCoolDown[client])
		{
			PrintToChat(client, "\x03You are sending messages too fast!");
			return Plugin_Handled;
		}
		else if(g_iChatTime2[client])
		{
			g_iSpamCoolDown[client] = 1;
			CreateTimer(g_fSpamDuration, TimerCallback_Spam3, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(g_iChatTime1[client])
		{
			g_iChatTime2[client] = 1;
			CreateTimer(g_fSpamDuration, TimerCallback_Spam2, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			g_iChatTime1[client] = 1;
			CreateTimer(g_fSpamDuration, TimerCallback_Spam1, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		SendMessageTeam(client, sText);
	}
	else
	{
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

public Action:TimerCallback_Spam3(Handle:Timer, any:client)
{
	g_iSpamCoolDown[client] = 0;
}

public Action:TimerCallback_Spam2(Handle:Timer, any:client)
{
	g_iChatTime2[client] = 0;
}

public Action:TimerCallback_Spam1(Handle:Timer, any:client)
{
	g_iChatTime1[client] = 0;
}

SendMessage(client, String:sText[])
{
	decl String:sBuffer[14];
	decl String:sTeamColor[13];
	decl String:sTeamName[13];
	new iIncludeBuffer = 0;
	if(GetClientTeam(client) == 1)
	{
		Format(sBuffer, sizeof(sBuffer), "\x01*SPEC* ");
		iIncludeBuffer = 1;
	}
	else if(!IsPlayerAlive(client) && ((GetClientTeam(client) == 2) || (GetClientTeam(client) == 3)))
	{
		Format(sBuffer, sizeof(sBuffer), "\x01*DEAD* ");
		iIncludeBuffer = 1;
	}
	
	if(GetClientTeam(client) == 2)
	{
		Format(sTeamColor, sizeof(sTeamColor), "\x07FF4040");
		Format(sTeamName, sizeof(sTeamName), "%s", sTeamTwoName);
	}
	else if(GetClientTeam(client) == 3)
	{
		Format(sTeamColor, sizeof(sTeamColor), "\x0799CCFF");
		Format(sTeamName, sizeof(sTeamName), "%s", sTeamThreeName);
	}
	else
	{
		Format(sTeamColor, sizeof(sTeamColor), "\x07CCCCCC");
		Format(sTeamName, sizeof(sTeamName), "Spectator");
	}
	
	LogToGame("\"%L(%s)\" say \"%s\"", client, sTeamName, sText);
	
	switch(g_iTagSetting[client])
	{
		case INDEX_NONE:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01%s%s \x01:  %s", sTeamColor, g_sName[client], sText);
			}
			else
			{
				CPrintToChatAll("%s%s%s \x01:  %s", sBuffer, sTeamColor, g_sName[client], sText);
			}
		}
		case INDEX_CHAT:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01%s%s \x01:  \x07%s%s", sTeamColor, g_sName[client], g_sChatColor[client], sText);
			}
			else
			{
				CPrintToChatAll("%s%s%s \x01:  \x07%s%s", sBuffer, sTeamColor, g_sName[client], g_sChatColor[client], sText);
			}
		}
		case INDEX_NAME:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01\x07%s%s \x01:  %s", g_sNameColor[client], g_sName[client], sText);
			}
			else
			{
				CPrintToChatAll("%s\x07%s%s \x01:  %s", sBuffer, g_sNameColor[client], g_sName[client], sText);
			}
		}
		case INDEX_NAMECHAT:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01\x07%s%s \x01:  \x07%s%s", g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
			}
			else
			{
				CPrintToChatAll("%s\x07%s%s \x01:  \x07%s%s", sBuffer, g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
			}
		}
		case INDEX_TEXT:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01%s %s%s :  %s", g_sTag[client], sTeamColor, g_sName[client], sText);
			}
			else
			{
				CPrintToChatAll("%s%s %s%s :  %s", sBuffer, g_sTag[client], sTeamColor, g_sName[client], sText);
			}
		}
		case INDEX_TEXTCHAT:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01%s %s%s :  \x07%s%s", g_sTag[client], sTeamColor, g_sName[client], g_sChatColor[client], sText);
			}
			else
			{
				CPrintToChatAll("%s%s %s%s :  \x07%s%s", sBuffer, g_sTag[client], sTeamColor, g_sName[client], g_sChatColor[client], sText);
			}
		}
		case INDEX_TEXTNAME:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01%s \x07%s%s \x01:  %s", g_sTag[client], g_sNameColor[client], g_sName[client], sText);
			}
			else
			{
				CPrintToChatAll("%s%s \x07%s%s \x01:  %s", sBuffer, g_sTag[client], g_sNameColor[client], g_sName[client], sText);
			}
		}
		case INDEX_TEXTNAMECHAT:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01%s \x07%s%s \x01:  \x07%s%s", g_sTag[client], g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
			}
			else
			{
				CPrintToChatAll("%s%s \x07%s%s \x01:  \x07%s%s", sBuffer, g_sTag[client], g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
			}
		}
		case INDEX_TEXTTAG:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01\x07%s%s %s%s \x01:  %s", g_sTagColor[client], g_sTag[client], sTeamColor, g_sName[client], sText);
			}
			else
			{
				CPrintToChatAll("%s\x07%s%s %s%s \x01:  %s", sBuffer, g_sTagColor[client], g_sTag[client], sTeamColor, g_sName[client], sText);
			}
		}
		case INDEX_TEXTTAGCHAT:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01\x07%s%s %s%s \x01:  \x07%s%s", g_sTagColor[client], g_sTag[client], sTeamColor, g_sName[client], g_sChatColor[client], sText);
			}
			else
			{
				CPrintToChatAll("%s\x07%s%s %s%s \x01:  \x07%s%s", sBuffer, g_sTagColor[client], g_sTag[client], sTeamColor, g_sName[client], g_sChatColor[client], sText);
			}
		}
		case INDEX_TEXTTAGNAME:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01\x07%s%s \x07%s%s \x01:  %s", g_sTagColor[client], g_sTag[client], g_sNameColor[client], g_sName[client], sText);
			}
			else
			{
				CPrintToChatAll("%s\x07%s%s \x07%s%s \x01:  %s", sBuffer, g_sTagColor[client], g_sTag[client], g_sNameColor[client], g_sName[client], sText);
			}
		}
		case INDEX_TEXTTAGNAMECHAT:
		{
			if(!iIncludeBuffer)
			{
				CPrintToChatAll("\x01\x07%s%s \x07%s%s \x01:  \x07%s%s", g_sTagColor[client], g_sTag[client], g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
			}
			else
			{
				CPrintToChatAll("%s\x07%s%s \x07%s%s \x01:  \x07%s%s", sBuffer, g_sTagColor[client], g_sTag[client], g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
			}
		}
	}
}

SendMessageTeam(client, String:sText[])
{
	decl String:sBuffer[14];
	decl String:sTeamColor[13];
	decl String:sTeamName[27];
	new iIncludeBuffer = 0;
	if(GetClientTeam(client) == 1)
	{
		Format(sBuffer, sizeof(sBuffer), "\x01*SPEC* ");
		iIncludeBuffer = 1;
	}
	else if(!IsPlayerAlive(client) && ((GetClientTeam(client) == 2) || (GetClientTeam(client) == 3)))
	{
		Format(sBuffer, sizeof(sBuffer), "\x01*DEAD* ");
		iIncludeBuffer = 1;
	}
	//no formatting yet, for sending to hlsw/server
	if(GetClientTeam(client) == 2)
	{
		Format(sTeamName, sizeof(sTeamName), "%s", sTeamTwoName);
	}
	else if(GetClientTeam(client) == 3)
	{
		Format(sTeamName, sizeof(sTeamName), "%s", sTeamThreeName);
	}
	else
	{
		Format(sTeamName, sizeof(sTeamName), "Spectator");
	}
	LogToGame("\"%L(%s)\" say \"%s\"", client, sTeamName, sText);
	
	//now format
	if(GetClientTeam(client) == 2)
	{
		Format(sTeamColor, sizeof(sTeamColor), "\x07FF4040");
		Format(sTeamName, sizeof(sTeamName), "\x01(%s) ", sTeamTwoName);
	}
	else if(GetClientTeam(client) == 3)
	{
		Format(sTeamColor, sizeof(sTeamColor), "\x0799CCFF");
		Format(sTeamName, sizeof(sTeamName), "\x01(%s) ", sTeamThreeName);
	}
	else if(GetClientTeam(client) == 1)
	{
		Format(sTeamColor, sizeof(sTeamColor), "\x07CCCCCC");
		Format(sTeamName, sizeof(sTeamName), "\x01(Spectator) ");
	}
	else
	{
		Format(sTeamColor, sizeof(sTeamColor), "\x07CCCCCC");
	}
	
	switch(g_iTagSetting[client])
	{
		case INDEX_NONE:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s%s \x01:  %s", sTeamName, sTeamColor, g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s%s%s \x01:  %s", sBuffer, sTeamName, sTeamColor, g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
		case INDEX_CHAT:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s%s \x01:  \x07%s%s", sTeamName, sTeamColor, g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s%s%s \x01:  \x07%s%s", sBuffer, sTeamName, sTeamColor, g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
		case INDEX_NAME:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s\x07%s%s \x01:  %s", sTeamName, g_sNameColor[client], g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s\x07%s%s \x01:  %s", sBuffer, sTeamName, g_sNameColor[client], g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
		case INDEX_NAMECHAT:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "\x07%s%s \x01:  \x07%s%s", sTeamName, g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s\x07%s%s \x01:  \x07%s%s", sBuffer, sTeamName, g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
		case INDEX_TEXT:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s %s%s :  %s", sTeamName, g_sTag[client], sTeamColor, g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s%s %s%s :  %s", sBuffer, sTeamName, g_sTag[client], sTeamColor, g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
		case INDEX_TEXTCHAT:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s %s%s :  \x07%s%s", sTeamName, g_sTag[client], sTeamColor, g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s%s %s%s :  \x07%s%s", sBuffer, sTeamName, g_sTag[client], sTeamColor, g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
		case INDEX_TEXTNAME:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s \x07%s%s \x01:  %s", sTeamName, g_sTag[client], g_sNameColor[client], g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s%s \x07%s%s \x01:  %s", sBuffer, sTeamName, g_sTag[client], g_sNameColor[client], g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
		case INDEX_TEXTNAMECHAT:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s \x07%s%s \x01:  \x07%s%s", sTeamName, g_sTag[client], g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s%s \x07%s%s \x01:  \x07%s%s", sBuffer, sTeamName, g_sTag[client], g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
		case INDEX_TEXTTAG:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s\x07%s%s %s%s \x01:  %s", sTeamName, g_sTagColor[client], g_sTag[client], sTeamColor, g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s\x07%s%s %s%s \x01:  %s", sBuffer, sTeamName, g_sTagColor[client], g_sTag[client], sTeamColor, g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
		case INDEX_TEXTTAGCHAT:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s\x07%s%s %s%s \x01:  \x07%s%s", sTeamName, g_sTagColor[client], g_sTag[client], sTeamColor, g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s\x07%s%s %s%s \x01:  \x07%s%s", sBuffer, sTeamName, g_sTagColor[client], g_sTag[client], sTeamColor, g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
		case INDEX_TEXTTAGNAME:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s\x07%s%s \x07%s%s \x01:  %s", sTeamName, g_sTagColor[client], g_sTag[client], g_sNameColor[client], g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s\x07%s%s \x07%s%s \x01:  %s", sBuffer, sTeamName, g_sTagColor[client], g_sTag[client], g_sNameColor[client], g_sName[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
		case INDEX_TEXTTAGNAMECHAT:
		{
			if(!iIncludeBuffer)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s\x07%s%s \x07%s%s \x01:  \x07%s%s", sTeamName, g_sTagColor[client], g_sTag[client], g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(GetClientTeam(i) == GetClientTeam(client))
						{
							CPrintToChat(i, "%s%s\x07%s%s \x07%s%s \x01:  \x07%s%s", sBuffer, sTeamName, g_sTagColor[client], g_sTag[client], g_sNameColor[client], g_sName[client], g_sChatColor[client], sText);
						}
						else
						{
							if(HasFlags(g_sAdminSeeAllFlag, i) && g_iAdminSeeAll)
							{
								CPrintToChat(i, "\x04[AdminSeeAll]\x01%s:  %s", g_sName[client], sText);
							}
						}
					}
				}
			}
		}
	}
}

public Action:Command_AdminChat(client, const String:command[], argc)
{
	//skip logging if through chat because it is already logged
	if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		return Plugin_Continue;
	}
	
	if(!g_iLog)
	{
		return Plugin_Continue;
	}
	
	decl String:sBuffer[128];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	
	decl String:sName[MAX_NAME_LENGTH];
	if(IsValidClient(client))
	{
		GetClientName(client, sName, sizeof(sName));
	}
	else
	{
		Format(sName, sizeof(sName), "CONSOLE");
	}
	LogToFileEx(g_sChatLogPath, "%s (admin say): %s", sName, sBuffer);

	return Plugin_Continue;
}

public Action:Command_AdminOnlyChat(client, const String:command[], argc)
{
	//skip logging if through chat because it is already logged
	if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		return Plugin_Continue;
	}
	
	if(!g_iLog)
	{
		return Plugin_Continue;
	}
	
	decl String:sBuffer[128];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	
	decl String:sName[MAX_NAME_LENGTH];
	if(IsValidClient(client))
	{
		GetClientName(client, sName, sizeof(sName));
	}
	else
	{
		Format(sName, sizeof(sName), "CONSOLE");
	}
	LogToFileEx(g_sChatLogPath, "%s (admin only): %s", sName, sBuffer);

	return Plugin_Continue;
}

public Action:Command_CSay(client, const String:command[], argc)
{
	//skip logging if through chat because it is already logged
	if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		return Plugin_Continue;
	}
	
	if(!g_iLog)
	{
		return Plugin_Continue;
	}
	
	decl String:sBuffer[128];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	
	decl String:sName[MAX_NAME_LENGTH];
	if(IsValidClient(client))
	{
		GetClientName(client, sName, sizeof(sName));
	}
	else
	{
		Format(sName, sizeof(sName), "CONSOLE");
	}
	LogToFileEx(g_sChatLogPath, "%s (csay): %s", sName, sBuffer);

	return Plugin_Continue;
}

public Action:Command_TSay(client, const String:command[], argc)
{
	//skip logging if through chat because it is already logged
	if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		return Plugin_Continue;
	}
	
	if(!g_iLog)
	{
		return Plugin_Continue;
	}
	
	decl String:sBuffer[128];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	
	decl String:sName[MAX_NAME_LENGTH];
	if(IsValidClient(client))
	{
		GetClientName(client, sName, sizeof(sName));
	}
	else
	{
		Format(sName, sizeof(sName), "CONSOLE");
	}
	LogToFileEx(g_sChatLogPath, "%s (tsay): %s", sName, sBuffer);

	return Plugin_Continue;
}

public Action:Command_MSay(client, const String:command[], argc)
{
	//skip logging if through chat because it is already logged
	if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		return Plugin_Continue;
	}
	
	if(!g_iLog)
	{
		return Plugin_Continue;
	}
	
	decl String:sBuffer[128];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	
	decl String:sName[MAX_NAME_LENGTH];
	if(IsValidClient(client))
	{
		GetClientName(client, sName, sizeof(sName));
	}
	else
	{
		Format(sName, sizeof(sName), "CONSOLE");
	}
	LogToFileEx(g_sChatLogPath, "%s (msay): %s", sName, sBuffer);

	return Plugin_Continue;
}

public Action:Command_HSay(client, const String:command[], argc)
{
	//skip logging if through chat because it is already logged
	if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		return Plugin_Continue;
	}
	
	if(!g_iLog)
	{
		return Plugin_Continue;
	}
	
	decl String:sBuffer[128];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	
	decl String:sName[MAX_NAME_LENGTH];
	if(IsValidClient(client))
	{
		GetClientName(client, sName, sizeof(sName));
	}
	else
	{
		Format(sName, sizeof(sName), "CONSOLE");
	}
	LogToFileEx(g_sChatLogPath, "%s (hsay): %s", sName, sBuffer);

	return Plugin_Continue;
}

public Action:Command_PSay(client, const String:command[], argc)
{
	//skip logging if through chat because it is already logged
	if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		return Plugin_Continue;
	}
	
	if(!g_iLog)
	{
		return Plugin_Continue;
	}
	
	decl String:sBuffer[128];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	
	decl String:sName[MAX_NAME_LENGTH];
	if(IsValidClient(client))
	{
		GetClientName(client, sName, sizeof(sName));
	}
	else
	{
		Format(sName, sizeof(sName), "CONSOLE");
	}
	LogToFileEx(g_sChatLogPath, "%s (psay): %s", sName, sBuffer);

	return Plugin_Continue;
}

public Action:Event_NameChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsValidClient(client))
			return Plugin_Continue;

		GetClientName(client, g_sName[client], sizeof(g_sName[]));
	}
	
	return Plugin_Continue;
}

Reload()
{
	LoadColorCfg();
	LoadCustomConfigs();
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && AreClientCookiesCached(i))
		{
			OnClientConnected(i);
			LoadClientData(i);
		}
	}
}

public OnClientSettingsChanged(client)
{
	if(g_iEnabled)
	{
		if(IsValidClient(client))
		{
			GetClientName(client, g_sName[client], sizeof(g_sName[]));
		}
	}
}

//////////////////////////////////////////////////////////////////////////
///////////////////////////// Admin Commands /////////////////////////////
//////////////////////////////////////////////////////////////////////////

public Action:Cmd_Reload(client,args)
{
	if(client != 0)
	{	
		if(!HasFlags(g_sAdminFlag, client))
		{
			PrintToConsole(client, "[TCT] You do not have access to this command!");
			PrintToChat(client, "[TCT] You do not have access to this command!");
			return Plugin_Handled;
		}
	}
	
	Reload();
	
	ReplyToCommand(client, "[TCT] Colors setups are now reloaded.");
	
	return Plugin_Continue;
}

public Action:Cmd_Unload(client,args)
{
	ReplyToCommand(client, "[TCT] TOGs Chat Tags is now unloaded until map change!");
	
	ServerCommand("sm plugins unload togschattags.smx");
	
	return Plugin_Continue;
}

public Action:Cmd_RemoveTag(client,args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "[TCT] Must be in the server to execute command!");
		return Plugin_Handled;
	}
	
	if(args != 1)
	{
		ReplyToCommand(client, "[TCT] Usage: sm_removetag <name>");
		return Plugin_Handled;
	}
	
	if(!HasFlags(g_sAdminFlag, client))
	{
		PrintToConsole(client, "[TCT] You do not have access to this command!");
		PrintToChat(client, "[TCT] You do not have access to this command!");
		return Plugin_Handled;
	}
	
	decl String:sTargetArg[MAX_NAME_LENGTH];
	GetCmdArg(1,sTargetArg,sizeof(sTargetArg));
	
	if(SearchForPlayer(sTargetArg) == 0)
	{
		ReplyToCommand(client, "[TCT] No valid clients found!");
		return Plugin_Handled;
	}
	else if(SearchForPlayer(sTargetArg) > 1)
	{
		ReplyToCommand(client, "[TCT] More than one matching player found!");
		return Plugin_Handled;
	}
	
	new target = FindTarget(client, sTargetArg, true);
	
	if(!IsValidClient(target))
	{
		ReplyToCommand(client, "Invalid target!");
		return Plugin_Handled;
	}
	
	if(IsFakeClient(target))
	{
		ReplyToCommand(client, "[TCT] Cannot target bots!");
		return Plugin_Handled;
	}
	
	RemoveSetup(target);
	
	ReplyToCommand(client, "[TCT] Tag settings for player '%s' are now set to default.", g_sName[target]);
	
	return Plugin_Continue;
}

RemoveSetup(target)
{
	if(!IsValidClient(target))
		return;

	g_iTagSetting[target] = 0;
	g_iTagHidden[target] = 1;		
	g_iIsRestricted[target] = 0;
	g_sTagColor[target] = "";
	g_sNameColor[target] = "";
	g_sChatColor[target] = "";	
	g_sTag[target] = "";
	SetClientCookie(target, g_hCookieTagHidden, "1");
	SetClientCookie(target, g_hCookieTag, "");
	SetClientCookie(target, g_hCookieTagColor, "");
	SetClientCookie(target, g_hCookieNameColor, "");
	SetClientCookie(target, g_hCookieChatColor, "");
	SetSetting(target);
}

public Action:Cmd_Restrict(client,args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "[TCT] Must be in the server to execute command!");
		return Plugin_Handled;
	}
	
	if(args != 1)
	{
		ReplyToCommand(client, "[TCT] Usage: sm_restricttag <name>");
		return Plugin_Handled;
	}
	
	if(!HasFlags(g_sAdminFlag, client))
	{
		PrintToConsole(client, "[TCT] You do not have access to this command!");
		PrintToChat(client, "[TCT] You do not have access to this command!");
		return Plugin_Handled;
	}
	
	decl String:sTargetArg[MAX_NAME_LENGTH];
	GetCmdArg(1,sTargetArg,sizeof(sTargetArg));
	
	if(SearchForPlayer(sTargetArg) == 0)
	{
		ReplyToCommand(client, "[TCT] No valid clients found!");
		return Plugin_Handled;
	}
	else if(SearchForPlayer(sTargetArg) > 1)
	{
		ReplyToCommand(client, "[TCT] More than one matching player found!");
		return Plugin_Handled;
	}
	
	new target = FindTarget(client, sTargetArg, true);
	
	if(!IsValidClient(target))
	{
		ReplyToCommand(client, "Invalid target!");
		return Plugin_Handled;
	}
	
	if(IsFakeClient(target))
	{
		ReplyToCommand(client, "[TCT] Cannot target bots!");
		return Plugin_Handled;
	}
	
	RestrictPlayer(client,target);
	
	return Plugin_Continue;
}

RestrictPlayer(client,target)
{
	if(!IsValidClient(target))
	{
		PrintToConsole(client, "[TCT] Target '%s' is either not in game, or is a bot!", g_sName[target]);
		PrintToChat(client, "[TCT] Target '%s' is either not in game, or is a bot!", g_sName[target]);
		return;
	}
	else if(g_iIsRestricted[target] == 1)
	{
		PrintToConsole(client, "[TCT] Target '%s' is already restricted!", g_sName[target]);
		PrintToChat(client, "[TCT] Target '%s' is already restricted!", g_sName[target]);
		return;
	}
	else
	{
		PrintToConsole(client, "[TCT] '%s' is now restricted from changing their chat tag!", g_sName[target]);
		CPrintToChatAll("\x07FF0000[TCT] '%s' has restricted '%s' from changing their chat tag!", g_sName[client], g_sName[target]);
		
		g_iIsRestricted[target] = 1;
		SetClientCookie(target, g_hCookieIsRestricted, "1");
	}
}

public Action:Cmd_Unrestrict(client,args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "[TCT] Must be in the server to execute command!");
		return Plugin_Handled;
	}
	
	if(args != 1)
	{
		ReplyToCommand(client, "[TCT] Usage: sm_unrestricttag <name>");
		return Plugin_Handled;
	}
	
	if(!HasFlags(g_sAdminFlag, client))
	{
		PrintToConsole(client, "[TCT] You do not have access to this command!");
		PrintToChat(client, "[TCT] You do not have access to this command!");
		return Plugin_Handled;
	}
	
	decl String:sTargetArg[MAX_NAME_LENGTH];
	GetCmdArg(1,sTargetArg,sizeof(sTargetArg));
	
	if(SearchForPlayer(sTargetArg) == 0)
	{
		ReplyToCommand(client, "[TCT] No valid clients found!");
		return Plugin_Handled;
	}
	else if(SearchForPlayer(sTargetArg) > 1)
	{
		ReplyToCommand(client, "[TCT] More than one matching player found!");
		return Plugin_Handled;
	}
	
	new target = FindTarget(client, sTargetArg, true);
	
	if(!IsValidClient(target))
	{
		ReplyToCommand(client, "Invalid target!");
		return Plugin_Handled;
	}
	
	if(IsFakeClient(target))
	{
		ReplyToCommand(client, "[TCT] Cannot target bots!");
		return Plugin_Handled;
	}
	
	UnrestrictPlayer(client,target);
	
	return Plugin_Continue;
}

UnrestrictPlayer(client,target)
{
	if(!IsValidClient(target))
	{
		PrintToConsole(client, "[TCT] Target '%s' is either not in game, or is a bot!", g_sName[target]);
		PrintToChat(client, "[TCT] Target '%s' is either not in game, or is a bot!", g_sName[target]);
		return;
	}
	else if(g_iIsRestricted[target] == 0)
	{
		PrintToConsole(client, "[TCT] Target '%s' is not restricted!", g_sName[target]);
		PrintToChat(client, "[TCT] Target '%s' is not restricted!", g_sName[target]);
		return;
	}
	else
	{
		PrintToConsole(client, "[TCT] Target '%s' is now unrestricted from changing their chat tag!", g_sName[target]);
		CPrintToChatAll("\x07FF0000[TCT] '%s' has unrestricted '%s' from changing their chat tag!", g_sName[client], g_sName[target]);
		
		g_iIsRestricted[target] = 0;
		SetClientCookie(target, g_hCookieIsRestricted, "0");
	}
}

////////////////////////////////////////////////////////////////////
///////////////////////////// Commands /////////////////////////////
////////////////////////////////////////////////////////////////////

public Action:Command_Tag(client, iArgs)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	if(g_iIsRestricted[client])
	{
		PrintToChat(client, "[TCT] You are currently restricted from changing your tags!");
		return Plugin_Handled;
	}
	if(!g_iIsLoaded[client])
	{
		PrintToChat(client, "[TCT] This feature is disabled until your cookies have cached!");
		return Plugin_Handled;
	}

	Menu_MainTag(client);
	return Plugin_Handled;
}

public Action:Command_TagColor(client, iArgs)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	if(iArgs != 1)
	{
		ReplyToCommand(client, "[TCT] Usage: sm_tagcolor <hex>");
		return Plugin_Handled;
	}
	
	if(!HasFlags(g_sAccessFlag, client))
	{
		PrintToChat(client, "[TCT] You do not have access to this feature!");
		return Plugin_Handled;
	}
	
	if(g_iIsRestricted[client])
	{
		PrintToChat(client, "[TCT] You are currently restricted from changing your tags!");
		return Plugin_Handled;
	}
	
	if(!g_iIsLoaded[client])
	{
		PrintToChat(client, "[TCT] This feature is disabled until your cookies have cached!");
		return Plugin_Handled;
	}

	decl String:sArg[32];
	GetCmdArgString(sArg, sizeof(sArg));
	ReplaceString(sArg, sizeof(sArg), "#", "", false);

	if(!IsValidHex(sArg))
	{
		ReplyToCommand(client, "[TCT] Usage: sm_tagcolor <hex>");
		return Plugin_Handled;
	}

	CPrintToChat(client, "\x01[TCT] Your tag is now set to:\x07%s %s", sArg, sArg);
	strcopy(g_sTagColor[client], sizeof(g_sTagColor[]), sArg);
	SetClientCookie(client, g_hCookieTagColor, sArg);
	SetSetting(client);

	return Plugin_Handled;
}

public Action:Command_SetText(client, iArgs)
{
	if(!IsValidClient(client))
		return Plugin_Continue;
	
	if(!HasFlags(g_sAccessFlag, client))
	{
		PrintToChat(client, "[TCT] You do not have access to this feature!");
		return Plugin_Handled;
	}
	
	if(g_iIsRestricted[client])
	{
		PrintToChat(client, "[TCT] You are currently restricted from changing your tags!");
		return Plugin_Handled;
	}
	
	if(!g_iIsLoaded[client])
	{
		PrintToChat(client, "[TCT] This feature is disabled until your cookies have cached!");
		return Plugin_Handled;
	}

	decl String:sArg[22];
	GetCmdArgString(sArg, sizeof(sArg));
	
	new iBlockedName = 0;
	
	for(new i = 0; i < GetArraySize(g_hBlockedTags); i++)
	{
		decl String:sBuffer[75];
		GetArrayString(g_hBlockedTags, i, sBuffer, sizeof(sBuffer));
		if(StrContains(sArg, sBuffer, false) != -1)
		{
			iBlockedName = 1;
		}
	}
	
	if(iBlockedName)
	{
		if(!HasFlags(g_sAdminFlag, client))
		{
			PrintToChat(client, "[TCT] Nice try! This tag is blocked from use.");
			return Plugin_Handled;
		}
	}

	PrintToChat(client, "[TCT] Your tag is now visible and is set to: %s", sArg);
	strcopy(g_sTag[client], sizeof(g_sTag[]), sArg);
	SetClientCookie(client, g_hCookieTag, sArg);
	g_iTagHidden[client] = 0;
	SetClientCookie(client, g_hCookieTagHidden, "0");
	SetSetting(client);
	
	return Plugin_Handled;
}

public Action:Command_NameColor(client, iArgs)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	if(iArgs != 1)
	{
		ReplyToCommand(client, "[TCT] Usage: sm_namecolor <hex>");
		return Plugin_Handled;
	}
	
	if(!HasFlags(g_sAccessFlag, client))
	{
		PrintToChat(client, "[TCT] You do not have access to this feature!");
		return Plugin_Handled;
	}
	
	if(g_iIsRestricted[client])
	{
		PrintToChat(client, "[TCT] You are currently restricted from changing your tags!");
		return Plugin_Handled;
	}
	
	if(!g_iIsLoaded[client])
	{
		PrintToChat(client, "[TCT] This feature is disabled until your cookies have cached!");
		return Plugin_Handled;
	}

	decl String:sArg[32];
	GetCmdArgString(sArg, sizeof(sArg));
	ReplaceString(sArg, sizeof(sArg), "#", "", false);

	if(!IsValidHex(sArg))
	{
		ReplyToCommand(client, "[TCT] Usage: sm_namecolor <hex>");
		return Plugin_Handled;
	}

	CPrintToChat(client, "\x01[TCT] Your name color is now set to: \x07%s%s", sArg, sArg);
	strcopy(g_sNameColor[client], sizeof(g_sNameColor[]), sArg);
	SetClientCookie(client, g_hCookieNameColor, sArg);
	SetSetting(client);

	return Plugin_Handled;
}

public Action:Command_ChatColor(client, iArgs)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	if(iArgs != 1)
	{
		ReplyToCommand(client, "[TCT] Usage: sm_chatcolor <hex>");
		return Plugin_Handled;
	}
	
	if(!HasFlags(g_sAccessFlag, client))
	{
		PrintToChat(client, "[TCT] You do not have access to this feature!");
		return Plugin_Handled;
	}
	
	if(g_iIsRestricted[client])
	{
		PrintToChat(client, "[TCT] You are currently restricted from changing your tags!");
		return Plugin_Handled;
	}
	
	if(!g_iIsLoaded[client])
	{
		PrintToChat(client, "[TCT] This feature is disabled until your cookies have cached!");
		return Plugin_Handled;
	}

	decl String:sArg[32];
	GetCmdArgString(sArg, sizeof(sArg));
	ReplaceString(sArg, sizeof(sArg), "#", "", false);

	if(!IsValidHex(sArg))
	{
		ReplyToCommand(client, "[TCT] Usage: sm_chatcolor <hex>");
		return Plugin_Handled;
	}

	CPrintToChat(client, "\x01[TCT] Your chat color is now set to: \x07%s%s", sArg, sArg);
	strcopy(g_sChatColor[client], sizeof(g_sChatColor[]), sArg);
	SetClientCookie(client, g_hCookieChatColor, sArg);
	SetSetting(client);

	return Plugin_Handled;
}

public Action:Command_CheckTag(client, iArgs)
{
	if(!IsValidClient(client))
		return Plugin_Continue;
	
	if(iArgs != 1)
	{
		ReplyToCommand(client, "[TCT] Usage: sm_checktag <name>");
		return Plugin_Handled;
	}
	
	decl String:sTargetArg[MAX_NAME_LENGTH];
	GetCmdArg(1,sTargetArg,sizeof(sTargetArg));
	
	if(SearchForPlayer(sTargetArg) == 0)
	{
		ReplyToCommand(client, "[TCT] No valid clients found!");
		return Plugin_Handled;
	}
	else if(SearchForPlayer(sTargetArg) > 1)
	{
		ReplyToCommand(client, "[TCT] More than one matching player found!");
		return Plugin_Handled;
	}
	
	new target = FindTarget(client, sTargetArg, true);
	
	if(!IsValidClient(target))
	{
		ReplyToCommand(client, "Invalid target!");
		return Plugin_Handled;
	}
	
	if(IsFakeClient(target))
	{
		ReplyToCommand(client, "[TCT] Cannot target bots!");
		return Plugin_Handled;
	}
	
	GetPlayerSetup(client,target);
	
	PrintToChat(client, "[TCT] Check console for output!");

	return Plugin_Handled;
}

GetPlayerSetup(client,target)
{
	PrintToConsole(client, "-------------------------- PLAYER TAG INFO --------------------------");
	decl String:sHiddenTag[10], String:sRestricted[24];
	if(g_iTagHidden[target])
	{
		sHiddenTag = "Hidden";
	}
	else
	{
		sHiddenTag = "Visible";
	}
	if(g_iIsRestricted[target])
	{
		sRestricted = "Restricted";
	}
	else
	{
		sRestricted = "Not Restricted";
	}
	
	PrintToConsole(client, "Player: \"%s\", STEAM ID: \"%s\", Status: \"%s\", Setup: %i", g_sName[target], g_sSteamID[target], sRestricted, g_iTagSetting[client]);
	PrintToConsole(client, "Tag status: \"%s\", Tag Color: \"%s\", Name Color: \"%s\", Chat Color: \"%s\", Tag: \"%s\"", sHiddenTag, g_sTagColor[target], g_sNameColor[target], g_sChatColor[target], g_sTag[target]);
}

SearchForPlayer(const String:targetstring[])
{
	new String:sName[MAX_NAME_LENGTH];
	new iNumberFound = 0;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			GetClientName(i, sName, sizeof(sName));
			
			if(StrContains(sName, targetstring, false) != -1)
			{
				iNumberFound++;
			}
		}
	}
	return iNumberFound;
}

///////////////////////////////////////////////////////////////////
///////////////////////////// Cookies /////////////////////////////
///////////////////////////////////////////////////////////////////

public OnClientCookiesCached(client)
{
	if(IsValidClient(client) && !g_iIsLoaded[client])
	{
		PrintToChat(client, "Your cookies are now cached. TOGs Chat Tags applied!");
		LoadClientData(client);
	}
}

LoadClientData(client)
{
	decl String:sBuffer[20] = "";
	
	GetClientAuthString(client, g_sSteamID[client], sizeof(g_sSteamID[]));
	
	//tag hidden cookie
	GetClientCookie(client, g_hCookieTagHidden, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, "", false))	//if cookie contents are blank
	{
		g_iTagHidden[client] = 1;
	}
	else
	{
		g_iTagHidden[client] = StringToInt(sBuffer);
	}
	
	sBuffer = "";	//reset sBuffer to blank for next cookie
	
	//restricted cookie
	GetClientCookie(client, g_hCookieIsRestricted, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, "", false))	//if cookie contents are blank
	{
		g_iIsRestricted[client] = 0;
	}
	else
	{
		g_iIsRestricted[client] = StringToInt(sBuffer);
	}
	
	sBuffer = "";	//reset sBuffer to blank for next cookie
	
	//tag text cookie
	GetClientCookie(client, g_hCookieTag, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, "", false))	//if cookie contents are blank
	{
		strcopy(g_sTag[client], sizeof(g_sTag[]), sBuffer);	//since sBuffer is blank, we can still copy it for a blank tag
	}
	else
	{
		strcopy(g_sTag[client], sizeof(g_sTag[]), sBuffer);
	}
	
	sBuffer = "";	//reset sBuffer to blank for next cookie
	
	//tag color cookie
	GetClientCookie(client, g_hCookieTagColor, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, "", false))	//if cookie contents are blank
	{
		strcopy(g_sTagColor[client], sizeof(g_sTagColor[]), sBuffer);
	}
	else
	{
		strcopy(g_sTagColor[client], sizeof(g_sTagColor[]), sBuffer);
	}
	
	sBuffer = "";	//reset sBuffer to blank for next cookie
	
	//name color cookie
	GetClientCookie(client, g_hCookieNameColor, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, "", false))	//if cookie contents are blank
	{
		strcopy(g_sNameColor[client], sizeof(g_sNameColor[]), sBuffer);
	}
	else
	{
		strcopy(g_sNameColor[client], sizeof(g_sNameColor[]), sBuffer);
	}
	
	sBuffer = "";	//reset sBuffer to blank for next cookie
	
	//chat color cookie
	GetClientCookie(client, g_hCookieChatColor, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, "", false))	//if cookie contents are blank
	{
		strcopy(g_sChatColor[client], sizeof(g_sChatColor[]), sBuffer);
	}
	else	//if blank cookie
	{
		strcopy(g_sChatColor[client], sizeof(g_sChatColor[]), sBuffer);
	}

	g_iIsLoaded[client] = 1;
	
	SetSetting(client);
}

//////////////////////////////////////////////////////////////////
///////////////////////////// Setups /////////////////////////////
//////////////////////////////////////////////////////////////////

SetSetting(client)
{
	if(((g_iTagHidden[client] || StrEqual(g_sTag[client], "", false)) && StrEqual(g_sNameColor[client], "", false) && StrEqual(g_sChatColor[client], "", false)) || !HasFlags(g_sAccessFlag, client) || !g_iIsLoaded[client] || g_iIsRestricted[client] || g_iTagHidden[client])
	{
		g_iTagSetting[client] = 0;
	}
	else if(StrEqual(g_sTag[client], "", false) && StrEqual(g_sNameColor[client], "", false) && !StrEqual(g_sChatColor[client], "", false))
	{
		g_iTagSetting[client] = 1;
	}
	else if(StrEqual(g_sTag[client], "", false) && !StrEqual(g_sNameColor[client], "", false) && StrEqual(g_sChatColor[client], "", false))
	{
		g_iTagSetting[client] = 2;
	}
	else if(StrEqual(g_sTag[client], "", false) && !StrEqual(g_sNameColor[client], "", false) && !StrEqual(g_sChatColor[client], "", false))
	{
		g_iTagSetting[client] = 3;
	}
	else if((!g_iTagHidden[client] && !StrEqual(g_sTag[client], "", false)) && StrEqual(g_sTagColor[client], "", false) && StrEqual(g_sNameColor[client], "", false) && StrEqual(g_sChatColor[client], "", false))
	{
		g_iTagSetting[client] = 4;
	}
	else if((!g_iTagHidden[client] && !StrEqual(g_sTag[client], "", false)) && StrEqual(g_sTagColor[client], "", false) && StrEqual(g_sNameColor[client], "", false) && !StrEqual(g_sChatColor[client], "", false))
	{
		g_iTagSetting[client] = 5;
	}
	else if((!g_iTagHidden[client] && !StrEqual(g_sTag[client], "", false)) && StrEqual(g_sTagColor[client], "", false) && !StrEqual(g_sNameColor[client], "", false) && StrEqual(g_sChatColor[client], "", false))
	{
		g_iTagSetting[client] = 6;
	}
	else if((!g_iTagHidden[client] && !StrEqual(g_sTag[client], "", false)) && StrEqual(g_sTagColor[client], "", false) && !StrEqual(g_sNameColor[client], "", false) && !StrEqual(g_sChatColor[client], "", false))
	{
		g_iTagSetting[client] = 7;
	}
	else if((!g_iTagHidden[client] && !StrEqual(g_sTag[client], "", false)) && !StrEqual(g_sTagColor[client], "", false) && StrEqual(g_sNameColor[client], "", false) && StrEqual(g_sChatColor[client], "", false))
	{
		g_iTagSetting[client] = 8;
	}
	else if((!g_iTagHidden[client] && !StrEqual(g_sTag[client], "", false)) && !StrEqual(g_sTagColor[client], "", false) && StrEqual(g_sNameColor[client], "", false) && !StrEqual(g_sChatColor[client], "", false))
	{
		g_iTagSetting[client] = 9;
	}
	else if((!g_iTagHidden[client] && !StrEqual(g_sTag[client], "", false)) && !StrEqual(g_sTagColor[client], "", false) && !StrEqual(g_sNameColor[client], "", false) && StrEqual(g_sChatColor[client], "", false))
	{
		g_iTagSetting[client] = 10;
	}
	else if((!g_iTagHidden[client] && !StrEqual(g_sTag[client], "", false)) && !StrEqual(g_sTagColor[client], "", false) && !StrEqual(g_sNameColor[client], "", false) && !StrEqual(g_sChatColor[client], "", false))
	{
		g_iTagSetting[client] = 11;
	}
}

stock bool:IsValidClient(client)
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsFakeClient(client) )
	{
		return false;
	}
	return true;
}

stock bool:IsValidHex(const String:strHex[])
{
	if(strlen(strHex) == 6 && MatchRegex(g_hRegexHex, strHex))
		return true;
	return false;
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_iEnabled = StringToInt(newvalue);
	}
	else if(cvar == g_hAccessFlag)
	{
		GetConVarString(g_hAccessFlag, g_sAccessFlag, sizeof(g_sAccessFlag));
	}
	else if(cvar == g_hAdminFlag)
	{
		GetConVarString(g_hAdminFlag, g_sAdminFlag, sizeof(g_sAdminFlag));
	}
	else if(cvar == g_hAdminUnloadFlag)
	{
		GetConVarString(g_hAdminUnloadFlag, g_sAdminUnloadFlag, sizeof(g_sAdminUnloadFlag));
	}
	else if(cvar == g_hAdminSeeAllFlag)
	{
		GetConVarString(g_hAdminSeeAllFlag, g_sAdminSeeAllFlag, sizeof(g_sAdminSeeAllFlag));
	}
	else if(cvar == g_hAdminSeeAll)
	{
		g_iAdminSeeAll = StringToInt(newvalue);
	}
	else if(cvar == g_hConvertTriggerCases)
	{
		g_iConvertTriggerCases = StringToInt(newvalue);
	}
	else if(cvar == g_hLog)
	{
		g_iLog = StringToInt(newvalue);
	}
	else if(cvar == g_hSpamDuration)
	{
		g_fSpamDuration = StringToFloat(newvalue);
	}
}

/////////////////////////////////////////////////////////////////////////////
///////////////////////////// Client Prefs Menu /////////////////////////////
/////////////////////////////////////////////////////////////////////////////

public Menu_ClientPrefs(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		if(g_iIsRestricted[client])
		{
			PrintToChat(client, "[TCT] You are currently restricted from changing your tags!");
			return;
		}
		else
		{
			Menu_MainTag(client);
		}
	}
}

Menu_MainTag(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "TOGs Chat Tags");

	if(g_iEnabled && HasFlags(g_sAccessFlag, client))
		if(!g_iTagHidden[client])
		{
			DrawPanelItem(panel, "Disable Tag");
		}
		else
		{
			DrawPanelItem(panel, "Enable Tag");
		}
	else
		DrawPanelItem(panel, "Enable Tag", ITEMDRAW_DISABLED);
		
	if(g_iEnabled && HasFlags(g_sAccessFlag, client))
		DrawPanelItem(panel, "Tag Colors");
	else
		DrawPanelItem(panel, "Tag Colors", ITEMDRAW_DISABLED);

	//name colors menu
	if(g_iEnabled && HasFlags(g_sAccessFlag, client))
		DrawPanelItem(panel, "Name Colors");
	else
		DrawPanelItem(panel, "Name Colors", ITEMDRAW_DISABLED);

	//chat colors menu
	if(g_iEnabled && HasFlags(g_sAccessFlag, client))
		DrawPanelItem(panel, "Chat Colors");
	else
		DrawPanelItem(panel, "Chat Colors", ITEMDRAW_DISABLED);
		
	DrawPanelItem(panel, "Check Setup of Player");
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);
	DrawPanelItem(panel, "------------------------", ITEMDRAW_RAWLINE);
	DrawPanelItem(panel, "Chat command to change tag:", ITEMDRAW_RAWLINE);
	DrawPanelItem(panel, "!settag Text You Want", ITEMDRAW_RAWLINE);
	DrawPanelItem(panel, "(20 Characters Max)", ITEMDRAW_RAWLINE);
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);
	DrawPanelItem(panel, "Back", ITEMDRAW_CONTROL);
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);
	DrawPanelItem(panel, "Exit", ITEMDRAW_CONTROL);
	
	SendPanelToClient(panel, client, PanelHandler_MenuMainTag, MENU_TIME_FOREVER);
 
	CloseHandle(panel);
		
	return 2;
}

public PanelHandler_MenuMainTag(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			EmitSoundToClient(param1, "buttons/combine_button7.wav");
			CloseHandle(menu);
		}
		case MenuAction_Cancel: 
		{
			if(param2 == MenuCancel_ExitBack)
				ShowCookieMenu(param1);
		}
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 1:
				{
					if(HasFlags(g_sAccessFlag, param1))
					{
						EmitSoundToClient(param1, "buttons/button14.wav");
						if(g_iTagHidden[param1])
						{
							g_iTagHidden[param1] = 0;
							SetClientCookie(param1, g_hCookieTagHidden, "0");
							SetSetting(param1);
							PrintToChat(param1, "[TCT] Your tag is now enabled!");
						}
						else
						{
							g_iTagHidden[param1] = 1;
							SetClientCookie(param1, g_hCookieTagHidden, "1");
							SetSetting(param1);
							PrintToChat(param1, "[TCT] Your tag is now disabled!");
						}
						Menu_MainTag(param1);
					}
					else
					{
						EmitSoundToClient(param1, "buttons/button14.wav");
						PrintToChat(param1, "[TCT] You do not have access to this feature!");
						Menu_MainTag(param1);
					}
				}
				case 2:
				{
					if(HasFlags(g_sAccessFlag, param1))
					{
						EmitSoundToClient(param1, "buttons/button14.wav");
						Menu_TagColor(param1);
					}
					else
					{
						EmitSoundToClient(param1, "buttons/button14.wav");
						PrintToChat(param1, "[TCT] You do not have access to this feature!");
						Menu_MainTag(param1);
					}
				}
				case 3:
				{
					if(HasFlags(g_sAccessFlag, param1))
					{
						EmitSoundToClient(param1, "buttons/button14.wav");
						Menu_NameColor(param1);
					}
					else
					{
						EmitSoundToClient(param1, "buttons/button14.wav");
						PrintToChat(param1, "[TCT] You do not have access to this feature!");
						Menu_MainTag(param1);
					}
				}
				case 4:
				{
					if(HasFlags(g_sAccessFlag, param1))
					{
						EmitSoundToClient(param1, "buttons/button14.wav");
						Menu_ChatColor(param1);
					}
					else
					{
						EmitSoundToClient(param1, "buttons/button14.wav");
						PrintToChat(param1, "[TCT] You do not have access to this feature!");
						Menu_MainTag(param1);
					}
				}
				case 5:
				{
					EmitSoundToClient(param1, "buttons/button14.wav");
					Menu_CheckTag(param1);
				}
				case 8:
				{
					EmitSoundToClient(param1, "buttons/button14.wav");
					ShowCookieMenu(param1);
				}
				case 10:
				{
					EmitSoundToClient(param1, "buttons/combine_button7.wav");
				}
			}
		}
	}
	
	return;
}

Menu_CheckTag(client)
{
	new Handle:hMenu = CreateMenu(CheckTag_PlayerSelectMenuHandler);
	SetGlobalTransTarget(client);
	decl String:text[128];
	Format(text, 128, "Check Tag Setup for:", client);
	SetMenuTitle(hMenu, text);
	SetMenuExitBackButton(hMenu, true);
	
	AddTargetsToMenu(hMenu, client, true, false);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public CheckTag_PlayerSelectMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
		return;
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_MainTag(client);
		return;
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);

		if (target == 0) PrintToChat(client, "[TCT] %t", "Player no longer available");
		else
		{
			decl String:sName[MAX_NAME_LENGTH];
			GetClientName(target, sName, sizeof(sName));
			FakeClientCommand(client, "sm_checktag \"%s\"", sName);
		}
	}
}

public Menu_TagColor(client)
{
	if(g_iIsRestricted[client])
	{
		PrintToChat(client, "[TCT] You are currently restricted from changing your tags!");
		return;
	}
	
	new Handle:hMenu = CreateMenu(MenuHandler_TagColor);
	SetMenuTitle(hMenu, "Tag Color");
	SetMenuExitBackButton(hMenu, true);

	AddMenuItem(hMenu, "Reset", "Reset");
	AddMenuItem(hMenu, "SetManually", "Define Your Own Color");

	decl String:sColorIndex[4];
	for(new i = 0; i < g_iColorCount; i++)
	{
		IntToString(i, sColorIndex, sizeof(sColorIndex));
		AddMenuItem(hMenu, sColorIndex, g_sColorName[i]);
	}

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_TagColor(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
	{
		Menu_MainTag(iParam1);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		decl String:sBuffer[32];
		GetMenuItem(hMenu, iParam2, sBuffer, sizeof(sBuffer));

		if(StrEqual(sBuffer, "Reset"))
		{
			PrintToChat(iParam1, "[TCT] Your tag color is now reset to default.");
			g_sTagColor[iParam1] = "";
			SetClientCookie(iParam1, g_hCookieTagColor, "");
			SetSetting(iParam1);
		}
		else if(StrEqual(sBuffer, "SetManually"))
		{
			PrintToChat(iParam1, "[TCT] To define your own tag color, type !tagcolor <hexcode> (e.g. !tagcolor FFFFFF).");
		}
		else
		{
			new iColorIndex = StringToInt(sBuffer);
			CPrintToChat(iParam1, "\x01[TCT] Your tag color is now set to: \x07%s%s", g_sColorHex[iColorIndex], g_sColorName[iColorIndex]);
			strcopy(g_sTagColor[iParam1], sizeof(g_sTagColor[]), g_sColorHex[iColorIndex]);
			SetClientCookie(iParam1, g_hCookieTagColor, g_sColorHex[iColorIndex]);
			SetSetting(iParam1);
		}

		Menu_MainTag(iParam1);
	}
}

public Menu_NameColor(client)
{
	if(g_iIsRestricted[client])
	{
		PrintToChat(client, "[TCT] You are currently restricted from changing your tags!");
		return;
	}
		
	new Handle:hMenu = CreateMenu(MenuHandler_NameColor);
	SetMenuTitle(hMenu, "Name Color");
	SetMenuExitBackButton(hMenu, true);

	AddMenuItem(hMenu, "Reset", "Reset");
	AddMenuItem(hMenu, "SetManually", "Define Your Own Color");

	decl String:sColorIndex[4];
	for(new i = 0; i < g_iColorCount; i++)
	{
		IntToString(i, sColorIndex, sizeof(sColorIndex));
		AddMenuItem(hMenu, sColorIndex, g_sColorName[i]);
	}

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_NameColor(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
	{
		Menu_MainTag(iParam1);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		decl String:sBuffer[32];
		GetMenuItem(hMenu, iParam2, sBuffer, sizeof(sBuffer));

		if(StrEqual(sBuffer, "Reset"))
		{
			PrintToChat(iParam1, "[TCT] Your name color has been reset to default!");
			strcopy(g_sNameColor[iParam1], sizeof(g_sNameColor[]), "");
			SetClientCookie(iParam1, g_hCookieNameColor, "");
			SetSetting(iParam1);
		}
		else if(StrEqual(sBuffer, "SetManually"))
		{
			PrintToChat(iParam1, "[TCT] To define your own name color, type !namecolor <hexcode> (e.g. !namecolor FFFFFF).");
		}
		else
		{
			new iColorIndex = StringToInt(sBuffer);
			CPrintToChat(iParam1, "\x01[TCT] Your name color is now set to: \x07%s%s", g_sColorHex[iColorIndex], g_sColorName[iColorIndex]);
			strcopy(g_sNameColor[iParam1], sizeof(g_sNameColor[]), g_sColorHex[iColorIndex]);
			SetClientCookie(iParam1, g_hCookieNameColor, g_sColorHex[iColorIndex]);
			SetSetting(iParam1);
		}

		Menu_MainTag(iParam1);
	}
}

public Menu_ChatColor(client)
{
	if(g_iIsRestricted[client])
	{
		PrintToChat(client, "[TCT] You are currently restricted from changing your tags!");
		return;
	}
	
	new Handle:hMenu = CreateMenu(MenuHandler_ChatColor);
	SetMenuTitle(hMenu, "Chat Color");
	SetMenuExitBackButton(hMenu, true);

	AddMenuItem(hMenu, "Reset", "Reset");
	AddMenuItem(hMenu, "SetManually", "Define Your Own Color");

	decl String:sColorIndex[4];
	for(new i = 0; i < g_iColorCount; i++)
	{
		IntToString(i, sColorIndex, sizeof(sColorIndex));
		AddMenuItem(hMenu, sColorIndex, g_sColorName[i]);
	}

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_ChatColor(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
	{
		Menu_MainTag(iParam1);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		decl String:sBuffer[32];
		GetMenuItem(hMenu, iParam2, sBuffer, sizeof(sBuffer));

		if(StrEqual(sBuffer, "Reset"))
		{
			PrintToChat(iParam1, "[TCT] Your chat color has been reset to default.");
			strcopy(g_sChatColor[iParam1], sizeof(g_sChatColor[]), "");
			SetClientCookie(iParam1, g_hCookieChatColor, "");
			SetSetting(iParam1);
		}
		else if(StrEqual(sBuffer, "SetManually"))
		{
			PrintToChat(iParam1, "[TCT] To define your own chat color, type !chatcolor <hexcode> (e.g. !chatcolor FFFFFF).");
		}
		else
		{
			new iColorIndex = StringToInt(sBuffer);
			CPrintToChat(iParam1, "\x01[TCT] Your chat color is now set to: \x07%s%s", g_sColorHex[iColorIndex], g_sColorName[iColorIndex]);
			strcopy(g_sChatColor[iParam1], sizeof(g_sChatColor[]), g_sColorHex[iColorIndex]);
			SetClientCookie(iParam1, g_hCookieChatColor, g_sColorHex[iColorIndex]);
			SetSetting(iParam1);
		}

		Menu_MainTag(iParam1);
	}
}

//////////////////////////////////////////////////////////////////////
///////////////////////////// Admin Menu /////////////////////////////
//////////////////////////////////////////////////////////////////////

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;

	new TopMenuObject:MenuObject = AddToTopMenu(hTopMenu, "togschattags", TopMenuObject_Category, Handle_Commands, INVALID_TOPMENUOBJECT);
	if(MenuObject == INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	AddToTopMenu(hTopMenu, "sm_reloadtags", TopMenuObject_Item, AdminMenu_Command, MenuObject, "sm_reloadtags", ReadFlagString(g_sAdminFlag));
	AddToTopMenu(hTopMenu, "sm_restricttag", TopMenuObject_Item, AdminMenu_PlayerCommand, MenuObject, "sm_restricttag", ReadFlagString(g_sAdminFlag));
	AddToTopMenu(hTopMenu, "sm_unrestricttag", TopMenuObject_Item, AdminMenu_PlayerCommand2, MenuObject, "sm_unrestricttag", ReadFlagString(g_sAdminFlag));
	AddToTopMenu(hTopMenu, "sm_removetag", TopMenuObject_Item, AdminMenu_PlayerCommand3, MenuObject, "sm_removetag", ReadFlagString(g_sAdminFlag));
	AddToTopMenu(hTopMenu, "sm_unloadtags", TopMenuObject_Item, AdminMenu_Unload, MenuObject, "sm_unloadtags", ReadFlagString(g_sAdminUnloadFlag));
}

public Handle_Commands(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "TOGs Chat Tags");
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "TOGs Chat Tags");
	}
}

public AdminMenu_Unload(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Unload plugin until map change");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		PrintToChat(param, "[TCT] TOGs Chat Tags is now unloaded until map change!");
		
		ServerCommand("sm plugins unload togschattags.smx"); 
	}
}

public AdminMenu_Command(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Reload Chat Tag Colors");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Reload();
	
		PrintToChat(param, "[TCT] Colors setups are now reloaded.");
		RedisplayAdminMenu(topmenu, param);
	}
}

public AdminMenu_PlayerCommand(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Restrict Tags");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		PlayerSelectMenu(param);
	}
}

public AdminMenu_PlayerCommand2(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Unrestrict Tags");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		PlayerSelectMenu2(param);
	}
}

public AdminMenu_PlayerCommand3(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Remove Tags");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		PlayerSelectMenu3(param);
	}
}

PlayerSelectMenu(client)
{
	new Handle:smMenu = CreateMenu(PlayerSelectMenuHandler);
	SetGlobalTransTarget(client);
	decl String:text[128];
	Format(text, 128, "Restrict tags for:");
	SetMenuTitle(smMenu, text);
	SetMenuExitBackButton(smMenu, true);
	
	AddTargetsToMenu(smMenu, client, true, false);
	
	DisplayMenu(smMenu, client, MENU_TIME_FOREVER);
}

PlayerSelectMenu2(client)
{
	new Handle:smMenu = CreateMenu(PlayerSelectMenuHandler2);
	SetGlobalTransTarget(client);
	decl String:text[128];
	Format(text, 128, "Unrestrict tags for:");
	SetMenuTitle(smMenu, text);
	SetMenuExitBackButton(smMenu, true);
	
	AddTargetsToMenu(smMenu, client, true, false);
	
	DisplayMenu(smMenu, client, MENU_TIME_FOREVER);
}

PlayerSelectMenu3(client)
{
	new Handle:smMenu = CreateMenu(PlayerSelectMenuHandler3);
	SetGlobalTransTarget(client);
	decl String:text[128];
	Format(text, 128, "Remove tags for:");
	SetMenuTitle(smMenu, text);
	SetMenuExitBackButton(smMenu, true);
	
	AddTargetsToMenu(smMenu, client, true, false);
	
	DisplayMenu(smMenu, client, MENU_TIME_FOREVER);
}

public PlayerSelectMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);

		if (target == 0) PrintToChat(client, "[TCT] %t", "Player no longer available");
		else
		{
			if(g_iIsRestricted[target])
			{
				PrintToChat(client, "[TCT] Player is already restricted!");
			}
			else
			{
				decl String:sName[MAX_NAME_LENGTH];
				GetClientName(target, sName, sizeof(sName));
				FakeClientCommand(client, "sm_restricttag \"%s\"", sName);
			}
		}
	}
}

public PlayerSelectMenuHandler2(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);

		if (target == 0) PrintToChat(client, "[TCT] %t", "Player no longer available");
		else
		{
			if(g_iIsRestricted[target])
			{
				decl String:sName[MAX_NAME_LENGTH];
				GetClientName(target, sName, sizeof(sName));
				FakeClientCommand(client, "sm_unrestricttag \"%s\"", sName);
			}
			else
			{
				PrintToChat(client, "[TCT] Player is not set to restricted!");
			}
		}
	}
}

public PlayerSelectMenuHandler3(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);

		if (target == 0) PrintToChat(client, "[TCT] %t", "Player no longer available");
		else
		{
			decl String:sName[MAX_NAME_LENGTH];
			GetClientName(target, sName, sizeof(sName));
			FakeClientCommand(client, "sm_removetag \"%s\"", sName);
		}
	}
}