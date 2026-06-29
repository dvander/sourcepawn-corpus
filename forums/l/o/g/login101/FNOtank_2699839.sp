
#pragma semicolon 1

/* 	INCLUDE	 */
#include <sourcemod>
#include <sdktools>

/* 	DEFINE	*/

/* 	NEW	 */
new bool:b_tankspawn = false;

/* 	HANDLE	 */

/*	INFORMATION	*/

public Plugin:myinfo =
{
	name = "No SI buring the tank alive",
	author = "Jun2",
	description = "Noting",
	version = "1.0",
	url = ""
}

/* 	PLUGIN START 	*/

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_first_spawn", Event_First_Spawn);
}

/* 	EVENTS 	*/

public Action:Event_TankSpawn(Handle:event,  String:event_name[], bool:dontBroadcast)
{
	b_tankspawn = true;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		new Z_Class = GetZombieClass(i);
		
		if(IsClientConnected(i)
		&& IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3 && Z_Class != 8)
			{
				KickClient(i);
			}
		}
	}
}

public Action:Event_RoundStart(Handle:event,  String:event_name[], bool:dontBroadcast)
{
	b_tankspawn = false;
}

public Action:Event_RoundEnd(Handle:event,  String:name[], bool:dontBroadcast)
{
	b_tankspawn = false;
}

public Action:Event_First_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Spawner = GetClientOfUserId(GetEventInt(event, "userid"));
	new Z_Class = GetZombieClass(Spawner);
	
	if(IsClientConnected(Spawner)
	&& IsClientInGame(Spawner))
	{
		if(GetClientTeam(Spawner) == 3 && Z_Class != 8 && b_tankspawn)
		{
			KickClient(Spawner);
		}
	}
}


/* 	STOCK OPTION 	*/

stock GetZombieClass(client) return GetEntProp(client, Prop_Send, "m_zombieClass");
