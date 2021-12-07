/*
	Revision 1.2.5
	--------------
	The updates between 1.2.3 and 1.2.5 were undocumented for unknown reasons. Here's what I can manage changed:
	The configuration files are now updated every OnMapStart if they've been recently modified.
	All aspects of the plugin containing sm_ have been replaced with css_, as it's a CS:S plugin.
	Removed the optional requirement of ClientPrefs as the crash issue has been resolved.
	Added the optional requirement of Dynamic Hooks, allowing clients to shoot tracers from their knives.
	Added the ability to attach trails to grenades.
	A cvar has been added to control what commands access the tracers feature.
	A new auth system has been added using the override Tracers_Access and a flag you provide.
*/

// Hardcoded limit to the number of tracers available in the configuration file (saves memory, increase to allow more).
#define MAX_TRACERS 128

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <clientprefs>
#include <cstrike>
#undef REQUIRE_EXTENSIONS
#tryinclude <dhooks>

#define PLUGIN_VERSION "1.2.5"

#define TRACERS_DISABLED 0
#define TRACERS_ENABLED 1
#define TRACERS_FORCED 2

#define VISIBLE_EVERYONE 0
#define VISIBLE_SPECTATE 1
#define VISIBLE_FRIENDLY 2
#define VISIBLE_OPPOSING 3
#define VISIBLE_CLIENT 4

#define IMPACT_BULLET 0
#define IMPACT_DAMAGE 1

#define KNIFE_PRIMARY 1
#define KNIFE_SECONDARY 2

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hAdvert = INVALID_HANDLE;
new Handle:g_hGlobalVisibility = INVALID_HANDLE;
new Handle:g_hFlag = INVALID_HANDLE;
new Handle:g_hChatCommands = INVALID_HANDLE;
new Handle:g_hKnife = INVALID_HANDLE;
new Handle:g_hClientEnabled = INVALID_HANDLE;
new Handle:g_hClientVisibility = INVALID_HANDLE;
new Handle:g_hClientTracer = INVALID_HANDLE;
new Handle:g_hClientPersonal = INVALID_HANDLE;
new Handle:g_hGrenadeTrails = INVALID_HANDLE;
new Handle:g_hForceRandom = INVALID_HANDLE;
new Handle:g_hForceTeam = INVALID_HANDLE;
new Handle:g_hAllowPersonal = INVALID_HANDLE;
new Handle:g_hGlobalWidth = INVALID_HANDLE;
new Handle:g_hGlobalLife = INVALID_HANDLE;
new Handle:g_hGlobalImpact = INVALID_HANDLE;
new Handle:g_cStatus = INVALID_HANDLE;
new Handle:g_cVisibility = INVALID_HANDLE;
new Handle:g_cTracer = INVALID_HANDLE;
new Handle:g_cPersonal = INVALID_HANDLE;
new Handle:g_hConfig = INVALID_HANDLE;
new Handle:g_hPosition = INVALID_HANDLE;
#if defined _dhooks_included
new Handle:g_hPrimaryAttack = INVALID_HANDLE;
new Handle:g_hSecondaryAttack = INVALID_HANDLE;
#endif

new g_iRedColors[4], g_iBlueColors[4], String:g_sRedTexture[256], String:g_sBlueTexture[256], g_iAccessFlag, g_iRedIndex, g_iBlueIndex;
new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bValidSDK, bool:g_bAllowPersonal, bool:g_bClientPersonal, bool:g_bDynamicHooks, bool:g_bGrenadeTrails;
new g_iNumCommands, g_iKnife, g_iVisibility, g_iNumTracers, g_iClientEnabled, g_iClientVisibility, g_iClientTracer, g_iGlobalImpact, g_iForceRandom, g_iForceTeam;
new Float:g_fAdvert, Float:g_fDefaultLife, Float:g_fDefaultWidth;
new String:g_sPrefixChat[32], String:g_sPrefixSelect[16], String:g_sPrefixEmpty[16], String:g_sChatCommands[16][32];
new bool:g_bLoadedHooks;
new g_iLoadTracers;

new bool:g_bTracerEnabled[MAX_TRACERS];
new String:g_sTracerName[MAX_TRACERS][64];
new String:g_sTracerTexture[MAX_TRACERS][256];
new Float:g_fTracerLife[MAX_TRACERS];
new Float:g_fTracerWidth[MAX_TRACERS];
new g_iTracerIndex[MAX_TRACERS];
new String:g_sTracerColors[MAX_TRACERS][16];
new g_iTracerColor[MAX_TRACERS][4];
new g_iTracerFlag[MAX_TRACERS];
new bool:g_bTracerTeam[MAX_TRACERS];

new g_iProjTrail[2049];

