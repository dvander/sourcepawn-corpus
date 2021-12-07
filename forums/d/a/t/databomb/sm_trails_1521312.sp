#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <sdkhooks>
#include <ToggleEffects>

#define PLUGIN_VERSION "3.0.2.1"
#define PLUGIN_PREFIX "\x04Trails: \x03"

//Hardcoded limit of 8 seperate flags
#define MAX_DEFINED_FLAGS 8
//Hardcoded limit of 128 defined colors.
#define MAX_DEFINED_COLORS 128
//Hardcoded limit of 128 defined layouts.
#define MAX_DEFINED_LAYOUTS 128
//Hardcoded limit of 128 defined materials.
#define MAX_DEFINED_MATERIALS 128
//Hardcoded limit of 128 defined widths.
#define MAX_DEFINED_WIDTHS 128
//Hardcoded limit of 128 defined life values.
#define MAX_DEFINED_LIFES 128

//Array Indexes for g_iTrailData
#define INDEX_COLOR 0
#define INDEX_LAYOUT 1
#define INDEX_START 2
#define INDEX_END 3
#define INDEX_LIFE 4
#define INDEX_RENDER 5
#define INDEX_MATERIAL 6
#define INDEX_TOTAL 7

//Flags
new g_iNumFlags;
new g_iFlag[MAX_DEFINED_FLAGS];

//Colors
new g_iNumColors;
new String:g_sColorSchemes[MAX_DEFINED_COLORS][16];
new String:g_sColorNames[MAX_DEFINED_COLORS][64];
new g_iColorFlags[MAX_DEFINED_COLORS];

//Layouts
new g_iNumLayouts;
new String:g_sLayoutNames[MAX_DEFINED_LAYOUTS][64];
new Float:g_fLayoutPositions[MAX_DEFINED_LAYOUTS][MAX_DEFINED_LAYOUTS][3];
new g_iLayoutFlags[MAX_DEFINED_LAYOUTS];
new g_iLayoutTotals[MAX_DEFINED_LAYOUTS];

//Materials
new g_iMaterials;
new String:g_sMaterialPaths[MAX_DEFINED_MATERIALS][256];
new String:g_sMaterialNames[MAX_DEFINED_MATERIALS][64];
new g_iMaterialFlags[MAX_DEFINED_MATERIALS];

