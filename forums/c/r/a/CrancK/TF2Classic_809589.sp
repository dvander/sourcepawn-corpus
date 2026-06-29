#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <dukehacks>

#define PLUGIN_VERSION "1.0.0.0"

public Plugin:myinfo = {
	name = "TF2 Classic",
	author = "CrancK",
	description = "Brings a bit of tfc into tf2",
	version = PLUGIN_VERSION,
	url = ""
};

// *************************************************
// defines
// *************************************************


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


new String:sndPain[128] = "player/pain.wav";


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
new gRemaining1[MAX_PLAYERS+1];						// how many nades player has this spawn
new gRemaining2[MAX_PLAYERS+1];						// how many nades player has this spawn
new gHolding[MAX_PLAYERS+1];
new Handle:gNadeTimer[MAX_PLAYERS+1][MAX_NADES];				// pointer to nade timer
new Handle:gNadeTimer2[MAX_PLAYERS+1][MAX_NADES];
new Handle:gNadeTimer3[MAX_PLAYERS+1][MAX_NADES];
new Handle:gNailTimer[MAX_PLAYERS+1][MAX_NADES];
new Handle:gNadeTimerBeep[MAX_PLAYERS+1][MAX_NADES];
new Handle:g_DrugTimers[MAXPLAYERS+1];
new bool:gDrugged[MAXPLAYERS+1];
new bool:gThrown[MAX_PLAYERS+1][MAX_NADES];
new nailNade[MAX_PLAYERS+1];
new gNade[MAX_PLAYERS+1][MAX_NADES];							// pointer to the player's nade
new gNadeNumber[MAX_PLAYERS+1];
new gRingModel;										// model for beams
new tempNumber[MAX_PLAYERS+1][MAX_NADES];
new tempNumber2[MAX_PLAYERS+1][MAX_NADES];
new Float:gHoldingArea[3];							// point to store unused objects
new Float:PlayersInRange[MAX_PLAYERS+1];			// players are in radius ?
new gKilledBy[MAX_PLAYERS+1];						// player that killed
new String:gKillWeapon[MAX_PLAYERS+1][STRLENGTH];	// weapon that killed
new Float:gKillTime[MAX_PLAYERS+1];					// time plugin requested kill
new gNapalmSprite;									// sprite index
new gEmpSprite;
new bool:throwTime[MAX_PLAYERS+1];
new showClientInfo[MAX_PLAYERS+1];

new CanDJump[MAX_PLAYERS+1];
new InTrimp[MAX_PLAYERS+1];
new WasInJumpLastTime[MAX_PLAYERS+1];
new WasOnGroundLastTime[MAX_PLAYERS+1];
new Float:VelLastTime[MAX_PLAYERS+1][3];
new offsFOV = -1;
new offsDefaultFOV = -1;
new fov[MAX_PLAYERS+1];



// UserMessageId for Fade.
new UserMsg:g_FadeUserMsgId;
new gNadesUsed[MAX_PLAYERS+1];
new Float:g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

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
new Handle:cvRefill = INVALID_HANDLE;
new Handle:cvHHincrement = INVALID_HANDLE;
new Handle:cvShowDistance = INVALID_HANDLE;
new Handle:cvBlastDistanceMin = INVALID_HANDLE;
new Handle:cvSoundEnabled = INVALID_HANDLE;
new Handle:cvPlayerNadeBeep = INVALID_HANDLE;
new Handle:cvPickupsAllowed = INVALID_HANDLE;
new Handle:cvShowInfo = INVALID_HANDLE;
new Handle:cvStartNades = INVALID_HANDLE;

new Handle:Speedo = INVALID_HANDLE;
new Handle:SpeedoOff = INVALID_HANDLE;
new Handle:BunnyMode = INVALID_HANDLE;
new Handle:BunnyIncrement = INVALID_HANDLE;
new Handle:BunnyCap = INVALID_HANDLE;
new Handle:SelfBoostX = INVALID_HANDLE;
new Handle:SelfBoostY = INVALID_HANDLE;
new Handle:g_fovEnabled = INVALID_HANDLE;
new Handle:g_scale = INVALID_HANDLE;
new Handle:BunnySlowDown = INVALID_HANDLE;
new Handle:cvExplosionPower = INVALID_HANDLE;
new Handle:cvExplosionRadius = INVALID_HANDLE;
new Handle:cvQuadThreshold = INVALID_HANDLE;
new Handle:accel = INVALID_HANDLE;
new Handle:cvAirAccel = INVALID_HANDLE;

//new Handle:cvTest = INVALID_HANDLE;
new Handle:g_hInterval;
new Handle:g_hTimer;
new Handle:HudMessage;


native TF2_IgnitePlayer(client, attacker);

// *************************************************
// main plugin
// *************************************************

