#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

Handle g_Enabled;
Handle g_FF;

public Plugin myinfo =
{
	name 			= "AbNeR Remove Bullet Impact",
	author 			= "AbNeR @CSB",
	description 	= "Remove bullet impact in teammates when FF is off.",
	version 		= PLUGIN_VERSION,
	url 			= "www.tecnohardclan.com/forum"
}

public void OnPluginStart()
{
	g_Enabled = CreateConVar("abner_remove_bullet_impact", "1", "Enable/Disable plugin");
	CreateConVar("abner_remove_bullet_impact_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	AutoExecConfig(true, "abner_remove_bullet_impact");
	
	g_FF = FindConVar("mp_friendlyfire");
	
	for(int i = 1;i <= MaxClients;i++)
	{
		if(IsValidClient(i))
			OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, Hook_TraceAttack);
}

public Action Hook_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) 
{
	if(GetConVarInt(g_Enabled) <= 0 || GetConVarInt(g_FF) == 1)
		return Plugin_Continue;
		
	if(IsValidClient(attacker) && IsValidClient(victim))
	{
		if(attacker != victim)   
        {
            if(GetClientTeam(attacker) == GetClientTeam(victim)) 
			   return Plugin_Handled;
        } 
	}
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
