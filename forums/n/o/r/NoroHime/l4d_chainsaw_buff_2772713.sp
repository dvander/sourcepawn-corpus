#define PLUGIN_VERSION	"1.2.1"
#define PLUGIN_NAME		"l4d_chainsaw_buff"

/**
 *	v1.0 (28-2-22)
 *		- just releases
 *	v1.1 (28-2-22)
 *		- add feature resistant receive damage when firing, fix an issue
 *	v1.1.1 (1-3-22)
 *		- fix an issue 'player sometime not weapon on hand cause error'
 *	v1.1.2 (1-3-22-afternoon)
 *		- fix a logic error thanks "ddd123", this is something i have neglected for a long time
 *	v1.2 (2-3-22)
 *		- optional 'refill or chance gain fuel when hit', solve 'instantly kill wont trigger hit action'
 *	v1.2.1 (26-May-2022)
 *		- fix damage resistant not work sometime like tank punch
 *		- temp health cant over than max hp now
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

ConVar Enabled;
ConVar Fire_adrenaline;	float fire_adrenaline;
ConVar Fire_buff;		float fire_buff;
ConVar Hit_adrenaline;	float hit_adrenaline;
ConVar Hit_buff;		float hit_buff;
ConVar Hit_refill;		float hit_refill;
ConVar Fire_resistance;	float fire_resistance;

public Plugin myinfo = {
	name = "[L4D & L4D2] Chainsaw Buff",
	author = "NoroHime",
	description = "make chainsaw great again",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {

	CreateConVar("chainsaw_buff_version", PLUGIN_VERSION,		"Version of 'Chainsaw Buff'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enabled = 			CreateConVar("chainsaw_buff_enabled", "1",				"Enabled 'Chainsaw Buff'", FCVAR_NOTIFY);
	Fire_adrenaline = 	CreateConVar("chainsaw_buff_fire_adrenaline", "0.02",	"gain adrenaline duration when every firing", FCVAR_NOTIFY);
	Fire_buff = 		CreateConVar("chainsaw_buff_fire_buff", "0.03",			"gain buff health when every firing", FCVAR_NOTIFY);
	Hit_adrenaline = 	CreateConVar("chainsaw_buff_hit_adrenaline", "0.1",		"gain adrenaline duration when hitted", FCVAR_NOTIFY);
	Hit_buff = 			CreateConVar("chainsaw_buff_hit_buff", "0.1",			"gain buff health when hitted", FCVAR_NOTIFY);
	Hit_refill = 		CreateConVar("chainsaw_buff_hit_refill", "-1",			"refill the fuel when hitted -1:refil whole clip 0.5:half chance gain 1sec fuel 1:certainly gain 1sec 0:nope", FCVAR_NOTIFY);
	Fire_resistance = 	CreateConVar("chainsaw_buff_fire_res", "0.5",			"resistant receive damages when firing, negative:add damage 1:invinsible", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_NAME);

	Enabled.AddChangeHook(Event_ConVarChanged);
	Fire_adrenaline.AddChangeHook(Event_ConVarChanged);
	Fire_buff.AddChangeHook(Event_ConVarChanged);
	Hit_adrenaline.AddChangeHook(Event_ConVarChanged);
	Hit_buff.AddChangeHook(Event_ConVarChanged);
	Hit_refill.AddChangeHook(Event_ConVarChanged);
	Fire_resistance.AddChangeHook(Event_ConVarChanged);

	ApplyCvars();
}

public void ApplyCvars() {

	static bool hooked = false;
	bool enabled = Enabled.BoolValue;

	if (enabled && !hooked) {

		HookEvent("infected_hurt", OnInfectedHurt);
		HookEvent("player_hurt", OnInfectedHurt);
		HookEvent("player_death", OnInfectedHurt);
		HookEvent("weapon_fire", OnWeaponFire);

		hooked = true;

	} else if (!enabled && hooked) {

		UnhookEvent("infected_hurt", OnInfectedHurt);
		UnhookEvent("player_hurt", OnInfectedHurt);
		UnhookEvent("player_death", OnInfectedHurt);
		UnhookEvent("weapon_fire", OnWeaponFire);

		hooked = false;
	}

	fire_adrenaline = Fire_adrenaline.FloatValue;
	fire_buff = Fire_buff.FloatValue;
	hit_adrenaline = Hit_adrenaline.FloatValue;
	hit_buff = Hit_buff.FloatValue;
	hit_refill = Hit_refill.FloatValue;
	fire_resistance = Fire_resistance.FloatValue;
}

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

#define WEAPONID_CHAINSAW 20

static bool chainsaw_prepared[MAXPLAYERS + 1];

public void OnWeaponFire(Event event, const char[] name, bool dontBroadcast) {

	if ((fire_adrenaline || fire_buff) && event.GetInt("weaponid") == WEAPONID_CHAINSAW) {

		int	client = GetClientOfUserId(event.GetInt("userid"));

		if (IsAliveSurvivor(client)) {

			if (fire_adrenaline)
				AddAdrenaline(client, fire_adrenaline);

			if (fire_buff)
				AddBuffHealth(client, fire_buff);
		}
	}
}
public void OnInfectedHurt(Event event, const char[] name, bool dontBroadcast) {

	static char name_weapon[32];

	if (hit_adrenaline || hit_buff || hit_refill) {

		event.GetString("weapon", name_weapon, sizeof(name_weapon));
		int	attacker = GetClientOfUserId(event.GetInt("attacker"));

		if (strcmp(name_weapon, "chainsaw") == 0 && IsAliveSurvivor(attacker)) {

			if (hit_refill) {

				int weapon = L4D_GetPlayerCurrentWeapon(attacker);

				if (hit_refill == -1)
					Weapon_SetPrimaryClip(weapon, 30);
				else
					AddAmmo(weapon, LuckyFloat(hit_refill));
			}
			
			if (hit_adrenaline)
				AddAdrenaline(attacker, hit_adrenaline);

			if (hit_buff)
				AddBuffHealth(attacker, hit_buff);

		}
	}
}

int LuckyFloat(float floating) {

	int floor = RoundToFloor(floating);

	int luck = (floating - floor) > GetURandomFloat();

	return floor + luck;
}

public void OnClientPutInServer(int client) {

	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect_Post(int client) {

	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype) {

	if (fire_resistance && chainsaw_prepared[victim] && (GetClientButtons(victim) & IN_ATTACK)) {

		if (fire_resistance >= 1.0)
			return Plugin_Stop;
		else
			damage *= fire_resistance;
	}
	return Plugin_Changed;
}

public void OnWeaponSwitchPost(int client, int weapon) {

	static char name_weapon[32];

	if (IsAliveSurvivor(client) && IsValidEntity(weapon)) {
		GetEntityClassname(weapon, name_weapon, sizeof(name_weapon));

		if (strcmp(name_weapon, "weapon_chainsaw") == 0)
			chainsaw_prepared[client] = true;
		else
			chainsaw_prepared[client] = false;
	}
}

void AddBuffHealth(int client, float amount) {

	int hp = GetClientHealth(client);
	float thp = GetTempHealth(client);

	int maxhp = GetEntProp(client, Prop_Send, "m_iMaxHealth");

	if (amount + hp + thp < maxhp)
		SetTempHealth(client, thp + amount);
}

void AddAdrenaline(int client, float duration) {
	Terror_SetAdrenalineTime(client, Terror_GetAdrenalineTime(client) + duration);
}

void AddAmmo(int weapon, int amount) {

	int remain = Weapon_GetPrimaryClip(weapon);

	if (remain + amount > 0)
		Weapon_SetPrimaryClip(weapon, remain + amount);
}

/*Stocks below*/

