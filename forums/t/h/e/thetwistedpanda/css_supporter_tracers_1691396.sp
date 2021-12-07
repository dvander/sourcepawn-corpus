/*
	Revision 2.0.5
	Added an additional check to prevent the plugin looking for DHooks if the plugin was compiled with DHooks.
	Removed the requirement for Weapon_ShootPosition gamedata.
	Gamedata is now only checked for Dynamic Hooks, and only if DHooks is loaded.
	Fixed a bug where Knife Tracers didn't obey whether a client had permissions.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <sdkhooks>
#include <clientprefs>
#undef REQUIRE_EXTENSIONS
#tryinclude <dhooks>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "2.0.5"

//Maximum amount of definitions allowed.
#define MAX_DEFINED_COLORS 128
#define MAX_DEFINED_MATERIALS 128
#define MAX_DEFINED_WIDTHS 128
#define MAX_DEFINED_LIFES 128
#define MAX_DEFINED_ALPHAS 128

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

#define KNIFE_PRIMARY 1
#define KNIFE_SECONDARY 2

new g_iLoadColors, g_iLoadMaterials, g_iLoadConfigs;

//Colors
new g_iNumColors;
new String:g_sColorSchemes[MAX_DEFINED_COLORS][32];
new String:g_sColorNames[MAX_DEFINED_COLORS][64];
new g_iColorFlag[MAX_DEFINED_COLORS];

//Materials
new g_iMaterials;
new String:g_sMaterialPaths[MAX_DEFINED_MATERIALS][256];
new String:g_sMaterialNames[MAX_DEFINED_MATERIALS][64];
new g_iMaterialIndexes[MAX_DEFINED_MATERIALS];
new g_iMaterialFlag[MAX_DEFINED_MATERIALS];

//Configs
new g_iNumWidths, g_iNumAlphas, g_iNumLifes;
new Float:g_fWidths[MAX_DEFINED_WIDTHS];
new g_iAlphas[MAX_DEFINED_ALPHAS];
new Float:g_fLifeTimes[MAX_DEFINED_LIFES];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hFlag = INVALID_HANDLE;
new Handle:g_hDefault = INVALID_HANDLE;
new Handle:g_hKnife = INVALID_HANDLE;
new Handle:g_hChatCommands = INVALID_HANDLE;
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
new Handle:g_hGrenadeTrails = INVALID_HANDLE;
new Handle:g_cEnabled = INVALID_HANDLE;
new Handle:g_cColor = INVALID_HANDLE;
new Handle:g_cWidth = INVALID_HANDLE;
new Handle:g_cAlpha = INVALID_HANDLE;
new Handle:g_cLifeTime = INVALID_HANDLE;
new Handle:g_cMaterial = INVALID_HANDLE;
new Handle:g_cVisible = INVALID_HANDLE;
new Handle:g_hConfig = INVALID_HANDLE;
#if defined _dhooks_included
new Handle:g_hPrimaryAttack = INVALID_HANDLE;
new Handle:g_hSecondaryAttack = INVALID_HANDLE;
#endif

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new bool:g_bValid[MAXPLAYERS + 1];
new bool:g_bFake[MAXPLAYERS + 1];
new bool:g_bKnife[MAXPLAYERS + 1];
new g_iAppear[MAXPLAYERS + 1];
new g_iColors[MAXPLAYERS + 1][4];
new g_iTracerData[MAXPLAYERS + 1][INDEX_TOTAL];

new g_iProjTrail[2048];

new g_iDefault, g_iDefaultColor, g_iDefaultLifeTime, g_iDefaultWidth, g_iDefaultAlpha, g_iDefaultMaterial, g_iDefaultVisible, g_iAccessFlag, g_iNumCommands, g_iKnife;
new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bConfigColor, bool:g_bConfigLifeTime, bool:g_bConfigWidth, bool:g_bConfigAlpha, bool:g_bConfigMaterial, 
    bool:g_bConfigVisible, bool:g_bDynamicHooks, bool:g_bGrenadeTrails, bool:g_bLoadedHooks;
new String:g_sPrefixChat[32], String:g_sPrefixSelect[16], String:g_sPrefixEmpty[16], String:g_sChatCommands[16][32];

public Plugin:myinfo =
{
	name = "CSS Supporters: Tracers", 
	author = "Twisted|Panda", 
	description = "Provides both simple and advanced functionality for displaying tracers - beams that expand from muzzle to bullet impact - focused on players.", 
	version = PLUGIN_VERSION, 
	url = "http://ominousgaming.com"
}

public OnAllPluginsLoaded()
{
	g_bDynamicHooks = LibraryExists("dhook");
	if(g_bDynamicHooks && !g_bLoadedHooks)
	{
		#if defined _dhooks_included
		if(g_hConfig == INVALID_HANDLE)
		{
			decl String:sPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/css_supporter_tracers.txt");
			if(FileExists(sPath))
				g_hConfig = LoadGameConfigFile("css_supporter_tracers.gamedata");
		}		
		if(g_hConfig != INVALID_HANDLE)
		{
			g_bLoadedHooks = true;
			new iPrimary = GameConfGetOffset(g_hConfig, "PrimaryAttack");
			g_hPrimaryAttack = DHookCreate(iPrimary, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, PrimaryAttack);
			new iSecondary = GameConfGetOffset(g_hConfig, "SecondaryAttack");
			g_hSecondaryAttack = DHookCreate(iSecondary, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, SecondaryAttack);
		}
		else
			g_bDynamicHooks = g_bLoadedHooks = false;
		#endif
	}
}
 
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "dhook"))
	{
		g_bDynamicHooks = g_bLoadedHooks = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "dhook") && !g_bLoadedHooks)
	{
		#if defined _dhooks_included
		if(g_hConfig == INVALID_HANDLE)
		{
			decl String:sPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/css_supporter_tracers.txt");
			if(FileExists(sPath))
				g_hConfig = LoadGameConfigFile("css_supporter_tracers.gamedata");
		}
		if(g_hConfig != INVALID_HANDLE)
		{
			g_bLoadedHooks = g_bDynamicHooks = true;
			new iPrimary = GameConfGetOffset(g_hConfig, "PrimaryAttack");
			g_hPrimaryAttack = DHookCreate(iPrimary, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, PrimaryAttack);
			new iSecondary = GameConfGetOffset(g_hConfig, "SecondaryAttack");
			g_hSecondaryAttack = DHookCreate(iSecondary, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, SecondaryAttack);
		}
		else
			g_bDynamicHooks = g_bLoadedHooks = false;
		#endif
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("css_supporter_tracers.phrases");

	CreateConVar("css_tracers_version", PLUGIN_VERSION, "Supporter Tracers: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_tracers_enabled", "1", "Enables/Disables all features of this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hFlag = CreateConVar("css_tracers_access", "s", "If \"\", everyone can use Tracers, otherwise, only players with this flag or the \"Tracers_Access\" override can access.", FCVAR_NONE);
	HookConVarChange(g_hFlag, OnSettingsChange);
	g_hDefault = CreateConVar("css_tracers_default_status", "1", "The default tracer status that is set to new clients. (0 = Disabled, 1 = Enabled, 2 = Always Enabled)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hDefault, OnSettingsChange);
	g_hKnife = CreateConVar("css_tracers_knife", "3", "If enabled, clients with access can shoot tracers from their knife to their crosshair location. (0 = Disabled, 1 = Left Click, 2 = Right Click, 3 = Both)", FCVAR_NONE, true, 0.0, true, 3.0);
	HookConVarChange(g_hKnife, OnSettingsChange);
	g_hChatCommands = CreateConVar("css_tracers_commands", "!tracer, !tracers, /tracer, /tracers, !laser, !lasers, /laser, /lasers", "The chat triggers available to clients to access tracers features.", FCVAR_NONE);
	HookConVarChange(g_hChatCommands, OnSettingsChange);

	g_hDefaultColor = CreateConVar("css_tracers_default_color", "-1", "The default color index to be applied to new players or upon css_tracers_config_color being set to 0. (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultColor, OnSettingsChange);
	g_hDefaultLifeTime = CreateConVar("css_tracers_default_lifetime", "4", "The default lifetime index to be applied to new players or upon css_tracers_config_lifetime being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultLifeTime, OnSettingsChange);
	g_hDefaultWidth = CreateConVar("css_tracers_default_width", "19", "The default width index to be applied to new players or upon css_tracers_config_width being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultWidth, OnSettingsChange);
	g_hDefaultAlpha = CreateConVar("css_tracers_default_alpha", "11", "The default alpha index to be applied to new players or upon css_tracers_config_alpha being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultAlpha, OnSettingsChange);
	g_hDefaultMaterial = CreateConVar("css_tracers_default_material", "-1", "The default material index to be applied to new players or upon css_tracers_config_material being set to 0 (-1 = Random, # = Index)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultMaterial, OnSettingsChange);
	g_hDefaultVisible = CreateConVar("css_tracers_default_visible", "1", "The default visibility index applied to new players. (0 = Player Only, 1 = Team Only, 2 = All)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hDefaultVisible, OnSettingsChange);
	g_hConfigColor = CreateConVar("css_tracers_config_color", "1", "If enabled, clients will be able to change the color of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigColor, OnSettingsChange);
	g_hConfigLifeTime = CreateConVar("css_tracers_config_lifetime", "1", "If enabled, clients will be able to change the lifetime of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigLifeTime, OnSettingsChange);
	g_hConfigWidth = CreateConVar("css_tracers_config_width", "1", "If enabled, clients will be able to change the width of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigWidth, OnSettingsChange);
	g_hConfigAlpha = CreateConVar("css_tracers_config_alpha", "1", "If enabled, clients will be able to change the alpha value of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigAlpha, OnSettingsChange);
	g_hConfigMaterial = CreateConVar("css_tracers_config_material", "1", "If enabled, clients will be able to change the material of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigMaterial, OnSettingsChange);
	g_hConfigVisible = CreateConVar("css_tracers_config_visible", "1", "If enabled, clients will be able to change the visibility status of their tracer.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hConfigVisible, OnSettingsChange);
	g_hGrenadeTrails = CreateConVar("css_tracers_grenades", "0", "If enabled, grenades thrown by clients will have their trail attached.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hGrenadeTrails, OnSettingsChange);
	AutoExecConfig(true, "css_supporter_tracers");
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("bullet_impact", Event_OnBulletImpact);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);

	SetCookieMenuItem(Menu_Cookies, 0, "Tracer Settings");
	g_cEnabled = RegClientCookie("SupporterTracers_Enabled", "Player Tracers: The client's tracer status.", CookieAccess_Protected);
	g_cColor = RegClientCookie("SupporterTracers_Color", "Player Tracers: The client's selected tracer color.", CookieAccess_Protected);
	g_cWidth = RegClientCookie("SupporterTracers_Width", "Player Tracers: The client's selected width value.", CookieAccess_Protected);
	g_cAlpha = RegClientCookie("SupporterTracers_Alpha", "Player Tracers: The client's selected alpha value.", CookieAccess_Protected);
	g_cLifeTime = RegClientCookie("SupporterTracers_Life", "Player Tracers: The client's selected lifetime value.", CookieAccess_Protected);
	g_cMaterial = RegClientCookie("SupporterTracers_Material", "Player Tracers: The client's selected material.", CookieAccess_Protected);
	g_cVisible = RegClientCookie("SupporterTracers_Visible", "Player Tracers: The client's selected visible status", CookieAccess_Protected);

	RegAdminCmd("css_tracers_print", Command_Print, ADMFLAG_RCON, "Usage: css_tracers_print, prints indexes to be used with css_tracers_default_* cvars.");

	Define_Colors();
	Define_Configs();
	Define_Materials();
	Void_SetDefaults();
}

public OnEntityCreated(entity, const String:classname[])
{
	if(g_bEnabled)
	{
		if(entity > 0)
		{
			if(g_bGrenadeTrails && StrContains(classname, "_projectile") != -1)
				CreateTimer(0.1, Timer_OnEntityCreated, EntIndexToEntRef(entity));
#if defined _dhooks_included
			else if(g_bDynamicHooks && g_bLoadedHooks && StrEqual(classname, "weapon_knife"))
			{	
				if(g_iKnife & KNIFE_PRIMARY)
					DHookEntity(g_hPrimaryAttack, false, entity);

				if(g_iKnife & KNIFE_SECONDARY)
					DHookEntity(g_hSecondaryAttack, false, entity);
			}
#endif
		}
	}
}

public OnEntityDestroyed(entity)
{
	if(g_bEnabled)
	{
		if(entity > 0 && g_iProjTrail[entity])
		{
			if(IsValidEntity(g_iProjTrail[entity]))
				AcceptEntityInput(g_iProjTrail[entity], "Kill");

			g_iProjTrail[entity] = 0;
		}
	}
}

public Action:Timer_OnEntityCreated(Handle:timer, any:ref)
{
	if(g_bEnabled)
	{
		new entity = EntRefToEntIndex(ref);
		if(entity != INVALID_ENT_REFERENCE)
		{
			new client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
			if(client > 0 && IsClientInGame(client) && g_bValid[client])
			{
				decl String:sTemp[64];
				Format(sTemp, sizeof(sTemp), "ProjectileTracers_%d", entity);
				DispatchKeyValue(entity, "targetname", sTemp);
				new iEntity = CreateEntityByName("env_spritetrail");
				if(iEntity > 0 && IsValidEntity(iEntity))
				{
					g_iProjTrail[entity] = iEntity;
					
					DispatchKeyValue(iEntity, "parentname", sTemp);
					DispatchKeyValue(iEntity, "renderamt", "255");
					DispatchKeyValue(iEntity, "rendercolor", g_sColorSchemes[g_iTracerData[client][INDEX_COLOR]]);
					DispatchKeyValue(iEntity, "spritename", g_sMaterialPaths[g_iTracerData[client][INDEX_MATERIAL]]);
					DispatchKeyValue(iEntity, "lifetime", "1.5");
					DispatchKeyValue(iEntity, "startwidth", "5.0");
					DispatchKeyValue(iEntity, "endwidth", "1.0");
					DispatchKeyValue(iEntity, "rendermode", "0");
					DispatchSpawn(iEntity);

					decl Float:gfOrigin[3];
					SetEntPropFloat(iEntity, Prop_Send, "m_flTextureRes", 0.05);
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", gfOrigin);
					TeleportEntity(iEntity, gfOrigin, NULL_VECTOR, NULL_VECTOR);
					SetVariantString(sTemp);
					AcceptEntityInput(iEntity, "SetParent", iEntity, iEntity);
				}
			}
		}
	}
}

public OnMapStart()
{
	if(g_bEnabled)
	{
		Define_Colors();
		Define_Configs();
		Define_Materials();

		PrepMaterial();
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Format(g_sPrefixChat, 32, "%T", "Prefix_Chat", LANG_SERVER);
		Format(g_sPrefixSelect, 16, "%T", "Menu_Option_Selected", LANG_SERVER);
		Format(g_sPrefixEmpty, 16, "%T", "Menu_Option_Empty", LANG_SERVER);

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i);
					g_bFake[i] = IsFakeClient(i) ? true : false;
					SDKHook(i, SDKHook_TraceAttack, Hook_TraceAttack);

					if(!g_iAccessFlag || CheckCommandAccess(i, "Tracers_Access", g_iAccessFlag))
					{
						g_bValid[i] = true;
						if(!g_bFake[i])
						{
							if(!g_bLoaded[i] && AreClientCookiesCached(i))
								LoadClientData(i);
						}
						else
						{
							g_bLoaded[i] = true;
							g_iAppear[i] = g_iDefault;

							g_iTracerData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, g_iNumColors) : g_iDefaultColor;
							g_iTracerData[i][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, g_iNumWidths) : g_iDefaultWidth;
							g_iTracerData[i][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, g_iNumAlphas) : g_iDefaultAlpha;
							g_iTracerData[i][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, g_iNumLifes) : g_iDefaultLifeTime;
							g_iTracerData[i][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, g_iMaterials) : g_iDefaultMaterial;
							g_iTracerData[i][INDEX_VISIBLE] = g_iDefaultVisible;
							
							decl String:sBuffer[3][8];
							ExplodeString(g_sColorSchemes[g_iTracerData[i][INDEX_COLOR]], " ", sBuffer, 3, 8);
							for(new j = 0; j <= 2; j++)
								g_iColors[i][j] = StringToInt(sBuffer[j]);
							g_iColors[i][3] = g_iAlphas[g_iTracerData[i][INDEX_ALPHA]];
						}
					}
					else
						g_iAppear[i] = g_iDefault;
				}
			}
			#if defined _dhooks_included
			if(g_bDynamicHooks && g_bLoadedHooks)
			{
				for(new entity = MaxClients + 1; entity <= 2048; entity++)
				{
					decl String:_sClassname[64];
					if(IsValidEdict(entity) && IsValidEntity(entity))
					{
						GetEntityClassname(entity, _sClassname, sizeof(_sClassname));
						if(StrEqual(_sClassname, "weapon_knife"))
						{
							if(g_iKnife & KNIFE_PRIMARY)
								DHookEntity(g_hPrimaryAttack, false, entity);

							if(g_iKnife & KNIFE_SECONDARY)
								DHookEntity(g_hSecondaryAttack, false, entity);
						}
					}
				}
			}
			#endif
			
			g_bLateLoad = false;
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		g_bFake[client] = IsFakeClient(client) ? true : false;
		SDKHook(client, SDKHook_TraceAttack, Hook_TraceAttack);
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled && IsClientInGame(client))
	{
		if(!g_iAccessFlag || CheckCommandAccess(client, "Tracers_Access", g_iAccessFlag))
		{
			g_bValid[client] = true;
			if(!g_bFake[client])
			{
				if(!g_bLoaded[client] && AreClientCookiesCached(client))
					LoadClientData(client);
			}
			else
			{
				g_bLoaded[client] = true;
				g_iAppear[client] = g_iDefault;

				g_iTracerData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, g_iNumColors) : g_iDefaultColor;
				g_iTracerData[client][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, g_iNumWidths) : g_iDefaultWidth;
				g_iTracerData[client][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, g_iNumAlphas) : g_iDefaultAlpha;
				g_iTracerData[client][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, g_iNumLifes) : g_iDefaultLifeTime;
				g_iTracerData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, g_iMaterials) : g_iDefaultMaterial;
				g_iTracerData[client][INDEX_VISIBLE] = g_iDefaultVisible;
				
				decl String:sBuffer[3][8];
				ExplodeString(g_sColorSchemes[g_iTracerData[client][INDEX_COLOR]], " ", sBuffer, 3, 8);
				for(new i = 0; i <= 2; i++)
					g_iColors[client][i] = StringToInt(sBuffer[i]);
				g_iColors[client][3] = g_iAlphas[g_iTracerData[client][INDEX_ALPHA]];
			}
		}
		else
			g_iAppear[client] = g_iDefault;
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_bKnife[client] = false;
		g_bAlive[client] = false;
		g_bLoaded[client] = false;
		g_bValid[client] = false;
		g_iAppear[client] = false;
	}
}

public OnClientCookiesCached(client)
{
	if(!g_bLoaded[client] && !g_bFake[client])
	{
		LoadClientData(client);
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
		if(g_iAppear[client] && g_bValid[client])
		{
			decl Float:fPosition[3], Float:fImpact[3], Float:fDifference[3];

			GetClientEyePosition(client, fPosition);
			fImpact[0] = GetEventFloat(event, "x");
			fImpact[1] = GetEventFloat(event, "y");
			fImpact[2] = GetEventFloat(event, "z");

			new Float:fDistance = GetVectorDistance(fPosition, fImpact);
			new Float:fPercent = (0.4 / (fDistance / 100.0));

			fDifference[0] = fPosition[0] + ((fImpact[0] - fPosition[0]) * fPercent);
			fDifference[1] = fPosition[1] + ((fImpact[1] - fPosition[1]) * fPercent) - 0.08;
			fDifference[2] = fPosition[2] + ((fImpact[2] - fPosition[2]) * fPercent);
			
			switch(g_iTracerData[client][INDEX_VISIBLE])
			{
				case VISIBLE_ONE:
				{
					TE_SetupBeamPoints(fDifference, fImpact, g_iMaterialIndexes[g_iTracerData[client][INDEX_MATERIAL]], 0, 0, 0, g_fLifeTimes[g_iTracerData[client][INDEX_LIFE]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], 1, 0.0, g_iColors[client], 0);
					TE_SendToClient(client);
				}
				case VISIBLE_TEAM:
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && g_iAppear[i] && (g_iTeam[i] == g_iTeam[client] || g_iTeam[i] == 1))
						{
							TE_SetupBeamPoints(fDifference, fImpact, g_iMaterialIndexes[g_iTracerData[client][INDEX_MATERIAL]], 0, 0, 0, g_fLifeTimes[g_iTracerData[client][INDEX_LIFE]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], 1, 0.0, g_iColors[client], 0);
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
							TE_SetupBeamPoints(fDifference, fImpact, g_iMaterialIndexes[g_iTracerData[client][INDEX_MATERIAL]], 0, 0, 0, g_fLifeTimes[g_iTracerData[client][INDEX_LIFE]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], 1, 0.0, g_iColors[client], 0);
							TE_SendToClient(i);
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

#if defined _dhooks_included
public MRESReturn:PrimaryAttack(this, Handle:hReturn)
{
	new client = GetEntPropEnt(this, Prop_Send, "m_hOwnerEntity");
	if(client > 0 && g_iAppear[client] && g_bValid[client])
		CreateTimer(0.1, Timer_KnifeTracer, GetClientUserId(client));

	return MRES_Ignored;
}

public MRESReturn:SecondaryAttack(this, Handle:hReturn)
{
	new client = GetEntPropEnt(this, Prop_Send, "m_hOwnerEntity");
	if(client > 0 && g_iAppear[client] && g_bValid[client])
		CreateTimer(0.1, Timer_KnifeTracer, GetClientUserId(client));

	return MRES_Ignored;
}
#endif

public Action:Timer_KnifeTracer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		if(g_bKnife[client])
			g_bKnife[client] = false;
		else if(g_bAlive[client] && g_bValid[client])
		{
			decl Float:fOrigin[3], Float:fImpact[3], Float:fDifference[3];
			GetClientEyePosition(client, fDifference);
			GetClientEyeAngles(client, fOrigin);
			new Handle:hTemp = TR_TraceRayFilterEx(fDifference, fOrigin, MASK_SHOT_HULL, RayType_Infinite, Bool_TraceFilterPlayers);
			
			if(TR_DidHit(hTemp))
				TR_GetEndPosition(fImpact, hTemp);
			else
			{
				CloseHandle(hTemp);
				return Plugin_Continue;
			}
			CloseHandle(hTemp);
			
			switch(g_iTracerData[client][INDEX_VISIBLE])
			{
				case VISIBLE_ONE:
				{
					TE_SetupBeamPoints(fDifference, fImpact, g_iMaterialIndexes[g_iTracerData[client][INDEX_MATERIAL]], 0, 0, 0, g_fLifeTimes[g_iTracerData[client][INDEX_LIFE]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], 1, 0.0, g_iColors[client], 0);
					TE_SendToClient(client);
				}
				case VISIBLE_TEAM:
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && g_iAppear[i] && (g_iTeam[i] == g_iTeam[client] || g_iTeam[i] == 1))
						{
							TE_SetupBeamPoints(fDifference, fImpact, g_iMaterialIndexes[g_iTracerData[client][INDEX_MATERIAL]], 0, 0, 0, g_fLifeTimes[g_iTracerData[client][INDEX_LIFE]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], 1, 0.0, g_iColors[client], 0);
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
							TE_SetupBeamPoints(fDifference, fImpact, g_iMaterialIndexes[g_iTracerData[client][INDEX_MATERIAL]], 0, 0, 0, g_fLifeTimes[g_iTracerData[client][INDEX_LIFE]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], g_fWidths[g_iTracerData[client][INDEX_WIDTH]], 1, 0.0, g_iColors[client], 0);
							TE_SendToClient(i);
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:Hook_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(victim && victim <= MaxClients && attacker && attacker <= MaxClients)
		g_bKnife[attacker] = true;
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client) || !g_bValid[client])
			return Plugin_Continue;

		decl String:_sText[192];
		GetCmdArgString(_sText, sizeof(_sText));
		StripQuotes(_sText);

		for(new i = 0; i < g_iNumCommands; i++)
		{
			if(StrEqual(_sText, g_sChatCommands[i], false))
			{
				Menu_Tracers(client);
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

public Action:Timer_Print(Handle:timer, Handle:_hPack)
{
	ResetPack(_hPack);
	new temp = ReadPackCell(_hPack);
	new client = temp > 0 ? GetClientOfUserId(temp) : temp;

	new index = ReadPackCell(_hPack);
	switch(index)
	{
		case 1:
			for(new i = 0; i <= g_iNumColors; i++)
				ReplyToCommand(client, "Tracers - Colors: Index (%d), Name (%s), Colors (%s)", i, g_sColorNames[i], g_sColorSchemes[i]);
		case 2:
			for(new i = 0; i <= g_iNumWidths; i++)
				ReplyToCommand(client, "Tracers - Widths: Index (%d), Value: (%f)", i, g_fWidths[i]);
		case 3:
			for(new i = 0; i <= g_iNumAlphas; i++)
				ReplyToCommand(client, "Tracers - Alphas: Index (%d), Value: (%d)", i, g_iAlphas[i]);
		case 4:
			for(new i = 0; i <= g_iNumLifes; i++)
				ReplyToCommand(client, "Tracers - Lifetimes: Index (%d), Value: (%f)", i, g_fLifeTimes[i]);
		case 5:
			for(new i = 0; i <= g_iMaterials; i++)
				ReplyToCommand(client, "Tracers - Materials: Index (%d), Name: (%s), Path: (%s)", i, g_sMaterialNames[i], g_sMaterialPaths[i]);
	}
	ReplyToCommand(client, "--------------------------");
	CloseHandle(_hPack);
}

Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_iDefault = GetConVarInt(g_hDefault);
	g_iKnife = GetConVarInt(g_hKnife);
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
	g_bGrenadeTrails = GetConVarInt(g_hGrenadeTrails) ? true : false;

	decl String:sTemp[192];
	GetConVarString(g_hChatCommands, sTemp, sizeof(sTemp));
	g_iNumCommands = ExplodeString(sTemp, ", ", g_sChatCommands, 16, 32);
	GetConVarString(g_hFlag, sTemp, sizeof(sTemp));
	g_iAccessFlag = ReadFlagString(sTemp);
	
	if(g_iDefaultColor < 0 || g_iDefaultColor > g_iNumColors)
		g_iDefaultColor = GetRandomInt(0, g_iNumColors);
	if(g_iDefaultLifeTime < 0 || g_iDefaultLifeTime > g_iNumLifes)
		g_iDefaultLifeTime = GetRandomInt(0, g_iNumLifes);
	if(g_iDefaultWidth < 0 || g_iDefaultWidth > g_iNumWidths)
		g_iDefaultWidth = GetRandomInt(0, g_iNumWidths);
	if(g_iDefaultAlpha < 0 || g_iDefaultAlpha > g_iNumAlphas)
		g_iDefaultAlpha = GetRandomInt(0, g_iNumAlphas);
	if(g_iDefaultMaterial < 0 || g_iDefaultMaterial > g_iMaterials)
		g_iDefaultMaterial = GetRandomInt(0, g_iMaterials);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = bool:StringToInt(newvalue);
	else if(cvar == g_hFlag)
		g_iAccessFlag = ReadFlagString(newvalue);
	else if(cvar == g_hDefault)
		g_iDefault = StringToInt(newvalue);
	else if(cvar == g_hKnife)
		g_iKnife = StringToInt(newvalue);
	else if(cvar == g_hChatCommands)
		g_iNumCommands = ExplodeString(newvalue, ", ", g_sChatCommands, 16, 32);
	else if(cvar == g_hDefaultColor)
	{
		g_iDefaultColor = StringToInt(newvalue);
		if(g_iDefaultColor < 0 || g_iDefaultColor > g_iNumColors)
			g_iDefaultColor = GetRandomInt(0, g_iNumColors);
	}
	else if(cvar == g_hDefaultLifeTime)
	{
		g_iDefaultLifeTime = StringToInt(newvalue);
		if(g_iDefaultLifeTime < 0 || g_iDefaultLifeTime > g_iNumLifes)
			g_iDefaultLifeTime = GetRandomInt(0, g_iNumLifes);
	}
	else if(cvar == g_hDefaultWidth)
	{
		g_iDefaultWidth = StringToInt(newvalue);
		if(g_iDefaultWidth < 0 || g_iDefaultWidth > g_iNumWidths)
			g_iDefaultWidth = GetRandomInt(0, g_iNumWidths);
	}
	else if(cvar == g_hDefaultAlpha)
	{
		g_iDefaultAlpha = StringToInt(newvalue);
		if(g_iDefaultAlpha < 0 || g_iDefaultAlpha > g_iNumAlphas)
			g_iDefaultAlpha = GetRandomInt(0, g_iNumAlphas);
	}
	else if(cvar == g_hDefaultMaterial)
	{
		g_iDefaultMaterial = StringToInt(newvalue);
		if(g_iDefaultMaterial < 0 || g_iDefaultMaterial > g_iMaterials)
			g_iDefaultMaterial = GetRandomInt(0, g_iMaterials);
	}
	else if(cvar == g_hDefaultVisible)
		g_iDefaultVisible = StringToInt(newvalue);
	else if(cvar == g_hConfigColor)
		g_bConfigColor = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigLifeTime)
		g_bConfigLifeTime = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigWidth)
		g_bConfigWidth = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigAlpha)
		g_bConfigAlpha = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigMaterial)
		g_bConfigMaterial = bool:StringToInt(newvalue);
	else if(cvar == g_hConfigVisible)
		g_bConfigVisible = bool:StringToInt(newvalue);
	else if(cvar == g_hGrenadeTrails)
		g_bGrenadeTrails = bool:StringToInt(newvalue);
}

Define_Colors()
{
	decl String:sPath[PLATFORM_MAX_PATH], String:sBuffer[64];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tracers/css_tracers_colors.ini");
	
	new iCurrent = GetFileTime(sPath, FileTime_LastChange);
	if(iCurrent < g_iLoadColors)
		return;
	else
		g_iLoadColors = iCurrent;

	g_iNumColors = 0;
	new Handle:_hKV = CreateKeyValues("SupporterTracers_Colors");
	if(FileToKeyValues(_hKV, sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, g_sColorNames[g_iNumColors], sizeof(g_sColorNames[]));
			KvGetString(_hKV, "Color", g_sColorSchemes[g_iNumColors], sizeof(g_sColorSchemes[]));
			KvGetString(_hKV, "Flag", sBuffer, sizeof(sBuffer));
			g_iColorFlag[g_iNumColors] = ReadFlagString(sBuffer);
			g_iNumColors++;
		}
		while (KvGotoNextKey(_hKV));
	}
	else
		SetFailState("FileToKeyValues(\"configs/tracers/css_tracers_colors.ini\") doesn't appear to exist or is invalid.");
	
	if(g_iNumColors)
		g_iNumColors--;
	
	CloseHandle(_hKV);
}

Define_Materials()
{
	decl String:sPath[PLATFORM_MAX_PATH], String:sBuffer[64];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tracers/css_tracers_materials.ini");
	
	new iCurrent = GetFileTime(sPath, FileTime_LastChange);
	if(iCurrent < g_iLoadMaterials)
		return;
	else
		g_iLoadMaterials = iCurrent;
	
	g_iMaterials = 0;
	new Handle:_hKV = CreateKeyValues("SupporterTracers_Materials");
	if(FileToKeyValues(_hKV, sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, g_sMaterialNames[g_iMaterials], sizeof(g_sMaterialNames[]));
			KvGetString(_hKV, "Path", g_sMaterialPaths[g_iMaterials], sizeof(g_sMaterialPaths[]));
			KvGetString(_hKV, "Flag", sBuffer, sizeof(sBuffer));
			g_iMaterialFlag[g_iMaterials] = ReadFlagString(sBuffer);
			g_iMaterials++;
		}
		while (KvGotoNextKey(_hKV));
	}
	else
		SetFailState("FileToKeyValues(\"configs/tracers/css_tracers_materials.ini\") doesn't appear to exist or is invalid.");

	if(g_iMaterials)
		g_iMaterials--;

	CloseHandle(_hKV);
}

Define_Configs()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tracers/css_tracers_configs.ini");
	new iCurrent = GetFileTime(sPath, FileTime_LastChange);
	if(iCurrent < g_iLoadConfigs)
		return;
	else
		g_iLoadConfigs = iCurrent;

	g_iNumWidths = g_iNumAlphas = g_iNumLifes = 0;
	new Handle:_hKV = CreateKeyValues("SupporterTracers_Configs");
	if(FileToKeyValues(_hKV, sPath))
	{
		decl String:sTemp[8], String:sBuffer[64];
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, sBuffer, sizeof(sBuffer));
			if(StrEqual(sBuffer, "Width_Values", false))
			{
				KvGetString(_hKV, "accurate_count", sTemp, sizeof(sTemp));
				new Float:_fAccurateCount = StringToFloat(sTemp);
				if(_fAccurateCount)
				{
					KvGetString(_hKV, "accurate_factor", sTemp, sizeof(sTemp));
					new Float:_fAccurateFactor = StringToFloat(sTemp);

					for(new Float:i = 1.0; i <= _fAccurateCount; i++)
						g_fWidths[g_iNumWidths++] = (_fAccurateFactor * i);
				}
				
				KvGetString(_hKV, "regular_count", sTemp, sizeof(sTemp));
				new Float:_fRegularCount = StringToFloat(sTemp);
				if(_fRegularCount)
				{
					KvGetString(_hKV, "regular_factor", sTemp, sizeof(sTemp));
					new Float:_fRegularFactor = StringToFloat(sTemp);
					
					for(new Float:i = 1.0; i <= _fRegularCount; i++)
						g_fWidths[g_iNumWidths++] = (_fRegularFactor * i);
				}
			}
			else if(StrEqual(sBuffer, "Alpha_Values", false))
			{
				KvGetString(_hKV, "accurate_count", sTemp, sizeof(sTemp));
				new _iAccurateCount = StringToInt(sTemp);
				if(_iAccurateCount)
				{
					KvGetString(_hKV, "accurate_factor", sTemp, sizeof(sTemp));
					new _iAccurateFactor = StringToInt(sTemp);
					
					for(new i = 1; i <= _iAccurateCount; i++)
						g_iAlphas[g_iNumAlphas++] = (_iAccurateFactor * i);
				}
				
				KvGetString(_hKV, "regular_count", sTemp, sizeof(sTemp));
				new _iRegularCount = StringToInt(sTemp);
				if(_iRegularCount)
				{
					KvGetString(_hKV, "regular_factor", sTemp, sizeof(sTemp));
					new _iRegularFactor = StringToInt(sTemp);
	
					for(new i = 1; i <= _iRegularCount; i++)
						g_iAlphas[g_iNumAlphas++] = (_iRegularFactor * i);
				}
			}
			else if(StrEqual(sBuffer, "Life_Values", false))
			{
				KvGetString(_hKV, "accurate_count", sTemp, sizeof(sTemp));
				new Float:_fAccurateCount = StringToFloat(sTemp);
				if(_fAccurateCount)
				{
					KvGetString(_hKV, "accurate_factor", sTemp, sizeof(sTemp));
					new Float:_fAccurateFactor = StringToFloat(sTemp);
					
					for(new Float:i = 1.0; i <= _fAccurateCount; i++)
						g_fLifeTimes[g_iNumLifes++] = (_fAccurateFactor * i);
				}
				
				KvGetString(_hKV, "regular_count", sTemp, sizeof(sTemp));
				new Float:_fRegularCount = StringToFloat(sTemp);
				if(_fRegularCount)
				{
					KvGetString(_hKV, "regular_factor", sTemp, sizeof(sTemp));
					new Float:_fRegularFactor = StringToFloat(sTemp);
					
					for(new Float:i = 1.0; i <= _fRegularCount; i++)
						g_fLifeTimes[g_iNumLifes++] = (_fRegularFactor * i);
				}
			}
		}
		while (KvGotoNextKey(_hKV));
	}
	else
		SetFailState("FileToKeyValues(\"configs/tracers/css_tracers_configs.ini\") doesn't appear to exist or is invalid.");

	if(g_iNumWidths)
		g_iNumWidths--;
	if(g_iNumAlphas)
		g_iNumAlphas--;
	if(g_iNumLifes)
		g_iNumLifes--;

	CloseHandle(_hKV);
}

PrepMaterial()
{
	decl String:sBuffer[256];
	for(new i = 0; i < g_iMaterials; i++)
	{
		strcopy(sBuffer, sizeof(sBuffer), g_sMaterialPaths[i]);
		AddFileToDownloadsTable(sBuffer);
		
		g_iMaterialIndexes[i] = PrecacheModel(sBuffer, true);
		ReplaceString(sBuffer, sizeof(sBuffer), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(sBuffer);
	}
}

LoadClientData(client)
{
	decl String:_sCookie[4] = "";
	GetClientCookie(client, g_cEnabled, _sCookie, sizeof(_sCookie));

	if(StrEqual(_sCookie, "", false))
	{
		_sCookie = g_iDefault ? "1" : "0";
		g_iAppear[client] = StringToInt(_sCookie) ? true : false;
		SetClientCookie(client, g_cEnabled, _sCookie);

		g_iTracerData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, g_iNumColors) : g_iDefaultColor;
		IntToString(g_iTracerData[client][INDEX_COLOR], _sCookie, 4);
		SetClientCookie(client, g_cColor, _sCookie);

		g_iTracerData[client][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, g_iNumWidths) : g_iDefaultWidth;
		IntToString(g_iTracerData[client][INDEX_WIDTH], _sCookie, 4);
		SetClientCookie(client, g_cWidth, _sCookie);

		g_iTracerData[client][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, g_iNumAlphas) : g_iDefaultAlpha;
		IntToString(g_iTracerData[client][INDEX_ALPHA], _sCookie, 4);
		SetClientCookie(client, g_cAlpha, _sCookie);

		g_iTracerData[client][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, g_iNumLifes) : g_iDefaultLifeTime;
		IntToString(g_iTracerData[client][INDEX_LIFE], _sCookie, 4);
		SetClientCookie(client, g_cLifeTime, _sCookie);

		g_iTracerData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, g_iMaterials) : g_iDefaultMaterial;
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
			if(g_iTracerData[client][INDEX_COLOR] > g_iNumColors || g_iTracerData[client][INDEX_COLOR] < 0)
			{
				g_iTracerData[client][INDEX_COLOR] = g_iDefaultColor;
				IntToString(g_iTracerData[client][INDEX_COLOR], _sCookie, 4);
				SetClientCookie(client, g_cColor, _sCookie);
			}
		}
		else
			g_iTracerData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, g_iNumColors) : g_iDefaultColor;

		if(g_bConfigWidth)
		{
			GetClientCookie(client, g_cWidth, _sCookie, 4);
			g_iTracerData[client][INDEX_WIDTH] = StringToInt(_sCookie);
			if(g_iTracerData[client][INDEX_WIDTH] > g_iNumWidths || g_iTracerData[client][INDEX_WIDTH] < 0)
			{
				g_iTracerData[client][INDEX_WIDTH] = g_iDefaultWidth;
				IntToString(g_iTracerData[client][INDEX_WIDTH], _sCookie, 4);
				SetClientCookie(client, g_cWidth, _sCookie);
			}
		}
		else
			g_iTracerData[client][INDEX_WIDTH] = g_iDefaultWidth == -1 ? GetRandomInt(0, g_iNumWidths) : g_iDefaultWidth;

		if(g_bConfigAlpha)
		{
			GetClientCookie(client, g_cAlpha, _sCookie, 4);
			g_iTracerData[client][INDEX_ALPHA] = StringToInt(_sCookie);
			if(g_iTracerData[client][INDEX_ALPHA] > g_iNumAlphas || g_iTracerData[client][INDEX_ALPHA] < 0)
			{
				g_iTracerData[client][INDEX_ALPHA] = g_iDefaultAlpha;
				IntToString(g_iTracerData[client][INDEX_ALPHA], _sCookie, 4);
				SetClientCookie(client, g_cAlpha, _sCookie);
			}
		}
		else
			g_iTracerData[client][INDEX_ALPHA] = g_iDefaultAlpha == -1 ? GetRandomInt(0, g_iNumAlphas) : g_iDefaultAlpha;

		if(g_bConfigLifeTime)
		{
			GetClientCookie(client, g_cLifeTime, _sCookie, 4);
			g_iTracerData[client][INDEX_LIFE] = StringToInt(_sCookie);
			if(g_iTracerData[client][INDEX_LIFE] > g_iNumLifes || g_iTracerData[client][INDEX_LIFE] < 0)
			{
				g_iTracerData[client][INDEX_LIFE] = g_iDefaultLifeTime;
				IntToString(g_iTracerData[client][INDEX_LIFE], _sCookie, 4);
				SetClientCookie(client, g_cLifeTime, _sCookie);
			}
		}
		else
			g_iTracerData[client][INDEX_LIFE] = g_iDefaultLifeTime == -1 ? GetRandomInt(0, g_iNumLifes) : g_iDefaultLifeTime;

		if(g_bConfigMaterial)
		{
			GetClientCookie(client, g_cMaterial, _sCookie, 4);
			g_iTracerData[client][INDEX_MATERIAL] = StringToInt(_sCookie);
			if(g_iTracerData[client][INDEX_MATERIAL] > g_iMaterials || g_iTracerData[client][INDEX_MATERIAL] < 0)
			{
				g_iTracerData[client][INDEX_MATERIAL] = g_iDefaultMaterial;
				IntToString(g_iTracerData[client][INDEX_MATERIAL], _sCookie, 4);
				SetClientCookie(client, g_cMaterial, _sCookie);
			}
		}
		else
			g_iTracerData[client][INDEX_MATERIAL] = g_iDefaultMaterial == -1 ? GetRandomInt(0, g_iMaterials) : g_iDefaultMaterial;

		if(g_bConfigVisible)
		{
			GetClientCookie(client, g_cVisible, _sCookie, 4);
			g_iTracerData[client][INDEX_VISIBLE] = StringToInt(_sCookie);
		}
		else
			g_iTracerData[client][INDEX_VISIBLE] = g_iDefaultVisible;
	}

	decl String:sBuffer[3][8];
	ExplodeString(g_sColorSchemes[g_iTracerData[client][INDEX_COLOR]], " ", sBuffer, 3, 8);
	for(new i = 0; i <= 2; i++)
		g_iColors[client][i] = StringToInt(sBuffer[i]);
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
			if(g_bEnabled)
				Menu_Tracers(client);
		}
	}
}

Menu_Tracers(client)
{
	decl String:sBuffer[128];
	new _iOptions, Handle:_hMenu = CreateMenu(MenuHandler_MenuTracers);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Main", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);

	if(g_iDefault != TRACERS_FORCED)
	{
		_iOptions++;
		if(g_iAppear[client])
			Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Disable", client);
		else
			Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Enable", client);
		AddMenuItem(_hMenu, "0", sBuffer);
	}
	
	new _iState = g_bValid[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	if(g_iNumColors > 0 && g_bConfigColor)
	{
		_iOptions++;
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Color", client);
		AddMenuItem(_hMenu, "1", sBuffer, _iState);
	}

	if(g_iMaterials > 0 && g_bConfigMaterial)
	{
		_iOptions++;
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Material", client);
		AddMenuItem(_hMenu, "2", sBuffer, _iState);
	}

	if(g_iNumWidths > 0 && g_bConfigWidth)
	{
		_iOptions++;
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Width", client);
		AddMenuItem(_hMenu, "3", sBuffer, _iState);
	}
	
	if(g_iNumAlphas > 0 && g_bConfigAlpha)
	{
		_iOptions++;
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Alpha", client);
		AddMenuItem(_hMenu, "4", sBuffer, _iState);
	}
	
	if(g_iNumLifes > 0 && g_bConfigLifeTime)
	{
		_iOptions++;
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Life", client);
		AddMenuItem(_hMenu, "5", sBuffer, _iState);
	}

	if(g_bConfigVisible)
	{
		_iOptions++;
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Visibility", client);
		AddMenuItem(_hMenu, "6", sBuffer, _iState);
	}
	
	if(_iOptions)
		DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
		
	return _iOptions;
}

public MenuHandler_MenuTracers(Handle:menu, MenuAction:action, param1, param2)
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
			decl String:sTemp[8];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));

			switch(StringToInt(sTemp))
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
	decl String:sTemp[8], String:sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuColors);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Color", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i <= g_iNumColors; i++)
	{
		if(!g_iColorFlag[i] || CheckCommandAccess(client, "Tracers_Access_Colors", g_iColorFlag[i]))
		{
			Format(sBuffer, sizeof(sBuffer), "%s%s", (g_iTracerData[client][INDEX_COLOR] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sColorNames[i]);
			IntToString(i, sTemp, sizeof(sTemp));
			AddMenuItem(_hMenu, sTemp, sBuffer);
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
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:sTemp[8], String:sBuffer[3][8];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));
			g_iTracerData[param1][INDEX_COLOR] = StringToInt(sTemp);
			
			ExplodeString(g_sColorSchemes[g_iTracerData[param1][INDEX_COLOR]], " ", sBuffer, 3, 8);
			for(new i = 0; i <= 2; i++)
				g_iColors[param1][i] = StringToInt(sBuffer[i]);
			
			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Color", g_sColorNames[g_iTracerData[param1][INDEX_COLOR]]);
			SetClientCookie(param1, g_cColor, sTemp);
			Menu_Colors(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_Widths(client, index = 0)
{
	decl String:sTemp[8], String:sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuWidths);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Width", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i <= g_iNumWidths; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "%s%.2f", (g_iTracerData[client][INDEX_WIDTH] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_fWidths[i]);
		IntToString(i, sTemp, sizeof(sTemp));
		AddMenuItem(_hMenu, sTemp, sBuffer);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuWidths(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:sTemp[8];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));
			g_iTracerData[param1][INDEX_WIDTH] = StringToInt(sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Width", g_fWidths[g_iTracerData[param1][INDEX_WIDTH]]);
			SetClientCookie(param1, g_cWidth, sTemp);
			Menu_Widths(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_Alphas(client, index = 0)
{
	decl String:sTemp[8], String:sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuAlphas);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Alpha", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i <= g_iNumAlphas; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "%s%d", (g_iTracerData[client][INDEX_ALPHA] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_iAlphas[i]);
		IntToString(i, sTemp, sizeof(sTemp));
		AddMenuItem(_hMenu, sTemp, sBuffer);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuAlphas(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:sTemp[8];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));
			g_iTracerData[param1][INDEX_ALPHA] = StringToInt(sTemp);
			g_iColors[param1][3] = g_iAlphas[g_iTracerData[param1][INDEX_ALPHA]];
			
			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Alpha", g_iAlphas[g_iTracerData[param1][INDEX_ALPHA]]);
			SetClientCookie(param1, g_cAlpha, sTemp);
			Menu_Alphas(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_LifeTimes(client, index = 0)
{
	decl String:sTemp[8], String:sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuLifeTimes);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Life", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i <= g_iNumLifes; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "%s%.2f", (g_iTracerData[client][INDEX_LIFE] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_fLifeTimes[i]);
		IntToString(i, sTemp, sizeof(sTemp));
		AddMenuItem(_hMenu, sTemp, sBuffer);
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
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:sTemp[8];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));
			g_iTracerData[param1][INDEX_LIFE] = StringToInt(sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Life", g_fLifeTimes[g_iTracerData[param1][INDEX_LIFE]]);
			SetClientCookie(param1, g_cLifeTime, sTemp);
			Menu_LifeTimes(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_Materials(client, index = 0)
{
	decl String:sTemp[8], String:sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuMaterials);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Material", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i <= g_iMaterials; i++)
	{
		if(!g_iMaterialFlag[i] || CheckCommandAccess(client, "Tracers_Access_Materials", g_iMaterialFlag[i]))
		{
			Format(sBuffer, sizeof(sBuffer), "%s%s", (g_iTracerData[client][INDEX_MATERIAL] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sMaterialNames[i]);
			IntToString(i, sTemp, sizeof(sTemp));
			AddMenuItem(_hMenu, sTemp, sBuffer);
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
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:sTemp[8];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));
			g_iTracerData[param1][INDEX_MATERIAL] = StringToInt(sTemp);

			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Material", g_sMaterialNames[g_iTracerData[param1][INDEX_MATERIAL]]);
			SetClientCookie(param1, g_cMaterial, sTemp);
			Menu_Materials(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_Visible(client)
{
	decl String:sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuVisible);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Visible", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Visibility_Single", client, (g_iTracerData[client][INDEX_VISIBLE] == VISIBLE_ONE) ? g_sPrefixSelect : g_sPrefixEmpty);
	AddMenuItem(_hMenu, "0", sBuffer);

	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Visibility_Team", client, (g_iTracerData[client][INDEX_VISIBLE] == VISIBLE_TEAM) ? g_sPrefixSelect : g_sPrefixEmpty);
	AddMenuItem(_hMenu, "1", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Visibility_All", client, (g_iTracerData[client][INDEX_VISIBLE] == VISIBLE_ALL) ? g_sPrefixSelect : g_sPrefixEmpty);
	AddMenuItem(_hMenu, "2", sBuffer);
	
	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuVisible(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Tracers(param1);
		case MenuAction_Select:
		{
			decl String:sTemp[8];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));
			new _iTemp = StringToInt(sTemp);

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
				
				SetClientCookie(param1, g_cVisible, sTemp);
			}

			Menu_Visible(param1);
		}
	}

	return;
}

public bool:Bool_TraceFilterPlayers(entity, contentsMask, any:client) 
{
	return !entity || entity > MaxClients;
}	