//Comment out the line below if you do not wish to use ClientPrefs
#define ENABLE_CLIENTPREFS 1

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>
#if defined ENABLE_CLIENTPREFS
#include <clientprefs>
#endif

#define PLUGIN_VERSION "1.0.3"

//Hardcoded limit of 8 seperate flags, increase/decrease to meet needs (saves memory by not declaring sizes excessively large)
#define MAX_DEFINED_FLAGS 8
//Hardcoded limit of 128 defined colors, increase/decrease to meet needs (saves memory by not declaring sizes excessively large)
#define MAX_DEFINED_COLORS 128
//Hardcoded limit of 128 defined materials, increase/decrease to meet needs (saves memory by not declaring sizes excessively large)
#define MAX_DEFINED_MATERIALS 128
//Hardcoded limit of 128 defined widths, increase/decrease to meet needs (saves memory by not declaring sizes excessively large)
#define MAX_DEFINED_WIDTHS 128
//Hardcoded limit of 128 defined life values, increase/decrease to meet needs (saves memory by not declaring sizes excessively large)
#define MAX_DEFINED_LIFES 128
//Hardcoded limit of 128 defined alpha values, increase/decrease to meet needs (saves memory by not declaring sizes excessively large)
#define MAX_DEFINED_ALPHAS 128

//Array Indexes for g_iTracerData
#define INDEX_COLOR 0
#define INDEX_WIDTH 1
#define INDEX_ALPHA 2
#define INDEX_LIFE 3
#define INDEX_MATERIAL 4
#define INDEX_VISIBLE 5
#define INDEX_TOTAL 6

#define VISIBLE_ONE 0
#define VISIBLE_TEAM 1
#define VISIBLE_ALL 2

#define TRACERS_DISABLED 0
#define TRACERS_ENABLED 1
#define TRACERS_FORCED 2

//Flags
new g_iNumFlags;
new g_iFlag[MAX_DEFINED_FLAGS];

//Colors
new g_iNumColors;
new String:g_sColorSchemes[MAX_DEFINED_COLORS][16];
new String:g_sColorNames[MAX_DEFINED_COLORS][64];
new g_iColorFlags[MAX_DEFINED_COLORS];

//Materials
new g_iMaterials;
new String:g_sMaterialPaths[MAX_DEFINED_MATERIALS][256];
new String:g_sMaterialNames[MAX_DEFINED_MATERIALS][64];
new g_iMaterialFlags[MAX_DEFINED_MATERIALS];
new g_iMaterialIndexes[MAX_DEFINED_MATERIALS];

//Configs
new g_iNumWidths, g_iNumAlphas, g_iNumLifes;
new Float:g_fWidths[MAX_DEFINED_WIDTHS];
new g_iAlphas[MAX_DEFINED_ALPHAS];
new Float:g_fLifeTimes[MAX_DEFINED_LIFES];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hFlags = INVALID_HANDLE;
new Handle:g_hDefault = INVALID_HANDLE;
new Handle:g_hDefaultColor = INVALID_HANDLE;
new Handle:g_hDefaultLifeTime = INVALID_HANDLE;
new Handle:g_hDefaultWidth = INVALID_HANDLE;
new Handle:g_hDefaultAlpha = INVALID_HANDLE;
new Handle:g_hDefaultMaterial = INVALID_HANDLE;
new Handle:g_hDefaultVisible = INVALID_HANDLE;
new Handle:g_hConfigColor = INVALID_HANDLE;
new Handle:g_hConfigLifeTime = INVALID_HANDLE;
new Handle:g_hConfigWidth = INVALID_HANDLE;
new Handle:g_hConfigAlpha = INVALID_HANDLE;
new Handle:g_hConfigMaterial = INVALID_HANDLE;
new Handle:g_hConfigVisible = INVALID_HANDLE;
new Handle:g_cEnabled = INVALID_HANDLE;
new Handle:g_cColor = INVALID_HANDLE;
new Handle:g_cWidth = INVALID_HANDLE;
new Handle:g_cAlpha = INVALID_HANDLE;
new Handle:g_cLifeTime = INVALID_HANDLE;
new Handle:g_cMaterial = INVALID_HANDLE;
new Handle:g_cVisible = INVALID_HANDLE;
new Handle:g_hTrie = INVALID_HANDLE;
new Handle:g_hConfig = INVALID_HANDLE;
new Handle:g_hPosition = INVALID_HANDLE;

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new bool:g_bAccess[MAXPLAYERS + 1];
new bool:g_bFake[MAXPLAYERS + 1];
new g_iAppear[MAXPLAYERS + 1];
new g_iColors[MAXPLAYERS + 1][4];
new g_iTracerData[MAXPLAYERS + 1][INDEX_TOTAL];

new g_iDefault, g_iDefaultColor, g_iDefaultLifeTime, g_iDefaultWidth, g_iDefaultAlpha, g_iDefaultMaterial, g_iDefaultVisible;
new bool:g_bValidSDK, bool:g_bEnabled, bool:g_bLateLoad, bool:g_bConfigColor, bool:g_bConfigLifeTime, bool:g_bConfigWidth, bool:g_bConfigAlpha, bool:g_bConfigMaterial, bool:g_bConfigVisible;
new String:g_sPrefixChat[32], String:g_sPrefixSelect[16], String:g_sPrefixEmpty[16];

