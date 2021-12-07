#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "2.0"

#define ON 1
#define OFF 0

#define FORMONE 1
#define FORMTWO 2
#define FORMTHREE 3
#define FORMFOUR 4
#define DEAD -1

#define SURVIVOR 2
#define CLASS_TANK 8

#define MOLOTOV 0
#define EXPLODE 1

#define ENTITY_GASCAN "models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE "models/props_junk/propanecanister001a.mdl"

#define SOUND_EXPLODE "animation/bombing_run_01.wav"
#define SOUND_SPAWN "music/pzattack/contusion.wav"
#define SOUND_BCLAW "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SOUND_GCLAW "plats/churchbell_end.wav"
#define SOUND_DCLAW "ambient/random_amb_sounds/randbridgegroan_03.wav"
#define SOUND_QUAKE "player/charger/hit/charger_smash_02.wav"
#define SOUND_STEEL "physics/metal/metal_solid_impact_hard5.wav"
#define SOUND_CHANGE "items/suitchargeok1.wav"
#define SOUND_HOWL "player/tank/voice/pain/tank_fire_08.wav"
#define SOUND_WARP "ambient/energy/zap9.wav"

#define PARTICLE_SPAWN "electrical_arc_01_system"
#define PARTICLE_DEATH "gas_explosion_main"
#define PARTICLEThird "apc_wheel_smoke1"
#define PARTICLELast "aircraft_destroy_fastFireTrail"
#define PARTICLE_WARP "water_splash"

#define MESSAGE_SPAWN "\x05Get Ready For Boss Battle! \x04Type=Super Tank\x01"
#define MESSAGESecond "\x05Form Changed! => \x01[STEEL OVERLOAD]"
#define MESSAGEThird "\x05Form Changed! => \x01[NIGHT STALKER]"
#define MESSAGELast "\x05Form Changed! => \x01[SPIRIT OF FIRE]"

new Handle:hLastBoss = INVALID_HANDLE;
new Handle:hLastBossAnnounce = INVALID_HANDLE;
new Handle:hLastBossSteel = INVALID_HANDLE;
new Handle:hLastBossStealth = INVALID_HANDLE;
new Handle:hLastBossGravity = INVALID_HANDLE;
new Handle:hLastBossBurn = INVALID_HANDLE;
new Handle:hLastBossJump = INVALID_HANDLE;
new Handle:hLastBossQuake = INVALID_HANDLE;
new Handle:hLastBossComet = INVALID_HANDLE;
new Handle:hLastBossDread = INVALID_HANDLE;
new Handle:hLastBossGush = INVALID_HANDLE;
new Handle:hLastBossAbyss = INVALID_HANDLE;
new Handle:hLastBossWarp = INVALID_HANDLE;

new Handle:hLastBossHealthMax = INVALID_HANDLE;
new Handle:hLastBossHealthSecond = INVALID_HANDLE;
new Handle:hLastBossHealthThird = INVALID_HANDLE;
new Handle:hLastBossHealthMin = INVALID_HANDLE;

new Handle:hLastBossColorFirst = INVALID_HANDLE;
new Handle:hLastBossColorSecond = INVALID_HANDLE;
new Handle:hLastBossColorThird = INVALID_HANDLE;
new Handle:hLastBossColorLast = INVALID_HANDLE;

new Handle:hLastBossForceFirst = INVALID_HANDLE;
new Handle:hLastBossForceSecond = INVALID_HANDLE;
new Handle:hLastBossForceThird = INVALID_HANDLE;
new Handle:hLastBossForceLast = INVALID_HANDLE;

new Handle:hLastBossSpeedFirst = INVALID_HANDLE;
new Handle:hLastBossSpeedSecond = INVALID_HANDLE;
new Handle:hLastBossSpeedThird = INVALID_HANDLE;
new Handle:hLastBossSpeedLast = INVALID_HANDLE;

