#define PLUGIN_VERSION		"1.0.4"
#define PLUGIN_PREFIX		"l4d_"
#define PLUGIN_NAME			"sidearm"
#define PLUGIN_NAME_FULL	"[L4D2] SideArm"
#define PLUGIN_DESCRIPTION	"sidearm is sidearm"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=340647"

/*
 *	v1.0 just released; 1-December-2022
 *	v1.0.1 fix some unexpected issue, weapon spawner bypass the plugin at before; 2-December-2022
 *	v1.0.2 player gets incappeed or ledge grabbed will cancel sidearm, not an issue, just in case; 2-December-2022 (2nd time)
 *	v1.0.3 fix unreasonable point, sidearm can trigger even not switch to melee yet; 2-December-2022 (3rd time)
 *	v1.0.4 fix forgot remove debug statement cause error; 21-December-2022
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>
// #include <noro>

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

ConVar cAnnounce;	int iAnnounce;
ConVar cHoldTime;	float flHoldTime;
ConVar cKey;		int iKey;


public void OnPluginStart() {

	CreateConVar			(PLUGIN_NAME, PLUGIN_VERSION,		"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cAnnounce =	CreateConVar(PLUGIN_NAME ... "_announce", "2",	"announce types 0=dont announce 1=center 2=chat 4=hint. add numbers together you want", FCVAR_NOTIFY);
	cHoldTime =	CreateConVar(PLUGIN_NAME ... "_holdtime", "0.0","time(seconds) for hold the reload to swap sidearm 0=tap mode", FCVAR_NOTIFY);
	cKey =		CreateConVar(PLUGIN_NAME ... "_key", "524288",	"key to trigger sidearm 524288=zoom. combine keys is available. see more in entity_prop_stocks.inc", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cAnnounce.AddChangeHook(OnConVarChanged);
	cHoldTime.AddChangeHook(OnConVarChanged);
	cKey.AddChangeHook(OnConVarChanged);

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

		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);

		for (int i = MaxClients; i < 2048; i++)
			if (IsValidEntity(i)) {
				static char classname[32];
				GetEntityClassname(i, classname, sizeof(classname));
				OnEntityCreated(i, classname);
			}
	}

	HookEvent("item_pickup", OnItemPickup, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerChange, EventHookMode_Pre);
	HookEvent("round_start", OnRoundChange, EventHookMode_Pre);
	HookEvent("round_end", OnRoundChange, EventHookMode_Pre);
	HookEvent("map_transition", OnRoundChange, EventHookMode_Pre);
	HookEvent("mission_lost", OnRoundChange, EventHookMode_Pre);
	HookEvent("finale_vehicle_leaving", OnRoundChange, EventHookMode_Pre);
	HookEvent("player_bot_replace", OnBotReplaces, EventHookMode_Pre); 
	HookEvent("bot_player_replace", OnBotReplaces, EventHookMode_Pre); 
	HookEvent("player_team", OnPlayerChange, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerChange, EventHookMode_Pre);
	HookEvent("player_ledge_grab", OnPlayerChange, EventHookMode_Pre);
	HookEvent("player_incapacitated_start", OnPlayerChange, EventHookMode_Pre);
}

void ApplyCvars() {

	flHoldTime = cHoldTime.FloatValue;
	iAnnounce = cAnnounce.IntValue;
	iKey = cKey.IntValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

float time_key_pressed [MAXPLAYERS + 1];
buttons_last [MAXPLAYERS + 1];

char stored_melee [MAXPLAYERS + 1] [32];
int stored_clip [MAXPLAYERS + 1] = { -1, ... };
int stored_reserved [MAXPLAYERS + 1] = { -1, ... };
bool bBlockListener = false;

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {

	Survivor survivor = Survivor(client);

	if (survivor.valid && IsPlayerAlive(client) && !IsFakeClient(client)) {
		
		float time = GetEngineTime();

		bool key_pressed = (buttons & iKey == iKey) && (buttons_last[client] & iKey != iKey);
		bool key_released = (buttons & iKey != iKey) && (buttons_last[client] & iKey == iKey);

		if (key_released)
			time_key_pressed[client] = 0.0

		if (key_pressed)
			time_key_pressed[client] = time;

		if ( (!flHoldTime && key_pressed) || time_key_pressed[client] && time - time_key_pressed[client] > flHoldTime ) {

			time_key_pressed[client] = 0.0;

			Weapon weapon_secondary = survivor.weapon;

			if (weapon_secondary.valid) {
				// has melee stored
				if ( stored_melee[client][0] )

					RollBackWeapon(client, weapon_secondary);

				 else {

					static char name_weapon[32];

					GetEntityClassname(weapon_secondary.index, name_weapon, sizeof(name_weapon));

					if ( strcmp(name_weapon, "weapon_melee") == 0 ) {
						// store melee type
						GetEntPropString( weapon_secondary.index, Prop_Data, "m_strMapSetScriptName", stored_melee[client], 32);

						bBlockListener = true;
						if ( weapon_secondary.RemoveFrom(client) ) {

							Weapon pistol = Weapon(GivePlayerItem(client, "weapon_pistol"));
							// restore pistol data if has
							if (pistol.valid) {

								if (stored_clip[client] != -1)
									pistol.clip = stored_clip[client];

								if (stored_reserved[client] != -1)
									pistol.SetAmmo(client, stored_reserved[client])
							}

						} else {
							// remove fail, rollback type to no data
							stored_melee[client] = "";
						}
						bBlockListener = false;

					} else if (strcmp(name_weapon, "weapon_chainsaw") == 0) {

						int clip = weapon_secondary.clip,
							reserved = weapon_secondary.GetAmmo(client);

						stored_melee[client] = "0"; //mark as Chainsaw

						bBlockListener = true;
						if ( weapon_secondary.RemoveFrom(client) ) {

							Weapon pistol = Weapon(GivePlayerItem(client, "weapon_pistol"));

							if (pistol.valid) {

								if (stored_clip[client] != -1)
									pistol.clip = stored_clip[client];

								if (stored_reserved[client] != -1)
									pistol.SetAmmo(client, stored_reserved[client])

								// store the chainsaw data
								stored_clip[client] = clip;
								stored_reserved[client] = reserved;
								
							} else {
								// remove success but given fail?, no way! todo: give chainsaw back
								LogError(PLUGIN_NAME_FULL ... ": remove melee success but give pistol fail, this is unexpected, please report");
							}
						} else {
							// remove fail, rollback type to no data
							stored_melee[client] = "";
						}
						bBlockListener = false;
					}
				}
			}
		}

		buttons_last[client] = buttons;
	}
}

int RollBackWeapon(int client, Weapon weapon_secondary) {

	Weapon melee;

	bool hasChainsaw = stored_melee[client][0] == '0';

	if (hasChainsaw)
		melee = Weapon(CreateEntityByName("weapon_chainsaw"));
	else
		melee = Weapon(CreateEntityByName("weapon_melee"));

	if (melee.valid) {

		if (!hasChainsaw)
			DispatchKeyValue(melee.index, "melee_script_name", stored_melee[client]);
		// fetch pistol data
		int clip = weapon_secondary.clip,
			reserved = weapon_secondary.GetAmmo(client);

		if ( weapon_secondary.RemoveFrom(client) ) {

			DispatchSpawn(melee.index);

			bBlockListener = true;
			EquipPlayerWeapon(client, melee.index);
			bBlockListener = false;

			if (hasChainsaw) {
				// restore chiansaw data
				if (stored_clip[client] != -1)
					melee.clip = stored_clip[client];

				if (stored_reserved[client] != -1)
					melee.SetAmmo(client, stored_reserved[client])
			}
			// store pistol data
			stored_clip[client] = clip;
			stored_reserved[client] = reserved;
			// success, mark no data
			stored_melee[client] = "";

			return melee.index;

		} else
			melee.Remove();
	}

	return -1;
}

void OnRoundChange(Event event, const char[] name, bool dontBroadcast) {

	for (int i = 1; i <= MaxClients; i++) {

		Survivor survivor = Survivor(i);

		if (survivor.valid && stored_melee[i][0]) {

			Weapon weapon = survivor.slot(1);

			if (weapon.valid)
				RollBackWeapon(i, weapon);
		}
	}
}

void OnPlayerChange(Event event, const char[] name, bool dontBroadcast) {

	Survivor survivor = Survivor(GetClientOfUserId(event.GetInt("userid")));
	
	if (survivor.valid && stored_melee[survivor.index][0]) {

		Weapon weapon = survivor.slot(1);

		if (weapon.valid)
			RollBackWeapon(survivor.index, weapon);
	}
}

void OnBotReplaces(Event event, const char[] name, bool dontBroadcast) {
	
	Survivor survivor = Survivor(GetClientOfUserId(event.GetInt("player")));
	
	if (survivor.valid && stored_melee[survivor.index][0]) {

		Weapon weapon = survivor.slot(1);

		if (weapon.valid)
			RollBackWeapon(survivor.index, weapon);
	}
}

void OnItemPickup(Event event, const char[] name, bool dontBroadcast) {

	Survivor survivor = Survivor(GetClientOfUserId(event.GetInt("userid")));

	static char name_item[32];

	event.GetString("item", name_item, sizeof(name_item));

	if ( survivor.valid) {

		if (strcmp(name_item, "melee") == 0) {
			
			if (flHoldTime > 0)
				Announce(survivor.index, "%t%t", "Melee", "SideArm by Hold")
			else
				Announce(survivor.index, "%t%t", "Melee", "SideArm by Tap")

		} else if (strcmp(name_item, "chainsaw") == 0) {

			if (flHoldTime > 0)
				Announce(survivor.index, "%t%t", "Chainsaw", "SideArm by Hold")
			else
				Announce(survivor.index, "%t%t", "Chainsaw", "SideArm by Tap")
		}

		if (bBlockListener || !stored_melee[survivor.index][0])
			return;

		Weapon weapon_secondary = survivor.slot(1);

		if (weapon_secondary.valid) {

			RollBackWeapon(survivor.index, weapon_secondary);
		}
	}
}


public void OnClientPutInServer(int client) {

	if (!IsFakeClient(client)) {
		SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponChange);
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponChange);
		SDKHook(client, SDKHook_WeaponDrop, OnWeaponChange);
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponChange);
	}
}

public void OnClientDisconnect_Post(int client) {

	stored_melee[client] = "";
	stored_clip[client] = -1;
	stored_reserved[client] = -1;
	time_key_pressed[client] = 0.0;
	buttons_last[client] = 0;
}


Action OnWeaponChange(int client, int weapon) {

	if (bBlockListener)
		return Plugin_Continue;

	Survivor survivor = Survivor(client);

	if (survivor.valid && stored_melee[client][0]) {

		Weapon weapon_secondary = survivor.slot(1);

		if (weapon_secondary.valid) {

			RollBackWeapon(client, weapon_secondary);
		}
	}

	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname) {

	if (!bBlockListener && StartsWith(classname, "weapon_") && EndsWith(classname, "_spawn"))
		SDKHook(entity, SDKHook_Use, OnWeaponSpawnerUse);
}

Action OnWeaponSpawnerUse(int entity, int activator, int caller, UseType type, float value) {

	if (bBlockListener)
		return Plugin_Continue;

	Survivor survivor = Survivor(caller);

	if (survivor.valid && stored_melee[caller][0]) {

		Weapon weapon_secondary = survivor.slot(1);

		if (weapon_secondary.valid) {

			RollBackWeapon(caller, weapon_secondary);
		}
	}

	return Plugin_Continue;
}

/**
 * @brief Called whenever weapon prepared to drop by plugin l4d_drop
 *
 * @param client		player index to be drop weapon
 * @param weapon		weapon index to be drop
 *
 * @return				Plugin_Continue to continuing dropping,
 * 						Plugin_Changed to change weapon target, otherwise to prevent weapon dropping.
 */

