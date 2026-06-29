#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_NAME		"[TF2] Projectile Gravity"
#define PLUGIN_AUTHOR		"Jouva"
#define PLUGIN_VERSION		"0.1.0"
#define PLUGIN_CONTACT		"jouva@moufette.com"
#define CVAR_FLAGS		FCVAR_PLUGIN|FCVAR_NOTIFY

new Handle:g_hCvarEnabled	= INVALID_HANDLE;
new Handle:g_hCvarPGravity	= INVALID_HANDLE;
new Handle:g_hCvarGravity	= INVALID_HANDLE;

new Float:g_fOldGravity;

public Plugin:myinfo = {
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description		= PLUGIN_NAME,
	version			= PLUGIN_VERSION,
	url			= PLUGIN_CONTACT
};

public OnPluginStart() {    
	decl String:strModName[32];
	GetGameFolderName(strModName, sizeof(strModName));
	if (!StrEqual(strModName, "tf"))
		SetFailState("This plugin is TF2 only.");

	CreateConVar("sm_projectile_gravity_version", PLUGIN_VERSION, PLUGIN_NAME, CVAR_FLAGS);
	g_hCvarEnabled	= CreateConVar("sm_projectile_gravity_enabled", "1", "Enables setting of projectile gravity on map changes", CVAR_FLAGS);
	g_hCvarPGravity	= CreateConVar("sm_projectile_gravity_value", "400", "Gravity of projectiles", CVAR_FLAGS);

	g_hCvarGravity	= FindConVar("sv_gravity");
}

public OnMapStart() {
	new iEnabled;
	
	iEnabled = GetConVarInt(g_hCvarEnabled);
	if(iEnabled == 1)
		SetConVarFloat(g_hCvarGravity, g_fOldGravity);
}

public OnMapEnd() {
	new Float:fPGravity;
	new iEnabled;

	iEnabled = GetConVarInt(g_hCvarEnabled);
	if(iEnabled == 1) {
		g_fOldGravity = GetConVarFloat(g_hCvarGravity);
		fPGravity = GetConVarFloat(g_hCvarPGravity);
		SetConVarFloat(g_hCvarGravity, fPGravity);
	}
}