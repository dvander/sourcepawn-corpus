#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

new Handle:hConVar_NoShoveEnabled = INVALID_HANDLE;
new Handle:hConVar_NoShoveWeapons = INVALID_HANDLE;

new bool:bEnabled = true;
new String:sAllowedWeapons[64][32];
new iAllowedWeaponsCount = 64;
new iPerf_AllowedWeapon[MAXPLAYERS+1] = 0; //For very good Performance in a loop! [0 = Nothing | 1 = True | 2 = False]
new iPerf_ActiveWeapon[MAXPLAYERS+1] = -1; // For "iPerf_AllowedWeapon"
static int    g_iShoveMinPenalty;

public Plugin:myinfo = 
{
	name = "No shove Pistols",
	author = "ddd123, original code:Timocop and Marttt",
	description = "No shove Pistol (or any weapons)",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=337368"
}

public OnPluginStart()
{

	hConVar_NoShoveEnabled = CreateConVar("l4d_noshovepistols_enabled", "1", "1 - enable / 0 - disable", FCVAR_REPLICATED | FCVAR_NOTIFY );
	hConVar_NoShoveWeapons = CreateConVar("l4d_noshovepistols_weapons", "weapon_pistol;weapon_magnum;weapon_pistol_magnum;magnum", "allow weapons, Use ';' to add more",  FCVAR_REPLICATED | FCVAR_NOTIFY);
	HookConVarChange(hConVar_NoShoveEnabled, ConVarChanged);
	HookConVarChange(hConVar_NoShoveWeapons, ConVarChanged);
	
	AutoExecConfig(true, "l4d_noshove_pistols");
	
	WeaponStringCalculation();
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == hConVar_NoShoveEnabled)
	{
		bEnabled = GetConVarBool(hConVar_NoShoveEnabled);
	}
	else if(convar == hConVar_NoShoveWeapons)
	{
		WeaponStringCalculation();
	}
}

WeaponStringCalculation()
{
	decl String:sConVarAllowedWeapons[256];
	GetConVarString(hConVar_NoShoveWeapons, sConVarAllowedWeapons, sizeof(sConVarAllowedWeapons));
	
	new iWeaponNumbers = ReplaceString(sConVarAllowedWeapons, sizeof(sConVarAllowedWeapons), ";", ";", false);
	iAllowedWeaponsCount = iWeaponNumbers;

	ExplodeString(sConVarAllowedWeapons, ";", sAllowedWeapons, iWeaponNumbers + 1, 32);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{ 
	if(!bEnabled)
	return Plugin_Continue;

	if (buttons & IN_ATTACK2)
	{
		if(!IsClientInGame(client)
			|| !IsPlayerAlive(client)
			|| GetClientTeam(client) != 2)
		return Plugin_Continue;

		new iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new bWeaponChanged = ((iActiveWeapon != iPerf_ActiveWeapon[client]) || (iPerf_ActiveWeapon[client] == -1));
		iPerf_ActiveWeapon[client] = iActiveWeapon;
		
		if(bWeaponChanged)
		{
			iPerf_AllowedWeapon[client] = 0;
		}
		
		if(!IsAllowedWeapon(client))
		return Plugin_Continue;

		int shovePenalty = GetEntProp(client, Prop_Send, "m_iShovePenalty");
		if (shovePenalty > g_iShoveMinPenalty)
		{
			SetEntProp(client, Prop_Send, "m_iShovePenalty", g_iShoveMinPenalty);
		}
	}
	/* else
	{
		if(iPerf_AllowedWeapon[client])
		iPerf_AllowedWeapon[client] = 0;
	} */
	return Plugin_Continue;
}

stock bool:IsAllowedWeapon(client)
{
	if(iPerf_AllowedWeapon[client] == 1)
	return true;
	else if(iPerf_AllowedWeapon[client] == 2)
	return false;
	
	decl String:sCurrentWeaponName[32];
	GetClientWeapon(client, sCurrentWeaponName, sizeof(sCurrentWeaponName));
	
	for(new i = 0; i <= iAllowedWeaponsCount; i++)
	{
		if(StrEqual(sAllowedWeapons[i], sCurrentWeaponName, false))
		{
			iPerf_AllowedWeapon[client] = 1;
			return true;
		}
		
	}
	
	iPerf_AllowedWeapon[client] = 2;
	return false;
}
