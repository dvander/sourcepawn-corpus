#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define DEBUG 0

#define ON				1
#define OFF				0
#define DEAD		    -1

#define MOLOTOV 		0
#define EXPLODE 		1

#define TYPE_GRAVITY	0
#define TYPE_QUAKE		1
#define TYPE_DREAD		2
#define TYPE_LAZY		3
#define TYPE_RABIES		4
#define TYPE_BOMBARD	5
#define TYPE_SCREAM		6
#define TYPE_SHIELD		7

public Plugin:myinfo = 
{
	name = "l4d2_Variant tanks",
	author = "largedick",
	description = "Variant tanks spawn randomly.",
	version = "0.1",
	url = "//"
}

/* Model */
#define SURVIVOR	2
#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"
#define ENTITY_SHIELD	"models/props_unique/airport/atlas_break_ball.mdl"

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
#define SOUND_SCREAM	"player/tank/voice/yell/tank_yell_01.wav"
#define SOUND_SHIELD	"physics/metal/metal_solid_impact_hard5.wav"

/* Sprite */
#define SPRITE_BEAM		"sprites/laserbeam.vmt"
#define SPRITE_HALO		"sprites/glow01.vmt"
#define SPRITE_LASER	"sprites/laser.vmt"

/* Particle */
#define PARTICLE_DEATH	"gas_explosion_main"
#define PARTICLE_WARP	"water_splash"
#define PARTICLE_SMOKE	"apc_wheel_smoke1"
#define PARTICLE_FIRE	"aircraft_destroy_fastFireTrail"

/* Message */

#define MESSAGE_SPAWN00	"[重力]坦克正在袭来! 小心:该坦克攻击附带失重效果!"
#define MESSAGE_SPAWN01 "[地震]坦克正在袭来! 小心:该坦克攻击倒下的生还者会触发地震让你升天!!!!"
#define MESSAGE_SPAWN02 "[恐惧]坦克正在袭来! 小心:该坦克攻击附带致盲效果!"
#define MESSAGE_SPAWN03 "[懒惰]坦克正在袭来! 小心:该坦克攻击附带减速效果!"
#define MESSAGE_SPAWN04 "[狂狗]坦克正在袭来! 小心:该坦克攻击会产生屏幕歪斜效果!!"
#define MESSAGE_SPAWN05 "[爆炸]坦克正在袭来! 小心:该坦克攻击附带会爆炸效果,造成大量伤害!"
#define MESSAGE_SPAWN06 "[尖叫]坦克正在袭来! 小心:该坦克攻击会发出刺耳尖叫使你失聪!"
#define MESSAGE_SPAWN07 "[护盾]坦克正在袭来! 小心该坦克攻击会生成强力护盾吸收大量伤害!"

/* Parameter */
new Handle:sm_lbex_enable = INVALID_HANDLE;
new Handle:sm_lbex_enable_finale = INVALID_HANDLE;
new Handle:sm_lbex_enable_announce = INVALID_HANDLE;
new Handle:sm_lbex_enable_warp = INVALID_HANDLE;

new Handle:sm_lbex_health_type00 = INVALID_HANDLE;
new Handle:sm_lbex_health_type01 = INVALID_HANDLE;
new Handle:sm_lbex_health_type02 = INVALID_HANDLE;
new Handle:sm_lbex_health_type03 = INVALID_HANDLE;
new Handle:sm_lbex_health_type04 = INVALID_HANDLE;
new Handle:sm_lbex_health_type05 = INVALID_HANDLE;
new Handle:sm_lbex_health_type06 = INVALID_HANDLE;
new Handle:sm_lbex_health_type07 = INVALID_HANDLE;

new Handle:sm_lbex_color_type00	= INVALID_HANDLE;
new Handle:sm_lbex_color_type01	= INVALID_HANDLE;
new Handle:sm_lbex_color_type02	= INVALID_HANDLE;
new Handle:sm_lbex_color_type03	= INVALID_HANDLE;
new Handle:sm_lbex_color_type04	= INVALID_HANDLE;
new Handle:sm_lbex_color_type05	= INVALID_HANDLE;
new Handle:sm_lbex_color_type06	= INVALID_HANDLE;
new Handle:sm_lbex_color_type07	= INVALID_HANDLE;

new Handle:sm_lbex_speed_type00	= INVALID_HANDLE;
new Handle:sm_lbex_speed_type01	= INVALID_HANDLE;
new Handle:sm_lbex_speed_type02	= INVALID_HANDLE;
new Handle:sm_lbex_speed_type03	= INVALID_HANDLE;
new Handle:sm_lbex_speed_type04 = INVALID_HANDLE;
new Handle:sm_lbex_speed_type05 = INVALID_HANDLE;
new Handle:sm_lbex_speed_type06 = INVALID_HANDLE;
new Handle:sm_lbex_speed_type07 = INVALID_HANDLE;

