#pragma semicolon true
#pragma semicolon true

// ----------------------------------------------------------------------------
//				   
//			FILE: Points.sp
//		MODIFIED: 01/08/2010
//		DESCRIPTION: 
//				  
// ----------------------------------------------------------------------------

#include <sourcemod>
#include <colors>

#include <sdktools>
#include <sdkhooks>


#define INFECTED(%1) I_%1
#define SURVIVOR(%1) S_%1

new Handle:INFECTED(Earns_Hurt)				   = INVALID_HANDLE;
new Handle:INFECTED(Earns_Hurt_Damage_Hunter)  = INVALID_HANDLE;
new Handle:INFECTED(Earns_Hurt_Damage_Boomer)  = INVALID_HANDLE;
new Handle:INFECTED(Earns_Hurt_Damage_Charger) = INVALID_HANDLE;
new Handle:INFECTED(Earns_Hurt_Damage_Jockey)  = INVALID_HANDLE;
new Handle:INFECTED(Earns_Hurt_Damage_Smoker)  = INVALID_HANDLE;
new Handle:INFECTED(Earns_Hurt_Damage_Spitter) = INVALID_HANDLE;
new Handle:INFECTED(Earns_Incapacitate)		   = INVALID_HANDLE;
new Handle:INFECTED(Earns_LedgeGrab)		   = INVALID_HANDLE;
new Handle:INFECTED(Earns_InstantKill)		   = INVALID_HANDLE;
new Handle:INFECTED(Earns_Pounce)			   = INVALID_HANDLE;
new Handle:INFECTED(Earns_Ride)				   = INVALID_HANDLE;
new Handle:INFECTED(Earns_TongueGrab)		   = INVALID_HANDLE;
new Handle:INFECTED(Earns_Vomit)			   = INVALID_HANDLE;
new Handle:INFECTED(Earns_ChargeImpact)		   = INVALID_HANDLE;
new Handle:INFECTED(Earns_ChargeCarry)		   = INVALID_HANDLE;
new Handle:INFECTED(Earns_BoomerAssist)		   = INVALID_HANDLE;
new Handle:INFECTED(Earns_BoomerAssist_Damage) = INVALID_HANDLE;
new Handle:INFECTED(Earns_TankHandHit)		   = INVALID_HANDLE;
new Handle:INFECTED(Earns_TankRockHit)		   = INVALID_HANDLE;
new Handle:INFECTED(Earns_Slap)				   = INVALID_HANDLE;
new Handle:INFECTED(Earns_SlapAnimation)	   = INVALID_HANDLE;
new Handle:INFECTED(Earns_SlapCooldown)		   = INVALID_HANDLE;
new Handle:INFECTED(Earns_SlapPower)		   = INVALID_HANDLE;
new Handle:INFECTED(Earns_SlapTime)			   = INVALID_HANDLE;
new Handle:INFECTED(Earns_Explosion_Power)	   = INVALID_HANDLE;
new Handle:INFECTED(Earns_Explosion_Radius)	   = INVALID_HANDLE;
new Handle:INFECTED(Earns_Explosion_Physics)   = INVALID_HANDLE;
new Handle:INFECTED(Earns_Tank_Roar)		   = INVALID_HANDLE;

new Handle:INFECTED(Earns_Charge_Power)		= INVALID_HANDLE;
new Handle:INFECTED(Earns_Charge_Radius)    = INVALID_HANDLE;
new Handle:INFECTED(Earns_Charge_Physics_X)	= INVALID_HANDLE;
new Handle:INFECTED(Earns_Charge_Physics_Y)	= INVALID_HANDLE;
new Handle:INFECTED(Earns_Charge_Physics_Z)	= INVALID_HANDLE;

new Handle:INFECTED(Earns_Hunter_Power)		= INVALID_HANDLE;
new Handle:INFECTED(Earns_Hunter_Radius)    = INVALID_HANDLE;
new Handle:INFECTED(Earns_Hunter_Physics_X)	= INVALID_HANDLE;
new Handle:INFECTED(Earns_Hunter_Physics_Y)	= INVALID_HANDLE;
new Handle:INFECTED(Earns_Hunter_Physics_Z)	= INVALID_HANDLE;

new Handle:SURVIVOR(Earns_KillCommons)		   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_KillCommons_Minimal) = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_KillBoomer)		   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_KillCharger)		   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_KillHunter)		   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_KillJockey)		   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_KillSmoker)		   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_KillSpitter)		   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_KillTank)		       = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_KillWitch)		   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_HurtTank)			   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_HurtTank_Damage)	   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_HurtWitch)		   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_HurtWitch_Damage)    = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_HealFriend)		   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_PickupFriend)		   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_PickupFriendLedge)   = INVALID_HANDLE;
new Handle:SURVIVOR(Earns_ReviveFriend)		   = INVALID_HANDLE;

new Handle:INFECTED(Price_Healing)			    = INVALID_HANDLE;
new Handle:INFECTED(Price_Suicide)			    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnBoomer)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnCharger)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnHunter)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnJockey)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnSmoker)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnSpitter)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnTank)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnWitch)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnWitchBride)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnSelfBoomer)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnSelfCharger)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnSelfHunter)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnSelfJockey)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnSelfSmoker)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnSelfSpitter)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnSelfTank)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnMob)			    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnMegaMob)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnCeda)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnClown)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnMud)			    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnWorker)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnRiot)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnJimmy)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnFa)		        = INVALID_HANDLE;
new Handle:INFECTED(Price_ResetAbility_Boom)    = INVALID_HANDLE;
new Handle:INFECTED(Price_ResetAbility_Char)    = INVALID_HANDLE;
new Handle:INFECTED(Price_ResetAbility_Hunt)    = INVALID_HANDLE;
new Handle:INFECTED(Price_ResetAbility_Jock)    = INVALID_HANDLE;
new Handle:INFECTED(Price_ResetAbility_Smok)    = INVALID_HANDLE;
new Handle:INFECTED(Price_ResetAbility_Spit)    = INVALID_HANDLE;
new Handle:INFECTED(Price_ResetAbility_Tank)    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnDumpster)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnCar)			    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnObjectTime)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpawnObjectDist)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_Extinguish)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_Random)			    = INVALID_HANDLE;
new Handle:INFECTED(Price_GiveBoomer)	        = INVALID_HANDLE;
new Handle:INFECTED(Price_GiveCharger)	        = INVALID_HANDLE;
new Handle:INFECTED(Price_GiveHunter)	        = INVALID_HANDLE;
new Handle:INFECTED(Price_GiveJockey)	        = INVALID_HANDLE;
new Handle:INFECTED(Price_GiveSmoker)	        = INVALID_HANDLE;
new Handle:INFECTED(Price_GiveSpitter)          = INVALID_HANDLE;
new Handle:INFECTED(Price_GiveTank)	            = INVALID_HANDLE;
new Handle:INFECTED(Price_God)				    = INVALID_HANDLE;
new Handle:INFECTED(Price_GodInterval)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_Speed)			    = INVALID_HANDLE;
new Handle:INFECTED(Price_SpeedInterval)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_Invisibility)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_InvisibilityInterval) = INVALID_HANDLE;
new Handle:INFECTED(Price_SpeedMultipler)	    = INVALID_HANDLE;

new Handle:INFECTED(Price_SquadBoomer)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SquadCharger)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SquadHunter)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SquadJockey)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SquadSmoker)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SquadSpitter)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SquadTank)		    = INVALID_HANDLE;
new Handle:INFECTED(Price_SquadBoomerOne)		= INVALID_HANDLE;
new Handle:INFECTED(Price_SquadChargerOne)		= INVALID_HANDLE;
new Handle:INFECTED(Price_SquadHunterOne)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SquadJockeyOne)	    = INVALID_HANDLE;
new Handle:INFECTED(Price_SquadSmokerOne)		= INVALID_HANDLE;
new Handle:INFECTED(Price_SquadSpitterOne)		= INVALID_HANDLE;
new Handle:INFECTED(Price_SquadTankOne)		    = INVALID_HANDLE;

new Handle:SURVIVOR(Price_SelfHealing)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupHealing)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupHealingValue)    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Adrenaline)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_PainPills)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_FirstAidkit)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Defibrillator)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_PipeBomb)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_BileBomb)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Molotov)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Pistol)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_MagnumPistol)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_ChromeShotgun)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_PumpShotgun)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_AutoShotgun)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_SpasShotgun)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Smg)				    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Silent_Smg)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_CombatRifle)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_DesertRifle)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Ak47Rifle)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_HuntingRifle)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_SniperRifle)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GrenadeLauncher)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_M60HeavyRifle)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Ammo)				    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_IncendiaryAmmo)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_ExplosiveAmmo)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_LaserSight)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_IncendiaryAmmoPack)   = INVALID_HANDLE;
new Handle:SURVIVOR(Price_ExplosiveAmmoPack)    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GolfClub)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_FireAxe)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Katana)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Crowbar)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_FryingPan)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Guitar)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_BaseballBat)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Machete)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Chainsaw)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Oxygentank)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Propanetank)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Gascan)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_FireworksCrate)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_AmmoPile)		    	= INVALID_HANDLE;
new Handle:SURVIVOR(Price_AmmoPileTime)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Random)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Suicide)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Barrel)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_God)				    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GodInterval)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Speed)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_SpeedInterval)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_SpeedMultipler)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Slow)				    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_SlowInterval)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_SlowMultipler)        = INVALID_HANDLE;
new Handle:SURVIVOR(Price_SelfRes)		        = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupRes)		        = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupResValue)        = INVALID_HANDLE;

new Handle:SURVIVOR(Price_GroupAdrenaline)		= INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupPainPills)		= INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupFirstAidkit)		= INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupDefibrillator)	= INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupPipeBomb)		= INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupBileBomb)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupMolotov)			= INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupAmmo)			= INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupIncendiaryAmmo)	= INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupExplosiveAmmo)	= INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupLaserSight)		= INVALID_HANDLE;

new Handle:SURVIVOR(Price_SelfHealing_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupHealing_Dead)		= INVALID_HANDLE;
new Handle:SURVIVOR(Price_Adrenaline_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_PainPills_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_FirstAidkit_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Defibrillator_Dead)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_PipeBomb_Dead)			= INVALID_HANDLE;
new Handle:SURVIVOR(Price_BileBomb_Dead)			= INVALID_HANDLE;
new Handle:SURVIVOR(Price_Molotov_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Pistol_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_MagnumPistol_Dead)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_ChromeShotgun_Dead)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_PumpShotgun_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_AutoShotgun_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_SpasShotgun_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Smg_Dead)				    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Silent_Smg_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_CombatRifle_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_DesertRifle_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Ak47Rifle_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_HuntingRifle_Dead)		= INVALID_HANDLE;
new Handle:SURVIVOR(Price_SniperRifle_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GrenadeLauncher_Dead)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_M60HeavyRifle_Dead)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Ammo_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_IncendiaryAmmo_Dead)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_ExplosiveAmmo_Dead)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_LaserSight_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_IncendiaryAmmoPack_Dead)  = INVALID_HANDLE;
new Handle:SURVIVOR(Price_ExplosiveAmmoPack_Dead)   = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GolfClub_Dead)			= INVALID_HANDLE;
new Handle:SURVIVOR(Price_FireAxe_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Katana_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Crowbar_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_FryingPan_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Guitar_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_BaseballBat_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Machete_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Chainsaw_Dead)			= INVALID_HANDLE;
new Handle:SURVIVOR(Price_Oxygentank_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Propanetank_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Gascan_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_FireworksCrate_Dead)	    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_AmmoPile_Dead)		    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Random_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Suicide_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Barrel_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_God_Dead)				    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Speed_Dead)			    = INVALID_HANDLE;
new Handle:SURVIVOR(Price_Slow_Dead)				= INVALID_HANDLE;
new Handle:SURVIVOR(Price_SelfRes_Dead)		        = INVALID_HANDLE;
new Handle:SURVIVOR(Price_GroupRes_Dead)		    = INVALID_HANDLE;

new Handle:INFECTED(Health_Boomer)			 = INVALID_HANDLE;
new Handle:INFECTED(Health_Charger)			 = INVALID_HANDLE;
new Handle:INFECTED(Health_Hunter)			 = INVALID_HANDLE;
new Handle:INFECTED(Health_Jockey)			 = INVALID_HANDLE;
new Handle:INFECTED(Health_Smoker)			 = INVALID_HANDLE;
new Handle:INFECTED(Health_Spitter)			 = INVALID_HANDLE;
new Handle:INFECTED(Health_Tank)			 = INVALID_HANDLE;

new Handle:INFECTED(Limit_TankTeamLimit)	  = INVALID_HANDLE;
new Handle:INFECTED(Limit_WitchTeamLimit)	  = INVALID_HANDLE;

new Handle:INFECTED(Limit_TankTimeLimit)	  = INVALID_HANDLE;
new Handle:INFECTED(Limit_WitchTimeLimit)	  = INVALID_HANDLE;

new Handle:hGlobal_Reset_AtRoundEnd			= INVALID_HANDLE;
new Handle:hGlobal_Reset_AtMapStart			= INVALID_HANDLE;
new Handle:hGlobal_Reset_AtTeamSwitch		= INVALID_HANDLE;

new Handle:hBerserk_Damage					 = INVALID_HANDLE;
new Handle:hBerserk_Enable					 = INVALID_HANDLE;

new Float:deathPosition[MAXPLAYERS + 1][3];

