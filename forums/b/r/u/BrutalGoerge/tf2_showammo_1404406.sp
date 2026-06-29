/************************************************************************
*************************************************************************
Tf2 Show Ammow
Description:
	Shows medics how mucha ammo the person they are healing has
*************************************************************************
*************************************************************************

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id: tf2_showammo.sp 163 2012-08-20 09:08:31Z brutalgoergectf@gmail.com $
$Author: brutalgoergectf@gmail.com $
$Revision: 163 $
$Date: 2012-08-20 03:08:31 -0600 (Mon, 20 Aug 2012) $
$LastChangedBy: brutalgoergectf@gmail.com $
$LastChangedDate: 2012-08-20 03:08:31 -0600 (Mon, 20 Aug 2012) $
$URL: https://tf2tmng.googlecode.com/svn/trunk/MedicAmmo/scripting/tf2_showammo.sp $
$Copyright: (c) Tf2Tmng 2009-2011$
*************************************************************************
*************************************************************************
*/
#define PL_VERSION "1.0.9"
#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#define REQUIRE_EXTENSIONS

#define COLOR_RED 		0
#define COLOR_BLUE 	1
#define COLOR_PINK 	2
#define COLOR_GREEN 	3
#define COLOR_WHITE	4
#define COLOR_TEAM		5

#define POS_LEFT 		0
#define POS_MIDLEFT 	1
#define POS_CENTER		2
#define POS_BOTTOM		3
#define POS_BLEFT		4


new Handle:g_hVarUpdateSpeed = INVALID_HANDLE;
new Handle:g_hVarChargeLevel = INVALID_HANDLE;
new Handle:g_hVarWho			= INVALID_HANDLE;
new Handle:g_hVarAdminFlag		= INVALID_HANDLE;

new Handle:g_hCookieEnable 	= INVALID_HANDLE,
	Handle:g_hCookiePosition 	= INVALID_HANDLE,
	Handle:g_hCookieColor 		= INVALID_HANDLE,
	Handle:g_hCookieCharge 	= INVALID_HANDLE;

new Float:g_fTextPositions[5][2] = { 	{0.01, 0.78},
										{0.01, 0.55},
										{0.3, 0.25},
										{0.3, 0.91},
										{0.01, 1.0}		};
new g_iColors[5][3] = { 	{255, 0, 0},
							{180, 150, 255},
							{255, 78, 140},
							{121, 255, 107},
							{240, 240, 240}	};
new Handle:h_HudMessage = INVALID_HANDLE;
new bool:g_bUseClientPrefs = false;

enum e_ClientSettings
{
	bEnabled,
	iPosition,
	iColor,
	iChargeLevel,
	iMaxClip1,
	iMaxClip2,
};

new g_aClientSettings[MAXPLAYERS+1][e_ClientSettings];

public Plugin:myinfo = 
{
	name = "[TF2] Show My Ammo",
	author = "Goerge",
	description = "Shows medics how much ammo a person has",
	version = PL_VERSION,
	url = "http://tf2tmng.googlecode.com/"
};

