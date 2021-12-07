/******************************************************
* 				L4D2: Last Boss v2.2
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.2"
#define DEBUG 0

#define ON			1
#define OFF			0

#define FORMONE		1
#define FORMTWO		2
#define FORMTHREE	3
#define FORMFOUR	4
#define DEAD		-1

#define SURVIVOR	2
#define MOLOTOV 	0
#define EXPLODE 	1
#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"
#define ENTITY_TIRE		"models/props_vehicles/tire001c_car.mdl"

/* Sound */
#define SOUND_EXPLODE	"animation/bombing_run_01.wav"
#define SOUND_SPAWN		"music/pzattack/contusion.wav"
#define SOUND_BCLAW		"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SOUND_GCLAW		"plats/churchbell_end.wav"
#define SOUND_DCLAW		"ambient/random_amb_sounds/randbridgegroan_03.wav"
#define SOUND_QUAKE		"player/charger/hit/charger_smash_02.wav"
#define SOUND_STEEL		"physics/metal/metal_solid_impact_hard5.wav"
#define SOUND_DEAD		"npc/infected/action/die/male/death_42.wav"
#define SOUND_CHANGE	"items/suitchargeok1.wav"
#define SOUND_HOWL		"player/tank/voice/pain/tank_fire_08.wav"
#define SOUND_WARP		"ambient/energy/zap9.wav"

/* Particle */
#define PARTICLE_SPAWN	"electrical_arc_01_system"
#define PARTICLE_DEATH	"gas_explosion_main"
#define PARTICLE_THIRD	"apc_wheel_smoke1"
#define PARTICLE_FORTH	"aircraft_destroy_fastFireTrail"
#define PARTICLE_WARP	"water_splash"

/* Message */
#define MESSAGE_SPAWN	"\x05Ready for Last Battle! \x04Type-UNKNOWN\x01[THE BOSS]"
#define MESSAGE_SPAWN2	"Helath:?????  SpeedRate:???\n"
#define MESSAGE_SECOND	"\x05Form changed -> \x01[STEEL OVERLOAD]"
#define MESSAGE_THIRD	"\x05Form changed -> \x01[NIGHT STALKER]"
#define MESSAGE_FORTH	"\x05Form changed -> \x01[SPIRIT OF FIRE]"

/* Parameter */
Handle sm_lastboss_enable				= INVALID_HANDLE;
Handle sm_lastboss_enable_announce		= INVALID_HANDLE;
Handle sm_lastboss_enable_steel			= INVALID_HANDLE;
Handle sm_lastboss_enable_stealth		= INVALID_HANDLE;
Handle sm_lastboss_enable_gravity		= INVALID_HANDLE;
Handle sm_lastboss_enable_burn			= INVALID_HANDLE;
Handle sm_lastboss_enable_jump			= INVALID_HANDLE;
Handle sm_lastboss_enable_quake			= INVALID_HANDLE;
Handle sm_lastboss_enable_comet			= INVALID_HANDLE;
Handle sm_lastboss_enable_dread			= INVALID_HANDLE;
Handle sm_lastboss_enable_gush			= INVALID_HANDLE;
Handle sm_lastboss_enable_abyss			= INVALID_HANDLE;
Handle sm_lastboss_enable_warp			= INVALID_HANDLE;

Handle sm_lastboss_health_max	 		= INVALID_HANDLE;
Handle sm_lastboss_health_second 		= INVALID_HANDLE;
Handle sm_lastboss_health_third	 		= INVALID_HANDLE;
Handle sm_lastboss_health_forth	 		= INVALID_HANDLE;

Handle sm_lastboss_color_first 	 		= INVALID_HANDLE;
Handle sm_lastboss_color_second	 		= INVALID_HANDLE;
Handle sm_lastboss_color_third 	 		= INVALID_HANDLE;
Handle sm_lastboss_color_forth			= INVALID_HANDLE;

Handle sm_lastboss_force_first 	 		= INVALID_HANDLE;
Handle sm_lastboss_force_second			= INVALID_HANDLE;
Handle sm_lastboss_force_third 			= INVALID_HANDLE;
Handle sm_lastboss_force_forth			= INVALID_HANDLE;