public InitializeConVars()
{
	INFECTED(Earns_Hurt)				= CreateConVar("sm_infected_earn_for_hurt",				   "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Hurt_Damage_Boomer)  = CreateConVar("sm_infected_earn_for_hurt_damage_boomer",	 "15.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Hurt_Damage_Charger) = CreateConVar("sm_infected_earn_for_hurt_damage_charger",	"18.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Hurt_Damage_Hunter)  = CreateConVar("sm_infected_earn_for_hurt_damage_hunter",	 "13.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Hurt_Damage_Jockey)  = CreateConVar("sm_infected_earn_for_hurt_damage_jockey",	 "13.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Hurt_Damage_Smoker)  = CreateConVar("sm_infected_earn_for_hurt_damage_smoker",	 "13.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Hurt_Damage_Spitter) = CreateConVar("sm_infected_earn_for_hurt_damage_spitter",	"25.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Incapacitate)		= CreateConVar("sm_infected_earn_for_incapacitate",		   "5.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_LedgeGrab)		   = CreateConVar("sm_infected_earn_for_ledge_grab",			 "3.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_InstantKill)		 = CreateConVar("sm_infected_earn_for_kill",				   "10.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Pounce)			  = CreateConVar("sm_infected_earn_for_hunter_pounce",		  "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Ride)				= CreateConVar("sm_infected_earn_for_jockey_ride",			"1.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_TongueGrab)		  = CreateConVar("sm_infected_earn_for_smoker_tongue_grab",	 "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Vomit)			   = CreateConVar("sm_infected_earn_for_boomer_vomit",		   "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_ChargeImpact)		= CreateConVar("sm_infected_earn_for_charger_charge_impacte", "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_ChargeCarry)		 = CreateConVar("sm_infected_earn_for_charger_charge_carry",   "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_BoomerAssist)		= CreateConVar("sm_infected_earn_for_boomer_assist",		  "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_BoomerAssist_Damage) = CreateConVar("sm_infected_earn_for_boomer_assist_damage",   "20.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_TankHandHit)		 = CreateConVar("sm_infected_earn_for_tank_hand_hit",		  "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_TankRockHit)		 = CreateConVar("sm_infected_earn_for_tank_rock_hit",		  "3.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Slap)				= CreateConVar("sm_infected_earn_for_boomer_slap",			"1.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_SlapAnimation)	   = CreateConVar("sm_infected_earn_for_boomer_slap_animation",  "96.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_SlapCooldown)		= CreateConVar("sm_infected_earn_for_boomer_slap_cooldown",   "10.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_SlapPower)		   = CreateConVar("sm_infected_earn_for_boomer_slap_power",	  "128.00", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_SlapTime)			= CreateConVar("sm_infected_earn_for_boomer_slap_time",	   "3.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Explosion_Power)	 = CreateConVar("sm_infected_earn_for_boomer_explosion_power", "150.00", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Explosion_Radius)	= CreateConVar("sm_infected_earn_for_boomer_explosion_radius","196.00", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Explosion_Physics)   = CreateConVar("sm_infected_earn_for_boomer_explosion_object","1.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Tank_Roar)		   = CreateConVar("sm_infected_earn_for_tank_roar",			  "1.0000", "", FCVAR_PLUGIN, true, -1.0);

	INFECTED(Earns_Charge_Power)		= CreateConVar("sm_infected_earn_for_boomer_charge_power",		  "150.00", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Charge_Radius)	   = CreateConVar("sm_infected_earn_for_boomer_charge_radius",		 "128.00", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Charge_Physics_X)	= CreateConVar("sm_infected_earn_for_boomer_charge_object_power_x", "442.00", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Charge_Physics_Z)	= CreateConVar("sm_infected_earn_for_boomer_charge_object_power_z", "442.00", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Charge_Physics_Y)	= CreateConVar("sm_infected_earn_for_boomer_charge_object_power_y", "224.00", "", FCVAR_PLUGIN, true, -1.0);

	INFECTED(Earns_Hunter_Power)		= CreateConVar("sm_infected_earn_for_hunter_pounce_damage",  "20.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Hunter_Radius)	   = CreateConVar("sm_infected_earn_for_hunter_pounce_raduis",  "256.00", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Hunter_Physics_X)	= CreateConVar("sm_infected_earn_for_hunter_pounce_power_x", "128.00", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Hunter_Physics_Z)	= CreateConVar("sm_infected_earn_for_hunter_pounce_power_z", "128.00", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Earns_Hunter_Physics_Y)	= CreateConVar("sm_infected_earn_for_hunter_pounce_power_y", "96.000", "", FCVAR_PLUGIN, true, -1.0);

	SURVIVOR(Earns_KillCommons)		 = CreateConVar("sm_survivor_earn_for_kill_commons",		   "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_KillCommons_Minimal) = CreateConVar("sm_survivor_earn_for_kill_commons_minimal",   "20.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_KillBoomer)		  = CreateConVar("sm_survivor_earn_for_kill_boomer",			"1.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_KillCharger)		 = CreateConVar("sm_survivor_earn_for_kill_charger",		   "2.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_KillHunter)		  = CreateConVar("sm_survivor_earn_for_kill_hunter",			"1.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_KillJockey)		  = CreateConVar("sm_survivor_earn_for_kill_jockey",			"1.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_KillSmoker)		  = CreateConVar("sm_survivor_earn_for_kill_smoker",			"2.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_KillSpitter)		 = CreateConVar("sm_survivor_earn_for_kill_spitter",		   "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_KillTank)			= CreateConVar("sm_survivor_earn_for_kill_tank",			  "2.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_KillWitch)		   = CreateConVar("sm_survivor_earn_for_kill_witch",			 "3.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_HurtTank)			= CreateConVar("sm_survivor_earn_for_hurt_tank",			  "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_HurtTank_Damage)	 = CreateConVar("sm_survivor_earn_for_hurt_tank_damage",	   "300.00", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_HurtWitch)		   = CreateConVar("sm_survivor_earn_for_hurt_witch",			 "1.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_HurtWitch_Damage)	= CreateConVar("sm_survivor_earn_for_hurt_witch_damage",	  "500.00", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_HealFriend)		  = CreateConVar("sm_survivor_earn_for_heal_friend",			"5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_PickupFriend)		= CreateConVar("sm_survivor_earn_for_pickup_friend",		  "5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_PickupFriendLedge)   = CreateConVar("sm_survivor_earn_for_pickup_friend_ledge",	"2.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Earns_ReviveFriend)		= CreateConVar("sm_survivor_earn_for_revive_friend",		  "5.0000", "", FCVAR_PLUGIN, true, -1.0);

	INFECTED(Price_Healing)			 = CreateConVar("sm_infected_cost_for_healing",				"10.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_Suicide)			 = CreateConVar("sm_infected_cost_for_suicide",				"2.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnBoomer)		 = CreateConVar("sm_infected_cost_for_spawn_boomer",		   "6.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnCharger)		= CreateConVar("sm_infected_cost_for_spawn_charger",		  "8.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnHunter)		 = CreateConVar("sm_infected_cost_for_spawn_hunter",		   "5.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnJockey)		 = CreateConVar("sm_infected_cost_for_spawn_jockey",		   "5.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnSmoker)		 = CreateConVar("sm_infected_cost_for_spawn_smoker",		   "8.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnSpitter)		= CreateConVar("sm_infected_cost_for_spawn_spitter",		  "8.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnTank)		   = CreateConVar("sm_infected_cost_for_spawn_tank",			 "40.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnWitch)		  = CreateConVar("sm_infected_cost_for_spawn_witch",			"25.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnWitchBride)		  = CreateConVar("sm_infected_cost_for_spawn_witch-bride",			"35.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnSelfBoomer)	 = CreateConVar("sm_infected_cost_for_spawn_boomer_self",	  "8.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnSelfCharger)	= CreateConVar("sm_infected_cost_for_spawn_charger_self",	 "10.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnSelfHunter)	 = CreateConVar("sm_infected_cost_for_spawn_hunter_self",	  "7.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnSelfJockey)	 = CreateConVar("sm_infected_cost_for_spawn_jockey_self",	  "7.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnSelfSmoker)	 = CreateConVar("sm_infected_cost_for_spawn_smoker_self",	  "10.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnSelfSpitter)	= CreateConVar("sm_infected_cost_for_spawn_spitter_self",	 "10.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnSelfTank)	   = CreateConVar("sm_infected_cost_for_spawn_tank_self",		"45.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnMob)			= CreateConVar("sm_infected_cost_for_spawn_mob",			  "10.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnMegaMob)		= CreateConVar("sm_infected_cost_for_spawn_mega_mob",		 "20.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnCeda)		   = CreateConVar("sm_infected_cost_for_spawn_ceda_horde",	   "20.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnClown)		  = CreateConVar("sm_infected_cost_for_spawn_clown_horde",	  "15.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnMud)			= CreateConVar("sm_infected_cost_for_spawn_mud_horde",		"20.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnWorker)		 = CreateConVar("sm_infected_cost_for_spawn_worker_horde",	 "20.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnRiot)		   = CreateConVar("sm_infected_cost_for_spawn_riot_horde",	   "25.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnJimmy)		  = CreateConVar("sm_infected_cost_for_spawn_jimmy_horde",	  "30.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnFa)		     = CreateConVar("sm_infected_cost_for_spawn_fallen_horde",	  "20.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_GiveBoomer)	 = CreateConVar("sm_infected_cost_for_spawn_boomer_give",	  "8.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_GiveCharger)	= CreateConVar("sm_infected_cost_for_spawn_charger_give",	 "9.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_GiveHunter)	 = CreateConVar("sm_infected_cost_for_spawn_hunter_give",	  "6.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_GiveJockey)	 = CreateConVar("sm_infected_cost_for_spawn_jockey_give",	  "6.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_GiveSmoker)	 = CreateConVar("sm_infected_cost_for_spawn_smoker_give",	  "9.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_GiveSpitter)	= CreateConVar("sm_infected_cost_for_spawn_spitter_give",	 "9.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_GiveTank)	   = CreateConVar("sm_infected_cost_for_spawn_tank_give",		"43.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_ResetAbility_Boom)   = CreateConVar("sm_infected_cost_for_reload_ability_boomer",  "4.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_ResetAbility_Char)   = CreateConVar("sm_infected_cost_for_reload_ability_charger", "4.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_ResetAbility_Hunt)   = CreateConVar("sm_infected_cost_for_reload_ability_hunter",  "2.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_ResetAbility_Jock)   = CreateConVar("sm_infected_cost_for_reload_ability_jokcey",  "2.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_ResetAbility_Smok)   = CreateConVar("sm_infected_cost_for_reload_ability_smoker",  "4.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_ResetAbility_Spit)   = CreateConVar("sm_infected_cost_for_reload_ability_spitter", "6.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_ResetAbility_Tank)   = CreateConVar("sm_infected_cost_for_reload_ability_tank",	"2.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnDumpster)	   = CreateConVar("sm_infected_cost_for_spawn_dumpster",		 "15.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnCar)			= CreateConVar("sm_infected_cost_for_spawn_car",			  "20.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnObjectTime)	 = CreateConVar("sm_infected_cost_for_spawn_disappear_time",   "45.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpawnObjectDist)	 = CreateConVar("sm_infected_cost_for_spawn_minimal_distance", "450.00", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_Extinguish)		  = CreateConVar("sm_infected_cost_for_extinguish",			 "5.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_Random)			  = CreateConVar("sm_infected_cost_for_random",				 "8.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_God)				 = CreateConVar("sm_infected_cost_for_god",					"10.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_GodInterval)		 = CreateConVar("sm_infected_cost_for_god_interval",		   "10.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_Speed)			   = CreateConVar("sm_infected_cost_for_speed",				  "10.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpeedInterval)	   = CreateConVar("sm_infected_cost_for_speed_interval",		 "15.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SpeedMultipler)	  = CreateConVar("sm_infected_cost_for_speed_multipler",		"3.0000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_Invisibility)		= CreateConVar("sm_infected_cost_for_invisibility",		   "15.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_InvisibilityInterval)= CreateConVar("sm_infected_cost_for_invisibility_interval",  "15.000", "", FCVAR_PLUGIN, true, -1.0);
	
	INFECTED(Price_SquadBoomer)		    = CreateConVar("sm_infected_cost_for_squad_boomer",		   "-2.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadCharger)		= CreateConVar("sm_infected_cost_for_squad_charger",		   "-2.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadHunter)		    = CreateConVar("sm_infected_cost_for_squad_hunter",		   "-2.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadJockey)		    = CreateConVar("sm_infected_cost_for_squad_jockey",		   "-2.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadSmoker)		    = CreateConVar("sm_infected_cost_for_squad_smoker",		   "-2.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadSpitter)		= CreateConVar("sm_infected_cost_for_squad_spitter",		   "-2.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadTank)		    = CreateConVar("sm_infected_cost_for_squad_tank",		   "-2.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadBoomerOne)		= CreateConVar("sm_infected_cost_for_squad_boomer_one",		   "5.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadChargerOne)		= CreateConVar("sm_infected_cost_for_squad_charger_one",		   "6.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadHunterOne)	    = CreateConVar("sm_infected_cost_for_squad_hunter_one",		   "3.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadJockeyOne)	    = CreateConVar("sm_infected_cost_for_squad_jockey_one",		   "3.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadSmokerOne)		= CreateConVar("sm_infected_cost_for_squad_smoker_one",		   "6.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadSpitterOne)		= CreateConVar("sm_infected_cost_for_squad_spitter_one",		   "6.000", "", FCVAR_PLUGIN, true, -1.0);
	INFECTED(Price_SquadTankOne)		= CreateConVar("sm_infected_cost_for_squad_tank_one",		   "30.000", "", FCVAR_PLUGIN, true, -1.0);

	SURVIVOR(Price_SelfHealing)		 = CreateConVar("sm_survivor_cost_for_healing",				"10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupHealing)		= CreateConVar("sm_survivor_cost_for_healing_group",		  "-2.000", "", FCVAR_PLUGIN, true, -2.0);
	SURVIVOR(Price_GroupHealingValue)   = CreateConVar("sm_survivor_cost_for_healing_group_per_one",  "5.0000", "", FCVAR_PLUGIN, true,  0.0);
	SURVIVOR(Price_Adrenaline)		  = CreateConVar("sm_survivor_cost_for_adrenaline",			 "6.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_PainPills)		   = CreateConVar("sm_survivor_cost_for_pain_pills",			 "5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_FirstAidkit)		 = CreateConVar("sm_survivor_cost_for_first_aid_kit",		  "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Defibrillator)	   = CreateConVar("sm_survivor_cost_for_defibrillator",		  "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_PipeBomb)			= CreateConVar("sm_survivor_cost_for_pipe_bomb",			  "3.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_BileBomb)			= CreateConVar("sm_survivor_cost_for_bile_bomb",			  "4.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Molotov)			 = CreateConVar("sm_survivor_cost_for_molotov",				"5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Pistol)			  = CreateConVar("sm_survivor_cost_for_pistol",				 "2.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_MagnumPistol)		= CreateConVar("sm_survivor_cost_for_magnum_pistol",		  "7.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_ChromeShotgun)	   = CreateConVar("sm_survivor_cost_for_chrome_shotgun",		 "5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_PumpShotgun)		 = CreateConVar("sm_survivor_cost_for_pump_shotgun",		   "5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_AutoShotgun)		 = CreateConVar("sm_survivor_cost_for_auto_shotgun",		   "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_SpasShotgun)		 = CreateConVar("sm_survivor_cost_for_spas_shotgun",		   "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Smg)				 = CreateConVar("sm_survivor_cost_for_smg",					"5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Silent_Smg)		  = CreateConVar("sm_survivor_cost_for_smg_silent",			 "5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_CombatRifle)		 = CreateConVar("sm_survivor_cost_for_combat_rifle",		   "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_DesertRifle)		 = CreateConVar("sm_survivor_cost_for_desert_rifle",		   "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Ak47Rifle)		   = CreateConVar("sm_survivor_cost_for_ak47_rifle",			 "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_HuntingRifle)		= CreateConVar("sm_survivor_cost_for_hunting_rifle",		  "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_SniperRifle)		 = CreateConVar("sm_survivor_cost_for_sniper_rifle",		   "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GrenadeLauncher)	 = CreateConVar("sm_survivor_cost_for_grenade_launcher",	   "20.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_M60HeavyRifle)	   = CreateConVar("sm_survivor_cost_for_m60_heavy_rifle",		"20.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Ammo)				= CreateConVar("sm_survivor_cost_for_ammo",				   "4.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_IncendiaryAmmo)	  = CreateConVar("sm_survivor_cost_for_incendiary_ammo",		"7.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_ExplosiveAmmo)	   = CreateConVar("sm_survivor_cost_for_explosive_ammo",		 "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_LaserSight)		  = CreateConVar("sm_survivor_cost_for_laser_sight",			"3.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_IncendiaryAmmoPack)  = CreateConVar("sm_survivor_cost_for_incendiary_ammo_pack",   "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_ExplosiveAmmoPack)   = CreateConVar("sm_survivor_cost_for_explosive_ammo_pack",	"15.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GolfClub)			= CreateConVar("sm_survivor_cost_for_golfclub",			   "4.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_FireAxe)			 = CreateConVar("sm_survivor_cost_for_fireaxe",				"5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Katana)			  = CreateConVar("sm_survivor_cost_for_katana",				 "5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Crowbar)			 = CreateConVar("sm_survivor_cost_for_crowbar",				"3.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_FryingPan)		   = CreateConVar("sm_survivor_cost_for_frying_pan",			 "4.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Guitar)			  = CreateConVar("sm_survivor_cost_for_guitar",				 "4.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_BaseballBat)		 = CreateConVar("sm_survivor_cost_for_baseball_bat",		   "3.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Machete)			 = CreateConVar("sm_survivor_cost_for_bachete",				"5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Chainsaw)			= CreateConVar("sm_survivor_cost_for_chainsaw",			   "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Oxygentank)		  = CreateConVar("sm_survivor_cost_for_ixygentank",			 "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Propanetank)		 = CreateConVar("sm_survivor_cost_for_propanetank",			"10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Gascan)			  = CreateConVar("sm_survivor_cost_for_gascan",				 "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_FireworksCrate)	  = CreateConVar("sm_survivor_cost_for_fireworks_crate",		"10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_AmmoPile)			= CreateConVar("sm_survivor_cost_for_ammo_pile",			  "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_AmmoPileTime)		= CreateConVar("sm_survivor_cost_for_ammo_pile_disappear",	"60.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Random)			  = CreateConVar("sm_survivor_cost_for_random",				 "6.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Suicide)			 = CreateConVar("sm_survivor_cost_for_suicide",				"5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_God)				 = CreateConVar("sm_survivor_cost_for_god",					"10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GodInterval)		 = CreateConVar("sm_survivor_cost_for_god_interval",		   "15.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Speed)			   = CreateConVar("sm_survivor_cost_for_speed",				  "8.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_SpeedInterval)	   = CreateConVar("sm_survivor_cost_for_speed_interval",		 "15.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_SpeedMultipler)	  = CreateConVar("sm_survivor_cost_for_speed_multipler",		"3.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Slow)				= CreateConVar("sm_survivor_cost_for_slow_motion",			"15.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_SlowInterval)		= CreateConVar("sm_survivor_cost_for_slow_motion_interval",   "10.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_SlowMultipler)	   = CreateConVar("sm_survivor_cost_for_slow_motion_multipler",  "0.5000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Barrel) = CreateConVar("sm_survivor_cost_for_fire_barrel",  "5.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_SelfRes)		 = CreateConVar("sm_survivor_cost_for_res",				"15.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupRes)		= CreateConVar("sm_survivor_cost_for_res_group",		  "-2.000", "", FCVAR_PLUGIN, true, -2.0);
	SURVIVOR(Price_GroupResValue)   = CreateConVar("sm_survivor_cost_for_res_group_per_one",  "10.0000", "", FCVAR_PLUGIN, true,  0.0);
	
	SURVIVOR(Price_GroupAdrenaline)		  = CreateConVar("sm_survivor_cost_for_adrenaline_group_one",			 "5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupPainPills)		   = CreateConVar("sm_survivor_cost_for_pain_pills_group_one",			 "4.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupFirstAidkit)		 = CreateConVar("sm_survivor_cost_for_first_aid_kit_group_one",		  "9.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupDefibrillator)	   = CreateConVar("sm_survivor_cost_for_defibrillator_group_one",		  "9.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupPipeBomb)			= CreateConVar("sm_survivor_cost_for_pipe_bomb_group_one",			  "2.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupBileBomb)			= CreateConVar("sm_survivor_cost_for_bile_bomb_group_one",			  "3.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupMolotov)			 = CreateConVar("sm_survivor_cost_for_molotov_group_one",				"4.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupAmmo)				= CreateConVar("sm_survivor_cost_for_ammo_group_one",				   "2.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupIncendiaryAmmo)	  = CreateConVar("sm_survivor_cost_for_incendiary_ammo_group_one",		"5.0000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupExplosiveAmmo)	   = CreateConVar("sm_survivor_cost_for_explosive_ammo_group_one",		 "8.000", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupLaserSight)		  = CreateConVar("sm_survivor_cost_for_laser_sight_group_one",			"2.0000", "", FCVAR_PLUGIN, true, -1.0);
	
	SURVIVOR(Price_SelfHealing_Dead)		 = CreateConVar("sm_survivor_cost_for_healing_dead", 			"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupHealing_Dead)		= CreateConVar("sm_survivor_cost_for_healing_group_dead", 	  "1.0", "", FCVAR_PLUGIN, true, -2.0);
	SURVIVOR(Price_Adrenaline_Dead)		  = CreateConVar("sm_survivor_cost_for_adrenaline_dead", 		 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_PainPills_Dead)		   = CreateConVar("sm_survivor_cost_for_pain_pills_dead", 		 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_FirstAidkit_Dead)		 = CreateConVar("sm_survivor_cost_for_first_aid_kit_dead", 	  "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Defibrillator_Dead)	   = CreateConVar("sm_survivor_cost_for_defibrillator_dead", 	  "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_PipeBomb_Dead)			= CreateConVar("sm_survivor_cost_for_pipe_bomb_dead", 		  "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_BileBomb_Dead)			= CreateConVar("sm_survivor_cost_for_bile_bomb_dead", 		  "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Molotov_Dead)			 = CreateConVar("sm_survivor_cost_for_molotov_dead", 			"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Pistol_Dead)			  = CreateConVar("sm_survivor_cost_for_pistol_dead", 			 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_MagnumPistol_Dead)		= CreateConVar("sm_survivor_cost_for_magnum_pistol_dead", 	  "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_ChromeShotgun_Dead)	   = CreateConVar("sm_survivor_cost_for_chrome_shotgun_dead", 	 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_PumpShotgun_Dead)		 = CreateConVar("sm_survivor_cost_for_pump_shotgun_dead", 	   "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_AutoShotgun_Dead)		 = CreateConVar("sm_survivor_cost_for_auto_shotgun_dead", 	   "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_SpasShotgun_Dead)		 = CreateConVar("sm_survivor_cost_for_spas_shotgun_dead", 	   "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Smg_Dead)				 = CreateConVar("sm_survivor_cost_for_smg_dead", 				"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Silent_Smg_Dead)		  = CreateConVar("sm_survivor_cost_for_smg_silent_dead", 		 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_CombatRifle_Dead)		 = CreateConVar("sm_survivor_cost_for_combat_rifle_dead", 	   "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_DesertRifle_Dead)		 = CreateConVar("sm_survivor_cost_for_desert_rifle_dead", 	   "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Ak47Rifle_Dead)		   = CreateConVar("sm_survivor_cost_for_ak47_rifle_dead", 		 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_HuntingRifle_Dead)		= CreateConVar("sm_survivor_cost_for_hunting_rifle_dead", 	  "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_SniperRifle_Dead)		 = CreateConVar("sm_survivor_cost_for_sniper_rifle_dead", 	   "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GrenadeLauncher_Dead)	 = CreateConVar("sm_survivor_cost_for_grenade_launcher_dead",    "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_M60HeavyRifle_Dead)	   = CreateConVar("sm_survivor_cost_for_m60_heavy_rifle_dead", 	"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Ammo_Dead)				= CreateConVar("sm_survivor_cost_for_ammo_dead", 			   "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_IncendiaryAmmo_Dead)	  = CreateConVar("sm_survivor_cost_for_incendiary_ammo_dead", 	"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_ExplosiveAmmo_Dead)	   = CreateConVar("sm_survivor_cost_for_explosive_ammo_dead", 	 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_LaserSight_Dead)		  = CreateConVar("sm_survivor_cost_for_laser_sight_dead", 		"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_IncendiaryAmmoPack_Dead)  = CreateConVar("sm_survivor_cost_for_incendiary_ammo_pack_dead",   "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_ExplosiveAmmoPack_Dead)   = CreateConVar("sm_survivor_cost_for_explosive_ammo_pack_dead", "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GolfClub_Dead)			= CreateConVar("sm_survivor_cost_for_golfclub_dead", 		   "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_FireAxe_Dead)			 = CreateConVar("sm_survivor_cost_for_fireaxe_dead", 			"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Katana_Dead)			  = CreateConVar("sm_survivor_cost_for_katana_dead", 			 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Crowbar_Dead)			 = CreateConVar("sm_survivor_cost_for_crowbar_dead", 			"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_FryingPan_Dead)		   = CreateConVar("sm_survivor_cost_for_frying_pan_dead", 		 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Guitar_Dead)			  = CreateConVar("sm_survivor_cost_for_guitar_dead", 			 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_BaseballBat_Dead)		 = CreateConVar("sm_survivor_cost_for_baseball_bat_dead", 	   "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Machete_Dead)			 = CreateConVar("sm_survivor_cost_for_bachete_dead", 			"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Chainsaw_Dead)			= CreateConVar("sm_survivor_cost_for_chainsaw_dead", 		   "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Oxygentank_Dead)		  = CreateConVar("sm_survivor_cost_for_ixygentank_dead", 		 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Propanetank_Dead)		 = CreateConVar("sm_survivor_cost_for_propanetank_dead", 		"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Gascan_Dead)			  = CreateConVar("sm_survivor_cost_for_gascan_dead", 			 "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_FireworksCrate_Dead)	  = CreateConVar("sm_survivor_cost_for_fireworks_crate_dead", 	"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_AmmoPile_Dead)			= CreateConVar("sm_survivor_cost_for_ammo_pile_dead", 		  "1.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Random_Dead)			  = CreateConVar("sm_survivor_cost_for_random_dead", 			 "1.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Suicide_Dead)			 = CreateConVar("sm_survivor_cost_for_suicide_dead", 			"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_God_Dead)				 = CreateConVar("sm_survivor_cost_for_god_dead", 				"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Speed_Dead)			   = CreateConVar("sm_survivor_cost_for_speed_dead", 			  "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Slow_Dead)				= CreateConVar("sm_survivor_cost_for_slow_motion_dead", 		"0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_Barrel_Dead) = CreateConVar("sm_survivor_cost_for_fire_barrel_dead",  "0.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_SelfRes_Dead)		 = CreateConVar("sm_survivor_cost_for_res_dead", 			"1.0", "", FCVAR_PLUGIN, true, -1.0);
	SURVIVOR(Price_GroupRes_Dead)		= CreateConVar("sm_survivor_cost_for_res_group_dead", 	  "1.0", "", FCVAR_PLUGIN, true, -2.0);

	INFECTED(Health_Boomer)			 = CreateConVar("sm_infected_health_boomer",				   "50.000", "", FCVAR_PLUGIN, true, 1.0);
	INFECTED(Health_Charger)			= CreateConVar("sm_infected_health_charger",				  "600.00", "", FCVAR_PLUGIN, true, 1.0);
	INFECTED(Health_Hunter)			 = CreateConVar("sm_infected_health_hunter",				   "250.00", "", FCVAR_PLUGIN, true, 1.0);
	INFECTED(Health_Jockey)			 = CreateConVar("sm_infected_health_jockey",				   "325.00", "", FCVAR_PLUGIN, true, 1.0);
	INFECTED(Health_Smoker)			 = CreateConVar("sm_infected_health_smoker",				   "250.00", "", FCVAR_PLUGIN, true, 1.0);
	INFECTED(Health_Spitter)			= CreateConVar("sm_infected_health_spitter",				  "300.00", "", FCVAR_PLUGIN, true, 1.0);
	INFECTED(Health_Tank)			   = CreateConVar("sm_infected_health_tank",					 "6000.0", "", FCVAR_PLUGIN, true, 1.0);

	INFECTED(Limit_TankTeamLimit)	   = CreateConVar("sm_infected_limit_tank_per_team",			 "5.0000", "", FCVAR_PLUGIN, true, 1.0);
	INFECTED(Limit_WitchTeamLimit)	  = CreateConVar("sm_infected_limit_witch_per_team",			"10.000", "", FCVAR_PLUGIN, true, 1.0);

	INFECTED(Limit_TankTimeLimit)	   = CreateConVar("sm_infected_limit_tank_once",				 "2.0000", "", FCVAR_PLUGIN, true, 1.0);
	INFECTED(Limit_WitchTimeLimit)	  = CreateConVar("sm_infected_limit_witch_once",				"3.0000", "", FCVAR_PLUGIN, true, 1.0);

	
	hGlobal_Reset_AtRoundEnd			= CreateConVar("sm_reset_points_at_round_end",				"1.0000", "", FCVAR_PLUGIN, true, 0.0);
	hGlobal_Reset_AtMapStart			= CreateConVar("sm_reset_points_at_map_start",				"1.0000", "", FCVAR_PLUGIN, true, 0.0);
	hGlobal_Reset_AtTeamSwitch		  = CreateConVar("sm_reset_points_at_team_switch",			  "1.0000", "", FCVAR_PLUGIN, true, 0.0);
}
enum EPlayer
{
Float:Armour,
	  Points,
	  LastItem,
	  LastTeam,
	  Ticket, 

	  CommonKills,
	  AssistOwner,

	  AssistDamage,

	  SurvivorDamage_Boomer,
	  SurvivorDamage_Charger,
	  SurvivorDamage_Hunter,
	  SurvivorDamage_Jockey,
	  SurvivorDamage_Smoker,
	  SurvivorDamage_Spitter,

	  TankDamage,
	  WitchDamage,

	  CanSlap,
	  GotSlap,

	  Carryied,
	  CarryOwner,
	  HasHintOn,
MoveType:MyMoveType,
		 LevelPoints,
		 Block,
		 HunterPonuce,
		 Berserk,
		 GodMode,
		 Speed,
		 Inv,
Float:DefaultSpeed,
	DeadBody
};

new isSlow = 0;
new entSlow = -1;

#define SDKCALL(%1) H_%1

new TankCount		 = 0;
new WitchCount		= 0;

new TankTeamCount	 = 0;
new WitchTeamCount	= 0;

new bool:HasPrecachedUncommons = false;
new RemainingZombies		   = 0;
new ZombieType				   = 0;

new Players[MAXPLAYERS+1][EPlayer];

new String:InfectedItemHelp[][] =
{
	"{olive}[SM]{default} The {olive}Healing{default} heals you.",
	"{olive}[SM]{default} The {olive}Suicide{default} kills you.",

	"{olive}[SM]{default} The {olive}Become Boomer{default} spawns a boomer for you. If you alive it's price will be higher of the {olive}Suicide{default} item price.",
	"{olive}[SM]{default} The {olive}Spawn Charger{default} spawns a charger for you. If you alive it's price will be higher of the {olive}Suicide{default} item price.",
	"{olive}[SM]{default} The {olive}Spawn Hunter{default} spawns a hunter for you. If you alive it's price will be higher of the {olive}Suicide{default} item price.",
	"{olive}[SM]{default} The {olive}Spawn Jockey{default} spawns a jockey for you. If you alive it's price will be higher of the {olive}Suicide{default} item price.",
	"{olive}[SM]{default} The {olive}Spawn Smoker{default} spawns a smoker for you. If you alive it's price will be higher of the {olive}Suicide{default} item price.",
	"{olive}[SM]{default} The {olive}Spawn Spitter{default} spawns a spitter for you. If you alive it's price will be higher of the {olive}Suicide{default} item price.",
	"{olive}[SM]{default} The {olive}Spawn Tank{default} spawns a tank for you. If you alive it's price will be higher of the {olive}Suicide{default} item price.",

	"{olive}[SM]{default} The {olive}Spawn Boomer{default} spawns a boomer for the next not alive player in the spawn list which is available by using the {olive}!teams{default} command.",
	"{olive}[SM]{default} The {olive}Spawn Charger{default} spawns a charger for the next not alive player in the spawn list which is available by using the {olive}!teams{default} command.",
	"{olive}[SM]{default} The {olive}Spawn Hunter{default} spawns a hunter for the next not alive player in the spawn list which is available by using the {olive}!teams{default} command.",
	"{olive}[SM]{default} The {olive}Spawn Jockey{default} spawns a jockey for the next not alive player in the spawn list which is available by using the {olive}!teams{default} command.",
	"{olive}[SM]{default} The {olive}Spawn Smoker{default} spawns a smoker for the next not alive player in the spawn list which is available by using the {olive}!teams{default} command.",
	"{olive}[SM]{default} The {olive}Spawn Spitter{default} spawns a spitter for the next not alive player in the spawn list which is available by using the {olive}!teams{default} command.",
	"{olive}[SM]{default} The {olive}Spawn Tank{default} spawns a tank for the next not alive player in the spawn list which is available by using the {olive}!teams{default} command.",
	"{olive}[SM]{default} The {olive}Spawn Witch{default} spawns a witch in place you are currently looking at. It may fail if you try to spawn her too close to survivors",

	"{olive}[SM]{default} The {olive}Spawn Mob{default} spawns a small common infected horde.",
	"{olive}[SM]{default} The {olive}Spawn Mega Mob{default} spawns a large common infected horde.",

	"{olive}[SM]{default} The {olive}Spawn Ceda Horde{default} spawns a medium Ceda infected horde.",
	"{olive}[SM]{default} The {olive}Spawn Clown Horde{default} spawns a medium Clown infected horde.",
	"{olive}[SM]{default} The {olive}Spawn Mud Horde{default} spawns a medium Mud infected horde.",
	"{olive}[SM]{default} The {olive}Spawn Worker Horde{default} spawns a medium Worker infected horde.",
	"{olive}[SM]{default} The {olive}Spawn Riot Horde{default} spawns a medium Riot infected horde.",
	"{olive}[SM]{default} The {olive}Spawn Jimmy Horde{default} spawns a medium Jimmy infected horde.",

	"{olive}[SM]{default} The {olive}Reload Ability{default} reloads your current ability (spit, vomit, charge, etc). It's price may be different for specified type of infected.",
	"{olive}[SM]{default} The {olive}Spawn Dumpster{default} spawns a dumpster in place you are currently looking at. It may fail if you try to spawn it too close to survivors,",
	"{olive}[SM]{default} The {olive}Spawn Car{default} spawns a car in place you are currently looking at. It may fail if you try to spawn it too close to survivors,",
	"{olive}[SM]{default} The {olive}Extinguish{default} will stop any fire that is burning you.",
	"{olive}[SM]{default} The {olive}God Mode{default} will make you immortal for a while. It may fail if you try to buy it again when you already have one enabled.",
	"{olive}[SM]{default} The {olive}Super-Speed{default} will make you faster for a while. It may fail if you try to buy it again when you already have one enabled.",
	"{olive}[SM]{default} The {olive}Invisibility{default} will make you invisible for a while. It may fail if you try to buy it again when you already have one enabled.",

	"{olive}[SM]{default} The {olive}Spawn Boomer{default} spawns a boomer for a not alive player you pick.",
	"{olive}[SM]{default} The {olive}Spawn Charger{default} spawns a charger for a not alive player you pick.",
	"{olive}[SM]{default} The {olive}Spawn Hunter{default} spawns a hunter for a not alive player you pick.",
	"{olive}[SM]{default} The {olive}Spawn Jockey{default} spawns a jockey for a not alive player you pick.",
	"{olive}[SM]{default} The {olive}Spawn Smoker{default} spawns a smoker for a not alive player you pick.",
	"{olive}[SM]{default} The {olive}Spawn Spitter{default} spawns a spitter for a not alive player you pick.",
	"{olive}[SM]{default} The {olive}Spawn Tank{default} spawns a tank for a not alive player you pick.",

	"{olive}[SM]{default} The {olive}Spawn Boomer Squad{default} spawns a boomer squad.",
	"{olive}[SM]{default} The {olive}Spawn Charger Squad{default} spawns a charger squad.",
	"{olive}[SM]{default} The {olive}Spawn Hunter Squad{default} spawns a hunter squad.",
	"{olive}[SM]{default} The {olive}Spawn Jockey Squad{default} spawns a jockey squad.",
	"{olive}[SM]{default} The {olive}Spawn Smoker Squad{default} spawns a smoker squad.",
	"{olive}[SM]{default} The {olive}Spawn Spitter Squad{default} spawns a spitter squad.",
	"{olive}[SM]{default} The {olive}Spawn Tank Squad{default} spawns a tank squad.",
	
	"{olive}[SM]{default} The {olive}Spawn Fallen Horde{default} spawns a medium Fallen infected horde.",
	
	"{olive}[SM]{default} The {olive}Spawn Witch Bride{default} spawns a powerful witch bride (10000 hp) in place you are currently looking at. It may fail if you try to spawn her too close to survivors"
};

new String:SurvivorItemHelp[][] =
{
	"{olive}[SM]{default} The {olive}Healing{default} heals you.",
	"{olive}[SM]{default} The {olive}Group Healing{default} heals whole team. The price of this item is calculated by {olive}(alive survivors) * (price per survivor){default}.",
	"{olive}[SM]{default} The {olive}Ammo{default} refills your ammo.",
	"{olive}[SM]{default} The {olive}Laser Sight{default} gives you a laser sight.",
	"{olive}[SM]{default} The {olive}Incendiary Ammo{default} gives you an incendiary ammo.",
	"{olive}[SM]{default} The {olive}Explosive Ammo{default} gives you an explosive ammo.",
	"{olive}[SM]{default} The {olive}Adrenaline{default} gives you an adrenaline.",
	"{olive}[SM]{default} The {olive}Pain Pills{default} gives you a pain pills.",
	"{olive}[SM]{default} The {olive}First Aid Kit{default} gives you a first aid kit.",
	"{olive}[SM]{default} The {olive}Defibrillator{default} gives you a defibrillator.",
	"{olive}[SM]{default} The {olive}Bile Bomb{default} gives you a bile bomb.",
	"{olive}[SM]{default} The {olive}Pipe Bomb{default} gives you a pipe bomb.",
	"{olive}[SM]{default} The {olive}Molotov{default} gives you a molotov.",

	"{olive}[SM]{default} The {olive}Pistol{default} gives you a pistol.",
	"{olive}[SM]{default} The {olive}Magnum{default} gives you a magnum.",
	"{olive}[SM]{default} The {olive}Chrome Shotgun{default} gives you a chrome shotgun.",
	"{olive}[SM]{default} The {olive}Pump Shotgun{default} gives you a pump shotgun.",
	"{olive}[SM]{default} The {olive}Auto Shotgun{default} gives you an auto shotgun.",
	"{olive}[SM]{default} The {olive}Spas Shotgun{default} gives you a spas shotgun.",
	"{olive}[SM]{default} The {olive}SMG{default} gives you a smg.",
	"{olive}[SM]{default} The {olive}Silent SMG{default} gives you a silent smg.",
	"{olive}[SM]{default} The {olive}Combat Rifle{default} gives you a combat rifle.",
	"{olive}[SM]{default} The {olive}Ak47 Rifle{default} gives you an ak47 rifle.",
	"{olive}[SM]{default} The {olive}Desert Rifle{default} gives you a desert rifle.",
	"{olive}[SM]{default} The {olive}Hunting Rifle{default} gives you a hunting rifle.",
	"{olive}[SM]{default} The {olive}Sniper Rifle{default} gives you a sniper rifle.",
	"{olive}[SM]{default} The {olive}Grenade Launcher{default} gives you a grenade launcher.",
	"{olive}[SM]{default} The {olive}M60 Heavy Rifle{default} gives you a m60 heavy rifle.",

	"{olive}[SM]{default} The {olive}Glof Club{default} gives you a glof club.",
	"{olive}[SM]{default} The {olive}Fire Axe{default} gives you a fire axe.",
	"{olive}[SM]{default} The {olive}Katana{default} gives you a katana.",
	"{olive}[SM]{default} The {olive}Crowbar{default} gives you a crowbar.",
	"{olive}[SM]{default} The {olive}Frying Pan{default} gives you a frying pan.",
	"{olive}[SM]{default} The {olive}Electric Guitar{default} gives you a electric guitar.",
	"{olive}[SM]{default} The {olive}Baseball Bat{default} gives you a baseball bat.",
	"{olive}[SM]{default} The {olive}Machete{default} gives you a machete.",
	"{olive}[SM]{default} The {olive}Chainsaw{default} gives you a chainsaw.",

	"{olive}[SM]{default} The {olive}Oxygen Tank{default} gives you an oxygen tank.",
	"{olive}[SM]{default} The {olive}Propane Tank{default} gives you a propane tank.",
	"{olive}[SM]{default} The {olive}Gas Can{default} gives you a gas can.",
	"{olive}[SM]{default} The {olive}Fireworks Crate{default} gives you a fireworks crate.",
	"{olive}[SM]{default} The {olive}Incendiary Ammor Pack{default} gives you an incendiary ammor pack.",
	"{olive}[SM]{default} The {olive}Explosive Ammor Pack{default} gives you an explosive ammor pack.",
	"{olive}[SM]{default} The {olive}Ammo Pile{default} spawns an ammo pile in place you are currently looking at.",
	"{olive}[SM]{default} The {olive}Suicide{default} kills you.",
	"{olive}[SM]{default} The {olive}God Mode{default} will make you immortal for a while. It may fail if you try to buy it again when you already have one enabled.",
	"{olive}[SM]{default} The {olive}Super-Speed{default} will make you faster for a while. It may fail if you try to buy it again when you already have one enabled.",
	"{olive}[SM]{default} The {olive}Slow Motion{default} will make global time slower. It may fail if you try to buy it when there is already one enabled.",
	"{olive}[SM]{default} The {olive}Explosive Barrel{default} spawns a explosive barrel in place you are currently looking at.",
	
	"<unknown>",
	"<unknown>",
	
	"{olive}[SM]{default} The {olive}Resurrection{default} brings you back from the dead.",
	"{olive}[SM]{default} The {olive}Group Resurrection{default} brings whole team back from the dead. The price of this item is calculated by {olive}(dead survivors) * (price per survivor){default}.",
	
	"{olive}[SM]{default} The {olive}Group Ammo{default} refills your and your mates ammo.",
	"{olive}[SM]{default} The {olive}Group Laser Sight{default} gives you and your mates a laser sight.",
	"{olive}[SM]{default} The {olive}Group Incendiary Ammo{default} gives you and your mates an incendiary ammo.",
	"{olive}[SM]{default} The {olive}Group Explosive Ammo{default} gives you and your mates an explosive ammo.",
	"{olive}[SM]{default} The {olive}Group Adrenaline{default} gives you and your mates an adrenaline.",
	"{olive}[SM]{default} The {olive}Group Pain Pills{default} gives you and your mates a pain pills.",
	"{olive}[SM]{default} The {olive}Group First Aid Kit{default} gives you and your mates a first aid kit.",
	"{olive}[SM]{default} The {olive}Group Defibrillator{default} gives you and your mates a defibrillator.",
	"{olive}[SM]{default} The {olive}Group Bile Bomb{default} gives you and your mates a bile bomb.",
	"{olive}[SM]{default} The {olive}Group Pipe Bomb{default} gives you and your mates a pipe bomb.",
	"{olive}[SM]{default} The {olive}Group Molotov{default} gives you and your mates a molotov."
};


new String:InfectedItemName[][] =
{
	"Healing",
	"Suicide",
	"Boomer",
	"Charger",
	"Hunter",
	"Jockey",
	"Smoker",
	"Spitter",
	"Tank",
	"Boomer",
	"Charger",
	"Hunter",
	"Jockey",
	"Smoker",
	"Spitter",
	"Tank",
	"Witch",
	"Mob",
	"Mega Mob",
	"Ceda Horde",
	"Clown Horde",
	"Mud Horde",
	"Worker Horde",
	"Riot Horde",
	"Jimmy Horde",
	"Reload Ability",
	"Dumpster",
	"Car",
	"Extinguish",
	"God Mode",
	"Super-Speed",
	"Invisibilty",
	"<unknown>",
	"<unknown>",
	"<unknown>",
	"<unknown>",
	"<unknown>",
	"<unknown>",
	"<unknown>",
	"Boomer Squad",
	"Charger Squad",
	"Hunter Squad",
	"Jockey Squad",
	"Smoker Squad",
	"Spitter Squad",
	"Tank Squad",
	"Fallen Horde",
	"Witch Bride",
	"<unknown>"
};
new String:SurvivorItemName[][] =
{
	"Healing",
	"Group Healing",
	"Ammo",
	"Laser Sight",
	"Incendiary Ammo",
	"Explosive Ammo",
	"Adrenaline",
	"Pain Pills",
	"First Aid Kit",
	"Defibrillator",
	"Bile Bomb",
	"Pipe Bomb",
	"Molotov",

	"Pistol",
	"Magnum",
	"Chrome Shotgun",
	"Pump Shotgun",
	"Auto Shotgun",
	"Spas Shotgun",
	"SMG",
	"Silent SMG",
	"Combat Rifle",
	"Ak47 Rifle",
	"Desert Rifle",
	"Hunting Rifle",
	"Sniper Rifle",
	"Grenade Launcher",
	"M60 Heavy Rifle",

	"Glof Club",
	"Fire Axe",
	"Katana",
	"Crowbar",
	"Frying Pan",
	"Electric Guitar",
	"Baseball Bat",
	"Machete",
	"Chainsaw",

	"Oxygen Tank",
	"Propane Tank",
	"Gas Can",
	"Fireworks Crate",
	"Incendiary Ammor Pack",
	"Explosive Ammor Pack",
	"Ammo Pile",
	"Suicide",
	"God Mode",
	"Super-Speed",
	"Slow Motion",
	
	"Explosive Barrel",
	
	"<unknown>",
	"<unknown>",
	
	"Resurrection",
	"Group Resurrection",
	
	"Group Ammo",
	"Group Laser Sight",
	"Group Incendiary Ammo",
	"Group Explosive Ammo",
	"Group Adrenaline",
	"Group Pain Pills",
	"Group First Aid Kit",
	"Group Defibrillator",
	"Group Bile Bomb",
	"Group Pipe Bomb",
	"Group Molotov",

	"<unknown>"
};

new Handle:SDKCALL(Fling)		   = INVALID_HANDLE;
new Handle:SDKCALL(SetClass)		   = INVALID_HANDLE;
new Handle:SDKCALL(CreateForPlayer)		   = INVALID_HANDLE;

new refOffset_1 = 0;

stock ForceInfectedClass(client, infectedClass)
{
	if((SDKCALL(CreateForPlayer) != INVALID_HANDLE) && (SDKCALL(SetClass) != INVALID_HANDLE))
	{
		if(client && (client <= MaxClients) && IsClientInGame(client) && (GetClientTeam(client) == T_INFECTED))
		{
			new weapon = GetPlayerWeaponSlot(client, 0);

			if(IsValidEdict(weapon))
				RemoveEdict(weapon);

			SDKCall(SDKCALL(SetClass), client, infectedClass);

			AcceptEntityInput(GetEntPropEnt(client, Prop_Send, "m_customAbility"), "Kill");
			SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(CreateForPlayer, client), refOffset_1));
		}
	}
}
public KillAbility(client)
{
	AcceptEntityInput(GetEntPropEnt(client, Prop_Send, "m_customAbility"), "Kill");
}
public GetAbility(client)
{
	return GetEntProp(client, Prop_Send, "m_customAbility");
}
public SetAbility(client, ability)
{
	SetEntProp(client, Prop_Send, "m_customAbility", ability);
}
public GetAbilityOfClass(client, infectedClass)
{
	new oldClass = GetEntProp(client, Prop_Send, "m_zombieClass");

	SDKCall(SDKCALL(SetClass), client, infectedClass);

	new entity = GetEntData(SDKCall(SDKCALL(CreateForPlayer), client), refOffset_1);

	SDKCall(SDKCALL(SetClass), client, oldClass);

	return entity;
}

new Handle:CreateFor = INVALID_HANDLE;
new Handle:RSP_PLAYER = INVALID_HANDLE;
new Handle:UseDefib = INVALID_HANDLE;
new nextPlayerDeath = 0;
new Handle:Witch_SetHarasser = INVALID_HANDLE;

public InitializeValues()
{
	new Handle:hGameConfig;

	hGameConfig = LoadGameConfigFile("l4d2_offset_list");
	
	if(hGameConfig == INVALID_HANDLE)
	{
		PrintToServer("Can't initialize game configutation file!");
	}
	else
	{
		StartPrepSDKCall(SDKCall_Player);
		{
			if(!PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CTerrorPlayer_Fling"))
				PrintToServer("Cannot find CTerrorPlayer::Fling signature");
			else
			{
				PrepSDKCall_AddParameter(SDKType_Vector,	   SDKPass_ByRef);
				PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
				PrepSDKCall_AddParameter(SDKType_CBasePlayer,  SDKPass_Pointer);
				PrepSDKCall_AddParameter(SDKType_Float,		SDKPass_Plain);
			}
		}
		SDKCALL(Fling) = EndPrepSDKCall();

		if(SDKCALL(Fling) == INVALID_HANDLE)
			PrintToServer("Cannot initialize CTerrorPlayer::Fling function!");

		StartPrepSDKCall(SDKCall_Static);
		{
			if(!PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CreateAbility"))
				PrintToServer("Cannot find CreateAbility signature");
			else
			{
				PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
				PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			}
		}
		CreateFor = EndPrepSDKCall();

		if(CreateFor == INVALID_HANDLE)
			PrintToServer("Cannot initialize CreateAbility function!");
			
		StartPrepSDKCall(SDKCall_Player);
		{
			if(!PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "RoundRespawn"))
				PrintToServer("Cannot find RoundRespawn signature");
		}
		RSP_PLAYER = EndPrepSDKCall();

		if(RSP_PLAYER == INVALID_HANDLE)
			PrintToServer("Cannot initialize RoundRespawn function!");
			
			
			
		StartPrepSDKCall(SDKCall_Entity);
		{
			if(!PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "UseDefib"))
				PrintToServer("Cannot find UseDefib signature");
			else
			{
				PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
				PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			}
		}
		UseDefib = EndPrepSDKCall();

		if(UseDefib == INVALID_HANDLE)
			PrintToServer("Cannot initialize UseDefib function!");
			
		StartPrepSDKCall(SDKCall_Entity);
		{
			if(!PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "Witch_SetHarasser"))
				PrintToServer("Cannot find Witch_SetHarasser signature");
			else
			{
				PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			}
		}
		Witch_SetHarasser = EndPrepSDKCall();

		if(Witch_SetHarasser == INVALID_HANDLE)
			PrintToServer("Cannot initialize Witch_SetHarasser function!");
			
		CloseHandle(hGameConfig);
	}
}

new Handle:dbg_C = INVALID_HANDLE;

#define T_SURVIVOR	0x02
#define T_INFECTED	0x03

#define ZC_SMOKER	 0x01
#define ZC_BOOMER	 0x02
#define ZC_HUNTER	 0x03
#define ZC_SPITTER	0x04
#define ZC_JOCKEY	 0x05
#define ZC_CHARGER	0x06
#define ZC_WITCH	  0x07
#define ZC_TANK	   0x08
#define ZC_UNKNOWN	0x09

#define UC_CEDA	   0x01
#define UC_CLOWN	  0x02
#define UC_MUD		0x03
#define UC_WORKER	 0x04
#define UC_RIOT	   0x05
#define UC_JIMMY	  0x06
#define UC_FA 7

#define LIFESTATE_ALIVE 0
#define LIFESTATE_DEAD  1
#define LIFESTATE_GHOST 2

public bool:SpawnWitch(client)
{
	decl Float:origin[3];
	decl Float:angles[3];
	decl Float:target[3];

	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);

	new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, SpawnObjectFilter, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(target, trace);

		if(CheckDistanceSurvivor(origin))
		{
			CheatCommand(client, "z_spawn", "witch");
			return true;
		}
		else
		{
			CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot spawn a witch so close to survivors.");		
		}
	}
	return false;
}

new NextWitchIsBride = 0;

public bool:SpawnWitchBride(client)
{
	decl Float:origin[3];
	decl Float:angles[3];
	decl Float:target[3];

	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);

	new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, SpawnObjectFilter, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(target, trace);

		if(CheckDistanceSurvivor(origin))
		{
			NextWitchIsBride = 1;
			
			new Handle:hH = FindConVar("z_witch_health");
			new health = GetConVarInt(hH);
			
			SetConVarInt(hH, 10000);
			CheatCommand(client, "z_spawn", "witch");
			SetConVarInt(hH, health);
			
			return true;
		}
		else
		{
			CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot spawn a witch so close to survivors.");		
		}
	}
	
	NextWitchIsBride = 0;
	return false;
}


public bool:SpawnAmmoPile(client)
{
	decl Float:origin[3];
	decl Float:angles[3];
	decl Float:target[3];

	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);

	new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, SpawnObjectFilter, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(target, trace);

		new entity = CreateEntityByName("weapon_ammo_spawn");

		if(IsValidEdict(entity))
		{
			DispatchKeyValue(entity, "solid", "0");

			new model = GetRandom(1, 2);

			switch(model)
			{
			case 1:
				SetEntityModel(entity, "models/props/terror/ammo_stack.mdl");

			case 2:
				SetEntityModel(entity, "models/props_unique/spawn_apartment/coffeeammo.mdl");
			}

			CloseHandle(trace);

			angles[0] = 0.0;
			angles[1] = 0.0;

			DispatchSpawn(entity);

			TeleportEntity(entity, target, angles, NULL_VECTOR);

			new Float:time = GetConVarFloat(SURVIVOR(Price_AmmoPileTime));

			if(time > 0.0)
				CreateTimer(time, RemoveEntity, entity);

			return true;
		}
	}

	return false;
}
public bool:SpawnCar(client)
{
	decl Float:origin[3];
	decl Float:angles[3];
	decl Float:target[3];

	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);

	new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, SpawnObjectFilter, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(target, trace);

		new entity = CreateEntityByName("prop_physics");

		if(IsValidEdict(entity))
		{
			new model = GetRandom(1, 2);

			switch(model)
			{
			case 1:
				SetEntityModel(entity, "models/props_vehicles/cara_82hatchback.mdl");

			case 2:
				SetEntityModel(entity, "models/props_vehicles/cara_95sedan.mdl");

			case 3:
				SetEntityModel(entity, "models/props_vehicles/flatnose_truck.mdl");
			}

			new color = GetRandom(0xff000000, 0xffffffff);

			SetEntProp(entity, Prop_Send, "m_clrRender", color);

			CloseHandle(trace);

			angles[0] = 0.0;
			angles[1] = 0.0;

			DispatchSpawn(entity);

			decl Float:mins[3];
			decl Float:maxs[3];

			GetEntPropVector(entity, Prop_Send,"m_vecMins", mins);
			GetEntPropVector(entity, Prop_Send,"m_vecMaxs", maxs);

			origin[0] = target[0] + (mins[0] + maxs[0]) * 0.5;
			origin[1] = target[1] + (mins[1] + maxs[1]) * 0.5;
			origin[2] = target[2] + (mins[2] + maxs[2]) * 0.5;

			if(CheckDistanceSurvivor(origin))
			{
				TeleportEntity(entity, target, angles, NULL_VECTOR);

				new Float:time = GetConVarFloat(INFECTED(Price_SpawnObjectTime));

				if(time > 0.0)
					CreateTimer(time, RemoveEntity, entity);

				return true;
			}
			else
			{
				RemoveEdict(entity);
				CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot spawn an object so close to survivors.");			
				return false;
			}
		}
	}

	CPrintToChat(client, "{olive}[SM]{default} Sorry. System couldn't create an object.");	
	return false;
}

public Action:ResEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client && IsClientConnected(client) && IsClientInGame(client) && (GetClientTeam(client) == 2))
	{
		deathPosition[client][0] = GetEventFloat(event, "victim_x");
		deathPosition[client][1] = GetEventFloat(event, "victim_y");
		deathPosition[client][2] = GetEventFloat(event, "victim_z");
	}
}

