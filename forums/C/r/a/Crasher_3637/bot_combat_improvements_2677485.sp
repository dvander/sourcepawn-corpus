#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

// new Handle:AttackTimer;
new Handle:Attack2Timer;
new Handle:Attack3Timer;
new Handle:Attack4Timer;
new Handle:Attack5Timer;
new Handle:Attack6Timer;
new Handle:Attack7Timer;
new Handle:Attack8Timer;


public Plugin:myinfo = 
{
	name = "TF Bot Logic",
	author = "tRololo312312 | Edited By Marqueritte",
	description = "Gamemode logic for TFBots (orignally for vsh/ff2) repurpose for normal play",
	version = "1.0",
	url = "Original plugin: https://forums.alliedmods.net/showthread.php?t=263130"
};

Float:moveForward(Float:vel[3],Float:MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

Float:moveBackwards(Float:vel[3],Float:MaxSpeed)
{
	vel[0] = -MaxSpeed;
	return vel;
}

Float:moveSide(Float:vel[3],Float:MaxSpeed)
{
	vel[1] = MaxSpeed;
	return vel;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client))
	{
		decl Float:camangle[3], Float:clientEyes[3], Float:targetEyes[3];
		GetClientEyePosition(client, clientEyes);
		new TFClassType:class = TF2_GetPlayerClass(client);
		new Ent = Client_GetClosest(clientEyes, client);
		
		decl Float:vec[3],Float:angle[3];
		if(IsValidClient(Ent) && class != TFClass_DemoMan && class != TFClass_Sniper && class != TFClass_Medic)
		{
			GetClientAbsOrigin(Ent, targetEyes);
			GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
			if(IsWeaponSlotActive(client, 0)) // If the bots have their primary out they will shoot in chest area and will do so automatically regardless of anything except for Demoman, Sniper, Soldier, and Medic.
			{
				targetEyes[2] += 55.5;
				buttons |= IN_ATTACK;
			}
			else
			{
			 	targetEyes[2] += 55.5;
			}
			MakeVectorFromPoints(targetEyes, clientEyes, vec);
			GetVectorAngles(vec, camangle);
			camangle[0] *= -1.0;
			camangle[1] += 180.0;
			ClampAngle(camangle);
			TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
		
			GetClientAbsOrigin(Ent, targetEyes);
			GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
			if(class == TFClass_Medic && IsWeaponSlotActive(client, 0)) // Medic bots aim at upper head level while using their primary.
			{
				targetEyes[2] += 78.5;
				buttons |= IN_ATTACK;
			}
			MakeVectorFromPoints(targetEyes, clientEyes, vec);
			GetVectorAngles(vec, camangle);
			camangle[0] *= -1.0;
			camangle[1] += 180.0;
			ClampAngle(camangle);
			TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
			
			GetClientAbsOrigin(Ent, targetEyes);
			GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
			if(class == TFClass_Soldier && IsWeaponSlotActive(client, 0)) // Soldier bots aim at the feet.
			{
				targetEyes[2] += 2.5;
				buttons |= IN_ATTACK;
			}
			else
			{
				targetEyes[2] += 55.5;
			}
			MakeVectorFromPoints(targetEyes, clientEyes, vec);
			GetVectorAngles(vec, camangle);
			camangle[0] *= -1.0;
			camangle[1] += 180.0;
			ClampAngle(camangle);
			TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
		}
		
		// For Unfinished RTD Support.
		// if(AttackTimer == INVALID_HANDLE) // Bots types !rtd and calls for medic afterwards.
		// {
		//	FakeClientCommand(client, "say !rtd");
		//	FakeClientCommand(client, "voicemenu 0 0");
		//	AttackTimer = CreateTimer(35.5, ResetAttackTimer);
		// }
		
		if(Attack2Timer == INVALID_HANDLE) // Bot use the "Help!" voice command
		{
			FakeClientCommand(client, "voicemenu 2 0");
			Attack2Timer = CreateTimer(10.5, ResetAttack2Timer);
		}
		
		if(Attack3Timer == INVALID_HANDLE) // Bots use the "Good Job" voice command
		{
			FakeClientCommand(client, "voicemenu 2 7");
			Attack3Timer = CreateTimer(15.5, ResetAttack3Timer);
		}
		
		if(Attack4Timer == INVALID_HANDLE) // Bots use the "Cheers" voice command
		{
			FakeClientCommand(client, "voicemenu 2 2");
			Attack4Timer = CreateTimer(20.5, ResetAttack4Timer);
		}
		
		if(Attack5Timer == INVALID_HANDLE) // Bot use the "Jeers" voice command
		{
			FakeClientCommand(client, "voicemenu 2 3");
			Attack5Timer = CreateTimer(25.5, ResetAttack5Timer);
		}
		
		if(Attack6Timer == INVALID_HANDLE) // Bot use the "Positive" voice command
		{
			FakeClientCommand(client, "voicemenu 2 4");
			Attack6Timer = CreateTimer(12.9, ResetAttack6Timer);
		}
		
		if(Attack7Timer == INVALID_HANDLE) // Bot use the "Negative" voice command
		{
			FakeClientCommand(client, "voicemenu 2 5");
			Attack7Timer = CreateTimer(18.8, ResetAttack7Timer);
		}
		
		if(Attack8Timer == INVALID_HANDLE) // Bot use the "Battle Cry" voice command 
		{
			FakeClientCommand(client, "voicemenu 2 1");
			Attack8Timer = CreateTimer(17.5, ResetAttack8Timer);
		}
			
		new Float:location_check[3];
		GetClientAbsOrigin(client, location_check);

		new Float:chainDistance;
		chainDistance = GetVectorDistance(location_check,targetEyes);
		
		if(chainDistance <400.0)
		{
			if(IsWeaponSlotActive(client, 2)) // if melee is out bots would run towards their target.
			{
				vel = moveForward(vel,400.0);
			}
			else
			{
			 // Bots move backwards and forwards depending on their target's position.
				Handle WallBehind;
				decl Float:lookangle[3], Float:ClientLocation[3], Float:WallBehindVec[3], Float:lookDir[3];
				vel = moveBackwards(vel,400.0);
				GetClientEyeAngles(client, lookangle);
				GetClientEyePosition(client, ClientLocation);
				GetAngleVectors(lookangle, lookDir, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(lookDir, 50.0);
				AddVectors(ClientLocation, lookDir, WallBehindVec);
				WallBehind = TR_TraceRayFilterEx(ClientLocation,WallBehindVec,MASK_PLAYERSOLID,RayType_EndPoint,Filter);
				if(TR_DidHit(WallBehind))
				{
					TR_GetEndPosition(WallBehindVec, WallBehind);
					new Float:wallDistance;
					wallDistance = GetVectorDistance(ClientLocation,WallBehindVec);
					if(wallDistance <60.0)
					{
						vel = moveSide(vel,400.0);
					}
				}
					
				CloseHandle(WallBehind);
			}
		}
	}
	
	return Plugin_Continue;
}