new g_iTeam[MAXPLAYERS + 1];
new g_iPlayerEnabled[MAXPLAYERS + 1];
new g_iPlayerVisibility[MAXPLAYERS + 1];
new g_iPlayerTracer[MAXPLAYERS + 1];
new bool:g_bPlayerPersonal[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new bool:g_bAccess[MAXPLAYERS + 1];
new bool:g_bKnife[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "CSS Tracer Effects",
	author = "Twisted|Panda",
	description = "Provides both simple and advanced functionality for displaying tracers focused on server-wide usage.", 	
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
}

public OnAllPluginsLoaded()
{
	g_bDynamicHooks = LibraryExists("dhook");
	if(g_bDynamicHooks && !g_bLoadedHooks)
	{
		#if defined _dhooks_included
		g_bLoadedHooks = true;
		new _iPrim = GameConfGetOffset(g_hConfig, "PrimaryAttack");
		g_hPrimaryAttack = DHookCreate(_iPrim, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, PrimaryAttack);
		new _iSec = GameConfGetOffset(g_hConfig, "SecondaryAttack");
		g_hSecondaryAttack = DHookCreate(_iSec, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, SecondaryAttack);
		#endif
	}
}
 
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "dhook"))
	{
		g_bDynamicHooks = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "dhook"))
	{
		g_bDynamicHooks = true;
		if(!g_bLoadedHooks)
		{
			#if defined _dhooks_included
			g_bLoadedHooks = true;
			new _iPrim = GameConfGetOffset(g_hConfig, "PrimaryAttack");
			g_hPrimaryAttack = DHookCreate(_iPrim, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, PrimaryAttack);
			new _iSec = GameConfGetOffset(g_hConfig, "SecondaryAttack");
			g_hSecondaryAttack = DHookCreate(_iSec, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, SecondaryAttack);
			#endif
		}
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
	LoadTranslations("css_tracer_effects.phrases");
	
	CreateConVar("css_tracer_effects_version", PLUGIN_VERSION, "Tracer Effects: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_tracer_effects", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hAdvert = CreateConVar("css_tracer_effects_advert", "-1.0", "The number of seconds after a client joins an initial team for an informational advert to be sent to the client. (-1.0 = No Advert)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hAdvert, OnSettingsChange);
	g_hAllowPersonal = CreateConVar("css_tracer_effects_personal_tracer", "1", "If enabled, players may hide their personal tracer from view (however, others will still see it)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hAllowPersonal, OnSettingsChange);
	g_hFlag = CreateConVar("css_tracer_effects_flag", "s", "If \"\", everyone can access all features of Tracer Effects, otherwise, only players with this flag or \"Tracers_Access\" override will have access to personal tracer modifications.", FCVAR_NONE);
	HookConVarChange(g_hFlag, OnSettingsChange);
	g_hKnife = CreateConVar("css_tracer_effects_knife", "3", "If enabled, clients with access can shoot tracers from their knife to their crosshair location. (0 = Disabled, 1 = Left Click, 2 = Right Click, 3 = Both)", FCVAR_NONE, true, 0.0, true, 3.0);
	HookConVarChange(g_hKnife, OnSettingsChange);
	g_hChatCommands = CreateConVar("css_tracer_effects_commands", "!tracer, !tracers, /tracer, /tracers, !laser, !lasers, /laser, /lasers", "The chat triggers available to clients to access tracers features.", FCVAR_NONE);
	HookConVarChange(g_hChatCommands, OnSettingsChange);
	
	g_hClientEnabled = CreateConVar("css_tracer_effects_client_enabled", "2", "The default tracer status for new clients. (0 = Disabled, 1 = Enabled, 2 = Always Enabled)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hClientEnabled, OnSettingsChange);
	g_hClientVisibility = CreateConVar("css_tracer_effects_client_visibility", "0", "The default tracer visibility for new clients. (0 = All, 1 = Spectators/Dead Only, 2 = Team Members Only, 3 = Opposing Team Only)", FCVAR_NONE, true, 0.0, true, 3.0);
	HookConVarChange(g_hClientVisibility, OnSettingsChange);
	g_hClientTracer = CreateConVar("css_tracer_effects_client_tracer", "0", "The default personal tracer for new clients. (0 = Random, # = Tracer Index)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hClientTracer, OnSettingsChange);
	g_hClientPersonal = CreateConVar("css_tracer_effects_client_personal", "1", "The default personal tracer status for new clients. (0 = Hidden, 1 = Visible)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hClientPersonal, OnSettingsChange);

	g_hForceRandom = CreateConVar("css_tracer_effects_force_random", "0", "If 1 (regular) or 2 (all), clients may not choose their own tracer, rather, every tracer will be randomly colored.", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hForceRandom, OnSettingsChange);
	g_hForceTeam = CreateConVar("css_tracer_effects_force_team", "1", "If 1 (regular) or 2 (all), clients may not choose their own tracer, rather, they are assigned their css_tracer_effects_*_tracer.", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hForceTeam, OnSettingsChange);

	g_hGlobalVisibility = CreateConVar("css_tracer_effects_global_visibility", "3", "Determines tracer visibility: (0 = All, 1 = Spectators/Dead Only, 2 = Team Members Only, 3 = Opposing Team Only, 4 = Client Choice)", FCVAR_NONE, true, 0.0, true, 4.0);
	HookConVarChange(g_hGlobalVisibility, OnSettingsChange);
	g_hGlobalWidth = CreateConVar("css_tracer_effects_global_width", "3.0", "The width value to be applied to tracers. Set to -1 to use pre-defined tracer values. (Example Width: 3.0)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hGlobalWidth, OnSettingsChange);
	g_hGlobalLife = CreateConVar("css_tracer_effects_global_life", "0.33", "The lifetime value to be applied to tracers. Set to -1 to use pre-defined tracer values. (Example Life: 0.33)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hGlobalLife, OnSettingsChange);
	g_hGlobalImpact = CreateConVar("css_tracer_effects_global_impact", "0", "Determines impact method: (0 = Tracers appear from bullet_impact, 1 = Tracers appear from damaging opponent)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hGlobalImpact, OnSettingsChange);
	
	g_hGrenadeTrails = CreateConVar("css_tracer_effects_grenades", "0", "If enabled, grenades thrown by clients will have their trail attached.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hGrenadeTrails, OnSettingsChange);
	AutoExecConfig(true, "css_tracer_effects");

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("bullet_impact", Event_OnBulletImpact);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	
	g_cStatus = RegClientCookie("TracerEffects_Status", "Tracer Effects: The client's tracer status.", CookieAccess_Private);
	g_cVisibility = RegClientCookie("TracerEffects_Visibility", "Tracer Effects: The client's tracer visibility.", CookieAccess_Private);
	g_cTracer = RegClientCookie("TracerEffects_Tracer", "Tracer Effects: The client's selected tracer.", CookieAccess_Private);
	g_cPersonal = RegClientCookie("TracerEffects_Personal", "Tracer Effects: The client's tracer personal tracer status.", CookieAccess_Private);
	SetCookieMenuItem(Menu_Cookies, 0, "Tracer Settings");

	g_hConfig = LoadGameConfigFile("css_tracer_effects.gamedata");
	if(g_hConfig == INVALID_HANDLE)
		PrintToServer("Notice: LoadGameConfigFile(\"css_tracer_effects.gamedata\") doesn't appear to exist or is invalid.");
	else
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hConfig, SDKConf_Virtual, "Weapon_ShootPosition");
		PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
		g_hPosition = EndPrepSDKCall();
	}

	g_bValidSDK = (g_hPosition != INVALID_HANDLE) ? true : false;

	Define_Tracers();	
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
			else if(g_bDynamicHooks && StrEqual(classname, "weapon_knife"))
			{
				if(g_iKnife & KNIFE_PRIMARY)
					DHookEntity(g_hPrimaryAttack, false, entity, RemovalCB);

				if(g_iKnife & KNIFE_SECONDARY)
					DHookEntity(g_hSecondaryAttack, false, entity, RemovalCB);
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
			if(client > 0 && IsClientInGame(client) && g_bAccess[client])
			{
				decl String:_sTemp[64];
				Format(_sTemp, sizeof(_sTemp), "ProjectileTracers_%d", entity);
				DispatchKeyValue(entity, "targetname", _sTemp);
				new _iTrailEntity = CreateEntityByName("env_spritetrail");
				if(_iTrailEntity > 0 && IsValidEntity(_iTrailEntity))
				{
					g_iProjTrail[entity] = _iTrailEntity;
					
					DispatchKeyValue(_iTrailEntity, "parentname", _sTemp);
					DispatchKeyValue(_iTrailEntity, "renderamt", "255");
					DispatchKeyValue(_iTrailEntity, "rendercolor", g_sTracerColors[g_iPlayerTracer[client]]);
					DispatchKeyValue(_iTrailEntity, "spritename", g_sTracerTexture[g_iPlayerTracer[client]]);
					DispatchKeyValue(_iTrailEntity, "lifetime", "1.5");
					DispatchKeyValue(_iTrailEntity, "startwidth", "5.0");
					DispatchKeyValue(_iTrailEntity, "endwidth", "1.0");
					DispatchKeyValue(_iTrailEntity, "rendermode", "0");
					DispatchSpawn(_iTrailEntity);
	
					decl Float:g_fOrigin[3];
					SetEntPropFloat(_iTrailEntity, Prop_Send, "m_flTextureRes", 0.05);
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_fOrigin);
					TeleportEntity(_iTrailEntity, g_fOrigin, NULL_VECTOR, NULL_VECTOR);
					SetVariantString(_sTemp);
					AcceptEntityInput(_iTrailEntity, "SetParent", _iTrailEntity, _iTrailEntity);
				}
			}
		}
	}
}

public OnMapStart()
{
	if(g_bEnabled)
	{
		Define_Tracers();	
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

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i);
					if(g_iAccessFlag)
						g_bAccess[i] = CheckCommandAccess(i, "Tracers_Access", g_iAccessFlag);
					SDKHook(i, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
					SDKHook(i, SDKHook_TraceAttack, Hook_TraceAttack);

					if(!IsFakeClient(i))
					{
						if(!g_bLoaded[i] && AreClientCookiesCached(i))
							Void_LoadCookies(i);
					}
					else
					{
						g_bLoaded[i] = true;
						g_iPlayerEnabled[i] = g_iClientEnabled;
						g_iPlayerVisibility[i] = g_iClientVisibility;
						g_iPlayerTracer[i] = g_iClientTracer ? g_iClientTracer : GetRandomInt(1, g_iNumTracers);
						g_bPlayerPersonal[i] = g_bClientPersonal;
					}
				}
			}
			
			#if defined _dhooks_included
			if(g_bDynamicHooks)
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
								DHookEntity(g_hPrimaryAttack, false, entity, RemovalCB);

							if(g_iKnife & KNIFE_SECONDARY)
								DHookEntity(g_hSecondaryAttack, false, entity, RemovalCB);
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
		SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
		SDKHook(client, SDKHook_TraceAttack, Hook_TraceAttack);
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled)
	{
		if(g_iAccessFlag)
			g_bAccess[client] = CheckCommandAccess(client, "Tracers_Access", g_iAccessFlag);

		if(!IsFakeClient(client))
		{
			if(!g_bLoaded[client] && AreClientCookiesCached(client))
				Void_LoadCookies(client);
		}
		else
		{
			g_bLoaded[client] = true;
			g_iPlayerEnabled[client] = g_iClientEnabled;
			g_iPlayerVisibility[client] = g_iClientVisibility;
			g_iPlayerTracer[client] = g_iClientTracer ? g_iClientTracer : GetRandomInt(1, g_iNumTracers);
			g_bPlayerPersonal[client] = g_bClientPersonal;
		}
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
		g_bAccess[client] = false;
		g_iPlayerEnabled[client] = TRACERS_DISABLED;
	}
}

public OnClientCookiesCached(client)
{
	if(g_bEnabled && !g_bLoaded[client] && !IsFakeClient(client))
	{
		Void_LoadCookies(client);
	}
}


public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client))
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

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
		if(GetEventInt(event, "oldteam") == CS_TEAM_NONE && g_fAdvert >= 0.0)
			CreateTimer(g_fAdvert, Timer_Announce, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= CS_TEAM_SPECTATOR)
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
		if(g_iGlobalImpact != IMPACT_BULLET)
			return Plugin_Continue;

		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
		if(g_iPlayerEnabled[attacker])
		{
			decl Float:_fOrigin[3], Float:_fImpact[3], Float:_fDifference[3], _iColors[4];
			if(g_bValidSDK)
			{
				SDKCall(g_hPosition, attacker, _fOrigin);
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
				GetClientEyePosition(attacker, _fDifference);
				GetClientEyeAngles(attacker, _fOrigin);
				new Handle:_hTemp = TR_TraceRayFilterEx(_fDifference, _fOrigin, MASK_SHOT_HULL, RayType_Infinite, Bool_TraceFilterPlayers);
				
				if(!TR_DidHit(_hTemp))
					return Plugin_Continue;
				else
				{
					TR_GetEndPosition(_fImpact, _hTemp);
					CloseHandle(_hTemp);
				}
			}

			switch((g_iVisibility != VISIBLE_CLIENT ? g_iVisibility : g_iPlayerVisibility[attacker]))
			{
				case VISIBLE_EVERYONE:
				{
					new _iLaser = GetTracerIndex(attacker);
					_iColors = GetTracerColor(attacker);
					new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
					new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i))
						{
							if(i == attacker && g_bAllowPersonal && !g_bPlayerPersonal[i])
								continue;

							TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_SPECTATE:
				{
					new _iLaser = GetTracerIndex(attacker);
					_iColors = GetTracerColor(attacker);
					new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
					new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] <= 1 || !g_bAlive[i]))
						{
							if(i == attacker && g_bAllowPersonal && !g_bPlayerPersonal[i])
								continue;

							TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_FRIENDLY:
				{
					new _iLaser = GetTracerIndex(attacker);
					_iColors = GetTracerColor(attacker);
					new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
					new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] == g_iTeam[attacker]))
						{
							if(i == attacker && g_bAllowPersonal && !g_bPlayerPersonal[i])
								continue;

							TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_OPPOSING:
				{
					new _iLaser = GetTracerIndex(attacker);
					_iColors = GetTracerColor(attacker);
					new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
					new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] != g_iTeam[attacker]))
						{
							if(i == attacker && g_bAllowPersonal && !g_bPlayerPersonal[i])
								continue;

							TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
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
	if(client > 0 && g_iPlayerEnabled[client])
		CreateTimer(0.1, Timer_KnifeTracer, GetClientUserId(client));

	return MRES_Ignored;
}

