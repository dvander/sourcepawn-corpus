#include <sourcemod>
#include <sdktools>
#include <smlib>

#pragma semicolon 1

new Handle:cvNapalm_DMG = INVALID_HANDLE;
new Handle:cvNapalm_TIME = INVALID_HANDLE;
new Float:gNapalm_DMG = 500.0;
new Float:gNapalm_TIME = 10.0;

public Plugin:myinfo = 
{
	name = "Nade-Fire",
	author = "Impact/Mitch.",
	description = "Napalm Grenade",
	version = "0.1",
	url = "http://gugyclan.eu"
}
public OnPluginStart()
{
	HookEvent("player_hurt", OnPlayerHurt);
	cvNapalm_DMG = CreateConVar("sm_napalm_dmg", "500.0", "damage delt from napalm.(0.0 to turn off damage, 50000.0 max.", FCVAR_NOTIFY, true, 0.0, true, 50000.0);
	cvNapalm_TIME = CreateConVar("sm_napalm_time", "10.0", "time burned from napalm. (0.0 to disable, max is 60.0)", FCVAR_NOTIFY, true, 0.0, true, 60.0);
	HookConVarChange(cvNapalm_DMG, cvChanged_DMG);
	HookConVarChange(cvNapalm_TIME, cvChanged_TIME);
}
public cvChanged_DMG(Handle:convar, const String:oldValue[], const String:newValue[])
{
	gNapalm_DMG = GetConVarFloat(cvNapalm_DMG);
}
public cvChanged_TIME(Handle:convar, const String:oldValue[], const String:newValue[])
{
	gNapalm_TIME = GetConVarFloat(cvNapalm_TIME);
}
public OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new String:Weapon[32];
	
	if(IsClientValid(Client) && IsClientValid(Attacker) && Client != Attacker)
	{
		GetEventString(event, "weapon", Weapon, sizeof(Weapon));

		if(StrContains(Weapon, "hegrenade"))
		{
			if(gNapalm_TIME > 0.0) IgniteEntity(Client, gNapalm_TIME);
			if(gNapalm_DMG > 0.0) Entity_Hurt(Client, RoundToZero(gNapalm_DMG), Attacker, DMG_BLAST);
		}
	}
}

stock bool:IsClientValid(id)
{
	if(id >0 && IsClientConnected(id) && IsClientInGame(id))
	{
		return true;
	}
	else
	{
		return false;
	}
}  