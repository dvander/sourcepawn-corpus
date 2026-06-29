#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

#include <sourcemod>

new Handle:g_Cvar_GrapplingHook;

public Plugin myinfo = 
{
	name = "Grappling Hook Toggler",
	author = "MrTimcakes",
	description = "Toggles the Grappling Hook Cvar",
	version = PLUGIN_VERSION,
	url = "http://ducke.uk/"
};

public OnPluginStart() 
{ 
	RegAdminCmd("sm_grapplingHook", Command_GrapplingHookToggle, ADMFLAG_GENERIC, "Toggles the Grappling Hook ConVar");
	RegAdminCmd("sm_grapple", Command_GrapplingHookToggle, ADMFLAG_GENERIC, "Toggles the Grappling Hook ConVar");
	g_Cvar_GrapplingHook = FindConVar("tf_grapplinghook_enable");
}

public Action:Command_GrapplingHookToggle(client, args) {
	SetConVarBool(g_Cvar_GrapplingHook, !GetConVarBool(g_Cvar_GrapplingHook));
	ShowActivity2(client, "[GrapplingHook]", " Toggled: %s", GetConVarBool(g_Cvar_GrapplingHook) ? "On" : "Off");
	return Plugin_Handled;
}