stock bool IsAliveSurvivor(int client) {
	return IsClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

stock bool IsClient(int client) {
	return IsClientIndex(client) && IsClientInGame(client);
}

stock bool IsClientIndex(int client) {
	return (1 <= client <= MaxClients);
}

// ====================================================================================================
//										STOCKS - HEALTH (left4dhooks.sp, left4dhooks_stocks.inc)
// ====================================================================================================

/**
 * Sets the adrenaline effect duration of a survivor.
 *
 * @param iClient		Client index of the survivor.
 * @param flDuration		Duration of the adrenaline effect.
 *
 * @error			Invalid client index.
 **/
// L4D2 only.
stock void Terror_SetAdrenalineTime(int iClient, float flDuration)
{
	// Get CountdownTimer address
	static int timerAddress = -1;
	if(timerAddress == -1)
	{
		timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
	}
	
	//timerAddress + 4 = Duration
	//timerAddress + 8 = TimeStamp
	SetEntDataFloat(iClient, timerAddress + 4, flDuration);
	SetEntDataFloat(iClient, timerAddress + 8, GetGameTime() + flDuration);
	SetEntProp(iClient, Prop_Send, "m_bAdrenalineActive", (flDuration <= 0.0 ? 0 : 1), 1);
}

/**
 * Returns the remaining duration of a survivor's adrenaline effect.
 *
 * @param iClient		Client index of the survivor.
 *
 * @return 			Remaining duration or -1.0 if there's no effect.
 * @error			Invalid client index.
 **/
// L4D2 only.
stock float Terror_GetAdrenalineTime(int iClient)
{
	// Get CountdownTimer address
	static int timerAddress = -1;
	if(timerAddress == -1)
	{
		timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
	}
	
	//timerAddress + 8 = TimeStamp
	float flGameTime = GetGameTime();
	float flTime = GetEntDataFloat(iClient, timerAddress + 8);
	if(flTime <= flGameTime)
		return 0.0;
	
	return flTime - flGameTime;
}

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


float GetTempHealth(int client)
{
	static ConVar painPillsDecayCvar;
	if (painPillsDecayCvar == null)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == null)
		{
			return 0.0;
		}
	}

	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * painPillsDecayCvar.FloatValue;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

// ====================================================================================================
//										STOCKS - WEAPONS (smlib/weapons.inc)
// ====================================================================================================

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