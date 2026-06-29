#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0.3"

new Handle:sm_ar_enable = INVALID_HANDLE;
new Handle:ar_respawn_delay = INVALID_HANDLE;
new Handle:ar_respawn_msgs = INVALID_HANDLE;
new Handle:ar_dissolve_ragdolls = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "AutoRespawn",
	author = ".Echo",
	description = "Respawns players shortly after their inevitable death or when they first join the server or change teams",
	version = PLUGIN_VERSION,
	url = "www.ke0.us"
}

public OnPluginStart()
{
	CreateConVar("sm_ar_version", PLUGIN_VERSION, "Defines the version of AutoRespawn installed on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_ar_enable = CreateConVar("sm_ar_enable", "1", "Enables/disables AutoRespawn on this server at any given time", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	ar_respawn_delay = CreateConVar("ar_respawn_delay", "3", "Amount of time (in seconds) after players die before they are automatically respawned");
	ar_respawn_msgs = CreateConVar("ar_respawn_msgs", "1", "Enables/disables notification messages to players after they die that they will be respawned");
	ar_dissolve_ragdolls = CreateConVar("ar_dissolve_ragdolls", "1", "Enables/disables the dissolving of a player's ragdoll following a successful respawn");

	HookEvent("player_team", Event_Spawn);
	HookEvent("player_death", Event_Death);
}

public OnPluginEnd()
{
	UnhookEvent("player_class", Event_Spawn);
	UnhookEvent("player_death", Event_Death);
}

public Event_Spawn( Handle:Spawn_Event, const String:Death_Name[], bool:Death_Broadcast )
{
	if( GetConVarBool(sm_ar_enable) )
	{
		new client = GetClientOfUserId( GetEventInt(Spawn_Event,"userid") );
		new team = GetEventInt(Spawn_Event, "team");

		if( client != 0 && team > 1 )
		{
			new Float:respawndelaytime = GetConVarFloat(ar_respawn_delay);
			CreateTimer(respawndelaytime, RespawnClient, any:client);
			
			if( GetConVarBool(ar_respawn_msgs) )
			{
				new respawndelaytimeint = GetConVarInt(ar_respawn_delay);
				PrintToChat(client, "\x01\x04[AutoRespawn] \x01You will spawn in approximately %d seconds...", respawndelaytimeint);
			}
		}
	}
}

public Event_Death( Handle:Death_Event, const String:Death_Name[], bool:Death_Broadcast )
{
	if( GetConVarBool(sm_ar_enable) )
	{
		new client = GetClientOfUserId( GetEventInt(Death_Event,"userid") );

		if ( client != 0 )
		{
			new Float:respawndelaytime = GetConVarFloat(ar_respawn_delay);
			CreateTimer(respawndelaytime, RespawnClient, any:client);
			
			if( GetConVarBool(ar_respawn_msgs) )
			{
				new respawndelaytimeint = GetConVarInt(ar_respawn_delay);
				PrintToChat(client, "\x01\x04[AutoRespawn] \x01You will respawn in approximately %d seconds...", respawndelaytimeint);
			}
		}
	}
}

public Action:RespawnClient( Handle:timer, any:client )
{
	if( GetConVarBool(sm_ar_enable) )
	{
		if ( IsValidEntity(client) && IsClientInGame(client) && IsClientObserver(client) && !IsPlayerAlive(client) )
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
}