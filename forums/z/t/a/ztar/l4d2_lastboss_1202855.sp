/******************************************************
* 				L4D2: Last Boss v2.0
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "2.0"
#define DEBUG 0

#define ON			1
#define OFF			0

#define FORMONE		1
#define FORMTWO		2
#define FORMTHREE	3
#define FORMFOUR	4
#define DEAD		-1

#define SURVIVOR	2
#define CLASS_TANK	8
#define MOLOTOV 	0
#define EXPLODE 	1
#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"

/* Sound */
#define SOUND_EXPLODE	"animation/bombing_run_01.wav"
#define SOUND_SPAWN		"music/pzattack/contusion.wav"
#define SOUND_BCLAW		"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SOUND_GCLAW		"plats/churchbell_end.wav"
#define SOUND_DCLAW		"ambient/random_amb_sounds/randbridgegroan_03.wav"
#define SOUND_QUAKE		"player/charger/hit/charger_smash_02.wav"
#define SOUND_STEEL		"physics/metal/metal_solid_impact_hard5.wav"
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
#define MESSAGE_SPAWN2	"  Helath:?????  SpeedRate:???\n"
#define MESSAGE_SECOND	"\x05Form changed -> \x01[STEEL OVERLOAD]"
#define MESSAGE_THIRD	"\x05Form changed -> \x01[NIGHT STALKER]"
#define MESSAGE_FORTH	"\x05Form changed -> \x01[SPIRIT OF FIRE]"

/* Parameter */
new Handle:sm_lastboss_enable				= INVALID_HANDLE;
new Handle:sm_lastboss_enable_announce		= INVALID_HANDLE;
new Handle:sm_lastboss_enable_steel			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_stealth		= INVALID_HANDLE;
new Handle:sm_lastboss_enable_gravity		= INVALID_HANDLE;
new Handle:sm_lastboss_enable_burn			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_jump			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_quake			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_comet			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_dread			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_gush			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_abyss			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_warp			= INVALID_HANDLE;

new Handle:sm_lastboss_health_max	 		= INVALID_HANDLE;
new Handle:sm_lastboss_health_second 		= INVALID_HANDLE;
new Handle:sm_lastboss_health_third	 		= INVALID_HANDLE;
new Handle:sm_lastboss_health_forth	 		= INVALID_HANDLE;

new Handle:sm_lastboss_color_first 	 		= INVALID_HANDLE;
new Handle:sm_lastboss_color_second	 		= INVALID_HANDLE;
new Handle:sm_lastboss_color_third 	 		= INVALID_HANDLE;
new Handle:sm_lastboss_color_forth			= INVALID_HANDLE;

new Handle:sm_lastboss_force_first 	 		= INVALID_HANDLE;
new Handle:sm_lastboss_force_second			= INVALID_HANDLE;
new Handle:sm_lastboss_force_third 			= INVALID_HANDLE;
new Handle:sm_lastboss_force_forth			= INVALID_HANDLE;

new Handle:sm_lastboss_speed_first 	 		= INVALID_HANDLE;
new Handle:sm_lastboss_speed_second	 		= INVALID_HANDLE;
new Handle:sm_lastboss_speed_third 	 		= INVALID_HANDLE;
new Handle:sm_lastboss_speed_forth	 		= INVALID_HANDLE;

new Handle:sm_lastboss_weight_second		= INVALID_HANDLE;
new Handle:sm_lastboss_stealth_third 		= INVALID_HANDLE;
new Handle:sm_lastboss_jumpinterval_forth	= INVALID_HANDLE;
new Handle:sm_lastboss_jumpheight_forth		= INVALID_HANDLE;
new Handle:sm_lastboss_gravityinterval 		= INVALID_HANDLE;
new Handle:sm_lastboss_quake_radius 		= INVALID_HANDLE;
new Handle:sm_lastboss_quake_force	 		= INVALID_HANDLE;
new Handle:sm_lastboss_dreadinterval 		= INVALID_HANDLE;
new Handle:sm_lastboss_dreadrate	 		= INVALID_HANDLE;
new Handle:sm_lastboss_forth_c5m5_bridge	= INVALID_HANDLE;
new Handle:sm_lastboss_warp_interval		= INVALID_HANDLE;

