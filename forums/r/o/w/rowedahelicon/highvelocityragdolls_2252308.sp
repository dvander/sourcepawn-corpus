#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new Handle:highVel;

public Plugin:myinfo = 
{
	name = "[TF2] High Velocity Ragdolls",
	author = "Rowedahelicon",
	description = "WHEEEEE",
	version = PLUGIN_VERSION,
	url = "http://www.rowedahelicon.com"
};

public OnPluginStart()
{	
	CreateConVar("sm__highvel_version", PLUGIN_VERSION, "[TF2] High Velocity Ragdolls", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	highVel = CreateConVar("sm_highvel", "1", "Enables the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetConVarInt(highVel) == 1 && IsValidClient(client) ){
	
	CreateTimer(0.0, RemoveBody, client);

	new vteam = GetClientTeam(client);
	new vclass = int:TF2_GetPlayerClass(client);
	decl Ent;
	Ent = CreateEntityByName("tf_ragdoll");
	

	new Float:Vel[3];
	Vel[0] = -180000.552734;
	Vel[1] = -1800.552734;
	Vel[2] = 800000.552734; //Muhahahahaha
	
	SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", Vel);
	SetEntPropVector(Ent, Prop_Send, "m_vecForce", Vel);

	decl Float:ClientOrigin[3];
	
	SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", ClientOrigin); 
	SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", client);
	SetEntProp(Ent, Prop_Send, "m_iTeam", vteam);
	SetEntProp(Ent, Prop_Send, "m_iClass", vclass);
	SetEntProp(Ent, Prop_Send, "m_nForceBone", 1);

	DispatchSpawn(Ent);
	
	CreateTimer(5.0, RemoveRagdoll, Ent);
}
	return Plugin_Continue; //Plugin continue needs to happen here otherwise it will hide the event from the killfeed regardless.
}

public Action:RemoveBody(Handle:Timer, any:Client)
{
	decl BodyRagdoll;
	BodyRagdoll = GetEntPropEnt(Client, Prop_Send, "m_hRagdoll");
	
	if(IsValidEdict(BodyRagdoll))
	{
		AcceptEntityInput(BodyRagdoll, "kill");
	}
}

public Action:RemoveRagdoll(Handle:Timer, any:Ent)
{
	if(IsValidEntity(Ent))
	{
		decl String:Classname[64];
		GetEdictClassname(Ent, Classname, sizeof(Classname));
		if(StrEqual(Classname, "tf_ragdoll", false))
		{
			AcceptEntityInput(Ent, "kill");
		}
	}
}

stock bool:IsValidClient(iClient)
	{
		if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
		return true;
	}