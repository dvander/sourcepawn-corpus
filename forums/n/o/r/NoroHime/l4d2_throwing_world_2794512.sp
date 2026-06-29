#define PLUGIN_VERSION		"1.0"
#define PLUGIN_PREFIX		"l4d2_"
#define PLUGIN_NAME			"throwing_world"
#define PLUGIN_NAME_FULL	"[L4D2] Be Throwing World"
#define PLUGIN_DESCRIPTION	"wanna fly...by throwing"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"steamcommunity.com/id/norohime"

/**
 *	v1.0 just released; 6-December-2022
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

native void L4D2_Charger_ThrowImpactedSurvivor(int victim, int attacker);
forward void L4D2_OnPounceOrLeapStumble_Post(int victim, int attacker);
forward void L4D2_OnJockeyRide_Post(int victim, int attacker);
forward void L4D2_OnStagger_Post(int target, int source);
forward void L4D_OnPouncedOnSurvivor_Post(int victim, int attacker);

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	MarkNativeAsOptional("L4D2_Charger_ThrowImpactedSurvivor");

	return APLRes_Success;
}

public void OnAllPluginsLoaded() {
	// Requires Left 4 DHooks Direct
	if( !LibraryExists("left4dhooks") ) {
		LogMessage	("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
		SetFailState("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
	}
}

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cStumble;		float flStumble;
ConVar cStagger;		float flStagger;
ConVar cJockey;			float flJockey;
ConVar cHunter;			float flHunter;

public void OnPluginStart() {

	CreateConVar					(PLUGIN_NAME, PLUGIN_VERSION,			"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cStumble =			CreateConVar(PLUGIN_NAME ... "_stumble", "0.16",	"be thrown chance of pounce and leap stumble", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cStagger =			CreateConVar(PLUGIN_NAME ... "_stagger", "0.2",		"be thrown chance of staggering", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cJockey =			CreateConVar(PLUGIN_NAME ... "_jockey", "0.33",		"be thrown chance of jockey ride, this will prevent control from rides", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cHunter =			CreateConVar(PLUGIN_NAME ... "_hunter", "0.84",		"extra chance for hunter pounce, throw far away make hunter looks powerful", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cStumble.AddChangeHook(OnConVarChanged);
	cStagger.AddChangeHook(OnConVarChanged);
	cJockey.AddChangeHook(OnConVarChanged);
	cHunter.AddChangeHook(OnConVarChanged);

	ApplyCvars();
}

void ApplyCvars() {

	flStumble = cStumble.FloatValue;
	flStagger = cStagger.FloatValue;
	flJockey = cJockey.FloatValue;
	flHunter = cHunter.FloatValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void L4D2_OnPounceOrLeapStumble_Post(int victim, int attacker) {

	if (flStumble > GetURandomFloat())

		L4D2_Charger_ThrowImpactedSurvivor(victim, attacker);

}

public void L4D2_OnJockeyRide_Post(int victim, int attacker) {

	if (flJockey > GetURandomFloat())

		L4D2_Charger_ThrowImpactedSurvivor(victim, attacker);
}

public void L4D2_OnStagger_Post(int target, int source) {

	if (flStagger > GetURandomFloat() && IsClient(target) && GetClientTeam(target) == 2)

		L4D2_Charger_ThrowImpactedSurvivor(target, IsClient(source) ? source : target);
}

public void L4D_OnPouncedOnSurvivor_Post(int victim, int attacker) {

	if (flHunter > GetURandomFloat())

		L4D2_Charger_ThrowImpactedSurvivor(victim, attacker);
}