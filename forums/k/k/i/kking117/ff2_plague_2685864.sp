#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <ff2_ams>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <tf2attributes>

#define PLUGIN_VERSION "1.0"

#define PLRName "plague_rage"
#define PLRAlias "PLR"

#define PLPName "plague_passive"

//////////////////PLRName///////////////////////////
new bool:FF2PLR_AMS[MAXPLAYERS+1];
new FF2PLR_Flags[MAXPLAYERS+1];
new FF2PLR_Style[MAXPLAYERS+1];
new FF2PLR_StunFlags[MAXPLAYERS+1];
new Float:FF2PLR_RageDur[MAXPLAYERS+1];

new Float:FF2PLR_InfectDur[MAXPLAYERS+1];
new Float:FF2PLR_InfectSpreadMult[MAXPLAYERS+1];
new Float:FF2PLR_InfectDmg[MAXPLAYERS+1];
new FF2PLR_DmgFix[MAXPLAYERS+1];
new Float:FF2PLR_InfectAttribs[MAXPLAYERS+1][15][2];
new Float:FF2PLR_InfectXBowHealMult[MAXPLAYERS+1];
new FF2PLR_CureMethod[MAXPLAYERS+1];
new Float:FF2PLR_MediRate[MAXPLAYERS+1];

new FF2PLR_InfectAddcond[MAXPLAYERS+1][32];

new String:SNDPLR_Infected[MAXPLAYERS+1][300];

new String:VISPLR_UserParticle[MAXPLAYERS+1][300];
new VISPLR_UserTeamAdd[MAXPLAYERS+1];
new Float:VISPLR_UserHeightOffset[MAXPLAYERS+1];
new String:VISPLR_UserOverlay[MAXPLAYERS+1][300];

new String:VISPLR_InfectParticle[MAXPLAYERS+1][300];
new VISPLR_InfectTeamAdd[MAXPLAYERS+1];
new Float:VISPLR_InfectHeightOffset[MAXPLAYERS+1];
new String:VISPLR_InfectOverlay[MAXPLAYERS+1][300];

new String:HUDPLR_PlaguedClue[MAXPLAYERS+1][100];
new String:HUDPLR_InfectedClue[MAXPLAYERS+1][100];
new String:HUDPLR_KillIcon[MAXPLAYERS+1][100];
//////////////////PLRName///////////////////////////

//////////////////PLPName///////////////////////////
new FF2PLP_Flags[MAXPLAYERS+1];
new FF2PLP_Style[MAXPLAYERS+1];
new FF2PLP_StunFlags[MAXPLAYERS+1];
new FF2PLP_LiveReq[MAXPLAYERS+1][16];

new Float:FF2PLP_InfectDur[MAXPLAYERS+1];
new Float:FF2PLP_InfectSpreadMult[MAXPLAYERS+1];
new Float:FF2PLP_InfectDmg[MAXPLAYERS+1];
new FF2PLP_DmgFix[MAXPLAYERS+1];
new Float:FF2PLP_InfectAttribs[MAXPLAYERS+1][15][2];
new Float:FF2PLP_InfectXBowHealMult[MAXPLAYERS+1];
new FF2PLP_CureMethod[MAXPLAYERS+1];
new Float:FF2PLP_MediRate[MAXPLAYERS+1];

new FF2PLP_InfectAddcond[MAXPLAYERS+1][32];

new String:SNDPLP_Infected[MAXPLAYERS+1][300];

new String:VISPLP_UserParticle[MAXPLAYERS+1][300];
new VISPLP_UserTeamAdd[MAXPLAYERS+1];
new Float:VISPLP_UserHeightOffset[MAXPLAYERS+1];
new String:VISPLP_UserOverlay[MAXPLAYERS+1][300];

new String:VISPLP_InfectParticle[MAXPLAYERS+1][300];
new VISPLP_InfectTeamAdd[MAXPLAYERS+1];
new Float:VISPLP_InfectHeightOffset[MAXPLAYERS+1];
new String:VISPLP_InfectOverlay[MAXPLAYERS+1][300];

new String:HUDPLP_PlaguedClue[MAXPLAYERS+1][100];
new String:HUDPLP_InfectedClue[MAXPLAYERS+1][100];
new String:HUDPLP_KillIcon[MAXPLAYERS+1][100];
//////////////////PLPName///////////////////////////

//general variables
new bool:HasPlagueRage[MAXPLAYERS+1];
new bool:HasPlaguePassive[MAXPLAYERS+1];
new bool:PlaguePassActive[MAXPLAYERS+1];
new Float:PlagueRageDur[MAXPLAYERS+1];

new PlagueParticleRef[MAXPLAYERS+1][2];
new bool:ParticleOn[MAXPLAYERS+1][2];

LastLiveNum[MAXPLAYERS+1];

new Float:LastPlagueNoise[MAXPLAYERS+1];
new Float:InfectionDur[MAXPLAYERS+1];
new Float:InfectionSpreadMult[MAXPLAYERS+1];
new Float:InfectionDmg[MAXPLAYERS+1];
new Float:InfectionDmgFix[MAXPLAYERS+1];
new InfectionOwner[MAXPLAYERS+1];
new Float:Infection_NextHit[MAXPLAYERS+1];
new Float:InfectGrace[MAXPLAYERS+1];
new InfectStyle[MAXPLAYERS+1];
new InfectionSpread[MAXPLAYERS+1];
new Float:InfectXBowMult[MAXPLAYERS+1];
new InfectCureMethod[MAXPLAYERS+1];
new Float:InfectCureRate[MAXPLAYERS+1];
new Float:InfectSpeedMult[MAXPLAYERS+1];
new Float:LastPlagueHit[MAXPLAYERS+1];
new InfectionAddcond[MAXPLAYERS+1][32];
new Float:InfectionAttribs[MAXPLAYERS+1][15][2];
new String:InfectionClue[MAXPLAYERS+1][100];
new String:InfectionKillIcon[MAXPLAYERS+1][100];
new String:InfectionOverlay[MAXPLAYERS+1][100];
new String:InfectionSND[MAXPLAYERS+1][300];
new String:InfectionParticle[MAXPLAYERS+1][300];
new InfectionTeamPart[MAXPLAYERS+1];
new Float:InfectionOffsetPart[MAXPLAYERS+1];

new LastHP[MAXPLAYERS+1];
new LastDmgType[MAXPLAYERS+1];
new LastInflictor[MAXPLAYERS+1];

public Plugin:myinfo=
{
	name="Freak Fortress 2: Plague",
	author="kking117",
	description="Adds a configurable replication of the Plague power up from Mann Power.",
	version=PLUGIN_VERSION,
};

