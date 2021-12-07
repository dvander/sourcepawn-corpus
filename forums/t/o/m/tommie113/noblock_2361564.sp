#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Collision_Offsets;

ConVar g_cvPlayerCollision;
ConVar g_cvNadeCollision;

public Plugin:myinfo = 
{
	name = "Noblock for players and nades", 
	author = "tommie113", 
	description = "Enables noblock for players and grenades.", 
	version = "1.0", 
	url = "http://www.sourcemod.net"
}

public void OnPluginStart()
{
	Collision_Offsets = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	g_cvPlayerCollision = CreateConVar("sm_noplayerblock_enabled", "1", "1 to enable noblock for players, 0 to disable noblock for players.");
	g_cvNadeCollision = CreateConVar("sm_nonadeblock_enabled", "1", "1 to enable noblock for nades, 0 to disable noblock for nades.");
	
	AutoExecConfig(true, "noblock", "sourcemod");
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new cvPlayerCollision = GetConVarInt(g_cvPlayerCollision);
	if(cvPlayerCollision == 1)
	{
		new user = GetEventInt(event, "userid");
		new client = GetClientOfUserId(user);
	
		SetEntData(client, Collision_Offsets, 2, 1, true);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	new cvNadeCollision = GetConVarInt(g_cvNadeCollision);
	if(cvNadeCollision == 1)
	{
		if(StrContains(classname, "_projectile") != -1)
		{
			SetEntData(entity, Collision_Offsets, 2, 1, true);
		}
	}
}