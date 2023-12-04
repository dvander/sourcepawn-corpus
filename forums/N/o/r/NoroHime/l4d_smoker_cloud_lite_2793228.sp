#define PLUGIN_VERSION		"1.0"
#define PLUGIN_NAME			"smoker_cloud"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] Smoker Cloud Damage Lite"
#define PLUGIN_DESCRIPTION	"[L4D & L4D2] Smoker Cloud Damage Lite"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"steamcommunity.com/id/norohime"

/*
 *	v1.0 just released; 19-November-2022
 */

#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cDamage;		float flDamage;

public void OnPluginStart() {

	CreateConVar				(PLUGIN_NAME, PLUGIN_VERSION,			"Version of " ... PLUGIN_NAME_FULL, FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cDamage =		CreateConVar(PLUGIN_NAME ... "_damage", "1.0",		"damage per cough", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d_" ... PLUGIN_NAME);

	cDamage.AddChangeHook(OnConVarChanged);

	ApplyCvars();
}

void ApplyCvars() {
	flDamage = cDamage.FloatValue;
}



void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

forward void L4D_OnPlayerCough_Post(int client, int attacker);

public void L4D_OnPlayerCough_Post(int client, int attacker) {
	SDKHooks_TakeDamage(client, client, client, flDamage);
}