public OnPluginStart2()
{
	HookEvent("post_inventory_application", OnRefreshLoadout, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
	HookEvent("crossbow_heal", OnCrossbowHeal, EventHookMode_Pre);
	
	HookEvent("arena_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", OnRoundEnd, EventHookMode_PostNoCopy);
	
	HookEntityOutput("item_healthkit_small",  "OnPlayerTouch",    EntityOutput_HealthKit);
	HookEntityOutput("item_healthkit_medium", "OnPlayerTouch",    EntityOutput_HealthKit);
	HookEntityOutput("item_healthkit_full",   "OnPlayerTouch",    EntityOutput_HealthKit);
	
	HookEntityOutput("item_healthkit_small",  "OnCacheInteraction",    EntityOutput_HealthKitPre);
	HookEntityOutput("item_healthkit_medium", "OnCacheInteraction",    EntityOutput_HealthKitPre);
	HookEntityOutput("item_healthkit_full",   "OnCacheInteraction",    EntityOutput_HealthKitPre);
	
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			SDKHook(client, SDKHook_StartTouch, PlagueTouch);
			SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_StartTouch, PlagueTouch);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	ClearVariables(client);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			ClearVariables(client);
			if(IsBoss(client))
			{
				if(FF2_HasAbility(FF2_GetBossIndex(client), this_plugin_name, PLRName))
				{
					RegisterBossAbility(client, PLRName);
				}
				if(FF2_HasAbility(FF2_GetBossIndex(client), this_plugin_name, PLPName))
				{
					RegisterBossAbility(client, PLPName);
				}
			}
		}
	}
	CreateTimer(0.25, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			ClearVariables(client);
		}
	}
	return Plugin_Continue;
}

public Action:OnTakeDamageAlive(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(IsValidClient(client))
	{
		LastDmgType[client] = damagetype;
		new String:ClassName[100];
		GetEntityClassname(inflictor, ClassName, sizeof(ClassName));
		LastInflictor[client] = inflictor;
	}
	return Plugin_Continue;
}