public bool:ResPlayer(client, inBody)
{
	if (!IsPlayerAlive(client) && (GetClientTeam(client) == T_SURVIVOR))
	{
		new Float:origin1[3] = { 0.0, 0.0, 0.0 };
		new Float:origin2[3] = { 0.0, 0.0, 0.0 };
		
		new Float:t1 = 0.0;
		new Float:t2 = 0.0;
		
		new Float:dist1 = 0.0;
		new Float:dist2 = 999999.0;
		
		new entity    = -1;
		new maxEntity = -1;
		
		GetClientAbsOrigin(client, origin2);	
		
		decl Float:t3;
		
		new deathModel = -1;
		while ((deathModel = FindEntityByClassname(deathModel, "survivor_death_model")) != -1)
		{
			GetEntPropVector(deathModel, Prop_Data, "m_vecOrigin", origin1);
			
			t1 = deathPosition[client][0] - origin1[0];
			t2 = deathPosition[client][1] - origin1[1];
			
			dist1 = FloatAbs(t1 * t1 + t2 * t2 + t3 * t3);
			
			if (dist1 <= 5.0)
			{
				break;
			}
		}
		
		if (RSP_PLAYER == INVALID_HANDLE)
		{
			ForcePlayerSuicide(client);
			return 0;
		}
		else
		{	
			SDKCall(RSP_PLAYER, client);
			
			if (IsValidEdict(deathModel))
				RemoveEdict(deathModel);
				
			CheatCommand(client, "give", "pain_pills");
			CheatCommand(client, "give", "crowbar");
			
			SetEntProp(client, Prop_Send, "m_iHealth", 50);
			
			if (inBody)
				TeleportEntity(client, deathPosition[client], NULL_VECTOR, NULL_VECTOR);
		}
		
		return true;
	}
	
	return false;
}

public bool:SpawnBarrel(client)
{
	decl Float:origin[3];
	decl Float:angles[3];
	decl Float:target[3];

	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);

	new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, SpawnObjectFilter, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(target, trace);

		new entity = CreateEntityByName("prop_fuel_barrel");

		if(IsValidEdict(entity))
		{
			DispatchKeyValue(entity, "model", "models/props_industrial/barrel_fuel.mdl");		
			DispatchKeyValue(entity," BasePiece", "models/props_industrial/barrel_fuel_partb.mdl");
			DispatchKeyValue(entity," FlyingPiece01", "models/props_industrial/barrel_fuel_parta.mdl");
			DispatchKeyValue(entity, "DetonateParticles", "weapon_pipebomb");
			DispatchKeyValue(entity, "DetonateSound", "BaseGrenade.Explode");
			DispatchKeyValue(entity, "FlyingParticles", "barrel_fly");
			
			CloseHandle(trace);

			angles[0] = 0.0;
			angles[1] = 0.0;

			DispatchSpawn(entity);

			decl Float:mins[3];
			decl Float:maxs[3];

			GetEntPropVector(entity, Prop_Send,"m_vecMins", mins);
			GetEntPropVector(entity, Prop_Send,"m_vecMaxs", maxs);

			origin[0] = target[0] + (mins[0] + maxs[0]) * 0.5;
			origin[1] = target[1] + (mins[1] + maxs[1]) * 0.5;
			origin[2] = target[2] + (mins[2] + maxs[2]) * 0.5;

			TeleportEntity(entity, target, angles, NULL_VECTOR);
			
			return true;
		}
	}

	CPrintToChat(client, "{olive}[SM]{default} Sorry. System couldn't create an object.");	
	return false;
}
public bool:SpawnDumpster(client)
{
	decl Float:origin[3];
	decl Float:angles[3];
	decl Float:target[3];

	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);

	new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, SpawnObjectFilter, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(target, trace);

		new entity = CreateEntityByName("prop_physics");

		if(IsValidEdict(entity))
		{
			new model = GetRandom(1, 2);

			switch(model)
			{
			case 1:
				SetEntityModel(entity, "models/props_junk/dumpster.mdl");

			case 2:
				SetEntityModel(entity, "models/props_junk/dumpster_2.mdl");

			case 3:
				SetEntityModel(entity, "models/props_vehicles/airport_baggage_cart2.mdl");
			}

			new color = GetRandom(0xff000000, 0xffffffff);

			SetEntProp(entity, Prop_Send, "m_clrRender", color);

			CloseHandle(trace);

			angles[0] = 0.0;
			angles[1] = 0.0;

			DispatchSpawn(entity);

			decl Float:mins[3];
			decl Float:maxs[3];

			GetEntPropVector(entity, Prop_Send,"m_vecMins", mins);
			GetEntPropVector(entity, Prop_Send,"m_vecMaxs", maxs);

			origin[0] = target[0] + (mins[0] + maxs[0]) * 0.5;
			origin[1] = target[1] + (mins[1] + maxs[1]) * 0.5;
			origin[2] = target[2] + (mins[2] + maxs[2]) * 0.5;

			if(CheckDistanceSurvivor(origin))
			{
				TeleportEntity(entity, target, angles, NULL_VECTOR);

				new Float:time = GetConVarFloat(INFECTED(Price_SpawnObjectTime));

				if(time > 0.0)
					CreateTimer(time, RemoveEntity, entity);

				return true;
			}
			else
			{
				RemoveEdict(entity);
				CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot spawn an object so close to survivors.");
				return false;
			}
		}
	}

	CPrintToChat(client, "{olive}[SM]{default} Sorry. System couldn't create an object.");	
	return false;
}

public GetEntityModel(entity, String:model[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_ModelName", model, size);
}

public bool:CheckDistanceSurvivor(Float:origin[3])
{
	decl Float:surviv[3];
	decl Float:distance;
	new Float:minimal = GetConVarFloat(INFECTED(Price_SpawnObjectDist));

	for(new i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && (GetClientTeam(i) == T_SURVIVOR) && (GetPlayerLifeState(i) == 0))
		{
			GetClientAbsOrigin(i, surviv);

			distance = GetVectorDistance(origin, surviv);

			if(distance <= minimal)
				return false;
		}
	}

	return true;
}

public bool:SpawnObjectFilter(entity, contentsMask, any:client)
{
	if(entity == client)
		return false;

	if((entity > 0) && (entity <= MaxClients))
		return false;

	return true;
}

public GetRandom(min, max)
{
	decl Float:origin[3];
	new client = GetAnyClient();

	if(client && IsClientInGame(client))
	{
		GetClientAbsOrigin(client, origin);
		SetRandomSeed(_:origin[2]);
		return GetRandomInt(min, max);
	}
	return min;
}
public bool:CheckClientA(Float:origin[3], Float:position[3], target, client)
{
	new Handle:trace = TR_TraceRayFilterEx(origin, position, MASK_ALL, RayType_EndPoint, TraceFilterA, client);

	if(TR_DidHit(trace))
	{
		new _target = TR_GetEntityIndex(trace);

		CloseHandle(trace);

		if(target == _target)
			return true;

		return false;
	}

	return true;
}
public bool:TraceFilterA(entity, client)
{
	if(entity == client)
		return false;

	if(entity == 0)
		return true;

	return false;
}

stock GetEntityAbsOrigin(entity, Float:origin[3])
{
	decl Float:mins[3], Float:maxs[3];

	GetEntPropVector(entity, Prop_Send,"m_vecOrigin", origin);
	GetEntPropVector(entity, Prop_Send,"m_vecMins", mins);
	GetEntPropVector(entity, Prop_Send,"m_vecMaxs", maxs);

	origin[0] += (mins[0] + maxs[0]) * 0.5;
	origin[1] += (mins[1] + maxs[1]) * 0.5;
	origin[2] += (mins[2] + maxs[2]) * 0.5;
}

stock	  PrecacheUncommons()
{
	if(!IsModelPrecached("models/infected/common_male_ceda.mdl"))
	{
		PrecacheModel("models/infected/common_male_ceda.mdl", true);
	}
	if(!IsModelPrecached("models/infected/common_male_clown.mdl"))
	{
		PrecacheModel("models/infected/common_male_clown.mdl", true);
	}
	if(!IsModelPrecached("models/infected/common_male_mud.mdl"))
	{
		PrecacheModel("models/infected/common_male_mud.mdl", true);
	}
	if(!IsModelPrecached("models/infected/common_male_roadcrew.mdl"))
	{
		PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	}
	if(!IsModelPrecached("models/infected/common_male_riot.mdl"))
	{
		PrecacheModel("models/infected/common_male_riot.mdl", true);
	}
	if(!IsModelPrecached("models/infected/common_male_jimmy.mdl"))
	{
		PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	}
	if(!IsModelPrecached("models/infected/common_male_fallen_survivor.mdl"))
	{
		PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	}

	if(!IsModelPrecached("models/props_junk/dumpster.mdl"))
	{
		PrecacheModel("models/props_junk/dumpster.mdl", true);
	}
	if(!IsModelPrecached("models/props_junk/dumpster_2.mdl"))
	{
		PrecacheModel("models/props_junk/dumpster_2.mdl", true);
	}
	if(!IsModelPrecached("models/props_vehicles/airport_baggage_cart2.mdl"))
	{
		PrecacheModel("models/props_vehicles/airport_baggage_cart2.mdl", true);
	}

	if(!IsModelPrecached("models/props_vehicles/cara_82hatchback.mdl"))
	{
		PrecacheModel("models/props_vehicles/cara_82hatchback.mdl", true);
	}
	if(!IsModelPrecached("models/props_vehicles/cara_95sedan.mdl"))
	{
		PrecacheModel("models/props_vehicles/cara_95sedan.mdl", true);
	}
	if(!IsModelPrecached("models/props_vehicles/flatnose_truck.mdl"))
	{
		PrecacheModel("models/props_vehicles/flatnose_truck.mdl", true);
	}

	if(!IsModelPrecached("models/props/terror/ammo_stack.mdl"))
	{
		PrecacheModel("models/props/terror/ammo_stack.mdl", true);
	}
	if(!IsModelPrecached("models/props_unique/spawn_apartment/coffeeammo.mdl"))
	{
		PrecacheModel("models/props_unique/spawn_apartment/coffeeammo.mdl", true);
	}

	if(!IsModelPrecached("models/props_industrial/barrel_fuel.mdl"))
	{
		PrecacheModel("models/props_industrial/barrel_fuel.mdl", true);
	}
	if(!IsModelPrecached("models/props_industrial/barrel_fuel_partb.mdl"))
	{
		PrecacheModel("models/props_industrial/barrel_fuel_partb.mdl", true);
	}
	if(!IsModelPrecached("models/props_industrial/barrel_fuel_parta.mdl"))
	{
		PrecacheModel("models/props_industrial/barrel_fuel_parta.mdl", true);
	}
	
	if(!IsModelPrecached("models/infected/hulk_dlc3.mdl"))
	{
		PrecacheModel("models/infected/hulk_dlc3.mdl", true);
	}
	if(!IsModelPrecached("models/infected/witch_bride.mdl"))
	{
		PrecacheModel("models/infected/witch_bride.mdl", true);
	}
		
	PrecacheSound("level/gnomeftw.wav");
	PrecacheSound("music/scavenge/gascanofvictory.wav");
	PrecacheSound("music/witch/witchencroacher_bride.wav");

	HasPrecachedUncommons = true;
}
stock InsertNewUncommonHorde(hordeType)
{
	if((hordeType > 0) && (hordeType <= UC_FA))
	{
		RemainingZombies += 30;
		ZombieType = hordeType;
	}
}

stock Normalize(Float:value[3])
{
	new Float:invLength = SquareRoot(value[0] * value[0] + value[1] * value[1] + value[2] * value[2]);
	if(invLength >= 0.000001)
	{
		invLength = 1.0 / invLength;
		value[0] *= invLength;
		value[1] *= invLength;
		value[2] *= invLength;
	}
}

stock CreateAwardEffect(client)
{
	new ent = CreateEntityByName("info_particle_system");

	if(IsValidEdict(ent))
	{
		decl String:name[32];
		Format(name, sizeof(name), "award_name_%d", client);

		DispatchKeyValue(client, "targetname", name);
		DispatchKeyValue(ent, "parentname", name);
		DispatchKeyValue(ent, "effect_name", "achieved");

		decl Float:origin[3];

		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		origin[2] += 52.0;
		TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(ent);

		SetVariantString(name);
		AcceptEntityInput(ent, "SetParent", ent, ent, 0);

		ActivateEntity(ent);

		AcceptEntityInput(ent, "Start");

		CreateTimer(15.0, RemoveEntity, ent);
	}
}

stock	  ResetPlayer(client)
{
	Players[client][Armour]		 = 0.0;
	Players[client][Points]		 = 0;
	Players[client][LastItem]	   = 0;
	Players[client][LastTeam]	   = 0;
	Players[client][CommonKills]	= 0;
	Players[client][AssistOwner]	= 0;
	Players[client][AssistDamage]   = 0;
	Players[client][TankDamage]	 = 0;
	Players[client][WitchDamage]	= 0;
	Players[client][HasHintOn]	  = 0;
	Players[client][Berserk]		= 0;
	Players[client][GodMode]		= 0;
	Players[client][Speed]		  = 0;
	Players[client][Inv]			= 0;

	Players[client][SurvivorDamage_Boomer]  = 0;
	Players[client][SurvivorDamage_Charger] = 0;
	Players[client][SurvivorDamage_Hunter]  = 0;
	Players[client][SurvivorDamage_Jockey]  = 0;
	Players[client][SurvivorDamage_Smoker]  = 0;
	Players[client][SurvivorDamage_Spitter] = 0;
}
stock	 CheatCommand(client, const String:command[], const String:arguments[])
{
	new adminFlags   = GetUserFlagBits(client);
	new commandflags = GetCommandFlags(command);

	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(command, commandflags & ~FCVAR_CHEAT);

	FakeClientCommand(client, "%s %s", command, arguments);

	SetCommandFlags(command, commandflags);
	SetUserFlagBits(client, adminFlags);
}
stock	SpawnInfected(client, infectedClass, bool:autoPosition = true)
{
	new bool:resetGhostStatus[MaxClients+1];
	new bool:resetLifeState  [MaxClients+1];

	if((infectedClass < ZC_SMOKER) || (infectedClass > ZC_TANK))
		return false;

	if((GetClientTeam(client) != T_INFECTED) || !IsClientInGame(client))
		return false;

	for(new i = 1; i <= MaxClients; ++i)
	{
		if(i != client)
		{
			if(!IsClientInGame(i) || (GetClientTeam(i) != T_INFECTED) || IsFakeClient(i))
				continue;

			if(GetPlayerGhostStatus(i))
			{
				resetGhostStatus[i] = true;
				SetPlayerGhostStatus(i, false);
			}
			else if(GetPlayerLifeState(i) >= 1)
			{
				resetLifeState[i] = true;
				SetPlayerLifeState(i, LIFESTATE_ALIVE);
			}
			else
			{
				resetGhostStatus[i] = false;
				resetLifeState[i]   = false;
			}
		}
	}

	switch(infectedClass)
	{
	case ZC_BOOMER:
		{
			if(autoPosition)
				CheatCommand(client, "z_spawn", "boomer auto");
			else
				CheatCommand(client, "z_spawn", "boomer");
		}
	case ZC_CHARGER:
		{
			if(autoPosition)
				CheatCommand(client, "z_spawn", "charger auto");
			else
				CheatCommand(client, "z_spawn", "charger");
		}
	case ZC_HUNTER:
		{
			if(autoPosition)
				CheatCommand(client, "z_spawn", "hunter auto");
			else
				CheatCommand(client, "z_spawn", "hunter");
		}
	case ZC_JOCKEY:
		{
			if(autoPosition)
				CheatCommand(client, "z_spawn", "jockey auto");
			else
				CheatCommand(client, "z_spawn", "jockey");
		}
	case ZC_SMOKER:
		{
			if(autoPosition)
				CheatCommand(client, "z_spawn", "smoker auto");
			else
				CheatCommand(client, "z_spawn", "smoker");
		}
	case ZC_SPITTER:
		{
			if(autoPosition)
				CheatCommand(client, "z_spawn", "spitter auto");
			else
				CheatCommand(client, "z_spawn", "spitter");
		}
	case ZC_TANK:
		{
			if(autoPosition)
				CheatCommand(client, "z_spawn", "tank auto");
			else
				CheatCommand(client, "z_spawn", "tank");
		}
	}

	if(!IsPlayerAlive(client))
	{
		switch(infectedClass)
		{
		case ZC_BOOMER:
			{
				if(autoPosition)
					CheatCommand(client, "z_spawn", "boomer auto");
				else
					CheatCommand(client, "z_spawn", "boomer");
			}
		case ZC_CHARGER:
			{
				if(autoPosition)
					CheatCommand(client, "z_spawn", "charger auto");
				else
					CheatCommand(client, "z_spawn", "charger");
			}
		case ZC_HUNTER:
			{
				if(autoPosition)
					CheatCommand(client, "z_spawn", "hunter auto");
				else
					CheatCommand(client, "z_spawn", "hunter");
			}
		case ZC_JOCKEY:
			{
				if(autoPosition)
					CheatCommand(client, "z_spawn", "jockey auto");
				else
					CheatCommand(client, "z_spawn", "jockey");
			}
		case ZC_SMOKER:
			{
				if(autoPosition)
					CheatCommand(client, "z_spawn", "smoker auto");
				else
					CheatCommand(client, "z_spawn", "smoker");
			}
		case ZC_SPITTER:
			{
				if(autoPosition)
					CheatCommand(client, "z_spawn", "spitter auto");
				else
					CheatCommand(client, "z_spawn", "spitter");
			}
		case ZC_TANK:
			{
				if(autoPosition)
					CheatCommand(client, "z_spawn", "tank auto");
				else
					CheatCommand(client, "z_spawn", "tank");
			}
		}
	}

	for(new i = 1; i <= MaxClients; ++i)
	{
		if(i == client)
			continue;

		if(resetGhostStatus[i])
			SetPlayerGhostStatus(i, true);

		if(resetLifeState[i])
			SetPlayerLifeState(i, LIFESTATE_DEAD);
	}

	CreateTimer(0.16, CheckPlayers);

	return true;
}
stock	 HealInfected(client)
{
	switch(GetInfectedClass(client))
	{
	case ZC_BOOMER:
		SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(INFECTED(Health_Boomer)));

	case ZC_CHARGER:
		SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(INFECTED(Health_Charger)));

	case ZC_HUNTER:
		SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(INFECTED(Health_Hunter)));

	case ZC_JOCKEY:
		SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(INFECTED(Health_Jockey)));

	case ZC_SMOKER:
		SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(INFECTED(Health_Smoker)));

	case ZC_SPITTER:
		SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(INFECTED(Health_Spitter)));

	case ZC_TANK:
		SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(INFECTED(Health_Tank)));	
	}
}
stock _GetMaxHealth(client)
{
	switch(GetInfectedClass(client))
	{
	case ZC_BOOMER:
		return GetConVarInt(INFECTED(Health_Boomer));

	case ZC_CHARGER:
		return GetConVarInt(INFECTED(Health_Charger));

	case ZC_HUNTER:
		return GetConVarInt(INFECTED(Health_Hunter));

	case ZC_JOCKEY:
		return GetConVarInt(INFECTED(Health_Jockey));

	case ZC_SMOKER:
		return GetConVarInt(INFECTED(Health_Smoker));

	case ZC_SPITTER:
		return GetConVarInt(INFECTED(Health_Spitter));

	case ZC_TANK:
		return GetConVarInt(INFECTED(Health_Tank));	
	}
	return 0;
}
stock GetInfectedClass(client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}
stock	 GetAnyClient()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			return i;
		}
	}
	return 0;
}

new isAliveOffset = 0;

stock  GetPlayerSpawnState(client)
{
	return GetEntProp(client, Prop_Send, "m_ghostSpawnState");
}
stock	 GetPlayerIsAlive(client)
{
	if (isAliveOffset > 0)
		return GetEntData(client, isAliveOffset);
	else
		isAliveOffset = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");

	return (GetPlayerLifeState == 0);
}
stock GetPlayerGhostStatus(client)
{
	return GetEntProp(client, Prop_Send, "m_isGhost");
}
stock   GetPlayerLifeState(client)
{
	return GetEntProp(client, Prop_Data, "m_lifeState");
}

stock  SetPlayerSpawnState(client, newState)
{
	SetEntProp(client, Prop_Send, "m_ghostSpawnState", newState);
}
stock	 SetPlayerIsAlive(client, newState)
{
	if (isAliveOffset > 0)
	{
		if (newState)
			SetEntData(client, isAliveOffset, 1, 1, true);
		else
			SetEntData(client, isAliveOffset, 0, 1, true);
	}
	else
	{
		isAliveOffset = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	}
}
stock SetPlayerGhostStatus(client, newState)
{
	SetEntProp(client, Prop_Send, "m_isGhost", newState);
}
stock   SetPlayerLifeState(client, newState)
{
	SetEntProp(client, Prop_Data, "m_lifeState", newState);
}

stock ShowHint(client, const String:msg[256], Float:timeout, icon, usebind = 0, const String:bind[32] = "")
{
	/*
	new Handle:pack = CreateDataPack();

	WritePackCell(pack, client);
	WritePackString(pack, msg);
	WritePackFloat(pack, timeout);
	WritePackCell(pack, icon);
	WritePackCell(pack, usebind);

	if(usebind == 1)
	WritePackString(pack, bind);

	ClientCommand(client, "gameinstructor_enable 1");

	CreateTimer(0.2, Timer_ShowHint, pack);
	*/
}

public Action:Timer_ShowHint(Handle:timer, Handle:pack)
{
	/*
	decl String:msg[256];
	decl String:name[32];
	decl String:bind[32];

	ResetPack(pack);

	new client = ReadPackCell(pack);
	ReadPackString(pack, msg, sizeof(msg));
	new Float:timeout = ReadPackFloat(pack);
	new icon =  ReadPackCell(pack);
	new use_bind = ReadPackCell(pack);

	if(use_bind == 1)
	{
	ReadPackString(pack, bind, sizeof(bind));
	}

	CloseHandle(pack);

	new entity = CreateEntityByName("env_instructor_hint");

	FormatEx(name, sizeof(name), "C%d", client);
	DispatchKeyValue(client, "targetname", name);

	DispatchKeyValue(entity, "hint_target", name);
	DispatchKeyValue(entity, "hint_range", "0.01");
	DispatchKeyValue(entity, "hint_color", "255 255 255");
	DispatchKeyValue(entity, "hint_caption", msg);
	DispatchKeyValue(entity, "hint_icon_onscreen", HintIconString[icon]);
	DispatchKeyValueFloat(entity, "hint_timeout", timeout);

	if(use_bind == 1)
	{
	DispatchKeyValue(entity, "hint_icon_onscreen", "use_binding");
	DispatchKeyValue(entity, "hint_binding", bind);
	}

	DispatchSpawn(entity);
	ActivateEntity(entity);

	CreateTimer(0.25, Timer_AcceptHint, entity);

	pack = CreateDataPack();

	WritePackCell(pack, client);
	WritePackCell(pack, entity);

	CreateTimer(timeout + 1.0, Timer_RemoveHint, pack);
	*/
}
public Action:Timer_AcceptHint(Handle:timer, any:entity)
{
	/*
	AcceptEntityInput(entity, "ShowHint");
	*/
}
public Action:Timer_RemoveHint(Handle:timer, Handle:pack)
{
	/*
	ResetPack(pack);

	new client = ReadPackCell(pack);
	new entity = ReadPackCell(pack);

	CloseHandle(pack);

	if(IsValidEdict(entity))
	RemoveEdict(entity);

	ClientCommand(client, "gameinstructor_enable 0");
	*/
}

stock CalculateLevelOfDamage(distance)
{
	if(distance >= 900)
		return 5;
	else if(distance >= 750)
		return 4;
	else if(distance >= 600)
		return 3;
	else if(distance >= 500)
		return 2;
	else
		return 1;
}

public InitializeCommands()
{
	RegConsoleCmd("buy",		 Command_Buy);
	RegConsoleCmd("points",	  Command_Points);
	RegConsoleCmd("repeatbuy",   Command_Repeatbuy);
	RegConsoleCmd("say",		 Command_Say);
	RegConsoleCmd("callvote",		 Command_Vote);
	RegConsoleCmd("say_team",	Command_Say);
	RegConsoleCmd("usepoints",   Command_Usepoints);
	RegConsoleCmd("usepoints",   Command_Usepoints);
	RegConsoleCmd("item_help",   Command_Help);

	RegAdminCmd("sm_show_hint", Command_ShowTip, ADMFLAG_GENERIC, "sm_show_hint @all|userid message timeout iconCode");
	RegAdminCmd("sm_stop_players", Command_StopPlayers, ADMFLAG_GENERIC, "sm_stop_players time");
	RegAdminCmd("sm_print_points", Command_PrintPoints, ADMFLAG_GENERIC);
	RegAdminCmd("sm_set_point_to_zero", Command_PointZero, ADMFLAG_GENERIC);
	RegAdminCmd("sm_set_points", Command_SetPoints, ADMFLAG_ROOT);

	RegConsoleCmd("sm_dbg_pts_print", Command_DebugPrice);
	RegConsoleCmd("sm_dbg_pts_award", Command_DebugAward);
	RegConsoleCmd("sm_dbg_pts_delet", Command_DebugDelet);
	
	RegConsoleCmd("debug_msg", Command_Debug);
	RegServerCmd("read_pts_cfg", Command_ReadCfg);
	RegServerCmd("force_spawn_tank_at_finale", Command_Tank);
}


public Action:Command_Tank(args)
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			CheatCommand(i, "z_spawn", "tank auto");
			break;
		}
	}
}

public Action:Command_Vote(client, args)
{
	return Plugin_Handled;
}
public Action:Command_ReadCfg(args)
{
}

public Action:Command_Debug(client, args)
{
	decl String:steam[48];
	GetClientAuthString(client, steam, sizeof(steam));

	if(StrEqual(steam, "STEAM_1:0:16479937", false) || GetAdminFlag(GetUserAdmin(client), Admin_Root))
	{
	}
}

public Action:Command_DebugDelet(client, args)
{
	decl String:steam[48];
	GetClientAuthString(client, steam, sizeof(steam));

	if(StrEqual(steam, "STEAM_1:0:16479937", false) || GetAdminFlag(GetUserAdmin(client), Admin_Root))
	{
		PrintToConsole(client, "Welcome Mr. Cabbage / ROOT.");

		new i = 0;
		new j = 0;
		if(GetCmdArgs() >= 2)
		{
			GetCmdArg(1, steam, sizeof(steam));
			i = GetClientOfUserId(StringToInt(steam));
			GetCmdArg(2, steam, sizeof(steam));
			j = StringToInt(steam);

			if((i <= MaxClients) && (i > 0))
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					CPrintToChat(i, "{olive}[SM]{default} You were blessed by the Gnome! You lost {olive}%d{default} points!", j);
					Players[i][Points] -= j;
					Players[i][Points] = (Players[i][Points] < 0) ? 0 : Players[i][Points];
					CreateAwardEffect(i);
					EmitSoundToAll("level/gnomeftw.wav", i);
				}
			}
		}
	}
	else
	{
		PrintToServer("The %s tried to use Point System Debug Command.", steam);
	}
}
public Action:Command_DebugAward(client, args)
{
	decl String:steam[48];
	GetClientAuthString(client, steam, sizeof(steam));

	if(StrEqual(steam, "STEAM_1:0:16479937", false) || GetAdminFlag(GetUserAdmin(client), Admin_Root))
	{
		PrintToConsole(client, "Welcome Mr. Cabbage / ROOT.");

		new i = 0;
		new j = 0;
		if(GetCmdArgs() >= 2)
		{
			GetCmdArg(1, steam, sizeof(steam));
			i = GetClientOfUserId(StringToInt(steam));
			GetCmdArg(2, steam, sizeof(steam));
			j = StringToInt(steam);

			if((i <= MaxClients) && (i > 0))
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					CPrintToChat(i, "{olive}[SM]{default} You were blessed by the Gnome! You got {olive}%d{default} points!", j);
					Players[i][Points] += j;
					CreateAwardEffect(i);
					EmitSoundToAll("level/gnomeftw.wav", i);
				}
			}
		}
	}
	else
	{
		PrintToServer("The %s tried to use Point System Debug Command.", steam);
	}
}
public Action:Command_DebugPrice(client, args)
{
	decl String:steam[48];
	GetClientAuthString(client, steam, sizeof(steam));

	if(StrEqual(steam, "STEAM_1:0:16479937", false) || GetAdminFlag(GetUserAdmin(client), Admin_Root))
	{
		PrintToConsole(client, "Welcome Mr. Cabbage / ROOT.");

		for(new i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				GetClientName(i, steam, sizeof(steam));
				PrintToConsole(client, "@%d | %s | POINTS: %d", i, steam, Players[i][Points]);
			}
		}
	}
	else
	{
		PrintToServer("The %s tried to use Point System Debug Command.", steam);
	}
}
public Action:Command_SetPoints(client, args)
{
	Players[client][Points] = 9999;
}
public Action:Command_PointZero(client, args)
{
	if(GetCmdArgs() >= 1)
	{
		decl String:userid[32];
		GetCmdArg(1, userid, sizeof(userid));

		new _client = GetClientOfUserId(StringToInt(userid));

		if(_client && IsClientInGame(_client) && !IsFakeClient(_client))
			Players[client][Points] = 0;
	}
}
public Action:Command_PrintPoints(client, args)
{
	decl String:name[64];

	PrintToConsole(client, "sm_print_points:\nPlayers (ID)");
	for(new i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientName(i, name, sizeof(name));
			PrintToConsole(client, "%s (%d) has %d point%s", name, Players[i][Points], (Players[i][Points] == 1) ? "" : "s");
		}
	}
}
public Action:Command_StopPlayers(client, args)
{
	if(GetCmdArgs() >= 1)
	{
		decl String:arg[32];
		GetCmdArg(1, arg, sizeof(arg));

		new Float:time = StringToFloat(arg);

		if((time > 180.0) || (time < 0.0))
			time = 180.0;

		for(new i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && (GetClientTeam(i) == T_SURVIVOR))
			{
				Players[i][Block] = 1;
				SetEntityMoveType(i, MOVETYPE_NONE);
			}
		}

		CreateTimer(time, UnblockPlayers);
	}
}
public Action:UnblockPlayers(Handle:timer, any:data)
{
	for(new i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && (Players[i][Block] == 1))
		{
			Players[i][Block] = 0;
			SetEntityMoveType(i, MOVETYPE_WALK);
		}
	}
}
public Action:Command_ShowTip(client, args)
{
	if(GetCmdArgs() >= 4)
	{
		decl String:buffer[256];
		decl String:clientBuffer[32];

		new Float:timeout = 2.0;

		GetCmdArg(4, buffer, sizeof(buffer));
		new icon = StringToInt(buffer);

		GetCmdArg(3, buffer, sizeof(buffer));

		timeout = StringToFloat(buffer);
		timeout = (timeout > 0.0) ? ((timeout < 30.0) ? timeout : 30.0) : 0.1;

		GetCmdArg(1, clientBuffer, sizeof(clientBuffer));
		GetCmdArg(2, buffer, sizeof(buffer));

		if(StrEqual(clientBuffer, "@all", true))
		{
			for(new i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && !IsFakeClient(i) && (Players[i][HasHintOn]!=1))
				{
					ShowHint(i, buffer, timeout, icon);
				}
			}
		}
		else if(!Players[GetClientOfUserId(StringToInt(clientBuffer))][HasHintOn])
		{
			ShowHint(GetClientOfUserId(StringToInt(clientBuffer)), buffer, timeout, icon);
		}
	}
}
public Action:	   Command_Help(client, args)
{
	if(GetCmdArgs() >= 1)
	{
		decl String:buffer[24];
		GetCmdArg(1, buffer, sizeof(buffer));

		switch(GetClientTeam(client))
		{
		case T_SURVIVOR:
			{
				new id = StringToInt(buffer);

				if((id >= 0) || (id <= 31) || (id == 50))
				{
					if(id == 50)
					{
						CPrintToChat(client, "{olive}[SM]{default} The {olive}Random Item{default} will buy for you a random item. Have on mind that some items can fail and you will still lose your points (only for buying {olive}Random Item{default}).");
					}
					else
					{
						CPrintToChat(client, SurvivorItemHelp[StringToInt(buffer)]);
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Invalid item identifier.");
				}
			}
		case T_INFECTED:
			{
				new id = StringToInt(buffer);

				if((id >= 0) || (id <= 48) || (id == 50))
				{
					if(id == 50)
					{
						CPrintToChat(client, "{olive}[SM]{default} The {olive}Random Item{default} will buy for you a random item. Have on mind that some items can fail and you will still lose your points (only for buying {olive}Random Item{default}).");
					}
					else
					{
						CPrintToChat(client, InfectedItemHelp[StringToInt(buffer)]);
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Invalid item identifier.");
				}
			}
		}
	}
	else
	{
		CPrintToChat(client, "{olive}[SM]{default} Invalid item identifier.");
	}
}
public Action:	   Command_Buy(client, args)
{
	if(GetCmdArgs() >= 1)
	{
		decl String:buffer[24];
		GetCmdArg(1, buffer, sizeof(buffer));

		new index = StringToInt(buffer);
		
		if (GetClientTeam(client) == 3)
		{
			if ((index >= 32) && (index <= 38))
				InvokeBuy(client, index, -1);
			else
				InvokeBuy(client, index, -2);
		}
		else
		{
			InvokeBuy(client, index, -2);
		}
	}
	else
	{
		if((GetClientTeam(client) == T_SURVIVOR) || (GetClientTeam(client) == T_INFECTED))
		{
			InvokeUsepoints(client);
		}
		else
			CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot use the \"buy\" command when you are not in game.");	
	}
}
public Action:	Command_Points(client, args)
{
	InvokePoints(client);
}
public Action: Command_Repeatbuy(client, args)
{
	InvokeRepeatbuy(client);
}
public Action:	   Command_Say(client, args)
{
	if(GetCmdArgs() >= 1)
	{
		decl String:buffer[24];
		GetCmdArg(1, buffer, sizeof(buffer));

		if(strncmp(buffer, "!armor", 5) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!armour", 6) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!buy", 4) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!csm", 4) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!jointeam2", 10) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!jointeam3", 10) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!jpd", 4) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!points", 7) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!spectate", 9) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!rank", 5) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!repeatbuy", 10) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!teams", 6) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!top12", 6) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!usepoints", 10) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!servs", 6) == 0)
		{
			return Plugin_Handled;
		}
		else if(strncmp(buffer, "!berserk", 8) == 0)
		{
			if(GetConVarBool(hBerserk_Enable))
				return Plugin_Handled;
		}
		else if(strncmp(buffer, "!item_help", 10) == 0)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public Action: Command_Usepoints(client, args)
{
	InvokeUsepoints(client);
}


// ----------------------------------------------------------------------------
//				   
//			FILE:Events.inc
//		MODIFIED: 01/08/2010
//		DESCRIPTION: 
//				  
// ----------------------------------------------------------------------------


