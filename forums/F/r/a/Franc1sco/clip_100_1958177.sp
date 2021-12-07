#include <sourcemod>
#include <sdkhooks>

#define VERSION "b0.1"

new Handle:Timers[MAXPLAYERS + 1] = INVALID_HANDLE;

new offsAmmoActive = -1;
new offsAmmoClip = -1;

new municion[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "SM Clip ammo 100",
	author = "Franc1sco steam: franug",
	description = "clip ammo 100",
	version = VERSION,
	url = "http://www.clanuea.com"
};

public OnPluginStart()
{
	CreateConVar("sm_clipammo100", VERSION, "Version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_CHEAT);
	HookEvent("weapon_reload", Event_WeaponReload);
	
	offsAmmoActive = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");    
	offsAmmoClip = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
}

AmmoGetActiveAmount(client)
{
    new offsActiveWeapon = GetEntDataEnt2(client, offsAmmoActive);
    return GetEntData(offsActiveWeapon, offsAmmoClip, 4);
}

AmmoSetActiveAmount(client, amount)
{
    new offsActiveWeapon = GetEntDataEnt2(client, offsAmmoActive);
    SetEntData(offsActiveWeapon, offsAmmoClip, amount, 4, true);
}

public Action:Event_WeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:weapon_name[64];
	
	GetClientWeapon(client, weapon_name, 64);
	
	if(StrEqual(weapon_name, "m3") || StrEqual(weapon_name, "xm1014")) // dont support shotguns
		return;
		
	if (Timers[client] == INVALID_HANDLE)
    {
		municion[client] = AmmoGetActiveAmount(client);
		Timers[client] = CreateTimer(0.1, Check, client, TIMER_REPEAT);
    }
	else
	{
		KillTimer(Timers[client]);
		Timers[client] = INVALID_HANDLE;
		
		municion[client] = AmmoGetActiveAmount(client);
		Timers[client] = CreateTimer(0.1, Check, client, TIMER_REPEAT);
	}
}

public Action:Check(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		KillTimer(Timers[client]);
		Timers[client] = INVALID_HANDLE;
	}
	else if(municion[client] != AmmoGetActiveAmount(client)) // end of reload
	{
		AmmoSetActiveAmount(client, 100);
		KillTimer(Timers[client]);
		Timers[client] = INVALID_HANDLE;
	}
    

}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	SDKHook(client, SDKHook_WeaponCanSwitchTo, ClientSwitchWeapon);
}

public OnClientDisconnect(client)
{
	if (Timers[client] != INVALID_HANDLE)
    {
		KillTimer(Timers[client]);
		Timers[client] = INVALID_HANDLE;
	}
}

public Action:ClientSwitchWeapon(client, iEntity)
{
	if (Timers[client] != INVALID_HANDLE)
    {
		KillTimer(Timers[client]);
		Timers[client] = INVALID_HANDLE;
	}
}

public Action:OnWeaponDrop(client, weapon)
{
	if (Timers[client] != INVALID_HANDLE)
    {
		KillTimer(Timers[client]);
		Timers[client] = INVALID_HANDLE;
	}
}
