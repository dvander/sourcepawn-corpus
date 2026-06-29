#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Scopeless Scout",
	author = "SAMURAI",
	description = "o yea",
	version = "1.0",
	url = "wtf"
}

public OnPluginStart()
{
	HookEvent("weapon_zoom",Event_WeaponZoom,EventHookMode_Pre);
}

public Action:Event_WeaponZoom(Handle:event, const String:weaponName[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(!IsClientConnected(client) && !IsClientInGame(client) && !IsPlayerAlive(client))
		return Plugin_Continue;
		
	static String:szWeapon[64];
	GetClientWeapon(client,szWeapon,sizeof(szWeapon));
	
	if(StrEqual(szWeapon,"weapon_scout"))
		return Plugin_Handled;
	
	return Plugin_Continue;
}
	