public MRESReturn:SecondaryAttack(this, Handle:hReturn)
{
	new client = GetEntPropEnt(this, Prop_Send, "m_hOwnerEntity");
	if(client > 0 && g_iPlayerEnabled[client])
		CreateTimer(0.1, Timer_KnifeTracer, GetClientUserId(client));

	return MRES_Ignored;
}

public RemovalCB(hookid)
{

}
#endif

public Action:Timer_KnifeTracer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		if(g_bKnife[client])
			g_bKnife[client] = false;
		else if(g_bAlive[client])
		{
			decl Float:_fOrigin[3], Float:_fImpact[3], Float:_fDifference[3], _iColors[4];
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
			
			switch((g_iVisibility != VISIBLE_CLIENT ? g_iVisibility : g_iPlayerVisibility[client]))
			{
				case VISIBLE_EVERYONE:
				{
					new _iLaser = GetTracerIndex(client);
					_iColors = GetTracerColor(client);
					new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
					new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i))
						{
							if(i == client && g_bAllowPersonal && !g_bPlayerPersonal[i])
								continue;

							TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_SPECTATE:
				{
					new _iLaser = GetTracerIndex(client);
					_iColors = GetTracerColor(client);
					new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
					new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] <= 1 || !g_bAlive[i]))
						{
							if(i == client && g_bAllowPersonal && !g_bPlayerPersonal[i])
								continue;

							TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_FRIENDLY:
				{
					new _iLaser = GetTracerIndex(client);
					_iColors = GetTracerColor(client);
					new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
					new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] == g_iTeam[client]))
						{
							if(i == client && g_bAllowPersonal && !g_bPlayerPersonal[i])
								continue;

							TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_OPPOSING:
				{
					new _iLaser = GetTracerIndex(client);
					_iColors = GetTracerColor(client);
					new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
					new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] != g_iTeam[client]))
						{
							if(i == client && g_bAllowPersonal && !g_bPlayerPersonal[i])
								continue;

							TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
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

public Hook_OnTakeDamagePost(client, attacker, inflictor, Float:damage, damagetype, weapon, const Float:_fForce[3], const Float:_fImpact[3])
{
	if(g_bEnabled)
	{
		if(g_iGlobalImpact != IMPACT_DAMAGE)
			return;

		if((0 < client <= MaxClients) && (0 < attacker <= MaxClients) && g_iTeam[client] != g_iTeam[attacker])
		{
			if(g_iPlayerEnabled[attacker])
			{
				decl Float:_fOrigin[3], Float:_fDifference[3], _iColors[4];
				if(g_bValidSDK)
				{
					SDKCall(g_hPosition, attacker, _fOrigin);
					new Float:_fDistance = GetVectorDistance(_fOrigin, _fImpact);
					new Float:_fPercent = (0.4 / (_fDistance / 100.0));

					_fDifference[0] = _fOrigin[0] + ((_fImpact[0] - _fOrigin[0]) * _fPercent);
					_fDifference[1] = _fOrigin[1] + ((_fImpact[1] - _fOrigin[1]) * _fPercent) - 0.08;
					_fDifference[2] = _fOrigin[2] + ((_fImpact[2] - _fOrigin[2]) * _fPercent);
				}
				else
				{
					GetClientEyePosition(attacker, _fDifference);
					GetClientEyeAngles(attacker, _fOrigin);
					new Handle:_hTemp = TR_TraceRayFilterEx(_fDifference, _fOrigin, MASK_SHOT_HULL, RayType_Infinite, Bool_TraceFilterPlayers);
					
					if(!TR_DidHit(_hTemp))
						return;
				}

				switch((g_iVisibility != VISIBLE_CLIENT ? g_iVisibility : g_iPlayerVisibility[attacker]))
				{
					case VISIBLE_EVERYONE:
					{
						new _iLaser = GetTracerIndex(attacker);
						_iColors = GetTracerColor(attacker);
						new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
						new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

						for(new i = 1; i <= MaxClients; i++)
						{
							if(g_iPlayerEnabled[i] && IsClientInGame(i))
							{
								if(i == attacker && g_bAllowPersonal && !g_bPlayerPersonal[i])
									continue;

								TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
								TE_SendToClient(i);
							}
						}
					}
					case VISIBLE_SPECTATE:
					{
						new _iLaser = GetTracerIndex(attacker);
						_iColors = GetTracerColor(attacker);
						new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
						new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

						for(new i = 1; i <= MaxClients; i++)
						{
							if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] <= 1 || !g_bAlive[i]))
							{
								if(i == attacker && g_bAllowPersonal && !g_bPlayerPersonal[i])
									continue;

								TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
								TE_SendToClient(i);
							}
						}
					}
					case VISIBLE_FRIENDLY:
					{
						new _iLaser = GetTracerIndex(attacker);
						_iColors = GetTracerColor(attacker);
						new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
						new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

						for(new i = 1; i <= MaxClients; i++)
						{
							if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] == g_iTeam[attacker]))
							{
								if(i == attacker && g_bAllowPersonal && !g_bPlayerPersonal[i])
									continue;

								TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
								TE_SendToClient(i);
							}
						}
					}
					case VISIBLE_OPPOSING:
					{
						new _iLaser = GetTracerIndex(attacker);
						_iColors = GetTracerColor(attacker);
						new Float:_fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[_iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[_iLaser];
						new Float:_fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[_iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[_iLaser];

						for(new i = 1; i <= MaxClients; i++)
						{
							if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] != g_iTeam[attacker]))
							{
								if(i == attacker && g_bAllowPersonal && !g_bPlayerPersonal[i])
									continue;

								TE_SetupBeamPoints(_fDifference, _fImpact, g_iTracerIndex[_iLaser], 0, 0, 0, _fLife, _fWidth, _fWidth, 1, 0.0, _iColors, 0);
								TE_SendToClient(i);
							}
						}
					}
				}
			}
		}
	}
}

