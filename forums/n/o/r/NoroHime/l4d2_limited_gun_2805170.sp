#define PLUGIN_VERSION		"1.0.1"
#define PLUGIN_PREFIX		"l4d2_"
#define PLUGIN_NAME			"limited_gun"
#define PLUGIN_NAME_FULL	"[L4D2] Limited Gun, Limited Ammo"
#define PLUGIN_DESCRIPTION	"replace gun spawner to only one gun with random reserved ammo"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=342915"

/**
 *	Changes
 *	v1.0 (26-May-2023)
 *		- just released
 *  v1.0.1 (31-May-2023)
 * 		- weapon MoveType now inherit from spawner 
 * 
 */


#pragma newdecls required
#pragma semicolon 1

#include <sdkhooks>
#include <sdktools>

// #include <left4dhooks>
// #include <noro>

// l4d_reservecontrol
bool bIsReserveControlExists;
int iReserveAmmoMax[L4D2WeaponId_MAX];

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))

native int L4D_GetWeaponID(const char[] weaponName);

//L4DD


static const char L4D2WeaponName[L4D2WeaponId][] =
{
	"weapon_none",					// 0
	"weapon_pistol",				// 1
	"weapon_smg",					// 2
	"weapon_pumpshotgun",			// 3
	"weapon_autoshotgun",			// 4
	"weapon_rifle",					// 5
	"weapon_hunting_rifle",			// 6
	"weapon_smg_silenced",			// 7
	"weapon_shotgun_chrome",		// 8
	"weapon_rifle_desert",			// 9
	"weapon_sniper_military",		// 10
	"weapon_shotgun_spas",			// 11
	"weapon_first_aid_kit",			// 12
	"weapon_molotov",				// 13
	"weapon_pipe_bomb",				// 14
	"weapon_pain_pills",			// 15
	"weapon_gascan",				// 16
	"weapon_propanetank",			// 17
	"weapon_oxygentank",			// 18
	"weapon_melee",					// 19
	"weapon_chainsaw",				// 20
	"weapon_grenade_launcher",		// 21
	"weapon_ammo_pack",				// 22
	"weapon_adrenaline",			// 23
	"weapon_defibrillator",			// 24
	"weapon_vomitjar",				// 25
	"weapon_rifle_ak47",			// 26
	"weapon_gnome",					// 27
	"weapon_cola_bottles",			// 28
	"weapon_fireworkcrate",			// 29
	"weapon_upgradepack_incendiary",	// 30
	"weapon_upgradepack_explosive",		// 31
	"weapon_pistol_magnum",			// 32
	"weapon_smg_mp5",				// 33
	"weapon_rifle_sg552",			// 34
	"weapon_sniper_awp",			// 35
	"weapon_sniper_scout",			// 36
	"weapon_rifle_m60",				// 37
	"weapon_tank_claw",				// 38
	"weapon_hunter_claw",			// 39
	"weapon_charger_claw",			// 40
	"weapon_boomer_claw",			// 41
	"weapon_smoker_claw",			// 42
	"weapon_spitter_claw",			// 43
	"weapon_jockey_claw",			// 44
	"weapon_machinegun",			// 45
	"vomit",						// 46
	"splat",						// 47
	"pounce",						// 48
	"lounge",						// 49
	"pull",							// 50
	"choke",						// 51
	"rock",							// 52
	"physics",						// 53
	"weapon_ammo",					// 54
	"upgrade_item",					// 55
	""
};


