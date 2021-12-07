#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

#define SOUNDMISSILELAUNCHER "physics/destruction/ExplosiveGasLeak.wav"
#define SOUNDMISSILELAUNCHER2 "physics/destruction/explosivegasleak.wav"
#define SOUNDMISSILELOCK "UI/Beep07.wav"

#define Missile_model_dummy "models/w_models/weapons/w_eq_molotov.mdl"
#define Missile_model "models/props_equipment/oxygentank01.mdl"
#define Missile_model2 "models/missiles/f18_agm65maverick.mdl"

#define FilterSelf 0
#define FilterSelfAndPlayer 1
#define FilterSelfAndSurvivor 2
#define FilterSelfAndInfected 3
#define FilterSelfAndPlayerAndCI 4

#define SurvivorTeam 2
#define InfectedTeam 3
#define MissileTeam 1

#define MissileNormal 0
#define MissileTrace 1

new Handle:l4d_missile_radius;
new Handle:l4d_missile_damage;
new Handle:l4d_missile_damage_tosurvivor;
new Handle:l4d_missile_push;
new Handle:l4d_missile_limit;
new Handle:l4d_missile_kills;
new Handle:l4d_missile_safe;
new Handle:l4d_missile_tracefactor;
new Handle:l4d_missile_radar_range;

new Handle:l4d_missile_infected_smoker;
new Handle:l4d_missile_infected_charger;
new Handle:l4d_missile_infected_spitter;
new Handle:l4d_missile_infected_witch;
new Handle:l4d_missile_infected_tank_throw;
new Handle:l4d_missile_infected_anti;

new Handle:l4d_missile_weapon_rifle;
new Handle:l4d_missile_weapon_sniper;
new Handle:l4d_missile_weapon_shotgun;
new Handle:l4d_missile_weapon_magnum;
new Handle:l4d_missile_weapon_smg;
new Handle:l4d_missile_weapon_pistol;
new Handle:l4d_missile_weapon_grenade;

new bool:gamestart=false;

new Float: LastUseTime[MAXPLAYERS+1];
new Float: LastTime[MAXPLAYERS+1];

new bool:Hooked[MAXPLAYERS+1];
new MissileCount[MAXPLAYERS+1];

new MissileEntity[MAXPLAYERS+1];
new MissileFlame[MAXPLAYERS+1];
new MissileOwner[MAXPLAYERS+1];
new MissileTeams[MAXPLAYERS+1];
new MissleModel[MAXPLAYERS+1];
new MissileType[MAXPLAYERS+1];
new MissileEnemy[MAXPLAYERS+1];
new Float:MissileScanTime[MAXPLAYERS+1];

new Float:PrintTime[MAXPLAYERS+1];
new ShowMsg[MAXPLAYERS+1];

new g_iVelocity;
new L4D2Version;
new GameMode;
new g_sprite;

new Float:modeloffset=50.0;

new Float:missilespeed_trace=250.0;
new Float:missilespeed_trace2=180.0;
new Float:missilespeed_normal=800.0;

public Plugin:myinfo =
{
	name = "L4D2 Missiles Galore",
	author = "Pan Xiaohai et al.",
	description = "Missiles for weapons in L4D & L4D2",
	version = "2.0.1",
	url = "https://forums.alliedmods.net/showpost.php?p=2730955&postcount=85"
}

public OnPluginStart()
{
	l4d_missile_radius = CreateConVar("l4d_missile_radius", "200.0", "Missile explode radius");
	l4d_missile_damage = CreateConVar("l4d_missile_damage", "500.0", "Damage done by missile");
	l4d_missile_damage_tosurvivor = CreateConVar("l4d_missile_damage_tosurvivor", "0.0", "Damage to survivors ");
	l4d_missile_push = CreateConVar("l4d_missile_push", "1200", "Push force done to target");

	l4d_missile_safe = CreateConVar("l4d_missile_safe", "1", "0:Normal chance of damage to survivor, 1:Less chance to hurt survivor [0, 1]");

	l4d_missile_infected_smoker = CreateConVar("l4d_missile_infected_smoker", "0.0", "Launch missile when smoker drags [0.0, 30.0]%");
	l4d_missile_infected_charger = CreateConVar("l4d_missile_infected_charger", "0.0", "Launch missile when charger charges [0.0, 30.0]%");
	l4d_missile_infected_spitter = CreateConVar("l4d_missile_infected_spitter", "0.0", "Launch missile when spitter spits [0.0, 30.0]%");
	l4d_missile_infected_witch = CreateConVar("l4d_missile_infected_witch", "0.0", "Launch missile when witch is startled[0.0, 30.0]%");
	l4d_missile_infected_tank_throw = CreateConVar("l4d_missile_infected_tank_throw", "0.0", "Launch missile when tank throws rock[0.0, 30.0]%");
	l4d_missile_infected_anti = CreateConVar("l4d_missile_infected_anti", "0.0", "Common infected launch missile when survivor launch missile [0.0, 30.0]%");

	l4d_missile_weapon_rifle = CreateConVar("l4d_missile_weapon_rifle", "1", "Enable or disable missiles for rifles {0, 1}");
	l4d_missile_weapon_sniper = CreateConVar("l4d_missile_weapon_sniper", "1", "Enable or disable missiles for snipers {0, 1}");
	l4d_missile_weapon_shotgun = CreateConVar("l4d_missile_weapon_shotgun", "1", "Enable or disable missiles for shotguns {0, 1}");
	l4d_missile_weapon_magnum = CreateConVar("l4d_missile_weapon_magnum", "1", "Enable or disable missiles for magnums {0, 1}");
	l4d_missile_weapon_smg = CreateConVar("l4d_missile_weapon_smg", "1", "Enable or disable missiles for smgs {0, 1}");
	l4d_missile_weapon_pistol = CreateConVar("l4d_missile_weapon_pistol", "1", "Enable or disable missiles for pistols {0, 1}");
	l4d_missile_weapon_grenade = CreateConVar("l4d_missile_weapon_grenade", "1", "Enable or disable missiles for grenade launcher {0, 1}");

	l4d_missile_limit = CreateConVar("l4d_missile_limit", "3", "Amount of missiles you can carry");
	l4d_missile_kills = CreateConVar("l4d_missile_kills", "30", "How many infected killed rewards one missile");
	l4d_missile_tracefactor = CreateConVar("l4d_missile_tracefactor", "1.5", "Trace factor of missile. Do not need to change [0.5, 3.0]");
	l4d_missile_radar_range = CreateConVar("l4d_missile_radar_range", "1500.0", "Radar scan range: missiles do not lock on target if out of this range [500.0, -]");

	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");

	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));

	if (StrEqual(GameName, "survival", false))
	{
		GameMode = 3;
	}
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
	{
		GameMode = 2;
	}
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
	{
		GameMode = 1;
	}
	else
	{
		GameMode = 0;
	}

	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version=true;
	}
	else
	{
		L4D2Version=false;
	}

	AutoExecConfig(true, "l4d2_missile");

	if(GameMode!=2)
	{
		RegConsoleCmd("sm_m", MissileHelp);

		HookEvent("player_death", player_death);
		HookEvent("infected_death", Event_InfectedDeath);
		HookEvent("weapon_fire", weapon_fire);
		HookEvent("round_start", round_start);
		HookEvent("round_end", round_end);
		HookEvent("map_transition", round_end);

		if(L4D2Version)
		{
			HookEvent("charger_charge_start", charger_charge_start);
		}

		HookEvent("tongue_grab", tongue_grab);
		HookEvent("witch_harasser_set", witch_harasser_set);
		HookEvent("ability_use", ability_use);

		ResetAllState();
		Set();
		gamestart=false;
	}
}

