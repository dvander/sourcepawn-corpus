
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

public Action:OnDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!attacker)
		return Plugin_Continue;

	if(inflictor > 0 && inflictor <= MaxClients)
	{

		new String:Weapon[32];
	
		new weapon = GetEntPropEnt(inflictor, Prop_Send, "m_hActiveWeapon");
		GetEdictClassname(weapon, Weapon, 32);
	
		if(StrContains(Weapon, "knife") == -1)
			return Plugin_Continue;


		if (GetClientTeam(victim) == GetClientTeam(attacker) && GetConVarBool(amigo)) return Plugin_Handled;
		else if (GetClientTeam(victim) != GetClientTeam(attacker) && GetConVarBool(enemigo)) return Plugin_Handled;
	}

	return Plugin_Continue;
}