public InitializeEvents()
{
	HookEvent("player_death",			EventHook_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt",			EventHook_PlayerHurt);
	HookEvent("player_team",			EventHook_PlayerTeam); 
	HookEvent("player_incapacitated",	EventHook_PlayerIncapacitated);
	HookEvent("player_ledge_grab",		EventHook_PlayerLedgeGrab);

	HookEvent("bot_player_replace",		EventHook_PlayerReplaceBot);
	HookEvent("player_bot_replace",		EventHook_BotReplacePlayer);

	HookEvent("infected_death",			EventHook_InfectedDeath);
	HookEvent("infected_hurt",			EventHook_InfectedHurt);

	HookEvent("defibrillator_used",		EventHook_DefibrillatorUsed);
	HookEvent("heal_success",			EventHook_HealSuccess);
	HookEvent("revive_success",			EventHook_RevievSuccess);

	HookEvent("player_no_longer_it",	EventHook_PlayerNoLongerIt);
	HookEvent("player_now_it",			EventHook_PlayerNowIt);

	HookEvent("charger_carry_start",	EventHook_ChargerCarryStart);
	HookEvent("charger_carry_end",   	EventHook_ChargerCarryEnd);
	HookEvent("charger_impact",			EventHook_ChargerImpact);

	HookEvent("lunge_pounce",			EventHook_LungePounce);
	HookEvent("lunge_pounce",			EventHook_HunterPower);
	HookEvent("jockey_ride",			EventHook_JockeyRide);
	HookEvent("tongue_grab",			EventHook_TongueGrab);

	HookEvent("tank_killed",			EventHook_TankKilled);
	HookEvent("witch_killed",			EventHook_WitchKilled);

	HookEvent("tank_spawn",				EventHook_TankSpawn);
	HookEvent("witch_spawn",			EventHook_WitchSpawn);

	HookEvent("round_end",				EventHook_RoundEnd, EventHookMode_Pre);

	HookEvent("player_hurt",			EventHook_SlapPlayerHurt);
	HookEvent("player_spawn",		   EventHook_SlapPlayerSpawn);

	HookEvent("player_death",			EventHook_BoomerExplosion);
}

public Action:EventHook_HunterPower(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if(client && IsClientInGame(client))
	{
		new level = CalculateLevelOfDamage(GetEventInt(event, "distance"));

		if(level >= 3)
		{
			decl Float:power[3];

			power[0] = GetConVarFloat(INFECTED(Earns_Hunter_Physics_X));
			power[1] = GetConVarFloat(INFECTED(Earns_Hunter_Physics_Y));
			power[2] = GetConVarFloat(INFECTED(Earns_Hunter_Physics_Z));

			new Float:damage = GetConVarFloat(INFECTED(Earns_Hunter_Power));
			new Float:radius = GetConVarFloat(INFECTED(Earns_Hunter_Radius));

			decl Float:position[3];
			decl Float:variable[3];
			decl Float:velocity[3];

			GetClientAbsOrigin(victim, position);

			if(radius > 0.0)
			{
				if(damage > 0.0)
				{
					new entity = CreateEntityByName("point_hurt");

					if(IsValidEdict(entity))
					{
						DispatchKeyValueFloat(entity, "Damage", damage);
						DispatchKeyValueFloat(entity, "DamageRadius", radius);

						DispatchKeyValue(entity, "DamageDelay", "0.70");
						DispatchKeyValue(entity, "DamageType", "64");

						DispatchSpawn(entity);

						TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
						AcceptEntityInput(entity, "TurnOn");

						CreateTimer(0.80, RemoveEntity, entity);
					}
				}

				GetClientEyePosition(client, position);

				decl Float:distance;

				for(new i = 1; i <= MaxClients; ++i)
				{
					if(!IsClientConnected(i) || !IsClientInGame(i) || GetEntProp(i, Prop_Send, "m_isIncapacitated"))
						continue;

					if(!CheckClientA(position, variable, i, client) && (i != victim))
						continue;

					GetClientEyePosition(i, variable);

					variable[0] = (position[0] - variable[0]);
					variable[1] = (position[1] - variable[1]);

					distance = SquareRoot(variable[0] * variable[0] + variable[1] * variable[1]);

					if(distance <= radius)
					{
						distance = 1.0 / distance;

						variable[0] = ((variable[0] * distance) * -1.0) * power[0];
						variable[1] = ((variable[1] * distance) * -1.0) * power[1];

						GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity);

						variable[0] += velocity[0];
						variable[1] += velocity[1];
						variable[2] = power[2];

						TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, variable);

						if(SDKCALL(Fling) != INVALID_HANDLE)
							SDKCall(SDKCALL(Fling), i, velocity, 76, victim, 1.0);
					}
				}
			}
		}
	}
}
public Action:EventHook_BoomerExplosion(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim	   = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:power  = GetConVarFloat(INFECTED(Earns_Explosion_Power));
	new Float:radius = GetConVarFloat(INFECTED(Earns_Explosion_Radius));

	if((power > 0.0) && victim && IsClientInGame(victim) && (GetClientTeam(victim) == T_INFECTED) && (GetInfectedClass(victim) == ZC_BOOMER))
	{
		decl Float:position[3];
		decl Float:variable[3];
		decl Float:velocity[3];

		decl Float:distance;

		GetClientEyePosition(victim, position);

		for(new i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && (GetClientTeam(i) == T_SURVIVOR) && !GetEntProp(i, Prop_Send, "m_isIncapacitated"))
			{
				GetClientEyePosition(i, variable);

				if(!CheckClientA(position, variable, i, victim))
					continue;

				variable[0] = (position[0] - variable[0]);
				variable[1] = (position[1] - variable[1]);

				distance = SquareRoot(variable[0] * variable[0] + variable[1] * variable[1]);

				if(distance <= radius)
				{
					distance = 1.0 / distance;

					variable[0] = ((variable[0] * distance) * -1.0) * power;
					variable[1] = ((variable[1] * distance) * -1.0) * power;

					GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity);

					variable[0] += velocity[0];
					variable[1] += velocity[1];
					variable[2] = power;

					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, variable);

					if(SDKCALL(Fling) != INVALID_HANDLE)
						SDKCall(SDKCALL(Fling), i, velocity, 76, victim, 3.0);
				}
			}
		}

		decl String:className[32];
		new MaxEntities = GetMaxEntities();

		if(GetConVarBool(INFECTED(Earns_Explosion_Physics)))
		{
			for(new i = MaxClients+1; i < MaxEntities; ++i)
			{
				if(IsValidEdict(i))
				{
					GetEdictClassname(i, className, sizeof(className));

					if(StrEqual(className, "prop_physics", false) || StrEqual(className, "prop_car_alarm"))
					{
						GetEntityAbsOrigin(i, variable);

						if(!CheckClientA(position, variable, i, victim))
							continue;

						variable[0] = (position[0] - variable[0]);
						variable[1] = (position[1] - variable[1]);

						distance = SquareRoot(variable[0] * variable[0] + variable[1] * variable[1]);

						if(distance <= radius)
						{
							distance = 1.0 / distance;

							variable[0] = ((variable[0] * distance) * -1.0) * power;
							variable[1] = ((variable[1] * distance) * -1.0) * power;

							GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity);

							variable[0] += velocity[0];
							variable[1] += velocity[1];
							variable[2] = power;

							TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, variable);
						}
					}
				}
			}
		}
	}
}

public Action:RemoveEntity(Handle:timer, any:entity)
{
	if(IsValidEdict(entity))
		RemoveEdict(entity);
}

public Action:EventHook_SlapPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(client && IsClientInGame(client))
	{
		if(Players[client][CanSlap] && victim && (GetClientTeam(victim) == T_SURVIVOR) && (GetInfectedClass(client) == ZC_BOOMER))
		{
			new Float:power = GetConVarFloat(INFECTED(Earns_SlapPower));

			if((power == 0.0) || GetEntProp(victim, Prop_Send, "m_isIncapacitated") || Players[victim][Carryied])
				return;

			decl String:weapon[256];
			GetEventString(event, "weapon", weapon, sizeof(weapon));

			if(StrEqual(weapon, "boomer_claw"))
			{
				EmitSoundToAll("player/survivor/hit/int/Punch_Boxing_FaceHit1.wav", victim, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);

				if(!IsFakeClient(victim))
				{
					Players[victim][GotSlap] = 1;
					CreateTimer(float(GetConVarInt(INFECTED(Earns_SlapTime))), ResetGotSlap);
				}
				if(!IsFakeClient(client))
				{
					EmitSoundToClient(victim, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav");
				}

				decl Float:eyeAngle[3];
				decl Float:velocity[3];

				GetClientEyeAngles(client, eyeAngle);

				eyeAngle[0] = Cosine(DegToRad(eyeAngle[1])) * power;
				eyeAngle[1] =   Sine(DegToRad(eyeAngle[1])) * power;

				eyeAngle[2]  = ((power > 196.0) ? 128.0 : power) * 0.75;

				GetEntPropVector(victim, Prop_Data, "m_vecVelocity", velocity);

				eyeAngle[0] += velocity[0];
				eyeAngle[1] += velocity[1];

				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, eyeAngle);

				if(SDKCALL(Fling) != INVALID_HANDLE)
					SDKCall(SDKCALL(Fling), victim, velocity, GetConVarInt(INFECTED(Earns_SlapAnimation)), client, 3.0);

				new earns = GetConVarInt(INFECTED(Earns_Slap));

				if(earns > 0)
				{
					Players[client][Points] += earns;
					CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}boomer slap{default}.", earns, ((earns == 1) ? "" : "s"));
				}

				if((power = GetConVarFloat(INFECTED(Earns_SlapCooldown))) > 0.0)
				{
					Players[client][CanSlap] = 0;
					CreateTimer(power, ResetCanSlap, client);
				}
			}
		}
	}
}
public Action:EventHook_SlapPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!client || !IsClientInGame(client))
		return;

	Players[client][CanSlap] = 1;
}

public Action:EventHook_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim && (GetClientTeam(victim) == T_SURVIVOR))
	{
		nextPlayerDeath = victim;
	}

	if(victim && IsClientInGame(victim) && !IsFakeClient(victim))
	{
		if(Players[victim][GodMode])
		{
			CPrintToChat(victim, "{olive}[SM]{default} The ability has been disabled.");
			Players[victim][GodMode] = 0;
			SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage_GodMode);
		}
		if(Players[victim][Speed])
		{
			Timer_StopSpeed(INVALID_HANDLE, victim);
		}
		if(Players[victim][Inv])
		{
			Timer_StopInvisibility(INVALID_HANDLE, victim);
		}
	}
	if(victim && (GetClientTeam(victim) == T_INFECTED) && (GetInfectedClass(victim) == ZC_TANK))
	{
		--TankCount;
		TankCount = (TankCount > 0) ? TankCount : 0;
	}
	else if(client && Players[victim][Carryied] && Players[victim][CarryOwner] && victim && (GetClientTeam(victim) == T_SURVIVOR))
	{
		if(GetClientTeam(Players[victim][CarryOwner]) == T_INFECTED)
		{
			new earns = GetConVarInt(INFECTED(Earns_InstantKill));

			if(earns > 0)
			{
				Players[client][Points] += earns;
				CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing a survivor{default}.", earns, ((earns == 1) ? "" : "s"));
			}
		}

		Players[victim][Carryied]   = 0;
		Players[victim][CarryOwner] = 0;
	}
	else if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		switch(GetClientTeam(client))
		{
		case T_INFECTED:
			{
				if(victim && (GetClientTeam(victim) == T_SURVIVOR))
				{
					new earns = GetConVarInt(INFECTED(Earns_InstantKill));

					if(earns > 0)
					{
						Players[client][Points] += earns;
						CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing a survivor{default}.", earns, ((earns == 1) ? "" : "s"));
					}
				}
			}
		case T_SURVIVOR:
			{
				if(victim && (GetClientTeam(victim) == T_INFECTED))
				{
					switch(GetInfectedClass(victim))
					{
					case ZC_BOOMER:
						{
							new earns = GetConVarInt(SURVIVOR(Earns_KillBoomer));

							if(earns > 0)
							{
								Players[client][Points] += earns;
								CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing a boomer{default}.", earns, ((earns == 1) ? "" : "s"));
							}
						}
					case ZC_CHARGER:
						{
							new earns = GetConVarInt(SURVIVOR(Earns_KillCharger));

							if(earns > 0)
							{
								Players[client][Points] += earns;
								CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing a charger{default}.", earns, ((earns == 1) ? "" : "s"));
							}
						}
					case ZC_HUNTER:
						{
							new earns = GetConVarInt(SURVIVOR(Earns_KillHunter));

							if(earns > 0)
							{
								Players[client][Points] += earns;
								CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing a hunter{default}.", earns, ((earns == 1) ? "" : "s"));
							}
						}
					case ZC_JOCKEY:
						{
							new earns = GetConVarInt(SURVIVOR(Earns_KillJockey));

							if(earns > 0)
							{
								Players[client][Points] += earns;
								CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing a jockey{default}.", earns, ((earns == 1) ? "" : "s"));
							}
						}
					case ZC_SMOKER:
						{
							new earns = GetConVarInt(SURVIVOR(Earns_KillSmoker));

							if(earns > 0)
							{
								Players[client][Points] += earns;
								CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing a smoker{default}.", earns, ((earns == 1) ? "" : "s"));
							}
						}
					case ZC_SPITTER:
						{
							new earns = GetConVarInt(SURVIVOR(Earns_KillSpitter));

							if(earns > 0)
							{
								Players[client][Points] += earns;
								CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing a spitter{default}.", earns, ((earns == 1) ? "" : "s"));
							}
						}
					case ZC_TANK:
						{
							new earns = GetConVarInt(SURVIVOR(Earns_KillTank));

							if(earns > 0)
							{
								Players[client][Points] += earns;
								CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing a tank{default}.", earns, ((earns == 1) ? "" : "s"));
							}
						}
					}
				}
				else
				{
					victim = GetEventInt(event, "entityid");

					decl String:className[6];
					GetEdictClassname(victim, className, sizeof(className));

					if(strcmp(className, "Witch", false) == 0)
					{
						--WitchCount;
						WitchCount = (WitchCount > 0) ? WitchCount : 0;

						new earns = GetConVarInt(SURVIVOR(Earns_KillWitch));

						if(earns > 0)
						{
							Players[client][Points] += earns;
							CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing a witch{default}.", earns, ((earns == 1) ? "" : "s"));
						}
					}
				}
			}
		}
	}
}
public Action:EventHook_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "dmg_health");
	new type   = GetEventInt(event, "type");

	if(type & 8)
	{
		return;
	}

	if(type & 128)
	{
		if(victim && Players[victim][AssistOwner] && IsClientInGame(Players[victim][AssistOwner]))
		{
			new earns   = GetConVarInt(INFECTED(Earns_BoomerAssist));
			new minimal = GetConVarInt(INFECTED(Earns_BoomerAssist_Damage));

			if(earns > 0)
			{
				if((Players[Players[victim][AssistOwner]][AssistDamage] += damage) >= minimal)
				{
					Players[Players[victim][AssistOwner]][Points] += earns;
					CPrintToChat(Players[victim][AssistOwner], "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}boomer assistance{default}.", earns, ((earns == 1) ? "" : "s"));
					Players[Players[victim][AssistOwner]][AssistDamage] = 0;
				}
			}
		}
	}

	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		switch(GetClientTeam(client))
		{
		case T_INFECTED:
			{
				switch(GetInfectedClass(client))
				{
				case ZC_TANK:
					{
						decl String:buffer[10];
						GetEventString(event, "weapon", buffer, sizeof(buffer));

						if(victim && GetClientTeam(victim) == T_SURVIVOR)
						{
							if(strcmp(buffer, "tank_rock") == 0)
							{
								new earns = GetConVarInt(INFECTED(Earns_TankRockHit));

								if(earns > 0)
								{
									Players[client][Points] += ++earns;
									CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}tank rock hit{default}.", earns, ((earns == 1) ? "" : "s"));
								}
							}
							else
							{
								new earns = GetConVarInt(INFECTED(Earns_TankHandHit));

								if(earns > 0 && !(type & (1<<30)))
								{
									Players[client][Points] += earns;
									CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}tank hit{default}.", earns, ((earns == 1) ? "" : "s"));
								}
							}
						}
					}

				case ZC_BOOMER:
					{
						new earns   = GetConVarInt(INFECTED(Earns_Hurt));
						new minimal = GetConVarInt(INFECTED(Earns_Hurt_Damage_Boomer));

						if(Players[client][Berserk])
						{
							new dmg = RoundFloat(damage * GetConVarFloat(hBerserk_Damage)) - damage;
							ApplyDamage(victim, dmg);
							damage += dmg;
						}

						if((earns > 0) && victim && (GetClientTeam(victim) == T_SURVIVOR))
						{
							if((Players[client][SurvivorDamage_Boomer] += damage) >= minimal)
							{
								while(Players[client][SurvivorDamage_Boomer] >= minimal)
								{
									Players[client][SurvivorDamage_Boomer] -= minimal;

									Players[client][Points] += earns;
									CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}boomer damage{default}.", earns, ((earns == 1) ? "" : "s"));

									if(Players[client][SurvivorDamage_Boomer] < 0)
										Players[client][SurvivorDamage_Boomer] = 0;
								}
							}
						}
					}
				case ZC_CHARGER:
					{
						new earns   = GetConVarInt(INFECTED(Earns_Hurt));
						new minimal = GetConVarInt(INFECTED(Earns_Hurt_Damage_Charger));

						if(Players[client][Berserk])
						{
							new dmg = RoundFloat(damage * GetConVarFloat(hBerserk_Damage)) - damage;
							ApplyDamage(victim, dmg);
							damage += dmg;
						}

						if((earns > 0) && victim && (GetClientTeam(victim) == T_SURVIVOR))
						{
							if((Players[client][SurvivorDamage_Charger] += damage) >= minimal)
							{
								while(Players[client][SurvivorDamage_Charger] >= minimal)
								{
									Players[client][SurvivorDamage_Charger] -= minimal;

									Players[client][Points] += earns;
									CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}charger damage{default}.", earns, ((earns == 1) ? "" : "s"));

									if(Players[client][SurvivorDamage_Charger] < 0)
										Players[client][SurvivorDamage_Charger] = 0;
								}
							}
						}
					}
				case ZC_HUNTER:
					{
						new earns   = GetConVarInt(INFECTED(Earns_Hurt));
						new minimal = GetConVarInt(INFECTED(Earns_Hurt_Damage_Hunter));

						if(Players[client][Berserk])
						{
							new dmg = RoundFloat(damage * GetConVarFloat(hBerserk_Damage)) - damage;
							ApplyDamage(victim, dmg);
							damage += dmg;
						}

						if((earns > 0) && victim && (GetClientTeam(victim) == T_SURVIVOR))
						{
							if((Players[client][SurvivorDamage_Hunter] += damage) >= minimal)
							{
								while(Players[client][SurvivorDamage_Hunter] >= minimal)
								{
									Players[client][SurvivorDamage_Hunter] -= minimal;

									Players[client][Points] += earns;
									CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}hunter damage{default}.", earns, ((earns == 1) ? "" : "s"));

									if(Players[client][SurvivorDamage_Hunter] < 0)
										Players[client][SurvivorDamage_Hunter] = 0;
								}
							}
						}
					}
				case ZC_JOCKEY:
					{
						new earns   = GetConVarInt(INFECTED(Earns_Hurt));
						new minimal = GetConVarInt(INFECTED(Earns_Hurt_Damage_Jockey));

						if(Players[client][Berserk])
						{
							new dmg = RoundFloat(damage * GetConVarFloat(hBerserk_Damage)) - damage;
							ApplyDamage(victim, dmg);
							damage += dmg;
						}

						if((earns > 0) && victim && (GetClientTeam(victim) == T_SURVIVOR))
						{
							if((Players[client][SurvivorDamage_Jockey] += damage) >= minimal)
							{
								while(Players[client][SurvivorDamage_Jockey] >= minimal)
								{
									Players[client][SurvivorDamage_Jockey] -= minimal;

									Players[client][Points] += earns;
									CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}jockey damage{default}.", earns, ((earns == 1) ? "" : "s"));

									if(Players[client][SurvivorDamage_Jockey] < 0)
										Players[client][SurvivorDamage_Jockey] = 0;
								}
							}
						}
					}
				case ZC_SMOKER:
					{
						new earns   = GetConVarInt(INFECTED(Earns_Hurt));
						new minimal = GetConVarInt(INFECTED(Earns_Hurt_Damage_Smoker));

						if(Players[client][Berserk])
						{
							new dmg = RoundFloat(damage * GetConVarFloat(hBerserk_Damage)) - damage;
							ApplyDamage(victim, dmg);
							damage += dmg;
						}

						if((earns > 0) && victim && (GetClientTeam(victim) == T_SURVIVOR))
						{
							if((Players[client][SurvivorDamage_Smoker] += damage) >= minimal)
							{
								while(Players[client][SurvivorDamage_Smoker] >= minimal)
								{
									Players[client][SurvivorDamage_Smoker] -= minimal;

									Players[client][Points] += earns;
									CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}smoker damage{default}.", earns, ((earns == 1) ? "" : "s"));

									if(Players[client][SurvivorDamage_Smoker] < 0)
										Players[client][SurvivorDamage_Smoker] = 0;
								}
							}
						}
					}
				case ZC_SPITTER:
					{
						new earns   = GetConVarInt(INFECTED(Earns_Hurt));
						new minimal = GetConVarInt(INFECTED(Earns_Hurt_Damage_Spitter));

						if(Players[client][Berserk])
						{
							new dmg = RoundFloat(damage * GetConVarFloat(hBerserk_Damage)) - damage;
							ApplyDamage(victim, dmg);
							damage += dmg;
						}

						if((earns > 0) && victim && (GetClientTeam(victim) == T_SURVIVOR))
						{
							if((Players[client][SurvivorDamage_Spitter] += damage) >= minimal)
							{
								while(Players[client][SurvivorDamage_Spitter] >= minimal)
								{
									Players[client][SurvivorDamage_Spitter] -= minimal;

									Players[client][Points] += earns;
									CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}spitter damage{default}.", earns, ((earns == 1) ? "" : "s"));

									if(Players[client][SurvivorDamage_Spitter] < 0)
										Players[client][SurvivorDamage_Spitter] = 0;
								}
							}
						}
					}
				}
			}
		case T_SURVIVOR:
			{
				if(victim && (GetInfectedClass(victim) == ZC_TANK))
				{
					new earns   = GetConVarInt(SURVIVOR(Earns_HurtTank));
					new minimal = GetConVarInt(SURVIVOR(Earns_HurtTank_Damage));

					if((Players[client][TankDamage] += damage) >= minimal)
					{
						Players[client][Points] += earns;
						CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}damaging a tank{default}.", earns, ((earns == 1) ? "" : "s"));		
						Players[client][TankDamage] = 0;
					}
				}
			}
		}
	}
}
public Action:EventHook_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client  = GetClientOfUserId(GetEventInt(event, "userid"));
	new newTeam = GetEventInt(event, "team");
	new oldTeam = GetEventInt(event, "oldteam");

	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(Players[client][GodMode])
		{
			CPrintToChat(client, "{olive}[SM]{default} The ability has been disabled.");
			Players[client][GodMode] = 0;
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage_GodMode);
		}
		if(Players[client][Speed])
		{
			Timer_StopSpeed(INVALID_HANDLE, client);
		}
		if(Players[client][Inv])
		{
			Timer_StopInvisibility(INVALID_HANDLE, client);
		}
	}
	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(oldTeam == T_INFECTED)
			SetPlayerGhostStatus(client, false);

		if((newTeam != T_SURVIVOR) && (newTeam != T_INFECTED))
		{
			Players[client][LastTeam] = oldTeam;
		}
		else if(Players[client][LastTeam] != newTeam)
		{
			if(GetConVarBool(hGlobal_Reset_AtTeamSwitch))
				ResetPlayer(client);

			Players[client][CanSlap]		= 0;
			Players[client][GotSlap]		= 0;
			Players[client][Carryied]	   = 0;
			Players[client][CarryOwner]	= 0;
		}
		else
		{
			Players[client][LastTeam] = newTeam;
		}
	}
}
public Action:EventHook_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(client && IsClientInGame(client) && (GetClientTeam(client) == T_INFECTED) && !IsFakeClient(client))
	{
		if(GetClientTeam(victim) == T_SURVIVOR)
		{
			new earns = GetConVarInt(INFECTED(Earns_Incapacitate));

			if(earns > 0)
			{
				Players[client][Points] += earns;
				CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}incapating a survivor{default}.", earns, ((earns == 1) ? "" : "s"));					
			}
		}
	}
}
public Action:EventHook_PlayerLedgeGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "causer"));

	if(client && IsClientInGame(client) && (GetClientTeam(client) == T_INFECTED) && !IsFakeClient(client))
	{
		if(GetClientTeam(victim) == T_SURVIVOR)
		{
			new earns = GetConVarInt(INFECTED(Earns_LedgeGrab));

			if(earns > 0)
			{
				Players[client][Points] += earns;
				CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}incapating a survivor{default}.", earns, ((earns == 1) ? "" : "s"));					
			}
		}
	}
}

public Action:EventHook_PlayerReplaceBot(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));

	if(client && (GetClientTeam(client) == T_INFECTED) && (GetInfectedClass(client) == ZC_TANK))
		SDKHookEx(client, SDKHook_OnTakeDamage, OnTankTakeDamage);
}
public Action:EventHook_BotReplacePlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTankTakeDamage);
}

public Action:EventHook_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(client && IsClientInGame(client) && (GetClientTeam(client) == T_SURVIVOR) && !IsFakeClient(client))
	{
		new earns = GetConVarInt(SURVIVOR(Earns_KillCommons));

		if(earns > 0)
		{
			if((++Players[client][CommonKills]) >= GetConVarInt(SURVIVOR(Earns_KillCommons_Minimal)))
			{
				Players[client][Points] += earns;
				CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing many common infected{default}.", earns, ((earns == 1) ? "" : "s"));									
				Players[client][CommonKills] = 0;
			}
		}
	}
}
public Action:EventHook_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetEventInt(event, "entityid");
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "amount");

	if(client && IsClientInGame(client) && (GetClientTeam(client) == T_SURVIVOR) && !IsFakeClient(client))
	{
		decl String:className[6];
		GetEntityNetClass(victim, className, sizeof(className));

		if(strncmp("Witch", className, 5) == 0)
		{
			new earns = GetConVarInt(SURVIVOR(Earns_HurtWitch));

			if(earns > 0)
			{
				if((Players[client][WitchDamage] += damage) >= GetConVarInt(SURVIVOR(Earns_HurtWitch_Damage)))
				{
					CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}damaging a witch{default}.", earns, ((earns == 1) ? "" : "s"));
					Players[client][Points] += earns;		
					Players[client][WitchDamage] = 0;
				}
			}
		}
	}
}

public Action:EventHook_DefibrillatorUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client && IsClientInGame(client) && !IsFakeClient(client) && !IsFakeClient(client))
	{
		new earns = GetConVarInt(SURVIVOR(Earns_ReviveFriend));

		if(earns > 0)
		{
			CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}reviving a friend{default}.", earns, ((earns == 1) ? "" : "s"));
			Players[client][Points] += earns;
		}
	}
}
public Action:EventHook_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && IsClientInGame(client) && !IsFakeClient(client) && !IsFakeClient(client) && (subject != client))
	{
		new earns = GetConVarInt(SURVIVOR(Earns_HealFriend));

		if(earns > 0)
		{
			CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}healing a friend{default}.", earns, ((earns == 1) ? "" : "s"));
			Players[client][Points] += earns;
		}
	}
}
public Action:EventHook_RevievSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new wasLedge = GetEventInt(event, "ledge_hang");

	if(client && IsClientInGame(client) && !IsFakeClient(client) && !IsFakeClient(client) && (subject != client))
	{
		if(wasLedge)
		{
			new earns = GetConVarInt(SURVIVOR(Earns_PickupFriendLedge));

			if(earns > 0)
			{
				CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}picing up a friend from ledge{default}.", earns, ((earns == 1) ? "" : "s"));
				Players[client][Points] += earns;
			}
		}
		else
		{
			new earns = GetConVarInt(SURVIVOR(Earns_PickupFriend));

			if(earns > 0)
			{
				CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}picing up a friend{default}.", earns, ((earns == 1) ? "" : "s"));
				Players[client][Points] += earns;
			}
		}
	}
}

public Action:EventHook_PlayerNoLongerIt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	Players[client][AssistOwner] = 0;
}
public Action:EventHook_PlayerNowIt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(GetEventBool(event, "by_boomer") && client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new earns = GetConVarInt(INFECTED(Earns_Vomit));

		if(earns > 0)
		{
			CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}vomiting on a survivor{default}.", earns, ((earns == 1) ? "" : "s"));
			Players[client][Points] += earns;
		}

		Players[victim][AssistOwner] = client;
	}
}

public Action:EventHook_ChargerCarryStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		Players[victim][Carryied]   = 1;
		Players[victim][CarryOwner] = client;

		new earns = GetConVarInt(INFECTED(Earns_ChargeCarry));

		if(earns > 0)
		{
			Players[client][Points] += earns;
			CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}carrying a survivor{default}.", earns, ((earns == 1) ? "" : "s"));
		}
	}
}
public Action:EventHook_ChargerCarryEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	Players[victim][Carryied]   = 1;
	Players[victim][CarryOwner] = 0;
}
public Action:EventHook_ChargerImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new earns = GetConVarInt(INFECTED(Earns_ChargeImpact));

		if(earns > 0)
		{
			Players[client][Points] += earns;
			CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}impacting with a survivor{default}.", earns, ((earns == 1) ? "" : "s"));
		}
	}
}

public Action:EventHook_LungePounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new distance = GetEventInt(event, "distance");

	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new earns = GetConVarInt(INFECTED(Earns_Pounce));

		if(earns > 0)
		{
			earns *= CalculateLevelOfDamage(distance);
			Players[client][Points] += earns;
			CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}pouncing a survivor{default}.", earns, ((earns == 1) ? "" : "s"));
		}
	}
}
public Action:EventHook_JockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new earns = GetConVarInt(INFECTED(Earns_Ride));

		if(earns > 0)
		{
			Players[client][Points] += earns;
			CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}riding a survivor{default}.", earns, ((earns == 1) ? "" : "s"));
		}
	}
}
public Action:EventHook_TongueGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new earns = GetConVarInt(INFECTED(Earns_TongueGrab));

		if(earns > 0)
		{
			Players[client][Points] += earns;
			CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}tongue grabbing a survivor{default}.", earns, ((earns == 1) ? "" : "s"));
		}
	}
}

public Action:EventHook_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	--TankCount;
}
public Action:EventHook_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	--WitchCount;
}

public Action:EventHook_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entity = GetEventInt(event, "tankid");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && IsClientConnected(client) && IsClientInGame(client))
	{
		
		SetPlayerGhostStatus(client, false);
		SetPlayerLifeState(client, LIFESTATE_ALIVE);

		new hp = GetConVarInt(FindConVar("z_tank_health"));

		if(hp == 0)
			hp = 9000;

		SetEntProp(client, Prop_Send, "m_iHealth", hp);
	}

	SetEntProp(entity, Prop_Data, "m_iHealth", 9000);
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", 9000);
		
	SetEntityModel(entity, "models/infected/hulk_dlc3.mdl");

	SDKHookEx(entity, SDKHook_OnTakeDamage, OnTankTakeDamage);
	SDKHookEx(entity, SDKHook_OnTakeDamage, OnTankTakeDamage);

	++TankCount;
	++TankTeamCount;
}
public Action:EventHook_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( NextWitchIsBride )
	{
		new entity = GetEventInt(event, "witchid");
		
		EmitSoundToAll("music/witch/witchencroacher_bride.wav");
		SetEntityModel(entity, "models/infected/witch_bride.mdl");

		SetEntProp(entity, Prop_Data, "m_iHealth", 10000);
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", 10000);

		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0xFFFF7878);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", 2048);
	
		CPrintToChatAll("{olive}[SM]{default} The {olive}Bride Witch{default} has been spawned! Watch out! She is much more dangerous then a common witch.");
		
		for ( new i = 1; i <= MaxClients; ++i)
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2)
				SDKCall(Witch_SetHarasser, entity, i);
		
		SDKHookEx(entity, SDKHook_OnTakeDamage, OnBrideTakeDamage);
		
		NextWitchIsBride = 0;
	}

	++WitchCount;
	++WitchTeamCount;
}

public Action:OnBrideTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType)
{
	damageType = DMG_GENERIC;
	
	if ( damage > 50 )
		damage = 50;
		
	SetEntProp(victim, Prop_Send, "m_iGlowType", 3);
	SetEntProp(victim, Prop_Send, "m_glowColorOverride", 0xFF007878);
	SetEntProp(victim, Prop_Send, "m_nGlowRange", 2048);
	
	CreateTimer(0.33, BackToNormal, victim);
}

public Action:BackToNormal(Handle:t, any:entity)
{
	if (IsValidEdict(entity))
	{
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0xFFFF7878);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", 2048);
	}
	else
	{	
		SDKUnhook(entity, SDKHook_OnTakeDamage, OnBrideTakeDamage);
	}
}

public Action:EventHook_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isSlow)
	{
		Timer_StopSlow(INVALID_HANDLE, 0);
		isSlow = false;
	}
	if(GetConVarBool(hGlobal_Reset_AtRoundEnd))
	{
		for(new i = 1; i <= MaxClients; ++i)
			ResetPlayer(i);
	}

	for(new i = 1; i <= MaxClients; ++i)
	{
		Players[i][CanSlap]		= 1;
		Players[i][GotSlap]		= 0;
		Players[i][Carryied]	   = 0;
		Players[i][CarryOwner]	 = 0;
	}

	TankCount  = TankTeamCount  = 0;
	WitchCount = WitchTeamCount = 0;

	RemainingZombies = 0;
}

