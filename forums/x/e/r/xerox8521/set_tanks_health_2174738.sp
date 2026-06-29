#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define TEAM_ZOMBIES		3

#define ZC_TANK	 8

#define VERSION "1.0"

new Handle: g_hZTankHealth = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Set Tanks Health L4D2",
	author = "XeroX",
	description = "Sets the health of a Tank",
	version = VERSION,
	url = "http://sammys-zps.com"
}

public OnPluginStart()
{
	HookEvent("player_spawn",Event_PlayerSpawn);
	
	g_hZTankHealth = FindConVar("z_tank_health");
	if(!g_hZTankHealth) SetFailState("z_tank_health could not be found");
	
	HookConVarChange(g_hZTankHealth,TankHealthChanged);
}

public TankHealthChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar != INVALID_HANDLE)
	{
		new old = StringToInt(oldVal);
		new _new = StringToInt(newVal);
		if(old != _new)
		{
			for(new i=1; i<GetMaxClients(); i++)
			{
				if(IsClientConnected(i))
				{
					if(IsClientInGame(i))
					{
						if(IsPlayerAlive(i))
						{
							if(GetClientTeam(i) == TEAM_ZOMBIES)
							{
								if(GetEntProp(i,Prop_Send,"m_zombieClass") == ZC_TANK)
								{
									SetMaxHealth(i,_new,false);
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(GetClientTeam(client) == TEAM_ZOMBIES)
	{
		if(GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK)
		{
			SetMaxHealth(client,GetConVarInt(g_hZTankHealth),true); 
		}
	}
}

// Sets Max Health and current health to amount
// if you pass false it will only set the tanks Max Health to amount while keeping his current health
stock SetMaxHealth(client, amount, bool:heal)
{
	if(amount >= 1)
	{
		SetEntProp(client,Prop_Send,"m_iMaxHealth",amount);
	}
	if(heal)
	{
		SetEntityHealth(client,amount);
	}
}
