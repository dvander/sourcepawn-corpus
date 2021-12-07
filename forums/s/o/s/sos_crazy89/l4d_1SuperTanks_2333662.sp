#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.3.2"

#define FFADE_IN 0x0001
#define FFADE_OUT 0x0002
#define FFADE_MODULATE 0x0004
#define FFADE_STAYOUT 0x0008
#define FFADE_PURGE 0x0010

#define PARTICLE_SPAWN		"smoker_smokecloud"
#define PARTICLE_FIRE		"aircraft_destroy_fastFireTrail"
#define PARTICLE_WARP		"electrical_arc_01_system"
#define PARTICLE_ICE		"steam_manhole"
#define PARTICLE_SPIT		"spitter_areaofdenial_glow2"
#define PARTICLE_SPITPROJ	"spitter_projectile"
#define PARTICLE_ELEC		"electrical_arc_01_parent"
#define PARTICLE_BLOOD		"boomer_explode_D"
#define PARTICLE_EXPLODE	"boomer_explode"
#define PARTICLE_METEOR		"smoke_medium_01"

/*Arrays*/
new TankAlive[MAXPLAYERS+1];
new TankAbility[MAXPLAYERS+1];
new Rock[MAXPLAYERS+1];
new ShieldsUp[MAXPLAYERS+1];
new PlayerSpeed[MAXPLAYERS+1];

/*
Super Tanks:
1)Spawn
2)Smasher
3)Warp
4)Meteor
5)Spitter
6)Heal
7)Fire
8)Ice
9)Jockey
10)Ghost
11)Shock
12)Witch
13)Shield
14)Cobalt
15)Jumper
16)Gravity
*/

/*Misc*/
new iTankWave;
new iNumTanks;
new iFrame;
new iTick;

/*Handles*/
new Handle:hSuperTanksEnabled = INVALID_HANDLE;
new Handle:hDisplayHealthCvar = INVALID_HANDLE;
new Handle:hWave1Cvar = INVALID_HANDLE;
new Handle:hWave2Cvar = INVALID_HANDLE;
new Handle:hWave3Cvar = INVALID_HANDLE;
new Handle:hFinaleOnly = INVALID_HANDLE;
new Handle:hDefaultTanks = INVALID_HANDLE;
new Handle:hGamemodeCvar = INVALID_HANDLE;

new Handle:hDefaultOverride = INVALID_HANDLE;
new Handle:hDefaultExtraHealth = INVALID_HANDLE;
new Handle:hDefaultSpeed = INVALID_HANDLE;
new Handle:hDefaultThrow = INVALID_HANDLE;
new Handle:hDefaultFireImmunity = INVALID_HANDLE;

new Handle:hSpawnEnabled = INVALID_HANDLE;
new Handle:hSpawnExtraHealth = INVALID_HANDLE;
new Handle:hSpawnSpeed = INVALID_HANDLE;
new Handle:hSpawnThrow = INVALID_HANDLE;
new Handle:hSpawnFireImmunity = INVALID_HANDLE;
new Handle:hSpawnCommonAmount = INVALID_HANDLE;
new Handle:hSpawnCommonInterval = INVALID_HANDLE;

new Handle:hSmasherEnabled = INVALID_HANDLE;
new Handle:hSmasherExtraHealth = INVALID_HANDLE;
new Handle:hSmasherSpeed = INVALID_HANDLE;
new Handle:hSmasherThrow = INVALID_HANDLE;
new Handle:hSmasherFireImmunity = INVALID_HANDLE;
new Handle:hSmasherMaimDamage = INVALID_HANDLE;
new Handle:hSmasherCrushDamage = INVALID_HANDLE;
new Handle:hSmasherRemoveBody = INVALID_HANDLE;

new Handle:hWarpEnabled = INVALID_HANDLE;
new Handle:hWarpExtraHealth = INVALID_HANDLE;
new Handle:hWarpSpeed = INVALID_HANDLE;
new Handle:hWarpThrow = INVALID_HANDLE;
new Handle:hWarpFireImmunity = INVALID_HANDLE;
new Handle:hWarpTeleportDelay = INVALID_HANDLE;

new Handle:hMeteorEnabled = INVALID_HANDLE;
new Handle:hMeteorExtraHealth = INVALID_HANDLE;
new Handle:hMeteorSpeed = INVALID_HANDLE;
new Handle:hMeteorThrow = INVALID_HANDLE;
new Handle:hMeteorFireImmunity = INVALID_HANDLE;
new Handle:hMeteorStormDelay = INVALID_HANDLE;
new Handle:hMeteorStormDamage = INVALID_HANDLE;

new Handle:hSpitterEnabled = INVALID_HANDLE;
new Handle:hSpitterExtraHealth = INVALID_HANDLE;
new Handle:hSpitterSpeed = INVALID_HANDLE;
new Handle:hSpitterThrow = INVALID_HANDLE;
new Handle:hSpitterFireImmunity = INVALID_HANDLE;

new Handle:hHealEnabled = INVALID_HANDLE;
new Handle:hHealExtraHealth = INVALID_HANDLE;
new Handle:hHealSpeed = INVALID_HANDLE;
new Handle:hHealThrow = INVALID_HANDLE;
new Handle:hHealFireImmunity = INVALID_HANDLE;
new Handle:hHealHealthCommons = INVALID_HANDLE;
new Handle:hHealHealthSpecials = INVALID_HANDLE;
new Handle:hHealHealthTanks = INVALID_HANDLE;

new Handle:hFireEnabled = INVALID_HANDLE;
new Handle:hFireExtraHealth = INVALID_HANDLE;
new Handle:hFireSpeed = INVALID_HANDLE;
new Handle:hFireThrow = INVALID_HANDLE;
new Handle:hFireFireImmunity = INVALID_HANDLE;

new Handle:hIceEnabled = INVALID_HANDLE;
new Handle:hIceExtraHealth = INVALID_HANDLE;
new Handle:hIceSpeed = INVALID_HANDLE;
new Handle:hIceThrow = INVALID_HANDLE;
new Handle:hIceFireImmunity = INVALID_HANDLE;

new Handle:hJockeyEnabled = INVALID_HANDLE;
new Handle:hJockeyExtraHealth = INVALID_HANDLE;
new Handle:hJockeySpeed = INVALID_HANDLE;
new Handle:hJockeyThrow = INVALID_HANDLE;
new Handle:hJockeyFireImmunity = INVALID_HANDLE;

new Handle:hGhostEnabled = INVALID_HANDLE;
new Handle:hGhostExtraHealth = INVALID_HANDLE;
new Handle:hGhostSpeed = INVALID_HANDLE;
new Handle:hGhostThrow = INVALID_HANDLE;
new Handle:hGhostFireImmunity = INVALID_HANDLE;
new Handle:hGhostDisarm = INVALID_HANDLE;

new Handle:hShockEnabled = INVALID_HANDLE;
new Handle:hShockExtraHealth = INVALID_HANDLE;
new Handle:hShockSpeed = INVALID_HANDLE;
new Handle:hShockThrow = INVALID_HANDLE;
new Handle:hShockFireImmunity = INVALID_HANDLE;
new Handle:hShockStunDamage = INVALID_HANDLE;
new Handle:hShockStunMovement = INVALID_HANDLE;

new Handle:hWitchEnabled = INVALID_HANDLE;
new Handle:hWitchExtraHealth = INVALID_HANDLE;
new Handle:hWitchSpeed = INVALID_HANDLE;
new Handle:hWitchThrow = INVALID_HANDLE;
new Handle:hWitchFireImmunity = INVALID_HANDLE;
new Handle:hWitchMaxWitches = INVALID_HANDLE;

new Handle:hShieldEnabled = INVALID_HANDLE;
new Handle:hShieldExtraHealth = INVALID_HANDLE;
new Handle:hShieldSpeed = INVALID_HANDLE;
new Handle:hShieldThrow = INVALID_HANDLE;
new Handle:hShieldFireImmunity = INVALID_HANDLE;
new Handle:hShieldShieldsDownInterval = INVALID_HANDLE;

new Handle:hCobaltEnabled = INVALID_HANDLE;
new Handle:hCobaltExtraHealth = INVALID_HANDLE;
new Handle:hCobaltSpeed = INVALID_HANDLE;
new Handle:hCobaltThrow = INVALID_HANDLE;
new Handle:hCobaltFireImmunity = INVALID_HANDLE;
new Handle:hCobaltSpecialSpeed = INVALID_HANDLE;

new Handle:hJumperEnabled = INVALID_HANDLE;
new Handle:hJumperExtraHealth = INVALID_HANDLE;
new Handle:hJumperSpeed = INVALID_HANDLE;
new Handle:hJumperThrow = INVALID_HANDLE;
new Handle:hJumperFireImmunity = INVALID_HANDLE;
new Handle:hJumperJumpDelay = INVALID_HANDLE;

new Handle:hGravityEnabled = INVALID_HANDLE;
new Handle:hGravityExtraHealth = INVALID_HANDLE;
new Handle:hGravitySpeed = INVALID_HANDLE;
new Handle:hGravityThrow = INVALID_HANDLE;
new Handle:hGravityFireImmunity = INVALID_HANDLE;
new Handle:hGravityPullForce = INVALID_HANDLE;

static Handle:SDKSpitBurst 		= INVALID_HANDLE;
static Handle:SDKVomitOnPlayer 		= INVALID_HANDLE;

new bool:bSuperTanksEnabled;
new iWave1Cvar;
new iWave2Cvar;
new iWave3Cvar;
new bool:bFinaleOnly;
new bool:bDisplayHealthCvar;
new bool:bDefaultTanks;

new bool:bTankEnabled[16+1];
new iTankExtraHealth[16+1];
new Float:flTankSpeed[16+1];
new Float:flTankThrow[16+1];
new bool:bTankFireImmunity[16+1];

new bool:bDefaultOverride;
new iSpawnCommonAmount;
new iSpawnCommonInterval;
new iSmasherMaimDamage;
new iSmasherCrushDamage;
new bool:bSmasherRemoveBody;
new iWarpTeleportDelay;
new iMeteorStormDelay;
new Float:flMeteorStormDamage;
new iHealHealthCommons;
new iHealHealthSpecials;
new iHealHealthTanks;
new bool:bGhostDisarm;
new iShockStunDamage;
new Float:flShockStunMovement;
new iWitchMaxWitches;
new Float:flShieldShieldsDownInterval;
new Float:flCobaltSpecialSpeed;
new iJumperJumpDelay;
new Float:flGravityPullForce;

