#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

#define Pai 3.14159265358979323846
#define DEBUG false

#define State_None 0
#define State_Scan 1
#define State_Sleep 2
#define State_Carry 3

#define PARTICLE_MUZZLE_FLASH		"weapon_muzzle_flash_autoshotgun"
#define PARTICLE_WEAPON_TRACER		"weapon_tracers"
#define PARTICLE_WEAPON_TRACER2		"weapon_tracers_50cal"//weapon_tracers_50cal" //"weapon_tracers_explosive" weapon_tracers_50cal

#define PARTICLE_BLOOD		"blood_impact_red_01"
#define PARTICLE_BLOOD2		"blood_impact_headshot_01"

#define SOUND_IMPACT1		"physics/flesh/flesh_impact_bullet1.wav"
#define SOUND_IMPACT2		"physics/concrete/concrete_impact_bullet1.wav"
#define SOUND_FIRE		"weapons/50cal/50cal_shoot.wav"
#define MODEL_W_PIPEBOMB "models/w_models/weapons/w_eq_pipebomb.mdl"
#define MODEL_GUN "models/w_models/weapons/w_minigun.mdl"
#define MODEL_GUN2 "models/w_models/weapons/50cal.mdl"

int MachineCount = 0;

int GameMode;
int L4D2Version;

#define EnemyArraySize 300
int InfectedsArray[EnemyArraySize];
int InfectedCount;

int UseCount[MAXPLAYERS+1];

float ScanTime=0.0;
int GunType[MAXPLAYERS+1];

int GunState[MAXPLAYERS+1];
int Gun[MAXPLAYERS+1];
int GunOwner[MAXPLAYERS+1];
int GunUser[MAXPLAYERS+1];
int GunEnemy[MAXPLAYERS+1];
int GunTeam[MAXPLAYERS+1];
int GunAmmo[MAXPLAYERS+1];
int AmmoIndicator[MAXPLAYERS+1];

int GunCarrier[MAXPLAYERS+1];
float GunCarrierOrigin[MAXPLAYERS+1][3];
float GunCarrierAngle[MAXPLAYERS+1][3];

float GunFireStopTime[MAXPLAYERS+1];
float GunLastCarryTime[MAXPLAYERS+1];

float GunFireTime[MAXPLAYERS+1];
float GunFireTotolTime[MAXPLAYERS+1];
int GunScanIndex[MAXPLAYERS+1];
float GunHealth[MAXPLAYERS+1];

bool Broken[MAXPLAYERS+1];
int LastButton[MAXPLAYERS+1];
float PressTime[MAXPLAYERS+1];
float LastTime[MAXPLAYERS+1];

int ShowMsg[MAXPLAYERS+1];

int g_sprite;
int g_PointHurt;

public Plugin myinfo =
{
	name = "Machine",
	author = "Pan Xiaohai",
	description = "",
	version = "1.08"
}

ConVar l4d_machine_enable ;
ConVar l4d_machine_damage_to_infected ;
ConVar l4d_machine_damage_to_survivor ;
//ConVar l4d_machine_damage_of_tank ;
ConVar l4d_machine_maxcount ;
ConVar l4d_machine_range ;
ConVar l4d_machine_overheat ;

ConVar l4d_machine_adminonly ;
ConVar l4d_machine_msg ;
ConVar l4d_machine_ammo_count ;
ConVar l4d_machine_ammo_type ;
ConVar l4d_machine_ammo_refill ;
ConVar l4d_machine_allow_carry ;
ConVar l4d_machine_sleep_time ;
ConVar l4d_machine_fire_rate ;
ConVar l4d_machine_health ;

ConVar l4d_machine_betray_chance ;

ConVar l4d_machine_limit ;

public void OnPluginStart()
{
	GameCheck();
 	l4d_machine_enable = CreateConVar("l4d_machine_enable", "2", "  0:disable, 1:enable in coop mode, 2: enable in all mode ", FCVAR_NOTIFY);
	l4d_machine_damage_to_infected = CreateConVar("l4d_machine_damage_to_infected", "1", "bullet damage", FCVAR_NOTIFY);
	l4d_machine_damage_to_survivor = CreateConVar("l4d_machine_damage_to_survivor", "0.0", "bullet damage", FCVAR_NOTIFY);
	//l4d_machine_damage_of_tank = CreateConVar("l4d_machine_damage_of_tank", "3", "bullet damage for tank", FCVAR_NOTIFY);
	l4d_machine_maxcount = CreateConVar("l4d_machine_maxuser", "4", "maximum of machine gun", FCVAR_NOTIFY);
	l4d_machine_range = CreateConVar("l4d_machine_range", "1000", "maxmum scan range of machine gun", FCVAR_NOTIFY);
	l4d_machine_overheat = CreateConVar("l4d_machine_overheat", "0.0", " seconds", FCVAR_NOTIFY);

	l4d_machine_adminonly = CreateConVar("l4d_machine_adminonly", "1", "1:admin use only", FCVAR_NOTIFY);
	l4d_machine_msg = CreateConVar("l4d_machine_msg", "1", "how many times to display usage information , 0 disable  ", FCVAR_NOTIFY);
	l4d_machine_ammo_count = CreateConVar("l4d_machine_ammo_count", "2000", "ammo count", FCVAR_NOTIFY);
	l4d_machine_ammo_type = CreateConVar("l4d_machine_ammo_type", "1", "0: normal , 1:incendiary 2:explosive", FCVAR_NOTIFY);
	l4d_machine_ammo_refill = CreateConVar("l4d_machine_ammo_refill", "1", "0:disable, 1:enable", FCVAR_NOTIFY);
	l4d_machine_allow_carry = CreateConVar("l4d_machine_allow_carry", "2", "0:disable carray 1:every one, 2:only creator", FCVAR_NOTIFY);
	l4d_machine_sleep_time = CreateConVar("l4d_machine_sleep_time", "0.0", "how many seconds does a gun goto sleep while no enemy, must >0", FCVAR_NOTIFY);
	l4d_machine_fire_rate = CreateConVar("l4d_machine_fire_rate", "5", "rate of fire, how many shot per soncods [5, 30]", FCVAR_NOTIFY);
 	l4d_machine_health = CreateConVar("l4d_machine_health", "700", "gun's health", FCVAR_NOTIFY);

 	l4d_machine_betray_chance = CreateConVar("l4d_machine_betray_chance", "0.0", "betray chance", FCVAR_NOTIFY);

	l4d_machine_limit = CreateConVar("l4d_machine_limit", "10.0", " ", FCVAR_NOTIFY);

 	AutoExecConfig(true, "l4d_machine");

	HookConVarChange(l4d_machine_range, ConVarChange);
	HookConVarChange(l4d_machine_overheat, ConVarChange);
	HookConVarChange(l4d_machine_sleep_time, ConVarChange);
	HookConVarChange(l4d_machine_fire_rate, ConVarChange);
	HookConVarChange(l4d_machine_ammo_count, ConVarChange);

	HookEvent("player_bot_replace", player_bot_replace );
	HookEvent("player_spawn", player_spawn);
	HookEvent("witch_harasser_set", witch_harasser_set);
	HookEvent("player_death", player_death);
	HookEvent("entity_shoved", entity_shoved);
	HookEvent("player_use", player_use);

	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);

	RegConsoleCmd("sm_machine", sm_machine);
	RegConsoleCmd("sm_removemachine", sm_removemachine);
	ResetAllState();
	GetConVar();
}