public Action:OnCrossbowHeal(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new client=GetClientOfUserId(GetEventInt(event, "healer"));
	new target=GetClientOfUserId(GetEventInt(event, "target"));
	new healing=GetEventInt(event, "amount");
	if(InfectXBowMult[target]!=1.0)
	{
		healing = RoundToNearest(healing*InfectXBowMult[target]);
		HealClient(target, healing, LastHP[target], false, false);
	}
	return Plugin_Continue;
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage=GetEventInt(event, "damageamount");
	if(damage>0)
	{
		if(IsValidClient(attacker))
		{
			if(IsValidEntity(LastInflictor[client]))
			{
				new String:WepName[100];
				GetEntityClassname(LastInflictor[client], WepName, sizeof(WepName));
				if(StrEqual(WepName, "player", false))
				{
					if(LastDmgType[client] & DMG_CLUB)
					{
						if(PassiveActive(attacker))
						{
							if(FF2PLP_Flags[attacker] & 4)
							{
								InfectClientMaster(client, attacker);
							}
						}
						else if(HasPlagueRage[attacker])
						{
							if(PlagueRageDur[attacker]>=GetGameTime())
							{
								if(FF2PLR_Flags[attacker] & 4)
								{
									InfectClientMaster(client, attacker);
								}
							}
						}
						
						if(PassiveActive(client))
						{
							if(FF2PLP_Flags[client] & 2)
							{
								InfectClientMaster(attacker, client);
							}
						}
						else if(HasPlagueRage[client])
						{
							if(PlagueRageDur[client]>=GetGameTime())
							{
								if(FF2PLR_Flags[client] & 2)
								{
									InfectClientMaster(attacker, client);
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:OnRefreshLoadout(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		ClearVariables(client);
		if(IsBoss(client))
		{
			if(FF2_HasAbility(FF2_GetBossIndex(client), this_plugin_name, PLRName))
			{
				RegisterBossAbility(client, PLRName);
			}
			if(FF2_HasAbility(FF2_GetBossIndex(client), this_plugin_name, PLPName))
			{
				RegisterBossAbility(client, PLPName);
			}
		}
	}
}

public Action:OnPlayerDeath(Handle:event, const String:eventName[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new damagetype = GetEventInt(event, "damagebits");
	if(damagetype & DMG_SLASH)
	{
		if(LastPlagueHit[client]>=GetGameTime())
		{
			if(strlen(InfectionKillIcon[client])>0)
			{
				SetEventString(event, "weapon", InfectionKillIcon[client]);
			}
			SetEventString(event, "weapon_logclassname", "the plague");
		}
	}
	if(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
	{
		if(InfectCureMethod[client] & 2)
		{
			CureInfection(client);
		}
	}
	else
	{
		CureInfection(client);
	}
	return Plugin_Continue;
}

public Action:ClientTimer(Handle:timer)
{
	return Plugin_Continue;
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], status)
{
	//new slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0);
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!strcmp(ability_name, PLRName))
	{
		if(FF2PLR_AMS[client])
		{
			if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
			{
				FF2PLR_AMS[client]=false;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		PLR_Invoke(client);
	}
	return Plugin_Continue;
}

public void PLR_Invoke(client)
{
	PlagueRageDur[client]=GetGameTime()+FF2PLR_RageDur[client];
	if(strlen(HUDPLR_PlaguedClue[client])>0)
	{
		PrintCenterText(client, HUDPLR_PlaguedClue[client]);
	}
	if(strlen(VISPLR_UserParticle[client])>0)
	{
		CreatePlagueParticle(client, VISPLR_UserParticle[client], VISPLR_UserTeamAdd[client], 0);
	}
	if(strlen(VISPLR_UserOverlay[client])>0)
	{
		new String:overlay[PLATFORM_MAX_PATH];
		Format(overlay, sizeof(overlay), "r_screenoverlay \"%s\"", VISPLR_UserOverlay[client]);
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
		ClientCommand(client, overlay);
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	}
}

public bool PLR_CanInvoke(client)
{
	return true;
}

stock bool:IsValidClient(client, bool:replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
	{
	}
	else
	{
		if(IsPlayerAlive(client))
		{
			if(IsBoss(client))
			{
				new lives = FF2_GetBossLives(FF2_GetBossIndex(client));
				if(LastLiveNum[client]!=lives)
				{
					LastLiveNum[client]=lives;
					if(LiveReq_True(lives, FF2PLP_LiveReq[client]))
					{
						if(!PlaguePassActive[client])
						{
							CreatePlagueParticle(client, VISPLP_UserParticle[client], VISPLP_UserTeamAdd[client], 1);
							EmitSoundToAll(SNDPLP_Infected[client], client, _, SNDLEVEL_SCREAMING);
							PrintCenterText(client, HUDPLP_PlaguedClue[client]);
						}
						PlaguePassActive[client]=true;
					}
					else
					{
						KillPlagueParticle(client, 1);
						PlaguePassActive[client]=false;
					}
				}
			}
			if(IsHidden(client))
			{
				if(ParticleOn[client][0])
				{
					HidePlagueParticle(client, 0);
				}
				if(ParticleOn[client][1])
				{
					HidePlagueParticle(client, 1);
				}
			}
			else
			{
				if(!ParticleOn[client][0])
				{
					ShowPlagueParticle(client, 0);
				}
				if(!ParticleOn[client][1])
				{
					ShowPlagueParticle(client, 1);
				}
			}
			if(PlaguePassActive[client])
			{
				RelocatePlagueParticle(client, 1);
			}
			if(HasPlagueRage[client])
			{
				if(PlagueRageDur[client]>=GetGameTime())
				{
					RelocatePlagueParticle(client, 0);
				}
				else if(PlagueRageDur[client]>0.0)
				{
					EndPlagueRage(client);
				}
			}
			if(InfectionDur[client]>=GetGameTime())
			{
				if(IsUbered(client) && (InfectCureMethod[client] & 4))
				{
					CureInfection(client);
				}
				else
				{
					if(Infection_NextHit[client]<=GetGameTime())
					{
						if(InfectionOwner[client]==-1)
						{
							LastPlagueHit[client]=GetGameTime();
							DamageEntity(client, client, InfectionDmg[client], 4);
						}
						else
						{
							new plagueowner = GetClientOfUserId(InfectionOwner[client]);
							if(IsValidClient(plagueowner))
							{
								if(IsBoss(plagueowner))
								{
									LastPlagueHit[client]=GetGameTime();
									DamageEntity(client, plagueowner, InfectionDmgFix[client], 4);
								}
								else
								{
									LastPlagueHit[client]=GetGameTime();
									DamageEntity(client, plagueowner, InfectionDmg[client], 4);
								}
							}
							else
							{
								InfectionOwner[client] = -1;
								LastPlagueHit[client]=GetGameTime();
								DamageEntity(client, client, InfectionDmg[client], 4);
							}
						}
						Infection_NextHit[client]+=0.5;
					}
					if(InfectionSpread[client] & 8)
					{
						if(InfectionDur[client]-GetGameTime()>0.75)
						{
							PlagueSpreadCheck(client);
						}
					}
					RelocatePlagueParticle(client, 0);
					CondApply_Infection(client, InfectionAddcond[client]);
				}
			}
			else if(InfectionDur[client]>0.0)
			{
				CureInfection(client);
			}
			PlagueMedigunCheck(client);
		}
		else
		{
			if(HasPlagueRage[client])
			{
				if(PlagueRageDur[client]>0.0)
				{
					EndPlagueRage(client);
				}
			}
			else
			{
				if(InfectionDur[client]>0.0)
				{
					CureInfection(client);
				}
			}
		}
	}
	LastHP[client] = GetEntityHealth(client);
}

PlagueMedigunCheck(client)
{
	new patient = GetHealingTarget(GetPlayerWeaponSlot(client, 1));
	if(IsValidClient(patient))
	{
		new bool:TeamMate = false;
		if(GetClientTeam(patient)==GetClientTeam(client))
		{
			TeamMate=true;
		}
		if(TeamMate)
		{
			if(InfectionDur[patient]>0.0)
			{
				if(InfectCureRate[patient]!=0.0)
				{
					InfectionDur[patient]-=0.01515*InfectCureRate[patient];
				}
				if(InfectionDur[patient]-GetGameTime()>0.75 && (InfectionSpread[patient] & 16))
				{
					InfectClientClone(client, patient);
				}
			}
			else if(InfectionDur[client]-GetGameTime()>0.75 && (InfectionSpread[client] & 32))
			{
				InfectClientClone(patient, client);
			}
		}
		else
		{
			if(PassiveActive(client))
			{
				if(FF2PLP_Flags[client] & 16)
				{
					InfectClientMaster(patient, client);
				}
			}
			else if(HasPlagueRage[client])
			{
				if(PlagueRageDur[client]>0.0 && (FF2PLR_Flags[client] & 16))
				{
					InfectClientMaster(patient, client);
				}
			}
		}
	}
}

stock GetHealingTarget(weapon)
{
	if(IsValidEntity(weapon))
	{
		if(HasEntProp(weapon, Prop_Send, "m_bHealing"))
		{
			return GetEntPropEnt(weapon, Prop_Send, "m_hHealingTarget");
		}
	}
	return -1;
}

public EntityOutput_HealthKit(const String:output[], caller, activator, Float:delay)
{
	if(IsValidClient(activator))
	{
		if(IsPlayerAlive(activator))
		{
			if(InfectionDur[activator]>GetGameTime())
			{
				if(InfectCureMethod[activator] & 1)
				{
					//this is so heavies can't cure theirself by picking up their lunchbox item
					//other classes can't pickup their own dropped sandvich, it just gets consumed like a normal health pack
					if((GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity")!=activator) || (GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity")==activator && TF2_GetPlayerClass(activator)!=TFClass_Heavy))
					{
						CureInfection(activator);
					}
				}
			}
		}
	}
}

public EntityOutput_HealthKitPre(const String:output[], caller, activator, Float:delay)
{
	if(IsValidClient(activator))
	{
		if(IsPlayerAlive(activator))
		{
			if(InfectionDur[activator]>GetGameTime())
			{
				if(InfectCureMethod[activator] & 1)
				{
					if(!TF2_IsPlayerInCondition(activator, TFCond_Bleeding) || !TF2_IsPlayerInCondition(activator, TFCond_OnFire))
					{
						TF2_AddCondition(activator, TFCond_Bleeding, 0.05);
					}
				}
			}
		}
	}
}

CreatePlagueParticle(client, String:particlename[], TeamCoded = 0, slot = 0)
{
	KillPlagueParticle(client, slot);
	new entity = CreateEntityByName("info_particle_system");
	if(IsValidEntity(entity))
	{
		new teamnum = GetClientTeam(client);
		new String:particlecopy[300];
		strcopy(particlecopy, 300, particlename);
		if(TeamCoded!=0)
		{
			if(teamnum==2)
			{
				StrCat(particlecopy, 300, "_red");
			}
			else if(teamnum==3)
			{
				StrCat(particlecopy, 300, "_blue");
			}
		}
		DispatchKeyValue(entity, "targetname", "tf2particle");
		DispatchKeyValue(entity, "effect_name", particlecopy);
		DispatchKeyValue(entity, "angles", "-90.0, 0.0, 0.0"); 
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");
		ParticleOn[client][slot]=true;
		PlagueParticleRef[client][slot] = EntIndexToEntRef(entity);		
	}
}

RelocatePlagueParticle(client, slot = 0)
{
	if(PlagueParticleRef[client][slot]!=-1)
	{
		new entity = EntRefToEntIndex(PlagueParticleRef[client][slot]);
		if(IsValidEntity(entity))
		{
			new Float:pos[3];
			new Float:vel[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
			pos[0]+=vel[0]*0.02;
			pos[1]+=vel[1]*0.02;
			pos[2]+=vel[2]*0.02;
			if(slot==0)
			{
				if(HasPlagueRage[client])
				{
					pos[2] += VISPLR_UserHeightOffset[client]*GetEntPropFloat(client, Prop_Send, "m_flModelScale");
				}
				else
				{
					pos[2] += InfectionOffsetPart[client]*GetEntPropFloat(client, Prop_Send, "m_flModelScale");
				}
			}
			else
			{
				pos[2] += VISPLP_UserHeightOffset[client]*GetEntPropFloat(client, Prop_Send, "m_flModelScale");
			}
			TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		}
		else
		{
			PlagueParticleRef[client][slot]=-1;
		}
	}
}

KillPlagueParticle(client, slot = 0)
{
	if(PlagueParticleRef[client][slot]!=-1)
	{
		new entity = EntRefToEntIndex(PlagueParticleRef[client][slot]);
		if(IsValidEntity(entity))
		{
			new String:ClassName[100];
			GetEntityClassname(entity, ClassName, sizeof(ClassName));
			if(StrEqual(ClassName, "info_particle_system", false))
			{
				AcceptEntityInput(entity, "kill");
			}
		}
		PlagueParticleRef[client][slot]=-1;
	}
}

HidePlagueParticle(client, slot = 0)
{
	if(PlagueParticleRef[client][slot]!=-1)
	{
		new entity = EntRefToEntIndex(PlagueParticleRef[client][slot]);
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "stop");
			ParticleOn[client][slot]=false;
		}
	}
}

ShowPlagueParticle(client, slot = 0)
{
	if(PlagueParticleRef[client][slot]!=-1)
	{
		new entity = EntRefToEntIndex(PlagueParticleRef[client][slot]);
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "start");
			ParticleOn[client][slot]=true;
		}
	}
}

InfectClientMaster(victim, client)
{
	if(InfectGrace[victim]<GetGameTime() && CanInfect(victim))
	{
		if(PassiveActive(client))
		{
			if(!ClientHasStunFlags(client, FF2PLP_StunFlags[client]))
			{
				AttribRemove_Infection(victim, InfectionAttribs[victim]);
				strcopy(InfectionSND[victim], 300, SNDPLP_Infected[client]);
				strcopy(InfectionClue[victim], 100, HUDPLP_InfectedClue[client]);
				strcopy(InfectionParticle[victim], 300, VISPLP_InfectParticle[client]);
				strcopy(InfectionOverlay[victim], 300, VISPLP_InfectOverlay[client]);
				strcopy(InfectionKillIcon[victim], 100, HUDPLP_KillIcon[client]);
				InfectionTeamPart[victim] = VISPLP_InfectTeamAdd[client];
				InfectionOffsetPart[victim] = VISPLP_InfectHeightOffset[client];
				if(strlen(InfectionParticle[victim])>0)
				{
					CreatePlagueParticle(victim, InfectionParticle[victim], InfectionTeamPart[victim], 0);
				}
				if(strlen(InfectionOverlay[victim])>0)
				{
					new String:overlay[PLATFORM_MAX_PATH];
					Format(overlay, sizeof(overlay), "r_screenoverlay \"%s\"", InfectionOverlay[victim]);
					SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
					ClientCommand(victim, overlay);
					SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
				}
				if(strlen(InfectionClue[victim])>0)
				{
					PrintCenterText(victim, InfectionClue[victim]);
				}
				if(strlen(InfectionSND[victim])>0)
				{
					if(GetGameTime()-LastPlagueNoise[victim]>2.0)
					{
						EmitSoundToAll(InfectionSND[victim], victim, _, SNDLEVEL_SCREAMING);
					}
					else
					{
						EmitSoundToAll(InfectionSND[victim], victim, _, SNDLEVEL_SCREAMING, _, 0.02+((GetGameTime()-LastPlagueNoise[victim])*0.49));
					}
					if(GetGameTime()-LastPlagueNoise[client]>2.0)
					{
						EmitSoundToAll(InfectionSND[victim], client, _, SNDLEVEL_SCREAMING);
					}
					else
					{
						EmitSoundToAll(InfectionSND[victim], client, _, SNDLEVEL_SCREAMING, _, 0.02+((GetGameTime()-LastPlagueNoise[client])*0.49));
					}
				}
				InfectionOwner[victim] = GetClientUserId(client);
				InfectStyle[victim] = FF2PLP_Style[client];
				InfectionDur[victim]=GetGameTime()+FF2PLP_InfectDur[client];
				InfectionSpreadMult[victim] = FF2PLP_InfectSpreadMult[client];
				InfectionDmg[victim]=FF2PLP_InfectDmg[client];
				InfectionDmgFix[victim]=FF2PLP_InfectDmg[client];
				if(FF2PLP_DmgFix[client]!=0)
				{
					if(InfectionDmgFix[victim]<=160.0)
					{
						InfectionDmgFix[victim]*=0.34;
					}
				}
				if(Infection_NextHit[victim]<=GetGameTime())
				{
					Infection_NextHit[victim]=GetGameTime()+0.49;
				}
				InfectGrace[victim] = GetGameTime()+0.5;
				InfectionSpread[victim] = FF2PLP_Flags[client];
				InfectXBowMult[victim] = FF2PLP_InfectXBowHealMult[client];
				InfectCureMethod[victim] = FF2PLP_CureMethod[client];
				InfectCureRate[victim] = FF2PLP_MediRate[client];
				CondClone_Infection(victim, FF2PLP_InfectAddcond[client]);
				AttribClone_Infection(victim, FF2PLP_InfectAttribs[client]);
				AttribApply_Infection(victim, InfectionAttribs[victim]);
				LastPlagueNoise[client]=GetGameTime();
				LastPlagueNoise[victim]=GetGameTime();
			}
		}
		else if(!ClientHasStunFlags(client, FF2PLR_StunFlags[client]))
		{
			AttribRemove_Infection(victim, InfectionAttribs[victim]);
			strcopy(InfectionSND[victim], 300, SNDPLR_Infected[client]);
			strcopy(InfectionClue[victim], 100, HUDPLR_InfectedClue[client]);
			strcopy(InfectionParticle[victim], 300, VISPLR_InfectParticle[client]);
			strcopy(InfectionOverlay[victim], 300, VISPLR_InfectOverlay[client]);
			strcopy(InfectionKillIcon[victim], 100, HUDPLR_KillIcon[client]);
			InfectionTeamPart[victim] = VISPLR_InfectTeamAdd[client];
			InfectionOffsetPart[victim] = VISPLR_InfectHeightOffset[client];
			if(strlen(InfectionParticle[victim])>0)
			{
				CreatePlagueParticle(victim, InfectionParticle[victim], InfectionTeamPart[victim], 0);
			}
			if(strlen(InfectionOverlay[victim])>0)
			{
				new String:overlay[PLATFORM_MAX_PATH];
				Format(overlay, sizeof(overlay), "r_screenoverlay \"%s\"", InfectionOverlay[victim]);
				SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
				ClientCommand(victim, overlay);
				SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
			}
			if(strlen(InfectionClue[victim])>0)
			{
				PrintCenterText(victim, InfectionClue[victim]);
			}
			if(strlen(InfectionSND[victim])>0)
			{
				if(GetGameTime()-LastPlagueNoise[victim]>2.0)
				{
					EmitSoundToAll(InfectionSND[victim], victim, _, SNDLEVEL_SCREAMING);
				}
				else
				{
					EmitSoundToAll(InfectionSND[victim], victim, _, SNDLEVEL_SCREAMING, _, 0.02+((GetGameTime()-LastPlagueNoise[victim])*0.49));
				}
				if(GetGameTime()-LastPlagueNoise[client]>2.0)
				{
					EmitSoundToAll(InfectionSND[victim], client, _, SNDLEVEL_SCREAMING);
				}
				else
				{
					EmitSoundToAll(InfectionSND[victim], client, _, SNDLEVEL_SCREAMING, _, 0.02+((GetGameTime()-LastPlagueNoise[client])*0.49));
				}
			}
			InfectionOwner[victim] = GetClientUserId(client);
			InfectStyle[victim] = FF2PLR_Style[client];
			InfectionDur[victim]=GetGameTime()+FF2PLR_InfectDur[client];
			InfectionSpreadMult[victim] = FF2PLR_InfectSpreadMult[client];
			InfectionDmg[victim]=FF2PLR_InfectDmg[client];
			InfectionDmgFix[victim]=FF2PLR_InfectDmg[client];
			if(FF2PLR_DmgFix[client]!=0)
			{
				if(InfectionDmgFix[victim]<=160.0)
				{
					InfectionDmgFix[victim]*=0.34;
				}
			}
			if(Infection_NextHit[victim]<=GetGameTime())
			{
				Infection_NextHit[victim]=GetGameTime()+0.49;
			}
			InfectGrace[victim] = GetGameTime()+0.5;
			InfectionSpread[victim] = FF2PLR_Flags[client];
			InfectXBowMult[victim] = FF2PLR_InfectXBowHealMult[client];
			InfectCureMethod[victim] = FF2PLR_CureMethod[client];
			InfectCureRate[victim] = FF2PLR_MediRate[client];
			CondClone_Infection(victim, FF2PLR_InfectAddcond[client]);
			AttribClone_Infection(victim, FF2PLR_InfectAttribs[client]);
			AttribApply_Infection(victim, InfectionAttribs[victim]);
			LastPlagueNoise[client]=GetGameTime();
			LastPlagueNoise[victim]=GetGameTime();
		}
	}
}

InfectClientClone(victim, client)
{
	if(InfectGrace[victim]<GetGameTime() && CanInfect(victim))
	{
		AttribRemove_Infection(victim, InfectionAttribs[victim]);
		strcopy(InfectionSND[victim], 300, InfectionSND[client]);
		strcopy(InfectionClue[victim], 100, InfectionClue[client]);
		strcopy(InfectionParticle[victim], 300, InfectionParticle[client]);
		strcopy(InfectionOverlay[victim], 300, InfectionOverlay[client]);
		strcopy(InfectionKillIcon[victim], 100, InfectionKillIcon[client]);
		InfectionTeamPart[victim] = InfectionTeamPart[client];
		InfectionOffsetPart[victim] = InfectionOffsetPart[client];
		if(strlen(InfectionParticle[victim])>0)
		{
			CreatePlagueParticle(victim, InfectionParticle[victim], InfectionTeamPart[victim], 0);
		}
		if(strlen(InfectionOverlay[victim])>0)
		{
			new String:overlay[PLATFORM_MAX_PATH];
			Format(overlay, sizeof(overlay), "r_screenoverlay \"%s\"", InfectionOverlay[victim]);
			SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
			ClientCommand(victim, overlay);
			SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
		}
		if(strlen(InfectionClue[victim])>0)
		{
			PrintCenterText(victim, InfectionClue[victim]);
		}
		if(strlen(InfectionSND[victim])>0)
		{
			if(GetGameTime()-LastPlagueNoise[victim]>2.0)
			{
				EmitSoundToAll(InfectionSND[victim], victim, _, SNDLEVEL_SCREAMING);
			}
			else
			{
				EmitSoundToAll(InfectionSND[victim], victim, _, SNDLEVEL_SCREAMING, _, 0.02+((GetGameTime()-LastPlagueNoise[victim])*0.49));
			}
			if(GetGameTime()-LastPlagueNoise[client]>2.0)
			{
				EmitSoundToAll(InfectionSND[victim], client, _, SNDLEVEL_SCREAMING);
			}
			else
			{
				EmitSoundToAll(InfectionSND[victim], client, _, SNDLEVEL_SCREAMING, _, 0.02+((GetGameTime()-LastPlagueNoise[client])*0.49));
			}
		}
		InfectionOwner[victim] = InfectionOwner[client];
		InfectStyle[victim] = InfectStyle[client];
		if(InfectionSpreadMult[client]==1.0)
		{
			InfectionDur[victim] = InfectionSpreadMult[client];
		}
		else
		{
			InfectionDur[client] = GetGameTime()+((InfectionDur[client]-GetGameTime())*InfectionSpreadMult[client]);
			InfectionDur[victim] = InfectionDur[client];	
		}
		InfectionSpreadMult[victim] = InfectionSpreadMult[client];
		InfectionDmg[victim]= InfectionDmg[client];
		InfectionDmgFix[victim]= InfectionDmgFix[client];
		if(Infection_NextHit[victim]<=GetGameTime())
		{
			Infection_NextHit[victim]=GetGameTime()+0.49;
		}
		InfectionSpread[victim] = InfectionSpread[client];
		InfectGrace[victim] = GetGameTime()+0.5;
		InfectXBowMult[victim] = InfectXBowMult[client];
		InfectCureMethod[victim] = InfectCureMethod[client];
		InfectCureRate[victim] = InfectCureRate[client];
		InfectSpeedMult[victim] = InfectSpeedMult[client];
		CondClone_Infection(victim, InfectionAddcond[client]);
		AttribClone_Infection(victim, InfectionAttribs[client]);
		AttribApply_Infection(victim, InfectionAttribs[victim]);
		LastPlagueNoise[client]=GetGameTime();
		LastPlagueNoise[victim]=GetGameTime();
	}
}

EndPlagueRage(client)
{
	KillPlagueParticle(client, 0);
	PlagueRageDur[client]=-1.0;
	if(strlen(VISPLR_UserOverlay[client])>0)
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
		ClientCommand(client, "r_screenoverlay \"\"");
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	}
}

CureInfection(client)
{
	CondClear_Build(InfectionAddcond[client]);
	KillPlagueParticle(client, 0);
	AttribRemove_Infection(client, InfectionAttribs[client]);
	AttribClear_Build(InfectionAttribs[client]);
	InfectCureMethod[client] = 0;
	InfectionDur[client]=-1.0;
	InfectionDmg[client]=0.0;
	InfectionDmgFix[client]=0.0;
	InfectStyle[client]=0;
	InfectionOwner[client]=-1;
	InfectGrace[client]=GetGameTime()+0.5;
	Infection_NextHit[client]=-1.0;
	InfectionSpread[client] = 0;
	InfectXBowMult[client] = 1.0;
	InfectCureMethod[client] = 0;
	InfectCureRate[client] = 1.0;
	Format(InfectionKillIcon[client], 100, "");
	Format(InfectionClue[client], 100, "");
	Format(InfectionSND[client], 300, "");
	Format(InfectionParticle[client], 300, "");
	InfectionTeamPart[client] = 0;
	InfectionOffsetPart[client] = 20.0;
	
	if(strlen(InfectionOverlay[client])>0)
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
		ClientCommand(client, "r_screenoverlay \"\"");
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	}
	Format(InfectionOverlay[client], 300, "");
}

PlagueSpreadCheck(client)
{
	new Float:clpos[3], Float:trpos[3];
	new Float:distance = 50.0*GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clpos);
	clpos[2]+=distance*0.5;
	for(new target=0; target<=MaxClients; target++)
	{
		if(IsValidClient(target))
		{
			if(IsPlayerAlive(target))
			{
				if(GetClientTeam(target)==GetClientTeam(client))
				{
					if(InfectionDur[target]<GetGameTime())
					{
						GetEntPropVector(target, Prop_Send, "m_vecOrigin", trpos);
						trpos[2]+=distance*0.5;
						if(GetVectorDistance(clpos, trpos)<=distance)
						{
							if(InfectionSpreadMult[client]>0.0)
							{
								InfectClientClone(target, client);
							}
							else
							{
								CureInfection(client);
								break;
							}
						}
					}
				}
			}
		}
	}
}

public Action:PlagueTouch(entity, other)
{
	if(IsValidClient(entity))
	{
		if(IsValidClient(other))
		{
			if(PassiveActive(entity))
			{
				if(FF2PLP_Flags[entity] & 1)
				{
					if(GetClientTeam(other)!=GetClientTeam(entity))
					{
						InfectClientMaster(other, entity);
					}
				}
			}
			else if(PlagueRageDur[entity]>=GetGameTime())
			{
				if(FF2PLR_Flags[entity] & 1)
				{
					if(GetClientTeam(other)!=GetClientTeam(entity))
					{
						InfectClientMaster(other, entity);
					}
				}
			}
		}
	}
}

RegisterBossAbility(client, String:ability_name[])
{
	if(IsBoss(client))
	{
		new boss=FF2_GetBossIndex(client);
		if(StrEqual(ability_name, PLRName, false))
		{
			//ams' suitability check either doesn't work right or isn't meant to check if the ability slot is using it
			//so I'm doing this for a sanity check
			//it should work fine since nobody in their right mind would set its ams slot below 0 unless they were disabling it in some jank way
			if(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 1006, -1)>=0)
			{
				if(AMS_IsSubabilityReady(boss, this_plugin_name, PLRName))
				{
					FF2PLR_AMS[client] = true;
					AMS_InitSubability(boss, client, this_plugin_name, PLRName, PLRAlias);
				}
			}
			else
			{
				FF2PLR_AMS[client] = false;
			}
			
			HasPlagueRage[client] = true;
			
			FF2PLR_Flags[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 1, 5);
			FF2PLR_Style[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 2, 1);
			FF2PLR_StunFlags[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 3, 14);
			FF2PLR_RageDur[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 4, 15.0);
			FF2PLR_CureMethod[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 5, 1);
			FF2PLR_MediRate[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 6, 1.0);
			
			FF2PLR_InfectDur[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 10, 20.0);
			FF2PLR_InfectSpreadMult[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 11, 0.5);
			FF2PLR_InfectDmg[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 12, 3.0);
			FF2PLR_DmgFix[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 13, 1);
			FF2PLR_InfectXBowHealMult[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 14, 1.0);
			AttribList_Build(boss, 15, PLRName, FF2PLR_InfectAttribs[client]);
			CondList_Build(boss, 16, PLRName, FF2PLR_InfectAddcond[client]);
			
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 30, SNDPLR_Infected[client], 300);
			
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 40, VISPLR_UserParticle[client], 300);
			VISPLR_UserTeamAdd[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 41, 0);
			VISPLR_UserHeightOffset[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 42, 70.0);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 43, VISPLR_UserOverlay[client], 300);
			
			
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 44, VISPLR_InfectParticle[client], 300);
			VISPLR_InfectTeamAdd[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 45, 0);
			VISPLR_InfectHeightOffset[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 46, 20.0);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 47, VISPLR_InfectOverlay[client], 300);
			
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 50, HUDPLR_PlaguedClue[client], 100);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 51, HUDPLR_InfectedClue[client], 100);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 59, HUDPLR_KillIcon[client], 100);
		}
		else if(StrEqual(ability_name, PLPName, false))
		{
			HasPlaguePassive[client] = true;
			
			FF2PLP_Flags[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 1, 5);
			FF2PLP_Style[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 2, 1);
			FF2PLP_StunFlags[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 3, 14);
			LiveReq_Build(boss, 4, PLPName, FF2PLP_LiveReq[client]);
			FF2PLP_CureMethod[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 5, 1);
			FF2PLP_MediRate[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 6, 1.0);
			
			FF2PLP_InfectDur[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 10, 20.0);
			FF2PLP_InfectSpreadMult[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 11, 0.5);
			FF2PLP_InfectDmg[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 12, 3.0);
			FF2PLP_DmgFix[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 13, 1);
			FF2PLP_InfectXBowHealMult[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 14, 1.0);
			AttribList_Build(boss, 15, PLPName, FF2PLR_InfectAttribs[client]);
			CondList_Build(boss, 16, PLPName, FF2PLP_InfectAddcond[client]);
			
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 30, SNDPLP_Infected[client], 300);
			
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 40, VISPLP_UserParticle[client], 300);
			VISPLP_UserTeamAdd[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 41, 0);
			VISPLP_UserHeightOffset[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 42, 70.0);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 43, VISPLP_UserOverlay[client], 300);
			
			
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 44, VISPLP_InfectParticle[client], 300);
			VISPLP_InfectTeamAdd[client] = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 45, 0);
			VISPLP_InfectHeightOffset[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 46, 20.0);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 47, VISPLP_InfectOverlay[client], 300);
			
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 50, HUDPLP_PlaguedClue[client], 100);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 51, HUDPLP_InfectedClue[client], 100);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 59, HUDPLP_KillIcon[client], 100);
		}
	}
}

