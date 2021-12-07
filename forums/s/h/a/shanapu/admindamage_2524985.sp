#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo = {
	name = "Admin less damage", 
	author = "shanapu", 
	description = "Root admins ignore some damage", 
	version = "1.0", 
	url = "https://github.com/shanapu/"
};

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakedamage);
}

public Action OnTakedamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsValidClient(victim, true, false) || attacker == victim || !IsValidClient(attacker, true, false))
		return Plugin_Continue;

	if (GetUserFlagBits(victim) & ADMFLAG_ROOT)
	{		
		int random = GetRandomInt(1,5);
		
		if(random <= 3)
			return Plugin_Handled;
		else
		{
			damage = damage/2;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}