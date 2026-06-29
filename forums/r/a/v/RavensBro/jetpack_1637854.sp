#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>

#define PLUGIN_VERSION "2.2"

#define SOUND_BURNER_START "weapons/flame_thrower_airblast.wav"
#define SOUND_BURNER_LOOP "weapons/flame_thrower_dg_loop.wav"
#define SOUND_BURNER_LOOP_CRIT "weapons/flame_thrower_dg_loop_crit.wav"
#define SOUND_BURNER_END "weapons/flame_thrower_dg_end.wav"
#define SOUND_BURNER_VOICE1 "vo/pyro_laughevil01.wav"
#define SOUND_BURNER_VOICE2 "vo/pyro_laughevil02.wav"
#define SOUND_BURNER_VOICE3 "vo/pyro_laughevil04.wav"
#define SOUND_PYRO_EXPLODE "ambient/explosions/explode_8.wav"
#define EFFECT_BURNER_RED "flamethrower"
#define EFFECT_BURNER_RED_CRIT "flamethrower_crit_red"
#define EFFECT_BURNER_BLU "flamethrower_blue"
#define EFFECT_BURNER_BLU_CRIT "flamethrower_crit_blue"
#define EFFECT_BURNER_EMPTY "muzzle_minigun"
#define EFFECT_BURNER_WARP "pyro_blast"
#define EFFECT_BURNER_WARP2 "pyro_blast"

new Handle:g_Enable = INVALID_HANDLE;
new Handle:g_BurnEnemy = INVALID_HANDLE;
new Handle:g_BurnEnemy2 = INVALID_HANDLE;
new Handle:g_JetPackUp = INVALID_HANDLE;
new Handle:g_JetPackUpward = INVALID_HANDLE;
new Handle:g_JetPackFall = INVALID_HANDLE;
new Handle:g_JetPackFrwd = INVALID_HANDLE;

new g_Particle1[MAXPLAYERS+1] = -1;
new g_Particle2[MAXPLAYERS+1] = -1;
new g_Explosion;
new g_LightEntity[MAXPLAYERS+1] = -1;
new jetpack_pref[MAXPLAYERS+1] = -1;

new bool:g_FirstJump[MAXPLAYERS+1] = false;
new bool:g_ReleaseButton[MAXPLAYERS+1] = false;
new bool:g_Flying[MAXPLAYERS+1] = false;
new bool:g_State[MAXPLAYERS+1] = false;
new bool:g_Crits[MAXPLAYERS+1] = false;
new bool:g_bKilling[MAXPLAYERS+1] = false;

new Float:g_LastKeyCheckTime[MAXPLAYERS+1] = 0.0;
new g_FilteredEntity = -1;
new iMaxClients;
public Plugin:myinfo = 
{
	name = "The Fury",
	author = "RavensBro",
	description = "Pyro's Jetpack",
	version = PLUGIN_VERSION,
	url = "N/A"
};

public OnPluginStart()
{
	CreateConVar("thefury", PLUGIN_VERSION, "The Fury version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(FindConVar("thefury"), PLUGIN_VERSION, true, true);
	g_Enable = CreateConVar("thefury_toggle", "1", "Enable/Disable plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_BurnEnemy = CreateConVar("thefury_burn", "0", "Burn enemy when hit Jet Pack's flame", 0, true, 0.0, true, 1.0);
	g_BurnEnemy2 = CreateConVar("thefury_explode", "0", _, 0, true, 0.0, true, 1.0);
	g_JetPackUp = CreateConVar("thefury_up_mag", "1.47", "Up velocity magnification", 0, true, 0.0, true, 2.0);
	g_JetPackUpward = CreateConVar("thefury_upward_mag", "2.07", "Upward velocity magnification", 0, true, 0.0, true, 2.0);
	g_JetPackFall = CreateConVar("thefury_fall_mag", "0.32", "Fall velocity magnification", 0, true, 0.0, true, 2.0);
	g_JetPackFrwd = CreateConVar("thefury_frwd_mag", "1.32", "Forward velocity magnification", 0, true, 0.0, true, 2.0);
		
	for (new iClient = 1; iClient <= MAXPLAYERS; iClient++)
	{
		DeleteBurnerParticle(iClient);
		g_LastKeyCheckTime[iClient] = 0.0;
		if(IsLightEntity(g_LightEntity[iClient]))
		{
			RemoveEdict(g_LightEntity[iClient]);
			g_LightEntity[iClient] = -1;
		}
	}
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	//RegConsoleCmd("say", OnPlayerSay);
	RegAdminCmd("sm_jetpack", OnJetpackCmd, ADMFLAG_CUSTOM1, "Toggles jetpack on/off");
	SetCookieMenuItem(jetpack_menu, 0, "JetPack Prefs");
}

public Action:OnJetpackCmd(client, args)
{
	if (client != 0)
	{
		showmenu(client);
	}
	return Plugin_Handled;
}

public jetpack_menu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		showmenu(client);
	}
}