new Handle:hLastBossWeightSecond = INVALID_HANDLE;
new Handle:hLastBossStealthThird = INVALID_HANDLE;
new Handle:hLastBossJumpIntervalLast = INVALID_HANDLE;
new Handle:hLastBossJumpHeightLast = INVALID_HANDLE;
new Handle:hLastBossGravityInterval = INVALID_HANDLE;
new Handle:hLastBossEarthQuakeRadius = INVALID_HANDLE;
new Handle:hLastBossEarthQuakeForce = INVALID_HANDLE;
new Handle:hLastBossDreadInterval = INVALID_HANDLE;
new Handle:hLastBossDreadRate = INVALID_HANDLE;
new Handle:hLastBossLastTheParish = INVALID_HANDLE;
new Handle:hLastBossWarpInterval = INVALID_HANDLE;

new Handle:TimerUpdate = INVALID_HANDLE;

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
	name = "Last Boss",
	author = "ztar",
	description = "Gives Finale And Escape Tanks Special Abilities.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

public OnPluginStart()
{
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	g_l4d1 = false;
	if(StrEqual(game, "left4dead"))
	{
		g_l4d1 = true;
	}
	
	hLastBoss = CreateConVar("last_boss_enable", "1", "Enable Mode: 0=Off, 1=Finales Only, 2=On, 3=Finale Second Waves Only", FCVAR_NOTIFY);
	hLastBossAnnounce = CreateConVar("last_boss_announce", "1", "Enable/Disable Announcements", FCVAR_NOTIFY);
	hLastBossSteel = CreateConVar("last_boss_steel", "1", "Enable/Disable Steel Skin Skill", FCVAR_NOTIFY);
	hLastBossStealth = CreateConVar("last_boss_stealth", "1", "Enable/Disable Stealth Skin Skill", FCVAR_NOTIFY);
	hLastBossGravity = CreateConVar("last_boss_gravity", "1", "Enable/Disable Gravity Claw Skill", FCVAR_NOTIFY);
	hLastBossBurn = CreateConVar("last_boss_burn", "1", "Enable/Disable Burn Claw Skill", FCVAR_NOTIFY);
	hLastBossQuake = CreateConVar("last_boss_quake", "1", "Enable/Disable Earth Quake Skill", FCVAR_NOTIFY);
	hLastBossJump = CreateConVar("last_boss_jump", "1", "Enable/Disable Mad Spring Skill", FCVAR_NOTIFY);
	hLastBossComet = CreateConVar("last_boss_comet", "1", "Enable/Disable Blast Rock And Comet Strike Skills", FCVAR_NOTIFY);
	hLastBossDread = CreateConVar("last_boss_dread", "1", "Enable/Disable Dread Claw Skill", FCVAR_NOTIFY);
	hLastBossGush = CreateConVar("last_boss_gush", "1", "Enable/Disable Flame Gush Skill", FCVAR_NOTIFY);
	hLastBossAbyss = CreateConVar("last_boss_abyss", "1", "Call Of Abyss Mode: 0=Off, 1=Last Form Only, 2=On", FCVAR_NOTIFY);
	hLastBossWarp = CreateConVar("last_boss_warp", "1", "Enable/Disable Fatal Mirror Skill", FCVAR_NOTIFY);
	
	hLastBossHealthMax = CreateConVar("last_boss_health_max", "35000", "Health Given To First Form", FCVAR_NOTIFY);
	hLastBossHealthSecond = CreateConVar("last_boss_health_second", "27000", "Health Given To Second Form", FCVAR_NOTIFY);
	hLastBossHealthThird = CreateConVar("last_boss_health_third", "21000", "Health Given To Third Form", FCVAR_NOTIFY);
	hLastBossHealthMin = CreateConVar("last_boss_health_min", "18000", "Health Given To Last Form", FCVAR_NOTIFY);
	
	hLastBossColorFirst = CreateConVar("last_boss_color_first", "255 255 80", "Color Painted On First Form", FCVAR_NOTIFY);
	hLastBossColorSecond = CreateConVar("last_boss_color_second", "80 255 80", "Color Painted On Second Form", FCVAR_NOTIFY);
	hLastBossColorThird = CreateConVar("last_boss_color_third", "80 80 255", "Color Painted On Third Form", FCVAR_NOTIFY);
	hLastBossColorLast = CreateConVar("last_boss_color_last", "255 80 80", "Color Painted On Last Form", FCVAR_NOTIFY);
	
	hLastBossForceFirst = CreateConVar("last_boss_force_first", "1400", "Force Of First Form", FCVAR_NOTIFY);
	hLastBossForceSecond = CreateConVar("last_boss_force_second", "1600", "Force Of Second Form", FCVAR_NOTIFY);
	hLastBossForceThird = CreateConVar("last_boss_force_third", "1200", "Force Of Third Form", FCVAR_NOTIFY);
	hLastBossForceLast = CreateConVar("last_boss_force_last", "1800", "Force Of Last Form", FCVAR_NOTIFY);
	
	hLastBossSpeedFirst = CreateConVar("last_boss_speed_first", "0.9", "Speed Of First Form", FCVAR_NOTIFY);
	hLastBossSpeedSecond = CreateConVar("last_boss_speed_second", "1.1", "Speed Of Second Form", FCVAR_NOTIFY);
	hLastBossSpeedThird = CreateConVar("last_boss_speed_third", "1.0", "Speed Of Third Form", FCVAR_NOTIFY);
	hLastBossSpeedLast = CreateConVar("last_boss_speed_last", "1.2", "Speed Of Last Form", FCVAR_NOTIFY);
	
	hLastBossWeightSecond = CreateConVar("last_boss_weight_second", "8.0", "Weight Added To Second Form", FCVAR_NOTIFY);
	hLastBossStealthThird = CreateConVar("last_boss_stealth_third", "10", "Interval Of Third Form: Stealth Skin Skill", FCVAR_NOTIFY);
	hLastBossJumpIntervalLast = CreateConVar("last_boss_jumpinterval_last", "7", "Interval Of Last Form: Mad Spring Skill", FCVAR_NOTIFY);
	hLastBossJumpHeightLast = CreateConVar("last_boss_jumpheight_last", "300", "Height Added To Last Form: Mad Spring Skill", FCVAR_NOTIFY);
	hLastBossGravityInterval = CreateConVar("last_boss_gravityinterval", "6", "Interval Of Second Form: Gravity Claw Skill", FCVAR_NOTIFY);
	hLastBossEarthQuakeRadius = CreateConVar("last_boss_earthquake_radius", "600", "Radius Covered Of Earth Quake Skill", FCVAR_NOTIFY);
	hLastBossEarthQuakeForce = CreateConVar("last_boss_earthquake_force", "350", "Force Applied Of Earth Quake Skill", FCVAR_NOTIFY);
	hLastBossDreadInterval = CreateConVar("last_boss_dreadinterval", "8", "Interval Of Third Form: Dread Claw Skill", FCVAR_NOTIFY);
	hLastBossDreadRate = CreateConVar("last_boss_dreadrate", "215", "Blind Rate Of Dread Claw Skill", FCVAR_NOTIFY);
	hLastBossLastTheParish = CreateConVar("last_boss_last_c5m5", "0", "Enable/Disable Last Form Only In The Parish Finale", FCVAR_NOTIFY);
	hLastBossWarpInterval = CreateConVar("last_boss_warp_interval", "20", "Interval Of Fatal Mirror Skill", FCVAR_NOTIFY);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("finale_start", OnFinaleStart);
	HookEvent("finale_vehicle_incoming", OnFinaleVehicleIncoming);
	HookEvent("tank_spawn", OnTankSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("player_incapacitated", OnPlayerHurt);
	if(!g_l4d1)
	{
		HookEvent("finale_bridge_lowering", OnFinaleStart);
	}
	
	AutoExecConfig(true, "last_boss");
	
	force_default = GetConVarInt(FindConVar("z_tank_throw_force"));
	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
}

InitPrecache()
{
	PrecacheModel(ENTITY_PROPANE, true);
	PrecacheModel(ENTITY_GASCAN, true);
	
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
	
	PrecacheParticle(PARTICLE_SPAWN);
	PrecacheParticle(PARTICLE_DEATH);
	PrecacheParticle(PARTICLEThird);
	PrecacheParticle(PARTICLELast);
	PrecacheParticle(PARTICLE_WARP);
}

InitData()
{
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

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	InitData();
}

public Action:OnFinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	bossflag = ON;
	lastflag = OFF;
	
	decl String:CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if(StrEqual(CurrentMap, "c1m4_atrium") || StrEqual(CurrentMap, "c5m5_bridge"))
	{
		wavecount = 2;
	}
	else
	{
		wavecount = 1;
	}
}

