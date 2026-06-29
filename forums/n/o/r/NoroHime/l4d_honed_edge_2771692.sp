#define PLUGIN_VERSION	"1.2.2"
#define PLUGIN_NAME		"l4d2_honed_edge"
#define PLUGIN_PHRASES	"l4d2_honed_edge.phrases"

/**
 *	v1.0 just releases; 2-17-22
 *	v1.1
 *		optional 'play ready/used/fulled sound'
 *		fix issue 'owner netprop wont change when weapon took by others', 
 *		fix issue 'better identification when weapon be destoryed',
 *		prevent error when not loaded tranlastions file,
 *		optimize OnPlayerRunCmd performance; 2-18-22
 *	v1.2
 *		add feature and optional 'restrict clip size after reloaded zipped ammo',
 *		add feature and optional 'save ammo when weapon destoryed', compatible with MultiEquip or WeaponDrop plugin etc. ,
 *		optimize reload, keep reference SMLib,
 *		more 8 randomized Ammo Fire sound effects; 2-19-22
 *	v1.2.1 fix some logic error and stricter entity check; 2-20-22
 *	v1.2.2
 *		optional 'specify zip bullet burning or knock back enemy' may not work with tank,
 *		prevent unstoppable check at reloading, because detect reloaded is hard,
 *		fix issue 'sometime weapon fire too early cause no damage multiply'; 2-21-22
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define SNIPER_HUNTING	(1 << 0)
#define SNIPER_MILITARY	(1 << 1)
#define SNIPER_SCOUT	(1 << 2)
#define SNIPER_AWP		(1 << 3)
#define PISTOL_MAGNUM	(1 << 4)

#define ANNOUNCE_CENTER	(1 << 0)
#define ANNOUNCE_CHAT	(1 << 1)
#define ANNOUNCE_HINT	(1 << 2)

#define SOUND_READY		"level/startwam.wav"
#define SOUND_USED		"ambient/energy/zap%d.wav"
#define SOUND_FULLED	"doors/latchlocked2.wav"

#define PLAY_READY		(1 << 0)
#define PLAY_USED		(1 << 1)
#define PLAY_FULLED		(1 << 2)

#define Witch			(7 - 1)
#define Survivor		(9 - 1)	

static const char classes[][] = {
	"weapon_hunting_rifle",
	"weapon_sniper_military",
	"weapon_sniper_scout",
	"weapon_sniper_awp",
	"weapon_pistol_magnum",
};

static bool hasTranslations;

static const int offsets_ammo[] = {36, 40, 40, 40, 0};

ConVar Enabled;
ConVar Zip_ratio;		float zip_ratio;
ConVar Zip_ammo;		int zip_ammo;
ConVar Zip_max;			int zip_max;
ConVar Allow_weapons;	int allow_weapons;
ConVar Allow_targets;	int allow_targets;
ConVar Announce_type;	int announce_type;
ConVar Time_trigger;	float time_trigger;
ConVar Sounds;			int sounds;
ConVar Allow_restore;	bool allow_restore;
ConVar Zip_restrict;	bool zip_restrict;
ConVar Zip_bullet_type;	int zip_bullet_type;

public Plugin myinfo = {
	name = "[L4D2] Zip Bullet / Honed Edge (Destiny 2 ability)",
	author = "NoroHime",
	description = "Compress Bullets for next Critical Shot like Destiny 2 Inazagi's Burden",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {

	CreateConVar("honed_edge_version", PLUGIN_VERSION, "Version of 'Honed Edge'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enabled = 			CreateConVar("honed_edge_enabled", "1", "Enabled 'Honed Edge'", FCVAR_NOTIFY);
	Zip_ratio = 		CreateConVar("honed_edge_zip_ratio", "0.975", "multiplier of zipped ammo damage, zip 4 ammo cause 4*0.975 damage", FCVAR_NOTIFY);
	Zip_ammo = 			CreateConVar("honed_edge_zip_ammo", "4", "how many ammo zipped you want on once zip", FCVAR_NOTIFY);
	Zip_max = 			CreateConVar("honed_edge_zip_max", "1", "how many zipped ammo max storage on per weapon", FCVAR_NOTIFY);
	Allow_weapons =		CreateConVar("honed_edge_allow_weapons", "31", "which weapon allow zip ammo, 1=hunting rifle 2=military sniper 4=scout sniper 8=awp sniper 16=magnum 31=all listed", FCVAR_NOTIFY);
	Allow_targets =		CreateConVar("honed_edge_allow_targets", "511", "Which Targets should receive Honed Edge, 1=Smoker, 2=Boomer, 4=Hunter, 8=Spitter, 16=Jockey, 32=Charger, 64=Witch, 128=Tank, 256=Survivor, 511=All. Add numbers together.", FCVAR_NOTIFY);
	Announce_type =		CreateConVar("honed_edge_announce_type", "3", "announce ammo 1=center 2=chat 4=hint 7=all add together you want", FCVAR_NOTIFY);
	Time_trigger =		CreateConVar("honed_edge_time_trigger", "0.5", "how long pressed reload to trigger zipping", FCVAR_NOTIFY);
	Sounds =			CreateConVar("honed_edge_sounds", "7", "which sound effect wanna play 1=zip ready 2=zip used 4=ammo fulled 7=All 0=not", FCVAR_NOTIFY);
	Allow_restore =		CreateConVar("honed_edge_allow_restore", "1", "allow restore ammo from owned weapon be destoyed, compatibale with MultiEquip or WeaponDrop plugin", FCVAR_NOTIFY);
	Zip_restrict =		CreateConVar("honed_edge_zip_restrict", "1", "restrict clip size to zipped ammo after reloaded", FCVAR_NOTIFY);
	Zip_bullet_type =	CreateConVar("honed_edge_zip_bullet_type", "8", "specify zipped ammo damage type 64=DMG_BLAST 8=DMG_BURN 0:disable", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_NAME);

	Enabled.AddChangeHook(Event_ConVarChanged);
	Zip_ratio.AddChangeHook(Event_ConVarChanged);
	Zip_ammo.AddChangeHook(Event_ConVarChanged);
	Zip_max.AddChangeHook(Event_ConVarChanged);
	Allow_weapons.AddChangeHook(Event_ConVarChanged);
	Allow_targets.AddChangeHook(Event_ConVarChanged);
	Announce_type.AddChangeHook(Event_ConVarChanged);
	Time_trigger.AddChangeHook(Event_ConVarChanged);
	Sounds.AddChangeHook(Event_ConVarChanged);
	Allow_restore.AddChangeHook(Event_ConVarChanged);
	Zip_restrict.AddChangeHook(Event_ConVarChanged);
	Zip_bullet_type.AddChangeHook(Event_ConVarChanged);

	PrecacheSound(SOUND_READY, false);
	PrecacheSound(SOUND_FULLED, false);
	PrecacheSound("ambient/energy/zap1.wav", false);
	PrecacheSound("ambient/energy/zap2.wav", false);
	PrecacheSound("ambient/energy/zap3.wav", false);
	PrecacheSound("ambient/energy/zap5.wav", false);
	PrecacheSound("ambient/energy/zap6.wav", false);
	PrecacheSound("ambient/energy/zap7.wav", false);
	PrecacheSound("ambient/energy/zap8.wav", false);
	PrecacheSound("ambient/energy/zap9.wav", false);

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", PLUGIN_PHRASES);
	hasTranslations = FileExists(path);

	if (hasTranslations)
		LoadTranslations(PLUGIN_PHRASES);
	
	ApplyCvars();
}

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void ApplyCvars() {

	static bool hooked = false;
	bool enabled = Enabled.BoolValue;

	if (enabled && !hooked) {

		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("witch_spawn", Event_WitchSpawn);
		HookEvent("witch_killed", Event_WitchKilled);
		HookEvent("weapon_fire", Event_WeaponFirePost, EventHookMode_Post);

		hooked = true;

	} else if (!enabled && hooked) {

		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("witch_spawn", Event_WitchSpawn);
		UnhookEvent("witch_killed", Event_WitchKilled);
		UnhookEvent("weapon_fire", Event_WeaponFirePost, EventHookMode_Post);

		hooked = false;
	}

	zip_ratio = Zip_ratio.FloatValue;
	zip_ammo = Zip_ammo.IntValue;
	zip_max = Zip_max.IntValue;
	allow_weapons = Allow_weapons.IntValue;
	allow_targets = Allow_targets.IntValue;
	announce_type = Announce_type.IntValue;
	time_trigger = Time_trigger.FloatValue;
	sounds = Sounds.IntValue;
	allow_restore = Allow_restore.BoolValue;
	zip_restrict = Zip_restrict.BoolValue;
	zip_bullet_type = Zip_bullet_type.IntValue;
}

static int weapon_type[2048 + 1];
static float time_weapon_reload_start[2048 + 1];
static int zipped_remaining[2048 + 1];
static int zipped_remain_by_player[MAXPLAYERS + 1];
static int weapon_owner[2048 + 1];

void Announce(int client, const char[] format, any ...) {

	if (!hasTranslations) return;

	static char buffer[254];
	VFormat(buffer, sizeof(buffer), format, 3);

	if (isClient(client)) {

		if (announce_type & ANNOUNCE_CHAT)
			PrintToChat(client, "%s", buffer);

		if (announce_type & ANNOUNCE_HINT)
			PrintHintText(client, "%s", buffer);

		if (announce_type & ANNOUNCE_CENTER)
			PrintCenterText(client, "%s", buffer);
	}
}

void PlaySound(int client, int operation) {

	static char buffer[63];

	if (isClient(client)) {

		if (sounds & operation & PLAY_READY)
			EmitSoundToClient(client, SOUND_READY, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);

		if (sounds & operation & PLAY_USED) {
			
			int luck = GetRandomInt(1, 9);
			luck = luck == 4 ? 3 : luck; //zap4.wav not exists

			Format(buffer, sizeof(buffer), SOUND_USED, luck);
			EmitSoundToClient(client, buffer, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		}

		if (sounds & operation & PLAY_FULLED)
			EmitSoundToClient(client, SOUND_FULLED, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
}

public void OnEntityCreated(int entity, const char[] classname) {

	for (int i = 0; i < sizeof(classes); i++)
		if (strcmp(classname, classes[i]) == 0 && allow_weapons & (1 << i)) {
			weapon_type[entity] = (1 << i);
			SDKHook(entity, SDKHook_ReloadPost, Event_ReloadPost);
		}
}

public void OnEntityDestroyed(int entity) {

	if (entity > 0 && weapon_type[entity]) {

		int owner = Weapon_GetOwner(entity);
		if (allow_restore && owner > 0)
			zipped_remain_by_player[owner] = zipped_remaining[entity];

		weapon_type[entity] = 0;
		weapon_owner[entity] = 0;
		zipped_remaining[entity] = 0;

		SDKUnhook(entity, SDKHook_ReloadPost, Event_ReloadPost);
	}
}

public void Event_ReloadPost(int weapon, bool agree) {

	int owner = Weapon_GetOwner(weapon);
	int buttons = GetClientButtons(owner);
	float time = GetGameTime();


	if (agree && buttons & IN_RELOAD) 
		time_weapon_reload_start[weapon] = time;

	if (agree && zip_restrict) {
		CreateTimer(0.1, OnReloadSuccess, weapon, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (!agree && !Weapon_IsReloading(weapon)) {
		ClipTransferReserved(weapon, 1);
	}
}


public Action OnReloadSuccess(Handle timer, int weapon) {

	if (zip_restrict && isValidWeapon(weapon)) {

		if (Weapon_IsReloading(weapon))
			return Plugin_Continue;

		int	owner = Weapon_GetOwner(weapon),
			owner_active = L4D_GetPlayerCurrentWeapon(owner),
			clip  = Weapon_GetPrimaryClip(weapon);

		if (owner_active == weapon && zipped_remaining[weapon] > 0)

			if (clip > 0)
				ClipTransferReserved(weapon, clip - zipped_remaining[weapon]);
	}

	return Plugin_Stop;
}

bool ClipTransferReserved(int weapon, int amount) {

	int	clip = Weapon_GetPrimaryClip(weapon),
		ammo = GetReservedAmmo(weapon);

	if (amount > 0 && clip > 1) {

		Weapon_SetPrimaryClip(weapon, clip - amount);
		SetReservedAmmo(weapon, ammo + amount);

		return true;

	} else if (amount < 0 && ammo > 0) {

		Weapon_SetPrimaryClip(weapon, clip - amount);
		SetReservedAmmo(weapon, ammo + amount);

		return true;
	} else
		return false;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon_switched, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {

	static int buttons_last[MAXPLAYERS + 1];

	int		reloading = buttons & IN_RELOAD;
	bool	reload_released = !(buttons & IN_RELOAD) && (buttons_last[client] & IN_RELOAD);

	if (reloading || reload_released) {

		int weapon = L4D_GetPlayerCurrentWeapon(client);
		float time = GetGameTime();

		if (weapon > 0 && weapon_type[weapon] > 0) {

			if (reload_released)
				time_weapon_reload_start[weapon] = 0.0;

			if (
				reloading && time_weapon_reload_start[weapon] && 
				(time - time_weapon_reload_start[weapon]) > time_trigger
			) {
				if (zipped_remaining[weapon] < zip_max)

					ZipAmmo(client, weapon, 1);

				else {

					Announce(client, "%T", "Honed Edge Full", client);
					PlaySound(client, PLAY_FULLED);
				}

				time_weapon_reload_start[weapon] = 0.0;
			}
		}
	}

	buttons_last[client] = buttons;

	return Plugin_Continue;
}

void ZipAmmo(int client, int weapon, int amount) {

	int ammo = GetReservedAmmo(weapon);

	if (ammo > zip_ammo * amount) {

		SetReservedAmmo(weapon, ammo - (zip_ammo - 1 ) * amount);
		zipped_remaining[weapon] += amount;

	} else {

		if (ammo < zip_ammo)

			return;

		else {

			zipped_remaining[weapon] += ammo / zip_ammo;
			SetReservedAmmo(weapon, ammo % zip_ammo);
		}
	}

	Announce(client, "%T", "Honed Edge Left", client, zip_ammo, zipped_remaining[weapon]);

	PlaySound(client, PLAY_READY);
}

void HookTarget(int client) {
	int team = GetClientTeam(client);

	switch (team) {
		case 2: {
			if (allow_targets & (1 << Survivor)) {
				SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			}
		}
		case 3: {

			int class = GetEntProp(client, Prop_Send, "m_zombieClass");
			if (allow_targets & (1 << (class - 1)))
				SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
}

void UnhookTarget(int client) {
	int team = GetClientTeam(client);

	switch (team) {
		case 2: {
			if (allow_targets & (1 << Survivor)) 
				SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			
		}
		case 3: {
			int class = GetEntProp(client, Prop_Send, "m_zombieClass");

			if (allow_targets & (1 << (class - 1)))
				SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
}

public void Event_WeaponFirePost(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid")),
		weapon = L4D_GetPlayerCurrentWeapon(client);

	if (weapon > 0 && weapon_type[weapon] && zipped_remaining[weapon] > 0) {

		RequestFrame(ConsumeAmmo, weapon);
		PlaySound(client, PLAY_USED);
		Announce(client, "%T", "Honed Edge Left", client, zip_ammo, zipped_remaining[weapon]);
	}
}

public void ConsumeAmmo(int weapon) {

	if (zipped_remaining[weapon] > 0)
		zipped_remaining[weapon]--;
}

public void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast) {

	int witch = event.GetInt("witchid");

	if (witch && allow_targets & (1 << Witch))
		SDKHook(witch, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast) {

	int witch = event.GetInt("witchid");

	if (witch && allow_targets & (1 << Witch))
		SDKUnhook(witch, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (isClient(client)) {

		HookTarget(client);
		SDKHook(client, SDKHook_WeaponSwitchPost, Event_WeaponSwitchPost);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (isClient(client)) {

		UnhookTarget(client);
		SDKUnhook(client, SDKHook_WeaponSwitchPost, Event_WeaponSwitchPost);
	}
}

public void Event_WeaponSwitchPost(int client, int weapon) {

	if (isHumanSurvivor(client)) {

		if (allow_restore && zipped_remain_by_player[client] && weapon_type[weapon]) {

			zipped_remaining[weapon] = zipped_remain_by_player[client];
			zipped_remain_by_player[client] = 0;
		}

		if (zipped_remaining[weapon]) {
			Weapon_SetOwner(weapon, client);
			Announce(client, "%T", "Honed Edge Left", client, zip_ammo, zipped_remaining[weapon]);
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {

	if (weapon > 0 && zipped_remaining[weapon] > 0 && isClient(attacker)) {

		damage *= zip_ammo * zip_ratio;
		damagetype |= zip_bullet_type;

		return Plugin_Changed;
	}

	return Plugin_Continue;
}


/*Stocks below*/


