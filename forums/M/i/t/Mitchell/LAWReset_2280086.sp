#pragma semicolon 1
#include <sdktools>
#define PVERSION "1.0.1"

new Handle:gH_Enabled = INVALID_HANDLE;
new bool:bEnabled = true;

public Plugin:myinfo = {
	name = "Auto +LookAtWeapon Reset",
	author = "Mitch",
	description = "For those baddies with nice knives.",
	version = PVERSION,
	url = "snbx.info"
};

public OnPluginStart() {
	gH_Enabled 	= CreateConVar("sm_lawreset_enabled", "1", "0 = Disables LAW Reset; 1 = Enables LAW Reset", FCVAR_PLUGIN, true, 0.0, true, 1.0); //Why would you disable this masterpiece in first place?!
	HookConVarChange(gH_Enabled, ConVarChanged);
	AutoExecConfig();

	CreateConVar("sm_lawreset_version", PVERSION, "Auto +LookAtWeapon Reset Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);

	AddCommandListener(Command_LAW_Plus, "-lookatweapon");
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	bEnabled = bool:StringToInt(newVal);
}

public Action:Command_LAW_Plus(client, const String:command[], argc) {
	if(!bEnabled || !client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	SetEntProp(client, Prop_Send, "m_bIsLookingAtWeapon", 0);
	SetEntProp(client, Prop_Send, "m_bIsHoldingLookAtWeapon", 0);
	return Plugin_Continue;
}