new Handle:sm_lbex_weight_type00 = INVALID_HANDLE;
new Handle:sm_lbex_gravityinterval_type00 = INVALID_HANDLE;
new Handle:sm_lbex_quakeradius_type01 = INVALID_HANDLE;
new Handle:sm_lbex_quakeforce_type01 = INVALID_HANDLE;
new Handle:sm_lbex_dreadinterval_type02	= INVALID_HANDLE;
new Handle:sm_lbex_dreadrate_type02 = INVALID_HANDLE;
new Handle:sm_lbex_lazy_type03 = INVALID_HANDLE;
new Handle:sm_lbex_lazyspeed_type03 = INVALID_HANDLE;
new Handle:sm_lbex_rabies_type04 = INVALID_HANDLE;
new Handle:sm_lbex_bombard_type05 = INVALID_HANDLE;
new Handle:sm_lbex_bombardradius_type05 = INVALID_HANDLE;
new Handle:sm_lbex_bombardforce_type05 = INVALID_HANDLE;
new Handle:sm_lbex_scream_type06 = INVALID_HANDLE;
new Handle:sm_lbex_screamradius_type06 = INVALID_HANDLE;
new Handle:sm_lbex_screaminterval_type06 = INVALID_HANDLE;
new Handle:sm_lbex_shield_health = INVALID_HANDLE;
new Handle:sm_lbex_shield_interval = INVALID_HANDLE;
new Handle:sm_lbex_warp_interval = INVALID_HANDLE;
new Handle:sm_lbex_announce_mode = INVALID_HANDLE;

// UserMessageId for Fade.
new UserMsg:g_FadeUserMsgId;

