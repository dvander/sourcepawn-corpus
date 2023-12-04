#define PLUGIN_VERSION		"1.0.1"
#define PLUGIN_PREFIX		"l4d2_"
#define PLUGIN_NAME			"timed_hordes"
#define PLUGIN_NAME_FULL	"[L4D2] Timed Hordes"
#define PLUGIN_DESCRIPTION	"flexible hordes independent of director"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=342980"

/**
 *	Changes
 *	v1.0 (4-June-2023)
 *		- just released
 *	v1.0.1 (6-June-2023)
 *		- fix survivors count equal *_survivor_min plugin not working
 */


/**
 * @brief Called when hordes timer be trigger
 *
 * @param &timeHordesPast	hordes timer past
 * @param timeHordesCap		hordes time trigger line
 * @param &iHordeType		override *_type once time
 *
 * @return					Plugin_Continue / Plugin_Changed to accept trigger,
 * 							otherwise to deny trigger.
 */

// forward Action OnTimedHordesTrigger(float &timeHordesPast, float timeHordesCap, int &iHordeType);

/**
 * @brief Called when hordes timer be trigger
 *
 * @param &timeHordesPast	hordes timer past
 * @param timeHordesCap		hordes time trigger line
 *
 * @return					Plugin_Continue / Plugin_Changed to continue timing, otherwise to skip.
 */

// forward Action OnTimedHordesContinuing(float &timeHordesPast, float timeHordesCap);

// native void TH_SetHordesTime(float timeHordesPast);
// native int TH_GetHordesTime();
// native bool TH_TriggerHordes();

#pragma newdecls required 
#pragma semicolon 1

#include <sdkhooks>
#include <sdktools>

#define L4D2_ZOMBIECLASS_TANK         8
 
public Plugin myinfo = {
	name			= PLUGIN_NAME_FULL,
	author			= PLUGIN_AUTHOR,
	description		= PLUGIN_DESCRIPTION,
	version			= PLUGIN_VERSION,
	url				= PLUGIN_LINK
};

bool bLateLoad;
float timeHordesPast, timeHordesCap;
GlobalForward OnTimedHordesTrigger, OnTimedHordesContinuing;
int iSurvivorsLeft;
bool bIsSurvivorFighting;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	RegPluginLibrary(PLUGIN_NAME);

	CreateNative("TH_SetHordesTime", NativeSetTime);
	CreateNative("TH_GetHordesTime", NativeGetTime);
	CreateNative("TH_TriggerHordes", NativeTrigger);

	return APLRes_Success;
}

int NativeSetTime(Handle plugin, int numParams) {

	float time = GetNativeCell(1);

	timeHordesPast = time;

	return 0;
}

any NativeGetTime(Handle plugin, int numParams) {

	return timeHordesPast;
}

int NativeTrigger(Handle plugin, int numParams) {

	if (timeHordesPast < timeHordesCap)
		timeHordesPast = timeHordesCap;

	return TriggerTimedHordes(false);
}

enum {
	AVOID_DEAD =	(1 << 0),
	AVOID_BOT =		(1 << 1)
}

enum {
	HORDE_SPAWN = 1,
	HORDE_EVENT,
	HORDE_TANK,
}

enum {
	SKIP_TANK_ON_GROUND =	(1 << 0),
	SKIP_LAST_SURVIVOR =	(1 << 1)
}

ConVar cTimeMin;		float flTimeMin;
ConVar cTimeMax;		float flTimeMax;
ConVar cChecks;			int iChecks;
ConVar cHordeType;		int iHordeType;
ConVar cSurvivorMin;	int iSurvivorMin;
ConVar cSurvivorMax;	int iSurvivorMax;
ConVar cSkips;			int iSkips;


