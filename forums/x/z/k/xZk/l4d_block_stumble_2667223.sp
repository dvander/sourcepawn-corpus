#define PLUGIN_VERSION 		"1.0.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Block Stumble From Tanks
*	Author	:	SilverShot
*	Descrp	:	Prevents Tank punches and rocks from stumbling survivors.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=318713
*	Plugins	:	http://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (16-Sep-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY

ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
bool g_bCvarAllow, g_bLeft4Dead2;



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Block Stumble From Tanks",
	author = "SilverShot",
	description = "Prevents Tank punches and rocks from stumbling survivors.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=318713"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead) g_bLeft4Dead2 = false;
	else if (test == Engine_Left4Dead2) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	// CVARS
	g_hCvarAllow = CreateConVar(	"l4d_block_stumble_allow",			"1",					"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(	"l4d_block_stumble_modes",			"",						"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d_block_stumble_modes_off",		"",						"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(	"l4d_block_stumble_modes_tog",		"0",					"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(					"l4d_block_stumble_version",		PLUGIN_VERSION,			"Block Stumble From Tanks plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d_block_stumble");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);

}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		HookClients();
		g_bCvarAllow = true;
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		UnhookClients();
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
//					EVENTS
// ====================================================================================================
public void OnClientPutInServer(int client)
{
	if( g_bCvarAllow )
	{
		SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamage);
	}
}

void HookClients()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamage);
		}
	}
}

void UnhookClients()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		SDKUnhook(i, SDKHook_OnTakeDamagePost, OnTakeDamage);
	}
}

public void OnTakeDamage(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if( damagetype == DMG_CLUB && victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 3 )
	{
		int class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
		if( class == (g_bLeft4Dead2 ? 8 : 5) && GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 0)
		{
			SDKHook(victim, SDKHook_PostThink, OnThink);
			SetEntProp(victim, Prop_Send, "m_isIncapacitated", 1);
		}
		
	}
	return;
}

public void OnThink(int victim)
{
	SetEntProp(victim, Prop_Send, "m_isIncapacitated", 0);
	SDKUnhook(victim, SDKHook_PostThink, OnThink);
}