/*

	OLAF THE SNOWMAN
	
	"abilityX"
	{
		"name"	"special_olaf"
		"arg1"	"5.0"// Wet Duration (from melee hit)
		"arg2"	"2.5"// How many seconds to be frozen
		"plugin_name""ff2_olaf"
	}
	
	ELSA THE SNOW QUEEN
	"ability5"
	{
		"name" "special_elsa"
		"arg1"	"1" 	// 1: AMS 0: E rage?
		"arg2"	"10.0" 	// Freeze Duration
		"arg3"	"2000.0" // Distance
		"arg4"	"50.0"	// Scale Rate
		"arg5"	"1"		// Affect projectiles?
		
        // args reserved for the ability management system, if configured to be used with AMS.
        "arg1001"    "30.0" // delay before first use
        "arg1002"    "15.0" // cooldown
        "arg1003"    "Full Freeze" // name
        "arg1004"    "Freeze nearby players and projectiles!" // description
        "arg1005"    "100" // rage cost
        "arg1006"    "1" // index for ability in the AMS menu
        "plugin_name"    "ff2_frozen"
	}
*/


#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

public Plugin myinfo = {
	name = "Freak Fortress 2: Frozen Abilities for Elsa and Olaf",
	author = "SHADoWNiNETR3S",
	version = "1.1",
};

#define OLAF "special_olaf"
#define ELSA "special_elsa"

#define MaxEntities 2048
bool IsPlayerFrozen[MAXPLAYERS+1]=false;
float UnFreezePlayerAt[MAXPLAYERS+1]=0.0;
bool FreezePlayers_CanUse[MAXPLAYERS+1]=false;
bool FreezeProjectiles_CanUse[MAXPLAYERS+1]=false;
float StartFreezeProcess[MAXPLAYERS+1]=0.0;
bool Freeze_AMS[MAXPLAYERS+1]=false;

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart);
	if(FF2_GetRoundState()==1)
	{
		HookDamageAndAbilities();
	}
}


public void Event_RoundStart(Event event, const char[] name,  bool dontBroadcast)
{
	HookDamageAndAbilities();
}

void HookDamageAndAbilities()
{
	for(int client=1;client<=MaxClients;client++)
	{
		if(!IsValidClient(client))
			continue;
			
		Freeze_AMS[client]=false;
		IsPlayerFrozen[client]=false;
		StartFreezeProcess[client]=0.0;
		FreezePlayers_CanUse[client]=false;
		FreezeProjectiles_CanUse[client]=false;
		
		int boss=FF2_GetBossIndex(client);
		if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, OLAF))
		{
			HookUserMessage(GetUserMessageId("PlayerJarated"), Event_Wet);
			for(int player=1;player<=MaxClients;player++)
			{
				if(!IsValidClient(player))
					continue;
				SDKHook(player, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, ELSA))
		{
			FreezePlayers_CanUse[client]=true;
			Freeze_AMS[client]=view_as<bool>(FF2_GetAbilityArgument(boss, this_plugin_name, ELSA, 1));
			if(Freeze_AMS[client])
			{
				AMS_InitSubability(boss, client, this_plugin_name, ELSA, "FRZ");
			}
		}
	}
}

public Action Event_Wet(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int client = BfReadByte(msg);
	int victim = BfReadByte(msg);

	int boss=FF2_GetBossIndex(client);
	
	if(boss>=0 && IsValidClient(victim) && FF2_HasAbility(boss, this_plugin_name, OLAF))
	{
		static bool isWet=false;
		if(!IsPlayerFrozen[victim])
		{
			if(!isWet)
			{
				isWet=true;
			}
			else
			{
				isWet=false;
				FreezeTarget(victim, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, OLAF, 2, 5.0));
				TF2_RemoveCondition(victim, TFCond_Milked);
			}
		}
		else
		{
			TF2_RemoveCondition(victim, TFCond_Milked);
		}
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{		
	int boss=FF2_GetBossIndex(attacker);
	if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, OLAF) && damage>0 && IsValidClient(client) && client!=attacker)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Milked))
		{
			TF2_RemoveCondition(client, TFCond_Milked);
			FreezeTarget(client, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, OLAF, 2, 5.0));
			return Plugin_Stop;
		}
		else
		{
			if(!IsPlayerFrozen[client])
			{
				TF2_AddCondition(client, TFCond_Milked, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, OLAF, 1, 5.0));
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool lifecheck=false)
{
    if(client<=0 || client>MaxClients) return false;
    return lifecheck ? IsClientInGame(client) && IsPlayerAlive(client) : IsClientInGame(client);
}


