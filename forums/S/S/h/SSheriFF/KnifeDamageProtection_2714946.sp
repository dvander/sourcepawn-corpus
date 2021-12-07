#pragma semicolon 1
#pragma tabsize 0
#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "Knife Damage Protection",
	author = "SheriF",
	description = "",
	version = "1.0",
	url = ""
};

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageHook);
}
public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamageHook);
}
public Action OnTakeDamageHook(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if ((client>=1) && (client<=MaxClients) && (attacker>=1) && (attacker<=MaxClients) && (attacker==inflictor))
    {
    	int ClientTeamCount = GetTeamAliveCount(GetClientTeam(client));
		int AttackerTeamCount = GetTeamAliveCount(GetClientTeam(attacker));
		if((ClientTeamCount==1 && AttackerTeamCount>1) || (AttackerTeamCount==1 && ClientTeamCount>1))
		{
        	char WeaponName[64];
        	GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));
        	if (StrContains(WeaponName, "knife", false) != -1||StrContains(WeaponName, "bayonet", false) != -1)
        	{
            	damage = 0.0;
            	return Plugin_Handled;
        	}
        }
    }
    return Plugin_Continue;
}
public int GetTeamAliveCount(int team)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) 
    { 
        if(IsClientInGame(i)&&!IsFakeClient(i)&&IsPlayerAlive(i)&&GetClientTeam(i)==team)
        	count++;
    }
	return count;
}
