#define PLUGIN_VERSION "1.2.2"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

/*
 *	v1.0 just releases; 2-2-22
 *	v1.1 add feature: gain adrenaline duration when pills used, userid bug fix; 4-2-22
 *	v1.2 add feature: combo system - duraion increase for combo kill by exponential growth, optional: cooldown time and exponent multiplier; 16-2-22
 *	v1.2.1 pills extra adrenaline ignore option 'allow_cooling', remove unsafe feature 'stack adrenaline', please go to plugin 'Medicines No More Limited';  26-2-22
 *	v1.2.2 fix wrong adrenaline duration, thanks to Silvers, fix witch not trigger; 17-October-2022
 *
*/

GlobalForward OnAdrenalineGiven;

ConVar Enable;
ConVar Adrenaline_duration_base;	float adrenaline_duration_base;
ConVar Adrenaline_allow_cooling;	bool adrenaline_allow_cooling;
ConVar Adrenaline_allow_bot;		bool adrenaline_allow_bot;

ConVar Adrenaline_headshot_ratio;	float adrenaline_headshot_ratio;
ConVar Adrenaline_melee_ratio;		float adrenaline_melee_ratio;
ConVar Adrenaline_distance_max;		float adrenaline_distance_max;
ConVar Adrenaline_distance_ratio;	float adrenaline_distance_ratio;
ConVar Adrenaline_piped_ratio;		float adrenaline_piped_ratio;
ConVar Adrenaline_grenade_ratio;	float adrenaline_grenade_ratio;

ConVar Adrenaline_tank_ratio;		float adrenaline_tank_ratio;
ConVar Adrenaline_witch_ratio;		float adrenaline_witch_ratio;

ConVar Adrenaline_boomer_ratio;		float adrenaline_boomer_ratio;
ConVar Adrenaline_smoker_ratio;		float adrenaline_smoker_ratio;
ConVar Adrenaline_hunter_ratio;		float adrenaline_hunter_ratio;
ConVar Adrenaline_spitter_ratio;	float adrenaline_spitter_ratio;
ConVar Adrenaline_jockey_ratio;		float adrenaline_jockey_ratio;
ConVar Adrenaline_charger_ratio;	float adrenaline_charger_ratio;
ConVar Adrenaline_pills_gain;		float adrenaline_pills_gain;
ConVar Adrenaline_duration_full;	float adrenaline_duration_full;
ConVar Adrenaline_combo_time;		float adrenaline_combo_time;
ConVar Adrenaline_combo_ratio;		float adrenaline_combo_ratio;

