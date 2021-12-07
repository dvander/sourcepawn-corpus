/************************************************************************
*************************************************************************
Bonus Round Immunity
Description:
	Gives admins immunity during the bonus round
*************************************************************************
*************************************************************************
This plugin is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or any later version.

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id: bonusroundimmunity.sp 8 2009-07-17 23:08:13Z antithasys $
$Author: antithasys $
$Revision: 8 $
$Date: 2009-07-17 17:08:13 -0600 (Fri, 17 Jul 2009) $
$LastChangedBy: antithasys $
$LastChangedDate: 2009-07-17 17:08:13 -0600 (Fri, 17 Jul 2009) $
$URL: http://projects.mygsn.net/svn/simple-plugins/trunk/bonusroundimmunity/addons/sourcemod/scripting/bonusroundimmunity.sp $
$Copyright: (c) Simple SourceMod Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/
 
#pragma semicolon 1
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <clientprefs>
#include <tf2_stocks>


#define PLUGIN_VERSION "1.2.$Revision: 8 $"
#define SPECTATOR 1
#define TEAM_RED 2
#define TEAM_BLUE 3

#define COLOR_GREEN 0
#define COLOR_BLACK 1
#define COLOR_RED 2
#define COLOR_BLUE 3
#define COLOR_TEAM 4
#define COLOR_RAINBOW 5
#define COLOR_NONE 6

enum e_Cookies
{
	bEnabled,
	iColor,
};

enum e_ColorNames
{
	Green,
	Black,
	Red,
	Blue
};

enum e_ColorValues
{
	iRed,
	iGreen,
	iBlue
};

new Handle:bri_charadminflag = INVALID_HANDLE;
new Handle:bri_enabled = INVALID_HANDLE;
new Handle:bri_cookie_enabled = INVALID_HANDLE;
new Handle:bri_cookie_color = INVALID_HANDLE;
new Handle:g_hPlayerColorTimer[MAXPLAYERS + 1];
new bool:g_bIsPlayerAdmin[MAXPLAYERS + 1];
new bool:g_bIsPlayerImmune[MAXPLAYERS + 1];
new bool:g_bIsEnabled = true;
new bool:g_bRoundEnd = false;
new String:g_sCharAdminFlag[32];
new g_iPlayerCycleColor[MAXPLAYERS + 1];
new g_aClientCookies[MAXPLAYERS + 1][e_Cookies];
new g_iColors[e_ColorNames][e_ColorValues];

public Plugin:myinfo =
{
	name = "Bonus Round Immunity",
	author = "Simple SourceMod Plugins",
	description = "Gives admins immunity during bonus round",
	version = PLUGIN_VERSION,
	url = "http://projects.mytf2.com"
}

public OnPluginStart()
{
	CreateConVar("brimmunity_version", PLUGIN_VERSION, "Bonus Round Immunity", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	bri_enabled = CreateConVar("bri_enabled", "1", "Enable/Disable Admin immunity during bonus round.");
	bri_charadminflag = CreateConVar("bri_charadminflag", "a", "Admin flag to use for immunity (only one).  Must be a in char format.");
	
	HookConVarChange(bri_enabled, EnabledChanged);
	
	HookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Post);
	HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
	
	RegAdminCmd("sm_immunity", Command_Immunity, ADMFLAG_ROOT, "sm_immunity: Gives you immunity");
	
	bri_cookie_enabled = RegClientCookie("bri_client_enabled", "Enable/Disable your immunity during the bonus round.", CookieAccess_Public);
	bri_cookie_color = RegClientCookie("bri_client_color", "Color to render when immune.", CookieAccess_Public);
	
	SetCookieMenuItem(CookieMenu_TopMenu, bri_cookie_enabled, "Bonus Round Immunity");
	
	LoadColors();
	
	AutoExecConfig(true, "plugin.bonusroundimmunity");
}

public OnAllPluginsLoaded()
{
	//something
}

public OnLibraryRemoved(const String:name[])
{
	//something
}

public OnConfigsExecuted()
{
	GetConVarString(bri_charadminflag, g_sCharAdminFlag, sizeof(g_sCharAdminFlag));
	g_bIsEnabled = GetConVarBool(bri_enabled);
	g_bRoundEnd = false;
}

public OnClientPostAdminCheck(client)
{
	if (IsValidAdmin(client, g_sCharAdminFlag))
		g_bIsPlayerAdmin[client] = true;
	else
		g_bIsPlayerAdmin[client] = false;
}

public OnClientCookiesCached(client)
{
	decl String:sEnabled[2], String:sColor[4];
	GetClientCookie(client, bri_cookie_enabled, sEnabled, sizeof(sEnabled));
	GetClientCookie(client, bri_cookie_color, sColor, sizeof(sColor));
	g_aClientCookies[client][bEnabled] = StringToInt(sEnabled);
	g_aClientCookies[client][iColor] = StringToInt(sColor);
}

public OnClientDisconnect(client)
{
	CleanUp(client);
}

public Action:Command_Immunity(client, args)
{
	if (g_bIsPlayerImmune[client])
	{
		DisableImmunity(client);
	}
	else
	{
		EnableImmunity(client);
	}
	return Plugin_Handled;
}

public HookRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundEnd = false;
	if (g_bIsEnabled) 
	{
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (g_bIsPlayerImmune[i]) 
			{
				DisableImmunity(i);
			}
		}
	}
}

public HookRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundEnd = true;
	if (g_bIsEnabled) 
	{
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (g_bIsPlayerAdmin[i]) 
			{
				EnableImmunity(i);
			}
		}
	}
}

public HookPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bIsEnabled && g_bIsPlayerAdmin[iClient] && g_bRoundEnd) 
	{
		EnableImmunity(iClient);
	}
}

public CookieMenu_TopMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		//don't think we need to do anything
	}
	else
	{
		new Handle:hMenu = CreateMenu(Menu_CookieSettings);
		SetMenuTitle(hMenu, "Options (Current Setting)");
		if (g_aClientCookies[client][bEnabled])
		{
			AddMenuItem(hMenu, "enable", "Enabled/Disable (Enabled)");
		}
		else
		{
			AddMenuItem(hMenu, "enable", "Enabled/Disable (Disabled)");
		}
		switch (g_aClientCookies[client][iColor])
		{
			case COLOR_GREEN:
			{
				AddMenuItem(hMenu, "color", "Color (Green)");
			}
			case COLOR_BLACK:
			{
				AddMenuItem(hMenu, "color", "Color (Black)");
			}
			case COLOR_RED:
			{
				AddMenuItem(hMenu, "color", "Color (Red)");
			}
			case COLOR_BLUE:
			{
				AddMenuItem(hMenu, "color", "Color (Blue)");
			}
			case COLOR_TEAM:
			{
				AddMenuItem(hMenu, "color", "Color (Team)");
			}
			case COLOR_RAINBOW:
			{
				AddMenuItem(hMenu, "color", "Color (Rainbow)");
			}
			case COLOR_NONE:
			{
				AddMenuItem(hMenu, "color", "Color (None)");
			}
		}
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}

public Menu_CookieSettings(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			new Handle:hMenu = CreateMenu(Menu_CookieSettingsEnable);
			SetMenuTitle(hMenu, "Enable/Disable Round End Immunity");
			
			if (g_aClientCookies[client][bEnabled])
			{
				AddMenuItem(hMenu, "enable", "Enable (Set)");
				AddMenuItem(hMenu, "disable", "Disable");
			}
			else
			{
				AddMenuItem(hMenu, "enable", "Enabled");
				AddMenuItem(hMenu, "disable", "Disable (Set)");
			}
			
			SetMenuExitBackButton(hMenu, true);
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
		}
		else
		{
			new Handle:hMenu = CreateMenu(Menu_CookieSettingsColors);
			SetMenuTitle(hMenu, "Select Immunity Color");
			switch (g_aClientCookies[client][iColor])
			{
				case COLOR_GREEN:
				{
					AddMenuItem(hMenu, "Green", "Green (Set)");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "None", "None");
				}
				case COLOR_BLACK:
				{
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Black", "Black (Set)");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "None", "None");
				}
				case COLOR_RED:
				{
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red (Set)");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "None", "None");
				}
				case COLOR_BLUE:
				{
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue (Set)");
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "None", "None");
				}
				case COLOR_TEAM:
				{
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Team", "Team Color (Set)");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "None", "None");
				}
				case COLOR_RAINBOW:
				{
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Rain", "Rainbow (Set)");
					AddMenuItem(hMenu, "None", "None");
				}
				case COLOR_NONE:
				{
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "None", "None (Set)");
				}
			}
			SetMenuExitBackButton(hMenu, true);
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_CookieSettingsEnable(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			SetClientCookie(client, bri_cookie_enabled, "1");
			g_aClientCookies[client][bEnabled] = 1;
			PrintToChat(client, "[SM] Bonus Round Immunity is ENABLED");
		}
		else
		{
			SetClientCookie(client, bri_cookie_enabled, "0");
			g_aClientCookies[client][bEnabled] = 0;
			PrintToChat(client, "[SM] Bonus Round Immunity is DISABLED");
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_CookieSettingsColors(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "Green", false))
		{
			SetClientCookie(client, bri_cookie_color, "0");
			g_aClientCookies[client][iColor] = COLOR_GREEN;
			PrintToChat(client, "[SM] Bonus Round Immunity color set to GREEN");
		}
		else if (StrEqual(sSelection, "Black", false))
		{
			SetClientCookie(client, bri_cookie_color, "1");
			g_aClientCookies[client][iColor] = COLOR_BLACK;
			PrintToChat(client, "[SM] Bonus Round Immunity color set to BLACK");
		}
		else if (StrEqual(sSelection, "Red", false))
		{
			SetClientCookie(client, bri_cookie_color, "2");
			g_aClientCookies[client][iColor] = COLOR_RED;
			PrintToChat(client, "[SM] Bonus Round Immunity color set to RED");
		}
		else if (StrEqual(sSelection, "Blue", false))
		{
			SetClientCookie(client, bri_cookie_color, "3");
			g_aClientCookies[client][iColor] = COLOR_BLUE;
			PrintToChat(client, "[SM] Bonus Round Immunity color set to BLUE");
		}
		else if (StrEqual(sSelection, "Team", false))
		{
			SetClientCookie(client, bri_cookie_color, "4");
			g_aClientCookies[client][iColor] = COLOR_TEAM;
			PrintToChat(client, "[SM] Bonus Round Immunity color set to TEAM COLOR");
		}
		else if (StrEqual(sSelection, "Rain", false))
		{
			SetClientCookie(client, bri_cookie_color, "5");
			g_aClientCookies[client][iColor] = COLOR_RAINBOW;
			PrintToChat(client, "[SM] Bonus Round Immunity color set to RAINBOW");
		}
		else if (StrEqual(sSelection, "None", false))
		{
			SetClientCookie(client, bri_cookie_color, "6");
			g_aClientCookies[client][iColor] = COLOR_NONE;
			PrintToChat(client, "[SM] Bonus Round Immunity color set to NONE");
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Timer_ChangeColor(Handle:timer, any:client)
{
	if (g_iPlayerCycleColor[client]++ == 3)
	{
		g_iPlayerCycleColor[client] = 0;
	}
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, g_iColors[g_iPlayerCycleColor[client]][iRed], g_iColors[g_iPlayerCycleColor[client]][iGreen], g_iColors[g_iPlayerCycleColor[client]][iBlue], 255);
	return Plugin_Continue;
}

stock CleanUp(iClient)
{
	g_bIsPlayerAdmin[iClient] = false;
	DisableImmunity(iClient);
}

stock EnableImmunity(iClient)
{
	SetEntityRenderMode(iClient, RENDER_TRANSCOLOR);
	switch (g_aClientCookies[iClient][iColor])
	{
		case COLOR_TEAM:
		{
			new iTeam = GetClientTeam(iClient);
			SetEntityRenderColor(iClient, g_iColors[e_ColorNames:iTeam][iRed], g_iColors[e_ColorNames:iTeam][iGreen], g_iColors[e_ColorNames:iTeam][iBlue], 255);
		}
		case COLOR_RAINBOW:
		{
			if (g_hPlayerColorTimer[iClient] != INVALID_HANDLE)
			{
				CloseHandle(g_hPlayerColorTimer[iClient]);
				g_hPlayerColorTimer[iClient] = INVALID_HANDLE;
			}
			g_hPlayerColorTimer[iClient] = CreateTimer(0.2, Timer_ChangeColor, iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		case COLOR_NONE:
		{
			//We dont have to set a color
		}
		default:
		{
			SetEntityRenderColor(iClient, g_iColors[e_ColorNames:g_aClientCookies[iClient][iColor]][iRed], g_iColors[e_ColorNames:g_aClientCookies[iClient][iColor]][iGreen], g_iColors[e_ColorNames:g_aClientCookies[iClient][iColor]][iBlue], 255);
		}
	}
	SetEntProp(iClient, Prop_Data, "m_takedamage", 1, 1);
	g_bIsPlayerImmune[iClient] = true;
}

stock DisableImmunity(iClient)
{
	if (g_hPlayerColorTimer[iClient] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerColorTimer[iClient]);
		g_hPlayerColorTimer[iClient] = INVALID_HANDLE;
	}
	if (IsClientInGame(iClient))
	{
		SetEntityRenderMode(iClient, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
		SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
	}
	g_iPlayerCycleColor[iClient] = 0;
	g_bIsPlayerImmune[iClient] = false;
}

stock LoadColors()
{
	g_iColors[Green][iRed] = 0;
	g_iColors[Green][iGreen] = 255;
	g_iColors[Green][iBlue] = 0;

	g_iColors[Black][iRed] = 10;
	g_iColors[Black][iGreen] = 10;
	g_iColors[Black][iBlue] = 0;
	
	g_iColors[Red][iRed] = 255;
	g_iColors[Red][iGreen] = 0;
	g_iColors[Red][iBlue] = 0;
	
	g_iColors[Blue][iRed] = 0;
	g_iColors[Blue][iGreen] = 0;
	g_iColors[Blue][iBlue] = 255;
}

stock bool:IsValidAdmin(iClient, const String:flags[])
{
	if (!IsClientConnected(iClient))
		return false;
	new ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(iClient) & ibFlags) == ibFlags) 
	{
		return true;
	}
	if (GetUserFlagBits(iClient) & ADMFLAG_ROOT) 
	{
		return true;
	}
	return false;
}

public EnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0) 
	{
		UnhookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Post);
		UnhookEvent("teamplay_round_start", HookRoundStart, EventHookMode_Post);
		UnhookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (g_bIsPlayerAdmin[i] && g_bIsPlayerImmune[i]) 
			{
				DisableImmunity(i);
			}
		}
		g_bIsEnabled = false;
	} 
	else 
	{
		HookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Post);
		HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_Post);
		HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
		g_bIsEnabled = true;
	}
}
