#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <dukehacks>

#define PLUGIN_VERSION "1.0.3.3"

public Plugin:myinfo = {
	name = "TF2 Classic",
	author = "CrancK",
	description = "Brings a bit of Team-Fortress into tf2",
	version = PLUGIN_VERSION,
	url = ""
};

// *************************************************
// defines
// *************************************************
// heavy sandvich healing infection
// ressuplies healing infection??
// basically... make heals only occur on 1hp/frame

#define MAX_PLAYERS 33   // maxplayers + sourceTV
#define MAX_NADES 10	//max amount of nades per person

#define SCOUT 1
#define SNIPER 2
#define SOLDIER 3
#define DEMO 4
#define MEDIC 5
#define HEAVY 6
#define PYRO 7
#define SPY 8
#define ENGIE 9
#define CLS_MAX 10

#define MIRV_PARTS 5

#define MDL_FRAG "models/weapons/nades/duke1/w_grenade_frag.mdl"
#define MDL_CONC "models/weapons/nades/duke1/w_grenade_conc.mdl"
#define MDL_NAIL "models/weapons/nades/duke1/w_grenade_nail.mdl"
#define MDL_MIRV1 "models/weapons/nades/duke1/w_grenade_mirv.mdl"
#define MDL_MIRV2 "models/weapons/nades/duke1/w_grenade_bomblet.mdl"
#define MDL_HEALTH "models/weapons/nades/duke1/w_grenade_heal.mdl"
#define MDL_NAPALM "models/weapons/nades/duke1/w_grenade_napalm.mdl"
#define MDL_HALLUC "models/weapons/nades/duke1/w_grenade_gas.mdl"
#define MDL_EMP "models/weapons/nades/duke1/w_grenade_emp.mdl"

#define MTL_NADE "materials/sprites/light_glow03.vmt"

// sounds
#define SND_THROWNADE "weapons/grenade_throw.wav"
#define SND_NADE_FRAG "weapons/explode1.wav"
#define SND_NADE_CONC "weapons/explode5.wav"
#define SND_NADE_NAIL "ambient/levels/labs/teleport_rings_loop2.wav"
#define SND_NADE_NAIL_EXPLODE "weapons/explode1.wav"
#define SND_NADE_NAIL_SHOOT1 "npc/turret_floor/shoot1.wav"
#define SND_NADE_NAIL_SHOOT2 "npc/turret_floor/shoot2.wav"
#define SND_NADE_NAIL_SHOOT3 "npc/turret_floor/shoot3.wav"
#define SND_NADE_MIRV1 "weapons/sentry_explode.wav"
#define SND_NADE_MIRV2 "weapons/explode1.wav"
#define SND_NADE_NAPALM "ambient/fire/gascan_ignite1.wav"
#define SND_NADE_HEALTH "items/suitchargeok1.wav"
#define SND_NADE_HALLUC "weapons/flame_thrower_airblast.wav"
#define SND_NADE_EMP "npc/scanner/scanner_electric2.wav"
#define SND_NADE_CONC_TIMER "weapons/det_pack_timer.wav"
#define SND_NADE_HEALTH_TIMER "hallelujah.wav"
#define SND_NADE_EMP_TIMER "weapons/boxing_gloves_crit_enabled.wav"
#define SND_NADE_HALLUC_TIMER "weapons/sentry_upgrading_steam3.wav"
#define SND_NADE_FIRE_TIMER "bush_fire.wav"
#define SND_NADE_NAIL_TIMER "camera_rewind.wav"
#define SND_INFECT "buttons/button19.wav"

/*
new String:sndThrowNade[32];
new String:sndExplodeConc[32];
new String:sndExplodeNail[32];
new String:sndExplodeMirv[32];
new String:sndExplodeMirv2[32];
new String:sndExplodeNapalm[32];
new String:sndExplodeHealth[32];
new String:sndExplodeHalluc[32];
new String:sndExplodeEmp[32];
new String:sndTimerConc[32];
new String:sndTimerHealth[32];
new String:sndTimerEmp[32];
new String:sndTimerFire[32];
new String:sndTimerNail[32];
*/


new String:sndPain[128] = "player/pain.wav";

new String:soundPainScoutSevere[6][32];
new String:soundPainScoutSharp[8][32];
new String:soundPainSniperSevere[4][32];
new String:soundPainSniperSharp[4][32];
new String:soundPainSoldierSevere[6][32];
new String:soundPainSoldierSharp[8][32];
new String:soundPainDemoSevere[4][32];
new String:soundPainDemoSharp[7][32];
new String:soundPainHeavySevere[3][32];
new String:soundPainHeavySharp[5][32];
new String:soundPainMedicSevere[4][32];
new String:soundPainMedicSharp[8][32];
new String:soundPainPyroSevere[6][32];
new String:soundPainPyroSharp[7][32];
new String:soundPainSpySevere[5][32];
new String:soundPainSpySharp[4][32];
new String:soundPainEngineerSevere[7][32];
new String:soundPainEngineerSharp[8][32];


#define STRLENGTH 128

// *************************************************
// globals 
// *************************************************

static const TFClass_MaxAmmo[TFClassType][3] =
{
  {-1, -1, -1}, {32, 36, -1},
  {25, 75, -1}, {16, 32, -1},
  {16, 24, -1}, {150, -1, -1},
  {200, 32, -1}, {200, 32, -1},
  {24, -1, -1}, {32, 200, 200}
};



// global data for current nade
new Float:gnSpeed;
new Float:gnDelay;
new String:gnModel[256];
new String:gnSkin[16];
new String:gnParticle[256];

#define OFFSIZE 4000


new bool:gCanRun = false;
new bool:gWaitOver = false;
new bool:beepOn[MAX_PLAYERS+1];
new Float:gMapStart;
new gRemaining1[MAX_PLAYERS+1];									// how many nades player has this spawn
new gRemaining2[MAX_PLAYERS+1];									// how many nades player has this spawn
new gHolding[MAX_PLAYERS+1];									// which nade is player holding
new Handle:gNadeTimer[MAX_PLAYERS+1][MAX_NADES];				// explosion timer
new Handle:gNadeTimer2[MAX_PLAYERS+1][MAX_NADES];				// sound timer
new Handle:infectionTimer[MAX_PLAYERS+1];						// infection timer
new Handle:gNailTimer[MAX_PLAYERS+1][MAX_NADES];				// nail nade timer
new Handle:gNadeTimerBeep[MAX_PLAYERS+1][MAX_NADES];			// client side beep timer
new Handle:g_DrugTimers[MAXPLAYERS+1];							// timer for drug effects
new bool:gDrugged[MAXPLAYERS+1];								// is player drugged?
new bool:gThrown[MAX_PLAYERS+1][MAX_NADES];						// was a nade thrown or held
new nailNade[MAX_PLAYERS+1];
new gNade[MAX_PLAYERS+1][MAX_NADES];							// pointer to the player's nade
new gNadeNumber[MAX_PLAYERS+1];
new gRingModel;													// model for beams
new tempNumber[MAX_PLAYERS+1][MAX_NADES];
new tempNumber2[MAX_PLAYERS+1][MAX_NADES];
new Float:gHoldingArea[3];										// point to store unused objects
new Float:PlayersInRange[MAX_PLAYERS+1];						// players are in radius ?
new gKilledBy[MAX_PLAYERS+1];									// player that killed
new String:gKillWeapon[MAX_PLAYERS+1][STRLENGTH];				// weapon that killed
new Float:gKillTime[MAX_PLAYERS+1];								// time plugin requested kill
new gNapalmSprite;												// sprite index
new gEmpSprite;													// sprite index
new bool:throwTime[MAX_PLAYERS+1];								// can player throw his next nade?
new showClientInfo[MAX_PLAYERS+1];								// client showinfo mode

new CanDJump[MAX_PLAYERS+1];									
new InTrimp[MAX_PLAYERS+1];										
new bool:InJump[MAX_PLAYERS+1];			
new bool:wallJumpReady[MAX_PLAYERS+1];
new WasInJumpLastTime[MAX_PLAYERS+1];
new WasOnGroundLastTime[MAX_PLAYERS+1];
new Float:VelLastTime[MAX_PLAYERS+1][3];
new Float:LastJumpLoc[MAX_PLAYERS+1][3];
new Float:LastHorLoc[MAX_PLAYERS+1][3];
new Float:HorMaxSpeed[MAX_PLAYERS+1];
new Float:VerMaxSpeed[MAX_PLAYERS+1];
new Float:HorDistance[MAX_PLAYERS+1];
new Float:MaxHeight[MAX_PLAYERS+1];
new offsFOV = -1;
new offsDefaultFOV = -1;
new fov[MAX_PLAYERS+1];
new tempClient = 0;
new Float:infectHits[MAX_PLAYERS+1]; 
new bool:isInfected[MAX_PLAYERS+1];
new tempInfectHP[MAX_PLAYERS+1];
new Float:speedDebuff[MAX_PLAYERS+1];
new Float:oldNormal[MAX_PLAYERS+1][3];
new Float:nextJumpTime[MAX_PLAYERS+1];
new bool:dJumpReady[MAX_PLAYERS+1];
new dispenser[MAX_PLAYERS+1];
new Float:lastJumpTime[MAX_PLAYERS+1];
//new Float:fTime;
//new Float:lastTime;
new armor[MAX_PLAYERS+1];
new bool:Piercing[MAX_PLAYERS+1];
new bool:hit[MAX_PLAYERS+1];
new hpBeforeHit[MAX_PLAYERS+1];




// UserMessageId for Fade.
new UserMsg:g_FadeUserMsgId;
new gNadesUsed[MAX_PLAYERS+1];
new Float:g_DrugAngles[20] = {
	0.0, 10.0, 20.0, 30.0, 40.0, 
	50.0, 40.0, 30.0, 20.0, 10.0, 
	0.0, -10.0, -20.0, -30.0, -40.0, 
	-50.0, -40.0, -30.0, -20.0, -10.0
	};

#define HOLD_NONE 0
#define HOLD_FRAG 1
#define HOLD_SPECIAL 2

// global "temps"
new String:tName[256];

// *************************************************
// convars
// *************************************************
new Handle:cvWaitPeriod = INVALID_HANDLE;
new Handle:cvFragNum[CLS_MAX][2];
new Handle:cvFragRadius = INVALID_HANDLE;
new Handle:cvFragDamage = INVALID_HANDLE;
new Handle:cvConcNum[2] = { INVALID_HANDLE, INVALID_HANDLE };
new Handle:cvConcDelay = INVALID_HANDLE;
new Handle:cvConcRadius = INVALID_HANDLE;
new Handle:cvConcForce = INVALID_HANDLE;
new Handle:cvConcDamage = INVALID_HANDLE;
new Handle:cvConcIgnore = INVALID_HANDLE;
new Handle:cvConcRings = INVALID_HANDLE;
new Handle:cvNailNum[2] = { INVALID_HANDLE, INVALID_HANDLE };
new Handle:cvNailRadius = INVALID_HANDLE;
new Handle:cvNailDamageNail = INVALID_HANDLE;
new Handle:cvNailDamageExplode = INVALID_HANDLE;
new Handle:cvMirvNum[4] = { INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE };
new Handle:cvMirvRadius = INVALID_HANDLE;
new Handle:cvMirvDamage1 = INVALID_HANDLE;
new Handle:cvMirvDamage2 = INVALID_HANDLE;
new Handle:cvMirvSpread = INVALID_HANDLE;
new Handle:cvHealthNum[2] = { INVALID_HANDLE, INVALID_HANDLE };
new Handle:cvHealthRadius = INVALID_HANDLE;
new Handle:cvHealthDelay = INVALID_HANDLE;
new Handle:cvHealNadeOverheal = INVALID_HANDLE;
new Handle:cvHealNadePower = INVALID_HANDLE;
new Handle:cvNapalmNum[2] = { INVALID_HANDLE, INVALID_HANDLE };
new Handle:cvNapalmRadius = INVALID_HANDLE;
new Handle:cvNapalmDamage = INVALID_HANDLE;
new Handle:cvHallucNum[2] = { INVALID_HANDLE, INVALID_HANDLE };
new Handle:cvHallucRadius = INVALID_HANDLE;
new Handle:cvHallucDelay = INVALID_HANDLE;
new Handle:cvHallucDamage = INVALID_HANDLE;
new Handle:cvEmpNum[2] = { INVALID_HANDLE, INVALID_HANDLE };
new Handle:cvEmpDelay = INVALID_HANDLE;
new Handle:cvEmpRadius = INVALID_HANDLE;
new Handle:cvEmpIgnore = INVALID_HANDLE;
new Handle:cvEmpExplosion = INVALID_HANDLE;
new Handle:cvNadesThrowSpeed = INVALID_HANDLE;
new Handle:cvRefill = INVALID_HANDLE;
new Handle:cvHHincrement = INVALID_HANDLE;
new Handle:cvShowDistance = INVALID_HANDLE;
new Handle:cvBlastDistanceMin = INVALID_HANDLE;
new Handle:cvSoundEnabled = INVALID_HANDLE;
new Handle:cvPlayerNadeBeep = INVALID_HANDLE;
new Handle:cvPickupsAllowed = INVALID_HANDLE;
new Handle:cvShowInfo = INVALID_HANDLE;
new Handle:cvStartNades = INVALID_HANDLE;
new Handle:cvPyroFly = INVALID_HANDLE;
new Handle:cvBunnyEnabled = INVALID_HANDLE;
new Handle:cvTrimpEnabled = INVALID_HANDLE;
new Handle:cvSandManDJump = INVALID_HANDLE;
new Handle:cvNadeHHMin = INVALID_HANDLE;
new Handle:cvNadeTrail = INVALID_HANDLE;

new Handle:Speedo = INVALID_HANDLE;
new Handle:SpeedoOff = INVALID_HANDLE;
new Handle:BunnyMode = INVALID_HANDLE;
new Handle:BunnyIncrement = INVALID_HANDLE;
new Handle:BunnyCap = INVALID_HANDLE;
new Handle:SelfBoostX = INVALID_HANDLE;
new Handle:SelfBoostY = INVALID_HANDLE;
new Handle:g_fovEnabled = INVALID_HANDLE;
new Handle:cvFovMax = INVALID_HANDLE;
new Handle:g_scale = INVALID_HANDLE;
new Handle:BunnySlowDown = INVALID_HANDLE;
new Handle:cvExplosionPower = INVALID_HANDLE;
new Handle:cvExplosionRadius = INVALID_HANDLE;
new Handle:cvQuadThreshold = INVALID_HANDLE;
new Handle:accel = INVALID_HANDLE;
new Handle:cvAirAccel = INVALID_HANDLE;
new Handle:cvInfectHits = INVALID_HANDLE;
new Handle:cvInfectEnabled = INVALID_HANDLE;
new Handle:cvInfectBaseDamage = INVALID_HANDLE;
new Handle:cvInfectDis[2] = { INVALID_HANDLE, INVALID_HANDLE };
new Handle:cvSniperShot = INVALID_HANDLE;
new Handle:cvSniperShotDelay = INVALID_HANDLE;
new Handle:cvSniperShotAmount = INVALID_HANDLE;
new Handle:cvDoors = INVALID_HANDLE;
new Handle:cvForcedShowInfo = INVALID_HANDLE;
new Handle:cvShowJumpInfo = INVALID_HANDLE;
new Handle:cvWallJump = INVALID_HANDLE;
new Handle:cvWallJumpPower = INVALID_HANDLE;
new Handle:cvWallJumpDelay = INVALID_HANDLE;
new Handle:cvWallJumpDelay2 = INVALID_HANDLE;
new Handle:cvWallJumpDistance = INVALID_HANDLE;
new Handle:cvWallJumpMinSpeed = INVALID_HANDLE;
new Handle:cvDJumpDelay = INVALID_HANDLE;
new Handle:cvDJumpDelay2 = INVALID_HANDLE;
new Handle:cvDJumpMax = INVALID_HANDLE;
new Handle:cvDJumpTBoost = INVALID_HANDLE;
new Handle:cvSpeedCheck = INVALID_HANDLE;
//new Handle:cvStrafeAmount = INVALID_HANDLE;
new Handle:cvNadesThrowPhysics = INVALID_HANDLE;
new Handle:cvArmor = INVALID_HANDLE;
new Handle:cvArmorAmounts[3][2] = { { INVALID_HANDLE, INVALID_HANDLE }, { INVALID_HANDLE, INVALID_HANDLE }, { INVALID_HANDLE, INVALID_HANDLE } };
new Handle:cvStartArmor = INVALID_HANDLE;
new Handle:cvQuickSwitch = INVALID_HANDLE;
new Handle:cvFDMulti = INVALID_HANDLE;

//new Handle:cvTest = INVALID_HANDLE;
new Handle:g_hInterval;
new Handle:g_hTimer;
new Handle:HudMessage;
new Handle:HudStatus;
new Handle:HudArmor;


native TF2_IgnitePlayer(client, attacker);

// *************************************************
// main plugin
// *************************************************