stock void FreezeTarget(int clientIdx, float freezetime)
{
	if(!IsPlayerFrozen[clientIdx])
	{
		int ragdoll[MAXPLAYERS+1];
		IsPlayerFrozen[clientIdx]=true;
		SetEntityMoveType(clientIdx, MOVETYPE_NONE);
		ColorizePlayer(clientIdx, {255,255,255,0});
		ragdoll[clientIdx]= CreateEntityByName("tf_ragdoll");
		if(ragdoll[clientIdx] > MaxClients && IsValidEntity(ragdoll[clientIdx]))
		{
			float flPos[3], flAng[3],flVel[3];
			GetClientAbsOrigin(clientIdx, flPos);
			GetClientAbsAngles(clientIdx, flAng);
		
			TeleportEntity(ragdoll[clientIdx], flPos, flAng, flVel);
		
			SetEntProp(ragdoll[clientIdx], Prop_Send, "m_iPlayerIndex", clientIdx);
			SetEntProp(ragdoll[clientIdx], Prop_Send, "m_bIceRagdoll", 1);
			SetEntProp(ragdoll[clientIdx], Prop_Send, "m_iTeam", GetClientTeam(clientIdx));
			SetEntProp(ragdoll[clientIdx], Prop_Send, "m_iClass", (view_as<int>(TF2_GetPlayerClass(clientIdx))));
			SetEntProp(ragdoll[clientIdx], Prop_Send, "m_bOnGround", 1);
			SetEntPropFloat(ragdoll[clientIdx], Prop_Send, "m_flHeadScale", 1.0);
			SetEntPropFloat(ragdoll[clientIdx], Prop_Send, "m_flTorsoScale", 1.0);
			SetEntPropFloat(ragdoll[clientIdx], Prop_Send, "m_flHandScale", 1.0);  
			SetEntityMoveType(ragdoll[clientIdx], MOVETYPE_NONE);
		
			DispatchSpawn(ragdoll[clientIdx]);
			ActivateEntity(ragdoll[clientIdx]);
	
			SetClientViewEntity(clientIdx, ragdoll[clientIdx]);
			SetThirdPerson(clientIdx, true);
	
			CreateTimer(freezetime, Timer_DeleteParticle, EntIndexToEntRef(ragdoll[clientIdx]));
			
			UnFreezePlayerAt[clientIdx]=GetEngineTime()+freezetime;
		
			for(int slot=0;slot<=5;slot++)
			{
				int weapon=GetPlayerWeaponSlot(clientIdx, slot);
				if(weapon && IsValidEdict(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+freezetime);
				}
			}
			SetEntPropFloat(clientIdx, Prop_Send, "m_flNextAttack", GetGameTime()+freezetime);
			if(TF2_GetPlayerClass(clientIdx)==TFClass_Spy)
			{
				SetEntPropFloat(clientIdx, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+freezetime);
			}
			
			if(GetEntProp(clientIdx, Prop_Send, "m_bGlowEnabled"))
			{
				SetEntProp(clientIdx, Prop_Send, "m_bGlowEnabled", 0);
			}
			
			SDKHook(clientIdx, SDKHook_PreThink, UnfreezeTime_PreThink);
		}
	}
}

public void UnfreezeTime_PreThink(int clientIdx)
{
	if(!IsValidClient(clientIdx, true) || FF2_GetRoundState()!=1)
	{
		UnFreezePlayerAt[clientIdx]=0.0;
		IsPlayerFrozen[clientIdx]=false;
		UnFreezePlayer(clientIdx);
		SDKUnhook(clientIdx, SDKHook_PreThink, UnfreezeTime_PreThink);
	}
	
	if((GetEngineTime() >= UnFreezePlayerAt[clientIdx]) && UnFreezePlayerAt[clientIdx]>0.0)
	{
		UnFreezePlayerAt[clientIdx]=0.0;
		IsPlayerFrozen[clientIdx]=false;
		UnFreezePlayer(clientIdx);
		SDKUnhook(clientIdx, SDKHook_PreThink, UnfreezeTime_PreThink);
	}
}

