#define PLUGIN_VERSION	"1.3.1"
#define PLUGIN_NAME		"l4d2_subsistence"

/**
 *	v1.0 just releases; 22-2-22
 *	v1.1 optional 'use generate ammo instead load from reserved', remove unused code; 22-2-22(noon)
 *	v1.1.1 fix issue 'wrong key causes m16 rifle not work'; 24-2-22
 *	v1.2 new feature: 'generate ammo also allow float value to generate part ammo', fix issue 'sometime wrong reserve ammo display'; 1-3-22
 *	v1.3 new ConVar *_allow_bot to control does allow bot to access subsistence,
 *		fix subsistence trigger when weapon not match; 25-November-2022
 *	v1.3.1 fix player kill zombie without weapon; 27-November-2022
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define IsEntity(%1) (2048 >= %1 > MaxClients)

static const char classes[][] = {
	"hunting_rifle", "sniper_military", "sniper_scout", "sniper_awp",
	"pistol_magnum",
	"rifle", "rifle_sg552", "rifle_desert", "rifle_ak47",
	"rifle_m60",
	"smg", "smg_silenced", "smg_mp5",
	"pistol",
	"pumpshotgun", "shotgun_chrome", "autoshotgun", "shotgun_spas",
	"grenade_launcher",
};

ConVar Enabled;
ConVar Allow_weapons;	int allow_weapons;
ConVar Ratio_snipers;	float ratio_snipers;
ConVar Ratio_magnum;	float ratio_magnum;
ConVar Ratio_rifles;	float ratio_rifles;
ConVar Ratio_m60;		float ratio_m60;
ConVar Ratio_smgs;		float ratio_smgs;
ConVar Ratio_pistol;	float ratio_pistol;
ConVar Ratio_shotguns;	float ratio_shotguns;
ConVar Ratio_GL;		float ratio_GL;
ConVar Ratio_smoker;	float ratio_smoker;
ConVar Ratio_boomer;	float ratio_boomer;
ConVar Ratio_hunter;	float ratio_hunter;
ConVar Ratio_spitter;	float ratio_spitter;
ConVar Ratio_jockey;	float ratio_jockey;
ConVar Ratio_charger;	float ratio_charger;
ConVar Ratio_witch;		float ratio_witch;
ConVar Ratio_tank;		float ratio_tank;
ConVar Ratio_headshot;	float ratio_headshot;
ConVar Ratio_common;	float ratio_common;
ConVar Allow_generate;	float allow_generate;
ConVar Allow_bot;		bool allow_bot;

public Plugin myinfo = {
	name = "[L4D2] Killing Ammo / Subsistence (Destiny 2 ability)",
	author = "NoroHime",
	description = "load part ammo to clip by killing zombies like Destiny 2 Subsistence Perk",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {

	CreateConVar("subsistence_version", PLUGIN_VERSION, "Version of 'Subsistence'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enabled = 			CreateConVar("subsistence_enabled", "1",			"Enabled 'Subsistence'", FCVAR_NOTIFY);
	Allow_weapons =		CreateConVar("subsistence_allow_weapons", "-1",		"which allow Subsistence , 1=hunting 2=military 4=scout 8=awp 16=magnum\n32=m16 64=sg552 128=fn_scar 256=ak47 512=m60 1024=uzi 2048=smg_s 4096=mp5\n8192=pistol 16384=pump 32768=chrome 65536=xm1014 131072=spas 262144=GL 524287=all", FCVAR_NOTIFY);
	Ratio_snipers =		CreateConVar("subsistence_ratio_snipers", "0.33",	"luck ratio of snipers ", FCVAR_NOTIFY);
	Ratio_magnum =		CreateConVar("subsistence_ratio_magnum", "0.25",	"luck ratio of magnum ", FCVAR_NOTIFY);
	Ratio_rifles =		CreateConVar("subsistence_ratio_rifles", "1.5",		"luck ratio of rifle ", FCVAR_NOTIFY);
	Ratio_m60 =			CreateConVar("subsistence_ratio_m60", "0.5",		"luck ratio of m60 ", FCVAR_NOTIFY);
	Ratio_smgs =		CreateConVar("subsistence_ratio_smgs", "3",			"luck ratio of smgs ", FCVAR_NOTIFY);
	Ratio_pistol =		CreateConVar("subsistence_ratio_pistol", "2",		"luck ratio of pistol ", FCVAR_NOTIFY);
	Ratio_shotguns =	CreateConVar("subsistence_ratio_shotgun", "0.25",	"luck ratio of shotgun ", FCVAR_NOTIFY);
	Ratio_GL =			CreateConVar("subsistence_ratio_gl", "0.05",		"luck ratio of Grenade Launcher ", FCVAR_NOTIFY);
	Ratio_smoker =		CreateConVar("subsistence_ratio_smoker", "2",		"luck multiplier of smoker ", FCVAR_NOTIFY);
	Ratio_boomer =		CreateConVar("subsistence_ratio_boomer", "1.5",		"luck multiplier of boomer ", FCVAR_NOTIFY);
	Ratio_hunter =		CreateConVar("subsistence_ratio_hunter", "2",		"luck multiplier of hunter ", FCVAR_NOTIFY);
	Ratio_spitter =		CreateConVar("subsistence_ratio_spitter", "1.5",	"luck multiplier of spitter ", FCVAR_NOTIFY);
	Ratio_jockey =		CreateConVar("subsistence_ratio_jockey", "2",		"luck multiplier of jockey ", FCVAR_NOTIFY);
	Ratio_charger =		CreateConVar("subsistence_ratio_charger", "3",		"luck multiplier of charger ", FCVAR_NOTIFY);
	Ratio_witch =		CreateConVar("subsistence_ratio_witch", "8",		"luck multiplier of witch ", FCVAR_NOTIFY);
	Ratio_tank =		CreateConVar("subsistence_ratio_tank", "8",			"luck multiplier of tank ", FCVAR_NOTIFY);
	Ratio_headshot =	CreateConVar("subsistence_ratio_headshot", "1.5",	"luck multiplier of headshot ", FCVAR_NOTIFY);
	Ratio_common =		CreateConVar("subsistence_ratio_common", "1",		"luck multiplier of common zombies ", FCVAR_NOTIFY);
	Allow_generate =	CreateConVar("subsistence_allow_generate", "0.5",	"allow generate ammo instead load from reserved, 0:load from reserved 0.5:generate part ammo", FCVAR_NOTIFY);
	Allow_bot =			CreateConVar("subsistence_allow_bot", "0",			"allow bot use subsistence", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_NAME);

	Enabled.AddChangeHook(Event_ConVarChanged);
	Allow_weapons.AddChangeHook(Event_ConVarChanged);
	Ratio_snipers.AddChangeHook(Event_ConVarChanged);
	Ratio_magnum.AddChangeHook(Event_ConVarChanged);
	Ratio_rifles.AddChangeHook(Event_ConVarChanged);
	Ratio_m60.AddChangeHook(Event_ConVarChanged);
	Ratio_smgs.AddChangeHook(Event_ConVarChanged);
	Ratio_pistol.AddChangeHook(Event_ConVarChanged);
	Ratio_shotguns.AddChangeHook(Event_ConVarChanged);
	Ratio_GL.AddChangeHook(Event_ConVarChanged);
	Ratio_smoker.AddChangeHook(Event_ConVarChanged);
	Ratio_boomer.AddChangeHook(Event_ConVarChanged);
	Ratio_hunter.AddChangeHook(Event_ConVarChanged);
	Ratio_spitter.AddChangeHook(Event_ConVarChanged);
	Ratio_jockey.AddChangeHook(Event_ConVarChanged);
	Ratio_charger.AddChangeHook(Event_ConVarChanged);
	Ratio_witch.AddChangeHook(Event_ConVarChanged);
	Ratio_tank.AddChangeHook(Event_ConVarChanged);
	Ratio_headshot.AddChangeHook(Event_ConVarChanged);
	Ratio_common.AddChangeHook(Event_ConVarChanged);
	Allow_generate.AddChangeHook(Event_ConVarChanged);
	Allow_bot.AddChangeHook(Event_ConVarChanged);
	
	ApplyCvars();
}


public void ApplyCvars() {

	static bool hooked = false;
	bool enabled = Enabled.BoolValue;

	if (enabled && !hooked) {

		HookEvent("player_death", OnPlayerDeath);

		hooked = true;

	} else if (!enabled && hooked) {

		UnhookEvent("player_death", OnPlayerDeath);

		hooked = false;
	}

	allow_weapons = Allow_weapons.IntValue;
	ratio_snipers = Ratio_snipers.FloatValue;
	ratio_magnum = Ratio_magnum.FloatValue;
	ratio_rifles = Ratio_rifles.FloatValue;
	ratio_m60 = Ratio_m60.FloatValue;
	ratio_smgs = Ratio_smgs.FloatValue;
	ratio_pistol = Ratio_pistol.FloatValue;
	ratio_shotguns = Ratio_shotguns.FloatValue;
	ratio_GL = Ratio_GL.FloatValue;
	ratio_smoker = Ratio_smoker.FloatValue;
	ratio_boomer = Ratio_boomer.FloatValue;
	ratio_hunter = Ratio_hunter.FloatValue;
	ratio_spitter = Ratio_spitter.FloatValue;
	ratio_jockey = Ratio_jockey.FloatValue;
	ratio_charger = Ratio_charger.FloatValue;
	ratio_witch = Ratio_witch.FloatValue;
	ratio_tank = Ratio_tank.FloatValue;
	ratio_headshot = Ratio_headshot.FloatValue;
	ratio_common = Ratio_common.FloatValue;
	allow_generate = Allow_generate.FloatValue;
	allow_bot = Allow_bot.BoolValue;
}

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

int LuckyFloat(float floating) {

	int floor = RoundToFloor(floating);

	int luck = (floating - floor) > GetURandomFloat();

	return floor + luck;
}


float GetWeaponRatio(const char[] name) {

	for (int i = 0; i < sizeof(classes); i++)
		if (strcmp(name, classes[i]) == 0 && allow_weapons & (1 << i)) {
			if (0 <= i <= 3) {
				return ratio_snipers;
			}

			if (i == 4) {
				return ratio_magnum;
			}

			if (5 <= i <= 8) {
				return ratio_rifles;
			}

			if (i == 9) {
				return ratio_m60;
			}

			if (10 <= i <= 12) {
				return ratio_smgs;
			}

			if (i == 13) {
				return ratio_pistol;
			}

			if (14 <= i <= 17) {
				return ratio_shotguns;
			}

			if (i == 18) {
				return ratio_GL;
			}
		}

	return 0.0;
}


bool ClipAmmoTransfer(int client, int weapon, int amount) {

	int	clip = Weapon_GetPrimaryClip(weapon),
		reserve = GetReservedAmmo(weapon, client);

	if (amount > 0 && clip > 1) { //clip to reserve

		if (clip - amount < 0) { //reached clip empty

			Weapon_SetPrimaryClip(weapon, 0);
			SetReservedAmmo(weapon, client,  reserve + clip);

		} else {
			
			Weapon_SetPrimaryClip(weapon, clip - amount);
			SetReservedAmmo(weapon, client,  reserve + amount);
		}

		return true;

	} else if (amount < 0 && reserve > 0) { //reserve to clip

		if (reserve + amount < 0) { //reached reserve empty

			Weapon_SetPrimaryClip(weapon, clip + reserve);
			SetReservedAmmo(weapon, client, 0);

		} else {
			
			Weapon_SetPrimaryClip(weapon, clip - amount);
			SetReservedAmmo(weapon, client, reserve + amount);
		}

		return true;
	} else
		return false;
}

void ClipAmmoAdd(int weapon, int amount) {
	int	clip = Weapon_GetPrimaryClip(weapon);
	if (clip + amount > 0)
		Weapon_SetPrimaryClip(weapon, clip + amount);
}

void ReserveAdd(int client, int weapon, int amount) {

	int reserve = GetReservedAmmo(weapon, client);

	if (amount + reserve < 0) {
		SetReservedAmmo(weapon, client, 0);
	} else
		SetReservedAmmo(weapon, client, reserve + amount);
}


public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	static char name_weapon[32], name_victim[32];

	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	event.GetString("weapon", name_weapon, sizeof(name_weapon));
	event.GetString("victimname", name_victim, sizeof(name_victim));

	if ((strcmp("dual_pistols", name_weapon) == 0))
		name_weapon = "pistol";

	float ratio = 1.0;

	if (event.GetBool("headshot")) 
		ratio *= ratio_headshot;

	switch (name_victim[0]) {
		case 'I' : ratio *= ratio_common;
		case 'S' : ratio *= name_victim[1] == 'm' ? ratio_smoker : ratio_spitter;
		case 'B' : ratio *= ratio_boomer;
		case 'H' : ratio *= ratio_hunter;
		case 'J' : ratio *= ratio_jockey;
		case 'C' : ratio *= ratio_charger;
		case 'W' : ratio *= ratio_witch;
		case 'T' : ratio *= ratio_tank;
		default : ratio = 0.0;
	}

	if (ratio && IsSurvivor(attacker) && (allow_bot || !IsFakeClient(attacker))) {

		static char name_weapon_actived[32];

		int weapon_actived = L4D_GetPlayerCurrentWeapon(attacker);
		float ratio_weapon = GetWeaponRatio(name_weapon);
		int ammo_load = LuckyFloat(ratio_weapon * ratio);

		if (IsEntity(weapon_actived)) {

			GetEntityClassname(weapon_actived, name_weapon_actived, sizeof(name_weapon_actived));

			if (StrContains(name_weapon_actived, name_weapon) != 7)
				return;

			if (ammo_load > 0) {

				if (allow_generate)
					ReserveAdd(attacker, weapon_actived, LuckyFloat(ammo_load * allow_generate));

				if (strcmp("pistol", name_weapon) == 0)

					ClipAmmoAdd(weapon_actived, ammo_load);
				else
					ClipAmmoTransfer(attacker, weapon_actived, -ammo_load);

				
			}
		}
	}

}

/*Stocks below*/

stock static int ammo_offset = -1;

stock int GetReservedAmmo(int weapon, int client) {

	if (ammo_offset == -1)
		ammo_offset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

	return GetEntData( client, ammo_offset + Weapon_GetPrimaryAmmoType(weapon) * 4 );
}

stock void SetReservedAmmo(int weapon, int client, int amount) {

	if (ammo_offset == -1)
		ammo_offset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

	SetEntData( client, ammo_offset + Weapon_GetPrimaryAmmoType(weapon) * 4, amount);
}

stock bool IsSurvivor(int client) {
	return IsClient(client) && GetClientTeam(client) == 2;
}

stock bool IsClient(int client) {
	return (1 <= client <= MaxClients) && IsClientInGame(client);
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


// ==================================================
// SMLib (smlib/weapons.inc)
// ==================================================

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

/* (smlib/clients.inc)
 * Gets the primary ammo Type (int offset)
 * 
 * @param weapon		Weapon Entity.
 * @return				Primary ammo type value.
 */
stock int Weapon_GetPrimaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
}