#include <sourcemod>
#include <sdktools>

new hCurrent_Weapon;
new iClip;
new Handle:uammo = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Custom U-Ammo for Left 4 Dead",
	author = "4nt1h4cker",
	description = "Unlimited Ammo for Weapons, NOT pipe_bomb, first_aid_kit etc.",
	version = "1.1",
	url = ""
}

public OnPluginStart()
{
	hCurrent_Weapon = FindSendPropOffs ( "CTerrorPlayer", "m_hActiveWeapon");
	iClip = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	
	uammo = CreateConVar("sm_uammo_enabled", "1");
	
	HookEvent ("weapon_fire", Event_WeaponFire)
}

public Action:Event_WeaponFire (Handle:event, const String:name[], bool:dontBroadcast)
{
	//decl String:sWeapon[1024];
	//GetEventString (event, "weapon", sWeapon, sizeof(sWeapon));
	
	if (!GetConVarBool(uammo))
	{	
		return Plugin_Continue;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new iCount = GetEventInt(event, "count");	
	new iWeapon = GetEntDataEnt2 (client, hCurrent_Weapon);
	new iAmmo = GetEntData (iWeapon, iClip);
	SetEntData (iWeapon, iClip, (iAmmo+iCount));
	
	return Plugin_Continue;
}

