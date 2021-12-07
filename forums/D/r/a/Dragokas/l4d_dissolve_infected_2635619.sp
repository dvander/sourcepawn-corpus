#define PLUGIN_VERSION 		"1.5.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Dissolve Infected
*	Author	:	SilverShot
*	Descrp	:	Dissolves the witch, common or special infected when killed
*	Link	:	https://forums.alliedmods.net/showthread.php?t=306789
*	Plugins	:	http://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.5.1 (20-Jan-2019) by Dragokas
	- Kill "immortal" entities if they didn't dissolve for some case.
	
1.5 (05-Sep-2018)
	- Added cvars "l4d_dissolve_time_min" and  "l4d_dissolve_time_max" to randomly select dissolve time.
	- Fixed fading ragdolls when the dissolve effects have reached their max active limit of 32.
	- Fixed 1 shot Witch kill not fading.

1.4 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_dissolve_modes_tog" now supports L4D1.

1.3 (15-Apr-2018)
	- Fixed crash.

1.2 (15-Apr-2018)
	- Potential crash fix.
	- Optimized the plugin for cvars set at 100 chance and 511 infected.

1.1.1 (14-Apr-2018)
	- Another stupid bug. Update required.

1.1 (14-Apr-2018)
	- Better version.
	- Various fixes.

1.0 (13-Apr-2018)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

//LMC
// #include <L4D2ModelChanger>
native int LMC_GetEntityOverlayModel(int iEntity); // remove this and uncomment out the l4d2modelchanger include to compile with the include
//LMC

#define CVAR_FLAGS			FCVAR_NOTIFY
#define SPRITE_GLOW			"sprites/blueglow1.vmt"
#define MAX_DISSOLVE		3
// L4D2 client? is missing "sprites/blueglow1.vmt" - used by env_entity_dissolver.
// Precache prevents server's error message, and clients can attempt to precache before round_start to avoid any possible stutter on the first attempt live in-game
// Error messages:
// Client:		Unable to load sprite material materials/sprites/blueglow1.vmt!
// Server:		Late precache of sprites/blueglow1.vmt

Handle sdkDissolveCreate;
ConVar g_hCvarAllow, g_hCvarChance, g_hCvarInfected, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarTime, g_hCvarTimeMin, g_hCvarTimeMax;
int g_iCvarChance, g_iCvarInfected, g_iPlayerSpawn, g_iRoundStart, g_iDissolvers[MAX_DISSOLVE]; // g_iRagdollFader
bool g_bCanDiss, g_bCvarAllow;
float g_fCvarTime, g_fCvarTimeMin, g_fCvarTimeMax;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Dissolve Infected",
	author = "SilverShot",
	description = "Dissolves the witch, common or special infected when killed.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=306789"
}

static bool bLMC_Available;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	MarkNativeAsOptional("LMC_GetEntityOverlayModel"); // LMC

	if( late ) g_bCanDiss = true;
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	bLMC_Available = LibraryExists("L4D2ModelChanger");
}

public void OnLibraryAdded(const char[] sName)
{
	if(StrEqual(sName, "L4D2ModelChanger"))
		bLMC_Available = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if(StrEqual(sName, "L4D2ModelChanger"))
		bLMC_Available = false;
}

