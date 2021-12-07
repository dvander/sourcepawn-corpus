#define PLUGIN_VERSION 		"1.6"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Block Stumble From Tanks
*	Author	:	SilverShot
*	Descrp	:	Prevents Tank punches and rocks from stumbling survivors.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=318713
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.6 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.5 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.4 (22-Sep-2019)
	- Fixed server crashing.
	- Fixed the round ending when the last standing survivor gets hit.

1.3 (16-Sep-2019)
	- Fixed not accounting for temporary health. Thanks to "xZk" for reporting.

1.2 (16-Sep-2019)
	- Fixed reviving when they should be incapped and instant death on hit.

1.1 (16-Sep-2019)
	- Fixed affecting incapacitated players - Thanks to "xZk" for scripting.

1.0 (16-Sep-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarDeathCheck, g_hCvarDecayRate, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2, g_bDeathCheck;
bool g_bIncapped[MAXPLAYERS+1];



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
	// CVARS
	g_hCvarAllow = CreateConVar(	"l4d_block_stumble_allow",			"1",					"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(	"l4d_block_stumble_modes",			"",						"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d_block_stumble_modes_off",		"",						"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(	"l4d_block_stumble_modes_tog",		"0",					"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(					"l4d_block_stumble_version",		PLUGIN_VERSION,			"Block Stumble From Tanks plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d_block_stumble");

	g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
	g_hCvarDeathCheck = FindConVar("director_no_death_check");
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
public void OnClientPutInServer(int client)
{
	if( g_bCvarAllow )
	{
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	}
}

void HookClients()
{
	HookEvent("player_incapacitated", EventIncap);

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
}

void UnhookClients()
{
	UnhookEvent("player_incapacitated", EventIncap);

	for( int i = 1; i <= MaxClients; i++ )
	{
		SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	}
}

public Action EventIncap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bIncapped[client] = true;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( damagetype == DMG_CLUB && victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 3 )
	{
		int class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
		if( class == (g_bLeft4Dead2 ? 8 : 5) && GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 0 )
		{
			g_bIncapped[victim] = false;

			// Temp Health
			float fHealth = GetEntPropFloat(victim, Prop_Send, "m_healthBuffer");
			fHealth -= (GetGameTime() - GetEntPropFloat(victim, Prop_Send, "m_healthBufferTime")) * g_hCvarDecayRate.FloatValue;
			if( fHealth < 0.0 )
				fHealth = 0.0;

			// Main Health
			int health = GetClientHealth(victim);
			if( health + fHealth - damage > 0.0 )
			{
				if( g_bDeathCheck == false )
				{
					g_bDeathCheck = true;
					RequestFrame(OnDeathCheck, g_hCvarDeathCheck.IntValue);
					g_hCvarDeathCheck.IntValue = 1;
				}

				SetEntProp(victim, Prop_Send, "m_isIncapacitated", 1);
				ChangeEdictState(victim,  FindSendPropInfo("player", "m_isIncapacitated"));
				SDKHook(victim, SDKHook_PostThink, OnThink);
			}
		}
	}
	return Plugin_Continue;
}

public void OnDeathCheck(int value)
{
	g_bDeathCheck = false;
	g_hCvarDeathCheck.IntValue = value;
}

public void OnThink(int victim)
{
	SDKUnhook(victim, SDKHook_PostThink, OnThink);

	if( g_bIncapped[victim] == false )
	{
		SetEntProp(victim, Prop_Send, "m_isIncapacitated", 0);
		ChangeEdictState(victim, FindSendPropInfo("player", "m_isIncapacitated"));
	}
}