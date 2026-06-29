#include <sourcemod>
#include <sdktools>
#include <hooker>

public Plugin:myinfo = 
{
    name = "Spawn Protection",
    author = "SAMURAI",
    description = "",
    version = "0.1",
    url = ""
}

#define    DAMAGE_NO  0
#define    DAMAGE_YES 2
#define    TIMER_TIME 20.0

new bool:OnSpawn[MAXPLAYERS + 1] = false;
new i_maxclients;

public OnPluginStart()
{
	HookEvent("player_spawn",Event_spawn);
    
	RegisterHook(HK_OnTakeDamage, TakeDamageFunction, false);

	i_maxclients = GetMaxClients();
}


public OnClientPutInServer(client)
{
	OnSpawn[client] = false;
	HookEntity(HKE_CCSPlayer, client);
}

public OnClientDisconnect(client)
{
    OnSpawn[client] = false;
    UnHookPlayer(HKE_CCSPlayer, client);

}

public Action:TakeDamageFunction(client, &inflictor, &attacker, &Float:Damage, &DamageType, &AmmoType)
{
	if(!client && !IsClientConnected(client) && !IsClientInGame(client))
	{
		PrintToChatAll("client not in game");
		return Plugin_Continue;
	}
	
	if(!attacker && !IsClientConnected(client) && !IsClientInGame(attacker))
	{
		PrintToChatAll("attacker not in game");
		return Plugin_Continue;
	}
	
	PrintToChatAll("debug :takedamage func client %d | attacker : %d Damage : %f",client,attacker,Damage);
        
	if(client && client <= i_maxclients && IsClientInGame(client) && OnSpawn[client])
	{
			if(attacker && IsClientConnected(attacker) && IsClientInGame(attacker))
				SetEntityHealth(attacker,GetClientHealth(attacker) - RoundFloat(Damage))

			Damage = 0.0;

			return Plugin_Changed;
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