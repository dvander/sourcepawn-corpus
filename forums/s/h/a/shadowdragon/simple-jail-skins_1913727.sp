
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
new String:n_CT_MODEL[65];
new String:n_T_MODEL[65];
new Handle:g_CT_MODEL = INVALID_HANDLE;
new Handle:g_T_MODEL = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "jailskins",
	author = "ShadowDragon",
	description = "jailskins",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_spawn",SpawnEvent);
	g_CT_MODEL = CreateConVar("sm_CT_MODEL","models/player/etc", "URL of model for CT");
	g_T_MODEL = CreateConVar("sm_T_MODEL","models/player/etc", "URL of model for CT");
	AutoExecConfig();
}

public OnMapStart()
{
	GetConVarString(g_CT_MODEL, n_CT_MODEL, sizeof(n_CT_MODEL));
	GetConVarString(g_T_MODEL, n_T_MODEL, sizeof(n_T_MODEL));
	PrecacheModel(n_CT_MODEL, true);
	PrecacheModel(n_T_MODEL, true);
	
}

public Action:SpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid")
	new client = GetClientOfUserId(client_id)
	PrecacheModel(n_CT_MODEL, true);
	PrecacheModel(n_T_MODEL, true);
	GetConVarString(g_CT_MODEL, n_CT_MODEL, sizeof(n_CT_MODEL));
	GetConVarString(g_T_MODEL, n_T_MODEL, sizeof(n_T_MODEL));
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		SetEntityModel(client, n_T_MODEL);
	}
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		SetEntityModel(client, n_CT_MODEL);
	}
}

