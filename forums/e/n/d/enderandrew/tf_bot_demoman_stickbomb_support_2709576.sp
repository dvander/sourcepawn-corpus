#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION  "1.0"

Handle AttackTimer;
Handle AttackTimer2;
Handle AttackTimer3;
Handle AttackTimer4;
Handle AttackTimer5;
Handle AttackTimer6;

public Plugin myinfo = 
{
	name = "Demoman Stickspam Support",
	author = "Marqueritte",
	description = "Demomen StickySpams now",
	version = PLUGIN_VERSION,
};

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

float g_flNextCommand[MAXPLAYERS + 1];
stock bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 0.4;
	
	return true;
}

stock int TF2_SwitchtoSlot(int client, int slot)
{
 if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
 {
  char classname[64];
  int wep = GetPlayerWeaponSlot(client, slot);
  if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
  {
   Format(classname, sizeof(classname), "use %s", classname);
   FakeClientCommandThrottled(client, classname);
   
   // Old Method That's Bugged
   //FakeClientCommandEx(client, "use %s", classname);
   //SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
  }
 }
}  

public Action OnPlayerRunCmd(int client, int &buttons)
{
	TFClassType class = TF2_GetPlayerClass(client);
	if(class == TFClass_DemoMan && IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client))
	{
		float clientEyes[3];
		float targetEyes[3];
		float targetEyes2[3];
		float targetEyes3[3];
		float targetEyesBase[3];
		GetClientEyePosition(client, clientEyes);
		int Ent = Client_GetClosest(clientEyes, client);
		
		if(IsValidClient(Ent))
		{
			GetClientAbsOrigin(Ent, targetEyes);
			GetClientAbsOrigin(Ent, targetEyesBase);
			GetClientAbsOrigin(Ent, targetEyes3);
			GetClientEyePosition(Ent, targetEyes2);
			
			
			if(IsWeaponSlotActive(client, 1))
			{
				float location_check[3];
				GetClientAbsOrigin(client, location_check);

				float chainDistance;
				chainDistance = GetVectorDistance(location_check,targetEyes);
				
				// Sentry Gun Checker
				int sentrygun = GetNearestEntity(client, "obj_sentrygun*"); 
				float sentrygunlocation[3];
				// GetClientAbsOrigin(sentrygun, sentrygunlocation);
								
				if(!IsPointVisible(clientEyes, sentrygunlocation))
				{
					TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary); 
					
					if(chainDistance < 500 && AttackTimer == INVALID_HANDLE)
					{
						targetEyes3[2] += 50.0;
						AttackTimer = CreateTimer(0.8, ResetAttackTimer);
						buttons |= IN_ATTACK2;
					}
					if(chainDistance > 500 && chainDistance < 750 && AttackTimer2 == INVALID_HANDLE)
					{
						targetEyes3[2] += 100.0;
						AttackTimer2 = CreateTimer(1.2, ResetAttackTimer2);
						buttons |= IN_ATTACK2;
					}
					if(chainDistance > 750 && chainDistance < 1000 && AttackTimer3 == INVALID_HANDLE)
					{
						targetEyes3[2] += 150.0;
						AttackTimer3 = CreateTimer(1.5, ResetAttackTimer3);
						buttons |= IN_ATTACK2;
					}
					if(chainDistance > 1000 && chainDistance < 1250 && AttackTimer4 == INVALID_HANDLE)
					{
						targetEyes3[2] += 200.0;
						AttackTimer4 = CreateTimer(2.0, ResetAttackTimer4);
						buttons |= IN_ATTACK2;
					}
					if(chainDistance > 1250 && chainDistance < 1500 && AttackTimer5 == INVALID_HANDLE)
					{
						targetEyes3[2] += 250.0;
						AttackTimer5 = CreateTimer(2.5, ResetAttackTimer5);
						buttons |= IN_ATTACK2;
					}
					if(chainDistance > 1500 && AttackTimer6 == INVALID_HANDLE)
					{
						targetEyes3[2] += 300.0;
						AttackTimer6 = CreateTimer(3.0, ResetAttackTimer6);
						buttons |= IN_ATTACK2;
					}
				}
			}
		}	
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client) 
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

stock bool IsWeaponSlotActive(int client, int slot)
{
    return GetPlayerWeaponSlot(client, slot) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

stock int Client_GetClosest(float vecOrigin_center[3], int client)
{
	float vecOrigin_edict[3];
	float distance = -1.0;
	int closestEdict = -1;
	for(int i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetClientEyePosition(i, vecOrigin_edict);
		if(GetClientTeam(i) != GetClientTeam(client))
		{
			if(TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
				continue;
			if(IsPointVisible(vecOrigin_center, vecOrigin_edict) && ClientViews(client, i))
			{
				float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					closestEdict = i;
				}
			}
		}
	}
	return closestEdict;
}

public Action ResetAttackTimer(Handle timer)
{
    AttackTimer = INVALID_HANDLE;
}

public Action ResetAttackTimer2(Handle timer)
{
    AttackTimer2 = INVALID_HANDLE;
}

public Action ResetAttackTimer3(Handle timer)
{
    AttackTimer3 = INVALID_HANDLE;
}

public Action ResetAttackTimer4(Handle timer)
{
    AttackTimer4 = INVALID_HANDLE;
}

public Action ResetAttackTimer5(Handle timer)
{
    AttackTimer5 = INVALID_HANDLE;
}

public Action ResetAttackTimer6(Handle timer)
{
    AttackTimer6 = INVALID_HANDLE;
}

stock bool IsPointVisible(float start[3], float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

stock bool ClientViews(int Viewer, int Target, float fMaxDistance=0.0, float fThreshold=0.70)
{
    // Retrieve view and target eyes position
    float fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
    float fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
    float fViewDir[3];
    float fTargetPos[3]; GetClientEyePosition(Target, fTargetPos);
    float fTargetDir[3];
    float fDistance[3];
	
    // Calculate view direction
    fViewAng[0] = fViewAng[2] = 0.0;
    GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
    
    // Calculate distance to viewer to see if it can be seen.
    fDistance[0] = fTargetPos[0]-fViewPos[0];
    fDistance[1] = fTargetPos[1]-fViewPos[1];
    fDistance[2] = 0.0;
    if (fMaxDistance != 0.0)
    {
        if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
            return false;
    }
    
    // Check dot product. If it's negative, that means the viewer is facing
    // backwards to the target.
    NormalizeVector(fDistance, fTargetDir);
    if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
    
    // Now check if there are no obstacles in between through raycasting
    Handle hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace)) {CloseHandle(hTrace); return false;}
    CloseHandle(hTrace);
    
    // Done, it's visible
    return true;
}

public bool ClientViewsFilter(int Entity, int Mask, any Junk)
{
    if (Entity >= 1 && Entity <= MaxClients) return false;
    return true;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
}