public OnPluginStart() 
{
	// events
	HookEvent("player_spawn",PlayerSpawn);
	HookEvent("player_death",PlayerDeath, EventHookMode_Pre);
	HookEvent("player_changeclass", ChangeClass);
	HookEvent("player_shoot", PlayerShoot);
	HookEvent("teamplay_round_start", MainEvents);
	HookEvent("teamplay_round_active", MainEvents);
	HookEvent("teamplay_restart_round", MainEvents);
	HookEvent("teamplay_round_stalemate", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", RoundEnd, EventHookMode_PostNoCopy);
	
	
	// convars
	cvWaitPeriod = CreateConVar("tf2c_nades_waitperiod", "1", "server waits for players on map start (1=true 0=false)(RECOMMENDED!)", FCVAR_PLUGIN);
	cvEmpRadius = CreateConVar("tf2c_nades_emp_radius", "256.0", "radius for emp nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvEmpDelay = CreateConVar("tf2c_nades_emp_delay", "3.0", "delay in seconds before nade explodes", FCVAR_PLUGIN, true, 1.0, true, 10.0);
	cvEmpNum[1] = CreateConVar("tf2c_nades_emp_max", "4", "max number of emp nades", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvEmpNum[0] = CreateConVar("tf2c_nades_emp_min", "2", "number of emp nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvEmpIgnore = CreateConVar("tf2c_nades_emp_ignorewalls", "1", "enables the blast to go through walls", FCVAR_PLUGIN);
	cvEmpExplosion = CreateConVar("tf2c_nades_emp_explosion", "1", "adds an explosion particle effect to indicate ammo blowing up", FCVAR_PLUGIN);
	cvHallucDamage = CreateConVar("tf2c_halluc_damage", "5", "damage done by hallucination nade", FCVAR_PLUGIN);
	cvHallucDelay = CreateConVar("tf2c_nades_hallucination_time", "10.0", "delay in seconds that effects last", FCVAR_PLUGIN, true, 1.0, true, 10.0);	
	cvHallucRadius = CreateConVar("tf2c_nades_hallucination_radius", "256.0", "radius for hallincation nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvHallucNum[1] = CreateConVar("tf2c_nades_hallucination_max", "4", "max number of hallucination nades", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvHallucNum[0] = CreateConVar("tf2c_nades_hallucination_min", "2", "number of hallucination nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvNapalmDamage = CreateConVar("tf2c_nades_napalm_damage", "25", "initial damage for napalm nade", FCVAR_PLUGIN, true, 1.0, true, 500.0);
	cvNapalmRadius = CreateConVar("tf2c_nades_napalm_radius", "320.0", "radius for napalm nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvNapalmNum[1] = CreateConVar("tf2c_nades_napalm_max", "3", "max number of napalm nades", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvNapalmNum[0] = CreateConVar("tf2c_nades_napalm_min", "2", "number of napalm nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvHealthDelay = CreateConVar("tf2c_nades_health_delay", "3.0", "delay in seconds before nade explodes", FCVAR_PLUGIN, true, 1.0, true, 10.0);
	cvHealthRadius = CreateConVar("tf2c_nades_health_radius", "384.0", "radius for health nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvHealthNum[1] = CreateConVar("tf2c_nades_health_max", "1", "max number of health nades", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvHealthNum[0] = CreateConVar("tf2c_nades_health_min", "1", "number of health nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvHealNadePower = CreateConVar("tf2c_nades_health_power", "1000", "amount of total hp the heal nade can heal",FCVAR_PLUGIN);
	cvHealNadeOverheal = CreateConVar("tf2c_nades_health_overheal", "1", "enables the healnade to overheal", FCVAR_PLUGIN);
	cvMirvSpread = CreateConVar("tf2c_nades_mirv_spread", "384.0", "spread of secondary explosives (max speed)", FCVAR_PLUGIN, true, 1.0, true, 2048.0);	
	cvMirvDamage2 = CreateConVar("tf2c_nades_mirv_damage2", "60.0", "damage done by secondary explosion of mirv nade", FCVAR_PLUGIN, true, 1.0, true, 500.0);	
	cvMirvDamage1 = CreateConVar("tf2c_nades_mirv_damage1", "60.0", "damage done by main explosion of mirv nade", FCVAR_PLUGIN, true, 1.0, true, 500.0);
	cvMirvRadius = CreateConVar("tf2c_nades_mirv_radius", "128.0", "radius for demo's nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvMirvNum[2] = CreateConVar("tf2c_nades_mirv_heavy_min", "1", "number of mirv nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvMirvNum[3] = CreateConVar("tf2c_nades_mirv_heavy_max", "2", "max number of mirv nades given to Heavy", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvMirvNum[0] = CreateConVar("tf2c_nades_mirv_demo_min", "2", "number of mirv nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvMirvNum[1] = CreateConVar("tf2c_nades_mirv_demo_max", "3", "max number of mirv nades given to Demo", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvNailDamageExplode = CreateConVar("tf2c_nades_nail_explodedamage", "80.0", "damage done by final explosion", FCVAR_PLUGIN, true, 1.0, true,1000.0);
	cvNailDamageNail = CreateConVar("tf2c_nades_nail_naildamage", "8.0", "damage done by nail projectile", FCVAR_PLUGIN, true, 1.0, true, 500.0);
	cvNailRadius = CreateConVar("tf2c_nades_nail_radius", "256.0", "radius for nail nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvNailNum[1] = CreateConVar("tf2c_nades_nail_max", "2", "max number of nail nades", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvNailNum[0] = CreateConVar("tf2c_nades_nail_min", "1", "number of nail nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvConcDamage = CreateConVar("tf2c_nades_conc_damage", "10", "damage done by concussion nade", FCVAR_PLUGIN);
	cvConcForce = CreateConVar("tf2c_nades_conc_force", "3.0", "force applied by concussion nade", FCVAR_PLUGIN);
	cvConcDelay = CreateConVar("tf2c_nades_conc_delay", "3.0", "delay in seconds before nade explodes", FCVAR_PLUGIN, true, 1.0, true, 10.0);
	cvConcRadius = CreateConVar("tf2c_nades_conc_radius", "256.0", "radius for concussion nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvConcNum[1] = CreateConVar("tf2c_nades_conc_max", "4", "max number of conc nades", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvConcNum[0] = CreateConVar("tf2c_nades_conc_min", "2", "number of conc nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvConcIgnore = CreateConVar("tf2c_nades_conc_ignorewalls", "1", "enables the blast to go through walls", FCVAR_PLUGIN);
	cvConcRings = CreateConVar("tf2c_nades_conc_rings", "10.0", "amount of rings for conc blast effect", FCVAR_PLUGIN, true, 0.0, true, 50.0);
	cvFragDamage = CreateConVar("tf2c_nades_frag_damage", "100", "damage done by concussion nade", FCVAR_PLUGIN);
	cvFragRadius = CreateConVar("tf2c_nades_frag_radius", "320.0", "radius for concussion nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvFragNum[ENGIE][1] = CreateConVar("tf2c_nades_frag_engineer_max", "2", "max number of frag nades", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[ENGIE][0] = CreateConVar("tf2c_nades_frag_engineer_min", "1", "number of frag nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[SPY][1] = CreateConVar("tf2c_nades_frag_spy_max", "2", "number of frag nades given", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[SPY][0] = CreateConVar("tf2c_nades_frag_spy_min", "1", "number of frag nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[PYRO][1] = CreateConVar("tf2c_nades_frag_pyro_max", "3", "number of frag nades given", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[PYRO][0] = CreateConVar("tf2c_nades_frag_pyro_min", "2", "number of frag nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[HEAVY][1] = CreateConVar("tf2c_nades_frag_heavy_max", "4", "number of frag nades given", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[HEAVY][0] = CreateConVar("tf2c_nades_frag_heavy_min", "2", "number of frag nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[MEDIC][1] = CreateConVar("tf2c_nades_frag_medic_max", "2", "number of frag nades given", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[MEDIC][0] = CreateConVar("tf2c_nades_frag_medic_min", "1", "number of frag nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[DEMO][1] = CreateConVar("tf2c_nades_frag_demo_max", "3", "number of frag nades given", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[DEMO][0] = CreateConVar("tf2c_nades_frag_demo_min", "2", "number of frag nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[SOLDIER][1] = CreateConVar("tf2c_nades_frag_soldier_max", "4", "number of frag nades given", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[SOLDIER][0] = CreateConVar("tf2c_nades_frag_soldier_min", "2", "number of frag nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[SNIPER][1] = CreateConVar("tf2c_nades_frag_sniper_max", "3", "number of frag nades given", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[SNIPER][0] = CreateConVar("tf2c_nades_frag_sniper_min", "2", "number of frag nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[SCOUT][1] = CreateConVar("tf2c_nades_frag_scout_max", "2", "number of frag nades given", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragNum[SCOUT][0] = CreateConVar("tf2c_nades_frag_scout_min", "1", "number of frag nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	
	cvNadeTrail = CreateConVar("tf2c_nades_showtrail", "1", "enables a trail behind nades", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvNadesThrowSpeed = CreateConVar("tf2c_nades_throwspeed", "950.0", "this + the playerspeed = speed at which the nade is thrown", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvShowDistance = CreateConVar("tf2c_nades_showdistance", "0", "shows distance to conc relative to radius, 1=radius", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvBlastDistanceMin = CreateConVar("tf2c_nades_blastdistancemin", "0.75", "minimum blast radius", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvHHincrement = CreateConVar("tf2c_nades_hhincrement", "2.95", "speed gain from HH", FCVAR_PLUGIN|FCVAR_NOTIFY , true, 1.0, true, 5.0);
	cvSoundEnabled = CreateConVar("tf2c_nades_soundEnabled", "1.0", "nade sounds enabled on 1", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvPickupsAllowed = CreateConVar("tf2c_pickupsAllowed", "1.0", "health & nade pickups", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvPlayerNadeBeep = CreateConVar("tf2c_nades_selfbeep", "1.0", "enables self-beep", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvShowInfo = CreateConVar("tf2c_nades_showinfo", "1", "enables health/nades display for clients", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvRefill = CreateConVar("tf2c_jump_refill", "0", "Allow refill for on jump maps", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvStartNades = CreateConVar("tf2c_startnades", "0", "Enables/disables nades on spawn, 1=min amounts, 2=max amounts", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvAirAccel = CreateConVar("tf2c_aa", "20", "airacceleration",FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvPyroFly = CreateConVar("tf2c_pyrofly_enabled", "1", "enables pyro's to fly", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvBunnyEnabled = CreateConVar("tf2c_bhop_enabled", "1", "enables bunnyhopping/trimping/pyrofly & bhopdoublejump", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvTrimpEnabled = CreateConVar("tf2c_bhop_trimp_enabled", "1", "enables trimping", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvSandManDJump = CreateConVar("tf2c_sandmandjump_enabled", "0", "on 1, enables sandman scouts, to do a bodged up doublejump", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvWallJump = CreateConVar("tf2c_walljump_enabled", "0", "enables the spy to wall-jump", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvWallJumpPower = CreateConVar("tf2c_walljump_power", "266.66", "power of the spy-walljump", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvWallJumpDelay = CreateConVar("tf2c_walljump_delay_g2w", "0.25", "delay in seconds before being able to walljump again from ground", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvWallJumpDelay2 = CreateConVar("tf2c_walljump_delay_w2w", "0.75", "delay in seconds before being able to walljump again from walls", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvWallJumpDistance = CreateConVar("tf2c_walljump_distance", "40.0", "distance to wall", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvWallJumpMinSpeed = CreateConVar("tf2c_walljump_minspeed", "133.33", "minimum total speed required to walljump", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvNadeHHMin = CreateConVar("tf2c_nades_hh_min", "1.5", "minimum boost increment from handhelding a nade",  FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvDJumpDelay = CreateConVar("tf2c_djump_delay_min", "0.15", "q3 style doublejump, min delay, before djump can be used, if 0.0 then doublejump is off", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 0.25);
	cvDJumpDelay2 = CreateConVar("tf2c_djump_delay_max", "0.55", "q3 style doublejump, max delay, until djump can be used", FCVAR_PLUGIN, true, 0.1, true, 0.65);
	cvDJumpMax = CreateConVar("tf2c_djump_max", "800.0", "q3 style doublejump, limit to height boost", FCVAR_PLUGIN);
	cvDJumpTBoost = CreateConVar("tf2c_djump_time_boost", "1.15", "depending on how quickly the doublejump is performed, more boost is gained, 1.15 = 100% if tf2c_djump_delay_min = 0.15", FCVAR_PLUGIN);
	cvSpeedCheck = CreateConVar("tf2c_speed_check", "0", "makes sure you don't slow down from bunnyhopping", FCVAR_PLUGIN);
	//cvStrafeAmount = CreateConVar("tf2c_strafe_amount", "1.0", "amount of q3 airacceleration", FCVAR_PLUGIN);
	cvNadesThrowPhysics = CreateConVar("tf2c_nades_throwphysics", "1", "enables clientspeed being added to nade throwspeed", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	Speedo = CreateConVar("tf2c_speedometer", "0", "ALWAYS show speedometer for all clients", FCVAR_PLUGIN);
	SpeedoOff = CreateConVar("tf2c_speedometer_off", "0", "Never show speedometer for all clients", FCVAR_PLUGIN);
	BunnyMode = CreateConVar("tf2c_bhop_Mode", "3", "Changes how bunnyhopping increases speed, 0 for normal, 1 for only turning speed, 2 for set speed 3 for set everything", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 6.0);
	BunnyIncrement = CreateConVar("tf2c_bhop_Increment", "1.01", "Changes bunnyhop speedincrease if bhopMode is set to 2", FCVAR_PLUGIN|FCVAR_NOTIFY , true, 1.0, true, 2.0);
	BunnyCap = CreateConVar("tf2c_bhop_Cap", "1.8", "Changes the bunnyhop speed cap if bhopMode is set to 2", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 5.0);
	BunnySlowDown = CreateConVar("tf2c_bhop_Slowdown", "0.10", "in bhopmode 3, if above the bhopcap, slow down rate", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.000, true, 1.000);
	SelfBoostX = CreateConVar("tf2c_selfdamageBoostX", "1.0", "Changes the selfhurting increment (horizontal)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 5.0);
	SelfBoostY = CreateConVar("tf2c_selfdamageBoostY", "1.0", "Changes the selfhurting increment (vertical)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 5.0);
	g_fovEnabled = CreateConVar("tf2c_fovEnabled", "1.0", "allows changing of fov", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvFovMax = CreateConVar("tf2c_fovmax", "160", "set's the max limit for the fov command", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_scale = CreateConVar("tf2c_rspeed", "1.05", "Rocket speed mult", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvExplosionPower = CreateConVar("tf2c_power", "4.0", "explosionpower default = 4.0 or 0.0, quadjump = 16.0 or 12.0", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvExplosionRadius = CreateConVar("tf2c_quadradius", "128.0", "radius of rocket explosion", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvQuadThreshold = CreateConVar("tf2c_quadthreshold", "64.0", "perfect point for max boost, in distance from middle of explosion", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvInfectEnabled = CreateConVar("tf2c_infect_enabled", "1.0", "enables infection", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvInfectHits = CreateConVar("tf2c_infect_hits", "5.0", "amount of hits needed to infect players", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvInfectBaseDamage = CreateConVar("tf2c_infect_basedamage", "2.0", "base amount of damage from infection", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvInfectDis[0] = CreateConVar("tf2c_infect_mindistance", "128.0", "upto this range, infection is 100% effective", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvInfectDis[1] = CreateConVar("tf2c_infect_maxdistance", "640.0", "max range of infection, any further and the needle wont infect", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvForcedShowInfo = CreateConVar("tf2c_forced_showinfo", "0", "makes all clients have this mode of showinfo displayed", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvSniperShot = CreateConVar("tf2c_snipershot_enabled", "0", "makes snipers shots slow people down (only works with bunnymode 3)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvSniperShotDelay = CreateConVar("tf2c_snipershot_delay", "5.0", "time in seconds for which the debuff lasts", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvSniperShotAmount = CreateConVar("tf2c_snipershot_debuffamount", "0.1", "amount of slowdown per shot, if you change this, mapchange is recommended", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvDoors = CreateConVar("tf2c_quickdoors_enabled", "1", "enables/disables doors to be opened instantly, needs mapchange", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvShowJumpInfo = CreateConVar("tf2c_jump_showinfo", "0", "shows info about jumps, 1 for speed, 2 for distance, 3 for both, 4 for detailed", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvArmor = CreateConVar("tf2c_armor_enabled", "1", "enables armor", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvArmorAmounts[0][0] = CreateConVar("tf2c_armor_light_fraction", "0.4", "amount of damage reduction from light armor", FCVAR_PLUGIN);
	cvArmorAmounts[1][0] = CreateConVar("tf2c_armor_medium_fraction", "0.5", "amount of damage reduction from medium armor", FCVAR_PLUGIN);
	cvArmorAmounts[2][0] = CreateConVar("tf2c_armor_heavy_fraction", "0.6", "amount of damage reduction from heavy armor", FCVAR_PLUGIN);
	cvArmorAmounts[0][1] = CreateConVar("tf2c_armor_light_max", "100", "max amount for light armor", FCVAR_PLUGIN);
	cvArmorAmounts[1][1] = CreateConVar("tf2c_armor_medium_max", "150", "max amount for medium armor", FCVAR_PLUGIN);
	cvArmorAmounts[2][1] = CreateConVar("tf2c_armor_heavy_max", "200", "max amount for heavy armor", FCVAR_PLUGIN);
	cvStartArmor = CreateConVar("tf2c_armor_startamount", "2", "if armor is enabled, 0 = 0 start armor, 1 = 1/4 start armor, 2 = 1/2 start armor, 3 = full start armor", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvQuickSwitch = CreateConVar("tf2c_quickswitch_enabled", "0", "enables quickswitch", FCVAR_PLUGIN);
	cvFDMulti = CreateConVar("tf2c_falldamage_multiplier", "0.6", "reduces/increases falldamage, 0.0 = no change", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	CreateConVar("tf2classic_version", PLUGIN_VERSION, "TF2Classic Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hInterval = CreateConVar("tf2c_hphud_interval", "5", "How often health timer is updated (in tenths of a second).");
	HookConVarChange(g_hInterval, ConVarChange_Interval);
	HookConVarChange(cvAirAccel, Cvar_AirAccel);
	HudMessage = CreateHudSynchronizer();
	HudStatus = CreateHudSynchronizer();
	HudArmor = CreateHudSynchronizer();
	
	
	// commands
	RegConsoleCmd("+nade1", Command_Nade1);
	RegConsoleCmd("-nade1", Command_UnNade1);
	RegConsoleCmd("+nade2", Command_Nade2);
	RegConsoleCmd("-nade2", Command_UnNade2);
	//RegConsoleCmd("+special", Command_Special);
	//RegConsoleCmd("-special", Command_unSpecial);
	RegConsoleCmd("tf2c_selfbeep", Command_SelfBeep);
	RegConsoleCmd("tf2c_showinfo", Command_ShowInfo);
	//RegConsoleCmd("throwammo", Command_ThrowAmmo);
	
	RegConsoleCmd("say", Command_Say);
	accel = FindConVar("sv_airaccelerate");
	
	
	RegConsoleCmd("tf2c_nades_refill", Command_RefillNades , "Refill nades");
	RegConsoleCmd("tf2c_fov", Command_fov, "Set your FOV.");
	offsFOV = FindSendPropOffs("CBasePlayer", "m_iFOV");
	offsDefaultFOV = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
	
	painSoundSetup();

	// misc setup
	g_FadeUserMsgId = GetUserMessageId("Fade");
	gHoldingArea[0]=-100000.0; gHoldingArea[1]=-100000.0; gHoldingArea[2]=-100000.0;
	new i;
	new j;
	for(i=0;i<MAX_PLAYERS+1;i++)
	{
		nailNade[i] = 0;
		infectHits[i] = 0.0;
		isInfected[i] = false;
		tempInfectHP[i] = 0;
		throwTime[i] = false;
		infectionTimer[i] = INVALID_HANDLE;
		speedDebuff[i] = 1.0;
		HorDistance[i] = 0.0;
		wallJumpReady[i] = true;
		nextJumpTime[i] = -1000.0;
		lastJumpTime[i] = -1000.0;
		dJumpReady[i] = false;
		dispenser[i] = 0;
		armor[i] = 0;
		Piercing[i] = false;
		hit[i] = false;
		for(j=0;j<MAX_NADES;j++)
		{
			gThrown[i][j] = false;
		}
	}
	
	
	// hooks
	HookEntityOutput("prop_dynamic", "OnAnimationBegun", EntityOutput_OnAnimationBegun);
	HookEntityOutput("item_ammopack_full", "OnPlayerTouch", EntityOutput_OnPlayerTouch);
	HookEntityOutput("item_ammopack_medium", "OnPlayerTouch", EntityOutput_OnPlayerTouch);
	HookEntityOutput("item_ammopack_small", "OnPlayerTouch", EntityOutput_OnPlayerTouch);
	
	// self-damage boost
	HookEvent("player_hurt", EventPlayerHurt);
	if(GetConVarInt(cvArmor)==1)
	{
		dhAddClientHook(CHK_TakeDamage, TakeDamageHook);
	}
}

public OnClientPutInServer(client) 
{
	fov[client] = GetEntData(client, offsFOV, 4);
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn",PlayerSpawn);
	UnhookEvent("player_death",PlayerDeath);
}

public OnMapStart()
{

	// initialize model for nades (until class is chosen)
	gnSpeed = 100.0;
	gnDelay = 2.0;
	
	// precache models
	gRingModel = PrecacheModel("sprites/laser.vmt", true);
	gNapalmSprite = PrecacheModel("sprites/floorfire4_.vmt", true);
	gEmpSprite = PrecacheModel("sprites/laser.vmt", true);
	
	
	// precache sounds
	PrecacheSound(SND_THROWNADE, true);
	PrecacheSound(SND_NADE_FRAG, true);
	PrecacheSound(SND_NADE_CONC, true);
	PrecacheSound(SND_NADE_NAIL, true);
	PrecacheSound(SND_NADE_NAIL_EXPLODE, true);
	PrecacheSound(SND_NADE_NAIL_SHOOT1, true);
	PrecacheSound(SND_NADE_NAIL_SHOOT2, true);
	PrecacheSound(SND_NADE_NAIL_SHOOT3, true);
	PrecacheSound(SND_NADE_MIRV1, true);
	PrecacheSound(SND_NADE_MIRV2, true);
	PrecacheSound(SND_NADE_HEALTH, true);
	PrecacheSound(SND_NADE_NAPALM, true);
	PrecacheSound(SND_NADE_HALLUC, true);
	PrecacheSound(SND_NADE_EMP, true);
	PrecacheSound(sndPain, true);
	PrecacheSound(SND_NADE_CONC_TIMER, true);
	PrecacheSound(SND_NADE_EMP_TIMER, true);
	PrecacheSound(SND_NADE_HALLUC_TIMER, true);
	PrecacheSound(SND_NADE_FIRE_TIMER, true);
	PrecacheSound(SND_NADE_NAIL_TIMER, true);
	PrecacheSound(SND_INFECT, true);
	PrecachePainSounds();
	PrecacheNadeModels();
	g_hTimer = CreateTimer(GetConVarInt(g_hInterval) * 0.1, Timer_ShowInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	// reset status
	gCanRun = false;
	gWaitOver = false;
	gMapStart = GetGameTime();
	for(new i=0;i<MAX_PLAYERS+1;i++)
	{
		lastJumpTime[i] = -1000.0;
	}
	MainEvents(INVALID_HANDLE, "map_start", true);
}

public OnConfigsExecuted()
{
	TagsCheck("TF2Classic");
	SetConVarInt(accel, GetConVarInt(cvAirAccel), true);
}

public OnClientPostAdminCheck(client)
{
	
	// kill hooks
	gKilledBy[client]=0;
	gKillTime[client] = 0.0;
	gKillWeapon[client][0]='\0';
	gNadesUsed[client] = 0;
}

public OnClientDisconnect(client) 
{
	if(infectionTimer[client] != INVALID_HANDLE)
	{ KillTimer(infectionTimer[client]); infectionTimer[client] = INVALID_HANDLE; }
	beepOn[client] = false;
	infectHits[client] = 0.0;
	isInfected[client] = false;
	for(new i=0;i<10;i++)
	{
		if(gNadeTimerBeep[client][i] != INVALID_HANDLE)
		{ KillTimer(gNadeTimerBeep[client][i]); gNadeTimerBeep[client][i] = INVALID_HANDLE; }
		if(gNadeTimer2[client][i] != INVALID_HANDLE)
		{ KillTimer(gNadeTimer2[client][i]); gNadeTimer2[client][i] = INVALID_HANDLE; }
	}
	gRemaining1[client] = 0;
	gRemaining2[client] = 0;
	showClientInfo[client] = 0;
	lastJumpTime[client] = -1000.0;
}

public Action:MainEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvWaitPeriod)==1)
	{
		if (StrEqual(name,"teamplay_restart_round", false))
		{
			gCanRun = true;
			gWaitOver = true;
		}
	}
	else
	{
		if (!StrEqual(name, "map_start"))
		{
			gCanRun = true;
			gWaitOver = true;
		}
	}
	
	if (gWaitOver)
	{
		if (StrEqual(name, "teamplay_round_start"))
		{
			gCanRun = false;
			serverMessage();
			if(GetConVarInt(cvDoors)==1)
			{ setDoorSpeed(); }
		}
		else if (StrEqual(name, "teamplay_round_active"))
		{
			gCanRun = true;
		}
	}
	
	
	// reset players
	new i;
	for (i=1;i<=MAX_PLAYERS;i++)
	{
		new j;
		for(j=0;j<MAX_NADES;j++)
		{
			// nades
			gNade[i][j]=0;
			gNadeTimerBeep[i][j]=INVALID_HANDLE;
			tempNumber[i][j]=0;
		}
		// kill hooks
		speedDebuff[i] = 1.0;
		infectHits[i]= 0.0;
		isInfected[i] = false;
		gKilledBy[i]=0;
		gKillTime[i] = 0.0;
		gKillWeapon[i][0]='\0';
		lastJumpTime[i] = -1000.0;
		if(infectionTimer[i] != INVALID_HANDLE)
		{ KillTimer(infectionTimer[i]); infectionTimer[i] = INVALID_HANDLE; SetEntityRenderColor(i, 255, 255, 255, 255);}
	}
	new k;
	for(k=1;k<=MaxClients;k++)
	{
		if(IsValidEntity(k) && i != 34)
		{
			if(IsClientAuthorized(k) && IsClientConnected(k))
			{
				if(IsPlayerAlive(k) && !IsFakeClient(k) && !IsClientObserver(k))
				{
					new class = int:TF2_GetPlayerClass(i);
					if(GetConVarInt(cvStartNades)==1)
					{
						gRemaining1[k] = GetConVarInt(cvFragNum[class][0]);
						gRemaining2[k] = GetNumNades(class, 0);
					}
					else if(GetConVarInt(cvStartNades)==2)
					{
						gRemaining1[k] = GetConVarInt(cvFragNum[class][1]);
						gRemaining2[k] = GetNumNades(class, 1);
					}
					else
					{
						gRemaining1[k] = 0;
						gRemaining2[k] = 0;
					}
					SetEntityRenderColor(k, 255, 255, 255, 255);
				}
			}
		}
	}
	
	
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	gCanRun = false;
	new i;
	new j;
	for(i=0;i<MAX_PLAYERS+1;i++)
	{
		for(j=0;j<MAX_NADES;j++)
		{
			if(gNadeTimer2[i][j] != INVALID_HANDLE)
			{ KillTimer(gNadeTimer2[i][j]); gNadeTimer2[i][j] = INVALID_HANDLE; }
		}
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	new class = int:TF2_GetPlayerClass(client);
	gHolding[client]=HOLD_NONE;
	
	if (!gCanRun)
	{
		if (GetGameTime() > (gMapStart + 60.0))
		{
			gCanRun = true;
		}
		else
		{
			return Plugin_Continue;
		}
	}
	
	// client info
	new String:clientname[32];
	Format(clientname, sizeof(clientname), "tf2player%d", client);
	DispatchKeyValue(client, "targetname", clientname);
	
	SetupNade(class, GetClientTeam(client), 1);
	
	if(GetConVarInt(cvStartNades)==1)
	{
		gRemaining1[client] = GetConVarInt(cvFragNum[class][0]);
		gRemaining2[client] = GetNumNades(class, 0);
	}
	else if(GetConVarInt(cvStartNades)==2)
	{
		gRemaining1[client] = GetConVarInt(cvFragNum[class][1]);
		gRemaining2[client] = GetNumNades(class, 1);
	}
	else
	{
		gRemaining1[client] = 0;
		gRemaining2[client] = 0;
	}

	armor[client] = GetArmorAmounts(class, GetConVarInt(cvStartArmor));
	new ents = GetMaxEntities();
	new String:edictname[128];
	for (new i=GetMaxClients()+1; i<ents; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, edictname, 128);
			if(StrEqual(edictname, "prop_physics") || StrEqual(edictname, "prop_dynamic_override"))
			{
				if (GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity")==client)
				{
					new String:modelname[128];
					GetEntPropString(i, Prop_Data, "m_ModelName", modelname, 128);
					if (!StrEqual(modelname, "models/flag/briefcase.mdl"))
					{
						RemoveEdict(i);
					}
				}
			}
		}
	}
	if(IsValidEntity(client))
	{ 
		if(IsClientAuthorized(client) && IsClientConnected(client))
		{
			if(IsPlayerAlive(client) && !IsFakeClient(client) && !IsClientObserver(client))
			{
				SetEntityRenderColor(client, 255, 255, 255, 255); 
			}
		}
	}
	for(new i=0;i<MAX_NADES;i++)
	{
		if(gNadeTimer2[client][i] != INVALID_HANDLE)
		{
			KillTimer(gNadeTimer2[client][i]); gNadeTimer[client][i] = INVALID_HANDLE;
		}
	}
	return Plugin_Continue;
}

public EntityOutput_OnPlayerTouch(const String:output[], caller, activator, Float:delay)
{
	if(GetConVarInt(cvPickupsAllowed) == 1){
		if(IsValidEntity(caller))
		{	
			
			new String:modelname[128];
			GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(modelname, "models/items/ammopack_large.mdl"))
			{
				new Float:pos[3];
				GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
				FindPlayersInRange(pos, 96.0, 0, caller, false, caller);
				new j;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						GiveNadesorHealth(j, 0, 2);
					}
				}
			}
			else if(StrEqual(modelname, "models/items/ammopack_medium.mdl"))
			{
				new Float:pos[3];
				GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
				FindPlayersInRange(pos, 96.0, 0, caller, false, caller);
				new j;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						GiveNadesorHealth(j, 0, 1);
					}
				}
			}
			else if(StrEqual(modelname, "models/items/ammopack_small.mdl"))
			{
				new Float:pos[3];
				GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
				FindPlayersInRange(pos, 96.0, 0, caller, false, caller);
				new j;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						GiveNadesorHealth(j, 0, 0);
					}
				}
			}
		}
	}
}

public EntityOutput_OnAnimationBegun(const String:output[], caller, activator, Float:delay)
{
	if (IsValidEntity(caller))
	{
		new String:modelname[128];
		GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, "models/props_gameplay/resupply_locker.mdl"))
		{
			new Float:pos[3];
			GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
			FindPlayersInRange(pos, 128.0, 0, caller, false, caller);
			new j;
			new maxplayers = GetMaxClients();
			for (j=1;j<=maxplayers;j++)
			{
				if(PlayersInRange[j]>0.0)
				{
					GiveNadesorHealth(j, 0 , 3);
				}
			}
		}
	}
}

public Action:ScaleSpeed(Handle:timer, any:ent) 
{
    if(IsValidEntity(ent)) 
	{
		decl Float:velocity[3];
		decl Float:ang[3];
		GetEntPropVector(ent, Prop_Data, "m_vecVelocity", velocity);
		GetVectorAngles(velocity, ang);
		ScaleVector(velocity, GetConVarFloat(g_scale));
		new Float:speed = GetVectorLength(velocity);
		ang[0] *= -1.0;
		ang[0] = DegToRad(ang[0]);
		ang[1] = DegToRad(ang[1]);
		velocity[0] = speed*Cosine(ang[0])*Cosine(ang[1]);
		velocity[1] = speed*Cosine(ang[0])*Sine(ang[1]);
		velocity[2] = speed*Sine(ang[0]);
		TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, velocity);
    }
}  

public Action:PlayerShoot(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvArmor)==1)
	{
		PrintToServer("Player shot and armor is on");
		new client;
		client = GetClientOfUserId(GetEventInt(event, "userid"));
		new String:weaponName[32]; GetClientWeapon(client, weaponName, 31);
		if(StrEqual(weaponName, "n_wrench"))
		{
			new Handle:tr, Float:angEye[3], Float:orig[3];
			GetClientEyeAngles(client, angEye);
			GetClientAbsOrigin(client, orig);
			tr = TR_TraceRayFilterEx(orig, angEye, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
			if(TR_DidHit(tr))
			{
				new Float:pos[3], Float:dis;
				TR_GetEndPosition(pos, tr);
				dis = GetVectorDistance(orig, pos);
				if(dis <= 64.0)
				{
					new ent;
					ent = TR_GetEntityIndex(tr);
					if(ent<=GetMaxClients() && ent != 0 && ent != -1)
					{
						
						new metalvalue;
						//m_Offset=FindSendPropOffs("CTFPlayer","m_iAmmo"); 
						metalvalue=GetMetalAmount(client);
						new class = int:TF2_GetPlayerClass(ent);
						if(metalvalue-25>0)
						{
							if(armor[ent]+25<GetArmorAmounts(class, 3))
							{
								SetMetalAmount(client, metalvalue-25);
								armor[ent] += 25;
							}
							else
							{
								metalvalue -= (GetArmorAmounts(class, 3) - armor[ent]);
								SetMetalAmount(client, metalvalue);
								armor[ent] = GetArmorAmounts(class, 3);
							}
						}
						else if(metalvalue>0)
						{
							if(armor[ent]+metalvalue<GetArmorAmounts(class, 3))
							{
								SetMetalAmount(client, 0);
								armor[ent] += metalvalue;
							}
							else
							{
								metalvalue -= (GetArmorAmounts(class, 3) - armor[ent]);
								SetMetalAmount(client, metalvalue);
								armor[ent] = GetArmorAmounts(class, 3);
							}
						}
					}
				}
			}
		}
	}
}


// Note that damage is BEFORE modifiers are applied by the game for
// things like crits, hitboxes, etc.  The damage shown here will NOT
// match the damage shown in player_hurt (which is after crits, hitboxes,
// etc. are applied).
public Action:TakeDamageHook(client, attacker, inflictor, Float:damage, &Float:multiplier, damagetype)
{
	// change the multiplier
	// (always use *= rather than = so that other plugins modifications are not lost)
	// multiplier *= GetConVarFloat(cvDmgMult);
	if(GetConVarInt(cvArmor)==1)
	{	
		if(damagetype == DMG_ACID || damagetype == DMG_FALL || damagetype == DMG_DROWN)
		{
			PrintToServer("piercing hit");
			Piercing[client] = true;
		}
		else
		{	
			if(armor[client] > 0)
			{
				new health = GetClientHealth(client);
				//if(RoundToCeil(damage) > health)
				//{
				SetEntityHealth(client, health+520);
				hpBeforeHit[client] = health+520;
				hit[client] = true;
			}
			/*else
			{
				hit[client] = true;
			}*/
			//}
		}
	}
	if(GetConVarFloat(cvFDMulti) > 0.0)
	{
		if(damagetype == DMG_FALL)
		{
			multiplier *= GetConVarFloat(cvFDMulti);
			return Plugin_Changed;
		}
	}
	// multipler was changed
	// (use Plugin_Continue if no changes)
	// (use Plugin_Handled to block the game's TraceAttack routine completely)
	return Plugin_Continue;
}

// self-damage boost
public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim_id = GetEventInt(event, "userid");
	new attacker_id = GetEventInt(event, "attacker");
	new health = GetEventInt(event, "health");
	
	
	
	new victim = GetClientOfUserId(victim_id);
	new attacker = GetClientOfUserId(attacker_id);
	new damage = hpBeforeHit[victim] - health;
	
	if(GetConVarInt(cvArmor)==1)
	{
		if(!Piercing[victim] && hit[victim] && damage > 0)
		{
			if(armor[victim] > 0)
			{
				PrintToServer("before, damage:%d health:%d", damage, health);
				new tf2class = int:TF2_GetPlayerClass(victim);
				if(tf2class == SCOUT || tf2class == SNIPER || tf2class == SPY)//light armor
				{
					new Float:tempDamage;
					tempDamage = float(damage)*GetConVarFloat(cvArmorAmounts[0][0]); //amount of damage to armor
					if(armor[victim] <= RoundToFloor(tempDamage))
					{
						tempDamage -= RoundToFloor(tempDamage)-float(armor[victim]); //since there wasnt enough armor, less armor damage, more normal damage
						armor[victim] = 0;
					}
					else
					{
						armor[victim] -= RoundToFloor(tempDamage);
					}
					health += RoundToFloor(tempDamage);
					if(health > 520)
					{
						SetEntityHealth(victim, health-520);
					}
					else
					{
						new String:weaponName[256];
						GetClientWeapon(attacker, weaponName, sizeof(weaponName));
						KillPlayer(victim, attacker, weaponName);
					}
				}
				else if(tf2class == MEDIC || tf2class == DEMO || tf2class == ENGIE || tf2class == PYRO) //medium armor
				{
					new Float:tempDamage;
					tempDamage = float(damage)*GetConVarFloat(cvArmorAmounts[1][0]);
					if(armor[victim] <= RoundToFloor(tempDamage))
					{
						tempDamage -= RoundToFloor(tempDamage)-float(armor[victim]);
						armor[victim] = 0;
					}
					else
					{
						armor[victim] -= RoundToFloor(tempDamage);
					}
					health += RoundToFloor(tempDamage);
					if(health > 520)
					{
						SetEntityHealth(victim, health-520);
					}
					else
					{
						new String:weaponName[256];
						GetClientWeapon(attacker, weaponName, sizeof(weaponName));
						KillPlayer(victim, attacker, weaponName);
					}
					//damage -= RoundToFloor(tempDamage);
					//if(health+RoundToFloor(tempDamage) > 0)
					//{
					//SetEntityHealth(client, health+RoundToFloor(tempDamage));
					//}
				}
				else if(tf2class == HEAVY || tf2class == SOLDIER) //heavy armor
				{
					new Float:tempDamage;
					tempDamage = float(damage)*GetConVarFloat(cvArmorAmounts[2][0]);
					if(armor[victim] < RoundToFloor(tempDamage))
					{
						tempDamage -= RoundToFloor(tempDamage)-float(armor[victim]);
						armor[victim] = 0;
					}
					else
					{
						armor[victim] -= RoundToFloor(tempDamage);
					}
					health += RoundToFloor(tempDamage);
					if(health > 520)
					{
						SetEntityHealth(victim, health-520);
					}
					else
					{
						new String:weaponName[256];
						GetClientWeapon(attacker, weaponName, sizeof(weaponName));
						KillPlayer(victim, attacker, weaponName);
					}
				}
				new newhp = GetClientHealth(victim);
				hit[victim] = false;
				PrintToServer("after, damage:%d, health:%d, armor lost:", damage, newhp);
			}
		}
		else
		{
			if(Piercing[victim])
			{
				Piercing[victim] = false;
			}
		}
	}
	
	PrintToConsole(0, "damage on victim %i by attacker %i", victim, attacker);
	
	if(attacker == victim)
	{
		tempClient = attacker;
		new Float:DamageVel[3];
		new Float:DamageSpeed[1];
		new Float:DamageOldSpeed[1];
		
		GetEntPropVector(attacker, Prop_Data, "m_vecVelocity", DamageVel);
		DamageSpeed[0] = SquareRoot( (DamageVel[0]*DamageVel[0]) + (DamageVel[1]*DamageVel[1]) + (DamageVel[2]*DamageVel[2]) );
		
		DamageOldSpeed[0] = SquareRoot( (VelLastTime[attacker][0]*VelLastTime[attacker][0]) + (VelLastTime[attacker][1]*VelLastTime[attacker][1]) + (VelLastTime[attacker][2]*VelLastTime[attacker][2]) );
		
		if(DamageSpeed[0] > DamageOldSpeed[0])
		{
			DamageVel[0] = GetConVarFloat(SelfBoostX) * DamageVel[0];
			DamageVel[1] = GetConVarFloat(SelfBoostX) * DamageVel[1];
			DamageVel[2] = GetConVarFloat(SelfBoostY) * DamageVel[2];
			
			TeleportEntity(attacker, NULL_VECTOR, NULL_VECTOR, DamageVel);
		}	
	}
	//any special states that attacks can give
	if(GetConVarInt(cvInfectEnabled)==1 || GetConVarInt(cvSniperShot)>0)
	{
		if(attacker <= MaxClients+1 && attacker != 0)
		{
			new String:weaponName[32]; GetClientWeapon(attacker, weaponName, 31);
			if(StrEqual(weaponName, "tf_weapon_syringegun_medic"))
			{
				new curWeapon = GetPlayerWeaponSlot(attacker, 0);
				new String:modelname[128];
				GetEntPropString(curWeapon, Prop_Data, "m_ModelName", modelname, 128);
				if(StrEqual(modelname, "models/weapons/v_models/v_syringegun_medic.mdl"))
				{
					//PrintToServer("hit with syringegun!");
					new Float:min, Float:max, Float:hits;
					min = GetConVarFloat(cvInfectDis[0]);
					max = GetConVarFloat(cvInfectDis[1]);
					new Float:pos[2][3], Float:dis;
					GetClientAbsOrigin(attacker, pos[0]);
					GetClientAbsOrigin(victim, pos[1]);
					dis = GetVectorDistance(pos[0], pos[1]);
					if(dis <= max) {
						if(dis < min) { dis = min; }
						hits = 1.0 / (dis / min);
						infectHits[victim] += hits;
						if(infectHits[victim] >= 20.0*GetConVarFloat(cvInfectHits)){ infectHits[victim] = 20.0*GetConVarFloat(cvInfectHits); }
						PrintToServer("dis = %f, min = %f, max = %f, hits = %f, infectHits = %f", dis, min, max, hits, infectHits[victim]);
					}
					if(infectHits[victim] >= GetConVarFloat(cvInfectHits) && infectionTimer[victim] == INVALID_HANDLE && !isInfected[victim])
					{
						tempInfectHP[victim] = GetClientHealth(victim);
						isInfected[victim] = true;
						//PrintToServer("player %i infected!", victim);
						EmitSoundToAll(SND_INFECT, victim);
						new Handle:pack;
						new Float:randTime = GetRandomFloat(0.0, 0.33);
						infectionTimer[victim] = CreateDataTimer((3.0 + randTime), InfectionTimer, pack, TIMER_REPEAT);
						WritePackCell(pack, victim);
						WritePackCell(pack, attacker);
					}
				}
			}
			else if(StrEqual(weaponName, "tf_weapon_sniperrifle"))
			{
				/*if(GetConVarInt(cvSniperShot)==2)
				{
					new damage = GetDamage(Event, victim, attacker, -1, -1);
					new String:damageString[8]; IntToString(damage, damageString, 7)
					new Float:fDamage = StringToFloat(damageString);
					fDamage = RoundFloat(fDamage/10.0);
					speedDebuff[victim] += GetConVarFloat(cvSniperShotAmount)*fDamage;
					CreateTimer(GetConVarFloat(cvSniperShotDelay), debuffAway, victim);
				}
				else*/
				if(GetConVarInt(cvSniperShot)==1)
				{
					if(speedDebuff[victim] == 1.0)
					{
						speedDebuff[victim] += GetConVarFloat(cvSniperShotAmount);
						CreateTimer(GetConVarFloat(cvSniperShotDelay), debuffAway, victim);
					}
					else
					{
						new Float:temp = speedDebuff[victim];
						temp = (temp - 1.0) / GetConVarFloat(cvSniperShotAmount);
						temp = (temp * 0.5) + GetConVarFloat(cvSniperShotDelay);
						speedDebuff[victim] += GetConVarFloat(cvSniperShotAmount);
						CreateTimer(temp, debuffAway, victim);
					}
				}
			}
		}
	}
	/*if(GetConVarInt(cvArmor)==1)
	{
		if(armored[victim])
		{
			new health = GetClientHealth(victim);
			SetEntityHealth(victim, health+globalDamage[victim]);
			armored[victim] = false;
		}
	}*/
	return Plugin_Continue;
}

public OnGameFrame()
{
	new Float:PlayerVel[3];
	new Float:TrimpVel[3];
	new Float:PlayerSpeed[1];
	new Float:PlayerSpeedLastTime[1];
	new String:TempString[32];
	new Float:EyeAngle[3];
	//fTime = GetGameTime() - lastTime;
	//lastTime = GetGameTime();
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if( IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) )
		{
			if(GetConVarInt(cvBunnyEnabled)==1)
			{
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", PlayerVel);
				PlayerSpeed[0] = SquareRoot( (PlayerVel[0]*PlayerVel[0]) + (PlayerVel[1]*PlayerVel[1]) );
				
				// speedometer
				if(GetConVarBool(SpeedoOff))
				{
					if( GetConVarBool(Speedo) || (PlayerSpeed[0] >= (400.0*GetConVarFloat(BunnyIncrement)/1.2)) )
					{
						PrintCenterText(i, "%f", PlayerSpeed[0]);
					}
					else
					{
						PrintCenterText(i,"");
					}
				}
				new bool:sandman = false;
				
				// bhop, trimp, normal jump
				if( (GetClientButtons(i) & IN_JUMP) && ( (GetEntityFlags(i) & FL_ONGROUND) || WasOnGroundLastTime[i] ) )
				{
					PlayerSpeedLastTime[0] = SquareRoot( (VelLastTime[i][0]*VelLastTime[i][0]) + (VelLastTime[i][1]*VelLastTime[i][1]) );
					
					// check we haven't been slowed down since last time
					if(PlayerSpeedLastTime[0] > PlayerSpeed[0])
					{
						PlayerVel[0] = PlayerVel[0] * PlayerSpeedLastTime[0] / PlayerSpeed[0];
						PlayerVel[1] = PlayerVel[1] * PlayerSpeedLastTime[0] / PlayerSpeed[0];
						PlayerSpeed[0] = PlayerSpeedLastTime[0];
					}
					if(GetConVarInt(BunnyMode)>=4)
					{
						new Float:vSpeed = VelLastTime[i][2];
						if((vSpeed >= 0.0 && PlayerVel[2] >= 0.0))
						{
							if(vSpeed > PlayerVel[2])
							{
								PlayerVel[2] = PlayerVel[2] * (vSpeed / PlayerVel[2]);
							}
						}
						else if((vSpeed <= 0.0 && PlayerVel[2] <= 0.0))
						{
							if(vSpeed < PlayerVel[2])
							{
								PlayerVel[2] = PlayerVel[2] * (vSpeed / PlayerVel[2]);
							}
						}
					}
					
					// trimp
					if( ( (GetClientButtons(i) & IN_FORWARD) || (GetClientButtons(i) & IN_BACK) ) && (PlayerSpeed[0] >= (400.0 * 1.6)) && (GetClientButtons(i) & IN_DUCK))
					{
						if(GetConVarInt(cvTrimpEnabled)==1)
						{
							TrimpVel[0] = PlayerVel[0] * Cosine(70.0*3.14159265/180.0);
							TrimpVel[1] = PlayerVel[1] * Cosine(70.0*3.14159265/180.0);
							TrimpVel[2] = PlayerSpeed[0] * Sine(70.0*3.14159265/180.0);
							
							InTrimp[i] = true;
							
							TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, TrimpVel);
						}
					}
					
					// bhop (and normal jump)
					else
					{	
						// apply bhop boost
						if( WasOnGroundLastTime[i] || (GetClientButtons(i) & IN_DUCK) )
						{
							if(GetConVarInt(BunnyMode)>=4)
							{
								if(GetConVarFloat(cvDJumpDelay)!=0.0)
								{
									new Float:time = GetGameTime();
									if(time - lastJumpTime[i] > 0.035)
									{
										PlayerVel[2] = 800.0/3.0; 
								
										new Float:delay;
										delay = IsDJumpReady(i, time);
										PrintToServer("Vel = %f", PlayerVel[2]);
										if(delay>0.0)
										{
											PlayerVel[2] = DoubleJump(delay, PlayerVel); 
										}
										//PrintToServer("lastJumpTime = %f, curTime = %f, delay = %f, vel = %f", lastJumpTime[i], time, delay, PlayerVel[2]);
										lastJumpTime[i] = time;
									}
								}
								else
								{
									PlayerVel[2] = 800.0/3.0;
								}
							}
							else
							{
								PlayerVel[2] = 800.0/3.0; 
								
							}
						}						
						else
						{
							switch (GetConVarInt(BunnyMode))
							{
								case 0:
								{
									PlayerVel[0] = 1.2 * PlayerVel[0];
									PlayerVel[1] = 1.2 * PlayerVel[1];
									PlayerSpeed[0] = 1.2 * PlayerSpeed[0];
									PlayerVel[2] = 800.0/3.0; 
								}
								case 1:
								{
								}
								case 2:
								{
									PlayerVel[0] = GetConVarFloat(BunnyIncrement) * PlayerVel[0];
									PlayerVel[1] = GetConVarFloat(BunnyIncrement) * PlayerVel[1];
									PlayerSpeed[0] = GetConVarFloat(BunnyIncrement) * PlayerSpeed[0];
									PlayerVel[2] = 800.0/3.0; 
								}
								case 3:
								{
									PlayerVel[0] = GetConVarFloat(BunnyIncrement) * PlayerVel[0];
									PlayerVel[1] = GetConVarFloat(BunnyIncrement) * PlayerVel[1];
									PlayerSpeed[0] = GetConVarFloat(BunnyIncrement) * PlayerSpeed[0];
									PlayerVel[2] = 800.0/3.0; 
								}
								case 4:
								{
									PlayerVel[0] = GetConVarFloat(BunnyIncrement) * PlayerVel[0];
									PlayerVel[1] = GetConVarFloat(BunnyIncrement) * PlayerVel[1];
									PlayerSpeed[0] = GetConVarFloat(BunnyIncrement) * PlayerSpeed[0];
									PlayerVel[2] = 800.0/3.0; 
									if(GetConVarFloat(cvDJumpDelay)!=0.0)
									{
										new Float:time = GetGameTime();
										if(time - lastJumpTime[i] > 0.05)
										{
											new Float:delay;
											delay = IsDJumpReady(i, time);
											if(delay>0.0)
											{
												PlayerVel[2] = DoubleJump(delay, PlayerVel); 
											}
											lastJumpTime[i] = time;
										}
									}
									
								}
								case 5:
								{
									PlayerVel[0] = GetConVarFloat(BunnyIncrement) * PlayerVel[0];
									PlayerVel[1] = GetConVarFloat(BunnyIncrement) * PlayerVel[1];
									PlayerSpeed[0] = GetConVarFloat(BunnyIncrement) * PlayerSpeed[0];
									if(PlayerVel[2] >= 0.0){ PlayerVel[2] += 800.0/3.0; } else { PlayerVel[2] = 800.0/3.0; }
									if(GetConVarFloat(cvDJumpDelay)!=0.0)
									{
										new Float:time = GetGameTime();
										if(time - lastJumpTime[i] > 0.05)
										{
											PlayerVel[2] = 800.0/3.0;
											new Float:delay;
											delay = IsDJumpReady(i, time);
											if(delay>0.0)
											{
												PlayerVel[2] = DoubleJump(delay, PlayerVel); 
											}
											lastJumpTime[i] = time;
										}
									}
								}
								case 6:
								{
									new Float:tempPVel[3];
									tempPVel[0] = (GetConVarFloat(BunnyIncrement)-1.0) * PlayerVel[0];
									tempPVel[1] = (GetConVarFloat(BunnyIncrement)-1.0) * PlayerVel[1];
									PlayerSpeed[0] = (GetConVarFloat(BunnyIncrement)-1.0) * PlayerSpeed[0];
									if(PlayerVel[2] >= 0.0){ PlayerVel[2] += 800.0/3.0; } else { PlayerVel[2] = 800.0/3.0; }
									tempPVel[2] = 0.0;
									new Float:vecDown[3] = {90.0, 0.0, 0.0};
									new Float:origin[3], Float:n[3];
									GetClientAbsOrigin(i, origin);
									new Handle:traces = TR_TraceRayFilterEx(origin, vecDown, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceRayDontHitSelfOrPlayers, i); 
									if(TR_DidHit(traces))
									{
										TR_GetPlaneNormal(traces, n);
										new Float:length = GetVectorLength(tempPVel);
										GetAngleVectors(n, n, NULL_VECTOR, NULL_VECTOR);
										ScaleVector(n, length);
										if((n[0]>=0.0 && PlayerVel[0] <=0.0) || (n[0]<=0.0 && PlayerVel[0] >=0.0))
										{ 
											n[2] += FloatAbs(n[0]);
											n[0] = 0.0;
										}
										if((n[1]>=0.0 && PlayerVel[1] <=0.0) || (n[1]<=0.0 && PlayerVel[1] >=0.0))
										{
											n[2] += FloatAbs(n[1]);
											n[1] = 0.0;
										}
										AddVectors(PlayerVel, n, PlayerVel);
									}
									if(GetConVarFloat(cvDJumpDelay)!=0.0)
									{
										new Float:time = GetGameTime();
										if(time - lastJumpTime[i] > 0.05)
										{
											PlayerVel[2] = 800.0/3.0;
											new Float:delay;
											delay = IsDJumpReady(i, time);
											if(delay>0.0)
											{
												PlayerVel[2] = DoubleJump(delay, PlayerVel); 
											}
											lastJumpTime[i] = time;
										}
									}
								}
							}
						}
						if(GetConVarInt(cvSpeedCheck)==1)
						{
							PlayerVel = CheckSpeed(PlayerSpeedLastTime[0], PlayerSpeed[0], PlayerVel);
						}
						// apply bhop caps
						if(GetConVarInt(BunnyMode) >= 2 ){
							if(GetClientButtons(i) & IN_DUCK)
							{
								if(PlayerSpeed[0] > ((1.2 * 400.0 * GetConVarFloat(BunnyCap))/speedDebuff[i]))
								{
									if(GetConVarInt(BunnyMode) >= 3)
									{
										PlayerVel[0] = PlayerVel[0] - PlayerVel[0]*GetConVarFloat(BunnySlowDown);
										PlayerVel[1] = PlayerVel[1] - PlayerVel[1]*GetConVarFloat(BunnySlowDown);
									}
									else
									{
										PlayerVel[0] = PlayerVel[0] * 1.2 * 400.0 * GetConVarFloat(BunnyCap) / PlayerSpeed[0];
										PlayerVel[1] = PlayerVel[1] * 1.2 * 400.0 * GetConVarFloat(BunnyCap) / PlayerSpeed[0];
									}
								}
							}
							else if(PlayerSpeed[0] > ((400.0 * GetConVarFloat(BunnyCap))/speedDebuff[i]))
							{
								if(GetConVarInt(BunnyMode) >= 3)
								{
									PlayerVel[0] = PlayerVel[0] - PlayerVel[0]*GetConVarFloat(BunnySlowDown);
									PlayerVel[1] = PlayerVel[1] - PlayerVel[1]*GetConVarFloat(BunnySlowDown);
								}
								else
								{
									PlayerVel[0] = PlayerVel[0] * 400.0 * GetConVarFloat(BunnyCap) / PlayerSpeed[0];
									PlayerVel[1] = PlayerVel[1] * 400.0 * GetConVarFloat(BunnyCap) / PlayerSpeed[0];
								}
							}
						}
						else
						{
							if(GetClientButtons(i) & IN_DUCK)
							{
								if(PlayerSpeed[0] > (1.2 * 400.0 * 1.6))
								{
									PlayerVel[0] = PlayerVel[0] * 1.2 * 400.0 * 1.6 / PlayerSpeed[0];
									PlayerVel[1] = PlayerVel[1] * 1.2 * 400.0 * 1.6 / PlayerSpeed[0];
								}
							}
							else if(PlayerSpeed[0] > (400.0 * 1.6))
							{
								PlayerVel[0] = PlayerVel[0] * 400.0 * 1.6 / PlayerSpeed[0];
								PlayerVel[1] = PlayerVel[1] * 400.0 * 1.6 / PlayerSpeed[0];
							}
						}
						
						
						
						if(GetConVarInt(cvShowJumpInfo)>0)
						{
							GetClientAbsOrigin(i, LastJumpLoc[i]);
							GetClientAbsOrigin(i, LastHorLoc[i]);
							InJump[i] = true;
						}
						
						if(GetConVarInt(cvWallJump)==1)
						{ 
							if(wallJumpReady[i])
							{ wallJumpReady[i] = false; CreateTimer((GetConVarFloat(cvWallJumpDelay)), WallJumpReady, i); }
						}
						TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel);
					}
				}
				// doublejump
				else if( (InTrimp[i] || (CanDJump[i] && (TF2_GetPlayerClass(i) == TFClass_Scout))) && (WasInJumpLastTime[i] == 0) && (GetClientButtons(i) & IN_JUMP) )
				{
					if(GetConVarInt(cvSandManDJump) == 0)
					{
						new String:classname[32], wpn;
						for(new j=0;j<=5;j++) 
						{
							wpn = GetPlayerWeaponSlot(i, j);
							if(wpn!=-1) 
							{
								GetEdictClassname(wpn, classname, sizeof(classname));
								if(StrEqual(classname, "tf_weapon_bat_wood"))
								{
										sandman = true;
								}
							}
						}
					}
					if(!sandman)
					{
						PlayerSpeedLastTime[0] = 1.1 * SquareRoot( (VelLastTime[i][0]*VelLastTime[i][0]) + (VelLastTime[i][1]*VelLastTime[i][1]) );
				
						if(PlayerSpeedLastTime[0] < 400.0)
						{
							PlayerSpeedLastTime[0] = 400.0;
						}
						
						if(PlayerSpeed[0] == 0.0)
						{
							PlayerSpeedLastTime[0] = 0.0;
						}
						
						PlayerVel[0] = PlayerVel[0] * PlayerSpeedLastTime[0] / PlayerSpeed[0];
						PlayerVel[1] = PlayerVel[1] * PlayerSpeedLastTime[0] / PlayerSpeed[0];
						PlayerSpeed[0] = PlayerSpeed[0] * PlayerSpeedLastTime[0] / PlayerSpeed[0];
						if(GetConVarInt(BunnyMode)<4) 
						{ 
							PlayerVel[2] = 800.0/3.0; 
						} 
						else if(GetConVarInt(BunnyMode)>=4)
						{ 
							if(PlayerVel[2] >= 800.0/3.0){ PlayerVel[2] += 400.0/3.0; } else { PlayerVel[2] = 800.0/3.0; }
							
							if(GetConVarFloat(cvDJumpDelay)!=0.0)
							{
								
								new Float:time = GetGameTime();
								if(time - lastJumpTime[i] > 0.05)
								{
									PlayerVel[2] = 800.0/3.0;
									new Float:delay;
									delay = IsDJumpReady(i, time);
									if(delay>0.0)
									{
										PlayerVel[2] = DoubleJump(delay, PlayerVel, 2); 
									}
									lastJumpTime[i] = time;
								}
							}
						}
						
						if(GetConVarInt(cvSpeedCheck)==1)
						{
							PlayerVel = CheckSpeed(PlayerSpeedLastTime[0], PlayerSpeed[0], PlayerVel);
						}
						if(PlayerSpeed[0] > ((1.2 * 400.0 * GetConVarFloat(BunnyCap))/speedDebuff[i]))
						{
							PlayerVel[0] = PlayerVel[0] - PlayerVel[0]*GetConVarFloat(BunnySlowDown);
							PlayerVel[1] = PlayerVel[1] - PlayerVel[1]*GetConVarFloat(BunnySlowDown);
						}
						CanDJump[i] = false;
						InTrimp[i] = false;
						
						TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel);
					}
				}
				
				// rocketman
				else
				{
					if(GetConVarInt(cvPyroFly)==1)
					{
						if(GetEntityFlags(i) & FL_ONGROUND){}
						else
						{
							GetClientWeapon(i,TempString,32);
							if( (strcmp(TempString,"tf_weapon_flamethrower") == 0) && (GetClientButtons(i) & IN_ATTACK) )
							{
								GetClientEyeAngles(i, EyeAngle);
								
								PlayerVel[2] = PlayerVel[2] + ( 15.0 * Sine(EyeAngle[0]*3.14159265/180.0) );
								
								if(PlayerVel[2] > 100.0)
								{
									PlayerVel[2] = 100.0;
								}
								
								PlayerVel[0] = PlayerVel[0] - ( 3.0 * Cosine(EyeAngle[0]*3.14159265/180.0) * Cosine(EyeAngle[1]*3.14159265/180.0) );
								PlayerVel[1] = PlayerVel[1] - ( 3.0 * Cosine(EyeAngle[0]*3.14159265/180.0) * Sine(EyeAngle[1]*3.14159265/180.0) );
								
								TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel);
							}
						}
					}
				}
								
				// enable doublejump
				if( ( (InTrimp[i] == 1) || (CanDJump[i] == 0) ) && (GetEntityFlags(i) & FL_ONGROUND) )
				{
					CanDJump[i] = true;
					InTrimp[i] = false;
				}
				
				// Jump Information
				if(GetConVarInt(cvShowJumpInfo)>0)
				{
					if(InJump[i] && (GetEntityFlags(i) & FL_ONGROUND))
					{
						if(GetConVarInt(cvShowJumpInfo)>0)
						{
							PrintToChat(i, "Jump:");
							new Float:CurLandLoc[3]; GetClientAbsOrigin(i, CurLandLoc);
							new Float:length;
							new Float:VecLength[3];
							new Float:height; 
							height = LastJumpLoc[i][2] - MaxHeight[i];
							if(height < 0.0){ height*=-1.0; }
							
							length = GetVectorLength(VecLength);
							for(new j=0;j<3;j++)
							{
								if(VecLength[j] < 0.0)
								{ VecLength[j] *= -1; }
							}
							if(GetConVarInt(cvShowJumpInfo)==1) //speed
							{
								PrintToChat(i, "Max Horizontal Speed = %f, Max Vertical Speed = %f", HorMaxSpeed[i], VerMaxSpeed[i]);
							}
							else if(GetConVarInt(cvShowJumpInfo)==2) //distance
							{
								PrintToChat(i, "Horizontal Distance = %f, Max Height = %f", HorDistance[i], height);
							}
							else if(GetConVarInt(cvShowJumpInfo)==3) //both
							{
								PrintToChat(i, "Horizontal Distance = %f, Max Height = %f", HorDistance[i], height);
								PrintToChat(i, "Max Horizontal Speed = %f, Max Vertical Speed = %f", HorMaxSpeed[i], VerMaxSpeed[i]);
							}
							else if(GetConVarInt(cvShowJumpInfo)==4)
							{
								PrintToChat(i, "length = %f, x = %f, y = %f, z = %f", length, VecLength[0], VecLength[1], VecLength[2]);
								PrintToChat(i, "Max Horizontal Speed = %f, Max Vertical Speed = %f", HorMaxSpeed[i], VerMaxSpeed[i]);
							}
							InJump[i] = false;
							HorMaxSpeed[i] = 0.0;
							VerMaxSpeed[i] = 0.0;
							HorDistance[i] = 0.0;
							MaxHeight[i] = 0.0;
						}
						else if(GetConVarInt(BunnyMode)==5)
						{
							InJump[i] = false;
							HorMaxSpeed[i] = 0.0;
							VerMaxSpeed[i] = 0.0;
							HorDistance[i] = 0.0;
							MaxHeight[i] = 0.0;
						}
					}
					if(InJump[i])
					{
						if(PlayerSpeed[0] >= 0.0)
						{
							if(PlayerSpeed[0] > HorMaxSpeed[0])
							{
								HorMaxSpeed[i] = PlayerSpeed[0];
							}
						}
						else
						{
							if(-PlayerSpeed[0] > HorMaxSpeed[0])
							{
								HorMaxSpeed[i] = PlayerSpeed[0];
							}
						}
						if(PlayerVel[2] > VerMaxSpeed[2])
						{
							VerMaxSpeed[i] = PlayerVel[2];
						}
					}
				}
				
				// wall jump
				if(GetConVarInt(cvWallJump)==1)
				{
					new Float:tempCheck[3], Float:lengthCheck;
					GetEntPropVector(i, Prop_Data, "m_vecVelocity", tempCheck);
					lengthCheck = GetVectorLength(tempCheck);
					if(( !(GetEntityFlags(i) & FL_ONGROUND) || !WasOnGroundLastTime[i] ) && (GetClientButtons(i) & IN_JUMP) && wallJumpReady[i] && (lengthCheck > GetConVarFloat(cvWallJumpMinSpeed)) && (GetClientButtons(i) & IN_DUCK))//
					{
						new tempclass = int:TF2_GetPlayerClass(i);
						if(tempclass==SPY)
						{
							new Float:orig[3], Float:ang[3], Float:angEye[3], Float:power, Float:vecEye[3];
							new Float:pos[3], Float:distance, Float:boostSpeed[2][3], Float:normal[3], Float:tempnormal[3];
							power = GetConVarFloat(cvWallJumpPower);
							new Handle:tr;
							GetClientEyePosition(i, orig);
							orig[2] -= 16.0;
							GetClientEyeAngles(i, angEye);
							GetClientAbsAngles(i, ang);
							GetAngleVectors(angEye, vecEye, NULL_VECTOR, NULL_VECTOR);
							ang[1] += 90.0; ang[0] = 0.0; ang[2] = 0.0;
							tr = TR_TraceRayFilterEx(orig, ang, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelfOrPlayers, i);
							if (tr!=INVALID_HANDLE)
							{
								if (TR_GetFraction(tr)<0.98)
								{
									TR_GetEndPosition(pos, tr);
									SubtractVectors(orig, pos, pos);
									distance = GetVectorLength(pos);
									if(distance < 0.0){ distance*=-1.0; }
									if(distance < GetConVarFloat(cvWallJumpDistance))
									{
										new Float:vecVel[3];
										TR_GetPlaneNormal(tr, normal);
										GetVectorAngles(normal, tempnormal);
										GetEntPropVector(i, Prop_Data, "m_vecVelocity", vecVel);
										if(CheckNormal(vecVel, normal))
										{
											ang[1]-=180.0; 
											GetAngleVectors(ang, ang, NULL_VECTOR, NULL_VECTOR);
											new Float:vecSpeed[3]; vecSpeed = vecVel;
											if(vecVel[2] < 0.0) { vecSpeed[2] = 0.0; }
											new Float:tempSpeed = GetVectorLength(vecSpeed);
											if(tempSpeed < power) { tempSpeed = power; }
											new Float:tempVel[3];
											boostSpeed[0][0] = normal[0]*power; boostSpeed[0][1] = normal[1]*power; boostSpeed[0][2] = normal[2]*power;
											boostSpeed[1][0] = vecEye[0]*((tempSpeed+power)/1.5); boostSpeed[1][1] = vecEye[1]*((tempSpeed+power)/1.5); boostSpeed[1][2] = vecEye[2]*(tempSpeed+power);
											if(boostSpeed[1][2] > 0.0 && boostSpeed[1][2]<power){ boostSpeed[1][2] = power; }
											AddVectors(boostSpeed[1], boostSpeed[0], tempVel);
											tempSpeed = GetVectorLength(vecVel);
											for(new j=0;j<3;j++)
											{	
												if(tempSpeed > ((1.2 * 400.0 * GetConVarFloat(BunnyCap))/speedDebuff[i]))
												{
													tempVel[0] = tempVel[0] - tempVel[0]*GetConVarFloat(BunnySlowDown);
													tempVel[1] = tempVel[1] - tempVel[1]*GetConVarFloat(BunnySlowDown);
												}
												if(boostSpeed[0][j] > 0.0 && tempVel[j] > 0.0)
												{
													if(tempVel[j] < boostSpeed[0][j])
													{
														tempVel[j] = boostSpeed[0][j];
													}
												}
												else if(boostSpeed[0][j] > 0.0 && tempVel[j] < 0.0)
												{
													tempVel[j] = boostSpeed[0][j];
												}
												else if(boostSpeed[0][j] < 0.0 && tempVel[j] > 0.0)
												{
													tempVel[j] = boostSpeed[0][j];
												}
												else if(boostSpeed[0][j] < 0.0 && tempVel[j] < 0.0)
												{
													if(tempVel[j] > boostSpeed[0][j])
													{
														tempVel[j] = boostSpeed[0][j];
													}
												}
											}
											if(GetConVarFloat(cvDJumpDelay)!=0.0)
											{
												new Float:time = GetGameTime();
												if(time - lastJumpTime[i] > 0.05)
												{
													new Float:delay;
													delay = IsDJumpReady(i, time);
													if(delay>0.0)
													{
														PlayerVel[2] = DoubleJump(delay, tempVel); 
													}
													lastJumpTime[i] = time;
												}
											}
											TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, tempVel);
											wallJumpReady[i] = false;
											if( (normal[0] - oldNormal[i][0] > -0.1 && normal[0] - oldNormal[i][0] < 0.1) && (normal[1] - oldNormal[i][1] > -0.1 && normal[1] - oldNormal[i][1] < 0.1) )
											{
												CreateTimer(GetConVarFloat(cvWallJumpDelay2), WallJumpReady, i);
											}
											else
											{
												CreateTimer(GetConVarFloat(cvWallJumpDelay), WallJumpReady, i);
											}
											oldNormal[i][0] = normal[0]; oldNormal[i][1] = normal[1]; oldNormal[i][2] = normal[2];
											CloseHandle(tr);
										}
									}
									else
									{
										CloseHandle(tr);
										ang[1]-=180.0;
										tr = TR_TraceRayFilterEx(orig, ang, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelfOrPlayers, i);
										if (tr!=INVALID_HANDLE)
										{
											if (TR_GetFraction(tr)<0.98)
											{
												TR_GetEndPosition(pos, tr);
												SubtractVectors(orig, pos, pos);
												distance = GetVectorLength(pos);
												if(distance < GetConVarFloat(cvWallJumpDistance))
												{
													new Float:vecVel[3];
													TR_GetPlaneNormal(tr, normal);
													GetVectorAngles(normal, tempnormal);
													GetEntPropVector(i, Prop_Data, "m_vecVelocity", vecVel);
													if(CheckNormal(vecVel, normal))
													{
														new Float:vecSpeed[3]; vecSpeed = vecVel;
														if(vecVel[2] < 0.0) { vecSpeed[2] = 0.0; }
														new Float:tempSpeed = GetVectorLength(vecSpeed);
														if(tempSpeed < power) { tempSpeed = power; }
														ang[1]+=180.0; 
														GetAngleVectors(ang, ang, NULL_VECTOR, NULL_VECTOR);
														new Float:tempVel[3];
														boostSpeed[0][0] = normal[0]*power; boostSpeed[0][1] = normal[1]*power; boostSpeed[0][2] = normal[2]*power;
														boostSpeed[1][0] = vecEye[0]*((tempSpeed+power)/1.5); boostSpeed[1][1] = vecEye[1]*((tempSpeed+power)/1.5); boostSpeed[1][2] = vecEye[2]*(tempSpeed+power);
														if(boostSpeed[1][2] > 0.0 && boostSpeed[1][2]<power){ boostSpeed[1][2] = power; }
														AddVectors(boostSpeed[1], boostSpeed[0], tempVel);
														tempSpeed = GetVectorLength(vecVel);
														for(new j=0;j<3;j++)
														{
															if(tempSpeed > ((1.2 * 400.0 * GetConVarFloat(BunnyCap))/speedDebuff[i]))
															{
																tempVel[0] = tempVel[0] - tempVel[0]*GetConVarFloat(BunnySlowDown);
																tempVel[1] = tempVel[1] - tempVel[1]*GetConVarFloat(BunnySlowDown);
															}
															if(boostSpeed[0][j] > 0.0 && tempVel[j] > 0.0)
															{
																if(tempVel[j] < boostSpeed[0][j])
																{
																	tempVel[j] = boostSpeed[0][j];
																}
															}
															else if(boostSpeed[0][j] > 0.0 && tempVel[j] < 0.0)
															{
																tempVel[j] = boostSpeed[0][j];
															}
															else if(boostSpeed[0][j] < 0.0 && tempVel[j] > 0.0)
															{
																tempVel[j] = boostSpeed[0][j];
															}
															else if(boostSpeed[0][j] < 0.0 && tempVel[j] < 0.0)
															{
																if(tempVel[j] > boostSpeed[0][j])
																{
																	tempVel[j] = boostSpeed[0][j];
																}
															}
														}
														if(GetConVarFloat(cvDJumpDelay)!=0.0)
														{
															new Float:time = GetGameTime();
															if(time - lastJumpTime[i] > 0.05)
															{
																new Float:delay;
																delay = IsDJumpReady(i, time);
																if(delay>0.0)
																{
																	PlayerVel[2] = DoubleJump(delay, tempVel); 
																}
																lastJumpTime[i] = time;
															}
														}
														TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, tempVel);
														wallJumpReady[i] = false;
														if( (normal[0] - oldNormal[i][0] > -0.1 && normal[0] - oldNormal[i][0] < 0.1) && (normal[1] - oldNormal[i][1] > -0.1 && normal[1] - oldNormal[i][1] < 0.1) )
														{
															CreateTimer(GetConVarFloat(cvWallJumpDelay2), WallJumpReady, i);
														}
														else
														{
															CreateTimer(GetConVarFloat(cvWallJumpDelay), WallJumpReady, i);
														}
														oldNormal[i][0] = normal[0]; oldNormal[i][1] = normal[1]; oldNormal[i][2] = normal[2];
													}
												}
												CloseHandle(tr);
											}
										}
									}
								}								
							}
							else
							{
								ang[1]-=180.0;
								tr = TR_TraceRayFilterEx(orig, ang, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelfOrPlayers, i);
								if (tr!=INVALID_HANDLE)
								{
									if (TR_GetFraction(tr)<0.98)
									{
										TR_GetEndPosition(pos, tr);
										SubtractVectors(orig, pos, pos);
										distance = GetVectorLength(pos);
										if(distance < GetConVarFloat(cvWallJumpDistance))
										{
											new Float:vecVel[3];
											TR_GetPlaneNormal(tr, normal);
											GetEntPropVector(i, Prop_Data, "m_vecVelocity", vecVel);
											if(CheckNormal(vecVel, normal))
											{
												ang[1]+=180.0; 
												GetAngleVectors(ang, ang, NULL_VECTOR, NULL_VECTOR);
												new Float:vecSpeed[3]; vecSpeed = vecVel;
												if(vecVel[2] < 0.0) { vecSpeed[2] = 0.0; }
												new Float:tempSpeed = GetVectorLength(vecSpeed);
												if(tempSpeed < power) { tempSpeed = power; }
												new Float:tempVel[3];
												boostSpeed[0][0] = normal[0]*power; boostSpeed[0][1] = normal[1]*power; boostSpeed[0][2] = normal[2]*power;
												boostSpeed[1][0] = vecEye[0]*((tempSpeed+power)/1.5); boostSpeed[1][1] = vecEye[1]*((tempSpeed+power)/1.5); boostSpeed[1][2] = vecEye[2]*(tempSpeed+power);
												if(boostSpeed[1][2] > 0.0 && boostSpeed[1][2]<power){ boostSpeed[1][2] = power; }
												AddVectors(boostSpeed[1], boostSpeed[0], tempVel);
												tempSpeed = GetVectorLength(vecVel);
												for(new j=0;j<3;j++)
												{
													if(tempSpeed > ((1.2 * 400.0 * GetConVarFloat(BunnyCap))/speedDebuff[i]))
													{
														tempVel[0] = tempVel[0] - tempVel[0]*GetConVarFloat(BunnySlowDown);
														tempVel[1] = tempVel[1] - tempVel[1]*GetConVarFloat(BunnySlowDown);
													}
													if(boostSpeed[0][j] > 0.0 && tempVel[j] > 0.0)
													{
														if(tempVel[j] < boostSpeed[0][j])
														{
															tempVel[j] = boostSpeed[0][j];
														}
													}
													else if(boostSpeed[0][j] > 0.0 && tempVel[j] < 0.0)
													{
														tempVel[j] = boostSpeed[0][j];
													}
													else if(boostSpeed[0][j] < 0.0 && tempVel[j] > 0.0)
													{
														tempVel[j] = boostSpeed[0][j];
													}
													else if(boostSpeed[0][j] < 0.0 && tempVel[j] < 0.0)
													{
														if(tempVel[j] > boostSpeed[0][j])
														{
															tempVel[j] = boostSpeed[0][j];
														}
													}
												}
												if(GetConVarFloat(cvDJumpDelay)!=0.0)
												{
													new Float:time = GetGameTime();
													if(time - lastJumpTime[i] > 0.05)
													{
														new Float:delay;
														delay = IsDJumpReady(i, time);
														if(delay>0.0)
														{
															PlayerVel[2] = DoubleJump(delay, tempVel); 
														}
														lastJumpTime[i] = time;
													}
												}
												TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, tempVel);
												
												wallJumpReady[i] = false;
												if( (normal[0] - oldNormal[i][0] > -0.1 && normal[0] - oldNormal[i][0] < 0.1) && (normal[1] - oldNormal[i][1] > -0.1 && normal[1] - oldNormal[i][1] < 0.1) )
												{
													CreateTimer(GetConVarFloat(cvWallJumpDelay2), WallJumpReady, i);
												}
												else
												{
													CreateTimer(GetConVarFloat(cvWallJumpDelay), WallJumpReady, i);
												}
												oldNormal[i][0] = normal[0]; oldNormal[i][1] = normal[1]; oldNormal[i][2] = normal[2];
											}
										}
										CloseHandle(tr);
									}
									CloseHandle(tr);
								}
							}
						}
					}
				}
				
				// always save this stuff for next time
				WasInJumpLastTime[i] = (GetClientButtons(i) & IN_JUMP);
				WasOnGroundLastTime[i] = (GetEntityFlags(i) & FL_ONGROUND);
				VelLastTime[i][0] = PlayerVel[0];
				VelLastTime[i][1] = PlayerVel[1];
				VelLastTime[i][2] = PlayerVel[2];
			}
			
			/*if(GetConVarInt(cvStrafeEnabled)==1)
			{
				
				//GetEntPropVector(i, Prop_Data, "m_vecVelocity", PlayerVel);
			}*/
			
			// infection
			if(GetConVarInt(cvInfectEnabled)==1)
			{
				if(infectionTimer[i] != INVALID_HANDLE && isInfected[i])
				{
					if(tempInfectHP[i] < GetClientHealth(i))
					{
						new String:TempString2[32];
						new healthdiff = GetClientHealth(i) - tempInfectHP[i];
						IntToString( healthdiff, TempString2, 31);
						new Float:diffFloat = StringToFloat(TempString2);
						PrintToServer("hpdif = %f, curhp = %i, lasthp = %i", diffFloat, GetClientHealth(i), tempInfectHP[i]);
						if(diffFloat > 3.0)
						{ diffFloat = 0.0; }
						PrintToServer("hpdif = %f", diffFloat);
						if((infectHits[i] - diffFloat) >= GetConVarFloat(cvInfectHits))
						{
							infectHits[i] -= diffFloat;
							tempInfectHP[i] = GetClientHealth(i);
							//PrintToServer("player %i healed %f", i, healthdiff);
						}
						else
						{
							infectHits[i] = 0.0;
							isInfected[i] = false;
							KillTimer(infectionTimer[i]);
							infectionTimer[i] = INVALID_HANDLE;
							tempInfectHP[i] = 0;
							SetEntityRenderColor(i, 255, 255, 255, 255);
							//PrintToServer("player %i healed from his infection", i);
						}
					}
					else
					{
						tempInfectHP[i] = GetClientHealth(i);
					}
				}
			}
			
			if(GetConVarInt(cvQuickSwitch)==1)
			{
				if(GetClientButtons(i) & IN_ALT1)
				{ PrintToServer("client %i IN_ALT1", i); }
				if(GetClientButtons(i) & IN_ALT2)
				{ PrintToServer("client %i IN_ALT2", i); }
				if(GetClientButtons(i) & IN_WEAPON1)
				{ PrintToServer("client %i IN_RELOAD", i); }
				if(GetClientButtons(i) & IN_WEAPON2)
				{ PrintToServer("client %i IN_RELOAD", i); }
				if(GetClientButtons(i) & IN_RELOAD)
				{ PrintToServer("client %i IN_RELOAD", i); }
			}
			
			//saving stuff for jump info
			if(GetConVarInt(cvShowJumpInfo)>0 || GetConVarInt(BunnyMode)==5)
			{
				if(InJump[i])
				{
					new Float:CurHorLoc[3]; GetClientAbsOrigin(i, CurHorLoc);
					new Float:DistanceVector[3]; SubtractVectors(LastHorLoc[i],CurHorLoc,DistanceVector);
					
					for(new j=0;j<3;j++)
					{
						if(DistanceVector[j]<0.0)
						{
							DistanceVector[j]*=-1.0;
						}
					}
					if(CurHorLoc[2] > MaxHeight[i])
					{ MaxHeight[i] = CurHorLoc[2]; }
					LastHorLoc[i] = CurHorLoc;
					HorDistance[i] += SquareRoot((DistanceVector[0] * DistanceVector[0]) + (DistanceVector[1] * DistanceVector[1]));
				}
			}
		}
	}
}


public ResultType:dhOnEntitySpawned(edict) 
{
	new String:classname[64];
	GetEdictClassname(edict, classname, sizeof(classname));
	if(StrEqual(classname, "tf_projectile_rocket")) 
	{ 
		CreateTimer(0.01, ScaleSpeed, edict);
	}
	else if(StrEqual(classname, "obj_dispenser"))
	{
		if(IsValidEntity(edict))
		{
			new client = GetEntPropEnt(edict, Prop_Data, "m_hOwnerEntity");
			dispenser[client] = edict;
		}
	}
	
	if(StrEqual(classname, "tf_projectile_pipe")) 
	{ 
		new Float:first = GetEntPropFloat(edict, Prop_Data, "m_flDetonateTime");
		PrintToServer("first = %f", first);
	}
}

// entity listener
public ResultType:dhOnEntityDeleted(edict)
{
	// get class name
	if(IsValidEntity(edict))
		{
		new String:classname[64];
		GetEdictClassname(edict, classname, sizeof(classname)); 
		// PrintToServer("%s", classname);
		// print entity class name to console
		if(StrEqual(classname, "tf_projectile_rocket") || StrEqual(classname, "tf_projectile_pipe")) 
		{ 
			new self = GetEntPropEnt(edict, Prop_Data, "m_hOwnerEntity");
			if(self == -1)
			{
				self = tempClient;
				tempClient = 0;
			}
			new Float:center[3];
			GetEntPropVector(edict, Prop_Send, "m_vecOrigin", center);
			
			new Float:radius = GetConVarFloat(cvExplosionRadius);
			new oteam = 0;
			if (GetEntProp(edict, Prop_Data, "m_iTeamNum")==3) {oteam=2;} else {oteam=3;}
			//PrintToServer("self = %i, other team = %i", self, oteam);
			//FindPlayersInRange2(center, radius, oteam, true, edict);
			FindPlayersInRange(center, radius, oteam, self, true, edict);
			new j;
			new Float:play[3];
			new Float:playerspeed[3];
			new Float:distance;
			new maxplayers = GetMaxClients();
			for (j=1;j<=maxplayers;j++)
			{
				if(PlayersInRange[j]>0.0)
				{
					GetClientAbsOrigin(j, play);
					SubtractVectors(play, center, play);
					distance = GetVectorLength(play);
					distance -= GetConVarFloat(cvQuadThreshold);
					if(distance< 0.0) { distance *= -1.0; }
					if(distance<0.01){ distance = 0.01;}
					ScaleVector(play, 1.0 - FloatDiv(distance, radius));
					ScaleVector(play, GetConVarFloat(cvExplosionPower));
					GetEntPropVector(j, Prop_Data, "m_vecVelocity", playerspeed);
					if(playerspeed[2]<0.0) { playerspeed[2] = 0.0; }
					AddVectors(play, playerspeed, play);
					TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, play); 
				}
			}
			PrintToConsole(0, "entity DELETED: (id %d) GetEdictClassName: %s", edict, classname);
		}
		else if(StrEqual(classname, "obj_dispenser")) 
		{
			new maxplayers = GetMaxClients();
			new client;
			for(new i=0;i<maxplayers;i++)
			{
				if(dispenser[i] == edict){ client = i; }
			}
			new tclient = GetEntPropEnt(edict, Prop_Data, "m_hOwnerEntity");
			if(client == tclient && client != -1)
			{
			}
			else if(client != tclient && client == -1)
			{
				client = tclient;
			}
			else
			{
				client = tempClient;
				tempClient = 0;
			}
			new Float:radius = 256.0;
			new damage = 100;
			new Float:center[3];
			GetEntPropVector(edict, Prop_Send, "m_vecOrigin", center);
			ShowParticle(center, "ExplosionCore_MidAir", 2.0);
			EmitSoundToAll(SND_NADE_MIRV1, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
			new oteam;
			if (GetEntProp(edict, Prop_Data, "m_iTeamNum")==3) {oteam=2;} else {oteam=3;}
			FindPlayersInRange(center, radius, oteam, client, false, edict);
			new j;
			new String:TempString[32];
			IntToString(damage , TempString, 31);
			new Float:origin[3];
			new Float:distance;
			new Float:damageFloat;
			damageFloat = StringToFloat(TempString);
			new Float:dynamic_damage;
			for (j=1;j<=maxplayers;j++)
			{
				if(PlayersInRange[j]>0.0)
				{
					GetClientAbsOrigin(j, origin);
					SubtractVectors(origin, center, origin);
					distance = GetVectorLength(origin);
					if (distance<0.01) { distance = 0.01; }
					dynamic_damage = FloatSub(damageFloat, (FloatMul(FloatMul(damageFloat, 0.75), FloatDiv(distance, radius))));
					FloatToString(dynamic_damage, TempString, 31);
					damage = StringToInt(TempString);
					HurtPlayer(j, client, damage, "dispenser", true, center, 6.0);
				}
			}
			//new Float:first = GetEntPropFloat(edict, Prop_Data, "m_flDetonateTime");

			//PrintToServer("first = %f", first);

		}
		if(StrEqual(classname, "tf_projectile_pipe")) 
		{ 
			new Float:first = GetEntPropFloat(edict, Prop_Data, "m_flDetonateTime");
			PrintToServer("first = %f", first);
		}
	}
	
	return;
}

public Action:Command_ShowInfo(client, args)
{
	if(GetConVarInt(cvForcedShowInfo)==0)
	{
		if(args>0) 
		{
			decl String:arg[8];
			GetCmdArg(1, arg, sizeof(arg));
			for(new i=0;i<strlen(arg);i++) 
			{
				if(!IsCharNumeric(arg[i])) 
				{
					ReplyToCommand(client, "Value must be an integer.");
					return Plugin_Handled;
				}
			}
			if(StringToInt(arg)<0 || StringToInt(arg)>4) {
				ReplyToCommand(client, "Value must be from 0 to 5.");
				return Plugin_Handled;
			}
			showClientInfo[client]=StringToInt(arg);
		}
	}
	else
	{
		ReplyToCommand(client, "forced showinfo is on, only the current mode is available");
	}
	return Plugin_Handled;
}

public Action:Timer_ShowInfo(Handle:timer) 
{
	for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) 
		{
			if(GetConVarInt(cvShowInfo)==1 || GetConVarInt(cvForcedShowInfo) > 0)
			{
				if(showClientInfo[i]==1 || GetConVarInt(cvForcedShowInfo)==1)
				{
					SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);
					ShowSyncHudText(i, HudMessage, "Health: %d, Grenades: %d, %d", GetClientHealth(i), gRemaining1[i], gRemaining2[i]);
				}
				else if(showClientInfo[i]==2 || GetConVarInt(cvForcedShowInfo)==2)
				{
					SetHudTextParams(0.04, 0.57, 1.0, 255, 50, 50, 255);
					ShowSyncHudText(i, HudMessage, "Grenades: %d, %d", gRemaining1[i], gRemaining2[i]);
				}
				else if(showClientInfo[i]==3 || GetConVarInt(cvForcedShowInfo)==3)
				{
					SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);
					ShowSyncHudText(i, HudMessage, "Health: %d", GetClientHealth(i));
				}
				else if(showClientInfo[i]==4 || GetConVarInt(cvForcedShowInfo)==4)
				{
					SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);
					ShowSyncHudText(i, HudMessage, "Grenades: %d, %d", gRemaining1[i], gRemaining2[i]);
					
					new String:tempString[32];
					new ln = 0;
					ln += Format(tempString[ln], 32-ln, "||");
					if(isInfected[i])
					{
						ln += Format(tempString[ln], 32-ln, "I|");
					}
					if(gDrugged[i])
					{
						ln += Format(tempString[ln], 32-ln, "D|");
					}
					if(speedDebuff[i] > 1.0)
					{
						ln += Format(tempString[ln], 32-ln, "S|");
					}
					ln += Format(tempString[ln], 32-ln, "|");
					SetHudTextParams(0.04, 0.42, 1.0, 50, 255, 50, 255);
					ShowSyncHudText(i, HudStatus, "%s", tempString);
				}
				else if(showClientInfo[i]==5 || GetConVarInt(cvForcedShowInfo)==5)
				{
					SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);
					ShowSyncHudText(i, HudMessage, "Grenades: %d, %d", gRemaining1[i], gRemaining2[i]);
					
					new String:tempString[32];
					new ln = 0;
					ln += Format(tempString[ln], 32-ln, "||");
					if(isInfected[i])
					{
						ln += Format(tempString[ln], 32-ln, "I|");
					}
					if(gDrugged[i])
					{
						ln += Format(tempString[ln], 32-ln, "D|");
					}
					if(speedDebuff[i] > 1.0)
					{
						ln += Format(tempString[ln], 32-ln, "S|");
					}
					ln += Format(tempString[ln], 32-ln, "|");
					SetHudTextParams(0.04, 0.42, 1.0, 50, 255, 50, 255);
					ShowSyncHudText(i, HudStatus, "%s", tempString);
					
					SetHudTextParams(0.04, 0.47, 1.0, 255, 255, 50, 255);
					ShowSyncHudText(i, HudArmor, "Armor: %d", armor[i]);
				}
			}			
		}
	}
	return Plugin_Continue;
}

public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
    if (g_hTimer != INVALID_HANDLE) 
	{
        KillTimer(g_hTimer);
    }
    
    g_hTimer          = CreateTimer(GetConVarInt(g_hInterval) * 0.1, Timer_ShowInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Cvar_AirAccel(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	SetConVarInt(accel, GetConVarInt(cvAirAccel), true);
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new client, bool:spec;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	gRemaining1[client] = 0;
	gRemaining2[client] = 0;
	armor[client] = 0;
	if(gHolding[client] != HOLD_NONE)
	{
		new Float:loc[3]; GetClientAbsOrigin(client, loc);
		//new class = int:TF2_GetPlayerClass(client);
		if(gHolding[client] == HOLD_FRAG){ spec = false; }
		if(gHolding[client] == HOLD_SPECIAL){ spec = true; }
		ThrowNade(client, spec, false, true);
		gHolding[client] = HOLD_NONE;
	}
	
	new weaponid = GetEventInt(event, "weaponid");
	
	/*
	PrintToServer("userid %d", GetEventInt(event, "userid"));
	PrintToServer("attacker %d", GetEventInt(event, "attacker"));
	GetEventString(event, "weapon", tName, sizeof(tName));
	PrintToServer("weapon %s", tName);
	PrintToServer("weaponid %d", GetEventInt(event, "weaponid"));
	PrintToServer("damagebits %d", GetEventInt(event, "damagebits"));
	PrintToServer("dominated %d", GetEventInt(event, "dominated"));
	PrintToServer("assister_dominated %d", GetEventInt(event, "assister_dominated"));
	PrintToServer("revenge %d", GetEventInt(event, "revenge"));
	PrintToServer("assister_revenge %d", GetEventInt(event, "assister_revenge"));
	GetEventString(event, "weapon_logclassname", tName, sizeof(tName));
	PrintToServer("weapon_logclassname %s", tName);
	*/
	
	if (gKilledBy[client]>0 && weaponid==0)
	{
		if ( (GetEngineTime()-gKillTime[client]) < 0.5)
		{
			SetEventInt(event, "attacker", gKilledBy[client]);
			SetEventInt(event, "weaponid", 100);
			SetEventString(event, "weapon", gKillWeapon[client]);
			SetEventString(event, "weapon_logclassname", gKillWeapon[client]);
		}
	}
	
	// kill hooks
	gKilledBy[client]=0;
	gKillTime[client] = 0.0;
	gKillWeapon[client][0]='\0';
	SetEntityRenderColor(client, 255, 255, 255, 255);
	isInfected[client] = false;
	infectHits[client] = 0.0;
	speedDebuff[client] = 1.0;
	if(infectionTimer[client] != INVALID_HANDLE)
	{ KillTimer(infectionTimer[client]); infectionTimer[client] = INVALID_HANDLE; }
	
	
	return Plugin_Continue;
}

public Action:ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new class = GetEventInt(event, "class");
	gRemaining1[client] = 0;
	gRemaining2[client] = 0;
	gHolding[client] = HOLD_NONE;	
}

public Action:Command_SelfBeep(client, args) 
{
	if(beepOn[client])
	{
		beepOn[client] = false;
	}
	else
	{
		beepOn[client] = true;
	}
	return Plugin_Handled;
}

public Action:Command_Nade1(client, args) 
{
	if (gHolding[client]>HOLD_NONE)
	{
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client) || IsFakeClient(client) || IsClientObserver(client))
	{
		return Plugin_Handled;
	}
	
	SetupHudMsg(3.0);
	if (!gCanRun)
	{
		ShowHudText(client, 1, "no nade throwing yet");
		return Plugin_Handled;
	}
	if(throwTime[client])
	{
		return Plugin_Handled;
	}
	// not while cloaked or taunting
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond&16 || cond&128)
	{
		return Plugin_Handled;
	}
	if(gNadesUsed[client] < 6){
		if(gRemaining1[client]>0)
		{
			ThrowNade(client, false, true);
			if(GetConVarInt(cvRefill)==0)
			{
				gRemaining1[client]-=1;
			}
			if(showClientInfo[client] == 0 || GetConVarInt(cvForcedShowInfo) == 0)
			{
				ShowHudText(client, 1, "%d normal nades, %d special nades", gRemaining1[client], gRemaining2[client]);
			}
			gNadesUsed[client]++;
			throwTime[client] = true;
			CreateTimer(0.5, throwTimer, client);
		}
		else
		{
			if(showClientInfo[client] == 0 || GetConVarInt(cvForcedShowInfo)==0)
			{
				ShowHudText(client, 1, "no nades remaining");
			}
		}
	}
	else
	{
		ShowHudText(client, 1, "Stop spamming you fuckwit!!");
	}
	return Plugin_Handled;
}

public Action:Command_UnNade1(client, args)
{
	if (gHolding[client]!=HOLD_FRAG)
	{
		return Plugin_Handled;
	}
		
	ThrowNade(client, false, false);
	
	return Plugin_Handled;
}

public Action:Command_Nade2(client, args) 
{
	if (gHolding[client]>HOLD_NONE)
	{
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client) || IsFakeClient(client) || IsClientObserver(client))
	{
		return Plugin_Handled;
	}
	
	SetupHudMsg(3.0);
	if (!gCanRun)
	{
		ShowHudText(client, 1, "no nade throwing yet");
		return Plugin_Handled;
	}
	
	if(throwTime[client])
	{
		return Plugin_Handled;
	}
	// not while cloaked or taunting
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond&16 || cond&128)
	{
		return Plugin_Handled;
	}
	if(gNadesUsed[client] < 6){
		if(gRemaining2[client]>0)
		{
			ThrowNade(client, true, true);
			if(GetConVarInt(cvRefill)==0)
			{
				gRemaining2[client]-=1;
			}
			if(showClientInfo[client] == 0 || GetConVarInt(cvForcedShowInfo) == 0)
			{
				ShowHudText(client, 1, "%d normal nades, %d special nades", gRemaining1[client], gRemaining2[client]);
			}
			gNadesUsed[client]++;
			throwTime[client] = true;
			CreateTimer(0.5, throwTimer, client);
		}
		else
		{
			if(showClientInfo[client] == 0 || GetConVarInt(cvForcedShowInfo) == 0)
			{
				ShowHudText(client, 1, "no nades remaining");
			}
		}
	}
	else
	{
		ShowHudText(client, 1, "Stop spamming you fuckwit!");
	}
	return Plugin_Handled;
}

public Action:Command_UnNade2(client, args)
{
	if (gHolding[client]!=HOLD_SPECIAL)
	{
		return Plugin_Handled;
	}
	ThrowNade(client, true, false);

	return Plugin_Handled;
}

public Action:Command_fov(client, args) 
{
	if(GetConVarInt(g_fovEnabled) == 1) {
		if(args>0) {
			new String:arg[32];
			GetCmdArg(1, arg, sizeof(arg));
			for(new i=0;i<strlen(arg);i++) {
				if(!IsCharNumeric(arg[i])) {
					ReplyToCommand(client, "Value must be an integer.");
					return Plugin_Handled;
				}
			}
			if(StringToInt(arg)<=0 || StringToInt(arg)>GetConVarInt(cvFovMax)) {
				ReplyToCommand(client, "Value must be between 1 and %i.", GetConVarInt(cvFovMax));
				return Plugin_Handled;
			}
			
			fov[client] = StringToInt(arg);
			SetEntData(client, offsFOV, fov[client], 4, true);
			SetEntData(client, offsDefaultFOV, fov[client], 4, true);
			ReplyToCommand(client, "FOV set to %i.", fov[client]);
		} else {
			ReplyToCommand(client, "FOV: %i", fov[client]);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_Say(client, args)
{
	new String:text[192];
	GetCmdArgString(text, sizeof(text));
 
	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}
	if (StrEqual(text[startidx], "/refill"))
	{
		Command_RefillNades(client, args);
		return Plugin_Handled;
	} 
	else if (StrEqual(text[startidx], "/info"))
	{
		PrintToChat(client, "for nades, bind keys to +nade1 and +nade2");
		PrintToChat(client, "for fov tf2c_fov ##, for nadesleft tf2c_showinfo #");
		/* Block the client's messsage from broadcasting */
		return Plugin_Handled;
	}
	/* Let say continue normally */
	return Plugin_Continue;
}

/*public Action:Command_Special(client, args)
{
	PrintToServer("+special pressed");
}*/

/*public Action:Command_unSpecial(client, args)
{
	PrintToServer("-special pressed");
}*/

public Action:Command_RefillNades(client, args)
{
	if(GetConVarFloat(cvRefill) == 1)
	{
		new class = int:TF2_GetPlayerClass(client);
		gRemaining1[client] = GetConVarInt(cvFragNum[class][1]);
		gRemaining2[client] = GetNumNades(class, 1);
		SetupHudMsg(3.0);
		ShowHudText(client, 1, "%d normal nades, %d special nades", gRemaining1[client], gRemaining2[client]);
	}
	return Plugin_Handled;
}

/*public Action:Command_ThrowAmmo(client, args)
{
	if(GetConVarInt(cvThrowAmmo) == 1) 
	{
		if(args>0) 
		{
			new String:arg[32];
			GetCmdArg(1, arg, sizeof(arg));
			for(new i=0;i<strlen(arg);i++) 
			{
				if(!IsCharNumeric(arg[i])) 
				{
					ReplyToCommand(client, "Value must be an integer.");
					return Plugin_Handled;
				}
			}
			new percent = StringToInt(arg);
			if(percent<=25 || percent>100) 
			{
				ReplyToCommand(client, "Value must be between 25 and 100.");
				return Plugin_Handled;
			}
			m_Offset=FindSendPropOffs("CTFPlayer","m_iAmmo");
			
			new TFClassType:iClass = TF2_GetPlayerClass(client);
			//new String:weaponName[32]; GetClientWeapon(client, weaponName, 31);
			//new entvalue = 0;
			new curAmmo, maxAmmo, ammoDropped, percentage[3];
			for (new i = 1; i < 3; i++)
			{
				curAmmo = GetEntData(client, ammoOffset + (i * 4), 4);
				if(curAmmo > 0)
				{
					maxAmmo = TFClass_MaxAmmo[class][i];
					ammoDropped = (maxAmmo*percent)/100;
					if(curAmmo > ammoDropped)
					{
						SetEntData(client, ammoOffset + (i * 4), curAmmo - ammoDropped);
						percentage[i] = percent;
					}
					else
					{
						SetEntData(client, ammoOffset + (i * 4), 0);
						percentage[i] =  (curAmmo/ammoDropped)*percent;
					}
				}
				else
				{
					percentage[i] = 0;
				}
			}
			percent = (percentage[0] + percentage[1] + percentage[2]) / 3;
			if(percent > 0)
			{
				MakeBag(client, percent);
			}
			//ReplyToCommand(client, "FOV set to %i.", fov[client]);
		} 
		else 
		{
			//ReplyToCommand(client, "no value", fov[client]);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}*/

public GiveNadesorHealth(client, type, size)
{
	new class = int:TF2_GetPlayerClass(client);
	/*
	max prim nades = GetConVarInt(cvFragNum[class])
	max sec nades = GetNumNades(class)
	cur prim nades = gRemaining1[client]
	cur sec nades = gRemaining2[client]
	*/
	//nades
	if(type == 0)
	{
		if(size==3)
		{
			if(gRemaining1[client] < GetConVarInt(cvFragNum[class][0]))
			{
				gRemaining1[client] = GetConVarInt(cvFragNum[class][0]);
			}
			if(gRemaining2[client] < GetNumNades(class, 0))
			{
				gRemaining2[client] = GetNumNades(class, 0);
			}
			
			if(GetConVarInt(cvArmor)==1)
			{
				new mode = GetConVarInt(cvStartArmor);
				if(armor[client] < GetArmorAmounts(class, mode))
				{
					if(mode > 0)
					{
						armor[client] = GetArmorAmounts(class, mode);
					}
				}
			}
		}
		else if(size==2)
		{
		
			if(gRemaining1[client] < GetConVarInt(cvFragNum[class][1]) - 1)
			{
				gRemaining1[client] += 2;
			}
			else if(gRemaining1[client] < GetConVarInt(cvFragNum[class][1]))
			{
				gRemaining1[client] += 1;
				if(gRemaining2[client] < GetNumNades(class, 1))
				{
				gRemaining2[client] += 1;
				}
			}
			if(gRemaining2[client] < GetNumNades(class, 1) - 1)
			{
				gRemaining2[client] += 2;
			}
			else if(gRemaining2[client] < GetNumNades(class, 1))
			{
				gRemaining2[client] += 1;
				if(gRemaining1[client] < GetConVarInt(cvFragNum[class][1]))
				{
					gRemaining1[client] += 1;
				}
			}
			if(GetConVarInt(cvArmor)==1)
			{
				if(armor[client] + GetArmorAmounts(class, 2) < GetArmorAmounts(class, 3))
				{
					armor[client] += GetArmorAmounts(class, 2);
				}
				else
				{
					armor[client] = GetArmorAmounts(class, 3);
				}
			}
		}
		else if(size==1)
		{
			if(gRemaining1[client] < GetConVarInt(cvFragNum[class][1]))
			{
				gRemaining1[client]++;
			}
			else if(gRemaining2[client] < GetNumNades(class, 1))
			{
				gRemaining2[client]++;
			}
			if(gRemaining2[client] < GetNumNades(class, 1))
			{
				gRemaining2[client]++;
			}
			else if(gRemaining1[client] < GetConVarInt(cvFragNum[class][1]))
			{
				gRemaining1[client]++;
			}
			
			if(GetConVarInt(cvArmor)==1)
			{
				if(armor[client] + GetArmorAmounts(class, 1) < GetArmorAmounts(class, 3))
				{
					armor[client] += GetArmorAmounts(class, 1);
				}
				else
				{
					armor[client] = GetArmorAmounts(class, 3);
				}
			}
		}
		else if(size==0)
		{
			if(gRemaining1[client] < GetConVarInt(cvFragNum[class][1]) - 1)
			{
				gRemaining1[client] += 2;
			}
			else if(gRemaining1[client] < GetConVarInt(cvFragNum[class][1]))
			{
				gRemaining1[client]++;
			}
			
			if(GetConVarInt(cvArmor)==1)
			{
				if(armor[client] + (GetArmorAmounts(class, 3)/10) < GetArmorAmounts(class, 3))
				{
					armor[client] += (GetArmorAmounts(class, 3)/10);
				}
				else
				{
					armor[client] = GetArmorAmounts(class, 3);
				}
			}
		}
		if(showClientInfo[client] == 0 && GetConVarInt(cvForcedShowInfo) == 0)
		{
			SetupHudMsg(3.0);
			ShowHudText(client, 1, "%d normal nades, %d special nades", gRemaining1[client], gRemaining2[client]);
		}
	}
}

GetNade(client)
{
	// spawn the nade entity if required

	new bool:makenade = false;
	new bool:temp = true;
	new i;
	i = -1;
	while(temp)
	{
		i++;
		if (gNade[client][i]>0 && IsValidEntity(gNade[client][i]))
		{
			GetEntPropString(gNade[client][i], Prop_Data, "m_iName", tName, sizeof(tName));
			if (strncmp(tName,"tf2nade",7)!=0)
			{
				makenade=true;
				temp=false;
			}
		}
		else
		{ 
			makenade = true;
			temp=false;
		}
	}	
	
	if (makenade)
	{
		gNade[client][i] = CreateEntityByName("prop_physics");
		if (IsValidEntity(gNade[client][i]))
		{
			SetEntPropEnt(gNade[client][i], Prop_Data, "m_hOwnerEntity", client);
			SetEntityModel(gNade[client][i], gnModel);
			SetEntityMoveType(gNade[client][i], MOVETYPE_VPHYSICS);
			SetEntProp(gNade[client][i], Prop_Data, "m_CollisionGroup", 1);
			SetEntProp(gNade[client][i], Prop_Data, "m_usSolidFlags", 16);

			DispatchSpawn(gNade[client][i]);
			Format(tName, sizeof(tName), "tf2nade%d", gNade[client][i]);
			DispatchKeyValue(gNade[client][i], "targetname", tName);
			AcceptEntityInput(gNade[client][i], "DisableDamageForces");
			//SetEntPropString(gNade[client][i], Prop_Data, "m_iName", "tf2nade%d", gNade[client][i]);
			TeleportEntity(gNade[client][i], gHoldingArea, NULL_VECTOR, NULL_VECTOR);
		}
	}
	gNadeNumber[client]=i;
	return gNade[client][i];
}

ThrowNade(client, bool:special=true, bool:Setup, bool:death=false)
{
	if (Setup)
	{
		// save priming status
		if (special)
		{
			gHolding[client]=HOLD_SPECIAL;
		}
		else
		{
			gHolding[client]=HOLD_FRAG;
		}
		
		// setup nade if it doesn't exist
		GetNade(client);


		// check that nade still exists in world
		if (IsValidEdict(gNade[client][gNadeNumber[client]]))
		{
			GetEntPropString(gNade[client][gNadeNumber[client]], Prop_Data, "m_iName", tName, sizeof(tName));
			if (strncmp(tName,"tf2nade",7)!=0)
			{
				LogError("tf2nade: player's nade name not found");
				return; 
			}
		}
		else
		{
			LogError("tf2nade: player's nade not found");
			return;
		}
	}
	
	// setup nade variables based on player class
	new class = int:TF2_GetPlayerClass(client);
	SetupNade(class, GetClientTeam(client), special ? 1 : 0);
	
	if (!Setup)
	{
		// reset priming status
		gHolding[client] = HOLD_NONE;
		gThrown[client][gNadeNumber[client]] = true;
		
		// get position and angles
		new Float:startpt[3];
		GetClientEyePosition(client, startpt);
		new Float:angle[3];
		new Float:speed[3];
		new Float:playerspeed[3];
		if(!death)
		{
			GetClientEyeAngles(client, angle);
			GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
			speed[2]+=0.2;
			speed[0]*=gnSpeed; speed[1]*=gnSpeed; speed[2]*=gnSpeed;
			if(GetConVarInt(cvNadesThrowPhysics)>0)
			{
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
				if(GetConVarInt(cvNadesThrowPhysics)==1)
				{
					for(new i=0;i<2;i++)
					{
						if(playerspeed[i] >= 0.0 && speed[i] < 0.0)
						{
							playerspeed[i] = 0.0;
						}
						else if(playerspeed[i] < 0.0 && speed[i] >= 0.0)
						{
							playerspeed[i] = 0.0;
						}
					}
					if(playerspeed[2] < 0.0 )
					{
						playerspeed[2] = 0.0;
					}
				}
				AddVectors(speed, playerspeed, speed);
				
			}
		}
	
		SetEntityModel( gNade[client][gNadeNumber[client]], gnModel);
		Format(gnSkin, sizeof(gnSkin), "%d", GetClientTeam(client)-2);
		DispatchKeyValue(gNade[client][gNadeNumber[client]], "skin", gnSkin);
		angle[0] = GetRandomFloat(-180.0, 180.0);
		angle[1] = GetRandomFloat(-180.0, 180.0);
		angle[2] = GetRandomFloat(-180.0, 180.0);
		if(!death)
		{
			TeleportEntity(gNade[client][gNadeNumber[client]], startpt, angle, speed);
		}
		else
		{
			TeleportEntity(gNade[client][gNadeNumber[client]], startpt, angle, NULL_VECTOR);
		}
		
		if (strlen(gnParticle)>0)
		{
			AttachParticle(gNade[client][gNadeNumber[client]], gnParticle, gnDelay);
		}
		if(GetConVarInt(cvNadeTrail)==1)
		{
			new color[4];
			if(GetClientTeam(client)==2) //red
			{
				if(special)
				{
					color = { 255, 255, 50, 255};
				}
				else
				{
					color = { 255, 50, 50, 255 };
				}
			}
			else if(GetClientTeam(client)==3)
			{
				if(special)
				{
					color = { 50, 255, 255, 255};
				}
				else
				{
					color = { 50, 50, 255, 255 };
				}
			}
			else
			{
				color = { 50, 255, 50, 255 };
			}
			ShowTrail(gNade[client][gNadeNumber[client]], color);
		}
		EmitSoundToAll(SND_THROWNADE, client);
	}
	
	if (Setup)
	{
		if(special)
		{	
			if(GetConVarInt(cvSoundEnabled) == 1)
			{
				switch (class)
				{
					case SCOUT:
					{
						
						EmitSoundToAll(SND_NADE_CONC_TIMER, client);
						
						new Handle:concpack;
						tempNumber[client][gNadeNumber[client]] = 0;
						gNadeTimer2[client][gNadeNumber[client]] = CreateDataTimer(1.0, soundTimer, concpack, TIMER_REPEAT);
						WritePackCell(concpack, gNadeNumber[client]);
						WritePackCell(concpack, client);
						WritePackCell(concpack, special ? 1 : 0);
					}
					case SOLDIER:
					{
						EmitSoundToAll(SND_NADE_NAIL_TIMER, client);
						
						new Handle:nailpack;
						tempNumber[client][gNadeNumber[client]] = 0;
						gNadeTimer2[client][gNadeNumber[client]] = CreateDataTimer(4.0, soundTimer, nailpack, TIMER_REPEAT);
						WritePackCell(nailpack, gNadeNumber[client]);
						WritePackCell(nailpack, client);
						WritePackCell(nailpack, special ? 1 : 0);
					}
					case PYRO:
					{
						EmitSoundToAll(SND_NADE_FIRE_TIMER, client);
						
						new Handle:napalmpack;
						tempNumber[client][gNadeNumber[client]] = 0;
						gNadeTimer2[client][gNadeNumber[client]] = CreateDataTimer(2.0, soundTimer, napalmpack, TIMER_REPEAT);
						WritePackCell(napalmpack, gNadeNumber[client]);
						WritePackCell(napalmpack, client);
						WritePackCell(napalmpack, special ? 1 : 0);
					}
					case DEMO:
					{
						
						EmitSoundToAll(SND_NADE_CONC_TIMER, client);
						
						//new Handle:beep;
						new Handle:mirvpack;
						tempNumber[client][gNadeNumber[client]] = 0;
						gNadeTimer2[client][gNadeNumber[client]] = CreateDataTimer(1.0, soundTimer, mirvpack, TIMER_REPEAT);
						WritePackCell(mirvpack, gNadeNumber[client]);
						WritePackCell(mirvpack, client);
						WritePackCell(mirvpack, special ? 1 : 0);
					}
					case MEDIC:
					{
					
						EmitSoundToAll(SND_NADE_HEALTH_TIMER, client);
						
						//new Handle:beep;
						new Handle:healthpack;
						tempNumber[client][gNadeNumber[client]] = 0;
						gNadeTimer2[client][gNadeNumber[client]] = CreateDataTimer(2.0, soundTimer, healthpack, TIMER_REPEAT);
						WritePackCell(healthpack, gNadeNumber[client]);
						WritePackCell(healthpack, client);
						WritePackCell(healthpack, special ? 1 : 0);
					}
					case HEAVY:
					{
						
						EmitSoundToAll(SND_NADE_CONC_TIMER, client);
						
						//new Handle:beep;
						new Handle:mirvpack;
						tempNumber[client][gNadeNumber[client]] = 0;
						gNadeTimer2[client][gNadeNumber[client]] = CreateDataTimer(1.0, soundTimer, mirvpack, TIMER_REPEAT);
						WritePackCell(mirvpack, gNadeNumber[client]);
						WritePackCell(mirvpack, client);
						WritePackCell(mirvpack, special ? 1 : 0);
					}
					case ENGIE:
					{
						EmitSoundToAll(SND_NADE_EMP_TIMER, client);
						new Handle:emppack;
						tempNumber[client][gNadeNumber[client]] = 0;
						CreateDataTimer(2.0, soundTimer, emppack);
						WritePackCell(emppack, gNadeNumber[client]);
						WritePackCell(emppack, client);
						WritePackCell(emppack, special ? 1 : 0);
					}
					case SPY:
					{
						EmitSoundToAll(SND_NADE_HALLUC_TIMER, client);
						
						//new Handle:beep;
						new Handle:hallucpack;
						tempNumber[client][gNadeNumber[client]] = 0;
						gNadeTimer2[client][gNadeNumber[client]] = CreateDataTimer(1.0, soundTimer, hallucpack, TIMER_REPEAT);
						WritePackCell(hallucpack, gNadeNumber[client]);
						WritePackCell(hallucpack, client);
						WritePackCell(hallucpack, special ? 1 : 0);
					}
				}
			}
		}
		else
		{
			if(GetConVarInt(cvSoundEnabled) == 1)
			{
				
				EmitSoundToAll(SND_NADE_CONC_TIMER, client);
				
				new Handle:fragpack;
				tempNumber[client][gNadeNumber[client]] = 0;
				gNadeTimer2[client][gNadeNumber[client]] = CreateDataTimer(1.0, soundTimer, fragpack, TIMER_REPEAT);
				WritePackCell(fragpack, gNadeNumber[client]);
				WritePackCell(fragpack, client);
				WritePackCell(fragpack, special ? 1 : 0);
			}
		}
		
		if(GetConVarInt(cvPlayerNadeBeep) == 1)
		{
			if(beepOn[client])
			{
				gNadeTimerBeep[client][gNadeNumber[client]] = INVALID_HANDLE;
				EmitSoundToClient(client, SND_NADE_CONC_TIMER);
				new Handle:beeppack;
				tempNumber2[client][gNadeNumber[client]] = 0;
				gNadeTimerBeep[client][gNadeNumber[client]] = CreateDataTimer(1.0, soundBeep, beeppack, TIMER_REPEAT);
				WritePackCell(beeppack, gNadeNumber[client]);
				WritePackCell(beeppack, client);
			}
		}
		
		new Handle:pack;
		gNadeTimer[client][gNadeNumber[client]] = CreateDataTimer(gnDelay, NadeExplode, pack);
		WritePackCell(pack, gNadeNumber[client]);
		WritePackCell(pack, client);
		WritePackCell(pack, GetClientTeam(client));
		WritePackCell(pack, class);
		WritePackCell(pack, special ? 1 : 0);
	}
}

/*MakeBag(client, percent)
{
	new amount = percent;
	new Float:vecStart[3], Float:vecAng[3];
	GetClientEyePosition(client, vecStart);
	GetClientEyeAngles(client, vecAng);
	vecStart[0] += 32.0*Cosine(0.0174532925*vecAng[1]);
	vecStart[1] += 32.0*Sine(0.0174532925*vecAng[1]);
	new Float:playerspeed[3];
	new Float:velocity[3], Float:ang[3], Float:ang2[3];
	GetClientEyeAngles(client, ang);
	ang2[0] = ang[0];
	ang2[1] = ang[1];
	ang2[2] = ang[2];
	ang[0] *= -1.0;
	ang[0] = DegToRad(ang[0]);
	ang[1] = DegToRad(ang[1]);
	velocity[0] = 400.0*Cosine(ang[0])*Cosine(ang[1]);
	velocity[1] = 400.0*Cosine(ang[0])*Sine(ang[1]);
	velocity[2] = 400.0*Sine(ang[0]);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
	AddVectors(velocity, playerspeed, velocity);
	new ent = CreateEntityByName("prop_physics_override");
	if(IsValidEntity(ent)) {
		SetEntityModel(ent, "");
		SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
		SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
		//SetEntProp(ent, Prop_Data, "m_usSolidFlags", 16);
		//SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
		DispatchSpawn(ent);
		TeleportEntity(flag, vecStart, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(ent, vecStart, NULL_VECTOR, velocity);
		new String:tName[64];
		Format(tName, sizeof(tName), "TFlag%d", ent);
		DispatchKeyValue(ent, "targetname", tName);
		DispatchKeyValue(ent, "disableshadows", "1");
		SetVariantString(tName);
		AcceptEntityInput(flag, "SetParent");
		AcceptEntityInput(ent, "DisableDamageForces");
		SetEntityRenderMode(ent, RENDER_ENVIRONMENTAL);
		dhHookEntity(ent, EHK_VPhysicsUpdate, ThinkHook);
	}
}*/

public Action:throwTimer(Handle:timer, any:client)
{
	throwTime[client] = false;
}

public Action:soundTimer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new j = ReadPackCell(pack);
	new client = ReadPackCell(pack);
	new special = ReadPackCell(pack);
	playSound(j, client, special);
	
	return Plugin_Continue;
}

playSound(j, client, type)
{
	if(IsValidEntity(gNade[client][j]) && IsValidEntity(client))
	{
		new class = int:TF2_GetPlayerClass(client);
		new Float:center[3];
		GetEntPropVector(gNade[client][j], Prop_Send, "m_vecOrigin", center);
		new bool:special;
		if(type==1){ special = true; } else { special = false; }
		if(tempNumber[client][j] < (gnDelay-1))
		{
			if (gHolding[client]>HOLD_NONE && gThrown[client][j]==false)
			{
				if(special)
				{
					switch (class)
					{
						case SCOUT:
						{
							EmitSoundToAll(SND_NADE_CONC_TIMER, client);
						}
						case SOLDIER:
						{
							EmitSoundToAll(SND_NADE_NAIL_TIMER, client);
						}
						case PYRO:
						{
							EmitSoundToAll(SND_NADE_FIRE_TIMER, client);
						}
						case DEMO:
						{
							EmitSoundToAll(SND_NADE_CONC_TIMER, client, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_CHANGEPITCH, SNDVOL_NORMAL, SNDPITCH_LOW, _, center, NULL_VECTOR, false, 0.0);
						}
						case HEAVY:
						{
							EmitSoundToAll(SND_NADE_CONC_TIMER, client, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_CHANGEPITCH, SNDVOL_NORMAL, SNDPITCH_LOW, _, center, NULL_VECTOR, false, 0.0);
						}
						case ENGIE:
						{
							EmitSoundToAll(SND_NADE_EMP_TIMER, client);
						}
						case MEDIC:
						{
							EmitSoundToAll(SND_NADE_HEALTH_TIMER, client);
						}
						case SPY:
						{
							EmitSoundToAll(SND_NADE_HALLUC_TIMER, client);
						}
					}
				}
				else
				{
					EmitSoundToAll(SND_NADE_CONC_TIMER, client);
				}
			}
			else
			{
				if(special)
				{
					switch (class)
					{
						case SCOUT:
						{
							EmitSoundToAll(SND_NADE_CONC_TIMER, gNade[client][j], SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, center, NULL_VECTOR, false, 0.0);
						}
						case SOLDIER:
						{
							EmitSoundToAll(SND_NADE_NAIL_TIMER, gNade[client][j], SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, center, NULL_VECTOR, false, 0.0);
						}
						case PYRO:
						{
							EmitSoundToAll(SND_NADE_FIRE_TIMER, gNade[client][j], SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, center, NULL_VECTOR, false, 0.0);
						}
						case DEMO:
						{
							EmitSoundToAll(SND_NADE_CONC_TIMER, gNade[client][j], SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_CHANGEPITCH, SNDVOL_NORMAL, SNDPITCH_LOW, _, center, NULL_VECTOR, false, 0.0);
						}
						case HEAVY:
						{
							EmitSoundToAll(SND_NADE_CONC_TIMER, gNade[client][j], SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_CHANGEPITCH, SNDVOL_NORMAL, SNDPITCH_LOW, _, center, NULL_VECTOR, false, 0.0);
						}
						case ENGIE:
						{
							EmitSoundToAll(SND_NADE_EMP_TIMER, gNade[client][j], SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, center, NULL_VECTOR, false, 0.0);
						}
						case MEDIC:
						{
							EmitSoundToAll(SND_NADE_HEALTH_TIMER, gNade[client][j], SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, center, NULL_VECTOR, false, 0.0);
						}
						case SPY:
						{
							EmitSoundToAll(SND_NADE_HALLUC_TIMER, gNade[client][j], SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, center, NULL_VECTOR, false, 0.0);
						}
					}
				}
				else
				{
					EmitSoundToAll(SND_NADE_CONC_TIMER, gNade[client][j], SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, center, NULL_VECTOR, false, 0.0);
				}
			}
			tempNumber[client][j]++;
		}
		else
		{
			tempNumber[client][j] = 0;
		}
	}
}
	
public Action:soundBeep(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new j = ReadPackCell(pack);
	new client = ReadPackCell(pack);
	new Float:center[3];
	GetEntPropVector(gNade[client][j], Prop_Send, "m_vecOrigin", center);
	if(tempNumber2[client][j] < 2)
	{
		EmitSoundToClient(client, SND_NADE_CONC_TIMER);
		tempNumber2[client][j]++;
	}
	else
	{
		tempNumber2[client][j] = 0;
		//return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:NadeExplode(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new j = ReadPackCell(pack);
	new client = ReadPackCell(pack);
	new team = ReadPackCell(pack);
	new class = ReadPackCell(pack);
	new special = ReadPackCell(pack);
	
	if (IsValidEdict(gNade[client][j]))
	{
		GetEntPropString(gNade[client][j], Prop_Data, "m_iName", tName, sizeof(tName));
		if (strncmp(tName,"tf2nade",7)==0)
		{
			gNadesUsed[client]--;
			ExplodeNade(client, team, class, special, j);
		} 
	}
}

ExplodeNade(client, team, class, special, jTemp)
{
 
	new bool:tempBool = false;
	if (gHolding[client]>HOLD_NONE && gThrown[client][jTemp]==false)
	{
		
		tempBool = true; 
		ThrowNade(client, gHolding[client]==HOLD_SPECIAL ? true : false, false);
	}
	gThrown[client][jTemp] = false; 
	gNadeTimer[client][jTemp] = INVALID_HANDLE;
	if(GetConVarInt(cvPlayerNadeBeep) == 1)
	{
		if(beepOn[client])
		{
			if(gNadeTimerBeep[client][jTemp] != INVALID_HANDLE)
			{
				KillTimer(gNadeTimerBeep[client][jTemp]);
				gNadeTimerBeep[client][jTemp] = INVALID_HANDLE;
			}
		}
	}
	new Float:radius;
	if (special==0)
	{
		if(class != MEDIC)
		{
			// effects
			if(gNadeTimer2[client][jTemp] != INVALID_HANDLE)
			{ KillTimer(gNadeTimer2[client][jTemp]); gNadeTimer2[client][jTemp] = INVALID_HANDLE; }
			new Float:center[3];
			GetEntPropVector(gNade[client][jTemp], Prop_Send, "m_vecOrigin", center);
			ShowParticle(center, "ExplosionCore_MidAir", 2.0);
			EmitSoundToAll(SND_NADE_FRAG, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
			// player damage
			radius = GetConVarFloat(cvFragRadius);
			new damage = GetConVarInt(cvFragDamage);
			new oteam;
			if (GetClientTeam(client)==3) {oteam=2;} else {oteam=3;}
			FindPlayersInRange(center, radius, oteam, client, true, gNade[client][jTemp]);
			new j;
			new String:TempString[32];
			new Float:damageFloat;
			IntToString(damage , TempString, 31);
			damageFloat = StringToFloat(TempString);
			new Float:origin[3];
			new Float:distance;
			
			new Float:playerspeed[3];
			
			new Float:dynamic_damage;
			new maxplayers = GetMaxClients();
			for (j=1;j<=maxplayers;j++)
			{
				if(PlayersInRange[j]>0.0)
				{
					GetClientAbsOrigin(j, origin);
					SubtractVectors(origin, center, origin);
					distance = GetVectorLength(origin);
					if (distance<0.01) { distance = 0.01; }
					dynamic_damage = FloatSub(damageFloat, (FloatMul(FloatMul(damageFloat, 0.75), FloatDiv(distance, radius))));
					FloatToString(dynamic_damage, TempString, 31);
					damage = StringToInt(TempString);
					if(tempBool && j==client)
					{
						GetEntPropVector(j, Prop_Data, "m_vecVelocity", playerspeed);
						new Float:temp = dynamic_damage/50.0;
						if(temp < GetConVarFloat(cvNadeHHMin)){ temp = GetConVarFloat(cvNadeHHMin); }
						
						if(GetVectorLength(playerspeed)<500.0 && GetVectorLength(playerspeed)>200.0)
						{ 
							temp = temp + (0.25 * (1.0 * (300.0/GetVectorLength(playerspeed))));
							ScaleVector(playerspeed, temp);
							TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, playerspeed);
						}
						else
						{
							ScaleVector(playerspeed, temp); 
							TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, playerspeed);
						}
					}
					HurtPlayer(j, client, damage, "tf2nade_frag", true, center, 4.0);
				}
			}
			DamageBuildings(client, center, radius, damage, gNade[client][jTemp], true);
		}
		else
		{
			if(gNadeTimer2[client][jTemp] != INVALID_HANDLE)
			{ KillTimer(gNadeTimer2[client][jTemp]); gNadeTimer2[client][jTemp] = INVALID_HANDLE; }
			radius = GetConVarFloat(cvConcRadius);
			new damage = GetConVarInt(cvConcDamage);
			new Float:center[3];
			GetEntPropVector(gNade[client][jTemp], Prop_Send, "m_vecOrigin", center);
			ShowParticle(center, "impact_generic_smoke", 2.0);
			//PrintToServer("client %d", client);
			new beamcolor[4] = { 255, 255, 255, 255 };
			new Float:beamcenter[3]; beamcenter = center;
			new Float:height = (radius/2.0)/GetConVarFloat(cvConcRings);
			for(new f=0;f<GetConVarInt(cvConcRings);f++)
			{
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				beamcenter[2] += height;
			}
			EmitSoundToAll(SND_NADE_CONC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
			new oteam;
			if (team==3) {oteam=2;} else {oteam=3;}
			if(GetConVarInt(cvConcIgnore) == 1)
			{
				FindPlayersInRange(center, radius, oteam, client, false, -1);
			}
			else
			{
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client][jTemp]);
			}
			new j;
			new Float:play[3];
			new Float:playerspeed[3];
			new Float:distance;
			new maxplayers = GetMaxClients();
			for (j=1;j<=maxplayers;j++)
			{
				if(PlayersInRange[j]>0.0)
				{
					GetClientAbsOrigin(j, play);
					play[2]+=64.0;
					SubtractVectors(play, center, play);
					distance = GetVectorLength(play);
					if (distance<GetConVarFloat(cvBlastDistanceMin)*radius) { distance = GetConVarFloat(cvBlastDistanceMin)*radius; }
					new String:TempString[32];
					FloatToString(FloatDiv(distance, radius), TempString, 32);
					if(GetConVarInt(cvShowDistance) == 1){PrintCenterText(j,"%s", TempString);}
					ScaleVector(play, FloatDiv(distance, radius));
					ScaleVector(play, GetConVarFloat(cvConcForce));
					GetEntPropVector(j, Prop_Data, "m_vecVelocity", playerspeed);
					if(playerspeed[2]<0.0) { playerspeed[2] = 0.0; }
					if(tempBool && j==client) 
					{ 
						if(GetVectorLength(playerspeed)<500.0 && GetVectorLength(playerspeed)>300.0)
						{ 
							new Float:temp = GetConVarFloat(cvHHincrement);
							temp = temp + (0.25 * (1.0 * (320.0/GetVectorLength(playerspeed))));
							ScaleVector(playerspeed, temp); //1300
						}
						else
						{
							ScaleVector(playerspeed, GetConVarFloat(cvHHincrement)); 
						}
					}
					AddVectors(play, playerspeed, play);
					TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, play);
					HurtPlayer(j, client, damage, "tf2nade_conc", true, center, 20.0, 1); 
				}
			}
		}
	}
	else
	{
		switch (class)
		{
			case SCOUT:
			{
				if(gNadeTimer2[client][jTemp] != INVALID_HANDLE)
				{ KillTimer(gNadeTimer2[client][jTemp]); gNadeTimer2[client][jTemp] = INVALID_HANDLE; }
				radius = GetConVarFloat(cvConcRadius);
				new damage = GetConVarInt(cvConcDamage);
				new Float:center[3];
				GetEntPropVector(gNade[client][jTemp], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "impact_generic_smoke", 2.0);
				//PrintToServer("client %d", client);
				new beamcolor[4] = { 255, 255, 255, 255 };
				new Float:beamcenter[3]; beamcenter = center;
				new Float:height = (radius/2.0)/GetConVarFloat(cvConcRings);
				for(new f=0;f<GetConVarInt(cvConcRings);f++)
				{
					TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
					TE_SendToAll(0.0);
					beamcenter[2] += height;
				}
				
				/*
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				beamcenter[2] += 12.0;
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				beamcenter[2] += 12.0;
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				beamcenter[2] += 12.0;
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				beamcenter[2] += 12.0;
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				beamcenter[2] += 12.0;
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				beamcenter[2] += 12.0;
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				beamcenter[2] += 12.0;
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				*/
				EmitSoundToAll(SND_NADE_CONC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				if(GetConVarInt(cvConcIgnore) == 1)
				{
					FindPlayersInRange(center, radius, oteam, client, false, -1);
				}
				else
				{
					FindPlayersInRange(center, radius, oteam, client, true, gNade[client][jTemp]);
				}
				new j;
				new Float:play[3];
				new Float:playerspeed[3];
				new Float:distance;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						GetClientAbsOrigin(j, play);
						play[2]+=64.0;
						SubtractVectors(play, center, play);
						distance = GetVectorLength(play);
						if (distance<GetConVarFloat(cvBlastDistanceMin)*radius) { distance = GetConVarFloat(cvBlastDistanceMin)*radius; }
						new String:TempString[32];
						FloatToString(FloatDiv(distance, radius), TempString, 32);
						if(GetConVarInt(cvShowDistance) == 1){PrintCenterText(j,"%s", TempString);}
						ScaleVector(play, FloatDiv(distance, radius));
						ScaleVector(play, GetConVarFloat(cvConcForce));
						GetEntPropVector(j, Prop_Data, "m_vecVelocity", playerspeed);
						if(playerspeed[2]<0.0) { playerspeed[2] = 0.0; }
						if(tempBool && j==client) 
						{ 
							if(GetVectorLength(playerspeed)<600.0 && GetVectorLength(playerspeed)>375.0)
							{ 
								new Float:temp = GetConVarFloat(cvHHincrement);
								temp = temp + (0.25 * (1.0 * (400.0/GetVectorLength(playerspeed))));
								ScaleVector(playerspeed, temp); //1300
							}
							else
							{
								ScaleVector(playerspeed, GetConVarFloat(cvHHincrement)); 
							}
						}
						AddVectors(play, playerspeed, play);
						TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, play);
						HurtPlayer(j, client, damage, "tf2nade_conc", true, center, 20.0, 1); 
					}
				}
			}
			case SNIPER:
			{
				
			}
			case SOLDIER:
			{
				if(gNadeTimer2[client][jTemp] != INVALID_HANDLE)
				{ KillTimer(gNadeTimer2[client][jTemp]); gNadeTimer2[client][jTemp] = INVALID_HANDLE; }
				SetupNade(SOLDIER, GetClientTeam(client), 1);
				radius = GetConVarFloat(cvNailRadius);
				new Float:center[3];
				GetEntPropVector(gNade[client][jTemp], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "Explosions_MA_Dustup_2", 2.0);
				center[2]+=32.0;
				new Float:angles[3] = {0.0,0.0,0.0};
				new gNadeTemp;
				gNadeTemp = CreateEntityByName("prop_dynamic_override");
				if (IsValidEntity(gNadeTemp))
				{
					SetEntPropEnt(gNadeTemp, Prop_Data, "m_hOwnerEntity", client);
					SetEntityModel(gNadeTemp,gnModel);
					SetEntProp(gNadeTemp, Prop_Data, "m_CollisionGroup", 1);
					SetEntProp(gNadeTemp, Prop_Data, "m_usSolidFlags", 16);
					Format(gnSkin, sizeof(gnSkin), "%d", GetClientTeam(client)-2);
					DispatchKeyValue(gNadeTemp, "skin", gnSkin);
					Format(tName, sizeof(tName), "tf2nailnade%d", gNadeTemp);
					DispatchKeyValue(gNadeTemp, "targetname", tName);
					DispatchSpawn(gNadeTemp);
					TeleportEntity(gNadeTemp, center, angles, NULL_VECTOR);
					SetVariantString("release");
					AcceptEntityInput(gNadeTemp, "SetAnimation");
					EmitSoundToAll(SND_NADE_NAIL, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
					new Handle:pack;
					new Handle:pack2;
					gNailTimer[client][nailNade[client]] = INVALID_HANDLE;
					gNailTimer[client][nailNade[client]] = CreateDataTimer(0.25, SoldierNadeThink, pack2, TIMER_REPEAT);
					WritePackCell(pack2, client);
					WritePackCell(pack2, gNadeTemp);
					CreateDataTimer(5.0, SoldierNadeFinish, pack); 
					WritePackCell(pack, client);
					WritePackCell(pack, nailNade[client]);
					WritePackCell(pack, gNadeTemp);
					if(nailNade[client] >= 9)
					{ 
						nailNade[client] = 0; 
					} 
					else
					{
						nailNade[client]++;
					}
					
					
				}
			}
			case DEMO:
			{
				if(gNadeTimer2[client][jTemp] != INVALID_HANDLE)
				{ KillTimer(gNadeTimer2[client][jTemp]); gNadeTimer2[client][jTemp] = INVALID_HANDLE; }
				radius = GetConVarFloat(cvMirvRadius);
				new damage = GetConVarInt(cvMirvDamage1);
				new Float:center[3];
				GetEntPropVector(gNade[client][jTemp], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);
				EmitSoundToAll(SND_NADE_MIRV1, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client][jTemp]);
				new j;
				new maxplayers = GetMaxClients();
				new String:TempString[32];
				IntToString(damage , TempString, 31);
				new Float:origin[3];
				new Float:distance;
				new Float:damageFloat;
				new Float:playerspeed[3];
				damageFloat = StringToFloat(TempString);
				new Float:dynamic_damage;
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						GetClientAbsOrigin(j, origin);
						SubtractVectors(origin, center, origin);
						distance = GetVectorLength(origin);
						if (distance<0.01) { distance = 0.01; }
						dynamic_damage = FloatSub(damageFloat, (FloatMul(FloatMul(damageFloat, 0.75), FloatDiv(distance, radius))));
						FloatToString(dynamic_damage, TempString, 31);
						damage = StringToInt(TempString);
						if(tempBool && j==client)
						{
							GetEntPropVector(j, Prop_Data, "m_vecVelocity", playerspeed);
							new Float:temp = dynamic_damage/50.0;
							if(temp < GetConVarFloat(cvNadeHHMin)){ temp = GetConVarFloat(cvNadeHHMin); }
							
							if(GetVectorLength(playerspeed)<500.0 && GetVectorLength(playerspeed)>200.0)
							{ 
								temp = temp + (0.25 * (1.0 * (300.0/GetVectorLength(playerspeed))));
								ScaleVector(playerspeed, temp);
								TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, playerspeed);
							}
							else
							{
								ScaleVector(playerspeed, temp); 
								TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, playerspeed);
							}
						}
						HurtPlayer(j, client, damage, "tf2nade_mirv", true, center, 5.0);
					}
				}
				DamageBuildings(client, center, radius, damage, gNade[client][jTemp], true);
				new Float:spread;
				new Float:vel[3], Float:angle[3], Float:rand;
				Format(gnSkin, sizeof(gnSkin), "%d", GetClientTeam(client)-2);
				new ent[MIRV_PARTS];
				new k;
				for (k=0;k<MIRV_PARTS;k++)
				{
					ent[k] = CreateEntityByName("prop_physics");
					if (IsValidEntity(ent[k]))
					{
						SetEntPropEnt(ent[k], Prop_Data, "m_hOwnerEntity", client);
						SetEntityModel(ent[k],MDL_MIRV2);
						SetEntityMoveType(ent[k], MOVETYPE_VPHYSICS);
						SetEntProp(ent[k], Prop_Data, "m_CollisionGroup", 1);
						SetEntProp(ent[k], Prop_Data, "m_usSolidFlags", 16);
						DispatchKeyValue(ent[k], "skin", gnSkin);
						DispatchSpawn(ent[k]);
						Format(tName, sizeof(tName), "tf2mirv%d", ent[k]);
						DispatchKeyValue(ent[k], "targetname", tName);
						AcceptEntityInput(ent[k], "DisableDamageForces");
						rand = GetRandomFloat(0.0, 314.0);
						spread = GetConVarFloat(cvMirvSpread) * GetRandomFloat(0.2, 1.0);
						vel[0] = spread*Sine(rand);
						vel[1] = spread*Cosine(rand);
						vel[2] = spread;
						GetVectorAngles(vel, angle);
						TeleportEntity(ent[k], center, angle, vel);
					}
				}
				
				
				new Handle:pack;
				//gNadeTimer3[client][jTemp] = INVALID_HANDLE;
				//gNadeTimer3[client][jTemp] = 
				CreateDataTimer(gnDelay, MirvExplode2, pack);
				WritePackCell(pack, jTemp);
				WritePackCell(pack, client);
				WritePackCell(pack, team);
				WritePackCell(pack, 0);
				for (k=0;k<MIRV_PARTS;k++)
				{
					WritePackCell(pack, ent[k]);
				}
			}
			case MEDIC:
			{
				if(gNadeTimer2[client][jTemp] != INVALID_HANDLE)
				{ KillTimer(gNadeTimer2[client][jTemp]); gNadeTimer2[client][jTemp] = INVALID_HANDLE; }
				radius = GetConVarFloat(cvHealthRadius);
				new Float:beamcenter[3];
				new beamcolor[4];
				if (team==2)
				{
					beamcolor[0]=255; beamcolor[1]=0; beamcolor[2]=0; beamcolor[3]=255;
				}
				else
				{
					beamcolor[0]=0; beamcolor[1]=0; beamcolor[2]=255; beamcolor[3]=255;
				}
				GetEntPropVector(gNade[client][jTemp], Prop_Send, "m_vecOrigin", beamcenter);
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.25,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.50,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.75,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				EmitSoundToAll(SND_NADE_HEALTH, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, beamcenter, NULL_VECTOR, false, 0.0);
				FindPlayersInRange(beamcenter, radius, team, client, true, gNade[client][jTemp]);
				new j;
				//new health;
				new maxplayers = GetMaxClients();
				new playersOnRegen[32];
				new tNr = 0;
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						playersOnRegen[tNr] = j;
						tNr++;
						
						ShowHealthParticle(j);
						//health = GetEntProp(j, Prop_Data, "m_iMaxHealth");
						//if (GetClientHealth(j)<health)
						//{
						//	SetEntityHealth(j, health);
						//}
					}
				}
				new Handle:pack;
				CreateDataTimer(1.0/24.0, HealthExplode, pack);
				WritePackCell(pack, tNr);
				WritePackCell(pack, GetConVarInt(cvHealNadePower));
				for(new k=0;k<tNr;k++)
				{
					WritePackCell(pack, playersOnRegen[k]);
				}
			}
			case HEAVY:
			{
				if(gNadeTimer2[client][jTemp] != INVALID_HANDLE)
				{ KillTimer(gNadeTimer2[client][jTemp]); gNadeTimer2[client][jTemp] = INVALID_HANDLE; }
				radius = GetConVarFloat(cvMirvRadius);
				new damage = GetConVarInt(cvMirvDamage1);
				new Float:center[3];
				GetEntPropVector(gNade[client][jTemp], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);
				EmitSoundToAll(SND_NADE_MIRV1, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client][jTemp]);
				new j;
				new maxplayers = GetMaxClients();
				new String:TempString[32];
				IntToString(damage , TempString, 31);
				new Float:origin[3];
				new Float:distance;
				new Float:damageFloat;
				new Float:playerspeed[3];
				damageFloat = StringToFloat(TempString);
				new Float:dynamic_damage;
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						GetClientAbsOrigin(j, origin);
						SubtractVectors(origin, center, origin);
						distance = GetVectorLength(origin);
						if (distance<0.01) { distance = 0.01; }
						dynamic_damage = FloatSub(damageFloat, (FloatMul(FloatMul(damageFloat, 0.75), FloatDiv(distance, radius))));
						FloatToString(dynamic_damage, TempString, 31);
						damage = StringToInt(TempString);
						if(tempBool && j==client)
						{
							GetEntPropVector(j, Prop_Data, "m_vecVelocity", playerspeed);
							new Float:temp = dynamic_damage/50.0;
							if(temp < GetConVarFloat(cvNadeHHMin)){ temp = GetConVarFloat(cvNadeHHMin); }
							
							if(GetVectorLength(playerspeed)<500.0 && GetVectorLength(playerspeed)>200.0)
							{ 
								temp = temp + (0.25 * (1.0 * (300.0/GetVectorLength(playerspeed))));
								ScaleVector(playerspeed, temp);
								TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, playerspeed);
							}
							else
							{
								ScaleVector(playerspeed, temp); 
								TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, playerspeed);
							}
						}
						HurtPlayer(j, client, damage, "tf2nade_mirv", true, center, 5.0);
					}
				}
				DamageBuildings(client, center, radius, damage, gNade[client][jTemp], true);
				new Float:spread;
				new Float:vel[3], Float:angle[3], Float:rand;
				Format(gnSkin, sizeof(gnSkin), "%d", GetClientTeam(client)-2);
				new ent[MIRV_PARTS];
				new k;
				for (k=0;k<MIRV_PARTS;k++)
				{
					ent[k] = CreateEntityByName("prop_physics");
					if (IsValidEntity(ent[k]))
					{
						SetEntPropEnt(ent[k], Prop_Data, "m_hOwnerEntity", client);
						SetEntityModel(ent[k],MDL_MIRV2);
						SetEntityMoveType(ent[k], MOVETYPE_VPHYSICS);
						SetEntProp(ent[k], Prop_Data, "m_CollisionGroup", 1);
						SetEntProp(ent[k], Prop_Data, "m_usSolidFlags", 16);
						DispatchKeyValue(ent[k], "skin", gnSkin);
						DispatchSpawn(ent[k]);
						Format(tName, sizeof(tName), "tf2mirv%d", ent[k]);
						DispatchKeyValue(ent[k], "targetname", tName);
						AcceptEntityInput(ent[k], "DisableDamageForces");
						rand = GetRandomFloat(0.0, 314.0);
						spread = GetConVarFloat(cvMirvSpread) * GetRandomFloat(0.2, 1.0);
						vel[0] = spread*Sine(rand);
						vel[1] = spread*Cosine(rand);
						vel[2] = spread;
						GetVectorAngles(vel, angle);
						TeleportEntity(ent[k], center, angle, vel);
					}
				}
				
				
				new Handle:pack;
				//gNadeTimer3[client][jTemp] = INVALID_HANDLE;
				//gNadeTimer3[client][jTemp] = 
				CreateDataTimer(gnDelay, MirvExplode2, pack);
				WritePackCell(pack, jTemp);
				WritePackCell(pack, client);
				WritePackCell(pack, team);
				WritePackCell(pack, 0);
				for (k=0;k<MIRV_PARTS;k++)
				{
					WritePackCell(pack, ent[k]);
				}

			}
			case PYRO:
			{
				if(gNadeTimer2[client][jTemp] != INVALID_HANDLE)
				{ KillTimer(gNadeTimer2[client][jTemp]); gNadeTimer2[client][jTemp] = INVALID_HANDLE; }
				radius = GetConVarFloat(cvNapalmRadius);
				new damage = GetConVarInt(cvNapalmDamage);
				new Float:center[3];
				GetEntPropVector(gNade[client][jTemp], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);
				TE_SetupExplosion(center, gNapalmSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
				TE_SendToAll();
				EmitSoundToAll(SND_NADE_NAPALM, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client][jTemp]);
				new j;
				new maxplayers = GetMaxClients();
				new String:TempString[32];
				IntToString(damage , TempString, 31);
				new Float:origin[3];
				new Float:distance;
				new Float:damageFloat;
				new Float:playerspeed[3];
				damageFloat = StringToFloat(TempString);
				new Float:dynamic_damage;
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						new health = GetClientHealth(j);
						if (damage>=health)
						{
							HurtPlayer(j, client, health-1, "tf2nade_napalm", true, center, 3.0);
						}
						else
						{
							GetClientAbsOrigin(j, origin);
							SubtractVectors(origin, center, origin);
							distance = GetVectorLength(origin);
							if (distance<0.01) { distance = 0.01; }
							dynamic_damage = FloatSub(damageFloat, (FloatMul(FloatMul(damageFloat, 0.75), FloatDiv(distance, radius))));
							FloatToString(dynamic_damage, TempString, 31);
							damage = StringToInt(TempString);
							if(tempBool && j==client)
							{
								GetEntPropVector(j, Prop_Data, "m_vecVelocity", playerspeed);
								new Float:temp = dynamic_damage/50.0;
								if(temp < GetConVarFloat(cvNadeHHMin)){ temp = GetConVarFloat(cvNadeHHMin); }
								
								if(GetVectorLength(playerspeed)<500.0 && GetVectorLength(playerspeed)>200.0)
								{ 
									temp = temp + (0.25 * (1.0 * (300.0/GetVectorLength(playerspeed))));
									ScaleVector(playerspeed, temp);
									TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, playerspeed);
								}
								else
								{
									ScaleVector(playerspeed, temp); 
									TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, playerspeed);
								}
							}
							HurtPlayer(j, client, damage, "tf2nade_napalm", true, center, 3.0);
						}
						if(j != client)
						{
							TF2_IgnitePlayer(j, client);
						}
					}
				}
				DamageBuildings(client, center, radius, damage, gNade[client][jTemp], true);
			}
			case SPY:
			{
				if(gNadeTimer2[client][jTemp] != INVALID_HANDLE)
				{ KillTimer(gNadeTimer2[client][jTemp]); gNadeTimer2[client][jTemp] = INVALID_HANDLE; }
				radius = GetConVarFloat(cvHallucRadius);
				new damage = GetConVarInt(cvHallucDamage);
				new Float:center[3]; //Float:angles[3];
				GetEntPropVector(gNade[client][jTemp], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_sapperdestroyed", 2.0);
				EmitSoundToAll(SND_NADE_HALLUC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client][jTemp]);
				new j;
				new maxplayers = GetMaxClients();
				new Float:hDelay = GetConVarFloat(cvHallucDelay);
				new Float:origin[3];
				new Float:distance;
				new Float:dynamic_time;
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{	
						if(!gDrugged[j]){
							g_DrugTimers[j] = CreateTimer(1.0, Timer_Drug, j, TIMER_REPEAT);
							gDrugged[j] = true;
							GetClientAbsOrigin(j, origin);
							SubtractVectors(origin, center, origin);
							distance = GetVectorLength(origin);
							if (distance<0.01) { distance = 0.01; }
							dynamic_time = FloatSub(hDelay, (FloatMul(FloatMul(hDelay, 0.60), FloatDiv(distance, radius))));
							CreateTimer(dynamic_time, ResetPlayerView, j);
						}
						HurtPlayer(j, client, damage, "tf2nade_halluc", false, NULL_VECTOR, 4.0, 1); 
					}
				}
			}
			case ENGIE:
			{
				if(gNadeTimer2[client][jTemp] != INVALID_HANDLE)
				{ KillTimer(gNadeTimer2[client][jTemp]); gNadeTimer2[client][jTemp] = INVALID_HANDLE; }
				radius = GetConVarFloat(cvEmpRadius);
				new Float:center[3];
				GetEntPropVector(gNade[client][jTemp], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_sapperdestroyed", 2.0);
				EmitSoundToAll(SND_NADE_EMP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				if(GetConVarInt(cvEmpIgnore) == 1)
				{
					FindPlayersInRange(center, radius, oteam, client, false, -1);
				}
				else
				{
					FindPlayersInRange(center, radius, oteam, client, true, gNade[client][jTemp]);
				}
				new j;
				new beamcolor[4];
				if (team==2)
				{
					beamcolor[0]=255;beamcolor[1]=0;beamcolor[2]=0;beamcolor[3]=255;
				}
				else
				{
					beamcolor[0]=0;beamcolor[1]=0;beamcolor[2]=255;beamcolor[3]=255;
				}
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 0.5, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 0.75, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 1.0, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();
				new maxplayers = GetMaxClients();
				new m_Offset;
				new ammoLost = 0;
				new ammoLostScale = 0;
				new damage = 0;
				m_Offset=FindSendPropOffs("CTFPlayer","m_iAmmo"); //Find the offset 
				for (j=1;j<=maxplayers;j++)
				{
					if(j!=client)
					{
						if(PlayersInRange[j]>0.0)
						{
							TF2_RemovePlayerDisguise(j);
							new TFClassType:iClass = TF2_GetPlayerClass(j);
							new String:weaponName[32]; GetClientWeapon(j, weaponName, 31);
							new entvalue = 0;
							if(StrContains(weaponName, "n_scattergun") != -1 || StrContains(weaponName, "n_rocketlauncher") != -1 || StrContains(weaponName, "n_flamethrower") != -1 || StrContains(weaponName, "n_grenadelauncher") != -1 || StrContains(weaponName, "n_minigun") != -1 || StrContains(weaponName, "n_shotgun_primary") != -1 || StrContains(weaponName, "n_syringegun_medic") != -1 || StrContains(weaponName, "n_sniperrifle") != -1 || StrContains(weaponName, "n_revolver") != -1)
							{
								entvalue=GetEntData(j,m_Offset+4,4);
								//PrintToServer("m_offset = \"%i\")", entvalue); //Print the value to the HLDS console
								if(entvalue > 0)
								{
									ammoLost = entvalue/4;
									ammoLostScale = ammoLost*400/TFClass_MaxAmmo[iClass][0];
									entvalue=(entvalue/4) * 3;
									//PrintToServer("ammoAmount = \"%i\")", entvalue); //Print the value to the HLDS console
									//PrintToServer("ammoLost = \"%i\")", ammoLost); //Print the value to the HLDS console
									SetEntData(j, m_Offset+((0+1)*4), entvalue, 4, true); //Set the value of m_iAmmo to -25% of what it was
								}
							}
							else if(StrContains(weaponName, "n_pistol_scout") != -1 || StrContains(weaponName, "n_shotgun_soldier") != -1 || StrContains(weaponName, "n_shotgun_pyro") != -1 || StrContains(weaponName, "n_pipebomblauncher") != -1 || StrContains(weaponName, "n_shotgun_hwg") != -1 || StrContains(weaponName, "n_pistol") != -1 || StrContains(weaponName, "n_smg") != -1 || StrContains(weaponName, "n_flaregun") != -1)
							{
								entvalue=GetEntData(j,m_Offset+8,4);
								//PrintToServer("m_offset = \"%i\")", entvalue); //Print the value to the HLDS console
								if(entvalue > 0)
								{
									ammoLost = entvalue/4;
									ammoLostScale = ammoLost*200/TFClass_MaxAmmo[iClass][1];
									entvalue=(entvalue/4) * 3;
									//PrintToServer("ammoAmount = \"%i\")", entvalue); //Print the value to the HLDS console
									//PrintToServer("ammoLost = \"%i\")", ammoLost); //Print the value to the HLDS console
									SetEntData(j, m_Offset+((1+1)*4), entvalue, 4, true); //Set the value of m_iAmmo to -25% of what it was
								}
							}									
							if(ammoLost > 0)
							{
								
								damage = (ammoLost * 2) + ammoLostScale;
								if(damage < 10){ damage = 10; }
								if(damage > 200){ damage = 200; }
								HurtPlayer(j, client, damage, "tf2nade_EMP", true, center, 2.0);
								if(GetConVarInt(cvEmpExplosion)==1)
								{
									new Float:tcenter[3];
									GetEntPropVector(j, Prop_Send, "m_vecOrigin", tcenter);
									ShowParticle(tcenter, "ExplosionCore_MidAir", 2.0);
								}
							}				
						}
					}
				}
				new i;
				radius = radius * radius;
				new Float:orig[3], Float:distance;
				for (i=GetMaxClients()+1; i<GetMaxEntities(); i++)
				{
					if (IsValidEntity(i))
					{
						GetEdictClassname(i, tName, sizeof(tName));
						if (StrContains(tName, "tf_projectile_")>-1 || StrContains(tName, "tf2nade_")>-1)
						{
							GetEntPropVector(i, Prop_Send, "m_vecOrigin", orig);
							orig[0]-=center[0];
							orig[1]-=center[1];
							orig[2]-=center[2];
							orig[0]*=orig[0];
							orig[1]*=orig[1];
							orig[2]*=orig[2];
							distance = orig[0]+orig[1]+orig[2];
							if (distance<radius)
							{
								RemoveEdict(i);
							}
						}
					}
				}
			}
			default:
			{
				
			}
		}
	}
	TeleportEntity(gNade[client][jTemp], gHoldingArea, NULL_VECTOR, NULL_VECTOR);
	RemoveEdict(gNade[client][jTemp]);
	gNade[client][jTemp] = 0;
}

SetupNade(class, team, special)
{
	// setup frag nade if not special
	new Float:tSpeed = GetConVarFloat(cvNadesThrowSpeed);
	if (special==0)
	{
		if(class != MEDIC)
		{
			strcopy(gnModel, sizeof(gnModel), MDL_FRAG);
			gnSpeed = tSpeed;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		else
		{
			strcopy(gnModel, sizeof(gnModel), MDL_CONC);
			gnSpeed = tSpeed;
			gnDelay = GetConVarFloat(cvConcDelay);
			strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
		}
		return;
	}
	
	// setup special nade if not frag
	switch (class)
	{
		case SCOUT:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_CONC);
			gnSpeed = tSpeed;
			gnDelay = GetConVarFloat(cvConcDelay);
			strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
			
		}
		case SNIPER:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_MIRV2);
			gnSpeed = tSpeed;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case SOLDIER:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_NAIL);
			gnSpeed = tSpeed;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case DEMO:
		{
			//SetupNade(ENGIE, team, special);
			strcopy(gnModel, sizeof(gnModel), MDL_MIRV1);
			gnSpeed = tSpeed;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case MEDIC:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_HEALTH);
			gnSpeed = tSpeed;
			gnDelay = GetConVarFloat(cvHealthDelay);
			if (team==2)
			{
				strcopy(gnParticle, sizeof(gnParticle), "player_recent_teleport_red");
			}
			else
			{
				strcopy(gnParticle, sizeof(gnParticle), "player_recent_teleport_blue");
			}
			
		}
		case HEAVY:
		{
			//SetupNade(ENGIE, team, special);
			strcopy(gnModel, sizeof(gnModel), MDL_MIRV1);
			gnSpeed = tSpeed;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case PYRO:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_NAPALM);
			gnSpeed = tSpeed;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case SPY:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_HALLUC);
			gnSpeed = tSpeed;
			gnDelay = 3.0;
			strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
		}
		case ENGIE:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_EMP);
			gnSpeed = tSpeed;
			gnDelay = GetConVarFloat(cvEmpDelay);
			if (team==2)
			{
				strcopy(gnParticle, sizeof(gnParticle), "critgun_weaponmodel_red");
			}
			else
			{
				strcopy(gnParticle, sizeof(gnParticle), "critgun_weaponmodel_blu");
			}
		}
		default:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_FRAG);
			gnSpeed = tSpeed;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
	}
	
}

GetNumNades(class, type)
{
	switch (class)
	{
		case SCOUT:
		{
			if(type==0)
			{
				return GetConVarInt(cvConcNum[0]);
			}
			else
			{
				return GetConVarInt(cvConcNum[1]);
			}
			
			
		}
		case SNIPER:
		{
			return 0;
		}
		case SOLDIER:
		{
			if(type==0)
			{
				return GetConVarInt(cvNailNum[0]);
			}
			else
			{
				return GetConVarInt(cvNailNum[1]);
			}
			
			//return 0;
		}
		case DEMO:
		{
			if(type==0)
			{
				return GetConVarInt(cvMirvNum[0]);
			}
			else
			{
				return GetConVarInt(cvMirvNum[1]);
			}
			
		}
		case MEDIC:
		{
			if(type==0)
			{
				return GetConVarInt(cvHealthNum[0]);
			}
			else
			{
				return GetConVarInt(cvHealthNum[1]);
			}
			
		}
		case HEAVY:
		{
			if(type==0)
			{
				return GetConVarInt(cvMirvNum[2]);
			}
			else
			{
				return GetConVarInt(cvMirvNum[3]);
			}
			
			//return 0;
		}
		case PYRO:
		{
			if(type==0)
			{
				return GetConVarInt(cvNapalmNum[0]);
			}
			else
			{
				return GetConVarInt(cvNapalmNum[1]);
			}
			
		}
		case SPY:
		{
			if(type==0)
			{
				return GetConVarInt(cvHallucNum[0]);
			}
			else
			{
				return GetConVarInt(cvHallucNum[1]);
			}
			
		}
		case ENGIE:
		{
			if(type==0)
			{
				return GetConVarInt(cvEmpNum[0]);
			}
			else
			{
				return GetConVarInt(cvEmpNum[1]);
			}
			
		}
		default:
		{
			return 0;
		}
	}
	
	return 0;
	
}

GetArmorAmounts(class, type)
{
	switch (class)
	{
		case SCOUT:
		{
			if(type==1)
			{
				return GetConVarInt(cvArmorAmounts[0][1])/4;
			}
			else if(type==2)
			{
				return GetConVarInt(cvArmorAmounts[0][1])/2;
			}
			else if(type==3)
			{
				return GetConVarInt(cvArmorAmounts[0][1]);
			}			
		}
		case SNIPER:
		{
			if(type==1)
			{
				return GetConVarInt(cvArmorAmounts[0][1])/4;
			}
			else if(type==2)
			{
				return GetConVarInt(cvArmorAmounts[0][1])/2;
			}
			else if(type==3)
			{
				return GetConVarInt(cvArmorAmounts[0][1]);
			}
		}
		case SOLDIER:
		{
			if(type==1)
			{
				return GetConVarInt(cvArmorAmounts[2][1])/4;
			}
			else if(type==2)
			{
				return GetConVarInt(cvArmorAmounts[2][1])/2;
			}
			else if(type==3)
			{
				return GetConVarInt(cvArmorAmounts[2][1]);
			}
		}
		case DEMO:
		{
			if(type==1)
			{
				return GetConVarInt(cvArmorAmounts[1][1])/4;
			}
			else if(type==2)
			{
				return GetConVarInt(cvArmorAmounts[1][1])/2;
			}
			else if(type==3)
			{
				return GetConVarInt(cvArmorAmounts[1][1]);
			}
		}
		case MEDIC:
		{
			if(type==1)
			{
				return GetConVarInt(cvArmorAmounts[1][1])/4;
			}
			else if(type==2)
			{
				return GetConVarInt(cvArmorAmounts[1][1])/2;
			}
			else if(type==3)
			{
				return GetConVarInt(cvArmorAmounts[1][1]);
			}
		}
		case HEAVY:
		{
			if(type==1)
			{
				return GetConVarInt(cvArmorAmounts[2][1])/4;
			}
			else if(type==2)
			{
				return GetConVarInt(cvArmorAmounts[2][1])/2;
			}
			else if(type==3)
			{
				return GetConVarInt(cvArmorAmounts[2][1]);
			}
		}
		case PYRO:
		{
			if(type==1)
			{
				return GetConVarInt(cvArmorAmounts[1][1])/4;
			}
			else if(type==2)
			{
				return GetConVarInt(cvArmorAmounts[1][1])/2;
			}
			else if(type==3)
			{
				return GetConVarInt(cvArmorAmounts[1][1]);
			}
		}
		case SPY:
		{
			if(type==1)
			{
				return GetConVarInt(cvArmorAmounts[0][1])/4;
			}
			else if(type==2)
			{
				return GetConVarInt(cvArmorAmounts[0][1])/2;
			}
			else if(type==3)
			{
				return GetConVarInt(cvArmorAmounts[0][1]);
			}
		}
		case ENGIE:
		{
			if(type==1)
			{
				return GetConVarInt(cvArmorAmounts[1][1])/4;
			}
			else if(type==2)
			{
				return GetConVarInt(cvArmorAmounts[1][1])/2;
			}
			else if(type==3)
			{
				return GetConVarInt(cvArmorAmounts[1][1]);
			}
		}
		default:
		{
			return 0;
		}
	}
	return 0;
}

public Action:SoldierNadeThink(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new gNadeTemp = ReadPackCell(pack);

	if (IsValidEntity(gNadeTemp))
	{
		// effects
		new Float:center[3];
		GetEntPropVector(gNadeTemp, Prop_Send, "m_vecOrigin", center);
		new rand = GetRandomInt(1, 3);
		switch (rand)
		{
			case 1:
			{
				Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT1);
			}
			case 2:
			{
				Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT2);
			}
			default:
			{
				Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT3);
			}
			
		}
		EmitSoundToAll(tName, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
		new Float:dir[3];
		dir[0] = GetRandomFloat(-1.0, 1.0);
		dir[1] = GetRandomFloat(-1.0, 1.0);
		dir[2] = GetRandomFloat(-1.0, 1.0);
		TE_SetupMetalSparks(center, dir);
		TE_SendToAll();
		
		// player damage
		new oteam;
		if (GetClientTeam(client)==3) {oteam=2;} else {oteam=3;}
		FindPlayersInRange(center, GetConVarFloat(cvNailRadius), oteam, client, true, gNadeTemp);
		new j;
		new maxplayers = GetMaxClients();
		for (j=1;j<=maxplayers;j++)
		{
			if(PlayersInRange[j]>0.0)
			{
				HurtPlayer(j, client, GetConVarInt(cvNailDamageNail), "tf2nade_nail", false, center, 4.0, 1);
			}
		}			
	}
	return Plugin_Continue;
}

public Action:SoldierNadeFinish(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new jTemp = ReadPackCell(pack);
	new gNadeTemp = ReadPackCell(pack);
	
	
	KillTimer(gNailTimer[client][jTemp]);
	gNailTimer[client][jTemp] = INVALID_HANDLE;
	
	StopSound(gNadeTemp, SNDCHAN_WEAPON, SND_NADE_NAIL);
	if (IsValidEntity(gNadeTemp))
	{
		new damage = GetConVarInt(cvNailDamageExplode);
		GetEntPropString(gNadeTemp, Prop_Data, "m_iName", tName, sizeof(tName));
		if (strncmp(tName,"tf2nailnade",11)==0)
		{
			// effects
			new Float:center[3];
			new Float:radius = GetConVarFloat(cvNailRadius);
			GetEntPropVector(gNadeTemp, Prop_Send, "m_vecOrigin", center);
			ShowParticle(center, "ExplosionCore_MidAir", 2.0);
			EmitSoundToAll(SND_NADE_NAIL_EXPLODE, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
			// player damage
			new oteam;
			if (GetClientTeam(client)==3) {oteam=2;} else {oteam=3;}
			FindPlayersInRange(center, radius, oteam, client, true, gNadeTemp);
			new j;
			new maxplayers = GetMaxClients();
			new String:TempString[32];
			IntToString(damage , TempString, 31);
			new Float:origin[3];
			new Float:distance;
			new Float:damageFloat;
			damageFloat = StringToFloat(TempString);
			new Float:dynamic_damage;
			for (j=1;j<=maxplayers;j++)
			{
				if(PlayersInRange[j]>0.0)
				{
					GetClientAbsOrigin(j, origin);
					SubtractVectors(origin, center, origin);
					distance = GetVectorLength(origin);
					if (distance<0.01) { distance = 0.01; }
					dynamic_damage = FloatSub(damageFloat, (FloatMul(FloatMul(damageFloat, 0.75), FloatDiv(distance, radius))));
					FloatToString(dynamic_damage, TempString, 31);
					damage = StringToInt(TempString);
					HurtPlayer(j, client, damage, "tf2nade_nail", true, center);
				}
			}
			DamageBuildings(client, center, radius, damage, gNadeTemp, true);
			RemoveEdict(gNadeTemp);
		}
	}
}

public Action:MirvExplode2(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new jTemp = ReadPackCell(pack);
	new client = ReadPackCell(pack);
	new team = ReadPackCell(pack);
	new min = ReadPackCell(pack);
	new ent[MIRV_PARTS-min];
	new k;
	for (k=0;k<MIRV_PARTS-min;k++)
	{
		ent[k] = ReadPackCell(pack);
	}
	//gNadeTimer3[client][jTemp] = INVALID_HANDLE;
	new Float:radius = GetConVarFloat(cvMirvRadius);
	new Float:center[3];
	
	GetEntPropString(ent[0], Prop_Data, "m_iName", tName, sizeof(tName));
	if (strncmp(tName,"tf2mirv",7)==0)
	{
		new damage = GetConVarInt(cvMirvDamage2);
		GetEntPropVector(ent[0], Prop_Send, "m_vecOrigin", center);
		ShowParticle(center, "ExplosionCore_MidAir", 2.0);
		EmitSoundToAll(SND_NADE_MIRV2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
		new oteam;
		if (team==3) {oteam=2;} else {oteam=3;}
		FindPlayersInRange(center, radius, oteam, client, true, ent[0]);
		new j;
		new maxplayers = GetMaxClients();
		for (j=1;j<=maxplayers;j++)
		{
			if(PlayersInRange[j]>0.0)
			{
				HurtPlayer(j, client, damage, "tf2nade_mirv", true, center);
			}
		}
		DamageBuildings(client, center, radius, damage, ent[0], true);
		RemoveEdict(ent[0]);
		
		if(min < MIRV_PARTS)
		{		
			CreateDataTimer(0.01, MirvExplode2, pack);
			WritePackCell(pack, jTemp);
			WritePackCell(pack, client);
			WritePackCell(pack, team);
			WritePackCell(pack, min+1);
			for (k=0;k<MIRV_PARTS-min;k++)
			{
				WritePackCell(pack, ent[k+1]);
			}
		}
	}
	/*
	for (k=0;k<MIRV_PARTS;k++)
	{
		GetEntPropString(ent[k], Prop_Data, "m_iName", tName, sizeof(tName));
		if (strncmp(tName,"tf2mirv",7)==0)
		{
			new damage = GetConVarInt(cvMirvDamage2);
			GetEntPropVector(ent[k], Prop_Send, "m_vecOrigin", center);
			ShowParticle(center, "ExplosionCore_MidAir", 2.0);
			EmitSoundToAll(SND_NADE_MIRV2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
			new oteam;
			if (team==3) {oteam=2;} else {oteam=3;}
			FindPlayersInRange(center, radius, oteam, client, true, ent[k]);
			new j;
			new maxplayers = GetMaxClients();
			for (j=1;j<=maxplayers;j++)
			{
				if(PlayersInRange[j]>0.0)
				{
					HurtPlayer(j, client, damage, "tf2nade_mirv", true, center);
				}
			}
			DamageBuildings(client, center, radius, damage, ent[k], true);
			RemoveEdict(ent[k]);
		}
	}
	*/
}

public Action:HealthExplode(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new tNr = ReadPackCell(pack);
	new amountHP = ReadPackCell(pack);
	new playersOnRegen[tNr];
	for(new i=0;i<tNr;i++)
	{
		playersOnRegen[i] = ReadPackCell(pack);
	}
	new indiHP = amountHP / tNr;
	new tempHP = amountHP;
	if(indiHP > 1)
	{
		for(new i=0;i<tNr;i++)
		{
			if(IsValidEntity(playersOnRegen[i]) && IsClientInGame(playersOnRegen[i]) && IsPlayerAlive(playersOnRegen[i]))
			{
				new curHP = GetClientHealth(playersOnRegen[i]);
				new maxHP = GetEntProp(playersOnRegen[i], Prop_Data, "m_iMaxHealth");
				if(GetConVarInt(cvHealNadeOverheal)==0)
				{
					if (curHP<maxHP)
					{
						SetEntityHealth(playersOnRegen[i], curHP+1);
						tempHP--;
					}
				}
				else if(GetConVarInt(cvHealNadeOverheal)==1)
				{
					if(curHP<(maxHP*(3/2)))
					{
						SetEntityHealth(playersOnRegen[i], curHP+1);
						tempHP--;
					}
				}
			}
		}
		if(tempHP < amountHP)
		{
			new Handle:pack2;
			CreateDataTimer(1.0/24.0, HealthExplode, pack2);
			WritePackCell(pack2, tNr);
			WritePackCell(pack2, amountHP);
			for(new k=0;k<tNr;k++)
			{
				WritePackCell(pack2, playersOnRegen[k]);
			}
		}
	}
	
	//health = GetEntProp(j, Prop_Data, "m_iMaxHealth");
	//if (GetClientHealth(j)<health)
	//{
	//	SetEntityHealth(j, health);
	//}
}

public Action:ResetPlayerView(Handle:timer, any:client)
{
	KillTimer(g_DrugTimers[client]);
	g_DrugTimers[client] = INVALID_HANDLE;
	gDrugged[client] = false;
	
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	new Float:angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[1] = 0.0;
	angs[2] = 0.0;
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);	
	
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();	
}

public Action:Timer_Drug(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		KillTimer(g_DrugTimers[client]);
		g_DrugTimers[client] = INVALID_HANDLE;
		gDrugged[client] = false;

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		CreateTimer(0.01, ResetPlayerView, client);
		return Plugin_Handled;
	}
	
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	new Float:angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[0] += g_DrugAngles[GetRandomInt(0,100) % 20];
	angs[1] += g_DrugAngles[GetRandomInt(0,100) % 20];
	angs[2] += g_DrugAngles[GetRandomInt(0,100) % 20];
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);
	
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 255);
	BfWriteShort(message, 255);
	BfWriteShort(message, (0x0002));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, 128);
	
	EndMessage();	
		
	return Plugin_Handled;
}