public void ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetConVar();
}

float FireIntervual = 0.08;
float FireOverHeatTime = 10.0;
float FireRange = 1000.0;
float SleepTime = 300.0;
int GunAmmoCount = 1000;

void GetConVar()
{
	FireOverHeatTime = GetConVarFloat(l4d_machine_overheat );
 	FireRange = GetConVarFloat(l4d_machine_range );
	SleepTime = GetConVarFloat(l4d_machine_sleep_time);
	FireIntervual = GetConVarFloat(l4d_machine_fire_rate);
	GunAmmoCount = GetConVarInt(l4d_machine_ammo_count);

	if(FireOverHeatTime <= 0.0) FireOverHeatTime = 10.0;
	if(FireRange <= 0.0) FireRange = 1.0;
	if(SleepTime <= 0.0) SleepTime = 300.0;
	if(FireIntervual <= 5.0) FireIntervual = 5.0;
	if(FireIntervual >= 30.0) FireIntervual = 30.0;
	FireIntervual = 1.0 / FireIntervual;
}

bool CanUse()
{
	int mode = GetConVarInt(l4d_machine_enable);
	if(mode == 0) return false;
	if(mode == 1 && GameMode != 2) return true;
	if(mode == 2) return true;
	return false;
}

public Action entity_shoved(Event event, char[] event_name, bool dontBroadcast)
{
	if(!CanUse()) return Plugin_Continue;
	if(GetConVarInt(l4d_machine_allow_carry) == 0)return Plugin_Continue;
	int attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(attacker > 0 && IsClientInGame(attacker) && GetClientTeam(attacker) == 2)
	{
		int b = GetClientButtons(attacker);
		if(b & IN_DUCK)
		{
			int gun = GetMinigun(attacker);
			if(gun > 0)
			{
				StartCarry(attacker, gun);
			}
		}
	}
	return Plugin_Continue;
}


public Action player_use(Event hEvent, const char[] strName, bool DontBroadcast)
{
	if(!CanUse()) return Plugin_Continue;
	if(GetConVarInt(l4d_machine_ammo_refill) == 0) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int ent = GetEventInt(hEvent, "targetid");
	char classname[64];
	GetEdictClassname(ent, classname, 64);
	if(StrContains(classname, "ammo")>=0)
	{
		int index = FindCarryIndex(client);
		if(index >= 0)
		{
			PrintHintText(client, "Machine gun's ammo have been refilled");
			GunAmmo[index] = GetConVarInt(l4d_machine_ammo_count);
		}
	}
	return Plugin_Continue;
}

int GetMinigun(int client)
{
	int ent = GetClientAimTarget(client, false);
	if(ent > 0)
	{
		char classname[64];
		GetEdictClassname(ent, classname, 64);
		if(StrEqual(classname, "prop_minigun") || StrEqual(classname, "prop_minigun_l4d1"))
		{
		}
		else ent = 0;
	}
	return ent;
}

public Action sm_machine(int client, int args)
{
	if(UseCount[client] >= GetConVarInt(l4d_machine_limit))
	{
		PrintToChat(client, "You can use it more than %d times",GetConVarInt(l4d_machine_limit));
		return;
	}

	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(GetConVarInt(l4d_machine_adminonly) == 1 && GetUserFlagBits(client) == 0)
		{
			PrintToChatAll("Only admin can spawn machine gun");
			return;
		}
		char str[32];
		int type = GetCmdArg(1, str, 32);
		if(strlen(str) == 0) type = GetRandomInt(0,1);
		else
		{
			if(StrEqual(str, "0")) type = 0;
			else type = 1;
		}
		CreateMachine(client, type);
	}
}

public Action sm_removemachine(int client, int args)
{
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		int gun = GetMinigun(client);
		int index = FindGunIndex(gun);
		if(index < 0)return;
		if(GetUserFlagBits(client) != 0)
		{
			int owner = GunOwner[index];
			if(owner == client) RemoveMachine(index);
			else if(owner > 0 && IsClientInGame(owner) && IsPlayerAlive(owner))
			{
				PrintHintText(client, "You can not reomve %N 's machine", owner);
			}
			else
			{
				RemoveMachine(index);
			}
		}
		else
		{
			RemoveMachine(index);
		}
	}
}

public void player_bot_replace(Event Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
	if(!CanUse()) return;
	int client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	int bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));
	StopClientCarry(client);
	StopClientCarry(bot);
}

public Action player_death(Event hEvent, const char[] strName, bool DontBroadcast)
{
	if(!CanUse()) return;
	// new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
}

public Action player_spawn(Event hEvent, const char[] strName, bool DontBroadcast)
{
	if(!CanUse()) return;
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client) )
		{

		}
	}
}

public Action witch_harasser_set(Event hEvent, const char[] strName, bool DontBroadcast)
{
	if(!CanUse()) return;
	int witch =  GetEventInt(hEvent, "witchid") ;
	InfectedsArray[0] = witch;
	for(int i = 0; i < MachineCount; i++)
	{
		GunEnemy[i] = witch;
		GunScanIndex[i] = 0;
	}
}
public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if(entity == data)
	{
		return false;
	}
	return true;
}

stock void PrintVector( float target[3], char[] s = "")
{
	PrintToChatAll("%s - %f %f %f", s, target[0], target[1], target[2]);
}

void CopyVector(float source[3], float target[3])
{
	target[0] = source[0];
	target[1] = source[1];
	target[2] = source[2];
}

void SetVector(float target[3], float x, float y, float z)
{
	target[0] = x;
	target[1] = y;
	target[2] = z;
}

void GameCheck()
{
	char GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));

	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
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
}