ClearVariables(client)
{
	PlaguePassActive[client] = false;
	LastLiveNum[client] = -2;
	LastPlagueHit[client]=0.0;
	LastPlagueNoise[client]=-1.0;
	CureInfection(client);
	EndPlagueRage(client);
	KillPlagueParticle(client, 1);
	//////////PLRName//////////
	HasPlagueRage[client]=false;
	FF2PLR_AMS[client]=false;
	
	FF2PLR_Flags[client]=7;
	FF2PLR_Style[client]=1;
	FF2PLR_StunFlags[client]=14;
	FF2PLR_RageDur[client]=15.0;

	FF2PLR_InfectDur[client]=20.0;
	FF2PLR_InfectSpreadMult[client]=0.5;
	FF2PLR_InfectDmg[client]=3.0;
	FF2PLR_DmgFix[client]=1;
	FF2PLR_InfectXBowHealMult[client]=1.0;
	
	FF2PLR_CureMethod[client] = 7;
	FF2PLR_MediRate[client] = 1.0;
	

	Format(SNDPLR_Infected[client], 300, "");
	
	Format(VISPLR_UserParticle[client], 300, "");
	VISPLR_UserTeamAdd[client]=0;
	VISPLR_UserHeightOffset[client]=70.0;
	Format(VISPLR_UserOverlay[client], 300, "");
	
	Format(VISPLR_InfectParticle[client], 300, "");
	VISPLR_InfectTeamAdd[client]=1;
	VISPLR_InfectHeightOffset[client]=20.0;
	Format(VISPLR_InfectOverlay[client], 300, "");
	
	Format(HUDPLR_PlaguedClue[client], 100, "");
	Format(HUDPLR_InfectedClue[client], 100, "");
	Format(HUDPLR_KillIcon[client], 100, "");
	
	CondClear_Build(FF2PLR_InfectAddcond[client]);
	AttribClear_Build(FF2PLR_InfectAttribs[client]);
	//////////////////////////
	
	//////////PLPName//////////
	HasPlaguePassive[client]=false;
	
	FF2PLP_Flags[client]=7;
	FF2PLP_Style[client]=1;
	FF2PLP_StunFlags[client]=14;
	LiveReq_Clear(FF2PLP_LiveReq[client]);

	FF2PLP_InfectDur[client]=20.0;
	FF2PLP_InfectSpreadMult[client]=0.5;
	FF2PLP_InfectDmg[client]=3.0;
	FF2PLP_DmgFix[client]=1;
	FF2PLP_InfectXBowHealMult[client]=1.0;
	
	FF2PLP_CureMethod[client] = 7;
	FF2PLP_MediRate[client] = 1.0;
	

	Format(SNDPLP_Infected[client], 300, "");
	
	Format(VISPLP_UserParticle[client], 300, "");
	VISPLP_UserTeamAdd[client]=0;
	VISPLP_UserHeightOffset[client]=70.0;
	Format(VISPLP_UserOverlay[client], 300, "");
	
	Format(VISPLP_InfectParticle[client], 300, "");
	VISPLP_InfectTeamAdd[client]=1;
	VISPLP_InfectHeightOffset[client]=20.0;
	Format(VISPLP_InfectOverlay[client], 300, "");
	
	Format(HUDPLP_PlaguedClue[client], 100, "");
	Format(HUDPLP_InfectedClue[client], 100, "");
	Format(HUDPLP_KillIcon[client], 100, "");
	
	CondClear_Build(FF2PLP_InfectAddcond[client]);
	AttribClear_Build(FF2PLP_InfectAttribs[client]);
	//////////////////////////
	
}