Handle sm_lastboss_speed_first 	 		= INVALID_HANDLE;
Handle sm_lastboss_speed_second	 		= INVALID_HANDLE;
Handle sm_lastboss_speed_third 	 		= INVALID_HANDLE;
Handle sm_lastboss_speed_forth	 		= INVALID_HANDLE;

Handle sm_lastboss_weight_second		= INVALID_HANDLE;
Handle sm_lastboss_stealth_third 		= INVALID_HANDLE;
Handle sm_lastboss_jumpinterval_forth	= INVALID_HANDLE;
Handle sm_lastboss_jumpheight_forth		= INVALID_HANDLE;
Handle sm_lastboss_gravityinterval 		= INVALID_HANDLE;
Handle sm_lastboss_quake_radius 		= INVALID_HANDLE;
Handle sm_lastboss_quake_force	 		= INVALID_HANDLE;
Handle sm_lastboss_dreadinterval 		= INVALID_HANDLE;
Handle sm_lastboss_dreadrate	 		= INVALID_HANDLE;
Handle sm_lastboss_forth_c5m5_bridge	= INVALID_HANDLE;
Handle sm_lastboss_warp_interval		= INVALID_HANDLE;

/* Timer Handle */
Handle TimerUpdate = INVALID_HANDLE;

/* Grobal */
int alpharate;
int visibility;
int bossflag = OFF;
int lastflag = OFF;
int idBoss = DEAD;
int form_prev = DEAD;
int force_default;
int g_iVelocity	= -1;
int wavecount;
float ftlPos[3];

static bool bL4D2;

public Plugin myinfo = 
{
	name 		= "[L4D1 AND L4D2] LAST BOSS",
	author 		= "Ztar, Edited By Ernecio (Satanael)",
	description = "Special Tank spawning in final chapters or map course.",
	version 	= PLUGIN_VERSION,
	url 		= "http://ztar.blog7.fc2.com/"
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
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "This Plugin \"Last Boss\" only runs in the \"Left 4 Dead 1/2\" Games!.");
		return APLRes_SilentFailure;
	}
	
	bL4D2 = (engine == Engine_Left4Dead2);
	return APLRes_Success;
}