public void OnPluginStart() {

	CreateConVar(PLUGIN_NAME ... "_version", PLUGIN_VERSION, "Plugin Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cTimeMin =			CreateConVar(PLUGIN_NAME ... "_time_min", "30",		"min countdown duration to trigger hordes", FCVAR_NOTIFY);
	cTimeMax =			CreateConVar(PLUGIN_NAME ... "_time_max", "180",	"max countdown duration to trigger hordes", FCVAR_NOTIFY);
	cChecks =			CreateConVar(PLUGIN_NAME ... "_checks", "1",		"which survivors wont affect countdown duration, 1=ignore dead survivor, 2=ignore bot, 3=ignore both", FCVAR_NOTIFY);
	cSurvivorMin =		CreateConVar(PLUGIN_NAME ... "_survivor_min", "2",	"countdown start at this survivor count", FCVAR_NOTIFY);
	cSurvivorMax =		CreateConVar(PLUGIN_NAME ... "_survivor_max", "8",	"server max survivors, to scale correct countdown duration", FCVAR_NOTIFY);
	cHordeType =		CreateConVar(PLUGIN_NAME ... "_type", "1",			"action when countdown trigger 1=z_spawn mob 2=director_force_panic_event 3=spawn tank!!", FCVAR_NOTIFY);
	cSkips =			CreateConVar(PLUGIN_NAME ... "_skips", "-1",		"situations to skip hordes 1=tank on ground 2=last survivor", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d2_" ... PLUGIN_NAME);
	ApplyCvars();

	cTimeMin.AddChangeHook(OnConVarChanged);
	cTimeMax.AddChangeHook(OnConVarChanged);
	cChecks.AddChangeHook(OnConVarChanged);
	cSurvivorMin.AddChangeHook(OnConVarChanged);
	cSurvivorMax.AddChangeHook(OnConVarChanged);
	cHordeType.AddChangeHook(OnConVarChanged);
	cSkips.AddChangeHook(OnConVarChanged);

	HookEvent("map_transition", OnRoundEnd);
	HookEvent("finale_vehicle_leaving", OnRoundEnd);
	HookEvent("mission_lost", OnRoundEnd);
	HookEvent("round_end", OnRoundEnd);

	HookEvent("player_left_safe_area", OnLeftSafeArea);

	if (bLateLoad) {
		OnLeftSafeArea(null, "player_left_safe_area", false);
		bLateLoad = false;
	}

	OnTimedHordesTrigger = new GlobalForward("OnTimedHordesTrigger", ET_Event, Param_FloatByRef, Param_Float, Param_CellByRef);
	OnTimedHordesContinuing = new GlobalForward("OnTimedHordesContinuing", ET_Event, Param_FloatByRef, Param_Float);
}

void ApplyCvars() {

	flTimeMin = cTimeMin.FloatValue;
	flTimeMax = cTimeMax.FloatValue;
	iChecks = cChecks.IntValue;
	iSurvivorMin = cSurvivorMin.IntValue;
	iSurvivorMax = cSurvivorMax.IntValue;
	iHordeType = cHordeType.IntValue;
	iSkips = cSkips.IntValue;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnMapStart() {
	CreateTimer(1.0, TimedHordesContinuing, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

void OnSurvivorChange() {

	int survivors;

	for (int i = 1; i <= MaxClients; i++)
		if ( IsClientInGame(i) && GetClientTeam(i) == 2 && ( iChecks & AVOID_DEAD == 0 || IsPlayerAlive(i) ) && ( iChecks & AVOID_BOT == 0 || !IsFakeClient(i)) )
			survivors++;

	float step = (flTimeMax - flTimeMin) / (iSurvivorMax - iSurvivorMin);

	timeHordesCap = flTimeMax - step * (survivors - iSurvivorMin);

	iSurvivorsLeft = survivors;
}

void OnLeftSafeArea(Event event, const char[] name, bool dontBroadcast) {
	bIsSurvivorFighting = true;
	timeHordesPast = 0.0;
}

Action TimedHordesContinuing(Handle timer) {

	if (!bIsSurvivorFighting)
		return Plugin_Continue;

	OnSurvivorChange();

	if (iSurvivorsLeft < iSurvivorMin)
		return Plugin_Continue;

	Action actResult = Plugin_Continue;

	Call_StartForward(OnTimedHordesContinuing);
	Call_PushFloatRef(timeHordesPast);
	Call_PushFloat(timeHordesCap);
	Call_Finish(actResult);

	switch (actResult)  {

		case Plugin_Continue, Plugin_Changed : {}

		default : 
			return Plugin_Continue;
	}

	timeHordesPast++;

	if (timeHordesPast >= timeHordesCap)
		TriggerTimedHordes();

	return Plugin_Continue;
}

bool TriggerTimedHordes(bool makeforward = true) {

	if (iSkips & SKIP_TANK_ON_GROUND && IsTankOnGround())
		return false;

	if (iSkips & SKIP_LAST_SURVIVOR && iSurvivorsLeft <= 1)
		return false;

	int horde_type = iHordeType;

	if (makeforward) {

		Action actResult = Plugin_Continue;

		Call_StartForward(OnTimedHordesTrigger);
		Call_PushFloatRef(timeHordesPast);
		Call_PushFloat(timeHordesCap);
		Call_PushCellRef(horde_type);
		Call_Finish(actResult);

		switch (actResult)  {

			case Plugin_Continue, Plugin_Changed : {}

			default : 
				return false;
		}
	}

	if (timeHordesPast >= timeHordesCap && SummonHordes(horde_type)) {

		timeHordesPast = 0.0;
		return true;
	}

	return false;
}

void OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	timeHordesPast = 0.0;
	bIsSurvivorFighting = false;
}

bool SummonHordes(int horde_type) {

	int client = GetRandomSurvivor();

	if (client == 0)
		return false;

	switch (horde_type) {

		case HORDE_EVENT :
			CheatCommand(client, "director_force_panic_event");

		case HORDE_SPAWN :
			CheatCommand(client, "z_spawn", "mob");

		case HORDE_TANK :
			CheatCommand(client, "z_spawn", "tank");

		default :
			return false;
	}

	return true;
}

void CheatCommand(int client, const char[] command, const char[] arguments = "") {

	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);

	if (arguments[0])
		FakeClientCommand(client, "%s %s", command, arguments);
	else
		FakeClientCommand(client, command);

	SetCommandFlags(command, flags);
}

int GetRandomSurvivor() {

	static ArrayList clients;

	if (!clients)
		clients = new ArrayList();

	clients.Clear();

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			clients.Push(i);

	if (clients.Length > 0) {
		SetRandomSeed(GetGameTickCount());
		return clients.Get(GetRandomInt(0, clients.Length - 1));
	}

	return 0;
}


bool IsTankOnGround() {

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == L4D2_ZOMBIECLASS_TANK)
			return true;

	return false;
}