public OnMapStart()
{
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheModel(Missile_model_dummy, true);
	PrecacheParticle("gas_explosion_pump");
	PrecacheParticleSystem("gas_explosion_pump");
	PrecacheSound(SOUNDMISSILELOCK, true);

	// fix for the first missile do not lag the server
	new ment = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(ment, "model", L4D2Version ? Missile_model2 : Missile_model);
	DispatchSpawn(ment);
	AcceptEntityInput(ment, "kill");

	if(L4D2Version)
	{
		PrecacheModel(Missile_model, true);
		g_sprite=PrecacheModel("materials/sprites/laserbeam.vmt");
		PrecacheSound(SOUNDMISSILELAUNCHER2, true);
	}
	else
	{
		PrecacheModel(Missile_model, true);
		g_sprite=PrecacheModel("materials/sprites/laser.vmt");
		PrecacheSound(SOUNDMISSILELAUNCHER, true);
	}
	ResetAllState();
	gamestart=true;
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

stock PrecacheParticleSystem(const String:p_strEffectName[])
{
	static s_numStringTable = INVALID_STRING_TABLE;

	if (s_numStringTable == INVALID_STRING_TABLE)
	{
		s_numStringTable = FindStringTable("ParticleEffectNames");
	}

	AddToStringTable(s_numStringTable, p_strEffectName);
}

ResetAllState()
{
	for (new x = 1; x < MAXPLAYERS+1; x++)
	{
		ResetClientState(x);
	}
}

ResetClientState(x)
{
	LastUseTime[x]=0.0;
	PrintTime[x]=0.0;
	MissileCount[x]=1;
	Hooked[x]=false;
	ShowMsg[x]=0;
	MissileEntity[x]=0;
	MissleModel[x]=0;
	MissileFlame[x]=0;
}

UnHookAll()
{
	for (new x = 1; x < MAXPLAYERS+1; x++)
	{
		UnHookMissile(x);
	}
}

public OnConfigExecuted()
{
	ResetAllState();
	Set();
}

Set()
{

}

public CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Set();
}

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllState();
	gamestart=true;
}

public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	UnHookAll();
	ResetAllState();
	gamestart=false;
}

public Action:MissileHelp(client,args)
{
	PrintToChat(client, "[MISSILES] For every %d killed infected you get 1 missile", GetConVarInt(l4d_missile_kills));
	PrintToChat(client, "[MISSILES] Type 1 = Grenade Launcher: Press USE and shoot");
	PrintToChat(client, "[MISSILES] Type 2 = Auto Tracking Missile: DUCK and press USE while firing");
}

public Action:ability_use(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:s[20];
	GetEventString(event, "ability", s, 32);
	if(StrEqual(s, "ability_spit", true))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(MissileEntity[client]==0 && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_missile_infected_spitter) )
		{
			LaunchMissile(client, missilespeed_trace2, MissileTrace,  true, 30.0);
		}
	}
	else if(StrEqual(s, "ability_throw", true))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!Hooked[client] && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_missile_infected_tank_throw) )
		{
			LaunchMissile(client,missilespeed_trace2, MissileTrace,  true, 30.0);
		}
	}
}

public Action:witch_harasser_set(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_missile_infected_witch) )
	{
		CreateTimer(GetRandomFloat(0.1, 0.5), InfectedAntiMissile, 0);
	}
}

public Action:charger_charge_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!Hooked[client] && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_missile_infected_charger))
	{
		LaunchMissile(client, missilespeed_trace2, MissileTrace, true, 30.0);
	}
}

public Action:tongue_grab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!Hooked[client] && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_missile_infected_smoker))
	{
		LaunchMissile(client, missilespeed_trace2, MissileTrace, true, 30.0);
	}
}

public Action:weapon_fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(gamestart==false)return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(client)==2)
	{
		if(GetClientButtons(client) & IN_USE)
		{
			new Float:time=GetEngineTime();
			if(time-LastUseTime[client]>1.0)
			{
				LastUseTime[client]=time;
				new bool:ok=false;
				decl String:item[65];
				GetEventString(event, "weapon", item, 65);
				if(GetConVarInt(l4d_missile_weapon_shotgun)>0 && StrContains(item, "shot")>=0 )ok=true;
				else if(GetConVarInt(l4d_missile_weapon_sniper)>0 && (StrContains(item, "sniper")>=0 || StrContains(item, "hunting")>=0))ok=true;
				else if(GetConVarInt(l4d_missile_weapon_rifle)>0 && StrContains(item, "rifle")>=0 )ok=true;
				else if(GetConVarInt(l4d_missile_weapon_magnum)>0 && StrContains(item, "magnum")>=0 )ok=true;
				else if(GetConVarInt(l4d_missile_weapon_pistol)>0 && StrContains(item, "pistol")>=0 )ok=true;
				else if(GetConVarInt(l4d_missile_weapon_smg)>0 && StrContains(item, "smg")>=0 )ok=true;
				else if(GetConVarInt(l4d_missile_weapon_grenade)>0 && StrContains(item, "grenade")>=0 )ok=true;

				if(ok)
				{
					new type=MissileNormal;
					if(GetClientButtons(client) & IN_DUCK)type=MissileTrace;
					StartMissile(client, time, type);
				}
			}
		}
	}
}

