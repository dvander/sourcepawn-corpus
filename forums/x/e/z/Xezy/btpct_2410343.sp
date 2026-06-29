#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <sdktools>

public Plugin:myinfo =
{
	name = "SM Force player ct, bot t",
	author = "Xezy",
	description = "Bot join t, Player join ct",
	version = "1.0",
	url = "http://steamcommunity.com/id/kawaiixezy/"
};

new Collision_Offsets;

public OnPluginStart()
{
	Collision_Offsets = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	HookEvent("player_spawn", PlayerSpawn);
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsFakeClient(client) && GetClientTeam(client) > 1)
	{
		ChangeClientTeam(client, 2);
		CS_RespawnPlayer(client);
		
		SetEntData(client, Collision_Offsets, 2, 1, true);
	}
	
	if(!IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		ChangeClientTeam(client, 3);
		CS_RespawnPlayer(client);
		
		SetEntData(client, Collision_Offsets, 2, 1, true);
	}

}