public OnPluginStart()
{
	CreateConVar("st_version", PLUGIN_VERSION, "Super Tanks Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	hSuperTanksEnabled = CreateConVar("st_on", "1", "Is Super Tanks enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hDisplayHealthCvar = CreateConVar("st_display_health", "1", "Display tanks health in crosshair?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hWave1Cvar = CreateConVar("st_wave1_tanks", "1", "Default number of tanks in the 1st wave of finale.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,5.0);
	hWave2Cvar = CreateConVar("st_wave2_tanks", "2", "Default number of tanks in the 2nd wave of finale.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,5.0);
	hWave3Cvar = CreateConVar("st_wave3_tanks", "1", "Default number of tanks in the finale escape.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,5.0);
	hFinaleOnly = CreateConVar("st_finale_only", "0", "Create Super Tanks in finale only?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hDefaultTanks = CreateConVar("st_default_tanks", "0", "Only use default tanks?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hGamemodeCvar = FindConVar("mp_gamemode");


	hDefaultOverride = CreateConVar("st_default_override", "0", "Setting this to 1 will allow further customization to default tanks.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hDefaultExtraHealth = CreateConVar("st_default_extra_health", "0", "Default Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hDefaultSpeed = CreateConVar("st_default_speed", "1.0", "Default Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hDefaultThrow = CreateConVar("st_default_throw", "5.0", "Default Tanks rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hDefaultFireImmunity = CreateConVar("st_default_fire_immunity", "0", "Are Default Tanks immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);

	hSpawnEnabled = CreateConVar("st_spawn", "1", "Is Spawn Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hSpawnExtraHealth = CreateConVar("st_spawn_extra_health", "27000", "Spawn Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hSpawnSpeed = CreateConVar("st_spawn_speed", "1.0", "Spawn Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hSpawnThrow = CreateConVar("st_spawn_throw", "10.0", "Spawn Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hSpawnFireImmunity = CreateConVar("st_spawn_fire_immunity", "0", "Is Spawn Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hSpawnCommonAmount = CreateConVar("st_spawn_common_amount", "8", "Number of common infected spawned by the Spawn Tank.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,1.0,true,50.0);
	hSpawnCommonInterval = CreateConVar("st_spawn_common_interval", "20", "Spawn Tanks common infected spawn interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,1.0,true,60.0);

	hSmasherEnabled = CreateConVar("st_smasher", "1", "Is Smasher Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hSmasherExtraHealth = CreateConVar("st_smasher_extra_health", "27000", "Smasher Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hSmasherSpeed = CreateConVar("st_smasher_speed", "0.70", "Smasher Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hSmasherThrow = CreateConVar("st_smasher_throw", "30.0", "Smasher Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hSmasherFireImmunity = CreateConVar("st_smasher_fire_immunity", "0", "Is Smasher Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hSmasherMaimDamage = CreateConVar("st_smasher_maim_damage", "1", "Smasher Tanks maim attack will set victims health to this amount.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,1.0,true,99.0);
	hSmasherCrushDamage = CreateConVar("st_smasher_crush_damage", "30", "Smasher Tanks claw attack damage.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1000.0);
	hSmasherRemoveBody = CreateConVar("st_smasher_remove_body", "0", "Smasher Tanks crush attack will remove survivors death body?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);

	hWarpEnabled = CreateConVar("st_warp", "1", "Is Warp Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hWarpExtraHealth = CreateConVar("st_warp_extra_health", "27000", "Warp Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hWarpSpeed = CreateConVar("st_warp_speed", "1.0", "Warp Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hWarpThrow = CreateConVar("st_warp_throw", "9.0", "Warp Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hWarpFireImmunity = CreateConVar("st_warp_fire_immunity", "0", "Is Warp Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hWarpTeleportDelay = CreateConVar("st_warp_teleport_delay", "30", "Warp Tanks Teleport Delay Interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,1.0,true,60.0);

	hMeteorEnabled = CreateConVar("st_meteor", "1", "Is Meteor Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hMeteorExtraHealth = CreateConVar("st_meteor_extra_health", "27000", "Meteor Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hMeteorSpeed = CreateConVar("st_meteor_speed", "1.0", "Meteor Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hMeteorThrow = CreateConVar("st_meteor_throw", "10.0", "Meteor Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hMeteorFireImmunity = CreateConVar("st_meteor_fire_immunity", "0", "Is Meteor Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hMeteorStormDelay = CreateConVar("st_meteor_storm_delay", "30", "Meteor Tanks Meteor Storm Delay Interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,1.0,true,60.0);
	hMeteorStormDamage = CreateConVar("st_meteor_storm_damage", "5.0", "Meteor Tanks falling meteor damage.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1000.0);

	hSpitterEnabled = CreateConVar("st_spitter", "0", "Is Spitter Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hSpitterExtraHealth = CreateConVar("st_spitter_extra_health", "0", "Spitter Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hSpitterSpeed = CreateConVar("st_spitter_speed", "1.0", "Spitter Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hSpitterThrow = CreateConVar("st_spitter_throw", "6.0", "Spitter Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hSpitterFireImmunity = CreateConVar("st_spitter_fire_immunity", "1", "Is Spitter Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);

	hHealEnabled = CreateConVar("st_heal", "1", "Is Heal Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hHealExtraHealth = CreateConVar("st_heal_extra_health", "27000", "Heal Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hHealSpeed = CreateConVar("st_heal_speed", "1.0", "Heal Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hHealThrow = CreateConVar("st_heal_throw", "15.0", "Heal Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hHealFireImmunity = CreateConVar("st_heal_fire_immunity", "0", "Is Heal Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hHealHealthCommons = CreateConVar("st_heal_health_commons", "50", "Heal Tanks receive this much health per second from being near a common infected.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1000.0);
	hHealHealthSpecials = CreateConVar("st_heal_health_specials", "50", "Heal Tanks receive this much health per second from being near a special infected.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1000.0);
	hHealHealthTanks = CreateConVar("st_heal_health_tanks", "50", "Heal Tanks receive this much health per second from being near another tank.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1000.0);

	hFireEnabled = CreateConVar("st_fire", "1", "Is Fire Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hFireExtraHealth = CreateConVar("st_fire_extra_health", "27000", "Fire Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hFireSpeed = CreateConVar("st_fire_speed", "1.0", "Fire Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hFireThrow = CreateConVar("st_fire_throw", "6.0", "Fire Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hFireFireImmunity = CreateConVar("st_fire_fire_immunity", "1", "Is Fire Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);

	hIceEnabled = CreateConVar("st_ice", "0", "Is Ice Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hIceExtraHealth = CreateConVar("st_ice_extra_health", "0", "Ice Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hIceSpeed = CreateConVar("st_ice_speed", "1.0", "Ice Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hIceThrow = CreateConVar("st_ice_throw", "6.0", "Ice Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hIceFireImmunity = CreateConVar("st_ice_fire_immunity", "1", "Is Ice Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);

	hJockeyEnabled = CreateConVar("st_jockey", "0", "Is Jockey Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hJockeyExtraHealth = CreateConVar("st_jockey_extra_health", "27000", "Jockey Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hJockeySpeed = CreateConVar("st_jockey_speed", "1.33", "Jockey Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hJockeyThrow = CreateConVar("st_jockey_throw", "7.0", "Jockey Tank jockey throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hJockeyFireImmunity = CreateConVar("st_jockey_fire_immunity", "1", "Is Jockey Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);

	hGhostEnabled = CreateConVar("st_ghost", "1", "Is Ghost Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hGhostExtraHealth = CreateConVar("st_ghost_extra_health", "27000", "Ghost Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hGhostSpeed = CreateConVar("st_ghost_speed", "1.0", "Ghost Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hGhostThrow = CreateConVar("st_ghost_throw", "15.0", "Ghost Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hGhostFireImmunity = CreateConVar("st_ghost_fire_immunity", "0", "Is Ghost Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hGhostDisarm = CreateConVar("st_ghost_disarm", "0", "Does Ghost Tank have a chance of disarming an attacking melee survivor?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);

	hShockEnabled = CreateConVar("st_shock", "1", "Is Shock Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hShockExtraHealth = CreateConVar("st_shock_extra_health", "27000", "Shock Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hShockSpeed = CreateConVar("st_shock_speed", "1.0", "Shock Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hShockThrow = CreateConVar("st_shock_throw", "10.0", "Shock Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hShockFireImmunity = CreateConVar("st_shock_fire_immunity", "0", "Is Shock Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hShockStunDamage = CreateConVar("st_shock_stun_damage", "5", "Shock Tanks stun damage.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1000.0);
	hShockStunMovement = CreateConVar("st_shock_stun_movement", "0.50", "Shock Tanks stun reduce survivors speed to this amount.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);

	hWitchEnabled = CreateConVar("st_witch", "1", "Is Witch Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hWitchExtraHealth = CreateConVar("st_witch_extra_health", "27000", "Witch Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hWitchSpeed = CreateConVar("st_witch_speed", "1.0", "Witch Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hWitchThrow = CreateConVar("st_witch_throw", "7.0", "Witch Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hWitchFireImmunity = CreateConVar("st_witch_fire_immunity", "0", "Is Witch Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hWitchMaxWitches = CreateConVar("st_witch_max_witches", "10", "Maximum number of witches converted from common infected by the Witch Tank.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100.0);

	hShieldEnabled = CreateConVar("st_shield", "0", "Is Shield Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hShieldExtraHealth = CreateConVar("st_shield_extra_health", "0", "Shield Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hShieldSpeed = CreateConVar("st_shield_speed", "1.0", "Shield Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hShieldThrow = CreateConVar("st_shield_throw", "8.0", "Shield Tank propane throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hShieldFireImmunity = CreateConVar("st_shield_fire_immunity", "1", "Is Shield Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hShieldShieldsDownInterval = CreateConVar("st_shield_shields_down_interval", "8.0", "When Shield Tanks shields are disabled, how long before shields activate again.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.1,true,60.0);

	hCobaltEnabled = CreateConVar("st_cobalt", "1", "Is Cobalt Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hCobaltExtraHealth = CreateConVar("st_cobalt_extra_health", "27000", "Cobalt Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hCobaltSpeed = CreateConVar("st_cobalt_speed", "1.0", "Cobalt Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hCobaltThrow = CreateConVar("st_cobalt_throw", "999.0", "Cobalt Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hCobaltFireImmunity = CreateConVar("st_cobalt_fire_immunity", "0", "Is Cobalt Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hCobaltSpecialSpeed = CreateConVar("st_cobalt_Special_speed", "1.80", "Cobalt Tanks movement value when speeding towards a survivor.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,1.0,true,5.0);

	hJumperEnabled = CreateConVar("st_jumper", "1", "Is Jumper Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hJumperExtraHealth = CreateConVar("st_jumper_extra_health", "27000", "Jumper Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hJumperSpeed = CreateConVar("st_jumper_speed", "1.0", "Jumper Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hJumperThrow = CreateConVar("st_jumper_throw", "999.0", "Jumper Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hJumperFireImmunity = CreateConVar("st_jumper_fire_immunity", "0", "Is Jumper Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hJumperJumpDelay = CreateConVar("st_jumper_jump_delay", "3", "Jumper Tanks delay interval to jump again.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,1.0,true,60.0);

	hGravityEnabled = CreateConVar("st_gravity", "1", "Is Gravity Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hGravityExtraHealth = CreateConVar("st_gravity_extra_health", "27000", "Gravity Tanks receive this many additional hitpoints.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,100000.0);
	hGravitySpeed = CreateConVar("st_gravity_speed", "1.0", "Gravity Tanks default movement speed.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,2.0);
	hGravityThrow = CreateConVar("st_gravity_throw", "10.0", "Gravity Tank rock throw ability interval.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,999.0);
	hGravityFireImmunity = CreateConVar("st_gravity_fire_immunity", "1", "Is Gravity Tank immune to fire?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	hGravityPullForce = CreateConVar("st_gravity_pull_force", "-20.0", "Gravity Tanks pull force value. Higher negative values equals greater pull forces.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,-200.0,true,0.0);

	bSuperTanksEnabled = GetConVarBool(hSuperTanksEnabled);
	bDisplayHealthCvar = GetConVarBool(hDisplayHealthCvar);
	iWave1Cvar = GetConVarInt(hWave1Cvar);
	iWave2Cvar = GetConVarInt(hWave2Cvar);
	iWave3Cvar = GetConVarInt(hWave3Cvar);
	bFinaleOnly = GetConVarBool(hFinaleOnly);
	bDefaultTanks = GetConVarBool(hDefaultTanks);
	bDefaultOverride = GetConVarBool(hDefaultOverride);

	bTankEnabled[1] = GetConVarBool(hSpawnEnabled);
	bTankEnabled[2] = GetConVarBool(hSmasherEnabled);
	bTankEnabled[3] = GetConVarBool(hWarpEnabled);
	bTankEnabled[4] = GetConVarBool(hMeteorEnabled);
	bTankEnabled[5] = GetConVarBool(hSpitterEnabled);
	bTankEnabled[6] = GetConVarBool(hHealEnabled);
	bTankEnabled[7] = GetConVarBool(hFireEnabled);
	bTankEnabled[8] = GetConVarBool(hIceEnabled);
	bTankEnabled[9] = GetConVarBool(hJockeyEnabled);
	bTankEnabled[10] = GetConVarBool(hGhostEnabled);
	bTankEnabled[11] = GetConVarBool(hShockEnabled);
	bTankEnabled[12] = GetConVarBool(hWitchEnabled);
	bTankEnabled[13] = GetConVarBool(hShieldEnabled);
	bTankEnabled[14] = GetConVarBool(hCobaltEnabled);
	bTankEnabled[15] = GetConVarBool(hJumperEnabled);
	bTankEnabled[16] = GetConVarBool(hGravityEnabled);

	iTankExtraHealth[0] = GetConVarInt(hDefaultExtraHealth);
	iTankExtraHealth[1] = GetConVarInt(hSpawnExtraHealth);
	iTankExtraHealth[2] = GetConVarInt(hSmasherExtraHealth);
	iTankExtraHealth[3] = GetConVarInt(hWarpExtraHealth);
	iTankExtraHealth[4] = GetConVarInt(hMeteorExtraHealth);
	iTankExtraHealth[5] = GetConVarInt(hSpitterExtraHealth);
	iTankExtraHealth[6] = GetConVarInt(hHealExtraHealth);
	iTankExtraHealth[7] = GetConVarInt(hFireExtraHealth);
	iTankExtraHealth[8] = GetConVarInt(hIceExtraHealth);
	iTankExtraHealth[9] = GetConVarInt(hJockeyExtraHealth);
	iTankExtraHealth[10] = GetConVarInt(hGhostExtraHealth);
	iTankExtraHealth[11] = GetConVarInt(hShockExtraHealth);
	iTankExtraHealth[12] = GetConVarInt(hWitchExtraHealth);
	iTankExtraHealth[13] = GetConVarInt(hShieldExtraHealth);
	iTankExtraHealth[14] = GetConVarInt(hCobaltExtraHealth);
	iTankExtraHealth[15] = GetConVarInt(hJumperExtraHealth);
	iTankExtraHealth[16] = GetConVarInt(hGravityExtraHealth);

	flTankSpeed[0] = GetConVarFloat(hDefaultSpeed);
	flTankSpeed[1] = GetConVarFloat(hSpawnSpeed);
	flTankSpeed[2] = GetConVarFloat(hSmasherSpeed);
	flTankSpeed[3] = GetConVarFloat(hWarpSpeed);
	flTankSpeed[4] = GetConVarFloat(hMeteorSpeed);
	flTankSpeed[5] = GetConVarFloat(hSpitterSpeed);
	flTankSpeed[6] = GetConVarFloat(hHealSpeed);
	flTankSpeed[7] = GetConVarFloat(hFireSpeed);
	flTankSpeed[8] = GetConVarFloat(hIceSpeed);
	flTankSpeed[9] = GetConVarFloat(hJockeySpeed);
	flTankSpeed[10] = GetConVarFloat(hGhostSpeed);
	flTankSpeed[11] = GetConVarFloat(hShockSpeed);
	flTankSpeed[12] = GetConVarFloat(hWitchSpeed);
	flTankSpeed[13] = GetConVarFloat(hShieldSpeed);
	flTankSpeed[14] = GetConVarFloat(hCobaltSpeed);
	flTankSpeed[15] = GetConVarFloat(hJumperSpeed);
	flTankSpeed[16] = GetConVarFloat(hGravitySpeed);

	flTankThrow[0] = GetConVarFloat(hDefaultThrow);
	flTankThrow[1] = GetConVarFloat(hSpawnThrow);
	flTankThrow[2] = GetConVarFloat(hSmasherThrow);
	flTankThrow[3] = GetConVarFloat(hWarpThrow);
	flTankThrow[4] = GetConVarFloat(hMeteorThrow);
	flTankThrow[5] = GetConVarFloat(hSpitterThrow);
	flTankThrow[6] = GetConVarFloat(hHealThrow);
	flTankThrow[7] = GetConVarFloat(hFireThrow);
	flTankThrow[8] = GetConVarFloat(hIceThrow);
	flTankThrow[9] = GetConVarFloat(hJockeyThrow);
	flTankThrow[10] = GetConVarFloat(hGhostThrow);
	flTankThrow[11] = GetConVarFloat(hShockThrow);
	flTankThrow[12] = GetConVarFloat(hWitchThrow);
	flTankThrow[13] = GetConVarFloat(hShieldThrow);
	flTankThrow[14] = GetConVarFloat(hCobaltThrow);
	flTankThrow[15] = GetConVarFloat(hJumperThrow);
	flTankThrow[16] = GetConVarFloat(hGravityThrow);

	bTankFireImmunity[0] = GetConVarBool(hDefaultFireImmunity);
	bTankFireImmunity[1] = GetConVarBool(hSpawnFireImmunity);
	bTankFireImmunity[2] = GetConVarBool(hSmasherFireImmunity);
	bTankFireImmunity[3] = GetConVarBool(hWarpFireImmunity);
	bTankFireImmunity[4] = GetConVarBool(hMeteorFireImmunity);
	bTankFireImmunity[5] = GetConVarBool(hSpitterFireImmunity);
	bTankFireImmunity[6] = GetConVarBool(hHealFireImmunity);
	bTankFireImmunity[7] = GetConVarBool(hFireFireImmunity);
	bTankFireImmunity[8] = GetConVarBool(hIceFireImmunity);
	bTankFireImmunity[9] = GetConVarBool(hJockeyFireImmunity);
	bTankFireImmunity[10] = GetConVarBool(hGhostFireImmunity);
	bTankFireImmunity[11] = GetConVarBool(hShockFireImmunity);
	bTankFireImmunity[12] = GetConVarBool(hWitchFireImmunity);
	bTankFireImmunity[13] = GetConVarBool(hShieldFireImmunity);
	bTankFireImmunity[14] = GetConVarBool(hCobaltFireImmunity);
	bTankFireImmunity[15] = GetConVarBool(hJumperFireImmunity);
	bTankFireImmunity[16] = GetConVarBool(hGravityFireImmunity);

	iSpawnCommonAmount = GetConVarInt(hSpawnCommonAmount);
	iSpawnCommonInterval = GetConVarInt(hSpawnCommonInterval);
	iSmasherMaimDamage = GetConVarInt(hSmasherMaimDamage);
	iSmasherCrushDamage = GetConVarInt(hSmasherCrushDamage);
	bSmasherRemoveBody = GetConVarBool(hSmasherRemoveBody);
	iWarpTeleportDelay = GetConVarInt(hWarpTeleportDelay);
	iMeteorStormDelay = GetConVarInt(hMeteorStormDelay);
	flMeteorStormDamage = GetConVarFloat(hMeteorStormDamage);
	iHealHealthCommons = GetConVarInt(hHealHealthCommons);
	iHealHealthSpecials = GetConVarInt(hHealHealthSpecials);
	iHealHealthTanks = GetConVarInt(hHealHealthTanks);
	bGhostDisarm = GetConVarBool(hGhostDisarm);
	iShockStunDamage = GetConVarInt(hShockStunDamage);
	flShockStunMovement = GetConVarFloat(hShockStunMovement);
	iWitchMaxWitches = GetConVarInt(hWitchMaxWitches);
	flShieldShieldsDownInterval = GetConVarFloat(hShieldShieldsDownInterval);
	flCobaltSpecialSpeed = GetConVarFloat(hCobaltSpecialSpeed);
	iJumperJumpDelay = GetConVarInt(hJumperJumpDelay);
	flGravityPullForce = GetConVarFloat(hGravityPullForce);

	HookConVarChange(hSuperTanksEnabled, SuperTanksCvarChanged);
	HookConVarChange(hDisplayHealthCvar, SuperTanksSettingsChanged);
	HookConVarChange(hWave1Cvar, SuperTanksSettingsChanged);
	HookConVarChange(hWave2Cvar, SuperTanksSettingsChanged);
	HookConVarChange(hWave3Cvar, SuperTanksSettingsChanged);
	HookConVarChange(hFinaleOnly, SuperTanksSettingsChanged);
	HookConVarChange(hDefaultTanks, SuperTanksSettingsChanged);
	HookConVarChange(hDefaultOverride, DefaultTanksSettingsChanged);
	HookConVarChange(hGamemodeCvar, GamemodeCvarChanged);

	HookConVarChange(hSpawnEnabled, TanksSettingsChanged);
	HookConVarChange(hSmasherEnabled, TanksSettingsChanged);
	HookConVarChange(hWarpEnabled, TanksSettingsChanged);
	HookConVarChange(hMeteorEnabled, TanksSettingsChanged);
	HookConVarChange(hSpitterEnabled, TanksSettingsChanged);
	HookConVarChange(hHealEnabled, TanksSettingsChanged);
	HookConVarChange(hFireEnabled, TanksSettingsChanged);
	HookConVarChange(hIceEnabled, TanksSettingsChanged);
	HookConVarChange(hJockeyEnabled, TanksSettingsChanged);
	HookConVarChange(hGhostEnabled, TanksSettingsChanged);
	HookConVarChange(hShockEnabled, TanksSettingsChanged);
	HookConVarChange(hWitchEnabled, TanksSettingsChanged);
	HookConVarChange(hShieldEnabled, TanksSettingsChanged);
	HookConVarChange(hCobaltEnabled, TanksSettingsChanged);
	HookConVarChange(hJumperEnabled, TanksSettingsChanged);
	HookConVarChange(hGravityEnabled, TanksSettingsChanged);

	HookConVarChange(hDefaultExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSpawnExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSmasherExtraHealth, TanksSettingsChanged);
	HookConVarChange(hWarpExtraHealth, TanksSettingsChanged);
	HookConVarChange(hMeteorExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSpitterExtraHealth, TanksSettingsChanged);
	HookConVarChange(hHealExtraHealth, TanksSettingsChanged);
	HookConVarChange(hFireExtraHealth, TanksSettingsChanged);
	HookConVarChange(hIceExtraHealth, TanksSettingsChanged);
	HookConVarChange(hJockeyExtraHealth, TanksSettingsChanged);
	HookConVarChange(hGhostExtraHealth, TanksSettingsChanged);
	HookConVarChange(hShockExtraHealth, TanksSettingsChanged);
	HookConVarChange(hWitchExtraHealth, TanksSettingsChanged);
	HookConVarChange(hShieldExtraHealth, TanksSettingsChanged);
	HookConVarChange(hCobaltExtraHealth, TanksSettingsChanged);
	HookConVarChange(hJumperExtraHealth, TanksSettingsChanged);
	HookConVarChange(hGravityExtraHealth, TanksSettingsChanged);

	HookConVarChange(hDefaultSpeed, TanksSettingsChanged);
	HookConVarChange(hSpawnSpeed, TanksSettingsChanged);
	HookConVarChange(hSmasherSpeed, TanksSettingsChanged);
	HookConVarChange(hWarpSpeed, TanksSettingsChanged);
	HookConVarChange(hMeteorSpeed, TanksSettingsChanged);
	HookConVarChange(hSpitterSpeed, TanksSettingsChanged);
	HookConVarChange(hHealSpeed, TanksSettingsChanged);
	HookConVarChange(hFireSpeed, TanksSettingsChanged);
	HookConVarChange(hIceSpeed, TanksSettingsChanged);
	HookConVarChange(hJockeySpeed, TanksSettingsChanged);
	HookConVarChange(hGhostSpeed, TanksSettingsChanged);
	HookConVarChange(hShockSpeed, TanksSettingsChanged);
	HookConVarChange(hWitchSpeed, TanksSettingsChanged);
	HookConVarChange(hShieldSpeed, TanksSettingsChanged);
	HookConVarChange(hCobaltSpeed, TanksSettingsChanged);
	HookConVarChange(hJumperSpeed, TanksSettingsChanged);
	HookConVarChange(hGravitySpeed, TanksSettingsChanged);

	HookConVarChange(hDefaultThrow, TanksSettingsChanged);
	HookConVarChange(hSpawnThrow, TanksSettingsChanged);
	HookConVarChange(hSmasherThrow, TanksSettingsChanged);
	HookConVarChange(hWarpThrow, TanksSettingsChanged);
	HookConVarChange(hMeteorThrow, TanksSettingsChanged);
	HookConVarChange(hSpitterThrow, TanksSettingsChanged);
	HookConVarChange(hHealThrow, TanksSettingsChanged);
	HookConVarChange(hFireThrow, TanksSettingsChanged);
	HookConVarChange(hIceThrow, TanksSettingsChanged);
	HookConVarChange(hJockeyThrow, TanksSettingsChanged);
	HookConVarChange(hGhostThrow, TanksSettingsChanged);
	HookConVarChange(hShockThrow, TanksSettingsChanged);
	HookConVarChange(hWitchThrow, TanksSettingsChanged);
	HookConVarChange(hShieldThrow, TanksSettingsChanged);
	HookConVarChange(hCobaltThrow, TanksSettingsChanged);
	HookConVarChange(hJumperThrow, TanksSettingsChanged);
	HookConVarChange(hGravityThrow, TanksSettingsChanged);

	HookConVarChange(hDefaultFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSpawnFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSmasherFireImmunity, TanksSettingsChanged);
	HookConVarChange(hWarpFireImmunity, TanksSettingsChanged);
	HookConVarChange(hMeteorFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSpitterFireImmunity, TanksSettingsChanged);
	HookConVarChange(hHealFireImmunity, TanksSettingsChanged);
	HookConVarChange(hFireFireImmunity, TanksSettingsChanged);
	HookConVarChange(hIceFireImmunity, TanksSettingsChanged);
	HookConVarChange(hJockeyFireImmunity, TanksSettingsChanged);
	HookConVarChange(hGhostFireImmunity, TanksSettingsChanged);
	HookConVarChange(hShockFireImmunity, TanksSettingsChanged);
	HookConVarChange(hWitchFireImmunity, TanksSettingsChanged);
	HookConVarChange(hShieldFireImmunity, TanksSettingsChanged);
	HookConVarChange(hCobaltFireImmunity, TanksSettingsChanged);
	HookConVarChange(hJumperFireImmunity, TanksSettingsChanged);
	HookConVarChange(hGravityFireImmunity, TanksSettingsChanged);

	HookConVarChange(hSpawnCommonAmount, TanksSettingsChanged);
	HookConVarChange(hSpawnCommonInterval, TanksSettingsChanged);
	HookConVarChange(hSmasherMaimDamage, TanksSettingsChanged);
	HookConVarChange(hSmasherCrushDamage, TanksSettingsChanged);
	HookConVarChange(hWarpTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hMeteorStormDelay, TanksSettingsChanged);
	HookConVarChange(hMeteorStormDamage, TanksSettingsChanged);
	HookConVarChange(hHealHealthCommons, TanksSettingsChanged);
	HookConVarChange(hHealHealthSpecials, TanksSettingsChanged);
	HookConVarChange(hHealHealthTanks, TanksSettingsChanged);
	HookConVarChange(hGhostDisarm, TanksSettingsChanged);
	HookConVarChange(hShockStunDamage, TanksSettingsChanged);
	HookConVarChange(hShockStunMovement, TanksSettingsChanged);
	HookConVarChange(hWitchMaxWitches, TanksSettingsChanged);
	HookConVarChange(hShieldShieldsDownInterval, TanksSettingsChanged);
	HookConVarChange(hCobaltSpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hJumperJumpDelay, TanksSettingsChanged);
	HookConVarChange(hGravityPullForce, TanksSettingsChanged);

	HookEvent("ability_use", Ability_Use);
	HookEvent("finale_escape_start", Finale_Escape_Start);
	HookEvent("finale_start", Finale_Start, EventHookMode_Pre);
	HookEvent("finale_vehicle_leaving", Finale_Vehicle_Leaving);
	HookEvent("finale_vehicle_ready", Finale_Vehicle_Ready);
	HookEvent("player_death", Player_Death);
	HookEvent("tank_spawn", Tank_Spawn);
	HookEvent("round_end", Round_End);
	HookEvent("round_start", Round_Start);

	CreateTimer(0.1,TimerUpdate01, _, TIMER_REPEAT);
	CreateTimer(1.0,TimerUpdate1, _, TIMER_REPEAT);

//	InitSDKCalls();
	InitStartUp();

	AutoExecConfig(true, "SuperTanks");
}
//=============================
// StartUp
//=============================
InitSDKCalls()
{
	new Handle:ConfigFile = LoadGameConfigFile("supertanks");
	new Handle:MySDKCall = INVALID_HANDLE;

	/////////////
	//SpitBurst//
	/////////////
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CSpitterProjectile_Detonate");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	MySDKCall = EndPrepSDKCall();
	if (MySDKCall == INVALID_HANDLE)
	{
		SetFailState("Cant initialize CSpitterProjectile_Detonate SDKCall");
	}
	SDKSpitBurst = CloneHandle(MySDKCall, SDKSpitBurst);

	/////////////////
	//VomitOnPlayer//
	/////////////////
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	MySDKCall = EndPrepSDKCall();
	if (MySDKCall == INVALID_HANDLE)
	{
		SetFailState("Cant initialize CTerrorPlayer_OnVomitedUpon SDKCall");
	}
	SDKVomitOnPlayer = CloneHandle(MySDKCall, SDKVomitOnPlayer);

	CloseHandle(ConfigFile);
	CloseHandle(MySDKCall);
}
stock SDKCallSpitBurst(client)
{
	SDKCall(SDKSpitBurst, client, true);
}
stock SDKCallVomitOnPlayer(victim, attacker)
{
//	SDKCall(SDKVomitOnPlayer, victim, attacker, true);
}
InitStartUp()
{
	if (bSuperTanksEnabled)
	{
		decl String:gamemode[24];
		GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
       		if (!StrEqual(gamemode, "coop", false) && !StrEqual(gamemode, "realism", false))
		{
			PrintToServer("[SuperTanks] This plugin is only compatible in Coop or Realism gamemodes.");
			PrintToServer("[SuperTanks] Plugin Disabled.");
			SetConVarBool(hSuperTanksEnabled, false);		
		}
	}
}
//=============================
// Events
//=============================
public GamemodeCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (bSuperTanksEnabled)
	{
		if (convar == hGamemodeCvar)
		{
       			if (StrEqual(oldValue, newValue, false)) return;

       			if (!StrEqual(newValue, "coop", false) && !StrEqual(newValue, "realism", false))
			{
				PrintToServer("[SuperTanks] This plugin is only compatible in Coop or Realism gamemodes.");
				PrintToServer("[SuperTanks] Plugin Disabled.");
				SetConVarBool(hSuperTanksEnabled, false);
			}
		}
	}
}
public SuperTanksCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == hSuperTanksEnabled)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);

		if (newval == oldval) return;

		if (newval == 1)
		{
			decl String:gamemode[24];
			GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
       			if (!StrEqual(gamemode, "coop", false) && !StrEqual(gamemode, "realism", false))
			{
				PrintToServer("[SuperTanks] This plugin is only compatible in Coop or Realism gamemodes.");
				PrintToServer("[SuperTanks] Plugin Disabled.");
				SetConVarBool(hSuperTanksEnabled, false);		
			}	
		}
		bSuperTanksEnabled = GetConVarBool(hSuperTanksEnabled);
	}
}
public SuperTanksSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bDisplayHealthCvar = GetConVarBool(hDisplayHealthCvar);
	iWave1Cvar = GetConVarInt(hWave1Cvar);
	iWave2Cvar = GetConVarInt(hWave2Cvar);
	iWave3Cvar = GetConVarInt(hWave3Cvar);
	bFinaleOnly = GetConVarBool(hFinaleOnly);
	bDefaultTanks = GetConVarBool(hDefaultTanks);
}
public DefaultTanksSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == hDefaultOverride)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);

		if (newval == oldval) return;

		if (newval == 0)
		{
			SetConVarInt(hDefaultExtraHealth, 0);
			SetConVarFloat(hDefaultSpeed, 1.0);
			SetConVarFloat(hDefaultThrow, 5.0);
			SetConVarBool(hDefaultFireImmunity, false);
		}
	}
	bDefaultOverride = GetConVarBool(hDefaultOverride);
}
public TanksSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bTankEnabled[1] = GetConVarBool(hSpawnEnabled);
	bTankEnabled[2] = GetConVarBool(hSmasherEnabled);
	bTankEnabled[3] = GetConVarBool(hWarpEnabled);
	bTankEnabled[4] = GetConVarBool(hMeteorEnabled);
	bTankEnabled[5] = GetConVarBool(hSpitterEnabled);
	bTankEnabled[6] = GetConVarBool(hHealEnabled);
	bTankEnabled[7] = GetConVarBool(hFireEnabled);
	bTankEnabled[8] = GetConVarBool(hIceEnabled);
	bTankEnabled[9] = GetConVarBool(hJockeyEnabled);
	bTankEnabled[10] = GetConVarBool(hGhostEnabled);
	bTankEnabled[11] = GetConVarBool(hShockEnabled);
	bTankEnabled[12] = GetConVarBool(hWitchEnabled);
	bTankEnabled[13] = GetConVarBool(hShieldEnabled);
	bTankEnabled[14] = GetConVarBool(hCobaltEnabled);
	bTankEnabled[15] = GetConVarBool(hJumperEnabled);
	bTankEnabled[16] = GetConVarBool(hGravityEnabled);

	iTankExtraHealth[0] = GetConVarInt(hDefaultExtraHealth);
	iTankExtraHealth[1] = GetConVarInt(hSpawnExtraHealth);
	iTankExtraHealth[2] = GetConVarInt(hSmasherExtraHealth);
	iTankExtraHealth[3] = GetConVarInt(hWarpExtraHealth);
	iTankExtraHealth[4] = GetConVarInt(hMeteorExtraHealth);
	iTankExtraHealth[5] = GetConVarInt(hSpitterExtraHealth);
	iTankExtraHealth[6] = GetConVarInt(hHealExtraHealth);
	iTankExtraHealth[7] = GetConVarInt(hFireExtraHealth);
	iTankExtraHealth[8] = GetConVarInt(hIceExtraHealth);
	iTankExtraHealth[9] = GetConVarInt(hJockeyExtraHealth);
	iTankExtraHealth[10] = GetConVarInt(hGhostExtraHealth);
	iTankExtraHealth[11] = GetConVarInt(hShockExtraHealth);
	iTankExtraHealth[12] = GetConVarInt(hWitchExtraHealth);
	iTankExtraHealth[13] = GetConVarInt(hShieldExtraHealth);
	iTankExtraHealth[14] = GetConVarInt(hCobaltExtraHealth);
	iTankExtraHealth[15] = GetConVarInt(hJumperExtraHealth);
	iTankExtraHealth[16] = GetConVarInt(hGravityExtraHealth);

	flTankSpeed[0] = GetConVarFloat(hDefaultSpeed);
	flTankSpeed[1] = GetConVarFloat(hSpawnSpeed);
	flTankSpeed[2] = GetConVarFloat(hSmasherSpeed);
	flTankSpeed[3] = GetConVarFloat(hWarpSpeed);
	flTankSpeed[4] = GetConVarFloat(hMeteorSpeed);
	flTankSpeed[5] = GetConVarFloat(hSpitterSpeed);
	flTankSpeed[6] = GetConVarFloat(hHealSpeed);
	flTankSpeed[7] = GetConVarFloat(hFireSpeed);
	flTankSpeed[8] = GetConVarFloat(hIceSpeed);
	flTankSpeed[9] = GetConVarFloat(hJockeySpeed);
	flTankSpeed[10] = GetConVarFloat(hGhostSpeed);
	flTankSpeed[11] = GetConVarFloat(hShockSpeed);
	flTankSpeed[12] = GetConVarFloat(hWitchSpeed);
	flTankSpeed[13] = GetConVarFloat(hShieldSpeed);
	flTankSpeed[14] = GetConVarFloat(hCobaltSpeed);
	flTankSpeed[15] = GetConVarFloat(hJumperSpeed);
	flTankSpeed[16] = GetConVarFloat(hGravitySpeed);

	flTankThrow[0] = GetConVarFloat(hDefaultThrow);
	flTankThrow[1] = GetConVarFloat(hSpawnThrow);
	flTankThrow[2] = GetConVarFloat(hSmasherThrow);
	flTankThrow[3] = GetConVarFloat(hWarpThrow);
	flTankThrow[4] = GetConVarFloat(hMeteorThrow);
	flTankThrow[5] = GetConVarFloat(hSpitterThrow);
	flTankThrow[6] = GetConVarFloat(hHealThrow);
	flTankThrow[7] = GetConVarFloat(hFireThrow);
	flTankThrow[8] = GetConVarFloat(hIceThrow);
	flTankThrow[9] = GetConVarFloat(hJockeyThrow);
	flTankThrow[10] = GetConVarFloat(hGhostThrow);
	flTankThrow[11] = GetConVarFloat(hShockThrow);
	flTankThrow[12] = GetConVarFloat(hWitchThrow);
	flTankThrow[13] = GetConVarFloat(hShieldThrow);
	flTankThrow[14] = GetConVarFloat(hCobaltThrow);
	flTankThrow[15] = GetConVarFloat(hJumperThrow);
	flTankThrow[16] = GetConVarFloat(hGravityThrow);

	bTankFireImmunity[0] = GetConVarBool(hDefaultFireImmunity);
	bTankFireImmunity[1] = GetConVarBool(hSpawnFireImmunity);
	bTankFireImmunity[2] = GetConVarBool(hSmasherFireImmunity);
	bTankFireImmunity[3] = GetConVarBool(hWarpFireImmunity);
	bTankFireImmunity[4] = GetConVarBool(hMeteorFireImmunity);
	bTankFireImmunity[5] = GetConVarBool(hSpitterFireImmunity);
	bTankFireImmunity[6] = GetConVarBool(hHealFireImmunity);
	bTankFireImmunity[7] = GetConVarBool(hFireFireImmunity);
	bTankFireImmunity[8] = GetConVarBool(hIceFireImmunity);
	bTankFireImmunity[9] = GetConVarBool(hJockeyFireImmunity);
	bTankFireImmunity[10] = GetConVarBool(hGhostFireImmunity);
	bTankFireImmunity[11] = GetConVarBool(hShockFireImmunity);
	bTankFireImmunity[12] = GetConVarBool(hWitchFireImmunity);
	bTankFireImmunity[13] = GetConVarBool(hShieldFireImmunity);
	bTankFireImmunity[14] = GetConVarBool(hCobaltFireImmunity);
	bTankFireImmunity[15] = GetConVarBool(hJumperFireImmunity);
	bTankFireImmunity[16] = GetConVarBool(hGravityFireImmunity);

	iSpawnCommonAmount = GetConVarInt(hSpawnCommonAmount);
	iSpawnCommonInterval = GetConVarInt(hSpawnCommonInterval);
	iSmasherMaimDamage = GetConVarInt(hSmasherMaimDamage);
	iSmasherCrushDamage = GetConVarInt(hSmasherCrushDamage);
	bSmasherRemoveBody = GetConVarBool(hSmasherRemoveBody);
	iWarpTeleportDelay = GetConVarInt(hWarpTeleportDelay);
	iMeteorStormDelay = GetConVarInt(hMeteorStormDelay);
	flMeteorStormDamage = GetConVarFloat(hMeteorStormDamage);
	iHealHealthCommons = GetConVarInt(hHealHealthCommons);
	iHealHealthSpecials = GetConVarInt(hHealHealthSpecials);
	iHealHealthTanks = GetConVarInt(hHealHealthTanks);
	bGhostDisarm = GetConVarBool(hGhostDisarm);
	iShockStunDamage = GetConVarInt(hShockStunDamage);
	flShockStunMovement = GetConVarFloat(hShockStunMovement);
	iWitchMaxWitches = GetConVarInt(hWitchMaxWitches);
	flShieldShieldsDownInterval = GetConVarFloat(hShieldShieldsDownInterval);
	flCobaltSpecialSpeed = GetConVarFloat(hCobaltSpecialSpeed);
	iJumperJumpDelay = GetConVarInt(hJumperJumpDelay);
	flGravityPullForce = GetConVarFloat(hGravityPullForce);	
}
public OnMapStart()
{
	PrecacheParticle(PARTICLE_SPAWN);
	PrecacheParticle(PARTICLE_FIRE);
	PrecacheParticle(PARTICLE_WARP);
	PrecacheParticle(PARTICLE_ICE);
	PrecacheParticle(PARTICLE_SPIT);
	PrecacheParticle(PARTICLE_SPITPROJ);
	PrecacheParticle(PARTICLE_ELEC);
	PrecacheParticle(PARTICLE_BLOOD);
	PrecacheParticle(PARTICLE_EXPLODE);
	PrecacheParticle(PARTICLE_METEOR);
	CheckModelPreCache("models/props_junk/gascan001a.mdl");
	CheckModelPreCache("models/props_junk/propanecanister001a.mdl");
    	CheckModelPreCache("models/infected/witch.mdl");
	CheckModelPreCache("models/infected/witch_bride.mdl");
	CheckModelPreCache("models/props_vehicles/tire001c_car.mdl");
	CheckModelPreCache("models/props_unique/airport/atlas_break_ball.mdl");
	CheckSoundPreCache("ambient/fire/gascan_ignite1.wav");
	CheckSoundPreCache("player/charger/hit/charger_smash_02.wav");
	CheckSoundPreCache("npc/infected/action/die/male/death_42.wav");
	CheckSoundPreCache("npc/infected/action/die/male/death_43.wav");
	CheckSoundPreCache("ambient/energy/zap1.wav");
	CheckSoundPreCache("ambient/energy/zap5.wav");
	CheckSoundPreCache("ambient/energy/zap7.wav");
	CheckSoundPreCache("player/spitter/voice/warn/spitter_spit_02.wav");
	CheckSoundPreCache("player/tank/voice/growl/tank_climb_01.wav");
	CheckSoundPreCache("player/tank/voice/growl/tank_climb_02.wav");
	CheckSoundPreCache("player/tank/voice/growl/tank_climb_03.wav");
	CheckSoundPreCache("player/tank/voice/growl/tank_climb_04.wav");
}
stock CheckModelPreCache(const String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile, true);
		PrintToServer("[Super Tanks]Precaching Model:%s",Modelfile);
	}
}
stock CheckSoundPreCache(const String:Soundfile[])
{
	//if (!IsSoundPrecached(Soundfile)) //Removed, Function not working
	//{
		PrecacheSound(Soundfile, true);
		PrintToServer("[Super Tanks]Precaching Sound:%s",Soundfile);
	//}
}
public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
	TankAbility[client] = 0;
	Rock[client] = 0;
	ShieldsUp[client] = 0;
	PlayerSpeed[client] = 0;
}
public Action:Ability_Use(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (bSuperTanksEnabled)
	{
		if (client > 0)
		{
			if (IsClientInGame(client))
			{
				if (IsTank(client))
				{
					new index = GetSuperTankByRenderColor(GetEntityRenderColor(client));
					if (index >= 0 && index <= 16)
					{
						if (index != 0 || (index == 0 && bDefaultOverride))
						{
							ResetInfectedAbility(client, flTankThrow[index]);
						}
					}
				}
			}
		}
	}
}
public Action:Finale_Escape_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iTankWave = 3;
}
public Action:Finale_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iTankWave = 1;
}
public Action:Finale_Vehicle_Leaving(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iTankWave = 4;
}
public Action:Finale_Vehicle_Ready(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iTankWave = 3;
}
public Action:Player_Death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (bSuperTanksEnabled)
	{
		if (client > 0 && IsClientInGame(client))
		{
			SetEntityGravity(client, 1.0);
//			SetEntProp(client, Prop_Send, "m_iGlowType", 0);
//			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
			if (IsTank(client))
			{
//				ExecTankDeath(client);		
			}	
			else if (GetClientTeam(client) == 2)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != INVALID_ENT_REFERENCE)
				{
					new Float:Origin[3], Float:EOrigin[3];
					GetClientAbsOrigin(client, Origin);
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EOrigin);
					if (Origin[0] == EOrigin[0] && Origin[1] == EOrigin[1] && Origin[2] == EOrigin[2])
					{
						SetEntProp(entity, Prop_Send, "m_hOwnerEntity", client);
					}
				}
			}
		}
	}
}
public Action:Round_End(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (bSuperTanksEnabled)
	{
		for (new i=1;i<=MaxClients;i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && IsFakeClient(i) && GetClientTeam(i) == 3 && !IsTank(i))
			{
				if (CountInfectedAll() > 16)
				{
					KickClient(i);
				}
			}
		}
	}
}
public Action:Round_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (bSuperTanksEnabled)
	{
		iTick = 0;
		iTankWave = 0;
		iNumTanks = 0;

		new flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
		SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false);
		SetConVarFlags(FindConVar("z_max_player_zombies"), flags & ~FCVAR_NOTIFY);
//		SetConVarInt(FindConVar("z_hunter_limit"), 32);
//		SetConVarInt(FindConVar("z_jockey_limit"), 32);
//		SetConVarInt(FindConVar("z_charger_limit"), 32);
//		SetConVarInt(FindConVar("z_hunter_limit"), 32);
//		SetConVarInt(FindConVar("z_boomer_limit"), 32);
//		SetConVarInt(FindConVar("z_spitter_limit"), 32);

		for (new client=1; client<=MaxClients; client++)
		{
			TankAbility[client] = 0;
			Rock[client] = 0;
			ShieldsUp[client] = 0;
			PlayerSpeed[client] = 0;
		}
	}
}
public Action:Tank_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client =  GetClientOfUserId(GetEventInt(event, "userid"));

	CountTanks();

	if (bSuperTanksEnabled)
	{
		if (client > 0 && IsClientInGame(client))
		{
			TankAlive[client] = 1;
			TankAbility[client] = 0;
			CreateTimer(0.1, TankSpawnTimer, client, TIMER_FLAG_NO_MAPCHANGE);
			if (!bFinaleOnly || (bFinaleOnly && iTankWave > 0))
			{
				RandomizeTank(client);
				switch(iTankWave)
				{
					case 1:
					{
						if (iNumTanks < iWave1Cvar)
						{
							CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
						}
						else if (iNumTanks > iWave1Cvar)
						{
							if (IsFakeClient(client))
							{
								KickClient(client);
							}
						}
					}
					case 2:
					{
						if (iNumTanks < iWave2Cvar)
						{
							CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
						}
						else if (iNumTanks > iWave2Cvar)
						{
							if (IsFakeClient(client))
							{
								KickClient(client);
							}
						}
					}
					case 3:
					{
						if (iNumTanks < iWave3Cvar)
						{
							CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
						}
						else if (iNumTanks > iWave3Cvar)
						{
							if (IsFakeClient(client))
							{
								KickClient(client);
							}
						}
					}
				}
			}
		}
	}
}
//=============================
// TANK CONTROLLER
//=============================
public TankController()
{
	CountTanks();
	if (iNumTanks > 0)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsTank(i))
			{
				new index = GetSuperTankByRenderColor(GetEntityRenderColor(i));
				if (index >= 0 && index <= 16)
				{
					if (index != 0 || (index == 0 && bDefaultOverride))
					{
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", flTankSpeed[index]);
						switch(index)
						{
							case 1:
							{
								iTick += 1;
								if (iTick >= iSpawnCommonInterval)
								{
									for (new count=1; count<=iSpawnCommonAmount; count++)
									{
										CheatCommand(i, "z_spawn_old", "zombie area");
									}
									iTick = 0;
								}
							}
							case 3:
							{
								TeleportTank(i);
							}
							case 4:
							{
								if (TankAbility[i] == 0)
								{
									new random = GetRandomInt(1,iMeteorStormDelay);
									if (random == 1)
									{
										StartMeteorFall(i);
									}
								}
							}
							case 6:
							{
								HealTank(i);
							}
							case 7:
							{
								IgniteEntity(i, 1.0);
							}
							case 10:
							{
								InfectedCloak(i);
								if (CountSurvRange(i) == CountSurvivorsAliveAll())
								{
									SetEntityRenderMode(i, RenderMode:3);
      	 								SetEntityRenderColor(i, 100, 100, 100, 50);
									EmitSoundToAll("npc/infected/action/die/male/death_43.wav", i);
								}
								else
								{
									SetEntityRenderMode(i, RenderMode:3);
      	 								SetEntityRenderColor(i, 100, 100, 100, 150);
									EmitSoundToAll("npc/infected/action/die/male/death_42.wav", i);
								}
							}
							case 12:
							{
								SpawnWitch(i);
							}
							case 13:
							{
								if (ShieldsUp[i] > 0)
								{
									new glowcolor = RGB_TO_INT(120, 90, 150);
									SetEntProp(i, Prop_Send, "m_iGlowType", 2);
									SetEntProp(i, Prop_Send, "m_bFlashing", 2);
									SetEntProp(i, Prop_Send, "m_glowColorOverride", glowcolor);
								}
								else
								{
									SetEntProp(i, Prop_Send, "m_iGlowType", 0);
									SetEntProp(i, Prop_Send, "m_bFlashing", 0);
									SetEntProp(i, Prop_Send, "m_glowColorOverride", 0);
								}
							}
							case 14:
							{
								if (TankAbility[i] == 0)
								{
									SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
									new random = GetRandomInt(1,9);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
									}
								}
								else if (TankAbility[i] == 1)
								{
									SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", flCobaltSpecialSpeed);
								}
							}
							case 16:
							{
								SetEntityGravity(i, 0.5);
							}
						}
						if (bTankFireImmunity[index])
						{
							if (IsPlayerBurning(i))
							{
								ExtinguishEntity(i);
								SetEntPropFloat(i, Prop_Send, "m_burnPercent", 1.0);
							}
						}
					}
				}	
			}
		}
	}
}
public Action:TankSpawnTimer(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsTank(client))
		{
			new index = GetSuperTankByRenderColor(GetEntityRenderColor(client));
			if (index >= 0 && index <= 16)
			{
				if (index != 0 || (index == 0 && bDefaultOverride))
				{
					switch(index)
					{
						case 1:
						{
							CreateTimer(1.2, Timer_AttachSPAWN, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "spawn tank");
							}
						}
						case 2:
						{
//							SetEntProp(client, Prop_Send, "m_iGlowType", 3);
//							new glowcolor = RGB_TO_INT(50, 50, 50);
//							SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "killer tank");
							}
						}
						case 3:
						{
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "warp tank");
							}
						}
						case 4:
						{
							CreateTimer(0.1, MeteorTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
							CreateTimer(6.0, Timer_AttachMETEOR, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "meteor tank");
							}
						}
						case 5:
						{
							CreateTimer(2.0, Timer_AttachSPIT, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "Spitter Tank");
							}
						}
						case 6:
						{
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "heal tank");
							}
						}
						case 7:
						{
							CreateTimer(0.8, Timer_AttachFIRE,client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "devil tank");
							}
						}
						case 8:
						{
							CreateTimer(2.0, Timer_AttachICE, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "Ice Tank");
							}
						}
						case 9:
						{
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "Jockey Tank");
							}
						}
						case 10:
						{
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "ghost tank");
							}
						}
						case 11:
						{
							CreateTimer(0.8, Timer_AttachELEC, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "shock tank");
							}
						}
						case 12:
						{
							CreateTimer(2.0, Timer_AttachBLOOD, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "witch tank");
							}
						}
						case 13:
						{
							if (ShieldsUp[client] == 0)
							{
								ActivateShield(client);
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "Shield Tank");
							}
						}
						case 14:
						{
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "cobalt tank");
							}
						}
						case 15:
						{
							CreateTimer(0.1, JumperTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
							CreateTimer(1.0, JumpTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "jumper tank");
							}
						}
						case 16:
						{
							CreateTimer(0.1, GravityTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "gravity tank");
							}
						}
					}
					if (iTankExtraHealth[index] > 0)
					{
						new health = GetEntProp(client, Prop_Send, "m_iHealth");
						new maxhealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
						SetEntProp(client, Prop_Send, "m_iMaxHealth", maxhealth + iTankExtraHealth[index]);
						SetEntProp(client, Prop_Send, "m_iHealth", health + iTankExtraHealth[index]);
					}
					ResetInfectedAbility(client, flTankThrow[index]);
				}
			}
		}
	}
}
//=============================
// Speed on Ground and in Water
//=============================
SpeedRebuild(client)
{
	new Float:value;
	if (PlayerSpeed[client] > 0)
	{
		value = flShockStunMovement;
	}
	else
	{
		value = 1.0;
	}
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", value);
}
//=============================
// FUNCTIONS
//=============================
public OnEntityCreated(entity, const String:classname[])
{
	if (bSuperTanksEnabled)
	{
		if (StrEqual(classname, "tank_rock", true))
		{
			CreateTimer(0.1, RockThrowTimer, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}
public OnEntityDestroyed(entity)
{
	if (!IsServerProcessing()) return;

	if (bSuperTanksEnabled)
	{
		if (entity > 32 && IsValidEntity(entity))
		{
			new String:classname[32];
			GetEdictClassname(entity, classname, sizeof(classname));
			if (StrEqual(classname, "tank_rock", true))
			{
				new color = GetEntityRenderColor(entity);
				switch(color)
				{
					//Fire
					case 12800:
					{
						new prop = CreateEntityByName("prop_physics");
						if (prop > 32 && IsValidEntity(prop))
						{
							new Float:Pos[3];
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);
							Pos[2] += 10.0;
							DispatchKeyValue(prop, "model", "models/props_junk/gascan001a.mdl");
							DispatchSpawn(prop);
							SetEntData(prop, GetEntSendPropOffs(prop, "m_CollisionGroup"), 1, 1, true);
							TeleportEntity(prop, Pos, NULL_VECTOR, NULL_VECTOR);
							AcceptEntityInput(prop, "break");
						}
					}
					//Spitter
					case 12115128:
					{
						new x = CreateFakeClient("Spitter");
						if (x > 0)
						{
							new Float:Pos[3];
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);
							TeleportEntity(x, Pos, NULL_VECTOR, NULL_VECTOR);	
							SDKCallSpitBurst(x);
							KickClient(x);
						}
					}
				}
			}
		}
	}
}
stock Pick()
{
    	new count, clients[MaxClients];
    	for (new i=1; i<= MaxClients; i++)
    	{
        	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
            		clients[count++] = i; 
    	}
    	return clients[GetRandomInt(0,count-1)];
}
stock bool:IsSpecialInfected(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[32];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Smoker", false) || StrEqual(classname, "Boomer", false) || StrEqual(classname, "Hunter", false) || StrEqual(classname, "Spitter", false) || StrEqual(classname, "Jockey", false) || StrEqual(classname, "Charger", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsTank(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && !IsPlayerIncap(client) && TankAlive[client] == 1)
	{
		decl String:classname[32];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Tank", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}
stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}
bool:IsWitch(i)
{
	if (IsValidEntity(i))
	{
		decl String: classname[32];
		GetEdictClassname(i, classname, sizeof(classname));
		if (StrEqual(classname, "witch"))
			return true;
		return false;
	}
	return false;
}
stock CountTanks()
{
	iNumTanks = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsTank(i))
		{
			iNumTanks++;
		}
	}
}
public Action:TankLifeCheck(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		new lifestate = GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"));
		if (lifestate == 0)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				new Float: Origin[3], Float:Angles[3];
				GetClientAbsOrigin(client, Origin);
				GetClientAbsAngles(client, Angles);
				KickClient(client);
				TeleportEntity(bot, Origin, Angles, NULL_VECTOR);
				SpawnInfected(bot, 8, true);
			}
		}	
	}
}
stock RandomizeTank(client)
{
	if (!bDefaultTanks)
	{
		new count;
		new TempArray[16+1];

		for (new index=1; index<=16; index++)
		{
			if (bTankEnabled[index])
			{
				TempArray[count+1] = index;
				count++;	
			}
		}
		if (count > 0)
		{
			new random = GetRandomInt(1,count);
			new tankpick = TempArray[random];
			switch(tankpick)
			{
				case 1:
				{
					//Spawn
      	 				SetEntityRenderColor(client, 75, 95, 105, 255);
				}
				case 2:
				{
					//Smasher
      	 				SetEntityRenderColor(client, 70, 80, 100, 255);
				}
				case 3:
				{
					//Warp
      	 				SetEntityRenderColor(client, 130, 130, 255, 255);
				}
				case 4:
				{
					//Meteor
      	 				SetEntityRenderColor(client, 100, 25, 25, 255);
				}
				case 5:
				{
					//Spitter
      	 				SetEntityRenderColor(client, 12, 115, 128, 255);
				}
				case 6:
				{
					//Heal
      	 				SetEntityRenderColor(client, 100, 255, 200, 255);
				}
				case 7:
				{
					//Fire
      	 				SetEntityRenderColor(client, 128, 0, 0, 255);
				}
				case 8:
				{
					//Ice
					SetEntityRenderMode(client, RenderMode:3);
      	 				SetEntityRenderColor(client, 0, 100, 170, 200);
				}
				case 9:
				{
					//Jockey
      	 				SetEntityRenderColor(client, 255, 200, 0, 255);
				}
				case 10:
				{
					//Ghost
					SetEntityRenderMode(client, RenderMode:3);
      	 				SetEntityRenderColor(client, 100, 100, 100, 0);
				}
				case 11:
				{
					//Shock
      	 				SetEntityRenderColor(client, 100, 165, 255, 255);
				}
				case 12:
				{
					//Witch
      	 				SetEntityRenderColor(client, 255, 200, 255, 255);
				}
				case 13:
				{
					//Shield
      	 				SetEntityRenderColor(client, 135, 205, 255, 255);
				}
				case 14:
				{
					//Cobalt
      	 				SetEntityRenderColor(client, 0, 105, 255, 255);
				}
				case 15:
				{
					//Jumper
      	 				SetEntityRenderColor(client, 200, 255, 0, 255);
				}
				case 16:
				{
					//Gravity
      	 				SetEntityRenderColor(client, 33, 34, 35, 255);
				}
			}
		}
	}
}
stock SpawnInfected(client, Class, bool:bAuto=true)
{
	new bool:resetGhostState[MaxClients+1];
	new bool:resetIsAlive[MaxClients+1];
	new bool:resetLifeState[MaxClients+1];
	ChangeClientTeam(client, 3);
	new String:g_sBossNames[9+1][10]={"","smoker","boomer","hunter","spitter","jockey","charger","witch","tank","survivor"};
	decl String:options[30];
	if (Class < 1 || Class > 8) return false;
	if (GetClientTeam(client) != 3) return false;
	if (!IsClientInGame(client)) return false;
	if (IsPlayerAlive(client)) return false;
	
	for (new i=1; i<=MaxClients; i++){ 
		if (i == client) continue; //dont disable the chosen one
		if (!IsClientInGame(i)) continue; //not ingame? skip
		if (GetClientTeam(i) != 3) continue; //not infected? skip
		if (IsFakeClient(i)) continue; //a bot? skip
		
		if (IsPlayerGhost(i)){
			resetGhostState[i] = true;
			SetPlayerGhostStatus(i, false);
			resetIsAlive[i] = true; 
			SetPlayerIsAlive(i, true);
		}
		else if (!IsPlayerAlive(i)){
			resetLifeState[i] = true;
			SetPlayerLifeState(i, false);
		}
	}
	Format(options,sizeof(options),"%s%s",g_sBossNames[Class],(bAuto?" auto":""));
	CheatCommand(client, "z_spawn_old", options);
	if (IsFakeClient(client)) KickClient(client);
	// We restore the player's status
	for (new i=1; i<=MaxClients; i++){
		if (resetGhostState[i]) SetPlayerGhostStatus(i, true);
		if (resetIsAlive[i]) SetPlayerIsAlive(i, false);
		if (resetLifeState[i]) SetPlayerLifeState(i, true);
	}

	return true;
}
stock SetPlayerGhostStatus(client, bool:ghost)
{
	if(ghost){	
		SetEntProp(client, Prop_Send, "m_isGhost", 1, 1);
	}else{
		SetEntProp(client, Prop_Send, "m_isGhost", 0, 1);
	}
}
stock SetPlayerIsAlive(client, bool:alive)
{
	new offset = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	if (alive) SetEntData(client, offset, 1, 1, true);
	else SetEntData(client, offset, 0, 1, true);
}
stock SetPlayerLifeState(client, bool:ready)
{
	if (ready) SetEntProp(client, Prop_Data, "m_lifeState", 1, 1);
	else SetEntProp(client, Prop_Data, "m_lifeState", 0, 1);
}
stock bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	return false;
}
stock bool:IsPlayerIncap(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
stock NearestSurvivor(j)
{
    	new target, Float:InfectedPos[3], Float:SurvivorPos[3], Float:nearest = 0.0;
   	for (new i=1; i<=MaxClients; i++)
    	{
        	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && ChaseTarget[i] == 0)
		{
			GetClientAbsOrigin(j, InfectedPos);
			GetClientAbsOrigin(i, SurvivorPos);
                        new Float:distance = GetVectorDistance(InfectedPos, SurvivorPos);
                        if (nearest == 0.0)
			{
				nearest = distance;
				target = i;
			}
			else if (nearest > distance)
			{
				nearest = distance;
				target = i;
			}
		} 
    	}
    	return target;
}
stock CountSurvivorsAliveAll()
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			count++;
		}
	}
	return count;
}
stock CountInfectedAll()
{
	new count = 0;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			count++;
		}
	}
	return count;
}
bool:IsPlayerBurning(i)
{
	new Float:IsBurning = GetEntPropFloat(i, Prop_Send, "m_burnPercent");
	if (IsBurning > 0) 
		return true;
	return false;
}
public Action:CreateParticle(target, String:particlename[], Float:time, Float:origin)
{
	if (target > 0)
	{
   		new particle = CreateEntityByName("info_particle_system");
    		if (IsValidEntity(particle))
    		{
        		new Float:pos[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
			pos[2] += origin;
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchKeyValue(particle, "targetname", "particle");
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		}
    	}
}
public Action:AttachParticle(target, String:particlename[], Float:time, Float:origin)
{
	if (target > 0 && IsValidEntity(target))
	{
   		new particle = CreateEntityByName("info_particle_system");
    		if (IsValidEntity(particle))
    		{
        		new Float:pos[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
			pos[2] += origin;
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			decl String:tName[64];
			Format(tName, sizeof(tName), "Attach%d", target);
			DispatchKeyValue(target, "targetname", tName);
			GetEntPropString(target, Prop_Data, "m_iName", tName, sizeof(tName));
			DispatchKeyValue(particle, "scale", "");
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchKeyValue(particle, "parentname", tName);
			DispatchKeyValue(particle, "targetname", "particle");
			DispatchSpawn(particle);
			ActivateEntity(particle);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle);
			AcceptEntityInput(particle, "Enable");
			AcceptEntityInput(particle, "start");
			CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		}
    	}
}
public Action:PrecacheParticle(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.1, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	}  
}
public Action:DeleteParticles(Handle:timer, any:particle)
{
    	if (IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
            		AcceptEntityInput(particle, "Kill");
	}
}
public PerformFade(client, duration, unknown, type1, type2, const Color[4]) 
{
	switch(type1)
	{
		case 1: type1 = FFADE_IN;
		case 2: type1 = FFADE_OUT;
		case 4: type1 = FFADE_MODULATE;
		case 8: type1 = FFADE_STAYOUT;
		case 10: type1 = FFADE_PURGE;
	}
	switch(type2)
	{
		case 1: type2 = FFADE_IN;
		case 2: type2 = FFADE_OUT;
		case 4: type2 = FFADE_MODULATE;
		case 8: type2 = FFADE_STAYOUT;
		case 10: type2 = FFADE_PURGE;
	}
    	new Handle:hFadeClient=StartMessageOne("Fade", client);
    	BfWriteShort(hFadeClient, duration);
    	BfWriteShort(hFadeClient, unknown);
   	BfWriteShort(hFadeClient, (type1|type2));
    	BfWriteByte(hFadeClient, Color[0]);
    	BfWriteByte(hFadeClient, Color[1]);
    	BfWriteByte(hFadeClient, Color[2]);
    	BfWriteByte(hFadeClient, Color[3]);
    	EndMessage();
}
public ScreenShake(target, Float:intensity)
{
	new Handle:msg;
	msg = StartMessageOne("Shake", target);
	
	BfWriteByte(msg, 0);
 	BfWriteFloat(msg, intensity);
 	BfWriteFloat(msg, 10.0);
 	BfWriteFloat(msg, 3.0);
	EndMessage();
}
public Action:RockThrowTimer(Handle:timer)
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
	{
		new thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		if (thrower > 0 && thrower < 33 && IsTank(thrower))
		{
			new color = GetEntityRenderColor(thrower);
			switch(color)
			{
				//Fire Tank
				case 12800:
				{
      	 				SetEntityRenderColor(entity, 128, 0, 0, 255);
					CreateTimer(0.8, Timer_AttachFIRE_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				//Ice Tank
				case 0100170:
				{
					SetEntityRenderMode(entity, RenderMode:3);
					SetEntityRenderColor(entity, 0, 100, 170, 180);
				}
				//Jockey Tank
				case 2552000:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, JockeyThrow, thrower, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				//Spitter Tank
				case 12115128:
				{
					SetEntityRenderMode(entity, RenderMode:3);
      	 				SetEntityRenderColor(entity, 121, 151, 28, 30);
					CreateTimer(0.8, Timer_SpitSound, thrower, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(0.8, Timer_AttachSPIT_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				//Shock Tank
				case 100165255:
				{
					CreateTimer(0.8, Timer_AttachELEC_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				//Shield Tank
				case 135205255:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, PropaneThrow, thrower, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}
public Action:PropaneThrow(Handle:timer, any:client)
{
	new Float:velocity[3];
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");	
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity);
		if (v > 500.0)
		{
			new propane = CreateEntityByName("prop_physics");
			if (IsValidEntity(propane))
			{
				DispatchKeyValue(propane, "model", "models/props_junk/propanecanister001a.mdl");
				DispatchSpawn(propane);
				new Float:Pos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);	
				AcceptEntityInput(entity, "Kill");
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed*1.4);
				TeleportEntity(propane, Pos, NULL_VECTOR, velocity);
			}	
			return Plugin_Stop;
		}		
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
public Action:JockeyThrow(Handle:timer, any:client)
{
	new Float:velocity[3];
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");	
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity);
		if (v > 500.0)
		{
			new bot = CreateFakeClient("Jockey");
			if (bot > 0)
			{
				SpawnInfected(bot, 5, true);
				new Float:Pos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);	
				AcceptEntityInput(entity, "Kill");
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed*1.4);
				TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
			}	
			return Plugin_Stop;
		}		
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
public Action:JumpTimer(Handle:timer, any:client)
{
	if (client > 0 && IsTank(client))
	{
		new flags = GetEntityFlags(client);
		if (flags & FL_ONGROUND)
		{
			new random = GetRandomInt(1,iJumperJumpDelay);
			if (random == 1)
			{
				if (GetNearestSurvivorDist(client) > 200 && GetNearestSurvivorDist(client) < 2000)
				{
					FakeJump(client);
				}
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public FakeJump(client)
{
	if (client > 0 && IsTank(client))
	{
		new Float:vecVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
		if (vecVelocity[0] > 0.0 && vecVelocity[0] < 500.0)
		{
			vecVelocity[0] += 500.0;
		}
		else if (vecVelocity[0] < 0.0 && vecVelocity[0] > -500.0)
		{
			vecVelocity[0] += -500.0;
		}
		if (vecVelocity[1] > 0.0 && vecVelocity[1] < 500.0)
		{
			vecVelocity[1] += 500.0;
		}
		else if (vecVelocity[1] < 0.0 && vecVelocity[1] > -500.0)
		{
			vecVelocity[1] += -500.0;
		}
		vecVelocity[2] += 750.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	}
}
public SkillFlameClaw(target)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			IgniteEntity(target, 3.0);
			EmitSoundToAll("ambient/fire/gascan_ignite1.wav", target);
			PerformFade(target, 500, 250, 10, 1, {100, 50, 0, 150});
		}
	}
}

public SkillIceClaw(target)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			SetEntityRenderMode(target, RenderMode:3);
			SetEntityRenderColor(target, 0, 100, 170, 180);
			SetEntityMoveType(target, MOVETYPE_VPHYSICS);
			CreateTimer(5.0, Timer_UnFreeze, target, TIMER_FLAG_NO_MAPCHANGE);
			PerformFade(target, 500, 250, 10, 1, {0, 50, 100, 150});
		}
	}
}

public SkillFlameGush(target)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 3)
		{
			decl Float:pos[3];
			GetClientAbsOrigin(target, pos);
			new entity = CreateEntityByName("prop_physics");
			if (IsValidEntity(entity))
			{
				pos[2] += 10.0;
				DispatchKeyValue(entity, "model", "models/props_junk/gascan001a.mdl");
				DispatchSpawn(entity);
				SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
				TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(entity, "break");
			}
		}
	}
}
public SkillGravityClaw(target)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			SetEntityGravity(target, 0.3);
			CreateTimer(2.0, Timer_ResetGravity, target, TIMER_FLAG_NO_MAPCHANGE);
			PerformFade(target, 500, 250, 10, 1, {100, 50, 100, 150});
			ScreenShake(target, 5.0);
		}
	}
}
public Action:MeteorTankTimer(Handle:timer, any:client)
{
	if (client > 0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 1002525)
		{
			new Float:Origin[3], Float:Angles[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
			new ent[5];
			for (new count=1; count<=4; count++)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override");
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, sizeof(tName), "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));

					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count]);
					switch(count)
					{
						case 1:SetVariantString("relbow");
						case 2:SetVariantString("lelbow");
						case 3:SetVariantString("rshoulder");
						case 4:SetVariantString("lshoulder");
					}
					AcceptEntityInput(ent[count], "SetParentAttachment");
					AcceptEntityInput(ent[count], "Enable");
					AcceptEntityInput(ent[count], "DisableCollision");
					switch(count)
					{
//						case 1,2:SetEntPropFloat(ent[count], Prop_Data, "m_flModelScale", 0.4);
//						case 3,4:SetEntPropFloat(ent[count], Prop_Data, "m_flModelScale", 0.5);
					}
					SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", client);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
			}
		}
	}
}
public Action:JumperTankTimer(Handle:timer, any:client)
{
	if (client > 0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 2002550)
		{
			new Float:Origin[3], Float:Angles[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
			Angles[0] += 90.0;
			new ent[3];
			for (new count=1; count<=2; count++)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override");
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, sizeof(tName), "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));

					DispatchKeyValue(ent[count], "model", "models/props_vehicles/tire001c_car.mdl");
					DispatchKeyValue(ent[count], "targetname", "TireEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count]);
					switch(count)
					{
						case 1:SetVariantString("rfoot");
						case 2:SetVariantString("lfoot");
					}
					AcceptEntityInput(ent[count], "SetParentAttachment");
					AcceptEntityInput(ent[count], "Enable");
					AcceptEntityInput(ent[count], "DisableCollision");
					SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", client);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
			}
		}
	}
}
public Action:GravityTankTimer(Handle:timer, any:client)
{
	if (client > 0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 333435)
		{
			new Float:Origin[3], Float:Angles[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
			Angles[0] += -90.0;
			new entity = CreateEntityByName("beam_spotlight");
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, sizeof(tName), "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));

				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "100 100 100");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment");
				AcceptEntityInput(entity, "Enable");
				AcceptEntityInput(entity, "DisableCollision");
				SetEntProp(entity, Prop_Send, "m_hOwnerEntity", client);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
			new blackhole = CreateEntityByName("point_push");
			if (IsValidEntity(blackhole))
			{
				decl String:tName[64];
				Format(tName, sizeof(tName), "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));

				DispatchKeyValue(blackhole, "targetname", "BlackholeEntity");
				DispatchKeyValue(blackhole, "parentname", tName);
				DispatchKeyValueVector(blackhole, "origin", Origin);
				DispatchKeyValueVector(blackhole, "angles", Angles);
				DispatchKeyValue(blackhole, "radius", "750");
				DispatchKeyValueFloat(blackhole, "magnitude", flGravityPullForce);
				DispatchKeyValue(blackhole, "spawnflags", "8");
				SetVariantString(tName);
				AcceptEntityInput(blackhole, "SetParent", blackhole, blackhole);
				AcceptEntityInput(blackhole, "Enable");
//				SetEntProp(blackhole, Prop_Send, "m_glowColorOverride", client);
			}
		}
	}
}
public Action:BlurEffect(Handle:timer, any:client)
{
	if (client > 0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3], Float:TankAng[3];
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, Prop_Send, "m_nSequence");
		new entity = CreateEntityByName("prop_dynamic");
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "6");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision");
			SetEntityRenderColor(entity, 0, 105, 255, 255);
			SetEntProp(entity, Prop_Send, "m_nSequence", Anim);
			SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 15.0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect, entity, TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Continue;
		}		
	}
	return Plugin_Stop;
}
public Action:RemoveBlurEffect(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic"))
		{
			decl String:model[128];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, "models/infected/hulk.mdl"))
			{
				AcceptEntityInput(entity, "Kill");
			}
		}	
	}
}
public SkillSmashClaw(target)
{
	new health = GetEntProp(target, Prop_Data, "m_iHealth");
	if (health > 1 && !IsPlayerIncap(target))
	{
		SetEntProp(target, Prop_Data, "m_iHealth", iSmasherMaimDamage);
		new Float:hbuffer = float(health) - float(iSmasherMaimDamage);
		if (hbuffer > 0.0)
		{
			SetEntPropFloat(target, Prop_Send, "m_healthBuffer", hbuffer);
		}
	}
	EmitSoundToAll("player/charger/hit/charger_smash_02.wav", target);
	PerformFade(target, 800, 300, 10, 1, {10, 0, 0, 250});
	ScreenShake(target, 30.0);
}
public SkillSmashClawKill(client, attacker)
{
	EmitSoundToAll("player/tank/voice/growl/tank_climb_01.wav", attacker);
	AttachParticle(client, PARTICLE_EXPLODE, 0.1, 0.0);
	DealDamagePlayer(client, attacker, 2, iSmasherCrushDamage);
	DealDamagePlayer(client, attacker, 2, iSmasherCrushDamage);
	CreateTimer(0.1, RemoveDeathBody, client, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:RemoveDeathBody(Handle:timer, any:client)
{
	if (bSmasherRemoveBody)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != INVALID_ENT_REFERENCE)
				{
					new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
					if (client == owner)
					{
						AcceptEntityInput(entity, "Kill");
					}
				}
			}
		}
	}
}
public SkillElecClaw(target, tank)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			PlayerSpeed[target] += 3;
			new Handle:Pack = CreateDataPack();
			WritePackCell(Pack, target);
			WritePackCell(Pack, tank);
			WritePackCell(Pack, 4);
			CreateTimer(5.0, Timer_Volt, Pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			PerformFade(target, 250, 100, 10, 1, {50, 150, 250, 100});
			ScreenShake(target, 15.0);
			AttachParticle(target, PARTICLE_ELEC, 2.0, 30.0);
			EmitSoundToAll("ambient/energy/zap1.wav", target);
		}
	}
}
public Action:Timer_Volt(Handle:timer, any:Pack)
{
	ResetPack(Pack, false);
	new client = ReadPackCell(Pack);
	new tank = ReadPackCell(Pack);
	new amount = ReadPackCell(Pack);

	if (client > 0 && tank > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && PlayerSpeed[client] == 0 && IsTank(tank))
		{
			if (amount > 0)
			{
				PlayerSpeed[client] += 2;
				ScreenShake(client, 2.0);
				DealDamagePlayer(client, tank, 2, iShockStunDamage);
				AttachParticle(client, PARTICLE_ELEC, 2.0, 30.0);
				new random = GetRandomInt(1,2);
				if (random == 1) 
				{
					EmitSoundToAll("ambient/energy/zap5.wav", client);
				}
				else
				{
					EmitSoundToAll("ambient/energy/zap7.wav", client);
				}
				ResetPack(Pack, true);
				WritePackCell(Pack, client);
				WritePackCell(Pack, tank);
				WritePackCell(Pack, amount - 1);
				return Plugin_Continue;
			}
		}
	}
	CloseHandle(Pack);
	return Plugin_Stop;
}
StartMeteorFall(client)
{
	TankAbility[client] = 1;
	decl Float:pos[3];
	GetClientEyePosition(client, pos);
	
	new Handle:h=CreateDataPack();
	WritePackCell(h, client);
	WritePackFloat(h, pos[0]);
	WritePackFloat(h, pos[1]);
	WritePackFloat(h, pos[2]);
	WritePackFloat(h, GetEngineTime());
	
	CreateTimer(0.6, UpdateMeteorFall, h, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:UpdateMeteorFall(Handle:timer, any:h)
{
	ResetPack(h);
	decl Float:pos[3];
	new client = ReadPackCell(h);
 	
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);

	new Float:time = ReadPackFloat(h);
	if ((GetEngineTime() - time) > 5.0)
	{
		TankAbility[client] = 0;
	}
	new entity = -1;
	if (IsTank(client) && TankAbility[client] == 1)
	{
		decl Float:angle[3], Float:velocity[3], Float:hitpos[3];
		angle[0] = 0.0 + GetRandomFloat(-20.0, 20.0);
		angle[1] = 0.0 + GetRandomFloat(-20.0, 20.0);
		angle[2] = 60.0;
		
		GetVectorAngles(angle, angle);
		GetRayHitPos(pos, angle, hitpos, client, true);
		new Float:dis = GetVectorDistance(pos, hitpos);
		if (GetVectorDistance(pos, hitpos) > 2000.0)
		{
			dis = 1600.0;
		}
		decl Float:t[3];
		MakeVectorFromPoints(pos, hitpos, t);
		NormalizeVector(t,t);
		ScaleVector(t, dis - 40.0);
		AddVectors(pos, t, hitpos);
		
		if (dis > 100.0)
		{
			new ent = CreateEntityByName("tank_rock");
			if (ent > 0)
			{
				DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl"); 
				DispatchSpawn(ent);  
				decl Float:angle2[3];
				angle2[0] = GetRandomFloat(-180.0, 180.0);
				angle2[1] = GetRandomFloat(-180.0, 180.0);
				angle2[2] = GetRandomFloat(-180.0, 180.0);

				velocity[0] = GetRandomFloat(0.0, 350.0);
				velocity[1] = GetRandomFloat(0.0, 350.0);
				velocity[2] = GetRandomFloat(0.0, 30.0);

				TeleportEntity(ent, hitpos, angle2, velocity);
				ActivateEntity(ent);
	 
				AcceptEntityInput(ent, "Ignite");
				SetEntProp(ent, Prop_Send, "m_hOwnerEntity", client);
			}
		} 
	}
	else if (TankAbility[client] == 0)
	{
		while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
		{
			new ownerent = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (client == ownerent)
			{
				ExplodeMeteor(entity, ownerent);
			}
		}
		CloseHandle(h);
		return Plugin_Stop;
	}
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
	{
		new ownerent = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
		if (client == ownerent)
		{
			if (OnGroundUnits(entity) < 200.0)
			{
				ExplodeMeteor(entity, ownerent);
			}
		}
	}
	return Plugin_Continue;	
}
public Float:OnGroundUnits(i_Ent)
{
	if (!(GetEntityFlags(i_Ent) & (FL_ONGROUND)))
	{ 
		decl Handle:h_Trace, Float:f_Origin[3], Float:f_Position[3], Float:f_Down[3] = { 90.0, 0.0, 0.0 };
		
		GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin);
		h_Trace = TR_TraceRayFilterEx(f_Origin, f_Down, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceRayDontHitSelfAndLive, i_Ent);

		if (TR_DidHit(h_Trace))
		{
			decl Float:f_Units;
			TR_GetEndPosition(f_Position, h_Trace);
			
			f_Units = f_Origin[2] - f_Position[2];

			CloseHandle(h_Trace);
			
			return f_Units;
		}
		CloseHandle(h_Trace);
	} 
	
	return 0.0;
}
stock GetRayHitPos(Float:pos[3], Float:angle[3], Float:hitpos[3], ent=0, bool:useoffset=false)
{
	new Handle:trace;
	new hit=0;
	
	trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndLive, ent);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit=TR_GetEntityIndex( trace);
	}
	CloseHandle(trace);
	
	if (useoffset)
	{
		decl Float:v[3];
		MakeVectorFromPoints(hitpos, pos, v);
		NormalizeVector(v, v);
		ScaleVector(v, 15.0);
		AddVectors(hitpos, v, hitpos);
	}
	return hit;
}
stock ExplodeMeteor(entity, client)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[20];
		GetEdictClassname(entity, classname, 20);
		if (!StrEqual(classname, "tank_rock", true))
		{
			return;
		}

		new Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);	
		pos[2]+=50.0;
		AcceptEntityInput(entity, "Kill");
	
		new ent = CreateEntityByName("prop_physics"); 		
		DispatchKeyValue(ent, "model", "models/props_junk/propanecanister001a.mdl"); 
		DispatchSpawn(ent); 
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Break");

		new pointHurt = CreateEntityByName("point_hurt");   
		DispatchKeyValueFloat(pointHurt, "Damage", flMeteorStormDamage);     
		DispatchKeyValue(pointHurt, "DamageType", "2");  
		DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(pointHurt, "DamageRadius", 200.0);  
		DispatchSpawn(pointHurt);
		TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
		AcceptEntityInput(pointHurt, "Hurt", client);    
		CreateTimer(0.1, DeletePointHurt, pointHurt, TIMER_FLAG_NO_MAPCHANGE); 
		
		new push = CreateEntityByName("point_push");         
  		DispatchKeyValueFloat (push, "magnitude", 600.0);                     
		DispatchKeyValueFloat (push, "radius", 200.0*1.0);                     
  		SetVariantString("spawnflags 24");                     
		AcceptEntityInput(push, "AddOutput");
 		DispatchSpawn(push);   
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
 		AcceptEntityInput(push, "Enable", -1, -1);
		CreateTimer(0.5, DeletePushForce, push, TIMER_FLAG_NO_MAPCHANGE);
	}
} 
public Action:DeletePushForce(Handle:timer, any:ent)
{
	 if (IsValidEntity(ent))
	 {
	 	decl String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_push", false))
		{
			AcceptEntityInput(ent, "Kill"); 
		}
	 }
}
public Action:DeletePointHurt(Handle:timer, any:ent)
{
	 if (IsValidEntity(ent))
	 {
		decl String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_hurt", false))
		{
			AcceptEntityInput(ent, "Kill"); 
		}
	 }
}
public bool:TraceRayDontHitSelfAndLive(entity, mask, any:data)
{
	if (entity == data) 
	{
		return false; 
	}
	else if (entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}
stock ExecTankDeath(client)
{
	TankAlive[client] = 0;
	TankAbility[client] = 0;

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
	{
		decl String:model[128];
            	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, "models/props_debris/concrete_chunk01a.mdl"))
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
		else if (StrEqual(model, "models/props_vehicles/tire001c_car.mdl"))
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
		else if (StrEqual(model, "models/props_unique/airport/atlas_break_ball.mdl"))
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
	while ((entity = FindEntityByClassname(entity, "beam_spotlight")) != INVALID_ENT_REFERENCE)
	{
		new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
		if (owner == client)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	while ((entity = FindEntityByClassname(entity, "point_push")) != INVALID_ENT_REFERENCE)
	{
//		new owner = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
		if (owner == client)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	switch(iTankWave)
	{
		case 1: CreateTimer(5.0, TimerTankWave2, _, TIMER_FLAG_NO_MAPCHANGE);
		case 2: CreateTimer(5.0, TimerTankWave3, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:TimerTankWave2(Handle:timer)
{
	CountTanks();
	if (iNumTanks == 0)
	{
		iTankWave = 2;
	}
}
public Action:TimerTankWave3(Handle:timer)
{
	CountTanks();
	if (iNumTanks == 0)
	{
		iTankWave = 3;
	}
}
public Action:SpawnTankTimer(Handle:timer)
{
	CountTanks();
	if (iTankWave == 1)
	{
		if (iNumTanks < iWave1Cvar)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
	else if (iTankWave == 2)
	{
		if (iNumTanks < iWave2Cvar)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
	else if (iTankWave == 3)
	{
		if (iNumTanks < iWave3Cvar)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
}
public Action:Timer_UnFreeze(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			SetEntityRenderMode(client, RenderMode:3);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}
public Action:Timer_ResetGravity(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsClientInGame(client))
		{
			SetEntityGravity(client, 1.0);
		}
	}
}
public Action:Timer_AttachSPAWN(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 7595105)
	{
		AttachParticle(client, PARTICLE_SPAWN, 1.2, 0.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachFIRE(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 12800)
	{
		AttachParticle(client, PARTICLE_FIRE, 0.8, 0.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachFIRE_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String: classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock"))
		{
			IgniteEntity(entity, 100.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
public Action:Timer_AttachICE(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 0100170)
	{
		AttachParticle(client, PARTICLE_ICE, 2.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_SpitSound(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 12115128)
	{
		EmitSoundToAll("player/spitter/voice/warn/spitter_spit_02.wav", client);
	}
}
public Action:Timer_AttachSPIT(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 12115128)
	{
		AttachParticle(client, PARTICLE_SPIT, 2.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachSPIT_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String: classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock"))
		{
			AttachParticle(entity, PARTICLE_SPITPROJ, 0.8, 0.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
public Action:Timer_AttachELEC(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 100165255)
	{
		AttachParticle(client, PARTICLE_ELEC, 0.8, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachELEC_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String: classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock"))
		{
			AttachParticle(entity, PARTICLE_ELEC, 0.8, 0.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
public Action:Timer_AttachBLOOD(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 255200255)
	{
		AttachParticle(client, PARTICLE_BLOOD, 0.8, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachMETEOR(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 1002525)
	{
		AttachParticle(client, PARTICLE_METEOR, 6.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:ActivateShieldTimer(Handle:timer, any:client)
{
	ActivateShield(client);
}
stock ActivateShield(client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 135205255 && ShieldsUp[client] == 0)
	{
		decl Float:Origin[3];
		GetClientAbsOrigin(client, Origin);
		Origin[2] -= 120.0;
		new entity = CreateEntityByName("prop_dynamic");
		if (IsValidEntity(entity))
		{
			decl String:tName[64];
			Format(tName, sizeof(tName), "Tank%d", client);
			DispatchKeyValue(client, "targetname", tName);
			GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));
			DispatchKeyValue(entity, "targetname", "Player");
			DispatchKeyValue(entity, "parentname", tName);
			DispatchKeyValue(entity, "model", "models/props_unique/airport/atlas_break_ball.mdl");
			DispatchKeyValueVector(entity, "origin", Origin);
			DispatchSpawn(entity);
			SetVariantString(tName);
			AcceptEntityInput(entity, "SetParent", entity, entity);
			SetEntityRenderMode(entity, RenderMode:3);
      	 		SetEntityRenderColor(entity, 25, 125, 125, 50);
			SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
			SetEntProp(entity, Prop_Send, "m_hOwnerEntity", client);
		}
		ShieldsUp[client] = 1;
	}
}
stock DeactivateShield(client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 135205255 && ShieldsUp[client] == 1)
	{
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
		{
			decl String:model[128];
            		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, "models/props_unique/airport/atlas_break_ball.mdl"))
			{
				new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
				if (owner == client)
				{
					AcceptEntityInput(entity, "Kill");
				}
			}
		}
		CreateTimer(flShieldShieldsDownInterval, ActivateShieldTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		ShieldsUp[client] = 0;
	}
}
stock TeleportTank(client)
{
	new random = GetRandomInt(1,iWarpTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3], Float:Angles[3];
			GetClientAbsOrigin(target, Origin);
                        GetClientAbsAngles(target, Angles);
			CreateParticle(client, PARTICLE_WARP, 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
}
stock CountWitches()
{
	new count;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		count++;
	}
	return count;
}
stock SpawnWitch(client)
{
	new count;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
	{
		if (count < 4 && CountWitches() < iWitchMaxWitches)
		{
			decl Float:TankPos[3], Float:InfectedPos[3], Float:InfectedAng[3];
                        GetClientAbsOrigin(client, TankPos);
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", InfectedPos);
			GetEntPropVector(entity, Prop_Send, "m_angRotation", InfectedAng);
			new Float:distance = GetVectorDistance(InfectedPos, TankPos);
                        if (distance < 100.0)
			{
				AcceptEntityInput(entity, "Kill");
				new witch = CreateEntityByName("witch");
				DispatchSpawn(witch);
				ActivateEntity(witch);
				TeleportEntity(witch, InfectedPos, InfectedAng, NULL_VECTOR);
				SetEntProp(witch, Prop_Send, "m_hOwnerEntity", 255200255);
				count++;
			}
		}
	}
}
stock HealTank(client)
{
	new infectedfound = 0;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
	{
		decl Float:TankPos[3], Float:InfectedPos[3];
               	GetClientAbsOrigin(client, TankPos);
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", InfectedPos);
		new Float:distance = GetVectorDistance(InfectedPos, TankPos);
                if (distance < 500)
		{
			new health = GetEntProp(client, Prop_Send, "m_iHealth");
			new maxhealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
			if (health <= (maxhealth - iHealHealthCommons) && health > 500)
			{
				SetEntProp(client, Prop_Data, "m_iHealth", health + iHealHealthCommons);
			}
			else if (health > 500)
			{
				SetEntProp(client, Prop_Data, "m_iHealth", maxhealth);
			}
			if (health > 500)
			{
//				new glowcolor = RGB_TO_INT(0, 185, 0);
//				SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
//				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
//				SetEntProp(client, Prop_Send, "m_bFlashing", 1);
				infectedfound = 1;
			}
		}
	}
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3], Float:InfectedPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, InfectedPos);
                       	new Float:distance = GetVectorDistance(TankPos, InfectedPos);
                        if (distance < 500)
			{
				new health = GetEntProp(client, Prop_Send, "m_iHealth");
				new maxhealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
				if (health <= (maxhealth - iHealHealthSpecials) && health > 500)
				{
					SetEntProp(client, Prop_Data, "m_iHealth", health + iHealHealthSpecials);
				}
				else if (health > 500)
				{
					SetEntProp(client, Prop_Data, "m_iHealth", maxhealth);
				}
				if (health > 500 && infectedfound < 2)
				{
//					new glowcolor = RGB_TO_INT(0, 220, 0);
//					SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
//					SetEntProp(client, Prop_Send, "m_iGlowType", 3);
//					SetEntProp(client, Prop_Send, "m_bFlashing", 1);
					infectedfound = 1;
				}
			}
		}
		else if (IsTank(i) && i != client)
		{
			decl Float:TankPos[3], Float:InfectedPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, InfectedPos);
                       	new Float:distance = GetVectorDistance(TankPos, InfectedPos);
                        if (distance < 500)
			{
				new health = GetEntProp(client, Prop_Send, "m_iHealth");
				new maxhealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
				if (health <= (maxhealth - iHealHealthTanks) && health > 500)
				{
					SetEntProp(client, Prop_Data, "m_iHealth", health + iHealHealthTanks);
				}
				else if (health > 500)
				{
					SetEntProp(client, Prop_Data, "m_iHealth", maxhealth);
				}
				if (health > 500)
				{
//					new glowcolor = RGB_TO_INT(0, 255, 0);
//					SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
//					SetEntProp(client, Prop_Send, "m_iGlowType", 3);
//					SetEntProp(client, Prop_Send, "m_bFlashing", 1);
					infectedfound = 2;
				}
			}
		}
	}
	if (infectedfound == 0)
	{
//		SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
//		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
//		SetEntProp(client, Prop_Send, "m_bFlashing", 0);
	}
}
stock InfectedCloak(client)
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3], Float:InfectedPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, InfectedPos);
                       	new Float:distance = GetVectorDistance(TankPos, InfectedPos);
                        if (distance < 500)
			{
				SetEntityRenderMode(i, RenderMode:3);
      	 			SetEntityRenderColor(i, 255, 255, 255, 50);
			}
			else
			{
				SetEntityRenderMode(i, RenderMode:3);
      	 			SetEntityRenderColor(i, 255, 255, 255, 255);
			}
		}
	}
}
stock CountSurvRange(client)
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			decl Float:TankPos[3], Float:PlayerPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, PlayerPos);
                       	new Float:distance = GetVectorDistance(TankPos, PlayerPos);
                        if (distance > 120)
			{
				count++;
			}
		}
	}
	return count;
}
stock GetEntityRenderColor(entity)
{
	if (entity > 0)
	{
		new offset = GetEntSendPropOffs(entity, "m_clrRender");
		new r = GetEntData(entity, offset, 1);
		new g = GetEntData(entity, offset+1, 1);
		new b = GetEntData(entity, offset+2, 1);
		decl String:rgb[10];
		Format(rgb, sizeof(rgb), "%d%d%d", r, g, b);
		new color = StringToInt(rgb);
		return color;
	}
	return 0;	
}
stock RGB_TO_INT(red, green, blue) 
{
	return (blue * 65536) + (green * 256) + red;
}
public Action:OnPlayerTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (bSuperTanksEnabled)
	{
		if (damage > 0.0 && IsValidClient(victim))
		{
			decl String:classname[32];
			if (GetClientTeam(victim) == 2)
			{
				if (IsWitch(attacker))
				{
					if (GetEntProp(attacker, Prop_Send, "m_hOwnerEntity") == 255200255)
					{
						damage = 16.0;
					}
				}
				else if (IsTank(attacker) && damagetype != 2)
				{
					new color = GetEntityRenderColor(attacker);
					switch(color)
					{
						//Fire Tank
						case 12800:
						{
							GetEdictClassname(inflictor, classname, sizeof(classname));
							if (StrEqual(classname, "weapon_tank_claw") || StrEqual(classname, "weapon_tank_rock"))
							{
								SkillFlameClaw(victim);
							}
						}
						//Gravity Tank
						case 333435:
						{
							GetEdictClassname(inflictor, classname, sizeof(classname));
							if (StrEqual(classname, "weapon_tank_claw"))
							{
								SkillGravityClaw(victim);
							}
						}
						//Ice Tank
						case 0100170:
						{
							new flags = GetEntityFlags(victim);
							if (flags & FL_ONGROUND)
							{
								new random = GetRandomInt(1,3);
								if (random == 1)
								{
									SkillIceClaw(victim);
								}
							}
						}
						//Cobalt Tank
						case 0105255:
						{
							GetEdictClassname(inflictor, classname, sizeof(classname));
							if (StrEqual(classname, "weapon_tank_claw"))
							{
								TankAbility[attacker] = 0;
							}
						}
						//Smasher Tank
						case 7080100:
						{
							GetEdictClassname(inflictor, classname, sizeof(classname));
							if (StrEqual(classname, "weapon_tank_claw"))
							{
								new random = GetRandomInt(1,2);
								if (random == 1)
								{
									SkillSmashClawKill(victim, attacker);
								}
								else
								{
									SkillSmashClaw(victim);
								}
							}
						}
						//Spawn Tank
						case 7595105:
						{
							GetEdictClassname(inflictor, classname, sizeof(classname));
							if (StrEqual(classname, "weapon_tank_claw"))
							{
								new random = GetRandomInt(1,4);
								if (random == 1)
								{
//									SDKCallVomitOnPlayer(victim, attacker);
								}
							}
						}
						//Shock Tank
						case 100165255:
						{
							GetEdictClassname(inflictor, classname, sizeof(classname));
							if (StrEqual(classname, "weapon_tank_claw"))
							{
								SkillElecClaw(victim, attacker);
							}
						}
						//Warp Tank
						case 130130255:
						{
							GetEdictClassname(inflictor, classname, sizeof(classname));
							if (StrEqual(classname, "weapon_tank_claw"))
							{
								new dmg = RoundFloat(damage / 2);
								DealDamagePlayer(victim, attacker, 2, dmg);
							}
						}
					}
				}
			}
			else if (IsTank(victim))
			{
				if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464)
				{
					new index = GetSuperTankByRenderColor(GetEntityRenderColor(victim));
					if (index >= 0 && index <= 16)
					{
						if (bTankFireImmunity[index])
						{
							if (index != 0 || (index == 0 && bDefaultOverride))
							{
								return Plugin_Handled;
							}
						}
					}
				}
				if (IsSurvivor(attacker))
				{
					new color = GetEntityRenderColor(victim);
					switch(color)
					{
						//Fire Tank
						case 12800:
						{
							GetEdictClassname(inflictor, classname, sizeof(classname));
							if (StrEqual(classname, "weapon_melee"))
							{
								new random = GetRandomInt(1,4);
								if (random == 1)
								{
									SkillFlameGush(victim);
								}
							}
						}
						//Meteor Tank
						case 1002525:
						{
							GetEdictClassname(inflictor, classname, sizeof(classname));
							if (StrEqual(classname, "weapon_melee"))
							{
								new random = GetRandomInt(1,2);
								if (random == 1)
								{
									if (TankAbility[victim] == 0)
									{
										StartMeteorFall(victim);
									}
								}
							}
						}
						//Spitter Tank
						case 12115128:
						{
							GetEdictClassname(inflictor, classname, sizeof(classname));
							if (StrEqual(classname, "weapon_melee"))
							{
								new random = GetRandomInt(1,4);
								if (random == 1)
								{
									new x = CreateFakeClient("Spitter");
									if (x > 0)
									{
										new Float:Pos[3];
										GetClientAbsOrigin(victim, Pos);
										TeleportEntity(x, Pos, NULL_VECTOR, NULL_VECTOR);	
										SDKCallSpitBurst(x);
										KickClient(x);
									}
								}
							}
						}
						//Ghost Tank
						case 100100100:
						{
							if (bGhostDisarm)
							{
								GetEdictClassname(inflictor, classname, sizeof(classname));
								if(StrEqual(classname, "weapon_melee"))
								{
									new random = GetRandomInt(1,4);
									if (random == 1)
									{
										ForceWeaponDrop(attacker);
										EmitSoundToClient(attacker, "npc/infected/action/die/male/death_42.wav", victim);
									}
								}
							}
						}
						//Shield Tank
						case 135205255:
						{
							if (damagetype == 134217792 || damagetype == 33554432 || damagetype == 16777280)
							{
								if (ShieldsUp[victim] == 1)
								{
									DeactivateShield(victim);
								}
							}
							else
							{
								if (ShieldsUp[victim] == 1)
								{
									return Plugin_Handled;
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Changed;
}
stock DealDamagePlayer(target, attacker, dmgtype, dmg)
{
	if (target > 0 && target <= MaxClients)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target))
		{
   	 		decl String:damage[16];
    			IntToString(dmg, damage, 16);
   	 		decl String:type[16];
    			IntToString(dmgtype, type, 16);
			new pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				DispatchKeyValue(target, "targetname", "hurtme");
				DispatchKeyValue(pointHurt, "Damage", damage);
				DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
				DispatchKeyValue(pointHurt, "DamageType", type);
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt, "Hurt", attacker);
				AcceptEntityInput(pointHurt, "Kill");
				DispatchKeyValue(target, "targetname", "donthurtme");
			}
		}
	}
}
stock DealDamageEntity(target, attacker, dmgtype, dmg)
{
	if (target > 32)
	{
		if (IsValidEntity(target))
		{
   	 		decl String:damage[16];
    			IntToString(dmg, damage, 16);
   	 		decl String:type[16];
    			IntToString(dmgtype, type, 16);
			new pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				DispatchKeyValue(target, "targetname", "hurtme");
				DispatchKeyValue(pointHurt, "Damage", damage);
				DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
				DispatchKeyValue(pointHurt, "DamageType", type);
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt, "Hurt", attacker);
				AcceptEntityInput(pointHurt, "Kill");
				DispatchKeyValue(target, "targetname", "donthurtme");
			}
		}
	}
}
stock ForceWeaponDrop(client)
{
	if (GetPlayerWeaponSlot(client, 1) > 0)
	{
		new weapon = GetPlayerWeaponSlot(client, 1);
		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
	}
}
stock ResetInfectedAbility(client, Float:time)
{
	if (client > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{
			new ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
			if (ability > 0)
			{
				SetEntPropFloat(ability, Prop_Send, "m_duration", time);
				SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() + time);
			}
		}
	}
}
stock GetNearestSurvivorDist(client)
{
    	new Float:PlayerPos[3], Float:TargetPos[3], Float:nearest = 0.0, Float:distance = 0.0;
	if (client > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetClientAbsOrigin(client, PlayerPos);
   			for (new i=1; i<=MaxClients; i++)
    			{
        			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					GetClientAbsOrigin(i, TargetPos);
                        		distance = GetVectorDistance(PlayerPos, TargetPos);
                        		if (nearest == 0.0)
					{
						nearest = distance;
					}
					else if (nearest > distance)
					{
						nearest = distance;
					}
				}
			}
		} 
    	}
    	return RoundFloat(distance);
}
stock GetSuperTankByRenderColor(color)
{
	switch(color)
	{
		//Fire Tank
		case 12800:
		{
			return 7;
		}
		//Gravity Tank
		case 333435:
		{
			return 16;
		}
		//Ice Tank
		case 0100170:
		{
			return 8;
		}
		//Cobalt Tank
		case 0105255:
		{
			return 14;
		}
		//Meteor Tank
		case 1002525:
		{
			return 4;
		}
		//Jumper Tank
		case 2002550:
		{
			return 15;
		}
		//Jockey Tank
		case 2552000:
		{
			return 9;
		}
		//Smasher Tank
		case 7080100:
		{
			return 2;
		}
		//Spawn Tank
		case 7595105:
		{
			return 1;
		}		
		//Spitter Tank
		case 12115128:
		{
			return 5;
		}
		//Heal Tank
		case 100255200:
		{
			return 6;
		}				
		//Ghost Tank
		case 100100100:
		{
			return 10;
		}
		//Shock Tank
		case 100165255:
		{
			return 11;
		}
		//Warp Tank
		case 130130255:
		{
			return 3;
		}
		//Shield Tank
		case 135205255:
		{
			return 13;
		}		
		//Witch Tank
		case 255200255:
		{
			return 12;
		}
		//Default Tank
		case 255255255:
		{
			return 0;
		}
	}
	return -1;
}
//=============================
// COMMANDS
//=============================
stock CheatCommand(client, const String:command[], const String:arguments[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments );
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}
stock DirectorCommand(client, String:command[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s", command);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}
//=============================
// GAMEFRAME
//=============================
public OnGameFrame()
{
	if (!IsServerProcessing()) return;

	if (bSuperTanksEnabled)
	{
		iFrame++;
		if (iFrame >= 3)
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					SpeedRebuild(i);
				}
			}
			iFrame = 0;
		}
	}
}
//=============================
// TIMER 0.1
//=============================
public Action:TimerUpdate01(Handle:timer)
{
	if (!IsServerProcessing()) return Plugin_Continue;

	if (bSuperTanksEnabled && bDisplayHealthCvar)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				if (!IsFakeClient(i))
				{
					new entity = GetClientAimTarget(i, false);
					if (IsValidEntity(entity))
					{
						new String:classname[32];
						GetEdictClassname(entity, classname, sizeof(classname));
						if (StrEqual(classname, "player", false))
						{
							if (entity > 0)
							{
								if (IsTank(entity))
								{
									new health = GetClientHealth(entity);
									PrintHintText(i, "%N (%d HP)", entity, health);
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
//=============================
// TIMER 1.0
//=============================
public Action:TimerUpdate1(Handle:timer)
{
	if (!IsServerProcessing()) return Plugin_Continue;

	if (bSuperTanksEnabled)
	{
		TankController();
		SetConVarInt(FindConVar("z_max_player_zombies"), 32);
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == 2)
				{
					if (PlayerSpeed[i] > 0)
					{
						PlayerSpeed[i] -= 1;
					}
				}
				else if (GetClientTeam(i) == 3)
				{
					if (IsFakeClient(i))
					{
						new zombie = GetEntData(i, FindSendPropInfo("CTerrorPlayer", "m_zombieClass"));
						if (zombie == 8)
						{
							CreateTimer(3.0, TankLifeCheck, i, TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}