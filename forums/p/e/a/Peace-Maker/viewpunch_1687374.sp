#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "No Teamattack Viewpunch",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Removes the screen shaking when a teammate shoots mate's head.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

new Handle:g_hFriendlyFire;

public OnPluginStart()
{
	g_hFriendlyFire = FindConVar("mp_friendlyfire");
	
	for(new i=1;i<=MaxClients;i++)
		if(IsClientInGame(i))
			OnClientPutInServer(i);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && !GetConVarBool(g_hFriendlyFire) && IsClientInGame(victim) && IsClientInGame(attacker) && GetClientTeam(victim) == GetClientTeam(attacker))
	{
		SetEntPropVector(victim, Prop_Send, "m_vecPunchAngle", Float:{0.0,0.0,0.0});
		SetEntPropVector(victim, Prop_Send, "m_vecPunchAngleVel", Float:{0.0,0.0,0.0});
	}
}