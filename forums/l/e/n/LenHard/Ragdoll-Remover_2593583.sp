#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

bool gB_Slayed[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo = 
{
	name = "[Any] Ragdoll Remover",
	author = "LenHard",
	description = "Removes ragdolls after being slayed.",
	version = "1.0",
	url = "http://steamcommunity.com/id/TheOfficalLenHard/"
};

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    
    AddCommandListener(CL_Kill, "kill");
    AddCommandListener(CL_Kill, "explode");
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);    
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
    if (IsValidClient(victim) && GetClientHealth(victim) <= RoundToFloor(damage))
        gB_Slayed[victim] = false;
}

public void Event_PlayerSpawn(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    
    if (IsValidClient(client))
        gB_Slayed[client] = true;
}

public void Event_PlayerDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    
    if (IsValidClient(client) && gB_Slayed[client])
    	CreateTimer(0.7, Timer_Delay, GetClientUserId(client));
}

public Action Timer_Delay(Handle hTimer, any iUser)
{
	int client = GetClientOfUserId(iUser);

	if (IsValidClient(client))
	{
        int iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
        if (IsValidEdict(iRagdoll)) AcceptEntityInput(iRagdoll, "Kill");	
	}
}

public Action CL_Kill(int client, const char[] sCmd, int args)
{
    if (IsValidClient(client) && IsPlayerAlive(client))
        gB_Slayed[client] = false;
}

bool IsValidClient(int client)
{
    if (!(0 < client <= MaxClients) || !IsClientInGame(client))
        return false;
    return true;
}  