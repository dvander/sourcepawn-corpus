#pragma semicolon 1

#include <sourcemod>
#include <SteamWorks>

#define PLUGIN_VERSION "0.2"

new Handle:descriptionCvar = INVALID_HANDLE;

public Plugin:myinfo = {
	name        = "[Any] SteamWorks Game Description Override",
	author      = "Dr. McKay, Sarabveer(VEER™)",
	description = "Overrides the default game description (i.e. \"Team Fortress\") in the server browser using SteamTools",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/showthread.php?p=1583349"
};

public OnPluginStart() {
	descriptionCvar = CreateConVar("sw_gamedesc_override", "", "What to override your game description to");
	CreateConVar("sw_gamedesc_override_version", PLUGIN_VERSION, "SteamTools Game Description Override Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	decl String:description[128];
	GetConVarString(descriptionCvar, description, sizeof(description));
	HookConVarChange(descriptionCvar, CvarChanged);
	SteamWorks_SetGameDescription(description);
}

public OnConfigsExecuted() {
	decl String:description[128];
	GetConVarString(descriptionCvar, description, sizeof(description));
	SteamWorks_SetGameDescription(description);
}

public CvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	decl String:description[128];
	GetConVarString(descriptionCvar, description, sizeof(description));
	SteamWorks_SetGameDescription(description);
}

public Callback_VersionConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	ResetConVar(convar);
}