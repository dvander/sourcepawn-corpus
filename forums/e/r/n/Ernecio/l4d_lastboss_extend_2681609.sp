/******************************************************
* 		L4D2: Last Boss (Extended Version) v1.0
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define DEBUG 0

#define ON				1
#define OFF				0
#define DEAD		    -1

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

/* Model */
#define SURVIVOR	2
#define MOLOTOV 	0
#define EXPLODE 	1
#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"

/* Sound */
#define SOUND_EXPLODE	"animation/bombing_run_01.wav"
#define SOUND_BCLAW		"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SOUND_GCLAW		"plats/churchbell_end.wav"
#define SOUND_DCLAW		"ambient/random_amb_sounds/randbridgegroan_03.wav"
#define SOUND_QUAKE		"player/charger/hit/charger_smash_02.wav"
#define SOUND_STEEL		"physics/metal/metal_solid_impact_hard5.wav"
#define SOUND_WARP		"ambient/energy/zap9.wav"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define SOUND_DEFROST	"physics/glass/glass_sheet_break1.wav"
#define SOUND_LAZY		"npc/infected/action/rage/female/rage_68.wav"
#define SOUND_QUICK		"ambient/water/distant_drip2.wav"
#define SOUND_ROAR	    "player/tank/voice/pain/tank_fire_08.wav"
#define SOUND_RABIES	"player/pz/voice/attack/zombiedog_attack2.wav"
#define SOUND_BOMBARD	"animation/van_inside_hit_wall.wav"

/* Particle */
#define PARTICLE_DEATH	"gas_explosion_main"
//#define PARTICLE_WARP	"water_splash"
#define PARTICLE_WARP 	"electrical_arc_01_system"
#define PARTICLE_SMOKE	"apc_wheel_smoke1"
#define PARTICLE_FIRE	"aircraft_destroy_fastFireTrail"

/* Message */
#define MESSAGE_SPAWN00	"\x03Tank \x01is approaching fast! \x04Type-00\x01[GHOST]"
#define MESSAGE_SPAWN01	"\x03Tank \x01is approaching fast! \x04Type-01\x01[LAVA]"
#define MESSAGE_SPAWN02	"\x03Tank \x01is approaching fast! \x04Type-02\x01[GRAVITY]"
#define MESSAGE_SPAWN03	"\x03Tank \x01is approaching fast! \x04Type-03\x01[QUAKE]"
#define MESSAGE_SPAWN04	"\x03Tank \x01is approaching fast! \x04Type-04\x01[LEAPER]"
#define MESSAGE_SPAWN05	"\x03Tank \x01is approaching fast! \x04Type-05\x01[DREAD]"
#define MESSAGE_SPAWN06	"\x03Tank \x01is approaching fast! \x04Type-06\x01[FREEZE]"
#define MESSAGE_SPAWN07	"\x03Tank \x01is approaching fast! \x04Type-07\x01[LAZY]"
#define MESSAGE_SPAWN08	"\x03Tank \x01is approaching fast! \x04Type-07\x01[RABIES]"
#define MESSAGE_SPAWN09	"\x03Tank \x01is approaching fast! \x04Type-07\x01[BOMBARD]"

/* Parameter */
Handle sm_lbex_enable 			= INVALID_HANDLE;
Handle sm_lbex_enable_finale 	= INVALID_HANDLE;
Handle sm_lbex_enable_announce 	= INVALID_HANDLE;
Handle sm_lbex_enable_warp 		= INVALID_HANDLE;

Handle sm_lbex_health_type00 = INVALID_HANDLE;
Handle sm_lbex_health_type01 = INVALID_HANDLE;
Handle sm_lbex_health_type02 = INVALID_HANDLE;
Handle sm_lbex_health_type03 = INVALID_HANDLE;
Handle sm_lbex_health_type04 = INVALID_HANDLE;
Handle sm_lbex_health_type05 = INVALID_HANDLE;
Handle sm_lbex_health_type06 = INVALID_HANDLE;
Handle sm_lbex_health_type07 = INVALID_HANDLE;
Handle sm_lbex_health_type08 = INVALID_HANDLE;
Handle sm_lbex_health_type09 = INVALID_HANDLE;

