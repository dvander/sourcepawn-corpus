#define PLUGIN_VERSION		"1.0.1"
#define PLUGIN_NAME			"magnum_revolver"
#define PLUGIN_NAME_FULL	"[L4D2] Revolver-ish Magnum Reloading"
#define PLUGIN_DESCRIPTION	"reloading as bullet by bullet"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://steamcommunity.com/id/NoroHime/"

/*
 *	v1.0 just released; 17-November-2022
 *	v1.0.1 change work way to make precious working; 17-November-2022 (2nd time)
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsEntity(%1) (2048 >= %1 > MaxClients)

native int L4D2_GetIntWeaponAttribute(const char[] weaponName, L4D2IntWeaponAttributes attr);

enum L4D2IntWeaponAttributes
{
	L4D2IWA_Damage,
	L4D2IWA_Bullets,
	L4D2IWA_ClipSize,
	L4D2IWA_Bucket,
	L4D2IWA_Tier, // L4D2 only
	MAX_SIZE_L4D2IntWeaponAttributes
};

enum L4D2FloatWeaponAttributes
{
	L4D2FWA_MaxPlayerSpeed,
	L4D2FWA_SpreadPerShot,
	L4D2FWA_MaxSpread,
	L4D2FWA_SpreadDecay,
	L4D2FWA_MinDuckingSpread,
	L4D2FWA_MinStandingSpread,
	L4D2FWA_MinInAirSpread,
	L4D2FWA_MaxMovementSpread,
	L4D2FWA_PenetrationNumLayers,
	L4D2FWA_PenetrationPower,
	L4D2FWA_PenetrationMaxDist,
	L4D2FWA_CharPenetrationMaxDist,
	L4D2FWA_Range,
	L4D2FWA_RangeModifier,
	L4D2FWA_CycleTime,
	L4D2FWA_PelletScatterPitch,
	L4D2FWA_PelletScatterYaw,
	L4D2FWA_VerticalPunch,
	L4D2FWA_HorizontalPunch, // Requires "z_gun_horiz_punch" cvar changed to "1".
	L4D2FWA_GainRange,
	L4D2FWA_ReloadDuration,
	MAX_SIZE_L4D2FloatWeaponAttributes
};

bool bLateLoad = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	MarkNativeAsOptional("L4D2_GetIntWeaponAttribute");

	if (late)
		bLateLoad = true;

	return APLRes_Success;
}

public void OnAllPluginsLoaded() {
	// Requires Left 4 DHooks Direct
	if( !LibraryExists("left4dhooks") ) {
		LogMessage	("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
		SetFailState("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
	}
}


public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cDelay;		float flDelay;

public void OnPluginStart() {

	CreateConVar			(PLUGIN_NAME, PLUGIN_VERSION,		"Version of " ... PLUGIN_NAME_FULL, FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cDelay =	CreateConVar(PLUGIN_NAME ... "_delay", "0.2",	"delay the fire available when reload compeleted", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d2_" ... PLUGIN_NAME);

	cDelay.AddChangeHook(OnConVarChanged);

	if (bLateLoad) {

		int found = INVALID_ENT_REFERENCE;

		while ((found = FindEntityByClassname(found, "weapon_pistol_magnum")) != INVALID_ENT_REFERENCE)
			if (IsValidEntity(found))
				OnEntityCreated(found, "weapon_pistol_magnum");
	}

	ApplyCvars();
}

void ApplyCvars() {

	flDelay = cDelay.FloatValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

float flWeaponReloadStart[2048];
int iWeaponAmmoAlreadyLoaded[2048];

int iMagnumClipSize = 0;

public void OnEntityCreated(int entity, const char[] name_entity) {

	if (strcmp(name_entity, "weapon_pistol_magnum") == 0) {

		iMagnumClipSize = L4D2_GetIntWeaponAttribute(name_entity, L4D2IWA_ClipSize);

		SDKHook(entity, SDKHook_ReloadPost, OnReloadPost);
	}
}

public OnEntityDestroyed(int entity) {

	if (IsEntity(entity))
		flWeaponReloadStart[entity] = 0.0;
}

void OnReloadPost(int entity, bool agree) {

	if (IsEntity(entity) && agree) {

		Weapon weapon = view_as<Weapon>(entity);

		flWeaponReloadStart[entity] = GetGameTime();
		iWeaponAmmoAlreadyLoaded[entity] = weapon.clip;

		RequestFrame(OnWeaponReloading, EntIndexToEntRef(entity));
	}
}

void OnWeaponReloading(int entity) {

	entity = EntRefToEntIndex(entity);

	if (entity != INVALID_ENT_REFERENCE) {

		Weapon weapon = view_as<Weapon>(entity);

		float time = GetGameTime();

		float duration = weapon.attack_time - flWeaponReloadStart[entity];

		float overtime = time - flWeaponReloadStart[entity];

		int should_load = RoundToCeil(overtime / duration * iMagnumClipSize);

		if (weapon.reloading && weapon.clip < iMagnumClipSize) {

			weapon.clip = iWeaponAmmoAlreadyLoaded[entity] + should_load;
			RequestFrame(OnWeaponReloading, EntIndexToEntRef(entity));

		} else {

			weapon.attack_time = time + flDelay;

			int owner = weapon.owner;

			if (IsClient(owner))
				SetEntPropFloat(owner, Prop_Send, "m_flNextAttack", time + flDelay);
		}
	}
}

/////////////////////////////
// Method Map Below ////////
///////////////////////////


/*
 * Weapon.state (naming from SMLib)
 */
