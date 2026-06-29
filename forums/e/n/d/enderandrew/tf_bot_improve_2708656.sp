#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1

float flag_pos[3];
float flag_pos2[3];
float flag_pos3[3];
float flag_pos4[3];

#define PLUGIN_VERSION  "4.0"
#define PLUGIN_CONFIG "cfg/sourcemod/plugin.tfbotimprove.cfg"

public Plugin:myinfo = 
{
	name = "TF2 Improved Bots",
	author = "EfeDursun125",
	description = "TFBots now uses voice commands and combat improve.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

Handle TimerVeryLow;
Handle TimerLow;
Handle TimerNormal;
Handle TimerHigh;

float moveForward(float vel[3],float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

float moveBackwards(float vel[3],float MaxSpeed)
{
	vel[0] = -MaxSpeed;
	return vel;
}

float moveSide(float vel[3],float MaxSpeed)
{
	vel[1] = MaxSpeed;
	return vel;
}

float moveSide2(float vel[3],float MaxSpeed)
{
	vel[1] = -MaxSpeed;
	return vel;
}

ConVar g_hCVOnUberedAlwaysMoveForward;
Handle BotHeavyReadyMinigunRange;
Handle BotSawLowSoundsRange;
Handle BotSawHighSoundsRange;

public OnPluginStart()
{
	CreateConVar("sm_tf_bot_improve_version", PLUGIN_VERSION, "TFBot Improver Plugin Version", FCVAR_NONE);
	g_hCVOnUberedAlwaysMoveForward = CreateConVar("tf_bot_on_ubercharged_always_move_forward", "1", " ", FCVAR_NONE, true, 1.0, false, 0.0);
	BotHeavyReadyMinigunRange = CreateConVar("tf_bot_heavy_spin_minigun_range", "1000.0", "", FCVAR_NONE, true, 0.0, false, _);
	BotSawLowSoundsRange = CreateConVar("tf_bot_saw_low_sounds_range", "512.0", "", FCVAR_NONE, true, 0.0, false, _);
	BotSawHighSoundsRange = CreateConVar("tf_bot_saw_high_sounds_range", "1024.0", "", FCVAR_NONE, true, 0.0, false, _);
	HookEvent("player_spawn", BotSpawn, EventHookMode_Post);
	HookEvent("player_hurt", BotHurt, EventHookMode_Post);
	HookEvent("teamplay_round_start", RoundStarted);
}

public OnMapStart()
{
	ServerCommand("sv_tags advancedbots");
	AddServerTag("advancedbots"); // This is not working, i know but, i trying this
	ServerCommand("sm_cvar tf_bot_health_critical_ratio 0.4");
	ServerCommand("sm_cvar tf_bot_max_point_defend_range 3000");
	ServerCommand("sm_cvar tf_bot_sniper_aim_error 0.0");
	ServerCommand("sm_cvar tf_bot_sniper_choose_target_interval 10.0f"); // Need Kill First Enemy Sniper
	ServerCommand("sm_cvar tf_bot_choose_target_interval 0.0f"); // For Kill Nearest Spy
	ServerCommand("sm_cvar tf_bot_sniper_melee_range 100"); // For Anti trick stab
	ServerCommand("sm_cvar tf_bot_sniper_flee_range 1000"); // Sniper bots using smg on high range
	ServerCommand("sm_cvar tf_bot_sniper_spot_min_range 2000");
	ServerCommand("sm_cvar tf_bot_sniper_patience_duration 8");
	ServerCommand("sm_cvar tf_bot_sniper_personal_space_range 1500");
	ServerCommand("sm_cvar tf_bot_min_setup_gate_sniper_defend_range 5000");
	ServerCommand("sm_cvar tf_bot_medic_cover_test_resolution 100"); // Anti Sniper & Don't wait on base
	ServerCommand("sm_cvar tf_bot_medic_max_call_response_range 999999"); // Medic Bots Can Wait 7/24 On Base, Need Fix
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	if(StrContains(currentMap, "pl_" , false) != -1)
	{
		CreateTimer(0.1, MoveTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, FindFlag,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientPutInServer(client)
{
	CreateTimer(GetRandomFloat(10.0, 20.0), MedicTimer, client, 3);
	CreateTimer(GetRandomFloat(20.0, 40.0), HelpThanksTimer, client, 3);
	CreateTimer(GetRandomFloat(40.0, 80.0), IncomingTimer, client, 3);
	CreateTimer(GetRandomFloat(15.0, 30.0), ReportSentry, client, 3);
	return;
}

public Action:FindFlag(Handle timer)
{
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE)
	{
		SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent, SDKHook_Touch, OnFlagTouch );
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

public Action:RoundStarted(Handle  event , const char[] name , bool dontBroadcast)
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if(StrContains(currentMap, "pl_" , false) != -1)
	{
		CreateTimer(0.1, LoadStuff);
	}
}

public Action:LoadStuff(Handle timer)
{
	char nameblue[] = "bluebotflag";
	char classblue[] = "item_teamflag";
	int ent = FindEntityByTargetname(nameblue, classblue);
	if(ent != -1)
	{
		//Do nothing.
	}
	else
	{
		int teamflags = CreateEntityByName("item_teamflag");
		if(IsValidEntity(teamflags))
		{
			DispatchKeyValue(teamflags, "targetname", "bluebotflag");
			DispatchKeyValue(teamflags, "trail_effect", "0");
			DispatchKeyValue(teamflags, "ReturnTime", "1");
			DispatchKeyValue(teamflags, "flag_model", "models/empty.mdl");
			DispatchSpawn(teamflags);
			SetEntProp(teamflags, Prop_Send, "m_iTeamNum", 2);
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, float vel[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				int team = GetClientTeam(client);
				int m_iStunFlags = FindSendPropInfo("CTFPlayer","m_iStunFlags");
				int stunFlag = GetEntData(client, m_iStunFlags);
				float clientEyes[3];
				GetClientEyePosition(client, clientEyes);
				char currentMap[PLATFORM_MAX_PATH];
				GetCurrentMap(currentMap, sizeof(currentMap));
				
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
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Scout)
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
				
				if(stunFlag == TF_STUNFLAGS_GHOSTSCARE)
				{
			    	vel = moveBackwards(vel,300.0);
				}
				
				if(class == TFClass_Scout)
				{
					if(buttons & IN_JUMP)
					{
						buttons |= IN_JUMP;
					}
					if(buttons & IN_JUMP)
					{
						buttons |= IN_DUCK;
					}
				}
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Scout)
				{
					int random = GetRandomInt(1,50);
					if (random == 1)
					{
						buttons |= IN_JUMP;
					}
				}
				
				if(GetClientButtons(client) & IN_JUMP && class == TFClass_Scout)
				{
					int random = GetRandomInt(1,4);
					switch(random)
					{
						case 1:
					    {
					        vel = moveForward(vel,300.0);
					    }
						case 2:
					    {
					        vel = moveBackwards(vel,300.0);
					    }
						case 3:
					    {
					        vel = moveSide(vel,300.0);
					    }
						case 4:
					    {
					        vel = moveSide2(vel,300.0);
					    }
					}
				}
				
				if(TimerVeryLow == INVALID_HANDLE && GetClientButtons(client) & IN_ATTACK && class == TFClass_Engineer && IsWeaponSlotActive(client, 2))
				{
					int random = GetRandomInt(1,20);
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
						int random = GetRandomInt(1,5);
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
						int random = GetRandomInt(1,3);
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
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Scout && IsWeaponSlotActive(client, 0) && GetHealth(client) > 75.0)
				{
					vel = moveForward(vel,400.0);
				}
				
				if(GetClientButtons(client) & IN_ATTACK && class == TFClass_Scout && IsWeaponSlotActive(client, 1) && GetHealth(client) > 50.0 && GetHealth(client) < 75.0)
				{
					vel = moveBackwards(vel,400.0);
				}
				
				if(TimerVeryLow == INVALID_HANDLE && GetClientButtons(client) & IN_JUMP && class == TFClass_Scout)
				{
					int random = GetRandomInt(1,2);
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
					int random = GetRandomInt(1,7);
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
				
				if(class == TFClass_Medic && IsWeaponSlotActive(client, 0))
				{
					buttons |= IN_RELOAD;
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
				
				if(class == TFClass_Spy && buttons & IN_ATTACK2 && TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
				{
					buttons &= ~IN_ATTACK2;
				}
				
				int Cart;
				if(class != TFClass_Medic && class != TFClass_Spy && class != TFClass_Sniper && class != TFClass_Engineer)
				{
					if((Cart = FindEntityByClassname(Cart, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE && class == TFClass_Medic)
					{
						if(IsValidEntity(Cart))
						{
							float fEntityLocation[3];
							float clientOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(Cart, Prop_Send, "m_vecOrigin", fEntityLocation);

							float chainDistance2;
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
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 > 1000.0 && IsWeaponSlotActive(client, 2) && buttons & IN_ATTACK)
							{
								if(class == TFClass_Engineer && buttons & IN_FORWARD)
								{
									buttons &= ~IN_FORWARD;
								}
							}
						}
					}
				}
				
				if(class == TFClass_Scout)
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 600.0 && IsWeaponSlotActive(search, 0) && otherclass == TFClass_Pyro && GetClientButtons(search) & IN_ATTACK && GetClientButtons(client) & IN_ATTACK)
							{
								vel = moveBackwards(vel,300.0);
							}
						}
					}
				}
				
				if(class == TFClass_Pyro)
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							float chainDistance2;
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
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 200.0 && IsWeaponSlotActive(search, 2) && otherclass == TFClass_Heavy)
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel,300.0);
								int Weapon = GetPlayerWeaponSlot(client, 0);
								if(IsValidEntity(Weapon))
								{
									SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 0));
								}
							}
						}
					}
				}
				
				if(class != TFClass_Medic)
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							float chainDistance2;
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
				
				if(class == TFClass_Heavy)
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							float clientOrigin[3];
							float searchOrigin[3];
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);
							
							if(chainDistance2 < GetConVarFloat(BotHeavyReadyMinigunRange) && otherclass != TFClass_Medic && otherclass != TFClass_Engineer && otherclass != TFClass_Sniper && otherclass != TFClass_Scout && otherclass != TFClass_Spy && IsWeaponSlotActive(client, 0))
							{
								buttons |= IN_ATTACK2;
							}
						}
					}
				}
				
				if(class != TFClass_Heavy && class != TFClass_Medic && !TF2_IsPlayerInCondition(client, TFCond_Zoomed))
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							float clientOrigin[3];
							float searchOrigin[3];
							float sawLowSoundOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							GetClientAbsOrigin(search, sawLowSoundOrigin);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);
							
							clientOrigin[2] += 50.0;
							searchOrigin[2] += 50.0;
							
							int changearea = GetRandomInt(1, 1000);
							if(changearea == 1)
							{
								sawLowSoundOrigin[0] += GetRandomFloat(-1024.0, 1024.0);
								sawLowSoundOrigin[1] += GetRandomFloat(-1024.0, 1024.0);
								sawLowSoundOrigin[2] += GetRandomFloat(-10.0, 100.0);
							}
							
							float buffer[3];
							GetEntPropVector(search, Prop_Data, "m_vecAbsVelocity", buffer);
							float bufferlength = GetVectorLength(buffer);
							
							if(chainDistance2 < GetConVarFloat(BotSawLowSoundsRange) && bufferlength != 0.0)
							{
								if(!IsPointVisible(clientOrigin, searchOrigin))
								{
									TF2_LookAtPos(client, sawLowSoundOrigin, 0.05);
								}
							}
						}
					}
				}
				
				if(class == TFClass_Sniper)
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							float sawLowSoundOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							GetClientAbsOrigin(search, sawLowSoundOrigin);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);
							
							clientOrigin[2] += 50.0;
							searchOrigin[2] += 50.0;
							
							int changearea = GetRandomInt(1, 1000);
							if(changearea == 1)
							{
								sawLowSoundOrigin[0] += GetRandomFloat(-1024.0, 1024.0);
								sawLowSoundOrigin[1] += GetRandomFloat(-1024.0, 1024.0);
								sawLowSoundOrigin[2] += GetRandomFloat(10.0, 110.0);
							}
							
							float buffer[3];
							GetEntPropVector(search, Prop_Data, "m_vecAbsVelocity", buffer);
							float bufferlength = GetVectorLength(buffer);
							
							if(chainDistance2 < (GetConVarFloat(BotSawLowSoundsRange) + GetConVarFloat(BotSawLowSoundsRange)) && bufferlength != 0.0)
							{
								if(IsPointVisible(clientOrigin, searchOrigin))
								{
									if(otherclass == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_Zoomed) && GetClientButtons(client) != IN_ATTACK)
									{
										TF2_LookAtPos(client, sawLowSoundOrigin, 0.05);
									}
								}
								else
								{
									TF2_LookAtPos(client, sawLowSoundOrigin, 0.05);
								}
							}
						}
					}
				}
				
				if(IsWeaponSlotActive(client, 0))
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							float sawLowSoundOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							GetClientAbsOrigin(search, sawLowSoundOrigin);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);
							
							clientOrigin[2] += 50.0;
							searchOrigin[2] += 50.0;
							
							int changearea = GetRandomInt(1, 1000);
							if(changearea == 1)
							{
								sawLowSoundOrigin[0] += GetRandomFloat(-720.0, 720.0);
								sawLowSoundOrigin[1] += GetRandomFloat(-512.0, 512.0);
								sawLowSoundOrigin[2] += GetRandomFloat(-10.0, 100.0);
							}
							
							if(chainDistance2 < GetConVarFloat(BotSawHighSoundsRange) && chainDistance2 > GetConVarFloat(BotSawLowSoundsRange) && (TF2_IsPlayerInCondition(client, TFCond_Bleeding) || TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_Disguising) || GetClientButtons(search) == IN_ATTACK) && (otherclass != TFClass_Sniper && GetClientButtons(search) == IN_ATTACK2))
							{
								if(!IsPointVisible(clientOrigin, searchOrigin))
								{
									TF2_LookAtPos(client, sawLowSoundOrigin, 0.05);
								}
							}
						}
					}
				}
				
				if(class == TFClass_Soldier)
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							float clientOrigin[3];
							float searchOrigin[3];
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							clientOrigin[2] += 65.0;
							searchOrigin[2] += 65.0;

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 250.0 && otherclass == TFClass_Pyro && class == TFClass_Soldier && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && IsPointVisible(clientOrigin, searchOrigin))
							{
								buttons |= IN_JUMP;
								buttons |= IN_ATTACK;
								vel = moveBackwards(vel,300.0);
								int Weapon2 = GetPlayerWeaponSlot(client, 1);
								if(IsValidEntity(Weapon2))
								{
									SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 1));
								}
							}
							else if(chainDistance2 < 500.0 && otherclass == TFClass_Pyro && class == TFClass_Soldier && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && IsPointVisible(clientOrigin, searchOrigin))
							{
								buttons |= IN_ATTACK;
								int Weapon2 = GetPlayerWeaponSlot(client, 1);
								if(IsValidEntity(Weapon2))
								{
									SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 1));
								}
							}
							else if(chainDistance2 < 750.0 && otherclass == TFClass_Pyro && class == TFClass_Soldier && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && IsPointVisible(clientOrigin, searchOrigin))
							{
								vel = moveBackwards(vel,300.0);
							}
						}
					}
				}
				
				if(class == TFClass_Pyro)
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 250.0 && IsWeaponSlotActive(client, 0) && TF2_IsPlayerInCondition(search, TFCond_OnFire))
							{
								buttons |= IN_ATTACK2;
								TF2_LookAtPos(client, searchOrigin, 0.075);
							}
							else if(chainDistance2 < 500.0 && IsWeaponSlotActive(client, 0) && TF2_IsPlayerInCondition(search, TFCond_OnFire))
							{
								vel = moveForward(vel,300.0);
								TF2_LookAtPos(client, searchOrigin, 0.075);
							}
						}
					}
				}
				
				if(class == TFClass_Spy)
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							float chainDistance2;
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
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							float chainDistance2;
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
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
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
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							float chainDistance2;
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
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							float chainDistance2;
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
								buttons |= IN_ATTACK;
							}
						}
					}
				}
				
				if(class == TFClass_Spy)
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							float chainDistance2;
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
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							float chainDistance2;
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
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							float chainDistance2;
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
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(!TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && IsWeaponSlotActive(client, 1) && chainDistance2 < 300.0 && otherclass != TFClass_Medic || !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && IsWeaponSlotActive(search, 0) && chainDistance2 < 600 && otherclass == TFClass_Pyro || !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && IsWeaponSlotActive(client, 0) && chainDistance2 < 600 && otherclass == TFClass_Scout || !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && TF2_IsPlayerInCondition(search, TFCond_Zoomed) && chainDistance2 < 1200 && otherclass == TFClass_Sniper)
							{
								vel = moveBackwards(vel,300.0);
							}
							
							if(TF_GetUberLevel(client)>=100.00 && chainDistance2 < 200.0 && otherclass == TFClass_Spy)
							{
								buttons |= IN_ATTACK2;
							}
							else if(!TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && chainDistance2 < 300.0 && otherclass == TFClass_Spy && GetClientAimTarget(client) == 0)
							{
								vel = moveForward(vel,300.0);
							}
						}
					}
				}
				
				if(class == TFClass_Medic && IsWeaponSlotActive(client, 1)) // Basic Medic Bot AI
				{
					for (int searchenemy = 1; searchenemy <= MaxClients; searchenemy++)
					{
						if (IsClientInGame(searchenemy) && IsPlayerAlive(searchenemy) && searchenemy != client && (GetClientTeam(client) != GetClientTeam(searchenemy)))
						{
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(searchenemy, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							float chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin, searchOrigin);
						
							if(chainDistance3 < 1536.0)
							{
								for (int search = 1; search <= MaxClients; search++)
								{
									if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)))
									{
										float clientOrigin2[3];
										float searchOrigin2[3];
										GetClientAbsOrigin(search, searchOrigin2);
										GetClientAbsOrigin(client, clientOrigin2);
							
										float chainDistance2;
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
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							
							float chainDistance2;
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
				
				if(GetClientButtons(client) & IN_ATTACK)
				{
					if(GetAmmo(client) != -1)
					{
						SetEntData(client, GetAmmo(client) +4, 100);
						SetEntData(client, GetAmmo(client) +8, 100);
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
				
				if(StrContains(currentMap, "pl_" , false) != -1 && team == 3)
				{
					if(class == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_Disguised) && IsWeaponSlotActive(client, 0))
					{
						if(buttons & IN_ATTACK)
						{
							buttons &= ~IN_ATTACK;
						}
					}
				
					if(class == TFClass_Spy && GetHealth(client) > 100.0 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						if(buttons & IN_ATTACK2)
						{
							buttons &= ~IN_ATTACK2;
						}
					}
					
					if(class == TFClass_Spy && GetHealth(client) < 75.0 && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						buttons |= IN_ATTACK2;
					}
					
					if(class == TFClass_Spy && GetHealth(client) < 35.0 && TF2_IsPlayerInCondition(client, TFCond_Disguising) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						buttons |= IN_ATTACK2;
					}
					
					if(class == TFClass_Spy && !IsWeaponSlotActive(client, 0))
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					
					if(class == TFClass_Spy && IsWeaponSlotActive(client, 2))
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
					
					if(class == TFClass_Medic && IsWeaponSlotActive(client, 1))
					{
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 2);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:MoveTimer(Handle timer)
{
	char nameblue[] = "bluebotflag";
	char classblue[] = "item_teamflag";
	int cartEnt = -1;
	int buildingent = -1;
	int random = GetRandomInt(1,3);
	switch(random)
	{
		case 1:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
				int ent = FindEntityByTargetname(nameblue, classblue);
				if(ent != -1)
				{
					int randompos = GetRandomInt(1,2);
					switch(randompos)
					{
						case 1:
						{
							flag_pos[0] += 44.0;
							flag_pos[1] += 14.0;
							flag_pos[2] -= 60.0;
						}
						case 2:
						{
							flag_pos[0] += -44.0;
							flag_pos[1] += -14.0;
							flag_pos[2] -= 60.0;
						}
					}
					TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
		case 2:
		{
			for(int client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						int ent = FindEntityByTargetname(nameblue, classblue);
						int team = GetClientTeam(client);
						if(ent != -1)
						{
							if(team == 2)
							{
								int selectedclient;
								do
								{
									selectedclient = GetRandomInt(1, MaxClients);
  								}
								while(!IsClientInGame(selectedclient) || GetClientTeam(selectedclient) != 2);
								GetClientAbsOrigin(selectedclient, flag_pos2);
								flag_pos2[2] += 50.0;
								TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 3:
		{
			if((buildingent = FindEntityByClassname(buildingent, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumObj = GetEntProp(buildingent, Prop_Send, "m_iTeamNum");
				if (iTeamNumObj == 2)
				{
					GetEntPropVector(buildingent, Prop_Data, "m_vecAbsOrigin", flag_pos3);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						flag_pos3[2] += 50.0;
						TeleportEntity(ent, flag_pos3, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			else if((buildingent = FindEntityByClassname(buildingent, "obj_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumObj = GetEntProp(buildingent, Prop_Send, "m_iTeamNum");
				if (iTeamNumObj == 2)
				{
					GetEntPropVector(buildingent, Prop_Data, "m_vecAbsOrigin", flag_pos3);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						flag_pos3[2] += 50.0;
						TeleportEntity(ent, flag_pos3, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			else if((buildingent = FindEntityByClassname(buildingent, "obj_teleporter")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumObj = GetEntProp(buildingent, Prop_Send, "m_iTeamNum");
				if (iTeamNumObj == 2)
				{
					GetEntPropVector(buildingent, Prop_Data, "m_vecAbsOrigin", flag_pos3);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						flag_pos3[2] += 50.0;
						TeleportEntity(ent, flag_pos3, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			else
			{
				for(int client=1;client<=MaxClients;client++)
				{
					if(IsClientInGame(client))
					{
						if(IsPlayerAlive(client))
						{
							int ent = FindEntityByTargetname(nameblue, classblue);
							new TFClassType:class = TF2_GetPlayerClass(client);
							int team = GetClientTeam(client);
							if(ent != -1)
							{
								if(team == 2)
								{
									if(class == TFClass_Spy)
									{
										GetClientAbsOrigin(client, flag_pos3);
										flag_pos3[2] += 50.0;
										TeleportEntity(ent, flag_pos3, NULL_VECTOR, NULL_VECTOR);
									}
									else if(class == TFClass_Sniper)
									{
										GetClientAbsOrigin(client, flag_pos3);
										flag_pos3[2] += 50.0;
										TeleportEntity(ent, flag_pos3, NULL_VECTOR, NULL_VECTOR);
									}
									else if(class == TFClass_Medic)
									{
										GetClientAbsOrigin(client, flag_pos3);
										flag_pos3[2] += 50.0;
										TeleportEntity(ent, flag_pos3, NULL_VECTOR, NULL_VECTOR);
									}
									else if(class == TFClass_Engineer)
									{
										GetClientAbsOrigin(client, flag_pos3);
										flag_pos3[2] += 50.0;
										TeleportEntity(ent, flag_pos3, NULL_VECTOR, NULL_VECTOR);
									}
									else
									{
										if((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
										{
											GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos4);
											flag_pos[0] += GetRandomFloat(-1000.0, 1000.0);
											flag_pos[1] += GetRandomFloat(-1000.0, 1000.0);
											flag_pos[2] += GetRandomFloat(-1000.0, 1000.0);
											TeleportEntity(ent, flag_pos4, NULL_VECTOR, NULL_VECTOR);
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
}

public Action:BotSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int botid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsFakeClient(botid))
	{
		if(IsPlayerAlive(botid))
		{
			SetVariantInt(1);
			AcceptEntityInput(botid, "SetForcedTauntCam");
			
			int type = GetRandomInt(1,100);
			if(type <= 40)
			{
				int random = GetRandomInt(1,7);
				switch(random)
				{
					case 1:
			    	{
			    		FakeClientCommand(botid, "voicemenu 0 2");
					}
					case 2:
			    	{
			    		FakeClientCommand(botid, "voicemenu 0 3");
					}
					case 3:
			    	{
			    		FakeClientCommand(botid, "voicemenu 1 0");
					}
					case 4:
			    	{
			    		FakeClientCommand(botid, "voicemenu 2 0");
					}
					case 5:
			    	{
			    		FakeClientCommand(botid, "voicemenu 0 0");
					}
					case 6:
			   		{
			    		FakeClientCommand(botid, "voicemenu 0 4");
					}
					case 7:
			   		{
			    		FakeClientCommand(botid, "voicemenu 0 5");
					}
				}
			}
		}
	}
}

public Action:BotHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int botid = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TF2_GetPlayerClass(botid);
	
	if(IsFakeClient(botid))
	{
		if(IsPlayerAlive(botid))
		{
			int type = GetRandomInt(1,100);
			if(type <= 50)
			{
				if(class != TFClass_Spy)
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != botid && (GetClientTeam(botid) != GetClientTeam(search)))
						{
							new TFClassType:otherclass = TF2_GetPlayerClass(search);
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(botid, clientOrigin);
							
							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 2000.0 && GetClientButtons(search) & IN_ATTACK && otherclass == TFClass_Spy)
							{
								int random = GetRandomInt(1,100);
								if(random <= 50)
								{
									FakeClientCommand(botid, "voicemenu 1 1");
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:ReportSentry(Handle timer, client)
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				int iSentry;
				
				while((iSentry = FindEntityByClassname(iSentry, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
				{
					float clientOrigin[3];
					float sentryOrigin[3];
					GetClientAbsOrigin(client, clientOrigin);
					GetEntPropVector(iSentry, Prop_Send, "m_vecOrigin", sentryOrigin);
					int iTeamNumObj = GetEntProp(iSentry, Prop_Send, "m_iTeamNum");
					
					if(IsValidEntity(iSentry) && GetClientTeam(client) != iTeamNumObj && IsPointVisibleTank(clientOrigin, sentryOrigin))
					{
						FakeClientCommand(client, "voicemenu 1 2");
					}
				}
			}
		}
	}
}

public Action:MedicTimer(Handle timer, client)
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				if (class == TFClass_Scout)
				{
					if(GetHealth(client) < 75.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 50)
						{
							FakeClientCommand(client, "voicemenu 0 0");
						}
					}
				}
				if (class == TFClass_Soldier)
				{
					if(GetHealth(client) < 125.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 50)
						{
							FakeClientCommand(client, "voicemenu 0 0");
						}
					}
				}
				if (class == TFClass_Pyro)
				{
					if(GetHealth(client) < 100.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 50)
						{
							FakeClientCommand(client, "voicemenu 0 0");
						}
					}
				}
				if (class == TFClass_DemoMan)
				{
					if(GetHealth(client) < 100.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 50)
						{
							FakeClientCommand(client, "voicemenu 0 0");
						}
					}
				}
				if (class == TFClass_Heavy)
				{
					if(GetHealth(client) < 200.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 50)
						{
							FakeClientCommand(client, "voicemenu 0 0");
						}
					}
				}
				if (class == TFClass_Engineer)
				{
					if(GetHealth(client) < 75.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 50)
						{
							FakeClientCommand(client, "voicemenu 0 0");
						}
					}
				}
				if (class == TFClass_Medic)
				{
					if(GetHealth(client) < 100.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 50)
						{
							FakeClientCommand(client, "voicemenu 0 0");
						}
					}
				}
				if (class == TFClass_Sniper)
				{
					if(GetHealth(client) < 75.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 50)
						{
							FakeClientCommand(client, "voicemenu 0 0");
						}
					}
				}
				if (class == TFClass_Spy)
				{
					if(GetHealth(client) < 70.00 && TF2_IsPlayerInCondition(client, TFCond_Disguising)) // 70 For Kunai
					{
						int random = GetRandomInt(1,100);
						if(random <= 50)
						{
							FakeClientCommand(client, "voicemenu 0 0");
						}
					}
					else if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						int random = GetRandomInt(1,100);
						if(random <= 50)
						{
							FakeClientCommand(client, "voicemenu 0 0");
						}
					}
				}
			}
		}
	}
}

public Action:HelpThanksTimer(Handle timer, client)
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				if(TF2_IsPlayerInCondition(client, TFCond_Milked) || TF2_IsPlayerInCondition(client, TFCond_OnFire) &&  GetClientButtons(client) & IN_ATTACK || TF2_IsPlayerInCondition(client, TFCond_Bleeding) || TF2_IsPlayerInCondition(client, TFCond_Jarated) || TF2_IsPlayerInCondition(client, TFCond_Bonked))
				{
					int random = GetRandomInt(1,100);
					if(random <= 45)
					{
						FakeClientCommand(client, "voicemenu 2 0");
					}
				}
				if(GetHealth(client) < 100.00 && GetClientButtons(client) & IN_ATTACK)
				{
					int random = GetRandomInt(1,100);
					if(random <= 45)
					{
						FakeClientCommand(client, "voicemenu 2 0");
					}
				}
				if (class == TFClass_Scout)
				{
					if(GetHealth(client) > 125.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 40)
						{
							FakeClientCommand(client, "voicemenu 0 1");
						}
					}
				}
				if (class == TFClass_Soldier)
				{
					if(GetHealth(client) > 200.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 40)
						{
							FakeClientCommand(client, "voicemenu 0 1");
						}
					}
				}
				if (class == TFClass_Pyro)
				{
					if(GetHealth(client) > 175.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 40)
						{
							FakeClientCommand(client, "voicemenu 0 1");
						}
					}
				}
				if (class == TFClass_DemoMan)
				{
					if(GetHealth(client) > 175.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 40)
						{
							FakeClientCommand(client, "voicemenu 0 1");
						}
					}
				}
				if (class == TFClass_Heavy)
				{
					if(GetHealth(client) > 300.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 40)
						{
							FakeClientCommand(client, "voicemenu 0 1");
						}
					}
				}
				if (class == TFClass_Engineer)
				{
					if(GetHealth(client) > 125.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 40)
						{
							FakeClientCommand(client, "voicemenu 0 1");
						}
					}
				}
				if (class == TFClass_Medic)
				{
					if(GetHealth(client) > 150.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 40)
						{
							FakeClientCommand(client, "voicemenu 0 1");
						}
					}
				}
				if (class == TFClass_Sniper)
				{
					if(GetHealth(client) > 125.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 40)
						{
							FakeClientCommand(client, "voicemenu 0 1");
						}
					}
				}
				if (class == TFClass_Spy)
				{
					if(GetHealth(client) > 125.00)
					{
						int random = GetRandomInt(1,100);
						if(random <= 40)
						{
							FakeClientCommand(client, "voicemenu 0 1");
						}
					}
				}
				int Cart = -1;
				int Flag = -1;
				int ControlPoint = -1;
				int CapZone = -1;
				if(class != TFClass_Spy)
				{
					if((Cart = FindEntityByClassname(Cart, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE && class == TFClass_Medic)
					{
						if(IsValidEntity(Cart))
						{
							float fEntityLocation[3];
							float clientOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(Cart, Prop_Send, "m_vecOrigin", fEntityLocation);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,fEntityLocation);

							if(chainDistance2 < 1000.0)
							{
								FakeClientCommand(client, "voicemenu 2 0");
							}
						}
					}
					else if((Flag = FindEntityByClassname(Flag, "item_teamflag")) != INVALID_ENT_REFERENCE && class == TFClass_Medic)
					{
						if(IsValidEntity(Flag))
						{
							float fEntityLocation[3];
							float clientOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(Flag, Prop_Send, "m_vecOrigin", fEntityLocation);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,fEntityLocation);

							if(chainDistance2 < 1000.0)
							{
								FakeClientCommand(client, "voicemenu 2 0");
							}
						}
					}
					
					if((ControlPoint = FindEntityByClassname(ControlPoint, "team_control_point")) != INVALID_ENT_REFERENCE && class == TFClass_Medic)
					{
						if(IsValidEntity(ControlPoint))
						{
							float fEntityLocation[3];
							float clientOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(ControlPoint, Prop_Send, "m_vecOrigin", fEntityLocation);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,fEntityLocation);

							if(chainDistance2 < 1000.0)
							{
								FakeClientCommand(client, "voicemenu 2 0");
							}
						}
					}
					else if((CapZone = FindEntityByClassname(CapZone, "func_capturezone")) != INVALID_ENT_REFERENCE && class == TFClass_Medic)
					{
						if(IsValidEntity(CapZone))
						{
							float fEntityLocation[3];
							float clientOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(CapZone, Prop_Send, "m_vecOrigin", fEntityLocation);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,fEntityLocation);

							if(chainDistance2 < 1000.0)
							{
								FakeClientCommand(client, "voicemenu 2 0");
							}
						}
					}
				}
			}
		}
	}
}

public Action:IncomingTimer(Handle timer, client)
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				if(GetHealth(client) < 125.00 && GetClientButtons(client) & IN_ATTACK)
				{
					FakeClientCommand(client, "voicemenu 1 0");
				}
				if(GetHealth(client) > 124.00 && GetClientButtons(client) & IN_ATTACK)
				{
					int random = GetRandomInt(1,10);
					switch(random)
					{
				    	case 1:
				        {
			      			FakeClientCommand(client, "voicemenu 0 2");
						}
						case 2:
				       	{
			       			FakeClientCommand(client, "voicemenu 0 3");
						}
						case 3:
			       		{
			        		FakeClientCommand(client, "voicemenu 0 4");
						}
						case 4:
				       	{
				       		FakeClientCommand(client, "voicemenu 0 5");
						}
						case 5:
				       	{
				       		FakeClientCommand(client, "voicemenu 0 0");
						}
						case 6:
						{
				        	FakeClientCommand(client, "voicemenu 1 6");
						}
						case 7:
				   		{
			     			FakeClientCommand(client, "voicemenu 1 0");
						}
						case 8:
		        		{
			        		FakeClientCommand(client, "voicemenu 2 0");
						}
						case 9:
				   		{
			     			FakeClientCommand(client, "voicemenu 0 7");
						}
						case 10:
		        		{
			        		FakeClientCommand(client, "voicemenu 0 6");
						}
					}
				}
			}
		}
	}
}

stock FindEntityByTargetname(const char[] targetname, const char[] classname)
{
  char namebuf[32];
  int index = -1;
  namebuf[0] = '\0';
 
  while(strcmp(namebuf, targetname) != 0
    && (index = FindEntityByClassname(index, classname)) != -1)
    GetEntPropString(index, Prop_Data, "m_iName", namebuf, sizeof(namebuf));
 
  return(index);
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

public Action:ResetTimerVeryLow(Handle timer)
{
	TimerVeryLow = INVALID_HANDLE;
}

public Action:ResetTimerLow(Handle timer)
{
	TimerLow = INVALID_HANDLE;
}

public Action:ResetTimerNormal(Handle timer)
{
	TimerNormal = INVALID_HANDLE;
}

public Action:ResetTimerHigh(Handle timer)
{
	TimerHigh = INVALID_HANDLE;
}

stock bool IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock float TF_GetUberLevel(client)
{
	int index = GetPlayerWeaponSlot(client, 1);
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

public SetClientButtons(client,button)
{
    if(IsClientConnected(client) && IsClientInGame(client))
	{
        SetEntProp(client, Prop_Data, "m_nButtons", button);
	}
}

stock bool IsPointVisibleTank(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuffTank(entity, mask)
{
	int maxentities = GetMaxEntities();
	return entity > maxentities;
}

stock bool IsPointVisible(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuff(entity, mask)
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

bool IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}
  