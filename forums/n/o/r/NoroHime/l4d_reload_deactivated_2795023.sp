#define PLUGIN_VERSION		"1.2.1"
#define PLUGIN_PREFIX		"l4d_"
#define PLUGIN_NAME			"reload_deactivated"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] BackGround Reloading (QuickSwitch Plus)"
#define PLUGIN_DESCRIPTION	"make ammo reloading during gun deactivated"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=340675"

/*
 *	v1.0 just early access; 3-December-2022
 *	v1.1 officially released:
 *		 new ConVar *_duration to scale the duration of background reload,
 *		 shotgun now reload bullet by bullet; 4-December-2022
 *	v1.2 new features and fix:
 *		 fix a potential variable leak issue (rarely about shotgun),
 *		 new ConVar *_access to allow which weapon can be background reloading,
 *		 new ConVar *_stepload to allow which gun reload ammo one by one, default is shoutguns,
 *		 new ConVar *_sounds to allow which sound should emit to client, load or success, success sound fully supoprt,
 *		 change weapon class matches to more effective way, thanks to Silvers,
 *		 optimize 'stepload' logic, more similar to game vanilla,
 *		 if didnt installed L4DD yet then throw error,
 *		 uploaded video https://youtu.be/DRcLd1QCVkg; 5-December-2022
 *	v1.2.1 fix some unknown lateload issue cause load plugin fail; 12-December-2022
 */

