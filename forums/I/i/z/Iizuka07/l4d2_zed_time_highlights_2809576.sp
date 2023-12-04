#define PLUGIN_VERSION "1.6.2"
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

/*
 *	v1.0 just releases; 1-15-22
 *	v1.1 add option "silence volume", "silence fading time", "trigging sound"; 1-17-22
 *	v1.1.1 now volume silence and trigging sound also work with native call; 1-17-22
 *	v1.1.2 bug fix for ZedBack(); 1-19-22
 *	v1.2 add feature: survivor or survivor bot death trigger Zed Time, code clean and create event forward OnZedTime(); 2-6-22
 *	v1.3 new features:
 *		lucky mode instead threshold mode,
 *		commands 'sm_zedtime [duration] [timescale]', 'sm_zedstop' to trigger manually and permission configuable,
 *		remove ConVar threshold_survivor_death and add threshold_bot to instead,
 *		fix trigger multiple zedtime cause multi sound effects,
 *		rewrite some00 code and less performance usage; 3-March-2022
 *	v1.4 new feature 'boost weapon actions when ZedTime triggering', required '[L4D/L4D2]WeaponHandling_API'; 4-March-2022
 *	v1.5 new feature 'boost movement speed when ZedTime triggering' but didnt recommended, explosion damage wont trigger headshot ; 1-May-2022
 *	v1.5.1	command sm_zedtime now can trigger from server console,
 *			optimize code suggestion from Silvers,
 *			new ConVar *_threshold_burn_ratio to control fire damage causes threshold; 1-November-2022
 *	v1.6 fixes:
 *		- now support "Lagged Movement" plugin,
 *		- little negligence cause movement boost default enabled, that should be optional,
 *		- remove some redundant code,
 *		- change forward OnZedTime to "Action OnZedTime(float &duration, float &timescale)",
 *		- turn code style to hungarian notation,
 *		- fix boost movement speed cause wrong velocity,
 *		- support late load; 21-December-2022
 *	v1.6.1 fix rare issue ZedTime trigger on round ended cause wont stop; 13-January-2023
 *	v1.6.2 fix 'Dead Center' finale game default slow-motion stop by plugin
 */



/**
 * @brief Called ZedTime be trigger by something
 *
 * @param duration		zedtime duration
 * @param timescale		zedtime timescale
 *
 * @return				Plugin_Continue to continuing zedtime,
 * 						Plugin_Changed to change arguments, otherwise to prevent weapon dropping.
 */

// forward Action OnZedTime(float &duration, float &timescale);


ConVar Enable;
ConVar cDuration;					float flDuration;
ConVar cTimescale;					float flTimescale;

ConVar cThresholdNeededBase;		float flThresholdNeededBase;
ConVar cThresholdNeededIncrease;	float flThresholdNeededIncrease;
ConVar cThresholdCooldown;			float flThresholdCooldown;


ConVar cThresholdHeadshotRatio;		float flThresholdHeadshotTatio;
ConVar cThresholdMeleeRatio;		float flThresholdMeleeRatio;
ConVar cThresholdDistanceMax;		float flThresholdDistanceMax;
ConVar cThresholdDistanceRatio;	float flThresholdDistanceRatio;
ConVar cThresholdPipedRatio;		float flThresholdPiped_ratio;
ConVar cThresholdGrenadeRatio;		float flThresholdGrenadeRatio;


ConVar cThresholdTankRatio;			float flThresholdTankRatio;
ConVar cThresholdWitchRatio;		float flThresholdWitchRatio;

ConVar cThresholdBoomerRatio;		float flThresholdBoomerRatio;
ConVar cThresholdSmokerRatio;		float flThresholdSmokerRatio;
ConVar cThresholdHunterRatio;		float flThresholdHunterRatio;
ConVar cThresholdSpitterRatio;		float flThresholdSpitterRatio;
ConVar cThresholdJockeyRatio;		float flThresholdJockeyRatio;
ConVar cThresholdChargerRatio;		float flThresholdChargerRatio;
ConVar cTriggerSilence;				float flTriggerSilence;
ConVar cTriggerSilenceFading;		float flTriggerSilenceFading;
ConVar cTriggerSound;				char sTriggerSound[64];
ConVar cThresholdSurvivorDeath;		float flThresholdSurvivorDeath;
ConVar cCommandsAccess;				int iCommandsAccess;
ConVar cLuckies;					bool bLuckies;
ConVar cThresholdBotRatio;			float flThresholdBotRatio;
ConVar cBoostActions;				int iBoostActions;
ConVar cBoostSpeed;					float flBoostSpeed;
ConVar cThresholdBurnRatio;			float flThresholdBurnRatio;