public Action:OnFinaleVehicleIncoming(Handle:event, const String:name[], bool:dontBroadcast)
{
	lastflag = ON;
}

public Action:OnTankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if(StrEqual(CurrentMap, "c1m4_atrium") || StrEqual(CurrentMap, "c5m5_bridge"))
	{
		bossflag = ON;
	}
	
	if(idBoss != DEAD)
	{
		return;
	}
	
	if(wavecount < 2 && GetConVarInt(hLastBoss) == 3)
	{
		return;
	}
	
	if((bossflag && (GetConVarInt(hLastBoss) == 1 || GetConVarInt(hLastBoss) == 3)) || GetConVarInt(hLastBoss) == 2)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsValidEntity(client) && IsClientInGame(client))
		{
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
			if(GetConVarInt(hLastBossAnnounce))
			{
				PrintToChatAll(MESSAGE_SPAWN);
			}
		}
	}
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client <= 0 || client > GetMaxClients() || !IsValidEntity(client) || !IsClientInGame(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != CLASS_TANK)
	{
		return;
	}
	
	if(wavecount < 2 && GetConVarInt(hLastBoss) == 3)
	{
		wavecount++;
		return;
	}
	
	if((bossflag && (GetConVarInt(hLastBoss) == 1 || GetConVarInt(hLastBoss) == 3)) || GetConVarInt(hLastBoss) == 2)
	{
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
	idBoss = client;
	decl String:CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss))
	{
		if(lastflag || (StrEqual(CurrentMap, "c5m5_bridge") && GetConVarInt(hLastBossLastTheParish)))
		{
			SetEntityHealth(idBoss, GetConVarInt(hLastBossHealthMin));
		}
		else
		{
			SetEntityHealth(idBoss, GetConVarInt(hLastBossHealthMax));
		}
	}
	
	return Plugin_Stop;
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if(!IsValidEntity(idBoss) || !IsClientInGame(idBoss) || idBoss == DEAD)
	{
		return;
	}
	
	if(wavecount < 2 && GetConVarInt(hLastBoss) == 3)
	{
		return;
	}
	
	if((bossflag && (GetConVarInt(hLastBoss) == 1 || GetConVarInt(hLastBoss) == 3)) || GetConVarInt(hLastBoss) == 2)
	{
		if(StrEqual(weapon, "tank_claw") && attacker == idBoss)
		{
			if(GetConVarInt(hLastBossQuake))
			{
				SkillEarthQuake(target);
			}
			
			if(GetConVarInt(hLastBossGravity))
			{
				if(form_prev == FORMTWO)
				{
					SkillGravityClaw(target);
				}
			}
			
			if(GetConVarInt(hLastBossDread))
			{
				if(form_prev == FORMTHREE)
				{
					SkillDreadClaw(target);
				}
			}
			
			if(GetConVarInt(hLastBossBurn))
			{
				if(form_prev == FORMFOUR)
				{
					SkillBurnClaw(target);
				}
			}
		}
		if(StrEqual(weapon, "tank_rock") && attacker == idBoss)
		{
			if(GetConVarInt(hLastBossComet))
			{
				if(form_prev == FORMFOUR)
				{
					SkillCometStrike(target, MOLOTOV);
				}
				else
				{
					SkillCometStrike(target, EXPLODE);
				}
			}
		}
		
		if(StrEqual(weapon, "melee") && target == idBoss)
		{
			if(GetConVarInt(hLastBossSteel))
			{
				if(form_prev == FORMTWO)
				{
					EmitSoundToClient(attacker, SOUND_STEEL);
					SetEntityHealth(idBoss, (GetEventInt(event,"dmg_health") + GetEventInt(event,"health")));
				}
			}
			
			if(GetConVarInt(hLastBossGush))
			{
				if(form_prev == FORMFOUR)
				{
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
			{
				continue;
			}
			
			if(!IsClientInGame(i) || GetClientTeam(i) != 2)
			{
				continue;
			}
			
			GetClientAbsOrigin(idBoss, Pos);
			GetClientAbsOrigin(i, tPos);
			if(GetVectorDistance(tPos, Pos) < GetConVarFloat(hLastBossEarthQuakeRadius))
			{
				EmitSoundToClient(i, SOUND_QUAKE);
				ScreenShake(i, 60.0);
				Smash(idBoss, i, GetConVarFloat(hLastBossEarthQuakeForce), 1.0, 1.5);
			}
		}
	}
}

public SkillDreadClaw(target)
{
	visibility = GetConVarInt(hLastBossDreadRate);
	CreateTimer(GetConVarFloat(hLastBossDreadInterval), DreadTimer, target);
	EmitSoundToAll(SOUND_DCLAW, target);
	ScreenFade(target, 0, 0, 0, visibility, 0, 0);
}

public SkillGravityClaw(target)
{
	SetEntityGravity(target, 0.3);
	CreateTimer(GetConVarFloat(hLastBossGravityInterval), GravityTimer, target);
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
	SetEntityMoveType(idBoss, MOVETYPE_NONE);
	SetEntProp(idBoss, Prop_Data, "m_takedamage", 0, 1);
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(!IsValidEntity(i) || !IsClientInGame(i) || GetClientTeam(i) != SURVIVOR)
		{
			continue;
		}
		EmitSoundToClient(i, SOUND_HOWL);
		ScreenShake(i, 20.0);
	}
	if((form_prev == FORMFOUR && GetConVarInt(hLastBossAbyss) == 1) || GetConVarInt(hLastBossAbyss) == 2)
	{
		TriggerPanicEvent();
	}
	
	CreateTimer(5.0, HowlTimer);
}

