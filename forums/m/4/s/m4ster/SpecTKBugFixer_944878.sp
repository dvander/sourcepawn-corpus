#include <sourcemod>
#include <sdktools>

//thanks cmptrwz for the help!

public Plugin:myinfo = 
{
	name = "SpecProj Remover",
	author = "KRosen",
	description = "Removes Projectiles when a player switches to spectator",
	version = "0.2a",
	url = "http://www.iOGaming.net"
};

public OnPluginStart()
{
	HookEvent("player_team", EventPlayerTeamChange);
}

public EventPlayerTeamChange(Handle:Event, const String:name[], bool:dontBroadcast)
{
  decl Client;
  Client = GetClientOfUserId(GetEventInt(Event, "userid"));
  
  new index = -1;
		while ((index = FindEntityByClassname2(index, "tf_projectile_pipe")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hThrower"))
		{
			RemoveEdict(index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_rocket")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_stun_ball")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_arrow")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_flare")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
		}
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
	