showmenu(client)
{
	new Handle:menu = CreateMenu(MenuHandlerJetPack);
	
	SetMenuTitle(menu,"jetpack menu");
	

	AddMenuItem(menu, "enable","enable");
	
	AddMenuItem(menu, "disable","disable");

	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 20);
}

public MenuHandlerJetPack(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	
	{
		if(param2 == 0)
		{
			jetpack_pref[param1] = true;
		}
		if(param2 == 1)
		{
			jetpack_pref[param1] = false;
		}
	} 
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// events
public OnMapStart()
{
	if(GuessSDKVersion()==SOURCE_SDK_EPISODE2VALVE)
	    SetConVarString(FindConVar("thefury"), PLUGIN_VERSION, true, true);
	
	for (new iClient = 1; iClient <= MAXPLAYERS; iClient++)
	{
		DeleteBurnerParticle(iClient);
		g_LastKeyCheckTime[iClient] = 0.0;
		if(IsLightEntity(g_LightEntity[iClient]))
		{
			RemoveEdict(g_LightEntity[iClient]);
			g_LightEntity[iClient] = -1;
		}
	}
	
	PrePlayParticle(EFFECT_BURNER_RED);
	PrePlayParticle(EFFECT_BURNER_RED_CRIT);
	PrePlayParticle(EFFECT_BURNER_BLU);
	PrePlayParticle(EFFECT_BURNER_BLU_CRIT);
	PrePlayParticle(EFFECT_BURNER_EMPTY);
	PrePlayParticle(EFFECT_BURNER_WARP);
	PrePlayParticle(EFFECT_BURNER_WARP2);
	PrecacheSound(SOUND_BURNER_START, true);
	PrecacheSound(SOUND_BURNER_LOOP, true);
	PrecacheSound(SOUND_BURNER_LOOP_CRIT, true);
	PrecacheSound(SOUND_BURNER_END, true);
	PrecacheSound(SOUND_BURNER_VOICE1, true);
	PrecacheSound(SOUND_BURNER_VOICE2, true);
	PrecacheSound(SOUND_BURNER_VOICE3, true);
	PrecacheSound(SOUND_PYRO_EXPLODE, true);
	g_Explosion = PrecacheModel("sprites/sprite_fire01.vmt");
	
	iMaxClients=GetMaxClients();
	
	for(new i = 1; i <=iMaxClients; i++) 
	{
		jetpack_pref[i] = false;
	}	
}

public OnClientPutInServer(client)
{
	jetpack_pref[client] = true;
}

public OnGameFrame()
{
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{	
	    if(IsValidClient(iClient) && IsPlayerAlive(iClient))
		{	
			if(jetpack_pref[iClient])
			{
		        if(TF2_GetPlayerClass(iClient) == TFClass_Pyro)
				{	
				    if(GetConVarBool(g_Enable))
					{
						if(!(TF2_IsPlayerInCondition(iClient, TFCond:TF_CONDFLAG_TAUNTING)))
						
						if(CheckElapsedTime(iClient, 0.1))
						{
							if(GetClientButtons(iClient) & IN_JUMP)
							{
								if(!(GetEntityFlags(iClient) & FL_ONGROUND) && !(GetEntityFlags(iClient) & FL_INWATER) && !(GetEntityFlags(iClient) & FL_SWIM) && g_ReleaseButton[iClient])
								{
									if(!g_State[iClient])
									{
										CalculateCrit(iClient);
										
										new Float:fVelocity[3];
										GetEntPropVector(iClient, Prop_Data, "m_vecAbsVelocity", fVelocity);
										
										if(fVelocity[2] >= -300.0 && !g_Flying[iClient])
										{
											fVelocity[2] = 250.0;
											SetEntPropVector(iClient, Prop_Data, "m_vecAbsVelocity", fVelocity);
										}
										
										StopSound(iClient, 0, SOUND_BURNER_START);
										EmitSoundToAll(SOUND_BURNER_START, iClient, _, _, SND_CHANGEPITCH, 0.3, 150);
										CreateTimer(0.02, Timer_StartBurnerLoopSound, iClient);
										
										new Float:ang[3], Float:pos[3];
										ang[0] = -25.0;
										ang[1] = 90.0;
										ang[2] = 0.0;
										
										pos[1] = 10.0;
										pos[2] = 1.0;
										pos[0] = 30.0;
										ang[1] = 75.0;
										AttachParticleBone(iClient, EFFECT_BURNER_EMPTY, "flag", 0.15, pos, ang);
										pos[0] = -30.0;
										ang[1] = 105.0;
										AttachParticleBone(iClient, EFFECT_BURNER_EMPTY, "flag", 0.15, pos, ang);
										
										pos[2] = 3.0;
										pos[0] = -27.0;
										ang[1] = 105.0;
										pos[1] = -10.0;
										if(TFTeam:GetClientTeam(iClient) == TFTeam_Red)
											if(g_Crits[iClient])
												g_Particle1[iClient] = AttachLoopParticleBone(iClient, EFFECT_BURNER_RED_CRIT, "flag", pos, ang);
											else
												g_Particle1[iClient] = AttachLoopParticleBone(iClient, EFFECT_BURNER_RED, "flag", pos, ang);
										else
											if(g_Crits[iClient])
												g_Particle1[iClient] = AttachLoopParticleBone(iClient, EFFECT_BURNER_BLU_CRIT, "flag", pos, ang);
											else
												g_Particle1[iClient] = AttachLoopParticleBone(iClient, EFFECT_BURNER_BLU, "flag", pos, ang);
										pos[0] = 27.0;
										ang[1] = 75.0;
										pos[1] = -2.0;
										if(TFTeam:GetClientTeam(iClient) == TFTeam_Red)
											if(g_Crits[iClient])
												g_Particle2[iClient] = AttachLoopParticleBone(iClient, EFFECT_BURNER_RED_CRIT, "flag", pos, ang);
											else
												g_Particle2[iClient] = AttachLoopParticleBone(iClient, EFFECT_BURNER_RED, "flag", pos, ang);
										else
											if(g_Crits[iClient])
												g_Particle2[iClient] = AttachLoopParticleBone(iClient, EFFECT_BURNER_BLU_CRIT, "flag", pos, ang);
											else
												g_Particle2[iClient] = AttachLoopParticleBone(iClient, EFFECT_BURNER_BLU, "flag", pos, ang);
										ang[1] = 90.0;
										pos[1] = 0.0;
										
										pos[1] = 10.0;
										pos[2] =  4.0;
										pos[0] = 30.0;
										ang[1] = 75.0;
										AttachParticleBone(iClient, EFFECT_BURNER_EMPTY, "flag", 0.15, pos, ang);
										AttachParticleBone(iClient, EFFECT_BURNER_WARP, "flag", 0.15, pos, ang);	
										AttachParticleBone(iClient, EFFECT_BURNER_WARP2, "flag", 0.15, pos, ang);
										pos[0] = -30.0;
										ang[1] = 105.0;
										AttachParticleBone(iClient, EFFECT_BURNER_EMPTY, "flag", 0.15, pos, ang);
										AttachParticleBone(iClient, EFFECT_BURNER_WARP, "flag", 0.15, pos, ang);	
										AttachParticleBone(iClient, EFFECT_BURNER_WARP2, "flag", 0.15, pos, ang);
										pos[0] = 0.0;
										ang[1] = 90.0;
										
										g_State[iClient] = true;
											
										if(!IsLightEntity(g_LightEntity[iClient]))
										{
											new iEntity = CreateLightEntity(iClient);
											if(IsLightEntity(iEntity))
												g_LightEntity[iClient] = iEntity;
										}
									}
									else
										if(!(GetEntityFlags(iClient) & FL_INWATER))
										{
											new Float:fOrigin[3];
											new Float:fVelocity[3];
											GetEntPropVector(iClient, Prop_Data, "m_vecAbsVelocity", fVelocity);
											
											GetClientEyeAngles(iClient, fOrigin);
											fOrigin[0] *= (-1.0);
											fOrigin[1] = DegToRad(fOrigin[1]);
											
											if(fVelocity[2] >= 0.0)
											{
												if(fVelocity[2]<230.0)
													if(fOrigin[0]>20.0)
														fVelocity[2] *= GetConVarFloat(g_JetPackUpward);
													else
														fVelocity[2] *= GetConVarFloat(g_JetPackUp);
											}
											else
											{
												decl Handle:TraceEx;
												decl Float:hitPos[3];
												decl Float:clientPos[3];
												decl Float:targetPos[3];
												(TraceEx = INVALID_HANDLE);
												targetPos[0] = 0.0;
												targetPos[1] = 0.0;
												targetPos[2] = -4096.0;
												GetClientAbsOrigin(iClient, clientPos);
												
												TraceEx = TR_TraceRayFilterEx( clientPos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayer );
												if(TR_DidHit(TraceEx))
													TR_GetEndPosition( hitPos, TraceEx );
												if( GetVectorDistanceMeter(clientPos, hitPos) <= 1.125 )
													fVelocity[2] = 133.33;
												else
													fVelocity[2] *= (GetConVarFloat(g_JetPackFall));
													
												CloseHandle(TraceEx);
											}
											
											decl Float:fOriginLength[2];
											if(Cosine(fOrigin[1])<0)
												fOriginLength[0] = Cosine(fOrigin[1]) * (-1.0);
											else
												fOriginLength[0] = Cosine(fOrigin[1]);
											if(Sine(fOrigin[1])<0)
												fOriginLength[1] = Sine(fOrigin[1]) * (-1.0);
											else
												fOriginLength[1] = Sine(fOrigin[1]);
											
											decl Float:fVelVector[3];
											fVelVector[2] = 0.0;
											if(fVelocity[0]<230.0 && fVelocity[0]>-230.0)
												if(fVelocity[0]<5.0 && fVelocity[0]>-5.0)
												{
													fVelocity[0] /= GetConVarFloat(g_JetPackFrwd);
													fVelVector[0] = 0.0;
												}
												else
												{
													fVelVector[0] = GetConVarFloat(g_JetPackFrwd) * Cosine(fOrigin[1]);
													fVelocity[0] *= GetConVarFloat(g_JetPackFrwd);
												}
											if(fVelocity[1]<230.0 && fVelocity[1]>-230.0)
												if(fVelocity[1]<5.0 && fVelocity[1]>-5.0)
												{
													fVelocity[1] /= GetConVarFloat(g_JetPackFrwd);
													fVelVector[1] = 0.0;
												}
												else
												{
													fVelVector[1] = GetConVarFloat(g_JetPackFrwd) * Sine(fOrigin[1]);
													fVelocity[1] *= GetConVarFloat(g_JetPackFrwd);
												}
											
											SetEntPropVector(iClient, Prop_Data, "m_vecAbsVelocity", fVelocity);
											AddVectors(fVelocity,fVelVector,fVelocity);
											
											if(GetConVarBool(g_BurnEnemy))
											{
												new Float:clientPos[3];
												new Float:clientAng[3];
												new Float:targetPos[3];
												new Float:targetAng[3];
												new Float:diffYaw = 0.0;
												GetEntPropVector(iClient, Prop_Data, "m_vecAbsOrigin", clientPos);
												GetEntPropVector(iClient, Prop_Data, "m_angRotation", clientAng);
												
												for (new iVictim = 1; iVictim <= MaxClients; iVictim++)
													if(IsValidClient(iVictim) && IsPlayerAlive(iVictim) && iClient!=iVictim && (GetClientTeam(iClient)!=GetClientTeam(iVictim) || GetConVarInt(FindConVar("mp_friendlyfire"))==1))
												{
													GetEntPropVector(iVictim, Prop_Data, "m_vecAbsOrigin", targetPos);
													SubtractVectors(clientPos, targetPos, targetAng);
													GetVectorAngles(targetAng, targetAng);	
													diffYaw = (targetAng[1] - 180.0) - clientAng[1];
													diffYaw = FloatAbs(diffYaw);
														
													if( (diffYaw >= 135.0) && (diffYaw < 225.0) )
														if(CanSeeTarget(iClient, clientPos, iVictim, targetPos, 10.0, true, false))
															CreateFlameAttack(iVictim, iClient, GetRandomInt(3,7), g_Crits[iClient]);
												}
											}
										}
										else
											g_State[iClient] = false;
									g_Flying[iClient] = true;
								}
								g_ReleaseButton[iClient] = true;
							}
							else
							{
								g_ReleaseButton[iClient] = false;
								g_Flying[iClient] = false;
							}
							
							if( (GetEntityFlags(iClient) & FL_ONGROUND) || (GetEntityFlags(iClient) & FL_INWATER))
							{
								g_ReleaseButton[iClient] = false;
								g_Flying[iClient] = false;
							}
							
							if( !(GetClientButtons(iClient) & IN_JUMP) || (GetEntityFlags(iClient) & FL_ONGROUND) )
								if( g_State[iClient] )
								{
									g_State[iClient] = false;
									DeleteBurnerParticle(iClient);
									StopSound(iClient, 0, SOUND_BURNER_LOOP);
									StopSound(iClient, 0, SOUND_BURNER_LOOP_CRIT);
									EmitSoundToAll(SOUND_BURNER_END, iClient, _, _, SND_CHANGEPITCH, 0.3, 120);
									if(IsLightEntity(g_LightEntity[iClient]))
									{
										RemoveEdict(g_LightEntity[iClient]);
										g_LightEntity[iClient] = -1;
									}
								}
							
							SaveKeyTime(iClient);
						}
					}
					else
					{
						ResetPlayerData(iClient);
						if(IsValidEntity(iClient))
						SetEntityRenderColor(iClient, 255, 255, 255, 255);
					}
				}
			    else
		            ResetPlayerData(iClient);
			}
		}	    
    }       
}

public OnClientConnected(iClient)
{
	if(IsValidClient(iClient))
		ResetPlayerData(iClient);
}

public OnClientDisconnect(iClient)
{
	if(IsValidClient(iClient))
		ResetPlayerData(iClient);
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(IsValidClient(iClient))
		ResetPlayerData(iClient);
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{	
    {
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));	
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient) || !IsValidClient(iAttacker))
		return Plugin_Continue;
	
	if(!GetConVarBool(g_Enable))
		return Plugin_Continue;
	
	if(TF2_GetPlayerClass(iClient)!=TFClass_Pyro)
		return Plugin_Continue;
		
	ResetPlayerData(iClient);
	CreateTimer(0.001, HookRagdoll, iClient);
	return Plugin_Continue;
	}
}	
	
