/******************************************************
* 		L4D2: Last Boss (Extended Version) v1.0
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0"
#define DEBUG 0

#define ON				1
#define OFF				0

#define MOLOTOV 		0
#define EXPLODE 		1

#define TYPE_GHOST		0
#define TYPE_LAVA		1
#define TYPE_GRAVITY	2
#define TYPE_QUAKE		3
#define TYPE_LEAPER		4
#define TYPE_DREAD		5

/* Model */
#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"

/* Sound */
#define SOUND_BCLAW		"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SOUND_GCLAW		"plats/churchbell_end.wav"
#define SOUND_DCLAW		"ambient/random_amb_sounds/randbridgegroan_03.wav"
#define SOUND_QUAKE		"player/charger/hit/charger_smash_02.wav"
#define SOUND_STEEL		"physics/metal/metal_solid_impact_hard5.wav"

/* Message */
#define MESSAGE_SPAWN00	"\x05Tank is approaching fast! \x04Type-00\x01[GHOST]"
#define MESSAGE_SPAWN01	"\x05Tank is approaching fast! \x04Type-01\x01[LAVA]"
#define MESSAGE_SPAWN02	"\x05Tank is approaching fast! \x04Type-02\x01[GRAVITY]"
#define MESSAGE_SPAWN03	"\x05Tank is approaching fast! \x04Type-03\x01[QUAKE]"
#define MESSAGE_SPAWN04	"\x05Tank is approaching fast! \x04Type-04\x01[LEAPER]"
#define MESSAGE_SPAWN05	"\x05Tank is approaching fast! \x04Type-05\x01[DREAD]"

/* Parameter */
new Handle:sm_lbex_enable					= INVALID_HANDLE;
new Handle:sm_lbex_enable_finale			= INVALID_HANDLE;
new Handle:sm_lbex_enable_announce			= INVALID_HANDLE;

new Handle:sm_lbex_health_type00			= INVALID_HANDLE;
new Handle:sm_lbex_health_type01			= INVALID_HANDLE;
new Handle:sm_lbex_health_type02			= INVALID_HANDLE;
new Handle:sm_lbex_health_type03			= INVALID_HANDLE;
new Handle:sm_lbex_health_type04			= INVALID_HANDLE;
new Handle:sm_lbex_health_type05			= INVALID_HANDLE;

new Handle:sm_lbex_color_type00				= INVALID_HANDLE;
new Handle:sm_lbex_color_type01				= INVALID_HANDLE;
new Handle:sm_lbex_color_type02				= INVALID_HANDLE;
new Handle:sm_lbex_color_type03				= INVALID_HANDLE;
new Handle:sm_lbex_color_type04				= INVALID_HANDLE;
new Handle:sm_lbex_color_type05				= INVALID_HANDLE;

new Handle:sm_lbex_speed_type00				= INVALID_HANDLE;
new Handle:sm_lbex_speed_type01				= INVALID_HANDLE;
new Handle:sm_lbex_speed_type02				= INVALID_HANDLE;
new Handle:sm_lbex_speed_type03				= INVALID_HANDLE;
new Handle:sm_lbex_speed_type04				= INVALID_HANDLE;
new Handle:sm_lbex_speed_type05				= INVALID_HANDLE;

new Handle:sm_lbex_weight_type02			= INVALID_HANDLE;
new Handle:sm_lbex_stealth_type00			= INVALID_HANDLE;
new Handle:sm_lbex_jumpinterval_type04		= INVALID_HANDLE;
new Handle:sm_lbex_jumpheight_type04		= INVALID_HANDLE;
new Handle:sm_lbex_gravityinterval_type02	= INVALID_HANDLE;
new Handle:sm_lbex_quakeradius_type03		= INVALID_HANDLE;
new Handle:sm_lbex_quakeforce_type03		= INVALID_HANDLE;
new Handle:sm_lbex_dreadinterval_type05		= INVALID_HANDLE;
new Handle:sm_lbex_dreadrate_type05			= INVALID_HANDLE;

/* Grobal */
new idTank[6] = {0, 0, 0, 0, 0, 0};
new alpharate;
new visibility;
new finaleflag = OFF;
new g_iVelocity	= -1;