public Plugin:myinfo =
{
	name = "Player Tracers", 
	author = "Twisted|Panda", 
	description = "Provides both simple and advanced functionality for displaying tracers - beams that expand from muzzle to bullet impact - focused on players.", 
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
	LoadTranslations("sm_tracers.phrases");

	CreateConVar("sm_tracers_version", PLUGIN_VERSION, "Player Tracers: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_tracers_enabled", "1", "Enables/Disables all features of this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hFlags = CreateConVar("sm_tracers_flags", "b, t", "Optional flags that are required to access Player Tracers. Supports multiple flags, separated with \", \". Use \"\" for free access.", FCVAR_NONE);
	g_hDefault = CreateConVar("sm_tracers_default_status", "1", "The default tracer status that is set to new clients. (0 = Disabled, 1 = Enabled, 2 = Always Enabled)", FCVAR_NONE, true, 0.0, true, 2.0);
	
	g_hDefaultColor = CreateConVar("sm_tracers_default_color", "-1", "The default color index to be applied to new players or upon sm_tracers_config_color being set to 0. (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hDefaultLifeTime = CreateConVar("sm_tracers_default_lifetime", "4", "The default lifetime index to be applied to new players or upon sm_tracers_config_lifetime being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hDefaultWidth = CreateConVar("sm_tracers_default_width", "19", "The default width index to be applied to new players or upon sm_tracers_config_width being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hDefaultAlpha = CreateConVar("sm_tracers_default_alpha", "11", "The default alpha index to be applied to new players or upon sm_tracers_config_alpha being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hDefaultMaterial = CreateConVar("sm_tracers_default_material", "-1", "The default material index to be applied to new players or upon sm_tracers_config_material being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	g_hDefaultVisible = CreateConVar("sm_tracers_default_visible", "1", "The default visibility index applied to new players. (0 = Player Only, 1 = Team Only, 2 = All)", FCVAR_NONE, true, 0.0, true, 2.0);
	g_hConfigColor = CreateConVar("sm_tracers_config_color", "1", "If enabled, clients will be able to change the color of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConfigLifeTime = CreateConVar("sm_tracers_config_lifetime", "1", "If enabled, clients will be able to change the lifetime of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConfigWidth = CreateConVar("sm_tracers_config_width", "1", "If enabled, clients will be able to change the width of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConfigAlpha = CreateConVar("sm_tracers_config_alpha", "1", "If enabled, clients will be able to change the alpha value of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConfigMaterial = CreateConVar("sm_tracers_config_material", "1", "If enabled, clients will be able to change the material of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConfigVisible = CreateConVar("sm_tracers_config_visible", "1", "If enabled, clients will be able to change the visibility status of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "sm_tracers_v1");

	HookConVarChange(g_hEnabled, Action_OnSettingsChange);
	HookConVarChange(g_hFlags, Action_OnSettingsChange);
	HookConVarChange(g_hDefault, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultColor, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultLifeTime, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultWidth, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultAlpha, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultMaterial, Action_OnSettingsChange);
	HookConVarChange(g_hDefaultVisible, Action_OnSettingsChange);
	HookConVarChange(g_hConfigColor, Action_OnSettingsChange);
	HookConVarChange(g_hConfigLifeTime, Action_OnSettingsChange);
	HookConVarChange(g_hConfigWidth, Action_OnSettingsChange);
	HookConVarChange(g_hConfigAlpha, Action_OnSettingsChange);
	HookConVarChange(g_hConfigMaterial, Action_OnSettingsChange);
	HookConVarChange(g_hConfigVisible, Action_OnSettingsChange);
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("bullet_impact", Event_OnBulletImpact);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);

#if defined ENABLE_CLIENTPREFS
	SetCookieMenuItem(Menu_Cookies, 0, "Tracer Settings");
	g_cEnabled = RegClientCookie("PlayerTracers_Enabled", "Player Tracers: The client's tracer status.", CookieAccess_Protected);
	g_cColor = RegClientCookie("PlayerTracers_Color", "Player Tracers: The client's selected tracer color.", CookieAccess_Protected);
	g_cWidth = RegClientCookie("PlayerTracers_Width", "Player Tracers: The client's selected width value.", CookieAccess_Protected);
	g_cAlpha = RegClientCookie("PlayerTracers_Alpha", "Player Tracers: The client's selected alpha value.", CookieAccess_Protected);
	g_cLifeTime = RegClientCookie("PlayerTracers_Life", "Player Tracers: The client's selected lifetime value.", CookieAccess_Protected);
	g_cMaterial = RegClientCookie("PlayerTracers_Material", "Player Tracers: The client's selected material.", CookieAccess_Protected);
	g_cVisible = RegClientCookie("PlayerTracers_Visible", "Player Tracers: The client's selected visible status", CookieAccess_Protected);
#endif

	RegAdminCmd("sm_tracers_print", Command_Print, ADMFLAG_RCON, "Usage: sm_tracers_print, prints indexes to be used with sm_tracers_default_* cvars.");
	RegAdminCmd("sm_tracers_reload", Command_Reload, ADMFLAG_RCON, "Usage: sm_tracers_reload, reloads all configuration files and issues changes in-game.");
	
	g_hConfig = LoadGameConfigFile("sm_tracers.gamedata");
	if(g_hConfig == INVALID_HANDLE)
		LogError("LoadGameConfigFile(\"sm_tracers.gamedata\") doesn't appear to exist or is invalid.");
	else
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hConfig, SDKConf_Virtual, "Weapon_ShootPosition");
		PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
		g_hPosition = EndPrepSDKCall();
	}

	if(g_hPosition != INVALID_HANDLE)
		g_bValidSDK = true;
	else
	{
		g_bValidSDK = false;
		LogError("Error: Weapon_ShootPosition signature appears to be invalid; activating secondary methods.");
	}
	
	Define_Colors();
	Define_Configs();
	Define_Materials();
	Void_Prepare();
}

public OnPluginEnd()
{
	if(g_bEnabled)
	{
		ClearTrie(g_hTrie);
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

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Format(g_sPrefixChat, 32, "%T", "Prefix_Chat", LANG_SERVER);
		Format(g_sPrefixSelect, 16, "%T", "Menu_Option_Selected", LANG_SERVER);
		Format(g_sPrefixEmpty, 16, "%T", "Menu_Option_Empty", LANG_SERVER);

		if(g_hTrie == INVALID_HANDLE)
		{
			g_hTrie = CreateTrie();
			SetTrieValue(g_hTrie, "!tracers", 1);
			SetTrieValue(g_hTrie, "/tracers", 1);
			SetTrieValue(g_hTrie, "!tracer", 1);
			SetTrieValue(g_hTrie, "/tracer", 1);
		}
	
		if(g_bLateLoad)
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

					if(g_bAccess[i])
					{
#if defined ENABLE_CLIENTPREFS
						if(!g_bFake[i])
						{
							if(!g_bLoaded[i] && AreClientCookiesCached(i))
								Void_LoadCookies(i);
						}
						else
						{
							g_iAppear[i] = g_iDefault;
							g_bLoaded[i] = true;

							g_iTracerData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
							g_iTracerData[i][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, (g_iNumWidths - 1)) : g_iDefaultWidth;
							g_iTracerData[i][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, (g_iNumAlphas - 1)) : g_iDefaultAlpha;
							g_iTracerData[i][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iNumLifes - 1)) : g_iDefaultLifeTime;
							g_iTracerData[i][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
							g_iTracerData[i][INDEX_VISIBLE] = g_iDefaultVisible;
							
							decl String:_sBuffer[3][8];
							ExplodeString(g_sColorSchemes[g_iTracerData[i][INDEX_COLOR]], " ", _sBuffer, 3, 8);
							for(new j = 0; j <= 2; j++)
								g_iColors[i][j] = StringToInt(_sBuffer[j]);
							g_iColors[i][3] = g_iAlphas[g_iTracerData[i][INDEX_ALPHA]];
						}
					}
#else
					g_iAppear[i] = g_iDefault;
					g_bLoaded[i] = true;

					g_iTracerData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
					g_iTracerData[i][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, (g_iNumWidths - 1)) : g_iDefaultWidth;
					g_iTracerData[i][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, (g_iNumAlphas - 1)) : g_iDefaultAlpha;
					g_iTracerData[i][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iNumLifes - 1)) : g_iDefaultLifeTime;
					g_iTracerData[i][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
					g_iTracerData[i][INDEX_VISIBLE] = g_iDefaultVisible;
					
					decl String:_sBuffer[3][8];
					ExplodeString(g_sColorSchemes[g_iTracerData[i][INDEX_COLOR]], " ", _sBuffer, 3, 8);
					for(new j = 0; j <= 2; j++)
						g_iColors[i][j] = StringToInt(_sBuffer[j]);
					g_iColors[i][3] = g_iAlphas[g_iTracerData[i][INDEX_ALPHA]];
#endif
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

		if(g_bAccess[client])
		{
#if defined ENABLE_CLIENTPREFS
			if(!g_bFake[client])
			{
				if(!g_bLoaded[client] && AreClientCookiesCached(client))
					Void_LoadCookies(client);
			}
			else
			{
				g_bLoaded[client] = true;
				g_iAppear[client] = g_iDefault;

				g_iTracerData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
				g_iTracerData[client][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, (g_iNumWidths - 1)) : g_iDefaultWidth;
				g_iTracerData[client][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, (g_iNumAlphas - 1)) : g_iDefaultAlpha;
				g_iTracerData[client][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iNumLifes - 1)) : g_iDefaultLifeTime;
				g_iTracerData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
				g_iTracerData[client][INDEX_VISIBLE] = g_iDefaultVisible;
				
				decl String:_sBuffer[3][8];
				ExplodeString(g_sColorSchemes[g_iTracerData[client][INDEX_COLOR]], " ", _sBuffer, 3, 8);
				for(new i = 0; i <= 2; i++)
					g_iColors[client][i] = StringToInt(_sBuffer[i]);
				g_iColors[client][3] = g_iAlphas[g_iTracerData[client][INDEX_ALPHA]];
			}
#else
			g_bLoaded[client] = true;
			g_iAppear[client] = g_iDefault;

			g_iTracerData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
			g_iTracerData[client][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, (g_iNumWidths - 1)) : g_iDefaultWidth;
			g_iTracerData[client][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, (g_iNumAlphas - 1)) : g_iDefaultAlpha;
			g_iTracerData[client][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iNumLifes - 1)) : g_iDefaultLifeTime;
			g_iTracerData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
			g_iTracerData[client][INDEX_VISIBLE] = g_iDefaultVisible;
			
			decl String:_sBuffer[3][8];
			ExplodeString(g_sColorSchemes[g_iTracerData[client][INDEX_COLOR]], " ", _sBuffer, 3, 8);
			for(new i = 0; i <= 2; i++)
				g_iColors[client][i] = StringToInt(_sBuffer[i]);
			g_iColors[client][3] = g_iAlphas[g_iTracerData[client][INDEX_ALPHA]];
#endif
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
		g_iAppear[client] = false;
	}
}

#if defined ENABLE_CLIENTPREFS
public OnClientCookiesCached(client)
{
	if(!g_bLoaded[client] && !g_bFake[client])
	{
		Void_LoadCookies(client);
	}
}
#endif

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] <= 1)
			g_bAlive[client] = false;
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
	}
	
	return Plugin_Continue;
}