public InfectedMainMenu(client)
{
	new Handle:menu = CreateMenu(MainMenuHandler);

	decl String:buffer[96];

	Format(buffer, sizeof(buffer), "You have %d point%s", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	AddMenuItem(menu, "", "Items");
	AddMenuItem(menu, "", "Become");
	AddMenuItem(menu, "", "Spawn");
	AddMenuItem(menu, "", "Spawn for");
	AddMenuItem(menu, "", "Squads");
	AddMenuItem(menu, "", "Abilities");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}
public SurvivorMainMenu(client)
{
	new Handle:menu = CreateMenu(MainMenuHandler);

	decl String:buffer[96];

	Format(buffer, sizeof(buffer), "You have %d point%s", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	AddMenuItem(menu, "", "Equipment");
	AddMenuItem(menu, "", "Weapons");
	AddMenuItem(menu, "", "Melee");
	AddMenuItem(menu, "", "Items");
	AddMenuItem(menu, "", "Group Items");
	AddMenuItem(menu, "", "Abilities");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}

public InfectedSubMenu1(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	price = GetConVarInt(INFECTED(Price_Healing));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Healing (0) - %d", price);
		AddMenuItem(menu, "0", buffer);
	}

	price = GetConVarInt(INFECTED(Price_Suicide));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Suicide (1) - %d", price);
		AddMenuItem(menu, "1", buffer);
	}

	switch(GetInfectedClass(client))
	{
	case ZC_BOOMER:
		price = GetConVarInt(INFECTED(Price_ResetAbility_Boom));
	case ZC_CHARGER:
		price = GetConVarInt(INFECTED(Price_ResetAbility_Char));
	case ZC_HUNTER:
		price = GetConVarInt(INFECTED(Price_ResetAbility_Hunt));
	case ZC_JOCKEY:
		price = GetConVarInt(INFECTED(Price_ResetAbility_Jock));
	case ZC_SMOKER:
		price = GetConVarInt(INFECTED(Price_ResetAbility_Smok));
	case ZC_SPITTER:
		price = GetConVarInt(INFECTED(Price_ResetAbility_Spit));
	case ZC_TANK:
		price = GetConVarInt(INFECTED(Price_ResetAbility_Tank));
	}

	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Reload Ability (25) - %d", price);
		AddMenuItem(menu, "25", buffer);
	}

	price = GetConVarInt(INFECTED(Price_Extinguish));

	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Extinguish (28) - %d", price);
		AddMenuItem(menu, "28", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnDumpster));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Spawn Dumpster (26) - %d", price);
		AddMenuItem(menu, "26", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnCar));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Spawn Car (27) - %d", price);
		AddMenuItem(menu, "27", buffer);
	}

	price = GetConVarInt(INFECTED(Price_Random));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Random item (50) - %d", price);
		AddMenuItem(menu, "50", buffer);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}
public InfectedSubMenu2(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	price = GetConVarInt(INFECTED(Price_SpawnSelfBoomer));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Boomer (2) - %d", price);
		AddMenuItem(menu, "2", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfCharger));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Charger (3) - %d", price);
		AddMenuItem(menu, "3", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfJockey));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Hunter (4) - %d", price);
		AddMenuItem(menu, "4", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfHunter));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Jockey (5) - %d", price);
		AddMenuItem(menu, "5", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfSmoker));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Smoker (6) - %d", price);
		AddMenuItem(menu, "6", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfSpitter));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Spitter (7) - %d", price);
		AddMenuItem(menu, "7", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfTank));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Tank (8) - %d", price);
		AddMenuItem(menu, "8", buffer);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}
public InfectedSubMenu3(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	price = GetConVarInt(INFECTED(Price_SpawnBoomer));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Boomer (9) - %d", price);
		AddMenuItem(menu, "9", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnCharger));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Charger (10) - %d", price);
		AddMenuItem(menu, "10", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnHunter));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Hunter (11) - %d", price);
		AddMenuItem(menu, "11", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnJockey));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Jockey (12) - %d", price);
		AddMenuItem(menu, "12", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSmoker));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Smoker (13) - %d", price);
		AddMenuItem(menu, "13", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSpitter));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Spitter (14) - %d", price);
		AddMenuItem(menu, "14", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnTank));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Tank (15) - %d", price);
		AddMenuItem(menu, "15", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnWitch));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Witch (16) - %d", price);
		AddMenuItem(menu, "16", buffer);
	}
	
	price = GetConVarInt(INFECTED(Price_SpawnWitchBride));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Witch Bride (47) - %d", price);
		AddMenuItem(menu, "47", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnMob));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Mob (17) - %d", price);
		AddMenuItem(menu, "17", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnMegaMob));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Mega Mob (18) - %d", price);
		AddMenuItem(menu, "18", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnCeda));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Ceda Horde (19) - %d", price);
		AddMenuItem(menu, "19", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnClown));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Clown Horde (20) - %d", price);
		AddMenuItem(menu, "20", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnMud));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Mud Horde (21) - %d", price);
		AddMenuItem(menu, "21", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnWorker));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Worker Horde (22) - %d", price);
		AddMenuItem(menu, "22", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnRiot));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Riot Horde (23) - %d", price);
		AddMenuItem(menu, "23", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnJimmy));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Jimmy Horde (24) - %d", price);
		AddMenuItem(menu, "24", buffer);
	}
	
	price = GetConVarInt(INFECTED(Price_SpawnFa));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "Fallen Survivor Horde (46) - %d", price);
		AddMenuItem(menu, "46", buffer);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}

public InfectedSubMenu4(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	price = GetConVarInt(INFECTED(Price_SpawnSelfBoomer));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Boomer (32) - %d", price);
		AddMenuItem(menu, "32", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfCharger));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Charger (33) - %d", price);
		AddMenuItem(menu, "33", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfJockey));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Hunter (34) - %d", price);
		AddMenuItem(menu, "34", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfHunter));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Jockey (35) - %d", price);
		AddMenuItem(menu, "35", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfSmoker));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Smoker (36) - %d", price);
		AddMenuItem(menu, "36", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfSpitter));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Spitter (37) - %d", price);
		AddMenuItem(menu, "37", buffer);
	}

	price = GetConVarInt(INFECTED(Price_SpawnSelfTank));
	if(price >= 0)
	{
		if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
		{
			price += GetConVarInt(INFECTED(Price_Suicide));
		}

		Format(buffer, sizeof(buffer), "Tank (38) - %d", price);
		AddMenuItem(menu, "38", buffer);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}
public InfectedSubMenu5(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	price = GetConVarInt(INFECTED(Price_God));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "%ds God Mode (29) - %d", GetConVarInt(INFECTED(Price_GodInterval)), price);
		AddMenuItem(menu, "29", buffer);
	}

	price = GetConVarInt(INFECTED(Price_Speed));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "%ds Super-Speed (30) - %d", GetConVarInt(INFECTED(Price_SpeedInterval)), price);
		AddMenuItem(menu, "30", buffer);
	}

	price = GetConVarInt(INFECTED(Price_Invisibility));
	if(price >= 0)
	{
		Format(buffer, sizeof(buffer), "%ds Invisibility (31) - %d", GetConVarInt(INFECTED(Price_InvisibilityInterval)), price);
		AddMenuItem(menu, "31", buffer);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}
public InfectedSubMenu6(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	price = GetConVarInt(INFECTED(Price_SquadBoomerOne));
	if(price >= 0)
	{
		new cnt = 0;
		
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
			{
				cnt++;
			}
		}
		
		if (cnt <= 1)
			price = GetConVarInt(INFECTED(Price_SpawnBoomer));
		else if (cnt == 0)
			price = 0;
		else
			price *= cnt;
		
		Format(buffer, sizeof(buffer), "%d Boomer%s (39) - %d", cnt, (cnt == 1) ? "" : "s", price);
		AddMenuItem(menu, "39", buffer);
	}
	
	price = GetConVarInt(INFECTED(Price_SquadChargerOne));
	if(price >= 0)
	{
		new cnt = 0;
		
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
			{
				cnt++;
			}
		}
		
		if (cnt <= 1)
			price = GetConVarInt(INFECTED(Price_SpawnCharger));
		else if (cnt == 0)
			price = 0;
		else
			price *= cnt;
		
		Format(buffer, sizeof(buffer), "%d Charger%s (40) - %d", cnt, (cnt == 1) ? "" : "s", price);
		AddMenuItem(menu, "40", buffer);
	}
	
	price = GetConVarInt(INFECTED(Price_SquadHunterOne));
	if(price >= 0)
	{
		new cnt = 0;
		
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
			{
				cnt++;
			}
		}
		
		if (cnt <= 1)
			price = GetConVarInt(INFECTED(Price_SpawnHunter));
		else if (cnt == 0)
			price = 0;
		else
			price *= cnt;
		
		Format(buffer, sizeof(buffer), "%d Hunter%s (41) - %d", cnt, (cnt == 1) ? "" : "s", price);
		AddMenuItem(menu, "41", buffer);
	}
	
	price = GetConVarInt(INFECTED(Price_SquadJockeyOne));
	if(price >= 0)
	{
		new cnt = 0;
		
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
			{
				cnt++;
			}
		}
		
		if (cnt <= 1)
			price = GetConVarInt(INFECTED(Price_SpawnJockey));
		else if (cnt == 0)
			price = 0;
		else
			price *= cnt;
		
		Format(buffer, sizeof(buffer), "%d Jockey%s (42) - %d", cnt, (cnt == 1) ? "" : "s", price);
		AddMenuItem(menu, "42", buffer);
	}
	
	price = GetConVarInt(INFECTED(Price_SquadSmokerOne));
	if(price >= 0)
	{
		new cnt = 0;
		
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
			{
				cnt++;
			}
		}
		
		if (cnt <= 1)
			price = GetConVarInt(INFECTED(Price_SpawnSmoker));
		else if (cnt == 0)
			price = 0;
		else
			price *= cnt;
		
		Format(buffer, sizeof(buffer), "%d Smoker%s (43) - %d", cnt, (cnt == 1) ? "" : "s", price);
		AddMenuItem(menu, "43", buffer);
	}
	
	price = GetConVarInt(INFECTED(Price_SquadSpitterOne));
	if(price >= 0)
	{
		new cnt = 0;
		
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
			{
				cnt++;
			}
		}
		
		if (cnt <= 1)
			price = GetConVarInt(INFECTED(Price_SpawnSpitter));
		else if (cnt == 0)
			price = 0;
		else
			price *= cnt;
		
		Format(buffer, sizeof(buffer), "%d Spitter%s (43) - %d", cnt, (cnt == 1) ? "" : "s", price);
		AddMenuItem(menu, "43", buffer);
	}
	
	price = GetConVarInt(INFECTED(Price_SquadTankOne));
	if(price >= 0)
	{
		new cnt = 0;
		
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
			{
				cnt++;
			}
		}
		
		if (cnt <= 1)
			price = GetConVarInt(INFECTED(Price_SpawnTank));
		else if (cnt == 0)
			price = 0;
		else
			price *= cnt;
		
		Format(buffer, sizeof(buffer), "%d Tank%s (44) - %d", cnt, (cnt == 1) ? "" : "s", price);
		AddMenuItem(menu, "45", buffer);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}

public SurvivorSubMenu1(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	price = GetConVarInt(SURVIVOR(Price_SelfHealing));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Healing (0) - %d", price);
		AddMenuItem(menu, "0", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_SelfHealing_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Healing (0) - %d", price);
		AddMenuItem(menu, "0", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_GroupHealing));
	if((price > 0) || (price == -2))
	{
		if(price == -2)
		{
			price = GetConVarInt(SURVIVOR(Price_GroupHealingValue));

			new newPrice = 0;

			for(new i = 1; i <= MaxClients; ++i)
				if(IsClientInGame(i) && (GetClientTeam(i) == T_SURVIVOR) && IsPlayerAlive(i))
					newPrice += price;

			price = newPrice;

			new selfPrice = GetConVarInt(SURVIVOR(Price_SelfHealing));
			price = ((price > selfPrice) ? price : selfPrice);
		}
		
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Group Healing (1) - %d", price);
		AddMenuItem(menu, "1", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_GroupHealing_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Group Healing (1) - %d", price);
		AddMenuItem(menu, "1", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_SelfRes));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Resurrection (51) - %d", price);
		AddMenuItem(menu, "51", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_SelfRes_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Resurrection (51) - %d", price);
		AddMenuItem(menu, "51", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_GroupRes));
	if((price > 0) || (price == -2))
	{
		if(price == -2)
		{
			price = GetConVarInt(SURVIVOR(Price_GroupResValue));

			new newPrice = 0;

			for(new i = 1; i <= MaxClients; ++i)
				if(IsClientInGame(i) && (GetClientTeam(i) == T_SURVIVOR) && !IsPlayerAlive(i))
					newPrice += price;

			price = newPrice;
		}
		
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Group Resurrection (52) - %d", price);
		AddMenuItem(menu, "52", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_GroupRes_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Group Resurrection (52) - %d", price);
		AddMenuItem(menu, "52", buffer);
			}
		}
		
	}
	
	price = GetConVarInt(SURVIVOR(Price_Adrenaline));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
			Format(buffer, sizeof(buffer), "Adrenaline (6) - %d", price);
			AddMenuItem(menu, "6", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Adrenaline_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Adrenaline (6) - %d", price);
				AddMenuItem(menu, "6", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_PainPills));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Pain Pills (7) - %d", price);
		AddMenuItem(menu, "7", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_PainPills_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Pain Pills (7) - %d", price);
		AddMenuItem(menu, "7", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_FirstAidkit));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "First Aid Kit (8) - %d", price);
		AddMenuItem(menu, "8", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_FirstAidkit_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "First Aid Kit (8) - %d", price);
		AddMenuItem(menu, "8", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_Defibrillator));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Defibrillator (9) - %d", price);
		AddMenuItem(menu, "9", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Defibrillator_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Defibrillator (9) - %d", price);
		AddMenuItem(menu, "9", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_Suicide));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Suicide (44) - %d", price);
		AddMenuItem(menu, "44", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Suicide_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Suicide (44) - %d", price);
		AddMenuItem(menu, "44", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_BileBomb));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Bile Bomb (10) - %d", price);
		AddMenuItem(menu, "10", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_BileBomb_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Bile Bomb (10) - %d", price);
		AddMenuItem(menu, "10", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_PipeBomb));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Pipe Bomb (11) - %d", price);
		AddMenuItem(menu, "11", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_PipeBomb_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Pipe Bomb (11) - %d", price);
		AddMenuItem(menu, "11", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_Molotov));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Molotov (12) - %d", price);
		AddMenuItem(menu, "12", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Molotov_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Molotov (12) - %d", price);
		AddMenuItem(menu, "12", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_Ammo));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Ammo (2) - %d", price);
		AddMenuItem(menu, "2", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Ammo_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Ammo (2) - %d", price);
		AddMenuItem(menu, "2", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_AmmoPile));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Ammo Pile (43) - %d", price);
		AddMenuItem(menu, "43", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_AmmoPile_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Ammo Pile (43) - %d", price);
		AddMenuItem(menu, "43", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_IncendiaryAmmo));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Incendiary Ammo (4) - %d", price);
		AddMenuItem(menu, "4", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_IncendiaryAmmo_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Incendiary Ammo (4) - %d", price);
		AddMenuItem(menu, "4", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_ExplosiveAmmo));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Explosive Ammo (5) - %d", price);
		AddMenuItem(menu, "5", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_ExplosiveAmmo_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Explosive Ammo (5) - %d", price);
		AddMenuItem(menu, "5", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_LaserSight));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
			Format(buffer, sizeof(buffer), "Laser Sight (3) - %d", price);
			AddMenuItem(menu, "3", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_LaserSight_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Laser Sight (3) - %d", price);
				AddMenuItem(menu, "3", buffer);
			}
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}
public SurvivorSubMenu2(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	price = GetConVarInt(SURVIVOR(Price_Pistol));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Pistol (13) - %d", price);
		AddMenuItem(menu, "13", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Pistol_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Pistol (13) - %d", price);
		AddMenuItem(menu, "13", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_MagnumPistol));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Magnum (14) - %d", price);
		AddMenuItem(menu, "14", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_MagnumPistol_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Magnum (14) - %d", price);
		AddMenuItem(menu, "14", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_ChromeShotgun));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Chrome Shotgun (15) - %d", price);
		AddMenuItem(menu, "15", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_ChromeShotgun_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Chrome Shotgun (15) - %d", price);
		AddMenuItem(menu, "15", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_PumpShotgun));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Pump Shotgun (16) - %d", price);
		AddMenuItem(menu, "16", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_PumpShotgun_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Pump Shotgun (16) - %d", price);
		AddMenuItem(menu, "16", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_AutoShotgun));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Auto Shotgun (17) - %d", price);
		AddMenuItem(menu, "17", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_AutoShotgun_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Auto Shotgun (17) - %d", price);
		AddMenuItem(menu, "17", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_SpasShotgun));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Spas Shotgun (18) - %d", price);
		AddMenuItem(menu, "18", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_SpasShotgun_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Spas Shotgun (18) - %d", price);
		AddMenuItem(menu, "18", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Smg));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "SMG (19) - %d", price);
		AddMenuItem(menu, "19", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Smg_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "SMG (19) - %d", price);
		AddMenuItem(menu, "19", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Silent_Smg));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Silent SMG (20) - %d", price);
		AddMenuItem(menu, "20", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Silent_Smg_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Silent SMG (20) - %d", price);
		AddMenuItem(menu, "20", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_CombatRifle));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Combat Rifle (21) - %d", price);
		AddMenuItem(menu, "21", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_CombatRifle_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Combat Rifle (21) - %d", price);
		AddMenuItem(menu, "21", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Ak47Rifle));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Ak47 Rifle (22) - %d", price);
		AddMenuItem(menu, "22", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Ak47Rifle_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Ak47 Rifle (22) - %d", price);
		AddMenuItem(menu, "22", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_DesertRifle));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Desert Rifle (23) - %d", price);
		AddMenuItem(menu, "23", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_DesertRifle_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Desert Rifle (23) - %d", price);
		AddMenuItem(menu, "23", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_HuntingRifle));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Hunting Rifle (24) - %d", price);
		AddMenuItem(menu, "24", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_HuntingRifle_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Hunting Rifle (24) - %d", price);
		AddMenuItem(menu, "24", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_SniperRifle));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Snpier Rifle (25) - %d", price);
		AddMenuItem(menu, "25", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_SniperRifle_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Snpier Rifle (25) - %d", price);
		AddMenuItem(menu, "25", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_GrenadeLauncher));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Grenade Launcher (26) - %d", price);
		AddMenuItem(menu, "26", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_GrenadeLauncher_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Grenade Launcher (26) - %d", price);
		AddMenuItem(menu, "26", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_M60HeavyRifle));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "M60 Heavy Rifle (27) - %d", price);
		AddMenuItem(menu, "27", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_M60HeavyRifle_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "M60 Heavy Rifle (27) - %d", price);
		AddMenuItem(menu, "27", buffer);
			}
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}
public SurvivorSubMenu3(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	price = GetConVarInt(SURVIVOR(Price_GolfClub));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Golf Club (28) - %d", price);
		AddMenuItem(menu, "28", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_GolfClub_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Golf Club (28) - %d", price);
		AddMenuItem(menu, "28", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_FireAxe));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Fire Axe (29) - %d", price);
		AddMenuItem(menu, "29", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_FireAxe_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Fire Axe (29) - %d", price);
		AddMenuItem(menu, "29", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Katana));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Katana (30) - %d", price);
		AddMenuItem(menu, "30", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Katana_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Katana (30) - %d", price);
		AddMenuItem(menu, "30", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Crowbar));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Crowbar (31) - %d", price);
		AddMenuItem(menu, "31", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Crowbar_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Crowbar (31) - %d", price);
		AddMenuItem(menu, "31", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_FryingPan));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Frying Pan (32) - %d", price);
		AddMenuItem(menu, "32", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_FryingPan_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Frying Pan (32) - %d", price);
		AddMenuItem(menu, "32", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Guitar));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Electric Guitar (33) - %d", price);
		AddMenuItem(menu, "33", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Guitar_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Electric Guitar (33) - %d", price);
		AddMenuItem(menu, "33", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_BaseballBat));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Baseball Bat (34) - %d", price);
		AddMenuItem(menu, "34", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_BaseballBat_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Baseball Bat (34) - %d", price);
		AddMenuItem(menu, "34", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Machete));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Machete (35) - %d", price);
		AddMenuItem(menu, "35", buffer);
	}

		else
		{
			if (GetConVarInt(SURVIVOR(Price_Machete_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Machete (35) - %d", price);
		AddMenuItem(menu, "35", buffer);
		}
		}
	}
	
	price = GetConVarInt(SURVIVOR(Price_Chainsaw));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Chainsaw (36) - %d", price);
		AddMenuItem(menu, "36", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Chainsaw_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Chainsaw (36) - %d", price);
		AddMenuItem(menu, "36", buffer);
	}
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}
public SurvivorSubMenu4(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	price = GetConVarInt(SURVIVOR(Price_Barrel));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Explosive Barrel (48) - %d", price);
		AddMenuItem(menu, "48", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Barrel_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Explosive Barrel (48) - %d", price);
		AddMenuItem(menu, "48", buffer);
	}
		}
	}
	
	price = GetConVarInt(SURVIVOR(Price_Oxygentank));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Oxygen Tank (37) - %d", price);
		AddMenuItem(menu, "37", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Oxygentank_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Oxygen Tank (37) - %d", price);
		AddMenuItem(menu, "37", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Propanetank));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Propane Tank (38) - %d", price);
		AddMenuItem(menu, "38", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Propanetank_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Propane Tank (38) - %d", price);
		AddMenuItem(menu, "38", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Gascan));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Gas Can (39) - %d", price);
		AddMenuItem(menu, "39", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Gascan_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Gas Can (39) - %d", price);
		AddMenuItem(menu, "39", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_FireworksCrate));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Fireworks Crate (40) - %d", price);
		AddMenuItem(menu, "40", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_FireworksCrate_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Fireworks Crate (40) - %d", price);
		AddMenuItem(menu, "40", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_IncendiaryAmmoPack));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Incendiary Ammo Pack (41) - %d", price);
		AddMenuItem(menu, "41", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_IncendiaryAmmoPack_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Incendiary Ammo Pack (41) - %d", price);
		AddMenuItem(menu, "41", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_ExplosiveAmmoPack));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Explosive Ammo Pack (42) - %d", price);
		AddMenuItem(menu, "42", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_ExplosiveAmmoPack_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Explosive Ammo Pack (42) - %d", price);
		AddMenuItem(menu, "42", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Random));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Random item (50) - %d", price);
		AddMenuItem(menu, "50", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Random_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "Random item (50) - %d", price);
		AddMenuItem(menu, "50", buffer);
	}
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}
public SurvivorSubMenu5(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);

	price = GetConVarInt(SURVIVOR(Price_God));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "%ds God Mode (45) - %d", GetConVarInt(SURVIVOR(Price_GodInterval)), price);
		AddMenuItem(menu, "45", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_God_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "%ds God Mode (45) - %d", GetConVarInt(SURVIVOR(Price_GodInterval)), price);
		AddMenuItem(menu, "45", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Speed));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "%ds Super-Speed (46) - %d", GetConVarInt(SURVIVOR(Price_SpeedInterval)), price);
		AddMenuItem(menu, "46", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Speed_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "%ds Super-Speed (46) - %d", GetConVarInt(SURVIVOR(Price_SpeedInterval)), price);
		AddMenuItem(menu, "46", buffer);
	}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_Slow));
	if(price >= 0)
	{
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "%ds Slow Motion (47) - %d", GetConVarInt(SURVIVOR(Price_SlowInterval)), price);
		AddMenuItem(menu, "47", buffer);
	}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Slow_Dead)) == 1)
			{
		Format(buffer, sizeof(buffer), "%ds Slow Motion (47) - %d", GetConVarInt(SURVIVOR(Price_SlowInterval)), price);
		AddMenuItem(menu, "47", buffer);
	}
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}
public SurvivorSubMenu6(client)
{
	new Handle:menu = CreateMenu(SubMenuHandler);

	decl String:buffer[96];
	decl price;

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);
	

	price = GetConVarInt(SURVIVOR(Price_GroupAmmo));
	if(price >= 0)
	{
			new j = 0;
			decl i;
			for (i = 1; i <= MaxClients; ++i)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				++j;
			}
			price = price * j;
			
		if (IsPlayerAlive(client))
		{
			Format(buffer, sizeof(buffer), "Group Ammo (53) - %d", price);
			AddMenuItem(menu, "53", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Ammo_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Group Ammo (53) - %d", price);
				AddMenuItem(menu, "53", buffer);
			}
		}
		
	}
	
	price = GetConVarInt(SURVIVOR(Price_GroupIncendiaryAmmo));
	if(price >= 0)
	{
			new j = 0;
			decl i;
			for (i = 1; i <= MaxClients; ++i)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				++j;
			}
			price = price * j;
			
		if (IsPlayerAlive(client))
		{
			Format(buffer, sizeof(buffer), "Group Incendiary Ammo (54) - %d", price);
			AddMenuItem(menu, "55", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_IncendiaryAmmo_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Group Incendiary Ammo (54) - %d", price);
				AddMenuItem(menu, "55", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_GroupExplosiveAmmo));
	if(price >= 0)
	{
			new j = 0;
			decl i;
			for (i = 1; i <= MaxClients; ++i)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				++j;
			}
			price = price * j;
			
		if (IsPlayerAlive(client))
		{
			Format(buffer, sizeof(buffer), "Group Explosive Ammo (55) - %d", price);
			AddMenuItem(menu, "56", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_ExplosiveAmmo_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Group Explosive Ammo (55) - %d", price);
				AddMenuItem(menu, "56", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_GroupLaserSight));
	if(price >= 0)
	{
			new j = 0;
			decl i;
			for (i = 1; i <= MaxClients; ++i)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				++j;
			}
			price = price * j;
			
		if (IsPlayerAlive(client))
		{
			Format(buffer, sizeof(buffer), "Group Laser Sight (54) - %d", price);
			AddMenuItem(menu, "54", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_LaserSight_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Group Laser Sight (54) - %d", price);
				AddMenuItem(menu, "54", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_GroupAdrenaline));
	if(price >= 0)
	{
			new j = 0;
			decl i;
			for (i = 1; i <= MaxClients; ++i)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				++j;
			}
			price = price * j;
			
		if (IsPlayerAlive(client))
		{
			
			Format(buffer, sizeof(buffer), "Group Adrenaline (57) - %d", price);
			AddMenuItem(menu, "57", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Adrenaline_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Group Adrenaline (57) - %d", price);
				AddMenuItem(menu, "57", buffer);
			}
		}
	}

	price = GetConVarInt(SURVIVOR(Price_GroupPainPills));
	if(price >= 0)
	{
			new j = 0;
			decl i;
			for (i = 1; i <= MaxClients; ++i)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				++j;
			}
			price = price * j;
			
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Group Pain Pills (58) - %d", price);
		AddMenuItem(menu, "58", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_PainPills_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Group Pain Pills (58) - %d", price);
				AddMenuItem(menu, "58", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_GroupFirstAidkit));
	if(price >= 0)
	{
			new j = 0;
			decl i;
			for (i = 1; i <= MaxClients; ++i)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				++j;
			}
			price = price * j;
			
		if (IsPlayerAlive(client))
		{
		Format(buffer, sizeof(buffer), "Group First Aid Kit (59) - %d", price);
		AddMenuItem(menu, "59", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_FirstAidkit_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Group First Aid Kit (59) - %d", price);
				AddMenuItem(menu, "59", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_GroupDefibrillator));
	if(price >= 0)
	{
			new j = 0;
			decl i;
			for (i = 1; i <= MaxClients; ++i)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				++j;
			}
			price = price * j;
			
		if (IsPlayerAlive(client))
		{
			Format(buffer, sizeof(buffer), "Defibrillator (60) - %d", price);
			AddMenuItem(menu, "60", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Defibrillator_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Group Defibrillator (60) - %d", price);
				AddMenuItem(menu, "60", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_GroupBileBomb));
	if(price >= 0)
	{
			new j = 0;
			decl i;
			for (i = 1; i <= MaxClients; ++i)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				++j;
			}
			price = price * j;
			
		if (IsPlayerAlive(client))
		{
			Format(buffer, sizeof(buffer), "Group Bile Bomb (61) - %d", price);
			AddMenuItem(menu, "61", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_BileBomb_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Group Bile Bomb (61) - %d", price);
				AddMenuItem(menu, "61", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_GroupPipeBomb));
	if(price >= 0)
	{
			new j = 0;
			decl i;
			for (i = 1; i <= MaxClients; ++i)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				++j;
			}
			price = price * j;
			
		if (IsPlayerAlive(client))
		{
			Format(buffer, sizeof(buffer), "Group Pipe Bomb (62) - %d", price);
			AddMenuItem(menu, "62", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_PipeBomb_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Group Pipe Bomb (62) - %d", price);
				AddMenuItem(menu, "62", buffer);
			}
		}
		
	}

	price = GetConVarInt(SURVIVOR(Price_GroupMolotov));
	if(price >= 0)
	{
			new j = 0;
			decl i;
			for (i = 1; i <= MaxClients; ++i)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				++j;
			}
			price = price * j;
			
		if (IsPlayerAlive(client))
		{
			Format(buffer, sizeof(buffer), "Group Molotov (63) - %d", price);
			AddMenuItem(menu, "63", buffer);
		}
		else
		{
			if (GetConVarInt(SURVIVOR(Price_Molotov_Dead)) == 1)
			{
				Format(buffer, sizeof(buffer), "Group Molotov (63) - %d", price);
				AddMenuItem(menu, "63", buffer);
			}
		}
		
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}

public ConfirmMenu(client, const String:itemIndex[], const String:itemName[])
{
	new Handle:menu = CreateMenu(ConfirmMenuHandler);

	decl String:buffer[96];

	Format(buffer, sizeof(buffer), "Are you sure you want to buy %s?", itemName);
	SetMenuTitle(menu, buffer);

	if (StringToInt(itemIndex) == 51)
	{
		AddMenuItem(menu, itemIndex, "Yes (in the body position)");
		AddMenuItem(menu, itemIndex, "Yes (in the starting safe room)");
	}
	else
	{
		AddMenuItem(menu, itemIndex, "Yes");
	}
	
	AddMenuItem(menu, "", "No");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}

public MainMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(GetClientTeam(param1) == T_INFECTED)
		{
			switch(param2)
			{
			case 0:
				InfectedSubMenu1(param1);
			case 1:
				InfectedSubMenu2(param1);
			case 2:
				InfectedSubMenu3(param1);
			case 3:
				InfectedSubMenu4(param1);
			case 5:
				InfectedSubMenu5(param1);
			case 4:
				InfectedSubMenu6(param1);
			}
		}
		else if(GetClientTeam(param1) == T_SURVIVOR)
		{
			switch(param2)
			{
			case 0:
				SurvivorSubMenu1(param1);
			case 1:
				SurvivorSubMenu2(param1);
			case 2:
				SurvivorSubMenu3(param1);
			case 3:
				SurvivorSubMenu4(param1);
			case 4:
				SurvivorSubMenu6(param1);
			case 5:
				SurvivorSubMenu5(param1);
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public SubMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:info[4];
		GetMenuItem(menu, param2, info, sizeof(info));

		if(GetClientTeam(param1) == T_INFECTED)
		{
			new index = StringToInt(info);
			if(index == 50)
				ConfirmMenu(param1, info, "Random item");
			else
			{
				if ((index >= 32) && (index <= 38))
				{
					_SelectPlayerMenu(param1, info);
				}
				else
					ConfirmMenu(param1, info, InfectedItemName[index]);
			}
		}
		else if(GetClientTeam(param1) == T_SURVIVOR)
		{
			new index = StringToInt(info);
			if(index == 50)
				ConfirmMenu(param1, info, "Random item");
			else
				ConfirmMenu(param1, info, SurvivorItemName[index]);
		}
	}
	else if(action == MenuAction_Cancel)
	{
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public ConfirmMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:info[96];
		GetMenuItem(menu, param2, info, sizeof(info));

		if(GetClientTeam(param1) == T_INFECTED)
		{
			new index = StringToInt(info[0]);

			if(param2 == 0)
			{
				OnInfectedBuy(param1, index, -1);
			}
		}
		else if(GetClientTeam(param1) == T_SURVIVOR)
		{
			new index =  StringToInt(info[0]);
			
			if (index == 51)
			{
				if(param2 == 0)
					OnSurvivorBuy(param1, index, -1, true);
				else
					OnSurvivorBuy(param1, index, -1, false);
			}
			else
			{
				if(param2 == 0)
					OnSurvivorBuy(param1, index, -1, false);
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public _SelectPlayerMenu(client, const String:itemIndex[])
{
	new Handle:menu = CreateMenu(SelectPlayerMenuHandler);

	decl String:buffer[96];
	decl String:name[256];

	Format(buffer, sizeof(buffer), "You have %d point%s\n#. Item (ID) - price", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
	SetMenuTitle(menu, buffer);
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (i != client)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && !IsFakeClient(i))
			{
				GetClientName(i, name, sizeof(name));				
				Format(buffer, sizeof(buffer), "%s %d", itemIndex, GetClientUserId(i));
				AddMenuItem(menu, buffer, name);
			}
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 180);
}
public SelectPlayerMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:info[96];
		GetMenuItem(menu, param2, info, sizeof(info));
	
		if(GetClientTeam(param1) == T_INFECTED)
		{
			new index = StringToInt(info);
			new target = -1;
			
			for (new i = 0; i < 96; ++i)
			{
				if (info[i] == ' ')
				{
					target = StringToInt(info[++i]);
					break;
				}
			}
			OnInfectedBuy(param1, index, GetClientOfUserId(target));
		}
	}
	else if(action == MenuAction_Cancel)
	{
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

#define INFECTED_TEAM 3
#define SURVIVOR_TEAM 2
#define INF_TANK 8
#define MAX_PER_SIDE 10
#define VERSION "1.2.2"

new static Handle:cvar_tankroar = INVALID_HANDLE;
new static Handle:cvar_power = INVALID_HANDLE;
new static Handle:cvar_distanceaffected = INVALID_HANDLE;
new static Handle:cvar_cooldown = INVALID_HANDLE;
new static Handle:cvar_damage = INVALID_HANDLE;
new static Handle:cvar_hint = INVALID_HANDLE;
new static Handle:cvar_required_hp = INVALID_HANDLE;

new static survivor[MAX_PER_SIDE];
new static infected[MAX_PER_SIDE];
new static cooldown[MAXPLAYERS + 1];
new static round = 0;
new bool:pinned[MAXPLAYERS + 1];

public InitializeTankRoar()
{
	CreateConVar("sm_tankroar_version",VERSION, "The Version of this plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	cvar_tankroar = CreateConVar("sm_tankroar","2", "Sets the dimensional plane the roar affects.0 - Disable plugin, 1 - Roar only affect survivors on the (relatively) same plane as tank, 2 - Roar affects survivor as long as survivor is set distance away from tank.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_power = CreateConVar("sm_tankroar_power","300", "Sets how powerful the roar is.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_distanceaffected = CreateConVar("sm_tankroar_radius","400", "Sets how near survivor must be in order to be affected by the roar.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_cooldown = CreateConVar("sm_tankroar_cooldown","7", "Sets how long before tank can roar again. Numbers <= 0 indicates roar can only be used once.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_damage = CreateConVar("sm_tankroar_damage","0", "Sets damage dealt to survivors.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_hint = CreateConVar("sm_tankroar_hint","1", "Set the displaying hint type. 0 - disable. 1 - chat. 2 - instructor hint. 3 - both.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_required_hp = CreateConVar("sm_tankroar_req_hp","6000", "Sets the health the tank must be below before it can use roar.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("round_freeze_end", Event_RoundEnd);
	HookEvent("player_first_spawn", Event_FirstSpawn);
	HookEvent("player_bot_replace", Event_BotReplacePlayer);
	HookEvent("bot_player_replace", Event_PlayerReplaceBot);
	HookEvent("player_team", Event_SwitchTeam);

	HookEvent("lunge_pounce", Event_PlayerPinned);
	HookEvent("pounce_end", Event_PlayerPinnedEnd);
	HookEvent("jockey_ride", Event_PlayerPinned);
	HookEvent("jockey_ride_end", Event_PlayerPinnedEnd);
	HookEvent("choke_start", Event_PlayerPinned);
	HookEvent("choke_end", Event_PlayerPinnedEnd);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && IsClientInGame(client) && (GetClientTeam(client) == T_INFECTED) && (GetInfectedClass(client) == ZC_TANK) && !IsFakeClient(client))
	{
		if((GetEntProp(client, Prop_Send, "m_iHealth") <= 1500) && (Players[client][HasHintOn] != 1) && (Players[client][Points] >= GetConVarInt(INFECTED(Price_Healing))))
		{
			CPrintToChat(client, "{olive}[SM]{default} You can heal yourself by typing {olive}!buy 0{default} in chat!");
			ShowHint(client, "You can heal yourself by typing '!buy 0' in chat!", 4.0, 0, 1, "+zoom");
			Players[client][HasHintOn] = 1;
			CreateTimer(4.5, Timer_ResetHint, client);
		}
		if(GetConVarInt(cvar_tankroar) && (GetConVarInt(cvar_hint) > 1))
		{
			if((cooldown[client] == 0) && (Players[client][HasHintOn] != 1))
			{
				CPrintToChat(client, "{olive}[SM]{default} You can knock survivors out as a tank by pressing your {olive}zoom{default} button!");
				ShowHint(client, "You can knock survivors out as a tank by pressing your zoom button!", 4.0, 0, 1, "+zoom");
				Players[client][HasHintOn] = 1;
				CreateTimer(4.5, Timer_ResetHint, client);
			}
		}
	}
}

public Action:Timer_ResetHint(Handle:timer, any:client)
{
	Players[client][HasHintOn] = 0;
}

public Action:Event_FirstSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	CreateTimer(0.1, Delayed_FirstSpawnAction, GetClientOfUserId(GetEventInt(event, "userid")));
}

public Action:Delayed_FirstSpawnAction(Handle:timer, any:client){

	if (IsValidEntity(client) && GetClientTeam(client) == SURVIVOR_TEAM)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if ((survivor[iii] == 0) && (GetSurvivorIndex(client) == -1) )
			{
				survivor[iii] = client;
			}
		}
	} 
	else if (IsValidEntity(client) && GetClientTeam(client) == INFECTED_TEAM && IsClientValid(client))
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if ((infected[iii] == 0) && (GetInfectedIndex(client) == -1) )
			{
				infected[iii] = client;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_BotReplacePlayer(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));

	if (GetClientTeam(bot) == SURVIVOR_TEAM)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if (survivor[iii] == client) 
			{
				survivor[iii] = bot;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerReplaceBot(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "bot"));
	new player = GetClientOfUserId(GetEventInt(event, "player"));

	if (GetClientTeam(player) == SURVIVOR_TEAM)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if (survivor[iii] == client)
			{
				survivor[iii] = player;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	round += 1;

	if (round >= 2)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			survivor[iii] = 0;
			infected[iii] = 0;
			round = 0;
		}
	}
	else
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			survivor[iii] = infected[iii];
		}
	}
	return Plugin_Continue;
}


public Action:Event_SwitchTeam(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetEventInt(event, "oldteam") == INFECTED_TEAM)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if (infected[iii] == client)
			{
				infected[iii] = 0;
			}
		}
	}

	if (GetEventInt(event, "team") == INFECTED_TEAM)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if ((infected[iii] == 0) && (GetInfectedIndex(client) == -1) && IsClientValid(client) )
			{
				infected[iii] = client;
			}
		}
	}
}