//Configs
new g_iStartWidths, g_iEndWidths, g_iLifeTimes, g_iRenderModes;
new String:g_sStartingWidths[MAX_DEFINED_WIDTHS][8];
new String:g_sEndingWidths[MAX_DEFINED_WIDTHS][8];
new String:g_sLifeTimes[MAX_DEFINED_LIFES][8];
new String:g_sRenderModes[6][] = { "0", "1", "2", "3", "4", "5" };
new bool:g_bRenderModes[6];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hFlags = INVALID_HANDLE;
new Handle:g_hDefault = INVALID_HANDLE;
new Handle:g_hDefaultColor = INVALID_HANDLE;
new Handle:g_hDefaultLayout = INVALID_HANDLE;
new Handle:g_hDefaultLifeTime = INVALID_HANDLE;
new Handle:g_hDefaultStarting = INVALID_HANDLE;
new Handle:g_hDefaultEnding = INVALID_HANDLE;
new Handle:g_hDefaultRender = INVALID_HANDLE;
new Handle:g_hDefaultMaterial = INVALID_HANDLE;
new Handle:g_hConfigColor = INVALID_HANDLE;
new Handle:g_hConfigLayout = INVALID_HANDLE;
new Handle:g_hConfigLifeTime = INVALID_HANDLE;
new Handle:g_hConfigStarting = INVALID_HANDLE;
new Handle:g_hConfigEnding = INVALID_HANDLE;
new Handle:g_hConfigRender = INVALID_HANDLE;
new Handle:g_hConfigMaterial = INVALID_HANDLE;
new Handle:g_cEnabled = INVALID_HANDLE;
new Handle:g_cColor = INVALID_HANDLE;
new Handle:g_cStartingWidth = INVALID_HANDLE;
new Handle:g_cEndingWidth = INVALID_HANDLE;
new Handle:g_cLifeTime = INVALID_HANDLE;
new Handle:g_cRenderMode = INVALID_HANDLE;
new Handle:g_cLayout = INVALID_HANDLE;
new Handle:g_cMaterial = INVALID_HANDLE;
new Handle:g_hTrie = INVALID_HANDLE;

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new g_iCount[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new bool:g_bAccess[MAXPLAYERS + 1];
new bool:g_bAppear[MAXPLAYERS + 1];
new bool:g_bFake[MAXPLAYERS + 1];
new g_iTrailData[MAXPLAYERS + 1][INDEX_TOTAL];
new Handle:g_hEntities[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

new g_iDefaultColor, g_iDefaultLayout, g_iDefaultLifeTime, g_iDefaultStarting, g_iDefaultEnding, g_iDefaultRender, g_iDefaultMaterial;
new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bDefault, bool:g_bEnding, bool:g_bConfigColor, bool:g_bConfigLayout, bool:g_bConfigLifeTime, bool:g_bConfigStarting, bool:g_bConfigEnding, bool:g_bConfigRender, bool:g_bConfigMaterial;

public Plugin:myinfo =
{
	name = "Player Trails", 
	author = "Twisted|Panda modified by databomb", 
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
	LoadTranslations("sm_trails.phrases");

	Void_LoadColors();
	Void_LoadLayouts();
	Void_LoadConfigs();
	Void_LoadMaterials();
	Void_Prepare();

	CreateConVar("sm_trails_version", PLUGIN_VERSION, "Player Trails: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_trails_enabled", "1", "Enables/Disables all features of this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hFlags = CreateConVar("sm_trails_flags", "b, t", "Optional flags that are required to access Player Trails. Supports multiple flags, separated with \", \". Use \"\" for free access.", FCVAR_NONE);

	g_hDefault = CreateConVar("sm_trails_default", "1", "The default trail status that is set to new clients.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hDefaultColor = CreateConVar("sm_trails_default_color", "-1", "The default color index to be applied to new players or upon sm_trails_config_color being set to 0. (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hDefaultLayout = CreateConVar("sm_trails_default_layout", "0", "The default layout index to be applied to new players or upon sm_trails_config_layout being set to 0. (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hDefaultLifeTime = CreateConVar("sm_trails_default_lifetime", "-1", "The default lifetime index to be applied to new players or upon sm_trails_config_lifetime being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hDefaultStarting = CreateConVar("sm_trails_default_starting", "37", "The default starting width index to be applied to new players or upon sm_trails_config_starting being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hDefaultEnding = CreateConVar("sm_trails_default_ending", "0", "The default ending width index to be applied to new players or upon sm_trails_config_ending being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hDefaultRender = CreateConVar("sm_trails_default_render", "2", "The default render index to be applied to new players or upon sm_trails_config_render being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hDefaultMaterial = CreateConVar("sm_trails_default_material", "-1", "The default material index to be applied to new players or upon sm_trails_config_material being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hConfigColor = CreateConVar("sm_trails_config_color", "1", "If enabled, clients will be able to change the color of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConfigLayout = CreateConVar("sm_trails_config_layout", "1", "If enabled, clients will be able to change the layout of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConfigLifeTime = CreateConVar("sm_trails_config_lifetime", "0", "If enabled, clients will be able to change the lifetime of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConfigStarting = CreateConVar("sm_trails_config_starting", "0", "If enabled, clients will be able to change the starting width of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConfigEnding = CreateConVar("sm_trails_config_ending", "0", "If enabled, clients will be able to change the ending width of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConfigRender = CreateConVar("sm_trails_config_render", "1", "If enabled, clients will be able to change the render mode of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConfigMaterial = CreateConVar("sm_trails_config_material", "1", "If enabled, clients will be able to change the material of their trail.", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "sm_trails_v3");

	HookConVarChange(g_hEnabled, Action_OnSettingsChange);
	HookConVarChange(g_hFlags, Action_OnSettingsChange);
	HookConVarChange(g_hDefault, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultColor, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultLayout, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultLifeTime, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultStarting, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultEnding, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultRender, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultMaterial, Action_OnSettingsChange);
	HookConVarChange(g_hConfigColor, Action_OnSettingsChange);
	HookConVarChange(g_hConfigLayout, Action_OnSettingsChange);
	HookConVarChange(g_hConfigLifeTime, Action_OnSettingsChange);
	HookConVarChange(g_hConfigStarting, Action_OnSettingsChange);
	HookConVarChange(g_hConfigEnding, Action_OnSettingsChange);
	HookConVarChange(g_hConfigRender, Action_OnSettingsChange);
	HookConVarChange(g_hConfigMaterial, Action_OnSettingsChange);
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);

	SetCookieMenuItem(Menu_Cookies, 0, "Trail Settings");
	g_cEnabled = RegClientCookie("PlayerTrails_Enabled", "Player Trails: The client's trail status.", CookieAccess_Protected);
	g_cColor = RegClientCookie("PlayerTrails_Color", "Player Trails: The client's selected trail color.", CookieAccess_Protected);
	g_cStartingWidth = RegClientCookie("PlayerTrails_Starting", "Player Trails: The client's selected starting trail width.", CookieAccess_Protected);
	g_cEndingWidth = RegClientCookie("PlayerTrails_Ending", "Player Trails: The client's selected ending trail width.", CookieAccess_Protected);
	g_cLifeTime = RegClientCookie("PlayerTrails_Life", "Player Trails: The client's selected LifeTime value.", CookieAccess_Protected);
	g_cRenderMode = RegClientCookie("PlayerTrails_Rendering", "Player Trails: The client's selected rendering mode.", CookieAccess_Protected);
	g_cLayout = RegClientCookie("PlayerTrails_Layout", "Player Trails: The client's selected layout.", CookieAccess_Protected);
	g_cMaterial = RegClientCookie("PlayerTrails_Material", "Player Trails: The client's selected material.", CookieAccess_Protected);

	RegAdminCmd("sm_trails_print", Command_Print, ADMFLAG_RCON, "Usage: sm_trails_print, prints indexes to be used with sm_trails_default_* cvars.");
	RegAdminCmd("sm_trails_reload", Command_Reload, ADMFLAG_RCON, "Usage: sm_trails_reload, reloads all configuration files and issues changes in-game.");
	g_hTrie = CreateTrie();
	SetTrieValue(g_hTrie, "!trails", 1);
	SetTrieValue(g_hTrie, "/trails", 1);
	SetTrieValue(g_hTrie, "!trail", 1);
	SetTrieValue(g_hTrie, "/trail", 1);
}

public OnPluginEnd()
{
	ClearTrie(g_hTrie);
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			Void_KillTrails(i, true);
		else
			Void_ClearTrails(i);
	}
}

public OnMapStart()
{
	Void_SetDefaults();
	
	if(g_bEnabled)
	{
		Void_Prepare();
	}
}

public OnMapEnd()
{
	if(g_bEnabled)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
				Void_KillTrails(i, true);
			else
				Void_ClearTrails(i);
		}
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled && g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				g_iTeam[i] = GetClientTeam(i);
				g_bAlive[i] = IsPlayerAlive(i) ? true : false;
				g_bFake[i] = IsFakeClient(i) ? true : false;

				if(!g_iNumFlags)
					g_bAccess[i] = true;
				else
				{
					new _iFlags = GetUserFlagBits(i);
					for(new j = 0; j < g_iNumFlags; j++)
					{
						if(_iFlags & g_iFlag[j])
						{
							g_bAccess[i] = true;
							break;
						}
					}
				}
				
				g_hEntities[i] = g_bAccess[i] ? CreateArray(i) : INVALID_HANDLE;
				if(g_bAccess[i])
				{
					if(!g_bFake[i])
					{
						if(!g_bLoaded[i] && AreClientCookiesCached(i))
							Void_LoadCookies(i);
					}
					else
					{
						g_bAppear[i] = g_bDefault;
						g_bLoaded[i] = true;

						g_iTrailData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
						g_iTrailData[i][INDEX_LAYOUT] = g_iDefaultLayout == -1 ? GetRandomInt(0, (g_iNumLayouts - 1)) : g_iDefaultLayout;
						g_iTrailData[i][INDEX_START] = g_iDefaultStarting == -1 ? GetRandomInt(0, (g_iStartWidths - 1)) : g_iDefaultStarting;
						g_iTrailData[i][INDEX_END] = g_iDefaultEnding == -1 ? GetRandomInt(0, (g_iEndWidths - 1)) : g_iDefaultEnding;
						g_iTrailData[i][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iLifeTimes - 1)) : g_iDefaultLifeTime;
						g_iTrailData[i][INDEX_RENDER] = g_iDefaultRender == -1 ? GetRandomInt(0, 5) : g_iDefaultRender;
						g_iTrailData[i][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
					}
				}

				if(!g_bEnding && g_bAlive[i] && g_iTeam[i] >= 2 && g_bAppear[i] && !g_iCount[i])
					Void_AttachTrails(i);
			}
			else
			{
				g_iTeam[i] = 0;
				g_bAlive[i] = false;
				if(g_hEntities[i] != INVALID_HANDLE && CloseHandle(g_hEntities[i]))
					g_hEntities[i] = INVALID_HANDLE;
			}
		}
		
		g_bLateLoad = false;
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled && IsClientInGame(client))
	{
		if(!g_iNumFlags)
			g_bAccess[client] = true;
		else
		{
			new _iFlags = GetUserFlagBits(client);
			for(new i = 0; i < g_iNumFlags; i++)
			{
				if(_iFlags & g_iFlag[i])
				{
					g_bAccess[client] = true;
					break;
				}
			}
		}

		g_bFake[client] = IsFakeClient(client) ? true : false;
		g_hEntities[client] = g_bAccess[client] ? CreateArray(client) : INVALID_HANDLE;
		if(g_bAccess[client])
		{
			if(!g_bFake[client])
			{
				if(!g_bLoaded[client] && AreClientCookiesCached(client))
					Void_LoadCookies(client);
			}
			else
			{
				g_bLoaded[client] = true;
				g_bAppear[client] = g_bDefault;

				g_iTrailData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
				g_iTrailData[client][INDEX_LAYOUT] = g_iDefaultLayout == -1 ? GetRandomInt(0, (g_iNumLayouts - 1)) : g_iDefaultLayout;
				g_iTrailData[client][INDEX_START] = g_iDefaultStarting == -1 ? GetRandomInt(0, (g_iStartWidths - 1)) : g_iDefaultStarting;
				g_iTrailData[client][INDEX_END] = g_iDefaultEnding == -1 ? GetRandomInt(0, (g_iEndWidths - 1)) : g_iDefaultEnding;
				g_iTrailData[client][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iLifeTimes - 1)) : g_iDefaultLifeTime;
				g_iTrailData[client][INDEX_RENDER] = g_iDefaultRender == -1 ? GetRandomInt(0, 5) : g_iDefaultRender;
				g_iTrailData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
			}
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
		g_bAccess[client] = false;
		g_bAppear[client] = false;

		Void_KillTrails(client, true);
	}
}

public OnClientCookiesCached(client)
{
	if(!g_bLoaded[client] && !g_bFake[client])
	{
		Void_LoadCookies(client);
		if(!g_bEnding && g_bAlive[client] && g_iTeam[client] >= 2 && IsClientInGame(client) && g_bAppear[client] && !g_iCount[client])
			Void_AttachTrails(client);
	}
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] <= 1)
		{
			g_bAlive[client] = false;
			if(g_bAccess[client])
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
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= 1)
			return Plugin_Continue;
		
		g_bAlive[client] = true;
		if(!g_bEnding && g_bAccess[client] && g_bAppear[client] && !g_iCount[client])
			CreateTimer(0.1, Timer_Attach, GetClientUserId(client));
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
		
		g_bAlive[client] = false;
		if(g_bAccess[client])
			Void_KillTrails(client, false);
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = false;
		for(new i = 1; i <= MaxClients; i++)
			if(g_bAlive[i] && IsClientInGame(i) && g_bAccess[i] && g_bAppear[i] && !g_iCount[i])
				Void_AttachTrails(i);
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
				Void_KillTrails(i, false);
	}

	return Plugin_Continue;
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		decl _iIndex, String:_sText[192];
		GetCmdArgString(_sText, sizeof(_sText));
		StripQuotes(_sText);

		if(GetTrieValue(g_hTrie, _sText, _iIndex))
		{
			if(!g_bAccess[client])
				PrintToChat(client, "%s%t", PLUGIN_PREFIX, "Phrase_Restricted");
			else
				Menu_Trails(client);

			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

public Action:Command_Print(client, args)
{
	ReplyToCommand(client, "%sPlease check your console for index data.", PLUGIN_PREFIX);
	new _iArray[2];
	if(client)
		_iArray[0] = GetClientUserId(client);
	else
		_iArray[0] = 0;

	for(_iArray[1] = 1; _iArray[1] <= 7; _iArray[1]++)
	{
		new Handle:_hPack = CreateDataPack();
		WritePackCell(_hPack, _iArray[0]);
		WritePackCell(_hPack, _iArray[1]);
		CreateTimer((0.1 * float(_iArray[1])), Timer_Print, _hPack);
	}
	
	return Plugin_Handled;
}

public Action:Command_Reload(client, args)
{
	ReplyToCommand(client, "%sSettings have been reloaded!", PLUGIN_PREFIX);

	Void_LoadColors();
	Void_LoadLayouts();
	Void_LoadConfigs();
	Void_LoadMaterials();
	Void_Prepare();
	for(new i = 1; i <= MaxClients; i++)
	{
		g_bLoaded[i] = false;
		g_bAccess[i] = false;
		if(IsClientInGame(i))
		{
			Void_KillTrails(i, true);

			g_iTeam[i] = GetClientTeam(i);
			g_bAlive[i] = IsPlayerAlive(i) ? true : false;
			g_bFake[i] = IsFakeClient(i) ? true : false;

			if(!g_iNumFlags)
				g_bAccess[i] = true;
			else
			{
				new _iFlags = GetUserFlagBits(i);
				for(new j = 0; j < g_iNumFlags; j++)
				{
					if(_iFlags & g_iFlag[j])
					{
						g_bAccess[i] = true;
						break;
					}
				}
			}

			if(g_bAccess[i])
			{
				g_hEntities[i] = CreateArray();
				if(!g_bFake[i])
				{
					if(!g_bLoaded[i] && AreClientCookiesCached(i))
						Void_LoadCookies(i);
				}
				else
				{
					g_bLoaded[i] = true;
					g_bAppear[i] = true;

					g_iTrailData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
					g_iTrailData[i][INDEX_LAYOUT] = g_iDefaultLayout == -1 ? GetRandomInt(0, (g_iNumLayouts - 1)) : g_iDefaultLayout;
					g_iTrailData[i][INDEX_START] = g_iDefaultStarting == -1 ? GetRandomInt(0, (g_iStartWidths - 1)) : g_iDefaultStarting;
					g_iTrailData[i][INDEX_END] = g_iDefaultEnding == -1 ? GetRandomInt(0, (g_iEndWidths - 1)) : g_iDefaultEnding;
					g_iTrailData[i][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iLifeTimes - 1)) : g_iDefaultLifeTime;
					g_iTrailData[i][INDEX_RENDER] = g_iDefaultRender == -1 ? GetRandomInt(0, 5) : g_iDefaultRender;
					g_iTrailData[i][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
				}

				if(!g_bEnding && g_bAlive[i] && g_iTeam[i] >= 2 && g_bAppear[i] && !g_iCount[i])
					Void_AttachTrails(i);
			}
		}
		else
		{
			g_iTeam[i] = 0;
			g_bAlive[i] = false;
			if(g_hEntities[i] != INVALID_HANDLE && CloseHandle(g_hEntities[i]))
				g_hEntities[i] = INVALID_HANDLE;
		}
	}

	return Plugin_Handled;
}

public Action:Timer_Attach(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client) && !g_bEnding && g_bAlive[client] && !g_iCount[client])
		Void_AttachTrails(client);
}

public Action:Timer_Kill(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && g_iCount[client] && IsClientInGame(client))
		Void_KillTrails(client, false);
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
	if(g_bLoaded[client] && g_hEntities[client] != INVALID_HANDLE)
	{
		decl String:_sTemp[64];
		g_iCount[client] = g_iLayoutTotals[g_iTrailData[client][INDEX_LAYOUT]];
		Format(_sTemp, 64, "PlayerTrails_%d", GetClientUserId(client));
		DispatchKeyValue(client, "targetname", _sTemp);

		decl Float:g_fAngle[3], Float:g_fOrigin[3], Float:_fTemp[3] = { 0.0, 90.0, 0.0 };
		GetEntPropVector(client, Prop_Data, "m_angAbsRotation", g_fAngle);
		SetEntPropVector(client, Prop_Data, "m_angAbsRotation", _fTemp);
		for(new i = 1; i <= g_iCount[client]; i++)
		{
			new _iEntity = CreateEntityByName("env_spritetrail");
			if(_iEntity > 0 && IsValidEntity(_iEntity))
			{
				SetEntPropFloat(_iEntity, Prop_Send, "m_flTextureRes", 0.05);

				PushArrayCell(g_hEntities[client], _iEntity);
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
	}
}

public Action:Hook_SetTransmit(entity, client)
{
	if (!ShowClientEffects(client))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Void_KillTrails(client, bool:clear = false)
{
	if(g_hEntities[client] != INVALID_HANDLE)
	{
		for(new i = 0; i < g_iCount[client]; i++)
		{
			new _iEntity = GetArrayCell(g_hEntities[client], i);
			if(_iEntity > 0 && IsValidEntity(_iEntity))
			{
				SDKUnhook(_iEntity, SDKHook_SetTransmit, Hook_SetTransmit);
				AcceptEntityInput(_iEntity, "Kill");
			}
		}

		ClearArray(g_hEntities[client]);
		if(clear && CloseHandle(g_hEntities[client]))
			g_hEntities[client] = INVALID_HANDLE;
	}

	g_iCount[client] = 0;
}

Void_ClearTrails(index)
{
	if(g_hEntities[index] != INVALID_HANDLE)
	{
		ClearArray(g_hEntities[index]);
		if(CloseHandle(g_hEntities[index]))
			g_hEntities[index] = INVALID_HANDLE;
	}
}

Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_bDefault = GetConVarInt(g_hDefault) ? true : false;
	g_iDefaultColor = GetConVarInt(g_hDefaultColor);
	g_iDefaultLayout = GetConVarInt(g_hDefaultLayout);
	g_iDefaultLifeTime = GetConVarInt(g_hDefaultLifeTime);
	g_iDefaultStarting = GetConVarInt(g_hDefaultStarting);
	g_iDefaultEnding = GetConVarInt(g_hDefaultEnding);
	g_iDefaultRender = GetConVarInt(g_hDefaultRender);
	g_iDefaultMaterial = GetConVarInt(g_hDefaultMaterial);
	g_bConfigColor = GetConVarInt(g_hConfigColor) ? true : false;
	g_bConfigLayout = GetConVarInt(g_hConfigLayout) ? true : false;
	g_bConfigLifeTime = GetConVarInt(g_hConfigLifeTime) ? true : false;
	g_bConfigStarting = GetConVarInt(g_hConfigStarting) ? true : false;
	g_bConfigEnding = GetConVarInt(g_hConfigEnding) ? true : false;
	g_bConfigRender = GetConVarInt(g_hConfigRender) ? true : false;
	g_bConfigMaterial = GetConVarInt(g_hConfigMaterial) ? true : false;
	
	decl String:_sFlag[32], String:_sBuffer[MAX_DEFINED_FLAGS][8];
	GetConVarString(g_hFlags, _sFlag, 32);
	g_iNumFlags = ExplodeString(_sFlag, ", ", _sBuffer, MAX_DEFINED_FLAGS, 8);
	for(new i = 0; i < g_iNumFlags; i++)
		g_iFlag[i] = ReadFlagString(_sBuffer[i]);
		
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

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_bEnabled = StringToInt(newvalue) ? true : false;
		
		if(g_bEnabled)
		{
			Void_LoadColors();
			Void_LoadLayouts();
			Void_LoadConfigs();
			Void_LoadMaterials();
			Void_Prepare();
		}
		else
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
					Void_KillTrails(i, true);
				else
					Void_ClearTrails(i);
			}
		}
	}
	else if(cvar == g_hFlags)
	{
		if(!StrEqual(newvalue, "", false))
		{
			decl String:_sBuffer[MAX_DEFINED_FLAGS][8];
			g_iNumFlags = ExplodeString(newvalue, ", ", _sBuffer, MAX_DEFINED_FLAGS, 8);
			for(new i = 0; i < g_iNumFlags; i++)
				g_iFlag[i] = ReadFlagString(_sBuffer[i]);
		}
		else
			g_iNumFlags = 0;

		for(new i = 1; i <= MaxClients; i++)
		{
			g_bLoaded[i] = false;
			g_bAccess[i] = false;
			if(IsClientInGame(i))
			{
				Void_KillTrails(i, true);

				g_iTeam[i] = GetClientTeam(i);
				g_bAlive[i] = IsPlayerAlive(i) ? true : false;
				g_bFake[i] = IsFakeClient(i) ? true : false;
				if(!g_iNumFlags)
					g_bAccess[i] = true;
				else
				{
					new _iFlags = GetUserFlagBits(i);
					for(new j = 0; j < g_iNumFlags; j++)
					{
						if(_iFlags & g_iFlag[j])
						{
							g_bAccess[i] = true;
							break;
						}
					}
				}

				if(g_bAccess[i])
				{
					g_hEntities[i] = CreateArray();
					if(!g_bFake[i])
					{
						if(!g_bLoaded[i] && AreClientCookiesCached(i))
							Void_LoadCookies(i);
					}
					else
					{
						g_bLoaded[i] = true;
						g_bAppear[i] = g_bDefault;

						g_iTrailData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
						g_iTrailData[i][INDEX_LAYOUT] = g_iDefaultLayout == -1 ? GetRandomInt(0, (g_iNumLayouts - 1)) : g_iDefaultLayout;
						g_iTrailData[i][INDEX_START] = g_iDefaultStarting == -1 ? GetRandomInt(0, (g_iStartWidths - 1)) : g_iDefaultStarting;
						g_iTrailData[i][INDEX_END] = g_iDefaultEnding == -1 ? GetRandomInt(0, (g_iEndWidths - 1)) : g_iDefaultEnding;
						g_iTrailData[i][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iLifeTimes - 1)) : g_iDefaultLifeTime;
						g_iTrailData[i][INDEX_RENDER] = g_iDefaultRender == -1 ? GetRandomInt(0, 5) : g_iDefaultRender;
						g_iTrailData[i][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
					}

					if(g_bAlive[i] && g_bAppear[i] && !g_iCount[i] && !g_bEnding)
						Void_AttachTrails(i);
				}
				else
				{
					g_hEntities[i] = INVALID_HANDLE;
					g_bAppear[i] = false;
				}
			}
			else
			{
				g_iTeam[i] = 0;
				g_bAlive[i] = false;
				if(g_hEntities[i] != INVALID_HANDLE && CloseHandle(g_hEntities[i]))
					g_hEntities[i] = INVALID_HANDLE;
			}
		}
	}
	else if(cvar == g_hDefault)
		g_bDefault = StringToInt(newvalue) ? true : false;
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
	else if(cvar == g_hConfigColor)
		g_bConfigColor = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hConfigLayout)
		g_bConfigLayout = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hConfigLifeTime)
		g_bConfigLifeTime = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hConfigStarting)
		g_bConfigStarting = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hConfigEnding)
		g_bConfigEnding = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hConfigRender)
		g_bConfigRender = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hConfigMaterial)
		g_bConfigMaterial = StringToInt(newvalue) ? true : false;
}