public Action:Event_OnBulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(g_iAppear[client] && g_bAccess[client])
		{
			decl Float:_fOrigin[3], Float:_fImpact[3], Float:_fDifference[3];
			if(g_bValidSDK)
			{
				SDKCall(g_hPosition, client, _fOrigin);
				_fImpact[0] = GetEventFloat(event, "x");
				_fImpact[1] = GetEventFloat(event, "y");
				_fImpact[2] = GetEventFloat(event, "z");

				new Float:_fDistance = GetVectorDistance(_fOrigin, _fImpact);
				new Float:_fPercent = (0.4 / (_fDistance / 100.0));

				_fDifference[0] = _fOrigin[0] + ((_fImpact[0] - _fOrigin[0]) * _fPercent);
				_fDifference[1] = _fOrigin[1] + ((_fImpact[1] - _fOrigin[1]) * _fPercent) - 0.08;
				_fDifference[2] = _fOrigin[2] + ((_fImpact[2] - _fOrigin[2]) * _fPercent);
			}
			else
			{
				GetClientEyePosition(client, _fDifference);
				GetClientEyeAngles(client, _fOrigin);
				new Handle:_hTemp = TR_TraceRayFilterEx(_fDifference, _fOrigin, MASK_SHOT_HULL, RayType_Infinite, Bool_TraceFilterPlayers);
				
				if(TR_DidHit(_hTemp))
					TR_GetEndPosition(_fImpact, _hTemp);
				else
				{
					CloseHandle(_hTemp);
					return Plugin_Continue;
				}

				CloseHandle(_hTemp);
			}
			
			switch(g_iTracerData[client][INDEX_VISIBLE])
			{
				case VISIBLE_ONE:
				{
					TE_SetupBeamPoints(_fDifference, _fImpact, g_iMaterialIndexes[g_iTracerData[client][INDEX_MATERIAL]], 0, 0, 0, g_fLifeTimes[g_iTracerData[client][INDEX_LIFE]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], 1, 0.0, g_iColors[client], 0);
					TE_SendToClient(client);
				}
				case VISIBLE_TEAM:
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && g_iAppear[i] && (g_iTeam[i] == g_iTeam[client] || g_iTeam[i] == 1))
						{
							TE_SetupBeamPoints(_fDifference, _fImpact, g_iMaterialIndexes[g_iTracerData[client][INDEX_MATERIAL]], 0, 0, 0, g_fLifeTimes[g_iTracerData[client][INDEX_LIFE]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], 1, 0.0, g_iColors[client], 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_ALL:
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && g_iAppear[i])
						{
							TE_SetupBeamPoints(_fDifference, _fImpact, g_iMaterialIndexes[g_iTracerData[client][INDEX_MATERIAL]], 0, 0, 0, g_fLifeTimes[g_iTracerData[client][INDEX_LIFE]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], 1, 0.0, g_iColors[client], 0);
							TE_SendToClient(i);
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public bool:Bool_TraceFilterPlayers(entity, contentsMask, any:client) 
{
	return !entity || entity > MaxClients;
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		decl _iSize, String:_sText[192];
		GetCmdArgString(_sText, sizeof(_sText));
		StripQuotes(_sText);
		TrimString(_sText);
		
		_iSize = strlen(_sText);
		for (new i = 0; i < _iSize; i++)
			if (IsCharAlpha(_sText[i]) && IsCharUpper(_sText[i]))
				_sText[i] = CharToLower(_sText[i]);

		if(GetTrieValue(g_hTrie, _sText, _iSize))
		{
			if(Menu_Tracers(client))
				return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

public Action:Command_Print(client, args)
{
	ReplyToCommand(client, "%sPlease check your console for index data.", g_sPrefixChat);
	new _iArray[2];
	if(client)
		_iArray[0] = GetClientUserId(client);
	else
		_iArray[0] = 0;

	for(_iArray[1] = 1; _iArray[1] <= 5; _iArray[1]++)
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
	ReplyToCommand(client, "%sSettings have been reloaded!", g_sPrefixChat);

	Define_Colors();
	Define_Configs();
	Define_Materials();
	Void_Prepare();
	for(new i = 1; i <= MaxClients; i++)
	{
		g_bLoaded[i] = false;
		g_bAccess[i] = false;
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

			if(g_bAccess[i])
			{
#if defined ENABLE_CLIENTPREFS
				if(!g_bFake[i])
				{
					if(!g_bLoaded[i] && AreClientCookiesCached(i))
						Void_LoadCookies(i);
				}
				else
				{
					g_bLoaded[i] = true;
					g_iAppear[i] = g_iDefault;

					g_iTracerData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
					g_iTracerData[i][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, (g_iNumWidths - 1)) : g_iDefaultWidth;
					g_iTracerData[i][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, (g_iNumAlphas - 1)) : g_iDefaultAlpha;
					g_iTracerData[i][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iNumLifes - 1)) : g_iDefaultLifeTime;
					g_iTracerData[i][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
					g_iTracerData[i][INDEX_VISIBLE] = g_iDefaultVisible;
					
					decl String:_sBuffer[3][8];
					ExplodeString(g_sColorSchemes[g_iTracerData[i][INDEX_COLOR]], " ", _sBuffer, 3, 8);
					for(new j = 0; j <= 2; j++)
						g_iColors[i][j] = StringToInt(_sBuffer[j]);
					g_iColors[i][3] = g_iAlphas[g_iTracerData[i][INDEX_ALPHA]];
				}
#else
				g_bLoaded[i] = g_iDefault;
				g_iAppear[i] = true;

				g_iTracerData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
				g_iTracerData[i][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, (g_iNumWidths - 1)) : g_iDefaultWidth;
				g_iTracerData[i][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, (g_iNumAlphas - 1)) : g_iDefaultAlpha;
				g_iTracerData[i][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iNumLifes - 1)) : g_iDefaultLifeTime;
				g_iTracerData[i][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
				g_iTracerData[i][INDEX_VISIBLE] = g_iDefaultVisible;
				
				decl String:_sBuffer[3][8];
				ExplodeString(g_sColorSchemes[g_iTracerData[i][INDEX_COLOR]], " ", _sBuffer, 3, 8);
				for(new j = 0; j <= 2; j++)
					g_iColors[i][j] = StringToInt(_sBuffer[j]);
				g_iColors[i][3] = g_iAlphas[g_iTracerData[i][INDEX_ALPHA]];
#endif
			}
		}
	}

	return Plugin_Handled;
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
				ReplyToCommand(client, "Tracers - Colors: Index (%d), Name (%s), Colors (%s)", i, g_sColorNames[i], g_sColorSchemes[i]);
		case 2:
			for(new i = 0; i < g_iNumWidths; i++)
				ReplyToCommand(client, "Tracers - Widths: Index (%d), Value: (%f)", i, g_fWidths[i]);
		case 3:
			for(new i = 0; i < g_iNumAlphas; i++)
				ReplyToCommand(client, "Tracers - Alphas: Index (%d), Value: (%d)", i, g_iAlphas[i]);
		case 4:
			for(new i = 0; i < g_iNumLifes; i++)
				ReplyToCommand(client, "Tracers - Lifetimes: Index (%d), Value: (%f)", i, g_fLifeTimes[i]);
		case 5:
			for(new i = 0; i < g_iMaterials; i++)
				ReplyToCommand(client, "Tracers - Materials: Index (%d), Name: (%s), Path: (%s)", i, g_sMaterialNames[i], g_sMaterialPaths[i]);
	}
	ReplyToCommand(client, "--------------------------");
	CloseHandle(_hPack);
}

Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_iDefault = GetConVarInt(g_hDefault);
	g_iDefaultColor = GetConVarInt(g_hDefaultColor);
	g_iDefaultLifeTime = GetConVarInt(g_hDefaultLifeTime);
	g_iDefaultWidth = GetConVarInt(g_hDefaultWidth);
	g_iDefaultAlpha = GetConVarInt(g_hDefaultAlpha);
	g_iDefaultMaterial = GetConVarInt(g_hDefaultMaterial);
	g_iDefaultVisible = GetConVarInt(g_hDefaultVisible);
	g_bConfigColor = GetConVarInt(g_hConfigColor) ? true : false;
	g_bConfigLifeTime = GetConVarInt(g_hConfigLifeTime) ? true : false;
	g_bConfigWidth = GetConVarInt(g_hConfigWidth) ? true : false;
	g_bConfigAlpha = GetConVarInt(g_hConfigAlpha) ? true : false;
	g_bConfigMaterial = GetConVarInt(g_hConfigMaterial) ? true : false;
	g_bConfigVisible = GetConVarInt(g_hConfigVisible) ? true : false;
	
	decl String:_sFlag[32], String:_sBuffer[MAX_DEFINED_FLAGS][8];
	GetConVarString(g_hFlags, _sFlag, 32);
	g_iNumFlags = ExplodeString(_sFlag, ", ", _sBuffer, MAX_DEFINED_FLAGS, 8);
	for(new i = 0; i < g_iNumFlags; i++)
		g_iFlag[i] = ReadFlagString(_sBuffer[i]);
		
	if(g_iDefaultColor >= g_iNumColors)
		g_iDefaultColor = (g_iNumColors - 1);
	if(g_iDefaultLifeTime >= g_iNumLifes)
		g_iDefaultLifeTime = (g_iNumLifes - 1);
	if(g_iDefaultWidth >= g_iNumWidths)
		g_iDefaultWidth = (g_iNumWidths - 1);
	if(g_iDefaultAlpha >= g_iNumAlphas)
		g_iDefaultAlpha = (g_iNumAlphas - 1);
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
			Define_Colors();
			Define_Configs();
			Define_Materials();
			Void_Prepare();
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
#if defined ENABLE_CLIENTPREFS
					if(!g_bFake[i])
					{
						if(!g_bLoaded[i] && AreClientCookiesCached(i))
							Void_LoadCookies(i);
					}
					else
					{
						g_bLoaded[i] = true;
						g_iAppear[i] = g_iDefault;

						g_iTracerData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
						g_iTracerData[i][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, (g_iNumWidths - 1)) : g_iDefaultWidth;
						g_iTracerData[i][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, (g_iNumAlphas - 1)) : g_iDefaultAlpha;
						g_iTracerData[i][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iNumLifes - 1)) : g_iDefaultLifeTime;
						g_iTracerData[i][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
						g_iTracerData[i][INDEX_VISIBLE] = g_iDefaultVisible;
						
						decl String:_sBuffer2[3][8];
						ExplodeString(g_sColorSchemes[g_iTracerData[i][INDEX_COLOR]], " ", _sBuffer2, 3, 8);
						for(new j = 0; j <= 2; j++)
							g_iColors[i][j] = StringToInt(_sBuffer2[j]);
						g_iColors[i][3] = g_iAlphas[g_iTracerData[i][INDEX_ALPHA]];
					}
#else
					g_bLoaded[i] = true;
					g_iAppear[i] = g_iDefault;

					g_iTracerData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
					g_iTracerData[i][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, (g_iNumWidths - 1)) : g_iDefaultWidth;
					g_iTracerData[i][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, (g_iNumAlphas - 1)) : g_iDefaultAlpha;
					g_iTracerData[i][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iNumLifes - 1)) : g_iDefaultLifeTime;
					g_iTracerData[i][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
					g_iTracerData[i][INDEX_VISIBLE] = g_iDefaultVisible;
					
					decl String:_sBuffer2[3][8];
					ExplodeString(g_sColorSchemes[g_iTracerData[i][INDEX_COLOR]], " ", _sBuffer2, 3, 8);
					for(new j = 0; j <= 2; j++)
						g_iColors[i][j] = StringToInt(_sBuffer2[j]);
					g_iColors[i][3] = g_iAlphas[g_iTracerData[i][INDEX_ALPHA]];
#endif
				}
				else
					g_iAppear[i] = g_iDefault;
			}
			else
			{
				g_iTeam[i] = 0;
				g_bAlive[i] = false;
			}
		}
	}
	else if(cvar == g_hDefault)
		g_iDefault = StringToInt(newvalue);
	else if(cvar == g_hDefaultColor)
	{
		g_iDefaultColor = StringToInt(newvalue);
		if(g_iDefaultColor >= g_iNumColors)
			g_iDefaultColor = (g_iNumColors - 1);
	}
	else if(cvar == g_hDefaultLifeTime)
	{
		g_iDefaultLifeTime = StringToInt(newvalue);
		if(g_iDefaultLifeTime >= g_iNumLifes)
			g_iDefaultLifeTime = (g_iNumLifes - 1);
	}
	else if(cvar == g_hDefaultWidth)
	{
		g_iDefaultWidth = StringToInt(newvalue);
		if(g_iDefaultWidth >= g_iNumWidths)
			g_iDefaultWidth = (g_iNumWidths - 1);
	}
	else if(cvar == g_hDefaultAlpha)
	{
		g_iDefaultAlpha = StringToInt(newvalue);
		if(g_iDefaultAlpha >= g_iNumAlphas)
			g_iDefaultAlpha = (g_iNumAlphas - 1);
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
		g_bConfigColor = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hConfigLifeTime)
		g_bConfigLifeTime = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hConfigWidth)
		g_bConfigWidth = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hConfigAlpha)
		g_bConfigAlpha = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hConfigMaterial)
		g_bConfigMaterial = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hConfigVisible)
		g_bConfigVisible = StringToInt(newvalue) ? true : false;
}

