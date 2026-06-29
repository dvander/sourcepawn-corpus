#define PLUGIN_VERSION		"1.3"
#define PLUGIN_NAME			"feeding_medicines"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] Feeding Medicines"
#define PLUGIN_DESCRIPTION	"why you guys dont eat pills"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://steamcommunity.com/id/NoroHime/"
/**
 *	v1.0 just releases; 14-March-2022
 *	v1.1 new features:
 *		add sound effects support 'adren start', 'adren injected', 'pills start', 'pills used', 'pills ate',
 *		optional feeding self,
 *		optional reward feeder health or buff health,
 *		fix issue 'feeding to an incapped player'; 16-March-2022
 *	v1.2 new features:
 *		healing anim support
 *		wont aggresive stops unreleated progress bar
 *	v1.2.1 fix issue 'feeding_medicines_allows not work proper', support online compile; 23-March-2022
 *	v1.2.2 fix issue 'be feeding target sometime stuck on third person view', change animation work way to solve unknown performance issue; 27-April-2022
 *	v1.2.3 add support for l4d1, fix some adrenaline duration incorrret; 6-November-2022
 *	v1.2.4 swap the sequence between fire event and health given, to solve compatiblity of third-party plugins; 20-November-2022
 *	v1.2.5 try to add support for l4d1, but not tested ; 28-November-2022
 *	v1.2.6 fixes
 *		- fix an unknown issue (about animation hooks) cause conflict to '[L4D & L4D2] Incapped Weapons Patch' v1.16 and newer ,
 *		- turn code style to hungarian notation, make animation work way to more effective, remove deprecated IsValidHandle(),
 *		- trying support l4d1; 9-December-2022
 *	v1.3 now officially support l4d1, fix some progress bar wrong target on l4d1; 10-December-2022
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

typeset AnimHookCallback {
	function Action(int client, int &sequence);
}

native bool AnimHookEnable(int client, AnimHookCallback callback, AnimHookCallback callbackPost = INVALID_FUNCTION);
native bool AnimHookDisable(int client, AnimHookCallback callback, AnimHookCallback callbackPost = INVALID_FUNCTION);
native int AnimGetFromActivity(char[] activity);
native float L4D_GetTempHealth(int client);
native int L4D_SetTempHealth(int client, float health);

forward Action L4D_OnLedgeGrabbed(int client);
forward Action L4D2_OnStagger(int target, int source);
forward Action L4D2_OnPounceOrLeapStumble(int victim, int attacker);
forward Action L4D_OnPouncedOnSurvivor(int victim, int attacker);
forward Action L4D_OnGrabWithTongue(int victim, int attacker);
forward Action L4D2_OnJockeyRide(int victim, int attacker);
forward Action L4D2_OnStartCarryingVictim(int victim, int attacker);

enum {
	Provider =		(1 << 0),
	Receiver =		(1 << 1),
}

enum {
	Other = 0,
	Pills =				(1 << 0),
	Adrenaline =		(1 << 1),
	PillsEvent =		(1 << 2),
	AdrenalineEvent =	(1 << 3),
}

#define SOUND_REJECT			"buttons/button11.wav"
#define SOUND_ADRENALINE_START	"weapons/adrenaline/adrenaline_cap_off.wav"
#define SOUND_ADRENALINE_END	"weapons/adrenaline/adrenaline_needle_in.wav"
#define SOUND_PILLS_START		"player/items/pain_pills/pills_deploy_2.wav"
#define SOUND_PILLS_END_ATE		"player/items/pain_pills/pills_use_1.wav"
#define SOUND_PILLS_END_USED	"player/items/pain_pills/pills_deploy_1.wav"

ConVar cProgressTargets;	int iProgressTargets;
ConVar cAllowMedicines;		int iAllowMedicines;
ConVar cActions;			int iActions;
ConVar cPillsBuff;			float flPillsBuff;
ConVar cAdrenalineBuff;		float flAdrenalineBuff;
ConVar cHealthMax;			float flHealthMax;
ConVar cFirstAidCap;
ConVar cOverflowTurn;		float flOverflowTurn;
ConVar cAdrenalineDuration;	float flAdrenalineDuration;
ConVar cUseDuration;		float flUseDuration;
ConVar cReward;				float flReward;
ConVar cAllowSelf;			int iAllowSelf;
ConVar cAllowAnimation;		bool bAllowAnimation;

bool bIsLeft4Dead2 = false,
	 bLateLoad = false;

public Plugin myinfo = {
	name = PLUGIN_NAME_FULL,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_LINK
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	bIsLeft4Dead2 = GetEngineVersion() == Engine_Left4Dead2;

	bLateLoad = late;

	MarkNativeAsOptional("AnimHookEnable");
	MarkNativeAsOptional("AnimHookDisable");
	MarkNativeAsOptional("AnimGetFromActivity");
	MarkNativeAsOptional("L4D_GetTempHealth");
	MarkNativeAsOptional("L4D_SetTempHealth");

	return APLRes_Success; 
}

public void OnPluginStart() {

	CreateConVar						(PLUGIN_NAME ... "_version", PLUGIN_VERSION,		"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cProgressTargets = 					CreateConVar(PLUGIN_NAME ... "_progress", "-1",		"which targets showing feeding progress bar 1=Feeder 2=Be Feeding -1=Both 0=Disable", FCVAR_NOTIFY);
	cAllowMedicines = 					CreateConVar(PLUGIN_NAME ... "_allows", "-1",		"which medicines allow feeding for teammate 1=Pills 2=Adrenaline -1=Both 0=why you install this plugin", FCVAR_NOTIFY);
	cActions = 							CreateConVar(PLUGIN_NAME ... "_actions", "-1",		"which action doing when medicine feeded 1=Pills buff 2=Adrenaline and buff 4=pills event 8=adren event -1=All 0=Disabled", FCVAR_NOTIFY);
	cHealthMax = 						CreateConVar(PLUGIN_NAME ... "_max", "-1",			"limit of health max -1=Use first_aid_kit_max_heal", FCVAR_NOTIFY);
	cOverflowTurn =						CreateConVar(PLUGIN_NAME ... "_overflow", "0.5",	"rate of turn the overflow temp health to real health when reached max, 0.5: turn as half 0: disable 1: completely turn", FCVAR_NOTIFY);
	cUseDuration =						CreateConVar(PLUGIN_NAME ... "_duration", "2.0",	"use duration of feeding a medicine (remarks: l4d1 use integer)", FCVAR_NOTIFY);
	cReward =							CreateConVar(PLUGIN_NAME ... "_reward", "-10",		"health reward of feeder -10=10 buff health 15=15 health 0=disabled", FCVAR_NOTIFY);
	cAllowSelf =						CreateConVar(PLUGIN_NAME ... "_self", "2",			"allow player feeding him self 1=allow feed self 2=also reward health", FCVAR_NOTIFY);
	cAllowAnimation =					CreateConVar(PLUGIN_NAME ... "_anim", "1",			"play healing animation on healer", FCVAR_NOTIFY);


	cPillsBuff = 						FindConVar("pain_pills_health_value");
	cFirstAidCap = 						FindConVar("first_aid_kit_max_heal");

	if (bIsLeft4Dead2) {
		cAdrenalineBuff =				FindConVar("adrenaline_health_buffer");
		cAdrenalineDuration =			FindConVar("adrenaline_duration");
	}

	AutoExecConfig(true, "l4d_" ... PLUGIN_NAME);

	HookEvent("player_incapacitated_start", OnIncapped);
	HookEvent("player_death", OnIncapped);

	cProgressTargets		.AddChangeHook(OnConVarChanged);
	cAllowMedicines			.AddChangeHook(OnConVarChanged);
	cActions				.AddChangeHook(OnConVarChanged);
	cPillsBuff				.AddChangeHook(OnConVarChanged);
	cHealthMax				.AddChangeHook(OnConVarChanged);
	cOverflowTurn			.AddChangeHook(OnConVarChanged);
	cFirstAidCap			.AddChangeHook(OnConVarChanged);

	if (bIsLeft4Dead2) {
		cAdrenalineBuff		.AddChangeHook(OnConVarChanged);
		cAdrenalineDuration	.AddChangeHook(OnConVarChanged);
	}

	cUseDuration			.AddChangeHook(OnConVarChanged);
	cReward					.AddChangeHook(OnConVarChanged);
	cAllowSelf				.AddChangeHook(OnConVarChanged);
	cAllowAnimation			.AddChangeHook(OnConVarChanged);
	
	ApplyCvars();

	// Late Load
	if (bLateLoad)
		for(int i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i))
				OnClientPutInServer(i);
}

public void OnMapStart() {
	PrecacheSound(SOUND_REJECT);
	PrecacheSound(SOUND_PILLS_START);
	PrecacheSound(SOUND_PILLS_END_ATE);
	PrecacheSound(SOUND_PILLS_END_USED);

	if (bIsLeft4Dead2) {
		PrecacheSound(SOUND_ADRENALINE_START);
		PrecacheSound(SOUND_ADRENALINE_END);
	}
}

public void ApplyCvars() {
	
	iProgressTargets = cProgressTargets.IntValue;
	iAllowMedicines = cAllowMedicines.IntValue;
	iActions = cActions.IntValue;
	flPillsBuff = cPillsBuff.FloatValue;
	flOverflowTurn = cOverflowTurn.FloatValue;
	flHealthMax = cHealthMax.FloatValue;
	if (flHealthMax < 0)
		flHealthMax = cFirstAidCap.FloatValue;
	flUseDuration = cUseDuration.FloatValue;
	flReward = cReward.FloatValue;
	iAllowSelf = cAllowSelf.IntValue;
	bAllowAnimation = cAllowAnimation.BoolValue;

	if (bIsLeft4Dead2) {
		flAdrenalineBuff = cAdrenalineBuff.FloatValue;
		flAdrenalineDuration = cAdrenalineDuration.FloatValue;
	}
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

int iFeedingTarget [MAXPLAYERS + 1];
Handle timerFeeding [MAXPLAYERS + 1];
bool bHookedAnimation [MAXPLAYERS + 1];

int CheckMedicine(int client, int weapon = 0) {

	if (!weapon)
		weapon = L4D_GetPlayerCurrentWeapon(client);

	if (IsValidEdict(weapon)) {

		static char name_weapon[32];
		GetEntityClassname(weapon, name_weapon, sizeof(name_weapon));

		if (strcmp(name_weapon, "weapon_pain_pills") == 0)
			return Pills;

		if (strcmp(name_weapon, "weapon_adrenaline") == 0)
			return Adrenaline;
		
	}
	return Other;		
}

void CancelFeeding(int client) {

	if (IsSurvivor(client)) {

		if (iFeedingTarget[client]) {

			if (iProgressTargets & Provider)
				SetupProgressBar(client);

			if (iProgressTargets & Receiver && IsAliveSurvivor(iFeedingTarget[client]))
				SetupProgressBar(iFeedingTarget[client]);
		}

		iFeedingTarget[client] = 0;

		if (bAllowAnimation && bHookedAnimation[client]) {
			AnimHookDisable(client, OnFeedingAnimation);
			bHookedAnimation[client] = false;
		}

		for (int i = 1; i <= MaxClients; i++) {
			if (iFeedingTarget[i] == client) {
				SetupProgressBar(i);
				SetupProgressBar(client);
				iFeedingTarget[i] = 0;
			}
		}

		if (timerFeeding[client] != null)
			delete timerFeeding[client];
	}	
}

void StartFeeding(int provider, int receiver) {

	if (iProgressTargets & Provider)
		SetupProgressBar(provider, flUseDuration, 1, receiver, provider);

	if (iProgressTargets & Receiver)
		SetupProgressBar(receiver, flUseDuration, 1, provider, receiver);

	iFeedingTarget[provider] = receiver;

	timerFeeding[provider] = CreateTimer(flUseDuration, EndFeeding, provider);

	if (bAllowAnimation && !bHookedAnimation[provider]) {
		AnimHookEnable(provider, OnFeedingAnimation);
		bHookedAnimation[provider] = true;
	}
}

public Action EndFeeding(Handle timer, int provider) {

	timerFeeding[provider] = null;
	
	switch (CheckMedicine(provider)) {

		case Pills : {

			int receiver = iFeedingTarget[provider];

			if (iAllowMedicines & Pills && IsAliveSurvivor(receiver) && !L4D_IsPlayerIncapacitated(receiver)) {

				if (RemovePlayerItem( provider, L4D_GetPlayerCurrentWeapon(provider) )) {

					if (iActions & PillsEvent) {
						Event ate = CreateEvent("pills_used");

						int userid_receiver = GetClientUserId(receiver);

						if (ate) {
							ate.SetInt("userid", userid_receiver);
							ate.SetInt("subject", userid_receiver);
							ate.Fire();
						}
					}

					if (iActions & Pills)
						AddBuffer(receiver, flPillsBuff);

					if ( flReward && ( (provider != receiver) || (iAllowSelf == 2) ) ) {

						if (flReward < 0)
							AddBuffer(provider, -flReward);
						else if (flReward > 0) {
							AddHealth(provider, LuckyFloat(flReward));
							AddBuffer(provider, 0.0);
						}
					}

					EmitSoundToClient(receiver, SOUND_PILLS_END_ATE);
					EmitSoundToClient(provider, SOUND_PILLS_END_USED);
				}
			}
		}
		case Adrenaline : {

			int receiver = iFeedingTarget[provider];

			if (iAllowMedicines & Adrenaline && IsAliveSurvivor(receiver) && !L4D_IsPlayerIncapacitated(receiver)) {

				if (RemovePlayerItem( provider, L4D_GetPlayerCurrentWeapon(provider) )) {

					if (iActions & AdrenalineEvent) {
						Event ate = CreateEvent("adrenaline_used");

						int userid_receiver = GetClientUserId(receiver);

						if (ate) {
							ate.SetInt("userid", userid_receiver);
							ate.Fire();
						}
					}

					if (iActions & Adrenaline) {
						AddBuffer(receiver, flAdrenalineBuff);

						float adren_remain = Terror_GetAdrenalineTime(receiver);
						Terror_SetAdrenalineTime(receiver, adren_remain < 0 ? flAdrenalineDuration : adren_remain + flAdrenalineDuration);
					}

					if ( flReward && ( (provider != receiver) || (iAllowSelf == 2) ) ) {

						if (flReward < 0)
							AddBuffer(provider, -flReward);
						else if (flReward > 0) {
							AddHealth(provider, LuckyFloat(flReward));
							AddBuffer(provider, 0.0);
						}
					}

					EmitSoundToClient(receiver, SOUND_ADRENALINE_END);
					EmitSoundToClient(provider, SOUND_ADRENALINE_END);
				}
			}
		}
	}

	if (iProgressTargets & Provider)
		SetupProgressBar(provider);

	if (iProgressTargets & Receiver)
		SetupProgressBar(iFeedingTarget[provider]);

	iFeedingTarget[provider] = 0;

	return Plugin_Stop;
}

public void OnUsePost(int entity, int activator, int caller, UseType type, float value) {

	if (entity == activator && !iAllowSelf)
		return;

	if (IsAliveSurvivor(entity) && !L4D_IsPlayerIncapacitated(entity) && IsAliveHumanSurvivor(activator)) {

		switch (CheckMedicine(activator)) {

			case Pills :

				if (iAllowMedicines & Pills) 

					if (IsAllowedHeal(entity)) {

						StartFeeding(activator, entity);

						EmitSoundToClient(entity, SOUND_PILLS_START);
						EmitSoundToClient(activator, SOUND_PILLS_START);
					}
					else
						EmitSoundToClient(activator, SOUND_REJECT);

			case Adrenaline :

				if (iAllowMedicines & Adrenaline)

					if (IsAllowedHeal(entity)) {

						StartFeeding(activator, entity);

						EmitSoundToClient(entity, SOUND_ADRENALINE_START);
						EmitSoundToClient(activator, SOUND_ADRENALINE_START);
					}
					else
						EmitSoundToClient(activator, SOUND_REJECT);
		}
	}
}

bool IsAllowedHeal(int client) {

	float buffing = L4D_GetTempHealth(client);
	int healthy = GetClientHealth(client);

	if (buffing + healthy > flHealthMax) {

		if (flOverflowTurn && healthy < flHealthMax)

			return true;

		return false;

	} else

		return true;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {

	static int buttons_last[MAXPLAYERS + 1];

	bool use_released = !(buttons & IN_USE) && (buttons_last[client] & IN_USE);
	buttons_last[client] = buttons;

	if (use_released && IsAliveHumanSurvivor(client))
		CancelFeeding(client);
}

public void OnClientPutInServer(int client) {

	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	SDKHook(client, SDKHook_UsePost, OnUsePost);
}

public void OnClientDisconnect_Post(int client) {

	iFeedingTarget[client] = 0;

	if (timerFeeding[client] != null)
		delete timerFeeding[client];

	if (bAllowAnimation)
		AnimHookDisable(client, OnFeedingAnimation);
}

enum {
	L4D1_ACT_TERROR_HEAL_SELF = 1080,
	L4D1_ACT_TERROR_HEAL_FRIEND = 1081,
	L4D2_ACT_TERROR_HEAL_SELF = 544,
	L4D2_ACT_TERROR_HEAL_FRIEND = 545
}

public Action OnFeedingAnimation(int client, int &sequence) {

	if (iFeedingTarget[client]) {

		if (iFeedingTarget[client] == client)

			sequence = bIsLeft4Dead2 ? L4D2_ACT_TERROR_HEAL_SELF : L4D1_ACT_TERROR_HEAL_SELF;

		else 

			sequence = bIsLeft4Dead2 ? L4D2_ACT_TERROR_HEAL_FRIEND : L4D1_ACT_TERROR_HEAL_FRIEND;

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

void SetupProgressBar(int client, float time = 0.0, int action = 0, int entity_target = -1, int entity_owner = -1) {

	if (!IsSurvivor(client))
		return;

	if (bIsLeft4Dead2) {

		SetEntPropEnt(client, Prop_Send, "m_useActionTarget", entity_target);

		SetEntPropEnt(client, Prop_Send, "m_useActionOwner", entity_owner);

		SetEntProp(client, Prop_Send, "m_iCurrentUseAction", action);

		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);

	} else {

		SetEntPropString(client, Prop_Send, "m_progressBarText", "Feeding Medicine...");

		SetEntPropEnt(client, Prop_Send, "m_healTarget", entity_target);
		SetEntPropEnt(client, Prop_Send, "m_healOwner", entity_owner);

		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", RoundToFloor(time));
	}
}

public void OnWeaponSwitchPost(int client, int weapon) {

	if (IsAliveHumanSurvivor(client))
		CancelFeeding(client);
}

void AddBuffer(int client, float buff) {

	float buffing = L4D_GetTempHealth(client);
	int health = GetClientHealth(client);

	if (health + buffing + buff > flHealthMax) {

		if (flOverflowTurn > 0) {

			float overflow = FloatAbs(flHealthMax - health - buffing - buff) * flOverflowTurn;

			if (health + overflow > flHealthMax) {

				SetEntityHealth(client, RoundToFloor(flHealthMax));
				L4D_SetTempHealth(client, 0.0);

			} else {

				SetEntityHealth(client, health + RoundToFloor(overflow));
				L4D_SetTempHealth(client, flHealthMax - health - overflow);
			}
		} else 
			L4D_SetTempHealth(client, flHealthMax - health);
	
		} else 
			L4D_SetTempHealth(client, buffing + buff);
}

void AddHealth(int client, int health) {

	int healthy = GetClientHealth(client);

	if (healthy + health > flHealthMax) {

		if (healthy >= flHealthMax) //dont change if reached max
			return;
		else
			SetEntityHealth(client, RoundToFloor(flHealthMax));

	} else
		SetEntityHealth(client, healthy + health);
}

int LuckyFloat(float floating) {

	int floor = RoundToFloor(floating);

	int luck = (floating - floor) > GetURandomFloat();

	return floor + luck;
}

public void OnIncapped(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));
	CancelFeeding(client);
}

public Action L4D_OnLedgeGrabbed(int client) {
	CancelFeeding(client);
	return Plugin_Continue;
}

public Action L4D2_OnStagger(int target, int source) {
	CancelFeeding(target);
	return Plugin_Continue;
}

public Action L4D2_OnPounceOrLeapStumble(int victim, int attacker) {
	CancelFeeding(victim);
	return Plugin_Continue;
}

public Action L4D_OnPouncedOnSurvivor(int victim, int attacker) {
	CancelFeeding(victim);
	return Plugin_Continue;
}

public Action L4D_OnGrabWithTongue(int victim, int attacker) {
	CancelFeeding(victim);
	return Plugin_Continue;
}

public Action L4D2_OnJockeyRide(int victim, int attacker) {
	CancelFeeding(victim);
	return Plugin_Continue;
}

public Action L4D2_OnStartCarryingVictim(int victim, int attacker) {
	CancelFeeding(victim);
	return Plugin_Continue;
}

bool IsAliveHumanSurvivor(int client) {
	return IsSurvivor(client) && IsPlayerAlive(client) && !IsFakeClient(client);
}

bool IsAliveSurvivor(int client) {
	return IsSurvivor(client) && IsPlayerAlive(client);
}

bool IsSurvivor(int client) {
	return IsClient(client) && GetClientTeam(client) == 2;
}

bool IsClient(int client) {
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}


// ==================================================
// ENTITY STOCKS
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
 * Returns whether player is incapacitated.
 *
 * Note: A tank player will return true when in dying animation.
 *
 * @param client		Player index.
 * @return				True if incapacitated, false otherwise.
 * @error				Invalid client index.
 */
stock bool L4D_IsPlayerIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1));
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
