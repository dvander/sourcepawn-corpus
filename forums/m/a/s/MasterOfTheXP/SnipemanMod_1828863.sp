#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
 
public Plugin:myinfo =
{
    name = "SnipemanMod",
    author = "Snipeman (robert.oates@gmail.com)",
    description = "Various TF2 gameplay tweaks.",
    version = "1.0.0.0",
    url = "http://www.sourcemod.net/"
};
 
new Handle:cvarHideKnife;
new Handle:cvarHideSapper;
new Handle:cvarHideAmby;
new Handle:cvarHideHeadshot;

public OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	HookEvent("object_destroyed", Event_Destruction, EventHookMode_Pre);

	cvarHideKnife	= CreateConVar("sm_hide_kills_knife", "1", "If 1, backstab kills will not show on the HUD.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarHideSapper = CreateConVar("sm_hide_kills_sapper", "1", "If 1, sapper kills (on buildings) will not show on the HUD.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarHideAmby = CreateConVar("sm_hide_kills_ambassador", "1", "If 1, Ambassador kills (on buildings) will not show on the HUD.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarHideHeadshot = CreateConVar("sm_hide_kills_headshot", "1", "If 1, headshot kills will not show on the HUD.", FCVAR_NONE, true, 0.0, true, 1.0);

	AutoExecConfig(true, "plugin_snipeman");
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker <= 0 || attacker > MaxClients) return Plugin_Continue;
	if (!IsClientInGame(attacker)) return Plugin_Continue;
	new TFClassType:class = TF2_GetPlayerClass(attacker);
	new active = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
	if (GetConVarBool(cvarHideKnife) && class == TFClass_Spy && active == GetPlayerWeaponSlot(attacker, 2))
		SetEventBroadcast(event, true);
	else if (GetConVarBool(cvarHideAmby) && class == TFClass_Spy && active == GetPlayerWeaponSlot(attacker, 0) && GetEntProp(active, Prop_Send, "m_iItemDefinitionIndex") == 61)
		SetEventBroadcast(event, true);
	else if (GetConVarBool(cvarHideHeadshot) && class == TFClass_Sniper && active == GetPlayerWeaponSlot(attacker, 0) && GetEventBool(event, "crit"))
		SetEventBroadcast(event, true);
	
	return Plugin_Continue;
}

public Action:Event_Destruction(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarHideSapper)) return Plugin_Continue;
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker <= 0 || attacker > MaxClients) return Plugin_Continue;
	if (!IsClientInGame(attacker)) return Plugin_Continue;
	new TFClassType:class = TF2_GetPlayerClass(attacker);
	new active = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
	if (GetConVarBool(cvarHideKnife) && class == TFClass_Spy && active == GetPlayerWeaponSlot(attacker, 2))
		SetEventBroadcast(event, true);
	else if (GetConVarBool(cvarHideAmby) && class == TFClass_Spy && active == GetPlayerWeaponSlot(attacker, 0) && GetEntProp(active, Prop_Send, "m_iItemDefinitionIndex") == 61)
		SetEventBroadcast(event, true);
	
	new String:weaponName[32];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));

	if (StrEqual(weaponName, "obj_attachment_sapper") || StrEqual(weaponName, "recorder"))
		SetEventBroadcast(event, true);
	
	return Plugin_Continue;
}