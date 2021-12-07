#define PLUGIN_VERSION 		"1.1"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Special Infected Ignite Explosives
*	Author	:	SilverShot
*	Descrp	:	Allows Special Infected to melee/scratch explosives to ignite them.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=324987
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 (04-Jun-2020)
	- Added cvar "l4d_special_explosives_fire" to control if Special Infected need to be on fire.
	- Added cvar "l4d_special_explosives_types" to control which Special Infected can ignite.
	- Fixed errors from non-networked entities spawning.
	- Fixed possibly including other models.

1.0 (04-Jun-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY

#define MODEL_CRATE			"models/props_junk/explosive_box001.mdl"
#define MODEL_OXYGEN		"models/props_equipment/oxygentank01.mdl"
#define MODEL_PROPANE		"models/props_junk/propanecanister001a.mdl"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarExplode, g_hCvarFire, g_hCvarTypes;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;
int g_iClassTank, g_iCvarExplode, g_iCvarFire, g_iCvarTypes;
bool g_bHooked[2048];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Special Infected Ignite Explosives",
	author = "SilverShot",
	description = "Allows Special Infected to melee/scratch explosives to ignite them.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=324987"
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
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =		CreateConVar(	"l4d_special_explosives_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_special_explosives_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_special_explosives_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_special_explosives_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarExplode =	CreateConVar(	"l4d_special_explosives_explosives",	"15",				"Allow special infected to scratch and ignite: 1=GasCans, 2=Firework Crates, 4=Oxygen Tank, 8=Propane Tank, 15=All. Add numbers together.", CVAR_FLAGS );
	g_hCvarFire =		CreateConVar(	"l4d_special_explosives_fire",			"0",				"0=Any time. 1=Special Infected must be on fire to ignite explosives.", CVAR_FLAGS );
	g_hCvarTypes =		CreateConVar(	"l4d_special_explosives_types",			"0",				"Allow these special infected to use: 0=All, 1=Smoker, 2=Boomer, 4=Hunter, 8=Spitter, 16=Jockey, 32=Charger, 64=Tank. Add numbers together.", CVAR_FLAGS );
	CreateConVar(						"l4d_special_explosives_version",		PLUGIN_VERSION,		"Special Infected Ignite Explosives plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_special_explosives");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarExplode.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFire.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTypes.AddChangeHook(ConVarChanged_Cvars);

	g_iClassTank = g_bLeft4Dead2 ? 7 : 4;
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
	g_iCvarExplode = g_hCvarExplode.IntValue;
	g_iCvarFire = g_hCvarFire.IntValue;
	g_iCvarTypes = g_hCvarTypes.IntValue;
	ScanExplosives();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		ScanExplosives();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
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
void ScanExplosives()
{
	for( int i = MaxClients + 1; i < 2048; i++ )
	{
		if( g_bHooked[i] )
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			g_bHooked[i] = false;
		}
	}

	int entity = -1;
	if( g_iCvarExplode & 1 )
	{
		while( (entity = FindEntityByClassname(entity, "weapon_gascan")) != INVALID_ENT_REFERENCE )
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			g_bHooked[entity] = true;
		}
	}

	if( g_iCvarExplode > 1 )
	{
		entity = -1;
		char sTemp[45];
		while( (entity = FindEntityByClassname(entity, "prop_physics")) != INVALID_ENT_REFERENCE )
		{
			GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

			if( g_iCvarExplode & 2 && strcmp(sTemp, MODEL_CRATE) == 0 ) // Firework crate
			{
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
				g_bHooked[entity] = true;
			}
			else if( g_iCvarExplode & 4 && strcmp(sTemp, MODEL_OXYGEN) == 0 ) // Oxygen
			{
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
				g_bHooked[entity] = true;
			}
			else if( g_iCvarExplode & 8 && strcmp(sTemp, MODEL_PROPANE) == 0 ) // Propane
			{
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
				g_bHooked[entity] = true;
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if( entity <= MaxClients ) return;

	g_bHooked[entity] = false;

	if( g_iCvarExplode & 1 && strcmp(classname, "weapon_gascan") == 0 )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		g_bHooked[entity] = true;
	}
	else if( g_iCvarExplode > 1 && strcmp(classname, "prop_physics") == 0 )
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawn);
	}
}

public void OnSpawn(int entity)
{
	static char sTemp[45];
	GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

	if( g_iCvarExplode & 2 && strcmp(sTemp, MODEL_CRATE) == 0 ) // Firework crate
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		g_bHooked[entity] = true;
	}
	else if( g_iCvarExplode & 4 && strcmp(sTemp, MODEL_OXYGEN) == 0 ) // Oxygen
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		g_bHooked[entity] = true;
	}
	else if( g_iCvarExplode & 8 && strcmp(sTemp, MODEL_PROPANE) == 0 ) // Propane
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		g_bHooked[entity] = true;
	}
}

public Action OnTakeDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( damagetype == DMG_CLUB && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 3 )
	{
		if( g_iCvarTypes )
		{
			int class = GetEntProp(attacker, Prop_Send, "m_zombieClass") - 1;
			if( class == g_iClassTank ) class = 6;
			if( g_iCvarTypes & (1 << class) == 0 ) return;
		}

		if( g_iCvarFire && GetEntPropEnt(attacker, Prop_Send, "m_hEffectEntity") == -1 ) return;

		AcceptEntityInput(entity, "Ignite");
		SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}