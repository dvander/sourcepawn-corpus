
/* 
	Round End Protection

		This Plugin Will Stop Players From Being Harmed/Killed After The ROund Has Ended
*/

#include <sourcemod>
#include <clients>
#include <sdktools>

#define VERSION    "0.4"   //plugin version

new Handle: Switch;
//new bool:RoundEnded = true

public Plugin:myinfo = 
{
	name = "Round End Protection",
	author = "Peoples Army",
	description = "Keeps Players From Being Killed At ROund End",
	version = VERSION,
	url = "www.sourcemod.net"
}

// hook round end event on plugin start

public OnPluginStart()
{
	Switch = CreateConVar("round_end_on","1","1 Turns The Plugin On 0 Is Off",FCVAR_NOTIFY);
	HookEvent("round_end",StopKills, EventHookMode_Pre);
	HookEvent("round_start",ResetMode);
    ///HookEvent("player_spawn",SpawnEvent);
}

// force godmode on all players for round end

public Action:StopKills(Handle: event , const String: name[] , bool: dontBroadcast)
{
	if(GetConVarInt(Switch))
	{	
		new PLAYERS = GetMaxClients();
		//RoundEnded = true;
	
		for(new j = 1 ; j <= PLAYERS ; ++j)
		{
			if(IsValidEntity(j))
			{
				SetEntProp(j, Prop_Data, "m_takedamage", 0 , 1);
			}
		}
	}
}

public ResetMode(Handle: event , const String: name[] , bool: dontBroadcast)
{
	if(GetConVarInt(Switch))
	{
		new PLAYERS = GetMaxClients();
		//RoundEnded = false;
	
		for(new j = 1 ; j <= PLAYERS ; ++j)
		{
			if(IsValidEntity(j))
			{
				SetEntProp(j, Prop_Data, "m_takedamage", 2 , 1);
			}
		}
	}
}
/*
public SpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new clientID = GetEventInt(event,"userid");
	new client = GetClientOfUserId(clientID);
	
	if(RoundEnded == true)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0 , 1);
	}

*/