Void_LoadColors()
{
	decl String:_sPath[256];
	new Handle:_hKV = CreateKeyValues("PlayerTrails_Colors");
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/trails/sm_trails_colors.ini");

	if(FileToKeyValues(_hKV, _sPath))
	{
		g_iNumColors = 0;

		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, g_sColorNames[g_iNumColors], 64);
			KvGetString(_hKV, "color", g_sColorSchemes[g_iNumColors], 16);

			KvGetString(_hKV, "flag", _sPath, sizeof(_sPath));
			g_iColorFlags[g_iNumColors] = StringToInt(_sPath);

			g_iNumColors++;
		}
		while (KvGotoNextKey(_hKV));

		if(!g_iNumColors)
		{
			CloseHandle(_hKV);
			SetFailState("Trails: There were no colors defined in sm_trails_colors.ini!");
			return;
		}
	}
	else
	{
		CloseHandle(_hKV);
		SetFailState("Trails: Unable to locate the file sourcemod/configs/trails/sm_trails_colors.ini!");
		return;		
	}

	CloseHandle(_hKV);
}

Void_LoadLayouts()
{
	decl String:_sPath[256];
	new Handle:_hKV = CreateKeyValues("PlayerTrails_Layouts");
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/trails/sm_trails_layouts.ini");
	
	if(FileToKeyValues(_hKV, _sPath))
	{
		g_iNumLayouts = 0;

		KvGotoFirstSubKey(_hKV);
		do
		{
			decl String:_sTemp[128];
			KvGetSectionName(_hKV, g_sLayoutNames[g_iNumLayouts], 64);

			KvGetString(_hKV, "flag", _sTemp, sizeof(_sTemp));
			g_iLayoutFlags[g_iNumLayouts] = StringToInt(_sTemp);
			
			g_iLayoutTotals[g_iNumLayouts] = 0;
			for(new i = 1; i <= MAX_DEFINED_LAYOUTS; i++)
			{
				IntToString(i, _sTemp, sizeof(_sTemp));
				KvGetString(_hKV, _sTemp, _sTemp, sizeof(_sTemp));
				if(!StrEqual(_sTemp, "", false))
				{
					g_iLayoutTotals[g_iNumLayouts]++;
					decl String:_sBuffer[3][8];
					
					ExplodeString(_sTemp, " ", _sBuffer, 3, 8);
					for(new j = 0; j <= 2; j++)
						g_fLayoutPositions[g_iNumLayouts][i][j] = StringToFloat(_sBuffer[j]);
				}
				else if(i == 1)
				{
					CloseHandle(_hKV);
					SetFailState("Trails: The layout %s is not properly configured!", g_sLayoutNames[g_iNumLayouts]);
					return;
				}
				else
					break;
			}
			
			g_iNumLayouts++;
		}
		while (KvGotoNextKey(_hKV));
		
		if(!g_iNumLayouts)
		{
			CloseHandle(_hKV);
			SetFailState("Trails: There were no layouts defined in sm_trails_layouts.ini!");
			return;
		}
	}
	else
	{
		CloseHandle(_hKV);
		SetFailState("Trails: Unable to locate the file sourcemod/configs/trails/sm_trails_layouts.ini!");
		return;		
	}

	CloseHandle(_hKV);
}