Define_Colors()
{
	decl String:_sPath[256];
	new Handle:_hKV = CreateKeyValues("PlayerTracers_Colors");
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/tracers/sm_tracers_colors.ini");

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
			SetFailState("Tracers: There were no colors defined in sm_tracers_colors.ini!");
			return;
		}
	}
	else
	{
		CloseHandle(_hKV);
		SetFailState("Tracers: Unable to locate the file sourcemod/configs/tracers/sm_tracers_colors.ini!");
		return;		
	}

	CloseHandle(_hKV);
}

Define_Configs()
{
	decl String:_sPath[256];
	new Handle:_hKV = CreateKeyValues("PlayerTracers_Configs");
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/tracers/sm_tracers_configs.ini");
	
	if(FileToKeyValues(_hKV, _sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			decl String:_sBuffer[64];
			KvGetSectionName(_hKV, _sBuffer, sizeof(_sBuffer));
			
			if(StrEqual(_sBuffer, "Width_Values", false))
			{
				decl String:_sTemp[8];
				g_iNumWidths = 0;

				KvGetString(_hKV, "accurate_count", _sTemp, sizeof(_sTemp));
				new Float:_fAccurateCount = StringToFloat(_sTemp);
				if(_fAccurateCount)
				{
					KvGetString(_hKV, "accurate_factor", _sTemp, sizeof(_sTemp));
					new Float:_fAccurateFactor = StringToFloat(_sTemp);

					for(new Float:i = 1.0; i <= _fAccurateCount; i++)
						g_fWidths[g_iNumWidths++] = (_fAccurateFactor * i);
				}
				
				KvGetString(_hKV, "regular_count", _sTemp, sizeof(_sTemp));
				new Float:_fRegularCount = StringToFloat(_sTemp);
				if(_fRegularCount)
				{
					KvGetString(_hKV, "regular_factor", _sTemp, sizeof(_sTemp));
					new Float:_fRegularFactor = StringToFloat(_sTemp);
					
					for(new Float:i = 1.0; i <= _fRegularCount; i++)
						g_fWidths[g_iNumWidths++] = (_fRegularFactor * i);
				}
			}
			else if(StrEqual(_sBuffer, "Alpha_Values", false))
			{
				decl String:_sTemp[8];
				g_iNumAlphas = 0;

				KvGetString(_hKV, "accurate_count", _sTemp, sizeof(_sTemp));
				new _iAccurateCount = StringToInt(_sTemp);
				if(_iAccurateCount)
				{
					KvGetString(_hKV, "accurate_factor", _sTemp, sizeof(_sTemp));
					new _iAccurateFactor = StringToInt(_sTemp);
					
					for(new i = 1; i <= _iAccurateCount; i++)
						g_iAlphas[g_iNumAlphas++] = (_iAccurateFactor * i);
				}
				
				KvGetString(_hKV, "regular_count", _sTemp, sizeof(_sTemp));
				new _iRegularCount = StringToInt(_sTemp);
				if(_iRegularCount)
				{
					KvGetString(_hKV, "regular_factor", _sTemp, sizeof(_sTemp));
					new _iRegularFactor = StringToInt(_sTemp);
	
					for(new i = 1; i <= _iRegularCount; i++)
						g_iAlphas[g_iNumAlphas++] = (_iRegularFactor * i);
				}
			}
			else if(StrEqual(_sBuffer, "Life_Values", false))
			{
				decl String:_sTemp[8];
				g_iNumLifes = 0;

				KvGetString(_hKV, "accurate_count", _sTemp, sizeof(_sTemp));
				new Float:_fAccurateCount = StringToFloat(_sTemp);
				if(_fAccurateCount)
				{
					KvGetString(_hKV, "accurate_factor", _sTemp, sizeof(_sTemp));
					new Float:_fAccurateFactor = StringToFloat(_sTemp);
					
					for(new Float:i = 1.0; i <= _fAccurateCount; i++)
						g_fLifeTimes[g_iNumLifes++] = (_fAccurateFactor * i);
				}
				
				KvGetString(_hKV, "regular_count", _sTemp, sizeof(_sTemp));
				new Float:_fRegularCount = StringToFloat(_sTemp);
				if(_fRegularCount)
				{
					KvGetString(_hKV, "regular_factor", _sTemp, sizeof(_sTemp));
					new Float:_fRegularFactor = StringToFloat(_sTemp);
					
					for(new Float:i = 1.0; i <= _fRegularCount; i++)
						g_fLifeTimes[g_iNumLifes++] = (_fRegularFactor * i);
				}
			}
		}
		while (KvGotoNextKey(_hKV));
	}
	else
	{
		CloseHandle(_hKV);
		SetFailState("Tracers: Unable to locate the file sourcemod/configs/tracers/sm_tracers_configs.ini!");
		return;		
	}

	CloseHandle(_hKV);
}

