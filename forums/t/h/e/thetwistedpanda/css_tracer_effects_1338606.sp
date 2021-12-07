/*
	Revision 1.2.6
	Added an additional check to prevent the plugin looking for DHooks if the plugin was compiled with DHooks.
	
	Revision 1.2.7
	Removed requirement of Weapon_ShootPosition gamedata.
	
	Revision 1.2.8
	Raised hardcoded tracer limit by 128.
	Cleaned up a few elements of aging code.
	Fixed Dynamic Hooks not being considered optional, and thus gamedata not being optional.
	Fixed a potentially harmless? bug where a client's living state wasn't reset on joining spectate.
	Depreciated Cvar css_tracer_effects_personal_tracer & expanded functionality of css_tracer_effects_client_personal:
		0 = Hidden
		1 = Visible
		2 = Always Hidden
		3 = Always Visible
	Default usage to morecolors.inc instead of colors.inc
	Compiled a non-dynamic hooks version as I do not plan on providing updated gamedata.
*/

#define MAX_TRACERS 256

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <clientprefs>
#include <cstrike>
//#undef REQUIRE_EXTENSIONS
//#tryinclude <dhooks>

#define PLUGIN_VERSION "1.2.8"

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
new Handle:g_hClientEnabled = INVALID_HANDLE;
new Handle:g_hClientVisibility = INVALID_HANDLE;
new Handle:g_hClientTracer = INVALID_HANDLE;
new Handle:g_hClientPersonal = INVALID_HANDLE;
new Handle:g_hGrenadeTrails = INVALID_HANDLE;
new Handle:g_hForceRandom = INVALID_HANDLE;
new Handle:g_hForceTeam = INVALID_HANDLE;
new Handle:g_hGlobalWidth = INVALID_HANDLE;
new Handle:g_hGlobalLife = INVALID_HANDLE;
new Handle:g_hGlobalImpact = INVALID_HANDLE;
new Handle:g_cStatus = INVALID_HANDLE;
new Handle:g_cVisibility = INVALID_HANDLE;
new Handle:g_cTracer = INVALID_HANDLE;
new Handle:g_cPersonal = INVALID_HANDLE;
#if defined _dhooks_included
new Handle:g_hConfig = INVALID_HANDLE;
new Handle:g_hKnife = INVALID_HANDLE;
new Handle:g_hPrimaryAttack = INVALID_HANDLE;
new Handle:g_hSecondaryAttack = INVALID_HANDLE;
#endif

