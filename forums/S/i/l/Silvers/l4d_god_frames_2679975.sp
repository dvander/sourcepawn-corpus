#define PLUGIN_VERSION 		"1.1.1 beta"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] God Frames Patch
*	Author	:	SilverShot
*	Descrp	:	Removes the IsInvulnerable function.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=320023
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1.2 beta (13-Jan-2020)
	- Added forward "OnTakeDamage_Invulnerable" to allow 3rd party plugins to modify invulnerable damage.

1.1.1 beta (13-Jan-2020)
	- Fixed not resetting delay timers OnMapEnd.

1.1 beta (13-Jan-2020)
	- Added a heap of new cvars to control damage for individual infected etc.
	- New gamedata required.

1.0 (01-Dec-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d_god_frames"

ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
ConVar g_hCvarDmg[12], g_hCvarDel[12];
float g_fCvarDmg[12], g_fCvarDel[12];
float g_fLastHit[MAXPLAYERS+1][12];
bool g_bCvarAllow;

Handle g_hDetour, g_hForwardInvul;
bool g_bInvulnerable[MAXPLAYERS+1];
bool g_bLateLoad, g_bLeft4Dead2;




// ====================================================================================================
//					PLUGIN
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] God Frames Patch",
	author = "SilverShot",
	description = "Removes the IsInvulnerable function.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=320023"
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

	RegPluginLibrary("l4d_god_frames");

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// GAMEDATA
	// ====================================================================================================
	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_hDetour = DHookCreateFromConf(hGameData, "CTerrorPlayer::IsInvulnerable");
	delete hGameData;

	if( !g_hDetour )
		SetFailState("Failed to find \"CTerrorPlayer::IsInvulnerable\" signature.");



	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow = CreateConVar(	"l4d_god_frames_allow",				"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarDmg[0] = CreateConVar(	"l4d_god_frames_damage_survivor",	"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by other Survivors.", CVAR_FLAGS );
	g_hCvarDmg[1] = CreateConVar(	"l4d_god_frames_damage_world",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by World.", CVAR_FLAGS );
	g_hCvarDmg[2] = CreateConVar(	"l4d_god_frames_damage_fire",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Fire.", CVAR_FLAGS );
	g_hCvarDmg[3] = CreateConVar(	"l4d_god_frames_damage_common",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Common Infected.", CVAR_FLAGS );
	g_hCvarDmg[4] = CreateConVar(	"l4d_god_frames_damage_witch",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Witch.", CVAR_FLAGS );
	g_hCvarDmg[5] = CreateConVar(	"l4d_god_frames_damage_tank",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Tank.", CVAR_FLAGS );
	g_hCvarDmg[6] = CreateConVar(	"l4d_god_frames_damage_smoker",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Smoker.", CVAR_FLAGS );
	g_hCvarDmg[7] = CreateConVar(	"l4d_god_frames_damage_boomer",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Boomer.", CVAR_FLAGS );
	g_hCvarDmg[8] = CreateConVar(	"l4d_god_frames_damage_hunter",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Hunter.", CVAR_FLAGS );

	g_hCvarDel[0] = CreateConVar(	"l4d_god_frames_delay_survivor",	"0.0",			"0.0=None. Minimum time before damage can be dealt again by other Survivors.", CVAR_FLAGS );
	g_hCvarDel[1] = CreateConVar(	"l4d_god_frames_delay_tank",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Tank.", CVAR_FLAGS );
	g_hCvarDel[2] = CreateConVar(	"l4d_god_frames_delay_world",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by World.", CVAR_FLAGS );
	g_hCvarDel[3] = CreateConVar(	"l4d_god_frames_delay_fire",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Fire.", CVAR_FLAGS );
	g_hCvarDel[4] = CreateConVar(	"l4d_god_frames_delay_common",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Common Infected.", CVAR_FLAGS );
	g_hCvarDel[5] = CreateConVar(	"l4d_god_frames_delay_witch",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Witch.", CVAR_FLAGS );
	g_hCvarDel[6] = CreateConVar(	"l4d_god_frames_delay_smoker",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Smoker.", CVAR_FLAGS );
	g_hCvarDel[7] = CreateConVar(	"l4d_god_frames_delay_boomer",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Boomer.", CVAR_FLAGS );
	g_hCvarDel[8] = CreateConVar(	"l4d_god_frames_delay_hunter",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Hunter.", CVAR_FLAGS );

	if( g_bLeft4Dead2 )
	{
	g_hCvarDmg[9] = CreateConVar(	"l4d_god_frames_damage_spitter",	"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Spitter.", CVAR_FLAGS );
	g_hCvarDmg[10] = CreateConVar(	"l4d_god_frames_damage_jockey",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Jockey.", CVAR_FLAGS );
	g_hCvarDmg[11] = CreateConVar(	"l4d_god_frames_damage_charger",	"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Charger.", CVAR_FLAGS );

	g_hCvarDel[9] = CreateConVar(	"l4d_god_frames_delay_spitter",		"0.1",			"0.0=None. Minimum time before damage can be dealt again by Spitter.", CVAR_FLAGS );
	g_hCvarDel[10] = CreateConVar(	"l4d_god_frames_delay_jockey",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Jockey.", CVAR_FLAGS );
	g_hCvarDel[11] = CreateConVar(	"l4d_god_frames_delay_charger",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Charger.", CVAR_FLAGS );
	}

	g_hCvarModes = CreateConVar(	"l4d_god_frames_modes",				"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d_god_frames_modes_off",			"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(	"l4d_god_frames_modes_tog",			"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(					"l4d_god_frames_version",			PLUGIN_VERSION,	"God Frames Patch plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d_god_frames");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);

	for( int i = 0; i < 12; i++ )
	{
		if( g_bLeft4Dead2 == false && i == 9 ) break;
		g_hCvarDmg[i].AddChangeHook(ConVarChanged_Cvars);
		g_hCvarDel[i].AddChangeHook(ConVarChanged_Cvars);
	}
}

public void OnPluginEnd()
{
	DetourAddress(false);
}

public void OnMapEnd()
{
	for( int i = 0; i <= MAXPLAYERS; i++ )
		for( int x = 0; x < 12; x++ )
			g_fLastHit[i][x] = 0.0;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	for( int i = 0; i < 12; i++ )
	{
		if( g_bLeft4Dead2 == false && i == 9 ) break;
		g_fCvarDmg[i] = g_hCvarDmg[i].FloatValue;
		g_fCvarDel[i] = g_hCvarDel[i].FloatValue;
	}
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		DetourAddress(true);
		g_bCvarAllow = true;

		if( g_bLateLoad ) // Only on lateload, or if re-enabled.
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					OnClientPutInServer(i);
				}
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		DetourAddress(false);
		g_bCvarAllow = false;
		g_bLateLoad = true; // So SDKHooks can re-hook damage if re-enabled.

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			}
		}
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
//					DAMAGE
// ====================================================================================================
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( g_bInvulnerable[client] )
	{
		// Forward
		Action aResult = Plugin_Continue;
		g_hForwardInvul = CreateGlobalForward("OnTakeDamage_Invulnerable", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
		Call_StartForward(g_hForwardInvul);
		Call_PushCell(client);
		Call_PushCell(attacker);
		Call_PushFloatRef(damage);
		Call_Finish(aResult);
		if( aResult != Plugin_Continue ) return aResult;



		// Main subroutine
		if( attacker >= 1 && attacker <= MaxClients )
		{
			if( GetClientTeam(attacker) == 3 )
			{
				// Special Infected
				int index = GetEntProp(attacker, Prop_Send, "m_zombieClass") + 5;
				if( index == 13 || index == 10 && g_bLeft4Dead2 == false ) index = 5; // Tank zombieClass == 8 (L4D2) or 5 (L4D1), and 5 in our indexing.

				if( IsClientInvul(client, index) ) // Time delay between god frame damage.
				{
					damage = 0.0;
					return Plugin_Handled;
				}

				damage *= g_fCvarDmg[index]; // Scaled damage
				return Plugin_Changed;
			} else { // Can be team 2 or 4 (support for some mods)
				// Survivors
				if( IsClientInvul(client, 0) ) // Time delay between god frame damage.
				{
					damage = 0.0;
					return Plugin_Handled;
				}

				damage *= g_fCvarDmg[0]; // Scaled damage
				return Plugin_Changed;
			}
		} else {
			char classname[4];
			GetEdictClassname(attacker, classname, sizeof classname);

			switch( classname[3] )
			{
				case 'l': // "worldspawn"
				{
					if( IsClientInvul(client, 1) ) // Time delay between god frame damage.
					{
						damage = 0.0;
						return Plugin_Handled;
					}

					damage *= g_fCvarDmg[1]; // Scaled damage
					return Plugin_Changed;
				}
				case 'i': // "entityflame"
				{
					if( IsClientInvul(client, 2) ) // Time delay between god frame damage.
					{
						damage = 0.0;
						return Plugin_Handled;
					}

					damage *= g_fCvarDmg[2]; // Scaled damage
					return Plugin_Changed;
				}
				case 'e': // "infected"
				{
					if( IsClientInvul(client, 3) ) // Time delay between god frame damage.
					{
						damage = 0.0;
						return Plugin_Handled;
					}

					damage *= g_fCvarDmg[3]; // Scaled damage
					return Plugin_Changed;
				}
				case 'c': // "witch"
				{
					if( IsClientInvul(client, 4) ) // Time delay between god frame damage.
					{
						damage = 0.0;
						return Plugin_Handled;
					}

					damage *= g_fCvarDmg[4]; // Scaled damage
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

bool IsClientInvul(int client, int index)
{
	if( g_fCvarDel[index] )
	{
		float time = GetGameTime();
		if( time < g_fLastHit[client][index] )
		{
			return true;
		}
		g_fLastHit[client][index] = g_fCvarDel[index] + time;
	}
	return false;
}



// ====================================================================================================
//					DETOUR
// ====================================================================================================
void DetourAddress(bool patch)
{
	static bool patched;

	if( !patched && patch )
	{
		if( !DHookEnableDetour(g_hDetour, false, IsInvulnerablePre) )
			SetFailState("Failed to detour pre \"CTerrorPlayer::IsInvulnerable\".");

		if( !DHookEnableDetour(g_hDetour, true, IsInvulnerablePost) )
			SetFailState("Failed to detour post \"CTerrorPlayer::IsInvulnerable\".");
	}
	else if( patched && !patch )
	{
		if( !DHookDisableDetour(g_hDetour, false, IsInvulnerablePre) )
			SetFailState("Failed to detour pre \"CTerrorPlayer::IsInvulnerable\".");

		if( !DHookDisableDetour(g_hDetour, true, IsInvulnerablePost) )
			SetFailState("Failed to detour post \"CTerrorPlayer::IsInvulnerable\".");
	}
}

public MRESReturn IsInvulnerablePre()
{
	// Unused but hook required to prevent crashing.
}

public MRESReturn IsInvulnerablePost(int pThis, Handle hReturn)
{
	bool invul = DHookGetReturn(hReturn);
	g_bInvulnerable[pThis] = invul;

	if( invul )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}