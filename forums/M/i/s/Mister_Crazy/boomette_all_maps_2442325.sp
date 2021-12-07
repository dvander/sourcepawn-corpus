#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

#define TEAM_INFECTED  3

#define ZOMBIECLASS_BOOMER	2

#define MODEL_BOOMER1   "models/infected/boomer.mdl" 
#define MODEL_BOOMER2   "models/infected/boomette.mdl" 
#define MODEL_EXPGIRL   "models/infected/limbs/exploded_boomette.mdl" 

public Plugin:myinfo = 
{
	name = "boomette_all_maps",
	author = "Mister Crazy",
	description = "Random model",
	version = PLUGIN_VERSION,
	url = "https://new.vk.com/left4deadapocalypse"
}
	
public OnPluginStart()
{		
	HookEvent("player_spawn", ePlayer_Spawn); 
}

public OnMapStart()
{	
	PrecacheModel(MODEL_BOOMER1, true);
	PrecacheModel(MODEL_BOOMER2, true);
	PrecacheModel(MODEL_EXPGIRL, true);
}

public ePlayer_Spawn(Handle:hEvent, String:sEventName[], bool:bDontBroadcast) 
{
	static iClient;
	iClient  = GetClientOfUserId(GetEventInt(hEvent, "userid"));
   
	if(iClient < 1 || iClient > MaxClients)
        return;

	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
     
	if(GetClientTeam(iClient) == 3)
	{
		switch (GetEntProp(iClient, Prop_Send, "m_zombieClass")) 
		{
			case ZOMBIECLASS_BOOMER:
			{
				switch(GetRandomInt(1,2)) 
				{
					case 1:
					{
						SetEntityModel(iClient, MODEL_BOOMER1);
					}
					case 2:
					{
						SetEntityModel(iClient, MODEL_BOOMER2);
					}															
				}
			}							
		}
	}
}	
	