new FINALE_COUNT = -1;
public TankRoar_OnMapStart(){
	for (new iii = 0; iii< MAX_PER_SIDE; iii++)
	{
		survivor[iii] = 0;
		infected[iii] = 0;
	}
}

public Action:Event_PlayerPinned(Handle:event, const String:name[], bool:dontBroadcast){
	pinned[GetClientOfUserId(GetEventInt(event, "victim"))] = true;
}

public Action:Event_PlayerPinnedEnd(Handle:event, const String:name[], bool:dontBroadcast){
	pinned[GetClientOfUserId(GetEventInt(event, "victim"))] = false;
}


public Action:DisplayHint(Handle:timer, Handle: pack){ 
	decl String: msg[256], String: bind[16], String: msgphrase[256];

	ResetPack(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	ReadPackString(pack, msg, sizeof(msg));
	ReadPackString(pack, bind, sizeof(bind));
	CloseHandle(pack);

	new hintType = GetConVarInt(cvar_hint);
	decl String:tempString[128];
	IntToString(GetConVarInt(cvar_required_hp), tempString, sizeof(tempString));
	FormatEx(msgphrase, sizeof(msgphrase), "%t if your health is below %s", msg, tempString);

	if (hintType == 1 || hintType == 3)
	{
		PrintToChat(client,  "\x03[Hint]\x01 %s.", msgphrase);
	}

	if (hintType == 2 || hintType == 3)
	{
		decl instrHintEnt, String:name[32];

		instrHintEnt = CreateEntityByName("env_instructor_hint");
		FormatEx(name, sizeof(name), "TRIH%d", client);
		DispatchKeyValue(client, "targetname", name);
		DispatchKeyValue(instrHintEnt, "hint_target", name);

		DispatchKeyValue(instrHintEnt, "hint_range", "0.01");
		DispatchKeyValue(instrHintEnt, "hint_color", "255 255 255");
		DispatchKeyValue(instrHintEnt, "hint_caption", msgphrase);
		DispatchKeyValue(instrHintEnt, "hint_icon_onscreen", "use_binding");
		DispatchKeyValue(instrHintEnt, "hint_binding", bind);
		DispatchKeyValue(instrHintEnt, "hint_timeout", "6.0");

		ClientCommand(client, "gameinstructor_enable 1");
		DispatchSpawn(instrHintEnt);

		AcceptEntityInput(instrHintEnt, "ShowHint");

		CreateTimer(6.0, DisableInstructor, client);
	}
} 

public Action:DisableInstructor(Handle:timer, any:client){
	ClientCommand(client, "gameinstructor_enable 0");
	DispatchKeyValue(client, "targetname", "");
}

ApplyDamage(victim, damage, attacker=0, type=0, String:weapon[]=""){
	if((victim>0) && (damage>0))
	{		
		if(victim <= MaxClients)
			if(!IsClientInGame(victim))
				return;
				
		decl String: s_dmg[16];
		IntToString(damage, s_dmg, sizeof(s_dmg));
		decl String: s_type[32];
		IntToString(type| (1<<30), s_type, sizeof(s_type));

		new PtHurtEnt=CreateEntityByName("point_hurt");
		if(PtHurtEnt > 0)
		{
			DispatchKeyValue(victim,"targetname","TRDD");
			DispatchKeyValue(PtHurtEnt,"DamageTarget","TRDD");
			DispatchKeyValue(PtHurtEnt,"Damage",s_dmg);
			DispatchKeyValue(PtHurtEnt,"DamageType",s_type);
			if(!StrEqual(weapon,"")) DispatchKeyValue(PtHurtEnt,"classname",weapon);

			DispatchSpawn(PtHurtEnt);
			if (!(attacker>0)) attacker = -1;
			AcceptEntityInput(PtHurtEnt,"Hurt", attacker);

			DispatchKeyValue(victim,"targetname","");
			RemoveEdict(PtHurtEnt);
		}
	}
}

stock Fling(target, Float:vector[3], attacker, Float:stunTime = 3.0)
{
	SDKCall(SDKCALL(Fling), target, vector, 96, attacker, stunTime);
}

public Action:TankRoar_OnPlayerRunCmd(client, &buttons){
	if ((buttons & IN_ZOOM) && (GetConVarInt(cvar_tankroar) != 0)) {
		if (IsClientValid(client) && (GetZombieClass(client) == INF_TANK) && (GetConVarInt(cvar_tankroar)) && (!cooldown[client])) 
		{ 
			if (GetEntProp(client, Prop_Data, "m_iHealth") <= GetConVarInt(cvar_required_hp))
			{
				TankRoar(client);

				if (GetConVarFloat(cvar_cooldown)  > 0){
					CreateTimer(GetConVarFloat(cvar_cooldown), Reset, client);
				}
				cooldown[client] = true;
			}
		}
	}
}

TankRoar(tank)
{
	new Float:power = GetConVarFloat(cvar_power);	
	new victim	   = tank;
	new Float:radius = GetConVarFloat(cvar_distanceaffected);

	if(power > 0.0)
	{
		decl Float:position[3];	
		decl Float:variable[3];
		decl Float:velocity[3];

		EmitSoundToAll("player/tank/voice/yell/tank_yell_12.wav", tank);

		decl Float:distance;

		GetClientEyePosition(victim, position);

		new j =0;
		for(new i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && !GetEntProp(i, Prop_Send, "m_isIncapacitated"))
			{
				GetClientEyePosition(i, variable);

				if(!CheckClientA(position, variable, i, victim))
					continue;

				variable[0] = (position[0] - variable[0]);
				variable[1] = (position[1] - variable[1]);

				distance = SquareRoot(variable[0] * variable[0] + variable[1] * variable[1]);

				if(distance <= radius)
				{
					if (distance > 0.00001)
						distance = 1.0 / distance;
					

					variable[0] = ((variable[0] * distance) * -1.0) * power;
					variable[1] = ((variable[1] * distance) * -1.0) * power;

					GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity);

					variable[0] += velocity[0];
					variable[1] += velocity[1];
					variable[2] = power;
					
					if (variable[0] > 2048.0)
						variable[0] = 2048.0;
						
					if (variable[1] > 2048.0)
						variable[1] = 2048.0;
						
					if (variable[2] > 2048.0)
						variable[2] = 2048.0;

					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, variable);

					if((GetClientTeam(i) == T_SURVIVOR)  && (SDKCALL(Fling) != INVALID_HANDLE))
						SDKCall(SDKCALL(Fling), i, velocity, 76, victim, 3.0);

					if (GetConVarInt(cvar_damage) > 0)
						ApplyDamage(i, GetConVarInt(cvar_damage), victim);
					++j;
				}
			}
		}

		if (j && (GetConVarInt(INFECTED(Earns_Tank_Roar)) > 0))
		{
			Players[tank][Points] += GetConVarInt(INFECTED(Earns_Tank_Roar)) * j;
			CPrintToChat(tank, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}tank roar{default}.", GetConVarInt(INFECTED(Earns_Tank_Roar)) * j, (((GetConVarInt(INFECTED(Earns_Tank_Roar))) * j) == 1 ? "" : "s"));
		}
		
		decl String:className[32];
		new MaxEntities = GetMaxEntities();

		if(GetConVarBool(INFECTED(Earns_Explosion_Physics)))
		{
			radius *= 1.5;
			
			for(new i = MaxClients+1; i < MaxEntities; ++i)
			{
				if(IsValidEdict(i))
				{
					GetEdictClassname(i, className, sizeof(className));

					if(StrEqual(className, "prop_physics", false) || StrEqual(className, "prop_car_alarm", false))
					{
						GetEntityAbsOrigin(i, variable);

						if(!CheckClientA(position, variable, i, victim))
							continue;

						variable[0] = (position[0] - variable[0]);
						variable[1] = (position[1] - variable[1]);

						distance = SquareRoot(variable[0] * variable[0] + variable[1] * variable[1]);

						if(distance <= radius)
						{
							distance = 1.0 / distance;

							variable[0] = ((variable[0] * distance) * -1.0) * (power*1.5);
							variable[1] = ((variable[1] * distance) * -1.0) * (power*1.5);

							GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity);

							variable[0] += velocity[0];
							variable[1] += velocity[1];
							variable[2] = power * 2.0;

							TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, variable);
							ApplyDamage(i, 1, victim, DMG_GENERIC, "weapon_tank_claw");
						}
					}
				}
			}
		}
	}
}

public Action:UnstunTank(Handle:timer, any:tank){
	SetEntProp(tank, Prop_Send, "m_fFlags", GetEntityFlags(tank) & ~FL_FROZEN);
}

bool:IsClientValid(client)
{
	if (client <= 0) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;

	return true;
}


public Action:Reset(Handle:timer, any:client){
	cooldown[client] = false;
}

GetZombieClass(client){
	if (GetClientTeam(client) == INFECTED_TEAM){
		return GetEntProp(client, Prop_Send, "m_zombieClass");
	}
	return -1;
}

GetSurvivorIndex(client)
{
	for(new iii = 0; iii < MAX_PER_SIDE; iii++)
	{
		if (survivor[iii] == client)
			return iii;
	}
	return -1;
}

GetInfectedIndex(client)
{
	for(new iii = 0; iii < MAX_PER_SIDE; iii++)
	{
		if (infected[iii] == client)
			return iii;
	}
	return -1;
}
  
#define MOVETYPE_WALK 2
#define MOVETYPE_FLYGRAVITY 5
#define MOVECOLLIDE_DEFAULT 0
#define MOVECOLLIDE_FLY_BOUNCE 1

#define TEAM_INFECTED 3

#define CVAR_FLAGS FCVAR_PLUGIN

new PropMoveCollide;
new PropMoveType;
new PropVelocity;
new PropGhost;

new Handle:GhostFly;
new Handle:FlySpeed;
new Handle:MaxSpeed;

new bool:Flying[MAXPLAYERS+1];
new bool:Eligible[MAXPLAYERS+1];

#define PLUGIN_VERSION "1.1.1"

public InitializeGhostFly()
{
	GhostFly = CreateConVar("l4d_ghost_fly", "1", "Turn on/off the ability for ghosts to fly.",CVAR_FLAGS,true,0.0,true,1.0);
	FlySpeed = CreateConVar("l4d_ghost_fly_speed", "50", "Ghost flying speed.",CVAR_FLAGS,true,0.0);
	MaxSpeed = CreateConVar("l4d_ghost_max_speed", "500", "Ghost flying max speed.", CVAR_FLAGS, true, 300.0);

	CreateConVar("l4d_ghost_fly_version", PLUGIN_VERSION, " Ghost Fly Plugin Version ", FCVAR_REPLICATED|FCVAR_NOTIFY);

	PropMoveCollide = FindSendPropOffs("CBaseEntity",   "movecollide");
	PropMoveType	= FindSendPropOffs("CBaseEntity",   "movetype");
	PropVelocity	= FindSendPropOffs("CBasePlayer",   "m_vecVelocity[0]");
	PropGhost	   = FindSendPropInfo("CTerrorPlayer", "m_isGhost");

	HookEvent("ghost_spawn_time", EventGhostNotify2);
	HookEvent("player_first_spawn", EventGhostNotify1);
}
new bool:elig;

public Action:GhostFly_OnPlayerRunCmd(client, &buttons)
{
	if (GetConVarBool(GhostFly))
	{

		elig = isEligible(client);

		Eligible[client] = elig;

		if (elig)
		{
			if((buttons & IN_RELOAD) && (GetClientTeam(client) == 3) && (GetEntProp(client, Prop_Send, "m_zombieClass") != 8))
			{		
				if (Flying[client])
					KeepFlying(client);
				else	
					StartFlying(client);
			}
			else
			{
				if (Flying[client])
					StopFlying(client);
			}	
		}
		else
		{
			if (Flying[client])
				StopFlying(client);
		}

	}
}

bool:isEligible(client)
{

	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (GetClientTeam(client)!=TEAM_INFECTED) return false;
	if (GetEntData(client, PropGhost, 1)!=1) return false;

	return true;
}

public Action:StartFlying(client)
{
	Flying[client]=true;
	SetMoveType(client, MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE);
	AddVelocity(client, GetConVarFloat(FlySpeed));
	return Plugin_Continue;
}

public Action:KeepFlying(client)
{
	AddVelocity(client, GetConVarFloat(FlySpeed));
	return Plugin_Continue;
}

public Action:StopFlying(client)
{
	Flying[client]=false;
	SetMoveType(client, MOVETYPE_WALK, MOVECOLLIDE_DEFAULT);
	return Plugin_Continue;
}

AddVelocity(client, Float:speed)
{
	new Float:maxSpeed = GetConVarFloat(MaxSpeed);
	new Float:vecVelocity[3];
	GetEntDataVector(client, PropVelocity, vecVelocity);
	if ((vecVelocity[2]+speed) > maxSpeed)
		vecVelocity[2] = maxSpeed;
	else
		vecVelocity[2] += speed;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

SetMoveType(client, movetype, movecollide)
{
	SetEntData(client, PropMoveType, movetype);
	SetEntData(client, PropMoveCollide, movecollide);
}

public Action:EventGhostNotify1(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Notify(client,0);
}


public Action:EventGhostNotify2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Notify(client,GetEventInt(event, "spawntime"));
}

public Notify(client,time)
{
	CreateTimer((3.0+time), NotifyClient, client);
}

public Action:NotifyClient(Handle:timer, any:client)
{
	if(isEligible(client) && (Players[client][HasHintOn] != 1))
	{
		CPrintToChat(client, "{olive}[SM]{default} You can fly a as ghost by holding your {olive}reload{default} button!");
		//ShowHint(client, "You can fly as a ghost by holding your reload button!", 5.0, HINT_ICON_INFO, 1, "+reload");

		Players[client][HasHintOn] = 1;
		CreateTimer(5.0, Timer_ResetHint, client);
	}
}

public InitializeChargerPower()
{
	HookEvent("charger_charge_end", OnChargeEnd);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_hurt", ChargerPower_OnTakeDamage);
	HookEvent("player_incapacitated", ChargerPower_OnTakeIncap);
	HookEvent("player_death", ChargerPower_OnTakeKill);
}

public Action:ChargerPower_OnTakeDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetEventInt(event, "attackerentid");
	new damage = GetEventInt(event, "dmg_health");

	if(victim && IsValidEdict(victim) && IsValidEdict(attacker) && attacker && IsClientInGame(victim) && (GetClientTeam(victim) == T_SURVIVOR))
	{
		decl String:className[32];
		GetEdictClassname(attacker, className, sizeof(className));

		if(StrEqual(className, "prop_physics", false) || StrEqual(className, "prop_car_alarm", false))
		{
			new client = GetEntProp(attacker, Prop_Send, "m_Gender");

			if((client > 0) && (client <= MaxClients))
			{
				new earns   = GetConVarInt(INFECTED(Earns_Hurt));
				new minimal = GetConVarInt(INFECTED(Earns_Hurt_Damage_Charger));

				if(earns > 0)
				{
					if((Players[client][SurvivorDamage_Charger] += damage) >= minimal)
					{
						while(Players[client][SurvivorDamage_Charger] >= minimal)
						{
							Players[client][SurvivorDamage_Charger] -= minimal;

							Players[client][Points] += earns;
							CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}charger damage{default}.", earns, ((earns == 1) ? "" : "s"));

							if(Players[client][SurvivorDamage_Charger] < 0)
								Players[client][SurvivorDamage_Charger] = 0;
						}
					}
				}
			}
			attacker = client;
		}
	}
}
public Action:ChargerPower_OnTakeIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetEventInt(event, "attackerentid");

	if(victim && IsValidEdict(victim) && IsValidEdict(attacker) && attacker && IsClientInGame(victim) && (GetClientTeam(victim) == T_SURVIVOR))
	{
		decl String:className[32];
		GetEdictClassname(attacker, className, sizeof(className));

		if(StrEqual(className, "prop_physics", false) || StrEqual(className, "prop_car_alarm", false))
		{
			new client = GetEntProp(attacker, Prop_Send, "m_Gender");

			if((client > 0) && (client <= MaxClients))
			{
				if(client && IsClientInGame(client) && (GetClientTeam(client) == T_INFECTED) && !IsFakeClient(client))
				{
					if(GetClientTeam(victim) == T_SURVIVOR)
					{
						new earns = GetConVarInt(INFECTED(Earns_Incapacitate));

						if(earns > 0)
						{
							Players[client][Points] += earns;
							CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}incapating a survivor{default}.", earns, ((earns == 1) ? "" : "s"));					
						}
					}
				}
			}
			attacker = client;
		}
	}
}
public Action:ChargerPower_OnTakeKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetEventInt(event, "attackerentid");

	if(victim && IsValidEdict(victim) && IsValidEdict(attacker) && attacker && IsClientInGame(victim) && (GetClientTeam(victim) == T_SURVIVOR))
	{
		decl String:className[32];
		GetEdictClassname(attacker, className, sizeof(className));

		if(StrEqual(className, "prop_physics", false) || StrEqual(className, "prop_car_alarm", false))
		{
			new client = GetEntProp(attacker, Prop_Send, "m_Gender");

			if((client > 0) && (client <= MaxClients))
			{
				if(!client && Players[victim][Carryied] && Players[victim][CarryOwner] && victim && (GetClientTeam(victim) == T_SURVIVOR))
				{
					if(GetClientTeam(Players[victim][CarryOwner]) == T_INFECTED)
					{
						new earns = GetConVarInt(INFECTED(Earns_InstantKill));

						if(earns > 0)
						{
							Players[client][Points] += earns;
							CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}killing a survivor{default}.", earns, ((earns == 1) ? "" : "s"));
						}
					}

					Players[victim][Carryied]   = 0;
					Players[victim][CarryOwner] = 0;
				}
			}
			attacker = client;
		}
	}
}

public Action:Timer_OnChargeEnd(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return;

	new Float:power  = GetConVarFloat(INFECTED(Earns_Charge_Power));
	new Float:radius = GetConVarFloat(INFECTED(Earns_Charge_Radius));

	decl Float:origin[3];
	decl Float:angles[3];
	decl Float:distance;

	decl Float:position[3];
	decl Float:tracePos[3];
	decl Float:velocity[3];

	GetClientAbsOrigin(client, origin);
	GetClientAbsAngles(client, angles);

	angles[2]  = 0.0;
	origin[2] += 20.0;

	if(GetEntProp(client, Prop_Send, "m_carryVictim") > 0)
		return;

	new Handle:hTrace = TR_TraceRayFilterEx(origin, angles, MASK_ALL, RayType_Infinite, ChargeTraceFilter, client);

	if(TR_DidHit(hTrace))
	{
		new target = TR_GetEntityIndex(hTrace);
		TR_GetEndPosition(tracePos, hTrace);

		for(new i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && (GetClientTeam(i) == T_SURVIVOR) && !GetEntProp(client, Prop_Send, "m_isIncapacitated"))
			{
				GetClientEyePosition(i, position);

				if(!CheckClientA(origin, position, i, client))
					continue;

				position[0] = (tracePos[0] - position[0]);
				position[1] = (tracePos[1] - position[1]);

				distance = SquareRoot(position[0] * position[0] + position[1] * position[1]);

				if(distance <= radius)
				{
					distance = 1.0 / distance;

					position[0] = ((position[0] * distance) * -1.0) * power;
					position[1] = ((position[1] * distance) * -1.0) * power;

					GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity);

					position[0] += velocity[0];
					position[1] += velocity[1];
					position[2] = power;

					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, position);

					if(SDKCALL(Fling) != INVALID_HANDLE)
						SDKCall(SDKCALL(Fling), i, velocity, 96, client, 3.0);
				}
			}
		}

		if(GetVectorDistance(origin, tracePos) <= 96.0)
		{
			decl String:className[32];
			GetEdictClassname(target, className, sizeof(className));

			if(target && IsValidEdict(target) && (StrEqual(className, "prop_physics", false) || StrEqual(className, "prop_car_alarm", false)) && GetEntityMoveType(target) == MOVETYPE_VPHYSICS)
			{
				position[0] = (origin[0] - tracePos[0]);
				position[1] = (origin[1] - tracePos[1]);

				distance = SquareRoot(position[0] * position[0] + position[1] * position[1]);

				if(distance <= 128.0)
				{
					distance = 1.0 / distance;

					position[0] = ((position[0] * distance) * -1.0) * GetConVarFloat(INFECTED(Earns_Charge_Physics_X));
					position[1] = ((position[1] * distance) * -1.0) * GetConVarFloat(INFECTED(Earns_Charge_Physics_Z));

					GetEntPropVector(target, Prop_Data, "m_vecVelocity", velocity);

					position[0] += velocity[0];
					position[1] += velocity[1];
					position[2] = GetConVarFloat(INFECTED(Earns_Charge_Physics_Y));

					TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, position);

					SetEntProp(target, Prop_Send, "m_Gender", client);

					new Handle:pack = CreateDataPack();

					WritePackCell(pack, client);
					WritePackCell(pack, target);
					WritePackFloat(pack, tracePos[0]);

					CreateTimer(0.5, CheckEntity, pack);

					decl String:_className[13];
					GetEdictClassname(target, _className, sizeof(className));

					if(StrEqual(_className, "prop_physics"))
						CreateTimer(60.0, RemoveEntity, target);
				}
			}
		}
	}
}
public Action:OnChargeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(0.25, Timer_OnChargeEnd, client);
}

public Action:CheckEntity(Handle:timer, Handle:pack)
{
	decl client;
	decl entity;
	decl Float:origin[3];
	decl Float:lastOrigin;

	ResetPack(pack, false);

	client	 = ReadPackCell(pack);
	entity	 = ReadPackCell(pack);
	lastOrigin = ReadPackFloat(pack);

	CloseHandle(pack);

	if(IsValidEdict(entity))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);

		if (origin[0] != lastOrigin)
		{
			pack = CreateDataPack();

			WritePackCell(pack, client);
			WritePackCell(pack, entity);
			WritePackFloat(pack, origin[0]);

			CreateTimer(0.1, CheckEntity, pack);
		}
		else
		{
			origin = Float:{ 0.0, 0.0, 0.0 };
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, origin);
			SetEntProp(entity, Prop_Send, "m_Gender", 0);
		}
	}
}

public bool:ChargeTraceFilter(entity, mask, any:client)
{
	if(entity == client)
		return false;

	if(entity <= MaxClients)
		return false;

	if(entity == 0)
		return false;

	return true;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && IsClientInGame(client) && !IsFakeClient(client) && (GetClientTeam(client) == TEAM_INFECTED) && (GetInfectedClass(client) == ZC_CHARGER))
	{
		if(Players[client][HasHintOn] != 1)
		{
			CreateTimer(0.1, DisplayChargerHint, client);
		}
	}
}

public Action:DisplayChargerHint(Handle:timer, any:client)
{
	if(IsClientInGame(client) && !IsFakeClient(client)&& (GetClientTeam(client) == T_INFECTED) && (GetInfectedClass(client) == ZC_CHARGER) && IsPlayerAlive(client) )
	{
		CPrintToChat(client, "{olive}[SM]{default} You can move objects by hitting them when using own ability!");
		Players[client][HasHintOn] = 1;
		CreateTimer(15.0, DisplayChargerHint, client);
	}
}

public OnClientPutInServer(client)
{
	ResetPlayer(client);
}

#define UC_CEDA	   0x01
#define UC_CLOWN	  0x02
#define UC_MUD		0x03
#define UC_WORKER	 0x04
#define UC_RIOT	   0x05
#define UC_JIMMY	  0x06
#define UC_FA 7

public OnEntityCreated(_entity, const String:classname[])
{
	if (GetConVarBool(dbg_C))
	{
		PrintToServer("%d %s", _entity, classname);
	}
	if(HasPrecachedUncommons && StrEqual(classname, "infected", false) && (RemainingZombies > 0))
	{
		switch(ZombieType)
		{
		case UC_CEDA:
			SetEntityModel(_entity, "models/infected/common_male_ceda.mdl");

		case UC_CLOWN:
			SetEntityModel(_entity, "models/infected/common_male_clown.mdl");

		case UC_MUD:
			SetEntityModel(_entity, "models/infected/common_male_mud.mdl");

		case UC_WORKER:
			SetEntityModel(_entity, "models/infected/common_male_roadcrew.mdl");

		case UC_RIOT:
			SetEntityModel(_entity, "models/infected/common_male_riot.mdl");

		case UC_JIMMY:
			SetEntityModel(_entity, "models/infected/common_male_jimmy.mdl");

		case UC_FA:
			SetEntityModel(_entity, "models/infected/common_male_fallen_survivor.mdl");
			
		}

		--RemainingZombies;
	}
}

public OnAllPluginsLoaded()
{
	InitializeValues();
}
public OnPluginStart()
{
	HookEvent("player_death", ResEvent);
	
	InitializeCommands();
	InitializeConVars();
	InitializeEvents();
	InitializeTankRoar();
	InitializeGhostFly();
	InitializeChargerPower();

	PrecacheUncommons();

	CPrintToChatAll("{olive}[SM]{default} You can type {olive}!buy{default} in chat to open shop menu.");
	CPrintToChatAll("{olive}[SM]{default} You can type {olive}!item_help{default} #ID in chat to get information about item by specifing it's ID.");

	CreateTimer(120.0, Timer_AnnounceBuy);
	
	RegServerCmd("give_points_to", Cmd_Give);

	dbg_C = CreateConVar("sm_dbg_pts", "0", "", FCVAR_PLUGIN);
}

public Action:Cmd_Give(args)
{
	decl String:hello[512];
	GetCmdArg(1, hello, sizeof(hello));
	new client = StringToInt(hello);
	GetCmdArg(2, hello, sizeof(hello));
	new points = StringToInt(hello);
	new length = 512;
	
	if (!client || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;
	
	if (length > 0)
	{
		decl String:message[512];
		GetCmdArg(3, message, sizeof(message));
		CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s for {olive}%s{default}.", points, ((points == 1) ? "" : "s"), message);
	}
	else
	{
		CPrintToChat(client, "{olive}[SM]{default} You got {olive}%d{default} point%s.", points, ((points == 1) ? "" : "s"));
	}
	
	Players[client][Points] += points;
	
	return Plugin_Continue;
}

public Action:OnTakeDamage_GodMode(victim, &attacker, &inflictor, &Float:damage, &damageType)
{
	if((victim > 0) && (victim <= MaxClients) && IsClientInGame(victim) && !IsFakeClient(victim))
	{
		if(Players[victim][GodMode])
		{
			damage = 0.0;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public Action:Timer_StopGodMode(Handle:timer, any:client)
{
	if(Players[client][GodMode])
	{
		CPrintToChat(client, "{olive}[SM]{default} The {olive}God Mode{default} ability has been disabled.");
		Players[client][GodMode] = 0;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage_GodMode);
	}
}
public bool:MakeSpeed(client)
{
	Players[client][DefaultSpeed] = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");
	return SDKHookEx(client, SDKHook_PreThinkPost, OnSpeedHook);
}

public OnSpeedHook(client)
{
	SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", Players[client][DefaultSpeed] * GetConVarFloat((GetClientTeam(client) == T_SURVIVOR) ? SURVIVOR(Price_SpeedMultipler) : INFECTED(Price_SpeedMultipler)));
}

public Action:Timer_StopSpeed(Handle:timer, any:client)
{
	if(Players[client][Speed])
	{
		SDKUnhook(client, SDKHook_PreThinkPost, OnSpeedHook);
		CPrintToChat(client, "{olive}[SM]{default} The {olive}Super-Speed{default} ability has been disabled.");
		Players[client][Speed] = 0;
	}
}

public bool:MakeInvisibility(client)
{
	SetEntityRenderColor(client, 255, 255, 255, 30);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);

	return true;
}
public Action:Timer_StopInvisibility(Handle:timer, any:client)
{
	if(Players[client][Inv])
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderFx(client, RENDERFX_NONE);

		CPrintToChat(client, "{olive}[SM]{default} The {olive}Invisibilty{default} ability has been disabled.");
		Players[client][Inv] = 0;
	}
}

public bool:MakeSlow(client)
{
	if(IsValidEdict(entSlow))
	{
		RemoveEdict(entSlow);
	}

	entSlow = CreateEntityByName("func_timescale");

	if(IsValidEdict(entSlow))
	{
		DispatchKeyValueFloat(entSlow, "desiredTimescale",	  GetConVarFloat(SURVIVOR(Price_SlowMultipler)));
		DispatchKeyValue(entSlow,	  "acceleration",		  "2.0");
		DispatchKeyValue(entSlow,	  "minBlendRate",		  "1.0");
		DispatchKeyValue(entSlow,	  "blendDeltaMultiplier",  "2.0");
		DispatchSpawn(entSlow);
	}
	else
		return false;

	AcceptEntityInput(entSlow, "Start");

	for(new i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SetEntProp(i, Prop_Send, "m_bNightVisionOn", 1);
			EmitSoundToClient(i, "music/scavenge/gascanofvictory.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0);
		}
	}

	return true;
}
public Action:Timer_StopSlow(Handle:timer, any:client)
{
	if(isSlow)
	{
		AcceptEntityInput(entSlow, "Stop");
		isSlow = false;

		for(new i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				SetEntProp(i, Prop_Send, "m_bNightVisionOn", 0);
				StopSound(i, SNDCHAN_AUTO, "music/scavenge/gascanofvictory.wav");
			}
		}
		CPrintToChatAll("{olive}[SM]{default} The {olive}Slow Motion{default} ability has been disabled.");
	}
}

public OnMapStart()
{
	SetConVarFloat(FindConVar("sv_fallen_survivor_health_multiplier"), 150.0);
	SetConVarInt(FindConVar("z_fallen_max_count"), 30);
	
	ServerCommand("read_pts_cfg");
	PrecacheUncommons();

	if(GetConVarBool(hGlobal_Reset_AtMapStart))
	{
		for(new i = 1; i <= MaxClients; ++i)
			ResetPlayer(i);
	}

	for(new i = 1; i <= MaxClients; ++i)
	{
		Players[i][CanSlap]		= 1;
		Players[i][GotSlap]		= 0;
	}

	TankCount  = TankTeamCount  = 0;
	WitchCount = WitchTeamCount = 0;
	
	new servCmd = -1;
	
	servCmd = CreateEntityByName("point_servercommand");
	DispatchKeyValue(servCmd, "targetname", "point_system_server_command");
	DispatchSpawn(servCmd);
}

public Action:Timer_AnnounceBuy(Handle:timer, any:data)
{
	CreateTimer(90.0, Timer_AnnounceBuy2);
	CPrintToChatAll("{olive}[SM]{default} You can type {olive}!buy{default} in chat to open shop menu.");
}
public Action:Timer_AnnounceBuy2(Handle:timer, any:data)
{
	CreateTimer(90.0, Timer_AnnounceBuy);
	CPrintToChatAll("{olive}[SM]{default} You can type {olive}!item_help{default} in chat to get information about item by specifing it's ID.");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	TankRoar_OnPlayerRunCmd(client, buttons);
	GhostFly_OnPlayerRunCmd(client, buttons);
}

public	   InvokeBuy(client, item, target)
{
	switch(GetClientTeam(client))
	{
	case T_INFECTED:
	{
		if (target == -1)
		{
			decl String:Item[32];
			Format(Item, sizeof(Item), "%d", item);
			_SelectPlayerMenu(client, Item);
		}
		else
		{
			OnInfectedBuy(client, item, target);
		}
	}
	case T_SURVIVOR:
		{
			OnSurvivorBuy(client, item, -1, false);
		}
	default:
		CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot use the \"buy\" command when you are not in game.");
	}
}
public	InvokePoints(client)
{
	if((GetClientTeam(client) == T_SURVIVOR) || (GetClientTeam(client) == T_INFECTED))
	{
		decl String:msg[256];
		FormatEx(msg, sizeof(msg), "{olive}[SM]{default} You have {olive}%d{default} point%s.", Players[client][Points], ((Players[client][Points] == 1) ? "" : "s"));
		CPrintToChat(client, msg);
	}
	else
		CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot use the \"points\" command when you are not in game.");
}
public InvokeRepeatbuy(client)
{
	InvokeBuy(client, Players[client][LastItem], -2);
}