public Action round_end(Event event, const char[] name, bool dontBroadcast)
{
	ResetAllState();
}

public void OnMapStart()
{
	PrecacheModel(MODEL_W_PIPEBOMB);
	PrecacheModel(MODEL_GUN);
	PrecacheModel(MODEL_GUN2);

	PrecacheSound(SOUND_FIRE);
	PrecacheSound(SOUND_IMPACT1);
	PrecacheSound(SOUND_IMPACT2);

	PrecacheParticle(PARTICLE_MUZZLE_FLASH);

	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		PrecacheParticle(PARTICLE_WEAPON_TRACER2);
		PrecacheParticle(PARTICLE_BLOOD2);
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");
		PrecacheParticle(PARTICLE_WEAPON_TRACER);
		PrecacheParticle(PARTICLE_BLOOD);
	}
}

public Action ShowInfo(Handle timer, any client)
{
	if(L4D2Version) DisplayHint(INVALID_HANDLE, client);
	else PrintToChat(client, "\x03Press \x04DUCK+SHOVE to \x03carry \x04machine gun\x03");
}
//code from "DJ_WEST"

public Action DisplayHint(Handle h_Timer, any i_Client)
{
	if ( IsClientInGame(i_Client))	ClientCommand(i_Client, "gameinstructor_enable 1");
	CreateTimer(1.0, DelayDisplayHint, i_Client);
}

public Action DelayDisplayHint(Handle h_Timer, any i_Client)
{
	DisplayInstructorHint(i_Client, "DUCK+SHOVE to carry machine gun", "+attack2");
}

public void DisplayInstructorHint(int i_Client, char s_Message[256], char[] s_Bind)
{
	int i_Ent; 
	char s_TargetName[32];
	Handle h_RemovePack;

	i_Ent = CreateEntityByName("env_instructor_hint");
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", i_Client);
	ReplaceString(s_Message, sizeof(s_Message), "\n", " ");
	DispatchKeyValue(i_Client, "targetname", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_timeout", "5");
	DispatchKeyValue(i_Ent, "hint_range", "0.01");
	DispatchKeyValue(i_Ent, "hint_color", "255 255 255");
	DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding");
	DispatchKeyValue(i_Ent, "hint_caption", s_Message);
	DispatchKeyValue(i_Ent, "hint_binding", s_Bind);
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "ShowHint");

	h_RemovePack = CreateDataPack();
	WritePackCell(h_RemovePack, i_Client);
	WritePackCell(h_RemovePack, i_Ent);
	CreateTimer(5.0, RemoveInstructorHint, h_RemovePack);
}

public Action RemoveInstructorHint(Handle h_Timer, Handle h_Pack)
{
	int i_Ent, i_Client;

	ResetPack(h_Pack, false);
	i_Client = ReadPackCell(h_Pack);
	i_Ent = ReadPackCell(h_Pack);
	CloseHandle(h_Pack);

	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled;

	if (IsValidEntity(i_Ent))
			RemoveEdict(i_Ent);

	ClientCommand(i_Client, "gameinstructor_enable 0");

	DispatchKeyValue(i_Client, "targetname", "");

	return Plugin_Continue;
}

public void PrecacheParticle(char[] particlename)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action DeleteParticles(Handle timer, any particle)
{
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

public Action DeleteParticletargets(Handle timer, any target)
{
	 if (IsValidEntity(target))
	 {
		char classname[64];
		GetEdictClassname(target, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_target", false) || StrEqual(classname, "info_target", false))
		{
			AcceptEntityInput(target, "stop");
			AcceptEntityInput(target, "kill");
			RemoveEdict(target);
		}
	}
}

public int ShowParticle(float pos[3], float ang[3], char[] particlename, float time)
{
 	int particle = CreateEntityByName("info_particle_system");
 	if (IsValidEdict(particle))
 	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchSpawn(particle);
		ActivateEntity(particle);

		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		return particle;
 	}
 	return 0;
}

//draw line between pos1 and pos2
stock int ShowLaser(int colortype, float pos1[3], float pos2[3], float life = 10.0, float width1 = 1.0, float width2 = 11.0)
{
	int color[4];
	if(colortype == 1)
	{
		color[0] = 200;
		color[1] = 0;
		color[2] = 0;
		color[3] = 230;
	}
	else if(colortype == 2)
	{
		color[0] = 0;
		color[1] = 200;
		color[2] = 0;
		color[3] = 230;
	}
	else if(colortype == 3)
	{
		color[0] = 0;
		color[1] = 0;
		color[2] = 200;
		color[3] = 230;
	}
	else
	{
		color[0] = 200;
		color[1] = 200;
		color[2] = 200;
		color[3] = 230;
	}
	TE_SetupBeamPoints(pos1, pos2, g_sprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
	TE_SendToAll();
}

//draw line between pos1 and pos2
stock int ShowPos(int color, float pos1[3], float pos2[3], float life = 10.0, float length = 200.0, float width = 1.0, float width2 = 4.0)
{
	float t[3];
	if(length != 0.0)
	{
		SubtractVectors(pos2, pos1, t);
		NormalizeVector(t,t);
		ScaleVector(t, length);
		AddVectors(pos1, t,t);
	}
	else
	{
		CopyVector(pos2,t);
	}
	ShowLaser(color, pos1, t, life,   width1, width2);
}

//draw line start from pos, the line's drection is dir.
stock int  ShowDir(int color, float pos[3], float dir[3], float life = 10.0, float length = 200.0, float width1 = 1.0, float width2 = 4.0)
{
	float pos2[3];
	CopyVector(dir, pos2);
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life,   width1, width2);
}

//draw line start from pos, the line's angle is angle.
stock int ShowAngle(int color, float pos[3], float dir[3], float life = 10.0, float length = 200.0, float width1 = 1.0, float width2 = 4.0)
{
	float pos2[3];
	GetAngleVectors(angle, pos2, NULL_VECTOR, NULL_VECTOR);

	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life, width1, width2);
}

void ShowMuzzleFlash(float pos[3], float angle[3])
{
 	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_MUZZLE_FLASH);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	TeleportEntity(particle, pos, angle, NULL_VECTOR);
	AcceptEntityInput(particle, "start");
	CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
}