#define WEAPON_IS_ONTARGET				0x40
#define WEAPON_NOT_CARRIED				0	// Weapon is on the ground
#define WEAPON_IS_CARRIED_BY_PLAYER		1	// This client is carrying this weapon.
#define WEAPON_IS_ACTIVE				2	// This client is carrying this weapon and it's the currently held weapon

int ammo_offset_terror = -1;

methodmap Weapon {

	public Weapon(int index) {
		return view_as<Weapon>(index);
	}

	property int owner {
		public get() {
			return GetEntPropEnt(view_as<int>(this), Prop_Send, "m_hOwnerEntity");
		}
		public set(int entity) {
			SetEntPropEnt(view_as<int>(this), Prop_Send, "m_hOwnerEntity", entity)
		}
	}

	property int state {
		public get() {
			return GetEntPropEnt(view_as<int>(this), Prop_Data, "m_iState");
		}
	}

	property float attack_time {
		public get() {
			return GetEntPropFloat(view_as<int>(this), Prop_Send, "m_flNextPrimaryAttack");
		}
		public set(float gametime) {
			SetEntPropFloat(view_as<int>(this), Prop_Send, "m_flNextPrimaryAttack", gametime);
		}
	}

	property float playback {
		public get() {
			return GetEntPropFloat(view_as<int>(this), Prop_Send, "m_flPlaybackRate");
		}
		public set(float rate) {
			SetEntPropFloat(view_as<int>(this), Prop_Send, "m_flPlaybackRate", rate);
		}
	}

	property bool reloading {
		public get() {
			return view_as<bool>(GetEntProp(view_as<int>(this), Prop_Send, "m_bInReload"));
		}
	}

	property bool firing {
		public get() {
			return view_as<bool>(GetEntProp(view_as<int>(this), Prop_Send, "m_isHoldingFireButton"));
		}
	}

	property bool reloading_empty {
		public get() {
			return view_as<bool>(GetEntProp(view_as<int>(this), Prop_Send, "m_reloadFromEmpty"));
		}
	}

	property int clip {
		public get() {
			return GetEntProp(view_as<int>(this), Prop_Data, "m_iClip1")
		}
		public set(int size) {
			SetEntProp(view_as<int>(this), Prop_Data, "m_iClip1", size);
		}
	}

	property int ammo {
		public get() {
			return GetEntProp(view_as<int>(this), Prop_Data, "m_iExtraPrimaryAmmo")
		}
		public set(int size) {
			SetEntProp(view_as<int>(this), Prop_Data, "m_iExtraPrimaryAmmo", size);
		}
	}

	property int ammotype {
		public get() {
			return GetEntProp(view_as<int>(this), Prop_Data, "m_iPrimaryAmmoType")
		}
	}

	public void SetAmmo(int client, int size) {

		if (ammo_offset_terror == -1)
			ammo_offset_terror = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

		SetEntData( client, ammo_offset_terror + this.ammotype * 4, size);
	}

	public int GetAmmo(int client) {

		if (ammo_offset_terror == -1)
			ammo_offset_terror = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

		return GetEntData( client, ammo_offset_terror + this.ammotype * 4 );
	}
}