enum L4D2WeaponId
{
	L4D2WeaponId_None,				// 0
	L4D2WeaponId_Pistol,			// 1
	L4D2WeaponId_Smg,				// 2
	L4D2WeaponId_Pumpshotgun,		// 3
	L4D2WeaponId_Autoshotgun,		// 4
	L4D2WeaponId_Rifle,				// 5
	L4D2WeaponId_HuntingRifle,		// 6
	L4D2WeaponId_SmgSilenced,		// 7
	L4D2WeaponId_ShotgunChrome,		// 8
	L4D2WeaponId_RifleDesert,		// 9
	L4D2WeaponId_SniperMilitary,	// 10
	L4D2WeaponId_ShotgunSpas,		// 11
	L4D2WeaponId_FirstAidKit,		// 12
	L4D2WeaponId_Molotov,			// 13
	L4D2WeaponId_PipeBomb,			// 14
	L4D2WeaponId_PainPills,			// 15
	L4D2WeaponId_Gascan,			// 16
	L4D2WeaponId_PropaneTank,		// 17
	L4D2WeaponId_OxygenTank,		// 18
	L4D2WeaponId_Melee,				// 19
	L4D2WeaponId_Chainsaw,			// 20
	L4D2WeaponId_GrenadeLauncher,	// 21
	L4D2WeaponId_AmmoPack,			// 22
	L4D2WeaponId_Adrenaline,		// 23
	L4D2WeaponId_Defibrillator,		// 24
	L4D2WeaponId_Vomitjar,			// 25
	L4D2WeaponId_RifleAK47,			// 26
	L4D2WeaponId_GnomeChompski,		// 27
	L4D2WeaponId_ColaBottles,		// 28
	L4D2WeaponId_FireworksBox,		// 29
	L4D2WeaponId_IncendiaryAmmo,	// 30
	L4D2WeaponId_FragAmmo,			// 31
	L4D2WeaponId_PistolMagnum,		// 32
	L4D2WeaponId_SmgMP5,			// 33
	L4D2WeaponId_RifleSG552,		// 34
	L4D2WeaponId_SniperAWP,			// 35
	L4D2WeaponId_SniperScout,		// 36
	L4D2WeaponId_RifleM60,			// 37
	L4D2WeaponId_TankClaw,			// 38
	L4D2WeaponId_HunterClaw,		// 39
	L4D2WeaponId_ChargerClaw,		// 40
	L4D2WeaponId_BoomerClaw,		// 41
	L4D2WeaponId_SmokerClaw,		// 42
	L4D2WeaponId_SpitterClaw,		// 43
	L4D2WeaponId_JockeyClaw,		// 44
	L4D2WeaponId_Machinegun,		// 45
	L4D2WeaponId_FatalVomit,		// 46
	L4D2WeaponId_ExplodingSplat,	// 47
	L4D2WeaponId_LungePounce,		// 48
	L4D2WeaponId_Lounge,			// 49
	L4D2WeaponId_FullPull,			// 50
	L4D2WeaponId_Choke,				// 51
	L4D2WeaponId_ThrowingRock,		// 52
	L4D2WeaponId_TurboPhysics,		// 53
	L4D2WeaponId_Ammo,				// 54
	L4D2WeaponId_UpgradeItem,		// 55
	L4D2WeaponId_MAX
};

bool bLateLoad;
ConVar cAmmoRifleMax, cAmmoAutoShotgunMax, cAmmoShotgunMax, cAmmoGLMax, cAmmoSniperMax, cAmmoM60Max, cAmmoHuntingRifleMax, cAmmoSMGMax; 

public Plugin myinfo = {
	name			= PLUGIN_NAME_FULL,
	author			= PLUGIN_AUTHOR,
	description		= PLUGIN_DESCRIPTION,
	version			= PLUGIN_VERSION,
	url				= PLUGIN_LINK
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	return APLRes_Success;
}

public void OnAllPluginsLoaded() {

	if (FindConVar("l4d_reservecontrol_version")) {
		bIsReserveControlExists = true;
		LoadConfigSMC();
	}
}

ConVar cAmmoMin;		float flAmmoMin;
ConVar cAmmoMax;		float flAmmoMax;


