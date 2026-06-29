#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0.3b3"

new Handle:sm_ar_enable			 			= INVALID_HANDLE;
new Handle:ar_respawn_delay		 			= INVALID_HANDLE;
new Handle:ar_respawn_msgs		 			= INVALID_HANDLE;
new Handle:ar_dissolve_ragdolls	 			= INVALID_HANDLE;
new Handle:ar_respawn_timer[MAXPLAYERS+1] 	= INVALID_HANDLE;
new Handle:ar_respawn_timer2[MAXPLAYERS+1] 	= INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "AutoRespawn",
	author = ".Echo, Zephyrus, St00ne",
	description = "Respawns players shortly after their inevitable death, or when they first join the server, or change teams.",
	version = PLUGIN_VERSION,
	url = "www.ke0.us"
};

public OnPluginStart()
{
	CreateConVar("sm_ar_version", PLUGIN_VERSION, "Version of AutoRespawn.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	sm_ar_enable = CreateConVar("sm_ar_enable", "1", "Enables/disables AutoRespawn on this server at any given time.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	ar_respawn_delay = CreateConVar("ar_respawn_delay", "3", "Delay in seconds before a player is automatically respawned.");
	ar_respawn_msgs = CreateConVar("ar_respawn_msgs", "1", "Enables/disables AutoRespawn notification messages to players.");
	ar_dissolve_ragdolls = CreateConVar("ar_dissolve_ragdolls", "1", "Enables/disables the dissolving of a player's ragdoll following a successful respawn.");

	HookEvent("player_team", Event_Spawn);
	HookEvent("player_death", Event_Death);
	HookEvent("round_end", round_end);
}

public Event_Spawn(Handle:Spawn_Event, const String:Death_Name[], bool:Death_Broadcast)
{
	if( GetConVarBool(sm_ar_enable) )
	{
		new client = GetClientOfUserId( GetEventInt(Spawn_Event,"userid") );
		new team = GetEventInt(Spawn_Event, "team");

		if( client != 0 && team > 1 )
		{
			new Float:respawndelaytime = GetConVarFloat(ar_respawn_delay);
			ar_respawn_timer[client] = CreateTimer(respawndelaytime, RespawnClient, client, TIMER_FLAG_NO_MAPCHANGE);
			
			if( GetConVarBool(ar_respawn_msgs) )
			{
				new respawndelaytimeint = GetConVarInt(ar_respawn_delay);
				PrintToChat(client, "\x01\x04[AutoRespawn] \x01You will spawn in approximately %d seconds...", respawndelaytimeint);
			}
		}
	}
}

public Event_Death(Handle:Death_Event, const String:Death_Name[], bool:Death_Broadcast)
{
	if( GetConVarBool(sm_ar_enable) )
	{
		new client = GetClientOfUserId( GetEventInt(Death_Event,"userid") );

		if ( client != 0 )
		{
			new Float:respawndelaytime = GetConVarFloat(ar_respawn_delay);
			ar_respawn_timer2[client] = CreateTimer(respawndelaytime, RespawnClient2, client, TIMER_FLAG_NO_MAPCHANGE);
			
			if( GetConVarBool(ar_respawn_msgs) )
			{
				new respawndelaytimeint2 = GetConVarInt(ar_respawn_delay);
				PrintToChat(client, "\x01\x04[AutoRespawn] \x01You will respawn in approximately %d seconds...", respawndelaytimeint2);
			}
		}
	}
}

public Action:RespawnClient(Handle:timer, any:client)
{
	if( GetConVarBool(sm_ar_enable) )
	{
		if ( client && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client) && IsClientObserver(client) && GetClientTeam(client) > 1 )
		{
			if ( GetConVarBool(ar_dissolve_ragdolls) )
			{
  				new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
  				if ( ragdoll > 0 )
				{
					new ent = CreateEntityByName("env_entity_dissolver");
					if ( ent > 0 )
					{
						new String:dissolvename[32];
						Format(dissolvename, sizeof(dissolvename), "dis_%d", client);
						DispatchKeyValue(ragdoll, "targetname", dissolvename);
						DispatchKeyValue(ent, "dissolvetype", "0");
						DispatchKeyValue(ent, "target", dissolvename);
						AcceptEntityInput(ent, "Dissolve");
						AcceptEntityInput(ent, "kill");
					}
				}
			}
			CS_RespawnPlayer(client);
		}
	}
	ar_respawn_timer[client] = INVALID_HANDLE;
}

public Action:RespawnClient2(Handle:timer, any:client)
{
	if( GetConVarBool(sm_ar_enable) )
	{
		if ( client && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client) && IsClientObserver(client) && GetClientTeam(client) > 1 )
		{
			if ( GetConVarBool(ar_dissolve_ragdolls) )
			{
  				new ragdoll2 = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
  				if ( ragdoll2 > 0 )
				{
					new ent2 = CreateEntityByName("env_entity_dissolver");
					if ( ent2 > 0 )
					{
						new String:dissolvename2[32];
						Format(dissolvename2, sizeof(dissolvename2), "dis_%d", client);
						DispatchKeyValue(ragdoll2, "targetname", dissolvename2);
						DispatchKeyValue(ent2, "dissolvetype", "0");
						DispatchKeyValue(ent2, "target", dissolvename2);
						AcceptEntityInput(ent2, "Dissolve");
						AcceptEntityInput(ent2, "kill");
					}
				}
			}
			CS_RespawnPlayer(client);
		}
	}
	ar_respawn_timer2[client] = INVALID_HANDLE;
}

public OnClientDisconnect(client)
{
	if (ar_respawn_timer[client] != INVALID_HANDLE)
	{
		KillTimer(ar_respawn_timer[client]);
		ar_respawn_timer[client] = INVALID_HANDLE;
	}
	if (ar_respawn_timer2[client] != INVALID_HANDLE)
	{
		KillTimer(ar_respawn_timer2[client]);
		ar_respawn_timer2[client] = INVALID_HANDLE;
	}
}

public round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if (ar_respawn_timer[i] != INVALID_HANDLE)
		{
			KillTimer(ar_respawn_timer[i]);
			ar_respawn_timer[i] = INVALID_HANDLE;
		}
		if (ar_respawn_timer2[i] != INVALID_HANDLE)
		{
			KillTimer(ar_respawn_timer2[i]);
			ar_respawn_timer2[i] = INVALID_HANDLE;
		}
	}
}

//**END**//