GlobalForward OnZedTime;

bool g_bLaggedMovement;
bool bLateLoad;
bool bBlockZedtime;

native any L4D_LaggedMovement(int client, float value, bool force = false);

public void OnLibraryAdded(const char[] name) {
	if( strcmp(name, "LaggedMovement") == 0 )
		g_bLaggedMovement = true;
}

public void OnLibraryRemoved(const char[] name) {
	if( strcmp(name, "LaggedMovement") == 0 )
		g_bLaggedMovement = false;
}

forward void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier);
forward void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnStartThrow(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnReadyingThrow(int client, int weapon, int weapontype, float &speedmodifier);

Handle zeding;

float time_kill_first[MAXPLAYERS+1];
float thresholds[MAXPLAYERS+1];
float threshold_required;

public Plugin myinfo = {
	name = "[L4D2] Zed Time Highlights System",
	author = "NoroHime",
	description = "Zed Time like Killing Floor now with highlights system",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (GetEngineVersion() != Engine_Left4Dead2) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}

	if (late)
		bLateLoad = true;

	RegPluginLibrary("l4d2_zed_time_highlights");

	MarkNativeAsOptional("L4D_LaggedMovement");

	CreateNative("ZedTime", ExternalZedTime);
	return APLRes_Success; 
}

int ExternalZedTime(Handle plugin, int numParams) {

	float durationParam = GetNativeCell(1),
		scaleParam = GetNativeCell(2);

	ZedTime(
		durationParam ? durationParam : flDuration, 
		scaleParam ? scaleParam : flTimescale
	);

	PrintToServer("ZedTime by native");

	return 0;
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
	if (convar == cTriggerSound)
		SoundCaching();
}