public bool:Bool_TraceFilterPlayers(entity, contentsMask, any:client) 
{
	return !entity || entity > MaxClients;
}

public Menu_Cookies(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "%T", "Title_Menu_Cookie", client);
		case CookieMenuAction_SelectOption:
			Menu_Tracers(client);
	}
}


Menu_Tracers(client)
{
	decl String:_sBuffer[128];
	new _iOptions, Handle:_hMenu = CreateMenu(MenuHandler_MenuTracers);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Title_Menu_Main", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);

	if(g_iClientEnabled != TRACERS_FORCED)
	{
		_iOptions++;
		if(g_iPlayerEnabled[client])
		{
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Main_Option_Disable", client);
			AddMenuItem(_hMenu, "1", _sBuffer);
		}
		else
		{
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Main_Option_Enable", client);
			AddMenuItem(_hMenu, "2", _sBuffer);
		}
	}
	
	if(g_iVisibility == VISIBLE_CLIENT)
	{
		_iOptions++;
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Main_Option_Visibility", client);
		AddMenuItem(_hMenu, "3", _sBuffer);
	}
	
	if((g_bAccess[client] && g_iForceTeam != 2 && g_iForceRandom != 2) || (!g_iAccessFlag && g_iForceRandom == 0 && g_iForceTeam == 0))
	{
		_iOptions++;
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Main_Option_Personal", client);
		AddMenuItem(_hMenu, "4", _sBuffer);
	}
	
	if(g_bAllowPersonal)
	{
		_iOptions++;
		if(g_bPlayerPersonal[client])
		{
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Main_Option_Personal_Disable", client);
			AddMenuItem(_hMenu, "5", _sBuffer);
		}
		else
		{
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Main_Option_Personal_Enable", client);
			AddMenuItem(_hMenu, "6", _sBuffer);
		}
	}

	if(_iOptions)
		DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);

	return _iOptions++;
}

