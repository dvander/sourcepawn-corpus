#pragma semicolon 1

#include <sourcemod>
#include <tf2>

public Plugin:myinfo = {
	name		= "[TF2] Humans 100% Crits",
	author		= "Dr. McKay",
	description	= "Gives humans 100% crits",
	version		= "1.0.0",
	url			= "http://www.doctormckay.com"
};

public OnPluginStart() {
	new Handle:buffer = FindConVar("tf_server_identity_disable_quickplay");
	SetConVarBool(buffer, true);
	HookConVarChange(buffer, OnConVarChanged);
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	SetConVarBool(convar, true);
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) {
	result = !IsFakeClient(client);
	return Plugin_Changed;
}