static int ammo_offset = -1;

stock int GetReservedAmmo(int weapon) {

	if (ammo_offset == -1)
		ammo_offset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

	return GetEntData(Weapon_GetOwner(weapon), ammo_offset + offsets_ammo[GetBitClosestPosition(weapon_type[weapon])]);
}

stock void SetReservedAmmo(int weapon, int amount) {

	if (ammo_offset == -1)
		ammo_offset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

	SetEntData(Weapon_GetOwner(weapon), ammo_offset + offsets_ammo[GetBitClosestPosition(weapon_type[weapon])], amount);
}

stock int GetBitClosestPosition(int integer) {
	for (int bit = 0; bit < 32; bit++) {
		if (integer & (1 << bit))
			return bit;
	}
	return -1;
}

stock bool isHumanSurvivor(int client) {
	return isSurvivor(client) && !IsFakeClient(client);
}

stock bool isSurvivor(int client) {
	return isClient(client) && GetClientTeam(client) == 2;
}

stock bool isInfected(int client) {
	return isClient(client) && GetClientTeam(client) == 3;
}

stock bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientInGame(client);
}

stock bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
}

stock bool isValidWeapon(int entity) {

	if (entity > 0 && IsValidEdict(entity)) {

		static char name[32];
		GetEntityClassname(entity, name, sizeof(name));

		if (StrContains(name, "weapon_") == 0) {
			return true;
		}
	}
	if (entity > 0) {

		zipped_remaining[entity] = 0;
		weapon_type[entity] = 0;
	}
	return false;
}


