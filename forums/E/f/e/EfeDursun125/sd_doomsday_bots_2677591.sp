#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2_flag>
#include <PathFollower>

#pragma newdecls optional

public Plugin:myinfo=
{
	name= "TFBots on sd_doomsday",
	author= "EfeDursun125",
	description= "Allows Bots to play in sd_doomsday map.",
	version= "1.3",
	url= "http://steamcommunity.com/profiles/76561198039186809"
}

float g_flGoal[MAXPLAYERS + 1][3];

public OnPluginStart()
{
	HookEvent("teamplay_round_start", RoundStarted);
}

public OnMapStart()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if(StrContains(currentMap, "sd_doomsday" , false) != -1)
	{
		CreateTimer(0.1, MoveTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.1, FindFlag,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:OnFlagTouch(point, client)
{
	for(client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:RoundStarted(Handle: event , const String: name[] , bool: dontBroadcast)
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if(StrContains(currentMap, "sd_doomsday" , false) != -1)
	{
		CreateTimer(0.1, LoadStuff);
		CreateTimer(0.1, LoadStuff2);
		CreateTimer(0.1, LoadStuff3);
	}
}

public Action:LoadStuff(Handle:timer)
{
	decl String:nameblue[] = "bluebotflag";
	decl String:classblue[] = "item_teamflag";
	new ent = FindEntityByTargetname(nameblue, classblue);
	if(ent != -1)
	{
		//Do nothing.
	}
	else
	{
		new teamflags = CreateEntityByName("item_teamflag");
		if(IsValidEntity(teamflags))
		{
			DispatchKeyValue(teamflags, "targetname", "bluebotflag");
			DispatchKeyValue(teamflags, "trail_effect", "0");
			DispatchKeyValue(teamflags, "ReturnTime", "1");
			DispatchKeyValue(teamflags, "flag_model", "models/empty.mdl");
			DispatchSpawn(teamflags);
			SetEntProp(teamflags, Prop_Send, "m_iTeamNum", 3);
		}
	}
}

public Action:LoadStuff2(Handle:timer)
{
	decl String:namered[] = "redbotflag";
	decl String:classred[] = "item_teamflag";
	new ent = FindEntityByTargetname(namered, classred);
	if(ent != -1)
	{
		//Do nothing.
	}
	else
	{
		new teamflags2 = CreateEntityByName("item_teamflag");
		if(IsValidEntity(teamflags2))
		{
			DispatchKeyValue(teamflags2, "targetname", "redbotflag");
			DispatchKeyValue(teamflags2, "trail_effect", "0");
			DispatchKeyValue(teamflags2, "ReturnTime", "1");
			DispatchKeyValue(teamflags2, "flag_model", "models/empty.mdl");
			DispatchSpawn(teamflags2);
			SetEntProp(teamflags2, Prop_Send, "m_iTeamNum", 2);
		}
	}
}

public Action:LoadStuff3(Handle:timer)
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if(StrContains(currentMap, "sd_doomsday" , false) != -1)
	{
		new snipepos = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos, "team", "0");
		new snipepos2 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos2, "team", "0");
		new snipepos3 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos3, "team", "2");
		new snipepos4 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos4, "team", "3");
		new cpred = CreateEntityByName("func_capturezone");
		DispatchKeyValue(cpred, "team", "2");
		new cpblu = CreateEntityByName("func_capturezone");
		DispatchKeyValue(cpblu, "team", "3");

		new Float:origin[3] = {-826.0, 727.0, 410.0};
		new Float:origin2[3] = {-1216.0, 725.0, 410.0};
		new Float:origin3[3] = {-1663.0, 3479.0, 197.0};
		new Float:origin4[3] = {-434.0, 3469.0, 197.0};
		
		new Float:origincp[3] = {-1024.0, 1077.0, 1333.0};

		TeleportEntity(snipepos, origin, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos2, origin2, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos3, origin3, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos4, origin4, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(cpblu, origincp, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(cpred, origincp, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:FindFlag(Handle:timer)
{
	decl String:namered[] = "redbotflag";
	decl String:classred[] = "item_teamflag";
	decl String:nameblue[] = "bluebotflag";
	decl String:classblue[] = "item_teamflag";
	
	new ent = FindEntityByTargetname(nameblue, classblue);
	new ent2 = FindEntityByTargetname(namered, classred);
	
	if(ent != -1)
	{
		SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent, SDKHook_Touch, OnFlagTouch );
	}
	
	if(ent2 != -1)
	{
		SDKHook(ent2, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent2, SDKHook_Touch, OnFlagTouch );
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				char currentMap[PLATFORM_MAX_PATH];
				GetCurrentMap(currentMap, sizeof(currentMap));

				if(StrContains(currentMap, "sd_doomsday" , false) != -1)
				{
					new TFClassType:class3 = TF2_GetPlayerClass(client);
					float clientOrigin[3];
					float clientEyes[3];
					GetClientAbsOrigin(client, clientOrigin);
					GetClientEyePosition(client, clientEyes);
					new CurrentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
					new MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
					
					if(TF2_HasTheFlag(client))
					{
						if (!(PF_Exists(client))) 
						{
							PF_Create(client, 48.0, 72.0, 10000.0, 600.0, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
						}
						
						float CaptureZone[3] = {-1024.0, 1077.0, 1333.0};
						
						float ClientGoal[3];
						
						ClientGoal[0] = CaptureZone[0];
						ClientGoal[1] = CaptureZone[1];
						ClientGoal[2] = clientOrigin[2];
						
						PF_SetGoalVector(client, CaptureZone);
						
						PF_StartPathing(client);
						
						PF_EnableCallback(client, PFCB_Approach, Approach);
						
						if(!IsPlayerAlive(client) || !PF_Exists(client))
							return Plugin_Continue;
						
						if(PF_Exists(client) && GetVectorDistance(clientOrigin, ClientGoal) > 75.0)
						{
							TF2_MoveTo(client, g_flGoal[client], vel, angles);
						}
					}
					
					if(CurrentHealth < MaxHealth && !TF2_HasTheFlag(client))
					{
						int healthkit = GetNearestEntity(client, "item_healthkit_*"); 
						
						if(healthkit != -1)
						{
							if(IsValidEntity(healthkit))
							{
								if (GetEntProp(healthkit, Prop_Send, "m_fEffects") != 0)
								{
									return Plugin_Continue;
								}
		
								new Float:healthkitorigin[3];
								GetEntPropVector(healthkit, Prop_Send, "m_vecOrigin", healthkitorigin);
								
								clientOrigin[2] += 5.0;
								healthkitorigin[2] += 5.0;
								
								if(IsPointVisible(clientOrigin, healthkitorigin))
								{
									TF2_MoveTo(client, healthkitorigin, vel, angles);
								}
							}
						}
					}
				
					if(class3 == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_Disguised) && IsWeaponSlotActive(client, 0))
					{
						if(buttons & IN_ATTACK)
						{
							buttons &= ~IN_ATTACK;
						}
					}
				
					if(class3 == TFClass_Spy && GetHealth(client) > 100.0 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						if(buttons & IN_ATTACK2)
						{
							buttons &= ~IN_ATTACK2;
						}
					}
					
					if(class3 == TFClass_Spy && GetHealth(client) < 75.0 && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						buttons |= IN_ATTACK2;
					}
					
					if(class3 == TFClass_Spy && GetHealth(client) < 35.0 && TF2_IsPlayerInCondition(client, TFCond_Disguising) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						buttons |= IN_ATTACK2;
					}
					
					if(class3 == TFClass_Spy && !IsWeaponSlotActive(client, 0))
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					
					if(class3 == TFClass_Spy && IsWeaponSlotActive(client, 2))
					{
						if(GetEntProp(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), Prop_Send, "m_bReadyToBackstab") && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
						{
							buttons |= IN_ATTACK;
						}
						else
						{
							if(buttons & IN_ATTACK)
							{
								buttons &= ~IN_ATTACK;
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock int GetObjTeam(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iTeamNum");
}

stock bool:IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock GetHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

public int FindNearestHealth(int client)
{
	char ClassName[32];
	float clientOrigin[3];
	float entityOrigin[3];
	float distance = -1.0;
	int nearestEntity = -1;
	for(int entity = 0; entity <= GetMaxEntities(); entity++)
	{
		if(IsValidEntity(entity))
		{
			GetEdictClassname(entity, ClassName, 32);
			
			if(!HasEntProp(entity, Prop_Send, "m_fEffects"))
				continue;
			
			if(GetEntProp(entity, Prop_Send, "m_fEffects") != 0)
				continue;
				
			if(StrContains(ClassName, "item_health", false) != -1 || StrContains(ClassName, "obj_dispenser", false) != -1 || StrContains(ClassName, "func_regen", false) != -1)
			{
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
				GetClientEyePosition(client, clientOrigin);
				
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					nearestEntity = entity;
				}
			}
		}
	}
	return nearestEntity;
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

public Action:MoveTimer(Handle:timer)
{
	decl String:namered[] = "redbotflag";
	decl String:classred[] = "item_teamflag";
	decl String:nameblue[] = "bluebotflag";
	decl String:classblue[] = "item_teamflag";
	
	new ent = FindEntityByTargetname(nameblue, classblue);
	new ent2 = FindEntityByTargetname(namered, classred);
	
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if(StrContains(currentMap, "sd_doomsday" , false) != -1)
	{
		new Float:GoalPos[3] = {-1024.0, 1077.0, 1333.0};
		
		new flag;
		while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
		{
			new iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
			if(IsValidEntity(flag) && flag != ent && flag != ent2)
			{
				new Float:flagorigin[3];
				new Float:flagdefendorigin[3];
				GetEntPropVector(flag, Prop_Data, "m_vecAbsOrigin", flagorigin);
				GetEntPropVector(flag, Prop_Data, "m_vecAbsOrigin", flagdefendorigin);
				
				flagdefendorigin[0] += GetRandomFloat(-1000.0, 1000.0);
				flagdefendorigin[1] += GetRandomFloat(-1000.0, 1000.0);
				
				int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
				
				if(FlagStatus == 0)
				{
					TeleportEntity(ent, flagorigin, NULL_VECTOR, NULL_VECTOR);
					TeleportEntity(ent2, flagorigin, NULL_VECTOR, NULL_VECTOR);
				}
				
				if(FlagStatus == 1)
				{
					if(iTeamNumObj == 2)
					{
						TeleportEntity(ent, GoalPos, NULL_VECTOR, NULL_VECTOR);
						TeleportEntity(ent2, flagorigin, NULL_VECTOR, NULL_VECTOR);
					}
					
					if(iTeamNumObj == 3)
					{
						TeleportEntity(ent, flagorigin, NULL_VECTOR, NULL_VECTOR);
						TeleportEntity(ent2, GoalPos, NULL_VECTOR, NULL_VECTOR);
					}
				}
				
				if(FlagStatus == 2)
				{
					if(iTeamNumObj == 2)
					{
						TeleportEntity(ent, flagorigin, NULL_VECTOR, NULL_VECTOR);
						TeleportEntity(ent2, flagdefendorigin, NULL_VECTOR, NULL_VECTOR);
					}
					
					if(iTeamNumObj == 3)
					{
						TeleportEntity(ent, flagdefendorigin, NULL_VECTOR, NULL_VECTOR);
						TeleportEntity(ent2, flagorigin, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
	}
}

stock int TF2_GetNumHealers(int client)
{
    return GetEntProp(client, Prop_Send, "m_nNumHealers");
}

public int GetNearestEntity(int client, char[] classname) // https://forums.alliedmods.net/showthread.php?t=318542
{
    int nearestEntity = -1;
    float clientVecOrigin[3], entityVecOrigin[3];
    
    //Get the distance between the first entity and client
    float distance, nearestDistance = -1.0;
    
    //Find all the entity and compare the distances
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, classname)) != -1)
    {
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityVecOrigin);
        distance = GetVectorDistance(clientVecOrigin, entityVecOrigin);
        
        if (distance < nearestDistance || nearestDistance == -1.0)
        {
            nearestEntity = entity;
            nearestDistance = distance;
        }
    }
    
    return nearestEntity;
}

stock void TF2_MoveTo(int client, float flGoal[3], float fVel[3], float fAng[3])
{
    float flPos[3];
    GetClientAbsOrigin(client, flPos);

    float newmove[3];
    SubtractVectors(flGoal, flPos, newmove);
    
    newmove[1] = -newmove[1];
    
    float sin = Sine(fAng[1] * FLOAT_PI / 180.0);
    float cos = Cosine(fAng[1] * FLOAT_PI / 180.0);                        
    
    fVel[0] = cos * newmove[0] - sin * newmove[1];
    fVel[1] = sin * newmove[0] + cos * newmove[1];
    
    NormalizeVector(fVel, fVel);
    ScaleVector(fVel, 450.0);
}

public void Approach(int bot_entidx, const float dst[3])
{
    g_flGoal[bot_entidx][0] = dst[0];
    g_flGoal[bot_entidx][1] = dst[1];
    g_flGoal[bot_entidx][2] = dst[2];
}

stock bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.99;
}

public bool:TraceEntityFilterStuff(entity, mask)
{
	return entity > MaxClients;
}

stock FindEntityByTargetname(const String:targetname[], const String:classname[])
{
  decl String:namebuf[32];
  new index = -1;
  namebuf[0] = '\0';
 
  while(strcmp(namebuf, targetname) != 0
    && (index = FindEntityByClassname(index, classname)) != -1)
    GetEntPropString(index, Prop_Data, "m_iName", namebuf, sizeof(namebuf));
 
  return(index);
}