#define PLUGIN_VERSION 		"1.4"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Upgrade Ammo Block - Grenade Launcher
*	Author	:	SilverShot
*	Descrp	:	Blocks the Grenade Launcher from picking up incendiary or explosive upgrade ammo.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=319354
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.4 (10-May-2020)
	- Blocked test commands.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.3 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.2 (30-Oct-2019)
	- Fixed glow not turning off after map transition or when a new upgrade pack is spawned.

1.1 (28-Oct-2019)
	- Added cvar "l4d2_upgrade_block_glow" to turn glow on/off.

1.0 (27-Oct-2019)
	- Initial release.

====================================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS				FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarGlow, g_hCvarType;
bool g_bCvarAllow, g_bMapStarted, g_bHookedExplo, g_bHookedIncen;
int g_iCvarGlow, g_iCvarType;
int g_iEntities[2048];
int g_iEntMasks[2048];
bool g_bMasked[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Upgrade Ammo Block - Grenade Launcher",
	author = "SilverShot",
	description = "Block the Grenade Launcher from picking up incendiary or explosive ammo.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=319354"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if( GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow = CreateConVar(	"l4d2_upgrade_block_allow",			"1",					"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(	"l4d2_upgrade_block_modes",			"",						"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d2_upgrade_block_modes_off",		"",						"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(	"l4d2_upgrade_block_modes_tog",		"0",					"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarGlow = CreateConVar(		"l4d2_upgrade_block_glow",			"0",					"When ammo pickup is blocked set upgrade pack glow to: 0=Off. 1=On.", CVAR_FLAGS );
	g_hCvarType = CreateConVar(		"l4d2_upgrade_block_type",			"2",					"Prevent grenade launchers picking up ammo from: 1=Explosive Ammo. 2=Incendiary Ammo. 3=Both.", CVAR_FLAGS );
	CreateConVar(					"l4d2_upgrade_block_version",		PLUGIN_VERSION,			"Upgrade Block plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d2_upgrade_block");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarGlow.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_uboff", sm_uboff, ADMFLAG_ROOT, "Test command.");
	RegAdminCmd("sm_ubon", sm_ubon, ADMFLAG_ROOT, "Test command.");
}

public Action sm_uboff(int c, int a)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			g_bMasked[i] = false;
			SetMask(i, false);

			SDKUnhook(i, SDKHook_WeaponEquipPost, OnWeaponEquip);
			if( !g_iCvarGlow )
				SDKHook(i, SDKHook_WeaponEquipPost, OnWeaponEquip);
		}
	}
	return Plugin_Handled;
}

public Action sm_ubon(int c, int a)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			g_bMasked[i] = false;
			OnWeaponEquip(i, 0);

			SDKUnhook(i, SDKHook_WeaponEquipPost, OnWeaponEquip);
			if( !g_iCvarGlow )
				SDKHook(i, SDKHook_WeaponEquipPost, OnWeaponEquip);
		}
	}
	return Plugin_Handled;
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
	HookToggle();
}

