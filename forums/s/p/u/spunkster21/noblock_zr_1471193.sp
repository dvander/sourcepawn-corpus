#include <sourcemod>
#include <zr/infect.zr>

#define COLLISIONS_DISABLED 2
#define COLLISIONS_ENABLED	5

new g_iOffsetCollision;

public Plugin:myinfo =
{
	name = "[Vs3] Zombie:Reloaded Noblock Mod",
	author = "Spunky",
	description = "Removes player collisions for zombies on Zombie:Reloaded.",
	version = "1.0.0.1",
	url = "http://www.vs3-clan.co.uk"
};

public OnPluginStart()
{
	/* Hook the player spawn event */
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	/* Find offsets. */
	g_iOffsetCollision = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	if (g_iOffsetCollision == -1)
	{
		SetFailState("[[Vs3] Zombie:Reloaded Noblock Mod] [Debug] - Couldn't find 'm_CollisionGroup' offset.");
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Get the userid and client. */
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	/* Set no blocking for this client. */
	if (ZR_IsClientHuman(client))
	{
		SetNoBlock(client, true);
	}
}

SetNoBlock(client, bool:noblock)
{
	if (IsValidClient(client))
	{
		if (noblock)
		{
			SetEntData(client, g_iOffsetCollision, COLLISIONS_DISABLED, 1, true);
		}
		else
		{
			SetEntData(client, g_iOffsetCollision, COLLISIONS_ENABLED, 1, true);
		}
	}
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	SetNoBlock(client, false);
}

bool:IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}