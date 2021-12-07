#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

/*
	Changelog:
	
	Version 1.1
		- Updated to transitional syntax

*/

#define VERSION "1.1"

ConVar gHCarrierAmount = null;

public Plugin myinfo = 
{
	name = "Multiple Carriers",
	author = "XeroX",
	description = "Allows Multiple Carriers similar to Hardcore Mode but the Infection stays the same",
	version = VERSION,
	url = "http://SoldiersOfDemise.com"
}

public void OnPluginStart()
{
	char ModDir[32];
	GetGameFolderName(ModDir,sizeof(ModDir));
	if(!StrEqual(ModDir,"zps",true))
	{
		SetFailState("Plugin will only work on Zombie Panic! Source");
		return;
	}
	CreateConVar("multiple_carriers_version",VERSION,"Version of the Multiple Carriers Plugin",FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_PLUGIN);
	gHCarrierAmount = CreateConVar("multiple_carriers_amount","3","How many additional carriers should spawn\nSet to 0 to Disable",FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY,true,0.0,true,20.0);
	HookEvent("player_spawn",EventPlayerSpawn);
}

public void OnMapStart()
{
	// We make sure the carrier model is loaded no matter what to prevent crashes
	PrecacheModel("models/zombies/zombie0/zombie0.mdl",true);
}


public Action EventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(event != null) // Make sure the Event exists
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		CreateTimer(3.0,SpawnEventTimer,client);
		// We use this timer to let the Server set all needed variables otherwise we will get errors
		// because they havent been set (yet)
	}
	else
	{
		SetFailState("Event: player_spawn doesnt exist");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action SpawnEventTimer(Handle timer, any client)
{
	if(timer != INVALID_HANDLE)
	{
		int maxcarriers = gHCarrierAmount.IntValue;
		int carriers;
		if(maxcarriers > 0)
		{
			int attempts;
			do
			{
				attempts++;
				int zombie = GetRandomInt(1,24);
				if(attempts < 100) // Check is needed to avoid infinite loop
				{
					if(IsClientConnected(zombie))
					{
						if(IsClientInGame(zombie))
						{
							if(!GetEntProp(zombie,Prop_Data,"m_bCarrier"))
							{
								SetEntProp(zombie,Prop_Data,"m_bCarrier",true);
								carriers++;
								
								#if defined DEBUG
								PrintToChatAll("%N has been made carrier",zombie);
								PrintToChatAll("%N | %d",zombie,GetEntProp(zombie,Prop_Data,"m_bCarrier"));
								#endif
							}
						}
					}
				}
				else
				{
					break;
				}
				
				
			}while(GetCarriers() < maxcarriers);
			#if defined DEBUG
			PrintToChatAll("maxcarriers: %d / GetCarriers(): %d",maxcarriers,GetCarriers());
			#endif
		}
	}
}


stock int GetCarriers()
{
	int amount;
	for(int i=1; i<25; i++)
	{
		if(IsClientConnected(i))
		{
			if(IsClientInGame(i))
			{
				if(GetEntProp(i,Prop_Data,"m_bCarrier"))
				{
					amount++;
				}
			}
		}
	}
	return amount;
}