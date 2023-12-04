#define PLUGIN_VERSION		"2.2"
#define PLUGIN_PREFIX		"l4d_"
#define PLUGIN_NAME			"costly_sprint"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] Costly Sprint / Dash"
#define PLUGIN_DESCRIPTION	"hold Shift to sprint like another game or double tap move key, here comes costly."
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=340323"

/*
 *	v1.0 just released; 9-November-2022
 *	v1.1 new ConVar *_mode to control boost work way, more compatible or smoothy,
 *		 new ConVar *_tap to control how to trigger dash, shift+MoveKey or double tap forward key,
 *		 add support "[L4D & L4D2] Lagged Movement" if set *_mode to 1; 13-November-2022
 *	v1.1.1 fix *_limp no work proper, optimize code more robust thanks to Silvers; 13-November-2022 (2nd time)
 *	v1.2 new ConVar *_tap_interval to control interval time between double tap forward key,
 *		make damage randomly if *_ache_amount less than 1; 14-November-2022
 *	v2.0 new features, fixes:
 *		- new Stamina mode, to instead hurt mode, if stamina used up, survivor speed gets down:
 *			- new ConVar *_stamina to control max stamina duration, if set then use stamina mode
 *			- new ConVar *_stamina_penalty_rate to control panalty move speed if stamina use up,
 *			- new ConVar *_stamina_progress to print stamina progress text position,
 *			- new ConVar *_stamina_recovery_rate to scale stamina recovery ratio,
 *			- ConVars *_ache_* also control the stamina mode,
 *		- fix key not detecting on incapped,
 *		- fix double tap mode not work,
 *		- remove ConVar *_sound_delay,
 *		- double tap mode now can accept any move key,
 *		- simplify codes, remove useless sounds because they sounds same,
 *		- uploaded translation file for stamina mode; 13-December-2022
 *	v2.0.1 optimizes:
 *		- optimize double tap logic,
 *		- clear state when player unavailable; 13-December-2022 (2nd time)
 *	v2.1 new features:
 *		- new Command +dash -dash let player work on "bind shift +dash"; 21-December-2022
 *	v2.2 fixes:
 *		- add Command sm_dashstart, sm_dashstop for dedicated server,
 *		- fix dash command wrong speed on *_tap == 0,
 *		- when set _ache_adren as 0, adrenaline state will ignore *_limp; 22-December-2022
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsAliveHumanSurvivor(%1) (IsClient(%1) && GetClientTeam(%1) == 2 && !IsFakeClient(%1) && IsPlayerAlive(%1))

#define SOUND_DASH		"weapons/crowbar/crowbar_swing_miss1.wav"

bool bIsLeft4Dead2;
bool bLaggedMovementExists;
bool bLateLoad;
bool hasTranslations;

native any L4D_LaggedMovement(int client, float value, bool force = false);
forward Action L4D_OnGetWalkTopSpeed(int client, float &retVal);
native float L4D_GetTempHealth(int client);
forward Action L4D_OnGetRunTopSpeed(int target, float &retVal);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	bLateLoad = late;

	bIsLeft4Dead2 = GetEngineVersion() == Engine_Left4Dead2;

	MarkNativeAsOptional("L4D_LaggedMovement");
	MarkNativeAsOptional("L4D_GetTempHealth");

	return APLRes_Success;

}

public void OnLibraryAdded(const char[] name) {
	if (strcmp(name, "LaggedMovement") == 0) {
		bLaggedMovementExists = true;
	}
}

public void OnLibraryRemoved(const char[] name) {
	if (strcmp(name, "LaggedMovement") == 0) {
		bLaggedMovementExists = false;
	}
}
public void OnAllPluginsLoaded() {
	// Require Left4DHooks
	if( !LibraryExists("left4dhooks") ) {
		LogMessage	("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
		SetFailState("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
	}

	bLaggedMovementExists = LibraryExists("LaggedMovement");
}

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cAcheInterval;		float flAcheInterval;
ConVar cAcheAmount;			float flAcheAmount;
ConVar cAcheAdren;			bool bAcheAdren;
ConVar cSound;				bool bSound;
ConVar cLimp;				float flLimp;
ConVar cBoost;				float flBoost;
ConVar cSurvivorSpeed;		float flSurvivorSpeed;
ConVar cMode;				int iMode;
ConVar cTap;				bool bTap;
ConVar cTapinterval;		float flTapInterval;
ConVar cStaminaMax;			float flStaminaMax;
ConVar cStaminaPenaltyRate;	float flStaminaPenaltyRate;
ConVar cStaminaProgress;	int iStaminaProgress;
ConVar cStaminaRecoveryRate;float flStaminaRecoveryRate;

float flMultiplierWalk;


public void OnPluginStart() {

	CreateConVar						(PLUGIN_NAME, PLUGIN_VERSION,						"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cAcheInterval =			CreateConVar(PLUGIN_NAME ... "_ache_interval", "1.0",			"interval(seconds) of hurt survivor when keep dashing", FCVAR_NOTIFY);
	cAcheAmount =			CreateConVar(PLUGIN_NAME ... "_ache_amount", "2.0",				"damage to hurt survivor every interval, less than 1 will be randomly", FCVAR_NOTIFY);
	cAcheAdren =			CreateConVar(PLUGIN_NAME ... "_ache_adren", "0",				"hurt survivor even he under adrenaline duration", FCVAR_NOTIFY);
	cSound =				CreateConVar(PLUGIN_NAME ... "_sound", "1",						"does play dash sound for dashing", FCVAR_NOTIFY);
	cLimp =					CreateConVar(PLUGIN_NAME ... "_limp", "4.0",					"stop dashing when health under this value", FCVAR_NOTIFY);
	cBoost =				CreateConVar(PLUGIN_NAME ... "_boost", "1.5",					"boost rate of dashing", FCVAR_NOTIFY);
	cSurvivorSpeed =		FindConVar	("survivor_speed");
	cMode =					CreateConVar(PLUGIN_NAME ... "_mode", "0",						"boost mode 0=L4D_OnGet*TopSpeed(more compatibility)\n1=m_flLaggedMovementValue(most smoothly, only suggest on *_tap 1)", FCVAR_NOTIFY);
	cTap =					CreateConVar(PLUGIN_NAME ... "_tap", "0",						"method to trigger dash 0=shift+move key 1=double tap move key", FCVAR_NOTIFY);
	cTapinterval =			CreateConVar(PLUGIN_NAME ... "_tap_interval", "0.3",			"interval(seconds) to trigger double tap", FCVAR_NOTIFY);
	cStaminaMax =			CreateConVar(PLUGIN_NAME ... "_stamina", "0",					"duration(seconds) of stamina mode, set duration use stamina mode to instead ache mode", FCVAR_NOTIFY);
	cStaminaPenaltyRate =	CreateConVar(PLUGIN_NAME ... "_stamina_penalty_rate", "0.5",	"factor to scale speed when used up stamina during penelty", FCVAR_NOTIFY);
	cStaminaProgress =		CreateConVar(PLUGIN_NAME ... "_stamina_progress", "1",			"stamina progress bar position, 1=center text 2=hint text 0=disabled", FCVAR_NOTIFY);
	cStaminaRecoveryRate =	CreateConVar(PLUGIN_NAME ... "_stamina_recovery_rate", "0.5",	"stamina recovery rate", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cAcheInterval.AddChangeHook(OnConVarChanged);
	cAcheAmount.AddChangeHook(OnConVarChanged);
	cAcheInterval.AddChangeHook(OnConVarChanged);
	cAcheAdren.AddChangeHook(OnConVarChanged);
	cSound.AddChangeHook(OnConVarChanged);
	cLimp.AddChangeHook(OnConVarChanged);
	cBoost.AddChangeHook(OnConVarChanged);
	cSurvivorSpeed.AddChangeHook(OnConVarChanged);
	cMode.AddChangeHook(OnConVarChanged);
	cTap.AddChangeHook(OnConVarChanged);
	cTapinterval.AddChangeHook(OnConVarChanged);
	cStaminaMax.AddChangeHook(OnConVarChanged);
	cStaminaPenaltyRate.AddChangeHook(OnConVarChanged);
	cStaminaProgress.AddChangeHook(OnConVarChanged);
	cStaminaRecoveryRate.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	// build translations file
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/" ... PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt");
	hasTranslations = FileExists(path);

	if (hasTranslations)
		LoadTranslations(PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases");
	else
		LogError("not translations file %s found yet, please check install guide for %s", PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt", PLUGIN_NAME_FULL);

	// lateload
	if (bLateLoad) {
		for (int client = 1; client <= MaxClients; client++)
			if (IsClientInGame(client))
				OnClientPutInServer(client);
	}

	RegConsoleCmd("+dash", CommandDashStart, "start dashing");
	RegConsoleCmd("sm_dashstart", CommandDashStart, "start dashing");
	RegConsoleCmd("-dash", CommandDashStop, "stop dash");
	RegConsoleCmd("sm_dashstop", CommandDashStop, "stop dash");

}


void ApplyCvars() {

	flAcheInterval = cAcheInterval.FloatValue;
	flAcheAmount = cAcheAmount.FloatValue;
	bAcheAdren = cAcheAdren.BoolValue;
	bSound = cSound.BoolValue;
	flLimp = cLimp.FloatValue;
	flSurvivorSpeed = cSurvivorSpeed.FloatValue;
	flBoost = cBoost.FloatValue

	flMultiplierWalk = flSurvivorSpeed / 85.0;
	// walking 85, crouch 75
	iMode = cMode.IntValue;
	bTap = cTap.BoolValue;
	flTapInterval = cTapinterval.FloatValue;

	flStaminaMax = cStaminaMax.FloatValue;
	flStaminaPenaltyRate = cStaminaPenaltyRate.FloatValue;
	iStaminaProgress = cStaminaProgress.IntValue;
	flStaminaRecoveryRate = cStaminaRecoveryRate.FloatValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnMapStart() {

	if (bIsLeft4Dead2)
		PrecacheSound(SOUND_DASH);
}

bool bBoostActivated [MAXPLAYERS + 1];
int iButtonsLast [MAXPLAYERS + 1];
bool bStaminaPenalty [MAXPLAYERS + 1]
float flStamina [MAXPLAYERS + 1];
Handle timer[MAXPLAYERS + 1];

Action CommandDashStart(int client, int args) {

	if (IsAliveHumanSurvivor(client) && GetClientButtons(client) & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT))
		TryDash(client);

	return Plugin_Handled;
}

Action CommandDashStop(int client, int args) {

	if (IsAliveHumanSurvivor(client))
		StopDash(client);

	return Plugin_Handled;
}


public Action L4D_OnGetWalkTopSpeed(int client, float &retVal) {

	if (bStaminaPenalty[client])
		return Plugin_Continue;

	if (bBoostActivated[client]) {

		// ==========
		// Code taken from "Weapons Movement Speed" by "Silvers"
		// Fix movement speed bug when jumping or staggering
		if( iMode == 1 && GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1 || GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > -1.0 ) {
			// Fix jumping resetting velocity to default
			float value = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
			if( value != 1.0 ) {
				float vVec[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVec);
				float height = vVec[2];

				ScaleVector(vVec, value);
				vVec[2] = height; // Maintain default jump height

				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVec);
			}

			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", bLaggedMovementExists ? L4D_LaggedMovement(client, 1.0, true) : 1.0);
			return Plugin_Continue;
		}
		// ==========

		if (flLimp && GetClientHealth(client) + L4D_GetTempHealth(client) < flLimp && !(bIsLeft4Dead2 && !bAcheAdren && GetEntProp(client, Prop_Send, "m_bAdrenalineActive")))

			StopDash(client);

		else {

			switch (iMode) {
				case 0 : {
					retVal *= flMultiplierWalk * flBoost;
					return Plugin_Handled;
				}
				case 1 : {
					SetTerrorMovement(client, flMultiplierWalk * flBoost);
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action L4D_OnGetRunTopSpeed(int client, float &retVal) {

	if (bStaminaPenalty[client]) {
		SetTerrorMovement(client, flStaminaPenaltyRate);
		return Plugin_Continue;
	}

	if (bBoostActivated[client] && !(iButtonsLast[client] & IN_SPEED)) {

		// ==========
		// Code taken from "Weapons Movement Speed" by "Silvers"
		// Fix movement speed bug when jumping or staggering
		if( iMode == 1 && GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1 || GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > -1.0 ) {
			// Fix jumping resetting velocity to default
			float value = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
			if( value != 1.0 ) {
				float vVec[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVec);
				float height = vVec[2];

				ScaleVector(vVec, value);
				vVec[2] = height; // Maintain default jump height

				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVec);
			}

			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", bLaggedMovementExists ? L4D_LaggedMovement(client, 1.0, true) : 1.0);
			return Plugin_Continue;
		}
		// ==========


		if (flLimp && GetClientHealth(client) + L4D_GetTempHealth(client) < flLimp && !(bIsLeft4Dead2 && !bAcheAdren && GetEntProp(client, Prop_Send, "m_bAdrenalineActive")))

			StopDash(client);

		else {

			switch (iMode) {
				case 0 : {
					retVal *= flBoost;
					return Plugin_Handled;
				}
				case 1 : {
					SetTerrorMovement(client, flBoost);
				}
			}
		}
	}

	return Plugin_Continue;
}

void SetTerrorMovement(int entity, float rate) {
	SetEntPropFloat(entity, Prop_Send, "m_flLaggedMovementValue", bLaggedMovementExists ? L4D_LaggedMovement(entity, rate) : rate);
}

public void OnClientPutInServer(int client) {
	flStamina[client] = flStaminaMax;
}

public void OnClientDisconnect_Post(int client) {

	iButtonsLast[client] = 0;

	if (timer[client])
		delete timer[client];
}

bool TryDash(int client) {

	if (!bStaminaPenalty[client] && !bBoostActivated[client]) {

		int health = GetClientHealth(client);
		float temp = L4D_GetTempHealth(client);

		if (health + temp > flLimp) {
			
			bBoostActivated[client] = true;

			if (flStaminaMax > 0) {
				if (!timer[client])
					timer[client] = CreateTimer(flAcheInterval, TimerStamina, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			} else
				timer[client] = CreateTimer(flAcheInterval, TimerHurt, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

			if (bSound && bIsLeft4Dead2)
				EmitSoundToClient(client, SOUND_DASH);

			return true;
		}
	}

	return false;
}

void StopDash(int client) {

	bBoostActivated[client] = false;

	if (timer[client] && flStaminaMax <= 0)
		delete timer[client];

	if (iMode == 1)
		SetTerrorMovement(client, 1.0);
}


public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {

	if (IsAliveHumanSurvivor(client) && !bStaminaPenalty[client]) {

		if (bTap) {

			bool moved_left = buttons & IN_MOVELEFT && !(iButtonsLast[client] & IN_MOVELEFT),
				 moved_right = buttons & IN_MOVERIGHT && !(iButtonsLast[client] & IN_MOVERIGHT),
				 moved_forward = buttons & IN_FORWARD && !(iButtonsLast[client] & IN_FORWARD),
				 moved_back = buttons & IN_BACK && !(iButtonsLast[client] & IN_BACK);

			static float moved_last_left [MAXPLAYERS + 1],
						 moved_last_right [MAXPLAYERS + 1],
						 moved_last_forward [MAXPLAYERS + 1],
						 moved_last_back [MAXPLAYERS + 1];

			float time = GetEngineTime();

			if ( !(iButtonsLast[client] & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)) &&
				 (
				 	(moved_left && time - moved_last_left[client] < flTapInterval) || 
	 				 (moved_right && time - moved_last_right[client] < flTapInterval) ||
	 				 (moved_forward && time - moved_last_forward[client] < flTapInterval) ||
	 				 (moved_back && time - moved_last_back[client] < flTapInterval)
				 )
			) {
				TryDash(client);
			}

			if ( !(buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)) && iButtonsLast[client] & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) )
				StopDash(client);

			if (moved_left)
				moved_last_left[client] = time;

			if (moved_right)
				moved_last_right[client] = time;

			if (moved_forward)
				moved_last_forward[client] = time;

			if (moved_back)
				moved_last_back[client] = time;

		} else {

			bool bShiftPressed = buttons & IN_SPEED && !(iButtonsLast[client] & IN_SPEED),
				bShiftReleased = !(buttons & IN_SPEED) && iButtonsLast[client] & IN_SPEED;

			if (bShiftPressed)
				TryDash(client);

			if (bShiftReleased)
				StopDash(client);
		}
	}

	iButtonsLast[client] = buttons;
}

Action TimerStamina(Handle self, int client) {

	client = GetClientOfUserId(client);

	if (IsAliveHumanSurvivor(client)) {


		int moving = iButtonsLast[client] & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT);

		// actived stamina mode
		if (flStaminaMax > 0) {

			// has stamina and not during penalty
			if (flStamina[client] >= 0 && !bStaminaPenalty[client] && moving && bBoostActivated[client]) {

				if (bIsLeft4Dead2 && !bAcheAdren && GetEntProp(client, Prop_Send, "m_bAdrenalineActive"))
					return Plugin_Continue;

				// reduce stamina
				flStamina[client] -= flAcheAmount;
				DisplayStamina(client);

				return Plugin_Continue;
			}
			// not enough stamina or during penalty
			if (flStamina[client] < 0 && !bStaminaPenalty[client]) {


				// enter penalty if not yet 
				bBoostActivated[client] = false;
				bStaminaPenalty[client] = true;
				return Plugin_Continue;

			} else if (flStamina[client] < flStaminaMax) {

				// recovery stamina
				flStamina[client] += flAcheAmount * flStaminaRecoveryRate;
				DisplayStamina(client);

				// stop recovery when stamina fulled, and cancel penalty
				if (flStamina[client] >= flStaminaMax) {

					flStamina[client] = flStaminaMax;

					bStaminaPenalty[client] = false;

					timer[client] = null;

					if (iMode == 1)
						SetTerrorMovement(client, 1.0);

					return Plugin_Stop;

				} else

					return Plugin_Continue;
			}
		}
	}

	flStamina[client] = flStaminaMax;
	bBoostActivated[client] = false;
	bStaminaPenalty[client] = false;
	timer[client] = null;
	return Plugin_Stop;
}

Action TimerHurt(Handle self, int client) {

	client = GetClientOfUserId(client);

	if (IsAliveHumanSurvivor(client)) {

		int health = GetClientHealth(client);
		float temp = L4D_GetTempHealth(client);

		int moving = iButtonsLast[client] & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT);

		if (flAcheAmount > 0 && moving && health + temp > flLimp && bBoostActivated[client]) {

			if (bIsLeft4Dead2 && !bAcheAdren && GetEntProp(client, Prop_Send, "m_bAdrenalineActive"))
				return Plugin_Continue;

			SDKHooks_TakeDamage(client, client, client, LuckyFloat(flAcheAmount), DMG_GENERIC);
		}

		return Plugin_Continue;
	}

	timer[client] = null;
	return Plugin_Stop;
}

float LuckyFloat(float floating) {

	int floor = RoundToFloor(floating);

	int luck = (floating - floor) > GetURandomFloat();

	return float(floor + luck);
}

void DisplayStamina(int client) {

	static char text[32];

	for(int i = 0; i < sizeof(text) - 1 ; i++)
		if (i < RoundToNearest(flStamina[client] / flStaminaMax * sizeof(text)))
			text[i] = '#';
		else
			text[i] = '=';

	text[sizeof(text) - 1] = '\0';

	SetGlobalTransTarget(client);

	switch (iStaminaProgress) {
		case 1 : {
			if (hasTranslations)
				PrintCenterText(client, "%t[%s]", "Stamina", text);
			else
				PrintCenterText(client, "Stamina: [%s]", text);
		}
		case 2 : {
			if (hasTranslations)
				PrintHintText(client, "%t[%s]", "Stamina", text);
			else
				PrintHintText(client, "Stamina: [%s]", text);
		}
	}
}