public void UnFreezePlayer(int clientIdx)
{
	SetClientViewEntity(clientIdx, clientIdx);
	SetEntityMoveType(clientIdx, MOVETYPE_WALK);
	ColorizePlayer(clientIdx, {255,255,255,255});
	SetThirdPerson(clientIdx, false);
}

public void SetThirdPerson(int clientIdx, bool bEnabled)
{
	if(bEnabled)
	{
		SetVariantInt(1);
	}else{
		SetVariantInt(0);
	}
	AcceptEntityInput(clientIdx, "SetForcedTauntCam");
}

public void SetEntityColor(int entity, int color[4])
{
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, color[0], color[1], color[2], color[3]);
}

public void ColorizePlayer(int clientIdx, int color[4])
{
	SetEntityColor(clientIdx, color);
	for(int i=0; i<5; i++)
	{
		int weapon = GetPlayerWeaponSlot(clientIdx, i);
		if(weapon && IsValidEdict(weapon))
		{
			SetEntityColor(weapon, color);
		}
	}
	
	int entity;
	while((entity=FindEntityByClassname(entity, "tf_wearable"))!=-1 || (entity=FindEntityByClassname(entity, "tf_powerup_bottle"))!=-1 || (entity=FindEntityByClassname(entity, "tf_wearable_demoshield"))!=-1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==clientIdx)
		{
			SetEntityColor(entity, color);
		}
	}

	int weapon = GetEntPropEnt(clientIdx, Prop_Send, "m_hDisguiseWeapon");
	if(weapon > MaxClients && IsValidEntity(weapon))
	{
		SetEntityColor(weapon, color);
	}
}

public Action Timer_DeleteParticle(Handle hTimer, any entref)
{
	int entity = EntRefToEntIndex(entref);
	if(entity > MaxClients)
	{
		AcceptEntityInput(entity, "Kill");
	}
	return Plugin_Handled;
}

stock bool IsProjectile(int entity)
{
	if(IsValidEntity(entity))
	{
		char classname[256];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!StrContains(classname, "tf_projectile_", false)) return true;
		return false;
	}
	return false;
}

stock int GetEntOwner(int entity)
{
	int owner=0;
	if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0)
	{
		return owner;
	}
	return 0;
}

public void FF2_OnAbility2(int bossIdx,const char[] plugin_name,const char[] ability_name,int action)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
		return;
	int clientIdx=GetClientOfUserId(FF2_GetBossUserId(bossIdx));
	if(!StrContains(ability_name, ELSA) && !Freeze_AMS[clientIdx])
	{
		FRZ_Invoke(clientIdx);
	}
}

public bool FRZ_CanInvoke(int client)
{
	return true;
}

public void FRZ_Invoke(int clientIdx)
{
	SDKHook(clientIdx, SDKHook_PreThink,  Freeze_PreThink);
	StartFreezeProcess[clientIdx]=GetEngineTime()+0.6;
}

public void Freeze_PreThink(int clientIdx)
{
	if(FF2_GetRoundState()!=1 || !IsValidClient(clientIdx, true)) // Round ended or defeated?
	{
		SDKUnhook(clientIdx, SDKHook_PreThink, Freeze_PreThink);
	}

	int bossIdx=FF2_GetBossIndex(clientIdx);
	if(FreezePlayers_CanUse[clientIdx] && StartFreezeProcess[clientIdx]>0.0)
	{
		StartFreeze(clientIdx, bossIdx, GetEngineTime());
	}
}

