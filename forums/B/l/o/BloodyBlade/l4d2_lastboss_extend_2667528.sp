/******************************************************
* 		L4D2: Last Boss (Extended Version) v1.0
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0"
#define DEBUG 0

#define ON				1
#define OFF				0
#define DEAD			-1

#define MOLOTOV 		0
#define EXPLODE 		1

#define TYPE_GHOST		0
#define TYPE_LAVA		1
#define TYPE_GRAVITY	2
#define TYPE_QUAKE		3
#define TYPE_LEAPER		4
#define TYPE_DREAD		5
#define TYPE_FREEZE		6
#define TYPE_LAZY		7
#define TYPE_RABIES		8
#define TYPE_BOMBARD	9
#define TYPE_TREMOR		10

#define FilterSelf 0
#define FilterSelfAndPlayer 1
#define FilterSelfAndSurvivor 2
#define FilterSelfAndInfected 3
#define FilterSelfAndPlayerAndCI 4

/* Model */
#define SURVIVOR	2
#define MOLOTOV 	0
#define EXPLODE 	1
#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"
#define ENTITY_TIRE		"models/props_vehicles/tire001c_car.mdl"
#define ENTITY_ROCK		"models/props_debris/concrete_chunk01a.mdl"


/* Sound */
#define SOUND_EXPLODE	"animation/bombing_run_01.wav"
#define SOUND_BCLAW		"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SOUND_GCLAW		"plats/churchbell_end.wav"
#define SOUND_DCLAW		"ambient/random_amb_sounds/randbridgegroan_03.wav"
#define SOUND_QUAKE		"player/charger/hit/charger_smash_02.wav"
#define SOUND_STEEL		"physics/metal/metal_solid_impact_hard5.wav"
#define SOUND_DEAD		"npc/infected/action/die/male/death_42.wav"
#define SOUND_WARP		"ambient/energy/zap9.wav"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define SOUND_DEFROST	"physics/glass/glass_sheet_break1.wav"
#define SOUND_LAZY		"npc/infected/action/rage/female/rage_68.wav"
#define SOUND_QUICK		"ambient/water/distant_drip2.wav"
#define SOUND_ROAR		"player/tank/voice/pain/tank_fire_08.wav"
#define SOUND_RABIES	"player/pz/voice/attack/zombiedog_attack2.wav"
#define SOUND_BOMBARD	"animation/van_inside_hit_wall.wav"
#define SOUND_TCLAW		"physics/destruction/smash_rockcollapse1.wav"
#define SOUNDMISSILELOCK "UI/Beep07.wav" 

/* Particle */
#define PARTICLE_DEATH	"gas_explosion_main"
#define PARTICLE_WARP	"water_splash"
#define PARTICLE_SMOKE	"apc_wheel_smoke1"
#define PARTICLE_FIRE	"aircraft_destroy_fastFireTrail"

/* Message */

#define MESSAGE_SPAWN00	"\x05Tank is approaching fast! \x04Type-00\x01[GHOST]"
#define MESSAGE_SPAWN01	"\x05Tank is approaching fast! \x04Type-01\x01[LAVA]"
#define MESSAGE_SPAWN02	"\x05Tank is approaching fast! \x04Type-02\x01[GRAVITY]"
#define MESSAGE_SPAWN03	"\x05Tank is approaching fast! \x04Type-03\x01[QUAKE]"
#define MESSAGE_SPAWN04	"\x05Tank is approaching fast! \x04Type-04\x01[LEAPER]"
#define MESSAGE_SPAWN05	"\x05Tank is approaching fast! \x04Type-05\x01[DREAD]"
#define MESSAGE_SPAWN06	"\x05Tank is approaching fast! \x04Type-06\x01[FREEZE]"
#define MESSAGE_SPAWN07	"\x05Tank is approaching fast! \x04Type-07\x01[LAZY]"
#define MESSAGE_SPAWN08	"\x05Tank is approaching fast! \x04Type-08\x01[RABIES]"
#define MESSAGE_SPAWN09	"\x05Tank is approaching fast! \x04Type-09\x01[BOMBARD]"
#define MESSAGE_SPAWN10	"\x05Tank is approaching fast! \x04Type-10\x01[TREMOR]"

/* Parameter */
ConVar sm_lbex_enable;
ConVar sm_lbex_enable_finale;
ConVar sm_lbex_enable_announce;
ConVar sm_lbex_enable_warp;

ConVar sm_lbex_force_type00;
ConVar sm_lbex_force_type01;
ConVar sm_lbex_force_type02;
ConVar sm_lbex_force_type03;
ConVar sm_lbex_force_type04;
ConVar sm_lbex_force_type05;
ConVar sm_lbex_force_type06;
ConVar sm_lbex_force_type07;
ConVar sm_lbex_force_type08;
ConVar sm_lbex_force_type09;
ConVar sm_lbex_force_type10;

ConVar sm_lbex_health_type00;
ConVar sm_lbex_health_type01;
ConVar sm_lbex_health_type02;
ConVar sm_lbex_health_type03;
ConVar sm_lbex_health_type04;
ConVar sm_lbex_health_type05;
ConVar sm_lbex_health_type06;
ConVar sm_lbex_health_type07;
ConVar sm_lbex_health_type08;
ConVar sm_lbex_health_type09;
ConVar sm_lbex_health_type10;

ConVar sm_lbex_color_type00;
ConVar sm_lbex_color_type01;
ConVar sm_lbex_color_type02;
ConVar sm_lbex_color_type03;
ConVar sm_lbex_color_type04;
ConVar sm_lbex_color_type05;
ConVar sm_lbex_color_type06;
ConVar sm_lbex_color_type07;
ConVar sm_lbex_color_type08;
ConVar sm_lbex_color_type09;
ConVar sm_lbex_color_type10;

ConVar sm_lbex_speed_type00;
ConVar sm_lbex_speed_type01;
ConVar sm_lbex_speed_type02;
ConVar sm_lbex_speed_type03;
ConVar sm_lbex_speed_type04;
ConVar sm_lbex_speed_type05;
ConVar sm_lbex_speed_type06;
ConVar sm_lbex_speed_type07;
ConVar sm_lbex_speed_type08;
ConVar sm_lbex_speed_type09;
ConVar sm_lbex_speed_type10;

ConVar sm_lbex_weight_type02;
ConVar sm_lbex_stealth_type00;
ConVar sm_lbex_jumpinterval_type04;
ConVar sm_lbex_jumpheight_type04;
ConVar sm_lbex_gravityinterval_type02;
ConVar sm_lbex_quakeradius_type03;
ConVar sm_lbex_quakeforce_type03;
ConVar sm_lbex_dreadinterval_type05;
ConVar sm_lbex_dreadrate_type05;
ConVar sm_lbex_freeze_type06;
ConVar sm_lbex_freezeinterval_type06;
ConVar sm_lbex_lazy_type07;
ConVar sm_lbex_lazyspeed_type07;
ConVar sm_lbex_rabies_type08;
ConVar sm_lbex_bombard_type09;
ConVar sm_lbex_bombardradius_type09;
ConVar sm_lbex_bombardforce_type09;
ConVar sm_lbex_warp_interval;
ConVar sm_multi_rock_chance_throw;
ConVar sm_multi_rock_damage;
ConVar sm_multi_rock_intervual;
ConVar sm_multi_rock_durtation;
ConVar sm_tracerock_speed;
ConVar sm_star_duration;
ConVar sm_star_fall_speed;
ConVar sm_rock_damage_immunity;

// UserMessageId for Fade.
UserMsg g_FadeUserMsgId;

