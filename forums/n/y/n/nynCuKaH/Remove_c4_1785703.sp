#pragma semicolon 1

#include <sdktools>

public Plugin:myinfo = {
	name		= "Remove c4",
	author		= "Pypsikan",
	version     = "1.0",
	url         = "http://sourcemod.net"
};

public OnPluginStart()
{	
	HookEvent("round_start", Remove_c4);
}

public Action:Remove_c4(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	new String:wpname[32];
	GetClientWeapon(client, wpname, sizeof(wpname));
	if (StrEqual(wpname, "weapon_c4", false))
    {
		new weapon = GetPlayerWeaponSlot(client, 5);
		if (IsValidEdict(weapon))
		{
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);
		}
	}
}