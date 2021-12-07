#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define TEAM_SPECTATOR 1
#define PIPEBOMB "tf_projectile_pipe"
#define ROCKET "tf_projectile_rocket"
#define PLUGIN_VERSION 1.1.0

public Plugin:myinfo = 
{
	name = "Speckill Blocker",
	author = "Ubercow",
	description = "Prevents killing from spectator using Demo Grenades or Solider Rockets",
	version = PLUGIN_VERSION,
	url = "www.nom-nom-nom.us"
}

public OnPluginStart()
{
	HookEvent("player_team", ChangeTeam);
	CreateConVar("uberspeckill_version", PLUGIN_VERSION, "Uberspeckill Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public Action:ChangeTeam(Handle:event, const String:eventName[], bool:dontBroadcast)
{
	new user = GetEventInt(event, "userid");
	new client = GetClientOfUserId(user);
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if (class == TFClass_DemoMan)
	{
		new index = -1;
		while ((index = FindEntityByClassname2(index, PIPEBOMB)) != -1)
		{
			new thrower = GetEntPropEnt(index, Prop_Send, "m_hThrower");			
			if (client == thrower) RemoveEdict(index);
		}
	}
	else if (class == TFClass_Soldier)
	{
		new index = -1;
		while ((index = FindEntityByClassname2(index, ROCKET)) != -1)
		{
			new owner = GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity");
			if (client == owner) RemoveEdict(index);
		}
	}
	
	return Plugin_Continue;
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}