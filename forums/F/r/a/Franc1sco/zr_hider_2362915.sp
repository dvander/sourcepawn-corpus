#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 
#include <zombiereloaded>

#define PLUGIN_VERSION "1.0" 

new bool:g_bHide[MAXPLAYERS+1][MAXPLAYERS+1]; 
new bool:g_hide[MAXPLAYERS+1]; 

public Plugin:myinfo =  
{ 
    name = "SM Hide Teammates For Proximity", 
    author = "Franc1sco franug", 
    description = "", 
    version = PLUGIN_VERSION, 
    url = "www.steamcommunity.com/id/franug/" 
} 

public OnPluginStart() 
{ 
	CreateTimer(0.5, Pasar, _, TIMER_REPEAT);
	
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	
	RegConsoleCmd("sm_hide", Comando);
}

public Action:Comando(client, args)
{
	g_hide[client] = !g_hide[client];
	PrintToChat(client, "Hide feature %s" ,g_hide[client]?"Activated":"Desactivated");

	return Plugin_Handled;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	for(new i = 1; i <= MaxClients; i++)
		g_bHide[client][i] = false; 
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	for(new i = 1; i <= MaxClients; i++)
		g_bHide[client][i] = false; 
}

public Action:Pasar(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i))
			CheckClientOrg(i);

}

CheckClientOrg(Client) 
{
	decl Float:MedicOrigin[3],Float:TargetOrigin[3], Float:Distance;
	GetClientAbsOrigin(Client, MedicOrigin);
	for (new X = 1; X <= MaxClients; X++)
	{
		if(X != Client && IsClientInGame(X) && IsPlayerAlive(X) && ZR_IsClientHuman(X))
		{
			GetClientAbsOrigin(X, TargetOrigin);
			Distance = GetVectorDistance(TargetOrigin,MedicOrigin);
			if(Distance <= 100.0)
				g_bHide[Client][X] = true;
			else
				g_bHide[Client][X] = false;
		}
	}
}

public OnClientPutInServer(client) 
{ 
	g_hide[client] = true;
	for(new i = 1; i <= MaxClients; i++)
		g_bHide[client][i] = false; 
		
	
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit); 
} 

public Action:Hook_SetTransmit(client1, client2) 
{ 
    if (client1 != client2 && g_hide[client2] && g_bHide[client1][client2]) 
        return Plugin_Handled;
     
    return Plugin_Continue; 
}  