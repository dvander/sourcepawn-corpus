#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1.4"

#define PLUGIN_CONFIG "cfg/sourcemod/plugin.tfbotchangeclass.cfg"

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "TFBots Change Class",
	author = "EfeDursun125",
	description = "TFBots now changing classes.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

new Handle:BotChangeClassChance;

public OnPluginStart()
{
	HookEvent("player_spawn", BotSpawn, EventHookMode_Post);
	BotChangeClassChance = CreateConVar("tf_bot_change_class_chance", "40", "", FCVAR_NONE, true, 0.0, false, _);
}

public OnMapStart()
{
	ServerCommand("sm_cvar tf_bot_reevaluate_class_in_spawnroom 0");
	ServerCommand("sm_cvar tf_bot_keep_class_after_death 1");
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client) && TF2_GetPlayerClass(client) != TFClass_Engineer)
			{
				float Timer;
				
				if(Timer < GetGameTime())
				{
					int sentry = TF2_GetObject(client, TFObject_Sentry, TFObjectMode_None);
					int dispenser = TF2_GetObject(client, TFObject_Dispenser, TFObjectMode_None);
					int teleporterenter = TF2_GetObject(client, TFObject_Teleporter, TFObjectMode_Entrance);
					int teleporterexit = TF2_GetObject(client, TFObject_Teleporter, TFObjectMode_Exit);
					
					if(IsValidEdict(sentry) && IsValidEntity(sentry))
					{
						RemoveEdict(sentry);
					}
					
					if(IsValidEdict(dispenser) && IsValidEntity(dispenser))
					{
						RemoveEdict(dispenser);
					}
					
					if(IsValidEdict(teleporterenter) && IsValidEntity(teleporterenter))
					{
						RemoveEdict(teleporterenter);
					}
					
					if(IsValidEdict(teleporterexit) && IsValidEntity(teleporterexit))
					{
						RemoveEdict(teleporterexit);
					}
					
					Timer = GetGameTime() + 5.0;
				}
			}
		}
	}
}

public Action:BotSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new botid = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(botid);
	
	if(IsFakeClient(botid))
	{
		if(IsPlayerAlive(botid))
		{
			new changeclass = GetRandomInt(1, 100);
			if(changeclass <= GetConVarInt(BotChangeClassChance))
			{
				if(GameRules_GetProp("m_bPlayingMannVsMachine"))
				{
					if(team == 2)
					{
						new random = GetRandomInt(1,6);
						switch(random)
						{
							case 1:
				    		{
			    				TF2_SetPlayerClass(botid, TFClass_Scout);
							}
							case 2:
			    			{
			    				TF2_SetPlayerClass(botid, TFClass_Soldier);
							}
							case 3:
			   			 	{
			    				TF2_SetPlayerClass(botid, TFClass_Pyro);
							}
							case 4:
			    			{
			    				TF2_SetPlayerClass(botid, TFClass_DemoMan);
							}
							case 5:
			    			{
			    				TF2_SetPlayerClass(botid, TFClass_Heavy);
							}
							case 6:
			   				{
			    				TF2_SetPlayerClass(botid, TFClass_Medic);
							}
						}
					}
					if(IsValidClient(botid) && team == 2)
					{
						TF2_RespawnPlayer(botid);
					}
				}
				else
				{
					new random = GetRandomInt(1,9);
					switch(random)
					{
						case 1:
			    		{
			    			TF2_SetPlayerClass(botid, TFClass_Scout);
						}
						case 2:
			    		{
			    			TF2_SetPlayerClass(botid, TFClass_Soldier);
						}
						case 3:
			   		 	{
			    			TF2_SetPlayerClass(botid, TFClass_Pyro);
						}
						case 4:
			    		{
			    			TF2_SetPlayerClass(botid, TFClass_DemoMan);
						}
						case 5:
			    		{
			    			TF2_SetPlayerClass(botid, TFClass_Heavy);
						}
						case 6:
			 	  		{
			    			TF2_SetPlayerClass(botid, TFClass_Engineer);
						}
						case 7:
			   			{
			    			TF2_SetPlayerClass(botid, TFClass_Medic);
						}
						case 8:
			   			{
			  		  		TF2_SetPlayerClass(botid, TFClass_Sniper);
						}
						case 9:
			  	 		{
			    			TF2_SetPlayerClass(botid, TFClass_Spy);
						}
					}
					if(IsValidClient(botid))
					{
						TF2_RespawnPlayer(botid);
					}
				}
			}
		}
	}
}

stock int TF2_GetObject(int client, TFObjectType type, TFObjectMode mode)
{
	int iObject = INVALID_ENT_REFERENCE;
	while ((iObject = FindEntityByClassname(iObject, "obj_*")) != -1)
	{
		TFObjectType iObjType = TF2_GetObjectType(iObject);
		TFObjectMode iObjMode = TF2_GetObjectMode(iObject);
		
		if(GetEntPropEnt(iObject, Prop_Send, "m_hBuilder") == client && iObjType == type && iObjMode == mode 
		&& !GetEntProp(iObject, Prop_Send, "m_bPlacing")
		&& !GetEntProp(iObject, Prop_Send, "m_bDisposableBuilding"))
		{			
			return iObject;
		}
	}
	
	return iObject;
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}
  