/* Timer Handle */
new Handle:TimerUpdate = INVALID_HANDLE;

/* Grobal */
new alpharate;
new visibility;
new bossflag = OFF;
new lastflag = OFF;
new idBoss = DEAD;
new form_prev = DEAD;
new force_default;
new g_iVelocity	= -1;
new wavecount;
new Float:ftlPos[3];
new bool:g_l4d1 = false;

public Plugin:myinfo = 
{
	name = "[L4D2] LAST BOSS",
	author = "ztar",
	description = "Special Tank spawns during finale.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

/******************************************************
*	When plugin started
*******************************************************/
public OnPluginStart()
{
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	g_l4d1 = false;
	if(StrEqual(game, "left4dead"))
		g_l4d1 = true;
	
	/* Enable/Disable */
	sm_lastboss_enable			= CreateConVar("sm_lastboss_enable","1","Last Boss spawned in Finale.(0:OFF 1:ON(Finale Only) 2:ON(Always) 3:ON(Second Tank Only)", FCVAR_NOTIFY);
	sm_lastboss_enable_announce	= CreateConVar("sm_lastboss_enable_announce","1","Enable Announcement.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_steel	= CreateConVar("sm_lastboss_enable_steel","1",	 "Last Boss can use SteelSkin.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_stealth	= CreateConVar("sm_lastboss_enable_stealth","1", "Last Boss can use StealthSkin.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_gravity	= CreateConVar("sm_lastboss_enable_gravity","1", "Last Boss can use GravityClaw.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_burn		= CreateConVar("sm_lastboss_enable_burn","1",	 "Last Boss can use BurnClaw.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_quake	= CreateConVar("sm_lastboss_enable_quake","1",	 "Last Boss can use EarthQuake.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_jump		= CreateConVar("sm_lastboss_enable_jump","1",	 "Last Boss can use MadSpring.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_comet	= CreateConVar("sm_lastboss_enable_comet","1",	 "Last Boss can use BlastRock and CometStrike.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_dread	= CreateConVar("sm_lastboss_enable_dread","1",	 "Last Boss can use DreadClaw.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_gush		= CreateConVar("sm_lastboss_enable_gush","1",	 "Last Boss can use FlameGush.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lastboss_enable_abyss	= CreateConVar("sm_lastboss_enable_abyss","1",	 "Last Boss can use CallOfAbyss.(0:OFF 1:ON(Forth form only) 2:ON(All forms))", FCVAR_NOTIFY);
	sm_lastboss_enable_warp		= CreateConVar("sm_lastboss_enable_warp","1",	 "Last Boss can use FatalMirror.(0:OFF 1:ON)", FCVAR_NOTIFY);
	
	/* Health */
	sm_lastboss_health_max	  = CreateConVar("sm_lastboss_health_max",   "30000", "LastBoss:MAX Health",    FCVAR_NOTIFY);
	sm_lastboss_health_second = CreateConVar("sm_lastboss_health_second","22000", "LastBoss:Health(second)", FCVAR_NOTIFY);
	sm_lastboss_health_third  = CreateConVar("sm_lastboss_health_third", "14000", "LastBoss:Health(third)",  FCVAR_NOTIFY);
	sm_lastboss_health_forth  = CreateConVar("sm_lastboss_health_forth", "8000",  "LastBoss:Health(forth)",  FCVAR_NOTIFY);
	
	/* Color */
	sm_lastboss_color_first	  = CreateConVar("sm_lastboss_color_first", "255 255 80", "RGB Value of First form(0-255)", FCVAR_NOTIFY);
	sm_lastboss_color_second  = CreateConVar("sm_lastboss_color_second","80 255 80", "RGB Value of Second form(0-255)", FCVAR_NOTIFY);
	sm_lastboss_color_third	  = CreateConVar("sm_lastboss_color_third", "80 80 255", "RGB Value of Third form(0-255)", FCVAR_NOTIFY);
	sm_lastboss_color_forth	  = CreateConVar("sm_lastboss_color_forth", "255 80 80", "RGB Value of Forth form(0-255)", FCVAR_NOTIFY);
	
	/* Force */
	sm_lastboss_force_first	  = CreateConVar("sm_lastboss_force_first",  "1000", "LastBoss:Force(first)",  FCVAR_NOTIFY);
	sm_lastboss_force_second  = CreateConVar("sm_lastboss_force_second", "1500", "LastBoss:Force(second)", FCVAR_NOTIFY);
	sm_lastboss_force_third	  = CreateConVar("sm_lastboss_force_third",  "800", "LastBoss:Force(third)",  FCVAR_NOTIFY);
	sm_lastboss_force_forth	  = CreateConVar("sm_lastboss_force_forth",  "1800", "LastBoss:Force(forth)",  FCVAR_NOTIFY);
	
	/* Speed */
	sm_lastboss_speed_first	  = CreateConVar("sm_lastboss_speed_first",  "0.9", "LastBoss:Speed(first)",  FCVAR_NOTIFY);
	sm_lastboss_speed_second  = CreateConVar("sm_lastboss_speed_second", "1.1", "LastBoss:Speed(second)", FCVAR_NOTIFY);
	sm_lastboss_speed_third	  = CreateConVar("sm_lastboss_speed_third",  "1.0", "LastBoss:Speed(third)",  FCVAR_NOTIFY);
	sm_lastboss_speed_forth	  = CreateConVar("sm_lastboss_speed_forth",  "1.2", "LastBoss:Speed(forth)",  FCVAR_NOTIFY);
	
	/* Skill */
	sm_lastboss_weight_second		= CreateConVar("sm_lastboss_weight_second", "8.0", "LastBoss:Weight(second)", FCVAR_NOTIFY);
	sm_lastboss_stealth_third		= CreateConVar("sm_lastboss_stealth_third", "10.0", "Stealth skill:Interval(third)", FCVAR_NOTIFY);
	sm_lastboss_jumpinterval_forth  = CreateConVar("sm_lastboss_jumpinterval_forth", "1.0", "Spring skill:Interval(forth)", FCVAR_NOTIFY);
	sm_lastboss_jumpheight_forth  	= CreateConVar("sm_lastboss_jumpheight_forth", "300.0", "Spring skill:Height(forth)", FCVAR_NOTIFY);
	sm_lastboss_gravityinterval		= CreateConVar("sm_lastboss_gravityinterval", "6.0", "Gravity claw skill:Interval(second)", FCVAR_NOTIFY);
	sm_lastboss_quake_radius		= CreateConVar("sm_lastboss_quake_radius", "600.0", "Earth Quake skill:Radius", FCVAR_NOTIFY);
	sm_lastboss_quake_force			= CreateConVar("sm_lastboss_quake_force", "350.0", "Earth Quake skill:Force", FCVAR_NOTIFY);
	sm_lastboss_dreadinterval		= CreateConVar("sm_lastboss_dreadinterval", "8.0", "Dread Claw skill:Interval(third)", FCVAR_NOTIFY);
	sm_lastboss_dreadrate			= CreateConVar("sm_lastboss_dreadrate", "235", "Dread Claw skill:Blind rate(third)", FCVAR_NOTIFY);
	sm_lastboss_forth_c5m5_bridge	= CreateConVar("sm_lastboss_forth_c5m5_bridge", "0", "Form is from the beginning to fourth in c5m5_bridge", FCVAR_NOTIFY);
	sm_lastboss_warp_interval		= CreateConVar("sm_lastboss_warp_interval", "35.0", "Fatal Mirror skill:Interval(all form)", FCVAR_NOTIFY);
	
	/* Event hook */
	HookEvent("round_start", Event_Round_Start);
	HookEvent("finale_start", Event_Finale_Start);
	HookEvent("finale_vehicle_incoming", Event_Finale_Last);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_incapacitated", Event_Player_Hurt);
	if(!g_l4d1)
		HookEvent("finale_bridge_lowering", Event_Finale_Start);
	
	AutoExecConfig(true, "l4d2_lastboss");
	
	force_default = GetConVarInt(FindConVar("z_tank_throw_force"));
	if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
}

/******************************************************
*	Initial functions
*******************************************************/
InitPrecache()
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

InitData()
{
	/* Reset flags */
	bossflag = OFF;
	lastflag = OFF;
	idBoss = DEAD;
	form_prev = DEAD;
	wavecount = 0;
	SetConVarInt(FindConVar("z_tank_throw_force"), force_default, true, true);
}

public OnMapStart()
{
	InitPrecache();
	InitData();
}

public OnMapEnd()
{
	InitData();
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	InitData();
}

public Action:Event_Finale_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	bossflag = ON;
	lastflag = OFF;
	
	/* Exception handling for some map */
	decl String:CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if(StrEqual(CurrentMap, "c1m4_atrium") || StrEqual(CurrentMap, "c5m5_bridge"))
		wavecount = 2;
	else
		wavecount = 1;
}

public Action:Event_Finale_Last(Handle:event, const String:name[], bool:dontBroadcast)
{
	lastflag = ON;
}

/******************************************************
*	Event when Tank has spawned or dead
*******************************************************/
public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:CurrentMap[64];
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
	if( (bossflag && GetConVarInt(sm_lastboss_enable) == 1) ||
					(GetConVarInt(sm_lastboss_enable) == 2) ||
		(bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsValidEntity(client) && IsClientInGame(client))
		{
			/* Get boss ID and set timer */
			CreateTimer(0.3, SetTankHealth, client);
			if(TimerUpdate != INVALID_HANDLE)
			{
				CloseHandle(TimerUpdate);
				TimerUpdate = INVALID_HANDLE;
			}
			TimerUpdate = CreateTimer(1.0, TankUpdate, _, TIMER_REPEAT);
			
			for(new j = 1; j <= MaxClients; j++)
			{
				if(IsClientInGame(j) && !IsFakeClient(j))
				{
					EmitSoundToClient(j, SOUND_SPAWN);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_announce))
			{
				PrintToChatAll(MESSAGE_SPAWN);
				PrintToChatAll(MESSAGE_SPAWN2);
			}
		}
	}
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
	if(client <= 0 || client > GetMaxClients())
		return;
	if(!IsValidEntity(client) || !IsClientInGame(client))
		return;
	if(GetEntProp(client, Prop_Send, "m_zombieClass") != CLASS_TANK)
		return;
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
	{
		wavecount++;
		return;
	}
	
	if( (bossflag && GetConVarInt(sm_lastboss_enable) == 1) ||
					(GetConVarInt(sm_lastboss_enable) == 2) ||
		(bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		/* Explode and burn when died */
		if(idBoss)
		{
			decl Float:Pos[3];
			GetClientAbsOrigin(idBoss, Pos);
			EmitSoundToAll(SOUND_EXPLODE, idBoss);
			ShowParticle(Pos, PARTICLE_DEATH, 5.0);
			LittleFlower(Pos, MOLOTOV);
			LittleFlower(Pos, EXPLODE);
			idBoss = DEAD;
			form_prev = DEAD;
		}
	}
}

public Action:SetTankHealth(Handle:timer, any:client)
{
	/* Set health and ID after spawning */
	idBoss = client;
	decl String:CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss))
	{
		/* In some map, Form is from the beginning to fourth */
		if(lastflag || (StrEqual(CurrentMap, "c5m5_bridge") && GetConVarInt(sm_lastboss_forth_c5m5_bridge)))
			SetEntityHealth(idBoss, GetConVarInt(sm_lastboss_health_forth));
		else
			SetEntityHealth(idBoss, GetConVarInt(sm_lastboss_health_max));
	}
}

/******************************************************
*	Special skills when attacking
*******************************************************/
public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if(!IsValidEntity(idBoss) || !IsClientInGame(idBoss) || idBoss == DEAD)
		return;
	
	/* Second Tank only? */
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	
	/* Special ability */
	if( (bossflag && GetConVarInt(sm_lastboss_enable) == 1) ||
					(GetConVarInt(sm_lastboss_enable) == 2) ||
		(bossflag && GetConVarInt(sm_lastboss_enable) == 3))
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
					SetEntityHealth(idBoss, (GetEventInt(event,"dmg_health") + GetEventInt(event,"health")));
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

public SkillEarthQuake(target)
{
	decl Float:Pos[3], Float:tPos[3];
	
	if(IsPlayerIncapped(target))
	{
		for(new i = 1; i <= GetMaxClients(); i++)
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

public SkillDreadClaw(target)
{
	visibility = GetConVarInt(sm_lastboss_dreadrate);
	CreateTimer(GetConVarFloat(sm_lastboss_dreadinterval), DreadTimer, target);
	EmitSoundToAll(SOUND_DCLAW, target);
	ScreenFade(target, 0, 0, 0, visibility, 0, 0);
}

public SkillGravityClaw(target)
{
	SetEntityGravity(target, 0.3);
	CreateTimer(GetConVarFloat(sm_lastboss_gravityinterval), GravityTimer, target);
	EmitSoundToAll(SOUND_GCLAW, target);
	ScreenFade(target, 0, 0, 100, 80, 4000, 1);
	ScreenShake(target, 30.0);
}

public SkillBurnClaw(target)
{
	new health = GetClientHealth(target);
	if(health > 0 && !IsPlayerIncapped(target))
	{
		SetEntityHealth(target, 1);
		SetEntPropFloat(target, Prop_Send, "m_healthBuffer", float(health));
	}
	EmitSoundToAll(SOUND_BCLAW, target);
	ScreenFade(target, 200, 0, 0, 150, 80, 1);
	ScreenShake(target, 50.0);
}

public SkillCometStrike(target, type)
{	
	decl Float:pos[3];
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

public SkillFlameGush(target)
{
	decl Float:pos[3];
	
	SkillBurnClaw(target);
	GetClientAbsOrigin(idBoss, pos);
	LittleFlower(pos, MOLOTOV);
}

public SkillCallOfAbyss()
{
	/* Stop moving and prevent all damage for a while */
	SetEntityMoveType(idBoss, MOVETYPE_NONE);
	SetEntProp(idBoss, Prop_Data, "m_takedamage", 0, 1);
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(!IsValidEntity(i) || !IsClientInGame(i) || GetClientTeam(i) != SURVIVOR)
			continue;
		EmitSoundToClient(i, SOUND_HOWL);
		ScreenShake(i, 20.0);
	}
	/* Panic event */
	if((form_prev == FORMFOUR && GetConVarInt(sm_lastboss_enable_abyss) == 1) ||
		GetConVarInt(sm_lastboss_enable_abyss) == 2)
	{
		TriggerPanicEvent();
	}
	
	/* After 5sec, change form and start moving */
	CreateTimer(5.0, HowlTimer);
}

/******************************************************
*	Check Tank condition and update status
*******************************************************/
public Action:TankUpdate(Handle:timer)
{
	if(!IsValidEntity(idBoss) || !IsClientInGame(idBoss) || idBoss == DEAD)
		return;
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	new health = GetClientHealth(idBoss);
	
	/* First form */
	if(health > GetConVarInt(sm_lastboss_health_second))
	{
		if(form_prev != FORMONE)
			SetPrameter(FORMONE);
	}
	/* Second form */
	else if(GetConVarInt(sm_lastboss_health_second) >= health &&
			health > GetConVarInt(sm_lastboss_health_third))
	{
		if(form_prev != FORMTWO)
			SetPrameter(FORMTWO);
	}
	/* Third form */
	else if(GetConVarInt(sm_lastboss_health_third) >= health &&
			health > GetConVarInt(sm_lastboss_health_forth))
	{
		/* Can't burn */
		ExtinguishEntity(idBoss);
		if(form_prev != FORMTHREE)
			SetPrameter(FORMTHREE);
	}
	/* Forth form */
	else if(GetConVarInt(sm_lastboss_health_forth) >= health &&
			health > 0)
	{
		if(form_prev != FORMFOUR)
			SetPrameter(FORMFOUR);
	}
}

public SetPrameter(form_next)
{
	new force;
	new Float:speed;
	decl String:color[32];
	
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
		for(new j = 1; j <= GetMaxClients(); j++)
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
	}
	
	/* Set force */
	SetConVarInt(FindConVar("z_tank_throw_force"), force, true, true);
	
	/* Set speed */
	SetEntPropFloat(idBoss, Prop_Send, "m_flLaggedMovementValue", speed);
	
	/* Set color */
	SetEntityRenderMode(idBoss, RenderMode:0);
	DispatchKeyValue(idBoss, "rendercolor", color);
}

/******************************************************
*	Timer functions
*******************************************************/
public Action:ParticleTimer(Handle:timer)
{
	if(form_prev == FORMTHREE)
		AttachParticle(idBoss, PARTICLE_THIRD);
	else if(form_prev == FORMFOUR)
		AttachParticle(idBoss, PARTICLE_FORTH);
	else
		KillTimer(timer);
}

public Action:GravityTimer(Handle:timer, any:target)
{
	SetEntityGravity(target, 1.0);
}

public Action:JumpingTimer(Handle:timer)
{
	if(form_prev == FORMFOUR && idBoss)
		AddVelocity(idBoss, GetConVarFloat(sm_lastboss_jumpheight_forth));
	else
		KillTimer(timer);
}

public Action:StealthTimer(Handle:timer)
{
	if(form_prev == FORMTHREE && idBoss)
	{
		alpharate = 255;
		Remove(idBoss);
	}
}

public Action:DreadTimer(Handle:timer, any:target)
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

public Action:HowlTimer(Handle:timer)
{
	if(idBoss)
	{
		SetEntityMoveType(idBoss, MOVETYPE_WALK);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 2, 1);
	}
}

public Action:WarpTimer(Handle:timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		decl Float:pos[3];
		
		for(new i = 1; i <= GetMaxClients(); i++)
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
		KillTimer(timer);
	}
}

public Action:GetSurvivorPosition(Handle:timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		new count = 0;
		new idAlive[MAXPLAYERS+1];
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != SURVIVOR)
				continue;
			idAlive[count] = i;
			count++;
		}
		if(count == 0) return;
		new clientNum = GetRandomInt(0, count-1);
		GetClientAbsOrigin(idAlive[clientNum], ftlPos);
	}
	else
	{
		KillTimer(timer);
	}
}