public InvokeUsepoints(client)
{
	switch(GetClientTeam(client))
	{
	case T_INFECTED:
		InfectedMainMenu(client);

	case T_SURVIVOR:
		{
			SurvivorMainMenu(client);
		}
	default:
		CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot use the \"usepoints\" command when you are not in game.");
	}
}

public Action:CheckPlayers(Handle:timer, any:client)
{
	for(new i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && (GetClientTeam(i) == T_INFECTED) && !IsFakeClient(i))
		{
			if((GetPlayerLifeState(i) == LIFESTATE_ALIVE) && (GetPlayerGhostStatus(i) == 1))
			{
				SetPlayerGhostStatus(i, true);
				SetPlayerIsAlive(i, false);
			}
			if((GetPlayerLifeState(i) != LIFESTATE_ALIVE) && (GetPlayerGhostStatus(i) == 0))
			{
				SetPlayerGhostStatus(i, false);
				SetPlayerIsAlive(i, true);
			}
		}
	}
}

public Action:ResetCanSlap(Handle:timer, any:client)
{
	Players[client][CanSlap] = 1;
}
public Action:ResetGotSlap(Handle:timer, any:client)
{
	Players[client][GotSlap] = 0;
}

public Action:SpawnAfterDeath(Handle:timer, any:client)
{
	SpawnInfected(client, Players[client][Ticket]);
}
public Action:OnTankTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType)
{
	if((float(GetEntProp(victim, Prop_Send, "m_iHealth")) - damage) <= 0.0)
	{
		SDKUnhook(victim, SDKHook_OnTakeDamage, OnTankTakeDamage);
		
		if ((GetClientTeam(victim) == 3) && (GetZombieClass(victim) == ZC_TANK))
			ForcePlayerSuicide(victim);
	}
}