// timers

public Action:Timer_StartBurnerLoopSound(Handle:hTimer, any:iClient)
{
	if(g_State[iClient])
	{
		if(g_Crits[iClient])
			EmitSoundToAll(SOUND_BURNER_LOOP_CRIT, iClient, _, _, SND_CHANGEPITCH, 0.3, 120);
		else
			EmitSoundToAll(SOUND_BURNER_LOOP, iClient, _, _, SND_CHANGEPITCH, 0.3, 120);
		switch(GetRandomInt(1,4))
		{
			case 1:
			{
				EmitSoundToAll(SOUND_BURNER_VOICE1, iClient, _, _, SND_CHANGEPITCH, 0.8, 100);
			}
			case 2:
			{
				EmitSoundToAll(SOUND_BURNER_VOICE2, iClient, _, _, SND_CHANGEPITCH, 0.8, 100);
			}
			case 3:
			{
				EmitSoundToAll(SOUND_BURNER_VOICE3, iClient, _, _, SND_CHANGEPITCH, 0.8, 100);
			}
		}
	}
}

public Action:Timer_InstantKill(Handle:hTimer, any:iClient)
{
	if(IsValidClient(iClient) && IsPlayerAlive(iClient) && IsValidEntity(iClient))
	{
		g_bKilling[iClient] = true;
		SetEntityHealth(iClient, 1);
		SlapPlayer(iClient, 5);
		g_bKilling[iClient] = false;
    }
}

