#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Collision_Offsets;

ConVar g_cvPlayerCollision;

public Plugin:myinfo = 
{
	name = "Noblock for players", 
	author = "tommie113 & modified by Walgrim", 
	description = "Enables noblock for player.", 
	version = "1.2", 
	url = "http://www.sourcemod.net"
}

public void OnPluginStart()
{
	Collision_Offsets = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	g_cvPlayerCollision = CreateConVar("sm_noplayerblock_enabled", "1", "1 to enable noblock for players, 0 to disable noblock for players.");
	
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
		if(GetClientTeam(user) == 3)
		{
			SetEntData(client, Collision_Offsets, 2, 1, true);
		}
		else
		 SetEntData(client, Collision_Offsets, 2, 1, false);
	}
}
