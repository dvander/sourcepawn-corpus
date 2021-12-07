#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1.0 Kigen Edit"


// convars
new Handle:cvDelay = INVALID_HANDLE;
new Handle:cvType = INVALID_HANDLE;


public Plugin:myinfo = {
	name = "Dissolve",
	author = "L. Duke, modified by Kigen",
	description = "Dissolves dead bodies",
	version = PLUGIN_VERSION,
	url = "http://www.lduke.com/"
};

public OnPluginStart() 
{ 
	// events
	HookEvent("player_death",PlayerDeath);
  
	// convars
	CreateConVar("sm_dissolve_version", PLUGIN_VERSION, "Dissolve", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvDelay = CreateConVar("sm_dissolve_delay","2");
	cvType = CreateConVar("sm_dissolve_type", "0");
}

public OnEventShutdown()
{
	UnhookEvent("player_death",PlayerDeath);
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !client )
		return Plugin_Continue;

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll<0)
	{
		PrintToServer("[DISSOLVE] Could not get ragdoll for player!");  
		return Plugin_Continue;
	}
	
	new Float:delay = GetConVarFloat(cvDelay);
	if (delay>0.0)
		CreateTimer(delay, Dissolve, ragdoll); 
	else
		Dissolve(INVALID_HANDLE, ragdoll);

	return Plugin_Continue;
}



public Action:Dissolve(Handle:timer, any:ragdoll)
{
	if (!IsValidEntity(ragdoll))
		return Plugin_Stop;

	new String:dname[32], String:dtype[32];
	Format(dname, sizeof(dname), "dis_%d", ragdoll);
	Format(dtype, sizeof(dtype), "%d", GetConVarInt(cvType));
  
	new ent = CreateEntityByName("env_entity_dissolver");
	if (ent>0)
	{
		DispatchKeyValue(ragdoll, "targetname", dname);
		DispatchKeyValue(ent, "dissolvetype", dtype);
		DispatchKeyValue(ent, "target", dname);
		AcceptEntityInput(ent, "Dissolve");
		AcceptEntityInput(ent, "kill");
	}
	return Plugin_Stop;
}