public Action:HookRagdoll(Handle:hTimer, any:iClient)
{
	decl String:sDissolveName[32];
	Format(sDissolveName, sizeof(sDissolveName), "dis_%d", iClient);
	
	new iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
	
	if(IsValidEdict(iRagdoll))
	{
		//SetEntityRenderColor(iRagdoll, 255, 255, 255, 255);
		DispatchKeyValue(iRagdoll, "targetname", sDissolveName);
	}
	
	decl iDissolver;
	iDissolver = CreateEntityByName("env_entity_dissolver");
	if(IsValidEdict(iDissolver))
	{
		DispatchKeyValue(iDissolver, "dissolvetype", "0");
		DispatchKeyValue(iDissolver, "target", sDissolveName);
		AcceptEntityInput(iDissolver, "Dissolve");
		AcceptEntityInput(iDissolver, "kill");
	}
	
	if(GetConVarBool(g_BurnEnemy2))
	{
		decl Float:fOrigin[3];
		GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fOrigin);
		decl Handle:hTimerData;
		//if(GetEntProp(iRagdoll, Prop_Send, 1))
			//CreateDataTimer(2.0, Timer_Explode, hTimerData);
		//else
		CreateDataTimer(0.001, Timer_Explode, hTimerData);
		WritePackCell(hTimerData, iClient);
		WritePackFloat(hTimerData, fOrigin[0]);
		WritePackFloat(hTimerData, fOrigin[1]);
		WritePackFloat(hTimerData, fOrigin[2]);
	}
}