public Action:TankUpdate(Handle:timer)
{
	if(!IsValidEntity(idBoss) || !IsClientInGame(idBoss) || idBoss == DEAD)
	{
		return Plugin_Stop;
	}
	
	if(wavecount < 2 && GetConVarInt(hLastBoss) == 3)
	{
		return Plugin_Stop;
	}
	new health = GetClientHealth(idBoss);
	
	if(health > GetConVarInt(hLastBossHealthSecond))
	{
		if(form_prev != FORMONE)
		{
			SetPrameter(FORMONE);
		}
	}
	else if(GetConVarInt(hLastBossHealthSecond) >= health && health > GetConVarInt(hLastBossHealthThird))
	{
		if(form_prev != FORMTWO)
		{
			SetPrameter(FORMTWO);
		}
	}
	else if(GetConVarInt(hLastBossHealthThird) >= health && health > GetConVarInt(hLastBossHealthMin))
	{
		ExtinguishEntity(idBoss);
		if(form_prev != FORMTHREE)
		{
			SetPrameter(FORMTHREE);
		}
	}
	else if(GetConVarInt(hLastBossHealthMin) >= health && health > 0)
	{
		if(form_prev != FORMFOUR)
		{
			SetPrameter(FORMFOUR);
		}
	}
	
	return Plugin_Stop;
}

