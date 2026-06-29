#include <sourcemod>  
#include <sdkhooks>
#include <tf2>  
#include <tf2_stocks>  

new Handle:g_crits_time;
new Handle:g_punishment;
new Handle:g_time_protected;

new protected[MAXPLAYERS + 1];

public Plugin:myinfo =  
{  
	name = "Crits spawn protection",  
	author = "Arkarr",  
	description = "Active crits for sec after respawn.",  
	version = "1.0",  
	url = "http://www.sourcemod.net/"  
}; 


public OnPluginStart()  
{	
	HookEvent("player_spawn", Event_PlayerSpawn)
	
	g_crits_time = CreateConVar("sm_crits_after_respawn", "3.0", "How much seconds should stay the crits after respawn ?");
	g_punishment = CreateConVar("sm_punishment_type", "0", "Wich type of punishement should it be ? 0 = disable 1 = slay 2 = return dammage");
	g_time_protected = CreateConVar("sm_protected_after_spawn", "3.0", "How much seconds should be the player protected after respawn ?");
	
	AutoExecConfig(true, "plugin.crits_respawn");
	
	for(new i = 1; i <= MaxClients; i++) {
       if(IsClientInGame(i)) {
           SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
       }
    }
}

//Thanks to bl4nk for is help : https://forums.alliedmods.net/showpost.php?p=1975240&postcount=10
public OnClientPutInServer(client)
{    
	protected[client] = 0;
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
	{
		TF2_AddCondition(client, TFCond_Kritzkrieged, GetConVarFloat(g_crits_time));
		
		protected[client] = 1;
	
		CreateTimer(GetConVarFloat(g_time_protected), LoadStuff, client);
	}
	
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) 
{
	if(IsValidClient(victim) && IsValidClient(attacker))
		{
			if(protected[victim] >= 1){
				
				if(GetConVarInt(g_punishment) == 1){
			
					if(attacker != victim){
					ForcePlayerSuicide(attacker);
					PrintHintText(attacker, "[COS] %s", "You are doing spawnkilling ! Server auto killed you !");
					}
				
				}
				
				else if(GetConVarInt(g_punishment) == 2){
			
					if(attacker != victim){
					PrintHintText(attacker, "[COS] %s", "You are doing spawnkilling ! Take your dammage back !");
					
					SetEntProp(attacker, Prop_Send, "m_iHealth", GetClientHealth(attacker) - RoundToNearest(damage));
					
					if( (GetClientHealth(attacker) <= 0) )
					{
						SlapPlayer(attacker, 1, false);
					}
					
					}
					
				}
				
				else if(GetConVarInt(g_punishment) != 1 && (GetConVarInt(g_punishment) != 2) && (GetConVarInt(g_punishment) != 0) ){
					PrintToServer("Value %i is not a valid value ! Value accepted : 0 = disabled 1 = slay 2 = return dammage", GetConVarInt(g_punishment));
				}
				// Block damage 
				return Plugin_Handled;
			}
		}
		// Allow damage 
		return Plugin_Continue; 
}



public Action:LoadStuff(Handle:timer, any:user)  
{  
	protected[user] = 0;
}

//Stocks here <------------------------------------------------------------------------------

stock bool:IsValidClient(iClient, bool:bReplay = true) {
    if(iClient <= 0 || iClient > MaxClients)
        return false;
    if(!IsClientInGame(iClient))
        return false;
    if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
        return false;
    return true;
}