public Action:InfectionTimer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new victim = ReadPackCell(pack);
	new attacker = ReadPackCell(pack);
	if(IsValidEntity(victim) && IsValidEntity(attacker))
	{
		new team = GetEntProp(attacker, Prop_Data, "m_iTeamNum");
		new oteam = GetEntProp(victim, Prop_Data, "m_iTeamNum");
		new String:tempParticle[256];
		//PrintToServer("team of attacker = %i", team);
		if (team==2)
		{
			strcopy(tempParticle, sizeof(tempParticle), "player_recent_teleport_red");
		}
		else
		{
			strcopy(tempParticle, sizeof(tempParticle), "player_recent_teleport_blue");
		}
		if(team == oteam && team == 2) { team = 3; } else if(team == oteam && team == 3) { team = 2; }
		new baseDamage = GetConVarInt(cvInfectBaseDamage);
		new Float:minHits = GetConVarFloat(cvInfectHits);
		if(infectHits[victim] >= (11.0*minHits)) //55
		{
			//new tempColor[4] = { 55, 255, 55, 255 };
			AttachParticle(victim, tempParticle, 2.0);
			SetEntityRenderColor(victim, 55, 255, 55, 255);
			InfectionSpread(victim, team, 640.0);
			HurtPlayer(victim, attacker, (baseDamage*5), "infection", false, NULL_VECTOR, 1.0, 1); 
			
			if( (infectHits[victim] == (16.0*minHits)) || (infectHits[victim] == (15.0*minHits)) || (infectHits[victim] == (14.0*minHits)) || (infectHits[victim] == (13.0*minHits)) || (infectHits[victim] == (12.0*minHits)) || (infectHits[victim] == (11.0*minHits)))
			{ 
				//PrintToServer("infection holding lvl6");
			}
			else
			{
				infectHits[victim]--; 
				//PrintToServer("infection weakening lvl6");		
			}
			
			
		}
		else if(infectHits[victim] >= (9.0*minHits)) //45
		{
			//new tempColor[4] = { 55, 230, 55, 255 };
			AttachParticle(victim, tempParticle, 2.0);
			SetEntityRenderColor(victim, 105, 255, 105, 255);
			InfectionSpread(victim, team, 576.0);
			HurtPlayer(victim, attacker, (baseDamage*4), "infection", false, NULL_VECTOR, 1.0, 1); 
			
			if( (infectHits[victim] == (10.0*minHits)) || (infectHits[victim] == (9.0*minHits)) )
			{ 
				//PrintToServer("infection holding lvl5");
			}
			else
			{
				infectHits[victim]--; 
				//PrintToServer("infection weakening lvl5");		
			}
			
			
		}
		else if( infectHits[victim] >= (7.0*minHits) ) //35
		{
			//new tempColor[4] = { 55, 205, 55, 255 };
			AttachParticle(victim, tempParticle, 2.0);
			SetEntityRenderColor(victim, 155, 255, 155, 255);
			InfectionSpread(victim, team, 512.0);
			HurtPlayer(victim, attacker, (baseDamage*3), "infection", false, NULL_VECTOR, 1.0, 1); 

			
			if((infectHits[victim] == (8.0*minHits)) || (infectHits[victim] == (7.0*minHits)) )
			{ 
				//PrintToServer("infection holding lvl4");
			}
			else
			{
				infectHits[victim]--; 
				//PrintToServer("infection weakening lvl4");		
			}
			
			
		}
		else if( infectHits[victim] >= (5.0*minHits) ) //25
		{
			//new tempColor[4] = { 55, 180, 55, 255 };
			AttachParticle(victim, tempParticle, 2.0);
			SetEntityRenderColor(victim, 180, 255, 180, 255);
			InfectionSpread(victim, team, 448.0);
			HurtPlayer(victim, attacker, (baseDamage*2), "infection", false, NULL_VECTOR, 1.0, 1); 
			
			
			if( (infectHits[victim] == (6.0*minHits)) || infectHits[victim] == (5.0*minHits) )
			{ 
				//PrintToServer("infection holding lvl 3");
			}
			else
			{
				infectHits[victim]--; 
				//PrintToServer("infection weakening lvl 3");
			}
		}
		else if( infectHits[victim] >= (3.0*minHits) ) //15
		{
			//new tempColor[4] = { 55, 155, 55, 255 };
			AttachParticle(victim, tempParticle, 2.0);
			SetEntityRenderColor(victim, 205, 255, 205, 255);
			InfectionSpread(victim, team, 384.0);
			HurtPlayer(victim, attacker, (baseDamage+(baseDamage/2)), "infection", false, NULL_VECTOR, 1.0, 1); 
			
			if( (infectHits[victim] == (4.0*minHits)) || (infectHits[victim] == (3.0*minHits)) )
			{ 
				//PrintToServer("infection holding lvl 2");
			}
			else
			{
				infectHits[victim]--; 
				//PrintToServer("infection weakening lvl 2");
			}
		}
		else if( infectHits[victim] >= minHits  ) //5
		{
			//new tempColor[4] = { 55, 130, 55, 255 };
			AttachParticle(victim, tempParticle, 2.0);
			SetEntityRenderColor(victim, 230, 255, 230, 255);
			InfectionSpread(victim, team, 320.0);
			HurtPlayer(victim, attacker, baseDamage, "infection", false, NULL_VECTOR, 1.0, 1); 
			
			if( (infectHits[victim] == (minHits*2.0)) || (infectHits[victim] == minHits) )
			{ 
				//PrintToServer("infection holding lvl 1");
			}
			else
			{
				infectHits[victim]--; 
				//PrintToServer("infection weakening lvl 1");
			}
		}
		
		//PrintToServer("player %i is infected with %i hits", victim, infectHits[victim]);
	}
	else
	{
		PrintToServer("a player was not valid, infection timer idle");
	}
	//Plugin_Continue;
}