public void OnPluginStart() {

	CreateConVar(PLUGIN_NAME ... "_version", PLUGIN_VERSION, "Plugin Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cAmmoMin =			CreateConVar(PLUGIN_NAME ... "_ammo_min", "0.0",		"min percent of reserved ammo,\n-1=fixed scale use *_max", FCVAR_NOTIFY);
	cAmmoMax =			CreateConVar(PLUGIN_NAME ... "_ammo_max", "1.0",		"max percent of reserved ammo,\n-1=fixed scale use *_min, both -1 to cancel random ammo feature", FCVAR_NOTIFY);

	cAmmoRifleMax =			FindConVar("ammo_assaultrifle_max");
	cAmmoAutoShotgunMax =	FindConVar("ammo_autoshotgun_max");
	cAmmoShotgunMax =		FindConVar("ammo_shotgun_max");
	cAmmoGLMax =			FindConVar("ammo_grenadelauncher_max");
	cAmmoSniperMax =		FindConVar("ammo_sniperrifle_max");
	cAmmoM60Max =			FindConVar("ammo_m60_max");
	cAmmoHuntingRifleMax =	FindConVar("ammo_huntingrifle_max");
	cAmmoSMGMax =			FindConVar("ammo_smg_max");

	AutoExecConfig(true, "l4d_" ... PLUGIN_NAME);
	ApplyCvars();

	cAmmoMin.AddChangeHook(OnConVarChanged);
	cAmmoMax.AddChangeHook(OnConVarChanged);

	cAmmoRifleMax =			FindConVar("ammo_assaultrifle_max");
	cAmmoAutoShotgunMax =	FindConVar("ammo_autoshotgun_max");
	cAmmoShotgunMax =		FindConVar("ammo_shotgun_max");
	cAmmoGLMax =			FindConVar("ammo_grenadelauncher_max");
	cAmmoSniperMax =		FindConVar("ammo_sniperrifle_max");
	cAmmoM60Max =			FindConVar("ammo_m60_max");
	cAmmoHuntingRifleMax =	FindConVar("ammo_huntingrifle_max");
	cAmmoSMGMax =			FindConVar("ammo_smg_max");

	cAmmoRifleMax.AddChangeHook(OnConVarChanged);
	cAmmoAutoShotgunMax.AddChangeHook(OnConVarChanged);
	cAmmoShotgunMax.AddChangeHook(OnConVarChanged);
	cAmmoRifleMax.AddChangeHook(OnConVarChanged);
	cAmmoGLMax.AddChangeHook(OnConVarChanged);
	cAmmoSniperMax.AddChangeHook(OnConVarChanged);
	cAmmoM60Max.AddChangeHook(OnConVarChanged);
	cAmmoHuntingRifleMax.AddChangeHook(OnConVarChanged);
	cAmmoSMGMax.AddChangeHook(OnConVarChanged);

	// Late Load
	if (bLateLoad) {

		char classname[32];

		for (int i = MaxClients + 1; i < 2048; i++)

			if (IsValidEntity(i)) {

				GetEntityClassname(i, classname, sizeof(classname));

				if ( classname[0] == 'w' && StartsWith(classname, "weapon_") && EndsWith(classname, "_spawn") )
					OnWeaponSpawnerFrame(i);
			}

		bLateLoad = false;
	}
}

void ApplyCvars() {

	flAmmoMin = cAmmoMin.FloatValue;
	flAmmoMax = cAmmoMax.FloatValue;

	if (!bIsReserveControlExists) {

		iReserveAmmoMax[L4D2WeaponId_Rifle] = iReserveAmmoMax[L4D2WeaponId_RifleAK47] = iReserveAmmoMax[L4D2WeaponId_RifleSG552] = iReserveAmmoMax[L4D2WeaponId_RifleDesert] = cAmmoRifleMax.IntValue;
		iReserveAmmoMax[L4D2WeaponId_ShotgunSpas] = iReserveAmmoMax[L4D2WeaponId_Autoshotgun] = cAmmoAutoShotgunMax.IntValue;
		iReserveAmmoMax[L4D2WeaponId_Smg] = iReserveAmmoMax[L4D2WeaponId_SmgSilenced] = iReserveAmmoMax[L4D2WeaponId_SmgMP5] = cAmmoSMGMax.IntValue;
		iReserveAmmoMax[L4D2WeaponId_SniperAWP] = iReserveAmmoMax[L4D2WeaponId_SniperScout] = iReserveAmmoMax[L4D2WeaponId_SniperMilitary] = cAmmoSMGMax.IntValue;
		iReserveAmmoMax[L4D2WeaponId_GrenadeLauncher] = cAmmoGLMax.IntValue;
		iReserveAmmoMax[L4D2WeaponId_HuntingRifle] = cAmmoHuntingRifleMax.IntValue;
		iReserveAmmoMax[L4D2WeaponId_RifleM60] = cAmmoM60Max.IntValue;
	}
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnEntityCreated(int entity, const char[] classname) {

	if ( classname[0] == 'w' && StartsWith(classname, "weapon_") && EndsWith(classname, "_spawn") )
		SDKHook(entity, SDKHook_SpawnPost, OnWeaponSpawnerSpawnPost);
}

void OnWeaponSpawnerSpawnPost(int spawner) {
	
	RequestFrame(OnWeaponSpawnerFrame, EntIndexToEntRef(spawner));
}

void OnWeaponSpawnerFrame(int spawner) {

	spawner = EntRefToEntIndex(spawner);

	if (spawner == INVALID_ENT_REFERENCE)
		return;

	L4D2WeaponId weaponid = view_as<L4D2WeaponId>(GetEntProp(spawner, Prop_Send, "m_weaponID"));

	switch (weaponid) {

		case L4D2WeaponId_Smg, L4D2WeaponId_Pumpshotgun, L4D2WeaponId_Autoshotgun, L4D2WeaponId_Rifle,
			L4D2WeaponId_HuntingRifle, L4D2WeaponId_SmgSilenced, L4D2WeaponId_ShotgunChrome,
			L4D2WeaponId_RifleDesert, L4D2WeaponId_SniperMilitary, L4D2WeaponId_ShotgunSpas,
			L4D2WeaponId_GrenadeLauncher, L4D2WeaponId_RifleAK47, L4D2WeaponId_SmgMP5,
			L4D2WeaponId_RifleSG552, L4D2WeaponId_SniperAWP, L4D2WeaponId_SniperScout, L4D2WeaponId_RifleM60 : {

			static char name_weapon[32];

			L4D2_GetWeaponNameByWeaponId(weaponid, name_weapon, sizeof(name_weapon));

			int weapon = CreateEntityByName(name_weapon);

			if (weapon != INVALID_ENT_REFERENCE) {

				float vOrigin[3], vAngles[3];

				GetEntPropVector(spawner, Prop_Send, "m_vecOrigin", vOrigin);
				GetEntPropVector(spawner, Prop_Send, "m_angRotation", vAngles);

				TeleportEntity(weapon, vOrigin, vAngles, NULL_VECTOR);
				
				DispatchSpawn(weapon);

				SetEntityMoveType(weapon, GetEntityMoveType(spawner));

				if (iReserveAmmoMax[weaponid] > 0) {

					int ammo_reserved = iReserveAmmoMax[weaponid];

					float scaling = flAmmoMin == -1 ? flAmmoMax == -1 ? 0.0 : flAmmoMax : flAmmoMax == -1 ? flAmmoMin : -1.0;

					if (scaling == -1)

						ammo_reserved = RoundToFloor(ammo_reserved * GetRandomFloat(flAmmoMin, flAmmoMax));

					else if (scaling > 0)

						ammo_reserved = RoundToFloor(ammo_reserved * scaling);

					SetEntProp(weapon, Prop_Send, "m_iExtraPrimaryAmmo", ammo_reserved);

					// Announce(TARGET_SERVER, MSG_CONSOLE, "scaling %.1f reserved %d name %s", scaling, ammo_reserved, name_weapon);
						
				}

				RemoveEntity(spawner);
			}
		}
	}
}

// load from l4d_reservecontrol (sourcemod/data/l4d_reservecontrol.cfg)
void LoadConfigSMC() {
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/l4d_reservecontrol.cfg");

	if( FileExists(sPath) ) {
		SMCParser parser = new SMCParser();
		parser.OnKeyValue = SMC_OnKeyValue;

		// Setup error logging
		char sError[128];
		int iLine, iCol;
		SMCError result = parser.ParseFile(sPath, iLine, iCol);
		if( result != SMCError_Okay ) {
			if( parser.GetErrorString(result, sError, sizeof(sError)) )
				SetFailState("CONFIG ERROR ID: #%d, %s. (line %d, column %d) [FILE: %s]", result, sError, iLine, iCol, sPath);
			else
				SetFailState("Unable to load config. Bad format? Check for missing { } etc.");
		}

		delete parser;
		return;
	}
	SetFailState("Could not load CFG '%s'! Plugin aborted.", sPath);
}

public SMCResult SMC_OnKeyValue(Handle smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	iReserveAmmoMax[L4D_GetWeaponID(key)] = StringToInt(value);

	// FYI: If you don't return, its this anyways
	return SMCParse_Continue;
}

//noro.inc

stock bool StartsWith(const char[] str, const char[] substr) {
	return strncmp(str, substr, strlen(substr) -1, true) == 0;
}


// SMLib (String_EndsWith)
stock bool EndsWith(const char[] str, const char[] substr) {
	int n_str = strlen(str) - 1,
		n_substr = strlen(substr) - 1;

	while (n_str != 0 && n_substr != 0) {

		if (str[n_str--] != substr[n_substr--]) {
			return false;
		}
	}

	return true;
}

//L4DD

/**
 * Returns weapon name by weapon id.
 *
 * @param weaponName	Weapon id to get name from.
 * @param dest			Destination string buffer to copy to.
 * @param destlen		Destination buffer length (includes null terminator).
 * @return				Number of cells written.
 */
// L4D2 only.
stock int L4D2_GetWeaponNameByWeaponId(L4D2WeaponId weaponId, char[] dest, int destlen)
{
	if (!L4D2_IsValidWeaponId(weaponId))
	{
		return 0;
	}

	return strcopy(dest, destlen, L4D2WeaponName[weaponId]);
}

/**
 * Returns whether weapon id is valid.
 *
 * @param weaponId		Weapon id to check for validity.
 * @return				True if weapon id is valid, false otherwise.
 */
// L4D2 only.
stock bool L4D2_IsValidWeaponId(L4D2WeaponId weaponId)
{
	return weaponId >= L4D2WeaponId_None && weaponId < L4D2WeaponId_MAX;
}