DamageEntity(client, attacker = 0, Float:dmg, dmg_type = DMG_GENERIC)
{
	if(IsValidClient(client) || IsValidEntity(client))
	{
		new damage = RoundToNearest(dmg);
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(client,"targetname","targetsname_ff2_plague");
			DispatchKeyValue(pointHurt,"DamageTarget","targetsname_ff2_plague");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			DispatchKeyValue(pointHurt,"classname", "");
			DispatchSpawn(pointHurt);
			if(IsValidEntity(attacker))
			{
				new Float:AttackLocation[3];
				GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", AttackLocation);
				TeleportEntity(pointHurt, AttackLocation, NULL_VECTOR, NULL_VECTOR);
			}
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(client,"targetname","donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}

stock bool:IsBoss(client)
{
	if(IsValidClient(client))
	{
		if(FF2_GetBossIndex(client) >= 0)
		{
			return true;
		}
	}
	return false;
}

stock GetEntityHealth(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iHealth");
}

stock GetClientMaxHealth(client)
{
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}

HealClient(client, amount, health = -9999, bool:overheal = false, bool:broadcast)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		if(broadcast)
		{
			new Handle:healevent = CreateEvent("player_healonhit", true);
			SetEventInt(healevent, "entindex", client);
			SetEventInt(healevent, "amount", amount);
			FireEvent(healevent);
		}
		if(health == -9999)
		{
			health = GetEntityHealth(client);
		}
		new healthmax = GetClientMaxHealth(client);
		if(overheal)
		{
			SetEntityHealth(client, health+amount);
		}
		else
		{
			if(health<healthmax)
			{
				if(health+amount>healthmax)
				{
					SetEntityHealth(client, healthmax);
				}
				else
				{
					SetEntityHealth(client, health+amount);
				}
			}
		}
	}
}

stock bool:IsHidden(client)
{
	if(TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		if(GetEntProp(client, Prop_Send, "m_nDisguiseTeam")!=GetClientTeam(client))
		{
			return true;
		}
	}
	else if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
	{
		return true;
	}
	else if(TF2_IsPlayerInCondition(client, TFCond_Stealthed))
	{
		return true;
	}
	else if(TF2_IsPlayerInCondition(client, TFCond_Stealthed))
	{
		return true;
	}
	else if(TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade))
	{
		return true;
	}
	return false;
}

