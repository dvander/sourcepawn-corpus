
#include <sourcemod>

/*
thx to Infinite Ammo by twistedeuphoria - http://forums.alliedmods.net/showthread.php?t=55381
*/

public Plugin:myinfo = {
	name = "Ammo Script for Zombie:Reloaded",
	author = "[SG-10]Cpt.Moore",
	description = "",
	version = "1.0",
	url = "http://jupiter.swissquake.ch/zombie/page"
};

new activeOffset = -1;
new clip1Offset = -1;
new clip2Offset = -1;
new secAmmoTypeOffset = -1;
new priAmmoTypeOffset = -1;

// native hooks

public OnPluginStart()
{
	HookEvent("weapon_fire", Event_WeaponFire);
	activeOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	
	clip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	clip2Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip2");
	
	priAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
	secAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iSecondaryAmmoCount");
}

// event hooks

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(!IsFakeClient(client))
	{
		Client_ResetAmmo(client);
	}
}

// helpers

public Client_ResetAmmo(client)
{
	new zomg = GetEntDataEnt(client, activeOffset);
	if (clip1Offset != -1)
		SetEntData(zomg, clip1Offset, 104, 4, true);
	if (clip2Offset != -1)
		SetEntData(zomg, clip2Offset, 104, 4, true);
	if (priAmmoTypeOffset != -1)
		SetEntData(zomg, priAmmoTypeOffset, 200, 4, true);
	if (secAmmoTypeOffset != -1)
		SetEntData(zomg, secAmmoTypeOffset, 200, 4, true);
}

