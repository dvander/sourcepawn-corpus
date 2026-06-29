#include <tf2attributes>
#include <tf2_stocks>

public Plugin:myinfo = {
    name = "Soldier banner+",
    author = "Michal",
    description = "Makes soldier less useless on cp_degrootkeep have full banner charge and its extended 9x times",
    version = "1.0",
    url = ""
};

public OnPluginStart()
{
HookEvent("player_spawn", OnPlayerSpawn);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:iClass = TF2_GetPlayerClass( client );
	if( iClass == TFClass_Soldier )
	{
		CreateTimer(0.1, Timer_SetRage, client)
	}
}
public Action:Timer_SetRage(Handle:timer, any:client)
{	
	new weaponBanner = GetPlayerWeaponSlot(client, 1);
	TF2Attrib_SetByName(weaponBanner, "increase buff duration", 9.0);
	SetEntPropFloat( client, Prop_Send, "m_flRageMeter", 100.0 );
}