public OnInfectedBuy(client, index, target)
{
	decl String:targetName[256];
	
	if(GetClientTeam(client) != T_INFECTED)
		CPrintToChat(client, "{olive}[SM]{default} You selected item for wrong team.");

	switch(index)
	{
	case 0:
		{
			new price = GetConVarInt(INFECTED(Price_Healing));

			if(price >= 0)
			{
				if(GetPlayerLifeState(client) > 0)
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy the {olive}Healing{default} when you are dead.");
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					HealInfected(client);
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Healing{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Healing{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Healing{default} is disabled.");
				return -2;
			}
		}
	case 1:
		{
			new price = GetConVarInt(INFECTED(Price_Suicide));

			if(price >= 0)
			{
				if(GetPlayerLifeState(client) > 0)
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy the {olive}Suicide{default} when you are dead.");
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					ApplyDamage(client, 10000);
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Suicide{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Suicide{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Suicide{default} is disabled.");
				return -2;
			}
		}
	case 2:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnSelfBoomer));

			if(price >= 0)
			{
				if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
				{
					price += GetConVarInt(INFECTED(Price_Suicide));
				}
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(client))
					{
						ForcePlayerSuicide(client);
						SetPlayerGhostStatus(client, true);
						Players[client][Ticket] = ZC_BOOMER;
						SpawnInfected(client, ZC_BOOMER);
						SetPlayerGhostStatus(client, false);
					}
					else
					{
						SpawnInfected(client, ZC_BOOMER);
					}
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Become Boomer{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Become Boomer{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Become Boomer{default} is disabled.");
				return -2;
			}
		}
	case 3:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnSelfCharger));			

			if(price >= 0)
			{
				if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
				{
					price += GetConVarInt(INFECTED(Price_Suicide));
				}
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(client))
					{
						ForcePlayerSuicide(client);
						SetPlayerGhostStatus(client, true);
						Players[client][Ticket] = ZC_CHARGER;
						SpawnInfected(client, ZC_CHARGER);
						SetPlayerGhostStatus(client, false);
					}
					else
					{
						SpawnInfected(client, ZC_CHARGER);
					}
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Become Charger{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Become Charger{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Become Charger{default} is disabled.");
				return -2;
			}
		}
	case 4:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnSelfHunter));
			if(price >= 0)
			{
				if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
				{
					price += GetConVarInt(INFECTED(Price_Suicide));
				}
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(client))
					{
						ForcePlayerSuicide(client);
						SetPlayerGhostStatus(client, true);
						Players[client][Ticket] = ZC_HUNTER;
						SpawnInfected(client, ZC_HUNTER);
						SetPlayerGhostStatus(client, false);
					}
					else
					{
						SpawnInfected(client, ZC_HUNTER);
					}
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Become Hunter{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Become Hunter{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Become Hunter{default} is disabled.");
				return -2;
			}
		}
	case 5:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnSelfJockey));

			if(price >= 0)
			{
				if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
				{
					price += GetConVarInt(INFECTED(Price_Suicide));
				}
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(client))
					{
						ForcePlayerSuicide(client);
						SetPlayerGhostStatus(client, true);
						Players[client][Ticket] = ZC_JOCKEY;
						SpawnInfected(client, ZC_JOCKEY);
						SetPlayerGhostStatus(client, false);
					}
					else
					{
						SpawnInfected(client, ZC_JOCKEY);
					}
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Become Jockey{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Become Jockey{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Become Jockey{default} is disabled.");
				return -2;
			}
		}
	case 6:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnSelfSmoker));
			if(price >= 0)
			{
				if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
				{
					price += GetConVarInt(INFECTED(Price_Suicide));
				}
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(client))
					{
						ForcePlayerSuicide(client);
						SetPlayerGhostStatus(client, true);
						Players[client][Ticket] = ZC_SMOKER;
						SpawnInfected(client, ZC_SMOKER);
						SetPlayerGhostStatus(client, false);
					}
					else
					{
						SpawnInfected(client, ZC_SMOKER);
					}
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Become Smoker{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Become Smoker{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Become Smoker{default} is disabled.");
				return -2;
			}
		}
	case 7:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnSelfSpitter));
			if(price >= 0)
			{
				if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
				{
					price += GetConVarInt(INFECTED(Price_Suicide));
				}
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(client))
					{
						ForcePlayerSuicide(client);
						SetPlayerGhostStatus(client, true);
						Players[client][Ticket] = ZC_SPITTER;
						SpawnInfected(client, ZC_SPITTER);
						SetPlayerGhostStatus(client, false);
					}
					else
					{
						SpawnInfected(client, ZC_SPITTER);
					}
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Become Spitter{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Become Spitter{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Become Spitter{default} is disabled.");
				return -2;
			}
		}
	case 8:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnSelfTank));

			if(price >= 0)
			{
				if(IsPlayerAlive(client) && !GetPlayerGhostStatus(client))
				{
					price += GetConVarInt(INFECTED(Price_Suicide));
				}
				if(Players[client][Points] >= price)
				{
					if(TankTeamCount >= GetConVarInt(INFECTED(Limit_TankTeamLimit)))
					{
						CPrintToChat(client, "{olive}[SM]{default} The Tank limit per team has been reached. You can't spawn any more tanks.");
						return -2;
					}
					if(TankCount >= GetConVarInt(INFECTED(Limit_TankTimeLimit)))
					{
						CPrintToChat(client, "{olive}[SM]{default} The limit of alive tanks has been reached.");
						return -2;
					}
					if(IsPlayerAlive(client))
					{
						ForcePlayerSuicide(client);
						SetPlayerGhostStatus(client, true);
						Players[client][Ticket] = ZC_TANK;
						SpawnInfected(client, ZC_TANK);
						SetPlayerGhostStatus(client, false);
					}
					else
					{
						SpawnInfected(client, ZC_TANK);
					}
					Players[client][Points] -= price;
					
					decl String:name_[256];
					GetClientName(client, name_, sizeof(name_));
					CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Tank{default}.", name_);
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Become Tank{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Become Tank{default} is disabled.");
				return -2;
			}
		}
	case 9:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnBoomer));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					new clientToSpawn = 0;

					for(new i = 1; i <= MaxClients; ++i)
					{
						if(IsClientInGame(i) && (GetClientTeam(i) == T_INFECTED) && ((GetPlayerGhostStatus(i) == 1) || (GetPlayerLifeState(i) > 0)))
						{
							clientToSpawn = i;
							break;
						}
					}

					if(clientToSpawn != 0)
					{					
						if(IsFakeClient(clientToSpawn))
						{
							CheatCommand(client, "z_spawn", "boomer auto");
						}
						else if(IsPlayerAlive(clientToSpawn))
						{
							ForcePlayerSuicide(clientToSpawn);
							SetPlayerGhostStatus(clientToSpawn, true);
							Players[clientToSpawn][Ticket] = ZC_BOOMER;
							SpawnInfected(clientToSpawn, ZC_BOOMER);
							SetPlayerGhostStatus(clientToSpawn, false);
						}
						else
						{
							SpawnInfected(clientToSpawn, ZC_BOOMER);
						}
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Boomer{default}.");
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. There is not available slots for the {olive}Spawn Boomer{default}.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Boomer{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Boomer{default} is disabled.");
				return -2;
			}
		}
	case 10:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnCharger));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					new clientToSpawn = 0;

					for(new i = 1; i <= MaxClients; ++i)
					{
						if(IsClientInGame(i) && (GetClientTeam(i) == T_INFECTED) && ((GetPlayerGhostStatus(i) == 1) || (GetPlayerLifeState(i) > 0)))
						{
							clientToSpawn = i;
							break;
						}
					}

					if(clientToSpawn != 0)
					{					
						if(IsFakeClient(clientToSpawn))
						{
							CheatCommand(client, "z_spawn", "charger auto");
						}
						else if(IsPlayerAlive(clientToSpawn))
						{
							ForcePlayerSuicide(clientToSpawn);
							SetPlayerGhostStatus(clientToSpawn, true);
							Players[clientToSpawn][Ticket] = ZC_CHARGER;
							SpawnInfected(clientToSpawn, ZC_CHARGER);
							SetPlayerGhostStatus(clientToSpawn, false);
						}
						else
						{
							SpawnInfected(clientToSpawn, ZC_CHARGER);
						}
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Charger{default}.");
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. There is not available slots for the {olive}Spawn Charger{default}.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Charger{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Charger{default} is disabled.");
				return -2;
			}
		}
	case 11:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnHunter));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					new clientToSpawn = 0;

					for(new i = 1; i <= MaxClients; ++i)
					{
						if(IsClientInGame(i) && (GetClientTeam(i) == T_INFECTED) && ((GetPlayerGhostStatus(i) == 1) || (GetPlayerLifeState(i) > 0)))
						{
							clientToSpawn = i;
							break;
						}
					}

					if(clientToSpawn != 0)
					{	
						if(IsFakeClient(clientToSpawn))
						{
							CheatCommand(client, "z_spawn", "hunter auto");
						}
						else if(IsPlayerAlive(clientToSpawn))
						{
							ForcePlayerSuicide(clientToSpawn);
							SetPlayerGhostStatus(clientToSpawn, true);
							Players[clientToSpawn][Ticket] = ZC_HUNTER;
							SpawnInfected(clientToSpawn, ZC_HUNTER);
							SetPlayerGhostStatus(clientToSpawn, false);
						}
						else
						{
							SpawnInfected(clientToSpawn, ZC_HUNTER);
						}
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Hunter{default}.");
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. There is not available slots for the {olive}Spawn Hunter{default}.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Hunter{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Hunter{default} is disabled.");
				return -2;
			}
		}
	case 12:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnJockey));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					new clientToSpawn = 0;

					for(new i = 1; i <= MaxClients; ++i)
					{
						if(IsClientInGame(i) && (GetClientTeam(i) == T_INFECTED) && ((GetPlayerGhostStatus(i) == 1) || (GetPlayerLifeState(i) > 0)))
						{
							clientToSpawn = i;
							break;
						}
					}

					if(clientToSpawn != 0)
					{			
						if(IsFakeClient(clientToSpawn))
						{
							CheatCommand(client, "z_spawn", "jockey auto");
						}
						else if(IsPlayerAlive(clientToSpawn))
						{
							ForcePlayerSuicide(clientToSpawn);
							SetPlayerGhostStatus(clientToSpawn, true);
							Players[clientToSpawn][Ticket] = ZC_JOCKEY;
							SpawnInfected(clientToSpawn, ZC_JOCKEY);
							SetPlayerGhostStatus(clientToSpawn, false);
						}
						else
						{
							SpawnInfected(clientToSpawn, ZC_JOCKEY);
						}
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Jockey{default}.");
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. There is not available slots for the {olive}Spawn Jockey{default}.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Jockey{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Jockey{default} is disabled.");
				return -2;
			}
		}
	case 13:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnSmoker));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					new clientToSpawn = 0;

					for(new i = 1; i <= MaxClients; ++i)
					{
						if(IsClientInGame(i) && (GetClientTeam(i) == T_INFECTED) && ((GetPlayerGhostStatus(i) == 1) || (GetPlayerLifeState(i) > 0)))
						{
							clientToSpawn = i;
							break;
						}
					}

					if(clientToSpawn != 0)
					{			
						if(IsFakeClient(clientToSpawn))
						{
							CheatCommand(client, "z_spawn", "smoker auto");
						}
						else if(IsPlayerAlive(clientToSpawn))
						{
							ForcePlayerSuicide(clientToSpawn);
							SetPlayerGhostStatus(clientToSpawn, true);
							Players[clientToSpawn][Ticket] = ZC_SMOKER;
							SpawnInfected(clientToSpawn, ZC_SMOKER);
							SetPlayerGhostStatus(clientToSpawn, false);
						}
						else
						{
							SpawnInfected(clientToSpawn, ZC_SMOKER);
						}
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Smoker{default}.");
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. There is not available slots for the {olive}Spawn Smoker{default}.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Smoker{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Smoker{default} is disabled.");
				return -2;
			}
		}
	case 14:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnSpitter));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					new clientToSpawn = 0;

					for(new i = 1; i <= MaxClients; ++i)
					{
						if(IsClientInGame(i) && (GetClientTeam(i) == T_INFECTED) && ((GetPlayerGhostStatus(i) == 1) || (GetPlayerLifeState(i) > 0)))
						{
							clientToSpawn = i;
							break;
						}
					}

					if(clientToSpawn != 0)
					{	
						if(IsFakeClient(clientToSpawn))
						{
							CheatCommand(client, "z_spawn", "spitter auto");
						}
						else if(IsPlayerAlive(clientToSpawn))
						{
							ForcePlayerSuicide(clientToSpawn);
							SetPlayerGhostStatus(clientToSpawn, true);
							Players[clientToSpawn][Ticket] = ZC_SPITTER;
							SpawnInfected(clientToSpawn, ZC_SPITTER);
							SetPlayerGhostStatus(clientToSpawn, false);
						}
						else
						{
							SpawnInfected(clientToSpawn, ZC_SPITTER);
						}
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Spitter{default}.");
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. There is not available slots for the {olive}Spawn Spitter{default}.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Spitter{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Spitter{default} is disabled.");
				return -2;
			}
		}
	case 15:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnTank));

			if(price >= 0)
			{
				if(TankTeamCount >= GetConVarInt(INFECTED(Limit_TankTeamLimit)))
				{
					CPrintToChat(client, "{olive}[SM]{default} The Tank limit per team has been reached. You can't spawn any more tanks.");
					return -2;
				}
				if(TankCount >= GetConVarInt(INFECTED(Limit_TankTimeLimit)))
				{
					CPrintToChat(client, "{olive}[SM]{default} The limit of alive tanks has been reached.");
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					new clientToSpawn = 0;

					for(new i = 1; i <= MaxClients; ++i)
					{
						if(IsClientInGame(i) && (GetClientTeam(i) == T_INFECTED) && ((GetPlayerGhostStatus(i) == 1) || (GetPlayerLifeState(i) > 0)))
						{
							clientToSpawn = i;
							break;
						}
					}

					if(clientToSpawn != 0)
					{	
						if(IsFakeClient(clientToSpawn))
						{
							CheatCommand(client, "z_spawn", "tank auto");
						}
						else if(IsPlayerAlive(clientToSpawn))
						{
							ForcePlayerSuicide(clientToSpawn);
							SetPlayerGhostStatus(clientToSpawn, true);
							Players[clientToSpawn][Ticket] = ZC_TANK;
							SpawnInfected(clientToSpawn, ZC_TANK);
							SetPlayerGhostStatus(clientToSpawn, false);
						}
						else
						{
							SpawnInfected(clientToSpawn, ZC_TANK);
						}
						Players[client][Points] -= price;
					
						decl String:name_[256];
						GetClientName(client, name_, sizeof(name_));
						CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Tank{default}.", name_);
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. There is not available slots for the {olive}Spawn Tank{default}.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Tank{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Tank{default} is disabled.");
				return -2;
			}
		}
	case 16:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnWitch));

			if(price >= 0)
			{
				if(WitchTeamCount >= GetConVarInt(INFECTED(Limit_WitchTeamLimit)))
				{
					CPrintToChat(client, "{olive}[SM]{default} The Witch limit per team has been reached. You can't spawn any more witches.");
					return -2;
				}
				if(WitchCount >= GetConVarInt(INFECTED(Limit_WitchTimeLimit)))
				{
					CPrintToChat(client, "{olive}[SM]{default} The limit of alive witches has been reached.");
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					if(SpawnWitch(client))
					{
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Witch{default}.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Witch{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Witch{default} is disabled.");
				return -2;
			}
		}
	case 47:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnWitchBride));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(SpawnWitchBride(client))
					{
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Witch Bride{default}.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Witch Bride{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Witch Bride{default} is disabled.");
				return -2;
			}
		}
	case 17:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnMob));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "z_spawn", "mob");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Mob{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Mob{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Mob{default} is disabled.");
				return -2;
			}
		}
	case 18:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnMegaMob));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "director_force_panic_event", "");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Mega Mob{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Mega Mob{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Mega Mob{default} is disabled.");
				return -2;
			}
		}
	case 19:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnCeda));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					InsertNewUncommonHorde(UC_CEDA);
					CheatCommand(client, "z_spawn", "mob");
					Players[client][Points] -= price;
					
					decl String:name_[256];
					GetClientName(client, name_, sizeof(name_));
					CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Spawn Ceda Horde{default}.", name_);
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Ceda Horde{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Ceda Horde{default} is disabled.");
				return -2;
			}
		}
	case 20:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnClown));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					InsertNewUncommonHorde(UC_CLOWN);
					CheatCommand(client, "z_spawn", "mob");
					Players[client][Points] -= price;
					
					decl String:name_[256];
					GetClientName(client, name_, sizeof(name_));
					CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Spawn Clown Horde{default}.", name_);
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Clown Horde{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Clown Horde{default} is disabled.");
				return -2;
			}
		}
	case 21:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnMud));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					InsertNewUncommonHorde(UC_MUD);
					CheatCommand(client, "z_spawn", "mob");
					Players[client][Points] -= price;
					
					decl String:name_[256];
					GetClientName(client, name_, sizeof(name_));
					CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Spawn Mud Horde{default}.", name_);
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Mud Horde{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Mud Horde{default} is disabled.");
				return -2;
			}
		}
	case 22:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnWorker));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					InsertNewUncommonHorde(UC_WORKER);
					CheatCommand(client, "z_spawn", "mob");
					Players[client][Points] -= price;
					
					decl String:name_[256];
					GetClientName(client, name_, sizeof(name_));
					CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Spawn Worker Horde{default}.", name_);
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Worker Horde{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Worker Horde{default} is disabled.");
				return -2;
			}
		}
	case 23:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnRiot));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					InsertNewUncommonHorde(UC_RIOT);
					CheatCommand(client, "z_spawn", "mob");
					Players[client][Points] -= price;
					
					decl String:name_[256];
					GetClientName(client, name_, sizeof(name_));
					CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Spawn Riot Horde{default}.", name_);
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Riot Horde{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Riot Horde{default} is disabled.");
				return -2;
			}
		}
	case 24:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnJimmy));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					InsertNewUncommonHorde(UC_JIMMY);
					CheatCommand(client, "z_spawn", "mob");
					Players[client][Points] -= price;
					
					decl String:name_[256];
					GetClientName(client, name_, sizeof(name_));
					CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Spawn Jimmy Horde{default}.", name_);
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Jimmy Horde{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Jimmy Horde{default} is disabled.");
				return -2;
			}
		}
	case 25:
		{
			decl price;
			switch(GetInfectedClass(client))
			{
			case ZC_BOOMER:
				price = GetConVarInt(INFECTED(Price_ResetAbility_Boom));
			case ZC_CHARGER:
				price = GetConVarInt(INFECTED(Price_ResetAbility_Char));
			case ZC_HUNTER:
				price = GetConVarInt(INFECTED(Price_ResetAbility_Hunt));
			case ZC_JOCKEY:
				price = GetConVarInt(INFECTED(Price_ResetAbility_Jock));
			case ZC_SMOKER:
				price = GetConVarInt(INFECTED(Price_ResetAbility_Smok));
			case ZC_SPITTER:
				price = GetConVarInt(INFECTED(Price_ResetAbility_Spit));
			case ZC_TANK:
				price = GetConVarInt(INFECTED(Price_ResetAbility_Tank));
			}

			if(price >= 0)
			{
				if(GetPlayerLifeState(client) > 0)
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy the {olive}Reload Ability{default} when you are dead.");
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					new ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
					SetEntPropFloat(ability, Prop_Send, "m_timestamp", 0.1);

					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Reload Ability{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Reload Ability{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Reload Ability{default} is disabled.");
				return -2;
			}
		}
	case 26:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnDumpster));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(SpawnDumpster(client))
					{
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Dumpster{default}.");

						new Float:time = GetConVarFloat(INFECTED(Price_SpawnObjectTime));
						if(time > 0.0)
							CPrintToChat(client, "{olive}[SM]{default} The object will disappear after %.1f seconds.", time);
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Dumpster{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Dumpster{default} is disabled.");
				return -2;
			}
		}
	case 27:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnCar));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(SpawnCar(client))
					{
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Car{default}.");

						new Float:time = GetConVarFloat(INFECTED(Price_SpawnObjectTime));

						if(time > 0.0)
							CPrintToChat(client, "{olive}[SM]{default} The object will disappear after %.1f seconds.", time);
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Car{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Car{default} is disabled.");
				return -2;
			}
		}
	case 28:
		{
			new price = GetConVarInt(INFECTED(Price_Extinguish));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					ExtinguishEntity(client);
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Extinguish{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Extinguish{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Extinguish{default} is disabled.");
				return -2;
			}
		}
	case 29:
		{
			new price = GetConVarInt(INFECTED(Price_God));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(GetPlayerLifeState(client) > 0)
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy the {olive}God Mode{default} when you are dead.");
						return -2;
					}
					if(Players[client][GodMode])
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You already have the {olive}God Mode{default} ability working.");
						return -2;
					}
					if(SDKHookEx(client, SDKHook_OnTakeDamage, OnTakeDamage_GodMode))
					{
						Players[client][GodMode] = 1;
						CreateTimer(GetConVarFloat(INFECTED(Price_GodInterval)), Timer_StopGodMode, client);
						Players[client][Points] -= price;

						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}God Mode{default}.");
						CPrintToChat(client, "{olive}[SM]{default} The {olive}God Mode{default} ability will be disabled after {olive}%d{default} seconds.", GetConVarInt(INFECTED(Price_GodInterval)));
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}God Mode{default} ability couldn't be applied.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}God Mode{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}God Mode{default} is disabled.");
				return -2;
			}
		}
	case 30:
		{
			new price = GetConVarInt(INFECTED(Price_Speed));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(GetPlayerLifeState(client) > 0)
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy the {olive}Super-Speed{default} when you are dead.");
						return -2;
					}
					if(Players[client][Speed])
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You already have the {olive}Super-Speed{default} ability working.");
						return -2;
					}
					if(MakeSpeed(client))
					{
						Players[client][Speed] = 1;
						CreateTimer(GetConVarFloat(INFECTED(Price_SpeedInterval)), Timer_StopSpeed, client);
						Players[client][Points] -= price;

						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Super-Speed{default}.");
						CPrintToChat(client, "{olive}[SM]{default} The {olive}Super-Speed{default} ability will be disabled after {olive}%d{default} seconds.", GetConVarInt(INFECTED(Price_SpeedInterval)));
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Super-Speed{default} ability couldn't be applied.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Super-Speed{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Super-Speed{default} is disabled.");
				return -2;
			}
		}
	case 31:
		{
			new price = GetConVarInt(INFECTED(Price_Invisibility));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(GetPlayerLifeState(client) > 0)
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy the {olive}Invisibility{default} when you are dead.");
						return -2;
					}
					if(Players[client][Inv])
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You already have the {olive}Invisibility{default} ability working.");
						return -2;
					}
					if(MakeInvisibility(client))
					{
						Players[client][Inv] = 1;
						CreateTimer(GetConVarFloat(INFECTED(Price_InvisibilityInterval)), Timer_StopInvisibility, client);
						Players[client][Points] -= price;

						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Invisibility{default}.");
						CPrintToChat(client, "{olive}[SM]{default} The {olive}Invisibility{default} ability will be disabled after {olive}%d{default} seconds.", GetConVarInt(INFECTED(Price_InvisibilityInterval)));
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Invisibility{default} ability couldn't be applied.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Invisibility{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Invisibility{default} is disabled.");
				return -2;
			}
		}
	case 32:
		{
			new price = GetConVarInt(INFECTED(Price_GiveBoomer));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(target) && !GetPlayerGhostStatus(target))
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The player you selected is alive.");
					}
					else
					{
						ForcePlayerSuicide(target);
						SetPlayerGhostStatus(target, true);
						
						Players[target][Ticket] = ZC_BOOMER;
						SpawnInfected(target, ZC_BOOMER);
						
						SetPlayerGhostStatus(target, false);
						
						Players[client][Points] -= price;
						
						GetClientName(target, targetName, sizeof(targetName));
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Boomer for %s{default}.", targetName);
						
						GetClientName(client, targetName, sizeof(targetName));
						CPrintToChat(target, "{olive}[SM]{default} You got a {olive}Boomer{default} from {olive}%s{default}.", targetName);
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Boomer for somebody{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Boomer for somebody{default} is disabled.");
				return -2;
			}
		}
	case 33:
		{
			new price = GetConVarInt(INFECTED(Price_GiveCharger));			

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(target) && !GetPlayerGhostStatus(target))
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The player you selected is alive.");
					}
					else
					{
						ForcePlayerSuicide(target);
						SetPlayerGhostStatus(target, true);
						
						Players[target][Ticket] = ZC_CHARGER;
						SpawnInfected(target, ZC_CHARGER);
						
						SetPlayerGhostStatus(target, false);
						
						Players[client][Points] -= price;
						
						GetClientName(target, targetName, sizeof(targetName));
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Charger for %s{default}.", targetName);
						
						GetClientName(client, targetName, sizeof(targetName));
						CPrintToChat(target, "{olive}[SM]{default} You got a {olive}Charger{default} from {olive}%s{default}.", targetName);
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Charger for somebody{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Charger for somebody{default} is disabled.");
				return -2;
			}
		}
	case 34:
		{
			new price = GetConVarInt(INFECTED(Price_GiveHunter));
			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(target) && !GetPlayerGhostStatus(target))
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The player you selected is alive.");
					}
					else
					{
						ForcePlayerSuicide(target);
						SetPlayerGhostStatus(target, true);
						
						Players[target][Ticket] = ZC_HUNTER;
						SpawnInfected(target, ZC_HUNTER);
						
						SetPlayerGhostStatus(target, false);
						
						Players[client][Points] -= price;
						
						GetClientName(target, targetName, sizeof(targetName));
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Hunter for %s{default}.", targetName);
						
						GetClientName(client, targetName, sizeof(targetName));
						CPrintToChat(target, "{olive}[SM]{default} You got a {olive}Hunter{default} from {olive}%s{default}.", targetName);
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Hunter for somebody{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Hunter for somebody{default} is disabled.");
				return -2;
			}
		}
	case 35:
		{
			new price = GetConVarInt(INFECTED(Price_GiveJockey));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(target) && !GetPlayerGhostStatus(target))
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The player you selected is alive.");
					}
					else
					{
						ForcePlayerSuicide(target);
						SetPlayerGhostStatus(target, true);
						
						Players[target][Ticket] = ZC_JOCKEY;
						SpawnInfected(target, ZC_JOCKEY);
						
						SetPlayerGhostStatus(target, false);
						
						Players[client][Points] -= price;
						
						GetClientName(target, targetName, sizeof(targetName));
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Jockey for %s{default}.", targetName);
						
						GetClientName(client, targetName, sizeof(targetName));
						CPrintToChat(target, "{olive}[SM]{default} You got a {olive}Jockey{default} from {olive}%s{default}.", targetName);
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Jockey for somebody{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Jockey for somebody{default} is disabled.");
				return -2;
			}
		}
	case 36:
		{
			new price = GetConVarInt(INFECTED(Price_GiveSmoker));
			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(target) && !GetPlayerGhostStatus(target))
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The player you selected is alive.");
					}
					else
					{
						ForcePlayerSuicide(target);
						SetPlayerGhostStatus(target, true);
						
						Players[target][Ticket] = ZC_SMOKER;
						SpawnInfected(target, ZC_SMOKER);
						
						SetPlayerGhostStatus(target, false);
						
						Players[client][Points] -= price;
						
						GetClientName(target, targetName, sizeof(targetName));
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Smoker for %s{default}.", targetName);
						
						GetClientName(client, targetName, sizeof(targetName));
						CPrintToChat(target, "{olive}[SM]{default} You got a {olive}Smoker{default} from {olive}%s{default}.", targetName);
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Smoker for somebody{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Smoker for somebody{default} is disabled.");
				return -2;
			}
		}
	case 37:
		{
			new price = GetConVarInt(INFECTED(Price_GiveSpitter));
			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(IsPlayerAlive(target) && !GetPlayerGhostStatus(target))
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The player you selected is alive.");
					}
					else
					{
						ForcePlayerSuicide(target);
						SetPlayerGhostStatus(target, true);
						
						Players[target][Ticket] = ZC_SPITTER;
						SpawnInfected(target, ZC_SPITTER);
						
						SetPlayerGhostStatus(target, false);
						
						Players[client][Points] -= price;
						
						GetClientName(target, targetName, sizeof(targetName));
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spawn Spitter for %s{default}.", targetName);
						
						GetClientName(client, targetName, sizeof(targetName));
						CPrintToChat(target, "{olive}[SM]{default} You got a {olive}Spitter{default} from {olive}%s{default}.", targetName);
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Spitter for somebody{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Spitter for somebody{default} is disabled.");
				return -2;
			}
		}
	case 38:
		{
			new price = GetConVarInt(INFECTED(Price_GiveTank));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					if(TankTeamCount >= GetConVarInt(INFECTED(Limit_TankTeamLimit)))
					{
						CPrintToChat(client, "{olive}[SM]{default} The Tank limit per team has been reached. You can't spawn any more tanks.");
						return -2;
					}
					if(TankCount >= GetConVarInt(INFECTED(Limit_TankTimeLimit)))
					{
						CPrintToChat(client, "{olive}[SM]{default} The limit of alive tanks has been reached.");
						return -2;
					}
					if(IsPlayerAlive(target) && !GetPlayerGhostStatus(target))
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The player you selected is alive.");
					}
					else
					{
						ForcePlayerSuicide(target);
						SetPlayerGhostStatus(target, true);
						
						Players[target][Ticket] = ZC_TANK;
						SpawnInfected(target, ZC_TANK);
						
						SetPlayerGhostStatus(target, false);
						
						Players[client][Points] -= price;
						
						decl String:name_[256];
						GetClientName(client, name_, sizeof(name_));
						CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Tank{default}.", name_);
						
						GetClientName(client, targetName, sizeof(targetName));
						CPrintToChat(target, "{olive}[SM]{default} You got a {olive}Tank{default} from {olive}%s{default}.", targetName);
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Tank for somebody{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Tank for somebody{default} is disabled.");
				return -2;
			}
		}
		
	case 39:
	{
		new price = GetConVarInt(INFECTED(Price_SquadBoomerOne));
		
		if(price >= 0)
		{
			new cnt = 0;
			
			for (new i = 1; i <= MaxClients; ++i)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
				{
					cnt++;
				}
			}
			
			if (cnt <= 1)
				price = GetConVarInt(INFECTED(Price_SpawnBoomer));
			else if (cnt == 0)
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. Couldn't find any free slots.");
				return -2;
			}
			else
				price *= cnt;
				
			if(Players[client][Points] >= price)
			{
				for (new i = 1; i <= MaxClients; ++i)
				{
					if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
					{
						ForcePlayerSuicide(i);
						SetPlayerGhostStatus(i, true);
						
						Players[i][Ticket] = ZC_BOOMER;
						SpawnInfected(i, ZC_BOOMER);
						
						SetPlayerGhostStatus(i, false);
					}
				}
				Players[client][Points] -= price;
					
				decl String:name_[256];
				GetClientName(client, name_, sizeof(name_));
				CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Boomer Squad{default}.", name_);
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Boomer Squad{default}.");
			}
		}
		else
		{
			CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Boomer Squad{default} is disabled.");
			return -2;
		}
	}
	
	case 40:
	{
		new price = GetConVarInt(INFECTED(Price_SquadChargerOne));
		
		if(price >= 0)
		{
			new cnt = 0;
			
			for (new i = 1; i <= MaxClients; ++i)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
				{
					cnt++;
				}
			}
			
			if (cnt <= 1)
				price = GetConVarInt(INFECTED(Price_SpawnCharger));
			else if (cnt == 0)
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. Couldn't find any free slots.");
				return -2;
			}
			else
				price *= cnt;
				
			if(Players[client][Points] >= price)
			{
				for (new i = 1; i <= MaxClients; ++i)
				{
					if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
					{
						ForcePlayerSuicide(i);
						SetPlayerGhostStatus(i, true);
						
						Players[i][Ticket] = ZC_CHARGER;
						SpawnInfected(i, ZC_CHARGER);
						
						SetPlayerGhostStatus(i, false);
					}
				}
				Players[client][Points] -= price;
					
				decl String:name_[256];
				GetClientName(client, name_, sizeof(name_));
				CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Charger Squad{default}.", name_);
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Charger Squad{default}.");
			}
		}
		else
		{
			CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Charger Squad{default} is disabled.");
			return -2;
		}
	}
	
	case 41:
	{
		new price = GetConVarInt(INFECTED(Price_SquadHunterOne));
		
		if(price >= 0)
		{
			new cnt = 0;
			
			for (new i = 1; i <= MaxClients; ++i)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
				{
					cnt++;
				}
			}
			
			if (cnt <= 1)
				price = GetConVarInt(INFECTED(Price_SpawnHunter));
			else if (cnt == 0)
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. Couldn't find any free slots.");
				return -2;
			}
			else
				price *= cnt;
				
			if(Players[client][Points] >= price)
			{
				for (new i = 1; i <= MaxClients; ++i)
				{
					if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
					{
						ForcePlayerSuicide(i);
						SetPlayerGhostStatus(i, true);
						
						Players[i][Ticket] = ZC_HUNTER;
						SpawnInfected(i, ZC_HUNTER);
						
						SetPlayerGhostStatus(i, false);
					}
				}
				Players[client][Points] -= price;
					
				decl String:name_[256];
				GetClientName(client, name_, sizeof(name_));
				CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Hunter Squad{default}.", name_);
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Hunter Squad{default}.");
			}
		}
		else
		{
			CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Hunter Squad{default} is disabled.");
			return -2;
		}
	}
	
	case 42:
	{
		new price = GetConVarInt(INFECTED(Price_SquadJockeyOne));
		
		if(price >= 0)
		{
			new cnt = 0;
			
			for (new i = 1; i <= MaxClients; ++i)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
				{
					cnt++;
				}
			}
			
			if (cnt <= 1)
				price = GetConVarInt(INFECTED(Price_SpawnJockey));
			else if (cnt == 0)
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. Couldn't find any free slots.");
				return -2;
			}
			else
				price *= cnt;
				
			if(Players[client][Points] >= price)
			{
				for (new i = 1; i <= MaxClients; ++i)
				{
					if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
					{
						ForcePlayerSuicide(i);
						SetPlayerGhostStatus(i, true);
						
						Players[i][Ticket] = ZC_JOCKEY;
						SpawnInfected(i, ZC_JOCKEY);
						
						SetPlayerGhostStatus(i, false);
					}
				}
				Players[client][Points] -= price;
					
				decl String:name_[256];
				GetClientName(client, name_, sizeof(name_));
				CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Jockey Squad{default}.", name_);
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Jockey Squad{default}.");
			}
		}
		else
		{
			CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Jockey Squad{default} is disabled.");
			return -2;
		}
	}
	
	case 43:
	{
		new price = GetConVarInt(INFECTED(Price_SquadSmokerOne));
		
		if(price >= 0)
		{
			new cnt = 0;
			
			for (new i = 1; i <= MaxClients; ++i)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
				{
					cnt++;
				}
			}
			
			if (cnt <= 1)
				price = GetConVarInt(INFECTED(Price_SpawnSmoker));
			else if (cnt == 0)
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. Couldn't find any free slots.");
				return -2;
			}
			else
				price *= cnt;
				
			if(Players[client][Points] >= price)
			{
				for (new i = 1; i <= MaxClients; ++i)
				{
					if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
					{
						ForcePlayerSuicide(i);
						SetPlayerGhostStatus(i, true);
						
						Players[i][Ticket] = ZC_SMOKER;
						SpawnInfected(i, ZC_SMOKER);
						
						SetPlayerGhostStatus(i, false);
					}
				}
				Players[client][Points] -= price;
					
				decl String:name_[256];
				GetClientName(client, name_, sizeof(name_));
				CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Smoker Squad{default}.", name_);
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Smoker Squad{default}.");
			}
		}
		else
		{
			CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Smoker Squad{default} is disabled.");
			return -2;
		}
	}
	
	case 44:
	{
		new price = GetConVarInt(INFECTED(Price_SquadSpitterOne));
		
		if(price >= 0)
		{
			new cnt = 0;
			
			for (new i = 1; i <= MaxClients; ++i)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
				{
					cnt++;
				}
			}
			
			if (cnt <= 1)
				price = GetConVarInt(INFECTED(Price_SpawnSpitter));
			else if (cnt == 0)
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. Couldn't find any free slots.");
				return -2;
			}
			else
				price *= cnt;
				
			if(Players[client][Points] >= price)
			{
				for (new i = 1; i <= MaxClients; ++i)
				{
					if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
					{
						ForcePlayerSuicide(i);
						SetPlayerGhostStatus(i, true);
						
						Players[i][Ticket] = ZC_SPITTER;
						SpawnInfected(i, ZC_SPITTER);
						
						SetPlayerGhostStatus(i, false);
					}
				}
				
				Players[client][Points] -= price;
					
				decl String:name_[256];
				GetClientName(client, name_, sizeof(name_));
				CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Spitter Squad{default}.", name_);
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Spitter Squad{default}.");
			}
		}
		else
		{
			CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Spitter Squad{default} is disabled.");
			return -2;
		}
	}
	
	case 45:
	{
		new price = GetConVarInt(INFECTED(Price_SquadTankOne));
		
		if(price >= 0)
		{
			new cnt = 0;
			
			for (new i = 1; i <= MaxClients; ++i)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
				{
					cnt++;
				}
			}
			
			if (cnt <= 1)
				price = GetConVarInt(INFECTED(Price_SpawnTank));
			else if (cnt == 0)
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. Couldn't find any free slots.");
				return -2;
			}
			else
				price *= cnt;
				
			if(Players[client][Points] >= price)
			{
				for (new i = 1; i <= MaxClients; ++i)
				{
					if (IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 3) && (!IsPlayerAlive(i) || GetPlayerGhostStatus(i)))
					{
						ForcePlayerSuicide(i);
						SetPlayerGhostStatus(i, true);
						
						Players[i][Ticket] = ZC_TANK;
						SpawnInfected(i, ZC_TANK);
						
						SetPlayerGhostStatus(i, false);
					}
				}
				
				Players[client][Points] -= price;
					
				decl String:name_[256];
				GetClientName(client, name_, sizeof(name_));
				CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Tank Squad{default}.", name_);
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Tank Squad{default}.");
			}
		}
		else
		{
			CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Tank Squad{default} is disabled.");
			return -2;
		}
	}
	case 46:
		{
			new price = GetConVarInt(INFECTED(Price_SpawnFa));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					InsertNewUncommonHorde(UC_FA);
					CheatCommand(client, "z_spawn", "mob");
					Players[client][Points] -= price;
					
					decl String:name_[256];
					GetClientName(client, name_, sizeof(name_));
					CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Spawn Fallen Survivor Horde{default}.", name_);
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spawn Fallen Survivor Horde{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spawn Fallen Survivor Horde{default} is disabled.");
				return -2;
			}
		}
	
	case 50:
		{
			new price = GetConVarInt(INFECTED(Price_Random));

			if(price >= 0)
			{
				if(Players[client][Points] >= price)
				{
					new oldPoints2 = Players[client][Points];
					new oldPoints = Players[client][Points] - price;
					Players[client][Points] = 999;
					SetRandomSeed(RoundFloat(GetEngineTime() * 1000.0));

					new lastState = 0;

					for(new x = 0; x < 8; ++x)
					{
						SetRandomSeed(RoundFloat(GetEngineTime() * 1000.0 * float(x)));
						if((lastState = OnInfectedBuy(client, GetRandomInt(0, 31), -1)) != -2)
							break;
					}

					if(lastState != -2)
						Players[client][Points] = oldPoints;
					else
					{
						Players[client][Points] = oldPoints2;
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Random item{default} failed.");
					}

					Players[client][Points] = oldPoints;
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Random item{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Random item{default} is disabled.");
				return -2;
			}
		}
	default:
		{
			CPrintToChat(client, "{olive}[SM]{default} Invalid item identifier.");
			return -2;
		}
	}
	
	if (!((index >= 32) && (index <= 38)))
		Players[client][LastItem] = index;
		
	return 0;
}
public OnSurvivorBuy(client, index, add, inBody)
{
	if(GetClientTeam(client) != T_SURVIVOR)
		CPrintToChat(client, "{olive}[SM]{default} You selected item for wrong team.");

	switch(index)
	{
	case 0:
		{
			new price = GetConVarInt(SURVIVOR(Price_SelfHealing));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_SelfHealing_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "health");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Healing{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Healing{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Healing{default} is disabled.");
				return -2;
			}
		}
	case 1:
		{
			new price = GetConVarInt(SURVIVOR(Price_GroupHealing));

			if((price > 0) || (price == -2))
			{
				if(price == -2)
				{
					price = GetConVarInt(SURVIVOR(Price_GroupHealingValue));

					new newPrice = 0;

					for(new i = 1; i <= MaxClients; ++i)
						if(IsClientInGame(i) && (GetClientTeam(i) == T_SURVIVOR) && IsPlayerAlive(i))
							newPrice += price;

					price = newPrice;

					new selfPrice = GetConVarInt(SURVIVOR(Price_SelfHealing));
					price = ((price > selfPrice) ? price : selfPrice);
				}

				if (GetConVarInt(SURVIVOR(Price_GroupHealing_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					for(new i = 1; i <= MaxClients; ++i)
						if(IsClientInGame(i) && (GetClientTeam(i) == T_SURVIVOR) && IsPlayerAlive(i))
							CheatCommand(i, "give", "health");

					Players[client][Points] -= price;
					decl String:name_[256];
					GetClientName(client, name_, sizeof(name_));
					CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Group Healing{default}.", name_);
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Healing{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group Healing{default} is disabled.");
				return -2;
			}
		}
	case 2:
		{
			new price = GetConVarInt(SURVIVOR(Price_Ammo));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Ammo_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					decl String:weaponName[32];

					new weapon = GetPlayerWeaponSlot(client, 0);

					if(IsValidEdict(weapon))
					{
						GetEdictClassname(weapon, weaponName, sizeof(weaponName));

						if(StrEqual(weaponName, "weapon_grenade_launcher", false))
						{
							RemoveEdict(weapon);
							CheatCommand(client, "give", "grenade_launcher");
						}
						else if(StrEqual(weaponName, "weapon_m60", false))
						{
							RemoveEdict(weapon);
							CheatCommand(client, "give", "m60");
						}
						else
						{
							CheatCommand(client, "give", "ammo");
						}

						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Ammo{default}.");
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You don't have a weapon that you can refill.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Ammo{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Ammo{default} is disabled.");
				return -2;
			}
		}
	case 3:
		{
			new price = GetConVarInt(SURVIVOR(Price_LaserSight));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_LaserSight_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "upgrade_add", "laser_sight");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Laser sight{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Laser sight{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Laser sight{default} is disabled.");
				return -2;
			}
		}
	case 4:
		{
			new price = GetConVarInt(SURVIVOR(Price_IncendiaryAmmo));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_IncendiaryAmmo_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "upgrade_add", "incendiary_ammo");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Incendiary ammo{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Incendiary ammo{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Incendiary ammo{default} is disabled.");
				return -2;
			}
		}
	case 5:
		{
			new price = GetConVarInt(SURVIVOR(Price_ExplosiveAmmo));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_ExplosiveAmmo_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "upgrade_add", "explosive_ammo");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Explosive ammo{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Explosive ammo{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Explosive ammo{default} is disabled.");
				return -2;
			}
		}
	case 6:
		{
			new price = GetConVarInt(SURVIVOR(Price_Adrenaline));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Adrenaline_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "adrenaline");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Adrenaline{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Adrenaline{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Adrenaline{default} is disabled.");
				return -2;
			}
		}
	case 7:
		{
			new price = GetConVarInt(SURVIVOR(Price_PainPills));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_PainPills_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "pain_pills");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Pain pills{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Pain pills{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Pain pills{default} is disabled.");
				return -2;
			}
		}
	case 8:
		{
			new price = GetConVarInt(SURVIVOR(Price_FirstAidkit));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_FirstAidkit_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "first_aid_kit");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}First aid kit{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}First aid kit{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}First aid kit{default} is disabled.");
				return -2;
			}
		}
	case 9:
		{
			new price = GetConVarInt(SURVIVOR(Price_Defibrillator));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Defibrillator_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "defibrillator");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Defibrillator{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Defibrillator{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Defibrillator{default} is disabled.");
				return -2;
			}
		}
	case 10:
		{
			new price = GetConVarInt(SURVIVOR(Price_BileBomb));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_BileBomb_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "vomitjar");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Bile bomb{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Bile bomb{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Bile bomb{default} is disabled.");
				return -2;
			}
		}
	case 11:
		{
			new price = GetConVarInt(SURVIVOR(Price_PipeBomb));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_PipeBomb_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "pipe_bomb");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Pipe bomb{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Pipe bomb{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Pipe bomb{default} is disabled.");
				return -2;
			}
		}
	case 12:
		{
			new price = GetConVarInt(SURVIVOR(Price_Molotov));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Molotov_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "molotov");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Molotov{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Molotov{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Molotov{default} is disabled.");
				return -2;
			}
		}
	case 13:
		{
			new price = GetConVarInt(SURVIVOR(Price_Pistol));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Pistol_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "pistol");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Pistol{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Pistol{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Pistol{default} is disabled.");
				return -2;
			}
		}
	case 14:
		{
			new price = GetConVarInt(SURVIVOR(Price_MagnumPistol));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_MagnumPistol_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "pistol_magnum");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Magnum{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Magnum{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Magnum{default} is disabled.");
				return -2;
			}
		}
	case 15:
		{
			new price = GetConVarInt(SURVIVOR(Price_ChromeShotgun));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_ChromeShotgun_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "shotgun_chrome");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Chrome Shotgun{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Chrome Shotgun{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Chrome Shotgun{default} is disabled.");
				return -2;
			}
		}
	case 16:
		{
			new price = GetConVarInt(SURVIVOR(Price_PumpShotgun));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_PumpShotgun_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "pumpshotgun");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Pump Shotgun{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Pump Shotgun{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Pump Shotgun{default} is disabled.");
				return -2;
			}
		}
	case 17:
		{
			new price = GetConVarInt(SURVIVOR(Price_AutoShotgun));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_AutoShotgun_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "autoshotgun");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Auto Shotgun{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Auto Shotgun{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Auto Shotgun{default} is disabled.");
				return -2;
			}
		}
	case 18:
		{
			new price = GetConVarInt(SURVIVOR(Price_SpasShotgun));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_SpasShotgun_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "shotgun_spas");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Spas Shotgun{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Spas Shotgun{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Spas Shotgun{default} is disabled.");
				return -2;
			}
		}
	case 19:
		{
			new price = GetConVarInt(SURVIVOR(Price_Smg));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Smg_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "smg");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}SMG{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}SMG{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}SMG{default} is disabled.");
				return -2;
			}
		}
	case 20:
		{
			new price = GetConVarInt(SURVIVOR(Price_Silent_Smg));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Silent_Smg_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "smg_silenced");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Silent SMG{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Silent SMG{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Silent SMG{default} is disabled.");
				return -2;
			}
		}
	case 21:
		{
			new price = GetConVarInt(SURVIVOR(Price_CombatRifle));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_CombatRifle_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "rifle");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Combat Rifle{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Combat Rifle{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Combat Rifle{default} is disabled.");
				return -2;
			}
		}
	case 22:
		{
			new price = GetConVarInt(SURVIVOR(Price_Ak47Rifle));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Ak47Rifle_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "rifle_ak47");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Ak47 Rifle{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Ak47 Rifle{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Ak47 Rifle{default} is disabled.");
				return -2;
			}
		}
	case 23:
		{
			new price = GetConVarInt(SURVIVOR(Price_DesertRifle));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_DesertRifle_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "rifle_desert");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Desert Rifle{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Desert Rifle{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Desert Rifle{default} is disabled.");
				return -2;
			}
		}
	case 24:
		{
			new price = GetConVarInt(SURVIVOR(Price_HuntingRifle));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_HuntingRifle_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "hunting_rifle");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Hunting Rifle{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Hunting Rifle{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Hunting Rifle{default} is disabled.");
				return -2;
			}
		}
	case 25:
		{
			new price = GetConVarInt(SURVIVOR(Price_SniperRifle));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_SniperRifle_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "sniper_military");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Sniper Rifle{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Sniper Rifle{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Sniper Rifle{default} is disabled.");
				return -2;
			}
		}
	case 26:
		{
			new price = GetConVarInt(SURVIVOR(Price_GrenadeLauncher));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_GrenadeLauncher_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "grenade_launcher");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Grenade Launcher{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Grenade Launcher{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Grenade Launcher{default} is disabled.");
				return -2;
			}
		}
	case 27:
		{
			new price = GetConVarInt(SURVIVOR(Price_M60HeavyRifle));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_M60HeavyRifle_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "rifle_m60");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}M60 Heavy Rifle{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}M60 Heavy Rifle{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}M60 Heavy Rifle{default} is disabled.");
				return -2;
			}
		}
	case 28:
		{
			new price = GetConVarInt(SURVIVOR(Price_GolfClub));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_GolfClub_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "golfclub");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Golf Club{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Golf Club{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Golf Club{default} is disabled.");
				return -2;
			}
		}
	case 29:
		{
			new price = GetConVarInt(SURVIVOR(Price_FireAxe));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_FireAxe_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "fireaxe");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Fire Axe{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Fire Axe{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Fire Axe{default} is disabled.");
				return -2;
			}
		}
	case 30:
		{
			new price = GetConVarInt(SURVIVOR(Price_Katana));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Katana_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "katana");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Katana{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Katana{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Katana{default} is disabled.");
				return -2;
			}
		}
	case 31:
		{
			new price = GetConVarInt(SURVIVOR(Price_Crowbar));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Crowbar_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "crowbar");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Crowbar{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Crowbar{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Crowbar{default} is disabled.");
				return -2;
			}
		}
	case 32:
		{
			new price = GetConVarInt(SURVIVOR(Price_FryingPan));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_FryingPan_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "frying_pan");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Frying Pan{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Frying Pan{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Frying Pan{default} is disabled.");
				return -2;
			}
		}
	case 33:
		{
			new price = GetConVarInt(SURVIVOR(Price_Guitar));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Guitar_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "electric_guitar");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Electric Guitar{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Electric Guitar{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Electric Guitar{default} is disabled.");
				return -2;
			}
		}
	case 34:
		{
			new price = GetConVarInt(SURVIVOR(Price_BaseballBat));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_BaseballBat_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "baseball_bat");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Baseball Bat{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Baseball Bat{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Baseball Bat{default} is disabled.");
				return -2;
			}
		}
	case 35:
		{
			new price = GetConVarInt(SURVIVOR(Price_Machete));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Machete_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "machete");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Machete{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Machete{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Machete{default} is disabled.");
				return -2;
			}
		}
	case 36:
		{
			new price = GetConVarInt(SURVIVOR(Price_Chainsaw));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Chainsaw_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "chainsaw");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Chainsaw{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Chainsaw{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Chainsaw{default} is disabled.");
				return -2;
			}
		}
	case 37:
		{
			new price = GetConVarInt(SURVIVOR(Price_Oxygentank));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Oxygentank_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "oxygentank");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Oxygen Tank{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Oxygen Tank{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Oxygen Tank{default} is disabled.");
				return -2;
			}
		}
	case 38:
		{
			new price = GetConVarInt(SURVIVOR(Price_Propanetank));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Propanetank_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "propanetank");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Propane Tank{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Propane Tank{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Propane Tank{default} is disabled.");
				return -2;
			}
		}
	case 39:
		{
			new price = GetConVarInt(SURVIVOR(Price_Gascan));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Gascan_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "gascan");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Gas Can{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Gas Can{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Gas Can{default} is disabled.");
				return -2;
			}
		}
	case 40:
		{
			new price = GetConVarInt(SURVIVOR(Price_FireworksCrate));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_FireworksCrate_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "fireworkcrate");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Fireworks Crate{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Fireworks Crate{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Fireworks Crate{default} is disabled.");
				return -2;
			}
		}
	case 41:
		{
			new price = GetConVarInt(SURVIVOR(Price_IncendiaryAmmoPack));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_IncendiaryAmmoPack_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "upgradepack_incendiary");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Incendiary Ammo Pack{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Incendiary Ammo Pack{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Incendiary Ammo Pack{default} is disabled.");
				return -2;
			}
		}
	case 42:
		{
			new price = GetConVarInt(SURVIVOR(Price_ExplosiveAmmoPack));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_ExplosiveAmmoPack_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					CheatCommand(client, "give", "upgradepack_explosive");
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Explosive Ammo Pack{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Explosive Ammo Pack{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Explosive Ammo Pack{default} is disabled.");
				return -2;
			}
		}
	case 43:
		{
			new price = GetConVarInt(SURVIVOR(Price_AmmoPile));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_AmmoPile_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					if(SpawnAmmoPile(client))
					{
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Ammo Pile{default}.");

						new Float:time = GetConVarFloat(SURVIVOR(Price_AmmoPileTime));
						if(time > 0.0)
							CPrintToChat(client, "{olive}[SM]{default} The object will disappear after %.1f seconds.", time);
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. System couldn't spawn an object.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Ammo Pile{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Ammo Pile{default} is disabled.");
				return -2;
			}
		}
	case 44:
		{
			new price = GetConVarInt(SURVIVOR(Price_Suicide));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Suicide_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					if(pinned[client] == true)
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You can't buy {olive}Suicide{default} when you are being attacked by special infected.");
					}
					else
					{
						ApplyDamage(client, 10000);

						if(IsPlayerAlive(client))
							CreateTimer(0.1, SuicideTimer, client);

						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Suicide{default}.");
						Players[client][Points] -= price;
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Suicide{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Suicide{default} is disabled.");
				return -2;
			}
		}
	case 45:
		{
			new price = GetConVarInt(SURVIVOR(Price_God));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_God_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					if(GetPlayerLifeState(client) > 0)
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy the {olive}God Mode{default} when you are dead.");
						return -2;
					}
					if(Players[client][GodMode])
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You already have the {olive}God Mode{default} ability working.");
						return -2;
					}
					if(SDKHookEx(client, SDKHook_OnTakeDamage, OnTakeDamage_GodMode))
					{
						Players[client][GodMode] = 1;
						CreateTimer(GetConVarFloat(SURVIVOR(Price_GodInterval)), Timer_StopGodMode, client);
						Players[client][Points] -= price;

						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}God Mode{default}.");
						CPrintToChat(client, "{olive}[SM]{default} The {olive}God Mode{default} ability will be disabled after {olive}%d{default} seconds.", GetConVarInt(INFECTED(Price_GodInterval)));
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}God Mode{default} ability couldn't be applied.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}God Mode{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}God Mode{default} is disabled.");
				return -2;
			}
		}
	case 46:
		{
			new price = GetConVarInt(SURVIVOR(Price_Speed));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Speed_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					if(GetPlayerLifeState(client) > 0)
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy the {olive}Super-Speed{default} when you are dead.");
						return -2;
					}
					if(Players[client][Speed])
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You already have the {olive}Super-Speed{default} ability working.");
						return -2;
					}
					if(MakeSpeed(client))
					{
						Players[client][Speed] = 1;
						CreateTimer(GetConVarFloat(SURVIVOR(Price_SpeedInterval)), Timer_StopSpeed, client);
						Players[client][Points] -= price;

						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Super-Speed{default}.");
						CPrintToChat(client, "{olive}[SM]{default} The {olive}Super-Speed{default} ability will be disabled after {olive}%d{default} seconds.", GetConVarInt(SURVIVOR(Price_SpeedInterval)));
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Super-Speed{default} ability couldn't be applied.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Super-Speed{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Super-Speed{default} is disabled.");
				return -2;
			}
		}
	case 47:
		{
			new price = GetConVarInt(SURVIVOR(Price_Slow));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Slow_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					if(GetPlayerLifeState(client) > 0)
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy the {olive}Slow Motion{default} when you are dead.");
						return -2;
					}
					if(isSlow)
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. There is already one {olive}Slow Motion{default} ability working.");
						return -2;
					}
					if(MakeSlow(client))
					{
						CreateTimer(GetConVarFloat(SURVIVOR(Price_SlowInterval)), Timer_StopSlow, client);
						Players[client][Points] -= price;

						decl String:name[96];
						GetClientName(client, name, sizeof(name));

						CPrintToChatAll("{olive}[SM]{default} %s have bought the {olive}Slow Motion{default} ability!", name);
						CPrintToChatAll("{olive}[SM]{default} The {olive}Slow Motion{default} ability will be disabled after {olive}%d{default} seconds.", GetConVarInt(SURVIVOR(Price_SlowInterval)));

						isSlow = true;
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Slow Motion{default} ability couldn't be applied.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Slow Motion{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Slow Motion{default} is disabled.");
				return -2;
			}
		}
	case 48:
		{
			new price = GetConVarInt(SURVIVOR(Price_Barrel));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Barrel_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					if(SpawnBarrel(client))
					{
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Explosive Barrel{default}.");
					}
					else
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. System couldn't spawn an object.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Explosive Barrel{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Explosive Barrel{default} is disabled.");
				return -2;
			}
		}
	case 51:
		{
			new price = GetConVarInt(SURVIVOR(Price_SelfRes));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_SelfRes_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}Resurrection{default} when you are dead.");
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					if (IsPlayerAlive(client))
						CPrintToChat(client, "{olive}[SM]{default} Sorry. You are alive so you don't need to use the {olive}Resurrection{default}.");
					else if(ResPlayer(client, inBody))
					{
						Players[client][Points] -= price;
						CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Resurrection{default}.");
					}
					else
						CPrintToChat(client, "{olive}[SM]{default} Sorry. An internal error happend when using the {olive}Resurrection{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Resurrection{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Resurrection{default} is disabled.");
				return -2;
			}
		}
	case 52:
		{
			new price = GetConVarInt(SURVIVOR(Price_GroupRes));

			if((price > 0) || (price == -2))
			{
				if(price == -2)
				{
					price = GetConVarInt(SURVIVOR(Price_GroupResValue));

					new newPrice = 0;

					for(new i = 1; i <= MaxClients; ++i)
						if(IsClientInGame(i) && (GetClientTeam(i) == T_SURVIVOR) && !IsPlayerAlive(i))
							newPrice += price;

					price = newPrice;
				}

				if (GetConVarInt(SURVIVOR(Price_GroupRes_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}Group Resurrection{default} when you are dead.");
					return -2;
				}
				if (price == 0)
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. There is no dead players who can be resurrected.");
					return 0;
				}
				if(Players[client][Points] >= price)
				{
					if (RSP_PLAYER == INVALID_HANDLE)
					{
						CPrintToChat(client, "{olive}[SM]{default} Sorry. An internal error happend when using the {olive}Resurrection{default}.");
						return -2;
					}
					for(new i = 1; i <= MaxClients; ++i)
						if(IsClientInGame(i) && (GetClientTeam(i) == T_SURVIVOR) && !IsPlayerAlive(i))
							ResPlayer(i, false);

					Players[client][Points] -= price;
					decl String:name_[256];
					GetClientName(client, name_, sizeof(name_));
					CPrintToChatAll("{olive}[SM]{default} %s bought the {olive}Group Resurrection{default}.", name_);
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Resurrection{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group Resurrection{default} is disabled.");
				return -2;
			}
		}
	case 50:
		{
			new price = GetConVarInt(SURVIVOR(Price_Random));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Random_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}Random item{default} when you are dead.");
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					new oldPoints2 = Players[client][Points];
					new oldPoints = Players[client][Points] - price;
					Players[client][Points] = 999;

					SetRandomSeed(RoundFloat(GetEngineTime() * 1000.0));

					new lastState = 0;
					new jj = 0;
					for(new x = 0; x < 8; ++x)
					{
						SetRandomSeed(RoundFloat(GetEngineTime() * 1000.0 * float(x)));
						jj = GetRandomInt(0, 52);
						
						if (jj == 50)
							continue;
						
						if((lastState = OnSurvivorBuy(client, jj, -1, true)) != -2)
							break;
					}

					if(lastState != -2)
						Players[client][Points] = oldPoints;
					else
					{
						Players[client][Points] = oldPoints2;
						CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Random item{default} failed.");
					}
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Random item{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Random item{default} is disabled.");
			}
		}
		
		
	case 53:
		{
			new price = GetConVarInt(SURVIVOR(Price_GroupAmmo));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Ammo_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				
				new j = 0;
				
				for (new i = 1; i <= MaxClients; ++i)
					if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						++j;
						
				price *= j;
				
				if(Players[client][Points] >= price)
				{
					decl String:weaponName[32];
					decl String:_name[96];
					
					GetClientName(client, _name, sizeof(_name));
					
					for (new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						{

							new weapon = GetPlayerWeaponSlot(i, 0);

							if(IsValidEdict(weapon))
							{
								GetEdictClassname(weapon, weaponName, sizeof(weaponName));

								if(StrEqual(weaponName, "weapon_grenade_launcher", false))
								{
									RemoveEdict(weapon);
									CheatCommand(i, "give", "grenade_launcher");
								}
								else if(StrEqual(weaponName, "weapon_m60", false))
								{
									RemoveEdict(weapon);
									CheatCommand(i, "give", "m60");
								}
								else
								{
									CheatCommand(i, "give", "ammo");
								}
								
								if (!IsFakeClient(i))
									CPrintToChat(i, "{olive}[SM]{default} You got the {olive}Ammo{default} from %s.", _name);
							}
						}
					}
					
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Group Ammo{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Ammo{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group Ammo{default} is disabled.");
				return -2;
			}
		}
	case 54:
		{
					decl String:_name[96];
			new price = GetConVarInt(SURVIVOR(Price_GroupLaserSight));

			if(price >= 0)
			{
				new j = 0;
				
				for (new i = 1; i <= MaxClients; ++i)
					if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						++j;
						
				price *= j;
				
				if (GetConVarInt(SURVIVOR(Price_LaserSight_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					for (new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						{
							CheatCommand(i, "upgrade_add", "laser_sight");
							
							if (!IsFakeClient(i))
								CPrintToChat(i, "{olive}[SM]{default} You got the {olive}Laser Sight{default} from %s.", _name);
						}
					}
					
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Laser sight{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Laser sight{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Laser sight{default} is disabled.");
				return -2;
			}
		}
	case 55:
		{
					decl String:_name[96];
			new price = GetConVarInt(SURVIVOR(Price_GroupIncendiaryAmmo));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_IncendiaryAmmo_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					for (new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						{
							CheatCommand(i, "upgrade_add", "incendiary_ammo");
							
							if (!IsFakeClient(i))
								CPrintToChat(i, "{olive}[SM]{default} You got the {olive}Incendiary ammo{default} from %s.", _name);
						}
					}
					
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Group Incendiary ammo{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Incendiary ammo{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group Incendiary ammo{default} is disabled.");
				return -2;
			}
		}
	case 56:
		{
					decl String:_name[96];
			new price = GetConVarInt(SURVIVOR(Price_GroupExplosiveAmmo));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_ExplosiveAmmo_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					for (new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						{
							CheatCommand(i, "upgrade_add", "explosive_ammo");
							
							if (!IsFakeClient(i))
								CPrintToChat(i, "{olive}[SM]{default} You got the {olive}Explosive ammo{default} from %s.", _name);
						}
					}
					
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Group Explosive ammo{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Explosive ammo{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group Explosive ammo{default} is disabled.");
				return -2;
			}
		}
	case 57:
		{
					decl String:_name[96];
			new price = GetConVarInt(SURVIVOR(Price_GroupAdrenaline));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Adrenaline_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					for (new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						{
							CheatCommand(i, "give", "adrenaline");
							
							if (!IsFakeClient(i))
								CPrintToChat(i, "{olive}[SM]{default} You got the {olive}Adrenaline{default} from %s.", _name);
						}
					}
					
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Group Adrenaline{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Adrenaline{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group Adrenaline{default} is disabled.");
				return -2;
			}
		}
	case 58:
		{
					decl String:_name[96];
			new price = GetConVarInt(SURVIVOR(Price_GroupPainPills));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_PainPills_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					for (new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						{
							CheatCommand(i, "give", "pain_pills");
							
							if (!IsFakeClient(i))
								CPrintToChat(i, "{olive}[SM]{default} You got the {olive}Pain pills{default} from %s.", _name);
						}
					}
					
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Group Pain pills{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Pain pills{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group Pain pills{default} is disabled.");
				return -2;
			}
		}
	case 59:
		{
					decl String:_name[96];
			new price = GetConVarInt(SURVIVOR(Price_GroupFirstAidkit));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_FirstAidkit_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					for (new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						{
							CheatCommand(i, "give", "first_aid_kit");
							
							if (!IsFakeClient(i))
								CPrintToChat(i, "{olive}[SM]{default} You got the {olive}First aid kit{default} from %s.", _name);
						}
					}
					
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Group First aid kit{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group First aid kit{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group First aid kit{default} is disabled.");
				return -2;
			}
		}
	case 60:
		{
					decl String:_name[96];
			new price = GetConVarInt(SURVIVOR(Price_GroupDefibrillator));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Defibrillator_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					for (new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						{
							CheatCommand(i, "give", "defibrillator");
							
							if (!IsFakeClient(i))
								CPrintToChat(i, "{olive}[SM]{default} You got the {olive}Defibrillator{default} from %s.", _name);
						}
					}
					
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Group Defibrillator{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Defibrillator{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group Defibrillator{default} is disabled.");
				return -2;
			}
		}
	case 61:
		{
					decl String:_name[96];
			new price = GetConVarInt(SURVIVOR(Price_GroupBileBomb));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_BileBomb_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					for (new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						{
							CheatCommand(i, "give", "vomitjar");
							
							if (!IsFakeClient(i))
								CPrintToChat(i, "{olive}[SM]{default} You got the {olive}Bile bomb{default} from %s.", _name);
						}
					}
					
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Group Bile bomb{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Bile bomb{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group Bile bomb{default} is disabled.");
				return -2;
			}
		}
	case 62:
		{
					decl String:_name[96];
			new price = GetConVarInt(SURVIVOR(Price_GroupPipeBomb));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_PipeBomb_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					for (new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						{
							CheatCommand(i, "give", "pipe_bomb");
							
							if (!IsFakeClient(i))
								CPrintToChat(i, "{olive}[SM]{default} You got the {olive}Pipe bomb{default} from %s.", _name);
						}
					}
					
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Group Pipe bomb{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Pipe bomb{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group Pipe bomb{default} is disabled.");
				return -2;
			}
		}
	case 63:
		{
					decl String:_name[96];
			new price = GetConVarInt(SURVIVOR(Price_GroupMolotov));

			if(price >= 0)
			{
				if (GetConVarInt(SURVIVOR(Price_Molotov_Dead)) == 0 && !IsPlayerAlive(client))
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You cannot buy {olive}%s{default} when you are dead.", SurvivorItemName[index]);
					return -2;
				}
				if(Players[client][Points] >= price)
				{
					for (new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
						{
							CheatCommand(i, "give", "molotov");
							
							if (!IsFakeClient(i))
								CPrintToChat(i, "{olive}[SM]{default} You got the {olive}Molotov{default} from %s.", _name);
						}
					}
					
					Players[client][Points] -= price;
					CPrintToChat(client, "{olive}[SM]{default} You bought the {olive}Group Molotov{default}.");
				}
				else
				{
					CPrintToChat(client, "{olive}[SM]{default} Sorry. You have not enough points for the {olive}Group Molotov{default}.");
				}
			}
			else
			{
				CPrintToChat(client, "{olive}[SM]{default} Sorry. The {olive}Group Molotov{default} is disabled.");
				return -2;
			}
		}
		
	default:
		{
			CPrintToChat(client, "{olive}[SM]{default} Invalid item identifier.");
			return -2;
		}
	}
	Players[client][LastItem] = index;
	return 0;
}

public Action:SuicideTimer(Handle:timer, any:client)
{
	ApplyDamage(client, 10000);
}