public SetPrameter(form_next)
{
	new force;
	new Float:speed;
	decl String:color[32];
	
	form_prev = form_next;
	
	if(form_next != FORMONE)
	{
		if(GetConVarInt(hLastBossAbyss))
		{
			SkillCallOfAbyss();
		}
		
		ExtinguishEntity(idBoss);
		
		AttachParticle(idBoss, PARTICLE_SPAWN);
		for(new j = 1; j <= GetMaxClients(); j++)
		{
			if(!IsClientInGame(j) || GetClientTeam(j) != 2)
			{
				continue;
			}
			EmitSoundToClient(j, SOUND_CHANGE);
			ScreenFade(j, 200, 200, 255, 255, 100, 1);
		}
	}
	
	if(form_next == FORMONE)
	{
		force = GetConVarInt(hLastBossForceFirst);
		speed = GetConVarFloat(hLastBossSpeedFirst);
		GetConVarString(hLastBossColorFirst, color, sizeof(color));
		
		if(GetConVarInt(hLastBossWarp))
		{
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(hLastBossWarpInterval), FatalMirror, _, TIMER_REPEAT);
		}
	}
	else if(form_next == FORMTWO)
	{
		if(GetConVarInt(hLastBossAnnounce))
		{
			PrintToChatAll(MESSAGESecond);
		}
		force = GetConVarInt(hLastBossForceSecond);
		speed = GetConVarFloat(hLastBossSpeedSecond);
		GetConVarString(hLastBossColorSecond, color, sizeof(color));
		
		SetEntityGravity(idBoss, GetConVarFloat(hLastBossWeightSecond));
	}
	else if(form_next == FORMTHREE)
	{
		if(GetConVarInt(hLastBossAnnounce))
		{
			PrintToChatAll(MESSAGEThird);
		}
		force = GetConVarInt(hLastBossForceThird);
		speed = GetConVarFloat(hLastBossSpeedThird);
		GetConVarString(hLastBossColorThird, color, sizeof(color));
		SetEntityGravity(idBoss, 1.0);
		
		CreateTimer(0.8, ParticleTimer, _, TIMER_REPEAT);
		
		if(GetConVarInt(hLastBossStealth))
		{
			CreateTimer(GetConVarFloat(hLastBossStealthThird), StealthTimer);
		}
	}
	else if(form_next == FORMFOUR)
	{
		if(GetConVarInt(hLastBossAnnounce))
		{
			PrintToChatAll(MESSAGELast);
		}
		SetEntityRenderMode(idBoss, RENDER_TRANSCOLOR);
		SetEntityRenderColor(idBoss, _, _, _, 255);
		
		force = GetConVarInt(hLastBossForceLast);
		speed = GetConVarFloat(hLastBossSpeedLast);
		GetConVarString(hLastBossColorLast, color, sizeof(color));
		SetEntityGravity(idBoss, 1.0);
		
		IgniteEntity(idBoss, 9999.9);
		
		if(GetConVarInt(hLastBossJump))
		{
			CreateTimer(GetConVarFloat(hLastBossJumpIntervalLast), JumpingTimer, _, TIMER_REPEAT);
		}
	}
	
	SetConVarInt(FindConVar("z_tank_throw_force"), force, true, true);
	
	SetEntPropFloat(idBoss, Prop_Send, "m_flLaggedMovementValue", speed);
	
	SetEntityRenderMode(idBoss, RenderMode:0);
	DispatchKeyValue(idBoss, "rendercolor", color);
}

