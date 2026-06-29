#define PLUGIN_VERSION		"1.3.1"
#define PLUGIN_NAME			"ammo_previous"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] Take Ammo From Previous Weapon"
#define PLUGIN_DESCRIPTION	"take the ammo from previous weapon when picking same gun or same ammo"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?p=2792690"

/**
 *  Changes
 *  
 *	v1.0 (13-November-2022)
 *		- just released
 *	v1.1 (16-November-2022)
 *		- new ConVar *_pile to allow pick ammo from gun pile, even pile just one gun only
 *	v1.1.1 (26-November-2022)
 *		- fix an issue 'plugin wont record max ammo without picking weapon' will causes plugin not working on first map
 *	v1.2 (9-December-2022)
 *		- ConVar *_pass set to 2 to pass on custom ammotype lists,
 *		- new ConVars *_pass_list# to control which ammotype is similar, work on *_pass = 2
 *		- fix unexpected upgraded ammo behavior, will record wrong max ammo,
 *		- turn code style to OOP-ish, simplify code (maybe),
 *		- fix plugin not work when didnt active weapon yet
 *	v1.3 (28-May-2023)
 *		- fully compatible with '[L4D/L4D2] Reserve Control'
 *		- overhaul max reserved ammo value getting way from in-game calcs to read from ConVars
 *		- fix sometime weird ammo count
 *	v1.3.1 (17-August-2023)
 *		- fix big bug got incorrect reserved ammo caused weird clip size
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

// l4d_reservecontrol
bool bIsReserveControlExists;

ConVar cAmmoRifleMax, cAmmoAutoShotgunMax, cAmmoShotgunMax, cAmmoGLMax, cAmmoSniperMax, cAmmoM60Max, cAmmoHuntingRifleMax, cAmmoSMGMax; 
bool bLateLoad;
int iReserveAmmoMax[L4D2WeaponId_MAX];

enum L4D2IntWeaponAttributes
{
	L4D2IWA_Damage,
	L4D2IWA_Bullets,
	L4D2IWA_ClipSize,
	L4D2IWA_Bucket,
	L4D2IWA_Tier, // L4D2 only
	MAX_SIZE_L4D2IntWeaponAttributes
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

native int L4D_GetWeaponID(const char[] weaponName);
native int L4D2_GetIntWeaponAttribute(const char[] weaponName, L4D2IntWeaponAttributes attr);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	MarkNativeAsOptional("L4D_GetWeaponID");

	return APLRes_Success;
}


enum { 
	PassOnSameGun = 0,
	PassOnSameAmmo,
	PassOnSimilarAmmo
}

public void OnAllPluginsLoaded() {
	// Require Left4DHooks
	if( LibraryExists("left4dhooks") == false ) {
		LogMessage	("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
		SetFailState("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
	}

	if(FindConVar("l4d_reservecontrol_version")) {
		bIsReserveControlExists = true;
		LoadConfigSMC();
	}
}

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cPass;		int iPass;
ConVar cPile;		bool bPile;
ConVar cPassList1;	ArrayList listAmmoTypes1;
ConVar cPassList2;	ArrayList listAmmoTypes2;
ConVar cPassList3;	ArrayList listAmmoTypes3;


public void OnPluginStart() {

	CreateConVar		(PLUGIN_NAME, PLUGIN_VERSION,						"Version of " ... PLUGIN_NAME_FULL, FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cPass =			CreateConVar(PLUGIN_NAME ... "_pass", "1",				"0=pick when same gun 1=pick when same ammo type 2=same type with custom list (*_pass_list#)", FCVAR_NOTIFY);
	cPile =			CreateConVar(PLUGIN_NAME ... "_pile", "1",				"allow pick ammo from gun pile(spawn point)", FCVAR_NOTIFY);
	cPassList1 =	CreateConVar(PLUGIN_NAME ... "_pass_list1", "7,8",		"similar ammo types list when set *_pass to 2, default: shotguns", FCVAR_NOTIFY);
	cPassList2 =	CreateConVar(PLUGIN_NAME ... "_pass_list2", "3,5",		"similar ammo types list when set *_pass to 2, default: rifles and smgs", FCVAR_NOTIFY);
	cPassList3 =	CreateConVar(PLUGIN_NAME ... "_pass_list3", "9,10,6",	"similar ammo types list when set *_pass to 2, default snipers and m60", FCVAR_NOTIFY);

	listAmmoTypes1 = new ArrayList();
	listAmmoTypes2 = new ArrayList();
	listAmmoTypes3 = new ArrayList();

	AutoExecConfig(true, "l4d_" ... PLUGIN_NAME);

	cPass.AddChangeHook(OnConVarChanged);
	cPile.AddChangeHook(OnConVarChanged);
	cPassList1.AddChangeHook(OnConVarChanged);
	cPassList2.AddChangeHook(OnConVarChanged);
	cPassList3.AddChangeHook(OnConVarChanged);

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

	ApplyCvars();

	// HookEvent("item_pickup", OnItemPickup);

	// Late Load
	if (bLateLoad)
		for(int i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i))
				SDKHook(i, SDKHook_WeaponCanUsePost, OnWeaponCanUsePost);
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_WeaponCanUsePost, OnWeaponCanUsePost);
}

void ApplyCvars() {

	iPass = cPass.IntValue;
	bPile = cPile.BoolValue;

	if (iPass == PassOnSimilarAmmo) {

		listAmmoTypes1.Clear();
		listAmmoTypes2.Clear();
		listAmmoTypes3.Clear();

		char sBuffer[32], sBuffer16[16][16];
		int size;

		cPassList1.GetString(sBuffer, sizeof(sBuffer));
		
		size = ExplodeString(sBuffer, ",", sBuffer16, 16, 16);

		for (int i = 0; i < size; i++)
			listAmmoTypes1.Push(StringToInt(sBuffer16[i]));

		cPassList2.GetString(sBuffer, sizeof(sBuffer));
		
		size = ExplodeString(sBuffer, ",", sBuffer16, 16, 16);

		for (int i = 0; i < size; i++)
			listAmmoTypes2.Push(StringToInt(sBuffer16[i]));

		cPassList3.GetString(sBuffer, sizeof(sBuffer));
		
		size = ExplodeString(sBuffer, ",", sBuffer16, 16, 16);

		for (int i = 0; i < size; i++)
			listAmmoTypes3.Push(StringToInt(sBuffer16[i]));
	}

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

bool IsSimilarAmmoType(int ammotype1, int ammotype2) {

	if (ammotype1 == ammotype2)
		return true;

	if (listAmmoTypes1.FindValue(ammotype1) != -1 && listAmmoTypes1.FindValue(ammotype2) != -1)
		return true;

	if (listAmmoTypes2.FindValue(ammotype1) != -1 && listAmmoTypes2.FindValue(ammotype2) != -1)
		return true;

	if (listAmmoTypes3.FindValue(ammotype1) != -1 && listAmmoTypes3.FindValue(ammotype2) != -1)
		return true;

	return false;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

void OnWeaponCanUsePost(int client, int weapon) {

	Survivor survivor = Survivor(client);
	Weapon weapon_after = Weapon(weapon);

	if ( survivor.valid && weapon_after.valid ) {

		Weapon weapon_before = survivor.slot(0);

		if (weapon_before.valid) {

			DataPack data = new DataPack();

			data.WriteCell(survivor.userid);
			data.WriteCell(weapon_before.ammotype);

			data.WriteCell(weapon_before.ref);
			data.WriteCell(weapon_after.ref);

			static char class_before[32];
			GetEdictClassname(weapon_before.index, class_before, sizeof(class_before));
			data.WriteString(class_before);

			RequestFrame(OnWeaponUseFrame, data);
		}
	}
}

void OnWeaponUseFrame(DataPack data) {

	static char class_before[32];

	data.Reset();

	int client = GetClientOfUserId(data.ReadCell()),
		type_before = data.ReadCell();

	Survivor survivor = Survivor(client);

	Weapon	weapon_before = Weapon(EntRefToEntIndex(data.ReadCell())),
			weapon_after = Weapon(EntRefToEntIndex(data.ReadCell()));

	data.ReadString(class_before, sizeof(class_before));

	delete data;

	if (survivor.valid && weapon_after.valid) {

		static char class_after[32];
		GetEdictClassname(weapon_after.index, class_after, sizeof(class_after));

		int id_after = L4D_GetWeaponID(class_after),
			reserved_after = weapon_after.GetAmmo(client),
			clip_after = weapon_after.clip,
			upgraded_after = weapon_after.upgraded,
			ammo_total_after = (clip_after + reserved_after - upgraded_after),
			ammo_carriable_after = L4D2_GetIntWeaponAttribute(class_after, L4D2IWA_ClipSize) + iReserveAmmoMax[id_after];

		Weapon weapon_current = survivor.slot(0);

		// // store and update max carriable ammo, situation to prevent: didnt picking yet, weapon_after still on ground 
		// if (weapon_after == weapon_current && ammo_total_after > iReserveAmmoMax[id_after]) {
		// 	iReserveAmmoMax[id_after] = ammo_total_after;

		// 	for(int i = 1; i <= MaxClients; i++)
		// 		if(IsClientInGame(i) && GetUserFlagBits(i) & ADMFLAG_ROOT)
		// 			PrintToChat(i, "%N updated %d max ammo to %d(%d+%d-%d)", client, id_after, ammo_total_after, clip_after, reserved_after, upgraded_after);
		// }

		// read diff from record to known how many ammo used

		int ammo_used_after = ammo_carriable_after ? ammo_carriable_after - ammo_total_after : -1;

		// situation to prevent: picking from gun pile
		if (weapon_before.valid) {

			int clip_before = weapon_before.clip,
				upgraded_before = weapon_before.upgraded;

			switch (iPass) {

				case PassOnSameGun : {

					if (strcmp(class_before, class_after) != 0)
						return;
				}

				case PassOnSameAmmo : {

					int	type_after = weapon_after.ammotype;

					if (type_before != type_after)
						return;
				}

				case PassOnSimilarAmmo : {

					int	type_after = weapon_after.ammotype;

					if (!IsSimilarAmmoType(type_before, type_after))
						return;
				}

				default : return;
			}

			// situation: weapon_after didnt pickup yet, weapon_before still on hand
			if (weapon_after.index != weapon_current.index) {
				// get reserved ammo completely diff way
				reserved_after = weapon_after.ammo;
				ammo_total_after = (clip_after + reserved_after - upgraded_after);

				int id_before = L4D_GetWeaponID(class_before),
					reserved_before = weapon_before.GetAmmo(client),
					ammo_total_before = (clip_before + reserved_before - upgraded_before),
					ammo_carriable_before = L4D2_GetIntWeaponAttribute(class_before, L4D2IWA_ClipSize) + iReserveAmmoMax[id_before];

				// read diff from record to known how many ammo used
				ammo_used_after = ammo_carriable_before ? ammo_carriable_before - ammo_total_before : -1;

				// got correct ammo_used_after & has ammo can be transfer
				if (ammo_used_after > 0 && clip_after + reserved_after > 0) {

					// how many ammo can be transfer
					int ammo_transfer = ammo_used_after >= ammo_total_after ? ammo_total_after : ammo_used_after;

					// simply add to reserved
					weapon_before.SetAmmo(client, reserved_before + ammo_transfer);

					// not enought reserved ammo to transfer, use clip
					if (ammo_transfer > reserved_after) {
						//took anything from reserved
						weapon_after.ammo = 0;

						//took ammo from clip
						weapon_after.clip = clip_after - (ammo_transfer - reserved_after);

					} else
						
						//transfer reserved
						weapon_after.ammo = reserved_after - ammo_transfer;
				}

			} else { // regular situation

				int reserved_before = weapon_before.ammo,
					ammo_total_before = (clip_before + reserved_before - upgraded_before);

				// got correct ammo_used_after & has ammo can be transfer
				if (ammo_used_after > 0 && ammo_total_before > 0) {

					// how many amo can be transfer
					int ammo_transfer = ammo_used_after >= ammo_total_before ? ammo_total_before : ammo_used_after;

					// simply add to reserved
					weapon_after.SetAmmo(client, reserved_after + ammo_transfer);

					// not enought reserved ammo to transfer, use clip
					if (ammo_transfer > reserved_before) {
						//took anything from reserved
						weapon_before.ammo = 0;

						//took ammo from clip
						weapon_before.clip = clip_before - (ammo_transfer - reserved_before);

					} else
						//transfer reserved
						weapon_before.ammo = reserved_before - ammo_transfer;
				}
			}

		// if using weapon drop plugin, maybe encounter didnt pickup yet situation, but i dont want handle it
		// situation: previou weapon sucked by gun pile
		} else if (bPile && weapon_after.index == weapon_current.index) {

			switch (iPass) {

				case PassOnSameGun : {

					if (strcmp(class_before, class_after) != 0)
						return;
				}

				case PassOnSameAmmo : {

					int	type_after = weapon_after.ammotype;

					if (type_before != type_after)
						return;
				}

				case PassOnSimilarAmmo : {

					int	type_after = weapon_after.ammotype;

					if (!IsSimilarAmmoType(type_before, type_after))
						return;
				}

				default : return;
			}

			if (ammo_used_after > 0) {
				// just fill-up the ammo anyway
				weapon_after.SetAmmo(client, reserved_after + ammo_used_after);
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


public SMCResult SMC_OnKeyValue(Handle smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes) {

	iReserveAmmoMax[L4D_GetWeaponID(key)] = StringToInt(value);

	return SMCParse_Continue;
}


/////////////////////////////
// Method Map Below ////////
///////////////////////////

/*
 * Weapon m_iState
 */