InfectionSpread(client, clientteam, Float:radius)
{
	new Float:loc[3];
	GetClientAbsOrigin(client, loc);
	new oteam = 0;
	if(clientteam == 2){ oteam = 3; } else { oteam = 2; }

	FindPlayersInRange(loc, radius, oteam, client, true, -1);
	new maxplayers = GetMaxClients();
	for (new i=1;i<=maxplayers;i++)
	{
		if(PlayersInRange[i]>0.0 && i != client)
		{
			new Float:min, Float:max, Float:hits;
			min = GetConVarFloat(cvInfectDis[0])/2.0;
			max = GetConVarFloat(cvInfectDis[1]);
			new Float:pos[2][3], Float:dis;
			GetClientAbsOrigin(i, pos[0]);
			GetClientAbsOrigin(client, pos[1]);
			dis = GetVectorDistance(pos[0], pos[1]);
			if(dis <= max)
			{
				if(dis < min) { dis = min; }
				hits = 1.0 / (dis / min);
				infectHits[i] += hits;
				if(infectHits[i] >= 20.0*GetConVarFloat(cvInfectHits)){ infectHits[i] = 20.0*GetConVarFloat(cvInfectHits); }
				PrintToServer("dis = %f, min = %f, max = %f, hits = %f, infectHits = %f", dis, min, max, hits, infectHits[i]);
			}
			//PrintToServer("player %i is spreading infection to player %i", client, i);
			if(infectHits[i] >= GetConVarInt(cvInfectHits) && infectionTimer[i] == INVALID_HANDLE && !isInfected[i])
			{
				tempInfectHP[i] = GetClientHealth(i);
				isInfected[i] = true;
				//PrintToServer("player %i is infected by spread", i);
				EmitSoundToAll(SND_INFECT, i);
				new Handle:pack;
				new Float:randTime = GetRandomFloat(0.0, 0.33);
				infectionTimer[i] = CreateDataTimer((3.0 + randTime), InfectionTimer, pack, TIMER_REPEAT);
				WritePackCell(pack, i);
				WritePackCell(pack, client);
			}
		}
	}
}

