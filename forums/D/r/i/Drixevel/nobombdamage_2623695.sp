#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "2.1"

public Plugin myinfo = 
{
	name = "No Bomb Damage",
	author = "Keith Warren (Shaders Allen)",
	description = "Stops all damage from bombs occuring to players.",
	version = PLUGIN_VERSION,
	url = "http://github.com/shadersallen"
}

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int client)
{	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (!IsValidEntity(inflictor))
		return Plugin_Continue;
	
	char class[32];
	GetEntityClassname(inflictor, class, sizeof(class));
	
	if (!StrEqual(class, "planted_c4", false))
		return Plugin_Continue;
	
	damage = 0.0;
	return Plugin_Changed;
}