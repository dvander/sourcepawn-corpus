#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 

#pragma newdecls required

public Plugin myinfo =  
{ 
    name = "[CS:GO] Nadeblock Fix",  
    author = "zhell",  
    description = "Replicates the nadeblock from before CS broke it",  
    version = "1.1",  
    url = "http://köp.vip" 
}; 

public void OnPluginStart() 
{ 
    for (int i = 1; i <= MaxClients; i++) 
    { 
        if (IsClientInGame(i)) 
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage); 
    } 
} 

public void OnClientPutInServer(int client) 
{ 
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
} 

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)  
{ 
	if (victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients) 
		return Plugin_Continue; 
		
	char weapon[64]; 
	GetClientWeapon(attacker, weapon, sizeof(weapon)); 
	
	if (damage <= 1.0)
	{
		if (StrContains(weapon, "grenade") != -1 || StrContains(weapon, "decoy") != -1 || StrContains(weapon, "flash") != -1) 
		{
			//PrintToChatAll("%N was hit with %s by %N", victim, weapon, attacker);
			RemoveSpeed(victim);
		}
	}
	return Plugin_Continue; 
} 


public void RemoveSpeed(int client)
{
	/* OLD
	float fVelocity[3];
	
	fVelocity[0] = 0.0;
	fVelocity[1] = 0.0;
	fVelocity[2] = 0.0;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	*/
	
	
	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	float currentspeed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0));
	
	float maxspeed = 20.0;
	
	if (currentspeed > maxspeed)
	{
		float mult = currentspeed / maxspeed;
	
		if(mult != 0.0)
		{
			fVelocity[0] /= mult;
			fVelocity[1] /= mult;
			fVelocity[2] = 0.0;
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		}
	}
}