public MenuHandler_MenuTracers(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel: 
		{
			switch (param2) 
			{
				case MenuCancel_ExitBack:
					ShowCookieMenu(param1);

			}
		}
		case MenuAction_Select:
		{
			decl String:_sTemp[4];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			switch(StringToInt(_sTemp))
			{
				case 1:
				{
					g_iPlayerEnabled[param1] = 0;
					SetClientCookie(param1, g_cStatus, "0");

					CPrintToChat(param1, "%s%t", g_sPrefixChat, "Personal_Phrase_Disable");
					Menu_Tracers(param1);
				}
				case 2:
				{
					g_iPlayerEnabled[param1] = 1;
					SetClientCookie(param1, g_cStatus, "1");

					CPrintToChat(param1, "%s%t", g_sPrefixChat, "Personal_Phrase_Enable");
					Menu_Tracers(param1);
				}
				case 3:
				{
					Menu_Visibility(param1);
				}
				case 4:
				{
					Menu_Personal(param1);
				}
				case 5:
				{
					g_bPlayerPersonal[param1] = false;
					
					IntToString(g_bPlayerPersonal[param1], _sTemp, sizeof(_sTemp));
					SetClientCookie(param1, g_cPersonal, _sTemp);

					CPrintToChat(param1, "%s%t", g_sPrefixChat, "Personal_Phrase_Hide");
					Menu_Tracers(param1);
				}
				case 6:
				{
					g_bPlayerPersonal[param1] = true;
					
					IntToString(g_bPlayerPersonal[param1], _sTemp, sizeof(_sTemp));
					SetClientCookie(param1, g_cPersonal, _sTemp);

					CPrintToChat(param1, "%s%t", g_sPrefixChat, "Personal_Phrase_Show");
					Menu_Tracers(param1);
				}
			}
		}
	}
}

