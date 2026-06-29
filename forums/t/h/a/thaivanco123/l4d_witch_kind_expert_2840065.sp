/*
*	Kind Expert Witch
*	Copyright (C) 2025 Dragokas
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



#define PLUGIN_VERSION 		"1.3"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Kind Expert Witch
*	Author	:	Dragokas, JustMe
*	Descrp	:	Makes the witch kinder on expert difficulty by adjusting damage, health, speed and behavior.
*	Link	:	https://github.com/dragokas/
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Dragokas

========================================================================================
	Change Log:

1.3 (04-Oct-2025)
	- Fix.
	- Added ConVar "l4d_kind_expert_witch_expert_only" to control if the plugin applies only on Expert or all difficulty.

1.2 (20-Apr-2023)
	- Added even more ConVars.

1.1
	- Added more ConVars.

1.0 (20-Sep-2020)
	- Initial release.

========================================================================================
	Credits:

	- samuelviveiros a.k.a Dartz8901 - for Pet Witch, partially used in this plugin.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define SAFE_RAGE			0.8
#define WITCH_SEQUENCE_RUN_RETREAT 6


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
ConVar g_hCvarDamageToSurvivor, g_hCvarDamageToWitch, g_hCvarHealthMultiplier, g_hCvarSpeedMultiplier, g_hCvarPreventAttackFirst;
ConVar g_hCvarDifficulty, g_hCvarWitchSpeed, g_hCvarWitchHealth;
ConVar g_hCvarExpertOnly;

int g_iWitchSpeedInit, g_iWitchHealthInit;
bool g_bCvarAllow, g_bMapStarted, g_bLateLoad;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Kind Expert Witch",
	author = "Dragokas, JustMe",
	description = "Makes the witch kinder on expert difficulty by adjusting damage, health, speed and behavior.",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead || test == Engine_Left4Dead2 )
	{
		g_bLateLoad = late;
		return APLRes_Success;
	}

	strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
	return APLRes_SilentFailure;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =					CreateConVar(	"l4d_kind_expert_witch_allow",				"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =					CreateConVar(	"l4d_kind_expert_witch_modes",				"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =				CreateConVar(	"l4d_kind_expert_witch_modes_off",			"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =				CreateConVar(	"l4d_kind_expert_witch_modes_tog",			"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarDamageToSurvivor =		CreateConVar(	"l4d_kind_expert_witch_damage_to_survivor",	"5",				"Maximum damage the witch can deal to survivor (on expert difficulty).", CVAR_FLAGS );
	g_hCvarDamageToWitch =			CreateConVar(	"l4d_kind_expert_witch_damage_to_witch",	"10",				"Maximum damage survivor can deal to the witch (for each bullet) (on expert difficulty).", CVAR_FLAGS );
	g_hCvarHealthMultiplier =		CreateConVar(	"l4d_kind_expert_witch_health_multiplier",	"3.0",				"Health of the witch multiplied with this number (on expert difficulty).", CVAR_FLAGS );
	g_hCvarSpeedMultiplier =		CreateConVar(	"l4d_kind_expert_witch_speed_multiplier",	"10.0",				"Speed of the witch multiplied with this number (on expert difficulty).", CVAR_FLAGS );
	g_hCvarPreventAttackFirst =		CreateConVar(	"l4d_kind_expert_witch_prevent_attack_first",	"1",			"Prevent witch to attack you first? (0 - No, 1 - Yes).", CVAR_FLAGS );
	g_hCvarExpertOnly =				CreateConVar(	"l4d_kind_expert_witch_expert_only",		"0",				"If 1, the plugin only affects witches on Expert difficulty. 0 = Affects on all difficulty.", CVAR_FLAGS );
	CreateConVar(									"l4d_kind_expert_witch_version",			PLUGIN_VERSION,		"Kind Expert Witch plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,							"l4d_kind_expert_witch");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarDamageToSurvivor.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDamageToWitch.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthMultiplier.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpeedMultiplier.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPreventAttackFirst.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarExpertOnly.AddChangeHook(ConVarChanged_ExpertOnly);

	g_hCvarDifficulty = FindConVar("z_difficulty");
	g_hCvarWitchSpeed = FindConVar("z_witch_speed");
	g_hCvarWitchHealth = FindConVar("z_witch_health");

	g_iWitchSpeedInit = g_hCvarWitchSpeed.IntValue;
	g_iWitchHealthInit = g_hCvarWitchHealth.IntValue;

	g_hCvarDifficulty.AddChangeHook(ConVarChanged_Difficulty);

	if( g_bLateLoad )
	{
		RefreshDifficulty();
		HookDamageAll();
		HookWitchesAll();
	}

	IsAllowed();
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

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	if( ShouldApply() )
	{
		if( convar == g_hCvarSpeedMultiplier )
		{
			WitchSpeed(true);
		}
		else if( convar == g_hCvarPreventAttackFirst )
		{
			bool bEnable = g_hCvarPreventAttackFirst.BoolValue;
			if( bEnable )
			{
				HookWitchesThinkAll();
			}
			else
			{
				UnhookWitchesThinkAll();
			}
		}
	}
}

void ConVarChanged_ExpertOnly(Handle convar, const char[] oldValue, const char[] newValue)
{
	RefreshDifficulty();
}

void ConVarChanged_Difficulty(Handle convar, const char[] oldValue, const char[] newValue)
{
	RefreshDifficulty();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		HookEvent("witch_spawn", Event_WitchSpawn);
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

		RefreshDifficulty();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookEvent("witch_spawn", Event_WitchSpawn);
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

		ResetHooks();
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

void OnGamemode(const char[] output, int caller, int activator, float delay)
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
//					EVENTS / HOOKS
// ====================================================================================================
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetHooks();
	RefreshDifficulty();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetHooks();
}

public void OnClientPutInServer(int client)
{
	if( g_bCvarAllow && ShouldApply() )
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( !g_bCvarAllow || !ShouldApply() ) return;

	int witch = event.GetInt("witchid");
	
	if( g_hCvarPreventAttackFirst.BoolValue )
	{
		SDKHook(witch, SDKHook_ThinkPost, PetWitch_ThinkHandler);
	}
	SDKHook(witch, SDKHook_OnTakeDamage, OnTakeDamageWitch);
	CreateTimer(0.33, Timer_SetWitchHealth, EntIndexToEntRef(witch), TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_SetWitchHealth(Handle timer, any ref)
{
	int witch = EntRefToEntIndex(ref);
	if( witch != INVALID_ENT_REFERENCE && IsWitchEntity(witch) )
	{
		SetEntProp(witch, Prop_Data, "m_iHealth", RoundToCeil(g_iWitchHealthInit * g_hCvarHealthMultiplier.FloatValue));
		SetEntProp(witch, Prop_Data, "m_iMaxHealth", RoundToCeil(g_iWitchHealthInit * g_hCvarHealthMultiplier.FloatValue));
	}
	return Plugin_Stop;
}

void PetWitch_ThinkHandler(int witch)
{
	if ( GetEntPropFloat(witch, Prop_Send, "m_rage") > SAFE_RAGE )
	{
		SetEntPropFloat(witch, Prop_Send, "m_rage", SAFE_RAGE);
	}
	if ( GetEntProp(witch, Prop_Send, "m_nSequence") == WITCH_SEQUENCE_RUN_RETREAT )
	{
		SDKUnhook(witch, SDKHook_ThinkPost, PetWitch_ThinkHandler);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if( g_bCvarAllow && ShouldApply() && victim && attacker && victim <= MaxClients && victim > 0 && GetClientTeam(victim) == 2 && IsWitchEntity(attacker) )
	{
		damage = g_hCvarDamageToSurvivor.FloatValue;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnTakeDamageWitch(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if( g_bCvarAllow && ShouldApply() && victim && attacker && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 2 )
	{
		damage = g_hCvarDamageToWitch.FloatValue;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

void RefreshDifficulty()
{
	static char sDif[32];
	g_hCvarDifficulty.GetString(sDif, sizeof(sDif));

	bool bExpert = StrEqual(sDif, "Impossible", false);
	bool bApply = g_hCvarExpertOnly.BoolValue ? bExpert : true;

	if( g_bCvarAllow )
	{
		if( bApply )
		{
			HookDamageAll();
			HookWitchesAll();
			WitchSpeed(true);
		}
		else
		{
			UnhookDamageAll();
			UnhookWitchesAll();
			WitchSpeed(false);
		}
	}
}

bool IsExpert()
{
	static char sDif[32];
	g_hCvarDifficulty.GetString(sDif, sizeof(sDif));
	return StrEqual(sDif, "Impossible", false);
}

bool ShouldApply()
{
	return g_hCvarExpertOnly.BoolValue ? IsExpert() : true;
}

void WitchSpeed(bool enable)
{
	if( enable )
	{
		SetCvarSilent(g_hCvarWitchSpeed, float(g_iWitchSpeedInit) * g_hCvarSpeedMultiplier.FloatValue);
	}
	else
	{
		SetCvarSilent(g_hCvarWitchSpeed, float(g_iWitchSpeedInit));
	}
}

stock void SetCvarSilent(ConVar cvar, float value)
{
	int flags = cvar.Flags;
	cvar.Flags &= ~FCVAR_NOTIFY;
	cvar.SetFloat(value);
	cvar.Flags = flags;
}

void HookDamageAll()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

void UnhookDamageAll()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

void HookWitchesAll()
{
	int ent = -1;
	while( (ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE )
	{
		if( g_hCvarPreventAttackFirst.BoolValue )
		{
			SDKHook(ent, SDKHook_ThinkPost, PetWitch_ThinkHandler);
		}
		SDKHook(ent, SDKHook_OnTakeDamage, OnTakeDamageWitch);
	}
}

void UnhookWitchesAll()
{
	int ent = -1;
	while( (ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE )
	{
		SDKUnhook(ent, SDKHook_ThinkPost, PetWitch_ThinkHandler);
		SDKUnhook(ent, SDKHook_OnTakeDamage, OnTakeDamageWitch);
	}
}

void HookWitchesThinkAll()
{
	int ent = -1;
	while( (ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE )
	{
		SDKHook(ent, SDKHook_ThinkPost, PetWitch_ThinkHandler);
	}
}

void UnhookWitchesThinkAll()
{
	int ent = -1;
	while( (ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE )
	{
		SDKUnhook(ent, SDKHook_ThinkPost, PetWitch_ThinkHandler);
	}
}

void ResetHooks()
{
	UnhookDamageAll();
	UnhookWitchesAll();
}

stock bool IsWitchEntity(int iEntity)
{
	if( iEntity && iEntity != -1 && IsValidEntity(iEntity) )
	{
		static char sClassname[32];
		GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
		return strcmp(sClassname, "witch") == 0;
	}
	return false;
}