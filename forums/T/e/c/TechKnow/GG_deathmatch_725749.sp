/*
	SM GG Deathmatch bY TechKnow
	
	
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.6"




public Plugin:myinfo = 
{
	name = "SM GG Deathmatch",
	author = "TechKnow",
	description = "Gives deathmatch respawn to GunGames",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:g_Respawn[MAXPLAYERS + 1];
new Handle:hRoundRespawn;
new Handle:Cvar_RespawnEnable;
new Handle:Cvar_Removeweapons;
new Handle:hGameConf;
new g_WeaponParent;

public OnPluginStart()
{
	CreateConVar("sm_GG-Deathmatch_version", PLUGIN_VERSION, "GG-Deathmatch", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	Cvar_RespawnEnable = CreateConVar("Respawn_on", "1", "1 respawn on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

	Cvar_Removeweapons = CreateConVar("Removeweapons_on", "1", "1 Removeweapons on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);


        hGameConf = LoadGameConfigFile("ggdm.gamedata")		
	
	StartPrepSDKCall(SDKCall_Player)
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn")
	hRoundRespawn = EndPrepSDKCall()

	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

	HookEventEx("player_death", SpawnTimer, EventHookMode_Post);
        HookEventEx("round_start", RoundStart, EventHookMode_Post);
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);
        CreateTimer(10.0, Autospawn, _, TIMER_REPEAT);	
        
}

public OnClientPutInServer(client)
{
	 if(!IsFakeClient(client))
	 {
                g_Respawn[client] = INVALID_HANDLE;
         }
}

public OnClientDisconnect(client)
{     
	if (g_Respawn[client] != INVALID_HANDLE)
	{
		KillTimer(g_Respawn[client]);
                g_Respawn[client] = INVALID_HANDLE;
	}
}

public Action:RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
        // By Kigen (c) 2008 - Please give me credit. :)
        if (!GetConVarBool(Cvar_Removeweapons))
	{
		return Plugin_Continue;
	}
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
					RemoveEdict(i);
		}
	}	
	return Plugin_Continue;
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// check to see if there is an outstanding handle from last round
	if (g_Respawn[client] != INVALID_HANDLE)
	{
	      KillTimer(g_Respawn[client]);
              g_Respawn[client] = INVALID_HANDLE;
	}
	return Plugin_Continue;
}

public Action:EventRoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// check to see if there is an outstanding handle
	if (g_Respawn[client] != INVALID_HANDLE)
	{
		KillTimer(g_Respawn[client]);
                g_Respawn[client] = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public Action:SpawnTimer(Handle:event,const String:name[],bool:dontBroadcast)
{
        if (!GetConVarBool(Cvar_RespawnEnable))
	{
		return Plugin_Continue;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(client))
	{
		g_Respawn[client] = CreateTimer(3.0, ExecRespawn, client);
	}
        // By Kigen (c) 2008 - Please give me credit. :)
        if (!GetConVarBool(Cvar_Removeweapons))
	{
		return Plugin_Continue;
	}
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
					RemoveEdict(i);
		}
	}	
	return Plugin_Continue;
}

public Action:ExecRespawn(Handle:timer, any:client)
{
        if(GetClientTeam(client) == 1)
        {
		KillTimer(g_Respawn[client]);
                g_Respawn[client] = INVALID_HANDLE;
                return Plugin_Continue;
        }
	if(client && IsClientInGame(client))
        {
	       SDKCall(hRoundRespawn, client)
               PrintToChat(client,"\x01\x04[GGDM]You have been respawned");
        }
	if (g_Respawn[client] != INVALID_HANDLE)
	{
		KillTimer(g_Respawn[client]);
                g_Respawn[client] = INVALID_HANDLE;
	}
	return Plugin_Continue;
}

public Action:Spawn(client)
{
	SDKCall(hRoundRespawn, client);
        PrintToChat(client,"\x01\x04[GGDM]You have been Spawned");
	return Plugin_Continue;
}

public Action:Autospawn (Handle:timer)
{
    new maxclients = GetMaxClients( );

    for(new i = 1; i < maxclients; i++)
    {
        if(!IsClientConnected(i) || !IsClientInGame(i))
            continue;
        new team = GetClientTeam(i)
 
        if (team < 2) 
            continue;
        if (g_Respawn[i] == INVALID_HANDLE && !IsPlayerAlive(i))
        {
              Spawn(i);
        }
        }
    return Plugin_Continue;

}