// ==================================================
// ENTITY STOCKS (left4dhooks_stocks.inc)
// ==================================================

/**
 * @brief Returns a players current weapon, or -1 if none.
 *
 * @param client			Client ID of the player to check
 *
 * @return weapon entity index or -1 if none
 */
stock int L4D_GetPlayerCurrentWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}


/**
 * (left4dhooks.inc)
 * Returns whether weapon is upgrade compatible.
 *
 * @param weapon		Weapon entity index.
 * @return				True if compatible with upgrades, false otherwise.
 * @error				Invalid entity index.
 */
stock bool L4D2_IsWeaponUpgradeCompatible(int weapon)
{
	char netclass[128];
	GetEntityNetClass(weapon, netclass, sizeof(netclass));
	return FindSendPropInfo(netclass, "m_upgradeBitVec") > 0;
}

/**
 * Returns upgraded ammo count for weapon.
 *
 * @param weapon		Weapon entity index.
 * @return				Upgraded ammo count.
 * @error				Invalid entity index.
 */
// L4D2 only.
stock int L4D2_GetWeaponUpgradeAmmoCount(int weapon)
{
	return HasEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") && GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
}

/**
 * Set upgraded ammo count in weapon.
 *
 * @param weapon		Weapon entity index.
 * @param count			Upgraded ammo count.
 * @noreturn
 * @error				Invalid entity index.
 */