void ApplyCvars() {

	static char flags[32];
	static bool hooked = false;

	if (Enable.BoolValue && !hooked) {

		HookEvent("player_death", OnPlayerDeath);
		HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
		HookEvent("map_transition", OnRoundEnd, EventHookMode_PostNoCopy);
		HookEvent("finale_vehicle_leaving", OnRoundEnd, EventHookMode_PostNoCopy);
		HookEvent("mission_lost", OnRoundEnd, EventHookMode_PostNoCopy);
		HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
		HookEvent("player_team", OnHumanChanged, EventHookMode_PostNoCopy);
		HookEvent("player_bot_replace", OnHumanChanged, EventHookMode_PostNoCopy);
		HookEvent("bot_player_replace", OnHumanChanged, EventHookMode_PostNoCopy);

		hooked = true;

	} else if (!Enable.BoolValue && hooked) {

		UnhookEvent("player_death", OnPlayerDeath);
		UnhookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("map_transition", OnRoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_leaving", OnRoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("mission_lost", OnRoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("player_team", OnHumanChanged, EventHookMode_PostNoCopy);
		UnhookEvent("player_bot_replace", OnHumanChanged, EventHookMode_PostNoCopy);
		UnhookEvent("bot_player_replace", OnHumanChanged, EventHookMode_PostNoCopy);

		hooked = false;
	}

	flDuration = cDuration.FloatValue;
	flTimescale = cTimescale.FloatValue;

	flThresholdNeededBase = cThresholdNeededBase.FloatValue;
	flThresholdNeededIncrease = cThresholdNeededIncrease.FloatValue;
	flThresholdCooldown = cThresholdCooldown.FloatValue;

	flThresholdHeadshotTatio = cThresholdHeadshotRatio.FloatValue;
	flThresholdMeleeRatio = cThresholdMeleeRatio.FloatValue;
	flThresholdDistanceMax = cThresholdDistanceMax.FloatValue;
	flThresholdDistanceRatio = cThresholdDistanceRatio.FloatValue;
	flThresholdPiped_ratio = cThresholdPipedRatio.FloatValue;
	flThresholdGrenadeRatio = cThresholdGrenadeRatio.FloatValue;


	flThresholdTankRatio = cThresholdTankRatio.FloatValue;
	flThresholdWitchRatio = cThresholdWitchRatio.FloatValue;
	flThresholdBoomerRatio = cThresholdBoomerRatio.FloatValue;
	flThresholdSmokerRatio = cThresholdSmokerRatio.FloatValue;
	flThresholdHunterRatio = cThresholdHunterRatio.FloatValue;
	flThresholdSpitterRatio = cThresholdSpitterRatio.FloatValue;
	flThresholdJockeyRatio = cThresholdJockeyRatio.FloatValue;
	flThresholdChargerRatio = cThresholdChargerRatio.FloatValue;

	flTriggerSilence = cTriggerSilence.FloatValue;
	flTriggerSilenceFading = cTriggerSilenceFading.FloatValue;
	cTriggerSound.GetString(sTriggerSound, sizeof(sTriggerSound));
	flThresholdSurvivorDeath = cThresholdSurvivorDeath.FloatValue;

	cCommandsAccess.GetString(flags, sizeof(flags));
	iCommandsAccess = flags[0] ? ReadFlagString(flags) : 0;

	bLuckies = cLuckies.BoolValue;
	flThresholdBotRatio = cThresholdBotRatio.FloatValue;
	iBoostActions = cBoostActions.IntValue;
	flBoostSpeed = cBoostSpeed.FloatValue;
	flThresholdBurnRatio = cThresholdBurnRatio.FloatValue;
}

public void OnPluginStart() {
	
	CreateConVar								("zed_time_version", PLUGIN_VERSION, 				"Version of Zed Time Highlights", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enable =						CreateConVar("zed_time_enable", "1", 							"Zed Time enable", FCVAR_NOTIFY);
	cDuration =						CreateConVar("zed_time_duration", "0.5", 						"zed time duration", FCVAR_NOTIFY, true, 0.1);
	cTimescale =					CreateConVar("zed_time_timescale", "0.2", 						"zed time scale of game time", FCVAR_NOTIFY, true, 0.1, true, 1.0);
	cThresholdNeededBase =			CreateConVar("zed_time_threshold_needed_base", "4", 			"to trigger zed time you need kill many zombie on short time, 4 means you need to kill 4 worth value of zombies", FCVAR_NOTIFY, true, 1.0);
	cThresholdNeededIncrease =		CreateConVar("zed_time_threshold_needed_increase", "1.33", 		"every alive human survivor will increase zed time threshold needed, if 3 human you should kill 6.66(4+2*1.33) unit zombies to trigger", FCVAR_NOTIFY, true, 0.0);

	cThresholdCooldown =			CreateConVar("zed_time_threshold_cooldown", "0.3", 				"if kill threshold worth greater than needed and between this time then trigger", FCVAR_NOTIFY, true, 0.01);

	cThresholdHeadshotRatio =		CreateConVar("zed_time_threshold_headshot_ratio", "1.5", 		"worth value multiplier of headshot", FCVAR_NOTIFY, true, 1.0);

	cThresholdDistanceMax =		CreateConVar("zed_time_threshold_distance_max", "1200", 		"max distance to apply multiplier worth value", FCVAR_NOTIFY, true, 220.0);
	cThresholdDistanceRatio =		CreateConVar("zed_time_threshold_distance_ratio", "1.5", 		"if kill distance close to max, multiplier also close to x1.5, nearest is x1", FCVAR_NOTIFY, true, 1.0);

	cThresholdPipedRatio =			CreateConVar("zed_time_threshold_piped_ratio", "0.85", 			"if zombie kill by pipe bomb, the kill worth multiply this value", FCVAR_NOTIFY, true, 0.0);
	cThresholdMeleeRatio =			CreateConVar("zed_time_threshold_melee_ratio", "1.16", 			"multiplier of melee kill", FCVAR_NOTIFY, true, 0.0);
	cThresholdGrenadeRatio =		CreateConVar("zed_time_threshold_grenade_ratio", "0.75", 		"multiplier of grenade launcher kill", FCVAR_NOTIFY, true, 0.0);

	cThresholdTankRatio =			CreateConVar("zed_time_threshold_tank_ratio", "32", 			"multiplier of tank death", FCVAR_NOTIFY, true, 0.0);
	cThresholdWitchRatio =			CreateConVar("zed_time_threshold_witch_ratio", "32", 			"multiplier of witch death", FCVAR_NOTIFY, true, 0.0);

	cThresholdBoomerRatio =			CreateConVar("zed_time_threshold_boomer_ratio", "1.33", 		"multiplier of boomer death", FCVAR_NOTIFY, true, 0.0);
	cThresholdSmokerRatio =			CreateConVar("zed_time_threshold_smoker_ratio", "1.33", 		"multiplier of smoker death", FCVAR_NOTIFY, true, 0.0);
	cThresholdHunterRatio =			CreateConVar("zed_time_threshold_hunter_ratio", "1.25", 		"multiplier of hunter death", FCVAR_NOTIFY, true, 0.0);
	cThresholdSpitterRatio =		CreateConVar("zed_time_threshold_spitter_ratio", "1.2", 		"multiplier of spitter death", FCVAR_NOTIFY, true, 0.0);
	cThresholdJockeyRatio =			CreateConVar("zed_time_threshold_jockey_ratio", "1.25", 		"multiplier of jockey death", FCVAR_NOTIFY, true, 0.0);
	cThresholdChargerRatio =		CreateConVar("zed_time_threshold_charger_ratio", "1.5", 		"multiplier of charger death", FCVAR_NOTIFY, true, 0.0);
	cTriggerSilence =				CreateConVar("zed_time_trigger_silence", "50", 					"percent of silence volume, 0: do not silence, 100: completely silence", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	cTriggerSilenceFading =			CreateConVar("zed_time_trigger_silence_fading", "0.2", 			"silence fading time, 0: instantly silence", FCVAR_NOTIFY, true, 0.0);
	cTriggerSound =					CreateConVar("zed_time_trigger_sound", "level/countdown.wav",	"trigger sound play to all client. recommanded: ui/menu_countdown.wav level/countdown.wav plats/churchbell_end.wav", FCVAR_NOTIFY);

	cThresholdSurvivorDeath =		CreateConVar("zed_time_threshold_survivor_death", "32", 		"threashold value of survivor death trigger Zed Time, 0:disable", FCVAR_NOTIFY, true, 0.0);
	cCommandsAccess =				CreateConVar("zed_time_access", "f", 							"admin flag to acces ZedTime commands f:slay empty:allow everyone", FCVAR_NOTIFY);
	cLuckies =						CreateConVar("zed_time_lucky", "0", 							"use lucky mode instead threshold mode, also effect by threshold requirement", FCVAR_NOTIFY, true, 0.0);
	cThresholdBotRatio =			CreateConVar("zed_time_threshold_bot", "0.5", 					"bot weight ratio, 0.5:bot cause half threshold 0:bot cant trigger", FCVAR_NOTIFY, true, 0.0);
	cBoostActions =					CreateConVar("zed_time_boost_actions", "31", 					"which actions boost under ZedTime \n1=Firing 2=Deploying 4=Reloading 8=MeleeSwinging 16=Throwing 32=Movement -1=All.\nadd numbers together you want", FCVAR_NOTIFY);
	cBoostSpeed =					CreateConVar("zed_time_boost_speed", "-1", 						"how fast boost the actions under ZedTime\n-1:auto scaling by timescale 2:doubling speed 0:disable", FCVAR_NOTIFY);
	cThresholdBurnRatio =			CreateConVar("zed_time_threshold_burn_ratio", "1.0", 			"threshold value multiplier of kill by burn damage", FCVAR_NOTIFY);

	RegConsoleCmd("sm_zedtime", CommandZedTime, "Trigger ZedTime manually. Usage: sm_zedtime [duration] [timescale]");
	RegConsoleCmd("sm_zedstop", CommandZedStop, "stop the zedtime manually");

	Enable.AddChangeHook(OnConVarChanged);
	cDuration.AddChangeHook(OnConVarChanged);
	cTimescale.AddChangeHook(OnConVarChanged);
	cThresholdNeededBase.AddChangeHook(OnConVarChanged);
	cThresholdNeededIncrease.AddChangeHook(OnConVarChanged);
	cThresholdCooldown.AddChangeHook(OnConVarChanged);
	cThresholdHeadshotRatio.AddChangeHook(OnConVarChanged);
	cThresholdDistanceMax.AddChangeHook(OnConVarChanged);
	cThresholdDistanceRatio.AddChangeHook(OnConVarChanged);
	cThresholdPipedRatio.AddChangeHook(OnConVarChanged);
	cThresholdMeleeRatio.AddChangeHook(OnConVarChanged);
	cThresholdTankRatio.AddChangeHook(OnConVarChanged);
	cThresholdWitchRatio.AddChangeHook(OnConVarChanged);
	cThresholdBoomerRatio.AddChangeHook(OnConVarChanged);
	cThresholdSmokerRatio.AddChangeHook(OnConVarChanged);
	cThresholdHunterRatio.AddChangeHook(OnConVarChanged);
	cThresholdSpitterRatio.AddChangeHook(OnConVarChanged);
	cThresholdJockeyRatio.AddChangeHook(OnConVarChanged);
	cThresholdChargerRatio.AddChangeHook(OnConVarChanged);
	cThresholdGrenadeRatio.AddChangeHook(OnConVarChanged);
	cTriggerSilence.AddChangeHook(OnConVarChanged);
	cTriggerSilenceFading.AddChangeHook(OnConVarChanged);
	cTriggerSound.AddChangeHook(OnConVarChanged);
	cThresholdSurvivorDeath.AddChangeHook(OnConVarChanged);
	cCommandsAccess.AddChangeHook(OnConVarChanged);
	cLuckies.AddChangeHook(OnConVarChanged);
	cBoostActions.AddChangeHook(OnConVarChanged);
	cBoostSpeed.AddChangeHook(OnConVarChanged);
	cThresholdBurnRatio.AddChangeHook(OnConVarChanged);
	ApplyCvars();

	OnZedTime = new GlobalForward("OnZedTime", ET_Event, Param_FloatByRef, Param_FloatByRef);

	AutoExecConfig(true, "l4d2_zed_time_highlights");

	if (bLateLoad) {

		g_bLaggedMovement = LibraryExists("L4D_LaggedMovement");

		GetThresholdRequired();

		// Late load
		for( int i = 1; i <= MaxClients; i++ )
			if( IsClientInGame(i) )
				OnClientPutInServer(i);
	}
}

bool HasPermission(int client) {

	int flag_client = GetUserFlagBits(client);

	if (!iCommandsAccess || flag_client & ADMFLAG_ROOT) return true;

	return view_as<bool>(flag_client & iCommandsAccess);
}


Action CommandZedTime(int client, int args) {

	static char arg1[8], arg2[8];

	if ( client == 0 || ( IsClient(client) && HasPermission(client) ) ) {

		switch(args) {
			case 0 : ZedTime(flDuration, flTimescale);
			case 1 : {
				GetCmdArg(1, arg1, sizeof(arg1));
				ZedTime(StringToFloat(arg1), flTimescale);
			}
			case 2 : {
				GetCmdArg(1, arg1, sizeof(arg1));
				GetCmdArg(2, arg2, sizeof(arg2));
				ZedTime(StringToFloat(arg1), StringToFloat(arg2));
			}
		}
	} else {
		ReplyToCommand(client, "Permission Denied.");
	}
	
	return Plugin_Handled;
}


Action CommandZedStop(int client, int args) {

	if (IsClient(client) && HasPermission(client)) {

		ZedBack(null, -1);

	} else
		ReplyToCommand(client, "Permission Denied.");
	
	return Plugin_Handled;
}

void OnRoundChange() {

	if(zeding) {

		TriggerTimer(zeding);
		zeding = null;

	} else {
		ZedBack(null, -1);
	}
}

void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	bBlockZedtime = false;
	OnRoundChange();
}

void OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	bBlockZedtime = true;
	OnRoundChange();
}
	
public void OnMapStart() {
	SoundCaching();
}

void SoundCaching() {
	if (sTriggerSound[0])
		PrecacheSound(sTriggerSound);
}

float ThresholdAdd(int attacker, float worth) {
	float time = GetEngineTime();
	bool waits = false;
	float threshold_require = threshold_required;

	if (
		worth > threshold_require ||
		time_kill_first[attacker] && 
		(time - time_kill_first[attacker]) < flThresholdCooldown
	) {
		
		thresholds[attacker] += worth;

		if (thresholds[attacker] >= threshold_require) {

			time_kill_first[attacker] = time;
			thresholds[attacker] = 0.0;

			ZedTime(flDuration, flTimescale);

		}

	} else {
		waits = true;
	}

	if (zeding || waits) {
		time_kill_first[attacker] = time;
		thresholds[attacker] = worth;
	}

	return thresholds[attacker];
}

void ThresholdLucky(float worth) {
	if (worth > GetRandomFloat(0.0, threshold_required))
		ZedTime(flDuration, flTimescale);
}


void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	static char weapon[32], victimname[32];
	static float victim_pos[3];

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	event.GetString("victimname", victimname, sizeof(victimname));
	event.GetString("weapon", weapon, sizeof(weapon));

	victim_pos[0] = event.GetFloat("victim_x");
	victim_pos[1] = event.GetFloat("victim_y");
	victim_pos[2] = event.GetFloat("victim_z");

	bool isHeadshot = event.GetBool("headshot");
	bool isPiped = strcmp(weapon, "pipe_bomb") == 0;
	bool isMelee = strcmp(weapon, "melee") == 0;
	bool isGrenade = StrContains(weapon, "projectile") != -1;
	bool isBurn = view_as<bool>(event.GetInt("type") & DMG_BURN);

	float ratio = 1.0;

	if (isPiped)
		ratio *= flThresholdPiped_ratio;

	if (isHeadshot && !isPiped && !isGrenade)
		ratio *= flThresholdHeadshotTatio;

	if (isMelee)
		ratio *= flThresholdMeleeRatio;

	if (isGrenade)
		ratio *= flThresholdGrenadeRatio;

	if (isBurn)
		ratio *= flThresholdBurnRatio;

	if (IsClient(attacker)) {

		float attacker_pos[3];
		GetClientAbsOrigin(attacker, attacker_pos);
		ratio *= 1.0 + (flThresholdDistanceRatio - 1) * ((GetVectorDistance(attacker_pos, victim_pos, false) / flThresholdDistanceMax));
	}

	switch (victimname[0]) {
		case 'I' : ratio *= 1.0;
		case 'S' : ratio *= victimname[1] == 'm' ? flThresholdSmokerRatio : flThresholdSpitterRatio;
		case 'B' : ratio *= flThresholdBoomerRatio;
		case 'H' : ratio *= flThresholdHunterRatio;
		case 'J' : ratio *= flThresholdJockeyRatio;
		case 'C' : ratio *= flThresholdChargerRatio;
		case 'W' : ratio *= flThresholdWitchRatio;
		case 'T' : ratio *= flThresholdTankRatio;
		default : {

			int victim = GetClientOfUserId(event.GetInt("userid"));

			if (IsSurvivor(victim) && flThresholdSurvivorDeath > 0) { //survivor death trigger

			float threshold_value = IsFakeClient(victim) ? flThresholdSurvivorDeath * flThresholdBotRatio : flThresholdSurvivorDeath;

			if (threshold_value >= threshold_required) //threashold reached
				ZedTime(flDuration, flTimescale);
			}

			ratio = 0.0;
		}
	}

	if (ratio && IsSurvivor(attacker)) {

		if (IsFakeClient(attacker))
			ratio *= flThresholdBotRatio;

		if (ratio > 0) 
			if (bLuckies)
				ThresholdLucky(ratio);
			else 
				ThresholdAdd(attacker, ratio);
	}

}

