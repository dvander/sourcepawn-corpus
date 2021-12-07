/*
*	Glare
*	Copyright (C) 2021 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"2.6"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Light Glare
*	Author	:	SilverShot
*	Descrp	:	Attaches a beam and halo glare to flashlights.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=181515
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.6 (11-Jul-2021)
	- Added cvar "l4d_glare_default" to default the glare to off for new players.
	- Added menu option "Off" to turn off the glare.
	- Requested by "Voevoda".

2.5 (01-Jul-2021)
	- Added a warning message to suggest installing the "Use Priority Patch" plugin.

2.4 (27-Mar-2021)
	- L4D1: Fixed the beam being visible in first person view when first starting and not detecting thirdperson status.

2.3 (05-Aug-2020)
	- Fixed displaying the beam when using a minigun.

2.2 (15-Jul-2020)
	- Fixed an error where client cookies are cached but the client is not yet in-game.

2.1 (04-Jul-2020)
	- Fixed not compiling on SourceMod 1.11.
	- Plugin "Attachments_API" updated and required.

2.0 (01-Jul-2020)
	- Glare beam now properly aligned with all weapon flashlight attachment points for all survivors.
	- Glare position fixed when a players model has changed. Does this by dropping all weapons/items for 0.1s.
	- Added client preferences to save a players previous glare color set.
	- Added command "sm_glaremenu" to display a menu for selecting glare color.
	- Removed commands "sm_glareang" and "sm_glarepos". No more manual positioning required.
	- Suggest changing cvar "l4d_glare_width" value to "5" to correctly match flashlight size.
	- Thanks to "Lux" for the bone merge method. Adapted from "Incapped Crawling" plugin.

	Plugin now requires:
	- "Attachments_API" plugin by "Silvers" to handle attaching to weapons.
	- "ThirdPersonShoulder_Detect" plugin by "Lux" to enable/disable the beam when changing view.

1.5 (17-May-2020)
	- Fixed Zoey's glare position in L4D2 for Spas Shotgun.

1.4 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.3 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.
	- Added cvar "l4d_glare_transmit" to show or hide your own glare.
	- Added command "sm_glare" for players to set their glare color. Requested by "Awerix".
	- Usage: !glare <color name|R G B>. Or 3 values 0-255. EG: !glare red or !glare 255 0 0

1.2 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_glare_modes_tog" now supports L4D1.

1.1.1 (31-Mar-2018)
	- Fixed not working in L4D1.
	- Did anyone use this or realize it wasn't working?

1.1 (10-May-2012)
	- Added commands "sm_glarepos" and "sm_glareang" to position the beam. Affects all players.
	- Fixed the beam sticking when players have no weapons.
	- Removed colors.inc include.

1.0 (30-Mar-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <attachments_api>
#include <ThirdPersonShoulder_Detect>

#define CVAR_FLAGS				FCVAR_NOTIFY
#define ATTACHMENT_POINT		"flashlight"


ConVar g_hCvarAllow, g_hCvarAlpha, g_hCvarColor, g_hCvarCustom, g_hCvarDefault, g_hCvarHalo, g_hCvarLength, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarTransmit, g_hCvarWidth;
int g_iCvarAlpha, g_iCvarColor, g_iCvarCustom, g_iCvarDefault, g_iCvarLength, g_iCvarTransmit, g_iCvarWidth;
bool g_bCvarAllow, g_bMapStarted, g_bLateLoad, g_bLeft4Dead2, g_bAttachments;
float g_fCvarHalo;
Handle g_hCookie;
Menu g_hMenu;

int g_iLightIndex[MAXPLAYERS+1];
int g_iLightState[MAXPLAYERS+1];
int g_iPlayerEnum[MAXPLAYERS+1];
int g_iWeaponIndex[MAXPLAYERS+1];
int g_iGlareColor[MAXPLAYERS+1];
bool g_bDetected[MAXPLAYERS+1];
Handle g_hTimerDetect;
StringMap g_hColors;
StringMap g_hWeapons;

enum
{
	ENUM_BLOCKED	= (1 << 0),
	ENUM_POUNCED	= (1 << 1),
	ENUM_ONLEDGE	= (1 << 2),
	ENUM_INREVIVE	= (1 << 3),
	ENUM_BLOCK		= (1 << 4),
	ENUM_MINIGUN	= (1 << 5)
}

enum
{
	LIGHT_DEFAULT	= -1,
	LIGHT_OFF		= 0,
	LIGHT_ON		= 1
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Glare",
	author = "SilverShot",
	description = "Attaches a beam and halo glare to flashlights.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=181515"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;

	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	// ThirdPersonShoulder_Detect
	if( FindConVar("ThirdPersonShoulder_Detect_Version") == null )
	{
		SetFailState("\n==========\nMissing required plugin: \"ThirdPersonShoulder_Detect\".\nRead installation instructions again.\n==========");
	}

	// L4D1 Charms and Glare conflict
	if( !g_bLeft4Dead2 && FindConVar("charms_version") != null )
	{
		SetFailState("\n==========\nPlugin conflict: \"Weapon Charms\" cannot work with \"Glare\" plugin.\n\"Glare\" plugin has been disabled.\n==========");
	}

	// Use Priority Patch
	if( FindConVar("l4d_use_priority_version") == null )
	{
		LogMessage("\n==========\nWarning: You should install \"[L4D & L4D2] Use Priority Patch\" to fix attached models blocking +USE action: https://forums.alliedmods.net/showthread.php?t=327511\n==========\n");
	}
}

public void OnPluginStart()
{
	g_bAttachments = true;
	LoadTranslations("core.phrases");

	g_hCvarAllow =			CreateConVar(	"l4d_glare_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarAlpha =			CreateConVar(	"l4d_glare_bright",		"155.0",		"Brightness of the beam.", CVAR_FLAGS );
	g_hCvarColor =			CreateConVar(	"l4d_glare_color",		"250 250 200",	"The beam color. RGB (red, green, blue) values (0-255).", CVAR_FLAGS );
	g_hCvarCustom =			CreateConVar(	"l4d_glare_custom",		"2",			"0=Use servers glare color. 1=Allow clients to customise the glare color. 2=Save and restore clients custom glare color.", CVAR_FLAGS );
	g_hCvarDefault =		CreateConVar(	"l4d_glare_default",	"1",			"0=New players glare is turned off by default. 1=New players glare is turned on by default.", CVAR_FLAGS );
	g_hCvarHalo =			CreateConVar(	"l4d_glare_halo",		"0.4",			"Brightness of the halo (glare).", CVAR_FLAGS );
	g_hCvarLength =			CreateConVar(	"l4d_glare_length",		"50",			"Length of the beam.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_glare_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_glare_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_glare_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarTransmit =		CreateConVar(	"l4d_glare_transmit",	"1",			"0=Hide your own glow. 1=Show glow (will attempt to detect and hide when in first person).", CVAR_FLAGS );
	g_hCvarWidth =			CreateConVar(	"l4d_glare_width",		"5",			"Width of the beam.", CVAR_FLAGS );
	CreateConVar(							"l4d_glare_version",	PLUGIN_VERSION,	"Glare plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_glare");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAlpha.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColor.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarCustom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDefault.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLength.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTransmit.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWidth.AddChangeHook(ConVarChanged_Cvars);

	RegConsoleCmd("sm_glare", CmdGlare, "Opens the glare color menu. Or: set glare color. Usage: [color name|R G B]. Or 3 values 0-255. EG: !glare red or !glare 255 0 0");

	CreateColors();
	g_hCookie = RegClientCookie("l4d_glare", "Glare Color", CookieAccess_Protected);

	// Weapons
	g_hWeapons = new StringMap();
	g_hWeapons.SetValue("pistol", 1);
	g_hWeapons.SetValue("smg", 1);
	g_hWeapons.SetValue("rifle", 1);
	g_hWeapons.SetValue("pumpshotgun", 1);
	g_hWeapons.SetValue("shotgun_chrome", 1);
	g_hWeapons.SetValue("hunting_rifle", 1);

	if( g_bLeft4Dead2 )
	{
		g_hWeapons.SetValue("pistol_magnum", 1);
		g_hWeapons.SetValue("smg_silenced", 1);
		g_hWeapons.SetValue("smg_mp5", 1);
		g_hWeapons.SetValue("rifle_sg552", 1);
		g_hWeapons.SetValue("rifle_desert", 1);
		g_hWeapons.SetValue("rifle_ak47", 1);
		g_hWeapons.SetValue("autoshotgun", 1);
		g_hWeapons.SetValue("shotgun_spas", 1);
		g_hWeapons.SetValue("sniper_awp", 1);
		g_hWeapons.SetValue("sniper_military", 1);
		g_hWeapons.SetValue("sniper_scout", 1);
		g_hWeapons.SetValue("grenade_launcher", 1);
		g_hWeapons.SetValue("rifle_m60", 1);
	}
}

public void Attachments_OnLateLoad()
{
	g_bLateLoad = true;
	g_bAttachments = true;
	IsAllowed();
}

public void Attachments_OnPluginEnd()
{
	g_bAttachments = false;
	OnPluginEnd();
	IsAllowed();
}

public void OnPluginEnd()
{
	for( int i = 1; i <= MaxClients; i++ )
		DeleteLight(i);
}

public void OnClientConnected(int client)
{
	g_iGlareColor[client] = g_iCvarColor;
	if( g_iCvarDefault == 0 )
		g_iLightState[client] = LIGHT_DEFAULT;
}

public void OnClientCookiesCached(int client)
{
	if( g_iCvarCustom == 2 )
	{
		char sCookie[10];
		GetClientCookie(client, g_hCookie, sCookie, sizeof(sCookie));

		if( sCookie[0] )
		{
			if( sCookie[0] == '0')
			{
				g_iLightState[client] = LIGHT_DEFAULT;
				return;
			}

			g_iGlareColor[client] = StringToInt(sCookie);

			int entity = g_iLightIndex[client];
			if( IsValidEntRef(entity) )
			{
				SetEntProp(entity, Prop_Send, "m_clrRender", g_iGlareColor[client]);
				AcceptEntityInput(entity, "LightOff");

				if( g_iPlayerEnum[client] == 0 && IsClientInGame(client) && GetEntProp(client, Prop_Send, "m_fEffects") == 4 )
					CreateTimer(0.1, TimerLightOn, g_iLightIndex[client]);
			}
		}
	}
}



// ====================================================================================================
//					COMMAND GLARE
// ====================================================================================================
public Action CmdGlare(int client, int args)
{
	if( !g_iCvarCustom )
	{
		ReplyToCommand(client, "[SM] %T.", "No Access", client);
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	}
	else if( args == 0 )
	{
		g_hMenu.Display(client, 0);
	}
	else if( args == 1 )
	{
		if( GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		{
			char sColor[12];
			GetCmdArgString(sColor, sizeof(sColor));

			if( g_hColors.GetString(sColor, sColor, sizeof(sColor)) )
			{
				g_iGlareColor[client] = GetColor(sColor);

				if( g_iCvarCustom == 2 )
				{
					char sNum[10];
					IntToString(g_iGlareColor[client], sNum, sizeof(sNum));
					SetClientCookie(client, g_hCookie, sNum);
				}

				int entity = g_iLightIndex[client];
				if( entity && IsValidEntRef(entity) )
				{
					SetVariantString(sColor);
					AcceptEntityInput(entity, "color");
					AcceptEntityInput(entity, "LightOff");
					if( g_iPlayerEnum[client] == 0 && GetEntProp(client, Prop_Send, "m_fEffects") == 4 )
						CreateTimer(0.1, TimerLightOn, g_iLightIndex[client]);
				}
				else
				{
					DeleteLight(client);
					CreateLight(client);
				}
			}
		}
	}
	else if( args != 3 )
	{
		ReplyToCommand(client, "Usage: !glare <color name|R G B>. Or 3 values 0-255. EG: !glare red or !glare 255 0 0");
	}
	else
	{
		if( GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		{
			char sColor[12];
			char sSplit[3][4];
			GetCmdArgString(sColor, sizeof(sColor));
			ExplodeString(sColor, " ", sSplit, sizeof(sSplit), sizeof(sSplit[]));
			Format(sColor, sizeof(sColor), "%d %d %d", StringToInt(sSplit[0]), StringToInt(sSplit[1]), StringToInt(sSplit[2]));
			g_iGlareColor[client] = GetColor(sColor);

			if( g_iCvarCustom == 2 )
			{
				char sNum[10];
				IntToString(g_iGlareColor[client], sNum, sizeof(sNum));
				SetClientCookie(client, g_hCookie, sNum);
			}

			int entity = g_iLightIndex[client];
			if( entity && IsValidEntRef(entity) )
			{
				SetVariantString(sColor);
				AcceptEntityInput(entity, "color");
				AcceptEntityInput(entity, "LightOff");
				if( g_iPlayerEnum[client] == 0 && GetEntProp(client, Prop_Send, "m_fEffects") == 4 )
					CreateTimer(0.1, TimerLightOn, g_iLightIndex[client]);
			}
			else
			{
				DeleteLight(client);
				CreateLight(client);
			}
		}
	}

	return Plugin_Handled;
}



// ====================================================================================================
//					MENU + COLORS
// ====================================================================================================
void CreateColors()
{
	// Menu
	g_hMenu = new Menu(Menu_Light);
	g_hMenu.SetTitle("Light Color:");
	g_hMenu.ExitButton = true;

	// Colors
	g_hColors = CreateTrie();

	AddColorItem("off",			"0 0 0");
	AddColorItem("red",			"255 0 0");
	AddColorItem("green",		"0 255 0");
	AddColorItem("blue",		"0 0 255");
	AddColorItem("purple",		"155 0 255");
	AddColorItem("cyan",		"0 255 255");
	AddColorItem("orange",		"255 155 0");
	AddColorItem("white",		"-1 -1 -1");
	AddColorItem("pink",		"255 0 150");
	AddColorItem("lime",		"128 255 0");
	AddColorItem("maroon",		"128 0 0");
	AddColorItem("teal",		"0 128 128");
	AddColorItem("yellow",		"255 255 0");
	AddColorItem("grey",		"50 50 50");
}

void AddColorItem(char[] sName, const char[] sColor)
{
	g_hColors.SetString(sName, sColor);

	sName[0] = CharToUpper(sName[0]);
	g_hMenu.AddItem(sColor, sName);
}

public int Menu_Light(Menu menu, MenuAction action, int client, int index)
{
	switch( action )
	{
		case MenuAction_Select:
		{
			g_hMenu.Display(client, 0);

			// Delete
			if( index == 0 )
			{
				DeleteLight(client);
				g_iLightState[client] = LIGHT_DEFAULT;

				if( g_iCvarCustom == 2 )
				{
					SetClientCookie(client, g_hCookie, "0");
				}
				return;
			}

			// Create
			char sColor[12];
			menu.GetItem(index, sColor, sizeof(sColor));

			g_iGlareColor[client] = GetColor(sColor);

			if( g_iCvarCustom == 2 )
			{
				char sNum[10];
				IntToString(g_iGlareColor[client], sNum, sizeof(sNum));
				SetClientCookie(client, g_hCookie, sNum);
			}

			int entity = g_iLightIndex[client];
			if( entity && IsValidEntRef(entity) )
			{
				SetVariantString(sColor);
				AcceptEntityInput(entity, "color");
				AcceptEntityInput(entity, "LightOff");
				if( g_iPlayerEnum[client] == 0 && GetEntProp(client, Prop_Send, "m_fEffects") == 4 )
					CreateTimer(0.1, TimerLightOn, g_iLightIndex[client]);
			}
			else
			{
				DeleteLight(client);
				CreateLight(client);
			}
		}
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	char sColor[16];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	g_iCvarColor = GetColor(sColor);
	g_iCvarCustom = g_hCvarCustom.IntValue;
	g_iCvarDefault = g_hCvarDefault.IntValue;
	g_iCvarAlpha = g_hCvarAlpha.IntValue;
	g_fCvarHalo = g_hCvarHalo.FloatValue;
	g_iCvarLength = g_hCvarLength.IntValue;
	g_iCvarTransmit = g_hCvarTransmit.IntValue;
	g_iCvarWidth = g_hCvarWidth.IntValue;
}

int GetColor(char[] sTemp)
{
	if( sTemp[0] == 0 )
		return 0;

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, sizeof(sColors), sizeof(sColors[]));

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true && g_bAttachments == true )
	{
		g_bCvarAllow = true;
		HookEvents();

		if( g_bLeft4Dead2 && g_iCvarTransmit )
		{
			delete g_hTimerDetect;
			g_hTimerDetect = CreateTimer(0.3, TimerDetect, _, TIMER_REPEAT);
		}

		if( g_bLateLoad )
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) && !IsFakeClient(i) )
				{
					OnClientConnected(i);
					OnClientCookiesCached(i);
				}
			}

			g_bLateLoad = false;
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false || g_bAttachments == false) )
	{
		g_bCvarAllow = false;
		UnhookEvents();

		for( int i = 1; i <= MaxClients; i++ )
		{
			DeleteLight(i);
		}
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents()
{
	HookEvent("round_start",					Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("player_ledge_grab",				Event_LedgeGrab);
	HookEvent("revive_begin",					Event_ReviveStart);
	HookEvent("revive_end",						Event_ReviveEnd);
	HookEvent("revive_success",					Event_ReviveSuccess);
	HookEvent("player_death",					Event_Unblock);
	HookEvent("player_spawn",					Event_Unblock);
	HookEvent("lunge_pounce",					Event_BlockHunter);
	HookEvent("pounce_end",						Event_BlockEndHunt);
	HookEvent("tongue_grab",					Event_BlockStart);
	HookEvent("tongue_release",					Event_BlockEnd);

	if( g_bLeft4Dead2 )
	{
		HookEvent("charger_pummel_start",		Event_BlockStart);
		HookEvent("charger_carry_start",		Event_BlockStart);
		HookEvent("charger_carry_end",			Event_BlockEnd);
		HookEvent("charger_pummel_end",			Event_BlockEnd);
	}
}

void UnhookEvents()
{
	UnhookEvent("round_start",					Event_RoundStart,	EventHookMode_PostNoCopy);
	UnhookEvent("player_ledge_grab",			Event_LedgeGrab);
	UnhookEvent("revive_begin",					Event_ReviveStart);
	UnhookEvent("revive_end",					Event_ReviveEnd);
	UnhookEvent("revive_success",				Event_ReviveSuccess);
	UnhookEvent("player_death",					Event_Unblock);
	UnhookEvent("player_spawn",					Event_Unblock);
	UnhookEvent("lunge_pounce",					Event_BlockHunter);
	UnhookEvent("pounce_end",					Event_BlockEndHunt);
	UnhookEvent("tongue_grab",					Event_BlockStart);
	UnhookEvent("tongue_release",				Event_BlockEnd);

	if( g_bLeft4Dead2 )
	{
		UnhookEvent("charger_pummel_start",		Event_BlockStart);
		UnhookEvent("charger_carry_start",		Event_BlockStart);
		UnhookEvent("charger_carry_end",		Event_BlockEnd);
		UnhookEvent("charger_pummel_end",		Event_BlockEnd);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i < MAXPLAYERS; i++ )
	{
		g_iPlayerEnum[i] = 0;
		g_iWeaponIndex[i] = 0;
	}

	if( g_bLeft4Dead2 && g_iCvarTransmit )
	{
		delete g_hTimerDetect;
		g_hTimerDetect = CreateTimer(0.3, TimerDetect, _, TIMER_REPEAT);
	}

	if( !g_bLeft4Dead2 )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
			{
				SetView(i, false);
			}
		}
	}
}

public void Event_BlockStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_BLOCKED;
}

public void Event_BlockEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~ENUM_BLOCKED;
}

public void Event_BlockHunter(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_POUNCED;
}

public void Event_BlockEndHunt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~ENUM_POUNCED;
}

public void Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_ONLEDGE;
}

public void Event_ReviveStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_INREVIVE;

	client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_INREVIVE;
}

public void Event_ReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~ENUM_INREVIVE;

	client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~ENUM_INREVIVE;
}

public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if( client > 0 )
	{
		g_iPlayerEnum[client] &= ~ENUM_INREVIVE;
		g_iPlayerEnum[client] &= ~ENUM_ONLEDGE;
	}

	client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~ENUM_INREVIVE;
}

public void Event_Unblock(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0)
	{
		g_iPlayerEnum[client] = 0;
		g_bDetected[client] = false;
	}
}



// ====================================================================================================
//					THIRDPERSON DETECT
// ====================================================================================================
public Action TimerDetect(Handle timer)
{
	if( g_bCvarAllow == false || g_iCvarTransmit == 0 )
	{
		g_hTimerDetect = null;
		return Plugin_Stop;
	}

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( g_iLightIndex[i] && g_bDetected[i] == false && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			if( GetEntPropFloat(i, Prop_Send, "m_TimeForceExternalView") > GetGameTime() )
				SetView(i, true);
			else
				SetView(i, false);
		}
	}

	return Plugin_Continue;
}

public void TP_OnThirdPersonChanged(int client, bool bIsThirdPerson)
{
	if( bIsThirdPerson == true && g_bDetected[client] == false )
	{
		g_bDetected[client] = true;
		SetView(client, true);
	}
	else if( bIsThirdPerson == false && g_bDetected[client] == true )
	{
		g_bDetected[client] = false;
		SetView(client, false);
	}
}

void SetView(int client, bool bSetView)
{
	if( bSetView )
	{
		int entity = g_iLightIndex[client];
		if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
	} else {
		int entity = g_iLightIndex[client];
		if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
	}
}



// ====================================================================================================
//					GLARE ON/OFF
// ====================================================================================================
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( g_bCvarAllow )
	{
		if( g_iLightState[client] == LIGHT_DEFAULT ) return;

		int entity = g_iLightIndex[client];

		if( GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		{
			if( IsValidEntRef(entity) == false )
			{
				g_iLightState[client] = LIGHT_ON;
				CreateLight(client);
			}
			else
			{
				// Last weapon or player model changed.
				int active = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

				if( g_iWeaponIndex[client] != active )
				{
					g_iWeaponIndex[client] = active;

					// No weapon, turn off light.
					if( active == -1 )
					{
						g_iPlayerEnum[client] |= ENUM_BLOCK;
						AcceptEntityInput(entity, "LightOff");
						g_iLightState[client] = LIGHT_OFF;
						return;
					}

					g_iPlayerEnum[client] &= ~ENUM_BLOCK;

					char sTemp[32];
					GetClientWeapon(client, sTemp, sizeof(sTemp));

					int val;
					if( g_hWeapons.GetValue(sTemp[7], val) == false )
					{
						g_iPlayerEnum[client] |= ENUM_BLOCK;
					}

					// Re-attach to different gun
					if( g_iPlayerEnum[client] == 0 )
					{
						int bone = GetEntPropEnt(entity, Prop_Send, "moveparent");
						if( bone == -1 ) bone = Attachments_GetWorldModel(client, active);

						SetVariantString("!activator");
						AcceptEntityInput(entity, "SetParent", bone);
						SetVariantString(ATTACHMENT_POINT);
						AcceptEntityInput(entity, "SetParentAttachment", bone, bone);

						TeleportEntity(entity, NULL_VECTOR, view_as<float>({-90.0, 0.0, 0.0}), NULL_VECTOR);
					}
				}
				else if( GetEntProp(client, Prop_Send, "m_usingMountedWeapon") != 0 )
				{
					g_iPlayerEnum[client] |= ENUM_MINIGUN;
				}
				else
				{
					g_iPlayerEnum[client] &= ~ENUM_MINIGUN;
				}

				if( g_iPlayerEnum[client] == 0 && GetEntProp(client, Prop_Send, "m_fEffects") == 4 )
				{
					if( g_iLightState[client] == LIGHT_OFF )
					{
						AcceptEntityInput(entity, "LightOn");
						g_iLightState[client] = LIGHT_ON;
					}
				}
				else
				{
					if( g_iLightState[client] == LIGHT_ON )
					{
						AcceptEntityInput(entity, "LightOff");
						g_iLightState[client] = LIGHT_OFF;
					}
				}
			}
		}
		else
		{
			if( IsValidEntRef(entity) == true )
				DeleteLight(client);
		}
	}
}

public void Attachments_OnWeaponSwitch(int client, int weapon, int ent_views, int ent_world)
{
	// Turn off between change to prevent flash at players feet
	int entity = g_iLightIndex[client];
	if( IsValidEntRef(entity) )
	{
		AcceptEntityInput(entity, "LightOff");
		g_iLightState[client] = LIGHT_OFF;
	}
}

void DeleteLight(int client)
{
	int entity = g_iLightIndex[client];
	g_iLightIndex[client] = 0;
	if( IsValidEntRef(entity) )
	{
		AcceptEntityInput(entity, "Kill");
		SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
	}
}

void CreateLight(int client)
{
	int entity = g_iLightIndex[client];
	if( IsValidEntRef(entity) )
		return;

	entity = CreateEntityByName("beam_spotlight");
	if( entity == -1)
		return;

	if( !g_iCvarTransmit )
	{
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
	}
	else
	{
		if( !g_bLeft4Dead2 && !g_bDetected[client] )
		{
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
		}
	}

	DispatchKeyValue(entity, "spawnflags", "3");

	static char sTemp[32];

	DispatchKeyValue(entity, "HaloScale", "250");
	IntToString(g_iCvarWidth, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "SpotlightWidth", sTemp);
	IntToString(g_iCvarLength, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "SpotlightLength", sTemp);
	IntToString(g_iCvarAlpha, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "renderamt", sTemp);
	DispatchKeyValueFloat(entity, "HDRColorScale", g_fCvarHalo);
	SetEntProp(entity, Prop_Send, "m_clrRender", g_iGlareColor[client]);
	DispatchSpawn(entity);

	g_iLightIndex[client] = EntIndexToEntRef(entity);

	// Validate weapon
	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if( weapon == -1 )
		return;

	GetClientWeapon(client, sTemp, sizeof(sTemp));

	int val;
	if( g_hWeapons.GetValue(sTemp[7], val) )
	{
		int bone = Attachments_GetWorldModel(client, weapon);
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", bone);
		SetVariantString(ATTACHMENT_POINT);
		AcceptEntityInput(entity, "SetParentAttachment", bone, bone);

		TeleportEntity(entity, NULL_VECTOR, view_as<float>({-90.0, 0.0, 0.0}), NULL_VECTOR);
	}
}

public Action Hook_SetTransmitLight(int entity, int client)
{
	if( g_iLightIndex[client] == EntIndexToEntRef(entity) )
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action TimerLightOn(Handle timer, any entity)
{
	if( IsValidEntRef(entity) )
	{
		AcceptEntityInput(entity, "LightOn");
	}
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}