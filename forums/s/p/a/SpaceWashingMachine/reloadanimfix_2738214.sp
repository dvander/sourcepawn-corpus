#include <sourcemod>

public Plugin:myinfo = 
{
	name = "[L4D2] Reload Animation Fix",
	author = "SpaceWashingMachine",
	description = "Fixes reload animations sometimes playing again after reload ends.",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	 HookEvent("weapon_reload", ReloadAnimFix); 
}

public ReloadAnimFix(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	CreateTimer(0.1, timerFixReloadAnim, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action:timerFixReloadAnim(Handle:timer, any:ref)
{
	new weapon = EntRefToEntIndex(ref);
	if(weapon == INVALID_ENT_REFERENCE || weapon <= MaxClients || !IsValidEntity(weapon))
		return Plugin_Stop;

	if(GetEntProp(weapon, Prop_Send, "m_bInReload") == 0)
	{
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", GetGameTime() + 2.0);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}