stock bool:PassiveActive(client)
{
	if(HasPlaguePassive[client])
	{
		if(PlagueRageDur[client]<GetGameTime())
		{
			if(PlaguePassActive[client])
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:CanInfect(client)
{
	if(HasPlagueRage[client])
	{
		return false;
	}
	else if(HasPlaguePassive[client])
	{
		return false;
	}
	else if(IsUbered(client))
	{
		return false;
	}
	else if(TF2_IsPlayerInCondition(client, TFCond_Bonked))
	{
		return false;
	}
	return true;
}

stock bool:IsUbered(client)
{
	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
	{
		return true;
	}
	else if(TF2_IsPlayerInCondition(client, TFCond_UberchargeFading))
	{
		return true;
	}
	else if(TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden))
	{
		return true;
	}
	else if(TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen))
	{
		return true;
	}
	else if(TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage))
	{
		return true;
	}
	return false;
}

stock bool:ClientHasStunFlags(client, flags)
{
	if(IsValidClient(client) && flags>0)
	{
		new stun = GetEntProp(client, Prop_Send, "m_iStunFlags");
		if(flags & 1)
		{
			if(stun & 1)
			{
				return true;
			}
		}
		if(flags & 8)
		{
			if(stun & 128)
			{
				return true;
			}
		}
		if(flags & 2)
		{
			if((stun & 64) && !(stun & 128))
			{
				return true;
			}
		}
		if(flags & 4)
		{
			if(stun & 2)
			{
				return true;
			}
		}
	}
	return false;
}