public Action:Timer_Explode(Handle:hTimer, Handle:hData)
{
    {
	ResetPack(hData);
	new bool:bFF = GetConVarBool(FindConVar("mp_friendlyfire"));
	new iClient = ReadPackCell(hData);
	new Float:fOrigin[3];
	fOrigin[0] = ReadPackFloat(hData);
	fOrigin[1] = ReadPackFloat(hData);
	fOrigin[2] = ReadPackFloat(hData);
	EmitSoundFromOrigin(SOUND_PYRO_EXPLODE, fOrigin);
	TE_SetupExplosion(fOrigin, g_Explosion, 10.0, 1, 0, 1250, 500);
	TE_SendToAll();
	EmitSoundFromOrigin(SOUND_PYRO_EXPLODE, fOrigin);
	TE_SetupExplosion(fOrigin, g_Explosion, 10.0, 1, 0, 200, 1250);
	TE_SendToAll();
	decl Float:PlayerVec[3];
	decl Float:distance;
	if(GetClientTeam(iClient))
		for(new iVictim = 1; iVictim <= MaxClients; iVictim++)
		{
			if( iVictim<=0 || iVictim>MaxClients || !IsClientConnected(iVictim) || !IsClientInGame(iVictim) || !IsPlayerAlive(iVictim) || iVictim==iClient || GetClientTeam(iVictim)<=1 ) continue;
			if( !bFF ) if ( GetClientTeam(iVictim)==GetClientTeam(iClient) ) continue;
			GetClientAbsOrigin(iVictim, PlayerVec);
			distance = GetVectorDistanceMeter(fOrigin, PlayerVec, true);
			if(distance > 3000.0) continue;
			if(!CanSeeTarget(iClient, fOrigin, iVictim, PlayerVec, 3000.0, true, false)) continue;
			new damage = RoundFloat(3000.0 - distance) / 5;
			CreateFlameAttack(iVictim, iClient, damage, _, _, true);
		}
    }
}	

