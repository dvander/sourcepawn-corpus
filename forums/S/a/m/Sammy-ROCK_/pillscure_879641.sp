#include <sourcemod>
#define Version "1.1"
#define ZPSMAXPLAYERS 24
#define UpdateDelay 1.0
new InfectedOffset = -1;
new MaxPlayers = -1;
new ClientHP[ZPSMAXPLAYERS] = {0, ...};

public Plugin:myinfo = {
	name = "Pills Cure",
	author = "NBK - Sammy-ROCK!",
	description = "Makes HealthKits and Health Pills cure the infection.",
	version = Version,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawnEvent);
	InfectedOffset = FindSendPropOffs("CHL2MP_Player", "m_IsInfected");
	CreateConVar("pillscure_version", Version, "Version of Pills Cure plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart()
{
	MaxPlayers = GetMaxClients();
	for(new client=1; client<=MaxPlayers; client++)
	{
		if(IsClientInGame(client))
			ClientHP[client] = GetClientHealth(client);
	}
	CreateTimer((UpdateDelay / float(MaxPlayers)), SetUpdateTimer, 1);
}

public Action:SetUpdateTimer(Handle:timer, any:client)
{
	CreateTimer(UpdateDelay, Recheck, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if(client < MaxPlayers)
		CreateTimer((UpdateDelay / float(MaxPlayers)), SetUpdateTimer, client + 1);
}

public Action:Recheck(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new HP = GetClientHealth(client);
		if(GetClientTeam(client) == 2 && ClientHP[client] < HP && GetEntData(client, InfectedOffset))
		{
			SetEntData(client, InfectedOffset, 0);
			PrintToChat(client, "You've been cured from the infection! For now...");
		}
		ClientHP[client] = HP;
	}
}

public Action:PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ClientHP[client] = GetClientHealth(client);
}