#include <sourcemod>

new hCurrent_Weapon;
new iClip;
new Handle:sm_uammo_enabled = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Custom U-Ammo for Left 4 Dead",
	author = "4nt1h4cker",
	description = "Unlimited Ammo for Weapons, NOT pipe_bomb, first_aid_kit etc.",
	version = "1.1",
	url = ""
};

public OnPluginStart()
{
	hCurrent_Weapon = FindSendPropOffs( "CTerrorPlayer", "m_hActiveWeapon");
	iClip = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");

	// Config
	sm_uammo_enabled = CreateConVar("sm_uammo_enabled", "1", "Unlimited Ammo Enable");
	AutoExecConfig(true, "plugin_uammo");

	HookEvent ("weapon_fire", Event_WeaponFire)
}

public Action:Event_WeaponFire (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(sm_uammo_enabled))
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new iWeapon = GetEntDataEnt2(client, hCurrent_Weapon);
	new iAmmo = GetEntData(iWeapon, iClip);
	new fired = GetEventInt(event, "count");

	if( (iAmmo > -1) && (fired > 0) ) // This is the fix
	{
		SetEntData(iWeapon, iClip, iAmmo+1, 4, true);
	}

	return Plugin_Continue;
}