public Action:InfectedAntiMissile(Handle:timer, any:ent)
{
	new selected=0;
	decl andidate[MAXPLAYERS+1];
	new index=0;
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==InfectedTeam && !Hooked[client])
		{
			andidate[index++]=client;
		}
	}
	if(index>0)
	{
		selected=GetRandomInt(0, index-1);
		LaunchMissile(andidate[selected], missilespeed_trace2, MissileTrace, true, 30.0);
	}
}

new upgradekillcount[MAXPLAYERS+1];
new totalkillcount[MAXPLAYERS+1];

UpGrade(x, kill)
{
	upgradekillcount[x]+=kill;
	totalkillcount[x]+=kill;
	new v=upgradekillcount[x]/GetConVarInt(l4d_missile_kills);
	upgradekillcount[x]=upgradekillcount[x]%GetConVarInt(l4d_missile_kills);
	MissileCount[x]+=v;
	if (v>0)
	{
		PrintHintText(x, "Infected killed: %d", totalkillcount[x]);
		if(MissileCount[x]>GetConVarInt(l4d_missile_limit))MissileCount[x]=GetConVarInt(l4d_missile_limit);
		PrintHintText(x, "Missile count: %d", MissileCount[x]);
		if(ShowMsg[x]<3)
		{
			PrintToChat(x, "Type !m in the chat to learn how to shoot missiles.", MissileCount[x]);
			ShowMsg[x]++;
		}
	}
}

public Action:Event_InfectedDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{

	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if (attacker<=0)
	{
		return Plugin_Continue;
	}
	if(IsClientInGame(attacker) )
	{
		if(GetClientTeam(attacker) == 2)
		{
			UpGrade(attacker, 1);
		}
	}
	return Plugin_Continue;
}

public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{

	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if (victim <= 0 || attacker<=0)
	{
		return Plugin_Continue;
	}
	if(IsClientInGame(attacker) )
	{
		if(GetClientTeam(attacker) == 2)
		{
			if(IsClientInGame(victim))
			{
				if(GetClientTeam(victim) == 3 )
				{
					new bool:headshot=GetEventBool(hEvent, "headshot");
					if(headshot)
					{
						UpGrade(attacker, 5);
					}
					else
					{
						UpGrade(attacker, 3);
					}
				}
			}
		}
	}
	if(victim>0)
	{
		UnHookMissile(victim);
		ResetClientState(victim);
	}
	return Plugin_Continue;
}

UnHookMissile(client)
{
	if(client>0 && Hooked[client])
	{
		if(IsEntityMissileModel(MissleModel[client]))
		{
			AcceptEntityInput(MissleModel[client], "kill");
		}
		if(IsEntityMissile(MissileEntity[client]))
		{
			AcceptEntityInput(MissileEntity[client], "kill");
		}
		SDKUnhook(client, SDKHook_PreThink, ThinkMissile);
	}
	Hooked[client]=false;
	MissileEntity[client]=0;
	MissleModel[client]=0;
}

bool:IsEntityMissile(ent)
{
	new bool:r=false;
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		decl String:g_classname[64];
		GetEdictClassname(ent, g_classname, 64);
		if(StrEqual(g_classname, "molotov_projectile" ))
		{
			r=true;
		}
	}
	return r;
}

bool:IsEntityMissileModel(ent)
{
	new bool:r=false;
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		decl String:g_classname[64];
		GetEdictClassname(ent, g_classname, 64);
		if(StrEqual(g_classname, "prop_dynamic_override", true) )
		{
			r=true;
		}
	}
	return r;
}