void StartFreeze(int clientIdx, int bossIdx, float gTime)
{
	if(gTime >= StartFreezeProcess[clientIdx])
	{
		float pos[3], pos2[3], pos3[3], dist;
		static float ragedist[MAXPLAYERS+1]=0.0;
		static float time[MAXPLAYERS+1]=0.0;
		static float maxdist[MAXPLAYERS+1]=0.0;
	
		if(!time[clientIdx] && !maxdist[clientIdx])
		{
			time[clientIdx]=FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ELSA, 2, 5.0);
			maxdist[clientIdx]=FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ELSA, 3, FF2_GetRageDist(bossIdx, this_plugin_name, ELSA));
		}
	
		if(ragedist[clientIdx]>=maxdist[clientIdx])
		{
			time[clientIdx]=0.0;
			maxdist[clientIdx]=0.0;
			ragedist[clientIdx]=0.0;
			StartFreezeProcess[clientIdx]=0.0;
			return;
		}
		
		ragedist[clientIdx]+=FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ELSA, 4, 50.0);
	
		GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", pos);
		for(int targetIdx=1; targetIdx<=MaxClients; targetIdx++)
		{
			if(IsValidClient(targetIdx, true) && !IsPlayerFrozen[targetIdx] && GetClientTeam(targetIdx)!= FF2_GetBossTeam())
			{
				GetEntPropVector(targetIdx, Prop_Send, "m_vecOrigin", pos2);
				dist=GetVectorDistance(pos,pos2);
				if (dist<ragedist[clientIdx] && GetClientTeam(targetIdx)!=FF2_GetBossTeam())
				{
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_UberBulletResist)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_BulletImmune)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_UberBlastResist)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_BlastImmune)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_UberFireResist)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_FireImmune)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_Ubercharged)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_UberchargedHidden)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_Stealthed)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_StealthedUserBuffFade)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_Cloaked)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_DeadRingered)) continue;
					if(TF2_IsPlayerInCondition(targetIdx, TFCond_UberchargedCanteen)) continue;			
					TF2_AddCondition(targetIdx, TFCond_UberchargedHidden, 3.0);
					FreezeTarget(targetIdx, time[clientIdx]);
				}	
			}
		}
		
		if(FF2_GetAbilityArgument(bossIdx, this_plugin_name, ELSA, 5))
		{
			for(int entity=MaxClients+1; entity<MaxEntities; entity++)
			{
				if(IsProjectile(entity))
				{
				
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos3);
					dist=GetVectorDistance(pos,pos3);
					if (dist<ragedist[clientIdx] &&  IsValidClient(GetEntOwner(entity)) && GetClientTeam(GetEntOwner(entity))!=FF2_GetBossTeam() && GetEntityMoveType(entity)!=MOVETYPE_NONE) 
					{
						SetEntityMoveType(entity, MOVETYPE_NONE);

						char modelname[PLATFORM_MAX_PATH];
						GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
						if(modelname[0] && FileExists(modelname, true))
						{
							if(!IsModelPrecached(modelname))
							{
								PrecacheModel(modelname);
							}
		
							int prop=CreateEntityByName("prop_physics_override");
							if(IsValidEntity(prop))
							{
								SetEntityModel(prop, modelname);
								SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
								SetEntProp(prop, Prop_Send, "m_CollisionGroup", 1);
								SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16);
								DispatchSpawn(prop);

								float position[3], angles[3];
								GetEntPropVector(entity, Prop_Data, "m_angRotation", angles);  
								GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
								TeleportEntity(prop, position, angles, NULL_VECTOR);

								CreateTimer(time[clientIdx], Timer_DeleteProp, prop, TIMER_FLAG_NO_MAPCHANGE);
							}
							AcceptEntityInput(entity, "kill");
						}
					}
				}
			}
		}
		StartFreezeProcess[clientIdx]+=0.1;
	}
}

public Action Timer_DeleteProp(Handle timer, any entity)
{
	if(!IsValidEntity(entity))
		return Plugin_Stop;
		
	AcceptEntityInput(entity, "kill");
	return Plugin_Continue;
}

// call AMS from epic scout's subplugin via reflection:
stock Handle FindPlugin(char[] pluginName)
{
	char buffer[256];
	char path[PLATFORM_MAX_PATH];
	Handle iter = GetPluginIterator();
	Handle pl = null;
	
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		Format(path, sizeof(path), "%s.ff2", pluginName);
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (StrContains(buffer, path, false) >= 0)
			break;
		else
			pl = null;
	}
	
	delete iter;

	return pl;
}

// this will tell AMS that the abilities listed on PrepareAbilities() supports AMS
stock void AMS_InitSubability(int bossIdx, int clientIdx, const char[] pluginName, const char[] abilityName, const char[] prefix)
{
	Handle plugin = FindPlugin("ff2_sarysapub3");
	if (plugin != null)
	{
		Function func = GetFunctionByName(plugin, "AMS_InitSubability");
		if (func != INVALID_FUNCTION)
		{
			
			Call_StartFunction(plugin, func);
			Call_PushCell(bossIdx);
			Call_PushCell(clientIdx);
			Call_PushString(pluginName);
			Call_PushString(abilityName);
			Call_PushString(prefix);
			Call_Finish();
		}
		else
			LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability()");
	}
	else
		LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability(). Make sure this plugin exists!");

}