Menu_Visibility(client)
{
	decl String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuVisibility);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Title_Menu_Visibility", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);
	
	Format(_sBuffer, sizeof(_sBuffer), "%s%T", (g_iPlayerVisibility[client] == VISIBLE_EVERYONE) ? g_sPrefixSelect : g_sPrefixEmpty, "Visibility_Option_Everyone", client);
	AddMenuItem(_hMenu, "0", _sBuffer);

	Format(_sBuffer, sizeof(_sBuffer), "%s%T", (g_iPlayerVisibility[client] == VISIBLE_SPECTATE) ? g_sPrefixSelect : g_sPrefixEmpty, "Visibility_Option_Spectate", client);
	AddMenuItem(_hMenu, "1", _sBuffer);
	
	Format(_sBuffer, sizeof(_sBuffer), "%s%T", (g_iPlayerVisibility[client] == VISIBLE_FRIENDLY) ? g_sPrefixSelect : g_sPrefixEmpty, "Visibility_Option_Friendly", client);
	AddMenuItem(_hMenu, "2", _sBuffer);
	
	Format(_sBuffer, sizeof(_sBuffer), "%s%T", (g_iPlayerVisibility[client] == VISIBLE_OPPOSING) ? g_sPrefixSelect : g_sPrefixEmpty, "Visibility_Option_Opposing", client);
	AddMenuItem(_hMenu, "3", _sBuffer);
	
	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuVisibility(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel: 
		{
			switch (param2) 
			{
				case MenuCancel_ExitBack:
					Menu_Tracers(param1);
			}
		}
		case MenuAction_Select:
		{
			decl String:_sOption[4];
			GetMenuItem(menu, param2, _sOption, sizeof(_sOption));
			g_iPlayerVisibility[param1] = StringToInt(_sOption);
			
			switch(g_iPlayerVisibility[param1])
			{
				case VISIBLE_EVERYONE:
					CPrintToChat(param1, "%s%t", g_sPrefixChat, "Visible_Phrase_Everyone");
				case VISIBLE_SPECTATE:
					CPrintToChat(param1, "%s%t", g_sPrefixChat, "Visible_Phrase_Spectate");
				case VISIBLE_FRIENDLY:
					CPrintToChat(param1, "%s%t", g_sPrefixChat, "Visible_Phrase_Friendly");
				case VISIBLE_OPPOSING:
					CPrintToChat(param1, "%s%t", g_sPrefixChat, "Visible_Phrase_Opposing");
			}
			SetClientCookie(param1, g_cVisibility, _sOption);

			Menu_Tracers(param1);
		}
	}
}

Menu_Personal(client)
{
	decl String:_sTemp[4], String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuPersonal);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Title_Menu_Personal", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 1; i <= g_iNumTracers; i++)
	{
		if(!g_bTracerEnabled[i])
			continue;

		if(!g_iTracerFlag[i] || CheckCommandAccess(client, "Tracers_Access_Material", g_iTracerFlag[i]))
		{
			IntToString(i, _sTemp, sizeof(_sTemp));
			Format(_sBuffer, sizeof(_sBuffer), "%s%s", (g_iPlayerTracer[client] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sTracerName[i]);
			AddMenuItem(_hMenu, _sTemp, _sBuffer);
		}
	}

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuPersonal(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel: 
		{
			switch (param2) 
			{
				case MenuCancel_ExitBack:
					Menu_Tracers(param1);
			}
		}
		case MenuAction_Select:
		{
			decl String:_sOption[4];
			GetMenuItem(menu, param2, _sOption, sizeof(_sOption));
			g_iPlayerTracer[param1] = StringToInt(_sOption);
			
			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Personal_Phrase_Select", g_sTracerName[g_iPlayerTracer[param1]]);
			SetClientCookie(param1, g_cTracer, _sOption);

			Menu_Tracers(param1);
		}
	}
}

public Action:Timer_Announce(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
		CPrintToChat(client, "%s%t", g_sPrefixChat, "Advert_Phrase");
}

GetTracerRandom()
{
	decl _iArray[4];
	for(new i = 0; i <= 3; i++)
		_iArray[i] = GetRandomInt(0, 255);

	return _iArray;
}