// additional functions

stock bool:CreateFlameAttack(any:iVictim, any:iAttacker=0, iDamage=5, bool:bCrits=false, bool:bMiniCrits=false, bool:bNoSlay=false)
{
	if(IsValidClient(iVictim) && (IsValidClient(iAttacker) || iAttacker==0))
	{	
	    if(!(GetEntityFlags(iVictim) & FL_INWATER) && (GetEntData(iVictim, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & TF_CONDFLAG_UBERCHARGED)!=TF_CONDFLAG_UBERCHARGED)
		{
			if(bCrits)
				iDamage *= GetRandomFloat(2.1,3.1);
			else if(bMiniCrits)
				iDamage *= GetRandomFloat(1.1,2.1);
			if((GetClientHealth(iVictim)-iDamage)>1)
			{
				new Handle:hTmpEvent = CreateEvent("player_hurt");
				if (hTmpEvent != INVALID_HANDLE && IsValidEntity(iVictim))
				{
					SetEventInt(hTmpEvent, "userid", GetClientUserId(iVictim));
					SetEventInt(hTmpEvent, "health", (GetClientHealth(iVictim)-iDamage));
					SetEventInt(hTmpEvent, "attacker", GetClientUserId(iAttacker));
					SetEventInt(hTmpEvent, "damageamount", iDamage);
					SetEventInt(hTmpEvent, "custom", 3);
					SetEventBool(hTmpEvent, "crit", bCrits);
					SetEventBool(hTmpEvent, "minicrit", false);
					SetEventBool(hTmpEvent, "allseecrit", (bCrits || bMiniCrits));
					SetEventInt(hTmpEvent, "weaponid", 21);
					FireEvent(hTmpEvent);
					TF2_IgnitePlayer(iVictim, iAttacker);
					SetEntityHealth(iVictim,(GetClientHealth(iVictim)-iDamage));
					return true;
				}
			}
			else
			{
				SetEntityHealth(iVictim,1);
				TF2_IgnitePlayer(iVictim, iAttacker);
				if(!bNoSlay)
					CreateTimer(1.0, Timer_InstantKill, iVictim);
				return true;
			}
		}
	}	
	return false;
}

stock CalculateCrit(any:iClient, iChance=5)
{
	if(IsValidClient(iClient))
		if(GetConVarInt(FindConVar("tf_weapon_criticals"))>0 && GetRandomInt(1,100)<iChance)
			g_Crits[iClient] = true;
		else
			g_Crits[iClient] = false;
}

public ResetPlayerData(any:iClient)
{
	DeleteBurnerParticle(iClient);	
	StopSound(iClient, 0, SOUND_BURNER_LOOP);
	StopSound(iClient, 0, SOUND_BURNER_LOOP_CRIT);
	if(IsLightEntity(g_LightEntity[iClient]))
	{
		RemoveEdict(g_LightEntity[iClient]);
		g_LightEntity[iClient] = -1;
	}
	g_FirstJump[iClient] = false;
	g_ReleaseButton[iClient] = false;
	g_Flying[iClient] = false;
	g_State[iClient] = false;
}

public bool:DeleteBurnerParticle(any:iClient)
{
	if (g_Particle1[iClient] != -1)
		if(IsValidEdict(g_Particle1[iClient]))
		{
			DeleteParticle(g_Particle1[iClient]);
			g_Particle1[iClient] = -1;
		}
		else
			return false;
	if (g_Particle2[iClient] != -1)
		if(IsValidEdict(g_Particle2[iClient]))
		{
			DeleteParticle(g_Particle2[iClient]);
			g_Particle2[iClient] = -1;
		}
		else
			return false;
	return true;
}

stock SaveKeyTime(any:iClient)
{
	if(IsValidClient(iClient,true))
		g_LastKeyCheckTime[iClient] = GetGameTime();
}

stock bool:CheckElapsedTime(any:iClient, Float:time)
{
	if(IsValidClient(iClient))
		if( (GetGameTime() - g_LastKeyCheckTime[iClient]) >= time )
			return true;
	return false;
}

stock bool:IsValidClient(any:iClient, bool:idOnly=false)
{
	if (iClient <= 0)
		return false;
	if (iClient > MaxClients)
		return false;
	if (!idOnly)
		return IsClientInGame(iClient);
	return true;
}

stock bool:PrePlayParticle(String:particlename[])
{
	if(IsValidEntity(0))
	{
		new particle = CreateEntityByName("info_particle_system");
		if (IsValidEdict(particle))
		{
			new String:tName[32];
			GetEntPropString(0, Prop_Data, "m_iName", tName, sizeof(tName));
			DispatchKeyValue(particle, "targetname", "tf2particle");
			DispatchKeyValue(particle, "parentname", tName);
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchSpawn(particle);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", 0, particle, 0);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			CreateTimer(0.01, RemoveParticle, particle);
			return true;
		}
		return false;
	}
	return false;
}

stock bool:AttachParticleBone(ent, String:particleType[], String:attachBone[], Float:time, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new String:tName[32];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, ent, 0);
		SetVariantString(attachBone);
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);
		TeleportEntity(particle, addPos, addAngle, NULL_VECTOR);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, RemoveParticle, particle);
		return true;
	}
	return false;
}