void ShowTrack(float pos[3], float endpos[3])
{
 	char temp[32];
	int target = 0;
	if(L4D2Version) target = CreateEntityByName("info_particle_target");
	else target = CreateEntityByName("info_target");
	Format(temp, 32, "cptarget%d", target);
	DispatchKeyValue(target, "targetname", temp);
	TeleportEntity(target, endpos, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(target);

	int particle = CreateEntityByName("info_particle_system");
	if(L4D2Version)	DispatchKeyValue(particle, "effect_name", PARTICLE_WEAPON_TRACER2);
	else DispatchKeyValue(particle, "effect_name", PARTICLE_WEAPON_TRACER);
	DispatchKeyValue(particle, "cpoint1", temp);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(particle, "start");
	CreateTimer(0.01, DeleteParticletargets, target, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
}

int CreatePointHurt()
{
	int pointHurt = CreateEntityByName("point_hurt");
	if(pointHurt)
	{
		DispatchKeyValue(pointHurt,"Damage","10");
		if(L4D2Version)	DispatchKeyValue(pointHurt,"DamageType","-2130706430");
		DispatchSpawn(pointHurt);
	}
	return pointHurt;
}

char N[10];

void DoPointHurtForInfected(int victim, int attacker = 0, int team)
{
	if(g_PointHurt > 0)
	{
		if(IsValidEdict(g_PointHurt))
		{
			if(victim>0 && IsValidEdict(victim))
			{

				Format(N, 20, "target%d", victim);
				DispatchKeyValue(victim,"targetname", N);
				DispatchKeyValue(g_PointHurt,"DamageTarget", N);
				float FireDamage;
				if(team == 2) FireDamage=GetConVarFloat(l4d_machine_damage_to_infected);
				else FireDamage = GetConVarFloat(l4d_machine_damage_to_survivor);
				DispatchKeyValueFloat(g_PointHurt,"Damage", FireDamage);
				int type = GetConVarInt(l4d_machine_ammo_type);
				if(type == 1 && victim <= MaxClients) type = 0;
				if(L4D2Version)
				{
					if(type == 1 && victim <= MaxClients) type = 0;
					if(type == 1 && victim <= MaxClients) type = 0;
					if(type == 0) DispatchKeyValue(g_PointHurt, "DamageType", "-2130706430");
					else if(type == 1) DispatchKeyValue(g_PointHurt, "DamageType", "-2130706422"); 	//incendiary
					else if(type == 2)DispatchKeyValue(g_PointHurt, "DamageType", " -2122317758"); 	//explosive
					DispatchKeyValueFloat(g_PointHurt, "Damage", FireDamage);
				}
				else
				{
					if(victim <= MaxClients) type = 0;
					if(type == 0)
					{
						int h = GetEntProp(victim, Prop_Data, "m_iHealth");
						if(h * 1.0 <= FireDamage) DispatchKeyValue(g_PointHurt, "DamageType", "64");
						else  DispatchKeyValue(g_PointHurt, "DamageType", "-1073741822");
					}
					else if(type == 1)
					{
						DispatchKeyValue(g_PointHurt, "DamageType", "8");
					}
					else if(type == 2)
					{
						DispatchKeyValue(g_PointHurt, "DamageType", "64");
					}
				}
				AcceptEntityInput(g_PointHurt, "Hurt", (attacker > 0) ? attacker: -1);
			}
		}
		else g_PointHurt = CreatePointHurt();
	}
	else g_PointHurt = CreatePointHurt();
}

public void OnEntityCreated(int entity, const char[] classname)
{
}

void ResetAllState()
{
	g_PointHurt = 0;
	MachineCount = 0;
	ScanTime = 0.0;
	for(int i = 1; i <= MaxClients; i++)
	{
		GunState[i] = State_None;
		ShowMsg[i] = 0;
		GunOwner[i] = GunCarrier[i] = Gun[i] = 0;
		UseCount[i] = 0;
	}
	ClearEnemys();
	GetConVar();
}

void ScanEnemys()
{
	if(IsWitch(InfectedsArray[0]))
	{
		InfectedCount = 1;
	}
	else InfectedCount = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			InfectedsArray[InfectedCount++] = i;
		}
	}
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "infected" )) != -1 && InfectedCount < EnemyArraySize - 1)
	{
		InfectedsArray[InfectedCount++] = ent;
	}
}

void ClearEnemys()
{
	InfectedCount = 0;
}

int IsWitch(int witch)
{
	if(witch > 0 && IsValidEdict(witch) && IsValidEntity(witch))
	{
		char classname[32];
		GetEdictClassname(witch, classname, sizeof(classname));
		if(StrEqual(classname, "witch"))
		{
			return true;
		}
	}
	return false;
}