public Action:debuffAway(Handle:timer, any:client) 
{
	if(GetConVarInt(cvSniperShot)==1)
	{
		if(speedDebuff[client] > 1.0)
		{
			speedDebuff[client] -= GetConVarFloat(cvSniperShotAmount);
		}
	}
	/*else if(GetConVarInt(cvSniperShot)==2)
	{
		if(speedDebuff[client] > 1.0)
		{
			if((speedDebuff[client] - (speedDebuff[client]/10.0) - GetConVarFloat(cvSniperShotAmount)) >= 1.0)
			{
				speedDebuff[client] = speedDebuff[client] - (speedDebuff[client]/10.0) - GetConVarFloat(cvSniperShotAmount);
			}
			else
			{
				speedDebuff[client] = 1.0;
			}
		}
	}*/
}

public Action:WallJumpReady(Handle:timer, any:client) 
{
	//if(wallJumpReady[client]) { wallJumpReady[client] = false; }
	//else { wallJumpReady[client] = true; }
	wallJumpReady[client] = true;
}

PrecacheNadeModels()
{
	
	PrecacheModel("models/error.mdl");
	
	PrecacheModel(MDL_FRAG, true);
	PrecacheModel(MDL_CONC, true);
	PrecacheModel(MDL_NAIL, true);
	PrecacheModel(MDL_MIRV1, true);
	PrecacheModel(MDL_MIRV2, true);
	PrecacheModel(MDL_HEALTH, true);
	PrecacheModel(MDL_NAPALM, true);
	PrecacheModel(MDL_HALLUC, true);
	PrecacheModel(MDL_EMP, true);
	//nadeMaterialIndex = PrecacheModel(MTL_NADE, true);
	PrecacheSound(SND_NADE_HEALTH_TIMER, true);
	
	AddFolderToDownloadTable("models/weapons/nades/duke1");
	AddFolderToDownloadTable("materials/models/weapons/nades/duke1");
	AddFileToDownloadsTable("sound/hallelujah.wav");
	AddFileToDownloadsTable("sound/camera_rewind.wav");
	AddFileToDownloadsTable("sound/bush_fire.wav");
	
}