Define_Materials()
{
	decl String:_sPath[256];
	new Handle:_hKV = CreateKeyValues("PlayerTracers_Materials");
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/tracers/sm_tracers_materials.ini");
	
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
			SetFailState("Tracers: There were no materials defined in sm_tracers_materials.ini!");
			return;
		}
	}
	else
	{
		CloseHandle(_hKV);
		SetFailState("Tracers: Unable to locate the file sourcemod/configs/tracers/sm_tracers_materials.ini!");
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

		g_iMaterialIndexes[i] = PrecacheModel(_sBuffer, true);
		AddFileToDownloadsTable(_sBuffer);
		ReplaceString(_sBuffer, sizeof(_sBuffer), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(_sBuffer);
	}
}

#if defined ENABLE_CLIENTPREFS
Void_LoadCookies(client)
{
	decl String:_sCookie[4] = "";
	GetClientCookie(client, g_cEnabled, _sCookie, sizeof(_sCookie));

	if(StrEqual(_sCookie, "", false))
	{
		_sCookie = g_iDefault ? "1" : "0";
		g_iAppear[client] = StringToInt(_sCookie) ? true : false;
		SetClientCookie(client, g_cEnabled, _sCookie);

		g_iTracerData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;
		IntToString(g_iTracerData[client][INDEX_COLOR], _sCookie, 4);
		SetClientCookie(client, g_cColor, _sCookie);

		g_iTracerData[client][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, (g_iNumWidths - 1)) : g_iDefaultWidth;
		IntToString(g_iTracerData[client][INDEX_WIDTH], _sCookie, 4);
		SetClientCookie(client, g_cWidth, _sCookie);

		g_iTracerData[client][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, (g_iNumAlphas - 1)) : g_iDefaultAlpha;
		IntToString(g_iTracerData[client][INDEX_ALPHA], _sCookie, 4);
		SetClientCookie(client, g_cAlpha, _sCookie);

		g_iTracerData[client][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iNumLifes - 1)) : g_iDefaultLifeTime;
		IntToString(g_iTracerData[client][INDEX_LIFE], _sCookie, 4);
		SetClientCookie(client, g_cLifeTime, _sCookie);

		g_iTracerData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;
		IntToString(g_iTracerData[client][INDEX_MATERIAL], _sCookie, 4);
		SetClientCookie(client, g_cMaterial, _sCookie);
		
		g_iTracerData[client][INDEX_VISIBLE] = g_iDefaultVisible;
		IntToString(g_iTracerData[client][INDEX_VISIBLE], _sCookie, 4);
		SetClientCookie(client, g_cVisible, _sCookie);
	}
	else
	{
		g_iAppear[client] = (StringToInt(_sCookie) || g_iDefault == TRACERS_FORCED) ? true : false;

		if(g_bConfigColor)
		{
			GetClientCookie(client, g_cColor, _sCookie, 4);
			g_iTracerData[client][INDEX_COLOR] = StringToInt(_sCookie);
			if(g_iTracerData[client][INDEX_COLOR] >= g_iNumColors)
			{
				g_iTracerData[client][INDEX_COLOR] = (g_iNumColors - 1);
				IntToString(g_iTracerData[client][INDEX_COLOR], _sCookie, 4);
				SetClientCookie(client, g_cColor, _sCookie);
			}
		}
		else
			g_iTracerData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, (g_iNumColors - 1)) : g_iDefaultColor;

		if(g_bConfigWidth)
		{
			GetClientCookie(client, g_cWidth, _sCookie, 4);
			g_iTracerData[client][INDEX_WIDTH] = StringToInt(_sCookie);
			if(g_iTracerData[client][INDEX_WIDTH] >= g_iNumWidths)
			{
				g_iTracerData[client][INDEX_WIDTH] = (g_iNumWidths - 1);
				IntToString(g_iTracerData[client][INDEX_WIDTH], _sCookie, 4);
				SetClientCookie(client, g_cWidth, _sCookie);
			}
		}
		else
			g_iTracerData[client][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, (g_iNumWidths - 1)) : g_iDefaultWidth;

		if(g_bConfigAlpha)
		{
			GetClientCookie(client, g_cAlpha, _sCookie, 4);
			g_iTracerData[client][INDEX_ALPHA] = StringToInt(_sCookie);
			if(g_iTracerData[client][INDEX_ALPHA] >= g_iNumAlphas)
			{
				g_iTracerData[client][INDEX_ALPHA] = (g_iNumAlphas - 1);
				IntToString(g_iTracerData[client][INDEX_ALPHA], _sCookie, 4);
				SetClientCookie(client, g_cAlpha, _sCookie);
			}
		}
		else
			g_iTracerData[client][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, (g_iNumAlphas - 1)) : g_iDefaultAlpha;

		if(g_bConfigLifeTime)
		{
			GetClientCookie(client, g_cLifeTime, _sCookie, 4);
			g_iTracerData[client][INDEX_LIFE] = StringToInt(_sCookie);
			if(g_iTracerData[client][INDEX_LIFE] >= g_iNumLifes)
			{
				g_iTracerData[client][INDEX_LIFE] = (g_iNumLifes - 1);
				IntToString(g_iTracerData[client][INDEX_LIFE], _sCookie, 4);
				SetClientCookie(client, g_cLifeTime, _sCookie);
			}
		}
		else
			g_iTracerData[client][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, (g_iNumLifes - 1)) : g_iDefaultLifeTime;

		if(g_bConfigMaterial)
		{
			GetClientCookie(client, g_cMaterial, _sCookie, 4);
			g_iTracerData[client][INDEX_MATERIAL] = StringToInt(_sCookie);
			if(g_iTracerData[client][INDEX_MATERIAL] >= g_iMaterials)
			{
				g_iTracerData[client][INDEX_MATERIAL] = (g_iMaterials - 1);
				IntToString(g_iTracerData[client][INDEX_MATERIAL], _sCookie, 4);
				SetClientCookie(client, g_cMaterial, _sCookie);
			}
		}
		else
			g_iTracerData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, (g_iMaterials - 1)) : g_iDefaultMaterial;

		if(g_bConfigVisible)
		{
			GetClientCookie(client, g_cVisible, _sCookie, 4);
			g_iTracerData[client][INDEX_VISIBLE] = StringToInt(_sCookie);
		}
		else
			g_iTracerData[client][INDEX_VISIBLE] = g_iDefaultVisible;
	}

	decl String:_sBuffer[3][8];
	ExplodeString(g_sColorSchemes[g_iTracerData[client][INDEX_COLOR]], " ", _sBuffer, 3, 8);
	for(new i = 0; i <= 2; i++)
		g_iColors[client][i] = StringToInt(_sBuffer[i]);
	g_iColors[client][3] = g_iAlphas[g_iTracerData[client][INDEX_ALPHA]];
	
	g_bLoaded[client] = true;
}

