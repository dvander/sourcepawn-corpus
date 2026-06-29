/*
	Revision 3.0.5
	------------
	Fixed an issue where slower responses to queries would allow a player to spawn without valid trails, causing errors.
	Fixed an issue where Layouts/Colors/Materials did not obey any flag/override defined within their configuration.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <colors>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_VERSION "3.0.5"

//Maximum amount of definitions allowed.
#define MAX_DEFINED_COLORS 128
#define MAX_DEFINED_LAYOUTS 128
#define MAX_DEFINED_MATERIALS 128
#define MAX_DEFINED_WIDTHS 128
#define MAX_DEFINED_LIFES 128

#define INDEX_COLOR 0
#define INDEX_LAYOUT 1
#define INDEX_START 2
#define INDEX_END 3
#define INDEX_LIFE 4
#define INDEX_RENDER 5
#define INDEX_MATERIAL 6
#define INDEX_VISIBLE 7
#define INDEX_TOTAL 8

#define VISIBLE_ONE 0
#define VISIBLE_TEAM 1
#define VISIBLE_ALL 2

new g_iLoadColors, g_iLoadMaterials, g_iLoadConfigs, g_iLoadLayouts;

//Colors
new g_iNumColors;
new String:g_sColorSchemes[MAX_DEFINED_COLORS][16];
new String:g_sColorNames[MAX_DEFINED_COLORS][64];
new g_iColorFlag[MAX_DEFINED_COLORS];

//Layouts
new g_iNumLayouts;
new String:g_sLayoutNames[MAX_DEFINED_LAYOUTS][64];
new Float:g_fLayoutPositions[MAX_DEFINED_LAYOUTS][MAX_DEFINED_LAYOUTS][3];
new g_iLayoutFlag[MAX_DEFINED_LAYOUTS];
new g_iLayoutTotals[MAX_DEFINED_LAYOUTS];

//Materials
new g_iMaterials;
new String:g_sMaterialPaths[MAX_DEFINED_MATERIALS][256];
new String:g_sMaterialNames[MAX_DEFINED_MATERIALS][64];
new g_iMaterialFlag[MAX_DEFINED_MATERIALS];

//Configs
new g_iStartWidths, g_iEndWidths, g_iLifeTimes, g_iRenderModes;
new String:g_sStartingWidths[MAX_DEFINED_WIDTHS][8];
new String:g_sEndingWidths[MAX_DEFINED_WIDTHS][8];
new String:g_sLifeTimes[MAX_DEFINED_LIFES][8];
new String:g_sRenderModes[][] = { "0", "1", "2", "3", "4", "5", "6", "7", "8" };
new bool:g_bRenderModes[9];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hFlag = INVALID_HANDLE;
new Handle:g_hDefault = INVALID_HANDLE;
new Handle:g_hDefaultColor = INVALID_HANDLE;
new Handle:g_hDefaultLayout = INVALID_HANDLE;
new Handle:g_hDefaultLifeTime = INVALID_HANDLE;
new Handle:g_hDefaultStarting = INVALID_HANDLE;
new Handle:g_hDefaultEnding = INVALID_HANDLE;
new Handle:g_hDefaultRender = INVALID_HANDLE;
new Handle:g_hDefaultMaterial = INVALID_HANDLE;
new Handle:g_hDefaultVisible = INVALID_HANDLE;
new Handle:g_hConfigColor = INVALID_HANDLE;
new Handle:g_hConfigLayout = INVALID_HANDLE;
new Handle:g_hConfigLifeTime = INVALID_HANDLE;
new Handle:g_hConfigStarting = INVALID_HANDLE;
new Handle:g_hConfigEnding = INVALID_HANDLE;
new Handle:g_hConfigRender = INVALID_HANDLE;
new Handle:g_hConfigMaterial = INVALID_HANDLE;
new Handle:g_hConfigVisible = INVALID_HANDLE;
new Handle:g_hChatCommands = INVALID_HANDLE;
new Handle:g_cEnabled = INVALID_HANDLE;
new Handle:g_cColor = INVALID_HANDLE;
new Handle:g_cStartingWidth = INVALID_HANDLE;
new Handle:g_cEndingWidth = INVALID_HANDLE;
new Handle:g_cLifeTime = INVALID_HANDLE;
new Handle:g_cRenderMode = INVALID_HANDLE;
new Handle:g_cLayout = INVALID_HANDLE;
new Handle:g_cMaterial = INVALID_HANDLE;
new Handle:g_cVisible = INVALID_HANDLE;

new g_iTrailOwner[2049];

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bFake[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new g_iTrailCount[MAXPLAYERS + 1];
new bool:g_bValid[MAXPLAYERS + 1];
new bool:g_bTrailsAppear[MAXPLAYERS + 1];
new g_iTrailData[MAXPLAYERS + 1][INDEX_TOTAL];
new Handle:g_hArray_Trails[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

new g_iDefaultColor, g_iDefaultLayout, g_iDefaultLifeTime, g_iDefaultStarting, g_iDefaultEnding, g_iDefaultRender, g_iDefaultMaterial, g_iDefaultVisible, g_iNumCommands, g_iFlag;
new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bDefault, bool:g_bEnding, bool:g_bConfigColor, bool:g_bConfigLayout, bool:g_bConfigLifeTime, bool:g_bConfigStarting, bool:g_bConfigEnding, bool:g_bConfigRender, bool:g_bConfigMaterial, bool:g_bConfigVisible;
new String:g_sChatCommands[16][32], String:g_sPrefixChat[128], String:g_sPrefixSelect[16], String:g_sPrefixEmpty[16];

public Plugin:myinfo =
{
	name = "CSS Supporters: Trails", 
	author = "Twisted|Panda", 
	description = "Provides simple and advanced functionality for attaching env_spritetrails to players with various configurations.", 
	version = PLUGIN_VERSION, 
	url = "http://ominousgaming.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("css_supporter_trails.phrases");

	CreateConVar("css_trails_version", PLUGIN_VERSION, "Supporter Trails: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_trails_enabled", "1", "Enables/Disables all features of this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hFlag = CreateConVar("css_trails_flag", "", "If \"\", everyone can use Supporter Trails, otherwise, only players with this flag or the \"Trails_Access\" override can access.", FCVAR_NONE);
	HookConVarChange(g_hFlag, OnSettingsChange);
	g_hChatCommands = CreateConVar("css_trails_commands", "!trail, !trails, /trail, /trails", "The chat triggers available to clients to access trail features.", FCVAR_NONE);
	HookConVarChange(g_hChatCommands, OnSettingsChange);
	
	g_hDefault = CreateConVar("css_trails_default", "1", "The default trail status that is set to new clients.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hDefault, OnSettingsChange);
	g_hDefaultColor = CreateConVar("css_trails_default_color", "-1", "The default color index to be applied to new players or upon css_trails_config_color being set to 0. (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultColor, OnSettingsChange);
	g_hDefaultLayout = CreateConVar("css_trails_default_layout", "0", "The default layout index to be applied to new players or upon css_trails_config_layout being set to 0. (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultLayout, OnSettingsChange);
	g_hDefaultLifeTime = CreateConVar("css_trails_default_lifetime", "14", "The default lifetime index to be applied to new players or upon css_trails_config_lifetime being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultLifeTime, OnSettingsChange);
	g_hDefaultStarting = CreateConVar("css_trails_default_starting", "33", "The default starting width index to be applied to new players or upon css_trails_config_starting being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultStarting, OnSettingsChange);
	g_hDefaultEnding = CreateConVar("css_trails_default_ending", "0", "The default ending width index to be applied to new players or upon css_trails_config_ending being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultEnding, OnSettingsChange);
	g_hDefaultRender = CreateConVar("css_trails_default_render", "2", "The default render index to be applied to new players or upon css_trails_config_render being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultRender, OnSettingsChange);
	g_hDefaultMaterial = CreateConVar("css_trails_default_material", "-1", "The default material index to be applied to new players or upon css_trails_config_material being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultMaterial, OnSettingsChange);
	g_hDefaultVisible = CreateConVar("css_trails_default_visible", "2", "The default visibility index applied to new players. (0 = Player Only, 1 = Team Only, 2 = All)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hDefaultVisible, OnSettingsChange);
	g_hConfigColor = CreateConVar("css_trails_config_color", "1", "If enabled, clients will be able to change the color of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigColor, OnSettingsChange);
	g_hConfigLayout = CreateConVar("css_trails_config_layout", "1", "If enabled, clients will be able to change the layout of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigLayout, OnSettingsChange);
	g_hConfigLifeTime = CreateConVar("css_trails_config_lifetime", "1", "If enabled, clients will be able to change the lifetime of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigLifeTime, OnSettingsChange);
	g_hConfigStarting = CreateConVar("css_trails_config_starting", "1", "If enabled, clients will be able to change the starting width of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigStarting, OnSettingsChange);
	g_hConfigEnding = CreateConVar("css_trails_config_ending", "1", "If enabled, clients will be able to change the ending width of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigEnding, OnSettingsChange);
	g_hConfigRender = CreateConVar("css_trails_config_render", "1", "If enabled, clients will be able to change the render mode of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigRender, OnSettingsChange);
	g_hConfigMaterial = CreateConVar("css_trails_config_material", "1", "If enabled, clients will be able to change the material of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigMaterial, OnSettingsChange);
	g_hConfigVisible = CreateConVar("css_trails_config_visible", "1", "If enabled, clients will be able to change the visibility status of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigVisible, OnSettingsChange);
	AutoExecConfig(true, "css_supporter_trails");
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);

	SetCookieMenuItem(Menu_Cookies, 0, "Trail Settings");
	g_cEnabled = RegClientCookie("SupporterTrails_Enabled", "Supporter Trails: The client's trail status.", CookieAccess_Protected);
	g_cColor = RegClientCookie("SupporterTrails_Color", "Supporter Trails: The client's selected trail color.", CookieAccess_Protected);
	g_cStartingWidth = RegClientCookie("SupporterTrails_Starting", "Supporter Trails: The client's selected starting trail width.", CookieAccess_Protected);
	g_cEndingWidth = RegClientCookie("SupporterTrails_Ending", "Supporter Trails: The client's selected ending trail width.", CookieAccess_Protected);
	g_cLifeTime = RegClientCookie("SupporterTrails_Life", "Supporter Trails: The client's selected LifeTime value.", CookieAccess_Protected);
	g_cRenderMode = RegClientCookie("SupporterTrails_Rendering", "Supporter Trails: The client's selected rendering mode.", CookieAccess_Protected);
	g_cLayout = RegClientCookie("SupporterTrails_Layout", "Supporter Trails: The client's selected layout.", CookieAccess_Protected);
	g_cMaterial = RegClientCookie("SupporterTrails_Material", "Supporter Trails: The client's selected material.", CookieAccess_Protected);
	g_cVisible = RegClientCookie("SupporterTrails_Visible", "Supporter Trails: The client's selected visibility.", CookieAccess_Protected);

	RegAdminCmd("css_trails_print", Command_Print, ADMFLAG_RCON, "Usage: css_trails_print, prints indexes to be used with css_trails_default_* cvars.");

	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_bDefault = GetConVarInt(g_hDefault) ? true : false;
	g_iDefaultColor = GetConVarInt(g_hDefaultColor);
	g_iDefaultLayout = GetConVarInt(g_hDefaultLayout);
	g_iDefaultLifeTime = GetConVarInt(g_hDefaultLifeTime);
	g_iDefaultStarting = GetConVarInt(g_hDefaultStarting);
	g_iDefaultEnding = GetConVarInt(g_hDefaultEnding);
	g_iDefaultRender = GetConVarInt(g_hDefaultRender);
	g_iDefaultMaterial = GetConVarInt(g_hDefaultMaterial);
	g_iDefaultVisible = GetConVarInt(g_hDefaultVisible);
	g_bConfigColor = GetConVarInt(g_hConfigColor) ? true : false;
	g_bConfigLayout = GetConVarInt(g_hConfigLayout) ? true : false;
	g_bConfigLifeTime = GetConVarInt(g_hConfigLifeTime) ? true : false;
	g_bConfigStarting = GetConVarInt(g_hConfigStarting) ? true : false;
	g_bConfigEnding = GetConVarInt(g_hConfigEnding) ? true : false;
	g_bConfigRender = GetConVarInt(g_hConfigRender) ? true : false;
	g_bConfigMaterial = GetConVarInt(g_hConfigMaterial) ? true : false;
	g_bConfigVisible = GetConVarInt(g_hConfigVisible) ? true : false;

	decl String:_sTemp[192];
	GetConVarString(g_hChatCommands, _sTemp, sizeof(_sTemp));
	g_iNumCommands = ExplodeString(_sTemp, ", ", g_sChatCommands, 16, 32);
	GetConVarString(g_hFlag, _sTemp, sizeof(_sTemp));
	g_iFlag = ReadFlagString(_sTemp);

	if(g_iDefaultColor >= g_iNumColors)
		g_iDefaultColor = (g_iNumColors - 1);
	if(g_iDefaultLayout >= g_iNumLayouts)
		g_iDefaultLayout = (g_iNumLayouts - 1);
	if(g_iDefaultLifeTime >= g_iLifeTimes)
		g_iDefaultLifeTime = (g_iLifeTimes - 1);
	if(g_iDefaultStarting >= g_iStartWidths)
		g_iDefaultStarting = (g_iStartWidths - 1);
	if(g_iDefaultEnding >= g_iEndWidths)
		g_iDefaultEnding = (g_iEndWidths - 1);
	if(g_iDefaultRender >= g_iRenderModes)
		g_iDefaultRender = (g_iRenderModes - 1);
	if(g_iDefaultMaterial >= g_iMaterials)
		g_iDefaultMaterial = (g_iMaterials - 1);
}

public OnPluginEnd()
{
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			Void_KillTrails(i);
}

public OnEntityDestroyed(entity)
{
	if(g_bEnabled)
	{
		if(entity > 0)
		{
			g_iTrailOwner[entity] = 0;
		}
	}
}

public OnMapStart()
{	
	if(g_bEnabled)
	{
		Void_LoadColors();
		Void_LoadLayouts();
		Void_LoadConfigs();
		Void_LoadMaterials();

		Void_Prepare();
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Format(g_sPrefixChat, sizeof(g_sPrefixChat), "%T", "Prefix_Chat", LANG_SERVER);
		Format(g_sPrefixSelect, sizeof(g_sPrefixSelect), "%T", "Menu_Option_Selected", LANG_SERVER);
		Format(g_sPrefixEmpty, sizeof(g_sPrefixEmpty), "%T", "Menu_Option_Empty", LANG_SERVER);

		for(new i = 1; i <= MaxClients; i++)
			if(g_hArray_Trails[i] == INVALID_HANDLE)
				g_hArray_Trails[i] = CreateArray();

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i);
					g_bFake[i] = IsFakeClient(i) ? true : false;
					if(!g_iFlag || CheckCommandAccess(i, "Trails_Access", g_iFlag))
					{
						g_bValid[i] = true;

						if(!g_bFake[i])
						{
							if(!g_bLoaded[i] && AreClientCookiesCached(i))
								Void_LoadCookies(i);
						}
						else
						{
							g_bLoaded[i] = true;
							g_bTrailsAppear[i] = g_bDefault;

							g_iTrailData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
							g_iTrailData[i][INDEX_LAYOUT] = g_iDefaultLayout == -1 ? GetRandomInt(0, (g_iNumLayouts - 1)) : g_iDefaultLayout;
							g_iTrailData[i][INDEX_START] = g_iDefaultStarting == -1 ? GetRandomInt(0, (g_iStartWidths - 1)) : g_iDefaultStarting;
							g_iTrailData[i][INDEX_END] = g_iDefaultEnding == -1 ? GetRandomInt(0, (g_iEndWidths - 1)) : g_iDefaultEnding;
							g_iTrailData[i][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iLifeTimes - 1)) : g_iDefaultLifeTime;
							g_iTrailData[i][INDEX_RENDER] = g_iDefaultRender == -1 ? GetRandomInt(0, 5) : g_iDefaultRender;
							g_iTrailData[i][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
						}
					}

					if(g_bLoaded[i] && g_bAlive[i] && g_iTeam[i] >= CS_TEAM_T && g_bTrailsAppear[i])
						Void_AttachTrails(i);
				}
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		g_bFake[client] = IsFakeClient(client) ? true : false;
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled && IsClientInGame(client))
	{
		if(!g_iFlag || CheckCommandAccess(client, "Trails_Access", g_iFlag))
		{
			g_bValid[client] = true;
			if(!g_bFake[client])
			{
				if(!g_bLoaded[client] && AreClientCookiesCached(client))
					Void_LoadCookies(client);
			}
			else
			{
				g_bLoaded[client] = true;
				g_bTrailsAppear[client] = g_bDefault;

				g_iTrailData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
				g_iTrailData[client][INDEX_LAYOUT] = g_iDefaultLayout == -1 ? GetRandomInt(0, (g_iNumLayouts - 1)) : g_iDefaultLayout;
				g_iTrailData[client][INDEX_START] = g_iDefaultStarting == -1 ? GetRandomInt(0, (g_iStartWidths - 1)) : g_iDefaultStarting;
				g_iTrailData[client][INDEX_END] = g_iDefaultEnding == -1 ? GetRandomInt(0, (g_iEndWidths - 1)) : g_iDefaultEnding;
				g_iTrailData[client][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iLifeTimes - 1)) : g_iDefaultLifeTime;
				g_iTrailData[client][INDEX_RENDER] = g_iDefaultRender == -1 ? GetRandomInt(0, 5) : g_iDefaultRender;
				g_iTrailData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
				g_iTrailData[client][INDEX_VISIBLE] = g_iDefaultVisible;
			}

			if(g_bLoaded[client] && g_bAlive[client] && g_iTeam[client] >= CS_TEAM_T && g_bTrailsAppear[client] && !g_iTrailCount[client])
				Void_AttachTrails(client);
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_bAlive[client] = false;
		g_bLoaded[client] = false;
		g_bValid[client] = false;
		g_bTrailsAppear[client] = false;

		Void_KillTrails(client);
	}
}

public OnClientCookiesCached(client)
{
	if(g_bValid[client] && !g_bLoaded[client] && !g_bFake[client])
	{
		Void_LoadCookies(client);
		if(!g_bEnding && g_bAlive[client] && g_iTeam[client] >= CS_TEAM_T && g_bTrailsAppear[client] && !g_iTrailCount[client])
			Void_AttachTrails(client);
	}
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] <= CS_TEAM_SPECTATOR)
		{
			g_bAlive[client] = false;
			if(g_bValid[client])
				Void_KillTrails(client);
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client) || g_iTeam[client] <= CS_TEAM_SPECTATOR)
			return Plugin_Continue;
		
		g_bAlive[client] = true;
		if(g_bValid[client] && g_bLoaded[client] && g_bTrailsAppear[client])
			CreateTimer(0.1, Timer_Attach, GetClientUserId(client));
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client))
			return Plugin_Continue;
		
		g_bAlive[client] = false;
		if(g_bValid[client])
			Void_KillTrails(client);
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = false;
	//	for(new i = 1; i <= MaxClients; i++)
	//		if(g_bAlive[i] && IsClientInGame(i) && g_bValid[i] && g_bTrailsAppear[i] && !g_iTrailCount[i])
	//			Void_AttachTrails(i);
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = true;
		for(new i = 1; i <= MaxClients; i++)
			if(g_bAlive[i] && IsClientInGame(i))
				Void_KillTrails(i);
	}

	return Plugin_Continue;
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(client <= 0 || !IsClientInGame(client) || !g_bValid[client])
			return Plugin_Continue;

		decl String:_sText[192];
		GetCmdArgString(_sText, sizeof(_sText));
		StripQuotes(_sText);

		for(new i = 0; i < g_iNumCommands; i++)
		{
			if(StrEqual(_sText, g_sChatCommands[i], false))
			{
				Menu_Trails(client);
				return Plugin_Stop;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Command_Print(client, args)
{
	ReplyToCommand(client, "%sPlease check your console for index data.", g_sPrefixChat);
	new _iArray[2];
	_iArray[0] = client ? GetClientUserId(client) : 0;
	for(_iArray[1] = 1; _iArray[1] <= 7; _iArray[1]++)
	{
		new Handle:_hPack = CreateDataPack();
		WritePackCell(_hPack, _iArray[0]);
		WritePackCell(_hPack, _iArray[1]);
		CreateTimer((0.1 * float(_iArray[1])), Timer_Print, _hPack);
	}
	
	return Plugin_Handled;
}

public Action:Timer_Attach(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && !g_bEnding && g_bAlive[client] && !g_iTrailCount[client])
		Void_AttachTrails(client);
}

public Action:Timer_Print(Handle:timer, Handle:_hPack)
{
	ResetPack(_hPack);
	new temp = ReadPackCell(_hPack);
	new client = temp > 0 ? GetClientOfUserId(temp) : temp;

	new index = ReadPackCell(_hPack);
	switch(index)
	{
		case 1:
			for(new i = 0; i < g_iNumColors; i++)
				ReplyToCommand(client, "Trails - Colors: Index (%d), Name (%s), Colors (%s)", i, g_sColorNames[i], g_sColorSchemes[i]);
		case 2:
			for(new i = 0; i < g_iNumLayouts; i++)
				ReplyToCommand(client, "Trails - Layouts: Index (%d), Name (%s), Trail Count (%d)", i, g_sLayoutNames[i], g_iLayoutTotals[i]);
		case 3:
			for(new i = 0; i < g_iStartWidths; i++)
				ReplyToCommand(client, "Trails - Start Widths: Index (%d), Value: (%s)", i, g_sStartingWidths[i]);
		case 4:
			for(new i = 0; i < g_iEndWidths; i++)
				ReplyToCommand(client, "Trails - End Widths: Index (%d), Value: (%s)", i, g_sEndingWidths[i]);
		case 5:
			for(new i = 0; i < g_iLifeTimes; i++)
				ReplyToCommand(client, "Trails - Lifetimes: Index (%d), Value: (%s)", i, g_sLifeTimes[i]);
		case 6:
			for(new i = 0; i <= g_iRenderModes; i++)
				ReplyToCommand(client, "Trails - Render Modes: Index (%d), Enabled: (%b)", i, g_bRenderModes[i]);
		case 7:
			for(new i = 0; i < g_iMaterials; i++)
				ReplyToCommand(client, "Trails - Materials: Index (%d), Name: (%s), Path: (%s)", i, g_sMaterialNames[i], g_sMaterialPaths[i]);
	}
	ReplyToCommand(client, "--------------------------");
	CloseHandle(_hPack);
}

Void_AttachTrails(client)
{
	if(g_bLoaded[client])
	{
		decl String:_sTemp[64], String:_sOriginal[64];
		GetEntPropString(client, Prop_Data, "m_iName", _sOriginal, sizeof(_sOriginal));
		Format(_sTemp, sizeof(_sTemp), "SupporterTrails_%d", GetClientUserId(client));
		DispatchKeyValue(client, "targetname", _sTemp);

		decl Float:g_fAngle[3], Float:g_fOrigin[3], Float:_fTemp[3] = {0.0, 90.0, 0.0};
		GetEntPropVector(client, Prop_Data, "m_angAbsRotation", g_fAngle);
		SetEntPropVector(client, Prop_Data, "m_angAbsRotation", _fTemp);

		g_iTrailCount[client] = g_iLayoutTotals[g_iTrailData[client][INDEX_LAYOUT]];
		for(new i = 1; i <= g_iTrailCount[client]; i++)
		{
			new _iEntity = CreateEntityByName("env_spritetrail");
			if(_iEntity > 0 && IsValidEntity(_iEntity))
			{
				g_iTrailOwner[_iEntity] = client;
				SetEntPropFloat(_iEntity, Prop_Send, "m_flTextureRes", 0.05);

				PushArrayCell(g_hArray_Trails[client], _iEntity);
				DispatchKeyValue(_iEntity, "parentname", _sTemp);
				DispatchKeyValue(_iEntity, "renderamt", "255");
				DispatchKeyValue(_iEntity, "rendercolor", g_sColorSchemes[g_iTrailData[client][INDEX_COLOR]]);
				DispatchKeyValue(_iEntity, "spritename", g_sMaterialPaths[g_iTrailData[client][INDEX_MATERIAL]]);
				DispatchKeyValue(_iEntity, "lifetime", g_sLifeTimes[g_iTrailData[client][INDEX_LIFE]]);
				DispatchKeyValue(_iEntity, "startwidth", g_sStartingWidths[g_iTrailData[client][INDEX_START]]);
				DispatchKeyValue(_iEntity, "endwidth", g_sEndingWidths[g_iTrailData[client][INDEX_END]]);
				DispatchKeyValue(_iEntity, "rendermode", g_sRenderModes[g_iTrailData[client][INDEX_RENDER]]);
				DispatchSpawn(_iEntity);

				GetClientAbsOrigin(client, g_fOrigin);
				AddVectors(g_fOrigin, g_fLayoutPositions[g_iTrailData[client][INDEX_LAYOUT]][i], g_fOrigin);
				TeleportEntity(_iEntity, g_fOrigin, _fTemp, NULL_VECTOR);
				SetVariantString(_sTemp);
				AcceptEntityInput(_iEntity, "SetParent", _iEntity, _iEntity);

				SDKHook(_iEntity, SDKHook_SetTransmit, Hook_SetTransmit);
			}
		}
		SetEntPropVector(client, Prop_Data, "m_angAbsRotation", g_fAngle);
		DispatchKeyValue(client, "targetname", _sOriginal);
	}
}

Void_KillTrails(client)
{
	for(new i = 0; i < g_iTrailCount[client]; i++)
	{
		new _iEntity = GetArrayCell(g_hArray_Trails[client], i);
		if(_iEntity > 0 && IsValidEntity(_iEntity))
			AcceptEntityInput(_iEntity, "Kill");
	}

	ClearArray(g_hArray_Trails[client]);
	g_iTrailCount[client] = 0;
}

public Action:Hook_SetTransmit(entity, client)
{
	if(!g_iTrailOwner[entity])
		return Plugin_Continue;
	else
	{
		switch(g_iTrailData[g_iTrailOwner[entity]][INDEX_VISIBLE])
		{
			case VISIBLE_ONE:
			{
				if(g_iTrailOwner[entity] != client)
					return Plugin_Handled;
			}
			case VISIBLE_TEAM:
			{
				if(g_iTeam[client] >= CS_TEAM_T && g_iTeam[client] != g_iTeam[g_iTrailOwner[entity]])
					return Plugin_Handled;
			}
			case VISIBLE_ALL:
				return Plugin_Continue;
		}
	}

	return Plugin_Continue;
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_bEnabled = bool:StringToInt(newvalue);
		if(!g_bEnabled && StringToInt(oldvalue))
			for(new i = 1; i <= MaxClients; i++)
				if(IsClientInGame(i))
					Void_KillTrails(i);
	}
	else if(cvar == g_hFlag)
		g_iFlag = ReadFlagString(newvalue);
	else if(cvar == g_hDefault)
		g_bDefault = bool:StringToInt(newvalue);
	else if(cvar == g_hChatCommands)
		g_iNumCommands = ExplodeString(newvalue, ", ", g_sChatCommands, 16, 32);
	else if(cvar == g_hDefaultColor)
	{
		g_iDefaultColor = StringToInt(newvalue);
		if(g_iDefaultColor >= g_iNumColors)
			g_iDefaultColor = (g_iNumColors - 1);
	}
	else if(cvar == g_hDefaultLayout)
	{
		g_iDefaultLayout = StringToInt(newvalue);
		if(g_iDefaultLayout >= g_iNumLayouts)
			g_iDefaultLayout = (g_iNumLayouts - 1);
	}
	else if(cvar == g_hDefaultLifeTime)
	{
		g_iDefaultLifeTime = StringToInt(newvalue);
		if(g_iDefaultLifeTime >= g_iLifeTimes)
			g_iDefaultLifeTime = (g_iLifeTimes - 1);
	}
	else if(cvar == g_hDefaultStarting)
	{
		g_iDefaultStarting = StringToInt(newvalue);
		if(g_iDefaultStarting >= g_iStartWidths)
			g_iDefaultStarting = (g_iStartWidths - 1);
	}
	else if(cvar == g_hDefaultEnding)
	{
		g_iDefaultEnding = StringToInt(newvalue);
		if(g_iDefaultEnding >= g_iEndWidths)
			g_iDefaultEnding = (g_iEndWidths - 1);
	}
	else if(cvar == g_hDefaultRender)
	{
		g_iDefaultRender = StringToInt(newvalue);
		if(g_iDefaultRender >= g_iRenderModes)
			g_iDefaultRender = (g_iRenderModes - 1);
	}
	else if(cvar == g_hDefaultMaterial)
	{
		g_iDefaultMaterial = StringToInt(newvalue);
		if(g_iDefaultMaterial >= g_iMaterials)
			g_iDefaultMaterial = (g_iMaterials - 1);
	}
	else if(cvar == g_hDefaultVisible)
		g_iDefaultVisible = StringToInt(newvalue);
	else if(cvar == g_hConfigColor)
		g_bConfigColor = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigLayout)
		g_bConfigLayout = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigLifeTime)
		g_bConfigLifeTime = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigStarting)
		g_bConfigStarting = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigEnding)
		g_bConfigEnding = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigRender)
		g_bConfigRender = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigMaterial)
		g_bConfigMaterial = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigVisible)
		g_bConfigVisible = bool:StringToInt(newvalue);
}

Void_LoadColors()
{
	decl String:_sPath[PLATFORM_MAX_PATH], String:_sBuffer[64];
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/trails/css_trails_colors.ini");

	new _iCurrent = GetFileTime(_sPath, FileTime_LastChange);
	if(_iCurrent < g_iLoadColors)
		return;
	else
		g_iLoadColors = _iCurrent;
	
	g_iNumColors = 0;
	new Handle:_hKV = CreateKeyValues("SupporterTrails_Colors");
	if(FileToKeyValues(_hKV, _sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, g_sColorNames[g_iNumColors], sizeof(g_sColorNames[]));
			KvGetString(_hKV, "Color", g_sColorSchemes[g_iNumColors], sizeof(g_sColorSchemes[]));
			KvGetString(_hKV, "Flag", _sBuffer, sizeof(_sBuffer));
			g_iColorFlag[g_iNumColors] = ReadFlagString(_sBuffer);
			g_iNumColors++;
		}
		while (KvGotoNextKey(_hKV));
	}
	else
		SetFailState("FileToKeyValues(\"configs/trails/css_trails_colors.ini\") doesn't appear to exist or is invalid.");
	
	CloseHandle(_hKV);
}

Void_LoadLayouts()
{
	decl String:_sPath[PLATFORM_MAX_PATH], String:_sBuffer[64];
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/trails/css_trails_layouts.ini");
	
	new _iCurrent = GetFileTime(_sPath, FileTime_LastChange);
	if(_iCurrent < g_iLoadLayouts)
		return;
	else
		g_iLoadLayouts = _iCurrent;

	g_iNumLayouts = 0;	
	new Handle:_hKV = CreateKeyValues("SupporterTrails_Layouts");
	if(FileToKeyValues(_hKV, _sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, g_sLayoutNames[g_iNumLayouts], sizeof(g_sLayoutNames[]));
			KvGetString(_hKV, "Flag", _sBuffer, sizeof(_sBuffer));
			g_iLayoutFlag[g_iNumLayouts] = ReadFlagString(_sBuffer);

			g_iLayoutTotals[g_iNumLayouts] = 0;
			for(new i = 1; i <= MAX_DEFINED_LAYOUTS; i++)
			{
				IntToString(i, _sPath, sizeof(_sPath));
				KvGetString(_hKV, _sPath, _sPath, sizeof(_sPath));
				if(!StrEqual(_sPath, "", false))
				{
					g_iLayoutTotals[g_iNumLayouts]++;
					decl String:_sBuffer2[3][8];
					
					ExplodeString(_sPath, " ", _sBuffer2, 3, 8);
					for(new j = 0; j <= 2; j++)
						g_fLayoutPositions[g_iNumLayouts][i][j] = StringToFloat(_sBuffer2[j]);
				}
			}
			
			g_iNumLayouts++;
		}
		while (KvGotoNextKey(_hKV));
	}
	else
		SetFailState("FileToKeyValues(\"configs/trails/css_trails_layouts.ini\") doesn't appear to exist or is invalid.");
	
	CloseHandle(_hKV);
}

Void_LoadMaterials()
{
	decl String:_sPath[PLATFORM_MAX_PATH], String:_sBuffer[64];
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/trails/css_trails_materials.ini");
	
	new _iCurrent = GetFileTime(_sPath, FileTime_LastChange);
	if(_iCurrent < g_iLoadMaterials)
		return;
	else
		g_iLoadMaterials = _iCurrent;
	
	g_iMaterials = 0;
	new Handle:_hKV = CreateKeyValues("SupporterTrails_Materials");
	if(FileToKeyValues(_hKV, _sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, g_sMaterialNames[g_iMaterials], sizeof(g_sMaterialNames[]));
			KvGetString(_hKV, "Path", g_sMaterialPaths[g_iMaterials], sizeof(g_sMaterialPaths[]));
			KvGetString(_hKV, "Flag", _sBuffer, sizeof(_sBuffer));
			g_iMaterialFlag[g_iMaterials] = ReadFlagString(_sBuffer);
			g_iMaterials++;
		}
		while (KvGotoNextKey(_hKV));
	}
	else
		SetFailState("FileToKeyValues(\"configs/trails/css_trails_materials.ini\") doesn't appear to exist or is invalid.");
	
	CloseHandle(_hKV);
}

Void_LoadConfigs()
{
	decl String:_sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/trails/css_trails_configs.ini");
	
	new _iCurrent = GetFileTime(_sPath, FileTime_LastChange);
	if(_iCurrent < g_iLoadConfigs)
		return;
	else
		g_iLoadConfigs = _iCurrent;
	
	g_iStartWidths = g_iEndWidths = g_iLifeTimes = g_iRenderModes = 0;
	new Handle:_hKV = CreateKeyValues("SupporterTrails_Configs");
	if(FileToKeyValues(_hKV, _sPath))
	{
		decl String:_sTemp[8];
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, _sPath, sizeof(_sPath));
			if(StrEqual(_sPath, "Start_Widths", false))
			{
				KvGetString(_hKV, "accurate_count", _sTemp, sizeof(_sTemp));
				new Float:_fAccurateCount = StringToFloat(_sTemp);
				if(_fAccurateCount)
				{
					KvGetString(_hKV, "accurate_factor", _sTemp, sizeof(_sTemp));
					new Float:_fAccurateFactor = StringToFloat(_sTemp);

					for(new Float:i = 1.0; i <= _fAccurateCount; i++)
					{
						FloatToString((_fAccurateFactor * i), _sTemp, sizeof(_sTemp));
						g_sStartingWidths[g_iStartWidths++] = _sTemp;
					}
				}
				
				KvGetString(_hKV, "regular_count", _sTemp, sizeof(_sTemp));
				new Float:_fRegularCount = StringToFloat(_sTemp);
				if(_fRegularCount)
				{
					KvGetString(_hKV, "regular_factor", _sTemp, sizeof(_sTemp));
					new Float:_fRegularFactor = StringToFloat(_sTemp);
					
					for(new Float:i = 1.0; i <= _fRegularCount; i++)
					{
						FloatToString((_fRegularFactor * i), _sTemp, sizeof(_sTemp));
						g_sStartingWidths[g_iStartWidths++] = _sTemp;
					}
				}
			}
			else if(StrEqual(_sPath, "End_Widths", false))
			{
				KvGetString(_hKV, "accurate_count", _sTemp, sizeof(_sTemp));
				new Float:_fAccurateCount = StringToFloat(_sTemp);
				if(_fAccurateCount)
				{
					KvGetString(_hKV, "accurate_factor", _sTemp, sizeof(_sTemp));
					new Float:_fAccurateFactor = StringToFloat(_sTemp);
					
					for(new Float:i = 1.0; i <= _fAccurateCount; i++)
					{
						FloatToString((_fAccurateFactor * i), _sTemp, sizeof(_sTemp));
						g_sEndingWidths[g_iEndWidths++] = _sTemp;
					}
				}
				
				KvGetString(_hKV, "regular_count", _sTemp, sizeof(_sTemp));
				new Float:_fRegularCount = StringToFloat(_sTemp);
				if(_fRegularCount)
				{
					KvGetString(_hKV, "regular_factor", _sTemp, sizeof(_sTemp));
					new Float:_fRegularFactor = StringToFloat(_sTemp);
	
					for(new Float:i = 1.0; i <= _fRegularCount; i++)
					{
						FloatToString((_fRegularFactor * i), _sTemp, sizeof(_sTemp));
						g_sEndingWidths[g_iEndWidths++] = _sTemp;
					}
				}
			}
			else if(StrEqual(_sPath, "LifeTimes", false))
			{
				KvGetString(_hKV, "accurate_count", _sTemp, sizeof(_sTemp));
				new Float:_fAccurateCount = StringToFloat(_sTemp);
				if(_fAccurateCount)
				{
					KvGetString(_hKV, "accurate_factor", _sTemp, sizeof(_sTemp));
					new Float:_fAccurateFactor = StringToFloat(_sTemp);
					
					for(new Float:i = 1.0; i <= _fAccurateCount; i++)
					{
						FloatToString((_fAccurateFactor * i), _sTemp, sizeof(_sTemp));
						g_sLifeTimes[g_iLifeTimes++] = _sTemp;
					}
				}
				
				KvGetString(_hKV, "regular_count", _sTemp, sizeof(_sTemp));
				new Float:_fRegularCount = StringToFloat(_sTemp);
				if(_fRegularCount)
				{
					KvGetString(_hKV, "regular_factor", _sTemp, sizeof(_sTemp));
					new Float:_fRegularFactor = StringToFloat(_sTemp);
					
					for(new Float:i = 1.0; i <= _fRegularCount; i++)
					{
						FloatToString((_fRegularFactor * i), _sTemp, sizeof(_sTemp));
						g_sLifeTimes[g_iLifeTimes++] = _sTemp;
					}
				}
			}
			else if(StrEqual(_sPath, "Render_Modes", false))
			{
				for(new i = 0; i <= 8; i++)
				{
					IntToString(i, _sTemp, sizeof(_sTemp));
					KvGetString(_hKV, _sTemp, _sTemp, sizeof(_sTemp));
					g_bRenderModes[i] = StringToInt(_sTemp) ? true : false;
					if(g_bRenderModes[i])
						g_iRenderModes++;
				}
			}
		}
		while (KvGotoNextKey(_hKV));
	}
	else
		SetFailState("FileToKeyValues(\"configs/trails/css_trails_configs.ini\") doesn't appear to exist or is invalid.");
	
	CloseHandle(_hKV);
}

Void_Prepare()
{
	for(new i = 0; i < g_iMaterials; i++)
	{
		decl String:_sBuffer[PLATFORM_MAX_PATH];
		strcopy(_sBuffer, sizeof(_sBuffer), g_sMaterialPaths[i]);
		PrecacheModel(_sBuffer, true);
		AddFileToDownloadsTable(_sBuffer);
		ReplaceString(_sBuffer, sizeof(_sBuffer), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(_sBuffer);
	}
}

Void_LoadCookies(client)
{
	new String:_sCookie[4];
	GetClientCookie(client, g_cEnabled, _sCookie, sizeof(_sCookie));

	if(StrEqual(_sCookie, ""))
	{
		_sCookie = g_bDefault ? "1" : "0";
		g_bTrailsAppear[client] = StringToInt(_sCookie) ? true : false;
		SetClientCookie(client, g_cEnabled, _sCookie);

		g_iTrailData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
		IntToString(g_iTrailData[client][INDEX_COLOR], _sCookie, 4);
		SetClientCookie(client, g_cColor, _sCookie);

		g_iTrailData[client][INDEX_LAYOUT] = g_iDefaultLayout == -1 ? GetRandomInt(0, (g_iNumLayouts - 1)) : g_iDefaultLayout;
		IntToString(g_iTrailData[client][INDEX_LAYOUT], _sCookie, 4);
		SetClientCookie(client, g_cLayout, _sCookie);

		g_iTrailData[client][INDEX_START] = g_iDefaultStarting == -1 ? GetRandomInt(0, (g_iStartWidths - 1)) : g_iDefaultStarting;
		IntToString(g_iTrailData[client][INDEX_START], _sCookie, 4);
		SetClientCookie(client, g_cStartingWidth, _sCookie);

		g_iTrailData[client][INDEX_END] = g_iDefaultEnding == -1 ? GetRandomInt(0, (g_iEndWidths - 1)) : g_iDefaultEnding;
		IntToString(g_iTrailData[client][INDEX_END], _sCookie, 4);
		SetClientCookie(client, g_cEndingWidth, _sCookie);

		g_iTrailData[client][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iLifeTimes - 1)) : g_iDefaultLifeTime;
		IntToString(g_iTrailData[client][INDEX_LIFE], _sCookie, 4);
		SetClientCookie(client, g_cLifeTime, _sCookie);

		g_iTrailData[client][INDEX_RENDER] = g_iDefaultRender == -1 ? GetRandomInt(0, 5) : g_iDefaultRender;
		IntToString(g_iTrailData[client][INDEX_RENDER], _sCookie, 4);
		SetClientCookie(client, g_cRenderMode, _sCookie);

		g_iTrailData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
		IntToString(g_iTrailData[client][INDEX_MATERIAL], _sCookie, 4);
		SetClientCookie(client, g_cMaterial, _sCookie);

		g_iTrailData[client][INDEX_VISIBLE] = g_iDefaultVisible;
		IntToString(g_iTrailData[client][INDEX_VISIBLE], _sCookie, 4);
		SetClientCookie(client, g_cVisible, _sCookie);
	}
	else
	{
		g_bTrailsAppear[client] = StringToInt(_sCookie) ? true : false;

		if(g_bConfigColor)
		{
			GetClientCookie(client, g_cColor, _sCookie, 4);
			g_iTrailData[client][INDEX_COLOR] = StringToInt(_sCookie);
			if(g_iTrailData[client][INDEX_COLOR] >= g_iNumColors || g_iTrailData[client][INDEX_COLOR] < 0)
			{
				g_iTrailData[client][INDEX_COLOR] = (g_iNumColors - 1);
				IntToString(g_iTrailData[client][INDEX_COLOR], _sCookie, 4);
				SetClientCookie(client, g_cColor, _sCookie);
			}
		}
		else
			g_iTrailData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;

		if(g_bConfigLayout)
		{
			GetClientCookie(client, g_cLayout, _sCookie, 4);
			g_iTrailData[client][INDEX_LAYOUT] = StringToInt(_sCookie);
			if(g_iTrailData[client][INDEX_LAYOUT] >= g_iNumLayouts || g_iTrailData[client][INDEX_LAYOUT] < 0)
			{
				g_iTrailData[client][INDEX_LAYOUT] = (g_iNumLayouts - 1);
				IntToString(g_iTrailData[client][INDEX_LAYOUT], _sCookie, 4);
				SetClientCookie(client, g_cLayout, _sCookie);
			}
		}
		else
			g_iTrailData[client][INDEX_LAYOUT] = g_iDefaultLayout == -1 ? GetRandomInt(0, (g_iNumLayouts - 1)) : g_iDefaultLayout;

		if(g_bConfigStarting)
		{
			GetClientCookie(client, g_cStartingWidth, _sCookie, 4);
			g_iTrailData[client][INDEX_START] = StringToInt(_sCookie);
			if(g_iTrailData[client][INDEX_START] >= g_iStartWidths || g_iTrailData[client][INDEX_START] < 0)
			{
				g_iTrailData[client][INDEX_START] = (g_iStartWidths - 1);
				IntToString(g_iTrailData[client][INDEX_START], _sCookie, 4);
				SetClientCookie(client, g_cStartingWidth, _sCookie);
			}
		}
		else
			g_iTrailData[client][INDEX_START] = g_iDefaultStarting == -1 ? GetRandomInt(0, (g_iStartWidths - 1)) : g_iDefaultStarting;

		if(g_bConfigEnding)
		{
			GetClientCookie(client, g_cEndingWidth, _sCookie, 4);
			g_iTrailData[client][INDEX_END] = StringToInt(_sCookie);
			if(g_iTrailData[client][INDEX_END] >= g_iEndWidths || g_iTrailData[client][INDEX_END] < 0)
			{
				g_iTrailData[client][INDEX_END] = (g_iEndWidths - 1);
				IntToString(g_iTrailData[client][INDEX_END], _sCookie, 4);
				SetClientCookie(client, g_cEndingWidth, _sCookie);
			}
		}
		else
			g_iTrailData[client][INDEX_END] = g_iDefaultEnding == -1 ? GetRandomInt(0, (g_iEndWidths - 1)) : g_iDefaultEnding;

		if(g_bConfigLifeTime)
		{
			GetClientCookie(client, g_cLifeTime, _sCookie, 4);
			g_iTrailData[client][INDEX_LIFE] = StringToInt(_sCookie);
			if(g_iTrailData[client][INDEX_LIFE] >= g_iLifeTimes || g_iTrailData[client][INDEX_LIFE] < 0)
			{
				g_iTrailData[client][INDEX_LIFE] = (g_iLifeTimes - 1);
				IntToString(g_iTrailData[client][INDEX_LIFE], _sCookie, 4);
				SetClientCookie(client, g_cLifeTime, _sCookie);
			}
		}
		else
			g_iTrailData[client][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iLifeTimes - 1)) : g_iDefaultLifeTime;

		if(g_bConfigRender)
		{
			GetClientCookie(client, g_cRenderMode, _sCookie, 4);
			g_iTrailData[client][INDEX_RENDER] = StringToInt(_sCookie);
			if(g_iTrailData[client][INDEX_RENDER] >= g_iRenderModes || g_iTrailData[client][INDEX_RENDER] < 0)
			{
				g_iTrailData[client][INDEX_RENDER] = (g_iRenderModes - 1);
				IntToString(g_iTrailData[client][INDEX_RENDER], _sCookie, 4);
				SetClientCookie(client, g_cRenderMode, _sCookie);
			}
		}
		else
			g_iTrailData[client][INDEX_RENDER] = g_iDefaultRender == -1 ? GetRandomInt(0, 5) : g_iDefaultRender;

		if(g_bConfigMaterial)
		{
			GetClientCookie(client, g_cMaterial, _sCookie, 4);
			g_iTrailData[client][INDEX_MATERIAL] = StringToInt(_sCookie);
			if(g_iTrailData[client][INDEX_MATERIAL] >= g_iMaterials || g_iTrailData[client][INDEX_MATERIAL] < 0)
			{
				g_iTrailData[client][INDEX_MATERIAL] = (g_iMaterials - 1);
				IntToString(g_iTrailData[client][INDEX_MATERIAL], _sCookie, 4);
				SetClientCookie(client, g_cMaterial, _sCookie);
			}
		}
		else
			g_iTrailData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
	
		if(g_bConfigVisible)
		{
			GetClientCookie(client, g_cVisible, _sCookie, 4);
			g_iTrailData[client][INDEX_VISIBLE] = StringToInt(_sCookie);
		}
		else
			g_iTrailData[client][INDEX_VISIBLE] = g_iDefaultVisible;
	}

	g_bLoaded[client] = true;
}

public Menu_Cookies(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "%t", "Cookie_Title", client);
		case CookieMenuAction_SelectOption:
		{
			if(g_bEnabled)
				Menu_Trails(client);
		}
	}
}

Menu_Trails(client)
{
	decl String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuTrails);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Main", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);

	new _iState = g_bValid[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	if(g_bTrailsAppear[client])
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Disable", client);
	else
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Enable", client);
	AddMenuItem(_hMenu, "0", _sBuffer, _iState);
	
	if(g_iNumColors > 1 && g_bConfigColor)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Color", client);
		AddMenuItem(_hMenu, "1", _sBuffer, _iState);
	}

	if(g_iMaterials > 1 && g_bConfigMaterial)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Material", client);
		AddMenuItem(_hMenu, "7", _sBuffer, _iState);
	}

	if(g_iStartWidths > 1 && g_bConfigStarting)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Starting", client);
		AddMenuItem(_hMenu, "3", _sBuffer, _iState);
	}
	
	if(g_iEndWidths > 1 && g_bConfigEnding)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Ending", client);
		AddMenuItem(_hMenu, "4", _sBuffer, _iState);
	}
	
	if(g_iLifeTimes > 1 && g_bConfigLifeTime)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Life", client);
		AddMenuItem(_hMenu, "5", _sBuffer, _iState);
	}
	
	if(g_iRenderModes > 1 && g_bConfigRender)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Render", client);
		AddMenuItem(_hMenu, "6", _sBuffer, _iState);
	}

	if(g_iNumLayouts > 1 && g_bConfigLayout)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Layout", client);
		AddMenuItem(_hMenu, "2", _sBuffer, _iState);
	}
	
	if(g_bConfigVisible)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Visibility", client);
		AddMenuItem(_hMenu, "8", _sBuffer, _iState);
	}
	
	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuTrails(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel: 
		{
			if(param2 == MenuCancel_ExitBack)
				ShowCookieMenu(param1);
		}
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));

			switch(StringToInt(_sTemp))
			{
				case 0:
				{
					if(!g_bTrailsAppear[param1])
					{
						g_bTrailsAppear[param1] = true;
						if(g_bAlive[param1] && !g_bEnding)
							Void_AttachTrails(param1);
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Enable");
						SetClientCookie(param1	, g_cEnabled, "1");
					}
					else
					{
						g_bTrailsAppear[param1] = false;
						if(g_bAlive[param1] && !g_bEnding)
							Void_KillTrails(param1);
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Disable");
						SetClientCookie(param1, g_cEnabled, "0");
					}
					
					Menu_Trails(param1);
				}
				case 1:
					Menu_Colors(param1);
				case 2:
					Menu_Layouts(param1);
				case 3:
					Menu_StartingWidths(param1);
				case 4:
					Menu_EndingWidths(param1);
				case 5:
					Menu_LifeTimes(param1);
				case 6:	
					Menu_RenderModes(param1);
				case 7:	
					Menu_Materials(param1);
				case 8:	
					Menu_Visible(param1);
			}
		}
	}
	
	return;
}

Menu_Layouts(client, index = 0)
{
	decl String:_sTemp[8], String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuLayouts);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Layout", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i < g_iNumLayouts; i++)
	{
		if(!g_iLayoutFlag[i] || CheckCommandAccess(client, "Trails_Access_Layouts", g_iLayoutFlag[i]))
		{
			IntToString(i, _sTemp, sizeof(_sTemp));
			Format(_sBuffer, sizeof(_sBuffer), "%s%s", (g_iTrailData[client][INDEX_LAYOUT] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sLayoutNames[i]);
			AddMenuItem(_hMenu, _sTemp, _sBuffer);
		}
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuLayouts(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Trails(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTrailData[param1][INDEX_LAYOUT] = StringToInt(_sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Layout", g_sLayoutNames[g_iTrailData[param1][INDEX_LAYOUT]]);
			if(g_bTrailsAppear[param1] && g_bAlive[param1])
			{
				Void_KillTrails(param1);
				if(!g_bEnding)
					Void_AttachTrails(param1);
			}

			SetClientCookie(param1, g_cLayout, _sTemp);
			Menu_Layouts(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_Colors(client, index = 0)
{
	decl String:_sTemp[8], String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuColors);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Color", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i < g_iNumColors; i++)
	{
		if(!g_iColorFlag[i] || CheckCommandAccess(client, "Trails_Access_Colors", g_iColorFlag[i]))
		{
			IntToString(i, _sTemp, sizeof(_sTemp));
			Format(_sBuffer, sizeof(_sBuffer), "%s%s", (g_iTrailData[client][INDEX_COLOR] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sColorNames[i]);
			AddMenuItem(_hMenu, _sTemp, _sBuffer);
		}
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuColors(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Trails(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTrailData[param1][INDEX_COLOR] = StringToInt(_sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Color", g_sColorNames[g_iTrailData[param1][INDEX_COLOR]]);
			if(g_bTrailsAppear[param1] && g_bAlive[param1])
			{
				for(new i = 0; i < g_iTrailCount[param1]; i++)
				{
					new _iEntity = GetArrayCell(g_hArray_Trails[param1], i);
					if(IsValidEntity(_iEntity))
					{
						DispatchKeyValue(_iEntity, "rendercolor", g_sColorSchemes[g_iTrailData[param1][INDEX_COLOR]]);
						ChangeEdictState(_iEntity, FL_EDICT_CHANGED);
					}
				}
			}

			SetClientCookie(param1, g_cColor, _sTemp);
			Menu_Colors(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_StartingWidths(client, index = 0)
{
	decl String:_sTemp[8], String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuStartingWidths);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Starting", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i < g_iStartWidths; i++)
	{
		IntToString(i, _sTemp, sizeof(_sTemp));
		Format(_sBuffer, sizeof(_sBuffer), "%s%s", (g_iTrailData[client][INDEX_START] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sStartingWidths[i]);
		AddMenuItem(_hMenu, _sTemp, _sBuffer);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuStartingWidths(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Trails(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTrailData[param1][INDEX_START] = StringToInt(_sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Starting", g_sStartingWidths[g_iTrailData[param1][INDEX_START]]);
			if(g_bTrailsAppear[param1] && g_bAlive[param1])
			{
				for(new i = 0; i < g_iTrailCount[param1]; i++)
				{
					new _iEntity = GetArrayCell(g_hArray_Trails[param1], i);
					if(IsValidEntity(_iEntity))
					{
						DispatchKeyValue(_iEntity, "startwidth", g_sStartingWidths[g_iTrailData[param1][INDEX_START]]);
						ChangeEdictState(_iEntity, FL_EDICT_CHANGED);
					}
				}
			}

			SetClientCookie(param1, g_cStartingWidth, _sTemp);
			Menu_StartingWidths(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_EndingWidths(client, index = 0)
{
	decl String:_sTemp[8], String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuEndingWidths);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Ending", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i < g_iEndWidths; i++)
	{
		IntToString(i, _sTemp, sizeof(_sTemp));
		Format(_sBuffer, sizeof(_sBuffer), "%s%s", (g_iTrailData[client][INDEX_END] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sEndingWidths[i]);
		AddMenuItem(_hMenu, _sTemp, _sBuffer);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuEndingWidths(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Trails(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTrailData[param1][INDEX_END] = StringToInt(_sTemp);
			
			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Ending", g_sEndingWidths[g_iTrailData[param1][INDEX_END]]);
			if(g_bTrailsAppear[param1] && g_bAlive[param1])
			{
				for(new i = 0; i < g_iTrailCount[param1]; i++)
				{
					new _iEntity = GetArrayCell(g_hArray_Trails[param1], i);
					if(IsValidEntity(_iEntity))
					{
						DispatchKeyValue(_iEntity, "endwidth", g_sEndingWidths[g_iTrailData[param1][INDEX_END]]);
						ChangeEdictState(_iEntity, FL_EDICT_CHANGED);
					}
				}
			}

			SetClientCookie(param1, g_cEndingWidth, _sTemp);
			Menu_EndingWidths(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_LifeTimes(client, index = 0)
{
	decl String:_sTemp[8], String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuLifeTimes);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Life", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i < g_iLifeTimes; i++)
	{
		IntToString(i, _sTemp, sizeof(_sTemp));
		Format(_sBuffer, sizeof(_sBuffer), "%s%s", (g_iTrailData[client][INDEX_LIFE] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sLifeTimes[i]);
		AddMenuItem(_hMenu, _sTemp, _sBuffer);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuLifeTimes(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Trails(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTrailData[param1][INDEX_LIFE] = StringToInt(_sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Life", g_sLifeTimes[g_iTrailData[param1][INDEX_LIFE]]);
			if(g_bTrailsAppear[param1] && g_bAlive[param1])
			{
				for(new i = 0; i < g_iTrailCount[param1]; i++)
				{
					new _iEntity = GetArrayCell(g_hArray_Trails[param1], i);
					if(IsValidEntity(_iEntity))
					{
						DispatchKeyValue(_iEntity, "lifetime", g_sLifeTimes[g_iTrailData[param1][INDEX_LIFE]]);
						ChangeEdictState(_iEntity, FL_EDICT_CHANGED);
					}
				}
			}

			SetClientCookie(param1, g_cLifeTime, _sTemp);
			Menu_LifeTimes(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_RenderModes(client, index = 0)
{
	decl String:_sTemp[8], String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuRenderModes);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Render", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i <= 8; i++)
	{
		IntToString(i, _sTemp, sizeof(_sTemp));
		Format(_sBuffer, sizeof(_sBuffer), "%sMethod %d", (g_iTrailData[client][INDEX_RENDER] == i) ? g_sPrefixSelect : g_sPrefixEmpty, i);
		AddMenuItem(_hMenu, _sTemp, _sBuffer);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuRenderModes(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Trails(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTrailData[param1][INDEX_RENDER] = StringToInt(_sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Render", g_iTrailData[param1][INDEX_RENDER]);
			if(g_bTrailsAppear[param1] && g_bAlive[param1])
			{
				for(new i = 0; i < g_iTrailCount[param1]; i++)
				{
					new _iEntity = GetArrayCell(g_hArray_Trails[param1], i);
					if(IsValidEntity(_iEntity))
					{
						DispatchKeyValue(_iEntity, "rendermode", _sTemp);
						ChangeEdictState(_iEntity, FL_EDICT_CHANGED);
					}
				}
			}

			SetClientCookie(param1, g_cRenderMode, _sTemp);
			Menu_RenderModes(param1, GetMenuSelectionPosition());
		}
	}
}

Menu_Materials(client, index = 0)
{
	decl String:_sTemp[8], String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuMaterials);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Material", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i < g_iMaterials; i++)
	{
		if(!g_iMaterialFlag[i] || CheckCommandAccess(client, "Trails_Access_Materials", g_iMaterialFlag[i]))
		{
			IntToString(i, _sTemp, sizeof(_sTemp));
			Format(_sBuffer, sizeof(_sBuffer), "%s%s", (g_iTrailData[client][INDEX_MATERIAL] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sMaterialNames[i]);
			AddMenuItem(_hMenu, _sTemp, _sBuffer);
		}
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuMaterials(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Trails(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTrailData[param1][INDEX_MATERIAL] = StringToInt(_sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Material", g_sMaterialNames[g_iTrailData[param1][INDEX_MATERIAL]]);
			if(g_bTrailsAppear[param1] && g_bAlive[param1])
			{
				Void_KillTrails(param1);
				if(!g_bEnding)
					Void_AttachTrails(param1);
			}

			SetClientCookie(param1, g_cMaterial, _sTemp);
			Menu_Materials(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_Visible(client)
{
	decl String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuVisible);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Visible", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	Format(_sBuffer, sizeof(_sBuffer), "%s%T", (g_iTrailData[client][INDEX_VISIBLE] == VISIBLE_ONE) ? g_sPrefixSelect : g_sPrefixEmpty, "Menu_Option_Visibility_Single", client);
	AddMenuItem(_hMenu, "0", _sBuffer);

	Format(_sBuffer, sizeof(_sBuffer), "%s%T", (g_iTrailData[client][INDEX_VISIBLE] == VISIBLE_TEAM) ? g_sPrefixSelect : g_sPrefixEmpty, "Menu_Option_Visibility_Team", client);
	AddMenuItem(_hMenu, "1", _sBuffer);
	
	Format(_sBuffer, sizeof(_sBuffer), "%s%T", (g_iTrailData[client][INDEX_VISIBLE] == VISIBLE_ALL) ? g_sPrefixSelect : g_sPrefixEmpty, "Menu_Option_Visibility_All", client);
	AddMenuItem(_hMenu, "2", _sBuffer);

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuVisible(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Trails(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			new _iTemp = StringToInt(_sTemp);

			if(_iTemp != g_iTrailData[param1][INDEX_VISIBLE])
			{
				g_iTrailData[param1][INDEX_VISIBLE] = _iTemp;
				switch(g_iTrailData[param1][INDEX_VISIBLE])
				{
					case VISIBLE_ONE:
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Visible_One");
					case VISIBLE_TEAM:
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Visible_Team");
					case VISIBLE_ALL:
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Visible_All");
				}
				
				SetClientCookie(param1, g_cVisible, _sTemp);
			}

			Menu_Visible(param1);
		}
	}

	return;
}