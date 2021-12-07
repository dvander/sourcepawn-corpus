
#include <sourcemod>
#include <sdkhooks>

new Handle:amigo;
new Handle:enemigo;

public OnPluginStart()
{
	amigo = CreateConVar("block_knife_teamattack", "1", "Enables or disable");
	enemigo = CreateConVar("block_knife_enemy", "1", "Enable or disable");
}

public OnClientPutInServer(client)
{
   SDKHook(client, SDKHook_OnTakeDamage, OnDamage);

}

//public Action:OnDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
public Action:OnDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) 
{
	//if (!attacker)
	if(attacker < 1 || attacker > MaxClients || victim < 1 || victim > MaxClients)
		return Plugin_Continue;

	if (!IsValidEdict(weapon))
		return Plugin_Continue;

	//new String:Weapon[32];
	decl String:Weapon[32];
	
	//new weapon = GetEntPropEnt(inflictor, Prop_Send, "m_hActiveWeapon");
	GetEdictClassname(weapon, Weapon, 32);
	
	if(StrContains(Weapon, "knife") == -1)
		return Plugin_Continue;


	if (GetClientTeam(victim) == GetClientTeam(attacker) && GetConVarBool(amigo)) return Plugin_Handled;
	else if (GetClientTeam(victim) != GetClientTeam(attacker) && GetConVarBool(enemigo)) return Plugin_Handled;

	return Plugin_Continue;
}