// public Action:ResetAttackTimer(Handle:timer)
// {
//	AttackTimer = INVALID_HANDLE;
// }

public Action:ResetAttack2Timer(Handle:timer)
{
	Attack2Timer = INVALID_HANDLE;
}

public Action:ResetAttack3Timer(Handle:timer)
{
	Attack3Timer = INVALID_HANDLE;
}

public Action:ResetAttack4Timer(Handle:timer)
{
	Attack4Timer = INVALID_HANDLE;
}

public Action:ResetAttack5Timer(Handle:timer)
{
	Attack5Timer = INVALID_HANDLE;
}

public Action:ResetAttack6Timer(Handle:timer)
{
	Attack6Timer = INVALID_HANDLE;
}

public Action:ResetAttack7Timer(Handle:timer)
{
	Attack7Timer = INVALID_HANDLE;
}

public Action:ResetAttack8Timer(Handle:timer)
{
	Attack8Timer = INVALID_HANDLE;
}

bool:IsValidClient( client ) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

stock bool:IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock Client_GetClosest(Float:vecOrigin_center[3], const client)
{
	decl Float:vecOrigin_edict[3];
	new Float:distance = -1.0;
	new closestEdict = -1;
	for(new i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetClientEyePosition(i, vecOrigin_edict);
		if(GetClientTeam(i) != GetClientTeam(client))
		{
			if(TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
				continue;
			if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			{
				new Float:edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
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

stock ClampAngle(Float:fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

stock bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

public bool:TraceEntityFilterStuff(entity, mask)
{
	return entity > MaxClients;
}

public bool:Filter(entity,mask)
{
	return !(IsValidClient(entity));
}