float ToxinAngle[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

/* Grobal */
int idTank[11] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int idBoss = DEAD;
int alpharate;
int visibility;
int finaleflag = OFF;
int force_default;
int g_iVelocity	= -1;
float ftlPos[3];
int freeze[MAXPLAYERS+1];
bool isSlowed[MAXPLAYERS+1] = false;
static int laggedMovementOffset = 0;
int Rabies[MAXPLAYERS+1];
int Toxin[MAXPLAYERS+1];
float trsPos[MAXPLAYERS+1][3];
int CurrentEnemy[MAXPLAYERS+1];
float FrameTime=0.0;
float FrameDuration=0.0;
bool starfalling = false;
bool g_IsTremor = false;

public Plugin myinfo = 
{
	name = "[L4D2] LAST BOSS (Extended Version)",
	author = "ztar & IxAvnoMonvAxI",
	description = "Special Tank spawns randomly.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

/******************************************************
*	When plugin started
*******************************************************/
public void OnPluginStart()
{
	/* Enable/Disable */
	sm_lbex_enable			= CreateConVar("sm_lbex_enable", "1", "Special Tank spawns randomly.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lbex_enable_finale	= CreateConVar("sm_lbex_enable_finale", "1", "If original LAST BOSS plugin is applied, Turn this OFF.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lbex_enable_announce	= CreateConVar("sm_lbex_enable_announce", "1", "Enable Announcement.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lbex_enable_warp		= CreateConVar("sm_lbex_enable_warp", "0", "Last Boss can use FatalMirror.(0:OFF 1:ON)", FCVAR_NOTIFY);
	
	/* Force */
	sm_lbex_force_type00	 = CreateConVar("sm_lbex_force_type00", "800", "Tank Type-00[GHOST]:Force", FCVAR_NOTIFY);
	sm_lbex_force_type01	 = CreateConVar("sm_lbex_force_type01", "1000", "Tank Type-01[LAVA]:Force", FCVAR_NOTIFY);
	sm_lbex_force_type02	 = CreateConVar("sm_lbex_force_type02", "1000", "Tank Type-02[GRAVITY]:Force", FCVAR_NOTIFY);
	sm_lbex_force_type03	 = CreateConVar("sm_lbex_force_type03", "1000", "Tank Type-03[QUAKE]:Force", FCVAR_NOTIFY);
	sm_lbex_force_type04	 = CreateConVar("sm_lbex_force_type04", "850", "Tank Type-04[LEAPER]:Force", FCVAR_NOTIFY);
	sm_lbex_force_type05	 = CreateConVar("sm_lbex_force_type05", "1000", "Tank Type-05[DREAD]:Force", FCVAR_NOTIFY);
	sm_lbex_force_type06	 = CreateConVar("sm_lbex_force_type06", "800", "Tank Type-06[FREEZE]:Force", FCVAR_NOTIFY);
	sm_lbex_force_type07	 = CreateConVar("sm_lbex_force_type07", "800", "Tank Type-07[LAZY]:Force", FCVAR_NOTIFY);
	sm_lbex_force_type08	 = CreateConVar("sm_lbex_force_type08", "900", "Tank Type-08[RABIES]:Force", FCVAR_NOTIFY);
	sm_lbex_force_type09	 = CreateConVar("sm_lbex_force_type09", "900", "Tank Type-09[BOMBARD]:Force", FCVAR_NOTIFY);
	sm_lbex_force_type10	 = CreateConVar("sm_lbex_force_type10", "1000", "Tank Type-10[TREMOR]:Force", FCVAR_NOTIFY);

	/* Health */
	sm_lbex_health_type00 = CreateConVar("sm_lbex_health_type00", "4000", "Tank Type-00[GHOST]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type01 = CreateConVar("sm_lbex_health_type01", "8000", "Tank Type-01[LAVA]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type02 = CreateConVar("sm_lbex_health_type02", "4000", "Tank Type-02[GRAVITY]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type03 = CreateConVar("sm_lbex_health_type03", "6000", "Tank Type-03[QUAKE]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type04 = CreateConVar("sm_lbex_health_type04", "4000", "Tank Type-04[LEAPER]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type05 = CreateConVar("sm_lbex_health_type05", "6000", "Tank Type-05[DREAD]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type06 = CreateConVar("sm_lbex_health_type06", "6000", "Tank Type-06[FREEZE]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type07 = CreateConVar("sm_lbex_health_type07", "4000", "Tank Type-07[LAZY]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type08 = CreateConVar("sm_lbex_health_type08", "4000", "Tank Type-08[RABIES]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type09 = CreateConVar("sm_lbex_health_type09", "6666", "Tank Type-09[BOMBARD]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type10 = CreateConVar("sm_lbex_health_type10", "8000", "Tank Type-10[TREMOR]:Health", FCVAR_NOTIFY);

	/* Color */
	sm_lbex_color_type00	  = CreateConVar("sm_lbex_color_type00", "80 80 255", "Tank Type-00[GHOST]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type01	  = CreateConVar("sm_lbex_color_type01", "255 80 80", "Tank Type-01[LAVA]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type02	  = CreateConVar("sm_lbex_color_type02", "80 255 80", "Tank Type-02[GRAVITY]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type03	  = CreateConVar("sm_lbex_color_type03", "255 255 80", "Tank Type-03[QUAKE]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type04	  = CreateConVar("sm_lbex_color_type04", "80 255 255", "Tank Type-04[LEAPER]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type05	  = CreateConVar("sm_lbex_color_type05", "90 90 90", "Tank Type-05[DREAD]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type06	  = CreateConVar("sm_lbex_color_type06", "0 128 255", "Tank Type-06[FREEZE]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type07	  = CreateConVar("sm_lbex_color_type07", "200 150 200", "Tank Type-07[LAZY]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type08	  = CreateConVar("sm_lbex_color_type08", "176 48 96", "Tank Type-08[RAIBES]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type09	  = CreateConVar("sm_lbex_color_type09", "153 153 255", "Tank Type-09[BOMBARD]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type10	  = CreateConVar("sm_lbex_color_type10", "128 64 0", "Tank Type-10[TREMOR]:Color(0-255)", FCVAR_NOTIFY);

	/* Speed */
	sm_lbex_speed_type00	  = CreateConVar("sm_lbex_speed_type00", "0.9", "Tank Type-00[GHOST]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type01	  = CreateConVar("sm_lbex_speed_type01", "1.1", "Tank Type-01[LAVA]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type02	  = CreateConVar("sm_lbex_speed_type02", "1.0", "Tank Type-02[GRAVITY]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type03	  = CreateConVar("sm_lbex_speed_type03", "1.0", "Tank Type-03[QUAKE]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type04	  = CreateConVar("sm_lbex_speed_type04", "1.2", "Tank Type-04[LEAPER]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type05	  = CreateConVar("sm_lbex_speed_type05", "1.0", "Tank Type-05[DREAD]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type06 	  = CreateConVar("sm_lbex_speed_type06", "1.2", "Tank Type-06[FREEZE]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type07 	  = CreateConVar("sm_lbex_speed_type07", "0.9", "Tank Type-07[LAZY]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type08 	  = CreateConVar("sm_lbex_speed_type08", "0.9", "Tank Type-08[RAIBES]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type09 	  = CreateConVar("sm_lbex_speed_type09", "1.3", "Tank Type-09[BOMBARD]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type10 	  = CreateConVar("sm_lbex_speed_type10", "1.3", "Tank Type-10[TREMOR]:Speed", FCVAR_NOTIFY);

	/* Skill */
	sm_lbex_weight_type02			= CreateConVar("sm_lbex_weight_type02", "10.0", "Tank Type-02[GRAVITY]:Weight", FCVAR_NOTIFY);
	sm_lbex_stealth_type00			= CreateConVar("sm_lbex_stealth_type00", "10.0", "Tank Type-00[GHOST]:Interval", FCVAR_NOTIFY);
	sm_lbex_jumpinterval_type04		= CreateConVar("sm_lbex_jumpinterval_type04", "1.0", "Tank Type-04[LEAPER]:JumpInterval", FCVAR_NOTIFY);
	sm_lbex_jumpheight_type04		= CreateConVar("sm_lbex_jumpheight_type04", "300.0", "Tank Type-04[LEAPER]:JumpHeight", FCVAR_NOTIFY);
	sm_lbex_gravityinterval_type02	= CreateConVar("sm_lbex_gravityinterval_type02", "6.0", "Tank Type-02[GRAVITY]:Interval", FCVAR_NOTIFY);
	sm_lbex_quakeradius_type03		= CreateConVar("sm_lbex_quakeradius_type03", "500.0", "Tank Type-03[QUAKE]:QuakeRadius", FCVAR_NOTIFY);
	sm_lbex_quakeforce_type03		= CreateConVar("sm_lbex_quakeforce_type03", "300.0", "Tank Type-03[QUAKE]:QuakeForce", FCVAR_NOTIFY);
	sm_lbex_dreadinterval_type05	= CreateConVar("sm_lbex_dreadinterval_type05", "8.0", "Tank Type-05[DREAD]:BlindInterval", FCVAR_NOTIFY);
	sm_lbex_dreadrate_type05		= CreateConVar("sm_lbex_dreadrate_type05", "235", "Tank Type-05[DREAD]:BlindRate", FCVAR_NOTIFY);
	sm_lbex_freeze_type06		    = CreateConVar("sm_lbex_freeze_type06", "10", "Tank Type-06[FREEZE]:FreezeTime", FCVAR_NOTIFY);
	sm_lbex_freezeinterval_type06	= CreateConVar("sm_lbex_freezeinterval_type06", "6.0", "Tank Type-06[FREEZE]:FreezeInterval", FCVAR_NOTIFY);
	sm_lbex_lazy_type07			    = CreateConVar("sm_lbex_lazy_type07", "10.0", "Tank Type-07[LAZY]:LazyTime", FCVAR_NOTIFY);
	sm_lbex_lazyspeed_type07		= CreateConVar("sm_lbex_lazyspeed_type07", "0.3", "Tank Type-07[LAZY]:LazySpeed", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_lbex_rabies_type08			= CreateConVar("sm_lbex_rabies_type08", "10.0", "Tank Type-08[RABIES]:RabiesTime", FCVAR_NOTIFY);
	CreateConVar("sm_lbex_rabiesdamage_type08", "5", "Tank Type-08[RABIES]:RabiesDamage", FCVAR_NOTIFY);
	CreateConVar("sm_lbex_lavadamage_type01", "150", "Tank Type-01[LAVA]:LavaDamage", FCVAR_NOTIFY);
	sm_lbex_bombard_type09		    = CreateConVar("sm_lbex_bombard_type09", "300", "Tank Type-10[BOMBARD]:BombDamage", FCVAR_NOTIFY);
	sm_lbex_bombardradius_type09	= CreateConVar("sm_lbex_bombardradius_type09", "250", "Tank Type-10[BOMBARD]:BombRadius", FCVAR_NOTIFY);
	sm_lbex_bombardforce_type09		= CreateConVar("sm_lbex_bombardforce_type09", "600.0", "Tank Type-10[BOMBARD]:BombForce", FCVAR_NOTIFY);
	sm_lbex_warp_interval		    = CreateConVar("sm_lbex_warp_interval", "35.0", "Fatal Mirror skill:Interval(all form)", FCVAR_NOTIFY);
	sm_multi_rock_chance_throw = 	CreateConVar("sm_multi_rock_chance_throw", "65", "Type-10[TREMOR]:Chance of throw multi-rock when tank throw rock, unseless [0.0, 100.0]", FCVAR_NOTIFY);
	sm_multi_rock_damage	=      	CreateConVar("sm_multi_rock_damage", "20", "Tank Type-10[TREMOR]:Damage of rock[1.0, 100.0]", FCVAR_NOTIFY);
	sm_multi_rock_intervual	 = 	CreateConVar("sm_multi_rock_intervual", "0.5", "Tank Type-10[TREMOR]:Multi rock throw intervual", FCVAR_NOTIFY);
	sm_multi_rock_durtation	 = 	CreateConVar("sm_multi_rock_durtation", "5.0", "Tank Type-10[TREMOR]:Multi rock duration", FCVAR_NOTIFY);
	sm_tracerock_speed 	      = CreateConVar("sm_tracerock_speed", "300", "Tank Type-10[TREMOR]:Trace rock's speed", FCVAR_NOTIFY);
	sm_star_duration 		=	    CreateConVar("sm_star_duration", "5", "Tank Type-10[TREMOR]:Starfall duration", FCVAR_NOTIFY);
	sm_star_fall_speed	=	    CreateConVar("sm_star_fall_speed", "450", "Tank Type-10[TREMOR]:Fall speed of rock", FCVAR_NOTIFY);
	sm_rock_damage_immunity	=   CreateConVar("sm_rock_damage_immunity", "1", "Tank Type-10[TREMOR]:Enable self rock damage immunity?", FCVAR_NOTIFY);
	
	/* Event hook */
	HookEvent("round_start", Event_Round_Start);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_incapacitated", Event_Player_Hurt);
	HookEvent("finale_start", Event_Finale_Start);
	HookEvent("round_end", Event_RoundEnd);

	g_FadeUserMsgId = GetUserMessageId("Fade");

	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	
	AutoExecConfig(true, "l4d2_lastboss_extend");
	
	force_default = GetConVarInt(FindConVar("z_tank_throw_force"));
	if((g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]")) == -1)
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
}

/******************************************************
*	Initial functions
*******************************************************/
void InitPrecache()
{
	/* Precache models */
	PrecacheModel(ENTITY_PROPANE, true);
	PrecacheModel(ENTITY_GASCAN, true);
	PrecacheModel(ENTITY_TIRE, true);
	PrecacheModel(ENTITY_ROCK, true);

	/* Precache sounds */
	PrecacheSound(SOUND_EXPLODE, true);
	PrecacheSound(SOUND_BCLAW, true);
	PrecacheSound(SOUND_GCLAW, true);
	PrecacheSound(SOUND_DCLAW, true);
	PrecacheSound(SOUND_QUAKE, true);
	PrecacheSound(SOUND_STEEL, true);
	PrecacheSound(SOUND_DEAD, true);
	PrecacheSound(SOUND_FREEZE, true);
	PrecacheSound(SOUND_DEFROST, true);
	PrecacheSound(SOUND_LAZY, true);
	PrecacheSound(SOUND_QUICK, true);
	PrecacheSound(SOUND_RABIES, true);
	PrecacheSound(SOUND_BOMBARD, true);
	PrecacheSound(SOUND_WARP, true);
	PrecacheSound(SOUND_TCLAW, true);
	PrecacheSound(SOUNDMISSILELOCK, true);

	/* Precache particles */
	PrecacheParticle(PARTICLE_DEATH);
	PrecacheParticle(PARTICLE_SMOKE);
	PrecacheParticle(PARTICLE_FIRE);
	PrecacheParticle(PARTICLE_WARP);
}

void InitData()
{
	for(int i = 0; i < 10; i++)
	{
		idTank[i] = 0;
	}
	idBoss = DEAD;
	finaleflag = OFF;
	
	starfalling = false;
	g_IsTremor = false;
	
	SetConVarInt(FindConVar("z_tank_throw_force"), force_default, true, true);
}

public void OnMapStart()
{
	InitPrecache();
	InitData();

	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheModel("models/props_junk/gascan001a.mdl", true);

	PrecacheParticle("gas_explosion_pump");
	PrecacheParticle("gas_explosion_main");
}

public void OnMapEnd()
{
	InitData();
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	InitData();
}

public Action Event_Finale_Start(Event event, const char[] name, bool dontBroadcast)
{
	finaleflag = ON;
}

/******************************************************
*	Event when Tank has spawned or dead
*******************************************************/
public Action Event_Tank_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!GetConVarInt(sm_lbex_enable) || (!GetConVarInt(sm_lbex_enable_finale) && finaleflag))
		return;
	
	if(idTank[0] && idTank[1] && idTank[2] && idTank[3] && idTank[4] && idTank[5] && idTank[6] && idTank[7] && idTank[8] && idTank[9] && idTank[10])
		return;

	int idTankSpawn = GetClientOfUserId(GetEventInt(event, "userid"));
	int type = GetRandomInt(0, 10);
	
	if (type >= 0 && type <= 10)
	{
		if (type != 0 || (type == 0))
		{
			type = GetRandomInt(0, 10);
		}
		
		idTank[type] = idTankSpawn;
		
		idBoss = idTankSpawn;

		if(IsValidEntity(idTank[type]) && IsClientInGame(idTank[type]))
		{
			SetTankStatus(type);
		}
	}
}

public void SetTankStatus(int type)
{
	int force;
	int health;
	float speed;
	char color[32];
	
	/* Type-00[GHOST] */
	if(type == TYPE_GHOST)
	{
		force = GetConVarInt(sm_lbex_force_type00);
		health = GetConVarInt(sm_lbex_health_type00);
		speed  = GetConVarFloat(sm_lbex_speed_type00);
		GetConVarString(sm_lbex_color_type00, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			PrintToChatAll(MESSAGE_SPAWN00);
			PrintToChatAll("  Helath:%d  SpeedRate:%.1f", health, speed);
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			/* Skill:Fatal Mirror (Teleport near the survivor) */
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
		/* Skill:Stealth Skin */
		CreateTimer(GetConVarFloat(sm_lbex_stealth_type00), StealthTimer);
	}
	/* Type-01[LAVA] */
	else if(type == TYPE_LAVA)
	{
		force = GetConVarInt(sm_lbex_force_type01);
		health = GetConVarInt(sm_lbex_health_type01);
		speed = GetConVarFloat(sm_lbex_speed_type01);
		GetConVarString(sm_lbex_color_type01, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			PrintToChatAll(MESSAGE_SPAWN01);
			PrintToChatAll("  Helath:%d  SpeedRate:%.1f", health, speed);
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			/* Skill:Fatal Mirror (Teleport near the survivor) */
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}
	/* Type-02[GRAVITY] */
	else if(type == TYPE_GRAVITY)
	{
		force = GetConVarInt(sm_lbex_force_type02);
		health = GetConVarInt(sm_lbex_health_type02);
		speed = GetConVarFloat(sm_lbex_speed_type02);
		GetConVarString(sm_lbex_color_type02, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			PrintToChatAll(MESSAGE_SPAWN02);
			PrintToChatAll("  Helath:%d  SpeedRate:%.1f", health, speed);
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			/* Skill:Fatal Mirror (Teleport near the survivor) */
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
		/* Weight increase */
		SetEntityGravity(idTank[type], GetConVarFloat(sm_lbex_weight_type02));	
	}
	/* Type-03[QUAKE] */
	else if(type == TYPE_QUAKE)
	{
		force = GetConVarInt(sm_lbex_force_type03);
		health = GetConVarInt(sm_lbex_health_type03);
		speed = GetConVarFloat(sm_lbex_speed_type03);
		GetConVarString(sm_lbex_color_type03, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			PrintToChatAll(MESSAGE_SPAWN03);
			PrintToChatAll("  Helath:%d  SpeedRate:%.1f", health, speed);
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			/* Skill:Fatal Mirror (Teleport near the survivor) */
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}
	/* Type-04[LEAPER] */
	else if(type == TYPE_LEAPER)
	{
		force = GetConVarInt(sm_lbex_force_type04);
		health = GetConVarInt(sm_lbex_health_type04);
		speed = GetConVarFloat(sm_lbex_speed_type04);
		GetConVarString(sm_lbex_color_type04, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			PrintToChatAll(MESSAGE_SPAWN04);
			PrintToChatAll("  Helath:%d  SpeedRate:%.1f", health, speed);
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			/* Skill:Fatal Mirror (Teleport near the survivor) */
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
		/* Skill:Mad Spring */
		CreateTimer(GetConVarFloat(sm_lbex_jumpinterval_type04), JumpingTimer, _, TIMER_REPEAT);

		float Origin[3], Angles[3];
		GetEntPropVector(idTank[TYPE_LEAPER], Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(idTank[TYPE_LEAPER], Prop_Send, "m_angRotation", Angles);
		Angles[0] += 90.0;
		int ent[3];
		for (int count=1; count<=2; count++)
		{
			ent[count] = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(ent[count]))
			{
				char tName[64];
				Format(tName, sizeof(tName), "Tank%d", idTank[TYPE_LEAPER]);
				DispatchKeyValue(idTank[TYPE_LEAPER], "targetname", tName);
				GetEntPropString(idTank[TYPE_LEAPER], Prop_Data, "m_iName", tName, sizeof(tName));

				DispatchKeyValue(ent[count], "model", ENTITY_TIRE);
				DispatchKeyValue(ent[count], "targetname", "TireEntity");
				DispatchKeyValue(ent[count], "parentname", tName);
				GetConVarString(sm_lbex_color_type04, color, sizeof(color));
				DispatchKeyValue(ent[count], "rendercolor", color);
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
				SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", idTank[TYPE_LEAPER]);
				TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	/* Type-05[DREAD] */
	else if(type == TYPE_DREAD)
	{
		force = GetConVarInt(sm_lbex_force_type05);
		health = GetConVarInt(sm_lbex_health_type05);
		speed = GetConVarFloat(sm_lbex_speed_type05);
		GetConVarString(sm_lbex_color_type05, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			PrintToChatAll(MESSAGE_SPAWN05);
			PrintToChatAll("  Helath:%d  SpeedRate:%.1f", health, speed);
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			/* Skill:Fatal Mirror (Teleport near the survivor) */
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}
	/* Type-06[FREEZE] */
	else if(type == TYPE_FREEZE)
	{
		force = GetConVarInt(sm_lbex_force_type06);
		health = GetConVarInt(sm_lbex_health_type06);
		speed = GetConVarFloat(sm_lbex_speed_type06);
		GetConVarString(sm_lbex_color_type06, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			PrintToChatAll(MESSAGE_SPAWN06);
			PrintToChatAll("  Helath:%d  SpeedRate:%.1f", health, speed);
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			/* Skill:Fatal Mirror (Teleport near the survivor) */
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}
	/* Type-07[LAZY] */
	else if(type == TYPE_LAZY)
	{
		force = GetConVarInt(sm_lbex_force_type07);
		health = GetConVarInt(sm_lbex_health_type07);
		speed = GetConVarFloat(sm_lbex_speed_type07);
		GetConVarString(sm_lbex_color_type07, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			PrintToChatAll(MESSAGE_SPAWN07);
			PrintToChatAll("  Helath:%d  SpeedRate:%.1f", health, speed);
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			/* Skill:Fatal Mirror (Teleport near the survivor) */
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}
	/* Type-08[RABIES] */
	else if(type == TYPE_RABIES)
	{
		force = GetConVarInt(sm_lbex_force_type08);
		health = GetConVarInt(sm_lbex_health_type08);
		speed = GetConVarFloat(sm_lbex_speed_type08);
		GetConVarString(sm_lbex_color_type08, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			PrintToChatAll(MESSAGE_SPAWN08);
			PrintToChatAll("  Helath:%d  SpeedRate:%.1f", health, speed);
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			/* Skill:Fatal Mirror (Teleport near the survivor) */
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}
	/* Type-09[BOMBARD] */
	else if(type == TYPE_BOMBARD)
	{
		force = GetConVarInt(sm_lbex_force_type09);
		health = GetConVarInt(sm_lbex_health_type09);
		speed = GetConVarFloat(sm_lbex_speed_type09);
		GetConVarString(sm_lbex_color_type09, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			PrintToChatAll(MESSAGE_SPAWN09);
			PrintToChatAll("  Helath:%d  SpeedRate:%.1f", health, speed);
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			/* Skill:Fatal Mirror (Teleport near the survivor) */
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}
	/* Type-10[TREMOR] */
	else if(type == TYPE_TREMOR)
	{
		g_IsTremor = true;
		
		force = GetConVarInt(sm_lbex_force_type10);
		health = GetConVarInt(sm_lbex_health_type10);
		speed = GetConVarFloat(sm_lbex_speed_type10);
		GetConVarString(sm_lbex_color_type10, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			PrintToChatAll(MESSAGE_SPAWN10);
			PrintToChatAll("  Helath:%d  SpeedRate:%.1f", health, speed);
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			/* Skill:Fatal Mirror (Teleport near the survivor) */
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
		
		float Origin[3], Angles[3];
		GetEntPropVector(idTank[TYPE_TREMOR], Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(idTank[TYPE_TREMOR], Prop_Send, "m_angRotation", Angles);
		int ent[5];
		for (int count = 1; count <= 4; count++)
		{
			ent[count] = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(ent[count]))
			{
				char tName[64];
				Format(tName, sizeof(tName), "Tank%d", idTank[TYPE_TREMOR]);
				DispatchKeyValue(idTank[TYPE_TREMOR], "targetname", tName);
				GetEntPropString(idTank[TYPE_TREMOR], Prop_Data, "m_iName", tName, sizeof(tName));

				DispatchKeyValue(ent[count], "model", ENTITY_ROCK);
				DispatchKeyValue(ent[count], "targetname", "RockEntity");
				DispatchKeyValue(ent[count], "parentname", tName);
				GetConVarString(sm_lbex_color_type10, color, sizeof(color));
				DispatchKeyValue(ent[count], "rendercolor", color);
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
					case 1,2:SetEntPropFloat(ent[count], Prop_Data, "m_flModelScale", 0.6);
					case 3,4:SetEntPropFloat(ent[count], Prop_Data, "m_flModelScale", 0.7);
				}
				SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", idTank[TYPE_TREMOR]);
				Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
				Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
				Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
				TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	
	/* Setup basic status */
	SetEntityHealth(idTank[type], health);
	SetEntPropFloat(idTank[type], Prop_Send, "m_flLaggedMovementValue", speed);
	SetEntityRenderMode(idTank[type], view_as<RenderMode>(0));
	DispatchKeyValue(idTank[type], "rendercolor", color);
	
	SetConVarInt(FindConVar("z_tank_throw_force"), force, true, true);
}

public Action Event_Player_Death(Event event, const char[] name, bool dontBroadcast)
{
	int idTankDead = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!GetConVarInt(sm_lbex_enable) || (!GetConVarInt(sm_lbex_enable_finale) && finaleflag))
		return;
	if(idTankDead <= 0 || idTankDead > GetMaxClients())
		return;
	if(!IsValidEntity(idTankDead) || !IsClientInGame(idTankDead))
		return;
	if(GetEntProp(idTankDead, Prop_Send, "m_zombieClass") != 8)
		return;

	if(idTankDead == idTank[TYPE_GHOST])
		idTank[TYPE_GHOST] = 0;
	else if(idTankDead == idTank[TYPE_LAVA])
		idTank[TYPE_LAVA] = 0;
	else if(idTankDead == idTank[TYPE_GRAVITY])
		idTank[TYPE_GRAVITY] = 0;
	else if(idTankDead == idTank[TYPE_QUAKE])
		idTank[TYPE_QUAKE] = 0;
	else if(idTankDead == idTank[TYPE_LEAPER])
		idTank[TYPE_LEAPER] = 0;
	else if(idTankDead == idTank[TYPE_DREAD])
		idTank[TYPE_DREAD] = 0;
	else if(idTankDead == idTank[TYPE_FREEZE])
		idTank[TYPE_FREEZE] = 0;
	else if(idTankDead == idTank[TYPE_LAZY])
		idTank[TYPE_LAZY] = 0;
	else if(idTankDead == idTank[TYPE_RABIES])
		idTank[TYPE_RABIES] = 0;
	else if(idTankDead == idTank[TYPE_BOMBARD])
		idTank[TYPE_BOMBARD] = 0;
	else if(idTankDead == idTank[TYPE_TREMOR])
		idTank[TYPE_TREMOR] = 0;

	/* Explode and burn when died */
	if(idTankDead)
	{
		float Pos[3];
		GetClientAbsOrigin(idTankDead, Pos);
		EmitSoundToAll(SOUND_EXPLODE, idTankDead);
		ShowParticle(Pos, PARTICLE_DEATH, 5.0);
		LittleFlower(Pos, MOLOTOV);
		LittleFlower(Pos, EXPLODE);
		
		starfalling=false;
	}
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
	{
		char model[128];
            	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, ENTITY_TIRE) && StrEqual(model, ENTITY_ROCK))
		{
			int OwnerEntity = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			
			if (OwnerEntity != idTankDead) 
			{
				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", idTankDead);
			}
			
			AcceptEntityInput(entity, "Kill");
		}
	}

	for (int target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target) && GetClientTeam(target) == 2)
		{
			isSlowed[target] = false;
			SetEntityGravity(target, 1.0);
			Rabies[target] = 0;
			Toxin[target] = 0;
		}
	}
}


public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int target = 1; target<=MaxClients; target++)
	{
		if (IsClientInGame(target) && GetClientTeam(target) == 2)
		{
			isSlowed[target] = false;
			SetEntityGravity(target, 1.0);
			Rabies[target] = 0;
			Toxin[target] = 0;
		}
	}
	starfalling = false;
	g_IsTremor = false;
}

/******************************************************
*	Special skills when attacking
*******************************************************/
public Action Event_Player_Hurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!GetConVarInt(sm_lbex_enable) || (!GetConVarInt(sm_lbex_enable_finale) && finaleflag))
		return;
	
	char weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	/* Tank primary attack */
	if(StrEqual(weapon, "tank_claw"))
	{
		if(attacker == idTank[TYPE_LAVA])
		{
			/* Skill:Burning Claw */
			SkillBurnClaw(target);
		}
		else if(attacker == idTank[TYPE_GRAVITY])
		{
			/* Skill:Gravity Claw */
			SkillGravityClaw(target);
		}
		else if(attacker == idTank[TYPE_QUAKE])
		{
			/* Skill:Earth Quake */
			SkillEarthQuake(target);
		}
		else if(attacker == idTank[TYPE_DREAD])
		{
			/* Skill:Dread Claw */
			SkillDreadClaw(target);
		}
		else if(attacker == idTank[TYPE_FREEZE])
		{
			/* Skill:Freeze Claw */
			SkillFreezeClaw(target);
		}
		else if(attacker == idTank[TYPE_LAZY])
		{
			/* Skill:Lazy Claw */
			SkillLazyClaw(target);
		}
		else if(attacker == idTank[TYPE_RABIES])
		{
			/* Skill:Rabies Claw */
			SkillRabiesClaw(target);
		}
		else if(attacker == idTank[TYPE_BOMBARD])
		{
			/* Skill:Bomb Claw */
			SkillBombClaw(target);
		}
		else if(g_IsTremor && (attacker == idTank[TYPE_TREMOR]))
		{
			/* Skill:Bomb Claw */
			SkillTremorClaw(target);
		}
	}

	/* Tank secondly attack */
	if(StrEqual(weapon, "tank_rock"))
	{
		if(attacker == idTank[TYPE_LAVA])
		{
			/* Skill:Comet Strike */
			SkillCometStrike(target, MOLOTOV);
		}
		else if(attacker == idTank[TYPE_QUAKE])
		{
			/* Skill:Blast Rock */
			SkillCometStrike(target, EXPLODE);
		}
		else if(attacker == idTank[TYPE_BOMBARD])
		{
			/* Skill:Blast Rock */
			SkillCometStrike(target, EXPLODE);
		}
	}

	if(StrEqual(weapon, "melee"))
	{
		if(GetEntProp(target, Prop_Send, "m_zombieClass") == 8)
		{
			if(target == idTank[TYPE_GRAVITY])
			{
				/* Skill:Steel Skin */
				EmitSoundToClient(attacker, SOUND_STEEL);
				SetEntityHealth(idTank[TYPE_GRAVITY], (GetEventInt(event,"dmg_health")+GetEventInt(event,"health")));
			}
			else if(target == idTank[TYPE_LAVA])
			{
				/* Skill:Flame Gush */
				SkillFlameGush(attacker);
			}
			else if(target == idTank[TYPE_GHOST])
			{
				int random = GetRandomInt(1,4);
				if (random == 1)
				{
					ForceWeaponDrop(attacker);
					EmitSoundToClient(attacker, SOUND_DEAD);
				}
			}
			else if(g_IsTremor && (target == idTank[TYPE_TREMOR]))
			{
				int random = GetRandomInt(1,4);
				if (random == 1)
				{
					StartStarFall(attacker);
				}
			}
		}
	}
	else
	{
		if(GetEntProp(target, Prop_Send, "m_zombieClass") == 8)
		{
			if(target == idTank[TYPE_LAVA])
			{
				/* Ignite */
				if(IsPlayerIgnited(idTank[TYPE_LAVA]))
					return;
				IgniteEntity(idTank[TYPE_LAVA], 9999.9);
			}
		}
	}
}

void StartStarFall(int client)
{
	float pos[3];
	
	GetClientEyePosition(client, pos);
	pos[2] += 20.0;
	
	Handle h = CreateDataPack(); 
	int ent = CreateEntityByName("env_rock_launcher");
	DispatchSpawn(ent); 
	char damagestr[32];
	GetConVarString(sm_multi_rock_damage, damagestr, 32);
	DispatchKeyValue(ent, "rockdamageoverride", damagestr);
	
	WritePackCell(h, client);
	WritePackCell(h, ent);
	WritePackFloat(h, pos[0]);
	WritePackFloat(h, pos[1]);
	WritePackFloat(h, pos[2]);
	WritePackFloat(h,GetEngineTime());
	starfalling=true;
	CreateTimer(0.2, UpdateStarFall, h, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	//PrintToChatAll("Meteor Shower!");
}

public Action UpdateStarFall(Handle timer, any h)
{
	ResetPack(h);
	float pos[3];
	int client = ReadPackCell(h);
	int ent = ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);

	float time = ReadPackFloat(h); 
	bool quit = false;
	if(ent > 0 && IsValidEdict(ent))
	{
		float angle[3];
		float hitpos[3];
		angle[0] = 0.0 + GetRandomFloat(-1.0, 1.0);
		angle[1] = 0.0 + GetRandomFloat(-1.0, 1.0);
		angle[2] = 2.0;
		
		GetVectorAngles(angle, angle);
		
		GetRayHitPos2(pos, angle, hitpos, client,0.0);
		float dis = GetVectorDistance(pos, hitpos);
		if(GetVectorDistance(pos, hitpos)>800.0)
		{
			dis = 800.0;
		}
		float t[3];
		MakeVectorFromPoints(pos, hitpos, t);
		NormalizeVector(t,t);
		ScaleVector(t, dis - 40.0);
		AddVectors(pos, t, hitpos);
		
		if(dis > 300.0)
		{ 
			if(ent > 0)
			{
				float angle2[3];
				angle2[0] = GetRandomFloat(-1.0, 1.0);
				angle2[1] = GetRandomFloat(-1.0, 1.0);
				angle2[2] =- 2.0;
				GetVectorAngles(angle2, angle2);
				TeleportEntity(ent, hitpos, angle2, NULL_VECTOR);
				AcceptEntityInput(ent, "LaunchRock");  
			}
		}
	}
	else quit = true;
	if(GetEngineTime() - time > GetConVarFloat(sm_star_duration) || quit)
	{
		starfalling=false;
		CloseHandle(h); 
		if(!quit)AcceptEntityInput(ent, "kill");
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "tank_rock"))
	{
		if(!starfalling)
		{
			if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
			{
				if (g_IsTremor && (idBoss == idTank[TYPE_TREMOR]))
				{
					float r = GetRandomFloat(0.0, 100.0); 
					if(r < GetConVarFloat(sm_multi_rock_chance_throw))
					{
						int integer = GetRandomInt(1, 2);
						switch (integer)
						{
							case 1:
							{
								float pos[3];
								Handle h = CreateDataPack();
								WritePackFloat(h, GetEngineTime());
								GetClientEyePosition(idBoss, pos);
								WritePackFloat(h, pos[0]); 
								WritePackFloat(h, pos[1]);
								WritePackFloat(h, pos[2]+80.0);
								CurrentEnemy[idBoss]=0;
								WritePackCell(h, idBoss);
								float count = 0.0;
								for(int i = CurrentEnemy[idBoss] + 1; i <= MaxClients; i++)
								{
									if(IsClientInGame(i) && GetClientTeam(i)==2 && IsPlayerAlive(i) && !IsFakeClient(i))
									{
										count+=1.0;
									} 
								}
								if(count==0.0)count=1.0; 
								CreateTimer(GetConVarFloat(sm_multi_rock_intervual), TimerDeadTankMulitRock, h, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
								//PrintToChatAll("\x04Watch the tank's rock!");
							}
							
							case 2:
							{
								CreateTimer(1.1, StartTimer, entity, TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
				}
			}
		}
		
		if(starfalling)
		{
			if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
			{
				if (g_IsTremor && (idBoss == idTank[TYPE_TREMOR]))
				{
					int OwnerEntity = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
					if (OwnerEntity != idBoss) 
					{
						SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", idBoss);
					}
					SetEntityGravity(entity, 0.8);
					CreateTimer(0.1, SetStarVol, entity, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action SetStarVol(Handle timer, any star)
{
	if(star > 0 && IsValidEdict(star))
	{
		float v[3];
		GetEntDataVector(star, g_iVelocity, v);
		NormalizeVector(v,v);
		ScaleVector(v, GetConVarFloat(sm_star_fall_speed));
		TeleportEntity(star, NULL_VECTOR, NULL_VECTOR, v);
	}
}

public Action TimerDeadTankMulitRock(Handle timer, Handle h)
{
	ResetPack(h, false);
	float starttime = ReadPackFloat(h);
	float eyepos[3];
	eyepos[0] = ReadPackFloat(h);
	eyepos[1] = ReadPackFloat(h);
	eyepos[2] = ReadPackFloat(h);
	int client = ReadPackCell(h); 
	
	if(starttime + GetConVarFloat(sm_multi_rock_durtation) < GetEngineTime())
	{
		CloseHandle(h);
		return Plugin_Stop;
	}
	
	int b = NextPlayer(client);
	if(!b) b = NextPlayer(client);
	if(!b) return Plugin_Continue;
	int enemy = CurrentEnemy[client];
	
	StartMultiRock2(eyepos, enemy);
	
	CloseHandle(h);
	return Plugin_Stop;
}

bool NextPlayer(int client)
{
	bool find = false;
	for(int i = CurrentEnemy[client] + 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==2 && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			find = true;
			CurrentEnemy[client]=i;
			break;
		} 
	}
	if(!find)
	{
		CurrentEnemy[client]=0;
	}
	return find;
}

Action StartMultiRock2(float eyePos[3], int enemy)
{
	float eyepos[3];
	CopyVector(eyePos, eyepos); 
	char damagestr[32];
	GetConVarString(sm_multi_rock_damage,damagestr, 32);
	
	int ent = CreateEntityByName("env_rock_launcher");
	DispatchSpawn(ent); 
	DispatchKeyValue(ent, "rockdamageoverride", damagestr);
	
	TeleportEntity(ent, eyepos, NULL_VECTOR,NULL_VECTOR );
	//PrintCenterText(enemy, "watch the rock!");
	
	SetVariantEntity(enemy);
	AcceptEntityInput(ent, "SetTarget" );
	AcceptEntityInput(ent, "LaunchRock");
	AcceptEntityInput(ent, "kill"); 
	//PrintToChat(1, "rock %N", enemy);

	return Plugin_Continue;
}

public Action StartTimer(Handle timer, any ent)
{ 
	if(ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
	{ 
		char classname[32];
		GetEdictClassname(ent, classname, sizeof(classname));
		if(StrEqual(classname, "tank_rock" ))
		{
			int OwnerEntity = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
			if (OwnerEntity != idBoss) 
			{
				SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", idBoss);
			}
			StartRockTrace(ent);
		}
	}
}

void StartRockTrace(int ent)
{ 
	//new h = GetConVarInt(l4d_tracerock_health);
	//if(h > 0)SetEntProp(ent, Prop_Data, "m_iHealth", h);
	SDKUnhook(ent, SDKHook_Think, PreThink);
	SDKHook(ent, SDKHook_Think, PreThink);
}

public void OnGameFrame()
{
	float time = GetEngineTime(); 
	FrameDuration = time - FrameTime; 
	FrameTime = time;
	if(FrameDuration > 0.1) FrameDuration = 0.1;
	if(FrameDuration == 0.0) FrameDuration = 0.01;
}

public void PreThink(int ent)
{
	if(ent > 0 && IsValidEntity(ent) && IsValidEdict(ent))
	{ 
		TraceMissile(ent, FrameDuration);
	}
	else
	{
		SDKUnhook(ent, SDKHook_Think, PreThink);
	}
}

void TraceMissile(int ent, float duration)
{
	float posmissile[3];
	float velocitymissile[3];
	
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", posmissile);
	GetEntDataVector(ent, g_iVelocity, velocitymissile);
	if(GetVectorLength(velocitymissile)<50.0)return;
	
	NormalizeVector(velocitymissile, velocitymissile);
	
	int enemyteam = 2;
	
	int enemy = GetEnemy(posmissile, velocitymissile, enemyteam);
	
	float velocityenemy[3];
	float vtrace[3];
	
	vtrace[0] = vtrace[1] = vtrace[2] = 0.0;
	bool visible = false;
	float missionangle[3];
	
	float disenemy = 1000.0;
	
	if(enemy > 0)
	{
		float posenemy[3];
		GetClientEyePosition(enemy, posenemy);
		
		disenemy = GetVectorDistance(posmissile, posenemy);
		 
		visible = IfTwoPosVisible(posmissile, posenemy, ent);
		
		//if(visible)PrintToChatAll("%N visible %f ", client, disenemy);
		GetEntDataVector(enemy, g_iVelocity, velocityenemy);

		ScaleVector(velocityenemy, duration);

		AddVectors(posenemy, velocityenemy, posenemy);
		MakeVectorFromPoints(posmissile, posenemy, vtrace);
		//PrintToChatAll("%N lock %N D:%f", client,enemy, disenemy); 
	}
	
	////////////////////////////////////////////////////////////////////////////////////
	GetVectorAngles(velocitymissile, missionangle);

	float vleft[3];
	float vright[3];
	float vup[3];
	float vdown[3];
	float vfront[3];
	float vv1[3];
	float vv2[3];
	float vv3[3];
	float vv4[3];
	float vv5[3];
	float vv6[3];
	float vv7[3];
	float vv8[3];
	
	vfront[0] = vfront[1] = vfront[2] = 0.0;
	
	float factor2 = 0.5;
	float factor1 = 0.2; 
	float t;
	float base = 1500.0;
	if(visible)
	{
		base = 80.0;
	}
	{
		//PrintToChatAll("%f %f %f %f %f",front, up, down, left, right);
		int flag = FilterSelfAndSurvivor;
		int self = ent;
		float front = CalRay(posmissile, missionangle, 0.0, 0.0, vfront, self, flag);

		float down = CalRay(posmissile, missionangle, 90.0, 0.0, vdown, self, flag);
		float up = CalRay(posmissile, missionangle, -90.0, 0.0, vup, self);
		float left = CalRay(posmissile, missionangle, 0.0, 90.0, vleft, self, flag);
		float right = CalRay(posmissile, missionangle, 0.0, -90.0, vright, self, flag);

		float f1 = CalRay(posmissile, missionangle, 30.0, 0.0, vv1, self, flag);
		float f2 = CalRay(posmissile, missionangle, 30.0, 45.0, vv2, self, flag);
		float f3 = CalRay(posmissile, missionangle, 0.0, 45.0, vv3, self, flag);
		float f4 = CalRay(posmissile, missionangle, -30.0, 45.0, vv4, self, flag);
		float f5 = CalRay(posmissile, missionangle, -30.0, 0.0, vv5, self, flag);
		float f6 = CalRay(posmissile, missionangle, -30.0, -45.0, vv6, self, flag);
		float f7 = CalRay(posmissile, missionangle, 0.0, -45.0, vv7, self, flag);
		float f8 = CalRay(posmissile, missionangle, 30.0, -45.0, vv8, self, flag);

		NormalizeVector(vfront,vfront);
		NormalizeVector(vup,vup);
		NormalizeVector(vdown,vdown);
		NormalizeVector(vleft,vleft);
		NormalizeVector(vright,vright);
		NormalizeVector(vtrace, vtrace);

		NormalizeVector(vv1,vv1);
		NormalizeVector(vv2,vv2);
		NormalizeVector(vv3,vv3);
		NormalizeVector(vv4,vv4);
		NormalizeVector(vv5,vv5);
		NormalizeVector(vv6,vv6);
		NormalizeVector(vv7,vv7);
		NormalizeVector(vv8,vv8);

		if(front > base) front = base;
		if(up > base) up = base;
		if(down > base) down = base;
		if(left > base) left = base;
		if(right > base) right = base;

		if(f1 > base) f1 = base;
		if(f2 > base) f2 = base;
		if(f3 > base) f3 = base;
		if(f4 > base) f4 = base;
		if(f5 > base) f5 = base;
		if(f6 > base) f6 = base;
		if(f7 > base) f7 = base;
		if(f8 > base) f8 = base;

		t =- 1.0 * factor1 * (base - front) / base;
		ScaleVector( vfront, t);
		
		t =- 1.0 * factor1 * (base - up) / base;
		ScaleVector( vup, t);
		
		t =- 1.0 * factor1 * (base - down) / base;
		ScaleVector( vdown, t);
		
		t =- 1.0 * factor1 * (base - left) / base;
		ScaleVector( vleft, t);
		
		t =- 1.0 * factor1 * (base - right) / base;
		ScaleVector( vright, t);
		
		t =- 1.0*factor1*(base-f1)/f1;
		ScaleVector( vv1, t);
		
		t =- 1.0 * factor1 * (base - f2) / f2;
		ScaleVector( vv2, t);
		
		t =- 1.0 * factor1 * (base - f3) / f3;
		ScaleVector( vv3, t);
		
		t =- 1.0 * factor1 * (base - f4) / f4;
		ScaleVector( vv4, t);
		
		t =- 1.0 * factor1 * (base - f5) / f5;
		ScaleVector( vv5, t);
		
		t =- 1.0 * factor1 * (base - f6) / f6;
		ScaleVector( vv6, t);
		
		t =- 1.0 * factor1 * (base - f7) / f7;
		ScaleVector( vv7, t);
		
		t =- 1.0 * factor1 * (base - f8) / f8;
		ScaleVector( vv8, t);
		
		if(disenemy >= 500.0) disenemy = 500.0;
		t = 1.0 * factor2 * (1000.0 - disenemy) / 500.0;
		ScaleVector( vtrace, t);

		AddVectors(vfront, vup, vfront);
		AddVectors(vfront, vdown, vfront);
		AddVectors(vfront, vleft, vfront);
		AddVectors(vfront, vright, vfront);

		AddVectors(vfront, vv1, vfront);
		AddVectors(vfront, vv2, vfront);
		AddVectors(vfront, vv3, vfront);
		AddVectors(vfront, vv4, vfront);
		AddVectors(vfront, vv5, vfront);
		AddVectors(vfront, vv6, vfront);
		AddVectors(vfront, vv7, vfront);
		AddVectors(vfront, vv8, vfront);

		AddVectors(vfront, vtrace, vfront);
		NormalizeVector(vfront, vfront);
	}
	
	float a = GetAngle(vfront, velocitymissile);
	float amax = 3.14159 * duration * 1.5;
	 
	if(a > amax) a = amax;
	
	ScaleVector(vfront,a);
	
	//PrintToChat(client, "max %f %f  ",amax , a);
	float newvelocitymissile[3];
	AddVectors(velocitymissile, vfront, newvelocitymissile);
	
	float speed = GetConVarFloat(sm_tracerock_speed);
	if(speed < 60.0) speed = 60.0;
	NormalizeVector(newvelocitymissile, newvelocitymissile);
	ScaleVector(newvelocitymissile,speed);
	
	SetEntityGravity(ent, 0.01);
	TeleportEntity(ent, NULL_VECTOR,  NULL_VECTOR ,newvelocitymissile);
	
	SetEntProp(ent, Prop_Send, "m_iGlowType", 3 ); //3
	SetEntProp(ent, Prop_Send, "m_nGlowRange", 0 ); //0
	SetEntProp(ent, Prop_Send, "m_glowColorOverride", 11111); //1
	
	//ShowDir(0, posmissile, newvelocitymissile, 0.06); 
}

void CopyVector(float source[3], float target[3])
{
	target[0] = source[0];
	target[1] = source[1];
	target[2] = source[2];
}

int GetEnemy(float pos[3], float vec[3], int enemyteam)
{
	float min = 4.0;
	float pos2[3];
	float t;
	int s = 0;
	
	for(int client = 1; client <= MaxClients; client++)
	{
		bool playerok = IsClientInGame(client) && GetClientTeam(client) == enemyteam && IsPlayerAlive(client);
		if(playerok)
		{
			GetClientEyePosition(client, pos2);
			MakeVectorFromPoints(pos, pos2, pos2);
			t = GetAngle(vec, pos2);
			//PrintToChatAll("%N %f", client, 360.0*t/3.1415926/2.0);
			if(t <= min)
			{
				min = t;
				s = client;
			}
		}
	}
	return s;
}

bool IfTwoPosVisible(float pos1[3], float pos2[3], int self)
{
	bool r = true;
	Handle trace;
	trace = TR_TraceRayFilterEx(pos2, pos1, MASK_SOLID, RayType_EndPoint, DontHitSelfAndSurvivor,self);
	if(TR_DidHit(trace))
	{
		r = false;
	}
	CloseHandle(trace);
	return r;
}

float CalRay(float posmissile[3], float angle[3], float offset1, float offset2, float force[3], int ent, int flag = FilterSelf) 
{
	float ang[3];
	CopyVector(angle, ang);
	ang[0] += offset1;
	ang[1] += offset2;
	GetAngleVectors(ang, force, NULL_VECTOR,NULL_VECTOR);
	float dis = GetRayDistance(posmissile, ang, ent, flag);
	//PrintToChatAll("%f %f, %f", dis, offset1, offset2);
	return dis;
}

float GetAngle(float x1[3], float x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}

public bool DontHitSelf(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}

public bool DontHitSelfAndPlayer(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity > 0 && entity <= MaxClients)
	{
		if(IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}

public bool DontHitSelfAndPlayerAndCI(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false;
	}
	else if(entity > 0 && entity <= MaxClients)
	{
		if(IsClientInGame(entity))
		{
			return false;
		}
	}
	else
	{
		if(IsValidEntity(entity) && IsValidEdict(entity))
		{
			char edictname[128];
			GetEdictClassname(entity, edictname, 128);
			if(StrContains(edictname, "infected")>=0)
			{
				return false;
			}
		}
	}
	return true;
}

public bool DontHitSelfAndMissile(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity > MaxClients)
	{
		if(IsValidEntity(entity) && IsValidEdict(entity))
		{
			char edictname[128];
			GetEdictClassname(entity, edictname, 128);
			if(StrContains(edictname, "prop_dynamic")>=0)
			{
				return false;
			}
		}
	}
	return true;
}

public bool DontHitSelfAndSurvivor(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity > 0 && entity <= MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity)==2)
		{
			return false;
		}
	}
	return true;
}

public bool DontHitSelfAndInfected(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity > 0 && entity <= MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity) == 3)
		{
			return false;
		}
	}
	return true;
}

float GetRayDistance(float pos[3], float angle[3], int self, int flag)
{
	float hitpos[3];
	GetRayHitPos(pos, angle, hitpos, self, flag);
	return GetVectorDistance( pos,  hitpos);
}

int GetRayHitPos(float pos[3], float angle[3], float hitpos[3], int self, int flag)
{
	Handle trace;
	int hit = 0;
	if(flag == FilterSelf)
	{
		trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelf, self);
	}
	else if(flag == FilterSelfAndPlayer)
	{
		trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayer, self);
	}
	else if(flag == FilterSelfAndSurvivor)
	{
		trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndSurvivor, self);
	}
	else if(flag == FilterSelfAndInfected)
	{
		trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndInfected, self);
	}
	else if(flag == FilterSelfAndPlayerAndCI)
	{
		trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayerAndCI, self);
	}
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit = TR_GetEntityIndex(trace);
	}
	CloseHandle(trace);
	return hit;
}

int GetRayHitPos2(float pos[3], float angle[3], float hitpos[3], int ent = 0, float offset = 0.0)
{
	Handle trace;
	int hit = 0;
	
	trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayer, ent);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit = TR_GetEntityIndex(trace);
	}
	CloseHandle(trace);
	
	if(offset != 0.0)
	{
		float v[3];
		MakeVectorFromPoints(hitpos, pos, v);
		NormalizeVector(v, v);
		ScaleVector(v, offset);
		AddVectors(hitpos, v, hitpos);
	}
	return hit;
}

public void SkillEarthQuake(int target)
{
	float Pos[3], tPos[3];

	if(IsPlayerIncapped(target))
	{
		for(int i = 1; i <= GetMaxClients(); i++)
		{
			if(i == idTank[TYPE_QUAKE])
				continue;
			if(!IsClientInGame(i) || GetClientTeam(i) != 2)
				continue;
			GetClientAbsOrigin(idTank[TYPE_QUAKE], Pos);
			GetClientAbsOrigin(i, tPos);
			if(GetVectorDistance(tPos, Pos) < GetConVarFloat(sm_lbex_quakeradius_type03))
			{
				EmitSoundToClient(i, SOUND_QUAKE);
				ScreenShake(i, 50.0);
				Smash(idTank[TYPE_QUAKE], i, GetConVarFloat(sm_lbex_quakeforce_type03), 1.0, 1.5);
			}
		}
	}
}

public void SkillDreadClaw(int target)
{
	visibility = GetConVarInt(sm_lbex_dreadrate_type05);
	CreateTimer(GetConVarFloat(sm_lbex_dreadinterval_type05), DreadTimer, target);
	EmitSoundToAll(SOUND_DCLAW, target);
	ScreenFade(target, 0, 0, 0, visibility, 0, 0);
}

public void SkillGravityClaw(int target)
{
	SetEntityGravity(target, 0.3);
	CreateTimer(GetConVarFloat(sm_lbex_gravityinterval_type02), GravityTimer, target);
	EmitSoundToAll(SOUND_GCLAW, target);
	ScreenFade(target, 0, 0, 100, 80, 4000, 1);
	ScreenShake(target, 30.0);
}

public void SkillBurnClaw(int target)
{
	EmitSoundToAll(SOUND_BCLAW, target);
	ScreenFade(target, 200, 0, 0, 150, 80, 1);
	ScreenShake(target, 50.0);
}

public void SkillFreezeClaw(int target)
{
	FreezePlayer(target, GetConVarFloat(sm_lbex_freeze_type06));
	CreateTimer(GetConVarFloat(sm_lbex_freezeinterval_type06), FreezeTimer, target);
}

public void SkillLazyClaw(int target)
{
	for(int i = 1; i <= GetMaxClients(); i++)
	{
		if(i == idTank[TYPE_LAZY])
			continue;
		if(!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		if(GetEntProp(i, Prop_Send, "m_zombieClass") != 8)
		{
			LazyPlayer(target);
		}
	}
}

public void SkillRabiesClaw(int target)
{
	Rabies[target] = (GetConVarInt(sm_lbex_rabies_type08));
	CreateTimer(1.0, RabiesTimer, target);
	Toxin[target] = (GetConVarInt(sm_lbex_rabies_type08));
	CreateTimer(1.0, Toxin_Timer, target);
	EmitSoundToAll(SOUND_ROAR, target);
}

public void SkillBombClaw(int target)
{
	float Pos[3];

	for(int i = 1; i <= GetMaxClients(); i++)
	{
		if(i == idTank[TYPE_BOMBARD])
			continue;
		if(!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		GetClientAbsOrigin(idTank[TYPE_BOMBARD], Pos);
		if(GetVectorDistance(Pos, trsPos[target]) < GetConVarFloat(sm_lbex_bombardradius_type09))
		{
			DamageEffect(idTank[TYPE_BOMBARD], GetConVarFloat(sm_lbex_bombard_type09));
		}
	}
	EmitSoundToAll(SOUND_BOMBARD, target);
	ScreenShake(target, 100.0);

	/* Explode */
	LittleFlower(Pos, EXPLODE);

	/* Push away */
	PushAway(target, GetConVarFloat(sm_lbex_bombardforce_type09), GetConVarFloat(sm_lbex_bombardradius_type09), 0.5);
}

public void SkillCometStrike(int target, int type)
{
	float pos[3];
	GetClientAbsOrigin(target, pos);
	
	if(type == MOLOTOV)
	{
		LittleFlower(pos, EXPLODE);
		LittleFlower(pos, MOLOTOV);
	}
	else if(type == EXPLODE)
	{
		LittleFlower(pos, EXPLODE);
	}
}

public void SkillFlameGush(int target)
{
	float pos[3];
	
	SkillBurnClaw(target);
	LavaDamage(target);
	LavaDamage(target);
	GetClientAbsOrigin(idTank[TYPE_LAVA], pos);
	LittleFlower(pos, MOLOTOV);
}

public void SkillTremorClaw(int target)
{
	EmitSoundToAll(SOUND_TCLAW, target);
	//ScreenFade(target, 120, 0, 0, 0, 500, 0);
	ScreenShake(target, 50.0);
}

/******************************************************
*	Timer functions
*******************************************************/
public Action ParticleTimer(Handle timer)
{
	if(idTank[TYPE_GHOST])
		AttachParticle(idTank[TYPE_GHOST], PARTICLE_SMOKE);
	else if(idTank[TYPE_LAVA])
		AttachParticle(idTank[TYPE_LAVA], PARTICLE_FIRE);
	else
		KillTimer(timer);
}

public Action GravityTimer(Handle timer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		SetEntityGravity(target, 1.0);
	}
}

public Action JumpingTimer(Handle timer)
{
	if(idTank[TYPE_LEAPER] && IsValidEntity(idTank[TYPE_LEAPER]) && IsClientInGame(idTank[TYPE_LEAPER]))
	{
		AddVelocity(idTank[TYPE_LEAPER], GetConVarFloat(sm_lbex_jumpheight_type04));
	}
	else
	{
		KillTimer(timer);
	}
}

public Action StealthTimer(Handle timer)
{
	if(idTank[TYPE_GHOST])
	{
		alpharate = 255;
		Remove(idTank[TYPE_GHOST]);
	}
}

public Action DreadTimer(Handle timer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		visibility -= 8;
		if(visibility < 0)  visibility = 0;
		ScreenFade(target, 0, 0, 0, visibility, 0, 1);
		if(visibility <= 0)
		{
			visibility = 0;
			KillTimer(timer);
		}
	}
}

public Action FreezeTimer(Handle timer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		EmitSoundToAll(SOUND_DEFROST, target);
		SetEntityMoveType(target, MOVETYPE_WALK);
		SetEntityRenderColor(target, 255, 255, 255, 255);
		ScreenFade(target, 0, 0, 0, 0, 0, 1);
		freeze[target] = OFF;
	}
}

public Action RabiesTimer(Handle timer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		if(Rabies[target] <= 0)
		{
			KillTimer(timer);
			return Plugin_Handled;
		}

		RabiesDamage(target);

		if(Rabies[target] > 0)
		{
			CreateTimer(1.0, RabiesTimer, target);
			Rabies[target] -= 1;
		}
		EmitSoundToAll(SOUND_RABIES, target);
	}
	return Plugin_Handled;
}

void KillToxin(int target)
{
	float pos[3];
	GetClientAbsOrigin(target, pos);
	float angs[3];
	GetClientEyeAngles(target, angs);

	angs[2] = 0.0;

	TeleportEntity(target, pos, angs, NULL_VECTOR);

	int clients[2];
	clients[0] = target;

	Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();
}

public Action Toxin_Timer(Handle timer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		if(Toxin[target] <= 0)
		{
			KillTimer(timer);
			return Plugin_Handled;
		}
		
		KillToxin(target);
		
		if(Toxin[target] > 0)
		{
			CreateTimer(1.0, Toxin_Timer, target);
			Toxin[target] -= 1;
		}
		
		float pos[3];
		GetClientAbsOrigin(target, pos);
		
		float angs[3];
		GetClientEyeAngles(target, angs);
		
		angs[2] = ToxinAngle[GetRandomInt(0,100) % 20];
		
		TeleportEntity(target, pos, angs, NULL_VECTOR);
		
		int clients[2];
		clients[0] = target;
		
		Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
		BfWriteShort(message, 255);
		BfWriteShort(message, 255);
		BfWriteShort(message, (0x0002));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, 128);
		
		EndMessage();
	}
	return Plugin_Handled;
}

public Action WarpTimer(Handle timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		float pos[3];
		
		for(int i = 1; i <= GetMaxClients(); i++)
		{
			if(idBoss == idTank[TYPE_GHOST] && idTank[TYPE_LAVA] && idTank[TYPE_GRAVITY] && idTank[TYPE_QUAKE] && idTank[TYPE_LEAPER] && idTank[TYPE_DREAD] 
			&& idTank[TYPE_FREEZE] && idTank[TYPE_LAZY] && idTank[TYPE_RABIES] && idTank[TYPE_BOMBARD] && idTank[TYPE_TREMOR])
				continue;
			if(!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != SURVIVOR)
				continue;
			EmitSoundToClient(i, SOUND_WARP);
		}
		GetClientAbsOrigin(idBoss, pos);
		ShowParticle(pos, PARTICLE_WARP, 2.0);
		TeleportEntity(idBoss, ftlPos, NULL_VECTOR, NULL_VECTOR);
		ShowParticle(ftlPos, PARTICLE_WARP, 2.0);
		SetEntityMoveType(idBoss, MOVETYPE_WALK);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 2, 1);
	}
	else
	{
		KillTimer(timer);
	}
}

public Action GetSurvivorPosition(Handle timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		int count = 0;
		int idAlive[MAXPLAYERS+1];
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != SURVIVOR)
				continue;
			idAlive[count] = i;
			count++;
		}
		if(count == 0) return;
		int clientNum = GetRandomInt(0, count-1);
		GetClientAbsOrigin(idAlive[clientNum], ftlPos);
	}
	else
	{
		KillTimer(timer);
	}
}

public Action FatalMirror(Handle timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		/* Stop moving and prevent all damage for a while */
		SetEntityMoveType(idBoss, MOVETYPE_NONE);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 0, 1);

		/* Teleport to position that survivor exsited 2sec ago */
		CreateTimer(1.5, WarpTimer);
	}
	else
	{
		KillTimer(timer);
	}
}

/******************************************************
*	Gimmick functions
*******************************************************/
public Action Remove(int ent)
{
	if(IsValidEntity(ent))
	{
		CreateTimer(0.1, fadeout, ent, TIMER_REPEAT);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	}
}

public Action fadeout(Handle Timer, any ent)
{
	if(!IsValidEntity(ent) || !idTank[TYPE_GHOST])
	{
		KillTimer(Timer);
		return;
	}
	alpharate -= 2;
	if (alpharate < 0)  alpharate = 0;
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 80, 80, 255, alpharate);
	if(alpharate <= 0)
	{
		KillTimer(Timer);
	}
}

public void AddVelocity(int client, float zSpeed)
{
	if(g_iVelocity == -1) return;
	
	float vecVelocity[3];
	GetEntDataVector(client, g_iVelocity, vecVelocity);
	vecVelocity[2] += zSpeed;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

public void LittleFlower(float pos[3], int type)
{
	/* Fire(type=0) or explosion(type=1) */
	int entity = CreateEntityByName("prop_physics");
	if (IsValidEntity(entity))
	{
		pos[2] += 10.0;
		if (type == 0)
			/* fire */
			DispatchKeyValue(entity, "model", ENTITY_GASCAN);
		else
			/* explode */
			DispatchKeyValue(entity, "model", ENTITY_PROPANE);
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
}

public void Smash(int client, int target, float power, float powHor, float powVec)
{
	/* Blow off target */
	float HeadingVector[3], AimVector[3];
	GetClientEyeAngles(client, HeadingVector);
	
	AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])) ,power * powHor);
	AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])) ,power * powHor);
	
	float current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	float resulting[3];
	resulting[0] = FloatAdd(current[0], AimVector[0]);
	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[2] = power * powVec;
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

public int ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg;
	msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
		BfWriteShort(msg, (0x0002 | 0x0008));
	else
		BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public void ScreenShake(int target, float intensity)
{
	Handle msg;
	msg = StartMessageOne("Shake", target);
	
	BfWriteByte(msg, 0);
	BfWriteFloat(msg, intensity);
	BfWriteFloat(msg, 10.0);
	BfWriteFloat(msg, 3.0);
	EndMessage();
}

public void FreezePlayer(int target, float time)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		SetEntityMoveType(target, MOVETYPE_NONE);
		SetEntityRenderColor(target, 0, 128, 255, 135);
		EmitSoundToAll(SOUND_FREEZE, target);
		freeze[target] = ON;
		CreateTimer(time, FreezeTimer, target);
	}
}

public void LazyPlayer(int target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2 && !isSlowed[target])
	{
		isSlowed[target] = true;
		CreateTimer(GetConVarFloat(sm_lbex_lazy_type07), Quick, target);
		SetEntDataFloat(target, laggedMovementOffset, GetConVarFloat(sm_lbex_lazyspeed_type07), true);
		SetEntityRenderColor(target, 255, 255, 255, 135);
		EmitSoundToAll(SOUND_LAZY, target);
	}
}

public Action Quick(Handle timer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		SetEntDataFloat(target, laggedMovementOffset, 1.0, true);
		isSlowed[target] = false;
		SetEntityRenderColor(target, 255, 255, 255, 255);
		EmitSoundToAll(SOUND_QUICK, target);
	}
}

