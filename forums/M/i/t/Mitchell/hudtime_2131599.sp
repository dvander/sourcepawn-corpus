#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <clientprefs>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.0.0"
#define MAXTIMEZONES 32

// ====[ HANDLES | CVARS ]=====================================================
new Handle:cvarEnabled;
new Handle:cvarPhrase;
new Handle:cvarXPos;
new Handle:cvarYPos;
new Handle:cvarEffect;
new Handle:cvarRed;
new Handle:cvarGreen;
new Handle:cvarBlue;
new Handle:cvarAlpha;

new Handle:g_hHud;

// ====[ VARIABLES ]===========================================================
new bool:g_bEnabled;
new g_iRed;
new g_iGreen;
new g_iBlue;
new g_iAlpha;
new g_iEffect;
new Float:g_fXPos;
new Float:g_fYPos;
new String:g_strPhase[255];

new Handle:g_hClientTime = INVALID_HANDLE;
new Handle:g_hClientShow = INVALID_HANDLE;
new g_iClientTimeZone[MAXPLAYERS+1];
new bool:g_bClientShow[MAXPLAYERS+1] = {false,...};

new tzCount = 0;
new TimeSettings[MAXTIMEZONES+1];
new String:TimeZoneString[MAXTIMEZONES+1][5];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Server Hud Time/Date",
	author = "ReFlexPoison, Mitch",
	description = "Add date and time for everyone to see",
	version = PLUGIN_VERSION,
	url = "SnBx.info"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	g_hClientTime = RegClientCookie("HudTimeZone", "TimeZone Cookie!", CookieAccess_Private);
	g_hClientShow = RegClientCookie("HudShowTime", "TimeZone Cookie!", CookieAccess_Private);
	for (new i = MaxClients; i > 0; --i)
    {
		if (!AreClientCookiesCached(i))
			continue;
		OnClientCookiesCached(i);
    }

	CreateConVar("sm_hudtime_version", PLUGIN_VERSION, "Version of Server Hud Logo", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_hudtime_enabled", "1", "Enable Server Hud Logo\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(cvarEnabled);

	cvarPhrase = CreateConVar("sm_hudtime_format", "[%D][%I:%M%p &TIMEZONE&]", "Time Format", FCVAR_PLUGIN);
	GetConVarString(cvarPhrase, g_strPhase, sizeof(g_strPhase));

	cvarXPos = CreateConVar("sm_hudtime_xvalue", "0.0", "X logo position\n-1 = Center", FCVAR_PLUGIN, true, -1.0, true, 1.0);
	g_fXPos = GetConVarFloat(cvarXPos);
	if(g_fXPos != -1.0 && g_fXPos < 0.0)
	{
		g_fXPos = 0.0;
		SetConVarFloat(cvarXPos, 0.0);
		PrintToServer("Invalid convar value for convar 'sm_hudtime_xvalue' (Set to default)");
	}

	cvarYPos = CreateConVar("sm_hudtime_yvalue", "0.0", "Y logo position\n-1 = Center", FCVAR_PLUGIN, true, -1.0, true, 1.0);
	g_fYPos = GetConVarFloat(cvarYPos);
	if(g_fYPos != -1.0 && g_fYPos < 0.0)
	{
		g_fYPos = 0.0;
		SetConVarFloat(cvarYPos, 0.0);
		PrintToServer("Invalid convar value for convar 'sm_hudtime_yvalue' (Set to default)");
	}

	cvarEffect = CreateConVar("sm_hudtime_effect", "0", "Logo effect\n0 = Fade In\n1 = Fade In/Out \n2 = Type", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_iEffect = GetConVarInt(cvarEffect);

	cvarRed = CreateConVar("sm_hudtime_red", "255", "Red logo color value", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_iRed = GetConVarInt(cvarRed);

	cvarGreen = CreateConVar("sm_hudtime_green", "255", "Green logo color value", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_iGreen = GetConVarInt(cvarGreen);

	cvarBlue = CreateConVar("sm_hudtime_blue", "255", "Blue logo color value", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_iBlue = GetConVarInt(cvarBlue);

	cvarAlpha = CreateConVar("sm_hudtime_alpha", "255", "Alpha transparency value", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_iAlpha = GetConVarInt(cvarAlpha);

	HookConVarChange(cvarEnabled, CVarChange);
	HookConVarChange(cvarPhrase, CVarChange);
	HookConVarChange(cvarXPos, CVarChange);
	HookConVarChange(cvarYPos, CVarChange);
	HookConVarChange(cvarEffect, CVarChange);
	HookConVarChange(cvarRed, CVarChange);
	HookConVarChange(cvarGreen, CVarChange);
	HookConVarChange(cvarBlue, CVarChange);
	HookConVarChange(cvarAlpha, CVarChange);

	AutoExecConfig(true);

	g_hHud = CreateHudSynchronizer();
	if(g_hHud == INVALID_HANDLE)
		SetFailState("HUD synchronisation is not supported by this mod");
		
	RegConsoleCmd("sm_time", Command_Time);
}

public Action:Command_Time(client, args)
{
	if (client)
	{
		Void_MenuTimeMain(client);
	}
	return Plugin_Handled;
}

public OnClientCookiesCached(client)
{
	decl String:sValue[8];
	GetClientCookie(client, g_hClientTime, sValue, sizeof(sValue));
	if(sValue[0] != '\0')
		g_iClientTimeZone[client] = StringToInt(sValue);
	else
		g_iClientTimeZone[client] = 0;
	GetClientCookie(client, g_hClientShow, sValue, sizeof(sValue));
	g_bClientShow[client] = (sValue[0] != '\0' && StringToInt(sValue));
}

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == cvarEnabled)
		g_bEnabled = GetConVarBool(cvarEnabled);
	if(hConvar == cvarPhrase)
		GetConVarString(cvarPhrase, g_strPhase, sizeof(g_strPhase));
	if(hConvar == cvarXPos)
	{
		g_fXPos = GetConVarFloat(cvarXPos);
		if(g_fXPos != -1.0 && g_fXPos < 0.0)
		{
			g_fXPos = 0.18;
			SetConVarFloat(cvarXPos, 0.18);
			PrintToServer("Invalid convar value for convar 'sm_hudtime_xvalue' (Set to default)");
		}
	}
	if(hConvar == cvarYPos)
	{
		g_fYPos = GetConVarFloat(cvarYPos);
		if(g_fYPos != -1.0 && g_fYPos < 0.0)
		{
			g_fYPos = 0.9;
			SetConVarFloat(cvarYPos, 0.9);
			PrintToServer("Invalid convar value for convar 'sm_hudtime_yvalue' (Set to default)");
		}
	}
	if(hConvar == cvarEffect)
		g_iEffect = GetConVarInt(cvarEffect);
	if(hConvar == cvarRed)
		g_iRed = GetConVarInt(cvarRed);
	if(hConvar == cvarGreen)
		g_iGreen = GetConVarInt(cvarGreen);
	if(hConvar == cvarBlue)
		g_iBlue = GetConVarInt(cvarBlue);
	if(hConvar == cvarAlpha)
		g_iAlpha = GetConVarInt(cvarAlpha);
}

public OnMapStart()
{
	CreateTimer(1.0, Timer_Hud, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	LoadConfig();
}

Void_MenuTimeMain(client)
{
	if(!IsValidClient(client)) return;
	decl String:g_sDisplay[128];
	new Handle:menu = CreateMenu(Menu_TimeMain, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(menu, "Hud Date/Time Display");

	AddMenuItem(menu, "endis", g_bClientShow[client] ? "Enable Display" : "Disable Display");

	Format(g_sDisplay, sizeof(g_sDisplay), "Time Zones [%s]", TimeZoneString[g_iClientTimeZone[client]]);
	AddMenuItem(menu, "tz", g_sDisplay);

	SetMenuExitButton(menu, true);
	DisplayMenuAtItem(menu, client, 0, MENU_TIME_FOREVER);
}
public Menu_TimeMain(Handle:main, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(main);
		case MenuAction_Select:
		{
			new String:info[32];
			GetMenuItem(main, param2, info, sizeof(info));
			if(StrEqual(info, "tz"))
			{
				Void_MenuTimeZones(client);
				return;
			}
			else
			{
				g_bClientShow[client] = !g_bClientShow[client];
				SetClientCookie(client, g_hClientShow, g_bClientShow[client] ? "1" : "0");
				Void_MenuTimeMain(client);
			}
		}
	}
	return;
}

Void_MenuTimeZones(client)
{
	if(!IsValidClient(client)) return;
	decl String:g_sDisplay[128];
	decl String:g_sChoice[6];
	new Handle:menu = CreateMenu(Menu_TimeZones, MENU_ACTIONS_DEFAULT);
	Format(g_sDisplay, sizeof(g_sDisplay), "Hud TimeZone: %s", TimeZoneString[g_iClientTimeZone[client]]);
	SetMenuTitle(menu, g_sDisplay);
	for(new X = 0; X < tzCount; X++)
	{
		Format(g_sDisplay, sizeof(g_sDisplay), "%s", TimeZoneString[X]);
		Format(g_sChoice, sizeof(g_sChoice), "%i", X);
		AddMenuItem(menu, g_sChoice, g_sDisplay);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenuAtItem(menu, client, 0, MENU_TIME_FOREVER);
}

public Menu_TimeZones(Handle:main, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(main);
		case MenuAction_Cancel:
			Void_MenuTimeZones(client);
		case MenuAction_Select:
		{
			new String:info[32];
			GetMenuItem(main, param2, info, sizeof(info));
			g_iClientTimeZone[client] = StringToInt(info);
			SetClientCookie(client, g_hClientTime, info);
			Void_MenuTimeMain(client);
		}
	}
	return;
}
// ====[ TIMERS ]==============================================================
public Action:Timer_Hud(Handle:hTimer)
{
	if(!g_bEnabled)
		return Plugin_Continue;
	new String:FormattedTime[255];
	new curtime = GetTime();
	for(new iClient=1;iClient<=MaxClients;iClient++)
	{
		if(!IsValidClient(iClient) || g_bClientShow[iClient])
			return Plugin_Continue;
		curtime = GetTime() - TimeSettings[g_iClientTimeZone[iClient]];
		strcopy(FormattedTime, sizeof(FormattedTime), g_strPhase);
		ReplaceString(FormattedTime, sizeof(FormattedTime), "&TIMEZONE&", TimeZoneString[g_iClientTimeZone[iClient]]);
		FormatTime(FormattedTime, sizeof(FormattedTime), FormattedTime, curtime);
		SetHudTextParams(g_fXPos, g_fYPos, 1.0, g_iRed, g_iGreen, g_iBlue, g_iAlpha, g_iEffect);
		ShowSyncHudText(iClient, g_hHud, FormattedTime);
	}
	return Plugin_Continue;
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:replay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if(replay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
------LoadConfig		(type: Public Function)
	Loads the config from
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
public LoadConfig()
{
	new Handle:SMC = SMC_CreateParser(); 
	SMC_SetReaders(SMC, NewSection, KeyValue, EndSection); 
	decl String:sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/hudtime_config.txt");
	tzCount = 0;
	SMC_ParseFile(SMC, sPaths);
	CloseHandle(SMC);
}
public SMCResult:NewSection(Handle:smc, const String:name[], bool:opt_quotes) { }
public SMCResult:EndSection(Handle:smc) { }  
public SMCResult:KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes) 
{
	strcopy(TimeZoneString[tzCount], 5, key);
	TimeSettings[tzCount] = StringToInt(value);
	tzCount++;
}