public void OnPluginStart()
{
	// SDKCalls
	Handle hGameConf = LoadGameConfigFile("l4d_dissolve_infected");
	if( hGameConf == null )
		SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CEntityDissolve_Create") == false )
		SetFailState("Could not load the \"CEntityDissolve_Create\" gamedata signature.");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	sdkDissolveCreate = EndPrepSDKCall();
	if( sdkDissolveCreate == null )
		SetFailState("Could not prep the \"CEntityDissolve_Create\" function.");
	delete hGameConf;

	// CVars
	g_hCvarAllow = CreateConVar(		"l4d_dissolve_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(		"l4d_dissolve_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(		"l4d_dissolve_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(		"l4d_dissolve_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarChance = CreateConVar(		"l4d_dissolve_chance",			"100",			"Out of 100 the chance of dissolving a zombie when it dies. Note: stays activate for 0.5 seconds after triggering.", CVAR_FLAGS );
	g_hCvarInfected = CreateConVar(		"l4d_dissolve_infected",		"511",			"Dissolve these on death: 1=Common, 2=Witch, 4=Smoker, 8=Boomer, 16=Hunter, 32=Spitter, 64=Jockey, 128=Charger, 256=Tank, 511=All.", CVAR_FLAGS );
	g_hCvarTime = CreateConVar(			"l4d_dissolve_time",			"0.2",			"How long the particles stay for. Recommended values for best results from 0.0 (minimal particles) to 0.8.", CVAR_FLAGS );
	g_hCvarTimeMin = CreateConVar(		"l4d_dissolve_time_min",		"0.0",			"When time_min and time_max are not 0.0 the dissolve time will randomly be set to a value between these.", CVAR_FLAGS );
	g_hCvarTimeMax = CreateConVar(		"l4d_dissolve_time_max",		"0.0",			"When time_min and time_max are not 0.0 the dissolve time will randomly be set to a value between these.", CVAR_FLAGS );
	CreateConVar(						"l4d_dissolve_version",			PLUGIN_VERSION,	"Dissolve Infected plugin version.", FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_dissolve_infected");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarChance.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarInfected.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeMin.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeMax.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_dissolve", CmdDissolve, ADMFLAG_ROOT, "Kills and dissolves the entity being aimed at.");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	PrecacheModel(SPRITE_GLOW, true);
}



// ====================================================================================================
//					LOAD RAGDOLL FADER
// ====================================================================================================
void ResetPlugin()
{
	g_bCanDiss = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	// DeleteFader();
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(2.0, tmrLoad, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(2.0, tmrLoad, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action tmrLoad(Handle timer)
{
	LoadPlugin();
}

void LoadPlugin()
{
	g_bCanDiss = true;
	// CreateFader();
}

// Old method when chance 100% and dissolving all infected to always remove ragdoll. New method prevents ragdoll removal if dissolve visual effects have reached the max active limit.
//void CreateFader()
//{
//	if( !g_bCvarAllow || g_iCvarChance != 100 || g_iCvarInfected != 511 )
//		return;
//
//	if( g_iRagdollFader && EntRefToEntIndex(g_iRagdollFader) != INVALID_ENT_REFERENCE )
//		return;
//
//	g_iRagdollFader = CreateEntityByName("func_ragdoll_fader");
//	if( g_iRagdollFader != -1 )
//	{
//		DispatchSpawn(g_iRagdollFader);
//		SetEntPropVector(g_iRagdollFader, Prop_Send, "m_vecMaxs", view_as<float>({ 999999.0, 999999.0, 999999.0 }));
//		SetEntPropVector(g_iRagdollFader, Prop_Send, "m_vecMins", view_as<float>({ -999999.0, -999999.0, -999999.0 }));
//		SetEntProp(g_iRagdollFader, Prop_Send, "m_nSolidType", 2);
//		g_iRagdollFader = EntIndexToEntRef(g_iRagdollFader);
//	}
//}
//
//void DeleteFader()
//{
//	if( g_iRagdollFader && EntRefToEntIndex(g_iRagdollFader) != INVALID_ENT_REFERENCE )
//	{
//		AcceptEntityInput(g_iRagdollFader, "Kill");
//		g_iRagdollFader = 0;
//	}
//}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarChance = g_hCvarChance.IntValue;
	g_iCvarInfected = g_hCvarInfected.IntValue;
	g_fCvarTime = g_hCvarTime.FloatValue;
	g_fCvarTimeMin = g_hCvarTimeMin.FloatValue;
	g_fCvarTimeMax = g_hCvarTimeMax.FloatValue;

	// if( g_iCvarChance == 100 && g_iCvarInfected == 511 )
		// CreateFader();
	// else
		// DeleteFader();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		LoadPlugin();

		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("player_death",		Event_Death,		EventHookMode_Pre);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin();

		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("player_death",		Event_Death,		EventHookMode_Pre);
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
		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
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
//					COMMAND
// ====================================================================================================
public Action CmdDissolve(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Dissolve] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	int target = GetClientAimTarget(client, false);
	if( target != -1 )
	{
		if( target > 0 && target <= MaxClients && IsClientInGame(target) )
		{
			if( GetClientTeam(target) == 2 )
			{
				PrintToChat(client, "[Dissolve] Not on survivors.");
				return Plugin_Handled;
			}

			if( GetClientTeam(target) == 3 )
			{
				// int ragdoll = GetEntPropEnt(target, Prop_Send, "m_hRagdoll");
				// if( ragdoll > 0 && IsValidEntity(ragdoll) )
				// {
					// DissolveTarget(ragdoll);
					// return Plugin_Handled;
				// }

				int index = GetDissolveIndex();
				if( index != -1 )
				{
					int clone = AttachFakeRagdoll(target);
					if( clone > 0)
					{
						SetEntityRenderMode(clone, RENDER_NONE); // Hide and dissolve clone - method to show more particles
						DissolveTarget(index, clone, target);
						return Plugin_Handled;
					}
				}
			}
		}

		int index = GetDissolveIndex();
		if( index != -1 )
		{
			SetEntityRenderFx(target, RENDERFX_FADE_FAST);
			DissolveTarget(index, target);
		}
	}

	return Plugin_Handled;
}

int GetDissolveIndex()
{
	int index = -1;
	for( int i = 0; i < MAX_DISSOLVE; i++ )
	{
		if( g_iDissolvers[i] == 0 || EntRefToEntIndex(g_iDissolvers[i]) == INVALID_ENT_REFERENCE )
		{
			index = i;
			break;
		}
	}
	return index;
}



// ====================================================================================================
//					EVENT
// ====================================================================================================
public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	if( g_bCanDiss )
	{
		int target = event.GetInt("userid");
		if( !target )
		{
			target = event.GetInt("entityid");

			if( IsValidEntity(target) )
			{
				char sTemp[64];
				GetEdictClassname(target, sTemp, sizeof(sTemp));
				bool bChance;
				bool bWitch;

				if( g_iCvarInfected & (1<<0) && strcmp(sTemp, "infected") == 0 )
				{
					if( HasChance() )
						bChance = true;
				}
				else if( g_iCvarInfected & (1<<1) && strcmp(sTemp, "witch") == 0 )
				{
					bWitch = true;
					if( HasChance() )
						bChance = true;
				}

				if( bChance )
				{
					int index = GetDissolveIndex();
					if( index != -1 )
					{
						SDKHook(target, SDKHook_OnTakeDamage, OnCommonDamage);
					
						if( bWitch )
						{
							SetEntityRenderFx(target, RENDERFX_FADE_FAST);
							DissolveTarget(index, target, 0);
						} else {
							int iOverlayModel = -1;
							if( bLMC_Available )
								iOverlayModel = LMC_GetEntityOverlayModel(target);

							SetEntityRenderFx(target, RENDERFX_FADE_FAST);
							if( iOverlayModel < 1 )
								DissolveTarget(index, target);
							else
								DissolveTarget(index, iOverlayModel, target);
						}
					}
				}
			}
		} else {
			target = GetClientOfUserId(target);

			if( target > 0 && target <= MaxClients && IsClientInGame(target) && GetClientTeam(target) == 3 )
			{
				int class = GetEntProp(target, Prop_Send, "m_zombieClass") + 1;
				if( class == 9 ) class = 8;
				if( g_iCvarInfected & (1 << class) )
				{
					if( HasChance() )
					{
						int index = GetDissolveIndex();
						if( index != -1 )
						{
							// int ragdoll = GetEntPropEnt(target, Prop_Send, "m_hRagdoll");
							// if( ragdoll > 0 && IsValidEntity(ragdoll) )
							// {
								// DissolveTarget(ragdoll);
							// }

							int clone = AttachFakeRagdoll(target);
							if( clone > 0)
							{
								SetEntityRenderMode(clone, RENDER_NONE); // Hide and dissolve clone - method to show more particles
								DissolveTarget(index, clone, class == 3 ? 0 : target); // Exclude boomer to producer gibs
							}
						}
					}
				}
			}
		}
	}
}

public Action OnCommonDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	damage = 0.0;
	return Plugin_Handled;
}

bool HasChance()
{
	if( g_iCvarChance > 0 && GetRandomInt(1, 100) <= g_iCvarChance )
		return true;
	return false;
}

void DissolveTarget(int index, int target, int original = 0)
{
	// for( int i = 0; i <= 2048; i++ )
	// {
		// if( IsValidEdict(i) )
			// count++;
	// }

	if (original == 0) original = target;
	
	// CreateEntityByName "env_entity_dissolver" has broken particles, this way works 100% of the time
	float time = g_fCvarTime;
	if( g_fCvarTimeMin && g_fCvarTimeMax )
		time = GetRandomFloat(g_fCvarTimeMin, g_fCvarTimeMax);

	int dissolver = SDKCall(sdkDissolveCreate, target, "", GetGameTime() + time, 2, false);
	if( dissolver > MaxClients && IsValidEntity(dissolver) )
	{
		SetEntPropFloat(dissolver, Prop_Send, "m_flFadeOutStart", 0.0); // Fixes broken particles
		g_iDissolvers[index] = EntIndexToEntRef(dissolver);

		// if( g_iCvarChance != 100 || g_iCvarInfected != 511 )
		// {
		int fader = CreateEntityByName("func_ragdoll_fader");
		if( fader != -1 )
		{
			float vec[3];
			GetEntPropVector(original, Prop_Data, "m_vecOrigin", vec);
			TeleportEntity(fader, vec, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(fader);

			SetEntPropVector(fader, Prop_Send, "m_vecMaxs", view_as<float>({ 50.0, 50.0, 50.0 }));
			SetEntPropVector(fader, Prop_Send, "m_vecMins", view_as<float>({ -50.0, -50.0, -50.0 }));
			SetEntProp(fader, Prop_Send, "m_nSolidType", 2);

			SetVariantString("OnUser1 !self:Kill::0.1:1");
			AcceptEntityInput(fader, "AddOutput");
			AcceptEntityInput(fader, "FireUser1");
		}
		// }
		if (IsValidEntity(original)) {
			CreateTimer(time + 0.1, tmrKill, EntIndexToEntRef(original), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action tmrKill(Handle timer, int iEntRef)
{
	int target = EntRefToEntIndex(iEntRef);
	if (target != INVALID_ENT_REFERENCE && IsValidEntity(target)) {
		SDKUnhook(target, SDKHook_OnTakeDamage, OnCommonDamage);
		AcceptEntityInput(target, "Kill");
	}
}

int AttachFakeRagdoll(int target)
{
	int entity = CreateEntityByName("prop_dynamic_ornament");
	if( entity != -1 )
	{
		char sModel[64];
		GetEntPropString(target, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		// GetClientModel(target, sModel, sizeof(sModel));
		DispatchKeyValue(entity, "model", sModel);
		DispatchSpawn(entity);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetAttached", target);
	}

	return entity;
}