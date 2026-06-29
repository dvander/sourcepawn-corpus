#include <sourcemod>

/*
thx to Infinite Ammo by twistedeuphoria - http://forums.alliedmods.net/showthread.php?t=55381
*/

public Plugin:myinfo = {
	name = "Ammo Script for Zombie:Reloaded",
	author = "[SG-10]Cpt.Moore, Richard Helgeby, Kyle Sanderson",
	description = "",
	version = "2.0",
	url = "http://jupiter.swissquake.ch/zombie/page"
};

new activeOffset = -1;
new clip1Offset = -1;
new clip2Offset = -1;
new secAmmoTypeOffset = -1;
new priAmmoTypeOffset = -1;

//new Handle:hTimer;
new Handle:cvarInterval;
new Handle:AmmoTimer;

public OnPluginStart()
{
	cvarInterval = CreateConVar("zr_ammo_interval", "5", "How often to reset ammo (in seconds).", _, true, 1.0);
	AutoExecConfig(true, "plugin.zr_ammo");

	activeOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	
	clip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	clip2Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip2");
	
	priAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
	secAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iSecondaryAmmoCount");
}

public OnConfigsExecuted()
{
	if (AmmoTimer != INVALID_HANDLE) {
		KillTimer(AmmoTimer);
	}
	new Float:interval = GetConVarFloat(cvarInterval);
	AmmoTimer = CreateTimer(interval, ResetAmmo, _, TIMER_REPEAT);
}

public Action:ResetAmmo(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && IsPlayerAlive(client))
		{
			Client_ResetAmmo(client);
		}
	}
}

public Client_ResetAmmo(client)
{
	new zomg = GetEntDataEnt2(client, activeOffset);
	if (clip1Offset != -1 && zomg != -1)
		SetEntData(zomg, clip1Offset, 200, 4, true);
	if (clip2Offset != -1 && zomg != -1)
		SetEntData(zomg, clip2Offset, 200, 4, true);
	if (priAmmoTypeOffset != -1 && zomg != -1)
		SetEntData(zomg, priAmmoTypeOffset, 200, 4, true);
	if (secAmmoTypeOffset != -1 && zomg != -1)
		SetEntData(zomg, secAmmoTypeOffset, 200, 4, true);
}