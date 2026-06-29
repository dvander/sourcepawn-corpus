#define PLUGIN_VERSION		"1.1"
#define PLUGIN_NAME			"adrenaline_speedup"
#define PLUGIN_NAME_FULL	"[L4D2] Adrenaline SpeedUp <WeaponHandling Add-On>"
#define PLUGIN_DESCRIPTION	"Speed Up the weapons when under Adrenaline duration."
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?p=2772483"
/**
 *	v1.0 just releases; 26-2-22
 *	v1.0.1 fix wrong adrenaline duration, thanks to Silvers; 17-October-2022
 *	v1.1 new ConVar *_speed_melee, *_actions_melee to control melee alone,
 *		*_actions_melee has 2 modes, 0=WeaponHandling API 1=NetProp flNextAttackTime 
 *		remove ConVar *_enabled if need just unmount the plugin; 6-November-2022
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
forward void WH_OnStartThrow(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnReadyingThrow(int client, int weapon, int weapontype, float &speedmodifier);

ConVar Speed_rate;			float speed_rate;
ConVar Buff_actions;		int buff_actions;
ConVar Announce_type;		int announce_types;
ConVar Speed_rate_melee;	float speed_rate_melee;
ConVar Mode_melee;			bool mode_melee;

static bool hasTranslations;

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

public void OnPluginStart() {

	CreateConVar					(PLUGIN_NAME ... "_version", PLUGIN_VERSION,	"Version of 'Adrenaline SpeedUp'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Speed_rate =		CreateConVar(PLUGIN_NAME ... "_speed", "1.5",				"buff speed rate 2:double speed", FCVAR_NOTIFY);
	Buff_actions =		CreateConVar(PLUGIN_NAME ... "_actions", "-1",				"buff actions 1=Firing 2=Deploying 4=Reloading 8=MeleeSwinging 16=Throwing", FCVAR_NOTIFY);
	Announce_type =		CreateConVar(PLUGIN_NAME ... "_announces", "2",				"1=center 2=chat 4=hint 7=all add together you want", FCVAR_NOTIFY);
	Speed_rate_melee =	CreateConVar(PLUGIN_NAME ... "_speed_melee", "2.22",			"speed rate of melee swing 2=double", FCVAR_NOTIFY);
	Mode_melee =		CreateConVar(PLUGIN_NAME ... "_actions_melee", "1",			"alternative mode of melee swing 0=WeaponHandling API 1=NetProp flNextAttackTime", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d2_" ... PLUGIN_NAME);

	Speed_rate.AddChangeHook(OnConVarChanged);
	Buff_actions.AddChangeHook(OnConVarChanged);
	Announce_type.AddChangeHook(OnConVarChanged);
	Announce_type.AddChangeHook(OnConVarChanged);
	Speed_rate_melee.AddChangeHook(OnConVarChanged);
	Mode_melee.AddChangeHook(OnConVarChanged);

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/" ... "l4d2_" ... PLUGIN_NAME ... ".phrases.txt");
	hasTranslations = FileExists(path);

	if (hasTranslations)
		LoadTranslations("l4d2_" ... PLUGIN_NAME ... ".phrases");

	HookEvent("pills_used", OnPillsUsed, EventHookMode_Post);
	HookEvent("adrenaline_used", OnArenalineUsed, EventHookMode_Post);

	ApplyCvars();
}


public void ApplyCvars() {
	speed_rate = Speed_rate.FloatValue;
	buff_actions = Buff_actions.IntValue;
	announce_types = Announce_type.IntValue;
	speed_rate_melee = Speed_rate_melee.FloatValue;
	mode_melee = Mode_melee.BoolValue;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnArenalineUsed(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid"));

	if (isHumanSurvivor(healer)) {

		float adrenaline_remain = Terror_GetAdrenalineTime(healer);
		
		if (adrenaline_remain > 0)
			Announce(healer, "%t", "Used Remain", adrenaline_remain, "Adrenaline");
		else
			Announce(healer, "%t", "Used", "Adrenaline");
	}
}

public void OnPillsUsed(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid"));

	if (isHumanSurvivor(healer)) {

		float adrenaline_remain = Terror_GetAdrenalineTime(healer);

		if (adrenaline_remain > 0)
			Announce(healer, "%t", "Used Remain", adrenaline_remain, "Pills");
		else
			Announce(healer, "%t", "Used", "Pills");
	}

}

enum {
	Firing = 0,
	Deploying,
	Reloading,
	MeleeSwinging,
	Throwing
}


public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier) {


	if (buff_actions & (1 << MeleeSwinging) && Terror_GetAdrenalineTime(client) > 0) {

		if (mode_melee) {

			static int NextPrimaryAttak = -1;

			if (NextPrimaryAttak == -1)
				NextPrimaryAttak = FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");

			float calcedNPA = GetGameTime() + (GetEntDataFloat(weapon, NextPrimaryAttak) - GetGameTime()) / speed_rate_melee;

			SetEntDataFloat(weapon, NextPrimaryAttak, calcedNPA, true);

		} else
			speedmodifier *= speed_rate_melee;
	}
}

public  void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier) {
	if (buff_actions & (1 << Reloading) && Terror_GetAdrenalineTime(client) > 0)
		speedmodifier *= speed_rate;
}

public void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier) {
	if (buff_actions & (1 << Firing) && Terror_GetAdrenalineTime(client) > 0)
		speedmodifier *= speed_rate;
}

public void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier) {
	if (buff_actions & (1 << Deploying) && Terror_GetAdrenalineTime(client) > 0)
		speedmodifier *= speed_rate;
}

public void WH_OnReadyingThrow(int client, int weapon, int weapontype, float &speedmodifier) {
	if (buff_actions & (1 << Throwing) && Terror_GetAdrenalineTime(client) > 0)
		speedmodifier *= speed_rate;
}

public void WH_OnStartThrow(int client, int weapon, int weapontype, float &speedmodifier) {
	if (buff_actions & (1 << Throwing) && Terror_GetAdrenalineTime(client) > 0)
		speedmodifier *= speed_rate;
}


/*Stocks below*/

enum {
	CENTER = 0,
	CHAT,
	HINT
}

void Announce(int client, const char[] format, any ...) {

	static char buffer[254];

	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceColor(buffer, sizeof(buffer));

	if (isClient(client)) {

		if (announce_types & (1 << CHAT))
			PrintToChat(client, "%s", buffer);

		if (announce_types & (1 << HINT))
			PrintHintText(client, "%s", buffer);

		if (announce_types & (1 << CENTER))
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

stock bool isHumanSurvivor(int client) {
	return isClient(client) && GetClientTeam(client) == 2 && !IsFakeClient(client);
}

stock bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientInGame(client);
}

stock bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
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
