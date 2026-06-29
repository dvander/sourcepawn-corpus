#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name = "[ANY] Cvar Locker",
	author = "Dr. McKay",
	description = "Locks cvars to their present values",
	version = PLUGIN_VERSION,
	url = "http://www.doctormckay.com"
};

new Handle:cvarsArray = INVALID_HANDLE;
new Handle:valuesArray = INVALID_HANDLE;

public OnPluginStart() {
	RegServerCmd("sm_lockcvar", Command_LockCvar, "Locks a cvar at a value");
	RegServerCmd("sm_lockcmd", Command_LockCommand, "Locks a command so it can't be used");
	cvarsArray = CreateArray(8);
	valuesArray = CreateArray(128);
}

public Action:Command_LockCvar(args) {
	if(args != 2) {
		PrintToServer("[SM] Usage: sm_lockcvar <cvar> <value>");
		return Plugin_Handled;
	}
	decl String:arg1[128], String:arg2[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	new Handle:cvar = FindConVar(arg1);
	if(cvar == INVALID_HANDLE) {
		PrintToServer("[SM] Invalid cvar: %s", arg1);
		return Plugin_Handled;
	}
	if(FindValueInArray(cvarsArray, cvar) != -1) {
		PrintToServer("[SM] Cvar %s is already locked.", arg1);
		return Plugin_Handled;
	}
	GetCmdArg(2, arg2, sizeof(arg2));
	SetConVarString(cvar, arg2);
	PushArrayCell(cvarsArray, _:cvar);
	PushArrayString(valuesArray, arg2);
	new flags = GetConVarFlags(cvar);
	flags |= FCVAR_CHEAT;
	SetConVarFlags(cvar, flags);
	HookConVarChange(cvar, Callback_CvarChanged);
	LogMessage("Cvar %s has been locked at value %s.", arg1, arg2);
	return Plugin_Handled;
}

public Callback_CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	new search = FindValueInArray(cvarsArray, _:convar);
	if(search == -1) {
		return;
	}
	decl String:forcedValue[128];
	GetArrayString(valuesArray, search, forcedValue, sizeof(forcedValue));
	if(!StrEqual(newValue, forcedValue)) {
		SetConVarString(convar, forcedValue);
	}
}

public Action:Command_LockCommand(args) {
	if(args != 1) {
		PrintToServer("[SM] Usage: sm_lockcmd <command>");
		return Plugin_Handled;
	}
	decl String:arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	RegServerCmd(arg1, Callback_LockedCommand);
	PrintToServer("[SM] Command %s has been locked.", arg1);
	return Plugin_Handled;
}

public Action:Callback_LockedCommand(args) {
	PrintToServer("[SM] This command is locked.");
	return Plugin_Handled;
}