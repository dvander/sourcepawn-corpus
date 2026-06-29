#pragma semicolon 1

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.0.3"

new Handle:g_cvVersion = INVALID_HANDLE;
new Handle:g_hCookie = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Set Client Language",
	author = "Leonardo",
	description = "...",
	version = PLUGIN_VERSION,
	url = "http://xpenia.pp.ru"
};

public OnPluginStart()
{
	if(GetExtensionFileStatus("clientprefs.ext")!=1 || !SQL_CheckConfig("clientprefs"))
		SetFailState("Clientprefs extension wasn't found!");
	
	LoadTranslations("common.phrases.txt");
	
	g_cvVersion = CreateConVar("sm_scl_version", PLUGIN_VERSION, "Set Client Language version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(g_cvVersion, PLUGIN_VERSION, true, true);
	HookConVarChange(g_cvVersion, OnConVarChanged_PluginVersion);
	
	RegAdminCmd("sm_scl_cookie", Command_CookieChanger, ADMFLAG_GENERIC);
	
	g_hCookie = RegClientCookie("client_language", "Force to change client language", CookieAccess_Private);
	SetCookieMenuItem(CookieMenu_TopMenu, 0, "Set Language");
	
	RegConsoleCmd("sm_setlanguage", Command_SetLang, "Show Language menu");
	RegConsoleCmd("sm_setlang", Command_SetLang, "Show Language menu");
	RegConsoleCmd("sm_lang", Command_SetLang, "Show Language menu");
	if(!FindConVar("sm_geolanguage_version"))
		RegConsoleCmd("sm_language", Command_SetLang, "Show Language menu");
	
	HookEvent("player_activate", OnPlayerActivate, EventHookMode_Post);
}

public OnMapStart()
	if(GuessSDKVersion()==SOURCE_SDK_EPISODE2VALVE)
		SetConVarString(g_cvVersion, PLUGIN_VERSION, true, true);

public OnPlayerActivate(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient<0 || iClient>MaxClients || !IsClientInGame(iClient))
		return;
	new String:sLangCode[4];
	GetClientCookie(iClient, g_hCookie, sLangCode, sizeof(sLangCode));
	if(strlen(sLangCode) && GetLanguageByCode(sLangCode)>=0)
		SetClientLanguage(iClient, GetLanguageByCode(sLangCode));
	else
	{
		GetLanguageInfo(GetClientLanguage(iClient), sLangCode, sizeof(sLangCode));
		SetClientCookie(iClient, g_hCookie, sLangCode);
	}
}

public Action:Command_CookieChanger(iClient, iArgs)
	if(iArgs<=0 || iArgs>2)
	{
		ReplyToCommand(iClient, "Usage: sm_scl_cookie <target> [value]");
		return Plugin_Handled;
	}
	else
	{
		new String:sTargets[128];
		new String:sLangCode[4];
		decl String:sTargetName[MAX_NAME_LENGTH];
		decl iTargets[MAXPLAYERS];
		decl iTargetsCount;
		decl bool:tn_is_ml;
		
		GetCmdArg(1, sTargets, sizeof(sTargets));
		GetCmdArg(2, sLangCode, sizeof(sLangCode));
		
		if( (iTargetsCount = ProcessTargetString(sTargets, 0, iTargets, MAXPLAYERS, COMMAND_FILTER_CONNECTED, sTargetName, sizeof(sTargetName), tn_is_ml)) <= 0 )
		{
			ReplyToTargetError(0, iTargetsCount);
			return Plugin_Handled;
		}
		
		for(new i=0; i<iTargetsCount; i++)
			if(iArgs==1)
			{
				GetClientCookie(iTargets[i], g_hCookie, sLangCode, sizeof(sLangCode));
				ReplyToCommand(iClient, "- (%i) %N: current language is '%s'", iTargets[i], iTargets[i], sLangCode);
			}
			else
			{
				if(GetLanguageByCode(sLangCode)<0)
				{
					ReplyToCommand(iClient, "Invalid language '%s'", sLangCode);
					return Plugin_Handled;
				}
				SetClientCookie(iTargets[i], g_hCookie, sLangCode);
				ReplyToCommand(iClient, "- (%i) %N: new language is '%s'", iTargets[i], iTargets[i], sLangCode);
			}
		
		return Plugin_Handled;
	}

public Action:Command_SetLang(iClient, iArgs)
	if (iClient>0 && iClient<=MaxClients && IsClientInGame(iClient))
	{
		SendCookieSettingsMenu(iClient, false);
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;

public CookieMenu_TopMenu(iClient, CookieMenuAction:iMenuAction, any:data, String:sBuffer[], iBufferSize)
	if(iMenuAction!=CookieMenuAction_DisplayOption)
		SendCookieSettingsMenu(iClient, true);

stock SendCookieSettingsMenu(iClient, bool:bExitBackButton=false)
{
	new iLanguages = GetLanguageCount();
	new String:sLangName[64], String:sLang[4], String:sCurLang[4], String:sBuffer[64];
	new Handle:hMenu = CreateMenu(Menu_CookieSettings);
	
	GetClientCookie(iClient, g_hCookie, sCurLang, sizeof(sCurLang));
	SetMenuTitle(hMenu, "Select language:");
	for(new iLang=0; iLang<iLanguages; iLang++)
	{
		GetLanguageInfo(iLang, sLang, sizeof(sLang), sLangName, sizeof(sLangName));
		//IntToString(iLang, sLang, sizeof(sLang));
		Format(sBuffer, sizeof(sBuffer), "%s%s (%s)", (StrEqual(sCurLang, sLang, false)?"* ":""), sLangName, sLang);
		AddMenuItem(hMenu, sLang, sBuffer);
	}
	SetMenuExitBackButton(hMenu, bExitBackButton);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public Menu_CookieSettings(Handle:hMenu, MenuAction:iMenuAction, iClient, iMenuItem)
	if(iMenuAction==MenuAction_Select) 
	{
		new String:sSelection[3];
		GetMenuItem(hMenu, iMenuItem, sSelection, sizeof(sSelection));
		SetClientCookie(iClient, g_hCookie, sSelection);
		SetClientLanguage(iClient, GetLanguageByCode(sSelection));
		SendCookieSettingsMenu(iClient, GetMenuExitBackButton(hMenu));
	}
	else if(iMenuAction==MenuAction_Cancel)
	{
		if(iMenuItem==MenuCancel_ExitBack)
			ShowCookieMenu(iClient);
	}
	else if(iMenuAction==MenuAction_End)
		CloseHandle(hMenu);

public OnConVarChanged_PluginVersion(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	if(!StrEqual(sNewValue, PLUGIN_VERSION, false))
		SetConVarString(hConVar, PLUGIN_VERSION, true, true);