#define WEAPON_IS_ONTARGET				0x40
#define WEAPON_NOT_CARRIED				0	// Weapon is on the ground
#define WEAPON_IS_CARRIED_BY_PLAYER		1	// This client is carrying this weapon.
#define WEAPON_IS_ACTIVE				2	// This client is carrying this weapon and it's the currently held weapon

methodmap Survivor {
	property int index {
		public get() {
			return view_as<int>(this);
		}
	}

	public Survivor(int index) {
		return view_as<Survivor>(index);
	}

	property Weapon weapon {
		public get() {
			return Weapon(GetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon"));
		}
	}

	property int userid {
		public get() {
			return GetClientUserId(this.index);
		}
	}
	
	public Weapon slot(int slot) {
		return Weapon(GetPlayerWeaponSlot(this.index, slot));
	}

	property bool valid {
		public get() {
			int index = this.index;
			return (1 <= index <= MaxClients) && IsClientInGame(index) && GetClientTeam(index) == 2;
		}
	}
	property float temphealth {

		public get() {

			static ConVar cPainPillsDecay;

			if (!cPainPillsDecay) {

				cPainPillsDecay = FindConVar("pain_pills_decay_rate");

				if (!cPainPillsDecay)
					return 0.0;
			}

			float fGameTime = GetGameTime();
			float fHealthTime = GetEntPropFloat(this.index, Prop_Send, "m_healthBufferTime");
			float fHealth = GetEntPropFloat(this.index, Prop_Send, "m_healthBuffer");
			fHealth -= (fGameTime - fHealthTime) * cPainPillsDecay.FloatValue;

			return fHealth < 0.0 ? 0.0 : fHealth;
		}
		public set(float fHealth) {
			SetEntPropFloat(this.index, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth);
			SetEntPropFloat(this.index, Prop_Send, "m_healthBufferTime", GetGameTime());
		}
	}
	property int health {

		public get() {
			return GetClientHealth(this.index);
		}
		public set(int health) {
			SetEntityHealth(this.index, health);
		}
	}
}
methodmap Weapon {

	property int index {
		public get() {
			return view_as<int>(this);
		}
	}

	public Weapon(int index) {
		return view_as<Weapon>(index);
	}

	property bool valid {
		public get() {
			int index = this.index;
			return (2048 > index > MaxClients) && IsValidEntity(index);
		}
	}

	property int ref {
		public get() {
			return EntIndexToEntRef(this.index);
		}
	}

	property int owner {
		public get() {
			return GetEntPropEnt(this.index, Prop_Send, "m_hOwnerEntity");
		}
		public set(int entity) {
			SetEntPropEnt(this.index, Prop_Send, "m_hOwnerEntity", entity)
		}
	}

	//on target = 0x40, not carried = 0, carrying = 1, activating = 2;
	property int state {
		public get() {
			return GetEntProp(this.index, Prop_Data, "m_iState");
		}
	}

	property bool melee {
		public get() {
			static char name[32];

			GetEntityClassname(this.index, name, sizeof(name));

			return strcmp(name, "weapon_melee") == 0;
		}
	}

	property float attacktime {
		public get() {
			return GetEntPropFloat(this.index, Prop_Send, "m_flNextPrimaryAttack");
		}
		public set(float gametime) {
			SetEntPropFloat(this.index, Prop_Send, "m_flNextPrimaryAttack", gametime);
		}
	}

	property float playback {
		public get() {
			return GetEntPropFloat(this.index, Prop_Send, "m_flPlaybackRate");
		}
		public set(float rate) {
			SetEntPropFloat(this.index, Prop_Send, "m_flPlaybackRate", rate);
		}
	}

	property bool reloading {
		public get() {
			return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_bInReload"));
		}
	}

	property bool firing {
		public get() {
			return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_isHoldingFireButton"));
		}
	}

	property bool reloadingempty {
		public get() {
			return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_reloadFromEmpty"));
		}
	}

	property int clip {
		public get() {
			return GetEntProp(this.index, Prop_Send, "m_iClip1")
		}
		public set(int amount) {
			SetEntProp(this.index, Prop_Send, "m_iClip1", amount);
		}
	}

	property int ammo {
		public get() {
			return GetEntProp(this.index, Prop_Send, "m_iExtraPrimaryAmmo")
		}
		public set(int amount) {
			SetEntProp(this.index, Prop_Send, "m_iExtraPrimaryAmmo", amount);
		}
	}

	property int ammotype {
		public get() {
			return GetEntProp(this.index, Prop_Data, "m_iPrimaryAmmoType")
		}
	}

	property int upgraded {
		public get() {
			return GetEntProp(this.index, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded")
		}
		public set(int amount) {
			SetEntProp(this.index, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount);
		}
	}

	property int upgradetype {
		public get() {
			return GetEntProp(this.index, Prop_Send, "m_upgradeBitVec")
		}
		public set(int bit) {
			SetEntProp(this.index, Prop_Send, "m_upgradeBitVec", bit);
		}
	}

	public void SetAmmo(int client, int size) {

		static int ammo_offset_terror = -1;

		if (ammo_offset_terror == -1)
			ammo_offset_terror = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

		SetEntData( client, ammo_offset_terror + this.ammotype * 4, size);
	}

	public int GetAmmo(int client) {

		static int ammo_offset_terror = -1;

		if (ammo_offset_terror == -1)
			ammo_offset_terror = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

		return GetEntData( client, ammo_offset_terror + this.ammotype * 4 );
	}

	public void Remove() {
		RemoveEntity(this.index);
	}

	public bool RemoveFrom(int client, bool clear = true) {

		bool result = RemovePlayerItem(client, this.index);

		if (clear)
			this.Remove();

		return result;
	}

	property bool dual {
		public get() {
			return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_hasDualWeapons"));
		}
	}
}