#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION  "1.7.4"

float DefaultAimSpeed = 0.065;

float g_flMedicHealTimer[MAXPLAYERS + 1];
float g_flJumpTimer[MAXPLAYERS + 1];
float g_flDuckTimer[MAXPLAYERS + 1];
float g_flMiscTimer[MAXPLAYERS + 1];
float g_flNeedHealTimer[MAXPLAYERS + 1];
float g_flThanksTimer[MAXPLAYERS + 1];
float g_flBuildhereTimer[MAXPLAYERS + 1];
float g_flRTDTimer[MAXPLAYERS + 1];
ConVar g_cvRTDEnable;
ConVar g_cvBVCEnable;
ConVar g_cvCombatJumpEnable;
ConVar g_cvDoubleJumpEnable;

Handle AttackTimer;
Handle AttackTimer2;
Handle AttackTimer3;
Handle AttackTimer4;
Handle AttackTimer5;
Handle AttackTimer6;

public Plugin myinfo = 
{
	name = "[TF2] Bot Combat Improvements",
	author = "EfeDursun125, enderandrew, Marqueritte, Showin', and Crasher_3637",
	description = "Bots fight better in combat.",
	version = PLUGIN_VERSION,
};

public void OnPluginStart()
{
 	g_cvBVCEnable = CreateConVar("tf_bot_voice_commands", "1", "controls whenever TFbots use voice commands. Default = 1.", _, true, 0.0, true, 1.0);
	g_cvRTDEnable = CreateConVar("tf_bot_rtd_support", "0", "Enables or Disables RTD(Roll The Dice) support for TFbots. Default = 0.", _, true, 0.0, true, 1.0);
	g_cvCombatJumpEnable = CreateConVar("tf_bot_combat_jump", "1", "controls whenever TFBots jump during gameplay. Default = 1.", _, true, 0.0, true, 1.0);
	g_cvDoubleJumpEnable = CreateConVar("tf_bot_scout_doublejump", "0", "controls whenever a Scout double jumps when he jumps. Default = 0 since it may be buggy.", _, true, 0.0, true, 1.0);
	HookEvent("player_spawn", BotSpawn, EventHookMode_Post);
	HookEvent("player_hurt", BotHurt, EventHookMode_Post);
	HookEvent("player_death", hookPlayerDie, EventHookMode_Post);
}