public Action:ParticleTimer(Handle:timer)
{
	if(form_prev == FORMTHREE)
	{
		AttachParticle(idBoss, PARTICLEThird);
	}
	else if(form_prev == FORMFOUR)
	{
		AttachParticle(idBoss, PARTICLELast);
	}
	
	return Plugin_Stop;
}

public Action:GravityTimer(Handle:timer, any:target)
{
	SetEntityGravity(target, 1.0);
	return Plugin_Stop;
}

public Action:JumpingTimer(Handle:timer)
{
	if(form_prev == FORMFOUR && idBoss)
	{
		AddVelocity(idBoss, GetConVarFloat(hLastBossJumpHeightLast));
	}
	
	return Plugin_Stop;
}

public Action:StealthTimer(Handle:timer)
{
	if(form_prev == FORMTHREE && idBoss)
	{
		alpharate = 255;
		Remove(idBoss);
	}
	
	return Plugin_Stop;
}

public Action:DreadTimer(Handle:timer, any:target)
{
	visibility -= 8;
	if(visibility < 0)
	{
		visibility = 0;
	}
	ScreenFade(target, 0, 0, 0, visibility, 0, 1);
	if(visibility <= 0)
	{
		visibility = 0;
		return Plugin_Stop;
	}
	
	return Plugin_Stop;
}

