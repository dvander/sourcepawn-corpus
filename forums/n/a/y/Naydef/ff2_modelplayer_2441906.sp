/*
Ability prototype in the config:

"ability1"
{
	"name" "modelplayer_ability"                           // Ability name
	
	"arg0" "1"                                             // Ability slot
	"arg1" "models/freak_fortress_2/blightcaller/sth.mdl"  // Model path | N.B.!-> Full model path(includes models/)
	"arg2" "10"                                            // How much time to freeze
	"arg3" "1"                                             // Force file check and precaches the model - For debugging purprose
	"arg4" "2.0"                                           // Model scaling - Experimental
	"arg5" "0"                                             // Solid type
	"arg6" "0"                                             // Collision Group
	"arg7" "255"                                           // Colour R
	"arg8" "255"                                           // Colour G
	"arg9" "255"                                           // Colour B
	"arg10" "255"                                          // Colour A
	"arg11" "0.0"                                          // Rage Distance | N.B.!-> 0.0 - All alive players will be affected | -1.0 - The "ragedist" arg will be used as a distance!
	"arg12" "0"                                            // Movetype
	"arg13" "0"                                            // Unused - Wait in future version
	
	"plugin_name" "ff2_modelplayer"                        // Unimportant
}

*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <sdktools>

#define PLUGIN_VERSION "0.3.0"
#define ABILITY_NAME1 "modelplayer_ability"


//Variables
new iAssocProp[MAXPLAYERS+1]={-1, ...};
new MoveType:iPrevCollision[MAXPLAYERS+1]={MOVETYPE_WALK, ...};

public Plugin:myinfo =
{
	name = "Freak Fortress 2: ModelAbility",
	author = "Naydef",
	description = "Hard to explain currently",
	version = PLUGIN_VERSION,
	url = "***",
};


public OnPluginStart2()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], action)
{
	if(StrEqual(ability_name, ABILITY_NAME1, false) && boss!=-1)
	{
		Debug("Client: %N | Step1", GetClientOfUserId(FF2_GetBossUserId(boss)));
		RageBoss(GetClientOfUserId(FF2_GetBossUserId(boss)));
	}
}

public RageBoss(client)
{
	Debug("Step2");
	new String:model[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1 , 1, model, sizeof(model));
	Debug("Step2");
	if(FF2_GetAbilityArgument(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1, 3, 0))
	{
		if(!FileExists(model, true))
		{
			LogError("[FF2 Ability] Cannot find model: %s", model);
			return;
		}
		Debug("Good!");
		PrecacheModel(model); // Prevent crashes!
	}
	Debug("Step4");
	new rgba[4];
	new Float:modelscale=FF2_GetAbilityArgumentFloat(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1 , 4, 1.0);
	new collisiongroup=FF2_GetAbilityArgument(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1 , 6, 0);
	new movetype=FF2_GetAbilityArgument(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1 , 12, 0);
	new Float:distance=FF2_GetAbilityArgumentFloat(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1 , 11, 1.0);
	rgba[0]=FF2_GetAbilityArgument(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1 , 7, 255);
	rgba[1]=FF2_GetAbilityArgument(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1 , 8, 255);
	rgba[2]=FF2_GetAbilityArgument(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1 , 9, 255);
	rgba[3]=FF2_GetAbilityArgument(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1 , 10, 255);
	Debug("Step5: %f", distance);
	if(distance==-1.0)
	{
		distance=FF2_GetRageDist(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1);
		Debug("Step6 %f", distance);
	}
	new Float:bossPosition[3], Float:clientPosition[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && !IsBoss(i))
		{
			Debug("Step7 Client: %N", i);
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", clientPosition);
			if(GetVectorDistance(bossPosition, clientPosition)<=distance || distance==0.0)
			{
				Debug("Step8 Client: %N", i);
				iAssocProp[i]=BuryPlayer(i, model, movetype, collisiongroup, rgba, modelscale);
				iPrevCollision[i]=GetEntityMoveType(i);
				SetEntityMoveType(i, MOVETYPE_NONE);
			}
		}
	}
	CreateTimer(FF2_GetAbilityArgumentFloat(FF2_GetBossIndex(client), this_plugin_name, ABILITY_NAME1 , 2, 0.0), Timer_EndAbility, _, TIMER_FLAG_NO_MAPCHANGE);
}


public Action:Timer_EndAbility(Handle:htimer)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && !IsBoss(i) && IsValidEntity(iAssocProp[i]))
		{
			AcceptEntityInput(iAssocProp[i], "Kill");
			SetEntityMoveType(i, iPrevCollision[i]);
			iAssocProp[i]=-1;
		}
		else
		{
			iPrevCollision[i]=MOVETYPE_WALK; // Reset
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	if(!IsBoss(client) && iAssocProp[client]!=0 && IsValidEntity(iAssocProp[client])) // Double check iAssocProp in order to prevent server crashes, because it deletes the worldspawn(0)
	{
		AcceptEntityInput(iAssocProp[client], "Kill");
		iAssocProp[client]=-1;
		iPrevCollision[client]=MOVETYPE_WALK; // Reset
		//Anything else needed?
	}
	return Plugin_Continue;
}


//Stocks
bool:IsValidClient(client, bool:replaycheck=true) // From Freak Fortress 2
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}

bool:IsBoss(client)
{
	return (FF2_GetBossIndex(client)!=-1) ? true : false;
}

BuryPlayer(client, const String:modelname[], movetype, collisiongroup, rgba[4], Float:modelscaling)
{
	new entity=CreateEntityByName("prop_dynamic_override");
	if(!IsValidEntity(entity))
	{
		return -1;
	}
	DispatchKeyValue(entity, "model", modelname);
	DispatchKeyValueFloat(entity, "modelscale", modelscaling);
	SetEntityMoveType(entity, MoveType:movetype);
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", collisiongroup);
	DispatchSpawn(entity);
	SetEntityRenderColor(entity, rgba[0], rgba[1], rgba[2], rgba[3]);
	new Float:position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
	return entity;
}