float moveForward(float vel[3],float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client))
	{
		float clientEyes[3];
		float targetEyes[3];
		float targetEyes2[3];
		float targetEyes3[3];
		float targetEyesBase[3];
		GetClientEyePosition(client, clientEyes);
		int CurrentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
		int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		TFClassType class = TF2_GetPlayerClass(client);
		int Ent = Client_GetClosest(clientEyes, client);
		
		
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
			
			if(class == TFClass_Medic && !IsWeaponSlotActive(client, 2))
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
			
			if(class == TFClass_DemoMan) // Demomen will sticky spam.
			{
				float StickyDistance;
				StickyDistance = GetVectorDistance(location_check,targetEyes);
				
				if(IsWeaponSlotActive(client, 1))
				{
					if(StickyDistance < 500 && AttackTimer == INVALID_HANDLE)
					{
						targetEyes3[2] += 50.0;
						AttackTimer = CreateTimer(0.8, ResetAttackTimer);
						buttons |= IN_ATTACK2;
					}
					if(StickyDistance > 500 && StickyDistance < 750 && AttackTimer2 == INVALID_HANDLE)
					{
						targetEyes3[2] += 100.0;
						AttackTimer2 = CreateTimer(1.2, ResetAttackTimer2);
						buttons |= IN_ATTACK2;
					}
					if(StickyDistance > 750 && StickyDistance < 1000 && AttackTimer3 == INVALID_HANDLE)
					{
						targetEyes3[2] += 150.0;
						AttackTimer3 = CreateTimer(1.5, ResetAttackTimer3);
						buttons |= IN_ATTACK2;
					}
					if(StickyDistance > 1000 && StickyDistance < 1250 && AttackTimer4 == INVALID_HANDLE)
					{
						targetEyes3[2] += 200.0;
						AttackTimer4 = CreateTimer(2.0, ResetAttackTimer4);
						buttons |= IN_ATTACK2;
					}
					if(StickyDistance > 1250 && StickyDistance < 1500 && AttackTimer5 == INVALID_HANDLE)
					{
						targetEyes3[2] += 250.0;
						AttackTimer5 = CreateTimer(2.5, ResetAttackTimer5);
						buttons |= IN_ATTACK2;
					}
					if(StickyDistance > 1500 && AttackTimer6 == INVALID_HANDLE)
					{
						targetEyes3[2] += 300.0;
						AttackTimer6 = CreateTimer(3.0, ResetAttackTimer6);
						buttons |= IN_ATTACK2;
					}
				}
			}
			
			int index = GetPlayerWeaponSlot(client, 1);
			if(131 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") && chainDistance < GetRandomFloat(500.0, 600.0) && class == TFClass_DemoMan && IsWeaponSlotActive(client, 2) || 406 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") && chainDistance < GetRandomFloat(500.0, 600.0) && class == TFClass_DemoMan && IsWeaponSlotActive(client, 2) || 1099 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") && chainDistance < GetRandomFloat(500.0, 600.0) && class == TFClass_DemoMan && IsWeaponSlotActive(client, 2) || 1144 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") && chainDistance < GetRandomFloat(500.0, 600.0) && class == TFClass_DemoMan && IsWeaponSlotActive(client, 2)) // Makes Demoman using melee go to their enemies.
			{
				targetEyes[2] = targetEyes2[2] - 35.0;
				vel = moveForward(vel,400.0);
			}
			
			
			if(class == TFClass_Soldier) // Soldier bots aim at the feet.
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
			}
			
			if(class != TFClass_Medic && class != TFClass_Soldier && class != TFClass_Sniper && class != TFClass_Engineer && class != TFClass_DemoMan && class != TFClass_Spy) // All except for the ones listed do not get aim tracking.
			{
				targetEyes[2] = targetEyes2[2] - 35.0;
			}
			else if(class == TFClass_Soldier && IsWeaponSlotActive(client, 1)) // When Soldier's Shotgun is out it applies the Tracking aim.
			{
				targetEyes[2] = targetEyes2[2] - 35.0;
			}
			
			
			// Code to activate the aim assist (Thanks to efe for pointing this out!)
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
			
			if(class == TFClass_Heavy)
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
			else if(class == TFClass_Scout)
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
			else if(class == TFClass_Pyro)
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
		}
		
		// Combat Jumping.
		if (g_cvCombatJumpEnable.IntValue > 0)
		{
			if(class != TFClass_Sniper && class != TFClass_Medic && !IsWeaponSlotActive(client, 2))
			{	
				// Modification of old script where bots jump in combat. (Makes sure that bots are not using melee)
				if(g_flJumpTimer[client] < GetGameTime())
				{
					buttons |= IN_JUMP;
					buttons &= ~IN_DUCK;
					g_flJumpTimer[client] = GetGameTime() + GetRandomFloat(5.0, 15.0);
				}
				
				if(g_flDuckTimer[client] < GetGameTime())
				{
					buttons |= IN_DUCK;
					g_flDuckTimer[client] = GetGameTime() + 25.0;		
				}
			}
		}
		
		if (g_cvDoubleJumpEnable.IntValue > 0)
		{
			if(class == TFClass_Scout)
			{
				if(buttons & IN_JUMP)
				{
					buttons |= IN_JUMP;
				}
			}
		}
		
		// Voice Commands
		
		if (g_cvRTDEnable.IntValue > 0)
		{	
			// For Unfinished RTD Support.
			if(g_flRTDTimer[client] < GetGameTime()) // Bots types RTD.
			{
				FakeClientCommandThrottled(client, "say /rtd"); // Instead of exclamation use a slash so it won't spam chat.
				g_flRTDTimer[client] = GetGameTime() + GetRandomFloat(90.0, 125.0);
			}
		}
		
		if (g_cvBVCEnable.IntValue > 0)
		{
			if(g_flMiscTimer[client] < GetGameTime()) // Bots use Misc Voice Commands (i.e "Battle Cry" and "Cheers")
			{
				int randomvoice = GetRandomInt(1,5);
				switch (randomvoice)
				{
					case 1: 
					{
						FakeClientCommandThrottled(client, "voicemenu 2 1"); // Battle Cry
					}
					case 2:
					{
						FakeClientCommandThrottled(client, "voicemenu 2 2"); // Cheers
					}
					case 3: 
					{
						FakeClientCommandThrottled(client, "voicemenu 2 3"); // Jeers
					}
					case 4:
					{
						FakeClientCommandThrottled(client, "voicemenu 2 4"); // Positive
					}
					case 5:
					{
						FakeClientCommandThrottled(client, "voicemenu 2 5"); // Negative
					}
				}
				g_flMiscTimer[client] = GetGameTime() + GetRandomFloat(40.0, 85.0);
			}
			
			if(g_flNeedHealTimer[client] < GetGameTime()) // Bot calls "Medic" when low in health (checks if there is a medic)
			{
				if(CurrentHealth < (MaxHealth / 2))
				{
					if(GetAliveMedicsCount(client) > 0)
					{
						FakeClientCommandThrottled(client, "voicemenu 0 0");
					}
				}
				g_flNeedHealTimer[client] = GetGameTime() + GetRandomFloat(5.0, 15.0);
			}
			
			if(g_flThanksTimer[client] < GetGameTime()) // Bots thank medics after being healed.
			{
				if(TF2_GetNumHealers(client) > 0)
				{
					FakeClientCommandThrottled(client, "voicemenu 0 1");
				}
				g_flThanksTimer[client] = GetGameTime() + GetRandomFloat(15.0, 25.0);
			}
			
			if(g_flBuildhereTimer[client] < GetGameTime()) // Bots use Build Voice Commands (i.e "SentryHere" and "DispenserHere")
			{
				if(class != TFClass_Engineer)
				{	
					if(GetAliveEngineerCount(client) > 0)
					{
						int buildvoice = GetRandomInt(1,4);
						switch (buildvoice)
						{
							case 1:
							{
								FakeClientCommandThrottled(client, "voicemenu 1 5"); // SentryHere
							}
							case 2:							
							{
								FakeClientCommandThrottled(client, "voicemenu 1 4"); // DispenserHere
							}
							case 3: 
							{
								FakeClientCommandThrottled(client, "voicemenu 1 3"); // TeleporterHere
							}
							case 4: 
							{
								FakeClientCommandThrottled(client, "voicemenu 0 3"); // MoveUp
							}
						}
						g_flBuildhereTimer[client] = GetGameTime() + 150.0;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action BotSpawn(Handle event, const char[] name, bool dontBroadcast) // Bot uses voice commands when they spawn. (This code and below are taken from efedursun)
{
	int botid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsFakeClient(botid) && IsPlayerAlive(botid)) 
	{
		int spawnchance = GetRandomInt(1,24);
		switch(spawnchance)
		{
			case 1:
			{
				FakeClientCommandThrottled(botid, "voicemenu 0 2"); // Go Go Go
			}
			case 2:
			{
				FakeClientCommandThrottled(botid, "voicemenu 1 0"); // Incoming
			}
			case 3:
			{
				FakeClientCommandThrottled(botid, "voicemenu 0 0"); // Medic!
			}
			case 4:
			{
				FakeClientCommandThrottled(botid, "voicemenu 2 0"); // Help!
			}
			case 5: 
			{
				FakeClientCommandThrottled(botid, "voicemenu 2 3"); // Jeers
			}
			case 6:
			{
				FakeClientCommandThrottled(botid, "voicemenu 2 5"); // Negative
			}
			case 7: 
			{
				FakeClientCommandThrottled(botid, "voicemenu 2 1"); // Battle Cry
			}
		}
	}
}

public Action BotHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int botid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsFakeClient(botid) && IsPlayerAlive(botid))
	{
		int hurtchance = GetRandomInt(1,18);
		switch(hurtchance)
		{
			case 1:
			{
				FakeClientCommandThrottled(botid, "voicemenu 2 0"); // Help!
			}
		}
	}
}

public Action hookPlayerDie(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetEventInt(event, "attacker");
	int botid = GetClientOfUserId(attacker);
	
	if(IsFakeClient(botid))
	{
		if(IsPlayerAlive(botid))
		{
			int random = GetRandomInt(1,12);
			switch(random)
			{
				case 1:
			  	{
					FakeClientCommandThrottled(botid, "voicemenu 2 6"); // Nice Shot
				}
				case 2: 
				{
					FakeClientCommandThrottled(botid, "voicemenu 2 7"); // Good Job
				}
			}
		}
	}
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

float g_flNextCommand[MAXPLAYERS + 1];
stock bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 0.4;
	
	return true;
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

stock int TF2_GetNumHealers(int client)
{
    return GetEntProp(client, Prop_Send, "m_nNumHealers");
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock int GetAliveEngineerCount(int client)
{
    int number = 0;
    for (int i=1; i<=MaxClients; i++)
    {
        if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(client) && TF2_GetPlayerClass(i) == TFClass_Engineer) 
            number++;
    }
    return number;
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