GetTracerIndex(client)
{
	switch(g_iForceRandom)
	{
		case 1:
		{
			if(!g_bAccess[client] || !g_iAccessFlag)
				return GetRandomInt(1, g_iNumTracers);
		}
		case 2:
			return GetRandomInt(1, g_iNumTracers);
	}

	switch(g_iForceTeam)
	{
		case 1:
		{
			if(!g_bAccess[client] || !g_iAccessFlag)
			{
				switch(g_iTeam[client])
				{
					case CS_TEAM_T:
						return g_iRedIndex;
					case CS_TEAM_CT:
						return g_iBlueIndex;
				}
			}
		}
		case 2:
		{
			switch(g_iTeam[client])
			{
				case CS_TEAM_T:
					return g_iRedIndex;
				case CS_TEAM_CT:
					return g_iBlueIndex;
			}
		}
	}

	return g_iPlayerTracer[client];
}

GetTracerColor(client)
{
	switch(g_iForceRandom)
	{
		case 1:
		{
			if(!g_bAccess[client] || !g_iAccessFlag)
				return GetTracerRandom();
		}
		case 2:
			return GetTracerRandom();
	}

	switch(g_iForceTeam)
	{
		case 1:
		{
			if(!g_bAccess[client] || !g_iAccessFlag)
			{
				switch(g_iTeam[client])
				{
					case CS_TEAM_T:
						return g_iRedColors;
					case CS_TEAM_CT:
						return g_iBlueColors;
				}
			}
		}
		case 2:
		{
			switch(g_iTeam[client])
			{
				case CS_TEAM_T:
					return g_iRedColors;
				case CS_TEAM_CT:
					return g_iBlueColors;
			}
		}
	}

	return g_iTracerColor[g_iPlayerTracer[client]];
}

Void_LoadCookies(client)
{
	decl String:_sCookie[8] = "";
	GetClientCookie(client, g_cStatus, _sCookie, sizeof(_sCookie));

	if(StrEqual(_sCookie, "", false))
	{
		g_iPlayerEnabled[client] = g_iClientEnabled;
		g_iPlayerVisibility[client] = g_iClientVisibility;
		g_iPlayerTracer[client] = g_iClientTracer ? g_iClientTracer : GetRandomInt(1, g_iNumTracers);
		g_bPlayerPersonal[client] = g_bClientPersonal;
	}
	else
	{
		g_iPlayerEnabled[client] = StringToInt(_sCookie);

		if(g_iVisibility == VISIBLE_CLIENT)
		{
			GetClientCookie(client, g_cVisibility, _sCookie, sizeof(_sCookie));
			g_iPlayerVisibility[client] = StringToInt(_sCookie);
		}
		else
			g_iPlayerVisibility[client] = g_iClientVisibility;
			
		if(g_iForceRandom != 2 && g_iForceTeam != 2)
		{
			GetClientCookie(client, g_cTracer, _sCookie, sizeof(_sCookie));
			g_iPlayerTracer[client] = StringToInt(_sCookie);
			
			if(g_iPlayerTracer[client] > g_iNumTracers)
				g_iPlayerTracer[client] = g_iClientTracer ? g_iClientTracer : GetRandomInt(1, g_iNumTracers);
		}
		else
			g_iPlayerTracer[client] = g_iClientTracer ? g_iClientTracer : GetRandomInt(1, g_iNumTracers);

		if(g_bAllowPersonal)
		{
			GetClientCookie(client, g_cPersonal, _sCookie, sizeof(_sCookie));
			g_bPlayerPersonal[client] = StringToInt(_sCookie) ? true : false;
		}
		else
			g_bPlayerPersonal[client] = g_bClientPersonal;
	}

	g_bLoaded[client] = true;
}


Define_Tracers()
{
	decl String:_sPath[PLATFORM_MAX_PATH], String:_sBuffer[64];
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "configs/css_tracer_effects.ini");
	
	new _iCurrent = GetFileTime(_sPath, FileTime_LastChange);
	if(_iCurrent < g_iLoadTracers)
		return;
	else
		g_iLoadTracers = _iCurrent;
	
	g_iNumTracers = 0;
	new Handle:_hKV = CreateKeyValues("TracerEffects_Tracers");
	if(FileToKeyValues(_hKV, _sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			g_iNumTracers++;
			KvGetSectionName(_hKV, g_sTracerName[g_iNumTracers], 64);
			if(StrContains(g_sTracerName[g_iNumTracers], "~", false) == -1)
				g_bTracerEnabled[g_iNumTracers] = true;
			else
			{
				g_bTracerEnabled[g_iNumTracers] = false;

				if(StrContains(g_sTracerName[g_iNumTracers], "2", false) != -1)
				{
					g_iRedIndex = g_iNumTracers;
					KvGetString(_hKV, "Texture", g_sRedTexture, sizeof(g_sRedTexture));

					g_iRedColors[0] = KvGetNum(_hKV, "Red", 255);
					g_iRedColors[1] = KvGetNum(_hKV, "Green", 255);
					g_iRedColors[2] = KvGetNum(_hKV, "Blue", 255);
					g_iRedColors[3] = KvGetNum(_hKV, "Alpha", 255);
				}
				else if(StrContains(g_sTracerName[g_iNumTracers], "3", false) != -1)
				{
					g_iBlueIndex = g_iNumTracers;
					KvGetString(_hKV, "Texture", g_sBlueTexture, sizeof(g_sBlueTexture));

					g_iBlueColors[0] = KvGetNum(_hKV, "Red", 255);
					g_iBlueColors[1] = KvGetNum(_hKV, "Green", 255);
					g_iBlueColors[2] = KvGetNum(_hKV, "Blue", 255);
					g_iBlueColors[3] = KvGetNum(_hKV, "Alpha", 255);
				}
			}

			KvGetString(_hKV, "Texture", g_sTracerTexture[g_iNumTracers], sizeof(g_sTracerTexture[]));
			KvGetString(_hKV, "Flag", _sBuffer, sizeof(_sBuffer));
			g_iTracerFlag[g_iNumTracers] = ReadFlagString(_sBuffer);

			g_fTracerLife[g_iNumTracers] = KvGetFloat(_hKV, "Life", g_fDefaultLife != -1 ? g_fDefaultLife : 1.0);
			g_fTracerWidth[g_iNumTracers] = KvGetFloat(_hKV, "Width", g_fDefaultWidth != -1 ? g_fDefaultWidth : 3.0);
			g_bTracerTeam[g_iNumTracers] = KvGetNum(_hKV, "Team", 0) ? true : false;
			g_iTracerColor[g_iNumTracers][0] = KvGetNum(_hKV, "Red", 255);
			g_iTracerColor[g_iNumTracers][1] = KvGetNum(_hKV, "Green", 255);
			g_iTracerColor[g_iNumTracers][2] = KvGetNum(_hKV, "Blue", 255);
			g_iTracerColor[g_iNumTracers][3] = KvGetNum(_hKV, "Alpha", 255);
			Format(g_sTracerColors[g_iNumTracers], sizeof(g_sTracerColors[]), "%d %d %d %d", g_iTracerColor[g_iNumTracers][0], g_iTracerColor[g_iNumTracers][1], g_iTracerColor[g_iNumTracers][2], g_iTracerColor[g_iNumTracers][3]);
		}
		while (KvGotoNextKey(_hKV));
		CloseHandle(_hKV);
	}
	else
	{
		CloseHandle(_hKV);
		SetFailState("Tracer Effects: Could not locate \"configs/css_tracer_effects.ini\"");
	}
}