public OnPluginStart() {
	
	// events
	HookEvent("player_spawn",PlayerSpawn);
	HookEvent("player_death",PlayerDeath, EventHookMode_Pre);
	HookEvent("player_changeclass", ChangeClass);
	HookEvent("teamplay_round_start", MainEvents);
	HookEvent("teamplay_round_active", MainEvents);
	HookEvent("teamplay_restart_round", MainEvents);
	HookEvent("teamplay_round_stalemate", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", RoundEnd, EventHookMode_PostNoCopy);
	
	
	// convars
	cvWaitPeriod = CreateConVar("tf2c_nades_waitperiod", "1", "server waits for players on map start (1=true 0=false)", FCVAR_PLUGIN);
	cvEmpRadius = CreateConVar("tf2c_nades_emp_radius", "256", "radius for emp nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvEmpDelay = CreateConVar("tf2c_nades_emp_delay", "3.0", "delay in seconds before nade explodes", FCVAR_PLUGIN, true, 1.0, true, 10.0);
	cvEmpNum[1] = CreateConVar("tf2c_nades_emp_max", "4", "max number of emp nades", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvEmpNum[0] = CreateConVar("tf2c_nades_emp_min", "2", "number of emp nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvHallucDamage = CreateConVar("tf2c_halluc_damage", "5", "damage done by hallucination nade", FCVAR_PLUGIN);
	cvHallucDelay = CreateConVar("tf2c_nades_hallucination_time", "10.0", "delay in seconds that effects last", FCVAR_PLUGIN, true, 1.0, true, 10.0);	
	cvHallucRadius = CreateConVar("tf2c_nades_hallucination_radius", "256", "radius for hallincation nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvHallucNum[1] = CreateConVar("tf2c_nades_hallucination_max", "4", "max number of hallucination nades", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvHallucNum[0] = CreateConVar("tf2c_nades_hallucination_min", "2", "number of hallucination nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvNapalmDamage = CreateConVar("tf2c_nades_napalm_damage", "25", "initial damage for napalm nade", FCVAR_PLUGIN, true, 1.0, true, 500.0);
	cvNapalmRadius = CreateConVar("tf2c_nades_napalm_radius", "256", "radius for napalm nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvNapalmNum[1] = CreateConVar("tf2c_nades_napalm_max", "3", "max number of napalm nades", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvNapalmNum[0] = CreateConVar("tf2c_nades_napalm_min", "2", "number of napalm nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvHealthDelay = CreateConVar("tf2c_nades_health_delay", "3.0", "delay in seconds before nade explodes", FCVAR_PLUGIN, true, 1.0, true, 10.0);
	cvHealthRadius = CreateConVar("tf2c_nades_health_radius", "384", "radius for health nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvHealthNum[1] = CreateConVar("tf2c_nades_health_max", "1", "max number of health nades", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvHealthNum[0] = CreateConVar("tf2c_nades_health_min", "1", "number of health nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvMirvSpread = CreateConVar("tf2c_nades_mirv_spread", "384.0", "spread of secondary explosives (max speed)", FCVAR_PLUGIN, true, 1.0, true, 2048.0);	
	cvMirvDamage2 = CreateConVar("tf2c_nades_mirv_damage2", "60.0", "damage done by secondary explosion of mirv nade", FCVAR_PLUGIN, true, 1.0, true, 500.0);	
	cvMirvDamage1 = CreateConVar("tf2c_nades_mirv_damage1", "60.0", "damage done by main explosion of mirv nade", FCVAR_PLUGIN, true, 1.0, true, 500.0);
	cvMirvRadius = CreateConVar("tf2c_nades_mirv_radius", "128", "radius for demo's nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvMirvNum[2] = CreateConVar("tf2c_nades_mirv_heavy_min", "1", "number of mirv nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvMirvNum[3] = CreateConVar("tf2c_nades_mirv_heavy_max", "2", "max number of mirv nades given to Heavy", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvMirvNum[0] = CreateConVar("tf2c_nades_mirv_demo_min", "2", "number of mirv nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvMirvNum[1] = CreateConVar("tf2c_nades_mirv_demo_max", "3", "max number of mirv nades given to Demo", FCVAR_PLUGIN, true, 0.0, true, 10.0); 
	cvNailDamageExplode = CreateConVar("tf2c_nades_nail_explodedamage", "80.0", "damage done by final explosion", FCVAR_PLUGIN, true, 1.0, true,1000.0);
	cvNailDamageNail = CreateConVar("tf2c_nades_nail_naildamage", "8.0", "damage done by nail projectile", FCVAR_PLUGIN, true, 1.0, true, 500.0);
	cvNailRadius = CreateConVar("tf2c_nades_nail_radius", "256", "radius for nail nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvNailNum[1] = CreateConVar("tf2c_nades_nail_max", "2", "max number of nail nades", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvNailNum[0] = CreateConVar("tf2c_nades_nail_min", "1", "number of nail nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvConcDamage = CreateConVar("tf2c_nades_conc_damage", "10", "damage done by concussion nade", FCVAR_PLUGIN);
	cvConcForce = CreateConVar("tf2c_nades_conc_force", "5", "force applied by concussion nade", FCVAR_PLUGIN);
	cvConcDelay = CreateConVar("tf2c_nades_conc_delay", "3.0", "delay in seconds before nade explodes", FCVAR_PLUGIN, true, 1.0, true, 10.0);
	cvConcRadius = CreateConVar("tf2c_nades_conc_radius", "256", "radius for concussion nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
	cvConcNum[1] = CreateConVar("tf2c_nades_conc_max", "4", "max number of conc nades", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvConcNum[0] = CreateConVar("tf2c_nades_conc_min", "2", "number of conc nades given at start and at spawn lockers", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	cvFragDamage = CreateConVar("tf2c_nades_frag_damage", "100", "damage done by concussion nade", FCVAR_PLUGIN);
	cvFragRadius = CreateConVar("tf2c_nades_frag_radius", "256", "radius for concussion nade", FCVAR_PLUGIN, true, 1.0, true, 2048.0);
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
	
	cvShowDistance = CreateConVar("tf2c_nades_showdistance", "0", "shows distance to conc relative to radius, 1=radius", 0, true, 0.0, true, 1.0);
	cvBlastDistanceMin = CreateConVar("tf2c_nades_blastdistancemin", "0.75", "minimum blast radius", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvHHincrement = CreateConVar("tf2c_nades_hhincrement", "2.0", "speed gain from HH", FCVAR_PLUGIN|FCVAR_NOTIFY , true, 1.0, true, 5.0);
	cvSoundEnabled = CreateConVar("tf2c_nades_soundEnabled", "1.0", "nade sounds enabled on 1", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvPickupsAllowed = CreateConVar("tf2c_pickupsAllowed", "1.0", "health & nade pickups", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvPlayerNadeBeep = CreateConVar("tf2c_nades_selfbeep", "1.0", "enables self-beep", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvShowInfo = CreateConVar("tf2c_nades_showinfo", "1", "enables health/nades display for clients", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvRefill = CreateConVar("tf2c_jump_refill", "0", "Allow refill for on jump maps", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvStartNades = CreateConVar("tf2c_startnades", "0", "Enables/disables nades on spawn, 1=min amounts, 2=max amounts", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvAirAccel = CreateConVar("tf2c_aa", "10", "airacceleration",FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	Speedo = CreateConVar("tf2c_speedometer", "0", "ALWAYS show speedometer for all clients", FCVAR_PLUGIN);
	SpeedoOff = CreateConVar("tf2c_speedometer_off", "0", "Never show speedometer for all clients", FCVAR_PLUGIN);
	BunnyMode = CreateConVar("tf2c_bhop_Mode", "3", "Changes how bunnyhopping increases speed, 0 for normal, 1 for only turning speed, 2 for set speed 3 for set everything", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	BunnyIncrement = CreateConVar("tf2c_bhop_Increment", "1.01", "Changes bunnyhop speedincrease if bhopMode is set to 2", FCVAR_PLUGIN|FCVAR_NOTIFY , true, 1.0, true, 2.0);
	BunnyCap = CreateConVar("tf2c_bhop_Cap", "1.8", "Changes the bunnyhop speed cap if bhopMode is set to 2", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 5.0);
	BunnySlowDown = CreateConVar("tf2c_bhop_Slowdown", "0.915", "in bhopmode 3, if above the bhopcap, slow down rate", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.000, true, 1.000);
	SelfBoostX = CreateConVar("tf2c_selfdamageBoostX", "1.1", "Changes the selfhurting increment (horizontal)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 5.0);
	SelfBoostY = CreateConVar("tf2c_selfdamageBoostY", "1.1", "Changes the selfhurting increment (vertical)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 5.0);
	g_fovEnabled = CreateConVar("tf2c_fovEnabled", "1.0", "allows changing of fov", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_scale = CreateConVar("tf2c_rspeed", "1.05", "Rocket speed mult", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvExplosionPower = CreateConVar("tf2c_power", "0.0", "explosionpower default = 4.0 or 0.0, quadjump = 16.0 or 12.0", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvExplosionRadius = CreateConVar("tf2c_quadradius", "128.0", "radius of rocket explosion", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvQuadThreshold = CreateConVar("tf2c_quadthreshold", "64.0", "perfect point for max boost, in distance from middle of explosion", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	CreateConVar("tf2c_version", PLUGIN_VERSION, "TF2Classic Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hInterval = CreateConVar("tf2c_hphud_interval", "5", "How often health timer is updated (in tenths of a second).");
	HookConVarChange(g_hInterval, ConVarChange_Interval);
	HookConVarChange(cvAirAccel, Cvar_AirAccel);
	HudMessage = CreateHudSynchronizer();
	
	
	// commands
	RegConsoleCmd("+nade1", Command_Nade1);
	RegConsoleCmd("-nade1", Command_UnNade1);
	RegConsoleCmd("+nade2", Command_Nade2);
	RegConsoleCmd("-nade2", Command_UnNade2);
	RegConsoleCmd("tf2c_selfbeep", Command_SelfBeep);
	RegConsoleCmd("tf2c_showinfo", Command_ShowInfo);
	
	RegConsoleCmd("say", Command_Say);
	accel = FindConVar("sv_airaccelerate");
	
	//RegConsoleCmd("tf2c_stop", Command_Stop, "stop the info panel from showing");
	//RegConsoleCmd("tf2c_nades", Command_NadeInfo, "view info on tf2nades plugin");
	RegConsoleCmd("tf2c_nades_refill", Command_RefillNades , "Refill nades");
	RegConsoleCmd("tf2c_fov", Command_fov, "Set your FOV.");
	offsFOV = FindSendPropOffs("CBasePlayer", "m_iFOV");
	offsDefaultFOV = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
	
	
	

	// misc setup
	g_FadeUserMsgId = GetUserMessageId("Fade");
	gHoldingArea[0]=-100000.0; gHoldingArea[1]=-100000.0; gHoldingArea[2]=-100000.0;
	new i;
	new j;
	for(i=0;i<MAX_PLAYERS+1;i++)
	{
		nailNade[i] = 0;
		throwTime[i] = false;
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
}

public OnClientPutInServer(client) {
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
	PrecacheNadeModels();
	g_hTimer = CreateTimer(GetConVarInt(g_hInterval) * 0.1, Timer_ShowInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	// reset status
	gCanRun = false;
	gWaitOver = false;
	gMapStart = GetGameTime();
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
	beepOn[client] = false;
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
			setDoorSpeed();
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
		if(IsValidEntity(i))
		{
			if(IsPlayerAlive(i) && !IsFakeClient(i) && !IsClientObserver(i))
			{
				new class = int:TF2_GetPlayerClass(i);
				if(GetConVarInt(cvStartNades)==1)
				{
					gRemaining1[i] = GetConVarInt(cvFragNum[class][0]);
					gRemaining2[i] = GetNumNades(class, 0);
				}
				else if(GetConVarInt(cvStartNades)==2)
				{
					gRemaining1[i] = GetConVarInt(cvFragNum[class][1]);
					gRemaining2[i] = GetNumNades(class, 1);
				}
				else
				{
					gRemaining1[i] = 0;
					gRemaining2[i] = 0;
				}
			}
		}
		// kill hooks
		gKilledBy[i]=0;
		gKillTime[i] = 0.0;
		gKillWeapon[i][0]='\0';
	}
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	gCanRun = false;
}


public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	
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
	
	new i;
	new ents = GetMaxEntities();
	new String:edictname[128];
	for (i=GetMaxClients()+1; i<ents; i++)
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
				FindPlayersInRange(pos, 128.0, 0, -1, false, -1);
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
				FindPlayersInRange(pos, 128.0, 0, -1, false, -1);
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
				FindPlayersInRange(pos, 128.0, 0, -1, false, -1);
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
			FindPlayersInRange(pos, 128.0, 0, -1, false, -1);
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

public Action:ScaleSpeed(Handle:timer, any:ent) {
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

// self-damage boost
public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim_id = GetEventInt(event, "userid");
	new attacker_id = GetEventInt(event, "attacker");
	//new damage = GetDamage(Event, victim, attacker, -1, -1);
		
	new victim = GetClientOfUserId(victim_id);
	new attacker = GetClientOfUserId(attacker_id);
	
	PrintToConsole(0, "selfdamage on victim %i by attacker %i", victim, attacker);
	
	if(attacker == victim)
	{
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
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if( IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) )
		{
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", PlayerVel);
			PlayerSpeed[0] = SquareRoot( (PlayerVel[0]*PlayerVel[0]) + (PlayerVel[1]*PlayerVel[1]) );
			
			// speedometer
			if(GetConVarBool(SpeedoOff))
			{
				if( GetConVarBool(Speedo) || (PlayerSpeed[0] >= (400.0*GetConVarFloat(BunnyIncrement)/1.2)) )
				{
					FloatToString((PlayerSpeed[0]),TempString,32); //"/(4.0*1.6)"
					PrintCenterText(i,"%i%", StringToInt(TempString));
				}
				else
				{
					PrintCenterText(i,"");
				}
			}
			
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
				
				// trimp
				if( ( (GetClientButtons(i) & IN_FORWARD) || (GetClientButtons(i) & IN_BACK) ) && (PlayerSpeed[0] >= (400.0 * 1.6)) && (GetClientButtons(i) & IN_DUCK))
				{
					TrimpVel[0] = PlayerVel[0] * Cosine(70.0*3.14159265/180.0);
					TrimpVel[1] = PlayerVel[1] * Cosine(70.0*3.14159265/180.0);
					TrimpVel[2] = PlayerSpeed[0] * Sine(70.0*3.14159265/180.0);
					
					InTrimp[i] = true;
					
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, TrimpVel);
				}
				
				// bhop (and normal jump)
				else
				{	
					// apply bhop boost
					if( WasOnGroundLastTime[i] || (GetClientButtons(i) & IN_DUCK) ){}
					else
					{
						switch (GetConVarInt(BunnyMode))
						{
							case 0:
							{
								PlayerVel[0] = 1.2 * PlayerVel[0];
								PlayerVel[1] = 1.2 * PlayerVel[1];
								PlayerSpeed[0] = 1.2 * PlayerSpeed[0];
							}
							case 1:
							{
							}
							case 2:
							{
								PlayerVel[0] = GetConVarFloat(BunnyIncrement) * PlayerVel[0];
								PlayerVel[1] = GetConVarFloat(BunnyIncrement) * PlayerVel[1];
								PlayerSpeed[0] = GetConVarFloat(BunnyIncrement) * PlayerSpeed[0];
							}
							case 3:
							{
								PlayerVel[0] = GetConVarFloat(BunnyIncrement) * PlayerVel[0];
								PlayerVel[1] = GetConVarFloat(BunnyIncrement) * PlayerVel[1];
								PlayerSpeed[0] = GetConVarFloat(BunnyIncrement) * PlayerSpeed[0];
							}
						}
					}
					// apply bhop caps
					if(GetConVarInt(BunnyMode) == 2 || GetConVarInt(BunnyMode) == 3){
						if(GetClientButtons(i) & IN_DUCK)
						{
							if(PlayerSpeed[0] > (1.2 * 400.0 * GetConVarFloat(BunnyCap)))
							{
								if(GetConVarInt(BunnyMode) == 3)
								{
									PlayerVel[0] *= GetConVarFloat(BunnySlowDown);
									PlayerVel[1] *= GetConVarFloat(BunnySlowDown);
								}
								else
								{
									PlayerVel[0] = PlayerVel[0] * 1.2 * 400.0 * GetConVarFloat(BunnyCap) / PlayerSpeed[0];
									PlayerVel[1] = PlayerVel[1] * 1.2 * 400.0 * GetConVarFloat(BunnyCap) / PlayerSpeed[0];
								}
							}
						}
						else if(PlayerSpeed[0] > (400.0 * GetConVarFloat(BunnyCap)))
						{
							if(GetConVarInt(BunnyMode) == 3)
							{
								PlayerVel[0] *= GetConVarFloat(BunnySlowDown);
								PlayerVel[1] *= GetConVarFloat(BunnySlowDown);
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
					
					PlayerVel[2] = 800.0/3.0;
					
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel);
				}
			}
			
			
			// doublejump
			else if( (InTrimp[i] || (CanDJump[i] && (TF2_GetPlayerClass(i) == TFClass_Scout))) && (WasInJumpLastTime[i] == 0) && (GetClientButtons(i) & IN_JUMP) )
			{
				PlayerSpeedLastTime[0] = 1.2 * SquareRoot( (VelLastTime[i][0]*VelLastTime[i][0]) + (VelLastTime[i][1]*VelLastTime[i][1]) );
				
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
				PlayerVel[2] = 800.0/3.0;
				
				CanDJump[i] = false;
				InTrimp[i] = false;
				
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel);
			}
			
			
			// rocketman
			else
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
			
			
			// enable doublejump
			if( ( (InTrimp[i] == 1) || (CanDJump[i] == 0) ) && (GetEntityFlags(i) & FL_ONGROUND) )
			{
				CanDJump[i] = true;
				InTrimp[i] = false;
			}
			
			
			// always save this stuff for next time
			WasInJumpLastTime[i] = (GetClientButtons(i) & IN_JUMP);
			WasOnGroundLastTime[i] = (GetEntityFlags(i) & FL_ONGROUND);
			VelLastTime[i][0] = PlayerVel[0];
			VelLastTime[i][1] = PlayerVel[1];
			VelLastTime[i][2] = PlayerVel[2];
		}
	}
}

public ResultType:dhOnEntitySpawned(edict) {
    new String:classname[64];
    GetEdictClassname(edict, classname, sizeof(classname)); 
    if(StrEqual(classname, "tf_projectile_rocket")) { 
		CreateTimer(0.01, ScaleSpeed, edict);
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
		// print entity class name to console
		if(StrEqual(classname, "tf_projectile_rocket")) { 
			new Float:center[3];
			GetEntPropVector(edict, Prop_Send, "m_vecOrigin", center);
			new Float:radius = GetConVarFloat(cvExplosionRadius);
			//new oteam = 0;
			//if (GetClientTeam(client)==3) {oteam=2;} else {oteam=3;}
			FindPlayersInRange2(center, radius, 0, true, edict);
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
	}
	
	return;
}

public Action:Command_ShowInfo(client, args)
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
		if(StringToInt(arg)<0 || StringToInt(arg)>3) {
			ReplyToCommand(client, "Value must be from 0 to 3.");
			return Plugin_Handled;
		}
		showClientInfo[client]=StringToInt(arg);
	}
	return Plugin_Handled;
}

public Action:Timer_ShowInfo(Handle:timer) 
{
	for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) 
		{
			if(GetConVarInt(cvShowInfo)==1)
			{
				if(showClientInfo[i]==1)
				{
					SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);
					ShowSyncHudText(i, HudMessage, "Health: %d, Prim: %d, Sec: %d", GetClientHealth(i), gRemaining1[i], gRemaining2[i]);
				}
				else if(showClientInfo[i]==2)
				{
					SetHudTextParams(0.04, 0.57, 1.0, 255, 50, 50, 255);
					ShowSyncHudText(i, HudMessage, "Prim: %d, Sec: %d", gRemaining1[i], gRemaining2[i]);
				}
				else if(showClientInfo[i]==3)
				{
					SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);
					ShowSyncHudText(i, HudMessage, "Health: %d", GetClientHealth(i));
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

public Cvar_AirAccel(Handle:convar, const String:oldValue[], const String:newValue[]) {
	SetConVarInt(accel, GetConVarInt(cvAirAccel), true);
}


public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	gRemaining1[client] = 0;
	gRemaining2[client] = 0;
	gHolding[client] = HOLD_NONE;
	
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
			if(showClientInfo[client] == 0)
			{
				ShowHudText(client, 1, "%d normal nades, %d special nades", gRemaining1[client], gRemaining2[client]);
			}
			gNadesUsed[client]++;
			throwTime[client] = true;
			CreateTimer(0.5, throwTimer, client);
		}
		else
		{
			if(showClientInfo[client] == 0)
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
			if(showClientInfo[client] == 0)
			{
				ShowHudText(client, 1, "%d normal nades, %d special nades", gRemaining1[client], gRemaining2[client]);
			}
			gNadesUsed[client]++;
			throwTime[client] = true;
			CreateTimer(0.5, throwTimer, client);
		}
		else
		{
			if(showClientInfo[client] == 0)
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

public Action:Command_fov(client, args) {
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
			if(StringToInt(arg)<=0 || StringToInt(arg)>120) {
				ReplyToCommand(client, "Value must be between 1 and 120.");
				return Plugin_Handled;
			}
			//GetClientAuthString(client, clientid, sizeof(clientid));
			
			fov[client] = StringToInt(arg);
			SetEntData(client, offsFOV, fov[client], 4, true);
			SetEntData(client, offsDefaultFOV, fov[client], 4, true);
			//Format(query, sizeof(query), "UPDATE instagib SET fov=%i WHERE steamid='%s'", fov[client], clientid);
			//SQL_TQuery(db, SQLErrorCheckCallback, query);
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
		PrintCenterText(client, "for nades, bind keys to +nade1 and +nade2,/nfor fov tf2c_fov ##,/n for nadesleft tf2c_showinfo #");
		/* Block the client's messsage from broadcasting */
		return Plugin_Handled;
	}
	/* Let say continue normally */
	return Plugin_Continue;
}

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
		}
		if(size==2)
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
		}
		if(showClientInfo[client] == 0)
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
			//SetEntPropString(gNade[client][i], Prop_Data, "m_iName", "tf2nade%d", gNade[client][i]);
			TeleportEntity(gNade[client][i], gHoldingArea, NULL_VECTOR, NULL_VECTOR);
		}
	}
	gNadeNumber[client]=i;
	return gNade[client][i];
}

ThrowNade(client, bool:special=true, bool:Setup)
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
		GetClientEyeAngles(client, angle);
		GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
		speed[2]+=0.2;
		speed[0]*=gnSpeed; speed[1]*=gnSpeed; speed[2]*=gnSpeed;
		
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
		AddVectors(speed, playerspeed, speed);
	
		SetEntityModel( gNade[client][gNadeNumber[client]], gnModel);
		Format(gnSkin, sizeof(gnSkin), "%d", GetClientTeam(client)-2);
		DispatchKeyValue(gNade[client][gNadeNumber[client]], "skin", gnSkin);
		angle[0] = GetRandomFloat(-180.0, 180.0);
		angle[1] = GetRandomFloat(-180.0, 180.0);
		angle[2] = GetRandomFloat(-180.0, 180.0);
		TeleportEntity(gNade[client][gNadeNumber[client]], startpt, angle, speed);
		if (strlen(gnParticle)>0)
		{
			AttachParticle(gNade[client][gNadeNumber[client]], gnParticle, gnDelay);
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
		if(class==SCOUT || class==MEDIC){ tempBool = true; }
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
			IntToString(damage , TempString, 31);
			new Float:origin[3];
			new Float:distance;
			new Float:damageFloat;
			damageFloat = StringToFloat(TempString);
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
					HurtPlayer(j, client, damage, "tf2nade_frag", true, center, 3.0);
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
			PrintToServer("client %d", client);
			EmitSoundToAll(SND_NADE_CONC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
			new oteam;
			if (team==3) {oteam=2;} else {oteam=3;}
			FindPlayersInRange(center, radius, oteam, client, true, gNade[client][jTemp]);
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
					if(tempBool) { ScaleVector(playerspeed, GetConVarFloat(cvHHincrement)); }
					AddVectors(play, playerspeed, play);
					TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, play);
					HurtPlayer(j, client, damage, "tf2nade_conc", false, NULL_VECTOR); 
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
				PrintToServer("client %d", client);
				EmitSoundToAll(SND_NADE_CONC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client][jTemp]);
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
						if(tempBool) { ScaleVector(playerspeed, GetConVarFloat(cvHHincrement)); }
						AddVectors(play, playerspeed, play);
						TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, play);
						HurtPlayer(j, client, damage, "tf2nade_conc", false, NULL_VECTOR); 
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
						HurtPlayer(j, client, damage, "tf2nade_mirv", true, center);
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
				gNadeTimer3[client][jTemp] = INVALID_HANDLE;
				gNadeTimer3[client][jTemp] = CreateDataTimer(gnDelay, MirvExplode2, pack);
				WritePackCell(pack, jTemp);
				WritePackCell(pack, client);
				WritePackCell(pack, team);
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
				new health;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						ShowHealthParticle(j);
						health = GetEntProp(j, Prop_Data, "m_iMaxHealth");
						if (GetClientHealth(j)<health)
						{
							SetEntityHealth(j, health);
						}
					}
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
						HurtPlayer(j, client, damage, "tf2nade_mirv", true, center);
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
				gNadeTimer3[client][jTemp] = INVALID_HANDLE;
				gNadeTimer3[client][jTemp] = CreateDataTimer(gnDelay, MirvExplode2, pack);
				WritePackCell(pack, jTemp);
				WritePackCell(pack, client);
				WritePackCell(pack, team);
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
				damageFloat = StringToFloat(TempString);
				new Float:dynamic_damage;
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						new health = GetClientHealth(j);
						if (damage>=health)
						{
							HurtPlayer(j, client, health-1, "tf2nade_napalm", true, center, 2.0);
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
							HurtPlayer(j, client, damage, "tf2nade_napalm", true, center, 2.0);
						}
						TF2_IgnitePlayer(j, client);
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
						HurtPlayer(j, client, damage, "tf2nade_halluc", false, NULL_VECTOR); 
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
				FindPlayersInRange(center, radius, oteam, client, false, -1);
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
								PrintToServer("m_offset = \"%i\")", entvalue); //Print the value to the HLDS console
								if(entvalue > 0)
								{
									ammoLost = entvalue/4;
									ammoLostScale = ammoLost*400/TFClass_MaxAmmo[iClass][0];
									entvalue=(entvalue/4) * 3;
									PrintToServer("ammoAmount = \"%i\")", entvalue); //Print the value to the HLDS console
									PrintToServer("ammoLost = \"%i\")", ammoLost); //Print the value to the HLDS console
									SetEntData(j, m_Offset+((0+1)*4), entvalue, 4, true); //Set the value of m_iAmmo to -25% of what it was
								}
							}
							else if(StrContains(weaponName, "n_pistol_scout") != -1 || StrContains(weaponName, "n_shotgun_soldier") != -1 || StrContains(weaponName, "n_shotgun_pyro") != -1 || StrContains(weaponName, "n_pipebomblauncher") != -1 || StrContains(weaponName, "n_shotgun_hwg") != -1 || StrContains(weaponName, "n_pistol") != -1 || StrContains(weaponName, "n_smg") != -1 || StrContains(weaponName, "n_flaregun") != -1)
							{
								entvalue=GetEntData(j,m_Offset+8,4);
								PrintToServer("m_offset = \"%i\")", entvalue); //Print the value to the HLDS console
								if(entvalue > 0)
								{
									ammoLost = entvalue/4;
									ammoLostScale = ammoLost*200/TFClass_MaxAmmo[iClass][1];
									entvalue=(entvalue/4) * 3;
									PrintToServer("ammoAmount = \"%i\")", entvalue); //Print the value to the HLDS console
									PrintToServer("ammoLost = \"%i\")", ammoLost); //Print the value to the HLDS console
									SetEntData(j, m_Offset+((1+1)*4), entvalue, 4, true); //Set the value of m_iAmmo to -25% of what it was
								}
							}									
							if(ammoLost > 0)
							{
								
								damage = (ammoLost * 2) + ammoLostScale;
								if(damage < 10){ damage = 10; }
								if(damage > 200){ damage = 200; }
								HurtPlayer(j, client, damage, "tf2nade_EMP", true, center);
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
						if (StrContains(tName, "tf_projectile_")>-1)
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
	if (special==0)
	{
		if(class != MEDIC)
		{
			strcopy(gnModel, sizeof(gnModel), MDL_FRAG);
			gnSpeed = 1500.0;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		else
		{
			strcopy(gnModel, sizeof(gnModel), MDL_CONC);
			gnSpeed = 500.0;
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
			gnSpeed = 500.0;
			gnDelay = GetConVarFloat(cvConcDelay);
			strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
			
		}
		case SNIPER:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_MIRV2);
			gnSpeed = 100.0;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case SOLDIER:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_NAIL);
			gnSpeed = 1000.0;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case DEMO:
		{
			//SetupNade(ENGIE, team, special);
			strcopy(gnModel, sizeof(gnModel), MDL_MIRV1);
			gnSpeed = 1250.0;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case MEDIC:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_HEALTH);
			gnSpeed = 1500.0;
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
			gnSpeed = 1250.0;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case PYRO:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_NAPALM);
			gnSpeed = 1500.0;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case SPY:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_HALLUC);
			gnSpeed = 1500.0;
			gnDelay = 3.0;
			strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
		}
		case ENGIE:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_EMP);
			gnSpeed = 1500.0;
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
			gnSpeed = 1500.0;
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
				HurtPlayer(j, client, GetConVarInt(cvNailDamageNail), "tf2nade_nail", false, center);
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
	new ent[MIRV_PARTS];
	new k;
	for (k=0;k<MIRV_PARTS;k++)
	{
		ent[k] = ReadPackCell(pack);
	}
	gNadeTimer3[client][jTemp] = INVALID_HANDLE;
	new Float:radius = GetConVarFloat(cvMirvRadius);
	new Float:center[3];
	
	for (k=0;k<MIRV_PARTS;k++)
	{
		GetEntPropString(ent[k], Prop_Data, "m_iName", tName, sizeof(tName));
		if (strncmp(tName,"tf2mirv",7)==0)
		{
			new damage = GetConVarInt(cvMirvDamage2);
			GetEntPropVector(ent[k], Prop_Send, "m_vecOrigin", center);
			ShowParticle(center, "ExplosionCore_MidAir", 2.0);
			EmitSoundToAll(SND_NADE_MIRV2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, Float:k * 0.25);
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
	
	angs[1] = g_DrugAngles[GetRandomInt(0,100) % 20];
	angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];
	
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
	PrecacheSound(SND_NADE_HEALTH_TIMER, true);
	
	AddFolderToDownloadTable("models/weapons/nades/duke1");
	AddFolderToDownloadTable("materials/models/weapons/nades/duke1");
	AddFileToDownloadsTable("sound/hallelujah.wav");
	AddFileToDownloadsTable("sound/camera_rewind.wav");
	AddFileToDownloadsTable("sound/bush_fire.wav");
	
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

// players in range setup  (self = 0 if doesn't affect self)
FindPlayersInRange2(Float:location[3], Float:radius, team, bool:trace, donthit)
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
				if ( (team>1 && GetClientTeam(j)==team) || team==0)
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
	PrintCenterTextAll("This server is running the TF2Classic mod./nfor info type /info");
}

setDoorSpeed()
{
	new ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "func_door"))!=-1) 
	{
		PrintToServer("found door %i", ent);
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
			PrintToServer("entity: %i, full name:%s", ent, tName);
			if ((StrContains(tName,"door",false)!=-1) || (StrContains(tName,"gate",false)!=-1))
			{
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

HurtPlayer(client, attacker, damage, String:weapon[256], bool:explosion, Float:pos[3], Float:knockbackmult = 4.0)
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
		SubtractVectors(play, pos, play);
		distance = GetVectorLength(play);
		if (distance<0.01) { distance = 0.01; }
		ScaleVector(play, (1.0/distance)+0.01);
		ScaleVector(play, damage * knockbackmult);
		if(play[2] > (damage * knockbackmult))
		{
			play[2] = damage * knockbackmult;
		}
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
		playerspeed[2]=0.0;
		AddVectors(play, playerspeed, play);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, play);
	}
	
	if (health>damage)
	{
		EmitSoundToAll(sndPain, client);
		SetEntityHealth(client, health-damage);
	}
	else
	{
		KillPlayer(client, attacker, weapon);
	}
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