void ZedTime(float duration, float scale) {

	if (bBlockZedtime) {
		PrintToServer("ZedTime Blocked");
		return;
	}

	Action actResult = Plugin_Continue;

	Call_StartForward(OnZedTime);
	Call_PushFloatRef(duration);
	Call_PushFloatRef(scale);
	Call_Finish(actResult);

	switch (actResult)  {

		case Plugin_Continue, Plugin_Changed : {}

		default : 
			return;
	}

	if (zeding)
		TriggerTimer(zeding);
	
	for(int client = 1; client <= MaxClients; client++)
		if (IsClient(client)) {
			if (flTriggerSilence)
				FadeClientVolume(client, flTriggerSilence, flTriggerSilenceFading, duration - flTriggerSilenceFading, flTriggerSilenceFading);
			if (sTriggerSound[0]) {
				StopSound(client, SNDCHAN_STATIC, sTriggerSound);
				EmitSoundToClient(client, sTriggerSound, client, SNDCHAN_STATIC);
			}
		}

	int entity = CreateEntityByName("func_timescale");

	static char sScale[8];
	FloatToString(scale, sScale, sizeof(sScale));
	DispatchKeyValue(entity, "desiredTimescale", sScale);
	DispatchKeyValue(entity, "acceleration", "2.0");
	DispatchKeyValue(entity, "minBlendRate", "1.0");
	DispatchKeyValue(entity, "blendDeltaMultiplier", "2.0");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "Start");

	zeding = CreateTimer(duration, ZedBack, EntIndexToEntRef(entity));
}