/******************************************************
*	When plugin started
*******************************************************/
public void OnPluginStart()
{
	/* Enable/Disable */
	sm_lastboss_enable			= CreateConVar("sm_lastboss_enable", 			"1", 	"Last Boss spawned in Finale.(0:OFF 1:ON(Finale Only) 2:ON(Always) 3:ON(Second Tank Only)", FCVAR_NOTIFY);
	sm_lastboss_enable_announce	= CreateConVar("sm_lastboss_enable_announce", 	"1", 	"Enable Announcement.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_steel	= CreateConVar("sm_lastboss_enable_steel", 		"1",	"Last Boss can use SteelSkin.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_stealth	= CreateConVar("sm_lastboss_enable_stealth", 	"1", 	"Last Boss can use StealthSkin.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_gravity	= CreateConVar("sm_lastboss_enable_gravity", 	"1", 	"Last Boss can use GravityClaw.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_burn		= CreateConVar("sm_lastboss_enable_burn", 		"1",	"Last Boss can use BurnClaw.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_quake	= CreateConVar("sm_lastboss_enable_quake", 		"1",	"Last Boss can use EarthQuake.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_jump		= CreateConVar("sm_lastboss_enable_jump", 		"1",	"Last Boss can use MadSpring.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_comet	= CreateConVar("sm_lastboss_enable_comet", 		"1",	"Last Boss can use BlastRock and CometStrike.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_dread	= CreateConVar("sm_lastboss_enable_dread", 		"1",	"Last Boss can use DreadClaw.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_gush		= CreateConVar("sm_lastboss_enable_gush", 		"1",	"Last Boss can use FlameGush.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_abyss	= CreateConVar("sm_lastboss_enable_abyss", 		"1",	"Last Boss can use CallOfAbyss.(0:OFF 1:ON(Forth form only) 2:ON(All forms))", FCVAR_NOTIFY);
	sm_lastboss_enable_warp		= CreateConVar("sm_lastboss_enable_warp", 		"1",	"Last Boss can use FatalMirror.(0:OFF 1:ON)", FCVAR_NOTIFY);
	
	/* Health */
	sm_lastboss_health_max	  = CreateConVar("sm_lastboss_health_max", 		"30000", 	"LastBoss:MAX Health", FCVAR_NOTIFY);
	sm_lastboss_health_second = CreateConVar("sm_lastboss_health_second", 	"22000", 	"LastBoss:Health(second)", FCVAR_NOTIFY);
	sm_lastboss_health_third  = CreateConVar("sm_lastboss_health_third", 	"14000", 	"LastBoss:Health(third)", FCVAR_NOTIFY);
	sm_lastboss_health_forth  = CreateConVar("sm_lastboss_health_forth", 	"8000", 	"LastBoss:Health(forth)", FCVAR_NOTIFY);
	
	/* Color */
	sm_lastboss_color_first	  = CreateConVar("sm_lastboss_color_first", 	"255 255 80", 	"RGB Value of First form(0-255)", FCVAR_NOTIFY);
	sm_lastboss_color_second  = CreateConVar("sm_lastboss_color_second", 	"80 255 80", 	"RGB Value of Second form(0-255)", FCVAR_NOTIFY);
	sm_lastboss_color_third	  = CreateConVar("sm_lastboss_color_third", 	"80 80 255", 	"RGB Value of Third form(0-255)", FCVAR_NOTIFY);
	sm_lastboss_color_forth	  = CreateConVar("sm_lastboss_color_forth", 	"255 80 80", 	"RGB Value of Forth form(0-255)", FCVAR_NOTIFY);
	
	/* Force */
	sm_lastboss_force_first	  = CreateConVar("sm_lastboss_force_first", 	"1000", 	"LastBoss:Force(first)",  FCVAR_NOTIFY);
	sm_lastboss_force_second  = CreateConVar("sm_lastboss_force_second", 	"1500", 	"LastBoss:Force(second)", FCVAR_NOTIFY);
	sm_lastboss_force_third	  = CreateConVar("sm_lastboss_force_third", 	"800", 		"LastBoss:Force(third)",  FCVAR_NOTIFY);
	sm_lastboss_force_forth	  = CreateConVar("sm_lastboss_force_forth", 	"1800", 	"LastBoss:Force(forth)",  FCVAR_NOTIFY);
	
	/* Speed */
	sm_lastboss_speed_first	  = CreateConVar("sm_lastboss_speed_first", 	"0.9", 		"LastBoss:Speed(first)",  FCVAR_NOTIFY);
	sm_lastboss_speed_second  = CreateConVar("sm_lastboss_speed_second", 	"1.1", 		"LastBoss:Speed(second)", FCVAR_NOTIFY);
	sm_lastboss_speed_third	  = CreateConVar("sm_lastboss_speed_third", 	"1.0", 		"LastBoss:Speed(third)",  FCVAR_NOTIFY);
	sm_lastboss_speed_forth	  = CreateConVar("sm_lastboss_speed_forth", 	"1.2", 		"LastBoss:Speed(forth)",  FCVAR_NOTIFY);
	
	/* Skill */
	sm_lastboss_weight_second		= CreateConVar("sm_lastboss_weight_second", 		"8.0", 		"LastBoss:Weight(second)", FCVAR_NOTIFY);
	sm_lastboss_stealth_third		= CreateConVar("sm_lastboss_stealth_third", 		"10.0", 	"Stealth skill:Interval(third)", FCVAR_NOTIFY);
	sm_lastboss_jumpinterval_forth  = CreateConVar("sm_lastboss_jumpinterval_forth", 	"1.0", 		"Spring skill:Interval(forth)", FCVAR_NOTIFY);
	sm_lastboss_jumpheight_forth  	= CreateConVar("sm_lastboss_jumpheight_forth", 		"300.0", 	"Spring skill:Height(forth)", FCVAR_NOTIFY);
	sm_lastboss_gravityinterval		= CreateConVar("sm_lastboss_gravityinterval", 		"6.0", 		"Gravity claw skill:Interval(second)", FCVAR_NOTIFY);
	sm_lastboss_quake_radius		= CreateConVar("sm_lastboss_quake_radius", 			"600.0", 	"Earth Quake skill:Radius", FCVAR_NOTIFY);
	sm_lastboss_quake_force			= CreateConVar("sm_lastboss_quake_force", 			"350.0", 	"Earth Quake skill:Force", FCVAR_NOTIFY);
	sm_lastboss_dreadinterval		= CreateConVar("sm_lastboss_dreadinterval", 		"8.0", 		"Dread Claw skill:Interval(third)", FCVAR_NOTIFY);
	sm_lastboss_dreadrate			= CreateConVar("sm_lastboss_dreadrate", 			"235", 		"Dread Claw skill:Blind rate(third)", FCVAR_NOTIFY);
	sm_lastboss_forth_c5m5_bridge	= CreateConVar("sm_lastboss_forth_c5m5_bridge", 	"0", 		"Form is from the beginning to fourth in c5m5_bridge", FCVAR_NOTIFY);
	sm_lastboss_warp_interval		= CreateConVar("sm_lastboss_warp_interval", 		"35.0", 	"Fatal Mirror skill:Interval(all form)", FCVAR_NOTIFY);
	CreateConVar( 									"sm_lbex_lavadamage_type01", 		"150", 		"LastBoss:LavaDamage(third)", FCVAR_NOTIFY);
	
	/* Event hook */
	HookEvent("round_start", Event_Round_Start);
	HookEvent("finale_start", Event_Finale_Start);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_incapacitated", Event_Player_Hurt);
	HookEvent("round_end", Event_RoundEnd);
	if ( bL4D2 ) HookEvent("finale_bridge_lowering", Event_Finale_Start);
	if ( bL4D2 ) HookEvent("finale_vehicle_incoming", Event_Finale_Last);
	
	AutoExecConfig(true, "l4d_lastboss");
	
	force_default = GetConVarInt( FindConVar( "z_tank_throw_force" ) );
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
	PrecacheSound(SOUND_SPAWN, true);
	PrecacheSound(SOUND_BCLAW, true);
	PrecacheSound(SOUND_GCLAW, true);
	PrecacheSound(SOUND_DCLAW, true);
	PrecacheSound(SOUND_QUAKE, true);
	PrecacheSound(SOUND_STEEL, true);
	PrecacheSound(SOUND_DEAD, true);
	PrecacheSound(SOUND_CHANGE, true);
	PrecacheSound(SOUND_HOWL, true);
	PrecacheSound(SOUND_WARP, true);
	
	/* Precache particles */
	PrecacheParticle(PARTICLE_SPAWN);
	PrecacheParticle(PARTICLE_DEATH);
	PrecacheParticle(PARTICLE_THIRD);
	PrecacheParticle(PARTICLE_FORTH);
	PrecacheParticle(PARTICLE_WARP);
}

void InitData()
{
	/* Reset flags */
	bossflag = OFF;
	lastflag = OFF;
	idBoss = DEAD;
	form_prev = DEAD;
	wavecount = 0;
	FindConVar("z_tank_throw_force").IntValue = force_default;
}

public void OnMapStart()
{
	InitPrecache();
	InitData();
}

public void OnMapEnd()
{
	InitData();
}

public void Event_Round_Start(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	InitData();
}

public void Event_Finale_Start(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	bossflag = ON;
	lastflag = OFF;
	
	/* Exception handling for some map */
	static char CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if( StrEqual( CurrentMap, "c1m4_atrium") || StrEqual(CurrentMap, "c5m5_bridge" ) ) wavecount = 2;
	else wavecount = 1;
}

public void Event_Finale_Last(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	lastflag = ON;
}

/******************************************************
*	Event when Tank has spawned or dead
*******************************************************/
public void Event_Tank_Spawn( Event hEvent, const char[] sName, bool bDontBroadcast)
{
	static char CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	/* Exception handling for some map */
	if(StrEqual(CurrentMap, "c1m4_atrium") || StrEqual(CurrentMap, "c5m5_bridge"))
		bossflag = ON;
	
	/* Already exists? */
	if(idBoss != DEAD)
		return;
	
	/* Second Tank only? */
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	
	/* Finale only */
	if( (bossflag && GetConVarInt(sm_lastboss_enable) == 1) || (GetConVarInt(sm_lastboss_enable) == 2) || (bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		int client = GetClientOfUserId(hEvent.GetInt( "userid" ) );
		if(IsValidEntity(client) && IsClientInGame(client))
		{
			/* Get boss ID and set timer */
//			CreateTimer(0.3, SetTankHealth, client);
			CreateTimer( 0.3, SetTankHealth, client, TIMER_FLAG_NO_MAPCHANGE );
			if(TimerUpdate != INVALID_HANDLE)
			{
				CloseHandle(TimerUpdate);
				TimerUpdate = INVALID_HANDLE;
			}
			
			TimerUpdate = CreateTimer(1.0, TankUpdate, _, TIMER_REPEAT);
			
			for(int j = 1; j <= MaxClients; j++)
				if(IsClientInGame(j) && !IsFakeClient(j))
					EmitSoundToClient(j, SOUND_SPAWN);
				
			if(GetConVarInt(sm_lastboss_enable_announce))
			{
				PrintToChatAll(MESSAGE_SPAWN);
				PrintToChatAll(MESSAGE_SPAWN2);
			}
		}
	}
}

public void Event_Player_Death(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	
	if(client <= 0 || client > MaxClients )
		return;
	if(!IsValidEntity(client) || !IsClientInGame(client))
		return;
	if( !IsTank( client ) )
		return;
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
	{
		wavecount++;
		return;
	}
	
	if( (bossflag && GetConVarInt(sm_lastboss_enable) == 1) || (GetConVarInt(sm_lastboss_enable) == 2) || (bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		idBoss = client;
		float Pos[3];
		GetClientAbsOrigin(idBoss, Pos);
		EmitSoundToAll(SOUND_EXPLODE, idBoss);
		ShowParticle(Pos, PARTICLE_DEATH, 5.0);
		LittleFlower(Pos, MOLOTOV);
		LittleFlower(Pos, EXPLODE);
		idBoss = DEAD;
		form_prev = DEAD;
	}
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
	{
		static char model[128];
		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, ENTITY_TIRE))
		{
			int owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
				AcceptEntityInput(entity, "Kill");
		}
	}
	
	for (int target=1; target<=MaxClients; target++)
		if (IsClientInGame(target) && GetClientTeam(target) == 2)
			SetEntityGravity(target, 1.0);
}

public void Event_RoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	for (int target=1; target<=MaxClients; target++)
		if (IsClientInGame(target) && GetClientTeam(target) == 2)
			SetEntityGravity(target, 1.0);
}

public Action SetTankHealth(Handle hTimer, any client)
{
	/* Set health and ID after spawning */
	idBoss = client;
	static char CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss))
	{
		/* In some map, Form is from the beginning to fourth */
		if( lastflag || ( StrEqual(CurrentMap, "c5m5_bridge" ) && GetConVarInt( sm_lastboss_forth_c5m5_bridge ) ) )
			SetEntityHealth(idBoss, GetConVarInt(sm_lastboss_health_forth));
		else
			SetEntityHealth(idBoss, GetConVarInt(sm_lastboss_health_max));
	}
}

/******************************************************
*	Special skills when attacking
*******************************************************/
public void Event_Player_Hurt( Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt( "attacker" ) );
	int target = GetClientOfUserId(hEvent.GetInt( "userid" ) );
	
	static char weapon[64];
	GetEventString( hEvent, "weapon", weapon, sizeof(weapon));
	
	if(!IsValidEntity(idBoss) || !IsClientInGame(idBoss) || idBoss == DEAD)
		return;
	
	/* Second Tank only? */
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	
	/* Special ability */
	if( (bossflag && GetConVarInt(sm_lastboss_enable) == 1) || (GetConVarInt(sm_lastboss_enable) == 2) || (bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		if(StrEqual(weapon, "tank_claw") && attacker == idBoss)
		{
			if(GetConVarInt(sm_lastboss_enable_quake))
			{
				/* Skill:Earth Quake (If target is incapped) */
				SkillEarthQuake(target);
			}
			if(GetConVarInt(sm_lastboss_enable_gravity))
			{
				if(form_prev == FORMTWO)
				{
					/* Skill:Gravity Claw (Second form only) */
					SkillGravityClaw(target);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_dread))
			{
				if(form_prev == FORMTHREE)
				{
					/* Skill:Dread Claw (Third form only) */
					SkillDreadClaw(target);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_burn))
			{
				if(form_prev == FORMFOUR)
				{
					/* Skill:Burning Claw (Forth form only) */
					SkillBurnClaw(target);
				}
			}
		}
		if(StrEqual(weapon, "tank_rock") && attacker == idBoss)
		{
			if(GetConVarInt(sm_lastboss_enable_comet))
			{
				if(form_prev == FORMFOUR)
				{
					/* Skill:Comet Strike (Forth form only) */
					SkillCometStrike(target, MOLOTOV);
				}
				else
				{
					/* Skill:Blast Rock (First-Third form) */
					SkillCometStrike(target, EXPLODE);
				}
			}
		}
		if(StrEqual(weapon, "melee") && target == idBoss)
		{
			if(GetConVarInt(sm_lastboss_enable_steel))
			{
				if(form_prev == FORMTWO)
				{
					/* Skill:Steel Skin (Second form only) */
					EmitSoundToClient(attacker, SOUND_STEEL);
					SetEntityHealth(idBoss, GetEventInt( hEvent, "dmg_health" ) + GetEventInt( hEvent, "health" ) );
				}
			}
			if(form_prev == FORMTHREE)
			{
				int random = GetRandomInt(1,4);
				if (random == 1)
				{
					ForceWeaponDrop(attacker);
					EmitSoundToClient(attacker, SOUND_DEAD);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_gush))
			{
				if(form_prev == FORMFOUR)
				{
					/* Skill:Flame Gush (Forth form only) */
					SkillFlameGush(attacker);
				}
			}
		}
	}
}

public void SkillEarthQuake(int target)
{
	float Pos[3], tPos[3];
	
	if(IsPlayerIncapped(target))
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i == idBoss)
				continue;
			if(!IsClientInGame(i) || GetClientTeam(i) != 2)
				continue;
			
			GetClientAbsOrigin(idBoss, Pos);
			GetClientAbsOrigin(i, tPos);
			if(GetVectorDistance(tPos, Pos) < GetConVarFloat(sm_lastboss_quake_radius))
			{
				EmitSoundToClient(i, SOUND_QUAKE);
				ScreenShake(i, 60.0);
				Smash(idBoss, i, GetConVarFloat(sm_lastboss_quake_force), 1.0, 1.5);
			}
		}
	}
}

