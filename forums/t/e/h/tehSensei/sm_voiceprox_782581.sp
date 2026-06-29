/*
   VOICE PROXIMITY
   Created by tehSensei AKA Han [BlackWatch]
   blackwatch.clanservers.com
  
   DESCRIPTION
   This plugin forces voice communication only to players within a certain
   radius of the speaker, which makes it so you cannot communicate to 
   players accross the map; but rather within "speaking range," which is a
   distance defined in a cvar. If alltalk is on, players will hear players from
   the opposite team if within proximity, but the dead are silent to them.  
   If alltalk is off, it's the same, except you cannot hear the other 
   team.  Likewise, the dead can only talk to other dead.  Only tested in 
   Day of Defeat:Source, but I don't see why it wouldn't work in TF2 or CSS.
   
   Credits:
   Wilson [29th ID] original amx script
   k2joyride help with functionality
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.100"

new Handle:g_enabled = INVALID_HANDLE
new Handle:g_distance = INVALID_HANDLE
new Handle:g_interval = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "sm_voiceprox",
	author = "tehSensei AKA Han [BlackWatch]",
	description = "Voice proximity mod",
	version = PLUGIN_VERSION,
	url = "www.blackwatch.clanservers.com"
}

public OnPluginStart() 
{
	
	CreateConVar("sm_voiceprox_version", PLUGIN_VERSION, "Version of sm_voiceprox", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_enabled  = CreateConVar("sm_voiceprox", "0","Enables Voice Proximity Plugin",FCVAR_PLUGIN)
	g_distance = CreateConVar("sm_voiceprox_distance", "1000","Sets the distance voices can be transmitted",FCVAR_PLUGIN)
	g_interval = CreateConVar("sm_voiceprox_interval",".2","Sets the delay between area checks",FCVAR_PLUGIN)
	
	CreateTimer(GetConVarInt(g_interval) * 1.0, Timer_UpdateListeners, _, TIMER_REPEAT)


}

public Action:Timer_UpdateListeners(Handle:timer) 
{
	new maxplayers = GetMaxClients()
	for (new client = 1; client<=maxplayers; client++)
	{
		if(GetConVarInt(g_enabled) == 1)
		{
			if(IsClientInGame(client))
			{
				if((IsPlayerAlive(client)) )
				{
					check_area(client)
				}
				else
				{
					check_dead(client)
				}
			}
		}
		else
		{
			set_all_listening(client)
		}
	}
}

public check_area(client) 
{
	new maxplayers = GetMaxClients()
	for (new id = 1; id <= maxplayers ; id++)
	{
		if (IsClientInGame(id) && id != client)
		{
			if(entity_distance_stock(client, id) <= GetConVarInt(g_distance) && IsPlayerAlive(id))
			{	
				SetClientListening(client, id, false)//In Range
			}
			else
			{
				SetClientListening(client, id, true)//Out of Range
			}
		}
	}
}

public check_dead(client) 
{
	new maxplayers = GetMaxClients()
	for (new id = 1; id <= maxplayers ; id++)
	{
		if (IsClientInGame(id) && id != client)
		{
			if(!IsPlayerAlive(id))
			{	
				SetClientListening(client, id, false)//In Range
			}
			else
			{
				SetClientListening(client, id, true)//Out of Range
			}
		}
	}
}

public set_all_listening(client)
{
	new maxplayers = GetMaxClients()
	for (new id = 1; id <= maxplayers ; id++)
	{
		if (IsClientInGame(id) && id != client)
		{
			SetClientListening(client, id, false)//In Range
		}
	}

}

stock Float:entity_distance_stock(ent1, ent2)
{
        new Float:orig1[3]
        new Float:orig2[3]
	
	new orig
 
	orig = FindSendPropOffs("CDODPlayer", "m_vecOrigin")
        GetEntDataVector(ent1, orig, orig1)
        GetEntDataVector(ent2, orig, orig2)
 
        return GetVectorDistance(orig1, orig2)
} 