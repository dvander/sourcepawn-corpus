#include <sourcemod>
#include <sdktools>
new ClientTeam[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Fix spectator killing & team switching, 2017 edition",
	author = "Spirit @ spirit.re, original by KRosen",
	description = "And we hope it's been worth the wait.",
	version = "1.0",
	url = "https://spirit.re/"
};

public OnPluginStart() 
{
	HookEvent("player_death", EventDeath);
	HookEvent("player_team", EventPlayerTeamChange);
}

public EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	decl Client;
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	ClientTeam[Client] = GetClientTeam(Client);
	CreateTimer(0.1, CheckEntities, Client, TIMER_FLAG_NO_MAPCHANGE);
}

public EventPlayerTeamChange(Handle:Event, const String:Name[], bool:Broadcast)
{
	decl Client;
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	ClientTeam[Client] = GetClientTeam(Client);
	
	CreateTimer(0.1, SlayPlayer, Client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.12, CheckEntities, Client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:SlayPlayer(Handle:Timer, any:Client)
{
	ForcePlayerSuicide(Client);
	SlapPlayer(Client, 999, true);
}

public Action:CheckEntities(Handle:Timer, any:Client)
{
	new ClientTeamAfter = GetClientTeam(Client);
	if(ClientTeamAfter == 1)
	{
		new index = -1;
		while ((index = FindEntityByClassname2(index, "tf_projectile_pipe")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hThrower"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's pipe %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_rocket")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's rocket %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_stun_ball")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's sandman ball %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_ball_ornament")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's ornament ball %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_arrow")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's arrow %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_flare")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's flare %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_jar")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's jarate %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_cleaver")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's cleaver %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_energy_ball")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's energy ball %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_energy_ring")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's energy ring %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_lightningorb")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's lightning orb %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_throwable")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("Removing %i's throwable %i", Client, index);
		}
	}
	return Plugin_Handled;
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}