public void SkillDreadClaw(int target)
{
	visibility = GetConVarInt(sm_lastboss_dreadrate);
	CreateTimer(GetConVarFloat(sm_lastboss_dreadinterval), DreadTimer, target);
	EmitSoundToAll(SOUND_DCLAW, target);
	ScreenFade(target, 0, 0, 0, visibility, 0, 0);
}

public void SkillGravityClaw(int target)
{
	SetEntityGravity(target, 0.3);
	CreateTimer(GetConVarFloat(sm_lastboss_gravityinterval), GravityTimer, target);
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
	GetClientAbsOrigin(idBoss, pos);
	LittleFlower(pos, MOLOTOV);
}

public void SkillCallOfAbyss()
{
	/* Stop moving and prevent all damage for a while */
	SetEntityMoveType(idBoss, MOVETYPE_NONE);
	SetEntProp(idBoss, Prop_Data, "m_takedamage", 0, 1);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidEntity(i) || !IsClientInGame(i) || GetClientTeam(i) != SURVIVOR)
			continue;
		EmitSoundToClient(i, SOUND_HOWL);
		ScreenShake(i, 20.0);
	}
	/* Panic event */
	if((form_prev == FORMFOUR && GetConVarInt(sm_lastboss_enable_abyss) == 1) || GetConVarInt(sm_lastboss_enable_abyss) == 2)
		TriggerPanicEvent();
	
	/* After 5sec, change form and start moving */
	CreateTimer(5.0, HowlTimer);
}