painSoundSetup()
{
	for(new i=0;i<9;i++)
	{
		switch (i)
		{
			case 0:
			{
				for(new j=0;j<6;j++)
				{
					Format(soundPainScoutSevere[j], 31, "vo/scout_painsevere0%i.wav", j+1);
				}
				for(new j=0;j<8;j++)
				{
					Format(soundPainScoutSharp[j], 31, "vo/scout_painsharp0%i.wav", j+1);
				}
			}
			case 1:
			{
				for(new j=0;j<4;j++)
				{
					Format(soundPainSniperSevere[j], 31, "vo/sniper_painsevere0%i.wav",j+1);
				}
				for(new j=0;j<4;j++)
				{
					Format(soundPainSniperSharp[j], 31, "vo/sniper_painsharp0%i.wav",j+1);
				}
			}
			case 2:
			{
				for(new j=0;j<6;j++)
				{
					Format(soundPainSoldierSevere[j], 31, "vo/soldier_painsevere0%i.wav",j+1);
				}
				for(new j=0;j<8;j++)
				{
					Format(soundPainSoldierSharp[j], 31, "vo/soldier_painsharp0%i.wav",j+1);
				}
			}
			case 3:
			{
				for(new j=0;j<4;j++)
				{
					Format(soundPainDemoSevere[j], 31, "vo/demoman_painsevere0%i.wav",j+1);
				}
				for(new j=0;j<7;j++)
				{
					Format(soundPainDemoSharp[j], 31, "vo/demoman_painsharp0%i.wav",j+1);
				}
			}
			case 4:
			{
				for(new j=0;j<4;j++)
				{
					Format(soundPainMedicSevere[j], 31, "vo/medic_painsevere0%i.wav",j+1);
				}
				for(new j=0;j<8;j++)
				{
					Format(soundPainMedicSharp[j], 31, "vo/medic_painsharp0%i.wav",j+1);
				}
			}
			case 5:
			{
				for(new j=0;j<3;j++)
				{
					Format(soundPainHeavySevere[j], 31, "vo/heavy_painsevere0%i.wav",j+1);
				}
				for(new j=0;j<5;j++)
				{
					Format(soundPainHeavySharp[j], 31, "vo/heavy_painsharp0%i.wav",j+1);
				}
				
			}
			case 6:
			{
				for(new j=0;j<6;j++)
				{
					Format(soundPainPyroSevere[j], 31, "vo/pyro_painsevere0%i.wav",j+1);
				}
				for(new j=0;j<7;j++)
				{
					Format(soundPainPyroSharp[j], 31, "vo/pyro_painsharp0%i.wav",j+1);
				}
			}
			case 7:
			{
				for(new j=0;j<5;j++)
				{
					Format(soundPainSpySevere[j], 31, "vo/spy_painsevere0%i.wav",j+1);
				}
				for(new j=0;j<4;j++)
				{
					Format(soundPainSpySharp[j], 31, "vo/spy_painsharp0%i.wav",j+1);
				}
			}
			case 8:
			{
				for(new j=0;j<7;j++)
				{
					Format(soundPainEngineerSevere[j], 31, "vo/engineer_painsevere0%i.wav",j+1);
				}
				for(new j=0;j<8;j++)
				{
					Format(soundPainEngineerSharp[j], 31, "vo/engineer_painsharp0%i.wav",j+1);
				}
			}
		}
	}
}