StartMissile(client, Float:time, type=MissileTrace)
{
	time+=0.0;
	if(MissileCount[client]-1>=0)
	{
		new bool:ok;
		if(type==MissileNormal)	ok=LaunchMissile(client, missilespeed_normal, type, false, 15.0);
		else ok=LaunchMissile(client, missilespeed_trace, type, false, 15.0);
		if(ok && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_missile_infected_anti) )
		{
			CreateTimer(GetRandomFloat(0.1, 1.0), InfectedAntiMissile, 0, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		PrintHintText(client, "You have no missiles.");
	}
}

bool:LaunchMissile(client, Float:force, type=MissileTrace, bool:up=false, Float:offset)
{
	if(Hooked[client])UnHookMissile(client);

	decl Float:pos[3];
	decl Float:angles[3];
	decl Float:velocity[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angles);
	if(up && true)
	{
		angles[1]=-90.0;
		angles[0]=-90.0;
		angles[2]=0.0;
	}

	GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(velocity, velocity);
	ScaleVector(velocity, force);
	{
		decl Float:vec[3];
		GetAngleVectors(angles,vec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vec,vec);
		ScaleVector(vec, offset);
		AddVectors(pos, vec, pos);
	}

	new Float:temp[3];
	new Float:dis=CalRay(pos, angles, 0.0, 0.0, temp, client, false, FilterSelf);

	if(dis<150.0)
	{
		PrintHintText(client, "Not enough space to launch!");
		return false;
	}

	new bool:ok=CreateMissile(client,type,  pos, velocity, angles);
	if(!ok )	return false;
	SetEntPropFloat(MissileEntity[client], Prop_Send, "m_fadeMaxDist", client*1.0);

	MissileEnemy[client]=0;
	MissileType[client]=type;
	MissileTeams[client]=GetClientTeam(client);
	MissileOwner[client]=client;
	LastTime[client]=0.0;
	MissileScanTime[client]=0.0;
	MissileCount[client]=MissileCount[client]-1;
	Hooked[client]=true;
	PrintTime[client]=0.0;

	SDKUnhook(client, SDKHook_PreThink, ThinkMissile);
	SDKHook(client, SDKHook_PreThink, ThinkMissile);

	if(L4D2Version)	EmitSoundToAll(SOUNDMISSILELAUNCHER2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
	else EmitSoundToAll(SOUNDMISSILELAUNCHER, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
	PrintHintText(client, "Missile %d", MissileCount[client]);
	if(GetClientTeam(client)==3)PrintToChatAll("\x04%N \x03launched a missile.", client);
	return true;
}

bool:CreateMissile(client, type,  Float:pos[3], Float:vol[3], Float:ang[3])
{
	new ok=false;
	type=type+0;
	new ent=CreateEntityByName("molotov_projectile");
	if(ent>0)DispatchKeyValue(ent, "model", Missile_model_dummy);
	decl Float:ang1[3];
	if(ent>0)
	{
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", -1);
		CopyVector(ang, ang1);
		ScaleVector(vol , 1.0);
		if(!L4D2Version)ang1[0]-=90.0;
		DispatchKeyValueVector(ent, "origin", pos);
		SetEntityGravity(ent, 0.01);
		DispatchSpawn(ent);
		ok=true;
	}
	else ok=false;
	new ment=0;
	if(ok)
	{
		ment=CreateEntityByName("prop_dynamic_override");
		if(ment>0 && ok)
		{
			new String:tname[20];
			Format(tname, 20, "missile%d", ent);
			DispatchKeyValue(ent, "targetname", tname);
			if(L4D2Version)
			{
				DispatchKeyValue(ment, "model", Missile_model2);

			}
			else	DispatchKeyValue(ment, "model", Missile_model);
			DispatchKeyValue(ment, "parentname", tname);

			decl Float:ang2[3];
			decl Float:offset[3];
			SetVector(offset, 0.0, 0.0, 80.0);

			NormalizeVector(offset, offset);
			ScaleVector(offset, -0.0);

			AddVectors(pos, offset, pos);

			CopyVector(ang, ang2);
			if(L4D2Version)
			{
				SetVector(ang2, 0.0, 0.0,0.0);
			}
			else
			{
				SetVector(ang2, 0.0, 0.0, -180.0);
			}
			DispatchKeyValueVector(ment, "Angles", ang2);
			DispatchKeyValueVector(ment, "origin", pos);

			SetVariantString(tname);
			AcceptEntityInput(ment, "SetParent",ment, ment, 0);

			DispatchSpawn(ment);
			DispatchKeyValueVector(ent, "Angles", ang1);
			TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, vol);

			DispatchKeyValueFloat(ment, "fademindist", 10000.0);
			DispatchKeyValueFloat(ment, "fademaxdist", 20000.0);
			DispatchKeyValueFloat(ment, "fadescale", 0.0);
			if(L4D2Version)
			{
				SetEntPropFloat(ment, Prop_Send,"m_flModelScale",0.5);
			}
			AttachFlame(client, ment);
		}
		else ok=false;
	}
	if(!ok)
	{
		ent=0;
		ment=0;
		MissleModel[client]=ment;
		MissileEntity[client]=ent;
		return false;
	}

	SetEntityMoveType(ent, MOVETYPE_NOCLIP);
	SetEntityMoveType(ment, MOVETYPE_NOCLIP);

	MissleModel[client]=ment;
	MissileEntity[client]=ent;
	return true;
}

AttachFlame(client, ent )
{
	decl String:flame_name[128];
	Format(flame_name, sizeof(flame_name), "target%d", ent);

	new Float:origin[3];
	SetVector(origin,  0.0, 0.0,  0.0);
	decl Float:ang[3];
	if(L4D2Version)	SetVector(ang, 0.0, 180.0, 0.0);
	else SetVector(ang, 90.0, 0.0, 0.0);

	new flame3 = CreateEntityByName("env_steam");
	DispatchKeyValue(ent,"targetname", flame_name);
	DispatchKeyValue(flame3,"SpawnFlags", "1");
	DispatchKeyValue(flame3,"Type", "0");
	DispatchKeyValue(flame3,"InitialState", "1");
	DispatchKeyValue(flame3,"Spreadspeed", "10");
	DispatchKeyValue(flame3,"Speed", "350");
	DispatchKeyValue(flame3,"Startsize", "5");
	DispatchKeyValue(flame3,"EndSize", "10");
	DispatchKeyValue(flame3,"Rate", "555");
	DispatchKeyValue(flame3,"RenderColor", "0 160 55");
	DispatchKeyValue(flame3,"JetLength", "50");
	DispatchKeyValue(flame3,"RenderAmt", "180");

	DispatchSpawn(flame3);
	SetVariantString(flame_name);
	AcceptEntityInput(flame3, "SetParent", flame3, flame3, 0);
	TeleportEntity(flame3, origin, ang,NULL_VECTOR);
	AcceptEntityInput(flame3, "TurnOn");

	MissileFlame[client]=flame3;
}

public ThinkMissile(client)
{
	if(Hooked[client]==false)
	{
		UnHookMissile(client);
		return;
	}
	if(IsClientInGame(client))
	{
		new Float:time=GetEngineTime();
		new Float:duration=time-LastTime[client];
		LastTime[client]=time;
		if(duration>0.1)duration=0.1;
		else if (duration<0.01)duration=0.01;

		if(MissileType[client]==MissileTrace)TraceMissile(client, time, duration);
		else if(MissileType[client]==MissileNormal)Missile(client, duration);
	}
	else
	{
		UnHookMissile(client);
	}
}

TraceMissile(client, Float:time,  Float:duration)
{
	new ent=MissileEntity[client];
	decl Float:posradar[3];
	decl Float:posmissile[3];
	decl Float:voffset[3];
	decl Float:velocitymissile[3];
	GetClientEyePosition(client, posradar);
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", posmissile);
		GetEntDataVector(ent, g_iVelocity, velocitymissile);
	}

	NormalizeVector(velocitymissile, velocitymissile);
	CopyVector(velocitymissile, voffset);
	ScaleVector(voffset, modeloffset);
	AddVectors(posmissile, voffset, posmissile);

	new myteam=MissileTeams[client];

	new enemyteam=myteam==SurvivorTeam?InfectedTeam:SurvivorTeam;
	new enemy=MissileEnemy[client];
	if(time-MissileScanTime[client]>0.3)
	{
		MissileScanTime[client]=time;
		enemy=ScanEnemy(posmissile, posradar, velocitymissile, enemyteam);
	}
	else
	{
		if(enemy>0)
		{
			if(IsClientInGame(enemy) && IsPlayerAlive(enemy)){}
			else enemy=0;
		}
		else if(enemy<0)
		{
			if(Hooked[0-enemy]){}
			else enemy=0;
		}
	}

	MissileEnemy[client]=enemy;

	decl Float:velocityenemy[3];
	decl Float:vtrace[3];

	vtrace[0]=vtrace[1]=vtrace[2]=0.0;
	new bool:visible=false;
	decl Float:missionangle[3];

	new Float:disenemy=1000.0;
	new Float:disobstacle=1000.0;
	new Float:disexploded=20.0;
	new bool:show=false;
	new bool:enemyismissile=false;
	if(time-PrintTime[client]>0.2)
	{
		PrintTime[client]=time;
		show=true;
	}
	new Float:speed=0.0;
	if(myteam==SurvivorTeam)speed=missilespeed_trace;
	else speed=missilespeed_trace2;
	new Float:tracefactor=GetConVarFloat(l4d_missile_tracefactor);
	if(enemy>0)
	{
		decl Float:posenemy[3];
		GetClientEyePosition(enemy, posenemy);

		disenemy=GetVectorDistance(posmissile, posenemy);

		visible=IfTwoPosVisible(posmissile, posenemy, ent, myteam);

		GetEntDataVector(enemy, g_iVelocity, velocityenemy);

		ScaleVector(velocityenemy, duration);

		AddVectors(posenemy, velocityenemy, posenemy);
		MakeVectorFromPoints(posmissile, posenemy, vtrace);

		if(show)
		{
			if(enemy>0 && IsClientInGame(enemy) && IsPlayerAlive(enemy))
			{
				if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client)) PrintHintText(enemy, "Missile locked on %N, distance: %d", client, RoundFloat(disenemy) );
				else PrintHintText(enemy, "Warning! Enemy's missile locked, distance: %d", RoundFloat(disenemy) );
				EmitSoundToClient(enemy, SOUNDMISSILELOCK);
			}
			if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
			{
				if(enemy>0 && IsClientInGame(enemy) && IsPlayerAlive(enemy))PrintHintText(client, "Missile locked on %N, distance %d", enemy, RoundFloat(disenemy));
				else PrintHintText(client, "Missile locked on enemy, distance: %d", RoundFloat(disenemy));
			}
		}
	}
	else if(enemy<0)
	{
		enemy=-enemy;

		decl Float:posenemy[3];
		GetEntPropVector(MissileEntity[enemy], Prop_Send, "m_vecOrigin", posenemy);
		GetEntDataVector(MissileEntity[enemy], g_iVelocity, velocityenemy);
		NormalizeVector(velocityenemy, velocityenemy);

		CopyVector(velocityenemy, voffset);
		ScaleVector(voffset, modeloffset);
		AddVectors(posenemy, voffset, posenemy);

		disenemy=GetVectorDistance(posmissile, posenemy);
		visible=IfTwoPosVisible(posmissile, posenemy, MissleModel[enemy], MissileTeam);
		ScaleVector(velocityenemy, duration);
		AddVectors(posenemy, velocityenemy, posenemy);
		MakeVectorFromPoints(posmissile, posenemy, vtrace);
		if(show)
		{
			if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
			{
				if(enemy>0 && IsClientInGame(enemy) && IsPlayerAlive(enemy))PrintHintText(client, "Missile locked on %N, distance: %d", enemy, RoundFloat(disenemy));
				else PrintHintText(client, "Missile locked on enemy's missile, distance: %d", RoundFloat(disenemy));
			}
		}
		enemyismissile=true;
	}
	if(enemy==0 && myteam==2 )
	{
		speed=missilespeed_trace2;
		new Float:dis=GetVectorDistance(posmissile,posradar);
		decl Float:posenemy[3];
		CopyVector(posradar, posenemy);
		disenemy=dis;
		MakeVectorFromPoints(posmissile, posenemy, vtrace);
	}

	GetVectorAngles(velocitymissile, missionangle);

	decl Float:vleft[3];
	decl Float:vright[3];
	decl Float:vup[3];
	decl Float:vdown[3];
	decl Float:vfront[3];
	decl Float:vv1[3];
	decl Float:vv2[3];
	decl Float:vv3[3];
	decl Float:vv4[3];
	decl Float:vv5[3];
	decl Float:vv6[3];
	decl Float:vv7[3];
	decl Float:vv8[3];

	vfront[0]=vfront[1]=vfront[2]=0.0;

	new Float:factor2=0.5;
	new Float:factor1=0.2;
	new Float:t;
	new Float:base=1500.0;
	if(visible)
	{
		base=80.0;
	}
	{
		new flag=FilterSelfAndInfected;
		new bool:print=false;
		new self=MissleModel[client];
		new Float:front=CalRay(posmissile, missionangle, 0.0, 0.0, vfront, self, print, flag);
		print=false;
		disobstacle=CalRay(posmissile, missionangle, 0.0, 0.0, vfront, self, print, FilterSelf);

		new Float:down=CalRay(posmissile, missionangle, 90.0, 0.0, vdown, self, print,  flag);
		new Float:up=CalRay(posmissile, missionangle, -90.0, 0.0, vup, self, print);
		new Float:left=CalRay(posmissile, missionangle, 0.0, 90.0, vleft, self, print, flag);
		new Float:right=CalRay(posmissile, missionangle, 0.0, -90.0, vright, self, print, flag);

		new Float:f1=CalRay(posmissile, missionangle, 30.0, 0.0, vv1, self, print, flag);
		new Float:f2=CalRay(posmissile, missionangle, 30.0, 45.0, vv2, self, print, flag);
		new Float:f3=CalRay(posmissile, missionangle, 0.0, 45.0, vv3, self, print, flag);
		new Float:f4=CalRay(posmissile, missionangle, -30.0, 45.0, vv4, self, print, flag);
		new Float:f5=CalRay(posmissile, missionangle, -30.0, 0.0, vv5, self, print,flag);
		new Float:f6=CalRay(posmissile, missionangle, -30.0, -45.0, vv6, self, print, flag);
		new Float:f7=CalRay(posmissile, missionangle, 0.0, -45.0, vv7, self, print, flag);
		new Float:f8=CalRay(posmissile, missionangle, 30.0, -45.0, vv8, self, print, flag);

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

		if(front>base) front=base;
		if(up>base) up=base;
		if(down>base) down=base;
		if(left>base) left=base;
		if(right>base) right=base;

		if(f1>base) f1=base;
		if(f2>base) f2=base;
		if(f3>base) f3=base;
		if(f4>base) f4=base;
		if(f5>base) f5=base;
		if(f6>base) f6=base;
		if(f7>base) f7=base;
		if(f8>base) f8=base;

		new Float:b2=10.0;
		if(front<b2) front=b2;
		if(up<b2) up=b2;
		if(down<b2) down=b2;
		if(left<b2) left=b2;
		if(right<b2) right=b2;

		if(f1<b2) f1=b2;
		if(f2<b2) f2=b2;
		if(f3<b2) f3=b2;
		if(f4<b2) f4=b2;
		if(f5<b2) f5=b2;
		if(f6<b2) f6=b2;
		if(f7<b2) f7=b2;
		if(f8<b2) f8=b2;

		t=-1.0*factor1*(base-front)/base;
		ScaleVector(vfront, t);

		t=-1.0*factor1*(base-up)/base;
		ScaleVector(vup, t);

		t=-1.0*factor1*(base-down)/base;
		ScaleVector(vdown, t);

		t=-1.0*factor1*(base-left)/base;
		ScaleVector(vleft, t);

		t=-1.0*factor1*(base-right)/base;
		ScaleVector(vright, t);

		t=-1.0*factor1*(base-f1)/f1;
		ScaleVector(vv1, t);

		t=-1.0*factor1*(base-f2)/f2;
		ScaleVector(vv2, t);

		t=-1.0*factor1*(base-f3)/f3;
		ScaleVector(vv3, t);

		t=-1.0*factor1*(base-f4)/f4;
		ScaleVector(vv4, t);

		t=-1.0*factor1*(base-f5)/f5;
		ScaleVector(vv5, t);

		t=-1.0*factor1*(base-f6)/f6;
		ScaleVector(vv6, t);

		t=-1.0*factor1*(base-f7)/f7;
		ScaleVector(vv7, t);

		t=-1.0*factor1*(base-f8)/f8;
		ScaleVector(vv8, t);

		if(disenemy>=500.0)disenemy=500.0;
		t=1.0*factor2*(1000.0-disenemy)/500.0;
		ScaleVector(vtrace, t);

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

	new Float:a=GetAngle(vfront, velocitymissile);
	new Float:amax=3.14159*duration*tracefactor;

	if(a> amax )a=amax;

	ScaleVector(vfront ,a);

	decl Float:newvelocitymissile[3];
	AddVectors(velocitymissile, vfront, newvelocitymissile);

	ScaleVector(newvelocitymissile,speed);

	decl Float:angle[3];
	GetVectorAngles(newvelocitymissile,  angle);
	if(!L4D2Version)angle[0]-=90.0;
	TeleportEntity(ent, NULL_VECTOR,  angle ,newvelocitymissile);

	if(disenemy<disexploded || disobstacle<disexploded)
	{
		new bool:hitenemy=false;
		if(disenemy<150.0)hitenemy=true;

		if(enemyismissile )
		{
			MissileHitMissileMsg(client, enemy, hitenemy);
			if(hitenemy)
			{
				MissileHit(enemy, 1);
				UnHookMissile(enemy);
			}
		}
		else
		{
			MissileHitPlayerMsg(client, enemy, hitenemy);
		}
		MissileHit(client);
		UnHookMissile(client);
	}
}