Action ZedBack(Handle Timer, int entity) {

	entity = EntRefToEntIndex(entity);

	if (entity != INVALID_ENT_REFERENCE && IsValidEdict(entity)) {
		StopTimescaler(entity);
	}

	//  else {
	// 	int found = -1;
	// 	while ((found = FindEntityByClassname(found, "func_timescale")) != -1)
	// 		if (IsValidEdict(found))
	// 			StopTimescaler(found);
	// }
	
	zeding = null;
	return Plugin_Continue;
}

void StopTimescaler(int entity) {
	AcceptEntityInput(entity, "Stop");
	SetVariantString("OnUser1 !self:Kill::3.0:-1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}

enum {
	Firing = 0,
	Deploying,
	Reloading,
	MeleeSwinging,
	Throwing,
	Movement
};

float SpeedStatus(float speedmodifier) {

	if (flBoostSpeed == -1)

		return speedmodifier * (1.0 / flTimescale);

	else if (flBoostSpeed > 0)

		return speedmodifier * flBoostSpeed;

	return speedmodifier;
}

public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier) {

	if (iBoostActions & (1 << MeleeSwinging) && flBoostSpeed && zeding)
		speedmodifier = SpeedStatus(speedmodifier);
}

public  void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier) {

	if (iBoostActions & (1 << Reloading) && flBoostSpeed && zeding)
		speedmodifier = SpeedStatus(speedmodifier);
}