public Action:HowlTimer(Handle:timer)
{
	if(!IsValidEntity(idBoss))
	{
		return Plugin_Stop;
	}
	
	if(idBoss)
	{
		SetEntityMoveType(idBoss, MOVETYPE_WALK);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 2, 1);
	}
	
	return Plugin_Stop;
}

public Action:WarpTimer(Handle:timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		decl Float:pos[3];
		
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != SURVIVOR)
			{
				continue;
			}
			EmitSoundToClient(i, SOUND_WARP);
		}
		GetClientAbsOrigin(idBoss, pos);
		ShowParticle(pos, PARTICLE_WARP, 2.0);
		TeleportEntity(idBoss, ftlPos, NULL_VECTOR, NULL_VECTOR);
		ShowParticle(ftlPos, PARTICLE_WARP, 2.0);
		SetEntityMoveType(idBoss, MOVETYPE_WALK);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 2, 1);
	}
	
	return Plugin_Stop;
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
			{
				continue;
			}
			idAlive[count] = i;
			count++;
		}
		if(count == 0)
		{
			return Plugin_Stop;
		}
		new clientNum = GetRandomInt(0, count - 1);
		GetClientAbsOrigin(idAlive[clientNum], ftlPos);
	}
	
	return Plugin_Stop;
}

public Action:FatalMirror(Handle:timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		SetEntityMoveType(idBoss, MOVETYPE_NONE);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 0, 1);
		
		CreateTimer(1.5, WarpTimer);
	}

	return Plugin_Stop;
}

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
		return Plugin_Stop;
	}
	alpharate -= 2;
	if (alpharate < 0)
	{
		alpharate = 0;
	}
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 80, 80, 255, alpharate);
	if(alpharate <= 0)
	{
		return Plugin_Stop;
	}
	
	return Plugin_Stop;
}

public AddVelocity(client, Float:zSpeed)
{
	if(g_iVelocity == -1)
	{
		return;
	}
	
	new Float:vecVelocity[3];
	GetEntDataVector(client, g_iVelocity, vecVelocity);
	vecVelocity[2] += zSpeed;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

public LittleFlower(Float:pos[3], type)
{
	new entity = CreateEntityByName("prop_physics");
	if (IsValidEntity(entity))
	{
		pos[2] += 10.0;
		if (type == 0)
		{
			DispatchKeyValue(entity, "model", ENTITY_GASCAN);
		}
		else
		{
			DispatchKeyValue(entity, "model", ENTITY_PROPANE);
		}
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
}

public Smash(client, target, Float:power, Float:powHor, Float:powVec)
{
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
	{
		BfWriteShort(msg, (0x0002 | 0x0008));
	}
	else
	{
		BfWriteShort(msg, (0x0001 | 0x0010));
	}
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

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
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
    if (IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
        {
			RemoveEdict(particle);
		}
	}
	
	return Plugin_Stop;
}

public PrecacheParticle(String:particlename[])
{
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

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
	else
	{
		return false;
	}
}

GetAnyClient()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEntity(i) && IsClientInGame(i))
		{
			return i;
		}
	}
	return -1;
}