/******************************************************
*	Check Tank condition and update status
*******************************************************/
public Action TankUpdate(Handle hTimer)
{
	if(!IsValidEntity(idBoss) || !IsClientInGame(idBoss) || idBoss == DEAD)
		return;
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	int health = GetClientHealth(idBoss);
	
	/* First form */
	if(health > GetConVarInt(sm_lastboss_health_second))
	{
		if(form_prev != FORMONE)
			SetPrameter(FORMONE);
	}
	/* Second form */
	else if(GetConVarInt(sm_lastboss_health_second) >= health && health > GetConVarInt(sm_lastboss_health_third))
	{
		if(form_prev != FORMTWO)
			SetPrameter(FORMTWO);
	}
	/* Third form */
	else if(GetConVarInt(sm_lastboss_health_third) >= health && health > GetConVarInt(sm_lastboss_health_forth))
	{
		/* Can't burn */
		ExtinguishEntity(idBoss);
		if(form_prev != FORMTHREE)
			SetPrameter(FORMTHREE);
	}
	/* Forth form */
	else if(GetConVarInt(sm_lastboss_health_forth) >= health && health > 0)
	{
		if(form_prev != FORMFOUR)
			SetPrameter(FORMFOUR);
	}
}

public void SetPrameter(int form_next)
{
	int force;
	float speed;
	static char color[32];
	
	form_prev = form_next;
	
	if(form_next != FORMONE)
	{
		if(GetConVarInt(sm_lastboss_enable_abyss))
		{
			/* Skill:Call of Abyss (Howl and Trigger panic event) */
			SkillCallOfAbyss();
		}
		
		/* Skill:Reflesh (Extinguish if fired) */
		ExtinguishEntity(idBoss);
		
		/* Show effect when form has changed */
		AttachParticle(idBoss, PARTICLE_SPAWN);
		for(int j = 1; j <= MaxClients; j++)
		{
			if(!IsClientInGame(j) || GetClientTeam(j) != 2)
				continue;
			EmitSoundToClient(j, SOUND_CHANGE);
			ScreenFade(j, 200, 200, 255, 255, 100, 1);
		}
	}
	
	/* Setup status of each form */
	if(form_next == FORMONE)
	{
		force = GetConVarInt(sm_lastboss_force_first);
		speed = GetConVarFloat(sm_lastboss_speed_first);
		GetConVarString(sm_lastboss_color_first, color, sizeof(color));
		
		/* Skill:Fatal Mirror (Teleport near the survivor) */
		if(GetConVarInt(sm_lastboss_enable_warp))
		{
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lastboss_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}
	else if(form_next == FORMTWO)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll(MESSAGE_SECOND);
		force = GetConVarInt(sm_lastboss_force_second);
		speed = GetConVarFloat(sm_lastboss_speed_second);
		GetConVarString(sm_lastboss_color_second, color, sizeof(color));
		
		/* Weight increases */
		SetEntityGravity(idBoss, GetConVarFloat(sm_lastboss_weight_second));
	}
	else if(form_next == FORMTHREE)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll(MESSAGE_THIRD);
		force = GetConVarInt(sm_lastboss_force_third);
		speed = GetConVarFloat(sm_lastboss_speed_third);
		GetConVarString(sm_lastboss_color_third, color, sizeof(color));
		SetEntityGravity(idBoss, 1.0);
		
		/* Attach particle */
		CreateTimer(0.8, ParticleTimer, _, TIMER_REPEAT);
		
		/* Skill:Stealth Skin */
		if(GetConVarInt(sm_lastboss_enable_stealth))
			CreateTimer(GetConVarFloat(sm_lastboss_stealth_third), StealthTimer);
	}
	else if(form_next == FORMFOUR)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll(MESSAGE_FORTH);
		SetEntityRenderMode(idBoss, RENDER_TRANSCOLOR);
		SetEntityRenderColor(idBoss, _, _, _, 255);
		
		force = GetConVarInt(sm_lastboss_force_forth);
		speed = GetConVarFloat(sm_lastboss_speed_forth);
		GetConVarString(sm_lastboss_color_forth, color, sizeof(color));
		SetEntityGravity(idBoss, 1.0);
		
		/* Ignite */
		IgniteEntity(idBoss, 9999.9);
		
		/* Skill:Mad Spring */
		if(GetConVarInt(sm_lastboss_enable_jump))
			CreateTimer(GetConVarFloat(sm_lastboss_jumpinterval_forth), JumpingTimer, _, TIMER_REPEAT);
			
		float Origin[3], Angles[3];
		GetEntPropVector(idBoss, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(idBoss, Prop_Send, "m_angRotation", Angles);
		Angles[0] += 90.0;
		int ent[3];
		for (int count=1; count<=2; count++)
		{
			ent[count] = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(ent[count]))
			{
				char tName[64];
				Format(tName, sizeof(tName), "Tank%d", idBoss);
				DispatchKeyValue(idBoss, "targetname", tName);
				GetEntPropString(idBoss, Prop_Data, "m_iName", tName, sizeof(tName));

				DispatchKeyValue(ent[count], "model", ENTITY_TIRE);
				DispatchKeyValue(ent[count], "targetname", "TireEntity");
				DispatchKeyValue(ent[count], "parentname", tName);
				GetConVarString(sm_lastboss_color_forth, color, sizeof(color));
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
				SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", idBoss);
				TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	
	/* Set force */
	SetConVarInt(FindConVar("z_tank_throw_force"), force, true, true);
	
	/* Set speed */
	SetEntPropFloat(idBoss, Prop_Send, "m_flLaggedMovementValue", speed);
	
	/* Set color */
	SetEntityRenderMode(idBoss, view_as<RenderMode>( 0 ));
	DispatchKeyValue(idBoss, "rendercolor", color);
}

/******************************************************
*	Timer functions
*******************************************************/
public Action ParticleTimer(Handle hTimer)
{
	if(form_prev == FORMTHREE && IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
		AttachParticle(idBoss, PARTICLE_THIRD);
	else if(form_prev == FORMFOUR && IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
		AttachParticle(idBoss, PARTICLE_FORTH);
	else
		KillTimer( hTimer );
}

public Action GravityTimer(Handle hTimer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
		SetEntityGravity(target, 1.0);
}

public Action JumpingTimer(Handle hTimer)
{
	if(form_prev == FORMFOUR && IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
		AddVelocity(idBoss, GetConVarFloat(sm_lastboss_jumpheight_forth));
	else
		KillTimer(hTimer);
}

public Action StealthTimer(Handle hTimer)
{
	if(form_prev == FORMTHREE && idBoss)
	{
		alpharate = 255;
		Remove(idBoss);
	}
}

public Action DreadTimer(Handle hTimer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		visibility -= 8;
		if(visibility < 0)  visibility = 0;
		ScreenFade(target, 0, 0, 0, visibility, 0, 1);
		if(visibility <= 0)
		{
			visibility = 0;
			KillTimer(hTimer);
		}
	}
}

public Action HowlTimer(Handle hTimer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		SetEntityMoveType(idBoss, MOVETYPE_WALK);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 2, 1);
	}
}

public Action WarpTimer(Handle hTimer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		float pos[3];
		
		for(int i = 1; i <= MaxClients; i++)
		{
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
		KillTimer(hTimer);
	}
}

public Action GetSurvivorPosition(Handle hTimer)
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
		KillTimer(hTimer);
	}
}