// L4D2 only.
stock void L4D2_SetWeaponUpgradeAmmoCount(int weapon, int count)
{
	if( HasEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") )
	{
		SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", count);
	}
}


// ==================================================
// SMLib (smlib/weapons.inc)
// ==================================================
// 

/* 
 * Gets the owner (usually a client) of the weapon
 * 
 * @param weapon		Weapon Entity.
 * @return				Owner of the weapon or INVALID_ENT_REFERENCE if the weapon has no owner.
 */
stock int Weapon_GetOwner(int weapon)
{
	int record = weapon_owner[weapon];
	return  record > 0 ? record : GetEntPropEnt(weapon, Prop_Data, "m_hOwner");
}

/*
 * Sets the owner (usually a client) of the weapon
 * 
 * @param weapon		Weapon Entity.
 * @param entity		Entity Index.
 * @noreturn
 */
stock void Weapon_SetOwner(int weapon, int entity)
{
	weapon_owner[weapon] = entity;
	SetEntPropEnt(weapon, Prop_Data, "m_hOwner", entity);
}

/*
 * Gets the primary clip count of a weapon.
 * 
 * @param weapon		Weapon Entity.
 * @return				Primary Clip count.
 */
stock int Weapon_GetPrimaryClip(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip1");
}

/*
 * Sets the primary clip count of a weapon.
 * 
 * @param weapon		Weapon Entity.
 * @param value			Clip Count value.
 */
stock void Weapon_SetPrimaryClip(int weapon, int value)
{
	SetEntProp(weapon, Prop_Data, "m_iClip1", value);
}


/*
 * Is the weapon currently reloading ?
 * 
 * @param weapon		Weapon Entity.
 * @return				True if weapon is currently reloading, false if not.
 */
stock bool Weapon_IsReloading(int weapon)
{
	return HasEntProp(weapon, Prop_Data, "m_bInReload") && (GetEntProp(weapon, Prop_Data, "m_bInReload"));
}