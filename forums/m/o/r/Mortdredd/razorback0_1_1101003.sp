//**********************************************************************************
//* Name: Razorback Respawner
//* Description: Snipers Razorback respawns after destruction
//* Creator: Mortdredd
//**********************************************************************************

//**********************************************************************************
//* Includes
//**********************************************************************************

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "0.1"

//**********************************************************************************
//* Name: my info
//* Description: basic information about the plugin
//**********************************************************************************

public Plugin:myinfo = 
{
    name = "Razorback Respawner",
    author = "Mortdredd",
    description = "Snipers Razorback respawns after destruction",
    version = "0.1",
    url = "http://www.alliedmods.net"
}

//**********************************************************************************
//* Name: On Plugin Start - Event Handler
//* Description: Set up the Hooks etc
//**********************************************************************************

public OnPluginStart()
{
	//Cvars
	CreateConVar("sm_razorback_version", PLUGIN_VERSION, "Razorback Replenisher Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
	//Hooks
	HookEvent("player_shield_blocked",player_shield_blocked);
}

//**********************************************************************************
//* Name: The Event
//* Description:The durtah spaih stickin the Knife in!
//**********************************************************************************

public Action:player_shield_blocked(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client_id = GetEventInt(event, "blocker_entindex");
    new client = GetClientOfUserId(client_id);
    if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
    {
       CreateTimer(0.5, GiveEquipment, client);
    }
}

//**********************************************************************************
//* Name: GiveEquipment
//* Description: create the timer that gives out Razorback
//**********************************************************************************

public Action:GiveEquipment(Handle:timer, any:client)
{
	new weapon = GetPlayerWeaponSlot(client, 1);
	if (IsValidEntity(weapon))
	{
		if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 57)
		{
		GivePlayerItem(client, "m_iItemDefinitionIndex", 57);
		}
	}
	CloseHandle(timer);
}