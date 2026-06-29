#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
//Using Diablos modified AFK manager.
#tryinclude <afk_manager>

new g_bAfkbot[MAXPLAYERS+1] = {false, ...};
new Handle:JumpTimer;
new Handle:AttackTimer;

// Removed my other account so it does not confuse others(3.2)
public Plugin:myinfo = 
{
	name = "MedicBot",
	author = "tRololo312312",
	description = "Medic AI for afk players",
	version = "3.8.1",
	url = "http://steamcommunity.com/profiles/76561198039186809"
}

public OnPluginStart()
{
	// teamplay instead of arena(3.5)
	HookEvent("teamplay_round_start", CheckClass);
	LoadTranslations("common.phrases.txt");
	RegConsoleCmd("sm_afk", Command_Afk);

	// Medic Call hook(3.3)
	AddCommandListener(Command_AfkOff, "voicemenu");
}

public Action:CheckClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(2.0, LoadStuff);
}

public Action:LoadStuff(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(g_bAfkbot[client] && IsValidClient(client))
		{
			new TFClassType:class = TF2_GetPlayerClass(client);
			if(class != TFClass_Medic)
			{
				TF2_SetPlayerClass(client, TFClass_Medic);
				ForcePlayerSuicide(client);
				PrintToChat(client,"[AFK Bot] Setting your class to Medic.");
			}
		}
	}
}

