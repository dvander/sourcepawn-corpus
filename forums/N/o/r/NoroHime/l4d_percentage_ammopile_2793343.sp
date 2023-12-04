#define PLUGIN_VERSION		"1.0"
#define PLUGIN_PREFIX		"l4d_"
#define PLUGIN_NAME			"percentage_ammopile"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] Percentage Limited Ammo Pile"
#define PLUGIN_DESCRIPTION	"ammo pile has shared limited ammo, dont waste any bullet"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?p=2793343"

/*
 *	v1.0 just released; 22-November-2022
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsEntity(%1) (2048 >= %1 > MaxClients)


bool bLateLoad = false;
bool hasTranslations = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	return APLRes_Success;
}

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cLimit;		float flLimit;
ConVar cAnnounce;	int iAnnounce;
ConVar cScale;		float flScale;


public void OnPluginStart() {

	CreateConVar		(PLUGIN_NAME, PLUGIN_VERSION,			"Version of " ... PLUGIN_NAME_FULL, FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cLimit =	CreateConVar(PLUGIN_NAME ... "_limit", "-1",	"percent of ammo pile limit\n-1=auto scaled by survivor count 1.0=shared 100% ammo, 4.0=shared 400% ammo", FCVAR_NOTIFY);
	cAnnounce =	CreateConVar(PLUGIN_NAME ... "_announce", "2",	"announce types 0=dont announce 1=center 2=chat 4=hint. add numbers together you want", FCVAR_NOTIFY);
	cScale =	CreateConVar(PLUGIN_NAME ... "_scale", "0.5",	"factor to scale the ammo limit, usually use on *_limit=-1", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cLimit.AddChangeHook(OnConVarChanged);
	cAnnounce.AddChangeHook(OnConVarChanged);
	cScale.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/" ... PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt");
	hasTranslations = FileExists(path);

	if (hasTranslations)
		LoadTranslations(PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases");
	else
		LogError("not translations file %s found yet, please check install guide for %s", PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt", PLUGIN_NAME_FULL);

	// Late Load
	if (bLateLoad) {

		int entity = INVALID_ENT_REFERENCE;

		while ((entity = FindEntityByClassname(entity, "weapon_ammo_spawn")) != INVALID_ENT_REFERENCE) {

			SDKHook(entity, SDKHook_UsePost, OnAmmoUsePost);
			SDKHook(entity, SDKHook_Use, OnAmmoUse);
		}
	}
}



void ApplyCvars() {

	flLimit = cLimit.FloatValue;
	iAnnounce = cAnnounce.IntValue;
	flScale = cScale.FloatValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}


float pile_used [2048];

public void OnEntityCreated(int entity, const char[] classname) {

	if (strcmp(classname, "weapon_ammo_spawn") == 0) {

		SDKHook(entity, SDKHook_UsePost, OnAmmoUsePost);
		SDKHook(entity, SDKHook_Use, OnAmmoUse);

		pile_used[entity] = 0.0;
	}
}


public void OnEntityDestroyed(int entity) {

	if (IsEntity(entity))
		pile_used[entity] = 0.0;
}

int ammo_use_before;

Action OnAmmoUse(int entity, int activator, int caller, UseType type, float value) {

	if (IsClient(caller)) {

		Survivor survivor = Survivor(caller);

		Weapon weapon = survivor.slot(0);

		if (weapon.valid) {

			if (pile_used[entity] >= GetAmmoLimit()) {

				RemoveEntity(entity);

				Announce(caller, "%t", "Ammo Pile Used");

				return Plugin_Handled;
			}

			ammo_use_before = weapon.clip + weapon.GetAmmo(caller);
		}
	}

	return Plugin_Continue;
}

float GetAmmoLimit() {

	if (flLimit < 0)
		return GetTeamClientCount(2) * flScale;
	else
		return flLimit;
}

void OnAmmoUsePost(int entity, int activator, int caller, UseType type, float value) {

	if (IsClient(caller)) {

		Survivor survivor = Survivor(caller);

		Weapon weapon = survivor.slot(0);

		if (weapon.valid) {

			int ammo_reserved =  weapon.GetAmmo(caller),
				ammo_after = weapon.clip + ammo_reserved,
				ammo_used = ammo_after - ammo_use_before;

			float limit = GetAmmoLimit();

			if (ammo_used > 0)

				pile_used[entity] += float(ammo_used) / ammo_after;

			else {

				Announce( caller, "%t", "Ammo Pile Remain", (limit - pile_used[entity]) * 100 );

				return;
			}


			// reached ammo limit
			if (pile_used[entity] >= limit) {


				// reduce weapon ammo
				int ammo_reduce = RoundToFloor( (pile_used[entity] - limit) * ammo_after ); //gave one more :)

				if (ammo_reserved - ammo_reduce >= 0) {

					weapon.SetAmmo(caller, ammo_reserved - ammo_reduce);
				} else { // almost dont encounter this situation, just in case if third-party plugin changed

					weapon.SetAmmo(caller, 0);
					weapon.clip = weapon.clip - (ammo_reduce - ammo_reserved);
				}

				pile_used[entity] = 0.0;

				RemoveEntity(entity);

				Announce(caller, "%t%t", "Ammo Pile Used", "Taken Ammo", ammo_used - ammo_reduce);


			} else {

				Announce(caller, "%t%t", "Ammo Pile Remain", (limit - pile_used[entity]) * 100, "Taken Ammo", ammo_used);
			}
		}
	}
}

/////////////////////////////
// Stocks Below     ////////
///////////////////////////

enum {
	ANNOUNCE_CENTER =	(1 << 0),
	ANNOUNCE_CHAT	=	(1 << 1),
	ANNOUNCE_HINT	=	(1 << 2),
}

void Announce(int client, const char[] format, any ...) {

	if (!hasTranslations)
		return;

	static char buffer[254];

	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceColor(buffer, sizeof(buffer));

	if (IsClient(client)) {

		if (iAnnounce & ANNOUNCE_CHAT)
			PrintToChat(client, "%s", buffer);

		if (iAnnounce & ANNOUNCE_HINT)
			PrintHintText(client, "%s", buffer);

		if (iAnnounce & ANNOUNCE_CENTER)
			PrintCenterText(client, "%s", buffer);
	}
}

stock void ReplaceColor(char[] message, int maxLen) {

	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{default}", "\x01", false);
	ReplaceString(message, maxLen, "{cyan}", "\x03", false);
	ReplaceString(message, maxLen, "{lightgreen}", "\x03", false);
	ReplaceString(message, maxLen, "{orange}", "\x04", false);
	ReplaceString(message, maxLen, "{olive}", "\x04", false);
	ReplaceString(message, maxLen, "{green}", "\x05", false);
}


/////////////////////////////
// Method Map Below ////////
///////////////////////////

methodmap Survivor {
	public Survivor(int index) {
		return view_as<Survivor>(index);
	}
	property Weapon weapon {
		public get() {
			return Weapon(GetEntPropEnt(view_as<int>(this), Prop_Send, "m_hActiveWeapon"));
		}
	}
	property int userid {
		public get() {
			return GetClientUserId(view_as<int>(this));
		}
	}
	public Weapon slot(int slot) {
		return Weapon(GetPlayerWeaponSlot(view_as<int>(this), slot));
	}
}

methodmap Weapon {

	public Weapon(int index) {
		return view_as<Weapon>(index);
	}

	property bool valid {
		public get() {
			int index = view_as<int>(this);
			return (2048 >= index > MaxClients) && IsValidEntity(index);
		}
	}

	property int owner {
		public get() {
			return GetEntPropEnt(view_as<int>(this), Prop_Send, "m_hOwnerEntity");
		}
		public set(int entity) {
			SetEntPropEnt(view_as<int>(this), Prop_Send, "m_hOwnerEntity", entity)
		}
	}

	//on target = 0x40, not carried = 0, carrying = 1, activating = 2;
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
}