public void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier) {

	if (iBoostActions & (1 << Firing) && flBoostSpeed && zeding)
		speedmodifier = SpeedStatus(speedmodifier);
}

public void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier) {

	if (iBoostActions & (1 << Deploying) && flBoostSpeed && zeding)
		speedmodifier = SpeedStatus(speedmodifier);

}

public void WH_OnReadyingThrow(int client, int weapon, int weapontype, float &speedmodifier) {

	if (iBoostActions & (1 << Throwing) && flBoostSpeed && zeding)
		speedmodifier = SpeedStatus(speedmodifier);
}

public void WH_OnStartThrow(int client, int weapon, int weapontype, float &speedmodifier) {

	if (iBoostActions & (1 << Throwing) && flBoostSpeed && zeding)
		speedmodifier = SpeedStatus(speedmodifier);
}

public void OnClientPutInServer(int client) {

	GetThresholdRequired();

	if (iBoostActions & (1 << Movement))
		SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
}

public void OnClientDisconnect_Post(int client) {

	GetThresholdRequired();
}

void OnPreThinkPost(int client) {

	if (IsSurvivor(client) && IsPlayerAlive(client)) {

		// ==========
		// Code taken from "Weapons Movement Speed" by "Silvers"
		// ==========
		// Fix movement speed bug when jumping or staggering
		if( GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1 || GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > -1.0 )
		{
			// Fix jumping resetting velocity to default
			float value = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
			if( value != 1.0 )
			{
				float vVec[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVec);
				float height = vVec[2];

				ScaleVector(vVec, value);
				vVec[2] = height; // Maintain default jump height

				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVec);
			}

			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(client, 1.0, true) : 1.0);
			return;
		}
		// ==========


		SetTerrorMovement(client, zeding ? SpeedStatus(1.0) : 1.0);
	}
}

void SetTerrorMovement(int entity, float rate) {
	SetEntPropFloat(entity, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(entity, rate) : rate);
}

void OnHumanChanged(Event event, const char[] name, bool dontBroadcast) {
	GetThresholdRequired();
}

float GetThresholdRequired() {

	int alives = 0;

	for (int client = 1; client <= MaxClients; client++) {
		if (IsHumanSurvivor(client) && IsPlayerAlive(client))
			alives++;
	}

	float threshold_require = flThresholdNeededBase;

	if (alives > 0)
		threshold_require += RoundToNearest((alives - 1) * flThresholdNeededIncrease);

	return threshold_required = threshold_require;
}

bool IsHumanSurvivor(int client){
	return IsSurvivor(client) && !IsFakeClient(client);
}

bool IsSurvivor(int client) {
	return IsClient(client) && GetClientTeam(client) == 2;
}

bool IsClient(int client) {
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}