Void_LoadConfigs()
{
	decl String:_sPath[256];
	new Handle:_hKV = CreateKeyValues("PlayerTrails_Configs");
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/trails/sm_trails_configs.ini");
	
	if(FileToKeyValues(_hKV, _sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			decl String:_sBuffer[64];
			KvGetSectionName(_hKV, _sBuffer, sizeof(_sBuffer));
			
			if(StrEqual(_sBuffer, "Start_Widths", false))
			{
				decl String:_sTemp[8];
				g_iStartWidths = 0;

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
			else if(StrEqual(_sBuffer, "End_Widths", false))
			{
				decl String:_sTemp[8];
				g_iEndWidths = 0;

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
			else if(StrEqual(_sBuffer, "LifeTimes", false))
			{
				decl String:_sTemp[8];
				g_iLifeTimes = 0;

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
			else if(StrEqual(_sBuffer, "Render_Modes", false))
			{
				decl String:_sTemp[32];
				for(new i = 0; i <= 5; i++)
				{
					IntToString(i, _sTemp, sizeof(_sTemp));
					KvGetString(_hKV, _sTemp, _sTemp, sizeof(_sTemp));
					g_bRenderModes[i] = StrEqual(_sTemp, "1", false) ? true : false;
					if(g_bRenderModes[i])
						g_iRenderModes++;
				}
			}
		}
		while (KvGotoNextKey(_hKV));
	}
	else
	{
		CloseHandle(_hKV);
		SetFailState("Trails: Unable to locate the file sourcemod/configs/trails/sm_trails_configs.ini!");
		return;		
	}

	CloseHandle(_hKV);
}

Void_LoadMaterials()
{
	decl String:_sPath[256];
	new Handle:_hKV = CreateKeyValues("PlayerTrails_Materials");
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/trails/sm_trails_materials.ini");
	
	if(FileToKeyValues(_hKV, _sPath))
	{
		g_iMaterials = 0;
		decl String:_sBuffer[64];

		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, g_sMaterialNames[g_iMaterials], 64);
			KvGetString(_hKV, "path", g_sMaterialPaths[g_iMaterials], 256);
			
			KvGetString(_hKV, "flag", _sBuffer, sizeof(_sBuffer));
			g_iMaterialFlags[g_iMaterials] = StringToInt(_sBuffer);

			g_iMaterials++;
		}
		while (KvGotoNextKey(_hKV));
		
		if(!g_iMaterials)
		{
			CloseHandle(_hKV);
			SetFailState("Trails: There were no materials defined in sm_trails_materials.ini!");
			return;
		}
	}
	else
	{
		CloseHandle(_hKV);
		SetFailState("Trails: Unable to locate the file sourcemod/configs/trails/sm_trails_materials.ini!");
		return;		
	}

	CloseHandle(_hKV);
}

Void_Prepare()
{
	for(new i = 0; i < g_iMaterials; i++)
	{
		decl String:_sBuffer[256];
		strcopy(_sBuffer, sizeof(_sBuffer), g_sMaterialPaths[i]);
		PrecacheModel(_sBuffer, true);
		AddFileToDownloadsTable(_sBuffer);
		ReplaceString(_sBuffer, sizeof(_sBuffer), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(_sBuffer);
	}
}

Void_LoadCookies(client)
{
	decl String:_sCookie[4] = "";
	GetClientCookie(client, g_cEnabled, _sCookie, sizeof(_sCookie));

	if(StrEqual(_sCookie, "", false))
	{
		_sCookie = g_bDefault ? "1" : "0";
		g_bAppear[client] = StringToInt(_sCookie) ? true : false;
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
	}
	else
	{
		g_bAppear[client] = StringToInt(_sCookie) ? true : false;

		if(g_bConfigColor)
		{
			GetClientCookie(client, g_cColor, _sCookie, 4);
			g_iTrailData[client][INDEX_COLOR] = StringToInt(_sCookie);
			if(g_iTrailData[client][INDEX_COLOR] >= g_iNumColors)
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
			if(g_iTrailData[client][INDEX_LAYOUT] >= g_iNumLayouts)
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
			if(g_iTrailData[client][INDEX_START] >= g_iStartWidths)
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
			if(g_iTrailData[client][INDEX_END] >= g_iEndWidths)
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
			if(g_iTrailData[client][INDEX_LIFE] >= g_iLifeTimes)
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
			if(g_iTrailData[client][INDEX_RENDER] >= g_iRenderModes)
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
			if(g_iTrailData[client][INDEX_MATERIAL] >= g_iMaterials)
			{
				g_iTrailData[client][INDEX_MATERIAL] = (g_iMaterials - 1);
				IntToString(g_iTrailData[client][INDEX_MATERIAL], _sCookie, 4);
				SetClientCookie(client, g_cMaterial, _sCookie);
			}
		}
		else
			g_iTrailData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
	}

	g_bLoaded[client] = true;
}

public Menu_Cookies(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "Trail Settings");
		case CookieMenuAction_SelectOption:
		{
			if(!g_bEnabled)
				PrintToChat(client, "%s%t", PLUGIN_PREFIX, "Phrase_Inactive");
			else if(!g_bAccess[client])
				PrintToChat(client, "%s%t", PLUGIN_PREFIX, "Phrase_Restricted");
			else if(client && IsClientInGame(client))
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

	if(g_bAppear[client])
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Disable", client);
	else
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Enable", client);
	AddMenuItem(_hMenu, "0", _sBuffer);
	
	if(g_iNumColors > 1 && g_bConfigColor)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Color", client);
		AddMenuItem(_hMenu, "1", _sBuffer);
	}

	if(g_iNumLayouts > 1 && g_bConfigLayout)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Layout", client);
		AddMenuItem(_hMenu, "2", _sBuffer);
	}

	if(g_iMaterials > 1 && g_bConfigMaterial)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Material", client);
		AddMenuItem(_hMenu, "7", _sBuffer);
	}

	if(g_iStartWidths > 1 && g_bConfigStarting)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Starting", client);
		AddMenuItem(_hMenu, "3", _sBuffer);
	}
	
	if(g_iEndWidths > 1 && g_bConfigEnding)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Ending", client);
		AddMenuItem(_hMenu, "4", _sBuffer);
	}
	
	if(g_iLifeTimes > 1 && g_bConfigLifeTime)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Life", client);
		AddMenuItem(_hMenu, "5", _sBuffer);
	}
	
	if(g_iRenderModes > 1 && g_bConfigRender)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Render", client);
		AddMenuItem(_hMenu, "6", _sBuffer);
	}
	
	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuTrails(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));

			switch(StringToInt(_sTemp))
			{
				case 0:
				{
					if(!g_bAppear[param1])
					{
						g_bAppear[param1] = true;
						if(g_bAlive[param1] && !g_bEnding)
							Void_AttachTrails(param1);
						PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Phrase_Enable");
						SetClientCookie(param1	, g_cEnabled, "1");
					}
					else
					{
						g_bAppear[param1] = false;
						if(g_bAlive[param1] && !g_bEnding)
							Void_KillTrails(param1, false);
						PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Phrase_Disable");
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

	new _iTemp = GetUserFlagBits(client);
	for(new i = 0; i < g_iNumLayouts; i++)
	{
		if(!g_iLayoutFlags[i] || _iTemp & g_iLayoutFlags[i])
		{
			IntToString(i, _sTemp, sizeof(_sTemp));
			AddMenuItem(_hMenu, _sTemp, g_sLayoutNames[i]);
		}
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuLayouts(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
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

			PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Phrase_Change_Layout", g_sLayoutNames[g_iTrailData[param1][INDEX_LAYOUT]]);
			if(g_bAppear[param1] && g_bAlive[param1])
			{
				Void_KillTrails(param1, false);
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

	new _iTemp = GetUserFlagBits(client);
	for(new i = 0; i < g_iNumColors; i++)
	{
		if(!g_iColorFlags[i] || _iTemp & g_iColorFlags[i])
		{
			IntToString(i, _sTemp, sizeof(_sTemp));
			AddMenuItem(_hMenu, _sTemp, g_sColorNames[i]);
		}
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuColors(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
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

			PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Phrase_Change_Color", g_sColorNames[g_iTrailData[param1][INDEX_COLOR]]);
			if(g_bAppear[param1] && g_bAlive[param1])
			{
				for(new i = 0; i < g_iCount[param1]; i++)
				{
					new _iEntity = GetArrayCell(g_hEntities[param1], i);
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
		AddMenuItem(_hMenu, _sTemp, g_sStartingWidths[i]);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuStartingWidths(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
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

			PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Phrase_Change_Starting", g_sStartingWidths[g_iTrailData[param1][INDEX_START]]);
			if(g_bAppear[param1] && g_bAlive[param1])
			{
				for(new i = 0; i < g_iCount[param1]; i++)
				{
					new _iEntity = GetArrayCell(g_hEntities[param1], i);
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
		AddMenuItem(_hMenu, _sTemp, g_sEndingWidths[i]);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuEndingWidths(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
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
			
			PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Phrase_Change_Ending", g_sEndingWidths[g_iTrailData[param1][INDEX_END]]);
			if(g_bAppear[param1] && g_bAlive[param1])
			{
				for(new i = 0; i < g_iCount[param1]; i++)
				{
					new _iEntity = GetArrayCell(g_hEntities[param1], i);
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
		AddMenuItem(_hMenu, _sTemp, g_sLifeTimes[i]);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuLifeTimes(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
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

			PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Phrase_Change_Life", g_sLifeTimes[g_iTrailData[param1][INDEX_LIFE]]);
			if(g_bAppear[param1] && g_bAlive[param1])
			{
				for(new i = 0; i < g_iCount[param1]; i++)
				{
					new _iEntity = GetArrayCell(g_hEntities[param1], i);
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
	decl String:_sDisplay[128], String:_sTemp[8], String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuRenderModes);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Render", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i < 6; i++)
	{
		IntToString(i, _sTemp, sizeof(_sTemp));
		Format(_sDisplay, 128, "Method %d", i);
		AddMenuItem(_hMenu, _sTemp, _sDisplay);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuRenderModes(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
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

			PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Phrase_Change_Render", g_iTrailData[param1][INDEX_RENDER]);
			if(g_bAppear[param1] && g_bAlive[param1])
			{
				for(new i = 0; i < g_iCount[param1]; i++)
				{
					new _iEntity = GetArrayCell(g_hEntities[param1], i);
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

	new _iTemp = GetUserFlagBits(client);
	for(new i = 0; i < g_iMaterials; i++)
	{
		if(!g_iMaterialFlags[i] || _iTemp & g_iMaterialFlags[i])
		{
			IntToString(i, _sTemp, sizeof(_sTemp));
			AddMenuItem(_hMenu, _sTemp, g_sMaterialNames[i]);
		}
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuMaterials(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
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

			PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Phrase_Change_Material", g_sMaterialNames[g_iTrailData[param1][INDEX_MATERIAL]]);
			if(g_bAppear[param1] && g_bAlive[param1])
			{
				Void_KillTrails(param1, false);
				if(!g_bEnding)
					Void_AttachTrails(param1);
			}

			SetClientCookie(param1, g_cMaterial, _sTemp);
			Menu_Materials(param1, GetMenuSelectionPosition());
		}
	}

	return;
}