Missile(client, Float:duration)
{
	decl Float:missionangle[3];
	decl Float:voffset[3];
	decl Float:missilepos[3];
	decl Float:velocitymissile[3];
	new ent=MissileEntity[client];
	duration=duration*1.0;
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", missilepos);
	GetEntDataVector(ent, g_iVelocity, velocitymissile);
	NormalizeVector(velocitymissile,velocitymissile);
	CopyVector(velocitymissile, voffset);
	ScaleVector(voffset, modeloffset);
	AddVectors(missilepos, voffset, missilepos);

	decl Float:temp[3];
	GetVectorAngles(velocitymissile, missionangle);
	new Float:disenemy=CalRay(missilepos, missionangle, 0.0, 0.0, temp, MissileEntity[client], false, FilterSelf);

	decl Float:angle[3];
	GetVectorAngles(velocitymissile,  angle);
	if(!L4D2Version)angle[0]-=90.0;

	DispatchKeyValueVector(ent, "Angles", angle);
	if(disenemy<20.0)
	{
		MissileHit(client);
		UnHookMissile(client);
	}
}

MissileHitMissileMsg(client, enemy, bool:hit=true)
{
	if(hit)
	{
		if(enemy>0 && IsClientInGame(enemy))
		{
			if(client> 0 && IsClientInGame(client))PrintHintText(enemy, "Your missile was intercepted by %N.", client);
			else PrintHintText(enemy, "Your missile was intercepted by enemy.");
		}
		if(client>0 && IsClientInGame(client))
		{
			if(enemy>0 && IsClientInGame(enemy) && IsPlayerAlive(enemy))PrintHintText(client, "You intercepted %N's missile.", enemy);
			else PrintHintText(client, "You intercepted the enemy's missile.");
		}
	}
	else
	{
		if(client> 0 && IsClientInGame(client))PrintHintText(client, "Your missile missed.");
	}
}