Handle sm_lbex_color_type00	= INVALID_HANDLE;
Handle sm_lbex_color_type01	= INVALID_HANDLE;
Handle sm_lbex_color_type02	= INVALID_HANDLE;
Handle sm_lbex_color_type03	= INVALID_HANDLE;
Handle sm_lbex_color_type04	= INVALID_HANDLE;
Handle sm_lbex_color_type05	= INVALID_HANDLE;
Handle sm_lbex_color_type06	= INVALID_HANDLE;
Handle sm_lbex_color_type07	= INVALID_HANDLE;
Handle sm_lbex_color_type08	= INVALID_HANDLE;
Handle sm_lbex_color_type09	= INVALID_HANDLE;

Handle sm_lbex_speed_type00	= INVALID_HANDLE;
Handle sm_lbex_speed_type01	= INVALID_HANDLE;
Handle sm_lbex_speed_type02	= INVALID_HANDLE;
Handle sm_lbex_speed_type03	= INVALID_HANDLE;
Handle sm_lbex_speed_type04	= INVALID_HANDLE;
Handle sm_lbex_speed_type05 = INVALID_HANDLE;
Handle sm_lbex_speed_type06 = INVALID_HANDLE;
Handle sm_lbex_speed_type07 = INVALID_HANDLE;
Handle sm_lbex_speed_type08 = INVALID_HANDLE;
Handle sm_lbex_speed_type09 = INVALID_HANDLE;

Handle sm_lbex_weight_type02 			= INVALID_HANDLE;
Handle sm_lbex_stealth_type00 			= INVALID_HANDLE;
Handle sm_lbex_jumpinterval_type04 		= INVALID_HANDLE;
Handle sm_lbex_jumpheight_type04 		= INVALID_HANDLE;
Handle sm_lbex_gravityinterval_type02 	= INVALID_HANDLE;
Handle sm_lbex_quakeradius_type03 		= INVALID_HANDLE;
Handle sm_lbex_quakeforce_type03 		= INVALID_HANDLE;
Handle sm_lbex_dreadinterval_type05		= INVALID_HANDLE;
Handle sm_lbex_dreadrate_type05 		= INVALID_HANDLE;
Handle sm_lbex_freeze_type06 			= INVALID_HANDLE;
Handle sm_lbex_freezeinterval_type06 	= INVALID_HANDLE;
Handle sm_lbex_lazy_type07 				= INVALID_HANDLE;
Handle sm_lbex_lazyspeed_type07 		= INVALID_HANDLE;
Handle sm_lbex_rabies_type08 			= INVALID_HANDLE;
Handle sm_lbex_bombard_type09 			= INVALID_HANDLE;
Handle sm_lbex_bombardradius_type09 	= INVALID_HANDLE;
Handle sm_lbex_bombardforce_type09 		= INVALID_HANDLE;
Handle sm_lbex_warp_interval 			= INVALID_HANDLE;

// UserMessageId for Fade.
UserMsg g_FadeUserMsgId;

float ToxinAngle[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

/* Grobal */
int idTank[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int idBoss = DEAD;
int alpharate;
int visibility;
int finaleflag = OFF;
int g_iVelocity	= -1;
float ftlPos[3];
int freeze[MAXPLAYERS+1];
bool isSlowed[MAXPLAYERS+1] = false;
static int laggedMovementOffset = 0;
int Rabies[MAXPLAYERS+1];
int Toxin[MAXPLAYERS+1];
float trsPos[MAXPLAYERS+1][3];
static bool bL4D2;

public Plugin myinfo = 
{
	name 		= "[L4D1 And L4D2] LAST BOSS (Extended Version)",
	author 		= "ztar & IxAvnoMonvAxI",
	description = "Special Tank spawns randomly.",
	version 	= PLUGIN_VERSION,
	url			= "http://ztar.blog7.fc2.com/"
}

/**
 * Called on pre plugin start.
 *
 * @param myself        Handle to the plugin.
 * @param late          Whether or not the plugin was loaded "late" (after map load).
 * @param error         Error message buffer in case load failed.
 * @param err_max       Maximum number of characters for error message buffer.
 * @return              APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if ( engine != Engine_Left4Dead && engine != Engine_Left4Dead2 /* || !IsDedicatedServer() */ )
	{
		strcopy( error, err_max, "This Plugin \"Lastboss Extended\" only runs in the \"Left 4 Dead 1/2\" Games!." );
		return APLRes_SilentFailure;
	}
	
	bL4D2 = ( engine == Engine_Left4Dead2 );
	return APLRes_Success;
}

