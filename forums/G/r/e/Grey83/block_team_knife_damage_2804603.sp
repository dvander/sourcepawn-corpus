#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>

public void OnPluginStart()
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) SDKHook(i, SDKHook_OnTakeDamage, TakeDamageHook);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, TakeDamageHook);
}

public Action TakeDamageHook(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(0 < attacker && attacker <= MaxClients && victim != attacker && attacker == inflictor && IsClientInGame(attacker)
	&& GetClientTeam(attacker) != 3)
	{
		static char wpn[16];
		GetClientWeapon(attacker, wpn, sizeof(wpn));
		if(!strcmp(wpn[7], "knife", false))
		{
			damage = 0.0;
			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}