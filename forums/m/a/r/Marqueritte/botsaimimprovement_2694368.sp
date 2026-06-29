#include <sourcemod>
#include <sdkhooks>
#include <insurgency>
#define PLUGIN_VERSION "1.0"
#define PLUGIN_DESCRIPTION "Bots have improve combat"

new Handle:AttackTimer;
new Handle:AttackTimer2;
new Handle:AttackTimer3;
new Handle:AttackTimer4;
new Handle:AttackTimer5;

public Plugin:myinfo =
{
	name = "Bots Aim Improvements",
	author = "Marqueritte",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client))
	{
		float clientEyes[3];
		float targetEyes[3];
		float targetEyes2[3];
		float targetEyes3[3];
		float targetEyesBase[3];
		int Ent = Client_GetClosest(clientEyes, client);
		
		if(IsValidClient(Ent))
		{
			GetClientAbsOrigin(Ent, targetEyes);
			GetClientAbsOrigin(Ent, targetEyesBase);
			GetClientAbsOrigin(Ent, targetEyes3);
			GetClientEyePosition(Ent, targetEyes2);
			
			if(IsWeaponSlotActive(client, 0) || IsWeaponSlotActive(client, 1))
			{
				new Float:location_check[3];
				GetClientAbsOrigin(client, location_check);

				new Float:chainDistance;
				chainDistance = GetVectorDistance(location_check,targetEyes);
				
				if(chainDistance < 500 && AttackTimer == INVALID_HANDLE)
				{
					targetEyes[2] = targetEyes2[2];
					AttackTimer = CreateTimer(0.8, ResetAttackTimer);
					buttons |= IN_ATTACK
				}
				if(chainDistance > 500 && chainDistance < 750 && AttackTimer2 == INVALID_HANDLE)
				{
					targetEyes[2] = targetEyes2[2] - 18.0;
					AttackTimer2 = CreateTimer(1.2, ResetAttackTimer2);
					buttons |= IN_ATTACK
				}
				if(chainDistance > 750 && chainDistance < 1000 && AttackTimer3 == INVALID_HANDLE)
				{
					targetEyes[2] = targetEyes2[2] - 35.0;
					AttackTimer3 = CreateTimer(2.0, ResetAttackTimer3);
					buttons |= IN_ATTACK
				}
				if(chainDistance > 1000 && chainDistance < 1250 && AttackTimer4 == INVALID_HANDLE)
				{
					targetEyes[2] = targetEyes2[2] - 35.0;
					AttackTimer4 = CreateTimer(3.0, ResetAttackTimer4);
					buttons |= IN_ATTACK
				}
				if(chainDistance > 1250 && chainDistance < 1500 && AttackTimer5 == INVALID_HANDLE)
				{
					int rnd = GetRandomUInt(0,4);
					if(rnd == 0)
					{
						targetEyes[2] = targetEyes2[2];
					}
					switch (rnd)
					{
						case 1:
						{
							targetEyes[2] = targetEyes2[2] - 18.0;
						}
						case 2:
						{
							targetEyes[2] = targetEyes2[2] - 35.0;
						}
						case 3:
						{
							targetEyes[2] = targetEyes2[2] - 45.0;
						}
						AttackTimer5 = CreateTimer(4.5, ResetAttackTimer5);
						buttons |= IN_ATTACK
					}
				}
			}
		}
	}	
	return Plugin_Continue;
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

public Action:ResetAttackTimer(Handle:timer)
{
    AttackTimer = INVALID_HANDLE;
}

public Action:ResetAttackTimer2(Handle:timer)
{
    AttackTimer2 = INVALID_HANDLE;
}

public Action:ResetAttackTimer3(Handle:timer)
{
    AttackTimer3 = INVALID_HANDLE;
}

public Action:ResetAttackTimer4(Handle:timer)
{
    AttackTimer4 = INVALID_HANDLE;
}

public Action:ResetAttackTimer5(Handle:timer)
{
    AttackTimer5 = INVALID_HANDLE;
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

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}
