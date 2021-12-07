

#include <sdkhooks>
#include <AG>


public void OnPluginStart()
{
	// edit
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) OnClientPutInServer(i);
	}
}

// edit
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(attacker < 1 || attacker > MaxClients) return Plugin_Continue;

	if(IsPlayerOnBuddha(attacker) && victim != attacker) return Plugin_Handled;

	return Plugin_Continue;
}

