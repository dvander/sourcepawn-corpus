#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
//Using Diablos modified AFK manager.
#tryinclude <afk_manager>

new g_bAfkbot[MAXPLAYERS+1];
new Handle:JumpTimer;
new Handle:AttackTimer;
new Handle:SnipeTimer;
new Handle:DontSnipeTimer;

// Removed my other account so it does not confuse others(3.2)
public Plugin:myinfo = 
{
	name = "MedicBot",
	author = "tRololo312312, edit by EfeDursun125",
	description = "Medic AI for afk players",
	version = "3.9",
	url = "http://steamcommunity.com/profiles/76561198039186809"
}

public OnPluginStart()
{
	// teamplay instead of arena(3.5)
	LoadTranslations("common.phrases.txt");
	RegConsoleCmd("sm_afk", Command_Afk);
	HookEvent("player_death", BotDie, EventHookMode_Post);

	// Medic Call hook(3.3)
	//AddCommandListener(Command_AfkOff, "voicemenu");
}

public OnMapStart()
{
	CreateTimer(5.0, TellYourInAFKMODE,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(300.0, InfoTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:InfoTimer(Handle:timer)
{
	PrintToChatAll("[AFK BOT] This server is using AFK BOT plugin type to chat !afk");
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
			if(IsValidClient(client))
			{
				TF2_RespawnPlayer(client);
			}
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
					TF2_SetPlayerClass(target_list[i], TFClass_Medic);
					if(IsValidClient(client))
					{
						TF2_RespawnPlayer(target_list[i]);
					}
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

Float:moveSide2(Float:vel[3],Float:MaxSpeed)
{
	vel[1] = -MaxSpeed;
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
				
				if(class != TFClass_Sniper && class != TFClass_Medic)
				{
					decl Float:camangle[3], Float:clientEyes[3], Float:clientEyes2[3], Float:targetEyes[3];
					GetClientEyePosition(client, clientEyes);
					new Ent = Client_GetClosest(clientEyes, client);
						
					if(Ent != -1 && TFClass_Sniper)
					{
						decl Float:vec[3],Float:angle[3];
						GetClientAbsOrigin(Ent, targetEyes);
						GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
						if(class == TFClass_Soldier)
						{
							targetEyes[2] += 2.5;
							targetEyes[1] += 0;
						}
						if(class == TFClass_DemoMan)
						{
							targetEyes[2] += 150;
							targetEyes[1] += 0;
						}
						if(class == TFClass_Pyro)
						{
							targetEyes[2] += 35;
							targetEyes[1] += GetRandomInt(-5, 5);
						}
						if(class == TFClass_Scout || class == TFClass_Heavy || class == TFClass_Engineer || class == TFClass_Spy)
						{
							targetEyes[2] += 50;
							targetEyes[1] += GetRandomInt(-1, 1);
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
						
						if(class == TFClass_Heavy)
						{
							if(GetClientButtons(client) & IN_ATTACK)
							{
								TF2_LookAtPos(client, targetEyes, 0.15); // Smooth Aim
							}
							else if(GetClientButtons(client) & IN_ATTACK2)
							{
								TF2_LookAtPos(client, targetEyes, 0.125); // Smooth Aim
							}
							else
							{
								TF2_LookAtPos(client, targetEyes, 0.1); // Smooth Aim
							}
						}
						
						if(class == TFClass_Soldier || class == TFClass_DemoMan)
						{
							if(GetEntityFlags(Ent) & FL_ONGROUND)
							{
								TF2_LookAtPos(client, targetEyes, 0.2); // Smooth Aim
							}
							else
							{
								TF2_LookAtPos(client, targetEyes, 0.1); // Smooth Aim
							}
						}
						
						if(class == TFClass_Scout || class == TFClass_Pyro || class == TFClass_Engineer || class == TFClass_Spy)
						{
							if(GetClientButtons(Ent) & IN_ATTACK)
							{
								TF2_LookAtPos(client, targetEyes, 0.15); // Smooth Aim
							}
							else if(GetClientButtons(client) & IN_ATTACK)
							{
								TF2_LookAtPos(client, targetEyes, 0.125); // Smooth Aim
							}
							else
							{
								TF2_LookAtPos(client, targetEyes, 0.1); // Smooth Aim
							}
						}
						
						//TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR); // Aimbot

						if(SnipeTimer == INVALID_HANDLE && TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						{
							SnipeTimer = CreateTimer(GetRandomFloat(1.5, 5.0), ResetSnipeTimer);
							buttons |= IN_ATTACK;
						}
						else if(TF2_GetPlayerClass(Ent) == TFClass_Sniper && TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						{
							buttons |= IN_ATTACK;
						}
						else if(!TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						{
							buttons |= IN_ATTACK2;
						}
						
						if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
						{
							buttons |= IN_ATTACK;
						}
						
						new random = GetRandomInt(1,3);
						switch(random)
						{
							case 1:
							{
								if(GetHealth(client) > 75.0)
								{
									if(chainDistance == 1250.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 1500.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
								else
								{
									if(chainDistance == 1750.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 2000.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
							}
							case 2:
							{
								if(GetHealth(client) > 75.0)
								{
									if(chainDistance == 1250.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 1750.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
								else
								{
									if(chainDistance == 2000.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 2250.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
							}
							case 3:
							{
								if(GetHealth(client) > 75.0)
								{
									if(chainDistance == 1750.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 2000.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
								else
								{
									if(chainDistance == 2250.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 1750.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
							}
						}

						if(GetClientButtons(client) & IN_JUMP)
						{
							vel = moveForward(vel,300.0);
							if(GetEntityFlags(client) & FL_ONGROUND)
							{
								// NOPE
							}
							else
							{
								buttons |= IN_DUCK;
							}
						}
						
						Handle Wall;
						decl Float:direction[3];
						GetClientEyeAngles(client, camangle);
						camangle[0] = 0.0;
						camangle[2] = 0.0;
						camangle[1] -= 40.0;
						GetAngleVectors(camangle, direction, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(direction, 75.0);
						AddVectors(clientEyes, direction, targetEyes);
						Wall = TR_TraceRayFilterEx(clientEyes,targetEyes,MASK_SOLID,RayType_EndPoint,Filter);
						if(TR_DidHit(Wall))
						{
							TR_GetEndPosition(targetEyes, Wall);
							new Float:wallDistance;
							wallDistance = GetVectorDistance(clientEyes,targetEyes);
							if(wallDistance < 75.0)
							{
								buttons |= IN_JUMP;
							}
						}
						
						CloseHandle(Wall);
					}
					else
					{
						// Loses Target and runs Forward(3.2)
						// Made bit slower to match Medics real speed(3.4)
						
						char currentMap[PLATFORM_MAX_PATH];
						GetCurrentMap(currentMap, sizeof(currentMap));
	
						if(StrContains(currentMap, "cp_" , false) != -1)
						{
							new ControlPoint = Client_GetClosest2(clientEyes2, client);
							if(ControlPoint != -1)
							{
								new TeamNumControlPoint = GetEntProp(ControlPoint, Prop_Send, "m_iTeamNum");
								if(GetClientTeam(client) != TeamNumControlPoint)
								{
									decl Float:vec[3],Float:angle[3],Float:fEntityLocation[3];
									GetEntPropVector(ControlPoint, Prop_Send, "m_vecOrigin", fEntityLocation);
									GetEntPropVector(ControlPoint, Prop_Data, "m_angRotation", angle);
									fEntityLocation[2] += 33.5;
									MakeVectorFromPoints(fEntityLocation, clientEyes2, vec);
									GetVectorAngles(vec, camangle);
									camangle[0] *= -1.0;
									camangle[1] += 180.0;
									ClampAngle(camangle);

									new Float:location_check[3];
									GetClientAbsOrigin(client, location_check);

									new Float:chainDistance;
									chainDistance = GetVectorDistance(location_check,targetEyes);

									if(IsPointVisibleTank(clientEyes2, fEntityLocation))
									{
										TF2_LookAtPos(client, fEntityLocation, 0.075); // Smooth Aim
									}
								}
							}
						}
						
						vel = moveForward(vel,300.0);

						if(GetClientButtons(client) & IN_JUMP)
						{
							if(GetEntityFlags(client) & FL_ONGROUND)
							{
								// NOPE
							}
							else
							{
								buttons |= IN_DUCK;
							}
						}
					}
				}
				
				if(class == TFClass_Sniper)
				{
					decl Float:camangle[3], Float:clientEyes[3], Float:targetEyes[3];
					GetClientEyePosition(client, clientEyes);
					new Ent = Client_GetClosest(clientEyes, client);
					
					if(DontSnipeTimer == INVALID_HANDLE && TF2_IsPlayerInCondition(client, TFCond_Zoomed) && Ent == -1 && TFClass_Sniper)
					{
						DontSnipeTimer = CreateTimer(GetRandomFloat(10.0, 20.0), ResetDontSnipeTimer);
						buttons |= IN_ATTACK2;
					}
					
					if(Ent != -1 && TFClass_Sniper)
					{
						decl Float:vec[3],Float:angle[3];
						GetClientAbsOrigin(Ent, targetEyes);
						GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
						new TFClassType:enemyclass = TF2_GetPlayerClass(Ent);
						if(enemyclass == TFClass_Sniper || enemyclass == TFClass_Medic || enemyclass == TFClass_Spy || enemyclass == TFClass_DemoMan)
						{
							targetEyes[2] += 70;
							targetEyes[1] += 0;
						}
						if(enemyclass == TFClass_Soldier || enemyclass == TFClass_Pyro)
						{
							targetEyes[2] += 65;
							targetEyes[1] += 0;
						}
						if(enemyclass == TFClass_Scout || enemyclass == TFClass_Engineer)
						{
							targetEyes[2] += 60;
							targetEyes[1] += 0;
						}
						if(enemyclass == TFClass_Heavy)
						{
							targetEyes[2] += 80;
							targetEyes[1] += 0;
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
						
						if(GetClientTeam(Ent) != GetClientTeam(client) && TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						{
							float AimRandomize1 = GetRandomFloat(0.24, 0.26);
							float AimRandomize2 = GetRandomFloat(0.18, 0.22);
							float AimRandomize3 = GetRandomFloat(0.14, 0.16);
							float AimRandomize4 = GetRandomFloat(0.08, 0.12);
							float AimRandomize5 = GetRandomFloat(0.06, 0.07);
							if(chainDistance > 2500.0)
							{
								TF2_LookAtPos(client, targetEyes, AimRandomize1); // Smooth Aim
							}
							if(chainDistance > 2000.0)
							{
								TF2_LookAtPos(client, targetEyes, AimRandomize2); // Smooth Aim
							}
							if(chainDistance > 1500.0)
							{
								TF2_LookAtPos(client, targetEyes, AimRandomize3); // Smooth Aim
							}
							if(chainDistance > 1000.0)
							{
								TF2_LookAtPos(client, targetEyes, AimRandomize4); // Smooth Aim
							}
							if(chainDistance > 500.0)
							{
								TF2_LookAtPos(client, targetEyes, AimRandomize5); // Smooth Aim
							}
							else
							{
								TF2_LookAtPos(client, targetEyes, 0.05); // Smooth Aim
							}
						}
						else
						{
							if(GetClientButtons(Ent) & IN_ATTACK)
							{
								TF2_LookAtPos(client, targetEyes, 0.15); // Smooth Aim
							}
							else if(GetClientButtons(client) & IN_ATTACK)
							{
								TF2_LookAtPos(client, targetEyes, 0.125); // Smooth Aim
							}
							else
							{
								TF2_LookAtPos(client, targetEyes, 0.1); // Smooth Aim
							}
						}
						
						//TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR); // Aimbot

						if(SnipeTimer == INVALID_HANDLE && TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						{
							SnipeTimer = CreateTimer(GetRandomFloat(1.5, 5.0), ResetSnipeTimer);
							buttons |= IN_ATTACK;
						}
						else if(TF2_GetPlayerClass(Ent) == TFClass_Sniper && TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						{
							buttons |= IN_ATTACK;
						}
						else if(!TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						{
							buttons |= IN_ATTACK2;
						}
						
						if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
						{
							buttons |= IN_ATTACK;
						}
						
						new random = GetRandomInt(1,3);
						switch(random)
						{
							case 1:
							{
								if(GetHealth(client) > 75.0)
								{
									if(chainDistance == 125.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 150.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
								else
								{
									if(chainDistance == 175.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 200.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
							}
							case 2:
							{
								if(GetHealth(client) > 75.0)
								{
									if(chainDistance == 125.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 175.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
								else
								{
									if(chainDistance == 200.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 225.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
							}
							case 3:
							{
								if(GetHealth(client) > 75.0)
								{
									if(chainDistance == 175.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 200.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
								else
								{
									if(chainDistance == 225.0)
									{
										vel = moveSide(vel,300.0);
									}
									if(chainDistance == 175.0)
									{
										vel = moveSide2(vel,300.0);
									}
								}
							}
						}

						if(GetClientButtons(client) & IN_JUMP)
						{
							vel = moveForward(vel,300.0);
							if(GetEntityFlags(client) & FL_ONGROUND)
							{
								// NOPE
							}
							else
							{
								buttons |= IN_DUCK;
							}
						}
						
						Handle Wall;
						decl Float:direction[3];
						GetClientEyeAngles(client, camangle);
						camangle[0] = 0.0;
						camangle[2] = 0.0;
						camangle[1] -= 40.0;
						GetAngleVectors(camangle, direction, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(direction, 75.0);
						AddVectors(clientEyes, direction, targetEyes);
						Wall = TR_TraceRayFilterEx(clientEyes,targetEyes,MASK_SOLID,RayType_EndPoint,Filter);
						if(TR_DidHit(Wall))
						{
							TR_GetEndPosition(targetEyes, Wall);
							new Float:wallDistance;
							wallDistance = GetVectorDistance(clientEyes,targetEyes);
							if(wallDistance < 75.0)
							{
								buttons |= IN_JUMP;
							}
						}
						
						CloseHandle(Wall);
					}
					else
					{
						// Loses Target and runs Forward(3.2)
						// Made bit slower to match Medics real speed(3.4)
						
						if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						{
							new random = GetRandomInt(1,100)
							if(random == 1)
							{
								vel = moveSide(vel,300.0);
							}
							if(random == 2)
							{
								vel = moveSide2(vel,300.0);
							}
						}
						else
						{
							vel = moveForward(vel,300.0);
						}

						if(GetClientButtons(client) & IN_JUMP)
						{
							if(GetEntityFlags(client) & FL_ONGROUND)
							{
								// NOPE
							}
							else
							{
								buttons |= IN_DUCK;
							}
						}
					}
				}
				
				if(class == TFClass_Medic)
				{
					decl Float:camangle[3], Float:clientEyes[3], Float:targetEyes[3];
					GetClientEyePosition(client, clientEyes);
					new Ent = Client_GetClosest(clientEyes, client);
					
					for (new searchenemy = 1; searchenemy <= MaxClients; searchenemy++ && class == TFClass_Medic)
					{
						if (IsClientInGame(searchenemy) && IsPlayerAlive(searchenemy) && searchenemy != client && (GetClientTeam(client) != GetClientTeam(searchenemy)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(searchenemy, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							new Float:chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin, searchOrigin);
								
							if(chainDistance4 < 1000.0 && GetClientButtons(searchenemy) & IN_ATTACK && GetHealth(client) < 75.0 && TF2_IsPlayerInCondition(searchenemy, TFCond_Zoomed))
							{
								buttons |= IN_DUCK;
							}
							else if(chainDistance4 < 1000.0 && GetClientButtons(searchenemy) & IN_ATTACK && GetHealth(client) < 75.0)
							{
								buttons |= IN_DUCK;
							}
						}
					}
					
					if(JumpTimer == INVALID_HANDLE)
					{
						JumpTimer = CreateTimer(5.0, ResetJumpTimer);
						for (new searchenemy = 1; searchenemy <= MaxClients; searchenemy++ && class == TFClass_Medic)
						{
							if (IsClientInGame(searchenemy) && IsPlayerAlive(searchenemy) && searchenemy != client && (GetClientTeam(client) != GetClientTeam(searchenemy)))
							{
								new Float:clientOrigin[3];
								new Float:searchOrigin[3];
								GetClientAbsOrigin(searchenemy, searchOrigin);
								GetClientAbsOrigin(client, clientOrigin);
							
								new Float:chainDistance3;
								chainDistance3 = GetVectorDistance(clientOrigin, searchOrigin);
					
								if(chainDistance3 < 2000.0 && TF2_IsPlayerInCondition(searchenemy, TFCond_Zoomed))
								{
									buttons |= IN_JUMP;
								}
								
								if(chainDistance3 < 200.0 && TF2_IsPlayerInCondition(searchenemy, TFCond_Disguised))
								{
									buttons |= IN_JUMP;
									vel = moveForward(vel,300.0);
								}
							}
						}
					}
						
					if(Ent != -1)
					{
						decl Float:vec[3],Float:angle[3];
						GetClientAbsOrigin(Ent, targetEyes);
						GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle); 
						targetEyes[2] += GetRandomFloat(69.0, 71.0);
						targetEyes[1] += GetRandomFloat(-1.0, 1.0);
						MakeVectorFromPoints(targetEyes, clientEyes, vec);
						GetVectorAngles(vec, camangle);
						camangle[0] *= -1.0;
						camangle[1] += 180.0;

						ClampAngle(camangle);
						
						new Float:location_check[3];
						GetClientAbsOrigin(client, location_check);

						new Float:chainDistance;
						chainDistance = GetVectorDistance(location_check,targetEyes);
						
						if(GetClientTeam(Ent) == GetClientTeam(client))
						{
							if(chainDistance < 500.0)
							{
								TF2_LookAtPos(client, targetEyes, 0.075); // Smooth Aim
							}
							else
							{
								TF2_LookAtPos(client, targetEyes, 0.05); // Smooth Aim
							}
						}
						
						if(GetClientTeam(Ent) != GetClientTeam(client))
						{
							if(chainDistance < 750.0)
							{
								TF2_LookAtPos(client, targetEyes, 0.095); // Smooth Aim
							}
							else
							{
								TF2_LookAtPos(client, targetEyes, 0.070); // Smooth Aim
							}
						}
						
						//TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR); // Aimbot

						if(AttackTimer == INVALID_HANDLE)
						{
							AttackTimer = CreateTimer(2.0, ResetAttackTimer);
						}
						else
						{
							buttons |= IN_ATTACK;
						}
						
						if(GetClientButtons(Ent) & IN_ATTACK && GetHealth(client) < 50.0)
						{
							buttons |= IN_ATTACK2;
						}

						if(GetClientTeam(Ent) == GetClientTeam(client))
						{
							new iMeleeEnt = GetPlayerWeaponSlot(client, 1);
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iMeleeEnt);
						}
						else if(GetClientTeam(Ent) != GetClientTeam(client))
						{
							if(TF_GetUberLevel(client)>=100.00 && GetHealth(client) < 50.0)
							{
								new iMeleeEnt = GetPlayerWeaponSlot(client, 1);
								SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iMeleeEnt);
								buttons |= IN_ATTACK2;
							}
							else if(chainDistance < 150.0 && GetHealth(client) > 100.0)
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
						
						if(chainDistance > 600.0 && chainDistance < 700.0)
						{
							vel = moveForward(vel,320.0);
						}
						
						if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) // For Save Ubercharge 3.9
						{
							buttons |= IN_ATTACK;
						}
						
						new random = GetRandomInt(1,3);
						switch(random)
						{
							case 1:
							{
								if(GetHealth(client) > 75.0)
								{
									if(chainDistance > 175.0)
									{
										vel = moveForward(vel,320.0);
									}
									if(chainDistance < 75.0)
									{
										vel = moveBackwards(vel,320.0);
									}
									if(chainDistance == 125.0)
									{
										vel = moveSide(vel,320.0);
									}
									if(chainDistance == 150.0)
									{
										vel = moveSide2(vel,320.0);
									}
								}
								else
								{
									if(chainDistance > 225.0)
									{
										vel = moveForward(vel,320.0);
									}
									if(chainDistance < 125.0)
									{
										vel = moveBackwards(vel,320.0);
									}
									if(chainDistance == 175.0)
									{
										vel = moveSide(vel,320.0);
									}
									if(chainDistance == 200.0)
									{
										vel = moveSide2(vel,320.0);
									}
								}
							}
							case 2:
							{
								if(GetHealth(client) > 75.0)
								{
									if(chainDistance > 200.0)
									{
										vel = moveForward(vel,320.0);
									}
									if(chainDistance < 50.0)
									{
										vel = moveBackwards(vel,320.0);
									}
									if(chainDistance == 125.0)
									{
										vel = moveSide(vel,320.0);
									}
									if(chainDistance == 175.0)
									{
										vel = moveSide2(vel,320.0);
									}
								}
								else
								{
									if(chainDistance > 250.0)
									{
										vel = moveForward(vel,320.0);
									}
									if(chainDistance < 150.0)
									{
										vel = moveBackwards(vel,320.0);
									}
									if(chainDistance == 200.0)
									{
										vel = moveSide(vel,320.0);
									}
									if(chainDistance == 225.0)
									{
										vel = moveSide2(vel,320.0);
									}
								}
							}
							case 3:
							{
								if(GetHealth(client) > 75.0)
								{
									if(chainDistance > 225.0)
									{
										vel = moveForward(vel,320.0);
									}
									if(chainDistance < 25.0)
									{
										vel = moveBackwards(vel,320.0);
									}
									if(chainDistance == 175.0)
									{
										vel = moveSide(vel,320.0);
									}
									if(chainDistance == 200.0)
									{
										vel = moveSide2(vel,320.0);
									}
								}
								else
								{
									if(chainDistance > 275.0)
									{
										vel = moveForward(vel,320.0);
									}
									if(chainDistance < 175.0)
									{
										vel = moveBackwards(vel,320.0);
									}
									if(chainDistance == 225.0)
									{
										vel = moveSide(vel,320.0);
									}
									if(chainDistance == 175.0)
									{
										vel = moveSide2(vel,320.0);
									}
								}
							}
						}
						
						if(chainDistance < 100.0 && TF2_GetPlayerClass(Ent) == TFClass_Medic && GetClientTeam(Ent) == GetClientTeam(client) && g_bAfkbot[Ent])
						{
							vel = moveForward(vel,320.0);
						}

						if(GetClientButtons(client) & IN_JUMP)
						{
							vel = moveForward(vel,320.0);
							if(GetEntityFlags(client) & FL_ONGROUND)
							{
								// NOPE
							}
							else
							{
								buttons |= IN_DUCK;
							}
						}

						if(chainDistance <150.0 && GetClientTeam(Ent) != GetClientTeam(client))
						{
							// Changed to forced velocity instead getting speed of distance(3.4)
							vel = moveForward(vel,320.0);
							vel = moveSide(vel,320.0);
						}
						else if(chainDistance <750.0 && GetClientTeam(Ent) != GetClientTeam(client))
						{
							// Here too :3
							vel = moveBackwards(vel,320.0);
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
						
						Handle Wall;
						decl Float:direction[3];
						GetClientEyeAngles(client, camangle);
						camangle[0] = 0.0;
						camangle[2] = 0.0;
						camangle[1] -= 40.0;
						GetAngleVectors(camangle, direction, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(direction, 75.0);
						AddVectors(clientEyes, direction, targetEyes);
						Wall = TR_TraceRayFilterEx(clientEyes,targetEyes,MASK_SOLID,RayType_EndPoint,Filter);
						if(TR_DidHit(Wall))
						{
							TR_GetEndPosition(targetEyes, Wall);
							new Float:wallDistance;
							wallDistance = GetVectorDistance(clientEyes,targetEyes);
							if(wallDistance < 75.0)
							{
								buttons |= IN_JUMP;
							}
						}
						
						CloseHandle(Wall);
					}
					else
					{
						// Loses Target and runs Forward(3.2)
						// Made bit slower to match Medics real speed(3.4)
						
						vel = moveForward(vel,320.0);

						if(GetClientButtons(client) & IN_JUMP)
						{
							if(GetEntityFlags(client) & FL_ONGROUND)
							{
								// NOPE
							}
							else
							{
								buttons |= IN_DUCK;
							}
						}
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

public Action:ResetSnipeTimer(Handle:timer)
{
	SnipeTimer = INVALID_HANDLE;
}

public Action:ResetDontSnipeTimer(Handle:timer)
{
	DontSnipeTimer = INVALID_HANDLE;
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

public Action:BotDie(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attacker");
	new botid =  GetClientOfUserId(attacker);
	
	if(IsValidClient(botid))
	{
		if(IsPlayerAlive(botid))
		{
			new random = GetRandomInt(1,20);
			if(random == 1)
			{
				FakeClientCommand(botid, "taunt");
			}
		}
	}
}

stock Client_GetClosest(Float:vecOrigin_center[3], const client)
{    
	decl Float:vecOrigin_edict[3];
	decl Float:client_origin[3];
	new Float:distance = -1.0;
	new closestEdict = -1;
	for(new i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", client_origin);
		new Float:PlayerDistance;
		PlayerDistance = GetVectorDistance(client_origin, vecOrigin_edict);
		GetClientEyePosition(i, vecOrigin_edict);
		new TFClassType:medic = TF2_GetPlayerClass(client);
		if(GetClientTeam(i) == GetClientTeam(client) && medic == TFClass_Medic)
		{
			new TFClassType:class = TF2_GetPlayerClass(i);
			// Cloaked and Disguised players should be now undetectable(3.2)
			if(GetHealth(i) >= 150.0 && class == TFClass_Medic || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || GetHealth(i) >= 125.0 && TF2_IsPlayerInCondition(i, TFCond_Disguised) || class == TFClass_Engineer && IsWeaponSlotActive(i,2) && GetHealth(i) >= 125.0 || GetHealth(i) >= 125.0 && TF2_IsPlayerInCondition(i, TFCond_Zoomed) || TF2_IsPlayerInCondition(i, TFCond_Teleporting) || TF2_IsPlayerInCondition(i, TFCond_Disguising))
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
			if (TF_IsUberCharge(client) || PlayerDistance > 750.0 && TF2_IsPlayerInCondition(i, TFCond_Cloaked) || PlayerDistance > 75.0 && TF2_IsPlayerInCondition(i, TFCond_Disguised) || TF2_IsPlayerInCondition(i, TFCond_Taunting))
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

stock Client_GetClosest2(Float:vecOrigin_center[3], const client)
{    
	decl Float:vecOrigin_edict[3];
	decl Float:client_origin[3];
	new Float:distance = -1.0;
	new closestEdict = -1;
	new ControlPoints = -1;
	if((ControlPoints = FindEntityByClassname(ControlPoints, "team_control_point")) != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ControlPoints, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", client_origin);
		GetEntPropVector(ControlPoints, Prop_Data, "m_angRotation", vecOrigin_edict);
		new iTeamNumPoint = GetEntProp(ControlPoints, Prop_Send, "m_iTeamNum");
		if(iTeamNumPoint != GetClientTeam(client))
		{	
			if(IsPointVisibleTank(vecOrigin_center, vecOrigin_edict))
			{
				new Float:edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					closestEdict = ControlPoints;
				}
			}
		}
	}
	return closestEdict;
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

stock GetHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock GetAmmo(client)
{
	return FindSendPropInfo("CTFPlayer", "m_iAmmo");
}

stock bool:IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
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

stock bool:IsPointVisibleTank(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.9;
}

public bool:TraceEntityFilterStuffTank(entity, mask)
{
	new maxentities = GetMaxEntities();
	return entity > maxentities;
}

public bool:Filter(entity,mask)
{
	return !(IsValidClient(entity));
}
  