Void_Prepare()
{
	decl String:_sBuffer[256];
	for(new i = 1; i <= g_iNumTracers; i++)
	{
		strcopy(_sBuffer, sizeof(_sBuffer), g_sTracerTexture[i]);
		AddFileToDownloadsTable(_sBuffer);

		g_iTracerIndex[i] = PrecacheModel(g_sTracerTexture[i]);
		ReplaceString(_sBuffer, sizeof(_sBuffer), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(_sBuffer);
	}
}

Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_fAdvert = GetConVarFloat(g_hAdvert);
	g_iVisibility = GetConVarInt(g_hGlobalVisibility);
	g_iKnife = GetConVarInt(g_hKnife);
	decl String:_sTemp[192];
	GetConVarString(g_hChatCommands, _sTemp, sizeof(_sTemp));
	g_iNumCommands = ExplodeString(_sTemp, ", ", g_sChatCommands, 16, 32);
	GetConVarString(g_hFlag, _sTemp, sizeof(_sTemp));
	g_iAccessFlag = ReadFlagString(_sTemp);
	
	g_iClientEnabled = GetConVarInt(g_hClientEnabled);
	g_iClientVisibility = GetConVarInt(g_hClientVisibility);
	g_iClientTracer = GetConVarInt(g_hClientTracer);
	g_bClientPersonal = GetConVarInt(g_hClientPersonal) ? true : false;

	g_iForceTeam = GetConVarInt(g_hForceTeam);
	g_iForceRandom = GetConVarInt(g_hForceRandom);
	g_bAllowPersonal = GetConVarInt(g_hAllowPersonal) ? true : false;

	g_fDefaultWidth = GetConVarFloat(g_hGlobalWidth);
	g_fDefaultLife = GetConVarFloat(g_hGlobalLife);
	g_iGlobalImpact = GetConVarInt(g_hGlobalImpact);
	g_bGrenadeTrails = GetConVarInt(g_hGrenadeTrails) ? true : false;
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = bool:StringToInt(newvalue);
	else if(cvar == g_hAdvert)
		g_fAdvert = StringToFloat(newvalue);
	else if(cvar == g_hGlobalVisibility)
		g_iVisibility = StringToInt(newvalue);
	else if(cvar == g_hKnife)
		g_iKnife = StringToInt(newvalue);
	else if(cvar == g_hChatCommands)
		g_iNumCommands = ExplodeString(newvalue, ", ", g_sChatCommands, 16, 32);
	else if(cvar == g_hClientEnabled)
		g_iClientEnabled = StringToInt(newvalue);
	else if(cvar == g_hClientVisibility)
		g_iClientVisibility = StringToInt(newvalue);
	else if(cvar == g_hClientTracer)
		g_iClientTracer = StringToInt(newvalue);
	else if(cvar == g_hClientPersonal)
		g_bClientPersonal = bool:StringToInt(newvalue);
	else if(cvar == g_hForceTeam)
		g_iForceTeam = StringToInt(newvalue);
	else if(cvar == g_hForceRandom)
		g_iForceRandom = StringToInt(newvalue);
	else if(cvar == g_hAllowPersonal)
		g_bAllowPersonal = bool:StringToInt(newvalue);
	else if(cvar == g_hGlobalWidth)
		g_fDefaultWidth = StringToFloat(newvalue);
	else if(cvar == g_hGlobalLife)
		g_fDefaultLife = StringToFloat(newvalue);
	else if(cvar == g_hGlobalImpact)
		g_iGlobalImpact = StringToInt(newvalue);
	else if(cvar == g_hFlag)
		g_iAccessFlag = ReadFlagString(newvalue);
	else if(cvar == g_hGrenadeTrails)
		g_bGrenadeTrails = bool:StringToInt(newvalue);
}