#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma tabsize 0
//////////////////////////////////////////////////////////////////////////////////
int En_Son_Oldurulen[MAXPLAYERS+1];
float Konum[MAXPLAYERS+1][3];
//////////////////////////////////////////////////////////////////////////////////
public OnPluginStart()
{
	//******************************************//
    HookEvent("player_death", Oyuncu_Oldugunde); 
	//******************************************//    
}
//////////////////////////////////////////////////////////////////////////////////
public Oyuncu_Oldugunde(Handle:event, const String:name[], bool:dontBroadcast)
{
	//******************************************//	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//******************************************//		
	if(En_Son_Oldurulen[client] && IsClientInGame(En_Son_Oldurulen[client]) && !IsFakeClient(En_Son_Oldurulen[client]))
	{
		//******************************************//		
		CS_RespawnPlayer(En_Son_Oldurulen[client]);
		TeleportEntity(En_Son_Oldurulen[client], Konum[En_Son_Oldurulen[client]], NULL_VECTOR, NULL_VECTOR);
		//******************************************//						
	}
	//******************************************//			
	En_Son_Oldurulen[GetClientOfUserId(GetEventInt(event, "attacker"))] = client;	
	//******************************************//						
	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		//******************************************//							
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Konum[client]);	
		En_Son_Oldurulen[client] = -1;	
		//******************************************//					
	}
	//******************************************//
}
//////////////////////////////////////////////////////////////////////////////////