MissileHitPlayerMsg(client, enemy, bool:hit)
{
	if(hit)
	{
		if(enemy>0 && IsClientInGame(enemy) )
		{
			if(client> 0 && IsClientInGame(client))PrintHintText(enemy, "You were hit by %N's missile!", client);
			else PrintHintText(enemy, "You were hit by the enemy's missile.");
		}
		if(client>0 && IsClientInGame(client))
		{
			if(enemy>0 && IsClientInGame(enemy))PrintHintText(client, "Your missile hit %N!", enemy);
			else PrintHintText(client, "Your missile hit obstacle.");
		}
	}
	else
	{
		if(client> 0 && IsClientInGame(client))PrintHintText(client, "Your missile missed!");
	}
}

MissileHit(client, num=2)
{
	{
		decl Float:pos[3];
		decl Float:voffset[3];
		GetEntPropVector(MissileEntity[client], Prop_Send, "m_vecOrigin", pos);

		decl Float:velocitymissile[3];
		GetEntDataVector(MissileEntity[client], g_iVelocity, velocitymissile);
		NormalizeVector(velocitymissile, velocitymissile);

		CopyVector(velocitymissile, voffset);
		ScaleVector(voffset, modeloffset);
		AddVectors(pos, voffset, pos);

		new ent1=0;
		new ent2=0;
		new ent3=0;
		{
			ent1=CreateEntityByName("prop_physics");
			DispatchKeyValue(ent1, "model", "models/props_junk/propanecanister001a.mdl");
			DispatchSpawn(ent1);
			TeleportEntity(ent1, pos, NULL_VECTOR, NULL_VECTOR);
			ActivateEntity(ent1);
		}
		if(num>1)
		{
			ent2=CreateEntityByName("prop_physics");
			DispatchKeyValue(ent2, "model", "models/props_junk/propanecanister001a.mdl");
			DispatchSpawn(ent2);
			TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
			ActivateEntity(ent2);
		}
		if(num>2)
		{
			ent3=CreateEntityByName("prop_physics");
			DispatchKeyValue(ent3, "model", "models/props_junk/propanecanister001a.mdl");
			DispatchSpawn(ent3);
			TeleportEntity(ent3, pos, NULL_VECTOR, NULL_VECTOR);
			ActivateEntity(ent3);
		}
		new Handle:h=CreateDataPack();
		WritePackCell(h, ent1);
		WritePackCell(h, ent2);
		WritePackCell(h, ent3);

		WritePackFloat(h, pos[0]);
		WritePackFloat(h, pos[1]);
		WritePackFloat(h, pos[2]);

		new Float:damage=0.0;
		if(MissileTeams[client]==3)damage=GetConVarFloat(l4d_missile_damage_tosurvivor);
		else damage=GetConVarFloat(l4d_missile_damage);

		new Float:radius=GetConVarFloat(l4d_missile_radius);
		new Float:pushforce=GetConVarFloat(l4d_missile_push);

		if(GetConVarInt(l4d_missile_safe)==1 && MissileTeams[client]==SurvivorTeam)
		{
			new Float:mindistance=GetSurvivorMinDistance(pos);
			if(mindistance<radius)radius=mindistance;
		}
		WritePackFloat(h, damage);
		WritePackFloat(h, radius);
		WritePackFloat(h, pushforce);

		ExplodeG(INVALID_HANDLE, h);

		if(MissileType[client]!=MissileTrace &&  IsClientInGame(client) && IsPlayerAlive(client))PrintHintText(client, "Missile exploded.");
	}
}

