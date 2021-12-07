#define PLUGIN_VERSION 		"1.2"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Tank Punch Force
*	Author	:	SilverShot
*	Descrp	:	Scales the Tanks punching force for standing or incapped survivors.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=320908
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.

1.1 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.0 (14-Jan-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d_tank_punch_force"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarForce, g_hCvarIncap;
bool g_bCvarAllow, g_bMapStarted;
float g_fCvarForce, g_fCvarIncap;
Handle g_hDetour;
int g_iClient;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Tank Punch Force",
	author = "SilverShot",
	description = "Scales the Tanks punching force for standing or incapped survivors.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=320908"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// GAMEDATA
	// ====================================================================================================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	// Detour
	g_hDetour = DHookCreateFromConf(hGameData, "CTankClaw::OnPlayerHit");
	delete hGameData;

	if( !g_hDetour )
		SetFailState("Failed to find \"CTankClaw::OnPlayerHit\" signature.");



	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =			CreateConVar(	"l4d_tank_punch_force_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_tank_punch_force_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_tank_punch_force_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_tank_punch_force_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarForce =			CreateConVar(	"l4d_tank_punch_force_force",			"1.0",				"Scales a Survivors velocity when punched by the Tank.", CVAR_FLAGS );
	g_hCvarIncap =			CreateConVar(	"l4d_tank_punch_force_incap",			"0.0",				"Scales an Incapped Survivors velocity when punched by the Tank.", CVAR_FLAGS );
	CreateConVar(							"l4d_tank_punch_force_version",			PLUGIN_VERSION,		"Tank Punch Force plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_tank_punch_force");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarForce.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIncap.AddChangeHook(ConVarChanged_Cvars);

	IsAllowed();
}

public void OnPluginEnd()
{
	DetourAddress(false);
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
	g_fCvarForce = g_hCvarForce.FloatValue;
	g_fCvarIncap = g_hCvarIncap.FloatValue;
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
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		DetourAddress(false);
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
//					DETOUR
// ====================================================================================================
void DetourAddress(bool patch)
{
	static bool patched;

	if( !patched && patch )
	{
		if( !DHookEnableDetour(g_hDetour, false, OnPlayerHitPre) )
			SetFailState("Failed to detour pre \"CTankClaw::OnPlayerHit\".");

		if( !DHookEnableDetour(g_hDetour, true, OnPlayerHitPost) )
			SetFailState("Failed to detour post \"CTankClaw::OnPlayerHit\".");
	}
	else if( patched && !patch )
	{
		if( !DHookDisableDetour(g_hDetour, false, OnPlayerHitPre) )
			SetFailState("Failed to remove detour pre \"CTankClaw::OnPlayerHit\".");

		if( !DHookDisableDetour(g_hDetour, true, OnPlayerHitPost) )
			SetFailState("Failed to remove detour post \"CTankClaw::OnPlayerHit\".");
	}
}

public MRESReturn OnPlayerHitPre(int pThis, Handle hReturn, Handle hParams)
{
	g_iClient = DHookGetParam(hParams, 1);
}

public MRESReturn OnPlayerHitPost(int pThis, Handle hReturn, Handle hParams)
{
	if( GetClientTeam(g_iClient) == 2 )
	{
		float vVec[3];
		GetEntPropVector(g_iClient, Prop_Data, "m_vecVelocity", vVec);
		ScaleVector(vVec, GetEntProp(g_iClient, Prop_Send, "m_isIncapacitated", 1) ? g_fCvarIncap : g_fCvarForce);
		TeleportEntity(g_iClient, NULL_VECTOR, NULL_VECTOR, vVec);
	}
}