PrecachePainSounds()
{
	for(new i=0;i<3;i++)
	{
		PrecacheSound(soundPainHeavySevere[i], true);
	}
	for(new i=0;i<4;i++)
	{
		PrecacheSound(soundPainMedicSevere[i], true);
		PrecacheSound(soundPainDemoSevere[i], true);
		PrecacheSound(soundPainSniperSevere[i], true);
		PrecacheSound(soundPainSniperSharp[i], true);
		PrecacheSound(soundPainSpySharp[i], true);
	}
	for(new i=0;i<5;i++)
	{
		PrecacheSound(soundPainSpySevere[i], true);
		PrecacheSound(soundPainHeavySharp[i], true);
	}
	for(new i=0;i<6;i++)
	{
		PrecacheSound(soundPainScoutSevere[i], true);
		PrecacheSound(soundPainSoldierSevere[i], true);
		PrecacheSound(soundPainPyroSevere[i], true);
	}
	for(new i=0;i<7;i++)
	{
		PrecacheSound(soundPainDemoSharp[i], true);
		PrecacheSound(soundPainPyroSharp[i], true);
		PrecacheSound(soundPainEngineerSevere[i], true);
	}
	for(new i=0;i<8;i++)
	{
		PrecacheSound(soundPainScoutSharp[i], true);
		PrecacheSound(soundPainMedicSharp[i], true);
		PrecacheSound(soundPainSoldierSharp[i], true);
		PrecacheSound(soundPainEngineerSharp[i], true);
	}
}

