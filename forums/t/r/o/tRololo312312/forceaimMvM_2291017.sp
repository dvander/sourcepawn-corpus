#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "BotAimMvM",
	author = "tRololo312312",
	description = "Makes Bots on MvM not so useless",
	version = "1.1",
	url = "http://steamcommunity.com/profiles/76561198039186809"
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				new team = GetClientTeam(client);
				if(team == 2)
				{
					decl Float:camangle[3], Float:clientEyes[3], Float:targetEyes[3], Float:fEntityLocation[3];
					GetClientEyePosition(client, clientEyes);
					new TFClassType:class = TF2_GetPlayerClass(client);
					new iEnt = -1;
					new Ent = Client_GetClosest(clientEyes, client);
					if((iEnt = FindEntityByClassname(iEnt, "entity_revive_marker")) != INVALID_ENT_REFERENCE && class == TFClass_Medic)
					{
						if(IsValidEntity(iEnt))
						{
							decl Float:vec[3],Float:angle[3];
							GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fEntityLocation);
							GetEntPropVector(iEnt, Prop_Data, "m_angRotation", angle);
							fEntityLocation[2] += 33.5;
							MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
							GetVectorAngles(vec, camangle);
							camangle[0] *= -1.0;
							camangle[1] += 180.0;
							ClampAngle(camangle);

							new Float:location_check[3];
							GetClientAbsOrigin(client, location_check);

							new Float:chainDistance;
							chainDistance = GetVectorDistance(location_check,targetEyes);

							if(IsPointVisibleTank(clientEyes, fEntityLocation))
							{
								new iMediGun = GetPlayerWeaponSlot(client, 1);
								SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iMediGun);
								if(chainDistance <175.0)
								{
									ScaleVector(vec, 400.0);
								}
								else
								{
									ScaleVector(vec, -400.0);
								}
								vec[2] = -450.0;
								TeleportEntity(client, NULL_VECTOR, camangle, vec);
								buttons |= IN_ATTACK;
							}
						}
					}
					else if((iEnt = FindEntityByClassname(iEnt, "tank_boss")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt))
						{
							decl Float:vec[3],Float:angle[3];
							GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fEntityLocation);
							GetEntPropVector(iEnt, Prop_Data, "m_angRotation", angle);
							fEntityLocation[2] += 33.5;
							MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
							GetVectorAngles(vec, camangle);
							camangle[0] *= -1.0;
							camangle[1] += 180.0;
							ClampAngle(camangle);

							new Float:location_check[3];
							GetClientAbsOrigin(client, location_check);

							new Float:chainDistance;
							chainDistance = GetVectorDistance(location_check,fEntityLocation);

							if(class == TFClass_Pyro && chainDistance <400.0)
							{
								GetAngleVectors(camangle, vec, NULL_VECTOR, NULL_VECTOR);
								ScaleVector(vec, 400.0);
								vec[2] = -450.0;
								if(IsPointVisibleTank(clientEyes, fEntityLocation))
								{
									TeleportEntity(client, NULL_VECTOR, camangle, vec);
									buttons |= IN_ATTACK;
								}
							}
							else if(chainDistance <400.0)
							{
								if(IsPointVisibleTank(clientEyes, fEntityLocation))
								{
									TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
									buttons |= IN_ATTACK;
								}
							}
						}
					}
					else if(Ent != -1)
					{
						decl Float:vec[3],Float:angle[3];
						GetClientAbsOrigin(Ent, targetEyes);
						GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
						if(GetClientButtons(Ent) & IN_DUCK)
						{
							targetEyes[2] += 15.0;
						}
						else
						{
							targetEyes[2] += 33.5;
						}
						MakeVectorFromPoints(targetEyes, clientEyes, vec);
						GetVectorAngles(vec, camangle);
						camangle[0] *= -1.0;
						camangle[1] += 180.0;
						ClampAngle(camangle);

						new Float:location_check[3];
						GetClientAbsOrigin(client, location_check);

						new Float:chainDistance;
						chainDistance = GetVectorDistance(location_check,targetEyes);

						new TFClassType:classspy = TF2_GetPlayerClass(Ent);
						if(class == TFClass_Pyro && chainDistance <400.0)
						{
							GetAngleVectors(camangle, vec, NULL_VECTOR, NULL_VECTOR);
							if(chainDistance <175.0)
							{
								ScaleVector(vec, -400.0);
							}
							else
							{
								ScaleVector(vec, 400.0);
							}
							vec[2] = -450.0;
							buttons |= IN_ATTACK;
							TeleportEntity(client, NULL_VECTOR, camangle, vec);
						}
						else
						{
							TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
						}
						if(classspy == TFClass_Spy)
						{
							buttons |= IN_ATTACK;
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

bool:IsValidClient( client ) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
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
			new TFClassType:class = TF2_GetPlayerClass(client);
			if(class == TFClass_Medic || class == TFClass_Engineer || class == TFClass_Sniper)
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

stock bool:IsPointVisibleTank(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.9;
}

public bool:TraceEntityFilterStuff(entity, mask)
{
	return entity > MaxClients;
}

public bool:TraceEntityFilterStuffTank(entity, mask)
{
	new maxentities = GetMaxEntities();
	return entity > maxentities;
}