ScanEnemy(Float:missilePos[3], Float:radarPos[3], Float:vec[3], enemyteam)
{
	new Float:min=4.0;
	decl Float:enmeyPos[3];
	decl Float:dir[3];
	new Float:t;
	new selected=0;
	new bool:hasmissile=false;
	new Float:range=GetConVarFloat(l4d_missile_radar_range);
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			new bool:playerok=IsPlayerAlive(client) && GetClientTeam(client)==enemyteam;
			new bool:ismissile=Hooked[client] && MissileTeams[client]==enemyteam ;
			if(playerok || ismissile)
			{
				if(ismissile)
				{
					GetEntPropVector(MissileEntity[client], Prop_Send, "m_vecOrigin", enmeyPos);
					if(enemyteam==2 || GetVectorDistance(enmeyPos,radarPos)<range)
					{
						if(!hasmissile)min=4.0;
						hasmissile=true;

						MakeVectorFromPoints(missilePos, enmeyPos, dir);
						t=GetAngle(vec, dir);
						if(t<=min)
						{
							min=t;
							selected=-client;
						}
					}
				}
				if(!hasmissile && playerok)
				{
					GetClientEyePosition(client, enmeyPos);
					if(enemyteam==2 || GetVectorDistance(enmeyPos,radarPos)<range)
					{
						MakeVectorFromPoints(missilePos, enmeyPos,  dir);
						t=GetAngle(vec,  dir);
						if(t<=min)
						{
							min=t;
							selected=client;
						}
					}
				}
			}
		}
	}
	return selected;
}

Float:GetSurvivorMinDistance(Float:pos[3])
{
	new Float:min=99999.0;
	decl Float:pos2[3];
	new Float:t;
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 )
		{
			GetClientEyePosition(client, pos2);
			t=GetVectorDistance(pos, pos2);
			if(t<=min)
			{
				min=t;
			}
		}
	}
	return min;
}

bool:IfTwoPosVisible(Float:pos1[3], Float:pos2[3], self, team=SurvivorTeam)
{
	new bool:r=true;
	new Handle:trace;
	if(team==SurvivorTeam)trace=TR_TraceRayFilterEx(pos2, pos1, MASK_SOLID, RayType_EndPoint, DontHitSelfAndInfected,self);
	else if(team==InfectedTeam)trace=TR_TraceRayFilterEx(pos2, pos1, MASK_SOLID, RayType_EndPoint, DontHitSelfAndSurvivor,self);
	else trace=TR_TraceRayFilterEx(pos2, pos1, MASK_SOLID, RayType_EndPoint, DontHitSelfAndMissile,self);
	if(TR_DidHit(trace))
	{
		r=false;
	}
	CloseHandle(trace);
	return r;
}

Float:CalRay(Float:posmissile[3], Float:angle[3], Float:offset1, Float:offset2,   Float:force[3], ent, bool:printlaser=true, flag=FilterSelf)
{
	decl Float:ang[3];
	CopyVector(angle, ang);
	ang[0]+=offset1;
	ang[1]+=offset2;
	GetAngleVectors(ang, force, NULL_VECTOR,NULL_VECTOR);
	new Float:dis=GetRayDistance(posmissile, ang, ent, flag);
	if(printlaser)ShowLaserByAngleAndDistance(posmissile, ang, dis*0.5);
	return dis;
}

ShowLaserByAngleAndDistance(Float:pos1[3], Float:angle[3], Float:dis, flag=0, Float:life=0.06)
{

	new Float:pos2[3];
	GetAngleVectors(angle, pos2, NULL_VECTOR,NULL_VECTOR);
	NormalizeVector(pos2, pos2);
	ScaleVector(pos2, dis);
	AddVectors(pos1, pos2, pos2);
	ShowLaserByPos(pos1, pos2, flag, life);

}

