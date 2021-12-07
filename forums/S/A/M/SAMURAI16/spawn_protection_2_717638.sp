#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Spawn Protection",
	author = "SAMURAI",
	description = "",
	version = "0.1",
	url = ""
}

#define TIMER_TIME 20.0
#define SLAP_DAMAGE 25

new bool:OnSpawn[MAXPLAYERS + 1] = false;

public OnPluginStart()
{
	HookEvent("player_hurt",fnPlayerHurtEvent);
}

public OnClientPutInServer(client)
{
	OnSpawn[client] = false;
}

public OnClientDisconnect(client)
{
	OnSpawn[client] = false;
}


public Action:fnPlayerHurtEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	
	if(!client && !IsClientConnected(client) && !IsClientInGame(client) && !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(!attacker && !IsClientConnected(attacker) && !IsClientInGame(attacker) && !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(OnSpawn[client])
	{
		SlapPlayer(attacker,SLAP_DAMAGE);
	}
		
	return Plugin_Continue;
}

public Action:Event_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    
    if(client && IsClientConnected(client) && IsClientInGame(client))
	{
		new Handle:data = CreateDataPack();
		WritePackCell(data,client);
		
		OnSpawn[client] = true;
        
		CreateTimer(TIMER_TIME,fnRmvProt,data,TIMER_HNDL_CLOSE);
	}
    
}

public Action:fnRmvProt(Handle:timer,any:data)
{
	ResetPack(Handle:data);
	new client = ReadPackCell(Handle:data);
	
	if(client && IsClientConnected(client) && IsClientInGame(client) && OnSpawn[client])
	{
        OnSpawn[client] = false;
	}
}