public Action FatalMirror(Handle hTimer)
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
		KillTimer(hTimer);
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

public Action fadeout(Handle hTimer, any ent)
{
	if(!IsValidEntity(ent) || form_prev != FORMTHREE)
	{
		KillTimer(hTimer);
		return;
	}
	alpharate -= 2;
	if (alpharate < 0)  alpharate = 0;
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 80, 80, 255, alpharate);
	if(alpharate <= 0)
	{
		KillTimer(hTimer);
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
	/* Cause fire(type=0) or explosion(type=1) */
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
	
	static float current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	static float resulting[3];
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

public void TriggerPanicEvent()
{
	int flager = GetAnyClient();
	if(flager == -1)  return;
	int flag = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flag & ~FCVAR_CHEAT);
	FakeClientCommand(flager, "director_force_panic_event");
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

public Action DeleteParticles(Handle hTimer, any particle)
{
	/* Delete particle */
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
			RemoveEdict(particle);
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

public bool IsValidClient(int client)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(client))
		return false;
	
	return true;
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

int GetAnyClient()
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsValidEntity(i) && IsClientInGame(i))
			return i;
		
	return -1;
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

stock void LavaDamage(int target)
{
	char dmg_lava[16];
	char dmg_type_lava[16];
	IntToString((1 << 17),dmg_lava,sizeof(dmg_type_lava));
	GetConVarString(FindConVar("sm_lbex_lavadamage_type01"), dmg_lava, sizeof(dmg_lava));
	int pointHurt=CreateEntityByName("point_hurt");
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

/**
 * Validates if the current client is valid to run the plugin.
 *
 * @param client		The client index.
 * @return              False if the client is not the Tank, true otherwise.
 */
stock bool IsTank( int client )
{
	if( client > 0 && client <= MaxClients && IsClientInGame( client ) && GetClientTeam( client ) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == ( bL4D2 ? 8 : 5 ) )
			return true;
	}
	return false;
}