public Plugin:myinfo = 
{
	name = "[L4D2] LAST BOSS (Extended Version)",
	author = "ztar",
	description = "Six kind of special Tank spawns randomly.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

/******************************************************
*	When plugin started
*******************************************************/
public OnPluginStart()
{
	/* Enable/Disable */
	sm_lbex_enable			= CreateConVar("sm_lbex_enable","1","Six kind of special Tank spawns randomly.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lbex_enable_finale	= CreateConVar("sm_lbex_enable_finale","0","If original LAST BOSS plugin is applied, Turn this OFF.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_lbex_enable_announce	= CreateConVar("sm_lbex_enable_announce","1","Enable Announcement.(0:OFF 1:ON)", FCVAR_NOTIFY);
	
	/* Health */
	sm_lbex_health_type00 = CreateConVar("sm_lbex_health_type00", "6666", "Tank Type-00[GHOST]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type01 = CreateConVar("sm_lbex_health_type01", "5400", "Tank Type-01[LAVA]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type02 = CreateConVar("sm_lbex_health_type02", "8000", "Tank Type-02[GRAVITY]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type03 = CreateConVar("sm_lbex_health_type03", "7000", "Tank Type-03[QUAKE]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type04 = CreateConVar("sm_lbex_health_type04", "4800", "Tank Type-04[LEAPER]:Health", FCVAR_NOTIFY);
	sm_lbex_health_type05 = CreateConVar("sm_lbex_health_type05", "6200", "Tank Type-05[DREAD]:Health", FCVAR_NOTIFY);
	
	/* Color */
	sm_lbex_color_type00	  = CreateConVar("sm_lbex_color_type00", "80 80 255", "Tank Type-00[GHOST]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type01	  = CreateConVar("sm_lbex_color_type01", "255 80 80", "Tank Type-01[LAVA]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type02	  = CreateConVar("sm_lbex_color_type02", "80 255 80", "Tank Type-02[GRAVITY]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type03	  = CreateConVar("sm_lbex_color_type03", "255 255 80", "Tank Type-03[QUAKE]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type04	  = CreateConVar("sm_lbex_color_type04", "80 255 255", "Tank Type-04[LEAPER]:Color(0-255)", FCVAR_NOTIFY);
	sm_lbex_color_type05	  = CreateConVar("sm_lbex_color_type05", "90 90 90", "Tank Type-05[DREAD]:Color(0-255)", FCVAR_NOTIFY);
	
	/* Speed */
	sm_lbex_speed_type00	  = CreateConVar("sm_lbex_speed_type00",  "0.9", "Tank Type-00[GHOST]:Speed",  FCVAR_NOTIFY);
	sm_lbex_speed_type01	  = CreateConVar("sm_lbex_speed_type01",  "1.1", "Tank Type-01[LAVA]:Speed",  FCVAR_NOTIFY);
	sm_lbex_speed_type02	  = CreateConVar("sm_lbex_speed_type02",  "1.0", "Tank Type-02[GRAVITY]:Speed",  FCVAR_NOTIFY);
	sm_lbex_speed_type03	  = CreateConVar("sm_lbex_speed_type03",  "1.0", "Tank Type-03[QUAKE]:Speed",  FCVAR_NOTIFY);
	sm_lbex_speed_type04	  = CreateConVar("sm_lbex_speed_type04",  "1.2", "Tank Type-04[LEAPER]:Speed",  FCVAR_NOTIFY);
	sm_lbex_speed_type05	  = CreateConVar("sm_lbex_speed_type05",  "1.0", "Tank Type-05[DREAD]:Speed",  FCVAR_NOTIFY);
	
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
	
	/* Event hook */
	HookEvent("round_start", Event_Round_Start);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_incapacitated", Event_Player_Hurt);
	HookEvent("finale_start", Event_Finale_Start);
	
	AutoExecConfig(true, "l4d2_lastboss_extend");
	
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
	PrecacheSound(SOUND_BCLAW, true);
	PrecacheSound(SOUND_GCLAW, true);
	PrecacheSound(SOUND_DCLAW, true);
	PrecacheSound(SOUND_QUAKE, true);
	PrecacheSound(SOUND_STEEL, true);
}

InitData()
{
	for(new i = 0; i < 6; i++)
	{
		idTank[i] = 0;
	}
	finaleflag = OFF;
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
	finaleflag = ON;
}

/******************************************************
*	Event when Tank has spawned or dead
*******************************************************/
public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarInt(sm_lbex_enable) || (!GetConVarInt(sm_lbex_enable_finale) && finaleflag))
		return;
	if(idTank[0] && idTank[1] && idTank[2] && idTank[3] && idTank[4] && idTank[5])
		return;
	new idTankSpawn = GetClientOfUserId(GetEventInt(event, "userid"));
	new type = GetRandomInt(0, 5);
	
	while(idTank[type] != 0)
	{
		type = GetRandomInt(0, 5);
	}
	idTank[type] = idTankSpawn;
	
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
	}
	PrintToChatAll(" ");
	
	/* Setup basic status */
	SetEntityHealth(idTank[type], health);
	SetEntPropFloat(idTank[type], Prop_Send, "m_flLaggedMovementValue", speed);
	SetEntityRenderMode(idTank[type], RenderMode:0);
	DispatchKeyValue(idTank[type], "rendercolor", color);
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new idTankDead = GetClientOfUserId(GetEventInt(event, "userid"));
	
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
		if(attacker == idTank[TYPE_LAVA])
		{
			/* Skill:Burning Claw) */
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
	}
	if(StrEqual(weapon, "melee"))
	{
		if(GetEntProp(target, Prop_Send, "m_zombieClass") == 8)
		{
			if(target == idTank[TYPE_GRAVITY])
			{
				/* Skill:Steel Skin */
				EmitSoundToClient(attacker, SOUND_STEEL);
				SetEntityHealth(idTank[TYPE_GRAVITY],
								(GetEventInt(event,"dmg_health")
								+GetEventInt(event,"health")));
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

public SkillEarthQuake(target)
{
	decl Float:Pos[3], Float:tPos[3];
	
	if(IsPlayerIncapped(target))
	{
		for(new i = 1; i <= GetMaxClients(); i++)
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

public SkillDreadClaw(target)
{
	visibility = GetConVarInt(sm_lbex_dreadrate_type05);
	CreateTimer(GetConVarFloat(sm_lbex_dreadinterval_type05), DreadTimer, target);
	EmitSoundToAll(SOUND_DCLAW, target);
	ScreenFade(target, 0, 0, 0, visibility, 0, 0);
}

public SkillGravityClaw(target)
{
	SetEntityGravity(target, 0.3);
	CreateTimer(GetConVarFloat(sm_lbex_gravityinterval_type02), GravityTimer, target);
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
	GetClientAbsOrigin(idTank[TYPE_LAVA], pos);
	LittleFlower(pos, MOLOTOV);
}

/******************************************************
*	Timer functions
*******************************************************/
public Action:GravityTimer(Handle:timer, any:target)
{
	SetEntityGravity(target, 1.0);
}

public Action:JumpingTimer(Handle:timer)
{
	if(idTank[TYPE_LEAPER] && GetEntProp(idTank[TYPE_LEAPER], Prop_Send, "m_zombieClass") == 8)
		AddVelocity(idTank[TYPE_LEAPER], GetConVarFloat(sm_lbex_jumpheight_type04));
	else
		KillTimer(timer);
}

public Action:StealthTimer(Handle:timer)
{
	if(idTank[TYPE_GHOST])
	{
		alpharate = 255;
		Remove(idTank[TYPE_GHOST]);
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

/******************************************************
*	Gimmick functions
*******************************************************/
public Action:Remove(ent)
{
	if(IsValidEntity(ent))
	{
		CreateTimer(0.2, fadeout, ent, TIMER_REPEAT);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	}
}

public Action:fadeout(Handle:Timer, any:ent)
{
	if(!IsValidEntity(ent) || !idTank[TYPE_GHOST])
	{
		KillTimer(Timer);
		return;
	}
	alpharate -= 1;
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

bool:IsPlayerIgnited(client)
{
	if(GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE)
		return true;
	else
		return false;
}

/******************************************************
*	EOF
*******************************************************/