#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1.1"

float DefaultAimSpeed = 0.2;

//float g_flRTDTimer[MAXPLAYERS + 1];
float g_flHelpTimer[MAXPLAYERS + 1];
float g_flGoodJobTimer[MAXPLAYERS + 1];
float g_flCheersJeersTimer[MAXPLAYERS + 1];
float g_flPositiveNegativeTimer[MAXPLAYERS + 1];
float g_flBattleCryTimer[MAXPLAYERS + 1];
float g_flMedicTimer[MAXPLAYERS + 1];
float g_flThanksTimer[MAXPLAYERS + 1];

float g_flMedicHealTimer[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[TF2] TFBot Logic",
	author = "tRololo312312 | Edited By Marqueritte",
	description = "Gamemode logic for TFBots (orignally for vsh/ff2) repurpose for normal play",
	version = PLUGIN_VERSION,
	url = "Original plugin: https://forums.alliedmods.net/showthread.php?t=263130"
};

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		float clientEyes[3];
		float targetEyes[3];
		float targetEyes2[3];
		float targetEyes3[3];
		float targetEyesBase[3];
		GetClientEyePosition(client, clientEyes);
		TFClassType class = TF2_GetPlayerClass(client);
		int Ent = Client_GetClosest(clientEyes, client);
		int CurrentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
		int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		
		float angle[3];
		if(IsValidClient(Ent))
		{
			GetClientAbsOrigin(Ent, targetEyes);
			GetClientAbsOrigin(Ent, targetEyesBase);
			GetClientAbsOrigin(Ent, targetEyes3);
			GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
			GetClientEyePosition(Ent, targetEyes2);
			
			float EntVel[3];
			GetEntPropVector(Ent, Prop_Data, "m_vecVelocity", EntVel);
			
			float location_check[3];
			GetClientAbsOrigin(client, location_check);
			
			float chainDistance;
			chainDistance = GetVectorDistance(location_check,targetEyes);
			
			if(class == TFClass_Medic && !IsWeaponSlotActive(client, 2)) // Medic bots aim at upper head level while using their primary.
			{
				targetEyes[2] = targetEyes2[2];
				if(g_flMedicHealTimer[client] < GetGameTime())
				{
					g_flMedicHealTimer[client] = GetGameTime() + GetRandomFloat(1.0, 3.0);
				}
				else
				{
					buttons |= IN_ATTACK;
				}
			}
			else if(class == TFClass_Medic && IsWeaponSlotActive(client, 2))
			{
				targetEyes[2] = targetEyes2[2] - 20.0;
				buttons |= IN_ATTACK;
			}
			else if(class == TFClass_DemoMan)
			{
				if(chainDistance < 500)
				{
					targetEyes3[2] += 50.0;
				}
				if(chainDistance > 500 && chainDistance < 750)
				{
					targetEyes3[2] += 100.0;
				}
				if(chainDistance > 750 && chainDistance < 1000)
				{
					targetEyes3[2] += 150.0;
				}
				if(chainDistance > 1000 && chainDistance < 1250)
				{
					targetEyes3[2] += 200.0;
				}
				if(chainDistance > 1250 && chainDistance < 1500)
				{
					targetEyes3[2] += 250.0;
				}
				if(chainDistance > 1500)
				{
					targetEyes3[2] += 300.0;
				}
			}
			else if(class == TFClass_Sniper)
			{
				targetEyes[2] = targetEyes2[2];
			}
			else if(class == TFClass_Soldier) // Soldier bots aim at the feet.
			{
				if(IsWeaponSlotActive(client, 0))
				{
					if(GetEntityFlags(Ent) & FL_ONGROUND)
					{
						targetEyes[2] += 5.0;
					}
					else
					{
						targetEyes[2] += 0.0;
					}
					
					if(IsPointVisible(clientEyes, EntVel))
					{
						targetEyes[1] += (EntVel[1] / 2);
					}
					else
					{
						targetEyes[1] = targetEyes2[1];
					}
				}
				else
				{
					targetEyes[2] = targetEyes2[2] - 35.0;
					targetEyes[1] += 0.0;
				}
				targetEyes[2] = targetEyes2[2] - 35.0;
			}
			else if(class != TFClass_Medic && class != TFClass_Soldier && class != TFClass_Sniper) // If the bots have their primary out they will shoot in chest area and will do so automatically regardless of anything except for Demoman, Sniper, Soldier, and Medic.
			{
				targetEyes[2] = targetEyes2[2] - 35.0;
				//buttons |= IN_ATTACK; i think this is so bad for huntsman snipers and sticky launcher using bots
			}
			
			if(class == TFClass_Soldier)
			{
				if(IsPointVisible(clientEyes, targetEyesBase))
				{
					TF2_LookAtPos(client, targetEyes, DefaultAimSpeed);
				}
				else
				{
					TF2_LookAtPos(client, targetEyes2, DefaultAimSpeed);
				}
			}
			else if(class == TFClass_DemoMan)
			{
				if(IsPointVisible(clientEyes, targetEyes3) && IsPointVisible(targetEyes2, targetEyes3))
				{
					TF2_LookAtPos(client, targetEyes3, DefaultAimSpeed);
				}
				else
				{
					TF2_LookAtPos(client, targetEyes2, DefaultAimSpeed);
				}
			}
			else if(class == TFClass_Engineer && !IsWeaponSlotActive(client,2))
			{
				TF2_LookAtPos(client, targetEyes, DefaultAimSpeed);
			}
			else
			{
				if(class == TFClass_Medic)
				{
					if(!IsWeaponSlotActive(client,1))
					{
						TF2_LookAtPos(client, targetEyes, DefaultAimSpeed);
					}
				}
				else
				{
					TF2_LookAtPos(client, targetEyes, DefaultAimSpeed);
				}
			}
			
			if(g_flHelpTimer[client] < GetGameTime()) // Bot use the "Help!" voice command
			{
				FakeClientCommandThrottled(client, "voicemenu 2 0");
			}
		}
		
		// For Unfinished RTD Support.
		// if(g_flRTDTimer[client] < GetGameTime()) // Bots types !rtd and calls for medic afterwards.
		// {
		//	FakeClientCommandThrottled(client, "say !rtd");
		//	FakeClientCommandThrottled(client, "voicemenu 0 0");
		//	g_flRTDTimer[client] = GetGameTime() + GetRandomFloat(30.0, 90.0);
		// }
		
		if(g_flHelpTimer[client] < GetGameTime()) // Bot use the "Help!" voice command
		{
			g_flHelpTimer[client] = GetGameTime() + GetRandomFloat(10.0, 20.0);
		}
		
		if(g_flGoodJobTimer[client] < GetGameTime()) // Bots use the "Good Job" voice command
		{
			FakeClientCommandThrottled(client, "voicemenu 2 7");
			g_flGoodJobTimer[client] = GetGameTime() + GetRandomFloat(15.0, 30.0);
		}
		
		if(g_flCheersJeersTimer[client] < GetGameTime()) // Bots use the "Cheers" & "Jeers" voice command
		{
			int randomvoice = GetRandomInt(1,100);
			if(randomvoice <= 50)
			{
				FakeClientCommandThrottled(client, "voicemenu 2 2");
			}
			else
			{
				FakeClientCommandThrottled(client, "voicemenu 2 3");
			}
			g_flCheersJeersTimer[client] = GetGameTime() + GetRandomFloat(20.0, 60.0);
		}
		
		if(g_flPositiveNegativeTimer[client] < GetGameTime()) // Bot use the "Positive" voice command
		{
			int randomvoice = GetRandomInt(1,100);
			if(randomvoice <= 50)
			{
				FakeClientCommandThrottled(client, "voicemenu 2 4");
			}
			else
			{
				FakeClientCommandThrottled(client, "voicemenu 2 5");
			}
			g_flPositiveNegativeTimer[client] = GetGameTime() + GetRandomFloat(40.0, 80.0);
		}
		
		if(g_flBattleCryTimer[client] < GetGameTime()) // Bot use the "Battle Cry" voice command 
		{
			FakeClientCommandThrottled(client, "voicemenu 2 1");
			g_flBattleCryTimer[client] = GetGameTime() + GetRandomFloat(22.0, 44.0);
		}
		
		if(g_flMedicTimer[client] < GetGameTime()) // Bot use the "Medic" voice command
		{
			if(CurrentHealth < (MaxHealth / 2))
			{
				if(GetAliveMedicsCount(client) > 0)
				{
					FakeClientCommandThrottled(client, "voicemenu 0 0");
				}
			}
			g_flMedicTimer[client] = GetGameTime() + GetRandomFloat(5.0, 15.0);
		}
		
		if(g_flThanksTimer[client] < GetGameTime())
		{
			if(TF2_GetNumHealers(client) > 0)
			{
				FakeClientCommandThrottled(client, "voicemenu 0 1");
			}
			g_flThanksTimer[client] = GetGameTime() + GetRandomFloat(5.0, 15.0);
		}
		
		float chainDistance2;
		chainDistance2 = GetVectorDistance(clientEyes,targetEyes);
		
		if(chainDistance2 < GetRandomFloat(100.0, 500.0))
		{
			if(IsWeaponSlotActive(client, 2) || class == TFClass_Pyro && IsWeaponSlotActive(client, 0)) // if melee is out bots would run towards their target.
			{
				if(Ent != -1)
				{
					TF2_MoveTo(client, targetEyes, vel, angles);
				}
			}
			else
			{
			 // Bots move backwards and forwards depending on their target's position.
				Handle WallBehind;
				if(Ent != -1)
				{
					TF2_MoveOut(client, targetEyes, vel, angles);
				}
				float lookangle[3];
				float ClientLocation[3];
				float WallBehindVec[3];
				float lookDir[3];
				GetClientEyeAngles(client, lookangle);
				GetClientEyePosition(client, ClientLocation);
				GetAngleVectors(lookangle, lookDir, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(lookDir, 50.0);
				AddVectors(ClientLocation, lookDir, WallBehindVec);
				WallBehind = TR_TraceRayFilterEx(ClientLocation,WallBehindVec,MASK_PLAYERSOLID,RayType_EndPoint,Filter);
				if(TR_DidHit(WallBehind))
				{
					TR_GetEndPosition(WallBehindVec, WallBehind);
					float wallDistance;
					wallDistance = GetVectorDistance(ClientLocation,WallBehindVec);
					if(wallDistance < 60.0)
					{
						TF2_MoveOut(client, WallBehindVec, vel, angles);
					}
				}
					
				CloseHandle(WallBehind);
			}
		}
	}
	
	return Plugin_Continue;
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