AttribList_Build(boss, arg, String:AbilityName[], Float:attriblist[15][2])
{
	new String:attrib[300];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, AbilityName, arg, attrib, 300);
	new String:attribs[15][15];
	new count = ExplodeString(attrib, " ; ", attribs, sizeof(attribs), sizeof(attribs));
	if (count > 0)
	{
		new Float:id;
		new Float:val;
		new slot = 0;
		for (new i = 0; i < count; i+=2)
		{
			id = StringToFloat(attribs[i]);
			val = StringToFloat(attribs[i+1]);
			if(id>0.0)
			{
				if(slot>14)
				{
					break;
				}
				attriblist[slot][0]=id;
				attriblist[slot][1]=val;
			}
			else
			{
				break;
			}
			slot+=1;
		}
	}
}

AttribClear_Build(Float:attriblist[15][2])
{
	for (new i = 0; i < 15; i++)
	{
		attriblist[i][0]=0.0;
		attriblist[i][1]=1.0;
	}
}

AttribApply_Infection(client, Float:attribs[15][2])
{
	new id;
	for (new i = 0; i < 15; i++)
	{
		id = RoundToNearest(attribs[i][0]);
		if(id>0)
		{
			TF2Attrib_SetByDefIndex(client, id, attribs[i][1]);
		}
		else
		{
			break;
		}
	}
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
}