ShowLaserByPos(Float:pos1[3], Float:pos2[3], flag=0, Float:life=0.06)
{
	decl color[4];
	if(flag==0)
	{
		color[0] = 200;
		color[1] = 200;
		color[2] = 200;
		color[3] = 230;
	}
	else
	{
		color[0] = 200;
		color[1] = 0;
		color[2] = 0;
		color[3] = 230;
	}

	new Float:width1=0.5;
	new Float:width2=0.5;
	if(L4D2Version)
	{
		width2=0.3;
		width2=0.3;
	}

	TE_SetupBeamPoints(pos1, pos2, g_sprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
	TE_SendToAll();
}

CopyVector(Float:source[3], Float:target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}

SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}

Float:GetRayDistance(Float:pos[3], Float: angle[3], self, flag)
{
	decl Float:hitpos[3];
	GetRayHitPos(pos, angle, hitpos, self, flag);
	return GetVectorDistance(pos,  hitpos);
}

Float:GetAngle(Float:x1[3], Float:x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}

GetRayHitPos(Float:pos[3], Float: angle[3], Float:hitpos[3], self, flag)
{
	new Handle:trace;
	new hit=0;
	if(flag==FilterSelf)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelf, self);
	}
	else if(flag==FilterSelfAndPlayer)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayer, self);
	}
	else if(flag==FilterSelfAndSurvivor)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndSurvivor, self);
	}
	else if(flag==FilterSelfAndInfected)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndInfected, self);
	}
	else if(flag==FilterSelfAndPlayerAndCI)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayerAndCI, self);
	}
	if(TR_DidHit(trace))
	{

		TR_GetEndPosition(hitpos, trace);
		hit=TR_GetEntityIndex(trace);

	}
	CloseHandle(trace);
	return hit;
}

public Action:ExplodeG(Handle:timer, Handle:h)
{
	ResetPack(h);

	new ent1=ReadPackCell(h);
	new ent2=ReadPackCell(h);
	new ent3=ReadPackCell(h);

	decl Float:pos[3];
	pos[0]=ReadPackFloat(h);
	pos[1]=ReadPackFloat(h);
	pos[2]=ReadPackFloat(h);
	new Float:damage=ReadPackFloat(h);
	new Float:radius=ReadPackFloat(h);
	new Float:force=ReadPackFloat(h);
	CloseHandle(h);

	if(ent1>0 && IsValidEntity(ent1) && IsValidEdict(ent1))
	{

		AcceptEntityInput(ent1, "break");
		AcceptEntityInput(ent1, "kill");
		if(ent2>0 && IsValidEntity(ent2)  && IsValidEdict(ent2))
		{
			AcceptEntityInput(ent2, "break");
			AcceptEntityInput(ent2, "kill");
		}
		if(ent3>0 && IsValidEntity(ent3) && IsValidEdict(ent3))
		{
			AcceptEntityInput(ent3, "break");
			AcceptEntityInput(ent3, "kill");
		}
	}

	ShowParticle(pos, "gas_explosion_pump", 3.0);

	new pointHurt = CreateEntityByName("point_hurt");

	DispatchKeyValueFloat(pointHurt, "Damage", damage);
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius);
	DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(pointHurt, "Hurt");
	CreateTimer(0.1, DeletePointHurt, pointHurt);

	new push = CreateEntityByName("point_push");
	DispatchKeyValueFloat (push, "magnitude", force);
	DispatchKeyValueFloat (push, "radius", radius*1.0);
	SetVariantString("spawnflags 24");
	AcceptEntityInput(push, "AddOutput");
	DispatchSpawn(push);
	TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(push, "Enable");
	CreateTimer(0.5, DeletePushForce, push);

	return;
}

//new version
public PrecacheParticle(String:sEffectName[])
{
	new table = INVALID_STRING_TABLE;

	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		new save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

//old version
//public PrecacheParticle(String:particlename[])
//{
//	new particle = CreateEntityByName("info_particle_system");
//	if (IsValidEdict(particle))
//	{
//		DispatchKeyValue(particle, "effect_name", particlename);
//		DispatchKeyValue(particle, "targetname", "particle");
//		DispatchSpawn(particle);
//		ActivateEntity(particle);
//		AcceptEntityInput(particle, "start");
//		CreateTimer(0.01, DeleteParticles, particle);
//	}
//}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (particle> 0 && IsValidEntity(particle) && IsValidEdict(particle))
	{
		decl String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
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

public Action:DeletePointHurt(Handle:timer, any:ent)
{
	if (ent> 0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		decl String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_hurt", false))
		{
			AcceptEntityInput(ent, "Kill");
			RemoveEdict(ent);
		}
	}
}

public bool:DontHitSelf(entity, mask, any:data)
{
	if(entity == data)
	{
		return false;
	}
	return true;
}

public bool:DontHitSelfAndPlayer(entity, mask, any:data)
{
	if(entity == data)
	{
		return false;
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}

public bool:DontHitSelfAndPlayerAndCI(entity, mask, any:data)
{
	if(entity == data)
	{
		return false;
	}
	else if(entity>0 && entity<=MaxClients)
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
			decl String:edictname[128];
			GetEdictClassname(entity, edictname, 128);
			if(StrContains(edictname, "infected")>=0)
			{
				return false;
			}
		}
	}
	return true;
}

public bool:DontHitSelfAndMissile(entity, mask, any:data)
{
	if(entity == data)
	{
		return false;
	}
	else if(entity > MaxClients)
	{
		if(IsValidEntity(entity) && IsValidEdict(entity))
		{
			decl String:edictname[128];
			GetEdictClassname(entity, edictname, 128);
			if(StrContains(edictname, "prop_dynamic")>=0)
			{
				return false;
			}
		}
	}
	return true;
}

public bool:DontHitSelfAndSurvivor(entity, mask, any:data)
{
	if(entity == data)
	{
		return false;
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity)==2)
		{
			return false;
		}
	}
	return true;
}

public bool:DontHitSelfAndInfected(entity, mask, any:data)
{
	if(entity == data)
	{
		return false;
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity)==3)
		{
			return false;
		}
	}
	return true;
}