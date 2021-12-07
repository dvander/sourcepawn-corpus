#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new String:doorlist[][32] = {
	
	"func_door",
	"func_rotating",
	"func_door_rotating",
	"func_movelinear",
	"prop_door",
//	"prop_door_rotating",
	"func_tracktrain",
	"func_elevator",
	"\0"
};

public Plugin:myinfo = 
{
	name = "Func_Door Fix",
	author = "Zephyrus",
	description = "Fixes func_door bug.",
	version = "2.1",
	url = ""
}

public OnPluginStart()
{
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Event_TakeDamage); 
}

public Action:Event_TakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new String:classname[32];
	GetEdictClassname(attacker, classname, sizeof(classname));
	for(new i=0;i<sizeof(doorlist);++i)
	{
		if(strcmp(classname, doorlist[i])==0)
		{
			if(GetEntPropFloat(attacker, Prop_Data, "m_flBlockDamage") == 0.0)
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}