// *************************************************
// helper funcs
// *************************************************

// show a health sign above client's head
ShowHealthParticle(client)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		if (GetClientTeam(client)==2)
		{
			DispatchKeyValue(particle, "effect_name", "healthgained_red");
		}
		else
		{
			DispatchKeyValue(particle, "effect_name", "healthgained_blu");
		}
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetVariantString("head");
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(2.0, DeleteParticles, particle);
	}
	else
	{
		LogError("ShowHealthParticle: could not create info_particle_system");
	}
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		new String:classname[STRLENGTH];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
		else
		{
			LogError("DeleteParticles: not removing entity - not a particle '%s'", classname);
		}
	}
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
	else
	{
		LogError("ShowParticle: could not create info_particle_system");
	}	
}

AttachParticle(ent, String:particleType[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
	else
	{
		LogError("AttachParticle: could not create info_particle_system");
	}
}

ShowTrail(nade, color[4])
{
	TE_SetupBeamFollow(nade, gRingModel, 0, Float:1.0, Float:10.0, Float:10.0, 5, color);
	TE_SendToAll();
}

// players in range setup  (self = 0 if doesn't affect self)
FindPlayersInRange(Float:location[3], Float:radius, team, self, bool:trace, donthit)
{
	new Float:rsquare = radius*radius;
	new Float:orig[3];
	new Float:distance;
	new Handle:tr;
	new j;
	new maxplayers = GetMaxClients();
	for (j=1;j<=maxplayers;j++)
	{
		PlayersInRange[j] = 0.0;
		if (IsClientInGame(j))
		{
			if (IsPlayerAlive(j))
			{
				if ( (team>1 && GetClientTeam(j)==team) || team==0 || j==self)
				{
					GetClientAbsOrigin(j, orig);
					orig[0]-=location[0];
					orig[1]-=location[1];
					orig[2]-=location[2];
					orig[0]*=orig[0];
					orig[1]*=orig[1];
					orig[2]*=orig[2];
					distance = orig[0]+orig[1]+orig[2];
					if (distance < rsquare)
					{
						if (trace)
						{
							GetClientEyePosition(j, orig);
							tr = TR_TraceRayFilterEx(location, orig, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfOrPlayers, donthit);
							if (tr!=INVALID_HANDLE)
							{
								if (TR_GetFraction(tr)>0.98)
								{
									PlayersInRange[j] = SquareRoot(distance)/radius;
								}
								CloseHandle(tr);
							}
							
						}
						else
						{
							PlayersInRange[j] = SquareRoot(distance)/radius;
						}
					}
				}
			}
		}
	}
}

serverMessage()
{
	PrintCenterTextAll("This server is running the TF2Classic mod. for info type /info");
}

setDoorSpeed()
{
	new ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "func_door"))!=-1) 
	{
		//PrintToServer("found door %i", ent);
		//SetVariantString("1234.5");
		//DispatchKeyValue(ent, speed, 1234);
		SetVariantFloat(6789.0);
		AcceptEntityInput(ent, "SetSpeed");
	}
	ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "prop_dynamic"))!=-1) 
	{
		if (IsValidEdict(ent))
		{
			GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
			if ((StrContains(tName,"door",false)!=-1) || (StrContains(tName,"gate",false)!=-1))
			{
				//PrintToServer("entity: %i, full name:%s", ent, tName);
				DispatchKeyValue(ent, "solid", "0");
			}
		}
	}
}

SetupHudMsg(Float:time)
{
	SetHudTextParams(-1.0, 0.8, time, 255, 255, 255, 64, 1, 0.5, 0.0, 0.5);
}

KillPlayer(client, attacker, String:weapon[256])
{
	gKilledBy[client] = GetClientUserId(attacker);
	gKillTime[client] = GetEngineTime();
	strcopy(gKillWeapon[client], STRLENGTH, weapon);
	/*
	if (explode)
	{
	FakeClientCommand(client, "explode\n");
	}
	else
	{
	ForcePlayerSuicide(client);
	}
	*/
	new ent = CreateEntityByName("env_explosion");
	if (IsValidEntity(ent))
	{
		DispatchKeyValue(ent, "iMagnitude", "1000");
		DispatchKeyValue(ent, "iRadiusOverride", "2");
		SetEntPropEnt(ent, Prop_Data, "m_hInflictor", attacker);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", attacker);
		DispatchKeyValue(ent, "spawnflags", "3964");
		DispatchSpawn(ent);
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(ent, "explode", client, client);
		CreateTimer(0.2, RemoveExplosion, ent);
	}
}

public Action:RemoveExplosion(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		new String:edictname[128];
		GetEdictClassname(ent, edictname, 128);
		if(StrEqual(edictname, "env_explosion"))
		{
			RemoveEdict(ent);
		}
	}
}

HurtPlayer(client, attacker, damage, String:weapon[256], bool:explosion, Float:pos[3], Float:knockbackmult = 4.0, type = 0)
{
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond & 32)
	{
		return;
	}
	
	new health = GetClientHealth(client);
	
	if (explosion)
	{
		
		new Float:play[3], Float:playerspeed[3], Float:distance;
		GetClientAbsOrigin(client, play);
		play[2] += 64.0;
		SubtractVectors(play, pos, play);
		distance = GetVectorLength(play);
		if (distance<1.0) { distance = 1.0; }
		ScaleVector(play, (1.0/distance)+0.01);
		ScaleVector(play, damage * knockbackmult);
		
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
		//playerspeed[2]=0.0;
		AddVectors(play, playerspeed, play);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, play);
	}
	
	if(GetConVarInt(cvArmor)==1)
	{
		if(damage > 0)
		{
			PrintToServer("damage before: %d", damage);
			new tf2class = int:TF2_GetPlayerClass(client);
			if(tf2class == SCOUT || tf2class == SNIPER || tf2class == SPY)//light armor
			{
				if(armor[client] > 0)
				{
					new Float:tempDamage;
					tempDamage = float(damage)*GetConVarFloat(cvArmorAmounts[0][0]);
					armor[client] -= RoundToFloor(tempDamage);
					if(armor[client] < 0)
					{ 
						damage -= armor[client];
						armor[client] = 0;
					}
					damage -= RoundToFloor(tempDamage);
				}
			}
			else if(tf2class == MEDIC || tf2class == DEMO || tf2class == ENGIE || tf2class == PYRO) //medium armor
			{
				if(armor[client] > 0)
				{
					new Float:tempDamage;
					tempDamage = float(damage)*GetConVarFloat(cvArmorAmounts[1][0]);
					armor[client] -= RoundToFloor(tempDamage);
					if(armor[client] < 0)
					{ 
						damage -= armor[client];
						armor[client] = 0;
					}
					damage -= RoundToFloor(tempDamage);
				}
			}
			else if(tf2class == HEAVY || tf2class == SOLDIER) //heavy armor
			{
				if(armor[client] > 0)
				{
					new Float:tempDamage;
					tempDamage = float(damage)*GetConVarFloat(cvArmorAmounts[2][0]);
					armor[client] -= RoundToFloor(tempDamage);
					if(armor[client] < 0)
					{ 
						damage -= armor[client];
						armor[client] = 0;
					}
					damage -= RoundToFloor(tempDamage);
				}
			}
			PrintToServer("damage after: %d", damage);
		}	
	}
		
	if (health>damage)
	{
		//EmitSoundToAll(sndPain, client);
		painSound(client, type);
		SetEntityHealth(client, health-damage);
	}
	else
	{
		KillPlayer(client, attacker, weapon);
	}
}

painSound(client, type)
{
	new class = int:TF2_GetPlayerClass(client);
	switch (class)
	{
		case SCOUT:
		{
			if(type==0) //severe (explosion)
			{
				new rand = GetRandomInt(0, 5);
				EmitSoundToAll(soundPainScoutSevere[rand], client);
			}
			else if(type==1) //sharp (nails)
			{
				new rand = GetRandomInt(0, 7);
				EmitSoundToAll(soundPainScoutSharp[rand], client);
			}
			else if(type==2) //infect
			{
				//new rand = GetRandomInt(1, 4);
			}
		}
		case SNIPER:
		{
			if(type==0) //severe (explosion)
			{
				new rand = GetRandomInt(0, 3);
				EmitSoundToAll(soundPainSniperSevere[rand], client);
			}
			else if(type==1) //sharp (nails)
			{
				new rand = GetRandomInt(0, 5);
				EmitSoundToAll(soundPainSniperSharp[rand], client);
			}
			else if(type==2) //infect
			{
				//new rand = GetRandomInt(1, 4);
			}
		}
		case SOLDIER:
		{
			if(type==0) //severe (explosion)
			{
				new rand = GetRandomInt(0, 5);
				EmitSoundToAll(soundPainSoldierSevere[rand], client);
			}
			else if(type==1) //sharp (nails)
			{
				new rand = GetRandomInt(0, 7);
				EmitSoundToAll(soundPainSoldierSharp[rand], client);
			}
			else if(type==2) //infect
			{
				//new rand = GetRandomInt(1, 4);
			}
		}
		case DEMO:
		{
			if(type==0) //severe (explosion)
			{
				new rand = GetRandomInt(0, 3);
				EmitSoundToAll(soundPainDemoSevere[rand], client);
			}
			else if(type==1) //sharp (nails)
			{
				new rand = GetRandomInt(0, 6);
				EmitSoundToAll(soundPainDemoSharp[rand], client);
			}
			else if(type==2) //infect
			{
				//new rand = GetRandomInt(1, 4);
			}
		}
		case MEDIC:
		{
			if(type==0) //severe (explosion)
			{
				new rand = GetRandomInt(0, 3);
				EmitSoundToAll(soundPainMedicSevere[rand], client);
			}
			else if(type==1) //sharp (nails)
			{
				new rand = GetRandomInt(0, 7);
				EmitSoundToAll(soundPainMedicSharp[rand], client);
			}
			else if(type==2) //infect
			{
				//new rand = GetRandomInt(1, 4);
			}
		}
		case HEAVY:
		{
			if(type==0) //severe (explosion)
			{
				new rand = GetRandomInt(0, 2);
				EmitSoundToAll(soundPainHeavySevere[rand], client);
			}
			else if(type==1) //sharp (nails)
			{
				new rand = GetRandomInt(0, 4);
				EmitSoundToAll(soundPainHeavySharp[rand], client);
			}
			else if(type==2) //infect
			{
				//new rand = GetRandomInt(1, 4);
			}
		}
		case PYRO:
		{
			if(type==0) //severe (explosion)
			{
				new rand = GetRandomInt(0, 5);
				EmitSoundToAll(soundPainPyroSevere[rand], client);
			}
			else if(type==1) //sharp (nails)
			{
				new rand = GetRandomInt(0, 6);
				EmitSoundToAll(soundPainPyroSharp[rand], client);
			}
			else if(type==2) //infect
			{
				//new rand = GetRandomInt(1, 4);
			}
		}
		case SPY:
		{
			if(type==0) //severe (explosion)
			{
				new rand = GetRandomInt(0, 4);
				EmitSoundToAll(soundPainSpySevere[rand], client);
			}
			else if(type==1) //sharp (nails)
			{
				new rand = GetRandomInt(0, 3);
				EmitSoundToAll(soundPainSpySharp[rand], client);
			}
			else if(type==2) //infect
			{
				//new rand = GetRandomInt(1, 4);
			}
		}
		case ENGIE:
		{
			if(type==0) //severe (explosion)
			{
				new rand = GetRandomInt(0, 6);
				EmitSoundToAll(soundPainEngineerSevere[rand], client);
			}
			else if(type==1) //sharp (nails)
			{
				new rand = GetRandomInt(0, 7);
				EmitSoundToAll(soundPainEngineerSharp[rand], client);
			}
			else if(type==2) //infect
			{
				//new rand = GetRandomInt(1, 4);
			}
		}
	}
}

GetMetalAmount(client)
{
	return GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 4);
}

SetMetalAmount(client, metal)
{
	SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), metal, 4);  
}

DamageBuildings(attacker, Float:start[3], Float:radius, damage, nade, bool:trace)
{
	new Float:pos[3];
	pos[0]=start[0];pos[1]=start[1];pos[2]=start[2]+16.0;
	new count = GetMaxEntities();
	new i;
	new Float:obj[3], Float:objcalc[3];
	new Float:rad = radius * radius;
	new Float:distance;
	new Handle:tr;
	new team = GetClientTeam(attacker);
	new objteam;
	for (i=GetMaxClients()+1; i<count; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, tName, sizeof(tName));
			if (StrEqual(tName, "obj_sentrygun")
				|| StrEqual(tName, "obj_dispenser") 
				|| StrEqual(tName, "obj_teleporter_entrance")
				|| StrEqual(tName, "obj_teleporter_exit") )
			{
				objteam=GetEntProp(i, Prop_Data, "m_iTeamNum");
				if (team!=objteam)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", obj);
					objcalc[0]=obj[0]-pos[0];
					objcalc[1]=obj[1]-pos[1];
					objcalc[2]=obj[2]-pos[2];
					objcalc[0]*=objcalc[0];
					objcalc[1]*=objcalc[1];
					objcalc[2]*=objcalc[2];
					distance = objcalc[0]+objcalc[1]+objcalc[2];
					if (distance<rad)
					{
						if (trace)
						{
							obj[2]+=16.0;
							tr = TR_TraceRayFilterEx(pos, obj, MASK_SOLID, RayType_EndPoint, TraceRayDontHitObjOrPlayers, nade);
							if (tr!=INVALID_HANDLE)
							{
								if (TR_GetFraction(tr)>0.98 || TR_GetEntityIndex(tr)==i)
								{
									SetVariantInt(damage);
									AcceptEntityInput(i, "RemoveHealth", attacker, attacker);
								}
								CloseHandle(tr);
							}
							
						}
						else
						{
							SetVariantInt(damage);
							AcceptEntityInput(i, "RemoveHealth", attacker, attacker);
						}
					}
				}
			}
		}
	}
}

AddFolderToDownloadTable(const String:Directory[], bool:recursive=false) 
{
	decl String:FileName[64], String:Path[512];
	new Handle:Dir = OpenDirectory(Directory), FileType:Type;
	while(ReadDirEntry(Dir, FileName, sizeof(FileName), Type))     
	{
		if(Type == FileType_Directory && recursive)         
		{           
			FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
			AddFolderToDownloadTable(FileName);
			continue;
			
		}                 
		if (Type != FileType_File) continue;
		FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
		AddFileToDownloadsTable(Path);
	}
	return;	
}

bool:CheckNormal(Float:vel[3], Float:min[3])
{
	new n0, n1;
	new Float:velocity[3], Float:minimum[3];
	velocity = vel;
	minimum = min;
	new bool:check;
	if(minimum[0] > 0.01) { n0 = 1; } else if(minimum[0] < -0.01) { n0 = -1; } else { n0 = 0; }
	if(minimum[1] > 0.01) { n1 = 1; } else if(minimum[1] < -0.01) { n1 = -1; } else { n1 = 0; }
	if( (n0 == 1 && n1 == 1) || (n0 == -1 && n1 == -1) || (n0 == 1 && n1 == -1) || (n0 == -1 && n1 == 1) )
	{
		minimum[0] = -minimum[1];
		minimum[1] = -minimum[0];
		minimum[2] = 0.0;
	}
	else if( (n0 == 1 && n1 == 0) || (n0 == -1 && n1 == 0) )
	{
		minimum[0] = -minimum[0];
		minimum[2] = 0.0;
	}
	else if( (n0 == 0 && n1 == 1) || (n0 == 0 && n1 == -1) )
	{
		minimum[1] = -minimum[1];
		minimum[2] = 0.0;
	}
	for(new i=0;i<3;i++)
	{
		minimum[i] *= (GetConVarFloat(cvWallJumpMinSpeed));
	}
	new Float:gospeed[2];
	gospeed[0] = SquareRoot( (minimum[0]*minimum[0]) + (minimum[1]*minimum[1]) );
	gospeed[1] = SquareRoot( (velocity[0]*velocity[0]) + (velocity[1]*velocity[1]) );
	if(gospeed[1] >= gospeed[0])
	{
		check = true;
	}
	else
	{
		check = false;
	}
	return check;
}

public bool:TraceRayDontHitSelfOrPlayers(entity, mask, any:startent)
{
	if(entity == startent)
	{
		return false; // 
	}
	
	if (entity <= GetMaxClients())
	{
		return false;
	}
	
	return true; 
}

public bool:TraceRayDontHitSelf(entity, mask, any:startent)
{
	if(entity == startent)
	{
		return false;
	}
	
	return true;
}

public bool:TraceRayDontHitObjOrPlayers(entity, mask, any:startent)
{
	if(entity == startent)
	{
		return false; // 
	}
	
	if (entity <= GetMaxClients())
	{
		return false;
	}
	
	if (IsValidEntity(entity))
	{
		GetEdictClassname(entity, tName, sizeof(tName));
		if (StrEqual(tName, "obj_sentrygun")
			|| StrEqual(tName, "obj_dispenser") 
			|| StrEqual(tName, "obj_teleporter_entrance")
			|| StrEqual(tName, "obj_teleporter_exit")
			|| StrEqual(tName, "tf_ammo_pack") )
		{
			return false;
		}
	}
	
	return true; 
}

TagsCheck(const String:tag[])
{
    new Handle:hTags = FindConVar("sv_tags");
	
    decl String:tags[255];
    GetConVarString(hTags, tags, sizeof(tags));

    if (!(StrContains(tags, tag, false)>-1))
    {
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		SetConVarString(hTags, newTags);
		GetConVarString(hTags, tags, sizeof(tags));
    }

    CloseHandle(hTags);
} 

Float:CheckSpeed(Float:lastSpeed, Float:Speed, Float:Vel[3])
{
	/*new Float:tLastVel[3]; tLastVel = lastVel;
	tLastVel[2] *= 0.5;
	new Float:tVel[3]; tVel = Vel;
	tVel[2] *= 0.5;
	new Float:lastSpeed = GetVectorLength(tLastVel);
	new Float:Speed = GetVectorLength(tVel);*/
	if(Speed < lastSpeed)
	{
		for(new x=0;x<3;x++)
		{
			Vel[x] *= lastSpeed/Speed;
		}
	}
	return Vel;
}

Float:DoubleJump(Float:time, Float:Vel[3], mode=0)
{
	new Float:zspeed;
	if(Vel[2] >= 0.0)
	{
		new Float:s = GetVectorLength(Vel);
		//time -= GetConVarFloat(cvDJumpDelay);
		//new Float:zspeed = (800.0/3.0)*GetConVarFloat(cvDJumpIncrement)*(1.5-time);
		//-75(x)^0.2+700 + -0.001(1/4(x-750)^2+500
		//
		new Float:pow, Float:pow2;
		pow = Pow(s, 0.2); pow2 = Pow(0.2*s-750.0, 2.0);
		new Float:max, Float:max1, Float:max2;
		max	= (-75.0*pow)+700.0;
		max1 = max + (-0.002*pow2)+1000.0;
		max2 = max1 * (GetConVarFloat(cvDJumpTBoost)-time);
		if(GetConVarInt(BunnyMode)>=5 || mode==2)
		{ zspeed = max2; } else { zspeed = s*(1.25-time); }
		if(zspeed < (800.0/3.0)*1.1) { zspeed = (800.0/3.0)*1.1; }
		if(zspeed > GetConVarFloat(cvDJumpMax)) { zspeed = GetConVarFloat(cvDJumpMax); }
		PrintToServer("pow:%f, pow2:%f, max:%f, max1:%f, max2:%f, spd:%f", pow, pow2, max, max1, max2, zspeed);
	}
	else
	{
		zspeed = 800.0/300.0;
	}
	return zspeed;
}

Float:IsDJumpReady(client, Float:curTime)
{
	new Float:result;
	if( (curTime - lastJumpTime[client] > GetConVarFloat(cvDJumpDelay)) && (curTime - lastJumpTime[client] < GetConVarFloat(cvDJumpDelay2)) )
	{
		result = curTime-lastJumpTime[client]-GetConVarFloat(cvDJumpDelay);
	}
	else
	{
		result = 0.0;
	}
	return result;
}
