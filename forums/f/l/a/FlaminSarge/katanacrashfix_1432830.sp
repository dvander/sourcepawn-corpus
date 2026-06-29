#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>


#define PLUGIN_VERSION	"1.0"

public Plugin:myinfo = {
	name = "Katana Crash Killer",
	author = "FlaminSarge",
	description	= "You're no longer screwed.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart()
{
	CreateConVar("katanacrashfix_version", PLUGIN_VERSION, "Katana Crash Killer Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
//	RegConsoleCmd("sm_what", Cmd_what);
/*	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}*/
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Continue;
	if (!(buttons & IN_ATTACK)) return Plugin_Continue;
	decl Float:vPos[3];
	decl Float:vPos2[3];
	GetClientAbsOrigin(client, vPos);
	new wep1 = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	decl String:classname[32];
	if (!IsValidEntity(wep1) || !GetEdictClassname(wep1, classname, sizeof(classname))) return Plugin_Continue;
	if (strncmp(classname, "tf_weapon_katana", 16, false) != 0) return Plugin_Continue;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			new wep2 = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if (!IsValidEntity(wep2) && GetClientTeam(client) != GetClientTeam(i))
			{
				GetClientAbsOrigin(i, vPos2);
				new Float:what = GetVectorDistance(vPos, vPos2);
				if (what < 170)
				{
					ForcePlayerSuicide(i);
					PrintToChat(i, "[SM] You were killed by the proximity of %N's Half-Zatoichi! (They're like garlic to vampires, for civilians...)", client);
				}
			}
		}
	}
	return Plugin_Continue;
}
/*public Action:Cmd_what(client, args)
{
	decl String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	new target = FindTarget(client, arg1);
	new wep = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
	PrintToChat(client, "%d", wep);
	return Plugin_Handled;
}*/

	
//public OnClientPutInServer(client) SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

/*public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	decl String:classname[32];
	if (!IsValidClient(attacker)) return Plugin_Continue;
	if (attacker != inflictor) return Plugin_Continue;
	new vwep = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
	if (IsValidEntity(vwep)) return Plugin_Continue;
	new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if (IsValidEntity(weapon) && GetEdictClassname(weapon, classname, sizeof(classname)) && strncmp(classname, "tf_weapon_katana", 16, false) == 0)
	{
		PrintToChatAll("firing main cannon...");
		ForcePlayerSuicide(victim);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}*/
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
//	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
stock ValidWeaponEnt(client)
{
	for (new i = 0; i < 5; i++)
	{
		new weapon = GetPlayerWeaponSlot(client, i);
		if (IsValidEntity(weapon)) return weapon;
	}
	return -1;
}