void GetCvars()
{
	g_iCvarGlow = g_hCvarGlow.IntValue;
	g_iCvarType = g_hCvarType.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookToggle();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		HookToggle();
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
//					STUFF
// ====================================================================================================
void HookToggle()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			g_bMasked[i] = false;
			SetMask(i, false);

			SDKUnhook(i, SDKHook_WeaponEquipPost, OnWeaponEquip);
			if( !g_iCvarGlow )
				SDKHook(i, SDKHook_WeaponEquipPost, OnWeaponEquip);
		}
	}

	bool ok = g_bCvarAllow && g_iCvarType & (1<<0);
	if( (!g_bHookedExplo && ok) || (g_bHookedExplo && !ok) )
	{
		g_bHookedExplo = !g_bHookedExplo;

		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "upgrade_ammo_explosive")) != INVALID_ENT_REFERENCE )
		{
			g_iEntMasks[entity] = 0;
			if( ok ) 	g_iEntities[entity] = EntIndexToEntRef(entity);
			else		g_iEntities[entity] = 0;

			if( ok )	SDKHook(entity, SDKHook_Use, OnUse);
			else		SDKUnhook(entity, SDKHook_Use, OnUse);
		}
	}

	ok = g_bCvarAllow && g_iCvarType & (1<<1);
	if( (!g_bHookedIncen && ok) || (g_bHookedIncen && !ok) )
	{
		g_bHookedIncen = !g_bHookedIncen;

		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "upgrade_ammo_incendiary")) != INVALID_ENT_REFERENCE )
		{
			g_iEntMasks[entity] = 0;
			if( ok ) 	g_iEntities[entity] = EntIndexToEntRef(entity);
			else		g_iEntities[entity] = 0;

			if( ok )	SDKHook(entity, SDKHook_Use, OnUse);
			else		SDKUnhook(entity, SDKHook_Use, OnUse);
		}
	}

	if( g_bCvarAllow )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && !IsFakeClient(i) )
			{
				OnWeaponEquip(i, 0);
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(
		g_bCvarAllow &&
		(g_bHookedExplo && strcmp(classname, "upgrade_ammo_explosive") == 0) ||
		(g_bHookedIncen && strcmp(classname, "upgrade_ammo_incendiary") == 0)
	)
	{
		SDKHook(entity, SDKHook_Use, OnUse);
		g_iEntMasks[entity] = 0;
		g_iEntities[entity] = EntIndexToEntRef(entity);

		if( !g_iCvarGlow )
		{
			SDKHook(entity, SDKHook_SpawnPost, OnSpawn); // Otherwise the mask value is overwritten when entity spawned.
		}
	}
}

public void OnSpawn(int entity)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( g_bMasked[i] && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			g_bMasked[i] = false;
			OnWeaponEquip(i, 0);
		}
	}
}

public Action OnUse(int entity, int activator, int caller, UseType type, float value)
{
	int weapon = GetPlayerWeaponSlot(activator, 0);
	if( weapon != -1 && IsGrenadeLauncher(weapon) )
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					STOP GLOW
// ====================================================================================================
public void OnClientPutInServer(int client)
{
	if( g_bCvarAllow && !g_iCvarGlow && !IsFakeClient(client) )
	{
		g_bMasked[client] = false;
		SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
	}
}

public void OnWeaponEquip(int client, int weapon)
{
	weapon = GetPlayerWeaponSlot(client, 0); // Because of !drop plugins not firing SDKHook_WeaponDropPost.
	if( weapon != -1 && IsGrenadeLauncher(weapon) )
	{
		if( g_bMasked[client] == false )
		{
			g_bMasked[client] = true;
			SetMask(client, true);
		}
	}
	else if( g_bMasked[client] )
	{
		g_bMasked[client] = false;
		SetMask(client, false);
	}
}

void SetMask(int client, bool set)
{
	int mask;
	for( int i = 0; i < 2048; i++ )
	{
		if( IsValidEntRef(g_iEntities[i]) )
		{
			if( set )
			{
				mask = GetEntProp(i, Prop_Send, "m_iUsedBySurvivorsMask");

				// Client not used
				if( !(mask & (1<<client-1)) )
				{
					// Mark as temporary used
					SetEntProp(i, Prop_Send, "m_iUsedBySurvivorsMask", mask | (1<<client-1));
					g_iEntMasks[i] |= (1<<client-1);
				}
			} else {
				// Reset temporary used
				if( g_iEntMasks[i] & (1<<client-1) )
				{
					mask = GetEntProp(i, Prop_Send, "m_iUsedBySurvivorsMask");
					SetEntProp(i, Prop_Send, "m_iUsedBySurvivorsMask", mask & ~(1<<client-1));

					g_iEntMasks[i] &= ~(1<<client-1);
				}
			}
		}
	}
}

bool IsGrenadeLauncher(int weapon)
{
	static char classname[32];
	GetEdictClassname(weapon, classname, sizeof(classname));

	if( strcmp(classname[7], "grenade_launcher") == 0 )
		return true;
	return false;
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}