void CreateMachine(int client, int type = 0)
{
	if(MachineCount >= GetConVarInt(l4d_machine_maxcount))
	{
		PrintToChat(client, "There are too many machine");
		return;
	}

	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(!(GetEntityFlags(client) & FL_ONGROUND))return;
		Gun[MachineCount] = SpawnMiniGun(client, MachineCount, type);
		int gun = Gun[MachineCount];
		GunState[MachineCount] = State_Scan;
		LastTime[MachineCount] = GetEngineTime();
		Broken[MachineCount] = false;

		GunScanIndex[MachineCount] = 0;
		GunEnemy[MachineCount] = 0;
		GunFireTime[MachineCount] = 0.0;
		GunFireStopTime[MachineCount] = 0.0;
		GunFireTotolTime[MachineCount] = 0.0;
		GunOwner[MachineCount] = client;
		GunUser[MachineCount] = client;
		GunCarrier[MachineCount] = 0;
		GunTeam[MachineCount] = 2;
		AmmoIndicator[MachineCount] = 0;
		GunLastCarryTime[MachineCount] = GetEngineTime();
		GunAmmo[MachineCount] = GetConVarInt(l4d_machine_ammo_count);
		GunHealth[MachineCount] = GetConVarFloat(l4d_machine_health);
		SDKUnhook( Gun[MachineCount], SDKHook_Think,  PreThinkGun);
		SDKHook( Gun[MachineCount], SDKHook_Think,  PreThinkGun);

		UseCount[client]++;
		if(MachineCount == 0)
		{
			ScanEnemys();
		}

		if(ShowMsg[client] < GetConVarInt(l4d_machine_msg))
		{
			ShowMsg[client]++;
			CreateTimer(1.0, ShowInfo, client);
		}

		MachineCount++;

		SDKUnhook(gun, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		SDKHook(gun, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	}
}

void RemoveMachine(int index)
{
	if(GunState[index] == State_None)return;
	GunState[index] = State_None;
	SDKUnhook( Gun[index], SDKHook_Think,  PreThinkGun);
	SDKUnhook(Gun[index], SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	if(Gun[index] > 0 && IsValidEdict(Gun[index]) && IsValidEntity(Gun[index]))AcceptEntityInput((Gun[index]), "Kill");
	Gun[index] = 0;
	if(MachineCount > 1)
	{
		Gun[index] = Gun[MachineCount - 1];
		GunState[index] = GunState[MachineCount - 1];
		LastTime[index] = LastTime[MachineCount - 1];
		Broken[index] = Broken[MachineCount - 1];
		GunScanIndex[index] = GunScanIndex[MachineCount - 1];
		GunEnemy[index] = GunEnemy[MachineCount - 1];
		GunFireTime[index] = GunFireTime[MachineCount - 1];
		GunFireStopTime[index] = GunFireStopTime[MachineCount - 1];
		GunFireTotolTime[index] = GunFireTotolTime[MachineCount - 1];
		GunOwner[index] = GunOwner[MachineCount - 1];
		GunUser[index] = GunUser[MachineCount - 1];
		GunCarrier[index] = GunCarrier[MachineCount - 1];
		GunLastCarryTime[index] = GunLastCarryTime[MachineCount - 1];
		GunAmmo[index] = GunAmmo[MachineCount - 1];
		AmmoIndicator[index] = AmmoIndicator[MachineCount - 1];
		GunHealth[index]  = GunHealth[MachineCount - 1];
		GunTeam[index] = GunTeam[MachineCount - 1];
		GunType[index] = GunType[MachineCount - 1];
	}
	MachineCount--;

	if(MachineCount <0) MachineCount = 0;
}

/* code from  "Movable Machine Gun", author = "hihi1210"
*/
int SpawnMiniGun(int client, int index, int type)
{
	float VecOrigin[3];
	float VecAngles[3];
	float VecDirection[3];
	int gun = 0;

	if(L4D2Version)
	{
		if(type == 0)
		{
			gun = CreateEntityByName ("prop_minigun_l4d1");
			SetEntityModel (gun, MODEL_GUN);
			GunType[index] = 0;
		}
		else if(type == 1)
		{
			gun = CreateEntityByName ( "prop_minigun");
			SetEntityModel (gun, MODEL_GUN2);
			GunType[index] = 1;
		}
	}
	else
	{
		gun = CreateEntityByName ("prop_minigun");
		SetEntityModel (gun, MODEL_GUN);
		GunType[index] = 0;
	}

	DispatchSpawn(gun);

	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 45;
	VecOrigin[1] += VecDirection[1] * 45;
	VecOrigin[2] += VecDirection[2] * 1;
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(gun, "Angles", VecAngles);

	TeleportEntity(gun, VecOrigin, NULL_VECTOR, NULL_VECTOR);

	SetEntProp(gun, Prop_Send, "m_iTeamNum", 2);
	//SetEntProp(index, Prop_Data, "m_CollisionGroup", 2);
	SetColor(gun, 2);

	return gun;
}

void SetColor(int gun, int team)
{
	if(!L4D2Version)return;
	SetEntProp(gun, Prop_Send, "m_iGlowType", 3);
	SetEntProp(gun, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(gun, Prop_Send, "m_nGlowRangeMin", 1);
	int red = 0;
	int gree = 0;
	int blue = 0;
	if(team == 3)
	{
		red = 200;
		gree = 0;
		blue = 0;
	}
	else
	{
		red = 0;
		gree = 100;
		blue = 0;
	}
	SetEntProp(gun, Prop_Send, "m_glowColorOverride", red + (gree * 256) + (blue * 65536));
}

int PutMiniGun(int gun, float VecOrigin[3], float VecAngles[3])
{
	float VecDirection[3];

	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 45;
	VecOrigin[1] += VecDirection[1] * 45;
	VecOrigin[2] += VecDirection[2] * 1;
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(gun, "Angles", VecAngles);
	TeleportEntity(gun, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	if(L4D2Version)
	{
		SetEntProp(gun, Prop_Send, "m_iGlowType", 3 ); //3
		SetEntProp(gun, Prop_Send, "m_nGlowRange", 0 ); //0
		SetEntProp(gun, Prop_Send, "m_glowColorOverride", 1); //1
	}
	return gun;
}

int FindGunIndex(int gun)
{
	int index = -1;
	for(int i = 0; i < MachineCount; i++)
	{
		if(Gun[i] == gun)
		{
			index = i;
			break;
		}
	}
	return index;
}

int FindCarryIndex(int client)
{
	int index = -1;
	for(int i = 0; i < MachineCount; i++)
	{
		if(GunCarrier[i] == client)
		{
			index = i;
			break;
		}
	}
	return index;
}

void StartCarry(int client, int gun)
{

	if(FindCarryIndex(client) >= 0) return;
	int index = FindGunIndex(gun);
	if(index >= 0)
	{
		if(GunCarrier[index] > 0) return;

		if(GetConVarInt(l4d_machine_allow_carry) == 2)
		{
			int owner = GunOwner[index];
			if(owner > 0 && IsClientInGame(owner) && IsPlayerAlive(owner))
			{
				if(owner != client)
				{
					PrintHintText(client, "You can not pick up %N 's machine", owner);
					return;
				}
			}
			else
			{
				GunOwner[index] = client;
			}
		}
		GunCarrier[index] = client;
		SetEntProp(gun, Prop_Send, "m_CollisionGroup", 2);
		SetEntProp(gun, Prop_Send, "m_firing", 0);
		float ang[3];
		SetVector(ang, 0.0, 0.0, 90.0);
		float pos[3];
		SetVector(pos, -5.0, 20.0,  0.0);
		if(GetClientTeam(client) == 2)	AttachEnt(client, gun, "medkit", pos, ang);
		else AttachEnt(client, gun, "medkit", pos, ang);
		LastButton[index] = 0;
		PressTime[index] = 0.0;
		GunState[index] = State_Carry;
		GunUser[index] = client;
		GunLastCarryTime[index] = GetEngineTime();
		GunHealth[index] = GetConVarFloat(l4d_machine_health);

		SDKUnhook(Gun[index], SDKHook_OnTakeDamagePost, OnTakeDamagePost);

		GunTeam[index] = 2;

		SetColor(Gun[index], 2);
		if(GunAmmo[index] > 0)
		{
			PrintHintText(client, "Machine gun's ammo: %d ", GunAmmo[index]);
		}
		else
		{
			PrintHintText(client, "Your machine is out of ammo, please refill");
		}
	}
}

int StopClientCarry(int client)
{
	if(client <= 0) return;
	int index = FindCarryIndex(client);
	if(index >= 0)
	{
		StopCarry(index);
	}
	return;
}

void StopCarry(int index)
{
	if(GunCarrier[index] > 0)
	{
		GunCarrier[index] = 0;
		AcceptEntityInput(Gun[index], "ClearParent");
		PutMiniGun(Gun[index], GunCarrierOrigin[index], GunCarrierAngle[index]);
		SetEntProp(Gun[index], Prop_Send, "m_CollisionGroup", 0);

		GunLastCarryTime[index] = GetEngineTime();
		GunState[index] = State_Scan;
		Broken[index] = false;
		GunEnemy[index] = 0;
		GunScanIndex[index] = 0;
		GunFireTotolTime[index] = 0.0;
		GunTeam[index] = 2;
		SDKHook(Gun[index], SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		SetColor(Gun[index], 2);
	}
}

void Carrying(int index, float intervual)
{
	int client = GunCarrier[index];
	int button = GetClientButtons(client);
	GetClientAbsOrigin(client, GunCarrierOrigin[index]);
	GetClientEyeAngles(client, GunCarrierAngle[index]);
	if(button & IN_USE)
	{
		int targetRevive = GetEntPropEnt(client, Prop_Send, "m_reviveTarget");

		if (targetRevive != -1)
		{
			PressTime[client] = GetEngineTime();
			return;
		}

		int targetUseAction = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");

		if (targetUseAction != -1)
		{
			PressTime[client] = GetEngineTime();
			return;
		}

		PressTime[index] += intervual;
		if(PressTime[index] > 0.5)
		{
			if(GetEntityFlags(client) & FL_ONGROUND) StopCarry(index);
		}
	}
	else
	{
		PressTime[index] = 0.0;
	}
	LastButton[index] = client;
}

void AttachEnt(int owner, int ent, char[] positon = "medkit", float pos[3] = NULL_VECTOR, float ang[3] = NULL_VECTOR)
{
	char tname[60];
	Format(tname, sizeof(tname), "target%d", owner);
	DispatchKeyValue(owner, "targetname", tname);
	DispatchKeyValue(ent, "parentname", tname);

	SetVariantString(tname);
	AcceptEntityInput(ent, "SetParent", ent, ent, 0);
	if(strlen(positon) != 0)
	{
		SetVariantString(positon);
		AcceptEntityInput(ent, "SetParentAttachment");
	}
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
}

public void PreThinkGun(int gun)
{
	int index = FindGunIndex(gun);
	if(index != -1)
	{
		float time = GetEngineTime( );
		float intervual = time - LastTime[index];
		LastTime[index] = time;

		if(GunState[index] == State_Scan || GunState[index] == State_Sleep)
		{
			ScanAndShotEnmey(index, time, intervual);
		}
		else if(GunState[index] == State_Carry)
		{
			int carrier = GunCarrier[index];
			if(IsClientInGame(carrier) && IsPlayerAlive(carrier) && !IsFakeClient(carrier))
			{
				Carrying(index, intervual);
			}
			else
			{
				StopCarry(index);
			}
		}
	}
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	//PrintToChatAll("%d inflictor, %d type", inflictor, damagetype);

	//if(!L4D2Version)return;
	int index = FindGunIndex(victim);
	if(GunState[index] == State_Carry) return;
	if(damage <= 0.0) return;
	if(index >= 0)
	{
		bool betrayToInfected = false;
		bool betrayToSurvivor = false;
		bool print = false;
		bool wakeup = false;
		bool attackerIsPlayer = false;
		if(attacker > 0 && attacker <= MaxClients)
		{
			if(IsClientInGame(attacker))
			{
				if(GetClientTeam(attacker) == 2 && damagetype == 128)
				{
					if(GunTeam[index] == 3)
					{
						betrayToInfected = false;
						betrayToSurvivor = true;
					}
				}
				else if(GunTeam[index] == 2)
				{
					betrayToInfected = true;
				}
				if(damagetype == 128) wakeup = true;
				attackerIsPlayer = true;
				if(GetClientTeam(attacker) == 3)
				{
					wakeup = true;
				}
				print = true;
			}
			else print = false;
		}
		else
		{
			if(GunTeam[index] == 2)
			{
				betrayToInfected = true;
			}
			wakeup = true;
		}
		if(betrayToInfected && GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_machine_betray_chance))
		{
			PrintHintTextToAll("A machine gun betray to infected team");
			GunLastCarryTime[index] = GetEngineTime();
			//GunState[index]=State_Scan;
			Broken[index] = false;
			GunEnemy[index] = 0;
			GunScanIndex[index] = 0;
			GunFireTotolTime[index] = 0.0;
			GunTeam[index] = 3;
			GunHealth[index] = GetConVarFloat(l4d_machine_health);
			if(attackerIsPlayer) GunUser[index] = attacker;
			print = false;
			SetColor(Gun[index], GunTeam[index]);
		}
		if(betrayToSurvivor)
		{
			PrintHintTextToAll("A machine gun betray to survivor team");
			GunLastCarryTime[index]=GetEngineTime();
			//GunState[index]=State_Scan;
			Broken[index] = false;
			GunEnemy[index] = 0;
			GunScanIndex[index] = 0;
			GunFireTotolTime[index] = 0.0;
			GunTeam[index] = 2;
			GunHealth[index] = GetConVarFloat(l4d_machine_health);
			if(attackerIsPlayer) GunUser[index] = attacker;
			print = false;
			SetColor(Gun[index], GunTeam[index]);
		}
 		if(wakeup && GunState[index] == State_Sleep)
		{
			PrintHintTextToAll("A machine gun waked up");
			GunLastCarryTime[index] = GetEngineTime();
			GunState[index] = State_Scan;
			Broken[index] = false;
			GunEnemy[index] = 0;
			GunScanIndex[index] = 0;
			GunFireTotolTime[index] = 0.0;
			GunHealth[index] = GetConVarFloat(l4d_machine_health);
			if(attackerIsPlayer) GunUser[index] = attacker;
			print = false;
			wakeup = true;
			SetColor(Gun[index], GunTeam[index]);
		}
		else wakeup = false;
		float oldHealth = GunHealth[index];
		if(!betrayToInfected && !betrayToSurvivor && !wakeup)GunHealth[index] -= damage;
		if(GunHealth[index] <= 0.0)
		{
			GunHealth[index] = 0.0;
			GunState[index] = State_Sleep;
			float gun1angle[3];
			GetEntPropVector(Gun[index], Prop_Send, "m_angRotation", gun1angle);
			gun1angle[0] =- 45.0;
			DispatchKeyValueVector(Gun[index], "Angles", gun1angle);
			SetEntProp(Gun[index], Prop_Send, "m_firing", 0);
			if(GunUser[index] > 0 && IsClientInGame(GunUser[index]) && oldHealth > 0.0)
			{
				PrintHintText(GunUser[index], "Your machine gun has been damaged");
			}
			SetColor(Gun[index], GunTeam[index]);
		}
		if(print)PrintHintText(attacker, "Gun's health %d", RoundFloat(GunHealth[index]));
	}
}

int ScanAndShotEnmey(int index, float time, float intervual)
{
	bool ok = false;
	int gun1 = Gun[index];
	if(gun1 > 0 && IsValidEdict(gun1) && IsValidEntity(gun1)) ok = true;

	int user = GunUser[index];
	if(user > 0 && IsClientInGame(user)) user = user + 0;
	else user = 0;

	if(ok == false || Broken[index])
	{
		if(user > 0) PrintHintText(user, "Your machine was broke");
		RemoveMachine(index);
	}

	Broken[index] = true;

	if(GunState[index] == State_Sleep)
	{
		SetEntProp(gun1, Prop_Send, "m_firing", 0);
		Broken[index] = false;
		return;
	}
	if(time - ScanTime > 1.0)
	{
		ScanTime = time;
		ScanEnemys();
	}

	float gun1pos[3];
	float gun1angle[3];
	float hitpos[3];
	float temp[3];
	float shotangle[3];
	float gunDir[3];

	GetEntPropVector(gun1, Prop_Send, "m_vecOrigin", gun1pos);
	GetEntPropVector(gun1, Prop_Send, "m_angRotation", gun1angle);

	if(GunLastCarryTime[index] + SleepTime < time)
	{
		GunState[index] = State_Sleep;
		gun1angle[0] =- 45.0;
		DispatchKeyValueVector(gun1, "Angles", gun1angle);
		SetEntProp(gun1, Prop_Send, "m_firing", 0);
		PrintToChatAll("A machine gun go to sleep");
		return;
	}
	GetAngleVectors(gun1angle, gunDir, NULL_VECTOR, NULL_VECTOR );
	NormalizeVector(gunDir, gunDir);
	CopyVector(gunDir, temp);
	if(GunType[index] == 0) ScaleVector(temp, 20.0);
	else ScaleVector(temp, 50.0);
	AddVectors(gun1pos, temp ,gun1pos);
	GetAngleVectors(gun1angle, NULL_VECTOR, NULL_VECTOR, temp );
	NormalizeVector(temp, temp);
	//ShowDir(2, gun1pos, temp, 0.06);
	ScaleVector(temp, 43.0);

	AddVectors(gun1pos, temp ,gun1pos);

	int newenemy = GunEnemy[index];
	if( IsVilidEenmey(newenemy, GunTeam[index]))
	{
		newenemy = IsEnemyVisible(gun1, newenemy, gun1pos, hitpos,shotangle, GunTeam[index]);
	}
	else newenemy = 0;

	if(InfectedCount > 0 && newenemy == 0)
	{
		if(GunScanIndex[index] >= InfectedCount)
		{
			GunScanIndex[index] = 0;
		}
		GunEnemy[index] = InfectedsArray[GunScanIndex[index]];
		GunScanIndex[index]++;
		newenemy = 0;
		//if(IsVilidEenmey(newenemy, GunTeam[index]))
		//{
			//newenemy=IsEnemyVisible(gun1, newenemy, gun1pos, hitpos, shotangle,GunTeam[index]);
		//}
	}
	//GunEnemy[index]=newenemy;

	//PrintToChatAll("team %d enemy %d",GunTeam[index], newenemy);
	if(newenemy == 0)
	{
		SetEntProp(gun1, Prop_Send, "m_firing", 0);
		Broken[index] = false;
		return;
	}

	float enemyDir[3];
	float newGunAngle[3];
	if(newenemy > 0)
	{
		SubtractVectors(hitpos, gun1pos, enemyDir);
	}
	else
	{
		CopyVector(gunDir, enemyDir);
		enemyDir[2] = 0.0;
	}
	NormalizeVector(enemyDir, enemyDir);

	float targetAngle[3];
	GetVectorAngles(enemyDir, targetAngle);
	float diff0 = AngleDiff(targetAngle[0], gun1angle[0]);
	float diff1 = AngleDiff(targetAngle[1], gun1angle[1]);

	float turn0 = 45.0 * Sign(diff0) * intervual;
	float turn1 = 180.0 * Sign(diff1) * intervual;
	if(FloatAbs(turn0) >= FloatAbs(diff0))
	{
		turn0 = diff0;
	}
	if(FloatAbs(turn1) >= FloatAbs(diff1))
	{
		turn1 = diff1;
	}

	newGunAngle[0] = gun1angle[0] + turn0;
	newGunAngle[1] = gun1angle[1] + turn1;

	newGunAngle[2] = 0.0;

	//PrintVector(newGunAngle);
	DispatchKeyValueVector(gun1, "Angles", newGunAngle);
	int overheated = GetEntProp(gun1, Prop_Send, "m_overheated");

	GetAngleVectors(newGunAngle, gunDir, NULL_VECTOR, NULL_VECTOR);
	//PrintToChatAll("find %d  %f %f", newenemy  );
	if(overheated == 0)
	{
		if(newenemy > 0 && FloatAbs(diff1) < 40.0)
		{
			if(time >= GunFireTime[index] && GunAmmo[index] > 0)
			{
				GunFireTime[index] = time + FireIntervual;
				Shot(user, index, gun1, GunTeam[index], gun1pos, newGunAngle);
				GunAmmo[index]--;
				AmmoIndicator[index]++;
				if(AmmoIndicator[index] >= GunAmmoCount / 20.0)
				{
					AmmoIndicator[index] = 0;
					if(user > 0) PrintCenterText(user, "Machine gun's ammo: %d ( %d %%)", GunAmmo[index], RoundFloat(GunAmmo[index] * 100.0 / GunAmmoCount ));
				}
				if(GunAmmo[index] == 0)
				{
					if(user>0) PrintHintText(user, "Your machine is out of ammo, please refill");
				}
				GunFireStopTime[index] = time + 0.05;
				GunLastCarryTime[index] = time;
			}
		}
	}
	float heat = GetEntPropFloat(gun1, Prop_Send, "m_heat");

	if(time < GunFireStopTime[index])
	{
		GunFireTotolTime[index] += intervual;
		heat = GunFireTotolTime[index] / FireOverHeatTime;
		if(heat >= 1.0) heat = 1.0;
		SetEntProp(gun1, Prop_Send, "m_firing", 1);
		SetEntPropFloat(gun1, Prop_Send, "m_heat", heat);
	}
	else
	{
		SetEntProp(gun1, Prop_Send, "m_firing", 0);
		heat = heat - intervual / 4.0;
		if(heat < 0.0)
		{
			heat = 0.0;
			SetEntProp(gun1, Prop_Send, "m_overheated", 0);
			SetEntPropFloat(gun1, Prop_Send, "m_heat", 0.0 );
		}
		else SetEntPropFloat(gun1, Prop_Send, "m_heat", heat );
		GunFireTotolTime[index] = FireOverHeatTime*heat;
	}
	Broken[index] = false;
	return;
}

int IsEnemyVisible(int gun, int ent, float gunpos[3], float hitpos[3], float angle[3], int team)
{
	if(ent <= 0) return 0;

	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", hitpos);
	hitpos[2] += 35.0;

	SubtractVectors(hitpos, gunpos, angle);
	GetVectorAngles(angle, angle);
	Handle trace = TR_TraceRayFilterEx(gunpos, angle, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, gun);
	if(team == 2) team = 3;
	else team = 2;
	int newenemy = 0;

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		newenemy = TR_GetEntityIndex(trace);
		if(GetVectorDistance(gunpos, hitpos) > FireRange) newenemy = 0;
	}
	else
	{
		newenemy = ent;
	}
	if(newenemy > 0)
	{
		if(newenemy <= MaxClients)
		{
			if(IsClientInGame(newenemy) && IsPlayerAlive(newenemy) && GetClientTeam(newenemy)==team)
			{
				newenemy = newenemy + 0;
			}
			else newenemy = 0;
		}
		else if(team == 3)
		{
			char classname[32];
			GetEdictClassname(newenemy, classname,32);
			if(StrEqual(classname, "infected", true) || StrEqual(classname, "witch", true))
			{
				newenemy = newenemy + 0;
			}
			else newenemy = 0;
		}
	}
	CloseHandle(trace);
	return newenemy;
}

void Shot(int client, int index, int gun, int team, float gunpos[3], float shotangle[3])
{
	float temp[3];
	float ang[3];
	GetAngleVectors(shotangle, temp, NULL_VECTOR,NULL_VECTOR);
	NormalizeVector(temp, temp);

	float acc = 0.020;
	temp[0] += GetRandomFloat(-1.0, 1.0)*acc;
	temp[1] += GetRandomFloat(-1.0, 1.0)*acc;
	temp[2] += GetRandomFloat(-1.0, 1.0)*acc;
	GetVectorAngles(temp, ang);

	Handle trace = TR_TraceRayFilterEx(gunpos, ang, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, gun);
	int enemy = 0;

	if(TR_DidHit(trace))
	{
		float hitpos[3];
		TR_GetEndPosition(hitpos, trace);
		enemy = TR_GetEntityIndex(trace);

		bool blood = false;
		if(enemy > 0)
		{
			char classname[32];
			GetEdictClassname(enemy, classname, 32);
			if(enemy >= 1 && enemy <= MaxClients)
			{
				if(GetClientTeam(enemy) == team) {enemy = 0;}
				blood = true;
			}
			else if(StrEqual(classname, "infected") || StrEqual(classname, "witch" ) ){ }
			else enemy = 0;
		}
		if(enemy > 0)
		{
			if(client > 0 && IsPlayerAlive(client)) client = client + 0;
			else client = 0;
			DoPointHurtForInfected(enemy, client, team);
			float Direction[3];
			GetAngleVectors(ang, Direction, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(Direction, -1.0);
			GetVectorAngles(Direction,Direction);
			if(!L4D2Version || blood)ShowParticle(hitpos, Direction, PARTICLE_BLOOD, 0.1);
			EmitSoundToAll(SOUND_IMPACT1, 0,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, hitpos, NULL_VECTOR, true, 0.0);
		}
		else
		{
			float Direction[3];
			Direction[0] = GetRandomFloat(-1.0, 1.0);
			Direction[1] = GetRandomFloat(-1.0, 1.0);
			Direction[2] = GetRandomFloat(-1.0, 1.0);
			TE_SetupSparks(hitpos,Direction,1,3);
			TE_SendToAll();
			EmitSoundToAll(SOUND_IMPACT2, 0,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,hitpos, NULL_VECTOR,true, 0.0);
		}

		ShowMuzzleFlash(gunpos, ang);
		if(L4D2Version) ShowTrack(gunpos, hitpos);
		else
		{
			//ShowPos(0, gunpos, hitpos, 0.06, 0.0, 0.5, 1.0);
		}

		if(GunType[index] == 1) EmitSoundToAll(SOUND_FIRE, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, gunpos, NULL_VECTOR, true, 0.0);
	}
	CloseHandle(trace);
}

float AngleDiff(float a, float b)
{
	float d = 0.0;
	if(a >= b)
	{
		d = a-b;
		if(d >= 180.0) d = d - 360.0;
	}
	else
	{
		d = a - b;
		if(d <=- 180.0) d = 360 + d;
	}
	return d;
}

float Sign(float v)
{
	if(v == 0.0) return 0.0;
	else if(v > 0.0) return 1.0;
	else return -1.0;
}

stock void CheckAngle(float angle[3])
{
	for(int i=0; i < 3; i++)
	{
		if(angle[i] > 360.0) angle[i] = angle[i] - 360.0;
		else if(angle[i] <- 360.0) angle[i] = angle[i] + 360.0;
	}
}

stock float GetAngle(float x1[3], float x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)))*180.0/Pai;
}

bool IsVilidEenmey(int enemy, int team)
{
	bool r=false;
	if(enemy <= 0) return r;
	if(team == 2) team = 3;
	else team = 2;
	if( enemy <= MaxClients)
	{
		if(IsClientInGame(enemy) && IsPlayerAlive(enemy) && GetClientTeam(enemy) == team)
		{
			r = true;
		}
	}
	else if( team ==3 && IsValidEntity(enemy) && IsValidEdict(enemy))
	{
		char classname[32];
		GetEdictClassname(enemy, classname,32);
		if(StrEqual(classname, "infected", true) )
		{
			r = true;
			if(L4D2Version)
			{
				int flag = GetEntProp(enemy, Prop_Send, "m_bIsBurning");
				if(flag == 1)
				{
					r = false;
				}
			}
			else
			{
			}
		}
		else if (StrEqual(classname, "witch", true))
		{
			r = true;
		}
	}
	return r;
}