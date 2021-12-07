#include <sourcemod>
#include <sdktools>
new ClientTeam[MAXPLAYERS+1];

//thanks cmptrwz for the help!

public Plugin:myinfo = 
{
	name = "SpecProj Remover",
	author = "KRosen",
	description = "Removes Projectiles when a player switches to spectator",
	version = "0.2",
	url = "http://www.iOGaming.net"
};

public OnPluginStart() 
{
	HookEvent("player_death", EventDeath);
}

public EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	decl Client;
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	ClientTeam[Client] = GetClientTeam(Client);
	CreateTimer(0.15, CheckEntities, Client, TIMER_FLAG_NO_MAPCHANGE);
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
			PrintToServer("[TKFIX] %i Client's Pipe has been removed! %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_rocket")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("[TKFIX] %i Client's Rocket has been removed! %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_stun_ball")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("[TKFIX] %i Client's SandmanBall has been removed! %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_arrow")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("[TKFIX] %i Client's Arrow has been removed! %i", Client, index);
		}
		while ((index = FindEntityByClassname2(index, "tf_projectile_flare")) != -1)
		if(Client == GetEntPropEnt(index, Prop_Send , "m_hOwnerEntity"))
		{
			RemoveEdict(index);
			PrintToServer("[TKFIX] %i Client's Flare has been removed! %i", Client, index);
		}
	}
	return Plugin_Handled;
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}