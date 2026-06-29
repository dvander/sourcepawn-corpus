#define PLUGIN_VERSION	"1.2.1"
#define PLUGIN_NAME		"l4d_swap_buff"

/**
 *	v1.0 just releases; 24-2-22
 *	v1.1 support announces and translations; 25-2-22
 *	v1.2
 *		optional 'duration gain cap'
 *		fix forgot set translate target, 
 *		speed use multiply rather than hardcode speed; 26-2-22
 *	v1.2.1 colors annonuce;
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

forward void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier);

forward void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier);

forward void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier);

forward void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier);

static const char classes[][] = {
	"hunting_rifle", "sniper_military", "sniper_scout", "sniper_awp",
	"rifle", "rifle_sg552", "rifle_desert", "rifle_ak47", "rifle_m60", "smg", "smg_silenced", "smg_mp5", 
	"pumpshotgun", "shotgun_chrome", "autoshotgun", "shotgun_spas", "grenade_launcher",
	"pistol_magnum", "pistol", "melee", "chainsaw"
};

enum {
	Firing = 0,
	Deploying,
	Reloading,
	MeleeSwinging
};

ConVar Enabled;
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
ConVar Allow_actions;	int allow_actions;
ConVar Allow_pause;		int allow_pause;
ConVar Speed;			float speed;
ConVar Announce_type;	int announce_type;
ConVar Cap;				float cap;

static bool hasTranslations;

public Plugin myinfo = {
	name = "[L4D2] Weapon Swapping Buff",
	author = "NoroHime",
	description = "make Switching Weapons as new Gameplay",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {

	CreateConVar("swap_buff_version", PLUGIN_VERSION, "Version of 'Swapping Buff'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enabled = 			CreateConVar("swap_buff_enabled", "1",			"Enabled 'Swapping Buff'", FCVAR_NOTIFY);
	Ratio_smoker =		CreateConVar("swap_buff_ratio_smoker", "2",		"buff duration gain of smoker", FCVAR_NOTIFY);
	Ratio_boomer =		CreateConVar("swap_buff_ratio_boomer", "1.5",	"buff duration gain of boomer", FCVAR_NOTIFY);
	Ratio_hunter =		CreateConVar("swap_buff_ratio_hunter", "2",		"buff duration gain of hunter", FCVAR_NOTIFY);
	Ratio_spitter =		CreateConVar("swap_buff_ratio_spitter", "1.5",	"buff duration gain of spitter", FCVAR_NOTIFY);
	Ratio_jockey =		CreateConVar("swap_buff_ratio_jockey", "2",		"buff duration gain of jockey", FCVAR_NOTIFY);
	Ratio_charger =		CreateConVar("swap_buff_ratio_charger", "3",	"buff duration gain of charger", FCVAR_NOTIFY);
	Ratio_witch =		CreateConVar("swap_buff_ratio_witch", "8",		"buff duration gain of witch", FCVAR_NOTIFY);
	Ratio_tank =		CreateConVar("swap_buff_ratio_tank", "8",		"buff duration gain of tank", FCVAR_NOTIFY);
	Ratio_headshot =	CreateConVar("swap_buff_ratio_headshot", "1.5",	"gain multiplier of headshot", FCVAR_NOTIFY);
	Ratio_common =		CreateConVar("swap_buff_ratio_common", "1",		"buff duration gain of common zombies", FCVAR_NOTIFY);
	Allow_actions =		CreateConVar("swap_buff_allow_actions", "-1",	"which action boost 1=Firing 2=Deploying 4=Reloading 8=MeleeSwinging -1=All. add numbers together you want", FCVAR_NOTIFY);
	Allow_pause =		CreateConVar("swap_buff_allow_pause", "0",		"allow pause countdown when switch to other weapon 1:pause -1:clear duration 0:countdown continue", FCVAR_NOTIFY);
	Speed =				CreateConVar("swap_buff_speed", "1.5",			"multiplier of action speed  1.5:boost 50% firing/reloading/deploying", FCVAR_NOTIFY);
	Announce_type =		CreateConVar("swap_buff_announces", "4",		"1=center 2=chat 4=hint 7=all add together you want", FCVAR_NOTIFY);
	Cap =				CreateConVar("swap_buff_max", "120",			"max duration can get, 0:not limited", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_NAME);

	Enabled.AddChangeHook(Event_ConVarChanged);
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
	Allow_actions.AddChangeHook(Event_ConVarChanged);
	Allow_pause.AddChangeHook(Event_ConVarChanged);
	Speed.AddChangeHook(Event_ConVarChanged);
	Announce_type.AddChangeHook(Event_ConVarChanged);
	Cap.AddChangeHook(Event_ConVarChanged);
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/" ... PLUGIN_NAME ... ".phrases.txt");
	hasTranslations = FileExists(path);

	if (hasTranslations)
		LoadTranslations(PLUGIN_NAME ... ".phrases");

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
	allow_actions = Allow_actions.IntValue;
	allow_pause = Allow_pause.IntValue;
	speed = Speed.FloatValue;
	announce_type = Announce_type.IntValue;
	cap = Cap.FloatValue;
}

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

enum {
	CENTER = 0,
	CHAT,
	HINT
}

void Announce(int client, const char[] format, any ...) {

	if (!hasTranslations) return;

	static char buffer[254];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceColor(buffer, sizeof(buffer));

	if (isClient(client)) {

		if (announce_type & (1 << CHAT))
			PrintToChat(client, "%s", buffer);

		if (announce_type & (1 << HINT))
			PrintHintText(client, "%s", buffer);

		if (announce_type & (1 << CENTER))
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

enum WeaponSlot {
	Others = 0, 
	Primary, 
	Secondary
};

WeaponSlot GetWeaponSlot(const char[] name) {

	for (int i = 0; i < sizeof(classes); i++)
		if (strcmp(name, classes[i]) == 0) {
			if (0 <= i <= 16) {
				return Primary;
			}

			if (17 <= i <= 20) {
				return Secondary;
			}
		}

	return Others;
}

public void OnClientPutInServer(int client) {

	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnClientDisconnect_Post(int client) {

	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

static float buff_remain_primary[MAXPLAYERS + 1];
static float buff_remain_secondary[MAXPLAYERS + 1];
static int buff_weapon_activating[MAXPLAYERS + 1];

static Handle timer_primary[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
static Handle timer_secondary[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

public void OnWeaponSwitchPost(int client, int weapon) {

	static char name_weapon[32];

	if (isAliveSurvivor(client)) {


		GetEntityClassname(weapon, name_weapon, sizeof(name_weapon));
		ReplaceStringEx(name_weapon, sizeof(name_weapon), "weapon_", "");

		switch(GetWeaponSlot(name_weapon)) {

			case Primary : {

				if (IsValidHandle(timer_primary[client])) {
					KillTimer(timer_primary[client]);

					timer_primary[client] = INVALID_HANDLE;
				}

				if (buff_remain_primary[client] > 0) {

					buff_weapon_activating[client] = weapon;

					timer_primary[client] = CreateTimer(1.0, Timer_PrimaryCountdown, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

					Announce(client, "%t", "Left", "Primary", buff_remain_primary[client]);

				} else {
					buff_weapon_activating[client] = 0;
				}

				if (allow_pause > 0) {

					if (IsValidHandle(timer_secondary[client]))
						KillTimer(timer_secondary[client]);

				} else if (allow_pause < 0) {

					if (IsValidHandle(timer_secondary[client]))
						KillTimer(timer_secondary[client]);

					buff_remain_secondary[client] = 0.0;
				}
			}
			case Secondary : {

				if (IsValidHandle(timer_secondary[client])) {
					KillTimer(timer_secondary[client]);

					timer_secondary[client] = INVALID_HANDLE;
				}

				if (buff_remain_secondary[client] > 0) {

					buff_weapon_activating[client] = weapon;

					timer_secondary[client] = CreateTimer(1.0, Timer_SecondaryCountdown, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

					Announce(client, "%t", "Left", "Secondary", buff_remain_secondary[client]);

				} else {

					buff_weapon_activating[client] = 0;
				}

				if (allow_pause > 0) {

					if (IsValidHandle(timer_primary[client]))
						KillTimer(timer_primary[client]);

				} else if (allow_pause < 0) {

					if (IsValidHandle(timer_primary[client]))
						KillTimer(timer_primary[client]);

					buff_remain_primary[client] = 0.0;
				}

			}
			case Others : {

				if (allow_pause > 0) {

					if (IsValidHandle(timer_primary[client]))
						KillTimer(timer_primary[client]);

					if (IsValidHandle(timer_secondary[client]))
						KillTimer(timer_secondary[client]);

				} else if (allow_pause < 0) {

					if (IsValidHandle(timer_primary[client]))
						KillTimer(timer_primary[client]);

					if (IsValidHandle(timer_secondary[client]))
						KillTimer(timer_secondary[client]);

					buff_remain_secondary[client] = 0.0;
					buff_remain_primary[client] = 0.0;
				}
			}
		}
	}
}

public Action Timer_PrimaryCountdown(Handle timer, int client) {

	if (buff_remain_primary[client] > 0) {
		buff_remain_primary[client]--;
		return Plugin_Continue;
	}
	buff_weapon_activating[client] = 0;
	timer_primary[client] = INVALID_HANDLE;
	Announce(client, "%t", "End", "Primary");
	return Plugin_Stop;
}

public Action Timer_SecondaryCountdown(Handle timer, int client) {

	if (buff_remain_secondary[client] > 0) {
		buff_remain_secondary[client]--;
		return Plugin_Continue;
	}
	buff_weapon_activating[client] = 0;
	timer_secondary[client] = INVALID_HANDLE;
	Announce(client, "%t", "End", "Secondary");
	return Plugin_Stop;
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

	if (ratio && isAliveSurvivor(attacker)) {

		switch(GetWeaponSlot(name_weapon)) {
			case Primary : {
				if (!cap || buff_remain_secondary[attacker] < cap)
					buff_remain_secondary[attacker] += ratio;
				else
					buff_remain_secondary[attacker] = cap;
			}
			
			case Secondary : {
				if (!cap || buff_remain_primary[attacker] < cap)
					buff_remain_primary[attacker] += ratio;
				else
					buff_remain_primary[attacker] = cap;
			}
		}
	}

}

float SpeedStatus(int client, int weapon, float speedmodifier) {

	if (buff_weapon_activating[client] == weapon && (buff_remain_primary[client] > 0 || buff_remain_secondary[client] > 0))
		return speedmodifier * speed;

	return speedmodifier;
}

public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier) {
	if (allow_actions & (1 << MeleeSwinging))
		speedmodifier = SpeedStatus(client, weapon, speedmodifier);
}

public  void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier) {
	if (allow_actions & (1 << Reloading))
		speedmodifier = SpeedStatus(client, weapon, speedmodifier);
}

public void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier) {
	if (allow_actions & (1 << Firing))
		speedmodifier = SpeedStatus(client, weapon, speedmodifier);
}

public void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier) {
	if (allow_actions & (1 << Deploying))
		speedmodifier = SpeedStatus(client, weapon, speedmodifier);

}

/*Stocks below*/

stock bool isAliveSurvivor(int client) {
	return isSurvivor(client) && IsPlayerAlive(client);
}

stock bool isSurvivor(int client) {
	return isClient(client) && GetClientTeam(client) == 2;
}

stock bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientInGame(client);
}

stock bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
}
