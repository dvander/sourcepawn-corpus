#define PLUGIN_VERSION 		"1.2"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Witch - Bots Trigger
*	Author	:	SilverShot
*	Descrp	:	Makes bots startle the Wandering Witch or block bots startling any Witch when shooting her.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=319939
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.

1.1 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.0 (27-Nov-2019)
	- Initial release.

======================================================================================*/

// sm_propent 0 m_iTimeOfDay 2; z_spawn witch

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarType;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;
int g_iCvarType;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Witch - Bots Trigger",
	author = "SilverShot",
	description = "Makes bots startle the Wandering Witch or block bots startling any Witch when shooting her.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=319939"
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
	g_hCvarAllow = CreateConVar(	"l4d_witch_trigger_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(	"l4d_witch_trigger_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d_witch_trigger_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(	"l4d_witch_trigger_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarType =	 CreateConVar(	"l4d_witch_trigger_type",			g_bLeft4Dead2 ? "1" : "0",			"0=Prevent bots from startling any Witches when shot. 1=Startle all Witches when bots shoot them.", CVAR_FLAGS );
	CreateConVar(					"l4d_witch_trigger_version",		PLUGIN_VERSION,	"Witch - Bots Trigger plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d_witch_trigger");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);
	GetCvars();
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
	g_iCvarType = g_hCvarType.IntValue;
	if( !g_bLeft4Dead2 && g_iCvarType ) LogError("This plugin with the cvar \"l4d_witch_trigger_type\" value of \"1\" is not required in L4D1. Only use \"0\" to block startling Witches.");
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		HookEntities(true);
		g_bCvarAllow = true;
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		HookEntities(false);
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
//					HOOK
// ====================================================================================================
void HookEntities(int hook)
{
	static bool hooked;

	if( !hooked && hook )
	{
		hooked = true;

		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE )
		{
			SDKHook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
	else if( hooked && !hook )
	{
		hooked = false;

		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE )
		{
			SDKUnhook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void OnEntityCreated(int entity, const char[] classname)
{
	if( g_bCvarAllow && strcmp(classname, "witch") == 0 )
	{
		SDKHook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	}
}

public Action OnTakeDamage(int witch, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( attacker > 0 && attacker <= MaxClients )
	{
		if( g_iCvarType )
		{
			if( GetEntPropFloat(witch, Prop_Send, "m_rage") >= 1.0 )
			{
				SDKUnhook(witch, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			}

			if( damagetype & DMG_BURN == 0 && IsFakeClient(attacker) )
			{
				SDKUnhook(witch, SDKHook_OnTakeDamageAlive, OnTakeDamage);
				SDKHook(witch, SDKHook_ThinkPost, PostThink);
				damagetype = DMG_BURN;
				return Plugin_Changed;
			}
		}
		else
		{
			if( GetEntPropFloat(witch, Prop_Send, "m_rage") >= 1.0 )
			{
				SDKUnhook(witch, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			}
			else if( IsFakeClient(attacker) )
			{
				attacker = 0;
				inflictor = 0;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

public void PostThink(int witch)
{
	SDKUnhook(witch, SDKHook_ThinkPost, PostThink);

	ExtinguishEntity(witch);

	int flame = GetEntPropEnt(witch, Prop_Send, "m_hEffectEntity");
	if( flame != -1 )
	{
		AcceptEntityInput(flame, "Kill");
	}
}