forward Action OnWeaponDrop(int client, int &weapon);

public Action OnWeaponDrop(int client, int &weapon) {

	if (bBlockListener)
		return Plugin_Continue;

	Survivor survivor = Survivor(client);

	if (survivor.valid && stored_melee[client][0]) {

		Weapon weapon_secondary = survivor.slot(1);

		if (weapon_secondary.valid) {

			int after = RollBackWeapon(client, weapon_secondary);

			if (after != -1) {
				weapon = after;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;

}



///////////////////////
// Stocks Below     //
/////////////////////

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

	if (!IsFakeClient(client)) {

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


bool StartsWith(const char[] str, const char[] substr) {
	return strncmp(str, substr, strlen(substr) -1, true) == 0;
}

bool EndsWith(const char[] str, const char[] substr) {
	int n_str = strlen(str) - 1,
		n_substr = strlen(substr) - 1;

	while (n_str != 0 && n_substr != 0) {

		if (str[n_str--] != substr[n_substr--]) {
			return false;
		}
	}

	return true;
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
			return (2048 >= index > MaxClients) && IsValidEntity(index);
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
			return GetEntPropEnt(this.index, Prop_Data, "m_iState");
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
			return GetEntProp(this.index, Prop_Data, "m_iClip1")
		}
		public set(int size) {
			SetEntProp(this.index, Prop_Data, "m_iClip1", size);
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
}