stock any:AttachLoopParticleBone(ent, String:particleType[], String:attachBone[], Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new String:tName[32];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, ent, 0);
		SetVariantString(attachBone);
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);

		TeleportEntity(particle, addPos, addAngle, NULL_VECTOR);
		AcceptEntityInput(particle, "start");
	}
	return particle;
}

stock DeleteParticle(&particle, Float:delay = 0.0)
{
	if(particle!= -1)
	{	
		if(IsValidEdict(particle))
		{
			new String:classname[32];
			GetEdictClassname( particle, classname, sizeof( classname ) );
			if( StrEqual( classname, "info_particle_system", false ) )
			{
				ActivateEntity( particle );
				AcceptEntityInput( particle, "stop" );
				CreateTimer( delay, RemoveParticle, particle );
				particle = -1;
	        }
		}
    }   
}

public Action:RemoveParticle( Handle:timer, any:particle )
{
	if(particle!= -1)
	{
    	if(IsValidEntity(particle))
		{
			new String:classname[32];
			GetEdictClassname(particle, classname, sizeof(classname));
			if (StrEqual(classname, "info_particle_system", false))
			{
				AcceptEntityInput(particle, "stop");
				AcceptEntityInput(particle, "Kill");
				particle = -1;
			}
		}
    } 
}