public Menu_Cookies(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "%t", "Menu_Title_Cookie", client);
		case CookieMenuAction_SelectOption:
		{
			if(client && IsClientInGame(client))
				Menu_Tracers(client);
		}
	}
}
#endif

Menu_Tracers(client)
{
	decl String:_sBuffer[128];
	new _iOptions, Handle:_hMenu = CreateMenu(MenuHandler_MenuTracers);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Main", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);

	if(g_iDefault != TRACERS_FORCED)
	{
		_iOptions++;
		if(g_iAppear[client])
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Disable", client);
		else
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Enable", client);
		AddMenuItem(_hMenu, "0", _sBuffer);
	}
	
	new _iState = g_bAccess[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	if(g_bConfigVisible)
	{
		_iOptions++;
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Visibility", client);
		AddMenuItem(_hMenu, "6", _sBuffer, _iState);
	}
	
	if(g_iNumColors > 1 && g_bConfigColor)
	{
		_iOptions++;
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Color", client);
		AddMenuItem(_hMenu, "1", _sBuffer, _iState);
	}

	if(g_iMaterials > 1 && g_bConfigMaterial)
	{
		_iOptions++;
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Material", client);
		AddMenuItem(_hMenu, "2", _sBuffer, _iState);
	}

	if(g_iNumWidths > 1 && g_bConfigWidth)
	{
		_iOptions++;
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Width", client);
		AddMenuItem(_hMenu, "3", _sBuffer, _iState);
	}
	
	if(g_iNumAlphas > 1 && g_bConfigAlpha)
	{
		_iOptions++;
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Alpha", client);
		AddMenuItem(_hMenu, "4", _sBuffer, _iState);
	}
	
	if(g_iNumLifes > 1 && g_bConfigLifeTime)
	{
		_iOptions++;
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Life", client);
		AddMenuItem(_hMenu, "5", _sBuffer, _iState);
	}
	
	if(_iOptions)
		DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
		
	return _iOptions;
}

public MenuHandler_MenuTracers(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel: 
		{
			switch (param2) 
			{
#if defined ENABLE_CLIENTPREFS
				case MenuCancel_ExitBack:
					ShowCookieMenu(param1);
#endif
			}
		}
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));

			switch(StringToInt(_sTemp))
			{
				case 0:
				{
					if(!g_iAppear[param1])
					{
						g_iAppear[param1] = true;
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Enable");
						SetClientCookie(param1, g_cEnabled, "1");
					}
					else
					{
						g_iAppear[param1] = false;
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Disable");
						SetClientCookie(param1, g_cEnabled, "0");
					}
					
					Menu_Tracers(param1);
				}
				case 1:
					Menu_Colors(param1);
				case 2:	
					Menu_Materials(param1);
				case 3:
					Menu_Widths(param1);
				case 4:
					Menu_Alphas(param1);
				case 5:
					Menu_LifeTimes(param1);
				case 6:
					Menu_Visible(param1);
			}
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
			Format(_sBuffer, sizeof(_sBuffer), "%s%s", (g_iTracerData[client][INDEX_COLOR] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sColorNames[i]);
			IntToString(i, _sTemp, sizeof(_sTemp));
			AddMenuItem(_hMenu, _sTemp, _sBuffer);
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
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8], String:_sBuffer[3][8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTracerData[param1][INDEX_COLOR] = StringToInt(_sTemp);
			
			ExplodeString(g_sColorSchemes[g_iTracerData[param1][INDEX_COLOR]], " ", _sBuffer, 3, 8);
			for(new i = 0; i <= 2; i++)
				g_iColors[param1][i] = StringToInt(_sBuffer[i]);
			
			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Color", g_sColorNames[g_iTracerData[param1][INDEX_COLOR]]);
			SetClientCookie(param1, g_cColor, _sTemp);
			Menu_Colors(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_Widths(client, index = 0)
{
	decl String:_sTemp[8], String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuWidths);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Width", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i < g_iNumWidths; i++)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%s%.2f", (g_iTracerData[client][INDEX_WIDTH] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_fWidths[i]);
		IntToString(i, _sTemp, sizeof(_sTemp));
		AddMenuItem(_hMenu, _sTemp, _sBuffer);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuWidths(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTracerData[param1][INDEX_WIDTH] = StringToInt(_sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Width", g_fWidths[g_iTracerData[param1][INDEX_WIDTH]]);
			SetClientCookie(param1, g_cWidth, _sTemp);
			Menu_Widths(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_Alphas(client, index = 0)
{
	decl String:_sTemp[8], String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuAlphas);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Alpha", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i < g_iNumAlphas; i++)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%s%d", (g_iTracerData[client][INDEX_ALPHA] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_iAlphas[i]);
		IntToString(i, _sTemp, sizeof(_sTemp));
		AddMenuItem(_hMenu, _sTemp, _sBuffer);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuAlphas(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTracerData[param1][INDEX_ALPHA] = StringToInt(_sTemp);
			g_iColors[param1][3] = g_iAlphas[g_iTracerData[param1][INDEX_ALPHA]];
			
			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Alpha", g_iAlphas[g_iTracerData[param1][INDEX_ALPHA]]);
			SetClientCookie(param1, g_cAlpha, _sTemp);
			Menu_Alphas(param1, GetMenuSelectionPosition());
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

	for(new i = 0; i < g_iNumLifes; i++)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%s%.2f", (g_iTracerData[client][INDEX_LIFE] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_fLifeTimes[i]);
		IntToString(i, _sTemp, sizeof(_sTemp));
		AddMenuItem(_hMenu, _sTemp, _sBuffer);
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
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTracerData[param1][INDEX_LIFE] = StringToInt(_sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Life", g_fLifeTimes[g_iTracerData[param1][INDEX_LIFE]]);
			SetClientCookie(param1, g_cLifeTime, _sTemp);
			Menu_LifeTimes(param1, GetMenuSelectionPosition());
		}
	}

	return;
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
			Format(_sBuffer, sizeof(_sBuffer), "%s%s", (g_iTracerData[client][INDEX_MATERIAL] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sMaterialNames[i]);
			IntToString(i, _sTemp, sizeof(_sTemp));
			AddMenuItem(_hMenu, _sTemp, _sBuffer);
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
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			g_iTracerData[param1][INDEX_MATERIAL] = StringToInt(_sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Material", g_sMaterialNames[g_iTracerData[param1][INDEX_MATERIAL]]);
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

	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Visibility_Single", client, (g_iTracerData[client][INDEX_VISIBLE] == VISIBLE_ONE) ? g_sPrefixSelect : g_sPrefixEmpty);
	AddMenuItem(_hMenu, "0", _sBuffer);

	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Visibility_Team", client, (g_iTracerData[client][INDEX_VISIBLE] == VISIBLE_TEAM) ? g_sPrefixSelect : g_sPrefixEmpty);
	AddMenuItem(_hMenu, "1", _sBuffer);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Option_Visibility_All", client, (g_iTracerData[client][INDEX_VISIBLE] == VISIBLE_ALL) ? g_sPrefixSelect : g_sPrefixEmpty);
	AddMenuItem(_hMenu, "2", _sBuffer);
	
	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuVisible(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			new _iTemp = StringToInt(_sTemp);

			if(_iTemp != g_iTracerData[param1][INDEX_VISIBLE])
			{
				g_iTracerData[param1][INDEX_VISIBLE] = _iTemp;
				switch(g_iTracerData[param1][INDEX_VISIBLE])
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