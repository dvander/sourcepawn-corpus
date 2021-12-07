#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <smlib>

#define PLUGIN_VERSION  "3.9"
#define PLUGIN_CONFIG "cfg/sourcemod/plugin.tfbotimprove.cfg"

public Plugin:myinfo = 
{
	name = "TF2 Improved Bots",
	author = "EfeDursun125",
	description = "TFBots now uses voice commands and combat improve.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

new g_iOffsetCloak;

new Handle:TimerVeryLow;
new Handle:TimerLow;
new Handle:TimerNormal;
new Handle:TimerHigh;

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

ConVar g_hCVOnUberedAlwaysMoveForward;
ConVar g_hCVSpyBotAlwaysForceCloak;
ConVar g_hCVSpyBotAlwaysForceCloakOnlyTeam;

public OnPluginStart()
{
	CreateConVar("sm_tf_bot_improve_version", PLUGIN_VERSION, "TFBot Improver Plugin Version", FCVAR_NONE);
	g_hCVOnUberedAlwaysMoveForward = CreateConVar("tf_bot_on_ubercharged_always_move_forward", "1", " ", FCVAR_NONE, true, 1.0, false, 0.0);
	g_hCVSpyBotAlwaysForceCloak = CreateConVar("tf_bot_spy_always_force_cloak_on_disguise_lost", "1", "0 = Spy bots only use cloak on health low than 60; 1 = Spy bots always use cloak on disguise lost", FCVAR_NONE, true, 1.0, false, 0.0);
	g_hCVSpyBotAlwaysForceCloakOnlyTeam = CreateConVar("tf_bot_spy_always_force_cloak_only_blu_team", "1", "Makes only blu team always use force cloak", FCVAR_NONE, true, 1.0, false, 0.0);
	HookEvent("player_hurt", BotHurt, EventHookMode_Post);
	HookEvent("player_death", hookPlayerDie, EventHookMode_Post);
	AddServerTag("advancedbots");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				new team = GetClientTeam(client);
				new m_iStunFlags = FindSendPropInfo("CTFPlayer","m_iStunFlags");
				new stunFlag = GetEntData(client, m_iStunFlags);
				
				if(TimerVeryLow == INVALID_HANDLE)
				{
					TimerVeryLow = CreateTimer(2.0, ResetTimerVeryLow);
				}
				
				if(TimerVeryLow == INVALID_HANDLE && class == TFClass_Medic && GetHealth(client) > 75.0)
				{
					buttons |= IN_ATTACK;
				}
				
				if(TimerLow == INVALID_HANDLE)
				{
					TimerLow = CreateTimer(10.0, ResetTimerLow);
				}
				
				if(TimerNormal == INVALID_HANDLE)
				{
					TimerNormal = CreateTimer(20.0, ResetTimerNormal);
				}
				
				if(TimerHigh == INVALID_HANDLE)
				{
					TimerHigh = CreateTimer(30.0, ResetTimerHigh);
				}
				
				if(GetConVarBool(g_hCVOnUberedAlwaysMoveForward))
				{
					if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && team == 3 || team == 2 && TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && class != TFClass_Medic)
					{
						vel = moveForward(vel,300.0);
					}
				}
				
				if(class == TFClass_Spy && GetConVarBool(g_hCVSpyBotAlwaysForceCloakOnlyTeam))
				{
					if(GetConVarBool(g_hCVSpyBotAlwaysForceCloak))
					{
						if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && class == TFClass_Spy && team == 3)
						{
							buttons |= IN_FORWARD;
						}
						else if(!TF2_IsPlayerInCondition(client, TFCond_Cloaked) && GetHealth(client) < 125.0)
						{
							buttons |= IN_ATTACK2;
							buttons |= IN_BACK;
						}
					}
					else
					{
						if(class == TFClass_Spy && GetHealth(client) < 60.0)
						{
							if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && team == 3)
							{
								buttons |= IN_FORWARD;
							}
							else if(!TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK2;
								buttons |= IN_BACK;
							}
						}
					}
				}
				else if(class == TFClass_Spy)
				{
					if(GetConVarBool(g_hCVSpyBotAlwaysForceCloak))
					{
						if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && class == TFClass_Spy)
						{
							buttons |= IN_FORWARD;
						}
						else if(!TF2_IsPlayerInCondition(client, TFCond_Cloaked) && GetHealth(client) < 125.0)
						{
							buttons |= IN_ATTACK2;
							buttons |= IN_BACK;
						}
					}
					else
					{
						if(class == TFClass_Spy && GetHealth(client) < 60.0)
						{
							if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && team == 3)
							{
								buttons |= IN_FORWARD;
							}
							else if(!TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK2;
								buttons |= IN_BACK;
							}
						}
					}
				}
				
				if(class == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_Bleeding) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
					buttons |= IN_ATTACK2;
					vel = moveBackwards(vel,300.0);
				}
				
				if(class == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_OnFire) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
					buttons |= IN_ATTACK2;
					vel = moveBackwards(vel,300.0);
				}
				
				if(class == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_Jarated) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
					buttons |= IN_ATTACK2;
					vel = moveBackwards(vel,300.0);
				}
				
				if(class == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_Milked) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
					buttons |= IN_ATTACK2;
					vel = moveBackwards(vel,300.0);
				}
				
				if(TimerVeryLow == INVALID_HANDLE && TF2_IsPlayerInCondition(client, TFCond_OnFire))
				{
					buttons |= IN_JUMP;
				}
				
				if(TimerLow == INVALID_HANDLE && TF2_IsPlayerInCondition(client, TFCond_Bleeding))
				{
					buttons |= IN_JUMP;
				}
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Scout && IsWeaponSlotActive(client, 0))
				{
					if(TimerVeryLow == INVALID_HANDLE)
					{
						buttons |= IN_JUMP;
					}
				}
				
				if(TimerVeryLow == INVALID_HANDLE && class == TFClass_Scout && IsWeaponSlotActive(client, 2))
				{
					buttons |= IN_ATTACK2;
				}
				
				if(TimerVeryLow == INVALID_HANDLE && GetClientButtons(client) & IN_ATTACK && class == TFClass_Medic && IsWeaponSlotActive(client, 1))
				{
					buttons |= IN_JUMP;
				}
				
				if(TimerVeryLow == INVALID_HANDLE && class == TFClass_Scout && IsWeaponSlotActive(client, 0))
				{
					if(TimerVeryLow == INVALID_HANDLE)
					{
						buttons |= IN_ATTACK2;
					}
				}
				
				if(TimerVeryLow == INVALID_HANDLE && class == TFClass_Engineer && IsWeaponSlotActive(client, 2))
				{
					buttons |= IN_ATTACK;
				}
				
				if(TimerVeryLow == INVALID_HANDLE && class == TFClass_Engineer && IsWeaponSlotActive(client, 1))
				{
					buttons |= IN_ATTACK2;
				}
				
				if(TimerVeryLow == INVALID_HANDLE && class == TFClass_Engineer && IsWeaponSlotActive(client, 0))
				{
					buttons |= IN_ATTACK2;
				}
				
				if(class == TFClass_Medic && IsWeaponSlotActive(client, 2) && GetHealth(client) < 150.0)
				{
					if(TimerVeryLow == INVALID_HANDLE)
					{
			    		FakeClientCommand(client, "taunt");
				    }
				}
				if(class == TFClass_Medic && IsWeaponSlotActive(client, 0) && GetHealth(client) < 20.0)
				{
					if(TimerLow == INVALID_HANDLE)
					{
			    		FakeClientCommand(client, "taunt");
				    }
				}
				
				if(stunFlag == TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT)
				{
			    	vel = moveBackwards(vel,300.0);
				}
				
				if(class == TFClass_Scout)
				{
					if(buttons & IN_JUMP)
					{
						buttons |= IN_JUMP;
					}
				}
				
				if(GetClientButtons(client) & IN_JUMP && class == TFClass_Scout)
				{
					new random = GetRandomInt(1,4);
					switch(random)
					{
						case 1:
					    {
					        buttons |= IN_JUMP;
					    }
						case 2:
					    {
					        buttons |= IN_DUCK;
					    }
						case 3:
					    {
					        vel = moveForward(vel,300.0);
					    }
						case 4:
					    {
					        buttons |= IN_JUMP;
					    }
					}
				}
				
				if(TimerVeryLow == INVALID_HANDLE && GetClientButtons(client) & IN_ATTACK && GetClientButtons(client) & IN_DUCK && class == TFClass_Engineer && IsWeaponSlotActive(client, 2))
				{
					new random = GetRandomInt(1,20);
					switch(random)
					{
						case 1:
					    {
					        vel = moveSide(vel,150.0);
					    }
						case 2:
					    {
					        vel = moveSide2(vel,150.0);
					    }
						case 3:
					    {
					        vel = moveBackwards(vel,150.0);
					    }
						case 4:
					    {
					        vel = moveForward(vel,150.0);
					    }
					}
				}
				
				if(GetClientButtons(client) & IN_ATTACK && IsWeaponSlotActive(client, 2) && class != TFClass_Engineer && class != TFClass_Sniper && class != TFClass_DemoMan)
				{
					vel = moveForward(vel,300.0);
				}
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Sniper && IsWeaponSlotActive(client, 1))
				{
					if(TimerVeryLow == INVALID_HANDLE)
					{
						new random = GetRandomInt(1,5);
						switch(random)
						{
					   	    case 1:
					        {
					            buttons |= IN_JUMP;
					        }
						    case 2:
					        {
					            vel = moveSide(vel,300.0);
					        }
					    	case 3:
					        {
					            vel = moveSide2(vel,300.0);
					        }
							case 4:
					        {
					            vel = moveBackwards(vel,300.0);
					        }
							case 5:
					        {
					            vel = moveForward(vel,300.0);
					        }
						}
					}
				}
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Sniper && IsWeaponSlotActive(client, 2))
				{
					vel = moveForward(vel,300.0);
				}
				
				if(GetClientButtons(client) & IN_ATTACK2 && class == TFClass_Sniper && IsWeaponSlotActive(client, 0))
				{
					if(TimerVeryLow == INVALID_HANDLE)
					{
						new random = GetRandomInt(1,3);
						switch(random)
						{
							case 1:
					    	{
					        	vel = moveSide(vel,300.0);
					    	}
							case 2:
					    	{
					        	vel = moveSide2(vel,300.0);
					    	}
							case 3:
					    	{
					        	buttons |= IN_DUCK;
							}
					    }
					}
				}
				
				if(GetClientButtons(client) & IN_JUMP && class == TFClass_Medic)
				{
					vel = moveForward(vel,300.0);
				}
				
				if(TimerVeryLow == INVALID_HANDLE && GetClientButtons(client) & IN_ATTACK && class == TFClass_Heavy)
				{
					vel = moveForward(vel,230.0);
					buttons |= IN_JUMP;
				}
				
				if(TimerVeryLow == INVALID_HANDLE && GetClientButtons(client) & IN_ATTACK2 && class == TFClass_Heavy)
				{
					vel = moveForward(vel,230.0);
					buttons |= IN_JUMP;
				}
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_DemoMan && IsWeaponSlotActive(client, 2))
				{
					vel = moveForward(vel,280.0);
					buttons |= IN_ATTACK2;
				}
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Pyro && GetHealth(client) > 100.0 && IsWeaponSlotActive(client, 0))
				{
					vel = moveForward(vel,300.0);
				}
				
				if(GetClientButtons(client) & IN_ATTACK2 && class == TFClass_Pyro && GetHealth(client) < 100.0)
				{
				 	buttons |= IN_JUMP;
				}
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Scout && IsWeaponSlotActive(client, 0))
				{
					if(TimerVeryLow == INVALID_HANDLE)
					{
						buttons |= IN_JUMP;
					}
					else
					{
						vel = moveForward(vel,400.0);
					}
				}
				
				if(TimerVeryLow == INVALID_HANDLE && GetClientButtons(client) & IN_JUMP && class == TFClass_Scout)
				{
					new random = GetRandomInt(1,2);
					switch(random)
					{
					    case 1:
					    {
						    vel = moveSide(vel,400.0);
					    }
						case 2:
					    {
						    vel = moveSide2(vel,400.0);
						}
					}
				}
				
				if(GetClientButtons(client) & IN_ATTACK && TF2_IsPlayerInCondition(client, TFCond_Bleeding))
				{
					vel = moveBackwards(vel,300.0);
				}
				
				if(GetClientButtons(client) & IN_ATTACK && TF2_IsPlayerInCondition(client, TFCond_OnFire))
				{
					vel = moveBackwards(vel,300.0);
				}
				
				if(GetClientButtons(client) & IN_ATTACK && TF2_IsPlayerInCondition(client, TFCond_Milked))
				{
					vel = moveBackwards(vel,300.0);
				}
				
				if(GetClientButtons(client) & IN_ATTACK && TF2_IsPlayerInCondition(client, TFCond_Jarated))
				{
					vel = moveBackwards(vel,300.0);
				}
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Heavy && IsWeaponSlotActive(client, 0) && GetHealth(client) < 150.0)
				{
					vel = moveBackwards(vel,230.0);
					buttons |= IN_ATTACK2;
				}
				
				if(TimerVeryLow == INVALID_HANDLE && class == TFClass_Heavy && IsWeaponSlotActive(client, 1) && GetHealth(client) > 250.0)
				{
					buttons |= IN_ATTACK2;
				}
				
				if(class == TFClass_Scout && GetHealth(client) > 125.0 && IsWeaponSlotActive(client, 2))
				{
					vel = moveForward(vel,400.0);
				}
				
				if(class == TFClass_Heavy && IsWeaponSlotActive(client, 1) && GetHealth(client) < 250.0)
				{
					buttons |= IN_ATTACK;
				}
				
				if(TimerVeryLow == INVALID_HANDLE && GetClientButtons(client) & IN_ATTACK && class == TFClass_Medic && GetHealth(client) >= 100.0 && IsWeaponSlotActive(client, 1))
				{
					new random = GetRandomInt(1,7);
					switch(random)
					{
					    case 1:
					    {
					        vel = moveForward(vel,300.0);
					    }
						case 2:
					    {
					        buttons |= IN_JUMP;
					    }
						case 3:
					    {
					        vel = moveBackwards(vel,300.0);
					    }
						case 4:
					    {
					        buttons |= IN_ATTACK;
					    }
						case 5:
					    {
					        buttons |= IN_DUCK;
					    }
						case 6:
					    {
					        vel = moveSide(vel,300.0);
					    }
						case 7:
					    {
					        vel = moveSide2(vel,300.0);
					    }
					}
				}
				
				if(GetClientButtons(client) & IN_ATTACK2 && class == TFClass_Medic)
				{
					buttons |= IN_JUMP;
				}
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Heavy && TF2_IsPlayerInCondition(client, TFCond_Overhealed))
				{
					vel = moveForward(vel,300.0);
				}
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Soldier && GetHealth(client) < 125.0)
				{
					if(TimerLow == INVALID_HANDLE)
					{
						buttons |= IN_JUMP;
					}
				}
				
				if(class == TFClass_Sniper)
				{
					if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
					{
		 				SetEntProp(client, Prop_Send, "m_iHideHUD", 5);
						new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
						SetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage", 150.0); 
					}
					else 	
					{
						SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
					}
				}
				
				if(class != TFClass_Medic)
				{
					SetVariantInt(1);
					AcceptEntityInput(client, "SetForcedTauntCam");
				}
				
				if(class == TFClass_Spy && buttons & IN_ATTACK2 && TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
				{
					buttons &= ~IN_ATTACK2;
				}
				
				new Cart;
				if(class != TFClass_Medic && class != TFClass_Spy && class != TFClass_Sniper && class != TFClass_Engineer)
				{
					if((Cart = FindEntityByClassname(Cart, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE && class == TFClass_Medic)
					{
						if(IsValidEntity(Cart))
						{
							float fEntityLocation[3];
							new Float:clientOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(Cart, Prop_Send, "m_vecOrigin", fEntityLocation);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,fEntityLocation);

							if(chainDistance2 < 300.0 && chainDistance2 > 100.0)
							{
								vel = moveBackwards(vel,300.0);
							}
						}
					}
				}
				
				if(class == TFClass_Engineer)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 > 1000.0 && IsWeaponSlotActive(client, 2) && buttons & IN_ATTACK)
							{
								if(class == TFClass_Engineer && buttons & IN_FORWARD)
								{
									buttons &= ~IN_FORWARD;
								}
							}
							
							if(chainDistance2 > 1000.0 && IsWeaponSlotActive(client, 2))
							{
								if(class == TFClass_Engineer && buttons & IN_DUCK)
								{
									buttons &= ~IN_DUCK;
								}
							}
						}
					}
				}
				
				if(class == TFClass_Pyro)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 250.0 && IsWeaponSlotActive(client, 0) && TF2_IsPlayerInCondition(search, TFCond_Ubercharged))
							{
								buttons |= IN_ATTACK2;
							}
							else if(chainDistance2 < 1250.0 && IsWeaponSlotActive(client, 0) && TF2_IsPlayerInCondition(search, TFCond_Ubercharged))
							{
								vel = moveForward(vel,300.0);
							}
						}
					}
				}
				
				if(class != TFClass_Medic)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 200.0 && IsWeaponSlotActive(search, 2) && otherclass == TFClass_Heavy)
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Secondary)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 1));
								}
							}
						}
					}
				}
				
				if(class != TFClass_Medic)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 200.0 && GetHealth(search) < 100.0 && otherclass == TFClass_Medic && TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
							{
								vel = moveBackwards(vel,300.0);
							}
							else if(chainDistance2 > 400.0 && GetHealth(search) < 100.0 && otherclass == TFClass_Medic && TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
							{
								vel = moveForward(vel,300.0);
							}
						}
					}
				}
				
				if(class == TFClass_Pyro && team == 2)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 250.0 && otherclass == TFClass_Pyro)
							{
								buttons |= IN_ATTACK2;
								vel = moveBackwards(vel,300.0);
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Primary)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 0));
								}
							}
							else if(chainDistance2 < 750.0 && otherclass == TFClass_Pyro)
							{
								Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 1));
							}
						}
					}
				}
				
				if(class == TFClass_Heavy)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);
							
							if(chainDistance2 < 1000.0 && otherclass != TFClass_Medic && otherclass != TFClass_Engineer && otherclass != TFClass_Sniper && otherclass != TFClass_Scout && otherclass != TFClass_Spy && IsWeaponSlotActive(client, 0))
							{
								buttons |= IN_ATTACK2;
							}
						}
					}
				}
				
				if(class == TFClass_Scout || class == TFClass_Medic || class == TFClass_Engineer)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 200.0 && GetHealth(client) > 100.0 && otherclass != TFClass_Pyro && class == TFClass_Scout && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
								vel = moveSide2(vel,300.0);
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Melee)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 2));
								}
							}
							else if(chainDistance2 < 100.0 && otherclass != TFClass_Pyro && class == TFClass_Scout && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK;
								vel = moveSide(vel,300.0);
								vel = moveForward(vel,300.0);
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Melee)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 2));
								}
							}
							
							if(chainDistance2 < 150.0 && GetHealth(client) > 100.0 && otherclass != TFClass_Pyro && class == TFClass_Medic && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
								vel = moveSide2(vel,300.0);
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Melee)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 2));
								}
							}
							else if(chainDistance2 < 75.0 && otherclass != TFClass_Pyro && class == TFClass_Medic && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK;
								vel = moveSide(vel,300.0);
								vel = moveBackwards(vel,300.0);
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Melee)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 2));
								}
							}
							
							if(chainDistance2 < 150.0 && GetHealth(client) > 125.0 && otherclass != TFClass_Pyro && class == TFClass_Engineer && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK;
								vel = moveBackwards(vel,300.0);
								vel = moveSide(vel,300.0);
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Melee)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 2));
								}
							}
							else if(chainDistance2 < 75.0 && otherclass != TFClass_Pyro && class == TFClass_Engineer && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK;
								vel = moveSide2(vel,300.0);
								vel = moveForward(vel,300.0);
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Melee)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 2));
								}
							}
						}
					}
				}
				
				if(class == TFClass_Pyro && team == 3)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 150.0 && otherclass == TFClass_Pyro)
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Melee)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 2));
								}
							}
							else if(chainDistance2 < 500.0 && otherclass == TFClass_Pyro)
							{
								Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 0));
								vel = moveForward(vel,300.0);
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Primary)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 0));
								}
							}
						}
					}
				}
				
				if(class == TFClass_Soldier)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 250.0 && otherclass == TFClass_Pyro && class == TFClass_Soldier && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
							{
								buttons |= IN_JUMP;
								buttons |= IN_ATTACK;
								vel = moveBackwards(vel,300.0);
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Secondary)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 1));
								}
							}
							else if(chainDistance2 < 500.0 && otherclass == TFClass_Pyro && class == TFClass_Soldier && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
							{
								buttons |= IN_ATTACK;
								new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
								if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == TFWeaponSlot_Secondary)
								{
									Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 1));
								}
							}
							else if(chainDistance2 < 750.0 && otherclass == TFClass_Pyro && class == TFClass_Soldier && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
							{
								vel = moveBackwards(vel,300.0);
							}
						}
					}
				}
				
				if(class == TFClass_Pyro)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							new TFClassType:otherclass = TF2_GetPlayerClass(search);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 250.0 && IsWeaponSlotActive(client, 0) && TF2_IsPlayerInCondition(search, TFCond_OnFire))
							{
								buttons |= IN_ATTACK2;
							}
							
							if(chainDistance2 < 250.0 && IsWeaponSlotActive(client, 0) && otherclass == TFClass_Engineer)
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
							else if(chainDistance2 < 250.0 && IsWeaponSlotActive(client, 0) && otherclass == TFClass_Sniper)
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
							else if(chainDistance2 < 250.0 && IsWeaponSlotActive(client, 0) && otherclass == TFClass_Spy)
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
						}
					}
				}
				
				if(class == TFClass_Spy)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 500.0 && TF2_IsPlayerInCondition(search, TFCond_Ubercharged))
							{
								buttons |= IN_ATTACK2;
							}
						}
					}
				}
				
				if(class == TFClass_Pyro)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 1000.0 && IsWeaponSlotActive(client, 0) && otherclass == TFClass_Spy && TF2_IsPlayerInCondition(search, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
							else if(chainDistance2 < 1000.0 && IsWeaponSlotActive(client, 0) && otherclass == TFClass_Spy && TF2_IsPlayerInCondition(search, TFCond_Jarated))
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
							else if(chainDistance2 < 1000.0 && IsWeaponSlotActive(client, 0) && otherclass == TFClass_Spy && TF2_IsPlayerInCondition(search, TFCond_OnFire))
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
							else if(chainDistance2 < 1000.0 && IsWeaponSlotActive(client, 0) && otherclass == TFClass_Spy && TF2_IsPlayerInCondition(search, TFCond_Bleeding))
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
							else if(chainDistance2 < 1000.0 && IsWeaponSlotActive(client, 0) && otherclass == TFClass_Spy && TF2_IsPlayerInCondition(search, TFCond_Milked))
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
							else if(chainDistance2 < 2000.0 && IsWeaponSlotActive(client, 0) && otherclass == TFClass_Spy && TF2_IsPlayerInCondition(search, TFCond_DeadRingered))
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
							else if(chainDistance2 < 2000.0 && IsWeaponSlotActive(client, 0) && otherclass == TFClass_Spy && TF2_IsPlayerInCondition(search, TFCond_Disguising))
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
							else if(IsWeaponSlotActive(client, 0) && otherclass == TFClass_Spy && TF2_IsPlayerInCondition(search, TFCond_Taunting))
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
							else if(IsWeaponSlotActive(client, 0) && otherclass == TFClass_Spy && TF2_IsPlayerInCondition(search, TFCond_Bonked))
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
							else if(chainDistance2 < 100.0 && IsWeaponSlotActive(client, 0) && otherclass == TFClass_Spy)
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
							}
						}
					}
				}
				
				if(class == TFClass_Spy)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							if(otherclass == TFClass_Medic && TF2_IsPlayerInCondition(search, TFCond_Healing) && TF2_IsPlayerInCondition(client, TFCond_Overhealed) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK2;
							}
						}
					}
				}
				
				if(class == TFClass_Spy)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);
							
							if(otherclass == TFClass_Spy && chainDistance2 < 200.0 && TF2_IsPlayerInCondition(client, TFCond_Disguised))
							{
								vel = moveBackwards(vel,300.0);
							}
							
							if(otherclass == TFClass_Spy && chainDistance2 < 400.0 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && TF2_IsPlayerInCondition(search, TFCond_Cloaked))
							{
								vel = moveBackwards(vel,300.0);
								buttons |= IN_ATTACK2;
							}
						}
					}
				}
				
				if(class == TFClass_Engineer && GetClientButtons(client) & IN_DUCK || class == TFClass_Sniper)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);
							
							if(otherclass == TFClass_Spy && chainDistance2 < 100.0 && TF2_IsPlayerInCondition(search, TFCond_Cloaked))
							{
								vel = moveBackwards(vel,300.0);
								buttons |= IN_ATTACK;
								buttons |= IN_JUMP;
							}
							else if(otherclass == TFClass_Spy && chainDistance2 < 200.0 && TF2_IsPlayerInCondition(search, TFCond_Cloaked))
							{
								vel = moveBackwards(vel,300.0);
								buttons |= IN_ATTACK;
							}
							else if(otherclass == TFClass_Spy && chainDistance2 > 200.0 && chainDistance2 < 300.0 && TF2_IsPlayerInCondition(search, TFCond_DeadRingered))
							{
								vel = moveForward(vel,300.0);
							}
						}
					}
				}
				
				if(class == TFClass_Spy)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);
							
							if(chainDistance2 < 600.0 && otherclass == TFClass_Pyro && IsWeaponSlotActive(search, 0) && GetClientButtons(search) & IN_ATTACK)
							{
								vel = moveBackwards(vel,300.0);
							}
						}
					}
				}
				
				if(class == TFClass_Medic)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 1000.0 && IsWeaponSlotActive(client, 1) && GetClientButtons(client) & IN_ATTACK && GetClientButtons(search) & IN_ATTACK && !TF2_IsPlayerInCondition(search, TFCond_Overhealed) && TF_GetUberLevel(client)>=100.00 && otherclass != TFClass_Medic && TF2_IsPlayerInCondition(search, TFCond_OnFire) || chainDistance2 < 1000.0 && IsWeaponSlotActive(client, 1) && GetClientButtons(client) & IN_ATTACK && GetClientButtons(search) & IN_ATTACK && !TF2_IsPlayerInCondition(search, TFCond_Overhealed) && TF_GetUberLevel(client)>=100.00 && otherclass != TFClass_Medic && TF2_IsPlayerInCondition(search, TFCond_Bleeding) || chainDistance2 < 1000.0 && IsWeaponSlotActive(client, 1) && GetClientButtons(client) & IN_ATTACK && GetClientButtons(search) & IN_ATTACK && !TF2_IsPlayerInCondition(search, TFCond_Overhealed) && TF_GetUberLevel(client)>=100.00 && otherclass != TFClass_Medic && TF2_IsPlayerInCondition(search, TFCond_Milked) || chainDistance2 < 1000.0 && IsWeaponSlotActive(client, 1) && GetClientButtons(client) & IN_ATTACK && GetClientButtons(search) & IN_ATTACK && !TF2_IsPlayerInCondition(search, TFCond_Overhealed) && TF_GetUberLevel(client)>=100.00 && otherclass != TFClass_Medic && TF2_IsPlayerInCondition(search, TFCond_Jarated))
							{
								buttons |= IN_ATTACK2;
							}
						}
					}
				}
				
				if(class == TFClass_Medic)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);
							
							if(GetClientButtons(client) & IN_JUMP)
							{
								buttons |= IN_DUCK;
							}

							if(chainDistance2 < 500.0 && otherclass == TFClass_Soldier && IsWeaponSlotActive(search, 0) && TF2_IsPlayerInCondition(search, TFCond_Overhealed) && GetClientButtons(search) & IN_JUMP && GetClientButtons(client) & IN_ATTACK && IsWeaponSlotActive(client, 1))
							{
								buttons |= IN_JUMP;
							}
							
							if(chainDistance2 < 500.0 && otherclass == TFClass_DemoMan && TF2_IsPlayerInCondition(search, TFCond_Overhealed) && GetClientButtons(search) & IN_JUMP && GetClientButtons(client) & IN_ATTACK && IsWeaponSlotActive(client, 1))
							{
								buttons |= IN_JUMP;
							}
							
							if(chainDistance2 < 500.0 && otherclass == TFClass_Pyro && IsWeaponSlotActive(search, 1) && TF2_IsPlayerInCondition(search, TFCond_Overhealed) && GetClientButtons(search) & IN_JUMP && GetClientButtons(client) & IN_ATTACK && IsWeaponSlotActive(client, 1))
							{
								buttons |= IN_JUMP;
							}
						}
					}
				}
				
				if(class == TFClass_Medic)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(!TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && IsWeaponSlotActive(client, 0) && chainDistance2 < 300.0 && otherclass != TFClass_Medic || !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && IsWeaponSlotActive(search, 0) && chainDistance2 < 600 && otherclass == TFClass_Pyro || !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && IsWeaponSlotActive(client, 0) && chainDistance2 < 600 && otherclass == TFClass_Scout || !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && TF2_IsPlayerInCondition(search, TFCond_Zoomed) && chainDistance2 < 1200 && otherclass == TFClass_Sniper)
							{
								vel = moveBackwards(vel,300.0);
							}
							
							if(TF_GetUberLevel(client)>=100.00 && chainDistance2 < 200.0 && otherclass == TFClass_Spy)
							{
								buttons |= IN_ATTACK2;
							}
							else if(!TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && chainDistance2 < 300.0 && otherclass == TFClass_Spy)
							{
								vel = moveForward(vel,300.0);
							}
						}
					}
				}
				
				if(class == TFClass_Medic && IsWeaponSlotActive(client, 1)) // Basic Medic Bot AI
				{
					for (new searchenemy = 1; searchenemy <= MaxClients; searchenemy++)
					{
						if (IsClientInGame(searchenemy) && IsPlayerAlive(searchenemy) && searchenemy != client && (GetClientTeam(client) != GetClientTeam(searchenemy)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(searchenemy, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							new Float:chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin, searchOrigin);
						
							if(chainDistance3 < 1000.0)
							{
								for (new search = 1; search <= MaxClients; search++)
								{
									if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
									{
										new Float:clientOrigin2[3];
										new Float:searchOrigin2[3];
										GetClientAbsOrigin(search, searchOrigin2);
										GetClientAbsOrigin(client, clientOrigin2);
							
										new Float:chainDistance2;
										chainDistance2 = GetVectorDistance(clientOrigin2, searchOrigin2);
						
										if(chainDistance2 > 600.0 && chainDistance2 < 700.0)
										{
											vel = moveForward(vel,300.0);
										}
						
										if(chainDistance2 < 60.0)
										{
											vel = moveBackwards(vel,300.0);
											buttons |= IN_ATTACK;
										}
						
										if(chainDistance2 == 100.0)
										{
											vel = moveSide(vel,300.0);
											buttons |= IN_ATTACK;
										}
						
										if(chainDistance2 == 200.0)
										{
											vel = moveSide2(vel,300.0);
											buttons |= IN_ATTACK;
										}
						
										if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
										{
											buttons |= IN_ATTACK;
										}
									}
								}
							}
						}
					}
				}
				
				if(class != TFClass_Pyro)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 1000.0 && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && TF2_IsPlayerInCondition(search, TFCond_Ubercharged) && class != TFClass_Spy)
							{
								vel = moveBackwards(vel,300.0);
							}
							
							if(class == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_DeadRingered) && chainDistance2 < 1000.0)
							{
								vel = moveBackwards(vel,300.0);
							}
							
							if(class == TFClass_Spy && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && chainDistance2 < 1000.0)
							{
								buttons |= IN_ATTACK2;
							}
						}
					}
				}
				
				if(TF2_IsPlayerInCondition(client, TFCond_Taunting))
				{
					vel = moveForward(vel,300.0);
				}
				
				if(class == TFClass_Spy && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
					if(TimerVeryLow == INVALID_HANDLE)
					{
						g_iOffsetCloak = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");
						SetEntDataFloat(client, g_iOffsetCloak, 100.0);
					}
				}
				
				if(class == TFClass_Spy && !TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
				{
					if(TimerVeryLow == INVALID_HANDLE)
					{
						g_iOffsetCloak = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");
						SetEntDataFloat(client, g_iOffsetCloak, 100.0);
					}
				}
				
				if(GetClientButtons(client) & IN_ATTACK)
				{
					if(GetAmmo(client) != -1)
					{
						SetEntData(client, GetAmmo(client) +4, 50);
						SetEntData(client, GetAmmo(client) +8, 50);
					}
				}
				
				if(TF2_IsPlayerInCondition(client, TFCond_Teleporting) && class == TFClass_Spy && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
				    buttons |= IN_ATTACK2;
				}
				
				if(TF2_IsPlayerInCondition(client, TFCond_TeleportedGlow) && class == TFClass_Spy && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
				    buttons |= IN_ATTACK2;
				}
				
				if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && class == TFClass_Medic)
				{
					buttons |= IN_ATTACK;
				}
				
				if(TimerHigh == INVALID_HANDLE && GetClientButtons(client) & IN_ATTACK && class == TFClass_Medic && GetHealth(client) < 100.0)
				{
					buttons |= IN_ATTACK3;
				}
				
				if(class == TFClass_Medic && GetHealth(client) < 50.0)
				{
					buttons |= IN_ATTACK2;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:BotHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new botid = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TF2_GetPlayerClass(botid);
	
	if(IsFakeClient(botid))
	{
		if(IsPlayerAlive(botid))
		{
			new type = GetRandomInt(1,2);
			if(type == 1)
			{
				if(class != TFClass_Spy)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != botid && (GetClientTeam(botid) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							new Float:clientOrigin[3];
							new Float:searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(botid, clientOrigin);
							
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 2000.0 && GetClientButtons(search) & IN_ATTACK && otherclass == TFClass_Spy)
							{
								new random = GetRandomInt(1,2);
								switch(random)
								{
									case 1:
									{
										FakeClientCommand(botid, "voicemenu 1 1");
									}
									case 2:
									{
										// NOPE
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:hookPlayerDie(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attacker")
	new botid =  GetClientOfUserId(attacker)
	
	if(IsFakeClient(botid))
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

public Action:ResetTimerVeryLow(Handle:timer)
{
	TimerVeryLow = INVALID_HANDLE;
}

public Action:ResetTimerLow(Handle:timer)
{
	TimerLow = INVALID_HANDLE;
}

public Action:ResetTimerNormal(Handle:timer)
{
	TimerNormal = INVALID_HANDLE;
}

public Action:ResetTimerHigh(Handle:timer)
{
	TimerHigh = INVALID_HANDLE;
}

stock bool:IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

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

stock bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

public bool:TraceEntityFilterStuff(entity, mask)
{
	return entity > MaxClients;
}

stock GetHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock GetAmmo(client)
{
	return FindSendPropInfo("CTFPlayer", "m_iAmmo");
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}