new Float:ToxinAngle[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

/* Grobal */
new idTank[8] = {0, 0, 0, 0, 0, 0, 0, 0};
new idBoss = DEAD;
new finaleflag = OFF;
new Float:ftlPos[3];
new bool:isSlowed[MAXPLAYERS+1];
static laggedMovementOffset = 0;
new Rabies[MAXPLAYERS+1];
new Toxin[MAXPLAYERS+1];
new Float:trsPos[MAXPLAYERS+1][3];
new DreadVisibility[MAXPLAYERS+1];
new bool:isDeafened[MAXPLAYERS+1];
new Float:g_flScreamRemaining[MAXPLAYERS+1];
new g_iSpriteBeam = 0;
new g_iSpriteHalo = 0;
new g_iSpriteLaser = 0;
new bool:isShielded[MAXPLAYERS+1];
new Float:g_flShieldRemaining[MAXPLAYERS+1];
new g_iShieldProp = 0;



/******************************************************
*	When plugin started
*******************************************************/
public OnPluginStart()
{
	/* Enable/Disable */
	sm_lbex_enable			= CreateConVar("sm_lbex_enable", "1", "Special Tank spawns randomly.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lbex_enable_finale	= CreateConVar("sm_lbex_enable_finale", "0", "If original LAST BOSS plugin is applied, Turn this OFF.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lbex_enable_announce	= CreateConVar("sm_lbex_enable_announce", "1", "Enable Announcement.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lbex_enable_warp		= CreateConVar("sm_lbex_enable_warp", "1", "Last Boss can use FatalMirror.(0:OFF 1:ON)", FCVAR_NOTIFY);

	/* Health */
	sm_lbex_health_type00 = CreateConVar("sm_lbex_health_type00", "8000", "Tank Type-00[GRAVITY]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type01 = CreateConVar("sm_lbex_health_type01", "7000", "Tank Type-01[QUAKE]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type02 = CreateConVar("sm_lbex_health_type02", "6200", "Tank Type-02[DREAD]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type03 = CreateConVar("sm_lbex_health_type03", "8600", "Tank Type-03[LAZY]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type04 = CreateConVar("sm_lbex_health_type04", "9000", "Tank Type-04[RABIES]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type05 = CreateConVar("sm_lbex_health_type05", "8800", "Tank Type-05[BOMBARD]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type06 = CreateConVar("sm_lbex_health_type06", "7500", "Tank Type-06[SCREAM]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type07 = CreateConVar("sm_lbex_health_type07", "9500", "Tank Type-07[SHIELD]:Health", FCVAR_NOTIFY);

	/* Color */
	sm_lbex_color_type00	  = CreateConVar("sm_lbex_color_type00", "80 255 80", "Tank Type-00[GRAVITY]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type01	  = CreateConVar("sm_lbex_color_type01", "255 255 80", "Tank Type-01[QUAKE]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type02	  = CreateConVar("sm_lbex_color_type02", "90 90 90", "Tank Type-02[DREAD]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type03	  = CreateConVar("sm_lbex_color_type03", "200 150 200", "Tank Type-03[LAZY]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type04	  = CreateConVar("sm_lbex_color_type04", "176 48 96", "Tank Type-04[RABIES]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type05	  = CreateConVar("sm_lbex_color_type05", "153 153 255", "Tank Type-05[BOMBARD]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type06   = CreateConVar("sm_lbex_color_type06", "255 100 255", "Tank Type-06[SCREAM]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type07   = CreateConVar("sm_lbex_color_type07", "50 150 255", "Tank Type-07[SHIELD]:Color(0-255)", FCVAR_NOTIFY);

	/* Speed */
	sm_lbex_speed_type00	  = CreateConVar("sm_lbex_speed_type00", "1.0", "Tank Type-00[GRAVITY]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type01	  = CreateConVar("sm_lbex_speed_type01", "1.0", "Tank Type-01[QUAKE]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type02	  = CreateConVar("sm_lbex_speed_type02", "1.0", "Tank Type-02[DREAD]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type03 	  = CreateConVar("sm_lbex_speed_type03", "0.9", "Tank Type-03[LAZY]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type04 	  = CreateConVar("sm_lbex_speed_type04", "0.9", "Tank Type-04[RABIES]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type05 	  = CreateConVar("sm_lbex_speed_type05", "1.3", "Tank Type-05[BOMBARD]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type06 	  = CreateConVar("sm_lbex_speed_type06", "1.1", "Tank Type-06[SCREAM]:Speed", FCVAR_NOTIFY);
	sm_lbex_speed_type07 	  = CreateConVar("sm_lbex_speed_type07", "1.0", "Tank Type-07[SHIELD]:Speed", FCVAR_NOTIFY);

	/* Skill */
	sm_lbex_weight_type00			= CreateConVar("sm_lbex_weight_type00", "10.0", "Tank Type-00[GRAVITY]:Weight", FCVAR_NOTIFY);
	sm_lbex_gravityinterval_type00	= CreateConVar("sm_lbex_gravityinterval_type00", "6.0", "Tank Type-00[GRAVITY]:Interval", FCVAR_NOTIFY);
	sm_lbex_quakeradius_type01		= CreateConVar("sm_lbex_quakeradius_type01", "500.0", "Tank Type-01[QUAKE]:QuakeRadius", FCVAR_NOTIFY);
	sm_lbex_quakeforce_type01		= CreateConVar("sm_lbex_quakeforce_type01", "300.0", "Tank Type-01[QUAKE]:QuakeForce", FCVAR_NOTIFY);
	sm_lbex_dreadinterval_type02	= CreateConVar("sm_lbex_dreadinterval_type02", "8.0", "Tank Type-02[DREAD]:BlindInterval", FCVAR_NOTIFY);
	sm_lbex_dreadrate_type02		= CreateConVar("sm_lbex_dreadrate_type02", "235", "Tank Type-02[DREAD]:BlindRate", FCVAR_NOTIFY);
	sm_lbex_lazy_type03			    = CreateConVar("sm_lbex_lazy_type03", "10.0", "Tank Type-03[LAZY]:LazyTime", FCVAR_NOTIFY);
	sm_lbex_lazyspeed_type03		= CreateConVar("sm_lbex_lazyspeed_type03", "0.3", "Tank Type-03[LAZY]:LazySpeed", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_lbex_rabies_type04			= CreateConVar("sm_lbex_rabies_type04", "10.0", "Tank Type-04[RABIES]:RabiesTime", FCVAR_NOTIFY);
	CreateConVar("sm_lbex_rabiesdamage_type04", "5", "Tank Type-04[RABIES]:RabiesDamage", FCVAR_NOTIFY);
	sm_lbex_bombard_type05		    = CreateConVar("sm_lbex_bombard_type05", "300", "Tank Type-05[BOMBARD]:BombDamage", FCVAR_NOTIFY);
	sm_lbex_bombardradius_type05	= CreateConVar("sm_lbex_bombardradius_type05", "250", "Tank Type-05[BOMBARD]:BombRadius", FCVAR_NOTIFY);
	sm_lbex_bombardforce_type05	= CreateConVar("sm_lbex_bombardforce_type05", "600.0", "Tank Type-05[BOMBARD]:BombForce", FCVAR_NOTIFY);
	sm_lbex_scream_type06		    = CreateConVar("sm_lbex_scream_type06", "5", "Tank Type-06[SCREAM]:ScreamDuration", FCVAR_NOTIFY);
	sm_lbex_screamradius_type06	    = CreateConVar("sm_lbex_screamradius_type06", "600.0", "Tank Type-06[SCREAM]:ScreamRadius", FCVAR_NOTIFY);
	sm_lbex_screaminterval_type06   = CreateConVar("sm_lbex_screaminterval_type06", "1.0", "Tank Type-06[SCREAM]:ScreamInterval", FCVAR_NOTIFY);
	sm_lbex_shield_health		= CreateConVar("sm_lbex_shield_health", "3000", "Tank Type-07[SHIELD]:ShieldHealth", FCVAR_NOTIFY);
	sm_lbex_shield_interval		= CreateConVar("sm_lbex_shield_interval", "0.5", "Tank Type-07[SHIELD]:ShieldInterval", FCVAR_NOTIFY);
	sm_lbex_warp_interval		    = CreateConVar("sm_lbex_warp_interval", "35.0", "Fatal Mirror skill:Interval(all form)", FCVAR_NOTIFY);
	sm_lbex_announce_mode		= CreateConVar("sm_lbex_announce_mode", "1", "Tank spawn announcement mode. (0: PrintToChatAll, 1: PrintHintText)", FCVAR_NOTIFY);

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

	ShieldHookSurvivors();

	AutoExecConfig(true, "l4d2_Variant tanks");
}

public ShieldHookSurvivors()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnShieldedTakeDamage);
		}
	}
}

public Action:OnShieldedTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!GetConVarInt(sm_lbex_enable))
		return Plugin_Continue;

	if(client <= 0 || client > MaxClients)
		return Plugin_Continue;

	if(!IsValidClient(client))
		return Plugin_Continue;

	if(isShielded[client] && attacker > 0 && IsValidEntity(attacker))
	{
		decl String:classname[32];
		GetEntityClassname(attacker, classname, sizeof(classname));

		if(StrEqual(classname, "player"))
		{
			if(IsClientInGame(attacker) && GetClientTeam(attacker) == 3)
			{
				damage *= 0.5;
				g_flShieldRemaining[client] -= damage;
				EmitSoundToClient(client, SOUND_SHIELD);
				ScreenFade(client, 50, 150, 255, 50, 300, 1);
				ShieldBeamEffect(client);

				if(g_flShieldRemaining[client] <= 0.0)
				{
					vDeactivateShield(client);
					damage *= 2.0;
				}
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

/******************************************************
*	Initial functions
*******************************************************/
InitPrecache()
{
	/* Precache models */
	PrecacheModel(ENTITY_PROPANE, true);
	PrecacheModel(ENTITY_GASCAN, true);
	PrecacheModel(ENTITY_SHIELD, true);

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
	PrecacheSound(SOUND_SCREAM, true);
	PrecacheSound(SOUND_SHIELD, true);

	/* Precache particles */
	PrecacheParticle(PARTICLE_DEATH);
	PrecacheParticle(PARTICLE_SMOKE);
	PrecacheParticle(PARTICLE_FIRE);
	PrecacheParticle(PARTICLE_WARP);

	/* Precache sprites */
	g_iSpriteBeam = PrecacheModel(SPRITE_BEAM, true);
	g_iSpriteHalo = PrecacheModel(SPRITE_HALO, true);
	g_iSpriteLaser = PrecacheModel(SPRITE_LASER, true);	
}

InitData()
{
	for(new i = 0; i < 8; i++)
	{
		idTank[i] = 0;
	}
	idBoss = DEAD;
	finaleflag = OFF;
}

public OnMapStart()
{
	InitPrecache();
	InitData();

	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheModel("models/props_junk/gascan001a.mdl", true);

	PrecacheParticle("gas_explosion_pump");
	PrecacheParticle("gas_explosion_main");
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnShieldedTakeDamage);
	}
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
	finaleflag = ON;
}

/******************************************************
*	Event when Tank has spawned or dead
*******************************************************/
public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarInt(sm_lbex_enable) || (!GetConVarInt(sm_lbex_enable_finale) && finaleflag))
		return;

	if(idTank[0] && idTank[1] && idTank[2] && idTank[3] && idTank[4] && idTank[5] && idTank[6] && idTank[7])
		return;

	new idTankSpawn = GetClientOfUserId(GetEventInt(event, "userid"));
	new type = GetRandomInt(0, 7);

	while(idTank[type] != 0)
	{
		type = GetRandomInt(0, 7);
	}
	idTank[type] = idTankSpawn;

	idBoss = idTankSpawn;

	if(IsValidEntity(idTank[type]) && IsClientInGame(idTank[type]))
	{
		SetTankStatus(type);
	}
}

public SetTankStatus(type)
{
	new health;
	new Float:speed;
	decl String:color[32];

	/* Type-00[GRAVITY] */
	if(type == TYPE_GRAVITY)
	{
		health = GetConVarInt(sm_lbex_health_type00);
		speed = GetConVarFloat(sm_lbex_speed_type00);
		GetConVarString(sm_lbex_color_type00, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			if(GetConVarInt(sm_lbex_announce_mode) == 0)
			{
				PrintToChatAll(MESSAGE_SPAWN00);
				PrintToChatAll("  坦克血量:%d  坦克移动速度:%.1f", health, speed);
			}
			else
			{
				ShowHintTextToAll(MESSAGE_SPAWN00, health, speed);			
			}
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
		SetEntityGravity(idTank[type], GetConVarFloat(sm_lbex_weight_type00));
	}

	/* Type-01[QUAKE] */
	else if(type == TYPE_QUAKE)
	{
		health = GetConVarInt(sm_lbex_health_type01);
		speed = GetConVarFloat(sm_lbex_speed_type01);
		GetConVarString(sm_lbex_color_type01, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			if(GetConVarInt(sm_lbex_announce_mode) == 0)
			{
				PrintToChatAll(MESSAGE_SPAWN01);
				PrintToChatAll("  坦克血量:%d  坦克移动速度:%.1f", health, speed);
			}
			else
			{
				ShowHintTextToAll(MESSAGE_SPAWN01, health, speed);
			}	
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}

	/* Type-02[DREAD] */
	else if(type == TYPE_DREAD)
	{
		health = GetConVarInt(sm_lbex_health_type02);
		speed = GetConVarFloat(sm_lbex_speed_type02);
		GetConVarString(sm_lbex_color_type02, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			if(GetConVarInt(sm_lbex_announce_mode) == 0)
			{
				PrintToChatAll(MESSAGE_SPAWN02);
				PrintToChatAll("  坦克血量:%d  坦克移动速度:%.1f", health, speed);
			}
			else
			{
				ShowHintTextToAll(MESSAGE_SPAWN02, health, speed);
			}
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}

	/* Type-03[LAZY] */
	else if(type == TYPE_LAZY)
	{
		health = GetConVarInt(sm_lbex_health_type03);
		speed = GetConVarFloat(sm_lbex_speed_type03);
		GetConVarString(sm_lbex_color_type03, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			if(GetConVarInt(sm_lbex_announce_mode) == 0)
			{
				PrintToChatAll(MESSAGE_SPAWN03);
				PrintToChatAll("  坦克血量:%d  坦克移动速度:%.1f", health, speed);
			}
			else
			{
				ShowHintTextToAll(MESSAGE_SPAWN03, health, speed);
			}
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}

	/* Type-04[RABIES] */
	else if(type == TYPE_RABIES)
	{
		health = GetConVarInt(sm_lbex_health_type04);
		speed = GetConVarFloat(sm_lbex_speed_type04);
		GetConVarString(sm_lbex_color_type04, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			if(GetConVarInt(sm_lbex_announce_mode) == 0)
			{
				PrintToChatAll(MESSAGE_SPAWN04);
				PrintToChatAll("  坦克血量:%d  坦克移动速度:%.1f", health, speed);
			}
			else
			{
				ShowHintTextToAll(MESSAGE_SPAWN04, health, speed);
			}
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}

	/* Type-05[BOMBARD] */
	else if(type == TYPE_BOMBARD)
	{
		health = GetConVarInt(sm_lbex_health_type05);
		speed = GetConVarFloat(sm_lbex_speed_type05);
		GetConVarString(sm_lbex_color_type05, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			if(GetConVarInt(sm_lbex_announce_mode) == 0)
			{
				PrintToChatAll(MESSAGE_SPAWN05);
				PrintToChatAll("  坦克血量:%d  坦克移动速度:%.1f", health, speed);
			}
			else
			{
				ShowHintTextToAll(MESSAGE_SPAWN05, health, speed);
			}
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}

	/* Type-06[SCREAM] */
	else if(type == TYPE_SCREAM)
	{
		health = GetConVarInt(sm_lbex_health_type06);
		speed = GetConVarFloat(sm_lbex_speed_type06);
		GetConVarString(sm_lbex_color_type06, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			if(GetConVarInt(sm_lbex_announce_mode) == 0)
			{
				PrintToChatAll(MESSAGE_SPAWN06);
				PrintToChatAll("  坦克血量:%d  坦克移动速度:%.1f", health, speed);
			}
			else
			{
				ShowHintTextToAll(MESSAGE_SPAWN06, health, speed);
			}
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}

	/* Type-07[SHIELD] */
	else if(type == TYPE_SHIELD)
	{
		health = GetConVarInt(sm_lbex_health_type07);
		speed = GetConVarFloat(sm_lbex_speed_type07);
		GetConVarString(sm_lbex_color_type07, color, sizeof(color));
		if(GetConVarInt(sm_lbex_enable_announce))
		{
			if(GetConVarInt(sm_lbex_announce_mode) == 0)
			{
				PrintToChatAll(MESSAGE_SPAWN07);
				PrintToChatAll("  坦克血量:%d  坦克移动速度:%.1f", health, speed);
			}
			else
			{
				ShowHintTextToAll(MESSAGE_SPAWN07, health, speed);
			}
		}
		if(GetConVarInt(sm_lbex_enable_warp))
		{
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lbex_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
		vCreateShieldProp(idTank[type]);
	}

	PrintToChatAll(" ");

	SetEntityHealth(idTank[type], health);
	SetEntPropFloat(idTank[type], Prop_Send, "m_flLaggedMovementValue", speed);
	SetEntityRenderMode(idTank[type], RenderMode:0);
	DispatchKeyValue(idTank[type], "rendercolor", color);
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new idTankDead = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));	

	if(!GetConVarInt(sm_lbex_enable) || (!GetConVarInt(sm_lbex_enable_finale) && finaleflag))
		return;
	if(idTankDead <= 0 || idTankDead > MaxClients)
		return;
	if(!IsValidEntity(idTankDead) || !IsClientInGame(idTankDead))
		return;
	if(GetEntProp(idTankDead, Prop_Send, "m_zombieClass") != 8)
		return;

	if(idTankDead == idTank[TYPE_GRAVITY])
		idTank[TYPE_GRAVITY] = 0;
	else if(idTankDead == idTank[TYPE_QUAKE])
		idTank[TYPE_QUAKE] = 0;
	else if(idTankDead == idTank[TYPE_DREAD])
		idTank[TYPE_DREAD] = 0;
	else if(idTankDead == idTank[TYPE_LAZY])
		idTank[TYPE_LAZY] = 0;
	else if(idTankDead == idTank[TYPE_RABIES])
		idTank[TYPE_RABIES] = 0;
	else if(idTankDead == idTank[TYPE_BOMBARD])
		idTank[TYPE_BOMBARD] = 0;
	else if(idTankDead == idTank[TYPE_SCREAM])
		idTank[TYPE_SCREAM] = 0;
	else if(idTankDead == idTank[TYPE_SHIELD])
	{
		idTank[TYPE_SHIELD] = 0;
		vDeactivateShield(idTankDead);
		vRemoveShieldProp();
	}

	/* Explode and burn when died */
	if(idTankDead)
	{
		decl Float:Pos[3];
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
		isDeafened[target] = false;
		isShielded[target] = false;
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		isSlowed[target] = false;
		Rabies[target] = 0;
		Toxin[target] = 0;
		isDeafened[target] = false;
		isShielded[target] = false;
	}
}

/******************************************************
*	Special skills when attacking
*******************************************************/
public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!GetConVarInt(sm_lbex_enable) || (!GetConVarInt(sm_lbex_enable_finale) && finaleflag))
		return;

	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	/* Tank primary attack */
	if(StrEqual(weapon, "tank_claw"))
	{
		if(attacker == idTank[TYPE_GRAVITY])
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
		else if(attacker == idTank[TYPE_SCREAM])
		{
			/* Skill:Scream Claw */
			SkillScreamClaw(target);
		}
		else if(attacker == idTank[TYPE_SHIELD])
		{
			/* Skill:Shield Claw */
			SkillShieldClaw(target);
		}
	}

	/* Tank secondly attack */
	if(StrEqual(weapon, "tank_rock"))
	{
		if(attacker == idTank[TYPE_QUAKE])
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
		}
	}
}

public SkillEarthQuake(target)
{
	decl Float:Pos[3], Float:tPos[3];

	if(IsPlayerIncapped(target))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(i == idTank[TYPE_QUAKE])
				continue;
			if(!IsClientInGame(i) || GetClientTeam(i) != 2)
				continue;
			GetClientAbsOrigin(idTank[TYPE_QUAKE], Pos);
			GetClientAbsOrigin(i, tPos);
			if(GetVectorDistance(tPos, Pos) < GetConVarFloat(sm_lbex_quakeradius_type01))
			{
				EmitSoundToClient(i, SOUND_QUAKE);
				ScreenShake(i, 50.0);
				Smash(idTank[TYPE_QUAKE], i, GetConVarFloat(sm_lbex_quakeforce_type01), 1.0, 1.5);
			}
		}
	}
}

public SkillDreadClaw(target)
{
	DreadVisibility[target] = GetConVarInt(sm_lbex_dreadrate_type02);
	CreateTimer(GetConVarFloat(sm_lbex_dreadinterval_type02), DreadTimer, target);
	EmitSoundToAll(SOUND_DCLAW, target);
	ScreenFade(target, 0, 0, 0, DreadVisibility[target], 0, 0);
}

public SkillGravityClaw(target)
{
	SetEntityGravity(target, 0.3);
	CreateTimer(GetConVarFloat(sm_lbex_gravityinterval_type00), GravityTimer, target);
	EmitSoundToAll(SOUND_GCLAW, target);
	ScreenFade(target, 0, 0, 100, 80, 4000, 1);
	ScreenShake(target, 30.0);
}

public SkillLazyClaw(target)
{
	for(new i = 1; i <= MaxClients; i++)
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

public SkillRabiesClaw(target)
{
	Rabies[target] = (GetConVarInt(sm_lbex_rabies_type04));
	CreateTimer(1.0, RabiesTimer, target);
	Toxin[target] = (GetConVarInt(sm_lbex_rabies_type04));
	CreateTimer(1.0, Toxin_Timer, target);
	EmitSoundToAll(SOUND_ROAR, target);
}

public SkillBombClaw(target)
{
	decl Float:Pos[3];

	for(new i = 1; i <= MaxClients; i++)
	{
	    if(i == idTank[TYPE_BOMBARD])
		    continue;
	    if(!IsClientInGame(i) || GetClientTeam(i) != 2)
		    continue;
	    GetClientAbsOrigin(idTank[TYPE_BOMBARD], Pos);
	    if(GetVectorDistance(Pos, trsPos[target]) < GetConVarFloat(sm_lbex_bombardradius_type05))
		{
			DamageEffect(idTank[TYPE_BOMBARD], GetConVarFloat(sm_lbex_bombard_type05));
		}
	}
	EmitSoundToAll(SOUND_BOMBARD, target);
	ScreenShake(target, 100.0);

	LittleFlower(Pos, EXPLODE);

	PushAway(target, GetConVarFloat(sm_lbex_bombardforce_type05), GetConVarFloat(sm_lbex_bombardradius_type05), 0.5);
}

public SkillScreamClaw(target)
{
	new tank = idTank[TYPE_SCREAM];
	decl Float:Pos[3];

	GetClientAbsOrigin(tank, Pos);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(i == tank)
			continue;
		if(!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		if(!IsPlayerAlive(i))
			continue;

		decl Float:tPos[3];
		GetClientAbsOrigin(i, tPos);

		if(GetVectorDistance(Pos, tPos) < GetConVarFloat(sm_lbex_screamradius_type06))
		{
			DeafenPlayer(i);
			EmitSoundToClient(i, SOUND_SCREAM);
		}
	}

	ScreamBeamEffect(Pos, GetConVarFloat(sm_lbex_screamradius_type06));

	g_flScreamRemaining[tank] = float(GetConVarInt(sm_lbex_scream_type06));
	CreateTimer(GetConVarFloat(sm_lbex_screaminterval_type06), ScreamTimer, tank, TIMER_FLAG_NO_MAPCHANGE);
}

ScreamBeamEffect(Float:center[3], Float:radius)
{
	new Float:pos[3];
	pos[0] = center[0];
	pos[1] = center[1];
	pos[2] = center[2] - 10.0;

	TE_SetupBeamRingPoint(pos, 10.0, radius, g_iSpriteBeam, g_iSpriteHalo, 0, 50, 1.0, 88.0, 3.0, {255, 50, 50, 180}, 1000, 0);
	TE_SendToAll();
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

public SkillShieldClaw(target)
{
	new tank = idTank[TYPE_SHIELD];
	if(!IsValidEntity(tank) || !IsClientInGame(tank) || !IsPlayerAlive(tank))
		return;

	decl Float:Pos[3];
	GetClientAbsOrigin(tank, Pos);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(i == tank)
			continue;
		if(!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		if(!IsPlayerAlive(i))
			continue;

		decl Float:tPos[3];
		GetClientAbsOrigin(i, tPos);

		if(GetVectorDistance(Pos, tPos) < 300.0)
		{
			EmitSoundToClient(i, SOUND_SHIELD);
			vActivateShield(i);
		}
	}
}

public vActivateShield(client)
{
	if(!IsValidClient(client) || GetClientTeam(client) != 2)
		return;

	isShielded[client] = true;
	g_flShieldRemaining[client] = float(GetConVarInt(sm_lbex_shield_health));
	SetEntityRenderColor(client, 50, 150, 255, 255);
	CreateTimer(GetConVarFloat(sm_lbex_shield_interval), ShieldTimer, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:ShieldTimer(Handle:timer, any:client)
{
	if(client <= 0 || client > MaxClients)
	{
		return Plugin_Stop;
	}

	if(!IsClientConnected(client) || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		isShielded[client] = false;
		return Plugin_Stop;
	}

	new Float:flRemaining = g_flShieldRemaining[client];
	if(flRemaining <= 0.0)
	{
		vDeactivateShield(client);
		return Plugin_Stop;
	}

	g_flShieldRemaining[client] = flRemaining - 1.0;
	ScreenFade(client, 50, 150, 255, 30, 200, 0);

	new tank = idTank[TYPE_SHIELD];
	if(tank > 0 && IsValidEntity(tank) && IsClientInGame(tank) && IsPlayerAlive(tank))
	{
		decl Float:tankPos[3], Float:clientPos[3];
		GetClientAbsOrigin(tank, tankPos);
		GetClientAbsOrigin(client, clientPos);
		if(GetVectorDistance(tankPos, clientPos) < 400.0)
		{
			ShieldBeamEffect(client);
		}
	}

	CreateTimer(GetConVarFloat(sm_lbex_shield_interval), ShieldTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public vDeactivateShield(client)
{
	isShielded[client] = false;
	g_flShieldRemaining[client] = 0.0;
	if(IsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

ShieldBeamEffect(client)
{
	new Float:clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	clientPos[2] -= 20.0;

	TE_SetupBeamRingPoint(clientPos, 10.0, 40.0, g_iSpriteLaser, g_iSpriteHalo, 0, 10, 0.3, 10.0, 2.0, {50, 150, 255, 200}, 100, 0);
	TE_SendToAll();
}

public vCreateShieldProp(tank)
{
	if(!IsValidEntity(tank) || !IsClientInGame(tank))
		return;

	vRemoveShieldProp();

	new entity = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(entity))
	{
		SetEntityModel(entity, ENTITY_SHIELD);
		SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
		SetEntityRenderMode(entity, RENDER_TRANSTEXTURE);
		SetEntityRenderColor(entity, 50, 150, 255, 150);
		DispatchSpawn(entity);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", tank, entity, 0);

		decl Float:origin[3];
		origin[0] = 0.0;
		origin[1] = 0.0;
		origin[2] = -70.0;
		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

		g_iShieldProp = entity;
	}
}

public vRemoveShieldProp()
{
	if(g_iShieldProp > 0 && IsValidEntity(g_iShieldProp))
	{
		AcceptEntityInput(g_iShieldProp, "Kill");
		g_iShieldProp = 0;
	}
}

/******************************************************
*	Timer functions
*******************************************************/
public Action:GravityTimer(Handle:timer, any:target)
{
	SetEntityGravity(target, 1.0);
}

public Action:DreadTimer(Handle:timer, any:target)
{
	DreadVisibility[target] -= 8;
	if(DreadVisibility[target] < 0)  DreadVisibility[target] = 0;
	ScreenFade(target, 0, 0, 0, DreadVisibility[target], 0, 1);
	if(DreadVisibility[target] <= 0)
	{
		KillTimer(timer);
	}
}

public Action:ScreamTimer(Handle:timer, any:tank)
{
	if(!IsValidEntity(tank) || !IsClientInGame(tank) || !IsClientConnected(tank) || !IsPlayerAlive(tank))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				isDeafened[i] = false;
			}
		}
		g_flScreamRemaining[tank] = 0.0;
		return Plugin_Stop;
	}

	new Float:Pos[3];
	GetClientAbsOrigin(tank, Pos);

	new Float:interval = GetConVarFloat(sm_lbex_screaminterval_type06);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;

		decl Float:tPos[3];
		GetClientAbsOrigin(i, tPos);

		if(GetVectorDistance(Pos, tPos) < GetConVarFloat(sm_lbex_screamradius_type06))
		{
			DeafenPlayer(i);
			EmitSoundToClient(i, SOUND_SCREAM);
			ScreenShake(i, 30.0);
		}
	}

	ScreamBeamEffect(Pos, GetConVarFloat(sm_lbex_screamradius_type06));

	g_flScreamRemaining[tank] -= interval;

	if(g_flScreamRemaining[tank] > 0.0)
	{
		CreateTimer(Float:interval, ScreamTimer, tank, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			isDeafened[i] = false;
		}
	}
	g_flScreamRemaining[tank] = 0.0;

	return Plugin_Stop;
}

public Action:RabiesTimer(Handle:timer, any:target)
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

KillToxin(target)
{
	new Float:pos[3];
	GetClientAbsOrigin(target, pos);
	new Float:angs[3];
	GetClientEyeAngles(target, angs);

	angs[2] = 0.0;

	TeleportEntity(target, pos, angs, NULL_VECTOR);

	new clients[2];
	clients[0] = target;

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

public Action:Toxin_Timer(Handle:timer, any:target)
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

	new Float:pos[3];
	GetClientAbsOrigin(target, pos);

	new Float:angs[3];
	GetClientEyeAngles(target, angs);

	angs[2] = ToxinAngle[GetRandomInt(0,100) % 20];

	TeleportEntity(target, pos, angs, NULL_VECTOR);

	new clients[2];
	clients[0] = target;

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

public Action:WarpTimer(Handle:timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		decl Float:pos[3];

		for(new i = 1; i <= MaxClients; i++)
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
public LittleFlower(Float:pos[3], type)
{
	/* Fire(type=0) or explosion(type=1) */
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
	
	AimVector[0] = Cosine(DegToRad(HeadingVector[1])) * (power * powHor);
	AimVector[1] = Sine(DegToRad(HeadingVector[1])) * (power * powHor);
	
	decl Float:current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	decl Float:resulting[3];
	resulting[0] = current[0] + AimVector[0];
	resulting[1] = current[1] + AimVector[1];
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

public FreezePlayer(target, Float:time)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		SetEntityMoveType(target, MOVETYPE_NONE);
		SetEntityRenderColor(target, 0, 128, 255, 135);
		EmitSoundToAll(SOUND_FREEZE, target);
	}
}

public DeafenPlayer(client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return;

	isDeafened[client] = true;

	new clients[1];
	clients[0] = client;

	new Handle:msg = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(msg, 1536);
	BfWriteShort(msg, 1536);
	BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, 0);
	BfWriteByte(msg, 0);
	BfWriteByte(msg, 0);
	BfWriteByte(msg, 0);
	EndMessage();
}

public LazyPlayer(target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2 && !isSlowed[target])
	{
		isSlowed[target] = true;
		CreateTimer(GetConVarFloat(sm_lbex_lazy_type03), Quick, target);
		SetEntDataFloat(target, laggedMovementOffset, GetConVarFloat(sm_lbex_lazyspeed_type03), true);
		SetEntityRenderColor(target, 255, 255, 255, 135);
		EmitSoundToAll(SOUND_LAZY, target);
	}
}

public Action:Quick(Handle:timer, any:target)
{
	if (IsValidClient(target))
	{
		SetEntDataFloat(target, laggedMovementOffset, 1.0, true);
		isSlowed[target] = false;
		SetEntityRenderColor(target, 255, 255, 255, 255);
		EmitSoundToAll(SOUND_QUICK, target);
	}
}

stock RabiesDamage(target)
{
	new String:dmg_str[16];
	new String:dmg_type_str[16];
	IntToString((1 << 17),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("sm_lbex_rabiesdamage_type04"), dmg_str, sizeof(dmg_str));
	new pointHurt=CreateEntityByName("point_hurt");
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

stock DamageEffect(target, Float:damage)
{
	decl String:tName[20];
	Format(tName, 20, "target%d", target);
	new pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(target, "targetname", tName);
	DispatchKeyValueFloat(pointHurt, "Damage", damage);
	DispatchKeyValue(pointHurt, "DamageTarget", tName);
	DispatchKeyValue(pointHurt, "DamageType", "65536");
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt");
	AcceptEntityInput(pointHurt, "Kill");
}

public PushAway(target, Float:force, Float:radius, Float:duration)
{
	new push = CreateEntityByName("point_push");
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
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}	
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

public Action:DeletePushForce(Handle:timer, any:ent)
{
	if (ent> 0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		decl String:classname[64];
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
bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return true;
	else
		return false;
}

public IsValidClient(client)
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

public ShowHintTextToAll(const String:message[], health, Float:speed)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			PrintHintText(i, "%s\n血量: %d | 速度: %.1f", message, health, speed);
		}
	}
}

/******************************************************
*	EOF
*******************************************************/