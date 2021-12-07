#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>


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
	cvarInterval = CreateConVar("zr_lastunlimited_interval", "5", "How often to reset ammo (in seconds).", _, true, 1.0);
	activeOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	
	clip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	clip2Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip2");
	
	priAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
    secAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iSecondaryAmmoCount");
    HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}


public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new humans = 0;
	new zombies = 0;
	
	new client = -1;

	for (new i = 1; i < GetMaxClients(); ++i)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
			continue;

		if (ZR_IsClientHuman(i))
		{
			humans++;
			client = i;
		}
		else if (ZR_IsClientZombie(i))
		{
			zombies++;
		}
	}

	if (zombies > 0 && humans == 1 && client != -1)
	{
	    AmmoTimer = INVALID_HANDLE;
	    new Float:interval = GetConVarFloat(cvarInterval);
	    AmmoTimer = CreateTimer(interval, Client_ResetAmmo, client, TIMER_REPEAT);
		PrintToChatAll("[ZR] Last human has received unlimited ammo");
	}
}

public Action:Client_ResetAmmo(Handle:timer, any:client)
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

public OnClientDisconnect()
{
    if (AmmoTimer != INVALID_HANDLE) 
    {
		KillTimer(AmmoTimer);
	} 
	AmmoTimer = INVALID_HANDLE;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (AmmoTimer != INVALID_HANDLE) 
    {
        KillTimer(AmmoTimer);
	}
	AmmoTimer = INVALID_HANDLE;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (AmmoTimer != INVALID_HANDLE) 
	{
		KillTimer(AmmoTimer);
	}
	AmmoTimer = INVALID_HANDLE;
}