public OnMapStart()
{
	CreateTimer(5.0, TellYourInAFKMODE,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(310.0, InfoTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:InfoTimer(Handle:timer)
{
	PrintToChatAll("This server is using AFK MedicBot plugin by tRololo312312");
}

public Action:Command_Afk(client, args)
{
	if(args != 0 && args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_afk <target> [0/1]");
		return Plugin_Handled;
	}

	if(args == 0)
	{
		if(!g_bAfkbot[client])
		{
			PrintToChat(client, "[SM] AfkBot enabled.");
			ForcePlayerSuicide(client);
			TF2_SetPlayerClass(client, TFClass_Medic);
			g_bAfkbot[client] = true;
		}
		else
		{
			PrintToChat(client, "[SM] AfkBot disabled.");
			PrintCenterText(client, "Your AfkBot is now Disabled");
			g_bAfkbot[client] = false;
		}
		return Plugin_Handled;
	}

	else if(args == 2)
	{
		decl String:arg1[PLATFORM_MAX_PATH];
		GetCmdArg(1, arg1, sizeof(arg1));
		decl String:arg2[8];
		GetCmdArg(2, arg2, sizeof(arg2));

		new value = StringToInt(arg2);
		if(value != 0 && value != 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_afk <target> [0/1]");
			return Plugin_Handled;
		}

		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS];
		new target_count;
		new bool:tn_is_ml;
		if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for(new i=0; i<target_count; i++) if(IsValidClient(target_list[i]))
		{
			if(value == 0)
			{
				if(CheckCommandAccess(client, "sm_afk_access", ADMFLAG_ROOT))
				{
					PrintToChat(target_list[i], "[SM] AfkBot disabled.");
					PrintCenterText(target_list[i], "Your AfkBot is now Disabled");
					g_bAfkbot[target_list[i]] = false;
				}
			}
			else
			{
				if(CheckCommandAccess(client, "sm_afk_access", ADMFLAG_ROOT))
				{
					PrintToChat(target_list[i], "[SM] AfkBot enabled.");
					ForcePlayerSuicide(target_list[i]);
					TF2_SetPlayerClass(target_list[i], TFClass_Medic);
					g_bAfkbot[target_list[i]] = true;
				}
			}
		}
	}

	return Plugin_Handled;
}

public Action:Command_AfkOff(client, const String:command[], argc)
{
	new String:args[5];
	GetCmdArgString(args, sizeof(args));
	if (!StrEqual(args, "0 0"))
	{
		return Plugin_Continue;
	}
	if(IsValidClient(client))
	{
		if(!g_bAfkbot[client])
			return Plugin_Continue;
		{
			if(IsPlayerAlive(client))
			{
				PrintToChat(client, "[SM] AfkBot disabled.");
				PrintCenterText(client, "Your AfkBot is now Disabled");
				g_bAfkbot[client] = false;
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

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
	if(IsValidClient(client))
	{
		if(!g_bAfkbot[client])
			return Plugin_Continue;
		{
			if(IsPlayerAlive(client))
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				if(class == TFClass_Medic)
				{
					decl Float:camangle[3], Float:clientEyes[3], Float:targetEyes[3];
					GetClientEyePosition(client, clientEyes);
					new Ent = Client_GetClosest(clientEyes, client);
					if(Ent != -1)
					{
						decl Float:vec[3],Float:angle[3];
						GetClientAbsOrigin(Ent, targetEyes);
						GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle); 
						targetEyes[2] += GetRandomFloat(20.0, 50.0);
						targetEyes[1] += GetRandomFloat(-10.0, 10.0);
						MakeVectorFromPoints(targetEyes, clientEyes, vec);
						GetVectorAngles(vec, camangle);
						camangle[0] *= -1.0;
						camangle[1] += 180.0;

						ClampAngle(camangle);
						TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
						if(JumpTimer == INVALID_HANDLE)
						{
							buttons |= IN_JUMP;
							JumpTimer = CreateTimer(3.0, ResetJumpTimer);
						}

						if(AttackTimer == INVALID_HANDLE)
						{
							AttackTimer = CreateTimer(1.5, ResetAttackTimer);
						}
						else
						{
							buttons |= IN_ATTACK;
						}

						if(GetClientButtons(Ent) & IN_ATTACK && GetClientTeam(Ent) == GetClientTeam(client))
						{
							buttons |= IN_ATTACK2;
						}

						new Float:location_check[3];
						GetClientAbsOrigin(client, location_check);

						new Float:chainDistance;
						chainDistance = GetVectorDistance(location_check,targetEyes);

						if(GetClientTeam(Ent) == GetClientTeam(client))
						{
							new iMeleeEnt = GetPlayerWeaponSlot(client, 1);
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iMeleeEnt);
						}
						else if(GetClientTeam(Ent) != GetClientTeam(client))
						{
							if(TF_GetUberLevel(client)>=100.00)
							{
								new iMeleeEnt = GetPlayerWeaponSlot(client, 1);
								SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iMeleeEnt);
								buttons |= IN_ATTACK2;
							}
							else if(chainDistance <145.0)
							{
								new iMeleeEnt = GetPlayerWeaponSlot(client, 2);
								SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iMeleeEnt);
							}
							else
							{
								new iMeleeEnt = GetPlayerWeaponSlot(client, 0);
								SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iMeleeEnt);
							}
						}

						if(chainDistance >=550.0 && GetClientTeam(Ent) != GetClientTeam(client))
						{
							// Changed to forced velocity instead getting speed of distance(3.4)
							vel = moveForward(vel,320.0);
						}
						else if(chainDistance >=150.0)
						{
							vel = moveForward(vel,chainDistance);
						}

						if(GetClientButtons(client) & IN_JUMP)
						{
							buttons |= IN_DUCK;
						}

						if(chainDistance >=50.0)
						{
							if(GetClientButtons(Ent) & IN_JUMP)
							{
								buttons |= IN_JUMP;
							}
							// Will not Duck if Enemy is target(3.4)
							if(GetClientButtons(Ent) & IN_DUCK  && GetClientTeam(Ent) == GetClientTeam(client))
							{
								buttons |= IN_DUCK;
							}
						}

						if(chainDistance <145.0 && GetClientTeam(Ent) != GetClientTeam(client))
						{
							// Changed to forced velocity instead getting speed of distance(3.4)
							vel = moveForward(vel,320.0);
							vel = moveSide(vel,320.0);
						}
						else if(chainDistance <500.0 && GetClientTeam(Ent) != GetClientTeam(client))
						{
							// Here too :3
							vel = moveBackwards(vel,320.0);
						}
						else if(chainDistance <145.0)
						{
							vel = moveBackwards(vel,chainDistance);
						}
					}
					else
					{
						decl Float:direction[3];
						// Loses Target and runs Forward(3.2)
						// Made bit slower to match Medics real speed(3.4)
						vel = moveForward(vel,320.0);

						// The New stuff starts from here.(3.8)
						if(JumpTimer == INVALID_HANDLE)
						{
							buttons |= IN_JUMP;
							JumpTimer = CreateTimer(3.0, ResetJumpTimer);
						}

						if(GetClientButtons(client) & IN_JUMP)
						{
							buttons |= IN_DUCK;
						}

						Handle Wall;
						GetClientEyeAngles(client, camangle);
						camangle[0] = 0.0;
						camangle[2] = 0.0;
						camangle[1] -= 40.0;
						GetAngleVectors(camangle, direction, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(direction, 50.0);
						AddVectors(clientEyes, direction, targetEyes);
						Wall = TR_TraceRayFilterEx(clientEyes,targetEyes,MASK_SOLID,RayType_EndPoint,Filter);
						if(TR_DidHit(Wall))
						{
							TR_GetEndPosition(targetEyes, Wall);
							new Float:chainDistance;
							chainDistance = GetVectorDistance(clientEyes,targetEyes);
							if(chainDistance <50.0)
							{
								new Float:newDirection[3];
								GetClientEyeAngles(client, newDirection);
								newDirection[1] += GetRandomFloat(-1.0, 360.0);
								TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
								//PrintToChat(client,"Wall detected");
							}
						}
						
						CloseHandle(Wall);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:ResetJumpTimer(Handle:timer)
{
	JumpTimer = INVALID_HANDLE;
}

public Action:ResetAttackTimer(Handle:timer)
{
	AttackTimer = INVALID_HANDLE;
}

bool:IsValidClient( client ) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

public Action:TellYourInAFKMODE(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(g_bAfkbot[client] && IsValidClient(client) && !IsFakeClient(client))
		{
			PrintToChat(client,"[AFK Bot] You are set AFK.\nType '!afk' [or press Medic Call button] in chat to get out of it.");
			//Center message thought up by Ra5ZeR. (SPYderman)
			PrintCenterText(client, "You are being controlled by a bot. Type !afk or press your Medic Call button to exit.");
		}
	}
}

#if defined _afk_manager_included
public Action:OnPlayerAFK(client)
{
	if(IsValidClient(client))
	{
		PrintToChat(client, "[SM] AfkBot enabled.");
		ForcePlayerSuicide(client);
		TF2_SetPlayerClass(client, TFClass_Medic);
		g_bAfkbot[client] = true;
	}

	// prevent sending to spec
	return Plugin_Stop;
}
#endif

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
		if(GetClientTeam(i) == GetClientTeam(client))
		{
			new TFClassType:class = TF2_GetPlayerClass(i);
			// Cloaked and Disguised players should be now undetectable(3.2)
			if(g_bAfkbot[i] && class == TFClass_Medic || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
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
		else if(GetClientTeam(i) != GetClientTeam(client))
		{	
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client) || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
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

//Fixed the spamming error message about chargelevel(3.7)
stock Float:TF_GetUberLevel(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if(IsValidEntity(index)
	&& (GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==29
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==211
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==35
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==411
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==663
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==796
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==805
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==885
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==894
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==903
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==912
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==961
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==970
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==998))
		return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100.0;
	else
		return 0.0;
}

stock TF_IsUberCharge(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if(IsValidEntity(index)
	&& (GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==29
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==211
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==35
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==411
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==663
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==796
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==805
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==885
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==894
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==903
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==912
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==961
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==970
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==998))
		return GetEntProp(index, Prop_Send, "m_bChargeRelease", 1);
	else
		return 0;
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