public Action:FatalMirror(Handle:timer)
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
public Action:Remove(ent)
{
	if(IsValidEntity(ent))
	{
		CreateTimer(0.1, fadeout, ent, TIMER_REPEAT);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	}
}

public Action:fadeout(Handle:Timer, any:ent)
{
	if(!IsValidEntity(ent) || form_prev != FORMTHREE)
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

public AddVelocity(client, Float:zSpeed)
{
	if(g_iVelocity == -1) return;
	
	new Float:vecVelocity[3];
	GetEntDataVector(client, g_iVelocity, vecVelocity);
	vecVelocity[2] += zSpeed;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

public LittleFlower(Float:pos[3], type)
{
	/* Cause fire(type=0) or explosion(type=1) */
	new entity = CreateEntityByName("prop_physics");
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

public Smash(client, target, Float:power, Float:powHor, Float:powVec)
{
	/* Blow off target */
	decl Float:HeadingVector[3], Float:AimVector[3];
	GetClientEyeAngles(client, HeadingVector);
	
	AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])) ,power * powHor);
	AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])) ,power * powHor);
	
	decl Float:current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	decl Float:resulting[3];
	resulting[0] = FloatAdd(current[0], AimVector[0]);	
	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[2] = power * powVec;
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	new Handle:msg = StartMessageOne("Fade", target);
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

public TriggerPanicEvent()
{
	new flager = GetAnyClient();
	if(flager == -1)  return;
	new flag = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flag & ~FCVAR_CHEAT);
	FakeClientCommand(flager, "director_force_panic_event");
}

/******************************************************
*	Particle control functions
*******************************************************/
public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	/* Show particle effect you like */
	new particle = CreateEntityByName("info_particle_system");
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

public AttachParticle(ent, String:particleType[])
{
	decl String:tName[64];
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
	}
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	/* Delete particle */
    if (IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
            RemoveEdict(particle);
	}
}

public PrecacheParticle(String:particlename[])
{
	/* Precache particle */
	new particle = CreateEntityByName("info_particle_system");
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

/******************************************************
*	Other functions
*******************************************************/
bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return true;
	else
		return false;
}

GetAnyClient()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEntity(i) && IsClientInGame(i))
			return i;
	}
	return -1;
}

/******************************************************
*	EOF
*******************************************************/