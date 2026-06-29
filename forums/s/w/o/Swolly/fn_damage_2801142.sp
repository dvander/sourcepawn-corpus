#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma tabsize 0
///////////////////////////////////////////////////////////////////////////////////////
public Plugin myinfo = {
	name = "Fortnite Damage System",
	author = "Swolly",
	description = "Fortnite Damage System",
	url = "www.plugincim.com"
};
///////////////////////////////////////////////////////////////////////////////////////
public Action Hasar_Aldiginda(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	//*********************************//				
	if(IsValidClient(client))
	{
		//*********************************//	
	    int Zirh_Miktari = GetEntProp(client, Prop_Send, "m_ArmorValue"); 
		//*********************************//
		if(Zirh_Miktari >= damage)
		{
			//*********************************//		            						
        	SetClientArmor(client, Zirh_Miktari - RoundFloat(damage)); 
			//*********************************//		            	
			damage = 0.0;
			return Plugin_Changed;  
			//*********************************//		            						
		}
		else
		{
			//*********************************//	
        	SetClientArmor(client, 0);
			//*********************************//		
			damage -= Zirh_Miktari;
			return Plugin_Changed;  
			//*********************************//		            	
		}				
		//*********************************//	
	}		
	//*********************************//			
	return Plugin_Continue;
	//*********************************//
}
//////////////////////////////////////////////////////////////////////////////////
public OnClientPostAdminCheck(client)
{
	//*********************************//
	if(IsValidClient(client)) 
		SDKHook(client, SDKHook_OnTakeDamage, Hasar_Aldiginda);	
	//*********************************//
}
//////////////////////////////////////////////////////////////////////////////////
stock SetClientArmor(client, iZirh_Miktari)
{
	//*************************************//
	SetEntProp(client, Prop_Send, "m_ArmorValue", iZirh_Miktari, 1);
	//*************************************// 
}
//////////////////////////////////////////////////////////////////////////////////
stock bool IsValidClient(client, bool nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
        return false; 

    return IsClientInGame(client); 
} 
//////////////////////////////////////////////////////////////////////////////////