#define PLUGIN_VERSION		"1.0"
#define PLUGIN_NAME			"crouch_ff"
#define PLUGIN_NAME_FULL	"[Any] Cancel Friendly-Fire on Crouch"
#define PLUGIN_DESCRIPTION	"when someone crouched it wont doing ff or gets ff"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"steamcommunity.com/id/norohime"

/*
 *	v1.0 just released; 25-November-2022
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cExtraKey;	int iExtraKey;

bool bLateLoad = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	return APLRes_Success; 
}

public void OnPluginStart() {

	CreateConVar				(PLUGIN_NAME, PLUGIN_VERSION,		"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cExtraKey =		CreateConVar(PLUGIN_NAME ... "_key", "131072",	"extra key(s) to cancel ff when hold, 131072=Shift see more on entity_prop_stocks.inc", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_NAME);

	cExtraKey.AddChangeHook(OnConVarChanged);

	if (bLateLoad)
		for (int client = 1; client <= MaxClients; client++)
			if (IsClientInGame(client))
				OnClientPutInServer(client);

	ApplyCvars();
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void ApplyCvars() {
	iExtraKey = cExtraKey.IntValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {

	if (victim == attacker || victim == inflictor)
		return Plugin_Continue;

	if (IsClient(victim) && IsClient(attacker) && GetClientTeam(victim) == GetClientTeam(attacker)) {

		int buttons_victim = GetClientButtons(victim),
			buttons_attacker = GetClientButtons(attacker);

		if (buttons_victim & (IN_DUCK|iExtraKey) || buttons_attacker & (IN_DUCK|iExtraKey))
			return Plugin_Stop;

		int status_victim = GetEntityFlags(victim),
			status_attacker = GetEntityFlags(attacker);

		if (status_victim & FL_DUCKING || status_attacker & FL_DUCKING)
			return Plugin_Stop;
	}
	
	return Plugin_Continue;
}