/******************************************************
*	When plugin started
*******************************************************/
public void OnPluginStart()
{
	/* Enable/Disable */
	sm_lbex_enable			= CreateConVar("sm_lbex_enable", 			"1", 	"Special Tank spawns randomly.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lbex_enable_finale	= CreateConVar("sm_lbex_enable_finale", 	"0", 	"If original LAST BOSS plugin is applied, Turn this OFF.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lbex_enable_announce	= CreateConVar("sm_lbex_enable_announce", 	"1", 	"Enable Announcement.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lbex_enable_warp		= CreateConVar("sm_lbex_enable_warp", 		"1", 	"Last Boss can use FatalMirror.(0:OFF 1:ON)", FCVAR_NOTIFY);

	/* Health */
	sm_lbex_health_type00 = CreateConVar("sm_lbex_health_type00", 	"6666", 	"Tank Type-00[GHOST]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type01 = CreateConVar("sm_lbex_health_type01", 	"5400", 	"Tank Type-01[LAVA]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type02 = CreateConVar("sm_lbex_health_type02", 	"8000", 	"Tank Type-02[GRAVITY]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type03 = CreateConVar("sm_lbex_health_type03", 	"7000", 	"Tank Type-03[QUAKE]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type04 = CreateConVar("sm_lbex_health_type04", 	"4800", 	"Tank Type-04[LEAPER]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type05 = CreateConVar("sm_lbex_health_type05", 	"6200", 	"Tank Type-05[DREAD]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type06 = CreateConVar("sm_lbex_health_type06", 	"8000", 	"Tank Type-06[FREEZE]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type07 = CreateConVar("sm_lbex_health_type07", 	"8600", 	"Tank Type-07[LAZY]:Health", FCVAR_NOTIFY);	
	sm_lbex_health_type08 = CreateConVar("sm_lbex_health_type08", 	"9000", 	"Tank Type-08[RABIES]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type09 = CreateConVar("sm_lbex_health_type09", 	"8800", 	"Tank Type-09[BOMBARD]:Health", FCVAR_NOTIFY);

	/* Color */
	sm_lbex_color_type00 = CreateConVar("sm_lbex_color_type00", 	"80 80 255", 	"Tank Type-00[GHOST]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type01 = CreateConVar("sm_lbex_color_type01", 	"255 80 80", 	"Tank Type-01[LAVA]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type02 = CreateConVar("sm_lbex_color_type02", 	"80 255 80", 	"Tank Type-02[GRAVITY]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type03 = CreateConVar("sm_lbex_color_type03", 	"255 255 80", 	"Tank Type-03[QUAKE]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type04 = CreateConVar("sm_lbex_color_type04", 	"80 255 255", 	"Tank Type-04[LEAPER]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type05 = CreateConVar("sm_lbex_color_type05", 	"90 90 90", 	"Tank Type-05[DREAD]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type06 = CreateConVar("sm_lbex_color_type06", 	"0 128 255", 	"Tank Type-06[FREEZE]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type07 = CreateConVar("sm_lbex_color_type07", 	"200 150 200", 	"Tank Type-07[LAZY]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type08 = CreateConVar("sm_lbex_color_type08", 	"176 48 96", 	"Tank Type-08[RAIBES]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type09 = CreateConVar("sm_lbex_color_type09", 	"153 153 255", 	"Tank Type-09[BOMBARD]:Color(0-255)", FCVAR_NOTIFY);

	/* Speed */
	sm_lbex_speed_type00 = CreateConVar("sm_lbex_speed_type00", 	"0.9", 	"Tank Type-00[GHOST]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type01 = CreateConVar("sm_lbex_speed_type01", 	"1.1", 	"Tank Type-01[LAVA]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type02 = CreateConVar("sm_lbex_speed_type02", 	"1.0", 	"Tank Type-02[GRAVITY]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type03 = CreateConVar("sm_lbex_speed_type03", 	"1.0", 	"Tank Type-03[QUAKE]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type04 = CreateConVar("sm_lbex_speed_type04", 	"1.2", 	"Tank Type-04[LEAPER]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type05 = CreateConVar("sm_lbex_speed_type05", 	"1.0", 	"Tank Type-05[DREAD]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type06 = CreateConVar("sm_lbex_speed_type06", 	"1.2", 	"Tank Type-06[FREEZE]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type07 = CreateConVar("sm_lbex_speed_type07", 	"0.9", 	"Tank Type-07[LAZY]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type08 = CreateConVar("sm_lbex_speed_type07", 	"0.9", 	"Tank Type-08[LAZY]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type09 = CreateConVar("sm_lbex_speed_type09", 	"1.3", 	"Tank Type-09[BOMBARD]:Speed", FCVAR_NOTIFY);

	/* Skill */
	sm_lbex_weight_type02			= CreateConVar("sm_lbex_weight_type02", 			"10.0", 	"Tank Type-02[GRAVITY]:Weight", FCVAR_NOTIFY);
	sm_lbex_stealth_type00			= CreateConVar("sm_lbex_stealth_type00", 			"10.0", 	"Tank Type-00[GHOST]:Interval", FCVAR_NOTIFY);
	sm_lbex_jumpinterval_type04		= CreateConVar("sm_lbex_jumpinterval_type04", 		"1.0", 		"Tank Type-04[LEAPER]:JumpInterval", FCVAR_NOTIFY);
	sm_lbex_jumpheight_type04		= CreateConVar("sm_lbex_jumpheight_type04", 		"300.0", 	"Tank Type-04[LEAPER]:JumpHeight", FCVAR_NOTIFY);
	sm_lbex_gravityinterval_type02	= CreateConVar("sm_lbex_gravityinterval_type02", 	"6.0", 		"Tank Type-02[GRAVITY]:Interval", FCVAR_NOTIFY);
	sm_lbex_quakeradius_type03		= CreateConVar("sm_lbex_quakeradius_type03", 		"500.0", 	"Tank Type-03[QUAKE]:QuakeRadius", FCVAR_NOTIFY);
	sm_lbex_quakeforce_type03		= CreateConVar("sm_lbex_quakeforce_type03", 		"300.0", 	"Tank Type-03[QUAKE]:QuakeForce", FCVAR_NOTIFY);
	sm_lbex_dreadinterval_type05	= CreateConVar("sm_lbex_dreadinterval_type05", 		"8.0", 		"Tank Type-05[DREAD]:BlindInterval", FCVAR_NOTIFY);
	sm_lbex_dreadrate_type05		= CreateConVar("sm_lbex_dreadrate_type05", 			"235", 		"Tank Type-05[DREAD]:BlindRate", FCVAR_NOTIFY);
	sm_lbex_freeze_type06		    = CreateConVar("sm_lbex_freeze_type06", 			"10", 		"Tank Type-06[FREEZE]:FreezeTime", FCVAR_NOTIFY);
	sm_lbex_freezeinterval_type06	= CreateConVar("sm_lbex_freezeinterval_type06", 	"6.0", 		"Tank Type-06[FREEZE]:FreezeInterval", FCVAR_NOTIFY);
	sm_lbex_lazy_type07			    = CreateConVar("sm_lbex_lazy_type07", 				"10.0", 	"Tank Type-07[LAZY]:LazyTime", FCVAR_NOTIFY);
	sm_lbex_lazyspeed_type07		= CreateConVar("sm_lbex_lazyspeed_type07", 			"0.3", 		"Tank Type-07[LAZY]:LazySpeed", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_lbex_rabies_type08			= CreateConVar("sm_lbex_rabies_type08", 			"10.0", 	"Tank Type-08[RABIES]:RabiesTime", FCVAR_NOTIFY);
	sm_lbex_bombard_type09		    = CreateConVar("sm_lbex_bombard_type09", 			"300", 		"Tank Type-10[BOMBARD]:BombDamage", FCVAR_NOTIFY);
	sm_lbex_bombardradius_type09	= CreateConVar("sm_lbex_bombardradius_type09", 		"250", 		"Tank Type-10[BOMBARD]:BombRadius", FCVAR_NOTIFY);
	sm_lbex_bombardforce_type09		= CreateConVar("sm_lbex_bombardforce_type09", 		"600.0", 	"Tank Type-10[BOMBARD]:BombForce", FCVAR_NOTIFY);	
	sm_lbex_warp_interval		    = CreateConVar("sm_lbex_warp_interval", 			"35.0", 	"Fatal Mirror skill:Interval(all form)", FCVAR_NOTIFY);
	
	CreateConVar("sm_lbex_rabiesdamage_type08", "5", "Tank Type-08[RABIES]:RabiesDamage", FCVAR_NOTIFY);

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
	
//	AutoExecConfig(true, "l4d2_lastboss_extend");
	
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

	/* Precache sounds */
	PrecacheSound(SOUND_EXPLODE, true);	
	PrecacheSound(SOUND_BCLAW, true);
	PrecacheSound(SOUND_GCLAW, true);
	PrecacheSound(SOUND_DCLAW, true);
	PrecacheSound(SOUND_QUAKE, true);
	PrecacheSound(SOUND_STEEL, true);
	PrecacheSound(SOUND_FREEZE, true);
	PrecacheSound(SOUND_DEFROST, true);
	PrecacheSound(SOUND_LAZY, true);
	PrecacheSound(SOUND_QUICK, true);
	PrecacheSound(SOUND_RABIES, true);
	PrecacheSound(SOUND_BOMBARD, true);	
	PrecacheSound(SOUND_WARP, true);

	/* Precache particles */
	PrecacheParticle(PARTICLE_DEATH);
	PrecacheParticle(PARTICLE_SMOKE);
	PrecacheParticle(PARTICLE_FIRE);	
	PrecacheParticle(PARTICLE_WARP);	
}

void InitData()
{
	for(int i = 0; i < 9; i++)
		idTank[i] = 0;
	
	idBoss = DEAD;
	finaleflag = OFF;
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

public Action Event_Round_Start(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	InitData();	
}

public Action Event_Finale_Start(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	finaleflag = ON;
}

/******************************************************
*	Event when Tank has spawned or dead
*******************************************************/
public Action Event_Tank_Spawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if(!GetConVarInt(sm_lbex_enable) || (!GetConVarInt(sm_lbex_enable_finale) && finaleflag))
		return;
		
	if(idTank[0] && idTank[1] && idTank[2] && idTank[3] && idTank[4] && idTank[5] && idTank[6] && idTank[7] && idTank[8] && idTank[9])
		return;

	int idTankSpawn = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	int type = GetRandomInt(0, 9);
	
	while(idTank[type] != 0)
		type = GetRandomInt(0, 9);
	
	idTank[type] = idTankSpawn;
	
	idBoss = idTankSpawn;

	if(IsValidEntity(idTank[type]) && IsClientInGame(idTank[type]))
		SetTankStatus(type);
	
}

public void SetTankStatus( int type )
{
	int health;
	float speed;
	static char color[32];	
	
	/* Type-00[GHOST] */
	if(type == TYPE_GHOST)
	{
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
	}
	
	/* Type-05[DREAD] */
	else if(type == TYPE_DREAD)
	{
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

	/* Type-07[RABIES] */
	else if(type == TYPE_RABIES)
	{
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

	/* Type-08[BOMBARD] */
	else if(type == TYPE_BOMBARD)
	{
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

	PrintToChatAll(" ");
	
	/* Setup basic status */
	SetEntityHealth(idTank[type], health);
	SetEntPropFloat(idTank[type], Prop_Send, "m_flLaggedMovementValue", speed);
	SetEntityRenderMode( idTank[type], view_as<RenderMode>( 0 ) );
	DispatchKeyValue(idTank[type], "rendercolor", color);
}

public Action Event_Player_Death(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int idTankDead = GetClientOfUserId(hEvent.GetInt( "userid" ) );
	int target = GetClientOfUserId(hEvent.GetInt( "userid" ) );	

	if(!GetConVarInt(sm_lbex_enable) || (!GetConVarInt(sm_lbex_enable_finale) && finaleflag))
		return;
	if(idTankDead <= 0 || idTankDead > MaxClients)
		return;
	if(!IsValidEntity(idTankDead) || !IsClientInGame(idTankDead))
		return;
	
//	if(GetEntProp(idTankDead, Prop_Send, "m_zombieClass") != 8)
//		return;
	if ( !IsTank( idTankDead ) )
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

	/* Explode and burn when died */
	if(idTankDead)
	{
		static float Pos[3];
		GetClientAbsOrigin(idTankDead, Pos);
		EmitSoundToAll(SOUND_EXPLODE, idTankDead);
		ShowParticle(Pos, PARTICLE_DEATH, 5.0);
		LittleFlower(Pos, MOLOTOV);
		LittleFlower(Pos, EXPLODE);
	}

	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		isSlowed[target] = false;
		Rabies[target] = 0;
		Toxin[target] = 0;		
	}	
}

public void Event_RoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int target = GetClientOfUserId(hEvent.GetInt( "userid" ) );

	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		isSlowed[target] = false;
		Rabies[target] = 0;
		Toxin[target] = 0;
	}
}

/******************************************************
*	Special skills when attacking
*******************************************************/
public Action Event_Player_Hurt(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt( "attacker" ) );
	int target = GetClientOfUserId(hEvent.GetInt( "userid" ) );
	
	if(!GetConVarInt(sm_lbex_enable) || (!GetConVarInt(sm_lbex_enable_finale) && finaleflag))
		return;
	
	static char weapon[64];
	GetEventString(hEvent, "weapon", weapon, sizeof(weapon));
	
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
//		if(GetEntProp(target, Prop_Send, "m_zombieClass") == 8)
		if ( IsTank( target ) )
		{
			if(target == idTank[TYPE_GRAVITY])
			{
				/* Skill:Steel Skin */
				EmitSoundToClient(attacker, SOUND_STEEL);
				SetEntityHealth( idTank[TYPE_GRAVITY], ( GetEventInt( hEvent, "dmg_health" ) + GetEventInt( hEvent, "health" ) ) );
			}
			else if(target == idTank[TYPE_LAVA])
			{
				/* Skill:Flame Gush */
				SkillFlameGush(attacker);		
			}
		}
	}
	else
	{	
//		if(GetEntProp(target, Prop_Send, "m_zombieClass") == 8)
		if ( IsTank( target ) )
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

public void SkillEarthQuake(int target)
{
	float Pos[3], tPos[3];

	if(IsPlayerIncapped(target))
	{
		for( int i = 1; i <= MaxClients; i ++ )
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
	int health = GetClientHealth(target);
	if(health > 0 && !IsPlayerIncapped(target))
	{
		SetEntityHealth(target, 1);
		SetEntPropFloat(target, Prop_Send, "m_healthBuffer", float(health));
	}
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
	for( int i = 1; i <= MaxClients; i ++ )
	{
		if(i == idTank[TYPE_LAZY])
			continue;
		if(!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
//	    if(GetEntProp(i, Prop_Send, "m_zombieClass") != 8)
		if ( !IsTank( i ) )
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

	for ( int i = 1; i <= MaxClients; i ++ )
	{
	    if(i == idTank[TYPE_BOMBARD])
		    continue;
		
	    if(!IsClientInGame(i) || GetClientTeam(i) != 2)
		    continue;
		
	    GetClientAbsOrigin(idTank[TYPE_BOMBARD], Pos);
		
	    if(GetVectorDistance(Pos, trsPos[target]) < GetConVarFloat(sm_lbex_bombardradius_type09))
			DamageEffect(idTank[TYPE_BOMBARD], GetConVarFloat(sm_lbex_bombard_type09));
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
	GetClientAbsOrigin(idTank[TYPE_LAVA], pos);
	LittleFlower(pos, MOLOTOV);
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
	SetEntityGravity(target, 1.0);
}

public Action JumpingTimer(Handle timer)
{
//	if(idTank[TYPE_LEAPER] && GetEntProp(idTank[TYPE_LEAPER], Prop_Send, "m_zombieClass") == 8)
	if(idTank[TYPE_LEAPER] && IsTank( idTank[TYPE_LEAPER] ) )
		AddVelocity(idTank[TYPE_LEAPER], GetConVarFloat(sm_lbex_jumpheight_type04));
	else
		KillTimer(timer);
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
	visibility -= 8;
	if(visibility < 0)  visibility = 0;
	ScreenFade(target, 0, 0, 0, visibility, 0, 1);
	if(visibility <= 0)
	{
		visibility = 0;
		KillTimer(timer);
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
	if (IsValidClient(target) && GetClientTeam(target) == 2 || !IsClientInGame(target))
	{
		if(Rabies[target] <= 0)
		{
			KillTimer(timer);
			return;
		}

		RabiesDamage(target);

		if(Rabies[target] > 0)
		{
			CreateTimer(1.0, RabiesTimer, target);
			Rabies[target] -= 1;
		}
	}
	EmitSoundToAll(SOUND_RABIES, target);
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
	if (IsValidClient(target) && GetClientTeam(target) == 2 || !IsClientInGame(target))
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
	}

	if (!IsPlayerAlive(target))
	{
		KillToxin(target);

		return Plugin_Handled;
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

	return Plugin_Handled;
}

public Action WarpTimer(Handle timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		float pos[3];
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(idBoss == idTank[TYPE_GHOST] && idTank[TYPE_LAVA] && idTank[TYPE_GRAVITY] && idTank[TYPE_QUAKE] && idTank[TYPE_DREAD]
			&& idTank[TYPE_FREEZE] && idTank[TYPE_LAZY] && idTank[TYPE_RABIES] && idTank[TYPE_BOMBARD])
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
	
//	AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])) ,power * powHor);
//	AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])) ,power * powHor);
	AimVector[0] = Cosine( DegToRad( HeadingVector[1] ) ) * ( power * powHor );
	AimVector[1] = Sine( DegToRad( HeadingVector[1] ) ) * ( power * powHor );
	
	float current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	float resulting[3];
//	resulting[0] = FloatAdd(current[0], AimVector[0]);	
//	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[0] = current[0] + AimVector[0];	
	resulting[1] = current[1] + AimVector[1];
	resulting[2] = power * powVec;
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

public int ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
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
	if (IsValidClient(target))
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

public Action PrecacheParticle(char[] particlename)
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
	if (client == 0)
		return false;

	if (!IsClientConnected(client))
		return false;
	
	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;

	if (!IsValidEntity(client))
		return false;

	return true;
}

/**
 * Validates if the current client is valid to run the plugin.
 *
 * @param client		The client index.
 * @return              False if the client is not the Tank, true otherwise.
 */
stock bool IsTank( int client )
{
	if ( client > 0 && client <= MaxClients && IsClientInGame( client ) && GetClientTeam( client ) == 3 )
	{
		int class = GetEntProp( client, Prop_Send, "m_zombieClass" );
		if( class == ( bL4D2 ? 8 : 5 ) )
			return true;
	}
	return false;
}

/******************************************************
*	EOF
*******************************************************/