AttribRemove_Infection(client, Float:attribs[15][2])
{
	new id;
	for (new i = 0; i < 15; i++)
	{
		id = RoundToNearest(attribs[i][0]);
		if(id>0)
		{
			TF2Attrib_RemoveByDefIndex(client, id);
		}
		else
		{
			break;
		}
	}
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
}

AttribClone_Infection(client, Float:attribs[15][2])
{
	for (new i = 0; i < 15; i++)
	{
		InfectionAttribs[client][i][0]=attribs[i][0];
		InfectionAttribs[client][i][1]=attribs[i][1];
	}
}

LiveReq_Build(boss, arg, String:AbilityName[], livelist[16])
{
	new String:live[300];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, AbilityName, arg, live, 300);
	if(strlen(live)>0)
	{
		new String:lives[8][8];
		new count = ExplodeString(live, " ; ", lives, sizeof(lives), sizeof(lives));
		if (count > 0)
		{
			new id;
			for (new i = 0; i < count; i++)
			{
				id = StringToInt(lives[i]);
				if(id>0)
				{
					livelist[i]=id;
				}
				id = StringToInt(lives[i+1]);
				if(id>0)
				{
					livelist[i+1]=id;
				}
			}
		}
	}
}

LiveReq_True(liveno, livelist[16])
{
	if(livelist[0]<1)
	{
		return true;
	}
	for(new i = 0; i < 16; i++)
	{
		if(liveno==livelist[i])
		{
			return true;
		}
	}
	return false;
}

LiveReq_Clear(livelist[16])
{
	for(new i = 0; i < 16; i++)
	{
		livelist[i]=0;
	}
}

CondList_Build(boss, arg, String:AbilityName[], condlist[32])
{
	new String:cond[300];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, AbilityName, arg, cond, 300);
	if(strlen(cond)>0)
	{
		new String:conds[32][32];
		new count = ExplodeString(cond, " ; ", conds, sizeof(conds), sizeof(conds));
		if (count > 0)
		{
			new id;
			for (new i = 0; i < count; i++)
			{
				id = StringToInt(conds[i]);
				if(id>-1)
				{
					if(i>31)
					{
						break;
					}
					condlist[i]=id;
				}
				else
				{
					break;
				}
			}
		}
	}
}

CondClear_Build(condlist[32])
{
	for (new i = 0; i < 32; i++)
	{
		condlist[i]=-1;
	}
}

CondApply_Infection(client, addconds[32])
{
	new plagueowner = client;
	if(InfectionOwner[client]!=-1)
	{
		plagueowner = GetClientOfUserId(InfectionOwner[client]);
		if(!IsValidClient(plagueowner))
		{
			plagueowner = client;
		}
	}
	for (new i = 0; i < 32; i++)
	{
		if(InfectionAddcond[client][i]>-1)
		{
			TF2_AddCondition(client, addconds[i], 0.1, plagueowner);
		}
		else
		{
			break;
		}
	}
}

CondClone_Infection(client, addconds[32])
{
	for (new i = 0; i < 32; i++)
	{
		InfectionAddcond[client][i]=addconds[i];
	}
}