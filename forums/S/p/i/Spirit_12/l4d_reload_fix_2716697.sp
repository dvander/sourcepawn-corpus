#define PLUGIN_VERSION		"1.1"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Reload Fix - Max Clip Size
*	Author	:	SilverShot
*	Descrp	:	Fixes glitchy animation when the max clip sized was changed.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321696
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (25-Aug-2020)
	- Initial release.

===================================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#define GAMEDATA		"l4d_reload_fix"

bool g_bLeft4Dead2;
StringMap g_hClipSize;
StringMap g_hDefaults;

char g_sWeapons[][] =
{
	"weapon_rifle",
	"weapon_autoshotgun",
	"weapon_hunting_rifle",
	"weapon_smg",
	"weapon_pumpshotgun",
	"weapon_pistol"
};

// From Left4Dhooks - put here to prevent using include and left4dhooks requirement for L4D1.
enum L4D2IntWeaponAttributes
{
	L4D2IWA_Damage,
	L4D2IWA_Bullets,
	L4D2IWA_ClipSize,
	MAX_SIZE_L4D2IntWeaponAttributes
};
native int L4D2_GetIntWeaponAttribute(const char[] weaponName, L4D2IntWeaponAttributes attr);




// ====================================================================================================
//										PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Reload Fix - Max Clip Size",
	author = "SilverShot",
	description = "Fixes glitchy animation when the max clip sized was changed.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=321696"
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

	MarkNativeAsOptional("L4D2_GetIntWeaponAttribute");

	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	if( g_bLeft4Dead2 && LibraryExists("left4dhooks") == false )
	{
		SetFailState("\n==========\nMissing required plugin: \"Left 4 DHooks Direct\".\nRead installation instructions again.\n==========");
	}
}

public void OnPluginStart()
{
	CreateConVar("l4d_reload_fix_version", PLUGIN_VERSION, "Reload Fix - Max Clip Size plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// =========================
	// GAMEDATA
	// =========================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	// =========================
	// DETOUR
	// =========================
	Handle hDetour = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if( !hDetour )
		SetFailState("Failed to setup detour handle: CTerrorGun::Reload");

	if( !DHookSetFromConf(hDetour, hGameData, SDKConf_Signature, "CTerrorGun::Reload") )
		SetFailState("Failed to find signature: CTerrorGun::Reload");

	if( !DHookEnableDetour(hDetour, false, OnGunReload) )
		SetFailState("Failed to detour: CTerrorGun::Reload");
		
	Handle hDetour_Shotgun = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if( !hDetour_Shotgun )
		SetFailState("Failed to setup detour handle: CBaseShotgun::Reload");

	if( !DHookSetFromConf(hDetour_Shotgun, hGameData, SDKConf_Signature, "CBaseShotgun::Reload") )
		SetFailState("Failed to find signature: CBaseShotgun::Reload");

	if( !DHookEnableDetour(hDetour_Shotgun, false, OnShotgunGunReload) )
		SetFailState("Failed to detour: CBaseShotgun::Reload");

	// =========================
	// CLIP SIZE
	// =========================
	if( !g_bLeft4Dead2 )
	{
		g_hDefaults = new StringMap();

		g_hDefaults.SetValue("weapon_rifle",			50);
		g_hDefaults.SetValue("weapon_autoshotgun",		10);
		g_hDefaults.SetValue("weapon_hunting_rifle",	15);
		g_hDefaults.SetValue("weapon_smg",				50);
		g_hDefaults.SetValue("weapon_pumpshotgun",		8);
		g_hDefaults.SetValue("weapon_pistol",			15);
	}
}

public void OnMapStart()
{
	if( !g_bLeft4Dead2 )
	{
		// Get weapons max clip size, does not support any servers that dynamically change during gameplay.
		delete g_hClipSize;
		g_hClipSize = new StringMap();

		int index, entity, size;
		size = g_bLeft4Dead2 ? 18 : 6;
		while( index < size )
		{
			entity = CreateEntityByName(g_sWeapons[index]);
			DispatchSpawn(entity);

			g_hClipSize.SetValue(g_sWeapons[index], GetEntProp(entity, Prop_Send, "m_iClip1"));
			RemoveEdict(entity);
			index++;
		}
	}
}

MRESReturn OnGunReload(int pThis, Handle hReturn, Handle hParams)
{
	if(BlockReload(pThis))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

MRESReturn OnShotgunGunReload(int pThis, Handle hReturn, Handle hParams)
{
	if(BlockReload(pThis))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

bool BlockReload(int pThis)
{
	if( pThis > MaxClients )
	{
		int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

		if( client > 0 && client <= MaxClients && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if( weapon > MaxClients && pThis == weapon )
			{
				static char classname[32];
				GetEdictClassname(weapon, classname, sizeof classname);

				int ammo;
				if( g_bLeft4Dead2 )
				{
					ammo = L4D2_GetIntWeaponAttribute(classname, L4D2IWA_ClipSize);
				}
				else
				{
					if( !g_hClipSize.GetValue(classname, ammo) )
						return false;
				}

				if( ammo != -1 )
				{
					if( GetEntProp(weapon, Prop_Send, "m_isDualWielding") )
						ammo *= 2;

					if( ammo == GetEntProp(weapon, Prop_Send, "m_iClip1") )
					{
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.1);
						return true;
					}
				}
			}
		}
	}
	
	return false;
}