stock void TF2_MoveOut(int client, float flGoal[3], float fVel[3], float fAng[3])
{
    float flPos[3];
    GetClientAbsOrigin(client, flPos);

    float newmove[3];
    SubtractVectors(flGoal, flPos, newmove);
    
    float sin = Sine(fAng[1] * FLOAT_PI / 180.0);
    float cos = Cosine(fAng[1] * FLOAT_PI / 180.0);                        
    
    fVel[0] = cos * newmove[0] - sin * newmove[1];
    fVel[1] = sin * newmove[0] + cos * newmove[1];
    
    NormalizeVector(fVel, fVel);
    ScaleVector(fVel, 450.0);
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

stock Client_GetClosest(float vecOrigin_center[3], int client)
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

float g_flNextCommand[MAXPLAYERS + 1];
stock bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 0.4;
	
	return true;
}

stock TF2_GetNumHealers(int client)
{
    return GetEntProp(client, Prop_Send, "m_nNumHealers");
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

stock void TF2_LookAtPos(int client, float flGoal[3], float flAimSpeed = 0.05)
{
	float flPos[3];
	GetClientEyePosition(client, flPos);

	float flAng[3];
	GetClientEyeAngles(client, flAng);
	
	// get normalised direction from target to client
	float desired_dir[3];
	MakeVectorFromPoints(flPos, flGoal, desired_dir);
	GetVectorAngles(desired_dir, desired_dir);
	
	// ease the current direction to the target direction
	flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
	flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) * flAimSpeed;

	TeleportEntity(client, NULL_VECTOR, flAng, NULL_VECTOR);
}

stock int AngleDifference(float angle1, float angle2)
{
	int diff = RoundToNearest((angle2 - angle1 + 180)) % 360 - 180;
	return diff < -180 ? diff + 360 : diff;
}

stock float AngleNormalize(float angle)
{
	angle = fmodf(angle, 360.0);
	if (angle > 180) 
	{
		angle -= 360;
	}
	if (angle < -180)
	{
		angle += 360;
	}
	
	return angle;
}

stock float fmodf(float number, float denom)
{
	return number - RoundToFloor(number / denom) * denom;
}

stock int GetAliveMedicsCount(int client)
{
    int number = 0;
    for (int i=1; i<=MaxClients; i++)
    {
        if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(client) && TF2_GetPlayerClass(i) == TFClass_Medic) 
            number++;
    }
    return number;
}

stock bool IsPointVisible(float start[3], float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
}

public bool Filter(int entity, int mask)
{
	return !(IsValidClient(entity));
}