/**
 * todos
 * 	- success sound (done)
 * 	- reloading sound (shotgun only, if needed edit yourself)
 * 	- specify which weapon available to quickswitch plus (done)
 * 	- specify which weapon reload bullet by bullet like shotgun (done)
 * 	- scale the reload duration (done)
 * 	- background reload without reloading first? (no prefer, i dont need and hard to read reload duration)
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

bool bLateLoad = false;
bool bL4DDExists = false;

enum L4D2IntWeaponAttributes
{
	L4D2IWA_Damage,
	L4D2IWA_Bullets,
	L4D2IWA_ClipSize,
	L4D2IWA_Bucket,
	L4D2IWA_Tier, // L4D2 only
	MAX_SIZE_L4D2IntWeaponAttributes
};

 
static const char CLASSES_WEAPON[][] = {
	"weapon_hunting_rifle",
	"weapon_sniper_military",
	"weapon_sniper_scout",
	"weapon_sniper_awp",
	"weapon_pistol_magnum",
	"weapon_rifle",
	"weapon_rifle_sg552",
	"weapon_rifle_desert",
	"weapon_rifle_ak47",
	"weapon_rifle_m60",
	"weapon_smg",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_pistol",
	"weapon_pumpshotgun",
	"weapon_shotgun_chrome",
	"weapon_autoshotgun",
	"weapon_shotgun_spas",
	"weapon_grenade_launcher",
};

StringMap MAP_WEAPONS;

static const char SOUNDS_SUCCESS[][] = {
	"weapons/hunting_rifle/gunother/hunting_rifle_cliplocked.wav",
	"weapons/sniper_military/gunother/sniper_military_slideforward_1.wav",
	"weapons/scout/gunother/scout_bolt_forward.wav",
	"weapons/awp/gunother/awp_bolt_forward.wav",
	"weapons/magnum/gunother/pistol_slideforward_1.wav",
	"weapons/rifle/gunother/rifle_fullautobutton_1.wav",
	"weapons/sg552/gunother/sg552_boltpullforward.wav",
	"weapons/rifle_desert/gunother/rifle_fullautobutton_1.wav",
	"weapons/rifle_ak47/gunother/rifle_slideforward.wav",
	"weapons/machinegun_m60/gunother/rifle_slideforward.wav",
	"weapons/smg/gunother/smg_slideforward_1.wav",
	"weapons/smg_silenced/gunother/smg_fullautobutton_1.wav",
	"weapons/mp5navy/gunother/mp5_slideback.wav",
	"weapons/pistol/gunother/pistol_slideforward_1.wav",
	"weapons/shotgun/gunother/shotgun_pump_1.wav",
	"weapons/shotgun_chrome/gunother/shotgun_pump_1.wav",
	"weapons/auto_shotgun/gunother/autoshotgun_boltforward.wav",
	"weapons/auto_shotgun_spas/gunother/autoshotgun_boltforward.wav",
	"weapons/grenade_launcher/grenadeother/grenade_launcher_shellin.wav",
}

static const char SOUNDS_LOAD[][] = {
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"weapons/shotgun/gunother/shotgun_load_shell_2.wav",
	"weapons/shotgun_chrome/gunother/shotgun_load_shell_2.wav",
	"weapons/auto_shotgun/gunother/auto_shotgun_load_shell_2.wav",
	"weapons/auto_shotgun_spas/gunother/auto_shotgun_load_shell_2.wav",
	"",
}

native int L4D2_GetIntWeaponAttribute(const char[] weaponName, L4D2IntWeaponAttributes attr);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	MarkNativeAsOptional("L4D2_GetIntWeaponAttribute");

	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name) {
	if( strcmp(name, "left4dhooks") == 0 )
		bL4DDExists = true;
}

public void OnLibraryRemoved(const char[] name) {
	if( strcmp(name, "left4dhooks") == 0 )
		bL4DDExists = true;
}

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cDuration;		float flDuration;
ConVar cAccess;			int iAccess;
ConVar cStepload;		int iStepload;
ConVar cSounds;			int iSounds;


public void OnPluginStart() {

	CreateConVar					(PLUGIN_NAME, PLUGIN_VERSION,				"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cDuration =			CreateConVar(PLUGIN_NAME ... "_duration", "1.0",		"scaler of the background reload duration", FCVAR_NOTIFY);
	cAccess =			CreateConVar(PLUGIN_NAME ... "_access", "524287",		"which weapons to access plugin: 1=hunting 2=military 4=scout 8=awp 16=magnum\n32=m16 64=sg552 128=desert 256=ak47 512=m60 1024=uzi 2048=mac10 4096=mp5 8192=pistol\n16384=pump 32768=chrome 65536=xm1014 131072=spas12 262144=GL.\n524287=All -1=All add numbers together you want", FCVAR_NOTIFY);
	cStepload =			CreateConVar(PLUGIN_NAME ... "_stepload", "245760",		"which weapons reload as one by one, default is shotguns, option see *_access", FCVAR_NOTIFY);
	cSounds =			CreateConVar(PLUGIN_NAME ... "_sounds", "3",			"which sounds should emit to client 1=reload success 2=loaded by *_stepload 3=All", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cDuration.AddChangeHook(OnConVarChanged);
	cAccess.AddChangeHook(OnConVarChanged);
	cStepload.AddChangeHook(OnConVarChanged);
	cSounds.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	MAP_WEAPONS = new StringMap();

	for (int i = 0; i < sizeof(CLASSES_WEAPON); i++)
		MAP_WEAPONS.SetValue(CLASSES_WEAPON[i], i);

	// Late Load
	if (bLateLoad) {

		bL4DDExists = LibraryExists("left4dhooks");

		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);

		for (int i = MaxClients + 1; i < 2048; i++)
			if (IsValidEntity(i)) {
				char classname[32];
				GetEntityClassname(i, classname, sizeof(classname));
				OnEntityCreated(i, classname);
			}
	}
}

void ApplyCvars() {

	flDuration = cDuration.FloatValue;
	iAccess = cAccess.IntValue;
	iStepload = cStepload.IntValue;
	iSounds = cSounds.IntValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnMapStart() {

	for (int i = 0; i < sizeof(SOUNDS_SUCCESS); i++)
		if (SOUNDS_SUCCESS[i][0])
			PrecacheSound(SOUNDS_SUCCESS[i]);

	for (int i = 0; i < sizeof(SOUNDS_LOAD); i++)
		if (SOUNDS_LOAD[i][0])
			PrecacheSound(SOUNDS_LOAD[i]);
}

float timeReloadStart [2048];
float timeReloadEnd [2048];
int iWeaponReloader [2048];
int iListeningType [2048] = { -1, ... };
int iClipMax [2048];
bool bIsBulletByBullet [2048]
int iWeaponAmmoAlreadyLoaded [2048];

public void OnClientPutInServer(int client) {

	if (!IsFakeClient(client)) {
		SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	}
}

public void OnEntityCreated(int entity, const char[] classname) {

	if (classname[0] == 'w') {

		int index;

		if (MAP_WEAPONS.GetValue(classname, index) && iAccess & ( 1 << index ) ) {

			if (!bL4DDExists) {
				LogMessage	("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
				SetFailState("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
				return;
			}

			iClipMax[entity] = L4D2_GetIntWeaponAttribute(classname, L4D2IWA_ClipSize);

			if (iClipMax[entity] > 0) {

				SDKHook(entity, SDKHook_ReloadPost, OnWeaponReloadPost);
				iListeningType[entity] = index;

				if (iStepload & ( 1 << index ))
					bIsBulletByBullet[entity] = true;
			}
		}
	}
}

public void OnEntityDestroyed(int entity) {

	if (2048 > entity > MaxClients) {
		timeReloadStart[entity] = 0.0;
		timeReloadEnd[entity] = 0.0;
		iWeaponReloader[entity] = 0;
		iListeningType[entity] = -1;
		iClipMax[entity] = 0;
		bIsBulletByBullet[entity] = false;
		iWeaponAmmoAlreadyLoaded[entity] = false;
	}
}


void OnWeaponReloadPost(int weapon, bool agree) {

	if (agree) {

		float time = GetGameTime(),
			  attacktime = Weapon(weapon).attacktime;

		timeReloadStart[weapon] = time;
		timeReloadEnd[weapon] = time + (attacktime - time) * flDuration;
	}
}

Action OnWeaponSwitch(int client, int weapon_switch) {

	Survivor survivor = Survivor(client);

	if (survivor.valid) {

		Weapon weapon_actived = survivor.weapon;

		if (weapon_actived.valid && weapon_actived.index != weapon_switch && iListeningType[weapon_actived.index] != -1 && weapon_actived.reloading) {
			iWeaponReloader[weapon_actived.index] = client;
			iWeaponAmmoAlreadyLoaded[weapon_actived.index] = weapon_actived.clip;

			RequestFrame(BackgroundReloadFrame, EntIndexToEntRef(weapon_actived.index));
		}
	}

	return Plugin_Continue;
}

enum {
	PLAY_SUCCESS	= (1 << 0),
	PLAY_LOADED		= (1 << 1)
}

void BackgroundReloadFrame(int index_weapon) {

	index_weapon = EntRefToEntIndex(index_weapon);

	Weapon weapon = Weapon(index_weapon);

	if (weapon.valid) {

		int owner = weapon.owner;

		if (owner == iWeaponReloader[index_weapon] && Survivor(owner).valid && weapon.state == 1) {

			float time = GetGameTime();

			bool step_loading = bIsBulletByBullet[index_weapon];

			if (time >= timeReloadEnd[index_weapon] || step_loading) {

				int ammo_clip = weapon.clip, should_load,
					ammo_clip_max = weapon.dual ? iClipMax[index_weapon] * 2 : iClipMax[index_weapon];

				if (step_loading) {

					float duration = timeReloadEnd[index_weapon] - timeReloadStart[index_weapon],
						  overtime = time - timeReloadStart[index_weapon];

					// just in case, prevent read the wrong attacktime
					if (overtime > 0)
						should_load = RoundToFloor(overtime / duration * (ammo_clip_max - iWeaponAmmoAlreadyLoaded[index_weapon])) - (ammo_clip - iWeaponAmmoAlreadyLoaded[index_weapon]);

					// situation: last load great than 1, and clip is very large
					if (should_load + ammo_clip > ammo_clip_max)
						should_load = ammo_clip_max - ammo_clip;

				} else {

					should_load = ammo_clip_max - ammo_clip;
				}

				if (should_load > 0) {

					int ammo_reserved = weapon.GetAmmo(owner);

					if (ammo_reserved >= should_load) { // regular situation
						// reduce reserved
						weapon.SetAmmo(owner, ammo_reserved - should_load);
						// give clip
						weapon.clip = ammo_clip + should_load;

					} else { // not enough reserved ammo

						switch (weapon.ammotype) {

							case 1, 2 : //pistol, magnum

								weapon.clip = ammo_clip + should_load;

							default : {

								weapon.SetAmmo(owner, 0);
								weapon.clip = ammo_clip + ammo_reserved;

								// not enough ammo to step loading
								if (step_loading) {
									EmitSuccessSound(owner, index_weapon, PLAY_SUCCESS);
									return;
								}
							}
						}
					}
				}

				if (step_loading && ammo_clip < ammo_clip_max) {

					RequestFrame(BackgroundReloadFrame, EntIndexToEntRef(index_weapon));

					if (should_load > 0)

						EmitSuccessSound(owner, index_weapon, PLAY_LOADED);
				} else

					EmitSuccessSound(owner, index_weapon, PLAY_SUCCESS);

			} else
				RequestFrame(BackgroundReloadFrame, EntIndexToEntRef(index_weapon));
		}
	}
}

void EmitSuccessSound(int client, int weapon, int type = PLAY_SUCCESS) {

	int sample = iListeningType[weapon];

	if ( sample != -1 && iSounds & type) {

		if (type == PLAY_SUCCESS && SOUNDS_SUCCESS[sample][0])
			EmitSoundToClient(client, SOUNDS_SUCCESS[sample]);

		if (type == PLAY_LOADED && SOUNDS_LOAD[sample][0])
			EmitSoundToClient(client, SOUNDS_LOAD[sample]);
	}
}


/////////////////////////////
// Method Map Below ////////
///////////////////////////

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
		public set(int size) {
			SetEntProp(this.index, Prop_Send, "m_iClip1", size);
		}
	}

	property int ammo {
		public get() {
			return GetEntProp(this.index, Prop_Data, "m_iExtraPrimaryAmmo")
		}
		public set(int size) {
			SetEntProp(this.index, Prop_Data, "m_iExtraPrimaryAmmo", size);
		}
	}

	property int ammotype {
		public get() {
			return GetEntProp(this.index, Prop_Data, "m_iPrimaryAmmoType")
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