stock bool:CanSeeTarget( any:origin, Float:pos[3], any:target, Float:targetPos[3], Float:range, bool:throughPlayer=true, bool:throughBuild=true )
{
	new Float:distance;
	new Float:backpos[3];
	backpos = pos;
	distance = GetVectorDistanceMeter( pos, targetPos );
	if( distance >= range )
		return false;
	new Handle:TraceEx = INVALID_HANDLE;
	g_FilteredEntity = origin;
	TraceEx = TR_TraceRayFilterEx( pos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter );
	new hitEnt = -1;
	hitEnt = TR_GetEntityIndex( TraceEx );
	new Float:hitPos[3];
	TR_GetEndPosition( hitPos, TraceEx );
	if( GetVectorDistanceMeter( hitPos, targetPos ) <= 1.0 )
	{
		if( throughPlayer )
		{
			new String:edictName[64];
			GetEdictClassname( hitEnt, edictName, sizeof( edictName ) ); 
			if( StrEqual( edictName, "player" ) )  
			{
				GetEntPropVector( hitEnt, Prop_Data, "m_vecAbsOrigin", pos );
				if(GetVectorDistanceMeter( pos, targetPos ) > 1.0)
				{
					g_FilteredEntity = hitEnt;
					TraceEx = TR_TraceRayFilterEx( hitPos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter );
					hitEnt = TR_GetEntityIndex(TraceEx);
					TR_GetEndPosition( hitPos, TraceEx );
				}
				else
					pos = targetPos;
			}
			CloseHandle(TraceEx);
		}
		if( throughBuild )
		{
			new String:edictName[64];
			GetEdictClassname( hitEnt, edictName, sizeof( edictName ) ); 
			if( StrEqual(edictName, "obj_dispenser")
			|| StrEqual(edictName, "obj_sentrygun") 
			||	StrEqual(edictName, "obj_teleporter_entrance") 
			||	StrEqual(edictName, "obj_teleporter_exit")
			||	StrEqual(edictName, "obj_attachment_sapper")
			)
			{
				GetEntPropVector( hitEnt, Prop_Data, "m_vecAbsOrigin", pos );
				if(GetVectorDistanceMeter( pos, targetPos ) > 1.0)
				{
					g_FilteredEntity = hitEnt;
					(TraceEx) = TR_TraceRayFilterEx( hitPos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter );
					hitEnt = TR_GetEntityIndex(TraceEx);
					TR_GetEndPosition( hitPos, TraceEx );
				}
				else
					pos = targetPos;
			}
			CloseHandle(TraceEx);
		}		
	}
	if( GetVectorDistanceMeter( hitPos, targetPos ) <= 1.0 )
	{
		pos = backpos;
		return true;
	}
	pos = backpos;
	return false;
}

public bool:TraceFilter(ent, contentMask)
	return (ent == g_FilteredEntity) ? false : true;

public bool:TraceEntityFilterPlayer(entity, contentsMask)
	return entity > GetMaxClients() || !entity;

stock CreateLightEntity(iClient)
{
	if (!IsValidClient(iClient))
		return -1;
	if (!IsPlayerAlive(iClient))
		return -1;
	new iEntity = CreateEntityByName("light_dynamic");
	if (IsValidEntity(iEntity))
	{
		DispatchKeyValue(iEntity, "inner_cone", "0");
		DispatchKeyValue(iEntity, "cone", "80");
		DispatchKeyValue(iEntity, "brightness", "6");
		DispatchKeyValueFloat(iEntity, "spotlight_radius", 240.0);
		DispatchKeyValueFloat(iEntity, "distance", 250.0);
		DispatchKeyValue(iEntity, "_light", "255 100 10 41");
		DispatchKeyValue(iEntity, "pitch", "-90");
		DispatchKeyValue(iEntity, "style", "5");
		DispatchSpawn(iEntity);

		decl Float:fPos[3];
		decl Float:fAngle[3];
		decl Float:fAngle2[3];
		decl Float:fForward[3];
		decl Float:fOrigin[3];
		GetClientEyePosition(iClient, fPos);
		GetClientEyeAngles(iClient, fAngle);
		GetClientEyeAngles(iClient, fAngle2);

		fAngle2[0] = 0.0;
		fAngle2[2] = 0.0;
		GetAngleVectors(fAngle2, fForward, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fForward, -50.0);
		fForward[2] = 0.0;
		AddVectors(fPos, fForward, fOrigin);

		fAngle[0] += 90.0;
		fOrigin[2] -= 120.0;
		TeleportEntity(iEntity, fOrigin, fAngle, NULL_VECTOR);

		decl String:strName[32];
		Format(strName, sizeof(strName), "target%i", iClient);
		DispatchKeyValue(iClient, "targetname", strName);

		DispatchKeyValue(iEntity, "parentname", strName);
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", iClient, iEntity, 0);
		SetVariantString("head");
		AcceptEntityInput(iEntity, "SetParentAttachmentMaintainOffset", iClient, iEntity, 0);
		AcceptEntityInput(iEntity, "TurnOn");
	}
	return iEntity;
}

stock Float:GetVectorDistanceMeter(const Float:vec1[3], const Float:vec2[3], bool:squared=false)
	return ( GetVectorDistance( vec1, vec2, squared ) / 50.00 );

public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);

stock bool:IsLightEntity(iEntity)
{
    if (iEntity > 0)
	{
        if (IsValidEdict(iEntity))
		{
            decl String:strClassname[32];
            GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
            if(StrEqual(strClassname, "light_dynamic", false))
				return true;
        }
	}	
    return false;
}