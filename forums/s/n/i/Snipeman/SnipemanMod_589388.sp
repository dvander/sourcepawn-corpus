#include <sourcemod.inc>
 
public Plugin:myinfo =
{
    name = "SnipemanMod",
    author = "Snipeman (robert.oates@gmail.com)",
    description = "Various TF2 gameplay tweaks.",
    version = "1.0.0.0",
    url = "http://www.sourcemod.net/"
};
 
new Handle:g_Cvar_hide_kills_knife	= INVALID_HANDLE
new Handle:g_Cvar_hide_kills_sapper	= INVALID_HANDLE

public OnPluginStart()
{
	HookEvent("player_death",		SnipemanMod_PlayerDeath,		EventHookMode_Pre)
	HookEvent("object_destroyed",	SnipemanMod_ObjectDestroyed,	EventHookMode_Pre)

	g_Cvar_hide_kills_knife		= CreateConVar( "sm_hide_kills_knife",  "1", "If 1, backstab kills will not show on the HUD." )
	g_Cvar_hide_kills_sapper	= CreateConVar( "sm_hide_kills_sapper", "1", "If 1, sapper kills (on buildings) will not show on the HUD." )

	AutoExecConfig( true, "plugin_snipeman")
}

public Action:SnipemanMod_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( !GetConVarBool(g_Cvar_hide_kills_knife) )
	{
		return Plugin_Continue
	}
	
	new String:weaponName[32]
	GetEventString(event, "weapon", weaponName, sizeof(weaponName))
	
	if ( strcmp(weaponName, "knife") == 0 )
	{
		return Plugin_Handled
	} 
	
	return Plugin_Continue
}

public Action:SnipemanMod_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( !GetConVarBool(g_Cvar_hide_kills_sapper) )
	{
		return Plugin_Continue
	}
	
	new String:weaponName[32]
	GetEventString(event, "weapon", weaponName, sizeof(weaponName))

	if ( strcmp(weaponName, "obj_attachment_sapper") == 0 )
	{
		return Plugin_Handled
	} 
	
	return Plugin_Continue
}