public Plugin myinfo = {
	name = "[L4D2] Killing Adrenaline",
	author = "NoroHime",
	description = "Adrenaline Duration increases by killing",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	RegPluginLibrary("l4d2_killing_adrenaline");

	return APLRes_Success;
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void ApplyCvars() {

	static bool hooked = false;
	bool enabled = Enable.BoolValue;

	if (enabled && !hooked) {

		HookEvent("player_death", OnPlayerDeath);
		HookEvent("pills_used", OnPillsUsed);

		hooked = true;

	} else if (!enabled && hooked) {

		UnhookEvent("player_death", OnPlayerDeath);
		UnhookEvent("pills_used", OnPillsUsed);

		hooked = false;
	}

	adrenaline_duration_base = Adrenaline_duration_base.FloatValue;

	adrenaline_allow_cooling = Adrenaline_allow_cooling.BoolValue;
	adrenaline_allow_bot = Adrenaline_allow_bot.BoolValue;

	adrenaline_headshot_ratio = Adrenaline_headshot_ratio.FloatValue;
	adrenaline_melee_ratio = Adrenaline_melee_ratio.FloatValue;
	adrenaline_distance_max = Adrenaline_distance_max.FloatValue;
	adrenaline_distance_ratio = Adrenaline_distance_ratio.FloatValue;
	adrenaline_piped_ratio = Adrenaline_piped_ratio.FloatValue;
	adrenaline_grenade_ratio = Adrenaline_grenade_ratio.FloatValue;

	adrenaline_tank_ratio = Adrenaline_tank_ratio.FloatValue;
	adrenaline_witch_ratio = Adrenaline_witch_ratio.FloatValue;
	adrenaline_boomer_ratio = Adrenaline_boomer_ratio.FloatValue;
	adrenaline_smoker_ratio = Adrenaline_smoker_ratio.FloatValue;
	adrenaline_hunter_ratio = Adrenaline_hunter_ratio.FloatValue;
	adrenaline_spitter_ratio = Adrenaline_spitter_ratio.FloatValue;
	adrenaline_jockey_ratio = Adrenaline_jockey_ratio.FloatValue;
	adrenaline_charger_ratio = Adrenaline_charger_ratio.FloatValue;
	adrenaline_pills_gain = Adrenaline_pills_gain.FloatValue;
	adrenaline_duration_full = Adrenaline_duration_full.FloatValue;
	adrenaline_combo_time = Adrenaline_combo_time.FloatValue;
	if (adrenaline_combo_time < 0)
		adrenaline_combo_time = adrenaline_duration_base;
	adrenaline_combo_ratio = Adrenaline_combo_ratio.FloatValue;
}

public void OnPluginStart() {
	CreateConVar("killing_adrenaline_version", PLUGIN_VERSION, "Version of Killing Adrenaline", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enable =					CreateConVar("killing_adrenaline_enable", "1", "Killing Adrenaline enable", FCVAR_NOTIFY);
	Adrenaline_duration_base =	CreateConVar("killing_adrenaline_duration_base", "0.33", "normal kill one zombie will increase this adrenaline duration", FCVAR_NOTIFY, true, 0.1);
	Adrenaline_headshot_ratio =	CreateConVar("killing_adrenaline_headshot_ratio", "1.5", "duration multiplier of headshot kill", FCVAR_NOTIFY, true, 0.0);

	Adrenaline_distance_max =	CreateConVar("killing_adrenaline_distance_max", "1200", "to get max distance multiplier, how long", FCVAR_NOTIFY, true, 220.0);
	Adrenaline_distance_ratio =	CreateConVar("killing_adrenaline_distance_ratio", "1.5", "if kill distance close to max, multiplier also close to x1.5, nearest is x1", FCVAR_NOTIFY, true, 1.0);

	Adrenaline_piped_ratio =	CreateConVar("killing_adrenaline_piped_ratio", "0.85", "duration multiplier of pipe bomb kill", FCVAR_NOTIFY, true, 0.0);
	Adrenaline_melee_ratio =	CreateConVar("killing_adrenaline_melee_ratio", "1.16", "duration multiplier of melee kill", FCVAR_NOTIFY, true, 0.0);
	Adrenaline_grenade_ratio =	CreateConVar("killing_adrenaline_grenade_ratio", "0.75", "duration multiplier of grenade launcher kill", FCVAR_NOTIFY, true, 0.0);

	Adrenaline_tank_ratio =		CreateConVar("killing_adrenaline_tank_ratio", "32", "duration multiplier of tank", FCVAR_NOTIFY, true, 0.0);
	Adrenaline_witch_ratio =	CreateConVar("killing_adrenaline_witch_ratio", "32", "duration multiplier of witch", FCVAR_NOTIFY, true, 0.0);

	Adrenaline_boomer_ratio =	CreateConVar("killing_adrenaline_boomer_ratio", "1.33", "duration multiplier of boomer", FCVAR_NOTIFY, true, 0.0);
	Adrenaline_smoker_ratio =	CreateConVar("killing_adrenaline_smoker_ratio", "1.33", "duration multiplier of smoker", FCVAR_NOTIFY, true, 0.0);
	Adrenaline_hunter_ratio =	CreateConVar("killing_adrenaline_hunter_ratio", "1.25", "duration multiplier of hunter", FCVAR_NOTIFY, true, 0.0);
	Adrenaline_spitter_ratio =	CreateConVar("killing_adrenaline_spitter_ratio", "1.2", "duration multiplier of spitter", FCVAR_NOTIFY, true, 0.0);
	Adrenaline_jockey_ratio =	CreateConVar("killing_adrenaline_jockey_ratio", "1.25", "duration multiplier of jockey", FCVAR_NOTIFY, true, 0.0);
	Adrenaline_charger_ratio =	CreateConVar("killing_adrenaline_charger_ratio", "1.5", "duration multiplier of charger", FCVAR_NOTIFY, true, 0.0);

	Adrenaline_allow_cooling =	CreateConVar("killing_adrenaline_allow_cooling", "1", "allow increase duration even player not under adrenaline", FCVAR_NOTIFY, true, 0.0);
	Adrenaline_allow_bot =		CreateConVar("killing_adrenaline_allow_bot", "1", "allow bot increase duration", FCVAR_NOTIFY, true, 0.0);
	Adrenaline_pills_gain =		CreateConVar("killing_adrenaline_pills_gain", "0.5", "also gain adrenaline when use pain pills, 0.5: half of ConVar 'adrenaline_duration' 0: disable", FCVAR_NOTIFY, true, 0.0);
	Adrenaline_duration_full =	FindConVar("adrenaline_duration");
	Adrenaline_combo_time =		CreateConVar("killing_adrenaline_combo_time", "-1", "combo time, between prev kill mean you make a combo, -1: same as 'duration_base', 0: disable combo", FCVAR_NOTIFY, true, -1.0);
	Adrenaline_combo_ratio =	CreateConVar("killing_adrenaline_combo_ratio", "1.072", "exponential growth ratio, 10x combo mean 0.33*1.072^10=0.66 doubling on every 10x", FCVAR_NOTIFY, true, 1.0);

	AutoExecConfig(true, "l4d2_Killing_Adrenaline");

	Enable.AddChangeHook(OnConVarChanged);
	Adrenaline_duration_base.AddChangeHook(OnConVarChanged);
	Adrenaline_headshot_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_distance_max.AddChangeHook(OnConVarChanged);
	Adrenaline_distance_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_piped_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_melee_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_grenade_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_tank_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_witch_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_boomer_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_smoker_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_hunter_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_spitter_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_jockey_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_charger_ratio.AddChangeHook(OnConVarChanged);
	Adrenaline_allow_cooling.AddChangeHook(OnConVarChanged);
	Adrenaline_allow_bot.AddChangeHook(OnConVarChanged);
	Adrenaline_pills_gain.AddChangeHook(OnConVarChanged);
	Adrenaline_duration_full.AddChangeHook(OnConVarChanged);
	Adrenaline_combo_time.AddChangeHook(OnConVarChanged);
	Adrenaline_combo_ratio.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	OnAdrenalineGiven = new GlobalForward("OnAdrenalineGiven", ET_Ignore, Param_Cell, Param_Cell);
}


public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	static float time_kill_last[MAXPLAYERS + 1];
	static float combo[MAXPLAYERS + 1];


	static char weapon[32], victimname[32];
	static float victim_pos[3];

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	event.GetString("victimname", victimname, sizeof(victimname));
	event.GetString("weapon", weapon, sizeof(weapon));
	float time = GetEngineTime();


	victim_pos[0] = event.GetFloat("victim_x");
	victim_pos[1] = event.GetFloat("victim_y");
	victim_pos[2] = event.GetFloat("victim_z");

	bool isHeadshot = event.GetBool("headshot");
	bool isPiped = strcmp(weapon, "pipe_bomb") == 0;
	bool isMelee = strcmp(weapon, "melee") == 0;
	bool isGrenade = StrContains(weapon, "projectile") != -1;

	float ratio = 1.0;

	if (adrenaline_combo_time > 0) {
		if (time_kill_last[attacker]) 
			if (time - time_kill_last[attacker] <= adrenaline_combo_time)
				combo[attacker]++;
			else
				combo[attacker] = 1.0;
		else
			combo[attacker] = 1.0;

		time_kill_last[attacker] = time;

		ratio *= Pow(adrenaline_combo_ratio, combo[attacker] - 1.0);
	}

	if (isPiped)
		ratio *= adrenaline_piped_ratio;

	if (isHeadshot && !isPiped && !isGrenade)
		ratio *= adrenaline_headshot_ratio;

	if (isMelee)
		ratio *= adrenaline_melee_ratio;

	if (isGrenade)
		ratio *= adrenaline_grenade_ratio;

	if (isClient(attacker)) {

		float attacker_pos[3];
		GetClientAbsOrigin(attacker, attacker_pos);
		ratio *= 1.0 + (adrenaline_distance_ratio - 1) * ((GetVectorDistance(attacker_pos, victim_pos, false) / adrenaline_distance_max));
	}

	switch (victimname[0]) {
		case 'I' : ratio *= adrenaline_duration_base;
		case 'S' : ratio *= victimname[1] == 'm' ? adrenaline_smoker_ratio : adrenaline_spitter_ratio;
		case 'B' : ratio *= adrenaline_boomer_ratio;
		case 'H' : ratio *= adrenaline_hunter_ratio;
		case 'J' : ratio *= adrenaline_jockey_ratio;
		case 'C' : ratio *= adrenaline_charger_ratio;
		case 'W' : ratio *= adrenaline_witch_ratio;
		case 'T' : ratio *= adrenaline_tank_ratio;
	}

	AddAdrenaline(attacker, ratio);
}

float AddAdrenaline(int client, float duration, bool force = false) {
	if (isSurvivorAlive(client)) {

		float remaining = Terror_GetAdrenalineTime(client);

		remaining = (remaining > 0) ? remaining : 0.0;

		if ( (adrenaline_allow_bot || !IsFakeClient(client)) && (adrenaline_allow_cooling || remaining || force) ) {
			
			Terror_SetAdrenalineTime(client, remaining + duration);

			Call_StartForward(OnAdrenalineGiven); //event forwarding
			Call_PushCell(client);
			Call_PushCell(duration);
			Call_Finish();

			return remaining + duration;

		} else 
			return remaining;

	} else 
		return 0.0;
	
}

public void OnPillsUsed(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (adrenaline_pills_gain > 0 && isSurvivorAlive(client)) {
		AddAdrenaline(client, adrenaline_pills_gain * adrenaline_duration_full, true);
	}
}


stock bool isSurvivorAlive(int client) {
	return isSurvivor(client) && IsPlayerAlive(client);
}

stock bool isSurvivor(int client) {
	return isClient(client) && GetClientTeam(client) == 2;
}

stock bool isInfected(int client) {
	return isClient(client) && GetClientTeam(client) == 3;
}

stock bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client);
}

stock bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
}

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
		return -1.0;


	if (!GetEntProp(iClient, Prop_Send, "m_bAdrenalineActive"))
		return -1.0;
	
	return flTime - flGameTime;
}