public OnPluginStart()
{
	CreateConVar("medic_ammocounts_version", PL_VERSION, _, FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	h_HudMessage = CreateHudSynchronizer();
	g_hVarUpdateSpeed = CreateConVar("sm_showammo_update_speed", "0.5", "Delay between updates", FCVAR_PLUGIN, true, 0.1, true, 5.0);
	g_hVarChargeLevel = CreateConVar("sm_showammo_charge_level", "0.90", "Default charge level where medics see ammo counts", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hVarWho = CreateConVar("sm_showammo_who", "0", "Who sees the ammo counts, 0 for everyone, 1 for admins", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hVarAdminFlag = CreateConVar("sm_showammo_flag", "a", "Admin flag for people who see the ammo counts", FCVAR_PLUGIN);
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", Event_PlayerSpawn, EventHookMode_Post);
	
	decl String:sExtError[256];
	new iExtStatus = GetExtensionFileStatus("clientprefs.ext", sExtError, sizeof(sExtError));
	if (iExtStatus == 1)
	{
		if (SQL_CheckConfig("clientprefs"))
		{
			g_bUseClientPrefs = true;
			g_hCookieEnable = RegClientCookie("tf2_showammo_enabed", "enable showing of ammo counts to medics", CookieAccess_Public);
			g_hCookiePosition = RegClientCookie("tf2_showammo_position", "client position of the text", CookieAccess_Public);
			g_hCookieColor		= RegClientCookie("tf2_showammo_color", "client text color setting", CookieAccess_Public);
			g_hCookieCharge	= RegClientCookie("tf2_showammo_chargelevel", "Client charge level setting", CookieAccess_Public);
			SetCookieMenuItem(AmmoCookieSettings, g_hCookieEnable, "TF2 Show Ammo");
		}
	}
	if (!g_bUseClientPrefs)
	{
		LogAction(0, -1, "tf2_showammo has detected errors in your clientprefs installation. %s", sExtError);
	}
	AutoExecConfig();
	CreateTimer(GetConVarFloat(g_hVarUpdateSpeed), Timer_MedicCheck, _, TIMER_REPEAT);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	// delay this in case another plugin is modifying the ammo
	CreateTimer(0.2, Timer_GetMaxAmmo, userid);
}

public Action:Timer_GetMaxAmmo(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client)
	{
		g_aClientSettings[client][iMaxClip1] = TF2_WeaponClip(TF2_GetSlotWeapon(client, 0));
		g_aClientSettings[client][iMaxClip2] = TF2_WeaponClip(TF2_GetSlotWeapon(client, 1));
	}
}

public AmmoCookieSettings(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		//don't think we need to do anything
	}
	else
	{
		new Handle:hMenu = CreateMenu(Menu_CookieSettings);
		SetMenuTitle(hMenu, "Options [Current Setting]");
		if (g_aClientSettings[client][bEnabled])
		{
			AddMenuItem(hMenu, "enable", "Enabled/Disable [Enabled]");
		}
		else
		{
			AddMenuItem(hMenu, "enable", "Enabled/Disable [Disabled]");
		}
		switch (g_aClientSettings[client][iColor])
		{
			case COLOR_RED:
			{
				AddMenuItem(hMenu, "color", "Color [Red]");
			}
			case COLOR_BLUE:
			{
				AddMenuItem(hMenu, "color", "Color [Blue]");
			}
			case COLOR_PINK:
			{
				AddMenuItem(hMenu, "color", "Color [Pink]");
			}
			case COLOR_GREEN:
			{
				AddMenuItem(hMenu, "color", "Color [Green]");
			}
			case COLOR_TEAM:
			{
				AddMenuItem(hMenu, "color", "Color [Team]");
			}
			case COLOR_WHITE:
			{
				AddMenuItem(hMenu, "color", "Color [White]");
			}
		}
		switch (g_aClientSettings[client][iPosition])
		{
			case POS_LEFT:
			{
				AddMenuItem(hMenu, "pos", "Position [Left]");
			}
			case POS_MIDLEFT:
			{
				AddMenuItem(hMenu, "pos", "Position [High Left]");
			}
			case POS_CENTER:
			{
				AddMenuItem(hMenu, "pos", "Position [Center]");
			}
			case POS_BOTTOM:
			{
				AddMenuItem(hMenu, "pos", "Position [Bottom]");
			}
			case POS_BLEFT:
			{
				AddMenuItem(hMenu, "pos", "Position [Bottom Left]");
			}
		}
		switch (g_aClientSettings[client][iChargeLevel])
		{
			case 1:
			{
				AddMenuItem(hMenu, "level", "Charge Level [1\%]");
			}
			case 25:
			{
				AddMenuItem(hMenu, "level", "Charge Level [25\%]");
			}
			case 50:
			{
				AddMenuItem(hMenu, "level", "Charge Level [50\%]");
			}
			case 75:
			{
				AddMenuItem(hMenu, "level", "Charge Level [75\%]");
			}
			default:
			{
				decl String:sBuffer[127];
				Format(sBuffer, sizeof(sBuffer), "Charge Level [Server Default %i\%]", g_aClientSettings[client][iChargeLevel]);
				AddMenuItem(hMenu, "level", sBuffer);
			}
		}
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}

stock bool:IsAdmin(client, const String:flags[])
{
	new bits = GetUserFlagBits(client);	
	if (bits & ADMFLAG_ROOT)
		return true;
	new iFlags = ReadFlagString(flags);
	if (bits & iFlags)
		return true;	
	return false;
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
			SetMenuTitle(hMenu, "Enable/Disable TF2 Show Ammo");
			
			if (g_aClientSettings[client][bEnabled])
			{
				AddMenuItem(hMenu, "enable", "Enable [Set]");
				AddMenuItem(hMenu, "disable", "Disable");
			}
			else
			{
				AddMenuItem(hMenu, "enable", "Enabled");
				AddMenuItem(hMenu, "disable", "Disable [Set]");
			}
			
			SetMenuExitBackButton(hMenu, true);
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
		}
		else if (StrEqual(sSelection, "color", false))
		{
			new Handle:hMenu = CreateMenu(Menu_CookieSettingsColors);
			SetMenuTitle(hMenu, "Select Medic Ammo Text Color");
			AddMenuItem(hMenu, "red", "Red");
			AddMenuItem(hMenu, "blue", "Blue");
			AddMenuItem(hMenu, "pink", "Pink");
			AddMenuItem(hMenu, "green", "Green");
			AddMenuItem(hMenu, "team", "Team Color");
			AddMenuItem(hMenu, "white", "White");
			SetMenuExitBackButton(hMenu, true);
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
		}
		else if (StrEqual(sSelection, "pos", false))
		{
			new Handle:hMenu = CreateMenu(Menu_CookieSettingsPosition);
			SetMenuTitle(hMenu, "Select Medic Ammo Position");
			AddMenuItem(hMenu, "left", "Left Side Near Bottom");
			AddMenuItem(hMenu, "midleft", "Left Side Higher Up");
			AddMenuItem(hMenu, "center", "Middle of Screen High Up");
			AddMenuItem(hMenu, "bottom", "Middle of Screen Bottom");
			AddMenuItem(hMenu, "bleft", "Left Side Bottom");
			SetMenuExitBackButton(hMenu, true);
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
		}
		else
		{
			new Handle:hMenu = CreateMenu(Menu_CookieSettingsChargeLevel);
			decl String:sBuffer[128];
			new iDefault = RoundFloat(FloatMul(GetConVarFloat(g_hVarChargeLevel), 100.0));
			Format(sBuffer, sizeof(sBuffer), "Default Setting %i\%", iDefault);
			SetMenuTitle(hMenu, "Select Charge Level To See Ammo Counts");
			AddMenuItem(hMenu, "25", "25\%");
			AddMenuItem(hMenu, "50", "50\%");
			AddMenuItem(hMenu, "75", "75\%");
			AddMenuItem(hMenu, "-1", sBuffer);
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
			SetClientCookie(client, g_hCookieEnable, "enabled");
			g_aClientSettings[client][bEnabled] = 1;
			PrintToChat(client, "[SM] TF2 Show Ammo is ENABLED for you");
		}
		else
		{
			SetClientCookie(client, g_hCookieEnable, "disabled");
			g_aClientSettings[client][bEnabled] = 0;
			PrintToChat(client, "[SM] TF2 Show Ammo is now DISABLED for you");
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

public Menu_CookieSettingsColors(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "red", false))
		{
			g_aClientSettings[client][iColor] = COLOR_RED;
			SetClientCookie(client, g_hCookieColor, "red");
			PrintToChat(client, "[SM] Color set to RED");
		}
		if (StrEqual(sSelection, "blue", false))
		{
			g_aClientSettings[client][iColor] = COLOR_BLUE;
			SetClientCookie(client, g_hCookieColor, "blue");
			PrintToChat(client, "[SM] Color set to BLUE");
		}
		if (StrEqual(sSelection, "pink", false))
		{
			g_aClientSettings[client][iColor] = COLOR_PINK;
			SetClientCookie(client, g_hCookieColor, "pink");
			PrintToChat(client, "[SM] Color set to PINK");
		}
		if (StrEqual(sSelection, "green", false))
		{
			g_aClientSettings[client][iColor] = COLOR_GREEN;
			SetClientCookie(client, g_hCookieColor, "green");
			PrintToChat(client, "[SM] Color set to GREEN");
		}
		if (StrEqual(sSelection, "team", false))
		{
			g_aClientSettings[client][iColor] = COLOR_TEAM;
			SetClientCookie(client, g_hCookieColor, "team");
			PrintToChat(client, "[SM] Color set to TEAM COLOR");
		}
		if (StrEqual(sSelection, "white", false))
		{
			g_aClientSettings[client][iColor] = COLOR_WHITE;
			SetClientCookie(client, g_hCookieColor, "white");
			PrintToChat(client, "[SM] Color set to WHITE");
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

public Menu_CookieSettingsPosition(Handle:menu, MenuAction:action, client, param2)
{
if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "left", false))
		{
			g_aClientSettings[client][iPosition] = POS_LEFT;
			SetClientCookie(client, g_hCookiePosition, "left");
			PrintToChat(client, "[SM] Position set to LEFT");
		}
		if (StrEqual(sSelection, "midleft", false))
		{
			g_aClientSettings[client][iPosition] = POS_MIDLEFT;
			SetClientCookie(client, g_hCookiePosition, "midleft");
			PrintToChat(client, "[SM] Position set to HIGH LEFT");
		}
		if (StrEqual(sSelection, "center", false))
		{
			g_aClientSettings[client][iPosition] = POS_CENTER;
			SetClientCookie(client, g_hCookiePosition, "center");
			PrintToChat(client, "[SM] Position set to CENTER HIGH");
		}
		if (StrEqual(sSelection, "bottom", false))
		{
			g_aClientSettings[client][iPosition] = POS_BOTTOM;
			SetClientCookie(client, g_hCookiePosition, "bottom");
			PrintToChat(client, "[SM] Position set to BOTTOM");
		}
		if (StrEqual(sSelection, "bleft", false))
		{
			g_aClientSettings[client][iPosition] = POS_BLEFT;
			SetClientCookie(client, g_hCookiePosition, "bleft");
			PrintToChat(client, "[SM] Position set to BOTTOM LEFT");
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

public Menu_CookieSettingsChargeLevel(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:sBuffer[120], iSelection;
		GetMenuItem(menu, param2, sBuffer, sizeof(sBuffer));
		iSelection = StringToInt(sBuffer);
		if (iSelection == -1)
		{
			iSelection = RoundFloat(FloatMul(GetConVarFloat(g_hVarChargeLevel), 100.0));
		}
		g_aClientSettings[client][iChargeLevel] = iSelection;
		SetClientCookie(client, g_hCookieCharge, sBuffer);
		PrintToChat(client, "[SM] Charge Level set to %i\%", iSelection);
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

public OnClientCookiesCached(client)
{
	decl String:sSetting[24];
	GetClientCookie(client, g_hCookieEnable, sSetting, sizeof(sSetting));
	if (StrEqual(sSetting, "disabled", false))
	{
		g_aClientSettings[client][bEnabled] = 0;
	}
	else
	{
		g_aClientSettings[client][bEnabled] = 1;
	}
	
	GetClientCookie(client, g_hCookieColor, sSetting, sizeof(sSetting));
	if (StrEqual(sSetting, "red", false))
	{
		g_aClientSettings[client][iColor] = COLOR_RED;
	}
	else if (StrEqual(sSetting, "blue", false))
	{
		g_aClientSettings[client][iColor] = COLOR_BLUE;
	}
	else if (StrEqual(sSetting, "pink", false))
	{
		g_aClientSettings[client][iColor] = COLOR_PINK;
	}
	else if (StrEqual(sSetting, "green", false))
	{
		g_aClientSettings[client][iColor] = COLOR_GREEN;
	}
	else if (StrEqual(sSetting, "white", false))
	{
		g_aClientSettings[client][iColor] = COLOR_WHITE;
	}
	else
	{
		g_aClientSettings[client][iColor] = COLOR_TEAM;
	}
	
	GetClientCookie(client, g_hCookiePosition, sSetting, sizeof(sSetting));
	if (StrEqual(sSetting, "midleft", false))
	{
		g_aClientSettings[client][iPosition] = POS_MIDLEFT;
	}
	else if (StrEqual(sSetting, "center", false))
	{
		g_aClientSettings[client][iPosition] = POS_CENTER;
	}
	else if (StrEqual(sSetting, "bottom", false))
	{
		g_aClientSettings[client][iPosition] = POS_BOTTOM;
	}
	else if (StrEqual(sSetting, "bleft", false))
	{
		g_aClientSettings[client][iPosition] = POS_BLEFT;
	}
	else
	{
		g_aClientSettings[client][iPosition] = POS_LEFT;
	}
	
	GetClientCookie(client, g_hCookieCharge, sSetting, sizeof(sSetting));
	{
		if (StringToInt(sSetting) > 1)
		{
			g_aClientSettings[client][iChargeLevel] = StringToInt(sSetting);
		}
		else
		{
			g_aClientSettings[client][iChargeLevel] = RoundFloat(FloatMul(GetConVarFloat(g_hVarChargeLevel), 100.0));
		}
	}
}

public Action:Timer_MedicCheck(Handle:timer)
{
	CheckHealers();
	return Plugin_Continue;
}

stock CheckHealers()
{
	new iTarget;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)&& IsPlayerAlive(i) && !IsFakeClient(i) && g_aClientSettings[i][bEnabled])
		{
			if (GetConVarBool(g_hVarWho))
			{
				decl String:sFlags[33];
				GetConVarString(g_hVarAdminFlag, sFlags, sizeof(sFlags));
				if (!IsAdmin(i, sFlags))
				{
					continue;
				}
			}
			iTarget = TF2_GetHealingTarget(i);
			if (iTarget > 0)
			{
				ShowInfo(i, iTarget);
			}
		}
	}
}

stock ShowInfo(medic, target)
{
	if (!TF2_IsClientUberCharged(medic))
	{
		return;
	}
	new TFClassType:class, iAmmo1, iClip1, iClip2, 
		iColorSetting = g_aClientSettings[medic][iColor],
		iPos = g_aClientSettings[medic][iPosition];
	new String:sMessage[255];
	iClip1 = TF2_WeaponClip(TF2_GetSlotWeapon(target, 0));
	iClip2 = TF2_WeaponClip(TF2_GetSlotWeapon(target, 1));
	if (iColorSetting == COLOR_TEAM)
	{
		if (GetClientTeam(medic) == 2)
		{
			iColorSetting = COLOR_RED;
		}
		else
		{
			iColorSetting = COLOR_BLUE;
		}
	}
	if (iClip1 == -1)
	{
		 iAmmo1 = TF2_GetSlotAmmo(target, 0);
		 if (iAmmo1 != -1) Format(sMessage, sizeof(sMessage), "Ammo: %i ", iAmmo1);
	}
	else Format(sMessage, sizeof(sMessage), "Primary Ammo: %i / %i ", iClip1, g_aClientSettings[target][iMaxClip1]);
	 
	class = TF2_GetPlayerClass(target);
	switch(class)
	{
		 case TFClass_Pyro, TFClass_Heavy, TFClass_Sniper:
		 {
			  iAmmo1 = GetHeavyPyroAmmo(target);
			  Format(sMessage, sizeof(sMessage), "Ammo: %i ", iAmmo1);
		 }
		 case TFClass_DemoMan:
		 {
			  if (iClip2 != -1) Format(sMessage, sizeof(sMessage), "%sAmmo 2: %i / %i ", sMessage, iClip2, g_aClientSettings[target][iMaxClip2]);
		 }
	}  
	SetHudTextParams(g_fTextPositions[iPos][0], g_fTextPositions[iPos][1], GetConVarFloat(g_hVarUpdateSpeed), g_iColors[iColorSetting][0], g_iColors[iColorSetting][1], g_iColors[iColorSetting][2], 255);
	ShowSyncHudText(medic, h_HudMessage, sMessage);
}

stock TF2_GetHealingTarget(client)
{
	new String:classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));
	
	if(StrEqual(classname, "CWeaponMedigun"))
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( GetEntProp(index, Prop_Send, "m_bHealing") == 1 )
		{
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}
	return -1;
}

stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength)
{
	if( client > 0 )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}

stock TF2_WeaponClip(weapon, clip = 1)
{
	if ( weapon != -1 )
	{
		if (clip == 1)
		{
			return GetEntProp( weapon, Prop_Send, "m_iClip1" );
		}
		else
		{
			return GetEntProp( weapon, Prop_Send, "m_iClip2" );
		}
	}
	return -1;
}

stock GetHeavyPyroAmmo(client)
{
	new ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	return GetEntData(client, ammoOffset + 4, 4);
}

stock TF2_GetSlotAmmo(any:client, slot)
{
	if( client > 0 )
	{
		new offset = FindDataMapOffs(client, "m_iAmmo") + ((slot + 1) * 4);
		return GetEntData(client, offset, 4);
	}
	return -1;
}

stock TF2_GetSlotWeapon(any:client, slot)
{
	if( client > 0 && slot >= 0 && IsClientInGame(client))
	{
		new weaponIndex = GetPlayerWeaponSlot(client, slot);
		return weaponIndex;
	}
	return -1;
}

stock bool:TF2_IsClientUberCharged(client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return false;
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class == TFClass_Medic)
	{			
		new entityIndex = GetPlayerWeaponSlot(client, 1);
		new Float:chargeLevel = GetEntPropFloat(entityIndex, Prop_Send, "m_flChargeLevel");
		if (chargeLevel >= FloatDiv(float(g_aClientSettings[client][iChargeLevel]), 100.0))				
			return true;				
	}
	return false;
}