stock void RabiesDamage(int target)
{
	char dmg_str[16];
	char dmg_type_str[16];
	IntToString((1 << 17),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("sm_lbex_rabiesdamage_type08"), dmg_str, sizeof(dmg_str));
	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(target,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchKeyValue(pointHurt,"classname","point_hurt");
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt",-1,(target>0)?target:-1);
	DispatchKeyValue(target,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

stock void LavaDamage(int target)
{
	char dmg_lava[16];
	char dmg_type_lava[16];
	IntToString((1 << 17),dmg_lava,sizeof(dmg_type_lava));
	GetConVarString(FindConVar("sm_lbex_lavadamage_type01"), dmg_lava, sizeof(dmg_lava));
	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(target,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_lava);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_lava);
	DispatchKeyValue(pointHurt,"classname","point_hurt");
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt",-1,(target>0)?target:-1);
	DispatchKeyValue(target,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

stock void DamageEffect(int target, float damage)
{
	char tName[20];
	Format(tName, 20, "target%d", target);
	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(target, "targetname", tName);
	DispatchKeyValueFloat(pointHurt, "Damage", damage);
	DispatchKeyValue(pointHurt, "DamageTarget", tName);
	DispatchKeyValue(pointHurt, "DamageType", "65536");
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt");
	AcceptEntityInput(pointHurt, "Kill");
}

public void PushAway(int target, float force, float radius, float duration)
{
	int push = CreateEntityByName("point_push");
	DispatchKeyValueFloat (push, "magnitude", force);
	DispatchKeyValueFloat (push, "radius", radius);
	SetVariantString("spawnflags 24");
	AcceptEntityInput(push, "AddOutput");
	DispatchSpawn(push);
	TeleportEntity(push, trsPos[target], NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(push, "Enable", -1, -1);
	CreateTimer(duration, DeletePushForce, push);
}

/******************************************************
*	Particle control functions
*******************************************************/
public void ShowParticle(float pos[3], char[] particlename, float time)
{
	/* Show particle effect you like */
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
}

public void AttachParticle(int ent, char[] particleType)
{
	char tName[64];
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		float pos[3];
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
	}
}

public Action DeleteParticles(Handle timer, any particle)
{
	/* Delete particle */
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
}

public void PrecacheParticle(char[] particlename)
{
	/* Precache particle */
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
	}
}

public Action DeletePushForce(Handle timer, any ent)
{
	if (ent> 0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		char classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_push", false))
		{
 			AcceptEntityInput(ent, "Disable");
			AcceptEntityInput(ent, "Kill"); 
			RemoveEdict(ent);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePosition[3]) 
{
	if(GetConVarInt(sm_rock_damage_immunity))
	{
		if(IsValidEntity(victim) && IsClientInGame(victim) && victim != DEAD)
		{
			if (g_IsTremor && (victim == idTank[TYPE_TREMOR]))
			{
				char name[128];
				GetEdictClassname(inflictor, name, sizeof(name));
				if (StrEqual(name, "tank_rock"))
				{
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

/******************************************************
*	Other functions
*******************************************************/
bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return true;
	else
		return false;
}

bool IsPlayerIgnited(int client)
{
	if(GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE)
		return true;
	else
		return false;
}

public int IsValidClient(int client)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(client))
	{
		return false;
	}
	return true;
}

/******************************************************
*	EOF
*******************************************************/

stock void ForceWeaponDrop(int client)
{
	if (GetPlayerWeaponSlot(client, 1) > 0)
	{
		int weapon = GetPlayerWeaponSlot(client, 1);
		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
	}
}