new g_iAccessFlag;
new g_iNumCommands;
new g_iVisibility;
new g_iNumTracers;
new g_iClientPersonal;
new g_iClientEnabled;
new g_iClientVisibility;
new g_iClientTracer;
new g_iGlobalImpact;
new g_iForceRandom;
new g_iForceTeam;
#if defined _dhooks_included
new g_iKnife;
new bool:g_bLoadedHooks;
new bool:g_bDynamicHooks;
#endif
new g_iRedIndex;
new g_iBlueIndex;
new g_iRedColors[4];
new g_iBlueColors[4];
new bool:g_bEnabled;
new bool:g_bLateLoad;
new bool:g_bGrenadeTrails;
new Float:g_fAdvert;
new Float:g_fDefaultLife;
new Float:g_fDefaultWidth;
new String:g_sPrefixChat[32];
new String:g_sPrefixSelect[16];
new String:g_sPrefixEmpty[16];
new String:g_sChatCommands[16][32];
new String:g_sRedTexture[PLATFORM_MAX_PATH];
new String:g_sBlueTexture[PLATFORM_MAX_PATH];

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
new g_iPlayerPersonal[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new bool:g_bAccess[MAXPLAYERS + 1];
new bool:g_bKnife[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "[CS:S] Tracer Effects",
	author = "Panduh (AlliedMods: thetwistedpanda)",
	description = "Provides both simple and advanced functionality for displaying tracers focused on server-wide usage.", 	
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public OnAllPluginsLoaded()
{
	#if defined _dhooks_included
	g_bDynamicHooks = LibraryExists("dhook");
	if(g_bDynamicHooks && !g_bLoadedHooks)
	{
		g_bLoadedHooks = true;
		new _iPrim = GameConfGetOffset(g_hConfig, "PrimaryAttack");
		g_hPrimaryAttack = DHookCreate(_iPrim, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, PrimaryAttack);
		new _iSec = GameConfGetOffset(g_hConfig, "SecondaryAttack");
		g_hSecondaryAttack = DHookCreate(_iSec, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, SecondaryAttack);
	}
	#endif
}
 
public OnLibraryRemoved(const String:name[])
{
	#if defined _dhooks_included
	if (StrEqual(name, "dhook"))
	{
		g_bDynamicHooks = false;
	}
	#endif
}
 
public OnLibraryAdded(const String:name[])
{
	#if defined _dhooks_included
	if (StrEqual(name, "dhook"))
	{
		g_bDynamicHooks = true;
		if(!g_bLoadedHooks)
		{
			g_bLoadedHooks = true;
			new _iPrim = GameConfGetOffset(g_hConfig, "PrimaryAttack");
			g_hPrimaryAttack = DHookCreate(_iPrim, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, PrimaryAttack);
			new _iSec = GameConfGetOffset(g_hConfig, "SecondaryAttack");
			g_hSecondaryAttack = DHookCreate(_iSec, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, SecondaryAttack);
			
		}
	}
	#endif
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	decl String:sTemp[192];
	LoadTranslations("common.phrases");
	LoadTranslations("css_tracer_effects.phrases");
	
	CreateConVar("css_tracer_effects_version", PLUGIN_VERSION, "[CS:S] Tracer Effects: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_tracer_effects", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnCVarChange);
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	g_hAdvert = CreateConVar("css_tracer_effects_advert", "-1.0", "The number of seconds after a client joins an initial team for an informational advert to be sent to the client. (-1.0 = No Advert)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hAdvert, OnCVarChange);
	g_fAdvert = GetConVarFloat(g_hAdvert);
	
	g_hFlag = CreateConVar("css_tracer_effects_flag", "", "Provides the ability to restrict Tracers to specific flag(s) or anyone with the \"Tracers_Access\" override.", FCVAR_NONE);
	HookConVarChange(g_hFlag, OnCVarChange);
	GetConVarString(g_hFlag, sTemp, sizeof(sTemp));
	g_iAccessFlag = ReadFlagString(sTemp);
	
	g_hChatCommands = CreateConVar("css_tracer_effects_commands", "!tracer, !tracers, /tracer, /tracers, !laser, !lasers, /laser, /lasers", "The chat triggers available to clients to access tracers features.", FCVAR_NONE);
	HookConVarChange(g_hChatCommands, OnCVarChange);
	GetConVarString(g_hChatCommands, sTemp, sizeof(sTemp));
	g_iNumCommands = ExplodeString(sTemp, ", ", g_sChatCommands, sizeof(g_sChatCommands), sizeof(g_sChatCommands[]));
	
	g_hClientEnabled = CreateConVar("css_tracer_effects_client_enabled", "2", "The tracer status for new clients. (0 = Disabled, 1 = Enabled, 2 = Always Enabled)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hClientEnabled, OnCVarChange);
	g_iClientEnabled = GetConVarInt(g_hClientEnabled);
	
	g_hClientVisibility = CreateConVar("css_tracer_effects_client_visibility", "0", "The default tracer visibility for new clients, if css_tracer_effects_global_visibility is set to Client Choice. (0 = All, 1 = Spectators/Dead Only, 2 = Team Members Only, 3 = Opposing Team Only)", FCVAR_NONE, true, 0.0, true, 3.0);
	HookConVarChange(g_hClientVisibility, OnCVarChange);
	g_iClientVisibility = GetConVarInt(g_hClientVisibility);
	
	g_hClientTracer = CreateConVar("css_tracer_effects_client_tracer", "0", "The default personal tracer for new clients. (0 = Random, # = Tracer Index)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hClientTracer, OnCVarChange);
	g_iClientTracer = GetConVarInt(g_hClientTracer);
	
	g_hClientPersonal = CreateConVar("css_tracer_effects_client_personal", "3", "The default personal tracer status for new clients. (0 = Hidden, 1 = Visible, 2 = Always Hidden, 3 = Always Visible)", FCVAR_NONE, true, 0.0, true, 3.0);
	HookConVarChange(g_hClientPersonal, OnCVarChange);
	g_iClientPersonal = GetConVarInt(g_hClientPersonal);

	g_hForceRandom = CreateConVar("css_tracer_effects_force_random", "0", "If 1 (only authed players) or 2 (all players), clients may not choose their own tracer, rather, every tracer will be randomly colored.", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hForceRandom, OnCVarChange);
	g_iForceRandom = GetConVarInt(g_hForceRandom);
	
	g_hForceTeam = CreateConVar("css_tracer_effects_force_team", "0", "If 1 (only authed) players) or 2 (all players), clients may not choose their own tracer, rather, they are assigned their css_tracer_effects_*_tracer.", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hForceTeam, OnCVarChange);
	g_iForceTeam = GetConVarInt(g_hForceTeam);

	g_hGlobalVisibility = CreateConVar("css_tracer_effects_global_visibility", "1", "Determines tracer visibility: (0 = Forced All, 1 = Forced Spectators/Dead Only, 2 = Forced Team Members Only, 3 = Forced Opposing Team Only, 4 = Client Choice)", FCVAR_NONE, true, 0.0, true, 4.0);
	HookConVarChange(g_hGlobalVisibility, OnCVarChange);
	g_iVisibility = GetConVarInt(g_hGlobalVisibility);
	
	g_hGlobalWidth = CreateConVar("css_tracer_effects_global_width", "3.0", "The width value to be applied to tracers. Set to -1 to use pre-defined tracer values from configuration file. (Example Width: 3.0)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hGlobalWidth, OnCVarChange);
	g_fDefaultWidth = GetConVarFloat(g_hGlobalWidth);

	g_hGlobalLife = CreateConVar("css_tracer_effects_global_life", "0.33", "The lifetime value to be applied to tracers. Set to -1 to use pre-defined tracer values from configuration file. (Example Life: 0.33)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hGlobalLife, OnCVarChange);
	g_fDefaultLife = GetConVarFloat(g_hGlobalLife);
	
	g_hGlobalImpact = CreateConVar("css_tracer_effects_global_impact", "0", "Determines impact method: (0 = Tracers appear from bullet_impact, 1 = Tracers appear from damaging opponent)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hGlobalImpact, OnCVarChange);
	g_iGlobalImpact = GetConVarInt(g_hGlobalImpact);
	
	g_hGrenadeTrails = CreateConVar("css_tracer_effects_grenades", "0", "If enabled, grenades thrown by clients will have their trail attached.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hGrenadeTrails, OnCVarChange);
	g_bGrenadeTrails = GetConVarBool(g_hGrenadeTrails);

	#if defined _dhooks_included
	g_hKnife = CreateConVar("css_tracer_effects_knife", "0", "[Requires DynamicHooks Game Data] If enabled, clients with access can shoot tracers from their knife to their crosshair location. (0 = Disabled, 1 = Left Click, 2 = Right Click, 3 = Both Clicks)", FCVAR_NONE, true, 0.0, true, 3.0);
	HookConVarChange(g_hKnife, OnCVarChange);
	g_iKnife = GetConVarInt(g_hKnife);
	#endif
	
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

	#if defined _dhooks_included
	g_hConfig = LoadGameConfigFile("css_tracer_effects.gamedata");
	#endif
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
			if(client > 0 && IsClientInGame(client) && g_bAccess[client])
			{
				decl String:sTemp[64];
				Format(sTemp, sizeof(sTemp), "ProjectileTracers_%d", entity);
				DispatchKeyValue(entity, "targetname", sTemp);
				new _iTrailEntity = CreateEntityByName("env_spritetrail");
				if(_iTrailEntity > 0 && IsValidEntity(_iTrailEntity))
				{
					g_iProjTrail[entity] = _iTrailEntity;
					
					DispatchKeyValue(_iTrailEntity, "parentname", sTemp);
					DispatchKeyValue(_iTrailEntity, "renderamt", "255");
					DispatchKeyValue(_iTrailEntity, "rendercolor", g_sTracerColors[g_iPlayerTracer[client]]);
					DispatchKeyValue(_iTrailEntity, "spritename", g_sTracerTexture[g_iPlayerTracer[client]]);
					DispatchKeyValue(_iTrailEntity, "lifetime", "1.5");
					DispatchKeyValue(_iTrailEntity, "startwidth", "5.0");
					DispatchKeyValue(_iTrailEntity, "endwidth", "1.0");
					DispatchKeyValue(_iTrailEntity, "rendermode", "0");
					DispatchSpawn(_iTrailEntity);
	
					decl Float:gfPosition[3];
					SetEntPropFloat(_iTrailEntity, Prop_Send, "m_flTextureRes", 0.05);
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", gfPosition);
					TeleportEntity(_iTrailEntity, gfPosition, NULL_VECTOR, NULL_VECTOR);
					SetVariantString(sTemp);
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
		Prepare();
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
					#if defined _dhooks_included
					SDKHook(i, SDKHook_TraceAttack, Hook_TraceAttack);
					#endif

					if(!IsFakeClient(i))
					{
						if(!g_bLoaded[i] && AreClientCookiesCached(i))
							LoadCookies(i);
					}
					else
					{
						g_bLoaded[i] = true;
						g_iPlayerEnabled[i] = g_iClientEnabled;
						g_iPlayerVisibility[i] = g_iClientVisibility;
						g_iPlayerTracer[i] = g_iClientTracer ? g_iClientTracer : GetRandomInt(1, g_iNumTracers);
						g_iPlayerPersonal[i] = g_iClientPersonal;
					}
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
		SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
		#if defined _dhooks_included
		SDKHook(client, SDKHook_TraceAttack, Hook_TraceAttack);
		#endif
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
				LoadCookies(client);
		}
		else
		{
			g_bLoaded[client] = true;
			g_iPlayerEnabled[client] = g_iClientEnabled;
			g_iPlayerVisibility[client] = g_iClientVisibility;
			g_iPlayerTracer[client] = g_iClientTracer ? g_iClientTracer : GetRandomInt(1, g_iNumTracers);
			g_iPlayerPersonal[client] = g_iClientPersonal;
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
		LoadCookies(client);
	}
}


public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client) || !g_iNumCommands)
			return Plugin_Continue;

		decl String:sText[192], String:sBuffer[32];
		GetCmdArgString(sText, sizeof(sText));

		new iStart;
		if(sText[strlen(sText) - 1] == '"')
		{
			sText[strlen(sText) - 1] = '\0';
			iStart = 1;
		}
		
		BreakString(sText[iStart], sBuffer, sizeof(sBuffer));
		for(new i = 0; i < g_iNumCommands; i++)
		{
			if(StrEqual(sBuffer, g_sChatCommands[i], false))
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
		if(g_iTeam[client] == CS_TEAM_SPECTATOR)
			g_bAlive[client] = false;
		
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
			decl Float:fPosition[3], Float:fImpact[3], Float:fDifference[3], iColors[4];
			GetClientEyePosition(attacker, fPosition);
			fImpact[0] = GetEventFloat(event, "x");
			fImpact[1] = GetEventFloat(event, "y");
			fImpact[2] = GetEventFloat(event, "z");

			new Float:fDistance = GetVectorDistance(fPosition, fImpact);
			new Float:fPercent = (0.4 / (fDistance / 100.0));

			fDifference[0] = fPosition[0] + ((fImpact[0] - fPosition[0]) * fPercent);
			fDifference[1] = fPosition[1] + ((fImpact[1] - fPosition[1]) * fPercent) - 0.08;
			fDifference[2] = fPosition[2] + ((fImpact[2] - fPosition[2]) * fPercent);

			switch((g_iVisibility != VISIBLE_CLIENT ? g_iVisibility : g_iPlayerVisibility[attacker]))
			{
				case VISIBLE_EVERYONE:
				{
					new iLaser = GetTracerIndex(attacker);
					iColors = GetTracerColor(attacker);
					new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
					new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i))
						{
							if(i == attacker && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
								continue;

							TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_SPECTATE:
				{
					new iLaser = GetTracerIndex(attacker);
					iColors = GetTracerColor(attacker);
					new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
					new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] <= 1 || !g_bAlive[i]))
						{
							if(i == attacker && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
								continue;

							TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_FRIENDLY:
				{
					new iLaser = GetTracerIndex(attacker);
					iColors = GetTracerColor(attacker);
					new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
					new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] == g_iTeam[attacker]))
						{
							if(i == attacker && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
								continue;

							TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_OPPOSING:
				{
					new iLaser = GetTracerIndex(attacker);
					iColors = GetTracerColor(attacker);
					new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
					new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] != g_iTeam[attacker]))
						{
							if(i == attacker && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
								continue;

							TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
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

public Action:Timer_KnifeTracer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		if(g_bKnife[client])
			g_bKnife[client] = false;
		else if(g_bAlive[client])
		{
			decl Float:fPosition[3], Float:fImpact[3], Float:fDifference[3], iColors[4];
			GetClientEyePosition(client, fDifference);
			GetClientEyeAngles(client, fPosition);
			new Handle:_hTemp = TR_TraceRayFilterEx(fDifference, fPosition, MASK_SHOT_HULL, RayType_Infinite, Bool_TraceFilterPlayers);
			
			if(TR_DidHit(_hTemp))
				TR_GetEndPosition(fImpact, _hTemp);
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
					new iLaser = GetTracerIndex(client);
					iColors = GetTracerColor(client);
					new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
					new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i))
						{
							if(i == client && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
								continue;

							TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_SPECTATE:
				{
					new iLaser = GetTracerIndex(client);
					iColors = GetTracerColor(client);
					new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
					new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] <= 1 || !g_bAlive[i]))
						{
							if(i == client && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
								continue;

							TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_FRIENDLY:
				{
					new iLaser = GetTracerIndex(client);
					iColors = GetTracerColor(client);
					new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
					new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] == g_iTeam[client]))
						{
							if(i == client && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
								continue;

							TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
							TE_SendToClient(i);
						}
					}
				}
				case VISIBLE_OPPOSING:
				{
					new iLaser = GetTracerIndex(client);
					iColors = GetTracerColor(client);
					new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
					new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

					for(new i = 1; i <= MaxClients; i++)
					{
						if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] != g_iTeam[client]))
						{
							if(i == client && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
								continue;

							TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
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
#endif

public Hook_OnTakeDamagePost(client, attacker, inflictor, Float:damage, damagetype, weapon, const Float:_fForce[3], const Float:fImpact[3])
{
	if(g_bEnabled)
	{
		if(g_iGlobalImpact != IMPACT_DAMAGE)
			return;

		if((0 < client <= MaxClients) && (0 < attacker <= MaxClients) && g_iTeam[client] != g_iTeam[attacker])
		{
			if(g_iPlayerEnabled[attacker])
			{
				decl Float:fPosition[3], Float:fDifference[3], iColors[4];
				GetClientEyePosition(client, fPosition);
				new Float:fDistance = GetVectorDistance(fPosition, fImpact);
				new Float:fPercent = (0.4 / (fDistance / 100.0));

				fDifference[0] = fPosition[0] + ((fImpact[0] - fPosition[0]) * fPercent);
				fDifference[1] = fPosition[1] + ((fImpact[1] - fPosition[1]) * fPercent) - 0.08;
				fDifference[2] = fPosition[2] + ((fImpact[2] - fPosition[2]) * fPercent);

				switch((g_iVisibility != VISIBLE_CLIENT ? g_iVisibility : g_iPlayerVisibility[attacker]))
				{
					case VISIBLE_EVERYONE:
					{
						new iLaser = GetTracerIndex(attacker);
						iColors = GetTracerColor(attacker);
						new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
						new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

						for(new i = 1; i <= MaxClients; i++)
						{
							if(g_iPlayerEnabled[i] && IsClientInGame(i))
							{
								if(i == attacker && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
									continue;

								TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
								TE_SendToClient(i);
							}
						}
					}
					case VISIBLE_SPECTATE:
					{
						new iLaser = GetTracerIndex(attacker);
						iColors = GetTracerColor(attacker);
						new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
						new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

						for(new i = 1; i <= MaxClients; i++)
						{
							if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] <= 1 || !g_bAlive[i]))
							{
								if(i == attacker && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
									continue;

								TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
								TE_SendToClient(i);
							}
						}
					}
					case VISIBLE_FRIENDLY:
					{
						new iLaser = GetTracerIndex(attacker);
						iColors = GetTracerColor(attacker);
						new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
						new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

						for(new i = 1; i <= MaxClients; i++)
						{
							if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] == g_iTeam[attacker]))
							{
								if(i == attacker && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
									continue;

								TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
								TE_SendToClient(i);
							}
						}
					}
					case VISIBLE_OPPOSING:
					{
						new iLaser = GetTracerIndex(attacker);
						iColors = GetTracerColor(attacker);
						new Float:fLife = (g_fDefaultLife != -1.0 || g_fTracerLife[iLaser] <= 0) ? g_fDefaultLife : g_fTracerLife[iLaser];
						new Float:fWidth = (g_fDefaultWidth != -1.0 || g_fTracerWidth[iLaser] <= 0) ? g_fDefaultWidth : g_fTracerWidth[iLaser];

						for(new i = 1; i <= MaxClients; i++)
						{
							if(g_iPlayerEnabled[i] && IsClientInGame(i) && (g_iTeam[i] != g_iTeam[attacker]))
							{
								if(i == attacker && (!g_iPlayerPersonal[i] || g_iPlayerPersonal[i] == 2))
									continue;

								TE_SetupBeamPoints(fDifference, fImpact, g_iTracerIndex[iLaser], 0, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColors, 0);
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
	decl String:sBuffer[128];
	new _iOptions, Handle:_hMenu = CreateMenu(MenuHandler_MenuTracers);
	Format(sBuffer, sizeof(sBuffer), "%T", "Title_Menu_Main", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);

	if(g_iClientEnabled != TRACERS_FORCED)
	{
		_iOptions++;
		if(g_iPlayerEnabled[client])
		{
			Format(sBuffer, sizeof(sBuffer), "%T", "Main_Option_Disable", client);
			AddMenuItem(_hMenu, "1", sBuffer);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "%T", "Main_Option_Enable", client);
			AddMenuItem(_hMenu, "2", sBuffer);
		}
	}
	
	if(g_iVisibility == VISIBLE_CLIENT)
	{
		_iOptions++;
		Format(sBuffer, sizeof(sBuffer), "%T", "Main_Option_Visibility", client);
		AddMenuItem(_hMenu, "3", sBuffer);
	}
	
	if((g_bAccess[client] && g_iForceTeam != 2 && g_iForceRandom != 2) || (!g_iAccessFlag && g_iForceRandom == 0 && g_iForceTeam == 0))
	{
		_iOptions++;
		Format(sBuffer, sizeof(sBuffer), "%T", "Main_Option_Personal", client);
		AddMenuItem(_hMenu, "4", sBuffer);
	}
	
	if(g_iPlayerPersonal[client] <= 1)
	{
		_iOptions++;
		if(g_iPlayerPersonal[client])
		{
			Format(sBuffer, sizeof(sBuffer), "%T", "Main_Option_Personal_Disable", client);
			AddMenuItem(_hMenu, "5", sBuffer);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "%T", "Main_Option_Personal_Enable", client);
			AddMenuItem(_hMenu, "6", sBuffer);
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
			decl String:sTemp[4];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));
			switch(StringToInt(sTemp))
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
					g_iPlayerPersonal[param1] = false;
					
					IntToString(g_iPlayerPersonal[param1], sTemp, sizeof(sTemp));
					SetClientCookie(param1, g_cPersonal, sTemp);

					CPrintToChat(param1, "%s%t", g_sPrefixChat, "Personal_Phrase_Hide");
					Menu_Tracers(param1);
				}
				case 6:
				{
					g_iPlayerPersonal[param1] = true;
					
					IntToString(g_iPlayerPersonal[param1], sTemp, sizeof(sTemp));
					SetClientCookie(param1, g_cPersonal, sTemp);

					CPrintToChat(param1, "%s%t", g_sPrefixChat, "Personal_Phrase_Show");
					Menu_Tracers(param1);
				}
			}
		}
	}
}

Menu_Visibility(client)
{
	decl String:sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuVisibility);
	Format(sBuffer, sizeof(sBuffer), "%T", "Title_Menu_Visibility", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);
	
	Format(sBuffer, sizeof(sBuffer), "%s%T", (g_iPlayerVisibility[client] == VISIBLE_EVERYONE) ? g_sPrefixSelect : g_sPrefixEmpty, "Visibility_Option_Everyone", client);
	AddMenuItem(_hMenu, "0", sBuffer);

	Format(sBuffer, sizeof(sBuffer), "%s%T", (g_iPlayerVisibility[client] == VISIBLE_SPECTATE) ? g_sPrefixSelect : g_sPrefixEmpty, "Visibility_Option_Spectate", client);
	AddMenuItem(_hMenu, "1", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%s%T", (g_iPlayerVisibility[client] == VISIBLE_FRIENDLY) ? g_sPrefixSelect : g_sPrefixEmpty, "Visibility_Option_Friendly", client);
	AddMenuItem(_hMenu, "2", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%s%T", (g_iPlayerVisibility[client] == VISIBLE_OPPOSING) ? g_sPrefixSelect : g_sPrefixEmpty, "Visibility_Option_Opposing", client);
	AddMenuItem(_hMenu, "3", sBuffer);
	
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
	decl String:sTemp[4], String:sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuPersonal);
	Format(sBuffer, sizeof(sBuffer), "%T", "Title_Menu_Personal", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 1; i <= g_iNumTracers; i++)
	{
		if(!g_bTracerEnabled[i])
			continue;

		if(!g_iTracerFlag[i] || CheckCommandAccess(client, "Tracers_Access_Material", g_iTracerFlag[i]))
		{
			IntToString(i, sTemp, sizeof(sTemp));
			Format(sBuffer, sizeof(sBuffer), "%s%s", (g_iPlayerTracer[client] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sTracerName[i]);
			AddMenuItem(_hMenu, sTemp, sBuffer);
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
	decl iArray[4];
	for(new i = 0; i <= 3; i++)
		iArray[i] = GetRandomInt(0, 255);

	return iArray;
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

LoadCookies(client)
{
	decl String:_sCookie[8] = "";
	GetClientCookie(client, g_cStatus, _sCookie, sizeof(_sCookie));

	if(StrEqual(_sCookie, "", false))
	{
		g_iPlayerEnabled[client] = g_iClientEnabled;
		g_iPlayerVisibility[client] = g_iClientVisibility;
		g_iPlayerTracer[client] = g_iClientTracer ? g_iClientTracer : GetRandomInt(1, g_iNumTracers);
		g_iPlayerPersonal[client] = g_iClientPersonal;
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

		if(g_iClientPersonal <= 1)
		{
			GetClientCookie(client, g_cPersonal, _sCookie, sizeof(_sCookie));
			g_iPlayerPersonal[client] = StringToInt(_sCookie) ? true : false;
		}
		else
			g_iPlayerPersonal[client] = g_iClientPersonal;
	}

	g_bLoaded[client] = true;
}


Define_Tracers()
{
	decl String:sPath[PLATFORM_MAX_PATH], String:sBuffer[64];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/css_tracer_effects.ini");

	g_iNumTracers = 0;
	new Handle:hKeyValues = CreateKeyValues("TracerEffects_Tracers");
	if(FileToKeyValues(hKeyValues, sPath) && KvGotoFirstSubKey(hKeyValues))
	{
		do
		{
			g_iNumTracers++;
			KvGetSectionName(hKeyValues, g_sTracerName[g_iNumTracers], 64);
			if(StrContains(g_sTracerName[g_iNumTracers], "~", false) == -1)
				g_bTracerEnabled[g_iNumTracers] = true;
			else
			{
				g_bTracerEnabled[g_iNumTracers] = false;

				if(StrContains(g_sTracerName[g_iNumTracers], "2", false) != -1)
				{
					g_iRedIndex = g_iNumTracers;
					KvGetString(hKeyValues, "Texture", g_sRedTexture, sizeof(g_sRedTexture));

					g_iRedColors[0] = KvGetNum(hKeyValues, "Red", 255);
					g_iRedColors[1] = KvGetNum(hKeyValues, "Green", 255);
					g_iRedColors[2] = KvGetNum(hKeyValues, "Blue", 255);
					g_iRedColors[3] = KvGetNum(hKeyValues, "Alpha", 255);
				}
				else if(StrContains(g_sTracerName[g_iNumTracers], "3", false) != -1)
				{
					g_iBlueIndex = g_iNumTracers;
					KvGetString(hKeyValues, "Texture", g_sBlueTexture, sizeof(g_sBlueTexture));

					g_iBlueColors[0] = KvGetNum(hKeyValues, "Red", 255);
					g_iBlueColors[1] = KvGetNum(hKeyValues, "Green", 255);
					g_iBlueColors[2] = KvGetNum(hKeyValues, "Blue", 255);
					g_iBlueColors[3] = KvGetNum(hKeyValues, "Alpha", 255);
				}
			}

			KvGetString(hKeyValues, "Texture", g_sTracerTexture[g_iNumTracers], sizeof(g_sTracerTexture[]));
			KvGetString(hKeyValues, "Flag", sBuffer, sizeof(sBuffer));
			g_iTracerFlag[g_iNumTracers] = ReadFlagString(sBuffer);

			g_fTracerLife[g_iNumTracers] = KvGetFloat(hKeyValues, "Life", g_fDefaultLife != -1 ? g_fDefaultLife : 1.0);
			g_fTracerWidth[g_iNumTracers] = KvGetFloat(hKeyValues, "Width", g_fDefaultWidth != -1 ? g_fDefaultWidth : 3.0);
			g_bTracerTeam[g_iNumTracers] = KvGetNum(hKeyValues, "Team", 0) ? true : false;
			g_iTracerColor[g_iNumTracers][0] = KvGetNum(hKeyValues, "Red", 255);
			g_iTracerColor[g_iNumTracers][1] = KvGetNum(hKeyValues, "Green", 255);
			g_iTracerColor[g_iNumTracers][2] = KvGetNum(hKeyValues, "Blue", 255);
			g_iTracerColor[g_iNumTracers][3] = KvGetNum(hKeyValues, "Alpha", 255);
			Format(g_sTracerColors[g_iNumTracers], sizeof(g_sTracerColors[]), "%d %d %d %d", g_iTracerColor[g_iNumTracers][0], g_iTracerColor[g_iNumTracers][1], g_iTracerColor[g_iNumTracers][2], g_iTracerColor[g_iNumTracers][3]);
		}
		while (KvGotoNextKey(hKeyValues));
		CloseHandle(hKeyValues);
	}
	else
	{
		CloseHandle(hKeyValues);
		SetFailState("Tracer Effects: Could not locate \"configs/css_tracer_effects.ini\"");
	}
}

Prepare()
{
	decl String:sBuffer[256];
	for(new i = 1; i <= g_iNumTracers; i++)
	{
		strcopy(sBuffer, sizeof(sBuffer), g_sTracerTexture[i]);
		AddFileToDownloadsTable(sBuffer);

		g_iTracerIndex[i] = PrecacheModel(g_sTracerTexture[i]);
		ReplaceString(sBuffer, sizeof(sBuffer), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(sBuffer);
	}
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = bool:StringToInt(newvalue);
	else if(cvar == g_hAdvert)
		g_fAdvert = StringToFloat(newvalue);
	else if(cvar == g_hGlobalVisibility)
		g_iVisibility = StringToInt(newvalue);
	#if defined _dhooks_included
	else if(cvar == g_hKnife)
		g_iKnife = StringToInt(newvalue);
	#endif
	else if(cvar == g_hChatCommands)
		g_iNumCommands = ExplodeString(newvalue, ", ", g_sChatCommands, sizeof(g_sChatCommands), sizeof(g_sChatCommands[]));
	else if(cvar == g_hClientEnabled)
		g_iClientEnabled = StringToInt(newvalue);
	else if(cvar == g_hClientVisibility)
		g_iClientVisibility = StringToInt(newvalue);
	else if(cvar == g_hClientTracer)
		g_iClientTracer = StringToInt(newvalue);
	else if(cvar == g_hClientPersonal)
		g_iClientPersonal = StringToInt(newvalue);
	else if(cvar == g_hForceTeam)
		g_iForceTeam = StringToInt(newvalue);
	else if(cvar == g_hForceRandom)
		g_iForceRandom = StringToInt(newvalue);
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