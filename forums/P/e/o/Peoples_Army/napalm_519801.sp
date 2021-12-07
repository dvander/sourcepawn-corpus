/* 

	Napalm Grenades
	
		*Ignites Players Injured By Greandes
		
*/


#include <sourcemod>
#include <sdktools_functions>

#define VERSION "0.4"

new Handle:Switch;
new String:Weapon[30];

public Plugin:myinfo = 
{
	name = "Napalm grenades",
	author = "Peoples Army",
	description = "Ignites Players On Fire From Nades",
	version = VERSION,
	url = "www.sourcemod.net"
};

// create convars and hook event

public OnPluginStart()
{
	Switch = CreateConVar("napalm_nades_on","1","Turns the plugin on and off 1/0",FCVAR_NOTIFY);
	HookEvent("player_hurt",DamageEvent);
	HookEvent("player_death",DeathEvent);
}

//hook the player_hurt event and look for nade damge

public DamageEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	GetEventString(event,"weapon",Weapon,30);
	new DmgDone = GetEventInt(event,"dmg_health");
	new clientid = GetEventInt(event,"userid");
	new client = GetClientOfUserId(clientid);
	
	// if plugin is on and nade was found then ignite client
	
	if(StrEqual(Weapon,"hegrenade")== true && GetConVarInt(Switch))
	{
		PrintToChat(client,"Youve Been Hit By A Napalm Grenade!");
		
		if(DmgDone <= 30)
		{
			IgniteEntity(client,12.0);
		}else if(DmgDone > 71)
		{
			IgniteEntity(client,9.0);
		}else if(DmgDone > 51)
		{
			IgniteEntity(client,6.0);
		}else if (DmgDone >= 31)
		{
			IgniteEntity(client,3.0);
		}
	}
}

// extinguihs player on death event to stop eternal ignite sound bug

public DeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new clientid = GetEventInt(event,"userid");
	new client = GetClientOfUserId(clientid);
	
	ExtinguishEntity(client);
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client)== true)
	{
		ExtinguishEntity(client);
	}
}

public bool:OnClientConnect(client)
{
	if(IsClientInGame(client)== true)
	{
		ExtinguishEntity(client);
	}
	return true;
}